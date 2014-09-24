module libavutil.avutil;

public import libavutil.rational;

extern(C):
nothrow:

uint avutil_version();
const(char) *avutil_configuration();
const(char) *avutil_license();

enum AVMediaType {
	AVMEDIA_TYPE_UNKNOWN = -1,
    AVMEDIA_TYPE_VIDEO,
    AVMEDIA_TYPE_AUDIO,
    AVMEDIA_TYPE_DATA,
    AVMEDIA_TYPE_SUBTITLE,
    AVMEDIA_TYPE_ATTACHMENT,
    AVMEDIA_TYPE_NB
};

enum FF_LAMBDA_SHIFT = 7;
enum FF_LAMBDA_SCALE = (1 << FF_LAMBDA_SHIFT);
enum FF_QP2LAMBDA = 118;
enum FF_LAMBDA_MAX = (256*128 - 1);

enum AV_NOPTS_VALUE = 0x8000000000000000L;
enum AV_TIME_BASE = 1000000;
enum AV_TIME_BASE_Q = AVRational(1, AV_TIME_BASE);

enum AVPictureType {
    AV_PICTURE_TYPE_I = 1,
    AV_PICTURE_TYPE_P,
    AV_PICTURE_TYPE_B,
    AV_PICTURE_TYPE_S,
    AV_PICTURE_TYPE_SI,
    AV_PICTURE_TYPE_SP,
    AV_PICTURE_TYPE_BI
};

char av_get_picture_type_char(AVPictureType pict_type);

public import libavutil.error;
public import libavutil.version_;
public import libavutil.macros;
