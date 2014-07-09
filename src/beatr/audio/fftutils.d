import std.file : mkdir, FileException;
import core.stdc.errno : EEXIST;
import std.string: toStringz;

import fftw.fftw3;

import util.beatr;

void fftInit() nothrow
{
	try {
		mkdir(Beatr.configDir);
	} catch (Exception e) {
		if (auto f = cast(FileException)e) {
			if (f.errno == EEXIST)
				goto end;
		}
		Beatr.writefln(Lvl.warning, "error creating config directory "
					   "'%s': %s", Beatr.configDir, e.msg);
		return;
	}

end:
	immutable auto filename = toStringz(Beatr.configDir ~ "/wisdom");
	fftw_import_wisdom_from_filename(filename);
}

void fftDestroy() nothrow
{
	fftw_cleanup();
}

void fftSaveWisdom()
{
	Beatr.writefln(Lvl.debug_, "no wisdom available: new wisdom exported "
				   "to '%s'", Beatr.configDir ~ "/wisdom");
	immutable auto filename = toStringz(Beatr.configDir ~ "/wisdom");
	fftw_export_wisdom_to_filename(filename);
}
