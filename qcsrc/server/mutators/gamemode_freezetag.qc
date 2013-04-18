void freezetag_Initialize()
{
	precache_model("models/ice/ice.md3");
	warmup = time + autocvar_g_start_delay + autocvar_g_freezetag_warmup;
	ScoreRules_freezetag();
}

void freezetag_CheckWinner()
{
	if(time <= game_starttime) // game didn't even start yet! nobody can win in that case.
		return;

	if(next_round || (time > warmup - autocvar_g_freezetag_warmup && time < warmup))
		return; // already waiting for next round to start

	if((redalive >= 1 && bluealive >= 1)
		|| (redalive >= 1 && yellowalive >= 1)
		|| (redalive >= 1 && pinkalive >= 1)
		|| (bluealive >= 1 && yellowalive >= 1)
		|| (bluealive >= 1 && pinkalive >= 1)
		|| (yellowalive >= 1 && pinkalive >= 1))
		return; // we still have active players on two or more teams, nobody won yet

	entity e, winner;
	winner = world;

	FOR_EACH_PLAYER(e)
	{
		if(e.frozen != 1 && e.health >= 1) // here's one player from the winning team... good
		{
			winner = e;
			break; // break, we found the winner
		}
	}

	if(winner != world) // just in case a winner wasn't found
	{
		Send_Notification(NOTIF_ALL, world, MSG_CENTER, APP_TEAM_NUM_4(winner.team, CENTER_FREEZETAG_ROUND_WIN_));
		Send_Notification(NOTIF_ALL, world, MSG_INFO, APP_TEAM_NUM_4(winner.team, INFO_FREEZETAG_ROUND_WIN_));
		TeamScore_AddToTeam(winner.team, ST_SCORE, +1);
	}

	next_round = time + 5;
}

// this is needed to allow the player to turn his view around (fixangle can't
// be used to freeze his view, as that also changes the angles), while not
// turning that ice object with the player
void freezetag_Ice_Think()
{
	setorigin(self, self.owner.origin - '0 0 16');
	self.nextthink = time;
}

void freezetag_Freeze(entity attacker)
{
	if(self.frozen)
		return;
		
	self.health = 1;
	
	Freeze(self, 0, 1, freezetag_revive_progress);
	
	// add waypoint
	WaypointSprite_Spawn("freezetag_frozen", 0, 0, self, '0 0 64', world, self.team, self, waypointsprite_attached, TRUE, RADARICON_WAYPOINT, '0.25 0.90 1');

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
	else
	{
		// nothing - got frozen by the game type rules themselves
	}
}

void freezetag_Unfreeze(entity attacker)
{
	Unfreeze(self, freezetag_revive_progress);

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
			if (head.frozen == 1)
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
		if ((head.team == self.team) && (head.frozen != 1))
			unfrozen++;
	}

	// If only one left on team or if role has timed out then start trying to free players.
	if (((unfrozen == 0) && (self.frozen != 1)) || (time > self.havocbot_role_timeout))
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
	if(self.frozen != 1 && self.health >= 1)
	{
		if(self.team == NUM_TEAM_1)
			--redalive;
		else if(self.team == NUM_TEAM_2)
			--bluealive;
		else if(self.team == NUM_TEAM_3)
			--yellowalive;
		else if(self.team == NUM_TEAM_4)
			--pinkalive;
		--totalalive;
	}

	if(total_players > 2) // only check for winners if we had more than two players (one of them left, don't let the other player win just because of that)
		freezetag_CheckWinner();

	freezetag_Unfreeze(world);

	return 1;
}

MUTATOR_HOOKFUNCTION(freezetag_PlayerDies)
{
	if(self.frozen != 1)
	{
		if(self.team == NUM_TEAM_1)
			--redalive;
		else if(self.team == NUM_TEAM_2)
			--bluealive;
		else if(self.team == NUM_TEAM_3)
			--yellowalive;
		else if(self.team == NUM_TEAM_4)
			--pinkalive;
		--totalalive;

		freezetag_Freeze(frag_attacker);
	}

	if(frag_attacker == frag_target || frag_attacker == world)
	{
		if(frag_target.classname == STR_PLAYER)
			Send_Notification(NOTIF_ONE, frag_target, MSG_CENTER, CENTER_FREEZETAG_SELF);
		Send_Notification(NOTIF_ALL, world, MSG_INFO, INFO_FREEZETAG_SELF, frag_target.netname);
	}
	else
	{
		if(frag_target.classname == STR_PLAYER)
			Send_Notification(NOTIF_ONE, frag_target, MSG_CENTER, CENTER_FREEZETAG_FROZEN, frag_attacker.netname);
		if(frag_attacker.classname == STR_PLAYER)
			Send_Notification(NOTIF_ONE, frag_attacker, MSG_CENTER, CENTER_FREEZETAG_FREEZE, frag_target.netname);
		Send_Notification(NOTIF_ALL, world, MSG_INFO, INFO_FREEZETAG_FREEZE, frag_target.netname, frag_attacker.netname);
	}

	frag_target.health = 1; // "respawn" the player :P

	freezetag_CheckWinner();

	return 1;
}

MUTATOR_HOOKFUNCTION(freezetag_PlayerSpawn)
{
	freezetag_Unfreeze(world); // start by making sure that all ice blocks are removed

	if(total_players == 1 && time > game_starttime) // only one player active on server, start a new match immediately
	if(!next_round && warmup && (time < warmup - autocvar_g_freezetag_warmup || time > warmup)) // not awaiting next round
	{
		next_round = time;
		return 1;
	}
	if(warmup && time > warmup) // spawn too late, freeze player
	{
		Send_Notification(NOTIF_ONE, self, MSG_CENTER, CENTER_FREEZETAG_SPAWN_LATE);
		freezetag_Freeze(world);
	}

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

	revive_extra_size = '1 1 1' * autocvar_g_freezetag_revive_extra_size;	
	
	entity o;
	o = world;
	n = 0;
	FOR_EACH_PLAYER(other) if(self != other)
	{
		if(other.frozen != 1)
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

	if(n && self.frozen == 1) // OK, there is at least one teammate reviving us
	{
		self.freezetag_revive_progress = bound(0, self.freezetag_revive_progress + frametime * autocvar_g_freezetag_revive_speed, 1);
		self.health = max(1, self.freezetag_revive_progress * autocvar_g_balance_health_start);

		if(self.freezetag_revive_progress >= 1)
		{
			freezetag_Unfreeze(self);

			// EVERY team mate nearby gets a point (even if multiple!)
			FOR_EACH_PLAYER(other) if(self != other)
			{
				if(other.frozen != 1)
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

			Send_Notification(NOTIF_ONE, self, MSG_CENTER, CENTER_FREEZETAG_REVIVED, o.netname);
			Send_Notification(NOTIF_ONE, o, MSG_CENTER, CENTER_FREEZETAG_REVIVE, self.netname);
			Send_Notification(NOTIF_ALL, world, MSG_INFO, INFO_FREEZETAG_REVIVE, self.netname, o.netname);
		}

		// now find EVERY teammate within reviving radius, set their revive_progress values correct
		FOR_EACH_PLAYER(other) if(self != other)
		{
			if(other.frozen != 1)
			{
				if(other.team == self.team)
				{
					if(boxesoverlap(self.absmin - revive_extra_size, self.absmax + revive_extra_size, other.absmin, other.absmax))
						other.freezetag_revive_progress = self.freezetag_revive_progress;
				}
			}
		}
	}
	else if(!n && self.frozen == 1) // only if no teammate is nearby will we reset
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

MUTATOR_HOOKFUNCTION(freezetag_PlayerDamage_Calculate)
{
    if(g_freezetag)
    {
        if(frag_target.frozen == 1 && frag_deathtype != DEATH_HURTTRIGGER)
        {
            frag_damage = 0;
            frag_force = frag_force * autocvar_g_freezetag_frozen_force;
        }
    }
    return 1;
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

MUTATOR_DEFINITION(gamemode_freezetag)
{
	MUTATOR_HOOK(MakePlayerObserver, freezetag_RemovePlayer, CBC_ORDER_ANY);
	MUTATOR_HOOK(ClientDisconnect, freezetag_RemovePlayer, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerDies, freezetag_PlayerDies, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerSpawn, freezetag_PlayerSpawn, CBC_ORDER_ANY);
	MUTATOR_HOOK(GiveFragsForKill, freezetag_GiveFragsForKill, CBC_ORDER_FIRST);
	MUTATOR_HOOK(PlayerPreThink, freezetag_PlayerPreThink, CBC_ORDER_FIRST);
	MUTATOR_HOOK(PlayerDamage_Calculate, freezetag_PlayerDamage_Calculate, CBC_ORDER_ANY);
	MUTATOR_HOOK(HavocBot_ChooseRule, freezetag_BotRoles, CBC_ORDER_ANY);

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
