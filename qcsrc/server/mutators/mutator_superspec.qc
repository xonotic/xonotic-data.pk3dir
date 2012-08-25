#define ASF_STRENGTH 1
#define ASF_SHIELD 2
#define ASF_MEGA_AR 4
#define ASF_MEGA_HP 8
#define ASF_FLAG_GRAB 16
#define ASF_ALL 0xFFFFFF

.float autospec_flags;

float _spectate(entity _player)
{
	if(SpectateNext(_player) == 1)
	{
		PutObserverInServer();
		self.classname = "spectator";
	}
	
	return TRUE;
}

MUTATOR_HOOKFUNCTION(superspec_ItemTouch)
{
	entity _oldself = self;
	entity _item = self;
	
	FOR_EACH_SPEC(self)
	{
		//centerprint(self, sprintf("Player %s^7 just grabbed a ^3%s\n", other.netname, _item.classname));
		
		if( (self.autospec_flags & ASF_SHIELD && _item.invincible_finished) ||
			(self.autospec_flags & ASF_STRENGTH && _item.strength_finished) ||
			(self.autospec_flags & ASF_MEGA_AR && _item.classname == "item_armor_large") ||
			(self.autospec_flags & ASF_MEGA_HP && _item.classname == "item_health_mega") )		
				_spectate(other);
	}
	
	self = _oldself;
	
	return FALSE;
}

MUTATOR_HOOKFUNCTION(superspec_SV_ParseClientCommand)
{
	if(MUTATOR_RETURNVALUE) // command was already handled?
		return FALSE;

	if(self.classname == "player")
		return FALSE;

	if(cmd_name == "autospec")
	{
		if(cmd_argc > 1)
		{
#define STRING2FLAG(str,flg) if(argv(i) == str) _bits |= flg
			float i, _bits, _start = 1;
			if(argv(1) == "clear")
			{
				self.autospec_flags = 0;
				_start = 2;
			}

			for(i = _start; i < cmd_argc; ++i)
			{
				if(argv(i) == "on" || argv(i) == "1")§
				{
					self.autospec_flags |= _bits;
					_bits = 0;
				}
				else if(argv(i) == "off" || argv(i) == "0")
				{
					if(_start == 1)
						self.autospec_flags &~= _bits;

					_bits = 0;
				}
				else
				{
					STRING2FLAG("strength", ASF_STRENGTH);
					STRING2FLAG("shield", ASF_SHIELD);
					STRING2FLAG("mega_health", ASF_MEGA_HP);
					STRING2FLAG("mega_armor", ASF_MEGA_AR);
					STRING2FLAG("all", ASF_ALL);
				}
			}
		}
		
		string _aspeco = "^3Current auto spectate options are:\n\n\n\n\n";
#undef STRING2FLAG

#define SPECOCLR(var,test,text) \
    var = strcat(var, ((self.autospec_flags & test) ? "^2" : "^1")); \
    var = strcat(var,text)

		SPECOCLR(_aspeco, ASF_STRENGTH, "Strength\n\n");
		SPECOCLR(_aspeco, ASF_SHIELD, "Shiled\n\n");
		SPECOCLR(_aspeco, ASF_MEGA_HP, "Mega Health\n\n");
		SPECOCLR(_aspeco, ASF_MEGA_AR, "Mega Armor\n\n");
#undef SPECOCLR

		centerprint(self, _aspeco);
		return TRUE;dfd
	}
	
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
		
		centerprint(self, "No active flag carrier\n");
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
	MUTATOR_HOOK(ItemTouch, superspec_ItemTouch, CBC_ORDER_ANY);
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
