import io = std.stdio;
import cio = std.c.stdio;
import std.c.stdlib;

import std.exception;
import core.exception;

nothrow:
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
	FIXED,
	ADAPTIVE,
};

/++ Provides a way to print debug messages according
 + to a verbose level +/
class Beatr
{
private:
	static auto verbLevel = Lvl.NORMAL;

	/* fft interpolation variables */
	static double fftSig = 1.0;
	static auto fftIMode = FFTInterpolationMode.ADAPTIVE;

	/* scales to analyze */
	static ubyte sOffset = 3;
	static ubyte sNumbers = 5;

	/* XXX: not working, because of static methods? */
	invariant() {
		assert(fftSig >= 0.);
		assert(scaleOffset <= 9);
		assert(1 <= scaleNumbers && scaleNumbers <= 10);
	}

public:
	/***** Verbose utilities *****/

	/++ set the verbose level to a particular value +/
	@property static auto verboseLevel(in Lvl v)
	{
		return verbLevel = v;
	}

	/++ retrieve the verbose level +/
    /* XXX: necessary? */
	@property static auto verboseLevel()
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
	static void writefln(T...)(in Lvl v, T args) @system
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

	/***** FFT Interpolation utilities *****/

	/++ The standard deviation of the gaussian function used to
	 + interpolate chroma values from the DFT vectors
	 + The gaussian is centered on the frequency of the note,
	 + the standard deviation is used to add neighbouring values.
	 + If the value is 0, a dirac function is used instead of a gaussian
	 +
	 + Default is 1
	 +/
	@property static auto fftSigma() { return fftSig; }

	@property static auto fftSigma(in double s)
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
	 + FIXED: use the same standard deviation for every note
	 + ADAPTIVE: use as standard deviation half the min distance to a neighbour
	 +   note, and multiply by fftSigma
	 + Default is ADAPTIVE
	 +/
	@property static auto fftInterpolationMode()
	{
		return fftIMode;
	}

	@property static auto fftInterpolationMode(in FFTInterpolationMode m)
	{
		return fftIMode = m;
	}
	unittest
	{
		auto m = fftIMode;
		assert(m == this.fftInterpolationMode);

		this.fftInterpolationMode = FFTInterpolationMode.FIXED;
		assert(this.fftInterpolationMode ==
			   FFTInterpolationMode.FIXED);
		assert(fftIMode == FFTInterpolationMode.FIXED);

		fftIMode = m;
	}

	/***** Scales to analyze ******/

	/++ Returns the offset indicating the first scale to analyze
	 + Default is XXX
	 +/
	@property static auto scaleOffset() { return sOffset; }

	@property static auto scaleOffset(in ubyte o)
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
	 + Default is XXX
	 +/
	@property static auto scaleNumbers() { return sNumbers; }

	@property static auto scaleNumbers(in ubyte n)
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
}
