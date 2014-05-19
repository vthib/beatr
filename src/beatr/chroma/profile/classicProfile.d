import chroma.profile.chromaProfile;

class classicProfile : chromaProfile
{
	profile pf;

	this()
	{
		pf = new profile(12, 12);

		foreach(i, ref t; pf) {
			t[(i + 0) % 12]  = 3;
			t[(i + 1) % 12]  = 0;
			t[(i + 2) % 12]  = 1;
			t[(i + 3) % 12]  = 0;
			t[(i + 4) % 12]  = 2;
			t[(i + 5) % 12]  = 1;
			t[(i + 6) % 12]  = 0;
			t[(i + 7) % 12]  = 2;
			t[(i + 8) % 12]  = 0;
			t[(i + 9) % 12]  = 2;
			t[(i + 10) % 12] = 0;
			t[(i + 11) % 12] = 1;
		}
	}

	~this()
	{
		pf.destroy;
	}

	@property const(profile) getProfile() const nothrow
	{
		return pf;
	}
}
