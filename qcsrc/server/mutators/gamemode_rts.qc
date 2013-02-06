// Real-Time Strategy
// Gamemode by Mario

.vector oldorigin;
.float selected;
.float last_click;
MUTATOR_HOOKFUNCTION(rts_PlayerSpawn)
{
	self.oldorigin = self.origin;
	self.last_click = time;
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
	entity head, wp = world;
	if(self.cursor_trace_ent == world && self.BUTTON_ATCK)
	{	
		FOR_EACH_MONSTER(head)
		{
			if(head.waypointsprite_attachedforcarrier)
				WaypointSprite_Kill(head.waypointsprite_attachedforcarrier);
				
			head.selected = FALSE;
			
			if(head.owner == self)
				head.owner = world;
		}
	}
	if(self.cursor_trace_ent.flags & FL_MONSTER && self.BUTTON_ATCK && time >= self.last_click)
	{
		if(self.cursor_trace_ent.selected)
		{
			WaypointSprite_Kill(self.cursor_trace_ent.waypointsprite_attachedforcarrier);
			self.cursor_trace_ent.selected = FALSE;
			self.cursor_trace_ent.owner = world;
			self.last_click = time + 0.5; // prevent spamming
		}
		else
		{
			WaypointSprite_Spawn("Selected", 0, 0, self.cursor_trace_ent, '0 0 64' + ('0 0 1' * self.cursor_trace_ent.maxs_z), world, 0, self.cursor_trace_ent, waypointsprite_attachedforcarrier, FALSE, RADARICON_FLAGCARRIER, BALL_SPRITECOLOR);
			
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
				WaypointSprite_SpawnFixed("Moving Here", wp.origin + '0 0 40', wp, sprite, RADARICON_HERE, '1 0.5 0');
			}
		}
		
		FOR_EACH_MONSTER(head)
		{
			if(head.owner != self) continue;
			
			if(head.goalentity)
			{
				if(head.goalentity.sprite)
					WaypointSprite_Kill(head.goalentity.sprite);
				remove(head.goalentity);
				head.goalentity = world;
			}
			
			if(head.sprite)
				WaypointSprite_Kill(head.sprite);
			
			if(self.cursor_trace_ent)
				head.enemy = self.cursor_trace_ent;
			else
				head.goalentity = wp;
		}
	}

	return FALSE;
}

MUTATOR_HOOKFUNCTION(rts_MonsterSpawn)
{
	self.effects |= EF_SELECTABLE;
	
	if(self.sprite)
		WaypointSprite_Kill(self.sprite); // no waypoint names in rts...?
	
	return FALSE;
}

MUTATOR_HOOKFUNCTION(rts_MonsterThink)
{
	if(self.selected)
		self.colormod = '1 1 1' * 4;
	else
		self.colormod = '1 1 1';
		
	return FALSE;
}

MUTATOR_HOOKFUNCTION(rts_MonsterDies)
{
	if(self.waypointsprite_attachedforcarrier)
		WaypointSprite_Kill(self.waypointsprite_attachedforcarrier);
		
	self.selected = FALSE;
	
	return FALSE;
}

MUTATOR_HOOKFUNCTION(rts_PlayerPhysics)
{
	self.origin_z = self.oldorigin_z;
	self.stat_sv_maxspeed *= 4; // lol
	
	return FALSE;
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
	MUTATOR_HOOK(MonsterDies, rts_MonsterDies, CBC_ORDER_ANY);
	
	MUTATOR_ONADD
	{
		if(time > 1) // game loads at time 1
			error("This is a game type and it cannot be added at runtime.");	
		cvar_settemp("g_monsters", "1");
	}

	MUTATOR_ONREMOVE
	{
		error("This is a game type and it cannot be removed at runtime.");
	}

	return FALSE;
}
