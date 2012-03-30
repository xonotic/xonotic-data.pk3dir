// ================================================================
//  Official capture the flag game mode coding, reworked by Samual
//  Last updated: March 27th, 2012
// ================================================================

float ctf_ReadScore(string parameter) // make this obsolete
{
	//if(g_ctf_win_mode != 2)
		return cvar(strcat("g_ctf_personal", parameter));
	//else
	//	return cvar(strcat("g_ctf_flag", parameter));
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

void ctf_EventLog(string mode, float flagteam, entity actor) // use an alias for easy changing and quick editing later
{
	if(autocvar_sv_eventlog)
		GameLogEcho(strcat(":ctf:", mode, ":", ftos(flagteam), ((actor != world) ? (strcat(":", ftos(actor.playerid))) : "")));
}


// =======================
// CaptureShield Functions 
// =======================

float ctf_CaptureShield_CheckStatus(entity p) 
{
	float s, se;
	entity e;
	float players_worseeq, players_total;

	if(ctf_captureshield_max_ratio <= 0)
		return FALSE;

	s = PlayerScore_Add(p, SP_SCORE, 0);
	if(s >= -ctf_captureshield_min_negscore)
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
	
	if(players_worseeq >= players_total * ctf_captureshield_max_ratio)
		return FALSE;

	return TRUE;
}

void ctf_CaptureShield_Update(entity player, float wanted_status)
{
	float updated_status = ctf_CaptureShield_CheckStatus(player);
	if((wanted_status == player.ctf_captureshielded) && (updated_status != wanted_status)) // 0: shield only, 1: unshield only
	{
		if(updated_status) // TODO csqc notifier for this // Samual: How?
			Send_CSQC_Centerprint_Generic(player, CPID_CTF_CAPTURESHIELD, "^3You are now ^4shielded^3 from the flag\n^3for ^1too many unsuccessful attempts^3 to capture.\n\n^3Make some defensive scores before trying again.", 5, 0);
		else
			Send_CSQC_Centerprint_Generic(player, CPID_CTF_CAPTURESHIELD, "^3You are now free.\n\n^3Feel free to ^1try to capture^3 the flag again\n^3if you think you will succeed.", 5, 0);
			
		player.ctf_captureshielded = updated_status;
	}
}

float ctf_CaptureShield_Customize()
{
	if not(other.ctf_captureshielded) { return FALSE; }
	if(self.team == other.team) { return FALSE; }
	
	return TRUE;
}

void ctf_CaptureShield_Touch()
{
	if not(other.ctf_captureshielded) { return; }
	if(self.team == other.team) { return; }
	
	vector mymid = (self.absmin + self.absmax) * 0.5;
	vector othermid = (other.absmin + other.absmax) * 0.5;

	Damage(other, self, self, 0, DEATH_HURTTRIGGER, mymid, normalize(othermid - mymid) * ctf_captureshield_force);
	Send_CSQC_Centerprint_Generic(other, CPID_CTF_CAPTURESHIELD, "^3You are ^4shielded^3 from the flag\n^3for ^1too many unsuccessful attempts^3 to capture.\n\n^3Get some defensive scores before trying again.", 5, 0);
}

void ctf_CaptureShield_Spawn(entity flag)
{
	entity shield = spawn();
	
	shield.enemy = self;
	shield.team = self.team;
	shield.touch = ctf_CaptureShield_Touch;
	shield.customizeentityforclient = ctf_CaptureShield_Customize;
	shield.classname = "ctf_captureshield";
	shield.effects = EF_ADDITIVE;
	shield.movetype = MOVETYPE_NOCLIP;
	shield.solid = SOLID_TRIGGER;
	shield.avelocity = '7 0 11';
	shield.scale = 0.5;
	
	setorigin(shield, self.origin);
	setmodel(shield, "models/ctf/shield.md3");
	setsize(shield, shield.scale * shield.mins, shield.scale * shield.maxs);
}


// ==============
// Event Handlers
// ==============

void ctf_Handle_Drop(entity player)
{
	entity flag = player.flagcarried;

	if(!flag) { return; }
	if(flag.speedrunning) { ctf_RespawnFlag(flag); return; }
	
	// reset the flag
	setattachment(flag, world, "");
	setorigin(flag, player.origin - '0 0 24' + '0 0 37');
	flag.owner.flagcarried = world;
	flag.owner = world;
	flag.movetype = MOVETYPE_TOSS;
	flag.solid = SOLID_TRIGGER;
	flag.takedamage = DAMAGE_YES;
	flag.health = flag.max_flag_health;
	flag.velocity = ('0 0 200' + ('0 100 0' * crandom()) + ('100 0 0' * crandom()));
	
	flag.ctf_droptime = time;
	flag.ctf_dropperid = player.playerid;
	flag.ctf_status = FLAG_DROPPED;

	// messages and sounds
	Send_KillNotification(player.netname, flag.netname, "", INFO_LOSTFLAG, MSG_INFO);
	sound(flag, CH_TRIGGER, flag.snd_flag_dropped, VOL_BASE, ATTN_NONE);
	ctf_EventLog("dropped", player.team, player);
	
	// scoring
	PlayerTeamScore_AddScore(player, -ctf_ReadScore("penalty_drop"));	
	PlayerScore_Add(player, SP_CTF_DROPS, 1);

	// waypoints
	if(autocvar_g_ctf_flag_dropped_waypoint)
		WaypointSprite_Spawn("flagdropped", 0, 0, flag, '0 0 64', world, ((autocvar_g_ctf_flag_dropped_waypoint == 2) ? 0 : player.team), flag, wps_flagdropped, FALSE, RADARICON_FLAG, '0 1 1'); // (COLOR_TEAM1 + COLOR_TEAM2 - flag.team)
	
	WaypointSprite_Ping(player.wps_flagcarrier);
	WaypointSprite_Kill(player.wps_flagcarrier);

	if(autocvar_g_ctf_flag_returntime || (autocvar_g_ctf_flag_take_damage && autocvar_g_ctf_flag_health))
	{
		WaypointSprite_UpdateMaxHealth(flag.wps_flagdropped, flag.max_flag_health);
		WaypointSprite_UpdateHealth(flag.wps_flagdropped, flag.health);
	}

	// captureshield
	ctf_CaptureShield_Update(player, 0); // shield only

	// check if the flag will fall off the map
	trace_startsolid = FALSE;
	tracebox(flag.origin, flag.mins, flag.maxs, flag.origin, TRUE, flag);
	if(trace_startsolid)
		dprint("FLAG FALLTHROUGH will happen SOON\n");
}

void ctf_Handle_Capture(entity flag, entity player)
{
	// declarations
	float cap_time, cap_record, success;
	string cap_message, refername;

	// records
	if((autocvar_g_ctf_captimerecord_always) || (player_count - currentbots)) {
		cap_record = ctf_captimerecord;
		cap_time = (time - player.flagcarried.ctf_pickuptime);

		refername = db_get(ServerProgsDB, strcat(GetMapname(), "/captimerecord/netname"));
		refername = ((refername == player.netname) ? "their" : strcat(refername, "^7's"));

		if(!ctf_captimerecord) 
			{ cap_message = strcat(" in ", ftos_decimals(cap_time, 2), " seconds"); success = TRUE; }
		else if(cap_time < cap_record) 
			{ cap_message = strcat(" in ", ftos_decimals(cap_time, 2), " seconds, breaking ", refername, " previous record of ", ftos_decimals(cap_record, 2), " seconds"); success = TRUE; }
		else
			{ cap_message = strcat(" in ", ftos_decimals(cap_time, 2), " seconds, failing to break ", refername, " record of ", ftos_decimals(cap_record, 2), " seconds"); success = FALSE; }

		if(success) {
			ctf_captimerecord = cap_time;
			db_put(ServerProgsDB, strcat(GetMapname(), "/captimerecord/time"), ftos(cap_time));
			db_put(ServerProgsDB, strcat(GetMapname(), "/captimerecord/netname"), player.netname);
			write_recordmarker(player, (time - cap_time), cap_time); } }
	
	// messages and sounds
	Send_KillNotification(player.netname, player.flagcarried.netname, cap_message, INFO_CAPTUREFLAG, MSG_INFO);
	sound(player, CH_TRIGGER, flag.snd_flag_capture, VOL_BASE, ATTN_NONE); // "ctf/*_capture.wav"
	ctf_EventLog("capture", player.flagcarried.team, player);
	
	// scoring
	PlayerTeamScore_AddScore(player, ctf_ReadScore("score_capture"));
	PlayerTeamScore_Add(player, SP_CTF_CAPS, ST_CTF_CAPS, 1);

	// effects
	if (autocvar_g_ctf_flag_capture_effects) 
	{
		pointparticles(particleeffectnum((player.team == COLOR_TEAM1) ? "red_ground_quake" : "blue_ground_quake"), flag.origin, '0 0 0', 1);
		//shockwave_spawn("models/ctf/shockwavetransring.md3", flag.origin - '0 0 15', -0.8, 0, 1);
	}

	// waypointsprites
	WaypointSprite_Kill(player.wps_flagcarrier);

	// reset the flag
	if(flag.speedrunning) { ctf_FakeTimeLimit(player, -1); }
	
	ctf_RespawnFlag(player.flagcarried);
}

void ctf_Handle_Return(entity flag, entity player)
{
	// messages and sounds
	Send_KillNotification (player.netname, flag.netname, "", INFO_RETURNFLAG, MSG_INFO);
	sound(player, CH_TRIGGER, flag.snd_flag_returned, VOL_BASE, ATTN_NONE);
	ctf_EventLog("return", flag.team, player);

	// scoring
	PlayerTeamScore_AddScore(player, ctf_ReadScore(strcat("score_return", ((player.playerid == flag.playerid) ? "_by_killer" : "")))); // reward for return
	PlayerScore_Add(player, SP_CTF_RETURNS, 1); // add to count of returns

	TeamScore_AddToTeam(((flag.team == COLOR_TEAM1) ? COLOR_TEAM2 : COLOR_TEAM1), ST_SCORE, -ctf_ReadScore("penalty_returned")); // punish the team who was last carrying it
	FOR_EACH_PLAYER(player) if(player.playerid == flag.ctf_dropperid) // punish the player who dropped the flag
	{
		PlayerScore_Add(player, SP_SCORE, -ctf_ReadScore("penalty_returned"));
		ctf_CaptureShield_Update(player, 0); // shield only
	}
	
	// reset the flag
	ctf_RespawnFlag(flag);
}

void ctf_Handle_Pickup_Base(entity flag, entity player)
{
	entity tmp_player; // temporary entity which the FOR_EACH_PLAYER loop uses to scan players
	string verbosename; // holds the name of the player OR no name at all for printing in the centerprints

	// attach the flag to the player
	flag.owner = player;
	player.flagcarried = flag;
	setattachment(flag, player, "");
	setorigin(flag, FLAG_CARRY_OFFSET);
	
	// set up the flag
	flag.movetype = MOVETYPE_NONE;
	flag.takedamage = DAMAGE_NO;
	flag.solid = SOLID_NOT;
	flag.angles = '0 0 0';
	flag.ctf_pickuptime = time; // used for timing runs
	flag.ctf_pickupid = player.playerid;
	flag.ctf_status = FLAG_CARRY;
	
	// messages and sounds
	Send_KillNotification (player.netname, flag.netname, "", INFO_GOTFLAG, MSG_INFO);
	sound(player, CH_TRIGGER, flag.snd_flag_taken, VOL_BASE, ATTN_NONE);
	ctf_EventLog("steal", flag.team, player);
	verbosename = ((autocvar_g_ctf_flag_pickup_verbosename) ? strcat(Team_ColorCode(player.team), "(^7", player.netname, Team_ColorCode(player.team), ") ") : "");
	FOR_EACH_PLAYER(tmp_player)
		if(tmp_player.team == flag.team)
			centerprint(tmp_player, strcat("The ", Team_ColorCode(player.team), "enemy ", verbosename, "^7got your flag! Retrieve it!"));
		else if((tmp_player.team == player.team) && (tmp_player != player))
			centerprint(tmp_player, strcat("Your ", Team_ColorCode(player.team), "team mate ", verbosename, "^7got the flag! Protect them!"));
	
	// scoring
	PlayerTeamScore_AddScore(player, ctf_ReadScore("score_pickup_base"));
	PlayerScore_Add(player, SP_CTF_PICKUPS, 1);
	
	// speedrunning
	flag.speedrunning = player.speedrunning; // if speedrunning, flag will flag-return and teleport the owner back after the record
	if((player.speedrunning) && (ctf_captimerecord))
		ctf_FakeTimeLimit(player, time + ctf_captimerecord);
		
	// effects
	if (autocvar_g_ctf_flag_pickup_effects)
	{
		pointparticles(particleeffectnum("smoke_ring"), 0.5 * (flag.absmin + flag.absmax), '0 0 0', 1);
	}
	
	// waypoints 
	WaypointSprite_Spawn("flagcarrier", 0, 0, player, '0 0 64', world, player.team, player, wps_flagcarrier, FALSE, RADARICON_FLAG, '1 1 0'); // (COLOR_TEAM1 + COLOR_TEAM2 - flag.team)
	WaypointSprite_UpdateMaxHealth(player.wps_flagcarrier, '1 0 0' * healtharmor_maxdamage(start_health, start_armorvalue, autocvar_g_balance_armor_blockpercent) * 2);
	WaypointSprite_UpdateHealth(player.wps_flagcarrier, '1 0 0' * healtharmor_maxdamage(player.health, player.armorvalue, autocvar_g_balance_armor_blockpercent));
	WaypointSprite_UpdateTeamRadar(player.wps_flagcarrier, RADARICON_FLAGCARRIER, '1 1 0');
	WaypointSprite_Ping(player.wps_flagcarrier);
}
 
void ctf_Handle_Pickup_Dropped(entity flag, entity player) // make sure this works
{
	// declarations
	float returnscore = bound(0, (flag.pain_finished - time) / autocvar_g_ctf_flag_returntime, 1); // can this be division by zero? FIXME
	entity tmp_player; // temporary entity which the FOR_EACH_PLAYER loop uses to scan players
	string verbosename; // holds the name of the player OR no name at all for printing in the centerprints

	// attach the flag to the player
	flag.owner = player;
	player.flagcarried = flag;
	setattachment(flag, player, "");
	setorigin(flag, FLAG_CARRY_OFFSET);
	
	// set up the flag
	flag.movetype = MOVETYPE_NONE;
	flag.takedamage = DAMAGE_NO;
	flag.health = flag.max_flag_health;
	flag.solid = SOLID_NOT;
	flag.angles = '0 0 0';
	//flag.ctf_pickuptime = time; // don't update pickuptime since this isn't a real steal. 
	flag.ctf_pickupid = player.playerid;
	flag.ctf_status = FLAG_CARRY;

	// messages and sounds
	Send_KillNotification (player.netname, flag.netname, "", INFO_PICKUPFLAG, MSG_INFO);
	sound (player, CH_TRIGGER, flag.snd_flag_taken, VOL_BASE, ATTN_NONE);
	ctf_EventLog("pickup", flag.team, player);
	verbosename = ((autocvar_g_ctf_flag_pickup_verbosename) ? strcat(Team_ColorCode(player.team), "(^7", player.netname, Team_ColorCode(player.team), ") ") : "");
	FOR_EACH_PLAYER(tmp_player)
		if(tmp_player.team == flag.team)
			centerprint(tmp_player, strcat("The ", Team_ColorCode(player.team), "enemy ", verbosename, "^7got your flag! Retrieve it!"));
		else if((tmp_player.team == player.team) && (tmp_player != player))
			centerprint(tmp_player, strcat("Your ", Team_ColorCode(player.team), "team mate ", verbosename, "^7got the flag! Protect them!"));
			
	// scoring
	returnscore = floor((ctf_ReadScore("score_pickup_dropped_late") * (1-returnscore) + ctf_ReadScore("score_pickup_dropped_early") * returnscore) + 0.5);
	print("score is ", ftos(returnscore), "\n");
	PlayerTeamScore_AddScore(player, returnscore);
	PlayerScore_Add(player, SP_CTF_PICKUPS, 1);

	// effects
	if (autocvar_g_ctf_flag_pickup_effects) // field pickup effect
	{
		pointparticles(particleeffectnum("smoke_ring"), 0.5 * (flag.absmin + flag.absmax), '0 0 0', 1);	
	}

	// waypoints
	WaypointSprite_Kill(flag.wps_flagdropped);
	WaypointSprite_Spawn("flagcarrier", 0, 0, player, '0 0 64', world, player.team, player, wps_flagcarrier, FALSE, RADARICON_FLAG, '1 1 0'); // (COLOR_TEAM1 + COLOR_TEAM2 - flag.team)
	WaypointSprite_UpdateMaxHealth(player.wps_flagcarrier, '1 0 0' * healtharmor_maxdamage(start_health, start_armorvalue, autocvar_g_balance_armor_blockpercent) * 2);
	WaypointSprite_UpdateHealth(player.wps_flagcarrier, '1 0 0' * healtharmor_maxdamage(player.health, player.armorvalue, autocvar_g_balance_armor_blockpercent));
	WaypointSprite_UpdateTeamRadar(player.wps_flagcarrier, RADARICON_FLAGCARRIER, '1 1 0');
	WaypointSprite_Ping(player.wps_flagcarrier);
}


// ===================
// Main Flag Functions
// ===================

void ctf_CheckFlagReturn(entity flag)
{
	if(flag.wps_flagdropped) { WaypointSprite_UpdateHealth(flag.wps_flagdropped, flag.health); }
	
	if((flag.health <= 0) || (time > flag.ctf_droptime + autocvar_g_ctf_flag_returntime))
	{
		bprint("The ", flag.netname, " has returned to base\n");
		sound(flag, CH_TRIGGER, flag.snd_flag_respawn, VOL_BASE, ATTN_NONE);
		ctf_EventLog("returned", flag.team, world);
		ctf_RespawnFlag(flag);
	}
}

void ctf_FlagDamage(entity inflictor, entity attacker, float damage, float deathtype, vector hitloc, vector force)
{
	if(autocvar_g_ctf_flag_take_damage) 
	{
		self.health = self.health - damage;
		ctf_CheckFlagReturn(self);
	}
}

void ctf_FlagThink()
{
	// declarations
	entity tmp_entity;

	self.nextthink = time + FLAG_THINKRATE; // only 5 fps, more is unnecessary.

	// captureshield
	if(self == ctf_worldflaglist) // only for the first flag
		FOR_EACH_CLIENT(tmp_entity)
			ctf_CaptureShield_Update(tmp_entity, 1); // release shield only

	// sanity checks
	if(self.mins != FLAG_MIN || self.maxs != FLAG_MAX) { // reset the flag boundaries in case it got squished
		dprint("wtf the flag got squished?\n");
		tracebox(self.origin, FLAG_MIN, FLAG_MAX, self.origin, MOVE_NOMONSTERS, self);
		if(!trace_startsolid) // can we resize it without getting stuck?
			setsize(self, FLAG_MIN, FLAG_MAX); }

	// main think method
	switch(self.ctf_status)
	{	
		case FLAG_BASE: // nothing to do here
			return;
		
		case FLAG_DROPPED:
			if(autocvar_g_ctf_flag_returntime)
			{
				self.health -= ((self.max_flag_health / autocvar_g_ctf_flag_returntime) * FLAG_THINKRATE);
				ctf_CheckFlagReturn(self);
			} 
			return;
				
		case FLAG_CARRY:
			if((self.owner) && (self.speedrunning) && (ctf_captimerecord) && (time >= self.ctf_pickuptime + ctf_captimerecord)) 
			{
				bprint("The ", self.netname, " became impatient after ", ftos_decimals(ctf_captimerecord, 2), " seconds and returned itself\n");
				sound(self, CH_TRIGGER, self.snd_flag_respawn, VOL_BASE, ATTN_NONE);
				ctf_EventLog("returned", self.team, world);
				ctf_RespawnFlag(tmp_entity);

				tmp_entity = self;
				self = self.owner;
				self.impulse = CHIMPULSE_SPEEDRUN; // move the player back to the waypoint they set
				ImpulseCommands();
				self = tmp_entity;
			}
			return;

		default: // this should never happen
			dprint("Think: Flag exists with no status?\n");
			return;
	}
}

void ctf_FlagTouch()
{
	if(gameover) { return; }
	if(!self) { return; }
	if((trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT) 
		|| ((trace_dpstartcontents | trace_dphitcontents) & (DPCONTENTS_SLIME | DPCONTENTS_LAVA | DPCONTENTS_NODROP)))
	{ // The flag fell off the map or into lava/slime, respawn it since players can't get to it
		bprint("The ", self.netname, " fell somewhere it couldn't be reached and has returned to base\n");
		sound (self, CH_TRIGGER, self.snd_flag_respawn, VOL_BASE, ATTN_NONE);
		ctf_EventLog("returned", self.team, world);
		ctf_RespawnFlag(self);
		return;
	}
	if(other.deadflag != DEAD_NO) { return; }
	if(other.classname != "player") 
	{  // The flag just touched an object, most likely the world
		pointparticles(particleeffectnum("kaball_sparks"), self.origin, '0 0 0', 1);
		sound(self, CH_TRIGGER, "keepaway/touch.wav", VOL_BASE, ATTN_NORM);
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
			else if((!other.flagcarried) && ((other.playerid != self.ctf_dropperid) || (time > self.ctf_droptime + autocvar_g_ctf_flag_collect_delay)))
				ctf_Handle_Pickup_Dropped(self, other); // other just picked up a dropped enemy flag
			break;
				
		case FLAG_CARRY:
			dprint("Someone touched a flag even though it was being carried?\n");
			break;

		default: // this should never happen
			dprint("Touch: Flag exists with no status?\n");
			break;
	}
}

void ctf_RespawnFlag(entity flag)
{
	// reset the player (if there is one)
	if((flag.owner) && (flag.owner.flagcarried == flag))
	{
		WaypointSprite_Kill(flag.wps_flagcarrier);
		flag.owner.flagcarried = world;

		if(flag.speedrunning)
			ctf_FakeTimeLimit(flag.owner, -1);
	}

	if((flag.ctf_status == FLAG_DROPPED) && (flag.wps_flagdropped))
		{ WaypointSprite_Kill(flag.wps_flagdropped); }

	// reset the flag
	setattachment(flag, world, "");
	setorigin(flag, flag.ctf_spawnorigin); // replace with flag.ctf_spawnorigin
	flag.movetype = ((flag.noalign) ? MOVETYPE_NONE : MOVETYPE_TOSS);
	flag.takedamage = DAMAGE_NO;
	flag.health = flag.max_flag_health;
	flag.solid = SOLID_TRIGGER;
	flag.velocity = '0 0 0';
	flag.angles = flag.mangle;
	flag.ctf_status = FLAG_BASE;
	flag.flags = FL_ITEM | FL_NOTARGET;
	flag.owner = world;
}

void ctf_Reset()
{
	if(self.owner)
		if(self.owner.classname == "player")
			ctf_Handle_Drop(self.owner);
			
	ctf_RespawnFlag(self);
}

void ctf_DelayedFlagSetup(void) // called after a flag is placed on a map by ctf_FlagSetup()
{
	// declarations
	float teamnumber = ((self.team == COLOR_TEAM1) ? TRUE : FALSE); // if we were originally 1, this will become 0. If we were originally 0, this will become 1. 

	// bot waypoints
	waypoint_spawnforitem_force(self, self.origin);
	self.nearestwaypointtimeout = 0; // activate waypointing again
	self.bot_basewaypoint = self.nearestwaypoint;

	// waypointsprites
	WaypointSprite_SpawnFixed(((teamnumber) ? "redbase" : "bluebase"), self.origin + '0 0 64', self, wps_flagbase, RADARICON_FLAG, colormapPaletteColor(((teamnumber) ? COLOR_TEAM1 : COLOR_TEAM2) - 1, FALSE));
	WaypointSprite_UpdateTeamRadar(self.wps_flagbase, RADARICON_FLAG, colormapPaletteColor(((teamnumber) ? COLOR_TEAM1 : COLOR_TEAM2) - 1, FALSE));

	// captureshield setup
	ctf_CaptureShield_Spawn(self);
}

void ctf_FlagSetup(float teamnumber, entity flag) // called when spawning a flag entity on the map as a spawnfunc 
{	
	// declarations
	teamnumber = fabs(teamnumber - bound(0, g_ctf_reverse, 1)); // if we were originally 1, this will become 0. If we were originally 0, this will become 1. 
	self = flag; // for later usage with droptofloor()
	
	// main setup
	flag.ctf_worldflagnext = ctf_worldflaglist; // link flag into ctf_worldflaglist
	ctf_worldflaglist = flag;

	setattachment(flag, world, "");	

	flag.netname = ((teamnumber) ? "^1RED^7 flag" : "^4BLUE^7 flag");
	flag.team = ((teamnumber) ? COLOR_TEAM1 : COLOR_TEAM2); // COLOR_TEAM1: color 4 team (red) - COLOR_TEAM2: color 13 team (blue)
	flag.items = ((teamnumber) ? IT_KEY2 : IT_KEY1); // IT_KEY2: gold key (redish enough) - IT_KEY1: silver key (bluish enough)
	flag.classname = "item_flag_team";
	flag.target = "###item###"; // wut?
	flag.flags = FL_ITEM | FL_NOTARGET;
	flag.solid = SOLID_TRIGGER;
	flag.takedamage = DAMAGE_NO;
	flag.damageforcescale = autocvar_g_ctf_flag_damageforcescale;	
	flag.max_flag_health = ((autocvar_g_ctf_flag_take_damage && autocvar_g_ctf_flag_health) ? autocvar_g_ctf_flag_health : 100);
	flag.health = flag.max_flag_health;
	flag.event_damage = ctf_FlagDamage;
	flag.velocity = '0 0 0';
	flag.mangle = flag.angles;
	flag.reset = ctf_Reset;
	flag.touch = ctf_FlagTouch;
	flag.think = ctf_FlagThink;
	flag.nextthink = time + 0.2;
	flag.ctf_status = FLAG_BASE;

	// appearence
	if(!flag.model) { flag.model = ((teamnumber) ? autocvar_g_ctf_flag_red_model : autocvar_g_ctf_flag_blue_model); }
	setmodel(flag, flag.model); // precision set below
	setsize(flag, FLAG_MIN, FLAG_MAX);
	setorigin(flag, (flag.origin + FLAG_SPAWN_OFFSET));
	if(!flag.scale) { flag.scale = FLAG_SCALE; }
	
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
	if(!flag.snd_flag_taken) { flag.snd_flag_taken  = ((teamnumber) ? "ctf/red_taken.wav" : "ctf/blue_taken.wav"); }
	if(!flag.snd_flag_returned) { flag.snd_flag_returned = ((teamnumber) ? "ctf/red_returned.wav" : "ctf/blue_returned.wav"); }
	if(!flag.snd_flag_capture) { flag.snd_flag_capture = ((teamnumber) ? "ctf/red_capture.wav" : "ctf/blue_capture.wav"); } // blue team scores by capturing the red flag
	if(!flag.snd_flag_respawn) { flag.snd_flag_respawn = "ctf/flag_respawn.wav"; } // if there is ever a team-based sound for this, update the code to match.
	if(!flag.snd_flag_dropped) { flag.snd_flag_dropped = ((teamnumber) ? "ctf/red_dropped.wav" : "ctf/blue_dropped.wav"); }
	if(!flag.snd_flag_touch) { flag.snd_flag_touch = "ctf/flag_touch.wav"; } // again has no team-based sound
	
	// precache
	precache_sound(flag.snd_flag_taken);
	precache_sound(flag.snd_flag_returned);
	precache_sound(flag.snd_flag_capture);
	precache_sound(flag.snd_flag_respawn);
	precache_sound(flag.snd_flag_dropped);
	precache_sound(flag.snd_flag_touch);
	precache_model(flag.model);
	precache_model("models/ctf/shield.md3");
	precache_model("models/ctf/shockwavetransring.md3");
	
	// flag placement
	if((flag.spawnflags & 1) || flag.noalign) // don't drop to floor, just stay at fixed location
	{ 	
		flag.dropped_origin = flag.origin; 
		flag.noalign = TRUE;
		flag.movetype = MOVETYPE_NONE;
	}
	else // drop to floor, automatically find a platform and set that as spawn origin
	{ 
		flag.noalign = FALSE;
		self = flag;
		droptofloor();
		flag.movetype = MOVETYPE_TOSS; 
	}	
	
	InitializeEntity(flag, ctf_DelayedFlagSetup, INITPRIO_SETLOCATION);
}


// ==============
// Hook Functions
// ==============

MUTATOR_HOOKFUNCTION(ctf_RemovePlayer)
{
	if(self.flagcarried) { ctf_Handle_Drop(self); }
	return 0;
}

MUTATOR_HOOKFUNCTION(ctf_PlayerPreThink)
{
	entity flag;
	
	// initially clear items so they can be set as necessary later.
	self.items &~= (IT_RED_FLAG_CARRYING | IT_RED_FLAG_TAKEN | IT_RED_FLAG_LOST 
		| IT_BLUE_FLAG_CARRYING | IT_BLUE_FLAG_TAKEN | IT_BLUE_FLAG_LOST | IT_CTF_SHIELDED);

	// item for stopping players from capturing the flag too often
	if(self.ctf_captureshielded)
		self.items |= IT_CTF_SHIELDED;

	// scan through all the flags and notify the client about them 
	for (flag = ctf_worldflaglist; flag; flag = flag.ctf_worldflagnext)
	{
		if(flag.ctf_status == FLAG_CARRY)
			if(flag.owner == self)
				self.items |= ((flag.items & IT_KEY2) ? IT_RED_FLAG_CARRYING : IT_BLUE_FLAG_CARRYING); // carrying: self is currently carrying the flag
			else 
				self.items |= ((flag.items & IT_KEY2) ? IT_RED_FLAG_TAKEN : IT_BLUE_FLAG_TAKEN); // taken: someone on self's team is carrying the flag
		else if(flag.ctf_status == FLAG_DROPPED) 
			self.items |= ((flag.items & IT_KEY2) ? IT_RED_FLAG_LOST : IT_BLUE_FLAG_LOST); // lost: the flag is dropped somewhere on the map
	}
	
	if(self.wps_flagcarrier) { WaypointSprite_UpdateHealth(self.wps_flagcarrier, self.health); }
	
	return 0;
}

MUTATOR_HOOKFUNCTION(ctf_PlayerDamage) // for changing damage and force values that are applied to players in g_damage.qc
{	/*
	if(frag_attacker.flagcarried) // if the attacker is a flagcarrier
	{
		if(frag_target == frag_attacker) // damage done to yourself
		{
			frag_damage *= autocvar_g_ctf_flagcarrier_selfdamagefactor;
			frag_force *= autocvar_g_ctf_flagcarrier_selfforcefactor;
		}
		else // damage done to noncarriers
		{
			frag_damage *= autocvar_g_ctf_flagcarrier_damagefactor;
			frag_force *= autocvar_g_ctf_flagcarrier_forcefactor;
		}
	}*/
	return 0;
}

MUTATOR_HOOKFUNCTION(ctf_GiveFragsForKill)
{
	frag_score = 0; // no frags counted in ctf
	return (g_ctf_ignore_frags); // you deceptive little bugger ;3 This needs to be true in order for this function to even count. 
}

MUTATOR_HOOKFUNCTION(ctf_PlayerUseKey)
{
	if(autocvar_g_ctf_allow_drop)
		ctf_Handle_Drop(self);
		
	return 0;
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
CTF flag for team one (Red).
Keys: 
"angle" Angle the flag will point (minus 90 degrees)... 
"model" model to use, note this needs red and blue as skins 0 and 1...
"noise" sound played when flag is picked up...
"noise1" sound played when flag is returned by a teammate...
"noise2" sound played when flag is captured...
"noise3" sound played when flag is lost in the field and respawns itself... 
"noise4" sound played when flag is dropped by a player...
"noise5" sound played when flag touches the ground... */
void spawnfunc_item_flag_team1()
{
	if(!g_ctf) { remove(self); return; }

	ctf_FlagSetup(1, self); // 1 = red
}

/*QUAKED spawnfunc_item_flag_team2 (0 0.5 0.8) (-48 -48 -37) (48 48 37)
CTF flag for team two (Blue).
Keys: 
"angle" Angle the flag will point (minus 90 degrees)... 
"model" model to use, note this needs red and blue as skins 0 and 1...
"noise" sound played when flag is picked up...
"noise1" sound played when flag is returned by a teammate...
"noise2" sound played when flag is captured...
"noise3" sound played when flag is lost in the field and respawns itself... 
"noise4" sound played when flag is dropped by a player...
"noise5" sound played when flag touches the ground... */
void spawnfunc_item_flag_team2()
{
	if(!g_ctf) { remove(self); return; }

	ctf_FlagSetup(0, self); // the 0 is misleading, but -- 0 = blue.
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
	entity oldself;
	oldself = self;
	self = spawn();
	self.classname = "ctf_team";
	self.netname = teamname;
	self.cnt = teamcolor;

	spawnfunc_ctf_team();

	self = oldself;
}

void ctf_DelayedInit() // Do this check with a delay so we can wait for teams to be set up.
{
	// if no teams are found, spawn defaults
	if(find(world, classname, "ctf_team") == world)
	{
		print("No ""ctf_team"" entities found on this map, creating them anyway.\n");
		ctf_SpawnTeam("Red", COLOR_TEAM1 - 1);
		ctf_SpawnTeam("Blue", COLOR_TEAM2 - 1);
	}
	
	ScoreRules_ctf();
}

void ctf_Initialize()
{
	ctf_captimerecord = stof(db_get(ServerProgsDB, strcat(GetMapname(), "/captimerecord/time")));

	ctf_captureshield_min_negscore = autocvar_g_ctf_shield_min_negscore;
	ctf_captureshield_max_ratio = autocvar_g_ctf_shield_max_ratio;
	ctf_captureshield_force = autocvar_g_ctf_shield_force;

	//g_ctf_win_mode = cvar("g_ctf_win_mode");
	
	InitializeEntity(world, ctf_DelayedInit, INITPRIO_GAMETYPE);
}


MUTATOR_DEFINITION(gamemode_ctf)
{
	MUTATOR_HOOK(MakePlayerObserver, ctf_RemovePlayer, CBC_ORDER_ANY);
	MUTATOR_HOOK(ClientDisconnect, ctf_RemovePlayer, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerDies, ctf_RemovePlayer, CBC_ORDER_ANY);
	MUTATOR_HOOK(GiveFragsForKill, ctf_GiveFragsForKill, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerPreThink, ctf_PlayerPreThink, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerDamage_Calculate, ctf_PlayerDamage, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerUseKey, ctf_PlayerUseKey, CBC_ORDER_ANY);
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

	return 0;
}
