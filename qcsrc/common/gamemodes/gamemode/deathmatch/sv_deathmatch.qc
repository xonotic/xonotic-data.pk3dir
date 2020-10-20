#include "sv_deathmatch.qh"

MUTATOR_HOOKFUNCTION(dm, Scores_CountFragsRemaining)
{
	// announce remaining frags
	return true;
}

MUTATOR_HOOKFUNCTION(dm, FragCenterMessage)
{
	// Use normal notifications in warmup
	if(warmup_stage) return false;
	
	entity attacker = M_ARGV(0, entity);
	entity targ = M_ARGV(1, entity);
	//float frag_deathtype = M_ARGV(2, float);
	int kill_count_to_attacker = M_ARGV(3, int);
	int kill_count_to_target = M_ARGV(4, int);
	
	Send_Notification(
		NOTIF_ONE,
		attacker,
		MSG_CENTER,
		CENTER_DEATH_MURDER_DM,
		targ.netname,
		kill_count_to_attacker,
		GameRules_scoring_add(attacker, SCORE, 0)
	);
	Send_Notification(
		NOTIF_ONE,
		targ,
		MSG_CHOICE,
		CHOICE_FRAGGED,
		attacker.netname,
		kill_count_to_target,
		GetResource(attacker, RES_HEALTH),
		GetResource(attacker, RES_ARMOR),
		(IS_BOT_CLIENT(attacker) ? -1 : CS(attacker).ping)
	);
	
	return true;
}