#include "keybinder.qh"

#include <common/weapons/_all.qh>
.int flags;

#include "button.qh"
#include "dialog_settings_input_userbind.qh"

const string KEY_NOT_BOUND_CMD = "// not bound";

const int MAX_KEYS_PER_FUNCTION = 2;
const int MAX_KEYBINDS = 256;
int KeyBinds_Count = -1;
string KeyBinds_Functions[MAX_KEYBINDS];
// If the first character of the func is `*` it's a special keybind
// If the first character of the func is `;` it's an overrider keybind
string KeyBinds_Descriptions[MAX_KEYBINDS];
// If the first character of the descr is `$` it's a user bind
string KeyBinds_Icons[MAX_KEYBINDS]; // Allow all keybinds to have an icon, although currently only weapons do
// The first character of the icon string is either ` ` for no tree-icon, `+` for a branch, `T` for the first branch, `L` for an elbow
// Remove this character before drawing the icon

#define KEYBIND_IS_USERBIND(descr) (substring(descr, 0, 1) == "$")
// Special keybinds can't be edited or selected
// If a special keybind description matches the previous one
// then it's considered as an alternative keybind of the previous one
#define KEYBIND_IS_SPECIAL(func) (substring(func, 0 ,1) == "*")
// Overriding keybinds unset other binds when they're set
// ... for the purposes of the menu, or for other reasons
// The other binds that need to be unset are concatenated to func with a ";" separator
#define KEYBIND_IS_OVERRIDER(func) (substring(func, 0 ,1) == ";")

string XonoticKeyBinder_cb_name, XonoticKeyBinder_cb_icon;
void XonoticKeyBinder_cb(string _name, string _icon)
{
	XonoticKeyBinder_cb_name = _name;
	XonoticKeyBinder_cb_icon = _icon;
}

void KeyBinds_BuildList()
{
	KeyBinds_Count = 0;

	#define KEYBIND_DEF_WITH_ICON(func, desc, icon) MACRO_BEGIN \
		if (KeyBinds_Count < MAX_KEYBINDS) \
		{ \
			KeyBinds_Functions[KeyBinds_Count] = strzone(func); \
			KeyBinds_Descriptions[KeyBinds_Count] = strzone(desc); \
			KeyBinds_Icons[KeyBinds_Count] = strzone(icon); \
			++KeyBinds_Count; \
		} \
	MACRO_END
	#define KEYBIND_DEF(func, desc) KEYBIND_DEF_WITH_ICON(func, desc, "")
	#define KEYBIND_DEF_SPECIAL_WITH_ICON(func, desc, icon) KEYBIND_DEF_WITH_ICON(strcat("*", func), desc, icon)
	#define KEYBIND_DEF_OVERRIDER_WITH_ICON(func, desc, icon) KEYBIND_DEF_WITH_ICON(strcat(";", func), desc, icon)

	#define KEYBIND_EMPTY_LINE() KEYBIND_DEF("", "")
	#define KEYBIND_HEADER(str) KEYBIND_DEF("", str)


	KEYBIND_HEADER(_("Moving"));
	KEYBIND_DEF("+forward"                              , _("move forwards"));
	KEYBIND_DEF("+back"                                 , _("move backwards"));
	KEYBIND_DEF("+moveleft"                             , _("strafe left"));
	KEYBIND_DEF("+moveright"                            , _("strafe right"));
	KEYBIND_DEF("+jump"                                 , _("jump / swim"));
	KEYBIND_DEF("+crouch"                               , _("crouch / sink"));
	KEYBIND_DEF("+hook"                                 , _("offhand hook"));
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

	#define SHOWABLE_WEAPON(w) \
		(!(it.spawnflags & WEP_FLAG_SPECIALATTACK) && \
		!((it.spawnflags & WEP_FLAG_MUTATORBLOCKED) && (it.spawnflags & WEP_FLAG_HIDDEN)) )
	// no special attacks, and no hidden mutator-blocked weapons

	for (int imp = 1; imp <= 9; ++imp)
	{
		string w_override_list = "";
		int w_count = 0;

		FOREACH(Weapons, it != WEP_Null, {
			if (it.impulse != imp || !SHOWABLE_WEAPON(it))
				continue;
			it.display(it, XonoticKeyBinder_cb);
			w_override_list = strcat(w_override_list, ";weapon_", it.netname);
			++w_count;
		});
		if (w_count)
		{
			if (w_count == 1) // group only has 1 weapon (like Blaster's group), use the group bind, and add the icon
			{                // no overrides needed
				KEYBIND_DEF_WITH_ICON(strcat("weapon_group_", itos(imp)), XonoticKeyBinder_cb_name, strcat(" ", XonoticKeyBinder_cb_icon));
			}
			else // group has multiple weapons, allow binding them separately or together
			{    // setting the group bind overrides the individual binds, and vice versa
				string w_group = strcat(";weapon_group_", itos(imp));
				KEYBIND_DEF(strcat(w_group, w_override_list), sprintf(_("weapon group %d"), imp));

				int w_counter = 0;
				FOREACH(Weapons, it != WEP_Null, {
					if (it.impulse != imp || !SHOWABLE_WEAPON(it))
						continue;
					it.display(it, XonoticKeyBinder_cb);
					++w_counter;
					KEYBIND_DEF_WITH_ICON(strcat(";weapon_", it.netname, w_group), XonoticKeyBinder_cb_name,
						strcat((w_counter == 1 ? "T" : w_counter == w_count ? "L" : "+"), XonoticKeyBinder_cb_icon));
				});
			}
		}
		if (imp == 0)
			break;
		if (imp == 9)
			imp = -1;
	}
	#undef SHOWABLE_WEAPON

	KEYBIND_EMPTY_LINE();

	KEYBIND_HEADER(_("View"));
	KEYBIND_DEF("+zoom"                                 , _("hold zoom"));
	KEYBIND_DEF("togglezoom"                            , _("toggle zoom"));
	KEYBIND_DEF("+showscores"                           , _("show scores"));
	KEYBIND_DEF("screenshot"                            , _("screenshot"));
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
		KEYBIND_DEF_SPECIAL_WITH_ICON(console_shortcut  , _("enter console"), "");
	KEYBIND_DEF("menu_showquitdialog"                   , _("quit"));
	KEYBIND_EMPTY_LINE();

	KEYBIND_HEADER(_("Teamplay"));
	KEYBIND_DEF("team_auto"                             , _("auto-join team"));
	KEYBIND_DEF("team_selection_show"                   , _("team selection"));
	KEYBIND_DEF("spec"                                  , _("spectate"));
	KEYBIND_EMPTY_LINE();

	KEYBIND_HEADER(_("Misc"));
	KEYBIND_DEF("+use"                                  , _("drop key/flag, exit vehicle"));
	KEYBIND_DEF("kill"                                  , _("suicide / respawn"));
	KEYBIND_DEF("quickmenu"                             , _("quick menu"));
	string scoreboard_ui_shortcut = strcat(translate_key("TAB"), "+", translate_key("ESCAPE"));
	KEYBIND_DEF_SPECIAL_WITH_ICON(scoreboard_ui_shortcut, _("scoreboard user interface"), "");
	KEYBIND_EMPTY_LINE();

	KEYBIND_HEADER(_("User defined"));

	for (int i = 1; i <= 32; ++i)
		KEYBIND_DEF(strcat("+userbind ", itos(i)), strcat("$userbind", itos(i)));

	KEYBIND_EMPTY_LINE();

	KEYBIND_HEADER(_("Development"));
	KEYBIND_DEF("menu_showsandboxtools"                 , _("sandbox menu"));
	KEYBIND_DEF("+button8"                              , _("drag object (sandbox)"));
	KEYBIND_DEF("wpeditor_menu"                         , _("waypoint editor menu"));

	#undef KEYBIND_DEF_WITH_ICON
	#undef KEYBIND_DEF
	#undef KEYBIND_EMPTY_LINE
	#undef KEYBIND_HEADER
	#undef KEYBIND_DEF_SPECIAL_WITH_ICON
	#undef KEYBIND_DEF_OVERRIDER_WITH_ICON
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
	for (j = 0; j < n; ++j)
	{
		k = stof(argv(j));
		if (k != -1)
			localcmd("\nbind \"", keynumtostring(k), "\" \"", to, "\"\n");
	}
	if (n)
		cvar_set("_hud_showbinds_reload", "1");
}
void XonoticKeyBinder_configureXonoticKeyBinder(entity me)
{
	me.configureXonoticListBox(me);
	me.nItems = 0;
}
void XonoticKeyBinder_loadKeyBinds(entity me)
{
	bool force_initial_selection = false;
	if (KeyBinds_Count < 0) // me.handle not loaded yet?
		force_initial_selection = true;
	KeyBinds_BuildList();
	me.nItems = KeyBinds_Count;
	if (force_initial_selection)
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

	me.itemAbsSize.y = absSize.y * me.itemHeight;
	me.itemAbsSize.x = absSize.x * (1 - me.controlWidth);
	me.realFontSize.y = me.fontSize / me.itemAbsSize.y;
	me.realFontSize.x = me.fontSize / me.itemAbsSize.x;
	me.realUpperMargin = 0.5 * (1 - me.realFontSize.y);

	entity e = REGISTRY_GET(Weapons, WEP_FIRST);
	e.display(e, XonoticKeyBinder_cb);
	vector sz = draw_PictureSize(XonoticKeyBinder_cb_icon);
	float aspect_ratio = sz.y ? sz.x / sz.y : 1;
	me.columnIconSize = me.itemAbsSize.y / me.itemAbsSize.x * aspect_ratio;

	me.columnTreeIconSize = me.itemAbsSize.y / me.itemAbsSize.x; // 1:1 aspect ratio
	me.columnKeysSize = me.realFontSize.x * 12;
	me.columnFunctionSize = 1 - me.columnKeysSize - 2 * me.realFontSize.x;
	// columnFunctionSize will need to be shortened if an icon is drawn
	me.columnKeysOrigin = me.columnFunctionSize + me.realFontSize.x;
}
void KeyBinder_Bind_Change(entity btn, entity me)
{
	string func = KeyBinds_Functions[me.selectedItem];
	if (func == "" || KEYBIND_IS_SPECIAL(func))
		return;

	me.setSelected(me, me.selectedItem); // make it visible if it's hidden
	me.keyGrabButton.forcePressed = true;
	me.clearButton.disabled = 1;
	keyGrabber = me;
}
void KeyBinder_Bind_UnbindAllForFunction(int n)
{
	// usage: call tokenize beforehand, then pass in the output

	float k;
	for (int j = 0; j < n; ++j)
	{
		k = stof(argv(j));
		if (k != -1)
		{
			// bind to empty cmd instead of using unbind so it gets saved in config and overrides any default binds
			localcmd("\nbind \"", keynumtostring(k), "\" \"", KEY_NOT_BOUND_CMD, "\"\n");
		}
	}
}
void XonoticKeyBinder_keyGrabbed(entity me, int key, bool ascii)
{
	int n, j, k, nvalid;

	me.keyGrabButton.forcePressed = false;
	me.clearButton.disabled = 0;

	if (key == K_ESCAPE)
		return;

	// forbid these keys from being bound in the menu
	if (key == K_CAPSLOCK || key == K_NUMLOCK)
	{
		KeyBinder_Bind_Change(me, me);
		return;
	}

	string func = KeyBinds_Functions[me.selectedItem];
	if (func == "" || KEYBIND_IS_SPECIAL(func))
		return;
	else if (KEYBIND_IS_OVERRIDER(func))
	{
		n = tokenizebyseparator(func, ";");
		if (n <= 1)
			return;
		func = argv(1);

		// unset all binds for the functions this key overrides
		for (j = 2; j < n; ++j)
		{
			n = tokenize(findkeysforcommand(argv(j), 0)); // uses '...' strings
			KeyBinder_Bind_UnbindAllForFunction(n);
			n = tokenizebyseparator(func, ";"); // reset argv back to the overridden functions
		}
	}

	n = tokenize(findkeysforcommand(func, 0)); // uses '...' strings
	nvalid = 0;
	for (j = 0; j < n; ++j)
	{
		k = stof(argv(j));
		if (k != -1)
			++nvalid;
	}
	if (nvalid >= MAX_KEYS_PER_FUNCTION)
		KeyBinder_Bind_UnbindAllForFunction(n);
	m_play_click_sound(MENU_SOUND_SELECT);
	localcmd("\nbind \"", keynumtostring(key), "\" \"", func, "\"\n");
	localcmd("-zoom\n"); // to make sure we aren't in togglezoom'd state
	cvar_set("_hud_showbinds_reload", "1");
}
void XonoticKeyBinder_destroy(entity me)
{
	if (KeyBinds_Count < 0)
		return;

	for (int i = 0; i < MAX_KEYBINDS; ++i)
	{
		strfree(KeyBinds_Functions[i]);
		strfree(KeyBinds_Descriptions[i]);
		strfree(KeyBinds_Icons[i]);
	}
	KeyBinds_Count = 0;
}
void XonoticKeyBinder_editUserbind(entity me, string theName, string theCommandPress, string theCommandRelease)
{
	if (!me.userbindEditDialog)
		return;

	string func = KeyBinds_Functions[me.selectedItem];
	if (func == "" || KEYBIND_IS_SPECIAL(func))
		return;

	string descr = KeyBinds_Descriptions[me.selectedItem];
	if (!KEYBIND_IS_USERBIND(descr))
		return;
	descr = substring(descr, 1, strlen(descr) - 1);

	// Hooray! It IS a user bind!
	cvar_set(strcat(descr, "_description"), theName);
	cvar_set(strcat(descr, "_press"), theCommandPress);
	cvar_set(strcat(descr, "_release"), theCommandRelease);
}
void KeyBinder_Bind_Edit(entity btn, entity me)
{
	if (!me.userbindEditDialog)
		return;

	string func = KeyBinds_Functions[me.selectedItem];
	if (func == "" || KEYBIND_IS_SPECIAL(func))
		return;

	string descr = KeyBinds_Descriptions[me.selectedItem];
	if (!KEYBIND_IS_USERBIND(descr))
		return;

	me.setSelected(me, me.selectedItem); // make it visible if it's hidden
	descr = substring(descr, 1, strlen(descr) - 1);

	// Hooray! It IS a user bind!
	me.userbindEditDialog.loadUserBind(me.userbindEditDialog, cvar_string(strcat(descr, "_description")), cvar_string(strcat(descr, "_press")), cvar_string(strcat(descr, "_release")));

	DialogOpenButton_Click(btn, me.userbindEditDialog);
}
void KeyBinder_Bind_Clear(entity btn, entity me)
{
	int n;

	string func = KeyBinds_Functions[me.selectedItem];
	if (func == "" || KEYBIND_IS_SPECIAL(func))
		return;
	else if (KEYBIND_IS_OVERRIDER(func))
	{
		n = tokenizebyseparator(func, ";");
		if (n <= 1)
			return;
		func = argv(1);
	}

	me.setSelected(me, me.selectedItem); // make it visible if it's hidden

	n = tokenize(findkeysforcommand(func, 0)); // uses '...' strings
	KeyBinder_Bind_UnbindAllForFunction(n);

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
	i = bound(0, i, me.nItems - 1);
#define KEYBIND_IS_UNSELECTABLE(idx) \
	(KeyBinds_Functions[idx] == "" || KEYBIND_IS_SPECIAL(KeyBinds_Functions[idx]))

	// skip over unselectables if selected via keyboard, otherwise ignore mouse input
	if (!me.pressed)
	{
		if (i < me.previouslySelected)
		{
			while ((i > 0) && KEYBIND_IS_UNSELECTABLE(i))
				--i;
		}
		else
		{
			while ((i < me.nItems - 1) && KEYBIND_IS_UNSELECTABLE(i))
				++i;
		}
	}
	if (KEYBIND_IS_UNSELECTABLE(i))
		i = me.previouslySelected;
	else
		me.previouslySelected = i;

	if (me.userbindEditButton)
		me.userbindEditButton.disabled = !KEYBIND_IS_USERBIND(KeyBinds_Descriptions[i]);
	SUPER(XonoticKeyBinder).setSelected(me, i);
#undef KEYBIND_IS_UNSELECTABLE
}
float XonoticKeyBinder_keyDown(entity me, int key, bool ascii, float shift)
{
	float r = 1;
	switch (key)
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
	float descrWidth;

	string descr = KeyBinds_Descriptions[i];
	string func = KeyBinds_Functions[i];
	string icon = KeyBinds_Icons[i];

	if (func == "")
	{
		theColor = SKINCOLOR_KEYGRABBER_TITLES;
		theAlpha = SKINALPHA_KEYGRABBER_TITLES;
		extraMargin = 0;
	}
	else
	{
		if (isSelected)
		{
			if (keyGrabber == me)
				draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_WAITING, SKINALPHA_LISTBOX_WAITING);
			else
				draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED);
		}
		else if (isFocused)
		{
			me.focusedItemAlpha = getFadedAlpha(me.focusedItemAlpha, SKINALPHA_LISTBOX_FOCUSED, SKINFADEALPHA_LISTBOX_FOCUSED);
			draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_FOCUSED, me.focusedItemAlpha);
		}

		theAlpha = SKINALPHA_KEYGRABBER_KEYS;
		theColor = SKINCOLOR_KEYGRABBER_KEYS;
		extraMargin = me.realFontSize.x * 0.5;
	}
	descrWidth = me.columnFunctionSize;

	if (KEYBIND_IS_USERBIND(descr))
	{
		string s = substring(descr, 1, strlen(descr) - 1);
		descr = cvar_string(strcat(s, "_description"));
		if (descr == "")
			descr = s;
		if (cvar_string(strcat(s, "_press")) == "")
			if (cvar_string(strcat(s, "_release")) == "")
				theAlpha *= SKINALPHA_DISABLED;
	}

	if (icon != "")
	{
		string tree_type = substring(icon, 0, 1);
		if (tree_type == "+" || tree_type == "T" || tree_type == "L")
		{
			string pic = (tree_type == "+" ? "tree_branch" : tree_type == "T" ? "tree_branch_start" : "tree_elbow");
			draw_Picture(extraMargin * eX, pic, me.columnTreeIconSize * eX + eY, '1 1 1', SKINALPHA_LISTBOX_SELECTED);
			float addedMargin = me.columnTreeIconSize + 0.25 * me.realFontSize.x;
			extraMargin += addedMargin;
			descrWidth  -= addedMargin;
		}
		if (strlen(icon) > 1) // not just the tree icon
		{
			draw_Picture(extraMargin * eX, substring(icon, 1, strlen(icon) - 1), me.columnIconSize * eX + eY, '1 1 1', SKINALPHA_LISTBOX_SELECTED);
			float addedMargin = me.columnIconSize + 0.25 * me.realFontSize.x;
			extraMargin += addedMargin;
			descrWidth  -= addedMargin;
		}
	}

	string s = draw_TextShortenToWidth(descr, descrWidth, 0, me.realFontSize);
	draw_Text(me.realUpperMargin * eY + extraMargin * eX, s, me.realFontSize, theColor, theAlpha, 0);

	if (func == "")
		return;

	int n;
	s = "";
	if (KEYBIND_IS_OVERRIDER(func))
	{
		n = tokenizebyseparator(func, ";");
		if (n <= 1)
			return;
		func = argv(1);
	}
	if (KEYBIND_IS_SPECIAL(func))
	{
		s = substring(func, 1, -1);
		theColor = SKINCOLOR_KEYGRABBER_KEYS_IMMUTABLE;
		theAlpha = SKINALPHA_KEYGRABBER_KEYS_IMMUTABLE;
	}
	else
	{
		string key;
		float k;
		const bool joy_active = cvar("joy_active");
		n = tokenize(findkeysforcommand(func, 0)); // uses '...' strings
		for (int j = 0; j < n; ++j)
		{
			k = stof(argv(j));
			if (k == -1)
				continue;
			key = keynumtostring(k);
			if (!joy_active && startsWith(key, "JOY"))
				continue;

			s = cons_mid(s, ", ", translate_key(key));
		}
	}
	s = draw_TextShortenToWidth(s, me.columnKeysSize, 0, me.realFontSize);
	draw_CenterText(me.realUpperMargin * eY + (me.columnKeysOrigin + 0.5 * me.columnKeysSize) * eX, s, me.realFontSize, theColor, theAlpha, 0);
}

#undef KEYBIND_IS_USERBIND
#undef KEYBIND_IS_SPECIAL
#undef KEYBIND_IS_OVERRIDER
