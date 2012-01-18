#ifdef INTERFACE
CLASS(XonoticMiscSettingsTab) EXTENDS(XonoticTab)
	METHOD(XonoticMiscSettingsTab, fill, void(entity))
	ATTRIB(XonoticMiscSettingsTab, title, string, _("Misc"))
	ATTRIB(XonoticMiscSettingsTab, intendedWidth, float, 0.9)
	ATTRIB(XonoticMiscSettingsTab, rows, float, 17)
	ATTRIB(XonoticMiscSettingsTab, columns, float, 6.2)
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
		me.TD(me, 1, 3, e = makeXonoticTextLabel(0, _("Network:")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Speed:")));
		me.TD(me, 1, 2, e = makeXonoticTextSlider("_cl_rate"));
			e.addValue(e, _("56k"), "4000");
			e.addValue(e, _("ISDN"), "7000");
			e.addValue(e, _("Slow ADSL"), "15000");
			e.addValue(e, _("Fast ADSL"), "20000");
			e.addValue(e, _("Broadband"), "66666");
			e.configureXonoticTextSliderValues(e);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Input packets/s:")));
		me.TD(me, 1, 2, e = makeXonoticSlider(20, 100, 5, "cl_netfps"));
	me.TR(me);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.8, e = makeXonoticTextLabel(0, _("Client UDP port:")));
		me.TD(me, 1, 1, e = makeXonoticInputBox(0, "cl_port"));
	me.TR(me);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.8, e = makeXonoticCheckBox(0, "shownetgraph", _("Show netgraph")));
	me.TR(me);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.8, e = makeXonoticCheckBox(0, "cl_movement", _("Client-side movement prediction")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.8, e = makeXonoticCheckBox(0, "cl_movement_errorcompensation", _("Compensate for prediction errors")));
		setDependent(e, "cl_movement", 1, 1);
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticTextLabel(0, _("Downloads:")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Maximum:")));
		me.TD(me, 1, 2, e = makeXonoticSlider(1, 5, 1, "cl_curl_maxdownloads"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Speed (kB/s):")));
		me.TD(me, 1, 2, e = makeXonoticSlider(10, 1500, 10, "cl_curl_maxspeed"));
	me.TR(me);

	me.gotoRC(me, 0, 3.2); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "showtime", _("Show current time")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "showdate", _("Show current date")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "showfps", _("Show frames per second")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "cl_maxfps_alwayssleep", _("Minimize input latency")));
		
	me.TR(me);
	me.TR(me);
		me.TDempty(me, 0.5);
		me.TD(me, 1, 2, e = makeXonoticButton(_("Advanced settings..."), '0 0 0'));
			e.onClick = DialogOpenButton_Click;
			e.onClickEntity = main.cvarsDialog;
	me.TR(me);
}
#endif
