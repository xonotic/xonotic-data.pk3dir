#include "ui_pinata.qh"

entity makeXonoticMutatorPinataTab()
{
	entity me = NEW(XonoticMutatorPinataTab);
	me.configureDialog(me);
	return me;
}

void XonoticMutatorPinataTab_fill(entity me)
{
	Mutators_main_checkbox(me);
}

METHOD(XonoticMutatorPinataTab, describe, string(XonoticMutatorPinataTab me))
{
	return _("Players will drop all weapons they possessed when they are fragged.");
}
METHOD(XonoticMutatorPinataTab, canEnable, bool(XonoticMutatorPinataTab me, bool is_already_enabled))
{
	bool can_enable = (!cvar("g_instagib") && !cvar("g_overkill") && !cvar("g_nix") && !cvar("g_melee_only")
		&& (cvar_string("g_weaponarena") == "0" || cvar_string("g_weaponarena") == "off" || cvar_string("g_weaponarena") == ""));
	if (is_already_enabled)
		return can_enable && cvar(me.message);
	return can_enable;
}
