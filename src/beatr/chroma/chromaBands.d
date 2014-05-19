import chroma.profile.chromaProfile;
import util.key;

import std.math : pow;
import std.algorithm;
import std.array;

enum nbScales = 10;

alias double[] beatrBands;

class chromaBands
{
	beatrBands bands;
	int sampleRate;
	enum freqs = genFreqs();

public:
	this(int sampleRate)
	{
		bands = new double[nbScales * 12];
		this.sampleRate = sampleRate;
	}

	/* XXX: can only add once */
	void addFftSample(double[] s)
	{
		auto chromaidx = freqs.map!(f => cast(int) (f * s.length / sampleRate));

		int note;
		int j1, j2;
		foreach(i, f; freqs) {
			j1 = (i != 0) ? (chromaidx[i-1] - chromaidx[i])/2 : 0;
			j2 = (i < freqs.length - 1) ? (chromaidx[i+1] - chromaidx[i])/2 : 0;

			bands[i] = 0.;
			for (long k = j1; k <= j2; k++)
				bands[i] += s[chromaidx[i] + k];
			bands[i] /= (j2 - j1 + 1);

			debug {
				std.stdio.writefln("%s%s\t%.3e\t%s\t%s", key.name(note % 12), note / 12,
								   f, chromaidx[i], bands[i]);
			}

			note++;
		}
	}

	key bestFit(chromaProfile p) const
	{
		std.stdio.writeln(p);

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

		debug {
			std.stdio.writeln(scores);
		}

		foreach(i, s; scores) {
			if (s == best)
				return new key(i);
		}

		throw new Exception("impossible!");
	}

private:
	static double[] genFreqs()
	{
		double[] freqs = new double[12*10];
		immutable double nextNote = 1.05946309436;
		// XXX: verify equals to pow(2, (1.0/12.0));

		freqs[0] = 16.352; /* C0 */
		for(uint i = 1; i < freqs.length; i++)
			freqs[i] = freqs[i-1] * nextNote;

		return freqs;
	}
}
