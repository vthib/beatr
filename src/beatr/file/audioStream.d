
interface audioStream(T)
{
	@property bool empty() const;

	@property T front();

	void popFront();
}
