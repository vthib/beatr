
import std.array;

import file.audioStream;
import file.audioFile;
import exc.libAvException;
import util.types;

import libavcodec.avcodec;

class decompStream : audioStream!beatrSample
{
private:
	ubyte[] d;
	ulong offset;
	audioFile af;
	AVFrame* frame;
	AVCodecContext* ctx;
	bool endOfFile;

	invariant() {
		assert(offset >= 0 && offset <= d.length);
		assert(af !is null);
	}

public:
	this(audioFile af)
	{
		this.af = af;
		frame = null;

		openDecoder();	

		auto bytesPerSamples =
			av_samples_get_buffer_size(null, ctx.channels,
									   1, ctx.sample_fmt, 1);

		d = new ubyte[bytesPerSamples*BeatrSampleSize*10];
		offset = d.length;
	}

	~this()
	{
		avcodec_close(ctx);
        if (frame !is null)
            av_frame_free(&frame);
	}

	@property bool empty() const
	{
		return endOfFile && (offset + BeatrSampleSize > d.length);
	}

	@property beatrSample front()
	{
		if (offset + BeatrSampleSize > d.length)
			addFrames();

		/* XXX: fill with blank if not a multiple of BeatrSampleSize? */
		if (offset + BeatrSampleSize > d.length) {
			assert(false, "should never happend?");
			return null;
		}

		return d[offset .. (offset + BeatrSampleSize)];
	}

	void popFront()
	{
		if (offset + BeatrSampleSize > d.length)
			addFrames();

		offset += BeatrSampleSize;
	}

	@property auto sampleRate() const
	{
		return ctx.sample_rate;
	}

private:
	void openDecoder()
	{
		ctx = af.audioCodec;
		int ret;

        /* open the decoder */
        auto avc = avcodec_find_decoder(ctx.codec_id);
        if (avc is null) throw new LibAvException("Could not find audio codec");

        if ((ret = avcodec_open2(ctx, avc, null)) < 0)
            throw new LibAvException("avcodec_open2 error", ret);

/+        writefln("sample rate: %s, duration: %s, total samples: %s", ctx.sample_rate, avfc.duration / AV_TIME_BASE,
				 ctx.sample_rate * avfc.duration / AV_TIME_BASE);+/
	}

	bool copyFrame()
	in
	{
		assert(frame !is null);
	}
	body
	{
		auto data_size =
			av_samples_get_buffer_size(null, ctx.channels,
									   frame.nb_samples,
									   ctx.sample_fmt, 1);
		if (offset + data_size > d.length)
			return false;

		debug {
			std.stdio.writefln("copyFrame: %s -> %s / %s", offset, offset + data_size, d.length);
		}

		d[offset .. (offset + data_size)] = frame.data[0][0 .. data_size];
		offset += data_size;

		return true;
	}

	void addFrames() {
		AVPacket pkt;
		int got_frame;
		int ret;

		if (endOfFile)
			return;

		offset = d.length - offset;
		assert(offset == 0, "offset equal length when adding frames");

		d[0 .. offset] = d[(d.length - offset) .. d.length];

		while (!got_frame || copyFrame()) {
			if (!af.getFrame(&pkt)) {
				endOfFile = true;
				d.length = offset;
				break;
			}

            if (frame is null) {
                if ((frame = av_frame_alloc()) is null)
                    throw new LibAvException("Error allocating frame");
            } else
                av_frame_unref(frame);

            if ((ret = avcodec_decode_audio4(ctx, frame, &got_frame,
											 &pkt)) < 0)
                throw new LibAvException("Error while decoding", ret);
			else if (got_frame)
				av_free_packet(&pkt);
        }


		offset = 0;
	}

}
