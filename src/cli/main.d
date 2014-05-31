module main;

import std.stdio;
import std.exception;
import std.getopt;
import std.file;
import exc.libavexception;

import analysis.analyzer;
import util.beatr;

int
main(string args[])
{
	int verbose;
	bool recursive;
	getopt(
		args,
		"verbose|v", &verbose_callback,
		"debug|d", &verbose_callback,
		"quiet|q", &verbose_callback,
		"recursive|r", &recursive);
	
	enforce(args.length > 1, "Not enough arguments: file to analyze missing.");

	return process(args[1], recursive);
}

bool
process(string f, bool recursive)
{
	auto d = DirEntry(f);
	bool hadError = false;

	if (d.isFile) {
		Beatr.writefln(BEATR_VERBOSE, "Processing '%s'...", f);
		try {
			auto a = new Analyzer(f);
			a.process();

			auto k = a.bestKey();
			writefln("%s\t%s\t%.2s", f, k, a.confidence);
		} catch (LibAvException e) {
			hadError = true;
			stderr.writefln("%s\n", e.msg);
		}
	} else if (d.isDir)
		foreach (name; dirEntries(f, recursive ? SpanMode.breadth :
								  SpanMode.shallow))
			hadError |= process(name, recursive);
	else
		stderr.writefln("'%s' is neither a file nor a directory", f);

	return hadError;
}

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

