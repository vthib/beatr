import util.types;

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
	enum NB_SCALES = 10;

	/* 12 semitons times number of scales = number of notes considered */
	double[NB_SCALES * 12] bands; /++ the chroma bands +/

	enum freqs = genFreqs(); /++ the frequencies for each note +/

public:
	this() @safe
	{
		bands[] = 0.0;
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
	void addFftSample(in double[] s, in double sigma) //XXX@safe
	in {
		assert(sigma >= 0);
	}
	body {
		/* indexes of each note in the FFT array */
		auto chromaidx = freqs.map!(f => cast(int) (f * s.length /
													beatrSampleRate));
		double mu;
		ulong begin, end;

		foreach(i, f; freqs) {
			/* center of the gaussian is the note frequency */
			mu = f * s.length / beatrSampleRate;
			/* we compute from -3*sigma to +3*sigma to get 99.5% of the value */
			if (mu - 3*sigma < 0.)
				begin = 0;
			else
				begin = to!ulong(mu - 3*sigma);
			end = to!ulong(mu + 3*sigma + 1.);

			foreach (j; begin .. end)
				bands[i] += s[j] * gaussian(mu, sigma, j);
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
				write(i / 12);
			else
				write(' ');
		}
		writeln();
	}

private:
	static double
	gaussian(in double mu, in double sigma, in ulong x) //pure //XXX @safe
	{
		if (sigma == 0.)
			return (x == (cast(ulong) mu));
		else
			return exp(-((x - mu)*(x-mu))/(2*sigma*sigma));
	}

	/++ Generate an array of the frequencies for each note +/
	static double[] genFreqs() pure @safe
	{
		double[] freqs = new double[NB_SCALES * 12];

		/* pow cannot be used in CTFE, so use a literal value instead */
		immutable double nextNote = 1.05946309435929;

		freqs[0] = 16.352; /* C0 */
		for(uint i = 1; i < freqs.length; i++)
			freqs[i] = freqs[i-1] * nextNote;

		return freqs;
	}
}
