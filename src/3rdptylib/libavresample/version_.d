module libavresample.version_;

public import libavutil.version_;

enum LIBAVRESAMPLE_VERSION_MAJOR = 1;
enum LIBAVRESAMPLE_VERSION_MINOR = 1;
enum LIBAVRESAMPLE_VERSION_MICRO = 0;

enum LIBAVRESAMPLE_VERSION_INT =
	AV_VERSION_INT(LIBAVRESAMPLE_VERSION_MAJOR, LIBAVRESAMPLE_VERSION_MINOR,
				   LIBAVRESAMPLE_VERSION_MICRO);
enum LIBAVRESAMPLE_VERSION =
	AV_VERSION(LIBAVRESAMPLE_VERSION_MAJOR, LIBAVRESAMPLE_VERSION_MINOR,
			   LIBAVRESAMPLE_VERSION_MICRO);
alias LIBAVRESAMPLE_VERSION_INT LIBAVRESAMPLE_BUILD;

enum LIBAVRESAMPLE_IDENT = "Lavr" ~ AV_STRINGIFY(LIBAVRESAMPLE_VERSION);

static if (LIBAVRESAMPLE_VERSION_MAJOR < 2) {
	enum FF_API_RESAMPLE_CLOSE_OPEN = 1;
}