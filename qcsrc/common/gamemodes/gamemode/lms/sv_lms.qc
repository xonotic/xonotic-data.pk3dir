#include "sv_lms.qh"

#include <common/mutators/mutator/instagib/items.qh>
#include <server/campaign.qh>
#include <server/command/_mod.qh>
#include <server/world.qh>
#include <server/items/items.qh>

int autocvar_g_lms_extra_lives;
float autocvar_g_lms_forfeit_min_match_time;
bool autocvar_g_lms_join_anytime;
int autocvar_g_lms_last_join;
bool autocvar_g_lms_items;
bool autocvar_g_lms_regenerate;
int autocvar_g_lms_leader_lives_diff = 2;
float autocvar_g_lms_leader_minpercent = 0.5;
float autocvar_g_lms_leader_wp_interval = 25;
float autocvar_g_lms_leader_wp_interval_jitter = 10;
float autocvar_g_lms_leader_wp_time = 5;
float autocvar_g_lms_dynamic_respawn_delay = 1;
float autocvar_g_lms_dynamic_respawn_delay_base = 2;
float autocvar_g_lms_dynamic_respawn_delay_increase = 3;
float autocvar_g_lms_dynamic_respawn_delay_max = 20;
bool autocvar_g_lms_dynamic_vampire = 1;
float autocvar_g_lms_dynamic_vampire_factor_base = 0.1;
float autocvar_g_lms_dynamic_vampire_factor_increase = 0.1;
float autocvar_g_lms_dynamic_vampire_factor_max = 0.5;
int autocvar_g_lms_dynamic_vampire_min_lives_diff = 2;

.float lms_leader;
int lms_leaders;
float lms_visible_leaders_time;
bool lms_visible_leaders = true; // triggers lms_visible_leaders_time update in the first frame
bool lms_visible_leaders_prev;
bool autocvar_g_lms_rot;

// main functions
int LMS_NewPlayerLives()
{
	int fl = floor(autocvar_fraglimit);
	if(fl == 0 || fl > 999)
		fl = 999;

	// first player has left the game for dying too much? Nobody else can get in.
	if(lms_lowest_lives < 1)
		return 0;

	if(!autocvar_g_lms_join_anytime)
		if(lms_lowest_lives < fl - max(0, floor(autocvar_g_lms_last_join)))
			return 0;

	return bound(1, lms_lowest_lives, fl);
}

void ClearWinners();

// LMS winning condition: game terminates if and only if there's at most one
// one player who's living lives. Top two scores being equal cancels the time
// limit.
int WinningCondition_LMS()
{
	if (warmup_stage || time <= game_starttime)
		return WINNING_NO;

	entity first_player = NULL;
	int totalplayers = 0;
	int totalplayed = 0;
	FOREACH_CLIENT(true, {
		if (IS_PLAYER(it) && it.frags == FRAGS_PLAYER)
		{
			if (!totalplayers)
				first_player = it;
			++totalplayers;
		}
		else if (GameRules_scoring_add(it, LMS_RANK, 0))
			++totalplayed;
	});

	if (totalplayers)
	{
		if (totalplayers > 1)
		{
			// two or more active players - continue with the game

			if (autocvar_g_campaign && campaign_bots_may_start)
			{
				FOREACH_CLIENT(IS_REAL_CLIENT(it), {
					float pl_lives = GameRules_scoring_add(it, LMS_LIVES, 0);
					if (!pl_lives)
						return WINNING_YES; // human player lost, game over
					break;
				});
			}
		}
		else
		{
			// exactly one player?

			ClearWinners();

			if (LMS_NewPlayerLives())
			{
				if (totalplayed && game_starttime > 0 && time > game_starttime + autocvar_g_lms_forfeit_min_match_time) // give players time to join
				{
					GameRules_scoring_add(first_player, LMS_RANK, 1);
					first_player.winning = 1;
					return WINNING_YES;
				}
				// game still running (that is, nobody got removed from the game by a frag yet)? then continue
				return WINNING_NO;
			}
			else
			{
				// a winner!
				// and assign them their first place
				GameRules_scoring_add(first_player, LMS_RANK, 1);
				first_player.winning = 1;
				return WINNING_YES;
			}
		}
	}
	else
	{
		// nobody is playing at all...
		if (LMS_NewPlayerLives())
		{
			if (totalplayed && game_starttime > 0 && time > game_starttime + autocvar_g_lms_forfeit_min_match_time) // give players time to join
			{
				ClearWinners();
				return WINNING_YES;
			}
			// wait for players...
		}
		else
		{
			// SNAFU (maybe a draw game?)
			ClearWinners();
			LOG_TRACE("No players, ending game.");
			return WINNING_YES;
		}
	}

	// When we get here, we have at least two players who are actually LIVING,
	// now check if the top two players have equal score.
	WinningConditionHelper(NULL);

	ClearWinners();
	if(WinningConditionHelper_winner)
		WinningConditionHelper_winner.winning = true;
	if(WinningConditionHelper_topscore == WinningConditionHelper_secondscore)
		return WINNING_NEVER;

	// Top two have different scores? Way to go for our beloved TIMELIMIT!
	return WINNING_NO;
}

// runs on waypoints which are attached to leaders, updates once per frame
bool lms_waypointsprite_visible_for_player(entity this, entity player, entity view)
{
	if(view.lms_leader)
		if(IS_SPEC(player))
			return false; // we don't want spectators of leaders to see the attached waypoint on the top of their screen

	if (!lms_visible_leaders)
		return false;

	return true;
}

int lms_leaders_lives_diff;
void lms_UpdateLeaders()
{
	int max_lives = 0;
	int pl_cnt = 0;
	FOREACH_CLIENT(IS_PLAYER(it) && it.frags != FRAGS_PLAYER_OUT_OF_GAME, {
		int lives = GameRules_scoring_add(it, LMS_LIVES, 0);
		if (lives > max_lives)
			max_lives = lives;
		pl_cnt++;
	});

	int second_max_lives = 0;
	int pl_cnt_with_max_lives = 0;
	FOREACH_CLIENT(IS_PLAYER(it) && it.frags != FRAGS_PLAYER_OUT_OF_GAME, {
		int lives = GameRules_scoring_add(it, LMS_LIVES, 0);
		if (lives == max_lives)
			pl_cnt_with_max_lives++;
		else if (lives > second_max_lives)
			second_max_lives = lives;
	});

	lms_leaders_lives_diff = max_lives - second_max_lives;

	int lives_diff = autocvar_g_lms_leader_lives_diff;
	if (lms_leaders_lives_diff >= lives_diff && pl_cnt_with_max_lives <= pl_cnt * autocvar_g_lms_leader_minpercent)
		FOREACH_CLIENT(IS_PLAYER(it) && it.frags != FRAGS_PLAYER_OUT_OF_GAME, {
			int lives = GameRules_scoring_add(it, LMS_LIVES, 0);
			if (lives == max_lives)
			{
				if (!it.lms_leader)
					it.lms_leader = true;
			}
			else
			{
				it.lms_leader = false;
			}
		});
	else
		FOREACH_CLIENT(IS_PLAYER(it) && it.frags != FRAGS_PLAYER_OUT_OF_GAME, {
			if (it.waypointsprite_attachedforcarrier)
				WaypointSprite_Kill(it.waypointsprite_attachedforcarrier);
			it.lms_leader = false;
		});
}

// mutator hooks
MUTATOR_HOOKFUNCTION(lms, reset_map_global)
{
	lms_lowest_lives = 999;
}

MUTATOR_HOOKFUNCTION(lms, reset_map_players)
{
	FOREACH_CLIENT(true, {
		if (it.frags == FRAGS_PLAYER_OUT_OF_GAME)
			it.frags = FRAGS_PLAYER;

		CS(it).killcount = 0;
		INGAME_STATUS_CLEAR(it);
		it.lms_spectate = false;
		GameRules_scoring_add(it, LMS_RANK, -GameRules_scoring_add(it, LMS_RANK, 0));
		GameRules_scoring_add(it, LMS_LIVES, -GameRules_scoring_add(it, LMS_LIVES, 0));

		if (it.frags != FRAGS_PLAYER)
			continue;

		TRANSMUTE(Player, it);
		PutClientInServer(it);
		it.lms_leader = false;
		if (it.waypointsprite_attachedforcarrier)
			WaypointSprite_Kill(it.waypointsprite_attachedforcarrier);
	});
}

// FIXME add support for sv_ready_restart_after_countdown
// that is find a way to respawn/reset players IN GAME without setting lives to 0
MUTATOR_HOOKFUNCTION(lms, ReadLevelCvars)
{
	// incompatible
	sv_ready_restart_after_countdown = 0;
}

// returns true if player is added to the game
bool lms_AddPlayer(entity player)
{
	if (!INGAME(player))
	{
		int lives = GameRules_scoring_add(player, LMS_LIVES, LMS_NewPlayerLives());
		if(lives <= 0)
			return false;
		if (time < game_starttime)
			INGAME_STATUS_SET(player, INGAME_STATUS_JOINED);
		else
			INGAME_STATUS_SET(player, INGAME_STATUS_JOINING); // this is just to delay setting health and armor that can't be done here
	}
	if (warmup_stage || time <= game_starttime)
	{
		player.lms_spectate = false;
		GameRules_scoring_add(player, LMS_RANK, -GameRules_scoring_add(player, LMS_RANK, 0));
		int lives = GameRules_scoring_add(player, LMS_LIVES, 0);
		if(lives <= 0)
			GameRules_scoring_add(player, LMS_LIVES, LMS_NewPlayerLives());
	}
	else
	{
		if(GameRules_scoring_add(player, LMS_LIVES, 0) <= 0)
		{
			Send_Notification(NOTIF_ONE, player, MSG_CENTER, CENTER_LMS_NOLIVES);
			return false;
		}
	}
	return true;
}

MUTATOR_HOOKFUNCTION(lms, PutClientInServer)
{
	entity player = M_ARGV(0, entity);
	if (!warmup_stage && (IS_BOT_CLIENT(player) || CS(player).jointime != time))
	{
		if (GameRules_scoring_add(player, LMS_RANK, 0) || !lms_AddPlayer(player))
			TRANSMUTE(Observer, player);
	}
}

int last_forfeiter_lives;
float last_forfeiter_health;
float last_forfeiter_armorvalue;
MUTATOR_HOOKFUNCTION(lms, PlayerSpawn)
{
	entity player = M_ARGV(0, entity);

	if (warmup_stage || time < game_starttime)
		return true;

	if (INGAME_JOINING(player))
	{
		// spawn player with the same amount of health / armor
		// as the least healthy player with the least number of lives
		int pl_lives = GameRules_scoring_add(player, LMS_LIVES, 0);
		float min_health = start_health;
		float min_armorvalue = start_armorvalue;
		if (last_forfeiter_lives == pl_lives)
		{
			min_health = last_forfeiter_health;
			min_armorvalue = last_forfeiter_armorvalue;
		}
		FOREACH_CLIENT(it != player && IS_PLAYER(it) && !IS_DEAD(it) && GameRules_scoring_add(it, LMS_LIVES, 0) == pl_lives, {
			if (GetResource(it, RES_HEALTH) < min_health)
				min_health = GetResource(it, RES_HEALTH);
			if (GetResource(it, RES_ARMOR) < min_armorvalue)
				min_armorvalue = GetResource(it, RES_ARMOR);
		});
		if (min_health != start_health)
			SetResource(player, RES_HEALTH, max(1, min_health));
		if (min_armorvalue != start_armorvalue)
			SetResource(player, RES_ARMOR, min_armorvalue);
		INGAME_STATUS_SET(player, INGAME_STATUS_JOINED);
	}
}

MUTATOR_HOOKFUNCTION(lms, ForbidSpawn)
{
	entity player = M_ARGV(0, entity);

	if (warmup_stage || lms_AddPlayer(player))
		return false;

	return true;
}

void lms_RemovePlayer(entity player)
{
	if (warmup_stage || time < game_starttime)
		return;

	float player_rank = GameRules_scoring_add(player, LMS_RANK, 0);
	if (!player_rank)
	{
		if (!player.lms_spectate)
		{
			player.frags = FRAGS_PLAYER_OUT_OF_GAME;
			int pl_cnt = 0;
			FOREACH_CLIENT(IS_PLAYER(it) && it.frags == FRAGS_PLAYER, {
				pl_cnt++;
			});
			GameRules_scoring_add(player, LMS_RANK, pl_cnt + 1);
		}
		else if (INGAME(player))
		{
			FOREACH_CLIENT(it != player, {
				// update rank of other players
				if (it.frags == FRAGS_PLAYER_OUT_OF_GAME)
					GameRules_scoring_add(it, LMS_RANK, -1);
			});
			int rank = GameRules_scoring_add(player, LMS_RANK, 0);
			GameRules_scoring_add(player, LMS_RANK, -rank);
			if(!warmup_stage)
			{
				int pl_lives = GameRules_scoring_add(player, LMS_LIVES, 0);
				float pl_health = IS_DEAD(player) ? start_health : GetResource(player, RES_HEALTH);
				float pl_armor = IS_DEAD(player) ? start_armorvalue : GetResource(player, RES_ARMOR);
				if (!last_forfeiter_lives || pl_lives < last_forfeiter_lives)
				{
					last_forfeiter_lives = pl_lives;
					last_forfeiter_health = pl_health;
					last_forfeiter_armorvalue = pl_armor;
				}
				else if (pl_lives == last_forfeiter_lives)
				{
					// these values actually can belong to a different forfeiter
					last_forfeiter_health = min(last_forfeiter_health, pl_health);
					last_forfeiter_armorvalue = min(last_forfeiter_armorvalue, pl_armor);
				}
				GameRules_scoring_add(player, LMS_LIVES, -pl_lives);
			}
			player.frags = FRAGS_SPECTATOR;
			TRANSMUTE(Observer, player);
			INGAME_STATUS_CLEAR(player);
			player.lms_spectate = false;
			CS(player).killcount = FRAGS_SPECTATOR;
		}
		if (autocvar_g_lms_leader_lives_diff > 0)
			lms_UpdateLeaders();
	}

	if (CS(player).killcount != FRAGS_SPECTATOR)
	{
		if (GameRules_scoring_add(player, LMS_RANK, 0) > 0)
			Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_LMS_NOLIVES, player.netname);
	}
}

MUTATOR_HOOKFUNCTION(lms, ClientDisconnect)
{
	entity player = M_ARGV(0, entity);

	player.lms_spectate = true;

	lms_RemovePlayer(player);
	INGAME_STATUS_CLEAR(player);
}

MUTATOR_HOOKFUNCTION(lms, MakePlayerObserver)
{
	entity player = M_ARGV(0, entity);
	bool is_forced = M_ARGV(1, bool);

	if (!IS_PLAYER(player))
		return true;

	if (warmup_stage || time <= game_starttime)
	{
		GameRules_scoring_add(player, LMS_LIVES, -GameRules_scoring_add(player, LMS_LIVES, 0));
		player.frags = FRAGS_SPECTATOR;
		TRANSMUTE(Observer, player);
		INGAME_STATUS_CLEAR(player);
	}
	else
	{
		if (is_forced || player.killindicator_teamchange == -2) // player is forced or wants to spectate
			player.lms_spectate = true;
		if (!GameRules_scoring_add(player, LMS_RANK, 0))
			lms_RemovePlayer(player);
	}
	return true;  // prevent team reset
}

MUTATOR_HOOKFUNCTION(lms, ClientConnect)
{
	entity player = M_ARGV(0, entity);
	player.frags = FRAGS_SPECTATOR;
}

MUTATOR_HOOKFUNCTION(lms, PlayerPreThink)
{
	entity player = M_ARGV(0, entity);

	// recycled REDALIVE and BLUEALIVE to avoid adding a dedicated stat
	STAT(REDALIVE, player) = lms_leaders;
	STAT(BLUEALIVE, player) = lms_leaders_lives_diff;

	if(player.deadflag == DEAD_DYING)
		player.deadflag = DEAD_RESPAWNING;
}

MUTATOR_HOOKFUNCTION(lms, SV_StartFrame)
{
	if (intermission_running)
		return;

	lms_leaders = 0;
	FOREACH_CLIENT(true, {
		if (IS_PLAYER(it) && it.frags != FRAGS_PLAYER_OUT_OF_GAME && it.lms_leader)
			lms_leaders++;
	});

	float leader_time = autocvar_g_lms_leader_wp_time;
	float leader_interval = leader_time + autocvar_g_lms_leader_wp_interval;
	lms_visible_leaders_prev = lms_visible_leaders;
	lms_visible_leaders = (lms_leaders && time > lms_visible_leaders_time && time < lms_visible_leaders_time + leader_time);
	if (!lms_leaders || (lms_visible_leaders_prev && !lms_visible_leaders))
		lms_visible_leaders_time = time + leader_interval + random() * autocvar_g_lms_leader_wp_interval_jitter;

	FOREACH_CLIENT(true, {
		STAT(OBJECTIVE_STATUS, it) = lms_visible_leaders;
		if (IS_PLAYER(it) && it.frags != FRAGS_PLAYER_OUT_OF_GAME)
		{
			if (it.lms_leader)
			{
				if (!it.waypointsprite_attachedforcarrier)
				{
					WaypointSprite_AttachCarrier(WP_LmsLeader, it, RADARICON_FLAGCARRIER);
					it.waypointsprite_attachedforcarrier.waypointsprite_visible_for_player = lms_waypointsprite_visible_for_player;
					WaypointSprite_UpdateRule(it.waypointsprite_attachedforcarrier, 0, SPRITERULE_DEFAULT);
					vector pl_color = colormapPaletteColor(it.clientcolors & 0x0F, false);
					WaypointSprite_UpdateTeamRadar(it.waypointsprite_attachedforcarrier, RADARICON_FLAGCARRIER, pl_color);
					WaypointSprite_Ping(it.waypointsprite_attachedforcarrier);
				}
				if (!lms_visible_leaders_prev && lms_visible_leaders && IS_REAL_CLIENT(it))
					Send_Notification(NOTIF_ONE, it, MSG_CENTER, CENTER_LMS_VISIBLE_LEADER);
			}
			else // if (!it.lms_leader)
			{
				if (IS_PLAYER(it) && it.frags != FRAGS_PLAYER_OUT_OF_GAME)
				{
					if (!lms_visible_leaders_prev && lms_visible_leaders && IS_REAL_CLIENT(it))
						Send_Notification(NOTIF_ONE, it, MSG_CENTER, CENTER_LMS_VISIBLE_OTHER);
				}
				if (it.waypointsprite_attachedforcarrier)
					WaypointSprite_Kill(it.waypointsprite_attachedforcarrier);
			}
		}
	});
}

MUTATOR_HOOKFUNCTION(lms, PlayerRegen)
{
	if(!autocvar_g_lms_regenerate)
		M_ARGV(2, float) = 0;
	if(!autocvar_g_lms_rot)
		M_ARGV(3, float) = 0;
	return (!autocvar_g_lms_regenerate && !autocvar_g_lms_rot);
}

MUTATOR_HOOKFUNCTION(lms, PlayerPowerups)
{
	entity player = M_ARGV(0, entity);
	if (player.waypointsprite_attachedforcarrier)
		player.effects |= (EF_ADDITIVE | EF_FULLBRIGHT);
	else
		player.effects &= ~(EF_ADDITIVE | EF_FULLBRIGHT);
}

MUTATOR_HOOKFUNCTION(lms, ForbidThrowCurrentWeapon)
{
	// forbode!
	return true;
}

MUTATOR_HOOKFUNCTION(lms, Damage_Calculate)
{
	if (!autocvar_g_lms_dynamic_vampire)
		return;

	entity frag_attacker = M_ARGV(1, entity);
	entity frag_target = M_ARGV(2, entity);
	float frag_damage = M_ARGV(4, float);

	if (IS_PLAYER(frag_attacker) && !IS_DEAD(frag_attacker)
		&& IS_PLAYER(frag_target) && !IS_DEAD(frag_target) && frag_attacker != frag_target)
	{
		float vampire_factor = 0;

		int frag_attacker_lives = GameRules_scoring_add(frag_attacker, LMS_LIVES, 0);
		int frag_target_lives = GameRules_scoring_add(frag_target, LMS_LIVES, 0);
		int diff = frag_target_lives - frag_attacker_lives - autocvar_g_lms_dynamic_vampire_min_lives_diff;

		if (diff >= 0)
			vampire_factor = autocvar_g_lms_dynamic_vampire_factor_base + diff * autocvar_g_lms_dynamic_vampire_factor_increase;
		if (vampire_factor > 0)
		{
			vampire_factor = min(vampire_factor, autocvar_g_lms_dynamic_vampire_factor_max);
			SetResourceExplicit(frag_attacker, RES_HEALTH,
				min(GetResource(frag_attacker, RES_HEALTH) + frag_damage * vampire_factor, start_health));
		}
	}
}

MUTATOR_HOOKFUNCTION(lms, PlayerDied)
{
	if (!warmup_stage && autocvar_g_lms_leader_lives_diff > 0)
		lms_UpdateLeaders();
}

MUTATOR_HOOKFUNCTION(lms, CalculateRespawnTime)
{
	entity player = M_ARGV(0, entity);
	player.respawn_flags |= RESPAWN_FORCE;

	int pl_lives = GameRules_scoring_add(player, LMS_LIVES, 0);
	if (pl_lives <= 0)
	{
		player.respawn_flags = RESPAWN_SILENT;
		// prevent unwanted sudden rejoin as spectator and movement of spectator camera
		player.respawn_time = time + 2;
		return true;
	}

	if (autocvar_g_lms_dynamic_respawn_delay <= 0)
		return false;

	int max_lives = 0;
	int pl_cnt = 0;
	FOREACH_CLIENT(it != player && IS_PLAYER(it) && it.frags != FRAGS_PLAYER_OUT_OF_GAME, {
		int lives = GameRules_scoring_add(it, LMS_LIVES, 0);
		if (lives > max_lives)
			max_lives = lives;
		pl_cnt++;
	});

	// min delay with only 2 players
	if (pl_cnt == 1) // player wasn't counted
		max_lives = 0;

	float dlay = autocvar_g_lms_dynamic_respawn_delay_base +
		autocvar_g_lms_dynamic_respawn_delay_increase * max(0, max_lives - pl_lives);
	player.respawn_time = time + min(autocvar_g_lms_dynamic_respawn_delay_max, dlay);
	return true;
}

MUTATOR_HOOKFUNCTION(lms, GiveFragsForKill)
{
	entity frag_target = M_ARGV(1, entity);

	if (!warmup_stage && time > game_starttime)
	{
		// remove a life
		int tl = GameRules_scoring_add(frag_target, LMS_LIVES, -1);
		if(tl < lms_lowest_lives)
			lms_lowest_lives = tl;
		if(tl <= 0)
		{
			int pl_cnt = 0;
			FOREACH_CLIENT(IS_PLAYER(it) && it.frags == FRAGS_PLAYER, {
				pl_cnt++;
			});
			frag_target.frags = FRAGS_PLAYER_OUT_OF_GAME;
			GameRules_scoring_add(frag_target, LMS_RANK, pl_cnt);
		}
	}
	M_ARGV(2, float) = 0; // frag score

	return true;
}

MUTATOR_HOOKFUNCTION(lms, SetStartItems)
{
	start_items &= ~(IT_UNLIMITED_AMMO | IT_UNLIMITED_SUPERWEAPONS);
	if(!cvar("g_use_ammunition"))
		start_items |= IT_UNLIMITED_AMMO;

	start_health       = warmup_start_health       = cvar("g_lms_start_health");
	start_armorvalue   = warmup_start_armorvalue   = cvar("g_lms_start_armor");
	start_ammo_shells  = warmup_start_ammo_shells  = cvar("g_lms_start_ammo_shells");
	start_ammo_nails   = warmup_start_ammo_nails   = cvar("g_lms_start_ammo_nails");
	start_ammo_rockets = warmup_start_ammo_rockets = cvar("g_lms_start_ammo_rockets");
	start_ammo_cells   = warmup_start_ammo_cells   = cvar("g_lms_start_ammo_cells");
	start_ammo_fuel    = warmup_start_ammo_fuel    = cvar("g_lms_start_ammo_fuel");
}

MUTATOR_HOOKFUNCTION(lms, ForbidPlayerScore_Clear)
{
	// don't clear player score
	return true;
}

MUTATOR_HOOKFUNCTION(lms, FilterItemDefinition)
{
	if (autocvar_g_lms_items || autocvar_g_pickup_items > 0)
		return false;

	entity def = M_ARGV(0, entity);
	if (autocvar_g_powerups && autocvar_g_lms_extra_lives && (def == ITEM_ExtraLife || def == ITEM_HealthMega))
		return false;

	return true;
}

void lms_replace_with_extralife(entity this)
{
	entity e = new(item_extralife);
	Item_CopyFields(this, e);

	StartItem(e, ITEM_ExtraLife);
}

MUTATOR_HOOKFUNCTION(lms, FilterItem)
{
	entity item = M_ARGV(0, entity);
	entity def = item.itemdef;
	if(def == ITEM_HealthMega && !(autocvar_g_lms_items || autocvar_g_pickup_items > 0))
	{
		if(autocvar_g_powerups && autocvar_g_lms_extra_lives)
			lms_replace_with_extralife(item);
		return true;
	}

	return false;
}

MUTATOR_HOOKFUNCTION(lms, ItemTouch)
{
	if(MUTATOR_RETURNVALUE) return false;

	entity item = M_ARGV(0, entity);
	entity toucher = M_ARGV(1, entity);

	if(item.itemdef == ITEM_ExtraLife)
	{
		Send_Notification(NOTIF_ONE, toucher, MSG_CENTER, CENTER_EXTRALIVES, autocvar_g_lms_extra_lives);
		GameRules_scoring_add(toucher, LMS_LIVES, autocvar_g_lms_extra_lives);
		Inventory_pickupitem(item.itemdef, toucher);
		return MUT_ITEMTOUCH_PICKUP;
	}

	return MUT_ITEMTOUCH_CONTINUE;
}

MUTATOR_HOOKFUNCTION(lms, Bot_FixCount, CBC_ORDER_EXCLUSIVE)
{
	FOREACH_CLIENT(IS_REAL_CLIENT(it), {
		if (INGAME(it))
			++M_ARGV(0, int); // activerealplayers
		++M_ARGV(1, int); // realplayers
	});

	return true;
}

MUTATOR_HOOKFUNCTION(lms, ClientCommand_Spectate)
{
	entity player = M_ARGV(0, entity);
	if(player.frags != FRAGS_SPECTATOR && player.frags != FRAGS_PLAYER_OUT_OF_GAME)
		return MUT_SPECCMD_CONTINUE;
	// ranked players (out of game) can no longer become real spectators
	return MUT_SPECCMD_RETURN;
}

MUTATOR_HOOKFUNCTION(lms, CheckRules_World)
{
	M_ARGV(0, float) = WinningCondition_LMS();
	return true;
}

MUTATOR_HOOKFUNCTION(lms, SetWeaponArena)
{
	if(M_ARGV(0, string) == "0" || M_ARGV(0, string) == "")
		M_ARGV(0, string) = autocvar_g_lms_weaponarena;
}

MUTATOR_HOOKFUNCTION(lms, AddPlayerScore)
{
	if(game_stopped)
	if(M_ARGV(0, entity) == SP_LMS_RANK) // score field
		return true; // allow writing to this field in intermission as it is needed for newly joining players
}

void lms_Initialize()
{
	lms_lowest_lives = 999;
}
