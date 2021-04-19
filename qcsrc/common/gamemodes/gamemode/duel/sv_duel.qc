#include "sv_duel.qh"

MUTATOR_HOOKFUNCTION(duel, GetPlayerLimit)
{
	M_ARGV(0, int) = 2; // duel is always 1v1!
}

MUTATOR_HOOKFUNCTION(duel, Scores_CountFragsRemaining)
{
	// announce remaining frags?
	return true;
}

MUTATOR_HOOKFUNCTION(duel, Scores_AnnounceLeads)
{
	// enable leads announcer
	return true;
}

MUTATOR_HOOKFUNCTION(duel, FilterItemDefinition)
{
	entity definition = M_ARGV(0, entity);

	if(definition.instanceOfPowerup)
	{
		return !autocvar_g_duel_with_powerups;
	}
}

MUTATOR_HOOKFUNCTION(duel, FragCenterMessage)
{
	// Use normal notifications in warmup
	if(warmup_stage) return false;
	
	entity attacker = M_ARGV(0, entity);
	entity targ = M_ARGV(1, entity);
	string tie_str;
	int kill_count_to_attacker = M_ARGV(3, int);
	int kill_count_to_target = M_ARGV(4, int);
	
	WinningConditionHelper(NULL);
	
	if(WinningConditionHelper_equality)
		tie_str = "^3Tied";
	else if(attacker == WinningConditionHelper_winner)
		tie_str = "^2Leads";
	else
		tie_str = "^1Trails";
	
	Send_Notification(
		NOTIF_ONE,
		attacker,
		MSG_CENTER,
		CENTER_DEATH_MURDER_DUEL,
		targ.netname,
		tie_str,
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
