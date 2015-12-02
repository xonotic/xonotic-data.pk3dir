#ifdef IMPLEMENTATION

float autocvar_g_infection_round_timelimit;
float autocvar_g_infection_warmup;
int autocvar_g_infection_teams;
bool autocvar_g_infection_conversions;

int infection_players_count;

.int infectioncolor;
.int infectioncolor_original;

const int INFECTIONTEAM_NONE = -1;
const int INFECTIONTEAM_UNDEFINED = -2;

// safe team comparisons
#define INF_SAMETEAM(a, b) (a.infectioncolor == b.infectioncolor)
#define INF_DIFFTEAM(a, b) (a.infectioncolor != b.infectioncolor)

void infection_SetColor(entity e, int _color)
{
	e.infectioncolor = _color;
	setcolor(e, (_color << 4) | _color);
}

string color_owner_green, color_owner_red;
// find whose color a player is carrying, true if it's his own, otherwise set color_owner_* to the other owner
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
			color_owner_green = sprintf("%s^2's", e.netname);
			color_owner_red = sprintf("%s^1's", e.netname);
			break;
		}
	}
}

void infection_Assign(bool late)
{
	if (!late)
	{
		int infection_coloridx = 0;
		entity e;
		FOR_EACH_PLAYER(e)
		{
			if (infection_coloridx < autocvar_g_infection_teams)  // Limit alphas
				e.infectioncolor_original = infection_coloridx;
			infection_SetColor(e, infection_coloridx++ % bound(0, autocvar_g_infection_teams, 15));
		}
	}
	else
	{
		// Spawn too late, give player a random color
		int color = 15;
		int skip = rint(random() * (infection_players_count - 1));  // Ignore self
		entity e;
		FOR_EACH_PLAYER(e)
		{
			if (e == self || IS_OBSERVER(e)) continue;
			if (!skip-- > 0) break;
		}
		dprintf("[INFECTION] copying %s's color\n", e.netname);
		color = e.infectioncolor;
		self.infectioncolor_original = INFECTIONTEAM_NONE;  // Can't win if player didn't spawn during the round delay
		infection_SetColor(self, color);
	}
}

bool infection_CheckTeams()
{
	return infection_players_count > 1;
}

bool infection_CheckWinner()
{
	if (infection_players_count <= 1) return false;                           // There can be no winner

	if (0 < round_handler_GetEndTime() && round_handler_GetEndTime() <= time) // Round over
	{
		Send_Notification(NOTIF_ALL, world, MSG_CENTER, CENTER_ROUND_OVER);
		Send_Notification(NOTIF_ALL, world, MSG_INFO, INFO_ROUND_OVER);
		round_handler_Init(5, autocvar_g_infection_warmup, autocvar_g_infection_round_timelimit);
		return true;
	}

	// Check if only one color remains
	int previnfectioncolor = -1;
	bool we_have_a_winner = true;  // until loop below proves us wrong
	entity e;
	FOR_EACH_PLAYER(e)
	{
		// All infection colors are the same if we have a winner
		if (previnfectioncolor != -1 && previnfectioncolor != e.infectioncolor)
		{
			// In this case we still have more than one color alive
			we_have_a_winner = false;
			break;
		}
		previnfectioncolor = e.infectioncolor;
	}

	if (!we_have_a_winner) return false;

	// Who is it?
	FOR_EACH_PLAYER(e)
	{
		if (e.infectioncolor == e.infectioncolor_original)
		{
			UpdateFrags(e, 10);  // Bonus points
			Send_Notification(NOTIF_ALL, world, MSG_CENTER, CENTER_ROUND_PLAYER_WIN, e.netname);
			Send_Notification(NOTIF_ALL, world, MSG_INFO, INFO_ROUND_PLAYER_WIN, e.netname);
		}
	}

	round_handler_Init(5, autocvar_g_infection_warmup, autocvar_g_infection_round_timelimit);
	return true;
}

void infection_RoundStart()
{
	infection_Assign(false);
	infection_CheckWinner();
}

MUTATOR_HOOKFUNCTION(inf, PlayerDies)
{
	infection_CheckWinner();
	return true;
}

bool inf_RemovePlayer();
MUTATOR_HOOKFUNCTION(inf, MakePlayerObserver)
{
	return inf_RemovePlayer();
}
MUTATOR_HOOKFUNCTION(inf, ClientDisconnect)
{
	return inf_RemovePlayer();
}
bool inf_RemovePlayer()
{
	if (!IS_PLAYER(self)) return true;  // Wasn't playing

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
	return true;
}

MUTATOR_HOOKFUNCTION(inf, PlayerSpawn)
{
	if (self.infectioncolor_original != INFECTIONTEAM_UNDEFINED) return true;  // Wasn't observing
	infection_players_count++;

	infection_Assign(true);

	return true;
}

MUTATOR_HOOKFUNCTION(inf, GiveFragsForKill, CBC_ORDER_FIRST)
{
	frag_score = 0;
	infection_GetColorOwner(frag_attacker);
	// If this is the first time we die... (our infectioncolor remained unchanged)
	if (autocvar_g_infection_conversions && frag_target.infectioncolor == frag_target.infectioncolor_original)
	{
		entity e;
		FOR_EACH_PLAYER(e)                    // check other players...
		{
			if (INF_SAMETEAM(e, frag_target)) // And see if they have our original infection color
			{  // If so, remove it, our infection color has now "died out" from this round and we can not win anymore.
				// The attacker will "summon" all of our previously fragged targets, and also us.
				centerprint(e, sprintf("^1Your alpha ^7%s^1 was infected by ^7%s^1 with ^7%s^1 color.\n",
					frag_target.netname, frag_attacker.netname, color_owner_red));
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

	centerprint(frag_attacker, sprintf("^2You infected ^7%s^2 with ^7%s^2 color.\n", target, color_owner_green));
	centerprint(frag_target, sprintf("^1You were infected by ^7%s^1 with ^7%s^1 color.\n", attacker, color_owner_red));

	bprint(sprintf("^7%s^1 was infected by ^7%s^1 with ^7%s^1 color.\n", frag_target.netname, attacker,
		color_owner_red));

	return true;
}

MUTATOR_HOOKFUNCTION(inf, PlayerPreThink, CBC_ORDER_FIRST)
{
	if (IS_PLAYER(self))
	{
		// Prevent cheating by changing player colors
		infection_SetColor(self, round_handler_IsRoundStarted()
			? self.infectioncolor : 15
		                  );
	}
	return true;
}

MUTATOR_HOOKFUNCTION(inf, PlayerDamage_Calculate)
{
	if (IS_PLAYER(frag_attacker)                    // Allow environment damage
	    && frag_attacker != frag_target             // Allow self damage
	    && INF_SAMETEAM(frag_attacker, frag_target) // Block friendly fire
	   )
	{
		frag_damage = 0;
		frag_force = '0 0 0';
	}
	return false;
}

MUTATOR_HOOKFUNCTION(inf, BotShouldAttack)
{
	return INF_SAMETEAM(checkentity, self);
}

MUTATOR_HOOKFUNCTION(inf, ClientConnect)
{
	self.infectioncolor_original = INFECTIONTEAM_UNDEFINED;
	stuffcmd(self, "settemp cl_forceplayercolors 0\n");

	return false;
}

REGISTER_MUTATOR(inf, false)
{
	MUTATOR_ONADD
	{
		if (time > 1)  // game loads at time 1
			error("This is a game type and it cannot be added at runtime.");
		infection_players_count = 0;
		round_handler_Spawn(infection_CheckTeams, infection_CheckWinner, infection_RoundStart);
		round_handler_Init(5, autocvar_g_infection_warmup, autocvar_g_infection_round_timelimit);
	}

	MUTATOR_ONROLLBACK_OR_REMOVE
	{
		// we actually cannot roll back inf_Initialize here
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

#endif
