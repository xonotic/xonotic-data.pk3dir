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
float warmup;
.float caplayer;

void PutObserverInServer();
void PutClientInServer();

float next_round;
float redalive, bluealive, yellowalive, pinkalive;
float totalalive;
.float redalive_stat, bluealive_stat, yellowalive_stat, pinkalive_stat;
float red_players, blue_players, yellow_players, pink_players;
float total_players;

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
	if(clienttype(self) == CLIENTTYPE_NOTACLIENT)
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
		kh_Controller_SetThink_NoMsg(autocvar_g_balance_keyhunt_delay_round+(game_starttime - time), kh_StartRound);

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
 * Called in StartFrame()
 */
float roundStartTime_prev; // prevent networkspam
void Arena_Warmup()
{
	float f;
	entity e;

	if(gameover)
	{
		if(warmup && time < warmup)
		{
			FOR_EACH_REALCLIENT(e)
				Send_CSQC_Centerprint_Generic_Expire(e, CPID_ROUND_STARTING);
			warmup = 0;
		}
		if(champion && g_arena)
		{
			FOR_EACH_REALCLIENT(e)
				centerprint(e, strcat("The Champion is ", champion.netname));
			champion = world;
		}
		return;
	}
	if((!g_arena && !g_ca && !g_freezetag) || (g_arena && !arena_roundbased) || (time < game_starttime))
		return;

	f = ceil(warmup - time);

	if(inWarmupStage)
		allowed_to_spawn = 1;
	else if(!g_ca)
		allowed_to_spawn = 0;

	if(time < warmup && !inWarmupStage)
	{
		if (g_ca)
			allowed_to_spawn = 1;
		if(champion && g_arena)
		{
			FOR_EACH_REALCLIENT(e)
				centerprint(e, strcat("The Champion is ", champion.netname));
		}

		if(f != roundStartTime_prev) {
			roundStartTime_prev = f;
			if(g_ca && !(red_players && blue_players)) {
				FOR_EACH_REALCLIENT(self)
					Send_CSQC_Centerprint_Generic(self, CPID_ROUND_STARTING, "^1Need at least 1 player in each team to play CA", 2, 0);
				warmup = time + autocvar_g_ca_warmup;
			} else {
				if(f == 5)
					Announce("prepareforbattle");
				else if(f == 3)
					Announce("3");
				else if(f == 2)
					Announce("2");
				else if(f == 1)
					Announce("1");

				FOR_EACH_REALCLIENT(e)
					Send_CSQC_Centerprint_Generic(e, CPID_ROUND_STARTING, "Round will start in %d", 1, f);
			}
		}

		if (g_arena) {
			FOR_EACH_CLIENT(e)
			{
				if(e.spawned && e.classname == "player")
					e.player_blocked = 1;
			}
		}
	}
	else if(f > -1 && f != roundStartTime_prev)
	{
		roundStartTime_prev = f;
		if(g_ca) {
			if(red_players && blue_players)
				allowed_to_spawn = 0;
			else
				reset_map(TRUE);
		} else {
			Announce("begin");
			FOR_EACH_REALCLIENT(e)
				Send_CSQC_Centerprint_Generic(e, CPID_ROUND_STARTING, "^1Begin!", 1, 0);
		}

		if(g_arena) {
			FOR_EACH_CLIENT(e)
			{
				if(e.player_blocked)
					e.player_blocked = 0;
			}
		}
	}

	// clear champion to avoid centerprinting again the champion msg
	if (champion)
		champion = world;
}

void count_players()
{
	// count amount of players in each team
	total_players = red_players = blue_players = yellow_players = pink_players = 0;
	FOR_EACH_PLAYER(self) {
		if (self.team == COLOR_TEAM1)
		{
			red_players += 1;
			total_players += 1;
		}
		else if (self.team == COLOR_TEAM2)
		{
			blue_players += 1;
			total_players += 1;
		}
		else if (self.team == COLOR_TEAM3)
		{
			yellow_players += 1;
			total_players += 1;
		}
		else if (self.team == COLOR_TEAM4)
		{
			pink_players += 1;
			total_players += 1;
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
	if(warmup == 0 && g_ca && !inWarmupStage)
	{
		if(red_players || blue_players)
			reset_map(TRUE);
		return;
	}
	if(time < warmup + 1 || inWarmupStage || intermission_running)
		return;

	if(g_ca) {
		if(allowed_to_spawn) // round is not started yet
			return;
		if(!next_round) {
			if(!(redalive && bluealive)) {
				// every player of (at least) one team is dead, round ends here
				if(redalive) {
					play2all("ctf/red_capture.wav");
					FOR_EACH_CLIENT(self) centerprint(self, "^1RED ^7team wins the round");
					TeamScore_AddToTeam(COLOR_TEAM1, ST_SCORE, +1);
				}
				else if(bluealive) {
					play2all("ctf/blue_capture.wav");
					FOR_EACH_CLIENT(self) centerprint(self, "^4BLUE ^7team wins the round");
					TeamScore_AddToTeam(COLOR_TEAM2, ST_SCORE, +1);
				}
				else
					FOR_EACH_CLIENT(self) centerprint(self, "^7Round tied");
				next_round = -1;
			}
			else if(time - warmup > autocvar_g_ca_round_timelimit) {
				FOR_EACH_CLIENT(self) centerprint(self, "^7Round tied");
				next_round = time + 5;
			}
		}
		else if(next_round == -1) {
			// wait for killed players to be put as spectators
			if(!(red_players && blue_players))
				next_round = time + 5;
		}
		else if((next_round > 0 && next_round < time))
		{
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
