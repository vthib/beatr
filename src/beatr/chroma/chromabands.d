import util.types;
import util.beatr;

import std.algorithm : map, max, min;
import std.stdio;
import std.conv: to;
import std.math;

version(unittest) {
	import std.array;
	import std.string;
}

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
	this(in ubyte numscales, in ubyte offsetscales, in uint dur = 0)
	in {
		assert(1 <= numscales && numscales <= 10);
		assert(offsetscales <= 10);
		assert(offsetscales + numscales - 1 <= 10);
	}
	body {
		nbscales = numscales;
		offset = offsetscales;
		duration = dur;

		curf = 0;
		version(with_duration) {
			bands = new double[][](dur/2 + 1, nbscales * 12);
			foreach (ref b; bands)
				b[] = 0.;
		}

		Beatr.writefln(Lvl.DEBUG, "using mode '%s' and sigma '%s'",
					   Beatr.fftInterpolationMode, Beatr.fftSigma);
		Beatr.writefln(Lvl.DEBUG, "Analyzing between C%s and C%s",
					   Beatr.scaleOffset,
					   Beatr.scaleOffset + Beatr.scaleNumbers);
	}

	@property auto getBands() const nothrow @safe
	{
		return bands;
	}
	unittest
	{
		import std.algorithm : equal;

		auto cb = new ChromaBands(10, 0);
		cb.bands ~= [1, 2, 3];
		cb.bands ~= [4, 5];
		assert(equal(cb.getBands, [[1, 2, 3], [4, 5]]));
	}
	alias getBands this;

	auto normalize() const nothrow @safe
	{
		double[] n = new double[12];

		n[] = 0.;
		foreach(b; bands)
			foreach(i, v; b)
				n[i % 12] += v;
		auto s = nbscales * bands.length;
		foreach(ref a; n)
			a /= s;

		return n;
	}
	unittest
	{
		import std.algorithm : equal;
		import std.math : approxEqual;

		auto cb = new ChromaBands(10, 0);
		cb.bands ~= [1, 2, 3];
		cb.bands ~= [4, 5];
		assert(equal!approxEqual(cb.normalize, [0.25, 0.35, 0.15, 0., 0., 0.,
												0., 0., 0., 0., 0., 0.]));

		cb = new ChromaBands(2, 0);
		cb.bands ~= [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12,
					 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1];
		cb.bands ~= [5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
					 8, 8, 8, 3, 8, 8, 2, 8, 8, 0, 8, 8];
		assert(equal!approxEqual(cb.normalize, [6.5, 6.5, 6.5, 5.25, 6.5, 6.5,
												5., 6.5, 6.5, 4.5, 6.5, 6.5]));
	}

	/++ Use an array representing a FFT analysis to fill the chroma bands
	 + Params: s = an array of a FFT analysis.
	 +/
	void addFftSample(in double[] s) //@safe
	body {
		/* indexes of each note in the FFT array */
		auto fscales = freqs[offset*12 .. ((offset + nbscales) * 12)];
		double[] b = new double[nbscales * 12];
		b[] = 0.;

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

		version(with_duration) {
			bands[curf++ / 2][] += b[];
		} else {
			if (curf++ % 2 == 0)
				bands ~= b;
			else
				bands[$ - 1][] += b[];
		}
	}
	/* XXX unittest? */

	/++ print an histogram of the bands
	 + Params: height = the height of the histograms
	 +/
	void printHistograms(in uint height) const
	{
		printHistograms(height, stdout.lockingTextWriter);
	}

	void printHistograms(Writer)(in uint height, Writer w) const
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
					w.put('X');
				else
					w.put(' ');
			}
			w.put('\n');
		}

		/* print the notes names */
		foreach(i; 0 .. b.length) {
			switch (i % 12) {
			case 0: w.put('C'); break;
			case 2: w.put('D'); break;
			case 4: w.put('E'); break;
			case 5: w.put('F'); break;
			case 7: w.put('G'); break;
			case 9: w.put('A'); break;
			case 11: w.put('B'); break;
			default: w.put(' '); break;
			}
		}
		w.put('\n');

		/* print the scales numbers */
		foreach(i; 0 .. b.length) {
			if (i % 12 == 0)
				w.put(to!string(i / 12 + offset));
			else
				w.put(' ');
		}
		w.put('\n');
	}
	unittest
	{
		auto app = appender!string();
		auto cb = new ChromaBands(2, 0);

		/* double Cmaj chord */
		cb.bands ~= [4, 0, 0, 0, 2, 0, 0, 3, 0, 0, 0, 0,
					 4, 0, 0, 0, 2, 0, 0, 3, 0, 0, 0, 0];
		/* single Ebmin chord */
		cb.bands ~= [0, 0, 0, 4, 0, 0, 2, 0, 0, 0, 3, 0,
					 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
		/* high Gmin harmonic scale */
		cb.bands ~= [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
					 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 1, 0];

		cb.printHistograms(5, app);
		assert(-1 != app.data.indexOf(q"EOS
            X           
X  X        X      X    
X  X   X  X X      X    
X  XX XX  X X   X  X    
X  XX XX  X X XXX XX XX 
EOS"
				   ));
	}

	/++ print a Chromagram
	 +/
	void printChromagram() const
	{
		printChromagram(stdout.lockingTextWriter);
	}

	void printChromagram(Writer)(Writer w) const
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
			case  0: w.put("C "); break;
			case  2: w.put("D "); break;
			case  4: w.put("E "); break;
			case  5: w.put("F "); break;
			case  7: w.put("G "); break;
			case  9: w.put("A "); break;
			case 11: w.put("B "); break;
			default: w.put("  "); break;
			}
			foreach (i; 0 .. b.length) {
				if (b[i][j] < max/6)
					w.put(" ");
				else if (b[i][j] <= max/3)
					w.put("-");
				else if (b[i][j] <= max/2)
					w.put("1");
				else if (b[i][j] <= 2*max/3)
					w.put("x");
				else if (b[i][j] < 5*max/6)
					w.put("Q");
				else
					w.put("#");
			}
			w.put('\n');
		}
	}
	unittest
	{
		auto app = appender!string();
		auto cb = new ChromaBands(2, 0);

		/* double Cmaj chord */
		cb.bands ~= [3, 0, 0, 0, 1, 0, 0, 2, 0, 0, 0, 0,
					 2, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0];
		/* single Ebmin chord */
		cb.bands ~= [0, 0, 0, 4, 0, 0, 2, 0, 0, 0, 3, 0,
					 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
		/* high Gmin harmonic scale */
		cb.bands ~= [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
					 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 1, 0];

		cb.printChromagram(app);
		assert(-1 != app.data.indexOf(
				   "C # -\n     \nD   -\n   Q-\nE 1  \nF    \n"
				   "   1-\nG x -\n     \nA   -\n   x-\nB    \n"));
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
