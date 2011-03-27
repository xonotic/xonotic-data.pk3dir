// ================================================================
//  Official capture the flag game mode coding, reworked by Samual
//  Last updated: March 25th, 2011
// ================================================================

// Flag constants 
#define FLAG_MIN (PL_MIN + '0 0 -13')
#define FLAG_MAX (PL_MAX + '0 0 -13')
#define FLAG_CARRY_POS '-15 0 7'

// Flag waypointsprite
.entity basewaypoint; 
.entity sprite; 

// CTF flags in the map
entity ctf_worldflaglist;
.entity ctf_worldflagnext;

// Don't allow spam of dropping the flag. 
.float ctf_dropperid;
.float ctf_droptime;

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

// ===================
// Main Flag Functions 
// ===================

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
		should = ctf_captureshield_shielded(p);
		if(should != dir)
		{
			if(should)
			{
				centerprint_atprio(p, CENTERPRIO_SHIELDING, "^3You are now ^4shielded^3 from the flag\n^3for ^1too many unsuccessful attempts^3 to capture.\n\n^3Make some defensive scores before trying again.");
				// TODO csqc notifier for this
			}
			else
			{
				centerprint_atprio(p, CENTERPRIO_SHIELDING, "^3You are now free.\n\n^3Feel free to ^1try to capture^3 the flag again\n^3if you think you will succeed.");
				// TODO csqc notifier for this
			}
			p.ctf_captureshielded = should;
		}
	}
}

float ctf_CaptureShield_customize()
{
	if not(other.ctf_captureshielded)
		return FALSE;
	if(self.team == other.team)
		return FALSE;
	return TRUE;
}

void ctf_CaptureShield_touch()
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

void ctf_flag_spawnstuff()
{
	entity e;
	e = spawn();
	e.enemy = self;
	e.team = self.team;
	e.touch = ctf_captureshield_touch;
	e.customizeentityforclient = ctf_captureshield_customize;
	e.classname = "ctf_captureshield";
	e.effects = EF_ADDITIVE;
	e.movetype = MOVETYPE_NOCLIP;
	e.solid = SOLID_TRIGGER;
	e.avelocity = '7 0 11';
	setorigin(e, self.origin);
	setmodel(e, "models/ctf/shield.md3");
	e.scale = 0.5;
	setsize(e, e.scale * e.mins, e.scale * e.maxs);

	waypoint_spawnforitem_force(self, self.origin);
	self.nearestwaypointtimeout = 0; // activate waypointing again
	self.basewaypoint = self.nearestwaypoint;

	if(self.team == COLOR_TEAM1)
	{
		WaypointSprite_SpawnFixed("redbase", self.origin + '0 0 61', self, sprite);
		WaypointSprite_UpdateTeamRadar(self.sprite, RADARICON_FLAG, colormapPaletteColor(COLOR_TEAM1 - 1, FALSE));
	}
	else
	{
		WaypointSprite_SpawnFixed("bluebase", self.origin + '0 0 61', self, sprite);
		WaypointSprite_UpdateTeamRadar(self.sprite, RADARICON_FLAG, colormapPaletteColor(COLOR_TEAM2 - 1, FALSE));
	}
}

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
	
	if(self.waypointsprite_attachedforcarrier)
		WaypointSprite_DetachCarrier(self);

	ReturnFlag(self);
}

// ===================
// Main Flag Functions
// ===================

void ctf_SetupFlag(float teamnumber, entity flag) // called when spawning a flag entity on the map as a spawnfunc 
{
	// declarations
	teamnumber = fabs(teamnumber - bound(0, g_ctf_reverse, 1));
	string flag_team_by_name;
	
	// main setup
	flag.ctf_worldflagnext = ctf_worldflaglist; // link flag into ctf_worldflaglist // todo: find out if this can be simplified
	ctf_worldflaglist = flag;
	
	flag.netname = ((teamnumber) ? "^1RED^7 flag" : "^4BLUE^7 flag");
	flag.team = ((teamnumber) ? COLOR_TEAM1 : COLOR_TEAM2); // COLOR_TEAM1: color 4 team (red) - COLOR_TEAM2: color 13 team (blue)
	flag.items = ((teamnumber) ? IT_KEY2 : IT_KEY1); // IT_KEY2: gold key (redish enough) - IT_KEY1: silver key (bluish enough)
	flag.classname = "item_flag_team";
	flag.target = "###item###"; // wut?
	flag.noalign = (flag.spawnflags & 1);
	
	flag.nextthink = time + 0.2; // start after doors etc // Samual: 0.2 though? Why? 
	flag.think = ctf_PlaceFlag; // todo: needs renaming
	flag.reset = ctf_Reset;

	// appearence
	if(!flag.model) { flag.model = ((teamnumber) ? autocvar_g_ctf_flag_red_model : autocvar_g_ctf_flag_blue_model); }
	setmodel (flag, flag.model); // precision set below
	setsize(flag, FLAG_MIN, FLAG_MAX);
	setorigin(flag, flag.origin + '0 0 37');
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
	if(!flag.noise3) { flag.noise3 = "ctf/flag_respawn.wav"; } 
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
}

void ctf_PlaceFlag()
{
	if(self.classname != "item_flag_team")
	{
		backtrace("PlaceFlag a non-flag");
		return;
	}

	setattachment(self, world, "");
	self.mdl = self.model;
	self.flags = FL_ITEM;
	self.solid = SOLID_TRIGGER;
	self.movetype = MOVETYPE_NONE;
	self.velocity = '0 0 0';
	self.origin_z = self.origin_z + 6;
	self.think = FlagThink;
	self.touch = FlagTouch;
	self.nextthink = time + 0.1;
	self.cnt = FLAG_BASE;
	self.mangle = self.angles;
	self.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_PLAYERCLIP | DPCONTENTS_BOTCLIP;
	//self.effects = self.effects | EF_DIMLIGHT;
	if(self.noalign)
	{
		self.dropped_origin = self.origin;
	}
	else
	{
		droptofloor();
		self.movetype = MOVETYPE_TOSS;
	}

	InitializeEntity(self, ctf_flag_spawnstuff, INITPRIO_SETLOCATION);
}

void ctf_RegenFlag(entity e)
{
	if(e.classname != "item_flag_team")
	{
		backtrace("RegenFlag a non-flag");
		return;
	}

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
	if(e.classname != "item_flag_team")
	{
		backtrace("ReturnFlag a non-flag");
		return;
	}

	if(e.owner)
	if(e.owner.flagcarried == e)
	{
		WaypointSprite_DetachCarrier(e.owner);
		e.owner.flagcarried = world;

		if(e.speedrunning)
			FakeTimeLimit(e.owner, -1);
	}
	e.owner = world;
	RegenFlag(e);
}

void ctf_DropFlag(entity flag, entity penalty_receiver, entity attacker)
{
	local entity carrier = flag.owner;
	
	// Called on an entity that is not a flag?
	if(flag.classname != "item_flag_team") { 
		backtrace("DropFlag a non-flag");
		return; }
		
	// Reset the flag when speedrunning is enabled.
	if(flag.speedrunning) {
		ReturnFlag(flag);
		return; }
		
	// HOW OFTEN DO THESE EVEN HAPPEN? IS THIS NEEDED? todo: remove if not needed.
	if(!flag.owner) {
		dprint("FLAG: drop - no owner?!?!\n");
		return; }
	if(carrier.flagcarried != flag) {
		dprint("FLAG: drop - owner is not carrying this flag??\n");
		return; }
	
	//bprint(p.netname, "^7 lost the ", e.netname, "\n");
	Send_KillNotification (carrier.netname, flag.netname, "", INFO_LOSTFLAG, MSG_INFO);

	if(penalty_receiver)
		UpdateFrags(penalty_receiver, -ctf_score_value("penalty_suicidedrop"));
	else
		UpdateFrags(carrier, -ctf_score_value("penalty_drop"));

	PlayerScore_Add(carrier, SP_CTF_DROPS, +1);
	ctf_captureshield_update(carrier, 0); // shield only
	flag.playerid = attacker.playerid;
	flag.ctf_droptime = time;
	WaypointSprite_Spawn("flagdropped", 0, 0, flag, '0 0 1' * 61, world, COLOR_TEAM1 + COLOR_TEAM2 - flag.team, flag, waypointsprite_attachedforcarrier, FALSE);
	
	if(carrier.waypointsprite_attachedforcarrier)
	{
		WaypointSprite_Ping(carrier.waypointsprite_attachedforcarrier);
		WaypointSprite_DetachCarrier(carrier);
	}
	else
	{
		bprint("\{1}^1Flag carrier had no flag sprite?!?\n");
		backtrace("Flag carrier had no flag sprite?!?");
	}
	
	ctf_EventLog("dropped", carrier.team, carrier);
	sound (self, CHAN_TRIGGER, self.noise4, VOL_BASE, ATTN_NONE);

	setattachment(flag, world, "");
	flag.damageforcescale = autocvar_g_balance_ctf_damageforcescale;
	flag.takedamage = DAMAGE_YES;

	if(carrier.flagcarried == flag)
		carrier.flagcarried = world;
	flag.owner = world;

	flag.flags = FL_ITEM; // clear FL_ONGROUND and any other junk
	flag.solid = SOLID_TRIGGER;
	flag.movetype = MOVETYPE_TOSS;
	// setsize(e, '-16 -16 0', '16 16 74');
	setorigin(flag, p.origin - '0 0 24' + '0 0 37');
	flag.cnt = FLAG_DROPPED;
	flag.velocity = '0 0 300';
	flag.pain_finished = time + autocvar_g_ctf_flag_returntime;//30;

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
			LogCTF("returned", self.team, world);
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

void FlagTouch()
{
	if(gameover) return;

	local float t;
	local entity player;
	local string s, s0, h0, h1;
	if(other.classname != "player")
		return;
	if(other.health < 1) // ignore dead players
		return;

	if(self.cnt == FLAG_CARRY)
		return;

	if(self.cnt == FLAG_BASE)
	if(other.team == self.team)
	if(other.flagcarried) // he's got a flag
	if(other.flagcarried.team != self.team) // capture
	{
		if(other.flagcarried == world)
		{
			return;
		}
		if(autocvar_g_ctf_captimerecord_always || player_count - currentbots <= 1) // at most one human
		{
			t = time - other.flagcarried.flagpickuptime;
			s = ftos_decimals(t, 2);
			s0 = ftos_decimals(flagcaptimerecord, 2);
			h0 = db_get(ServerProgsDB, strcat(GetMapname(), "/captimerecord/netname"));
			h1 = other.netname;
			if(h0 == h1)
				h0 = "their";
			else
				h0 = strcat(h0, "^7's"); // h0: display text for previous netname
			if(flagcaptimerecord == 0)
			{
				s = strcat(" in ", s, " seconds");
				flagcaptimerecord = t;
				db_put(ServerProgsDB, strcat(GetMapname(), "/captimerecord/time"), ftos(t));
				db_put(ServerProgsDB, strcat(GetMapname(), "/captimerecord/netname"), h1);
				write_recordmarker(other, time - t, t);
			}
			else if(t < flagcaptimerecord)
			{
				s = strcat(" in ", s, " seconds, breaking ", h0, " previous record of ", s0, " seconds");
				flagcaptimerecord = t;
				db_put(ServerProgsDB, strcat(GetMapname(), "/captimerecord/time"), ftos(t));
				db_put(ServerProgsDB, strcat(GetMapname(), "/captimerecord/netname"), h1);
				write_recordmarker(other, time - t, t);
			}
			else
			{
				s = strcat(" in ", s, " seconds, failing to break ", h0, " record of ", s0, " seconds");
			}
		}
		else
			s = "";

		Send_KillNotification (other.netname, other.flagcarried.netname, s, INFO_CAPTUREFLAG, MSG_INFO);

		PlayerTeamScore_Add(other, SP_CTF_CAPS, ST_CTF_CAPS, 1);
		LogCTF("capture", other.flagcarried.team, other);
		// give credit to the individual player
		UpdateFrags(other, ctf_score_value("score_capture"));

		if(autocvar_g_ctf_flag_capture_effects) {
			if(other.team == COLOR_TEAM1) { // red team scores effect
				pointparticles(particleeffectnum("red_ground_quake"), self.origin, '0 0 0', 1);
				flag_cap_ring_spawn(self.origin);
			}
			if(other.team == COLOR_TEAM2) { // blue team scores effect
				pointparticles(particleeffectnum("blue_ground_quake"), self.origin, '0 0 0', 1);
				flag_cap_ring_spawn(self.origin);
			}
		}

		sound (other, CHAN_AUTO, self.noise2, VOL_BASE, ATTN_NONE);
		WaypointSprite_DetachCarrier(other);
		if(self.speedrunning)
			FakeTimeLimit(other, -1);
		RegenFlag (other.flagcarried);
		other.flagcarried = world;
		other.next_take_time = time + 1;
	}
	
	if(self.cnt == FLAG_BASE)
	if(other.team == COLOR_TEAM1 || other.team == COLOR_TEAM2) // only red and blue team can steal flags
	if(other.team != self.team)
	if(!other.flagcarried)
	if(!other.ctf_captureshielded)
	{
		if(other.next_take_time > time)
			return;
			
		if(autocvar_g_ctf_flag_pickup_effects) // pickup effect
			pointparticles(particleeffectnum("smoke_ring"), 0.5 * (self.absmin + self.absmax), '0 0 0', 1);
			
		// pick up
		self.flagpickuptime = time; // used for timing runs
		self.speedrunning = other.speedrunning; // if speedrunning, flag will self-return and teleport the owner back after the record
		if(other.speedrunning)
		if(flagcaptimerecord)
			FakeTimeLimit(other, time + flagcaptimerecord);
		self.solid = SOLID_NOT;
		setorigin(self, self.origin); // relink
		self.owner = other;
		other.flagcarried = self;
		self.cnt = FLAG_CARRY;
		self.angles = '0 0 0';
		//bprint(other.netname, "^7 got the ", self.netname, "\n");
		Send_KillNotification (other.netname, self.netname, "", INFO_GOTFLAG, MSG_INFO);
		UpdateFrags(other, ctf_score_value("score_pickup_base"));
		self.ctf_dropperid = other.playerid;
		PlayerScore_Add(other, SP_CTF_PICKUPS, 1);
		LogCTF("steal", self.team, other);
		sound (other, CHAN_AUTO, self.noise, VOL_BASE, ATTN_NONE);

		FOR_EACH_PLAYER(player)
			if(player.team == self.team)
				centerprint(player, "The enemy got your flag! Retrieve it!");

		self.movetype = MOVETYPE_NONE;
		setorigin(self, FLAG_CARRY_POS);
		setattachment(self, other, "");
		WaypointSprite_AttachCarrier("flagcarrier", other);
		WaypointSprite_UpdateTeamRadar(other.waypointsprite_attachedforcarrier, RADARICON_FLAGCARRIER, '1 1 0');
		WaypointSprite_Ping(self.sprite);

		return;
	}

	if(self.cnt == FLAG_DROPPED)
	{
		self.flags = FL_ITEM; // clear FL_ONGROUND and any other junk
		if(other.team == self.team || (other.team != COLOR_TEAM1 && other.team != COLOR_TEAM2))
		{
			// return flag
			Send_KillNotification (other.netname, self.netname, "", INFO_RETURNFLAG, MSG_INFO);
			//bprint(other.netname, "^7 returned the ", self.netname, "\n");

			// punish the player who last had it
			FOR_EACH_PLAYER(player)
				if(player.playerid == self.ctf_dropperid)
				{
					PlayerScore_Add(player, SP_SCORE, -ctf_score_value("penalty_returned"));
					ctf_captureshield_update(player, 0); // shield only
				}

			// punish the team who was last carrying it
			if(self.team == COLOR_TEAM1)
				TeamScore_AddToTeam(COLOR_TEAM2, ST_SCORE, -ctf_score_value("penalty_returned"));
			else
				TeamScore_AddToTeam(COLOR_TEAM1, ST_SCORE, -ctf_score_value("penalty_returned"));

			// reward the player who returned it
			if(other.playerid == self.playerid) // is this the guy who killed the FC last?
			{
				if(other.team == COLOR_TEAM1 || other.team == COLOR_TEAM2)
					UpdateFrags(other, ctf_score_value("score_return_by_killer"));
				else
					UpdateFrags(other, ctf_score_value("score_return_rogue_by_killer"));
			}
			else
			{
				if(other.team == COLOR_TEAM1 || other.team == COLOR_TEAM2)
					UpdateFrags(other, ctf_score_value("score_return"));
				else
					UpdateFrags(other, ctf_score_value("score_return_rogue"));
			}
			PlayerScore_Add(other, SP_CTF_RETURNS, 1);
			LogCTF("return", self.team, other);
			sound (other, CHAN_AUTO, self.noise1, VOL_BASE, ATTN_NONE);
			ReturnFlag(self);
		}
		else if(!other.flagcarried && (other.playerid != self.ctf_dropperid || time > self.ctf_droptime + autocvar_g_balance_ctf_delay_collect))
		{
			if(self.waypointsprite_attachedforcarrier)
				WaypointSprite_DetachCarrier(self);

			if(autocvar_g_ctf_flag_pickup_effects) // field pickup effect
				pointparticles(particleeffectnum("smoke_ring"), 0.5 * (self.absmin + self.absmax), '0 0 0', 1);
			
			// pick up
			self.solid = SOLID_NOT;
			setorigin(self, self.origin); // relink
			self.owner = other;
			other.flagcarried = self;
			self.cnt = FLAG_CARRY;
			Send_KillNotification (other.netname, self.netname, "", INFO_PICKUPFLAG, MSG_INFO);
			//bprint(other.netname, "^7 picked up the ", self.netname, "\n");

			float f;
			f = bound(0, (self.pain_finished - time) / autocvar_g_ctf_flag_returntime, 1);
			//print("factor is ", ftos(f), "\n");
			f = ctf_score_value("score_pickup_dropped_late") * (1-f)
			  + ctf_score_value("score_pickup_dropped_early") * f;
			f = floor(f + 0.5);
			self.ctf_dropperid = other.playerid;
			//print("score is ", ftos(f), "\n");

			UpdateFrags(other, f);
			PlayerScore_Add(other, SP_CTF_PICKUPS, 1);
			LogCTF("pickup", self.team, other);
			sound (other, CHAN_AUTO, self.noise, VOL_BASE, ATTN_NONE);

			FOR_EACH_PLAYER(player)
				if(player.team == self.team)
					centerprint(player, "The enemy got your flag! Retrieve it!");

			self.movetype = MOVETYPE_NONE;	// flag must have MOVETYPE_NONE here, otherwise it will drop through the floor...
			setorigin(self, FLAG_CARRY_POS);
			setattachment(self, other, "");
			self.damageforcescale = 0;
			self.takedamage = DAMAGE_NO;
			WaypointSprite_AttachCarrier("flagcarrier", other);
			WaypointSprite_UpdateTeamRadar(other.waypointsprite_attachedforcarrier, RADARICON_FLAGCARRIER, '1 1 0');
		}
	}
}



// ============================================
// Spawnfunc Section - aka "giant f%$!ing mess"
// ============================================

/*QUAKED spawnfunc_info_player_team1 (1 0 0) (-16 -16 -24) (16 16 24)
CTF Starting point for a player in team one (Red).
Keys: "angle" viewing angle when spawning. */
void spawnfunc_info_player_team1()
{
	if(g_assault) { remove(self); return; }
	
	self.team = COLOR_TEAM1; // red
	spawnfunc_info_player_deathmatch();
}


/*QUAKED spawnfunc_info_player_team1 (1 0 0) (-16 -16 -24) (16 16 24)
CTF Starting point for a player in team two (Blue).
Keys: "angle" viewing angle when spawning. */
void spawnfunc_info_player_team2()
{
	if(g_assault) { remove(self); return; }
	
	self.team = COLOR_TEAM2; // blue
	spawnfunc_info_player_deathmatch();
}

/*QUAKED spawnfunc_info_player_team1 (1 0 0) (-16 -16 -24) (16 16 24)
CTF Starting point for a player in team three (Yellow).
Keys: "angle" viewing angle when spawning. */
void spawnfunc_info_player_team3()
{
	if(g_assault) { remove(self); return; }
	
	self.team = COLOR_TEAM3; // yellow
	spawnfunc_info_player_deathmatch();
}


/*QUAKED spawnfunc_info_player_team1 (1 0 0) (-16 -16 -24) (16 16 24)
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

/*QUAKED spawnfunc_item_flag_team1 (0 0.5 0.8) (-48 -48 -37) (48 48 37)
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

// code from here on is just to support maps that don't have control point and team entities
void ctf_spawnteam (string teamname, float teamcolor)
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

// spawn some default teams if the map is not set up for ctf
void ctf_spawnteams()
{
	float numteams;

	numteams = 2;//cvar("g_ctf_default_teams");

	ctf_spawnteam("Red", COLOR_TEAM1 - 1);
	ctf_spawnteam("Blue", COLOR_TEAM2 - 1);
}

void ctf_delayedinit()
{
	// if no teams are found, spawn defaults
	if(find(world, classname, "ctf_team") == world)
	{
		ctf_spawnteam("Red", COLOR_TEAM1 - 1);
		ctf_spawnteam("Blue", COLOR_TEAM2 - 1);
	}

	ScoreRules_ctf();
}

void ctf_Initialize()
{
	InitializeEntity(world, ctf_delayedinit, INITPRIO_GAMETYPE);
	flagcaptimerecord = stof(db_get(ServerProgsDB, strcat(GetMapname(), "/captimerecord/time")));

	captureshield_min_negscore = autocvar_g_ctf_shield_min_negscore;
	captureshield_max_ratio = autocvar_g_ctf_shield_max_ratio;
	captureshield_force = autocvar_g_ctf_shield_force;


//#NO AUTOCVARS START
	g_ctf_win_mode = cvar("g_ctf_win_mode");
//#NO AUTOCVARS END
}


MUTATOR_DEFINITION(gamemode_ctf)
{
	MUTATOR_HOOK(MakePlayerObserver, ctf_RemovePlayer, CBC_ORDER_ANY);
	MUTATOR_HOOK(ClientDisconnect, ctf_RemovePlayer, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerDies, ctf_Scoring, CBC_ORDER_ANY);
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