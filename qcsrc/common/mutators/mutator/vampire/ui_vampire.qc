#include "ui_vampire.qh"

#include <menu/xonotic/checkbox.qh>
#include <menu/xonotic/slider.qh>
#include <menu/xonotic/textlabel.qh>

entity makeXonoticMutatorVampireTab()
{
	entity me = NEW(XonoticMutatorVampireTab);
	me.configureDialog(me);
	return me;
}

void XonoticMutatorVampireTab_fill(entity me)
{
	entity e;

	Mutators_main_checkbox(me);

	me.TR(me);
		me.TD(me, 1, 1.5, e = makeXonoticTextLabel(0, _("Factor:")));
		me.TD(me, 1, 2.5, e = makeXonoticSlider_T(0.05, 1, 0.05, "g_vampire_factor",
			_("Fraction of the damage dealt to be stolen as health")));
			e.formatString = _("%sx");
	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticCheckBox(0, "g_vampire_use_total_damage", _("Consider both health and armor")));
}

METHOD(XonoticMutatorVampireTab, describe, string(XonoticMutatorVampireTab me))
{
	return _("All damage dealt to your enemies is added to your own health.");
}
METHOD(XonoticMutatorVampireTab, canEnable, bool(XonoticMutatorVampireTab me, bool is_already_enabled))
{
	bool can_enable = !cvar("g_instagib");
	if (is_already_enabled)
		return can_enable && cvar(me.message);
	return can_enable;
}
