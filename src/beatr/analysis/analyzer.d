import chroma.chromaprofile;
import chroma.chromabands;
import audio.audiofile;
import audio.audiostream;
import audio.fftutils;
import audio.fft;
import analysis.scores;
import util.beatr;

/++
 + Main class of Beatr.
 + Process samples of audio data and returns the best key estimate
 +/
class Analyzer
{
private:
	ChromaBands b;
	Fft2Freqs fft;

public:
	this()
	{
		b = new ChromaBands(Beatr.scaleNumbers, Beatr.scaleOffset);

		fftInit();
		fft = new Fft2Freqs(Beatr.fftTransformSize());
	}

	/++ Process the audio file, up to 'seconds' seconds +/
	void processFile(string fname, size_t seconds = size_t.max)
	{
		auto af = new AudioFile(fname);
		auto stream = new AudioStream(af);

		Beatr.writefln(Lvl.VERBOSE, "Using fft transform size %s and %s "
					   "overlaps", Beatr.fftTransformSize,
					   Beatr.fftNbOverlaps);

		clean();
		size_t i = 0;
		foreach(frame; stream) {
			if (i++ >= seconds)
				break;
			processFrame(frame);
		}
	}

	/++ process the given frame into chroma bands +/
	void processFrame(short[] f)
	{
		if (Beatr.fftNbOverlaps > 1) {
			fft.executeOverlaps(f, Beatr.fftNbOverlaps);
		} else {
			foreach (i, ref a; fft.input)
				a = f[i];
			fft.execute();
		}

		b.addFftSample(fft.output, fft.transformationSize);
	}

	void clean() nothrow
	{
		b.clean();
	}

	/++ Returns a score object based on the current chroma bands +/
	auto score(ProfileType pt = ProfileType.KRUMHANSL,
			   CorrelationMethod cm = CorrelationMethod.COSINE,
			   MatchingType mt = MatchingType.DOMINANT)
	{
		Beatr.writefln(Lvl.VERBOSE, "Using profile %s, correlation method %s "
					   "and matching type %s", pt, cm, mt);

		return new Scores(b, new ChromaProfile(pt), cm, mt);
	}

	@property auto bands() nothrow
	{
		return this.b;
	}
	unittest
	{
		import std.algorithm : equal;

		auto a = new Analyzer();
		assert(a.bands.getBands.length == 0);

		auto frame = new short[Beatr.fftTransformSize];
		a.processFrame(frame);
		auto b = new double[][](1, Beatr.scaleNumbers*12);
		b[0][] = 0.;
		assert(equal(a.bands.getBands, b));
	}

private:
	~this()
	{
		fftDestroy();
	}
}
