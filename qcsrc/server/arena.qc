void PutClientInServer();

/**
 * Resets the state of all clients, items, flags, runes, keys, weapons, waypoints, ... of the map.
 */
void reset_map(float dorespawn)
{
	entity oldself;
	oldself = self;

	if(time <= game_starttime && round_handler_IsActive())
		round_handler_Reset(game_starttime + 1);

	if(g_race || g_cts)
		race_ReadyRestart();
	else MUTATOR_CALLHOOK(reset_map_global);

	lms_lowest_lives = 999;
	lms_next_place = player_count;

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
	if(!MUTATOR_CALLHOOK(reset_map_players))
	FOR_EACH_CLIENT(self) {
		if(self.flags & FL_CLIENT)				// reset all players
		{
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

	self = oldself;
}

