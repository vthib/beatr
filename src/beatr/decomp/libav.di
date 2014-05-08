module libav;

extern(C):
nothrow:

enum AV_TIME_BASE = 1000000;

/* structs not yet translated */
alias void* AVDictionary;
alias void* AVInputFormat;
alias void* AVOutputFormat;
alias void* AVIOContext;
alias void* AVProgram;
alias void* AVFrac;
alias void* AVChapter;
alias void* AVIOInterruptCB;
alias void* AVRational;
alias void* AVFormatInternal;
alias void* AVClass;
alias void* AVPacketSideData;
alias void* AVBufferRef;
alias void* AVFrameSideData;
alias void* AVCodecInternal;
alias void* RcOverride;

/* enum not yet translated */
alias int AVCodecID;
alias int AVDiscard;
alias int AVPictureType;
alias int AVSampleFormat;
alias int AVColorPrimaries;
alias int AVColorTransferCharacteristic;
alias int AVColorSpace;
alias int AVColorRange;
alias int AVChromaLocation;
alias int AVFieldOrder;
alias int AVPixelFormat;
alias int AVAudioServiceType;

enum AVMediaType {
	AVMEDIA_TYPE_UNKNOWN = -1,
	AVMEDIA_TYPE_VIDEO,
	AVMEDIA_TYPE_AUDIO,
	AVMEDIA_TYPE_DATA,    
	AVMEDIA_TYPE_SUBTITLE,
	AVMEDIA_TYPE_ATTACHMENT,
	AVMEDIA_TYPE_NB
};

enum AVERROR_EOF = -0x5fb9b0bb;

struct AVPacket {
	AVBufferRef* buf;
	long pts;
	long dts;
	byte* data;
	int size;
	int stream_index;
	int flags;
	AVPacketSideData* side_data;
	int side_data_elems;
	int duration;
	void function(AVPacket *) destruct;
	void* priv;
	long pos;
	long convergence_duration;
}

struct AVPacketList {
	AVPacket pkt;
	AVPacketList *next;
}

enum AV_NUM_DATA_POINTERS = 8;

struct AVFrame {
	byte* data[AV_NUM_DATA_POINTERS];
	int linesize[AV_NUM_DATA_POINTERS];
	byte** extended_data;
	int width;
	int height;
	int nb_samples;
	int format;
	int key_frame;
	AVPictureType pict_type;
	AVRational sample_aspect_ratio;
	long pts;
	long pkt_pts;
	long pkt_dts;
	int coded_picture_number;
	int display_picture_number;
	int quality;
	void* opaque;
	long error[AV_NUM_DATA_POINTERS];
	int repeat_pict;
	int interlaced_frame;
	int top_field_first;
	int palette_has_changed;
	long reordered_opaque;
	int sample_rate;
    long channel_layout;
	AVBufferRef* buf[AV_NUM_DATA_POINTERS];
	AVBufferRef** extended_buf;
	int nb_extended_buf;
	AVFrameSideData** side_data;
	int nb_side_data;
	int flags;
}

struct AVFormatContext {
	AVClass *av_class;

	AVInputFormat *iformat;
	AVOutputFormat *oformat;

	void *priv_data;

	AVIOContext *pb;

	/* stream info */
	int ctx_flags;
	uint nb_streams;
	AVStream **streams;

	char filename[1024];

	long start_time;
	long duration;

	int bit_rate;

	uint packet_size;
	int max_delay;

	int flags;

	uint probesize;

	int max_analyze_duration;

	byte *key;
	int keylen;

	uint nb_programs;
	AVProgram **programs;

	AVCodecID video_codec_id;
	AVCodecID audio_codec_id;
	AVCodecID subtitle_codec_id;

	uint max_index_size;

	uint max_picutre_buffer;

	uint nb_chapters;
	AVChapter **chapters;

	AVDictionary *metadata;

	long start_time_realtime;

	int fps_probe_size;

	int error_recognition;

	AVIOInterruptCB interrupt_callback;

	int debug_;

	long max_interleave_delta;

	AVPacketList *packet_buffer;
	AVPacketList *packet_buffer_end;

	long data_offset;
	AVPacketList *raw_packet_buffer;
	AVPacketList *raw_packet_buffer_end;
	AVPacketList *parse_queue;
	AVPacketList *parse_queue_end;
	int raw_packet_buffer_remaining_size;

	long offset;

	AVRational offset_timebase;

	AVFormatInternal *internal;
}

struct AVStream {
	int index;
	int id;
	AVCodecContext* codec;
	void* priv_data;

	AVFrac pts;

	AVRational time_base;

	long start_time;

	long duration;

	long nb_frames;

	int disposition;
	AVDiscard discard;

	AVRational sample_aspect_ratio;

	AVDictionary* metadata;

	AVRational avg_frame_rate;

	AVPacket attached_pic;

	AVPacketSideData* side_data;
	int nb_side_data;

	void* private_fields;
}

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

	int flags;
	int flags2;
	byte* extradata;
	int extradata_size;

	AVRational time_base;
	int ticks_per_frame;

	int delay;
	int width;
	int height;

	int coded_width;
	int coded_height;
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
	int* slice_offset;
	AVRational sample_aspect_ratio;

	int me_cmp;
	int me_sub_cmp;
	int mb_cmp;
	int ildct_cmp;
	int dia_size;

	int last_predictor_count;
	int pre_me;
	int me_pre_cmp;

	int pre_dia_size;
	int me_subpel_quality;
	int dtg_active_format;

	int me_range;
	int intra_quant_bias;
	int inter_quant_bias;

	int slice_flags;
//	int xvmc_acceleration;
	int mb_decision;

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
	int request_channels;
	long channel_layout;
	long request_channel_layout;
	AVAudioServiceType audio_service_type;
	AVSampleFormat request_sample_fmt;
	int function(AVCodecContext *c, AVFrame *pic) get_buffer;
	void function(AVCodecContext *c, AVFrame *pic) release_buffer;
	int function(AVCodecContext *c, AVFrame *pic) reget_buffer;
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
	int coder_type;
	int context_model;
	int lmin;
	int lmax;
	int frame_skip_threshold;
	int frame_skip_factor;
	int frame_skip_exp;
	int frame_skip_cmp;
}

struct AVCodec {
	const char *name;
	const char *long_name;
	AVMediaType type;
	AVCodecID id;

	void* rest; /* XXX: complete */
};

int avformat_open_input(AVFormatContext **ps, const char *filename,
						AVInputFormat *fmt, AVDictionary **options);
void avformat_close_input(AVFormatContext **s);

void av_register_all();
int avformat_find_stream_info(AVFormatContext *ic, AVDictionary **options);

AVCodec *avcodec_find_decoder(AVCodecID id);
int avcodec_open2(AVCodecContext *avctx, const AVCodec *codec,
				  AVDictionary **options);
int avcodec_close(AVCodecContext* avctx);

AVCodecContext* avcodec_alloc_context3(const AVCodec *codec);

int av_strerror(int errnum, char *errbuf, size_t errbuf_size);
void av_free(void* ptr);


AVFrame* av_frame_alloc();
void av_frame_free(AVFrame** frame);
void av_frame_unref(AVFrame* frame);

void av_init_packet(AVPacket* pkt);
unittest
{
	AVPacket pkt;
	av_init_packet(&pkt);
	assert(pkt.pos == -1L);
//	assert(pkt.data !is null);
}

int av_read_frame(AVFormatContext* s, AVPacket* pkt);

int avcodec_decode_audio4(AVCodecContext* avctx, AVFrame* frame,
						  int* got_frame_ptr, AVPacket* avpkt);

int av_samples_get_buffer_size(int* linesize, int nb_channels, int nb_samples,
							   AVSampleFormat sample_fmt, int alignment);
int av_get_bytes_per_sample(AVSampleFormat sample_fmt);

const char* av_get_sample_fmt_name(AVSampleFormat sample_fmt);
