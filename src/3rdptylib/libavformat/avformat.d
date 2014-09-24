module libavformat.avformat;

import core.stdc.stdio;

public {
	import libavcodec.avcodec;
	import libavutil.dict;
	import libavutil.log;

	import libavformat.avio;
	import libavformat.version_;
}

extern(C):
nothrow:

int av_get_packet(AVIOContext *s, AVPacket *pkt, int size);
int av_append_packet(AVIOContext *s, AVPacket *pkt, int size);

struct AVFrac {
	long val, num, dem;
};

struct AVCodecTag;

struct AVProbeData {
	const char *filename;
	ubyte *buf;
	int buf_size;
}

enum AVPROBE_SCORE_EXTENSION = 50;
enum AVPROBE_SCORE_MAX = 100;

enum AVPROBE_PADDING_SIZE = 32;

enum AVFMT_NOFILE        = 0x0001;
enum AVFMT_NEEDNUMBER    = 0x0002;

enum AVFMT_SHOW_IDS      = 0x0008;
enum AVFMT_RAWPICTURE    = 0x0020;
enum AVFMT_GLOBALHEADER  = 0x0040;
enum AVFMT_NOTIMESTAMPS  = 0x0080;
enum AVFMT_GENERIC_INDEX = 0x0100;
enum AVFMT_TS_DISCONT    = 0x0200;
enum AVFMT_VARIABLE_FPS  = 0x0400;
enum AVFMT_NODIMENSIONS  = 0x0800;
enum AVFMT_NOSTREAMS     = 0x1000;
enum AVFMT_NOBINSEARCH   = 0x2000;
enum AVFMT_NOGENSEARCH   = 0x4000;
enum AVFMT_NO_BYTE_SEEK  = 0x8000;
enum AVFMT_ALLOW_FLUSH   = 0x10000;
enum AVFMT_TS_NONSTRICT  = 0x20000;
enum AVFMT_TS_NEGATIVE   = 0x40000;

struct AVOutputFormat {
    const char *name;
    const char *long_name;
    const char *mime_type;
    const char *extensions;
	AVCodecID audio_codec;
    AVCodecID video_codec;
    AVCodecID subtitle_codec;
    int flags;

    AVCodecTag **codec_tag;

    AVClass *priv_class;
	AVOutputFormat *next;
    int priv_data_size;

    int function(AVFormatContext *) write_header;
    int function(AVFormatContext *, AVPacket *) write_packet;
    int function(AVFormatContext *) write_trailer;

    int function(AVFormatContext *, AVPacket *o, AVPacket *i,
				 int flush) interleave_packet;

    int function(AVCodecID id, int std_compliance) query_codec;
}

/* XXX: TODO AVInputFormat */
struct AVInputFormat;

enum AVStreamParseType {
    AVSTREAM_PARSE_NONE,
    AVSTREAM_PARSE_FULL,
    AVSTREAM_PARSE_HEADERS,
    AVSTREAM_PARSE_TIMESTAMPS,
    AVSTREAM_PARSE_FULL_ONCE
};

enum AVINDEX_KEYFRAME = 0x0001;

/* XXX: TODO: AVIndexEntry: contains bitfields */
struct AVIndexEntry;

enum AV_DISPOSITION_DEFAULT  = 0x0001;
enum AV_DISPOSITION_DUB      = 0x0002;
enum AV_DISPOSITION_ORIGINAL = 0x0004;
enum AV_DISPOSITION_COMMENT  = 0x0008;
enum AV_DISPOSITION_LYRICS   = 0x0010;
enum AV_DISPOSITION_KARAOKE  = 0x0020;

enum AV_DISPOSITION_FORCED           = 0x0040;
enum AV_DISPOSITION_HEARING_IMPAIRED = 0x0080;
enum AV_DISPOSITION_VISUAL_IMPAIRED  = 0x0100;
enum AV_DISPOSITION_CLEAN_EFFECTS    = 0x0200;
enum AV_DISPOSITION_ATTACHED_PIC     = 0x0400;

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

	/* Non-public fields not written */
}

enum AV_PROGRAM_RUNNING = 1;

/* XXX: TODO: AVProgram */
struct AVProgram;

enum AVFMTCTX_NOHEADER = 0x0001;

/* XXX: TODO: AVChapter */
struct AVChapter;

struct AVFormatInternal;

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
	enum AVFMT_FLAG_GENPTS          = 0x0001;
	enum AVFMT_FLAG_IGNIDX          = 0x0002;
	enum AVFMT_FLAG_NONBLOCK        = 0x0004;
	enum AVFMT_FLAG_IGNDTS          = 0x0008;
	enum AVFMT_FLAG_NOFILLIN        = 0x0010;
	enum AVFMT_FLAG_NOPARSE         = 0x0020;
	enum AVFMT_FLAG_NOBUFFER        = 0x0040;
	enum AVFMT_FLAG_CUSTOM_IO       = 0x0080;
	enum AVFMT_FLAG_DISCARD_CORRUPT = 0x0100;
	enum AVFMT_FLAG_FLUSH_PACKETS   = 0x0200;

	uint probesize;

	int max_analyze_duration;

	ubyte *key;
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
	enum FF_FDEBUG_TS = 0x0001;

	long max_interleave_delta;

	AVPacketList *packet_buffer;
	AVPacketList *packet_buffer_end;

	long data_offset;
	AVPacketList *raw_packet_buffer;
	AVPacketList *raw_packet_buffer_end;
	AVPacketList *parse_queue;
	AVPacketList *parse_queue_end;

	enum RAW_PACKET_BUFFER_SIZE = 2500000;
	int raw_packet_buffer_remaining_size;

	long offset;

	AVRational offset_timebase;

	AVFormatInternal *internal;
}

struct AVPacketList {
    AVPacket pkt;
    AVPacketList *next;
};

/*** Core ***/

uint avformat_version();
const(char) *avformat_configuration();
const(char) *avformat_license();

void av_register_all();

void av_register_input_format(AVInputFormat *format);
void av_register_output_format(AVOutputFormat *format);

int avformat_network_init();
int avformat_network_deinit();

AVInputFormat  *av_iformat_next(AVInputFormat  *f);
AVOutputFormat *av_oformat_next(AVOutputFormat *f);

AVFormatContext *avformat_alloc_context();

void avformat_free_context(AVFormatContext *s);
const(AVClass) *avformat_get_class();

AVStream *avformat_new_stream(AVFormatContext *s, AVCodec *c);
AVProgram *av_new_program(AVFormatContext *s, int id);

/*** Decoding ***/

AVInputFormat *av_find_input_format(const char *short_name);

AVInputFormat *av_probe_input_format(AVProbeData *pd, int is_opened);
AVInputFormat *av_probe_input_format2(AVProbeData *pd, int is_opened,
									  int *score_max);

int av_probe_input_buffer(AVIOContext *pb, AVInputFormat **fmt,
                          const char *filename, void *logctx,
                          uint offset, uint max_probe_size);

int avformat_open_input(AVFormatContext **ps, const char *filename,
						AVInputFormat *fmt, AVDictionary **options);

int avformat_find_stream_info(AVFormatContext *ic, AVDictionary **options);

int av_find_best_stream(AVFormatContext *ic, AVMediaType type,
                        int wanted_stream_nb, int related_stream,
                        AVCodec **decoder_ret, int flags);

int av_read_frame(AVFormatContext *s, AVPacket *pkt);
int av_seek_frame(AVFormatContext *s, int stream_index, long timestamp,
                  int flags);

int avformat_seek_file(AVFormatContext *s, int stream_index, long min_ts,
					   long ts, long max_ts, int flags);

int av_read_play(AVFormatContext *s);
int av_read_pause(AVFormatContext *s);

void avformat_close_input(AVFormatContext **s);

enum AVSEEK_FLAG_BACKWARD = 1;
enum AVSEEK_FLAG_BYTE     = 2;
enum AVSEEK_FLAG_ANY      = 4;
enum AVSEEK_FLAG_FRAME    = 8;

/*** encoding ***/

int avformat_write_header(AVFormatContext *s, AVDictionary **options);

int av_write_frame(AVFormatContext *s, AVPacket *pkt);

int av_interleaved_write_frame(AVFormatContext *s, AVPacket *pkt);

int av_write_trailer(AVFormatContext *s);

AVOutputFormat *av_guess_format(const char *short_name,
                                const char *filename,
                                const char *mime_type);

AVCodecID av_guess_codec(AVOutputFormat *fmt, const char *short_name,
						 const char *filename, const char *mime_type,
						 AVMediaType type);

/*** Misc ***/

void av_hex_dump(FILE *f, const ubyte *buf, int size);
void av_hex_dump_log(void *avcl, int level, const ubyte *buf, int size);
void av_pkt_dump2(FILE *f, AVPacket *pkt, int dump_payload, AVStream *st);
void av_pkt_dump_log2(void *avcl, int level, AVPacket *pkt, int dump_payload,
                      AVStream *st);

AVCodecID av_codec_get_id(const AVCodecTag **tags, uint tag);
uint av_codec_get_tag(const AVCodecTag **tags, AVCodecID id);

int av_find_default_stream_index(AVFormatContext *s);

int av_index_search_timestamp(AVStream *st, long timestamp, int flags);

int av_add_index_entry(AVStream *st, long pos, long timestamp,
                       int size, int distance, int flags);

void av_url_split(char *proto,         int proto_size,
                  char *authorization, int authorization_size,
                  char *hostname,      int hostname_size,
                  int *port_ptr,
                  char *path,          int path_size,
                  const char *url);

void av_dump_format(AVFormatContext *ic, int index,
                    const char *url, int is_output);

int av_get_frame_filename(char *buf, int buf_size,
                          const char *path, int number);

int av_filename_number_test(const char *filename);

int av_sdp_create(AVFormatContext *ac[], int n_files, char *buf, int size);

int av_match_ext(const char *filename, const char *extensions);

int avformat_query_codec(AVOutputFormat *ofmt, AVCodecID codec_id,
						 int std_compliance);

const(AVCodecTag) *avformat_get_riff_video_tags();
const(AVCodecTag) *avformat_get_riff_audio_tags();
