#include "ui_invincibleproj.qh"

entity makeXonoticMutatorInvincibleProjectilesTab()
{
	entity me = NEW(XonoticMutatorInvincibleProjectilesTab);
	me.configureDialog(me);
	return me;
}

void XonoticMutatorInvincibleProjectilesTab_fill(entity me)
{
	Mutators_main_checkbox(me);
}

#include <common/weapons/weapon/electro.qh>

METHOD(XonoticMutatorInvincibleProjectilesTab, describe, string(XonoticMutatorInvincibleProjectilesTab me))
{
	return sprintf(_("Projectiles can't be destroyed. However, you can still explode %s orbs with the %s primary fire."), COLORED_NAME(WEP_ELECTRO), COLORED_NAME(WEP_ELECTRO));
}
METHOD(XonoticMutatorInvincibleProjectilesTab, canEnable, bool(XonoticMutatorInvincibleProjectilesTab me, bool is_already_enabled))
{
	bool can_enable = !cvar("g_melee_only");
	if (is_already_enabled)
		return can_enable && cvar(me.message);
	return can_enable;
}
