#ifndef GAMEMODE_CTF_H
#define GAMEMODE_CTF_H

#ifndef CSQC
void ctf_Initialize();

REGISTER_MUTATOR(ctf, false)
{
	MUTATOR_ONADD
	{
		if (time > 1) // game loads at time 1
			error("This is a game type and it cannot be added at runtime.");
		ctf_Initialize();

		ActivateTeamplay();
		SetLimits(autocvar_capturelimit_override, autocvar_captureleadlimit_override, -1, -1);
		have_team_spawns = -1; // request team spawns
	}

	MUTATOR_ONROLLBACK_OR_REMOVE
	{
		// we actually cannot roll back ctf_Initialize here
		// BUT: we don't need to! If this gets called, adding always
		// succeeds.
	}

	MUTATOR_ONREMOVE
	{
		LOG_INFO("This is a game type and it cannot be removed at runtime.");
		return -1;
	}

	return 0;
}
#endif

#ifdef SVQC
// used in cheats.qc
void ctf_RespawnFlag(entity flag);

// score rule declarations
const int ST_CTF_CAPS = 1;
const int SP_CTF_CAPS = 4;
const int SP_CTF_CAPTIME = 5;
const int SP_CTF_PICKUPS = 6;
const int SP_CTF_DROPS = 7;
const int SP_CTF_FCKILLS = 8;
const int SP_CTF_RETURNS = 9;

CLASS(Flag, Pickup)
    ATTRIB(Flag, m_mins, vector, PL_MIN_CONST + '0 0 -13')
    ATTRIB(Flag, m_maxs, vector, PL_MAX_CONST + '0 0 -13')
ENDCLASS(Flag)
Flag CTF_FLAG; STATIC_INIT(Flag) { CTF_FLAG = NEW(Flag); }
void ctf_FlagTouch() { SELFPARAM(); ITEM_HANDLE(Pickup, CTF_FLAG, this, other); }

// flag constants // for most of these, there is just one question to be asked: WHYYYYY?

const float FLAG_SCALE = 0.6;

const float FLAG_THINKRATE = 0.2;
const float FLAG_TOUCHRATE = 0.5;
const float WPFE_THINKRATE = 0.5;

const vector FLAG_DROP_OFFSET = ('0 0 32');
const vector FLAG_CARRY_OFFSET = ('-16 0 8');
#define FLAG_SPAWN_OFFSET ('0 0 1' * (PL_MAX_CONST.z - 13))
const vector FLAG_WAYPOINT_OFFSET = ('0 0 64');
const vector FLAG_FLOAT_OFFSET = ('0 0 32');
const vector FLAG_PASS_ARC_OFFSET = ('0 0 -10');

const vector VEHICLE_FLAG_OFFSET = ('0 0 96');
const float VEHICLE_FLAG_SCALE = 1.0;

// waypoint colors
#define WPCOLOR_ENEMYFC(t) ((t) ? colormapPaletteColor(t - 1, false) * 0.75 : '1 1 1')
#define WPCOLOR_FLAGCARRIER(t) (WP_FlagCarrier.m_color)
#define WPCOLOR_DROPPEDFLAG(t) ((t) ? ('0.25 0.25 0.25' + colormapPaletteColor(t - 1, false)) * 0.5 : '1 1 1')

// sounds
#define snd_flag_taken noise
#define snd_flag_returned noise1
#define snd_flag_capture noise2
#define snd_flag_respawn noise3
.string snd_flag_dropped;
.string snd_flag_touch;
.string snd_flag_pass;

// effects
.string toucheffect;
.string passeffect;
.string capeffect;

// list of flags on the map
entity ctf_worldflaglist;
.entity ctf_worldflagnext;
.entity ctf_staleflagnext;

// waypoint sprites
.entity bot_basewaypoint; // flag waypointsprite
.entity wps_helpme;
.entity wps_flagbase;
.entity wps_flagcarrier;
.entity wps_flagdropped;
.entity wps_enemyflagcarrier;
.float wps_helpme_time;
bool wpforenemy_announced;
float wpforenemy_nextthink;

// statuses
const int FLAG_BASE = 1;
const int FLAG_DROPPED = 2;
const int FLAG_CARRY = 3;
const int FLAG_PASSING = 4;

const int DROP_NORMAL = 1;
const int DROP_THROW = 2;
const int DROP_PASS = 3;
const int DROP_RESET = 4;

const int PICKUP_BASE = 1;
const int PICKUP_DROPPED = 2;

const int CAPTURE_NORMAL = 1;
const int CAPTURE_DROPPED = 2;

const int RETURN_TIMEOUT = 1;
const int RETURN_DROPPED = 2;
const int RETURN_DAMAGE = 3;
const int RETURN_SPEEDRUN = 4;
const int RETURN_NEEDKILL = 5;

void ctf_Handle_Throw(entity player, entity receiver, float droptype);

// flag properties
#define ctf_spawnorigin dropped_origin
bool ctf_stalemate; // indicates that a stalemate is active
float ctf_captimerecord; // record time for capturing the flag
.float ctf_pickuptime;
.float ctf_droptime;
.int ctf_status; // status of the flag (FLAG_BASE, FLAG_DROPPED, FLAG_CARRY declared globally)
.entity ctf_dropper; // don't allow spam of dropping the flag
.int max_flag_health;
.float next_take_time;
.bool ctf_flagdamaged;
int ctf_teams;

// passing/throwing properties
.float pass_distance;
.entity pass_sender;
.entity pass_target;
.float throw_antispam;
.float throw_prevtime;
.int throw_count;

// CaptureShield: If the player is too bad to be allowed to capture, shield them from taking the flag.
.bool ctf_captureshielded; // set to 1 if the player is too bad to be allowed to capture
float ctf_captureshield_min_negscore; // punish at -20 points
float ctf_captureshield_max_ratio; // punish at most 30% of each team
float ctf_captureshield_force; // push force of the shield

// 1 flag ctf
bool ctf_oneflag; // indicates whether or not a neutral flag has been found

// bot player logic
const int HAVOCBOT_CTF_ROLE_NONE = 0;
const int HAVOCBOT_CTF_ROLE_DEFENSE = 2;
const int HAVOCBOT_CTF_ROLE_MIDDLE = 4;
const int HAVOCBOT_CTF_ROLE_OFFENSE = 8;
const int HAVOCBOT_CTF_ROLE_CARRIER = 16;
const int HAVOCBOT_CTF_ROLE_RETRIEVER = 32;
const int HAVOCBOT_CTF_ROLE_ESCORT = 64;

.bool havocbot_cantfindflag;

vector havocbot_ctf_middlepoint;
float havocbot_ctf_middlepoint_radius;

void havocbot_role_ctf_setrole(entity bot, int role);

// team checking
#define CTF_SAMETEAM(a,b) ((autocvar_g_ctf_reverse || (ctf_oneflag && autocvar_g_ctf_oneflag_reverse)) ? DIFF_TEAM(a,b) : SAME_TEAM(a,b))
#define CTF_DIFFTEAM(a,b) ((autocvar_g_ctf_reverse || (ctf_oneflag && autocvar_g_ctf_oneflag_reverse)) ? SAME_TEAM(a,b) : DIFF_TEAM(a,b))

// networked flag statuses
.int ctf_flagstatus = _STAT(CTF_FLAGSTATUS);
#endif

const int CTF_RED_FLAG_TAKEN			= 1;
const int CTF_RED_FLAG_LOST				= 2;
const int CTF_RED_FLAG_CARRYING			= 3;
const int CTF_BLUE_FLAG_TAKEN			= 4;
const int CTF_BLUE_FLAG_LOST			= 8;
const int CTF_BLUE_FLAG_CARRYING		= 12;
const int CTF_YELLOW_FLAG_TAKEN			= 16;
const int CTF_YELLOW_FLAG_LOST			= 32;
const int CTF_YELLOW_FLAG_CARRYING		= 48;
const int CTF_PINK_FLAG_TAKEN			= 64;
const int CTF_PINK_FLAG_LOST			= 128;
const int CTF_PINK_FLAG_CARRYING		= 192;
const int CTF_NEUTRAL_FLAG_TAKEN		= 256;
const int CTF_NEUTRAL_FLAG_LOST			= 512;
const int CTF_NEUTRAL_FLAG_CARRYING		= 768;
const int CTF_FLAG_NEUTRAL				= 2048;
const int CTF_SHIELDED					= 4096;
#endif

#ifdef IMPLEMENTATION

#ifdef SVQC
#include "../../../common/vehicles/all.qh"
#include "../../teamplay.qh"
#endif

#include "../../../lib/warpzone/common.qh"

bool autocvar_g_ctf_allow_vehicle_carry;
bool autocvar_g_ctf_allow_vehicle_touch;
bool autocvar_g_ctf_allow_monster_touch;
bool autocvar_g_ctf_throw;
float autocvar_g_ctf_throw_angle_max;
float autocvar_g_ctf_throw_angle_min;
int autocvar_g_ctf_throw_punish_count;
float autocvar_g_ctf_throw_punish_delay;
float autocvar_g_ctf_throw_punish_time;
float autocvar_g_ctf_throw_strengthmultiplier;
float autocvar_g_ctf_throw_velocity_forward;
float autocvar_g_ctf_throw_velocity_up;
float autocvar_g_ctf_drop_velocity_up;
float autocvar_g_ctf_drop_velocity_side;
bool autocvar_g_ctf_oneflag_reverse;
bool autocvar_g_ctf_portalteleport;
bool autocvar_g_ctf_pass;
float autocvar_g_ctf_pass_arc;
float autocvar_g_ctf_pass_arc_max;
float autocvar_g_ctf_pass_directional_max;
float autocvar_g_ctf_pass_directional_min;
float autocvar_g_ctf_pass_radius;
float autocvar_g_ctf_pass_wait;
bool autocvar_g_ctf_pass_request;
float autocvar_g_ctf_pass_turnrate;
float autocvar_g_ctf_pass_timelimit;
float autocvar_g_ctf_pass_velocity;
bool autocvar_g_ctf_dynamiclights;
float autocvar_g_ctf_flag_collect_delay;
float autocvar_g_ctf_flag_damageforcescale;
bool autocvar_g_ctf_flag_dropped_waypoint;
bool autocvar_g_ctf_flag_dropped_floatinwater;
bool autocvar_g_ctf_flag_glowtrails;
int autocvar_g_ctf_flag_health;
bool autocvar_g_ctf_flag_return;
bool autocvar_g_ctf_flag_return_carrying;
float autocvar_g_ctf_flag_return_carried_radius;
float autocvar_g_ctf_flag_return_time;
bool autocvar_g_ctf_flag_return_when_unreachable;
float autocvar_g_ctf_flag_return_damage;
float autocvar_g_ctf_flag_return_damage_delay;
float autocvar_g_ctf_flag_return_dropped;
float autocvar_g_ctf_flagcarrier_auto_helpme_damage;
float autocvar_g_ctf_flagcarrier_auto_helpme_time;
float autocvar_g_ctf_flagcarrier_selfdamagefactor;
float autocvar_g_ctf_flagcarrier_selfforcefactor;
float autocvar_g_ctf_flagcarrier_damagefactor;
float autocvar_g_ctf_flagcarrier_forcefactor;
//float autocvar_g_ctf_flagcarrier_waypointforenemy_spotting;
bool autocvar_g_ctf_fullbrightflags;
bool autocvar_g_ctf_ignore_frags;
int autocvar_g_ctf_score_capture;
int autocvar_g_ctf_score_capture_assist;
int autocvar_g_ctf_score_kill;
int autocvar_g_ctf_score_penalty_drop;
int autocvar_g_ctf_score_penalty_returned;
int autocvar_g_ctf_score_pickup_base;
int autocvar_g_ctf_score_pickup_dropped_early;
int autocvar_g_ctf_score_pickup_dropped_late;
int autocvar_g_ctf_score_return;
float autocvar_g_ctf_shield_force;
float autocvar_g_ctf_shield_max_ratio;
int autocvar_g_ctf_shield_min_negscore;
bool autocvar_g_ctf_stalemate;
int autocvar_g_ctf_stalemate_endcondition;
float autocvar_g_ctf_stalemate_time;
bool autocvar_g_ctf_reverse;
float autocvar_g_ctf_dropped_capture_delay;
float autocvar_g_ctf_dropped_capture_radius;

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

void ctf_EventLog(string mode, int flagteam, entity actor) // use an alias for easy changing and quick editing later
{
	if(autocvar_sv_eventlog)
		GameLogEcho(sprintf(":ctf:%s:%d:%d:%s", mode, flagteam, actor.team, ((actor != world) ? ftos(actor.playerid) : "")));
		//GameLogEcho(strcat(":ctf:", mode, ":", ftos(flagteam), ((actor != world) ? (strcat(":", ftos(actor.playerid))) : "")));
}

void ctf_CaptureRecord(entity flag, entity player)
{
	float cap_record = ctf_captimerecord;
	float cap_time = (time - flag.ctf_pickuptime);
	string refername = db_get(ServerProgsDB, strcat(GetMapname(), "/captimerecord/netname"));

	// notify about shit
	if(ctf_oneflag) { Send_Notification(NOTIF_ALL, world, MSG_INFO, INFO_CTF_CAPTURE_NEUTRAL, player.netname); }
	else if(!ctf_captimerecord) { Send_Notification(NOTIF_ALL, world, MSG_CHOICE, APP_TEAM_ENT_4(flag, CHOICE_CTF_CAPTURE_TIME_), player.netname, (cap_time * 100)); }
	else if(cap_time < cap_record) { Send_Notification(NOTIF_ALL, world, MSG_CHOICE, APP_TEAM_ENT_4(flag, CHOICE_CTF_CAPTURE_BROKEN_), player.netname, refername, (cap_time * 100), (cap_record * 100)); }
	else { Send_Notification(NOTIF_ALL, world, MSG_CHOICE, APP_TEAM_ENT_4(flag, CHOICE_CTF_CAPTURE_UNBROKEN_), player.netname, refername, (cap_time * 100), (cap_record * 100)); }

	// write that shit in the database
	if(!ctf_oneflag) // but not in 1-flag mode
	if((!ctf_captimerecord) || (cap_time < cap_record))
	{
		ctf_captimerecord = cap_time;
		db_put(ServerProgsDB, strcat(GetMapname(), "/captimerecord/time"), ftos(cap_time));
		db_put(ServerProgsDB, strcat(GetMapname(), "/captimerecord/netname"), player.netname);
		write_recordmarker(player, (time - cap_time), cap_time);
	}
}

void ctf_FlagcarrierWaypoints(entity player)
{
	WaypointSprite_Spawn(WP_FlagCarrier, 0, 0, player, FLAG_WAYPOINT_OFFSET, world, player.team, player, wps_flagcarrier, true, RADARICON_FLAG);
	WaypointSprite_UpdateMaxHealth(player.wps_flagcarrier, '1 0 0' * healtharmor_maxdamage(start_health, start_armorvalue, autocvar_g_balance_armor_blockpercent, DEATH_WEAPON.m_id) * 2);
	WaypointSprite_UpdateHealth(player.wps_flagcarrier, '1 0 0' * healtharmor_maxdamage(player.health, player.armorvalue, autocvar_g_balance_armor_blockpercent, DEATH_WEAPON.m_id));
	WaypointSprite_UpdateTeamRadar(player.wps_flagcarrier, RADARICON_FLAGCARRIER, WPCOLOR_FLAGCARRIER(player.team));
}

void ctf_CalculatePassVelocity(entity flag, vector to, vector from, float turnrate)
{
	float current_distance = vlen((('1 0 0' * to.x) + ('0 1 0' * to.y)) - (('1 0 0' * from.x) + ('0 1 0' * from.y))); // for the sake of this check, exclude Z axis
	float initial_height = min(autocvar_g_ctf_pass_arc_max, (flag.pass_distance * tanh(autocvar_g_ctf_pass_arc)));
	float current_height = (initial_height * min(1, (current_distance / flag.pass_distance)));
	//print("current_height = ", ftos(current_height), ", initial_height = ", ftos(initial_height), ".\n");

	vector targpos;
	if(current_height) // make sure we can actually do this arcing path
	{
		targpos = (to + ('0 0 1' * current_height));
		WarpZone_TraceLine(flag.origin, targpos, MOVE_NOMONSTERS, flag);
		if(trace_fraction < 1)
		{
			//print("normal arc line failed, trying to find new pos...");
			WarpZone_TraceLine(to, targpos, MOVE_NOMONSTERS, flag);
			targpos = (trace_endpos + FLAG_PASS_ARC_OFFSET);
			WarpZone_TraceLine(flag.origin, targpos, MOVE_NOMONSTERS, flag);
			if(trace_fraction < 1) { targpos = to; /* print(" ^1FAILURE^7, reverting to original direction.\n"); */ }
			/*else { print(" ^3SUCCESS^7, using new arc line.\n"); } */
		}
	}
	else { targpos = to; }

	//flag.angles = normalize(('0 1 0' * to_y) - ('0 1 0' * from_y));

	vector desired_direction = normalize(targpos - from);
	if(turnrate) { flag.velocity = (normalize(normalize(flag.velocity) + (desired_direction * autocvar_g_ctf_pass_turnrate)) * autocvar_g_ctf_pass_velocity); }
	else { flag.velocity = (desired_direction * autocvar_g_ctf_pass_velocity); }
}

bool ctf_CheckPassDirection(vector head_center, vector passer_center, vector passer_angle, vector nearest_to_passer)
{
	if(autocvar_g_ctf_pass_directional_max || autocvar_g_ctf_pass_directional_min)
	{
		// directional tracing only
		float spreadlimit;
		makevectors(passer_angle);

		// find the closest point on the enemy to the center of the attack
		float h; // hypotenuse, which is the distance between attacker to head
		float a; // adjacent side, which is the distance between attacker and the point on w_shotdir that is closest to head.origin

		h = vlen(head_center - passer_center);
		a = h * (normalize(head_center - passer_center) * v_forward);

		vector nearest_on_line = (passer_center + a * v_forward);
		float distance_from_line = vlen(nearest_to_passer - nearest_on_line);

		spreadlimit = (autocvar_g_ctf_pass_radius ? min(1, (vlen(passer_center - nearest_on_line) / autocvar_g_ctf_pass_radius)) : 1);
		spreadlimit = (autocvar_g_ctf_pass_directional_min * (1 - spreadlimit) + autocvar_g_ctf_pass_directional_max * spreadlimit);

		if(spreadlimit && (distance_from_line <= spreadlimit) && ((vlen(normalize(head_center - passer_center) - v_forward) * RAD2DEG) <= 90))
			{ return true; }
		else
			{ return false; }
	}
	else { return true; }
}


// =======================
// CaptureShield Functions
// =======================

bool ctf_CaptureShield_CheckStatus(entity p)
{
	int s, s2, s3, s4, se, se2, se3, se4, sr, ser;
	entity e;
	int players_worseeq, players_total;

	if(ctf_captureshield_max_ratio <= 0)
		return false;

	s = PlayerScore_Add(p, SP_CTF_CAPS, 0);
	s2 = PlayerScore_Add(p, SP_CTF_PICKUPS, 0);
	s3 = PlayerScore_Add(p, SP_CTF_RETURNS, 0);
	s4 = PlayerScore_Add(p, SP_CTF_FCKILLS, 0);

	sr = ((s - s2) + (s3 + s4));

	if(sr >= -ctf_captureshield_min_negscore)
		return false;

	players_total = players_worseeq = 0;
	FOR_EACH_PLAYER(e)
	{
		if(DIFF_TEAM(e, p))
			continue;
		se = PlayerScore_Add(e, SP_CTF_CAPS, 0);
		se2 = PlayerScore_Add(e, SP_CTF_PICKUPS, 0);
		se3 = PlayerScore_Add(e, SP_CTF_RETURNS, 0);
		se4 = PlayerScore_Add(e, SP_CTF_FCKILLS, 0);

		ser = ((se - se2) + (se3 + se4));

		if(ser <= sr)
			++players_worseeq;
		++players_total;
	}

	// player is in the worse half, if >= half the players are better than him, or consequently, if < half of the players are worse
	// use this rule here

	if(players_worseeq >= players_total * ctf_captureshield_max_ratio)
		return false;

	return true;
}

void ctf_CaptureShield_Update(entity player, bool wanted_status)
{
	bool updated_status = ctf_CaptureShield_CheckStatus(player);
	if((wanted_status == player.ctf_captureshielded) && (updated_status != wanted_status)) // 0: shield only, 1: unshield only
	{
		Send_Notification(NOTIF_ONE, player, MSG_CENTER, ((updated_status) ? CENTER_CTF_CAPTURESHIELD_SHIELDED : CENTER_CTF_CAPTURESHIELD_FREE));
		player.ctf_captureshielded = updated_status;
	}
}

bool ctf_CaptureShield_Customize()
{SELFPARAM();
	if(!other.ctf_captureshielded) { return false; }
	if(CTF_SAMETEAM(self, other)) { return false; }

	return true;
}

void ctf_CaptureShield_Touch()
{SELFPARAM();
	if(!other.ctf_captureshielded) { return; }
	if(CTF_SAMETEAM(self, other)) { return; }

	vector mymid = (self.absmin + self.absmax) * 0.5;
	vector othermid = (other.absmin + other.absmax) * 0.5;

	Damage(other, self, self, 0, DEATH_HURTTRIGGER.m_id, mymid, normalize(othermid - mymid) * ctf_captureshield_force);
	if(IS_REAL_CLIENT(other)) { Send_Notification(NOTIF_ONE, other, MSG_CENTER, CENTER_CTF_CAPTURESHIELD_SHIELDED); }
}

void ctf_CaptureShield_Spawn(entity flag)
{SELFPARAM();
	entity shield = new(ctf_captureshield);

	shield.enemy = self;
	shield.team = self.team;
	shield.touch = ctf_CaptureShield_Touch;
	shield.customizeentityforclient = ctf_CaptureShield_Customize;
	shield.effects = EF_ADDITIVE;
	shield.movetype = MOVETYPE_NOCLIP;
	shield.solid = SOLID_TRIGGER;
	shield.avelocity = '7 0 11';
	shield.scale = 0.5;

	setorigin(shield, self.origin);
	setmodel(shield, MDL_CTF_SHIELD);
	setsize(shield, shield.scale * shield.mins, shield.scale * shield.maxs);
}


// ====================
// Drop/Pass/Throw Code
// ====================

void ctf_Handle_Drop(entity flag, entity player, int droptype)
{
	// declarations
	player = (player ? player : flag.pass_sender);

	// main
	flag.movetype = MOVETYPE_TOSS;
	flag.takedamage = DAMAGE_YES;
	flag.angles = '0 0 0';
	flag.health = flag.max_flag_health;
	flag.ctf_droptime = time;
	flag.ctf_dropper = player;
	flag.ctf_status = FLAG_DROPPED;

	// messages and sounds
	Send_Notification(NOTIF_ALL, world, MSG_INFO, ((flag.team) ? APP_TEAM_ENT_4(flag, INFO_CTF_LOST_) : INFO_CTF_LOST_NEUTRAL), player.netname);
	_sound(flag, CH_TRIGGER, flag.snd_flag_dropped, VOL_BASE, ATTEN_NONE);
	ctf_EventLog("dropped", player.team, player);

	// scoring
	PlayerTeamScore_AddScore(player, -autocvar_g_ctf_score_penalty_drop);
	PlayerScore_Add(player, SP_CTF_DROPS, 1);

	// waypoints
	if(autocvar_g_ctf_flag_dropped_waypoint) {
		entity wp = WaypointSprite_Spawn(WP_FlagDropped, 0, 0, flag, FLAG_WAYPOINT_OFFSET, world, ((autocvar_g_ctf_flag_dropped_waypoint == 2) ? 0 : player.team), flag, wps_flagdropped, true, RADARICON_FLAG);
		wp.colormod = WPCOLOR_DROPPEDFLAG(flag.team);
	}

	if(autocvar_g_ctf_flag_return_time || (autocvar_g_ctf_flag_return_damage && autocvar_g_ctf_flag_health))
	{
		WaypointSprite_UpdateMaxHealth(flag.wps_flagdropped, flag.max_flag_health);
		WaypointSprite_UpdateHealth(flag.wps_flagdropped, flag.health);
	}

	player.throw_antispam = time + autocvar_g_ctf_pass_wait;

	if(droptype == DROP_PASS)
	{
		flag.pass_distance = 0;
		flag.pass_sender = world;
		flag.pass_target = world;
	}
}

void ctf_Handle_Retrieve(entity flag, entity player)
{
	entity tmp_player; // temporary entity which the FOR_EACH_PLAYER loop uses to scan players
	entity sender = flag.pass_sender;

	// transfer flag to player
	flag.owner = player;
	flag.owner.flagcarried = flag;

	// reset flag
	if(player.vehicle)
	{
		setattachment(flag, player.vehicle, "");
		setorigin(flag, VEHICLE_FLAG_OFFSET);
		flag.scale = VEHICLE_FLAG_SCALE;
	}
	else
	{
		setattachment(flag, player, "");
		setorigin(flag, FLAG_CARRY_OFFSET);
	}
	flag.movetype = MOVETYPE_NONE;
	flag.takedamage = DAMAGE_NO;
	flag.solid = SOLID_NOT;
	flag.angles = '0 0 0';
	flag.ctf_status = FLAG_CARRY;

	// messages and sounds
	_sound(player, CH_TRIGGER, flag.snd_flag_pass, VOL_BASE, ATTEN_NORM);
	ctf_EventLog("receive", flag.team, player);

	FOR_EACH_REALPLAYER(tmp_player)
	{
		if(tmp_player == sender)
			Send_Notification(NOTIF_ONE, tmp_player, MSG_CENTER, ((flag.team) ? APP_TEAM_ENT_4(flag, CENTER_CTF_PASS_SENT_) : CENTER_CTF_PASS_SENT_NEUTRAL), player.netname);
		else if(tmp_player == player)
			Send_Notification(NOTIF_ONE, tmp_player, MSG_CENTER, ((flag.team) ? APP_TEAM_ENT_4(flag, CENTER_CTF_PASS_RECEIVED_) : CENTER_CTF_PASS_RECEIVED_NEUTRAL), sender.netname);
		else if(SAME_TEAM(tmp_player, sender))
			Send_Notification(NOTIF_ONE, tmp_player, MSG_CENTER, ((flag.team) ? APP_TEAM_ENT_4(flag, CENTER_CTF_PASS_OTHER_) : CENTER_CTF_PASS_OTHER_NEUTRAL), sender.netname, player.netname);
	}

	// create new waypoint
	ctf_FlagcarrierWaypoints(player);

	sender.throw_antispam = time + autocvar_g_ctf_pass_wait;
	player.throw_antispam = sender.throw_antispam;

	flag.pass_distance = 0;
	flag.pass_sender = world;
	flag.pass_target = world;
}

void ctf_Handle_Throw(entity player, entity receiver, int droptype)
{
	entity flag = player.flagcarried;
	vector targ_origin, flag_velocity;

	if(!flag) { return; }
	if((droptype == DROP_PASS) && !receiver) { return; }

	if(flag.speedrunning) { ctf_RespawnFlag(flag); return; }

	// reset the flag
	setattachment(flag, world, "");
	setorigin(flag, player.origin + FLAG_DROP_OFFSET);
	flag.owner.flagcarried = world;
	flag.owner = world;
	flag.solid = SOLID_TRIGGER;
	flag.ctf_dropper = player;
	flag.ctf_droptime = time;

	flag.flags = FL_ITEM | FL_NOTARGET; // clear FL_ONGROUND for MOVETYPE_TOSS

	switch(droptype)
	{
		case DROP_PASS:
		{
			// warpzone support:
			// for the examples, we assume player -> wz1 -> ... -> wzn -> receiver
			// findradius has already put wzn ... wz1 into receiver's warpzone parameters!
			WarpZone_RefSys_Copy(flag, receiver);
			WarpZone_RefSys_AddInverse(flag, receiver); // wz1^-1 ... wzn^-1 receiver
			targ_origin = WarpZone_RefSys_TransformOrigin(receiver, flag, (0.5 * (receiver.absmin + receiver.absmax))); // this is target origin as seen by the flag

			flag.pass_distance = vlen((('1 0 0' * targ_origin.x) + ('0 1 0' * targ_origin.y)) - (('1 0 0' *  player.origin.x) + ('0 1 0' *  player.origin.y))); // for the sake of this check, exclude Z axis
			ctf_CalculatePassVelocity(flag, targ_origin, player.origin, false);

			// main
			flag.movetype = MOVETYPE_FLY;
			flag.takedamage = DAMAGE_NO;
			flag.pass_sender = player;
			flag.pass_target = receiver;
			flag.ctf_status = FLAG_PASSING;

			// other
			_sound(player, CH_TRIGGER, flag.snd_flag_touch, VOL_BASE, ATTEN_NORM);
			WarpZone_TrailParticles(world, _particleeffectnum(flag.passeffect), player.origin, targ_origin);
			ctf_EventLog("pass", flag.team, player);
			break;
		}

		case DROP_THROW:
		{
			makevectors((player.v_angle.y * '0 1 0') + (bound(autocvar_g_ctf_throw_angle_min, player.v_angle.x, autocvar_g_ctf_throw_angle_max) * '1 0 0'));

			flag_velocity = (('0 0 1' * autocvar_g_ctf_throw_velocity_up) + ((v_forward * autocvar_g_ctf_throw_velocity_forward) * ((player.items & ITEM_Strength.m_itemid) ? autocvar_g_ctf_throw_strengthmultiplier : 1)));
			flag.velocity = W_CalculateProjectileVelocity(player.velocity, flag_velocity, false);
			ctf_Handle_Drop(flag, player, droptype);
			break;
		}

		case DROP_RESET:
		{
			flag.velocity = '0 0 0'; // do nothing
			break;
		}

		default:
		case DROP_NORMAL:
		{
			flag.velocity = W_CalculateProjectileVelocity(player.velocity, (('0 0 1' * autocvar_g_ctf_drop_velocity_up) + ((('0 1 0' * crandom()) + ('1 0 0' * crandom())) * autocvar_g_ctf_drop_velocity_side)), false);
			ctf_Handle_Drop(flag, player, droptype);
			break;
		}
	}

	// kill old waypointsprite
	WaypointSprite_Ping(player.wps_flagcarrier);
	WaypointSprite_Kill(player.wps_flagcarrier);

	if(player.wps_enemyflagcarrier)
		WaypointSprite_Kill(player.wps_enemyflagcarrier);

	// captureshield
	ctf_CaptureShield_Update(player, 0); // shield player from picking up flag
}

void shockwave_spawn(string m, vector org, float sz, float t1, float t2)
{
	return modeleffect_spawn(m, 0, 0, org, '0 0 0', '0 0 0', '0 0 0', 0, sz, 1, t1, t2);
}

// ==============
// Event Handlers
// ==============

void ctf_Handle_Capture(entity flag, entity toucher, int capturetype)
{
	entity enemy_flag = ((capturetype == CAPTURE_NORMAL) ? toucher.flagcarried : toucher);
	entity player = ((capturetype == CAPTURE_NORMAL) ? toucher : enemy_flag.ctf_dropper);
	entity player_team_flag = world, tmp_entity;
	float old_time, new_time;

	if(!player) { return; } // without someone to give the reward to, we can't possibly cap
	if(CTF_DIFFTEAM(player, flag)) { return; }

	if(ctf_oneflag)
	for(tmp_entity = ctf_worldflaglist; tmp_entity; tmp_entity = tmp_entity.ctf_worldflagnext)
	if(SAME_TEAM(tmp_entity, player))
	{
		player_team_flag = tmp_entity;
		break;
	}

	nades_GiveBonus(player, autocvar_g_nades_bonus_score_high );

	player.throw_prevtime = time;
	player.throw_count = 0;

	// messages and sounds
	Send_Notification(NOTIF_ONE, player, MSG_CENTER, ((enemy_flag.team) ? APP_TEAM_ENT_4(enemy_flag, CENTER_CTF_CAPTURE_) : CENTER_CTF_CAPTURE_NEUTRAL));
	ctf_CaptureRecord(enemy_flag, player);
	_sound(player, CH_TRIGGER, ((ctf_oneflag) ? player_team_flag.snd_flag_capture : ((DIFF_TEAM(player, flag)) ? enemy_flag.snd_flag_capture : flag.snd_flag_capture)), VOL_BASE, ATTEN_NONE);

	switch(capturetype)
	{
		case CAPTURE_NORMAL: ctf_EventLog("capture", enemy_flag.team, player); break;
		case CAPTURE_DROPPED: ctf_EventLog("droppedcapture", enemy_flag.team, player); break;
		default: break;
	}

	// scoring
	PlayerTeamScore_AddScore(player, autocvar_g_ctf_score_capture);
	PlayerTeamScore_Add(player, SP_CTF_CAPS, ST_CTF_CAPS, 1);

	old_time = PlayerScore_Add(player, SP_CTF_CAPTIME, 0);
	new_time = TIME_ENCODE(time - enemy_flag.ctf_pickuptime);
	if(!old_time || new_time < old_time)
		PlayerScore_Add(player, SP_CTF_CAPTIME, new_time - old_time);

	// effects
	Send_Effect_(flag.capeffect, flag.origin, '0 0 0', 1);
	//shockwave_spawn("models/ctf/shockwavetransring.md3", flag.origin - '0 0 15', -0.8, 0, 1);

	// other
	if(capturetype == CAPTURE_NORMAL)
	{
		WaypointSprite_Kill(player.wps_flagcarrier);
		if(flag.speedrunning) { ctf_FakeTimeLimit(player, -1); }

		if((enemy_flag.ctf_dropper) && (player != enemy_flag.ctf_dropper))
			{ PlayerTeamScore_AddScore(enemy_flag.ctf_dropper, autocvar_g_ctf_score_capture_assist); }
	}

	// reset the flag
	player.next_take_time = time + autocvar_g_ctf_flag_collect_delay;
	ctf_RespawnFlag(enemy_flag);
}

void ctf_Handle_Return(entity flag, entity player)
{
	// messages and sounds
	if(IS_MONSTER(player))
	{
		Send_Notification(NOTIF_ALL, world, MSG_INFO, APP_TEAM_ENT_4(flag, INFO_CTF_RETURN_MONSTER_), player.monster_name);
	}
	else if(flag.team)
	{
		Send_Notification(NOTIF_ONE, player, MSG_CENTER, APP_TEAM_ENT_4(flag, CENTER_CTF_RETURN_));
		Send_Notification(NOTIF_ALL, world, MSG_INFO, APP_TEAM_ENT_4(flag, INFO_CTF_RETURN_), player.netname);
	}
	_sound(player, CH_TRIGGER, flag.snd_flag_returned, VOL_BASE, ATTEN_NONE);
	ctf_EventLog("return", flag.team, player);

	// scoring
	if(IS_PLAYER(player))
	{
		PlayerTeamScore_AddScore(player, autocvar_g_ctf_score_return); // reward for return
		PlayerScore_Add(player, SP_CTF_RETURNS, 1); // add to count of returns

		nades_GiveBonus(player,autocvar_g_nades_bonus_score_medium);
	}

	TeamScore_AddToTeam(flag.team, ST_SCORE, -autocvar_g_ctf_score_penalty_returned); // punish the team who was last carrying it

	if(flag.ctf_dropper)
	{
		PlayerScore_Add(flag.ctf_dropper, SP_SCORE, -autocvar_g_ctf_score_penalty_returned); // punish the player who dropped the flag
		ctf_CaptureShield_Update(flag.ctf_dropper, 0); // shield player from picking up flag
		flag.ctf_dropper.next_take_time = time + autocvar_g_ctf_flag_collect_delay; // set next take time
	}

	// other
	if(player.flagcarried == flag)
		WaypointSprite_Kill(player.wps_flagcarrier);

	// reset the flag
	ctf_RespawnFlag(flag);
}

void ctf_Handle_Pickup(entity flag, entity player, int pickuptype)
{
	// declarations
	float pickup_dropped_score; // used to calculate dropped pickup score
	entity tmp_entity; // temporary entity

	// attach the flag to the player
	flag.owner = player;
	player.flagcarried = flag;
	if(player.vehicle)
	{
		setattachment(flag, player.vehicle, "");
		setorigin(flag, VEHICLE_FLAG_OFFSET);
		flag.scale = VEHICLE_FLAG_SCALE;
	}
	else
	{
		setattachment(flag, player, "");
		setorigin(flag, FLAG_CARRY_OFFSET);
	}

	// flag setup
	flag.movetype = MOVETYPE_NONE;
	flag.takedamage = DAMAGE_NO;
	flag.solid = SOLID_NOT;
	flag.angles = '0 0 0';
	flag.ctf_status = FLAG_CARRY;

	switch(pickuptype)
	{
		case PICKUP_BASE: flag.ctf_pickuptime = time; break; // used for timing runs
		case PICKUP_DROPPED: flag.health = flag.max_flag_health; break; // reset health/return timelimit
		default: break;
	}

	// messages and sounds
	Send_Notification(NOTIF_ALL, world, MSG_INFO, ((flag.team) ? APP_TEAM_ENT_4(flag, INFO_CTF_PICKUP_) : INFO_CTF_PICKUP_NEUTRAL), player.netname);
	if(ctf_stalemate) { Send_Notification(NOTIF_ONE, player, MSG_CENTER, CENTER_CTF_STALEMATE_CARRIER); }
	if(!flag.team) { Send_Notification(NOTIF_ONE, player, MSG_CENTER, CENTER_CTF_PICKUP_NEUTRAL); }
	else if(CTF_DIFFTEAM(player, flag)) { Send_Notification(NOTIF_ONE, player, MSG_CENTER, APP_TEAM_ENT_4(flag, CENTER_CTF_PICKUP_)); }
	else { Send_Notification(NOTIF_ONE, player, MSG_CENTER, ((SAME_TEAM(player, flag)) ? CENTER_CTF_PICKUP_TEAM : CENTER_CTF_PICKUP_TEAM_ENEMY), Team_ColorCode(flag.team)); }

	Send_Notification(NOTIF_TEAM_EXCEPT, player, MSG_CHOICE, ((flag.team) ? APP_TEAM_ENT_4(flag, CHOICE_CTF_PICKUP_TEAM_) : CHOICE_CTF_PICKUP_TEAM_NEUTRAL), Team_ColorCode(player.team), player.netname);

	if(!flag.team)
	FOR_EACH_PLAYER(tmp_entity)
	if(tmp_entity != player)
	if(DIFF_TEAM(player, tmp_entity))
		Send_Notification(NOTIF_ONE, tmp_entity, MSG_CHOICE, CHOICE_CTF_PICKUP_ENEMY_NEUTRAL, Team_ColorCode(player.team), player.netname);

	if(flag.team)
	FOR_EACH_PLAYER(tmp_entity)
	if(tmp_entity != player)
	if(CTF_SAMETEAM(flag, tmp_entity))
	if(SAME_TEAM(player, tmp_entity))
		Send_Notification(NOTIF_ONE, tmp_entity, MSG_CHOICE, APP_TEAM_ENT_4(flag, CHOICE_CTF_PICKUP_TEAM_), Team_ColorCode(player.team), player.netname);
	else
		Send_Notification(NOTIF_ONE, tmp_entity, MSG_CHOICE, ((SAME_TEAM(flag, player)) ? CHOICE_CTF_PICKUP_ENEMY_TEAM : CHOICE_CTF_PICKUP_ENEMY), Team_ColorCode(player.team), player.netname);

	_sound(player, CH_TRIGGER, flag.snd_flag_taken, VOL_BASE, ATTEN_NONE);

	// scoring
	PlayerScore_Add(player, SP_CTF_PICKUPS, 1);
	nades_GiveBonus(player, autocvar_g_nades_bonus_score_minor);
	switch(pickuptype)
	{
		case PICKUP_BASE:
		{
			PlayerTeamScore_AddScore(player, autocvar_g_ctf_score_pickup_base);
			ctf_EventLog("steal", flag.team, player);
			break;
		}

		case PICKUP_DROPPED:
		{
			pickup_dropped_score = (autocvar_g_ctf_flag_return_time ? bound(0, ((flag.ctf_droptime + autocvar_g_ctf_flag_return_time) - time) / autocvar_g_ctf_flag_return_time, 1) : 1);
			pickup_dropped_score = floor((autocvar_g_ctf_score_pickup_dropped_late * (1 - pickup_dropped_score) + autocvar_g_ctf_score_pickup_dropped_early * pickup_dropped_score) + 0.5);
			LOG_TRACE("pickup_dropped_score is ", ftos(pickup_dropped_score), "\n");
			PlayerTeamScore_AddScore(player, pickup_dropped_score);
			ctf_EventLog("pickup", flag.team, player);
			break;
		}

		default: break;
	}

	// speedrunning
	if(pickuptype == PICKUP_BASE)
	{
		flag.speedrunning = player.speedrunning; // if speedrunning, flag will flag-return and teleport the owner back after the record
		if((player.speedrunning) && (ctf_captimerecord))
			ctf_FakeTimeLimit(player, time + ctf_captimerecord);
	}

	// effects
	Send_Effect_(flag.toucheffect, player.origin, '0 0 0', 1);

	// waypoints
	if(pickuptype == PICKUP_DROPPED) { WaypointSprite_Kill(flag.wps_flagdropped); }
	ctf_FlagcarrierWaypoints(player);
	WaypointSprite_Ping(player.wps_flagcarrier);
}


// ===================
// Main Flag Functions
// ===================

void ctf_CheckFlagReturn(entity flag, int returntype)
{
	if((flag.ctf_status == FLAG_DROPPED) || (flag.ctf_status == FLAG_PASSING))
	{
		if(flag.wps_flagdropped) { WaypointSprite_UpdateHealth(flag.wps_flagdropped, flag.health); }

		if((flag.health <= 0) || (time >= flag.ctf_droptime + autocvar_g_ctf_flag_return_time))
		{
			switch(returntype)
			{
				case RETURN_DROPPED: Send_Notification(NOTIF_ALL, world, MSG_INFO, ((flag.team) ? APP_TEAM_ENT_4(flag, INFO_CTF_FLAGRETURN_DROPPED_) : INFO_CTF_FLAGRETURN_DROPPED_NEUTRAL)); break;
				case RETURN_DAMAGE: Send_Notification(NOTIF_ALL, world, MSG_INFO, ((flag.team) ? APP_TEAM_ENT_4(flag, INFO_CTF_FLAGRETURN_DAMAGED_) : INFO_CTF_FLAGRETURN_DAMAGED_NEUTRAL)); break;
				case RETURN_SPEEDRUN: Send_Notification(NOTIF_ALL, world, MSG_INFO, ((flag.team) ? APP_TEAM_ENT_4(flag, INFO_CTF_FLAGRETURN_SPEEDRUN_) : INFO_CTF_FLAGRETURN_SPEEDRUN_NEUTRAL), ctf_captimerecord); break;
				case RETURN_NEEDKILL: Send_Notification(NOTIF_ALL, world, MSG_INFO, ((flag.team) ? APP_TEAM_ENT_4(flag, INFO_CTF_FLAGRETURN_NEEDKILL_) : INFO_CTF_FLAGRETURN_NEEDKILL_NEUTRAL)); break;

				default:
				case RETURN_TIMEOUT:
					{ Send_Notification(NOTIF_ALL, world, MSG_INFO, ((flag.team) ? APP_TEAM_ENT_4(flag, INFO_CTF_FLAGRETURN_TIMEOUT_) : INFO_CTF_FLAGRETURN_TIMEOUT_NEUTRAL)); break; }
			}
			_sound(flag, CH_TRIGGER, flag.snd_flag_respawn, VOL_BASE, ATTEN_NONE);
			ctf_EventLog("returned", flag.team, world);
			ctf_RespawnFlag(flag);
		}
	}
}

bool ctf_Stalemate_Customize()
{SELFPARAM();
	// make spectators see what the player would see
	entity e, wp_owner;
	e = WaypointSprite_getviewentity(other);
	wp_owner = self.owner;

	// team waypoints
	if(CTF_SAMETEAM(wp_owner.flagcarried, wp_owner)) { return false; }
	if(SAME_TEAM(wp_owner, e)) { return false; }
	if(!IS_PLAYER(e)) { return false; }

	return true;
}

void ctf_CheckStalemate()
{
	// declarations
	int stale_flags = 0, stale_red_flags = 0, stale_blue_flags = 0, stale_yellow_flags = 0, stale_pink_flags = 0, stale_neutral_flags = 0;
	entity tmp_entity;

	entity ctf_staleflaglist = world; // reset the list, we need to build the list each time this function runs

	// build list of stale flags
	for(tmp_entity = ctf_worldflaglist; tmp_entity; tmp_entity = tmp_entity.ctf_worldflagnext)
	{
		if(autocvar_g_ctf_stalemate)
		if(tmp_entity.ctf_status != FLAG_BASE)
		if(time >= tmp_entity.ctf_pickuptime + autocvar_g_ctf_stalemate_time || !tmp_entity.team) // instant stalemate in oneflag
		{
			tmp_entity.ctf_staleflagnext = ctf_staleflaglist; // link flag into staleflaglist
			ctf_staleflaglist = tmp_entity;

			switch(tmp_entity.team)
			{
				case NUM_TEAM_1: ++stale_red_flags; break;
				case NUM_TEAM_2: ++stale_blue_flags; break;
				case NUM_TEAM_3: ++stale_yellow_flags; break;
				case NUM_TEAM_4: ++stale_pink_flags; break;
				default: ++stale_neutral_flags; break;
			}
		}
	}

	if(ctf_oneflag)
		stale_flags = (stale_neutral_flags >= 1);
	else
		stale_flags = (stale_red_flags >= 1) + (stale_blue_flags >= 1) + (stale_yellow_flags >= 1) + (stale_pink_flags >= 1);

	if(ctf_oneflag && stale_flags == 1)
		ctf_stalemate = true;
	else if(stale_flags >= 2)
		ctf_stalemate = true;
	else if(stale_flags == 0 && autocvar_g_ctf_stalemate_endcondition == 2)
		{ ctf_stalemate = false; wpforenemy_announced = false; }
	else if(stale_flags < 2 && autocvar_g_ctf_stalemate_endcondition == 1)
		{ ctf_stalemate = false; wpforenemy_announced = false; }

	// if sufficient stalemate, then set up the waypointsprite and announce the stalemate if necessary
	if(ctf_stalemate)
	{
		for(tmp_entity = ctf_staleflaglist; tmp_entity; tmp_entity = tmp_entity.ctf_staleflagnext)
		{
			if((tmp_entity.owner) && (!tmp_entity.owner.wps_enemyflagcarrier))
			{
				entity wp = WaypointSprite_Spawn(((ctf_oneflag) ? WP_FlagCarrier : WP_FlagCarrierEnemy), 0, 0, tmp_entity.owner, FLAG_WAYPOINT_OFFSET, world, 0, tmp_entity.owner, wps_enemyflagcarrier, true, RADARICON_FLAG);
				wp.colormod = WPCOLOR_ENEMYFC(tmp_entity.owner.team);
				tmp_entity.owner.wps_enemyflagcarrier.customizeentityforclient = ctf_Stalemate_Customize;
			}
		}

		if (!wpforenemy_announced)
		{
			FOR_EACH_REALPLAYER(tmp_entity)
				Send_Notification(NOTIF_ONE, tmp_entity, MSG_CENTER, ((tmp_entity.flagcarried) ? CENTER_CTF_STALEMATE_CARRIER : CENTER_CTF_STALEMATE_OTHER));

			wpforenemy_announced = true;
		}
	}
}

void ctf_FlagDamage(entity inflictor, entity attacker, float damage, int deathtype, vector hitloc, vector force)
{SELFPARAM();
	if(ITEM_DAMAGE_NEEDKILL(deathtype))
	{
		if(autocvar_g_ctf_flag_return_damage_delay)
		{
			self.ctf_flagdamaged = true;
		}
		else
		{
			self.health = 0;
			ctf_CheckFlagReturn(self, RETURN_NEEDKILL);
		}
		return;
	}
	if(autocvar_g_ctf_flag_return_damage)
	{
		// reduce health and check if it should be returned
		self.health = self.health - damage;
		ctf_CheckFlagReturn(self, RETURN_DAMAGE);
		return;
	}
}

void ctf_FlagThink()
{SELFPARAM();
	// declarations
	entity tmp_entity;

	self.nextthink = time + FLAG_THINKRATE; // only 5 fps, more is unnecessary.

	// captureshield
	if(self == ctf_worldflaglist) // only for the first flag
		FOR_EACH_CLIENT(tmp_entity)
			ctf_CaptureShield_Update(tmp_entity, 1); // release shield only

	// sanity checks
	if(self.mins != CTF_FLAG.m_mins || self.maxs != CTF_FLAG.m_maxs) { // reset the flag boundaries in case it got squished
		LOG_TRACE("wtf the flag got squashed?\n");
		tracebox(self.origin, CTF_FLAG.m_mins, CTF_FLAG.m_maxs, self.origin, MOVE_NOMONSTERS, self);
		if(!trace_startsolid || self.noalign) // can we resize it without getting stuck?
			setsize(self, CTF_FLAG.m_mins, CTF_FLAG.m_maxs); }

	switch(self.ctf_status) // reset flag angles in case warpzones adjust it
	{
		case FLAG_DROPPED:
		{
			self.angles = '0 0 0';
			break;
		}

		default: break;
	}

	// main think method
	switch(self.ctf_status)
	{
		case FLAG_BASE:
		{
			if(autocvar_g_ctf_dropped_capture_radius)
			{
				for(tmp_entity = ctf_worldflaglist; tmp_entity; tmp_entity = tmp_entity.ctf_worldflagnext)
					if(tmp_entity.ctf_status == FLAG_DROPPED)
					if(vlen(self.origin - tmp_entity.origin) < autocvar_g_ctf_dropped_capture_radius)
					if(time > tmp_entity.ctf_droptime + autocvar_g_ctf_dropped_capture_delay)
						ctf_Handle_Capture(self, tmp_entity, CAPTURE_DROPPED);
			}
			return;
		}

		case FLAG_DROPPED:
		{
			if(autocvar_g_ctf_flag_dropped_floatinwater)
			{
				vector midpoint = ((self.absmin + self.absmax) * 0.5);
				if(pointcontents(midpoint) == CONTENT_WATER)
				{
					self.velocity = self.velocity * 0.5;

					if(pointcontents(midpoint + FLAG_FLOAT_OFFSET) == CONTENT_WATER)
						{ self.velocity_z = autocvar_g_ctf_flag_dropped_floatinwater; }
					else
						{ self.movetype = MOVETYPE_FLY; }
				}
				else if(self.movetype == MOVETYPE_FLY) { self.movetype = MOVETYPE_TOSS; }
			}
			if(autocvar_g_ctf_flag_return_dropped)
			{
				if((vlen(self.origin - self.ctf_spawnorigin) <= autocvar_g_ctf_flag_return_dropped) || (autocvar_g_ctf_flag_return_dropped == -1))
				{
					self.health = 0;
					ctf_CheckFlagReturn(self, RETURN_DROPPED);
					return;
				}
			}
			if(self.ctf_flagdamaged)
			{
				self.health -= ((self.max_flag_health / autocvar_g_ctf_flag_return_damage_delay) * FLAG_THINKRATE);
				ctf_CheckFlagReturn(self, RETURN_NEEDKILL);
				return;
			}
			else if(autocvar_g_ctf_flag_return_time)
			{
				self.health -= ((self.max_flag_health / autocvar_g_ctf_flag_return_time) * FLAG_THINKRATE);
				ctf_CheckFlagReturn(self, RETURN_TIMEOUT);
				return;
			}
			return;
		}

		case FLAG_CARRY:
		{
			if(self.speedrunning && ctf_captimerecord && (time >= self.ctf_pickuptime + ctf_captimerecord))
			{
				self.health = 0;
				ctf_CheckFlagReturn(self, RETURN_SPEEDRUN);

				setself(self.owner);
				self.impulse = CHIMPULSE_SPEEDRUN.impulse; // move the player back to the waypoint they set
				ImpulseCommands(self);
				setself(this);
			}
			if(autocvar_g_ctf_stalemate)
			{
				if(time >= wpforenemy_nextthink)
				{
					ctf_CheckStalemate();
					wpforenemy_nextthink = time + WPFE_THINKRATE; // waypoint for enemy think rate (to reduce unnecessary spam of this check)
				}
			}
			if(CTF_SAMETEAM(self, self.owner) && self.team)
			{
				if(autocvar_g_ctf_flag_return) // drop the flag if reverse status has changed
					ctf_Handle_Throw(self.owner, world, DROP_THROW);
				else if(vlen(self.owner.origin - self.ctf_spawnorigin) <= autocvar_g_ctf_flag_return_carried_radius)
					ctf_Handle_Return(self, self.owner);
			}
			return;
		}

		case FLAG_PASSING:
		{
			vector targ_origin = ((self.pass_target.absmin + self.pass_target.absmax) * 0.5);
			targ_origin = WarpZone_RefSys_TransformOrigin(self.pass_target, self, targ_origin); // origin of target as seen by the flag (us)
			WarpZone_TraceLine(self.origin, targ_origin, MOVE_NOMONSTERS, self);

			if((self.pass_target == world)
				|| (self.pass_target.deadflag != DEAD_NO)
				|| (self.pass_target.flagcarried)
				|| (vlen(self.origin - targ_origin) > autocvar_g_ctf_pass_radius)
				|| ((trace_fraction < 1) && (trace_ent != self.pass_target))
				|| (time > self.ctf_droptime + autocvar_g_ctf_pass_timelimit))
			{
				// give up, pass failed
				ctf_Handle_Drop(self, world, DROP_PASS);
			}
			else
			{
				// still a viable target, go for it
				ctf_CalculatePassVelocity(self, targ_origin, self.origin, true);
			}
			return;
		}

		default: // this should never happen
		{
			LOG_TRACE("ctf_FlagThink(): Flag exists with no status?\n");
			return;
		}
	}
}

METHOD(Flag, giveTo, bool(Flag this, entity flag, entity toucher))
{
	return = false;
	if(gameover) { return; }
	if(trace_dphitcontents & (DPCONTENTS_PLAYERCLIP | DPCONTENTS_MONSTERCLIP)) { return; }

	bool is_not_monster = (!IS_MONSTER(toucher));

	// automatically kill the flag and return it if it touched lava/slime/nodrop surfaces
	if(ITEM_TOUCH_NEEDKILL())
	{
		if(!autocvar_g_ctf_flag_return_damage_delay)
		{
			flag.health = 0;
			ctf_CheckFlagReturn(flag, RETURN_NEEDKILL);
		}
		if(!flag.ctf_flagdamaged) { return; }
	}

	int num_perteam = 0;
	entity tmp_entity; FOR_EACH_PLAYER(tmp_entity) if(SAME_TEAM(toucher, tmp_entity)) { ++num_perteam; }

	// special touch behaviors
	if(toucher.frozen) { return; }
	else if(IS_VEHICLE(toucher))
	{
		if(autocvar_g_ctf_allow_vehicle_touch && toucher.owner)
			toucher = toucher.owner; // the player is actually the vehicle owner, not other
		else
			return; // do nothing
	}
	else if(IS_MONSTER(toucher))
	{
		if(!autocvar_g_ctf_allow_monster_touch)
			return; // do nothing
	}
	else if (!IS_PLAYER(toucher)) // The flag just touched an object, most likely the world
	{
		if(time > flag.wait) // if we haven't in a while, play a sound/effect
		{
			Send_Effect_(flag.toucheffect, flag.origin, '0 0 0', 1);
			_sound(flag, CH_TRIGGER, flag.snd_flag_touch, VOL_BASE, ATTEN_NORM);
			flag.wait = time + FLAG_TOUCHRATE;
		}
		return;
	}
	else if(toucher.deadflag != DEAD_NO) { return; }

	switch(flag.ctf_status)
	{
		case FLAG_BASE:
		{
			if(ctf_oneflag)
			{
				if(CTF_SAMETEAM(toucher, flag) && (toucher.flagcarried) && !toucher.flagcarried.team && is_not_monster)
					ctf_Handle_Capture(flag, toucher, CAPTURE_NORMAL); // toucher just captured the neutral flag to enemy base
				else if(!flag.team && (!toucher.flagcarried) && (!toucher.ctf_captureshielded) && (time > toucher.next_take_time) && is_not_monster)
					ctf_Handle_Pickup(flag, toucher, PICKUP_BASE); // toucher just stole the neutral flag
			}
			else if(CTF_SAMETEAM(toucher, flag) && (toucher.flagcarried) && DIFF_TEAM(toucher.flagcarried, flag) && is_not_monster)
				ctf_Handle_Capture(flag, toucher, CAPTURE_NORMAL); // toucher just captured the enemies flag to his base
			else if(CTF_DIFFTEAM(toucher, flag) && (toucher.flagcarried) && CTF_SAMETEAM(toucher.flagcarried, toucher) && (!toucher.ctf_captureshielded) && autocvar_g_ctf_flag_return_carrying && (time > toucher.next_take_time) && is_not_monster)
			{
				ctf_Handle_Return(toucher.flagcarried, toucher); // return their current flag
				ctf_Handle_Pickup(flag, toucher, PICKUP_BASE); // now pickup the flag
			}
			else if(CTF_DIFFTEAM(toucher, flag) && (!toucher.flagcarried) && (!toucher.ctf_captureshielded) && (time > toucher.next_take_time) && is_not_monster)
				ctf_Handle_Pickup(flag, toucher, PICKUP_BASE); // toucher just stole the enemies flag
			break;
		}

		case FLAG_DROPPED:
		{
			if(CTF_SAMETEAM(toucher, flag) && (autocvar_g_ctf_flag_return || num_perteam <= 1 || (autocvar_g_ctf_flag_return_carrying && toucher.flagcarried)) && flag.team) // automatically return if there's only 1 player on the team
				ctf_Handle_Return(flag, toucher); // toucher just returned his own flag
			else if(is_not_monster && (!toucher.flagcarried) && ((toucher != flag.ctf_dropper) || (time > flag.ctf_droptime + autocvar_g_ctf_flag_collect_delay)))
				ctf_Handle_Pickup(flag, toucher, PICKUP_DROPPED); // toucher just picked up a dropped enemy flag
			break;
		}

		case FLAG_CARRY:
		{
			LOG_TRACE("Someone touched a flag even though it was being carried?\n");
			break;
		}

		case FLAG_PASSING:
		{
			if((IS_PLAYER(toucher)) && (toucher.deadflag == DEAD_NO) && (toucher != flag.pass_sender))
			{
				if(DIFF_TEAM(toucher, flag.pass_sender))
					ctf_Handle_Return(flag, toucher);
				else
					ctf_Handle_Retrieve(flag, toucher);
			}
			break;
		}
	}
}

.float last_respawn;
void ctf_RespawnFlag(entity flag)
{
	// check for flag respawn being called twice in a row
	if(flag.last_respawn > time - 0.5)
		{ backtrace("flag respawn called twice quickly! please notify Samual about this..."); }

	flag.last_respawn = time;

	// reset the player (if there is one)
	if((flag.owner) && (flag.owner.flagcarried == flag))
	{
		WaypointSprite_Kill(flag.owner.wps_enemyflagcarrier);
		WaypointSprite_Kill(flag.wps_flagcarrier);

		flag.owner.flagcarried = world;

		if(flag.speedrunning)
			ctf_FakeTimeLimit(flag.owner, -1);
	}

	if((flag.owner) && (flag.owner.vehicle))
		flag.scale = FLAG_SCALE;

	if(flag.ctf_status == FLAG_DROPPED)
		{ WaypointSprite_Kill(flag.wps_flagdropped); }

	// reset the flag
	setattachment(flag, world, "");
	setorigin(flag, flag.ctf_spawnorigin);

	flag.movetype = ((flag.noalign) ? MOVETYPE_NONE : MOVETYPE_TOSS);
	flag.takedamage = DAMAGE_NO;
	flag.health = flag.max_flag_health;
	flag.solid = SOLID_TRIGGER;
	flag.velocity = '0 0 0';
	flag.angles = flag.mangle;
	flag.flags = FL_ITEM | FL_NOTARGET;

	flag.ctf_status = FLAG_BASE;
	flag.owner = world;
	flag.pass_distance = 0;
	flag.pass_sender = world;
	flag.pass_target = world;
	flag.ctf_dropper = world;
	flag.ctf_pickuptime = 0;
	flag.ctf_droptime = 0;
	flag.ctf_flagdamaged = 0;

	ctf_CheckStalemate();
}

void ctf_Reset(entity this)
{
	if(this.owner && IS_PLAYER(this.owner))
        ctf_Handle_Throw(this.owner, world, DROP_RESET);

	ctf_RespawnFlag(this);
}

void ctf_DelayedFlagSetup() // called after a flag is placed on a map by ctf_FlagSetup()
{SELFPARAM();
	// bot waypoints
	waypoint_spawnforitem_force(self, self.origin);
	self.nearestwaypointtimeout = 0; // activate waypointing again
	self.bot_basewaypoint = self.nearestwaypoint;

	// waypointsprites
	entity basename;
	switch (self.team)
	{
		case NUM_TEAM_1: basename = WP_FlagBaseRed; break;
		case NUM_TEAM_2: basename = WP_FlagBaseBlue; break;
		case NUM_TEAM_3: basename = WP_FlagBaseYellow; break;
		case NUM_TEAM_4: basename = WP_FlagBasePink; break;
		default: basename = WP_FlagBaseNeutral; break;
	}

	entity wp = WaypointSprite_SpawnFixed(basename, self.origin + FLAG_WAYPOINT_OFFSET, self, wps_flagbase, RADARICON_FLAG);
	wp.colormod = ((self.team) ? Team_ColorRGB(self.team) : '1 1 1');
	WaypointSprite_UpdateTeamRadar(self.wps_flagbase, RADARICON_FLAG, ((self.team) ? colormapPaletteColor(self.team - 1, false) : '1 1 1'));

	// captureshield setup
	ctf_CaptureShield_Spawn(self);
}

void ctf_FlagSetup(int teamnumber, entity flag) // called when spawning a flag entity on the map as a spawnfunc
{SELFPARAM();
	// declarations
	setself(flag); // for later usage with droptofloor()

	// main setup
	flag.ctf_worldflagnext = ctf_worldflaglist; // link flag into ctf_worldflaglist
	ctf_worldflaglist = flag;

	setattachment(flag, world, "");

	flag.netname = strzone(sprintf("%s%s^7 flag", Team_ColorCode(teamnumber), Team_ColorName_Upper(teamnumber)));
	flag.team = teamnumber;
	flag.classname = "item_flag_team";
	flag.target = "###item###"; // wut?
	flag.flags = FL_ITEM | FL_NOTARGET;
	flag.solid = SOLID_TRIGGER;
	flag.takedamage = DAMAGE_NO;
	flag.damageforcescale = autocvar_g_ctf_flag_damageforcescale;
	flag.max_flag_health = ((autocvar_g_ctf_flag_return_damage && autocvar_g_ctf_flag_health) ? autocvar_g_ctf_flag_health : 100);
	flag.health = flag.max_flag_health;
	flag.event_damage = ctf_FlagDamage;
	flag.pushable = true;
	flag.teleportable = TELEPORT_NORMAL;
	flag.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_PLAYERCLIP | DPCONTENTS_BOTCLIP;
	flag.damagedbytriggers = autocvar_g_ctf_flag_return_when_unreachable;
	flag.damagedbycontents = autocvar_g_ctf_flag_return_when_unreachable;
	flag.velocity = '0 0 0';
	flag.mangle = flag.angles;
	flag.reset = ctf_Reset;
	flag.touch = ctf_FlagTouch;
	flag.think = ctf_FlagThink;
	flag.nextthink = time + FLAG_THINKRATE;
	flag.ctf_status = FLAG_BASE;

	string teamname = Static_Team_ColorName_Lower(teamnumber);
	// appearence
	if(!flag.scale)				{ flag.scale = FLAG_SCALE; }
	if(flag.skin == 0)			{ flag.skin = cvar(sprintf("g_ctf_flag_%s_skin", teamname)); }
	if(flag.model == "")		{ flag.model = cvar_string(sprintf("g_ctf_flag_%s_model", teamname)); }
	if (flag.toucheffect == "") { flag.toucheffect = EFFECT_FLAG_TOUCH(teamnumber).eent_eff_name; }
	if (flag.passeffect == "") 	{ flag.passeffect = EFFECT_PASS(teamnumber).eent_eff_name; }
	if (flag.capeffect == "") 	{ flag.capeffect = EFFECT_CAP(teamnumber).eent_eff_name; }

	// sounds
	flag.snd_flag_taken = strzone(SND(CTF_TAKEN(teamnumber)));
	flag.snd_flag_returned = strzone(SND(CTF_RETURNED(teamnumber)));
	flag.snd_flag_capture = strzone(SND(CTF_CAPTURE(teamnumber)));
	flag.snd_flag_dropped = strzone(SND(CTF_DROPPED(teamnumber)));
	if (flag.snd_flag_respawn == "") flag.snd_flag_respawn = strzone(SND(CTF_RESPAWN)); // if there is ever a team-based sound for this, update the code to match.
	precache_sound(flag.snd_flag_respawn);
	if (flag.snd_flag_touch == "") flag.snd_flag_touch = strzone(SND(CTF_TOUCH)); // again has no team-based sound
	precache_sound(flag.snd_flag_touch);
	if (flag.snd_flag_pass == "") flag.snd_flag_pass = strzone(SND(CTF_PASS)); // same story here
	precache_sound(flag.snd_flag_pass);

	// precache
	precache_model(flag.model);

	// appearence
	_setmodel(flag, flag.model); // precision set below
	setsize(flag, CTF_FLAG.m_mins, CTF_FLAG.m_maxs);
	setorigin(flag, (flag.origin + FLAG_SPAWN_OFFSET));

	if(autocvar_g_ctf_flag_glowtrails)
	{
		switch(teamnumber)
		{
			case NUM_TEAM_1: flag.glow_color = 251; break;
			case NUM_TEAM_2: flag.glow_color = 210; break;
			case NUM_TEAM_3: flag.glow_color = 110; break;
			case NUM_TEAM_4: flag.glow_color = 145; break;
			default:		 flag.glow_color = 254; break;
		}
		flag.glow_size = 25;
		flag.glow_trail = 1;
	}

	flag.effects |= EF_LOWPRECISION;
	if(autocvar_g_ctf_fullbrightflags) { flag.effects |= EF_FULLBRIGHT; }
	if(autocvar_g_ctf_dynamiclights)
	{
		switch(teamnumber)
		{
			case NUM_TEAM_1: flag.effects |= EF_RED; break;
			case NUM_TEAM_2: flag.effects |= EF_BLUE; break;
			case NUM_TEAM_3: flag.effects |= EF_DIMLIGHT; break;
			case NUM_TEAM_4: flag.effects |= EF_RED; break;
			default:		 flag.effects |= EF_DIMLIGHT; break;
		}
	}

	// flag placement
	if((flag.spawnflags & 1) || flag.noalign) // don't drop to floor, just stay at fixed location
	{
		flag.dropped_origin = flag.origin;
		flag.noalign = true;
		flag.movetype = MOVETYPE_NONE;
	}
	else // drop to floor, automatically find a platform and set that as spawn origin
	{
		flag.noalign = false;
		setself(flag);
		droptofloor();
		flag.movetype = MOVETYPE_TOSS;
	}

	InitializeEntity(flag, ctf_DelayedFlagSetup, INITPRIO_SETLOCATION);
}


// ================
// Bot player logic
// ================

// NOTE: LEGACY CODE, needs to be re-written!

void havocbot_calculate_middlepoint()
{
	entity f;
	vector s = '0 0 0';
	vector fo = '0 0 0';
	float n = 0;

	f = ctf_worldflaglist;
	while (f)
	{
		fo = f.origin;
		s = s + fo;
		f = f.ctf_worldflagnext;
	}
	if(!n)
		return;
	havocbot_ctf_middlepoint = s * (1.0 / n);
	havocbot_ctf_middlepoint_radius	 = vlen(fo - havocbot_ctf_middlepoint);
}


entity havocbot_ctf_find_flag(entity bot)
{
	entity f;
	f = ctf_worldflaglist;
	while (f)
	{
		if (CTF_SAMETEAM(bot, f))
			return f;
		f = f.ctf_worldflagnext;
	}
	return world;
}

entity havocbot_ctf_find_enemy_flag(entity bot)
{
	entity f;
	f = ctf_worldflaglist;
	while (f)
	{
		if(ctf_oneflag)
		{
			if(CTF_DIFFTEAM(bot, f))
			{
				if(f.team)
				{
					if(bot.flagcarried)
						return f;
				}
				else if(!bot.flagcarried)
					return f;
			}
		}
		else if (CTF_DIFFTEAM(bot, f))
			return f;
		f = f.ctf_worldflagnext;
	}
	return world;
}

int havocbot_ctf_teamcount(entity bot, vector org, float tc_radius)
{
	if (!teamplay)
		return 0;

	int c = 0;
	entity head;

	FOR_EACH_PLAYER(head)
	{
		if(DIFF_TEAM(head, bot) || head.deadflag != DEAD_NO || head == bot)
			continue;

		if(vlen(head.origin - org) < tc_radius)
			++c;
	}

	return c;
}

void havocbot_goalrating_ctf_ourflag(float ratingscale)
{SELFPARAM();
	entity head;
	head = ctf_worldflaglist;
	while (head)
	{
		if (CTF_SAMETEAM(self, head))
			break;
		head = head.ctf_worldflagnext;
	}
	if (head)
		navigation_routerating(head, ratingscale, 10000);
}

void havocbot_goalrating_ctf_ourbase(float ratingscale)
{SELFPARAM();
	entity head;
	head = ctf_worldflaglist;
	while (head)
	{
		if (CTF_SAMETEAM(self, head))
			break;
		head = head.ctf_worldflagnext;
	}
	if (!head)
		return;

	navigation_routerating(head.bot_basewaypoint, ratingscale, 10000);
}

void havocbot_goalrating_ctf_enemyflag(float ratingscale)
{SELFPARAM();
	entity head;
	head = ctf_worldflaglist;
	while (head)
	{
		if(ctf_oneflag)
		{
			if(CTF_DIFFTEAM(self, head))
			{
				if(head.team)
				{
					if(self.flagcarried)
						break;
				}
				else if(!self.flagcarried)
					break;
			}
		}
		else if(CTF_DIFFTEAM(self, head))
			break;
		head = head.ctf_worldflagnext;
	}
	if (head)
		navigation_routerating(head, ratingscale, 10000);
}

void havocbot_goalrating_ctf_enemybase(float ratingscale)
{SELFPARAM();
	if (!bot_waypoints_for_items)
	{
		havocbot_goalrating_ctf_enemyflag(ratingscale);
		return;
	}

	entity head;

	head = havocbot_ctf_find_enemy_flag(self);

	if (!head)
		return;

	navigation_routerating(head.bot_basewaypoint, ratingscale, 10000);
}

void havocbot_goalrating_ctf_ourstolenflag(float ratingscale)
{SELFPARAM();
	entity mf;

	mf = havocbot_ctf_find_flag(self);

	if(mf.ctf_status == FLAG_BASE)
		return;

	if(mf.tag_entity)
		navigation_routerating(mf.tag_entity, ratingscale, 10000);
}

void havocbot_goalrating_ctf_droppedflags(float ratingscale, vector org, float df_radius)
{
	entity head;
	head = ctf_worldflaglist;
	while (head)
	{
		// flag is out in the field
		if(head.ctf_status != FLAG_BASE)
		if(head.tag_entity==world)	// dropped
		{
			if(df_radius)
			{
				if(vlen(org-head.origin)<df_radius)
					navigation_routerating(head, ratingscale, 10000);
			}
			else
				navigation_routerating(head, ratingscale, 10000);
		}

		head = head.ctf_worldflagnext;
	}
}

void havocbot_goalrating_ctf_carrieritems(float ratingscale, vector org, float sradius)
{SELFPARAM();
	entity head;
	float t;
	head = findchainfloat(bot_pickup, true);
	while (head)
	{
		// gather health and armor only
		if (head.solid)
		if (head.health || head.armorvalue)
		if (vlen(head.origin - org) < sradius)
		{
			// get the value of the item
			t = head.bot_pickupevalfunc(self, head) * 0.0001;
			if (t > 0)
				navigation_routerating(head, t * ratingscale, 500);
		}
		head = head.chain;
	}
}

void havocbot_ctf_reset_role(entity bot)
{
	float cdefense, cmiddle, coffense;
	entity mf, ef, head;
	float c;

	if(bot.deadflag != DEAD_NO)
		return;

	if(vlen(havocbot_ctf_middlepoint)==0)
		havocbot_calculate_middlepoint();

	// Check ctf flags
	if (bot.flagcarried)
	{
		havocbot_role_ctf_setrole(bot, HAVOCBOT_CTF_ROLE_CARRIER);
		return;
	}

	mf = havocbot_ctf_find_flag(bot);
	ef = havocbot_ctf_find_enemy_flag(bot);

	// Retrieve stolen flag
	if(mf.ctf_status!=FLAG_BASE)
	{
		havocbot_role_ctf_setrole(bot, HAVOCBOT_CTF_ROLE_RETRIEVER);
		return;
	}

	// If enemy flag is taken go to the middle to intercept pursuers
	if(ef.ctf_status!=FLAG_BASE)
	{
		havocbot_role_ctf_setrole(bot, HAVOCBOT_CTF_ROLE_MIDDLE);
		return;
	}

	// if there is only me on the team switch to offense
	c = 0;
	FOR_EACH_PLAYER(head)
	if(SAME_TEAM(head, bot))
		++c;

	if(c==1)
	{
		havocbot_role_ctf_setrole(bot, HAVOCBOT_CTF_ROLE_OFFENSE);
		return;
	}

	// Evaluate best position to take
	// Count mates on middle position
	cmiddle = havocbot_ctf_teamcount(bot, havocbot_ctf_middlepoint, havocbot_ctf_middlepoint_radius * 0.5);

	// Count mates on defense position
	cdefense = havocbot_ctf_teamcount(bot, mf.dropped_origin, havocbot_ctf_middlepoint_radius * 0.5);

	// Count mates on offense position
	coffense = havocbot_ctf_teamcount(bot, ef.dropped_origin, havocbot_ctf_middlepoint_radius);

	if(cdefense<=coffense)
		havocbot_role_ctf_setrole(bot, HAVOCBOT_CTF_ROLE_DEFENSE);
	else if(coffense<=cmiddle)
		havocbot_role_ctf_setrole(bot, HAVOCBOT_CTF_ROLE_OFFENSE);
	else
		havocbot_role_ctf_setrole(bot, HAVOCBOT_CTF_ROLE_MIDDLE);
}

void havocbot_role_ctf_carrier()
{SELFPARAM();
	if(self.deadflag != DEAD_NO)
	{
		havocbot_ctf_reset_role(self);
		return;
	}

	if (self.flagcarried == world)
	{
		havocbot_ctf_reset_role(self);
		return;
	}

	if (self.bot_strategytime < time)
	{
		self.bot_strategytime = time + autocvar_bot_ai_strategyinterval;

		navigation_goalrating_start();
		if(ctf_oneflag)
			havocbot_goalrating_ctf_enemybase(50000);
		else
			havocbot_goalrating_ctf_ourbase(50000);

		if(self.health<100)
			havocbot_goalrating_ctf_carrieritems(1000, self.origin, 1000);

		navigation_goalrating_end();

		if (self.navigation_hasgoals)
			self.havocbot_cantfindflag = time + 10;
		else if (time > self.havocbot_cantfindflag)
		{
			// Can't navigate to my own base, suicide!
			// TODO: drop it and wander around
			Damage(self, self, self, 100000, DEATH_KILL.m_id, self.origin, '0 0 0');
			return;
		}
	}
}

void havocbot_role_ctf_escort()
{SELFPARAM();
	entity mf, ef;

	if(self.deadflag != DEAD_NO)
	{
		havocbot_ctf_reset_role(self);
		return;
	}

	if (self.flagcarried)
	{
		havocbot_role_ctf_setrole(self, HAVOCBOT_CTF_ROLE_CARRIER);
		return;
	}

	// If enemy flag is back on the base switch to previous role
	ef = havocbot_ctf_find_enemy_flag(self);
	if(ef.ctf_status==FLAG_BASE)
	{
		self.havocbot_role = self.havocbot_previous_role;
		self.havocbot_role_timeout = 0;
		return;
	}

	// If the flag carrier reached the base switch to defense
	mf = havocbot_ctf_find_flag(self);
	if(mf.ctf_status!=FLAG_BASE)
	if(vlen(ef.origin - mf.dropped_origin) < 300)
	{
		havocbot_role_ctf_setrole(self, HAVOCBOT_CTF_ROLE_DEFENSE);
		return;
	}

	// Set the role timeout if necessary
	if (!self.havocbot_role_timeout)
	{
		self.havocbot_role_timeout = time + random() * 30 + 60;
	}

	// If nothing happened just switch to previous role
	if (time > self.havocbot_role_timeout)
	{
		self.havocbot_role = self.havocbot_previous_role;
		self.havocbot_role_timeout = 0;
		return;
	}

	// Chase the flag carrier
	if (self.bot_strategytime < time)
	{
		self.bot_strategytime = time + autocvar_bot_ai_strategyinterval;
		navigation_goalrating_start();
		havocbot_goalrating_ctf_enemyflag(30000);
		havocbot_goalrating_ctf_ourstolenflag(40000);
		havocbot_goalrating_items(10000, self.origin, 10000);
		navigation_goalrating_end();
	}
}

void havocbot_role_ctf_offense()
{SELFPARAM();
	entity mf, ef;
	vector pos;

	if(self.deadflag != DEAD_NO)
	{
		havocbot_ctf_reset_role(self);
		return;
	}

	if (self.flagcarried)
	{
		havocbot_role_ctf_setrole(self, HAVOCBOT_CTF_ROLE_CARRIER);
		return;
	}

	// Check flags
	mf = havocbot_ctf_find_flag(self);
	ef = havocbot_ctf_find_enemy_flag(self);

	// Own flag stolen
	if(mf.ctf_status!=FLAG_BASE)
	{
		if(mf.tag_entity)
			pos = mf.tag_entity.origin;
		else
			pos = mf.origin;

		// Try to get it if closer than the enemy base
		if(vlen(self.origin-ef.dropped_origin)>vlen(self.origin-pos))
		{
			havocbot_role_ctf_setrole(self, HAVOCBOT_CTF_ROLE_RETRIEVER);
			return;
		}
	}

	// Escort flag carrier
	if(ef.ctf_status!=FLAG_BASE)
	{
		if(ef.tag_entity)
			pos = ef.tag_entity.origin;
		else
			pos = ef.origin;

		if(vlen(pos-mf.dropped_origin)>700)
		{
			havocbot_role_ctf_setrole(self, HAVOCBOT_CTF_ROLE_ESCORT);
			return;
		}
	}

	// About to fail, switch to middlefield
	if(self.health<50)
	{
		havocbot_role_ctf_setrole(self, HAVOCBOT_CTF_ROLE_MIDDLE);
		return;
	}

	// Set the role timeout if necessary
	if (!self.havocbot_role_timeout)
		self.havocbot_role_timeout = time + 120;

	if (time > self.havocbot_role_timeout)
	{
		havocbot_ctf_reset_role(self);
		return;
	}

	if (self.bot_strategytime < time)
	{
		self.bot_strategytime = time + autocvar_bot_ai_strategyinterval;
		navigation_goalrating_start();
		havocbot_goalrating_ctf_ourstolenflag(50000);
		havocbot_goalrating_ctf_enemybase(20000);
		havocbot_goalrating_items(5000, self.origin, 1000);
		havocbot_goalrating_items(1000, self.origin, 10000);
		navigation_goalrating_end();
	}
}

// Retriever (temporary role):
void havocbot_role_ctf_retriever()
{SELFPARAM();
	entity mf;

	if(self.deadflag != DEAD_NO)
	{
		havocbot_ctf_reset_role(self);
		return;
	}

	if (self.flagcarried)
	{
		havocbot_role_ctf_setrole(self, HAVOCBOT_CTF_ROLE_CARRIER);
		return;
	}

	// If flag is back on the base switch to previous role
	mf = havocbot_ctf_find_flag(self);
	if(mf.ctf_status==FLAG_BASE)
	{
		havocbot_ctf_reset_role(self);
		return;
	}

	if (!self.havocbot_role_timeout)
		self.havocbot_role_timeout = time + 20;

	if (time > self.havocbot_role_timeout)
	{
		havocbot_ctf_reset_role(self);
		return;
	}

	if (self.bot_strategytime < time)
	{
		float rt_radius;
		rt_radius = 10000;

		self.bot_strategytime = time + autocvar_bot_ai_strategyinterval;
		navigation_goalrating_start();
		havocbot_goalrating_ctf_ourstolenflag(50000);
		havocbot_goalrating_ctf_droppedflags(40000, self.origin, rt_radius);
		havocbot_goalrating_ctf_enemybase(30000);
		havocbot_goalrating_items(500, self.origin, rt_radius);
		navigation_goalrating_end();
	}
}

void havocbot_role_ctf_middle()
{SELFPARAM();
	entity mf;

	if(self.deadflag != DEAD_NO)
	{
		havocbot_ctf_reset_role(self);
		return;
	}

	if (self.flagcarried)
	{
		havocbot_role_ctf_setrole(self, HAVOCBOT_CTF_ROLE_CARRIER);
		return;
	}

	mf = havocbot_ctf_find_flag(self);
	if(mf.ctf_status!=FLAG_BASE)
	{
		havocbot_role_ctf_setrole(self, HAVOCBOT_CTF_ROLE_RETRIEVER);
		return;
	}

	if (!self.havocbot_role_timeout)
		self.havocbot_role_timeout = time + 10;

	if (time > self.havocbot_role_timeout)
	{
		havocbot_ctf_reset_role(self);
		return;
	}

	if (self.bot_strategytime < time)
	{
		vector org;

		org = havocbot_ctf_middlepoint;
		org.z = self.origin.z;

		self.bot_strategytime = time + autocvar_bot_ai_strategyinterval;
		navigation_goalrating_start();
		havocbot_goalrating_ctf_ourstolenflag(50000);
		havocbot_goalrating_ctf_droppedflags(30000, self.origin, 10000);
		havocbot_goalrating_enemyplayers(10000, org, havocbot_ctf_middlepoint_radius * 0.5);
		havocbot_goalrating_items(5000, org, havocbot_ctf_middlepoint_radius * 0.5);
		havocbot_goalrating_items(2500, self.origin, 10000);
		havocbot_goalrating_ctf_enemybase(2500);
		navigation_goalrating_end();
	}
}

void havocbot_role_ctf_defense()
{SELFPARAM();
	entity mf;

	if(self.deadflag != DEAD_NO)
	{
		havocbot_ctf_reset_role(self);
		return;
	}

	if (self.flagcarried)
	{
		havocbot_role_ctf_setrole(self, HAVOCBOT_CTF_ROLE_CARRIER);
		return;
	}

	// If own flag was captured
	mf = havocbot_ctf_find_flag(self);
	if(mf.ctf_status!=FLAG_BASE)
	{
		havocbot_role_ctf_setrole(self, HAVOCBOT_CTF_ROLE_RETRIEVER);
		return;
	}

	if (!self.havocbot_role_timeout)
		self.havocbot_role_timeout = time + 30;

	if (time > self.havocbot_role_timeout)
	{
		havocbot_ctf_reset_role(self);
		return;
	}
	if (self.bot_strategytime < time)
	{
		float mp_radius;
		vector org;

		org = mf.dropped_origin;
		mp_radius = havocbot_ctf_middlepoint_radius;

		self.bot_strategytime = time + autocvar_bot_ai_strategyinterval;
		navigation_goalrating_start();

		// if enemies are closer to our base, go there
		entity head, closestplayer = world;
		float distance, bestdistance = 10000;
		FOR_EACH_PLAYER(head)
		{
			if(head.deadflag!=DEAD_NO)
				continue;

			distance = vlen(org - head.origin);
			if(distance<bestdistance)
			{
				closestplayer = head;
				bestdistance = distance;
			}
		}

		if(closestplayer)
		if(DIFF_TEAM(closestplayer, self))
		if(vlen(org - self.origin)>1000)
		if(checkpvs(self.origin,closestplayer)||random()<0.5)
			havocbot_goalrating_ctf_ourbase(30000);

		havocbot_goalrating_ctf_ourstolenflag(20000);
		havocbot_goalrating_ctf_droppedflags(20000, org, mp_radius);
		havocbot_goalrating_enemyplayers(15000, org, mp_radius);
		havocbot_goalrating_items(10000, org, mp_radius);
		havocbot_goalrating_items(5000, self.origin, 10000);
		navigation_goalrating_end();
	}
}

void havocbot_role_ctf_setrole(entity bot, int role)
{
	LOG_TRACE(strcat(bot.netname," switched to "));
	switch(role)
	{
		case HAVOCBOT_CTF_ROLE_CARRIER:
			LOG_TRACE("carrier");
			bot.havocbot_role = havocbot_role_ctf_carrier;
			bot.havocbot_role_timeout = 0;
			bot.havocbot_cantfindflag = time + 10;
			bot.bot_strategytime = 0;
			break;
		case HAVOCBOT_CTF_ROLE_DEFENSE:
			LOG_TRACE("defense");
			bot.havocbot_role = havocbot_role_ctf_defense;
			bot.havocbot_role_timeout = 0;
			break;
		case HAVOCBOT_CTF_ROLE_MIDDLE:
			LOG_TRACE("middle");
			bot.havocbot_role = havocbot_role_ctf_middle;
			bot.havocbot_role_timeout = 0;
			break;
		case HAVOCBOT_CTF_ROLE_OFFENSE:
			LOG_TRACE("offense");
			bot.havocbot_role = havocbot_role_ctf_offense;
			bot.havocbot_role_timeout = 0;
			break;
		case HAVOCBOT_CTF_ROLE_RETRIEVER:
			LOG_TRACE("retriever");
			bot.havocbot_previous_role = bot.havocbot_role;
			bot.havocbot_role = havocbot_role_ctf_retriever;
			bot.havocbot_role_timeout = time + 10;
			bot.bot_strategytime = 0;
			break;
		case HAVOCBOT_CTF_ROLE_ESCORT:
			LOG_TRACE("escort");
			bot.havocbot_previous_role = bot.havocbot_role;
			bot.havocbot_role = havocbot_role_ctf_escort;
			bot.havocbot_role_timeout = time + 30;
			bot.bot_strategytime = 0;
			break;
	}
	LOG_TRACE("\n");
}


// ==============
// Hook Functions
// ==============

MUTATOR_HOOKFUNCTION(ctf, PlayerPreThink)
{SELFPARAM();
	entity flag;
	int t = 0, t2 = 0, t3 = 0;

	// initially clear items so they can be set as necessary later.
	self.ctf_flagstatus &= ~(CTF_RED_FLAG_CARRYING		| CTF_RED_FLAG_TAKEN		| CTF_RED_FLAG_LOST
						   | CTF_BLUE_FLAG_CARRYING		| CTF_BLUE_FLAG_TAKEN		| CTF_BLUE_FLAG_LOST
						   | CTF_YELLOW_FLAG_CARRYING	| CTF_YELLOW_FLAG_TAKEN 	| CTF_YELLOW_FLAG_LOST
						   | CTF_PINK_FLAG_CARRYING 	| CTF_PINK_FLAG_TAKEN		| CTF_PINK_FLAG_LOST
						   | CTF_NEUTRAL_FLAG_CARRYING	| CTF_NEUTRAL_FLAG_TAKEN	| CTF_NEUTRAL_FLAG_LOST
						   | CTF_FLAG_NEUTRAL | CTF_SHIELDED);

	// scan through all the flags and notify the client about them
	for(flag = ctf_worldflaglist; flag; flag = flag.ctf_worldflagnext)
	{
		if(flag.team == NUM_TEAM_1) { t = CTF_RED_FLAG_CARRYING;		t2 = CTF_RED_FLAG_TAKEN;		t3 = CTF_RED_FLAG_LOST; }
		if(flag.team == NUM_TEAM_2) { t = CTF_BLUE_FLAG_CARRYING;		t2 = CTF_BLUE_FLAG_TAKEN;		t3 = CTF_BLUE_FLAG_LOST; }
		if(flag.team == NUM_TEAM_3) { t = CTF_YELLOW_FLAG_CARRYING; 	t2 = CTF_YELLOW_FLAG_TAKEN;		t3 = CTF_YELLOW_FLAG_LOST; }
		if(flag.team == NUM_TEAM_4) { t = CTF_PINK_FLAG_CARRYING;		t2 = CTF_PINK_FLAG_TAKEN;		t3 = CTF_PINK_FLAG_LOST; }
		if(flag.team == 0) 			{ t = CTF_NEUTRAL_FLAG_CARRYING;	t2 = CTF_NEUTRAL_FLAG_TAKEN;	t3 = CTF_NEUTRAL_FLAG_LOST; self.ctf_flagstatus |= CTF_FLAG_NEUTRAL; }

		switch(flag.ctf_status)
		{
			case FLAG_PASSING:
			case FLAG_CARRY:
			{
				if((flag.owner == self) || (flag.pass_sender == self))
					self.ctf_flagstatus |= t; // carrying: self is currently carrying the flag
				else
					self.ctf_flagstatus |= t2; // taken: someone else is carrying the flag
				break;
			}
			case FLAG_DROPPED:
			{
				self.ctf_flagstatus |= t3; // lost: the flag is dropped somewhere on the map
				break;
			}
		}
	}

	// item for stopping players from capturing the flag too often
	if(self.ctf_captureshielded)
		self.ctf_flagstatus |= CTF_SHIELDED;

	// update the health of the flag carrier waypointsprite
	if(self.wps_flagcarrier)
		WaypointSprite_UpdateHealth(self.wps_flagcarrier, '1 0 0' * healtharmor_maxdamage(self.health, self.armorvalue, autocvar_g_balance_armor_blockpercent, DEATH_WEAPON.m_id));

	return false;
}

MUTATOR_HOOKFUNCTION(ctf, PlayerDamage_Calculate) // for changing damage and force values that are applied to players in g_damage.qc
{
	if(frag_attacker.flagcarried) // if the attacker is a flagcarrier
	{
		if(frag_target == frag_attacker) // damage done to yourself
		{
			frag_damage *= autocvar_g_ctf_flagcarrier_selfdamagefactor;
			frag_force *= autocvar_g_ctf_flagcarrier_selfforcefactor;
		}
		else // damage done to everyone else
		{
			frag_damage *= autocvar_g_ctf_flagcarrier_damagefactor;
			frag_force *= autocvar_g_ctf_flagcarrier_forcefactor;
		}
	}
	else if(frag_target.flagcarried && (frag_target.deadflag == DEAD_NO) && CTF_DIFFTEAM(frag_target, frag_attacker)) // if the target is a flagcarrier
	{
		if(autocvar_g_ctf_flagcarrier_auto_helpme_damage > ('1 0 0' * healtharmor_maxdamage(frag_target.health, frag_target.armorvalue, autocvar_g_balance_armor_blockpercent, DEATH_WEAPON.m_id)))
		if(time > frag_target.wps_helpme_time + autocvar_g_ctf_flagcarrier_auto_helpme_time)
		{
			frag_target.wps_helpme_time = time;
			WaypointSprite_HelpMePing(frag_target.wps_flagcarrier);
		}
		// todo: add notification for when flag carrier needs help?
	}
	return false;
}

MUTATOR_HOOKFUNCTION(ctf, PlayerDies)
{
	if((frag_attacker != frag_target) && (IS_PLAYER(frag_attacker)) && (frag_target.flagcarried))
	{
		PlayerTeamScore_AddScore(frag_attacker, ((SAME_TEAM(frag_attacker, frag_target)) ? -autocvar_g_ctf_score_kill : autocvar_g_ctf_score_kill));
		PlayerScore_Add(frag_attacker, SP_CTF_FCKILLS, 1);
	}

	if(frag_target.flagcarried)
	{
		entity tmp_entity = frag_target.flagcarried;
		ctf_Handle_Throw(frag_target, world, DROP_NORMAL);
		tmp_entity.ctf_dropper = world;
	}

	return false;
}

MUTATOR_HOOKFUNCTION(ctf, GiveFragsForKill)
{
	frag_score = 0;
	return (autocvar_g_ctf_ignore_frags); // no frags counted in ctf if this is true
}

void ctf_RemovePlayer(entity player)
{
	if(player.flagcarried)
		{ ctf_Handle_Throw(player, world, DROP_NORMAL); }

	for(entity flag = ctf_worldflaglist; flag; flag = flag.ctf_worldflagnext)
	{
		if(flag.pass_sender == player) { flag.pass_sender = world; }
		if(flag.pass_target == player) { flag.pass_target = world; }
		if(flag.ctf_dropper == player) { flag.ctf_dropper = world; }
	}
}

MUTATOR_HOOKFUNCTION(ctf, MakePlayerObserver)
{SELFPARAM();
	ctf_RemovePlayer(self);
	return false;
}

MUTATOR_HOOKFUNCTION(ctf, ClientDisconnect)
{SELFPARAM();
	ctf_RemovePlayer(self);
	return false;
}

MUTATOR_HOOKFUNCTION(ctf, PortalTeleport)
{SELFPARAM();
	if(self.flagcarried)
	if(!autocvar_g_ctf_portalteleport)
		{ ctf_Handle_Throw(self, world, DROP_NORMAL); }

	return false;
}

MUTATOR_HOOKFUNCTION(ctf, PlayerUseKey)
{SELFPARAM();
	if(MUTATOR_RETURNVALUE || gameover) { return false; }

	entity player = self;

	if((time > player.throw_antispam) && (player.deadflag == DEAD_NO) && !player.speedrunning && (!player.vehicle || autocvar_g_ctf_allow_vehicle_touch))
	{
		// pass the flag to a team mate
		if(autocvar_g_ctf_pass)
		{
			entity head, closest_target = world;
			head = WarpZone_FindRadius(player.origin, autocvar_g_ctf_pass_radius, true);

			while(head) // find the closest acceptable target to pass to
			{
				if(IS_PLAYER(head) && head.deadflag == DEAD_NO)
				if(head != player && SAME_TEAM(head, player))
				if(!head.speedrunning && !head.vehicle)
				{
					// if it's a player, use the view origin as reference (stolen from RadiusDamage functions in g_damage.qc)
					vector head_center = WarpZone_UnTransformOrigin(head, CENTER_OR_VIEWOFS(head));
					vector passer_center = CENTER_OR_VIEWOFS(player);

					if(ctf_CheckPassDirection(head_center, passer_center, player.v_angle, head.WarpZone_findradius_nearest))
					{
						if(autocvar_g_ctf_pass_request && !player.flagcarried && head.flagcarried)
						{
							if(IS_BOT_CLIENT(head))
							{
								Send_Notification(NOTIF_ONE, player, MSG_CENTER, CENTER_CTF_PASS_REQUESTING, head.netname);
								ctf_Handle_Throw(head, player, DROP_PASS);
							}
							else
							{
								Send_Notification(NOTIF_ONE, head, MSG_CENTER, CENTER_CTF_PASS_REQUESTED, player.netname);
								Send_Notification(NOTIF_ONE, player, MSG_CENTER, CENTER_CTF_PASS_REQUESTING, head.netname);
							}
							player.throw_antispam = time + autocvar_g_ctf_pass_wait;
							return true;
						}
						else if(player.flagcarried)
						{
							if(closest_target)
							{
								vector closest_target_center = WarpZone_UnTransformOrigin(closest_target, CENTER_OR_VIEWOFS(closest_target));
								if(vlen(passer_center - head_center) < vlen(passer_center - closest_target_center))
									{ closest_target = head; }
							}
							else { closest_target = head; }
						}
					}
				}
				head = head.chain;
			}

			if(closest_target) { ctf_Handle_Throw(player, closest_target, DROP_PASS); return true; }
		}

		// throw the flag in front of you
		if(autocvar_g_ctf_throw && player.flagcarried)
		{
			if(player.throw_count == -1)
			{
				if(time > player.throw_prevtime + autocvar_g_ctf_throw_punish_delay)
				{
					player.throw_prevtime = time;
					player.throw_count = 1;
					ctf_Handle_Throw(player, world, DROP_THROW);
					return true;
				}
				else
				{
					Send_Notification(NOTIF_ONE, player, MSG_CENTER, CENTER_CTF_FLAG_THROW_PUNISH, rint((player.throw_prevtime + autocvar_g_ctf_throw_punish_delay) - time));
					return false;
				}
			}
			else
			{
				if(time > player.throw_prevtime + autocvar_g_ctf_throw_punish_time) { player.throw_count = 1; }
				else { player.throw_count += 1; }
				if(player.throw_count >= autocvar_g_ctf_throw_punish_count) { player.throw_count = -1; }

				player.throw_prevtime = time;
				ctf_Handle_Throw(player, world, DROP_THROW);
				return true;
			}
		}
	}

	return false;
}

MUTATOR_HOOKFUNCTION(ctf, HelpMePing)
{SELFPARAM();
	if(self.wps_flagcarrier) // update the flagcarrier waypointsprite with "NEEDING HELP" notification
	{
		self.wps_helpme_time = time;
		WaypointSprite_HelpMePing(self.wps_flagcarrier);
	}
	else // create a normal help me waypointsprite
	{
		WaypointSprite_Spawn(WP_Helpme, waypointsprite_deployed_lifetime, waypointsprite_limitedrange, self, FLAG_WAYPOINT_OFFSET, world, self.team, self, wps_helpme, false, RADARICON_HELPME);
		WaypointSprite_Ping(self.wps_helpme);
	}

	return true;
}

MUTATOR_HOOKFUNCTION(ctf, VehicleEnter)
{
	if(vh_player.flagcarried)
	{
		vh_player.flagcarried.nodrawtoclient = vh_player; // hide the flag from the driver

		if(!autocvar_g_ctf_allow_vehicle_carry && !autocvar_g_ctf_allow_vehicle_touch)
		{
			ctf_Handle_Throw(vh_player, world, DROP_NORMAL);
		}
		else
		{
			setattachment(vh_player.flagcarried, vh_vehicle, "");
			setorigin(vh_player.flagcarried, VEHICLE_FLAG_OFFSET);
			vh_player.flagcarried.scale = VEHICLE_FLAG_SCALE;
			//vh_player.flagcarried.angles = '0 0 0';
		}
		return true;
	}

	return false;
}

MUTATOR_HOOKFUNCTION(ctf, VehicleExit)
{
	if(vh_player.flagcarried)
	{
		setattachment(vh_player.flagcarried, vh_player, "");
		setorigin(vh_player.flagcarried, FLAG_CARRY_OFFSET);
		vh_player.flagcarried.scale = FLAG_SCALE;
		vh_player.flagcarried.angles = '0 0 0';
		vh_player.flagcarried.nodrawtoclient = world;
		return true;
	}

	return false;
}

MUTATOR_HOOKFUNCTION(ctf, AbortSpeedrun)
{SELFPARAM();
	if(self.flagcarried)
	{
		Send_Notification(NOTIF_ALL, world, MSG_INFO, ((self.flagcarried.team) ? APP_TEAM_ENT_4(self.flagcarried, INFO_CTF_FLAGRETURN_ABORTRUN_) : INFO_CTF_FLAGRETURN_ABORTRUN_NEUTRAL));
		ctf_RespawnFlag(self.flagcarried);
		return true;
	}

	return false;
}

MUTATOR_HOOKFUNCTION(ctf, MatchEnd)
{
	entity flag; // temporary entity for the search method

	for(flag = ctf_worldflaglist; flag; flag = flag.ctf_worldflagnext)
	{
		switch(flag.ctf_status)
		{
			case FLAG_DROPPED:
			case FLAG_PASSING:
			{
				// lock the flag, game is over
				flag.movetype = MOVETYPE_NONE;
				flag.takedamage = DAMAGE_NO;
				flag.solid = SOLID_NOT;
				flag.nextthink = false; // stop thinking

				//dprint("stopping the ", flag.netname, " from moving.\n");
				break;
			}

			default:
			case FLAG_BASE:
			case FLAG_CARRY:
			{
				// do nothing for these flags
				break;
			}
		}
	}

	return false;
}

MUTATOR_HOOKFUNCTION(ctf, HavocBot_ChooseRole)
{SELFPARAM();
	havocbot_ctf_reset_role(self);
	return true;
}

MUTATOR_HOOKFUNCTION(ctf, GetTeamCount)
{
	//ret_float = ctf_teams;
	ret_string = "ctf_team";
	return true;
}

MUTATOR_HOOKFUNCTION(ctf, SpectateCopy)
{SELFPARAM();
	self.ctf_flagstatus = other.ctf_flagstatus;
	return false;
}

MUTATOR_HOOKFUNCTION(ctf, GetRecords)
{
	for(int i = record_page * 200; i < MapInfo_count && i < record_page * 200 + 200; ++i)
	{
		if (MapInfo_Get_ByID(i))
		{
			float r = stof(db_get(ServerProgsDB, strcat(MapInfo_Map_bspname, "/captimerecord/time")));

			if(!r)
				continue;

			// TODO: uid2name
			string h = db_get(ServerProgsDB, strcat(MapInfo_Map_bspname, "/captimerecord/netname"));
			ret_string = strcat(ret_string, strpad(32, MapInfo_Map_bspname), " ", strpad(-6, ftos_decimals(r, 2)), " ", h, "\n");
		}
	}

	return false;
}

bool superspec_Spectate(entity _player); // TODO
void superspec_msg(string _center_title, string _con_title, entity _to, string _msg, float _spamlevel); // TODO
MUTATOR_HOOKFUNCTION(ctf, SV_ParseClientCommand)
{
	if(IS_PLAYER(self) || MUTATOR_RETURNVALUE || !cvar("g_superspectate")) { return false; }

	if(cmd_name == "followfc")
	{
		if(!g_ctf)
			return true;

		entity _player;
		int _team = 0;
		bool found = false;

		if(cmd_argc == 2)
		{
			switch(argv(1))
			{
				case "red": _team = NUM_TEAM_1; break;
				case "blue": _team = NUM_TEAM_2; break;
				case "yellow": if(ctf_teams >= 3) _team = NUM_TEAM_3; break;
				case "pink": if(ctf_teams >= 4) _team = NUM_TEAM_4; break;
			}
		}

		FOR_EACH_PLAYER(_player)
		{
			if(_player.flagcarried && (_player.team == _team || _team == 0))
			{
				found = true;
				if(_team == 0 && IS_SPEC(self) && self.enemy == _player)
					continue; // already spectating a fc, try to find the other fc
				return superspec_Spectate(_player);
			}
		}

		if(!found)
			superspec_msg("", "", self, "No active flag carrier\n", 1);
		return true;
	}

	return false;
}

MUTATOR_HOOKFUNCTION(ctf, DropSpecialItems)
{
	if(frag_target.flagcarried)
		ctf_Handle_Throw(frag_target, world, DROP_THROW);

	return false;
}


// ==========
// Spawnfuncs
// ==========

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
spawnfunc(item_flag_team1)
{
	if(!g_ctf) { remove(self); return; }

	ctf_FlagSetup(NUM_TEAM_1, self);
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
spawnfunc(item_flag_team2)
{
	if(!g_ctf) { remove(self); return; }

	ctf_FlagSetup(NUM_TEAM_2, self);
}

/*QUAKED spawnfunc_item_flag_team3 (0 0.5 0.8) (-48 -48 -37) (48 48 37)
CTF flag for team three (Yellow).
Keys:
"angle" Angle the flag will point (minus 90 degrees)...
"model" model to use, note this needs red, blue yellow and pink as skins 0, 1, 2 and 3...
"noise" sound played when flag is picked up...
"noise1" sound played when flag is returned by a teammate...
"noise2" sound played when flag is captured...
"noise3" sound played when flag is lost in the field and respawns itself...
"noise4" sound played when flag is dropped by a player...
"noise5" sound played when flag touches the ground... */
spawnfunc(item_flag_team3)
{
	if(!g_ctf) { remove(self); return; }

	ctf_FlagSetup(NUM_TEAM_3, self);
}

/*QUAKED spawnfunc_item_flag_team4 (0 0.5 0.8) (-48 -48 -37) (48 48 37)
CTF flag for team four (Pink).
Keys:
"angle" Angle the flag will point (minus 90 degrees)...
"model" model to use, note this needs red, blue yellow and pink as skins 0, 1, 2 and 3...
"noise" sound played when flag is picked up...
"noise1" sound played when flag is returned by a teammate...
"noise2" sound played when flag is captured...
"noise3" sound played when flag is lost in the field and respawns itself...
"noise4" sound played when flag is dropped by a player...
"noise5" sound played when flag touches the ground... */
spawnfunc(item_flag_team4)
{
	if(!g_ctf) { remove(self); return; }

	ctf_FlagSetup(NUM_TEAM_4, self);
}

/*QUAKED spawnfunc_item_flag_neutral (0 0.5 0.8) (-48 -48 -37) (48 48 37)
CTF flag (Neutral).
Keys:
"angle" Angle the flag will point (minus 90 degrees)...
"model" model to use, note this needs red, blue yellow and pink as skins 0, 1, 2 and 3...
"noise" sound played when flag is picked up...
"noise1" sound played when flag is returned by a teammate...
"noise2" sound played when flag is captured...
"noise3" sound played when flag is lost in the field and respawns itself...
"noise4" sound played when flag is dropped by a player...
"noise5" sound played when flag touches the ground... */
spawnfunc(item_flag_neutral)
{
	if(!g_ctf) { remove(self); return; }
	if(!cvar("g_ctf_oneflag")) { remove(self); return; }

	ctf_FlagSetup(0, self);
}

/*QUAKED spawnfunc_ctf_team (0 .5 .8) (-16 -16 -24) (16 16 32)
Team declaration for CTF gameplay, this allows you to decide what team names and control point models are used in your map.
Note: If you use spawnfunc_ctf_team entities you must define at least 2!  However, unlike domination, you don't need to make a blank one too.
Keys:
"netname" Name of the team (for example Red, Blue, Green, Yellow, Life, Death, Offense, Defense, etc)...
"cnt" Scoreboard color of the team (for example 4 is red and 13 is blue)... */
spawnfunc(ctf_team)
{
	if(!g_ctf) { remove(self); return; }

	self.classname = "ctf_team";
	self.team = self.cnt + 1;
}

// compatibility for quake maps
spawnfunc(team_CTF_redflag)    { spawnfunc_item_flag_team1(this);    }
spawnfunc(team_CTF_blueflag)   { spawnfunc_item_flag_team2(this);    }
spawnfunc(info_player_team1);
spawnfunc(team_CTF_redplayer)  { spawnfunc_info_player_team1(this);  }
spawnfunc(team_CTF_redspawn)   { spawnfunc_info_player_team1(this);  }
spawnfunc(info_player_team2);
spawnfunc(team_CTF_blueplayer) { spawnfunc_info_player_team2(this);  }
spawnfunc(team_CTF_bluespawn)  { spawnfunc_info_player_team2(this);  }

void team_CTF_neutralflag()			 { SELFPARAM(); spawnfunc_item_flag_neutral(self);  }
void team_neutralobelisk()			 { SELFPARAM(); spawnfunc_item_flag_neutral(self);  }


// ==============
// Initialization
// ==============

// scoreboard setup
void ctf_ScoreRules(int teams)
{
	CheckAllowedTeams(world);
	ScoreRules_basics(teams, SFL_SORT_PRIO_PRIMARY, 0, true);
	ScoreInfo_SetLabel_TeamScore  (ST_CTF_CAPS,     "caps",      SFL_SORT_PRIO_PRIMARY);
	ScoreInfo_SetLabel_PlayerScore(SP_CTF_CAPS,     "caps",      SFL_SORT_PRIO_SECONDARY);
	ScoreInfo_SetLabel_PlayerScore(SP_CTF_CAPTIME,  "captime",   SFL_LOWER_IS_BETTER | SFL_TIME);
	ScoreInfo_SetLabel_PlayerScore(SP_CTF_PICKUPS,  "pickups",   0);
	ScoreInfo_SetLabel_PlayerScore(SP_CTF_FCKILLS,  "fckills",   0);
	ScoreInfo_SetLabel_PlayerScore(SP_CTF_RETURNS,  "returns",   0);
	ScoreInfo_SetLabel_PlayerScore(SP_CTF_DROPS,    "drops",     SFL_LOWER_IS_BETTER);
	ScoreRules_basics_end();
}

// code from here on is just to support maps that don't have flag and team entities
void ctf_SpawnTeam (string teamname, int teamcolor)
{
	entity this = new(ctf_team);
	this.netname = teamname;
	this.cnt = teamcolor;
	this.spawnfunc_checked = true;
	WITH(entity, self, this, spawnfunc_ctf_team(this));
}

void ctf_DelayedInit() // Do this check with a delay so we can wait for teams to be set up.
{
	ctf_teams = 2;

	entity tmp_entity;
	for(tmp_entity = ctf_worldflaglist; tmp_entity; tmp_entity = tmp_entity.ctf_worldflagnext)
	{
		if(tmp_entity.team == NUM_TEAM_3) { ctf_teams = max(3, ctf_teams); }
		if(tmp_entity.team == NUM_TEAM_4) { ctf_teams = max(4, ctf_teams); }
		if(tmp_entity.team == 0) { ctf_oneflag = true; }
	}

	ctf_teams = bound(2, ctf_teams, 4);

	// if no teams are found, spawn defaults
	if(find(world, classname, "ctf_team") == world)
	{
		LOG_TRACE("No \"ctf_team\" entities found on this map, creating them anyway.\n");
		ctf_SpawnTeam("Red", NUM_TEAM_1 - 1);
		ctf_SpawnTeam("Blue", NUM_TEAM_2 - 1);
		if(ctf_teams >= 3)
			ctf_SpawnTeam("Yellow", NUM_TEAM_3 - 1);
		if(ctf_teams >= 4)
			ctf_SpawnTeam("Pink", NUM_TEAM_4 - 1);
	}

	ctf_ScoreRules(ctf_teams);
}

void ctf_Initialize()
{
	ctf_captimerecord = stof(db_get(ServerProgsDB, strcat(GetMapname(), "/captimerecord/time")));

	ctf_captureshield_min_negscore = autocvar_g_ctf_shield_min_negscore;
	ctf_captureshield_max_ratio = autocvar_g_ctf_shield_max_ratio;
	ctf_captureshield_force = autocvar_g_ctf_shield_force;

	InitializeEntity(world, ctf_DelayedInit, INITPRIO_GAMETYPE);
}

#endif
