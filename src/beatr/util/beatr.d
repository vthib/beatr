import io = std.stdio;
import cio = std.c.stdio;
import std.c.stdlib;

@system:

/++ different levels of debugging +/
enum {
	BEATR_NORMAL,
	BEATR_VERBOSE,
	BEATR_DEBUG
};

/++ Provides a way to print debug messages according
 + to a verbose level +/
class Beatr
{
	static int verbLevel = BEATR_NORMAL;

public:

	static void setVerboseLevel(in int v) nothrow
	{
		verbLevel = v;
	}

	@property static int verboseLevel() nothrow
	{
		return verbLevel;
	}

	static void writefln(T...)(int v, T args) nothrow
	{
		if (verbLevel >= v) {
			try {
				io.writefln(args);
			} catch (Exception exc) {
				cio.printf("%.*s\n", exc.msg.length, exc.msg.ptr);
				exit(1);
			}
		}
	}
}
