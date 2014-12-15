#define INFECTIONCOLOR_MAX 16

entity infection_players[INFECTIONCOLOR_MAX];
float infection_players_count;
float next_round;

void infection_Initialize()
{
	float i;
	for(i = 0; i < INFECTIONCOLOR_MAX; ++i)
	{
		infection_players[i] = world;
	}
	next_round = time + 5;
}

void infection_CheckWinner()
{
	// Check if only one color remains
	float i, previnfectioncolor, we_have_a_winner;
	entity e;
	we_have_a_winner = TRUE; // TRUE until below loop proves us wrong
	entity winner = world; //?
	previnfectioncolor = FALSE;

	float temp_infection_players_count;
	temp_infection_players_count = infection_players_count;

	for(i = 0; i < temp_infection_players_count; ++i)
	{
		e = infection_players[i];
		if(e == world) // empty slot, skip to next
		{
			if(temp_infection_players_count < INFECTIONCOLOR_MAX - 1) // just in case
				++temp_infection_players_count; // keep on searching for one additional since this was empty
			continue;
		}

		if(i > 0)
		{
			if(previnfectioncolor != e.infectioncolor) // all infection colors are the same if we have a winner, in this case we still have more than one color alive
			{
				we_have_a_winner = FALSE;
				break;
			}
		}

		previnfectioncolor = e.infectioncolor;
	}

	if(we_have_a_winner)
	{
		temp_infection_players_count = infection_players_count;
		for(i = 0; i < temp_infection_players_count; ++i)
		{
			e = infection_players[i];
			if(e == world) // empty slot, skip to next
			{
				if(temp_infection_players_count < INFECTIONCOLOR_MAX - 1) // just in case
					++temp_infection_players_count;
				continue;
			}

			if(e.infectioncolor == e.infectioncolor_original) // here's our winner :)
			{
				winner = e;
				break; // break, we found the winner
			}
		}

		if(winner.netname != "" && infection_players_count > 1)
		{
			UpdateFrags(winner, +1);

			FOR_EACH_PLAYER(e)
			{
				centerprint(e, strcat(winner.netname, "^1 wins the round since their color survived.\n"));
			}
			bprint(winner.netname, "^1 wins the round since their color survived.\n");
		}

		next_round = time + 5;
	}
}

string color_owner_green, color_owner_red;
float color_owner_self;
// find whose color your attacker is carrying, set color_owner_self to 1 if it's his own, otherwise set color_owner_* to the other owner
#define infection_GetFragAttackers_ColorOwner()\
{\
	float j;\
	entity get_frag_attacker_temp;\
	temp_infection_players_count = infection_players_count;\
	color_owner_self = 0;\
	for(j = 0; j < temp_infection_players_count; ++j)\
	{\
		get_frag_attacker_temp = infection_players[j];\
		if(get_frag_attacker_temp == world)\
		{\
			if(temp_infection_players_count < INFECTIONCOLOR_MAX - 1)\
				++temp_infection_players_count;\
			continue;\
		}\
		if(get_frag_attacker_temp.infectioncolor_original == frag_attacker.infectioncolor_original)\
		{\
			color_owner_self = 1;\
			break;\
		}\
		else if(get_frag_attacker_temp.infectioncolor_original == frag_attacker.infectioncolor)\
		{\
			color_owner_green = strcat(get_frag_attacker_temp.netname, "^2's");\
			color_owner_red = strcat(get_frag_attacker_temp.netname, "^1's");\
			break;\
		}\
	}\
} ENDS_WITH_CURLY_BRACE

MUTATOR_HOOKFUNCTION(infection_PlayerDies)
{
	float i;
	entity e;

	float temp_infection_players_count;
	temp_infection_players_count = infection_players_count;

	if(frag_target.infectioncolor == frag_target.infectioncolor_original) // if this is the first time we die... (our infectioncolor remained unchanged)
	{
		for(i = 0; i < temp_infection_players_count; ++i) // check other players...
		{
			e = infection_players[i];
			if(e == world) // empty slot, skip to next
			{
				if(temp_infection_players_count < INFECTIONCOLOR_MAX - 1) // just in case
					++temp_infection_players_count;
				continue;
			}

			if(e.infectioncolor == frag_target.infectioncolor_original) // and see if they have our original infection color
			{
				infection_GetFragAttackers_ColorOwner();
				centerprint(e, strcat("^1Your master ^7", frag_target.netname, "^1 was infected by ^7", frag_attacker.netname, " ^1with ^7", color_owner_red, " ^1color.\n"));
				e.infectioncolor = frag_attacker.infectioncolor; // if so, remove it, our infection color has now "died out" from this round and we can not win anymore. The attacker will "summon" all of our previously fragged targets, and also us.
				setcolor(e, 16 * e.infectioncolor + e.infectioncolor);
			}
		}
	}
	else
	{
		frag_target.infectioncolor = frag_attacker.infectioncolor;
		setcolor(frag_target, 16 * frag_target.infectioncolor + frag_target.infectioncolor);
	}

	infection_GetFragAttackers_ColorOwner();

	if(color_owner_self)
		color_owner_green = "^2your own";
	centerprint(frag_attacker, strcat("^2You infected ^7", frag_target.netname, " ^2with ^7", color_owner_green, " ^2color.\n"));

	if(color_owner_self)
		color_owner_red = "^1their own";
	centerprint(frag_target, strcat("^1You were infected by ^7", frag_attacker.netname, " ^1with ^7", color_owner_red, " ^1color.\n"));
	bprint("^7", frag_target.netname, "^1 was infected by ^7", frag_attacker.netname, " ^1with ^7", color_owner_red, " ^1color.\n");

	frag_target.health = cvar("g_balance_health_start"); // "respawn" the player :P

	infection_CheckWinner();

	return 1;
}

MUTATOR_HOOKFUNCTION(infection_RemovePlayer)
{
	if(self.infection_playernum == -1)
		return 0; // nothing to remove

	float i, j;
	/*for (i = self.infection_playernum; i < infection_players_count; ++i)
	{
		infection_players[i] = infection_players[i+1];
		infection_players[i].infection_playernum = infection_players[i].infection_playernum - 1;
	}
	*/

	infection_players[self.infection_playernum] = world;
	infection_players_count = infection_players_count - 1;

	// if other players have our color, randomize their color
	entity e;
	float temp_infection_players_count;
	temp_infection_players_count = infection_players_count;

	if(!next_round) // ... but ONLY if next_round isn't set. We don't care about the colors if the round has already ended
	for(i = 0; i < temp_infection_players_count; ++i) // check other players...
	{
		e = infection_players[i];
		if(e == world) // empty slot, skip to next
		{
			if(temp_infection_players_count < INFECTIONCOLOR_MAX - 1) // just in case
				++temp_infection_players_count;
			continue;
		}

		if(e.infectioncolor == self.infectioncolor_original) // and see if they have our original infection color
		{
			entity random_player = world;
			
			for(j = 0; j < 100; ++j) // try 100 times to find a color that isn't the same as our color. If this fails we are either damn unlucky, or there are really only players left of our color
			{
				random_player = infection_players[floor(random() * (INFECTIONCOLOR_MAX - 1))];

				if(random_player == world) // hit empty slot, try again
					continue;

				if(random_player.infectioncolor != self.infectioncolor_original) // break if we found another color
				{
					break;
				}
			}
			e.infectioncolor = random_player.infectioncolor;
			setcolor(e, 16 * e.infectioncolor + e.infectioncolor);
		}
	}

	self.infection_playernum = -1;

	if(infection_players_count > 1 && time > autocvar_g_infection_delay_round)
		infection_CheckWinner();

	return 1;
}

MUTATOR_HOOKFUNCTION(infection_PlayerSpawn)
{
	float i;
	if(infection_players_count == 1 && time > autocvar_g_infection_delay_round)
		next_round = time; // start a new round immediately

	if(infection_players_count + 1 >= INFECTIONCOLOR_MAX)
	{
		bprint("^1Sorry, only ", ftos(INFECTIONCOLOR_MAX), " players can play infection at once.");
		return 0;
	}

	if(self.infection_playernum == -1) // only add if we don't have a infection_playernum
	{
		// add player to the players array, give him a playernum
		for(i = 0; i <= infection_players_count; ++i) // <= because we might not find any empty slots until then, and in that case we need a new slot
		{
			if(infection_players[i] == world) // empty slot, give player this slot
			{
				self.infection_playernum = i;
				break;
			}
		}
		infection_players[i] = self;
		infection_players_count = infection_players_count + 1;
	}

	if(time > autocvar_g_infection_delay_round) // spawn too late, give player a random color
	{
		entity random_player = world;
		
		for(i = 0; i < 100; ++i) // try 100 times to find a color that isn't the same as our color. If this fails we are either damn unlucky, or there are really only players left of our color
		{
			random_player = infection_players[floor(random() * (INFECTIONCOLOR_MAX - 1))];

			if(random_player == world) // hit empty slot, try again
				continue;

			if(random_player.infectioncolor != self.infectioncolor_original) // break if we found another color
			{
				break;
			}
		}

		self.infectioncolor = random_player.infectioncolor;
		self.infectioncolor_original = -1; // can't win if player didn't spawn during the round delay
	}
	else // we are still in the delay period before the round starts
	{
		self.infectioncolor = self.infection_playernum;
		self.infectioncolor_original = self.infectioncolor;
	}
	setcolor(self, 16 * self.infectioncolor + self.infectioncolor);

	return 1;
}

MUTATOR_HOOKFUNCTION(infection_GiveFragsForKill)
{
	frag_score = 0; // no frags counted in infection, maybe later (TODO)
	return 1;
}

MUTATOR_HOOKFUNCTION(infection_PlayerPreThink)
{
	setcolor(self, 16 * self.infectioncolor + self.infectioncolor); // prevent cheating by changing player colors
	return 1;
}

MUTATOR_HOOKFUNCTION(infection_PlayerDamage_Calculate)
{
    if ((frag_attacker.infectioncolor == frag_target.infectioncolor && frag_attacker != frag_target) || (frag_deathtype == DEATH_FALL) || (frag_deathtype == DEATH_DROWN) || (frag_deathtype == DEATH_SLIME) || (frag_deathtype == DEATH_LAVA))
    {
        frag_damage = 0;
        frag_force = '0 0 0';
    }
    return 1;
}

MUTATOR_DEFINITION(gamemode_infection)
{
	MUTATOR_HOOK(MakePlayerObserver, infection_RemovePlayer, CBC_ORDER_ANY);
	MUTATOR_HOOK(ClientDisconnect, infection_RemovePlayer, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerDies, infection_PlayerDies, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerSpawn, infection_PlayerSpawn, CBC_ORDER_ANY);
	MUTATOR_HOOK(GiveFragsForKill, infection_GiveFragsForKill, CBC_ORDER_FIRST);
	MUTATOR_HOOK(PlayerPreThink, infection_PlayerPreThink, CBC_ORDER_FIRST);
	MUTATOR_HOOK(PlayerDamage_Calculate, infection_PlayerDamage_Calculate, CBC_ORDER_ANY);

	MUTATOR_ONADD
	{
		if(time > 1) // game loads at time 1
			error("This is a game type and it cannot be added at runtime.");
		//g_infection = 1;
		infection_Initialize();
	}

	MUTATOR_ONREMOVE
	{
		//g_infection = 0;
		error("This is a game type and it cannot be removed at runtime.");
		return -1;
	}

	return 0;
}
