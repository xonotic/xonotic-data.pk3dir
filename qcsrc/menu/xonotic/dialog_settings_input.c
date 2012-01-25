#ifdef INTERFACE
CLASS(XonoticInputSettingsTab) EXTENDS(XonoticTab)
	METHOD(XonoticInputSettingsTab, fill, void(entity))
	ATTRIB(XonoticInputSettingsTab, title, string, _("Input"))
	ATTRIB(XonoticInputSettingsTab, intendedWidth, float, 0.9)
	ATTRIB(XonoticInputSettingsTab, rows, float, 17)
	ATTRIB(XonoticInputSettingsTab, columns, float, 6.5)
ENDCLASS(XonoticInputSettingsTab)
entity makeXonoticInputSettingsTab();
#endif

#ifdef IMPLEMENTATION
entity makeXonoticInputSettingsTab()
{
	entity me;
	me = spawnXonoticInputSettingsTab();
	me.configureDialog(me);
	return me;
}
void XonoticInputSettingsTab_fill(entity me)
{
	entity e;
	entity kb;

	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticTextLabel(0, _("Key bindings:")));
	me.TR(me);
		me.TD(me, me.rows - 4, 3.3, kb = makeXonoticKeyBinder());
	me.gotoRC(me, me.rows - 3, 0);
	me.TR(me);
		me.TD(me, 1, 1.1, e = makeXonoticButton(_("Change key..."), '0 0 0'));
			e.onClick = KeyBinder_Bind_Change;
			e.onClickEntity = kb;
			kb.keyGrabButton = e;
		me.TD(me, 1, 1.1, e = makeXonoticButton(_("Edit..."), '0 0 0'));
			e.onClick = KeyBinder_Bind_Edit;
			e.onClickEntity = kb;
			kb.userbindEditButton = e;
			kb.userbindEditDialog = main.userbindEditDialog;
			main.userbindEditDialog.keybindBox = kb;
		me.TD(me, 1, 1.1, e = makeXonoticButton(_("Clear"), '0 0 0'));
			e.onClick = KeyBinder_Bind_Clear;
			e.onClickEntity = kb;

	me.gotoRC(me, 0, 3.5); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Sensitivity:")));
		me.TD(me, 1, 2, e = makeXonoticSlider(1, 32, 0.2, "sensitivity"));
	me.TR(me);
		if(cvar("menu_mouse_absolute") == 0) // TODO remove this entirely later
		{
			me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("UI mouse speed:")));
			me.TD(me, 1, 2, e = makeXonoticSlider(0.2, 4.0, 0.1, "menu_mouse_speed"));
		}
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "m_filter", _("Mouse filter")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(1.022, "m_pitch", _("Invert mouse")));
	me.TR(me);
		if(cvar_type("joy_enable") & CVAR_TYPEFLAG_ENGINE)
			me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "joy_enable", _("Use joystick input")));
		else if(cvar_type("joystick") & CVAR_TYPEFLAG_ENGINE)
			me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "joystick", _("Use joystick input")));
	me.TR(me);
		if(cvar_type("vid_dgamouse") & CVAR_TYPEFLAG_ENGINE)
			me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "vid_dgamouse", _("Turn off OS mouse acceleration")));
		else if(cvar_type("apple_mouse_noaccel") & CVAR_TYPEFLAG_ENGINE)
			me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "apple_mouse_noaccel", _("Turn off OS mouse acceleration")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "con_closeontoggleconsole", _("\"enter console\" also closes")));
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(1, "cl_movement_track_canjump", _("Holding jump key keeps jumping")));
	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, makeXonoticCommandButton(_("Apply immediately"), '0 0 0', "sendcvar cl_movement_track_canjump", COMMANDBUTTON_APPLY));
}
#endif
