#include "weaponslist.qh"

#include <common/weapons/_all.qh>

.bool disabled;

string XonoticWeaponsList_cb_name, XonoticWeaponsList_cb_icon;
void XonoticWeaponsList_cb(string _name, string _icon)
{
	XonoticWeaponsList_cb_name = _name;
	XonoticWeaponsList_cb_icon = _icon;
}

entity makeXonoticWeaponsList()
{
	entity me;
	me = NEW(XonoticWeaponsList);
	me.configureXonoticListBox(me);
	return me;
}

void XonoticWeaponsList_draw(entity me)
{
	// read in cvar?
	string s, t;
	s = W_NumberWeaponOrder(cvar_string("cl_weaponpriority"));
	t = W_FixWeaponOrder(s, 1);
	if(t != s)
		cvar_set("cl_weaponpriority", W_NameWeaponOrder(t));
	me.nItems = tokenize_console(t);
	SUPER(XonoticWeaponsList).draw(me);
}
void WeaponsList_MoveUp_Click(entity box, entity me)
{
	if(me.selectedItem > 0)
	{
		cvar_set("cl_weaponpriority", swapInPriorityList(cvar_string("cl_weaponpriority"), me.selectedItem - 1, me.selectedItem));
		me.setSelected(me, me.selectedItem - 1);
	}
}
void WeaponsList_MoveDown_Click(entity box, entity me)
{
	if(me.selectedItem < me.nItems - 1)
	{
		cvar_set("cl_weaponpriority", swapInPriorityList(cvar_string("cl_weaponpriority"), me.selectedItem, me.selectedItem + 1));
		me.setSelected(me, me.selectedItem + 1);
	}
}
void XonoticWeaponsList_resizeNotify(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
{
	SUPER(XonoticWeaponsList).resizeNotify(me, relOrigin, relSize, absOrigin, absSize);

	me.itemAbsSize.y = absSize.y * me.itemHeight;
	me.itemAbsSize.x = absSize.x * (1 - me.controlWidth);
	me.realFontSize.y = me.fontSize / me.itemAbsSize.y;
	me.realFontSize.x = me.fontSize / me.itemAbsSize.x;
	me.realUpperMargin = 0.5 * (1 - me.realFontSize.y);

	entity e = REGISTRY_GET(Weapons, WEP_FIRST);
	e.display(e, XonoticWeaponsList_cb);
	vector sz = draw_PictureSize(XonoticWeaponsList_cb_icon);
	float aspect_ratio = sz.y ? sz.x / sz.y : 1;
	me.columnIconOrigin = 0.25 * me.realFontSize.x;
	me.columnIconSize = me.itemAbsSize.y / me.itemAbsSize.x * aspect_ratio;

	me.columnNameOrigin = me.columnIconOrigin + me.columnIconSize + (0.25 * me.realFontSize.x);
	me.columnNameSize = 1 - me.columnIconSize - (1.5 * me.realFontSize.x); // unused
}
float XonoticWeaponsList_mouseDrag(entity me, vector pos)
{
	int i = me.selectedItem;
	float f = SUPER(XonoticWeaponsList).mouseDrag(me, pos);

	if(me.pressed != 1) // don't change priority if the person is just scrolling
	{
		if(me.selectedItem != i)
		{
			if(me.applyButton)
				me.applyButton.disabled = false;
			cvar_set("cl_weaponpriority", swapInPriorityList(cvar_string("cl_weaponpriority"), me.selectedItem, i));
		}
	}

	return f;
}
string XonoticWeaponsList_toString(entity me)
{
	float n, i;
	string s;
	entity e;
	n = tokenize_console(W_NumberWeaponOrder(cvar_string("cl_weaponpriority")));
	s = "";
	for(i = 0; i < n; ++i)
	{
		e = REGISTRY_GET(Weapons, stof(argv(i)));
		s = strcat(s, e.m_name, ", ");
	}
	return substring(s, 0, strlen(s) - 2);
}
void XonoticWeaponsList_drawListBoxItem(entity me, int i, vector absSize, bool isSelected, bool isFocused)
{
	entity e;
	if(isSelected)
		draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED);
	else if(isFocused)
	{
		me.focusedItemAlpha = getFadedAlpha(me.focusedItemAlpha, SKINALPHA_LISTBOX_FOCUSED, SKINFADEALPHA_LISTBOX_FOCUSED);
		draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_FOCUSED, me.focusedItemAlpha);
	}
	e = REGISTRY_GET(Weapons, stof(argv(i)));
	e.display(e, XonoticWeaponsList_cb);
	string msg = XonoticWeaponsList_cb_name;
	string icon = XonoticWeaponsList_cb_icon;

	draw_Picture(me.columnIconOrigin * eX, icon, me.columnIconSize * eX + eY, '1 1 1', SKINALPHA_LISTBOX_SELECTED);

	bool drawStar = e.spawnflags & WEP_FLAG_MUTATORBLOCKED;
	vector save_fontscale = draw_fontscale;
	float f = draw_CondensedFontFactor(strcat(msg, drawStar ? "*" : ""), false, me.realFontSize, 1);
	draw_fontscale.x *= f;
	vector fs = me.realFontSize;
	fs.x *= f;
	draw_Text(me.realUpperMargin * eY + me.columnNameOrigin * eX, msg, fs, SKINCOLOR_TEXT, SKINALPHA_TEXT, 0);
	if(drawStar)
		draw_Text(me.realUpperMargin * eY + (me.columnNameOrigin + draw_TextWidth(msg, 0, fs)) * eX, "*", fs, SKINCOLOR_HEADER, SKINALPHA_HEADER, 0);
	draw_fontscale = save_fontscale;
}

float XonoticWeaponsList_keyDown(entity me, float key, float ascii, float shift)
{
	if (((shift & S_CTRL) && (key == K_UPARROW || key == K_KP_UPARROW))
		|| ascii == '+')
	{
		WeaponsList_MoveUp_Click(NULL, me);
		return 1;
	}
	else if (((shift & S_CTRL) && (key == K_DOWNARROW || key == K_KP_DOWNARROW))
		|| ascii == '-')
	{
		WeaponsList_MoveDown_Click(NULL, me);
		return 1;
	}
	else if(SUPER(XonoticWeaponsList).keyDown(me, key, ascii, shift))
		return 1;
	return 0;
}
