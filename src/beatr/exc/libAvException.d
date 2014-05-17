import libavutil.error;

import core.stdc.string;

@safe:

// XXX: remove nothrow until version 2.066

class LibAvException : Exception
{
    int ret;

    this(string msg, int r = 0, string file = __FILE__, size_t line = __LINE__,
         Throwable next = null) pure //nothrow
    {
        this.ret = r;
        if (r != 0) {
			auto buf = new char[512];
			av_strerror(r, buf.ptr, buf.length);
			msg ~= ": " ~ ptrToString(buf);
		}

		super(msg, file, line, next);
    }

private:
	string ptrToString(char[] b) pure //nothrow
	{
		auto trustedstrlen(char *p) @trusted nothrow { return strlen(p); };
		auto end = trustedstrlen(b.ptr);
		b.length = end;
		return b.idup;
	}
}
