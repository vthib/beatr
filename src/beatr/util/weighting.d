module util.weighting;

import std.exception : assumeUnique;
import std.math : log10, sqrt, pow;
import std.string : format;

version(unittest) {
	import std.math : approxEqual;
	import core.exception : AssertError;
	import std.exception : assertThrown;
}

enum WeightCurve {
	A,
	B,
	C,
	ITUR468,
	INVISO226,
	none,
}

class Weighting
{
private:
	immutable double[] weights;

public:
	this(in WeightCurve wc, in size_t size, in double scaling)
	{
		auto w = new double[size];

		double function(double) pure nothrow weight;
		final switch (wc) {
		case WeightCurve.A:
			weight = &aCurve; break;
		case WeightCurve.B:
			weight = &bCurve; break;
		case WeightCurve.C:
			weight = &cCurve; break;
		case WeightCurve.ITUR468:
			weight = null;
			fillITUR468Weight(w, scaling);
			break;
		case WeightCurve.INVISO226:
			weight = null;
			fillInvIsoWeight(w, scaling);
			break;
		case WeightCurve.none:
			weight = (a => 1); break;
		}

		if (weight !is null)
			foreach(i, ref a; w)
				a = weight(i / scaling);

		weights = assumeUnique(w);
	}

	double weight(size_t index) const
	in
	{
		assert(index < weights.length,
			   format("index %s is greater than max %s", index,
					  weights.length - 1));
	}
	body
	{
		return weights[index];
	}
	unittest
	{
		auto aw = new Weighting(WeightCurve.A, 20, 2.);

		assert(approxEqual(aCurve(5.), aw.weight(10)));
		assert(approxEqual(aCurve(7.5), aw.weight(15)));
		assertThrown!AssertError(aw.weight(20));

		aw = new Weighting(WeightCurve.B, 30, 4.);

		assert(approxEqual(bCurve(5.), aw.weight(20)));
		assert(approxEqual(bCurve(15./4.), aw.weight(15)));
		assertThrown!AssertError(aw.weight(50));
	}

private:
    /++ A-weighting db correction, returned as a multiplication coefficient
      + for the energy level. Cf wikipedia page for function +/
	static double aCurve(double f) pure nothrow
	{
		immutable auto f2 = f*f;
		immutable auto f4 = f*f*f*f;

		double w = 1.;

		w = (f2 + 20.598997*20.598997)*(f2 + 12194.217*12194.217);
		w *= sqrt((f2 + 107.65265*107.65265)*(f2 + 737.86223*737.86223));
		w = 1.87193440e8 * f4 / w;

		return w;
	}
    unittest
	{
		assert(approxEqual(aCurve(31.5), pow(10, -39.5/20.)));
        assert(approxEqual(aCurve(250.), pow(10, -8.6/20.)));
        assert(approxEqual(aCurve(1000.), 1.0));
        assert(approxEqual(aCurve(4000.), pow(10, 1.0/20.)));
    }

    /++ B-weighting db correction, returned as a multiplication coefficient
      + for the energy level. Cf wikipedia page for function +/
	static double bCurve(double f) pure nothrow
	{
		immutable auto f2 = f*f;
		immutable auto f3 = f*f*f;

		double w = 1.;

		w = (f2 + 20.598997*20.598997)*(f2 + 12194.22*12194.22);
		w *= sqrt(f2 + 158.48932*158.48932);
		w = 1.5163179e8 * f3 / w;

		return w;
	}
    unittest
	{
        assert(approxEqual(bCurve(31.5), pow(10, -17.1/20.)));
        assert(approxEqual(bCurve(250.), pow(10, -1.3/20.)));
        assert(approxEqual(bCurve(1000.), 1.0));
        assert(approxEqual(bCurve(4000.), pow(10, -0.7/20.)));
    }

    /++ C-weighting db correction, returned as a multiplication coefficient
      + for the energy level. Cf wikipedia page for function +/
	static double cCurve(double f) pure nothrow
	{
		immutable auto f2 = f*f;

		double w = 1.;

		w = (f2 + 20.598997*20.598997)*(f2 + 12194.22*12194.22);
		w = 1.4976251e8 * f2 / w;

		return w;
	}
    unittest
    {
        assert(approxEqual(cCurve(31.5), pow(10, -3.0/20.)));
        assert(approxEqual(cCurve(250.), pow(10, 0./20.)));
        assert(approxEqual(cCurve(1000.), 1.0));
        assert(approxEqual(cCurve(4000.), pow(10, -0.8/20.)));
    }

    /++ Inverse of ISO-226 curve, returned as a multiplication coefficient
      + for the energy level.
	  + The ISO-226 only provides values for a few frequencies. Others are
	  + interpolated linearly.
	  +/
	static void fillInvIsoWeight(double[] weights,
								 in double scaling) pure nothrow
	{
		enum fs = [20, 25, 31.5, 40, 50, 63, 80, 100, 125, 160, 200, 250, 315,
				   400, 500, 630, 800, 1000, 1250, 1600, 2000, 2500, 3150,
				   4000, 5000, 6300, 8000, 10000, 12500, 20000];
		enum af = [0.532, 0.506, 0.480, 0.455, 0.432, 0.409, 0.387, 0.367,
				   0.349, 0.330, 0.315, 0.301, 0.288, 0.276, 0.267, 0.259,
				   0.253, 0.250, 0.246, 0.244, 0.243, 0.243, 0.243, 0.242,
				   0.242, 0.245, 0.254, 0.271, 0.301, 0.532];
		enum Lu = [-31.6, -27.2, -23.0, -19.1, -15.9, -13.0, -10.3, -8.1,
				   -6.2, -4.5, -3.1, -2.0, -1.1, -0.4, 0.0, 0.3, 0.5, 0.0,
				   -2.7, -4.1, -1.0,  1.7, 2.5, 1.2, -2.1, -7.1, -11.2, -10.7,
				   -3.1, -31.6];
		enum Tf = [78.5, 68.7, 59.5, 51.1, 44.0, 37.5, 31.5, 26.5, 22.1, 17.9,
				   14.4, 11.4, 8.6, 6.2, 4.4, 3.0, 2.2, 2.4, 3.5, 1.7, -1.3,
				   -4.2, -6.0, -5.4, -1.5, 6.0, 12.6, 13.9, 12.3, 78.5];

		double Af, Lp;
		immutable Ln = 40;

		double[] coeffs = new double[fs.length];

		foreach (i, f; fs) {
			Af = 4.47e-3 * (pow(10., 0.025*Ln) - 1.15) +
				pow((0.4*pow(10., (((Tf[i] + Lu[i])/10) - 9))), af[i]);
			Lp = (10./af[i] * log10(Af)) - Lu[i] + 94;

			coeffs[i] = Lp;
		}

		/* inverse the curve, setting the coefficient of freq 1000 at 0 */
		immutable coeff1000 = coeffs[17];
		foreach (ref c; coeffs)
			c = coeff1000 - c;

		size_t curi = 0;
		foreach (i, ref w; weights) {
			double x = i / scaling;
			double y;

			if (x < 20) {
				w = 0.;
				continue;
			}

			if (x == fs[curi])
				y = coeffs[curi];
			else {
				if (x > fs[curi+1] && curi + 2 < fs.length)
					curi++;
				y = (x - fs[curi]) * (coeffs[curi+1] - coeffs[curi])
					/(fs[curi+1] - fs[curi]) + coeffs[curi];
			}
			w = pow(10, y/20.);
		}
	}
    unittest
    {
		double[] w = new double[44100/2 + 1];

		fillInvIsoWeight(w, 0.5);
        assert(approxEqual(w[20 / 2], pow(10, -59.84/20.)));
        assert(approxEqual(w[250 / 2], pow(10, -10.38/20.)));
        assert(approxEqual(w[1000 / 2], 1.));
        assert(approxEqual(w[4000 / 2], pow(10, 3.361/20.)));
        assert(approxEqual(w[20000 / 2], pow(10, -59.84/20.)));
    }

    /++ ITU-R 468 curve, returned as a multiplication coefficient
      + for the energy level.
	  + Only values for a few frequencies are available. Others are
	  + interpolated linearly.
	  +/
	static void fillITUR468Weight(double[] weights,
								  in double scaling) pure nothrow
	{
		enum fs = [31.5, 63, 100, 200, 400, 800, 1000, 2000, 3150, 4000, 5000,
				   6300, 7100, 8000, 9000, 10000, 12500, 14000, 16000, 20000,
				   31500];
		enum coeffs = [-29.9, -23.9, -19.8, -13.8, -7.8, -1.9, 0, 5.6, 9, 10.5,
				  11.7, 12.2, 12, 11.4, 10.1, 8.1, 0, -5.3, -11.7, -22.2,
				  -42.7];

		size_t curi = 0;
		foreach (i, ref w; weights) {
			double x = i / scaling;
			double y;

			if (x < 20) {
				w = 0.;
				continue;
			}

			if (x == fs[curi])
				y = coeffs[curi];
			else {
				if (x > fs[curi+1] && curi + 2 < fs.length)
					curi++;
				y = (x - fs[curi]) * (coeffs[curi+1] - coeffs[curi])
					/(fs[curi+1] - fs[curi]) + coeffs[curi];
			}
			w = pow(10, y/20.);
		}
	}
    unittest
    {
		double[] w = new double[44100/2 + 1];

		fillITUR468Weight(w, 0.5);
        assert(approxEqual(w[100 / 2], pow(10, -19.8/20.)));
        assert(approxEqual(w[150 / 2], pow(10, -16.8/20.)));
        assert(approxEqual(w[1000 / 2], 1.));
        assert(approxEqual(w[4000 / 2], pow(10, 10.5/20.)));
        assert(approxEqual(w[9250 / 2], pow(10, 9.6/20.)));
    }
}
