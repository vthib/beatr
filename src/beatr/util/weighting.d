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
//	ITUR468,
//	INVISO226,
}

class Weighting
{
private:
	immutable double[] weights;

public:
	this(in WeightCurve wc, in size_t size, in double scaling)
	{
		auto w = new double[size];

		double function(double) weight;// pure nothrow weight;
		final switch (wc) {
		case WeightCurve.A:
			weight = &aCurve; break;
		case WeightCurve.B:
			weight = &bCurve; break;
		case WeightCurve.C:
			weight = &cCurve; break;
		}
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
	static double aCurve(double f) //pure nothrow
	{
		immutable auto f2 = f*f;
		immutable auto f4 = f*f*f*f;

		double w = 1.;

		w = (f2 + 20.598997*20.598997)*(f2 + 12194.22*12194.22);
		w *= sqrt((f2 + 107.65265*107.65265)*(f2 + 737.86223*737.86223));
		w = 1.87193495e8 * f4 / w;

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

    /++ B-weighting db correction, returned as a multiplication coefficient
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
}
