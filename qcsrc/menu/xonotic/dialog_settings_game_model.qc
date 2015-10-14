#ifndef DIALOG_SETTINGS_GAME_MODEL_H
#define DIALOG_SETTINGS_GAME_MODEL_H
#include "tab.qc"
CLASS(XonoticGameModelSettingsTab, XonoticTab)
	METHOD(XonoticGameModelSettingsTab, fill, void(entity));
	METHOD(XonoticGameModelSettingsTab, showNotify, void(entity));
	ATTRIB(XonoticGameModelSettingsTab, title, string, _("Models"))
	ATTRIB(XonoticGameModelSettingsTab, intendedWidth, float, 0.9)
	ATTRIB(XonoticGameModelSettingsTab, rows, float, 13)
	ATTRIB(XonoticGameModelSettingsTab, columns, float, 5)
ENDCLASS(XonoticGameModelSettingsTab)
entity makeXonoticGameModelSettingsTab();
#include "../gamesettings.qh"
REGISTER_SETTINGS(Models, makeXonoticGameModelSettingsTab());
#endif

#ifdef IMPLEMENTATION
void XonoticGameModelSettingsTab_showNotify(entity me)
{
	loadAllCvars(me);
}
entity makeXonoticGameModelSettingsTab()
{
	entity me;
	me = NEW(XonoticGameModelSettingsTab);
	me.configureDialog(me);
	return me;
}

void XonoticGameModelSettingsTab_fill(entity me)
{
	entity e;
	//float i;

	// Note that this is pretty terrible currently due to the lack of options for this tab...
	// There is really not many other decent places for these options, additionally
	// later I would like quite a few more options in this tab.

	me.gotoRC(me, 0, 1); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 3, e = makeXonoticHeaderLabel(_("Items")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "cl_simple_items", _("Use simple 2D images instead of item models")));
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Unavailable alpha:")));
		me.TD(me, 1, 2, e = makeXonoticSlider(0, 1, 0.1, "cl_ghost_items"));
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Unavailable color:")));
		me.TD(me, 1, 2, e = makeXonoticTextSlider("cl_ghost_items_color"));
			e.addValue(e, ZCTX(_("GHOITEMS^Black")), "-1 -1 -1");
			e.addValue(e, ZCTX(_("GHOITEMS^Dark")), "0.1 0.1 0.1");
			e.addValue(e, ZCTX(_("GHOITEMS^Tinted")), "0.6 0.6 0.6");
			e.addValue(e, ZCTX(_("GHOITEMS^Normal")), "1 1 1");
			e.addValue(e, ZCTX(_("GHOITEMS^Blue")), "-1 -1 3");
			e.configureXonoticTextSliderValues(e);
			setDependent(e, "cl_ghost_items", 0.001, 1);

	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticHeaderLabel(_("Players")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "cl_forceplayermodels", _("Force player models to mine")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "cl_forceplayercolors", _("Force player colors to mine")));
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
}
#endif
