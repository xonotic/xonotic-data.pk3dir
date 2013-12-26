#ifdef INTERFACE
CLASS(XonoticGameModelSettingsTab) EXTENDS(XonoticTab)
	//METHOD(XonoticGameModelSettingsTab, toString, string(entity))
	METHOD(XonoticGameModelSettingsTab, fill, void(entity))
	METHOD(XonoticGameModelSettingsTab, showNotify, void(entity))
	ATTRIB(XonoticGameModelSettingsTab, title, string, _("Model"))
	ATTRIB(XonoticGameModelSettingsTab, intendedWidth, float, 0.9)
	ATTRIB(XonoticGameModelSettingsTab, rows, float, 14)
	ATTRIB(XonoticGameModelSettingsTab, columns, float, 6.2)
ENDCLASS(XonoticGameModelSettingsTab)
entity makeXonoticGameModelSettingsTab();
#endif

#ifdef IMPLEMENTATION
void XonoticGameModelSettingsTab_showNotify(entity me)
{
	loadAllCvars(me);
}
entity makeXonoticGameModelSettingsTab()
{
	entity me;
	me = spawnXonoticGameModelSettingsTab();
	me.configureDialog(me);
	return me;
}

void XonoticGameModelSettingsTab_fill(entity me)
{
	entity e;
	//float i;

	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Body fading:")));
		me.TD(me, 1, 2, e = makeXonoticSlider(0, 2, 0.2, "cl_deathglow"));
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
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "cl_forceplayermodels", _("Force player models to mine")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "cl_forceplayercolors", _("Force player colors to mine")));
}
#endif
