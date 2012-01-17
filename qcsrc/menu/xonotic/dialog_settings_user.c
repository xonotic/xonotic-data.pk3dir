#ifdef INTERFACE
CLASS(XonoticUserSettingsTab) EXTENDS(XonoticTab)
	METHOD(XonoticUserSettingsTab, fill, void(entity))
	ATTRIB(XonoticUserSettingsTab, title, string, _("User"))
	ATTRIB(XonoticUserSettingsTab, intendedWidth, float, 0.9)
	ATTRIB(XonoticUserSettingsTab, rows, float, 17)
	ATTRIB(XonoticUserSettingsTab, columns, float, 6.2) // added extra .2 for center space 
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

	me.TR(me);
		//me.TD(me, 1, 3, e = makeXonoticCheckBox(1, "cl_nolerp", _("User update smoothing")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "shownetgraph", _("Show netgraph")));
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("User speed:")));
		me.TD(me, 1, 2, e = makeXonoticTextSlider("_cl_rate"));
			e.addValue(e, _("56k"), "4000");
			e.addValue(e, _("ISDN"), "7000");
			e.addValue(e, _("Slow ADSL"), "15000");
			e.addValue(e, _("Fast ADSL"), "20000");
			e.addValue(e, _("Broadband"), "66666");
			e.configureXonoticTextSliderValues(e);
    me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Input packets/s:")));
		me.TD(me, 1, 2, e = makeXonoticSlider(20, 100, 1, "cl_netfps"));
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticTextLabel(0, _("HTTP downloads:")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Downloads:")));
		me.TD(me, 1, 2, e = makeXonoticSlider(1, 5, 1, "cl_curl_maxdownloads"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Speed (kB/s):")));
		me.TD(me, 1, 2, e = makeXonoticSlider(10, 1500, 10, "cl_curl_maxspeed"));
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Client UDP port:")));
		me.TD(me, 1, 0.64, e = makeXonoticInputBox(0, "cl_port"));
}
#endif
