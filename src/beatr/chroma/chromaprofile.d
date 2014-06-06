/* XXX: replace 12 by semitons count */

import std.exception;

/++ Keeps coefficient representing a profile for each possible key
 + First dimension is 2 (major then minor)
 + Second dimension the number of possible key (12)
 + Third dimension is the number of notes in a scale (12)
 + Values are coefficients rating the corresponding note in the scale +/
alias double[12][12][2] profile;

enum ProfileType {
	KRUMHANSL = 0,
	SCALE = 1,
	SCALE_HARM = 2,
	SCALE_BOTH = 3,
	CHORD = 4,
	CHORD_NORMALIZED = 5,
};

/++ An interface representing chroma profiles for each possible key +/
class ChromaProfile
{
	profile p;

	this(ProfileType pt)
	{
		foreach (i, ref tab; p[0])
			foreach (j, ref elem; tab)
				elem = pfs[pt].maj[(12 - i + j) % 12];

		foreach (i, ref tab; p[1])
			foreach (j, ref elem; tab)
				elem = pfs[pt].min[(12 - i + j) % 12];
	}

	alias p this;
}

private:
struct pf {
	double[12] maj;
	double[12] min;
};

enum pfs = [
	// KRUMHANSL
	pf([6.35, 2.23, 3.48, 2.33, 4.38, 4.09,
		2.52, 5.19, 2.39, 3.66, 2.29, 2.88],
       [6.33, 2.68, 3.52, 5.38, 2.60, 3.53,
		2.54, 4.75, 3.98, 2.69, 3.34, 3.17]),
	// SCALE
	pf([1, 0, 1, 0, 1, 1, 0, 1, 0, 1, 0, 1],
	   [1, 0, 1, 1, 0, 1, 0, 1, 1, 0, 1, 0]),
	// SCALE_HARM
	pf([1, 0, 1, 0, 1, 1, 0, 1, 0, 1, 0, 1],
	   [1, 0, 1, 1, 0, 1, 0, 1, 1, 0, 0, 1]),
	// SCALE_BOTH
	pf([1, 0, 1, 0, 1, 1, 0, 1, 0, 1, 0, 1],
	   [1, 0, 1, 1, 0, 1, 0, 1, 1, 0, 0.5, 0.5]),
	// CHORD
	pf([3, 0, 1, 0, 2, 1, 0, 2, 0, 2, 0, 1],
	   [2, 0, 1, 2, 0, 1, 0, 3, 1, 0, 1.5, 0.5]),
	// CHORD_NORMALIZED
	pf([3, 0, 1, 0, 2, 1, 0, 2, 0, 2, 0, 1],
	   [3, 0, 1, 2, 0, 1, 0, 2, 1, 0, 1.5, 0.5]),
	];
