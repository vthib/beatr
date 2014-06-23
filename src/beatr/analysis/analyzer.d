import chroma.chromaprofile;
import chroma.chromabands;
import file.audiostream;
import file.audiofile;
import util.beatr;
import analysis.scores;
import analysis.fftutils;

/++
 + Main class of Beatr.
 + Process samples of audio data and returns the best key estimate
 +/
class Analyzer
{
private:
	ChromaBands b;
	Scores sc;
	AudioFile af;

public:
	this(string as)
	{
		af = new AudioFile(as);
		b = new ChromaBands(Beatr.scaleNumbers, Beatr.scaleOffset,
							af.duration);

		fftInit();
	}

	/++ Process the audio file +/
	void process()
	in {
		assert(af !is null);
	}
	body {
		auto stream = new AudioStream(af);

		foreach(frame; stream)
			b.addFftSample(fftTransform(frame));
	}

	/++ Returns the best key estimate of the sample processed +/
	auto bestKey(ProfileType pt = ProfileType.KRUMHANSL,
				 MatchingType mt = MatchingType.CLASSIC)
	{

		Beatr.writefln(Lvl.VERBOSE, "Using profile %s and matching %s",
					   pt, mt);

		sc = new Scores(b, new ChromaProfile(pt), CorrelationMethod.COSINE, mt);

		return sc.bestKey();
	}

	@property auto scores() nothrow
	{
		return this.sc;
	}

	@property auto bands() nothrow
	{
		return this.b;
	}

private:
	~this()
	{
		fftDestroy();
	}
}
