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

/++ Implements a low-pass filter
 + Based mostly on http://paulbourke.net/miscellaneous/filter/
 +
 + A desired frequency response is first created, then translated to the
 + time domain. This impulse function is truncated into an array of size
 + "order". This array is multiplied by a Hamming window function to limit
 + artifacts.
 +
 + Application of the filter is done with the "filter" function, translating
 + an input array into an output array. The filter has a delay of "order/2"
 + inputs, giving its first results only after "order/2" inputs has been
 + received. To output the last bytes, the third argument of the function has
 + to be set to true
 +/
class LowPassFilter(size_t order)
{
private:
	immutable double[order + 1] impulse; /++ the impulse function +/
	immutable double gain; /++ the sum of the impulse function coefficients +/

	/++ the circular buffer used to keep delayed inputs +/
	double[order + 1] inBuf;
	size_t idx; /++ the current index in the buffer +/
	bool bootstrapped; /++ Is the input buffer correctly initialized?
						+ (ie has order/2 inputs been received?) +/

public:
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

		/* first order/2 inputs are 0 */
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

	/++ Apply the filter on input, returning results in the "output" variable.
	 + The "output" buffer has to have enough room:
	 +  Between (input.length - order/2) and input.length if not flushing
	 +  Up to input.length + order/2 if flushing
	 + Set "flush" to true to retrieve the delayed inputs
	 + Returns: the number of elements put in the "output" buffer
	 +/
	size_t filter(in double[] input, double[] output, bool flush = false)
	{
		size_t iidx = 0;
		size_t outcnt = 0;

		if (!bootstrapped) {
			/* put input elements in the buffer as long as there are more
			   than 1 place available */
			while (idx != inBuf.length - 1) {
				if (iidx >= input.length)
					return 0;
				addInput(input[iidx]);
				iidx++;
			}
			bootstrapped = true;
		}

		/* add the input (from the input array or 0 if flushing),
		 * then convolutes the buffer with the impulse function.
		 * Divide by gain to normalize */
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
	/++ Add input in the buffer, then increments modulo (order+1) the index +/
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

	/++ Computes the convolution of a with b, but starting in a from ai
	 + ie, computes sum(i : 0 -> n, a[(ai + i) % n] * b[n - i] +/
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

	/++ Creates a time-domain vector equal to a reverse FFT of the desired
	 + frequency response of an lp filter +/
	double[] createImpulse(in int transformSize, in double cutOffFreq)
	{
		auto ibuf = new cdouble[transformSize];
		auto obuf = new double[transformSize];

		auto plan = fftw_plan_dft_c2r_1d(transformSize, ibuf.ptr, obuf.ptr,
										 0);
		scope(exit)
			fftw_destroy_plan(plan);

		/* tau is a constant that means that the highest norm possible
		 * after the transformation will be <= short.max */
		immutable auto tau = short.max/((cutOffFreq + 1)*2);
		double input;
		foreach (i; 0 .. (transformSize/2)) {
			input = (i < cutOffFreq) ? tau : 0.;
			ibuf[i] = input + 0i;
			ibuf[transformSize - 1 - i] = input + 0i;
		}

		fftw_execute(plan);

		/* copy the impulse function in an array, translating
		 * it to make it causal */
		double[] impulse = new double[order+1];
		foreach (i; order/2 .. (order+1))
			impulse[i] = obuf[i - order/2];
		foreach (i; 0 .. order/2)
			impulse[i] = obuf[transformSize - order/2 + i];

		/* multiply with an Hamming function */
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
