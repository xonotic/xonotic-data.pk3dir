#include "sv_lms.qh"

#include <common/mutators/mutator/instagib/items.qh>
#include <server/campaign.qh>
#include <server/command/_mod.qh>

int autocvar_g_lms_extra_lives;
bool autocvar_g_lms_join_anytime;
int autocvar_g_lms_last_join;
bool autocvar_g_lms_regenerate;

// main functions
float LMS_NewPlayerLives()
{
	float fl;
	fl = autocvar_fraglimit;
	if(fl == 0)
		fl = 999;

	// first player has left the game for dying too much? Nobody else can get in.
	if(lms_lowest_lives < 1)
		return 0;

	if(!autocvar_g_lms_join_anytime)
		if(lms_lowest_lives < fl - autocvar_g_lms_last_join)
			return 0;

	return bound(1, lms_lowest_lives, fl);
}

void ClearWinners();

// LMS winning condition: game terminates if and only if there's at most one
// one player who's living lives. Top two scores being equal cancels the time
// limit.
int WinningCondition_LMS()
{
	entity first_player = NULL;
	int totalplayers = 0;
	FOREACH_CLIENT(IS_PLAYER(it), {
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
				if(warmup_stage)
					return WINNING_NO;
				else
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
		TRANSMUTE(Player, it);
		it.frags = FRAGS_PLAYER;
		GameRules_scoring_add(it, LMS_LIVES, LMS_NewPlayerLives());
		PutClientInServer(it);
	});
}

// FIXME add support for sv_ready_restart_after_countdown
// that is find a way to respawn/reset players IN GAME without setting lives to 0
MUTATOR_HOOKFUNCTION(lms, ReadLevelCvars)
{
	// incompatible
	sv_ready_restart_after_countdown = 0;
}

MUTATOR_HOOKFUNCTION(lms, PutClientInServer)
{
	entity player = M_ARGV(0, entity);

	if(player.frags == FRAGS_SPECTATOR)
		TRANSMUTE(Observer, player);
	else
	{
		float tl = GameRules_scoring_add(player, LMS_LIVES, 0);
		if(tl < lms_lowest_lives)
			lms_lowest_lives = tl;
		if(tl <= 0)
			TRANSMUTE(Observer, player);
		if(warmup_stage)
			GameRules_scoring_add(player, LMS_RANK, -GameRules_scoring_add(player, LMS_RANK, 0));
	}
}

MUTATOR_HOOKFUNCTION(lms, ForbidSpawn)
{
	entity player = M_ARGV(0, entity);

	if(warmup_stage)
		return false;
	if(player.frags == FRAGS_SPECTATOR)
		return true;
	if(GameRules_scoring_add(player, LMS_LIVES, 0) <= 0)
	{
		Send_Notification(NOTIF_ONE, player, MSG_CENTER, CENTER_LMS_NOLIVES);
		return true;
	}
	return false;
}

MUTATOR_HOOKFUNCTION(lms, PlayerDies)
{
	entity frag_target = M_ARGV(2, entity);

	frag_target.respawn_flags |= RESPAWN_FORCE;
}

void lms_RemovePlayer(entity player)
{
	static int quitters = 0;
	float player_rank = GameRules_scoring_add(player, LMS_RANK, 0);
	if (!player_rank)
	{
		int pl_cnt = 0;
		FOREACH_CLIENT(IS_PLAYER(it), { pl_cnt++; });
		if (player.lms_spectate_warning != 2)
		{
			if(IS_BOT_CLIENT(player))
				bot_clear(player);
			player.frags = FRAGS_LMS_LOSER;
			GameRules_scoring_add(player, LMS_RANK, pl_cnt + 1);
		}
		else
		{
			lms_lowest_lives = 999;
			FOREACH_CLIENT(true, {
				if (it.frags == FRAGS_LMS_LOSER)
				{
					float it_rank = GameRules_scoring_add(it, LMS_RANK, 0);
					if (it_rank > player_rank && it_rank <= 256)
						GameRules_scoring_add(it, LMS_RANK, -1);
					lms_lowest_lives = 0;
				}
				else if (it.frags != FRAGS_SPECTATOR)
				{
					float tl = GameRules_scoring_add(it, LMS_LIVES, 0);
					if(tl < lms_lowest_lives)
						lms_lowest_lives = tl;
				}
			});
			GameRules_scoring_add(player, LMS_RANK, 665 - quitters); // different from 666
			if(!warmup_stage)
			{
				GameRules_scoring_add(player, LMS_LIVES, -GameRules_scoring_add(player, LMS_LIVES, 0));
				++quitters;
			}
			player.frags = FRAGS_LMS_LOSER;
			TRANSMUTE(Observer, player);
		}
		if (pl_cnt == 2 && !warmup_stage) // a player is forfeiting leaving only one player
			lms_lowest_lives = 0; // end the game now!
	}

	if(CS(player).killcount != FRAGS_SPECTATOR)
		if(GameRules_scoring_add(player, LMS_RANK, 0) > 0 && player.lms_spectate_warning != 2)
			Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_LMS_NOLIVES, player.netname);
		else
			Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_LMS_FORFEIT, player.netname);
}

MUTATOR_HOOKFUNCTION(lms, ClientDisconnect)
{
	entity player = M_ARGV(0, entity);

	lms_RemovePlayer(player);
}

MUTATOR_HOOKFUNCTION(lms, MakePlayerObserver)
{
	entity player = M_ARGV(0, entity);

	if (!IS_PLAYER(player))
		return true;

	lms_RemovePlayer(player);
	return true;  // prevent team reset
}

MUTATOR_HOOKFUNCTION(lms, ClientConnect)
{
	entity player = M_ARGV(0, entity);

	if(GameRules_scoring_add(player, LMS_LIVES, LMS_NewPlayerLives()) <= 0)
	{
		GameRules_scoring_add(player, LMS_RANK, 666); // mark as forced spectator for the hud code
		player.frags = FRAGS_SPECTATOR;
	}
}

// FIXME LMS doesn't allow clients to spectate due to its particular implementation
MUTATOR_HOOKFUNCTION(lms, AutoJoinOnConnection)
{
	if(autocvar_g_campaign)
		return false;
	return true;
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

MUTATOR_HOOKFUNCTION(lms, GiveFragsForKill)
{
	entity frag_target = M_ARGV(1, entity);

	if (!warmup_stage)
	{
		// remove a life
		int tl = GameRules_scoring_add(frag_target, LMS_LIVES, -1);
		if(tl < lms_lowest_lives)
			lms_lowest_lives = tl;
		if(tl <= 0)
		{
			int pl_cnt = 0;
			FOREACH_CLIENT(IS_PLAYER(it), { pl_cnt++; });
			if(IS_BOT_CLIENT(frag_target))
				bot_clear(frag_target);
			frag_target.frags = FRAGS_LMS_LOSER;
			GameRules_scoring_add(frag_target, LMS_RANK, pl_cnt);
		}
	}
	M_ARGV(2, float) = 0; // frag score

	return true;
}

MUTATOR_HOOKFUNCTION(lms, SetStartItems)
{
	start_items &= ~IT_UNLIMITED_AMMO;
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
	entity item = M_ARGV(0, entity);
	entity toucher = M_ARGV(1, entity);

	if(item.itemdef == ITEM_ExtraLife)
	{
		Send_Notification(NOTIF_ONE, toucher, MSG_CENTER, CENTER_EXTRALIVES);
		GameRules_scoring_add(toucher, LMS_LIVES, autocvar_g_lms_extra_lives);
		return MUT_ITEMTOUCH_PICKUP;
	}

	return MUT_ITEMTOUCH_CONTINUE;
}

MUTATOR_HOOKFUNCTION(lms, Bot_FixCount, CBC_ORDER_EXCLUSIVE)
{
	FOREACH_CLIENT(IS_REAL_CLIENT(it), {
		++M_ARGV(0, int); // activerealplayers
		++M_ARGV(1, int); // realplayers
	});

	return true;
}

MUTATOR_HOOKFUNCTION(lms, ClientCommand_Spectate)
{
	entity player = M_ARGV(0, entity);

	if(warmup_stage || player.lms_spectate_warning)
	{
		// for the forfeit message...
		player.lms_spectate_warning = 2;
	}
	else
	{
		if(player.frags != FRAGS_SPECTATOR && player.frags != FRAGS_LMS_LOSER)
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

MUTATOR_HOOKFUNCTION(lms, WantWeapon)
{
	M_ARGV(2, bool) = true; // all weapons
}

MUTATOR_HOOKFUNCTION(lms, GetPlayerStatus)
{
	return true;
}

MUTATOR_HOOKFUNCTION(lms, AddPlayerScore)
{
	if(game_stopped)
	if(M_ARGV(0, entity) == SP_LMS_RANK) // score field
		return true; // allow writing to this field in intermission as it is needed for newly joining players
}

void lms_Initialize()
{
	lms_lowest_lives = 9999;
}
