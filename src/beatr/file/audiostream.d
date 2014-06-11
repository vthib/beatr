//@safe:

import std.array;
import std.stdio;

import file.audiofile;
import exc.libavexception;
import util.types;
import util.beatr;

import libavcodec.avcodec;
import libavresample.avresample;
import libavutil.opt;
import libavutil.samplefmt;

/++
 + Provides a Range object for the decompressed
 + data of an audio file
 +/
class AudioStream
{
private:
	short[] d; /++ buffer containing the decompressed data +/
	ulong offset; /++ current position in the buffer +/
	AudioFile af; /++ the audio file we are decompressing +/
	AVFrame* frame; /++ a frame, kept if already decompressed but buffer full +/
	bool endOfFile; /++ No more data is available from the audio file +/
	AVCodecContext* ctx;
	AVAudioResampleContext *resamplectx;

	invariant() {
		assert(offset >= 0 && offset <= d.length);
		assert(af !is null);
	}

public:
	/++ Throws: LibAvException on libav function errors +/
	this(AudioFile af)
	{
		this.af = af;

		openDecoder();	

		auto bytesPerSamples =
			av_samples_get_buffer_size(null, ctx.channels,
									   1, ctx.sample_fmt, 1);

		version(stream_decomp) {
			/* XXX: experiment with this value */
			/* allocates for the buffer 10 seconds of samples */
			d = new short[beatrSampleRate*10];

			offset = d.length; /* indicates the buffer unusable */
		} version (full_decomp) {
			d = new short[beatrSampleRate *
						  (af.duration / AV_TIME_BASE + 10)];

			offset = d.length; /* indicates the buffer unusable */

			addFrames();
			offset = 0;
			assert(endOfFile, "file not decompressed entirely");
		}
	}

	/++++ Range Functions +++++/

	@property bool empty() const
	{
		return endOfFile && (offset + beatrSampleRate > d.length);
	}

	@property beatrSample front()
	{
		/* if not enough data left in the buffer, fill it again */
		if (offset + beatrSampleRate > d.length)
			addFrames();

		/* XXX: fill with blank if not a multiple of beatrSampleRate? */
		if (offset + beatrSampleRate > d.length) {
			assert(false, "should never happend?");
			return null;
		}

		return d[offset .. (offset + beatrSampleRate)];
	}

	void popFront()
	{
		if (offset + beatrSampleRate > d.length)
			addFrames();

		offset += beatrSampleRate;
	}

private:
	~this()
	{
		avcodec_close(ctx);

		if (avresample_available(resamplectx))
			Beatr.writefln(Lvl.WARNING, "Still some "
						   "resampled samples available");
		avresample_close(resamplectx);
		avresample_free(&resamplectx);

        if (frame !is null)
            av_frame_free(&frame);
	}

	/++ Open the codec context
	 + Throws: LibAvException on a libav function error
	 +/
	void openDecoder()
	{
		ctx = af.audioCodec;
		int ret;

        /* open the decoder */
        auto avc = avcodec_find_decoder(ctx.codec_id);
        if (avc is null) throw new LibAvException("Could not find audio codec");

        if ((ret = avcodec_open2(ctx, avc, null)) < 0)
            throw new LibAvException("avcodec_open2 error", ret);

        Beatr.writefln(Lvl.DEBUG, "sample rate: %s, duration: %s, "
					   "channels: %s", ctx.sample_rate,
					   af.duration / AV_TIME_BASE, ctx.channels);

		/* open resampler */
		resamplectx = avresample_alloc_context();
		av_opt_set_int(resamplectx, "in_channels", ctx.channels, 0);
		av_opt_set_int(resamplectx, "in_channel_layout",
					   av_get_default_channel_layout(ctx.channels), 0);
		av_opt_set_int(resamplectx, "out_channel_layout",
					   av_get_default_channel_layout(1), 0);
		av_opt_set_int(resamplectx, "out_channels", 1, 0);
		av_opt_set_int(resamplectx, "in_sample_rate", ctx.sample_rate, 0);
		av_opt_set_int(resamplectx, "out_sample_rate", beatrSampleRate, 0);
		av_opt_set_int(resamplectx, "in_sample_fmt", ctx.sample_fmt, 0);
		av_opt_set_int(resamplectx, "out_sample_fmt",
					   AVSampleFormat.AV_SAMPLE_FMT_S16P, 0);
		if ((ret = avresample_open(resamplectx)) < 0)
			throw new LibAvException("Cannot open resampler", ret);
	}

	/++ Copies a frame in the data buffer
	 + Returns: false if buffer full, true otherwise
	 +/
	bool copyFrame() nothrow
	in
	{
		assert(frame !is null);
	}
	body
	{
		int linesize;

		if (offset + frame.nb_samples > d.length)
			return false; /* buffer full */

		/* computes the size of the whole frame */
		/* XXX quick instruction or double libav call? */
		immutable auto size = frame.nb_samples + avresample_available(resamplectx)
			+ avresample_get_delay(resamplectx);
		// immutable auto size = frame.nb_samples;

		ubyte *output;
		int out_linesize, in_linesize;

		/* allocate a output buffer big enough */
		av_samples_alloc(&output, &out_linesize, 1, size,
						 AVSampleFormat.AV_SAMPLE_FMT_S16P, 0);
		/* get the linesize */
		av_samples_get_buffer_size(&in_linesize, ctx.channels,
								   frame.nb_samples, ctx.sample_fmt, 0);

		/* resample input in the output buffer */
		auto out_samples = avresample_convert(resamplectx, &output,
											  out_linesize, size,
											  &(frame.data[0]), in_linesize,
											  frame.nb_samples);
		memcpy(d.ptr + offset, output, out_samples * 2);
		offset += out_samples;
		av_freep(&output);

		return true;
	}

	/++ Add decompressed data to the buffer until it is full
	 + Throws: LibAvException on a libav function error
	 +/
	void addFrames() {
		AVPacket pkt;
		int got_frame;
		int ret;

		Beatr.writefln(Lvl.DEBUG, "adding decompressed frames...");

		if (endOfFile)
			return;

		/* copy the data left to the beginning of the buffer */
		offset = d.length - offset;
		d[0 .. offset] = d[(d.length - offset) .. d.length];

		/* XXX: always 0? if this is the case, can clean these instructions */
		assert(offset == 0, "offset equal length when adding frames");

		scope(exit) {
			endOfFile = true;
			d.length = offset;
			/* put the offset back at the beginning */
			offset = 0;
		}

		/* while we have frames and we copy them successfully in the buffer */
		while (!got_frame || copyFrame()) {
			if (!af.getFrame(&pkt))
				return;

            /* allocates the frame */
			if (frame is null) {
                if ((frame = av_frame_alloc()) is null)
                    throw new LibAvException("Error allocating frame");
            } else
                av_frame_unref(frame);

			if ((ret = avcodec_decode_audio4(ctx, frame, &got_frame,
											 &pkt)) < 0) {
				Beatr.writefln(Lvl.WARNING, "Error while decoding: %s",
							   LibAvException.errorToString(ret));
				return;
			}
			if (got_frame)
				av_free_packet(&pkt);
        }
	}
}
