
float autocvar_g_kick_teamkiller_limit;

REGISTER_MUTATOR(kick_teamkiller, (autocvar_g_kick_teamkiller_limit > 0));

MUTATOR_HOOKFUNCTION(kick_teamkiller, PlayerDies)
{
	if (!teamplay)
		return;
	entity attacker = M_ARGV(1, entity);
	if (!IS_REAL_CLIENT(attacker))
	{
		return;
	}

	int teamkills = PlayerScore_Get(attacker, SP_TEAMKILLS);
	if (teamkills >= autocvar_g_kick_teamkiller_limit)
	{
		Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_QUIT_KICK_TEAMKILL, attacker.netname);
		dropclient(attacker);
	}
}
