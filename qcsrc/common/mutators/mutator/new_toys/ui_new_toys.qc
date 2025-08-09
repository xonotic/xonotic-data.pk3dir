#include "ui_new_toys.qh"

#include <menu/xonotic/radiobutton.qh>

entity makeXonoticMutatorNewToysTab()
{
	entity me = NEW(XonoticMutatorNewToysTab);
	me.configureDialog(me);
	return me;
}

void XonoticMutatorNewToysTab_fill(entity me)
{
	entity e;

	Mutators_main_checkbox(me);

	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticTextLabel(0, _("Replacement:")));
	me.TR(me);
		const string nta_tooltip = _("Automatically replace some normal weapons of the map with their corresponding additional weapons");
		me.TDempty(me, 0.2);
		me.TD(me, 1, (4 - 0.2) / 3, e = makeXonoticRadioButton_T(1, "g_new_toys_autoreplace", "0", _("Never"),    nta_tooltip));
		me.TD(me, 1, (4 - 0.2) / 3, e = makeXonoticRadioButton_T(1, "g_new_toys_autoreplace", "1", _("Always"),   nta_tooltip));
		me.TD(me, 1, (4 - 0.2) / 3, e = makeXonoticRadioButton_T(1, "g_new_toys_autoreplace", "2", _("Randomly"), nta_tooltip));
}

METHOD(XonoticMutatorNewToysTab, describe, string(XonoticMutatorNewToysTab me))
{
	return _("Allow maps to spawn additional weapons (new toys).");
}
METHOD(XonoticMutatorNewToysTab, canEnable, bool(XonoticMutatorNewToysTab me, bool is_already_enabled))
{
	bool can_enable = (!cvar("g_instagib") && !cvar("g_overkill") && !cvar("g_melee_only"));
	if (is_already_enabled)
		return can_enable && cvar(me.message);
	return can_enable;
}
