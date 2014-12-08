#ifdef SVQC
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
#endif

// TODO: water prediction

// TODO: move to a common header
#define VLEN2(v) dotproduct(v, v)

// Client/server mappings
#ifdef CSQC

	#define PHYS_INPUT_ANGLES(s)   				input_angles
	#define PHYS_INPUT_BUTTONS(s)   			input_buttons

	#define PHYS_INPUT_TIMELENGTH				input_timelength

	#define PHYS_INPUT_MOVEVALUES(s)			input_movevalues

	#define GAMEPLAYFIX_GRAVITYUNAFFECTEDBYTICRATE	moveflags & MOVEFLAG_GRAVITYUNAFFECTEDBYTICRATE
	#define GAMEPLAYFIX_NOGRAVITYONGROUND			moveflags & MOVEFLAG_NOGRAVITYONGROUND
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

	#define PHYS_ACCELERATE						getstatf(STAT_MOVEVARS_ACCELERATE)
	#define PHYS_AIRACCEL_QW					getstatf(STAT_MOVEVARS_AIRACCEL_QW)
	#define PHYS_AIRACCEL_QW_STRETCHFACTOR		getstatf(STAT_MOVEVARS_AIRACCEL_QW_STRETCHFACTOR)
	#define PHYS_AIRACCEL_SIDEWAYS_FRICTION		getstatf(STAT_MOVEVARS_AIRACCEL_SIDEWAYS_FRICTION)
	#define PHYS_AIRACCELERATE					getstatf(STAT_MOVEVARS_AIRACCELERATE)
	#define PHYS_AIRCONTROL						getstatf(STAT_MOVEVARS_AIRCONTROL)
	#define PHYS_AIRCONTROL_PENALTY				getstatf(STAT_MOVEVARS_AIRCONTROL_PENALTY)
	#define PHYS_AIRCONTROL_POWER				getstatf(STAT_MOVEVARS_AIRCONTROL_POWER)
	#define PHYS_AIRSPEEDLIMIT_NONQW			getstatf(STAT_MOVEVARS_AIRSPEEDLIMIT_NONQW)
	#define PHYS_AIRSTOPACCELERATE				getstatf(STAT_MOVEVARS_AIRSTOPACCELERATE)
	#define PHYS_AIRSTRAFEACCEL_QW				getstatf(STAT_MOVEVARS_AIRSTRAFEACCEL_QW)
	#define PHYS_AIRSTRAFEACCELERATE			getstatf(STAT_MOVEVARS_AIRSTRAFEACCELERATE)
	#define PHYS_EDGEFRICTION					getstatf(STAT_MOVEVARS_EDGEFRICTION)
	#define PHYS_ENTGRAVITY(s)					getstatf(STAT_MOVEVARS_ENTGRAVITY)
	#define PHYS_FRICTION						getstatf(STAT_MOVEVARS_FRICTION)
	#define PHYS_GRAVITY						getstatf(STAT_MOVEVARS_GRAVITY)
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

#elif defined(SVQC)

	#define PHYS_INPUT_ANGLES(s)				s.v_angle
	// FIXME
	#define PHYS_INPUT_BUTTONS(s)   			0

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

	#define PHYS_ACCELERATE						autocvar_sv_accelerate
	#define PHYS_AIRACCEL_QW					autocvar_sv_airaccel_qw
	#define PHYS_AIRACCEL_QW_STRETCHFACTOR		autocvar_sv_airaccel_qw_stretchfactor
	#define PHYS_AIRACCEL_SIDEWAYS_FRICTION		autocvar_sv_airaccel_sideways_friction
	#define PHYS_AIRACCELERATE					autocvar_sv_airaccelerate
	#define PHYS_AIRCONTROL						autocvar_sv_aircontrol
	#define PHYS_AIRCONTROL_PENALTY				autocvar_sv_aircontrol_penalty
	#define PHYS_AIRCONTROL_POWER				autocvar_sv_aircontrol_power
	#define PHYS_AIRSPEEDLIMIT_NONQW			autocvar_sv_airspeedlimit_nonqw
	#define PHYS_AIRSTOPACCELERATE				autocvar_sv_airstopaccelerate
	#define PHYS_AIRSTRAFEACCEL_QW				autocvar_sv_airstrafeaccel_qw
	#define PHYS_AIRSTRAFEACCELERATE			autocvar_sv_airstrafeaccelerate
	#define PHYS_EDGEFRICTION					1
	#define PHYS_ENTGRAVITY(s)					s.gravity
	#define PHYS_FRICTION						autocvar_sv_friction
	#define PHYS_GRAVITY						autocvar_sv_gravity
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

#endif

float IsMoveInDirection(vector mv, float angle) // key mix factor
{
	if(mv_x == 0 && mv_y == 0)
		return 0; // avoid division by zero
	angle -= RAD2DEG * atan2(mv_y, mv_x);
	angle = remainder(angle, 360) / 45;
	if(angle >  1)
		return 0;
	if(angle < -1)
		return 0;
	return 1 - fabs(angle);
}

float GeomLerp(float a, float lerp, float b)
{
	if(a == 0)
	{
		if(lerp < 1)
			return 0;
		else
			return b;
	}
	if(b == 0)
	{
		if(lerp > 0)
			return 0;
		else
			return a;
	}
	return a * pow(fabs(b / a), lerp);
}

float pmove_waterjumptime; // weird engine flag we shouldn't really use but have to for now

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

void CSQC_ClientMovement_Unstick(entity s)
{
	float i;
	vector neworigin;
	for (i = 0; i < unstick_count; i++)
	{
		neworigin = unstick_offsets[i] + s.origin;
		tracebox(neworigin, PL_CROUCH_MIN, PL_CROUCH_MAX, neworigin, MOVE_NORMAL, s);
		if (!trace_startsolid)
		{
			s.origin = neworigin;
			return;// true;
		}
	}
}

void CSQC_ClientMovement_UpdateStatus(entity s)
{
	float f;
	vector origin1, origin2;

	// make sure player is not stuck
	CSQC_ClientMovement_Unstick(s);

	// set crouched
	if (PHYS_INPUT_BUTTONS(s) & 16)
	{
		// wants to crouch, this always works..
		if (!IS_DUCKED(s))
			SET_DUCKED(s);
	}
	else
	{
		// wants to stand, if currently crouching we need to check for a
		// low ceiling first
		if (IS_DUCKED(s))
		{
			tracebox(s.origin, PL_MIN, PL_MAX, s.origin, MOVE_NORMAL, s);
			if (!trace_startsolid)
				UNSET_DUCKED(s);
		}
	}
	if (IS_DUCKED(s))
	{
		s.mins = PL_CROUCH_MIN;
		s.maxs = PL_CROUCH_MAX;
	}
	else
	{
		s.mins = PL_MIN;
		s.maxs = PL_MAX;
	}

	// set onground
	origin1 = s.origin;
	origin1_z += 1;
	origin2 = s.origin;
    origin2_z -= 1; // -2 causes clientside doublejump bug at above 150fps, raising that to 300fps :)

	tracebox(origin1, s.mins, s.maxs, origin2, MOVE_NORMAL, s);
	if(trace_fraction < 1 && trace_plane_normal_z > 0.7)
	{
		SET_ONGROUND(s);

		// this code actually "predicts" an impact; so let's clip velocity first
		f = dotproduct(s.velocity, trace_plane_normal);
		if(f < 0) // only if moving downwards actually
			s.velocity -= f * trace_plane_normal;
	}
	else
		UNSET_ONGROUND(s);

	// set watertype/waterlevel
	origin1 = s.origin;
	origin1_z += s.mins_z + 1;
	s.waterlevel = WATERLEVEL_NONE;
	// TODO: convert
//	s.watertype = CL_TracePoint(origin1, MOVE_NOMONSTERS, s, 0, true, false, NULL, false).startsupercontents & SUPERCONTENTS_LIQUIDSMASK;
//	if (s.watertype)
//	{
//		s.waterlevel = WATERLEVEL_WETFEET;
//		origin1[2] = s.origin[2] + (s.mins[2] + s.maxs[2]) * 0.5f;
//		if (CL_TracePoint(origin1, MOVE_NOMONSTERS, s, 0, true, false, NULL, false).startsupercontents & SUPERCONTENTS_LIQUIDSMASK)
//		{
//			s.waterlevel = WATERLEVEL_SWIMMING;
//			origin1[2] = s.origin[2] + 22;
//			if (CL_TracePoint(origin1, MOVE_NOMONSTERS, s, 0, true, false, NULL, false).startsupercontents & SUPERCONTENTS_LIQUIDSMASK)
//				s.waterlevel = WATERLEVEL_SUBMERGED;
//		}
//	}
//
//	// water jump prediction
//	if (IS_ONGROUND(s) || s.velocity_z <= 0 || pmove_waterjumptime <= 0)
//		pmove_waterjumptime = 0;
}

void CSQC_ClientMovement_Move(entity s)
{
	float bump;
	float t;
	float f;
	vector neworigin;
	vector currentorigin2;
	vector neworigin2;
	vector primalvelocity;
	float old_trace1_fraction;
	vector old_trace1_endpos;
	vector old_trace1_plane_normal;
	float old_trace2_fraction;
	vector old_trace2_plane_normal;
	CSQC_ClientMovement_UpdateStatus(s);
	primalvelocity = s.velocity;
	for (bump = 0, t = PHYS_INPUT_TIMELENGTH; bump < 8 && VLEN2(s.velocity) > 0; bump++)
	{
		neworigin = s.origin + t * s.velocity;
		tracebox(s.origin, s.mins, s.maxs, neworigin, MOVE_NORMAL, s);
		old_trace1_fraction = trace_fraction;
		old_trace1_endpos = trace_endpos;
		old_trace1_plane_normal = trace_plane_normal;
		if (trace_fraction < 1 && trace_plane_normal_z == 0)
		{
			// may be a step or wall, try stepping up
			// first move forward at a higher level
			currentorigin2 = s.origin;
			currentorigin2_z += PHYS_STEPHEIGHT;
			neworigin2 = neworigin;
			neworigin2_z = s.origin_z + PHYS_STEPHEIGHT;
			tracebox(currentorigin2, s.mins, s.maxs, neworigin2, MOVE_NORMAL, s);
			if (!trace_startsolid)
			{
				// then move down from there
				currentorigin2 = trace_endpos;
				neworigin2 = trace_endpos;
				neworigin2_z = s.origin_z;
				old_trace2_fraction = trace_fraction;
				old_trace2_plane_normal = trace_plane_normal;
				tracebox(currentorigin2, s.mins, s.maxs, neworigin2, MOVE_NORMAL, s);
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
			s.origin = trace_endpos;

		// check if it moved all the way
		if (trace_fraction == 1)
			break;

		// this is only really needed for nogravityonground combined with gravityunaffectedbyticrate
		// <LordHavoc> I'm pretty sure I commented it out solely because it seemed redundant
		// this got commented out in a change that supposedly makes the code match QW better
		// so if this is broken, maybe put it in an if(cls.protocol != PROTOCOL_QUAKEWORLD) block
		if (trace_plane_normal_z > 0.7)
			SET_ONGROUND(s);

		t -= t * trace_fraction;

		f = dotproduct(s.velocity, trace_plane_normal);
		s.velocity -= f * trace_plane_normal;
	}
	if (pmove_waterjumptime > 0)
		s.velocity = primalvelocity;
}

void CPM_PM_Aircontrol(entity s, vector wishdir, float wishspeed)
{
	float zspeed, xyspeed, dot, k;

#if 0
	// this doesn't play well with analog input
	if(s.movement_x == 0 || s.movement_y != 0)
		return; // can't control movement if not moving forward or backward
	k = 32;
#else
	k = 32 * (2 * IsMoveInDirection(PHYS_INPUT_MOVEVALUES(s), 0) - 1);
	if(k <= 0)
		return;
#endif

	k *= bound(0, wishspeed / PHYS_MAXAIRSPEED, 1);

	zspeed = s.velocity_z;
	s.velocity_z = 0;
	xyspeed = vlen(s.velocity); s.velocity = normalize(s.velocity);

	dot = s.velocity * wishdir;

	if(dot > 0) // we can't change direction while slowing down
	{
		k *= pow(dot, PHYS_AIRCONTROL_POWER)*PHYS_INPUT_TIMELENGTH;
		xyspeed = max(0, xyspeed - PHYS_AIRCONTROL_PENALTY * sqrt(max(0, 1 - dot*dot)) * k/32);
		k *= PHYS_AIRCONTROL;
		s.velocity = normalize(s.velocity * xyspeed + wishdir * k);
	}

	s.velocity = s.velocity * xyspeed;
	s.velocity_z = zspeed;
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
void PM_Accelerate(entity s, vector wishdir, float wishspeed, float wishspeed0, float accel, float accelqw, float stretchfactor, float sidefric, float speedlimit)
{
	float vel_straight;
	float vel_z;
	vector vel_perpend;
	float step;

	vector vel_xy;
	float vel_xy_current;
	float vel_xy_backward, vel_xy_forward;
	float speedclamp;

	if(stretchfactor > 0)
		speedclamp = stretchfactor;
	else if(accelqw < 0)
		speedclamp = 1; // full clamping, no stretch
	else
		speedclamp = -1; // no clamping

	if(accelqw < 0)
		accelqw = -accelqw;

	if(GAMEPLAYFIX_Q2AIRACCELERATE)
		wishspeed0 = wishspeed; // don't need to emulate this Q1 bug

	vel_straight = s.velocity * wishdir;
	vel_z = s.velocity_z;
	vel_xy = vec2(s.velocity);
	vel_perpend = vel_xy - vel_straight * wishdir;

	step = accel * PHYS_INPUT_TIMELENGTH * wishspeed0;

	vel_xy_current  = vlen(vel_xy);
	if(speedlimit)
		accelqw = AdjustAirAccelQW(accelqw, (speedlimit - bound(wishspeed, vel_xy_current, speedlimit)) / max(1, speedlimit - wishspeed));
	vel_xy_forward  = vel_xy_current + bound(0, wishspeed - vel_xy_current, step) * accelqw + step * (1 - accelqw);
	vel_xy_backward = vel_xy_current - bound(0, wishspeed + vel_xy_current, step) * accelqw - step * (1 - accelqw);
	if(vel_xy_backward < 0)
		vel_xy_backward = 0; // not that it REALLY occurs that this would cause wrong behaviour afterwards

	vel_straight    = vel_straight   + bound(0, wishspeed - vel_straight,   step) * accelqw + step * (1 - accelqw);

	if(sidefric < 0 && (vel_perpend*vel_perpend))
		// negative: only apply so much sideways friction to stay below the speed you could get by "braking"
	{
		float f, fmin;
		f = max(0, 1 + PHYS_INPUT_TIMELENGTH * wishspeed * sidefric);
		fmin = (vel_xy_backward*vel_xy_backward - vel_straight*vel_straight) / (vel_perpend*vel_perpend);
		// assume: fmin > 1
		// vel_xy_backward*vel_xy_backward - vel_straight*vel_straight > vel_perpend*vel_perpend
		// vel_xy_backward*vel_xy_backward > vel_straight*vel_straight + vel_perpend*vel_perpend
		// vel_xy_backward*vel_xy_backward > vel_xy * vel_xy
		// obviously, this cannot be
		if(fmin <= 0)
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

	if(speedclamp >= 0)
	{
		float vel_xy_preclamp;
		vel_xy_preclamp = vlen(vel_xy);
		if(vel_xy_preclamp > 0) // prevent division by zero
		{
			vel_xy_current += (vel_xy_forward - vel_xy_current) * speedclamp;
			if(vel_xy_current < vel_xy_preclamp)
				vel_xy *= (vel_xy_current / vel_xy_preclamp);
		}
	}

	s.velocity = vel_xy + vel_z * '0 0 1';
}

void PM_AirAccelerate(entity s, vector wishdir, float wishspeed)
{
	vector curvel, wishvel, acceldir, curdir;
	float addspeed, accelspeed, curspeed, f;
	float dot;

	if(wishspeed == 0)
		return;

	curvel = s.velocity;
	curvel_z = 0;
	curspeed = vlen(curvel);

	if(wishspeed > curspeed * 1.01)
	{
		wishspeed = min(wishspeed, curspeed + PHYS_WARSOWBUNNY_AIRFORWARDACCEL * PHYS_MAXSPEED(s) * PHYS_INPUT_TIMELENGTH);
	}
	else
	{
		f = max(0, (PHYS_WARSOWBUNNY_TOPSPEED - curspeed) / (PHYS_WARSOWBUNNY_TOPSPEED - PHYS_MAXSPEED(s)));
		wishspeed = max(curspeed, PHYS_MAXSPEED(s)) + PHYS_WARSOWBUNNY_ACCEL * f * PHYS_MAXSPEED(s) * PHYS_INPUT_TIMELENGTH;
	}
	wishvel = wishdir * wishspeed;
	acceldir = wishvel - curvel;
	addspeed = vlen(acceldir);
	acceldir = normalize(acceldir);

	accelspeed = min(addspeed, PHYS_WARSOWBUNNY_TURNACCEL * PHYS_MAXSPEED(s) * PHYS_INPUT_TIMELENGTH);

	if(PHYS_WARSOWBUNNY_BACKTOSIDERATIO < 1)
	{
		curdir = normalize(curvel);
		dot = acceldir * curdir;
		if(dot < 0)
			acceldir = acceldir - (1 - PHYS_WARSOWBUNNY_BACKTOSIDERATIO) * dot * curdir;
	}

	s.velocity += accelspeed * acceldir;
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
	if(self.frozen)
		return; // no jumping in freezetag when frozen

	if(self.player_blocked)
		return; // no jumping while blocked

	float doublejump = FALSE;
	float mjumpheight = autocvar_sv_jumpvelocity;

	player_multijump = doublejump;
	player_jumpheight = mjumpheight;
	if(MUTATOR_CALLHOOK(PlayerJump))
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
			if(f < 0)
				self.velocity -= f * trace_plane_normal;
		}
	}

	if (self.waterlevel >= WATERLEVEL_SWIMMING)
	{
		self.velocity_z = self.stat_sv_maxspeed * 0.7;
		return;
	}

	if (!doublejump)
		if (!(self.flags & FL_ONGROUND))
			return;

	if(self.cvar_cl_movement_track_canjump)
		if (!(self.flags & FL_JUMPRELEASED))
			return;

	// sv_jumpspeedcap_min/sv_jumpspeedcap_max act as baseline
	// velocity bounds.  Final velocity is bound between (jumpheight *
	// min + jumpheight) and (jumpheight * max + jumpheight);

	if(autocvar_sv_jumpspeedcap_min != "")
	{
		float minjumpspeed;

		minjumpspeed = mjumpheight * stof(autocvar_sv_jumpspeedcap_min);

		if (self.velocity_z < minjumpspeed)
			mjumpheight += minjumpspeed - self.velocity_z;
	}

	if(autocvar_sv_jumpspeedcap_max != "")
	{
		// don't do jump speedcaps on ramps to preserve old xonotic ramjump style
		tracebox(self.origin + '0 0 0.01', self.mins, self.maxs, self.origin - '0 0 0.01', MOVE_NORMAL, self);

		if(!(trace_fraction < 1 && trace_plane_normal_z < 0.98 && autocvar_sv_jumpspeedcap_max_disable_on_ramps))
		{
			float maxjumpspeed;

			maxjumpspeed = mjumpheight * stof(autocvar_sv_jumpspeedcap_max);

			if (self.velocity_z > maxjumpspeed)
				mjumpheight -= self.velocity_z - maxjumpspeed;
		}
	}

	if(!(self.lastflags & FL_ONGROUND))
	{
		if(autocvar_speedmeter)
			dprint(strcat("landing velocity: ", vtos(self.velocity), " (abs: ", ftos(vlen(self.velocity)), ")\n"));
		if(self.lastground < time - 0.3)
		{
			self.velocity_x *= (1 - autocvar_sv_friction_on_land);
			self.velocity_y *= (1 - autocvar_sv_friction_on_land);
		}
		if(self.jumppadcount > 1)
			dprint(strcat(ftos(self.jumppadcount), "x jumppad combo\n"));
		self.jumppadcount = 0;
	}

	self.velocity_z = self.velocity_z + mjumpheight;
	self.oldvelocity_z = self.velocity_z;

	self.flags &= ~FL_ONGROUND;
	self.flags &= ~FL_JUMPRELEASED;

	animdecide_setaction(self, ANIMACTION_JUMP, TRUE);

	if(autocvar_g_jump_grunt)
		PlayerSound(playersound_jump, CH_PLAYER, VOICETYPE_PLAYERSOUND);

	self.restart_jump = -1; // restart jump anim next time
	// value -1 is used to not use the teleport bit (workaround for tiny hitch when re-jumping)
#endif
}

void CheckWaterJump()
{
#ifdef SVQC
	vector start, end;

// check for a jump-out-of-water
	makevectors (self.angles);
	start = self.origin;
	start_z = start_z + 8;
	v_forward_z = 0;
	normalize(v_forward);
	end = start + v_forward*24;
	traceline (start, end, TRUE, self);
	if (trace_fraction < 1)
	{	// solid at waist
		start_z = start_z + self.maxs_z - 8;
		end = start + v_forward*24;
		self.movedir = trace_plane_normal * -50;
		traceline (start, end, TRUE, self);
		if (trace_fraction == 1)
		{	// open at eye level
			self.flags |= FL_WATERJUMP;
			self.velocity_z = 225;
			self.flags &= ~FL_JUMPRELEASED;
			self.teleport_time = time + 2;	// safety net
			return;
		}
	}
#endif
}

void CheckPlayerJump()
{
#ifdef SVQC
	if (self.BUTTON_JUMP)
		PlayerJump ();
	else
		self.flags |= FL_JUMPRELEASED;

	if (self.waterlevel == WATERLEVEL_SWIMMING)
		CheckWaterJump ();
#endif
}

float racecar_angle(float forward, float down)
{
	float ret, angle_mult;

	if(forward < 0)
	{
		forward = -forward;
		down = -down;
	}

	ret = vectoyaw('0 1 0' * down + '1 0 0' * forward);

	angle_mult = forward / (800 + forward);

	if(ret > 180)
		return ret * angle_mult + 360 * (1 - angle_mult);
	else
		return ret * angle_mult;
}

void RaceCarPhysics()
{
#ifdef SVQC
	// using this move type for "big rigs"
	// the engine does not push the entity!

	float accel, steer, f, myspeed, steerfactor;
	vector angles_save, rigvel;

	angles_save = self.angles;
	accel = bound(-1, self.movement_x / self.stat_sv_maxspeed, 1);
	steer = bound(-1, self.movement_y / self.stat_sv_maxspeed, 1);

	if(g_bugrigs_reverse_speeding)
	{
		if(accel < 0)
		{
			// back accel is DIGITAL
			// to prevent speedhack
			if(accel < -0.5)
				accel = -1;
			else
				accel = 0;
		}
	}

	self.angles_x = 0;
	self.angles_z = 0;
	makevectors(self.angles); // new forward direction!

	if(self.flags & FL_ONGROUND || g_bugrigs_air_steering)
	{
		float upspeed, accelfactor;

		myspeed = self.velocity * v_forward;
		upspeed = self.velocity * v_up;

		// responsiveness factor for steering and acceleration
		f = 1 / (1 + pow(max(-myspeed, myspeed) / g_bugrigs_speed_ref, g_bugrigs_speed_pow));
		//MAXIMA: f(v) := 1 / (1 + (v / g_bugrigs_speed_ref) ^ g_bugrigs_speed_pow);

		if(myspeed < 0 && g_bugrigs_reverse_spinning)
			steerfactor = -myspeed * g_bugrigs_steer;
		else
			steerfactor = -myspeed * f * g_bugrigs_steer;

		if(myspeed < 0 && g_bugrigs_reverse_speeding)
			accelfactor = g_bugrigs_accel;
		else
			accelfactor = f * g_bugrigs_accel;
		//MAXIMA: accel(v) := f(v) * g_bugrigs_accel;

		if(accel < 0)
		{
			if(myspeed > 0)
			{
				myspeed = max(0, myspeed - frametime * (g_bugrigs_friction_floor - g_bugrigs_friction_brake * accel));
			}
			else
			{
				if(!g_bugrigs_reverse_speeding)
					myspeed = min(0, myspeed + frametime * g_bugrigs_friction_floor);
			}
		}
		else
		{
			if(myspeed >= 0)
			{
				myspeed = max(0, myspeed - frametime * g_bugrigs_friction_floor);
			}
			else
			{
				if(g_bugrigs_reverse_stopping)
					myspeed = 0;
				else
					myspeed = min(0, myspeed + frametime * (g_bugrigs_friction_floor + g_bugrigs_friction_brake * accel));
			}
		}
		// terminal velocity = velocity at which 50 == accelfactor, that is, 1549 units/sec
		//MAXIMA: friction(v) := g_bugrigs_friction_floor;

		self.angles_y += steer * frametime * steerfactor; // apply steering
		makevectors(self.angles); // new forward direction!

		myspeed += accel * accelfactor * frametime;

		rigvel = myspeed * v_forward + '0 0 1' * upspeed;
	}
	else
	{
		myspeed = vlen(self.velocity);

		// responsiveness factor for steering and acceleration
		f = 1 / (1 + pow(max(0, myspeed / g_bugrigs_speed_ref), g_bugrigs_speed_pow));
		steerfactor = -myspeed * f;
		self.angles_y += steer * frametime * steerfactor; // apply steering

		rigvel = self.velocity;
		makevectors(self.angles); // new forward direction!
	}

	rigvel = rigvel * max(0, 1 - vlen(rigvel) * g_bugrigs_friction_air * frametime);
	//MAXIMA: airfriction(v) := v * v * g_bugrigs_friction_air;
	//MAXIMA: total_acceleration(v) := accel(v) - friction(v) - airfriction(v);
	//MAXIMA: solve(total_acceleration(v) = 0, v);

	if(g_bugrigs_planar_movement)
	{
		vector rigvel_xy, neworigin, up;
		float mt;

		rigvel_z -= frametime * autocvar_sv_gravity; // 4x gravity plays better
		rigvel_xy = vec2(rigvel);

		if(g_bugrigs_planar_movement_car_jumping)
			mt = MOVE_NORMAL;
		else
			mt = MOVE_NOMONSTERS;

		tracebox(self.origin, self.mins, self.maxs, self.origin + '0 0 1024', mt, self);
		up = trace_endpos - self.origin;

		// BUG RIGS: align the move to the surface instead of doing collision testing
		// can we move?
		tracebox(trace_endpos, self.mins, self.maxs, trace_endpos + rigvel_xy * frametime, mt, self);

		// align to surface
		tracebox(trace_endpos, self.mins, self.maxs, trace_endpos - up + '0 0 1' * rigvel_z * frametime, mt, self);

		if(trace_fraction < 0.5)
		{
			trace_fraction = 1;
			neworigin = self.origin;
		}
		else
			neworigin = trace_endpos;

		if(trace_fraction < 1)
		{
			// now set angles_x so that the car points parallel to the surface
			self.angles = vectoangles(
					'1 0 0' * v_forward_x * trace_plane_normal_z
					+
					'0 1 0' * v_forward_y * trace_plane_normal_z
					+
					'0 0 1' * -(v_forward_x * trace_plane_normal_x + v_forward_y * trace_plane_normal_y)
					);
			self.flags |= FL_ONGROUND;
		}
		else
		{
			// now set angles_x so that the car points forward, but is tilted in velocity direction
			self.flags &= ~FL_ONGROUND;
		}

		self.velocity = (neworigin - self.origin) * (1.0 / frametime);
		self.movetype = MOVETYPE_NOCLIP;
	}
	else
	{
		rigvel_z -= frametime * autocvar_sv_gravity; // 4x gravity plays better
		self.velocity = rigvel;
		self.movetype = MOVETYPE_FLY;
	}

	trace_fraction = 1;
	tracebox(self.origin, self.mins, self.maxs, self.origin - '0 0 4', MOVE_NORMAL, self);
	if(trace_fraction != 1)
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
	f = bound(0, frametime * g_bugrigs_angle_smoothing, 1);
	if(f == 0)
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
	if(!CheatImpulse(99))
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
	return 0;
#endif
}

void PM_check_race_movetime(void)
{
#ifdef SVQC
	self.race_movetime_frac += frametime;
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
	if(!buttons)
		c = "x";
	else if(buttons == 1)
		c = "1";
	else if(buttons == 2)
		c = " ";
	else if(buttons == 128)
		c = "s";
	else if(buttons == 256)
		c = "w";
	else if(buttons == 512)
		c = "a";
	else if(buttons == 1024)
		c = "d";
	else
		c = "?";

	if(c == substring(specialcommand, self.specialcommand_pos, 1))
	{
		self.specialcommand_pos += 1;
		if(self.specialcommand_pos >= strlen(specialcommand))
		{
			self.specialcommand_pos = 0;
			SpecialCommand();
			return TRUE;
		}
	}
	else if(self.specialcommand_pos && (c != substring(specialcommand, self.specialcommand_pos - 1, 1)))
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
		self.movement = -1 * self.movement;
		self.BUTTON_ATCK = self.BUTTON_JUMP = self.BUTTON_ATCK2 = self.BUTTON_ZOOM = self.BUTTON_CROUCH = self.BUTTON_HOOK = self.BUTTON_USE = 0;

		if (self.nickspamcount >= autocvar_g_nick_flood_penalty_red) // if you are persistent and the slight annoyance above does not stop you, I'll show you!
		{
			self.angles_x = random() * 360;
			self.angles_y = random() * 360;
			// at least I'm not forcing retardedview by also assigning to angles_z
			self.fixangle = TRUE;
		}
	}
#endif
}

void PM_check_punch()
{
#ifdef SVQC
	float f;
	if (self.punchangle != '0 0 0')
	{
		f = vlen(self.punchangle) - 10 * frametime;
		if (f > 0)
			self.punchangle = normalize(self.punchangle) * f;
		else
			self.punchangle = '0 0 0';
	}

	if (self.punchvector != '0 0 0')
	{
		f = vlen(self.punchvector) - 30 * frametime;
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
	if(time < self.spider_slowness)
	{
		self.stat_sv_maxspeed *= 0.5; // half speed while slow from spider
		self.stat_sv_airspeedlimit_nonqw *= 0.5;
	}
#endif
}

void PM_check_frozen(void)
{
#ifdef SVQC
	if(!self.frozen)
		return;
	if(autocvar_sv_dodging_frozen && IS_REAL_CLIENT(self))
	{
		self.movement_x = bound(-5, self.movement_x, 5);
		self.movement_y = bound(-5, self.movement_y, 5);
		self.movement_z = bound(-5, self.movement_z, 5);
	}
	else
		self.movement = '0 0 0';
	self.disableclientprediction = 1;

	vector midpoint = ((self.absmin + self.absmax) * 0.5);
	if(pointcontents(midpoint) == CONTENT_WATER)
	{
		self.velocity = self.velocity * 0.5;

		if(pointcontents(midpoint + '0 0 16') == CONTENT_WATER)
			self.velocity_z = 200;
	}
#endif
}

void PM_check_blocked(void)
{
#ifdef SVQC
	if(self.player_blocked)
	{
		self.movement = '0 0 0';
		self.disableclientprediction = 1;
	}
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
	if(vlen(self.velocity - self.velocity_z * '0 0 1') > speedaward_speed)
	{
		speedaward_speed = vlen(self.velocity - self.velocity_z * '0 0 1');
		speedaward_holder = self.netname;
		speedaward_uid = self.crypto_idfp;
		speedaward_lastupdate = time;
	}
	if(speedaward_speed > speedaward_lastsent && time - speedaward_lastupdate > 1)
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
	float xyspeed;
	xyspeed = vlen('1 0 0' * self.velocity_x + '0 1 0' * self.velocity_y);
	if(self.weapon == WEP_NEX && autocvar_g_balance_nex_charge && autocvar_g_balance_nex_charge_velocity_rate && xyspeed > autocvar_g_balance_nex_charge_minspeed)
	{
		// add a maximum of charge_velocity_rate when going fast (f = 1), gradually increasing from minspeed (f = 0) to maxspeed
		xyspeed = min(xyspeed, autocvar_g_balance_nex_charge_maxspeed);
		float f = (xyspeed - autocvar_g_balance_nex_charge_minspeed) / (autocvar_g_balance_nex_charge_maxspeed - autocvar_g_balance_nex_charge_minspeed);
		// add the extra charge
		self.nex_charge = min(1, self.nex_charge + autocvar_g_balance_nex_charge_velocity_rate * f * frametime);
	}
#endif
}

void PM_fly(float maxspd_mod)
{
#ifdef SVQC
	// noclipping or flying
	self.flags &= ~FL_ONGROUND;

	self.velocity = self.velocity * (1 - frametime * autocvar_sv_friction);
	makevectors(self.v_angle);
	//wishvel = v_forward * self.movement_x + v_right * self.movement_y + v_up * self.movement_z;
	vector wishvel = v_forward * self.movement_x + v_right * self.movement_y + '0 0 1' * self.movement_z;
	// acceleration
	vector wishdir = normalize(wishvel);
	float wishspeed = vlen(wishvel);
	if (wishspeed > self.stat_sv_maxspeed*maxspd_mod)
		wishspeed = self.stat_sv_maxspeed*maxspd_mod;
	if (time >= self.teleport_time)
		PM_Accelerate(self, wishdir, wishspeed, wishspeed, autocvar_sv_accelerate*maxspd_mod, 1, 0, 0, 0);
#endif
}

void PM_swim(float maxspd_mod)
{
#ifdef SVQC
	// swimming
	self.flags &= ~FL_ONGROUND;

	makevectors(self.v_angle);
	//wishvel = v_forward * self.movement_x + v_right * self.movement_y + v_up * self.movement_z;
	vector wishvel = v_forward * self.movement_x + v_right * self.movement_y + '0 0 1' * self.movement_z;
	if (wishvel == '0 0 0')
		wishvel = '0 0 -60'; // drift towards bottom

	vector wishdir = normalize(wishvel);
	float wishspeed = vlen(wishvel);
	if (wishspeed > self.stat_sv_maxspeed*maxspd_mod)
		wishspeed = self.stat_sv_maxspeed*maxspd_mod;
	wishspeed = wishspeed * 0.7;

	// water friction
	self.velocity = self.velocity * (1 - frametime * autocvar_sv_friction);

	// water acceleration
	PM_Accelerate(self, wishdir, wishspeed, wishspeed, autocvar_sv_accelerate*maxspd_mod, 1, 0, 0, 0);
#endif
}

void PM_ladder(float maxspd_mod)
{
#ifdef SVQC
	// on a spawnfunc_func_ladder or swimming in spawnfunc_func_water
	self.flags &= ~FL_ONGROUND;

	float g;
	g = autocvar_sv_gravity * frametime;
	if(self.gravity)
		g *= self.gravity;
	if(autocvar_sv_gameplayfix_gravityunaffectedbyticrate)
	{
		g *= 0.5;
		self.velocity_z += g;
	}

	self.velocity = self.velocity * (1 - frametime * autocvar_sv_friction);
	makevectors(self.v_angle);
	//wishvel = v_forward * self.movement_x + v_right * self.movement_y + v_up * self.movement_z;
	vector wishvel = v_forward * self.movement_x + v_right * self.movement_y + '0 0 1' * self.movement_z;
	self.velocity_z += g;
	if (self.ladder_entity.classname == "func_water")
	{
		float f = vlen(wishvel);
		if (f > self.ladder_entity.speed)
			wishvel = wishvel * (self.ladder_entity.speed / f);

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
	float wishspeed = vlen(wishvel);
	if (wishspeed > self.stat_sv_maxspeed*maxspd_mod)
		wishspeed = self.stat_sv_maxspeed*maxspd_mod;
	if (time >= self.teleport_time)
	{
		// water acceleration
		PM_Accelerate(self, wishdir, wishspeed, wishspeed, autocvar_sv_accelerate*maxspd_mod, 1, 0, 0, 0);
	}
#endif
}

void PM_jetpack(float maxspd_mod)
{
#ifdef SVQC
	//makevectors(self.v_angle_y * '0 1 0');
	makevectors(self.v_angle);
	vector wishvel = v_forward * self.movement_x + v_right * self.movement_y;
	// add remaining speed as Z component
	float maxairspd = autocvar_sv_maxairspeed*max(1, maxspd_mod);
	// fix speedhacks :P
	wishvel = normalize(wishvel) * min(vlen(wishvel) / maxairspd, 1);
	// add the unused velocity as up component
	wishvel_z = 0;

	// if(self.BUTTON_JUMP)
		wishvel_z = sqrt(max(0, 1 - wishvel * wishvel));

	// it is now normalized, so...
	float a_side, a_up, a_add, a_diff;
	a_side = autocvar_g_jetpack_acceleration_side;
	a_up = autocvar_g_jetpack_acceleration_up;
	a_add = autocvar_g_jetpack_antigravity * autocvar_sv_gravity;

	wishvel_x *= a_side;
	wishvel_y *= a_side;
	wishvel_z *= a_up;
	wishvel_z += a_add;

	float best;
	best = 0;
	//////////////////////////////////////////////////////////////////////////////////////
	// finding the maximum over all vectors of above form
	// with wishvel having an absolute value of 1
	//////////////////////////////////////////////////////////////////////////////////////
	// we're finding the maximum over
	//   f(a_side, a_up, a_add, z) := a_side * (1 - z^2) + (a_add + a_up * z)^2;
	// for z in the range from -1 to 1
	//////////////////////////////////////////////////////////////////////////////////////
	// maximum is EITHER attained at the single extreme point:
	a_diff = a_side * a_side - a_up * a_up;
	float f;
	if(a_diff != 0)
	{
		f = a_add * a_up / a_diff; // this is the zero of diff(f(a_side, a_up, a_add, z), z)
		if(f > -1 && f < 1) // can it be attained?
		{
			best = (a_diff + a_add * a_add) * (a_diff + a_up * a_up) / a_diff;
			//print("middle\n");
		}
	}
	// OR attained at z = 1:
	f = (a_up + a_add) * (a_up + a_add);
	if(f > best)
	{
		best = f;
		//print("top\n");
	}
	// OR attained at z = -1:
	f = (a_up - a_add) * (a_up - a_add);
	if(f > best)
	{
		best = f;
		//print("bottom\n");
	}
	best = sqrt(best);
	//////////////////////////////////////////////////////////////////////////////////////

	//print("best possible acceleration: ", ftos(best), "\n");

	float fxy, fz;
	fxy = bound(0, 1 - (self.velocity * normalize(wishvel_x * '1 0 0' + wishvel_y * '0 1 0')) / autocvar_g_jetpack_maxspeed_side, 1);
	if(wishvel_z - autocvar_sv_gravity > 0)
		fz = bound(0, 1 - self.velocity_z / autocvar_g_jetpack_maxspeed_up, 1);
	else
		fz = bound(0, 1 + self.velocity_z / autocvar_g_jetpack_maxspeed_up, 1);

	float fvel;
	fvel = vlen(wishvel);
	wishvel_x *= fxy;
	wishvel_y *= fxy;
	wishvel_z = (wishvel_z - autocvar_sv_gravity) * fz + autocvar_sv_gravity;

	fvel = min(1, vlen(wishvel) / best);
	if(autocvar_g_jetpack_fuel && !(self.items & IT_UNLIMITED_WEAPON_AMMO))
		f = min(1, self.ammo_fuel / (autocvar_g_jetpack_fuel * frametime * fvel));
	else
		f = 1;

	//print("this acceleration: ", ftos(vlen(wishvel) * f), "\n");

	if (f > 0 && wishvel != '0 0 0')
	{
		self.velocity = self.velocity + wishvel * f * frametime;
		if (!(self.items & IT_UNLIMITED_WEAPON_AMMO))
			self.ammo_fuel -= autocvar_g_jetpack_fuel * frametime * fvel * f;
		self.flags &= ~FL_ONGROUND;
		self.items |= IT_USING_JETPACK;

		// jetpack also inhibits health regeneration, but only for 1 second
		self.pauseregen_finished = max(self.pauseregen_finished, time + autocvar_g_balance_pause_fuel_regen);
	}
#endif
}

void PM_walk(float buttons_prev, float maxspd_mod)
{
#ifdef SVQC
	// we get here if we ran out of ammo
	if((self.items & IT_JETPACK) && self.BUTTON_HOOK && !(buttons_prev & 32) && self.ammo_fuel < 0.01)
		sprint(self, "You don't have any fuel for the ^2Jetpack\n");

	// walking
	makevectors(self.v_angle_y * '0 1 0');
	vector wishvel = v_forward * self.movement_x + v_right * self.movement_y;

	if(!(self.lastflags & FL_ONGROUND))
	{
		if(autocvar_speedmeter)
			dprint(strcat("landing velocity: ", vtos(self.velocity), " (abs: ", ftos(vlen(self.velocity)), ")\n"));
		if(self.lastground < time - 0.3)
			self.velocity = self.velocity * (1 - autocvar_sv_friction_on_land);
		if(self.jumppadcount > 1)
			dprint(strcat(ftos(self.jumppadcount), "x jumppad combo\n"));
		self.jumppadcount = 0;
	}

#ifdef LETS_TEST_FTEQCC
	if(self.velocity_x || self.velocity_y)
	{
		// good
	}
	else
	{
		if(self.velocity_x)
			checkclient();
		if(self.velocity_y)
			checkclient();
	}
#endif

	vector v = self.velocity;
	v_z = 0;
	float f = vlen(v);
	if(f > 0)
	{
		if (f < autocvar_sv_stopspeed)
			f = 1 - frametime * (autocvar_sv_stopspeed / f) * autocvar_sv_friction;
		else
			f = 1 - frametime * autocvar_sv_friction;
		if (f > 0)
			self.velocity = self.velocity * f;
		else
			self.velocity = '0 0 0';
		/*
		   Mathematical analysis time!

		   Our goal is to invert this mess.

		   For the two cases we get:
			v = v0 * (1 - frametime * (autocvar_sv_stopspeed / v0) * autocvar_sv_friction)
			  = v0 - frametime * autocvar_sv_stopspeed * autocvar_sv_friction
			v0 = v + frametime * autocvar_sv_stopspeed * autocvar_sv_friction
		   and
			v = v0 * (1 - frametime * autocvar_sv_friction)
			v0 = v / (1 - frametime * autocvar_sv_friction)

		   These cases would be chosen ONLY if:
			v0 < autocvar_sv_stopspeed
			v + frametime * autocvar_sv_stopspeed * autocvar_sv_friction < autocvar_sv_stopspeed
			v < autocvar_sv_stopspeed * (1 - frametime * autocvar_sv_friction)
		   and, respectively:
			v0 >= autocvar_sv_stopspeed
			v / (1 - frametime * autocvar_sv_friction) >= autocvar_sv_stopspeed
			v >= autocvar_sv_stopspeed * (1 - frametime * autocvar_sv_friction)
		 */
	}

	// acceleration
	vector wishdir = normalize(wishvel);
	float wishspeed = vlen(wishvel);
	if (wishspeed > self.stat_sv_maxspeed*maxspd_mod)
		wishspeed = self.stat_sv_maxspeed*maxspd_mod;
	if (self.crouch)
		wishspeed = wishspeed * 0.5;
	if (time >= self.teleport_time)
		PM_Accelerate(self, wishdir, wishspeed, wishspeed, autocvar_sv_accelerate*maxspd_mod, 1, 0, 0, 0);
#endif
}

void PM_air(float buttons_prev, float maxspd_mod)
{
#ifdef SVQC
	float wishspeed0;
	// we get here if we ran out of ammo
	if((self.items & IT_JETPACK) && self.BUTTON_HOOK && !(buttons_prev & 32) && self.ammo_fuel < 0.01)
		sprint(self, "You don't have any fuel for the ^2Jetpack\n");

	float maxairspd, airaccel;
	if(maxspd_mod < 1)
	{
		maxairspd = autocvar_sv_maxairspeed*maxspd_mod;
		airaccel = autocvar_sv_airaccelerate*maxspd_mod;
	}
	else
	{
		maxairspd = autocvar_sv_maxairspeed;
		airaccel = autocvar_sv_airaccelerate;
	}
	// airborn
	makevectors(self.v_angle_y * '0 1 0');
	vector wishvel = v_forward * self.movement_x + v_right * self.movement_y;
	// acceleration
	vector wishdir = normalize(wishvel);
	float wishspeed = wishspeed0 = vlen(wishvel);
	if (wishspeed0 > self.stat_sv_maxspeed*maxspd_mod)
		wishspeed0 = self.stat_sv_maxspeed*maxspd_mod;
	if (wishspeed > maxairspd)
		wishspeed = maxairspd;
	if (self.crouch)
		wishspeed = wishspeed * 0.5;
	if (time >= self.teleport_time)
	{
		float accelerating;
		float wishspeed2;
		float airaccelqw;
		float strafity;

		airaccelqw = self.stat_sv_airaccel_qw;
		accelerating = (self.velocity * wishdir > 0);
		wishspeed2 = wishspeed;

		// CPM
		if(autocvar_sv_airstopaccelerate)
		{
			vector curdir;
			curdir = self.velocity;
			curdir_z = 0;
			curdir = normalize(curdir);
			airaccel = airaccel + (autocvar_sv_airstopaccelerate*maxspd_mod - airaccel) * max(0, -(curdir * wishdir));
		}
		// note that for straight forward jumping:
		// step = accel * frametime * wishspeed0;
		// accel  = bound(0, wishspeed - vel_xy_current, step) * accelqw + step * (1 - accelqw);
		// -->
		// dv/dt = accel * maxspeed (when slow)
		// dv/dt = accel * maxspeed * (1 - accelqw) (when fast)
		// log dv/dt = logaccel + logmaxspeed (when slow)
		// log dv/dt = logaccel + logmaxspeed + log(1 - accelqw) (when fast)
		strafity = IsMoveInDirection(self.movement, -90) + IsMoveInDirection(self.movement, +90); // if one is nonzero, other is always zero
		if(autocvar_sv_maxairstrafespeed)
			wishspeed = min(wishspeed, GeomLerp(autocvar_sv_maxairspeed*maxspd_mod, strafity, autocvar_sv_maxairstrafespeed*maxspd_mod));
		if(autocvar_sv_airstrafeaccelerate)
			airaccel = GeomLerp(airaccel, strafity, autocvar_sv_airstrafeaccelerate*maxspd_mod);
		if(self.stat_sv_airstrafeaccel_qw)
			airaccelqw = copysign(1-GeomLerp(1-fabs(self.stat_sv_airaccel_qw), strafity, 1-fabs(self.stat_sv_airstrafeaccel_qw)), ((strafity > 0.5) ? self.stat_sv_airstrafeaccel_qw : self.stat_sv_airaccel_qw));
		// !CPM

		if(autocvar_sv_warsowbunny_turnaccel && accelerating && self.movement_y == 0 && self.movement_x != 0)
			PM_AirAccelerate(self, wishdir, wishspeed);
		else
			PM_Accelerate(self, wishdir, wishspeed, wishspeed0, airaccel, airaccelqw, autocvar_sv_airaccel_qw_stretchfactor, autocvar_sv_airaccel_sideways_friction / maxairspd, self.stat_sv_airspeedlimit_nonqw);

		if(autocvar_sv_aircontrol)
			CPM_PM_Aircontrol(self, wishdir, wishspeed2);
	}
#endif
}

// TODO: merge this with main physics frame
void CSQC_ClientMovement_Physics_Walk(entity s)
{
	float friction;
	float wishspeed;
	float addspeed;
	float accelspeed;
	float f;
	float g;
	vector wishvel;
	vector wishdir;
	vector yawangles;

	// jump if on ground with jump button pressed but only if it has been
	// released at least once since the last jump
	if (PHYS_INPUT_BUTTONS(s) & 2)
	{
		if (IS_ONGROUND(s) && (!IS_JUMP_HELD(s) || !cvar("cl_movement_track_canjump")))
		{
			s.velocity_z += PHYS_JUMPVELOCITY;
			UNSET_ONGROUND(s);
			SET_JUMP_HELD(s); // canjump = false
		}
	}
	else
		UNSET_JUMP_HELD(s); // canjump = true

	// calculate movement vector
	yawangles = '0 0 0';
	yawangles_y = PHYS_INPUT_ANGLES(s)_y;
	makevectors(yawangles);
	wishvel = PHYS_INPUT_MOVEVALUES(s)_x * v_forward + PHYS_INPUT_MOVEVALUES(s)_y * v_right;

	// split wishvel into wishspeed and wishdir
	wishspeed = vlen(wishvel);
	if (wishspeed)
		wishdir = wishvel / wishspeed;
	else
		wishdir = '0 0 0';
	// check if onground
	if (IS_ONGROUND(s))
	{
		wishspeed = min(wishspeed, PHYS_MAXSPEED(s));
		if (IS_DUCKED(s))
			wishspeed *= 0.5;

		// apply edge friction
		f = sqrt(s.velocity_x * s.velocity_x + s.velocity_y * s.velocity_y);
		if (f > 0)
		{
			friction = PHYS_FRICTION;
			if (PHYS_EDGEFRICTION != 1)
			{
				vector neworigin2;
				vector neworigin3;
				// note: QW uses the full player box for the trace, and yet still
				// uses s.origin_z + s.mins_z, which is clearly an bug, but
				// this mimics it for compatibility
				neworigin2 = s.origin;
				neworigin2_x += s.velocity_x*(16/f);
				neworigin2_y += s.velocity_y*(16/f);
				neworigin2_z += s.mins_z;
				neworigin3 = neworigin2;
				neworigin3_z -= 34;
				traceline(neworigin2, neworigin3, MOVE_NORMAL, s);
				if (trace_fraction == 1 && !trace_startsolid)
					friction *= PHYS_EDGEFRICTION;
			}
			// apply ground friction
			f = 1 - PHYS_INPUT_TIMELENGTH * friction * ((f < PHYS_STOPSPEED) ? (PHYS_STOPSPEED / f) : 1);
			f = max(f, 0);
			s.velocity *= f;
		}
		addspeed = wishspeed - dotproduct(s.velocity, wishdir);
		if (addspeed > 0)
		{
			accelspeed = min(PHYS_ACCELERATE * PHYS_INPUT_TIMELENGTH * wishspeed, addspeed);
			s.velocity += accelspeed * wishdir;
		}
		g = PHYS_GRAVITY * PHYS_ENTGRAVITY(s) * PHYS_INPUT_TIMELENGTH;
		if(!(GAMEPLAYFIX_NOGRAVITYONGROUND))
		{
			if(GAMEPLAYFIX_GRAVITYUNAFFECTEDBYTICRATE)
				s.velocity_z -= g * 0.5;
			else
				s.velocity_z -= g;
		}
		if (VLEN2(s.velocity))
			CSQC_ClientMovement_Move(s);
		if(!(GAMEPLAYFIX_NOGRAVITYONGROUND) || !IS_ONGROUND(s))
		{
			if(GAMEPLAYFIX_GRAVITYUNAFFECTEDBYTICRATE)
				s.velocity_z -= g * 0.5;
		}
	}
	else
	{
		if (pmove_waterjumptime <= 0)
		{
			// apply air speed limit
			float accel, wishspeed0, wishspeed2, accelqw, strafity;
			float accelerating;

			accelqw = PHYS_AIRACCEL_QW;
			wishspeed0 = wishspeed;
			wishspeed = min(wishspeed, PHYS_MAXAIRSPEED);
			if (IS_DUCKED(s))
				wishspeed *= 0.5;
			accel = PHYS_AIRACCELERATE;

			accelerating = (dotproduct(s.velocity, wishdir) > 0);
			wishspeed2 = wishspeed;

			// CPM: air control
			if(PHYS_AIRSTOPACCELERATE != 0)
			{
				vector curdir;
				curdir_x = s.velocity_x;
				curdir_y = s.velocity_y;
				curdir_z = 0;
				curdir = normalize(curdir);
				accel = accel + (PHYS_AIRSTOPACCELERATE - accel) * max(0, -dotproduct(curdir, wishdir));
			}
			strafity = IsMoveInDirection(PHYS_INPUT_MOVEVALUES(s), -90) + IsMoveInDirection(PHYS_INPUT_MOVEVALUES(s), +90); // if one is nonzero, other is always zero
			if(PHYS_MAXAIRSTRAFESPEED)
				wishspeed = min(wishspeed, GeomLerp(PHYS_MAXAIRSPEED, strafity, PHYS_MAXAIRSTRAFESPEED));
			if(PHYS_AIRSTRAFEACCELERATE)
				accel = GeomLerp(PHYS_AIRACCELERATE, strafity, PHYS_AIRSTRAFEACCELERATE);
			if(PHYS_AIRSTRAFEACCEL_QW)
				accelqw =
					(((strafity > 0.5 ? PHYS_AIRSTRAFEACCEL_QW : PHYS_AIRACCEL_QW) >= 0) ? +1 : -1)
					*
					(1 - GeomLerp(1 - fabs(PHYS_AIRACCEL_QW), strafity, 1 - fabs(PHYS_AIRSTRAFEACCEL_QW)));
			// !CPM

			if(PHYS_WARSOWBUNNY_TURNACCEL && accelerating && PHYS_INPUT_MOVEVALUES(s)_y == 0 && PHYS_INPUT_MOVEVALUES(s)_x != 0)
				PM_AirAccelerate(s, wishdir, wishspeed2);
			else
				PM_Accelerate(s, wishdir, wishspeed, wishspeed0, accel, accelqw, PHYS_AIRACCEL_QW_STRETCHFACTOR, PHYS_AIRACCEL_SIDEWAYS_FRICTION / PHYS_MAXAIRSPEED, PHYS_AIRSPEEDLIMIT_NONQW);

			if(PHYS_AIRCONTROL)
				CPM_PM_Aircontrol(s, wishdir, wishspeed2);
		}
		g = PHYS_GRAVITY * PHYS_ENTGRAVITY(s) * PHYS_INPUT_TIMELENGTH;
		if(GAMEPLAYFIX_GRAVITYUNAFFECTEDBYTICRATE)
			s.velocity_z -= g * 0.5;
		else
			s.velocity_z -= g;
		CSQC_ClientMovement_Move(s);
		if(!(GAMEPLAYFIX_NOGRAVITYONGROUND) || !IS_ONGROUND(s))
		{
			if(GAMEPLAYFIX_GRAVITYUNAFFECTEDBYTICRATE)
				s.velocity_z -= g * 0.5;
		}
	}
}

// TODO: merge this with main physics frame
void CSQC_ClientMovement_Physics_Swim(entity s)
{
	// swimming
	self.flags &= ~FL_ONGROUND;

	makevectors(PHYS_INPUT_ANGLES(s));
	//wishvel = v_forward * self.movement_x + v_right * self.movement_y + v_up * self.movement_z;
	vector wishvel = v_forward * PHYS_INPUT_MOVEVALUES(s)_x + v_right * PHYS_INPUT_MOVEVALUES(s)_y + '0 0 1' * PHYS_INPUT_MOVEVALUES(s)_z;
	if (wishvel == '0 0 0')
		wishvel = '0 0 -60'; // drift towards bottom

	vector wishdir = normalize(wishvel);
	float wishspeed = vlen(wishvel);
	if (wishspeed > PHYS_MAXSPEED(s))
		wishspeed = PHYS_MAXSPEED(s);
	wishspeed = wishspeed * 0.7;

	// water friction
	self.velocity = self.velocity * (1 - PHYS_INPUT_TIMELENGTH * PHYS_FRICTION);

	// water acceleration
	PM_Accelerate(s, wishdir, wishspeed, wishspeed, PHYS_ACCELERATE, 1, 0, 0, 0);
}

void PM_Main(entity s)
{
#ifdef CSQC
	//Con_Printf(" %f", frametime);
	if (!(PHYS_INPUT_BUTTONS(s) & 2)) // !jump
		UNSET_JUMP_HELD(s); // canjump = true
	pmove_waterjumptime -= PHYS_INPUT_TIMELENGTH;
	CSQC_ClientMovement_UpdateStatus(s);
#endif
#ifdef SVQC
	float maxspd_mod, buttons;
	float buttons_prev;
	float not_allowed_to_move;

	WarpZone_PlayerPhysics_FixVAngle();

	maxspd_mod = 1;
	maxspd_mod *= PM_check_keepaway();
	maxspd_mod *= autocvar_g_movement_highspeed;

	// fix physics stats for g_movement_highspeed
	// TODO maybe rather use maxairspeed? needs testing
	self.stat_sv_airaccel_qw = AdjustAirAccelQW(autocvar_sv_airaccel_qw, maxspd_mod);
	if(autocvar_sv_airstrafeaccel_qw)
		self.stat_sv_airstrafeaccel_qw = AdjustAirAccelQW(autocvar_sv_airstrafeaccel_qw, maxspd_mod);
	else
		self.stat_sv_airstrafeaccel_qw = 0;
	self.stat_sv_airspeedlimit_nonqw = autocvar_sv_airspeedlimit_nonqw * maxspd_mod;
	self.stat_sv_maxspeed = autocvar_sv_maxspeed * maxspd_mod; // also slow walking
	self.stat_movement_highspeed = autocvar_g_movement_highspeed;

    if(self.PlayerPhysplug)
        if(self.PlayerPhysplug())
            return;

	PM_check_race_movetime();

	anticheat_physics();

	buttons = self.BUTTON_ATCK + 2 * self.BUTTON_JUMP + 4 * self.BUTTON_ATCK2 + 8 * self.BUTTON_ZOOM + 16 * self.BUTTON_CROUCH + 32 * self.BUTTON_HOOK + 64 * self.BUTTON_USE + 128 * (self.movement_x < 0) + 256 * (self.movement_x > 0) + 512 * (self.movement_y < 0) + 1024 * (self.movement_y > 0);

	if (PM_check_specialcommand(buttons))
		return;

	if(sv_maxidle > 0)
	{
		if(buttons != self.buttons_old || self.movement != self.movement_old || self.v_angle != self.v_angle_old)
			self.parm_idlesince = time;
	}
	buttons_prev = self.buttons_old;
	self.buttons_old = buttons;
	self.movement_old = self.movement;
	self.v_angle_old = self.v_angle;

	PM_check_nickspam();

	PM_check_punch();

	if (IS_BOT_CLIENT(self))
	{
		if(playerdemo_read())
			return;
		bot_think();
	}

	self.items &= ~IT_USING_JETPACK;

	if(IS_PLAYER(self))
	{
		if(self.race_penalty)
			if(time > self.race_penalty)
				self.race_penalty = 0;

		not_allowed_to_move = 0;
		if(self.race_penalty)
			not_allowed_to_move = 1;
		if(!autocvar_sv_ready_restart_after_countdown)
		if(time < game_starttime)
			not_allowed_to_move = 1;

		if(not_allowed_to_move)
		{
			self.velocity = '0 0 0';
			self.movetype = MOVETYPE_NONE;
			self.disableclientprediction = 2;
		}
		else if(self.disableclientprediction == 2)
		{
			if(self.movetype == MOVETYPE_NONE)
				self.movetype = MOVETYPE_WALK;
			self.disableclientprediction = 0;
		}
	}

	if (self.movetype == MOVETYPE_NONE)
		return;

	// when we get here, disableclientprediction cannot be 2
	self.disableclientprediction = 0;
	if(time < self.ladder_time)
		self.disableclientprediction = 1;

	PM_check_spider();

	PM_check_frozen();

	MUTATOR_CALLHOOK(PlayerPhysics);

	PM_check_blocked();

	maxspd_mod = 1;

	if(self.in_swamp) {
		maxspd_mod *= self.swamp_slowdown; //cvar("g_balance_swamp_moverate");
	}

	// conveyors: first fix velocity
	if(self.conveyor.state)
		self.velocity -= self.conveyor.movedir;

	if (!IS_PLAYER(self))
	{
		maxspd_mod *= autocvar_sv_spectator_speed_multiplier;
		if(!self.spectatorspeed)
			self.spectatorspeed = maxspd_mod;
		if(self.impulse && self.impulse <= 19 || (self.impulse >= 200 && self.impulse <= 209) || (self.impulse >= 220 && self.impulse <= 229))
		{
			if(self.lastclassname != "player")
			{
				if(self.impulse == 10 || self.impulse == 15 || self.impulse == 18 || (self.impulse >= 200 && self.impulse <= 209))
					self.spectatorspeed = bound(1, self.spectatorspeed + 0.5, 5);
				else if(self.impulse == 11)
					self.spectatorspeed = maxspd_mod;
				else if(self.impulse == 12 || self.impulse == 16  || self.impulse == 19 || (self.impulse >= 220 && self.impulse <= 229))
					self.spectatorspeed = bound(1, self.spectatorspeed - 0.5, 5);
				else if(self.impulse >= 1 && self.impulse <= 9)
					self.spectatorspeed = 1 + 0.5 * (self.impulse - 1);
			} // otherwise just clear
			self.impulse = 0;
		}
		maxspd_mod *= self.spectatorspeed;
	}

	// if dead, behave differently
	if (self.deadflag)
		goto end;

	if (!self.fixangle && !g_bugrigs)
	{
		self.angles_x = 0;
		self.angles_y = self.v_angle_y;
		self.angles_z = 0;
	}

	if(self.flags & FL_ONGROUND)
	if(IS_PLAYER(self)) // no fall sounds for observers thank you very much
	if(self.wasFlying)
	{
		self.wasFlying = 0;

		if(self.waterlevel < WATERLEVEL_SWIMMING)
		if(time >= self.ladder_time)
		if (!self.hook)
		{
			self.nextstep = time + 0.3 + random() * 0.1;
			trace_dphitq3surfaceflags = 0;
			tracebox(self.origin, self.mins, self.maxs, self.origin - '0 0 1', MOVE_NOMONSTERS, self);
			if (!(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOSTEPS))
			{
				if(trace_dphitq3surfaceflags & Q3SURFACEFLAG_METALSTEPS)
					GlobalSound(globalsound_metalfall, CH_PLAYER, VOICETYPE_PLAYERSOUND);
				else
					GlobalSound(globalsound_fall, CH_PLAYER, VOICETYPE_PLAYERSOUND);
			}
		}
	}

	if(IsFlying(self))
		self.wasFlying = 1;

	if(IS_PLAYER(self))
		CheckPlayerJump();
#endif
#ifdef CSQC
	if (s.waterlevel >= WATERLEVEL_SWIMMING)
		CSQC_ClientMovement_Physics_Swim(s);
	else
		CSQC_ClientMovement_Physics_Walk(s);
#endif
#ifdef SVQC
	if (self.flags & FL_WATERJUMP )
	{
		self.velocity_x = self.movedir_x;
		self.velocity_y = self.movedir_y;
		if (time > self.teleport_time || self.waterlevel == WATERLEVEL_NONE)
		{
			self.flags &= ~FL_WATERJUMP;
			self.teleport_time = 0;
		}
	}
	else if (g_bugrigs && IS_PLAYER(self))
	{
		RaceCarPhysics();
	}
	else if (self.movetype == MOVETYPE_NOCLIP || self.movetype == MOVETYPE_FLY || self.movetype == MOVETYPE_FLY_WORLDONLY)
	{
		PM_fly(maxspd_mod);
	}
	else if (self.waterlevel >= WATERLEVEL_SWIMMING)
	{
		PM_swim(maxspd_mod);
	}
	else if (time < self.ladder_time)
	{
		PM_ladder(maxspd_mod);
	}
	else if ((self.items & IT_JETPACK) && self.BUTTON_HOOK && (!autocvar_g_jetpack_fuel || self.ammo_fuel >= 0.01 || self.items & IT_UNLIMITED_WEAPON_AMMO) && !self.frozen)
	{
		PM_jetpack(maxspd_mod);
	}
	else if (self.flags & FL_ONGROUND)
	{
		PM_walk(buttons_prev, maxspd_mod);
	}
	else
	{
		PM_air(buttons_prev, maxspd_mod);
	}
#endif
#ifdef SVQC
	if(!IS_OBSERVER(self))
		PM_check_race();

	PM_check_vortex();
:end
	if(self.flags & FL_ONGROUND)
		self.lastground = time;

	// conveyors: then break velocity again
	if(self.conveyor.state)
		self.velocity += self.conveyor.movedir;

	self.lastflags = self.flags;
	self.lastclassname = self.classname;
#endif
}

void CSQC_ClientMovement_PlayerMove_Frame(entity s)
{
	// if a move is more than 50ms, do it as two moves (matching qwsv)
	//Con_Printf("%i ", s.cmd.msec);
	if(PHYS_INPUT_TIMELENGTH > 0.0005)
	{
		if (PHYS_INPUT_TIMELENGTH > 0.05)
		{
			PHYS_INPUT_TIMELENGTH /= 2;
			PM_Main(s);
		}
		PM_Main(s);
	}
	else
	{
		// we REALLY need this handling to happen, even if the move is not executed
		if (!(PHYS_INPUT_BUTTONS(s) & 2)) // !jump
			UNSET_JUMP_HELD(s); // canjump = true
	}
}

#undef VLEN2

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
	PM_Main(self);
}
#endif