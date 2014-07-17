/++ Keeps coefficient representing a profile for each possible key
 + First dimension is 2 (major then minor)
 + Second dimension the number of possible key (12)
 + Third dimension is the number of notes in a scale (12)
 + Values are coefficients rating the corresponding note in the scale +/
alias double[12][12][2] profile;

/++ The different profile types available +/
enum ProfileType {
	krumhansl = 0, /++ Profile based on Krumhansl's works +/
	scale = 1, /++ 1 if the note is in the scale, 0 otherwise +/
	scaleHarm = 2, /++ Idem but with the harmonic scale for minor +/
	scaleBoth = 3, /++ A mean of the two previous profiles +/
	chord = 4, /++ A profile counting the occurence of every note in
				+ 4 chords: tonic, sub-dominant, dominant and relative +/
    chordNormalized = 5, /++ Idem but renormalized between the tonic
						   + and the dominant for minor +/
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
	unittest
	{
		import std.algorithm : equal;

		enum type = ProfileType.chord;
		auto cp = new ChromaProfile(type);
		double[3] a = [1, 2, 3];
		assert(equal(cp[0][0][], pfs[type].maj[]));
		assert(equal(cp[0][4][], pfs[type].maj[($ - 4) .. $]
					 ~ pfs[type].maj[0 .. ($ - 4)]));
		assert(equal(cp[1][0][], pfs[type].min[]));
		assert(equal(cp[1][8][], pfs[type].min[($ - 8) .. $]
					 ~ pfs[type].min[0 .. ($ - 8)]));
	}

	alias p this;
}

private:
struct pf {
	double[12] maj;
	double[12] min;
};

enum pfs = [
	// krumhansl
	pf([6.35, 2.23, 3.48, 2.33, 4.38, 4.09,
		2.52, 5.19, 2.39, 3.66, 2.29, 2.88],
       [6.33, 2.68, 3.52, 5.38, 2.60, 3.53,
		2.54, 4.75, 3.98, 2.69, 3.34, 3.17]),
	// scale
	pf([1, 0, 1, 0, 1, 1, 0, 1, 0, 1, 0, 1],
	   [1, 0, 1, 1, 0, 1, 0, 1, 1, 0, 1, 0]),
	// scaleHarm
	pf([1, 0, 1, 0, 1, 1, 0, 1, 0, 1, 0, 1],
	   [1, 0, 1, 1, 0, 1, 0, 1, 1, 0, 0, 1]),
	// scaleBoth
	pf([1, 0, 1, 0, 1, 1, 0, 1, 0, 1, 0, 1],
	   [1, 0, 1, 1, 0, 1, 0, 1, 1, 0, 0.5, 0.5]),
	// chord
	pf([3, 0, 1, 0, 2, 1, 0, 2, 0, 2, 0, 1],
	   [2, 0, 1, 2, 0, 1, 0, 3, 1, 0, 1.5, 0.5]),
	// chordNormalized
	pf([3, 0, 1, 0, 2, 1, 0, 2, 0, 2, 0, 1],
	   [3, 0, 1, 2, 0, 1, 0, 2, 1, 0, 1.5, 0.5]),
	];
unittest
{
	assert(pfs.length == ProfileType.max + 1);
}
