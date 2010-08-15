#ifdef INTERFACE
CLASS(XonoticMiscSettingsTab) EXTENDS(XonoticTab)
	METHOD(XonoticMiscSettingsTab, fill, void(entity))
	ATTRIB(XonoticMiscSettingsTab, title, string, "Misc")
	ATTRIB(XonoticMiscSettingsTab, intendedWidth, float, 0.9)
	ATTRIB(XonoticMiscSettingsTab, rows, float, 17)
	ATTRIB(XonoticMiscSettingsTab, columns, float, 6.5)
ENDCLASS(XonoticMiscSettingsTab)
entity makeXonoticMiscSettingsTab();
#endif

#ifdef IMPLEMENTATION
entity makeXonoticMiscSettingsTab()
{
	entity me;
	me = spawnXonoticMiscSettingsTab();
	me.configureDialog(me);
	return me;
}
void XonoticMiscSettingsTab_fill(entity me)
{
	entity e;
	entity sk;

	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticTextLabel(0, "Menu skins:"));
	me.TR(me);
		me.TD(me, me.rows - 2, 3, sk = makeXonoticSkinList());
	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, 3, e = makeXonoticButton("Apply immediately", '0 0 0'));
			e.onClick = SetSkin_Click;
			e.onClickEntity = sk;

	me.gotoRC(me, 0, 3.5); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "showtime", "Show current time"));
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "showdate", "Show current date"));
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "showfps", "Show frames per second"));
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "cl_showspeed", "Speedometer"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.8/3, e = makeXonoticRadioButton(1, "cl_showspeed_unit", "0", "qu/s (hidden)"));
			setDependent(e, "cl_showspeed", 1, 1);
		me.TD(me, 1, 2.8/3, e = makeXonoticRadioButton(1, "cl_showspeed_unit", "1", "qu/s"));
			setDependent(e, "cl_showspeed", 1, 1);
		me.TD(me, 1, 2.8/3, e = makeXonoticRadioButton(1, "cl_showspeed_unit", "2", "m/s"));
			setDependent(e, "cl_showspeed", 1, 1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.8/3, e = makeXonoticRadioButton(1, "cl_showspeed_unit", "3", "km/h"));
			setDependent(e, "cl_showspeed", 1, 1);
		me.TD(me, 1, 2.8/3, e = makeXonoticRadioButton(1, "cl_showspeed_unit", "4", "mph"));
			setDependent(e, "cl_showspeed", 1, 1);
		me.TD(me, 1, 2.8/3, e = makeXonoticRadioButton(1, "cl_showspeed_unit", "5", "knots"));
			setDependent(e, "cl_showspeed", 1, 1);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "cl_showacceleration", "Show accelerometer"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.8/2, e = makeXonoticTextLabel(0, "Accelerometer scale:"));
			setDependent(e, "cl_showacceleration", 1, 1);
		me.TD(me, 1, 2.8/2, e = makeXonoticSlider(1, 10, 0.5, "cl_showacceleration_scale"));
			setDependent(e, "cl_showacceleration", 1, 1);
	me.TR(me);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.8, e = makeXonoticCheckBox(0, "cl_maxfps_alwayssleep", "Minimize input latency"));
	me.TR(me);
	me.TR(me);
		me.TDempty(me, 0.5);
		me.TD(me, 1, 2, e = makeXonoticButton("Advanced settings...", '0 0 0'));
			e.onClick = DialogOpenButton_Click;
			e.onClickEntity = main.cvarsDialog;
}
#endif
