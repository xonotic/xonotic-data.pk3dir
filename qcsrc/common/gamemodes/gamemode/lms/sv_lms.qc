#include "sv_lms.qh"

#include <common/mutators/mutator/instagib/items.qh>
#include <server/campaign.qh>
#include <server/command/_mod.qh>
#include <server/world.qh>
#include <server/items/items.qh>

int autocvar_g_lms_extra_lives;
bool autocvar_g_lms_join_anytime;
int autocvar_g_lms_last_join;
bool autocvar_g_lms_regenerate;
int autocvar_g_lms_leader_wp_lives;
float autocvar_g_lms_leader_wp_max_relative;
float autocvar_g_lms_leader_wp_time;
float autocvar_g_lms_leader_wp_time_repeat;
float autocvar_g_lms_dynamic_respawn_delay;
float autocvar_g_lms_dynamic_respawn_delay_base;
float autocvar_g_lms_dynamic_respawn_delay_increase;
bool autocvar_g_lms_dynamic_vampire;
float autocvar_g_lms_dynamic_vampire_factor_base;
float autocvar_g_lms_dynamic_vampire_factor_increase;
float autocvar_g_lms_dynamic_vampire_factor_max;
int autocvar_g_lms_dynamic_vampire_min_lives_diff;

.float lms_wp_time;

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
	FOREACH_CLIENT(IS_PLAYER(it) && it.frags == FRAGS_PLAYER, {
		if (!totalplayers)
			first_player = it;
		++totalplayers;
	});

	if (totalplayers)
	{
		if (totalplayers > 1)
		{
			// two or more active players - continue with the game

			if (autocvar_g_campaign)
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
			SetWinners(winning, 0); // NOTE: exactly one player is still "player", so this works out

			if (LMS_NewPlayerLives())
			{
				// game still running (that is, nobody got removed from the game by a frag yet)? then continue
				return WINNING_NO;
			}
			else
			{
				// a winner!
				// and assign him his first place
				GameRules_scoring_add(first_player, LMS_RANK, 1);
				return WINNING_YES;
			}
		}
	}
	else
	{
		// nobody is playing at all...
		if (LMS_NewPlayerLives())
		{
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

// mutator hooks
MUTATOR_HOOKFUNCTION(lms, reset_map_global)
{
	lms_lowest_lives = 999;
}

MUTATOR_HOOKFUNCTION(lms, reset_map_players)
{
	FOREACH_CLIENT(true, {
		if (it.frags == FRAGS_PLAYER_OUT_OF_GAME)
		{
			// players who forfeited (rank >= 256) become spectators
			if (it.lms_spectate_warning == 2)
				it.frags = FRAGS_SPECTATOR;
			else
				it.frags = FRAGS_PLAYER;
		}

		CS(it).killcount = 0;
		it.lmsplayer = 0;
		it.lms_spectate_warning = 0;
		GameRules_scoring_add(it, LMS_RANK, -GameRules_scoring_add(it, LMS_RANK, 0));
		GameRules_scoring_add(it, LMS_LIVES, -GameRules_scoring_add(it, LMS_LIVES, 0));

		if (it.frags != FRAGS_PLAYER)
			continue;

		TRANSMUTE(Player, it);
		PutClientInServer(it);
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
	if (!player.lmsplayer)
	{
		int lives = GameRules_scoring_add(player, LMS_LIVES, LMS_NewPlayerLives());
		if(lives <= 0)
			return false;
		player.lmsplayer = 2; // temp value indicating player has just joined the game (but not spawned yet)
	}
	if (warmup_stage || time <= game_starttime)
	{
		if(player.lms_spectate_warning)
		{
			player.lms_spectate_warning = 0;
			GameRules_scoring_add(player, LMS_RANK, -GameRules_scoring_add(player, LMS_RANK, 0));
			int lives = GameRules_scoring_add(player, LMS_LIVES, 0);
			if(lives <= 0)
				GameRules_scoring_add(player, LMS_LIVES, LMS_NewPlayerLives());
		}
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

MUTATOR_HOOKFUNCTION(lms, PlayerSpawn)
{
	entity player = M_ARGV(0, entity);

	if (warmup_stage || time < game_starttime)
		return true;

	if (player.lmsplayer == 2) // just joined the game
	{
		// spawn player with the same amount of health / armor
		// as the least healthy player with the least number of lives
		int pl_lives = GameRules_scoring_add(player, LMS_LIVES, 0);
		float min_health = start_health;
		float min_armorvalue = start_armorvalue;
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
		player.lmsplayer = 1;
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
		if (player.lms_spectate_warning < 2)
		{
			player.frags = FRAGS_PLAYER_OUT_OF_GAME;
			int pl_cnt = 0;
			FOREACH_CLIENT(IS_PLAYER(it) && it.frags == FRAGS_PLAYER, {
				pl_cnt++;
			});
			GameRules_scoring_add(player, LMS_RANK, pl_cnt + 1);
		}
		else
		{
			int min_forfeiter_rank = 665; // different from 666
			FOREACH_CLIENT(true, {
				// update rank of other players that were eliminated
				if (it.frags == FRAGS_PLAYER_OUT_OF_GAME)
				{
					float it_rank = GameRules_scoring_add(it, LMS_RANK, 0);
					if (it_rank > player_rank && it_rank <= 256)
						GameRules_scoring_add(it, LMS_RANK, -1);
					if (it_rank > 256 && it_rank <= min_forfeiter_rank)
						min_forfeiter_rank = it_rank - 1;
				}
				else if (it.frags != FRAGS_SPECTATOR)
				{
					float tl = GameRules_scoring_add(it, LMS_LIVES, 0);
					if(tl < lms_lowest_lives)
						lms_lowest_lives = tl;
				}
			});
			GameRules_scoring_add(player, LMS_RANK, min_forfeiter_rank);
			if(!warmup_stage)
				GameRules_scoring_add(player, LMS_LIVES, -GameRules_scoring_add(player, LMS_LIVES, 0));
			player.frags = FRAGS_PLAYER_OUT_OF_GAME;
			TRANSMUTE(Observer, player);
		}
	}

	if (CS(player).killcount != FRAGS_SPECTATOR && player.lms_spectate_warning < 3)
	{
		if (GameRules_scoring_add(player, LMS_RANK, 0) > 0 && player.lms_spectate_warning < 2)
			Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_LMS_NOLIVES, player.netname);
		else
			Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_LMS_FORFEIT, player.netname);
	}
}

MUTATOR_HOOKFUNCTION(lms, ClientDisconnect)
{
	entity player = M_ARGV(0, entity);

	// no further message other than the disconnect message
	player.lms_spectate_warning = 3;

	lms_RemovePlayer(player);
	player.lmsplayer = 0;
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
		player.lmsplayer = 0;
	}
	else
	{
		if (is_forced)
			player.lms_spectate_warning = 2;
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

	if(player.deadflag == DEAD_DYING)
		player.deadflag = DEAD_RESPAWNING;
}

MUTATOR_HOOKFUNCTION(lms, PlayerRegen)
{
	if(autocvar_g_lms_regenerate)
		return false;
	return true;
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

bool lms_waypointsprite_visible_for_player(entity this, entity player, entity view) // runs on waypoints which are attached to ballcarriers, updates once per frame
{
	if(view.lms_wp_time)
		if(IS_SPEC(player))
			return false; // we don't want spectators of leaders to see the attached waypoint on the top of their screen

	float leader_time = autocvar_g_lms_leader_wp_time;
	float leader_repeat_time = leader_time + autocvar_g_lms_leader_wp_time_repeat;
	float wp_time = this.owner.lms_wp_time;
	if (wp_time && (time - wp_time) % leader_repeat_time > leader_time)
		return false;

	return true;
}

void lms_UpdateWaypoints()
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

	int lives_diff = autocvar_g_lms_leader_wp_lives;
	if (max_lives - second_max_lives >= lives_diff && pl_cnt_with_max_lives <= pl_cnt * autocvar_g_lms_leader_wp_max_relative)
		FOREACH_CLIENT(IS_PLAYER(it) && it.frags != FRAGS_PLAYER_OUT_OF_GAME, {
			int lives = GameRules_scoring_add(it, LMS_LIVES, 0);
			if (lives == max_lives)
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
				if (!it.lms_wp_time)
					it.lms_wp_time = time;
			}
			else
			{
				if (it.waypointsprite_attachedforcarrier)
					WaypointSprite_Kill(it.waypointsprite_attachedforcarrier);
				it.lms_wp_time = 0;
			}
		});
	else
		FOREACH_CLIENT(IS_PLAYER(it) && it.frags != FRAGS_PLAYER_OUT_OF_GAME, {
			if (it.waypointsprite_attachedforcarrier)
				WaypointSprite_Kill(it.waypointsprite_attachedforcarrier);
			it.lms_wp_time = 0;
		});
}

MUTATOR_HOOKFUNCTION(lms, PlayerDied)
{
	if (!warmup_stage && autocvar_g_lms_leader_wp_lives > 0)
		lms_UpdateWaypoints();
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

	player.respawn_time = time + autocvar_g_lms_dynamic_respawn_delay_base +
		autocvar_g_lms_dynamic_respawn_delay_increase * max(0, max_lives - pl_lives);
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
	start_health       = warmup_start_health       = cvar("g_lms_start_health");
	start_armorvalue   = warmup_start_armorvalue   = cvar("g_lms_start_armor");
	start_ammo_shells  = warmup_start_ammo_shells  = cvar("g_lms_start_ammo_shells");
	start_ammo_nails   = warmup_start_ammo_nails   = cvar("g_lms_start_ammo_nails");
	start_ammo_rockets = warmup_start_ammo_rockets = cvar("g_lms_start_ammo_rockets");
	start_ammo_cells   = warmup_start_ammo_cells   = cvar("g_lms_start_ammo_cells");
	start_ammo_plasma  = warmup_start_ammo_plasma  = cvar("g_lms_start_ammo_plasma");
	start_ammo_fuel    = warmup_start_ammo_fuel    = cvar("g_lms_start_ammo_fuel");
}

MUTATOR_HOOKFUNCTION(lms, ForbidPlayerScore_Clear)
{
	// don't clear player score
	return true;
}

MUTATOR_HOOKFUNCTION(lms, FilterItemDefinition)
{
	entity definition = M_ARGV(0, entity);

	if (autocvar_g_lms_extra_lives && definition == ITEM_ExtraLife)
	{
		return false;
	}
	return true;
}

void lms_extralife(entity this)
{
	StartItem(this, ITEM_ExtraLife);
}

MUTATOR_HOOKFUNCTION(lms, OnEntityPreSpawn)
{
	if (MUTATOR_RETURNVALUE) return false;
	if (!autocvar_g_powerups) return false;
	if (!autocvar_g_lms_extra_lives) return false;

	entity ent = M_ARGV(0, entity);

	// Can't use .itemdef here
	if (ent.classname != "item_health_mega") return false;

	entity e = spawn();
	setthink(e, lms_extralife);

	e.nextthink = time + 0.1;
	e.spawnflags = ent.spawnflags;
	e.noalign = ent.noalign;
	setorigin(e, ent.origin);

	return true;
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
		return MUT_ITEMTOUCH_PICKUP;
	}

	return MUT_ITEMTOUCH_CONTINUE;
}

MUTATOR_HOOKFUNCTION(lms, Bot_FixCount, CBC_ORDER_EXCLUSIVE)
{
	FOREACH_CLIENT(IS_REAL_CLIENT(it), {
		if (it.lmsplayer && it.lms_spectate_warning < 2)
			++M_ARGV(0, int); // activerealplayers
		++M_ARGV(1, int); // realplayers
	});

	return true;
}

MUTATOR_HOOKFUNCTION(lms, ClientCommand_Spectate)
{
	entity player = M_ARGV(0, entity);

	if(warmup_stage || time < game_starttime || player.lms_spectate_warning)
	{
		// for the forfeit message...
		player.lms_spectate_warning = 2;
	}
	else
	{
		if(player.frags != FRAGS_SPECTATOR && player.frags != FRAGS_PLAYER_OUT_OF_GAME)
		{
			player.lms_spectate_warning = 1;
			sprint(player, "WARNING: you won't be able to enter the game again after spectating in LMS. Use the same command again to spectate anyway.\n");
		}
		return MUT_SPECCMD_RETURN;
	}
	return MUT_SPECCMD_CONTINUE;
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

MUTATOR_HOOKFUNCTION(lms, GetPlayerStatus)
{
	entity player = M_ARGV(0, entity);

	return boolean(player.lmsplayer);
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
