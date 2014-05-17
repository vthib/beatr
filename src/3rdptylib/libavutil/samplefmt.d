module libavutil.samplefmt;

public {
	import libavutil.avutil;
	import libavutil.attributes;
}

extern(C):
nothrow:

enum AVSampleFormat {
    AV_SAMPLE_FMT_NONE = -1,
    AV_SAMPLE_FMT_U8,
    AV_SAMPLE_FMT_S16,
    AV_SAMPLE_FMT_S32,
    AV_SAMPLE_FMT_FLT,
    AV_SAMPLE_FMT_DBL,

    AV_SAMPLE_FMT_U8P,
    AV_SAMPLE_FMT_S16P,
    AV_SAMPLE_FMT_S32P,
    AV_SAMPLE_FMT_FLTP,
    AV_SAMPLE_FMT_DBLP,

    AV_SAMPLE_FMT_NB
};

const char *av_get_sample_fmt_name(AVSampleFormat sample_fmt);

AVSampleFormat av_get_sample_fmt(const char *name);
AVSampleFormat av_get_packed_sample_fmt(AVSampleFormat sample_fmt);
AVSampleFormat av_get_planar_sample_fmt(AVSampleFormat sample_fmt);

char *av_get_sample_fmt_string(char *buf, int buf_size,
							   AVSampleFormat sample_fmt);
int av_get_bytes_per_sample(AVSampleFormat sample_fmt);
int av_sample_fmt_is_planar(AVSampleFormat sample_fmt);
int av_samples_get_buffer_size(int *linesize, int nb_channels, int nb_samples,
                               AVSampleFormat sample_fmt, int align_);
int av_samples_fill_arrays(ubyte **audio_data, int *linesize, const ubyte *buf,
                           int nb_channels, int nb_samples,
                           AVSampleFormat sample_fmt, int align_);
int av_samples_alloc(ubyte **audio_data, int *linesize, int nb_channels,
                     int nb_samples, AVSampleFormat sample_fmt, int align_);
int av_samples_copy(ubyte **dst, ubyte **src, int dst_offset,
                    int src_offset, int nb_samples, int nb_channels,
                    AVSampleFormat sample_fmt);
int av_samples_set_silence(ubyte **audio_data, int offset, int nb_samples,
                           int nb_channels, AVSampleFormat sample_fmt);
