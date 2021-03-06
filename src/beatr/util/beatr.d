module util.beatr;

import io = std.stdio;
import cio = std.c.stdio;
import std.c.stdlib : exit;
import std.path : expandTilde;
import std.string : format;
version(unittest) {
	import std.array;
	import std.exception : assertThrown;
	import core.exception : AssertError;
	import std.algorithm : equal;
	import std.math : approxEqual;
}

import util.window;
import util.weighting;

version(unittest) {}
else {  @safe: }

/++ different levels of debugging +/
enum Lvl {
	silence = -2,
	warning = -1,
	normal = 0,
	verbose = 1,
	debug_ = 2
};

enum CorrelationMethod {
	cosine,
	pearson,
};

/++ Describe how the adjust the score for each key after using a
 + ChromaProfile
 +/
enum AdjustmentType {
	none   = 0, /++ Just use the score from the ChromaProfile +/
	addSubdom = 0x01, /++ Add the score of the subdominant to each key +/ 
	addDom    = 0x02, /++ Idem, for the dominant +/
	addRel    = 0x04, /++ Idem, for the relative key +/
	dominant  = addDom, /++ Only add the dominant +/
	cadence   = addDom | addSubdom, /++ Add both the dominant and the
									 + sub-dominant +/
	/++ Add the dominant, the sub-dominant and the relative +/
	all       = addDom | addSubdom | addRel,
}

/* XXX Make Options thread-independent */
/++ Provides a way to print debug messages according
 + to a verbose level +/
class Beatr
{
private:
	private static void checkInvariants() {
		foreach (c; Beatr.mCoefficients)
			assert(c >= 0.,
				   format("matching coefficients (%s) must be positive",
						  Beatr.mCoefficients));
		assert(Beatr.fftSigma >= 0.,
			   format("the sigma of fft interpolation (%s) needs to be positive",
					  Beatr.fftSigma));
		assert(Beatr.scales[0] < Beatr.scales[1] && Beatr.scales[1] <= 10,
			   format("Scales %s is not valid (first element must be less than "
					  "second one which must be less or equal than 10",
					  Beatr.scales));
		assert(Beatr.firstNote < 12,
			   format("The first analyzed note (%s) must be less than 12",
					  Beatr.firstNote));
	}

public:
	/***** Verbose utilities *****/

	/++ set the verbose level to a particular value
	 + Every message with a level greater than the one set will not be displayed
	 + Messages on a level < 0 will be printed on stderr
	 + Default is Lvl.normal
	 +/
	mixin property!(Lvl, "verboseLevel", "verbLevel", Lvl.normal, Lvl.debug_);

	/++ Call writefln(args) only if 'v' is a verbose level
	 + lesser than the current verbose level.
	 + If v is negative, print to stderr instead of stdout
	 +/
	static void writefln(T...)(in Lvl v, T args) @system nothrow
	{
		if (this.verboseLevel >= v) {
			try {
				if (v < 0)
					io.stderr.writefln(args);
				else
					io.stdout.writefln(args);
			} catch (Exception exc) {
				cio.printf("%.*s\n", exc.msg.length, exc.msg.ptr);
				exit(1);
			}
		}
	}
	/* XXX unittest? */

	/***** FFT Interpolation utilities *****/

	/++ The standard deviation of the gaussian function used to
	 + interpolate chroma values from the DFT vectors.
	 + The window used is equal to fftSigma * (1 - sqrt(2, 12))
	 + Thus, if fftSigma is 1, every bin between the previous note
	 + and the next one is considered.
	 + For a value of 0.5, the values considered are between -50 cents
	 + and +50 cents
	 +
	 + Default is 0.9
	 +/
	mixin property!(double, "fftSigma", "sigma", 0.9, 1.5);
	unittest {
		auto s = this.fftSigma;
		assertThrown!AssertError(this.fftSigma = -1.0);
		assertThrown!AssertError(this.fftSigma = double.nan);
		this.fftSigma = s;
	}

	/++ The window functino to use to transform a DFT vector to chroma values
	 + The window is taken as fftSigma * (1 - sqrt(2, 12)).
	 + Default is WindowType.hann
	 +/
	mixin property!(WindowType, "fftInterpolationMode", "fftIMode",
					WindowType.hann, WindowType.triangle);

	/***** Scales to analyze ******/

	/++ Returns an array of the starting and ending scale to analyze
	 + Default is [1, 9]
	 +/
	mixin property!(ubyte[2], "scales", "sc", [1, 9], [2, 3]);
	unittest {
		auto s = this.scales;

		/* test the invariant */
		assertThrown!AssertError(this.scales = [3, 11]);
		assertThrown!AssertError(this.scales = [3, 2]);
		assertThrown!AssertError(this.scales = [5, 5]);

		this.scales = s;
	}

	/++ Returns the first note possible to analyze
	 + Default is 0 (C0)
	 +/
	mixin property!(ubyte, "firstNote", "fnote", 0, 3);
	unittest {
		auto n = this.firstNote;

		/* test the invariant */
		assertThrown!AssertError(this.firstNote = 12);

		this.firstNote = n;
	}

	/++ Returns the number of frames in the buffer used to
	 + decode the audio stream
	 + Default is 10
	 +/
	mixin property!(size_t, "framesBufSize", "nbFramesBuf", 10, 5);

	/++ Returns the size of the FFT transformation
	 + Default is 16384
	 +/
	private static int fftSize = 16384;

	@property static auto fftTransformSize() nothrow
	{
		return (fftSize > this.sampleRate) ? this.sampleRate : fftSize;
	}

	@property static auto fftTransformSize(in int s) nothrow
	{
		return fftSize = s;
	}
	unittest
	{
		auto s = this.fftTransformSize;
		assert(s == fftSize);

		this.fftTransformSize = 8192;
		assert(this.fftTransformSize == 8192);
		assert(fftSize == 8192);

		fftSize = s;
	}

	/++ Returns the number of overlaps to execute when the fftTransformSize
	 + is smaller than the audio frame size
	 + Default is 8
	 +/
	mixin property!(uint, "fftNbOverlaps", "nboverlaps", 8, 32);

	/++ Returns the sample rate of the resampled audio signal used
	 + Default is 44100
	 +/
	mixin property!(uint, "sampleRate", "srate", 44100, 48000);
	unittest {
		auto fs = this.fftTransformSize;
		auto ss = this.sampleRate;

		/* test the fact that fftsize is min(fftsize, samplerate) */
		this.fftTransformSize = 35000;
		this.sampleRate = 16384;
		assert(this.fftTransformSize == 16384);
		this.sampleRate = 44100;
		assert(this.fftTransformSize == 35000);

		this.fftTransformSize = fs;
		this.sampleRate = ss;
	}

	/++ Returns the cut off frequency for a low pass filter before the
	 + fft transformation
	 + Default is 20000 Hz
	 +/
	mixin property!(double, "cutoffFreq", "cof", 20000., 15000.);

	/++ Returns whether to use the low pass filter or not
	 + Default is false
	 +/
	mixin property!(bool, "useFilter", "withFilter", false, true);

	/++ Returns the weight curve used to adjust the intensity of each frequency
	 + Default is A
	 +/
	mixin property!(WeightCurve, "weightCurve", "wCurve", WeightCurve.A,
					WeightCurve.B);

	/++ Returns the directory where config files are stored (wisdom, ...)
	 + Default is "~/.beatr"
     +/
	private static string config = null;

	@property static auto configDir() nothrow
	{
		if (config is null) {
			try {
				version (Windows) {
					config = ".beatr";
				} else {
					config = expandTilde("~/.beatr");
				}
			} catch (Exception e) {
				cio.printf("error expanding tilde in config directory name");
			}
		}
		return config;
	}

	@property static auto configDir(in string c) nothrow
	{
		return config = c;
	}
	unittest
	{
		auto c = this.configDir;
		assert(c == config);

		this.configDir = "/etc/beatr";
		assert(this.configDir == "/etc/beatr");
		assert(config == "/etc/beatr");

		config = c;
	}

	/++ Returns the adjusting method to use to compensate scores
	 + Default is cadence
	 +/
	mixin property!(AdjustmentType, "adjustType", "adjtype",
					AdjustmentType.cadence, AdjustmentType.none);

	/++ Returns the coefficients used with the matching algorithm
	 + This is an array of 3 double, for respectively the dominant,
	 + sub-dominant and relative scores
	 + Default is [0.5, 0.2, 0.]
	 +/
	mixin property!(double[3], "mCoefficients", "coeffs", [0.5, 0.2, 0.],
					[0.3, 0.3, 0.3]);
	unittest
	{
		auto c = this.mCoefficients;
		assertThrown!AssertError(this.mCoefficients = [-1.0, 0., 3.]);
		assertThrown!AssertError(this.mCoefficients = [1., 1., double.nan]);
		this.mCoefficients = c;
	}

private:
	mixin template property(T, string name, string var, T dval, T oval) {
		/* declare static private variable */
		mixin(format(q{
			private static T %s = dval;
		}, var));

		/* declare getter */
		mixin(format(q{
			@property public static T %s() nothrow @safe
			{
				return %s;
			}
		}, name, var));

		/* declare setter */
		mixin(format(q{
			static if (__traits(isStaticArray, T)) {
				private alias U = typeof(%s[0])[]; /* if T is V[n], U is V[] */

				@property public static inout(U) %s(inout(U) v)
				{
					foreach (i, c; v) { /* copy each element up to T.length */
						if (i >= T.length)
							break;
						%s[i] = c;
					}
					checkInvariants();
					return v;
				}
			} else {
				@property public static T %s(in T v)
				{
					%s = v;
					checkInvariants();
					return v;
				}
			}
				}, var, name, var, name, var));

		/* create unittests */
		mixin(format(q{
			unittest
			{
				auto v = this.%s;

				io.writefln("Testing properties Beatr.%s...");
				assert(v == %s);

				this.%s = oval;
				assert(this.%s == oval);
				assert(%s == oval);

				%s = v;
			}
		}, name, name, var, name, name, var, var));
	}
}
