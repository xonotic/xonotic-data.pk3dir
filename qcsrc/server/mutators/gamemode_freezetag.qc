float freezetag_CheckTeams();
float freezetag_CheckWinner();
void freezetag_Initialize()
{
	precache_model("models/ice/ice.md3");
	ScoreRules_freezetag();

	round_handler_Spawn(freezetag_CheckTeams, freezetag_CheckWinner, 5, autocvar_g_freezetag_warmup);

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

float freezetag_TeamsCanPlay()
{
	if((redalive >= 1 && bluealive >= 1)
		|| (redalive >= 1 && yellowalive >= 1)
		|| (redalive >= 1 && pinkalive >= 1)
		|| (bluealive >= 1 && yellowalive >= 1)
		|| (bluealive >= 1 && pinkalive >= 1)
		|| (yellowalive >= 1 && pinkalive >= 1))
		return 1; // we still have active players on two or more teams, nobody won yet
	return 0;
}

float prev_total_players;
float freezetag_CheckTeams()
{
	entity e;
	if(freezetag_TeamsCanPlay())
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
		teams_missing = substring(teams_missing, 0, strlen(teams_missing)-2);

		FOR_EACH_REALCLIENT(e)
			Send_CSQC_Centerprint_Generic(e, CPID_WAITING_PLAYERS, strcat("Waiting for players to join...\n\nNeed active players for: ", teams_missing), -1, 0);
		prev_total_players = total_players;
	}
	return 0;
}
float freezetag_CheckWinner()
{
	if(freezetag_TeamsCanPlay())
		return 0;

	entity e, winner;
	string teamname;
	winner = world;

	FOR_EACH_PLAYER(e)
	{
		if(e.freezetag_frozen == 0 && e.health >= 1) // here's one player from the winning team... good
		{
			winner = e;
			break; // break, we found the winner
		}
	}

	if(winner != world) // just in case a winner wasn't found
	{
		teamname = ColoredTeamName(winner.team);
		FOR_EACH_REALCLIENT(e)
			centerprint(e, strcat(teamname, "^5 wins the round, all other teams were frozen."));
		bprint(teamname, "^5 wins the round since all the other teams were frozen.\n");
		TeamScore_AddToTeam(winner.team, ST_SCORE, +1);
	}

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
	self.freezetag_revive_progress = 0;
	self.health = 1;
	// if(inWarmupStage)
		// self.freezetag_frozen_timeout = time + 5;

	freezetag_count_alive_players();

	entity ice;
	ice = spawn();
	ice.owner = self;
	ice.classname = "freezetag_ice";
	ice.think = freezetag_Ice_Think;
	ice.nextthink = time;
	ice.frame = floor(random() * 21); // ice model has 20 different looking frames
	setmodel(ice, "models/ice/ice.md3");

	entity oldself;
	oldself = self;
	self = ice;
	freezetag_Ice_Think();
	self = oldself;

	RemoveGrapplingHook(self);

	// add waypoint
	WaypointSprite_Spawn("freezetag_frozen", 0, 0, self, '0 0 64', world, self.team, self, waypointsprite_attached, TRUE, RADARICON_WAYPOINT, '0.25 0.90 1');

	freezetag_Add_Score(attacker);
}

void freezetag_Unfreeze(entity attacker)
{
	self.freezetag_frozen = 0;
	self.freezetag_frozen_timeout = 0;
	self.freezetag_revive_progress = 0;

	// remove the ice block
	entity ice;
	for(ice = world; (ice = find(ice, classname, "freezetag_ice")); ) if(ice.owner == self)
	{
		remove(ice);
		break;
	}

	// remove waypoint
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

MUTATOR_HOOKFUNCTION(freezetag_PlayerPreThink)
{
	float n;
	vector revive_extra_size;

	if(gameover)
		return 1;

	if(self.freezetag_frozen)
	{
		// keep health = 1
		self.pauseregen_finished = time + autocvar_g_balance_pause_health_regen;

		if(self.freezetag_frozen_timeout > 0 && time >= self.freezetag_frozen_timeout)
		{
			self.health = autocvar_g_balance_health_start;
			freezetag_Unfreeze(world);
			freezetag_count_alive_players();
			return 1;
		}
	}

	if(round_handler_IsActive())
	if(!round_handler_IsRoundStarted())
		return 1;

	revive_extra_size = '1 1 1' * autocvar_g_freezetag_revive_extra_size;

	entity o;
	o = world;
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
					++n;
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

			// EVERY team mate nearby gets a point (even if multiple!)
			FOR_EACH_PLAYER(other) if(self != other)
			{
				if(other.freezetag_frozen == 0)
				{
					if(other.team == self.team)
					{
						if(boxesoverlap(self.absmin - revive_extra_size, self.absmax + revive_extra_size, other.absmin, other.absmax))
						{
							PlayerScore_Add(other, SP_FREEZETAG_REVIVALS, +1);
							PlayerScore_Add(other, SP_SCORE, +1);
						}
					}
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

		// now find EVERY teammate within reviving radius, set their revive_progress values correct
		FOR_EACH_PLAYER(other) if(self != other)
		{
			if(other.freezetag_frozen == 0)
			{
				if(other.team == self.team)
				{
					if(boxesoverlap(self.absmin - revive_extra_size, self.absmax + revive_extra_size, other.absmin, other.absmax))
						other.freezetag_revive_progress = self.freezetag_revive_progress;
				}
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
	if(frag_target.freezetag_frozen == 1 && frag_deathtype != DEATH_HURTTRIGGER)
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
