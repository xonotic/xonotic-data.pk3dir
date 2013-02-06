// Real-Time Strategy
// Gamemode by Mario

.vector oldorigin;
.float selected;
.float last_click;
MUTATOR_HOOKFUNCTION(rts_PlayerSpawn)
{
	self.effects |= EF_NODRAW;
	self.oldorigin = self.origin;
	self.last_click = time;
	self.takedamage = DAMAGE_NO;
	self.flags |= FL_NOTARGET;
	self.movetype = MOVETYPE_FLY;
	stuffcmd(self, "settemp cl_prydoncursor 1\n");
	return FALSE;
}

MUTATOR_HOOKFUNCTION(rts_FilterItem)
{
	// no items... yet
	return TRUE;
}

MUTATOR_HOOKFUNCTION(rts_SetStartItems)
{
	WEPSET_COPY_AW(start_weapons, 0);
	
	return FALSE;
}

MUTATOR_HOOKFUNCTION(rts_PlayerThink)
{
	if(self.classname != "player")
		return FALSE; // dont do any checks for spectators
	entity head, wp = world;
	if(self.cursor_trace_ent == world && self.BUTTON_ATCK && time >= self.last_click)
	{	
		FOR_EACH_MONSTER(head)
		{
			if(head.owner != self) continue;
			
			if(head.goalentity)
			{
				remove(head.goalentity);
				head.goalentity = world;
			}
				
			head.selected = FALSE;
			
			if(!self.enemy && !self.goalentity)
				head.owner = world;
		}
	}
	if(self.cursor_trace_ent.flags & FL_MONSTER && self.BUTTON_ATCK && time >= self.last_click)
	{
		if(self.cursor_trace_ent.owner != self && self.cursor_trace_ent.owner != world)
			return FALSE; // someone else owns it
		else if(self.cursor_trace_ent.team != self.team)
			return FALSE; // not our team
		else if(self.cursor_trace_ent.selected)
		{
			self.cursor_trace_ent.selected = FALSE;
			self.cursor_trace_ent.owner = world;
			self.last_click = time + 0.5; // prevent spamming
		}
		else
		{
			self.cursor_trace_ent.owner = self;
			self.cursor_trace_ent.selected = TRUE;
			self.last_click = time + 0.5; // prevent spamming
		}
	}
	if(self.BUTTON_ATCK2)
	{
		if not(self.cursor_trace_ent)
		{
			float selected_count = 0;
			FOR_EACH_MONSTER(head) { if(head.owner == self) selected_count += 1; }
			if(selected_count > 0)
			{
				wp = spawn();
				setorigin(wp, self.cursor_trace_endpos);
			}
		}
		
		FOR_EACH_MONSTER(head)
		{
			if(head.owner != self) continue;
			
			if(head.goalentity)
			{
				remove(head.goalentity);
				head.goalentity = world;
			}
			
			if(self.cursor_trace_ent && self.cursor_trace_ent.team != self.team)
				head.enemy = self.cursor_trace_ent;
			else
			{
				head.goalentity = wp;
				head.enemy = world;
			}
		}
	}

	return FALSE;
}

MUTATOR_HOOKFUNCTION(rts_MonsterSpawn)
{
	self.respawntime = time + 5; // default to 5 seconds for now
	self.effects |= EF_SELECTABLE;
	self.monster_moveflags = MONSTER_MOVE_NOMOVE;
	
	WaypointSprite_Kill(self.sprite);
	self.sprite = world;
	
	return FALSE;
}

MUTATOR_HOOKFUNCTION(rts_MonsterThink)
{
	vector color;
	if(self.team)
		color = TeamColor(self.team);
	else
		color = '1 1 1';
		
	monster_speed_run = 100;
	monster_speed_walk = 100;
	
	if(self.selected)
		self.colormod = color * 4;
	else
	{
		self.colormod = color;
		if(self.goalentity)
		{
			remove(self.goalentity);
			self.goalentity = world;
		}
	}
	
	if(self.goalentity)
		self.enemy = world; // don't ignore our owner's commands
	
	if(!self.sprite)
	{
		WaypointSprite_Spawn(self.netname, 0, 0, self, '0 0 1' * self.sprite_height, world, self.team, self, sprite, FALSE, RADARICON_DANGER, ((teamplay) ? TeamColor(self.team) : '1 0 0'));	
		WaypointSprite_UpdateMaxHealth(self.sprite, self.max_health);
		WaypointSprite_UpdateHealth(self.sprite, self.health);
	}
	
	if(!self.selected)
	if(self.owner)
	if(!self.goalentity && !self.enemy)
		self.owner = world;
	
	if(self.enemy.team == self.team)
		self.enemy = world; // no same team fighting
	
	self.last_trace = time; // realtime moving?
		
	return FALSE;
}

MUTATOR_HOOKFUNCTION(rts_MonsterDies)
{
	float otherteam = ((self.team == COLOR_TEAM1) ? COLOR_TEAM2 : COLOR_TEAM1);
	
	TeamScore_AddToTeam(otherteam, ST_SCORE, 1);

	self.effects &~= EF_SELECTABLE;
	self.selected = FALSE;
	
	return FALSE;
}

MUTATOR_HOOKFUNCTION(rts_MonsterRespawn)
{
	if(other.team)
		return TRUE;
		
	return FALSE; // if no team is set, don't respawn
}

MUTATOR_HOOKFUNCTION(rts_MonsterTarget)
{
	// don't search for enemies, they are given to us
	return TRUE;
}

MUTATOR_HOOKFUNCTION(rts_MonsterBossFlag)
{
	// no minibosses in RTS
	return TRUE;
}

MUTATOR_HOOKFUNCTION(rts_PlayerDamage)
{
	if(frag_target.classname == "player")
		frag_damage = 0; // don't damage the invincible players...
		
	if((frag_target.flags & FL_MONSTER) && frag_target.goalentity)
		frag_target.enemy = world; // don't attack the attacker, we're probably pulling back
		
	return FALSE;
}

MUTATOR_HOOKFUNCTION(rts_PlayerPhysics)
{
	self.origin_z = self.oldorigin_z;
	self.stat_sv_maxspeed *= 4; // lol
	
	return FALSE;
}

void rts_ScoreRules()
{
	ScoreRules_basics(2, SFL_SORT_PRIO_PRIMARY, 0, TRUE);
	ScoreRules_basics_end();
}

void rts_DelayedInit()
{
	rts_ScoreRules();
}

void rts_Initialize()
{
	InitializeEntity(world, rts_DelayedInit, INITPRIO_GAMETYPE);
}

MUTATOR_DEFINITION(gamemode_rts)
{
	MUTATOR_HOOK(PlayerPhysics, rts_PlayerPhysics, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerSpawn, rts_PlayerSpawn, CBC_ORDER_ANY);
	MUTATOR_HOOK(SetStartItems, rts_SetStartItems, CBC_ORDER_ANY);
	MUTATOR_HOOK(FilterItem, rts_FilterItem, CBC_ORDER_ANY);
	MUTATOR_HOOK(MonsterSpawn, rts_MonsterSpawn, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerPreThink, rts_PlayerThink, CBC_ORDER_ANY);
	MUTATOR_HOOK(MonsterMove, rts_MonsterThink, CBC_ORDER_ANY);
	MUTATOR_HOOK(MonsterFindTarget, rts_MonsterTarget, CBC_ORDER_ANY);
	MUTATOR_HOOK(MonsterDies, rts_MonsterDies, CBC_ORDER_ANY);
	MUTATOR_HOOK(MonsterRespawn, rts_MonsterRespawn, CBC_ORDER_ANY);
	MUTATOR_HOOK(MonsterCheckBossFlag, rts_MonsterBossFlag, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerDamage_Calculate, rts_PlayerDamage, CBC_ORDER_ANY);
	
	MUTATOR_ONADD
	{
		if(time > 1) // game loads at time 1
			error("This is a game type and it cannot be added at runtime.");	
		cvar_settemp("g_monsters", "1");
		
		rts_Initialize();
	}

	MUTATOR_ONREMOVE
	{
		error("This is a game type and it cannot be removed at runtime.");
	}

	return FALSE;
}
