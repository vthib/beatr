import chroma.profile.chromaprofile;
import util.note;
import util.types;
import util.beatr;

import std.math : pow;
import std.algorithm : map, reduce, max;
import std.array : array;
import std.stdio;

/* XXX: because of writefln functions... */
//@safe:

/++ Number of scales in our chroma bands +/
enum nbScales = 10;

alias double[] beatrBands;

/++
 + Chroma bands represents an histogram of the intensity of each note.
 +/
class ChromaBands
{
private:
	beatrBands bands; /+ the chroma bands +/
	enum freqs = genFreqs(); /+ the frequencies for each note +/

public:
	this()
	{
		/* 12 semitons times number of scales = number of notes considered */
		bands = new double[nbScales * 12];
	}

	/* XXX: can only add once */
	/* XXX: not nothrow because of writefln */
	/++ Use an array representing a FFT analysis to fill the chroma bands
	 + Params: s = an array of a FFT analysis.
	 +/
	void addFftSample(double[] s) //nothrow
	{
		/* indexes of each note in the FFT array */
		auto chromaidx = freqs.map!(f => cast(int) (f * s.length / beatrSampleRate));

		int note;
		int j1, j2;
		foreach(i, f; freqs) {

			/* for each band, computes the mean of the values around its
			   index (to compensate the note frequencies not being perfectly
			   equals to the FFT frequencies */
/+			j1 = (i != 0) ? (chromaidx[i-1] - chromaidx[i])/2 : 0;
			j2 = (i < freqs.length - 1) ? (chromaidx[i+1] - chromaidx[i])/2 : 0;

			bands[i] = 0.;
			for (long k = j1; k <= j2; k++)
				bands[i] += s[chromaidx[i] + k];
			bands[i] /= (j2 - j1 + 1);+/
			bands[i] = s[chromaidx[i]];

			Beatr.writefln(BEATR_DEBUG, "%s%s\t%.3e\t%s\t%s",
						   Note.name(note % 12), note / 12,
						   f, chromaidx[i], bands[i]);


			note++;
		}
	}

	/++ Find the best key possible for our chroma bands using the given profile
	 + Params: p = the profile to use against our chroma bands
	 + Returns: the best key estimate
	 +/
	Note bestFit(in ChromaProfile p) const
	{
		/* compute a score multiplying each band with its profile coeff */
		auto combineBandsAndProfile(inout ubyte[] p)
		{
			double s = 0.;

			std.exception.enforce(p.length >= 12);

			foreach(j, c; bands)
				s += c*p[j % 12];

			return s / bands.length;
		}

		auto scores = array(p.getProfile.map!(combineBandsAndProfile));
		auto best = scores.reduce!(max);

		Beatr.writefln(BEATR_DEBUG, "Scores for each note: %s", scores);

		double secondmax = 0.;
		foreach(s; scores) {
			if (s > secondmax && s != best)
				secondmax = s;
		}

		Beatr.writefln(BEATR_DEBUG, "Best estimate %.2f%% better than next one",
					   (best - secondmax)*100/secondmax);

		foreach(i, s; scores) {
			if (s == best)
				return new Note(i % 12);
		}

		/* XXX: do something better (test equality double can fail?) */
		throw new Exception("impossible!");
	}

	void printHistograms(in uint height) const
	{
		auto m = bands.reduce!(max);
		auto step = m/height;

		foreach(i; 0 .. (height + 1)) {
			foreach(b; bands) {
				if (b >= (height - i) * step)
					write('X');
				else
					write(' ');
			}
			writeln();
		}

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
	static double[] genFreqs()
	{
		double[] freqs = new double[12*nbScales];

		/* pow cannot be used in CTFE, so use a literal value instead */
		/* XXX: get a better literal value of pow(2, 1.0/12.0) */
		immutable double nextNote = 1.05946309436;

		freqs[0] = 16.352; /* C0 */
		for(uint i = 1; i < freqs.length; i++)
			freqs[i] = freqs[i-1] * nextNote;

		return freqs;
	}
}
