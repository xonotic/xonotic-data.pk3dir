void freezetag_Initialize()
{
	precache_model("models/ice/ice.md3");
	next_round = time + 5;
}

void freezetag_CheckWinner()
{
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
		if(e.freezetag_frozen == 0) // here's one player from the winning team... good
		{
			winner = e;
			break; // break, we found the winner
		}
	}

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

	next_round = time + 5;
}

void freezetag_Freeze()
{
	self.freezetag_frozen = 1;

	entity tag;
	tag = spawn();
	tag.owner = self;
	tag.classname = "freezetag_ice";
	tag.frame = floor(random() * 21); // ice model has 20 different looking frames
	setmodel(tag, "models/ice/ice.md3");

	setattachment(tag, self, "");

	self.movetype = MOVETYPE_NONE;

	self.movement = '0 0 0';
}

void freezetag_Unfreeze()
{
	self.freezetag_frozen = 0;

	self.movetype = MOVETYPE_WALK;

	// remove the ice block
	entity tag;
	for(tag = world; (tag = find(tag, classname, "freezetag_ice")); ) if(tag.owner == self)
	{
		remove(tag);
		break;
	}
}

MUTATOR_HOOKFUNCTION(freezetag_RemovePlayer)
{
	freezetag_CheckWinner();

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
		centerprint(frag_target, strcat("^1You froze yourself.\n"));
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
	if(redalive + bluealive + yellowalive + pinkalive == 1 && time > warmup)
		next_round = time; // start a new round immediately

	if(time > warmup) // spawn too late, freeze player
	{
		centerprint(self, strcat("^1You spawned after the round started, you'll spawn as frozen.\n"));
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
	if(self.freezetag_frozen)
	{
		// nasty hack, i want them to move around later on as i figure out a better way to block movement TODO TODO TODO !!!
		self.velocity_x = 0;
		self.velocity_y = 0;
		self.velocity_z = min(self.velocity_z, 0);
		self.movement = '0 0 0'; // don't move anywhere :-P
		self.avelocity = '0 0 0';
	}

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
				break;
			}
		}
	}

	if(teammate_nearby && self.freezetag_frozen == 1)
	{
		if(self.freezetag_beginrevive_time == -9999)
		{
			self.freezetag_beginrevive_time = time;
		}
		else
		{
			if(time - self.freezetag_beginrevive_time >= cvar("g_freezetag_revive_time"))
			{
				freezetag_Unfreeze();

				centerprint(self, strcat("^5You were revived by ^7", other.netname, ".\n"));
				centerprint(other, strcat("^5You revived ^7", self.netname, ".\n"));
				bprint("^7", other.netname, "^5 revived ^7", self.netname, ".\n");

				self.freezetag_beginrevive_time = -9999;
			}
		}
	}
	else
	{
		self.freezetag_beginrevive_time = -9999;
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
