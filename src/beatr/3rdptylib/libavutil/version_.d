module libavutil.version_;

public import libavutil.macros;

import std.string : format;

T AV_VERSION_INT(T)(T a, T b, T c)
{
	static assert(__ctfe);
	return (a << 16 | b << 8 | c);
}

string AV_VERSION_DOT(T, U, V)(T a, U b, V c)
{
	static assert(__ctfe);
	return format("%s.%s.%s", a, b, c);
}

alias AV_VERSION_DOT AV_VERSION;

enum LIBAVUTIL_VERSION_MAJOR = 53;
enum LIBAVUTIL_VERSION_MINOR = 3;
enum LIBAVUTIL_VERSION_MICRO = 0;

enum LIBAVUTIL_VERSION_INT =
	AV_VERSION_INT(LIBAVUTIL_VERSION_MAJOR, LIBAVUTIL_VERSION_MINOR,
				   LIBAVUTIL_VERSION_MICRO);
enum LIBAVUTIL_VERSION =
	AV_VERSION(LIBAVUTIL_VERSION_MAJOR, LIBAVUTIL_VERSION_MINOR,
			   LIBAVUTIL_VERSION_MICRO);
alias LIBAVUTIL_VERSION_INT LIBAVUTIL_BUILD;

enum LIBAVUTIL_IDENT = "Lavu" ~ AV_STRINGIFY(LIBAVUTIL_VERSION);

static if (LIBAVUTIL_VERSION_MAJOR < 54) {
	enum FF_API_PIX_FMT = 1;
	enum FF_API_CONTEXT_SIZE = 1;
	enum FF_API_PIX_FMT_DESC = 1;
	enum FF_API_AV_REVERSE = 1;
	enum FF_API_AUDIOCONVERT = 1;
	enum FF_API_CPU_FLAG_MMX2 = 1;
	enum FF_API_LLS_PRIVATE = 1;
	enum FF_API_AVFRAME_LAVC = 1;
	enum FF_API_VDPAU = 1;
	enum FF_API_XVMC = 1;
}
