/++
 + Interface of a Range object providing access to a stream
 + input of audio data
 +/
interface AudioStream(T)
{
	@property bool empty() const;

	@property T front();

	void popFront();
}
