#include "gamemode_lms.qh"

#include "gamemode.qh"

#include "../campaign.qh"
#include "../command/cmd.qh"

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
		self.classname = "observer";
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

	if(player.killcount != -666)
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
	self.classname = "player";
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
	if(self.itemdef == ITEM_HealthMega)
	{
		self.max_health = 1;
		return false;
	}

	return true;
}

MUTATOR_HOOKFUNCTION(lms, ItemTouch)
{SELFPARAM();
	// give extra lives for mega health
	if (self.items & ITEM_HealthMega.m_itemid)
	{
		Send_Notification(NOTIF_ONE, other, MSG_CENTER, CENTER_EXTRALIVES);
		PlayerScore_Add(other, SP_LMS_LIVES, autocvar_g_lms_extra_lives);
	}

	return MUT_ITEMTOUCH_CONTINUE;
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

REGISTER_MUTATOR(lms, g_lms)
{
	SetLimits(((!autocvar_g_lms_lives_override) ? -1 : autocvar_g_lms_lives_override), 0, -1, -1);

	MUTATOR_ONADD
	{
		if(time > 1) // game loads at time 1
			error("This is a game type and it cannot be added at runtime.");
		lms_Initialize();
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
