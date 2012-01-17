#ifdef INTERFACE
CLASS(XonoticUserSettingsTab) EXTENDS(XonoticTab)
	METHOD(XonoticUserSettingsTab, fill, void(entity))
	ATTRIB(XonoticUserSettingsTab, title, string, _("User"))
	ATTRIB(XonoticUserSettingsTab, intendedWidth, float, 0.9)
	ATTRIB(XonoticUserSettingsTab, rows, float, 17)
	ATTRIB(XonoticUserSettingsTab, columns, float, 5)
ENDCLASS(XonoticUserSettingsTab)
entity makeXonoticUserSettingsTab();
#endif

#ifdef IMPLEMENTATION
entity makeXonoticUserSettingsTab()
{
	entity me;
	me = spawnXonoticUserSettingsTab();
	me.configureDialog(me);
	return me;
}

void XonoticUserSettingsTab_fill(entity me)
{
	entity e;
	entity sk;

	me.TR(me);
		me.TD(me, 1, 2, e = makeXonoticTextLabel(0, _("Menu skins:")));
	me.TR(me);
		me.TD(me, me.rows - 2, 2, sk = makeXonoticSkinList());
	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, 2, e = makeXonoticButton(_("Apply immediately"), '0 0 0'));
			e.onClick = SetSkin_Click;
			e.onClickEntity = sk;

	me.gotoRC(me, 0, 2.2); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Text language:")));
	me.TR(me);
		me.TD(me, 6, 1, sk = makeXonoticLanguageList());
	me.TR(me);
	me.TR(me);
	me.TR(me);
	me.TR(me);
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticButton(_("Set language"), '0 0 0'));
			e.onClick = SetLanguage_Click;
			e.onClickEntity = sk;

	me.gotoRC(me, 0, 3.3); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 1.5, e = makeXonoticTextLabel(0, _("Font:")));
	me.TR(me);
		me.TD(me, 2, 1.5, sk = makeXonoticLanguageList());
	me.TR(me);
	me.TR(me);
	me.TR(me);
	me.TR(me);
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1.5, e = makeXonoticButton(_("Set font"), '0 0 0'));
			e.onClick = SetLanguage_Click;
			e.onClickEntity = sk;
		
	me.gotoRC(me, 7, 2.2); me.setFirstColumn(me, me.currentColumn);
	if(cvar("developer"))
	{
		me.TR(me);
		me.TR(me);
			me.TD(me, 1, 0.75, e = makeXonoticTextLabel(0, _("Menu tooltips:")));
			me.TD(me, 1, 0.75, e = makeXonoticRadioButton(2, "menu_tooltips", "0", _("Disabled")));
			me.TD(me, 1, 0.75, e = makeXonoticRadioButton(2, "menu_tooltips", "1", _("Standard")));
			me.TD(me, 1, 0.75, e = makeXonoticRadioButton(2, "menu_tooltips", "2", _("Advanced")));
	}
}
#endif
