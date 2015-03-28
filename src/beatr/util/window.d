module util.window;

import std.math;

/++ Different types of windows usable +/
enum WindowType {
	triangle,
	rectangle,
	gaussian,
	hann,
	flattop,
};

template Window(T) {
private:
	alias wFun = T function(T x, T mu, T l, T r, T Q);

public:
	wFun
	getFunction(in WindowType t)
	{
		final switch(t) {
		case WindowType.triangle:
			return (x, mu, l, r, Q) =>  triangle!T(x, mu, l, r);
		case WindowType.rectangle:
			return (x, mu, l, r, Q) => 1;
		case WindowType.gaussian:
			return (x, mu, l, r, Q) => gaussian!T(x, mu, Q);
		case WindowType.hann:
			return (x, mu, l, r, Q) => hann!T(x, l, r);
		case WindowType.flattop:
			return (x, mu, l, r, Q) => flattop!T(x, l, r);
		}
	}
}

/++ compute the result of a window function
 + Params:
 +  t = the window type
 +  l = the left boundary
 +  r = the right boundary
 +  mu = the center of the window (mu = (l + r)/2)
 +  Q = the parameter of the window function (if applicable)
 + Returns: f(x) where f is the window function
 +/
T
window(T)(in WindowType t, in T x, in T mu, in T l, in T r, in T Q)
in
{
	assert(l <= x && x <= r);
	assert(l < mu && mu < r);
	assert(Q > 0);
}
body
{
	T coeff;

	auto f = windowFunction!T(t);

	return f(x, mu, l, r, Q);
}

private:
T
triangle(T)(in T x, in T mu, in T l, in T r) pure @safe
{
	if (x < mu)
		return (x - l)/(mu - l);
	else
		return (r - x)/(r - mu);
}
unittest
{
	import std.math : approxEqual;

	assert(approxEqual(triangle(3., 5., 3., 7.), 0));
	assert(approxEqual(triangle(4., 5., 3., 7.), 0.5));
	assert(approxEqual(triangle(5., 5., 3., 7.), 1));
	assert(approxEqual(triangle(6., 5., 3., 7.), 0.5));
	assert(approxEqual(triangle(7., 5., 3., 7.), 0));
}

T
gaussian(T)(in T x, in T mu, in T sigma) pure @safe
{
	immutable auto a = (x - mu)/sigma;
	return exp(-0.5*a*a);
}
unittest
{
	import std.math : approxEqual;

	assert(approxEqual(gaussian(3., 3., 1.), 1));
	immutable double a = sqrt(log(4));
	assert(approxEqual(gaussian(3., 3. - a, 1.), 0.5));
	assert(approxEqual(gaussian(50., 3., 1.), 0.));
}

T
hann(T)(in T x, in T l, in T r) pure @safe
{
	return 1 - cos(2*PI * ((x - l)/(r - l)));
}
unittest
{
	import std.math : approxEqual;

	assert(approxEqual(hann(1., 1., 3.), 0.));
	assert(approxEqual(hann(2., 1., 3.), 2.));
	assert(approxEqual(hann(3., 1., 3.), 0.));

	assert(approxEqual(hann(2., 1., 5.), 1.));
	assert(approxEqual(hann(4., 1., 5.), 1.));
}

T
flattop(T)(in T x, in T l, in T r) pure @safe
{
	enum a = [1., 1.93, 1.29, 0.388, 0.028];

	immutable auto d = (x - l)/(r - l);
	return a[0] - a[1]*cos(2*PI*d) + a[2]*cos(4*PI*d)
		- a[3]*cos(6*PI*d) + a[4]*cos(8*PI*d);
}
unittest
{
	import std.math : approxEqual;

	assert(approxEqual(flattop(1., 1., 3.), 0.));
	assert(flattop(2., 1., 3.) > 4.);
	assert(approxEqual(flattop(3., 1., 3.), 0.));

	assert(flattop(1., 0., 8.) < 0.);
	assert(flattop(2., 0., 8.) < 0.);
	assert(flattop(6., 0., 8.) < 0.);
	assert(flattop(7., 0., 8.) < 0.);
}
