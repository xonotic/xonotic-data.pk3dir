#include "vampire.qh"

#ifdef SVQC
MUTATOR_HOOKFUNCTION(buffs, PlayerDamage_SplitHealthArmor)
{
	// NOTE: vampire PlayerDamage_SplitHealthArmor code is similar
	entity frag_attacker = M_ARGV(1, entity);
	entity frag_target = M_ARGV(2, entity);
	if (!StatusEffects_active(BUFF_VAMPIRE, frag_attacker))
		return;
	float health_take = bound(0, M_ARGV(4, float), GetResource(frag_target, RES_HEALTH));

	if (!StatusEffects_active(STATUSEFFECT_SpawnShield, frag_target)
		&& frag_target != frag_attacker
		&& IS_PLAYER(frag_attacker) && !IS_DEAD(frag_target) && !STAT(FROZEN, frag_target))
	{
		GiveResource(frag_attacker, RES_HEALTH, autocvar_g_buffs_vampire_damage_steal * health_take);
	}
}
#endif // SVQC
#ifdef MENUQC
#include "vengeance.qh"

METHOD(VampireBuff, describe, string(VampireBuff this))
{
	TC(VampireBuff, this);
	PAGE_TEXT_INIT();
	PAR(_("The %s buff converts some of the damage you deal to enemies and monsters into health for yourself, until the buff expires."), COLORED_NAME(this));
	PAR(_("In some sense, this is the opposite of the %s buff."), COLORED_NAME(BUFF_VENGEANCE));
	return PAGE_TEXT;
}
#endif // MENUQC
