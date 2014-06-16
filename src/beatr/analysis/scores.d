import chroma.chromabands;
import chroma.chromaprofile;
import util.note;
import util.beatr;

import std.stdio;
import std.conv : to;
import std.array;

enum CorrelationMethod {
	PEARSON,
	COSINE,
};

/++ Describe how the adjust the score for each key after using a
 + ChromaProfile
 +/
enum MatchingType {
	CLASSIC      = 0, /++ Just use the score from the ChromaProfile +/
	ADD_SUBDOM   = 0x01, /++ Add the score of the subdominant to each key +/ 
	ADD_DOMINANT = 0x02, /++ Idem, for the dominant +/
	ADD_RELATIVE = 0x04, /++ Idem, for the relative key +/
	DOMINANT     = ADD_DOMINANT, /++ Only add the dominant +/
	CADENCE      = ADD_DOMINANT | ADD_SUBDOM, /++ Add both the dominant and
											   + the sub-dominant +/
	/++ Add the dominant, the sub-dominant and the relative +/
	ALL          = ADD_DOMINANT | ADD_SUBDOM | ADD_RELATIVE,
}

/++
 + Class computing the score for every possible key
 +/
class Scores
{
private:
	double[12 * 2] scores;
	double marginScore;

public:
	/++ Compute the scores of each key
	 + Params: b = a ChromaBands object for the score of each note
	 +         p = the profile to use against our chroma bands
	 +         m = the post-processing algorithm of the scores
	 +/
	this(in ChromaBands b, in ChromaProfile p, in CorrelationMethod cm,
		 in MatchingType m)
	{
		compute(b, p, cm, m);
	}

	Note bestKey()
	{
		/* find max and secondmax */
		double max = 0.;
		ulong imax;
		double secondmax = 0.;
		foreach(j, s; scores) {
			if (s > max) {
				secondmax = max;
				max = s;
				imax = j;
			} else if (s > secondmax)
				secondmax = s;
		}

		marginScore = (max - secondmax)*100 / secondmax;

		/* return best match */
		return new Note(to!int(imax % 12), to!int(imax / 12));
	}

	@property auto confidence()
	{
		if (marginScore == double.nan)
			bestKey();
		return marginScore;
	}

	/++ print an histogram of the bands
	 + Params: height = the height of the histograms
	 +/
	void printHistograms(in uint height) const
	{
		double m = 0;
		foreach(s; scores)
			if (s >= m)
				m = s;

		auto step = m/height;

		/* print the histograms */
		foreach(i; 0 .. (height + 1)) {
			foreach(s; scores) {
				if (s >= (height - i) * step)
					write('X');
				else
					write(' ');
			}
			writeln();
		}

		/* print the notes names */
		foreach(i; 0 .. scores.length) {
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

		/* print major or minor */
		writeln("major       minor");
	}

private:
	void reset()
	{
		scores[] = 0.0;
		marginScore = double.nan;
	}

	void compute(in ChromaBands b, in ChromaProfile p, in CorrelationMethod cm,
				 in MatchingType m)
	{
		reset();

		/* compute score from the profile */
		foreach (i; 0 .. 12)
			scores[i] = computeKeyScore(b, p[0][i], cm);
		foreach (i; 12 .. 24)
			scores[i] = computeKeyScore(b, p[1][i - 12], cm);

		/* adjust the scores from the matching type */
		adjustScores(scores, m);

		Beatr.writefln(Lvl.DEBUG, "Scores for each note: %s", scores);
	}

	/* compute a score multiplying each band with its profile coeff */
	static double
	computeKeyScore(inout double[] bands, inout double[] profile,
					in CorrelationMethod cm) pure nothrow
	in
	{
		assert(profile.length == 12);
	}
	body
	{
		final switch(cm) {
		case CorrelationMethod.PEARSON:
			return pearson(bands, profile);
		case CorrelationMethod.COSINE:
			return cosine(bands, profile);
		}
	}

	static double
	pearson(inout double[] bands, inout double[] profile) pure nothrow
	{
		/* mean of the profile vector */
		double pmean = 0.;
		foreach (p; profile)
			pmean += p;
		pmean /= profile.length;

		/* mean of the bands vector */
		double bmean = 0.;
		foreach (b; bands)
			bmean += b;
		bmean /= bands.length;

		/* result = E((x-xbar)*(y-ybar))/(sigma_x*sigma_y) */
		double bDiff, pDiff;
		double corr = 0., bVariance = 0., pVariance = 0.;
		foreach(j, c; bands) {
			bDiff = c - bmean;
			bVariance += bDiff*bDiff;

			pDiff = profile[j % 12] - pmean;
			pVariance += pDiff*pDiff;

		    corr += bDiff*pDiff;
		}

		if (bVariance > 0 && pVariance > 0)
			corr /= std.math.sqrt(bVariance * pVariance);

		return corr;
	}

	static double
	cosine(inout double[] bands, inout double[] profile) pure nothrow
	{
		/* result = bands.profile/(|bands|*|profile|) */
		double cos = 0., bNorm = 0., pNorm = 0.;
		foreach(i, b; bands) {
			cos += b * profile[i % 12];
			bNorm += b * b;
			pNorm += profile[i % 12] * profile[i % 12];
		}

		if (bNorm > 0. && pNorm > 0.)
			return cos / std.math.sqrt(bNorm * pNorm);
		else
			return 0;
	}

	static void adjustScores(double[] scores, MatchingType m) pure
	{
		ulong idx;
		auto save = scores.idup;

		/* add the score of the relative to each */
		if (m & MatchingType.ADD_RELATIVE) {
			foreach (i; 0 .. 12)
				scores[i] += save[12 + ((i + 9) % 12)];
			foreach (i; 12 .. 24)
				scores[i] += save[((i - 9) % 12)];
		}
		/* add the score of the dominant to each */
		if (m & MatchingType.ADD_DOMINANT) {
			foreach (i; 0 .. 12) {
				idx = (i + 7) % 12;
				scores[i] += save[idx];
				scores[12 + i] += save[12 + idx];
			}
		}
		/* add the score of the dominant to each */
		if (m & MatchingType.ADD_SUBDOM) {
			foreach (i; 0 .. 12) {
				idx = (i + 5) % 12;
				scores[i] += save[idx];
				scores[12 + i] += save[12 + idx];
			}
		}
	}

private:

}