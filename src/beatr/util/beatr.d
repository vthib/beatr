import io = std.stdio;
import cio = std.c.stdio;
import std.c.stdlib;

nothrow:
@safe:

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

	static double fftSig = 1.0;
	static auto fftIMode = FFTInterpolationMode.ADAPTIVE;

public:
	/***** Verbose utilities *****/

	/++ set the verbose level to a particular value +/
	@property static auto verboseLevel(in Lvl v)
	{
		return verbLevel = v;
	}

	/++ retrieve the verbose level +/
    /* XXX: necessary? */
	@property static int verboseLevel()
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

	@property static auto fftSigma() { return fftSig; }

	@property static auto fftSigma(in double s)
	{
		return fftSig = s;
	}


	@property static auto fftInterpolationMode()
	{
		return fftIMode;
	}

	@property static auto fftInterpolationMode(in FFTInterpolationMode m)
	{
		return fftIMode = m;
	}

}
