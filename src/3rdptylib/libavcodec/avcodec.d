module libavcodec.avcodec;

public {
	import libavutil.samplefmt;
	import libavutil.attributes;
	import libavutil.avutil;
	import libavutil.buffer;
	import libavutil.cpu;
	import libavutil.dict;
	import libavutil.frame;
	import libavutil.log;
	import libavutil.pixfmt;
	import libavutil.rational;

	public import libavcodec.version_;

	static if (FF_API_FAST_MALLOC)
		import libavutil.mem;
}

extern(C):
nothrow:

/* XXX: TODO: all aliases in avcodec */

alias int AVCodecID;

struct AVCodecDescriptor;

enum AV_CODEC_PROP_INTRA_ONLY = (1 << 0);
enum AV_CODEC_PROP_LOSSY      = (1 << 1);
enum AV_CODEC_PROP_LOSSLESS   = (1 << 2);

enum FF_INPUT_BUFFER_PADDING_SIZE = 8;
enum FF_MIN_BUFFER_SIZE = 16384;

alias int Motion_Est_ID;
alias int AVDiscard;
alias int AVColorPrimaries;
alias int AVColorTransferCharacteristic;
alias int AVColorSpace;
alias int AVColorRange;
alias int AVChromaLocation;
alias int AVAudioServiceType;

struct RcOverride {
	int start_frame;
	int end_frame;
	int qscale;
	float quality_factor;
};

static if (FF_API_MAX_BFRAMES)
	deprecated enum FF_MAX_B_FRAMES = 16;

/* XXX skip... */

alias int AVPacketSideDataType;

/* XXX skip... */

struct AVPacketSideData {
	ubyte *data;
	int size;
	AVPacketSideDataType type;
};
 
struct AVPacket {
	AVBufferRef* buf;
	long pts;

	long dts;
	byte* data;
	int size;
	int stream_index;

	int flags;
	AVPacketSideDataType *side_data;

	int side_data_elems;

	int duration;

	static if (FF_API_DESTRUCT_PACKET) {
		deprecated void function(AVPacket *) destruct;
		deprecated void* priv;
	}

	long pos;

	long convergence_duration;
}

enum AV_PKT_FLAG_KEY     = 0x0001;
enum AV_PKT_FLAG_CORRUPT = 0x0002;

enum AVSideDataParamChangeFlags {
    AV_SIDE_DATA_PARAM_CHANGE_CHANNEL_COUNT  = 0x0001,
    AV_SIDE_DATA_PARAM_CHANGE_CHANNEL_LAYOUT = 0x0002,
    AV_SIDE_DATA_PARAM_CHANGE_SAMPLE_RATE    = 0x0004,
    AV_SIDE_DATA_PARAM_CHANGE_DIMENSIONS     = 0x0008
};

struct AVCodecInternal;

enum AVFieldOrder {
    AV_FIELD_UNKNOWN,
    AV_FIELD_PROGRESSIVE,
    AV_FIELD_TT,
    AV_FIELD_BB,
    AV_FIELD_TB,
    AV_FIELD_BT
};

struct AVCodecContext {
	const AVClass* av_class;
	int log_level_offset;

	AVMediaType codec_type;
	AVCodec* codec;
	char codec_name[32];
	AVCodecID codec_id;

	uint codec_tag;
	uint stream_codec_tag;
	void* priv_data;

	AVCodecInternal* internal;
	void* opaque;

	int bit_rate;
	int bit_rate_tolerance;
	int global_quality;
	int compression_level;
	enum FF_COMPRESSION_DEFAULT = -1;

	int flags;
	int flags2;
	byte* extradata;
	int extradata_size;

	AVRational time_base;
	int ticks_per_frame;

	int delay;
	int width, height;

	int coded_width, coded_height;
	static if (FF_API_ASPECT_EXTENDED)
		enum FF_ASPECT_EXTENDED = 15;

	int gop_size;

	AVPixelFormat pix_fmt;
	int me_method;
	void function(AVCodecContext *s, const AVFrame *src,
				  int offset[AV_NUM_DATA_POINTERS], int y, int type,
				  int height) draw_horiz_band;
	AVPixelFormat function(AVCodecContext *s, const AVPixelFormat *fmt) get_format;

	int max_b_frames;
	float b_quant_factor;
	int rc_strategy;
	enum FF_RC_STRATEGY_XVID = 1;

	int b_frame_strategy;
	float b_quant_offset;
	int has_b_frames;

	int mpeg_quant;
	float i_quant_factor;
	float i_quant_offset;

	float lumi_masking;
	float temporal_cplx_masking;
	float spatial_cplx_masking;

	float p_masking;
	float dark_masking;
	int slice_count;

	int prediction_method;
	enum FF_PRED_LEFT = 0;
	enum FF_PRED_PLANE = 1;
	enum FF_PRED_MEDIAN = 2;

	int* slice_offset;
	AVRational sample_aspect_ratio;

	int me_cmp;
	int me_sub_cmp;
	int mb_cmp;
	int ildct_cmp;
	enum FF_CMP_SAD = 0;
	enum FF_CMP_SSE = 1;
	enum FF_CMP_SATD = 2;
	enum FF_CMP_DCT = 3;
	enum FF_CMP_PSNR = 4;
	enum FF_CMP_BIT = 5;
	enum FF_CMP_RD = 6;
	enum FF_CMP_ZERO = 7;
	enum FF_CMP_VSAD = 8;
	enum FF_CMP_VSSE = 9;
	enum FF_CMP_NSSE = 10;
	enum FF_CMP_DCTMAX = 13;
	enum FF_CMP_DCT256 = 14;
	enum FF_CMP_CHROMA = 256;

	int dia_size;

	int last_predictor_count;
	int pre_me;
	int me_pre_cmp;

	int pre_dia_size;
	int me_subpel_quality;
	int dtg_active_format;
	enum FF_DTG_AFD_SAME = 8;
	enum FF_DTG_AFD_4_3 = 9;
	enum FF_DTG_AFD_16_9 = 10;
	enum FF_DTG_AFD_14_9 = 11;
	enum FF_DTG_AFD_4_3_SP_14_9 = 13;
	enum FF_DTG_AFD_16_9_SP_14_9 = 14;
	enum FF_DTG_AFD_SP_4_3 = 15;

	int me_range;
	int intra_quant_bias;
	enum FF_DEFAULT_QUANT_BIAS = 999999;

	int inter_quant_bias;

	int slice_flags;
	enum SLICE_FLAG_CODED_ORDER = 0x0001;
	enum SLICE_FLAG_ALLOW_FIELD = 0x0002;
	enum SLICE_FLAG_ALLOW_PLANE = 0x0004;

	static if (FF_API_XVMC)
		deprecated int xvmc_acceleration;

	int mb_decision;
	enum FF_MB_DECISION_SIMPLE = 0;
	enum FF_MB_DECISION_BITS = 1;
	enum FF_MB_DECISION_RD = 2;

	ushort* intra_matrix;
	ushort* inter_matrix;

	int scenechange_threshold;
	int noise_reduction;
	int me_threshold;
	int mb_threshold;

	int intra_dc_precision;
	int skip_top;
	int skip_bottom;

	float border_masking;
	int mb_lmin;
	int mb_lmax;

	int me_penalty_compensation;
	int bidir_refine;
	int brd_scale;

	int keyint_min;
	int refs;
	int chromaoffset;

	int scenechange_factor;
	int mv0_threshold;
	int b_sensitivity;

	AVColorPrimaries color_primaries;
	AVColorTransferCharacteristic color_trc;
	AVColorSpace colorspace;
	AVColorRange color_range;
	AVChromaLocation chroma_sample_location;

	int slices;
	AVFieldOrder field_order;
	int sample_rate;
	int channels;
	AVSampleFormat sample_fmt;

	int frame_size;
	int frame_number;
	int block_align;
	int cutoff;

	static if (FF_API_REQUEST_CHANNELS)
		deprecated int request_channels;

	ulong channel_layout;
	ulong request_channel_layout;

	AVAudioServiceType audio_service_type;
	AVSampleFormat request_sample_fmt;

	static if (FF_API_GET_BUFFER) {
		deprecated int function(AVCodecContext *c, AVFrame *pic) get_buffer;
		deprecated void function(AVCodecContext *c, AVFrame *pic)
			release_buffer;
		deprecated int function(AVCodecContext *c, AVFrame *pic) reget_buffer;
	}

	int function(AVCodecContext *s, AVFrame *frame, int flags) get_buffer2;

	int refcounted_frames;
	float qcompress;
	float qblur;
	int qmin;
	int qmax;
	int max_qdiff;

	float rc_qsquish;
	float rc_qmod_amp;
	int rc_qmod_freq;
	int rc_buffer_size;
	int rc_override_count;
	RcOverride * rc_override;
	const char * rc_eq;
	int rc_max_rate;
	int rc_min_rate;
	float rc_buffer_aggressivity;
	float rc_initial_cplx;
	float rc_max_available_vbv_use;
	float rc_min_vbv_overflow_use;
	int rc_initial_buffer_occupancy;
	enum FF_CODER_TYPE_VLC = 0;
	enum FF_CODER_TYPE_AC = 1;
	enum FF_CODER_TYPE_RAW = 2;
	enum FF_CODER_TYPE_RLE = 3;
	enum FF_CODER_TYPE_DEFLATE = 4;

	int coder_type;
	int context_model;
	int lmin;
	int lmax;
	int frame_skip_threshold;
	int frame_skip_factor;
	int frame_skip_exp;
	int frame_skip_cmp;

	int trellis;
	int min_prediction_order;
	int max_prediction_order;
	long timecode_frame_start;

	void function(AVCodecContext *avctx, void *data, int s, int mb_nb)
		rtp_callback;

	int rtp_payload_size;

	int mv_bits;
    int header_bits;
    int i_tex_bits;
    int p_tex_bits;
    int i_count;
    int p_count;
    int skip_count;
    int misc_bits;

	int frame_bits;
	char *stats_out;
	char *stats_in;

	int workaround_bugs;
	enum FF_BUG_AUTODETECT = 1;
	static if (FF_API_OLD_MSMPEG4)
		enum FF_BUG_OLD_MSMPEG4 = 2;
	enum FF_BUG_XVID_ILACE = 4;
	enum FF_BUG_UMP4 = 8;
	enum FF_BUG_NO_PADDING = 16;
	enum FF_BUG_AMV = 32;
	static if (FF_API_AC_VLC)
		enum FF_BUG_AC_VLC = 0;
	enum FF_BUG_QPEL_CHROMA = 64;
	enum FF_BUG_STD_QPEL = 128;
	enum FF_BUG_QPEL_CHROMA2 = 256;
	enum FF_BUG_DIRECT_BLOCKSIZE = 512;
	enum FF_BUG_EDGE = 1024;
	enum FF_BUG_HPEL_CHROMA = 2048;
	enum FF_BUG_DC_CLIP = 4096;
	enum FF_BUG_MS = 8192;
	enum FF_BUG_TRUNCATED = 16384;

	int strict_std_compliance;
	enum FF_COMPLIANCE_VERY_STRICT = 2;
	enum FF_COMPLIANCE_STRICT = 1;
	enum FF_COMPLIANCE_NORMAL = 0;
	enum FF_COMPLIANCE_UNOFFICIAL = -1;
	enum FF_COMPLIANCE_EXPERIMENTAL = -2;

	int error_concealment;
	enum FF_EC_GUESS_MVS = 1;
	enum FF_EC_DEBLOCK = 2;

	int debug_;
	enum FF_DEBUG_PICT_INFO = 1;
	enum FF_DEBUG_RC = 2;
	enum FF_DEBUG_BITSTREAM = 4;
	enum FF_DEBUG_MB_TYPE = 8;
	enum FF_DEBUG_QP = 16;
	static if (FF_API_DEBUG_MV)
		deprecated enum FF_DEBUG_MV = 32;
	enum FF_DEBUG_DCT_COEFF       = 0x00000040;
	enum FF_DEBUG_SKIP            = 0x00000080;
	enum FF_DEBUG_STARTCODE       = 0x00000100;
	enum FF_DEBUG_PTS             = 0x00000200;
	enum FF_DEBUG_ER              = 0x00000400;
	enum FF_DEBUG_MMCO            = 0x00000800;
	enum FF_DEBUG_BUGS            = 0x00001000;
	static if (FF_API_DEBUG_MV) {
		enum FF_DEBUG_VIS_QP      = 0x00002000;
		enum FF_DEBUG_VIS_MB_TYPE = 0x00004000;
	}
	enum FF_DEBUG_BUFFERS         = 0x00008000;
	enum FF_DEBUG_THREADS         = 0x00010000;

	static if (FF_API_DEBUG_MV) {
		deprecated {
			int debug_mv;
			enum FF_DEBUG_VIS_MV_P_FOR = 0x00000001;
			enum FF_DEBUG_VIS_MV_B_FOR = 0x00000002;
			enum FF_DEBUG_VIS_MV_B_BACK = 0x00000004;
		}
	}

	int err_recognition;
	enum AV_EF_CRCCHECK = 1 << 0;
	enum AV_EF_BITSTREAM = 1 << 1;
	enum AV_EF_BUFFER = 1 << 2;
	enum AV_EF_EXPLODE = 1 << 3;

	long reordered_opaque;

	AVHWAccel *hwaccel;

	long error[AV_NUM_DATA_POINTERS];

	int dct_algo;
	enum FF_DCT_AUTO = 0;
	enum FF_DCT_FASTINT = 1;
	enum FF_DCT_INT = 2;
	enum FF_DCT_MMX = 3;
	enum FF_DCT_ALTIVEC = 5;
	enum FF_DCT_FAAN = 6;

	int idct_algo;
	enum FF_IDCT_AUTO = 0;
	enum FF_IDCT_INT = 1;
	enum FF_IDCT_SIMPLE = 2;
	enum FF_IDCT_SIMPLEMMX = 3;
	enum FF_IDCT_ARM = 7;
	enum FF_IDCT_ALTIVEC = 8;
	enum FF_IDCT_SH4 = 9;
	enum FF_IDCT_SIMPLEARM = 10;
	enum FF_IDCT_IPP = 13;
	enum FF_IDCT_XVIDMMX = 14;
	enum FF_IDCT_SIMPLEARMV5TE = 16;
	enum FF_IDCT_SIMPLEARMV6 = 17;
	enum FF_IDCT_SIMPLEVIS = 18;
	enum FF_IDCT_FAAN = 20;
	enum FF_IDCT_SIMPLENEON = 22;
	static if (FF_API_ARCH_ALPHA)
		enum FF_IDCT_SIMPLEALPHA = 23;

	int bits_per_coded_sample;
	int bits_per_raw_sample;

	static if (FF_API_LOWRES)
		deprecated int lowres;

	AVFrame *coded_frame;

	int thread_count;
	int thread_type;
	enum FF_THREAD_FRAME = 1;
	enum FF_THREAD_SLICE = 2;

	int active_thread_type;
	int thread_safe_callbacks;

	int function(AVCodecContext *c, int function(AVCodecContext *c2, void *),
				 void *arg2, int *ret, int count, int size) execute;

	int function(AVCodecContext *c, int function(AVCodecContext *c2, void *,
												 int jobnr, int threadnr),
				 void *arg2, int *ret, int count) execute2;

	static if (FF_API_THREAD_OPAQUE)
		deprecated void* thread_opaque;

	int nsse_weight;

	int profile;
	enum FF_PROFILE_UNKNOWN = -99;
	enum FF_PROFILE_RESERVED = -100;

	enum FF_PROFILE_AAC_MAIN = 0;
	enum FF_PROFILE_AAC_LOW = 1;
	enum FF_PROFILE_AAC_SSR = 2;
	enum FF_PROFILE_AAC_LTP = 3;
	enum FF_PROFILE_AAC_HE = 4;
	enum FF_PROFILE_AAC_HE_V2 = 28;
	enum FF_PROFILE_AAC_LD = 22;
	enum FF_PROFILE_AAC_ELD = 38;
	enum FF_PROFILE_MPEG2_AAC_LOW = 128;
	enum FF_PROFILE_MPEG2_AAC_HE = 131;

	enum FF_PROFILE_DTS = 20;
	enum FF_PROFILE_DTS_ES = 30;
	enum FF_PROFILE_DTS_96_24 = 40;
	enum FF_PROFILE_DTS_HD_HRA = 50;
	enum FF_PROFILE_DTS_HD_MA = 60;

	enum FF_PROFILE_MPEG2_422 = 0;
	enum FF_PROFILE_MPEG2_HIGH = 1;
	enum FF_PROFILE_MPEG2_SS = 2;
	enum FF_PROFILE_MPEG2_SNR_SCALABLE = 3;
	enum FF_PROFILE_MPEG2_MAIN   = 4;
	enum FF_PROFILE_MPEG2_SIMPLE = 5;

	enum FF_PROFILE_H264_CONSTRAINED = (1<<9);
	enum FF_PROFILE_H264_INTRA       = (1<<11);

	enum FF_PROFILE_H264_BASELINE            = 66;
	enum FF_PROFILE_H264_CONSTRAINED_BASELINE =
		(66|FF_PROFILE_H264_CONSTRAINED);
	enum FF_PROFILE_H264_MAIN                = 77;
	enum FF_PROFILE_H264_EXTENDED            = 88;
	enum FF_PROFILE_H264_HIGH                = 100;
	enum FF_PROFILE_H264_HIGH_10             = 110;
	enum FF_PROFILE_H264_HIGH_10_INTRA       = (110|FF_PROFILE_H264_INTRA);
	enum FF_PROFILE_H264_HIGH_422            = 122;
	enum FF_PROFILE_H264_HIGH_422_INTRA      = (122|FF_PROFILE_H264_INTRA);
	enum FF_PROFILE_H264_HIGH_444            = 144;
	enum FF_PROFILE_H264_HIGH_444_PREDICTIVE = 244;
	enum FF_PROFILE_H264_HIGH_444_INTRA      = (244|FF_PROFILE_H264_INTRA);
	enum FF_PROFILE_H264_CAVLC_444 = 44;
	enum FF_PROFILE_VC1_SIMPLE   = 0;
	enum FF_PROFILE_VC1_MAIN     = 1;
	enum FF_PROFILE_VC1_COMPLEX  = 2;
	enum FF_PROFILE_VC1_ADVANCED = 3;

	enum FF_PROFILE_MPEG4_SIMPLE                    =  0;
	enum FF_PROFILE_MPEG4_SIMPLE_SCALABLE           =  1;
	enum FF_PROFILE_MPEG4_CORE                      =  2;
	enum FF_PROFILE_MPEG4_MAIN                      =  3;
	enum FF_PROFILE_MPEG4_N_BIT                     =  4;
	enum FF_PROFILE_MPEG4_SCALABLE_TEXTURE          =  5;
	enum FF_PROFILE_MPEG4_SIMPLE_FACE_ANIMATION     =  6;
	enum FF_PROFILE_MPEG4_BASIC_ANIMATED_TEXTURE    =  7;
	enum FF_PROFILE_MPEG4_HYBRID                    =  8;
	enum FF_PROFILE_MPEG4_ADVANCED_REAL_TIME        =  9;
	enum FF_PROFILE_MPEG4_CORE_SCALABLE             = 10;
	enum FF_PROFILE_MPEG4_ADVANCED_CODING           = 11;
	enum FF_PROFILE_MPEG4_ADVANCED_CORE             = 12;
	enum FF_PROFILE_MPEG4_ADVANCED_SCALABLE_TEXTURE = 13;
	enum FF_PROFILE_MPEG4_SIMPLE_STUDIO             = 14;
	enum FF_PROFILE_MPEG4_ADVANCED_SIMPLE           = 15;

	enum FF_PROFILE_JPEG2000_CSTREAM_RESTRICTION_0  = 0;
	enum FF_PROFILE_JPEG2000_CSTREAM_RESTRICTION_1  = 1;
	enum FF_PROFILE_JPEG2000_CSTREAM_NO_RESTRICTION = 2;
	enum FF_PROFILE_JPEG2000_DCINEMA_2K             = 3;
	enum FF_PROFILE_JPEG2000_DCINEMA_4K             = 4;

	enum FF_PROFILE_HEVC_MAIN                       = 1;
	enum FF_PROFILE_HEVC_MAIN_10                    = 2;
	enum FF_PROFILE_HEVC_MAIN_STILL_PICTURE         = 3;

	int level;
	enum FF_LEVEL_UNKNOWN = -99;
	
	AVDiscard skip_loop_filter;
	AVDiscard skip_idct;
	AVDiscard skip_frame;

	ubyte *subtitle_header;
	int subtitle_header_size;

	static if (FF_API_ERROR_RATE)
		deprecated int error_rate;

	static if (FF_API_CODEC_PKT)
		deprecated AVPacket *pkt;

	long vbv_delay;
}

struct AVProfile {
	int profile;
	const char *name;
};

struct AVCodecDefault;

struct AVCodec {
	const char *name;
	const char *long_name;

	AVMediaType type;
    AVCodecID id;

    int capabilities;
    const AVRational *supported_framerates;
    const AVPixelFormat *pix_fmts;
	const int *supported_samplerates;
	const AVSampleFormat *sample_fmts;
	const ulong *channel_layouts;
	static if (FF_API_LOWRES)
		deprecated ubyte max_lowres;
	const AVClass *priv_class;
	const AVProfile *profiles;

	/* private fields not written */
}

struct AVHWAccel {
	const char *name;
	AVMediaType type;
	AVCodecID id;
	AVPixelFormat pix_fmt;

	int capabilities;
	AVHWAccel *next;

	int function(AVCodecContext *avcctx, const ubyte *buf, uint buf_size)
		start_frame;
	int function(AVCodecContext *avcctx, const ubyte *buf, uint buf_size)
		decode_slice;
	int function(AVCodecContext *avcctx) end_frame;

	int priv_data_size;
}

struct AVPicture {
	ubyte *data[AV_NUM_DATA_POINTERS];
	int linesize[AV_NUM_DATA_POINTERS];
};

enum AVPALETTE_SIZE = 1024;
enum AVPALETTE_COUNT = 256;

enum AVSubtitleType {
    SUBTITLE_NONE,
    SUBTITLE_BITMAP,
    SUBTITLE_TEXT,
    SUBTITLE_ASS,
};

enum AV_SUBTITLE_FLAG_FORCED = 0x00000001;

struct AVSubtitleRect {
	int x;
	int y;
	int w;
	int h;
	int nb_colors;

	AVPicture pict;
	AVSubtitleType type;

	char *text;

	char *ass;
	int flags;
};

struct AVSubtitle {
	ushort format;
	uint start_display_time;
	uint end_display_time;
	uint num_rects;
	AVSubtitleRect **rects;
	long pts;
};

AVCodec *av_codec_next(const AVCodec *c);

uint avcodec_version();
const(char) *avcodec_configuration();
const(char) *avcodec_license();
void avcodec_register(AVCodec *codec);
void avcodec_register_all();

AVCodecContext *avcodec_alloc_context3(const AVCodec *codec);
int avcodec_get_context_defaults3(AVCodecContext *s, const AVCodec *codec);
const(AVClass) *avcodec_get_class();

int avcodec_copy_context(AVCodecContext *dest, const AVCodecContext *src);

static if (FF_API_AVFRAME_LAVC) {
	deprecated AVFrame *avcodec_alloc_frame();
	deprecated void avcodec_get_frame_defaults(AVFrame *frame);
	deprecated void avcodec_free_frame(AVFrame **frame);
}

int avcodec_open2(AVCodecContext *avctx, const AVCodec *codec,
				  AVDictionary **options);
int avcodec_close(AVCodecContext *avctx);
void avsubtitle_free(AVSubtitle *sub);

static if (FF_API_DESTRUCT_PACKET)
	deprecated void av_destruct_packet(AVPacket *pkt);

void av_init_packet(AVPacket *pkt);
int av_new_packet(AVPacket *pkt, int size);
void av_shrink_packet(AVPacket *pkt, int size);
int av_grow_packet(AVPacket *pkt, int grow_by);
int av_packet_from_data(AVPacket *pkt, ubyte *data, int size);
int av_dup_packet(AVPacket *pkt);

void av_free_packet(AVPacket *pkt);

ubyte* av_packet_new_side_data(AVPacket *pkt, AVPacketSideDataType type,
							   int size);
int av_packet_shrink_side_data(AVPacket *pkt, AVPacketSideDataType type,
                               int size);
ubyte* av_packet_get_side_data(AVPacket *pkt, AVPacketSideDataType type,
							   int *size);
void av_packet_free_side_data(AVPacket *pkt);

int av_packet_ref(AVPacket *dst, AVPacket *src);
void av_packet_unref(AVPacket *pkt);

void av_packet_move_ref(AVPacket *dst, AVPacket *src);
int av_packet_copy_props(AVPacket *dst, const AVPacket *src);

AVCodec *avcodec_find_decoder(AVCodecID id);

/**
 * Find a registered decoder with the specified name.
 *
 * @param name name of the requested decoder
 * @return A decoder if one was found, NULL otherwise.
 */
AVCodec *avcodec_find_decoder_by_name(const char *name);

static if (FF_API_GET_BUFFER) {
	deprecated int avcodec_default_get_buffer(AVCodecContext *s, AVFrame *pic);
	deprecated void avcodec_default_release_buffer(AVCodecContext *s,
												   AVFrame *pic);
	deprecated int avcodec_default_reget_buffer(AVCodecContext *s,
												AVFrame *pic);
}

int avcodec_default_get_buffer2(AVCodecContext *s, AVFrame *frame, int flags);

static if (FF_API_EMU_EDGE)
	deprecated uint avcodec_get_edge_width();

void avcodec_align_dimensions(AVCodecContext *s, int *width, int *height);
void avcodec_align_dimensions2(AVCodecContext *s, int *width, int *height,
                               int linesize_align[AV_NUM_DATA_POINTERS]);

int avcodec_decode_audio4(AVCodecContext *avctx, AVFrame *frame,
                          int *got_frame_ptr, AVPacket *avpkt);
