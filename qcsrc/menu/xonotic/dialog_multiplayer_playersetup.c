#ifdef INTERFACE
CLASS(XonoticPlayerSettingsTab) EXTENDS(XonoticTab)
	METHOD(XonoticPlayerSettingsTab, fill, void(entity))
	METHOD(XonoticPlayerSettingsTab, draw, void(entity))
	ATTRIB(XonoticPlayerSettingsTab, title, string, _("Player Setup"))
	ATTRIB(XonoticPlayerSettingsTab, intendedWidth, float, 0.9)
	ATTRIB(XonoticPlayerSettingsTab, rows, float, 22)
	ATTRIB(XonoticPlayerSettingsTab, columns, float, 6.2) // added extra .2 for center space 
	ATTRIB(XonoticPlayerSettingsTab, playerNameLabel, entity, NULL)
	ATTRIB(XonoticPlayerSettingsTab, playerNameLabelAlpha, float, 0)
ENDCLASS(XonoticPlayerSettingsTab)
entity makeXonoticPlayerSettingsTab();

void HUDSetup_Join_Click(entity me, entity btn);
#endif

#ifdef IMPLEMENTATION

entity makeXonoticPlayerSettingsTab()
{
	entity me;
	me = spawnXonoticPlayerSettingsTab();
	me.configureDialog(me);
	return me;
}
void XonoticPlayerSettingsTab_draw(entity me)
{
	if(cvar_string("_cl_name") == "Player")
		me.playerNameLabel.alpha = ((mod(time * 2, 2) < 1) ? 1 : 0);
	else
		me.playerNameLabel.alpha = me.playerNameLabelAlpha;
	SUPER(XonoticPlayerSettingsTab).draw(me);
}
void XonoticPlayerSettingsTab_fill(entity me)
{
	entity e, pms, sl, label, e0, box;
	float i, r, m, n;

	me.TR(me);
		me.TD(me, 1, 0.5, me.playerNameLabel = makeXonoticTextLabel(0, _("Name:")));
			me.playerNameLabelAlpha = me.playerNameLabel.alpha;
		me.TD(me, 1, 2.5, label = makeXonoticTextLabel(0, string_null));
			label.allowCut = 1;
			label.allowColors = 1;
			label.alpha = 1;
	me.TR(me);
		me.TD(me, 1, 3.0, box = makeXonoticInputBox(1, "_cl_name"));
			box.forbiddenCharacters = "\r\n\\\"$"; // don't care, isn't getting saved
			box.maxLength = -127; // negative means encoded length in bytes
			box.saveImmediately = 1;
			label.textEntity = box;
	me.TR(me);
		me.TD(me, 5, 1, e = makeXonoticColorpicker(box));
		me.TD(me, 5, 2, e = makeXonoticCharmap(box));
	me.TR(me);
	me.TR(me);
	me.TR(me);
	me.TR(me);
	me.TR(me);
	me.TR(me);
	me.gotoRC(me, 8, 0.0);
		pms = makeXonoticPlayerModelSelector();
		me.TD(me, 1, 0.6, e = makeXonoticTextLabel(1, _("Model:")));
		me.TD(me, 1, 0.3, e = makeXonoticButton("<<", '0 0 0'));
			e.onClick = PlayerModelSelector_Prev_Click;
			e.onClickEntity = pms;
		me.TD(me, me.rows - (me.currentRow + 3), 1.8, pms);
		me.TD(me, 1, 0.3, e = makeXonoticButton(">>", '0 0 0'));
			e.onClick = PlayerModelSelector_Next_Click;
			e.onClickEntity = pms;
	me.TR(me);
		r = me.currentRow;
		m = me.rows - (r + 4);
		n = 16 - !cvar("developer");
		m = m / (n - 1);
		for(i = 0; i < n; ++i)
		{
			me.gotoRC(me, r + i * m, 0.1);
			me.TDNoMargin(me, m, 0.2, e = makeXonoticColorButton(1, 0, i), '0 1 0');
		}
		for(i = 0; i < n; ++i)
		{
			me.gotoRC(me, r + i * m, 0.4);
			me.TDNoMargin(me, m, 0.2, e = makeXonoticColorButton(2, 1, i), '0 1 0');
		}

	me.gotoRC(me, 0, 3.2); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 3, e = makeXonoticRadioButton(3, "crosshair_enabled", "0", _("No crosshair")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticRadioButton(3, "crosshair_per_weapon", string_null, _("Per weapon crosshair")));
		makeMulti(e, "crosshair_enabled");
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticRadioButton(3, "crosshair_enabled", "2", _("Custom crosshair")));
	me.TR(me);
		me.TDempty(me, 0.1);
		for(i = 1; i <= 10; ++i) {
			me.TDNoMargin(me, 1, 2 / 10, e = makeXonoticCrosshairButton(4, i), '1 1 0');
				setDependentAND(e, "crosshair_per_weapon", 0, 0, "crosshair_enabled", 1, 2);
		}
		// show a larger preview of the selected crosshair
		me.TDempty(me, 0.1);
		me.TDNoMargin(me, 3, 0.8, e = makeXonoticCrosshairButton(7, -1), '1 1 0'); // crosshair -1 makes this a preview
			setDependentAND(e, "crosshair_per_weapon", 0, 0, "crosshair_enabled", 1, 2);
	me.TR(me);
		me.TDempty(me, 0.1);
		for(i = 11; i <= 20; ++i) {
			me.TDNoMargin(me, 1, 2 / 10, e = makeXonoticCrosshairButton(4, i), '1 1 0');
				setDependentAND(e, "crosshair_per_weapon", 0, 0, "crosshair_enabled", 1, 2);
		}
	me.TR(me);
		me.TDempty(me, 0.1);
		for(i = 21; i <= 30; ++i) {
			me.TDNoMargin(me, 1, 2 / 10, e = makeXonoticCrosshairButton(4, i), '1 1 0');
				setDependentAND(e, "crosshair_per_weapon", 0, 0, "crosshair_enabled", 1, 2);
		}
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Crosshair size:")));
			setDependent(e, "crosshair_enabled", 1, 2);
		me.TD(me, 1, 2, e = makeXonoticSlider(0.1, 1.0, 0.01, "crosshair_size"));
			setDependent(e, "crosshair_enabled", 1, 2);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Crosshair alpha:")));
			setDependent(e, "crosshair_enabled", 1, 2);
		me.TD(me, 1, 2, e = makeXonoticSlider(0, 1, 0.1, "crosshair_alpha"));
			setDependent(e, "crosshair_enabled", 1, 2);
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Crosshair color:")));
			setDependent(e, "crosshair_enabled", 1, 2);
		me.TD(me, 1, 1, e = makeXonoticRadioButton(5, "crosshair_color_per_weapon", string_null, _("Per weapon")));
			setDependent(e, "crosshair_enabled", 1, 2);
		me.TD(me, 1, 1, e = makeXonoticRadioButton(5, "crosshair_color_by_health", string_null, _("By health")));
			setDependent(e, "crosshair_enabled", 1, 2);
	me.TR(me);
		me.TDempty(me, 0.1);
		me.TD(me, 1, 0.8, e = makeXonoticRadioButton(5, string_null, string_null, _("Custom")));
			setDependent(e, "crosshair_enabled", 1, 2);
		me.TD(me, 2, 2, e = makeXonoticColorpickerString("crosshair_color", "crosshair_color"));
			setDependentAND3(e, "crosshair_color_per_weapon", 0, 0, "crosshair_color_by_health", 0, 0, "crosshair_enabled", 1, 2);
	me.TR(me);
	me.TR(me);
	me.TR(me);
		me.TDempty(me, 0.5);
		me.TD(me, 1, 2, e = makeXonoticButton(_("Other crosshair settings"), '0 0 0'));
			e.onClick = HUDSetup_Join_Click;
			e.onClickEntity = me;
		setDependent(e, "crosshair_enabled", 1, 2);
	me.TR(me);
	me.TR(me);
		me.TDempty(me, 0.5);
		me.TD(me, 1, 2, e = makeXonoticButton(_("Model settings"), '0 0 0'));
			e.onClick = HUDSetup_Join_Click;
			e.onClickEntity = me;
	me.TR(me);
		me.TDempty(me, 0.5);
		me.TD(me, 1, 2, e = makeXonoticButton(_("View settings"), '0 0 0'));
			e.onClick = HUDSetup_Join_Click;
			e.onClickEntity = me;
	me.TR(me);
		me.TDempty(me, 0.5);
		me.TD(me, 1, 2, e = makeXonoticButton(_("Weapon settings"), '0 0 0'));
			e.onClick = HUDSetup_Join_Click;
			e.onClickEntity = me;
	me.TR(me);
		me.TDempty(me, 0.5);
		me.TD(me, 1, 2, e = makeXonoticButton(_("HUD settings"), '0 0 0'));
			e.onClick = HUDSetup_Join_Click;
			e.onClickEntity = me;

	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, makeXonoticCommandButton(_("Apply immediately"), '0 0 0', "color -1 -1;name \"$_cl_name\";cl_cmd sendcvar cl_weaponpriority;sendcvar cl_zoomfactor;sendcvar cl_zoomspeed;sendcvar cl_autoswitch;sendcvar cl_forceplayermodelsfromxonotic;sendcvar cl_forceplayermodels;playermodel $_cl_playermodel;playerskin $_cl_playerskin", COMMANDBUTTON_APPLY));
}
void HUDSetup_Join_Click(entity me, entity btn)
{
	if(! (gamestatus & (GAME_CONNECTED | GAME_ISSERVER)))
	{
		localcmd("map hudsetup/hudsetup", "\n");
	}
	else
		localcmd("togglemenu 0\n");
	localcmd("_hud_configure 1", "\n");
}
#endif
