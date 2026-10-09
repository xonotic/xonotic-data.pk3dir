#include "dialog_settings_game_model.qh"

#include "checkbox.qh"
#include "mixedslider.qh"
#include "radiobutton.qh"
#include "slider.qh"
#include "textlabel.qh"
#include "textslider.qh"

void XonoticGameModelSettingsTab_showNotify(entity me)
{
	loadAllCvars(me);
}
entity makeXonoticGameModelSettingsTab()
{
	entity me = NEW(XonoticGameModelSettingsTab);
	me.configureDialog(me);
	return me;
}

void XonoticGameModelSettingsTab_fill(entity me)
{
	entity e;

	// Note that this is pretty terrible currently due to the lack of options for this tab...
	// There is really not many other decent places for these options, additionally
	// later I would like quite a few more options in this tab.

	me.gotoRC(me, 0, (me.columns - 3) * 0.5); me.setFirstColumn(me, me.currentColumn);
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
			e.addValue(e, ZCTX(_("GHOITEMS^Black")),  "-1 -1 -1");
			e.addValue(e, ZCTX(_("GHOITEMS^Dark")),   "0.1 0.1 0.1");
			e.addValue(e, ZCTX(_("GHOITEMS^Tinted")), "0.6 0.6 0.6");
			e.addValue(e, ZCTX(_("GHOITEMS^Normal")), "1 1 1");
			e.addValue(e, ZCTX(_("GHOITEMS^Blue")),   "-1 -1 3");
			e.configureXonoticTextSliderValues(e);
			setDependentNOT(e, "cl_ghost_items", 0);

	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticHeaderLabel(_("Players")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "cl_forceplayermodels", _("Force player models to mine")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticTextLabel(0, _("Force player colors to mine:")));
		string fpc_warning = _("Warning: if enabled in team games your team's color may be the same as the enemy team's");
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.8/2, e = makeXonoticRadioButton_T(1, "cl_forceplayercolors", "0", _("Never"), fpc_warning));
		me.TD(me, 1, 2.8/2, e = makeXonoticRadioButton_T(1, "cl_forceplayercolors", "2", _("Always"), fpc_warning));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.8/2, e = makeXonoticRadioButton_T(1, "cl_forceplayercolors", "4", _("Only in team games"), fpc_warning));
		me.TD(me, 1, 2.8/2, e = makeXonoticRadioButton_T(1, "cl_forceplayercolors", "1", _("Except in team games"), fpc_warning));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.8/2, e = makeXonoticRadioButton_T(1, "cl_forceplayercolors", "3", _("Only in Duel"), fpc_warning));
		me.TD(me, 1, 2.8/2, e = makeXonoticRadioButton_T(1, "cl_forceplayercolors", "5", _("In team games and Duel"), fpc_warning));
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Body fading:")));
		me.TD(me, 1, 2, e = makeXonoticSlider(0, 2, 0.2, "cl_deathglow"));
			e.formatString = "S";
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Gibs:")));
			setDependent(e, "cl_gentle", 0, 0);
		me.TD(me, 1, 2, e = makeXonoticMixedSlider("cl_nogibs"));
			e.addText(e, ZCTX(_("GIBS^None")), 1);
			e.addText(e, ZCTX(_("GIBS^Few")),  0.75);
			e.addText(e, ZCTX(_("GIBS^Many")), 0.5);
			e.addText(e, ZCTX(_("GIBS^Lots")), 0);
			e.configureXonoticMixedSliderValues(e);
			setDependent(e, "cl_gentle", 0, 0);
}
