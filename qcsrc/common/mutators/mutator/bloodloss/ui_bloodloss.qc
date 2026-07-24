#include "ui_bloodloss.qh"

#include <menu/xonotic/checkbox_slider_invalid.qh>
#include <menu/xonotic/slider.qh>
#include <menu/xonotic/textlabel.qh>

entity makeXonoticMutatorBloodLossTab()
{
	entity me = NEW(XonoticMutatorBloodLossTab);
	me.configureDialog(me);
	return me;
}

void XonoticMutatorBloodLossTab_fill(entity me)
{
	entity e;
	entity s = makeXonoticSlider(10, 50, 1, me.message);

	me.TR(me);
		me.TDempty(me, 1.75);
		me.TD(me, 1, 2.25, e = makeXonoticSliderCheckBox(0, 1, s, _("Enable")));
			Mutators_add_SliderCheckBox(me, e);
	me.TR(me);
		me.TD(me, 1, 1.5, e = makeXonoticTextLabel(0, _("Bleed below health:")));
		me.TD(me, 1, 2.5, s);
}

METHOD(XonoticMutatorBloodLossTab, describe, string(XonoticMutatorBloodLossTab me))
{
	return _("Amount of health below which players start bleeding out (health rots and they can't jump).");
}
METHOD(XonoticMutatorBloodLossTab, canEnable, bool(XonoticMutatorBloodLossTab me, bool is_already_enabled))
{
	bool can_enable = true;
	if (is_already_enabled)
		return can_enable && cvar(me.message);
	return can_enable;
}
