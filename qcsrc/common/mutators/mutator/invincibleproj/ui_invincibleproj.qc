#include "ui_invincibleproj.qh"

entity makeXonoticMutatorInvincibleProjectilesTab()
{
	entity me;
	me = NEW(XonoticMutatorInvincibleProjectilesTab);
	me.configureDialog(me);
	return me;
}

void XonoticMutatorInvincibleProjectilesTab_fill(entity me)
{
	Mutators_main_checkbox(me);
}

METHOD(XonoticMutatorInvincibleProjectilesTab, describe, string(XonoticMutatorInvincibleProjectilesTab me))
{
	return _("Projectiles can't be destroyed. However, you can still explode Electro orbs with the Electro primary fire");
}
METHOD(XonoticMutatorInvincibleProjectilesTab, canEnable, bool(XonoticMutatorInvincibleProjectilesTab me, bool is_already_enabled))
{
	bool can_enable = !cvar("g_melee_only");
	if (is_already_enabled)
		return can_enable && cvar(me.message);
	return can_enable;
}
