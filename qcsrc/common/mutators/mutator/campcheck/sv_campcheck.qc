#include "sv_campcheck.qh"

string autocvar_g_campcheck;
float autocvar_g_campcheck_damage;
float autocvar_g_campcheck_distance;
float autocvar_g_campcheck_interval;
bool autocvar_g_campcheck_typecheck;

REGISTER_MUTATOR(campcheck, expr_evaluate(autocvar_g_campcheck));

.float campcheck_nextcheck;
.float campcheck_traveled_distance;

.vector campcheck_prevorigin;

MUTATOR_HOOKFUNCTION(campcheck, PlayerDies)
{
	entity frag_target = M_ARGV(2, entity);

	Kill_Notification(NOTIF_ONE, frag_target, MSG_CENTER, CPID_CAMPCHECK);
}

MUTATOR_HOOKFUNCTION(campcheck, Damage_Calculate)
{
	entity frag_attacker = M_ARGV(1, entity);
	entity frag_target = M_ARGV(2, entity);

	if(frag_attacker != frag_target && IS_PLAYER(frag_target) && IS_PLAYER(frag_attacker))
	{
		frag_target.campcheck_traveled_distance = autocvar_g_campcheck_distance;
		frag_attacker.campcheck_traveled_distance = autocvar_g_campcheck_distance;
	}
}

MUTATOR_HOOKFUNCTION(campcheck, PlayerPreThink)
{
	entity player = M_ARGV(0, entity);
	bool checked = false;

	if(autocvar_g_campcheck_interval)
	if(!game_stopped && !warmup_stage && time >= game_starttime)
	if(IS_PLAYER(player) && !IS_DEAD(player) && !STAT(FROZEN, player))
	if(autocvar_g_campcheck_typecheck || !PHYS_INPUT_BUTTON_CHAT(player))
	if(IS_REAL_CLIENT(player)) // only apply to real clients (bots may "camp" due to missing waypoints in the map, but that's no reason to constantly kill them, clones can't move)
	if(!weaponLocked(player))
	{
		// calculate player movement (in 2 dimensions only, so jumping on one spot doesn't count as movement)
		vector dist = vec2(player.campcheck_prevorigin - player.origin);
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
					Damage(player.vehicle, NULL, NULL, autocvar_g_campcheck_damage * 2, DEATH_CAMP.m_id, DMG_NOWEP, player.vehicle.origin, '0 0 0');
				else
				{
					float max_dmg = GetResource(player, RES_HEALTH) + GetResource(player, RES_ARMOR) * autocvar_g_balance_armor_blockpercent + 5;
					Damage(player, NULL, NULL, bound(0, autocvar_g_campcheck_damage, max_dmg), DEATH_CAMP.m_id, DMG_NOWEP, player.origin, '0 0 0');
				}
			}
			player.campcheck_nextcheck = time + autocvar_g_campcheck_interval;
			player.campcheck_traveled_distance = 0;
		}

		checked = true;
	}

	if(!checked)
		player.campcheck_nextcheck = time + autocvar_g_campcheck_interval; // one of the above checks failed, so keep the timer up to date

	player.campcheck_prevorigin = player.origin;
}

MUTATOR_HOOKFUNCTION(campcheck, CopyBody)
{
	entity player = M_ARGV(0, entity);
	entity clone = M_ARGV(1, entity);

	clone.campcheck_prevorigin = player.campcheck_prevorigin;
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
