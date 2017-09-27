
float autocvar_g_kick_teamkiller_rate;
float autocvar_g_kick_teamkiller_mintime;

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
	// don't use the players actual playtime if they just started playing
	// to avoid kicking players who only teamkilled by mistake just after joining
	float playtime_minutes = max((time - attacker.alivetime)/60.0, autocvar_g_kick_teamkiller_mintime);
	if (teamkills >= autocvar_g_kick_teamkiller_rate*playtime_minutes)
	{
		Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_QUIT_KICK_TEAMKILL, attacker.netname);
		dropclient(attacker);
	}
}
