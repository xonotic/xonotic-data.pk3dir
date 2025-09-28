#include "mapinfo.qh"
#if defined(CSQC)
	#include <common/util.qh>
	#include <common/weapons/_all.qh>
#elif defined(MENUQC)
#elif defined(SVQC)
	#include <common/util.qh>
	#include <common/monsters/_mod.qh>
#endif

int autocvar_g_mapinfo_q3compat = 1;

#ifdef SVQC
	bool autocvar_g_mapinfo_ignore_warnings;
	#define WARN_COND (!autocvar_g_mapinfo_ignore_warnings && MapInfo_Map_bspname == mi_shortname)
#else
	#define WARN_COND false
#endif

vector _GametypeFlags_FromGametype(int a)
{
	if (REGISTRY_MAX(Gametypes) > 24)
		if (a >= 24)
		{
			a -= 24;
			if (REGISTRY_MAX(Gametypes) > 48)
				if (a >= 24)
				{
					a -= 24;
					return '0 0 1' * BIT(a);
				}
			return '0 1 0' * BIT(a);
		}
	return '1 0 0' * BIT(a);
}

// generic string stuff

int _MapInfo_Cache_Active;
int _MapInfo_Cache_DB_NameToIndex;
int _MapInfo_Cache_Buf_IndexToMapData;

void MapInfo_Cache_Destroy()
{
	if(!_MapInfo_Cache_Active)
		return;

	db_close(_MapInfo_Cache_DB_NameToIndex);
	buf_del(_MapInfo_Cache_Buf_IndexToMapData);
	_MapInfo_Cache_Active = 0;
}

void MapInfo_Cache_Create()
{
	MapInfo_Cache_Destroy();
	_MapInfo_Cache_DB_NameToIndex = db_create();
	_MapInfo_Cache_Buf_IndexToMapData = buf_create();
	_MapInfo_Cache_Active = 1;
}

void MapInfo_Cache_Invalidate()
{
	if(!_MapInfo_Cache_Active)
		return;

	MapInfo_Cache_Create();
}

void MapInfo_Cache_Store()
{
	float i;
	string s;
	if(!_MapInfo_Cache_Active)
		return;

	s = db_get(_MapInfo_Cache_DB_NameToIndex, MapInfo_Map_bspname);
	if(s == "")
	{
		i = buf_getsize(_MapInfo_Cache_Buf_IndexToMapData);
		db_put(_MapInfo_Cache_DB_NameToIndex, MapInfo_Map_bspname, ftos(i));
	}
	else
		i = stof(s);

	// now store all the stuff
	bufstr_set(_MapInfo_Cache_Buf_IndexToMapData,   i, MapInfo_Map_bspname);
	bufstr_set(_MapInfo_Cache_Buf_IndexToMapData, ++i, MapInfo_Map_title);
	bufstr_set(_MapInfo_Cache_Buf_IndexToMapData, ++i, MapInfo_Map_titlestring);
	bufstr_set(_MapInfo_Cache_Buf_IndexToMapData, ++i, MapInfo_Map_description);
	bufstr_set(_MapInfo_Cache_Buf_IndexToMapData, ++i, MapInfo_Map_author);
	bufstr_set(_MapInfo_Cache_Buf_IndexToMapData, ++i, vtos(MapInfo_Map_supportedGametypes));
	bufstr_set(_MapInfo_Cache_Buf_IndexToMapData, ++i, ftos(MapInfo_Map_supportedFeatures));
	bufstr_set(_MapInfo_Cache_Buf_IndexToMapData, ++i, ftos(MapInfo_Map_flags));
}

float MapInfo_Cache_Retrieve(string map)
{
	float i;
	string s;
	if(!_MapInfo_Cache_Active)
		return 0;

	s = db_get(_MapInfo_Cache_DB_NameToIndex, map);
	if(s == "")
		return 0;
	i = stof(s);

	// now retrieve all the stuff
	MapInfo_Map_bspname = bufstr_get(_MapInfo_Cache_Buf_IndexToMapData, i);
	MapInfo_Map_title = bufstr_get(_MapInfo_Cache_Buf_IndexToMapData, ++i);
	MapInfo_Map_titlestring = bufstr_get(_MapInfo_Cache_Buf_IndexToMapData, ++i);
	MapInfo_Map_description = bufstr_get(_MapInfo_Cache_Buf_IndexToMapData, ++i);
	MapInfo_Map_author = bufstr_get(_MapInfo_Cache_Buf_IndexToMapData, ++i);
	MapInfo_Map_supportedGametypes = stov(bufstr_get(_MapInfo_Cache_Buf_IndexToMapData, ++i));
	MapInfo_Map_supportedFeatures = stof(bufstr_get(_MapInfo_Cache_Buf_IndexToMapData, ++i));
	MapInfo_Map_flags = stof(bufstr_get(_MapInfo_Cache_Buf_IndexToMapData, ++i));

	return 1;
}

// GLOB HANDLING (for all BSP files)
float _MapInfo_globopen;
float _MapInfo_globcount;
float _MapInfo_globhandle;
string _MapInfo_GlobItem(float i)
{
	string s;
	if(!_MapInfo_globopen)
		return string_null;
	s = search_getfilename(_MapInfo_globhandle, i);
	return substring(s, 5, strlen(s) - 9); // without maps/ and .bsp
}

void MapInfo_Enumerate()
{
	if(_MapInfo_globopen)
	{
		search_end(_MapInfo_globhandle);
		_MapInfo_globopen = 0;
	}
	MapInfo_Cache_Invalidate();
	_MapInfo_globhandle = search_begin("maps/*.bsp", true, true);
	if(_MapInfo_globhandle >= 0)
	{
		_MapInfo_globcount = search_getsize(_MapInfo_globhandle);
		_MapInfo_globopen = 1;
	}
	else
		_MapInfo_globcount = 0;
}

// filter the info by gametype mask (updates MapInfo_count)
//
float _MapInfo_filtered;
float _MapInfo_filtered_allocated;
float MapInfo_FilterList_Lookup(float i)
{
	return stof(bufstr_get(_MapInfo_filtered, i));
}

void _MapInfo_FilterList_swap(float i, float j, entity pass)
{
	string h;
	h = bufstr_get(_MapInfo_filtered, i);
	bufstr_set(_MapInfo_filtered, i, bufstr_get(_MapInfo_filtered, j));
	bufstr_set(_MapInfo_filtered, j, h);
}

float _MapInfo_FilterList_cmp(float i, float j, entity pass)
{
	string a, b;
	a = _MapInfo_GlobItem(stof(bufstr_get(_MapInfo_filtered, i)));
	b = _MapInfo_GlobItem(stof(bufstr_get(_MapInfo_filtered, j)));
	return strcasecmp(a, b);
}

float MapInfo_FilterGametype(Gametype pGametype, int pFeatures, int pFlagsRequired, int pFlagsForbidden, bool pAbortOnGenerate)
{
	return _MapInfo_FilterGametype(pGametype.gametype_flags, pFeatures, pFlagsRequired, pFlagsForbidden, pAbortOnGenerate);
}
float _MapInfo_FilterGametype(vector pGametype, int pFeatures, int pFlagsRequired, int pFlagsForbidden, bool pAbortOnGenerate)
{
	float i, j;
	if (!_MapInfo_filtered_allocated)
	{
		_MapInfo_filtered_allocated = 1;
		_MapInfo_filtered = buf_create();
	}
	MapInfo_count = 0;
	for(i = 0, j = -1; i < _MapInfo_globcount; ++i)
	{
		if(MapInfo_Get_ByName(_MapInfo_GlobItem(i), 1, NULL) == 2) // if we generated one... BAIL OUT and let the caller continue in the next frame.
			if(pAbortOnGenerate)
			{
				LOG_TRACE("Autogenerated a .mapinfo, doing the rest later.");
				MapInfo_progress = i / _MapInfo_globcount;
				return 0;
			}
		if(MapInfo_Map_supportedGametypes & pGametype)
		if((MapInfo_Map_supportedFeatures & pFeatures) == pFeatures)
		if((MapInfo_Map_flags & pFlagsForbidden) == 0)
		if((MapInfo_Map_flags & pFlagsRequired) == pFlagsRequired)
			bufstr_set(_MapInfo_filtered, ++j, ftos(i));
	}
	MapInfo_count = j + 1;
	MapInfo_ClearTemps();

	// sometimes the glob isn't sorted nicely, so fix it here...
	heapsort(MapInfo_count, _MapInfo_FilterList_swap, _MapInfo_FilterList_cmp, NULL);

	return 1;
}
void MapInfo_FilterString(string sf)
{
	// this function further filters _MapInfo_filtered, which is prepared by MapInfo_FilterGametype by string
	float i, j;
	string title;

	for(i = 0, j = -1; i < MapInfo_count; ++i)
	{
		if (MapInfo_Get_ByID(i))
		{
			// prepare for keyword filter
			if (MapInfo_Map_title && strstrofs(MapInfo_Map_title, "<TITLE>", 0) == -1)
				title = MapInfo_Map_title;
			else
				title = MapInfo_Map_bspname;
			// keyword filter
			if((strstrofs(strtolower(title), strtolower(sf), 0)) >= 0)
				bufstr_set(_MapInfo_filtered, ++j, bufstr_get(_MapInfo_filtered, i));
		}
	}
	MapInfo_count = j + 1;
	MapInfo_ClearTemps();

	// sometimes the glob isn't sorted nicely, so fix it here...
	heapsort(MapInfo_count, _MapInfo_FilterList_swap, _MapInfo_FilterList_cmp, NULL);
}

void MapInfo_Filter_Free()
{
	if(_MapInfo_filtered_allocated)
	{
		buf_del(_MapInfo_filtered);
		_MapInfo_filtered_allocated = 0;
	}
}

// load info about the i-th map into the MapInfo_Map_* globals
string MapInfo_BSPName_ByID(float i)
{
	return _MapInfo_GlobItem(MapInfo_FilterList_Lookup(i));
}

string unquote(string s)
{
	float l = strlen(s);
	for(float i = 0; i < l; ++i)
	{
		string ch = substring(s, i, 1);
		if((ch != " ") && (ch != "\""))
		{
			for(float j = l - i - 1; j > 0; --j)
			{
				ch = substring(s, i+j, 1);
				if(ch != " ") if(ch != "\"")
					return substring(s, i, j+1);
			}
			return substring(s, i, 1);
		}
	}
	return "";
}

bool MapInfo_Get_ByID(int i)
{
	return MapInfo_Get_ByName(MapInfo_BSPName_ByID(i), 0, NULL) ? true : false;
}

string _MapInfo_Map_worldspawn_music;

float _MapInfo_Generate(string pFilename) // 0: failure, 1: ok ent, 2: ok bsp
{
	string fn;
	float fh;
	string s, k, v;
	vector o;
	float i;
	float inWorldspawn;
	float r;
	float diameter, spawnpoints;
	float spawnplaces;
	bool is_q3df_map = false;
	vector mapMins, mapMaxs;

	if(autocvar_g_mapinfo_q3compat >= 2) // generate mapinfo using arena data
	{
		// try for .arena or .defi files, as they may have more accurate information
		// supporting .arena AND .defi for the same map
		bool success = false;
		fh = -1;
		fn = _MapInfo_FindArenaFile(pFilename, ".arena");
		if(fn != "" && (fh = fopen(fn, FILE_READ)) >= 0)
		{
			success = _MapInfo_ParseArena(fn, fh, pFilename, NULL, false, true);
			fclose(fh);
		}
		fn = _MapInfo_FindArenaFile(pFilename, ".defi");
		if(fn != "" && (fh = fopen(fn, FILE_READ)) >= 0)
		{
			success |= _MapInfo_ParseArena(fn, fh, pFilename, NULL, true, true);
			fclose(fh);
		}
		if (success && autocvar_g_mapinfo_q3compat == 3)
			return 3; // skip entity analysis
	}

	r = 1;
	fn = strcat("maps/", pFilename, ".ent");
	fh = fopen(fn, FILE_READ);
	if(fh < 0)
	{
		r = 2;
		fn = strcat("maps/", pFilename, ".bsp");
		fh = fopen(fn, FILE_READ);
	}
	if(fh < 0)
		return 0;
	LOG_INFO("Generating ", pFilename, ".mapinfo: analyzing ", fn);

	inWorldspawn = 2;
	spawnpoints = 0;
	spawnplaces = 0;
	_MapInfo_Map_worldspawn_music = "";
	mapMins = '0 0 0';
	mapMaxs = '0 0 0';

	for (;;)
	{
		if (!((s = fgets(fh))))
			break;
		if(inWorldspawn == 1)
			if(startsWith(s, "}"))
				inWorldspawn = 0;
		k = unquote(car(s));
		v = unquote(cdr(s));
		if(inWorldspawn)
		{
			if(k == "classname" && v == "worldspawn")
				inWorldspawn = 1;
			else if(k == "author")
				MapInfo_Map_author = v;
			else if(k == "_description")
				MapInfo_Map_description = v;
			else if(k == "music")
				_MapInfo_Map_worldspawn_music = v;
			else if(k == "noise")
				_MapInfo_Map_worldspawn_music = v;
			else if(k == "message" && (!MapInfo_Map_title || MapInfo_Map_title == "<TITLE>") && v != "")
				MapInfo_Map_title = v;
		}
		else
		{
			if(k == "origin")
			{
				o = stov(strcat("'", v, "'"));
				mapMins.x = min(mapMins.x, o.x);
				mapMins.y = min(mapMins.y, o.y);
				mapMins.z = min(mapMins.z, o.z);
				mapMaxs.x = max(mapMaxs.x, o.x);
				mapMaxs.y = max(mapMaxs.y, o.y);
				mapMaxs.z = max(mapMaxs.z, o.z);
			}
			else if(k == "race_place")
			{
				if(stof(v) > 0)
					spawnplaces = 1;
			}
			else if(k == "classname")
			{
				if(v == "info_player_team1")
					++spawnpoints;
				else if(v == "info_player_team2")
					++spawnpoints;
				else if(v == "info_player_start")
					++spawnpoints;
				else if(v == "info_player_deathmatch")
					++spawnpoints;
				else if(v == "weapon_nex")
					{ }
				else if(v == "weapon_railgun")
					{ }
				else if(startsWith(v, "weapon_"))
					MapInfo_Map_supportedFeatures |= MAPINFO_FEATURE_WEAPONS;
				else if(startsWith(v, "turret_"))
					MapInfo_Map_supportedFeatures |= MAPINFO_FEATURE_TURRETS;
				else if(startsWith(v, "vehicle_"))
					MapInfo_Map_supportedFeatures |= MAPINFO_FEATURE_VEHICLES;
				else if(startsWith(v, "monster_"))
					MapInfo_Map_supportedFeatures |= MAPINFO_FEATURE_MONSTERS;
				else if(v == "target_music" || v == "trigger_music")
					_MapInfo_Map_worldspawn_music = string_null; // don't use regular BGM
				else if(v == "target_stopTimer")
					is_q3df_map = true; // don't support standard gametypes UNLESS we found them in .arena
				else
					FOREACH(Gametypes, true, it.m_generate_mapinfo(it, v));
			}
		}
	}
	if(inWorldspawn)
	{
		LOG_WARN(fn, " ended still in worldspawn, BUG");
		return 0;
	}
	diameter = vlen(mapMaxs - mapMins);

	vector twoBaseModes = '0 0 0';
	FOREACH(Gametypes, it.m_isTwoBaseMode(), twoBaseModes |= it.gametype_flags);
	if(twoBaseModes && (twoBaseModes &= MapInfo_Map_supportedGametypes))
	{
		// we have a symmetrical map, don't add the modes without bases
	}
	else if(!is_q3df_map)
	{
		FOREACH(Gametypes, it.m_isAlwaysSupported(it, spawnpoints, diameter), MapInfo_Map_supportedGametypes |= it.gametype_flags);
	}

	if(MapInfo_Map_supportedGametypes & MAPINFO_TYPE_RACE.gametype_flags)
	if(!spawnplaces)
	{
		MapInfo_Map_supportedGametypes &= ~MAPINFO_TYPE_RACE.gametype_flags;
		MapInfo_Map_supportedGametypes |= MAPINFO_TYPE_CTS.gametype_flags;
	}

	LOG_TRACE("-> diameter ",    ftos(diameter));
	LOG_TRACE(";  spawnpoints ", ftos(spawnpoints));
	LOG_TRACE(";  modes ",       vtos(MapInfo_Map_supportedGametypes));

	fclose(fh);

	return r;
}

void _MapInfo_Map_Reset()
{
	MapInfo_Map_title = "<TITLE>";
	MapInfo_Map_titlestring = "<TITLE>";
	MapInfo_Map_description = "<DESCRIPTION>";
	MapInfo_Map_author = "<AUTHOR>";
	MapInfo_Map_supportedGametypes = '0 0 0';
	MapInfo_Map_supportedFeatures = 0;
	MapInfo_Map_flags = 0;
	MapInfo_Map_clientstuff = "";
	MapInfo_Map_fog = "";
	MapInfo_Map_mins = '0 0 0';
	MapInfo_Map_maxs = '0 0 0';
}

string _MapInfo_GetDefault(Gametype t)
{
	return t.m_legacydefaults;
}

void _MapInfo_Map_ApplyGametype(string s, Gametype pWantedType, Gametype pThisType, int load_default)
{
	string sa;
	MapInfo_Map_supportedGametypes |= pThisType.gametype_flags;
	if(!(pThisType.gametype_flags & pWantedType.gametype_flags))
		return;

	if(load_default)
		_MapInfo_Map_ApplyGametype(_MapInfo_GetDefault(pThisType), pWantedType, pThisType, false);

	if(!pWantedType.frags) // these modes don't use fraglimit
	{
		cvar_set("fraglimit", "0");
	}
	else
	{
		sa = car(s);
		if(sa != "")
			cvar_set("fraglimit", sa);
		s = cdr(s);
	}

	sa = car(s);
	if(sa != "")
		cvar_set("timelimit", sa);
	s = cdr(s);

	if(pWantedType.m_setTeams)
	{
		sa = car(s);
		if(sa != "")
			pWantedType.m_setTeams(sa);
		s = cdr(s);
	}

	// rc = timelimit timelimit_qualification laps laps_teamplay
	if(pWantedType == MAPINFO_TYPE_RACE)
	{
		cvar_set("fraglimit", "0"); // special case!

		sa = car(s); if(sa == "") sa = cvar_string("timelimit");
		cvar_set("g_race_qualifying_timelimit", sa);
		s = cdr(s);

		sa = car(s);
		if(sa != "")
			if(cvar("g_race_teams") < 2)
				cvar_set("fraglimit", sa);
		s = cdr(s);

		sa = car(s);
		if(sa != "")
			if(cvar("g_race_teams") >= 2)
				cvar_set("fraglimit", sa);
		s = cdr(s);
	}

	if(!pWantedType.frags) // these modes don't use fraglimit
	{
		cvar_set("leadlimit", "0");
	}
	else
	{
		sa = car(s);
		if(sa != "")
			cvar_set("leadlimit", sa);
		s = cdr(s);
	}
}

string _MapInfo_GetDefaultEx(Gametype t)
{
	return t ? t.model2 : "";
}

float _MapInfo_GetTeamPlayBool(Gametype t)
{
	return t ? t.team : false;
}

void _MapInfo_Map_ApplyGametypeEx(string s, Gametype pWantedType, Gametype pThisType)
{
	MapInfo_Map_supportedGametypes |= pThisType.gametype_flags;
	if (!(pThisType.gametype_flags & pWantedType.gametype_flags))
		return;

	// reset all the cvars to their defaults

	cvar_set("timelimit", cvar_defstring("timelimit"));
	cvar_set("leadlimit", cvar_defstring("leadlimit"));
	cvar_set("fraglimit", cvar_defstring("fraglimit"));
	FOREACH(Gametypes, true, it.m_parse_mapinfo(string_null, string_null));

	string fraglimit_normal = string_null;
	string fraglimit_teams = string_null;

	for (s = strcat(_MapInfo_GetDefaultEx(pWantedType), " ", s); s != ""; s = cdr(s)) {
		string sa = car(s);
		if (sa == "") continue;
		int p = strstrofs(sa, "=", 0);
		if (p < 0) {
			if(WARN_COND)
				LOG_WARNF("Invalid gametype setting in mapinfo for gametype %s: %s", MapInfo_Type_ToString(pWantedType), sa);
			continue;
		}
		string k = substring(sa, 0, p);
		string v = substring(sa, p + 1, -1);
		bool handled = true;
		switch (k) {
			case "timelimit":
			{
				cvar_set("timelimit", v);
				break;
			}
			case "leadlimit":
			{
				cvar_set("leadlimit", v);
				break;
			}
			case "pointlimit":
			case "fraglimit":
			case "lives":
			case "laplimit":
			case "caplimit":
			{
				fraglimit_normal = v;
				break;
			}
			case "teampointlimit":
			case "teamlaplimit":
			{
				fraglimit_teams = v;
				break;
			}
			default:
			{
			    handled = false;
			    break;
			}
		}
		FOREACH(Gametypes, true, handled |= it.m_parse_mapinfo(k, v));
		if (!handled && WARN_COND)
            LOG_WARNF("Invalid gametype setting in mapinfo for gametype %s: %s", MapInfo_Type_ToString(pWantedType), sa);
	}

	if (pWantedType == MAPINFO_TYPE_RACE && cvar("g_race_teams") >= 2)
	{
		if(fraglimit_teams)
			cvar_set("fraglimit", fraglimit_teams);
	}
	else
	{
		if(fraglimit_normal)
			cvar_set("fraglimit", fraglimit_normal);
	}
}

Gametype MapInfo_Type_FromString(string gtype, bool dowarn, bool is_q3compat)
{
	string replacement = "";

	switch (gtype)
	{
		case "nexball":   replacement = "nb"; break;
		case "freezetag": replacement = "ft"; break;
		case "keepaway":  replacement = "ka"; break;
		case "invasion":  replacement = "inv"; break;
		case "assault":   replacement = "as"; break;
		case "race":      replacement = "rc"; break;
		// Q3/QL compat, see DoesQ3ARemoveThisEntity() in quake3.qc for complete lists
		case "ffa":       replacement = "dm"; break;
		case "cctf": // from ThreeWave, maps with this should all have "ctf" too
		case "oneflag":   replacement = "ctf"; break;
		case "tourney":   replacement = "duel"; break;
		case "arena": // which Q3 mod is this from? In Nexuiz it was 'duel with rounds'.
			if(is_q3compat) { replacement = "ca"; } break;
	}
	if (replacement != "")
	{
		if (dowarn && WARN_COND)
			LOG_WARNF("MapInfo_Type_FromString (probably %s): using deprecated name '%s'. Should use '%s'.", MapInfo_Map_bspname, gtype, replacement);
		gtype = replacement;
	}
	FOREACH(Gametypes, it.mdl == gtype, return it);
	return NULL;
}

string MapInfo_Type_Description(Gametype t)
{
	return t ? t.m_description : "";
}

string MapInfo_Type_ToString(Gametype t)
{
	return t ? t.mdl : "";
}

string MapInfo_Type_ToText(Gametype t)
{
	/* xgettext:no-c-format */
	return t ? t.message : _("@!#%'n Tuba Throwing");
}

void _MapInfo_Parse_Settemp(string pFilename, string acl, float type, string s, float recurse)
{
	string t;
	float o;
	// tabs are invalid, treat them as "empty"
	s = strreplace("\t", "", s);

	t = car(s); s = cdr(s);

	// limited support of "" and comments
	//   remove trailing and leading " of t
	if(substring(t, 0, 1) == "\"")
	{
		if(substring(t, -1, 1) == "\"")
			t = substring(t, 1, -2);
	}

	//   remove leading " of s
	if(substring(s, 0, 1) == "\"")
	{
		s = substring(s, 1, -1);
	}
	//   remove trailing " of s, and all that follows (cvar description)
	o = strstrofs(s, "\"", 0);
	if(o >= 0)
		s = substring(s, 0, o);

	//   remove // comments
	o = strstrofs(s, "//", 0);
	if(o >= 0)
		s = substring(s, 0, o);

	//   remove trailing spaces
	while(substring(s, -1, 1) == " ")
		s = substring(s, 0, -2);

	if(t == "#include")
	{
		if(recurse > 0)
		{
			float fh = fopen(s, FILE_READ);
			if(fh < 0)
			{
				if(WARN_COND)
					LOG_WARN("Map ", pFilename, " references not existing config file ", s);
			}
			else
			{
				while((s = fgets(fh)))
				{
					s = strreplace("\t", "", s); // treat tabs as "empty", perform here first to ensure coments are detected
					// catch different sorts of comments
					if(s == "")                    // empty lines
						continue;
					if(substring(s, 0, 1) == "#")  // UNIX style
						continue;
					if(substring(s, 0, 2) == "//") // C++ style
						continue;
					if(substring(s, 0, 1) == "_")  // q3map style
						continue;

					if(substring(s, 0, 4) == "set ")
						s = substring(s, 4, -1);
					if(substring(s, 0, 5) == "seta ")
						s = substring(s, 5, -1);

					_MapInfo_Parse_Settemp(pFilename, acl, type, s, recurse - 1);
				}
				fclose(fh);
			}
		}
		else if(WARN_COND)
			LOG_WARN("Map ", pFilename, " uses too many levels of inclusion");
	}
	else if(t == ""
		|| !cvar_value_issafe(t)
		|| !cvar_value_issafe(s)
		|| matchacl(MAPINFO_SETTEMP_ACL_SYSTEM, t) <= 0)
	{
		if (WARN_COND)
			LOG_WARN("Map ", pFilename, " contains a potentially harmful setting, ignored");
	}
	else if(matchacl(acl, t) <= 0)
	{
		if (WARN_COND)
			LOG_WARN("Map ", pFilename, " contains a denied setting, ignored");
	}
	else
	{
		if(type == 0) // server set
		{
			LOG_TRACE("Applying temporary setting ", t, " := ", s);
		#if 0
			if(cvar("g_campaign"))
				cvar_set(t, s); // this is a wrapper and is always temporary anyway; no need to backup old values then
			else
		#endif
				cvar_settemp(t, s);
		}
		else
		{
			LOG_TRACE("Applying temporary client setting ", t, " := ", s);
			MapInfo_Map_clientstuff = strcat(
					MapInfo_Map_clientstuff, "cl_cmd settemp \"", t, "\" \"", s, "\"\n"
					);
		}
	}
}

/// Removes author string from title (if found)
/// and copies it to MapInfo_Map_author if that wasn't set.
string MapInfo_title_sans_author(string title)
{
	int offset;

	if ((offset = strstrofs(title, " by ", 0)) >= 0)
	{
		if (MapInfo_Map_author == "<AUTHOR>")
			MapInfo_Map_author = substring(title, offset + 4, strlen(title) - (offset + 4));
		title = substring(title, 0, offset);
	}
	else if ((offset = strstrofs(title, " (by ", 0)) >= 0 || (offset = strstrofs(title, " [by ", 0)) >= 0)
	{
		if (MapInfo_Map_author == "<AUTHOR>")
			MapInfo_Map_author = substring(title, offset + 5, strlen(title) - (offset + 5) - 1);
		title = substring(title, 0, offset);
	}
	else if ((offset = strstrofs(title, "Made By ", 0)) >= 0) // often at the start of the string
	{
		if (MapInfo_Map_author == "<AUTHOR>")
			MapInfo_Map_author = substring(title, offset + 8, strlen(title) - (offset + 8));
		title = substring(title, 0, offset);
	}

	return title != "" ? title : "<TITLE>";
}

bool MapInfo_isRedundant(string fn, string t)
{
	// normalize file name
	fn = strreplace("_", "", fn);
	fn = strreplace("-", "", fn);

	// normalize visible title
	t = strreplace(":", "", t);
	t = strreplace(" ", "", t);
	t = strreplace("_", "", t);
	t = strreplace("-", "", t);
	t = strreplace("'", "", t);
	t = strdecolorize(t);

	// we allow the visible title to have punctuation the file name does
	// not, but not vice versa
	if(!strcasecmp(fn, t))
		return true;

	return false;
}

bool _MapInfo_ParseArena(string arena_filename, int fh, string pFilename, Gametype pGametypeToSet, bool isdefi, bool isgenerator)
{
	// NOTE: .arena files can hold more than 1 map's information!
	// to handle this, we're going to store gathered information in local variables and save it if we encounter the correct map name
	bool in_brackets = false; // testing a potential mapinfo section (within brackets)
	bool dosave = false;
	string stored_Map_description = "";
	string stored_Map_title = "";
	string stored_Map_author = "";
	vector stored_supportedGametypes = '0 0 0';
	int stored_supportedFeatures = 0;
	int stored_flags = 0;
	string t, s;

	if (isgenerator)
		LOG_INFO("Generating ", pFilename, ".mapinfo: analyzing ", arena_filename);

	for (;;)
	{
		if (!((s = fgets(fh))))
			break;

		// catch different sorts of comments
		if(s == "")                    // empty lines
			continue;
		if(substring(s, 0, 2) == "//") // C++ style
			continue;
		if(strstrofs(s, "{", 0) >= 0)
		{
			if(in_brackets)
				return false; // edge case? already in a bracketed section!
			in_brackets = true;
			continue;
		}
		else if(!in_brackets)
		{
			// if we're not inside a bracket, don't process map info
			continue;
		}
		if(strstrofs(s, "}", 0) >= 0)
		{
			if(!in_brackets)
				return false; // no starting bracket! let the mapinfo generation system handle it
			in_brackets = false;
			if(dosave)
			{
				MapInfo_Map_description = stored_Map_description;
				if(stored_Map_title != "")
					MapInfo_Map_title = stored_Map_title;
				if(stored_Map_author != "") // write the usual "<AUTHOR>" if we have nothing better
					MapInfo_Map_author = stored_Map_author;
				// might have .arena AND .defi for the same map so these bitfields are OR'd
				if(isgenerator)
					MapInfo_Map_supportedGametypes |= stored_supportedGametypes;
				else
				{
					FOREACH(Gametypes, it.gametype_flags & stored_supportedGametypes,
					{
						_MapInfo_Map_ApplyGametype ("", pGametypeToSet, it, true);
					});
				}
				MapInfo_Map_supportedFeatures |= stored_supportedFeatures;
				MapInfo_Map_flags |= stored_flags;
				return true; // no need to continue through the file, we have our map!
			}
			else
			{
				// discard any gathered locals, we're not using the correct map!
				stored_Map_description = "";
				stored_Map_title = "";
				stored_Map_author = "";
				stored_supportedGametypes = '0 0 0';
				stored_supportedFeatures = 0;
				stored_flags = 0;
				continue;
			}
		}

		s = strreplace("\t", " ", s);

		float p = strstrofs(s, "//", 0);
		if(p >= 0)
			s = substring(s, 0, p);

		// perform an initial trim to ensure the first argument is properly obtained
		//   remove leading spaces
		while(substring(s, 0, 1) == " ")
			s = substring(s, 1, -1);

		t = car(s); s = cdr(s);
		t = strtolower(t); // apparently some q3 maps use capitalized parameters

		//   remove trailing spaces
		while(substring(t, -1, 1) == " ")
			t = substring(t, 0, -2);

		//   remove trailing spaces
		while(substring(s, -1, 1) == " ")
			s = substring(s, 0, -2);
		//   remove leading spaces
		while(substring(s, 0, 1) == " ")
			s = substring(s, 1, -1);
		// limited support of ""
		//   remove trailing and leading " of s
		if(substring(s, 0, 1) == "\"")
		{
			if(substring(s, -1, 1) == "\"")
				s = substring(s, 1, -2);
		}
		if(t == "longname")
			stored_Map_title = s;
		else if(t == "author")
			stored_Map_author = s;
		else if(t == "type")
		{
			// if there is a valid gametype in this .arena file, include it in the menu
			stored_supportedFeatures |= MAPINFO_FEATURE_WEAPONS;
			// type in quake 3 holds all the supported gametypes, so we must loop through all of them
			// TODO: handle support here better to include more Xonotic teamplay modes
			string types = s;
			types = strreplace("team", "tdm ft", types);
			types = strreplace("ffa", "dm lms ka", types);
			types = strreplace("tourney", "duel", types); // QL used duel so the following check must support it
			if(strstrofs(types, "duel", 0) < 0 && strstrofs(types, "tdm", 0) >= 0) // larger team map, support additional gametypes!
				types = cons(types, "ca kh");
			FOREACH_WORD(types, true,
			{
				Gametype f = MapInfo_Type_FromString(it, false, true);
				if(f)
					stored_supportedGametypes |= f.gametype_flags;
			});
		}
		else if(t == "style" && isdefi)
		{
			// we have a defrag map on our hands, add CTS!
			// TODO: styles
			stored_supportedGametypes |= MAPINFO_TYPE_CTS.gametype_flags;
		}
		else if(t == "map")
		{
			if(strtolower(s) == strtolower(pFilename))
				dosave = true; // yay, found our map!
		}
		else if(t == "quote")
			stored_Map_description = s;
		// TODO: fraglimit
	}

	// if the map wasn't found in the .arena, fall back to generated .mapinfo
	return false;
}

string _MapInfo_CheckArenaFile(string pFilename, string pMapname)
{
	// returns the file name if valid, otherwise returns ""
	// a string is returned to optimise the use cases where a filename is also returned
	int fh = fopen(pFilename, FILE_READ);
	if(fh < 0)
		return "";
	for(string s; (s = fgets(fh)); )
	{
		s = strreplace("\t", "", s);
		while(substring(s, 0, 1) == " ")
			s = substring(s, 1, -1);
		if(substring(s, 0, 2) == "//")
			continue;
		if(s == "")
			continue;
		int offset = strstrofs(s, "map", 0);
		if(offset >= 0)
		{
			if(strstrofs(strtolower(s), strcat("\"", strtolower(pMapname), "\""), offset) >= 0) // quake 3 is case insensitive
			{
				fclose(fh);
				return pFilename; // FOUND IT!
			}
		}
	}
	fclose(fh);
	return ""; // file did not contain a "map" field matching our map name
}

string _MapInfo_FindArenaFile(string pFilename, string extension)
{
	// A valid arena file with the "default" name may have been created as a map-specific
	// override of an arena file with a different name (possibly multi-map) in the pk3
	// (occasionally in the wild such file exists in the pk3 but isn't valid for a map in the pk3).
	// Therefore we try the "default" name first.
	string afile = _MapInfo_CheckArenaFile(strcat("scripts/", pFilename, extension), pFilename);
	if (afile != ""
	|| !checkextension("DP_QC_FS_SEARCH_PACKFILE"))
		return afile;

	string base_pack = whichpack(strcat("maps/", pFilename, ".bsp"));
	if(base_pack == "") // this map isn't packaged!
		return "";
	int glob = search_packfile_begin(strcat("scripts/*", extension), true, true, base_pack);
	if(glob < 0) // there's no matching file in the pack
		return "";
	int n = search_getsize(glob);
	for(int j = 0; j < n; ++j)
	{
		afile = search_getfilename(glob, j);
		if(_MapInfo_CheckArenaFile(afile, pFilename) != "")
		{
			search_end(glob);
			return afile;
		}
	}
	search_end(glob);

	return ""; // if we get here, a valid .arena file could not be found
}

// load info about a map by name into the MapInfo_Map_* globals
float MapInfo_Get_ByName_NoFallbacks(string pFilename, int pAllowGenerate, Gametype pGametypeToSet)
{
	string fn;
	string s, t;
	float fh;
	int f, i;
	float r, n;
	string acl;

	acl = MAPINFO_SETTEMP_ACL_USER;

	if(strstrofs(pFilename, "/", 0) >= 0)
	{
		LOG_WARN("Invalid character in map name, ignored");
		return 0;
	}

	if(pGametypeToSet == NULL)
		if(MapInfo_Cache_Retrieve(pFilename))
			return 1;

	r = 1;

	MapInfo_Map_bspname = pFilename;

	// default all generic fields so they have "good" values in case something fails
	fn = strcat("maps/", pFilename, ".mapinfo");
	fh = fopen(fn, FILE_READ);
	if(fh < 0)
	{
		if(autocvar_g_mapinfo_q3compat == 1) // use arena data instead of generating a mapinfo file
		{
			// supporting .arena AND .defi for the same map
			bool success = false;
			fn = _MapInfo_FindArenaFile(pFilename, ".arena");
			if(fn != "" && (fh = fopen(fn, FILE_READ)) >= 0)
			{
				_MapInfo_Map_Reset();
				success = _MapInfo_ParseArena(fn, fh, pFilename, pGametypeToSet, false, false);
				fclose(fh);
			}
			fn = _MapInfo_FindArenaFile(pFilename, ".defi");
			if(fn != "" && (fh = fopen(fn, FILE_READ)) >= 0)
			{
				if(!success)
					_MapInfo_Map_Reset();
				success |= _MapInfo_ParseArena(fn, fh, pFilename, pGametypeToSet, true, false);
				fclose(fh);
			}
			if(success)
				goto mapinfo_handled; // skip generation
		}

		fn = strcat("maps/autogenerated/", pFilename, ".mapinfo");
		fh = fopen(fn, FILE_READ);
		if(fh < 0)
		{
			if(!pAllowGenerate)
				return 0;
			_MapInfo_Map_Reset();
			r = _MapInfo_Generate(pFilename);
			if(!r)
				return 0;
			MapInfo_Map_title = MapInfo_title_sans_author(MapInfo_Map_title);
			fh = fopen(fn, FILE_WRITE);
			fputs(fh, strcat("title ", MapInfo_Map_title, "\n"));
			fputs(fh, strcat("description ", MapInfo_Map_description, "\n"));
			fputs(fh, strcat("author ", MapInfo_Map_author, "\n"));
			if(_MapInfo_Map_worldspawn_music != "")
			{
				if(strcasecmp(substring(_MapInfo_Map_worldspawn_music, -4, 4), ".wav") == 0 || strcasecmp(substring(_MapInfo_Map_worldspawn_music, -4, 4), ".ogg") == 0)
					fputs(fh, strcat("cdtrack ", substring(_MapInfo_Map_worldspawn_music, 0, -4), "\n"));
				else
					fputs(fh, strcat("cdtrack ", _MapInfo_Map_worldspawn_music, "\n"));
			}
			else
			{
				n = tokenize_console(cvar_string("g_cdtracks_remaplist"));
				s = strcat(" ", cvar_string("g_cdtracks_dontusebydefault"), " ");
				for (;;)
				{
					i = floor(random() * n);
					if(strstrofs(s, strcat(" ", argv(i), " "), 0) < 0)
						break;
				}
				fputs(fh, strcat("cdtrack ", ftos(i + 1), "\n"));
			}
			if(MapInfo_Map_supportedFeatures & MAPINFO_FEATURE_WEAPONS)
				fputs(fh, "has weapons\n");
			else
				fputs(fh, "// uncomment this if you added weapon pickups: has weapons\n");
			if(MapInfo_Map_supportedFeatures & MAPINFO_FEATURE_TURRETS)
				fputs(fh, "has turrets\n");
			else
				fputs(fh, "// uncomment this if you added turrets: has turrets\n");
			if(MapInfo_Map_supportedFeatures & MAPINFO_FEATURE_VEHICLES)
				fputs(fh, "has vehicles\n");
			else
				fputs(fh, "// uncomment this if you added vehicles: has vehicles\n");
			if(MapInfo_Map_flags & MAPINFO_FLAG_FRUSTRATING)
				fputs(fh, "frustrating\n");

			FOREACH(Gametypes, MapInfo_Map_supportedGametypes & it.gametype_flags, {
				fputs(fh, sprintf("gametype %s // defaults: %s\n", MapInfo_Type_ToString(it), _MapInfo_GetDefaultEx(it)));
			});

			fputs(fh, "// optional: fog density red green blue alpha mindist maxdist\n");
			fputs(fh, "// optional: settemp_for_type (all|gametypename) cvarname value\n");
			fputs(fh, "// optional: clientsettemp_for_type (all|gametypename) cvarname value\n");
			fputs(fh, "// optional: size mins_x mins_y mins_z maxs_x maxs_y maxs_z\n");
			fputs(fh, "// optional: hidden\n");

			fclose(fh);
			r = 2;
			// return r;
			fh = fopen(fn, FILE_READ);
			if(fh < 0)
				error("... but I just wrote it!");
		}

		if(WARN_COND)
			LOG_WARN("autogenerated mapinfo file ", fn, " has been loaded; please edit that file and move it to maps/", pFilename, ".mapinfo");
	}

	_MapInfo_Map_Reset();
	for (;;)
	{
		if (!((s = fgets(fh))))
			break;

		// catch different sorts of comments
		if(s == "")                    // empty lines
			continue;
		if(substring(s, 0, 1) == "#")  // UNIX style
			continue;
		if(substring(s, 0, 2) == "//") // C++ style
			continue;
		if(substring(s, 0, 1) == "_")  // q3map style
			continue;

		float p = strstrofs(s, "//", 0);
		if(p >= 0)
			s = substring(s, 0, p);

		t = car(s); s = cdr(s);
		if(t == "title")
			MapInfo_Map_title = s;
		else if(t == "description")
			MapInfo_Map_description = s;
		else if(t == "author")
			MapInfo_Map_author = s;
		else if(t == "has")
		{
			t = car(s); // s = cdr(s);
			if     (t == "weapons") MapInfo_Map_supportedFeatures |= MAPINFO_FEATURE_WEAPONS;
			else if(t == "turrets") MapInfo_Map_supportedFeatures |= MAPINFO_FEATURE_TURRETS;
			else if(t == "vehicles") MapInfo_Map_supportedFeatures |= MAPINFO_FEATURE_VEHICLES;
			else if(t == "monsters") MapInfo_Map_supportedFeatures |= MAPINFO_FEATURE_MONSTERS;
			else if(t == "new_toys") MapInfo_Map_supportedFeatures |= MAPINFO_FEATURE_WEAPONS;
			else if(WARN_COND)
				LOG_WARN("Map ", pFilename, " supports unknown feature ", t, ", ignored");
		}
		else if(t == "hidden")
		{
			MapInfo_Map_flags |= MAPINFO_FLAG_HIDDEN;
		}
		else if(t == "forbidden")
		{
			MapInfo_Map_flags |= MAPINFO_FLAG_FORBIDDEN;
		}
		else if(t == "frustrating")
		{
			MapInfo_Map_flags |= MAPINFO_FLAG_FRUSTRATING;
		}
		else if(t == "donotwant" || t == "noautomaplist")
		{
			MapInfo_Map_flags |= MAPINFO_FLAG_DONOTWANT;
		}
		else if(t == "gameversion_min")
		{
			if (cvar("gameversion") < stof(s))
				MapInfo_Map_flags |= MAPINFO_FLAG_DONOTWANT;
		}
		else if(t == "type")
		{
			t = car(s); s = cdr(s);
			Gametype f = MapInfo_Type_FromString(t, true, false);
			//if(WARN_COND)
				//LOG_WARN("Map ", pFilename, " contains the legacy 'type' keyword which is deprecated and will be removed in the future. Please migrate the mapinfo file to 'gametype'.");
			if(f)
				_MapInfo_Map_ApplyGametype (s, pGametypeToSet, f, true);
			else if(WARN_COND)
				LOG_DEBUG("Map ", pFilename, " supports unknown gametype ", t, ", ignored");
		}
		else if(t == "gametype")
		{
			t = car(s); s = cdr(s);
			Gametype f = MapInfo_Type_FromString(t, true, false);
			if(f)
				_MapInfo_Map_ApplyGametypeEx (s, pGametypeToSet, f);
			else if(WARN_COND)
				LOG_DEBUG("Map ", pFilename, " supports unknown gametype ", t, ", ignored");
		}
		else if(t == "size")
		{
			float a, b, c, d, e;
			t = car(s); s = cdr(s); a = stof(t);
			t = car(s); s = cdr(s); b = stof(t);
			t = car(s); s = cdr(s); c = stof(t);
			t = car(s); s = cdr(s); d = stof(t);
			t = car(s); s = cdr(s); e = stof(t);
			if(s == "")
			{
				if(WARN_COND)
					LOG_WARN("Map ", pFilename, " contains an incorrect size line (not enough params), syntax: size mins_x mins_y mins_z maxs_x maxs_y maxs_z");
			}
			else
			{
				t = car(s); s = cdr(s); f = stof(t);
				if(s != "")
				{
					if(WARN_COND)
						LOG_WARN("Map ", pFilename, " contains an incorrect size line (too many params), syntax: size mins_x mins_y mins_z maxs_x maxs_y maxs_z");
				}
				else
				{
					if(a >= d || b >= e || c >= f)
					{
						if(WARN_COND)
							LOG_WARN("Map ", pFilename, " contains an incorrect size line, mins have to be < maxs");
					}
					else
					{
						MapInfo_Map_mins.x = a;
						MapInfo_Map_mins.y = b;
						MapInfo_Map_mins.z = c;
						MapInfo_Map_maxs.x = d;
						MapInfo_Map_maxs.y = e;
						MapInfo_Map_maxs.z = f;
					}
				}
			}
		}
		else if(t == "settemp_for_type")
		{
			t = car(s); s = cdr(s);
			bool all = t == "all";
			Gametype f = NULL;
			if(all || (f = MapInfo_Type_FromString(t, true, false)))
			{
				if((all ? MAPINFO_TYPE_ALL : f.gametype_flags) & pGametypeToSet.gametype_flags)
				{
					_MapInfo_Parse_Settemp(pFilename, acl, 0, s, 1);
				}
			}
			else
			{
				LOG_DEBUG("Map ", pFilename, " has a setting for unknown gametype ", t, ", ignored");
			}
		}
		else if(t == "clientsettemp_for_type")
		{
			t = car(s); s = cdr(s);
			bool all = t == "all";
			Gametype f = NULL;
			if(all || (f = MapInfo_Type_FromString(t, true, false)))
			{
				if((all ? MAPINFO_TYPE_ALL : f.gametype_flags) & pGametypeToSet.gametype_flags)
				{
					_MapInfo_Parse_Settemp(pFilename, acl, 1, s, 1);
				}
			}
			else
			{
				LOG_DEBUG("Map ", pFilename, " has a client setting for unknown gametype ", t, ", ignored");
			}
		}
		else if(t == "fog")
		{
			if (!cvar_value_issafe(s))
			{
				if(WARN_COND)
					LOG_WARN("Map ", pFilename, " contains a potentially harmful fog setting, ignored");
			}
			else
				MapInfo_Map_fog = s;
		}
		else if(t == "cdtrack")
		{
			t = car(s); s = cdr(s);
			// We do this only if pGametypeToSet even though this
			// content is theoretically gametype independent,
			// because MapInfo_Map_clientstuff contains otherwise
			// gametype dependent stuff. That way this value stays
			// empty when not setting a gametype to not set any
			// false expectations.
			if(pGametypeToSet)
			{
				if (!cvar_value_issafe(t))
				{
					if(WARN_COND)
						LOG_WARN("Map ", pFilename, " contains a potentially harmful cdtrack, ignored");
				}
				else
					MapInfo_Map_clientstuff = strcat(
						MapInfo_Map_clientstuff, "cd loop \"", t, "\"\n"
					);
			}
		}
		else if(WARN_COND)
			LOG_WARN("Map ", pFilename, " provides unknown info item ", t, ", ignored");
	}
	fclose(fh);

LABEL(mapinfo_handled)
#ifdef SVQC
	// if the map is currently loaded we can read worldspawn fields directly
	if (pFilename == mi_shortname)
	{
		if (MapInfo_Map_title == "<TITLE>")
			if (world.message != "")
				MapInfo_Map_title = world.message;
		if (MapInfo_Map_author == "<AUTHOR>")
			if ((s = GetField_fullspawndata(world, "author", false)) != "")
				MapInfo_Map_author = s;
	}
#endif
	// Could skip removing author from title when it's source is .mapinfo
	// but must always do it for world.message and .arena/.defi as VQ3 didn't support author
	// so mappers tended to put it in world.message and/or longname.
	MapInfo_Map_title = MapInfo_title_sans_author(MapInfo_Map_title); // may set author if not set

	if(MapInfo_Map_title == "<TITLE>")
		MapInfo_Map_titlestring = strcat("^2", MapInfo_Map_bspname);
	else if(MapInfo_isRedundant(MapInfo_Map_bspname, MapInfo_Map_title))
		MapInfo_Map_titlestring = strcat("^2", MapInfo_Map_title);
	else
		MapInfo_Map_titlestring = sprintf("^2%s ^7// ^2%s", MapInfo_Map_bspname, MapInfo_Map_title);

	if (MapInfo_Map_author == "<AUTHOR>")
		MapInfo_Map_author = ""; // don't display "<AUTHOR>" in the UI (we do write it to .mapinfo files)

	MapInfo_Cache_Store();
	if(MapInfo_Map_supportedGametypes != '0 0 0')
		return r;
	if (WARN_COND)
		LOG_WARN("Map ", pFilename, " supports no gametypes, ignored");
	return 0;
}
int MapInfo_Get_ByName(string pFilename, float pAllowGenerate, Gametype pGametypeToSet)
{
	int r = MapInfo_Get_ByName_NoFallbacks(pFilename, pAllowGenerate, pGametypeToSet);

	FOREACH(Gametypes, it.m_isForcedSupported(it), _MapInfo_Map_ApplyGametypeEx("", pGametypeToSet, it));

	if(pGametypeToSet)
	{
		if(!(MapInfo_Map_supportedGametypes & pGametypeToSet.gametype_flags))
		{
			error("Can't select the requested gametype. This should never happen as the caller should prevent it!\n");
			//_MapInfo_Map_ApplyGametypeEx("", pGametypeToSet, MAPINFO_TYPE_DEATHMATCH);
			//return;
		}
	}

	return r;
}

bool MapReadSizes(string map)
{
	// TODO: implement xonotic#28 / xonvote 172 (sizes in mapinfo)
	string readsize_msg = strcat("MapReadSizes ", map);
	float fh = fopen(strcat("maps/", map, ".sizes"), FILE_READ);
	if(fh >= 0)
	{
		map_minplayers = stoi(fgets(fh));
		map_maxplayers = stoi(fgets(fh));
		fclose(fh);
		LOG_TRACEF(readsize_msg, ": ok, min %d max %d", map_minplayers, map_maxplayers);
		return true;
	}
	LOG_TRACE(readsize_msg, ": not found");
	return false;
}

float MapInfo_FindName(string s)
{
	// if there is exactly one map of prefix s, return it
	// if not, return the null string
	// note that DP sorts glob results... so I can use a binary search
	float l, r, m, cmp;
	l = 0;
	r = MapInfo_count;
	// invariants: r is behind s, l-1 is equal or before
	while(l != r)
	{
		m = floor((l + r) / 2);
		MapInfo_FindName_match = _MapInfo_GlobItem(MapInfo_FilterList_Lookup(m));
		cmp = strcasecmp(MapInfo_FindName_match, s);
		if(cmp == 0)
			return m; // found and good
		if(cmp < 0)
			l = m + 1; // l-1 is before s
		else
			r = m; // behind s
	}
	MapInfo_FindName_match = _MapInfo_GlobItem(MapInfo_FilterList_Lookup(l));
	MapInfo_FindName_firstResult = l;
	// r == l, so: l is behind s, l-1 is before
	// SO: if there is any, l is the one with the right prefix
	//     and l+1 may be one too
	if(l == MapInfo_count)
	{
		MapInfo_FindName_match = string_null;
		MapInfo_FindName_firstResult = -1;
		return -1; // no MapInfo_FindName_match, behind last item
	}
	if(!startsWithNocase(MapInfo_FindName_match, s))
	{
		MapInfo_FindName_match = string_null;
		MapInfo_FindName_firstResult = -1;
		return -1; // wrong prefix
	}
	if(l == MapInfo_count - 1)
		return l; // last one, nothing can follow => unique
	if(startsWithNocase(_MapInfo_GlobItem(MapInfo_FilterList_Lookup(l + 1)), s))
	{
		MapInfo_FindName_match = string_null;
		return -1; // ambigous MapInfo_FindName_match
	}
	return l;
}

string MapInfo_FixName(string s)
{
	MapInfo_FindName(s);
	return MapInfo_FindName_match;
}

int MapInfo_CurrentFeatures()
{
	int req = 0;
    // TODO: find a better way to check if weapons are required on the map
	if(!(cvar("g_instagib") || cvar("g_overkill") || cvar("g_nix") || cvar("g_weaponarena") || !cvar("g_pickup_items") || !cvar("g_melee_only") 
		|| cvar("g_race") || cvar("g_cts") || cvar("g_nexball") || cvar("g_ca") || cvar("g_freezetag") || cvar("g_lms")))
		req |= MAPINFO_FEATURE_WEAPONS;
	return req;
}

Gametype MapInfo_CurrentGametype()
{
	Gametype prev = MapInfo_Type_FromString(cvar_string("gamecfg"), false, false);
	FOREACH(Gametypes, cvar(it.netname) && it != prev, return it);
	return prev ? prev : MAPINFO_TYPE_DEATHMATCH;
}

float _MapInfo_CheckMap(string s, bool gametype_only) // returns 0 if the map can't be played with the current settings, 1 otherwise
{
	if(!MapInfo_Get_ByName(s, 1, NULL))
		return 0;
	if(!(MapInfo_Map_supportedGametypes & MapInfo_CurrentGametype().gametype_flags))
		return 0;
	if (gametype_only)
		return 1;
	if((MapInfo_Map_supportedFeatures & MapInfo_CurrentFeatures()) != MapInfo_CurrentFeatures())
		return 0;
	return 1;
}

float MapInfo_CheckMap(string s) // returns 0 if the map can't be played with the current settings, 1 otherwise
{
	float r;
	r = _MapInfo_CheckMap(s, false);
	MapInfo_ClearTemps();
	return r;
}

void MapInfo_SwitchGameType(Gametype t)
{
	FOREACH(Gametypes, true, cvar_set(it.netname, (it == t) ? "1" : "0"));
}

void MapInfo_LoadMap(string s, float reinit)
{
	MapInfo_Map_supportedGametypes = '0 0 0';
	// we shouldn't need this, as LoadMapSettings already fixes the gametype
	//if(!MapInfo_CheckMap(s))
	//{
	//	print("EMERGENCY: can't play the selected map in the given gametype. Falling back to DM.\n");
	//	MapInfo_SwitchGameType(MAPINFO_TYPE_DEATHMATCH.gametype_flags);
	//}

	LOG_INFO("Switching to map ", s);

	cvar_settemp_restore();
	if(reinit)
		localcmd(strcat("\nmap ", s, "\n"));
	else
		localcmd(strcat("\nchangelevel ", s, "\n"));
}

string MapInfo_ListAllowedMaps(Gametype type, float pRequiredFlags, float pForbiddenFlags)
{
	string out;

	// to make absolutely sure:
	MapInfo_Enumerate();
	MapInfo_FilterGametype(type, MapInfo_CurrentFeatures(), pRequiredFlags, pForbiddenFlags, 0);

	out = "";
	for(float i = 0; i < MapInfo_count; ++i)
		out = strcat(out, " ", _MapInfo_GlobItem(MapInfo_FilterList_Lookup(i)));
	return substring(out, 1, strlen(out) - 1);
}

string MapInfo_ListAllAllowedMaps(float pRequiredFlags, float pForbiddenFlags)
{
	string out;

	// to make absolutely sure:
	MapInfo_Enumerate();
	_MapInfo_FilterGametype(MAPINFO_TYPE_ALL, 0, pRequiredFlags, pForbiddenFlags, 0);

	out = "";
	for(float i = 0; i < MapInfo_count; ++i)
		out = strcat(out, " ", _MapInfo_GlobItem(MapInfo_FilterList_Lookup(i)));

	MapInfo_FilterGametype(MapInfo_CurrentGametype(), MapInfo_CurrentFeatures(), pRequiredFlags, pForbiddenFlags, 0);

	return substring(out, 1, strlen(out) - 1);
}

void MapInfo_LoadMapSettings_SaveGameType(Gametype t)
{
	MapInfo_SwitchGameType(t);
	cvar_set("gamecfg", t.mdl);
	MapInfo_LoadedGametype = t;
}

void MapInfo_LoadMapSettings(string s) // to be called from worldspawn
{
	Gametype t = MapInfo_CurrentGametype();
	MapInfo_LoadMapSettings_SaveGameType(t);

	if(!_MapInfo_CheckMap(s, true)) // with underscore, it keeps temps
	{
		if(cvar("g_mapinfo_allow_unsupported_modes_and_let_stuff_break"))
		{
			LOG_SEVERE("can't play the selected map in the given gametype. Working with only the override settings.");
			_MapInfo_Map_ApplyGametypeEx("", t, t);
			return; // do not call Get_ByName!
		}

		if(MapInfo_Map_supportedGametypes == '0 0 0')
		{
			RandomSelection_Init();
			FOREACH(Gametypes, it.m_priority == 2, 
			{
				MapInfo_Map_supportedGametypes |= it.gametype_flags;
				RandomSelection_AddEnt(it, 1, 1);
			});
			if(RandomSelection_chosen_ent)
				t = RandomSelection_chosen_ent;
			LOG_SEVEREF("Mapinfo system is not functional at all. Falling back to a preferred mode (%s).", t.mdl);
			MapInfo_LoadMapSettings_SaveGameType(t);
			_MapInfo_Map_ApplyGametypeEx("", t, t);
			return; // do not call Get_ByName!
		}

#if 0
		// find the lowest bit in the supported gametypes
		// unnecessary now that we select one at random
		int _t = 1;
		while(!(MapInfo_Map_supportedGametypes & 1))
		{
			_t <<= 1;
			MapInfo_Map_supportedGametypes = floor(MapInfo_Map_supportedGametypes >> 1);
		}
#endif
		RandomSelection_Init();
		Gametype t_prev = t;
		FOREACH(Gametypes, MapInfo_Map_supportedGametypes & it.gametype_flags,
		{
			RandomSelection_AddEnt(it, 1, it.m_priority);
		});
		if(RandomSelection_chosen_ent)
			t = RandomSelection_chosen_ent;

		// t is now a supported mode!
		LOG_WARNF("can't play the selected map in the given gametype (%s). Falling back to a supported mode (%s).", t_prev.mdl, t.mdl);
		MapInfo_LoadMapSettings_SaveGameType(t);
	}
	if(!_MapInfo_CheckMap(s, false)) { // with underscore, it keeps temps
		LOG_WARNF("the selected map lacks features required by current settings; playing anyway.");
	}
	MapInfo_Get_ByName(s, 1, t);
}

void MapInfo_ClearTemps()
{
	MapInfo_Map_bspname = string_null;
	MapInfo_Map_title = string_null;
	MapInfo_Map_titlestring = string_null;
	MapInfo_Map_description = string_null;
	MapInfo_Map_author = string_null;
	MapInfo_Map_clientstuff = string_null;
	MapInfo_Map_supportedGametypes = '0 0 0';
	MapInfo_Map_supportedFeatures = 0;
}

void MapInfo_Shutdown()
{
	MapInfo_ClearTemps();
	MapInfo_Filter_Free();
	MapInfo_Cache_Destroy();
	if(_MapInfo_globopen)
	{
		search_end(_MapInfo_globhandle);
		_MapInfo_globhandle = -1;
		_MapInfo_globopen = false;
	}
}

int MapInfo_ForbiddenFlags()
{
	int f = MAPINFO_FLAG_FORBIDDEN;

#ifdef GAMEQC
	if (!cvar("g_maplist_allow_hidden"))
#endif
		f |= MAPINFO_FLAG_HIDDEN;

	if (!cvar("g_maplist_allow_frustrating"))
		f |= MAPINFO_FLAG_FRUSTRATING;

	return f;
}

int MapInfo_RequiredFlags()
{
	int f = 0;

	if(cvar("g_maplist_allow_frustrating") > 1)
		f |= MAPINFO_FLAG_FRUSTRATING;

	return f;
}
