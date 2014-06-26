import chroma.chromabands;
import chroma.chromaprofile;
import util.note;
import util.beatr;

import std.stdio;
import std.conv : to;
import std.array;

version(unittest) {
	import std.string;
}

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

private:
	this() {} /* for unit testing */

public:
	Note bestKey()
	{
		/* find max and secondmax */
		double max = 0.;
		size_t imax;
		double secondmax = 0.;
		foreach(j, s; scores) {
			if (s > max) {
				secondmax = max;
				max = s;
				imax = j;
			} else if (s > secondmax)
				secondmax = s;
		}

		marginScore = (max - secondmax)*100 / max;

		/* return best match */
		return new Note(to!int(imax % 12), to!int(imax / 12));
	}

	@property auto confidence()
	{
		if (std.math.isNaN(marginScore))
			bestKey();
		return marginScore;
	}
	unittest
	{
		auto sc = new Scores();
		sc.scores[] = 0.;
		sc.scores[1] = 4.;
		sc.scores[2] = 3.;

		assert(sc.confidence == 25.);
		assert(sc.bestKey() == new Note(1, 0));

		sc.scores[18] = 4.;
		assert(sc.bestKey() == new Note(1, 0));
		assert(sc.confidence == 0.);
	}

	/++ Returns a histogram of the bands
	 + Params: height = the height of the histograms
	 +/
	void printHistograms(in uint height) const
	{
		printHistograms(height, stdout.lockingTextWriter);
	}

	void printHistograms(Writer)(in uint height, Writer w) const
	{
		double m = 0;
		foreach(s; scores)
			if (s >= m)
				m = s;

		auto step = m/height;

		/* print the histograms */
		foreach(i; 0 .. height) {
			foreach(s; scores) {
				if (s >= (height - i) * step)
					w.put('X');
				else
					w.put(' ');
			}
			w.put('\n');
		}

		/* print the notes names */
		foreach(i; 0 .. scores.length) {
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

		/* print major or minor */
		w.put("major       minor\n");
	}
	unittest
	{
		auto app = appender!string();
		auto sc = new Scores();

		sc.scores[] = [1, 5, 3, 2, 0, 3, 4, 4, 3, 2, 5, 0,
					   0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5];

		sc.printHistograms(5, app);
		assert(-1 != app.data.indexOf(q"EOS
 X        X           XX
 X    XX  X         XXXX
 XX  XXXX X       XXXXXX
 XXX XXXXXX     XXXXXXXX
XXXX XXXXXX   XXXXXXXXXX
EOS"
				   ));
	}


/+
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
+/
private:
	void reset()
	{
		scores[] = 0.0;
		marginScore = double.nan;
	}

	void compute(in ChromaBands bands, in ChromaProfile p,
				 in CorrelationMethod cm, in MatchingType m)
	{
		reset();

		auto b = bands.normalize;
		/* compute score from the profile */
		foreach (i; 0 .. 12)
			scores[i] = computeKeyScore(b, p[0][i], cm);
		foreach (i; 12 .. 24)
			scores[i] = computeKeyScore(b, p[1][i - 12], cm);

		/* adjust the scores from the matching type */
		adjustScores(scores, m);

		Beatr.writefln(Lvl.VERBOSE, "Scores for each note: %s", scores);
	}

	/* compute a score multiplying each band with its profile coeff */
	static double
	computeKeyScore(inout double[] bands, inout double[] profile,
					in CorrelationMethod cm) pure nothrow
	body
	{
		final switch(cm) {
		case CorrelationMethod.PEARSON:
			return pearson(bands, profile);
		case CorrelationMethod.COSINE:
			return cosine(bands, profile);
		}
	}
	unittest
	{
		import std.math : approxEqual;

		double[] a = [5., 2., -1., 8., 7., 0., 2.];
		double[] b = [3., -4, 2, -0.5, 0., 3., -0.5];

		assert(approxEqual(computeKeyScore(a, b, CorrelationMethod.PEARSON),
							0.) == false);
		assert(approxEqual(computeKeyScore(a, b, CorrelationMethod.COSINE),
							0.) == true);
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
	unittest
	{
		import std.math : approxEqual;

		double[] a = [3., 5., 1.];
		auto ma = a.map!(a => -a).array;
		double[] b = [1., 1., 1.];

		assert(approxEqual(pearson(a, a), 1));
		assert(approxEqual(pearson(a, ma), -1));
		assert(approxEqual(pearson(a, b), 0));
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
	unittest
	{
		import std.math : approxEqual;

		double[] a = [5., 2., -1., 8., 7., 0., 2.];
		auto ma = a.map!(a => -a).array;
		double[] b = [3., -4, 2, -0.5, 0., 3., -0.5];

		assert(approxEqual(cosine(a, a), 1));
		assert(approxEqual(cosine(a, ma), -1));
		assert(approxEqual(cosine(a, b), 0));
		assert(approxEqual(cosine([0., 0., 0.], [0., 0., 0.]), 0));
	}

	static void adjustScores(double[] scores, MatchingType m) pure
	{
		size_t idx;
		auto save = scores.idup;

		/* add the score of the relative to each */
		if (m & MatchingType.ADD_RELATIVE) {
			foreach (i; 0 .. 12)
				scores[i] += save[12 + ((i + 9) % 12)];
			foreach (i; 12 .. 24)
				scores[i] += save[((i - 3) % 12)];
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
	unittest
	{
		import std.algorithm : equal;
		import std.math : approxEqual;

		double[] s = [1., 2., 4., 8., 16., 32., 64.,
                      128., 256., 512., 1024., 2048.,
					  0., 1., 2., 4., 8., 16., 32.,
                      64, 128., 256., 512., 1024.];
		double[] dom = s[7  .. 12] ~ s[0  ..  7] ~ s[19 .. 24] ~ s[12 .. 19];
		double[] rel = s[21 .. 24] ~ s[12 .. 21] ~ s[9  .. 12] ~ s[0  ..  9];
		double[] sub = s[5  .. 12] ~ s[0  ..  5] ~ s[17 .. 24] ~ s[12 .. 17];
		auto t = s.dup;

		auto res = s.dup;
		t[] = s[];
		adjustScores(res, MatchingType.CLASSIC);
		assert(equal!approxEqual(res, t));

		res = s.dup;
		t[] = s[] + dom[];
		adjustScores(res, MatchingType.ADD_DOMINANT);
		assert(equal!approxEqual(res, t));

		res = s.dup;
		t[] = s[] + sub[];
		adjustScores(res, MatchingType.ADD_SUBDOM);
		assert(equal!approxEqual(res, t));

		res = s.dup;
		t[] = s[] + rel[];
		adjustScores(res, MatchingType.ADD_RELATIVE);
		assert(equal!approxEqual(res, t));

		res = s.dup;
		t[] = s[] + dom[];
		adjustScores(res, MatchingType.DOMINANT);
		assert(equal!approxEqual(res, t));

		res = s.dup;
		t[] = s[] + dom[] + sub[];
		adjustScores(res, MatchingType.CADENCE);
		assert(equal!approxEqual(res, t));

		res = s.dup;
		t[] = s[] + dom[] + sub[] + rel[];
		adjustScores(res, MatchingType.ALL);
		assert(equal!approxEqual(res, t));
	}
}
