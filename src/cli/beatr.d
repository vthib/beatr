module main;

import io = std.stdio;
import std.exception;
import std.getopt;
import std.algorithm;
import std.file;
import std.array;
import std.string: toLower;
import std.conv : to;

import exc.libavexception;
import analysis.analyzer;
import analysis.scores;
import util.beatr;
import chroma.chromaprofile;
import util.window;
import util.weighting;

struct Options {
	MatchingType match;
	ProfileType profile;
	CorrelationMethod corr;
	WeightCurve wcurve;
	bool recursive;
	bool sgraph;
	bool cgraph;
	bool chromagram;
	size_t seconds;
}

/* used to map options like "--profile" with a corresponding enum value */
struct Info(T) {
	string name;
    T type;
};

Info!ProfileType[] profiles;
Info!MatchingType[] matchings;
Info!WindowType[] windows;
Info!CorrelationMethod[] corrs;
Info!WeightCurve[] wcurves;

/* fill the arrays mapping enum names to values */
void
initOptArrays()
{
	void
	fillInfos(T)(ref Info!T[] a)
	{
		foreach (v; __traits(allMembers, T))
			a ~= Info!T(v.toLower, __traits(getMember, T, v));
	}

	fillInfos(profiles);
	fillInfos(matchings);
	fillInfos(windows);
	fillInfos(corrs);
	fillInfos(wcurves);
}

/***** callbacks to set the options values *****/

void matchingCallback(ref Options opt, string option, string val)
{
	bool found;

	opt.match = MatchingType.classic;
	foreach (s; val.splitter(',')) {
		found = false;
		foreach(m; matchings) {
			if (val == m.name) {
				opt.match |= m.type;
				found = true;
				break;
			}
		}
		if (!found) {
			io.stderr.writefln("Unknown matching type '%s'", s);
			return;
		}
	}
}

void infoArrayCallback(T)(ref T o, ref Info!T[] a, string option, string val)
{
	foreach(p; a) {
		if (val == p.name) {
			o = p.type;
			return;
		}
	}
	io.stderr.writefln("Unknown %s: '%s'", T.stringof, val);
}

void printHelp(string programName)
{
	void printArray(T)(Info!T[] a)
	{
		size_t i = 0;
		foreach (j, v; a) {
			if (i++ % 4 == 0)
				io.write("\n\t\t\t");
			io.writef("'%s'", v.name);
			if (j != a.length - 1)
				io.write(", ");
		}
		io.writeln();
	}

	io.writefln("usage: %s [options] input", programName);
	io.writeln("\tOptions:");
	io.writeln("\t\t-c|--cgraph\tPrint an histogram of the chroma "
			   "profiles");
	io.writeln("\t\t--chromagram\tPrint a chromagram");
	io.writeln("\t\t-d|--debug\tAdd even more messages");
	io.writeln("\t\t-g|--graph\tPrint an histogram of the notes from the "
			   "input");
	io.writeln("\t\t-h|--help\tPrint this help message");

	/* print all the possible matching types */
	io.writeln("\t\t-m|--mtype\tUse the specified matching algorithm.");
	io.write("\t\t\tIf several are specified separated with a ',', then\n"
			 "\t\t\tadd the combination of them. Possible choices are:");
	printArray(matchings);

	/* print all possible profile types */
	io.write("\t\t-p|--profile\tUse the specified profile, amongst:");
	printArray(profiles);

	/* print all possible correlation methods */
	io.write("\t\t--correlation\tUse the specified correlation method, "
			 "amongst:");
	printArray(corrs);

	io.writeln("\t\t-q|--quiet\tOnly print the result");
	io.writeln("\t\t-r|--recursive\tRecursively analyze every file in "
			   "'input'");
	io.writeln("\t\t-v|--verbose\tAdd more messages");

	io.writeln("\t\t--fftsigma\tSelect a sigma value for the FFT "
			   "interpolation");
	/* print all possible window type for interpolation */
	io.write("\t\t--fftimode\tSelect a FFT interpolation mode, amongst:");
	printArray(windows);

	/* print all possible weight curves */
	io.write("\t\t--weightcurve\tSelect a weight curve for adjustment, "
			 "amongst:");
	printArray(wcurves);

	io.writeln("\t\t--scales N:M\tAnalyze scales between the N-th one and "
			   "the M-th one");
	io.writeln("\t\t--bufsize\tSize of the buffer used to decode the\n"
			   "\t\t\taudio stream in seconds");

	io.writeln("\t\t--fftsize\tSize of the fft transformation");
	io.writeln("\t\t--fftoverlaps\tNumber of overlaps executed when the\n"
			   "\t\t\tfftsize is different than the audio stream size");
	io.writeln("\t\t--samplerate\tSamplerate used internally to which the\n"
			   "\t\t\taudio input is reduced");

	io.writeln("\t\t--cutoff\tcutoff frequency of the low pass filter");
	io.writeln("\t\t--filter\tboolean whether to use or not the low pass "
			   "filter");

	io.writeln("\t\t--seconds\tOnly analyze first 'n' seconds from the input");
}

int
main(string args[])
{
	Options opt;

	initOptArrays();

	opt.match = MatchingType.dominant;

	try {
		getopt(
			args,
			"cgraph|c", &opt.cgraph,
			"chromagram", &opt.chromagram,
			"debug|d", &setOptions,
			"graph|g", &opt.sgraph,
			"seconds", &opt.seconds,
			"help|h", () => printHelp(args[0]),
			"mtype|m", (string a, string b) => matchingCallback(opt, a, b),
			"profile|p",
			(string a, string b) => infoArrayCallback(opt.profile,
													  profiles, a, b),
			"correlation",
			(string a, string b) => infoArrayCallback(opt.corr,
													  corrs, a, b),
			"weightcurve",
			(string a, string b) => infoArrayCallback(opt.wcurve,
													  wcurves, a, b),
			"quiet|q", &setOptions,
			"recursive|r", &opt.recursive,
			"fftsigma", &setOptions2,
			"fftimode", &setOptions2,
			"scales", &setOptions2,
			"bufsize", &setOptions2,
			"fftsize", &setOptions2,
			"fftoverlaps", &setOptions2,
			"samplerate", &setOptions2,
			"mcoeffs", &setOptions2,
			"cutoff", &setOptions2,
			"filter", &setOptions2,
			"verbose|v", &setOptions);
	} catch (Exception e) {
		io.stderr.writefln("error: %s", e.msg);
		return 3;
	}

	Beatr.weightCurve = opt.wcurve;

	if (args.length <= 1) {
		printHelp(args[0]);
		return 2;
	} else
		return process(args[1], opt, new Analyzer());
}

bool
process(string f, Options opt, Analyzer a)
{
	bool hadError = false;
	DirEntry d;

	try {
		d = DirEntry(f);
	} catch (FileException e) {
		io.stderr.writefln("error: %s", e.msg);
		return true;
	}

	if (d.isFile) {
		Beatr.writefln(Lvl.verbose, "Processing '%s'...", f);
		try {
			if (opt.seconds != 0)
				a.processFile(f, opt.seconds);
			else
				a.processFile(f);

			auto s = a.score(opt.profile, opt.corr, opt.match);
			auto k = s.bestKey();
			if (opt.cgraph)
				a.bands.printHistograms(25);
			if (opt.sgraph)
				s.printHistograms(25);
			if (opt.chromagram)
				a.bands.printChromagram();
			io.writefln("%s\t%s\t%.2s", f, k, s.confidence);
		} catch (LibAvException e) {
			hadError = true;
			io.stderr.writefln("%s\n", e.msg);
		}
	} else if (d.isDir)
		foreach (name; dirEntries(f, opt.recursive ? SpanMode.breadth :
								  SpanMode.shallow))
			hadError |= process(name, opt, a);
	else
		io.stderr.writefln("'%s' is neither a file nor a directory", f);

	return hadError;
}

void
setOptions(string opt)
{
	switch (opt) {
	case "verbose|v":
		Beatr.verboseLevel = Lvl.verbose;
		break;
	case "debug|d":
		Beatr.verboseLevel = Lvl.debug_;
		break;
	case "quiet|q":
		Beatr.verboseLevel = Lvl.normal;
		break;
	default:
		io.stderr.writefln("Unknown option '%s'", opt);
		break;
	}
}

void
setOptions2(string opt, string value)
{
	switch (opt) {
	case "fftimode":
		foreach(w; windows) {
			if (value == w.name) {
				Beatr.fftInterpolationMode = w.type;
				return;
			}
		}
		io.stderr.writefln("Unknown FFT Interpolation Mode '%s'", value);
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
			io.stderr.writefln("--scales requires argument in form 'N:M' with M > N");
			break;
		}
		break;
	case "fftsigma":
		Beatr.fftSigma = to!(typeof(Beatr.fftSigma))(value);
		break;
	case "bufsize":
		Beatr.framesBufSize = to!(typeof(Beatr.framesBufSize))(value);
		break;
	case "fftsize":
		Beatr.fftTransformSize = to!(typeof(Beatr.fftTransformSize))(value);
		break;
	case "fftoverlaps":
		Beatr.fftNbOverlaps= to!(typeof(Beatr.fftNbOverlaps))(value);
		break;
	case "samplerate":
		Beatr.sampleRate = to!(typeof(Beatr.sampleRate))(value);
		break;
	case "mcoeffs":
		Beatr.mCoefficients = to!(typeof(Beatr.mCoefficients))(value);
		break;
	case "cutoff":
		Beatr.cutoffFreq = to!(typeof(Beatr.cutoffFreq))(value);
		break;
	case "filter":
		Beatr.useFilter = to!(typeof(Beatr.useFilter))(value);
		break;
	default:
		io.stderr.writefln("Unknown option '%s'", opt);
		break;
	}
}
