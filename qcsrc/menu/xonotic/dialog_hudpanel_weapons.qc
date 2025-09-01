#include "dialog_hudpanel_weapons.qh"

#include "checkbox.qh"
#include "textlabel.qh"
#include "mixedslider.qh"
#include "slider.qh"
#include "radiobutton.qh"
#include "colorpicker_string.qh"

void XonoticHUDWeaponsDialog_fill(entity me)
{
	entity e;
	string panelname = "weapons";
	float i;

	dialog_hudpanel_main_checkbox(me, panelname);

	dialog_hudpanel_main_settings(me, panelname);

	me.TR(me);
		me.TD(me, 1, 1.4, e = makeXonoticTextLabel(0, _("Fade out after:")));
			me.TD(me, 1, 2.6, e = makeXonoticMixedSlider(strzone(strcat("hud_panel_", panelname, "_timeout"))));
				e.formatString = "s";
				e.setValueSpace(e, e.valueSpace * 1.2);
				e.addText(e, _("Never"), 0);
				e.addRange(e, 1, 10, 1);
				e.configureXonoticMixedSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 1.4, e = makeXonoticTextLabel(0, _("Fade effect:")));
		setDependentNOT(e, strzone(strcat("hud_panel_", panelname, "_timeout")), 0);
			me.TD(me, 1, 2.6, e = makeXonoticMixedSlider(strzone(strcat("hud_panel_", panelname, "_timeout_effect"))));
				e.addText(e, ZCTX(_("EF^None")), 0);
				e.addText(e, _("Opacity"),       1);
				e.addText(e, _("Slide"),         2);
				e.addText(e, ZCTX(_("EF^Both")), 3);
				e.configureXonoticMixedSliderValues(e);
				setDependentNOT(e, strzone(strcat("hud_panel_", panelname, "_timeout")), 0);

	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticCheckBox(0, "hud_panel_weapons_onlyowned", _("Show only owned weapons")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.4, e = makeXonoticTextLabel(0, _("Noncurrent opacity:")));
			setDependent(e, "hud_panel_weapons_onlyowned", 0, 1);
		me.TD(me, 1, 2.4, e = makeXonoticSlider(0.1, 1, 0.1, "hud_panel_weapons_noncurrent_alpha"));
			e.formatString = "%";
			setDependent(e, "hud_panel_weapons_onlyowned", 0, 1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.4, e = makeXonoticTextLabel(0, _("Noncurrent scale:")));
			setDependentNOT(e, "hud_panel_weapons_noncurrent_alpha", 0);
			setDependentAND(e, "hud_panel_weapons_onlyowned", 0, 1);
		me.TD(me, 1, 2.4, e = makeXonoticSlider(0.1, 1, 0.1, "hud_panel_weapons_noncurrent_scale"));
			e.formatString = "%";
			setDependentNOT(e, "hud_panel_weapons_noncurrent_alpha", 0);
			setDependentAND(e, "hud_panel_weapons_onlyowned", 0, 1);

	me.TR(me);
 		me.TD(me, 1, 1.4, e = makeXonoticCheckBox(0, "hud_panel_weapons_label", _("Show label:")));
			me.TD(me, 1, 2.6/3, e = makeXonoticRadioButton(2, "hud_panel_weapons_label", "1", _("Number")));
				setDependent(e, "hud_panel_weapons_label", 1, 3);
			me.TD(me, 1, 2.6/3, e = makeXonoticRadioButton(2, "hud_panel_weapons_label", "2", _("Bind")));
				setDependent(e, "hud_panel_weapons_label", 1, 3);
			me.TD(me, 1, 2.6/3, e = makeXonoticRadioButton(2, "hud_panel_weapons_label", "3", _("Name")));
				setDependent(e, "hud_panel_weapons_label", 1, 3);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Scale:")));
			setDependent(e, "hud_panel_weapons_label", 1, 3);
		me.TD(me, 1, 2.6, e = makeXonoticSlider(0.1, 1, 0.05, "hud_panel_weapons_label_scale"));
			e.formatString = _("%sx");
			setDependent(e, "hud_panel_weapons_label", 1, 3);

	me.TR(me);
		me.TD(me, 1, 2, e = makeXonoticCheckBox(0, "hud_panel_weapons_ammo", _("Show Ammo")));
		me.TD(me, 1, 2, e = makeXonoticCheckBox(0, "hud_panel_weapons_accuracy", _("Show Accuracy")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.4, e = makeXonoticTextLabel(0, _("Ammo bar opacity:")));
			setDependent(e, "hud_panel_weapons_ammo", 1, 1);
		me.TD(me, 1, 2.4, e = makeXonoticSlider(0.1, 1, 0.1, "hud_panel_weapons_ammo_alpha"));
			e.formatString = "%";
			setDependent(e, "hud_panel_weapons_ammo", 1, 1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Ammo bar color:")));
			setDependentNOT(e, "hud_panel_weapons_ammo_alpha", 0);
			setDependentAND(e, "hud_panel_weapons_ammo", 1, 1);
		me.TD(me, 2, 2.4, e = makeXonoticColorpickerString("hud_panel_weapons_ammo_color", "hud_panel_weapons_ammo_color"));
			setDependentNOT(e, "hud_panel_weapons_ammo_alpha", 0);
			setDependentAND(e, "hud_panel_weapons_ammo", 1, 1);
		me.TR(me);
}
