import util.types;
import util.beatr;

import std.algorithm : map;
import std.stdio;
import std.conv: to;
import std.math : exp;

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

	/++ Use an array representing a FFT analysis to fill the chroma bands
	 + Params: s = an array of a FFT analysis.
	 +/
	void addFftSample(in double[] s) //@safe
	body {
		/* indexes of each note in the FFT array */
		auto fscales = freqs[offset*12 .. ((offset + nbscales) * 12)];
		auto chromaidx = fscales.map!(f => cast(int) (f * s.length /
													  beatrSampleRate));

		Beatr.writefln(Lvl.DEBUG, "using mode '%s' and sigma '%s'",
					   Beatr.fftInterpolationMode, Beatr.fftSigma);
		Beatr.writefln(Lvl.DEBUG, "Analyzing between C%s and C%s",
					   Beatr.scaleOffset,
					   Beatr.scaleOffset + Beatr.scaleNumbers);

		size_t begin;
		size_t end;

		foreach(i, f; fscales) {
			/* center of the gaussian is the note frequency */
			auto mu = f * s.length / beatrSampleRate;

			final switch (Beatr.fftInterpolationMode) {
			case FFTInterpolationMode.FIXED:
				/* we compute from -3*sigma to +3*sigma to get 99.5% of the value */
				auto left = mu - 3*Beatr.fftSigma;
				begin = (left < 0.) ? 0 : to!ulong(left);
				end = to!ulong(mu + 3*Beatr.fftSigma + 1.);

				/* for every significant abscissa of the gaussian, add the
				   FFT value times the gaussian value */
				foreach (j; begin .. end)
					bands[i] += s[j] * gaussian(mu, Beatr.fftSigma, j);

				break;
			case FFTInterpolationMode.ADAPTIVE:
				/* get the shortest distance from our note index to
				 * a adjacent note */
				auto d = (i == 0) ? chromaidx[i+1] - chromaidx[i]
					              : chromaidx[i]   - chromaidx[i - 1];
				auto sigma = d/2 * Beatr.fftSigma;

				/* idem as before between the adjacent notes */
				begin = (i == 0) ? chromaidx[i] : chromaidx[i-1];
				end = (i == fscales.length - 1) ? chromaidx[i] : chromaidx[i+1];

				foreach (j; begin .. (end + 1))
					bands[i] += s[j] * gaussian(mu, sigma, j);

				break;
			}
		}
	}

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

private:
	static double
	gaussian(in double mu, in double sigma, in ulong x) pure @safe
	{
		if (sigma == 0.)
			return (x == (cast(ulong) mu));
		else
			return (1./(sigma*std.math.sqrt(2*std.math.PI)))*exp(-((x - mu)*(x-mu))/(2*sigma*sigma));
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
}
