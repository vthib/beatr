module exc.libavexception;

import libavutil.error;

import core.stdc.string : strlen;
import std.string : indexOf;

@safe:

// XXX: remove nothrow until version 2.066 (idup bug)

/++
 + Wraps a libav error in a exception
 +/
class LibAvException : Exception
{
    int ret;

    this(string msg, int r = 0, string file = __FILE__, size_t line = __LINE__,
         Throwable next = null) pure //nothrow
    {
        this.ret = r;
        if (r != 0) /* append a descriptive error message */
			msg ~= ": " ~ errorToString(r);

		super(msg, file, line, next);
    }
	@system unittest
	{
		auto m = "test message";
		auto exc = new LibAvException(m, 5);

		assert(-1 != exc.msg.indexOf(m));
		assert(-1 != exc.msg.indexOf(errorToString(5)));
	}

	/++ returns a string describing a libav error +/
	static string errorToString(int r) pure // nothrow
	{
		char[512] buf;
		av_strerror(r, buf.ptr, buf.length);
		return ptrToString(buf);
	}

private:
	/++ converts a c-style string to a string type +/
	static string ptrToString(char[] b) pure //nothrow
	{
		auto trustedstrlen(char *p) @trusted nothrow { return strlen(p); };
		auto end = trustedstrlen(b.ptr);
		b.length = end;
		return b.idup;
	}
	unittest
	{
		assert(ptrToString(['f', 'o', 'o', '\0']) == "foo");
		assert(ptrToString(['\0']) == "");
	}
}
