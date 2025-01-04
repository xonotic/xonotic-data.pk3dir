#include "quickmenu.qh"

#include <client/draw.qh>
#include <client/hud/_mod.qh>
#include <client/mapvoting.qh>
#include <common/ent_cs.qh>
#include <common/minigames/cl_minigames.qh>
#include <client/view.qh>

// QuickMenu (#23)

void HUD_QuickMenu_Export(int fh)
{
	// allow saving cvars that aesthetically change the panel into hud skin files
	HUD_Write_Cvar("hud_panel_quickmenu_align");
}

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
#define QM_TAG_KCOMMAND "K"
#define QM_TAG_PLCOMMAND "P"

// QuickMenu_Page_Command_Type
#define QM_PCT_NONE 0
#define QM_PCT_TOGGLE 1
#define QM_PCT_KEEP 2

#define QuickMenu_Buffer_Set(tag, string) bufstr_set(QuickMenu_Buffer, QuickMenu_Buffer_Size, strcat(tag, string))
#define QuickMenu_Buffer_Get() bufstr_get(QuickMenu_Buffer, QuickMenu_Buffer_Index)

#define QUICKMENU_ENTRY_TAG(title, command, tag) { \
	if(QuickMenu_Buffer_Size + 1 < QUICKMENU_BUFFER_MAXENTRIES) \
	{ \
		QuickMenu_Buffer_Set(QM_TAG_TITLE, title); \
		++QuickMenu_Buffer_Size; \
		QuickMenu_Buffer_Set(tag, command); \
	} \
	++QuickMenu_Buffer_Size; \
}

#define QUICKMENU_ENTRY(title, command) QUICKMENU_ENTRY_TAG(title, command, QM_TAG_COMMAND)

// special entries are shown with a different color
#define QUICKMENU_ENTRY_SPECIAL(title, command) QUICKMENU_ENTRY(title, strcat("\n", command))


void QuickMenu_TimeOut_Set()
{
	QuickMenu_TimeOut = ((autocvar_hud_panel_quickmenu_time > 0) ? time + autocvar_hud_panel_quickmenu_time : 0);
}

// if s1 is not empty s will be displayed as command otherwise as submenu
void QuickMenu_Page_LoadEntry(int i, string s, string s1)
{
	TC(int, i);
	//LOG_INFOF("^xc80 entry %d: %s, %s\n", i, s, s1);
	strcpy(QuickMenu_Page_Description[i], s);
	strcpy(QuickMenu_Page_Command[i], s1);
}

void QuickMenu_Page_ClearEntry(int i)
{
	TC(int, i);
	strfree(QuickMenu_Page_Description[i]);
	strfree(QuickMenu_Page_Command[i]);
	QuickMenu_Page_Command_Type[i] = 0;
}

bool HUD_QuickMenu_Forbidden()
{
	return (mv_active
		|| intermission_time == time // close upon game over, can still be opened during intermission
		|| scoreboard_ui_enabled
		|| (hud_configure_prev && hud_configure_prev != -1)
		|| HUD_MinigameMenu_IsOpened()
		|| (QuickMenu_TimeOut && time > QuickMenu_TimeOut));
}

// returns true if succeded, false otherwise
bool QuickMenu_Open(string mode, string submenu, string file)
{
	QuickMenu_TimeOut = 0;
	if (HUD_QuickMenu_Forbidden())
		return false;

	int fh = -1;
	string s;

	if(mode == "")
	{
		if(file == "" || file == "0")
			mode = "default";
		else
			mode = "file";
	}

	if(mode == "default")
	{
		if (autocvar_hud_panel_quickmenu_server_is_default && autocvar__hud_panel_quickmenu_file_from_server != "")
		{
			mode = "file";
			file = autocvar__hud_panel_quickmenu_file_from_server;
		}
	}

	if(mode == "file")
	{
		if(file == "" || file == "0")
			LOG_INFO("No file name is set in hud_panel_quickmenu_file, loading default quickmenu");
		else
		{
			fh = fopen(file, FILE_READ);
			if(fh < 0)
				LOG_INFOF("Couldn't open file \"%s\", loading default quickmenu", file);
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
			int argc;
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
			else if(argc == 3 && argv(2) == "KEEP_OPEN")
			{
				if(argv(1) == "")
					continue;
				QuickMenu_Buffer_Set(QM_TAG_TITLE, argv(0));
				++QuickMenu_Buffer_Size;
				QuickMenu_Buffer_Set(QM_TAG_KCOMMAND, argv(1));
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

		// forcedly add this entry
		if (autocvar_hud_panel_quickmenu_server_is_default && autocvar__hud_panel_quickmenu_file_from_server != "")
		{
			string prev_value = cvar_string("hud_panel_quickmenu_server_is_default");
			QUICKMENU_ENTRY_SPECIAL(_("Standard quick menu"), sprintf("hud_panel_quickmenu_server_is_default 0; quickmenu; wait; quickmenu; wait; hud_panel_quickmenu_server_is_default \"%s\"", prev_value))
		}
	}
	else
	{
		LOG_WARNF("Unrecognized mode %s", mode);
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

	mouseClicked = 0;
	hudShiftState = 0;

	Release_Common_Keys();

	QuickMenu_TimeOut_Set();
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
	strfree(QuickMenu_CurrentSubMenu);
	int i;
	for (i = 0; i < QUICKMENU_MAXLINES; ++i)
		QuickMenu_Page_ClearEntry(i);
	QuickMenu_Page_Entries = 0;
	mouseClicked = 0;
	prevMouseClicked = 0;
	QuickMenu_Buffer_Close();
}

// It assumes submenu open tag is already detected
void QuickMenu_skip_submenu(string submenu)
{
	string z_submenu = string_null; strcpy(z_submenu, submenu);
	for(++QuickMenu_Buffer_Index ; QuickMenu_Buffer_Index < QuickMenu_Buffer_Size; ++QuickMenu_Buffer_Index)
	{
		string s = QuickMenu_Buffer_Get();
		if(substring(s, 0, 1) != QM_TAG_SUBMENU)
			continue;
		if(substring(s, 1, -1) == z_submenu) // submenu end
			break;
		QuickMenu_skip_submenu(substring(s, 1, -1));
	}
	strfree(z_submenu);
}

bool QuickMenu_IsOpened()
{
	return (QuickMenu_Page_Entries > 0);
}

bool HUD_Quickmenu_PlayerListEntries_Create(string cmd, int teamplayers, bool without_me)
{
	TC(int, teamplayers); TC(bool, without_me);
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
bool QuickMenu_Page_Load(string target_submenu, bool new_page)
{
	TC(bool, new_page);
	string s = string_null, cmd = string_null, z_submenu;

	QuickMenu_Page_ActivatedEntry = -1;
	if (new_page == 0)
		QuickMenu_Page = 0;
	else
		++QuickMenu_Page;

	z_submenu = strzone(target_submenu);
	strcpy(QuickMenu_CurrentSubMenu, z_submenu);

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
				//LOG_INFOF("^3 beginning of %s\n", z_submenu);
				++QuickMenu_Buffer_Index;
				break; // target_submenu found!
			}
			//LOG_INFOF("^1 skipping %s\n", s);
		}
		if(QuickMenu_Buffer_Index == QuickMenu_Buffer_Size)
			LOG_WARNF("Couldn't find submenu \"%s\"", z_submenu);
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
			//LOG_INFOF("^3 end of %s\n", z_submenu);
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
		else if(substring(s, 0, 1) == QM_TAG_TITLE)
		{
			++QuickMenu_Buffer_Index;
			if(entry_num >= first_entry)
			{
				cmd = QuickMenu_Buffer_Get();
				string command_code = substring(cmd, 0, 1);
				if(command_code == QM_TAG_COMMAND)
				{
					cmd = substring(cmd, 1, -1);
					QuickMenu_Page_Command_Type[QuickMenu_Page_Entries] = QM_PCT_NONE;
				}
				else if(command_code == QM_TAG_KCOMMAND)
				{
					cmd = substring(cmd, 1, -1);
					QuickMenu_Page_Command_Type[QuickMenu_Page_Entries] = QM_PCT_KEEP;
				}
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
				if(argv(1) && argv(0) == "toggle")
					QuickMenu_Page_Command_Type[QuickMenu_Page_Entries] = QM_PCT_TOGGLE;

				QuickMenu_Page_LoadEntry(QuickMenu_Page_Entries, substring(s, 1, -1), cmd);
			}

		}

		++entry_num;
	}
	strunzone(z_submenu);
	if (QuickMenu_Page_Entries == 0)
	{
		QuickMenu_Close();
		return false;
	}
	QuickMenu_TimeOut_Set();
	return true;
}

bool QuickMenu_ActionForNumber(int num)
{
	TC(int, num);
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
		QuickMenu_Page_ActivatedEntry_Time = time + 0.1;
		localcmd(strcat("\n", QuickMenu_Page_Command[num], "\n"));
		QuickMenu_TimeOut_Set();
		if(QuickMenu_Page_Command_Type[num] == QM_PCT_TOGGLE || QuickMenu_Page_Command_Type[num] == QM_PCT_KEEP)
			return false;
		else
			return true;
	}
	if (QuickMenu_Page_Description[num] != "")
		QuickMenu_Page_Load(QuickMenu_Page_Description[num], 0);
	return false;
}

void QuickMenu_Page_ActiveEntry(int entry_num)
{
	TC(int, entry_num);
	QuickMenu_Page_ActivatedEntry = entry_num;
	if(QuickMenu_Page_Command[QuickMenu_Page_ActivatedEntry])
	{
		bool f = QuickMenu_ActionForNumber(QuickMenu_Page_ActivatedEntry);
		QuickMenu_Page_ActivatedEntry_Close = (hudShiftState & S_CTRL) ? !f : f;
	}
	else
		QuickMenu_Page_ActivatedEntry_Close = (!(hudShiftState & S_CTRL));
}

bool QuickMenu_InputEvent(int bInputType, float nPrimary, float nSecondary)
{
	TC(int, bInputType);

	if(!QuickMenu_IsOpened() || autocvar__hud_configure || mv_active)
		return false;

	if(bInputType == 3)
	{
		mousepos.x = nPrimary;
		mousepos.y = nSecondary;
		return true;
	}

	if(bInputType == 2)
		return false;

	// at this point bInputType can only be 0 or 1 (key pressed or released)
	bool key_pressed = (bInputType == 0);

	int hudShiftState_prev = hudShiftState;
	int mouseClicked_prev = mouseClicked;
	if(key_pressed)
	{
		if(nPrimary == K_ALT) hudShiftState |= S_ALT;
		if(nPrimary == K_CTRL) hudShiftState |= S_CTRL;
		if(nPrimary == K_SHIFT) hudShiftState |= S_SHIFT;
		if(nPrimary == K_MOUSE1) mouseClicked |= S_MOUSE1;
		if(nPrimary == K_MOUSE2) mouseClicked |= S_MOUSE2;
	}
	else
	{
		if(nPrimary == K_ALT) hudShiftState &= ~S_ALT;
		if(nPrimary == K_CTRL) hudShiftState &= ~S_CTRL;
		if(nPrimary == K_SHIFT) hudShiftState &= ~S_SHIFT;
		if(nPrimary == K_MOUSE1) mouseClicked &= ~S_MOUSE1;
		if(nPrimary == K_MOUSE2) mouseClicked &= ~S_MOUSE2;
	}

	if(nPrimary == K_ESCAPE && key_pressed)
	{
		QuickMenu_Close();
	}
	else if(nPrimary >= '0' && nPrimary <= '9' && key_pressed)
	{
		QuickMenu_Page_ActiveEntry(stof(chr2str(nPrimary)));
	}
	else if (hudShiftState_prev == hudShiftState && mouseClicked_prev == mouseClicked)
	{
		// allow console bind to work
		string con_keys = findkeysforcommand("toggleconsole", 0);
		int keys = tokenize(con_keys); // findkeysforcommand returns data for this
		for (int i = 0; i < keys; ++i)
		{
			if(nPrimary == stof(argv(i)))
				return false; // hit console bind
		}
		if (key_pressed)
			QuickMenu_Close();
		return false;
	}

	return true;
}

int entry_num_prev = 0;
void QuickMenu_Mouse()
{
	if(mv_active) return;

	if(!mouseClicked)
	if(prevMouseClicked & S_MOUSE2)
	{
		QuickMenu_Close();
		return;
	}

	panel = HUD_PANEL(QUICKMENU);
	HUD_Panel_LoadCvars();

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
		int entry_num = min(QuickMenu_Page_Entries - 1, floor((mousepos.y - first_entry_pos) / fontsize.y));
		if (entry_num != entry_num_prev)
		{
			QuickMenu_TimeOut_Set();
			entry_num_prev = entry_num;
		}
		if (QuickMenu_IsLastPage || entry_num != QUICKMENU_MAXLINES - 2)
		{
			if(!mouseClicked && (prevMouseClicked & S_MOUSE1))
				QuickMenu_Page_ActiveEntry((entry_num < QUICKMENU_MAXLINES - 1) ? entry_num + 1 : 0);

			if (time > QuickMenu_Page_ActivatedEntry_Time)
			{
				vector entry_pos = panel_pos;
				entry_pos.y = first_entry_pos + entry_num * fontsize.y;
				vector color;
				if (mouseClicked & S_MOUSE1)
					color = '0.5 1 0.5';
				else if (hudShiftState & S_CTRL)
					color = '1 1 0.3';
				else
					color = '1 1 1';
				drawfill(entry_pos, vec2(panel_size.x, fontsize.y), color, .2, DRAWFLAG_NORMAL);
			}
		}
	}
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
		drawpic(pos + vec2(desc_width, (fontsize.y - option_size.y) / 2), pic, option_size, '1 1 1', panel_fg_alpha, DRAWFLAG_ADDITIVE);
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

void HUD_QuickMenu()
{
	if(!autocvar__hud_configure)
	{
		if (!hud_draw_maximized || !QuickMenu_IsOpened())
			return;

		if (HUD_QuickMenu_Forbidden())
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

	HUD_Panel_LoadCvars();

	HUD_Scale_Disable();
	HUD_Panel_DrawBg();

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
			if (substring(QuickMenu_Page_Command[i], 0, 1) == "\n")
				color = "^6"; // special command
			else
				color = "^3";
			if(QuickMenu_Page_Command_Type[i] == QM_PCT_TOGGLE) // toggle command
			{
				int end = strstrofs(QuickMenu_Page_Command[i], ";", 0);
				if(end < 0)
					tokenize_console(QuickMenu_Page_Command[i]);
				else
					tokenize_console(substring(QuickMenu_Page_Command[i], 0, end));

				if(argv(1) && argv(0) == "toggle")
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

		if (time < QuickMenu_Page_ActivatedEntry_Time && QuickMenu_Page_ActivatedEntry == i)
			drawfill(panel_pos, vec2(panel_size.x, fontsize.y), '0.5 1 0.5', .2, DRAWFLAG_NORMAL);

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
	if(prvm_language == "en") { \
		tc_title = title; \
		tc_cmd = sprintf(command, text); \
	} \
	else if(!autocvar_hud_panel_quickmenu_translatecommands || translated_text == text) { \
		tc_title = strcat("(en)", title); \
		tc_cmd = sprintf(command, text); \
	} \
	else { \
		tc_title = strcat("(", prvm_language, ")", title); \
		tc_cmd = sprintf(command, translated_text); \
	} \
	QUICKMENU_ENTRY(tc_title, tc_cmd) \
}

void HUD_Quickmenu_PlayerListEntries(string cmd, int teamplayers, bool without_me)
{
	TC(int, teamplayers); TC(bool, without_me);
	entity pl;
	if(teamplayers && !team_count)
		return;

	Scoreboard_UpdatePlayerTeams();
	for(pl = players.sort_next; pl; pl = pl.sort_next)
	{
		if(teamplayers == 1 && (pl.team != myteam || pl.team == NUM_SPECTATOR)) // only own team players
			continue;
		if(teamplayers == 2 && (pl.team == myteam || pl.team == NUM_SPECTATOR)) // only enemy team players
			continue;
		if(without_me && pl.sv_entnum == player_localnum)
			continue;
		QUICKMENU_ENTRY(strcat("^7", entcs_GetName(pl.sv_entnum)), sprintf(cmd, entcs_GetName(pl.sv_entnum)))
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

	string tc_title;
	string tc_cmd;

	QUICKMENU_SMENU(_("Chat"), "Chat")
		QUICKMENU_SMENU_PL(CTX(_("QMCMD^Send public message to")), "Send public message to", "commandmode say %s:^7", 0, 1)
		QUICKMENU_ENTRY_TC(CTX(_("QMCMD^nice one")), "say %s", ":-) / nice one", CTX(_("QMCMD^:-) / nice one")))
		QUICKMENU_ENTRY_TC(CTX(_("QMCMD^good game")), "say %s", "good game", CTX(_("QMCMD^good game")))
		QUICKMENU_ENTRY_TC(CTX(_("QMCMD^hi / good luck")), "say %s", "hi / good luck and have fun", CTX(_("QMCMD^hi / good luck and have fun")))
		if(prvm_language != "en")
		QUICKMENU_ENTRY(CTX(_("QMCMD^Send in English")), "toggle hud_panel_quickmenu_translatecommands 0 1; quickmenu; wait; quickmenu default Chat")
	QUICKMENU_SMENU(_("Chat"), "Chat")

	if(teamplay)
	{
	QUICKMENU_SMENU(CTX(_("QMCMD^Team chat")), "Team chat")
		QUICKMENU_ENTRY_TC(CTX(_("QMCMD^strength soon")), "say_team %s", "strength soon", CTX(_("QMCMD^strength soon")))
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
		QUICKMENU_ENTRY_TC(CTX(_("QMCMD^killed flagcarrier, icon")), "say_team %s; g_waypointsprite_team_here_p", "killed flagcarrier (l:%y^7)", CTX(_("QMCMD^killed flagcarrier (l:%y^7)")))
		QUICKMENU_ENTRY_TC(CTX(_("QMCMD^dropped flag, icon")), "say_team %s; g_waypointsprite_team_here_d", "dropped flag (l:%d^7)", CTX(_("QMCMD^dropped flag (l:%d^7)")))
		QUICKMENU_ENTRY_TC(CTX(_("QMCMD^drop weapon, icon")), "say_team %s; g_waypointsprite_team_here; wait; dropweapon", "dropped gun %w^7 (l:%l^7)", CTX(_("QMCMD^dropped weapon %w^7 (l:%l^7)")))
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
		QUICKMENU_ENTRY_TAG(CTX(_("QMCMD^Change spectator camera")), "dropweapon", QM_TAG_KCOMMAND)
		}

		if(spectatee_status == -1)
		{
		QUICKMENU_SMENU(CTX(_("QMCMD^Observer camera")), "Observer camera")
			QUICKMENU_ENTRY_TAG(CTX(_("QMCMD^Increase speed")), "weapnext", QM_TAG_KCOMMAND)
			QUICKMENU_ENTRY_TAG(CTX(_("QMCMD^Decrease speed")), "weapprev", QM_TAG_KCOMMAND)
			QUICKMENU_ENTRY(CTX(_("QMCMD^Wall collision")), "toggle cl_clippedspectating")
		QUICKMENU_SMENU(CTX(_("QMCMD^Observer camera")), "Observer camera")
		}

		QUICKMENU_ENTRY(CTX(_("QMCMD^Fullscreen")), "toggle vid_fullscreen; vid_restart")
	QUICKMENU_SMENU(CTX(_("QMCMD^Settings")), "Settings")

	QUICKMENU_SMENU(CTX(_("QMCMD^Call a vote")), "Call a vote")
		QUICKMENU_ENTRY(CTX(_("QMCMD^Restart the map")), "vcall restart")
		QUICKMENU_ENTRY(CTX(_("QMCMD^End match")), "vcall endmatch")
		if(STAT(TIMELIMIT) > 0)
		{
		QUICKMENU_ENTRY(CTX(_("QMCMD^Reduce match time")), "vcall reducematchtime")
		QUICKMENU_ENTRY(CTX(_("QMCMD^Extend match time")), "vcall extendmatchtime")
		}
		if(teamplay)
		QUICKMENU_ENTRY(CTX(_("QMCMD^Shuffle teams")), "vcall shuffleteams")
	QUICKMENU_SMENU(CTX(_("QMCMD^Call a vote")), "Call a vote")

	if (autocvar__hud_panel_quickmenu_file_from_server != "")
	{
	string entry_name = _("Server quick menu");
	if (autocvar__hud_panel_quickmenu_file_from_server == "wpeditor.txt")
		entry_name = _("Waypoint editor menu");
	QUICKMENU_ENTRY_SPECIAL(entry_name, "quickmenu; wait; quickmenu \"\" \"\" $_hud_panel_quickmenu_file_from_server")
	if (autocvar__hud_panel_quickmenu_file_from_server == "wpeditor.txt")
		entry_name = _("Waypoint editor menu as default");
	else
		entry_name = _("Server quick menu as default");
	QUICKMENU_ENTRY(entry_name, "toggle hud_panel_quickmenu_server_is_default")
	}

	if(spectatee_status != 0)
	{
	QUICKMENU_SMENU_PL(CTX(_("QMCMD^Spectate a player")), "Spectate a player", "spectate \"%s^7\"", 0, 1)
	}

	if(target_submenu != "" && !target_submenu_found)
	{
		LOG_INFOF("Couldn't find submenu \"%s\"", target_submenu);
		if(prvm_language != "en")
			LOG_INFO("^3Warning: submenu title must be in English");
		QuickMenu_Buffer_Size = 0;
	}
}
#undef QUICKMENU_SMENU
#undef QUICKMENU_ENTRY
#undef QUICKMENU_ENTRY_TC
