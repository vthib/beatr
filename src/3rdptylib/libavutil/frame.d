module libavutil.frame;

public {
	import libavutil.avutil;
	import libavutil.buffer;
	import libavutil.dict;
	import libavutil.rational;
	import libavutil.samplefmt;
	import libavutil.version_;
}

extern(C):
nothrow:

enum AVFrameSideDataType {
    AV_FRAME_DATA_PANSCAN,
    AV_FRAME_DATA_A53_CC,
    AV_FRAME_DATA_STEREO3D,
    AV_FRAME_DATA_MATRIXENCODING,
    AV_FRAME_DATA_DOWNMIX_INFO,
};

struct AVFrameSideData {
    AVFrameSideDataType type;
    ubyte *data;
    int size;
    AVDictionary *metadata;
};

struct AVPanScan;
struct AVCodecContext;

enum AV_NUM_DATA_POINTERS = 8;

struct AVFrame {
    ubyte *data[AV_NUM_DATA_POINTERS];

    int linesize[AV_NUM_DATA_POINTERS];

    ubyte **extended_data;

    int width, height;
    int nb_samples;
    int format;

    int key_frame;

    AVPictureType pict_type;

	static if (FF_API_AVFRAME_LAVC)
		deprecated ubyte *base[AV_NUM_DATA_POINTERS];

    AVRational sample_aspect_ratio;

    long pts;
    long pkt_pts;
    long pkt_dts;

    int coded_picture_number;
    int display_picture_number;

    int quality;

	static if (FF_API_AVFRAME_LAVC) {
		deprecated int reference;
		deprecated byte *qscale_table;
		deprecated int qstride;
		deprecated int qscale_type;

		deprecated ubyte *mbskip_table;

		deprecated short[2]* motion_val[2];
		deprecated uint *mb_type;

		deprecated short *dct_coeff;

		deprecated byte *ref_index[2];
	}

    void *opaque;

    ulong error[AV_NUM_DATA_POINTERS];

	static if (FF_API_AVFRAME_LAVC)
		deprecated int type;

    int repeat_pict;
    int interlaced_frame;
    int top_field_first;
    int palette_has_changed;

	static if (FF_API_AVFRAME_LAVC) {
		deprecated int buffer_hints;
		deprecated AVPanScan *pan_scan;
	}

    long reordered_opaque;

	static if (FF_API_AVFRAME_LAVC) {
		deprecated void *hwaccel_picture_private;
		deprecated AVCodecContext *owner;
		deprecated void *thread_opaque;

		deprecated ubyte motion_subsample_log2;
	}

    int sample_rate;

    ulong channel_layout;

    AVBufferRef *buf[AV_NUM_DATA_POINTERS];
    AVBufferRef **extended_buf;
    int        nb_extended_buf;

    AVFrameSideData **side_data;
    int            nb_side_data;

	enum AV_FRAME_FLAG_CORRUPT = (1 << 0);

    int flags;
};

AVFrame *av_frame_alloc();
void av_frame_free(AVFrame **frame);

int av_frame_ref(AVFrame *dst, const AVFrame *src);

AVFrame *av_frame_clone(const AVFrame *src);

void av_frame_unref(AVFrame *frame);
void av_frame_move_ref(AVFrame *dst, AVFrame *src);

int av_frame_get_buffer(AVFrame *frame, int align_);
int av_frame_is_writable(AVFrame *frame);
int av_frame_make_writable(AVFrame *frame);
int av_frame_copy_props(AVFrame *dst, const AVFrame *src);

AVBufferRef *av_frame_get_plane_buffer(AVFrame *frame, int plane);

AVFrameSideData *av_frame_new_side_data(AVFrame *frame,
                                        AVFrameSideDataType type,
                                        int size);
AVFrameSideData *av_frame_get_side_data(const AVFrame *frame,
                                        AVFrameSideDataType type);
