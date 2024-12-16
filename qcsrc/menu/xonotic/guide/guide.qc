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
	#define TOPIC(src, name, icon) n++;
	TOPICS(TOPIC);
	#undef TOPIC
	return n;
}

entity DebugSource_find_debug()
{
	entity head = NULL, tail = NULL;
	for (entity it = NULL; (it = nextent(it)); ) {
		if (!it.instanceOfObject) continue;
		if (it.instanceOfGameItem) continue;
		if (it.instanceOfAnimHost) continue;
		if (it.instanceOfDataSource) continue;
		if (it.classname == "Object") continue;
		if (it.classname == "vtbl") continue;
		if (!tail)
			tail = head = it;
		else
		{
			tail.nextdebug = it;
			tail = it;
		}
	}
	return head;
}
METHOD(DebugSource, getEntry, entity(DebugSource this, int i, void(string, string) returns))
{
	int idx = 0;
	entity e;
	for (e = DebugSource_find_debug(); e; e = e.nextdebug)
	{
		if (strstrofs(sprintf("entity %i", e), DebugSource_activeFilter, 0) < 0) continue;
		if (idx++ == i) break;
	}
	if (returns)
		e.display(e, returns);
	return e;
}
METHOD(DebugSource, reload, int(DebugSource this, string filter))
{
	DebugSource_activeFilter = filter;
	int idx = 0;
	entity e;
	for (e = DebugSource_find_debug(); e; e = e.nextdebug)
	{
		if (strstrofs(sprintf("entity %i", e), DebugSource_activeFilter, 0) < 0) continue;
		idx++;
	}
	return idx;
}

METHOD(MapSource, getEntry, entity(MapSource this, int i, void(string, string) returns))
{
	if (!MapInfo_Get_ByID(i))
		return DataSource_false;
	string path = strcat("/maps/", MapInfo_Map_bspname);
	string img = draw_PictureSize(path) ? path : "nopreview_map";
	if (returns)
		returns(MapInfo_Map_titlestring, img);
	MapInfo_ClearTemps();
	return DataSource_true;
}
METHOD(MapSource, indexOf, int(MapSource this, string s))
{
	MapInfo_FindName(s);
	return MapInfo_FindName_firstResult;
}
METHOD(MapSource, reload, int(MapSource this, string s))
{
	_MapInfo_FilterGametype(MAPINFO_TYPE_ALL, 0, 0, 0, 0);
	if (s)
		MapInfo_FilterString(s);
	return MapInfo_count;
}
METHOD(MapSource, destroy, void(MapSource this))
{
	MapInfo_Shutdown();
}
