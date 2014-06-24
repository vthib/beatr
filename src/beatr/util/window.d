import std.math;

enum WindowType {
	TRIANGLE,
	RECTANGLE,
	GAUSSIAN,
	HANN,
	FLATTOP,
};

T
window(T)(WindowType t, in T l, in T r, in T mu, in T x, in T Q)
in
{
	assert(l <= x && x <= r);
	assert(l < mu && mu < r);
	assert(Q > 0);
}
body
{
	T coeff;

	final switch(t) {
	case WindowType.TRIANGLE:
		coeff = triangle(mu, l, r, x);
		break;
	case WindowType.RECTANGLE:
		coeff = 1;
		break;
	case WindowType.GAUSSIAN:
		coeff = gaussian(mu, Q, x);
		break;
	case WindowType.HANN:
		coeff = hann(l, r, x);
		break;
	case WindowType.FLATTOP:
		coeff = flattop(l, r, x);
		break;
	}

	return coeff;
}

private:

T
triangle(T)(in T mu, in T l, in T r, in T x) pure @safe
{
	if (x < mu)
		return (x - l)/(mu - l);
	else
		return (r - x)/(r - mu);
}
unittest
{
	import std.math : approxEqual;

	assert(approxEqual(triangle(5., 3., 7., 3.), 0));
	assert(approxEqual(triangle(5., 3., 7., 4.), 0.5));
	assert(approxEqual(triangle(5., 3., 7., 5.), 1));
	assert(approxEqual(triangle(5., 3., 7., 6.), 0.5));
	assert(approxEqual(triangle(5., 3., 7., 7.), 0));
}

T
gaussian(T)(in T mu, in T sigma, in T x) pure @safe
{
	immutable auto a = (x - mu)/sigma;
	return exp(-0.5*a*a);
}
unittest
{
	import std.math : approxEqual;

	assert(approxEqual(gaussian(3., 1., 3.), 1));
	immutable double a = sqrt(log(4));
	assert(approxEqual(gaussian(3. - a, 1., 3.), 0.5));
	assert(approxEqual(gaussian(3., 1., 50.), 0.));
}

T
hann(T)(in T l, in T r, in T j) pure @safe
{
	return 1 - cos(2*PI * ((j - l)/(r - l)));
}
unittest
{
	import std.math : approxEqual;

	assert(approxEqual(hann(1., 3., 1.), 0.));
	assert(approxEqual(hann(1., 3., 2.), 2.));
	assert(approxEqual(hann(1., 3., 3.), 0.));

	assert(approxEqual(hann(1., 5., 2.), 1.));
	assert(approxEqual(hann(1., 5., 4.), 1.));
}

T
flattop(T)(in T l, in T r, in T j) pure @safe
{
	enum coeffs = [1.93, 1.29, 0.388, 0.028];

	auto ret = 1.;
	foreach(i, a; coeffs)
		ret += a * cos((i+1)*2*PI * ((j - l)/(r - l)));

	return ret;
}
unittest
{
	import std.math : approxEqual;

	assert(approxEqual(flattop(1., 3., 1.), 0.));
	assert(flattop(1., 3., 2.) > 4.);
	assert(approxEqual(flattop(1., 3., 3.), 0.));

	assert(flattop(0., 8., 1.) < 0.);
	assert(flattop(0., 8., 2.) < 0.);
	assert(flattop(0., 8., 6.) < 0.);
	assert(flattop(0., 8., 7.) < 0.);
}
