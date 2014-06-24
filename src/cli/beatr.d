module main;

import std.stdio;
import std.exception;
import std.getopt;
import std.algorithm;
import std.file;
import std.array;

import exc.libavexception;
import analysis.analyzer;
import analysis.scores;
import util.beatr;
import chroma.chromaprofile;
import util.window;

struct Options {
	MatchingType m;
	ProfileType p;
	bool recursive;
	bool sgraph;
	bool cgraph;
	bool chromagram;
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
			default:
				stderr.writefln("Unknown matching type '%s'", s);
				break;
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
		case "chord_krumhansl":  opt.p = ProfileType.CHORD_KRUMHANSL; break;
		default:
			stderr.writefln("Unknown profile type '%s'", val);
			break;
		}
	}

	void printHelp()
	{
		writefln("usage: %s [options] input", args[0]);
		writeln("\tOptions:");
		writeln("\t\t-c|--cgraph\tPrint an histogram of the chroma profiles");
		writeln("\t\t--chromagram\tPrint a chromagram");
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
		writeln("\t\t\t'scale_both', 'chord', 'chord_normalized'");
		writeln("\t\t\tor 'chord_krumhansl'");
		writeln("\t\t-q|--quiet\tOnly print the result");
		writeln("\t\t-r|--recursive\tRecursively analyze every file in "
				 "'input'");
		writeln("\t\t-v|--verbose\tAdd more messages");

		writeln("\t\t--fftsigma\tSelect a sigma value for the FFT "
				"interpolation");
		writeln("\t\t--fftimode\tSelect a FFT interpolation mode: 'triangle', "
				"'rectangle', 'hann' or 'gaussian'");

		writeln("\t\t--scales N:M\tAnalyze scales between the N-th one and "
				"the M-th one");
		writeln("\t\t--bufsize\tSize of the buffer used to decode the audio "
				"stream in seconds");
	}

	try {
		getopt(
			args,
			"cgraph|c", &opt.cgraph,
			"chromagram|cg", &opt.chromagram,
			"debug|d", &setOptions,
			"graph|g", &opt.sgraph,
			"help|h", &printHelp,
			"mtype|m", &matchingCallback,
			"profile|p", &profileCallback,
			"quiet|q", &setOptions,
			"recursive|r", &opt.recursive,
			"fftsigma", &setOptions2,
			"fftimode", &setOptions2,
			"scales", &setOptions2,
			"bufsize", &setOptions2,
			"verbose|v", &setOptions);
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
		Beatr.writefln(Lvl.VERBOSE, "Processing '%s'...", f);
		try {
			auto a = new Analyzer(f);
			a.process();

			auto k = a.bestKey(opt.p, opt.m);
			if (opt.cgraph)
				a.bands.printHistograms(25);
			if (opt.sgraph)
				a.scores.printHistograms(25);
			if (opt.chromagram)
				a.bands.printChromagram();
			writefln("%s\t%s\t%.2s", f, k, a.scores.confidence);
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
setOptions(string opt)
{
	switch (opt) {
	case "verbose|v":
		Beatr.verboseLevel = Lvl.VERBOSE;
		break;
	case "debug|d":
		Beatr.verboseLevel = Lvl.DEBUG;
		break;
	case "quiet|q":
		Beatr.verboseLevel = Lvl.NORMAL;
		break;
	default:
		stderr.writefln("Unknown option '%s'", opt);
		break;
	}
}

void
setOptions2(string opt, string value)
{
	switch (opt) {
	case "fftsigma":
		Beatr.fftSigma = to!(typeof(Beatr.fftSigma))(value);
		break;
	case "fftimode":
		switch (value) {
		case "triangle":
			Beatr.fftInterpolationMode = WindowType.TRIANGLE;
			break;
		case "rectangle":
			Beatr.fftInterpolationMode = WindowType.RECTANGLE;
			break;
		case "hann":
			Beatr.fftInterpolationMode = WindowType.HANN;
			break;
		case "flattop":
			Beatr.fftInterpolationMode = WindowType.FLATTOP;
			break;
		case "gaussian":
			Beatr.fftInterpolationMode = WindowType.GAUSSIAN;
			break;
		default:
			stderr.writefln("Unknown FFT Interpolation Mode '%s'", value);
			break;
		}
		break;
	case "scales":
		try {
			auto nums = splitter(value, ':').array;
			enforce(nums.length == 2);

			ubyte start = to!ubyte(nums[0]);
			ubyte end = to!ubyte(nums[1]);
			enforce(end > start);

			Beatr.scaleOffset = start;
			Beatr.scaleNumbers = cast(ubyte) (end - start);
		} catch (Exception e) {
			stderr.writefln("--scales requires argument in form 'N:M' with M > N");
			break;
		}
		break;
	case "bufsize":
		Beatr.framesBufSize = to!(typeof(Beatr.framesBufSize))(value);
		break;
	default:
		stderr.writefln("Unknown option '%s'", opt);
		break;
	}
}
