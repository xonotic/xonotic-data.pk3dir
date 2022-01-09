#include "sv_kick_teamkiller.qh"

float autocvar_g_kick_teamkiller_rate;
float autocvar_g_kick_teamkiller_lower_limit;

REGISTER_MUTATOR(kick_teamkiller, (autocvar_g_kick_teamkiller_rate > 0));

MUTATOR_HOOKFUNCTION(kick_teamkiller, PlayerDies)
{
	if (!teamplay)
	{
		return;
	}
	if (warmup_stage)
	{
		return;
	}
	entity attacker = M_ARGV(1, entity);
	if (!IS_REAL_CLIENT(attacker))
	{
		return;
	}

	int teamkills = PlayerScore_Get(attacker, SP_TEAMKILLS);
	// use the players actual playtime
	float playtime = time - CS(attacker).startplaytime;
	// rate is in teamkills/minutes, playtime in seconds
	if (teamkills >= autocvar_g_kick_teamkiller_lower_limit &&
	    teamkills >= autocvar_g_kick_teamkiller_rate*playtime/60.0)
	{
		if (dropclient_schedule(attacker))
			Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_QUIT_KICK_TEAMKILL, attacker.netname);
	}
}
