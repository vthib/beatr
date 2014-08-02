import chroma.chromaprofile;
import chroma.chromabands;
import audio.audiofile;
import audio.audiostream;
import audio.fftutils;
import audio.lpfilter;
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
	LowPassFilter!80 lpf;
	size_t fbidx;

public:
	this()
	{
		b = new ChromaBands(cast(ubyte) (Beatr.scales[1] - Beatr.scales[0]),
							Beatr.scales[0]);

		fftInit();
		fft = new Fft2Freqs(Beatr.fftTransformSize());

		if (Beatr.useFilter)
			lpf = new typeof(lpf)(Beatr.sampleRate, Beatr.cutoffFreq);
		fbidx = 0;
	}

	/++ Process the audio file, up to 'seconds' seconds +/
	void processFile(string fname, size_t seconds = size_t.max)
	{
		auto af = new AudioFile(fname);
		auto stream = new AudioStream(af);

		Beatr.writefln(Lvl.verbose, "Using fft transform size %s and %s "
					   "overlaps", Beatr.fftTransformSize,
					   Beatr.fftNbOverlaps);

		clean();
		size_t i = 0;
		if (Beatr.useFilter) {
			foreach(frame; stream) {
				if (i++ >= seconds)
					break;
				processFrame!true(frame);
			}
			processFrame!true(null, true);
		} else {
			foreach(frame; stream) {
				if (i++ >= seconds)
					break;
				processFrame!false(frame);
			}
		}
	}

	/++ process the given frame into chroma bands +/
	void processFrame(bool withFilter)(short[] f, bool flush = false)
	{
		size_t cnt;

		static if (withFilter) {
			cnt = lpf.filter(flush ? null : f[0 .. (fft.input.length - fbidx)],
							 fft.input[fbidx .. $], flush);
			fbidx = (fbidx + cnt) % fft.input.length;
			if (fbidx != 0)
				return;
		} else {
			foreach (i, ref a; fft.input)
				a = f[i];
		}

		if (Beatr.fftNbOverlaps > 1)
			fft.executeOverlaps(f, Beatr.fftNbOverlaps);
		else
			fft.execute();

		static if (withFilter)
			fbidx += lpf.filter(flush ? null : f[cnt .. $], fft.input[0 .. $], flush);

		b.addFftSample(fft.output, fft.transformationSize);
	}

	void clean() nothrow
	{
		b.clean();
	}

	/++ Returns a score object based on the current chroma bands +/
	auto score(ProfileType pt = ProfileType.chordNormalized,
			   CorrelationMethod cm = CorrelationMethod.cosine)
	{
		Beatr.writefln(Lvl.verbose, "Using profile type %s", pt);

		return new Scores(b, new ChromaProfile(pt), cm);
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
		a.processFrame!false(frame);
		auto b = new double[][](1, (Beatr.scales[1] - Beatr.scales[0])*12);
		b[0][] = 0.;
		assert(equal(a.bands.getBands, b));
	}

private:
	~this()
	{
		fftDestroy();
	}
}
