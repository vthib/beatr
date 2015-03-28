module audio.fft;

import std.math : sqrt;
version(unittest) {
	import std.random : uniform;
	import std.math;
}

import fftw.fftw3;

import util.beatr;
import audio.fftutils;

class FftTransformation(T, U, bool t2f)
{
private:
	T[] ibuf;
	U[] obuf;
	double[] onormed;
	size_t size;
	fftw_plan plan;
	immutable double norm_coeff;

public:
	this(size_t s)
	in
	{
		assert(s <= int.max, format("The size of the fft transformation (%s) "
									"is too big", s));
	}
	body
	{
		size = s;
		static if (t2f) {
			ibuf = new T[size];
			obuf = new U[size/2 + 1];
			enum create_plan = &fftw_plan_dft_r2c_1d;
		} else {
			ibuf = new T[size/2 + 1];
			obuf = new U[size];
			enum create_plan = &fftw_plan_dft_c2r_1d;
		}
		onormed = new double[obuf.length];
		norm_coeff = 1./sqrt(1.0 * size);

		plan = create_plan(cast(int) size, ibuf.ptr, obuf.ptr,
						   FFTW_MEASURE | FFTW_DESTROY_INPUT
						   | FFTW_WISDOM_ONLY);
		if (plan is null) {
			plan = create_plan(cast(int) size, ibuf.ptr, obuf.ptr,
							   FFTW_MEASURE | FFTW_DESTROY_INPUT);
			fftSaveWisdom();
		}
	}

	void execute()
	{
		executePlan!false();
	}

	@property auto input() { return ibuf; }
	@property auto output() const nothrow { return onormed; }
	@property auto rawoutput() const nothrow { return obuf; }
	@property auto transformationSize() const nothrow { return size; }

	void
	executeOverlaps(R)(R[] biginput, uint nbOverlaps)
	in
	{
		assert(biginput.length >= input.length,
			   format("Input needs to be larger than %s", input.length));
		assert(nbOverlaps > 1, "number of overlaps must be >= 2");
	}
	body
	{
		onormed[] = 0.;

		version(none) { /* annoying as new default is to lose some samples:
						   44100 -> 16384 with 8 overlaps */
			if ((biginput.length - input.length) % nbOverlaps != 0)
				Beatr.writefln(Lvl.warning, "Samples lost due to difference "
							   "between frame length and FFT transform size "
							   "not divisible by number of overlaps");
		}

		foreach(step; 0 .. nbOverlaps) {
			/*copy the input into the ibuf buffer */
			/* This has to be done _after_ the plan creation, as this function sets
			   its argument to 0 */
			import std.stdio;
			size_t idx = step * (biginput.length - input.length)/(nbOverlaps - 1);
			foreach (ref a; ibuf)
				a = biginput[idx++];

			executePlan!true();
		}

		onormed[] /= nbOverlaps;
	}

private:
	void executePlan(bool add)()
	{
		fftw_execute(plan);

		foreach(i, c; obuf) {
			static if (t2f) {
				static if (add)
					onormed[i] += sqrt(c.re*c.re + c.im*c.im) * norm_coeff;
				else
					onormed[i] = sqrt(c.re*c.re + c.im*c.im) * norm_coeff;
			} else {
				static if (add)
					onormed[i] += c * norm_coeff;
				else
					onormed[i] = c * norm_coeff;
			}
		}
	}

	~this()
	{
		fftw_destroy_plan(plan);
	}
}

alias Fft2Freqs = FftTransformation!(double, cdouble, true);
unittest
{
	auto fft = new Fft2Freqs(44100);

	import std.stdio;
	writefln("Testing Fft2Freqs...");

	/* create noise input */
	foreach (ref a; fft.input)
		a = uniform(-100, 100);

	/* noise has every frequency components */
	fft.execute();
	foreach (a; fft.output)
		assert(a != 0.);
	auto ibig = new double[48000];
	foreach (ref a; ibig)
		a = uniform(-100, 100);
	fft.executeOverlaps(ibig, 4);
	foreach (a; fft.output)
		assert(a != 0.);

	/* create 2 sin input */
	enum samplerate = 40000;
	auto fft2 = new Fft2Freqs(20000);
	foreach (i, ref a; fft2.input)
		a = sin(2*PI*500./samplerate * i) + sin(2*PI*8000./samplerate * i);

	/* normal execute */
	fft2.execute();
	auto o1 = fft2.output.idup;

	/* big input, 16 overlaps execute */
	auto ibig2 = new double[48000];
	foreach (i, ref a; ibig2)
		a = sin(2*PI*500./samplerate * i) + sin(2*PI*8000./samplerate * i);
	fft2.executeOverlaps(ibig2, 16);

	/* every frequency energy is null but the two we set */
	foreach (array; [o1, fft2.output]) {
		foreach (i, a; array) {
			if (i == (500 * 20000 / samplerate) || i == (8000 * 20000 / samplerate))
				assert(approxEqual(a, sqrt(20000.)/2.));
			else
				assert(fabs(a) < 1e-10);
		}
	}	
}

alias Fft2Times = FftTransformation!(cdouble, double, false);
unittest
{
	import std.stdio;
	writefln("Testing Fft2Times...");

	auto f2t = new Fft2Times(44100);
	/* create noise input */
	auto biginput = new cdouble[30051];
	foreach (ref a; biginput)
		a = uniform(0, 100) + 0i;
	/* noise has every time components */
	f2t.executeOverlaps(biginput, 16);
	foreach (a; f2t.output)
		assert(a != 0.);

	/* create noise input */
	auto firstinput = new double[f2t.input.length];
	foreach (i, ref a; firstinput) {
		a = uniform(0, 100);
		f2t.input[i] = a + 0i;
	}
	/* noise has every time components */
	f2t.execute();
	foreach (a; f2t.output)
		assert(a != 0.);

	/* freqs -> times -> freqs returns same input */
	auto t2f = new Fft2Freqs(44100);
	t2f.input[] = f2t.output[];
	t2f.execute();
	assert(approxEqual(firstinput, t2f.output, 1e-10, 1e-10));

	/* times -> freqs -> times returns same input */
	auto times = t2f.input.dup;
	f2t.input[] = t2f.rawoutput();
	/* we get the raw (complex) output directly back to f2t, we need
	 * to take care of the sqrt(samplerate) coefficient */ 
	times[] *= sqrt(44100.);
	f2t.execute();
	assert(approxEqual(f2t.output, times, 1e-10, 1e-10));

	/* create 3*cos + 0.5*sin input and expected output */
	enum samplerate = 40000;
	auto fft = new Fft2Times(20000);
	fft.input[] = 0 + 0i;
	fft.input[500 * 20000 / samplerate] = sqrt(20000.)*(3*0.5 + 0i);
	fft.input[8000 * 20000 / samplerate] = sqrt(20000.)*(0 - 0.5*0.5*1.0i);

	auto expected = new double[20000];
	foreach (i, ref a; expected)
		a = 3*cos(2*PI*500./samplerate * i) + 0.5*sin(2*PI*8000./samplerate * i);

	fft.execute();
	assert(approxEqual(fft.output, expected));
}
