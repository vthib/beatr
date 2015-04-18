module audio.audiostream;

//@safe:
import core.stdc.string : memcpy;
import std.algorithm : min;

import libavcodec.avcodec;

import audio.audiofile;
import audio.resampler;
import exc.libavexception;
import util.beatr;


/++
 + Provides a Range object for the decompressed
 + data of an audio file
 +/
class AudioStream
{
private:
	short[] d; /++ buffer containing the decompressed data +/
	size_t offset; /++ current position in the buffer +/
	size_t dend; /++ current end of valid data in the buffer +/
	bool endOfFile; /++ No more data is available from the audio file +/

	AudioFile af; /++ the audio file we are decompressing +/
	AVFrame* frame; /++ a frame, kept if already decompressed but buffer full +/
	AVCodecContext* ctx;
	Resampler resampler;
	immutable uint  samplerate;
    ulong           full_length;
    ulong           real_pos;

	invariant() {
		assert(0 <= dend && dend <= d.length);
		assert(offset >= 0 && offset <= dend);
		assert(af !is null);
	}

public:
	/++ Throws: LibAvException on libav function errors +/
	this(AudioFile af)
	{
		int ret;

		this.af = af;

		ctx = af.audioCodec;

        /* open the decoder */
        auto avc = avcodec_find_decoder(ctx.codec_id);
        if (avc is null) throw new LibAvException("Could not find audio codec");

        if ((ret = avcodec_open2(ctx, avc, null)) < 0)
            throw new LibAvException("avcodec_open2 error", ret);

        Beatr.writefln(Lvl.debug_, "sample rate: %s, channels: %s",
					   ctx.sample_rate, ctx.channels);

		/* open the resampler */
		samplerate = Beatr.sampleRate;
		resampler = new Resampler(ctx, samplerate);
        full_length = samplerate * af.duration;
        real_pos = 0;

		/* allocates for the buffer nbFramesBuf seconds of samples */
		d = new short[samplerate * Beatr.framesBufSize];

		dend = d.length;
		offset = dend; /* indicates the buffer unusable */

		addFrames();
	}

    void setMaxSeconds(size_t seconds) nothrow
    {
        full_length = min(full_length, seconds * samplerate);
    }

    @property int progress() const
    {
        if (full_length == 0)
            return 100;
        else
            return cast(int)(real_pos * 100 / full_length);
    }

	/++++ Range Functions +++++/

	@property bool empty() const
	{
		return endOfFile && (offset == dend);
	}

	@property short[] front()
	{
		/* if not enough data left in the buffer, fill it again */
		if (offset + samplerate > dend) {
			/* we still have less than a frame left. We return it
			   followed by zeroes */
			typeof(d) end = new typeof(d[0])[samplerate];
			end[0 .. (dend - offset)] = d[offset .. dend];
			end[(dend - offset) .. $] = 0;

			/* After popping, offset will be equal to dend,
			   keeping the invariant true */
			dend = offset + samplerate;

			return end;
		}

		return d[offset .. (offset + samplerate)];
	}

	void popFront()
	{
		offset += samplerate;
        real_pos += samplerate;

		/* refill the data if necessary so that empty() will work */
		if (offset + samplerate > dend && !endOfFile)
			addFrames();
	}

private:
	~this()
	{
        if (frame !is null)
            av_frame_free(&frame);
        destroy(d);
        destroy(resampler);
	}

	/++ Copies a frame in the data buffer
	 + Returns: false if buffer full, true otherwise
	 +/
	bool copyFrame() nothrow
	in
	{
		assert(frame !is null);
	}
	body /* XXX handle error returns from libav functions */
	{
		int linesize;

		if (offset + frame.nb_samples > dend)
			return false; /* buffer full */

		size_t out_bytes;
		auto output = resampler.resample(frame, out_bytes);

		memcpy(d.ptr + offset, output, out_bytes);

		offset += out_bytes / 2; /* byte to short */
		resampler.freeSample(output);

		return true;
	}

	/++ Add decompressed data to the buffer until it is full
	 + Throws: LibAvException on a libav function error
	 +/
	void addFrames() {
		AVPacket pkt;
		int got_frame;
		int ret;

		if (endOfFile)
			return;

		/* copy the data left to the beginning of the buffer */
		offset = dend - offset;
		d[0 .. offset] = d[(dend - offset) .. dend];
		dend = d.length;

		got_frame = (frame !is null);
		/* while we have frames and we copy them successfully in the buffer */
		while (!got_frame || copyFrame()) {
			if (!af.getFrame(&pkt)) {
				endOfFile = true;
				break;
			}

            /* allocates the frame */
			if (frame is null) {
                if ((frame = av_frame_alloc()) is null)
                    throw new LibAvException("Error allocating frame");
            } else
                av_frame_unref(frame);

			if ((ret = avcodec_decode_audio4(ctx, frame, &got_frame,
											 &pkt)) < 0) {
				Beatr.writefln(Lvl.warning, "Error while decoding: %s",
							   LibAvException.errorToString(ret));
			}
			av_free_packet(&pkt);
        }

		/* put the offset back at the beginning */
		dend = offset;
		offset = 0;
	}
}
