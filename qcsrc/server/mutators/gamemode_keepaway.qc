void ka_SpawnBall(void);
void ka_TouchEvent(void);
void ka_RespawnBall(void);
void ka_DropEvent(entity);

float ka_ballcarrier_waypointsprite_visible_for_player(entity);

void ka_Initialize() // run at the start of a match, initiates game mode
{
	if(!g_keepaway)
		return;
		
	precache_sound("keepaway/pickedup.wav");
	precache_sound("keepaway/dropped.wav");
	precache_sound("keepaway/respawn.wav");
	precache_sound("keepaway/touch.wav");

	ScoreRules_keepaway();
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
	e.model = "models/orbs/orbblue.md3";	
	e.scale = 1;
	precache_model(e.model);
	setmodel(e, e.model);
	setsize(e, '-16 -16 -20', '16 16 20'); // 20 20 20 was too big, player is only 16 16 24... gotta cheat with the Z (20) axis so that the particle isn't cut off
	e.classname = "keepawayball";
	e.damageforcescale = autocvar_g_keepawayball_damageforcescale;
	e.takedamage = DAMAGE_YES;
	e.glow_color = autocvar_g_keepawayball_trail_color;
	e.glow_trail = TRUE;
	e.movetype = MOVETYPE_BOUNCE;
	e.touch = ka_TouchEvent;
	e.flags = FL_ITEM;
	e.reset = ka_Reset;
	e.owner = world;

	InitializeEntity(e, ka_RespawnBall, INITPRIO_SETLOCATION); // is this the right priority? Neh, I have no idea.. Well-- it works! So. 
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
		self.think = ka_RespawnBall;
		self.nextthink = time + autocvar_g_keepawayball_respawntime;
		
		pointparticles(particleeffectnum("electro_combo"), oldballorigin, '0 0 0', 1);
		pointparticles(particleeffectnum("electro_combo"), self.origin, '0 0 0', 1);

		WaypointSprite_Spawn("ka-ball", 0, 0, self, '0 0 64', world, self.team, self, waypointsprite_attachedforcarrier, FALSE);
		WaypointSprite_UpdateTeamRadar(self.waypointsprite_attachedforcarrier, RADARICON_FLAGCARRIER, '0 1 1');
		WaypointSprite_Ping(self.waypointsprite_attachedforcarrier);	

		sound(self, CHAN_AUTO, "keepaway/respawn.wav", VOL_BASE, ATTN_NONE); // ATTN_NONE (it's a sound intended to be heard anywhere) 
	}
	else
	{
		ka_RespawnBall(); // finding a location failed, retry 
	}
}

void ka_TouchEvent() // runs any time that the ball comes in contact with something
{
	if(!self) { return; }
	if(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT)
	{ // The ball fell off the map, respawn it since players can't get to it
		ka_RespawnBall();
		return;
	}
	if(other.deadflag != DEAD_NO) { return; }
	if(other.classname != "player") 
	{  // The ball just touched an object, most likely the world
		pointparticles(particleeffectnum("kaball_sparks"), self.origin, '0 0 0', 1);
		sound(self, CHAN_AUTO, "keepaway/touch.wav", VOL_BASE, ATTN_NORM);
		return; 
	}
	else if(self.wait > time) { return; }

	// attach the ball to the player
	self.owner = other;
	other.ballcarried = self;
	setattachment(self, other, "");
	setorigin(self, '3 0 20');
	
	// make the ball invisible/unable to do anything
	self.velocity = '0 0 0';
	self.movetype = MOVETYPE_NONE;
	self.touch = SUB_Null;
	self.effects |= EF_NODRAW;
	self.think = SUB_Null;
	self.nextthink = 0;
	self.takedamage = DAMAGE_NO;

	// apply effects to player
	other.glow_color = autocvar_g_keepawayball_trail_color;
	other.glow_trail = TRUE;
	other.effects |= EF_DIMLIGHT;
	other.alpha = autocvar_g_keepaway_ballcarrier_alpha;
	other.exteriorweaponentity.alpha = autocvar_g_keepaway_ballcarrier_alpha;

	// messages and sounds
	Send_KillNotification(other.netname, "", "", KA_PICKUPBALL, MSG_KA);
	WriteByte(MSG_BROADCAST, SVC_CENTERPRINT);
	WriteString(MSG_BROADCAST, strcat("\n\n", other.netname, "^7 has picked up the ball!\n"));
	sound(self.owner, CHAN_AUTO, "keepaway/pickedup.wav", VOL_BASE, ATTN_NONE); // ATTN_NONE (it's a sound intended to be heard anywhere) 
	
	// scoring
	PlayerScore_Add(other, SP_KEEPAWAY_PICKUPS, 1);

	// waypoints
	WaypointSprite_AttachCarrier("ka-ballcarrier", other);
	other.waypointsprite_attachedforcarrier.waypointsprite_visible_for_player = ka_ballcarrier_waypointsprite_visible_for_player;
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
	
	// reset the ball
	setattachment(ball, world, "");
	ball.movetype = MOVETYPE_BOUNCE;
	ball.solid = SOLID_TRIGGER; // is this needed? 
	ball.wait = time + 1; 
	ball.think = ka_RespawnBall;
	ball.nextthink = time + autocvar_g_keepawayball_respawntime;
	ball.touch = ka_TouchEvent;
	ball.takedamage = DAMAGE_YES;
	ball.effects &~= EF_NODRAW; 
	setorigin(ball, plyr.origin + '0 0 10');
	ball.velocity = '0 0 200' + '0 100 0'*crandom() + '100 0 0'*crandom();
	ball.owner.ballcarried = world; // I hope nothing checks to see if the world has the ball in the rest of my code :P 
	ball.owner = world;
	
	// reset the player effects
	plyr.effects &~= EF_DIMLIGHT;
	plyr.alpha = default_player_alpha;
	plyr.exteriorweaponentity.alpha = default_weapon_alpha; 
	plyr.glow_trail = FALSE;
	
	// messages and sounds
	Send_KillNotification(plyr.netname, "", "", KA_DROPBALL, MSG_KA);
	WriteByte(MSG_BROADCAST, SVC_CENTERPRINT);
	WriteString(MSG_BROADCAST, strcat("\n\n", plyr.netname, "^7 has dropped the ball!\n"));
	sound(other, CHAN_AUTO, "keepaway/dropped.wav", VOL_BASE, ATTN_NONE);	// ATTN_NONE (it's a sound intended to be heard anywhere) 
	
	// scoring
	PlayerScore_Add(plyr, SP_KEEPAWAY_DROPS, 1);
	
	// waypoints
	WaypointSprite_Spawn("ka-ball", 0, 0, ball, '0 0 64', world, ball.team, ball, waypointsprite_attachedforcarrier, FALSE);
	WaypointSprite_UpdateRule(ball.waypointsprite_attachedforcarrier, 0, SPRITERULE_DEFAULT);
	WaypointSprite_UpdateTeamRadar(ball.waypointsprite_attachedforcarrier, RADARICON_FLAGCARRIER, '0 1 1');
	WaypointSprite_Ping(ball.waypointsprite_attachedforcarrier);	
	WaypointSprite_Kill(plyr.waypointsprite_attachedforcarrier);
}

float ka_ballcarrier_waypointsprite_visible_for_player(entity e) // runs on waypoints which are attached to ballcarriers, updates once per frame 
{
	if(e.ballcarried)
	{
		if(other.classname == "spectator") 
			return FALSE; // we don't want spectators of the ballcarrier to see the attached waypoint on the top of their screen
		else if(g_minstagib && (e.items & IT_STRENGTH))
			return FALSE; // if the ballcarrier has invisibility, don't draw the waypoint as this is the function of invisibility in keepaway
	}

	return TRUE;
}

MUTATOR_HOOKFUNCTION(ka_RemovePlayer)
{
	if(self.ballcarried) { ka_DropEvent(self); } // a player with the ball has left the match, drop it
	return 0;
}

MUTATOR_HOOKFUNCTION(ka_Scoring)
{
	if((frag_attacker != frag_target) && (frag_attacker.classname == "player"))
	{
		if(frag_target.ballcarried) { // add to amount of times killing carrier
			PlayerScore_Add(frag_attacker, SP_KEEPAWAY_CARRIERKILLS, 1);
			if(autocvar_g_keepaway_bckillscore) // add bckills to the score
				PlayerScore_Add(frag_attacker, SP_KEEPAWAY_SCORE, 1);
		}
		else if(!frag_attacker.ballcarried)
			if(autocvar_g_keepaway_noncarrier_warn)
				centerprint_atprio(frag_attacker, (CENTERPRIO_SPAM + 5), "Killing people while you don't have the ball gives no points!");

		if(frag_attacker.ballcarried) // add to amount of kills while ballcarrier
			PlayerScore_Add(frag_attacker, SP_KEEPAWAY_SCORE, 1);
	}

	if(self.ballcarried) { ka_DropEvent(self); } // a player with the ball has died, drop it
	return 0;
}

MUTATOR_HOOKFUNCTION(ka_GiveFragsForKill)
{
	frag_score = 0; // no frags counted in keepaway
	return 0;
}

MUTATOR_HOOKFUNCTION(ka_PlayerPreThink)
{
	// clear the item used for the ball in keepaway
	self.items &~= IT_KEY1;
	
	// if the player has the ball, make sure they have the item for it (Used for HUD primarily)
	if(self.ballcarried)
		self.items |= IT_KEY1;

	// drop the ball if the player presses the use button
	if(self.BUTTON_USE)
		if(self.ballcarried) { ka_DropEvent(self); } 

	return 0;
}

MUTATOR_HOOKFUNCTION(ka_PlayerDamage) // for changing damage and force values that are applied to players in g_damage.qc
{
	if(frag_attacker.ballcarried) // if the attacker is a ballcarrier
	{
		if(frag_target == frag_attacker) // damage done to yourself
		{
			frag_damage *= autocvar_g_keepaway_ballcarrier_selfdamage;
			frag_force *= autocvar_g_keepaway_ballcarrier_selfforce;
		}
		else // damage done to noncarriers
		{
			frag_damage *= autocvar_g_keepaway_ballcarrier_damage;
			frag_force *= autocvar_g_keepaway_ballcarrier_force;
		}
	}
	else if not(frag_target.ballcarried) // if the target is a noncarrier
	{
		if(frag_target == frag_attacker) // damage done to yourself
		{
			frag_damage *= autocvar_g_keepaway_noncarrier_selfdamage;
			frag_force *= autocvar_g_keepaway_noncarrier_selfforce;
		}
		else // damage done to other noncarriers
		{
			frag_damage *= autocvar_g_keepaway_noncarrier_damage;
			frag_force *= autocvar_g_keepaway_noncarrier_force;
		}
	}
	return 0;
}

MUTATOR_HOOKFUNCTION(ka_PlayerPowerups)
{
	if(self.ballcarried)
	{ 
		// if the player has the ball, force ballcarrier alpha upon them
		self.alpha = autocvar_g_keepaway_ballcarrier_alpha;
		self.exteriorweaponentity.alpha = autocvar_g_keepaway_ballcarrier_alpha;
	
		// if we're in minstagib and a ballcarrier has just picked up invisibility, 
		// notify all the other players that the ballcarrier no longer has a waypoint
		if(g_minstagib)
		{
			if(olditems & IT_STRENGTH) 
			{
				if(time > self.strength_finished) 
				{	// this only runs ONCE right after the player loses invisibility
					bprint(self.netname, "^7 isn't invisible from radar anymore.\n");
				}
			}
			else 
			{
				if(time < self.strength_finished)
				{	// this only runs ONCE right after the player gains invisibility
					bprint(self.netname, "^7 has picked up invisibility and can no longer be seen on radar!\n");
				}
			}
		}
	}
	else if(g_minstagib)
	{
		// if we're in minstagib and a noncarrier has invisibility, assure that we apply the invisibility effects normally
		if(olditems & IT_STRENGTH) 
		{
			self.alpha = g_minstagib_invis_alpha;
			self.exteriorweaponentity.alpha = g_minstagib_invis_alpha;
		}
	}
	else
	{
		// if we're a normal player with no powerups that edit alpha make sure the alpha is default. 
		// (normal powerups just use EF_ADDITIVE)
		self.alpha = default_player_alpha;
		self.exteriorweaponentity.alpha = default_weapon_alpha;
	}
	
	return 0;
}

MUTATOR_DEFINITION(gamemode_keepaway)
{
	// I don't quite understand these orders, perhaps someone could enlighten me?
	MUTATOR_HOOK(MakePlayerObserver, ka_RemovePlayer, CBC_ORDER_ANY);
	MUTATOR_HOOK(ClientDisconnect, ka_RemovePlayer, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerDies, ka_Scoring, CBC_ORDER_ANY);
	MUTATOR_HOOK(GiveFragsForKill, ka_GiveFragsForKill, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerPreThink, ka_PlayerPreThink, CBC_ORDER_FIRST);
	MUTATOR_HOOK(PlayerDamage_Calculate, ka_PlayerDamage, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerPowerups, ka_PlayerPowerups, CBC_ORDER_ANY);

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
