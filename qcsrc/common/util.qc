#include "util.qh"

#if defined(CSQC)
	#include <client/mutators/_mod.qh>
	#include <common/constants.qh>
	#include <common/deathtypes/all.qh>
	#include <common/gametypes/_mod.qh>
	#include <common/mapinfo.qh>
	#include <common/notifications/all.qh>
	#include <common/scores.qh>
#elif defined(MENUQC)
#elif defined(SVQC)
	#include <common/constants.qh>
	#include <common/deathtypes/all.qh>
	#include <common/gametypes/_mod.qh>
	#include <common/mapinfo.qh>
	#include <common/notifications/all.qh>
	#include <common/scores.qh>
	#include <server/mutators/_mod.qh>
#endif

#ifdef SVQC
float tracebox_inverted (vector v1, vector mi, vector ma, vector v2, float nomonsters, entity forent, float stopatentity, entity ignorestopatentity) // returns the number of traces done, for benchmarking
{
	vector pos, dir, t;
	float nudge;
	entity stopentity;

	//nudge = 2 * cvar("collision_impactnudge"); // why not?
	nudge = 0.5;

	dir = normalize(v2 - v1);

	pos = v1 + dir * nudge;

	float c;
	c = 0;

	for (;;)
	{
		if(pos * dir >= v2 * dir)
		{
			// went too far
			trace_fraction = 1;
			trace_endpos = v2;
			return c;
		}

		tracebox(pos, mi, ma, v2, nomonsters, forent);
		++c;

		if(c == 50)
		{
			LOG_TRACE("When tracing from ", vtos(v1), " to ", vtos(v2));
			LOG_TRACE("  Nudging gets us nowhere at ", vtos(pos));
			LOG_TRACE("  trace_endpos is ", vtos(trace_endpos));
			LOG_TRACE("  trace distance is ", ftos(vlen(pos - trace_endpos)));
		}

		stopentity = trace_ent;

		if(trace_startsolid)
		{
			// we started inside solid.
			// then trace from endpos to pos
			t = trace_endpos;
			tracebox(t, mi, ma, pos, nomonsters, forent);
			++c;
			if(trace_startsolid)
			{
				// t is still inside solid? bad
				// force advance, then, and retry
				pos = t + dir * nudge;

				// but if we hit an entity, stop RIGHT before it
				if(stopatentity && stopentity && stopentity != ignorestopatentity)
				{
					trace_ent = stopentity;
					trace_endpos = t;
					trace_fraction = ((trace_endpos - v1) * dir) / ((v2 - v1) * dir);
					return c;
				}
			}
			else
			{
				// we actually LEFT solid!
				trace_fraction = ((trace_endpos - v1) * dir) / ((v2 - v1) * dir);
				return c;
			}
		}
		else
		{
			// pos is outside solid?!? but why?!? never mind, just return it.
			trace_endpos = pos;
			trace_fraction = ((trace_endpos - v1) * dir) / ((v2 - v1) * dir);
			return c;
		}
	}
}

void traceline_inverted (vector v1, vector v2, float nomonsters, entity forent, float stopatentity, entity ignorestopatentity)
{
	tracebox_inverted(v1, '0 0 0', '0 0 0', v2, nomonsters, forent, stopatentity, ignorestopatentity);
}
#endif

#ifdef GAMEQC
/*
==================
findbetterlocation

Returns a point at least 12 units away from walls
(useful for explosion animations, although the blast is performed where it really happened)
Ripped from DPMod
==================
*/
vector findbetterlocation (vector org, float mindist)
{
	vector vec = mindist * '1 0 0';
	int c = 0;
	while (c < 6)
	{
		traceline (org, org + vec, true, NULL);
		vec = vec * -1;
		if (trace_fraction < 1)
		{
			vector loc = trace_endpos;
			traceline (loc, loc + vec, true, NULL);
			if (trace_fraction >= 1)
				org = loc + vec;
		}
		if (c & 1)
		{
			float h = vec.y;
			vec.y = vec.x;
			vec.x = vec.z;
			vec.z = h;
		}
		c = c + 1;
	}

	return org;
}

/*
* Get "real" origin, in worldspace, even if ent is attached to something else.
*/
vector real_origin(entity ent)
{
	vector v = ((ent.absmin + ent.absmax) * 0.5);
	entity e = ent.tag_entity;

	while(e)
	{
		v = v + ((e.absmin + e.absmax) * 0.5);
		e = e.tag_entity;
	}

	return v;
}
#endif

string wordwrap_buffer;

void wordwrap_buffer_put(string s)
{
	wordwrap_buffer = strcat(wordwrap_buffer, s);
}

string wordwrap(string s, float l)
{
	string r;
	wordwrap_buffer = "";
	wordwrap_cb(s, l, wordwrap_buffer_put);
	r = wordwrap_buffer;
	wordwrap_buffer = "";
	return r;
}

#ifdef SVQC
entity _wordwrap_buffer_sprint_ent;
void wordwrap_buffer_sprint(string s)
{
	wordwrap_buffer = strcat(wordwrap_buffer, s);
	if(s == "\n")
	{
		sprint(_wordwrap_buffer_sprint_ent, wordwrap_buffer);
		wordwrap_buffer = "";
	}
}

void wordwrap_sprint(entity to, string s, float l)
{
	wordwrap_buffer = "";
	_wordwrap_buffer_sprint_ent = to;
	wordwrap_cb(s, l, wordwrap_buffer_sprint);
	_wordwrap_buffer_sprint_ent = NULL;
	if(wordwrap_buffer != "")
		sprint(to, strcat(wordwrap_buffer, "\n"));
	wordwrap_buffer = "";
	return;
}
#endif

#ifndef SVQC
string draw_UseSkinFor(string pic)
{
	if(substring(pic, 0, 1) == "/")
		return substring(pic, 1, strlen(pic)-1);
	else
		return strcat(draw_currentSkin, "/", pic);
}

#ifdef CSQC
	#define PRECACHE_PIC precache_pic
	#define SKIN_PATH    hud_skin_path
#endif
#ifdef MENUQC
	#define PRECACHE_PIC draw_PreloadPicture
	#define SKIN_PATH    (strreplace("gfx/menu", "gfx/hud", draw_currentSkin))
#endif

/// CLIENT: Returns icon path from the current HUD skin
/// MENU: Returns icon path from the HUD skin with the same name as the current menu skin
string icon_path_from_HUDskin(string theIcon)
{
	if (theIcon == "")
		return "";

	string img = strcat("/", SKIN_PATH, "/", theIcon);
	if (PRECACHE_PIC(img) == "")
		img = sprintf("/gfx/hud/default/%s", theIcon);
	return img;
}

#ifdef MENUQC
/// Returns icon path from the current menu skin (MENU only)
string icon_path_from_menuskin(string theIcon)
{
	if (theIcon == "")
		return "";

	string img = strcat("/", draw_currentSkin, "/", theIcon);
	if (draw_PreloadPicture(img) == "")
		img = sprintf("/gfx/menu/wickedx/%s", theIcon); // default menu skin
	return img;
}
#endif

#undef PRECACHE_PIC
#undef SKIN_PATH


void mut_set_active(int mut)
{
	if (mut >= 24)
		active_mutators[1] |= BIT(mut - 24);
	else
		active_mutators[0] |= BIT(mut);
}

bool mut_is_active(int mut)
{
	if (mut >= 24)
		return (active_mutators[1] & (BIT(mut - 24)));
	else
		return (active_mutators[0] & BIT(mut));
}

// MENUQC: it builds the mutator list based on local cvars (for the Mutators dialog)
// CSQC: it translates the mutator list received from server (for the Welcome dialog)
// MENUQC and CSQC code is merged in order to avoid duplicating and separating strings
string build_mutator_list(string s)
{
	#ifdef CSQC
	if (s == "") return "";
	#endif

	#ifdef MENUQC
	if (s != "") s = "";
	#endif

	int i = -1, n = 0; // allow only 1 iteration in the following for loop if (s == "")
	if (s != "")
	{
		i = 0;
		n = tokenizebyseparator(s, ", ");
	}
	string s2 = "";
	for (string arg = ""; i < n; ++i)
	{
		if (i >= 0) arg = argv(i);
		// cond is the condition for showing the mutator enabled in the menu
		#define X(name, translated_name, mut, cond) \
			if(arg == name || (!n && (cond))) { s2 = cons_mid(s2, ", ", translated_name); mut_set_active(mut); }
		X("Dodging"                   , _("Dodging")                   , MUT_DODGING                   , cvar("g_dodging"))
		X("InstaGib"                  , _("InstaGib")                  , MUT_INSTAGIB                  , cvar("g_instagib"))
		X("New Toys"                  , _("New Toys")                  , MUT_NEW_TOYS                  , cvar("g_new_toys"))
		X("NIX"                       , _("NIX")                       , MUT_NIX                       , cvar("g_nix"))
		X("Rocket Flying"             , _("Rocket Flying")             , MUT_ROCKET_FLYING             , cvar("g_rocket_flying"))
		X("Invincible Projectiles"    , _("Invincible Projectiles")    , MUT_INVINCIBLE_PROJECTILES    , cvar("g_invincible_projectiles"))
		X("Low gravity"               , _("Low gravity")               , MUT_GRAVITY                   , cvar("sv_gravity") < stof(cvar_defstring("sv_gravity")))
		X("Cloaked"                   , _("Cloaked")                   , MUT_CLOAKED                   , cvar("g_cloaked"))
		X("Hook"                      , _("Hook")                      , MUT_GRAPPLING_HOOK            , cvar("g_grappling_hook"))
		X("Midair"                    , _("Midair")                    , MUT_MIDAIR                    , cvar("g_midair"))
		X("Melee only Arena"          , _("Melee only Arena")          , MUT_MELEE_ONLY                , cvar("g_melee_only"))
		X("Vampire"                   , _("Vampire")                   , MUT_VAMPIRE                   , cvar("g_vampire"))
		X("Piñata"                    , _("Piñata")                    , MUT_PINATA                    , cvar("g_pinata"))
		X("Weapons stay"              , _("Weapons stay")              , MUT_WEAPON_STAY               , cvar("g_weapon_stay"))
		X("Blood loss"                , _("Blood loss")                , MUT_BLOODLOSS                 , cvar("g_bloodloss") > 0)
		X("Jetpack"                   , _("Jetpack")                   , MUT_JETPACK                   , cvar("g_jetpack"))
		X("Buffs"                     , _("Buffs")                     , MUT_BUFFS                     , cvar("g_buffs") > 0)
		X("Overkill"                  , _("Overkill")                  , MUT_OVERKILL                  , cvar("g_overkill"))
		X("No powerups"               , _("No powerups")               , MUT_NO_POWERUPS               , cvar("g_powerups") == 0)
		X("Powerups"                  , _("Powerups")                  , MUT_POWERUPS                  , cvar("g_powerups") > 0)
		X("Touch explode"             , _("Touch explode")             , MUT_TOUCHEXPLODE              , cvar("g_touchexplode") > 0)
		X("Wall jumping"              , _("Wall jumping")              , MUT_WALLJUMP                  , cvar("g_walljump"))
		X("No start weapons"          , _("No start weapons")          , MUT_NO_START_WEAPONS          , cvar_string("g_weaponarena") == "0" && cvar("g_balance_blaster_weaponstartoverride") == 0)
		X("Nades"                     , _("Nades")                     , MUT_NADES                     , cvar("g_nades"))
		X("Offhand blaster"           , _("Offhand blaster")           , MUT_OFFHAND_BLASTER           , cvar("g_offhand_blaster"))
		#undef X
	}
	return s2;
}
#endif

void wordwrap_cb(string s, float l, void(string) callback)
{
	string c;
	float lleft, i, j, wlen;

	s = strzone(s);
	lleft = l;
	int len = strlen(s);
	for (i = 0; i < len; ++i)
	{
		if (substring(s, i, 2) == "\\n")
		{
			callback("\n");
			lleft = l;
			++i;
		}
		else if (substring(s, i, 1) == "\n")
		{
			callback("\n");
			lleft = l;
		}
		else if (substring(s, i, 1) == " ")
		{
			if (lleft > 0)
			{
				callback(" ");
				--lleft;
			}
		}
		else
		{
			for (j = i+1; j < len; ++j)
				//    ^^ this skips over the first character of a word, which
				//       is ALWAYS part of the word
				//       this is safe since if i+1 == strlen(s), i will become
				//       strlen(s)-1 at the end of this block and the function
				//       will terminate. A space can't be the first character we
				//       read here, and neither can a \n be the start, since these
				//       two cases have been handled above.
			{
				c = substring(s, j, 1);
				if (c == " ")
					break;
				if (c == "\\")
					break;
				if (c == "\n")
					break;
				// we need to keep this tempstring alive even if substring is
				// called repeatedly, so call strcat even though we're not
				// doing anything
				callback("");
			}
			wlen = j - i;
			if (lleft < wlen)
			{
				callback("\n");
				lleft = l;
			}
			callback(substring(s, i, wlen));
			lleft -= wlen;
			i = j - 1;
		}
	}
	strunzone(s);
}

void depthfirst(entity start, .entity up, .entity downleft, .entity right, void(entity, entity) funcPre, void(entity, entity) funcPost, entity pass)
{
	entity e;
	e = start;
	funcPre(pass, e);
	while (e.(downleft))
	{
		e = e.(downleft);
		funcPre(pass, e);
	}
	funcPost(pass, e);
	while(e != start)
	{
		if (e.(right))
		{
			e = e.(right);
			funcPre(pass, e);
			while (e.(downleft))
			{
				e = e.(downleft);
				funcPre(pass, e);
			}
		}
		else
			e = e.(up);
		funcPost(pass, e);
	}
}

#ifdef GAMEQC
string ScoreString(int pFlags, float pValue, int rounds_played)
{
	string valstr;
	float l;

	pValue = floor(pValue + 0.5); // round

	if((pValue == 0) && (pFlags & (SFL_HIDE_ZERO | SFL_RANK | SFL_TIME)))
		valstr = "";
	else if(pFlags & SFL_RANK)
		valstr = (pValue < 256 ? count_ordinal(pValue) : _("N/A"));
	else if(pFlags & SFL_TIME)
		valstr = TIME_ENCODED_TOSTRING(pValue, true);
	else if (rounds_played)
		valstr = sprintf("%.1f", pValue / rounds_played);
	else
		valstr = ftos(pValue);

	return valstr;
}
#endif

// compressed vector format:
// like MD3, just even shorter
//   4 bit pitch (16 angles), 0 is -90, 8 is 0, 16 would be 90
//   5 bit yaw (32 angles), 0=0, 8=90, 16=180, 24=270
//   7 bit length (logarithmic encoding), 1/8 .. about 7844
//     length = 2^(length_encoded/8) / 8
// if pitch is 90, yaw does nothing and therefore indicates the sign (yaw is then either 11111 or 11110); 11111 is pointing DOWN
// thus, valid values are from 0000.11110.0000000 to 1111.11111.1111111
// the special value 0 indicates the zero vector

float lengthLogTable[128];

float invertLengthLog(float dist)
{
	int l, r, m;

	if(dist >= lengthLogTable[127])
		return 127;
	if(dist <= lengthLogTable[0])
		return 0;

	l = 0;
	r = 127;

	while(r - l > 1)
	{
		m = floor((l + r) / 2);
		if(lengthLogTable[m] < dist)
			l = m;
		else
			r = m;
	}

	// now: r is >=, l is <
	float lerr = (dist - lengthLogTable[l]);
	float rerr = (lengthLogTable[r] - dist);
	if(lerr < rerr)
		return l;
	return r;
}

vector decompressShortVector(int data)
{
	vector out;
	if(data == 0)
		return '0 0 0';
	float p	= (data & 0xF000) / 0x1000;
	float q	= (data & 0x0F80) / 0x80;
	int len = (data & 0x007F);

	//print("\ndecompress: p:", ftos(p)); print(" q:", ftos(q)); print(" len:", ftos(len), "\n");

	if(p == 0)
	{
		out.x = 0;
		out.y = 0;
		if(q == 31)
			out.z = -1;
		else
			out.z = +1;
	}
	else
	{
		q = M_PI / 16 * q;
		p = M_PI / 16 * p - M_PI_2;
		float cos_p = cos(p);
		out.x = cos(q) *  cos_p;
		out.y = sin(q) *  cos_p;
		out.z =          -sin(p);
	}

	//print("decompressed: ", vtos(out), "\n");

	return out * lengthLogTable[len];
}

float compressShortVector(vector vec)
{
	vector ang;
	float p, y, len;
	if(vec == '0 0 0')
		return 0;
	//print("compress: ", vtos(vec), "\n");
	ang = vectoangles(vec);
	ang.x = -ang.x;
	if(ang.x < -90)
		ang.x += 360;
	if(ang.x < -90 && ang.x > +90)
		error("BOGUS vectoangles");
	//print("angles: ", vtos(ang), "\n");

	p = floor(0.5 + (ang.x + 90) * (16 / 180)) & 15; // -90..90 to 0..14
	if(p == 0)
	{
		if(vec.z < 0)
			y = 31;
		else
			y = 30;
	}
	else
		y = floor(0.5 + ang.y * (32 / 360)) & 31; // 0..360 to 0..32
	len = invertLengthLog(vlen(vec));

	//print("compressed: p:", ftos(p)); print(" y:", ftos(y)); print(" len:", ftos(len), "\n");

	return (p * 0x1000) + (y * 0x80) + len;
}

STATIC_INIT(compressShortVector)
{
	float l = 1;
	float f = (2 ** (1/8));
	int i;
	for(i = 0; i < 128; ++i)
	{
		lengthLogTable[i] = l;
		l *= f;
	}

	if(cvar("developer") > 0)
	{
		LOG_TRACE("Verifying vector compression table...");
		for(i = 0x0F00; i < 0xFFFF; ++i)
			if(i != compressShortVector(decompressShortVector(i)))
			{
				LOG_FATALF(
				    "BROKEN vector compression: %s -> %s -> %s",
				    ftos(i),
				    vtos(decompressShortVector(i)),
				    ftos(compressShortVector(decompressShortVector(i)))
                );
			}
		LOG_TRACE("Done.");
	}
}

#ifdef GAMEQC
float CheckWireframeBox(entity forent, vector v0, vector dvx, vector dvy, vector dvz)
{
	traceline(v0, v0 + dvx, true, forent); if(trace_fraction < 1) return 0;
	traceline(v0, v0 + dvy, true, forent); if(trace_fraction < 1) return 0;
	traceline(v0, v0 + dvz, true, forent); if(trace_fraction < 1) return 0;
	traceline(v0 + dvx, v0 + dvx + dvy, true, forent); if(trace_fraction < 1) return 0;
	traceline(v0 + dvx, v0 + dvx + dvz, true, forent); if(trace_fraction < 1) return 0;
	traceline(v0 + dvy, v0 + dvy + dvx, true, forent); if(trace_fraction < 1) return 0;
	traceline(v0 + dvy, v0 + dvy + dvz, true, forent); if(trace_fraction < 1) return 0;
	traceline(v0 + dvz, v0 + dvz + dvx, true, forent); if(trace_fraction < 1) return 0;
	traceline(v0 + dvz, v0 + dvz + dvy, true, forent); if(trace_fraction < 1) return 0;
	traceline(v0 + dvx + dvy, v0 + dvx + dvy + dvz, true, forent); if(trace_fraction < 1) return 0;
	traceline(v0 + dvx + dvz, v0 + dvx + dvy + dvz, true, forent); if(trace_fraction < 1) return 0;
	traceline(v0 + dvy + dvz, v0 + dvx + dvy + dvz, true, forent); if(trace_fraction < 1) return 0;
	return 1;
}
#endif

string fixPriorityList(string order, float from, float to, float subtract, float complete)
{
	string neworder;
	float i, n, w;

	n = tokenize_console(order);
	neworder = "";
	for(i = 0; i < n; ++i)
	{
		w = stof(argv(i));
		if(w == floor(w))
		{
			if(w >= from && w <= to)
				neworder = strcat(neworder, ftos(w), " ");
			else
			{
				w -= subtract;
				if(w >= from && w <= to)
					neworder = strcat(neworder, ftos(w), " ");
			}
		}
	}

	if(complete)
	{
		n = tokenize_console(neworder);
		for(w = to; w >= from; --w)
		{
			int wflags = REGISTRY_GET(Weapons, w).spawnflags;
			if(wflags & WEP_FLAG_SPECIALATTACK)
				continue;
			for(i = 0; i < n; ++i)
				if(stof(argv(i)) == w)
					break;
			if(i == n) // not found
				neworder = strcat(neworder, ftos(w), " ");
		}
	}

	return substring(neworder, 0, strlen(neworder) - 1);
}

string mapPriorityList(string order, string(string) mapfunc)
{
	string neworder;
	float n;

	n = tokenize_console(order);
	neworder = "";
	for(float i = 0; i < n; ++i)
		neworder = strcat(neworder, mapfunc(argv(i)), " ");

	return substring(neworder, 0, strlen(neworder) - 1);
}

string swapInPriorityList(string order, float i, float j)
{
	float n = tokenize_console(order);

	if(i >= 0 && i < n && j >= 0 && j < n && i != j)
	{
		string s = "";
		for(float w = 0; w < n; ++w)
		{
			if(w == i)
				s = strcat(s, argv(j), " ");
			else if(w == j)
				s = strcat(s, argv(i), " ");
			else
				s = strcat(s, argv(w), " ");
		}
		return substring(s, 0, strlen(s) - 1);
	}

	return order;
}

#ifdef GAMEQC
void get_mi_min_max(float mode)
{
	vector mi, ma;

	string s = mapname;
	if(!strcasecmp(substring(s, 0, 5), "maps/"))
		s = substring(s, 5, strlen(s) - 5);
	if(!strcasecmp(substring(s, strlen(s) - 4, 4), ".bsp"))
		s = substring(s, 0, strlen(s) - 4);
	strcpy(mi_shortname, s);

#ifdef CSQC
	mi = world.mins;
	ma = world.maxs;
#else
	mi = world.absmin;
	ma = world.absmax;
#endif

	mi_min = mi;
	mi_max = ma;
	MapInfo_Get_ByName(mi_shortname, 0, NULL);
	if(MapInfo_Map_mins.x < MapInfo_Map_maxs.x)
	{
		mi_min = MapInfo_Map_mins;
		mi_max = MapInfo_Map_maxs;
	}
	else
	{
		// not specified
		if(mode)
		{
			// be clever
			tracebox('1 0 0' * mi.x,
					 '0 1 0' * mi.y + '0 0 1' * mi.z,
					 '0 1 0' * ma.y + '0 0 1' * ma.z,
					 '1 0 0' * ma.x,
					 MOVE_WORLDONLY,
					 NULL);
			if(!trace_startsolid)
				mi_min.x = trace_endpos.x;

			tracebox('0 1 0' * mi.y,
					 '1 0 0' * mi.x + '0 0 1' * mi.z,
					 '1 0 0' * ma.x + '0 0 1' * ma.z,
					 '0 1 0' * ma.y,
					 MOVE_WORLDONLY,
					 NULL);
			if(!trace_startsolid)
				mi_min.y = trace_endpos.y;

			tracebox('0 0 1' * mi.z,
					 '1 0 0' * mi.x + '0 1 0' * mi.y,
					 '1 0 0' * ma.x + '0 1 0' * ma.y,
					 '0 0 1' * ma.z,
					 MOVE_WORLDONLY,
					 NULL);
			if(!trace_startsolid)
				mi_min.z = trace_endpos.z;

			tracebox('1 0 0' * ma.x,
					 '0 1 0' * mi.y + '0 0 1' * mi.z,
					 '0 1 0' * ma.y + '0 0 1' * ma.z,
					 '1 0 0' * mi.x,
					 MOVE_WORLDONLY,
					 NULL);
			if(!trace_startsolid)
				mi_max.x = trace_endpos.x;

			tracebox('0 1 0' * ma.y,
					 '1 0 0' * mi.x + '0 0 1' * mi.z,
					 '1 0 0' * ma.x + '0 0 1' * ma.z,
					 '0 1 0' * mi.y,
					 MOVE_WORLDONLY,
					 NULL);
			if(!trace_startsolid)
				mi_max.y = trace_endpos.y;

			tracebox('0 0 1' * ma.z,
					 '1 0 0' * mi.x + '0 1 0' * mi.y,
					 '1 0 0' * ma.x + '0 1 0' * ma.y,
					 '0 0 1' * mi.z,
					 MOVE_WORLDONLY,
					 NULL);
			if(!trace_startsolid)
				mi_max.z = trace_endpos.z;
		}
	}
}

void get_mi_min_max_texcoords(float mode)
{
	vector extend;

	get_mi_min_max(mode);

	mi_picmin = mi_min;
	mi_picmax = mi_max;

	// extend mi_picmax to get a square aspect ratio
	// center the map in that area
	extend = mi_picmax - mi_picmin;
	if(extend.y > extend.x)
	{
		mi_picmin.x -= (extend.y - extend.x) * 0.5;
		mi_picmax.x += (extend.y - extend.x) * 0.5;
	}
	else
	{
		mi_picmin.y -= (extend.x - extend.y) * 0.5;
		mi_picmax.y += (extend.x - extend.y) * 0.5;
	}

	// add another some percent
	extend = (mi_picmax - mi_picmin) * (1 / 64.0);
	mi_picmin -= extend;
	mi_picmax += extend;

	// calculate the texcoords
	mi_pictexcoord0 = mi_pictexcoord1 = mi_pictexcoord2 = mi_pictexcoord3 = '0 0 0';
	// first the two corners of the origin
	mi_pictexcoord0_x = (mi_min.x - mi_picmin.x) / (mi_picmax.x - mi_picmin.x);
	mi_pictexcoord0_y = (mi_min.y - mi_picmin.y) / (mi_picmax.y - mi_picmin.y);
	mi_pictexcoord2_x = (mi_max.x - mi_picmin.x) / (mi_picmax.x - mi_picmin.x);
	mi_pictexcoord2_y = (mi_max.y - mi_picmin.y) / (mi_picmax.y - mi_picmin.y);
	// then the other corners
	mi_pictexcoord1_x = mi_pictexcoord0_x;
	mi_pictexcoord1_y = mi_pictexcoord2_y;
	mi_pictexcoord3_x = mi_pictexcoord2_x;
	mi_pictexcoord3_y = mi_pictexcoord0_y;
}
#endif

float cvar_settemp(string tmp_cvar, string tmp_value)
{
	float created_saved_value;

	created_saved_value = 0;

	if (!(tmp_cvar || tmp_value))
	{
		LOG_TRACE("Error: Invalid usage of cvar_settemp(string, string); !");
		return 0;
	}

	if(!cvar_type(tmp_cvar))
	{
		LOG_INFOF("Error: cvar %s doesn't exist!", tmp_cvar);
		return 0;
	}

	IL_EACH(g_saved_cvars, it.netname == tmp_cvar,
	{
		created_saved_value = -1; // skip creation
		break; // no need to continue
	});

	if(created_saved_value != -1)
	{
		// creating a new entity to keep track of this cvar
		entity e = new_pure(saved_cvar_value);
		IL_PUSH(g_saved_cvars, e);
		e.netname = strzone(tmp_cvar);
		e.message = strzone(cvar_string(tmp_cvar));
		created_saved_value = 1;
	}

	// update the cvar to the value given
	cvar_set(tmp_cvar, tmp_value);

	return created_saved_value;
}

int cvar_settemp_restore()
{
	int j = 0;
	// FIXME this new-style loop fails!
#if 0
	FOREACH_ENTITY_CLASS("saved_cvar_value", true,
	{
		if(cvar_type(it.netname))
		{
			cvar_set(it.netname, it.message);
			strunzone(it.netname);
			strunzone(it.message);
			delete(it);
			++j;
		}
		else
			LOG_INFOF("Error: cvar %s doesn't exist anymore! It can still be restored once it's manually recreated.", it.netname);
	});

#else
	entity e = NULL;
	while((e = find(e, classname, "saved_cvar_value")))
	{
		if(cvar_type(e.netname))
		{
			cvar_set(e.netname, e.message);
			delete(e);
			++j;
		}
		else
			print(sprintf("Error: cvar %s doesn't exist anymore! It can still be restored once it's manually recreated.", e.netname));
	}
#endif

	return j;
}

float textLengthUpToWidth(string theText, float maxWidth, vector theSize, textLengthUpToWidth_widthFunction_t w)
{
	// STOP.
	// The following function is SLOW.
	// For your safety and for the protection of those around you...
	// DO NOT CALL THIS AT HOME.
	// No really, don't.
	if(w(theText, theSize) <= maxWidth)
		return strlen(theText); // yeah!

	bool colors = (w("^7", theSize) == 0);

	// binary search for right place to cut string
	int len, left, right, middle;
	left = 0;
	right = len = strlen(theText);
	int ofs = 0;
	do
	{
		middle = floor((left + right) / 2);
		if(colors)
		{
			vector res = checkColorCode(theText, len, middle, false);
			ofs = (res.x) ? res.x - res.y : 0;
		}

		if(w(substring(theText, 0, middle + ofs), theSize) <= maxWidth)
			left = middle + ofs;
		else
			right = middle;
	}
	while(left < right - 1);

	return left;
}

float textLengthUpToLength(string theText, int maxLength, textLengthUpToLength_lenFunction_t w)
{
	// STOP.
	// The following function is SLOW.
	// For your safety and for the protection of those around you...
	// DO NOT CALL THIS AT HOME.
	// No really, don't.
	if(w(theText) <= maxLength)
		return strlen(theText); // yeah!

	bool colors = (w("^7") == 0);

	// binary search for right place to cut string
	int len, left, right, middle;
	left = 0;
	right = len = strlen(theText);
	int ofs = 0;
	do
	{
		middle = floor((left + right) / 2);
		if(colors)
		{
			vector res = checkColorCode(theText, len, middle, true);
			ofs = (!res.x) ? 0 : res.x - res.y;
		}

		if(w(substring(theText, 0, middle + ofs)) <= maxLength)
			left = middle + ofs;
		else
			right = middle;
	}
	while(left < right - 1);

	return left;
}

string find_last_color_code(string s)
{
	int start = strstrofs(s, "^", 0);
	if (start == -1) // no caret found
		return "";
	int len = strlen(s)-1;
	for(int i = len; i >= start; --i)
	{
		if(substring(s, i, 1) != "^")
			continue;

		int carets = 1;
		while (i-carets >= start && substring(s, i-carets, 1) == "^")
			++carets;

		// check if carets aren't all escaped
		if (carets & 1)
		{
			if(i+1 <= len)
			if(IS_DIGIT(substring(s, i+1, 1)))
				return substring(s, i, 2);

			if(i+4 <= len)
			if(substring(s, i+1, 1) == "x")
			if(IS_HEXDIGIT(substring(s, i + 2, 1)))
			if(IS_HEXDIGIT(substring(s, i + 3, 1)))
			if(IS_HEXDIGIT(substring(s, i + 4, 1)))
				return substring(s, i, 5);
		}
		i -= carets; // this also skips one char before the carets
	}

	return "";
}

string getWrappedLine(float maxWidth, vector theFontSize, textLengthUpToWidth_widthFunction_t tw)
{
	string s = getWrappedLine_remaining;

	if(maxWidth <= 0)
	{
		getWrappedLine_remaining = string_null;
		return s; // the line has no size ANYWAY, nothing would be displayed.
	}

	int take_until = textLengthUpToWidth(s, maxWidth, theFontSize, tw);
	if(take_until > 0 && take_until < strlen(s))
	{
		int last_word = take_until - 1;
		while(last_word > 0 && substring(s, last_word, 1) != " ")
			--last_word;

		int skip = 0;
		if(last_word != 0)
		{
			take_until = last_word;
			skip = 1;
		}

		getWrappedLine_remaining = substring(s, take_until + skip, strlen(s) - take_until);
		if(getWrappedLine_remaining == "")
			getWrappedLine_remaining = string_null;
		else if (tw("^7", theFontSize) == 0)
			getWrappedLine_remaining = strcat(find_last_color_code(substring(s, 0, take_until)), getWrappedLine_remaining);
		return substring(s, 0, take_until);
	}
	else
	{
		getWrappedLine_remaining = string_null;
		return s;
	}
}

string getWrappedLineLen(int maxLength, textLengthUpToLength_lenFunction_t tw)
{
	string s = getWrappedLine_remaining;

	if(maxLength <= 0)
	{
		getWrappedLine_remaining = string_null;
		return s; // the line has no size ANYWAY, nothing would be displayed.
	}

	int take_until = textLengthUpToLength(s, maxLength, tw);
	if(take_until > 0 && take_until < strlen(s))
	{
		int last_word = take_until - 1;
		while(last_word > 0 && substring(s, last_word, 1) != " ")
			--last_word;

		int skip = 0;
		if(last_word != 0)
		{
			take_until = last_word;
			skip = 1;
		}

		getWrappedLine_remaining = substring(s, take_until + skip, strlen(s) - take_until);
		if(getWrappedLine_remaining == "")
			getWrappedLine_remaining = string_null;
		else if (tw("^7") == 0)
			getWrappedLine_remaining = strcat(find_last_color_code(substring(s, 0, take_until)), getWrappedLine_remaining);
		return substring(s, 0, take_until);
	}
	else
	{
		getWrappedLine_remaining = string_null;
		return s;
	}
}

string textShortenToWidth(string theText, float maxWidth, vector theFontSize, textLengthUpToWidth_widthFunction_t tw)
{
	if(tw(theText, theFontSize) <= maxWidth)
		return theText;
	else
		return strcat(substring(theText, 0, textLengthUpToWidth(theText, maxWidth - tw("...", theFontSize), theFontSize, tw)), "...");
}

string textShortenToLength(string theText, float maxWidth, textLengthUpToLength_lenFunction_t tw)
{
	if(tw(theText) <= maxWidth)
		return theText;
	else
		return strcat(substring(theText, 0, textLengthUpToLength(theText, maxWidth - tw("..."), tw)), "...");
}

float isGametypeInFilter(Gametype gt, float tp, float ts, string pattern)
{
	string subpattern, subpattern2, subpattern3, subpattern4;
	subpattern = strcat(",", MapInfo_Type_ToString(gt), ",");
	if(tp)
		subpattern2 = ",teams,";
	else
		subpattern2 = ",noteams,";
	if(ts)
		subpattern3 = ",teamspawns,";
	else
		subpattern3 = ",noteamspawns,";
	if(gt == MAPINFO_TYPE_RACE || gt == MAPINFO_TYPE_CTS)
		subpattern4 = ",race,";
	else
		subpattern4 = string_null;

	if(substring(pattern, 0, 1) == "-")
	{
		pattern = substring(pattern, 1, strlen(pattern) - 1);
		if(strstrofs(strcat(",", pattern, ","), subpattern, 0) >= 0)
			return 0;
		if(strstrofs(strcat(",", pattern, ","), subpattern2, 0) >= 0)
			return 0;
		if(strstrofs(strcat(",", pattern, ","), subpattern3, 0) >= 0)
			return 0;
		if(subpattern4 && strstrofs(strcat(",", pattern, ","), subpattern4, 0) >= 0)
			return 0;
	}
	else
	{
		if(substring(pattern, 0, 1) == "+")
			pattern = substring(pattern, 1, strlen(pattern) - 1);
		if(strstrofs(strcat(",", pattern, ","), subpattern, 0) < 0)
		if(strstrofs(strcat(",", pattern, ","), subpattern2, 0) < 0)
		if(strstrofs(strcat(",", pattern, ","), subpattern3, 0) < 0)
		{
			if (!subpattern4)
				return 0;
			if(strstrofs(strcat(",", pattern, ","), subpattern4, 0) < 0)
				return 0;
		}
	}
	return 1;
}

vector solve_shotdirection(vector myorg, vector myvel, vector eorg, vector evel, float spd, float newton_style)
{
	vector ret;

	// make origin and speed relative
	eorg -= myorg;
	if(newton_style)
		evel -= myvel;

	// now solve for ret, ret normalized:
	//   eorg + t * evel == t * ret * spd
	// or, rather, solve for t:
	//   |eorg + t * evel| == t * spd
	//   eorg^2 + t^2 * evel^2 + 2 * t * (eorg * evel) == t^2 * spd^2
	//   t^2 * (evel^2 - spd^2) + t * (2 * (eorg * evel)) + eorg^2 == 0
	vector solution = solve_quadratic(evel * evel - spd * spd, 2 * (eorg * evel), eorg * eorg);
	// p = 2 * (eorg * evel) / (evel * evel - spd * spd)
	// q = (eorg * eorg) / (evel * evel - spd * spd)
	if(!solution.z) // no real solution
	{
		// happens if D < 0
		// (eorg * evel)^2 < (evel^2 - spd^2) * eorg^2
		// (eorg * evel)^2 / eorg^2 < evel^2 - spd^2
		// spd^2 < ((evel^2 * eorg^2) - (eorg * evel)^2) / eorg^2
		// spd^2 < evel^2 * (1 - cos^2 angle(evel, eorg))
		// spd^2 < evel^2 * sin^2 angle(evel, eorg)
		// spd < |evel| * sin angle(evel, eorg)
		return '0 0 0';
	}
	else if(solution.x > 0)
	{
		// both solutions > 0: take the smaller one
		// happens if p < 0 and q > 0
		ret = normalize(eorg + solution.x * evel);
	}
	else if(solution.y > 0)
	{
		// one solution > 0: take the larger one
		// happens if q < 0 or q == 0 and p < 0
		ret = normalize(eorg + solution.y * evel);
	}
	else
	{
		// no solution > 0: reject
		// happens if p > 0 and q >= 0
		// 2 * (eorg * evel) / (evel * evel - spd * spd) > 0
		// (eorg * eorg) / (evel * evel - spd * spd) >= 0
		//
		// |evel| >= spd
		// eorg * evel > 0
		//
		// "Enemy is moving away from me at more than spd"
		return '0 0 0';
	}

	// NOTE: we always got a solution if spd > |evel|

	if(newton_style == 2)
		ret = normalize(ret * spd + myvel);

	return ret;
}

vector get_shotvelocity(vector myvel, vector mydir, float spd, float newton_style, float mi, float ma)
{
	if(!newton_style)
		return spd * mydir;

	if(newton_style == 2)
	{
		// true Newtonian projectiles with automatic aim adjustment
		//
		// solve: |outspeed * mydir - myvel| = spd
		// outspeed^2 - 2 * outspeed * (mydir * myvel) + myvel^2 - spd^2 = 0
		// outspeed = (mydir * myvel) +- sqrt((mydir * myvel)^2 - myvel^2 + spd^2)
		// PLUS SIGN!
		// not defined?
		// then...
		// myvel^2 - (mydir * myvel)^2 > spd^2
		// velocity without mydir component > spd
		// fire at smallest possible spd that works?
		// |(mydir * myvel) * myvel - myvel| = spd

		vector solution = solve_quadratic(1, -2 * (mydir * myvel), myvel * myvel - spd * spd);

		float outspeed;
		if(solution.z)
			outspeed = solution.y; // the larger one
		else
		{
			//outspeed = 0; // slowest possible shot
			outspeed = solution.x; // the real part (that is, the average!)
			//dprint("impossible shot, adjusting\n");
		}

		outspeed = bound(spd * mi, outspeed, spd * ma);
		return mydir * outspeed;
	}

	// real Newtonian
	return myvel + spd * mydir;
}

// compresses the shot origin offset vector to an int with the following format:
// xxxxxxxx SSyyyyyy SUzzzzzz
// 32109876 54321098 76543210
// 1st byte: x component (it uses all 8 bits)
// 2nd byte: y component in the last 6 bits and the signs of the x and y components
// 3rd byte: z component in the last 6 bits and the sign of the z component (the 2nd bit is unused)
// all values are doubled on compression and halved on decompression
// so the precision for all components is 0.5
// values are bound to the following ranges:
// x: -127.5 +127.5
// y:  -31.5  +31.5
// z:  -31.5  +31.5
float compressShotOrigin(vector v)
{
	int rx_neg = (v.x < 0) ? 1 : 0;
	int ry_neg = (v.y < 0) ? 1 : 0;
	int rz_neg = (v.z < 0) ? 1 : 0;
	int rx = rint(fabs(v.x) * 2);
	int ry = rint(fabs(v.y) * 2);
	int rz = rint(fabs(v.z) * 2);
	if(rx > 255) // 128 * 2 - 1
	{
		LOG_DEBUG("shot origin ", vtos(v), " x out of bounds\n");
		rx = bound(0, rx, 255);
	}
	if(ry > 63) // 32 * 2 - 1
	{
		LOG_DEBUG("shot origin ", vtos(v), " y out of bounds\n");
		ry = bound(0, ry, 63);
	}
	if(rz > 63) // 32 * 2 - 1
	{
		LOG_DEBUG("shot origin ", vtos(v), " z out of bounds\n");
		rz = bound(0, rz, 63);
	}
	ry |= ry_neg * BIT(6) + rx_neg * BIT(7);
	rz |= rz_neg * BIT(6); // BIT(7) unused
	return rx * 0x10000 + ry * 0x100 + rz;
}
vector decompressShotOrigin(int f)
{
	vector v;
	v.x = f >> 16;
	v.y = (f & 0xFF00) >> 8;
	v.z = f & 0xFF;
	// remove sign bits and apply sign
	if (v.y & BIT(7)) { v.y &= ~BIT(7); v.x *= -1; }
	if (v.y & BIT(6)) { v.y &= ~BIT(6); v.y *= -1; }
	if (v.z & BIT(6)) { v.z &= ~BIT(6); v.z *= -1; }
	return v * 0.5;
}

#ifdef GAMEQC
vector healtharmor_maxdamage(float h, float a, float armorblock, int deathtype)
{
	// NOTE: we'll always choose the SMALLER value...
	float healthdamage, armordamage, armorideal;
	if (DEATH_IS(deathtype, DEATH_DROWN))  // Why should armor help here...
		armorblock = 0;
	vector v;
	healthdamage = (h - 1) / (1 - armorblock); // damage we can take if we could use more health
	armordamage = a + (h - 1); // damage we can take if we could use more armor
	armorideal = healthdamage * armorblock;
	v.y = armorideal;
	if(armordamage < healthdamage)
	{
		v.x = armordamage;
		v.z = 1;
	}
	else
	{
		v.x = healthdamage;
		v.z = 0;
	}
	return v;
}

vector healtharmor_applydamage(float a, float armorblock, int deathtype, float damage)
{
	vector v;
	if (DEATH_IS(deathtype, DEATH_DROWN))  // Why should armor help here...
		armorblock = 0;
	if (deathtype & HITTYPE_ARMORPIERCE)
		armorblock = 0;
	v.y = bound(0, damage * armorblock, a); // save
	v.x = bound(0, damage - v.y, damage); // take
	v.z = 0;
	return v;
}
#endif

string getcurrentmod()
{
	float n;
	string m;
	m = cvar_string("fs_gamedir");
	n = tokenize_console(m);
	if(n == 0)
		return "data";
	else
		return argv(n - 1);
}

float matchacl(string acl, string str)
{
	string t, s;
	float r, d;
	r = 0;
	while(acl)
	{
		t = car(acl); acl = cdr(acl);

		d = 1;
		if(substring(t, 0, 1) == "-")
		{
			d = -1;
			t = substring(t, 1, strlen(t) - 1);
		}
		else if(substring(t, 0, 1) == "+")
			t = substring(t, 1, strlen(t) - 1);

		if(substring(t, -1, 1) == "*")
		{
			t = substring(t, 0, strlen(t) - 1);
			s = substring(str, 0, strlen(t));
		}
		else
			s = str;

		if(s == t)
		{
			r = d;
			break; // if we found a killing case, apply it! other settings may be allowed in the future, but this one is caught
		}
	}
	return r;
}

ERASEABLE
void write_String_To_File(int fh, string str, bool alsoprint)
{
	fputs(fh, str);
	if (alsoprint) LOG_HELP(str);
}

string get_model_datafilename(string m, float sk, string fil)
{
	if(m)
		m = strcat(m, "_");
	else
		m = "models/player/*_";
	if(sk >= 0)
		m = strcat(m, ftos(sk));
	else
		m = strcat(m, "*");
	return strcat(m, ".", fil);
}

float get_model_parameters(string m, float sk)
{
	get_model_parameters_modelname = string_null;
	get_model_parameters_modelskin = -1;
	get_model_parameters_name = string_null;
	get_model_parameters_species = -1;
	get_model_parameters_sex = string_null;
	get_model_parameters_weight = -1;
	get_model_parameters_age = -1;
	get_model_parameters_desc = string_null;
	get_model_parameters_bone_upperbody = string_null;
	get_model_parameters_bone_weapon = string_null;
	for(int i = 0; i < MAX_AIM_BONES; ++i)
	{
		get_model_parameters_bone_aim[i] = string_null;
		get_model_parameters_bone_aimweight[i] = 0;
	}
	get_model_parameters_fixbone = 0;
	get_model_parameters_hidden = false;

#ifdef GAMEQC
	MUTATOR_CALLHOOK(ClearModelParams);
#endif

	if (!m)
		return 1;

	if(substring(m, -9, 5) == "_lod1" || substring(m, -9, 5) == "_lod2")
		m = strcat(substring(m, 0, -10), substring(m, -4, -1));

	if(sk < 0)
	{
		if(substring(m, -4, -1) != ".txt")
			return 0;
		if(substring(m, -6, 1) != "_")
			return 0;
		sk = stof(substring(m, -5, 1));
		m = substring(m, 0, -7);
	}

	string fn = get_model_datafilename(m, sk, "txt");
	int fh = fopen(fn, FILE_READ);
	if(fh < 0)
	{
		sk = 0;
		fn = get_model_datafilename(m, sk, "txt");
		fh = fopen(fn, FILE_READ);
		if(fh < 0)
			return 0;
	}

	get_model_parameters_modelname = m;
	get_model_parameters_modelskin = sk;
	string s, c;
	while((s = fgets(fh)))
	{
		if(s == "")
			break; // next lines will be description
		c = car(s);
		s = cdr(s);
		if(c == "name")
			get_model_parameters_name = s;
		if(c == "species")
			switch(s)
			{
				case "human":       get_model_parameters_species = SPECIES_HUMAN;       break;
				case "alien":       get_model_parameters_species = SPECIES_ALIEN;       break;
				case "robot_shiny": get_model_parameters_species = SPECIES_ROBOT_SHINY; break;
				case "robot_rusty": get_model_parameters_species = SPECIES_ROBOT_RUSTY; break;
				case "robot_solid": get_model_parameters_species = SPECIES_ROBOT_SOLID; break;
				case "animal":      get_model_parameters_species = SPECIES_ANIMAL;      break;
				case "reserved":    get_model_parameters_species = SPECIES_RESERVED;    break;
			}
		if(c == "sex")
		{
			if (s == "Male")				s = _("Male");
			else if (s == "Female")			s = _("Female");
			else if (s == "Undisclosed")	s = _("Undisclosed");
			get_model_parameters_sex = s;
		}
		if(c == "weight")
			get_model_parameters_weight = stof(s);
		if(c == "age")
			get_model_parameters_age = stof(s);
		if(c == "description")
			get_model_parameters_description = s;
		if(c == "bone_upperbody")
			get_model_parameters_bone_upperbody = s;
		if(c == "bone_weapon")
			get_model_parameters_bone_weapon = s;
	#ifdef GAMEQC
		MUTATOR_CALLHOOK(GetModelParams, c, s);
	#endif
		for(int i = 0; i < MAX_AIM_BONES; ++i)
			if(c == strcat("bone_aim", ftos(i)))
			{
				get_model_parameters_bone_aimweight[i] = stof(car(s));
				get_model_parameters_bone_aim[i] = cdr(s);
			}
		if(c == "fixbone")
			get_model_parameters_fixbone = stof(s);
		if(c == "hidden")
			get_model_parameters_hidden = stob(s);
	}

	while((s = fgets(fh)))
	{
		if(get_model_parameters_desc)
			get_model_parameters_desc = strcat(get_model_parameters_desc, "\n");
		if(s != "")
			get_model_parameters_desc = strcat(get_model_parameters_desc, s);
	}

	fclose(fh);

	return 1;
}

string translate_key(string key)
{
	if (prvm_language == "en") return key;

	if (substring(key, 0, 1) == "<")
	{
		if (key == "<KEY NOT FOUND>") return _("<KEY NOT FOUND>");
		if (key == "<UNKNOWN KEYNUM>") return _("<UNKNOWN KEYNUM>");
	}

	switch(key)
	{
		case "TAB":				return _("TAB");
		case "ENTER":			return _("ENTER");
		case "ESCAPE":			return _("ESCAPE");
		case "SPACE":			return _("SPACE");

		case "BACKSPACE":		return _("BACKSPACE");
		case "UPARROW":			return _("UPARROW");
		case "DOWNARROW":		return _("DOWNARROW");
		case "LEFTARROW":		return _("LEFTARROW");
		case "RIGHTARROW":		return _("RIGHTARROW");

		case "ALT":				return _("ALT");
		case "CTRL":			return _("CTRL");
		case "SHIFT":			return _("SHIFT");

		case "INS":				return _("INS");
		case "DEL":				return _("DEL");
		case "PGDN":			return _("PGDN");
		case "PGUP":			return _("PGUP");
		case "HOME":			return _("HOME");
		case "END":				return _("END");

		case "PAUSE":			return _("PAUSE");

		case "NUMLOCK":			return _("NUMLOCK");
		case "CAPSLOCK":		return _("CAPSLOCK");
		case "SCROLLOCK":		return _("SCROLLOCK");

		case "SEMICOLON":		return _("SEMICOLON");
		case "TILDE":			return _("TILDE");
		case "BACKQUOTE":		return _("BACKQUOTE");
		case "QUOTE":			return _("QUOTE");
		case "APOSTROPHE":		return _("APOSTROPHE");
		case "BACKSLASH":		return _("BACKSLASH");
	}

	if (substring(key, 0, 1) == "F")
	{
		string subkey = substring(key, 1, -1);
		if (IS_DIGIT(substring(key, 3, 1))) // check only first digit
		{
			return sprintf(_("F%d"), stof(subkey));
		}
		// continue in case there is another key name starting with F
	}

	if (substring(key, 0, 3) == "KP_")
	{
		string subkey = substring(key, 3, -1);
		if (IS_DIGIT(substring(key, 3, 1))) // check only first digit
		{
			return sprintf(_("KP_%d"), stof(subkey));
		}

		switch(subkey)
		{
			case "INS":				return sprintf(_("KP_%s"), _("INS"));
			case "END":				return sprintf(_("KP_%s"), _("END"));
			case "DOWNARROW":		return sprintf(_("KP_%s"), _("DOWNARROW"));
			case "PGDN":			return sprintf(_("KP_%s"), _("PGDN"));
			case "LEFTARROW":		return sprintf(_("KP_%s"), _("LEFTARROW"));
			case "RIGHTARROW":		return sprintf(_("KP_%s"), _("RIGHTARROW"));
			case "HOME":			return sprintf(_("KP_%s"), _("HOME"));
			case "UPARROW":			return sprintf(_("KP_%s"), _("UPARROW"));
			case "PGUP":			return sprintf(_("KP_%s"), _("PGUP"));
			case "PERIOD":			return sprintf(_("KP_%s"), _("PERIOD"));
			case "DEL":				return sprintf(_("KP_%s"), _("DEL"));
			case "DIVIDE":			return sprintf(_("KP_%s"), _("DIVIDE"));
			case "SLASH":			return sprintf(_("KP_%s"), _("SLASH"));
			case "MULTIPLY":		return sprintf(_("KP_%s"), _("MULTIPLY"));
			case "MINUS":			return sprintf(_("KP_%s"), _("MINUS"));
			case "PLUS":			return sprintf(_("KP_%s"), _("PLUS"));
			case "ENTER":			return sprintf(_("KP_%s"), _("ENTER"));
			case "EQUALS":			return sprintf(_("KP_%s"), _("EQUALS"));
			default:				return key;
		}
	}

	if (key == "PRINTSCREEN") return _("PRINTSCREEN");

	if (substring(key, 0, 5) == "MOUSE")
		return sprintf(_("MOUSE%d"), stof(substring(key, 5, -1)));

	if (key == "MWHEELUP") return _("MWHEELUP");
	if (key == "MWHEELDOWN") return _("MWHEELDOWN");

	if (substring(key, 0,3) == "JOY")
		return sprintf(_("JOY%d"), stof(substring(key, 3, -1)));

	if (substring(key, 0,3) == "AUX")
		return sprintf(_("AUX%d"), stof(substring(key, 3, -1)));

	if (substring(key, 0, 4) == "X360_")
	{
		string subkey = substring(key, 4, -1);
		switch(subkey)
		{
			case "DPAD_UP":					return sprintf(_("X360_%s"), _("DPAD_UP"));
			case "DPAD_DOWN":				return sprintf(_("X360_%s"), _("DPAD_DOWN"));
			case "DPAD_LEFT":				return sprintf(_("X360_%s"), _("DPAD_LEFT"));
			case "DPAD_RIGHT":				return sprintf(_("X360_%s"), _("DPAD_RIGHT"));
			case "START":					return sprintf(_("X360_%s"), _("START"));
			case "BACK":					return sprintf(_("X360_%s"), _("BACK"));
			case "LEFT_THUMB":				return sprintf(_("X360_%s"), _("LEFT_THUMB"));
			case "RIGHT_THUMB":				return sprintf(_("X360_%s"), _("RIGHT_THUMB"));
			case "LEFT_SHOULDER":			return sprintf(_("X360_%s"), _("LEFT_SHOULDER"));
			case "RIGHT_SHOULDER":			return sprintf(_("X360_%s"), _("RIGHT_SHOULDER"));
			case "LEFT_TRIGGER":			return sprintf(_("X360_%s"), _("LEFT_TRIGGER"));
			case "RIGHT_TRIGGER":			return sprintf(_("X360_%s"), _("RIGHT_TRIGGER"));
			case "LEFT_THUMB_UP":			return sprintf(_("X360_%s"), _("LEFT_THUMB_UP"));
			case "LEFT_THUMB_DOWN":			return sprintf(_("X360_%s"), _("LEFT_THUMB_DOWN"));
			case "LEFT_THUMB_LEFT":			return sprintf(_("X360_%s"), _("LEFT_THUMB_LEFT"));
			case "LEFT_THUMB_RIGHT":		return sprintf(_("X360_%s"), _("LEFT_THUMB_RIGHT"));
			case "RIGHT_THUMB_UP":			return sprintf(_("X360_%s"), _("RIGHT_THUMB_UP"));
			case "RIGHT_THUMB_DOWN":		return sprintf(_("X360_%s"), _("RIGHT_THUMB_DOWN"));
			case "RIGHT_THUMB_LEFT":		return sprintf(_("X360_%s"), _("RIGHT_THUMB_LEFT"));
			case "RIGHT_THUMB_RIGHT":		return sprintf(_("X360_%s"), _("RIGHT_THUMB_RIGHT"));
			default:						return key;
		}
	}

	if (substring(key, 0, 4) == "JOY_")
	{
		string subkey = substring(key, 4, -1);
		switch(subkey)
		{
			case "UP":			return sprintf(_("JOY_%s"), _("UP"));
			case "DOWN":		return sprintf(_("JOY_%s"), _("DOWN"));
			case "LEFT":		return sprintf(_("JOY_%s"), _("LEFT"));
			case "RIGHT":		return sprintf(_("JOY_%s"), _("RIGHT"));
			default:			return key;
		}
	}

	if (substring(key, 0, 8) == "MIDINOTE")
		return sprintf(_("MIDINOTE%d"), stof(substring(key, 8, -1)));

	return key;
}

// x-encoding (encoding as zero length invisible string)
const string XENCODE_2  = "xX";
const string XENCODE_22 = "0123456789abcdefABCDEF";
string xencode(int f)
{
	float a, b, c, d;
	d = f % 22; f = floor(f / 22);
	c = f % 22; f = floor(f / 22);
	b = f % 22; f = floor(f / 22);
	a = f %  2; // f = floor(f /  2);
	return strcat(
		"^",
		substring(XENCODE_2,  a, 1),
		substring(XENCODE_22, b, 1),
		substring(XENCODE_22, c, 1),
		substring(XENCODE_22, d, 1)
	);
}
float xdecode(string s)
{
	float a, b, c, d;
	if(substring(s, 0, 1) != "^")
		return -1;
	if(strlen(s) < 5)
		return -1;
	a = strstrofs(XENCODE_2,  substring(s, 1, 1), 0);
	b = strstrofs(XENCODE_22, substring(s, 2, 1), 0);
	c = strstrofs(XENCODE_22, substring(s, 3, 1), 0);
	d = strstrofs(XENCODE_22, substring(s, 4, 1), 0);
	if(a < 0 || b < 0 || c < 0 || d < 0)
		return -1;
	return ((a * 22 + b) * 22 + c) * 22 + d;
}

/*
string strlimitedlen(string input, string truncation, float strip_colors, float limit)
{
	if(strlen((strip_colors ? strdecolorize(input) : input)) <= limit)
		return input;
	else
		return strcat(substring(input, 0, (strlen(input) - strlen(truncation))), truncation);
}*/

float shutdown_running;
#ifdef SVQC
void SV_Shutdown()
#endif
#ifdef CSQC
void CSQC_Shutdown()
#endif
#ifdef MENUQC
void m_shutdown()
#endif
{
	if(shutdown_running)
	{
		LOG_INFO("Recursive shutdown detected! Only restoring cvars...");
	}
	else
	{
		shutdown_running = 1;
		Shutdown();
		shutdownhooks();
	}
	cvar_settemp_restore(); // this must be done LAST, but in any case
}

#ifdef GAMEQC
.float skeleton_bones_index;
void Skeleton_SetBones(entity e)
{
	// set skeleton_bones to the total number of bones on the model
	if(e.skeleton_bones_index == e.modelindex)
		return; // same model, nothing to update

	float skelindex;
	skelindex = skel_create(e.modelindex);
	e.skeleton_bones = skel_get_numbones(skelindex);
	skel_delete(skelindex);
	e.skeleton_bones_index = e.modelindex;
}
#endif

string to_execute_next_frame;
void execute_next_frame()
{
	if(to_execute_next_frame)
	{
		localcmd("\n", to_execute_next_frame, "\n");
		strfree(to_execute_next_frame);
	}
}
void queue_to_execute_next_frame(string s)
{
	if(to_execute_next_frame)
	{
		s = strcat(s, "\n", to_execute_next_frame);
	}
	strcpy(to_execute_next_frame, s);
}

.float FindConnectedComponent_processing;
void FindConnectedComponent(entity e, .entity fld, findNextEntityNearFunction_t nxt, isConnectedFunction_t iscon, entity pass)
{
	entity queue_start, queue_end;

	// we build a queue of to-be-processed entities.
	// queue_start is the next entity to be checked for neighbors
	// queue_end is the last entity added

	if(e.FindConnectedComponent_processing)
		error("recursion or broken cleanup");

	// start with a 1-element queue
	queue_start = queue_end = e;
	queue_end.(fld) = NULL;
	queue_end.FindConnectedComponent_processing = 1;

	// for each queued item:
	for (; queue_start; queue_start = queue_start.(fld))
	{
		// find all neighbors of queue_start
		entity t;
		for(t = NULL; (t = nxt(t, queue_start, pass)); )
		{
			if(t.FindConnectedComponent_processing)
				continue;
			if(iscon(t, queue_start, pass))
			{
				// it is connected? ADD IT. It will look for neighbors soon too.
				queue_end.(fld) = t;
				queue_end = t;
				queue_end.(fld) = NULL;
				queue_end.FindConnectedComponent_processing = 1;
			}
		}
	}

	// unmark
	for (queue_start = e; queue_start; queue_start = queue_start.(fld))
		queue_start.FindConnectedComponent_processing = 0;
}

#ifdef GAMEQC
vector animfixfps(entity e, vector a, vector b)
{
	// multi-frame anim: keep as-is
	if(a.y == 1)
	{
		float dur = frameduration(e.modelindex, a.x);
		if (dur <= 0 && b.y)
		{
			a = b;
			dur = frameduration(e.modelindex, a.x);
		}
		if (dur > 0)
			a.z = 1.0 / dur;
	}
	return a;
}
#endif

#ifdef GAMEQC
Notification Announcer_PickNumber(int type, int num)
{
    return = NULL;
	switch (type)
	{
		case CNT_GAMESTART:
		{
			switch(num)
			{
				case 10: return ANNCE_NUM_GAMESTART_10;
				case 9:  return ANNCE_NUM_GAMESTART_9;
				case 8:  return ANNCE_NUM_GAMESTART_8;
				case 7:  return ANNCE_NUM_GAMESTART_7;
				case 6:  return ANNCE_NUM_GAMESTART_6;
				case 5:  return ANNCE_NUM_GAMESTART_5;
				case 4:  return ANNCE_NUM_GAMESTART_4;
				case 3:  return ANNCE_NUM_GAMESTART_3;
				case 2:  return ANNCE_NUM_GAMESTART_2;
				case 1:  return ANNCE_NUM_GAMESTART_1;
			}
			break;
		}
		case CNT_KILL:
		{
			switch(num)
			{
				case 10: return ANNCE_NUM_KILL_10;
				case 9:  return ANNCE_NUM_KILL_9;
				case 8:  return ANNCE_NUM_KILL_8;
				case 7:  return ANNCE_NUM_KILL_7;
				case 6:  return ANNCE_NUM_KILL_6;
				case 5:  return ANNCE_NUM_KILL_5;
				case 4:  return ANNCE_NUM_KILL_4;
				case 3:  return ANNCE_NUM_KILL_3;
				case 2:  return ANNCE_NUM_KILL_2;
				case 1:  return ANNCE_NUM_KILL_1;
			}
			break;
		}
		case CNT_RESPAWN:
		{
			switch(num)
			{
				case 10: return ANNCE_NUM_RESPAWN_10;
				case 9:  return ANNCE_NUM_RESPAWN_9;
				case 8:  return ANNCE_NUM_RESPAWN_8;
				case 7:  return ANNCE_NUM_RESPAWN_7;
				case 6:  return ANNCE_NUM_RESPAWN_6;
				case 5:  return ANNCE_NUM_RESPAWN_5;
				case 4:  return ANNCE_NUM_RESPAWN_4;
				case 3:  return ANNCE_NUM_RESPAWN_3;
				case 2:  return ANNCE_NUM_RESPAWN_2;
				case 1:  return ANNCE_NUM_RESPAWN_1;
			}
			break;
		}
		case CNT_ROUNDSTART:
		{
			switch(num)
			{
				case 10: return ANNCE_NUM_ROUNDSTART_10;
				case 9:  return ANNCE_NUM_ROUNDSTART_9;
				case 8:  return ANNCE_NUM_ROUNDSTART_8;
				case 7:  return ANNCE_NUM_ROUNDSTART_7;
				case 6:  return ANNCE_NUM_ROUNDSTART_6;
				case 5:  return ANNCE_NUM_ROUNDSTART_5;
				case 4:  return ANNCE_NUM_ROUNDSTART_4;
				case 3:  return ANNCE_NUM_ROUNDSTART_3;
				case 2:  return ANNCE_NUM_ROUNDSTART_2;
				case 1:  return ANNCE_NUM_ROUNDSTART_1;
			}
			break;
		}
		case CNT_NORMAL:
		default:
		{
			switch(num)
			{
				case 10: return ANNCE_NUM_10;
				case 9:  return ANNCE_NUM_9;
				case 8:  return ANNCE_NUM_8;
				case 7:  return ANNCE_NUM_7;
				case 6:  return ANNCE_NUM_6;
				case 5:  return ANNCE_NUM_5;
				case 4:  return ANNCE_NUM_4;
				case 3:  return ANNCE_NUM_3;
				case 2:  return ANNCE_NUM_2;
				case 1:  return ANNCE_NUM_1;
			}
			break;
		}
	}
}
#endif

#ifdef GAMEQC
int Mod_Q1BSP_SuperContentsFromNativeContents(int nativecontents)
{
	switch(nativecontents)
	{
		case CONTENT_EMPTY:
			return 0;
		case CONTENT_SOLID:
			return DPCONTENTS_SOLID | DPCONTENTS_OPAQUE;
		case CONTENT_WATER:
			return DPCONTENTS_WATER;
		case CONTENT_SLIME:
			return DPCONTENTS_SLIME;
		case CONTENT_LAVA:
			return DPCONTENTS_LAVA | DPCONTENTS_NODROP;
		case CONTENT_SKY:
			return DPCONTENTS_SKY | DPCONTENTS_NODROP | DPCONTENTS_OPAQUE; // to match behaviour of Q3 maps, let sky count as opaque
	}
	return 0;
}

int Mod_Q1BSP_NativeContentsFromSuperContents(int supercontents)
{
	if(supercontents & (DPCONTENTS_SOLID | DPCONTENTS_BODY))
		return CONTENT_SOLID;
	if(supercontents & DPCONTENTS_SKY)
		return CONTENT_SKY;
	if(supercontents & DPCONTENTS_LAVA)
		return CONTENT_LAVA;
	if(supercontents & DPCONTENTS_SLIME)
		return CONTENT_SLIME;
	if(supercontents & DPCONTENTS_WATER)
		return CONTENT_WATER;
	return CONTENT_EMPTY;
}
#endif

#ifdef SVQC
void attach_sameorigin(entity e, entity to, string tag)
{
    vector org, t_forward, t_left, t_up, e_forward, e_up;
    float tagscale;

    org = e.origin - gettaginfo(to, gettagindex(to, tag));
    tagscale = (vlen(v_forward) ** -2); // undo a scale on the tag
    t_forward = v_forward * tagscale;
    t_left = v_right * -tagscale;
    t_up = v_up * tagscale;

    e.origin_x = org * t_forward;
    e.origin_y = org * t_left;
    e.origin_z = org * t_up;

    // current forward and up directions
    if (substring(e.model, 0, 1) == "*") // bmodels have their own rules
		e.angles = AnglesTransform_FromVAngles(e.angles);
	else
		e.angles = AnglesTransform_FromAngles(e.angles);
    fixedmakevectors(e.angles);

    // untransform forward, up!
    e_forward.x = v_forward * t_forward;
    e_forward.y = v_forward * t_left;
    e_forward.z = v_forward * t_up;
    e_up.x = v_up * t_forward;
    e_up.y = v_up * t_left;
    e_up.z = v_up * t_up;

    e.angles = fixedvectoangles2(e_forward, e_up);
    if (substring(e.model, 0, 1) == "*") // bmodels have their own rules
		e.angles = AnglesTransform_ToVAngles(e.angles);
	else
		e.angles = AnglesTransform_ToAngles(e.angles);

    setattachment(e, to, tag);
    setorigin(e, e.origin);
}

void detach_sameorigin(entity e)
{
    vector org;
    org = gettaginfo(e, 0);
    e.angles = fixedvectoangles2(v_forward, v_up);
    if (substring(e.model, 0, 1) == "*") // bmodels have their own rules
		e.angles = AnglesTransform_ToVAngles(e.angles);
	else
		e.angles = AnglesTransform_ToAngles(e.angles);
    setorigin(e, org);
    setattachment(e, NULL, "");
    setorigin(e, e.origin);
}

void follow_sameorigin(entity e, entity to)
{
    set_movetype(e, MOVETYPE_FOLLOW); // make the hole follow
    e.aiment = to; // make the hole follow bmodel
    e.punchangle = to.angles; // the original angles of bmodel
    e.view_ofs = e.origin - to.origin; // relative origin
    e.v_angle = e.angles - to.angles; // relative angles
}

#if 0
// TODO: unused, likely for a reason, possibly needs extensions (allow setting the new movetype as a parameter?)
void unfollow_sameorigin(entity e)
{
    set_movetype(e, MOVETYPE_NONE);
}
#endif

.string aiment_classname;
.float aiment_deadflag;
void SetMovetypeFollow(entity ent, entity e)
{
	set_movetype(ent, MOVETYPE_FOLLOW); // make the hole follow
	ent.solid = SOLID_NOT; // MOVETYPE_FOLLOW is always non-solid - this means this cannot be teleported by warpzones any more! Instead, we must notice when our owner gets teleported.
	ent.aiment = e; // make the hole follow bmodel
	ent.punchangle = e.angles; // the original angles of bmodel
	ent.view_ofs = ent.origin - e.origin; // relative origin
	ent.v_angle = ent.angles - e.angles; // relative angles
	ent.aiment_classname = e.classname;
	ent.aiment_deadflag = e.deadflag;

	if(IS_PLAYER(ent.aiment))
	{
		entity pl = ent.aiment;
		ent.view_ofs.x = bound(pl.mins.x + 4, ent.view_ofs.x, pl.maxs.x - 4);
		ent.view_ofs.y = bound(pl.mins.y + 4, ent.view_ofs.y, pl.maxs.y - 4);
		ent.view_ofs.z = bound(pl.mins.z + 4, ent.view_ofs.z, pl.maxs.z - 4);
	}
}

void UnsetMovetypeFollow(entity ent)
{
	set_movetype(ent, MOVETYPE_FLY);
	PROJECTILE_MAKETRIGGER(ent);
	ent.aiment_classname = string_null;
	// FIXME: engine bug?
	// resetting aiment the engine will set orb's origin close to world's origin
	//ent.aiment = NULL;
}

int LostMovetypeFollow(entity ent)
{
/*
	if(ent.move_movetype != MOVETYPE_FOLLOW)
		if(ent.aiment)
			error("???");
*/
	// FIXME: engine bug?
	// when aiment disconnects the engine will set orb's origin close to world's origin
	if(!ent.aiment)
		return 2;
	if(ent.aiment.classname != ent.aiment_classname || ent.aiment.deadflag != ent.aiment_deadflag)
		return 1;
	return 0;
}
#endif

#ifdef GAMEQC
// decolorizes and team colors the player name when needed
string playername(string thename, int teamid, bool team_colorize)
{
	TC(int, teamid);
	bool do_colorize = (teamplay && team_colorize);
#ifdef SVQC
	if(do_colorize && !intermission_running)
#else
	if(do_colorize)
#endif
    {
        string t = Team_ColorCode(teamid);
        return strcat(t, strdecolorize(thename));
    }
    else
        return thename;
}

float trace_hits_box_a0, trace_hits_box_a1;

float trace_hits_box_1d(float end, float thmi, float thma)
{
    if (end == 0)
    {
        // just check if x is in range
        if (0 < thmi)
            return false;
        if (0 > thma)
            return false;
    }
    else
    {
        // do the trace with respect to x
        // 0 -> end has to stay in thmi -> thma
        trace_hits_box_a0 = max(trace_hits_box_a0, min(thmi / end, thma / end));
        trace_hits_box_a1 = min(trace_hits_box_a1, max(thmi / end, thma / end));
        if (trace_hits_box_a0 > trace_hits_box_a1)
            return false;
    }
    return true;
}

float trace_hits_box(vector start, vector end, vector thmi, vector thma)
{
    end -= start;
    thmi -= start;
    thma -= start;
    // now it is a trace from 0 to end

    trace_hits_box_a0 = 0;
    trace_hits_box_a1 = 1;

    if (!trace_hits_box_1d(end.x, thmi.x, thma.x))
        return false;
    if (!trace_hits_box_1d(end.y, thmi.y, thma.y))
        return false;
    if (!trace_hits_box_1d(end.z, thmi.z, thma.z))
        return false;

    return true;
}

float tracebox_hits_box(vector start, vector mi, vector ma, vector end, vector thmi, vector thma)
{
    return trace_hits_box(start, end, thmi - ma, thma - mi);
}
#endif

ERASEABLE
float cvar_or(string cv, float v)
{
	string s = cvar_string(cv);
	if(s == "")
		return v;
	else
		return stof(s);
}

// NOTE base is the central value
// freq: circle frequency, = 2*pi*frequency in hertz
// start_pos:
//  -1 start from the lower value
//   0 start from the base value
//   1 start from the higher value
ERASEABLE
float blink_synced(float base, float range, float freq, float start_time, int start_pos)
{
	// note:
	//   RMS = sqrt(base^2 + 0.5 * range^2)
	// thus
	//   base = sqrt(RMS^2 - 0.5 * range^2)
	// ensure RMS == 1

	return base + range * sin((time - start_time - (M_PI / 2) * start_pos) * freq);
}

ERASEABLE
float blink(float base, float range, float freq)
{
	return blink_synced(base, range, freq, 0, 0);
}
