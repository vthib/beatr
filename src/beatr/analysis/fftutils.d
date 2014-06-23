import std.math : sqrt;
import std.stdio;
import std.file : mkdir, FileException;
import std.string : toStringz;
import core.stdc.errno : EEXIST;

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
double[] fftTransform(const(short[]) audio, int transformSize = -1)
{
	if (transformSize == -1)
		transformSize = cast(int) audio.length;

	auto ibuf = new double[transformSize];
	auto obuf = new cdouble[transformSize];

	auto plan = fftw_plan_dft_r2c_1d(transformSize, ibuf.ptr, obuf.ptr,
									 FFTW_MEASURE | FFTW_DESTROY_INPUT
									 | FFTW_WISDOM_ONLY);
	if (plan is null) {
		plan = fftw_plan_dft_r2c_1d(transformSize, ibuf.ptr, obuf.ptr,
									FFTW_MEASURE | FFTW_DESTROY_INPUT);
		Beatr.writefln(Lvl.DEBUG, "no wisdom available: new wisdom exported "
					   "to '%s'", Beatr.configDir ~ "/wisdom");
		immutable auto filename = toStringz(Beatr.configDir ~ "/wisdom");
		fftw_export_wisdom_to_filename(filename);
	}
	scope(exit) fftw_destroy_plan(plan);

	/* copy the input into the ibuf buffer */
	/* !!! This has to be _after_ the plan creation, as this function sets
	   its argument to 0 */
	/* XXX compute step if transformSize != audio.length */
	enum step = 1;
	uint idx = 0;
	foreach (ref i; ibuf) {
		i = audio[idx];
		idx += step;
	}

	fftw_execute(plan);

	auto vec = new double[transformSize];
	/* add it to our norms field */
	foreach (i, ref o; vec)
		o = sqrt(obuf[i].re * obuf[i].re + obuf[i].im * obuf[i].im)
			/ transformSize;

	return vec;
}
