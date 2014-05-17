module libavformat.avio;

import core.stdc.stdio;

public {
	import libavutil.common;
	import libavutil.dict;
	import libavutil.log;

	import libavformat.version_;
}

extern(C):
nothrow:

enum AVIO_SEEKABLE_NORMAL = 0x0001;

struct AVIOInterruptCB {
    int function(void *) callback;
    void *opaque;
};

/* XXX: TODO: AVIOContext */
struct AVIOContext;

int avio_check(const char *url, int flags);

AVIOContext *avio_alloc_context(
	ubyte *buffer, int buffer_size,	int write_flag,	void *opaque,
	int function(void *opaque, ubyte *buf, int buf_size) read_packet,
	int function(void *opaque, ubyte *buf, int buf_size) write_packet,
	long function(void *opaque, long offset, int whence) seek);

void avio_w8(AVIOContext *s, int b);
void avio_write(AVIOContext *s, const ubyte *buf, int size);
void avio_wl64(AVIOContext *s, ulong val);
void avio_wb64(AVIOContext *s, ulong val);
void avio_wl32(AVIOContext *s, uint val);
void avio_wb32(AVIOContext *s, uint val);
void avio_wl24(AVIOContext *s, uint val);
void avio_wb24(AVIOContext *s, uint val);
void avio_wl16(AVIOContext *s, uint val);
void avio_wb16(AVIOContext *s, uint val);

int avio_put_str(AVIOContext *s, const char *str);

int avio_put_str16le(AVIOContext *s, const char *str);

enum AVSEEK_SIZE  = 0x10000;
enum AVSEEK_FORCE = 0x20000;

long avio_seek(AVIOContext *s, long offset, int whence);

long avio_skip(AVIOContext *s, long offset)
{
    return avio_seek(s, offset, SEEK_CUR);
}

long avio_tell(AVIOContext *s)
{
    return avio_seek(s, 0, SEEK_CUR);
}

long avio_size(AVIOContext *s);

int avio_printf(AVIOContext *s, const char *fmt, ...);

void avio_flush(AVIOContext *s);

int avio_read(AVIOContext *s, ubyte *buf, int size);

int   avio_r8  (AVIOContext *s);
uint  avio_rl16(AVIOContext *s);
uint  avio_rl24(AVIOContext *s);
uint  avio_rl32(AVIOContext *s);
ulong avio_rl64(AVIOContext *s);
uint  avio_rb16(AVIOContext *s);
uint  avio_rb24(AVIOContext *s);
uint  avio_rb32(AVIOContext *s);
ulong avio_rb64(AVIOContext *s);

int avio_get_str(AVIOContext *pb, int maxlen, char *buf, int buflen);

int avio_get_str16le(AVIOContext *pb, int maxlen, char *buf, int buflen);
int avio_get_str16be(AVIOContext *pb, int maxlen, char *buf, int buflen);

enum AVIO_FLAG_READ       = 1;
enum AVIO_FLAG_WRITE      = 2;
enum AVIO_FLAG_READ_WRITE = (AVIO_FLAG_READ|AVIO_FLAG_WRITE);
enum AVIO_FLAG_NONBLOCK   = 8;

int avio_open(AVIOContext **s, const char *url, int flags);
int avio_open2(AVIOContext **s, const char *url, int flags,
               const AVIOInterruptCB *int_cb, AVDictionary **options);

int avio_close(AVIOContext *s);
int avio_closep(AVIOContext **s);

int avio_open_dyn_buf(AVIOContext **s);
int avio_close_dyn_buf(AVIOContext *s, ubyte **pbuffer);

const char *avio_enum_protocols(void **opaque, int output);

int avio_pause(AVIOContext *h, int pause);

long avio_seek_time(AVIOContext *h, int stream_index,
					long timestamp, int flags);
