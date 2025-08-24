#include "dialog_settings_game_model.qh"

#include "textlabel.qh"
#include "checkbox.qh"
#include "textslider.qh"
#include "mixedslider.qh"
#include "slider.qh"

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
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Unavailable opacity:")));
		me.TD(me, 1, 2, e = makeXonoticSlider(0, 1, 0.1, "cl_ghost_items"));
			e.formatString = "%";
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Unavailable color:")));
			setDependentNOT(e, "cl_ghost_items", 0);
		me.TD(me, 1, 2, e = makeXonoticTextSlider("cl_ghost_items_color"));
			e.addValue(e, ZCTX(_("GHOITEMS^Black")), "-1 -1 -1");
			e.addValue(e, ZCTX(_("GHOITEMS^Dark")), "0.1 0.1 0.1");
			e.addValue(e, ZCTX(_("GHOITEMS^Tinted")), "0.6 0.6 0.6");
			e.addValue(e, ZCTX(_("GHOITEMS^Normal")), "1 1 1");
			e.addValue(e, ZCTX(_("GHOITEMS^Blue")), "-1 -1 3");
			e.configureXonoticTextSliderValues(e);
			setDependentNOT(e, "cl_ghost_items", 0);

	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticHeaderLabel(_("Players")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "cl_forceplayermodels", _("Force player models to mine")));
	me.TR(me);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Force player colors to mine")));
		me.TD(me, 1, 1.8, e = makeXonoticMixedSlider_T("cl_forceplayercolors",
			_("Warning: if enabled in team games your team's color may be the same as the enemy team")));
			e.setValueSpace(e, e.valueSpace * 1.75);
			e.addText(e, _("Never"), 0);
			e.addText(e, _("Except in team games"), 1);
			e.addText(e, _("Only in Duel"), 3);
			e.addText(e, _("Only in team games"), 4);
			e.addText(e, _("In team games and Duel"), 5);
			e.addText(e, _("Always"), 2);
			e.configureXonoticMixedSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Body fading:")));
		me.TD(me, 1, 2, e = makeXonoticSlider(0, 2, 0.2, "cl_deathglow"));
			e.formatString = "S";
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Gibs:")));
			setDependent(e, "cl_gentle", 0, 0);
		me.TD(me, 1, 2, e = makeXonoticMixedSlider("cl_nogibs"));
			e.addText(e, ZCTX(_("GIBS^None")), 1);
			e.addText(e, ZCTX(_("GIBS^Few")), 0.75);
			e.addText(e, ZCTX(_("GIBS^Many")), 0.5);
			e.addText(e, ZCTX(_("GIBS^Lots")), 0);
			e.configureXonoticMixedSliderValues(e);
			setDependent(e, "cl_gentle", 0, 0);
}
