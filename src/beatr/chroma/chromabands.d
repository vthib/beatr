import util.types;
import util.beatr;

import std.algorithm : map;
import std.stdio;
import std.conv: to;
import std.math;

/++
 + Chroma bands represents an histogram of the intensity of each note.
 +/
public:
class ChromaBands
{
private:
	/* Number of scales in our chroma bands */
	immutable ubyte nbscales;
	immutable ubyte offset;
	immutable uint duration;

	/* 1st dim: division of time (one band for every 2 second) */
	/* 2nd dim: 12 semitons * number of scales = number of notes considered */
	double[][] bands; /++ the chroma bands +/
	size_t curf; /++ number of frame added +/

	enum freqs = genFreqs(); /++ the frequencies for each note +/

public:
	this(in ubyte numscales, in ubyte offsetscales, in uint dur) @safe
	in {
		assert(1 <= numscales && numscales <= 10);
		assert(offsetscales <= 10);
		assert(offsetscales + numscales - 1 <= 10);
	}
	body {
		nbscales = numscales;
		offset = offsetscales;
		duration = dur;

		bands = new double[][](dur/2 + 1, nbscales * 12);
		curf = 0;
		foreach (ref b; bands)
			b[] = 0.;
	}

	@property auto getBands() const nothrow @safe
	{
		return bands;
	}
	alias getBands this;

	@property auto normalize() const nothrow @safe
	{
		double[] n = new double[12];

		n[] = 0.;
		foreach(b; bands)
			foreach(i, v; b)
				n[i % 12] += v;
		foreach(ref a; n)
			a /= nbscales;

		return n;
	}

	static T min(T)(T a, T b) { return a < b ? a : b; }
	static T max(T)(T a, T b) { return a > b ? a : b; }

	/++ Use an array representing a FFT analysis to fill the chroma bands
	 + Params: s = an array of a FFT analysis.
	 +/
	void addFftSample(in double[] s) //@safe
	body {
		/* indexes of each note in the FFT array */
		auto fscales = freqs[offset*12 .. ((offset + nbscales) * 12)];
		double[] b = new double[nbscales * 12];
		b[] = 0.;

		Beatr.writefln(Lvl.DEBUG, "using mode '%s' and sigma '%s'",
					   Beatr.fftInterpolationMode, Beatr.fftSigma);
		Beatr.writefln(Lvl.DEBUG, "Analyzing between C%s and C%s",
					   Beatr.scaleOffset,
					   Beatr.scaleOffset + Beatr.scaleNumbers);

		size_t begin;
		size_t end;

		/* Q is equal to sigma*(sqrt(2, 12) - 1)
		 * Thus mu_(i) * Q = mu_(i+1)*sigma */
		immutable Q = Beatr.fftSigma * 0.05946309435929;

		foreach(i, f; fscales) {
			/* center of the window is the note frequency */
			auto mu = f * s.length / beatrSampleRate;

			if (Q == 0.) {
				b[i] = s[to!ulong(mu)];
				continue;
			}

			/* Leftmost bin from which we start to aggregate results */
			auto left = mu*(1 - Q);
			begin = (left < 0.) ? 0 : min(to!ulong(left), to!ulong(mu));
			// XXX bound check for end
			end = max(to!ulong(mu*(1 + Q)), to!ulong(mu) + 1);
			auto right = mu*(1+Q);

			/* for every significant abscissa ([mu(1-Q); mu(1+Q)], compute
			   the correlation coeff, add coeff * value, and in the end
			   divide by the sum of the coefficients */
			double sum = 0.;
			double coeff;

			import util.note;
			foreach (j; begin .. (end+1)) {
				if (j < left || j > right)
					continue;
				final switch (Beatr.fftInterpolationMode) {
				case FFTInterpolationMode.TRIANGLE:
					coeff = triangle(mu, left, mu*(1+Q), j);
					break;
				case FFTInterpolationMode.RECTANGLE:
					coeff = 1;
					break;
				case FFTInterpolationMode.COSINE:
					coeff = cosine(left, mu*(1+Q), j);
					break;
				case FFTInterpolationMode.GAUSSIAN:
					coeff = gaussian(mu, mu*Q/3, j);
					break;
				}
				sum += coeff;
				b[i] += s[j] * coeff;
			}
			if (sum != 0)
				b[i] /= sum;
		}

		bands[curf++ / 2][] += b[];
	}
	/* XXX unittest? */

	/++ print an histogram of the bands
	 + Params: height = the height of the histograms
	 +/
	void printHistograms(in uint height) const
	{
		double m = 0;
		double[] b = new double[nbscales * 12];

		b[] = 0.;
		foreach (t; bands)
			foreach (i, v; t)
				b[i] += v;

		foreach(v; b)
			if (v >= m)
				m = v;

		auto step = m/height;

		/* print the histograms */
		foreach(i; 0 .. (height + 1)) {
			foreach(v; b) {
				if (v >= (height - i) * step)
					write('X');
				else
					write(' ');
			}
			writeln();
		}

		/* print the notes names */
		foreach(i; 0 .. b.length) {
			switch (i % 12) {
			case 0: write('C'); break;
			case 2: write('D'); break;
			case 4: write('E'); break;
			case 5: write('F'); break;
			case 7: write('G'); break;
			case 9: write('A'); break;
			case 11: write('B'); break;
			default: write(' '); break;
			}
		}
		writeln();

		/* print the scales numbers */
		foreach(i; 0 .. b.length) {
			if (i % 12 == 0)
				write(i / 12 + offset);
			else
				write(' ');
		}
		writeln();
	}
	/* XXX unittest? */

	/++ print a Chromagram
	 +/
	void printChromagram() const
	{
		auto b = new double[12][bands.length];
		foreach(ref t; b)
			t[] = 0.;
		foreach(i, t; bands)
			foreach(j, v; t)
				b[i][j % 12] += v;

		double max = 0.;
		foreach (t; b)
			foreach (a; t)
				if (a > max) max = a;

		foreach (j; 0 .. 12) {
			switch (j) {
			case  0: write("C "); break;
			case  2: write("D "); break;
			case  4: write("E "); break;
			case  5: write("F "); break;
			case  7: write("G "); break;
			case  9: write("A "); break;
			case 11: write("B "); break;
			default: write("  "); break;
			}
			foreach (i; 0 .. b.length) {
				if (b[i][j] < max/6)
					write(" ");
				else if (b[i][j] < max/3)
					write("-");
				else if (b[i][j] < max/2)
					write("1");
				else if (b[i][j] < 2*max/3)
					write("x");
				else if (b[i][j] < 5*max/6)
					write("Q");
				else
					write("#");
			}
			writeln();
		}
	}

private:
	static double
	triangle(in double mu, in double l, in double r, in ulong x) pure @safe
	in
	{
		assert(l <= x && x <= r);
		assert(l < mu && mu < r);
	}
	body
	{
		if (x < mu)
			return (x - l)/(mu - l);
		else
			return (r - x)/(r - mu);
	}
	unittest
	{
		import std.math : approxEqual;

		assert(approxEqual(triangle(5, 3, 7, 3), 0));
		assert(approxEqual(triangle(5, 3, 7, 4), 0.5));
		assert(approxEqual(triangle(5, 3, 7, 5), 1));
		assert(approxEqual(triangle(5, 3, 7, 6), 0.5));
		assert(approxEqual(triangle(5, 3, 7, 7), 0));
	}

	static double
	gaussian(in double mu, in double sigma, in ulong x) pure @safe
	in {
		assert(sigma != 0.);
	}
	body
	{
		return exp(-((x - mu)*(x-mu))/(2*sigma*sigma));
	}
	unittest
	{
		import std.math : approxEqual;

		assert(approxEqual(gaussian(3., 1., 3), 1));
		immutable double a = sqrt(log(4));
		assert(approxEqual(gaussian(3. - a, 1., 3), 0.5));
		assert(approxEqual(gaussian(3., 1., 50), 0.));
	}

	static double
	cosine(in double l, in double r, in size_t j) pure @safe
	in {
		assert(l < r);
	}
	body
	{
		return 1 - cos(2*PI * ((j - l)/(r - l)));
	}
	unittest
	{
		import std.math : approxEqual;

		assert(approxEqual(cosine(1., 3., 1), 0.));
		assert(approxEqual(cosine(1., 3., 2), 2.));
		assert(approxEqual(cosine(1., 3., 3), 0.));

		assert(approxEqual(cosine(1., 5., 2), 1.));
		assert(approxEqual(cosine(1., 5., 4), 1.));
	}


	/++ Generate an array of the frequencies for each note +/
	static double[] genFreqs() pure @safe
	{
		double[] freqs = new double[10 * 12];

		/* pow cannot be used in CTFE, so use a literal value instead */
		immutable double nextNote = 1.05946309435929;

		freqs[0] = 16.352; /* C0 */
		for(uint i = 1; i < freqs.length; i++)
			freqs[i] = freqs[i-1] * nextNote;

		return freqs;
	}
	unittest
	{
		import std.math : approxEqual;

		auto freqs = genFreqs();

		assert(approxEqual(freqs[9 + 12 * 4], 440)); /* A4 */
		assert(approxEqual(2*freqs[23], freqs[23 + 12]));
	}
}
