float _spectate(entity _player)
{
	if(SpectateNext(_player) == 1)
	{
		PutObserverInServer();
		self.classname = "spectator";
	}	
	return TRUE;
}

MUTATOR_HOOKFUNCTION(superspec_SV_ParseClientCommand)
{
	if(MUTATOR_RETURNVALUE) // command was already handled?
		return FALSE;

	if(self.classname == "player")
		return TRUE;

	if(cmd_name == "followpowerup")
	{
		entity _player;
		FOR_EACH_PLAYER(_player)
		{
			if(_player.strength_finished > time || _player.invincible_finished > time)
				return _spectate(_player);
		}
		centerprint(self, "No active powerups\n");
		return TRUE;
	}

	if(cmd_name == "followstrength")
	{
		entity _player;
		FOR_EACH_PLAYER(_player)
		{
			if(_player.strength_finished > time)
				return _spectate(_player);
		}
		centerprint(self, "No active Strength\n");
		return TRUE;
	}

	if(cmd_name == "followstshield")
	{
		entity _player;
		FOR_EACH_PLAYER(_player)
		{
			if(_player.invincible_finished > time)
				return _spectate(_player);
		}
		centerprint(self, "No active Shield\n");
		return TRUE;
	}

	if(cmd_name == "followfc")
	{
		if(!g_ctf)
			return TRUE;
		
		entity _player;		
		float _team;
		
		if(cmd_argc == 2)
		{			
			if(argv(1) == "red")
				_team = COLOR_TEAM1;
			else
				_team = COLOR_TEAM2;
		}
		
		FOR_EACH_PLAYER(_player)
		{
			if(_player.flagcarried && (_player.team == _team || _team == 0))
				return _spectate(_player);
		}
		
		centerprint(self, "No active FC\n");
		return TRUE;
	}	

	return FALSE;
}

MUTATOR_HOOKFUNCTION(superspec_BuildMutatorsString)
{
	ret_string = strcat(ret_string, ":SS");
	return 0;
}

MUTATOR_HOOKFUNCTION(superspec_BuildMutatorsPrettyString)
{
	ret_string = strcat(ret_string, ", Super Spectators");
	return 0;
}

/*
MUTATOR_HOOKFUNCTION(superspec_PlayerSpawn)
{

	return FALSE;
}

MUTATOR_HOOKFUNCTION(superspec_ClientDisconnect)
{

	return FALSE;
}
MUTATOR_HOOKFUNCTION(superspec_PlayerPreThink)
{
	return FALSE;
}
*/

MUTATOR_DEFINITION(mutator_superspec)
{

	MUTATOR_HOOK(BuildMutatorsString, superspec_BuildMutatorsString, CBC_ORDER_ANY);
	MUTATOR_HOOK(BuildMutatorsPrettyString, superspec_BuildMutatorsPrettyString, CBC_ORDER_ANY);
	MUTATOR_HOOK(SV_ParseClientCommand, superspec_SV_ParseClientCommand, CBC_ORDER_ANY);
	//MUTATOR_HOOK(ClientConnect, superspec_ClientConnect, CBC_ORDER_ANY);
	//MUTATOR_HOOK(PlayerSpawn, superspec_PlayerSpawn, CBC_ORDER_ANY);
	//MUTATOR_HOOK(PlayerPreThink, superspec_PlayerPreThink, CBC_ORDER_ANY);
	//MUTATOR_HOOK(ClientDisconnect, superspec_ClientDisconnect, CBC_ORDER_ANY);

	MUTATOR_ONADD
	{
	}

	MUTATOR_ONREMOVE
	{
	}

	return 0;
}
