#include "ui_cloaked.qh"

entity makeXonoticMutatorCloakedTab()
{
	entity me = NEW(XonoticMutatorCloakedTab);
	me.configureDialog(me);
	return me;
}

void XonoticMutatorCloakedTab_fill(entity me)
{
	Mutators_main_checkbox(me);
}

METHOD(XonoticMutatorCloakedTab, describe, string(XonoticMutatorCloakedTab me))
{
	return _("All players are almost invisible.");
}
METHOD(XonoticMutatorCloakedTab, canEnable, bool(XonoticMutatorCloakedTab me, bool is_already_enabled))
{
	bool can_enable = true;
	if (is_already_enabled)
		return can_enable && cvar(me.message);
	return can_enable;
}
