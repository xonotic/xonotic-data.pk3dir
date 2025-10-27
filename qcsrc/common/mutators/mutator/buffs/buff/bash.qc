#include "bash.qh"

#ifdef SVQC
vector buff_Bash_TargetCalculateForce(vector frag_force, entity frag_target, entity frag_attacker)
{
	if (frag_attacker != frag_target)
		frag_force = '0 0 0';
	return frag_force;
}
vector buff_Bash_AttackerCalculateForce(vector frag_force, entity frag_target, entity frag_attacker)
{
	if (frag_force)
	{
		if (frag_attacker == frag_target)
			frag_force *= autocvar_g_buffs_bash_force_self;
		else
			frag_force *= autocvar_g_buffs_bash_force;
	}
	return frag_force;
}
#endif // SVQC
#ifdef MENUQC
METHOD(BashBuff, describe, string(BashBuff this))
{
	TC(BashBuff, this);
	PAGE_TEXT_INIT();
	PAR(_("The %s buff increases the knockback force you deal, and makes you immune to knockback while the buff is active."), COLORED_NAME(this));
	PAR(_("It also slightly increases the knockback you deal to yourself."));
	return PAGE_TEXT;
}
#endif // MENUQC
