float infection_players_count = 0;
float infection_coloridx;

float next_round;

.float infection_jointime;
.float infectioncolor;
.float infectioncolor_original;

void infection_SetColor(entity e, float _color)
{
	setcolor(e, (_color << 4) | _color);
}

void infection_Initialize()
{
	infection_coloridx = 0;
	next_round = time + autocvar_g_infection_delay_round;
}

void infection_CheckWinner()
{
	if (infection_players_count <= 1) return; // There can be no winner

	// Check if only one color remains
	float previnfectioncolor = -1;
	float we_have_a_winner = TRUE; // TRUE until below loop proves us wrong
	entity e;
	FOR_EACH_PLAYER(e)
	{
		// All infection colors are the same if we have a winner
		if (previnfectioncolor != -1 && previnfectioncolor != e.infectioncolor)
		{
			// In this case we still have more than one color alive
			we_have_a_winner = FALSE;
			break;
		}
		previnfectioncolor = e.infectioncolor;
	}

	if (!we_have_a_winner) return;

	// Who is it?
	entity winner = world;
	FOR_EACH_PLAYER(e)
	{
		if (e.infectioncolor == e.infectioncolor_original)
		{
			winner = e;
			break;
		}
	}

	if (winner.netname)
	{
		UpdateFrags(winner, 1);

		FOR_EACH_PLAYER(e)
		{
			centerprint(e, strcat(winner.netname, "^1 wins the round since their color survived.\n"));
		}
		bprint(winner.netname, "^1 wins the round since their color survived.\n");
	}

	infection_Initialize();
}

string color_owner_green, color_owner_red;
// find whose color your attacker is carrying, TRUE if it's his own, otherwise set color_owner_* to the other owner
float infection_GetColorOwner(entity me)
{
	entity e;
	FOR_EACH_PLAYER(e)
	{
		if (e.infectioncolor_original == me.infectioncolor_original)
		{
			return TRUE;
		}
		else if (e.infectioncolor_original == me.infectioncolor)
		{
			color_owner_green = strcat(e.netname, "^2's");
			color_owner_red = strcat(e.netname, "^1's");
			break;
		}
	}
	return FALSE;
}

MUTATOR_HOOKFUNCTION(infection_PlayerDies)
{
	// If this is the first time we die... (our infectioncolor remained unchanged)
	if (frag_target.infectioncolor == frag_target.infectioncolor_original)
	{
		infection_GetColorOwner(frag_attacker);
		entity e;
		FOR_EACH_PLAYER(e) // check other players...
		{
			if (e.infectioncolor == frag_target.infectioncolor) // And see if they have our original infection color
			{
				// If so, remove it, our infection color has now "died out" from this round and we can not win anymore.
				// The attacker will "summon" all of our previously fragged targets, and also us.
				centerprint(e, strcat("^1Your master ^7", frag_target.netname, "^1 was infected by ^7", frag_attacker.netname, " ^1with ^7", color_owner_red, " ^1color.\n"));
				e.infectioncolor = frag_attacker.infectioncolor;
				infection_SetColor(e, e.infectioncolor);
			}
		}
	}
	else
	{
		frag_target.infectioncolor = frag_attacker.infectioncolor;
		infection_SetColor(frag_target, frag_target.infectioncolor);
	}

	if (infection_GetColorOwner(frag_attacker))
	{
		color_owner_green = "^2your own";
		color_owner_red = "^1their own";
	}
	centerprint(frag_attacker, strcat("^2You infected ^7", frag_target.netname, " ^2with ^7", color_owner_green, " ^2color.\n"));
	centerprint(frag_target, strcat("^1You were infected by ^7", frag_attacker.netname, " ^1with ^7", color_owner_red, " ^1color.\n"));

	bprint("^7", frag_target.netname, "^1 was infected by ^7", frag_attacker.netname, " ^1with ^7", color_owner_red, " ^1color.\n");

	frag_target.health = cvar("g_balance_health_start"); // "respawn" the player

	infection_CheckWinner();

	return TRUE;
}

MUTATOR_HOOKFUNCTION(infection_RemovePlayer)
{
	if (!self.infection_jointime)
		return FALSE; // nothing to remove

	infection_players_count--;

	// if other players have our color, randomize their color
	// ... but ONLY if next_round isn't set. We don't care about the colors if the round has already ended
	if (!time < next_round)
	{
		entity e;
		FOR_EACH_PLAYER(e) // check other players...
		{
			if (e.infectioncolor == self.infectioncolor_original) // and see if they have our original infection color
			{
				e.infectioncolor_original = self.infectioncolor;
				centerprint(frag_attacker, "^2You are now a master.\n");
				break;
			}
		}
	}

	if (infection_players_count > 1 && time >= next_round)
		infection_CheckWinner();

	return TRUE;
}

MUTATOR_HOOKFUNCTION(infection_PlayerSpawn)
{
	if (self.infection_jointime) return TRUE; // only add if we don't have a infection_jointime
	self.infection_jointime = time;
	if (++infection_players_count > 1 && time >= next_round)
		next_round = time + autocvar_g_infection_delay_round; // start a new round immediately

	if (time >= next_round) // spawn too late, give player a random color
	{
		float skip = floor(random() * infection_players_count);
		entity e;
		FOR_EACH_PLAYER(e)
		{
			if (skip--) continue;
			self.infectioncolor = e.infectioncolor;
			self.infectioncolor_original = -1; // can't win if player didn't spawn during the round delay
		}
	}
	else // we are still in the delay period before the round starts
	{
		self.infectioncolor = infection_coloridx++;
		self.infectioncolor_original = self.infectioncolor;
	}
	infection_SetColor(self, self.infectioncolor);

	return TRUE;
}

MUTATOR_HOOKFUNCTION(infection_GiveFragsForKill)
{
	frag_score = 0; // TODO: no frags counted in infection, maybe later
	return TRUE;
}

MUTATOR_HOOKFUNCTION(infection_PlayerPreThink)
{
	infection_SetColor(self, self.infectioncolor); // prevent cheating by changing player colors
	return TRUE;
}

MUTATOR_HOOKFUNCTION(infection_PlayerDamage_Calculate)
{
	if (
	(frag_attacker.infectioncolor == frag_target.infectioncolor && frag_attacker != frag_target)
	|| (frag_deathtype == DEATH_FALL)
	|| (frag_deathtype == DEATH_DROWN)
	|| (frag_deathtype == DEATH_SLIME)
	|| (frag_deathtype == DEATH_LAVA)
	)
	{
		frag_damage = 0;
		frag_force = '0 0 0';
	}
	return TRUE;
}

MUTATOR_HOOKFUNCTION(infection_BotShouldAttack)
{
	return checkentity.infectioncolor == self.infectioncolor; // FIXME: Has reverse meaning
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
	MUTATOR_HOOK(BotShouldAttack, infection_BotShouldAttack, CBC_ORDER_ANY);

	MUTATOR_ONADD
	{
		if (time > 1) // game loads at time 1
			error("This is a game type and it cannot be added at runtime.");
		infection_Initialize();
	}

	MUTATOR_ONROLLBACK_OR_REMOVE
	{
	}

	MUTATOR_ONREMOVE
	{
		error("This is a game type and it cannot be removed at runtime.");
		return -1;
	}

	return 0;
}
