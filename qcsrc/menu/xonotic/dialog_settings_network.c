#ifdef INTERFACE
CLASS(XonoticNetworkSettingsTab) EXTENDS(XonoticTab)
	METHOD(XonoticNetworkSettingsTab, fill, void(entity))
	ATTRIB(XonoticNetworkSettingsTab, title, string, "Network")
	ATTRIB(XonoticNetworkSettingsTab, intendedWidth, float, 0.9)
	ATTRIB(XonoticNetworkSettingsTab, rows, float, 17)
	ATTRIB(XonoticNetworkSettingsTab, columns, float, 6.5)
ENDCLASS(XonoticNetworkSettingsTab)
entity makeXonoticNetworkSettingsTab();
#endif

#ifdef IMPLEMENTATION
entity makeXonoticNetworkSettingsTab()
{
	entity me;
	me = spawnXonoticNetworkSettingsTab();
	me.configureDialog(me);
	return me;
}

void XonoticNetworkSettingsTab_fill(entity me)
{
	entity e;

	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "cl_movement", "Client-side movement prediction"));
	me.TR(me);
		//me.TD(me, 1, 3, e = makeXonoticCheckBox(1, "cl_nolerp", "Network update smoothing"));
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "shownetgraph", "Show netgraph"));
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, "Network speed:"));
		me.TD(me, 1, 2, e = makeXonoticTextSlider("_cl_rate"));
			e.addValue(e, "56k", "4000");
			e.addValue(e, "ISDN", "7000");
			e.addValue(e, "Slow ADSL", "15000");
			e.addValue(e, "Fast ADSL", "20000");
			e.addValue(e, "Broadband", "66666");
			e.configureXonoticTextSliderValues(e);
    me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, "Input packets/s:"));
		me.TD(me, 1, 2, e = makeXonoticSlider(20, 100, 1, "cl_netfps"));
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticTextLabel(0, "HTTP downloads:"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, "Downloads:"));
		me.TD(me, 1, 2, e = makeXonoticSlider(1, 5, 1, "cl_curl_maxdownloads"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, "Speed (kB/s):"));
		me.TD(me, 1, 2, e = makeXonoticSlider(10, 1500, 10, "cl_curl_maxspeed"));
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, "Client UDP port:"));
		me.TD(me, 1, 0.64, e = makeXonoticInputBox(0, "cl_port"));
}
#endif
