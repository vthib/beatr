module libavutil.opt;

public import libavutil.rational;
public import libavutil.avutil;
public import libavutil.dict;
public import libavutil.log;

extern(C):
nothrow:

enum AVOptionType{
    AV_OPT_TYPE_FLAGS,
    AV_OPT_TYPE_INT,
    AV_OPT_TYPE_INT64,
    AV_OPT_TYPE_DOUBLE,
    AV_OPT_TYPE_FLOAT,
    AV_OPT_TYPE_STRING,
    AV_OPT_TYPE_RATIONAL,
    AV_OPT_TYPE_BINARY,
    AV_OPT_TYPE_CONST = 128,
};

struct AVOption {
	const char *name;
    const char *help;

    int offset;
    AVOptionType type;

	union default_val {
		long i64;
		double dbl;
		const char *str;
        AVRational q;
    };
	double min;
	double max;

    int flags;
	enum AV_OPT_FLAG_ENCODING_PARAM = 1;
	enum AV_OPT_FLAG_DECODING_PARAM = 2;
	enum AV_OPT_FLAG_METADATA = 4;
	enum AV_OPT_FLAG_AUDIO_PARAM = 8;
	enum AV_OPT_FLAG_VIDEO_PARAM = 16;
	enum AV_OPT_FLAG_SUBTITLE_PARAM = 32;

	const char *unit;
}

int av_opt_show2(void *obj, void *av_log_obj, int req_flags, int rej_flags);
void av_opt_set_defaults(void *s);
int av_set_options_string(void *ctx, const char *opts,
                          const char *key_val_sep, const char *pairs_sep);
void av_opt_free(void *obj);

int av_opt_flag_is_set(void *obj, const char *field_name,
					   const char *flag_name);

int av_opt_set_dict(void *obj, AVDictionary **options);

int av_opt_eval_flags (void *obj, const AVOption *o, const char *val,
					   int *flags_out);
int av_opt_eval_int   (void *obj, const AVOption *o, const char *val,
					   int *int_out);
int av_opt_eval_int64 (void *obj, const AVOption *o, const char *val,
					   long *int64_out);
int av_opt_eval_float (void *obj, const AVOption *o, const char *val,
					   float *float_out);
int av_opt_eval_double(void *obj, const AVOption *o, const char *val,
					   double *double_out);
int av_opt_eval_q     (void *obj, const AVOption *o, const char *val,
					   AVRational *q_out);

enum AV_OPT_SEARCH_CHILDREN = 0x0001;
enum AV_OPT_SEARCH_FAKE_OBJ = 0x0002;

const AVOption *av_opt_find(void *obj, const char *name, const char *unit,
                            int opt_flags, int search_flags);
const AVOption *av_opt_find2(void *obj, const char *name, const char *unit,
                             int opt_flags, int search_flags,
							 void **target_obj);
const AVOption *av_opt_next(void *obj, const AVOption *prev);

void *av_opt_child_next(void *obj, void *prev);

const AVClass *av_opt_child_class_next(const AVClass *parent,
									   const AVClass *prev);

int av_opt_set       (void *obj, const char *name, const char *val,
					  int search_flags);
int av_opt_set_int   (void *obj, const char *name, long        val,
					  int search_flags);
int av_opt_set_double(void *obj, const char *name, double      val,
					  int search_flags);
int av_opt_set_q     (void *obj, const char *name, AVRational  val,
					  int search_flags);
int av_opt_set_bin   (void *obj, const char *name, const ubyte *val, int size,
					  int search_flags);

int av_opt_get       (void *obj, const char *name, int search_flags,
					  ubyte     **out_val);
int av_opt_get_int   (void *obj, const char *name, int search_flags,
					  long       *out_val);
int av_opt_get_double(void *obj, const char *name, int search_flags,
					  double     *out_val);
int av_opt_get_q     (void *obj, const char *name, int search_flags,
					  AVRational *out_val);
