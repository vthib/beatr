/* XXX: replace 12 by semitons count */
alias ubyte[][] profile;

interface chromaProfile
{
	@property const(profile) getProfile() const nothrow;

	alias getProfile this;
}
