class LibAvException : Exception
{
    int ret;

    this(string msg, int r = 0, string file = __FILE__, size_t line = __LINE__,
         Throwable next = null) @safe pure nothrow
    {
        super(msg, file, line, next);
        this.ret = r;
    }
}
