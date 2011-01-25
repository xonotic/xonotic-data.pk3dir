#ifdef INTERFACE
CLASS(XonoticMiscSettingsTab) EXTENDS(XonoticTab)
	METHOD(XonoticMiscSettingsTab, fill, void(entity))
	ATTRIB(XonoticMiscSettingsTab, title, string, _("Misc"))
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
		me.TD(me, 1, 3, e = makeXonoticTextLabel(0, _("Menu skins:")));
	me.TR(me);
		me.TD(me, me.rows - 2, 3, sk = makeXonoticSkinList());
	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, 3, e = makeXonoticButton(_("Apply immediately"), '0 0 0'));
			e.onClick = SetSkin_Click;
			e.onClickEntity = sk;

	me.gotoRC(me, 0, 3.5); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 3, e = makeXonoticTextLabel(0, _("Text language:")));
	me.TR(me);
		me.TD(me, 3, 3, sk = makeXonoticLanguageList());
	me.TR(me);
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticButton(_("Apply immediately"), '0 0 0'));
			e.onClick = SetLanguage_Click;
			e.onClickEntity = sk;

	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "showtime", _("Show current time")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "showdate", _("Show current date")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "showfps", _("Show frames per second")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "cl_showspeed", _("Speedometer")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.8/3, e = makeXonoticRadioButton(1, "cl_showspeed_unit", "0", _("qu/s (hidden)")));
			setDependent(e, "cl_showspeed", 1, 1);
		me.TD(me, 1, 2.8/3, e = makeXonoticRadioButton(1, "cl_showspeed_unit", "1", _("qu/s")));
			setDependent(e, "cl_showspeed", 1, 1);
		me.TD(me, 1, 2.8/3, e = makeXonoticRadioButton(1, "cl_showspeed_unit", "2", _("m/s")));
			setDependent(e, "cl_showspeed", 1, 1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.8/3, e = makeXonoticRadioButton(1, "cl_showspeed_unit", "3", _("km/h")));
			setDependent(e, "cl_showspeed", 1, 1);
		me.TD(me, 1, 2.8/3, e = makeXonoticRadioButton(1, "cl_showspeed_unit", "4", _("mph")));
			setDependent(e, "cl_showspeed", 1, 1);
		me.TD(me, 1, 2.8/3, e = makeXonoticRadioButton(1, "cl_showspeed_unit", "5", _("knots")));
			setDependent(e, "cl_showspeed", 1, 1);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "cl_showacceleration", _("Show accelerometer")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.8/2, e = makeXonoticTextLabel(0, _("Accelerometer scale:")));
			setDependent(e, "cl_showacceleration", 1, 1);
		me.TD(me, 1, 2.8/2, e = makeXonoticSlider(0.2, 2, 0.2, "cl_showacceleration_scale"));
			setDependent(e, "cl_showacceleration", 1, 1);
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "cl_maxfps_alwayssleep", _("Minimize input latency")));
	me.TR(me);
	me.TR(me);
		me.TDempty(me, 0.5);
		me.TD(me, 1, 2, e = makeXonoticButton(_("Advanced settings..."), '0 0 0'));
			e.onClick = DialogOpenButton_Click;
			e.onClickEntity = main.cvarsDialog;
}
#endif
