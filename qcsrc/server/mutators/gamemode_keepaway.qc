void ka_SpawnBall(void);
void ka_TouchEvent(entity);
void ka_RespawnBall(void);

void ka_Initialize()
{
	if(!g_keepaway)
		return;
		
	precache_sound("keepaway/pickedup.wav");
	precache_sound("keepaway/dropped.wav");
	
	entity e;
	e = spawn();
	e.think = ka_SpawnBall;
	e.nextthink = time;
}

void ka_SpawnBall()
{
	if(!g_keepaway) { 
		remove(self); 
		return; 
	}
	if (!self.model) {
		self.model = "models/nexball/ball.md3";	
		self.scale = 1.3;
	}

	precache_model(self.model);
	setmodel(self, self.model);
	setsize(self, BALL_MINS, BALL_MAXS);
	ball_scale = self.scale;
	self.classname = "keepawayball";
	self.damageforcescale = cvar("g_keepawayball_damageforcescale");
	self.effects = self.effects | EF_FULLBRIGHT;
	self.movetype = MOVETYPE_BOUNCE;
	self.touch = ka_TouchEvent;
	self.think = ka_RespawnBall;
	self.nextthink = time;
	self.flags = FL_ITEM;
	//self.reset = ka_Reset;
	self.owner = world;
	
	// todo: Waypoints and radar
	//WaypointSprite_AttachCarrier();
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

void ka_TouchEvent(entity plyr)
{
	if(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT)
	{
		self.think = ka_SpawnBall;
		self.nextthink = time;
		return;
	}
	if (!plyr) 
		return;
	if (!self) 
		return;
	if ((other.classname != "player" || other.health < 1) && (time > self.ctf_droptime + cvar("g_keepawayball_respawntime")))
		return;
	if (self.wait > time)
		return;

	self.owner = other;
	other.ballcarried = self;
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
	plyr.effects |= 8;
	plyr.alpha = 0.6;

	bprint(other.netname, "^7 has picked up the ball!\n");
	WriteByte(MSG_BROADCAST, SVC_CENTERPRINT);
	WriteString(MSG_BROADCAST, strcat("\n\n", other.netname, "^7 has picked up the ball!\n"));
	sound(self.owner, CHAN_AUTO, "keepaway/pickedup.wav", VOL_BASE, ATTN_NORM);
	
	PlayerScore_Add(other, SP_KEEPAWAY_PICKUPS, 1);

	// todo: Waypoints and radar
}

MUTATOR_HOOKFUNCTION(ka_RemovePlayer)
{
	entity ball;
	ball = self.ballcarried;

	setattachment(ball, world, "");
	ball.movetype = MOVETYPE_BOUNCE;
	ball.solid = SOLID_TRIGGER;
	ball.wait = time + 1;
	ball.ctf_droptime = time;
	ball.think = ka_SpawnBall;
	ball.nextthink = time + cvar("g_keepawayball_respawntime");
	ball.touch = ka_TouchEvent;
	self.effects = EF_LOWPRECISION;
	self.alpha = 1.0;
	ball.alpha = 1.0;
	setorigin(ball, self.origin + '0 0 10');
	ball.velocity = '0 0 200' + '0 100 0'*crandom() + '100 0 0'*crandom();
	
	bprint(self.netname, "^7 has dropped the ball!\n");
	WriteByte(MSG_BROADCAST, SVC_CENTERPRINT);
	WriteString(MSG_BROADCAST, strcat("\n\n", self.netname, "^7 has dropped the ball!\n"));
	sound(other, CHAN_AUTO, "keepaway/dropped.wav", VOL_BASE, ATTN_NORM);	
	
	PlayerScore_Add(self, SP_KEEPAWAY_DROPS, 1);
	
	// todo
	//WaypointSprite_AttachCarrier("ka-ball", ball);
	//WaypointSprite_Kill(plyr.waypointsprite_attachedforcarrier);
	
	ball.owner.ballcarried = world;
	ball.owner = world;

	return 1;
}

/*
void ka_DropEvent(entity plyr, entity ball)
{	
	setattachment(ball, world, "");
	ball.movetype = MOVETYPE_BOUNCE;
	ball.solid = SOLID_TRIGGER;
	ball.wait = time + 1;
	ball.ctf_droptime = time;
	ball.think = ka_SpawnBall;
	ball.nextthink = time + cvar("g_keepawayball_respawntime");
	ball.touch = ka_TouchEvent;
	plyr.effects = EF_LOWPRECISION;
	plyr.alpha = 1.0;
	ball.alpha = 1.0;
	setorigin(ball, plyr.origin + '0 0 10');
	ball.velocity = '0 0 200' + '0 100 0'*crandom() + '100 0 0'*crandom();
	
	bprint(plyr.netname, "^7 has dropped the ball!\n");
	WriteByte(MSG_BROADCAST, SVC_CENTERPRINT);
	WriteString(MSG_BROADCAST, strcat("\n\n", plyr.netname, "^7 has dropped the ball!\n"));
	sound(other, CHAN_AUTO, "keepaway/dropped.wav", VOL_BASE, ATTN_NORM);	
	
	PlayerScore_Add(plyr, SP_KEEPAWAY_DROPS, 1);
	
	// todo
	//WaypointSprite_AttachCarrier("ka-ball", ball);
	//WaypointSprite_Kill(plyr.waypointsprite_attachedforcarrier);
	
	ball.owner.kaballcarried = world;
	ball.owner = world;
}


void ka_CheckWinner()
{

}

MUTATOR_HOOKFUNCTION(ka_PlayerDies)
{
	float i;
	entity e;

	float temp_tag_players_count;
	temp_tag_players_count = tag_players_count;

	if(frag_target.tagcolor == frag_target.tagcolor_original) // if this is the first time we die... (our tagcolor remained unchanged)
	{
		for(i = 0; i < temp_tag_players_count; ++i) // check other players...
		{
			e = tag_players[i];
			if(e == world) // empty slot, skip to next
			{
				if(temp_tag_players_count < TAGCOLOR_MAX - 1) // just in case
					++temp_tag_players_count;
				continue;
			}

			if(e.tagcolor == frag_target.tagcolor_original) // and see if they have our original tag color
			{
				tag_GetFragAttackers_ColorOwner();
				centerprint(e, strcat("^1Your master ^7", frag_target.netname, "^1 was tagged by ^7", frag_attacker.netname, " ^1with ^7", color_owner_red, " ^1color.\n"));
				e.tagcolor = frag_attacker.tagcolor; // if so, remove it, our tag color has now "died out" from this round and we can not win anymore. The attacker will "summon" all of our previously fragged targets, and also us.
				setcolor(e, 16 * e.tagcolor + e.tagcolor);
			}
		}
	}
	else
	{
		frag_target.tagcolor = frag_attacker.tagcolor;
		setcolor(frag_target, 16 * frag_target.tagcolor + frag_target.tagcolor);
	}

	tag_GetFragAttackers_ColorOwner();

	if(color_owner_self)
		color_owner_green = "^2your own";
	centerprint(frag_attacker, strcat("^2You tagged ^7", frag_target.netname, " ^2with ^7", color_owner_green, " ^2color.\n"));

	if(color_owner_self)
		color_owner_red = "^1their own";
	centerprint(frag_target, strcat("^1You were tagged by ^7", frag_attacker.netname, " ^1with ^7", color_owner_red, " ^1color.\n"));
	bprint("^7", frag_target.netname, "^1 was tagged by ^7", frag_attacker.netname, " ^1with ^7", color_owner_red, " ^1color.\n");

	frag_target.health = cvar("g_balance_health_start"); // "respawn" the player :P

	tag_CheckWinner();

	return 1;
}

MUTATOR_HOOKFUNCTION(tag_RemovePlayer)
{

	return 1;
}

MUTATOR_HOOKFUNCTION(tag_GiveFragsForKill)
{
	frag_score = 0; // no frags counted in Tag, maybe later (TODO)
	return 1;
}

MUTATOR_HOOKFUNCTION(tag_PlayerPreThink)
{
	setcolor(self, 16 * self.tagcolor + self.tagcolor); // prevent cheating by changing player colors
	return 1;
}
*/


MUTATOR_DEFINITION(gamemode_keepaway)
{
	MUTATOR_HOOK(MakePlayerObserver, ka_RemovePlayer, CBC_ORDER_ANY);
	MUTATOR_HOOK(ClientDisconnect, ka_RemovePlayer, CBC_ORDER_ANY);
	//MUTATOR_HOOK(PlayerDies, ka_PlayerDies, CBC_ORDER_ANY);
	//MUTATOR_HOOK(PlayerSpawn, ka_PlayerSpawn, CBC_ORDER_ANY);
	//MUTATOR_HOOK(GiveFragsForKill, ka_GiveFragsForKill, CBC_ORDER_FIRST);
	//MUTATOR_HOOK(PlayerPreThink, ka_PlayerPreThink, CBC_ORDER_FIRST);

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

