#include "menu.qh"
#include "oo/classes.qc"
#include "xonotic/util.qh"

#include "../common/items/all.qh"
#include "../common/weapons/all.qh"
#include "../common/mapinfo.qh"
#include "../common/mutators/base.qh"

///////////////////////////////////////////////
// Menu Source File
///////////////////////
// This file belongs to dpmod/darkplaces
// AK contains all menu functions (especially the required ones)
///////////////////////////////////////////////

float mouseButtonsPressed;
vector menuMousePos;
int menuShiftState;
float menuPrevTime;
float menuAlpha;
float menuLogoAlpha;
float prevMenuAlpha;
float menuInitialized;
float menuNotTheFirstFrame;
float menuMouseMode;

float conwidth_s, conheight_s, vidwidth_s, vidheight_s, vidpixelheight_s,
      realconwidth, realconheight;

void m_sync()
{
	updateCompression();
	vidwidth_s = vidheight_s = vidpixelheight_s = 0;  // Force updateConwidths on next draw.

	loadAllCvars(main);
}

void m_gamestatus()
{
	gamestatus = 0;
	if(isserver())
		gamestatus = gamestatus | GAME_ISSERVER;
	if(clientstate() == CS_CONNECTED || isdemo())
		gamestatus = gamestatus | GAME_CONNECTED;
	if(cvar("developer"))
		gamestatus = gamestatus | GAME_DEVELOPER;
}

void m_init()
{
	float restarting = 0;
	cvar_set("_menu_alpha", "0");
	prvm_language = cvar_string("prvm_language");
	if(prvm_language == "")
	{
		prvm_language = "en";
		cvar_set("prvm_language", prvm_language);
		localcmd("\nmenu_restart\n");
		restarting = 1;
	}
	prvm_language = strzone(prvm_language);
	cvar_set("_menu_prvm_language", prvm_language);

#ifdef WATERMARK
	LOG_TRACEF("^4MQC Build information: ^1%s\n", WATERMARK);
#endif

	// list all game dirs (TEST)
	if(cvar("developer"))
	{
		float i;
		string s;
		for(i = 0; ; ++i)
		{
			s = getgamedirinfo(i, GETGAMEDIRINFO_NAME);
			if (!s)
				break;
			LOG_TRACE(s, ": ", getgamedirinfo(i, GETGAMEDIRINFO_DESCRIPTION));
		}
	}

	// needs to be done so early because of the constants they create
	static_init();

	RegisterSLCategories();

	float ddsload = cvar("r_texture_dds_load");
	float texcomp = cvar("gl_texturecompression");
	updateCompression();
	if(ddsload != cvar("r_texture_dds_load") || texcomp != cvar("gl_texturecompression"))
		localcmd("\nr_restart\n");

	if(!restarting)
	{
		if(cvar("_menu_initialized")) // always show menu after menu_restart
			m_display();
		else
			m_hide();
		cvar_set("_menu_initialized", "1");
	}

}

const float MENU_ASPECT = 1.25; // 1280x1024

void draw_reset_cropped()
{
	draw_reset(conwidth, conheight, 0.5 * (realconwidth - conwidth), 0.5 * (realconheight - conheight));
}
void draw_reset_full()
{
	draw_reset(realconwidth, realconheight, 0, 0);
}

void UpdateConWidthHeight(float w, float h, float p)
{
	if (w != vidwidth_s || h != vidheight_s || p != vidpixelheight_s)
	{
		if (updateConwidths(w, h, p))
			localcmd(sprintf("\nexec %s\n", cvar_string("menu_font_cfg")));
		vidwidth_s = w;
		vidheight_s = h;
		vidpixelheight_s = p;
	}
	conwidth_s = conwidth;
	conheight_s = conheight;
	realconwidth = cvar("vid_conwidth");
	realconheight = cvar("vid_conheight");
	if(realconwidth / realconheight > MENU_ASPECT)
	{
		// widescreen
		conwidth = realconheight * MENU_ASPECT;
		conheight = realconheight;
	}
	else
	{
		// squarescreen
		conwidth = realconwidth;
		conheight = realconwidth / MENU_ASPECT;
	}
	if(main)
	{
		if(conwidth_s != conwidth || conheight_s != conheight)
		{
			draw_reset_cropped();
			main.resizeNotify(main, '0 0 0', eX * conwidth + eY * conheight, '0 0 0', eX * conwidth + eY * conheight);
		}
	}
	else
	{
		vidwidth_s = vidheight_s = vidpixelheight_s = 0; // retry next frame
	}
}

string m_goto_buffer;
void m_init_delayed()
{
	float fh, glob, n, i;
	string s;

	draw_reset_cropped();

	menuInitialized = 0;
	if(!preMenuInit())
		return;
	menuInitialized = 1;

	fh = -1;
	if(cvar_string("menu_skin") != "")
	{
		draw_currentSkin = strcat("gfx/menu/", cvar_string("menu_skin"));
		fh = fopen(language_filename(strcat(draw_currentSkin, "/skinvalues.txt")), FILE_READ);
	}
	if(fh < 0)
	if(cvar_defstring("menu_skin") != "")
	{
		cvar_set("menu_skin", cvar_defstring("menu_skin"));
		draw_currentSkin = strcat("gfx/menu/", cvar_string("menu_skin"));
		fh = fopen(language_filename(strcat(draw_currentSkin, "/skinvalues.txt")), FILE_READ);
	}
	if(fh < 0)
	{
		draw_currentSkin = "gfx/menu/default";
		fh = fopen(language_filename(strcat(draw_currentSkin, "/skinvalues.txt")), FILE_READ);
	}
	if(fh < 0)
	{
		error("cannot load any menu skin\n");
	}
	draw_currentSkin = strzone(draw_currentSkin);
	while((s = fgets(fh)))
	{
		// these two are handled by skinlist.qc
		if(substring(s, 0, 6) == "title ")
			continue;
		if(substring(s, 0, 7) == "author ")
			continue;
		n = tokenize_console(s);
		if(n >= 2)
			Skin_ApplySetting(argv(0), substring(s, argv_start_index(1), argv_end_index(-1) - argv_start_index(1)));
	}
	fclose(fh);

	glob = search_begin(strcat(draw_currentSkin, "/*.tga"), true, true);
	if(glob >= 0)
	{
		n = search_getsize(glob);
		for(i = 0; i < n; ++i)
			precache_pic(search_getfilename(glob, i));
		search_end(glob);
	}

	draw_setMousePointer(SKINGFX_CURSOR, SKINSIZE_CURSOR, SKINOFFSET_CURSOR);

	loadTooltips();
	anim = NEW(AnimHost);
	main = NEW(MainWindow); main.configureMainWindow(main);
	unloadTooltips();

	main.resizeNotify(main, '0 0 0', eX * conwidth + eY * conheight, '0 0 0', eX * conwidth + eY * conheight);
	main.focused = 1;
	menuShiftState = 0;
	menuMousePos = '0.5 0.5 0';

	m_sync();

	if(m_goto_buffer)
	{
		m_goto(m_goto_buffer);
		strunzone(m_goto_buffer);
		m_goto_buffer = string_null;
	}

	if(Menu_Active)
		m_display(); // delayed menu display
}

void m_keyup (float key, float ascii)
{
	if(!menuInitialized)
		return;
	if(!Menu_Active)
		return;
	draw_reset_cropped();
	main.keyUp(main, key, ascii, menuShiftState);
	if(key >= K_MOUSE1 && key <= K_MOUSE3)
	{
		--mouseButtonsPressed;
		if(!mouseButtonsPressed)
			main.mouseRelease(main, menuMousePos);
		if(mouseButtonsPressed < 0)
		{
			mouseButtonsPressed = 0;
			LOG_TRACE("Warning: released an already released button\n");
		}
	}
	if(key == K_ALT) menuShiftState -= (menuShiftState & S_ALT);
	if(key == K_CTRL) menuShiftState -= (menuShiftState & S_CTRL);
	if(key == K_SHIFT) menuShiftState -= (menuShiftState & S_SHIFT);
}

void m_keydown(float key, float ascii)
{
	if(!menuInitialized)
		return;
	if(!Menu_Active)
		return;

	if(menuMouseMode)
	if(key >= K_MOUSE1 && key <= K_MOUSE3)
	{
		// detect a click outside of the game window
		vector p = getmousepos();
		if(p.x < 0 || p.x > realconwidth || p.y < 0 || p.y > realconheight)
		{
			++mouseButtonsPressed;
			return;
		}
	}

	if(keyGrabber)
	{
		entity e;
		e = keyGrabber;
		keyGrabber = NULL;
		e.keyGrabbed(e, key, ascii);
	}
	else
	{
		draw_reset_cropped();
		if(key >= K_MOUSE1 && key <= K_MOUSE3)
			if(!mouseButtonsPressed)
				main.mousePress(main, menuMousePos);
		if(!main.keyDown(main, key, ascii, menuShiftState))
			if(key == K_ESCAPE)
				if(gamestatus & (GAME_ISSERVER | GAME_CONNECTED)) // don't back out to console only
					m_hide(); // disable menu on unhandled ESC
	}
	if(key >= K_MOUSE1 && key <= K_MOUSE3)
	{
		++mouseButtonsPressed;
		if(mouseButtonsPressed > 10)
		{
			mouseButtonsPressed = 10;
			LOG_TRACE("Warning: pressed an already pressed button\n");
		}
	}
	if(key == K_ALT) menuShiftState |= S_ALT;
	if(key == K_CTRL) menuShiftState |= S_CTRL;
	if(key == K_SHIFT) menuShiftState |= S_SHIFT;
}

const float SCALEMODE_CROP = 0;
const float SCALEMODE_LETTERBOX = 1;
const float SCALEMODE_WIDTH = 2;
const float SCALEMODE_HEIGHT = 3;
const float SCALEMODE_STRETCH = 4;
void draw_Picture_Aligned(vector algn, float scalemode, string img, float a)
{
	vector sz, org, isz, isz_w, isz_h;
	float width_is_larger;

	sz = draw_PictureSize(img);
	width_is_larger = (sz.x * draw_scale.y >= sz.y * draw_scale.x);
	isz_w = '1 0 0' + '0 1 0' * ((sz.y / sz.x) * (draw_scale.x / draw_scale.y));
	isz_h = '0 1 0' + '1 0 0' * ((sz.x / sz.y) * (draw_scale.y / draw_scale.x));

	switch(scalemode)
	{
		default:
		case SCALEMODE_CROP:
			isz = (width_is_larger ? isz_h : isz_w);
			break;
		case SCALEMODE_LETTERBOX:
			isz = (width_is_larger ? isz_w : isz_h);
			break;
		case SCALEMODE_WIDTH:
			isz = isz_w;
			break;
		case SCALEMODE_HEIGHT:
			isz = isz_h;
			break;
		case SCALEMODE_STRETCH:
			isz = '1 1 0';
			break;
	}

	org = eX * (algn.x * (1 - isz.x)) + eY * (algn.y * (1 - isz.y));
	draw_Picture(org, img, isz, '1 1 1', a);
}

void drawBackground(string img, float a, string algn, float force1)
{
	if(main.mainNexposee.ModalController_state == 0)
		return;

	vector v;
	float i, l;
	string c;
	float scalemode;

	v.z = 0;

	scalemode = SCALEMODE_CROP;

	l = 0;
	for(i = 0; i < strlen(algn); ++i)
	{
		c = substring(algn, i, 1);
		switch(c)
		{
			case "c": scalemode = SCALEMODE_CROP; goto nopic;
			case "l": scalemode = SCALEMODE_LETTERBOX; goto nopic;
			case "h": scalemode = SCALEMODE_HEIGHT; goto nopic;
			case "w": scalemode = SCALEMODE_WIDTH; goto nopic;
			case "s": scalemode = SCALEMODE_STRETCH; goto nopic;
			case "1": case "4": case "7": v.x = 0.0; break;
			case "2": case "5": case "8": v.x = 0.5; break;
			case "3": case "6": case "9": v.x = 1.0; break;
			default: v.x = random(); break;
		}
		switch(c)
		{
			case "7": case "8": case "9": v.y = 0.0; break;
			case "4": case "5": case "6": v.y = 0.5; break;
			case "1": case "2": case "3": v.y = 1.0; break;
			default: v.y = random(); break;
		}
		if(l == 0)
			draw_Picture_Aligned(v, scalemode, img, a);
		else if(force1)
			// force all secondary layers to use alpha 1. Prevents ugly issues
			// with overlap. It's a flag because it cannot be used for the
			// ingame background
			draw_Picture_Aligned(v, scalemode, strcat(img, "_l", ftos(l+1)), 1);
		else
			draw_Picture_Aligned(v, scalemode, strcat(img, "_l", ftos(l+1)), a);
		++l;
:nopic
	}
}

float menu_tooltips;
float menu_tooltips_old;
vector menuTooltipAveragedMousePos;
entity menuTooltipItem;
vector menuTooltipOrigin;
vector menuTooltipSize;
float menuTooltipAlpha;
string menuTooltipText;
float menuTooltipState; // 0: static, 1: fading in, 2: fading out
float m_testmousetooltipbox(vector pos)
{
	if(pos.x >= menuTooltipOrigin.x && pos.x < menuTooltipOrigin.x + menuTooltipSize.x)
	if(pos.y >= menuTooltipOrigin.y && pos.y < menuTooltipOrigin.y + menuTooltipSize.y)
		return false;
	return true;
}
float m_testtooltipbox(vector tooltippos)
{
	if(tooltippos.x < 0)
		return false;
	if(tooltippos.y < 0)
		return false;
	if(tooltippos.x + menuTooltipSize.x > 1)
		return false;
	if(tooltippos.y + menuTooltipSize.y > 1)
		return false;
	menuTooltipOrigin = tooltippos;
	return true;
}
float m_allocatetooltipbox(vector pos)
{
	vector avoidplus, avoidminus;
	vector v;

	avoidplus.x = (SKINAVOID_TOOLTIP_x + SKINSIZE_CURSOR_x - SKINOFFSET_CURSOR_x * SKINSIZE_CURSOR_x) / conwidth;
	avoidplus.y = (SKINAVOID_TOOLTIP_y + SKINSIZE_CURSOR_y - SKINOFFSET_CURSOR_y * SKINSIZE_CURSOR_y) / conheight;
	avoidplus.z = 0;

	avoidminus.x = (SKINAVOID_TOOLTIP_x + SKINOFFSET_CURSOR_x * SKINSIZE_CURSOR_x) / conwidth + menuTooltipSize.x;
	avoidminus.y = (SKINAVOID_TOOLTIP_y + SKINOFFSET_CURSOR_y * SKINSIZE_CURSOR_y) / conheight + menuTooltipSize.y;
	avoidminus.z = 0;

	// bottom right
	v = pos + avoidplus;
	if(m_testtooltipbox(v))
		return true;

	// bottom center
	v.x = pos.x - menuTooltipSize.x * 0.5;
	if(m_testtooltipbox(v))
		return true;

	// bottom left
	v.x = pos.x - avoidminus.x;
	if(m_testtooltipbox(v))
		return true;

	// top left
	v.y = pos.y - avoidminus.y;
	if(m_testtooltipbox(v))
		return true;

	// top center
	v.x = pos.x - menuTooltipSize.x * 0.5;
	if(m_testtooltipbox(v))
		return true;

	// top right
	v.x = pos.x + avoidplus.x;
	if(m_testtooltipbox(v))
		return true;

	return false;
}
entity m_findtooltipitem(entity root, vector pos)
{
	entity it;
	entity best;

	best = world;
	it = root;

	while(it.instanceOfContainer)
	{
		while(it.instanceOfNexposee && it.focusedChild)
		{
			it = it.focusedChild;
			pos = globalToBox(pos, it.Container_origin, it.Container_size);
		}
		if(it.instanceOfNexposee)
		{
			it = it.itemFromPoint(it, pos);
			if(it.tooltip)
				best = it;
			else if(menu_tooltips == 2 && (it.cvarName || it.onClickCommand))
				best = it;
			it = world;
		}
		else if(it.instanceOfModalController)
			it = it.focusedChild;
		else
			it = it.itemFromPoint(it, pos);
		if(!it)
			break;
		if(it.tooltip)
			best = it;
		else if(menu_tooltips == 2 && (it.cvarName || it.onClickCommand))
			best = it;
		pos = globalToBox(pos, it.Container_origin, it.Container_size);
	}

	return best;
}
string gettooltip()
{
	if (menu_tooltips == 2)
	{
		string s;
		if (menuTooltipItem.cvarName)
		{
			if (getCvarsMulti(menuTooltipItem))
				s = strcat("[", menuTooltipItem.cvarName, " ", getCvarsMulti(menuTooltipItem), "]");
			else
				s = strcat("[", menuTooltipItem.cvarName, "]");
		}
		else if (menuTooltipItem.onClickCommand)
			s = strcat("<", menuTooltipItem.onClickCommand, ">");
		else
			return menuTooltipItem.tooltip;
		if (menuTooltipItem.tooltip)
			return strcat(menuTooltipItem.tooltip, " ", s);
		return s;
	}
	return menuTooltipItem.tooltip;
}
void m_tooltip(vector pos)
{
	float f, i, w;
	entity it;
	vector fontsize, p;
	string s;

	menu_tooltips = cvar("menu_tooltips");
	if (!menu_tooltips)
	{
		// don't return immediately, fade out the active tooltip first
		if (menuTooltipItem == world)
			return;
		it = world;
		menu_tooltips_old = menu_tooltips;
	}
	else
	{
		f = bound(0, frametime * 2, 1);
		menuTooltipAveragedMousePos = menuTooltipAveragedMousePos * (1 - f) + pos * f;
		f = vlen(pos - menuTooltipAveragedMousePos);
		if(f < 0.01)
			it = m_findtooltipitem(main, pos);
		else
			it = world;
	}
	fontsize = '1 0 0' * (SKINFONTSIZE_TOOLTIP / conwidth) + '0 1 0' * (SKINFONTSIZE_TOOLTIP / conheight);

	// float menuTooltipState; // 0: static, 1: fading in, 2: fading out
	if(it != menuTooltipItem)
	{
		switch(menuTooltipState)
		{
			case 0:
				if(menuTooltipItem)
				{
					// another item: fade out first
					menuTooltipState = 2;
				}
				else
				{
					// new item: fade in
					menuTooltipState = 1;
					menuTooltipItem = it;

					menuTooltipOrigin.x = -1; // unallocated

					if (menuTooltipText)
						strunzone(menuTooltipText);
					menuTooltipText = strzone(gettooltip());

					i = 0;
					w = 0;
					getWrappedLine_remaining = menuTooltipText;
					while(getWrappedLine_remaining)
					{
						s = getWrappedLine(SKINWIDTH_TOOLTIP, fontsize, draw_TextWidth_WithoutColors);
						++i;
						f = draw_TextWidth(s, false, fontsize);
						if(f > w)
							w = f;
					}
					menuTooltipSize.x = w + 2 * (SKINMARGIN_TOOLTIP_x / conwidth);
					menuTooltipSize.y = i * fontsize.y + 2 * (SKINMARGIN_TOOLTIP_y / conheight);
					menuTooltipSize.z = 0;
				}
				break;
			case 1:
				// changing item while fading in: fade out first
				menuTooltipState = 2;
				break;
			case 2:
				// changing item while fading out: can't
				break;
		}
	}
	else if(menuTooltipState == 2) // re-fade in?
		menuTooltipState = 1;

	if(menuTooltipItem)
		if(!m_testmousetooltipbox(pos))
			menuTooltipState = 2; // fade out if mouse touches it

	switch(menuTooltipState)
	{
		case 1:
			menuTooltipAlpha = bound(0, menuTooltipAlpha + 5 * frametime, 1);
			if(menuTooltipAlpha == 1)
				menuTooltipState = 0;
			break;
		case 2:
			menuTooltipAlpha = bound(0, menuTooltipAlpha - 2 * frametime, 1);
			if(menuTooltipAlpha == 0)
			{
				menuTooltipState = 0;
				menuTooltipItem = world;
			}
			break;
	}

	if(menuTooltipItem == world)
	{
		if (menuTooltipText)
		{
			strunzone(menuTooltipText);
			menuTooltipText = string_null;
		}
		return;
	}
	else
	{
		if(menu_tooltips != menu_tooltips_old)
		{
			if (menu_tooltips != 0 && menu_tooltips_old != 0)
				menuTooltipItem = world; // reload tooltip next frame
			menu_tooltips_old = menu_tooltips;
		}
		else if(menuTooltipOrigin.x < 0) // unallocated?
			m_allocatetooltipbox(pos);

		if(menuTooltipOrigin.x >= 0)
		{
			// draw the tooltip!
			p = SKINBORDER_TOOLTIP;
			p.x *= 1 / conwidth;
			p.y *= 1 / conheight;
			draw_BorderPicture(menuTooltipOrigin, SKINGFX_TOOLTIP, menuTooltipSize, '1 1 1', menuTooltipAlpha, p);
			p = menuTooltipOrigin;
			p.x += SKINMARGIN_TOOLTIP_x / conwidth;
			p.y += SKINMARGIN_TOOLTIP_y / conheight;
			getWrappedLine_remaining = menuTooltipText;
			while(getWrappedLine_remaining)
			{
				s = getWrappedLine(SKINWIDTH_TOOLTIP, fontsize, draw_TextWidth_WithoutColors);
				draw_Text(p, s, fontsize, SKINCOLOR_TOOLTIP, SKINALPHA_TOOLTIP * menuTooltipAlpha, false);
				p.y += fontsize.y;
			}
		}
	}
}

void m_draw(float width, float height)
{
	float t;
	float realFrametime;

	m_gamestatus();

	execute_next_frame();

	menuMouseMode = cvar("menu_mouse_absolute");

	if (anim)
		anim.tickAll(anim);

	UpdateConWidthHeight(width, height, cvar("vid_pixelheight"));

	if(!menuInitialized)
	{
		// TODO draw an info image about this situation
		m_init_delayed();
		return;
	}
	if(!menuNotTheFirstFrame)
	{
		menuNotTheFirstFrame = 1;
		if(Menu_Active)
		if(!cvar("menu_video_played"))
		{
			localcmd("cd loop $menu_cdtrack; play sound/announcer/default/welcome.wav\n");
			menuLogoAlpha = -0.8; // no idea why, but when I start this at zero, it jumps instead of fading FIXME
		}
		// ALWAYS set this cvar; if we start but menu is not active, this means we want no background music!
		localcmd("set menu_video_played 1\n");
	}

	t = gettime();
	realFrametime = frametime = min(0.2, t - menuPrevTime);
	menuPrevTime = t;
	time += frametime;

	t = cvar("menu_slowmo");
	if(t)
	{
		frametime *= t;
		realFrametime *= t;
	}
	else
		t = 1;

	if(Menu_Active)
	{
		if(getmousetarget() == (menuMouseMode ? MT_CLIENT : MT_MENU) && (getkeydest() == KEY_MENU || getkeydest() == KEY_MENU_GRABBED))
			setkeydest(keyGrabber ? KEY_MENU_GRABBED : KEY_MENU);
		else
			m_hide();
	}

	if(cvar("cl_capturevideo"))
		frametime = t / cvar("cl_capturevideo_fps"); // make capturevideo work smoothly

	prevMenuAlpha = menuAlpha;
	if(Menu_Active)
	{
		if(menuAlpha == 0 && menuLogoAlpha < 2)
		{
			menuLogoAlpha = menuLogoAlpha + frametime * 2;
		}
		else
		{
			menuAlpha = min(1, menuAlpha + frametime * 5);
			menuLogoAlpha = 2;
		}
	}
	else
	{
		menuAlpha = max(0, menuAlpha - frametime * 5);
		menuLogoAlpha = 2;
	}

	draw_reset_cropped();

	if(!(gamestatus & (GAME_CONNECTED | GAME_ISSERVER)))
	{
		if(menuLogoAlpha > 0)
		{
			draw_reset_full();
			draw_Fill('0 0 0', '1 1 0', SKINCOLOR_BACKGROUND, 1);
			drawBackground(SKINGFX_BACKGROUND, bound(0, menuLogoAlpha, 1), SKINALIGN_BACKGROUND, true);
			draw_reset_cropped();
			if(menuAlpha <= 0 && SKINALPHA_CURSOR_INTRO > 0)
			{
				draw_alpha = SKINALPHA_CURSOR_INTRO * bound(0, menuLogoAlpha, 1);
				draw_drawMousePointer(menuMousePos);
				draw_alpha = 1;
			}
		}
	}
	else if(SKINALPHA_BACKGROUND_INGAME)
	{
		if(menuAlpha > 0)
		{
			draw_reset_full();
			drawBackground(SKINGFX_BACKGROUND_INGAME, menuAlpha * SKINALPHA_BACKGROUND_INGAME, SKINALIGN_BACKGROUND_INGAME, false);
			draw_reset_cropped();
		}
	}

	if(menuAlpha != prevMenuAlpha)
		cvar_set("_menu_alpha", ftos(menuAlpha));

	draw_reset_cropped();
	preMenuDraw();
	draw_reset_cropped();

	if(menuAlpha <= 0)
	{
		if(prevMenuAlpha > 0)
			main.initializeDialog(main, main.firstChild);
		draw_reset_cropped();
		postMenuDraw();
		return;
	}

	draw_alpha *= menuAlpha;

	if(!Menu_Active)
	{
		// do not update mouse position
		// it prevents mouse jumping to '0 0 0' when menu is fading out
	}
	else if(menuMouseMode)
	{
		vector newMouse;
		newMouse = globalToBox(getmousepos(), draw_shift, draw_scale);
		if(newMouse != '0 0 0')
			if(newMouse != menuMousePos)
			{
				menuMousePos = newMouse;
				if(mouseButtonsPressed)
					main.mouseDrag(main, menuMousePos);
				else
					main.mouseMove(main, menuMousePos);
			}
	}
	else
	{
		if(frametime > 0)
		{
			vector dMouse, minpos, maxpos;
			dMouse = getmousepos() * (frametime / realFrametime); // for capturevideo
			if(dMouse != '0 0 0')
			{
				minpos = globalToBox('0 0 0', draw_shift, draw_scale);
				maxpos = globalToBox(eX * (realconwidth - 1) + eY * (realconheight - 1), draw_shift, draw_scale);
				dMouse = globalToBoxSize(dMouse, draw_scale);
				menuMousePos += dMouse * cvar("menu_mouse_speed");
				menuMousePos.x = bound(minpos.x, menuMousePos.x, maxpos.x);
				menuMousePos.y = bound(minpos.y, menuMousePos.y, maxpos.y);
				if(mouseButtonsPressed)
					main.mouseDrag(main, menuMousePos);
				else
					main.mouseMove(main, menuMousePos);
			}
		}
	}
	main.draw(main);

	m_tooltip(menuMousePos);

	draw_alpha = max(draw_alpha, SKINALPHA_CURSOR_INTRO * bound(0, menuLogoAlpha, 1));

	draw_drawMousePointer(menuMousePos);

	draw_reset_cropped();
	postMenuDraw();

	frametime = 0;
}

void m_display()
{
	Menu_Active = true;
	setkeydest(KEY_MENU);
	setmousetarget((menuMouseMode ? MT_CLIENT : MT_MENU));

	if(!menuInitialized)
		return;

	if(mouseButtonsPressed)
		main.mouseRelease(main, menuMousePos);
	mouseButtonsPressed = 0;

	main.focusEnter(main);
	main.showNotify(main);
}

void m_hide()
{
	Menu_Active = false;
	setkeydest(KEY_GAME);
	setmousetarget(MT_CLIENT);

	if(!menuInitialized)
		return;

	main.focusLeave(main);
	main.hideNotify(main);
}

void m_toggle(float mode)
{
	if(Menu_Active)
	{
		if (mode == 1)
			return;
		m_hide();
	}
	else
	{
		if (mode == 0)
			return;
		m_display();
	}
}

void Shutdown()
{
	entity e;

	m_hide();
	for(e = NULL; (e = nextent(e)) != NULL; )
	{
		if(e.classname != "vtbl")
			if(e.destroy)
				e.destroy(e);
	}
}

void m_focus_item_chain(entity outermost, entity innermost)
{
	if(innermost.parent != outermost)
		m_focus_item_chain(outermost, innermost.parent);
	innermost.parent.setFocus(innermost.parent, innermost);
}

void m_activate_window(entity wnd)
{
	entity par;
	par = wnd.parent;
	if(par)
		m_activate_window(par);

	if(par.instanceOfModalController)
	{
		if(wnd.tabSelectingButton)
			// tabs
			TabButton_Click(wnd.tabSelectingButton, wnd);
		else
			// root
			par.initializeDialog(par, wnd);
	}
	else if(par.instanceOfNexposee)
	{
		// nexposee (sorry for violating abstraction here)
		par.selectedChild = wnd;
		par.animationState = 1;
		Container_setFocus(par, NULL);
	}
	else if(par.instanceOfContainer)
	{
		// other containers
		if(par.focused)
			par.setFocus(par, wnd);
	}
}

void m_setpointerfocus(entity wnd)
{
	if(wnd.instanceOfContainer)
	{
		entity focus = wnd.preferredFocusedGrandChild(wnd);
		if(focus)
		{
			menuMousePos = focus.origin + 0.5 * focus.size;
			menuMousePos.x *= 1 / conwidth;
			menuMousePos.y *= 1 / conheight;
			entity par = wnd.parent;
			if(par.focused)
				par.setFocus(par, wnd);
			if(wnd.focused)
				m_focus_item_chain(wnd, focus);
		}
	}
}

void m_goto(string itemname)
{
	entity e;
	if(!menuInitialized)
	{
		if(m_goto_buffer)
			strunzone(m_goto_buffer);
		m_goto_buffer = strzone(itemname);
		return;
	}
	if(itemname == "") // this can be called by GameCommand
	{
		if(gamestatus & (GAME_ISSERVER | GAME_CONNECTED))
		{
			m_hide();
		}
		else
		{
			m_activate_window(main.mainNexposee);
			m_display();
		}
	}
	else
	{
		for(e = NULL; (e = find(e, name, itemname)); )
			if(e.classname != "vtbl")
				break;

		if((e) && (!e.requiresConnection || (gamestatus & (GAME_ISSERVER | GAME_CONNECTED))))
		{
			m_hide();
			m_activate_window(e);
			m_setpointerfocus(e);
			m_display();
		}
	}
}

float menuLastFocusSoundTime;
void m_play_focus_sound()
{
	if(cvar("menu_sounds") > 1)
		if(time - menuLastFocusSoundTime > 0.25)
		{
			localsound(MENU_SOUND_FOCUS);
			menuLastFocusSoundTime = time;
		}
}

void m_play_click_sound(string soundfile)
{
	if(cvar("menu_sounds"))
		localsound(soundfile);
}
