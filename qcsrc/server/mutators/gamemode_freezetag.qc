void freezetag_Initialize()
{
	precache_model("models/ice/ice.md3");
	warmup = time + cvar("g_freezetag_warmup");
}

void freezetag_CheckWinner()
{
	if(next_round || (time > warmup - cvar("g_freezetag_warmup") && time < warmup))
		return; // already waiting for next round to start

	if((redalive >= 1 && bluealive >= 1) // counted in arena.qc
		|| (redalive >= 1 && yellowalive >= 1)
		|| (redalive >= 1 && pinkalive >= 1)
		|| (bluealive >= 1 && yellowalive >= 1)
		|| (bluealive >= 1 && pinkalive >= 1)
		|| (yellowalive >= 1 && pinkalive >= 1))
		return; // we still have active players on two or more teams

	if(redalive + bluealive + yellowalive + pinkalive <= 0)
	{
		next_round = time + 5;
		return;
	}

	entity e, winner;
	string teamname;

	FOR_EACH_PLAYER(e)
	{
		if(e.freezetag_frozen == 0 && e.classname == "player" && e.health >= 1) // here's one player from the winning team... good
		{
			winner = e;
			TeamScore_AddToTeam(winner.team, ST_SCORE, +1); // just in case a winner isn't found, we do this already here (causes crashes otherwise...)
			break; // break, we found the winner
		}
	}

	if(winner.team == COLOR_TEAM1)
		teamname = "^1Red Team";
	else if(winner.team == COLOR_TEAM2)
		teamname = "^4Blue Team";
	else if(winner.team == COLOR_TEAM3)
		teamname = "^3Yellow Team";
	else
		teamname = "^6Pink Team";
	FOR_EACH_PLAYER(e) {
		centerprint(e, strcat(teamname, "^5 wins the round, all other teams were frozen.\n"));
	}
	bprint(teamname, "^5 wins the round since all the other teams were frozen.\n");

	next_round = time + 5;
}

void freezetag_Ice_Think()
{
	setorigin(self, self.owner.origin - '0 0 16');
	self.nextthink = time;
}

void freezetag_Freeze()
{
	self.freezetag_frozen = 1;

	entity ice;
	ice = spawn();
	ice.owner = self;
	ice.classname = "freezetag_ice";
	ice.think = freezetag_Ice_Think;
	ice.nextthink = time;
	ice.frame = floor(random() * 21); // ice model has 20 different looking frames
	setmodel(ice, "models/ice/ice.md3");

	self.movement = '0 0 0';

	// add waypoint
	WaypointSprite_Spawn("freezetag_frozen", 0, 0, self, '0 0 64', world, self.team, self, waypointsprite_attached, TRUE);
	if(self.waypointsprite_attached)
	{
		WaypointSprite_UpdateTeamRadar(self.waypointsprite_attached, RADARICON_WAYPOINT, '0.25 0.90 1');
	}
}

void freezetag_Unfreeze()
{
	self.freezetag_frozen = 0;

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

MUTATOR_HOOKFUNCTION(freezetag_RemovePlayer)
{
	freezetag_CheckWinner();
	freezetag_Unfreeze();

	return 1;
}

MUTATOR_HOOKFUNCTION(freezetag_PlayerDies)
{
	// if the player was previously not frozen (should be the case anyway), decrement alive playercount before running CheckWinner
	if (self.team == COLOR_TEAM1 && self.freezetag_frozen == 0) redalive -= 1;
	else if (self.team == COLOR_TEAM2 && self.freezetag_frozen == 0) bluealive -= 1;
	else if (self.team == COLOR_TEAM3 && self.freezetag_frozen == 0) yellowalive -= 1;
	else if (self.team == COLOR_TEAM4 && self.freezetag_frozen == 0) pinkalive -= 1;
	
	freezetag_Freeze();

	centerprint(frag_attacker, strcat("^2You froze ^7", frag_target.netname, ".\n"));
	if(frag_attacker == frag_target || frag_attacker == world)
	{
		centerprint(frag_target, "^1You froze yourself.\n");
		bprint("^7", frag_target.netname, "^1 froze himself.\n");
	}
	else
	{
		centerprint(frag_target, strcat("^1You were frozen by ^7", frag_attacker.netname, ".\n"));
		bprint("^7", frag_target.netname, "^1 was frozen by ^7", frag_attacker.netname, ".\n");
	}

	frag_target.health = cvar("g_balance_health_start"); // "respawn" the player :P

	freezetag_CheckWinner();

	return 1;
}

MUTATOR_HOOKFUNCTION(freezetag_PlayerSpawn)
{
	if(time > warmup) // spawn too late, freeze player
	{
		centerprint(self, "^1You spawned after the round started, you'll spawn as frozen.\n");
		freezetag_Freeze();
	}
	else // we are still in the delay period before the round starts
	{
		freezetag_Unfreeze();
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
	vector revive_extra_size;
	revive_extra_size = '1 1 1' * cvar("g_freezetag_revive_extra_size");

	float teammate_nearby;
	FOR_EACH_PLAYER(other) if(self != other)
	{
		if(other.freezetag_frozen == 0)
		{
			if(other.team == self.team)
			{
				teammate_nearby = boxesoverlap(self.absmin - revive_extra_size, self.absmax + revive_extra_size, other.absmin, other.absmax);
				if(teammate_nearby)
					break;
			}
		}
	}

	if(teammate_nearby && self.freezetag_frozen == 1)
	{
		if(self.freezetag_beginrevive_time == -9999)
		{
			self.freezetag_beginrevive_time = time;
			self.freezetag_revive_progress = 0;
			other.freezetag_revive_progress = 0;
		}
		else
		{
			self.freezetag_revive_progress = (time - self.freezetag_beginrevive_time) / cvar("g_freezetag_revive_time");
			other.freezetag_revive_progress = (time - self.freezetag_beginrevive_time) / cvar("g_freezetag_revive_time");
			if(time - self.freezetag_beginrevive_time >= cvar("g_freezetag_revive_time"))
			{
				freezetag_Unfreeze();

				centerprint(self, strcat("^5You were revived by ^7", other.netname, ".\n"));
				centerprint(other, strcat("^5You revived ^7", self.netname, ".\n"));
				bprint("^7", other.netname, "^5 revived ^7", self.netname, ".\n");

				self.freezetag_beginrevive_time = -9999;
				self.freezetag_revive_progress = 0;
				other.freezetag_revive_progress = 0;
			}
		}
	}
	else
	{
		self.freezetag_beginrevive_time = -9999;
		self.freezetag_revive_progress = 0;
		other.freezetag_revive_progress = 0;
	}

	return 1;
}

MUTATOR_HOOKFUNCTION(freezetag_PlayerPhysics)
{
	if(self.freezetag_frozen)
		self.movement = '0 0 0';
	return 1;
}

MUTATOR_DEFINITION(gamemode_freezetag)
{
	MUTATOR_HOOK(MakePlayerObserver, freezetag_RemovePlayer, CBC_ORDER_ANY);
	MUTATOR_HOOK(ClientDisconnect, freezetag_RemovePlayer, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerDies, freezetag_PlayerDies, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerSpawn, freezetag_PlayerSpawn, CBC_ORDER_ANY);
	MUTATOR_HOOK(GiveFragsForKill, freezetag_GiveFragsForKill, CBC_ORDER_FIRST);
	MUTATOR_HOOK(PlayerPreThink, freezetag_PlayerPreThink, CBC_ORDER_FIRST);
	MUTATOR_HOOK(PlayerPhysics, freezetag_PlayerPhysics, CBC_ORDER_FIRST);

	MUTATOR_ONADD
	{
		if(time > 1) // game loads at time 1
			error("This is a game type and it cannot be added at runtime.");
		g_freezetag = 1;
		freezetag_Initialize();
	}

	MUTATOR_ONREMOVE
	{
		g_freezetag = 0;
		error("This is a game type and it cannot be removed at runtime.");
	}

	return 0;
}
