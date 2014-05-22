import io = std.stdio;
import cio = std.c.stdio;
import std.c.stdlib;

@system:

enum {
	BEATR_NORMAL,
	BEATR_DEBUG
};

/++ Provides a way to print debug messages according
 + to a verbose level +/
class Beatr
{
	static int verboseLevel;

public:

	static void setVerboseLevel(in int v) nothrow
	{
		verboseLevel = v;
	}

	static void writefln(T...)(int v, T args) nothrow
	{
		if (verboseLevel >= v) {
			try {
				io.writefln(args);
			} catch (Exception exc) {
				cio.printf("%.*s\n", exc.msg.length, exc.msg.ptr);
				exit(1);
			}
		}
	}
}
