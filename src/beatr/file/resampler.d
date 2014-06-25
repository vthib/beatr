import exc.libavexception;
import util.beatr;

import libavcodec.avcodec;
import libavresample.avresample;
import libavutil.opt;
import libavutil.samplefmt;

class Resampler
{
private:
	AVAudioResampleContext *resamplectx;
	immutable int channels;
	immutable AVSampleFormat samplefmt;

public:
	this(AVCodecContext *ctx, int samplerate)
	{
		int ret;

		/* open resampler */
		/* resample to 1 channel, samplerate, 16bit planar */
		resamplectx = avresample_alloc_context();
		channels = ctx.channels;
		av_opt_set_int(resamplectx, "in_channel_layout",
					   av_get_default_channel_layout(channels), 0);
		av_opt_set_int(resamplectx, "out_channel_layout",
					   av_get_default_channel_layout(1), 0);
		av_opt_set_int(resamplectx, "in_channels", channels, 0);
		av_opt_set_int(resamplectx, "out_channels", 1, 0);

		av_opt_set_int(resamplectx, "in_sample_rate", ctx.sample_rate, 0);
		av_opt_set_int(resamplectx, "out_sample_rate", samplerate, 0);

		samplefmt = ctx.sample_fmt;
		av_opt_set_int(resamplectx, "in_sample_fmt", samplefmt, 0);
		av_opt_set_int(resamplectx, "out_sample_fmt",
					   AVSampleFormat.AV_SAMPLE_FMT_S16P, 0);
		if ((ret = avresample_open(resamplectx)) < 0)
			throw new LibAvException("Cannot open resampler", ret);
	}

	ubyte* resample(AVFrame *frame, out size_t out_bytes) nothrow
	in
	{
		assert(frame !is null);
	}
	body /* XXX handle error returns from libav functions */
	{
		int linesize;

		immutable auto size = frame.nb_samples + samplesDelayed();
		// immutable auto size = frame.nb_samples;

		ubyte *output;
		int out_linesize, in_linesize;

		/* allocate a output buffer big enough */
		av_samples_alloc(&output, &out_linesize, 1, size,
						 AVSampleFormat.AV_SAMPLE_FMT_S16P, 0);
		/* get the linesize */
		av_samples_get_buffer_size(&in_linesize, channels,
								   frame.nb_samples, samplefmt, 0);

		/* resample input in the output buffer */
		auto out_samples = avresample_convert(resamplectx, &output,
											  out_linesize, size,
											  &(frame.data[0]), in_linesize,
											  frame.nb_samples);

		out_bytes = out_samples * 2;

		return output;
	}

	void freeSample(ubyte* s) nothrow
	{
		av_freep(&s);
	}

private:
	~this()
	{
		if (avresample_available(resamplectx))
			Beatr.writefln(Lvl.WARNING, "Still some "
						   "resampled samples available");
		avresample_close(resamplectx);
		avresample_free(&resamplectx);
	}

	int samplesDelayed() nothrow
	{
		return avresample_available(resamplectx)
			+ avresample_get_delay(resamplectx);
	}
}
