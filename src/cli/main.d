module main;

import std.stdio;

import beatr.analyzer.fft.fftw3;

void
main()
{
	fftw_complex cpx;

	writeln(fftw_plan_dft_1d(1, &cpx, &cpx, FFTW_FORWARD, FFTW_ESTIMATE));
	writeln(fftw_cc);
}
