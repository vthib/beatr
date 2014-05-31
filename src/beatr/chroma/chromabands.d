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
private:
enum nbScales = 10;

alias double band;
alias band[nbScales * 12] beatrBands;

/++
 + Chroma bands represents an histogram of the intensity of each note.
 +/
public:
class ChromaBands
{
private:
	/* 12 semitons times number of scales = number of notes considered */
	beatrBands bands; /++ the chroma bands +/
	enum freqs = genFreqs(); /++ the frequencies for each note +/
	double marginScore;

	invariant() {
		assert(beatrBands.length == nbScales * 12);
	}

public:
	this()
	{
		bands[] = 0.0;
	}

	/* XXX: if too much add, bands can overflow
	 * solution: track max at all time, divide all when reach threshold? */

	/++ Use an array representing a FFT analysis to fill the chroma bands
	 + Params: s = an array of a FFT analysis.
	 +/
	void addFftSample(double[] s) nothrow
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
			bands[i] += s[chromaidx[i]];

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
	Note bestFit(in ChromaProfile p)
	{
		/* compute a score multiplying each band with its profile coeff */
		auto combineBandsAndProfile(inout typeof(p[0]) profile)
		{
			band s = 0.;

			std.exception.enforce(profile.length >= 12);

			foreach(j, c; bands)
				s += c*profile[j % 12];

			return s / bands.length;
		}

		auto scores = array(p.getProfile.map!(combineBandsAndProfile));

		Beatr.writefln(BEATR_DEBUG, "Scores for each note: %s", scores);

		/* find max and secondmax */
		band max = 0.;
		ulong imax;
		band secondmax = 0.;
		foreach(j, s; scores) {
			if (s > max) {
				secondmax = max;
				max = s;
				imax = j;
			} else if (s > secondmax)
				secondmax = s;
		}

		marginScore = (max - secondmax)*100 / secondmax;

		Beatr.writefln(BEATR_DEBUG, "Best estimate %.2f%% better than next one",
					   marginScore);

		/* return best match */
		return new Note(imax % 12);
	}

	/++ print an histogram of the bands
	 + Params: height = the height of the histograms
	 +/
	void printHistograms(in uint height) const
	{
		// auto m = bands.reduce!(max); XXX: need update of compiler?
		band m = 0;
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

	@property auto confidence() const
	{
		return marginScore;
	}

private:
	/++ Generate an array of the frequencies for each note +/
	static double[] genFreqs()
	{
		double[] freqs = new double[12*nbScales];

		/* pow cannot be used in CTFE, so use a literal value instead */
		immutable double nextNote = 1.05946309435929;

		freqs[0] = 16.352; /* C0 */
		for(uint i = 1; i < freqs.length; i++)
			freqs[i] = freqs[i-1] * nextNote;

		return freqs;
	}
}
