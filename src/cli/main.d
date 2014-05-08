module main;

import std.stdio;
import std.string;
import std.conv;
import std.algorithm;
import std.complex;

import beatr.anal.fft.fftw3;
import beatr.decomp.libav;

class LibAvException : Exception {
	int ret;

    this(string msg, int r = 0, string file = __FILE__, size_t line = __LINE__,
		 Throwable next = null) @safe pure nothrow
    {
        super(msg, file, line, next);
        this.ret = r;
    }
}

void
main()
{
	AVFormatContext *s = null;

	try {
		av_register_all();

		/* open file */
		int ret = avformat_open_input(&s, "electric_relaxation.mp3".toStringz, null, null);
		if (ret < 0) throw new LibAvException("avformat_open_input error", ret);
		scope(exit) avformat_close_input(&s);

		/* analyse the file */
		ret = avformat_find_stream_info(s, null);
		if (ret < 0) throw new LibAvException("avformat_find_stream_info error", ret);

		/* find the audio stream */
		uint audio = uint.max;
		for (auto i = 0; i < s.nb_streams; i++) {
			if (s.streams[i].codec.codec_type == AVMediaType.AVMEDIA_TYPE_AUDIO)
				audio = i;
		}

		AVCodecContext *cctx = s.streams[audio].codec;


		/* open the decoder */
		AVCodec *avc = avcodec_find_decoder(cctx.codec_id);
		if (avc is null) throw new LibAvException("Could not find audio codec");

		if ((ret = avcodec_open2(cctx, avc, null)) < 0)
			throw new LibAvException("avcodec_open2 error", ret);
		scope(exit) avcodec_close(cctx);

		writefln("sample rate: %s, duration: %s, total samples: %s", cctx.sample_rate, s.duration / AV_TIME_BASE,
		cctx.sample_rate * s.duration / AV_TIME_BASE);

/+
		/* open resample */
		AVAudioResampleContext *avr = avresample_alloc_context();
		av_opt_set_int(avr, "in_channels", cctx.channels, 0);
		av_opt_set_int(avr, "out_channels", 1, 0);
		av_opt_set_int(avr, "in_sample_rate", cctx.sample_rate, 0);
		av_opt_set_int(avr, "out_sample_rate", 44100, 0);
		av_opt_set_int(avr, "in_sample_fmt", cctx.sample_fmt, 0);
		av_opt_set_int(avr, "out_sample_fmt", AV_SAMPLE_FMT_S16, 0);
		av_resample_open(avr);
+/

		/* read the packets */
		AVPacket pkt;
		AVFrame* frame = null;

		ulong total = 0;
		int got_frame;

		auto bytes_per_sample = av_samples_get_buffer_size(null, cctx.channels,
														   1, cctx.sample_fmt, 1);
		byte[] decoded = new byte[cctx.sample_rate * (s.duration / AV_TIME_BASE + 10)
								  * bytes_per_sample];

	decodeloop:
		for (;;) {
			do {
				av_init_packet(&pkt);
				ret = av_read_frame(s, &pkt);
				if (ret < 0) {
					if (ret == AVERROR_EOF)
						break decodeloop;
					throw new LibAvException("Error reading frame", ret);
				}
//				writefln("packet: size: %s", pkt.size);
			} while (pkt.stream_index != audio);

			if (frame is null) {
				if ((frame = av_frame_alloc()) is null)
					throw new LibAvException("Error allocating frame");
			} else
				av_frame_unref(frame);

			if ((ret = avcodec_decode_audio4(cctx, frame, &got_frame, &pkt)) < 0)
				throw new LibAvException("Error while decoding", ret);

			if (got_frame) {
				int data_size = av_samples_get_buffer_size(null, cctx.channels,
														   frame.nb_samples,
														   cctx.sample_fmt, 1);

				decoded[total .. (total + data_size)] = frame.data[0][0 .. data_size];
				total += data_size;
			}
		}

		decoded.length = total;
		writefln("length: %s", decoded.length);

		enum transformSize = 32768; /* 2^15; */

		double[] input = new double[transformSize];
		cdouble[] output = new cdouble[transformSize];

		auto plan = fftw_plan_dft_r2c_1d(transformSize, input.ptr, output.ptr,
										 0);

		immutable int step = 4;
		uint idx = 0;
		foreach (ref i; input) {
			i = decoded[idx];
			idx += step;
		}

		fftw_execute(plan);

		double[] freqs = new double[12*10];
		immutable double nextNote = std.math.pow(2., 1./12.);
		freqs[0] = 16.352; /* C0 */
		for(uint i = 1; i < freqs.length; i++)
			freqs[i] = freqs[i-1] * nextNote;

		immutable string[] notes = ["A", "Bb", "B", "C", "C#", "D", "Eb", "E",
									"F", "F#", "G", "G#"];
		int note = 3; /* C0 */
		foreach(i, f; freqs) {
			int k = cast(int) (f * transformSize / cctx.sample_rate);
			writefln("%s%s\t%.3e\t%s\t%.3f\t%.3f", notes[note++ % 12], note / 12,
					 f, k, output[k].re, output[k].im);
		}

		auto norm = output.map!(a => std.math.sqrt(a.re*a.re + a.im*a.im));

		foreach(i, f; freqs) {
			int k = cast(int) (f * transformSize / cctx.sample_rate);
			writefln("%s\t%s", norm[k], std.math.sqrt(output[k].re*output[k].re +
													  output[k].im*output[k].im));
		}

		if (frame !is null)
			av_frame_free(&frame);

		writefln("bitrate: %s", s.bit_rate);
	} catch (LibAvException e) {
		char[] buf = new char[512];
		if (e.ret != 0) {
			av_strerror(e.ret, buf.ptr, 512);
			stderr.writefln("%s: %s", e.msg, to!string(buf.ptr));
		} else
			stderr.writefln("%s", e.msg);

	}
}
