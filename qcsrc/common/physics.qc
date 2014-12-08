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

void CSQC_ClientMovement_PlayerMove(entity s)
{
	//Con_Printf(" %f", frametime);
	if (!(PHYS_INPUT_BUTTONS(s) & 2)) // !jump
		UNSET_JUMP_HELD(s); // canjump = true
	pmove_waterjumptime -= PHYS_INPUT_TIMELENGTH;
	CSQC_ClientMovement_UpdateStatus(s);
	if (s.waterlevel >= WATERLEVEL_SWIMMING)
		CSQC_ClientMovement_Physics_Swim(s);
	else
		CSQC_ClientMovement_Physics_Walk(s);
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
			CSQC_ClientMovement_PlayerMove(s);
		}
		CSQC_ClientMovement_PlayerMove(s);
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