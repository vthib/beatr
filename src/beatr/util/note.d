module util.note;

@safe:

/++
 + The Note class wraps an integer representing one note
 + and provides a clearer name
 +/
class Note
{
private:
    immutable int k;
    immutable int minor;

    enum notes  = ["C", "C#", "D", "Eb", "E", "F",
                   "F#", "G", "Ab", "A", "Bb", "B"];
    enum codesM = ["8B","3B","10B","5B","12B","7B",
                   "2B","9B","4B","11B", "6B","1B"];
    enum codesm = ["5A","12A","7A","2A", "9A","4A",
                   "11A","6A","1A","8A","3A","10A"];

    invariant() {
        assert(0 <= k && k < 12);
        assert(-1 <= minor && minor <= 1);
    }

public:
    this(in int key, in int m = -1)
    {
        k = key;
        minor = m;
    }

    /++ Returns: an integer representing the note between 0 (C) and 11 (B) +/
    @property auto note() const nothrow
    {
        return k;
    }
    unittest
    {
        int k = 3;
        assert(k == new Note(k).note);
    }

    /++ Returns 1 for minor, 0 for major and -1 if neither +/
    @property auto mode() const nothrow
    {
        return minor;
    }
    unittest
    {
        assert(-1 == new Note(2).mode);
        assert(0 == new Note(5, 0).mode);
        assert(1 == new Note(7, 1).mode);
    }

    /++ return the english name of the note +/
    @property auto name() const nothrow
    {
        if (minor == -1)
            return notes[k];
        else
            return notes[k] ~ (minor == 1 ? "m" : "");
    }

    /++ return the english name of the note +/
    static string name(T)(in T i, in T minor = T.max) nothrow pure
    in
    {
        assert(0 <= i && i < 12);
        assert(minor == T.max || (0 <= minor && minor < 2));
    }
    body
    {
        /* XXX duplication of this code between static and non static method */
        if (minor == T.max)
            return notes[i];
        else
            return notes[i] ~ (minor == 1 ? "m" : "");
    }
    unittest
    {
        assert(new Note(4).name == "E");
        assert(new Note(7, 0).name == "G");
        assert(new Note(10, 1).name == "Bbm");

        assert(Note.name(4) == "E");
        assert(Note.name(7, 0) == "G");
        assert(Note.name(10, 1) == "Bbm");
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
        assert("G" == Note.name(k, 0));
        assert("Gm" == Note.name(k, 1));
        assert("G" == n.toString());

        k = 3;
        n = new Note(k, 1);
        assert("Ebm" == n.name);
        assert("Eb" == Note.name(k));
        assert("Ebm" == n.toString());
    }

    /++ return the camelot code of the note +/
    string toCode() const nothrow
    {
        return minor ? codesm[k] : codesM[k];
    }

    override bool opEquals(Object o) const
    {
        auto n = cast(const Note) o;

        return (n && n.note == k && n.mode == minor);
    }

    /* the note is caracterized by its number */
    alias k this;
}
