import std.math : sqrt;
version(unittest) {
	import std.random : uniform;
	import std.math : cos, sin, PI;
}

import fftw.fftw3;

import audio.fft2freqs;
import util.beatr;

class Fft2Times
{
private:
	cdouble[] ibuf;
	double[] obuf;
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
		ibuf = new cdouble[size/2 + 1];
		obuf = new double[size];
		onormed = new double[size];
		norm_coeff = 1./sqrt(1.0 * size);

		plan = fftw_plan_dft_c2r_1d(cast(int) size, ibuf.ptr, obuf.ptr,
									FFTW_MEASURE | FFTW_DESTROY_INPUT
									| FFTW_WISDOM_ONLY);
		if (plan is null) {
			plan = fftw_plan_dft_c2r_1d(cast(int) size, ibuf.ptr, obuf.ptr,
										FFTW_MEASURE | FFTW_DESTROY_INPUT);
			saveWisdom();
		}
	}

	void execute()
	{
		onormed[] = 0.;
		executePlan();
	}

	@property input() { return ibuf; }
	@property output() const { return onormed; }

	void
	executeOverlaps(typeof(input[0])[] biginput, int nbOverlaps)
	in
	{
		assert(biginput.length >= input.length,
			   format("Input needs to be larger than %s", input.length));
	}
	body
	{
		onormed[] = 0.;

		if ((biginput.length - input.length) % nbOverlaps != 0)
			Beatr.writefln(Lvl.WARNING, "Samples lost due to difference "
						   "between frame length and FFT transform size "
						   "not divisible by number of overlaps");

		foreach(step; 0 .. nbOverlaps) {
			/*copy the input into the ibuf buffer */
			/* This has to be done _after_ the plan creation, as this function sets
			   its argument to 0 */
			size_t idx = step * (biginput.length - input.length)/nbOverlaps;
			foreach (ref a; ibuf)
				a = biginput[idx++];

			executePlan();
		}

		if (nbOverlaps != 1)
			onormed[] /= nbOverlaps;
	}

private:
	void saveWisdom()
	{
		Beatr.writefln(Lvl.DEBUG, "no wisdom available: new wisdom exported "
					   "to '%s'", Beatr.configDir ~ "/wisdom");
		immutable auto filename = toStringz(Beatr.configDir ~ "/wisdom");
		fftw_export_wisdom_to_filename(filename);
	}

	void executePlan()
	{
		fftw_execute(plan);

		foreach(i, c; obuf)
			onormed[i] += c * norm_coeff;
	}

	~this()
	{
		fftw_destroy_plan(plan);
	}
}
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
