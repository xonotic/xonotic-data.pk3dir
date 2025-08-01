#include "slider_resolution.qh"

/* private static */ float XonoticResolutionSlider_DataHasChanged;
/* attrib */ float vid_conwidth;
/* attrib */ float vid_conheight;

// Updates cvars (to be called by menu.qc at startup or on detected res change)
float updateConwidths(float width, float height, float pixelheight)
{
	vector r, c;
	float minfactor, maxfactor;
	float sz, f;

	sz = cvar("menu_vid_scale");
	if (sz < -1)
		return 0;  // No recalculation.

	// Save off current settings.
	cvar_set("_menu_vid_width", ftos(width));
	cvar_set("_menu_vid_height", ftos(height));
	cvar_set("_menu_vid_pixelheight", ftos(pixelheight));
	cvar_set("_menu_vid_desktopfullscreen", cvar_string("vid_desktopfullscreen"));

	// engine is handling conwidth calculations!
	if((cvar_type("vid_conwidthauto") & CVAR_TYPEFLAG_ENGINE) && cvar("vid_conwidthauto"))
	{
		if(vid_conwidth != cvar("vid_conwidth") || vid_conheight != cvar("vid_conheight"))
		{
			// Please reload resolutions list and such stuff.
			XonoticResolutionSlider_DataHasChanged = true;
			vid_conwidth = cvar("vid_conwidth");
			vid_conheight = cvar("vid_conheight");
			return 1;
		}
		return 0; // No recalculation
	}

	r_x = width;
	r_y = height;
	r_z = pixelheight;

	// calculate the base resolution
	c_z = 0;
	c_x = 800;
	c_y = c.x * r.y * r.z / r.x;
	if(c.y < 600)
	{
		c_y = 600;
		c_x = c.y * r.x / (r.y * r.z);
	}

	f = min(r.x / c.x, r.y / c.y);
	if(f < 1)
		c = c * f; // ensures that c_x <= r_x and c_y <= r_y

	minfactor = min(1, 640 / c.x);            // can be > 1 only if c_x is <640
	maxfactor = max(1, r.x / c.x, r.y / c.y); // can be < 1 only if r_x < c_x and r_y < c_y
	LOG_TRACE("min factor: ", ftos(minfactor));
	LOG_TRACE("max factor: ", ftos(maxfactor));

	if(sz < 0)
		f = 1 - (maxfactor - 1) * sz;
	else if(sz > 0)
		f = 1 + (minfactor - 1) * sz;
	else
		f = 1;
	c = c * f; // fteqcc fail

	c_x = rint(c.x);
	c_y = rint(c.y);

	// Please reload resolutions list and such stuff.
	XonoticResolutionSlider_DataHasChanged = true;

	if (c.x != cvar("vid_conwidth") || c.y != cvar("vid_conheight"))
	{
		cvar_set("vid_conwidth", ftos(c.x));
		cvar_set("vid_conheight", ftos(c.y));
		return 1;
	}
	return 0;
}
entity makeXonoticResolutionSlider()
{
	entity me;
	me = NEW(XonoticResolutionSlider);
	me.configureXonoticResolutionSlider(me);
	return me;
}
void XonoticResolutionSlider_addResolution(entity me, float w, float h, float pixelheight)
{
	if (me.maxAllowedWidth && w > me.maxAllowedWidth)
		return;
	if (me.maxAllowedHeight && h > me.maxAllowedHeight)
		return;
	float i;
	for (i = 0; i < me.nValues; ++i)
	{
		tokenize_console(me.valueToIdentifier(me, i));
		if (w > stof(argv(0))) continue;
		if (w < stof(argv(0))) break;
		if (h > stof(argv(1))) continue;
		if (h < stof(argv(1))) break;
		if (pixelheight > stof(argv(2)) + 0.01) continue;
		if (pixelheight < stof(argv(2)) - 0.01) break;
		return;  // already there
	}
	if (pixelheight != 1)
	{
		float aspect = w / (h * pixelheight);
		float bestdenom = rint(aspect);
		float bestnum = 1;
		float denom;
		for (denom = 2; denom < 10; ++denom) {
			float num = rint(aspect * denom);
			if (fabs(num / denom - aspect) < fabs(bestnum / bestdenom - aspect))
			{
				bestnum = num;
				bestdenom = denom;
			}
		}
		me.insertValue(me, i, strzone(sprintf("%dx%d (%d:%d)", w, h, bestnum, bestdenom)), strzone(strcat(ftos(w), " ", ftos(h), " ", ftos(pixelheight))));
	}
	else
		me.insertValue(me, i, strzone(sprintf("%dx%d", w, h)), strzone(strcat(ftos(w), " ", ftos(h), " ", ftos(pixelheight))));
}
float autocvar_menu_vid_allowdualscreenresolution;
void XonoticResolutionSlider_configureXonoticResolutionSlider(entity me)
{
	me.configureXonoticTextSlider(me, "_menu_vid_width",
		_("Screen resolution"));
	me.loadResolutions(me, cvar("vid_fullscreen"));
}
void XonoticResolutionSlider_loadResolutions(entity me, float fullscreen)
{
	float i;
	vector r;

	// HACK: text slider assumes the strings are constants, so clearValues
	// will not unzone them
	for(i = 0; i < me.nValues; ++i)
	{
		strunzone(me.valueToIdentifier(me, i));
		strunzone(me.valueToText(me, i));
	}
	// NOW we can safely clear.
	me.clearValues(me);
	me.maxAllowedWidth = 0;
	me.maxAllowedHeight = 0;

	if (fullscreen)
	{
		for(i = 0;; ++i)
		{
			r = getresolution(i);
			if(r_x == 0 && r_y == 0)
				break;
			if(r.x < 640 || r.y < 480)
				continue;
			if(r.x > 2 * r.y) // likely dualscreen resolution, skip this one
				if(autocvar_menu_vid_allowdualscreenresolution <= 0)
					continue;
			me.addResolution(me, r.x, r.y, r.z);
		}
		r = getresolution(-1);
		if(r.x != 0 || r.y != 0)
			me.addResolution(me, r.x, r.y, r.z);
		LOG_TRACE("Added system resolutions.");
	}

	if(me.nValues == 0)
	{
		// Get workarea.
		r = getresolution(-2);
		// If workarea is not supported, get desktop size.
		if(r.x == 0 && r.y == 0)
			r = getresolution(-1);

		// Add it, and limit all other resolutions to the workarea/desktop size.
		if(r.x != 0 || r.y != 0)
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
	LOG_TRACE("Total number of resolutions detected: ", ftos(me.nValues));

	me.vid_fullscreen = fullscreen;

	me.configureXonoticTextSliderValues(me);
}
void XonoticResolutionSlider_loadCvars(entity me)
{
	me.setValueFromIdentifier(me, strcat(cvar_string("_menu_vid_width"), " ", cvar_string("_menu_vid_height"), " ", cvar_string("_menu_vid_pixelheight")), false);
}
void XonoticResolutionSlider_saveCvars(entity me)
{
	if(me.value >= 0 || me.value < me.nValues)
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
	if (cvar("vid_fullscreen") != me.vid_fullscreen)
	{
		me.loadResolutions(me, cvar("vid_fullscreen"));
		XonoticResolutionSlider_DataHasChanged = true;
	}
	if (XonoticResolutionSlider_DataHasChanged)
	{
		XonoticResolutionSlider_DataHasChanged = false;
		me.loadCvars(me);
	}
	SUPER(XonoticResolutionSlider).draw(me);
}
