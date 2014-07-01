import std.exception : assumeUnique;
import std.math : log10;
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
	this(double[] freqs)
	{
		auto w = new double[freqs.length];

		foreach(i, f; freqs)
			w[i] = weightOfFreq(f);

		weights = assumeUnique(w);
	}

	double weight(size_t index) const
	in
	{
		assert(index < weights.length);
	}
	body
	{
		return weights[index];
	}
	unittest
	{
		auto aw = new AWeighting([20, 2000]);

		assert(approxEqual(weightOfFreq(20), aw.weight(0)));
		assert(approxEqual(weightOfFreq(2000), aw.weight(1)));
		assertThrown!AssertError(aw.weight(2));
	}

	double weightEnergy(double f) pure nothrow
	{
		immutable auto f2 = f*f;
		immutable auto f4 = f2*f2;
		enum t = [[1.562339, 107.65265 * 107.65265, 737.86223 * 737.86223],
				  [2.242881e16, 20.598997 * 20.598997, 12194.22 * 12194.22]];

		double w = 1.;
		auto div = (f2 + t[1][1])*(f2 + t[1][2]);

		w *= (t[0][0] * f4)/((f2 + t[0][1])*(f2 + t[0][2]));
		w *= (t[1][0] * f4)/(div * div);

		return w;
	}

private:
	/++ See
	 + http://www.diracdelta.co.uk/science/source/a/w/aweighting/source.html
	 +/
	static double weightOfFreq(double f) pure nothrow
	{
		immutable auto f2 = f*f;
		immutable auto f4 = f2*f2;
		enum t = [[1.562339, 107.65265 * 107.65265, 737.86223 * 737.86223],
				  [2.242881e16, 20.598997 * 20.598997, 12194.22 * 12194.22]];

		double w = 0.;
		auto div = (f2 + t[1][1])*(f2 + t[1][2]);

		w += 10 * log10((t[0][0] * f4)/((f2 + t[0][1])*(f2 + t[0][2])));
		w += 10 * log10((t[1][0] * f4)/(div * div));

		return w;
	}
	unittest
	{
		assert(approxEqual(weightOfFreq(20), -50.5));
		assert(approxEqual(weightOfFreq(630), -1.9));
		assert(approxEqual(weightOfFreq(1000), 0));
		assert(approxEqual(weightOfFreq(2000), 1.2));
		assert(approxEqual(weightOfFreq(12500), -4.25));
	}
}
