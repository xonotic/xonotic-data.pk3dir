#include "util.qh"

#if defined(CSQC)
    #include "../client/defs.qh"
    #include "constants.qh"
	#include "../client/mutators/events.qh"
    #include "mapinfo.qh"
    #include "notifications.qh"
    #include "deathtypes/all.qh"
#elif defined(MENUQC)
#elif defined(SVQC)
    #include "constants.qh"
    #include "../server/autocvars.qh"
    #include "../server/defs.qh"
	#include "../server/mutators/events.qh"
    #include "notifications.qh"
    #include "deathtypes/all.qh"
    #include "mapinfo.qh"
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

#ifndef MENUQC
#ifndef CSQC
void wordwrap_buffer_sprint(string s)
{SELFPARAM();
	wordwrap_buffer = strcat(wordwrap_buffer, s);
	if(s == "\n")
	{
		sprint(self, wordwrap_buffer);
		wordwrap_buffer = "";
	}
}

void wordwrap_sprint(string s, float l)
{SELFPARAM();
	wordwrap_buffer = "";
	wordwrap_cb(s, l, wordwrap_buffer_sprint);
	if(wordwrap_buffer != "")
		sprint(self, strcat(wordwrap_buffer, "\n"));
	wordwrap_buffer = "";
	return;
}
#endif
#endif

#ifndef SVQC
string draw_UseSkinFor(string pic)
{
	if(substring(pic, 0, 1) == "/")
		return substring(pic, 1, strlen(pic)-1);
	else
		return strcat(draw_currentSkin, "/", pic);
}
#endif

void wordwrap_cb(string s, float l, void(string) callback)
{
	string c;
	float lleft, i, j, wlen;

	s = strzone(s);
	lleft = l;
	for (i = 0;i < strlen(s);++i)
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
				lleft = lleft - 1;
			}
		}
		else
		{
			for (j = i+1;j < strlen(s);++j)
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
			lleft = lleft - wlen;
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

string ScoreString(int pFlags, float pValue)
{
	string valstr;
	float l;

	pValue = floor(pValue + 0.5); // round

	if((pValue == 0) && (pFlags & (SFL_HIDE_ZERO | SFL_RANK | SFL_TIME)))
		valstr = "";
	else if(pFlags & SFL_RANK)
	{
		valstr = ftos(pValue);
		l = strlen(valstr);
		if((l >= 2) && (substring(valstr, l - 2, 1) == "1"))
			valstr = strcat(valstr, "th");
		else if(substring(valstr, l - 1, 1) == "1")
			valstr = strcat(valstr, "st");
		else if(substring(valstr, l - 1, 1) == "2")
			valstr = strcat(valstr, "nd");
		else if(substring(valstr, l - 1, 1) == "3")
			valstr = strcat(valstr, "rd");
		else
			valstr = strcat(valstr, "th");
	}
	else if(pFlags & SFL_TIME)
		valstr = TIME_ENCODED_TOSTRING(pValue);
	else
		valstr = ftos(pValue);

	return valstr;
}

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

float invertLengthLog(float x)
{
	int l, r, m;

	if(x >= lengthLogTable[127])
		return 127;
	if(x <= lengthLogTable[0])
		return 0;

	l = 0;
	r = 127;

	while(r - l > 1)
	{
		m = floor((l + r) / 2);
		if(lengthLogTable[m] < x)
			l = m;
		else
			r = m;
	}

	// now: r is >=, l is <
	float lerr = (x - lengthLogTable[l]);
	float rerr = (lengthLogTable[r] - x);
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
	float y	= (data & 0x0F80) / 0x80;
	int len = (data & 0x007F);

	//print("\ndecompress: p ", ftos(p)); print("y ", ftos(y)); print("len ", ftos(len), "\n");

	if(p == 0)
	{
		out.x = 0;
		out.y = 0;
		if(y == 31)
			out.z = -1;
		else
			out.z = +1;
	}
	else
	{
		y   = .19634954084936207740 * y;
		p = .19634954084936207740 * p - 1.57079632679489661922;
		out.x = cos(y) *  cos(p);
		out.y = sin(y) *  cos(p);
		out.z =          -sin(p);
	}

	//print("decompressed: ", vtos(out), "\n");

	return out * lengthLogTable[len];
}

float compressShortVector(vector vec)
{
	vector ang;
	float p, y, len;
	if(vlen(vec) == 0)
		return 0;
	//print("compress: ", vtos(vec), "\n");
	ang = vectoangles(vec);
	ang.x = -ang.x;
	if(ang.x < -90)
		ang.x += 360;
	if(ang.x < -90 && ang.x > +90)
		error("BOGUS vectoangles");
	//print("angles: ", vtos(ang), "\n");

	p = floor(0.5 + (ang.x + 90) * 16 / 180) & 15; // -90..90 to 0..14
	if(p == 0)
	{
		if(vec.z < 0)
			y = 31;
		else
			y = 30;
	}
	else
		y = floor(0.5 + ang.y * 32 / 360)          & 31; // 0..360 to 0..32
	len = invertLengthLog(vlen(vec));

	//print("compressed: p ", ftos(p)); print("y ", ftos(y)); print("len ", ftos(len), "\n");

	return (p * 0x1000) + (y * 0x80) + len;
}

void compressShortVector_init()
{
	float l = 1;
	float f = pow(2, 1/8);
	int i;
	for(i = 0; i < 128; ++i)
	{
		lengthLogTable[i] = l;
		l *= f;
	}

	if(cvar("developer"))
	{
		LOG_INFO("Verifying vector compression table...\n");
		for(i = 0x0F00; i < 0xFFFF; ++i)
			if(i != compressShortVector(decompressShortVector(i)))
			{
				LOG_INFO("BROKEN vector compression: ", ftos(i));
				LOG_INFO(" -> ", vtos(decompressShortVector(i)));
				LOG_INFO(" -> ", ftos(compressShortVector(decompressShortVector(i))));
				LOG_INFO("\n");
				error("b0rk");
			}
		LOG_INFO("Done.\n");
	}
}

#ifndef MENUQC
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
	float i, n;

	n = tokenize_console(order);
	neworder = "";
	for(i = 0; i < n; ++i)
		neworder = strcat(neworder, mapfunc(argv(i)), " ");

	return substring(neworder, 0, strlen(neworder) - 1);
}

string swapInPriorityList(string order, float i, float j)
{
	string s;
	float w, n;

	n = tokenize_console(order);

	if(i >= 0 && i < n && j >= 0 && j < n && i != j)
	{
		s = "";
		for(w = 0; w < n; ++w)
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

#ifndef MENUQC
void get_mi_min_max(float mode)
{
	vector mi, ma;

	if(mi_shortname)
		strunzone(mi_shortname);
	mi_shortname = mapname;
	if(!strcasecmp(substring(mi_shortname, 0, 5), "maps/"))
		mi_shortname = substring(mi_shortname, 5, strlen(mi_shortname) - 5);
	if(!strcasecmp(substring(mi_shortname, strlen(mi_shortname) - 4, 4), ".bsp"))
		mi_shortname = substring(mi_shortname, 0, strlen(mi_shortname) - 4);
	mi_shortname = strzone(mi_shortname);

#ifdef CSQC
	mi = world.mins;
	ma = world.maxs;
#else
	mi = world.absmin;
	ma = world.absmax;
#endif

	mi_min = mi;
	mi_max = ma;
	MapInfo_Get_ByName(mi_shortname, 0, 0);
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
					 world);
			if(!trace_startsolid)
				mi_min.x = trace_endpos.x;

			tracebox('0 1 0' * mi.y,
					 '1 0 0' * mi.x + '0 0 1' * mi.z,
					 '1 0 0' * ma.x + '0 0 1' * ma.z,
					 '0 1 0' * ma.y,
					 MOVE_WORLDONLY,
					 world);
			if(!trace_startsolid)
				mi_min.y = trace_endpos.y;

			tracebox('0 0 1' * mi.z,
					 '1 0 0' * mi.x + '0 1 0' * mi.y,
					 '1 0 0' * ma.x + '0 1 0' * ma.y,
					 '0 0 1' * ma.z,
					 MOVE_WORLDONLY,
					 world);
			if(!trace_startsolid)
				mi_min.z = trace_endpos.z;

			tracebox('1 0 0' * ma.x,
					 '0 1 0' * mi.y + '0 0 1' * mi.z,
					 '0 1 0' * ma.y + '0 0 1' * ma.z,
					 '1 0 0' * mi.x,
					 MOVE_WORLDONLY,
					 world);
			if(!trace_startsolid)
				mi_max.x = trace_endpos.x;

			tracebox('0 1 0' * ma.y,
					 '1 0 0' * mi.x + '0 0 1' * mi.z,
					 '1 0 0' * ma.x + '0 0 1' * ma.z,
					 '0 1 0' * mi.y,
					 MOVE_WORLDONLY,
					 world);
			if(!trace_startsolid)
				mi_max.y = trace_endpos.y;

			tracebox('0 0 1' * ma.z,
					 '1 0 0' * mi.x + '0 1 0' * mi.y,
					 '1 0 0' * ma.x + '0 1 0' * ma.y,
					 '0 0 1' * mi.z,
					 MOVE_WORLDONLY,
					 world);
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
	entity e;

	created_saved_value = 0;

	if (!(tmp_cvar || tmp_value))
	{
		LOG_TRACE("Error: Invalid usage of cvar_settemp(string, string); !\n");
		return 0;
	}

	if(!cvar_type(tmp_cvar))
	{
		LOG_INFOF("Error: cvar %s doesn't exist!\n", tmp_cvar);
		return 0;
	}

	for(e = world; (e = find(e, classname, "saved_cvar_value")); )
		if(e.netname == tmp_cvar)
			created_saved_value = -1; // skip creation

	if(created_saved_value != -1)
	{
		// creating a new entity to keep track of this cvar
		e = new(saved_cvar_value);
		make_pure(e);
		e.netname = strzone(tmp_cvar);
		e.message = strzone(cvar_string(tmp_cvar));
		created_saved_value = 1;
	}

	// update the cvar to the value given
	cvar_set(tmp_cvar, tmp_value);

	return created_saved_value;
}

float cvar_settemp_restore()
{
	float i = 0;
	entity e = world;
	while((e = find(e, classname, "saved_cvar_value")))
	{
		if(cvar_type(e.netname))
		{
			cvar_set(e.netname, e.message);
			strunzone(e.netname);
			strunzone(e.message);
			remove(e);
			++i;
		}
		else
			LOG_INFOF("Error: cvar %s doesn't exist anymore! It can still be restored once it's manually recreated.\n", e.netname);
	}

	return i;
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

	// binary search for right place to cut string
	float ch;
	float left, right, middle; // this always works
	left = 0;
	right = strlen(theText); // this always fails
	do
	{
		middle = floor((left + right) / 2);
		if(w(substring(theText, 0, middle), theSize) <= maxWidth)
			left = middle;
		else
			right = middle;
	}
	while(left < right - 1);

	if(w("^7", theSize) == 0) // detect color codes support in the width function
	{
		// NOTE: when color codes are involved, this binary search is,
		// mathematically, BROKEN. However, it is obviously guaranteed to
		// terminate, as the range still halves each time - but nevertheless, it is
		// guaranteed that it finds ONE valid cutoff place (where "left" is in
		// range, and "right" is outside).

		// terencehill: the following code detects truncated ^xrgb tags (e.g. ^x or ^x4)
		// and decrease left on the basis of the chars detected of the truncated tag
		// Even if the ^xrgb tag is not complete/correct, left is decreased
		// (sometimes too much but with a correct result)
		// it fixes also ^[0-9]
		while(left >= 1 && substring(theText, left-1, 1) == "^")
			left-=1;

		if (left >= 2 && substring(theText, left-2, 2) == "^x") // ^x/
			left-=2;
		else if (left >= 3 && substring(theText, left-3, 2) == "^x")
			{
				ch = str2chr(theText, left-1);
				if( (ch >= '0' && ch <= '9') || (ch >= 'a' && ch <= 'f') || (ch >= 'A' && ch <= 'F') ) // ^xr/
					left-=3;
			}
		else if (left >= 4 && substring(theText, left-4, 2) == "^x")
			{
				ch = str2chr(theText, left-2);
				if ( (ch >= '0' && ch <= '9') || (ch >= 'a' && ch <= 'f') || (ch >= 'A' && ch <= 'F') )
				{
					ch = str2chr(theText, left-1);
					if ( (ch >= '0' && ch <= '9') || (ch >= 'a' && ch <= 'f') || (ch >= 'A' && ch <= 'F') ) // ^xrg/
						left-=4;
				}
			}
	}

	return left;
}

float textLengthUpToLength(string theText, float maxWidth, textLengthUpToLength_lenFunction_t w)
{
	// STOP.
	// The following function is SLOW.
	// For your safety and for the protection of those around you...
	// DO NOT CALL THIS AT HOME.
	// No really, don't.
	if(w(theText) <= maxWidth)
		return strlen(theText); // yeah!

	// binary search for right place to cut string
	float ch;
	float left, right, middle; // this always works
	left = 0;
	right = strlen(theText); // this always fails
	do
	{
		middle = floor((left + right) / 2);
		if(w(substring(theText, 0, middle)) <= maxWidth)
			left = middle;
		else
			right = middle;
	}
	while(left < right - 1);

	if(w("^7") == 0) // detect color codes support in the width function
	{
		// NOTE: when color codes are involved, this binary search is,
		// mathematically, BROKEN. However, it is obviously guaranteed to
		// terminate, as the range still halves each time - but nevertheless, it is
		// guaranteed that it finds ONE valid cutoff place (where "left" is in
		// range, and "right" is outside).

		// terencehill: the following code detects truncated ^xrgb tags (e.g. ^x or ^x4)
		// and decrease left on the basis of the chars detected of the truncated tag
		// Even if the ^xrgb tag is not complete/correct, left is decreased
		// (sometimes too much but with a correct result)
		// it fixes also ^[0-9]
		while(left >= 1 && substring(theText, left-1, 1) == "^")
			left-=1;

		if (left >= 2 && substring(theText, left-2, 2) == "^x") // ^x/
			left-=2;
		else if (left >= 3 && substring(theText, left-3, 2) == "^x")
			{
				ch = str2chr(theText, left-1);
				if( (ch >= '0' && ch <= '9') || (ch >= 'a' && ch <= 'f') || (ch >= 'A' && ch <= 'F') ) // ^xr/
					left-=3;
			}
		else if (left >= 4 && substring(theText, left-4, 2) == "^x")
			{
				ch = str2chr(theText, left-2);
				if ( (ch >= '0' && ch <= '9') || (ch >= 'a' && ch <= 'f') || (ch >= 'A' && ch <= 'F') )
				{
					ch = str2chr(theText, left-1);
					if ( (ch >= '0' && ch <= '9') || (ch >= 'a' && ch <= 'f') || (ch >= 'A' && ch <= 'F') ) // ^xrg/
						left-=4;
				}
			}
	}

	return left;
}

string find_last_color_code(string s)
{
	int start = strstrofs(s, "^", 0);
	if (start == -1) // no caret found
		return "";
	int len = strlen(s)-1;
	int i;
	for(i = len; i >= start; --i)
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
			if(strstrofs("0123456789", substring(s, i+1, 1), 0) >= 0)
				return substring(s, i, 2);

			if(i+4 <= len)
			if(substring(s, i+1, 1) == "x")
			if(strstrofs("0123456789abcdefABCDEF", substring(s, i+2, 1), 0) >= 0)
			if(strstrofs("0123456789abcdefABCDEF", substring(s, i+3, 1), 0) >= 0)
			if(strstrofs("0123456789abcdefABCDEF", substring(s, i+4, 1), 0) >= 0)
				return substring(s, i, 5);
		}
		i -= carets; // this also skips one char before the carets
	}

	return "";
}

string getWrappedLine(float w, vector theFontSize, textLengthUpToWidth_widthFunction_t tw)
{
	float cantake;
	float take;
	string s;

	s = getWrappedLine_remaining;

	if(w <= 0)
	{
		getWrappedLine_remaining = string_null;
		return s; // the line has no size ANYWAY, nothing would be displayed.
	}

	cantake = textLengthUpToWidth(s, w, theFontSize, tw);
	if(cantake > 0 && cantake < strlen(s))
	{
		take = cantake - 1;
		while(take > 0 && substring(s, take, 1) != " ")
			--take;
		if(take == 0)
		{
			getWrappedLine_remaining = substring(s, cantake, strlen(s) - cantake);
			if(getWrappedLine_remaining == "")
				getWrappedLine_remaining = string_null;
			else if (tw("^7", theFontSize) == 0)
				getWrappedLine_remaining = strcat(find_last_color_code(substring(s, 0, cantake)), getWrappedLine_remaining);
			return substring(s, 0, cantake);
		}
		else
		{
			getWrappedLine_remaining = substring(s, take + 1, strlen(s) - take);
			if(getWrappedLine_remaining == "")
				getWrappedLine_remaining = string_null;
			else if (tw("^7", theFontSize) == 0)
				getWrappedLine_remaining = strcat(find_last_color_code(substring(s, 0, take)), getWrappedLine_remaining);
			return substring(s, 0, take);
		}
	}
	else
	{
		getWrappedLine_remaining = string_null;
		return s;
	}
}

string getWrappedLineLen(float w, textLengthUpToLength_lenFunction_t tw)
{
	float cantake;
	float take;
	string s;

	s = getWrappedLine_remaining;

	if(w <= 0)
	{
		getWrappedLine_remaining = string_null;
		return s; // the line has no size ANYWAY, nothing would be displayed.
	}

	cantake = textLengthUpToLength(s, w, tw);
	if(cantake > 0 && cantake < strlen(s))
	{
		take = cantake - 1;
		while(take > 0 && substring(s, take, 1) != " ")
			--take;
		if(take == 0)
		{
			getWrappedLine_remaining = substring(s, cantake, strlen(s) - cantake);
			if(getWrappedLine_remaining == "")
				getWrappedLine_remaining = string_null;
			else if (tw("^7") == 0)
				getWrappedLine_remaining = strcat(find_last_color_code(substring(s, 0, cantake)), getWrappedLine_remaining);
			return substring(s, 0, cantake);
		}
		else
		{
			getWrappedLine_remaining = substring(s, take + 1, strlen(s) - take);
			if(getWrappedLine_remaining == "")
				getWrappedLine_remaining = string_null;
			else if (tw("^7") == 0)
				getWrappedLine_remaining = strcat(find_last_color_code(substring(s, 0, take)), getWrappedLine_remaining);
			return substring(s, 0, take);
		}
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

float isGametypeInFilter(float gt, float tp, float ts, string pattern)
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

float compressShotOrigin(vector v)
{
	float x, y, z;
	x = rint(v.x * 2);
	y = rint(v.y * 4) + 128;
	z = rint(v.z * 4) + 128;
	if(x > 255 || x < 0)
	{
		LOG_INFO("shot origin ", vtos(v), " x out of bounds\n");
		x = bound(0, x, 255);
	}
	if(y > 255 || y < 0)
	{
		LOG_INFO("shot origin ", vtos(v), " y out of bounds\n");
		y = bound(0, y, 255);
	}
	if(z > 255 || z < 0)
	{
		LOG_INFO("shot origin ", vtos(v), " z out of bounds\n");
		z = bound(0, z, 255);
	}
	return x * 0x10000 + y * 0x100 + z;
}
vector decompressShotOrigin(int f)
{
	vector v;
	v.x = ((f & 0xFF0000) / 0x10000) / 2;
	v.y = ((f & 0xFF00) / 0x100 - 128) / 4;
	v.z = ((f & 0xFF) - 128) / 4;
	return v;
}

#ifndef MENUQC
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
		}
	}
	return r;
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

#ifndef MENUQC
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
			get_model_parameters_sex = s;
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
	#ifndef MENUQC
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
		LOG_INFO("Recursive shutdown detected! Only restoring cvars...\n");
	}
	else
	{
		shutdown_running = 1;
		Shutdown();
		shutdownhooks();
	}
	cvar_settemp_restore(); // this must be done LAST, but in any case
}

#ifndef MENUQC
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
		strunzone(to_execute_next_frame);
		to_execute_next_frame = string_null;
	}
}
void queue_to_execute_next_frame(string s)
{
	if(to_execute_next_frame)
	{
		s = strcat(s, "\n", to_execute_next_frame);
		strunzone(to_execute_next_frame);
	}
	to_execute_next_frame = strzone(s);
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
	queue_end.(fld) = world;
	queue_end.FindConnectedComponent_processing = 1;

	// for each queued item:
	for (; queue_start; queue_start = queue_start.(fld))
	{
		// find all neighbors of queue_start
		entity t;
		for(t = world; (t = nxt(t, queue_start, pass)); )
		{
			if(t.FindConnectedComponent_processing)
				continue;
			if(iscon(t, queue_start, pass))
			{
				// it is connected? ADD IT. It will look for neighbors soon too.
				queue_end.(fld) = t;
				queue_end = t;
				queue_end.(fld) = world;
				queue_end.FindConnectedComponent_processing = 1;
			}
		}
	}

	// unmark
	for (queue_start = e; queue_start; queue_start = queue_start.(fld))
		queue_start.FindConnectedComponent_processing = 0;
}

#ifndef MENUQC
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

#ifdef SVQC
void dedicated_print(string input) // print(), but only print if the server is not local
{
	if(server_is_dedicated) { LOG_INFO(input); }
}
#endif

#ifndef MENUQC
float Announcer_PickNumber(float type, float num)
{
	switch(type)
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
		case CNT_IDLE:
		{
			switch(num)
			{
				case 10: return ANNCE_NUM_IDLE_10;
				case 9:  return ANNCE_NUM_IDLE_9;
				case 8:  return ANNCE_NUM_IDLE_8;
				case 7:  return ANNCE_NUM_IDLE_7;
				case 6:  return ANNCE_NUM_IDLE_6;
				case 5:  return ANNCE_NUM_IDLE_5;
				case 4:  return ANNCE_NUM_IDLE_4;
				case 3:  return ANNCE_NUM_IDLE_3;
				case 2:  return ANNCE_NUM_IDLE_2;
				case 1:  return ANNCE_NUM_IDLE_1;
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
	return NOTIF_ABORT; // abort sending if none of these numbers were right
}
#endif

#ifndef MENUQC
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
