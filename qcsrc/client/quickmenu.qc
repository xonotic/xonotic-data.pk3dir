#include "_all.qh"

#include "hud_config.qh"

#include "../dpdefs/keycodes.qh"

// QUICKMENU_MAXLINES must be <= 10
const int QUICKMENU_MAXLINES = 10;
// visible entries are loaded from QuickMenu_Buffer into QuickMenu_Page_* arrays
string QuickMenu_Page_Command[QUICKMENU_MAXLINES];
string QuickMenu_Page_Description[QUICKMENU_MAXLINES];
int QuickMenu_Page_Command_Type[QUICKMENU_MAXLINES];
int QuickMenu_Page_Entries;
int QuickMenu_Page;
int QuickMenu_Page_ActivatedEntry = -1;
bool QuickMenu_Page_ActivatedEntry_Close;
float QuickMenu_Page_ActivatedEntry_Time;
bool QuickMenu_IsLastPage;
// all the entries are loaded into QuickMenu_Buffer
// each entry (submenu or command) is composed of 2 entries
const int QUICKMENU_MAXENTRIES = 256;
const int QUICKMENU_BUFFER_MAXENTRIES = 2 * QUICKMENU_MAXENTRIES;
int QuickMenu_Buffer = -1;
int QuickMenu_Buffer_Size;
int QuickMenu_Buffer_Index;
string QuickMenu_CurrentSubMenu;
float QuickMenu_TimeOut;

// QuickMenu_Buffer are labeled with these tags
#define QM_TAG_TITLE "T"
#define QM_TAG_SUBMENU "S"
#define QM_TAG_COMMAND "C"
#define QM_TAG_PLCOMMAND "P"

#define QuickMenu_Buffer_Set(tag, string) bufstr_set(QuickMenu_Buffer, QuickMenu_Buffer_Size, strcat(tag, string))
#define QuickMenu_Buffer_Get() bufstr_get(QuickMenu_Buffer, QuickMenu_Buffer_Index)

// if s1 is not empty s will be displayed as command otherwise as submenu
void QuickMenu_Page_LoadEntry(int i, string s, string s1)
{
	//printf("^xc80 entry %d: %s, %s\n", i, s, s1);
	if (QuickMenu_Page_Description[i])
		strunzone(QuickMenu_Page_Description[i]);
	QuickMenu_Page_Description[i] = strzone(s);
	if (QuickMenu_Page_Command[i])
		strunzone(QuickMenu_Page_Command[i]);
	QuickMenu_Page_Command[i] = strzone(s1);
}

void QuickMenu_Page_ClearEntry(int i)
{
	if (QuickMenu_Page_Description[i])
		strunzone(QuickMenu_Page_Description[i]);
	QuickMenu_Page_Description[i] = string_null;
	if (QuickMenu_Page_Command[i])
		strunzone(QuickMenu_Page_Command[i]);
	QuickMenu_Page_Command[i] = string_null;
}

float QuickMenu_Page_Load(string target_submenu, float new_page);
void QuickMenu_Default(string submenu);
bool QuickMenu_Open(string mode, string submenu)
{
	int fh = -1;
	string s;

	if(mode == "")
	{
		if(autocvar_hud_panel_quickmenu_file == "" || autocvar_hud_panel_quickmenu_file == "0")
			mode = "default";
		else
			mode = "file";
	}

	if(mode == "file")
	{
		if(autocvar_hud_panel_quickmenu_file == "" || autocvar_hud_panel_quickmenu_file == "0")
			printf("No file name is set in hud_panel_quickmenu_file, loading default quickmenu\n");
		else
		{
			fh = fopen(autocvar_hud_panel_quickmenu_file, FILE_READ);
			if(fh < 0)
				printf("Couldn't open file \"%s\", loading default quickmenu\n", autocvar_hud_panel_quickmenu_file);
		}
		if(fh < 0)
			mode = "default";
	}

	if(mode == "default")
	{
		QuickMenu_Buffer = buf_create();
		if(QuickMenu_Buffer < 0)
			return false;

		QuickMenu_Default(submenu);
	}
	else if(mode == "file")
	{
		QuickMenu_Buffer = buf_create();
		if(QuickMenu_Buffer < 0)
		{
			fclose(fh);
			return false;
		}

		QuickMenu_Buffer_Size = 0;
		while((s = fgets(fh)) && QuickMenu_Buffer_Size < QUICKMENU_BUFFER_MAXENTRIES)
		{
			// first skip invalid entries, so we don't check them anymore
			float argc;
			argc = tokenize_console(s);
			if(argc == 0 || argv(0) == "")
				continue;
			if(argc == 1)
				QuickMenu_Buffer_Set(QM_TAG_SUBMENU, argv(0));
			else if(argc == 2)
			{
				if(argv(1) == "")
					continue;
				QuickMenu_Buffer_Set(QM_TAG_TITLE, argv(0));
				++QuickMenu_Buffer_Size;
				QuickMenu_Buffer_Set(QM_TAG_COMMAND, argv(1));
			}
			else if(argc == 3)
			{
				// check for special keywords
				float teamplayers = 0, without_me = 0;
				switch(argv(2))
				{
					case "ALLPLAYERS_BUT_ME":		without_me = 1; // fall through
					case "ALLPLAYERS":				teamplayers = 0; break;
					case "OWNTEAMPLAYERS_BUT_ME":	without_me = 1; // fall through
					case "OWNTEAMPLAYERS":			teamplayers = 1; break;
					case "ENEMYTEAMPLAYERS":		teamplayers = 2; break;
					default: continue;
				}

				if(QuickMenu_Buffer_Size + 3 < QUICKMENU_BUFFER_MAXENTRIES)
				{
					QuickMenu_Buffer_Set(QM_TAG_SUBMENU, argv(0));
					++QuickMenu_Buffer_Size;
					QuickMenu_Buffer_Set(QM_TAG_TITLE, strcat(ftos(teamplayers), ftos(without_me))); // put PLCOMMAND arguments in the title string
					++QuickMenu_Buffer_Size;
					QuickMenu_Buffer_Set(QM_TAG_PLCOMMAND, argv(1));
					++QuickMenu_Buffer_Size;
					QuickMenu_Buffer_Set(QM_TAG_SUBMENU, argv(0));
				}
			}
			++QuickMenu_Buffer_Size;
		}
		fclose(fh);
	}
	else
	{
		printf("Unrecognized mode %s\n", mode);
		return false;
	}

	if (QuickMenu_Buffer_Size <= 0)
	{
		buf_del(QuickMenu_Buffer);
		QuickMenu_Buffer = -1;
		return false;
	}

	if(mode == "file")
		QuickMenu_Page_Load(submenu, 0);
	else
		QuickMenu_Page_Load("", 0);

	hud_panel_quickmenu = 1;
	if(autocvar_hud_cursormode)
		setcursormode(1);
	hudShiftState = 0;

	QuickMenu_TimeOut = ((autocvar_hud_panel_quickmenu_time > 0) ? time + autocvar_hud_panel_quickmenu_time : 0);
	return true;
}

void QuickMenu_Buffer_Close()
{
	if (QuickMenu_Buffer >= 0)
	{
		buf_del(QuickMenu_Buffer);
		QuickMenu_Buffer = -1;
		QuickMenu_Buffer_Size = 0;
	}
}

void QuickMenu_Close()
{
	if (QuickMenu_CurrentSubMenu)
		strunzone(QuickMenu_CurrentSubMenu);
	QuickMenu_CurrentSubMenu = string_null;
	int i;
	for (i = 0; i < QUICKMENU_MAXLINES; ++i)
		QuickMenu_Page_ClearEntry(i);
	QuickMenu_Page_Entries = 0;
	hud_panel_quickmenu = 0;
	mouseClicked = 0;
	prevMouseClicked = 0;
	QuickMenu_Buffer_Close();

	if(autocvar_hud_cursormode)
	if(!mv_active)
		setcursormode(0);
}

// It assumes submenu open tag is already detected
void QuickMenu_skip_submenu(string submenu)
{
	string s, z_submenu;
	z_submenu = strzone(submenu);
	for(++QuickMenu_Buffer_Index ; QuickMenu_Buffer_Index < QuickMenu_Buffer_Size; ++QuickMenu_Buffer_Index)
	{
		s = QuickMenu_Buffer_Get();
		if(substring(s, 0, 1) != QM_TAG_SUBMENU)
			continue;
		if(substring(s, 1, -1) == z_submenu) // submenu end
			break;
		QuickMenu_skip_submenu(substring(s, 1, -1));
	}
	strunzone(z_submenu);
}

bool QuickMenu_IsOpened()
{
	return (QuickMenu_Page_Entries > 0);
}

void HUD_Quickmenu_PlayerListEntries(string cmd, int teamplayers, float without_me);
bool HUD_Quickmenu_PlayerListEntries_Create(string cmd, int teamplayers, float without_me)
{
	int i;
	for(i = 0; i < QUICKMENU_MAXLINES; ++i)
		QuickMenu_Page_ClearEntry(i);
	QuickMenu_Buffer_Close();

	QuickMenu_Buffer = buf_create();
	if(QuickMenu_Buffer < 0)
		return false;

	HUD_Quickmenu_PlayerListEntries(cmd, teamplayers, without_me);

	if(QuickMenu_Buffer_Size <= 0)
	{
		buf_del(QuickMenu_Buffer);
		QuickMenu_Buffer = -1;
		return false;
	}
	return true;
}

// new_page 0 means page 0, new_page != 0 means next page
int QuickMenu_Buffer_Index_Prev;
bool QuickMenu_Page_Load(string target_submenu, int new_page)
{
	string s = string_null, cmd = string_null, z_submenu;

	if (new_page == 0)
		QuickMenu_Page = 0;
	else
		++QuickMenu_Page;

	z_submenu = strzone(target_submenu);
	if (QuickMenu_CurrentSubMenu)
		strunzone(QuickMenu_CurrentSubMenu);
	QuickMenu_CurrentSubMenu = strzone(z_submenu);

	QuickMenu_IsLastPage = true;
	QuickMenu_Page_Entries = 0;

	QuickMenu_Buffer_Index = 0;
	if (z_submenu != "")
	{
		// skip everything until the submenu open tag is found
		for( ; QuickMenu_Buffer_Index < QuickMenu_Buffer_Size; ++QuickMenu_Buffer_Index)
		{
			s = QuickMenu_Buffer_Get();
			if(substring(s, 0, 1) == QM_TAG_SUBMENU && substring(s, 1, -1) == z_submenu)
			{
				// printf("^3 beginning of %s\n", z_submenu);
				++QuickMenu_Buffer_Index;
				break; // target_submenu found!
			}
			// printf("^1 skipping %s\n", s);
		}
		if(QuickMenu_Buffer_Index == QuickMenu_Buffer_Size)
			printf("Couldn't find submenu \"%s\"\n", z_submenu);
	}

	// only the last page can contain up to QUICKMENU_MAXLINES entries
	// the other ones contain only (QUICKMENU_MAXLINES - 2) entries
	// so that the panel can show an empty row and "Continue..."
	float first_entry = QuickMenu_Page * (QUICKMENU_MAXLINES - 2);
	int entry_num = 0; // counts entries in target_submenu
	for( ; QuickMenu_Buffer_Index < QuickMenu_Buffer_Size; ++QuickMenu_Buffer_Index)
	{
		s = QuickMenu_Buffer_Get();

		if(z_submenu != "" && substring(s, 1, -1) == z_submenu)
		{
			// printf("^3 end of %s\n", z_submenu);
			break;
		}

		if(entry_num >= first_entry)
		{
			++QuickMenu_Page_Entries;
			if(QuickMenu_Page_Entries == QUICKMENU_MAXLINES - 2)
				QuickMenu_Buffer_Index_Prev = QuickMenu_Buffer_Index;
			else if(QuickMenu_Page_Entries == QUICKMENU_MAXLINES)
			{
				QuickMenu_Page_ClearEntry(QUICKMENU_MAXLINES - 1);
				QuickMenu_Buffer_Index = QuickMenu_Buffer_Index_Prev;
				QuickMenu_IsLastPage = false;
				break;
			}
		}

		// NOTE: entries are loaded starting from 1, not from 0
		if(substring(s, 0, 1) == QM_TAG_SUBMENU)
		{
			if(entry_num >= first_entry)
				QuickMenu_Page_LoadEntry(QuickMenu_Page_Entries, substring(s, 1, -1), "");
			QuickMenu_skip_submenu(substring(s, 1, -1));
		}
		else if(entry_num >= first_entry && substring(s, 0, 1) == QM_TAG_TITLE)
		{
			++QuickMenu_Buffer_Index;
			cmd = QuickMenu_Buffer_Get();
			string command_code = substring(cmd, 0, 1);
			if(command_code == QM_TAG_COMMAND)
				cmd = substring(cmd, 1, -1);
			else if(command_code == QM_TAG_PLCOMMAND)
			{
				// throw away the current quickmenu buffer and load a new one
				cmd = substring(cmd, 1, -1);
				strunzone(z_submenu);
				if(HUD_Quickmenu_PlayerListEntries_Create(cmd, stof(substring(s, 1, 1)), stof(substring(s, 2, 1))))
					return QuickMenu_Page_Load("", 0);
				QuickMenu_Close();
				return false;
			}

			tokenize_console(cmd);
			QuickMenu_Page_Command_Type[QuickMenu_Page_Entries] = (argv(1) && argv(0) == "toggle");

			QuickMenu_Page_LoadEntry(QuickMenu_Page_Entries, substring(s, 1, -1), cmd);
		}

		++entry_num;
	}
	strunzone(z_submenu);
	if (QuickMenu_Page_Entries == 0)
	{
		QuickMenu_Close();
		return false;
	}
	QuickMenu_TimeOut = ((autocvar_hud_panel_quickmenu_time > 0) ? time + autocvar_hud_panel_quickmenu_time : 0);
	return true;
}

bool QuickMenu_ActionForNumber(int num)
{
	if (!QuickMenu_IsLastPage)
	{
		if (num < 0 || num >= QUICKMENU_MAXLINES)
			return false;
		if (num == QUICKMENU_MAXLINES - 1)
			return false;
		if (num == 0)
		{
			QuickMenu_Page_Load(QuickMenu_CurrentSubMenu, +1);
			return false;
		}
	} else if (num <= 0 || num > QuickMenu_Page_Entries)
		return false;

	if (QuickMenu_Page_Command[num] != "")
	{
		localcmd(strcat("\n", QuickMenu_Page_Command[num], "\n"));
		QuickMenu_TimeOut = ((autocvar_hud_panel_quickmenu_time > 0) ? time + autocvar_hud_panel_quickmenu_time : 0);
		return true;
	}
	if (QuickMenu_Page_Description[num] != "")
		QuickMenu_Page_Load(QuickMenu_Page_Description[num], 0);
	return false;
}

void QuickMenu_Page_ActiveEntry(float entry_num)
{
	QuickMenu_Page_ActivatedEntry = entry_num;
	QuickMenu_Page_ActivatedEntry_Time = time + 0.1;
	if(QuickMenu_Page_Command[QuickMenu_Page_ActivatedEntry])
	{
		bool f = QuickMenu_ActionForNumber(QuickMenu_Page_ActivatedEntry);
		// toggle commands don't close the quickmenu
		if(QuickMenu_Page_Command_Type[QuickMenu_Page_ActivatedEntry] == 1)
			QuickMenu_Page_ActivatedEntry_Close = false;
		else
			QuickMenu_Page_ActivatedEntry_Close = (f && !(hudShiftState & S_CTRL));
	}
	else
		QuickMenu_Page_ActivatedEntry_Close = (!(hudShiftState & S_CTRL));
}

bool QuickMenu_InputEvent(float bInputType, float nPrimary, float nSecondary)
{
	// we only care for keyboard events
	if(bInputType == 2)
		return false;

	if(!QuickMenu_IsOpened() || autocvar__hud_configure || mv_active)
		return false;

	if(bInputType == 3)
	{
		mousepos.x = nPrimary;
		mousepos.y = nSecondary;
		return true;
	}

	// allow console bind to work
	string con_keys;
	float keys;
	con_keys = findkeysforcommand("toggleconsole", 0);
	keys = tokenize(con_keys); // findkeysforcommand returns data for this

	bool hit_con_bind = false;
	int i;
	for (i = 0; i < keys; ++i)
	{
		if(nPrimary == stof(argv(i)))
			hit_con_bind = true;
	}

	if(bInputType == 0) {
		if(nPrimary == K_ALT) hudShiftState |= S_ALT;
		if(nPrimary == K_CTRL) hudShiftState |= S_CTRL;
		if(nPrimary == K_SHIFT) hudShiftState |= S_SHIFT;
	}
	else if(bInputType == 1) {
		if(nPrimary == K_ALT) hudShiftState -= (hudShiftState & S_ALT);
		if(nPrimary == K_CTRL) hudShiftState -= (hudShiftState & S_CTRL);
		if(nPrimary == K_SHIFT) hudShiftState -= (hudShiftState & S_SHIFT);
	}

	if(nPrimary == K_ESCAPE)
	{
		if (bInputType == 1)
			return true;
		QuickMenu_Close();
	}
	else if(nPrimary >= '0' && nPrimary <= '9')
	{
		if (bInputType == 1)
			return true;
		QuickMenu_Page_ActiveEntry(stof(chr2str(nPrimary)));
	}
	if(nPrimary == K_MOUSE1)
	{
		if(bInputType == 0) // key pressed
			mouseClicked |= S_MOUSE1;
		else if(bInputType == 1) // key released
			mouseClicked -= (mouseClicked & S_MOUSE1);
	}
	else if(nPrimary == K_MOUSE2)
	{
		if(bInputType == 0) // key pressed
			mouseClicked |= S_MOUSE2;
		else if(bInputType == 1) // key released
			mouseClicked -= (mouseClicked & S_MOUSE2);
	}
	else if(hit_con_bind)
		return false;

	return true;
}

void QuickMenu_Mouse()
{
	if(mv_active) return;

	if(!mouseClicked)
	if(prevMouseClicked & S_MOUSE2)
	{
		QuickMenu_Close();
		return;
	}

	if(!autocvar_hud_cursormode)
	{
		mousepos = mousepos + getmousepos() * autocvar_menu_mouse_speed;

		mousepos.x = bound(0, mousepos.x, vid_conwidth);
		mousepos.y = bound(0, mousepos.y, vid_conheight);
	}

	HUD_Panel_UpdateCvars();

	if(panel_bg_padding)
	{
		panel_pos += '1 1 0' * panel_bg_padding;
		panel_size -= '2 2 0' * panel_bg_padding;
	}

	float first_entry_pos, entries_height;
	vector fontsize;
	fontsize = '1 1 0' * (panel_size.y / QUICKMENU_MAXLINES);
	first_entry_pos = panel_pos.y + ((QUICKMENU_MAXLINES - QuickMenu_Page_Entries) * fontsize.y) / 2;
	entries_height = panel_size.y - ((QUICKMENU_MAXLINES - QuickMenu_Page_Entries) * fontsize.y);

	if (mousepos.x >= panel_pos.x && mousepos.y >= first_entry_pos && mousepos.x <= panel_pos.x + panel_size.x && mousepos.y <= first_entry_pos + entries_height)
	{
		float entry_num;
		entry_num = floor((mousepos.y - first_entry_pos) / fontsize.y);
		if (QuickMenu_IsLastPage || entry_num != QUICKMENU_MAXLINES - 2)
		{
			panel_pos.y = first_entry_pos + entry_num * fontsize.y;
			vector color;
			if(mouseClicked & S_MOUSE1)
				color = '0.5 1 0.5';
			else if(hudShiftState & S_CTRL)
				color = '1 1 0.3';
			else
				color = '1 1 1';
			drawfill(panel_pos, eX * panel_size.x + eY * fontsize.y, color, .2, DRAWFLAG_NORMAL);

			if(!mouseClicked && (prevMouseClicked & S_MOUSE1))
				QuickMenu_Page_ActiveEntry((entry_num < QUICKMENU_MAXLINES - 1) ? entry_num + 1 : 0);
		}
	}

	vector cursorsize = '32 32 0';
	drawpic(mousepos, strcat("gfx/menu/", autocvar_menu_skin, "/cursor.tga"), cursorsize, '1 1 1', 0.8, DRAWFLAG_NORMAL);

	prevMouseClicked = mouseClicked;
}

void HUD_Quickmenu_DrawEntry(vector pos, string desc, string option, vector fontsize)
{
	string entry;
	float offset;
	float desc_width = panel_size.x;
	if(option)
	{
		string pic = strcat(hud_skin_path, "/", option);
		if(precache_pic(pic) == "")
			pic = strcat("gfx/hud/default/", option);
		vector option_size = '1 1 0' * fontsize.y * 0.8;
		desc_width -= option_size.x;
		drawpic(pos + eX * desc_width + eY * (fontsize.y - option_size.y) / 2, pic, option_size, '1 1 1', panel_fg_alpha, DRAWFLAG_ADDITIVE);
		desc_width -= fontsize.x / 4;
	}
	entry = textShortenToWidth(desc, desc_width, fontsize, stringwidth_colors);
	if (autocvar_hud_panel_quickmenu_align > 0)
	{
		float real_desc_width = stringwidth_colors(entry, fontsize);
		offset = (desc_width - real_desc_width) * min(autocvar_hud_panel_quickmenu_align, 1);

		if(option)
		{
			// when there's enough room align description regardless the checkbox
			float extra_offset = (panel_size.x - desc_width) * min(autocvar_hud_panel_quickmenu_align, 1);
			if(offset + real_desc_width + extra_offset < desc_width)
				offset += extra_offset;
			else
				offset = max(0, desc_width - real_desc_width);
		}
		drawcolorcodedstring(pos + eX * offset, entry, fontsize, panel_fg_alpha, DRAWFLAG_ADDITIVE);
	}
	else
		drawcolorcodedstring(pos, entry, fontsize, panel_fg_alpha, DRAWFLAG_ADDITIVE);
}

void HUD_QuickMenu(void)
{
	if(!autocvar__hud_configure)
	{
		if (hud_configure_prev && hud_configure_prev != -1)
			QuickMenu_Close();

		if(!hud_draw_maximized) return;
		if(mv_active) return;
		//if(!autocvar_hud_panel_quickmenu) return;
		if(!hud_panel_quickmenu) return;

		if(QuickMenu_TimeOut)
		if(time > QuickMenu_TimeOut)
		{
			QuickMenu_Close();
			return;
		}
	}
	else
	{
		if(!QuickMenu_IsOpened())
		{
			QuickMenu_Page_Entries = 1;
			QuickMenu_Page_LoadEntry(QuickMenu_Page_Entries, sprintf(_("Submenu%d"), QuickMenu_Page_Entries), "");
			++QuickMenu_Page_Entries;
			QuickMenu_Page_LoadEntry(QuickMenu_Page_Entries, sprintf(_("Submenu%d"), QuickMenu_Page_Entries), "");
			++QuickMenu_Page_Entries;
			// although real command doesn't matter here, it must not be empty
			// otherwise the entry is displayed like a submenu
			for (; QuickMenu_Page_Entries < QUICKMENU_MAXLINES - 1; ++QuickMenu_Page_Entries)
				QuickMenu_Page_LoadEntry(QuickMenu_Page_Entries, sprintf(_("Command%d"), QuickMenu_Page_Entries), "-");
			++QuickMenu_Page_Entries;
			QuickMenu_Page_ClearEntry(QuickMenu_Page_Entries);
			QuickMenu_IsLastPage = false;
		}
	}

	HUD_Panel_UpdateCvars();

	HUD_Panel_DrawBg(1);

	if(panel_bg_padding)
	{
		panel_pos += '1 1 0' * panel_bg_padding;
		panel_size -= '2 2 0' * panel_bg_padding;
	}

	int i;
	vector fontsize;
	string color;
	fontsize = '1 1 0' * (panel_size.y / QUICKMENU_MAXLINES);

	if (!QuickMenu_IsLastPage)
	{
		color = "^5";
		HUD_Quickmenu_DrawEntry(panel_pos + eY * (panel_size.y - fontsize.y), sprintf("%d: %s%s", 0, color, _("Continue...")), string_null, fontsize);
	}
	else
		panel_pos.y += ((QUICKMENU_MAXLINES - QuickMenu_Page_Entries) * fontsize.y) / 2;

	for (i = 1; i <= QuickMenu_Page_Entries; ++i) {
		if (QuickMenu_Page_Description[i] == "")
			break;
		string option = string_null;
		if (QuickMenu_Page_Command[i] == "")
			color = "^4";
		else
		{
			color = "^3";
			if(QuickMenu_Page_Command_Type[i] == 1) // toggle command
			{
				int end = strstrofs(QuickMenu_Page_Command[i], ";", 0);
				if(end < 0)
					tokenize_console(QuickMenu_Page_Command[i]);
				else
					tokenize_console(substring(QuickMenu_Page_Command[i], 0, end));

				//if(argv(1) && argv(0) == "toggle") // already checked
				{
					// "enable feature xxx" "toggle xxx" (or "toggle xxx 1 0")
					// "disable feature xxx" "toggle xxx 0 1"
					float ON_value = 1, OFF_value = 0;
					if(argv(2))
						ON_value = stof(argv(2));

					if(argv(3))
						OFF_value = stof(argv(3));
					else
						OFF_value = !ON_value;

					float value = cvar(argv(1));
					if(value == ON_value)
						option = "checkbox_checked";
					else if(value == OFF_value)
						option = "checkbox_empty";
					else
						option = "checkbox_undefined";
				}
			}
		}
		HUD_Quickmenu_DrawEntry(panel_pos, sprintf("%d: %s%s", i, color, QuickMenu_Page_Description[i]), option, fontsize);

		if(QuickMenu_Page_ActivatedEntry_Time && time < QuickMenu_Page_ActivatedEntry_Time
			&& QuickMenu_Page_ActivatedEntry == i)
			drawfill(panel_pos, eX * panel_size.x + eY * fontsize.y, '0.5 1 0.5', .2, DRAWFLAG_NORMAL);

		panel_pos.y += fontsize.y;
	}

	if(QuickMenu_Page_ActivatedEntry >= 0 && time >= QuickMenu_Page_ActivatedEntry_Time)
	{
		if(!QuickMenu_Page_Command[QuickMenu_Page_ActivatedEntry])
		{
			bool f = QuickMenu_ActionForNumber(QuickMenu_Page_ActivatedEntry);
			if(f && QuickMenu_Page_ActivatedEntry_Close)
				QuickMenu_Close();
		}
		else if(QuickMenu_Page_ActivatedEntry_Close)
			QuickMenu_Close();
		QuickMenu_Page_ActivatedEntry = -1;
		QuickMenu_Page_ActivatedEntry_Time = 0;
	}
}


#define QUICKMENU_SMENU(submenu,eng_submenu) { \
	if(target_submenu == eng_submenu && target_submenu_found) \
		return; /* target_submenu entries are now loaded, exit */ \
	if(QuickMenu_Buffer_Size < QUICKMENU_BUFFER_MAXENTRIES) \
		QuickMenu_Buffer_Set(QM_TAG_SUBMENU, submenu); \
	++QuickMenu_Buffer_Size; \
	if(target_submenu == eng_submenu && !target_submenu_found) { \
		QuickMenu_Buffer_Size = 0; /* enable load of next entries */ \
		target_submenu_found = true; \
	} \
}

#define QUICKMENU_ENTRY(title,command) { \
	if(QuickMenu_Buffer_Size + 1 < QUICKMENU_BUFFER_MAXENTRIES) \
	{ \
		QuickMenu_Buffer_Set(QM_TAG_TITLE, title); \
		++QuickMenu_Buffer_Size; \
		QuickMenu_Buffer_Set(QM_TAG_COMMAND, command); \
	} \
	++QuickMenu_Buffer_Size; \
}

#define QUICKMENU_SMENU_PL(submenu,eng_submenu,command,teamplayers,without_me) { \
	if(QuickMenu_Buffer_Size + 3 < QUICKMENU_BUFFER_MAXENTRIES) {\
		QUICKMENU_SMENU(submenu,eng_submenu) \
		QuickMenu_Buffer_Set(QM_TAG_TITLE, strcat(ftos(teamplayers), ftos(without_me))); \
		++QuickMenu_Buffer_Size; \
		QuickMenu_Buffer_Set(QM_TAG_PLCOMMAND, command); \
		++QuickMenu_Buffer_Size; \
		QUICKMENU_SMENU(submenu,eng_submenu) \
	} \
}



// useful to Translate a string inside the Command
#define QUICKMENU_ENTRY_TC(title,command,text,translated_text) {\
	if(prvm_language == "en") \
		QUICKMENU_ENTRY(title, sprintf(command, text)) \
	else if(!autocvar_hud_panel_quickmenu_translatecommands || translated_text == text) \
		QUICKMENU_ENTRY(strcat("(en)", title), sprintf(command, text)) \
	else \
		QUICKMENU_ENTRY(strcat("(", prvm_language, ")", title), sprintf(command, translated_text)) \
}

void HUD_Quickmenu_PlayerListEntries(string cmd, float teamplayers, float without_me)
{
	entity pl;
	if(teamplayers && !team_count)
		return;

	for(pl = players.sort_next; pl; pl = pl.sort_next)
	{
		if(teamplayers == 1 && (pl.team != myteam || pl.team == NUM_SPECTATOR)) // only own team players
			continue;
		if(teamplayers == 2 && (pl.team == myteam || pl.team == NUM_SPECTATOR)) // only enemy team players
			continue;
		if(without_me && pl.sv_entnum == player_localnum)
			continue;
		QUICKMENU_ENTRY(GetPlayerName(pl.sv_entnum), sprintf(cmd, GetPlayerName(pl.sv_entnum)))
	}

	return;
}


// Specifying target_submenu, this function only loads entries inside target_submenu
// NOTE: alternatively we could have loaded the whole default quickmenu and
// then called QuickMenu_Page_Load(target_submenu, 0);
// but this sytem is more reliable since we can always refer to target_submenu
// with the English title even if a translation is active
void QuickMenu_Default(string target_submenu)
{
	bool target_submenu_found = false;
	if(target_submenu != "")
		QuickMenu_Buffer_Size = QUICKMENU_BUFFER_MAXENTRIES; // forbids load of next entries until target_submenu

	QUICKMENU_SMENU(CTX(_("QMCMD^Chat")), "Chat")
		QUICKMENU_ENTRY_TC(CTX(_("QMCMD^nice one")), "say %s", ":-) / nice one", CTX(_("QMCMD^:-) / nice one")))
		QUICKMENU_ENTRY_TC(CTX(_("QMCMD^good game")), "say %s", "good game", CTX(_("QMCMD^good game")))
		QUICKMENU_ENTRY_TC(CTX(_("QMCMD^hi / good luck")), "say %s", "hi / good luck and have fun", CTX(_("QMCMD^hi / good luck and have fun")))
	QUICKMENU_SMENU(CTX(_("QMCMD^Chat")), "Chat")

	if(teamplay)
	{
	QUICKMENU_SMENU(CTX(_("QMCMD^Team chat")), "Team chat")
		QUICKMENU_ENTRY_TC(CTX(_("QMCMD^quad soon")), "say_team %s", "quad soon", CTX(_("QMCMD^quad soon")))
		QUICKMENU_ENTRY_TC(CTX(_("QMCMD^free item, icon")), "say_team %s; g_waypointsprite_team_here_p", "free item %x^7 (l:%y^7)", CTX(_("QMCMD^free item %x^7 (l:%y^7)")))
		QUICKMENU_ENTRY_TC(CTX(_("QMCMD^took item, icon")), "say_team %s; g_waypointsprite_team_here", "took item (l:%l^7)", CTX(_("QMCMD^took item (l:%l^7)")))
		QUICKMENU_ENTRY_TC(CTX(_("QMCMD^negative")), "say_team %s", "negative", CTX(_("QMCMD^negative")))
		QUICKMENU_ENTRY_TC(CTX(_("QMCMD^positive")), "say_team %s", "positive", CTX(_("QMCMD^positive")))
		QUICKMENU_ENTRY_TC(CTX(_("QMCMD^need help, icon")), "say_team %s; g_waypointsprite_team_helpme; cmd voice needhelp", "need help (l:%l^7) (h:%h^7 a:%a^7 w:%w^7)", CTX(_("QMCMD^need help (l:%l^7) (h:%h^7 a:%a^7 w:%w^7)")))
		QUICKMENU_ENTRY_TC(CTX(_("QMCMD^enemy seen, icon")), "say_team %s; g_waypointsprite_team_danger_p; cmd voice incoming", "enemy seen (l:%y^7)", CTX(_("QMCMD^enemy seen (l:%y^7)")))
		QUICKMENU_ENTRY_TC(CTX(_("QMCMD^flag seen, icon")), "say_team %s; g_waypointsprite_team_here_p; cmd voice seenflag", "flag seen (l:%y^7)", CTX(_("QMCMD^flag seen (l:%y^7)")))
		QUICKMENU_ENTRY_TC(CTX(_("QMCMD^defending, icon")), "say_team %s; g_waypointsprite_team_here", "defending (l:%l^7) (h:%h^7 a:%a^7 w:%w^7)", CTX(_("QMCMD^defending (l:%l^7) (h:%h^7 a:%a^7 w:%w^7)")))
		QUICKMENU_ENTRY_TC(CTX(_("QMCMD^roaming, icon")), "say_team %s; g_waypointsprite_team_here", "roaming (l:%l^7) (h:%h^7 a:%a^7 w:%w^7)", CTX(_("QMCMD^roaming (l:%l^7) (h:%h^7 a:%a^7 w:%w^7)")))
		QUICKMENU_ENTRY_TC(CTX(_("QMCMD^attacking, icon")), "say_team %s; g_waypointsprite_team_here", "attacking (l:%l^7) (h:%h^7 a:%a^7 w:%w^7)", CTX(_("QMCMD^attacking (l:%l^7) (h:%h^7 a:%a^7 w:%w^7)")))
		QUICKMENU_ENTRY_TC(CTX(_("QMCMD^killed flag, icon")), "say_team %s; g_waypointsprite_team_here_p", "killed flagcarrier (l:%y^7)", CTX(_("QMCMD^killed flagcarrier (l:%y^7)")))
		QUICKMENU_ENTRY_TC(CTX(_("QMCMD^dropped flag, icon")), "say_team %s; g_waypointsprite_team_here_d", "dropped flag (l:%d^7)", CTX(_("QMCMD^dropped flag (l:%d^7)")))
		QUICKMENU_ENTRY_TC(CTX(_("QMCMD^drop gun, icon")), "say_team %s; g_waypointsprite_team_here; wait; dropweapon", "dropped gun %w^7 (l:%l^7)", CTX(_("QMCMD^dropped gun %w^7 (l:%l^7)")))
		QUICKMENU_ENTRY_TC(CTX(_("QMCMD^drop flag/key, icon")), "say_team %s; g_waypointsprite_team_here; wait; use", "dropped flag/key %w^7 (l:%l^7)", CTX(_("QMCMD^dropped flag/key %w^7 (l:%l^7)")))
	QUICKMENU_SMENU(CTX(_("QMCMD^Team chat")), "Team chat")
	}

	QUICKMENU_SMENU_PL(CTX(_("QMCMD^Send private message to")), "Send private message to", "commandmode tell \"%s^7\"", 0, 1)

	QUICKMENU_SMENU(CTX(_("QMCMD^Settings")), "Settings")
		QUICKMENU_SMENU(CTX(_("QMCMD^View/HUD settings")), "View/HUD settings")
			QUICKMENU_ENTRY(CTX(_("QMCMD^3rd person view")), "toggle chase_active")
			QUICKMENU_ENTRY(CTX(_("QMCMD^Player models like mine")), "toggle cl_forceplayermodels")
			QUICKMENU_ENTRY(CTX(_("QMCMD^Names above players")), "toggle hud_shownames")
			QUICKMENU_ENTRY(CTX(_("QMCMD^Crosshair per weapon")), "toggle crosshair_per_weapon")
			QUICKMENU_ENTRY(CTX(_("QMCMD^FPS")), "toggle hud_panel_engineinfo")
			QUICKMENU_ENTRY(CTX(_("QMCMD^Net graph")), "toggle shownetgraph")
		QUICKMENU_SMENU(CTX(_("QMCMD^View/HUD settings")), "View/HUD settings")

		QUICKMENU_SMENU(CTX(_("QMCMD^Sound settings")), "Sound settings")
			QUICKMENU_ENTRY(CTX(_("QMCMD^Hit sound")), "toggle cl_hitsound")
			QUICKMENU_ENTRY(CTX(_("QMCMD^Chat sound")), "toggle con_chatsound")
		QUICKMENU_SMENU(CTX(_("QMCMD^Sound settings")), "Sound settings")

		if(spectatee_status > 0)
		{
		QUICKMENU_SMENU(CTX(_("QMCMD^Spectator camera")), "Spectator camera")
			QUICKMENU_ENTRY(CTX(_("QMCMD^1st person")), "chase_active 0; -use")
			QUICKMENU_ENTRY(CTX(_("QMCMD^3rd person around player")), "chase_active 1; +use")
			QUICKMENU_ENTRY(CTX(_("QMCMD^3rd person behind")), "chase_active 1; -use")
		QUICKMENU_SMENU(CTX(_("QMCMD^Spectator camera")), "Spectator camera")
		}

		if(spectatee_status == -1)
		{
		QUICKMENU_SMENU(CTX(_("QMCMD^Observer camera")), "Observer camera")
			QUICKMENU_ENTRY(CTX(_("QMCMD^Increase speed")), "weapnext")
			QUICKMENU_ENTRY(CTX(_("QMCMD^Decrease speed")), "weapprev")
			QUICKMENU_ENTRY(CTX(_("QMCMD^Wall collision off")), "+use")
			QUICKMENU_ENTRY(CTX(_("QMCMD^Wall collision on")), "-use")
		QUICKMENU_SMENU(CTX(_("QMCMD^Observer camera")), "Observer camera")
		}

		QUICKMENU_ENTRY(CTX(_("QMCMD^Fullscreen")), "toggle vid_fullscreen; vid_restart")
		if(prvm_language != "en")
		QUICKMENU_ENTRY(CTX(_("QMCMD^Translate chat messages")), "toggle hud_panel_quickmenu_translatecommands")
	QUICKMENU_SMENU(CTX(_("QMCMD^Settings")), "Settings")

	QUICKMENU_SMENU(CTX(_("QMCMD^Call a vote")), "Call a vote")
		QUICKMENU_ENTRY(CTX(_("QMCMD^Restart the map")), "vcall restart")
		QUICKMENU_ENTRY(CTX(_("QMCMD^End match")), "vcall endmatch")
		if(getstatf(STAT_TIMELIMIT) > 0)
		{
		QUICKMENU_ENTRY(CTX(_("QMCMD^Reduce match time")), "vcall reducematchtime")
		QUICKMENU_ENTRY(CTX(_("QMCMD^Extend match time")), "vcall extendmatchtime")
		}
		if(teamplay)
		QUICKMENU_ENTRY(CTX(_("QMCMD^Shuffle teams")), "vcall shuffleteams")
	QUICKMENU_SMENU(CTX(_("QMCMD^Call a vote")), "Call a vote")

	if(target_submenu != "" && !target_submenu_found)
	{
		printf("Couldn't find submenu \"%s\"\n", target_submenu);
		if(prvm_language != "en")
			printf("^3Warning: submenu must be in English\n", target_submenu);
		QuickMenu_Buffer_Size = 0;
	}
}
#undef QUICKMENU_SMENU
#undef QUICKMENU_ENTRY
#undef QUICKMENU_ENTRY_TC
