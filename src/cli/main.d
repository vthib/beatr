module main;

import std.stdio;
import std.string;
import std.conv;
import std.algorithm;
import std.complex;
import std.exception;

import fftw.fftw3;
import libavformat.avformat;

class LibAvException : Exception {
	int ret;

    this(string msg, int r = 0, string file = __FILE__, size_t line = __LINE__,
		 Throwable next = null) @safe pure nothrow
    {
        super(msg, file, line, next);
        this.ret = r;
    }
}

void processSamples(inout const ubyte[] input, double[] output, bool add)
{
	auto ibuf = new double[input.length];
	auto obuf = new cdouble[input.length];
	enum step = 1;
	uint idx = 0;

	enforce(input.length <= output.length,
			"Output length greater than input length");
	enforce(output.length < int.max, "Output length too great");

	auto plan = fftw_plan_dft_r2c_1d(cast(int) output.length, ibuf.ptr, obuf.ptr,
									 0);
	foreach (ref i; ibuf) {
		i = input[idx];
		idx += step;
	}

	fftw_execute(plan);

	auto norm = obuf.map!((a => std.math.sqrt(a.re*a.re + a.im*a.im)/output.length));

	foreach (i, ref o; output)
		o = add ? (o + norm[i]) : norm[i];
}

ubyte[12][12]
createProfiles()
{
	ubyte[12][12] profiles;

	foreach(i, ref t; profiles) {
		t[(i + 0) % 12]  = 3;
		t[(i + 1) % 12]  = 0;
		t[(i + 2) % 12]  = 1;
		t[(i + 3) % 12]  = 0;
		t[(i + 4) % 12]  = 2;
		t[(i + 5) % 12]  = 1;
		t[(i + 6) % 12]  = 0;
		t[(i + 7) % 12]  = 2;
		t[(i + 8) % 12]  = 0;
		t[(i + 9) % 12]  = 2;
		t[(i + 10) % 12] = 0;
		t[(i + 11) % 12] = 1;
	}

	return profiles;
}

void
main(string args[])
{
	AVFormatContext *avfc = null;

	try {
		av_register_all();

		enforce(args.length > 1, "Not enough arguments");

		/* open file */
		int ret = avformat_open_input(&avfc, args[1].toStringz, null, null);
		if (ret < 0) throw new LibAvException("avformat_open_input error", ret);
		scope(exit) avformat_close_input(&avfc);

		/* analyse the file */
		ret = avformat_find_stream_info(avfc, null);
		if (ret < 0) throw new LibAvException("avformat_find_stream_info error", ret);

		/* find the audio stream */
		uint audio = uint.max;
		for (auto i = 0; i < avfc.nb_streams; i++) {
			if (avfc.streams[i].codec.codec_type == AVMediaType.AVMEDIA_TYPE_AUDIO)
				audio = i;
		}

		AVCodecContext *cctx = avfc.streams[audio].codec;


		/* open the decoder */
		AVCodec *avc = avcodec_find_decoder(cctx.codec_id);
		if (avc is null) throw new LibAvException("Could not find audio codec");

		if ((ret = avcodec_open2(cctx, avc, null)) < 0)
			throw new LibAvException("avcodec_open2 error", ret);
		scope(exit) avcodec_close(cctx);

		writefln("sample rate: %s, duration: %s, total samples: %s", cctx.sample_rate, avfc.duration / AV_TIME_BASE,
		cctx.sample_rate * avfc.duration / AV_TIME_BASE);

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
														   1, cctx.sample_fmt,
														   1);
		ubyte[] decoded = new ubyte[cctx.sample_rate *
									(avfc.duration / AV_TIME_BASE + 10)
									* bytes_per_sample];

	decodeloop:
		for (;;) {
			do {
				av_init_packet(&pkt);
				ret = av_read_frame(avfc, &pkt);
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

//		enum transformSize = 32768; /* 2^15; */
		immutable auto transformSize = cctx.sample_rate;

		double[] norm = new double[transformSize];
		ulong offset = 0;
		bool append = false;
		int n = 0;

		while (decoded.length - offset >= cctx.sample_rate) {
			processSamples(decoded[offset .. (offset + cctx.sample_rate)], norm, append);
			append = true;
			offset += cctx.sample_rate;
			n++;
		}
		writefln("loop done %s times", n);

		double[] freqs = new double[12*10];
		immutable double nextNote = std.math.pow(2., 1./12.);
		freqs[0] = 16.352; /* C0 */
		for(uint i = 1; i < freqs.length; i++)
			freqs[i] = freqs[i-1] * nextNote;

		immutable string[] notes = ["C", "C#", "D", "Eb", "E", "F",
									"F#", "G", "G#", "A", "Bb", "B"];
		int note = 0; /* C0 */
		double[] chromas = new double[freqs.length];
		auto chromaidx = freqs.map!(f => cast(int) f * transformSize / cctx.sample_rate);
		long j1, j2;

		foreach(i, f; freqs) {
			j1 = (i != 0) ? (chromaidx[i-1] - chromaidx[i])/2 : 0;
			j2 = (i < freqs.length - 1) ? (chromaidx[i+1] - chromaidx[i])/2 : 0;
			chromas[i] = 0.;
			for (long k = j1; k <= j2; k++)
				chromas[i] += norm[chromaidx[i] + k]; 
			chromas[i] /= (j2 - j1 + 1);

//			chromas[i] = norm[chromaidx[i]];
			writefln("%s%s\t%.3e\t%s\t%s", notes[note % 12], note / 12,
					 f, chromaidx[i], chromas[i]);
			note++;
		}
/*		for(uint i = 0; i < norm.length; i++)
		writefln("%s: %s", i, norm[i]);*/

		auto m = chromas.reduce!(max);
		auto m2 = chromas.reduce!((a, b) => (b > a && b != m) ? b : a);

		writefln("max: %s; %%%s greater", m, cast(int) (m - m2)/m2*100);

		auto profiles = createProfiles();

		double[12] scores;

		foreach(i, ref s; scores) {
			s = 0.;
			foreach(j, c; chromas)
				s += c*profiles[i][j % 12];
			s /= chromas.length;
		}

		auto best = scores.reduce!(max);
		foreach(i, s; scores)
			if (s == best)
				writefln("best key estimate: %s", notes[i]);
		writefln("%(%s %)", scores);

		if (frame !is null)
			av_frame_free(&frame);

		writefln("bitrate: %s", avfc.bit_rate);
	} catch (LibAvException e) {
		char[] buf = new char[512];
		if (e.ret != 0) {
			av_strerror(e.ret, buf.ptr, 512);
			stderr.writefln("%s: %s", e.msg, to!string(buf.ptr));
		} else
			stderr.writefln("%s", e.msg);

	}
}
