#include "ui_damagetext.qh"

#include <menu/gamesettings.qh>
#include <menu/xonotic/slider.qh>
#include <menu/xonotic/mixedslider.qh>

void XonoticDamageTextSettings_showNotify(entity me)
{
	loadAllCvars(me);
}
entity makeXonoticDamageTextSettingsTab()
{
	entity me;
	me = NEW(XonoticDamageTextSettings);
	me.configureDialog(me);
	return me;
}

void XonoticDamageTextSettings_fill(entity me)
{
	entity e;

	me.gotoRC(me, 0, 1); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 3, e = makeXonoticHeaderLabel(_("Damage Text")));
	me.TR(me);
		me.TD(me, 1, 3, makeXonoticCheckBox(0, "cl_damagetext", _("Draw damage numbers")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "cl_damagetext_friendlyfire", _("Draw damage numbers for friendly fire")));
			setDependent(e, "cl_damagetext", 1, 1);

	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Font size minimum:")));
			setDependent(e, "cl_damagetext", 1, 1);
		me.TD(me, 1, 2, e = makeXonoticSlider(0, 50, 1, "cl_damagetext_size_min"));
			setDependent(e, "cl_damagetext", 1, 1);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Font size maximum:")));
			setDependent(e, "cl_damagetext", 1, 1);
		me.TD(me, 1, 2, e = makeXonoticSlider(0, 50, 1, "cl_damagetext_size_max"));
			setDependent(e, "cl_damagetext", 1, 1);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Color:")));
			setDependent(e, "cl_damagetext", 1, 1);
		me.TD(me, 2, 2, e = makeXonoticColorpickerString("cl_damagetext_color", "cl_damagetext_color"));
			setDependentAND(e, "cl_damagetext", 1, 1, "cl_damagetext_color_per_weapon", 0, 0);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.8, e = makeXonoticCheckBox(0, "cl_damagetext_color_per_weapon", _("Per weapon")));
			setDependent(e, "cl_damagetext", 1, 1);

	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Initial alpha:")));
			setDependent(e, "cl_damagetext", 1, 1);
		me.TD(me, 1, 2, e = makeXonoticSlider(0.5, 1, 0.05, "cl_damagetext_alpha_start"));
			setDependent(e, "cl_damagetext", 1, 1);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Fade time:")));
			setDependent(e, "cl_damagetext", 1, 1);
		me.TD(me, 1, 2, e = makeXonoticSlider(1, 5, 0.5, "cl_damagetext_alpha_lifetime"));
			setDependent(e, "cl_damagetext", 1, 1);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Accumulate:")));
			setDependent(e, "cl_damagetext", 1, 1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("If younger than:")));
			setDependent(e, "cl_damagetext", 1, 1);
		me.TD(me, 1, 1.8, e = makeXonoticMixedSlider("cl_damagetext_accumulate_lifetime"));
			e.addText(e, _("Never"), 0);
			e.addText(e, _("1s"), 1);
			e.addText(e, _("2s"), 2);
			e.addText(e, _("3s"), 3);
			e.addText(e, _("Always"), -1);
			e.configureXonoticMixedSliderValues(e);
			setDependent(e, "cl_damagetext", 1, 1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Or alpha greater than:")));
			setDependentAND(e, "cl_damagetext", 1, 1, "cl_damagetext_accumulate_lifetime", 0.00001, 999999);
		me.TD(me, 1, 1.8, e = makeXonoticSlider(0, 1, 0.05, "cl_damagetext_accumulate_alpha_rel"));
			setDependentAND(e, "cl_damagetext", 1, 1, "cl_damagetext_accumulate_lifetime", 0.00001, 999999);
}
