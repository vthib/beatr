/* XXX: replace 12 by semitons count */

/++ Keeps coefficient representing a profile for each possible key
 + First dimension is the number of possible key (12/24, Cmaj->Bmaj
 + then possibly Cmin->Bmin).
 + Second dimension is the number of notes in a scale (12)
 + Values are coefficients rating the corresponding note in the scale +/
alias ubyte[][] profile;

/++ An interface representing chroma profiles for each possible key +/
interface ChromaProfile
{
	@property const(profile) getProfile() const nothrow;

	alias getProfile this;
}
