#ifdef INTERFACE
CLASS(XonoticPlayerSettingsTab) EXTENDS(XonoticTab)
	METHOD(XonoticPlayerSettingsTab, fill, void(entity))
	METHOD(XonoticPlayerSettingsTab, draw, void(entity))
	ATTRIB(XonoticPlayerSettingsTab, title, string, _("Player Setup"))
	ATTRIB(XonoticPlayerSettingsTab, intendedWidth, float, 0.9)
	ATTRIB(XonoticPlayerSettingsTab, rows, float, 22)
	ATTRIB(XonoticPlayerSettingsTab, columns, float, 6.5)
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
		me.TD(me, me.rows - me.currentRow - 1, 1.8, pms);
		me.TD(me, 1, 0.3, e = makeXonoticButton(">>", '0 0 0'));
			e.onClick = PlayerModelSelector_Next_Click;
			e.onClickEntity = pms;
	me.TR(me);
		r = me.currentRow;
		m = me.rows - r - 2;
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

	me.gotoRC(me, 0, 3.5); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Field of view:")));
		me.TD(me, 1, 2, e = makeXonoticSlider(60, 130, 1, "fov"));
	me.TR(me);
		sl = makeXonoticSlider(0.45, 0.75, 0.01, "cl_bobcycle");
		me.TD(me, 1, 1, e = makeXonoticSliderCheckBox(0, 1, sl, _("View bobbing:")));
		makeMulti(sl, "cl_bob2cycle");
		me.TD(me, 1, 2, sl);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Zoom factor:")));
		me.TD(me, 1, 2, e = makeXonoticSlider(2, 16, 0.5, "cl_zoomfactor"));
	me.TR(me);
		sl = makeXonoticSlider(1, 8, 0.5, "cl_zoomspeed");
		me.TD(me, 1, 1, e = makeXonoticSliderCheckBox(-1, 1, sl, _("Zoom speed:")));
		me.TD(me, 1, 2, sl);
	me.TR(me);
		me.TD(me, 1, 1.5, e = makeXonoticButton(_("Weapon settings..."), '0 0 0'));
			e.onClick = DialogOpenButton_Click;
			e.onClickEntity = main.weaponsDialog;
		me.TD(me, 1, 1.5, e0 = makeXonoticTextLabel(0, string_null));
			e0.textEntity = main.weaponsDialog;
			e0.allowCut = 1;
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Crosshair:")));
		me.TD(me, 1, 2, e = makeXonoticCheckBox(0, "crosshair_per_weapon", _("Per weapon")));
	me.TR(me);
		me.TDempty(me, 0.2);
		for(i = 1; i <= 10; ++i) {
			me.TDNoMargin(me, 1, 2 / 10, e = makeXonoticCrosshairButton(3, i), '1 1 0');
			setDependent(e, "crosshair_per_weapon", 0, 0);
		}
		// show a larger preview of the selected crosshair
		me.TDempty(me, 0.2);
		me.TDNoMargin(me, 2, 2 / 5, e = makeXonoticCrosshairButton(7, -1), '1 1 0'); // crosshair -1 makes this a preview
		setDependent(e, "crosshair_per_weapon", 0, 0);
	me.TR(me);
		me.TDempty(me, 0.2);
		for(i = 11; i <= 20; ++i) {
			me.TDNoMargin(me, 1, 2 / 10, e = makeXonoticCrosshairButton(3, i), '1 1 0');
			setDependent(e, "crosshair_per_weapon", 0, 0);
		}
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Crosshair size:")));
		me.TD(me, 1, 1.8, e = makeXonoticSlider(0.10, 1.5, 0.05, "crosshair_size"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Crosshair alpha:")));
		me.TD(me, 1, 1.8, e = makeXonoticSlider(0, 1, 0.1, "crosshair_alpha"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Crosshair color:")));
		me.TD(me, 1, 0.9, e = makeXonoticRadioButton(4, "crosshair_color_per_weapon", string_null, _("Per weapon")));
		me.TD(me, 1, 0.9, e = makeXonoticRadioButton(4, "crosshair_color_by_health", string_null, _("By health")));
	me.TR(me);
		me.TDempty(me, 0.3);
		me.TD(me, 1, 0.9, e = makeXonoticRadioButton(4, string_null, string_null, _("Custom")));
		me.TD(me, 2, 1.8, e = makeXonoticColorpickerString("crosshair_color", "crosshair_color"));
			setDependentAND(e, "crosshair_color_per_weapon", 0, 0, "crosshair_color_by_health", 0, 0);
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "crosshair_dot", _("Enable center dot")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.5, e = makeXonoticTextLabel(0, _("Size:")));
		me.TD(me, 1, 0.9, e = makeXonoticSlider(0.2, 2, 0.1, "crosshair_dot_size"));
			setDependent(e, "crosshair_dot", 1, 1);
		me.TD(me, 1, 0.5, e = makeXonoticTextLabel(0, _("Alpha:")));
		me.TD(me, 1, 0.9, e = makeXonoticSlider(0.10, 1, 0.1, "crosshair_dot_alpha"));
			setDependent(e, "crosshair_dot", 1, 1);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Hit test:")));
		me.TD(me, 1, 2/3, e = makeXonoticRadioButton(5, "crosshair_hittest", "0",    ZCTX(_("HTST^None"))));
		me.TD(me, 1, 2/3, e = makeXonoticRadioButton(5, "crosshair_hittest", "1",    _("TrueAim")));
		me.TD(me, 1, 2/3, e = makeXonoticRadioButton(5, "crosshair_hittest", "1.25", _("Enemies")));
	me.TR(me);
		me.TDempty(me, 0.4);
		me.TD(me, 1, 2.2, e = makeXonoticButton(_("Waypoints setup..."), '0 0 0'));
			e.onClick = DialogOpenButton_Click;
			e.onClickEntity = main.waypointDialog;
	me.TR(me);
		me.TDempty(me, 0.4);
		me.TD(me, 1, 2.2, e = makeXonoticButton(_("Enter HUD editor"), '0 0 0'));
			e.onClick = HUDSetup_Join_Click;
			e.onClickEntity = me;
	#ifdef ALLOW_FORCEMODELS
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Force models:")));
		me.TD(me, 1, 2/3, e = makeXonoticRadioButton(6, string_null, string_null, ZCTX(_("MDL^None"))));
		me.TD(me, 1, 2/3, e = makeXonoticRadioButton(6, "cl_forceplayermodelsfromxonotic", string_null, ZCTX(_("MDL^Custom"))));
		me.TD(me, 1, 2/3, e = makeXonoticRadioButton(6, "cl_forceplayermodels", string_null, ZCTX(_("MDL^All"))));
	#endif
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "cl_gentle", _("Disable gore effects")));
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Gibs:")));
		me.TD(me, 1, 2, e = makeXonoticTextSlider("cl_nogibs"));
			e.addValue(e, ZCTX(_("GIBS^None")), "1");
			e.addValue(e, ZCTX(_("GIBS^Few")), "0.75");
			e.addValue(e, ZCTX(_("GIBS^Many")), "0.5");
			e.addValue(e, ZCTX(_("GIBS^Lots")), "0");
			e.configureXonoticTextSliderValues(e);
			setDependent(e, "cl_gentle", 0, 0);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Damage splash:")));
		me.TD(me, 1, 2, e = makeXonoticSlider(0, 1, 0.05, "hud_damage"));

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
