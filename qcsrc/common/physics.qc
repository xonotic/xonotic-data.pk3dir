#include "physics.qh"
#include "triggers/trigger/swamp.qh"
#include "triggers/trigger/jumppads.qh"
#include "viewloc.qh"

#ifdef SVQC

#include "../server/miscfunctions.qh"
#include "triggers/trigger/viewloc.qh"

// client side physics
bool Physics_Valid(string thecvar)
{
	if(!autocvar_g_physics_clientselect) { return false; }

	string l = strcat(" ", autocvar_g_physics_clientselect_options, " ");

	if(strstrofs(l, strcat(" ", thecvar, " "), 0) >= 0)
		return true;

	return false;
}

float Physics_ClientOption(entity pl, string option)
{
	if(Physics_Valid(pl.cvar_cl_physics))
	{
		string var = sprintf("g_physics_%s_%s", pl.cvar_cl_physics, option);
		if(cvar_type(var) & CVAR_TYPEFLAG_EXISTS)
			return cvar(var);
	}
	if(autocvar_g_physics_clientselect && autocvar_g_physics_clientselect_default)
	{
		string var = sprintf("g_physics_%s_%s", autocvar_g_physics_clientselect_default, option);
		if(cvar_type(var) & CVAR_TYPEFLAG_EXISTS)
			return cvar(var);
	}
	return cvar(strcat("sv_", option));
}

void Physics_AddStats()
{
	// static view offset and hitbox vectors
	// networked for all you bandwidth pigs out there
	addstat(STAT_PL_VIEW_OFS1, AS_FLOAT, stat_pl_view_ofs_x);
	addstat(STAT_PL_VIEW_OFS2, AS_FLOAT, stat_pl_view_ofs_y);
	addstat(STAT_PL_VIEW_OFS3, AS_FLOAT, stat_pl_view_ofs_z);
	addstat(STAT_PL_CROUCH_VIEW_OFS1, AS_FLOAT, stat_pl_crouch_view_ofs_x);
	addstat(STAT_PL_CROUCH_VIEW_OFS2, AS_FLOAT, stat_pl_crouch_view_ofs_y);
	addstat(STAT_PL_CROUCH_VIEW_OFS3, AS_FLOAT, stat_pl_crouch_view_ofs_z);

	addstat(STAT_PL_MIN1, AS_FLOAT, stat_pl_min_x);
	addstat(STAT_PL_MIN2, AS_FLOAT, stat_pl_min_y);
	addstat(STAT_PL_MIN3, AS_FLOAT, stat_pl_min_z);
	addstat(STAT_PL_MAX1, AS_FLOAT, stat_pl_max_x);
	addstat(STAT_PL_MAX2, AS_FLOAT, stat_pl_max_y);
	addstat(STAT_PL_MAX3, AS_FLOAT, stat_pl_max_z);
	addstat(STAT_PL_CROUCH_MIN1, AS_FLOAT, stat_pl_crouch_min_x);
	addstat(STAT_PL_CROUCH_MIN2, AS_FLOAT, stat_pl_crouch_min_y);
	addstat(STAT_PL_CROUCH_MIN3, AS_FLOAT, stat_pl_crouch_min_z);
	addstat(STAT_PL_CROUCH_MAX1, AS_FLOAT, stat_pl_crouch_max_x);
	addstat(STAT_PL_CROUCH_MAX2, AS_FLOAT, stat_pl_crouch_max_y);
	addstat(STAT_PL_CROUCH_MAX3, AS_FLOAT, stat_pl_crouch_max_z);

	// g_movementspeed hack
	addstat(STAT_MOVEVARS_AIRSPEEDLIMIT_NONQW, AS_FLOAT, stat_sv_airspeedlimit_nonqw);
	addstat(STAT_MOVEVARS_MAXSPEED, AS_FLOAT, stat_sv_maxspeed);
	addstat(STAT_MOVEVARS_AIRACCEL_QW, AS_FLOAT, stat_sv_airaccel_qw);
	addstat(STAT_MOVEVARS_AIRSTRAFEACCEL_QW, AS_FLOAT, stat_sv_airstrafeaccel_qw);
	addstat(STAT_MOVEVARS_HIGHSPEED, AS_FLOAT, stat_movement_highspeed);

	// jet pack
	addstat(STAT_JETPACK_ACCEL_SIDE, AS_FLOAT, stat_jetpack_accel_side);
	addstat(STAT_JETPACK_ACCEL_UP, AS_FLOAT, stat_jetpack_accel_up);
	addstat(STAT_JETPACK_ANTIGRAVITY, AS_FLOAT, stat_jetpack_antigravity);
	addstat(STAT_JETPACK_FUEL, AS_FLOAT, stat_jetpack_fuel);
	addstat(STAT_JETPACK_MAXSPEED_UP, AS_FLOAT, stat_jetpack_maxspeed_up);
	addstat(STAT_JETPACK_MAXSPEED_SIDE, AS_FLOAT, stat_jetpack_maxspeed_side);

	// hack to fix track_canjump
	addstat(STAT_MOVEVARS_TRACK_CANJUMP, AS_INT, cvar_cl_movement_track_canjump);

	// double jump
	addstat(STAT_DOUBLEJUMP, AS_INT, stat_doublejump);

	// jump speed caps
	addstat(STAT_MOVEVARS_JUMPSPEEDCAP_DISABLE_ONRAMPS, AS_INT, stat_jumpspeedcap_disable_onramps);

	// hacks
	addstat(STAT_MOVEVARS_FRICTION_ONLAND, AS_FLOAT, stat_sv_friction_on_land);
	addstat(STAT_MOVEVARS_FRICTION_SLICK, AS_FLOAT, stat_sv_friction_slick);
	addstat(STAT_GAMEPLAYFIX_EASIERWATERJUMP, AS_INT, stat_gameplayfix_easierwaterjump);

	// new properties
	addstat(STAT_MOVEVARS_JUMPVELOCITY, AS_FLOAT, stat_sv_jumpvelocity);
	addstat(STAT_MOVEVARS_AIRACCEL_QW_STRETCHFACTOR, AS_FLOAT, stat_sv_airaccel_qw_stretchfactor);
	addstat(STAT_MOVEVARS_MAXAIRSTRAFESPEED, AS_FLOAT, stat_sv_maxairstrafespeed);
	addstat(STAT_MOVEVARS_MAXAIRSPEED, AS_FLOAT, stat_sv_maxairspeed);
	addstat(STAT_MOVEVARS_AIRSTRAFEACCELERATE, AS_FLOAT, stat_sv_airstrafeaccelerate);
	addstat(STAT_MOVEVARS_WARSOWBUNNY_TURNACCEL, AS_FLOAT, stat_sv_warsowbunny_turnaccel);
	addstat(STAT_MOVEVARS_AIRACCEL_SIDEWAYS_FRICTION, AS_FLOAT, stat_sv_airaccel_sideways_friction);
	addstat(STAT_MOVEVARS_AIRCONTROL, AS_FLOAT, stat_sv_aircontrol);
	addstat(STAT_MOVEVARS_AIRCONTROL_POWER, AS_FLOAT, stat_sv_aircontrol_power);
	addstat(STAT_MOVEVARS_AIRCONTROL_PENALTY, AS_FLOAT, stat_sv_aircontrol_penalty);
	addstat(STAT_MOVEVARS_WARSOWBUNNY_AIRFORWARDACCEL, AS_FLOAT, stat_sv_warsowbunny_airforwardaccel);
	addstat(STAT_MOVEVARS_WARSOWBUNNY_TOPSPEED, AS_FLOAT, stat_sv_warsowbunny_topspeed);
	addstat(STAT_MOVEVARS_WARSOWBUNNY_ACCEL, AS_FLOAT, stat_sv_warsowbunny_accel);
	addstat(STAT_MOVEVARS_WARSOWBUNNY_BACKTOSIDERATIO, AS_FLOAT, stat_sv_warsowbunny_backtosideratio);
	addstat(STAT_MOVEVARS_FRICTION, AS_FLOAT, stat_sv_friction);
	addstat(STAT_MOVEVARS_ACCELERATE, AS_FLOAT, stat_sv_accelerate);
	addstat(STAT_MOVEVARS_STOPSPEED, AS_FLOAT, stat_sv_stopspeed);
	addstat(STAT_MOVEVARS_AIRACCELERATE, AS_FLOAT, stat_sv_airaccelerate);
	addstat(STAT_MOVEVARS_AIRSTOPACCELERATE, AS_FLOAT, stat_sv_airstopaccelerate);

	addstat(STAT_GAMEPLAYFIX_UPVELOCITYCLEARSONGROUND, AS_INT, stat_gameplayfix_upvelocityclearsonground);
}

void Physics_UpdateStats(float maxspd_mod)
{
	// blah
	self.stat_pl_view_ofs = PL_VIEW_OFS;
	self.stat_pl_crouch_view_ofs = PL_CROUCH_VIEW_OFS;

	self.stat_pl_min = PL_MIN;
	self.stat_pl_max = PL_MAX;
	self.stat_pl_crouch_min = PL_CROUCH_MIN;
	self.stat_pl_crouch_max = PL_CROUCH_MAX;


	self.stat_sv_airaccel_qw = AdjustAirAccelQW(Physics_ClientOption(self, "airaccel_qw"), maxspd_mod);
	if(Physics_ClientOption(self, "airstrafeaccel_qw"))
		self.stat_sv_airstrafeaccel_qw = AdjustAirAccelQW(Physics_ClientOption(self, "airstrafeaccel_qw"), maxspd_mod);
	else
		self.stat_sv_airstrafeaccel_qw = 0;
	self.stat_sv_airspeedlimit_nonqw = Physics_ClientOption(self, "airspeedlimit_nonqw") * maxspd_mod;
	self.stat_sv_maxspeed = Physics_ClientOption(self, "maxspeed") * maxspd_mod; // also slow walking
	self.stat_movement_highspeed = PHYS_HIGHSPEED; // TODO: remove this!

	self.stat_doublejump = PHYS_DOUBLEJUMP;

	self.stat_jetpack_antigravity = PHYS_JETPACK_ANTIGRAVITY;
	self.stat_jetpack_accel_up = PHYS_JETPACK_ACCEL_UP;
	self.stat_jetpack_accel_side = PHYS_JETPACK_ACCEL_SIDE;
	self.stat_jetpack_maxspeed_side = PHYS_JETPACK_MAXSPEED_SIDE;
	self.stat_jetpack_maxspeed_up = PHYS_JETPACK_MAXSPEED_UP;
	self.stat_jetpack_fuel = PHYS_JETPACK_FUEL;

	self.stat_jumpspeedcap_disable_onramps = PHYS_JUMPSPEEDCAP_DISABLE_ONRAMPS;

	self.stat_sv_friction_on_land = PHYS_FRICTION_ONLAND;
	self.stat_sv_friction_slick = PHYS_FRICTION_SLICK;

	self.stat_gameplayfix_easierwaterjump = GAMEPLAYFIX_EASIERWATERJUMP;


	// old stats
	// fix some new settings
	self.stat_sv_airaccel_qw_stretchfactor = Physics_ClientOption(self, "airaccel_qw_stretchfactor");
	self.stat_sv_maxairstrafespeed = Physics_ClientOption(self, "maxairstrafespeed");
	self.stat_sv_maxairspeed = Physics_ClientOption(self, "maxairspeed");
	self.stat_sv_airstrafeaccelerate = Physics_ClientOption(self, "airstrafeaccelerate");
	self.stat_sv_warsowbunny_turnaccel = Physics_ClientOption(self, "warsowbunny_turnaccel");
	self.stat_sv_airaccel_sideways_friction = Physics_ClientOption(self, "airaccel_sideways_friction");
	self.stat_sv_aircontrol = Physics_ClientOption(self, "aircontrol");
	self.stat_sv_aircontrol_power = Physics_ClientOption(self, "aircontrol_power");
	self.stat_sv_aircontrol_penalty = Physics_ClientOption(self, "aircontrol_penalty");
	self.stat_sv_warsowbunny_airforwardaccel = Physics_ClientOption(self, "warsowbunny_airforwardaccel");
	self.stat_sv_warsowbunny_topspeed = Physics_ClientOption(self, "warsowbunny_topspeed");
	self.stat_sv_warsowbunny_accel = Physics_ClientOption(self, "warsowbunny_accel");
	self.stat_sv_warsowbunny_backtosideratio = Physics_ClientOption(self, "warsowbunny_backtosideratio");
	self.stat_sv_friction = Physics_ClientOption(self, "friction");
	self.stat_sv_accelerate = Physics_ClientOption(self, "accelerate");
	self.stat_sv_stopspeed = Physics_ClientOption(self, "stopspeed");
	self.stat_sv_airaccelerate = Physics_ClientOption(self, "airaccelerate");
	self.stat_sv_airstopaccelerate = Physics_ClientOption(self, "airstopaccelerate");
	self.stat_sv_jumpvelocity = Physics_ClientOption(self, "jumpvelocity");

	self.stat_gameplayfix_upvelocityclearsonground = UPWARD_VELOCITY_CLEARS_ONGROUND;
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

noref float pmove_waterjumptime;

const float unstick_count = 27;
vector unstick_offsets[unstick_count] =
{
// 1 no nudge (just return the original if this test passes)
	'0.000   0.000  0.000',
// 6 simple nudges
	' 0.000  0.000  0.125', '0.000  0.000 -0.125',
	'-0.125  0.000  0.000', '0.125  0.000  0.000',
	' 0.000 -0.125  0.000', '0.000  0.125  0.000',
// 4 diagonal flat nudges
	'-0.125 -0.125  0.000', '0.125 -0.125  0.000',
	'-0.125  0.125  0.000', '0.125  0.125  0.000',
// 8 diagonal upward nudges
	'-0.125  0.000  0.125', '0.125  0.000  0.125',
	' 0.000 -0.125  0.125', '0.000  0.125  0.125',
	'-0.125 -0.125  0.125', '0.125 -0.125  0.125',
	'-0.125  0.125  0.125', '0.125  0.125  0.125',
// 8 diagonal downward nudges
	'-0.125  0.000 -0.125', '0.125  0.000 -0.125',
	' 0.000 -0.125 -0.125', '0.000  0.125 -0.125',
	'-0.125 -0.125 -0.125', '0.125 -0.125 -0.125',
	'-0.125  0.125 -0.125', '0.125  0.125 -0.125',
};

void PM_ClientMovement_Unstick()
{
	float i;
	for (i = 0; i < unstick_count; i++)
	{
		vector neworigin = unstick_offsets[i] + self.origin;
		tracebox(neworigin, PL_CROUCH_MIN, PL_CROUCH_MAX, neworigin, MOVE_NORMAL, self);
		if (!trace_startsolid)
		{
			setorigin(self, neworigin);
			return;// true;
		}
	}
}

void PM_ClientMovement_UpdateStatus(bool ground)
{
	// make sure player is not stuck
	PM_ClientMovement_Unstick();

	// set crouched
	if (PHYS_INPUT_BUTTON_CROUCH(self))
	{
		// wants to crouch, this always works..
		if (!IS_DUCKED(self))
			SET_DUCKED(self);
	}
	else
	{
		// wants to stand, if currently crouching we need to check for a
		// low ceiling first
		if (IS_DUCKED(self))
		{
			tracebox(self.origin, PL_MIN, PL_MAX, self.origin, MOVE_NORMAL, self);
			if (!trace_startsolid)
				UNSET_DUCKED(self);
		}
	}

	// set onground
	vector origin1 = self.origin + '0 0 1';
	vector origin2 = self.origin - '0 0 1';

	if(ground)
	{
		tracebox(origin1, self.mins, self.maxs, origin2, MOVE_NORMAL, self);
		if (trace_fraction < 1.0 && trace_plane_normal_z > 0.7)
		{
			SET_ONGROUND(self);

			// this code actually "predicts" an impact; so let's clip velocity first
			float f = self.velocity * trace_plane_normal;
			self.velocity -= f * trace_plane_normal;
		}
		else
			UNSET_ONGROUND(self);
	}

	// set watertype/waterlevel
	origin1 = self.origin;
	origin1_z += self.mins_z + 1;
	self.waterlevel = WATERLEVEL_NONE;

	int thepoint = pointcontents(origin1);

	self.watertype = (thepoint == CONTENT_WATER || thepoint == CONTENT_LAVA || thepoint == CONTENT_SLIME);

	if(self.watertype)
	{
		self.waterlevel = WATERLEVEL_WETFEET;
		origin1_z = self.origin_z + (self.mins_z + self.maxs_z) * 0.5;
		thepoint = pointcontents(origin1);
		if(thepoint == CONTENT_WATER || thepoint == CONTENT_LAVA || thepoint == CONTENT_SLIME)
		{
			self.waterlevel = WATERLEVEL_SWIMMING;
			origin1_z = self.origin_z + 22;
			thepoint = pointcontents(origin1);
			if(thepoint == CONTENT_WATER || thepoint == CONTENT_LAVA || thepoint == CONTENT_SLIME)
				self.waterlevel = WATERLEVEL_SUBMERGED;
		}
	}

	if(IS_ONGROUND(self) || self.velocity_z <= 0 || pmove_waterjumptime <= 0)
		pmove_waterjumptime = 0;
}

void PM_ClientMovement_Move()
{
#ifdef CSQC
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
	

	PM_ClientMovement_UpdateStatus(false);
	primalvelocity = self.velocity;
	for(bump = 0, t = PHYS_INPUT_TIMELENGTH; bump < 8 && (self.velocity * self.velocity) > 0; bump++)
	{
		neworigin = self.origin + t * self.velocity;
		tracebox(self.origin, self.mins, self.maxs, neworigin, MOVE_NORMAL, self);
		trace1_endpos = trace_endpos;
		trace1_fraction = trace_fraction;
		trace1_plane_normal = trace_plane_normal;
		if(trace1_fraction < 1 && trace1_plane_normal_z == 0)
		{
			// may be a step or wall, try stepping up
			// first move forward at a higher level
			currentorigin2 = self.origin;
			currentorigin2_z += PHYS_STEPHEIGHT;
			neworigin2 = neworigin;
			neworigin2_z += PHYS_STEPHEIGHT;
			tracebox(currentorigin2, self.mins, self.maxs, neworigin2, MOVE_NORMAL, self);
			trace2_endpos = trace_endpos;
			trace2_fraction = trace_fraction;
			trace2_plane_normal = trace_plane_normal;
			if(!trace_startsolid)
			{
				// then move down from there
				currentorigin2 = trace2_endpos;
				neworigin2 = trace2_endpos;
				neworigin2_z = self.origin_z;
				tracebox(currentorigin2, self.mins, self.maxs, neworigin2, MOVE_NORMAL, self);
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
			setorigin(self, trace1_endpos);

		// check if it moved all the way
		if(trace1_fraction == 1)
			break;

		// this is only really needed for nogravityonground combined with gravityunaffectedbyticrate
		// <LordHavoc> I'm pretty sure I commented it out solely because it seemed redundant
		// this got commented out in a change that supposedly makes the code match QW better
		// so if this is broken, maybe put it in an if(cls.protocol != PROTOCOL_QUAKEWORLD) block
		if(trace1_plane_normal_z > 0.7)
			SET_ONGROUND(self);

		t -= t * trace1_fraction;

		f = (self.velocity * trace1_plane_normal);
		self.velocity = self.velocity + -f * trace1_plane_normal;
	}
	if(pmove_waterjumptime > 0)
		self.velocity = primalvelocity;
#endif
}

void CPM_PM_Aircontrol(vector wishdir, float wishspeed)
{
	float k = 32 * (2 * IsMoveInDirection(self.movement, 0) - 1);
	if (k <= 0)
		return;

	k *= bound(0, wishspeed / PHYS_MAXAIRSPEED(self), 1);

	float zspeed = self.velocity_z;
	self.velocity_z = 0;
	float xyspeed = vlen(self.velocity);
	self.velocity = normalize(self.velocity);

	float dot = self.velocity * wishdir;

	if (dot > 0) // we can't change direction while slowing down
	{
		k *= pow(dot, PHYS_AIRCONTROL_POWER) * PHYS_INPUT_TIMELENGTH;
		xyspeed = max(0, xyspeed - PHYS_AIRCONTROL_PENALTY * sqrt(max(0, 1 - dot*dot)) * k/32);
		k *= PHYS_AIRCONTROL;
		self.velocity = normalize(self.velocity * xyspeed + wishdir * k);
	}

	self.velocity = self.velocity * xyspeed;
	self.velocity_z = zspeed;
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
void PM_Accelerate(vector wishdir, float wishspeed, float wishspeed0, float accel, float accelqw, float stretchfactor, float sidefric, float speedlimit)
{
	float speedclamp = stretchfactor > 0 ? stretchfactor
	: accelqw < 0 ? 1 // full clamping, no stretch
	: -1; // no clamping

	accelqw = fabs(accelqw);

	if (GAMEPLAYFIX_Q2AIRACCELERATE)
		wishspeed0 = wishspeed; // don't need to emulate this Q1 bug

	float vel_straight = self.velocity * wishdir;
	float vel_z = self.velocity_z;
	vector vel_xy = vec2(self.velocity);
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
		float fmin = (vel_xy_backward * vel_xy_backward - vel_straight * vel_straight) / (vel_perpend * vel_perpend);
		// assume: fmin > 1
		// vel_xy_backward*vel_xy_backward - vel_straight*vel_straight > vel_perpend*vel_perpend
		// vel_xy_backward*vel_xy_backward > vel_straight*vel_straight + vel_perpend*vel_perpend
		// vel_xy_backward*vel_xy_backward > vel_xy * vel_xy
		// obviously, this cannot be
		if (fmin <= 0)
			vel_perpend *= f;
		else
		{
			fmin = sqrt(fmin);
			vel_perpend *= max(fmin, f);
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

	self.velocity = vel_xy + vel_z * '0 0 1';
}

void PM_AirAccelerate(vector wishdir, float wishspeed)
{
	if (wishspeed == 0)
		return;

	vector curvel = self.velocity;
	curvel_z = 0;
	float curspeed = vlen(curvel);

	if (wishspeed > curspeed * 1.01)
		wishspeed = min(wishspeed, curspeed + PHYS_WARSOWBUNNY_AIRFORWARDACCEL * PHYS_MAXSPEED(self) * PHYS_INPUT_TIMELENGTH);
	else
	{
		float f = max(0, (PHYS_WARSOWBUNNY_TOPSPEED - curspeed) / (PHYS_WARSOWBUNNY_TOPSPEED - PHYS_MAXSPEED(self)));
		wishspeed = max(curspeed, PHYS_MAXSPEED(self)) + PHYS_WARSOWBUNNY_ACCEL * f * PHYS_MAXSPEED(self) * PHYS_INPUT_TIMELENGTH;
	}
	vector wishvel = wishdir * wishspeed;
	vector acceldir = wishvel - curvel;
	float addspeed = vlen(acceldir);
	acceldir = normalize(acceldir);

	float accelspeed = min(addspeed, PHYS_WARSOWBUNNY_TURNACCEL * PHYS_MAXSPEED(self) * PHYS_INPUT_TIMELENGTH);

	if (PHYS_WARSOWBUNNY_BACKTOSIDERATIO < 1)
	{
		vector curdir = normalize(curvel);
		float dot = acceldir * curdir;
		if (dot < 0)
			acceldir -= (1 - PHYS_WARSOWBUNNY_BACKTOSIDERATIO) * dot * curdir;
	}

	self.velocity += accelspeed * acceldir;
}


/*
=============
PlayerJump

When you press the jump key
returns true if handled
=============
*/
bool PlayerJump (void)
{
	if (PHYS_FROZEN(self))
		return true; // no jumping in freezetag when frozen

#ifdef SVQC
	if (self.player_blocked)
		return true; // no jumping while blocked
#endif

	bool doublejump = false;
	float mjumpheight = PHYS_JUMPVELOCITY;

#ifdef SVQC
	if (MUTATOR_CALLHOOK(PlayerJump, doublejump, mjumpheight))
#elif defined(CSQC)
	player_multijump = doublejump;
	player_jumpheight = mjumpheight;
	if (PM_multijump_checkjump())
#endif
		return true;

	doublejump = player_multijump;
	mjumpheight = player_jumpheight;

	if (PHYS_DOUBLEJUMP)
	{
		tracebox(self.origin + '0 0 0.01', self.mins, self.maxs, self.origin - '0 0 0.01', MOVE_NORMAL, self);
		if (trace_fraction < 1 && trace_plane_normal_z > 0.7)
		{
			doublejump = true;

			// we MUST clip velocity here!
			float f;
			f = self.velocity * trace_plane_normal;
			if (f < 0)
				self.velocity -= f * trace_plane_normal;
		}
	}

	if (self.waterlevel >= WATERLEVEL_SWIMMING)
	{
		self.velocity_z = PHYS_MAXSPEED(self) * 0.7;
		return true;
	}

	if (!doublejump)
		if (!IS_ONGROUND(self))
			return IS_JUMP_HELD(self);

	if (PHYS_TRACK_CANJUMP(self))
		if (IS_JUMP_HELD(self))
			return true;

	// sv_jumpspeedcap_min/sv_jumpspeedcap_max act as baseline
	// velocity bounds.  Final velocity is bound between (jumpheight *
	// min + jumpheight) and (jumpheight * max + jumpheight);

	if(PHYS_JUMPSPEEDCAP_MIN != "")
	{
		float minjumpspeed = mjumpheight * stof(PHYS_JUMPSPEEDCAP_MIN);

		if (self.velocity_z < minjumpspeed)
			mjumpheight += minjumpspeed - self.velocity_z;
	}

	if(PHYS_JUMPSPEEDCAP_MAX != "")
	{
		// don't do jump speedcaps on ramps to preserve old xonotic ramjump style
		tracebox(self.origin + '0 0 0.01', self.mins, self.maxs, self.origin - '0 0 0.01', MOVE_NORMAL, self);

		if (!(trace_fraction < 1 && trace_plane_normal_z < 0.98 && PHYS_JUMPSPEEDCAP_DISABLE_ONRAMPS))
		{
			float maxjumpspeed = mjumpheight * stof(PHYS_JUMPSPEEDCAP_MAX);

			if (self.velocity_z > maxjumpspeed)
				mjumpheight -= self.velocity_z - maxjumpspeed;
		}
	}

	if (!WAS_ONGROUND(self))
	{
#ifdef SVQC
		if(autocvar_speedmeter)
			dprint(strcat("landing velocity: ", vtos(self.velocity), " (abs: ", ftos(vlen(self.velocity)), ")\n"));
#endif
		if(self.lastground < time - 0.3)
		{
			self.velocity_x *= (1 - PHYS_FRICTION_ONLAND);
			self.velocity_y *= (1 - PHYS_FRICTION_ONLAND);
		}
#ifdef SVQC
		if(self.jumppadcount > 1)
			dprint(strcat(ftos(self.jumppadcount), "x jumppad combo\n"));
		self.jumppadcount = 0;
#endif
	}

	self.velocity_z += mjumpheight;

	UNSET_ONGROUND(self);
	SET_JUMP_HELD(self);

#ifdef SVQC

	self.oldvelocity_z = self.velocity_z;

	animdecide_setaction(self, ANIMACTION_JUMP, true);

	if (autocvar_g_jump_grunt)
		PlayerSound(playersound_jump, CH_PLAYER, VOICETYPE_PLAYERSOUND);
#endif
	return true;
}

void CheckWaterJump()
{
// check for a jump-out-of-water
	makevectors(self.v_angle);
	vector start = self.origin;
	start_z += 8;
	v_forward_z = 0;
	normalize(v_forward);
	vector end = start + v_forward*24;
	traceline (start, end, true, self);
	if (trace_fraction < 1)
	{	// solid at waist
		start_z = start_z + self.maxs_z - 8;
		end = start + v_forward*24;
		self.movedir = trace_plane_normal * -50;
		traceline(start, end, true, self);
		if (trace_fraction == 1)
		{	// open at eye level
			self.velocity_z = 225;
			self.flags |= FL_WATERJUMP;
			SET_JUMP_HELD(self);
#ifdef SVQC
			self.teleport_time = time + 2;	// safety net
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
// Hack: shouldn't need to know about this
.float multijump_count;
void CheckPlayerJump()
{
#ifdef SVQC
	float was_flying = ITEMS_STAT(self) & IT_USING_JETPACK;
#endif
	if (JETPACK_JUMP(self) < 2)
		ITEMS_STAT(self) &= ~IT_USING_JETPACK;

	if(PHYS_INPUT_BUTTON_JUMP(self) || PHYS_INPUT_BUTTON_JETPACK(self))
	{
		float air_jump = !PlayerJump() || self.multijump_count > 0; // PlayerJump() has important side effects
		float activate = JETPACK_JUMP(self) && air_jump && PHYS_INPUT_BUTTON_JUMP(self) || PHYS_INPUT_BUTTON_JETPACK(self);
		float has_fuel = !PHYS_JETPACK_FUEL || PHYS_AMMO_FUEL(self) || ITEMS_STAT(self) & IT_UNLIMITED_WEAPON_AMMO;

		if (!(ITEMS_STAT(self) & ITEM_Jetpack.m_itemid)) { }
		else if (self.jetpack_stopped) { }
		else if (!has_fuel)
		{
#ifdef SVQC
			if (was_flying) // TODO: ran out of fuel message
				Send_Notification(NOTIF_ONE, self, MSG_INFO, INFO_JETPACK_NOFUEL);
			else if (activate)
				Send_Notification(NOTIF_ONE, self, MSG_INFO, INFO_JETPACK_NOFUEL);
#endif
			self.jetpack_stopped = true;
			ITEMS_STAT(self) &= ~IT_USING_JETPACK;
		}
		else if (activate && !PHYS_FROZEN(self))
			ITEMS_STAT(self) |= IT_USING_JETPACK;
	}
	else
	{
		self.jetpack_stopped = false;
		ITEMS_STAT(self) &= ~IT_USING_JETPACK;
	}
	if (!PHYS_INPUT_BUTTON_JUMP(self))
		UNSET_JUMP_HELD(self);

	if (self.waterlevel == WATERLEVEL_SWIMMING)
		CheckWaterJump();
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

void RaceCarPhysics()
{
#ifdef SVQC
	// using this move type for "big rigs"
	// the engine does not push the entity!

	vector rigvel;

	vector angles_save = self.angles;
	float accel = bound(-1, self.movement.x / PHYS_MAXSPEED(self), 1);
	float steer = bound(-1, self.movement.y / PHYS_MAXSPEED(self), 1);

	if (g_bugrigs_reverse_speeding)
	{
		if (accel < 0)
		{
			// back accel is DIGITAL
			// to prevent speedhack
			if (accel < -0.5)
				accel = -1;
			else
				accel = 0;
		}
	}

	self.angles_x = 0;
	self.angles_z = 0;
	makevectors(self.angles); // new forward direction!

	if (IS_ONGROUND(self) || g_bugrigs_air_steering)
	{
		float myspeed = self.velocity * v_forward;
		float upspeed = self.velocity * v_up;

		// responsiveness factor for steering and acceleration
		float f = 1 / (1 + pow(max(-myspeed, myspeed) / g_bugrigs_speed_ref, g_bugrigs_speed_pow));
		//MAXIMA: f(v) := 1 / (1 + (v / g_bugrigs_speed_ref) ^ g_bugrigs_speed_pow);

		float steerfactor;
		if (myspeed < 0 && g_bugrigs_reverse_spinning)
			steerfactor = -myspeed * g_bugrigs_steer;
		else
			steerfactor = -myspeed * f * g_bugrigs_steer;

		float accelfactor;
		if (myspeed < 0 && g_bugrigs_reverse_speeding)
			accelfactor = g_bugrigs_accel;
		else
			accelfactor = f * g_bugrigs_accel;
		//MAXIMA: accel(v) := f(v) * g_bugrigs_accel;

		if (accel < 0)
		{
			if (myspeed > 0)
			{
				myspeed = max(0, myspeed - PHYS_INPUT_TIMELENGTH * (g_bugrigs_friction_floor - g_bugrigs_friction_brake * accel));
			}
			else
			{
				if (!g_bugrigs_reverse_speeding)
					myspeed = min(0, myspeed + PHYS_INPUT_TIMELENGTH * g_bugrigs_friction_floor);
			}
		}
		else
		{
			if (myspeed >= 0)
			{
				myspeed = max(0, myspeed - PHYS_INPUT_TIMELENGTH * g_bugrigs_friction_floor);
			}
			else
			{
				if (g_bugrigs_reverse_stopping)
					myspeed = 0;
				else
					myspeed = min(0, myspeed + PHYS_INPUT_TIMELENGTH * (g_bugrigs_friction_floor + g_bugrigs_friction_brake * accel));
			}
		}
		// terminal velocity = velocity at which 50 == accelfactor, that is, 1549 units/sec
		//MAXIMA: friction(v) := g_bugrigs_friction_floor;

		self.angles_y += steer * PHYS_INPUT_TIMELENGTH * steerfactor; // apply steering
		makevectors(self.angles); // new forward direction!

		myspeed += accel * accelfactor * PHYS_INPUT_TIMELENGTH;

		rigvel = myspeed * v_forward + '0 0 1' * upspeed;
	}
	else
	{
		float myspeed = vlen(self.velocity);

		// responsiveness factor for steering and acceleration
		float f = 1 / (1 + pow(max(0, myspeed / g_bugrigs_speed_ref), g_bugrigs_speed_pow));
		float steerfactor = -myspeed * f;
		self.angles_y += steer * PHYS_INPUT_TIMELENGTH * steerfactor; // apply steering

		rigvel = self.velocity;
		makevectors(self.angles); // new forward direction!
	}

	rigvel *= max(0, 1 - vlen(rigvel) * g_bugrigs_friction_air * PHYS_INPUT_TIMELENGTH);
	//MAXIMA: airfriction(v) := v * v * g_bugrigs_friction_air;
	//MAXIMA: total_acceleration(v) := accel(v) - friction(v) - airfriction(v);
	//MAXIMA: solve(total_acceleration(v) = 0, v);

	if (g_bugrigs_planar_movement)
	{
		vector rigvel_xy, neworigin, up;
		float mt;

		rigvel_z -= PHYS_INPUT_TIMELENGTH * PHYS_GRAVITY; // 4x gravity plays better
		rigvel_xy = vec2(rigvel);

		if (g_bugrigs_planar_movement_car_jumping)
			mt = MOVE_NORMAL;
		else
			mt = MOVE_NOMONSTERS;

		tracebox(self.origin, self.mins, self.maxs, self.origin + '0 0 1024', mt, self);
		up = trace_endpos - self.origin;

		// BUG RIGS: align the move to the surface instead of doing collision testing
		// can we move?
		tracebox(trace_endpos, self.mins, self.maxs, trace_endpos + rigvel_xy * PHYS_INPUT_TIMELENGTH, mt, self);

		// align to surface
		tracebox(trace_endpos, self.mins, self.maxs, trace_endpos - up + '0 0 1' * rigvel_z * PHYS_INPUT_TIMELENGTH, mt, self);

		if (trace_fraction < 0.5)
		{
			trace_fraction = 1;
			neworigin = self.origin;
		}
		else
			neworigin = trace_endpos;

		if (trace_fraction < 1)
		{
			// now set angles_x so that the car points parallel to the surface
			self.angles = vectoangles(
					'1 0 0' * v_forward_x * trace_plane_normal_z
					+
					'0 1 0' * v_forward_y * trace_plane_normal_z
					+
					'0 0 1' * -(v_forward_x * trace_plane_normal_x + v_forward_y * trace_plane_normal_y)
					);
			SET_ONGROUND(self);
		}
		else
		{
			// now set angles_x so that the car points forward, but is tilted in velocity direction
			UNSET_ONGROUND(self);
		}

		self.velocity = (neworigin - self.origin) * (1.0 / PHYS_INPUT_TIMELENGTH);
		self.movetype = MOVETYPE_NOCLIP;
	}
	else
	{
		rigvel_z -= PHYS_INPUT_TIMELENGTH * PHYS_GRAVITY; // 4x gravity plays better
		self.velocity = rigvel;
		self.movetype = MOVETYPE_FLY;
	}

	trace_fraction = 1;
	tracebox(self.origin, self.mins, self.maxs, self.origin - '0 0 4', MOVE_NORMAL, self);
	if (trace_fraction != 1)
	{
		self.angles = vectoangles2(
				'1 0 0' * v_forward_x * trace_plane_normal_z
				+
				'0 1 0' * v_forward_y * trace_plane_normal_z
				+
				'0 0 1' * -(v_forward_x * trace_plane_normal_x + v_forward_y * trace_plane_normal_y),
				trace_plane_normal
				);
	}
	else
	{
		vector vel_local;

		vel_local_x = v_forward * self.velocity;
		vel_local_y = v_right * self.velocity;
		vel_local_z = v_up * self.velocity;

		self.angles_x = racecar_angle(vel_local_x, vel_local_z);
		self.angles_z = racecar_angle(-vel_local_y, vel_local_z);
	}

	// smooth the angles
	vector vf1, vu1, smoothangles;
	makevectors(self.angles);
	float f = bound(0, PHYS_INPUT_TIMELENGTH * g_bugrigs_angle_smoothing, 1);
	if (f == 0)
		f = 1;
	vf1 = v_forward * f;
	vu1 = v_up * f;
	makevectors(angles_save);
	vf1 = vf1 + v_forward * (1 - f);
	vu1 = vu1 + v_up * (1 - f);
	smoothangles = vectoangles2(vf1, vu1);
	self.angles_x = -smoothangles_x;
	self.angles_z =  smoothangles_z;
#endif
}

string specialcommand = "xwxwxsxsxaxdxaxdx1x ";
.float specialcommand_pos;
void SpecialCommand()
{
#ifdef SVQC
#ifdef TETRIS
	TetrisImpulse();
#else
	if (!CheatImpulse(99))
		print("A hollow voice says \"Plugh\".\n");
#endif
#endif
}

float PM_check_keepaway(void)
{
#ifdef SVQC
	return (self.ballcarried && g_keepaway) ? autocvar_g_keepaway_ballcarrier_highspeed : 1;
#else
	return 1;
#endif
}

void PM_check_race_movetime(void)
{
#ifdef SVQC
	self.race_movetime_frac += PHYS_INPUT_TIMELENGTH;
	float f = floor(self.race_movetime_frac);
	self.race_movetime_frac -= f;
	self.race_movetime_count += f;
	self.race_movetime = self.race_movetime_frac + self.race_movetime_count;
#endif
}

float PM_check_specialcommand(float buttons)
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

	if (c == substring(specialcommand, self.specialcommand_pos, 1))
	{
		self.specialcommand_pos += 1;
		if (self.specialcommand_pos >= strlen(specialcommand))
		{
			self.specialcommand_pos = 0;
			SpecialCommand();
			return true;
		}
	}
	else if (self.specialcommand_pos && (c != substring(specialcommand, self.specialcommand_pos - 1, 1)))
		self.specialcommand_pos = 0;
#endif
	return false;
}

void PM_check_nickspam(void)
{
#ifdef SVQC
	if (time >= self.nickspamtime)
		return;
	if (self.nickspamcount >= autocvar_g_nick_flood_penalty_yellow)
	{
		// slight annoyance for nick change scripts
		self.movement = -1 * self.movement;
		self.BUTTON_ATCK = self.BUTTON_JUMP = self.BUTTON_ATCK2 = self.BUTTON_ZOOM = self.BUTTON_CROUCH = self.BUTTON_HOOK = self.BUTTON_USE = 0;

		if (self.nickspamcount >= autocvar_g_nick_flood_penalty_red) // if you are persistent and the slight annoyance above does not stop you, I'll show you!
		{
			self.v_angle_x = random() * 360;
			self.v_angle_y = random() * 360;
			// at least I'm not forcing retardedview by also assigning to angles_z
			self.fixangle = true;
		}
	}
#endif
}

void PM_check_punch()
{
#ifdef SVQC
	if (self.punchangle != '0 0 0')
	{
		float f = vlen(self.punchangle) - 10 * PHYS_INPUT_TIMELENGTH;
		if (f > 0)
			self.punchangle = normalize(self.punchangle) * f;
		else
			self.punchangle = '0 0 0';
	}

	if (self.punchvector != '0 0 0')
	{
		float f = vlen(self.punchvector) - 30 * PHYS_INPUT_TIMELENGTH;
		if (f > 0)
			self.punchvector = normalize(self.punchvector) * f;
		else
			self.punchvector = '0 0 0';
	}
#endif
}

void PM_check_spider(void)
{
#ifdef SVQC
	if (time >= self.spider_slowness)
		return;
	PHYS_MAXSPEED(self) *= 0.5; // half speed while slow from spider
	PHYS_MAXAIRSPEED(self) *= 0.5;
	PHYS_AIRSPEEDLIMIT_NONQW(self) *= 0.5;
	PHYS_AIRSTRAFEACCELERATE(self) *= 0.5;
#endif
}

// predict frozen movement, as frozen players CAN move in some cases
void PM_check_frozen(void)
{
	if (!PHYS_FROZEN(self))
		return;
	if (PHYS_DODGING_FROZEN
#ifdef SVQC
	&& IS_REAL_CLIENT(self)
#endif
	)
	{
		self.movement_x = bound(-5, self.movement.x, 5);
		self.movement_y = bound(-5, self.movement.y, 5);
		self.movement_z = bound(-5, self.movement.z, 5);
	}
	else
		self.movement = '0 0 0';

	vector midpoint = ((self.absmin + self.absmax) * 0.5);
	if (pointcontents(midpoint) == CONTENT_WATER)
	{
		self.velocity = self.velocity * 0.5;

		if (pointcontents(midpoint + '0 0 16') == CONTENT_WATER)
			self.velocity_z = 200;
	}
}

void PM_check_hitground()
{
#ifdef SVQC
	if (IS_ONGROUND(self))
	if (IS_PLAYER(self)) // no fall sounds for observers thank you very much
	if (self.wasFlying)
	{
		self.wasFlying = 0;
		if (self.waterlevel < WATERLEVEL_SWIMMING)
		if (time >= self.ladder_time)
		if (!self.hook)
		{
			self.nextstep = time + 0.3 + random() * 0.1;
			trace_dphitq3surfaceflags = 0;
			tracebox(self.origin, self.mins, self.maxs, self.origin - '0 0 1', MOVE_NOMONSTERS, self);
			if (!(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOSTEPS))
			{
				if (trace_dphitq3surfaceflags & Q3SURFACEFLAG_METALSTEPS)
					GlobalSound(globalsound_metalfall, CH_PLAYER, VOICETYPE_PLAYERSOUND);
				else
					GlobalSound(globalsound_fall, CH_PLAYER, VOICETYPE_PLAYERSOUND);
			}
		}
	}
#endif
}

void PM_check_blocked(void)
{
#ifdef SVQC
	if (!self.player_blocked)
		return;
	self.movement = '0 0 0';
	self.disableclientprediction = 1;
#endif
}

#ifdef SVQC
float speedaward_lastsent;
float speedaward_lastupdate;
#endif
void PM_check_race(void)
{
#ifdef SVQC
	if(!(g_cts || g_race))
		return;
	if (vlen(self.velocity - self.velocity_z * '0 0 1') > speedaward_speed)
	{
		speedaward_speed = vlen(self.velocity - self.velocity_z * '0 0 1');
		speedaward_holder = self.netname;
		speedaward_uid = self.crypto_idfp;
		speedaward_lastupdate = time;
	}
	if (speedaward_speed > speedaward_lastsent && time - speedaward_lastupdate > 1)
	{
		string rr = (g_cts) ? CTS_RECORD : RACE_RECORD;
		race_send_speedaward(MSG_ALL);
		speedaward_lastsent = speedaward_speed;
		if (speedaward_speed > speedaward_alltimebest && speedaward_uid != "")
		{
			speedaward_alltimebest = speedaward_speed;
			speedaward_alltimebest_holder = speedaward_holder;
			speedaward_alltimebest_uid = speedaward_uid;
			db_put(ServerProgsDB, strcat(GetMapname(), rr, "speed/speed"), ftos(speedaward_alltimebest));
			db_put(ServerProgsDB, strcat(GetMapname(), rr, "speed/crypto_idfp"), speedaward_alltimebest_uid);
			race_send_speedaward_alltimebest(MSG_ALL);
		}
	}
#endif
}

void PM_check_vortex(void)
{
#ifdef SVQC
	// WEAPONTODO
	float xyspeed = vlen(vec2(self.velocity));
	if (self.weapon == WEP_VORTEX.m_id && WEP_CVAR(vortex, charge) && WEP_CVAR(vortex, charge_velocity_rate) && xyspeed > WEP_CVAR(vortex, charge_minspeed))
	{
		// add a maximum of charge_velocity_rate when going fast (f = 1), gradually increasing from minspeed (f = 0) to maxspeed
	        xyspeed = min(xyspeed, WEP_CVAR(vortex, charge_maxspeed));
		float f = (xyspeed - WEP_CVAR(vortex, charge_minspeed)) / (WEP_CVAR(vortex, charge_maxspeed) - WEP_CVAR(vortex, charge_minspeed));
		// add the extra charge
		self.vortex_charge = min(1, self.vortex_charge + WEP_CVAR(vortex, charge_velocity_rate) * f * PHYS_INPUT_TIMELENGTH);
	}
#endif
}

void PM_fly(float maxspd_mod)
{
	// noclipping or flying
	UNSET_ONGROUND(self);

	self.velocity = self.velocity * (1 - PHYS_INPUT_TIMELENGTH * PHYS_FRICTION);
	makevectors(self.v_angle);
	//wishvel = v_forward * self.movement.x + v_right * self.movement.y + v_up * self.movement.z;
	vector wishvel = v_forward * self.movement.x
					+ v_right * self.movement.y
					+ '0 0 1' * self.movement.z;
	// acceleration
	vector wishdir = normalize(wishvel);
	float wishspeed = min(vlen(wishvel), PHYS_MAXSPEED(self) * maxspd_mod);
#ifdef SVQC
	if (time >= self.teleport_time)
#endif
		PM_Accelerate(wishdir, wishspeed, wishspeed, PHYS_ACCELERATE * maxspd_mod, 1, 0, 0, 0);
	PM_ClientMovement_Move();
}

void PM_swim(float maxspd_mod)
{
	// swimming
	UNSET_ONGROUND(self);

	float jump = PHYS_INPUT_BUTTON_JUMP(self);
	// water jump only in certain situations
	// this mimics quakeworld code
	if (jump && self.waterlevel == WATERLEVEL_SWIMMING && self.velocity_z >= -180)
	{
		vector yawangles = '0 1 0' * self.v_angle.y;
		makevectors(yawangles);
		vector forward = v_forward;
		vector spot = self.origin + 24 * forward;
		spot_z += 8;
		traceline(spot, spot, MOVE_NOMONSTERS, self);
		if (trace_startsolid)
		{
			spot_z += 24;
			traceline(spot, spot, MOVE_NOMONSTERS, self);
			if (!trace_startsolid)
			{
				self.velocity = forward * 50;
				self.velocity_z = 310;
				pmove_waterjumptime = 2;
				UNSET_ONGROUND(self);
				SET_JUMP_HELD(self);
			}
		}
	}
	makevectors(self.v_angle);
	//wishvel = v_forward * self.movement.x + v_right * self.movement.y + v_up * self.movement.z;
	vector wishvel = v_forward * self.movement.x
					+ v_right * self.movement.y
					+ '0 0 1' * self.movement.z;
	if (wishvel == '0 0 0')
		wishvel = '0 0 -60'; // drift towards bottom

	vector wishdir = normalize(wishvel);
	float wishspeed = min(vlen(wishvel), PHYS_MAXSPEED(self) * maxspd_mod) * 0.7;

	if (IS_DUCKED(self))
    	wishspeed *= 0.5;

//	if (pmove_waterjumptime <= 0) // TODO: use
    {
		// water friction
		float f = 1 - PHYS_INPUT_TIMELENGTH * PHYS_FRICTION;
		f = min(max(0, f), 1);
		self.velocity *= f;

		f = wishspeed - self.velocity * wishdir;
		if (f > 0)
		{
			float accelspeed = min(PHYS_ACCELERATE * PHYS_INPUT_TIMELENGTH * wishspeed, f);
			self.velocity += accelspeed * wishdir;
		}

		// holding jump button swims upward slowly
		if (jump)
		{
#if 0
			if (self.watertype & CONTENT_LAVA)
				self.velocity_z =  50;
			else if (self.watertype & CONTENT_SLIME)
				self.velocity_z =  80;
			else
			{
				if (IS_NEXUIZ_DERIVED(gamemode))
#endif
					self.velocity_z = 200;
#if 0
				else
					self.velocity_z = 100;
			}
#endif
		}
	}
	// water acceleration
	PM_Accelerate(wishdir, wishspeed, wishspeed, PHYS_ACCELERATE * maxspd_mod, 1, 0, 0, 0);
	PM_ClientMovement_Move();
}

void PM_ladder(float maxspd_mod)
{
	// on a spawnfunc_func_ladder or swimming in spawnfunc_func_water
	UNSET_ONGROUND(self);

	float g;
	g = PHYS_GRAVITY * PHYS_INPUT_TIMELENGTH;
	if (PHYS_ENTGRAVITY(self))
		g *= PHYS_ENTGRAVITY(self);
	if (GAMEPLAYFIX_GRAVITYUNAFFECTEDBYTICRATE)
	{
		g *= 0.5;
		self.velocity_z += g;
	}

	self.velocity = self.velocity * (1 - PHYS_INPUT_TIMELENGTH * PHYS_FRICTION);
	makevectors(self.v_angle);
	//wishvel = v_forward * self.movement.x + v_right * self.movement.y + v_up * self.movement.z;
	vector wishvel = v_forward * self.movement_x
					+ v_right * self.movement_y
					+ '0 0 1' * self.movement_z;
	self.velocity_z += g;
	if (self.ladder_entity.classname == "func_water")
	{
		float f = vlen(wishvel);
		if (f > self.ladder_entity.speed)
			wishvel *= (self.ladder_entity.speed / f);

		self.watertype = self.ladder_entity.skin;
		f = self.ladder_entity.origin_z + self.ladder_entity.maxs_z;
		if ((self.origin_z + self.view_ofs_z) < f)
			self.waterlevel = WATERLEVEL_SUBMERGED;
		else if ((self.origin_z + (self.mins_z + self.maxs_z) * 0.5) < f)
			self.waterlevel = WATERLEVEL_SWIMMING;
		else if ((self.origin_z + self.mins_z + 1) < f)
			self.waterlevel = WATERLEVEL_WETFEET;
		else
		{
			self.waterlevel = WATERLEVEL_NONE;
			self.watertype = CONTENT_EMPTY;
		}
	}
	// acceleration
	vector wishdir = normalize(wishvel);
	float wishspeed = min(vlen(wishvel), PHYS_MAXSPEED(self) * maxspd_mod);
#ifdef SVQC
	if (time >= self.teleport_time)
#endif
		// water acceleration
		PM_Accelerate(wishdir, wishspeed, wishspeed, PHYS_ACCELERATE*maxspd_mod, 1, 0, 0, 0);
	PM_ClientMovement_Move();
}

void PM_jetpack(float maxspd_mod)
{
	//makevectors(self.v_angle.y * '0 1 0');
	makevectors(self.v_angle);
	vector wishvel = v_forward * self.movement_x
					+ v_right * self.movement_y;
	// add remaining speed as Z component
	float maxairspd = PHYS_MAXAIRSPEED(self) * max(1, maxspd_mod);
	// fix speedhacks :P
	wishvel = normalize(wishvel) * min(1, vlen(wishvel) / maxairspd);
	// add the unused velocity as up component
	wishvel_z = 0;

	// if (self.BUTTON_JUMP)
		wishvel_z = sqrt(max(0, 1 - wishvel * wishvel));

	// it is now normalized, so...
	float a_side = PHYS_JETPACK_ACCEL_SIDE;
	float a_up = PHYS_JETPACK_ACCEL_UP;
	float a_add = PHYS_JETPACK_ANTIGRAVITY * PHYS_GRAVITY;

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
	fxy = bound(0, 1 - (self.velocity * normalize(wishvel_x * '1 0 0' + wishvel_y * '0 1 0')) / PHYS_JETPACK_MAXSPEED_SIDE, 1);
	if (wishvel_z - PHYS_GRAVITY > 0)
		fz = bound(0, 1 - self.velocity_z / PHYS_JETPACK_MAXSPEED_UP, 1);
	else
		fz = bound(0, 1 + self.velocity_z / PHYS_JETPACK_MAXSPEED_UP, 1);

	float fvel;
	fvel = vlen(wishvel);
	wishvel_x *= fxy;
	wishvel_y *= fxy;
	wishvel_z = (wishvel_z - PHYS_GRAVITY) * fz + PHYS_GRAVITY;

	fvel = min(1, vlen(wishvel) / best);
	if (PHYS_JETPACK_FUEL && !(ITEMS_STAT(self) & IT_UNLIMITED_WEAPON_AMMO))
		f = min(1, PHYS_AMMO_FUEL(self) / (PHYS_JETPACK_FUEL * PHYS_INPUT_TIMELENGTH * fvel));
	else
		f = 1;

	//print("this acceleration: ", ftos(vlen(wishvel) * f), "\n");

	if (f > 0 && wishvel != '0 0 0')
	{
		self.velocity = self.velocity + wishvel * f * PHYS_INPUT_TIMELENGTH;
		UNSET_ONGROUND(self);

#ifdef SVQC
		if (!(ITEMS_STAT(self) & IT_UNLIMITED_WEAPON_AMMO))
			self.ammo_fuel -= PHYS_JETPACK_FUEL * PHYS_INPUT_TIMELENGTH * fvel * f;

		ITEMS_STAT(self) |= IT_USING_JETPACK;

		// jetpack also inhibits health regeneration, but only for 1 second
		self.pauseregen_finished = max(self.pauseregen_finished, time + autocvar_g_balance_pause_fuel_regen);
#endif
	}

#ifdef CSQC
	float g = PHYS_GRAVITY * PHYS_ENTGRAVITY(self) * PHYS_INPUT_TIMELENGTH;
	if (GAMEPLAYFIX_GRAVITYUNAFFECTEDBYTICRATE)
		self.velocity_z -= g * 0.5;
	else
		self.velocity_z -= g;
	PM_ClientMovement_Move();
	if (!IS_ONGROUND(self) || !(GAMEPLAYFIX_NOGRAVITYONGROUND))
		if (GAMEPLAYFIX_GRAVITYUNAFFECTEDBYTICRATE)
			self.velocity_z -= g * 0.5;
#endif
}

void PM_walk(float buttons_prev, float maxspd_mod)
{
	if (!WAS_ONGROUND(self))
	{
#ifdef SVQC
		if (autocvar_speedmeter)
			dprint(strcat("landing velocity: ", vtos(self.velocity), " (abs: ", ftos(vlen(self.velocity)), ")\n"));
#endif
		if (self.lastground < time - 0.3)
			self.velocity *= (1 - PHYS_FRICTION_ONLAND);
#ifdef SVQC
		if (self.jumppadcount > 1)
			dprint(strcat(ftos(self.jumppadcount), "x jumppad combo\n"));
		self.jumppadcount = 0;
#endif
	}

	// walking
	makevectors(self.v_angle.y * '0 1 0');
	vector wishvel = v_forward * self.movement.x
					+ v_right * self.movement.y;
	// acceleration
	vector wishdir = normalize(wishvel);
	float wishspeed = vlen(wishvel);

	wishspeed = min(wishspeed, PHYS_MAXSPEED(self) * maxspd_mod);
	if (IS_DUCKED(self))
		wishspeed *= 0.5;

	// apply edge friction
	float f = vlen(vec2(self.velocity));
	if (f > 0)
	{
		float realfriction;
		trace_dphitq3surfaceflags = 0;
		tracebox(self.origin, self.mins, self.maxs, self.origin - '0 0 1', MOVE_NOMONSTERS, self);
		// TODO: apply edge friction
		// apply ground friction
		if(trace_dphitq3surfaceflags & Q3SURFACEFLAG_SLICK)
			realfriction = PHYS_FRICTION_SLICK;
		else
			realfriction = PHYS_FRICTION;

		f = 1 - PHYS_INPUT_TIMELENGTH * realfriction * ((f < PHYS_STOPSPEED) ? (PHYS_STOPSPEED / f) : 1);
		f = max(0, f);
		self.velocity *= f;
		/*
		   Mathematical analysis time!

		   Our goal is to invert this mess.

		   For the two cases we get:
			v = v0 * (1 - PHYS_INPUT_TIMELENGTH * (PHYS_STOPSPEED / v0) * PHYS_FRICTION)
			  = v0 - PHYS_INPUT_TIMELENGTH * PHYS_STOPSPEED * PHYS_FRICTION
			v0 = v + PHYS_INPUT_TIMELENGTH * PHYS_STOPSPEED * PHYS_FRICTION
		   and
			v = v0 * (1 - PHYS_INPUT_TIMELENGTH * PHYS_FRICTION)
			v0 = v / (1 - PHYS_INPUT_TIMELENGTH * PHYS_FRICTION)

		   These cases would be chosen ONLY if:
			v0 < PHYS_STOPSPEED
			v + PHYS_INPUT_TIMELENGTH * PHYS_STOPSPEED * PHYS_FRICTION < PHYS_STOPSPEED
			v < PHYS_STOPSPEED * (1 - PHYS_INPUT_TIMELENGTH * PHYS_FRICTION)
		   and, respectively:
			v0 >= PHYS_STOPSPEED
			v / (1 - PHYS_INPUT_TIMELENGTH * PHYS_FRICTION) >= PHYS_STOPSPEED
			v >= PHYS_STOPSPEED * (1 - PHYS_INPUT_TIMELENGTH * PHYS_FRICTION)
		 */
	}
	float addspeed = wishspeed - self.velocity * wishdir;
	if (addspeed > 0)
	{
		float accelspeed = min(PHYS_ACCELERATE * PHYS_INPUT_TIMELENGTH * wishspeed, addspeed);
		self.velocity += accelspeed * wishdir;
	}
	float g = PHYS_GRAVITY * PHYS_ENTGRAVITY(self) * PHYS_INPUT_TIMELENGTH;
	if (!(GAMEPLAYFIX_NOGRAVITYONGROUND))
		self.velocity_z -= g * (GAMEPLAYFIX_GRAVITYUNAFFECTEDBYTICRATE ? 0.5 : 1);
	if (self.velocity * self.velocity)
		PM_ClientMovement_Move();
	if (GAMEPLAYFIX_GRAVITYUNAFFECTEDBYTICRATE)
		if (!IS_ONGROUND(self) || !GAMEPLAYFIX_NOGRAVITYONGROUND)
			self.velocity_z -= g * 0.5;
}

void PM_air(float buttons_prev, float maxspd_mod)
{
	makevectors(self.v_angle.y * '0 1 0');
	vector wishvel = v_forward * self.movement.x
					+ v_right * self.movement.y;
	// acceleration
	vector wishdir = normalize(wishvel);
	float wishspeed = vlen(wishvel);

#ifdef SVQC
	if (time >= self.teleport_time)
#else
	if (pmove_waterjumptime <= 0)
#endif
	{
		float maxairspd = PHYS_MAXAIRSPEED(self) * min(maxspd_mod, 1);

		// apply air speed limit
		float airaccelqw = PHYS_AIRACCEL_QW(self);
		float wishspeed0 = wishspeed;
		wishspeed = min(wishspeed, maxairspd);
		if (IS_DUCKED(self))
			wishspeed *= 0.5;
		float airaccel = PHYS_AIRACCELERATE * min(maxspd_mod, 1);

		float accelerating = (self.velocity * wishdir > 0);
		float wishspeed2 = wishspeed;

		// CPM: air control
		if (PHYS_AIRSTOPACCELERATE)
		{
			vector curdir = normalize(vec2(self.velocity));
			airaccel += (PHYS_AIRSTOPACCELERATE*maxspd_mod - airaccel) * max(0, -(curdir * wishdir));
		}
		// note that for straight forward jumping:
		// step = accel * PHYS_INPUT_TIMELENGTH * wishspeed0;
		// accel  = bound(0, wishspeed - vel_xy_current, step) * accelqw + step * (1 - accelqw);
		// -->
		// dv/dt = accel * maxspeed (when slow)
		// dv/dt = accel * maxspeed * (1 - accelqw) (when fast)
		// log dv/dt = logaccel + logmaxspeed (when slow)
		// log dv/dt = logaccel + logmaxspeed + log(1 - accelqw) (when fast)
		float strafity = IsMoveInDirection(self.movement, -90) + IsMoveInDirection(self.movement, +90); // if one is nonzero, other is always zero
		if (PHYS_MAXAIRSTRAFESPEED)
			wishspeed = min(wishspeed, GeomLerp(PHYS_MAXAIRSPEED(self)*maxspd_mod, strafity, PHYS_MAXAIRSTRAFESPEED*maxspd_mod));
		if (PHYS_AIRSTRAFEACCELERATE(self))
			airaccel = GeomLerp(airaccel, strafity, PHYS_AIRSTRAFEACCELERATE(self)*maxspd_mod);
		if (PHYS_AIRSTRAFEACCEL_QW(self))
			airaccelqw =
            	(((strafity > 0.5 ? PHYS_AIRSTRAFEACCEL_QW(self) : PHYS_AIRACCEL_QW(self)) >= 0) ? +1 : -1)
            	*
            	(1 - GeomLerp(1 - fabs(PHYS_AIRACCEL_QW(self)), strafity, 1 - fabs(PHYS_AIRSTRAFEACCEL_QW(self))));
		// !CPM

		if (PHYS_WARSOWBUNNY_TURNACCEL && accelerating && self.movement.y == 0 && self.movement.x != 0)
			PM_AirAccelerate(wishdir, wishspeed2);
		else
			PM_Accelerate(wishdir, wishspeed, wishspeed0, airaccel, airaccelqw, PHYS_AIRACCEL_QW_STRETCHFACTOR(self), PHYS_AIRACCEL_SIDEWAYS_FRICTION / maxairspd, PHYS_AIRSPEEDLIMIT_NONQW(self));

		if (PHYS_AIRCONTROL)
			CPM_PM_Aircontrol(wishdir, wishspeed2);
	}
	float g = PHYS_GRAVITY * PHYS_ENTGRAVITY(self) * PHYS_INPUT_TIMELENGTH;
	if (GAMEPLAYFIX_GRAVITYUNAFFECTEDBYTICRATE)
		self.velocity_z -= g * 0.5;
	else
		self.velocity_z -= g;
	PM_ClientMovement_Move();
	if (!IS_ONGROUND(self) || !(GAMEPLAYFIX_NOGRAVITYONGROUND))
		if (GAMEPLAYFIX_GRAVITYUNAFFECTEDBYTICRATE)
			self.velocity_z -= g * 0.5;
}

// used for calculating airshots
bool IsFlying(entity a)
{
	if(IS_ONGROUND(a))
		return false;
	if(a.waterlevel >= WATERLEVEL_SWIMMING)
		return false;
	traceline(a.origin, a.origin - '0 0 48', MOVE_NORMAL, a);
	if(trace_fraction < 1)
		return false;
	return true;
}

void PM_Main()
{
	int buttons = PHYS_INPUT_BUTTON_MASK(self);
#ifdef CSQC
	self.items = getstati(STAT_ITEMS, 0, 24);

	self.movement = PHYS_INPUT_MOVEVALUES(self);

	vector oldv_angle = self.v_angle;
	vector oldangles = self.angles; // we need to save these, as they're abused by other code
	self.v_angle = PHYS_INPUT_ANGLES(self);
	self.angles = PHYS_WORLD_ANGLES(self);

	self.team = myteam + 1; // is this correct?
	if (!(PHYS_INPUT_BUTTON_JUMP(self))) // !jump
		UNSET_JUMP_HELD(self); // canjump = true
	pmove_waterjumptime -= PHYS_INPUT_TIMELENGTH;

	PM_ClientMovement_UpdateStatus(true);
#endif
	

#ifdef SVQC
	WarpZone_PlayerPhysics_FixVAngle();
#endif
	float maxspeed_mod = 1;
	maxspeed_mod *= PM_check_keepaway();
	maxspeed_mod *= PHYS_HIGHSPEED;

#ifdef SVQC
	Physics_UpdateStats(maxspeed_mod);

	if (self.PlayerPhysplug)
		if (self.PlayerPhysplug())
			return;
#endif

	PM_check_race_movetime();
#ifdef SVQC
	anticheat_physics();
#endif

	if (PM_check_specialcommand(buttons))
		return;
#ifdef SVQC
	if (sv_maxidle > 0)
	{
		if (buttons != self.buttons_old || self.movement != self.movement_old || self.v_angle != self.v_angle_old)
			self.parm_idlesince = time;
	}
#endif
	int buttons_prev = self.buttons_old;
	self.buttons_old = buttons;
	self.movement_old = self.movement;
	self.v_angle_old = self.v_angle;

	PM_check_nickspam();

	PM_check_punch();
#ifdef SVQC
	if (IS_BOT_CLIENT(self))
	{
		if (playerdemo_read())
			return;
		bot_think();
	}

	if (IS_PLAYER(self))
#endif
	{
#ifdef SVQC
		if (self.race_penalty)
			if (time > self.race_penalty)
				self.race_penalty = 0;
#endif

		bool not_allowed_to_move = false;
#ifdef SVQC
		if (self.race_penalty)
			not_allowed_to_move = true;
#endif
#ifdef SVQC
		if (time < game_starttime)
			not_allowed_to_move = true;
#endif

		if (not_allowed_to_move)
		{
			self.velocity = '0 0 0';
			self.movetype = MOVETYPE_NONE;
#ifdef SVQC
			self.disableclientprediction = 2;
#endif
		}
#ifdef SVQC
		else if (self.disableclientprediction == 2)
		{
			if (self.movetype == MOVETYPE_NONE)
				self.movetype = MOVETYPE_WALK;
			self.disableclientprediction = 0;
		}
#endif
	}

#ifdef SVQC
	if (self.movetype == MOVETYPE_NONE)
		return;

	// when we get here, disableclientprediction cannot be 2
	self.disableclientprediction = 0;
#endif

	viewloc_PlayerPhysics();

	PM_check_spider();

	PM_check_frozen();

	PM_check_blocked();

	maxspeed_mod = 1;

	if (self.in_swamp)
		maxspeed_mod *= self.swamp_slowdown; //cvar("g_balance_swamp_moverate");

	// conveyors: first fix velocity
	if (self.conveyor.state)
		self.velocity -= self.conveyor.movedir;

#ifdef SVQC
	MUTATOR_CALLHOOK(PlayerPhysics);
#endif
#ifdef CSQC
	PM_multijump();
#endif

//	float forcedodge = 1;
//	if(forcedodge) {
//#ifdef CSQC
//		PM_dodging_checkpressedkeys();
//#endif
//		PM_dodging();
//		PM_ClientMovement_Move();
//		return;
//	}

#ifdef SVQC
	if (!IS_PLAYER(self))
	{
		maxspeed_mod = autocvar_sv_spectator_speed_multiplier;
		if (!self.spectatorspeed)
			self.spectatorspeed = maxspeed_mod;
		if (self.impulse && self.impulse <= 19 || (self.impulse >= 200 && self.impulse <= 209) || (self.impulse >= 220 && self.impulse <= 229))
		{
			if (self.lastclassname != "player")
			{
				if (self.impulse == 10 || self.impulse == 15 || self.impulse == 18 || (self.impulse >= 200 && self.impulse <= 209))
					self.spectatorspeed = bound(1, self.spectatorspeed + 0.5, 5);
				else if (self.impulse == 11)
					self.spectatorspeed = maxspeed_mod;
				else if (self.impulse == 12 || self.impulse == 16  || self.impulse == 19 || (self.impulse >= 220 && self.impulse <= 229))
					self.spectatorspeed = bound(1, self.spectatorspeed - 0.5, 5);
				else if (self.impulse >= 1 && self.impulse <= 9)
					self.spectatorspeed = 1 + 0.5 * (self.impulse - 1);
			} // otherwise just clear
			self.impulse = 0;
		}
		maxspeed_mod = self.spectatorspeed;
	}

	float spd = max(PHYS_MAXSPEED(self), PHYS_MAXAIRSPEED(self)) * maxspeed_mod;
	if(self.speed != spd)
	{
		self.speed = spd;
		string temps = ftos(spd);
		stuffcmd(self, strcat("cl_forwardspeed ", temps, "\n"));
		stuffcmd(self, strcat("cl_backspeed ", temps, "\n"));
		stuffcmd(self, strcat("cl_sidespeed ", temps, "\n"));
		stuffcmd(self, strcat("cl_upspeed ", temps, "\n"));
	}

	if(self.stat_jumpspeedcap_min != PHYS_JUMPSPEEDCAP_MIN)
	{
		self.stat_jumpspeedcap_min = PHYS_JUMPSPEEDCAP_MIN;
		stuffcmd(self, strcat("cl_jumpspeedcap_min ", PHYS_JUMPSPEEDCAP_MIN, "\n"));
	}
	if(self.stat_jumpspeedcap_max != PHYS_JUMPSPEEDCAP_MAX)
	{
		self.stat_jumpspeedcap_min = PHYS_JUMPSPEEDCAP_MAX;
		stuffcmd(self, strcat("cl_jumpspeedcap_max ", PHYS_JUMPSPEEDCAP_MAX, "\n"));
	}
#endif

	if(PHYS_DEAD(self))
	{
		// handle water here
		vector midpoint = ((self.absmin + self.absmax) * 0.5);
		if(pointcontents(midpoint) == CONTENT_WATER)
		{
			self.velocity = self.velocity * 0.5;

			// do we want this?
			//if(pointcontents(midpoint + '0 0 2') == CONTENT_WATER)
				//{ self.velocity_z = 70; }
		}
		goto end;
	}

#ifdef SVQC
	if (!self.fixangle && !g_bugrigs)
		self.angles = '0 1 0' * self.v_angle.y;
#endif

	PM_check_hitground();

	if(IsFlying(self))
		self.wasFlying = 1;

	if (IS_PLAYER(self))
		CheckPlayerJump();

	if (self.flags & FL_WATERJUMP)
	{
		self.velocity_x = self.movedir_x;
		self.velocity_y = self.movedir_y;
		if (time > self.teleport_time || self.waterlevel == WATERLEVEL_NONE)
		{
			self.flags &= ~FL_WATERJUMP;
			self.teleport_time = 0;
		}
	}

#ifdef SVQC
	else if (g_bugrigs && IS_PLAYER(self))
		RaceCarPhysics();
#endif

	else if (self.movetype == MOVETYPE_NOCLIP || self.movetype == MOVETYPE_FLY || self.movetype == MOVETYPE_FLY_WORLDONLY || (BUFFS_STAT(self) & BUFF_FLIGHT.m_itemid))
		PM_fly(maxspeed_mod);

	else if (self.waterlevel >= WATERLEVEL_SWIMMING)
		PM_swim(maxspeed_mod);

	else if (time < self.ladder_time)
		PM_ladder(maxspeed_mod);

	else if (ITEMS_STAT(self) & IT_USING_JETPACK)
		PM_jetpack(maxspeed_mod);

	else if (IS_ONGROUND(self))
		PM_walk(buttons_prev, maxspeed_mod);

	else
		PM_air(buttons_prev, maxspeed_mod);

#ifdef SVQC
	if (!IS_OBSERVER(self))
		PM_check_race();
#endif
	PM_check_vortex();

:end
	if (IS_ONGROUND(self))
		self.lastground = time;

	// conveyors: then break velocity again
	if(self.conveyor.state)
		self.velocity += self.conveyor.movedir;

	self.lastflags = self.flags;

	self.lastclassname = self.classname;

#ifdef CSQC
	self.v_angle = oldv_angle;
	self.angles = oldangles;
#endif
}

#ifdef SVQC
void SV_PlayerPhysics(void)
#elif defined(CSQC)
void CSQC_ClientMovement_PlayerMove_Frame(void)
#endif
{
	PM_Main();

#ifdef CSQC
	self.pmove_flags = 
			((self.flags & FL_DUCKED) ? PMF_DUCKED : 0) |
			(!(self.flags & FL_JUMPRELEASED) ? 0 : PMF_JUMP_HELD) |
			((self.flags & FL_ONGROUND) ? PMF_ONGROUND : 0);
#endif
}
