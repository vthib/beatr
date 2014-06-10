import chroma.chromaprofile;
import chroma.chromabands;
import file.audiostream;
import file.audiofile;
import util.types;
import util.beatr;
import analysis.scores;

import fftw.fftw3;

import std.exception : enforce;
import std.algorithm : map;

/++
 + Main class of Beatr.
 + Process samples of audio data and returns the best key estimate
 +/
class Analyzer
{
private:
	ChromaBands b;
	double[beatrSampleRate] norms;
	Scores scores;
	AudioFile af;

public:
	this(string as)
	{
		af = new AudioFile(as);
		norms[] = 0.0; /* set all to 0, as by default it is NaN */
		b = new ChromaBands();
	}

	/++ Process the audio file +/
	void process(in double sigma = 0.)
	in {
		assert(af !is null);
	}
	body {
		auto stream = new AudioStream(af);

		foreach(frame; stream)
			processSample(frame);

		b.addFftSample(norms, sigma);
	}

	/++ Returns the best key estimate of the sample processed +/
	auto bestKey(ProfileType pt = ProfileType.KRUMHANSL,
				 MatchingType mt = MatchingType.CLASSIC)
	{

		Beatr.writefln(BEATR_VERBOSE, "Using profile %s and matching %s",
					   pt, mt);

		scores = new Scores(b, new ChromaProfile(pt), mt);

		return scores.bestKey();
	}

	@property auto getScores() nothrow
	{
		return this.scores;
	}

private:
	~this()
	{
		fftw_cleanup();
	}


	/++ Process the input sample for a future key estimate +/
	void processSample(inout ref beatrSample s)
	in {
		assert(s.length == beatrSampleRate);
	}
	body {
		auto ibuf = new double[s.length];
		auto obuf = new cdouble[s.length];
		enum step = 1;
		uint idx = 0;

		auto plan = fftw_plan_dft_r2c_1d(cast(int) s.length, ibuf.ptr, obuf.ptr,
										 0);
		scope(exit) fftw_destroy_plan(plan);

		/* copy the input into the ibuf buffer */
		/* !!! This has to be _after_ the plan creation, as this function sets
		   its argument to 0 */
		foreach (ref i; ibuf) {
			i = s[idx];
			idx += step;
		}

		fftw_execute(plan);

		/* retrieve the norm of each complex output */
		auto n = obuf.map!((a => std.math.sqrt(a.re*a.re + a.im*a.im) / s.length));

		/* add it to our norms field */
		foreach (i, ref o; this.norms)
			o += n[i];
	}
}
