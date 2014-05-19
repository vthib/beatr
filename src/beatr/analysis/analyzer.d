import chroma.chromaBands;
import chroma.profile.classicProfile;
import util.types;

import fftw.fftw3;

import std.exception : enforce;
import std.algorithm : map;

class analyzer
{
	chromaBands b;
	double[] norms;

public:
	this()
	{
		norms = new double[BeatrSampleSize];
		norms[0 .. $] = 0.0;
		b = new chromaBands(BeatrSampleSize);
	}

	~this()
	{
		fftw_cleanup();
	}

	void processSample(beatrSample s)
	{
		auto ibuf = new double[s.length];
		auto obuf = new cdouble[s.length];
		enum step = 1;
		uint idx = 0;

		enforce(s.length == BeatrSampleSize, "a sample is not of the same "
				 ~ "size as the predefined sample size");

		auto plan = fftw_plan_dft_r2c_1d(cast(int) s.length, ibuf.ptr, obuf.ptr,
										 0);
		foreach (ref i; ibuf) {
			i = s[idx];
			idx += step;
		}

		fftw_execute(plan);

		auto n = obuf.map!((a => std.math.sqrt(a.re*a.re + a.im*a.im) / s.length));

		foreach (i, ref o; norms)
			o += n[i];

		fftw_destroy_plan(plan);
	}

/+
	@property auto bands() const nothrow
	{
		return b;
	}
+/

	auto bestKey()
	{
		b.addFftSample(norms);
/+		auto p = new classicProfile();
		std.stdio.writeln(p.getProfile);+/
		return b.bestFit(new classicProfile());
	}
}
