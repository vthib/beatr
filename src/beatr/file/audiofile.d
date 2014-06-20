import std.string;

import libavcodec.avcodec;
import libavformat.avformat;

import exc.libavexception;
import util.beatr;

/++
 + Represents an audio file, and wraps the AVFormatContext object
 + in a convenient class
 +/
class AudioFile
{
private:
	AVFormatContext *ctx;
	uint audioStream; /* the stream number of the audio date */
	/* XXX: several streams? */

public:
	/++ Throws: LibAvException on libav function errors +/
	this(string file)
	{
		int ret;

		av_register_all();
		
		/* open file */
		ret = avformat_open_input(&ctx, file.toStringz, null, null);
		if (ret < 0)
			throw new LibAvException("avformat_open_input error", ret);

		/* analyse the file */
		ret = avformat_find_stream_info(ctx, null);
		if (ret < 0)
					throw new LibAvException("avformat_find_stream_info error", ret);

		/* find the audio stream */
		audioStream = uint.max;

		/* XXX: first one or last one? */
		foreach (i; 0 .. ctx.nb_streams) {
			if (ctx.streams[i].codec.codec_type
				== AVMediaType.AVMEDIA_TYPE_AUDIO) {
				if (audioStream != uint.max)
					Beatr.writefln(Lvl.WARNING, "Several audio stream found!");
				audioStream = i;
			}
		}

		if (audioStream == uint.max)
			throw new LibAvException("No audio stream found");
	}

	/* find the audio stream */
	@property AVCodecContext* audioCodec() nothrow pure
	{
		return ctx.streams[audioStream].codec;
	}

	/* return the libAV format context */
	@property const(AVFormatContext*) formatContext() const nothrow pure
	{
		return ctx;
	}

	/* return the duration in seconds */
	@property uint duration() const nothrow pure
	{
		return cast(uint) (ctx.duration / AV_TIME_BASE);
	}

	/++ Retrieves the next frame in the audio data
	 + Returns: false if end of file, true if success
	 + Throws: LibAvException on libav function error
	 +/
	bool getFrame(AVPacket *pkt) 
	in
	{
		assert(pkt !is null);
	}
	body
	{
		int ret;

		/* loops until we get a non empty packet from the audio stream */
		do {
			av_init_packet(pkt);
			ret = av_read_frame(this.ctx, pkt);
			if (ret < 0) {
				if (ret == AVERROR_EOF)
					return false;
				throw new LibAvException("Error reading frame", ret);
			}
		} while (pkt.stream_index != this.audioStream);

		return true;
	}

private:
	~this()
	{
		if (ctx !is null)
			avformat_close_input(&ctx);
	}

	/++ An AudioFile object can be used to access directly the members
	 + of the AVFormatContext structure +/
	alias formatContext this;
}
