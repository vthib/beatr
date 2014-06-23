import io = std.stdio;
import cio = std.c.stdio;
import std.c.stdlib;
import std.path : expandTilde;

import std.exception;
import core.exception;

version(Unittest) {}
else {  @safe: }

public:

/++ different levels of debugging +/
enum Lvl {
	WARNING = -1,
	NORMAL = 0,
	VERBOSE = 1,
	DEBUG = 2
};

enum FFTInterpolationMode {
	TRIANGLE,
	RECTANGLE,
	GAUSSIAN,
	COSINE
};

/* XXX Make Options thread-independent */
/++ Provides a way to print debug messages according
 + to a verbose level +/
class Beatr
{
private:
	static auto verbLevel = Lvl.NORMAL;

	/* fft interpolation variables */
	static double fftSig = 0.4;
	static auto fftIMode = FFTInterpolationMode.GAUSSIAN;

	/* scales to analyze */
	static ubyte sOffset = 1;
	static ubyte sNumbers = 6;

	/++ numbers of frames in the decompression buffer +/
	static size_t nbFramesBuf = 10;

	/++ Directory where config files are stored +/
	static string config = null;

	/* XXX: not working, because of static methods? */
	version(none) {
		invariant() {
			assert(fftSig >= 0.);
			assert(scaleOffset <= 9);
			assert(1 <= scaleNumbers && scaleNumbers <= 10);
		}
	}

public:
	/***** Verbose utilities *****/

	/++ set the verbose level to a particular value +/
	@property static auto verboseLevel(in Lvl v) nothrow
	{
		return verbLevel = v;
	}

	/++ retrieve the verbose level +/
	@property static auto verboseLevel() nothrow
	{
		return verbLevel;
	}
	unittest
	{
		auto v = verbLevel;
		assert(v == this.verboseLevel);

		this.verboseLevel = Lvl.WARNING;
		assert(verbLevel == Lvl.WARNING);
		assert(this.verboseLevel == Lvl.WARNING);

		this.verboseLevel = Lvl.DEBUG;
		assert(verbLevel == Lvl.DEBUG);
		assert(this.verboseLevel == Lvl.DEBUG);

		verbLevel = v;
	}

	/++ Call writefln(args) only if 'v' is a verbose level
	 + lesser than the current verbose level.
	 + If v is negative, print to stderr instead of stdout
	 +/
	static void writefln(T...)(in Lvl v, T args) @system nothrow
	{
		if (verbLevel >= v) {
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
	 + Default is 0.4
	 +/
	@property static auto fftSigma() nothrow { return fftSig; }

	@property static auto fftSigma(in double s) nothrow
	in { assert(s >= 0.); }
    body
	{
		return fftSig = s;
	}
	unittest
	{
		auto s = fftSig;
		assert(s == this.fftSigma);

		this.fftSigma = 2.0;
		assert(this.fftSigma == 2.0);
		assert(fftSig == 2.0);

		assertThrown!AssertError(this.fftSigma = -1.0);
		assertThrown!AssertError(this.fftSigma = double.nan);

		fftSig = s;
	}

	/++ The mode of interpolation to transform a DFT vector to chroma values
	 + The window is taken as fftSigma * (1 - sqrt(2, 12)).
	 + RECTANGLE: Every value in the window has the same coefficient
	 + TRIANGLE: Use a triangle window equal to 0 left and right and 1 on the
	 + note frequency
	 + COSINE: Use a cosine function centered on the note frequency
	 + GAUSSIAN: Idem with a gaussian function
	 +
	 + Default is GAUSSIAN
	 +/
	@property static auto fftInterpolationMode() nothrow
	{
		return fftIMode;
	}

	@property static auto
	fftInterpolationMode(in FFTInterpolationMode m) nothrow
	{
		return fftIMode = m;
	}
	unittest
	{
		auto m = fftIMode;
		assert(m == this.fftInterpolationMode);

		enum mode = FFTInterpolationMode.TRIANGLE;
		this.fftInterpolationMode = mode;
		assert(this.fftInterpolationMode == mode);
		assert(fftIMode == mode);

		fftIMode = m;
	}

	/***** Scales to analyze ******/

	/++ Returns the offset indicating the first scale to analyze
	 + Default is 1
	 +/
	@property static auto scaleOffset() nothrow { return sOffset; }

	@property static auto scaleOffset(in ubyte o) nothrow
	in { assert(o <= 10); }
    body
	{
		return sOffset = o;
	}
	unittest
	{
		auto o = sOffset;
		assert(o == this.scaleOffset);

		this.scaleOffset = 5;
		assert(this.scaleOffset == 5);
		assert(sOffset == 5);

		assertThrown!AssertError(this.scaleOffset = 11);

		sOffset = o;
	}

	/++ Returns the number of scales to analyze
	 + Default is 6
	 +/
	@property static auto scaleNumbers() nothrow { return sNumbers; }

	@property static auto scaleNumbers(in ubyte n) nothrow
	in { assert(1 <= n && n <= 10); }
    body
	{
		return sNumbers = n;
	}
	unittest
	{
		auto n = sNumbers;
		assert(n == this.scaleNumbers);

		this.scaleNumbers = 5;
		assert(this.scaleNumbers == 5);
		assert(sNumbers == 5);

		assertThrown!AssertError(this.scaleNumbers = 0);
		assertThrown!AssertError(this.scaleNumbers = 11);

		sNumbers = n;
	}

	/++ Returns the number of frames in the buffer used to
	 + decode the audio stream
	 + Default is 10
	 +/
	@property static auto framesBufSize() nothrow
	{
		return nbFramesBuf;
	}

	@property static auto framesBufSize(in size_t n) nothrow
	{
		return nbFramesBuf = n;
	}
	unittest
	{
		auto n = nbFramesBuf;
		assert(n == this.framesBufSize);

		this.framesBufSize = 5;
		assert(this.framesBufSize == 5);
		assert(nbFramesBuf == 5);

		nbFramesBuf = n;
	}

	/++ Returns the directory where config files are stored (wisdom, ...)
	 + Default is "~/.beatr"
	 +/
	@property static auto configDir() nothrow
	{
		if (config is null) {
			try {
				config = expandTilde("~/.beatr");
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
}
