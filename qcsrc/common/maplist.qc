#include "maplist.qh"

#include <common/mapinfo.qh>
#include <common/util.qh>

// A cvar written from QC can't exceed 16383 bytes and one read back in is capped the same way, so
// leave a margin rather than writing a list that only just fits and can never be added to.
const int MAPLIST_CVAR_MAXLEN = 15000;

int _MapList_ReadFile(int buf)
{
	int fh = fopen(MAPLIST_FILE, FILE_READ);
	if(fh < 0)
		return -1;

	int n = 0;
	for(string l; (l = fgets(fh)); )
	{
		l = strreplace("\r", "", l); // tolerate a file written on Windows
		// one map per line; a line may be commented out with # or //, and anything after the map
		// name is ignored so a comment can be put next to an entry
		FOREACH_WORD(l, true,
		{
			if(substring(it, 0, 1) == "#" || substring(it, 0, 2) == "//")
				break;
			bufstr_set(buf, n++, it);
			break; // first word only
		});
	}
	fclose(fh);
	return n;
}

bool _MapList_WriteFile(int buf, int count)
{
	int fh = fopen(MAPLIST_FILE, FILE_WRITE);
	if(fh < 0)
	{
		LOG_WARNF("MapList: can't write %s, the map list won't persist", MAPLIST_FILE);
		return false;
	}

	fputs(fh, "// Xonotic map list: one map per line, # or // comments a line out.\n");
	fputs(fh, "// Used when g_maplist is empty. Delete it to go back to using every installed map.\n");
	for(int i = 0; i < count; ++i)
		fputs(fh, strcat(bufstr_get(buf, i), "\n"));
	fclose(fh);
	return true;
}

int MapList_ToBuffer(int buf)
{
	// 1. the cvar wins whenever it's set: an admin's or the menu's curated list
	if(cvar_string("g_maplist") != "")
	{
		MapList_Source = MAPLIST_SOURCE_CVAR;
		int n = 0;
		FOREACH_WORD(cvar_string("g_maplist"), true, bufstr_set(buf, n++, it));
		return n;
	}

	// 2. the file, if one has been generated or supplied
	int n = _MapList_ReadFile(buf);
	if(n > 0)
	{
		MapList_Source = MAPLIST_SOURCE_FILE;
		return n;
	}

	// 3. everything installed, resolved fresh every time.
	// NOTE: deliberately NOT written out. Saving it here would turn a list that tracks the installed
	// maps into a frozen snapshot, and a map added afterwards would never enter the rotation until
	// someone deleted the file. Nothing configured means "whatever is installed right now", which is
	// what an empty g_maplist has always meant.
	MapList_Source = MAPLIST_SOURCE_ALL;
	MapInfo_Enumerate();
	_MapInfo_FilterGametype(MAPINFO_TYPE_ALL, 0, 0, MapInfo_ForbiddenFlags(), 0);
	n = _MapInfo_FilteredToBuffer(buf);

	// leave the filter as we found it: callers (getlsmaps, the menu list) read it right after
	MapInfo_FilterGametype(MapInfo_CurrentGametype(), MapInfo_CurrentFeatures(),
		MapInfo_RequiredFlags(), MapInfo_ForbiddenFlags(), 0);
	return n;
}

int MapList_FromBuffer(int buf, int count)
{
	// measure before committing: a list that doesn't fit must not be silently cut in half
	int len = 0;
	for(int i = 0; i < count; ++i)
		len += strlen(bufstr_get(buf, i)) + 1;

	if(len < MAPLIST_CVAR_MAXLEN)
	{
		string s = buf_implode(buf, " ");
		// buf_implode() writes the separator in front of every entry, including the first one
		cvar_set("g_maplist", substring(s, 1, -1));
		// Drop any file the list used to live in. It's shadowed by the cvar either way, but leaving
		// it behind means clearing g_maplist later resurrects a list the admin already edited away.
		MapList_Forget();
		return MAPLIST_SOURCE_CVAR;
	}

	// too long for a cvar: the file becomes the list, and g_maplist steps out of the way
	_MapList_WriteFile(buf, count);
	cvar_set("g_maplist", "");
	return MAPLIST_SOURCE_FILE;
}

void MapList_Forget()
{
	int fh = fopen(MAPLIST_FILE, FILE_READ);
	if(fh < 0)
		return; // nothing to forget
	fclose(fh);

	// there is no unlink builtin, so truncate it instead: an empty file reads back as "no list"
	fh = fopen(MAPLIST_FILE, FILE_WRITE);
	if(fh >= 0)
		fclose(fh);
}
