module main;

import std.stdio;
import std.exception;
import std.getopt;

import analysis.analyzer;
import util.beatr;

void
verbose_callback(string opt)
{
	switch (opt) {
	case "verbose|v":
		Beatr.setVerboseLevel(BEATR_VERBOSE);
		break;
	case "debug|d":
		Beatr.setVerboseLevel(BEATR_DEBUG);
		break;
	case "quiet|q":
		Beatr.setVerboseLevel(BEATR_NORMAL);
		break;
	default:
		break;
	}
}

void
main(string args[])
{
	int verbose;
	getopt(
		args,
		"verbose|v", &verbose_callback,
		"debug|d", &verbose_callback,
		"quiet|q", &verbose_callback);

	enforce(args.length > 1, "Not enough arguments: file to analyze missing.");

	auto a = new Analyzer(args[1]);

	a.process();

	writefln("best key estimate: %s", a.bestKey());
}
