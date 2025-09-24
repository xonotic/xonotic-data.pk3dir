#include "sv_ctf.qh"

#include <common/checkextension.qh>
#include <common/effects/all.qh>
#include <common/mapobjects/teleporters.qh>
#include <common/mapobjects/triggers.qh>
#include <common/mutators/mutator/powerups/_mod.qh>
#include <common/vehicles/all.qh>
#include <server/command/vote.qh>
#include <server/client.qh>
#include <server/gamelog.qh>
#include <server/intermission.qh>
#include <server/damage.qh>
#include <server/world.qh>
#include <server/items/items.qh>
#include <server/race.qh>
#include <server/teamplay.qh>

#include <lib/warpzone/common.qh>

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
float autocvar_g_ctf_flag_health;
bool autocvar_g_ctf_flag_return;
bool autocvar_g_ctf_flag_return_carrying;
float autocvar_g_ctf_flag_return_carried_radius;
float autocvar_g_ctf_flag_return_time;
bool autocvar_g_ctf_flag_return_when_unreachable;
float autocvar_g_ctf_flag_return_damage;
float autocvar_g_ctf_flag_return_damage_delay;
float autocvar_g_ctf_flag_return_dropped;
bool autocvar_g_ctf_flag_waypoint = true;
float autocvar_g_ctf_flag_waypoint_maxdistance;
float autocvar_g_ctf_flagcarrier_auto_helpme_damage;
float autocvar_g_ctf_flagcarrier_auto_helpme_time;
float autocvar_g_ctf_flagcarrier_selfdamagefactor;
float autocvar_g_ctf_flagcarrier_selfforcefactor;
float autocvar_g_ctf_flagcarrier_damagefactor;
float autocvar_g_ctf_flagcarrier_forcefactor;
//float autocvar_g_ctf_flagcarrier_waypointforenemy_spotting;
bool autocvar_g_ctf_fullbrightflags;
bool autocvar_g_ctf_ignore_frags;
bool autocvar_g_ctf_score_ignore_fields;
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
		GameLogEcho(sprintf(":ctf:%s:%d:%d:%s", mode, flagteam, actor.team, ((actor != NULL) ? ftos(actor.playerid) : "")));
		//GameLogEcho(strcat(":ctf:", mode, ":", ftos(flagteam), ((actor != NULL) ? (strcat(":", ftos(actor.playerid))) : "")));
}

void ctf_CaptureRecord(entity flag, entity player)
{
	float cap_record = ctf_captimerecord;
	float cap_time = (time - flag.ctf_pickuptime);
	string refername = db_get(ServerProgsDB, strcat(GetMapname(), "/captimerecord/netname"));

	// notify about shit
	if(ctf_oneflag)
		Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_CTF_CAPTURE_NEUTRAL, player.netname);
	else if(!ctf_captimerecord)
		Send_Notification(NOTIF_ALL, NULL, MSG_CHOICE, APP_TEAM_NUM(flag.team, CHOICE_CTF_CAPTURE_TIME), player.netname, TIME_ENCODE(cap_time));
	else if(cap_time < cap_record)
		Send_Notification(NOTIF_ALL, NULL, MSG_CHOICE, APP_TEAM_NUM(flag.team, CHOICE_CTF_CAPTURE_BROKEN), player.netname, refername, TIME_ENCODE(cap_time), TIME_ENCODE(cap_record));
	else
		Send_Notification(NOTIF_ALL, NULL, MSG_CHOICE, APP_TEAM_NUM(flag.team, CHOICE_CTF_CAPTURE_UNBROKEN), player.netname, refername, TIME_ENCODE(cap_time), TIME_ENCODE(cap_record));

	// write that shit in the database
	if(!ctf_oneflag) // but not in 1-flag mode
	if((!ctf_captimerecord) || (cap_time < cap_record))
	{
		ctf_captimerecord = cap_time;
		db_put(ServerProgsDB, strcat(GetMapname(), "/captimerecord/time"), ftos(cap_time));
		db_put(ServerProgsDB, strcat(GetMapname(), "/captimerecord/netname"), player.netname);
		write_recordmarker(player, flag.ctf_pickuptime, cap_time);
	}

	if(autocvar_g_ctf_leaderboard && !ctf_oneflag)
		race_setTime(GetMapname(), TIME_ENCODE(cap_time), player.crypto_idfp, player.netname, player, false);
}

bool ctf_Immediate_Return_Allowed(entity flag, entity toucher)
{
	int num_perteam = 0;
	FOREACH_CLIENT(IS_PLAYER(it) && SAME_TEAM(toucher, it), { ++num_perteam; });

	// automatically return if there's only 1 player on the team
	return ((autocvar_g_ctf_flag_return || num_perteam <= 1 || (autocvar_g_ctf_flag_return_carrying && toucher.flagcarried))
		&& flag.team);
}

bool ctf_Return_Customize(entity this, entity client)
{
	// only to the carrier
	return boolean(client == this.owner);
}

void ctf_FlagcarrierWaypoints(entity player)
{
	WaypointSprite_Spawn(WP_FlagCarrier, 0, 0, player, FLAG_WAYPOINT_OFFSET, NULL, player.team, player, wps_flagcarrier, true, RADARICON_FLAG);
	WaypointSprite_UpdateMaxHealth(player.wps_flagcarrier, 2 * healtharmor_maxdamage(start_health, start_armorvalue, autocvar_g_balance_armor_blockpercent, DEATH_WEAPON.m_id).x);
	WaypointSprite_UpdateHealth(player.wps_flagcarrier, healtharmor_maxdamage(GetResource(player, RES_HEALTH), GetResource(player, RES_ARMOR), autocvar_g_balance_armor_blockpercent, DEATH_WEAPON.m_id).x);
	WaypointSprite_UpdateTeamRadar(player.wps_flagcarrier, RADARICON_FLAGCARRIER, WPCOLOR_FLAGCARRIER(player.team));

	if(player.flagcarried && CTF_SAMETEAM(player, player.flagcarried))
	{
		if(!player.wps_enemyflagcarrier)
		{
			entity base_wp = WP_FlagCarrier;
			if (!ctf_oneflag)
			{
				switch (player.team)
				{
					case NUM_TEAM_1: base_wp = WP_FlagCarrierEnemyRed; break;
					case NUM_TEAM_2: base_wp = WP_FlagCarrierEnemyBlue; break;
					case NUM_TEAM_3: base_wp = WP_FlagCarrierEnemyYellow; break;
					case NUM_TEAM_4: base_wp = WP_FlagCarrierEnemyPink; break;
					default: base_wp = WP_FlagCarrierEnemyNeutral; break;
				}
			}
			entity wp = WaypointSprite_Spawn(base_wp, 0, 0, player, FLAG_WAYPOINT_OFFSET, NULL,
				0, player, wps_enemyflagcarrier, true, RADARICON_FLAG);
			wp.colormod = WPCOLOR_ENEMYFC(player.team);
			setcefc(wp, ctf_Stalemate_Customize);

			if(IS_REAL_CLIENT(player) && !ctf_stalemate)
				Send_Notification(NOTIF_ONE, player, MSG_CENTER, CENTER_CTF_PICKUP_VISIBLE);
		}

		if(!player.wps_flagreturn)
		{
			entity owp = WaypointSprite_SpawnFixed(WP_FlagReturn, player.flagcarried.ctf_spawnorigin + FLAG_WAYPOINT_OFFSET, player, wps_flagreturn, RADARICON_FLAG);
			owp.colormod = '0 0.8 0.8';
			//WaypointSprite_UpdateTeamRadar(player.wps_flagreturn, RADARICON_FLAG, ((player.team) ? colormapPaletteColor(player.team - 1, false) : '1 1 1'));
			setcefc(owp, ctf_Return_Customize);
		}
	}
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
			targpos = (trace_endpos + eZ * FLAG_PASS_ARC_OFFSET_Z);
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
	int players_worseeq, players_total;

	if(ctf_captureshield_max_ratio <= 0)
		return false;

	s  = GameRules_scoring_add(p, CTF_CAPS, 0);
	s2 = GameRules_scoring_add(p, CTF_PICKUPS, 0);
	s3 = GameRules_scoring_add(p, CTF_RETURNS, 0);
	s4 = GameRules_scoring_add(p, CTF_FCKILLS, 0);

	sr = ((s - s2) + (s3 + s4));

	if(sr >= -ctf_captureshield_min_negscore)
		return false;

	players_total = players_worseeq = 0;
	FOREACH_CLIENT(IS_PLAYER(it), {
		if(DIFF_TEAM(it, p))
			continue;
		se  = GameRules_scoring_add(it, CTF_CAPS, 0);
		se2 = GameRules_scoring_add(it, CTF_PICKUPS, 0);
		se3 = GameRules_scoring_add(it, CTF_RETURNS, 0);
		se4 = GameRules_scoring_add(it, CTF_FCKILLS, 0);

		ser = ((se - se2) + (se3 + se4));

		if(ser <= sr)
			++players_worseeq;
		++players_total;
	});

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

bool ctf_CaptureShield_Customize(entity this, entity client)
{
	if(!client.ctf_captureshielded) { return false; }
	if(CTF_SAMETEAM(this, client)) { return false; }

	return true;
}

void ctf_CaptureShield_Touch(entity this, entity toucher)
{
	if(!toucher.ctf_captureshielded) { return; }
	if(CTF_SAMETEAM(this, toucher)) { return; }

	vector mymid = (this.absmin + this.absmax) * 0.5;
	vector theirmid = (toucher.absmin + toucher.absmax) * 0.5;

	Damage(toucher, this, this, 0, DEATH_HURTTRIGGER.m_id, DMG_NOWEP, mymid, normalize(theirmid - mymid) * ctf_captureshield_force);
	if(IS_REAL_CLIENT(toucher)) { Send_Notification(NOTIF_ONE, toucher, MSG_CENTER, CENTER_CTF_CAPTURESHIELD_SHIELDED); }
}

void ctf_CaptureShield_Spawn(entity flag)
{
	entity shield = new(ctf_captureshield);

	shield.enemy = flag;
	shield.team = flag.team;
	settouch(shield, ctf_CaptureShield_Touch);
	setcefc(shield, ctf_CaptureShield_Customize);
	shield.effects = EF_ADDITIVE;
	set_movetype(shield, MOVETYPE_NOCLIP);
	shield.solid = SOLID_TRIGGER;
	shield.avelocity = '7 0 11';
	shield.scale = 0.5;

	setorigin(shield, flag.origin);
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
	set_movetype(flag, MOVETYPE_TOSS);
	flag.takedamage = DAMAGE_YES;
	flag.angles = '0 0 0';

	flag.max_health = ((autocvar_g_ctf_flag_return_damage && autocvar_g_ctf_flag_health > 0) ? autocvar_g_ctf_flag_health : 100);
	SetResourceExplicit(flag, RES_HEALTH, flag.max_health);

	flag.ctf_droptime = time;
	flag.ctf_landtime = 0;
	flag.ctf_dropper = player;
	flag.ctf_status = FLAG_DROPPED;

	flag.damagedbycontents = autocvar_g_ctf_flag_return_when_unreachable;
	if(flag.damagedbycontents)
		IL_PUSH(g_damagedbycontents, flag);

	// messages and sounds
	Send_Notification(NOTIF_ALL, NULL, MSG_INFO, APP_NUM(flag.team, INFO_CTF_LOST), player.netname);
	_sound(flag, CH_TRIGGER, flag.snd_flag_dropped, VOL_BASE, ATTEN_NONE);
	ctf_EventLog("dropped", player.team, player);

	// scoring
	GameRules_scoring_add_team(player, SCORE, -((flag.score_drop) ? flag.score_drop : autocvar_g_ctf_score_penalty_drop));
	GameRules_scoring_add(player, CTF_DROPS, 1);

	// waypoints
	if(autocvar_g_ctf_flag_dropped_waypoint) {
		entity base_wp;
		switch (flag.team)
		{
			case NUM_TEAM_1: base_wp = WP_FlagDroppedRed; break;
			case NUM_TEAM_2: base_wp = WP_FlagDroppedBlue; break;
			case NUM_TEAM_3: base_wp = WP_FlagDroppedYellow; break;
			case NUM_TEAM_4: base_wp = WP_FlagDroppedPink; break;
			default: base_wp = WP_FlagDroppedNeutral; break;
		}
		int wp_team = ((autocvar_g_ctf_flag_dropped_waypoint == 2) ? 0 : player.team);
		entity wp = WaypointSprite_Spawn(base_wp, 0, 0, flag, FLAG_WAYPOINT_OFFSET, NULL,
			wp_team, flag, wps_flagdropped, true, RADARICON_FLAG);
		wp.colormod = WPCOLOR_DROPPEDFLAG(flag.team);
	}

	if(autocvar_g_ctf_flag_return_time > 0 || autocvar_g_ctf_flag_return_damage)
	{
		WaypointSprite_UpdateMaxHealth(flag.wps_flagdropped, flag.max_health);
		WaypointSprite_UpdateHealth(flag.wps_flagdropped, GetResource(flag, RES_HEALTH));
	}

	player.throw_antispam = time + autocvar_g_ctf_pass_wait;

	if(droptype == DROP_PASS)
	{
		flag.pass_distance = 0;
		flag.pass_sender = NULL;
		flag.pass_target = NULL;
	}
}

void ctf_Handle_Retrieve(entity flag, entity player)
{
	entity sender = flag.pass_sender;

	// transfer flag to player
	flag.owner = player;
	flag.owner.flagcarried = flag;
	GameRules_scoring_vip(player, true);

	// reset flag
	flag.solid = SOLID_NOT; // before setorigin to prevent area grid linking
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
	set_movetype(flag, MOVETYPE_NONE);
	flag.takedamage = DAMAGE_NO;
	flag.angles = '0 0 0';
	flag.ctf_status = FLAG_CARRY;

	// messages and sounds
	_sound(player, CH_TRIGGER, flag.snd_flag_pass, VOL_BASE, ATTEN_NORM);
	ctf_EventLog("receive", flag.team, player);

	FOREACH_CLIENT(IS_PLAYER(it) && IS_REAL_CLIENT(it), {
		if(it == sender)
			Send_Notification(NOTIF_ONE, it, MSG_CENTER, APP_NUM(flag.team, CENTER_CTF_PASS_SENT), player.netname);
		else if(it == player)
			Send_Notification(NOTIF_ONE, it, MSG_CENTER, APP_NUM(flag.team, CENTER_CTF_PASS_RECEIVED), sender.netname);
		else if(SAME_TEAM(it, sender))
			Send_Notification(NOTIF_ONE, it, MSG_CENTER, APP_NUM(flag.team, CENTER_CTF_PASS_OTHER), sender.netname, player.netname);
	});

	// create new waypoint
	ctf_FlagcarrierWaypoints(player);

	sender.throw_antispam = time + autocvar_g_ctf_pass_wait;
	player.throw_antispam = sender.throw_antispam;

	flag.pass_distance = 0;
	flag.pass_sender = NULL;
	flag.pass_target = NULL;
}

void ctf_Handle_Throw(entity player, entity receiver, int droptype)
{
	entity flag = player.flagcarried;
	vector targ_origin, flag_velocity;

	if(!flag) { return; }
	if((droptype == DROP_PASS) && !receiver) { return; }

	if(flag.speedrunning)
	{
		// ensure old waypoints are removed before resetting the flag
		WaypointSprite_Kill(player.wps_flagcarrier);

		if(player.wps_enemyflagcarrier)
			WaypointSprite_Kill(player.wps_enemyflagcarrier);

		if(player.wps_flagreturn)
			WaypointSprite_Kill(player.wps_flagreturn);
		ctf_RespawnFlag(flag);
		return;
	}

	// reset the flag
	setattachment(flag, NULL, "");
	tracebox(player.origin + vec3(0, 0, player.mins.z - flag.m_mins.z), // same bbox floor height as player
	         flag.m_mins, flag.m_maxs, player.origin + FLAG_DROP_OFFSET, MOVE_NOMONSTERS, flag);
	flag.solid = SOLID_TRIGGER; // before setorigin to ensure area grid linking
	setorigin(flag, trace_endpos);
	if (trace_startsolid && !nudgeoutofsolid_OrFallback(flag)) // TODO: trace_allsolid would perform better but isn't 100% reliable yet
	{
		// the flag's bbox doesn't fit but we can assume the player's current bbox does
		tracebox(player.origin, player.mins, player.maxs, player.origin + FLAG_DROP_OFFSET, MOVE_NOMONSTERS, flag);
		flag.origin = trace_endpos;
		setsize(flag, player.mins, player.maxs); // this allows physics to move the flag somewhere its think func can resize it
	}
	flag.owner.flagcarried = NULL;
	GameRules_scoring_vip(flag.owner, false);
	flag.owner = NULL;
	flag.ctf_dropper = player;
	flag.ctf_droptime = time;
	flag.ctf_landtime = 0;

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
			set_movetype(flag, MOVETYPE_FLY);
			flag.takedamage = DAMAGE_NO;
			flag.pass_sender = player;
			flag.pass_target = receiver;
			flag.ctf_status = FLAG_PASSING;

			// other
			_sound(player, CH_TRIGGER, flag.snd_flag_touch, VOL_BASE, ATTEN_NORM);
			WarpZone_TrailParticles(NULL, _particleeffectnum(flag.passeffect), player.origin, targ_origin);
			ctf_EventLog("pass", flag.team, player);
			break;
		}

		case DROP_THROW:
		{
			makevectors((player.v_angle.y * '0 1 0') + (bound(autocvar_g_ctf_throw_angle_min, player.v_angle.x, autocvar_g_ctf_throw_angle_max) * '1 0 0'));

			flag_velocity = (('0 0 1' * autocvar_g_ctf_throw_velocity_up) + ((v_forward * autocvar_g_ctf_throw_velocity_forward) * ((StatusEffects_active(STATUSEFFECT_Strength, player)) ? autocvar_g_ctf_throw_strengthmultiplier : 1)));
			flag.velocity = W_CalculateProjectileVelocity(player, player.velocity, flag_velocity, false);
			ctf_Handle_Drop(flag, player, droptype);
			navigation_dynamicgoal_set(flag, player);
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
			flag.velocity = W_CalculateProjectileVelocity(player, player.velocity, (('0 0 1' * autocvar_g_ctf_drop_velocity_up) + ((('0 1 0' * crandom()) + ('1 0 0' * crandom())) * autocvar_g_ctf_drop_velocity_side)), false);
			ctf_Handle_Drop(flag, player, droptype);
			navigation_dynamicgoal_set(flag, player);
			break;
		}
	}

	// kill old waypointsprite
	WaypointSprite_Ping(player.wps_flagcarrier);
	WaypointSprite_Kill(player.wps_flagcarrier);

	if(player.wps_enemyflagcarrier)
		WaypointSprite_Kill(player.wps_enemyflagcarrier);

	if(player.wps_flagreturn)
		WaypointSprite_Kill(player.wps_flagreturn);

	// captureshield
	ctf_CaptureShield_Update(player, 0); // shield player from picking up flag
}

#if 0
void shockwave_spawn(string m, vector org, float sz, float t1, float t2)
{
	return modeleffect_spawn(m, 0, 0, org, '0 0 0', '0 0 0', '0 0 0', 0, sz, 1, t1, t2);
}
#endif

// ==============
// Event Handlers
// ==============

void nades_GiveBonus(entity player, float score);

void ctf_Handle_Capture(entity flag, entity toucher, int capturetype)
{
	entity enemy_flag = ((capturetype == CAPTURE_NORMAL) ? toucher.flagcarried : toucher);
	entity player = ((capturetype == CAPTURE_NORMAL) ? toucher : enemy_flag.ctf_dropper);
	entity player_team_flag = NULL, tmp_entity;
	float old_time, new_time;

	if(!player) { return; } // without someone to give the reward to, we can't possibly cap
	if(CTF_DIFFTEAM(player, flag)) { return; }
	if((flag.cnt || enemy_flag.cnt) && flag.cnt != enemy_flag.cnt) { return; } // this should catch some edge cases (capturing grouped flag at ungrouped flag disallowed etc)

	if (toucher.goalentity == flag.bot_basewaypoint)
		toucher.goalentity_lock_timeout = 0;

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
	Send_Notification(NOTIF_ONE, player, MSG_CENTER, APP_NUM(enemy_flag.team, CENTER_CTF_CAPTURE));
	ctf_CaptureRecord(enemy_flag, player);
	_sound(player, CH_TRIGGER, ((ctf_oneflag) ? player_team_flag.snd_flag_capture : ((DIFF_TEAM(player, flag)) ? enemy_flag.snd_flag_capture : flag.snd_flag_capture)), VOL_BASE, ATTEN_NONE);

	switch(capturetype)
	{
		case CAPTURE_NORMAL: ctf_EventLog("capture", enemy_flag.team, player); break;
		case CAPTURE_DROPPED: ctf_EventLog("droppedcapture", enemy_flag.team, player); break;
		default: break;
	}

	// scoring
	float pscore = 0;
	if(enemy_flag.score_capture || flag.score_capture)
		pscore = floor((max(1, enemy_flag.score_capture) + max(1, flag.score_capture)) * 0.5);
	GameRules_scoring_add_team(player, SCORE, ((pscore) ? pscore : autocvar_g_ctf_score_capture));
	float capscore = 0;
	if(enemy_flag.score_team_capture || flag.score_team_capture)
		capscore = floor((max(1, enemy_flag.score_team_capture) + max(1, flag.score_team_capture)) * 0.5);
	GameRules_scoring_add_team(player, CTF_CAPS, ((capscore) ? capscore : 1));

	old_time = GameRules_scoring_add(player, CTF_CAPTIME, 0);
	new_time = TIME_ENCODE(time - enemy_flag.ctf_pickuptime);
	if(!old_time || new_time < old_time)
		GameRules_scoring_add(player, CTF_CAPTIME, new_time - old_time);

	// effects
	Send_Effect_(flag.capeffect, flag.origin, '0 0 0', 1);
#if 0
	shockwave_spawn("models/ctf/shockwavetransring.md3", flag.origin - '0 0 15', -0.8, 0, 1);
#endif

	// other
	if(capturetype == CAPTURE_NORMAL)
	{
		WaypointSprite_Kill(player.wps_flagcarrier);
		if(flag.speedrunning) { ctf_FakeTimeLimit(player, -1); }

		if((enemy_flag.ctf_dropper) && (player != enemy_flag.ctf_dropper))
			{ GameRules_scoring_add_team(enemy_flag.ctf_dropper, SCORE, ((enemy_flag.score_assist) ? enemy_flag.score_assist : autocvar_g_ctf_score_capture_assist)); }
	}

	flag.enemy = toucher;

	// reset the flag
	player.next_take_time = time + autocvar_g_ctf_flag_collect_delay;
	ctf_RespawnFlag(enemy_flag);
}

void ctf_Handle_Return(entity flag, entity player)
{
	// messages and sounds
	if(IS_MONSTER(player))
	{
		Send_Notification(NOTIF_ALL, NULL, MSG_INFO, APP_TEAM_NUM(flag.team, INFO_CTF_RETURN_MONSTER), player.m_name);
	}
	else if(flag.team)
	{
		Send_Notification(NOTIF_ONE, player, MSG_CENTER, APP_TEAM_NUM(flag.team, CENTER_CTF_RETURN));
		Send_Notification(NOTIF_ALL, NULL, MSG_INFO, APP_TEAM_NUM(flag.team, INFO_CTF_RETURN), player.netname);
	}
	_sound(player, CH_TRIGGER, flag.snd_flag_returned, VOL_BASE, ATTEN_NONE);
	ctf_EventLog("return", flag.team, player);

	// scoring
	if(IS_PLAYER(player))
	{
		GameRules_scoring_add_team(player, SCORE, ((flag.score_return) ? flag.score_return : autocvar_g_ctf_score_return)); // reward for return
		GameRules_scoring_add(player, CTF_RETURNS, 1); // add to count of returns

		nades_GiveBonus(player,autocvar_g_nades_bonus_score_medium);
	}

	TeamScore_AddToTeam(flag.team, ST_SCORE, -autocvar_g_ctf_score_penalty_returned); // punish the team who was last carrying it

	if(flag.ctf_dropper)
	{
		GameRules_scoring_add(flag.ctf_dropper, SCORE, -autocvar_g_ctf_score_penalty_returned); // punish the player who dropped the flag
		ctf_CaptureShield_Update(flag.ctf_dropper, 0); // shield player from picking up flag
		flag.ctf_dropper.next_take_time = time + autocvar_g_ctf_flag_collect_delay; // set next take time
	}

	// other
	if(player.flagcarried == flag)
		WaypointSprite_Kill(player.wps_flagcarrier);

	flag.enemy = player;

	// reset the flag
	ctf_RespawnFlag(flag);
}

void ctf_Handle_Pickup(entity flag, entity player, int pickuptype)
{
	// declarations
	float pickup_dropped_score; // used to calculate dropped pickup score

	// attach the flag to the player
	flag.owner = player;
	player.flagcarried = flag;
	GameRules_scoring_vip(player, true);
	flag.solid = SOLID_NOT; // before setorigin to prevent area grid linking
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
	set_movetype(flag, MOVETYPE_NONE);
	flag.takedamage = DAMAGE_NO;
	flag.angles = '0 0 0';
	flag.ctf_status = FLAG_CARRY;

	flag.damagedbycontents = false;
	if(IL_CONTAINS(g_damagedbycontents, flag))
		IL_REMOVE(g_damagedbycontents, flag);

	StatusEffects_removeall(flag, STATUSEFFECT_REMOVE_CLEAR);

	switch(pickuptype)
	{
		case PICKUP_BASE: flag.ctf_pickuptime = time; break; // used for timing runs
		case PICKUP_DROPPED: SetResourceExplicit(flag, RES_HEALTH, flag.max_health); break; // reset health/return timelimit
		default: break;
	}

	// messages and sounds
	Send_Notification(NOTIF_ALL, NULL, MSG_INFO, APP_NUM(flag.team, INFO_CTF_PICKUP), player.netname);
	if(ctf_stalemate)
		Send_Notification(NOTIF_ONE, player, MSG_CENTER, CENTER_CTF_STALEMATE_CARRIER);
	if(!flag.team)
		Send_Notification(NOTIF_ONE, player, MSG_CENTER, CENTER_CTF_PICKUP_NEUTRAL);
	else if(CTF_DIFFTEAM(player, flag))
		Send_Notification(NOTIF_ONE, player, MSG_CENTER, APP_TEAM_NUM(flag.team, CENTER_CTF_PICKUP));
	else
		Send_Notification(NOTIF_ONE, player, MSG_CENTER, ((SAME_TEAM(player, flag)) ? CENTER_CTF_PICKUP_RETURN : CENTER_CTF_PICKUP_RETURN_ENEMY), Team_ColorCode(flag.team));

	Send_Notification(NOTIF_TEAM_EXCEPT, player, MSG_CHOICE, APP_NUM(flag.team, CHOICE_CTF_PICKUP_TEAM), Team_ColorCode(player.team), player.netname);

	if(!flag.team)
		FOREACH_CLIENT(IS_PLAYER(it) && it != player && DIFF_TEAM(it, player), { Send_Notification(NOTIF_ONE, it, MSG_CHOICE, CHOICE_CTF_PICKUP_ENEMY_NEUTRAL, Team_ColorCode(player.team), player.netname); });

	if(flag.team)
		FOREACH_CLIENT(IS_PLAYER(it) && it != player, {
			if(CTF_SAMETEAM(flag, it))
				Send_Notification(NOTIF_ONE, it, MSG_CHOICE, ((SAME_TEAM(flag, player)) ? CHOICE_CTF_PICKUP_ENEMY_TEAM : CHOICE_CTF_PICKUP_ENEMY), Team_ColorCode(player.team), player.netname);
			else if(DIFF_TEAM(player, it))
				Send_Notification(NOTIF_ONE, it, MSG_CHOICE, APP_NUM(flag.team, CHOICE_CTF_PICKUP_ENEMY_OTHER), Team_ColorCode(player.team), player.netname);
		});

	_sound(player, CH_TRIGGER, flag.snd_flag_taken, VOL_BASE, ATTEN_NONE);

	// scoring
	GameRules_scoring_add(player, CTF_PICKUPS, 1);
	nades_GiveBonus(player, autocvar_g_nades_bonus_score_minor);
	switch(pickuptype)
	{
		case PICKUP_BASE:
		{
			GameRules_scoring_add_team(player, SCORE, ((flag.score_pickup) ? flag.score_pickup : autocvar_g_ctf_score_pickup_base));
			ctf_EventLog("steal", flag.team, player);
			break;
		}

		case PICKUP_DROPPED:
		{
			pickup_dropped_score = (autocvar_g_ctf_flag_return_time > 0 ? bound(0, ((flag.ctf_droptime + autocvar_g_ctf_flag_return_time) - time) / autocvar_g_ctf_flag_return_time, 1) : 1);
			pickup_dropped_score = floor((autocvar_g_ctf_score_pickup_dropped_late * (1 - pickup_dropped_score) + autocvar_g_ctf_score_pickup_dropped_early * pickup_dropped_score) + 0.5);
			LOG_TRACE("pickup_dropped_score is ", ftos(pickup_dropped_score));
			GameRules_scoring_add_team(player, SCORE, pickup_dropped_score);
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
		if (flag.wps_flagdropped
		&& (autocvar_g_ctf_flag_return_time > 0 || autocvar_g_ctf_flag_return_damage))
		{
			WaypointSprite_UpdateHealth(flag.wps_flagdropped, GetResource(flag, RES_HEALTH));
		}

		if((GetResource(flag, RES_HEALTH) <= 0)
			|| (autocvar_g_ctf_flag_return_time > 0 && time >= flag.ctf_droptime + autocvar_g_ctf_flag_return_time))
		{
			switch(returntype)
			{
				case RETURN_DROPPED:
					Send_Notification(NOTIF_ALL, NULL, MSG_INFO, APP_NUM(flag.team, INFO_CTF_FLAGRETURN_DROPPED)); break;
				case RETURN_DAMAGE:
					Send_Notification(NOTIF_ALL, NULL, MSG_INFO, APP_NUM(flag.team, INFO_CTF_FLAGRETURN_DAMAGED)); break;
				case RETURN_SPEEDRUN:
					Send_Notification(NOTIF_ALL, NULL, MSG_INFO, APP_NUM(flag.team, INFO_CTF_FLAGRETURN_SPEEDRUN), TIME_ENCODE(ctf_captimerecord)); break;
				case RETURN_NEEDKILL:
					Send_Notification(NOTIF_ALL, NULL, MSG_INFO, APP_NUM(flag.team, INFO_CTF_FLAGRETURN_NEEDKILL)); break;
				default:
				case RETURN_TIMEOUT:
					Send_Notification(NOTIF_ALL, NULL, MSG_INFO, APP_NUM(flag.team, INFO_CTF_FLAGRETURN_TIMEOUT)); break;
			}
			_sound(flag, CH_TRIGGER, flag.snd_flag_respawn, VOL_BASE, ATTEN_NONE);
			ctf_EventLog("returned", flag.team, NULL);
			flag.enemy = NULL;
			ctf_RespawnFlag(flag);
		}
	}
}

bool ctf_Stalemate_Customize(entity this, entity client)
{
	// make spectators see what the player would see
	entity e = WaypointSprite_getviewentity(client);
	entity wp_owner = this.owner;

	// team waypoints
	//if(CTF_SAMETEAM(wp_owner.flagcarried, wp_owner)) { return false; }
	if(SAME_TEAM(wp_owner, e) || !IS_PLAYER(e))
		return false;
	if(IS_INVISIBLE(wp_owner))
		return false; // hide the waypointsprite if the owner is invisible

	return true;
}

void ctf_CheckStalemate()
{
	// declarations
	int stale_flags = 0, stale_red_flags = 0, stale_blue_flags = 0, stale_yellow_flags = 0, stale_pink_flags = 0, stale_neutral_flags = 0;
	entity tmp_entity;

	entity ctf_staleflaglist = NULL; // reset the list, we need to build the list each time this function runs

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
				entity base_wp = WP_FlagCarrier;
				if (!ctf_oneflag)
				{
					switch (tmp_entity.owner.team)
					{
						case NUM_TEAM_1: base_wp = WP_FlagCarrierEnemyRed; break;
						case NUM_TEAM_2: base_wp = WP_FlagCarrierEnemyBlue; break;
						case NUM_TEAM_3: base_wp = WP_FlagCarrierEnemyYellow; break;
						case NUM_TEAM_4: base_wp = WP_FlagCarrierEnemyPink; break;
						default: base_wp = WP_FlagCarrierEnemyNeutral; break;
					}
				}
				entity wp = WaypointSprite_Spawn(base_wp, 0, 0, tmp_entity.owner, FLAG_WAYPOINT_OFFSET, NULL,
					0, tmp_entity.owner, wps_enemyflagcarrier, true, RADARICON_FLAG);
				wp.colormod = WPCOLOR_ENEMYFC(tmp_entity.owner.team);
				setcefc(tmp_entity.owner.wps_enemyflagcarrier, ctf_Stalemate_Customize);
			}
		}

		if (!wpforenemy_announced)
		{
			FOREACH_CLIENT(IS_PLAYER(it) && IS_REAL_CLIENT(it), { Send_Notification(NOTIF_ONE, it, MSG_CENTER, ((it.flagcarried) ? CENTER_CTF_STALEMATE_CARRIER : CENTER_CTF_STALEMATE_OTHER)); });

			wpforenemy_announced = true;
		}
	}
}

void ctf_FlagDamage(entity this, entity inflictor, entity attacker, float damage, int deathtype, .entity weaponentity, vector hitloc, vector force)
{
	if(ITEM_DAMAGE_NEEDKILL(deathtype))
	{
		if(autocvar_g_ctf_flag_return_damage_delay)
			this.ctf_flagdamaged_byworld = true;
		else
		{
			SetResourceExplicit(this, RES_HEALTH, 0);
			ctf_CheckFlagReturn(this, RETURN_NEEDKILL);
		}
		return;
	}
	if(autocvar_g_ctf_flag_return_damage)
	{
		// reduce health and check if it should be returned
		TakeResource(this, RES_HEALTH, damage);
		ctf_CheckFlagReturn(this, RETURN_DAMAGE);
		return;
	}
}

void ctf_FlagThink(entity this)
{
	// declarations
	entity tmp_entity;

	this.nextthink = time + FLAG_THINKRATE; // only 5 fps, more is unnecessary.

	// captureshield
	if(this == ctf_worldflaglist) // only for the first flag
		FOREACH_CLIENT(true, { ctf_CaptureShield_Update(it, 1); }); // release shield only

	// sanity checks
	if(this.mins != this.m_mins || this.maxs != this.m_maxs) { // reset the flag boundaries in case it got squished
		tracebox(this.origin, this.m_mins, this.m_maxs, this.origin, MOVE_NOMONSTERS, this);
		if(!trace_startsolid || this.noalign) // can we resize it without getting stuck?
			setsize(this, this.m_mins, this.m_maxs);
	}

	// main think method
	switch(this.ctf_status)
	{
		case FLAG_BASE:
		{
			if(autocvar_g_ctf_dropped_capture_radius)
			{
				for(tmp_entity = ctf_worldflaglist; tmp_entity; tmp_entity = tmp_entity.ctf_worldflagnext)
					if(tmp_entity.ctf_status == FLAG_DROPPED)
					if(vdist(this.origin - tmp_entity.origin, <, autocvar_g_ctf_dropped_capture_radius))
					if((this.noalign || tmp_entity.ctf_landtime) && time > ((this.noalign) ? tmp_entity.ctf_droptime : tmp_entity.ctf_landtime) + autocvar_g_ctf_dropped_capture_delay)
						ctf_Handle_Capture(this, tmp_entity, CAPTURE_DROPPED);
			}
			return;
		}

		case FLAG_DROPPED:
		{
			this.angles = '0 0 0'; // reset flag angles in case warpzones adjust it
			if(IS_ONGROUND(this) && !this.ctf_landtime)
				this.ctf_landtime = time; // landtime is reset when thrown, and we don't want to restart the timer if the flag is pushed

			if(autocvar_g_ctf_flag_dropped_floatinwater)
			{
				vector midpoint = ((this.absmin + this.absmax) * 0.5);
				if(pointcontents(midpoint) == CONTENT_WATER)
				{
					this.velocity = this.velocity * 0.5;

					if (pointcontents(midpoint + eZ * FLAG_FLOAT_OFFSET_Z) == CONTENT_WATER)
						{ this.velocity_z = autocvar_g_ctf_flag_dropped_floatinwater; }
					else
						{ set_movetype(this, MOVETYPE_FLY); }
				}
				else if(this.move_movetype == MOVETYPE_FLY) { set_movetype(this, MOVETYPE_TOSS); }
			}
			if(autocvar_g_ctf_flag_return_dropped)
			{
				if((vdist(this.origin - this.ctf_spawnorigin, <=, autocvar_g_ctf_flag_return_dropped)) || (autocvar_g_ctf_flag_return_dropped == -1))
				{
					SetResourceExplicit(this, RES_HEALTH, 0);
					ctf_CheckFlagReturn(this, RETURN_DROPPED);
					return;
				}
			}
			if(this.ctf_flagdamaged_byworld)
			{
				TakeResource(this, RES_HEALTH, (this.max_health / autocvar_g_ctf_flag_return_damage_delay) * FLAG_THINKRATE);
				ctf_CheckFlagReturn(this, RETURN_NEEDKILL);
				return;
			}
			else if(autocvar_g_ctf_flag_return_time > 0)
			{
				TakeResource(this, RES_HEALTH, (this.max_health / autocvar_g_ctf_flag_return_time) * FLAG_THINKRATE);
				ctf_CheckFlagReturn(this, RETURN_TIMEOUT);
				return;
			}
			return;
		}

		case FLAG_CARRY:
		{
			if(this.speedrunning && ctf_captimerecord && (time >= this.ctf_pickuptime + ctf_captimerecord))
			{
				SetResourceExplicit(this, RES_HEALTH, 0);
				ctf_CheckFlagReturn(this, RETURN_SPEEDRUN);

				CS(this.owner).impulse = CHIMPULSE_SPEEDRUN.impulse; // move the player back to the waypoint they set
				ImpulseCommands(this.owner);
			}
			if(autocvar_g_ctf_stalemate)
			{
				if(time >= wpforenemy_nextthink)
				{
					ctf_CheckStalemate();
					wpforenemy_nextthink = time + WPFE_THINKRATE; // waypoint for enemy think rate (to reduce unnecessary spam of this check)
				}
			}
			if(CTF_SAMETEAM(this, this.owner) && this.team)
			{
				if(autocvar_g_ctf_flag_return) // drop the flag if reverse status has changed
					ctf_Handle_Throw(this.owner, NULL, DROP_THROW);
				else if(vdist(this.owner.origin - this.ctf_spawnorigin, <=, autocvar_g_ctf_flag_return_carried_radius))
					ctf_Handle_Return(this, this.owner);
			}
			return;
		}

		case FLAG_PASSING:
		{
			vector targ_origin = ((this.pass_target.absmin + this.pass_target.absmax) * 0.5);
			targ_origin = WarpZone_RefSys_TransformOrigin(this.pass_target, this, targ_origin); // origin of target as seen by the flag (us)
			WarpZone_TraceLine(this.origin, targ_origin, MOVE_NOMONSTERS, this);

			if((this.pass_target == NULL)
				|| (IS_DEAD(this.pass_target))
				|| (this.pass_target.flagcarried)
				|| (vdist(this.origin - targ_origin, >, autocvar_g_ctf_pass_radius))
				|| ((trace_fraction < 1) && (trace_ent != this.pass_target))
				|| (time > this.ctf_droptime + autocvar_g_ctf_pass_timelimit))
			{
				// give up, pass failed
				ctf_Handle_Drop(this, NULL, DROP_PASS);
			}
			else
			{
				// still a viable target, go for it
				ctf_CalculatePassVelocity(this, targ_origin, this.origin, true);
			}
			return;
		}

		default: // this should never happen
		{
			LOG_TRACE("ctf_FlagThink(): Flag exists with no status?");
			return;
		}
	}
}

METHOD(Flag, giveTo, bool(Flag this, entity flag, entity toucher))
{
	return = false;
	if(game_stopped) return;
	if(trace_dphitcontents & (DPCONTENTS_PLAYERCLIP | DPCONTENTS_MONSTERCLIP)) { return; }

	bool is_not_monster = (!IS_MONSTER(toucher));

	// automatically kill the flag and return it if it touched lava/slime/nodrop surfaces
	if(ITEM_TOUCH_NEEDKILL())
	{
		if(!autocvar_g_ctf_flag_return_damage_delay)
		{
			SetResourceExplicit(flag, RES_HEALTH, 0);
			ctf_CheckFlagReturn(flag, RETURN_NEEDKILL);
		}
		if(!flag.ctf_flagdamaged_byworld) { return; }
	}

	// special touch behaviors
	// TODO: mutator hook to prevent picking up objectives
	if(IS_INDEPENDENT_PLAYER(toucher)) { return; }
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
	else if(IS_DEAD(toucher)) { return; }

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
				ctf_Handle_Capture(flag, toucher, CAPTURE_NORMAL); // toucher just captured the enemies flag to their base
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
			if(CTF_SAMETEAM(toucher, flag) && ctf_Immediate_Return_Allowed(flag, toucher))
				ctf_Handle_Return(flag, toucher); // toucher just returned their own flag
			else if(is_not_monster && (!toucher.flagcarried) && ((toucher != flag.ctf_dropper) || (time > flag.ctf_droptime + autocvar_g_ctf_flag_collect_delay)))
				ctf_Handle_Pickup(flag, toucher, PICKUP_DROPPED); // toucher just picked up a dropped enemy flag
			break;
		}

		case FLAG_CARRY:
		{
			LOG_TRACE("Someone touched a flag even though it was being carried?");
			break;
		}

		case FLAG_PASSING:
		{
			if((IS_PLAYER(toucher)) && !IS_DEAD(toucher) && (toucher != flag.pass_sender))
			{
				if(DIFF_TEAM(toucher, flag.pass_sender))
				{
					if(ctf_Immediate_Return_Allowed(flag, toucher))
						ctf_Handle_Return(flag, toucher);
					else if(is_not_monster && (!toucher.flagcarried))
						ctf_Handle_Pickup(flag, toucher, PICKUP_DROPPED);
				}
				else if(!toucher.flagcarried)
					ctf_Handle_Retrieve(flag, toucher);
			}
			break;
		}
	}
}

void ctf_RespawnFlag(entity flag)
{
	flag.watertype = CONTENT_EMPTY; // TODO: it is unclear why this workaround is needed, likely many other potential breakage points!!

	// reset the player (if there is one)
	if((flag.owner) && (flag.owner.flagcarried == flag))
	{
		WaypointSprite_Kill(flag.owner.wps_enemyflagcarrier);
		WaypointSprite_Kill(flag.owner.wps_flagreturn);
		WaypointSprite_Kill(flag.wps_flagcarrier);

		flag.owner.flagcarried = NULL;
		GameRules_scoring_vip(flag.owner, false);

		if(flag.speedrunning)
			ctf_FakeTimeLimit(flag.owner, -1);
	}

	if((flag.owner) && (flag.owner.vehicle))
		flag.scale = FLAG_SCALE;

	if(flag.ctf_status == FLAG_DROPPED)
		{ WaypointSprite_Kill(flag.wps_flagdropped); }

	// reset the flag
	setattachment(flag, NULL, "");
	flag.solid = SOLID_TRIGGER; // before setorigin to ensure area grid linking
	setorigin(flag, flag.ctf_spawnorigin);

	//set_movetype(flag, ((flag.noalign) ? MOVETYPE_NONE : MOVETYPE_TOSS)); // would be desired, except maps that want floating flags have it set to fall!
	set_movetype(flag, MOVETYPE_NONE); // match the initial setup handling (flag doesn't move when spawned)
	flag.takedamage = DAMAGE_NO;
	SetResourceExplicit(flag, RES_HEALTH, flag.max_health);
	flag.velocity = '0 0 0';
	flag.angles = flag.mangle;
	flag.flags = FL_ITEM | FL_NOTARGET;

	flag.damagedbycontents = false;
	if(IL_CONTAINS(g_damagedbycontents, flag))
		IL_REMOVE(g_damagedbycontents, flag);

	StatusEffects_removeall(flag, STATUSEFFECT_REMOVE_CLEAR);

	flag.ctf_status = FLAG_BASE;
	flag.owner = NULL;
	flag.pass_distance = 0;
	flag.pass_sender = NULL;
	flag.pass_target = NULL;
	flag.ctf_dropper = NULL;
	flag.ctf_pickuptime = 0;
	flag.ctf_droptime = 0;
	flag.ctf_landtime = 0;
	flag.ctf_flagdamaged_byworld = false;
	navigation_dynamicgoal_unset(flag);

	ctf_CheckStalemate();
}

void ctf_Reset(entity this)
{
	if(this.owner && IS_PLAYER(this.owner))
		ctf_Handle_Throw(this.owner, NULL, DROP_RESET);

	this.enemy = NULL;
	ctf_RespawnFlag(this);
}

bool ctf_FlagBase_Customize(entity this, entity client)
{
	entity e = WaypointSprite_getviewentity(client);
	entity wp_owner = this.owner;
	entity flag = e.flagcarried;
	if(flag && CTF_SAMETEAM(e, flag))
		return false;
	if(flag && (flag.cnt || wp_owner.cnt) && wp_owner.cnt != flag.cnt)
		return false;
	return true;
}

void ctf_DelayedFlagSetup(entity this) // called after a flag is placed on a map by ctf_FlagSetup()
{
	// bot waypoints
	waypoint_spawnforitem_force(this, this.origin);
	navigation_dynamicgoal_init(this, true);

	// waypointsprites
	entity basename;
	switch (this.team)
	{
		case NUM_TEAM_1: basename = WP_FlagBaseRed; break;
		case NUM_TEAM_2: basename = WP_FlagBaseBlue; break;
		case NUM_TEAM_3: basename = WP_FlagBaseYellow; break;
		case NUM_TEAM_4: basename = WP_FlagBasePink; break;
		default: basename = WP_FlagBaseNeutral; break;
	}

	if(autocvar_g_ctf_flag_waypoint)
	{
		entity wp = WaypointSprite_SpawnFixed(basename, this.origin + FLAG_WAYPOINT_OFFSET, this, wps_flagbase, RADARICON_FLAG);
		wp.colormod = ((this.team) ? Team_ColorRGB(this.team) : '1 1 1');
		wp.fade_rate = autocvar_g_ctf_flag_waypoint_maxdistance;
		WaypointSprite_UpdateTeamRadar(this.wps_flagbase, RADARICON_FLAG, ((this.team) ? colormapPaletteColor(this.team - 1, false) : '1 1 1'));
		setcefc(wp, ctf_FlagBase_Customize);
	}

	// captureshield setup
	ctf_CaptureShield_Spawn(this);
}

.bool pushable;

void ctf_FlagSetup(int teamnum, entity flag) // called when spawning a flag entity on the map as a spawnfunc
{
	// main setup
	flag.ctf_worldflagnext = ctf_worldflaglist; // link flag into ctf_worldflaglist
	ctf_worldflaglist = flag;

	setattachment(flag, NULL, "");

	flag.netname = strzone(sprintf("%s%s^7 flag", Team_ColorCode(teamnum), Team_ColorName_Upper(teamnum)));
	flag.team = teamnum;
	flag.classname = "item_flag_team";
	flag.target = "###item###"; // for finding the nearest item using findnearest
	flag.flags = FL_ITEM | FL_NOTARGET;
	IL_PUSH(g_items, flag);
	flag.solid = SOLID_TRIGGER;
	flag.takedamage = DAMAGE_NO;
	flag.damageforcescale = autocvar_g_ctf_flag_damageforcescale;

	flag.max_health = ((autocvar_g_ctf_flag_return_damage && autocvar_g_ctf_flag_health > 0) ? autocvar_g_ctf_flag_health : 100);
	SetResourceExplicit(flag, RES_HEALTH, flag.max_health);

	flag.event_damage = ctf_FlagDamage;
	flag.pushable = true;
	flag.teleportable = TELEPORT_NORMAL;
	flag.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_PLAYERCLIP;
	flag.damagedbytriggers = autocvar_g_ctf_flag_return_when_unreachable;
	flag.damagedbycontents = false; // can be damaged by contents only when dropped

	flag.velocity = '0 0 0';
	flag.mangle = flag.angles;
	flag.reset = ctf_Reset;
	settouch(flag, ctf_FlagTouch);
	setthink(flag, ctf_FlagThink);
	flag.nextthink = time + FLAG_THINKRATE;
	flag.ctf_status = FLAG_BASE;

	// set correct team colors
	flag.glowmod = Team_ColorRGB(teamnum);
	flag.colormap = (teamnum) ? (teamnum - 1) * 0x11 : 0x00;
	flag.colormap |= BIT(10); // RENDER_COLORMAPPED

	// crudely force them all to 0
	if(autocvar_g_ctf_score_ignore_fields)
		flag.cnt = flag.score_assist = flag.score_team_capture = flag.score_capture = flag.score_drop = flag.score_pickup = flag.score_return = 0;

	string teamname = Static_Team_ColorName_Lower(teamnum);
	// appearence
	if(!flag.scale)				{ flag.scale = FLAG_SCALE; }
	if(flag.skin == 0)			{ flag.skin = cvar(sprintf("g_ctf_flag_%s_skin", teamname)); }
	if(flag.model == "")		{ flag.model = cvar_string(sprintf("g_ctf_flag_%s_model", teamname)); }
	if (flag.toucheffect == "") { flag.toucheffect = EFFECT_FLAG_TOUCH(teamnum).eent_eff_name; }
	if (flag.passeffect == "") 	{ flag.passeffect = EFFECT_PASS(teamnum).eent_eff_name; }
	if (flag.capeffect == "") 	{ flag.capeffect = EFFECT_CAP(teamnum).eent_eff_name; }

	// sounds
#define X(s,b) \
		if(flag.s == "") flag.s = b; \
		precache_sound(flag.s);

	X(snd_flag_taken, 		strzone(SND(CTF_TAKEN(teamnum))))
	X(snd_flag_returned, 	strzone(SND(CTF_RETURNED(teamnum))))
	X(snd_flag_capture, 	strzone(SND(CTF_CAPTURE(teamnum))))
	X(snd_flag_dropped, 	strzone(SND(CTF_DROPPED(teamnum))))
	X(snd_flag_respawn, 	strzone(SND(CTF_RESPAWN)))
	X(snd_flag_touch, 		strzone(SND(CTF_TOUCH)))
	X(snd_flag_pass, 		strzone(SND(CTF_PASS)))
#undef X

	// precache
	precache_model(flag.model);

	// appearence
	_setmodel(flag, flag.model); // precision set below
	setsize(flag, vrint(CTF_FLAG.m_mins * flag.scale), vrint(CTF_FLAG.m_maxs * flag.scale));
	flag.m_mins = flag.mins; // store these for squash checks
	flag.m_maxs = flag.maxs;
	setorigin(flag, (flag.origin + FLAG_SPAWN_OFFSET));

	if(autocvar_g_ctf_flag_glowtrails)
	{
		switch(teamnum)
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
		switch(teamnum)
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
		set_movetype(flag, MOVETYPE_NONE);
	}
	else // drop to floor, automatically find a platform and set that as spawn origin
	{
		flag.noalign = false;
		DropToFloor_QC_DelayedInit(flag);
		set_movetype(flag, MOVETYPE_NONE);
	}

	InitializeEntity(flag, ctf_DelayedFlagSetup, INITPRIO_SETLOCATION);
}


// ================
// Bot player logic
// ================

// NOTE: LEGACY CODE, needs to be re-written!

void havocbot_ctf_calculate_middlepoint()
{
	entity f;
	vector s = '0 0 0';
	vector fo = '0 0 0';
	int n = 0;

	f = ctf_worldflaglist;
	while (f)
	{
		fo = f.origin;
		s = s + fo;
		f = f.ctf_worldflagnext;
		n++;
	}
	if(!n)
		return;

	// TODO: Consider changing this back to `s / n` after https://github.com/graphitemaster/gmqcc/issues/210.
	havocbot_middlepoint = s * (1 / n);
	havocbot_middlepoint_radius = vlen(fo - havocbot_middlepoint);

	havocbot_symmetry_axis_m = 0;
	havocbot_symmetry_axis_q = 0;
	if(n == 2)
	{
		// for symmetrical editing of waypoints
		entity f1 = ctf_worldflaglist;
		entity f2 = f1.ctf_worldflagnext;
		float m = -(f1.origin.y - f2.origin.y) / (max(f1.origin.x - f2.origin.x, FLOAT_EPSILON));
		float q = havocbot_middlepoint.y - m * havocbot_middlepoint.x;
		havocbot_symmetry_axis_m = m;
		havocbot_symmetry_axis_q = q;
	}
	havocbot_symmetry_origin_order = n;
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
	return NULL;
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
	return NULL;
}

int havocbot_ctf_teamcount(entity bot, vector org, float tc_radius)
{
	if (!teamplay)
		return 0;

	int c = 0;

	FOREACH_CLIENT(IS_PLAYER(it), {
		if(DIFF_TEAM(it, bot) || IS_DEAD(it) || it == bot)
			continue;

		if(vdist(it.origin - org, <, tc_radius))
			++c;
	});

	return c;
}

// unused
#if 0
void havocbot_goalrating_ctf_ourflag(entity this, float ratingscale)
{
	entity head;
	head = ctf_worldflaglist;
	while (head)
	{
		if (CTF_SAMETEAM(this, head))
			break;
		head = head.ctf_worldflagnext;
	}
	if (head)
		navigation_routerating(this, head, ratingscale, 10000);
}
#endif

void havocbot_goalrating_ctf_ourbase(entity this, float ratingscale)
{
	entity head;
	head = ctf_worldflaglist;
	while (head)
	{
		if (CTF_SAMETEAM(this, head))
		{
			if (this.flagcarried)
			if ((this.flagcarried.cnt || head.cnt) && this.flagcarried.cnt != head.cnt)
			{
				head = head.ctf_worldflagnext; // skip base if it has a different group
				continue;
			}
			break;
		}
		head = head.ctf_worldflagnext;
	}
	if (!head)
		return;

	navigation_routerating(this, head.bot_basewaypoint, ratingscale, 10000);
}

void havocbot_goalrating_ctf_enemyflag(entity this, float ratingscale)
{
	entity head;
	head = ctf_worldflaglist;
	while (head)
	{
		if(ctf_oneflag)
		{
			if(CTF_DIFFTEAM(this, head))
			{
				if(head.team)
				{
					if(this.flagcarried)
						break;
				}
				else if(!this.flagcarried)
					break;
			}
		}
		else if(CTF_DIFFTEAM(this, head))
			break;
		head = head.ctf_worldflagnext;
	}
	if (head)
	{
		if (head.ctf_status == FLAG_CARRY)
		{
			// adjust rating of our flag carrier depending on their health
			head = head.tag_entity;
			float f = bound(0, (GetResource(head, RES_HEALTH) + GetResource(head, RES_ARMOR)) / 100, 2) - 1;
			ratingscale += ratingscale * f * 0.1;
		}
		navigation_routerating(this, head, ratingscale, 10000);
	}
}

void havocbot_goalrating_ctf_enemybase(entity this, float ratingscale)
{
	// disabled because we always spawn waypoints for flags with waypoint_spawnforitem_force
	/*
	if (!bot_waypoints_for_items)
	{
		havocbot_goalrating_ctf_enemyflag(this, ratingscale);
		return;
	}
	*/
	entity head;

	head = havocbot_ctf_find_enemy_flag(this);

	if (!head)
		return;

	navigation_routerating(this, head.bot_basewaypoint, ratingscale, 10000);
}

void havocbot_goalrating_ctf_ourstolenflag(entity this, float ratingscale)
{
	entity mf;

	mf = havocbot_ctf_find_flag(this);

	if(mf.ctf_status == FLAG_BASE)
		return;

	if(mf.tag_entity)
		navigation_routerating(this, mf.tag_entity, ratingscale, 10000);
}

void havocbot_goalrating_ctf_droppedflags(entity this, float ratingscale, vector org, float df_radius)
{
	entity head;
	head = ctf_worldflaglist;
	while (head)
	{
		// flag is out in the field
		if(head.ctf_status != FLAG_BASE)
		if(head.tag_entity==NULL)	// dropped
		{
			if(df_radius)
			{
				if(vdist(org - head.origin, <, df_radius))
					navigation_routerating(this, head, ratingscale, 10000);
			}
			else
				navigation_routerating(this, head, ratingscale, 10000);
		}

		head = head.ctf_worldflagnext;
	}
}

void havocbot_ctf_reset_role(entity this)
{
	float cdefense, cmiddle, coffense;
	entity mf, ef;

	if(IS_DEAD(this))
		return;

	// Check ctf flags
	if (this.flagcarried)
	{
		havocbot_role_ctf_setrole(this, HAVOCBOT_CTF_ROLE_CARRIER);
		return;
	}

	mf = havocbot_ctf_find_flag(this);
	ef = havocbot_ctf_find_enemy_flag(this);

	// Retrieve stolen flag
	if(mf.ctf_status!=FLAG_BASE)
	{
		havocbot_role_ctf_setrole(this, HAVOCBOT_CTF_ROLE_RETRIEVER);
		return;
	}

	// If enemy flag is taken go to the middle to intercept pursuers
	if(ef.ctf_status!=FLAG_BASE)
	{
		havocbot_role_ctf_setrole(this, HAVOCBOT_CTF_ROLE_MIDDLE);
		return;
	}

	// if there is no one else on the team switch to offense
	int count = 0;
	// don't check if this bot is a player since it isn't true when the bot is added to the server
	FOREACH_CLIENT(it != this && IS_PLAYER(it) && SAME_TEAM(it, this), { ++count; });

	if (count == 0)
	{
		havocbot_role_ctf_setrole(this, HAVOCBOT_CTF_ROLE_OFFENSE);
		return;
	}
	else if (time < CS(this).jointime + 1)
	{
		// if bots spawn all at once set good default roles
		if (count == 1)
		{
			havocbot_role_ctf_setrole(this, HAVOCBOT_CTF_ROLE_DEFENSE);
			return;
		}
		else if (count == 2)
		{
			havocbot_role_ctf_setrole(this, HAVOCBOT_CTF_ROLE_MIDDLE);
			return;
		}
	}

	// Evaluate best position to take
	// Count mates on middle position
	cmiddle = havocbot_ctf_teamcount(this, havocbot_middlepoint, havocbot_middlepoint_radius * 0.5);

	// Count mates on defense position
	cdefense = havocbot_ctf_teamcount(this, mf.dropped_origin, havocbot_middlepoint_radius * 0.5);

	// Count mates on offense position
	coffense = havocbot_ctf_teamcount(this, ef.dropped_origin, havocbot_middlepoint_radius);

	if(cdefense<=coffense)
		havocbot_role_ctf_setrole(this, HAVOCBOT_CTF_ROLE_DEFENSE);
	else if(coffense<=cmiddle)
		havocbot_role_ctf_setrole(this, HAVOCBOT_CTF_ROLE_OFFENSE);
	else
		havocbot_role_ctf_setrole(this, HAVOCBOT_CTF_ROLE_MIDDLE);

	// if bots spawn all at once assign them a more appropriated role after a while
	if (time < CS(this).jointime + 1 && count > 2)
		this.havocbot_role_timeout = time + 10 + random() * 10;
}

bool havocbot_ctf_is_basewaypoint(entity item)
{
	if (item.classname != "waypoint")
		return false;

	entity head = ctf_worldflaglist;
	while (head)
	{
		if (item == head.bot_basewaypoint)
			return true;
		head = head.ctf_worldflagnext;
	}
	return false;
}

void havocbot_role_ctf_carrier(entity this)
{
	if(IS_DEAD(this))
	{
		havocbot_ctf_reset_role(this);
		return;
	}

	if (this.flagcarried == NULL)
	{
		havocbot_ctf_reset_role(this);
		return;
	}

	if (navigation_goalrating_timeout(this))
	{
		navigation_goalrating_start(this);

		// role: carrier
		entity mf = havocbot_ctf_find_flag(this);
		vector base_org = mf.dropped_origin;
		float base_rating = (mf.ctf_status == FLAG_BASE) ? 10000 : (vdist(this.origin - base_org, >, 100) ? 2000 : 1000);
		if(ctf_oneflag)
			havocbot_goalrating_ctf_enemybase(this, base_rating);
		else
			havocbot_goalrating_ctf_ourbase(this, base_rating);

		// start collecting items very close to the bot but only inside of own base radius
		if (vdist(this.origin - base_org, <, havocbot_middlepoint_radius))
			havocbot_goalrating_items(this, 15000, this.origin, min(500, havocbot_middlepoint_radius * 0.5));

		havocbot_goalrating_items(this, 10000, base_org, havocbot_middlepoint_radius * 0.5);

		navigation_goalrating_end(this);

		navigation_goalrating_timeout_set(this);

		entity goal = this.goalentity;
		if (havocbot_ctf_is_basewaypoint(goal) && vdist(goal.origin - this.origin, <, 100))
			this.goalentity_lock_timeout = time + ((this.enemy) ? 2 : 3);

		if (goal)
			this.havocbot_cantfindflag = time + 10;
		else if (time > this.havocbot_cantfindflag)
		{
			// Can't navigate to my own base, suicide!
			// TODO: drop it and wander around
			Damage(this, this, this, 100000, DEATH_KILL.m_id, DMG_NOWEP, this.origin, '0 0 0');
			return;
		}
	}
}

void havocbot_role_ctf_escort(entity this)
{
	entity mf, ef;

	if(IS_DEAD(this))
	{
		havocbot_ctf_reset_role(this);
		return;
	}

	if (this.flagcarried)
	{
		havocbot_role_ctf_setrole(this, HAVOCBOT_CTF_ROLE_CARRIER);
		return;
	}

	// If enemy flag is back on the base switch to previous role
	ef = havocbot_ctf_find_enemy_flag(this);
	if(ef.ctf_status==FLAG_BASE)
	{
		this.havocbot_role = this.havocbot_previous_role;
		this.havocbot_role_timeout = 0;
		return;
	}
	if (ef.ctf_status == FLAG_DROPPED)
	{
		navigation_goalrating_timeout_expire(this, 1);
		return;
	}

	// If the flag carrier reached the base switch to defense
	mf = havocbot_ctf_find_flag(this);
	if (mf.ctf_status != FLAG_BASE && vdist(ef.origin - mf.dropped_origin, <, 900))
	{
		havocbot_role_ctf_setrole(this, HAVOCBOT_CTF_ROLE_DEFENSE);
		return;
	}

	// Set the role timeout if necessary
	if (!this.havocbot_role_timeout)
	{
		this.havocbot_role_timeout = time + random() * 30 + 60;
	}

	// If nothing happened just switch to previous role
	if (time > this.havocbot_role_timeout)
	{
		this.havocbot_role = this.havocbot_previous_role;
		this.havocbot_role_timeout = 0;
		return;
	}

	// Chase the flag carrier
	if (navigation_goalrating_timeout(this))
	{
		navigation_goalrating_start(this);

		// role: escort
		havocbot_goalrating_ctf_enemyflag(this, 10000);
		havocbot_goalrating_ctf_ourstolenflag(this, 6000);
		havocbot_goalrating_items(this, 21000, this.origin, 10000);

		navigation_goalrating_end(this);

		navigation_goalrating_timeout_set(this);
	}
}

void havocbot_role_ctf_offense(entity this)
{
	entity mf, ef;
	vector pos;

	if(IS_DEAD(this))
	{
		havocbot_ctf_reset_role(this);
		return;
	}

	if (this.flagcarried)
	{
		havocbot_role_ctf_setrole(this, HAVOCBOT_CTF_ROLE_CARRIER);
		return;
	}

	// Check flags
	mf = havocbot_ctf_find_flag(this);
	ef = havocbot_ctf_find_enemy_flag(this);

	// Own flag stolen
	if(mf.ctf_status!=FLAG_BASE)
	{
		if(mf.tag_entity)
			pos = mf.tag_entity.origin;
		else
			pos = mf.origin;

		// Try to get it if closer than the enemy base
		if(vlen2(this.origin-ef.dropped_origin)>vlen2(this.origin-pos))
		{
			havocbot_role_ctf_setrole(this, HAVOCBOT_CTF_ROLE_RETRIEVER);
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

		if(vdist(pos - mf.dropped_origin, >, 700))
		{
			havocbot_role_ctf_setrole(this, HAVOCBOT_CTF_ROLE_ESCORT);
			return;
		}
	}

	// Set the role timeout if necessary
	if (!this.havocbot_role_timeout)
		this.havocbot_role_timeout = time + 120;

	if (time > this.havocbot_role_timeout)
	{
		havocbot_ctf_reset_role(this);
		return;
	}

	if (navigation_goalrating_timeout(this))
	{
		navigation_goalrating_start(this);

		// role: offense
		havocbot_goalrating_ctf_ourstolenflag(this, 10000);
		havocbot_goalrating_ctf_enemybase(this, 10000);
		havocbot_goalrating_items(this, 22000, this.origin, 10000);

		navigation_goalrating_end(this);

		navigation_goalrating_timeout_set(this);
	}
}

// Retriever (temporary role):
void havocbot_role_ctf_retriever(entity this)
{
	entity mf;

	if(IS_DEAD(this))
	{
		havocbot_ctf_reset_role(this);
		return;
	}

	if (this.flagcarried)
	{
		havocbot_role_ctf_setrole(this, HAVOCBOT_CTF_ROLE_CARRIER);
		return;
	}

	// If flag is back on the base switch to previous role
	mf = havocbot_ctf_find_flag(this);
	if(mf.ctf_status==FLAG_BASE)
	{
		if (mf.enemy == this) // did this bot return the flag?
			navigation_goalrating_timeout_force(this);
		havocbot_ctf_reset_role(this);
		return;
	}

	if (!this.havocbot_role_timeout)
		this.havocbot_role_timeout = time + 20;

	if (time > this.havocbot_role_timeout)
	{
		havocbot_ctf_reset_role(this);
		return;
	}

	if (navigation_goalrating_timeout(this))
	{
		const float RT_RADIUS = 10000;

		navigation_goalrating_start(this);

		// role: retriever
		havocbot_goalrating_ctf_ourstolenflag(this, 10000);
		havocbot_goalrating_ctf_droppedflags(this, 12000, this.origin, RT_RADIUS);
		havocbot_goalrating_ctf_enemybase(this, 8000);
		entity ef = havocbot_ctf_find_enemy_flag(this);
		vector enemy_base_org = ef.dropped_origin;
		// start collecting items very close to the bot but only inside of enemy base radius
		if (vdist(this.origin - enemy_base_org, <, havocbot_middlepoint_radius))
			havocbot_goalrating_items(this, 27000, this.origin, min(500, havocbot_middlepoint_radius * 0.5));
		havocbot_goalrating_items(this, 18000, this.origin, havocbot_middlepoint_radius);

		navigation_goalrating_end(this);

		navigation_goalrating_timeout_set(this);
	}
}

void havocbot_role_ctf_middle(entity this)
{
	entity mf;

	if(IS_DEAD(this))
	{
		havocbot_ctf_reset_role(this);
		return;
	}

	if (this.flagcarried)
	{
		havocbot_role_ctf_setrole(this, HAVOCBOT_CTF_ROLE_CARRIER);
		return;
	}

	mf = havocbot_ctf_find_flag(this);
	if(mf.ctf_status!=FLAG_BASE)
	{
		havocbot_role_ctf_setrole(this, HAVOCBOT_CTF_ROLE_RETRIEVER);
		return;
	}

	if (!this.havocbot_role_timeout)
		this.havocbot_role_timeout = time + 10;

	if (time > this.havocbot_role_timeout)
	{
		havocbot_ctf_reset_role(this);
		return;
	}

	if (navigation_goalrating_timeout(this))
	{
		vector org;

		org = havocbot_middlepoint;
		org.z = this.origin.z;

		navigation_goalrating_start(this);

		// role: middle
		havocbot_goalrating_ctf_ourstolenflag(this, 8000);
		havocbot_goalrating_ctf_droppedflags(this, 9000, this.origin, 10000);
		havocbot_goalrating_enemyplayers(this, 25000, org, havocbot_middlepoint_radius * 0.5);
		havocbot_goalrating_items(this, 25000, org, havocbot_middlepoint_radius * 0.5);
		havocbot_goalrating_items(this, 18000, this.origin, 10000);
		havocbot_goalrating_ctf_enemybase(this, 3000);

		navigation_goalrating_end(this);

		entity goal = this.goalentity;
		if (havocbot_ctf_is_basewaypoint(goal) && vdist(goal.origin - this.origin, <, 100))
			this.goalentity_lock_timeout = time + 2;

		navigation_goalrating_timeout_set(this);
	}
}

void havocbot_role_ctf_defense(entity this)
{
	entity mf;

	if(IS_DEAD(this))
	{
		havocbot_ctf_reset_role(this);
		return;
	}

	if (this.flagcarried)
	{
		havocbot_role_ctf_setrole(this, HAVOCBOT_CTF_ROLE_CARRIER);
		return;
	}

	// If own flag was captured
	mf = havocbot_ctf_find_flag(this);
	if(mf.ctf_status!=FLAG_BASE)
	{
		havocbot_role_ctf_setrole(this, HAVOCBOT_CTF_ROLE_RETRIEVER);
		return;
	}

	if (!this.havocbot_role_timeout)
		this.havocbot_role_timeout = time + 30;

	if (time > this.havocbot_role_timeout)
	{
		havocbot_ctf_reset_role(this);
		return;
	}
	if (navigation_goalrating_timeout(this))
	{
		vector org = mf.dropped_origin;

		navigation_goalrating_start(this);

		// if enemies are closer to our base, go there
		entity closestplayer = NULL;
		float distance, bestdistance = 10000;
		FOREACH_CLIENT(IS_PLAYER(it) && !IS_DEAD(it), {
			distance = vlen(org - it.origin);
			if(distance<bestdistance)
			{
				closestplayer = it;
				bestdistance = distance;
			}
		});

		// role: defense
		if(closestplayer)
		if(DIFF_TEAM(closestplayer, this))
		if(vdist(org - this.origin, >, 1000))
		if(checkpvs(this.origin,closestplayer)||random()<0.5)
			havocbot_goalrating_ctf_ourbase(this, 10000);

		havocbot_goalrating_ctf_ourstolenflag(this, 5000);
		havocbot_goalrating_ctf_droppedflags(this, 6000, org, havocbot_middlepoint_radius);
		havocbot_goalrating_enemyplayers(this, 25000, org, havocbot_middlepoint_radius);
		havocbot_goalrating_items(this, 25000, org, havocbot_middlepoint_radius);
		havocbot_goalrating_items(this, 18000, this.origin, 10000);

		navigation_goalrating_end(this);

		navigation_goalrating_timeout_set(this);
	}
}

void havocbot_role_ctf_setrole(entity bot, int role)
{
	string s = "(null)";
	switch(role)
	{
		case HAVOCBOT_CTF_ROLE_CARRIER:
			s = "carrier";
			bot.havocbot_role = havocbot_role_ctf_carrier;
			bot.havocbot_role_timeout = 0;
			bot.havocbot_cantfindflag = time + 10;
			if (bot.havocbot_previous_role != bot.havocbot_role)
				navigation_goalrating_timeout_force(bot);
			break;
		case HAVOCBOT_CTF_ROLE_DEFENSE:
			s = "defense";
			bot.havocbot_role = havocbot_role_ctf_defense;
			bot.havocbot_role_timeout = 0;
			break;
		case HAVOCBOT_CTF_ROLE_MIDDLE:
			s = "middle";
			bot.havocbot_role = havocbot_role_ctf_middle;
			bot.havocbot_role_timeout = 0;
			break;
		case HAVOCBOT_CTF_ROLE_OFFENSE:
			s = "offense";
			bot.havocbot_role = havocbot_role_ctf_offense;
			bot.havocbot_role_timeout = 0;
			break;
		case HAVOCBOT_CTF_ROLE_RETRIEVER:
			s = "retriever";
			bot.havocbot_previous_role = bot.havocbot_role;
			bot.havocbot_role = havocbot_role_ctf_retriever;
			bot.havocbot_role_timeout = time + 10;
			if (bot.havocbot_previous_role != bot.havocbot_role)
				navigation_goalrating_timeout_expire(bot, 2);
			break;
		case HAVOCBOT_CTF_ROLE_ESCORT:
			s = "escort";
			bot.havocbot_previous_role = bot.havocbot_role;
			bot.havocbot_role = havocbot_role_ctf_escort;
			bot.havocbot_role_timeout = time + 30;
			if (bot.havocbot_previous_role != bot.havocbot_role)
				navigation_goalrating_timeout_expire(bot, 2);
			break;
	}
	LOG_TRACE(bot.netname, " switched to ", s);
}


// ==============
// Hook Functions
// ==============

MUTATOR_HOOKFUNCTION(ctf, PlayerPreThink)
{
	entity player = M_ARGV(0, entity);

	int t = 0, t2 = 0, t3 = 0;
	bool b1 = false, b2 = false, b3 = false, b4 = false, b5 = false; // TODO: kill this, we WANT to show the other flags, somehow! (note: also means you don't see if you're FC)

	// initially clear items so they can be set as necessary later.
	STAT(OBJECTIVE_STATUS, player) &= ~(CTF_RED_FLAG_CARRYING		| CTF_RED_FLAG_TAKEN		| CTF_RED_FLAG_LOST
						   | CTF_BLUE_FLAG_CARRYING		| CTF_BLUE_FLAG_TAKEN		| CTF_BLUE_FLAG_LOST
						   | CTF_YELLOW_FLAG_CARRYING	| CTF_YELLOW_FLAG_TAKEN 	| CTF_YELLOW_FLAG_LOST
						   | CTF_PINK_FLAG_CARRYING 	| CTF_PINK_FLAG_TAKEN		| CTF_PINK_FLAG_LOST
						   | CTF_NEUTRAL_FLAG_CARRYING	| CTF_NEUTRAL_FLAG_TAKEN	| CTF_NEUTRAL_FLAG_LOST
						   | CTF_FLAG_NEUTRAL | CTF_SHIELDED | CTF_STALEMATE);

	// scan through all the flags and notify the client about them
	for(entity flag = ctf_worldflaglist; flag; flag = flag.ctf_worldflagnext)
	{
		if(flag.team == NUM_TEAM_1 && !b1) { b1 = true; t = CTF_RED_FLAG_CARRYING;		t2 = CTF_RED_FLAG_TAKEN;		t3 = CTF_RED_FLAG_LOST; }
		if(flag.team == NUM_TEAM_2 && !b2) { b2 = true; t = CTF_BLUE_FLAG_CARRYING;		t2 = CTF_BLUE_FLAG_TAKEN;		t3 = CTF_BLUE_FLAG_LOST; }
		if(flag.team == NUM_TEAM_3 && !b3) { b3 = true; t = CTF_YELLOW_FLAG_CARRYING; 	t2 = CTF_YELLOW_FLAG_TAKEN;		t3 = CTF_YELLOW_FLAG_LOST; }
		if(flag.team == NUM_TEAM_4 && !b4) { b4 = true; t = CTF_PINK_FLAG_CARRYING;		t2 = CTF_PINK_FLAG_TAKEN;		t3 = CTF_PINK_FLAG_LOST; }
		if(flag.team == 0 && !b5) 		   { b5 = true; t = CTF_NEUTRAL_FLAG_CARRYING;	t2 = CTF_NEUTRAL_FLAG_TAKEN;	t3 = CTF_NEUTRAL_FLAG_LOST; STAT(OBJECTIVE_STATUS, player) |= CTF_FLAG_NEUTRAL; }

		switch(flag.ctf_status)
		{
			case FLAG_PASSING:
			case FLAG_CARRY:
			{
				if((flag.owner == player) || (flag.pass_sender == player))
					STAT(OBJECTIVE_STATUS, player) |= t; // carrying: player is currently carrying the flag
				else
					STAT(OBJECTIVE_STATUS, player) |= t2; // taken: someone else is carrying the flag
				break;
			}
			case FLAG_DROPPED:
			{
				STAT(OBJECTIVE_STATUS, player) |= t3; // lost: the flag is dropped somewhere on the map
				break;
			}
		}
	}

	// item for stopping players from capturing the flag too often
	if(player.ctf_captureshielded)
		STAT(OBJECTIVE_STATUS, player) |= CTF_SHIELDED;

	if(ctf_stalemate)
		STAT(OBJECTIVE_STATUS, player) |= CTF_STALEMATE;

	// update the health of the flag carrier waypointsprite
	if(player.wps_flagcarrier)
		WaypointSprite_UpdateHealth(player.wps_flagcarrier, healtharmor_maxdamage(GetResource(player, RES_HEALTH), GetResource(player, RES_ARMOR), autocvar_g_balance_armor_blockpercent, DEATH_WEAPON.m_id).x);
}

MUTATOR_HOOKFUNCTION(ctf, Damage_Calculate) // for changing damage and force values that are applied to players in damage.qc
{
	entity frag_attacker = M_ARGV(1, entity);
	entity frag_target = M_ARGV(2, entity);
	float frag_damage = M_ARGV(4, float);
	vector frag_force = M_ARGV(6, vector);

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

		M_ARGV(4, float) = frag_damage;
		M_ARGV(6, vector) = frag_force;
	}
	else if(frag_target.flagcarried && !IS_DEAD(frag_target) && CTF_DIFFTEAM(frag_target, frag_attacker)) // if the target is a flagcarrier
	{
		if(autocvar_g_ctf_flagcarrier_auto_helpme_damage > healtharmor_maxdamage(GetResource(frag_target, RES_HEALTH), GetResource(frag_target, RES_ARMOR), autocvar_g_balance_armor_blockpercent, DEATH_WEAPON.m_id).x
			&& time > frag_target.wps_helpme_time + autocvar_g_ctf_flagcarrier_auto_helpme_time)
		{
			frag_target.wps_helpme_time = time;
			WaypointSprite_HelpMePing(frag_target.wps_flagcarrier);
		}
		// todo: add notification for when flag carrier needs help?
	}
}

MUTATOR_HOOKFUNCTION(ctf, PlayerDies)
{
	entity frag_attacker = M_ARGV(1, entity);
	entity frag_target = M_ARGV(2, entity);

	if((frag_attacker != frag_target) && (IS_PLAYER(frag_attacker)) && (frag_target.flagcarried))
	{
		GameRules_scoring_add_team(frag_attacker, SCORE, ((SAME_TEAM(frag_attacker, frag_target)) ? -autocvar_g_ctf_score_kill : autocvar_g_ctf_score_kill));
		GameRules_scoring_add(frag_attacker, CTF_FCKILLS, 1);
	}

	if(frag_target.flagcarried)
	{
		entity tmp_entity = frag_target.flagcarried;
		ctf_Handle_Throw(frag_target, NULL, DROP_NORMAL);
		tmp_entity.ctf_dropper = NULL;
	}
}

MUTATOR_HOOKFUNCTION(ctf, GiveFragsForKill)
{
	M_ARGV(2, float) = 0; // frag score
	return (autocvar_g_ctf_ignore_frags); // no frags counted in ctf if this is true
}

void ctf_RemovePlayer(entity player)
{
	if(player.flagcarried)
		{ ctf_Handle_Throw(player, NULL, DROP_NORMAL); }

	for(entity flag = ctf_worldflaglist; flag; flag = flag.ctf_worldflagnext)
	{
		if(flag.pass_sender == player) { flag.pass_sender = NULL; }
		if(flag.pass_target == player) { flag.pass_target = NULL; }
		if(flag.ctf_dropper == player) { flag.ctf_dropper = NULL; }
	}
}

MUTATOR_HOOKFUNCTION(ctf, MakePlayerObserver)
{
	entity player = M_ARGV(0, entity);

	ctf_RemovePlayer(player);
}

MUTATOR_HOOKFUNCTION(ctf, ClientDisconnect)
{
	entity player = M_ARGV(0, entity);

	ctf_RemovePlayer(player);
}

MUTATOR_HOOKFUNCTION(ctf, ClientConnect)
{
	if(!autocvar_g_ctf_leaderboard)
		return;

	entity player = M_ARGV(0, entity);

	race_SendAll(player, true);
}

MUTATOR_HOOKFUNCTION(ctf, GetPressedKeys)
{
	if(!autocvar_g_ctf_leaderboard)
		return;

	entity player = M_ARGV(0, entity);

	race_checkAndWriteName(player);
}

MUTATOR_HOOKFUNCTION(ctf, PortalTeleport)
{
	entity player = M_ARGV(0, entity);

	if(player.flagcarried)
	if(!autocvar_g_ctf_portalteleport)
		{ ctf_Handle_Throw(player, NULL, DROP_NORMAL); }
}

MUTATOR_HOOKFUNCTION(ctf, PlayerUseKey)
{
	if(MUTATOR_RETURNVALUE || game_stopped) return;

	entity player = M_ARGV(0, entity);

	if((time > player.throw_antispam) && !IS_DEAD(player) && !player.speedrunning && (!player.vehicle || autocvar_g_ctf_allow_vehicle_touch))
	{
		// pass the flag to a teammate
		if(autocvar_g_ctf_pass)
		{
			entity head, closest_target = NULL;
			head = WarpZone_FindRadius(player.origin, autocvar_g_ctf_pass_radius, true);

			while(head) // find the closest acceptable target to pass to
			{
				if(IS_PLAYER(head) && !IS_DEAD(head) && !IS_INDEPENDENT_PLAYER(head))
				if(head != player && SAME_TEAM(head, player))
				if(!head.speedrunning && !head.vehicle)
				{
					// if it's a player, use the view origin as reference (stolen from RadiusDamage functions in damage.qc)
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
						else if(player.flagcarried && !head.flagcarried)
						{
							if(closest_target)
							{
								vector closest_target_center = WarpZone_UnTransformOrigin(closest_target, CENTER_OR_VIEWOFS(closest_target));
								if(vlen2(passer_center - head_center) < vlen2(passer_center - closest_target_center))
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
					ctf_Handle_Throw(player, NULL, DROP_THROW);
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
				ctf_Handle_Throw(player, NULL, DROP_THROW);
				return true;
			}
		}
	}
}

MUTATOR_HOOKFUNCTION(ctf, HelpMePing)
{
	entity player = M_ARGV(0, entity);

	if(player.wps_flagcarrier) // update the flagcarrier waypointsprite with "NEEDING HELP" notification
	{
		player.wps_helpme_time = time;
		WaypointSprite_HelpMePing(player.wps_flagcarrier);
	}
	else // create a normal help me waypointsprite
	{
		WaypointSprite_Spawn(WP_Helpme, waypointsprite_deployed_lifetime, waypointsprite_limitedrange, player, FLAG_WAYPOINT_OFFSET, NULL, player.team, player, wps_helpme, false, RADARICON_HELPME);
		WaypointSprite_Ping(player.wps_helpme);
	}

	return true;
}

MUTATOR_HOOKFUNCTION(ctf, VehicleEnter)
{
	entity player = M_ARGV(0, entity);
	entity veh = M_ARGV(1, entity);

	if(player.flagcarried)
	{
		if(!autocvar_g_ctf_allow_vehicle_carry && !autocvar_g_ctf_allow_vehicle_touch)
		{
			ctf_Handle_Throw(player, NULL, DROP_NORMAL);
		}
		else
		{
			player.flagcarried.nodrawtoclient = player; // hide the flag from the driver
			setattachment(player.flagcarried, veh, "");
			setorigin(player.flagcarried, VEHICLE_FLAG_OFFSET);
			player.flagcarried.scale = VEHICLE_FLAG_SCALE;
			//player.flagcarried.angles = '0 0 0';
		}
		return true;
	}
}

MUTATOR_HOOKFUNCTION(ctf, VehicleExit)
{
	entity player = M_ARGV(0, entity);

	if(player.flagcarried)
	{
		setattachment(player.flagcarried, player, "");
		setorigin(player.flagcarried, FLAG_CARRY_OFFSET);
		player.flagcarried.scale = FLAG_SCALE;
		player.flagcarried.angles = '0 0 0';
		player.flagcarried.nodrawtoclient = NULL;
		return true;
	}
}

MUTATOR_HOOKFUNCTION(ctf, AbortSpeedrun)
{
	entity player = M_ARGV(0, entity);

	if(player.flagcarried)
	{
		Send_Notification(NOTIF_ALL, NULL, MSG_INFO, APP_NUM(player.flagcarried.team, INFO_CTF_FLAGRETURN_ABORTRUN));
		ctf_RespawnFlag(player.flagcarried);
		return true;
	}
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
				set_movetype(flag, MOVETYPE_NONE);
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
}

MUTATOR_HOOKFUNCTION(ctf, HavocBot_ChooseRole)
{
	entity bot = M_ARGV(0, entity);

	havocbot_ctf_reset_role(bot);
	return true;
}

MUTATOR_HOOKFUNCTION(ctf, TeamBalance_CheckAllowedTeams)
{
	M_ARGV(1, string) = "ctf_team";
}

MUTATOR_HOOKFUNCTION(ctf, GetRecords)
{
	int record_page = M_ARGV(0, int);
	string ret_string = M_ARGV(1, string);

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

	M_ARGV(1, string) = ret_string;
}

bool superspec_Spectate(entity this, entity targ); // TODO
void superspec_msg(string _center_title, string _con_title, entity _to, string _msg, float _spamlevel); // TODO
MUTATOR_HOOKFUNCTION(ctf, SV_ParseClientCommand)
{
	entity player = M_ARGV(0, entity);
	string cmd_name = M_ARGV(1, string);
	int cmd_argc = M_ARGV(2, int);

	if(IS_PLAYER(player) || MUTATOR_RETURNVALUE || !cvar("g_superspectate")) { return false; }

	if(cmd_name == "followfc")
	{
		if(!g_ctf)
			return true;

		int _team = 0;
		bool found = false;

		if(cmd_argc == 2)
		{
			switch(argv(1))
			{
				case "red":    if(ctf_teams & BIT(0)) _team = NUM_TEAM_1; break;
				case "blue":   if(ctf_teams & BIT(1)) _team = NUM_TEAM_2; break;
				case "yellow": if(ctf_teams & BIT(2)) _team = NUM_TEAM_3; break;
				case "pink":   if(ctf_teams & BIT(3)) _team = NUM_TEAM_4; break;
			}
		}

		FOREACH_CLIENT(IS_PLAYER(it), {
			if(it.flagcarried && (it.team == _team || _team == 0))
			{
				found = true;
				if(_team == 0 && IS_SPEC(player) && player.enemy == it)
					continue; // already spectating this fc, try another
				return superspec_Spectate(player, it);
			}
		});

		if(!found)
			superspec_msg("", "", player, "No active flag carrier\n", 1);
		return true;
	}
}

MUTATOR_HOOKFUNCTION(ctf, DropSpecialItems)
{
	entity frag_target = M_ARGV(0, entity);

	if(frag_target.flagcarried)
		ctf_Handle_Throw(frag_target, NULL, DROP_THROW);
}

MUTATOR_HOOKFUNCTION(ctf, LogDeath_AppendItemCodes)
{
	entity player = M_ARGV(0, entity);
	if(player.flagcarried)
		M_ARGV(1, string) = strcat(M_ARGV(1, string), "F"); // item codes
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
	if(!g_ctf) { delete(this); return; }

	ctf_FlagSetup(NUM_TEAM_1, this);
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
	if(!g_ctf) { delete(this); return; }

	ctf_FlagSetup(NUM_TEAM_2, this);
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
	if(!g_ctf) { delete(this); return; }

	ctf_FlagSetup(NUM_TEAM_3, this);
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
	if(!g_ctf) { delete(this); return; }

	ctf_FlagSetup(NUM_TEAM_4, this);
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
	if(!g_ctf) { delete(this); return; }
	if(!cvar("g_ctf_oneflag")) { delete(this); return; }

	ctf_FlagSetup(0, this);
}

/*QUAKED spawnfunc_ctf_team (0 .5 .8) (-16 -16 -24) (16 16 32)
Team declaration for CTF gameplay, this allows you to decide what team names and control point models are used in your map.
Note: If you use spawnfunc_ctf_team entities you must define at least 2!  However, unlike domination, you don't need to make a blank one too.
Keys:
"netname" Name of the team (for example Red, Blue, Green, Yellow, Life, Death, Offense, Defense, etc)...
"cnt" Scoreboard color of the team (for example 4 is red and 13 is blue)... */
spawnfunc(ctf_team)
{
	if(!g_ctf) { delete(this); return; }

	this.team = this.cnt + 1;
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

spawnfunc(team_CTF_neutralflag)	{ spawnfunc_item_flag_neutral(this);  }
spawnfunc(team_neutralobelisk)	{ spawnfunc_item_flag_neutral(this);  }

// compatibility for wop maps
spawnfunc(team_redplayer)      { spawnfunc_info_player_team1(this);  }
spawnfunc(team_blueplayer)     { spawnfunc_info_player_team2(this);  }
spawnfunc(team_ctl_redlolly)   { spawnfunc_item_flag_team1(this);    }
spawnfunc(team_CTL_redlolly)   { spawnfunc_item_flag_team1(this);    }
spawnfunc(team_ctl_bluelolly)  { spawnfunc_item_flag_team2(this);    }
spawnfunc(team_CTL_bluelolly)  { spawnfunc_item_flag_team2(this);    }


// ==============
// Initialization
// ==============

// scoreboard setup
void ctf_ScoreRules(int teams)
{
	GameRules_scoring(teams, SFL_SORT_PRIO_PRIMARY, 0, {
        field_team(ST_CTF_CAPS, "caps", SFL_SORT_PRIO_PRIMARY);
        field(SP_CTF_CAPS, "caps", SFL_SORT_PRIO_SECONDARY);
        field(SP_CTF_CAPTIME, "captime", SFL_LOWER_IS_BETTER | SFL_TIME);
        field(SP_CTF_PICKUPS, "pickups", 0);
        field(SP_CTF_FCKILLS, "fckills", 0);
        field(SP_CTF_RETURNS, "returns", 0);
        field(SP_CTF_DROPS, "drops", SFL_LOWER_IS_BETTER);
	});
}

// code from here on is just to support maps that don't have flag and team entities
void ctf_SpawnTeam (string teamname, int teamcolor)
{
	entity this = new_pure(ctf_team);
	this.netname = teamname;
	this.cnt = teamcolor - 1;
	this.spawnfunc_checked = true;
	this.team = teamcolor;
}

void ctf_DelayedInit(entity this) // Do this check with a delay so we can wait for teams to be set up.
{
	ctf_teams = 0;

	entity tmp_entity;
	for(tmp_entity = ctf_worldflaglist; tmp_entity; tmp_entity = tmp_entity.ctf_worldflagnext)
	{
		//if(tmp_entity.team == NUM_TEAM_3) { ctf_teams = max(3, ctf_teams); }
		//if(tmp_entity.team == NUM_TEAM_4) { ctf_teams = max(4, ctf_teams); }

		switch(tmp_entity.team)
		{
			case NUM_TEAM_1: BITSET_ASSIGN(ctf_teams, BIT(0)); break;
			case NUM_TEAM_2: BITSET_ASSIGN(ctf_teams, BIT(1)); break;
			case NUM_TEAM_3: BITSET_ASSIGN(ctf_teams, BIT(2)); break;
			case NUM_TEAM_4: BITSET_ASSIGN(ctf_teams, BIT(3)); break;
		}
		if(tmp_entity.team == 0) { ctf_oneflag = true; }
	}

	havocbot_ctf_calculate_middlepoint();

	if(NumTeams(ctf_teams) < 2) // somehow, there's not enough flags!
	{
		ctf_teams = 0; // so set the default red and blue teams
		BITSET_ASSIGN(ctf_teams, BIT(0));
		BITSET_ASSIGN(ctf_teams, BIT(1));
	}

	//ctf_teams = bound(2, ctf_teams, 4);

	// if no teams are found, spawn defaults
	if(find(NULL, classname, "ctf_team") == NULL)
	{
		LOG_TRACE("No \"ctf_team\" entities found on this map, creating them anyway.");
		if(ctf_teams & BIT(0))
			ctf_SpawnTeam("Red", NUM_TEAM_1);
		if(ctf_teams & BIT(1))
			ctf_SpawnTeam("Blue", NUM_TEAM_2);
		if(ctf_teams & BIT(2))
			ctf_SpawnTeam("Yellow", NUM_TEAM_3);
		if(ctf_teams & BIT(3))
			ctf_SpawnTeam("Pink", NUM_TEAM_4);
	}

	ctf_ScoreRules(ctf_teams);
}

void ctf_Initialize()
{
	CTF_FLAG = NEW(Flag);
	record_type = CTF_RECORD;
	ctf_captimerecord = stof(db_get(ServerProgsDB, strcat(GetMapname(), "/captimerecord/time")));

	ctf_captureshield_min_negscore = autocvar_g_ctf_shield_min_negscore;
	ctf_captureshield_max_ratio = autocvar_g_ctf_shield_max_ratio;
	ctf_captureshield_force = autocvar_g_ctf_shield_force;

	InitializeEntity(NULL, ctf_DelayedInit, INITPRIO_GAMETYPE);
}
