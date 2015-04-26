module audio.fftutils;

import std.file : mkdir, FileException;
import core.stdc.errno : EEXIST;
import std.string: toStringz;
import std.path : buildPath;
import std.windows.syserror;

import fftw.fftw3;

import util.beatr;

immutable(char) *wisdomFilename() nothrow
{
	return buildPath(Beatr.configDir, "wisdom").toStringz;
}

void fftInit() nothrow
{
	try {
		mkdir(Beatr.configDir);
	} catch (Exception e) {
		if (auto f = cast(FileException)e) {
			if (f.errno == EEXIST)
				goto end;
		}
		if (auto f = cast(WindowsException)e) {
			try {
				if (f.code == 183) /* ERROR_ALREADY_EXISTS */
					goto end;
			} catch (Exception e) {
			}
		}
		Beatr.writefln(Lvl.warning, "error creating config directory "
					   "'%s': %s", Beatr.configDir, e.msg);
		return;
	}

end:
	fftw_import_wisdom_from_filename(wisdomFilename());
}

void fftDestroy() nothrow
{
	fftw_cleanup();
}

void fftSaveWisdom()
{
	auto f = wisdomFilename();
	Beatr.writefln(Lvl.debug_, "no wisdom available: new wisdom exported "
				   "to '%s'", f);
	fftw_export_wisdom_to_filename(f);
}
