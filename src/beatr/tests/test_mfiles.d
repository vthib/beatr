import std.file;
import std.stdio;
import std.algorithm;
import std.array;
import std.parallelism;
import std.string;
import std.path;

import analysis.analyzer;
import util.note;

void
errorMessage(string filename, string msg)
{
	stderr.writefln("Test on file '%s' failed: %s", filename, msg);
}

int
main()
{
	auto mfiles = array(dirEntries("mfiles", "*.{wav,mp3}", SpanMode.depth));
	bool[] res = new bool[mfiles.length];

	foreach(i, d; mfiles)
	{
		try {
			auto a = new Analyzer(d.name);
			a.process();
			auto key = a.bestKey();
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

	return cast(int) (res.length - count);
}
