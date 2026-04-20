#include "ui_rocketflying.qh"

#include <menu/xonotic/checkbox.qh>

entity makeXonoticMutatorRocketFlyingTab()
{
	entity me = NEW(XonoticMutatorRocketFlyingTab);
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

#include <common/weapons/weapon/devastator.qh>

METHOD(XonoticMutatorRocketFlyingTab, describe, string(XonoticMutatorRocketFlyingTab me))
{
	return sprintf(_("%s rockets can be detonated instantly (otherwise, there's a short delay). This allows players to fire and detonate a rocket while mid-air for a strong boost even while moving fast."), COLORED_NAME(WEP_DEVASTATOR));
}
METHOD(XonoticMutatorRocketFlyingTab, canEnable, bool(XonoticMutatorRocketFlyingTab me, bool is_already_enabled))
{
	bool can_enable = (!cvar("g_instagib") && !cvar("g_overkill") && !cvar("g_melee_only"));
	if (is_already_enabled)
		return can_enable && cvar(me.message);
	return can_enable;
}
