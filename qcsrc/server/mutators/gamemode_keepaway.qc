void ka_SpawnBall(void);
void ka_TouchEvent(void);
void ka_RespawnBall(void);
void ka_DropEvent(entity);
//.float dropperid;

void ka_Initialize() // run at the start of a match, initiates game mode
{
	if(!g_keepaway)
		return;
		
	precache_sound("keepaway/pickedup.wav");
	precache_sound("keepaway/dropped.wav");

	ScoreRules_keepaway();
	
	//entity e; // Is this needed here? I think not
	//e = spawn();
	//e.think = ka_SpawnBall;
	//e.nextthink = time;

	//InitializeEntity(e, ka_SpawnBall, INITPRIO_SETLOCATION); // Is initializeentity needed here? I think not
	ka_SpawnBall();
}

void ka_Reset() // used to clear the ballcarrier whenever the match switches from warmup to normal
{
	if(self.owner)
		if(self.owner.classname == "player")
			ka_DropEvent(self.owner);

	ka_RespawnBall();
}

void ka_SpawnBall() // loads various values for the ball
{
	if(!g_keepaway) { return; }
	
	entity e;
	e = spawn();
	if (!e.model) { // is this needed? OF COURSE the model doesn't exist, the ball isn't on the map yet!
		e.model = "models/orbs/orbblue.md3";	
		e.scale = 1; }
	precache_model(e.model);
	setmodel(e, e.model);
	setsize(e, BALL_MINS, BALL_MAXS);
	ball_scale = e.scale;
	e.classname = "keepawayball";
	e.damageforcescale = cvar("g_keepawayball_damageforcescale");
	e.takedamage = DAMAGE_YES;
	//self.effects |= "sparks";
	e.glow_color = cvar("g_keepawayball_trail_color");
	e.glow_trail = TRUE;
	e.movetype = MOVETYPE_BOUNCE;
	e.touch = ka_TouchEvent;
	e.think = ka_RespawnBall;
	e.nextthink = time;
	e.flags = FL_ITEM;
	e.reset = ka_Reset;
	e.owner = world;
}

void ka_RespawnBall() // runs whenever the ball needs to be relocated
{
	vector oldballorigin = self.origin;

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
		pointparticles(particleeffectnum("electro_combo"), oldballorigin, '0 0 0', 1);
		pointparticles(particleeffectnum("electro_combo"), self.origin, '0 0 0', 1);

		WaypointSprite_Spawn("ka-ball", 0, 0, self, '0 0 64', world, self.team, self, waypointsprite_attachedforcarrier, FALSE);
		WaypointSprite_UpdateTeamRadar(self.waypointsprite_attachedforcarrier, RADARICON_FLAGCARRIER, '0 1 1');

		sound(self.owner, CHAN_AUTO, "keepaway/respawn.wav", VOL_BASE, ATTN_NONE);
	}
	else
	{
		// sorry, can't spawn, better luck next frame
		self.think = ka_RespawnBall;
		self.nextthink = time;
	}
}

void ka_TouchEvent() // runs any time that the ball comes in contact with something
{
	if(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT)
	{
		self.think = ka_RespawnBall;
		self.nextthink = time;
		return;
	}
	if(other.deadflag != DEAD_NO) { return; }
	if(other.classname != "player") 
	{ 
		pointparticles(particleeffectnum("kaball_sparks"), self.origin, '0 0 0', 1);
		return; 
	}
	if(!self) { return; }
	if(self.wait > time) { return; }

	self.owner = other;
	other.ballcarried = self;
	setattachment(self, other, "");
	setorigin(self, BALL_ATTACHORG);
	
	self.velocity = '0 0 0';
	self.movetype = MOVETYPE_NONE;
	self.touch = SUB_Null;
	self.effects |= EF_NODRAW;
	self.think = SUB_Null;
	self.nextthink = 0;
	self.takedamage = DAMAGE_NO;

	other.glow_color = cvar("g_keepawayball_trail_color");
	other.glow_trail = TRUE;
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

void ka_DropEvent(entity plyr) // runs any time that a player is supposed to lose the ball
{
	entity ball;
	ball = plyr.ballcarried;

	if(!ball) { return; }
	
	setattachment(ball, world, "");
	ball.movetype = MOVETYPE_BOUNCE;
	ball.solid = SOLID_TRIGGER;
	ball.wait = time + 1; 
	ball.think = ka_RespawnBall;
	ball.nextthink = time + cvar("g_keepawayball_respawntime");
	ball.touch = ka_TouchEvent;
	ball.takedamage = DAMAGE_YES;
	ball.effects &~= EF_NODRAW; //ball.alpha = 1.0;
	setorigin(ball, plyr.origin + '0 0 10');
	ball.velocity = '0 0 200' + '0 100 0'*crandom() + '100 0 0'*crandom();
	ball.owner.ballcarried = world;
	ball.owner = world;

	plyr.effects &~= 8;
	plyr.alpha = 1.0;
	plyr.glow_trail = FALSE;
	
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
	if(self.ballcarried) { ka_DropEvent(self); }
	return 1;
}

MUTATOR_HOOKFUNCTION(ka_Scoring)
{
	if((frag_attacker != frag_target) && (frag_attacker.classname == "player"))
	{
		if(frag_target.ballcarried) { // get amount of times killing carrier
			PlayerScore_Add(frag_attacker, SP_KEEPAWAY_CARRIERKILLS, 1);
			if(cvar("g_keepaway_bckillscore"))
				PlayerScore_Add(frag_attacker, SP_KEEPAWAY_SCORE, 1);
		}
		else if(!frag_attacker.ballcarried)
			if(cvar("g_keepaway_noncarrier_warn"))
				centerprint_atprio(frag_attacker, (CENTERPRIO_SPAM + 5), "Killing people while you don't have the ball gives no points!");

		if(frag_attacker.ballcarried) // get kills as carrier
			PlayerScore_Add(frag_attacker, SP_KEEPAWAY_SCORE, 1);
	}

	if(self.ballcarried) { ka_DropEvent(self); }
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

	if(self.ballcarried)
		self.items |= IT_KEY1; 
	
	if(self.BUTTON_USE)
		if(self.ballcarried) { ka_DropEvent(self); }

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