// ================================================================
//  Official capture the flag game mode coding, reworked by Samual
//  Last updated: March 27th, 2011
// ================================================================

// Flag constants 
#define FLAG_MIN (PL_MIN + '0 0 -13')
#define FLAG_MAX (PL_MAX + '0 0 -13')
#define FLAG_CARRY_POS '-15 0 7'

.entity bot_basewaypoint; // Flag waypointsprite
.entity wps_flagbase; 

entity ctf_worldflaglist; // CTF flags in the map
.entity ctf_worldflagnext;

.float ctf_dropperid; // Don't allow spam of dropping the flag
.float ctf_droptime;
.float ctf_status; // status of the flag (FLAG_BASE, FLAG_DROPPED, FLAG_CARRY declared globally)

// Delay between when the person can pick up a flag // replace with .wait? 
.float next_take_time;

// Record time for capturing the flag
float flagcaptimerecord;
.float flagpickuptime;

// CaptureShield: If the player is too bad to be allowed to capture, shield them from taking the flag.
.float ctf_captureshielded; // set to 1 if the player is too bad to be allowed to capture
float captureshield_min_negscore; // punish at -20 points
float captureshield_max_ratio; // punish at most 30% of each team
float captureshield_force; // push force of the shield


// declare functions so they can be used in any order in the file
void ctf_TouchEvent(void);
void ctf_FlagThink(void);
void ctf_SetupFlag(float, entity);


// ==================
// Misc CTF functions
// ==================

float ctf_ReadScore(string parameter)
{
	if(g_ctf_win_mode != 2)
		return cvar(strcat("g_ctf_personal", parameter));
	else
		return cvar(strcat("g_ctf_flag", parameter));
}

void ctf_FakeTimeLimit(entity e, float t)
{
	msg_entity = e;
	WriteByte(MSG_ONE, 3); // svc_updatestat
	WriteByte(MSG_ONE, 236); // STAT_TIMELIMIT
	if(t < 0)
		WriteCoord(MSG_ONE, autocvar_timelimit);
	else
		WriteCoord(MSG_ONE, (t + 1) / 60);
}

void ctf_EventLog(string mode, float flagteam, entity actor)
{
	string s;
	if(!autocvar_sv_eventlog)
		return;
	s = strcat(":ctf:", mode);
	s = strcat(s, ":", ftos(flagteam));
	if(actor != world)
		s = strcat(s, ":", ftos(actor.playerid));
	GameLogEcho(s);
}

void ctf_CaptureShockwave(vector org)
{
	shockwave_spawn("models/ctf/shockwavetransring.md3", org - '0 0 15', -0.8, 0, 1);
}

void ctf_CreateBaseWaypoints(entity flag, float teamnumber)
{
	// for bots
	waypoint_spawnforitem_force(flag, flag.origin);
	flag.nearestwaypointtimeout = 0; // activate waypointing again
	flag.bot_basewaypoint = flag.nearestwaypoint;

	// waypointsprites
	WaypointSprite_SpawnFixed(((teamnumber) ? "redbase" : "bluebase"), flag.origin + '0 0 61', flag, wps_flagbase);
	WaypointSprite_UpdateTeamRadar(flag.wps_flagbase, RADARICON_FLAG, colormapPaletteColor(((teamnumber) ? COLOR_TEAM1 : COLOR_TEAM2) - 1, FALSE));
}

void ctf_SetStatus_ForType(entity flag, float type)
{
	if(flag.cnt ==	FLAG_CARRY)
	{
		if(flag.owner == self)
			self.items |= type * 3; // carrying: self is currently carrying the flag
		else 
			self.items |= type * 1; // taken: someone on self's team is carrying the flag
	}
	else if(flag.cnt == FLAG_DROPPED) 
		self.items |= type * 2; // lost: the flag is dropped somewhere on the map
}

void ctf_SetStatus()
{
	// declarations 
	float redflags, blueflags;
	local entity flag;
	
	// initially clear items so they can be set as necessary later.
	self.items &~= (IT_RED_FLAG_TAKEN | IT_RED_FLAG_LOST | IT_BLUE_FLAG_TAKEN | IT_BLUE_FLAG_LOST | IT_CTF_SHIELDED);

	// item for stopping players from capturing the flag too often
	if(self.ctf_captureshielded)
		self.items |= IT_CTF_SHIELDED;

	// figure out what flags we already own
	for (flag = ctf_worldflaglist; flag; flag = flag.ctf_worldflagnext) if(flag.cnt != FLAG_BASE)
	{
		if(flag.items & IT_KEY2) // blue
			++redflags;
		else if(flag.items & IT_KEY1) // red
			++blueflags;
	}

	// blinking magic: if there is more than one flag, show one of these in a clever way // wtf?
	if(redflags)
		redflags = mod(floor(time * redflags * 0.75), redflags);
		
	if(blueflags)
		blueflags = mod(floor(time * blueflags * 0.75), blueflags);

	for (flag = ctf_worldflaglist; flag; flag = flag.ctf_worldflagnext) if(flag.cnt != FLAG_BASE)
	{
		if(flag.items & IT_KEY2) // blue
		{
			if(--redflags == -1) // happens exactly once (redflags is in 0..count-1, and will --'ed count times) // WHAT THE FUCK DOES THIS MEAN? whoever wrote this is shitty at explaining things.
				ctf_SetStatus_ForType(flag, IT_RED_FLAG_TAKEN);
		}
		else if(flag.items & IT_KEY1) // red
		{
			if(--blueflags == -1) // happens exactly once
				ctf_SetStatus_ForType(flag, IT_BLUE_FLAG_TAKEN);
		}
	}
}

void ctf_Reset()
{
	DropFlag(self, world, world);

	ReturnFlag(self);
}


// ===================
// Main Flag Functions
// ===================

void ctf_SetupFlag(float teamnumber, entity flag) // called when spawning a flag entity on the map as a spawnfunc 
{
	// declarations
	teamnumber = fabs(teamnumber - bound(0, g_ctf_reverse, 1)); // if we were originally 1, this will become 0. If we were originally 0, this will become 1. 
	string flag_team_by_name;
	
	// main setup
	flag.ctf_worldflagnext = ctf_worldflaglist; // link flag into ctf_worldflaglist // todo: find out if this can be simplified
	ctf_worldflaglist = flag;

	setattachment(flag, world, "");	

	flag.netname = ((teamnumber) ? "^1RED^7 flag" : "^4BLUE^7 flag");
	flag.team = ((teamnumber) ? COLOR_TEAM1 : COLOR_TEAM2); // COLOR_TEAM1: color 4 team (red) - COLOR_TEAM2: color 13 team (blue)
	flag.items = ((teamnumber) ? IT_KEY2 : IT_KEY1); // IT_KEY2: gold key (redish enough) - IT_KEY1: silver key (bluish enough)
	flag.classname = "item_flag_team";
	flag.target = "###item###"; // wut?
	flag.flags = FL_ITEM;
	flag.solid = SOLID_TRIGGER;
	flag.velocity = '0 0 0';
	flag.ctf_status = FLAG_BASE;
	flag.mangle = flag.angles;
	flag.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_PLAYERCLIP | DPCONTENTS_BOTCLIP;
	
	if((flag.spawnflags & 1) 
	{ 	
		flag.noalign = TRUE;
		flag.dropped_origin = flag.origin; 
		flag.movetype = MOVETYPE_NONE;
	}
	else 
	{ 
		flag.noalign = FALSE;
		droptofloor(); 
		flag.movetype = MOVETYPE_TOSS; 
	}	
	
	flag.reset = ctf_Reset;
	flag.touch = ctf_TouchEvent;
	flag.think = ctf_RespawnFlag;
	flag.nextthink = time + 0.2; // start after doors etc // Samual: 0.2 though? Why? 

	// appearence
	if(!flag.model) { flag.model = ((teamnumber) ? autocvar_g_ctf_flag_red_model : autocvar_g_ctf_flag_blue_model); }
	setmodel (flag, flag.model); // precision set below
	setsize(flag, FLAG_MIN, FLAG_MAX);
	setorigin(flag, flag.origin + '0 0 37');
	flag.origin_z = flag.origin_z + 6; // why 6?
	if(!flag.scale) { flag.scale = 0.6; }
	
	flag.skin = ((teamnumber) ? autocvar_g_ctf_flag_red_skin : autocvar_g_ctf_flag_blue_skin);
	
	if(autocvar_g_ctf_flag_glowtrails)
	{
		flag.glow_color = ((teamnumber) ? 251 : 210); // 251: red - 210: blue
		flag.glow_size = 25;
		flag.glow_trail = 1;
	}
	
	flag.effects |= EF_LOWPRECISION;
	if(autocvar_g_ctf_fullbrightflags) { flag.effects |= EF_FULLBRIGHT; }
	if(autocvar_g_ctf_dynamiclights)   { flag.effects |= ((teamnumber) ? EF_RED : EF_BLUE); }
	
	// sound 
	if(!flag.noise)  { flag.noise  = ((teamnumber) ? "ctf/red_taken.wav" : "ctf/blue_taken.wav"); }
	if(!flag.noise1) { flag.noise1 = ((teamnumber) ? "ctf/red_returned.wav" : "ctf/blue_returned.wav"); }
	if(!flag.noise2) { flag.noise2 = ((teamnumber) ? "ctf/red_capture.wav" : "ctf/blue_capture.wav"); } // blue team scores by capturing the red flag
	if(!flag.noise3) { flag.noise3 = "ctf/flag_respawn.wav"; } // if there is ever a team-based sound for this, update the code to match.
	if(!flag.noise4) { flag.noise4 = ((teamnumber) ? "ctf/red_dropped.wav" : "ctf/blue_dropped.wav"); }
	
	// precache
	precache_sound(flag.noise);
	precache_sound(flag.noise1);
	precache_sound(flag.noise2);
	precache_sound(flag.noise3);
	precache_sound(flag.noise4);
	precache_model(flag.model);
	precache_model("models/ctf/shield.md3");
	precache_model("models/ctf/shockwavetransring.md3");

	// other initialization stuff
	ctf_CreateBaseWaypoints(flag, teamnumber);
	ctf_CaptureShield_Spawn(flag, teamnumber);
	//InitializeEntity(self, ctf_CaptureShield_Spawn, INITPRIO_SETLOCATION);
}

void ctf_RespawnFlag(entity flag)
{
}

void ctf_RegenFlag(entity e)
{
	if(self.classname != "item_flag_team") { backtrace("ctf_RegenFlag was called incorrectly."); return; }

	if(e.waypointsprite_attachedforcarrier)
		WaypointSprite_DetachCarrier(e);

	setattachment(e, world, "");
	e.damageforcescale = 0;
	e.takedamage = DAMAGE_NO;
	e.movetype = MOVETYPE_NONE;
	if(!e.noalign)
		e.movetype = MOVETYPE_TOSS;
	e.velocity = '0 0 0';
	e.solid = SOLID_TRIGGER;
	// TODO: play a sound here
	setorigin(e, e.dropped_origin);
	e.angles = e.mangle;
	e.cnt = FLAG_BASE;
	e.owner = world;
	e.flags = FL_ITEM; // clear FL_ONGROUND and any other junk // there shouldn't be any "junk" set on this... look into it and make sure it's kept clean. 
}

void ctf_ReturnFlag(entity e)
{
	if(e.classname != "item_flag_team") { backtrace("ctf_ReturnFlag was called incorrectly."); return; }

	if(e.owner)
	if(e.owner.flagcarried == e)
	{
		WaypointSprite_DetachCarrier(e.owner);
		e.owner.flagcarried = world;

		if(e.speedrunning)
			ctf_FakeTimeLimit(e.owner, -1);
	}
	e.owner = world;
	RegenFlag(e);
}

void ctf_Handle_Drop(entity player)
{
	entity flag = player.flagcarried;

	if(!flag) { return; }
	if(flag.speedrunning) { ReturnFlag(flag); return; }
	
	// reset the flag
	setattachment(flag, world, "");
	flag.owner.flagcarried = world;
	flag.owner = world;
	flag.ctf_status = FLAG_DROPPED;
	flag.movetype = MOVETYPE_TOSS;
	flag.solid = SOLID_TRIGGER;
	flag.damageforcescale = autocvar_g_balance_ctf_damageforcescale; // should this really be set here? I don't think so
	flag.takedamage = DAMAGE_YES;
	flag.flags = FL_ITEM; // does this need set?
	setorigin(flag, p.origin - '0 0 24' + '0 0 37');
	flag.ctf_status = FLAG_DROPPED;
	flag.velocity = '0 0 200' + '0 100 0'*crandom() + '100 0 0'*crandom();
	flag.pain_finished = time + autocvar_g_ctf_flag_returntime;//30;
	
	flag.ctf_droptime = time;
	
	// reset the player
	
	
	// messages and sounds
	Send_KillNotification(carrier.netname, flag.netname, "", INFO_LOSTFLAG, MSG_INFO);
	sound(flag, CHAN_TRIGGER, flag.noise4, VOL_BASE, ATTN_NONE);
	ctf_EventLog("dropped", carrier.team, carrier);
	
	// scoring
	PlayerScore_Add(carrier, SP_CTF_DROPS, 1);
	if(penalty_receiver)
		UpdateFrags(penalty_receiver, -ctf_score_value("penalty_suicidedrop"));
	else
		UpdateFrags(carrier, -ctf_score_value("penalty_drop"));
	
	// waypoints
	WaypointSprite_Spawn("flagdropped", 0, 0, flag, '0 0 64', world, (COLOR_TEAM1 + COLOR_TEAM2 - flag.team), flag, waypointsprite_attachedforcarrier, FALSE);
	WaypointSprite_Ping(carrier.waypointsprite_attachedforcarrier);
	WaypointSprite_DetachCarrier(carrier);

	ctf_captureshield_update(carrier, 0); // shield only

	// eh? 
	trace_startsolid = FALSE;
	tracebox(flag.origin, flag.mins, flag.maxs, flag.origin, TRUE, flag);
	if(trace_startsolid)
		dprint("FLAG FALLTHROUGH will happen SOON\n");
}

void ctf_FlagThink()
{
	local entity e;

	self.nextthink = time + 0.1;

	// sorry, we have to reset the flag size if it got squished by something
	if(self.mins != FLAG_MIN || self.maxs != FLAG_MAX)
	{
		// if we can grow back, grow back
		tracebox(self.origin, FLAG_MIN, FLAG_MAX, self.origin, MOVE_NOMONSTERS, self);
		if(!trace_startsolid)
			setsize(self, FLAG_MIN, FLAG_MAX);
	}

	if(self == ctf_worldflaglist) // only for the first flag
	{
		FOR_EACH_CLIENT(e)
			ctf_captureshield_update(e, 1); // release shield only
	}

	if(self.speedrunning)
	if(self.cnt == FLAG_CARRY)
	{
		if(self.owner)
		if(flagcaptimerecord)
		if(time >= self.flagpickuptime + flagcaptimerecord)
		{
			bprint("The ", self.netname, " became impatient after ", ftos_decimals(flagcaptimerecord, 2), " seconds and returned itself\n");

			sound (self, CHAN_TRIGGER, self.noise3, VOL_BASE, ATTN_NONE);
			self.owner.impulse = 141; // returning!

			e = self;
			self = self.owner;
			ReturnFlag(e);
			ImpulseCommands();
			self = e;
			return;
		}
	}

	if(self.cnt == FLAG_BASE)
		return;

	if(self.cnt == FLAG_DROPPED)
	{
		// flag fallthrough? FIXME remove this if bug is really fixed now
		if(self.origin_z < -131072)
		{
			dprint("FLAG FALLTHROUGH just happened\n");
			self.pain_finished = 0;
		}
		setattachment(self, world, "");
		if(time > self.pain_finished)
		{
			bprint("The ", self.netname, " has returned to base\n");
			sound (self, CHAN_TRIGGER, self.noise3, VOL_BASE, ATTN_NONE);
			ctf_EventLog("returned", self.team, world);
			ReturnFlag(self);
		}
		return;
	}

	e = self.owner;
	if(e.classname != "player" || (e.deadflag) || (e.flagcarried != self))
	{
		dprint("CANNOT HAPPEN - player dead and STILL had a flag!\n");
		DropFlag(self, world, world);
		return;
	}

	if(autocvar_g_ctf_allow_drop)
	if(e.BUTTON_USE)
		DropFlag(self, e, world);
}

void ctf_TouchEvent()
{
	if(gameover) { return; }
	if(!self) { return; }
	if(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT)
	{ // The ball fell off the map, respawn it since players can't get to it
		ctf_RespawnFlag();
		return;
	}
	if(other.deadflag != DEAD_NO) { return; }
	if(other.classname != "player") 
	{  // the flag just touched an object, most likely the world
		pointparticles(particleeffectnum("kaball_sparks"), self.origin, '0 0 0', 1);
		sound(self, CHAN_AUTO, "keepaway/touch.wav", VOL_BASE, ATTN_NORM);
		return; 
	}
	else if(self.wait > time) { return; }

	switch(self.ctf_status) 
	{	
		case FLAG_BASE:
			if((other.team == self.team) && (other.flagcarried) && (other.flagcarried.team != self.team))
				ctf_Handle_Capture(self, other); // other just captured the enemies flag to his base
			else if((other.team != self.team) && (!other.flagcarried) && (!other.ctf_captureshielded))
				ctf_Handle_Pickup_Base(self, other); // other just stole the enemies flag
			break;
		
		case FLAG_DROPPED:
			if(other.team == self.team)
				ctf_Handle_Return(self, other); // other just returned his own flag
			else if((!other.flagcarried) && ((other.playerid != self.ctf_dropperid) || (time > self.ctf_droptime + autocvar_g_balance_ctf_delay_collect)))
				ctf_Handle_Pickup_Dropped(self, other); // other just picked up a dropped enemy flag
			break;
				
		case FLAG_CARRY:
		default:
			dprint("Someone touched a flag even though it was being carried? wtf?\n");
			break; // this should never happen
	}
}


// =======================
// CaptureShield Functions 
// =======================

float ctf_CaptureShield_CheckStatus(entity p) // check to see 
{
	float s, se;
	entity e;
	float players_worseeq, players_total;

	if(captureshield_max_ratio <= 0)
		return FALSE;

	s = PlayerScore_Add(p, SP_SCORE, 0);
	if(s >= -captureshield_min_negscore)
		return FALSE;

	players_total = players_worseeq = 0;
	FOR_EACH_PLAYER(e)
	{
		if(e.team != p.team)
			continue;
		se = PlayerScore_Add(e, SP_SCORE, 0);
		if(se <= s)
			++players_worseeq;
		++players_total;
	}

	// player is in the worse half, if >= half the players are better than him, or consequently, if < half of the players are worse
	// use this rule here
	
	if(players_worseeq >= players_total * captureshield_max_ratio)
		return FALSE;

	return TRUE;
}

void ctf_CaptureShield_Update(entity p, float dir)
{
	float should;
	if(dir == p.ctf_captureshielded) // 0: shield only, 1: unshield only
	{
		should = ctf_CaptureShield_CheckStatus(p);
		if(should != dir)
		{
			if(should) // TODO csqc notifier for this
				centerprint_atprio(p, CENTERPRIO_SHIELDING, "^3You are now ^4shielded^3 from the flag\n^3for ^1too many unsuccessful attempts^3 to capture.\n\n^3Make some defensive scores before trying again.");
			else
				centerprint_atprio(p, CENTERPRIO_SHIELDING, "^3You are now free.\n\n^3Feel free to ^1try to capture^3 the flag again\n^3if you think you will succeed.");
			
			p.ctf_captureshielded = should;
		}
	}
}

float ctf_CaptureShield_Customize()
{
	if not(other.ctf_captureshielded)
		return FALSE;
	if(self.team == other.team)
		return FALSE;
	return TRUE;
}

void ctf_CaptureShield_Touch()
{
	if not(other.ctf_captureshielded)
		return;
	if(self.team == other.team)
		return;
	vector mymid;
	vector othermid;
	mymid = (self.absmin + self.absmax) * 0.5;
	othermid = (other.absmin + other.absmax) * 0.5;
	Damage(other, self, self, 0, DEATH_HURTTRIGGER, mymid, normalize(othermid - mymid) * captureshield_force);
	centerprint_atprio(other, CENTERPRIO_SHIELDING, "^3You are ^4shielded^3 from the flag\n^3for ^1too many unsuccessful attempts^3 to capture.\n\n^3Get some defensive scores before trying again.");
}

void ctf_CaptureShield_Spawn()
{
	entity e;
	e = spawn();
	e.enemy = self;
	e.team = self.team;
	e.touch = ctf_CaptureShield_Touch;
	e.customizeentityforclient = ctf_CaptureShield_Customize;
	e.classname = "ctf_captureshield";
	e.effects = EF_ADDITIVE;
	e.movetype = MOVETYPE_NOCLIP;
	e.solid = SOLID_TRIGGER;
	e.avelocity = '7 0 11';
	setorigin(e, self.origin);
	setmodel(e, "models/ctf/shield.md3");
	e.scale = 0.5;
	setsize(e, e.scale * e.mins, e.scale * e.maxs);
}


// ==============
// Hook Functions
// ==============

MUTATOR_HOOKFUNCTION(ctf_RemovePlayer)
{
	if(self.flagcarried) { ctf_DropEvent(self); } // figure this out
	
	return TRUE;
}


// ==========
// Spawnfuncs
// ==========

/*QUAKED spawnfunc_info_player_team1 (1 0 0) (-16 -16 -24) (16 16 24)
CTF Starting point for a player in team one (Red).
Keys: "angle" viewing angle when spawning. */
void spawnfunc_info_player_team1()
{
	if(g_assault) { remove(self); return; }
	
	self.team = COLOR_TEAM1; // red
	spawnfunc_info_player_deathmatch();
}


/*QUAKED spawnfunc_info_player_team2 (1 0 0) (-16 -16 -24) (16 16 24)
CTF Starting point for a player in team two (Blue).
Keys: "angle" viewing angle when spawning. */
void spawnfunc_info_player_team2()
{
	if(g_assault) { remove(self); return; }
	
	self.team = COLOR_TEAM2; // blue
	spawnfunc_info_player_deathmatch();
}

/*QUAKED spawnfunc_info_player_team3 (1 0 0) (-16 -16 -24) (16 16 24)
CTF Starting point for a player in team three (Yellow).
Keys: "angle" viewing angle when spawning. */
void spawnfunc_info_player_team3()
{
	if(g_assault) { remove(self); return; }
	
	self.team = COLOR_TEAM3; // yellow
	spawnfunc_info_player_deathmatch();
}


/*QUAKED spawnfunc_info_player_team4 (1 0 0) (-16 -16 -24) (16 16 24)
CTF Starting point for a player in team four (Purple).
Keys: "angle" viewing angle when spawning. */
void spawnfunc_info_player_team4()
{
	if(g_assault) { remove(self); return; }
	
	self.team = COLOR_TEAM4; // purple
	spawnfunc_info_player_deathmatch();
}

/*QUAKED spawnfunc_item_flag_team1 (0 0.5 0.8) (-48 -48 -37) (48 48 37)
CTF flag for team one (Red). Multiple flags are allowed.
Keys: 
"angle" Angle the flag will point (minus 90 degrees)... 
"model" model to use, note this needs red and blue as skins 0 and 1 (default models/ctf/flag.md3)...
"noise" sound played when flag is picked up (default ctf/take.wav)...
"noise1" sound played when flag is returned by a teammate (default ctf/return.wav)...
"noise2" sound played when flag is captured (default ctf/redcapture.wav)...
"noise3" sound played when flag is lost in the field and respawns itself (default ctf/respawn.wav)... */
void spawnfunc_item_flag_team1()
{
	if(!g_ctf) { remove(self); return; }

	ctf_SetupFlag(1, self);
}

/*QUAKED spawnfunc_item_flag_team2 (0 0.5 0.8) (-48 -48 -37) (48 48 37)
CTF flag for team two (Blue). Multiple flags are allowed.
Keys: 
"angle" Angle the flag will point (minus 90 degrees)... 
"model" model to use, note this needs red and blue as skins 0 and 1 (default models/ctf/flag.md3)...
"noise" sound played when flag is picked up (default ctf/take.wav)...
"noise1" sound played when flag is returned by a teammate (default ctf/return.wav)...
"noise2" sound played when flag is captured (default ctf/redcapture.wav)...
"noise3" sound played when flag is lost in the field and respawns itself (default ctf/respawn.wav)... */
void spawnfunc_item_flag_team2()
{
	if(!g_ctf) { remove(self); return; }

	ctf_SetupFlag(0, self);
}

/*QUAKED spawnfunc_ctf_team (0 .5 .8) (-16 -16 -24) (16 16 32)
Team declaration for CTF gameplay, this allows you to decide what team names and control point models are used in your map.
Note: If you use spawnfunc_ctf_team entities you must define at least 2!  However, unlike domination, you don't need to make a blank one too.
Keys:
"netname" Name of the team (for example Red, Blue, Green, Yellow, Life, Death, Offense, Defense, etc)...
"cnt" Scoreboard color of the team (for example 4 is red and 13 is blue)... */
void spawnfunc_ctf_team()
{
	if(!g_ctf) { remove(self); return; }
	
	self.classname = "ctf_team";
	self.team = self.cnt + 1;
}


// ==============
// Initialization
// ==============

// code from here on is just to support maps that don't have flag and team entities
void ctf_SpawnTeam (string teamname, float teamcolor)
{
	local entity oldself;
	oldself = self;
	self = spawn();
	self.classname = "ctf_team";
	self.netname = teamname;
	self.cnt = teamcolor;

	spawnfunc_ctf_team();

	self = oldself;
}

void ctf_DelayedInit()
{
	// if no teams are found, spawn defaults
	if(find(world, classname, "ctf_team") == world)
	{
		ctf_SpawnTeam("Red", COLOR_TEAM1 - 1);
		ctf_SpawnTeam("Blue", COLOR_TEAM2 - 1);
	}
}

void ctf_Initialize()
{
	flagcaptimerecord = stof(db_get(ServerProgsDB, strcat(GetMapname(), "/captimerecord/time")));

	captureshield_min_negscore = autocvar_g_ctf_shield_min_negscore;
	captureshield_max_ratio = autocvar_g_ctf_shield_max_ratio;
	captureshield_force = autocvar_g_ctf_shield_force;

	g_ctf_win_mode = cvar("g_ctf_win_mode");
	
	ScoreRules_ctf();
	
	InitializeEntity(world, ctf_DelayedInit, INITPRIO_GAMETYPE);
}


MUTATOR_DEFINITION(gamemode_ctf)
{
	MUTATOR_HOOK(MakePlayerObserver, ctf_RemovePlayer, CBC_ORDER_ANY);
	MUTATOR_HOOK(ClientDisconnect, ctf_RemovePlayer, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerDies, ctf_RemovePlayer, CBC_ORDER_ANY);
	//MUTATOR_HOOK(GiveFragsForKill, ctf_GiveFragsForKill, CBC_ORDER_ANY);
	//MUTATOR_HOOK(PlayerPreThink, ctf_PlayerPreThink, CBC_ORDER_ANY);
	//MUTATOR_HOOK(PlayerDamage_Calculate, ctf_PlayerDamage, CBC_ORDER_ANY);
	//MUTATOR_HOOK(PlayerPowerups, ctf_PlayerPowerups, CBC_ORDER_ANY);

	MUTATOR_ONADD
	{
		if(time > 1) // game loads at time 1
			error("This is a game type and it cannot be added at runtime.");
		g_ctf = 1;
		ctf_Initialize();
	}

	MUTATOR_ONREMOVE
	{
		g_ctf = 0;
		error("This is a game type and it cannot be removed at runtime.");
	}

	return TRUE;
}
