float autocvar_g_infection_round_timelimit;
float autocvar_g_infection_warmup;
float autocvar_g_infection_teams;
float autocvar_g_infection_conversions;

float infection_players_count;

.float infectioncolor;
.float infectioncolor_original;

const float INFECTIONTEAM_NONE = -1;
const float INFECTIONTEAM_UNDEFINED = -2;

void infection_SetColor(entity _e, float _color)
{
	_e.infectioncolor = _color;
	setcolor(_e, (_color << 4) | _color);
}

string color_owner_green, color_owner_red;
// find whose color a player is carrying, TRUE if it's his own, otherwise set color_owner_* to the other owner
void infection_GetColorOwner(entity me)
{
	if (me.infectioncolor == me.infectioncolor_original)
	{
		color_owner_green = "^2your own";
		color_owner_red = "^1their own";
		return;
	}
	entity e;
	FOR_EACH_PLAYER(e)
	{
		if (me.infectioncolor == e.infectioncolor_original)
		{
			color_owner_green = strcat(e.netname, "^2's");
			color_owner_red = strcat(e.netname, "^1's");
			break;
		}
	}
}

void infection_Assign(float _late)
{
	entity e;
	if (_late == 0)
	{
		float infection_coloridx = 0;
		FOR_EACH_PLAYER(e)
		{
			if (infection_coloridx < autocvar_g_infection_teams) // Limit alphas
				e.infectioncolor_original = infection_coloridx;
			infection_SetColor(e, infection_coloridx++ % bound(0, autocvar_g_infection_teams, 15));
		}
	}
	else
	{
		// Spawn too late, give player a random color
		float color = 15;
		float skip = random() * (infection_players_count - 1); // Ignore self
		skip = rint(skip);
		entity e;
		FOR_EACH_PLAYER(e)
		{
			if (e == self || IS_OBSERVER(e)) continue;
			if (!skip --> 0) break;
		}
		dprint(strcat("[INFECTION] copying ", e.netname, "'s color\n"));
		color = e.infectioncolor;
		self.infectioncolor_original = INFECTIONTEAM_NONE; // Can't win if player didn't spawn during the round delay
		infection_SetColor(self, color);
    }
}

float infection_CheckTeams()
{
	return infection_players_count > 1;
}

float infection_CheckWinner()
{
	if (infection_players_count <= 1) return FALSE; // There can be no winner

	if (0 < round_handler_GetEndTime() && round_handler_GetEndTime() <= time) // Round over
	{
		Send_Notification(NOTIF_ALL, world, MSG_CENTER, CENTER_ROUND_OVER);
		Send_Notification(NOTIF_ALL, world, MSG_INFO, INFO_ROUND_OVER);
		round_handler_Init(5, autocvar_g_infection_warmup, autocvar_g_infection_round_timelimit);
		return TRUE;
	}

	// Check if only one color remains
	float previnfectioncolor = -1;
	float we_have_a_winner = TRUE; // TRUE until loop below proves us wrong
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

	if (!we_have_a_winner) return FALSE;

	// Who is it?
	FOR_EACH_PLAYER(e)
	{
		if (e.infectioncolor == e.infectioncolor_original)
		{
			UpdateFrags(e, 10); // Bonus points
			Send_Notification(NOTIF_ALL, world, MSG_CENTER, CENTER_ROUND_PLAYER_WIN, e.netname);
			Send_Notification(NOTIF_ALL, world, MSG_INFO, INFO_ROUND_PLAYER_WIN, e.netname);
		}
	}

	round_handler_Init(5, autocvar_g_infection_warmup, autocvar_g_infection_round_timelimit);
	return TRUE;
}

void infection_RoundStart()
{
	infection_Assign(FALSE);
	infection_CheckWinner();
}

void infection_Initialize()
{
	infection_players_count = 0;
	round_handler_Spawn(infection_CheckTeams, infection_CheckWinner, infection_RoundStart);
	round_handler_Init(5, autocvar_g_infection_warmup, autocvar_g_infection_round_timelimit);
}

MUTATOR_HOOKFUNCTION(infection_PlayerDies)
{
	infection_CheckWinner();
	return TRUE;
}

MUTATOR_HOOKFUNCTION(infection_RemovePlayer)
{
	if (!IS_PLAYER(self)) return TRUE; // Wasn't playing

	infection_players_count--;

	self.infectioncolor_original = INFECTIONTEAM_UNDEFINED;

	// Grant alpha status to next of kin
	entity e;
	FOR_EACH_PLAYER(e)
	{
		if (e.infectioncolor == self.infectioncolor_original)
		{
			e.infectioncolor_original = self.infectioncolor;
			centerprint(e, "^2You are now an alpha.\n");
			break;
		}
	}

	infection_CheckWinner();
	return TRUE;
}

MUTATOR_HOOKFUNCTION(infection_PlayerSpawn)
{
	if (self.infectioncolor_original != INFECTIONTEAM_UNDEFINED) return TRUE; // Wasn't observing
	infection_players_count++;

	infection_Assign(TRUE);

	return TRUE;
}

MUTATOR_HOOKFUNCTION(infection_GiveFragsForKill)
{
	frag_score = 0;
	infection_GetColorOwner(frag_attacker);
	// If this is the first time we die... (our infectioncolor remained unchanged)
	if (autocvar_g_infection_conversions && frag_target.infectioncolor == frag_target.infectioncolor_original)
	{
		entity e;
		FOR_EACH_PLAYER(e) // check other players...
		{
			if (e.infectioncolor == frag_target.infectioncolor) // And see if they have our original infection color
			{
				// If so, remove it, our infection color has now "died out" from this round and we can not win anymore.
				// The attacker will "summon" all of our previously fragged targets, and also us.
				centerprint(e, strcat("^1Your alpha ^7", frag_target.netname, "^1 was infected by ^7", frag_attacker.netname, " ^1with ^7", color_owner_red, " ^1color.\n"));
				infection_SetColor(e, frag_attacker.infectioncolor);
				frag_score++;
			}
		}
	}
	else
	{
		infection_SetColor(frag_target, frag_attacker.infectioncolor);
		frag_score++;
	}

	string target = frag_target.netname, attacker = frag_attacker.netname;

	centerprint(frag_attacker, strcat("^2You infected ^7", target, " ^2with ^7", color_owner_green, " ^2color.\n"));
	centerprint(frag_target, strcat("^1You were infected by ^7", attacker, " ^1with ^7", color_owner_red, " ^1color.\n"));

	bprint("^7", frag_target.netname, "^1 was infected by ^7", attacker, " ^1with ^7", color_owner_red, " ^1color.\n");

	return TRUE;
}

MUTATOR_HOOKFUNCTION(infection_PlayerPreThink)
{
	if (IS_PLAYER(self))
	{
		// Prevent cheating by changing player colors
		infection_SetColor(self, round_handler_IsRoundStarted()
			? self.infectioncolor : 15
		);
	}
	return TRUE;
}

MUTATOR_HOOKFUNCTION(infection_PlayerDamage_Calculate)
{
	if (
	(IS_PLAYER(frag_attacker) && frag_attacker.infectioncolor == frag_target.infectioncolor && frag_attacker != frag_target)
	|| (frag_deathtype == DEATH_FALL)
	|| (frag_deathtype == DEATH_DROWN)
	|| (frag_deathtype == DEATH_SLIME)
	|| (frag_deathtype == DEATH_LAVA)
	)
	{
		frag_damage = 0;
		frag_force = '0 0 0';
	}
	return FALSE;
}

MUTATOR_HOOKFUNCTION(infection_BotShouldAttack)
{
	return checkentity.infectioncolor == self.infectioncolor;
}

MUTATOR_HOOKFUNCTION(infection_ClientConnect)
{
	self.infectioncolor_original = INFECTIONTEAM_UNDEFINED;
	stuffcmd(self, "settemp cl_forceplayercolors 0\n");

	return FALSE;
}

MUTATOR_DEFINITION(gamemode_infection)
{
	MUTATOR_HOOK(ClientConnect, infection_ClientConnect, CBC_ORDER_ANY);
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
