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
	unittest
	{
		int k = 3;
		assert(k == new Note(k).get);
	}

	/++ return the english name of the note +/
	@property auto name() const nothrow
	{
		return notes[k];
	}

	/++ return the english name of the note +/
	static string name(T)(in T i) nothrow pure
	in
	{
		assert(0 <= i && i < 12);
	}
	body
	{
		return notes[i];
	}

	/++ return the english name of the note +/
	override string toString() const nothrow
	{
		return notes[k];
	}
	unittest
	{
		int k = 7;
		Note n = new Note(k);
		assert("G" == n.name);
		assert("G" == Note.name(k));
		assert("G" == n.toString());

		k = 3;
		n = new Note(k);
		assert("Eb" == n.name);
		assert("Eb" == Note.name(k));
		assert("Eb" == n.toString());
	}

	/* the note is caracterized by its number */
	alias k this;
}
