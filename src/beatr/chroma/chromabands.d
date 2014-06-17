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

	/* 12 semitons times number of scales = number of notes considered */
	double[] bands; /++ the chroma bands +/

	enum freqs = genFreqs(); /++ the frequencies for each note +/

public:
	this(T)(in T n, in T o) @safe
	in {
		assert(1 <= n && n <= 10);
		assert(o <= 10);
		assert(o + n - 1 <= 10);
	}
	body {
		nbscales = cast(ubyte) n;
		offset = cast(ubyte) o;

		bands = new double[nbscales * 12];
		bands[] = 0.;
	}

	@property auto getBands() const nothrow @safe
	{
		return bands;
	}
	alias getBands this;

	/* XXX: if too much add, bands can overflow
	 * solution: track max at all time, divide all when reach threshold? */

	static T min(T)(T a, T b) { return a < b ? a : b; }
	static T max(T)(T a, T b) { return a > b ? a : b; }

	/++ Use an array representing a FFT analysis to fill the chroma bands
	 + Params: s = an array of a FFT analysis.
	 +/
	void addFftSample(in double[] s) //@safe
	body {
		/* indexes of each note in the FFT array */
		auto fscales = freqs[offset*12 .. ((offset + nbscales) * 12)];

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
			/* center of the gaussian is the note frequency */
			auto mu = f * s.length / beatrSampleRate;

			if (Q == 0.) {
				bands[i] = s[to!ulong(mu)];
				continue;
			}

			/* Leftmost bin from which we start to aggregate results */
			auto left = mu*(1 - Q);
			begin = (left < 0.) ? 0 : min(to!ulong(left), to!ulong(mu));
			// XXX bound check for end
			end = max(to!ulong(mu*(1 + Q)), to!ulong(mu) + 1);
			auto right = mu*(1+Q);

			/* for every significant abscissa of the gaussian, add the
			   FFT value times the gaussian value */
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
				bands[i] += s[j] * coeff;
			}
			if (sum != 0)
				bands[i] /= sum;
		}
	}
	/* XXX unittest? */

	/++ print an histogram of the bands
	 + Params: height = the height of the histograms
	 +/
	void printHistograms(in uint height) const
	{
		double m = 0;
		foreach(b; bands)
			if (b >= m)
				m = b;

		auto step = m/height;

		/* print the histograms */
		foreach(i; 0 .. (height + 1)) {
			foreach(b; bands) {
				if (b >= (height - i) * step)
					write('X');
				else
					write(' ');
			}
			writeln();
		}

		/* print the notes names */
		foreach(i; 0 .. bands.length) {
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
		foreach(i; 0 .. bands.length) {
			if (i % 12 == 0)
				write(i / 12 + offset);
			else
				write(' ');
		}
		writeln();
	}
	/* XXX unittest? */

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

	static double
	cosine(in double l, in double r, in size_t j) pure @safe
	in {
		assert(l < r);
	}
	body
	{
		return 1 - cos(2*PI * ((j - l)/(r - l)));
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
