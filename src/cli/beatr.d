module main;

import std.stdio;
import std.exception;
import std.getopt;
import std.algorithm;
import std.file;
import exc.libavexception;

import analysis.analyzer;
import analysis.scores;
import util.beatr;
import chroma.chromaprofile;

int
main(string args[])
{
	int verbose;
	bool recursive;
	MatchingType m;
	bool graph;

	void matchingCallback(string opt, string val)
	{
		foreach (s; val.splitter(',')) {
			switch (s) {
			case "add_dom":      m |= MatchingType.ADD_DOMINANT; break;
			case "add_subdom":   m |= MatchingType.ADD_SUBDOM; break;
			case "add_relative": m |= MatchingType.ADD_RELATIVE; break;
			case "dominant":     m = MatchingType.DOMINANT; break;
			case "cadence":      m = MatchingType.CADENCE; break;
			case "all":          m = MatchingType.ALL; break;
			case "classic":      m = MatchingType.CLASSIC; break;
			default: break;
			}
		}
	}

	void printHelp()
	{
		writefln("usage: %s [options] input", args[0]);
		writeln("\tOptions:");
		writeln("\t\t-d|--debug\tAdd even more messages");
		writeln("\t\t-g|--graph\tPrint an histogram of the notes from the "
				 "input");
		writeln("\t\t-h|--help\tPrint this help message");
		writeln("\t\t-m|--mtype\tUse the specified matching algorithm");
		writeln("\t\t\tIt can be 'classic', 'dominant', 'cadence', 'all'");
		writeln("\t\t\tor any combination (separated with a command) of");
		writeln("\t\t\t\t'add_dom', 'add_subdom' and 'add_rel'");
		writeln("\t\t-q|--quiet\tOnly print the result");
		writeln("\t\t-r|--recursive\tRecursively analyze every file in "
				 "'input'");
		writeln("\t\t-v|--verbose\tAdd more messages");
	}

	try {
		getopt(
			args,
			"verbose|v", &verboseCallback,
			"debug|d", &verboseCallback,
			"quiet|q", &verboseCallback,
			"recursive|r", &recursive,
			"mtype|m", &matchingCallback,
			"graph|g", &graph,
			"help|h", &printHelp);
	} catch (Exception e) {
		stderr.writefln("error: %s", e.msg);
		return 3;
	}

	if (args.length <= 1) {
		printHelp();
		return 2;
	} else
		return process(args[1], m, recursive, graph);
}

bool
process(string f, MatchingType m, bool recursive, bool graph)
{
	bool hadError = false;
	DirEntry d;

	try {
		d = DirEntry(f);
	} catch (FileException e) {
		stderr.writefln("error: %s", e.msg);
		return true;
	}

	if (d.isFile) {
		Beatr.writefln(BEATR_VERBOSE, "Processing '%s'...", f);
		try {
			auto a = new Analyzer(f);
			a.process();

			auto k = a.bestKey(ProfileType.PROFILE_KRUMHANSL, m);
			auto scores = a.getScores();
			if (graph)
				scores.printHistograms(15);
			writefln("%s\t%s\t%.2s", f, k, scores.confidence);
		} catch (LibAvException e) {
			hadError = true;
			stderr.writefln("%s\n", e.msg);
		}
	} else if (d.isDir)
		foreach (name; dirEntries(f, recursive ? SpanMode.breadth :
								  SpanMode.shallow))
			hadError |= process(name, m, recursive, graph);
	else
		stderr.writefln("'%s' is neither a file nor a directory", f);

	return hadError;
}

void
verboseCallback(string opt)
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
