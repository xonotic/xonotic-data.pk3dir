#include "sv_bash.qh"

vector buff_Bash_TargetCalculateForce(vector frag_force, entity frag_target, entity frag_attacker)
{
	if(frag_attacker != frag_target)
		frag_force = '0 0 0';
	return frag_force;
}
vector buff_Bash_AttackerCalculateForce(vector frag_force, entity frag_target, entity frag_attacker)
{
	if(frag_force)
	{
		if(frag_attacker == frag_target)
			frag_force *= autocvar_g_buffs_bash_force_self;
		else
			frag_force *= autocvar_g_buffs_bash_force;
	}
	return frag_force;
}
