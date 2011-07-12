float maxspawned;
float numspawned;
float arena_roundbased;
.float spawned;
.entity spawnqueue_next;
.entity spawnqueue_prev;
.float spawnqueue_in;
entity spawnqueue_first;
entity spawnqueue_last;
entity champion;
string champion_name;
float warmup;
float ca_players;
float required_ca_players;
.float caplayer;

void PutObserverInServer();
void PutClientInServer();
void(entity e) ReturnFlag;
void dom_controlpoint_setup();
void onslaught_generator_reset();
void onslaught_controlpoint_reset();
void func_breakable_reset();
void assault_objective_reset();
void target_assault_roundend_reset();

float next_round;
float stopalivecheck;
float redalive, bluealive, yellowalive, pinkalive;
float totalalive;
.float redalive_stat, bluealive_stat, yellowalive_stat, pinkalive_stat;
float redspawned, bluespawned, yellowspawned, pinkspawned;
float totalspawned;

/**
 * Resets the state of all clients, items, flags, runes, keys, weapons, waypoints, ... of the map.
 * Sets the 'warmup' global variable.
 */
void reset_map(float dorespawn)
{
	entity oldself;
	oldself = self;

	if(g_arena && autocvar_g_arena_warmup)
		warmup = time + autocvar_g_arena_warmup;
	else if(g_ca) {
		warmup = time + autocvar_g_ca_warmup;
		allowed_to_spawn = 1;
	}
	else if(g_freezetag)
	{
		warmup = time + autocvar_g_freezetag_warmup;
	}

	lms_lowest_lives = 999;
	lms_next_place = player_count;

	race_ReadyRestart();

	for(self = world; (self = nextent(self)); )
	if(clienttype(self) == CLIENTTYPE_NOTACLIENT && self.items != IT_STRENGTH && self.items != IT_INVINCIBLE) // don't respawn strength or shield, that will only lead to them spawning very early each match
	{
		if(self.reset)
		{
			self.reset();
			continue;
		}

		if(self.team_saved)
			self.team = self.team_saved;

		if(self.flags & FL_PROJECTILE) // remove any projectiles left
			remove(self);
	}

	// Waypoints and assault start come LAST
	for(self = world; (self = nextent(self)); )
	if(clienttype(self) == CLIENTTYPE_NOTACLIENT)
	{
		if(self.reset2)
		{
			self.reset2();
			continue;
		}
	}

	// Moving the player reset code here since the player-reset depends
	// on spawnpoint entities which have to be reset first --blub
	if(dorespawn)
	FOR_EACH_CLIENT(self) {
		if(self.flags & FL_CLIENT)				// reset all players
		{
			if(g_arena)
			{
				if(self.spawned)
					PutClientInServer();
				else
					PutObserverInServer();
			}
			else if(g_ca && self.caplayer) {
				self.classname = "player";
				PutClientInServer();
			}
			else if(g_freezetag)
			{
				if(self.classname == "player")
					PutClientInServer();
			}
			else
			{
				/*
				only reset players if a restart countdown is active
				this can either be due to cvar sv_ready_restart_after_countdown having set
				restart_mapalreadyrestarted to 1 after the countdown ended or when
				sv_ready_restart_after_countdown is not used and countdown is still running
				*/
				if (restart_mapalreadyrestarted || (time < game_starttime))
				{
					//NEW: changed behaviour so that it prevents that previous spectators/observers suddenly spawn as players
					if (self.classname == "player") {
						//PlayerScore_Clear(self);
						if(g_lms)
							PlayerScore_Add(self, SP_LMS_LIVES, LMS_NewPlayerLives());
						self.killcount = 0;
						//stop the player from moving so that he stands still once he gets respawned
						self.velocity = '0 0 0';
						self.avelocity = '0 0 0';
						self.movement = '0 0 0';
						PutClientInServer();
					}
				}
			}
		}
	}

	if(g_keyhunt)
		kh_Controller_SetThink(autocvar_g_balance_keyhunt_delay_round+(game_starttime - time), "", kh_StartRound);

	if(g_arena)
	if(champion && champion.classname == "player" && player_count > 1)
		UpdateFrags(champion, +1);

	self = oldself;
}

void Spawnqueue_Insert(entity e)
{
	if(e.spawnqueue_in)
		return;
	dprint(strcat("Into queue: ", e.netname, "\n"));
	e.spawnqueue_in = TRUE;
	e.spawnqueue_prev = spawnqueue_last;
	e.spawnqueue_next = world;
	if(spawnqueue_last)
		spawnqueue_last.spawnqueue_next = e;
	spawnqueue_last = e;
	if(!spawnqueue_first)
		spawnqueue_first = e;
}

void Spawnqueue_Remove(entity e)
{
	if(!e.spawnqueue_in)
		return;
	dprint(strcat("Out of queue: ", e.netname, "\n"));
	e.spawnqueue_in = FALSE;
	if(e == spawnqueue_first)
		spawnqueue_first = e.spawnqueue_next;
	if(e == spawnqueue_last)
		spawnqueue_last = e.spawnqueue_prev;
	if(e.spawnqueue_prev)
		e.spawnqueue_prev.spawnqueue_next = e.spawnqueue_next;
	if(e.spawnqueue_next)
		e.spawnqueue_next.spawnqueue_prev = e.spawnqueue_prev;
	e.spawnqueue_next = world;
	e.spawnqueue_prev = world;
}

void Spawnqueue_Unmark(entity e)
{
	if(!e.spawned)
		return;
	e.spawned = FALSE;
	numspawned = numspawned - 1;
}

void Spawnqueue_Mark(entity e)
{
	if(e.spawned)
		return;
	e.spawned = TRUE;
	numspawned = numspawned + 1;
}

/**
 * If roundbased arena game mode is active, it centerprints the texts for the
 * player when player is waiting for the countdown to finish.
 * Blocks the players movement while countdown is active.
 * Unblocks the player once the countdown is over.
 *
 * Called in PlayerPostThink()
 */
float roundStartTime_prev; // prevent networkspam
void Arena_Warmup()
{
	float f;
	string msg;
    entity e;

	if((!g_arena && !g_ca && !g_freezetag) || (g_arena && !arena_roundbased) || (time < game_starttime))
		return;

	f = ceil(warmup - time);
	if(f > 0)
		champion = world; // this is done because a if(champion) will not execute if champion = world

	allowed_to_spawn = 0;

	if(inWarmupStage)
		allowed_to_spawn = 1;
	if(ca_players < required_ca_players)
		allowed_to_spawn = 1;

	msg = NEWLINES;
	if(time < warmup && !inWarmupStage)
	{
		if (g_ca)
			allowed_to_spawn = 1;
		if(champion && g_arena)
			msg = strcat("The Champion is ", champion_name, "^7\n");
			//centerprint(self, strcat(msg, "The Champion is ", champion.netname, "^7\n"));

		if(f != roundStartTime_prev) {
			msg = strcat(msg, "Round will start in ", ftos(f),"\n");
			//centerprint(self, strcat("Round will start in ", ftos(f),"\n"));
			roundStartTime_prev = f;
			if(f == 5)
				Announce("prepareforbattle");
			else if(f == 3)
				Announce("3");
			else if(f == 2)
				Announce("2");
			else if(f == 1)
				Announce("1");

            FOR_EACH_PLAYER(e)
                centerprint(e, msg);
		}

		if (g_arena) {
			if(self.spawned && self.classname == "player")
				self.movetype = MOVETYPE_NONE;

			self.velocity = '0 0 0';
			self.avelocity = '0 0 0';
			self.movement = '0 0 0';
		}
	}

	else if(f > -1 && f != roundStartTime_prev)
	{
		roundStartTime_prev = f;
		Announce("begin");
		centerprint(self, "^1Begin!\n");

		if(g_ca) {
			ca_players = 0;

            FOR_EACH_PLAYER(e)
				ca_players += 1;
		}

        if(self.classname == "player" && self.health > 0 && self.movetype == MOVETYPE_NONE)
            self.movetype = MOVETYPE_WALK;
	}
}

void count_spawned_players()
{
	// TODO fix "*spawned" name, it should rather be "*players" or so
	// not doing this now to prevent merge hell with Tag
	// fix after merging with Tag

	// count amount of players in each team
	totalspawned = redspawned = bluespawned = yellowspawned = pinkspawned = 0;
	FOR_EACH_PLAYER(self) {
		if (self.team == COLOR_TEAM1)
		{
			redspawned += 1;
			totalspawned += 1;
		}
		else if (self.team == COLOR_TEAM2)
		{
			bluespawned += 1;
			totalspawned += 1;
		}
		else if (self.team == COLOR_TEAM3)
		{
			yellowspawned += 1;
			totalspawned += 1;
		}
		else if (self.team == COLOR_TEAM4)
		{
			pinkspawned += 1;
			totalspawned += 1;
		}
	}
}

void count_alive_players()
{
	totalalive = redalive = bluealive = yellowalive = pinkalive = 0;
	if(g_ca)
	{
		FOR_EACH_PLAYER(self) {
			if (self.team == COLOR_TEAM1 && self.health >= 1)
			{
				redalive += 1;
				totalalive += 1;
			}
			else if (self.team == COLOR_TEAM2 && self.health >= 1)
			{
				bluealive += 1;
				totalalive += 1;
			}
		}
		FOR_EACH_REALCLIENT(self) {
			self.redalive_stat = redalive;
			self.bluealive_stat = bluealive;
		}
	}
	else if(g_freezetag)
	{
		// count amount of alive players in each team
		FOR_EACH_PLAYER(self) {
			if (self.team == COLOR_TEAM1 && self.freezetag_frozen == 0 && self.health >= 1)
			{
				redalive += 1;
				totalalive += 1;
			}
			else if (self.team == COLOR_TEAM2 && self.freezetag_frozen == 0 && self.health >= 1)
			{
				bluealive += 1;
				totalalive += 1;
			}
			else if (self.team == COLOR_TEAM3 && self.freezetag_frozen == 0 && self.health >= 1)
			{
				yellowalive += 1;
				totalalive += 1;
			}
			else if (self.team == COLOR_TEAM4 && self.freezetag_frozen == 0 && self.health >= 1)
			{
				pinkalive += 1;
				totalalive += 1;
			}
		}
		FOR_EACH_REALCLIENT(self) {
			self.redalive_stat = redalive;
			self.bluealive_stat = bluealive;
			self.yellowalive_stat = yellowalive;
			self.pinkalive_stat = pinkalive;
		}
	}

}

/**
 * This function finds out whether an arena round is over 1 player is left.
 * It determines the last player who's still alive and saves it's entity reference
 * in the global variable 'champion'. Then the new enemy/enemies are put into the server.
 *
 * Gets called in StartFrame()
 */
void Spawnqueue_Check()
{
	count_spawned_players();
	if(g_ca || g_freezetag) // we want to perform this before the return block below (CA)...
	{
		count_alive_players();
	}
	if(time < warmup + 1 || inWarmupStage || intermission_running)
		return;

	if(g_ca) {
		required_ca_players = max(2, fabs(autocvar_bot_vs_human + 1));

		if(ca_players < required_ca_players && (redspawned && bluespawned)) {
			reset_map(TRUE);
		}
		else if(ca_players < required_ca_players) {
			FOR_EACH_PLAYER(self)
				centerprint(self, strcat("^1Need at least 1 player in each team to play CA", "^7\n"));
			return;
		}
		else if(!next_round) {
			if((redspawned && !bluespawned) || (bluespawned && !redspawned)) {
				next_round = time + 5;
				champion = find(world, classname, "player");
				if(champion_name)
					strunzone(champion_name);
				champion_name = strzone(champion.netname);
			}
			else if((!redspawned && !bluespawned) || time - warmup > autocvar_g_ca_round_timelimit) {
				FOR_EACH_CLIENT(self) centerprint(self, strcat("^7Round tied.", "^7\n"));
				next_round = time + 5;
			}

		}
		if(!stopalivecheck)
		{
			if(redalive && !bluealive)
			{
				play2all("ctf/red_capture.wav");
				FOR_EACH_CLIENT(self) centerprint(self, "^1 RED ^7team wins the round.\n");
				TeamScore_AddToTeam(COLOR_TEAM1, ST_SCORE, +1);
				stopalivecheck = TRUE;
			}
			else if(bluealive && !redalive)
			{
				play2all("ctf/blue_capture.wav");
				FOR_EACH_CLIENT(self) centerprint(self, "^4 BLUE ^7team wins the round.\n");
				TeamScore_AddToTeam(COLOR_TEAM2, ST_SCORE, +1);
				stopalivecheck = TRUE;
			}
		}

		if((next_round && next_round < time))
		{
			stopalivecheck = FALSE;
			next_round = 0;
			reset_map(TRUE);
		}
	} else if(g_freezetag) {
		if((next_round && next_round < time))
		{
			next_round = 0;
			reset_map(TRUE);
		}
	} else { // arena
		//extend next_round if it isn't set yet and only 1 player is spawned
		if(!next_round)
		if(numspawned < 2)
			next_round = time + 3;

		if(!arena_roundbased || (next_round && next_round < time && player_count > 1))
		{
			next_round = 0;

			if(arena_roundbased)
			{
				champion = find(world, classname, "player");
				while(champion && champion.deadflag)
					champion = find(champion, classname, "player");
				reset_map(TRUE);
			}

			while(numspawned < maxspawned && spawnqueue_first)
			{
				self = spawnqueue_first;

				bprint ("^4", self.netname, "^4 is the next challenger\n");

				Spawnqueue_Remove(self);
				Spawnqueue_Mark(self);

				self.classname = "player";
				PutClientInServer();
			}
		}
	}
}
