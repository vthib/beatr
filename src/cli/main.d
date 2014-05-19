module main;

import std.stdio;
import std.exception;

import file.audioFile;
import file.audioStream;
import file.decompStream;
import analysis.analyzer;

void
main(string args[])
{
	audioFile af;
	decompStream audioData;

	enforce(args.length > 1, "Not enough arguments");

	af = new audioFile(args[1]);

	audioData = new decompStream(af);

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

	auto a = new analyzer();

	ulong n = 0;
	foreach(frame; audioData) {
		a.processSample(frame);
		n++;
	}
	writefln("loop done %s times", n);

	writefln("best key estimate: %s", a.bestKey());
}
