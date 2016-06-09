#ifdef IMPLEMENTATION

float autocvar_g_infection_round_timelimit;
float autocvar_g_infection_warmup;
int autocvar_g_infection_teams;
bool autocvar_g_infection_conversions;
bool autocvar_g_infection_mutany;

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
	FOREACH_CLIENT(IS_PLAYER(it) && me.infectioncolor == it.infectioncolor_original, {
        color_owner_green = sprintf("%s^2's", it.netname);
        color_owner_red = sprintf("%s^1's", it.netname);
        break;
	});
}

void infection_Assign(bool late)
{
    SELFPARAM();
	if (!late)
	{
		int infection_coloridx = 0;
		FOREACH_CLIENT(IS_PLAYER(it), {
			if (infection_coloridx < autocvar_g_infection_teams)  // Limit alphas
				it.infectioncolor_original = infection_coloridx;
			infection_SetColor(it, infection_coloridx++ % bound(0, autocvar_g_infection_teams, 15));
		});
	}
	else
	{
		// Spawn too late, give player a random color
		int color = 15;
		int skip = rint(random() * (infection_players_count - 1));  // Ignore self
		entity e = NULL;
		FOREACH_CLIENT(IS_PLAYER(it), {
			if (it == this || IS_OBSERVER(it)) continue;
			if (!skip-- > 0) {
			    e = it;
                break;
			}
		});
		LOG_DEBUGF("[INFECTION] copying %s's color", e.netname);
		color = e.infectioncolor;
		this.infectioncolor_original = INFECTIONTEAM_NONE;  // Can't win if player didn't spawn during the round delay
		infection_SetColor(this, color);
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
	FOREACH_CLIENT(IS_PLAYER(it), {
		// All infection colors are the same if we have a winner
		if (previnfectioncolor != -1 && previnfectioncolor != it.infectioncolor)
		{
			// In this case we still have more than one color alive
			we_have_a_winner = false;
			break;
		}
		previnfectioncolor = it.infectioncolor;
	});

	if (!we_have_a_winner) return false;

	// Who is it?
	FOREACH_CLIENT(IS_PLAYER(it) && it.infectioncolor == it.infectioncolor_original, {
        UpdateFrags(it, 10);  // Bonus points
        Send_Notification(NOTIF_ALL, world, MSG_CENTER, CENTER_ROUND_PLAYER_WIN, it.netname);
        Send_Notification(NOTIF_ALL, world, MSG_INFO, INFO_ROUND_PLAYER_WIN, it.netname);
	});

	round_handler_Init(5, autocvar_g_infection_warmup, autocvar_g_infection_round_timelimit);
	return true;
}

void infection_RoundStart()
{
	infection_Assign(false);
	infection_CheckWinner();
}

bool infection_IsAlpha(entity e)
{
    return e.infectioncolor == e.infectioncolor_original;
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
    SELFPARAM();
	if (!IS_PLAYER(this)) return true;  // Wasn't playing

	infection_players_count--;

	this.infectioncolor_original = INFECTIONTEAM_UNDEFINED;

	// Grant alpha status to next of kin
	FOREACH_CLIENT(IS_PLAYER(it) && it.infectioncolor == this.infectioncolor_original, {
        it.infectioncolor_original = this.infectioncolor;
        centerprint(it, "^2You are now an alpha.\n");
        infection_GetColorOwner(it);
        break;
	});

	// notify all team members
	FOREACH_CLIENT(IS_PLAYER(it) && it.infectioncolor == this.infectioncolor_original && !infection_IsAlpha(it), {
        centerprint(it, sprintf("^2Your alpha is now: ^7%s^2.\n", color_owner_red));
        break;
	});

	infection_CheckWinner();
	return true;
}

MUTATOR_HOOKFUNCTION(inf, PlayerSpawn)
{
    SELFPARAM();
	if (this.infectioncolor_original != INFECTIONTEAM_UNDEFINED) return true;  // Wasn't observing
	infection_players_count++;

	infection_Assign(true);

	return true;
}

MUTATOR_HOOKFUNCTION(inf, GiveFragsForKill, CBC_ORDER_FIRST)
{
	frag_score = 0;
	infection_GetColorOwner(frag_attacker);
	// Check whether this was an act of mutany
	if (autocvar_g_infection_mutany
	    && infection_IsAlpha(frag_target)
	    && INF_SAMETEAM(frag_attacker, frag_target))
    {
        // Mutany! Tell others about this act of shame!
        FOREACH_CLIENT(IS_PLAYER(it) && INF_SAMETEAM(it, frag_target), {
            centerprint(it, sprintf("^1MUTANY! Your alpha ^7%s^1 was killed by his own follower ^7%s^1!\n^7%s^1 is now your new alpha!",
                frag_target.netname, frag_attacker.netname, frag_attacker.netname));
        });

        centerprint(frag_attacker, sprintf("^2You became alpha of your team!"));
        centerprint(frag_target, sprintf("^7%s^1 mutanied against you!", frag_attacker.netname));

        frag_attacker.infectioncolor_original = frag_target.infectioncolor_original;
        frag_target.infectioncolor_original = INFECTIONTEAM_NONE;

        frag_score = -2;
        return true;
	}

	// If this is the first time we die... (our infectioncolor remained unchanged)
	if (autocvar_g_infection_conversions && infection_IsAlpha(frag_target))
	{
	    // check other players and see if they have our original infection color
		FOREACH_CLIENT(IS_PLAYER(it) && INF_SAMETEAM(it, frag_target), {
            // If so, remove it, our infection color has now "died out" from this round and we can not win anymore.
            // The attacker will "summon" all of our previously fragged targets, and also us.
            centerprint(it, sprintf("^1Your alpha ^7%s^1 was infected by ^7%s^1 with ^7%s^1's color.\nYou now belong to ^7%s^1's team!",
                frag_target.netname, frag_attacker.netname, color_owner_red, color_owner_red));
            infection_SetColor(it, frag_attacker.infectioncolor);
            frag_score++;
		});

		frag_target.infectioncolor_original = INFECTIONTEAM_NONE;
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
    SELFPARAM();
	if (IS_PLAYER(this))
	{
		// Prevent cheating by changing player colors
		infection_SetColor(this, round_handler_IsRoundStarted()
			? this.infectioncolor
			: 15);
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
	    if(!infection_IsAlpha(frag_target) || (infection_IsAlpha(frag_target) && !autocvar_g_infection_mutany) ){
		    frag_damage = 0;
		    frag_force = '0 0 0';
		}
	}
	return false;
}

MUTATOR_HOOKFUNCTION(inf, BotShouldAttack)
{
    SELFPARAM();
	return INF_SAMETEAM(checkentity, this);
}

MUTATOR_HOOKFUNCTION(inf, ClientConnect)
{
    SELFPARAM();
	this.infectioncolor_original = INFECTIONTEAM_UNDEFINED;
	stuffcmd(this, "settemp cl_forceplayercolors 0\n");

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
