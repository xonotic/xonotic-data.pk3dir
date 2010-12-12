void freezetag_Initialize()
{
	precache_model("models/ice/ice.md3");
	warmup = time + autocvar_g_start_delay + autocvar_g_freezetag_warmup;
}

void freezetag_CheckWinner()
{
	if(time <= game_starttime) // game didn't even start yet! nobody can win in that case.
		return;

	if(next_round || (time > warmup - autocvar_g_freezetag_warmup && time < warmup))
		return; // already waiting for next round to start

	if((redalive >= 1 && bluealive >= 1) // counted in arena.qc
		|| (redalive >= 1 && yellowalive >= 1)
		|| (redalive >= 1 && pinkalive >= 1)
		|| (bluealive >= 1 && yellowalive >= 1)
		|| (bluealive >= 1 && pinkalive >= 1)
		|| (yellowalive >= 1 && pinkalive >= 1))
		return; // we still have active players on two or more teams, nobody won yet

	entity e, winner;
	string teamname;

	FOR_EACH_PLAYER(e)
	{
		if(e.freezetag_frozen == 0 && e.classname == "player" && e.health >= 1) // here's one player from the winning team... good
		{
			winner = e;
			break; // break, we found the winner
		}
	}

	if(winner != world) // just in case a winner wasn't found
	{
		TeamScore_AddToTeam(winner.team, ST_SCORE, +1);
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
	}

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
	if(self.freezetag_frozen == 0)
	{
		if(self.team == COLOR_TEAM1)
			--redalive;
		else if(self.team == COLOR_TEAM2)
			--bluealive;
		else if(self.team == COLOR_TEAM3)
			--yellowalive;
		else if(self.team == COLOR_TEAM4)
			--pinkalive;
		--totalalive;
	}

	if(totalspawned > 2) // only check for winners if we had more than two players (one of them left, don't let the other player win just because of that)
		freezetag_CheckWinner();

	freezetag_Unfreeze();

	return 1;
}

MUTATOR_HOOKFUNCTION(freezetag_PlayerDies)
{
	if(self.freezetag_frozen == 0)
	{
		if(self.team == COLOR_TEAM1)
			--redalive;
		else if(self.team == COLOR_TEAM2)
			--bluealive;
		else if(self.team == COLOR_TEAM3)
			--yellowalive;
		else if(self.team == COLOR_TEAM4)
			--pinkalive;
		--totalalive;

        freezetag_Freeze();
	}

    if(frag_attacker.classname == STR_PLAYER)
        centerprint(frag_attacker, strcat("^2You froze ^7", frag_target.netname, ".\n"));

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
		bprint("^7", frag_target.netname, "^1 was frozen by ^7", frag_attacker.netname, ".\n");
	}

	frag_target.health = autocvar_g_balance_health_start; // "respawn" the player :P

	freezetag_CheckWinner();

	return 1;
}

MUTATOR_HOOKFUNCTION(freezetag_PlayerSpawn)
{
    freezetag_Unfreeze(); // start by making sure that all ice blocks are removed

	if(totalspawned == 1 && time > game_starttime) // only one player active on server, start a new match immediately
	if(!next_round && warmup && (time < warmup - autocvar_g_freezetag_warmup || time > warmup)) // not awaiting next round
	{
		next_round = time;
		return 1;
	}
	if(warmup && time > warmup) // spawn too late, freeze player
	{
		centerprint(self, "^1You spawned after the round started, you'll spawn as frozen.\n");
		freezetag_Freeze();
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
    revive_extra_size = '1 1 1' * autocvar_g_freezetag_revive_extra_size;

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

    if(teammate_nearby && self.freezetag_frozen == 1) // OK, there is at least one teammate reviving us
    {
        if(self.freezetag_beginrevive_time == -9999) // initialize values if this is the first frame of revival
        {
            self.freezetag_beginrevive_time = time;
            self.freezetag_revive_progress = 0;
        }
        else
        {
            self.freezetag_revive_progress = (time - self.freezetag_beginrevive_time) / autocvar_g_freezetag_revive_time;
            if(time - self.freezetag_beginrevive_time >= autocvar_g_freezetag_revive_time)
            {
                freezetag_Unfreeze();

                centerprint(self, strcat("^5You were revived by ^7", other.netname, ".\n"));
                centerprint(other, strcat("^5You revived ^7", self.netname, ".\n"));
                bprint("^7", other.netname, "^5 revived ^7", self.netname, ".\n");

                self.freezetag_beginrevive_time = -9999;
                self.freezetag_revive_progress = 0;
            }
        }
        // now find EVERY teammate within reviving radius, set their revive_progress values correct
        FOR_EACH_PLAYER(other) if(self != other)
        {
            if(other.freezetag_frozen == 0)
            {
                if(other.team == self.team)
                {
                    teammate_nearby = boxesoverlap(self.absmin - revive_extra_size, self.absmax + revive_extra_size, other.absmin, other.absmax);
                    if(teammate_nearby)
                        other.freezetag_revive_progress = self.freezetag_revive_progress;
                }
            }
        }
    }
    else if(!teammate_nearby) // only if no teammate is nearby will we reset
    {
        self.freezetag_beginrevive_time = -9999;
        self.freezetag_revive_progress = 0;
    }

	return 1;
}

MUTATOR_HOOKFUNCTION(freezetag_PlayerPhysics)
{
	if(self.freezetag_frozen)
		self.movement = '0 0 0';
	return 1;
}

MUTATOR_HOOKFUNCTION(freezetag_PlayerDamage_Calculate)
{
    if(g_freezetag)
    {
        if(frag_target.freezetag_frozen == 1 && frag_deathtype != DEATH_HURTTRIGGER)
        {
            frag_damage = 0;
            frag_force = frag_force * autocvar_g_freezetag_frozen_force;
        }
    }
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
	MUTATOR_HOOK(PlayerDamage_Calculate, freezetag_PlayerDamage_Calculate, CBC_ORDER_ANY);

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
