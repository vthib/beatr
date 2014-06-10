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

struct Options {
	double sigma;
	MatchingType m;
	ProfileType p;
	bool recursive;
	bool graph;
}

int
main(string args[])
{
	Options opt;

	void matchingCallback(string option, string val)
	{
		foreach (s; val.splitter(',')) {
			switch (s) {
			case "add_dom":      opt.m |= MatchingType.ADD_DOMINANT; break;
			case "add_subdom":   opt.m |= MatchingType.ADD_SUBDOM; break;
			case "add_relative": opt.m |= MatchingType.ADD_RELATIVE; break;
			case "dominant":     opt.m = MatchingType.DOMINANT; break;
			case "cadence":      opt.m = MatchingType.CADENCE; break;
			case "all":          opt.m = MatchingType.ALL; break;
			case "classic":      opt.m = MatchingType.CLASSIC; break;
			default: break;
			}
		}
	}

	void profileCallback(string option, string val)
	{
		switch (val) {
		case "krumhansl":        opt.p = ProfileType.KRUMHANSL; break;
		case "scale":            opt.p = ProfileType.SCALE; break;
		case "scale_harm":       opt.p = ProfileType.SCALE_HARM; break;
		case "scale_both":       opt.p = ProfileType.SCALE_BOTH; break;
		case "chord":            opt.p = ProfileType.CHORD; break;
		case "chord_normalized": opt.p = ProfileType.CHORD_NORMALIZED; break;
		default: break;
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
		writeln("\t\t-p|--profile\tUse the specified profile");
		writeln("\t\t\tIt can be 'krumhansl', 'scale', 'scale_harm',");
		writeln("\t\t\t'scale_both', 'chord' or 'chord_normalized'");
		writeln("\t\t-q|--quiet\tOnly print the result");
		writeln("\t\t-r|--recursive\tRecursively analyze every file in "
				 "'input'");
		writeln("\t\t-s|--sigma\tSelect a sigma value for the gaussian");
		writeln("\t\t\tprofiles to process DFT samples");
		writeln("\t\t-v|--verbose\tAdd more messages");
	}

	try {
		getopt(
			args,
			"debug|d", &verboseCallback,
			"graph|g", &opt.graph,
			"help|h", &printHelp,
			"mtype|m", &matchingCallback,
			"profile|p", &profileCallback,
			"quiet|q", &verboseCallback,
			"recursive|r", &opt.recursive,
			"sigma|s", &opt.sigma,
			"verbose|v", &verboseCallback);
	} catch (Exception e) {
		stderr.writefln("error: %s", e.msg);
		return 3;
	}

	if (args.length <= 1) {
		printHelp();
		return 2;
	} else
		return process(args[1], opt);
}

bool
process(string f, Options opt)
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
			if (std.math.isNaN(opt.sigma))
				a.process();
			else
				a.process(opt.sigma);

			auto k = a.bestKey(opt.p, opt.m);
			auto scores = a.getScores();
			if (opt.graph)
				scores.printHistograms(15);
			writefln("%s\t%s\t%.2s", f, k, scores.confidence);
		} catch (LibAvException e) {
			hadError = true;
			stderr.writefln("%s\n", e.msg);
		}
	} else if (d.isDir)
		foreach (name; dirEntries(f, opt.recursive ? SpanMode.breadth :
								  SpanMode.shallow))
			hadError |= process(name, opt);
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
