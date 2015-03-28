module libavutil.common;

/* XXX: TODO: avutil.common */

extern(C):
nothrow:

int MKTAG(T)(T a, T b, T c, T d)
{
	return a | (b << 8) | (c << 16) | (cast(uint)d << 24);
}
