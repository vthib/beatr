class key
{
	ulong k;
	enum notes = ["C", "C#", "D", "Eb", "E", "F",
				  "F#", "G", "G#", "A", "Bb", "B"];

	this(ulong key)
	{
		k = key;
	}

	static string name(ulong i)
	{
		return notes[i];
	}

	override string toString() const
	{
		return name(k);
	}

	alias k this;
}
