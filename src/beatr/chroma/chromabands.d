import std.algorithm : max, min;
import std.exception : enforce;
import std.string : format;
import std.range : assumeSorted;
import std.conv: to;
import std.stdio : stdout;
version(unittest) {
	import std.string : appender, indexOf;
}

import util.beatr;
import util.window;

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

	/* pow cannot be used in CTFE, so use a literal value instead */
	enum nextNote = 1.05946309435929; /* sqrt(2, 12) */
	enum freqs = genFreqs(); /++ the frequencies for each note +/

public:
	this(in ubyte numscales, in ubyte offsetscales, in uint dur = 0)
	in {
		assert(0 <= numscales && numscales <= 10);
		assert(offsetscales <= 10);
		assert(offsetscales + numscales - 1 <= 10);
	}
	body {
		offset = offsetscales;
		duration = dur;

		curf = 0;
		version(with_duration) {
			bands = new double[][](dur/2 + 1, nbscales * 12);
			foreach (ref b; bands)
				b[] = 0.;
		}

		if (freqs[offset + 12*numscales - 1]
			>= Beatr.fftTransformSize/2) {
			/* consider the last frequency admissible */
			auto lastfreq = Beatr.fftTransformSize/2;
			auto fs = assumeSorted(freqs);
			/* we compute the index of the frequency of the highest note
			   possible (length of the subarray inferior to lastfreq) */
			int lastscale = to!int(fs.lowerBound(lastfreq).length / 12);
			nbscales = to!ubyte((lastscale > offset) ? lastscale - offset : 0);

			Beatr.writefln(Lvl.WARNING, "Maximum frequency considered greater "
						   "than the Nyquist frequency of the fft "
						   "transformation. Replacing number of scales with "
						   "%s.", nbscales);
		} else
			nbscales = numscales;

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

		auto cb = new ChromaBands(1, 1);
		cb.bands ~= [1, 2, 3];
		cb.bands ~= [4, 5];
		assert(equal(cb.getBands, [[1, 2, 3], [4, 5]]));
	}
	alias getBands this;

	auto normalize() const nothrow @safe
	{
		double[] n = new double[12];
		immutable auto firstoffset = (offset == 0) ? 9 : 0;

		n[] = 0.;
		foreach(b; bands)
			foreach(i; firstoffset .. b.length)
				n[i % 12] += b[i];

		/* coefficient to get back to the same dimension */
		auto s = new size_t[12];
		s[] = nbscales * bands.length;
		foreach(i; 0 .. firstoffset)
			s[i] = (nbscales - 1) * bands.length;
		foreach(i; firstoffset .. s.length)
			s[i] = nbscales * bands.length;

		foreach(i, ref a; n)
			a /= s[i];

		return n;
	}
	unittest
	{
		import std.algorithm : equal;
		import std.math : approxEqual;

		auto cb = new ChromaBands(2, 1);
		cb.bands ~= [1, 2, 3];
		cb.bands ~= [4, 5];
		assert(equal!approxEqual(cb.normalize, [1.25, 1.75, 0.75, 0., 0., 0.,
												0., 0., 0., 0., 0., 0.]));

		cb = new ChromaBands(2, 1);
		cb.bands ~= [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12,
					 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1];
		cb.bands ~= [5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
					 8, 8, 8, 3, 8, 8, 2, 8, 8, 0, 8, 8];
		assert(equal!approxEqual(cb.normalize, [6.5, 6.5, 6.5, 5.25, 6.5, 6.5,
												5., 6.5, 6.5, 4.5, 6.5, 6.5]));

		/* test that it starts from A0, not C0 */
		cb = new ChromaBands(2, 0);
		cb.bands ~= [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12,
					 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1];
		cb.bands ~= [5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
					 8, 8, 8, 3, 8, 8, 2, 8, 8, 0, 8, 8];
		assert(equal!approxEqual(cb.normalize, [10., 9.5, 9., 6., 8., 7.5,
												4., 6.5, 6., 4.5, 6.5, 6.5]));
	}

	/++ Use an array representing a FFT analysis to fill the chroma bands
	 + Params: s = an array of a FFT analysis.
	 +/
	void addFftSample(in double[] s) //@safe
	body {
		/* indexes of each note in the FFT array */
		auto fscales = freqs[offset*12 .. ((offset + nbscales) * 12)];

		enforce(fscales[$ - 1] < s.length,
				format("Sample provided (%s) too small for the frequencies "
					   "considered (<= %s).", s.length, fscales[$ - 1]));

		/* bands of the sample */
		double[] b = new double[nbscales * 12];

		/* boundaries of the window */
		size_t begin;
		size_t end;

		/* Q is equal to sigma*(sqrt(2, 12) - 1)
		 * Thus mu_(i) * Q = mu_(i+1)*sigma */
		immutable Q = Beatr.fftSigma * (nextNote - 1);

		double sum;
		double coeff;
		foreach(i, f; fscales) {
			/* center of the window is the note frequency */
			auto mu = f * s.length / Beatr.sampleRate;

			if (Q == 0.) {
				b[i] = s[to!(size_t)(mu)];
				continue;
			} else
				b[i] = 0.;

			/* Leftmost bin from which we start to aggregate results */
			auto left = mu*(1 - Q);
			begin = (left < 0.) ? 0 : to!size_t(min(left, mu));
			// XXX bound check for end
			end = to!size_t(max(mu*(1 + Q), mu + 1));
			end = min(end, s.length - 1);
			auto right = mu*(1 + Q);

			/* for every significant abscissa ([mu(1-Q); mu(1+Q)], compute
			   the correlation coeff, add coeff * value, and in the end
			   divide by the sum of the coefficients */
			sum = 0.;

			foreach (j; begin .. (end+1)) {
				if (j < left || j > right)
					continue;
				coeff = window!double(Beatr.fftInterpolationMode, left,
									  right, mu, j, Q);
				sum += coeff;
				b[i] += s[j] * coeff;
			}

			if (sum != 0.)
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
		/* start from A0 and not C0 if offset == 0*/
		immutable firstoffset = (offset == 0) ? 9 : 0;
		double[] b = new double[nbscales * 12 - firstoffset];

		b[] = 0.;
		foreach (t; bands)
			foreach (i; firstoffset .. t.length)
				b[i - firstoffset] += t[i];

		foreach(v; b)
			if (v >= m)
				m = v;

		auto step = m/height;

		/* print the histograms */
		foreach(i; 0 .. height) {
			foreach(v; b) {
				if (v >= (height - i) * step)
					w.put('X');
				else
					w.put(' ');
			}
			w.put('\n');
		}

		/* print the notes names */
		foreach(i; firstoffset .. (b.length + firstoffset)) {
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
		foreach(i; firstoffset .. (b.length + firstoffset)) {
			if (i % 12 == 0 || i == firstoffset)
				w.put(to!string(i / 12 + offset));
			else
				w.put(' ');
		}
		w.put('\n');
	}
	unittest
	{
		/***** test correct behaviour of function *****/
		auto app = appender!string();
		auto cb = new ChromaBands(2, 1);

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
C D EF G A BC D EF G A B
1           2           
EOS"
				   ));

		/***** test that it starts from A0, not C0 *****/
		app = appender!string();
		cb = new ChromaBands(2, 0);

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
   X      X    
 X X      X    
 X X   X  X    
 X X XXX XX XX 
A BC D EF G A B
0  1           
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
		/* start from A0 and not C0 if offset == 0*/
		immutable firstoffset = (offset == 0) ? 9 : 0;
		auto b = new double[12][bands.length];
		foreach(ref t; b)
			t[] = 0.;
		foreach(i, t; bands)
			foreach(j; firstoffset .. t.length)
				b[i][j % 12] += t[j];

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
		/* test correct behaviour of function */
		auto app = appender!string();
		auto cb = new ChromaBands(2, 1);

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

		/* test that it starts from A0 not C0 */
		app = appender!string();
		cb = new ChromaBands(1, 0);

		/* double Cmaj chord */
		cb.bands ~= [3, 0, 0, 0, 1, 0, 0, 2, 0, 0, 0, 0];
		/* single Ebmin chord */
		cb.bands ~= [0, 0, 0, 4, 0, 0, 2, 0, 0, 0, 3, 0];
		/* high Gmin harmonic scale */
		cb.bands ~= [1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 1, 0];

		cb.printChromagram(app);
		assert(-1 != app.data.indexOf(
				   "C    \n     \nD    \n     \nE    \nF    \n"
				   "     \nG    \n     \nA   -\n   #-\nB    \n"));
	}

private:
	/++ Generate an array of the frequencies for each note +/
	static double[] genFreqs() pure @safe
	{
		double[] freqs = new double[10 * 12];

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
