@safe:

/++
 + The Note class wraps an integer representing one note
 + and provides a clearer name
 +/
class Note
{
private:
	int k;
	enum notes = ["C", "C#", "D", "Eb", "E", "F",
				  "F#", "G", "G#", "A", "Bb", "B"];

	invariant() {
		assert(0 <= k && k < 12);
	}

public:
	this(in int key) nothrow
	{
		k = key;
	}

	@property auto get() const nothrow
	{
		return k;
	}

	static string name(T)(in T i) nothrow pure
	in
	{
		assert(0 <= i && i < 12);
	}
	body
	{
		return notes[i];
	}


	override string toString() const nothrow
	{
		return name(k);
	}

	alias k this;
}
