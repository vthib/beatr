module libavutil.error;

import core.stdc.errno;

public import libavutil.common;

extern(C):
@trusted:
nothrow:

static if (EDOM > 0) {
	T AVERROR(T)(T E) { return -e; }
	T AVUNERROR(T)(T E) { return -e; }
} else {
	T AVERROR(T)(T E) { return e; }
	T AVUNERROR(T)(T E) { return e; }
}

int FFERRTAG(T)(T a, T b, T c, T d) { return -MKTAG(a, b, c, d); }

enum AVERROR_BSF_NOT_FOUND      = FFERRTAG(0xF8,'B','S','F');
enum AVERROR_BUG                = FFERRTAG( 'B','U','G','!');
enum AVERROR_BUFFER_TOO_SMALL   = FFERRTAG( 'B','U','F','S');
enum AVERROR_DECODER_NOT_FOUND  = FFERRTAG(0xF8,'D','E','C');
enum AVERROR_DEMUXER_NOT_FOUND  = FFERRTAG(0xF8,'D','E','M');
enum AVERROR_ENCODER_NOT_FOUND  = FFERRTAG(0xF8,'E','N','C');
enum AVERROR_EOF                = FFERRTAG( 'E','O','F',' ');
enum AVERROR_EXIT               = FFERRTAG( 'E','X','I','T');
enum AVERROR_EXTERNAL           = FFERRTAG( 'E','X','T',' ');
enum AVERROR_FILTER_NOT_FOUND   = FFERRTAG(0xF8,'F','I','L');
enum AVERROR_INVALIDDATA        = FFERRTAG( 'I','N','D','A');
enum AVERROR_MUXER_NOT_FOUND    = FFERRTAG(0xF8,'M','U','X');
enum AVERROR_OPTION_NOT_FOUND   = FFERRTAG(0xF8,'O','P','T');
enum AVERROR_PATCHWELCOME       = FFERRTAG( 'P','A','W','E');
enum AVERROR_PROTOCOL_NOT_FOUND = FFERRTAG(0xF8,'P','R','P');
enum AVERROR_STREAM_NOT_FOUND   = FFERRTAG(0xF8,'S','T','R');

enum AVERROR_BUG2               = FFERRTAG( 'B','U','G',' ');
enum AVERROR_UNKNOWN            = FFERRTAG( 'U','N','K','N');
enum AVERROR_EXPERIMENTAL       = (-0x2bb2afa8);
enum AVERROR_INPUT_CHANGED      = (-0x636e6701);
enum AVERROR_OUTPUT_CHANGED     = (-0x636e6702);

enum AVERROR_HTTP_BAD_REQUEST   = FFERRTAG(0xF8,'4','0','0');
enum AVERROR_HTTP_UNAUTHORIZED  = FFERRTAG(0xF8,'4','0','1');
enum AVERROR_HTTP_FORBIDDEN     = FFERRTAG(0xF8,'4','0','3');
enum AVERROR_HTTP_NOT_FOUND     = FFERRTAG(0xF8,'4','0','4');
enum AVERROR_HTTP_OTHER_4XX     = FFERRTAG(0xF8,'4','X','X');
enum AVERROR_HTTP_SERVER_ERROR  = FFERRTAG(0xF8,'5','X','X');

int av_strerror(int errnum, char *errbuf, size_t errbuf_size) pure;
