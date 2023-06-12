#include "sv_kick_teamkiller.qh"
#include <server/ipban.qh>

float autocvar_g_kick_teamkiller_rate;
float autocvar_g_kick_teamkiller_lower_limit;
int autocvar_g_kick_teamkiller_severity;
float autocvar_g_kick_teamkiller_bantime;

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

	float masksize = autocvar_g_ban_default_masksize;
	float bantime = autocvar_g_kick_teamkiller_bantime;

	int teamkills = PlayerScore_Get(attacker, SP_TEAMKILLS);
	// use the players actual playtime
	float playtime = time - CS(attacker).startplaytime;
	// rate is in teamkills/minutes, playtime in seconds
	if (teamkills >= autocvar_g_kick_teamkiller_lower_limit &&
		teamkills >= autocvar_g_kick_teamkiller_rate*playtime/60.0)
	{
		switch (autocvar_g_kick_teamkiller_severity)
		{
			case 1:
			{
				if (dropclient_schedule(attacker))
					Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_QUIT_KICK_TEAMKILL, attacker.netname);
				return;
			}
			case 2:
			{
				attacker.respawn_flags = RESPAWN_SILENT;
				Ban_KickBanClient(attacker, bantime, masksize, "Team Killing");
				Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_QUIT_KICK_TEAMKILL, attacker.netname);
				return;
			}
			default:
			{
				attacker.respawn_flags = RESPAWN_SILENT;
				string theid = "";

				if(!PlayerInIPList(attacker, autocvar_g_playban_list))
					theid = cons(theid, attacker.netaddress);
				if(!PlayerInIDList(attacker, autocvar_g_playban_list))
					theid = cons(theid, attacker.crypto_idfp);

				LOG_INFO(strcat("Play-banning player ", GetCallerName(attacker), " (", attacker.netaddress, ")."));
				PutObserverInServer(attacker, true, true);
				cvar_set("g_playban_list", cons(autocvar_g_playban_list, theid));

				Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_QUIT_PLAYBAN_TEAMKILL, attacker.netname);
				Send_Notification(NOTIF_ONE, attacker, MSG_CENTER, CENTER_QUIT_PLAYBAN_TEAMKILL);

				if (PlayerInList(attacker, autocvar_g_playban_list))
					TRANSMUTE(Observer, attacker);

				return;
			}
		}
	}
}
