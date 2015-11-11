#ifndef GAMEMODE_LMS_H
#define GAMEMODE_LMS_H

#define autocvar_g_lms_lives_override cvar("g_lms_lives_override")
void lms_Initialize();

REGISTER_MUTATOR(lms, false)
{
	MUTATOR_ONADD
	{
		if (time > 1) // game loads at time 1
			error("This is a game type and it cannot be added at runtime.");
		lms_Initialize();

		SetLimits(((!autocvar_g_lms_lives_override) ? -1 : autocvar_g_lms_lives_override), 0, -1, -1);
	}

	MUTATOR_ONROLLBACK_OR_REMOVE
	{
		// we actually cannot roll back lms_Initialize here
		// BUT: we don't need to! If this gets called, adding always
		// succeeds.
	}

	MUTATOR_ONREMOVE
	{
		LOG_INFO("This is a game type and it cannot be removed at runtime.");
		return -1;
	}

	return 0;
}

// scoreboard stuff
const float SP_LMS_LIVES = 4;
const float SP_LMS_RANK = 5;

// lives related defs
float lms_lowest_lives;
float lms_next_place;
float LMS_NewPlayerLives();

#endif

#ifdef IMPLEMENTATION

#include "../../campaign.qh"
#include "../../command/cmd.qh"

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

// LMS winning condition: game terminates if and only if there's at most one
// one player who's living lives. Top two scores being equal cancels the time
// limit.
float WinningCondition_LMS()
{
	entity head, head2;
	float have_player;
	float have_players;
	float l;

	have_player = false;
	have_players = false;
	l = LMS_NewPlayerLives();

	head = find(world, classname, "player");
	if(head)
		have_player = true;
	head2 = find(head, classname, "player");
	if(head2)
		have_players = true;

	if(have_player)
	{
		// we have at least one player
		if(have_players)
		{
			// two or more active players - continue with the game
		}
		else
		{
			// exactly one player?

			ClearWinners();
			SetWinners(winning, 0); // NOTE: exactly one player is still "player", so this works out

			if(l)
			{
				// game still running (that is, nobody got removed from the game by a frag yet)? then continue
				return WINNING_NO;
			}
			else
			{
				// a winner!
				// and assign him his first place
				PlayerScore_Add(head, SP_LMS_RANK, 1);
				return WINNING_YES;
			}
		}
	}
	else
	{
		// nobody is playing at all...
		if(l)
		{
			// wait for players...
		}
		else
		{
			// SNAFU (maybe a draw game?)
			ClearWinners();
			LOG_TRACE("No players, ending game.\n");
			return WINNING_YES;
		}
	}

	// When we get here, we have at least two players who are actually LIVING,
	// now check if the top two players have equal score.
	WinningConditionHelper();

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
	lms_next_place = player_count;

	return false;
}

MUTATOR_HOOKFUNCTION(lms, reset_map_players)
{SELFPARAM();
	entity e;
	if(restart_mapalreadyrestarted || (time < game_starttime))
	FOR_EACH_CLIENT(e)
	if(IS_PLAYER(e))
	{
		WITH(entity, self, e, PlayerScore_Add(e, SP_LMS_LIVES, LMS_NewPlayerLives()));
	}

	return false;
}

MUTATOR_HOOKFUNCTION(lms, PutClientInServer)
{SELFPARAM();
	// player is dead and becomes observer
	// FIXME fix LMS scoring for new system
	if(PlayerScore_Add(self, SP_LMS_RANK, 0) > 0)
	{
		self.classname = STR_OBSERVER;
		Send_Notification(NOTIF_ONE, self, MSG_CENTER, CENTER_LMS_NOLIVES);
	}

	return false;
}

MUTATOR_HOOKFUNCTION(lms, PlayerDies)
{SELFPARAM();
	self.respawn_flags |= RESPAWN_FORCE;

	return false;
}

void lms_RemovePlayer(entity player)
{
	// Only if the player cannot play at all
	if(PlayerScore_Add(player, SP_LMS_RANK, 0) == 666)
		player.frags = FRAGS_SPECTATOR;
	else
		player.frags = FRAGS_LMS_LOSER;

	if(player.killcount != FRAGS_SPECTATOR)
		if(PlayerScore_Add(player, SP_LMS_RANK, 0) > 0 && player.lms_spectate_warning != 2)
			Send_Notification(NOTIF_ALL, world, MSG_INFO, INFO_LMS_NOLIVES, player.netname);
		else
			Send_Notification(NOTIF_ALL, world, MSG_INFO, INFO_LMS_FORFEIT, player.netname);
}

MUTATOR_HOOKFUNCTION(lms, ClientDisconnect)
{SELFPARAM();
	lms_RemovePlayer(self);
	return false;
}

MUTATOR_HOOKFUNCTION(lms, MakePlayerObserver)
{SELFPARAM();
	lms_RemovePlayer(self);
	return false;
}

MUTATOR_HOOKFUNCTION(lms, ClientConnect)
{SELFPARAM();
	self.classname = STR_PLAYER;
	campaign_bots_may_start = 1;

	if(PlayerScore_Add(self, SP_LMS_LIVES, LMS_NewPlayerLives()) <= 0)
	{
		PlayerScore_Add(self, SP_LMS_RANK, 666);
		self.frags = FRAGS_SPECTATOR;
	}

	return false;
}

MUTATOR_HOOKFUNCTION(lms, PlayerPreThink)
{SELFPARAM();
	if(self.deadflag == DEAD_DYING)
		self.deadflag = DEAD_RESPAWNING;

	return false;
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
	// remove a life
	float tl;
	tl = PlayerScore_Add(frag_target, SP_LMS_LIVES, -1);
	if(tl < lms_lowest_lives)
		lms_lowest_lives = tl;
	if(tl <= 0)
	{
		if(!lms_next_place)
			lms_next_place = player_count;
		else
			lms_next_place = min(lms_next_place, player_count);
		PlayerScore_Add(frag_target, SP_LMS_RANK, lms_next_place); // won't ever spawn again
		--lms_next_place;
	}
	frag_score = 0;

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

	return false;
}

MUTATOR_HOOKFUNCTION(lms, ForbidPlayerScore_Clear)
{
	// don't clear player score
	return true;
}

MUTATOR_HOOKFUNCTION(lms, FilterItem)
{SELFPARAM();
	if(autocvar_g_lms_extra_lives)
	if(self.itemdef == ITEM_ExtraLife)
		return false;

	return true;
}

void lms_extralife()
{SELFPARAM();
	StartItem(this, ITEM_ExtraLife);
}

MUTATOR_HOOKFUNCTION(lms, OnEntityPreSpawn)
{SELFPARAM();
	if (!autocvar_g_powerups) return false;
	if (!autocvar_g_lms_extra_lives) return false;

	// Can't use .itemdef here
	if (self.classname != "item_health_mega") return false;

	entity e = spawn();
	e.think = lms_extralife;

	e.nextthink = time + 0.1;
	e.spawnflags = self.spawnflags;
	e.noalign = self.noalign;
	setorigin(e, self.origin);

	return true;
}

MUTATOR_HOOKFUNCTION(lms, ItemTouch)
{SELFPARAM();
	if(self.itemdef == ITEM_ExtraLife)
	{
		Send_Notification(NOTIF_ONE, other, MSG_CENTER, CENTER_EXTRALIVES);
		PlayerScore_Add(other, SP_LMS_LIVES, autocvar_g_lms_extra_lives);
		return MUT_ITEMTOUCH_PICKUP;
	}

	return MUT_ITEMTOUCH_CONTINUE;
}

MUTATOR_HOOKFUNCTION(lms, Bot_FixCount, CBC_ORDER_EXCLUSIVE)
{
	entity head;
	FOR_EACH_REALCLIENT(head)
	{
		++bot_activerealplayers;
		++bot_realplayers;
	}

	return true;
}

MUTATOR_HOOKFUNCTION(lms, ClientCommand_Spectate)
{
	if(self.lms_spectate_warning)
	{
		// for the forfeit message...
		self.lms_spectate_warning = 2;
		// mark player as spectator
		PlayerScore_Add(self, SP_LMS_RANK, 666 - PlayerScore_Add(self, SP_LMS_RANK, 0));
	}
	else
	{
		self.lms_spectate_warning = 1;
		sprint(self, "WARNING: you won't be able to enter the game again after spectating in LMS. Use the same command again to spectate anyway.\n");
		return MUT_SPECCMD_RETURN;
	}
	return MUT_SPECCMD_CONTINUE;
}

MUTATOR_HOOKFUNCTION(lms, CheckRules_World)
{
	ret_float = WinningCondition_LMS();
	return true;
}

MUTATOR_HOOKFUNCTION(lms, WantWeapon)
{
	want_allguns = true;
	return false;
}

MUTATOR_HOOKFUNCTION(lms, GetPlayerStatus)
{
	return true;
}

MUTATOR_HOOKFUNCTION(lms, AddPlayerScore)
{
	if(gameover)
	if(score_field == SP_LMS_RANK)
		return true; // allow writing to this field in intermission as it is needed for newly joining players
	return false;
}

// scoreboard stuff
void lms_ScoreRules()
{
	ScoreRules_basics(0, 0, 0, false);
	ScoreInfo_SetLabel_PlayerScore(SP_LMS_LIVES,    "lives",     SFL_SORT_PRIO_SECONDARY);
	ScoreInfo_SetLabel_PlayerScore(SP_LMS_RANK,     "rank",      SFL_LOWER_IS_BETTER | SFL_RANK | SFL_SORT_PRIO_PRIMARY | SFL_ALLOW_HIDE);
	ScoreRules_basics_end();
}

void lms_Initialize()
{
	lms_lowest_lives = 9999;
	lms_next_place = 0;

	lms_ScoreRules();
}


#endif
