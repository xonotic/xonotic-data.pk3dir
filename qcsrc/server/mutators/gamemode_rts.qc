// Real-Time Strategy
// Gamemode by Mario

// basically a fusion reactor with a new classname
void spawnfunc_healing_tower()
{
	self.spawnflags = TSL_NO_RESPAWN; // healing towers don't respawn?
	self.netname = "Monster Healing Tower"; // not used by waypoints...
	spawnfunc_turret_fusionreactor();
	self.classname = "healing_tower";
	self.target_range = 1000;
	self.shot_dmg = 30;
}

void rts_waypoint_think()
{
	float goalcount = 0;
	entity e;
	
	self.nextthink = time + 0.1;
	
	for(e = world; (e = findentity(e, goalentity, self)); )
	{
		++goalcount;
	}
	
	if(goalcount < 1)
	{
		WaypointSprite_Kill(self.sprite);
		remove(self);
		return;
	}
}

void Monster_LevelUp(entity e)
{
	if(self.level >= 5)
		return; // max level is 5 for now
	e.speed += 0.25;
	e.max_health += 20;
	e.health = e.max_health;
	e.level += 1;
	WaypointSprite_UpdateHealth(e.sprite, e.health);
}

MUTATOR_HOOKFUNCTION(rts_PlayerSpawn)
{
	if(self.rts_viewangle)
		self.angles_x = self.rts_viewangle;
	else
		self.angles_x = 30;
		
	self.effects |= EF_NODRAW;
	self.oldorigin = self.origin;
	self.monster_attack = FALSE;
	self.last_click = time;
	self.takedamage = DAMAGE_NO;
	self.flags |= FL_NOTARGET;
	self.movetype = MOVETYPE_NOCLIP;
	stuffcmd(self, "cl_cmd settemp cl_prydoncursor 1\n");
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
		
	switch(self.impulse)
	{
		case 10:
        case 15:        
        case 18:
            self.oldorigin_z += 50;
            break;
        case 12:
        case 16:
        case 19:
			self.oldorigin_z -= 50;
			break;
	}
	self.hasweapon_complain_spam = time + 9999999999; // no spam
		
	entity head, wp = world;
	if(!self.cursor_trace_ent && self.BUTTON_ATCK && time >= self.last_click)
	{	
		FOR_EACH_MONSTER(head)
		{
			if(head.owner != self) continue;
			
			head.selected = FALSE;
			
			if(!self.enemy)
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
		entity e = self.cursor_trace_ent;
		
		if(e)
		if not(IsDifferentTeam(e, self) || e.takedamage)
			e = world;
		
		if not(e)
		{
			wp = spawn();
			wp.classname = "monster_waypoint"; // set so we can kill this later
			wp.owner = self; // hmm...
			wp.think = rts_waypoint_think;
			wp.nextthink = time;
			WaypointSprite_Spawn("Waypoint", 0, 0, wp, '0 0 10', world, 0, wp, sprite, FALSE, RADARICON_DANGER, ((teamplay) ? TeamColor(self.team) : '1 0 0'));
			setorigin(wp, self.cursor_trace_endpos);
		}
		
		FOR_EACH_MONSTER(head)
		{
			if(head.owner != self) continue;
			if not(head.selected) continue;
			
			if(e)
			{
				head.goalentity = world;
				head.enemy = e;
			}
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
	// new monster
	if not(self.monster_respawned)
	{
		self.level = 0;
		self.speed = 1;
	}
	
	self.spawnflags = MONSTERFLAG_NORESPAWN;
	
	self.goalentity = world;
	self.enemy = world;
	self.moveto = self.origin;
		
	self.respawntime = 10; // default to 10 seconds for now
	self.effects |= EF_SELECTABLE;
	self.monster_moveflags = MONSTER_MOVE_NOMOVE;
	
	WaypointSprite_Kill(self.sprite);
	self.sprite = world;
	self.heal_delay = -1; // this is reset when monster takes damage
	
	return FALSE;
}

MUTATOR_HOOKFUNCTION(rts_MonsterThink)
{
	vector color = ((self.team) ? TeamColor(self.team) : '1 1 1');
		
	if(self.health >= self.max_health)
		self.heal_delay = -1;	
	else if(time >= self.heal_delay)
	{
		self.health = min(self.health + 5, self.max_health);
		WaypointSprite_UpdateHealth(self.sprite, self.health);
		self.heal_delay = time + 2;
	}
		
	monster_speed_run = 150 * self.speed;
	monster_speed_walk = 150 * self.speed;
	
	if(monster_target.classname == "player")
		monster_target = world;
	
	if(self.selected)
		self.colormod = color * 4;
	else
		self.colormod = color;
		
	if(monster_target)
		self.enemy = world; // don't ignore our owner's commands
	
	if not(self.sprite)
	{
		WaypointSprite_Spawn(self.netname, 0, 0, self, '0 0 1' * self.sprite_height, world, self.team, self, sprite, FALSE, RADARICON_DANGER, ((teamplay) ? TeamColor(self.team) : '1 0 0'));
		WaypointSprite_UpdateMaxHealth(self.sprite, self.max_health);
		WaypointSprite_UpdateHealth(self.sprite, self.health);
	}
	
	if(self.owner)
	if not(self.selected)
		self.owner = world;
	
	if not(IsDifferentTeam(self, self.enemy))
		self.enemy = world; // no same team fighting
	
	self.last_trace = time; // realtime moving?
		
	return FALSE;
}

MUTATOR_HOOKFUNCTION(rts_MonsterDies)
{
	if(IsDifferentTeam(frag_attacker, frag_target) && frag_attacker.team)
		TeamScore_AddToTeam(frag_attacker.team, ST_SCORE, 1);
	
	// need to keep the monster selected to get the points... hmm (TODO: realowners?)
	if(frag_attacker.owner.classname == "player")
	{
		PlayerScore_Add(frag_attacker.owner, SP_SCORE, 5);
		PlayerScore_Add(frag_attacker.owner, SP_KILLS, 1);
	}
		
	if(frag_attacker.flags & FL_MONSTER)
	{
		frag_attacker.monster_score += 5;
		if(frag_attacker.monster_score == 25)
			Monster_LevelUp(frag_attacker);
	}

	self.effects &~= EF_SELECTABLE;
	self.selected = FALSE;
	
	self.goalentity = world;
	self.enemy = world;
	
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
		
	if((frag_target.flags & FL_MONSTER) && !IsDifferentTeam(frag_target, frag_attacker))
		frag_damage = 0; // no team damage
		
	if((frag_target.flags & FL_MONSTER) && frag_damage > 0)
		frag_target.heal_delay = time + 2; // reset delay whenever hurt
		
	return FALSE;
}

MUTATOR_HOOKFUNCTION(rts_PlayerPhysics)
{
	if(self.classname != "player")
		return FALSE;
		
	self.origin_z = self.oldorigin_z;
	self.stat_sv_maxspeed *= 4; // lol
	
	return FALSE;
}

MUTATOR_HOOKFUNCTION(rts_PlayerDies)
{
	// prevent changing teams with selected monsters
	entity head;
	FOR_EACH_MONSTER(head)
	{
		if(head.owner != self) continue;
		if not(head.selected) continue;
		
		if(IsDifferentTeam(self, head))
		{
			head.selected = FALSE;
			head.owner = world;
		}
	}
	
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
	MUTATOR_HOOK(PlayerDies, rts_PlayerDies, CBC_ORDER_ANY);
	
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
