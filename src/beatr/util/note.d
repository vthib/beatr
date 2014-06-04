@safe:

/++
 + The Note class wraps an integer representing one note
 + and provides a clearer name
 +/
class Note
{
private:
	int k;
	int minor;

	enum notes = ["C", "C#", "D", "Eb", "E", "F",
				  "F#", "G", "G#", "A", "Bb", "B"];

	invariant() {
		assert(0 <= k && k < 12);
	}

public:
	this(in int key, in int m = -1) nothrow
	{
		k = key;
		minor = m;
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
		if (minor == -1)
			return notes[k];
		else
			return notes[k] ~ (minor == 1 ? "min" : "maj");
	}

	/++ return the english name of the note +/
	static string name(T)(in T i, in T minor = -1) nothrow pure
	in
	{
		assert(0 <= i && i < 12);
		assert(-1 <= minor && minor < 2);
	}
	body
	{
		if (minor == -1)
			return notes[i];
		else
			return notes[i] ~ (minor == 1 ? "min" : "maj");
	}

	/++ return the english name of the note +/
	override string toString() const nothrow
	{
		return name();
	}
	unittest
	{
		int k = 7;
		Note n = new Note(k);
		assert("G" == n.name);
		assert("G" == Note.name(k));
		assert("Gmaj" == Note.name(k, 0));
		assert("Gmin" == Note.name(k, 1));
		assert("G" == n.toString());

		k = 3;
		n = new Note(k, 1);
		assert("Ebmin" == n.name);
		assert("Eb" == Note.name(k));
		assert("Ebmin" == n.toString());
	}

	/* the note is caracterized by its number */
	alias k this;
}
