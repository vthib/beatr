import std.file : mkdir, FileException;
import std.math : sqrt;
import core.stdc.errno : EEXIST;
import std.exception : enforce;
version(unittest) {
	import std.random : uniform;
	import std.math : sin, PI, fabs;
	import std.exception : assertThrown;
}

import fftw.fftw3;

import util.beatr;

void fftInit() nothrow
{
	try {
		mkdir(Beatr.configDir);
	} catch (Exception e) {
		if (auto f = cast(FileException)e) {
			if (f.errno == EEXIST)
				goto end;
		}
		Beatr.writefln(Lvl.WARNING, "error creating config directory "
					   "'%s': %s", Beatr.configDir, e.msg);
		return;
	}

end:
	immutable auto filename = toStringz(Beatr.configDir ~ "/wisdom");
	fftw_import_wisdom_from_filename(filename);
}

void fftDestroy() nothrow
{
	fftw_cleanup();
}

/++ transform an audio frame into a frequency-intensity vector +/
double[] times2freqs(T)(inout T[] audio, int transformSize = -1,
					 uint nbOverlaps = 4)
{
	if (transformSize == -1) {
		transformSize = cast(int) audio.length;
		nbOverlaps = 1;
	} else {
		enforce(audio.length >= transformSize, "Audio samples need to be "
				"larger than FFT transform size");
		if ((audio.length - transformSize) % nbOverlaps != 0)
			Beatr.writefln(Lvl.WARNING, "Samples lost due to difference "
						   "between frame length and FFT transform size "
						   "not divisible by number of overlaps");
	}

	auto ibuf = fftw_alloc_real(transformSize);
	auto obuf = fftw_alloc_complex(transformSize);
	scope(exit) {
		fftw_free(ibuf);
		fftw_free(obuf);
	}

	auto plan = fftw_plan_dft_r2c_1d(transformSize, ibuf, obuf,
									 FFTW_MEASURE | FFTW_DESTROY_INPUT
									 | FFTW_WISDOM_ONLY);
	if (plan is null) {
		plan = fftw_plan_dft_r2c_1d(transformSize, ibuf, obuf,
									FFTW_MEASURE | FFTW_DESTROY_INPUT);
		Beatr.writefln(Lvl.DEBUG, "no wisdom available: new wisdom exported "
					   "to '%s'", Beatr.configDir ~ "/wisdom");
		immutable auto filename = toStringz(Beatr.configDir ~ "/wisdom");
		fftw_export_wisdom_to_filename(filename);
	}
	scope(exit)
		fftw_destroy_plan(plan);

	auto vec = new double[transformSize/2];
	vec[] = 0.;

	foreach(step; 0 .. nbOverlaps) {
		/*copy the input into the ibuf buffer */
		/* This has to be done _after_ the plan creation, as this function sets
		   its argument to 0 */
		size_t idx = step * (audio.length - transformSize)/nbOverlaps;
		foreach (i; 0 .. transformSize)
			ibuf[i] = audio[idx++];

		fftw_execute(plan);

		/* add it to our norms field */
		foreach (i, ref o; vec)
			o += sqrt((obuf[i].re * obuf[i].re + obuf[i].im * obuf[i].im)
					  / transformSize);
	}

	if (nbOverlaps != 1)
		vec[] /= nbOverlaps;

	return vec;
}
unittest
{
	double[] input = new double[44100];

	/* create noise input */
	foreach (ref a; input)
		a = uniform(-100, 100);

	auto output = times2freqs(input);

	/* noise has every frequency components */
	foreach (a; output)
		assert(a != 0.);

	/* create 2 sin input */
	enum samplerate = 40000;
	double[] in2 = new double[20000];
	foreach (i, ref a; in2)
		a = sin(2*PI*500./samplerate * i) + sin(2*PI*8000./samplerate * i);

	output = times2freqs(in2, 20000);

	/* every frequency energy is null but the two we set */
	foreach (i, a; output) {
		if (i == (500 * 20000 / samplerate) || i == (8000 * 20000 / samplerate))
			assert(a != 0.);
		else
			assert(fabs(a) < 1e-10);
	}

	assertThrown!Exception(times2freqs(in2, 40000));
}
