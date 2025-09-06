#include "menu.qh"

#include "item.qh"

#include "anim/animhost.qh"

#include "item/dialog.qh"
#include "item/listbox.qh"
#include "item/nexposee.qh"

#include "xonotic/commandbutton.qh"
#include "xonotic/mainwindow.qh"
#include "xonotic/serverlist.qh"
#include "xonotic/slider_resolution.qh"

.string controlledCvar;

#include "xonotic/util.qh"

#include <common/checkextension.qh>
#include <common/items/_mod.qh>
#include <common/weapons/_all.qh>
#include <common/mapinfo.qh>
#include <common/mutators/base.qh>

int mouseButtonsPressed;
vector menuMousePos;
int menuShiftState;
float menuPrevTime;
float menuAlpha;
float menuLogoAlpha;
float prevMenuAlpha;
bool menuInitialized;
int menuMouseMode;

// Used for having effects only execute once in main menu, not for every reload
// 0: never been in main menu before. 1: coming back to main menu. 2: in main menu.
int menuNotTheFirstFrame;
bool autocvar_menu_no_music_nor_welcome;

float conwidth_s, conheight_s;
float vidwidth_s, vidheight_s, vidpixelheight_s;
float realconwidth, realconheight;

void m_sync()
{
	updateCompression();
	vidwidth_s = vidheight_s = vidpixelheight_s = 0;  // Force updateConwidths on next draw

	loadAllCvars(main);
}

void m_gamestatus()
{
	gamestatus = 0;
	if (isserver()) gamestatus |= GAME_ISSERVER;
	if (clientstate() == CS_CONNECTED || isdemo()) gamestatus |= GAME_CONNECTED;
	if (cvar("developer") > 0) gamestatus |= GAME_DEVELOPER;
}

void m_init()
{
	bool restarting = false;
	cvar_set("_menu_alpha", "0");
	prvm_language = cvar_string("prvm_language");
	if (prvm_language == "")
	{
		prvm_language = "en";
		cvar_set("prvm_language", prvm_language);
		localcmd("\nmenu_restart\n");
		restarting = true;
	}
	prvm_language = strzone(prvm_language);
	cvar_set("_menu_prvm_language", prvm_language);

#ifdef WATERMARK
		LOG_TRACEF("^4MQC Build information: ^1%s", WATERMARK);
#endif

	CheckEngineExtensions();

	registercvar("_menu_cmd_closemenu_available", "0", 0);
	cvar_set("_menu_cmd_closemenu_available", "1");

	// needs to be done so early because of the constants they create
	static_init();
	static_init_late();
	static_init_precache();

	RegisterSLCategories();

	float ddsload = cvar("r_texture_dds_load");
	float texcomp = cvar("gl_texturecompression");
	updateCompression();
	if (ddsload != cvar("r_texture_dds_load") || texcomp != cvar("gl_texturecompression")) localcmd("\nr_restart\n");

	if (!restarting)
	{
		if (cvar("_menu_initialized"))  // always show menu after menu_restart
			m_display();
		else m_hide();
		cvar_set("_menu_initialized", "1");
	}
}

const float MENU_ASPECT = 1280 / 1024;

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
		if (updateConwidths(w, h, p) && menuNotTheFirstFrame)
			localcmd(sprintf("\nexec %s\n", cvar_string("menu_font_cfg")));
		vidwidth_s = w;
		vidheight_s = h;
		vidpixelheight_s = p;
	}
	conwidth_s = conwidth;
	conheight_s = conheight;
	realconwidth = cvar("vid_conwidth");
	realconheight = cvar("vid_conheight");
	if (realconwidth / realconheight > MENU_ASPECT)
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
	if (main)
	{
		if (conwidth_s != conwidth || conheight_s != conheight)
		{
			draw_reset_cropped();
			main.resizeNotify(main, '0 0 0', eX * conwidth + eY * conheight, '0 0 0', eX * conwidth + eY * conheight);
		}
	}
	else
	{
		vidwidth_s = vidheight_s = vidpixelheight_s = 0;  // retry next frame
	}
}

string m_goto_buffer;
void m_init_delayed()
{
	draw_reset_cropped();

	menuInitialized = false;
	if (!preMenuInit()) return;
	menuInitialized = true;

	int fh = -1;
	if (cvar_string("menu_skin") != "")
	{
		draw_currentSkin = strcat("gfx/menu/", cvar_string("menu_skin"));
		fh = fopen(strcat(draw_currentSkin, "/skinvalues.txt"), FILE_READ);
	}
	if (fh < 0 && cvar_defstring("menu_skin") != "")
	{
		cvar_set("menu_skin", cvar_defstring("menu_skin"));
		draw_currentSkin = strcat("gfx/menu/", cvar_string("menu_skin"));
		fh = fopen(strcat(draw_currentSkin, "/skinvalues.txt"), FILE_READ);
	}
	if (fh < 0)
	{
		draw_currentSkin = "gfx/menu/wickedx"; // default menu skin
		fh = fopen(strcat(draw_currentSkin, "/skinvalues.txt"), FILE_READ);
	}
	if (fh < 0) error("cannot load any menu skin\n");
	draw_currentSkin = strzone(draw_currentSkin);
	for (string s; (s = fgets(fh)); )
	{
		// these two are handled by skinlist.qc
		if (substring(s, 0, 6) == "title ") continue;
		if (substring(s, 0, 7) == "author ") continue;
		int n = tokenize_console(s);
		if (n < 2) continue;
		Skin_ApplySetting(argv(0), substring(s, argv_start_index(1), argv_end_index(-1) - argv_start_index(1)));
	}
	fclose(fh);

	int glob = search_begin(strcat(draw_currentSkin, "/*.tga"), true, true);
	if (glob >= 0)
	{
		for (int i = 0, n = search_getsize(glob); i < n; ++i)
			precache_pic(search_getfilename(glob, i));
		search_end(glob);
	}

	draw_setMousePointer(SKINGFX_CURSOR, SKINSIZE_CURSOR, SKINOFFSET_CURSOR);

	anim = NEW(AnimHost);
	main = NEW(MainWindow);
	main.configureMainWindow(main);

	main.resizeNotify(main, '0 0 0', eX * conwidth + eY * conheight, '0 0 0', eX * conwidth + eY * conheight);
	main.focused = true;
	menuShiftState = 0;
	menuMousePos = '0.5 0.5 0';

	m_sync();

	if (m_goto_buffer)
	{
		m_goto(m_goto_buffer, false);
		strfree(m_goto_buffer);
	}

	if (Menu_Active) m_display();  // delayed menu display

	cvar_set("_menu_initialized", "2");
}

void m_keyup(float key, float ascii)
{
	if (!menuInitialized) return;
	if (!Menu_Active) return;
	draw_reset_cropped();
	main.keyUp(main, key, ascii, menuShiftState);
	if (key >= K_MOUSE1 && key <= K_MOUSE3)
	{
		--mouseButtonsPressed;
		if (!mouseButtonsPressed) main.mouseRelease(main, menuMousePos);
		if (mouseButtonsPressed < 0)
		{
			mouseButtonsPressed = 0;
			LOG_TRACE("Warning: released an already released button");
		}
	}
	if (key == K_ALT) menuShiftState &= ~S_ALT;
	if (key == K_CTRL) menuShiftState &= ~S_CTRL;
	if (key == K_SHIFT) menuShiftState &= ~S_SHIFT;
}

void m_keydown(float key, float ascii)
{
	if (!menuInitialized) return;
	if (!Menu_Active) return;

	if (menuMouseMode && key >= K_MOUSE1 && key <= K_MOUSE3)
	{
		// detect a click outside of the game window
		vector p = getmousepos();
		if (p.x < 0 || p.x > realconwidth || p.y < 0 || p.y > realconheight)
		{
			++mouseButtonsPressed;
			return;
		}
	}

	if (keyGrabber)
	{
		entity e = keyGrabber;
		keyGrabber = NULL;
		e.keyGrabbed(e, key, ascii);
	}
	else
	{
		draw_reset_cropped();
		if (!mouseButtonsPressed && key >= K_MOUSE1 && key <= K_MOUSE3)
			main.mousePress(main, menuMousePos);
		if (!main.keyDown(main, key, ascii, menuShiftState))
		{
			// disable menu on unhandled ESC
			if (key == K_ESCAPE)
				if (gamestatus & (GAME_ISSERVER | GAME_CONNECTED))  // don't back out to console only
					m_hide();
		}
	}
	if (key >= K_MOUSE1 && key <= K_MOUSE3)
	{
		++mouseButtonsPressed;
		if (mouseButtonsPressed > 10)
		{
			mouseButtonsPressed = 10;
			LOG_TRACE("Warning: pressed an already pressed button");
		}
	}
	if (key == K_ALT) menuShiftState |= S_ALT;
	if (key == K_CTRL) menuShiftState |= S_CTRL;
	if (key == K_SHIFT) menuShiftState |= S_SHIFT;
}

enum {
	SCALEMODE_CROP,
	SCALEMODE_LETTERBOX,
	SCALEMODE_WIDTH,
	SCALEMODE_HEIGHT,
	SCALEMODE_STRETCH,
};
void draw_Picture_Aligned(vector algn, float scalemode, string img, float a)
{
	vector sz = draw_PictureSize(img);
	bool width_is_larger = (sz.x * draw_scale.y >= sz.y * draw_scale.x);
	vector isz_w = '1 0 0' + '0 1 0' * ((sz.y / sz.x) * (draw_scale.x / draw_scale.y));
	vector isz_h = '0 1 0' + '1 0 0' * ((sz.x / sz.y) * (draw_scale.y / draw_scale.x));
	vector isz;
	switch (scalemode)
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
	vector org = eX * (algn.x * (1 - isz.x)) + eY * (algn.y * (1 - isz.y));
	draw_Picture(org, img, isz, '1 1 1', a);
}

void drawBackground(string img, float a, string algn, float force1)
{
	if (main.mainNexposee.ModalController_state == 0
	&& !(main.focusedChild && main.focusedChild.hideMenuOnClose && !(gamestatus & (GAME_ISSERVER | GAME_CONNECTED))))
		return;

	vector v = '0 0 0';
	int scalemode = SCALEMODE_CROP;
	int len = strlen(algn);
	for (int i = 0, l = 0; i < len; ++i)
	{
		string c = substring(algn, i, 1);
		switch (c)
		{
			case "c":
				scalemode = SCALEMODE_CROP;
				goto nopic;
			case "l":
				scalemode = SCALEMODE_LETTERBOX;
				goto nopic;
			case "h":
				scalemode = SCALEMODE_HEIGHT;
				goto nopic;
			case "w":
				scalemode = SCALEMODE_WIDTH;
				goto nopic;
			case "s":
				scalemode = SCALEMODE_STRETCH;
				goto nopic;
			case "1": case "4": case "7":
				v.x = 0.0;
				break;
			case "2": case "5": case "8":
				v.x = 0.5;
				break;
			case "3": case "6": case "9":
				v.x = 1.0;
				break;
			default:
				v.x = random();
				break;
		}
		switch (c)
		{
			case "7": case "8": case "9":
				v.y = 0.0;
				break;
			case "4": case "5": case "6":
				v.y = 0.5;
				break;
			case "1": case "2": case "3":
				v.y = 1.0;
				break;
			default:
				v.y = random();
				break;
		}
		if (l == 0)
		{
			draw_Picture_Aligned(v, scalemode, img, a);
		}
		else if (force1)
		{
			// force all secondary layers to use alpha 1. Prevents ugly issues
			// with overlap. It's a flag because it cannot be used for the
			// ingame background
			draw_Picture_Aligned(v, scalemode, strcat(img, "_l", ftos(l + 1)), 1);
		}
		else
		{
			draw_Picture_Aligned(v, scalemode, strcat(img, "_l", ftos(l + 1)), a);
		}
		++l;
LABEL(nopic)
	}
}

int menu_tooltips;
int menu_tooltips_old;
vector menuTooltipAveragedMousePos;
entity menuTooltipItem;
vector menuTooltipOrigin;
vector menuTooltipSize;
float menuTooltipAlpha;
string menuTooltipText;
int menuTooltipState;  // 0: static, 1: fading in, 2: fading out, 3: forced fading out
bool m_testmousetooltipbox(vector pos)
{
	return !(
	    (pos.x >= menuTooltipOrigin.x && pos.x < menuTooltipOrigin.x + menuTooltipSize.x)
	    && (pos.y >= menuTooltipOrigin.y && pos.y < menuTooltipOrigin.y + menuTooltipSize.y)
	        );
}
bool m_testtooltipbox(vector tooltippos)
{
	if (tooltippos.x < 0) return false;
	if (tooltippos.y < 0) return false;
	if (tooltippos.x + menuTooltipSize.x > 1) return false;
	if (tooltippos.y + menuTooltipSize.y > 1) return false;
	menuTooltipOrigin = tooltippos;
	return true;
}
bool m_allocatetooltipbox(vector pos)
{
	vector avoidplus;
	avoidplus.x = (SKINAVOID_TOOLTIP_x + SKINSIZE_CURSOR_x - SKINOFFSET_CURSOR_x * SKINSIZE_CURSOR_x) / conwidth;
	avoidplus.y = (SKINAVOID_TOOLTIP_y + SKINSIZE_CURSOR_y - SKINOFFSET_CURSOR_y * SKINSIZE_CURSOR_y) / conheight;
	avoidplus.z = 0;

	vector avoidminus;
	avoidminus.x = (SKINAVOID_TOOLTIP_x + SKINOFFSET_CURSOR_x * SKINSIZE_CURSOR_x) / conwidth + menuTooltipSize.x;
	avoidminus.y = (SKINAVOID_TOOLTIP_y + SKINOFFSET_CURSOR_y * SKINSIZE_CURSOR_y) / conheight + menuTooltipSize.y;
	avoidminus.z = 0;

	// bottom right
	vector v = pos + avoidplus;
	if (m_testtooltipbox(v)) return true;

	// bottom center
	v.x = pos.x - menuTooltipSize.x * 0.5;
	if (m_testtooltipbox(v)) return true;

	// bottom left
	v.x = pos.x - avoidminus.x;
	if (m_testtooltipbox(v)) return true;

	// top left
	v.y = pos.y - avoidminus.y;
	if (m_testtooltipbox(v)) return true;

	// top center
	v.x = pos.x - menuTooltipSize.x * 0.5;
	if (m_testtooltipbox(v)) return true;

	// top right
	v.x = pos.x + avoidplus.x;
	if (m_testtooltipbox(v)) return true;

	return false;
}
entity m_findtooltipitem(entity root, vector pos)
{
	entity best = NULL;
	for (entity it = root; it.instanceOfContainer; )
	{
		while (it.instanceOfNexposee && it.focusedChild)
		{
			it = it.focusedChild;
			pos = globalToBox(pos, it.Container_origin, it.Container_size);
		}
		if (it.instanceOfNexposee)
		{
			it = it.itemFromPoint(it, pos);
			if (it.tooltip) best = it;
			else if (menu_tooltips == 2 && (it.controlledCvar || it.onClickCommand)) best = it;
			it = NULL;
		}
		else if (it.instanceOfModalController)
		{
			it = it.focusedChild;
		}
		else
		{
			it = it.itemFromPoint(it, pos);
		}
		if (!it) break;
		if (it.tooltip) best = it;
		else if (menu_tooltips == 2 && (it.controlledCvar || it.onClickCommand)) best = it;
		pos = globalToBox(pos, it.Container_origin, it.Container_size);
	}

	return best;
}
string gettooltip_dependency_string_numeric(entity e, .string cvarStr, .float cvarMin, .float cvarMax, float not_if_equal)
{
	if (e.(cvarMin) == e.(cvarMax))
	{
		if (not_if_equal)
			return sprintf(_("^3%s^7 not equal to \"%s\""),        e.(cvarStr), ftos_mindecimals(e.(cvarMin)));
		else
			return sprintf("^3%s^7 \"%s\"",                        e.(cvarStr), ftos_mindecimals(e.(cvarMin)));
	}
	else if (e.(cvarMin) < e.(cvarMax))
		return sprintf(_("^3%s^7 in range \"%s\" to \"%s\""),      e.(cvarStr), ftos_mindecimals(e.(cvarMin)), ftos_mindecimals(e.(cvarMax)));
	else
		return sprintf(_("^3%s^7 outside range \"%s\" to \"%s\""), e.(cvarStr), ftos_mindecimals(e.(cvarMax)), ftos_mindecimals(e.(cvarMin)));
}
string gettooltip()
{
	string s;
	if (menu_tooltips == 2)
	{
		if (menuTooltipItem.controlledCvar)
		{
			string cvar_list = getCvarsMulti(menuTooltipItem);
			if (cvar_list)
				cvar_list = strcat(menuTooltipItem.controlledCvar, " ", cvar_list);
			else
				cvar_list = menuTooltipItem.controlledCvar;
			s = strcat("^3", cvar_list,
				" ^7\"",    cvar_string(menuTooltipItem.controlledCvar), "^7\" "
				"^8[\"", cvar_defstring(menuTooltipItem.controlledCvar), "^8\"]^7");
		}
		else if (menuTooltipItem.onClickCommand)
			s = strcat("<", menuTooltipItem.onClickCommand, "^7>");
		else
			s = "";

		if (menuTooltipItem.tooltip)
			s = strcat(rgb_to_hexcolor(SKINCOLOR_TOOLTIP), (s == "" ? menuTooltipItem.tooltip : strcat(menuTooltipItem.tooltip, "\n\n", s)));

		if (menuTooltipItem.disabled)
		{
			if (menuTooltipItem.func_setDependent)
				s = strcat(s, "\n\n", _("Has special requirements"));
			else if (menuTooltipItem.cvarString_setDependent)
				s = strcat(s, "\n\n",
					sprintf(_("Requires ^3%s^7 not equal to \"%s^7\""), menuTooltipItem.cvarString_setDependent, menuTooltipItem.cvarValue_setDependent));
			else if (menuTooltipItem.cvar1_setDependent)
			{
				s = strcat(s, "\n\n");
				string cvar1_s, cvar2_s, cvar3_s;
				cvar1_s = gettooltip_dependency_string_numeric(menuTooltipItem, cvar1_setDependent, cvar1Min_setDependent, cvar1Max_setDependent, menuTooltipItem.op_setDependent & BIT(1));
				if (menuTooltipItem.cvar2_setDependent)
				{
					cvar2_s = gettooltip_dependency_string_numeric(menuTooltipItem, cvar2_setDependent, cvar2Min_setDependent, cvar2Max_setDependent, 0);
					if (menuTooltipItem.cvar3_setDependent)
					{
						cvar3_s = gettooltip_dependency_string_numeric(menuTooltipItem, cvar3_setDependent, cvar3Min_setDependent, cvar3Max_setDependent, 0);
						s = strcat(s, sprintf((menuTooltipItem.op_setDependent & BIT(0) ? _("Requires %s, %s, and %s") : _("Requires %s, %s, or %s")), cvar1_s, cvar2_s, cvar3_s));
					}
					else
						s = strcat(s, sprintf((menuTooltipItem.op_setDependent & BIT(0) ? _("Requires %s or %s")       : _("Requires %s and %s")),     cvar1_s, cvar2_s));
				}
				else
					s = strcat(s, sprintf(_("Requires %s"), cvar1_s));
			}
			// if this point is reached, it's disabled for some other unknown reason
		}
	}
	else
		s = menuTooltipItem.tooltip;
	return s;
}
void m_tooltip(vector pos)
{
	const float MAX_TOOLTIP_LINES = 16;
	static string prev_tooltip;
	entity it;
	menu_tooltips = cvar("menu_tooltips");
	if (!menu_tooltips)
	{
		// don't return immediately, fade out the active tooltip first
		if (menuTooltipItem == NULL) return;
		it = NULL;
		menu_tooltips_old = menu_tooltips;
	}
	else
	{
		float f = bound(0, frametime * 2, 1);
		menuTooltipAveragedMousePos = menuTooltipAveragedMousePos * (1 - f) + pos * f;
		if (vdist(pos - menuTooltipAveragedMousePos, <, 0.01))
		{
			it = m_findtooltipitem(main, pos);

			if (it.instanceOfListBox && it.isScrolling(it)) it = NULL;

			if (it && prev_tooltip != it.tooltip)
			{
				// fade out if tooltip of a certain item has changed
				menuTooltipState = 3;
				strcpy(prev_tooltip, it.tooltip);
			}
			else if (menuTooltipItem && !m_testmousetooltipbox(pos))
			{
				menuTooltipState = 3;  // fade out if mouse touches it
			}
		}
		else
		{
			it = NULL;
		}
	}
	vector fontsize = '1 0 0' * (SKINFONTSIZE_TOOLTIP / conwidth) + '0 1 0' * (SKINFONTSIZE_TOOLTIP / conheight);

	// float menuTooltipState; // 0: static, 1: fading in, 2: fading out, 3: forced fading out
	if (it != menuTooltipItem)
	{
		switch (menuTooltipState)
		{
			case 0:
				if (menuTooltipItem)
				{
					// another item: fade out first
					menuTooltipState = 2;
				}
				else
				{
					// new item: fade in
					menuTooltipState = 1;
					menuTooltipItem = it;

					menuTooltipOrigin.x = -1;  // unallocated

					strcpy(menuTooltipText, gettooltip());

					float w = 0;
					float lines = 0;
					int n = tokenizebyseparator(menuTooltipText, "\n");
					for (int k = 0; k < n && lines <= MAX_TOOLTIP_LINES; ++k)
					{
						if (argv(k) == "")
						{
							lines += 0.5; // insert a half-height separator between paragraphs (marked by 2 newlines)
							continue;
						}
						for (getWrappedLine_remaining = argv(k); getWrappedLine_remaining && lines <= MAX_TOOLTIP_LINES; ++lines)
						{
							string s = getWrappedLine(SKINWIDTH_TOOLTIP, fontsize, draw_TextWidth_WithColors);
							if (lines + 1 > MAX_TOOLTIP_LINES)
								s = "...";
							float f = draw_TextWidth_WithColors(s, fontsize);
							if (f > w) w = f;
						}
					}
					menuTooltipSize.x = w + 2 * (SKINMARGIN_TOOLTIP_x / conwidth);
					menuTooltipSize.y = lines * fontsize.y + 2 * (SKINMARGIN_TOOLTIP_y / conheight);
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
	else if (menuTooltipState == 2)  // re-fade in?
	{
		menuTooltipState = 1;
	}

	switch (menuTooltipState)
	{
		case 1:  // fade in
			menuTooltipAlpha = bound(0, menuTooltipAlpha + 5 * frametime, 1);
			if (menuTooltipAlpha == 1) menuTooltipState = 0;
			break;
		case 2:  // fade out
		case 3:  // forced fade out
			menuTooltipAlpha = bound(0, menuTooltipAlpha - 2 * frametime, 1);
			if (menuTooltipAlpha == 0)
			{
				menuTooltipState = 0;
				menuTooltipItem = NULL;
			}
			break;
	}

	if (menuTooltipItem == NULL)
	{
		strfree(menuTooltipText);
		return;
	}
	else
	{
		if (menu_tooltips != menu_tooltips_old)
		{
			if (menu_tooltips != 0 && menu_tooltips_old != 0) menuTooltipItem = NULL; // reload tooltip next frame
			menu_tooltips_old = menu_tooltips;
		}
		else if (menuTooltipOrigin.x < 0)                                             // unallocated?
		{
			m_allocatetooltipbox(pos);
		}
		if (menuTooltipOrigin.x >= 0)
		{
			// draw the tooltip!
			vector p = SKINBORDER_TOOLTIP;
			p.x *= 1 / conwidth;
			p.y *= 1 / conheight;
			draw_BorderPicture(menuTooltipOrigin, SKINGFX_TOOLTIP, menuTooltipSize, '1 1 1', menuTooltipAlpha, p);
			p = menuTooltipOrigin;
			p.x += SKINMARGIN_TOOLTIP_x / conwidth;
			p.y += SKINMARGIN_TOOLTIP_y / conheight;
			float lines = 0;
			int n = tokenizebyseparator(menuTooltipText, "\n");
			for (int k = 0; k < n && lines <= MAX_TOOLTIP_LINES; ++k)
			{
				if (argv(k) == "")
				{
					p.y += fontsize.y / 2;
					continue;
				}
				for (getWrappedLine_remaining = argv(k); getWrappedLine_remaining && lines <= MAX_TOOLTIP_LINES; ++lines)
				{
					string s = getWrappedLine(SKINWIDTH_TOOLTIP, fontsize, draw_TextWidth_WithColors);
					if (lines + 1 > MAX_TOOLTIP_LINES)
						s = "...";
					draw_Text(p, s, fontsize, '1 1 1', SKINALPHA_TOOLTIP * menuTooltipAlpha, true);
					p.y += fontsize.y;
				}
			}
		}
	}
}

const int MIN_DISCONNECTION_TIME = 1;
bool autocvar_g_campaign;
void m_draw(float width, float height)
{
	static float connected_time;
	if (clientstate() == CS_DISCONNECTED)
	{
		// avoid a bug where the main menu re-opens when changing maps
		// potentially exclusive to `map <mapname>` cmd?
		if (connected_time && time - connected_time > MIN_DISCONNECTION_TIME)
		{
			if (autocvar_g_campaign)
			{
				// in the case player uses the disconnect command (in the console or with a key)
				// reset g_campaign and update menu items to reflect cvar values that may have been restored after quiting the campaign
				// see also LEAVEMATCH_CMD
				cvar_set("g_campaign", "0");
				m_sync();
			}

			// reload the menu so that disconnecting players don't
			// have to press ESC to open it again
			m_toggle(true);

			localcmd("\nmenu_cmd directmenu Welcome RESET\n");
			connected_time = 0;

			// reset main menu
			// FIXME?: find out if anything should be done to reset it more,
			// this is just a fix to make main menu music replay nicely
			menuNotTheFirstFrame = 1;
		}
	}
	else
		connected_time = time;

	m_gamestatus();

	execute_next_frame();

	menuMouseMode = cvar("menu_mouse_absolute");

	if (anim) anim.tickAll(anim);

	UpdateConWidthHeight(width, height, cvar("vid_pixelheight"));

	if (!menuInitialized)
	{
		// TODO draw an info image about this situation
		m_init_delayed();
		return;
	}

	if (menuNotTheFirstFrame == 0) // only fade the menu in once ever
		menuLogoAlpha = -0.8;  // no idea why, but when I start this at zero, it jumps instead of fading FIXME

	if (menuNotTheFirstFrame <= 1) // only once per menu reload
	{
		if (Menu_Active && !autocvar_menu_no_music_nor_welcome)
		{
			localcmd("cd loop $menu_cdtrack\n");

			// TODO: enable this when we have a welcome sound
			// FIXME: change the file used according to the selected announcer
			// Only play the welcome announcement once, not on any menu reloads
			//if (menuNotTheFirstFrame == 0)
			//localcmd("play sound/announcer/default/welcome.wav\n");
		}

		menuNotTheFirstFrame = 2;
	}

	float t = gettime();
	float realFrametime = frametime = min(0.2, t - menuPrevTime);
	menuPrevTime = t;
	time += frametime;

	t = cvar("menu_slowmo");
	if (t)
	{
		frametime *= t;
		realFrametime *= t;
	}
	else
	{
		t = 1;
	}

	if (Menu_Active)
	{
		if (getmousetarget() == (menuMouseMode ? MT_CLIENT : MT_MENU)
		    && (getkeydest() == KEY_MENU || getkeydest() == KEY_MENU_GRABBED))
		    	setkeydest(keyGrabber ? KEY_MENU_GRABBED : KEY_MENU);
		else m_hide();
	}

	if (cvar("cl_capturevideo")) frametime = t / cvar("cl_capturevideo_fps");  // make capturevideo work smoothly

	prevMenuAlpha = menuAlpha;
	if (Menu_Active)
	{
		if (menuAlpha == 0 && menuLogoAlpha < 2)
		{
			menuLogoAlpha += 2 * frametime;
		}
		else
		{
			menuAlpha = min(1, menuAlpha + 5 * frametime);
			menuLogoAlpha = 2;
		}
	}
	else
	{
		menuAlpha = max(0, menuAlpha - 5 * frametime);
		menuLogoAlpha = 2;
	}

	draw_reset_cropped();

	if (!(gamestatus & (GAME_CONNECTED | GAME_ISSERVER)))
	{
		if (menuLogoAlpha > 0)
		{
			draw_reset_full();
			draw_Fill('0 0 0', '1 1 0', SKINCOLOR_BACKGROUND, 1);
			drawBackground(SKINGFX_BACKGROUND, bound(0, menuLogoAlpha, 1), SKINALIGN_BACKGROUND, true);
			draw_reset_cropped();
			if (menuAlpha <= 0 && SKINALPHA_CURSOR_INTRO > 0)
			{
				draw_alpha = SKINALPHA_CURSOR_INTRO * bound(0, menuLogoAlpha, 1);
				draw_drawMousePointer(menuMousePos);
				draw_alpha = 1;
			}
		}
	}
	else if (SKINALPHA_BACKGROUND_INGAME)
	{
		if (menuAlpha > 0)
		{
			draw_reset_full();
			drawBackground(SKINGFX_BACKGROUND_INGAME, menuAlpha * SKINALPHA_BACKGROUND_INGAME,
				SKINALIGN_BACKGROUND_INGAME, false);
			draw_reset_cropped();
		}
	}

	if (menuAlpha != prevMenuAlpha) cvar_set("_menu_alpha", ftos(menuAlpha));

	draw_reset_cropped();
	preMenuDraw();
	draw_reset_cropped();

	if (menuAlpha <= 0)
	{
		if (prevMenuAlpha > 0) main.initializeDialog(main, main.firstChild);
		draw_reset_cropped();
		postMenuDraw();
		return;
	}

	draw_alpha *= menuAlpha;

	if (menuMouseMode)
	{
		vector rawMousePos = getmousepos();
		vector newMouse = globalToBox(rawMousePos, draw_shift, draw_scale);
		if (rawMousePos != '0 0 0' && newMouse != menuMousePos)
		{
			menuMousePos = newMouse;
			if (mouseButtonsPressed) main.mouseDrag(main, menuMousePos);
			else main.mouseMove(main, menuMousePos);
		}
	}
	else if (frametime > 0)
	{
		vector dMouse = getmousepos() * (frametime / realFrametime);  // for capturevideo
		if (dMouse != '0 0 0')
		{
			vector minpos = globalToBox('0 0 0', draw_shift, draw_scale);
			vector maxpos = globalToBox(eX * (realconwidth - 1) + eY * (realconheight - 1), draw_shift, draw_scale);
			dMouse = globalToBoxSize(dMouse, draw_scale);
			menuMousePos += dMouse * cvar("menu_mouse_speed");
			menuMousePos.x = bound(minpos.x, menuMousePos.x, maxpos.x);
			menuMousePos.y = bound(minpos.y, menuMousePos.y, maxpos.y);
			if (mouseButtonsPressed) main.mouseDrag(main, menuMousePos);
			else main.mouseMove(main, menuMousePos);
		}
	}
	main.draw(main);

	m_tooltip(menuMousePos);

	draw_alpha = max(draw_alpha, SKINALPHA_CURSOR_INTRO * bound(0, menuLogoAlpha, 1));

	draw_drawMousePointer(menuMousePos);

	draw_reset_cropped();
	postMenuDraw();

	frametime = 0;
	IL_ENDFRAME();
}

void m_display()
{
	Menu_Active = true;
	setkeydest(KEY_MENU);
	setmousetarget((menuMouseMode ? MT_CLIENT : MT_MENU));

	if (!menuInitialized) return;

	if (mouseButtonsPressed) main.mouseRelease(main, menuMousePos);
	mouseButtonsPressed = 0;

	main.focusEnter(main);
	main.showNotify(main);
}

void m_hide()
{
	Menu_Active = false;
	setkeydest(KEY_GAME);
	setmousetarget(MT_CLIENT);

	if (!menuInitialized) return;

	main.focusLeave(main);
	main.hideNotify(main);
}

void m_toggle(int mode)
{
	if (Menu_Active)
	{
		if (mode == 1) return;
		// when togglemenu is called without arguments (mode is -1)
		// the menu is closed only when connected
		if (mode == -1 && !(gamestatus & GAME_CONNECTED)) return;
		// togglemenu 0 always closes the menu
		m_hide();
	}
	else
	{
		if (mode == 0) return;
		m_display();
	}
}

void Shutdown()
{
	m_hide();
	FOREACH_ENTITY_ORDERED(it.destroy, {
		if (it.classname == "vtbl") continue;
		it.destroy(it);
	});
	cvar_set("_menu_cmd_closemenu_available", "0");
}

void m_focus_item_chain(entity outermost, entity innermost)
{
	if (innermost.parent != outermost) m_focus_item_chain(outermost, innermost.parent);
	innermost.parent.setFocus(innermost.parent, innermost);
}

void m_activate_window(entity wnd)
{
	entity par = wnd.parent;
	if (par) m_activate_window(par);

	if (par.instanceOfModalController)
	{
		if (wnd.tabSelectingButton)
			// tabs
			TabButton_Click(wnd.tabSelectingButton, wnd);
		else
			// root
			par.initializeDialog(par, wnd);
	}
	else if (par.instanceOfNexposee)
	{
		// nexposee (sorry for violating abstraction here)
		par.selectedChild = wnd;
		par.animationState = 1;
		Container_setFocus(par, NULL);
	}
	else if (par.instanceOfContainer)
	{
		// other containers
		if (par.focused) par.setFocus(par, wnd);
	}
}

void m_setpointerfocus(entity wnd)
{
	if (!wnd.instanceOfContainer) return;
	entity focus = wnd.preferredFocusedGrandChild(wnd);
	if (!focus) return;
	menuMousePos = focus.origin + 0.5 * focus.size;
	menuMousePos.x *= 1 / conwidth;
	menuMousePos.y *= 1 / conheight;
	entity par = wnd.parent;
	if (par.focused) par.setFocus(par, wnd);
	if (wnd.focused) m_focus_item_chain(wnd, focus);
}

void m_goto(string itemname, bool hide_menu_on_close)
{
	if (!menuInitialized)
	{
		strcpy(m_goto_buffer, itemname);
		return;
	}
	if (itemname == "")  // this can be called by GameCommand
	{
		if (gamestatus & (GAME_ISSERVER | GAME_CONNECTED))
		{
			m_hide();
			return;
		}
		itemname = "nexposee";
	}

	if (itemname == "nexposee")
	{
		// unlike 'togglemenu 1', this closes modal and root dialogs if opened
		m_activate_window(main.mainNexposee);
		m_display();
	}
	else
	{
		entity e;
		for (e = NULL; (e = find(e, name, itemname)); )
			if (e.classname != "vtbl") break;

		if ((e) && (!e.requiresConnection || (gamestatus & (GAME_ISSERVER | GAME_CONNECTED))))
		{
			m_hide();
			m_activate_window(e);
			m_setpointerfocus(e);
			m_display();
			if (hide_menu_on_close)
			{
				while(e.parent && !(e.instanceOfDialog && e.isTabRoot))
					e = e.parent;
				if (e.instanceOfDialog)
					e.hideMenuOnClose = true;
			}
		}
	}
}

void m_play_focus_sound()
{
	static float menuLastFocusSoundTime;
	if (cvar("menu_sounds") < 2) return;
	if (time - menuLastFocusSoundTime <= 0.25) return;
	localsound(MENU_SOUND_FOCUS);
	menuLastFocusSoundTime = time;
}

void m_play_click_sound(string soundfile)
{
	if (!cvar("menu_sounds")) return;
	localsound(soundfile);
}
