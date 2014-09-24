module libavresample.avresample;

public {
	import libavutil.avutil;
	import libavutil.channel_layout;
	import libavutil.dict;
	import libavutil.log;

	import libavresample.version_;
}

extern(C):
nothrow:

enum AVRESAMPLE_MAX_CHANNELS = 32;

struct AVAudioResampleContext;

enum AVMixCoeffType {
    AV_MIX_COEFF_TYPE_Q8,
    AV_MIX_COEFF_TYPE_Q15,
    AV_MIX_COEFF_TYPE_FLT,
    AV_MIX_COEFF_TYPE_NB,
};

enum AVResampleFilterType {
    AV_RESAMPLE_FILTER_TYPE_CUBIC,
    AV_RESAMPLE_FILTER_TYPE_BLACKMAN_NUTTALL,
    AV_RESAMPLE_FILTER_TYPE_KAISER,
};

enum AVResampleDitherMethod {
    AV_RESAMPLE_DITHER_NONE,
    AV_RESAMPLE_DITHER_RECTANGULAR,
    AV_RESAMPLE_DITHER_TRIANGULAR,
    AV_RESAMPLE_DITHER_TRIANGULAR_HP,
    AV_RESAMPLE_DITHER_TRIANGULAR_NS,
    AV_RESAMPLE_DITHER_NB,
};

uint avresample_version();

const(char) *avresample_configuration();

const(char) *avresample_license();

const(AVClass) *avresample_get_class();

AVAudioResampleContext *avresample_alloc_context();

int avresample_open(AVAudioResampleContext *avr);

void avresample_close(AVAudioResampleContext *avr);

void avresample_free(AVAudioResampleContext **avr);

int avresample_build_matrix(ulong in_layout, ulong out_layout,
                            double center_mix_level, double surround_mix_level,
                            double lfe_mix_level, int normalize, double *matrix,
                            int stride, AVMatrixEncoding matrix_encoding);

int avresample_get_matrix(AVAudioResampleContext *avr, double *matrix,
                          int stride);

int avresample_set_matrix(AVAudioResampleContext *avr, const double *matrix,
                          int stride);

int avresample_set_channel_mapping(AVAudioResampleContext *avr,
                                   const int *channel_map);

int avresample_set_compensation(AVAudioResampleContext *avr, int sample_delta,
                                int compensation_distance);

int avresample_convert(AVAudioResampleContext *avr, ubyte **output,
                       int out_plane_size, int out_samples, ubyte **input,
                       int in_plane_size, int in_samples);

int avresample_get_delay(AVAudioResampleContext *avr);

int avresample_available(AVAudioResampleContext *avr);

int avresample_read(AVAudioResampleContext *avr, ubyte **output, int nb_samples);
