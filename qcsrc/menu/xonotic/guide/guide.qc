#include "guide.qh"

METHOD(TopicSource, getEntry, entity(TopicSource this, int i, void(string, string) returns))
{
	int idx = 0;
	#define TOPIC(src, name, icon) \
		if (idx++ == i) \
		{ \
			if (returns) \
				returns(name, icon); \
			return DataSource_true; \
		}
	TOPICS(TOPIC);
	#undef TOPIC
	if (returns)
		returns("undefined", "undefined");
	return DataSource_false;
}
METHOD(TopicSource, reload, int(TopicSource this, string filter))
{
	int n = 0;
	#define TOPIC(src, name, icon) ++n;
	TOPICS(TOPIC);
	#undef TOPIC
	return n;
}
