#include "keybinder.qh"

#include <common/weapons/_all.qh>
.int flags;

#include "button.qh"
#include "dialog_settings_input_userbind.qh"

const string KEY_NOT_BOUND_CMD = "// not bound";

const int MAX_KEYS_PER_FUNCTION = 2;
const int MAX_KEYBINDS = 256;
string KeyBinds_Functions[MAX_KEYBINDS];
string KeyBinds_Descriptions[MAX_KEYBINDS];
int KeyBinds_Count = -1;

void KeyBinds_BuildList()
{
	KeyBinds_Count = 0;

	#define KEYBIND_DEF(func, desc) MACRO_BEGIN \
		if((KeyBinds_Count < MAX_KEYBINDS)) { \
			KeyBinds_Functions[KeyBinds_Count] = strzone(func); \
			KeyBinds_Descriptions[KeyBinds_Count] = strzone(desc); \
			++KeyBinds_Count; \
		} \
	MACRO_END

	#define KEYBIND_EMPTY_LINE() KEYBIND_DEF("", "")
	#define KEYBIND_HEADER(str) KEYBIND_DEF("", str)

	#define KEYBIND_IS_SPECIAL(func) (substring(func, 0 ,1) == "*")
	#define KEYBIND_SPECIAL_DEF(key, desc) KEYBIND_DEF(strcat("*", key), desc)

	KEYBIND_HEADER(_("Moving"));
	KEYBIND_DEF("+forward"                              , _("forward"));
	KEYBIND_DEF("+back"                                 , _("backpedal"));
	KEYBIND_DEF("+moveleft"                             , _("strafe left"));
	KEYBIND_DEF("+moveright"                            , _("strafe right"));
	KEYBIND_DEF("+jump"                                 , _("jump / swim"));
	KEYBIND_DEF("+crouch"                               , _("crouch / sink"));
	KEYBIND_DEF("+hook"                                 , _("off-hand hook"));
	KEYBIND_DEF("+jetpack"                              , _("jetpack"));
	KEYBIND_EMPTY_LINE();

	KEYBIND_HEADER(_("Attacking"));
	KEYBIND_DEF("+fire"                                 , _("primary fire"));
	KEYBIND_DEF("+fire2"                                , _("secondary fire"));
	KEYBIND_EMPTY_LINE();

	KEYBIND_HEADER(_("Weapons"));
	KEYBIND_DEF("weapprev"                              , CTX(_("WEAPON^previous")));
	KEYBIND_DEF("weapnext"                              , CTX(_("WEAPON^next")));
	KEYBIND_DEF("weaplast"                              , CTX(_("WEAPON^previously used")));
	KEYBIND_DEF("weapbest"                              , CTX(_("WEAPON^best")));
	KEYBIND_DEF("reload"                                , _("reload"));
	KEYBIND_DEF("dropweapon"                            , _("drop weapon / throw nade"));

	#define ADD_TO_W_LIST(pred) \
		FOREACH(Weapons, it != WEP_Null, { \
			if (it.impulse != imp) continue; \
			if (!(pred)) continue; \
			w_list = strcat(w_list, it.m_name, " / "); \
		})

	for(int imp = 1; imp <= 9; ++imp)
	{
		string w_list = "";
		ADD_TO_W_LIST(!(it.spawnflags & (WEP_FLAG_MUTATORBLOCKED | WEP_FLAG_HIDDEN | WEP_FLAG_SPECIALATTACK | WEP_FLAG_SUPERWEAPON)));
		ADD_TO_W_LIST((it.spawnflags & WEP_FLAG_SUPERWEAPON) && !(it.spawnflags & WEP_FLAG_HIDDEN));
		ADD_TO_W_LIST((it.spawnflags & WEP_FLAG_MUTATORBLOCKED) && !(it.spawnflags & (WEP_FLAG_HIDDEN | WEP_FLAG_SPECIALATTACK)));
		if(w_list)
			KEYBIND_DEF(strcat("weapon_group_", itos(imp)), substring(w_list, 0, -4));
		if(imp == 0)
			break;
		if(imp == 9)
			imp = -1;
	}
	#undef ADD_TO_W_LIST

	KEYBIND_EMPTY_LINE();

	KEYBIND_HEADER(_("View"));
	KEYBIND_DEF("+zoom"                                 , _("hold zoom"));
	KEYBIND_DEF("togglezoom"                            , _("toggle zoom"));
	KEYBIND_DEF("+showscores"                           , _("show scores"));
	KEYBIND_DEF("screenshot"                            , _("screen shot"));
	KEYBIND_DEF("+hud_panel_radar_maximized"            , _("maximize radar"));
	KEYBIND_DEF("toggle chase_active"                   , _("3rd person view"));
	KEYBIND_DEF("spec"                                  , _("enter spectator mode"));
	KEYBIND_EMPTY_LINE();

	KEYBIND_HEADER(_("Communication"));
	KEYBIND_DEF("messagemode"                           , _("public chat"));
	KEYBIND_DEF("messagemode2"                          , _("team chat"));
	KEYBIND_DEF("+con_chat_maximize"                    , _("show chat history"));
	KEYBIND_DEF("vyes"                                  , _("vote YES"));
	KEYBIND_DEF("vno"                                   , _("vote NO"));
	KEYBIND_DEF("ready"                                 , _("ready"));
	KEYBIND_EMPTY_LINE();

	KEYBIND_HEADER(_("Client"));
	KEYBIND_DEF("+show_info"                            , _("server info"));
	// display the hardcoded shortcut to open the console as it works for all
	// non-English keyboard layouts, unlike default keys (` and ~)
	KEYBIND_DEF("toggleconsole"                         , _("enter console"));
		string console_shortcut = strcat(translate_key("SHIFT"), "+", translate_key("ESCAPE"));
		KEYBIND_SPECIAL_DEF(console_shortcut, _("enter console"));
	KEYBIND_DEF("menu_showquitdialog"                   , _("quit"));
	KEYBIND_EMPTY_LINE();

	KEYBIND_HEADER(_("Teamplay"));
	KEYBIND_DEF("team_auto"                             , _("auto-join team"));
	KEYBIND_DEF("menu_showteamselect"                   , _("team menu"));
	KEYBIND_DEF("spec"                                  , _("spectate"));
	KEYBIND_EMPTY_LINE();

	KEYBIND_HEADER(_("Misc"));
	KEYBIND_DEF("+use"                                  , _("drop key/flag, exit vehicle"));
	KEYBIND_DEF("kill"                                  , _("suicide / respawn"));
	KEYBIND_DEF("quickmenu"                             , _("quick menu"));
	KEYBIND_EMPTY_LINE();

	KEYBIND_HEADER(_("User defined"));

	for(int i = 1; i <= 32; ++i)
		KEYBIND_DEF(strcat("+userbind ", itos(i)), strcat("$userbind", itos(i)));

	KEYBIND_EMPTY_LINE();

	KEYBIND_HEADER(_("Development"));
	KEYBIND_DEF("menu_showsandboxtools"                 , _("sandbox menu"));
	KEYBIND_DEF("+button8"                              , _("drag object (sandbox)"));
	KEYBIND_DEF("wpeditor_menu"                         , _("waypoint editor menu"));

	#undef KEYBIND_DEF
}

entity makeXonoticKeyBinder()
{
	entity me;
	me = NEW(XonoticKeyBinder);
	me.configureXonoticKeyBinder(me);
	return me;
}
void replace_bind(string from, string to)
{
	int n, j;
	float k; // not sure if float or int
	n = tokenize(findkeysforcommand(from, 0)); // uses '...' strings
	for(j = 0; j < n; ++j)
	{
		k = stof(argv(j));
		if(k != -1)
			localcmd("\nbind \"", keynumtostring(k), "\" \"", to, "\"\n");
	}
	if(n)
		cvar_set("_hud_showbinds_reload", "1");
}
void XonoticKeyBinder_configureXonoticKeyBinder(entity me)
{
	me.configureXonoticListBox(me);
	me.nItems = 0;

	// TEMP: Xonotic 0.1 to later
	replace_bind("impulse 1", "weapon_group_1");
	replace_bind("impulse 2", "weapon_group_2");
	replace_bind("impulse 3", "weapon_group_3");
	replace_bind("impulse 4", "weapon_group_4");
	replace_bind("impulse 5", "weapon_group_5");
	replace_bind("impulse 6", "weapon_group_6");
	replace_bind("impulse 7", "weapon_group_7");
	replace_bind("impulse 8", "weapon_group_8");
	replace_bind("impulse 9", "weapon_group_9");
	replace_bind("impulse 14", "weapon_group_0");
}
void XonoticKeyBinder_loadKeyBinds(entity me)
{
	bool force_initial_selection = false;
	if(KeyBinds_Count < 0) // me.handle not loaded yet?
		force_initial_selection = true;
	KeyBinds_BuildList();
	me.nItems = KeyBinds_Count;
	if(force_initial_selection)
		me.setSelected(me, 0);
}
void XonoticKeyBinder_showNotify(entity me)
{
	me.destroy(me);
	me.loadKeyBinds(me);
}
void XonoticKeyBinder_resizeNotify(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
{
	SUPER(XonoticKeyBinder).resizeNotify(me, relOrigin, relSize, absOrigin, absSize);

	me.realFontSize_y = me.fontSize / (absSize.y * me.itemHeight);
	me.realFontSize_x = me.fontSize / (absSize.x * (1 - me.controlWidth));
	me.realUpperMargin = 0.5 * (1 - me.realFontSize.y);

	me.columnFunctionOrigin = 0;
	me.columnKeysSize = me.realFontSize.x * 12;
	me.columnFunctionSize = 1 - me.columnKeysSize - 2 * me.realFontSize.x;
	me.columnKeysOrigin = me.columnFunctionOrigin + me.columnFunctionSize + me.realFontSize.x;
}
void KeyBinder_Bind_Change(entity btn, entity me)
{
	string func = KeyBinds_Functions[me.selectedItem];
	if(func == "" || KEYBIND_IS_SPECIAL(func))
		return;

	me.keyGrabButton.forcePressed = 1;
	me.clearButton.disabled = 1;
	keyGrabber = me;
}
void XonoticKeyBinder_keyGrabbed(entity me, int key, bool ascii)
{
	int n, j, nvalid;
	float k;

	me.keyGrabButton.forcePressed = 0;
	me.clearButton.disabled = 0;

	if(key == K_ESCAPE)
		return;

	// forbid these keys from being bound in the menu
	if(key == K_CAPSLOCK || key == K_NUMLOCK)
	{
		KeyBinder_Bind_Change(me, me);
		return;
	}

	string func = KeyBinds_Functions[me.selectedItem];
	if(func == "" || KEYBIND_IS_SPECIAL(func))
		return;

	n = tokenize(findkeysforcommand(func, 0)); // uses '...' strings
	nvalid = 0;
	for(j = 0; j < n; ++j)
	{
		k = stof(argv(j));
		if(k != -1)
			++nvalid;
	}
	if(nvalid >= MAX_KEYS_PER_FUNCTION)
	{
		for(j = 0; j < n; ++j)
		{
			k = stof(argv(j));
			if(k != -1)
			{
				// bind to empty cmd instead of using unbind so it gets saved in config and overrides any default binds
				localcmd("\nbind \"", keynumtostring(k), "\" \"", KEY_NOT_BOUND_CMD, "\"\n");
			}
		}
	}
	m_play_click_sound(MENU_SOUND_SELECT);
	localcmd("\nbind \"", keynumtostring(key), "\" \"", func, "\"\n");
	localcmd("-zoom\n"); // to make sure we aren't in togglezoom'd state
	cvar_set("_hud_showbinds_reload", "1");
}
void XonoticKeyBinder_destroy(entity me)
{
	if(KeyBinds_Count < 0)
		return;

	for(int i = 0; i < MAX_KEYBINDS; ++i)
	{
		strfree(KeyBinds_Functions[i]);
		strfree(KeyBinds_Descriptions[i]);
	}
	KeyBinds_Count = 0;
}
void XonoticKeyBinder_editUserbind(entity me, string theName, string theCommandPress, string theCommandRelease)
{
	if(!me.userbindEditDialog)
		return;

	string func = KeyBinds_Functions[me.selectedItem];
	if(func == "" || KEYBIND_IS_SPECIAL(func))
		return;

	string descr = KeyBinds_Descriptions[me.selectedItem];
	if(substring(descr, 0, 1) != "$")
		return;
	descr = substring(descr, 1, strlen(descr) - 1);

	// Hooray! It IS a user bind!
	cvar_set(strcat(descr, "_description"), theName);
	cvar_set(strcat(descr, "_press"), theCommandPress);
	cvar_set(strcat(descr, "_release"), theCommandRelease);
}
void KeyBinder_Bind_Edit(entity btn, entity me)
{
	if(!me.userbindEditDialog)
		return;

	string func = KeyBinds_Functions[me.selectedItem];
	if(func == "" || KEYBIND_IS_SPECIAL(func))
		return;

	string descr = KeyBinds_Descriptions[me.selectedItem];
	if(substring(descr, 0, 1) != "$")
		return;
	descr = substring(descr, 1, strlen(descr) - 1);

	// Hooray! It IS a user bind!
	me.userbindEditDialog.loadUserBind(me.userbindEditDialog, cvar_string(strcat(descr, "_description")), cvar_string(strcat(descr, "_press")), cvar_string(strcat(descr, "_release")));

	DialogOpenButton_Click(btn, me.userbindEditDialog);
}
void KeyBinder_Bind_Clear(entity btn, entity me)
{
	float n, j, k;

	string func = KeyBinds_Functions[me.selectedItem];
	if(func == "" || KEYBIND_IS_SPECIAL(func))
		return;

	n = tokenize(findkeysforcommand(func, 0)); // uses '...' strings
	for(j = 0; j < n; ++j)
	{
		k = stof(argv(j));
		if(k != -1)
		{
			// bind to empty cmd instead of using unbind so it gets saved in config and overrides any default binds
			localcmd("\nbind \"", keynumtostring(k), "\" \"", KEY_NOT_BOUND_CMD, "\"\n");
		}
	}
	m_play_click_sound(MENU_SOUND_CLEAR);
	localcmd("-zoom\n"); // to make sure we aren't in togglezoom'd state
	cvar_set("_hud_showbinds_reload", "1");
}
void KeyBinder_Bind_Reset_All(entity btn, entity me)
{
	localcmd("unbindall\n");
	localcmd("exec binds-xonotic.cfg\n");
	localcmd("-zoom\n"); // to make sure we aren't in togglezoom'd state
	cvar_set("_hud_showbinds_reload", "1");
	me.close(me);
}
void XonoticKeyBinder_doubleClickListBoxItem(entity me, float i, vector where)
{
	KeyBinder_Bind_Change(NULL, me);
}
void XonoticKeyBinder_setSelected(entity me, int i)
{
	// handling of "unselectable" items
	i = floor(0.5 + bound(0, i, me.nItems - 1));
	if (KEYBIND_IS_SPECIAL(KeyBinds_Functions[i]))
	{
		SUPER(XonoticKeyBinder).setSelected(me, i - 1);
		return;
	}
	if(me.pressed == 0 || me.pressed == 1) // keyboard or scrolling - skip unselectable items
	{
		if(i > me.previouslySelected)
		{
			while((i < me.nItems - 1) && (KeyBinds_Functions[i] == ""))
				++i;
		}
		while((i > 0) && (KeyBinds_Functions[i] == ""))
			--i;
		while((i < me.nItems - 1) && (KeyBinds_Functions[i] == ""))
			++i;
	}
	if(me.pressed == 3) // released the mouse - fall back to last valid item
	{
		if(KeyBinds_Functions[i] == "")
			i = me.previouslySelected;
	}
	if(KeyBinds_Functions[i] != "")
		me.previouslySelected = i;
	if(me.userbindEditButton)
		me.userbindEditButton.disabled = (substring(KeyBinds_Descriptions[i], 0, 1) != "$");
	SUPER(XonoticKeyBinder).setSelected(me, i);
}
float XonoticKeyBinder_keyDown(entity me, int key, bool ascii, float shift)
{
	bool r = true;
	switch(key)
	{
		case K_ENTER:
		case K_KP_ENTER:
		case K_SPACE:
			KeyBinder_Bind_Change(me, me);
			break;
		case K_DEL:
		case K_KP_DEL:
		case K_BACKSPACE:
			KeyBinder_Bind_Clear(me, me);
			break;
		case K_MOUSE2:
			KeyBinder_Bind_Edit(me, me);
			break;
		default:
			r = SUPER(XonoticKeyBinder).keyDown(me, key, ascii, shift);
			break;
	}
	return r;
}

void XonoticKeyBinder_drawListBoxItem(entity me, int i, vector absSize, bool isSelected, bool isFocused)
{
	vector theColor;
	float theAlpha;
	float extraMargin;

	string descr = KeyBinds_Descriptions[i];
	string func = KeyBinds_Functions[i];

	if(func == "")
	{
		theColor = SKINCOLOR_KEYGRABBER_TITLES;
		theAlpha = SKINALPHA_KEYGRABBER_TITLES;
		extraMargin = 0;
	}
	else
	{
		if(isSelected)
		{
			if(keyGrabber == me)
				draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_WAITING, SKINALPHA_LISTBOX_WAITING);
			else
				draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED);
		}
		else if(isFocused)
		{
			me.focusedItemAlpha = getFadedAlpha(me.focusedItemAlpha, SKINALPHA_LISTBOX_FOCUSED, SKINFADEALPHA_LISTBOX_FOCUSED);
			draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_FOCUSED, me.focusedItemAlpha);
		}

		theAlpha = SKINALPHA_KEYGRABBER_KEYS;
		theColor = SKINCOLOR_KEYGRABBER_KEYS;
		extraMargin = me.realFontSize.x * 0.5;
	}

	if(substring(descr, 0, 1) == "$")
	{
		string s = substring(descr, 1, strlen(descr) - 1);
		descr = cvar_string(strcat(s, "_description"));
		if(descr == "")
			descr = s;
		if(cvar_string(strcat(s, "_press")) == "")
			if(cvar_string(strcat(s, "_release")) == "")
				theAlpha *= SKINALPHA_DISABLED;
	}

	string s = draw_TextShortenToWidth(descr, me.columnFunctionSize, 0, me.realFontSize);
	draw_Text(me.realUpperMargin * eY + extraMargin * eX, s, me.realFontSize, theColor, theAlpha, 0);

	if (func == "")
		return;

	s = "";
	if (KEYBIND_IS_SPECIAL(func))
		s = substring(func, 1, -1);
	else
	{
		bool joy_active = cvar("joy_active");
		int n = tokenize(findkeysforcommand(func, 0)); // uses '...' strings
		for(int j = 0; j < n; ++j)
		{
			float k = stof(argv(j));
			if(k != -1)
			{
				string key = keynumtostring(k);
				if (!joy_active && startsWith(key, "JOY"))
					continue;
				if(s != "")
					s = strcat(s, ", ");
				s = strcat(s, translate_key(key));
			}
		}
	}
	s = draw_TextShortenToWidth(s, me.columnKeysSize, 0, me.realFontSize);
	draw_CenterText(me.realUpperMargin * eY + (me.columnKeysOrigin + 0.5 * me.columnKeysSize) * eX, s, me.realFontSize, theColor, theAlpha, 0);
}
