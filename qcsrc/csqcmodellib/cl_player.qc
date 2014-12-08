/*
 * Copyright (c) 2011 Rudolf Polzer
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to
 * deal in the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
 * IN THE SOFTWARE.
 */

var float autocvar_cl_movement_errorcompensation = 0;
var float autocvar_cl_movement = 2; // testing purposes

// engine stuff
#define REFDEFFLAG_TELEPORTED 1
#define REFDEFFLAG_JUMPING 2
float pmove_onground; // weird engine flag we shouldn't really use but have to for now

vector csqcplayer_origin, csqcplayer_velocity;
float csqcplayer_sequence, player_pmflags;
float csqcplayer_moveframe;
vector csqcplayer_predictionerroro;
vector csqcplayer_predictionerrorv;
float csqcplayer_predictionerrortime;
float csqcplayer_predictionerrorfactor;

vector CSQCPlayer_GetPredictionErrorO()
{
	if(time >= csqcplayer_predictionerrortime)
		return '0 0 0';
	return csqcplayer_predictionerroro * (csqcplayer_predictionerrortime - time) * csqcplayer_predictionerrorfactor;
}

vector CSQCPlayer_GetPredictionErrorV()
{
	if(time >= csqcplayer_predictionerrortime)
		return '0 0 0';
	return csqcplayer_predictionerrorv * (csqcplayer_predictionerrortime - time) * csqcplayer_predictionerrorfactor;
}

void CSQCPlayer_SetPredictionError(vector o, vector v, float onground_diff)
{
	// error too big to compensate, we LIKELY hit a teleport or a
	// jumppad, or it's a jump time disagreement that'll get fixed
	// next frame

	// FIXME we sometimes have disagreement in order of jump velocity. Do not act on them!
	/*
	// commented out as this one did not help
	if(onground_diff)
	{
		printf("ONGROUND MISMATCH: %d x=%v v=%v\n", onground_diff, o, v);
		return;
	}
	*/
	if(vlen(o) > 32 || vlen(v) > 192)
	{
		//printf("TOO BIG: x=%v v=%v\n", o, v);
		return;
	}

	if(!autocvar_cl_movement_errorcompensation)
	{
		csqcplayer_predictionerrorfactor = 0;
		return;
	}

	csqcplayer_predictionerroro = CSQCPlayer_GetPredictionErrorO() + o;
	csqcplayer_predictionerrorv = CSQCPlayer_GetPredictionErrorV() + v;
	csqcplayer_predictionerrorfactor = autocvar_cl_movement_errorcompensation / ticrate;
	csqcplayer_predictionerrortime = time + 1.0 / csqcplayer_predictionerrorfactor;
}

void CSQCPlayer_Unpredict()
{
	if(csqcplayer_status == CSQCPLAYERSTATUS_UNPREDICTED)
		return;
	if(csqcplayer_status != CSQCPLAYERSTATUS_PREDICTED)
		error("Cannot unpredict in current status");
	self.origin = csqcplayer_origin;
	self.velocity = csqcplayer_velocity;
	csqcplayer_moveframe = csqcplayer_sequence+1; //+1 because the recieved frame has the move already done (server side)
	self.pmove_flags = player_pmflags;
}

void CSQCPlayer_SetMinsMaxs()
{
	if(self.pmove_flags & PMF_DUCKED)
	{
		self.mins = PL_CROUCH_MIN;
		self.maxs = PL_CROUCH_MAX;
		self.view_ofs = PL_CROUCH_VIEW_OFS;
	}
	else
	{
		self.mins = PL_MIN;
		self.maxs = PL_MAX;
		self.view_ofs = PL_VIEW_OFS;
	}
}

void CSQCPlayer_SavePrediction()
{
	player_pmflags = self.pmove_flags;
	csqcplayer_origin = self.origin;
	csqcplayer_velocity = self.velocity;
	csqcplayer_sequence = servercommandframe;
	csqcplayer_status = CSQCPLAYERSTATUS_PREDICTED;
}

// TODO: water prediction
float pmove_waterjumptime; // weird engine flag we shouldn't really use but have to for now
// TODO: move to a common header
#define vlen2(v) dotproduct(v, v)

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

float CSQC_ClientMovement_Unstick(entity s)
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
			return true;
		}
	}
	// if all offsets failed, give up
	return false;
}

void CSQC_ClientMovement_UpdateStatus(entity s)
{
	float f;
	vector origin1, origin2;

	// make sure player is not stuck
	CSQC_ClientMovement_Unstick(s);

	// set crouched
	if (input_buttons & 16)
	{
		// wants to crouch, this always works..
		if (!s.pmove_flags & PMF_DUCKED)
			s.pmove_flags |= PMF_DUCKED;
	}
	else
	{
		// wants to stand, if currently crouching we need to check for a
		// low ceiling first
		if (s.pmove_flags & PMF_DUCKED)
		{
			tracebox(s.origin, PL_MIN, PL_MAX, s.origin, MOVE_NORMAL, s);
			if (!trace_startsolid)
				s.pmove_flags &= ~PMF_DUCKED;
		}
	}
	if (s.pmove_flags & PMF_DUCKED)
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
		s.pmove_flags |= PMF_ONGROUND;

		// this code actually "predicts" an impact; so let's clip velocity first
		f = dotproduct(s.velocity, trace_plane_normal);
		if(f < 0) // only if moving downwards actually
			s.velocity -= f * trace_plane_normal;
	}
	else
		s.pmove_flags &= ~PMF_ONGROUND; // onground = false;

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
//	if ((s.pmove_flags & PMF_ONGROUND) || s.velocity_z <= 0 || pmove_waterjumptime <= 0)
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
	for (bump = 0, t = input_timelength; bump < 8 && vlen2(s.velocity) > 0; bump++)
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
			currentorigin2_z += getstatf(STAT_MOVEVARS_STEPHEIGHT);
			neworigin2 = neworigin;
			neworigin2_z = s.origin_z + getstatf(STAT_MOVEVARS_STEPHEIGHT);
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
			s.pmove_flags |= PMF_ONGROUND;

		t -= t * trace_fraction;

		f = dotproduct(s.velocity, trace_plane_normal);
		s.velocity -= f * trace_plane_normal;
	}
	if (pmove_waterjumptime > 0)
		s.velocity = primalvelocity;
}

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

// TODO: remove this and use above function
float CSQC_IsMoveInDirection(float forward, float side, float angle)
{
	// TODO: move to a common header
	#define RAD2DEG(a) ((a) * (180.0f / M_PI))
	#define ANGLEMOD(a) ((a) - 360.0 * floor((a) / 360.0))
	if(forward == 0 && side == 0)
		return 0; // avoid division by zero
	angle -= RAD2DEG(atan2(side, forward));
	angle = (ANGLEMOD(angle + 180) - 180) / 45;
	if(angle > 1)
		return 0;
	if(angle < -1)
		return 0;
	return 1 - fabs(angle);
	#undef RAD2DEG
	#undef ANGLEMOD
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

void CSQC_ClientMovement_Physics_CPM_PM_Aircontrol(entity s, vector wishdir, float wishspeed)
{
	float zspeed, xyspeed, dot, k;

#if 0
	// this doesn't play well with analog input
	if(s.movement_x == 0 || s.movement_y != 0)
		return; // can't control movement if not moving forward or backward
	k = 32;
#else
	k = 32 * (2 * IsMoveInDirection(input_movevalues, 0) - 1);
	if(k <= 0)
		return;
#endif

	k *= bound(0, wishspeed / getstatf(STAT_MOVEVARS_MAXAIRSPEED), 1);

	zspeed = s.velocity_z;
	s.velocity_z = 0;
	xyspeed = vlen(s.velocity); s.velocity = normalize(s.velocity);

	dot = s.velocity * wishdir;

	if(dot > 0) // we can't change direction while slowing down
	{
		k *= pow(dot, getstatf(STAT_MOVEVARS_AIRCONTROL_POWER))*input_timelength;
		xyspeed = max(0, xyspeed - getstatf(STAT_MOVEVARS_AIRCONTROL_PENALTY) * sqrt(max(0, 1 - dot*dot)) * k/32);
		k *= getstatf(STAT_MOVEVARS_AIRCONTROL);
		s.velocity = normalize(s.velocity * xyspeed + wishdir * k);
	}

	s.velocity = s.velocity * xyspeed;
	s.velocity_z = zspeed;
}

float CSQC_ClientMovement_Physics_AdjustAirAccelQW(float accelqw, float factor)
{
	return copysign(bound(0.000001, 1 - (1 - fabs(accelqw)) * factor, 1), accelqw);
}

void CSQC_ClientMovement_Physics_PM_Accelerate(entity s, vector wishdir, float wishspeed, float wishspeed0, float accel, float accelqw, float stretchfactor, float sidefric, float speedlimit)
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
		speedclamp = 1;
	else
		speedclamp = -1; // no clamping

	if(accelqw < 0)
		accelqw = -accelqw;

	if(moveflags & MOVEFLAG_Q2AIRACCELERATE)
		wishspeed0 = wishspeed; // don't need to emulate this Q1 bug

	vel_straight = dotproduct(s.velocity, wishdir);
	vel_z = s.velocity_z;
	vel_xy = s.velocity;
	vel_xy_z -= vel_z;
	vel_perpend = vel_xy - vel_straight * wishdir;

	step = accel * input_timelength * wishspeed0;

	vel_xy_current  = vlen(vel_xy);
	if(speedlimit > 0)
		accelqw = CSQC_ClientMovement_Physics_AdjustAirAccelQW(accelqw, (speedlimit - bound(wishspeed, vel_xy_current, speedlimit)) / max(1, speedlimit - wishspeed));
	vel_xy_forward  = vel_xy_current + bound(0, wishspeed - vel_xy_current, step) * accelqw + step * (1 - accelqw);
	vel_xy_backward = vel_xy_current - bound(0, wishspeed + vel_xy_current, step) * accelqw - step * (1 - accelqw);
	if(vel_xy_backward < 0)
		vel_xy_backward = 0; // not that it REALLY occurs that this would cause wrong behaviour afterwards

	vel_straight    = vel_straight   + bound(0, wishspeed - vel_straight,   step) * accelqw + step * (1 - accelqw);

	if(sidefric < 0 && vlen2(vel_perpend))
		// negative: only apply so much sideways friction to stay below the speed you could get by "braking"
	{
		float f, fmin;
		f = max(0, 1 + input_timelength * wishspeed * sidefric);
		fmin = (vel_xy_backward*vel_xy_backward - vel_straight*vel_straight) / vlen2(vel_perpend);
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
		vel_perpend *= max(0, 1 - input_timelength * wishspeed * sidefric);

	s.velocity = vel_perpend + vel_straight * wishdir;

	if(speedclamp >= 0)
	{
		float vel_xy_preclamp;
		vel_xy_preclamp = vlen(s.velocity);
		if(vel_xy_preclamp > 0) // prevent division by zero
		{
			vel_xy_current += (vel_xy_forward - vel_xy_current) * speedclamp;
			if(vel_xy_current < vel_xy_preclamp)
				s.velocity *= (vel_xy_current / vel_xy_preclamp);
		}
	}

	s.velocity_z += vel_z;
}

void CSQC_ClientMovement_Physics_PM_AirAccelerate(entity s, vector wishdir, float wishspeed)
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
		wishspeed = min(wishspeed, curspeed + getstatf(STAT_MOVEVARS_WARSOWBUNNY_AIRFORWARDACCEL) * getstatf(STAT_MOVEVARS_MAXSPEED) * input_timelength);
	}
	else
	{
		f = max(0, (getstatf(STAT_MOVEVARS_WARSOWBUNNY_TOPSPEED) - curspeed) / (getstatf(STAT_MOVEVARS_WARSOWBUNNY_TOPSPEED) - getstatf(STAT_MOVEVARS_MAXSPEED)));
		wishspeed = max(curspeed, getstatf(STAT_MOVEVARS_WARSOWBUNNY_ACCEL)) + getstatf(STAT_MOVEVARS_WARSOWBUNNY_ACCEL) * f * getstatf(STAT_MOVEVARS_WARSOWBUNNY_ACCEL) * input_timelength;
	}
	wishvel = wishdir * wishspeed;
	acceldir = wishvel - curvel;
	addspeed = vlen(acceldir);
	acceldir = normalize(acceldir);

	accelspeed = min(addspeed, getstatf(STAT_MOVEVARS_WARSOWBUNNY_TURNACCEL) * getstatf(STAT_MOVEVARS_WARSOWBUNNY_ACCEL) * input_timelength);

	if(getstatf(STAT_MOVEVARS_WARSOWBUNNY_BACKTOSIDERATIO) < 1)
	{
		curdir = normalize(curvel);
		dot = acceldir * curdir;
		if(dot < 0)
			acceldir = acceldir - (1 - getstatf(STAT_MOVEVARS_WARSOWBUNNY_BACKTOSIDERATIO)) * dot * curdir;
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
	float gravity;
	vector wishvel;
	vector wishdir;
	vector yawangles;

	// jump if on ground with jump button pressed but only if it has been
	// released at least once since the last jump
	if (input_buttons & 2)
	{
		if ((s.pmove_flags & PMF_ONGROUND) && ((s.pmove_flags & PMF_JUMP_HELD) == 0 || !cvar("cl_movement_track_canjump")))
		{
			s.velocity_z += getstatf(STAT_MOVEVARS_JUMPVELOCITY);
			s.pmove_flags &= ~PMF_ONGROUND;
			s.pmove_flags |= PMF_JUMP_HELD; // canjump = false
		}
	}
	else
		s.pmove_flags &= ~PMF_JUMP_HELD; // canjump = true

	// calculate movement vector
	yawangles = '0 0 0';
	yawangles_y = input_angles_y;
	makevectors(yawangles);
	wishvel = input_movevalues_x * v_forward + input_movevalues_y * v_right;

	// split wishvel into wishspeed and wishdir
	wishspeed = vlen(wishvel);
	if (wishspeed)
		wishdir = wishvel / wishspeed;
	else
		wishdir = '0 0 0';
	// check if onground
	if ((s.pmove_flags & PMF_ONGROUND))
	{
		wishspeed = min(wishspeed, getstatf(STAT_MOVEVARS_MAXSPEED));
		if (s.pmove_flags & PMF_DUCKED)
			wishspeed *= 0.5;

		// apply edge friction
		f = sqrt(s.velocity_x * s.velocity_x + s.velocity_y * s.velocity_y);
		if (f > 0)
		{
			friction = getstatf(STAT_MOVEVARS_FRICTION);
			if (getstatf(STAT_MOVEVARS_EDGEFRICTION) != 1)
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
					friction *= getstatf(STAT_MOVEVARS_EDGEFRICTION);
			}
			// apply ground friction
			f = 1 - input_timelength * friction * ((f < getstatf(STAT_MOVEVARS_STOPSPEED)) ? (getstatf(STAT_MOVEVARS_STOPSPEED) / f) : 1);
			f = max(f, 0);
			s.velocity *= f;
		}
		addspeed = wishspeed - dotproduct(s.velocity, wishdir);
		if (addspeed > 0)
		{
			accelspeed = min(getstatf(STAT_MOVEVARS_ACCELERATE) * input_timelength * wishspeed, addspeed);
			s.velocity += accelspeed * wishdir;
		}
		gravity = getstatf(STAT_MOVEVARS_GRAVITY) * getstatf(STAT_MOVEVARS_ENTGRAVITY) * input_timelength;
		if(!(moveflags & MOVEFLAG_NOGRAVITYONGROUND))
		{
			if(moveflags & MOVEFLAG_GRAVITYUNAFFECTEDBYTICRATE)
				s.velocity_z -= gravity * 0.5;
			else
				s.velocity_z -= gravity;
		}
		if (vlen2(s.velocity))
			CSQC_ClientMovement_Move(s);
		if(!(moveflags & MOVEFLAG_NOGRAVITYONGROUND) || !(s.pmove_flags & PMF_ONGROUND))
		{
			if(moveflags & MOVEFLAG_GRAVITYUNAFFECTEDBYTICRATE)
				s.velocity_z -= gravity * 0.5;
		}
	}
	else
	{
		if (pmove_waterjumptime <= 0)
		{
			// apply air speed limit
			float accel, wishspeed0, wishspeed2, accelqw, strafity;
			float accelerating;

			accelqw = getstatf(STAT_MOVEVARS_AIRACCEL_QW);
			wishspeed0 = wishspeed;
			wishspeed = min(wishspeed, getstatf(STAT_MOVEVARS_MAXAIRSPEED));
			if (s.pmove_flags & PMF_DUCKED)
				wishspeed *= 0.5;
			accel = getstatf(STAT_MOVEVARS_AIRACCELERATE);

			accelerating = (dotproduct(s.velocity, wishdir) > 0);
			wishspeed2 = wishspeed;

			// CPM: air control
			if(getstatf(STAT_MOVEVARS_AIRSTOPACCELERATE) != 0)
			{
				vector curdir;
				curdir_x = s.velocity_x;
				curdir_y = s.velocity_y;
				curdir_z = 0;
				curdir = normalize(curdir);
				accel = accel + (getstatf(STAT_MOVEVARS_AIRSTOPACCELERATE) - accel) * max(0, -dotproduct(curdir, wishdir));
			}
			strafity = CSQC_IsMoveInDirection(input_movevalues_x, input_movevalues_y, -90) + CSQC_IsMoveInDirection(input_movevalues_x, input_movevalues_y, +90); // if one is nonzero, other is always zero
			if(getstatf(STAT_MOVEVARS_MAXAIRSTRAFESPEED))
				wishspeed = min(wishspeed, GeomLerp(getstatf(STAT_MOVEVARS_MAXAIRSPEED), strafity, getstatf(STAT_MOVEVARS_MAXAIRSTRAFESPEED)));
			if(getstatf(STAT_MOVEVARS_AIRSTRAFEACCELERATE))
				accel = GeomLerp(getstatf(STAT_MOVEVARS_AIRACCELERATE), strafity, getstatf(STAT_MOVEVARS_AIRSTRAFEACCELERATE));
			if(getstatf(STAT_MOVEVARS_AIRSTRAFEACCEL_QW))
				accelqw =
					(((strafity > 0.5 ? getstatf(STAT_MOVEVARS_AIRSTRAFEACCEL_QW) : getstatf(STAT_MOVEVARS_AIRACCEL_QW)) >= 0) ? +1 : -1)
					*
					(1 - GeomLerp(1 - fabs(getstatf(STAT_MOVEVARS_AIRACCEL_QW)), strafity, 1 - fabs(getstatf(STAT_MOVEVARS_AIRSTRAFEACCEL_QW))));
			// !CPM

			if(getstatf(STAT_MOVEVARS_WARSOWBUNNY_TURNACCEL) && accelerating && input_movevalues_y == 0 && input_movevalues_x != 0)
				CSQC_ClientMovement_Physics_PM_AirAccelerate(s, wishdir, wishspeed2);
			else
				CSQC_ClientMovement_Physics_PM_Accelerate(s, wishdir, wishspeed, wishspeed0, accel, accelqw, getstatf(STAT_MOVEVARS_AIRACCEL_QW_STRETCHFACTOR), getstatf(STAT_MOVEVARS_AIRACCEL_SIDEWAYS_FRICTION) / getstatf(STAT_MOVEVARS_MAXAIRSPEED), getstatf(STAT_MOVEVARS_AIRSPEEDLIMIT_NONQW));

			if(getstatf(STAT_MOVEVARS_AIRCONTROL))
				CSQC_ClientMovement_Physics_CPM_PM_Aircontrol(s, wishdir, wishspeed2);
		}
		gravity = getstatf(STAT_MOVEVARS_GRAVITY) * getstatf(STAT_MOVEVARS_ENTGRAVITY) * input_timelength;
		if(moveflags & MOVEFLAG_GRAVITYUNAFFECTEDBYTICRATE)
			s.velocity_z -= gravity * 0.5;
		else
			s.velocity_z -= gravity;
		CSQC_ClientMovement_Move(s);
		if(!(moveflags & MOVEFLAG_NOGRAVITYONGROUND) || !(s.pmove_flags & PMF_ONGROUND))
		{
			if(moveflags & MOVEFLAG_GRAVITYUNAFFECTEDBYTICRATE)
				s.velocity_z -= gravity * 0.5;
		}
	}
}

// TODO: merge this with main physics frame
void CSQC_ClientMovement_Physics_Swim(entity s)
{
	// swimming
	self.flags &= ~FL_ONGROUND;

	makevectors(input_angles);
	//wishvel = v_forward * self.movement_x + v_right * self.movement_y + v_up * self.movement_z;
	vector wishvel = v_forward * input_movevalues_x + v_right * input_movevalues_y + '0 0 1' * input_movevalues_z;
	if (wishvel == '0 0 0')
		wishvel = '0 0 -60'; // drift towards bottom

	vector wishdir = normalize(wishvel);
	float wishspeed = vlen(wishvel);
	if (wishspeed > getstatf(STAT_MOVEVARS_MAXSPEED))
		wishspeed = getstatf(STAT_MOVEVARS_MAXSPEED);
	wishspeed = wishspeed * 0.7;

	// water friction
	self.velocity = self.velocity * (1 - input_timelength * getstatf(STAT_MOVEVARS_FRICTION));

	// water acceleration
	CSQC_ClientMovement_Physics_PM_Accelerate(s, wishdir, wishspeed, wishspeed, getstatf(STAT_MOVEVARS_ACCELERATE), 1, 0, 0, 0);
}

void CSQC_ClientMovement_PlayerMove(entity s)
{
	//Con_Printf(" %f", frametime);
	if (!(input_buttons & 2)) // !jump
		s.pmove_flags &= ~PMF_JUMP_HELD; // canjump = true
	pmove_waterjumptime -= input_timelength;
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
	if(input_timelength > 0.0005)
	{
		if (input_timelength > 0.05)
		{
			input_timelength /= 2;
			CSQC_ClientMovement_PlayerMove(s);
		}
		CSQC_ClientMovement_PlayerMove(s);
	}
	else
	{
		// we REALLY need this handling to happen, even if the move is not executed
		if (!(input_buttons & 2)) // !jump
			s.pmove_flags &= ~PMF_JUMP_HELD; // canjump = true
	}
}

void CSQCPlayer_Physics(void)
{
	switch(autocvar_cl_movement)
	{
		case 1: runstandardplayerphysics(self); break;
		case 2: CSQC_ClientMovement_PlayerMove_Frame(self); break;
	}
}
#undef vlen2

void CSQCPlayer_PredictTo(float endframe, float apply_error)
{
	CSQCPlayer_Unpredict();
	if(apply_error)
	{
		self.origin += CSQCPlayer_GetPredictionErrorO();
		self.velocity += CSQCPlayer_GetPredictionErrorV();
	}
	CSQCPlayer_SetMinsMaxs();

	csqcplayer_status = CSQCPLAYERSTATUS_PREDICTED;

#if 0
	// we don't need this
	// darkplaces makes servercommandframe == 0 in these cases anyway
	if (getstatf(STAT_HEALTH) <= 0)
	{
		csqcplayer_moveframe = clientcommandframe;
		getinputstate(csqcplayer_moveframe-1);
		print("the Weird code path got hit\n");
		return;
	}
#endif

	if(csqcplayer_moveframe >= endframe)
	{
		getinputstate(csqcplayer_moveframe - 1);
	}
	else
	{
		do
		{
			if (!getinputstate(csqcplayer_moveframe))
				break;
			CSQCPlayer_Physics();
			CSQCPlayer_SetMinsMaxs();
			csqcplayer_moveframe++;
		}
		while(csqcplayer_moveframe < endframe);
	}

	//add in anything that was applied after (for low packet rate protocols)
	input_angles = view_angles;
}

float CSQCPlayer_IsLocalPlayer()
{
	return (self == csqcplayer);
}

void(entity e, float fl) V_CalcRefdef = #640; // DP_CSQC_V_CALCREFDEF

void CSQCPlayer_SetCamera()
{
	vector v0;
	v0 = pmove_vel; // TRICK: pmove_vel is set by the engine when we get here. No need to network velocity

	if(csqcplayer)
	{
		entity oldself;
		oldself = self;
		self = csqcplayer;

#ifdef COMPAT_XON050_ENGINE
		if(servercommandframe == 0 || clientcommandframe == 0 || !(checkextension("DP_CSQC_V_CALCREFDEF") || checkextension("DP_CSQC_V_CALCREFDEF_WIP1")))
#else
		if(servercommandframe == 0 || clientcommandframe == 0)
#endif
		{
			InterpolateOrigin_Do();
			self.view_ofs = '0 0 1' * getstati(STAT_VIEWHEIGHT);

			// get crouch state from the server
			if(getstati(STAT_VIEWHEIGHT) == PL_VIEW_OFS_z)
				self.pmove_flags &= ~PMF_DUCKED;
			else if(getstati(STAT_VIEWHEIGHT) == PL_CROUCH_VIEW_OFS_z)
				self.pmove_flags |= PMF_DUCKED;

			// get onground state from the server
			if(pmove_onground)
				self.pmove_flags |= PMF_ONGROUND;
			else
				self.pmove_flags &= ~PMF_ONGROUND;

			CSQCPlayer_SetMinsMaxs();

			// override it back just in case
			self.view_ofs = '0 0 1' * getstati(STAT_VIEWHEIGHT);

			// set velocity
			self.velocity = v0;
		}
		else
		{
			float flg = self.iflags;
			self.iflags &= ~(IFLAG_ORIGIN | IFLAG_ANGLES);
			InterpolateOrigin_Do();
			self.iflags = flg;

			if(csqcplayer_status == CSQCPLAYERSTATUS_FROMSERVER)
			{
				vector o, v;
				o = self.origin;
				v = v0;
				csqcplayer_status = CSQCPLAYERSTATUS_PREDICTED;
				CSQCPlayer_PredictTo(servercommandframe + 1, FALSE);
				CSQCPlayer_SetPredictionError(self.origin - o, self.velocity - v, pmove_onground - !!(self.pmove_flags & PMF_ONGROUND));
				self.origin = o;
				self.velocity = v;

				// get crouch state from the server
				if(getstati(STAT_VIEWHEIGHT) == PL_VIEW_OFS_z)
					self.pmove_flags &= ~PMF_DUCKED;
				else if(getstati(STAT_VIEWHEIGHT) == PL_CROUCH_VIEW_OFS_z)
					self.pmove_flags |= PMF_DUCKED;

				// get onground state from the server
				if(pmove_onground)
					self.pmove_flags |= PMF_ONGROUND;
				else
					self.pmove_flags &= ~PMF_ONGROUND;

				CSQCPlayer_SavePrediction();
			}
			CSQCPlayer_PredictTo(clientcommandframe + 1, TRUE);

#ifdef CSQCMODEL_SERVERSIDE_CROUCH
			// get crouch state from the server (LAG)
			if(getstati(STAT_VIEWHEIGHT) == PL_VIEW_OFS_z)
				self.pmove_flags &= ~PMF_DUCKED;
			else if(getstati(STAT_VIEWHEIGHT) == PL_CROUCH_VIEW_OFS_z)
				self.pmove_flags |= PMF_DUCKED;
#endif

			CSQCPlayer_SetMinsMaxs();

			self.angles_y = input_angles_y;
		}

		// relink
		setorigin(self, self.origin);

		self = oldself;
	}

	entity view;
#ifdef COMPAT_XON050_ENGINE
	view = CSQCModel_server2csqc((spectatee_status > 0) ? spectatee_status : player_localentnum);
#else
	view = CSQCModel_server2csqc(player_localentnum);
#endif

	if(view && view != csqcplayer)
	{
		entity oldself = self;
		self = view;
		InterpolateOrigin_Do();
		self.view_ofs = '0 0 1' * getstati(STAT_VIEWHEIGHT);
		self = oldself;
	}

#ifdef COMPAT_XON050_ENGINE
	if(view && !(checkextension("DP_CSQC_V_CALCREFDEF") || checkextension("DP_CSQC_V_CALCREFDEF_WIP1")))
	{
		// legacy code, not totally correct, but good enough for not having V_CalcRefdef
		setproperty(VF_ORIGIN, view.origin + '0 0 1' * getstati(STAT_VIEWHEIGHT));
		setproperty(VF_ANGLES, view_angles);
	}
	else
#endif
	if(view)
	{
		var float refdefflags = 0;

		if(view.csqcmodel_teleported)
			refdefflags |= REFDEFFLAG_TELEPORTED;

		if(input_buttons & 4)
			refdefflags |= REFDEFFLAG_JUMPING;

		// note: these two only work in WIP2, but are harmless in WIP1
		if(getstati(STAT_HEALTH) <= 0)
			refdefflags |= REFDEFFLAG_DEAD;

		if(intermission)
			refdefflags |= REFDEFFLAG_INTERMISSION;

		V_CalcRefdef(view, refdefflags);
	}
	else
	{
		// FIXME by CSQC spec we have to do this:
		// but it breaks chase cam
		/*
		setproperty(VF_ORIGIN, pmove_org + '0 0 1' * getstati(STAT_VIEWHEIGHT));
		setproperty(VF_ANGLES, view_angles);
		*/
	}

	{ CSQCPLAYER_HOOK_POSTCAMERASETUP }
}

void CSQCPlayer_Remove()
{
	csqcplayer = world;
	cvar_settemp("cl_movement_replay", "1");
}

float CSQCPlayer_PreUpdate()
{
	if(self != csqcplayer)
		return 0;
	if(csqcplayer_status != CSQCPLAYERSTATUS_FROMSERVER)
		CSQCPlayer_Unpredict();
	return 1;
}

float CSQCPlayer_PostUpdate()
{
	if(self.entnum != player_localnum + 1)
		return 0;
	csqcplayer = self;
	csqcplayer_status = CSQCPLAYERSTATUS_FROMSERVER;
	cvar_settemp("cl_movement_replay", "0");
	self.entremove = CSQCPlayer_Remove;
	return 1;
}
