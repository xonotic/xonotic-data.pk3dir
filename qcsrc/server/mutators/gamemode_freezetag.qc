.float freezetag_frozen_time;
.float freezetag_frozen_timeout;
.float freezetag_revive_progress;
.entity freezetag_ice;
#define ICE_MAX_ALPHA 0.6
#define ICE_MIN_ALPHA 0.1
float freezetag_teams;

float freezetag_CheckTeams();
float freezetag_CheckWinner();
void freezetag_Initialize()
{
	precache_model("models/ice/ice.md3");
	ScoreRules_freezetag();

	round_handler_Spawn(freezetag_CheckTeams, freezetag_CheckWinner, func_null, 5, autocvar_g_freezetag_warmup, autocvar_g_freezetag_round_timelimit);

	addstat(STAT_REDALIVE, AS_INT, redalive_stat);
	addstat(STAT_BLUEALIVE, AS_INT, bluealive_stat);
	addstat(STAT_YELLOWALIVE, AS_INT, yellowalive_stat);
	addstat(STAT_PINKALIVE, AS_INT, pinkalive_stat);

	addstat(STAT_FROZEN, AS_INT, freezetag_frozen);
	addstat(STAT_REVIVE_PROGRESS, AS_FLOAT, freezetag_revive_progress);
}

void freezetag_count_alive_players()
{
	entity e;
	total_players = redalive = bluealive = yellowalive = pinkalive = 0;
	FOR_EACH_PLAYER(e) {
		if(e.team == COLOR_TEAM1 && e.health >= 1)
		{
			++total_players;
			if (!e.freezetag_frozen) ++redalive;
		}
		else if(e.team == COLOR_TEAM2 && e.health >= 1)
		{
			++total_players;
			if (!e.freezetag_frozen) ++bluealive;
		}
		else if(e.team == COLOR_TEAM3 && e.health >= 1)
		{
			++total_players;
			if (!e.freezetag_frozen) ++yellowalive;
		}
		else if(e.team == COLOR_TEAM4 && e.health >= 1)
		{
			++total_players;
			if (!e.freezetag_frozen) ++pinkalive;
		}
	}
	FOR_EACH_REALCLIENT(e) {
		e.redalive_stat = redalive;
		e.bluealive_stat = bluealive;
		e.yellowalive_stat = yellowalive;
		e.pinkalive_stat = pinkalive;
	}
}
#define FREEZETAG_ALIVE_TEAMS() ((redalive > 0) + (bluealive > 0) + (yellowalive > 0) + (pinkalive > 0))
#define FREEZETAG_ALIVE_TEAMS_OK() (FREEZETAG_ALIVE_TEAMS() == freezetag_teams)

float prev_total_players;
float freezetag_CheckTeams()
{
	entity e;
	if(FREEZETAG_ALIVE_TEAMS_OK())
	{
		if(prev_total_players != -1)
		{
			FOR_EACH_REALCLIENT(e)
				Send_CSQC_Centerprint_Generic_Expire(e, CPID_WAITING_PLAYERS);
		}
		prev_total_players = -1;
		return 1;
	}
	if(prev_total_players != total_players)
	{
		string teams_missing = "";
		if(!redalive)	teams_missing = strcat(teams_missing, ColoredTeamName(COLOR_TEAM1), ", ");
		if(!bluealive)	teams_missing = strcat(teams_missing, ColoredTeamName(COLOR_TEAM2), ", ");
		if(freezetag_teams >= 3)
		if(!yellowalive)	teams_missing = strcat(teams_missing, ColoredTeamName(COLOR_TEAM3), ", ");
		if(freezetag_teams == 4)
		if(!pinkalive)	teams_missing = strcat(teams_missing, ColoredTeamName(COLOR_TEAM4), ", ");
		teams_missing = substring(teams_missing, 0, strlen(teams_missing)-2);

		FOR_EACH_REALCLIENT(e)
			Send_CSQC_Centerprint_Generic(e, CPID_WAITING_PLAYERS, strcat("Waiting for players to join...\n\nNeed active players for: ", teams_missing), -1, 0);
		prev_total_players = total_players;
	}
	return 0;
}

float freezetag_getWinnerTeam()
{
	float winner_team = 0;
	if(redalive >= 1)
		winner_team = COLOR_TEAM1;
	if(bluealive >= 1)
	{
		if(winner_team) return 0;
		winner_team = COLOR_TEAM2;
	}
	if(yellowalive >= 1)
	{
		if(winner_team) return 0;
		winner_team = COLOR_TEAM3;
	}
	if(pinkalive >= 1)
	{
		if(winner_team) return 0;
		winner_team = COLOR_TEAM4;
	}
	if(winner_team)
		return winner_team;
	return -1; // no player left
}

float freezetag_CheckWinner()
{
	entity e;
	if(round_handler_GetTimeLeft() <= 0)
	{
		FOR_EACH_REALCLIENT(e)
			centerprint(e, "Round over, there's no winner");
		bprint("Round over, there's no winner.\n");
		FOR_EACH_PLAYER(e)
			e.freezetag_frozen_timeout = 0;
		return 1;
	}

	if(FREEZETAG_ALIVE_TEAMS() > 1)
		return 0;

	float winner_team;
	string teamname;
	winner_team = freezetag_getWinnerTeam();
	if(winner_team > 0)
	{
		teamname = ColoredTeamName(winner_team);
		FOR_EACH_REALCLIENT(e)
			centerprint(e, strcat(teamname, "^5 wins the round, all other teams were frozen."));
		bprint(teamname, "^5 wins the round since all the other teams were frozen.\n");
		TeamScore_AddToTeam(winner_team, ST_SCORE, +1);
	}
	else if(winner_team == -1)
	{
		FOR_EACH_REALCLIENT(e)
			centerprint(e, "^5Round tied! All teams were frozen.");
		bprint("^5Round tied! All teams were frozen.\n");
	}

	FOR_EACH_PLAYER(e)
		e.freezetag_frozen_timeout = 0;
	return 1;
}

// this is needed to allow the player to turn his view around (fixangle can't
// be used to freeze his view, as that also changes the angles), while not
// turning that ice object with the player
void freezetag_Ice_Think()
{
	setorigin(self, self.owner.origin - '0 0 16');
	self.nextthink = time;
}

void freezetag_Add_Score(entity attacker)
{
	if(attacker == self)
	{
		// you froze your own dumb self
		// counted as "suicide" already
		PlayerScore_Add(self, SP_SCORE, -1);
	}
	else if(attacker.classname == "player")
	{
		// got frozen by an enemy
		// counted as "kill" and "death" already
		PlayerScore_Add(self, SP_SCORE, -1);
		PlayerScore_Add(attacker, SP_SCORE, +1);
	}
	// else nothing - got frozen by the game type rules themselves
}

void freezetag_Freeze(entity attacker)
{
	if(self.freezetag_frozen)
		return;
	self.freezetag_frozen = 1;
	self.freezetag_frozen_time = time;
	self.freezetag_revive_progress = 0;
	self.health = 1;
	if(autocvar_g_freezetag_frozen_maxtime > 0)
		self.freezetag_frozen_timeout = time + autocvar_g_freezetag_frozen_maxtime;

	freezetag_count_alive_players();

	entity ice;
	ice = spawn();
	ice.owner = self;
	ice.classname = "freezetag_ice";
	ice.think = freezetag_Ice_Think;
	ice.nextthink = time;
	ice.frame = floor(random() * 21); // ice model has 20 different looking frames
	ice.alpha = ICE_MAX_ALPHA;
	setmodel(ice, "models/ice/ice.md3");

	self.freezetag_ice = ice;

	RemoveGrapplingHook(self);

	// add waypoint
	WaypointSprite_Spawn("freezetag_frozen", 0, 0, self, '0 0 64', world, self.team, self, waypointsprite_attached, TRUE, RADARICON_WAYPOINT, '0.25 0.90 1');

	freezetag_Add_Score(attacker);
}

void freezetag_Unfreeze(entity attacker)
{
	self.freezetag_frozen = 0;
	self.freezetag_frozen_time = 0;
	self.freezetag_frozen_timeout = 0;
	self.freezetag_revive_progress = 0;

	remove(self.freezetag_ice);
	self.freezetag_ice = world;

	if(self.waypointsprite_attached)
		WaypointSprite_Kill(self.waypointsprite_attached);
}


// ================
// Bot player logic
// ================

void() havocbot_role_ft_freeing;
void() havocbot_role_ft_offense;

void havocbot_goalrating_freeplayers(float ratingscale, vector org, float sradius)
{
	entity head;
	float distance;

	FOR_EACH_PLAYER(head)
	{
		if ((head != self) && (head.team == self.team))
		{
			if (head.freezetag_frozen)
			{
				distance = vlen(head.origin - org);
				if (distance > sradius)
					continue;
				navigation_routerating(head, ratingscale, 2000);
			}
			else
			{
				// If teamate is not frozen still seek them out as fight better
				// in a group.
				navigation_routerating(head, ratingscale/3, 2000);
			}
		}
	}
}

void havocbot_role_ft_offense()
{
	entity head;
	float unfrozen;

	if(self.deadflag != DEAD_NO)
		return;

	if (!self.havocbot_role_timeout)
		self.havocbot_role_timeout = time + random() * 10 + 20;

	// Count how many players on team are unfrozen.
	unfrozen = 0;
	FOR_EACH_PLAYER(head)
	{
		if ((head.team == self.team) && (!head.freezetag_frozen))
			unfrozen++;
	}

	// If only one left on team or if role has timed out then start trying to free players.
	if (((unfrozen == 0) && (!self.freezetag_frozen)) || (time > self.havocbot_role_timeout))
	{
		dprint("changing role to freeing\n");
		self.havocbot_role = havocbot_role_ft_freeing;
		self.havocbot_role_timeout = 0;
		return;
	}

	if (time > self.bot_strategytime)
	{
		self.bot_strategytime = time + autocvar_bot_ai_strategyinterval;

		navigation_goalrating_start();
		havocbot_goalrating_items(10000, self.origin, 10000);
		havocbot_goalrating_enemyplayers(20000, self.origin, 10000);
		havocbot_goalrating_freeplayers(9000, self.origin, 10000);
		//havocbot_goalrating_waypoints(1, self.origin, 1000);
		navigation_goalrating_end();
	}
}

void havocbot_role_ft_freeing()
{
	if(self.deadflag != DEAD_NO)
		return;

	if (!self.havocbot_role_timeout)
		self.havocbot_role_timeout = time + random() * 10 + 20;

	if (time > self.havocbot_role_timeout)
	{
		dprint("changing role to offense\n");
		self.havocbot_role = havocbot_role_ft_offense;
		self.havocbot_role_timeout = 0;
		return;
	}

	if (time > self.bot_strategytime)
	{
		self.bot_strategytime = time + autocvar_bot_ai_strategyinterval;

		navigation_goalrating_start();
		havocbot_goalrating_items(8000, self.origin, 10000);
		havocbot_goalrating_enemyplayers(10000, self.origin, 10000);
		havocbot_goalrating_freeplayers(20000, self.origin, 10000);
		//havocbot_goalrating_waypoints(1, self.origin, 1000);
		navigation_goalrating_end();
	}
}


// ==============
// Hook Functions
// ==============

MUTATOR_HOOKFUNCTION(freezetag_RemovePlayer)
{
	self.health = 0; // neccessary to update correctly alive stats
	freezetag_Unfreeze(world);
	freezetag_count_alive_players();
	return 1;
}

MUTATOR_HOOKFUNCTION(freezetag_PlayerDies)
{
	if(round_handler_IsActive())
	if(round_handler_CountdownRunning())
	{
		if(self.freezetag_frozen)
			freezetag_Unfreeze(world);
		freezetag_count_alive_players();
		return 1; // let the player die so that he can respawn whenever he wants
	}

	// Cases DEATH_TEAMCHANGE and DEATH_AUTOTEAMCHANGE are needed to fix a bug whe
	// you succeed changing team through the menu: you both really die (gibbing) and get frozen
	if(ITEM_DAMAGE_NEEDKILL(frag_deathtype)
		|| frag_deathtype == DEATH_TEAMCHANGE || frag_deathtype == DEATH_AUTOTEAMCHANGE)
	{
		// let the player die, he will be automatically frozen when he respawns
		if(!self.freezetag_frozen)
		{
			freezetag_Add_Score(frag_attacker);
			freezetag_count_alive_players();
		}
		else
			freezetag_Unfreeze(world); // remove ice
		self.freezetag_frozen_timeout = -2; // freeze on respawn
		return 1;
	}

	if(self.freezetag_frozen)
		return 1;

	freezetag_Freeze(frag_attacker);

	if(frag_attacker == frag_target || frag_attacker == world)
	{
		if(frag_target.classname == STR_PLAYER)
			centerprint(frag_target, "^1You froze yourself.\n");
		bprint("^7", frag_target.netname, "^1 froze himself.\n");
	}
	else
	{
		if(frag_target.classname == STR_PLAYER)
			centerprint(frag_target, strcat("^1You were frozen by ^7", frag_attacker.netname, ".\n"));
		if(frag_attacker.classname == STR_PLAYER)
			centerprint(frag_attacker, strcat("^2You froze ^7", frag_target.netname, ".\n"));
		bprint("^7", frag_target.netname, "^1 was frozen by ^7", frag_attacker.netname, ".\n");
	}

	frag_target.health = 1; // "respawn" the player :P

	return 1;
}

MUTATOR_HOOKFUNCTION(freezetag_PlayerSpawn)
{
	if(self.freezetag_frozen_timeout == -1) // if PlayerSpawn is called by reset_map_players
		return 1; // do nothing, round is starting right now

	if(self.freezetag_frozen_timeout == -2) // player was dead
	{
		freezetag_Freeze(world);
		return 1;
	}

	freezetag_count_alive_players();

	if(round_handler_IsActive())
	if(round_handler_IsRoundStarted())
	{
		centerprint(self, "^1Round already started, you spawn as frozen.");
		freezetag_Freeze(world);
	}

	return 1;
}

MUTATOR_HOOKFUNCTION(freezetag_reset_map_players)
{
	FOR_EACH_PLAYER(self)
	{
		if (self.freezetag_frozen)
			freezetag_Unfreeze(world);
		self.freezetag_frozen_timeout = -1;
		PutClientInServer();
		self.freezetag_frozen_timeout = 0;
	}
	freezetag_count_alive_players();
	return 1;
}

MUTATOR_HOOKFUNCTION(freezetag_GiveFragsForKill)
{
	frag_score = 0; // no frags counted in Freeze Tag
	return 1;
}

.float reviving; // temp var
MUTATOR_HOOKFUNCTION(freezetag_PlayerPreThink)
{
	float n;

	if(gameover)
		return 1;

	if(self.freezetag_frozen)
	{
		// keep health = 1
		self.pauseregen_finished = time + autocvar_g_balance_pause_health_regen;
	}

	if(round_handler_IsActive())
	if(!round_handler_IsRoundStarted())
		return 1;

	entity o;
	o = world;
	if(self.freezetag_frozen_timeout > 0 && time < self.freezetag_frozen_timeout)
		self.freezetag_ice.alpha = ICE_MIN_ALPHA + (ICE_MAX_ALPHA - ICE_MIN_ALPHA) * (self.freezetag_frozen_timeout - time) / (self.freezetag_frozen_timeout - self.freezetag_frozen_time);

	if(self.freezetag_frozen_timeout > 0 && time >= self.freezetag_frozen_timeout)
		n = -1;
	else
	{
		vector revive_extra_size = '1 1 1' * autocvar_g_freezetag_revive_extra_size;
		n = 0;
		FOR_EACH_PLAYER(other) if(self != other)
		{
			if(other.freezetag_frozen == 0)
			{
				if(other.team == self.team)
				{
					if(boxesoverlap(self.absmin - revive_extra_size, self.absmax + revive_extra_size, other.absmin, other.absmax))
					{
						if(!o)
							o = other;
						if(self.freezetag_frozen)
							other.reviving = TRUE;
						++n;
					}
				}
			}
		}
	}

	if(n && self.freezetag_frozen) // OK, there is at least one teammate reviving us
	{
		self.freezetag_revive_progress = bound(0, self.freezetag_revive_progress + frametime * autocvar_g_freezetag_revive_speed, 1);
		self.health = max(1, self.freezetag_revive_progress * autocvar_g_balance_health_start);

		if(self.freezetag_revive_progress >= 1)
		{
			freezetag_Unfreeze(self);
			freezetag_count_alive_players();

			if(n == -1)
			{
				string s = ftos(autocvar_g_freezetag_frozen_maxtime);
				centerprint(self, strcat("^5You were automatically revived after ", s, " seconds^5.\n"));
				bprint("^7", self.netname, "^5 were automatically revived after ", s, " seconds^5.\n");
				return 1;
			}

			// EVERY team mate nearby gets a point (even if multiple!)
			FOR_EACH_PLAYER(other)
			{
				if(other.reviving)
				{
					PlayerScore_Add(other, SP_FREEZETAG_REVIVALS, +1);
					PlayerScore_Add(other, SP_SCORE, +1);
				}
			}

			if(n > 1)
				centerprint(self, strcat("^5You were revived by ^7", o.netname, "^5 et al.\n"));
			else
				centerprint(self, strcat("^5You were revived by ^7", o.netname, "^5.\n"));
			centerprint(o, strcat("^5You revived ^7", self.netname, "^5.\n"));
			if(n > 1)
				bprint("^7", o.netname, "^5 et al revived ^7", self.netname, "^5.\n");
			else
				bprint("^7", o.netname, "^5 revived ^7", self.netname, "^5.\n");
		}

		FOR_EACH_PLAYER(other)
		{
			if(other.reviving)
			{
				other.freezetag_revive_progress = self.freezetag_revive_progress;
				other.reviving = FALSE;
			}
		}
	}
	else if(!n && self.freezetag_frozen) // only if no teammate is nearby will we reset
	{
		self.freezetag_revive_progress = bound(0, self.freezetag_revive_progress - frametime * autocvar_g_freezetag_revive_clearspeed, 1);
		self.health = max(1, self.freezetag_revive_progress * autocvar_g_balance_health_start);
	}
	else if(!n)
	{
		self.freezetag_revive_progress = 0; // thawing nobody
	}

	return 1;
}

MUTATOR_HOOKFUNCTION(freezetag_PlayerPhysics)
{
	if(self.freezetag_frozen)
	{
		self.movement = '0 0 0';
		self.disableclientprediction = 1;
	}
	return 1;
}

MUTATOR_HOOKFUNCTION(freezetag_PlayerDamage_Calculate)
{
	if(frag_target.freezetag_frozen && frag_deathtype != DEATH_HURTTRIGGER)
	{
		frag_damage = 0;
		frag_force = frag_force * autocvar_g_freezetag_frozen_force;
	}
	return 1;
}

MUTATOR_HOOKFUNCTION(freezetag_ForbidThrowCurrentWeapon)
{
	if (self.freezetag_frozen)
		return 1;
	return 0;
}

MUTATOR_HOOKFUNCTION(freezetag_BotRoles)
{
	if not(self.deadflag)
	{
		if (random() < 0.5)
			self.havocbot_role = havocbot_role_ft_freeing;
		else
			self.havocbot_role = havocbot_role_ft_offense;
	}

	return TRUE;
}

MUTATOR_HOOKFUNCTION(freezetag_SpectateCopy)
{
	self.freezetag_frozen = other.freezetag_frozen;
	self.freezetag_revive_progress = other.freezetag_revive_progress;
	return 0;
}

MUTATOR_HOOKFUNCTION(freezetag_GetTeamCount)
{
	freezetag_teams = autocvar_g_freezetag_teams_override;
	if(freezetag_teams < 2)
		freezetag_teams = autocvar_g_freezetag_teams;
	freezetag_teams = bound(2, freezetag_teams, 4);
	ret_float = freezetag_teams;
	return 0;
}

MUTATOR_DEFINITION(gamemode_freezetag)
{
	MUTATOR_HOOK(MakePlayerObserver, freezetag_RemovePlayer, CBC_ORDER_ANY);
	MUTATOR_HOOK(ClientDisconnect, freezetag_RemovePlayer, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerDies, freezetag_PlayerDies, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerSpawn, freezetag_PlayerSpawn, CBC_ORDER_ANY);
	MUTATOR_HOOK(reset_map_players, freezetag_reset_map_players, CBC_ORDER_ANY);
	MUTATOR_HOOK(GiveFragsForKill, freezetag_GiveFragsForKill, CBC_ORDER_FIRST);
	MUTATOR_HOOK(PlayerPreThink, freezetag_PlayerPreThink, CBC_ORDER_FIRST);
	MUTATOR_HOOK(PlayerPhysics, freezetag_PlayerPhysics, CBC_ORDER_FIRST);
	MUTATOR_HOOK(PlayerDamage_Calculate, freezetag_PlayerDamage_Calculate, CBC_ORDER_ANY);
	MUTATOR_HOOK(ForbidThrowCurrentWeapon, freezetag_ForbidThrowCurrentWeapon, CBC_ORDER_ANY);
	MUTATOR_HOOK(HavocBot_ChooseRule, freezetag_BotRoles, CBC_ORDER_ANY);
	MUTATOR_HOOK(SpectateCopy, freezetag_SpectateCopy, CBC_ORDER_ANY);
	MUTATOR_HOOK(GetTeamCount, freezetag_GetTeamCount, CBC_ORDER_EXCLUSIVE);

	MUTATOR_ONADD
	{
		if(time > 1) // game loads at time 1
			error("This is a game type and it cannot be added at runtime.");
		freezetag_Initialize();
	}

	MUTATOR_ONROLLBACK_OR_REMOVE
	{
		// we actually cannot roll back freezetag_Initialize here
		// BUT: we don't need to! If this gets called, adding always
		// succeeds.
	}

	MUTATOR_ONREMOVE
	{
		print("This is a game type and it cannot be removed at runtime.");
		return -1;
	}

	return 0;
}
