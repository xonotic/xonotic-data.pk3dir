#include "physics.qh"
#include "triggers/include.qh"
#include "viewloc.qh"

#ifdef SVQC

#include "../server/miscfunctions.qh"
#include "triggers/trigger/viewloc.qh"

// client side physics
bool Physics_Valid(string thecvar)
{
	return autocvar_g_physics_clientselect && strhasword(autocvar_g_physics_clientselect_options, thecvar);
}

float Physics_ClientOption(entity this, string option)
{
	if(Physics_Valid(this.cvar_cl_physics))
	{
		string s = sprintf("g_physics_%s_%s", this.cvar_cl_physics, option);
		if(cvar_type(s) & CVAR_TYPEFLAG_EXISTS)
			return cvar(s);
	}
	if(autocvar_g_physics_clientselect && autocvar_g_physics_clientselect_default)
	{
		string s = sprintf("g_physics_%s_%s", autocvar_g_physics_clientselect_default, option);
		if(cvar_type(s) & CVAR_TYPEFLAG_EXISTS)
			return cvar(s);
	}
	return cvar(strcat("sv_", option));
}

void Physics_UpdateStats(entity this, float maxspd_mod)
{
	STAT(MOVEVARS_AIRACCEL_QW, this) = AdjustAirAccelQW(Physics_ClientOption(this, "airaccel_qw"), maxspd_mod);
	STAT(MOVEVARS_AIRSTRAFEACCEL_QW, this) = (Physics_ClientOption(this, "airstrafeaccel_qw"))
		? AdjustAirAccelQW(Physics_ClientOption(this, "airstrafeaccel_qw"), maxspd_mod)
		: 0;
	STAT(MOVEVARS_AIRSPEEDLIMIT_NONQW, this) = Physics_ClientOption(this, "airspeedlimit_nonqw") * maxspd_mod;
	STAT(MOVEVARS_MAXSPEED, this) = Physics_ClientOption(this, "maxspeed") * maxspd_mod; // also slow walking

	// old stats
	// fix some new settings
	STAT(MOVEVARS_AIRACCEL_QW_STRETCHFACTOR, this) = Physics_ClientOption(this, "airaccel_qw_stretchfactor");
	STAT(MOVEVARS_MAXAIRSTRAFESPEED, this) = Physics_ClientOption(this, "maxairstrafespeed");
	STAT(MOVEVARS_MAXAIRSPEED, this) = Physics_ClientOption(this, "maxairspeed");
	STAT(MOVEVARS_AIRSTRAFEACCELERATE, this) = Physics_ClientOption(this, "airstrafeaccelerate");
	STAT(MOVEVARS_WARSOWBUNNY_TURNACCEL, this) = Physics_ClientOption(this, "warsowbunny_turnaccel");
	STAT(MOVEVARS_AIRACCEL_SIDEWAYS_FRICTION, this) = Physics_ClientOption(this, "airaccel_sideways_friction");
	STAT(MOVEVARS_AIRCONTROL, this) = Physics_ClientOption(this, "aircontrol");
	STAT(MOVEVARS_AIRCONTROL_POWER, this) = Physics_ClientOption(this, "aircontrol_power");
	STAT(MOVEVARS_AIRCONTROL_PENALTY, this) = Physics_ClientOption(this, "aircontrol_penalty");
	STAT(MOVEVARS_WARSOWBUNNY_AIRFORWARDACCEL, this) = Physics_ClientOption(this, "warsowbunny_airforwardaccel");
	STAT(MOVEVARS_WARSOWBUNNY_TOPSPEED, this) = Physics_ClientOption(this, "warsowbunny_topspeed");
	STAT(MOVEVARS_WARSOWBUNNY_ACCEL, this) = Physics_ClientOption(this, "warsowbunny_accel");
	STAT(MOVEVARS_WARSOWBUNNY_BACKTOSIDERATIO, this) = Physics_ClientOption(this, "warsowbunny_backtosideratio");
	STAT(MOVEVARS_FRICTION, this) = Physics_ClientOption(this, "friction");
	STAT(MOVEVARS_ACCELERATE, this) = Physics_ClientOption(this, "accelerate");
	STAT(MOVEVARS_STOPSPEED, this) = Physics_ClientOption(this, "stopspeed");
	STAT(MOVEVARS_AIRACCELERATE, this) = Physics_ClientOption(this, "airaccelerate");
	STAT(MOVEVARS_AIRSTOPACCELERATE, this) = Physics_ClientOption(this, "airstopaccelerate");
	STAT(MOVEVARS_JUMPVELOCITY, this) = Physics_ClientOption(this, "jumpvelocity");
	STAT(MOVEVARS_TRACK_CANJUMP, this) = Physics_ClientOption(this, "track_canjump");
}
#endif

float IsMoveInDirection(vector mv, float ang) // key mix factor
{
	if (mv_x == 0 && mv_y == 0)
		return 0; // avoid division by zero
	ang -= RAD2DEG * atan2(mv_y, mv_x);
	ang = remainder(ang, 360) / 45;
	return ang > 1 ? 0 : ang < -1 ? 0 : 1 - fabs(ang);
}

float GeomLerp(float a, float lerp, float b)
{
	return a == 0 ? (lerp < 1 ? 0 : b)
		: b == 0 ? (lerp > 0 ? 0 : a)
		: a * pow(fabs(b / a), lerp);
}

#define unstick_offsets(X) \
/* 1 no nudge (just return the original if this test passes) */ \
	X(' 0.000  0.000  0.000') \
/* 6 simple nudges */ \
	X(' 0.000  0.000  0.125') X('0.000  0.000 -0.125') \
	X('-0.125  0.000  0.000') X('0.125  0.000  0.000') \
	X(' 0.000 -0.125  0.000') X('0.000  0.125  0.000') \
/* 4 diagonal flat nudges */ \
	X('-0.125 -0.125  0.000') X('0.125 -0.125  0.000') \
	X('-0.125  0.125  0.000') X('0.125  0.125  0.000') \
/* 8 diagonal upward nudges */ \
	X('-0.125  0.000  0.125') X('0.125  0.000  0.125') \
	X(' 0.000 -0.125  0.125') X('0.000  0.125  0.125') \
	X('-0.125 -0.125  0.125') X('0.125 -0.125  0.125') \
	X('-0.125  0.125  0.125') X('0.125  0.125  0.125') \
/* 8 diagonal downward nudges */ \
	X('-0.125  0.000 -0.125') X('0.125  0.000 -0.125') \
	X(' 0.000 -0.125 -0.125') X('0.000  0.125 -0.125') \
	X('-0.125 -0.125 -0.125') X('0.125 -0.125 -0.125') \
	X('-0.125  0.125 -0.125') X('0.125  0.125 -0.125') \
/**/

void PM_ClientMovement_Unstick(entity this)
{
	#define X(unstick_offset) \
	{ \
		vector neworigin = unstick_offset + this.origin; \
		tracebox(neworigin, PL_CROUCH_MIN, PL_CROUCH_MAX, neworigin, MOVE_NORMAL, this); \
		if (!trace_startsolid) \
		{ \
			setorigin(this, neworigin); \
			return; \
		} \
	}
	unstick_offsets(X);
	#undef X
}

void PM_ClientMovement_UpdateStatus(entity this, bool ground)
{
#ifdef CSQC
	if(!IS_PLAYER(this))
		return;
	// make sure player is not stuck
	if(autocvar_cl_movement == 3)
		PM_ClientMovement_Unstick(this);

	// set crouched
	if (PHYS_INPUT_BUTTON_CROUCH(this))
	{
		// wants to crouch, this always works
		if (!IS_DUCKED(this)) SET_DUCKED(this);
	}
	else
	{
		// wants to stand, if currently crouching we need to check for a low ceiling first
		if (IS_DUCKED(this))
		{
			tracebox(this.origin, PL_MIN, PL_MAX, this.origin, MOVE_NORMAL, this);
			if (!trace_startsolid) UNSET_DUCKED(this);
		}
	}

	// set onground
	vector origin1 = this.origin + '0 0 1';
	vector origin2 = this.origin - '0 0 1';

	if (ground && autocvar_cl_movement == 3)
	{
		tracebox(origin1, this.mins, this.maxs, origin2, MOVE_NORMAL, this);
		if (trace_fraction < 1.0 && trace_plane_normal.z > 0.7)
		{
			SET_ONGROUND(this);

			// this code actually "predicts" an impact; so let's clip velocity first
			this.velocity -= this.velocity * trace_plane_normal * trace_plane_normal;
		}
		else
			UNSET_ONGROUND(this);
	}

	if(autocvar_cl_movement == 3)
	{
		// set watertype/waterlevel
		origin1 = this.origin;
		origin1.z += this.mins_z + 1;
		this.waterlevel = WATERLEVEL_NONE;

		int thepoint = pointcontents(origin1);

		this.watertype = (thepoint == CONTENT_WATER || thepoint == CONTENT_LAVA || thepoint == CONTENT_SLIME);

		if (this.watertype)
		{
			this.waterlevel = WATERLEVEL_WETFEET;
			origin1.z = this.origin.z + (this.mins.z + this.maxs.z) * 0.5;
			thepoint = pointcontents(origin1);
			if (thepoint == CONTENT_WATER || thepoint == CONTENT_LAVA || thepoint == CONTENT_SLIME)
			{
				this.waterlevel = WATERLEVEL_SWIMMING;
				origin1.z = this.origin.z + 22;
				thepoint = pointcontents(origin1);
				if (thepoint == CONTENT_WATER || thepoint == CONTENT_LAVA || thepoint == CONTENT_SLIME)
					this.waterlevel = WATERLEVEL_SUBMERGED;
			}
		}
	}

	if (IS_ONGROUND(this) || this.velocity.z <= 0 || pmove_waterjumptime <= 0)
		pmove_waterjumptime = 0;
#endif
}

void PM_ClientMovement_Move(entity this)
{
#ifdef CSQC

	PM_ClientMovement_UpdateStatus(this, false);
	if(autocvar_cl_movement == 1)
		return;

	int bump;
	float t;
	float f;
	vector neworigin;
	vector currentorigin2;
	vector neworigin2;
	vector primalvelocity;

	vector trace1_endpos = '0 0 0';
	vector trace2_endpos = '0 0 0';
	vector trace3_endpos = '0 0 0';
	float trace1_fraction = 0;
	float trace2_fraction = 0;
	float trace3_fraction = 0;
	vector trace1_plane_normal = '0 0 0';
	vector trace2_plane_normal = '0 0 0';
	vector trace3_plane_normal = '0 0 0';

	primalvelocity = this.velocity;
	for(bump = 0, t = PHYS_INPUT_TIMELENGTH; bump < 8 && (this.velocity * this.velocity) > 0; bump++)
	{
		neworigin = this.origin + t * this.velocity;
		tracebox(this.origin, this.mins, this.maxs, neworigin, MOVE_NORMAL, this);
		trace1_endpos = trace_endpos;
		trace1_fraction = trace_fraction;
		trace1_plane_normal = trace_plane_normal;
		if(trace1_fraction < 1 && trace1_plane_normal_z == 0)
		{
			// may be a step or wall, try stepping up
			// first move forward at a higher level
			currentorigin2 = this.origin;
			currentorigin2_z += PHYS_STEPHEIGHT(this);
			neworigin2 = neworigin;
			neworigin2_z += PHYS_STEPHEIGHT(this);
			tracebox(currentorigin2, this.mins, this.maxs, neworigin2, MOVE_NORMAL, this);
			trace2_endpos = trace_endpos;
			trace2_fraction = trace_fraction;
			trace2_plane_normal = trace_plane_normal;
			if(!trace_startsolid)
			{
				// then move down from there
				currentorigin2 = trace2_endpos;
				neworigin2 = trace2_endpos;
				neworigin2_z = this.origin_z;
				tracebox(currentorigin2, this.mins, this.maxs, neworigin2, MOVE_NORMAL, this);
				trace3_endpos = trace_endpos;
				trace3_fraction = trace_fraction;
				trace3_plane_normal = trace_plane_normal;
				// accept the new trace if it made some progress
				if(fabs(trace3_endpos_x - trace1_endpos_x) >= 0.03125 || fabs(trace3_endpos_y - trace1_endpos_y) >= 0.03125)
				{
					trace1_endpos = trace2_endpos;
					trace1_fraction = trace2_fraction;
					trace1_plane_normal = trace2_plane_normal;
					trace1_endpos = trace3_endpos;
				}
			}
		}

		// check if it moved at all
		if(trace1_fraction >= 0.001)
			setorigin(this, trace1_endpos);

		// check if it moved all the way
		if(trace1_fraction == 1)
			break;

		// this is only really needed for nogravityonground combined with gravityunaffectedbyticrate
		// <LordHavoc> I'm pretty sure I commented it out solely because it seemed redundant
		// this got commented out in a change that supposedly makes the code match QW better
		// so if this is broken, maybe put it in an if(cls.protocol != PROTOCOL_QUAKEWORLD) block
		if(trace1_plane_normal_z > 0.7)
			SET_ONGROUND(this);

		t -= t * trace1_fraction;

		f = (this.velocity * trace1_plane_normal);
		this.velocity = this.velocity + -f * trace1_plane_normal;
	}
	if(PHYS_TELEPORT_TIME(this) > 0)
		this.velocity = primalvelocity;
#endif
}

void CPM_PM_Aircontrol(entity this, vector wishdir, float wishspeed)
{
	float k = 32 * (2 * IsMoveInDirection(this.movement, 0) - 1);
	if (k <= 0)
		return;

	k *= bound(0, wishspeed / PHYS_MAXAIRSPEED(this), 1);

	float zspeed = this.velocity_z;
	this.velocity_z = 0;
	float xyspeed = vlen(this.velocity);
	this.velocity = normalize(this.velocity);

	float dot = this.velocity * wishdir;

	if (dot > 0) // we can't change direction while slowing down
	{
		k *= pow(dot, PHYS_AIRCONTROL_POWER(this)) * PHYS_INPUT_TIMELENGTH;
		xyspeed = max(0, xyspeed - PHYS_AIRCONTROL_PENALTY(this) * sqrt(max(0, 1 - dot*dot)) * k/32);
		k *= PHYS_AIRCONTROL(this);
		this.velocity = normalize(this.velocity * xyspeed + wishdir * k);
	}

	this.velocity = this.velocity * xyspeed;
	this.velocity_z = zspeed;
}

float AdjustAirAccelQW(float accelqw, float factor)
{
	return copysign(bound(0.000001, 1 - (1 - fabs(accelqw)) * factor, 1), accelqw);
}

// example config for alternate speed clamping:
//   sv_airaccel_qw 0.8
//   sv_airaccel_sideways_friction 0
//   prvm_globalset server speedclamp_mode 1
//     (or 2)
void PM_Accelerate(entity this, vector wishdir, float wishspeed, float wishspeed0, float accel, float accelqw, float stretchfactor, float sidefric, float speedlimit)
{
	float speedclamp = stretchfactor > 0 ? stretchfactor
	: accelqw < 0 ? 1 // full clamping, no stretch
	: -1; // no clamping

	accelqw = fabs(accelqw);

	if (GAMEPLAYFIX_Q2AIRACCELERATE)
		wishspeed0 = wishspeed; // don't need to emulate this Q1 bug

	float vel_straight = this.velocity * wishdir;
	float vel_z = this.velocity_z;
	vector vel_xy = vec2(this.velocity);
	vector vel_perpend = vel_xy - vel_straight * wishdir;

	float step = accel * PHYS_INPUT_TIMELENGTH * wishspeed0;

	float vel_xy_current  = vlen(vel_xy);
	if (speedlimit)
		accelqw = AdjustAirAccelQW(accelqw, (speedlimit - bound(wishspeed, vel_xy_current, speedlimit)) / max(1, speedlimit - wishspeed));
	float vel_xy_forward =  vel_xy_current  + bound(0, wishspeed - vel_xy_current, step) * accelqw + step * (1 - accelqw);
	float vel_xy_backward = vel_xy_current  - bound(0, wishspeed + vel_xy_current, step) * accelqw - step * (1 - accelqw);
	vel_xy_backward = max(0, vel_xy_backward); // not that it REALLY occurs that this would cause wrong behaviour afterwards
	vel_straight =          vel_straight    + bound(0, wishspeed - vel_straight,   step) * accelqw + step * (1 - accelqw);

	if (sidefric < 0 && (vel_perpend*vel_perpend))
		// negative: only apply so much sideways friction to stay below the speed you could get by "braking"
	{
		float f = max(0, 1 + PHYS_INPUT_TIMELENGTH * wishspeed * sidefric);
		float themin = (vel_xy_backward * vel_xy_backward - vel_straight * vel_straight) / (vel_perpend * vel_perpend);
		// assume: themin > 1
		// vel_xy_backward*vel_xy_backward - vel_straight*vel_straight > vel_perpend*vel_perpend
		// vel_xy_backward*vel_xy_backward > vel_straight*vel_straight + vel_perpend*vel_perpend
		// vel_xy_backward*vel_xy_backward > vel_xy * vel_xy
		// obviously, this cannot be
		if (themin <= 0)
			vel_perpend *= f;
		else
		{
			themin = sqrt(themin);
			vel_perpend *= max(themin, f);
		}
	}
	else
		vel_perpend *= max(0, 1 - PHYS_INPUT_TIMELENGTH * wishspeed * sidefric);

	vel_xy = vel_straight * wishdir + vel_perpend;

	if (speedclamp >= 0)
	{
		float vel_xy_preclamp;
		vel_xy_preclamp = vlen(vel_xy);
		if (vel_xy_preclamp > 0) // prevent division by zero
		{
			vel_xy_current += (vel_xy_forward - vel_xy_current) * speedclamp;
			if (vel_xy_current < vel_xy_preclamp)
				vel_xy *= (vel_xy_current / vel_xy_preclamp);
		}
	}

	this.velocity = vel_xy + vel_z * '0 0 1';
}

void PM_AirAccelerate(entity this, vector wishdir, float wishspeed)
{
	if (wishspeed == 0)
		return;

	vector curvel = this.velocity;
	curvel_z = 0;
	float curspeed = vlen(curvel);

	if (wishspeed > curspeed * 1.01)
		wishspeed = min(wishspeed, curspeed + PHYS_WARSOWBUNNY_AIRFORWARDACCEL(this) * PHYS_MAXSPEED(this) * PHYS_INPUT_TIMELENGTH);
	else
	{
		float f = max(0, (PHYS_WARSOWBUNNY_TOPSPEED(this) - curspeed) / (PHYS_WARSOWBUNNY_TOPSPEED(this) - PHYS_MAXSPEED(this)));
		wishspeed = max(curspeed, PHYS_MAXSPEED(this)) + PHYS_WARSOWBUNNY_ACCEL(this) * f * PHYS_MAXSPEED(this) * PHYS_INPUT_TIMELENGTH;
	}
	vector wishvel = wishdir * wishspeed;
	vector acceldir = wishvel - curvel;
	float addspeed = vlen(acceldir);
	acceldir = normalize(acceldir);

	float accelspeed = min(addspeed, PHYS_WARSOWBUNNY_TURNACCEL(this) * PHYS_MAXSPEED(this) * PHYS_INPUT_TIMELENGTH);

	if (PHYS_WARSOWBUNNY_BACKTOSIDERATIO(this) < 1)
	{
		vector curdir = normalize(curvel);
		float dot = acceldir * curdir;
		if (dot < 0)
			acceldir -= (1 - PHYS_WARSOWBUNNY_BACKTOSIDERATIO(this)) * dot * curdir;
	}

	this.velocity += accelspeed * acceldir;
}


/*
=============
PlayerJump

When you press the jump key
returns true if handled
=============
*/
bool PlayerJump(entity this)
{
	if (PHYS_FROZEN(this))
		return true; // no jumping in freezetag when frozen

#ifdef SVQC
	if (this.player_blocked)
		return true; // no jumping while blocked
#endif

	bool doublejump = false;
	float mjumpheight = PHYS_JUMPVELOCITY(this);

	if (MUTATOR_CALLHOOK(PlayerJump, this, doublejump, mjumpheight))
		return true;

	doublejump = player_multijump;
	mjumpheight = player_jumpheight;

	if (this.waterlevel >= WATERLEVEL_SWIMMING)
	{
		if(this.viewloc)
		{
			doublejump = true;
			mjumpheight *= 0.7;
		}
		else
		{
			this.velocity_z = PHYS_MAXSPEED(this) * 0.7;
			return true;
		}
	}

	if (!doublejump)
		if (!IS_ONGROUND(this))
			return IS_JUMP_HELD(this);

	bool track_jump = PHYS_CL_TRACK_CANJUMP(this);
	if(PHYS_TRACK_CANJUMP(this))
		track_jump = true;

	if (track_jump)
		if (IS_JUMP_HELD(this))
			return true;

	// sv_jumpspeedcap_min/sv_jumpspeedcap_max act as baseline
	// velocity bounds.  Final velocity is bound between (jumpheight *
	// min + jumpheight) and (jumpheight * max + jumpheight);

	if(PHYS_JUMPSPEEDCAP_MIN != "")
	{
		float minjumpspeed = mjumpheight * stof(PHYS_JUMPSPEEDCAP_MIN);

		if (this.velocity_z < minjumpspeed)
			mjumpheight += minjumpspeed - this.velocity_z;
	}

	if(PHYS_JUMPSPEEDCAP_MAX != "")
	{
		// don't do jump speedcaps on ramps to preserve old xonotic ramjump style
		tracebox(this.origin + '0 0 0.01', this.mins, this.maxs, this.origin - '0 0 0.01', MOVE_NORMAL, this);

		if (!(trace_fraction < 1 && trace_plane_normal_z < 0.98 && PHYS_JUMPSPEEDCAP_DISABLE_ONRAMPS(this)))
		{
			float maxjumpspeed = mjumpheight * stof(PHYS_JUMPSPEEDCAP_MAX);

			if (this.velocity_z > maxjumpspeed)
				mjumpheight -= this.velocity_z - maxjumpspeed;
		}
	}

	if (!WAS_ONGROUND(this))
	{
#ifdef SVQC
		if(autocvar_speedmeter)
			LOG_TRACE(strcat("landing velocity: ", vtos(this.velocity), " (abs: ", ftos(vlen(this.velocity)), ")\n"));
#endif
		if(this.lastground < time - 0.3)
		{
			float f = (1 - PHYS_FRICTION_ONLAND(this));
			this.velocity_x *= f;
			this.velocity_y *= f;
		}
#ifdef SVQC
		if(this.jumppadcount > 1)
			LOG_TRACE(strcat(ftos(this.jumppadcount), "x jumppad combo\n"));
		this.jumppadcount = 0;
#endif
	}

	this.velocity_z += mjumpheight;

	UNSET_ONGROUND(this);
	SET_JUMP_HELD(this);

#ifdef SVQC

	this.oldvelocity_z = this.velocity_z;

	animdecide_setaction(this, ANIMACTION_JUMP, true);

	if (autocvar_g_jump_grunt)
		PlayerSound(this, playersound_jump, CH_PLAYER, VOICETYPE_PLAYERSOUND);
#endif
	return true;
}

void CheckWaterJump(entity this)
{
// check for a jump-out-of-water
	makevectors(this.v_angle);
	vector start = this.origin;
	start_z += 8;
	v_forward_z = 0;
	normalize(v_forward);
	vector end = start + v_forward*24;
	traceline (start, end, true, this);
	if (trace_fraction < 1)
	{	// solid at waist
		start_z = start_z + this.maxs_z - 8;
		end = start + v_forward*24;
		this.movedir = trace_plane_normal * -50;
		traceline(start, end, true, this);
		if (trace_fraction == 1)
		{	// open at eye level
			this.velocity_z = 225;
			this.flags |= FL_WATERJUMP;
			SET_JUMP_HELD(this);
		#ifdef SVQC
			PHYS_TELEPORT_TIME(this) = time + 2;	// safety net
		#elif defined(CSQC)
			pmove_waterjumptime = time + 2;
		#endif
		}
	}
}


#ifdef SVQC
	#define JETPACK_JUMP(s)	s.cvar_cl_jetpack_jump
#elif defined(CSQC)
	float autocvar_cl_jetpack_jump;
	#define JETPACK_JUMP(s)	autocvar_cl_jetpack_jump
#endif
.float jetpack_stopped;
void CheckPlayerJump(entity this)
{
#ifdef SVQC
	float was_flying = ITEMS_STAT(this) & IT_USING_JETPACK;
#endif
	if (JETPACK_JUMP(this) < 2)
		ITEMS_STAT(this) &= ~IT_USING_JETPACK;

	if(PHYS_INPUT_BUTTON_JUMP(this) || PHYS_INPUT_BUTTON_JETPACK(this))
	{
		float air_jump = !PlayerJump(this) || player_multijump; // PlayerJump() has important side effects
		float activate = JETPACK_JUMP(this) && air_jump && PHYS_INPUT_BUTTON_JUMP(this) || PHYS_INPUT_BUTTON_JETPACK(this);
		float has_fuel = !PHYS_JETPACK_FUEL(this) || PHYS_AMMO_FUEL(this) || ITEMS_STAT(this) & IT_UNLIMITED_WEAPON_AMMO;

		if (!(ITEMS_STAT(this) & ITEM_Jetpack.m_itemid)) { }
		else if (this.jetpack_stopped) { }
		else if (!has_fuel)
		{
#ifdef SVQC
			if (was_flying) // TODO: ran out of fuel message
				Send_Notification(NOTIF_ONE, this, MSG_INFO, INFO_JETPACK_NOFUEL);
			else if (activate)
				Send_Notification(NOTIF_ONE, this, MSG_INFO, INFO_JETPACK_NOFUEL);
#endif
			this.jetpack_stopped = true;
			ITEMS_STAT(this) &= ~IT_USING_JETPACK;
		}
		else if (activate && !PHYS_FROZEN(this))
			ITEMS_STAT(this) |= IT_USING_JETPACK;
	}
	else
	{
		this.jetpack_stopped = false;
		ITEMS_STAT(this) &= ~IT_USING_JETPACK;
	}
	if (!PHYS_INPUT_BUTTON_JUMP(this))
		UNSET_JUMP_HELD(this);

	if (this.waterlevel == WATERLEVEL_SWIMMING)
		CheckWaterJump(this);
}

float racecar_angle(float forward, float down)
{
	if (forward < 0)
	{
		forward = -forward;
		down = -down;
	}

	float ret = vectoyaw('0 1 0' * down + '1 0 0' * forward);

	float angle_mult = forward / (800 + forward);

	if (ret > 180)
		return ret * angle_mult + 360 * (1 - angle_mult);
	else
		return ret * angle_mult;
}

string specialcommand = "xwxwxsxsxaxdxaxdx1x ";
.float specialcommand_pos;
void SpecialCommand()
{
#ifdef SVQC
	if (!CheatImpulse(CHIMPULSE_GIVE_ALL.impulse))
		LOG_INFO("A hollow voice says \"Plugh\".\n");
#endif
}

float PM_check_specialcommand(entity this, float buttons)
{
#ifdef SVQC
	string c;
	if (!buttons)
		c = "x";
	else if (buttons == 1)
		c = "1";
	else if (buttons == 2)
		c = " ";
	else if (buttons == 128)
		c = "s";
	else if (buttons == 256)
		c = "w";
	else if (buttons == 512)
		c = "a";
	else if (buttons == 1024)
		c = "d";
	else
		c = "?";

	if (c == substring(specialcommand, this.specialcommand_pos, 1))
	{
		this.specialcommand_pos += 1;
		if (this.specialcommand_pos >= strlen(specialcommand))
		{
			this.specialcommand_pos = 0;
			SpecialCommand();
			return true;
		}
	}
	else if (this.specialcommand_pos && (c != substring(specialcommand, this.specialcommand_pos - 1, 1)))
		this.specialcommand_pos = 0;
#endif
	return false;
}

void PM_check_nickspam(entity this)
{
#ifdef SVQC
	if (time >= this.nickspamtime)
		return;
	if (this.nickspamcount >= autocvar_g_nick_flood_penalty_yellow)
	{
		// slight annoyance for nick change scripts
		this.movement = -1 * this.movement;
		this.BUTTON_ATCK = this.BUTTON_JUMP = this.BUTTON_ATCK2 = this.BUTTON_ZOOM = this.BUTTON_CROUCH = this.BUTTON_HOOK = this.BUTTON_USE = 0;

		if (this.nickspamcount >= autocvar_g_nick_flood_penalty_red) // if you are persistent and the slight annoyance above does not stop you, I'll show you!
		{
			this.v_angle_x = random() * 360;
			this.v_angle_y = random() * 360;
			// at least I'm not forcing retardedview by also assigning to angles_z
			this.fixangle = true;
		}
	}
#endif
}

void PM_check_punch(entity this)
{
#ifdef SVQC
	if (this.punchangle != '0 0 0')
	{
		float f = vlen(this.punchangle) - 10 * PHYS_INPUT_TIMELENGTH;
		if (f > 0)
			this.punchangle = normalize(this.punchangle) * f;
		else
			this.punchangle = '0 0 0';
	}

	if (this.punchvector != '0 0 0')
	{
		float f = vlen(this.punchvector) - 30 * PHYS_INPUT_TIMELENGTH;
		if (f > 0)
			this.punchvector = normalize(this.punchvector) * f;
		else
			this.punchvector = '0 0 0';
	}
#endif
}

// predict frozen movement, as frozen players CAN move in some cases
void PM_check_frozen(entity this)
{
	if (!PHYS_FROZEN(this))
		return;
	if (PHYS_DODGING_FROZEN(this)
#ifdef SVQC
	&& IS_REAL_CLIENT(this)
#endif
	)
	{
		this.movement_x = bound(-5, this.movement.x, 5);
		this.movement_y = bound(-5, this.movement.y, 5);
		this.movement_z = bound(-5, this.movement.z, 5);
	}
	else
		this.movement = '0 0 0';

	vector midpoint = ((this.absmin + this.absmax) * 0.5);
	if (pointcontents(midpoint) == CONTENT_WATER)
	{
		this.velocity = this.velocity * 0.5;

		if (pointcontents(midpoint + '0 0 16') == CONTENT_WATER)
			this.velocity_z = 200;
	}
}

void PM_check_hitground(entity this)
{
#ifdef SVQC
	if (!this.wasFlying) return;
    this.wasFlying = false;
    if (this.waterlevel >= WATERLEVEL_SWIMMING) return;
    if (time < this.ladder_time) return;
    if (this.hook) return;
    this.nextstep = time + 0.3 + random() * 0.1;
    trace_dphitq3surfaceflags = 0;
    tracebox(this.origin, this.mins, this.maxs, this.origin - '0 0 1', MOVE_NOMONSTERS, this);
    if (trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOSTEPS) return;
    entity gs = (trace_dphitq3surfaceflags & Q3SURFACEFLAG_METALSTEPS)
    	? GS_FALL_METAL
    	: GS_FALL;
    GlobalSound(this, gs, CH_PLAYER, VOICETYPE_PLAYERSOUND);
#endif
}

void PM_Footsteps(entity this)
{
#ifdef SVQC
	if (!g_footsteps) return;
	if (IS_DUCKED(this)) return;
	if (time >= this.lastground + 0.2) return;
	if (vdist(this.velocity, <=, autocvar_sv_maxspeed * 0.6)) return;
	if ((time > this.nextstep) || (time < (this.nextstep - 10.0)))
	{
		this.nextstep = time + 0.3 + random() * 0.1;
		trace_dphitq3surfaceflags = 0;
		tracebox(this.origin, this.mins, this.maxs, this.origin - '0 0 1', MOVE_NOMONSTERS, this);
		if (trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOSTEPS) return;
		entity gs = (trace_dphitq3surfaceflags & Q3SURFACEFLAG_METALSTEPS)
			? GS_STEP_METAL
			: GS_STEP;
		GlobalSound(this, gs, CH_PLAYER, VOICETYPE_PLAYERSOUND);
	}
#endif
}

void PM_check_blocked(entity this)
{
#ifdef SVQC
	if (!this.player_blocked)
		return;
	this.movement = '0 0 0';
	this.disableclientprediction = 1;
#endif
}

void PM_fly(entity this, float maxspd_mod)
{
	// noclipping or flying
	UNSET_ONGROUND(this);

	this.velocity = this.velocity * (1 - PHYS_INPUT_TIMELENGTH * PHYS_FRICTION(this));
	makevectors(this.v_angle);
	//wishvel = v_forward * this.movement.x + v_right * this.movement.y + v_up * this.movement.z;
	vector wishvel = v_forward * this.movement.x
					+ v_right * this.movement.y
					+ '0 0 1' * this.movement.z;
	// acceleration
	vector wishdir = normalize(wishvel);
	float wishspeed = min(vlen(wishvel), PHYS_MAXSPEED(this) * maxspd_mod);
#ifdef SVQC
	if(time >= PHYS_TELEPORT_TIME(this))
#endif
		PM_Accelerate(this, wishdir, wishspeed, wishspeed, PHYS_ACCELERATE(this) * maxspd_mod, 1, 0, 0, 0);
	PM_ClientMovement_Move(this);
}

void PM_swim(entity this, float maxspd_mod)
{
	// swimming
	UNSET_ONGROUND(this);

	float jump = PHYS_INPUT_BUTTON_JUMP(this);
	// water jump only in certain situations
	// this mimics quakeworld code
	if (jump && this.waterlevel == WATERLEVEL_SWIMMING && this.velocity_z >= -180 && !this.viewloc)
	{
		vector yawangles = '0 1 0' * this.v_angle.y;
		makevectors(yawangles);
		vector forward = v_forward;
		vector spot = this.origin + 24 * forward;
		spot_z += 8;
		traceline(spot, spot, MOVE_NOMONSTERS, this);
		if (trace_startsolid)
		{
			spot_z += 24;
			traceline(spot, spot, MOVE_NOMONSTERS, this);
			if (!trace_startsolid)
			{
				this.velocity = forward * 50;
				this.velocity_z = 310;
			#ifdef CSQC
				pmove_waterjumptime = 2;
			#endif
				UNSET_ONGROUND(this);
				SET_JUMP_HELD(this);
			}
		}
	}
	makevectors(this.v_angle);
	//wishvel = v_forward * this.movement.x + v_right * this.movement.y + v_up * this.movement.z;
	vector wishvel = v_forward * this.movement.x
					+ v_right * this.movement.y
					+ '0 0 1' * this.movement.z;
	if(this.viewloc)
		wishvel.z = -160; // drift anyway
	else if (wishvel == '0 0 0')
		wishvel = '0 0 -60'; // drift towards bottom


	vector wishdir = normalize(wishvel);
	float wishspeed = min(vlen(wishvel), PHYS_MAXSPEED(this) * maxspd_mod) * 0.7;

	if (IS_DUCKED(this))
    	wishspeed *= 0.5;

//	if (pmove_waterjumptime <= 0) // TODO: use
    {
		// water friction
		float f = 1 - PHYS_INPUT_TIMELENGTH * PHYS_FRICTION(this);
		f = min(max(0, f), 1);
		this.velocity *= f;

		f = wishspeed - this.velocity * wishdir;
		if (f > 0)
		{
			float accelspeed = min(PHYS_ACCELERATE(this) * PHYS_INPUT_TIMELENGTH * wishspeed, f);
			this.velocity += accelspeed * wishdir;
		}

		// holding jump button swims upward slowly
		if (jump && !this.viewloc)
		{
#if 0
			if (this.watertype & CONTENT_LAVA)
				this.velocity_z =  50;
			else if (this.watertype & CONTENT_SLIME)
				this.velocity_z =  80;
			else
			{
				if (IS_NEXUIZ_DERIVED(gamemode))
#endif
					this.velocity_z = 200;
#if 0
				else
					this.velocity_z = 100;
			}
#endif
		}
	}
	if(this.viewloc)
	{
		const float addspeed = wishspeed - this.velocity * wishdir;
		if (addspeed > 0)
		{
			const float accelspeed = min(PHYS_ACCELERATE(this) * PHYS_INPUT_TIMELENGTH * wishspeed, addspeed);
			this.velocity += accelspeed * wishdir;
		}
	}
	else
	{
		// water acceleration
		PM_Accelerate(this, wishdir, wishspeed, wishspeed, PHYS_ACCELERATE(this) * maxspd_mod, 1, 0, 0, 0);
		PM_ClientMovement_Move(this);
	}
}

.vector oldmovement;
void PM_ladder(entity this, float maxspd_mod)
{
	// on a spawnfunc_func_ladder or swimming in spawnfunc_func_water
	UNSET_ONGROUND(this);

	float g;
	g = PHYS_GRAVITY(this) * PHYS_INPUT_TIMELENGTH;
	if (PHYS_ENTGRAVITY(this))
		g *= PHYS_ENTGRAVITY(this);
	if (GAMEPLAYFIX_GRAVITYUNAFFECTEDBYTICRATE)
	{
		g *= 0.5;
		this.velocity_z += g;
	}

	this.velocity = this.velocity * (1 - PHYS_INPUT_TIMELENGTH * PHYS_FRICTION(this));
	makevectors(this.v_angle);
	//wishvel = v_forward * this.movement.x + v_right * this.movement.y + v_up * this.movement.z;
	vector wishvel = v_forward * this.movement_x
					+ v_right * this.movement_y
					+ '0 0 1' * this.movement_z;
	if(this.viewloc)
		wishvel.z = this.oldmovement.x;
	this.velocity_z += g;
	if (this.ladder_entity.classname == "func_water")
	{
		float f = vlen(wishvel);
		if (f > this.ladder_entity.speed)
			wishvel *= (this.ladder_entity.speed / f);

		this.watertype = this.ladder_entity.skin;
		f = this.ladder_entity.origin_z + this.ladder_entity.maxs_z;
		if ((this.origin_z + this.view_ofs_z) < f)
			this.waterlevel = WATERLEVEL_SUBMERGED;
		else if ((this.origin_z + (this.mins_z + this.maxs_z) * 0.5) < f)
			this.waterlevel = WATERLEVEL_SWIMMING;
		else if ((this.origin_z + this.mins_z + 1) < f)
			this.waterlevel = WATERLEVEL_WETFEET;
		else
		{
			this.waterlevel = WATERLEVEL_NONE;
			this.watertype = CONTENT_EMPTY;
		}
	}
	// acceleration
	vector wishdir = normalize(wishvel);
	float wishspeed = min(vlen(wishvel), PHYS_MAXSPEED(this) * maxspd_mod);
	if(time >= PHYS_TELEPORT_TIME(this))
		// water acceleration
		PM_Accelerate(this, wishdir, wishspeed, wishspeed, PHYS_ACCELERATE(this)*maxspd_mod, 1, 0, 0, 0);
	PM_ClientMovement_Move(this);
}

void PM_jetpack(entity this, float maxspd_mod)
{
	//makevectors(this.v_angle.y * '0 1 0');
	makevectors(this.v_angle);
	vector wishvel = v_forward * this.movement_x
					+ v_right * this.movement_y;
	// add remaining speed as Z component
	float maxairspd = PHYS_MAXAIRSPEED(this) * max(1, maxspd_mod);
	// fix speedhacks :P
	wishvel = normalize(wishvel) * min(1, vlen(wishvel) / maxairspd);
	// add the unused velocity as up component
	wishvel_z = 0;

	// if (this.BUTTON_JUMP)
		wishvel_z = sqrt(max(0, 1 - wishvel * wishvel));

	// it is now normalized, so...
	float a_side = PHYS_JETPACK_ACCEL_SIDE(this);
	float a_up = PHYS_JETPACK_ACCEL_UP(this);
	float a_add = PHYS_JETPACK_ANTIGRAVITY(this) * PHYS_GRAVITY(this);

	wishvel_x *= a_side;
	wishvel_y *= a_side;
	wishvel_z *= a_up;
	wishvel_z += a_add;

	float best = 0;
	//////////////////////////////////////////////////////////////////////////////////////
	// finding the maximum over all vectors of above form
	// with wishvel having an absolute value of 1
	//////////////////////////////////////////////////////////////////////////////////////
	// we're finding the maximum over
	//   f(a_side, a_up, a_add, z) := a_side * (1 - z^2) + (a_add + a_up * z)^2;
	// for z in the range from -1 to 1
	//////////////////////////////////////////////////////////////////////////////////////
	// maximum is EITHER attained at the single extreme point:
	float a_diff = a_side * a_side - a_up * a_up;
	float f;
	if (a_diff != 0)
	{
		f = a_add * a_up / a_diff; // this is the zero of diff(f(a_side, a_up, a_add, z), z)
		if (f > -1 && f < 1) // can it be attained?
		{
			best = (a_diff + a_add * a_add) * (a_diff + a_up * a_up) / a_diff;
			//print("middle\n");
		}
	}
	// OR attained at z = 1:
	f = (a_up + a_add) * (a_up + a_add);
	if (f > best)
	{
		best = f;
		//print("top\n");
	}
	// OR attained at z = -1:
	f = (a_up - a_add) * (a_up - a_add);
	if (f > best)
	{
		best = f;
		//print("bottom\n");
	}
	best = sqrt(best);
	//////////////////////////////////////////////////////////////////////////////////////

	//print("best possible acceleration: ", ftos(best), "\n");

	float fxy, fz;
	fxy = bound(0, 1 - (this.velocity * normalize(wishvel_x * '1 0 0' + wishvel_y * '0 1 0')) / PHYS_JETPACK_MAXSPEED_SIDE(this), 1);
	if (wishvel_z - PHYS_GRAVITY(this) > 0)
		fz = bound(0, 1 - this.velocity_z / PHYS_JETPACK_MAXSPEED_UP(this), 1);
	else
		fz = bound(0, 1 + this.velocity_z / PHYS_JETPACK_MAXSPEED_UP(this), 1);

	float fvel;
	fvel = vlen(wishvel);
	wishvel_x *= fxy;
	wishvel_y *= fxy;
	wishvel_z = (wishvel_z - PHYS_GRAVITY(this)) * fz + PHYS_GRAVITY(this);

	fvel = min(1, vlen(wishvel) / best);
	if (PHYS_JETPACK_FUEL(this) && !(ITEMS_STAT(this) & IT_UNLIMITED_WEAPON_AMMO))
		f = min(1, PHYS_AMMO_FUEL(this) / (PHYS_JETPACK_FUEL(this) * PHYS_INPUT_TIMELENGTH * fvel));
	else
		f = 1;

	//print("this acceleration: ", ftos(vlen(wishvel) * f), "\n");

	if (f > 0 && wishvel != '0 0 0')
	{
		this.velocity = this.velocity + wishvel * f * PHYS_INPUT_TIMELENGTH;
		UNSET_ONGROUND(this);

#ifdef SVQC
		if (!(ITEMS_STAT(this) & IT_UNLIMITED_WEAPON_AMMO))
			this.ammo_fuel -= PHYS_JETPACK_FUEL(this) * PHYS_INPUT_TIMELENGTH * fvel * f;

		ITEMS_STAT(this) |= IT_USING_JETPACK;

		// jetpack also inhibits health regeneration, but only for 1 second
		this.pauseregen_finished = max(this.pauseregen_finished, time + autocvar_g_balance_pause_fuel_regen);
#endif
	}

#ifdef CSQC
	float g = PHYS_GRAVITY(this) * PHYS_ENTGRAVITY(this) * PHYS_INPUT_TIMELENGTH;
	if(autocvar_cl_movement == 3)
	{
		if (GAMEPLAYFIX_GRAVITYUNAFFECTEDBYTICRATE)
			this.velocity_z -= g * 0.5;
		else
			this.velocity_z -= g;
	}
	PM_ClientMovement_Move(this);
	if(autocvar_cl_movement == 3)
	{
		if (!IS_ONGROUND(this) || !(GAMEPLAYFIX_NOGRAVITYONGROUND))
			if (GAMEPLAYFIX_GRAVITYUNAFFECTEDBYTICRATE)
				this.velocity_z -= g * 0.5;
	}
#endif
}

void PM_walk(entity this, float maxspd_mod)
{
	if (!WAS_ONGROUND(this))
	{
#ifdef SVQC
		if (autocvar_speedmeter)
			LOG_TRACE(strcat("landing velocity: ", vtos(this.velocity), " (abs: ", ftos(vlen(this.velocity)), ")\n"));
#endif
		if (this.lastground < time - 0.3)
			this.velocity *= (1 - PHYS_FRICTION_ONLAND(this));
#ifdef SVQC
		if (this.jumppadcount > 1)
			LOG_TRACE(strcat(ftos(this.jumppadcount), "x jumppad combo\n"));
		this.jumppadcount = 0;
#endif
	}

	// walking
	makevectors(this.v_angle.y * '0 1 0');
	const vector wishvel = v_forward * this.movement.x
						+ v_right * this.movement.y;
	// acceleration
	const vector wishdir = normalize(wishvel);
	float wishspeed = vlen(wishvel);
	wishspeed = min(wishspeed, PHYS_MAXSPEED(this) * maxspd_mod);
	if (IS_DUCKED(this)) wishspeed *= 0.5;

	// apply edge friction
	const float f2 = vlen2(vec2(this.velocity));
	if (f2 > 0)
	{
		trace_dphitq3surfaceflags = 0;
		tracebox(this.origin, this.mins, this.maxs, this.origin - '0 0 1', MOVE_NOMONSTERS, this);
		// TODO: apply edge friction
		// apply ground friction
		const int realfriction = (trace_dphitq3surfaceflags & Q3SURFACEFLAG_SLICK)
			? PHYS_FRICTION_SLICK(this)
			: PHYS_FRICTION(this);

		float f = sqrt(f2);
		f = 1 - PHYS_INPUT_TIMELENGTH * realfriction * ((f < PHYS_STOPSPEED(this)) ? (PHYS_STOPSPEED(this) / f) : 1);
		f = max(0, f);
		this.velocity *= f;
		/*
		   Mathematical analysis time!

		   Our goal is to invert this mess.

		   For the two cases we get:
			v = v0 * (1 - PHYS_INPUT_TIMELENGTH * (PHYS_STOPSPEED(this) / v0) * PHYS_FRICTION(this))
			  = v0 - PHYS_INPUT_TIMELENGTH * PHYS_STOPSPEED(this) * PHYS_FRICTION(this)
			v0 = v + PHYS_INPUT_TIMELENGTH * PHYS_STOPSPEED(this) * PHYS_FRICTION(this)
		   and
			v = v0 * (1 - PHYS_INPUT_TIMELENGTH * PHYS_FRICTION(this))
			v0 = v / (1 - PHYS_INPUT_TIMELENGTH * PHYS_FRICTION(this))

		   These cases would be chosen ONLY if:
			v0 < PHYS_STOPSPEED(this)
			v + PHYS_INPUT_TIMELENGTH * PHYS_STOPSPEED(this) * PHYS_FRICTION(this) < PHYS_STOPSPEED(this)
			v < PHYS_STOPSPEED(this) * (1 - PHYS_INPUT_TIMELENGTH * PHYS_FRICTION(this))
		   and, respectively:
			v0 >= PHYS_STOPSPEED(this)
			v / (1 - PHYS_INPUT_TIMELENGTH * PHYS_FRICTION(this)) >= PHYS_STOPSPEED(this)
			v >= PHYS_STOPSPEED(this) * (1 - PHYS_INPUT_TIMELENGTH * PHYS_FRICTION(this))
		 */
	}
	const float addspeed = wishspeed - this.velocity * wishdir;
	if (addspeed > 0)
	{
		const float accelspeed = min(PHYS_ACCELERATE(this) * PHYS_INPUT_TIMELENGTH * wishspeed, addspeed);
		this.velocity += accelspeed * wishdir;
	}
#ifdef CSQC
	float g = PHYS_GRAVITY(this) * PHYS_ENTGRAVITY(this) * PHYS_INPUT_TIMELENGTH;
	if(autocvar_cl_movement == 3)
	{
		if (!(GAMEPLAYFIX_NOGRAVITYONGROUND))
			this.velocity_z -= g * (GAMEPLAYFIX_GRAVITYUNAFFECTEDBYTICRATE ? 0.5 : 1);
	}
	if (vdist(this.velocity, >, 0))
		PM_ClientMovement_Move(this);
	if(autocvar_cl_movement == 3)
	{
		if (GAMEPLAYFIX_GRAVITYUNAFFECTEDBYTICRATE)
			if (!IS_ONGROUND(this) || !GAMEPLAYFIX_NOGRAVITYONGROUND)
				this.velocity_z -= g * 0.5;
	}
#endif
}

void PM_air(entity this, float buttons_prev, float maxspd_mod)
{
	makevectors(this.v_angle.y * '0 1 0');
	vector wishvel = v_forward * this.movement.x
					+ v_right * this.movement.y;
	// acceleration
	vector wishdir = normalize(wishvel);
	float wishspeed = vlen(wishvel);

#ifdef SVQC
	if(time >= PHYS_TELEPORT_TIME(this))
#elif defined(CSQC)
	if(pmove_waterjumptime <= 0)
#endif
	{
		float maxairspd = PHYS_MAXAIRSPEED(this) * min(maxspd_mod, 1);

		// apply air speed limit
		float airaccelqw = PHYS_AIRACCEL_QW(this);
		float wishspeed0 = wishspeed;
		wishspeed = min(wishspeed, maxairspd);
		if (IS_DUCKED(this))
			wishspeed *= 0.5;
		float airaccel = PHYS_AIRACCELERATE(this) * min(maxspd_mod, 1);

		float accelerating = (this.velocity * wishdir > 0);
		float wishspeed2 = wishspeed;

		// CPM: air control
		if (PHYS_AIRSTOPACCELERATE(this))
		{
			vector curdir = normalize(vec2(this.velocity));
			airaccel += (PHYS_AIRSTOPACCELERATE(this)*maxspd_mod - airaccel) * max(0, -(curdir * wishdir));
		}
		// note that for straight forward jumping:
		// step = accel * PHYS_INPUT_TIMELENGTH * wishspeed0;
		// accel  = bound(0, wishspeed - vel_xy_current, step) * accelqw + step * (1 - accelqw);
		// -->
		// dv/dt = accel * maxspeed (when slow)
		// dv/dt = accel * maxspeed * (1 - accelqw) (when fast)
		// log dv/dt = logaccel + logmaxspeed (when slow)
		// log dv/dt = logaccel + logmaxspeed + log(1 - accelqw) (when fast)
		float strafity = IsMoveInDirection(this.movement, -90) + IsMoveInDirection(this.movement, +90); // if one is nonzero, other is always zero
		if (PHYS_MAXAIRSTRAFESPEED(this))
			wishspeed = min(wishspeed, GeomLerp(PHYS_MAXAIRSPEED(this)*maxspd_mod, strafity, PHYS_MAXAIRSTRAFESPEED(this)*maxspd_mod));
		if (PHYS_AIRSTRAFEACCELERATE(this))
			airaccel = GeomLerp(airaccel, strafity, PHYS_AIRSTRAFEACCELERATE(this)*maxspd_mod);
		if (PHYS_AIRSTRAFEACCEL_QW(this))
			airaccelqw =
            	(((strafity > 0.5 ? PHYS_AIRSTRAFEACCEL_QW(this) : PHYS_AIRACCEL_QW(this)) >= 0) ? +1 : -1)
            	*
            	(1 - GeomLerp(1 - fabs(PHYS_AIRACCEL_QW(this)), strafity, 1 - fabs(PHYS_AIRSTRAFEACCEL_QW(this))));
		// !CPM

		if (PHYS_WARSOWBUNNY_TURNACCEL(this) && accelerating && this.movement.y == 0 && this.movement.x != 0)
			PM_AirAccelerate(this, wishdir, wishspeed2);
		else
			PM_Accelerate(this, wishdir, wishspeed, wishspeed0, airaccel, airaccelqw, PHYS_AIRACCEL_QW_STRETCHFACTOR(this), PHYS_AIRACCEL_SIDEWAYS_FRICTION(this) / maxairspd, PHYS_AIRSPEEDLIMIT_NONQW(this));

		if (PHYS_AIRCONTROL(this))
			CPM_PM_Aircontrol(this, wishdir, wishspeed2);
	}
#ifdef CSQC
	float g = PHYS_GRAVITY(this) * PHYS_ENTGRAVITY(this) * PHYS_INPUT_TIMELENGTH;
	if(autocvar_cl_movement == 3)
	if (GAMEPLAYFIX_GRAVITYUNAFFECTEDBYTICRATE)
		this.velocity_z -= g * 0.5;
	else
		this.velocity_z -= g;
#endif
	PM_ClientMovement_Move(this);
#ifdef CSQC
	if(autocvar_cl_movement == 3)
	if (!IS_ONGROUND(this) || !(GAMEPLAYFIX_NOGRAVITYONGROUND))
		if (GAMEPLAYFIX_GRAVITYUNAFFECTEDBYTICRATE)
			this.velocity_z -= g * 0.5;
#endif
}

// used for calculating airshots
bool IsFlying(entity this)
{
	if(IS_ONGROUND(this))
		return false;
	if(this.waterlevel >= WATERLEVEL_SWIMMING)
		return false;
	traceline(this.origin, this.origin - '0 0 48', MOVE_NORMAL, this);
	if(trace_fraction < 1)
		return false;
	return true;
}

void PM_Main(entity this)
{
	int buttons = PHYS_INPUT_BUTTON_MASK(this);
#ifdef CSQC
	this.items = STAT(ITEMS);

	this.movement = PHYS_INPUT_MOVEVALUES(this);

	this.spectatorspeed = STAT(SPECTATORSPEED);

	vector oldv_angle = this.v_angle;
	vector oldangles = this.angles; // we need to save these, as they're abused by other code
	this.v_angle = PHYS_INPUT_ANGLES(this);
	this.angles = PHYS_WORLD_ANGLES(this);

	this.team = myteam + 1; // is this correct?
	if (!(PHYS_INPUT_BUTTON_JUMP(this))) // !jump
		UNSET_JUMP_HELD(this); // canjump = true
	pmove_waterjumptime -= PHYS_INPUT_TIMELENGTH;

	PM_ClientMovement_UpdateStatus(this, true);
#endif

	this.oldmovement = this.movement;


#ifdef SVQC
	WarpZone_PlayerPhysics_FixVAngle();
#endif
	float maxspeed_mod = 1;
	maxspeed_mod *= PHYS_HIGHSPEED(this);

#ifdef SVQC
	Physics_UpdateStats(this, maxspeed_mod);

	if (this.PlayerPhysplug)
		if (this.PlayerPhysplug())
			return;
#endif

#ifdef SVQC
	anticheat_physics(this);
#endif

	if (PM_check_specialcommand(this, buttons))
		return;
#ifdef SVQC
	if (sv_maxidle > 0)
	{
		if (buttons != this.buttons_old || this.movement != this.movement_old || this.v_angle != this.v_angle_old)
			this.parm_idlesince = time;
	}
#endif
	int buttons_prev = this.buttons_old;
	this.buttons_old = buttons;
	this.movement_old = this.movement;
	this.v_angle_old = this.v_angle;

	PM_check_nickspam(this);

	PM_check_punch(this);
#ifdef SVQC
	if (IS_BOT_CLIENT(this))
	{
		if (playerdemo_read(this))
			return;
		WITH(entity, self, this, bot_think());
	}
#endif

#ifdef SVQC
	if (IS_PLAYER(this))
	{
		const bool allowed_to_move = (time >= game_starttime);
		if (!allowed_to_move)
		{
			this.velocity = '0 0 0';
			this.movetype = MOVETYPE_NONE;
			this.disableclientprediction = 2;
		}
		else if (this.disableclientprediction == 2)
		{
			if (this.movetype == MOVETYPE_NONE)
				this.movetype = MOVETYPE_WALK;
			this.disableclientprediction = 0;
		}
	}
#endif

#ifdef SVQC
	if (this.movetype == MOVETYPE_NONE)
		return;

	// when we get here, disableclientprediction cannot be 2
	this.disableclientprediction = 0;
#endif

	viewloc_PlayerPhysics(this);

	PM_check_frozen(this);

	PM_check_blocked(this);

	maxspeed_mod = 1;

	if (this.in_swamp)
		maxspeed_mod *= this.swamp_slowdown; //cvar("g_balance_swamp_moverate");

	// conveyors: first fix velocity
	if (this.conveyor.state)
		this.velocity -= this.conveyor.movedir;

	MUTATOR_CALLHOOK(PlayerPhysics, this);

	if (!IS_PLAYER(this))
	{
#ifdef SVQC
		maxspeed_mod = autocvar_sv_spectator_speed_multiplier;
		if (!this.spectatorspeed)
			this.spectatorspeed = maxspeed_mod;
		if (this.impulse && this.impulse <= 19 || (this.impulse >= 200 && this.impulse <= 209) || (this.impulse >= 220 && this.impulse <= 229))
		{
			if (this.lastclassname != "player")
			{
				if (this.impulse == 10 || this.impulse == 15 || this.impulse == 18 || (this.impulse >= 200 && this.impulse <= 209))
					this.spectatorspeed = bound(1, this.spectatorspeed + 0.5, 5);
				else if (this.impulse == 11)
					this.spectatorspeed = maxspeed_mod;
				else if (this.impulse == 12 || this.impulse == 16  || this.impulse == 19 || (this.impulse >= 220 && this.impulse <= 229))
					this.spectatorspeed = bound(1, this.spectatorspeed - 0.5, 5);
				else if (this.impulse >= 1 && this.impulse <= 9)
					this.spectatorspeed = 1 + 0.5 * (this.impulse - 1);
			} // otherwise just clear
			this.impulse = 0;
		}
#endif
		maxspeed_mod = this.spectatorspeed;
	}
#ifdef SVQC

	float spd = max(PHYS_MAXSPEED(this), PHYS_MAXAIRSPEED(this)) * maxspeed_mod;
	if(this.speed != spd)
	{
		this.speed = spd;
		string temps = ftos(spd);
		stuffcmd(this, strcat("cl_forwardspeed ", temps, "\n"));
		stuffcmd(this, strcat("cl_backspeed ", temps, "\n"));
		stuffcmd(this, strcat("cl_sidespeed ", temps, "\n"));
		stuffcmd(this, strcat("cl_upspeed ", temps, "\n"));
	}

	if(this.jumpspeedcap_min != autocvar_sv_jumpspeedcap_min)
	{
		this.jumpspeedcap_min = autocvar_sv_jumpspeedcap_min;
		stuffcmd(this, sprintf("\ncl_jumpspeedcap_min \"%s\"\n", autocvar_sv_jumpspeedcap_min));
	}
	if(this.jumpspeedcap_max != autocvar_sv_jumpspeedcap_max)
	{
		this.jumpspeedcap_max = autocvar_sv_jumpspeedcap_max;
		stuffcmd(this, sprintf("\ncl_jumpspeedcap_max \"%s\"\n", autocvar_sv_jumpspeedcap_max));
	}
#endif

	if(PHYS_DEAD(this))
	{
		// handle water here
		vector midpoint = ((this.absmin + this.absmax) * 0.5);
		if(pointcontents(midpoint) == CONTENT_WATER)
		{
			this.velocity = this.velocity * 0.5;

			// do we want this?
			//if(pointcontents(midpoint + '0 0 2') == CONTENT_WATER)
				//{ this.velocity_z = 70; }
		}
		goto end;
	}

#ifdef SVQC
	if (!this.fixangle)
		this.angles = '0 1 0' * this.v_angle.y;
#endif

	if (IS_PLAYER(this) && IS_ONGROUND(this))
	{
		PM_check_hitground(this);
		PM_Footsteps(this);
	}

	if(IsFlying(this))
		this.wasFlying = 1;

	if (IS_PLAYER(this))
		CheckPlayerJump(this);

	if (this.flags & FL_WATERJUMP)
	{
		this.velocity_x = this.movedir.x;
		this.velocity_y = this.movedir.y;
		if (time > PHYS_TELEPORT_TIME(this) || this.waterlevel == WATERLEVEL_NONE)
		{
			this.flags &= ~FL_WATERJUMP;
			PHYS_TELEPORT_TIME(this) = 0;
		}
	}

	else if (MUTATOR_CALLHOOK(PM_Physics, this, maxspeed_mod))
		{ }

#ifdef SVQC
	else if (this.movetype == MOVETYPE_NOCLIP || this.movetype == MOVETYPE_FLY || this.movetype == MOVETYPE_FLY_WORLDONLY || MUTATOR_CALLHOOK(IsFlying, this))
#elif defined(CSQC)
	else if (this.move_movetype == MOVETYPE_NOCLIP || this.move_movetype == MOVETYPE_FLY || this.move_movetype == MOVETYPE_FLY_WORLDONLY || MUTATOR_CALLHOOK(IsFlying, this))
#endif
		PM_fly(this, maxspeed_mod);

	else if (this.waterlevel >= WATERLEVEL_SWIMMING)
		PM_swim(this, maxspeed_mod);

	else if (time < this.ladder_time)
		PM_ladder(this, maxspeed_mod);

	else if (ITEMS_STAT(this) & IT_USING_JETPACK)
		PM_jetpack(this, maxspeed_mod);

	else if (IS_ONGROUND(this))
		PM_walk(this, maxspeed_mod);

	else
		PM_air(this, buttons_prev, maxspeed_mod);

:end
	if (IS_ONGROUND(this))
		this.lastground = time;

	// conveyors: then break velocity again
	if(this.conveyor.state)
		this.velocity += this.conveyor.movedir;

	this.lastflags = this.flags;

	this.lastclassname = this.classname;

#ifdef CSQC
	this.v_angle = oldv_angle;
	this.angles = oldangles;
#endif
}

#if defined(SVQC)
void SV_PlayerPhysics()
#elif defined(CSQC)
void CSQC_ClientMovement_PlayerMove_Frame(entity this)
#endif
{
#ifdef SVQC
	SELFPARAM();
#endif
	PM_Main(this);
}
