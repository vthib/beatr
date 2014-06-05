import util.types;

import std.algorithm : map;
import std.stdio;

/* XXX: because of writefln functions... */
//@safe:

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
	this()
	{
		bands[] = 0.0;
	}

	@property auto getBands() const nothrow
	{
		return bands;
	}
	alias getBands this;

	/* XXX: if too much add, bands can overflow
	 * solution: track max at all time, divide all when reach threshold? */

	/++ Use an array representing a FFT analysis to fill the chroma bands
	 + Params: s = an array of a FFT analysis.
	 +/
	void addFftSample(double[] s) nothrow
	{
		/* indexes of each note in the FFT array */
		auto chromaidx = freqs.map!(f => cast(int) (f * s.length /
													beatrSampleRate));

		int note;
		int j1, j2;
		foreach(i, f; freqs) {

			/* for each band, computes the mean of the values around its
			   index (to compensate the note frequencies not being perfectly
			   equals to the FFT frequencies */
			j1 = (i != 0) ? (chromaidx[i-1] - chromaidx[i])/2 : 0;
			j2 = (i < freqs.length - 1) ? (chromaidx[i+1] - chromaidx[i])/2 : 0;

			bands[i] = 0.;
			for (long k = j1; k <= j2; k++)
				bands[i] += s[chromaidx[i] + k];
			bands[i] /= (j2 - j1 + 1);
//			bands[i] += s[chromaidx[i]];

			note++;
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
	/++ Generate an array of the frequencies for each note +/
	static double[] genFreqs() pure
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
