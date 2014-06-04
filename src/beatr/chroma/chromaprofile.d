/* XXX: replace 12 by semitons count */

import std.exception;

/++ Keeps coefficient representing a profile for each possible key
 + First dimension is 2 (major then minor)
 + Second dimension the number of possible key (12)
 + Third dimension is the number of notes in a scale (12)
 + Values are coefficients rating the corresponding note in the scale +/
alias ubyte[12][12][2] profile;

enum ProfileType {
	PROFILE_CLASSIC = 0,
	PROFILE_MAJ = 1,
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
	ubyte[12] maj;
	ubyte[12] min;
};

enum pfs = [
	pf([3, 0, 1, 0, 2, 1, 0, 2, 0, 2, 0, 1],
	   [3, 0, 1, 2, 0, 1, 0, 2, 0, 2, 0, 1]), // CLASSIC
	pf([2, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0],
       [2, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0]), // MAJ
	];
