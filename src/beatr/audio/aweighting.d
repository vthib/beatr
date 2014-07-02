import std.exception : assumeUnique;
import std.math : log10, sqrt, pow;
import std.string : format;
version(unittest) {
	import std.math : approxEqual;
	import core.exception : AssertError;
	import std.exception : assertThrown;
}

class AWeighting
{
private:
	immutable double[] weights;

public:
	this(in size_t size, in double scaling)
	{
		auto w = new double[size];

		foreach(i, ref a; w)
			a = weightEnergy(i * scaling);

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
		auto aw = new AWeighting(20, 2.);

		assert(approxEqual(weightEnergy(20.), aw.weight(10)));
		assert(approxEqual(weightEnergy(30.), aw.weight(15)));
		assertThrown!AssertError(aw.weight(20));
	}

private:
	/++ A-weighting db correction, returned as a multiplication coefficient
	  + for the energy level +/
	static double weightEnergy(double f) pure nothrow
	{
		immutable auto f2 = f*f;
		immutable auto f4 = f2*f2;

		double w = 1.;

		w = (f2 + 20.6*20.6)*(f2+12200.*12200.);
		w *= sqrt((f2 + 107.7*107.7)*(f2 + 737.9*737.9));
		w = 12200. * 12200. * f4 / w;

		return w * pow(10., 0.1);
	}
	unittest
	{
		assert(approxEqual(weightEnergy(1000), 1.0));
	}
}
