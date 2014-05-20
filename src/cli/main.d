module main;

import std.stdio;
import std.exception;

import file.audiofile;
import file.audiostream;
import file.decompstream;
import analysis.analyzer;

void
main(string args[])
{
	enforce(args.length > 1, "Not enough arguments");

	auto af = new AudioFile(args[1]);

	auto audioData = new DecompStream(af);

	auto a = new Analyzer();

	ulong n = 0;
	foreach(frame; audioData) {
		a.processSample(frame);
		n++;
	}
	writefln("loop done %s times", n);

	writefln("best key estimate: %s", a.bestKey());
}
