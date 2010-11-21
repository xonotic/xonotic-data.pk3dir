void ka_SpawnBall(void);
void ka_TouchEvent(void);
void ka_RespawnBall(void);
void ka_DropEvent(entity);

void ka_Initialize()
{
	if(!g_keepaway)
		return;
		
	precache_sound("keepaway/pickedup.wav");
	precache_sound("keepaway/dropped.wav");

	ScoreRules_keepaway();
	
	entity e;
	e = spawn();
	e.think = ka_SpawnBall;
	e.nextthink = time;
}

void ka_SpawnBall() // self = the ball
{
	if(!g_keepaway) { 
		remove(self); 
		return; 
	}
	if (!self.model) {
		self.model = "models/orbs/orbblue.md3";	
		self.scale = 1;
	}

	precache_model(self.model);
	setmodel(self, self.model);
	setsize(self, BALL_MINS, BALL_MAXS);
	ball_scale = self.scale;
	self.classname = "keepawayball";
	self.damageforcescale = cvar("g_keepawayball_damageforcescale");
	self.takedamage = DAMAGE_YES;
	self.effects = self.effects | EF_FULLBRIGHT;
	self.movetype = MOVETYPE_BOUNCE;
	self.touch = ka_TouchEvent;
	self.think = ka_RespawnBall;
	self.nextthink = time;
	self.flags = FL_ITEM;
	//self.reset = ka_Reset;
	self.owner = world;

	WaypointSprite_Spawn("ka-ball", 0, 0, self, '0 0 64', world, self.team, self, waypointsprite_attachedforcarrier, FALSE);
	WaypointSprite_UpdateTeamRadar(self.waypointsprite_attachedforcarrier, RADARICON_FLAGCARRIER, '0 1 1');
}

void ka_RespawnBall()
{
	if(MoveToRandomMapLocation(self, DPCONTENTS_SOLID | DPCONTENTS_CORPSE | DPCONTENTS_PLAYERCLIP, DPCONTENTS_SLIME | DPCONTENTS_LAVA | DPCONTENTS_SKY | DPCONTENTS_BODY | DPCONTENTS_DONOTENTER, Q3SURFACEFLAG_SKY, 10, 1024, 256))
	{
		makevectors(self.angles);
		self.movetype = MOVETYPE_BOUNCE;
		self.velocity = '0 0 200';
		self.angles = '0 0 0';
		self.solid = SOLID_TRIGGER;
		//self.touch = ka_TouchEvent;
		self.think = ka_RespawnBall;
		self.nextthink = time + cvar("g_keepawayball_respawntime");
	}
	else
	{
		// sorry, can't spawn, better luck next frame
		self.think = ka_RespawnBall;
		self.nextthink = time;
	}
}

void ka_TouchEvent()
{
	if(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT)
	{
		self.think = ka_SpawnBall;
		self.nextthink = time;
		return;
	}
	if(other.classname != "player" || other.health < 1) { return; }
	if(!self) { return; }
	if(self.wait > time) { return; }

	self.owner = other;
	other.kaballcarried = self;
	setattachment(self, other, "");
	setorigin(self, BALL_ATTACHORG);
	
	self.velocity = '0 0 0';
	self.movetype = MOVETYPE_NONE;
	self.touch = SUB_Null;
	self.alpha = 0.01;
	self.think = SUB_Null;
	self.nextthink = 0;
	self.glow_color = cvar("g_keepawayball_trail_color");
	self.glow_trail = TRUE;
	self.takedamage = DAMAGE_NO;

	other.effects |= 8;
	other.alpha = 0.6;

	bprint(other.netname, "^7 has picked up the ball!\n");
	WriteByte(MSG_BROADCAST, SVC_CENTERPRINT);
	WriteString(MSG_BROADCAST, strcat("\n\n", other.netname, "^7 has picked up the ball!\n"));
	sound(self.owner, CHAN_AUTO, "keepaway/pickedup.wav", VOL_BASE, ATTN_NONE);
	
	PlayerScore_Add(other, SP_KEEPAWAY_PICKUPS, 1);

	WaypointSprite_AttachCarrier("ka-ballcarrier", other);
	WaypointSprite_UpdateRule(other.waypointsprite_attachedforcarrier, 0, SPRITERULE_DEFAULT);
	WaypointSprite_UpdateTeamRadar(other.waypointsprite_attachedforcarrier, RADARICON_FLAGCARRIER, '1 0 0');
	WaypointSprite_Ping(other.waypointsprite_attachedforcarrier);	
	WaypointSprite_Kill(self.waypointsprite_attachedforcarrier);
}

void ka_DropEvent(entity plyr) 
{
	entity ball;
	ball = plyr.kaballcarried;

	if(!ball) { return; }
	
	setattachment(ball, world, "");
	ball.movetype = MOVETYPE_BOUNCE;
	ball.solid = SOLID_TRIGGER;
	ball.wait = time + 1; 
	ball.think = ka_SpawnBall;
	ball.nextthink = time + cvar("g_keepawayball_respawntime");
	ball.touch = ka_TouchEvent;
	ball.takedamage = DAMAGE_YES;
	plyr.effects = EF_LOWPRECISION;
	plyr.alpha = 1.0;
	ball.alpha = 1.0;
	setorigin(ball, plyr.origin + '0 0 10');
	ball.velocity = '0 0 200' + '0 100 0'*crandom() + '100 0 0'*crandom();
	ball.owner.kaballcarried = world;
	ball.owner = world;
	
	bprint(plyr.netname, "^7 has dropped the ball!\n");
	WriteByte(MSG_BROADCAST, SVC_CENTERPRINT);
	WriteString(MSG_BROADCAST, strcat("\n\n", plyr.netname, "^7 has dropped the ball!\n"));
	sound(other, CHAN_AUTO, "keepaway/dropped.wav", VOL_BASE, ATTN_NONE);	
	
	PlayerScore_Add(plyr, SP_KEEPAWAY_DROPS, 1);
	
	WaypointSprite_Spawn("ka-ball", 0, 0, ball, '0 0 64', world, ball.team, ball, waypointsprite_attachedforcarrier, FALSE);
	WaypointSprite_UpdateRule(ball.waypointsprite_attachedforcarrier, 0, SPRITERULE_DEFAULT);
	WaypointSprite_UpdateTeamRadar(ball.waypointsprite_attachedforcarrier, RADARICON_FLAGCARRIER, '0 1 1');
	WaypointSprite_Ping(ball.waypointsprite_attachedforcarrier);	
	WaypointSprite_Kill(plyr.waypointsprite_attachedforcarrier);
}

MUTATOR_HOOKFUNCTION(ka_RemovePlayer)
{
	if(self.kaballcarried) { ka_DropEvent(self); }
	return 1;
}

MUTATOR_HOOKFUNCTION(ka_Scoring)
{
	if((frag_attacker != frag_target) && (frag_attacker.classname == "player"))
	{
		if(frag_target.kaballcarried) { // get amount of times killing carrier
			PlayerScore_Add(frag_attacker, SP_KEEPAWAY_CARRIERKILLS, 1);
			if(cvar("g_keepaway_bckillscore"))
				PlayerScore_Add(frag_attacker, SP_KEEPAWAY_SCORE, 1);
		}
		else if(!frag_attacker.kaballcarried)
			if(cvar("g_keepaway_noncarrier_warn"))
				centerprint_atprio(frag_attacker, (CENTERPRIO_SPAM + 5), "Killing people while you don't have the ball gives no points!");

		if(frag_attacker.kaballcarried) // get kills as carrier
			PlayerScore_Add(frag_attacker, SP_KEEPAWAY_SCORE, 1);
	}

	if(self.kaballcarried) { ka_DropEvent(self); }
	return 1;
}

MUTATOR_HOOKFUNCTION(ka_GiveFragsForKill)
{
	frag_score = 0; // no frags counted in keepaway
	return 1;
}

MUTATOR_HOOKFUNCTION(ka_PlayerPreThink)
{
	self.items &~= IT_KEY1;

	if(self.kaballcarried) {
		self.items |= IT_KEY1; 
	}
	return 1;
}

MUTATOR_DEFINITION(gamemode_keepaway)
{
	MUTATOR_HOOK(MakePlayerObserver, ka_RemovePlayer, CBC_ORDER_ANY);
	MUTATOR_HOOK(ClientDisconnect, ka_RemovePlayer, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerDies, ka_Scoring, CBC_ORDER_ANY);
	MUTATOR_HOOK(GiveFragsForKill, ka_GiveFragsForKill, CBC_ORDER_FIRST);
	MUTATOR_HOOK(PlayerPreThink, ka_PlayerPreThink, CBC_ORDER_FIRST);

	MUTATOR_ONADD
	{
		if(time > 1) // game loads at time 1
			error("This is a game type and it cannot be added at runtime.");
		g_keepaway = 1;
		ka_Initialize();
	}

	MUTATOR_ONREMOVE
	{
		g_keepaway = 0;
		error("This is a game type and it cannot be removed at runtime.");
	}

	return 0;
}