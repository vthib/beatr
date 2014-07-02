import std.math : sqrt, cos, PI;
import std.exception : assumeUnique;
version(unittest) {
    import std.algorithm : equal;
	import std.exception : assertThrown;
    import core.exception : AssertError;
	import std.math : approxEqual, abs;
	import std.random;

	import audio.fftutils;
}

import fftw.fftw3;

class LowPassFilter(size_t order)
{
	immutable double[order + 1] impulse;
	immutable double gain;
	double[order + 1] inBuf;
	size_t idx;
	bool bootstrapped;

	this(in int transformSize, in double cutOffFreq)
	in
	{
		assert(order % 2 == 0, "Order has to be even");
		assert(cutOffFreq > 0.,
			   format("Invalid cutOff frequency: %s", cutOffFreq));
		assert(order <= transformSize, "Filter order greater than FFT "
			   "transformation size");
	}
	body
	{
		impulse = assumeUnique(createImpulse(transformSize, cutOffFreq));
		double g = 0.;
		foreach (a; impulse)
			g += a;
		gain = g;

		inBuf[] = 0.;
		idx = order/2;
		bootstrapped = false;
	}
	unittest
	{
		auto lpf = new LowPassFilter!4(4, 200.);

		assert(lpf.gain != 0.);
		assert(lpf.idx == 4/2);
		foreach (i; 0 .. 4/2)
			assert(lpf.inBuf[i] == 0.);

		assertThrown!AssertError(new LowPassFilter!5(20, 20000.));
		assertThrown!AssertError(new LowPassFilter!30(20, 20000.));
		assertThrown!AssertError(new LowPassFilter!10(20, -50.));
	}

	size_t filter(in double[] input, double[] output, bool flush = false)
	{
		size_t iidx = 0;
		size_t outcnt = 0;

		if (!bootstrapped) {
			while (idx != inBuf.length - 1) {
				if (iidx >= input.length)
					return 0;
				addInput(input[iidx]);
				iidx++;
			}
			bootstrapped = true;
		}

		while (iidx < input.length) {
			addInput(input[iidx++]);
			output[outcnt++] = convolution(inBuf, idx, impulse) / gain;
		}
		if (flush) {
			foreach (i; 0 .. order/2) {
				addInput(0.);
				output[outcnt++] = convolution(inBuf, idx, impulse) / gain;
			}
		}

		return outcnt;
	}

private:
	void addInput(in double input) nothrow
	{
		inBuf[idx++] = input;
		idx %= (order+1);
	}
	unittest
	{
		auto lpf = new LowPassFilter!4(4, 20.);

		lpf.addInput(5);
		assert(lpf.idx == 3 && lpf.inBuf[2] == 5);
		lpf.addInput(3);
		lpf.addInput(1);
		assert(lpf.idx == 0 && lpf.inBuf[4] == 1);
	}

	static T convolution(T)(in T[] a, in size_t ai, in T[] b) nothrow pure
	in
	{
		assert(a.length == b.length);
		assert(ai < a.length);
	}
	body
	{
		T r = 0.;

		size_t j = b.length - 1;
		foreach (i; ai .. a.length)
			r += a[i] * b[j--];
		foreach (i; 0 .. ai)
			r += a[i] * b[j--];

		return r;
	}
	unittest
	{
		double[] a = [3., 5., 2.];
		double[] b = [-3.2, 4, 0.5];

		assert(approxEqual(convolution(a, 0, b), 1.5 + 20. + -6.4));
		assert(approxEqual(convolution(a, 1, b), 2.5 + 8. + -9.6));
		assertThrown!AssertError(convolution(a, 5, b));
		assertThrown!AssertError(convolution(a, 1, [2., 3.]));
	}

	/++ Creates a time-domain vector equal to a reverse FFT of a lp filter +/
	double[] createImpulse(in int transformSize, in double cutOffFreq)
	{
		auto ibuf = new cdouble[transformSize];
		auto obuf = new double[transformSize];

		auto plan = fftw_plan_dft_c2r_1d(transformSize, ibuf.ptr, obuf.ptr,
										 0);
		scope(exit)
			fftw_destroy_plan(plan);

		immutable auto tau = short.max/((cutOffFreq + 1)*2);
		double input;
		foreach (i; 0 .. (transformSize/2)) {
			input = (i < cutOffFreq) ? tau : 0.;
			ibuf[i] = input + 0i;
			ibuf[transformSize - 1 - i] = input + 0i;
		}

		fftw_execute(plan);

		double[] impulse = new double[order+1];
		foreach (i; order/2 .. (order+1))
			impulse[i] = obuf[i - order/2];
		foreach (i; 0 .. order/2)
			impulse[i] = obuf[transformSize - order/2 + i];

		foreach (i, ref a; impulse)
			a *= 0.54 - 0.46 * cos(2*PI*i/(order+1));

		return impulse;
	}

	version(none) {
		void printTab(inout double[] t)
		{
			import std.stdio;

			double M = 0;
			double m = 0.;
			foreach (a; t) {
				if (a > M) M = a;
				if (a < m) m = a;
			}

			auto step = (M - m + 1) / 80;
			writefln("min: %s, max: %s", m, M);
			foreach (i, a; t) {
				writef("%s ", i);
				for (auto j = step; j + m <= M; j += step) {
					if ((j+m) - step < 0 && (j+m) >= 0)
						write("|");
					else
						write((j + m <= a) ? "X" : " ");
				}
				writeln();
			}
		}
	}
}
unittest
{
	enum cutOff = 10000;
	auto plf = new LowPassFilter!80(44100, cutOff);

	/* create random input (noise) */
	double[] input = new double[44100];
	foreach (ref a; input)
		a = uniform(short.min, short.max);

	/* get the output of the filter */
	double[] output = new double[44100];
	plf.filter(input, output, true);

	/* get the frequencies of the input with and without the filter
	   applied */
	double[] freqs_without = times2freqs(input, 44100);
	double[] freqs_with = times2freqs(output, 44100);

	/* we will compare the two arrays except between
	   cutoff - margin and cutoff + margin */
	enum margin = 1000;
	double[] zeroes = new double[freqs_with.length - (cutOff + margin)];
	zeroes[] = 0.;

	/* difference must be less than 1% of the maximum value */
	bool cmp(double a, double b) { return (abs(a - b) < 2*short.max/100); }

	/* make sure both output are equal for frequencies < cutOff - margin,
	   and that the output with the filter is null for
	   frequencies > cutOff + margin */
	assert(equal!cmp(freqs_without[0 .. (cutOff - margin)],
					 freqs_with[0 .. (cutOff - margin)]));
	assert(equal!cmp(freqs_with[(cutOff + margin) .. $],
					 zeroes));
}
