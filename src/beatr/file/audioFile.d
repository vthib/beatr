
import std.string;

import libavcodec.avcodec;
import libavformat.avformat;

import exc.libAvException;

class audioFile
{
	AVFormatContext *ctx;
	uint audioStream;

	this(string file)
	{
		int ret;

		av_register_all();
		
		/* open file */
		ret = avformat_open_input(&ctx, file.toStringz, null, null);
		if (ret < 0) throw new LibAvException("avformat_open_input error", ret);

		/* analyse the file */
		ret = avformat_find_stream_info(ctx, null);
		if (ret < 0) throw new LibAvException("avformat_find_stream_info error", ret);

		/* find the audio stream */
		audioStream = uint.max;

		/* XXX: first one or last one? */
		for (auto i = 0; i < ctx.nb_streams; i++) {
			if (ctx.streams[i].codec.codec_type == AVMediaType.AVMEDIA_TYPE_AUDIO)
				audioStream = i;
		}
	}

	~this()
	{
		avformat_close_input(&ctx);
	}

	/* find the audio stream */
	@property AVCodecContext* audioCodec() pure
	{
		return ctx.streams[audioStream].codec;
	}

	bool getFrame(AVPacket *pkt)
	{
		int ret;

		do {
			av_init_packet(pkt);
			ret = av_read_frame(ctx, pkt);
			if (ret < 0) {
				if (ret == AVERROR_EOF)
					return false;
				throw new LibAvException("Error reading frame", ret);
			}
//              writefln("packet: size: %s", pkt.size);
		} while (pkt.stream_index != audioStream);

		return true;
	}
}
