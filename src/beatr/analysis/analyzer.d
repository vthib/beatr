import chroma.chromaprofile;
import chroma.chromabands;
import audio.audiofile;
import audio.audiostream;
import audio.fftutils;
import audio.lpfilter;
import audio.fft;
import analysis.scores;
import util.beatr;

import std.typecons : scoped;

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
	double[] filterout;

public:
	this()
	{
		b = new ChromaBands(cast(ubyte) (Beatr.scales[1] - Beatr.scales[0]),
							Beatr.scales[0]);

		fft = new Fft2Freqs(Beatr.fftTransformSize());

		if (Beatr.useFilter) {
			lpf = new typeof(lpf)(Beatr.sampleRate, Beatr.cutoffFreq);
			filterout = new double[Beatr.sampleRate];
		}
		fbidx = 0;
	}

	/++ Process the audio file, up to 'seconds' seconds +/
	void processFile(string fname, size_t seconds = size_t.max)
	{
		auto af = scoped!AudioFile(fname);
		auto stream = scoped!AudioStream(af);

		Beatr.writefln(Lvl.verbose, "Using fft transform size %s and %s "
					   "overlaps", Beatr.fftTransformSize,
					   Beatr.fftNbOverlaps);

		clean();
		size_t i = 0;
		if (Beatr.useFilter) {
			foreach(frame; stream) {
				if (i++ >= seconds)
					break;
				processFrameWithFilter(frame);
			}
			processFrameWithFilter(null, true);
		} else {
			foreach(frame; stream) {
				if (i++ >= seconds)
					break;
				processFrame(frame);
			}
		}
	}

	/++ Filter the input before processing it +/
	void processFrameWithFilter(short[] f, bool flush = false)
	{
		size_t cnt;

		cnt = lpf.filter(flush ? null : f[0 .. (filterout.length - fbidx)],
						 filterout[fbidx .. $], flush);
		fbidx = (fbidx + cnt) % filterout.length;
		if (fbidx != 0)
			return;

		processFrame(filterout);

		fbidx += lpf.filter(flush ? null : f[cnt .. $], filterout[0 .. $], flush);
	}

	/++ Process the given frame into chroma bands +/
	void processFrame(T)(T[] f)
	{
        if (Beatr.fftNbOverlaps > 1)
            fft.executeOverlaps(f, Beatr.fftNbOverlaps);
        else {
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
		a.processFrame(frame);
		auto b = new double[][](1, (Beatr.scales[1] - Beatr.scales[0])*12);
		b[0][] = 0.;
		assert(equal(a.bands.getBands, b));
	}
}

void
beatrInit()
{
	fftInit();
}

void
beatrCleanup()
{
	fftDestroy();
}
