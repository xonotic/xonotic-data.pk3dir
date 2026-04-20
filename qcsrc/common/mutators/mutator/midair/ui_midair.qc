#include "ui_midair.qh"

#include <menu/xonotic/slider.qh>
#include <menu/xonotic/textlabel.qh>

entity makeXonoticMutatorMidAirTab()
{
	entity me = NEW(XonoticMutatorMidAirTab);
	me.configureDialog(me);
	return me;
}

void XonoticMutatorMidAirTab_fill(entity me)
{
	entity e;

	Mutators_main_checkbox(me);

	me.TR(me);
		me.TD(me, 1, 1.5, e = makeXonoticTextLabel(0, _("Invincibility time:")));
		me.TD(me, 1, 2.5, e = makeXonoticSlider_T(0, 1, 0.1, "g_midair_shieldtime",
			_("Invincibility time after leaving contact with ground")));
			e.formatString = "S";
			e.setValueSpace(e, e.valueSpace * 1.2);	
}

METHOD(XonoticMutatorMidAirTab, describe, string(XonoticMutatorMidAirTab me))
{
	return _("Makes it only possible to inflict damage on your enemy while they're airborne.");
}
METHOD(XonoticMutatorMidAirTab, canEnable, bool(XonoticMutatorMidAirTab me, bool is_already_enabled))
{
	bool can_enable = true;
	if (is_already_enabled)
		return can_enable && cvar(me.message);
	return can_enable;
}
