import std.file;
import std.stdio;
import std.algorithm;
import std.array;
import std.parallelism;
import std.string;
import std.path;

import analysis.analyzer;
import util.note;
import audio.fftutils;

void
errorMessage(string filename, string msg)
{
	stderr.writefln("Test on file '%s' failed: %s", filename, msg);
}

int
main(string[] args)
{
    string dirname;

    if (args.length > 1)
        dirname = args[1] ~ "/mfiles";
    else
        dirname = "mfiles";

	beatrInit();

	auto mfiles = array(dirEntries(dirname, "*.{wav,mp3}", SpanMode.depth));
	bool[] res = new bool[mfiles.length];
	auto a = new Analyzer();

	foreach(i, d; mfiles)
	{
		try {
			a.processFile(d.name);
			auto s = a.score();
			s.printHistograms(10);
			a.bands.printChromagram();
			a.bands.printHistograms(10);
			auto key = s.bestKey();
			if (baseName(d.name).startsWith(key.name)) {
				res[i] = true;
				writefln("File '%s', key detected; %s", d.name, key);
			} else
				errorMessage(d.name, format("Wrong Key detected: %s", key));
		} catch(Exception e)
			errorMessage(d.name, e.msg);
	}

	auto count = reduce!((acc, r) => acc + r)(0, res);
	writefln("%s/%s tests passed", count, res.length);

	beatrCleanup();

	return cast(int) (res.length - count);
}
