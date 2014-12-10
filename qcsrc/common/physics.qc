.float race_penalty;
.float restart_jump;

.float ladder_time;
.entity ladder_entity;
.float gravity;
.float swamp_slowdown;
.float lastflags;
.float lastground;
.float wasFlying;
.float spectatorspeed;

.vector movement_old;
.float buttons_old;
.vector v_angle_old;
.string lastclassname;

.float() PlayerPhysplug;
float AdjustAirAccelQW(float accelqw, float factor);

#ifdef SVQC
.float stat_dodging_frozen;
.float stat_sv_airaccel_qw;
.float stat_sv_airstrafeaccel_qw;
.float stat_sv_airspeedlimit_nonqw;
.float stat_sv_maxspeed;
.float stat_movement_highspeed;

.float stat_jetpack_accel_side;
.float stat_jetpack_accel_up;
.float stat_jetpack_antigravity;
.float stat_jetpack_fuel;
.float stat_jetpack_maxspeed_up;
.float stat_jetpack_maxspeed_side;

void Physics_AddStats()
{
	// g_movementspeed hack
	addstat(STAT_MOVEVARS_AIRSPEEDLIMIT_NONQW, AS_FLOAT, stat_sv_airspeedlimit_nonqw);
	addstat(STAT_MOVEVARS_MAXSPEED, AS_FLOAT, stat_sv_maxspeed);
	addstat(STAT_MOVEVARS_AIRACCEL_QW, AS_FLOAT, stat_sv_airaccel_qw);
	addstat(STAT_MOVEVARS_AIRSTRAFEACCEL_QW, AS_FLOAT, stat_sv_airstrafeaccel_qw);
	addstat(STAT_MOVEVARS_HIGHSPEED, AS_FLOAT, stat_movement_highspeed);

	// dodging
	addstat(STAT_DODGING_FROZEN, AS_INT, stat_dodging_frozen);

	// jet pack
	addstat(STAT_JETPACK_ACCEL_SIDE, AS_FLOAT, stat_jetpack_accel_side);
	addstat(STAT_JETPACK_ACCEL_UP, AS_FLOAT, stat_jetpack_accel_up);
	addstat(STAT_JETPACK_ANTIGRAVITY, AS_FLOAT, stat_jetpack_antigravity);
	addstat(STAT_JETPACK_FUEL, AS_FLOAT, stat_jetpack_fuel);
	addstat(STAT_JETPACK_MAXSPEED_UP, AS_FLOAT, stat_jetpack_maxspeed_up);
	addstat(STAT_JETPACK_MAXSPEED_SIDE, AS_FLOAT, stat_jetpack_maxspeed_side);
}
#endif

// Client/server mappings
#ifdef CSQC
.float watertype;

	#define PHYS_INPUT_ANGLES(s)   				input_angles
	#define PHYS_INPUT_BUTTONS(s)   			input_buttons
	#define PHYS_INPUT_TIMELENGTH				input_timelength
	#define PHYS_INPUT_MOVEVALUES(s)			input_movevalues

	#define GAMEPLAYFIX_GRAVITYUNAFFECTEDBYTICRATE	moveflags & MOVEFLAG_GRAVITYUNAFFECTEDBYTICRATE
	#define GAMEPLAYFIX_NOGRAVITYONGROUND			cvar("sv_gameplayfix_nogravityonground")
	#define GAMEPLAYFIX_Q2AIRACCELERATE				moveflags & MOVEFLAG_Q2AIRACCELERATE

	#define IS_DUCKED(s)    					(s.pmove_flags & PMF_DUCKED)
	#define SET_DUCKED(s)   					s.pmove_flags |= PMF_DUCKED
	#define UNSET_DUCKED(s) 					s.pmove_flags &= ~PMF_DUCKED

	#define IS_JUMP_HELD(s)    					(s.pmove_flags & PMF_JUMP_HELD)
	#define SET_JUMP_HELD(s)   					s.pmove_flags |= PMF_JUMP_HELD
	#define UNSET_JUMP_HELD(s) 					s.pmove_flags &= ~PMF_JUMP_HELD

	#define IS_ONGROUND(s)    					(s.pmove_flags & PMF_ONGROUND)
	#define SET_ONGROUND(s)   					s.pmove_flags |= PMF_ONGROUND
	#define UNSET_ONGROUND(s) 					s.pmove_flags &= ~PMF_ONGROUND

	#define ITEMS(s) 							getstati(STAT_ITEMS, 0, 24)
	#define PHYS_AMMO_FUEL(s)					getstati(STAT_FUEL)
	#define PHYS_FROZEN(s)						getstati(STAT_FROZEN)

	#define PHYS_ACCELERATE						getstatf(STAT_MOVEVARS_ACCELERATE)
	#define PHYS_AIRACCEL_QW(s)					getstatf(STAT_MOVEVARS_AIRACCEL_QW)
	#define PHYS_AIRACCEL_QW_STRETCHFACTOR(s)	getstatf(STAT_MOVEVARS_AIRACCEL_QW_STRETCHFACTOR)
	#define PHYS_AIRACCEL_SIDEWAYS_FRICTION		getstatf(STAT_MOVEVARS_AIRACCEL_SIDEWAYS_FRICTION)
	#define PHYS_AIRACCELERATE					getstatf(STAT_MOVEVARS_AIRACCELERATE)
	#define PHYS_AIRCONTROL						getstatf(STAT_MOVEVARS_AIRCONTROL)
	#define PHYS_AIRCONTROL_PENALTY				getstatf(STAT_MOVEVARS_AIRCONTROL_PENALTY)
	#define PHYS_AIRCONTROL_POWER				getstatf(STAT_MOVEVARS_AIRCONTROL_POWER)
	#define PHYS_AIRSPEEDLIMIT_NONQW(s)			getstatf(STAT_MOVEVARS_AIRSPEEDLIMIT_NONQW)
	#define PHYS_AIRSTOPACCELERATE				getstatf(STAT_MOVEVARS_AIRSTOPACCELERATE)
	#define PHYS_AIRSTRAFEACCEL_QW(s)			getstatf(STAT_MOVEVARS_AIRSTRAFEACCEL_QW)
	#define PHYS_AIRSTRAFEACCELERATE			getstatf(STAT_MOVEVARS_AIRSTRAFEACCELERATE)
	#define PHYS_ENTGRAVITY(s)					getstatf(STAT_MOVEVARS_ENTGRAVITY)
	#define PHYS_FRICTION						getstatf(STAT_MOVEVARS_FRICTION)
	#define PHYS_GRAVITY						getstatf(STAT_MOVEVARS_GRAVITY)
	#define PHYS_HIGHSPEED						getstatf(STAT_MOVEVARS_HIGHSPEED)
	#define PHYS_JUMPVELOCITY					getstatf(STAT_MOVEVARS_JUMPVELOCITY)
	#define PHYS_MAXAIRSPEED					getstatf(STAT_MOVEVARS_MAXAIRSPEED)
	#define PHYS_MAXAIRSTRAFESPEED				getstatf(STAT_MOVEVARS_MAXAIRSTRAFESPEED)
	#define PHYS_MAXSPEED(s)					getstatf(STAT_MOVEVARS_MAXSPEED)
	#define PHYS_STEPHEIGHT						getstatf(STAT_MOVEVARS_STEPHEIGHT)
	#define PHYS_STOPSPEED						getstatf(STAT_MOVEVARS_STOPSPEED)
	#define PHYS_WARSOWBUNNY_ACCEL				getstatf(STAT_MOVEVARS_WARSOWBUNNY_ACCEL)
	#define PHYS_WARSOWBUNNY_BACKTOSIDERATIO	getstatf(STAT_MOVEVARS_WARSOWBUNNY_BACKTOSIDERATIO)
	#define PHYS_WARSOWBUNNY_AIRFORWARDACCEL	getstatf(STAT_MOVEVARS_WARSOWBUNNY_AIRFORWARDACCEL)
	#define PHYS_WARSOWBUNNY_TOPSPEED			getstatf(STAT_MOVEVARS_WARSOWBUNNY_TOPSPEED)
	#define PHYS_WARSOWBUNNY_TURNACCEL			getstatf(STAT_MOVEVARS_WARSOWBUNNY_TURNACCEL)

	#define PHYS_JETPACK_ACCEL_UP 				getstatf(STAT_JETPACK_ACCEL_UP)
	#define PHYS_JETPACK_ACCEL_SIDE 			getstatf(STAT_JETPACK_ACCEL_SIDE)
	#define PHYS_JETPACK_ANTIGRAVITY 			getstatf(STAT_JETPACK_ANTIGRAVITY)
	#define PHYS_JETPACK_FUEL					getstatf(STAT_JETPACK_FUEL)
	#define PHYS_JETPACK_MAXSPEED_UP			getstatf(STAT_JETPACK_MAXSPEED_UP)
	#define PHYS_JETPACK_MAXSPEED_SIDE			getstatf(STAT_JETPACK_MAXSPEED_SIDE)

	#define PHYS_BUTTON_HOOK(s)					(input_buttons & 32)

	#define PHYS_DODGING_FROZEN					getstati(STAT_DODGING_FROZEN)

#elif defined(SVQC)

	#define PHYS_INPUT_ANGLES(s)				s.v_angle
	// TODO: cache
	#define PHYS_INPUT_BUTTONS(s)   			(s.BUTTON_ATCK + 2 * s.BUTTON_JUMP + 4 * s.BUTTON_ATCK2 + 8 * s.BUTTON_ZOOM + 16 * s.BUTTON_CROUCH + 32 * s.BUTTON_HOOK + 64 * s.BUTTON_USE + 128 * (s.movement_x < 0) + 256 * (s.movement_x > 0) + 512 * (s.movement_y < 0) + 1024 * (s.movement_y > 0))
	#define PHYS_INPUT_TIMELENGTH				frametime
	#define PHYS_INPUT_MOVEVALUES(s)			s.movement

	#define GAMEPLAYFIX_GRAVITYUNAFFECTEDBYTICRATE	autocvar_sv_gameplayfix_gravityunaffectedbyticrate
	#define GAMEPLAYFIX_NOGRAVITYONGROUND			cvar("sv_gameplayfix_nogravityonground")
	#define GAMEPLAYFIX_Q2AIRACCELERATE				autocvar_sv_gameplayfix_q2airaccelerate

	#define IS_DUCKED(s)    					s.crouch
	#define SET_DUCKED(s)   					s.crouch = TRUE
	#define UNSET_DUCKED(s) 					s.crouch = FALSE

	#define IS_JUMP_HELD(s)    					(s.flags & FL_JUMPRELEASED == 0)
	#define SET_JUMP_HELD(s)   					s.flags &= ~FL_JUMPRELEASED
	#define UNSET_JUMP_HELD(s) 					s.flags |= FL_JUMPRELEASED

	#define IS_ONGROUND(s)    					(s.flags & FL_ONGROUND)
	#define SET_ONGROUND(s)   					s.flags |= FL_ONGROUND
	#define UNSET_ONGROUND(s) 					s.flags &= ~FL_ONGROUND

	#define ITEMS(s)							s.items
	#define PHYS_AMMO_FUEL(s)					s.ammo_fuel
	#define PHYS_FROZEN(s)						s.frozen

	#define PHYS_ACCELERATE						autocvar_sv_accelerate
	#define PHYS_AIRACCEL_QW(s)					s.stat_sv_airaccel_qw
	#define PHYS_AIRACCEL_QW_STRETCHFACTOR(s)	autocvar_sv_airaccel_qw_stretchfactor
	#define PHYS_AIRACCEL_SIDEWAYS_FRICTION		autocvar_sv_airaccel_sideways_friction
	#define PHYS_AIRACCELERATE					autocvar_sv_airaccelerate
	#define PHYS_AIRCONTROL						autocvar_sv_aircontrol
	#define PHYS_AIRCONTROL_PENALTY				autocvar_sv_aircontrol_penalty
	#define PHYS_AIRCONTROL_POWER				autocvar_sv_aircontrol_power
	#define PHYS_AIRSPEEDLIMIT_NONQW(s)			s.stat_sv_airspeedlimit_nonqw
	#define PHYS_AIRSTOPACCELERATE				autocvar_sv_airstopaccelerate
	#define PHYS_AIRSTRAFEACCEL_QW(s)			s.stat_sv_airstrafeaccel_qw
	#define PHYS_AIRSTRAFEACCELERATE			autocvar_sv_airstrafeaccelerate
	#define PHYS_ENTGRAVITY(s)					s.gravity
	#define PHYS_FRICTION						autocvar_sv_friction
	#define PHYS_GRAVITY						autocvar_sv_gravity
	#define PHYS_HIGHSPEED						autocvar_g_movement_highspeed
	#define PHYS_JUMPVELOCITY					autocvar_sv_jumpvelocity
	#define PHYS_MAXAIRSPEED					autocvar_sv_maxairspeed
	#define PHYS_MAXAIRSTRAFESPEED				autocvar_sv_maxairstrafespeed
	#define PHYS_MAXSPEED(s)					s.stat_sv_maxspeed
	#define PHYS_STEPHEIGHT						autocvar_sv_stepheight
	#define PHYS_STOPSPEED						autocvar_sv_stopspeed
	#define PHYS_WARSOWBUNNY_ACCEL				autocvar_sv_warsowbunny_accel
	#define PHYS_WARSOWBUNNY_BACKTOSIDERATIO	autocvar_sv_warsowbunny_backtosideratio
	#define PHYS_WARSOWBUNNY_AIRFORWARDACCEL	autocvar_sv_warsowbunny_airforwardaccel
	#define PHYS_WARSOWBUNNY_TOPSPEED			autocvar_sv_warsowbunny_topspeed
	#define PHYS_WARSOWBUNNY_TURNACCEL			autocvar_sv_warsowbunny_turnaccel

	#define PHYS_JETPACK_ACCEL_UP 				autocvar_g_jetpack_acceleration_up
	#define PHYS_JETPACK_ACCEL_SIDE 			autocvar_g_jetpack_acceleration_side
	#define PHYS_JETPACK_ANTIGRAVITY 			autocvar_g_jetpack_antigravity
	#define PHYS_JETPACK_FUEL					autocvar_g_jetpack_fuel
	#define PHYS_JETPACK_MAXSPEED_UP			autocvar_g_jetpack_maxspeed_up
	#define PHYS_JETPACK_MAXSPEED_SIDE			autocvar_g_jetpack_maxspeed_side

	#define PHYS_BUTTON_HOOK(s)					s.BUTTON_HOOK

	#define PHYS_DODGING_FROZEN					autocvar_sv_dodging_frozen


void Physics_UpdateStats(float maxspd_mod)
{
	self.stat_sv_airaccel_qw = AdjustAirAccelQW(autocvar_sv_airaccel_qw, maxspd_mod);
	if (autocvar_sv_airstrafeaccel_qw)
		self.stat_sv_airstrafeaccel_qw = AdjustAirAccelQW(autocvar_sv_airstrafeaccel_qw, maxspd_mod);
	else
		self.stat_sv_airstrafeaccel_qw = 0;
	self.stat_sv_airspeedlimit_nonqw = autocvar_sv_airspeedlimit_nonqw * maxspd_mod;
	self.stat_sv_maxspeed = autocvar_sv_maxspeed * maxspd_mod; // also slow walking
	self.stat_movement_highspeed = PHYS_HIGHSPEED; // TODO: remove this!

	self.stat_jetpack_antigravity = PHYS_JETPACK_ANTIGRAVITY;
	self.stat_jetpack_accel_up = PHYS_JETPACK_ACCEL_UP;
	self.stat_jetpack_accel_side = PHYS_JETPACK_ACCEL_SIDE;
	self.stat_jetpack_maxspeed_side = PHYS_JETPACK_MAXSPEED_SIDE;
	self.stat_jetpack_maxspeed_up = PHYS_JETPACK_MAXSPEED_UP;
	self.stat_jetpack_fuel = PHYS_JETPACK_FUEL;
}
#endif

float IsMoveInDirection(vector mv, float angle) // key mix factor
{
	if (mv_x == 0 && mv_y == 0)
		return 0; // avoid division by zero
	angle -= RAD2DEG * atan2(mv_y, mv_x);
	angle = remainder(angle, 360) / 45;
	return angle > 1 ? 0 : angle < -1 ? 0 : 1 - fabs(angle);
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
			self.origin = neworigin;
			return;// true;
		}
	}
}

void PM_ClientMovement_UpdateStatus()
{
	// make sure player is not stuck
	PM_ClientMovement_Unstick();

	// set crouched
	if (PHYS_INPUT_BUTTONS(self) & 16)
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

	tracebox(origin1, self.mins, self.maxs, origin2, MOVE_NORMAL, self);
	if (trace_fraction < 1 && trace_plane_normal_z > 0.7)
	{
		SET_ONGROUND(self);

		// this code actually "predicts" an impact; so let's clip velocity first
		float f = dotproduct(self.velocity, trace_plane_normal);
		if (f < 0) // only if moving downwards actually
			self.velocity -= f * trace_plane_normal;
	}
	else
		UNSET_ONGROUND(self);

	// set watertype/waterlevel
	origin1 = self.origin;
	origin1_z += self.mins_z + 1;
	self.waterlevel = WATERLEVEL_NONE;

	self.watertype = (pointcontents(origin1) == CONTENT_WATER);

	if(self.watertype)
	{
		self.waterlevel = WATERLEVEL_WETFEET;
		origin1_z = self.origin_z + (self.mins_z + self.maxs_z) * 0.5;
		if(pointcontents(origin1) == CONTENT_WATER)
		{
			self.waterlevel = WATERLEVEL_SWIMMING;
			origin1_z = self.origin_z + 22;
			if(pointcontents(origin1) == CONTENT_WATER)
				self.waterlevel = WATERLEVEL_SUBMERGED;
		}
	}

	if(IS_ONGROUND(self) || self.velocity_z <= 0 || pmove_waterjumptime <= 0)
		pmove_waterjumptime = 0;
}

void PM_ClientMovement_Move()
{
#ifdef CSQC
	float t = PHYS_INPUT_TIMELENGTH;
	vector primalvelocity = self.velocity;
	PM_ClientMovement_UpdateStatus();
	float bump = 0;
	for (bump = 0; bump < 8 && self.velocity * self.velocity > 0; bump++)
	{
		vector neworigin = self.origin + t * self.velocity;
		tracebox(self.origin, self.mins, self.maxs, neworigin, MOVE_NORMAL, self);
		float old_trace1_fraction = trace_fraction;
		vector old_trace1_endpos = trace_endpos;
		vector old_trace1_plane_normal = trace_plane_normal;
		if (trace_fraction < 1 && trace_plane_normal_z == 0)
		{
			// may be a step or wall, try stepping up
			// first move forward at a higher level
			vector currentorigin2 = self.origin;
			currentorigin2_z += PHYS_STEPHEIGHT;
			vector neworigin2 = neworigin;
			neworigin2_z = self.origin_z + PHYS_STEPHEIGHT;
			tracebox(currentorigin2, self.mins, self.maxs, neworigin2, MOVE_NORMAL, self);
			if (!trace_startsolid)
			{
				// then move down from there
				currentorigin2 = trace_endpos;
				neworigin2 = trace_endpos;
				neworigin2_z = self.origin_z;
				float old_trace2_fraction = trace_fraction;
				vector old_trace2_plane_normal = trace_plane_normal;
				tracebox(currentorigin2, self.mins, self.maxs, neworigin2, MOVE_NORMAL, self);
				//Con_Printf("%f %f %f %f : %f %f %f %f : %f %f %f %f\n", trace.fraction, trace.endpos[0], trace.endpos[1], trace.endpos[2], trace2.fraction, trace2.endpos[0], trace2.endpos[1], trace2.endpos[2], trace3.fraction, trace3.endpos[0], trace3.endpos[1], trace3.endpos[2]);
				// accept the new trace if it made some progress
				if (fabs(trace_endpos_x - old_trace1_endpos_x) >= 0.03125 || fabs(trace_endpos_y - old_trace1_endpos_y) >= 0.03125)
				{
					trace_fraction = old_trace2_fraction;
					trace_endpos = trace_endpos;
					trace_plane_normal = old_trace2_plane_normal;
				}
				else
				{
					trace_fraction = old_trace1_fraction;
					trace_endpos = old_trace1_endpos;
					trace_plane_normal = old_trace1_plane_normal;
				}
			}
		}

		// check if it moved at all
		if (trace_fraction >= 0.001)
			self.origin = trace_endpos;

		// check if it moved all the way
		if (trace_fraction == 1)
			break;

		// this is only really needed for nogravityonground combined with gravityunaffectedbyticrate
		// <LordHavoc> I'm pretty sure I commented it out solely because it seemed redundant
		// this got commented out in a change that supposedly makes the code match QW better
		// so if this is broken, maybe put it in an if (cls.protocol != PROTOCOL_QUAKEWORLD) block
		if (trace_plane_normal_z > 0.7)
			SET_ONGROUND(self);

		t -= t * trace_fraction;

		float f = dotproduct(self.velocity, trace_plane_normal);
		self.velocity -= f * trace_plane_normal;
	}
	if (pmove_waterjumptime > 0)
		self.velocity = primalvelocity;
#endif
}

void CPM_PM_Aircontrol(vector wishdir, float wishspeed)
{
	float k;
#if 0
	// this doesn't play well with analog input
	if (PHYS_INPUT_MOVEVALUES(self).x == 0 || PHYS_INPUT_MOVEVALUES(self).y != 0)
		return; // can't control movement if not moving forward or backward
	k = 32;
#else
	k = 32 * (2 * IsMoveInDirection(PHYS_INPUT_MOVEVALUES(self), 0) - 1);
	if (k <= 0)
		return;
#endif

	k *= bound(0, wishspeed / PHYS_MAXAIRSPEED, 1);

	float zspeed = self.velocity_z;
	self.velocity_z = 0;
	float xyspeed = vlen(self.velocity);
	self.velocity = normalize(self.velocity);

	float dot = self.velocity * wishdir;

	if (dot > 0) // we can't change direction while slowing down
	{
		k *= pow(dot, PHYS_AIRCONTROL_POWER)*PHYS_INPUT_TIMELENGTH;
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
=============
*/
void PlayerJump (void)
{
#ifdef SVQC
	if (PHYS_FROZEN(self))
		return; // no jumping in freezetag when frozen

	if (self.player_blocked)
		return; // no jumping while blocked

	float doublejump = FALSE;
	float mjumpheight = PHYS_JUMPVELOCITY;

	player_multijump = doublejump;
	player_jumpheight = mjumpheight;
	if (MUTATOR_CALLHOOK(PlayerJump))
		return;

	doublejump = player_multijump;
	mjumpheight = player_jumpheight;

	if (autocvar_sv_doublejump)
	{
		tracebox(self.origin + '0 0 0.01', self.mins, self.maxs, self.origin - '0 0 0.01', MOVE_NORMAL, self);
		if (trace_fraction < 1 && trace_plane_normal_z > 0.7)
		{
			doublejump = TRUE;

			// we MUST clip velocity here!
			float f;
			f = self.velocity * trace_plane_normal;
			if (f < 0)
				self.velocity -= f * trace_plane_normal;
		}
	}

	if (self.waterlevel >= WATERLEVEL_SWIMMING)
	{
		self.velocity_z = self.stat_sv_maxspeed * 0.7;
		return;
	}

	if (!doublejump)
		if (!IS_ONGROUND(self))
			return;

	if (self.cvar_cl_movement_track_canjump)
		if (!(self.flags & FL_JUMPRELEASED))
			return;

	// sv_jumpspeedcap_min/sv_jumpspeedcap_max act as baseline
	// velocity bounds.  Final velocity is bound between (jumpheight *
	// min + jumpheight) and (jumpheight * max + jumpheight);

	if (autocvar_sv_jumpspeedcap_min != "")
	{
		float minjumpspeed = mjumpheight * stof(autocvar_sv_jumpspeedcap_min);

		if (self.velocity_z < minjumpspeed)
			mjumpheight += minjumpspeed - self.velocity_z;
	}

	if (autocvar_sv_jumpspeedcap_max != "")
	{
		// don't do jump speedcaps on ramps to preserve old xonotic ramjump style
		tracebox(self.origin + '0 0 0.01', self.mins, self.maxs, self.origin - '0 0 0.01', MOVE_NORMAL, self);

		if (!(trace_fraction < 1 && trace_plane_normal_z < 0.98 && autocvar_sv_jumpspeedcap_max_disable_on_ramps))
		{
			float maxjumpspeed = mjumpheight * stof(autocvar_sv_jumpspeedcap_max);

			if (self.velocity_z > maxjumpspeed)
				mjumpheight -= self.velocity_z - maxjumpspeed;
		}
	}

	if (!(self.lastflags & FL_ONGROUND))
	{
		if (autocvar_speedmeter)
			dprint(strcat("landing velocity: ", vtos(self.velocity), " (abs: ", ftos(vlen(self.velocity)), ")\n"));
		if (self.lastground < time - 0.3)
		{
			self.velocity_x *= (1 - autocvar_sv_friction_on_land);
			self.velocity_y *= (1 - autocvar_sv_friction_on_land);
		}
		if (self.jumppadcount > 1)
			dprint(strcat(ftos(self.jumppadcount), "x jumppad combo\n"));
		self.jumppadcount = 0;
	}

	self.oldvelocity_z = self.velocity_z += mjumpheight;

	UNSET_ONGROUND(self);
	self.flags &= ~FL_JUMPRELEASED;

	animdecide_setaction(self, ANIMACTION_JUMP, TRUE);

	if (autocvar_g_jump_grunt)
		PlayerSound(playersound_jump, CH_PLAYER, VOICETYPE_PLAYERSOUND);

	self.restart_jump = -1; // restart jump anim next time
	// value -1 is used to not use the teleport bit (workaround for tiny hitch when re-jumping)
#endif
}

void CheckWaterJump()
{
// check for a jump-out-of-water
	makevectors(PHYS_INPUT_ANGLES(self));
	vector start = self.origin;
	start_z += 8;
	v_forward_z = 0;
	normalize(v_forward);
	vector end = start + v_forward*24;
	traceline (start, end, TRUE, self);
	if (trace_fraction < 1)
	{	// solid at waist
		start_z = start_z + self.maxs_z - 8;
		end = start + v_forward*24;
		self.movedir = trace_plane_normal * -50;
		traceline(start, end, TRUE, self);
		if (trace_fraction == 1)
		{	// open at eye level
			self.velocity_z = 225;
#ifdef SVQC
			self.flags |= FL_WATERJUMP;
			self.flags &= ~FL_JUMPRELEASED;
			self.teleport_time = time + 2;	// safety net
#endif
		}
	}
}

void CheckPlayerJump()
{
#ifdef SVQC
	if (self.BUTTON_JUMP)
		PlayerJump();
	else
		self.flags |= FL_JUMPRELEASED;

#endif
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
	float accel = bound(-1, PHYS_INPUT_MOVEVALUES(self).x / self.stat_sv_maxspeed, 1);
	float steer = bound(-1, PHYS_INPUT_MOVEVALUES(self).y / self.stat_sv_maxspeed, 1);

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

#ifdef SVQC
float speedaward_speed;
string speedaward_holder;
string speedaward_uid;
#endif
void race_send_speedaward(float msg)
{
#ifdef SVQC
	// send the best speed of the round
	WriteByte(msg, SVC_TEMPENTITY);
	WriteByte(msg, TE_CSQC_RACE);
	WriteByte(msg, RACE_NET_SPEED_AWARD);
	WriteInt24_t(msg, floor(speedaward_speed+0.5));
	WriteString(msg, speedaward_holder);
#endif
}

#ifdef SVQC
float speedaward_alltimebest;
string speedaward_alltimebest_holder;
string speedaward_alltimebest_uid;
#endif
void race_send_speedaward_alltimebest(float msg)
{
#ifdef SVQC
	// send the best speed
	WriteByte(msg, SVC_TEMPENTITY);
	WriteByte(msg, TE_CSQC_RACE);
	WriteByte(msg, RACE_NET_SPEED_AWARD_BEST);
	WriteInt24_t(msg, floor(speedaward_alltimebest+0.5));
	WriteString(msg, speedaward_alltimebest_holder);
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
			return TRUE;
		}
	}
	else if (self.specialcommand_pos && (c != substring(specialcommand, self.specialcommand_pos - 1, 1)))
		self.specialcommand_pos = 0;
#endif
	return FALSE;
}

void PM_check_nickspam(void)
{
#ifdef SVQC
	if (time >= self.nickspamtime)
		return;
	if (self.nickspamcount >= autocvar_g_nick_flood_penalty_yellow)
	{
		// slight annoyance for nick change scripts
		PHYS_INPUT_MOVEVALUES(self) = -1 * PHYS_INPUT_MOVEVALUES(self);
		self.BUTTON_ATCK = self.BUTTON_JUMP = self.BUTTON_ATCK2 = self.BUTTON_ZOOM = self.BUTTON_CROUCH = self.BUTTON_HOOK = self.BUTTON_USE = 0;

		if (self.nickspamcount >= autocvar_g_nick_flood_penalty_red) // if you are persistent and the slight annoyance above does not stop you, I'll show you!
		{
			PHYS_INPUT_ANGLES(self)_x = random() * 360;
			PHYS_INPUT_ANGLES(self)_y = random() * 360;
			// at least I'm not forcing retardedview by also assigning to angles_z
			self.fixangle = TRUE;
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
	self.stat_sv_maxspeed *= 0.5; // half speed while slow from spider
	self.stat_sv_airspeedlimit_nonqw *= 0.5;
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
		PHYS_INPUT_MOVEVALUES(self)_x = bound(-5, PHYS_INPUT_MOVEVALUES(self).x, 5);
		PHYS_INPUT_MOVEVALUES(self)_y = bound(-5, PHYS_INPUT_MOVEVALUES(self).y, 5);
		PHYS_INPUT_MOVEVALUES(self)_z = bound(-5, PHYS_INPUT_MOVEVALUES(self).z, 5);
	}
	else
		PHYS_INPUT_MOVEVALUES(self) = '0 0 0';

	vector midpoint = ((self.absmin + self.absmax) * 0.5);
	if (pointcontents(midpoint) == CONTENT_WATER)
	{
		self.velocity = self.velocity * 0.5;

		if (pointcontents(midpoint + '0 0 16') == CONTENT_WATER)
			self.velocity_z = 200;
	}
}

void PM_check_blocked(void)
{
#ifdef SVQC
	if (!self.player_blocked)
		return;
	PHYS_INPUT_MOVEVALUES(self) = '0 0 0';
	self.disableclientprediction = 1;
#endif
}

#ifdef SVQC
float speedaward_lastsent;
float speedaward_lastupdate;
string GetMapname(void);
#endif
void PM_check_race(void)
{
#ifdef SVQC
	if not(g_cts || g_race)
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
	float xyspeed = vlen(vec2(self.velocity));
	if (self.weapon == WEP_NEX && autocvar_g_balance_nex_charge && autocvar_g_balance_nex_charge_velocity_rate && xyspeed > autocvar_g_balance_nex_charge_minspeed)
	{
		// add a maximum of charge_velocity_rate when going fast (f = 1), gradually increasing from minspeed (f = 0) to maxspeed
		xyspeed = min(xyspeed, autocvar_g_balance_nex_charge_maxspeed);
		float f = (xyspeed - autocvar_g_balance_nex_charge_minspeed) / (autocvar_g_balance_nex_charge_maxspeed - autocvar_g_balance_nex_charge_minspeed);
		// add the extra charge
		self.nex_charge = min(1, self.nex_charge + autocvar_g_balance_nex_charge_velocity_rate * f * PHYS_INPUT_TIMELENGTH);
	}
#endif
}

void PM_fly(float maxspd_mod)
{
	// noclipping or flying
	UNSET_ONGROUND(self);

	self.velocity = self.velocity * (1 - PHYS_INPUT_TIMELENGTH * PHYS_FRICTION);
	makevectors(PHYS_INPUT_ANGLES(self));
	//wishvel = v_forward * PHYS_INPUT_MOVEVALUES(self).x + v_right * PHYS_INPUT_MOVEVALUES(self).y + v_up * PHYS_INPUT_MOVEVALUES(self).z;
	vector wishvel = v_forward * PHYS_INPUT_MOVEVALUES(self).x
					+ v_right * PHYS_INPUT_MOVEVALUES(self).y
					+ '0 0 1' * PHYS_INPUT_MOVEVALUES(self).z;
	// acceleration
	vector wishdir = normalize(wishvel);
	float wishspeed = min(vlen(wishvel), PHYS_MAXSPEED(self) * maxspd_mod);
	if (time >= self.teleport_time)
		PM_Accelerate(wishdir, wishspeed, wishspeed, PHYS_ACCELERATE * maxspd_mod, 1, 0, 0, 0);
}

void PM_swim(float maxspd_mod)
{
	// swimming
	UNSET_ONGROUND(self);

	float jump = PHYS_INPUT_BUTTONS(self) & 2;
	// water jump only in certain situations
	// this mimics quakeworld code
	if (jump && self.waterlevel == WATERLEVEL_SWIMMING && self.velocity_z >= -180)
	{
		vector yawangles = '0 1 0' * PHYS_INPUT_ANGLES(self).y;
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
	makevectors(PHYS_INPUT_ANGLES(self));
	//wishvel = v_forward * PHYS_INPUT_MOVEVALUES(self).x + v_right * PHYS_INPUT_MOVEVALUES(self).y + v_up * PHYS_INPUT_MOVEVALUES(self).z;
	vector wishvel = v_forward * PHYS_INPUT_MOVEVALUES(self).x
					+ v_right * PHYS_INPUT_MOVEVALUES(self).y
					+ '0 0 1' * PHYS_INPUT_MOVEVALUES(self).z;
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
	PM_ClientMovement_Move();
	// water acceleration
	PM_Accelerate(wishdir, wishspeed, wishspeed, PHYS_ACCELERATE * maxspd_mod, 1, 0, 0, 0);
}

void PM_ladder(float maxspd_mod)
{
#ifdef SVQC
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
	makevectors(PHYS_INPUT_ANGLES(self));
	//wishvel = v_forward * PHYS_INPUT_MOVEVALUES(self).x + v_right * PHYS_INPUT_MOVEVALUES(self).y + v_up * PHYS_INPUT_MOVEVALUES(self).z;
	vector wishvel = v_forward * PHYS_INPUT_MOVEVALUES(self).x
					+ v_right * PHYS_INPUT_MOVEVALUES(self).y
					+ '0 0 1' * PHYS_INPUT_MOVEVALUES(self).z;
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
	float wishspeed = min(vlen(wishvel), self.stat_sv_maxspeed * maxspd_mod);
	if (time >= self.teleport_time)
		// water acceleration
		PM_Accelerate(wishdir, wishspeed, wishspeed, PHYS_ACCELERATE*maxspd_mod, 1, 0, 0, 0);
#endif
}

void PM_jetpack(float maxspd_mod)
{
	//makevectors(PHYS_INPUT_ANGLES(self).y * '0 1 0');
	makevectors(PHYS_INPUT_ANGLES(self));
	vector wishvel = v_forward * PHYS_INPUT_MOVEVALUES(self)_x
					+ v_right * PHYS_INPUT_MOVEVALUES(self)_y;
	// add remaining speed as Z component
	float maxairspd = PHYS_MAXAIRSPEED * max(1, maxspd_mod);
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
	if (PHYS_JETPACK_FUEL && !(ITEMS(self) & IT_UNLIMITED_WEAPON_AMMO))
		f = min(1, PHYS_AMMO_FUEL(self) / (PHYS_JETPACK_FUEL * PHYS_INPUT_TIMELENGTH * fvel));
	else
		f = 1;

	//print("this acceleration: ", ftos(vlen(wishvel) * f), "\n");

	if (f > 0 && wishvel != '0 0 0')
	{
		self.velocity = self.velocity + wishvel * f * PHYS_INPUT_TIMELENGTH;
		UNSET_ONGROUND(self);

#ifdef SVQC
		if (!(ITEMS(self) & IT_UNLIMITED_WEAPON_AMMO))
			self.ammo_fuel -= PHYS_JETPACK_FUEL * PHYS_INPUT_TIMELENGTH * fvel * f;

		self.items |= IT_USING_JETPACK;

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
#ifdef SVQC
	// we get here if we ran out of ammo
	if ((ITEMS(self) & IT_JETPACK) && self.BUTTON_HOOK && !(buttons_prev & 32) && self.ammo_fuel < 0.01)
		sprint(self, "You don't have any fuel for the ^2Jetpack\n");
	if (!(self.lastflags & FL_ONGROUND))
	{
		if (autocvar_speedmeter)
			dprint(strcat("landing velocity: ", vtos(self.velocity), " (abs: ", ftos(vlen(self.velocity)), ")\n"));
		if (self.lastground < time - 0.3)
			self.velocity *= (1 - autocvar_sv_friction_on_land);
		if (self.jumppadcount > 1)
			dprint(strcat(ftos(self.jumppadcount), "x jumppad combo\n"));
		self.jumppadcount = 0;
	}
#endif
	// walking
	makevectors(PHYS_INPUT_ANGLES(self).y * '0 1 0');
	vector wishvel = v_forward * PHYS_INPUT_MOVEVALUES(self).x
					+ v_right * PHYS_INPUT_MOVEVALUES(self).y;
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
		// TODO: apply edge friction
		// apply ground friction
		f = 1 - PHYS_INPUT_TIMELENGTH * PHYS_FRICTION * ((f < PHYS_STOPSPEED) ? (PHYS_STOPSPEED / f) : 1);
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
#ifdef SVQC
	// we get here if we ran out of ammo
	if ((ITEMS(self) & IT_JETPACK) && self.BUTTON_HOOK && !(buttons_prev & 32) && PHYS_AMMO_FUEL(self) < 0.01)
		sprint(self, "You don't have any fuel for the ^2Jetpack\n");
#endif
	makevectors(PHYS_INPUT_ANGLES(self).y * '0 1 0');
	vector wishvel = v_forward * PHYS_INPUT_MOVEVALUES(self).x
					+ v_right * PHYS_INPUT_MOVEVALUES(self).y;
	// acceleration
	vector wishdir = normalize(wishvel);
	float wishspeed = vlen(wishvel);

#ifdef SVQC
	if (time >= self.teleport_time)
#else
	if (pmove_waterjumptime <= 0)
#endif
	{
		float maxairspd = PHYS_MAXAIRSPEED * min(maxspd_mod, 1);

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
		float strafity = IsMoveInDirection(PHYS_INPUT_MOVEVALUES(self), -90) + IsMoveInDirection(PHYS_INPUT_MOVEVALUES(self), +90); // if one is nonzero, other is always zero
		if (PHYS_MAXAIRSTRAFESPEED)
			wishspeed = min(wishspeed, GeomLerp(PHYS_MAXAIRSPEED*maxspd_mod, strafity, PHYS_MAXAIRSTRAFESPEED*maxspd_mod));
		if (PHYS_AIRSTRAFEACCELERATE)
			airaccel = GeomLerp(airaccel, strafity, PHYS_AIRSTRAFEACCELERATE*maxspd_mod);
		if (PHYS_AIRSTRAFEACCEL_QW(self))
			airaccelqw =
            	(((strafity > 0.5 ? PHYS_AIRSTRAFEACCEL_QW(self) : PHYS_AIRACCEL_QW(self)) >= 0) ? +1 : -1)
            	*
            	(1 - GeomLerp(1 - fabs(PHYS_AIRACCEL_QW(self)), strafity, 1 - fabs(PHYS_AIRSTRAFEACCEL_QW(self))));
		// !CPM

		if (PHYS_WARSOWBUNNY_TURNACCEL && accelerating && PHYS_INPUT_MOVEVALUES(self).y == 0 && PHYS_INPUT_MOVEVALUES(self).x != 0)
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
float PM_is_flying()
{
	if (IS_ONGROUND(self))
		return 0;
	if (self.waterlevel >= WATERLEVEL_SWIMMING)
		return 0;
	traceline(self.origin, self.origin - '0 0 48', MOVE_NORMAL, self);
	return trace_fraction >= 1;
}

void PM_Main()
{
#ifdef CSQC
	//Con_Printf(" %f", PHYS_INPUT_TIMELENGTH);
	if (!(PHYS_INPUT_BUTTONS(self) & 2)) // !jump
		UNSET_JUMP_HELD(self); // canjump = true
	pmove_waterjumptime -= PHYS_INPUT_TIMELENGTH;
	PM_ClientMovement_UpdateStatus();
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
	float buttons = PHYS_INPUT_BUTTONS(self);

	if (PM_check_specialcommand(buttons))
		return;
#ifdef SVQC
	if (sv_maxidle > 0)
	{
		if (buttons != self.buttons_old || PHYS_INPUT_MOVEVALUES(self) != self.movement_old || PHYS_INPUT_ANGLES(self) != self.v_angle_old)
			self.parm_idlesince = time;
	}
#endif
	float buttons_prev = self.buttons_old;
	self.buttons_old = buttons;
	self.movement_old = PHYS_INPUT_MOVEVALUES(self);
	self.v_angle_old = PHYS_INPUT_ANGLES(self);

	PM_check_nickspam();

	PM_check_punch();
#ifdef SVQC
	if (IS_BOT_CLIENT(self))
	{
		if (playerdemo_read())
			return;
		bot_think();
	}

	self.items &= ~IT_USING_JETPACK;

	if (IS_PLAYER(self))
#endif
	{
#ifdef SVQC
		if (self.race_penalty)
			if (time > self.race_penalty)
				self.race_penalty = 0;
#endif

		float not_allowed_to_move = 0;
#ifdef SVQC
		if (self.race_penalty)
			not_allowed_to_move = 1;
#endif
#ifdef SVQC
		if (!autocvar_sv_ready_restart_after_countdown)
			if (time < game_starttime)
				not_allowed_to_move = 1;
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
#endif

#ifdef SVQC
	// when we get here, disableclientprediction cannot be 2
	self.disableclientprediction = 0;
	if (time < self.ladder_time)
		self.disableclientprediction = 1;
#endif

	PM_check_spider();

	PM_check_frozen();

#ifdef SVQC
	MUTATOR_CALLHOOK(PlayerPhysics);
#endif

	PM_check_blocked();

	maxspeed_mod = 1;

#ifdef SVQC
	if (self.in_swamp) {
		maxspeed_mod *= self.swamp_slowdown; //cvar("g_balance_swamp_moverate");
	}
#endif

#ifdef SVQC
	// conveyors: first fix velocity
	if (self.conveyor.state)
		self.velocity -= self.conveyor.movedir;
#endif

#ifdef SVQC
	if (!IS_PLAYER(self))
	{
		maxspeed_mod *= autocvar_sv_spectator_speed_multiplier;
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
		maxspeed_mod *= self.spectatorspeed;
	}
#endif

#ifdef SVQC
	// if dead, behave differently
	// in CSQC, physics don't handle dead player
	if (self.deadflag)
		goto end;
#endif

#ifdef SVQC
	if (!self.fixangle && !g_bugrigs)
		self.angles = '0 1 0' * PHYS_INPUT_ANGLES(self).y;
#endif

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

	if (PM_is_flying())
		self.wasFlying = 1;

#ifdef SVQC
	if (IS_PLAYER(self))
#endif
		CheckPlayerJump();


	if (self.flags & /* FL_WATERJUMP */ 2048)
	{
		self.velocity_x = self.movedir_x;
		self.velocity_y = self.movedir_y;
		if (time > self.teleport_time || self.waterlevel == WATERLEVEL_NONE)
		{
			self.flags &= ~/* FL_WATERJUMP */ 2048;
			self.teleport_time = 0;
		}
	}

#ifdef SVQC
	else if (g_bugrigs && IS_PLAYER(self))
		RaceCarPhysics();
#endif

	else if (self.movetype == MOVETYPE_NOCLIP || self.movetype == MOVETYPE_FLY || self.movetype == MOVETYPE_FLY_WORLDONLY)
		PM_fly(maxspeed_mod);

	else if (self.waterlevel >= WATERLEVEL_SWIMMING)
		PM_swim(maxspeed_mod);

#ifdef SVQC
	else if (time < self.ladder_time)
		PM_ladder(maxspeed_mod);
#endif

	else if ((ITEMS(self) & IT_JETPACK) && PHYS_BUTTON_HOOK(self) && (!PHYS_JETPACK_FUEL || PHYS_AMMO_FUEL(self) > 0 || (ITEMS(self) & IT_UNLIMITED_WEAPON_AMMO)) && !PHYS_FROZEN(self))
		PM_jetpack(maxspeed_mod);

	else
	{
#ifdef CSQC
		// jump if on ground with jump button pressed but only if it has been
		// released at least once since the last jump
		if (PHYS_INPUT_BUTTONS(self) & 2)
		{
			if (IS_ONGROUND(self) && (!IS_JUMP_HELD(self) || !cvar("cl_movement_track_canjump")))
			{
				self.velocity_z += PHYS_JUMPVELOCITY;
				UNSET_ONGROUND(self);
				SET_JUMP_HELD(self); // canjump = false
			}
		}
		else
			UNSET_JUMP_HELD(self); // canjump = true
#endif
		if (IS_ONGROUND(self))
			PM_walk(buttons_prev, maxspeed_mod);
		else
			PM_air(buttons_prev, maxspeed_mod);
	}

#ifdef SVQC
	if (!IS_OBSERVER(self))
		PM_check_race();
#endif
	PM_check_vortex();

:end
	if (IS_ONGROUND(self))
		self.lastground = time;

#ifdef SVQC
	// conveyors: then break velocity again
	if (self.conveyor.state)
		self.velocity += self.conveyor.movedir;
#endif

	self.lastflags = self.flags;
	self.lastclassname = self.classname;
}

void CSQC_ClientMovement_PlayerMove_Frame()
{
	// if a move is more than 50ms, do it as two moves (matching qwsv)
	//Con_Printf("%i ", self.cmd.msec);
	if (PHYS_INPUT_TIMELENGTH > 0.0005)
	{
		if (PHYS_INPUT_TIMELENGTH > 0.05)
		{
			PHYS_INPUT_TIMELENGTH /= 2;
			PM_Main();
		}
		PM_Main();
	}
	else
		// we REALLY need this handling to happen, even if the move is not executed
		if (!(PHYS_INPUT_BUTTONS(self) & 2)) // !jump
			UNSET_JUMP_HELD(self); // canjump = true
}

#undef PHYS_INPUT_ANGLES
#undef PHYS_INPUT_BUTTONS
#undef PHYS_INPUT_TIMELENGTH
#undef PHYS_INPUT_MOVEVALUES

#undef GAMEPLAYFIX_GRAVITYUNAFFECTEDBYTICRATE
#undef GAMEPLAYFIX_NOGRAVITYONGROUND
#undef GAMEPLAYFIX_Q2AIRACCELERATE

#undef IS_DUCKED
#undef SET_DUCKED
#undef UNSET_DUCKED

#undef IS_JUMP_HELD
#undef SET_JUMP_HELD
#undef UNSET_JUMP_HELD

#undef IS_ONGROUND
#undef SET_ONGROUND
#undef UNSET_ONGROUND

#undef PHYS_ACCELERATE
#undef PHYS_AIRACCEL_QW
#undef PHYS_AIRACCEL_QW_STRETCHFACTOR
#undef PHYS_AIRACCEL_SIDEWAYS_FRICTION
#undef PHYS_AIRACCELERATE
#undef PHYS_AIRCONTROL
#undef PHYS_AIRCONTROL_PENALTY
#undef PHYS_AIRCONTROL_POWER
#undef PHYS_AIRSPEEDLIMIT_NONQW
#undef PHYS_AIRSTOPACCELERATE
#undef PHYS_AIRSTRAFEACCEL_QW
#undef PHYS_AIRSTRAFEACCELERATE
#undef PHYS_EDGEFRICTION
#undef PHYS_ENTGRAVITY
#undef PHYS_FRICTION
#undef PHYS_GRAVITY
#undef PHYS_HIGHSPEED
#undef PHYS_JUMPVELOCITY
#undef PHYS_MAXAIRSPEED
#undef PHYS_MAXAIRSTRAFESPEED
#undef PHYS_MAXSPEED
#undef PHYS_STEPHEIGHT
#undef PHYS_STOPSPEED
#undef PHYS_WARSOWBUNNY_ACCEL
#undef PHYS_WARSOWBUNNY_BACKTOSIDERATIO
#undef PHYS_WARSOWBUNNY_AIRFORWARDACCEL
#undef PHYS_WARSOWBUNNY_TOPSPEED
#undef PHYS_WARSOWBUNNY_TURNACCEL

#ifdef SVQC
// Entry point
void SV_PlayerPhysics(void)
{
	PM_Main();
}
#endif