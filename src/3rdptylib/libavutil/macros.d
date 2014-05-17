module libavutil.macros;

import std.string : format;

string AV_TOSTRING(T)(T s)
{
	static assert(__ctfe);
	return format("%s", s);
}
alias AV_TOSTRING AV_STRINGIFY;

string AV_GLUE(T, U)(T a, U b)
{
	static assert(__ctfe);
	return format("%s%s", a, b);
}
alias AV_GLUE AV_JOIN;

void AV_PRAGMA(T)(T s) {}
