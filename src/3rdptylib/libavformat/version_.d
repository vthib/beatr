module libavformat.version_;

public import libavutil.version_;

enum LIBAVFORMAT_VERSION_MAJOR = 55;
enum LIBAVFORMAT_VERSION_MINOR = 12;
enum LIBAVFORMAT_VERSION_MICRO = 0;

enum LIBAVFORMAT_VERSION_INT =
	AV_VERSION_INT(LIBAVFORMAT_VERSION_MAJOR, LIBAVFORMAT_VERSION_MINOR,
				   LIBAVFORMAT_VERSION_MICRO);
enum LIBAVFORMAT_VERSION =
	AV_VERSION(LIBAVFORMAT_VERSION_MAJOR, LIBAVFORMAT_VERSION_MINOR,
			   LIBAVFORMAT_VERSION_MICRO);
alias LIBAVFORMAT_VERSION_INT LIBAVFORMAT_BUILD;

enum LIBAVFORMAT_IDENT = "Lavf" ~ AV_STRINGIFY(LIBAVFORMAT_VERSION);

static if (LIBAVFORMAT_VERSION_MAJOR < 56) {
	enum FF_API_REFERENCE_DTS = 1;
}
