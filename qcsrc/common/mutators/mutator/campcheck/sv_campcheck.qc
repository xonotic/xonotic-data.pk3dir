#include "sv_campcheck.qh"

float autocvar_g_campcheck_damage;
float autocvar_g_campcheck_distance;
float autocvar_g_campcheck_interval;

REGISTER_MUTATOR(campcheck, cvar("g_campcheck"));

.float campcheck_nextcheck;
.float campcheck_traveled_distance;

MUTATOR_HOOKFUNCTION(campcheck, PlayerDies)
{
	entity frag_target = M_ARGV(2, entity);

	Kill_Notification(NOTIF_ONE, frag_target, MSG_CENTER, CPID_CAMPCHECK);
}

MUTATOR_HOOKFUNCTION(campcheck, Damage_Calculate)
{
	entity frag_attacker = M_ARGV(1, entity);
	entity frag_target = M_ARGV(2, entity);

	if(IS_PLAYER(frag_target))
	if(IS_PLAYER(frag_attacker))
	if(frag_attacker != frag_target)
	{
		frag_target.campcheck_traveled_distance = autocvar_g_campcheck_distance;
		frag_attacker.campcheck_traveled_distance = autocvar_g_campcheck_distance;
	}
}

MUTATOR_HOOKFUNCTION(campcheck, PlayerPreThink)
{
	entity player = M_ARGV(0, entity);

	if(!game_stopped)
	if(!warmup_stage) // don't consider it camping during warmup?
	if(time >= game_starttime)
	if(IS_PLAYER(player))
	if(IS_REAL_CLIENT(player)) // bots may camp, but that's no reason to constantly kill them
	if(!IS_DEAD(player))
	if(!forbidWeaponUse(player))
	if(!STAT(FROZEN, player))
	if(!PHYS_INPUT_BUTTON_CHAT(player))
	if(autocvar_g_campcheck_interval)
	{
		vector dist;

		// calculate player movement (in 2 dimensions only, so jumping on one spot doesn't count as movement)
		dist = player.prevorigin - player.origin;
		dist.z = 0;
		player.campcheck_traveled_distance += fabs(vlen(dist));

		if((autocvar_g_campaign && !campaign_bots_may_start) || (time < game_starttime) || (round_handler_IsActive() && !round_handler_IsRoundStarted()))
		{
			player.campcheck_nextcheck = time + autocvar_g_campcheck_interval * 2;
			player.campcheck_traveled_distance = 0;
		}

		if(time > player.campcheck_nextcheck)
		{
			if(player.campcheck_traveled_distance < autocvar_g_campcheck_distance)
			{
				Send_Notification(NOTIF_ONE, player, MSG_CENTER, CENTER_CAMPCHECK);
				if(player.vehicle)
					Damage(player.vehicle, NULL, NULL, autocvar_g_campcheck_damage * 2, DEATH_CAMP.m_id, player.vehicle.origin, '0 0 0');
				else
					Damage(player, NULL, NULL, bound(0, autocvar_g_campcheck_damage, player.health + player.armorvalue * autocvar_g_balance_armor_blockpercent + 5), DEATH_CAMP.m_id, player.origin, '0 0 0');
			}
			player.campcheck_nextcheck = time + autocvar_g_campcheck_interval;
			player.campcheck_traveled_distance = 0;
		}

		return;
	}

	player.campcheck_nextcheck = time + autocvar_g_campcheck_interval; // one of the above checks failed, so keep the timer up to date
}

MUTATOR_HOOKFUNCTION(campcheck, PlayerSpawn)
{
	entity player = M_ARGV(0, entity);

	player.campcheck_nextcheck = time + autocvar_g_campcheck_interval * 2;
	player.campcheck_traveled_distance = 0;
}

MUTATOR_HOOKFUNCTION(campcheck, BuildMutatorsString)
{
	M_ARGV(0, string) = strcat(M_ARGV(0, string), ":CampCheck");
}
