module libavutil.error;

import core.stdc.errno;

extern(C):
nothrow:

static if (EDOM > 0) {
	T AVERROR(T)(T E) { static assert(__ctfe); return -e; }
	T AVUNERROR(T)(T E) { static assert(__ctfe); return -e; }
} else {
	T AVERROR(T)(T E) { static assert(__ctfe); return e; }
	T AVUNERROR(T)(T E) { static assert(__ctfe); return e; }
}

enum AVERROR_BSF_NOT_FOUND      = (-0x39acbd08);
enum AVERROR_DECODER_NOT_FOUND  = (-0x3cbabb08);
enum AVERROR_DEMUXER_NOT_FOUND  = (-0x32babb08);
enum AVERROR_ENCODER_NOT_FOUND  = (-0x3cb1ba08);
enum AVERROR_EOF                = (-0x5fb9b0bb);
enum AVERROR_EXIT               = (-0x2bb6a7bb);
enum AVERROR_FILTER_NOT_FOUND   = (-0x33b6b908);
enum AVERROR_INVALIDDATA        = (-0x3ebbb1b7);
enum AVERROR_MUXER_NOT_FOUND    = (-0x27aab208);
enum AVERROR_OPTION_NOT_FOUND   = (-0x2bafb008);
enum AVERROR_PATCHWELCOME       = (-0x3aa8beb0);
enum AVERROR_PROTOCOL_NOT_FOUND = (-0x30adaf08);
enum AVERROR_STREAM_NOT_FOUND   = (-0x2dabac08);
enum AVERROR_BUG                = (-0x5fb8aabe);
enum AVERROR_UNKNOWN            = (-0x31b4b1ab);
enum AVERROR_EXPERIMENTAL       = (-0x2bb2afa8);

int av_strerror(int errnum, char *errbuf, size_t errbuf_size);
