#include "cvarlist.qh"

#include "inputbox.qh"
#include "../item/checkbox.qh"
#include "../item/container.qh"
#include "../item/checkbox.qh"

entity makeXonoticCvarList()
{
	entity me;
	me = NEW(XonoticCvarList);
	me.configureXonoticCvarList(me);
	return me;
}
void XonoticCvarList_configureXonoticCvarList(entity me)
{
	me.configureXonoticListBox(me);
	me.handle = buf_create();
	me.nItems = 0;
}
void CvarList_Load(entity me, string filter)
{
	if(me.handle < 0)
		return;

	buf_cvarlist(me.handle, filter, "_"); // cvars starting with "_" are excluded
	me.nItems = buf_getsize(me.handle);
	if(autocvar_menu_cvarlist_onlymodified)
	{
		float newbuf = buf_create();
		for (int i = 0; i < me.nItems; ++i)
		{
			string k = bufstr_get(me.handle, i);
			if(cvar_string(k) != cvar_defstring(k))
				bufstr_add(newbuf, k, false);
		}
		buf_del(me.handle);
		me.handle = newbuf;
		me.nItems = buf_getsize(me.handle);
	}
}
void XonoticCvarList_showNotify(entity me)
{
	bool force_initial_selection = false;
	if(me.handle >= 0 && me.nItems <= 0) // me.handle not loaded yet?
		force_initial_selection = true;
	CvarList_Load(me, me.controlledTextbox.text);
	if(force_initial_selection)
		me.setSelected(me, 0);
}
void XonoticCvarList_hideNotify(entity me)
{
	if(me.handle)
		buf_del(me.handle);
	me.handle = buf_create();
	me.nItems = 0;
}
void XonoticCvarList_destroy(entity me)
{
	if(me.handle)
		buf_del(me.handle);
}
string autocvar_menu_forced_saved_cvars;
string autocvar_menu_reverted_nonsaved_cvars;
bool XonoticCvarList_updateCvarType(entity me)
{
	float t;
	t = cvar_type(me.cvarName);
	me.cvarType = "";
	bool needsForcing;
	if(strhasword(autocvar_menu_forced_saved_cvars, me.cvarName))
	{
		me.cvarType = strcat(me.cvarType, ", ", _("forced to be saved to config.cfg"));
		needsForcing = false;
	}
	else if(strhasword(autocvar_menu_reverted_nonsaved_cvars, me.cvarName))
	{
		// Currently claims to be saved, but won't be on next startup.
		me.cvarType = strcat(me.cvarType, ", ", _("will not be saved"));
		needsForcing = true;
	}
	else if(t & CVAR_TYPEFLAG_SAVED)
	{
		me.cvarType = strcat(me.cvarType, ", ", _("will be saved to config.cfg"));
		needsForcing = false;
	}
	else
	{
		me.cvarType = strcat(me.cvarType, ", ", _("will not be saved"));
		needsForcing = true;
	}
	if(t & CVAR_TYPEFLAG_PRIVATE)
		me.cvarType = strcat(me.cvarType, ", ", _("private"));
	if(t & CVAR_TYPEFLAG_ENGINE)
		me.cvarType = strcat(me.cvarType, ", ", _("engine setting"));
	if(t & CVAR_TYPEFLAG_READONLY)
	{
		me.cvarType = strcat(me.cvarType, ", ", _("read only"));
		me.cvarValueBox.disabled = true;
		me.cvarDefaultBox.disabled = true;
	}
	else
	{
		me.cvarValueBox.disabled = false;
		me.cvarDefaultBox.disabled = false;
	}
	me.cvarType = strzone(substring(me.cvarType, 2, strlen(me.cvarType) - 2));
	me.cvarTypeBox.setText(me.cvarTypeBox, me.cvarType);
	return needsForcing;
}
void XonoticCvarList_setSelected(entity me, float i)
{
	string s;

	SUPER(XonoticCvarList).setSelected(me, i);
	if(me.nItems == 0)
		return;

	strfree(me.cvarType);
	strcpy(me.cvarName, bufstr_get(me.handle, me.selectedItem));
	strcpy(me.cvarDescription, cvar_description(me.cvarName));
	strcpy(me.cvarDefault, cvar_defstring(me.cvarName));
	me.cvarNameBox.setText(me.cvarNameBox, me.cvarName);
	me.cvarDescriptionBox.setText(me.cvarDescriptionBox, me.cvarDescription);
	bool needsForcing = me.updateCvarType(me);
	me.cvarDefaultBox.setText(me.cvarDefaultBox, me.cvarDefault);

	// this one can handle tempstrings
	s = cvar_string(me.cvarName);
	me.cvarNeedsForcing = false;
	me.cvarValueBox.setText(me.cvarValueBox, s);
	me.cvarNeedsForcing = needsForcing;
	me.cvarValueBox.cursorPos = strlen(s);
}
void CvarList_Filter_Change(entity box, entity me)
{
	CvarList_Load(me, box.text);
	me.setSelected(me, 0);
}
void CvarList_Filter_ModifiedCvars(entity box, entity me)
{
	cvar_set("menu_cvarlist_onlymodified", ftos(!autocvar_menu_cvarlist_onlymodified));
	box.setChecked(box, autocvar_menu_cvarlist_onlymodified);
	CvarList_Load(me, me.controlledTextbox.text);
	me.setSelected(me, 0);
}
void XonoticCvarList_resizeNotify(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
{
	SUPER(XonoticCvarList).resizeNotify(me, relOrigin, relSize, absOrigin, absSize);

	me.realFontSize_y = me.fontSize / (absSize.y * me.itemHeight);
	me.realFontSize_x = me.fontSize / (absSize.x * (1 - me.controlWidth));
	me.realUpperMargin = 0.5 * (1 - me.realFontSize.y);

	me.columnNameOrigin = 0;
	me.columnValueSize = me.realFontSize.x * 20;
	me.columnNameSize = 1 - me.columnValueSize - me.realFontSize.x;
	me.columnValueOrigin = me.columnNameOrigin + me.columnNameSize + me.realFontSize.x;
}
void XonoticCvarList_drawListBoxItem(entity me, int i, vector absSize, bool isSelected, bool isFocused)
{
	string k, v, d;
	float t;

	vector theColor;
	float theAlpha;

	string s;

	if(isSelected)
		draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED);
	else if(isFocused)
	{
		me.focusedItemAlpha = getFadedAlpha(me.focusedItemAlpha, SKINALPHA_LISTBOX_FOCUSED, SKINFADEALPHA_LISTBOX_FOCUSED);
		draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_FOCUSED, me.focusedItemAlpha);
	}

	k = bufstr_get(me.handle, i);

	v = cvar_string(k);
	d = cvar_defstring(k);
	t = cvar_type(k);
	if(strhasword(autocvar_menu_forced_saved_cvars, k))
		theAlpha = SKINALPHA_CVARLIST_SAVED;
	else if(strhasword(autocvar_menu_reverted_nonsaved_cvars, k))
		theAlpha = SKINALPHA_CVARLIST_TEMPORARY;
	else if(t & CVAR_TYPEFLAG_SAVED)
		theAlpha = SKINALPHA_CVARLIST_SAVED;
	else
		theAlpha = SKINALPHA_CVARLIST_TEMPORARY;
	if(v == d)
		theColor = SKINCOLOR_CVARLIST_UNCHANGED;
	else
		theColor = SKINCOLOR_CVARLIST_CHANGED;

	s = draw_TextShortenToWidth(k, me.columnNameSize, 0, me.realFontSize);
	draw_Text(me.realUpperMargin * eY + me.columnNameOrigin * eX, s, me.realFontSize, theColor, theAlpha, 0);
	s = draw_TextShortenToWidth(v, me.columnValueSize, 0, me.realFontSize);
	draw_Text(me.realUpperMargin * eY + me.columnValueOrigin * eX, s, me.realFontSize, theColor, theAlpha, 0);
}

float XonoticCvarList_keyDown(entity me, float scan, float ascii, float shift)
{
	if (!me.cvarValueBox.disabled && (scan == K_MOUSE3 || ((shift & S_CTRL) && scan == K_SPACE)))
	{
		CvarList_Revert_Click(NULL, me);
		return 1;
	}
	else if(!me.cvarValueBox.disabled && scan == K_ENTER)
	{
		me.cvarValueBox.parent.setFocus(me.cvarValueBox.parent, me.cvarValueBox);
		return 1;
	}
	else if(SUPER(XonoticCvarList).keyDown(me, scan, ascii, shift))
		return 1;
	else if(!me.controlledTextbox || me.cvarValueBox.disabled)
		return 0;
	else
		return me.controlledTextbox.keyDown(me.controlledTextbox, scan, ascii, shift);
}

float XonoticCvarList_mouseRelease(entity me, vector pos)
{
	if (!me.cvarValueBox.disabled && me.pressed == 2)
		me.cvarValueBox.parent.setFocus(me.cvarValueBox.parent, me.cvarValueBox);
	return SUPER(XonoticCvarList).mouseRelease(me, pos);
}

void CvarList_Value_Change(entity box, entity me)
{
	if (box.disabled)
		return;
	cvar_set(me.cvarNameBox.text, box.text);
	if(me.cvarNeedsForcing)
	{
		localcmd(sprintf("\nseta %1$s \"$%1$s\"\n", me.cvarName));
		cvar_set("menu_reverted_nonsaved_cvars", substring(strreplace(strcat(" ", me.cvarName, " "), " ", strcat(" ", autocvar_menu_reverted_nonsaved_cvars, " ")), 1, -2));
		if (autocvar_menu_forced_saved_cvars == "")
			cvar_set("menu_forced_saved_cvars", me.cvarName);
		else
			cvar_set("menu_forced_saved_cvars", strcat(autocvar_menu_forced_saved_cvars, " ", me.cvarName));
		me.cvarNeedsForcing = false;
		me.updateCvarType(me);
	}
}

void CvarList_Revert_Click(entity btn, entity me)
{
	me.cvarValueBox.setText(me.cvarValueBox, me.cvarDefault);
	me.cvarValueBox.cursorPos = strlen(me.cvarDefault);
	if(strhasword(autocvar_menu_forced_saved_cvars, me.cvarName))
	{
		cvar_set("menu_forced_saved_cvars", substring(strreplace(strcat(" ", me.cvarName, " "), " ", strcat(" ", autocvar_menu_forced_saved_cvars, " ")), 1, -2));
		if (autocvar_menu_reverted_nonsaved_cvars == "")
			cvar_set("menu_reverted_nonsaved_cvars", me.cvarName);
		else
			cvar_set("menu_reverted_nonsaved_cvars", strcat(autocvar_menu_reverted_nonsaved_cvars, " ", me.cvarName));
	}
	me.cvarNeedsForcing = me.updateCvarType(me);
}

void CvarList_End_Editing(entity box, entity me)
{
	if (!box.disabled)
		box.parent.setFocus(box.parent, me);
}
