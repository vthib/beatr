module libavutil.log;

import core.vararg;

public import libavutil.avutil;
public import libavutil.attributes;

struct AVOption;

extern(C):

struct AVClass {
	const char *class_name;

	const char *function(void* ctx) item_name;

	const AVOption *option;

	int version_;

	int log_level_offset_offset;
	int parent_log_context_offset;

	void* function(void *obj, void *prev) child_next;

	const AVClass *function(const AVClass *prev) child_class_next;
};

enum AV_LOG_QUIET = -8;
enum AV_LOG_PANIC = 0;
enum AV_LOG_FATAL = 8;
enum AV_LOG_ERROR = 16;
enum AV_LOG_WARNING = 24;
enum AV_LOG_INFO = 32;
enum AV_LOG_VERBOSE = 40;
enum AV_LOG_DEBUG = 48;

nothrow {
void av_log(void *avcl, int level, const char *fmt, ...);
void av_vlog(void *avcl, int level, const char *fmt, va_list vl);

int av_log_get_level();
void av_log_set_level(int level);

void av_log_set_callback(void function(void*, int, const char*, va_list) cb);
void av_log_default_callback(void *avcl, int level, const char *fmt,
							 va_list vl);

const char* av_default_item_name(void* ctx);
}

debug {
	extern(C) void av_dlog(void* pctx, const char *fmt, ...) {
		va_list ap;

		version(X86_64) {
			va_start(ap, __va_argsave);
		} else version(X86) {
			va_start(ap, fmt);
		} else version(WIN64) {
			va_start(ap, fmt);
		} else
			static assert(false, "Unsupported platform");

		av_vlog(pctx, AV_LOG_DEBUG, fmt, ap);
		va_end(ap);
	}
} else {
	void av_dlog(void* pctx, ...) {}
}

enum AV_LOG_SKIP_REPEATED = 1;
void av_log_set_flags(int arg);
