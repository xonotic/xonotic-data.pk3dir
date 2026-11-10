#include "slider_resolution.qh"

/* private static */ bool XonoticResolutionSlider_DataHasChanged;
/* attrib */ float vid_conwidth;
/* attrib */ float vid_conheight;

/// Updates cvars (to be called by menu.qc at startup or on detected res change)
bool updateConwidths(float width, float height, float pixelheight)
{
	float sz = cvar("menu_vid_scale");
	if (sz < -1)
		return false; // no recalculation

	// Save current settings
	cvar_set("_menu_vid_width", ftos(width));
	cvar_set("_menu_vid_height", ftos(height));
	cvar_set("_menu_vid_pixelheight", ftos(pixelheight));
	cvar_set("_menu_vid_desktopfullscreen", cvar_string("vid_desktopfullscreen"));

	// engine is handling conwidth calculations!
	if ((cvar_type("vid_conwidthauto") & CVAR_TYPEFLAG_ENGINE) && cvar("vid_conwidthauto"))
	{
		if (vid_conwidth  != cvar("vid_conwidth")
		||  vid_conheight != cvar("vid_conheight"))
		{
			// Please reload resolutions list and such stuff.
			XonoticResolutionSlider_DataHasChanged = true;
			vid_conwidth = cvar("vid_conwidth");
			vid_conheight = cvar("vid_conheight");
			return true;
		}
		return false; // no recalculation
	}

	vector r;
	r.x = width;
	r.y = height;
	r.z = pixelheight;

	// calculate the base resolution
	vector c;
	c.z = 0;
	c.x = 800;
	c.y = c.x * r.y * r.z / r.x;
	if (c.y < 600)
	{
		c.y = 600;
		c.x = c.y * r.x / (r.y * r.z);
	}

	float f = min(r.x / c.x, r.y / c.y);
	if (f < 1)
		c *= f; // ensures that c.x <= r.x and c.y <= r.y

	float minfactor = min(1, 640 / c.x);            // can be > 1 only if c_x is <640
	float maxfactor = max(1, r.x / c.x, r.y / c.y); // can be < 1 only if r_x < c_x and r_y < c_y
	LOG_TRACE("min factor: ", ftos(minfactor));
	LOG_TRACE("max factor: ", ftos(maxfactor));

	if (sz < 0)
		f = 1 - (maxfactor - 1) * sz;
	else if (sz > 0)
		f = 1 + (minfactor - 1) * sz;
	else
		f = 1;
	c *= f; // fteqcc fail

	c.x = rint(c.x);
	c.y = rint(c.y);

	// Please reload resolutions list and such stuff.
	XonoticResolutionSlider_DataHasChanged = true;

	if (c.x != cvar("vid_conwidth")
	||  c.y != cvar("vid_conheight"))
	{
		cvar_set("vid_conwidth",  ftos(c.x));
		cvar_set("vid_conheight", ftos(c.y));
		return 1;
	}
	return 0;
}

entity makeXonoticResolutionSlider()
{
	entity me = NEW(XonoticResolutionSlider);
	me.configureXonoticResolutionSlider(me);
	return me;
}

void XonoticResolutionSlider_addResolution(entity me, float w, float h, float pixelheight)
{
	if ((me.maxAllowedWidth  && w > me.maxAllowedWidth)
	||  (me.maxAllowedHeight && h > me.maxAllowedHeight))
		return;

	int i;
	float option_w, option_h, option_pixelheight;
	for (i = 0; i < me.nValues; ++i)
	{
		tokenize_console(me.valueToIdentifier(me, i));
		option_w = stof(argv(0));
		if (w > option_w) continue;
		if (w < option_w) break;
		option_h = stof(argv(1));
		if (h > option_h) continue;
		if (h < option_h) break;
		option_pixelheight = stof(argv(2));
		if (pixelheight > option_pixelheight + 0.01) continue;
		if (pixelheight < option_pixelheight - 0.01) break;
		return; // already there
	}
	string text = sprintf("%dx%d", w, h);
	if (pixelheight != 1)
	{
		float aspect = w / (h * pixelheight);
		float bestdenom = rint(aspect);
		float bestnum = 1;
		for (float num, denom = 2; denom < 10; ++denom)
		{
			num = rint(aspect * denom);
			if (fabs(num / denom - aspect) < fabs(bestnum / bestdenom - aspect))
			{
				bestnum = num;
				bestdenom = denom;
			}
		}
		text = strcat(text, sprintf(_(" (%s)"), sprintf("%d:%d", bestnum, bestdenom)));
	}
	me.insertValue(me, i, strzone(text), strzone(strcat(ftos(w), " ", ftos(h), " ", ftos(pixelheight))));
}

void XonoticResolutionSlider_configureXonoticResolutionSlider(entity me)
{
	me.configureXonoticTextSlider(me, "_menu_vid_width", _("Screen resolution"));
	me.vid_fullscreen = cvar("vid_fullscreen");
	me.rebuildValues(me);
}

float autocvar_menu_vid_allowdualscreenresolution;
void XonoticResolutionSlider_rebuildValues(entity me)
{
	// HACK: TextSlider assumes the strings are constants, so clearValues will not unzone them
	float i;
	for (i = 0; i < me.nValues; ++i)
	{
		strunzone(me.valueToIdentifier(me, i));
		strunzone(me.valueToText(me, i));
	}
	// NOW we can safely clear.
	me.clearValues(me);
	me.maxAllowedWidth = 0;
	me.maxAllowedHeight = 0;

	vector r;
	if (me.vid_fullscreen)
	{
		for (i = 0; ; ++i)
		{
			r = getresolution(i);
			if (r.x == 0 && r.y == 0)
				break;
			if (r.x < 640 || r.y < 480)
				continue;
			if (r.x > 2 * r.y // likely dualscreen resolution, skip this one
			&& autocvar_menu_vid_allowdualscreenresolution <= 0)
				continue;
			me.addResolution(me, r.x, r.y, r.z);
		}
		r = getresolution(-1);
		if (r.x != 0 || r.y != 0)
			me.addResolution(me, r.x, r.y, r.z);
		LOG_TRACE("Added system resolutions.");
	}

	if (me.nValues == 0)
	{
		// Get workarea.
		r = getresolution(-2);
		// If workarea is not supported, get desktop size.
		if (r.x == 0 && r.y == 0)
			r = getresolution(-1);

		// Add it, and limit all other resolutions to the workarea/desktop size.
		if (r.x != 0 || r.y != 0)
		{
			me.maxAllowedWidth = r.x;
			me.maxAllowedHeight = r.y;
			me.addResolution(me, r.x, r.y, r.z);
		}

		// Add nice hardcoded defaults.
		me.addResolution(me, 640, 480, 1); // pc res
#if 0
		me.addResolution(me, 720, 480, 1.125); // DVD NTSC 4:3
		me.addResolution(me, 720, 576, 0.9375); // DVD PAL 4:3
		me.addResolution(me, 720, 480, 0.84375); // DVD NTSC 16:9
		me.addResolution(me, 720, 576, 0.703125); // DVD PAL 16:9
#endif
		me.addResolution(me, 800, 480, 1); // 480p at 1:1 pixel aspect
		me.addResolution(me, 800, 600, 1); // pc res
		me.addResolution(me, 1024, 600, 1); // notebook res
		me.addResolution(me, 1024, 768, 1); // pc res
		me.addResolution(me, 1280, 720, 1); // 720p
		me.addResolution(me, 1280, 960, 1); // pc res
		me.addResolution(me, 1280, 1024, 1); // pc res
		me.addResolution(me, 1920, 1080, 1); // 1080p
		LOG_TRACE("Added default resolutions.");
	}
	LOG_TRACE("Total number of resolutions detected: ", itos(me.nValues));

	me.configureXonoticTextSliderValues(me); // calls .loadCvars
}

void XonoticResolutionSlider_loadCvars(entity me)
{
	me.setValueFromIdentifier(me, strcat(cvar_string("_menu_vid_width"), " ", cvar_string("_menu_vid_height"), " ", cvar_string("_menu_vid_pixelheight")), false);
}
void XonoticResolutionSlider_saveCvars(entity me)
{
	if (me.value >= 0 || me.value < me.nValues)
	{
		tokenize_console(me.getIdentifier(me));
		cvar_set("_menu_vid_width", argv(0));
		cvar_set("_menu_vid_height", argv(1));
		cvar_set("_menu_vid_pixelheight", argv(2));
		vector r = getresolution(-1);
		if (stof(argv(0)) == r.x && stof(argv(1)) == r.y && fabs(stof(argv(2)) - r.z) < 0.01)
			cvar_set("_menu_vid_desktopfullscreen", "1");
		else
			cvar_set("_menu_vid_desktopfullscreen", "0");
	}
}

void XonoticResolutionSlider_draw(entity me)
{
	bool fullscreen = cvar("vid_fullscreen");
	if (fullscreen != me.vid_fullscreen)
	{
		me.vid_fullscreen = fullscreen;
		me.rebuildValues(me);
		XonoticResolutionSlider_DataHasChanged = true;
	}
	if (XonoticResolutionSlider_DataHasChanged)
	{
		XonoticResolutionSlider_DataHasChanged = false;
		me.loadCvars(me);
	}
	SUPER(XonoticResolutionSlider).draw(me);
}
