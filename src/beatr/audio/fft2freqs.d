import std.math : sqrt;
version(unittest) {
	import std.random : uniform;
	import std.math : sin, fabs, PI;
}

import fftw.fftw3;

import util.beatr;

class Fft2Freqs
{
private:
	double[] ibuf;
	cdouble[] obuf;
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
		ibuf = new double[size];
		obuf = new cdouble[size/2 + 1];
		onormed = new double[size/2 + 1];
		norm_coeff = 1./sqrt(1.0 * size);

		plan = fftw_plan_dft_r2c_1d(cast(int) size, ibuf.ptr, obuf.ptr,
									FFTW_MEASURE | FFTW_DESTROY_INPUT
									| FFTW_WISDOM_ONLY);
		if (plan is null) {
			plan = fftw_plan_dft_r2c_1d(cast(int) size, ibuf.ptr, obuf.ptr,
										FFTW_MEASURE | FFTW_DESTROY_INPUT);
			saveWisdom();
		}
	}

	void execute()
	{
		onormed[] = 0.;
		executePlan();
	}

	@property auto input() nothrow { return ibuf; }
	@property auto output() const nothrow { return onormed; }
	@property auto rawoutput() const nothrow { return obuf; }
	@property auto transformationSize() const nothrow { return size; }

	void
	executeOverlaps(T)(T[] biginput, uint nbOverlaps)
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
			onormed[i] += sqrt(c.re * c.re + c.im * c.im) * norm_coeff;
	}

	~this()
	{
		fftw_destroy_plan(plan);
	}
}
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
