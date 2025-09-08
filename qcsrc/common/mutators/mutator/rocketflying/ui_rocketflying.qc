#include "ui_rocketflying.qh"

#include <menu/xonotic/checkbox.qh>

entity makeXonoticMutatorRocketFlyingTab()
{
	entity me;
	me = NEW(XonoticMutatorRocketFlyingTab);
	me.configureDialog(me);
	return me;
}

void XonoticMutatorRocketFlyingTab_fill(entity me)
{
	entity e;

	Mutators_main_checkbox(me);

	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticCheckBox(0, "g_rocket_flying_disabledelays", _("Disable projectile detonation delay")));
}

METHOD(XonoticMutatorRocketFlyingTab, describe, string(XonoticMutatorRocketFlyingTab me))
{
	return _("Devastator rockets can be detonated instantly (otherwise, there's a short delay). This allows players to fire and detonate a Devastator rocket while in the air for a strong mid-air boost even while moving fast");
}
METHOD(XonoticMutatorRocketFlyingTab, canEnable, bool(XonoticMutatorRocketFlyingTab me, bool is_already_enabled))
{
	bool can_enable = (!cvar("g_instagib") && !cvar("g_overkill") && !cvar("g_melee_only"));
	if (is_already_enabled)
		return can_enable && cvar(me.message);
	return can_enable;
}
