import std.file : mkdir, FileException;
import std.math : sqrt;
import core.stdc.errno : EEXIST;
import std.exception : enforce;

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
double[] fft2bins(const(short[]) audio, int transformSize = -1,
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

/++ Creates a time-domain vector equal to a reverse FFT of a band filter +/
double[] lowPassFilter(in int transformSize, in size_t filterSize)
{
	auto ibuf = new cdouble[transformSize];
	auto obuf = new double[transformSize];

	auto plan = fftw_plan_dft_c2r_1d(transformSize, ibuf.ptr, obuf.ptr,
									 0);
	scope(exit)
		fftw_destroy_plan(plan);

	import std.stdio;
	enum cutOff = 20000.;
	enum tau = short.max/((cutOff + 1)*2);
	double input;
	foreach (i; 0 .. (transformSize/2)) {
		input = (i < cutOff) ? tau : 0.;
		ibuf[i] = input + 0i;
		ibuf[transformSize - 1 - i] = 0 + 0i;
	}

	fftw_execute(plan);

	double[] filter = new double[filterSize];
	foreach (i; filterSize/2 .. filterSize)
		filter[i] = obuf[i - filterSize/2];
	foreach (i; 0 .. filterSize/2)
		filter[i] = obuf[transformSize - filterSize/2 + i];

	import std.stdio;
	writefln("%s", filter);

	double M = 0;
	double m = 0.;
	foreach (a; filter) {
		if (a > M) M = a;
		if (a < m) m = a;
	}

	auto step = (M - m + 1) / 80;
	writefln("min: %s, max: %s", m, M);
	foreach (i, a; filter) {
		writef("%s ", i);
		for (auto j = step; j + m <= M; j += step) {
			if ((j+m) - step < 0 && (j+m) >= 0)
				write("|");
			else
				write((j + m <= a) ? "X" : " ");
		}
		writeln();
	}

	plan = fftw_plan_dft_r2c_1d(transformSize, obuf.ptr, ibuf.ptr,
									 0);

	obuf[] = 0.;
	foreach (i, a; filter)
		obuf[i] = a;

	fftw_execute(plan);

	M = 0;
	m = 0.;

	import std.algorithm;
	import std.math;
	import std.array;
	double[] norms = ibuf.map!(a => sqrt(a.re*a.re + a.im*a.im)).array;
	foreach (a; norms) {
		if (a > M) M = a;
		if (a < m) m = a;
	}

	import std.stdio;
	step = (M - m + 1) / 80;
	writefln("min: %s, max: %s", m, M);
	foreach (i, a; norms) {
		writef("%s ", i);
		for (auto j = step; j + m <= M; j += step) {
			if ((j+m) - step < 0 && (j+m) >= 0)
				write("|");
			else
				write((j + m <= a) ? "X" : " ");
		}
		writeln();
	}

	return filter;
}/*
unittest
{
	import std.stdio;
	writefln("starting test bandFilter...");
	lowPassFilter(44100, 200);
}
*/
