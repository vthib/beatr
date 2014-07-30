import std.math : isNaN, sqrt;
version(unittest) {
	import std.math : approxEqual;
	import std.algorithm : equal, map;
	import std.array : array;
	import std.string : appender, indexOf;
}

import chroma.chromabands;
import chroma.chromaprofile;
import util.note;
import util.beatr;

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
	this(in ChromaBands b, in ChromaProfile p, in CorrelationMethod cm)
	{
		compute(b, p, cm, Beatr.adjustType);
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

		if (max != 0.)
			marginScore = (max - secondmax)*100 / max;
		else
			marginScore = 0.;

		/* return best match */
		return new Note(to!int(imax % 12), to!int(imax / 12));
	}

	@property auto confidence()
	{
		if (isNaN(marginScore))
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
		double M = -double.max;
		double m = double.max;

		foreach(s; scores) {
			if (s >= M)
				M = s;
			if (s <= m)
				m = s;
		}

		auto step = (M - m)/height;

		/* print the histograms */
		foreach(i; 1 .. (height+1)) {
			foreach(s; scores) {
				if (s > (height - i) * step + m)
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

private:
	void reset()
	{
		scores[] = 0.0;
		marginScore = double.nan;
	}

	void compute(in ChromaBands bands, in ChromaProfile p,
				 in CorrelationMethod cm, in AdjustmentType m)
	{
		reset();

		Beatr.writefln(Lvl.verbose, "Using correlation method %s "
					   "and adjustment type %s", cm, m);

		auto b = bands.normalize;
		/* compute score from the profile */
		foreach (i; 0 .. 12)
			scores[i] = computeKeyScore(b, p[0][i], cm);
		foreach (i; 12 .. 24)
			scores[i] = computeKeyScore(b, p[1][i - 12], cm);

		/* adjust the scores from the matching type */
		adjustScores(scores, m);

		Beatr.writefln(Lvl.verbose, "Scores for each note: %s", scores);
	}

	/* compute a score multiplying each band with its profile coeff */
	static double
	computeKeyScore(inout double[] bands, inout double[] profile,
					in CorrelationMethod cm) pure nothrow
	body
	{
		final switch(cm) {
		case CorrelationMethod.cosine:
			return cosine(bands, profile);
		case CorrelationMethod.pearson:
			return pearson(bands, profile);
		}
	}
	unittest
	{
		double[] a = [5., 2., -1., 8., 7., 0., 2.];
		double[] b = [3., -4, 2, -0.5, 0., 3., -0.5];

		assert(approxEqual(computeKeyScore(a, b, CorrelationMethod.pearson),
							0.) == false);
		assert(approxEqual(computeKeyScore(a, b, CorrelationMethod.cosine),
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
			corr /= sqrt(bVariance * pVariance);

		return corr;
	}
	unittest
	{
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
			return cos / sqrt(bNorm * pNorm);
		else
			return 0;
	}
	unittest
	{
		double[] a = [5., 2., -1., 8., 7., 0., 2.];
		auto ma = a.map!(a => -a).array;
		double[] b = [3., -4, 2, -0.5, 0., 3., -0.5];

		assert(approxEqual(cosine(a, a), 1));
		assert(approxEqual(cosine(a, ma), -1));
		assert(approxEqual(cosine(a, b), 0));
		assert(approxEqual(cosine([0., 0., 0.], [0., 0., 0.]), 0));
	}

	/* XXX experiment with different coefficients for each addition,
	 * e.g. 0.5 for add_dominant, 0.3 for add_relative, ... */
	static void adjustScores(double[] scores, AdjustmentType m)
	{
		size_t idx;
		auto save = scores.idup;
		double c;

		Beatr.writefln(Lvl.debug_, "Adjusting scores using matching type %s "
					   "and coefficients %s", m, Beatr.mCoefficients);

		/* add the score of the dominant to each */
		if (m & AdjustmentType.addDom) {
			foreach (i; 0 .. 12) {
				c = Beatr.mCoefficients[0];
				idx = (i + 7) % 12;
				scores[i] +=  c * save[idx];
				scores[12 + i] += c * save[12 + idx];
			}
		}
		/* add the score of the sub-dominant to each */
		if (m & AdjustmentType.addSubdom) {
			foreach (i; 0 .. 12) {
				c = Beatr.mCoefficients[1];
				idx = (i + 5) % 12;
				scores[i] += c * save[idx];
				scores[12 + i] +=  c * save[12 + idx];
			}
		}
		/* add the score of the relative to each */
		if (m & AdjustmentType.addRel) {
			c = Beatr.mCoefficients[2];
			foreach (i; 0 .. 12)
				scores[i] += c * save[12 + ((i + 9) % 12)];
			foreach (i; 12 .. 24)
				scores[i] += c * save[((i - 3) % 12)];
		}
	}
	unittest
	{
		double[] s = [1., 2., 4., 8., 16., 32., 64.,
                      128., 256., 512., 1024., 2048.,
					  0., 1., 2., 4., 8., 16., 32.,
                      64, 128., 256., 512., 1024.];
		double[] dom = s[7  .. 12] ~ s[0  ..  7] ~ s[19 .. 24] ~ s[12 .. 19];
		double[] rel = s[21 .. 24] ~ s[12 .. 21] ~ s[9  .. 12] ~ s[0  ..  9];
		double[] sub = s[5  .. 12] ~ s[0  ..  5] ~ s[17 .. 24] ~ s[12 .. 17];
		auto t = s.dup;

		auto csave = Beatr.mCoefficients();
		Beatr.mCoefficients = [1., 1., 1.];

		auto res = s.dup;
		t[] = s[];
		adjustScores(res, AdjustmentType.none);
		assert(equal!approxEqual(res, t));

		res = s.dup;
		t[] = s[] + dom[];
		adjustScores(res, AdjustmentType.addDom);
		assert(equal!approxEqual(res, t));

		res = s.dup;
		t[] = s[] + sub[];
		adjustScores(res, AdjustmentType.addSubdom);
		assert(equal!approxEqual(res, t));

		res = s.dup;
		t[] = s[] + rel[];
		adjustScores(res, AdjustmentType.addRel);
		assert(equal!approxEqual(res, t));

		res = s.dup;
		t[] = s[] + dom[];
		adjustScores(res, AdjustmentType.dominant);
		assert(equal!approxEqual(res, t));

		res = s.dup;
		t[] = s[] + dom[] + sub[];
		adjustScores(res, AdjustmentType.cadence);
		assert(equal!approxEqual(res, t));

		res = s.dup;
		t[] = s[] + dom[] + sub[] + rel[];
		adjustScores(res, AdjustmentType.all);
		assert(equal!approxEqual(res, t));

		Beatr.mCoefficients = [0.5, 0.3, 0.2];
		res = s.dup;
		t[] = s[] + 0.5*dom[] + 0.3*sub[] + 0.2*rel[];
		adjustScores(res, AdjustmentType.all);
		assert(equal!approxEqual(res, t));

		Beatr.mCoefficients = csave;
	}
}
