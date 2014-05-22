module main;

import std.stdio;
import std.exception;
import std.getopt;

import file.audiofile;
import file.stream.decompstream;
import analysis.analyzer;
import util.beatr;

void
main(string args[])
{
	bool verbose;
	getopt(
		args,
		"verbose|v",  &verbose);

	enforce(args.length > 1, "Not enough arguments: file to analyze missing.");

	Beatr.setVerboseLevel(verbose);

	auto a = new Analyzer(args[1]);

	a.process();

	writefln("best key estimate: %s", a.bestKey());
}
