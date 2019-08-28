/*
 * Copyright (c) 2011 Rudolf Polzer
 * Copyright (c) 2015 Micah Talkiewicz
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
#include "cl_player.qh"

#include "cl_model.qh"
#include "common.qh"
#include "interpolate.qh"

float autocvar_cl_movement_errorcompensation = 0;
bool autocvar_cl_movement_intermissionrunning = false;

// engine stuff
float pmove_onground; // weird engine flag we shouldn't really use but have to for now

vector csqcplayer_origin, csqcplayer_velocity;
float csqcplayer_sequence;
int player_pmflags;
float csqcplayer_moveframe;
vector csqcplayer_predictionerroro;
vector csqcplayer_predictionerrorv;
float csqcplayer_predictionerrortime;
float csqcplayer_predictionerrorfactor;

vector CSQCPlayer_GetPredictionErrorO()
{
	if (time >= csqcplayer_predictionerrortime) return '0 0 0';
	return csqcplayer_predictionerroro * (csqcplayer_predictionerrortime - time) * csqcplayer_predictionerrorfactor;
}

vector CSQCPlayer_GetPredictionErrorV()
{
	if (time >= csqcplayer_predictionerrortime) return '0 0 0';
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
	if(vdist(o, >, 32) || vdist(v, >, 192))
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

void CSQCPlayer_Unpredict(entity this)
{
	if (csqcplayer_status == CSQCPLAYERSTATUS_UNPREDICTED) return;
	if (csqcplayer_status != CSQCPLAYERSTATUS_PREDICTED) LOG_FATALF("Cannot unpredict in current status (%d)", csqcplayer_status);
	this.origin = csqcplayer_origin;
	this.velocity = csqcplayer_velocity;
	csqcplayer_moveframe = csqcplayer_sequence + 1; // + 1 because the recieved frame has the move already done (server side)
	this.flags = player_pmflags;
}

void CSQCPlayer_SetMinsMaxs(entity this)
{
	if (IS_DUCKED(this) || !(this.isplayermodel & ISPLAYER_PLAYER))
	{
		this.mins = PHYS_PL_CROUCH_MIN(this);
		this.maxs = PHYS_PL_CROUCH_MAX(this);
		this.view_ofs = PHYS_PL_CROUCH_VIEWOFS(this);
	}
	else
	{
		this.mins = PHYS_PL_MIN(this);
		this.maxs = PHYS_PL_MAX(this);
		this.view_ofs = PHYS_PL_VIEWOFS(this);
	}
}

void CSQCPlayer_SavePrediction(entity this)
{
	player_pmflags = this.flags;
	csqcplayer_origin = this.origin;
	csqcplayer_velocity = this.velocity;
	csqcplayer_sequence = servercommandframe;
	csqcplayer_status = CSQCPLAYERSTATUS_PREDICTED;
}

void CSQC_ClientMovement_PlayerMove_Frame(entity this);

void CSQCPlayer_Physics(entity this)
{
	if(!autocvar_cl_movement) { return; }

	_Movetype_CheckWater(this); // we apparently need to check water *before* physics so it can use this for water jump

	vector oldv_angle = this.v_angle;
	vector oldangles = this.angles; // we need to save these, as they're abused by other code
	this.v_angle = PHYS_INPUT_ANGLES(this);
	this.angles = PHYS_WORLD_ANGLES(this);

	CSQC_ClientMovement_PlayerMove_Frame(this);

	Movetype_Physics_NoMatchTicrate(this, PHYS_INPUT_TIMELENGTH, true);

	view_angles = this.v_angle;
	input_angles = this.angles;
	this.v_angle = oldv_angle;
	this.angles = oldangles;

	this.pmove_flags =
			((IS_DUCKED(this)) ? PMF_DUCKED : 0) |
			((IS_JUMP_HELD(this)) ? PMF_JUMP_HELD : 0) |
			((IS_ONGROUND(this)) ? PMF_ONGROUND : 0);
}

void CSQCPlayer_PredictTo(entity this, float endframe, bool apply_error)
{
	CSQCPlayer_Unpredict(this);
	if (apply_error)
	{
		this.origin += CSQCPlayer_GetPredictionErrorO();
		this.velocity += CSQCPlayer_GetPredictionErrorV();
	}
	CSQCPlayer_SetMinsMaxs(this);

	csqcplayer_status = CSQCPLAYERSTATUS_PREDICTED;

#if 0
	// we don't need this
	// darkplaces makes servercommandframe == 0 in these cases anyway
	if (STAT(HEALTH) <= 0)
	{
		csqcplayer_moveframe = clientcommandframe;
		getinputstate(csqcplayer_moveframe-1);
		LOG_INFO("the Weird code path got hit");
		return;
	}
#endif

	if (csqcplayer_moveframe >= endframe)
	{
		getinputstate(csqcplayer_moveframe - 1);
	}
	else
	{
		do
		{
			if (!getinputstate(csqcplayer_moveframe)) break;
			/*if (input_timelength > 0.0005)
			{
				if (input_timelength > 0.05)
				{
					input_timelength /= 2;
					CSQCPlayer_Physics(this);
				}
				CSQCPlayer_Physics(this);
			}*/
			CSQCPlayer_Physics(this);
			CSQCPlayer_SetMinsMaxs(this);
			++csqcplayer_moveframe;
		}
		while (csqcplayer_moveframe < endframe);
	}

	// add in anything that was applied after (for low packet rate protocols)
	input_angles = view_angles;
}

bool CSQCPlayer_IsLocalPlayer(entity this)
{
	return (this == csqcplayer);
}

float stairsmoothz;
float autocvar_cl_stairsmoothspeed;
float autocvar_cl_smoothviewheight;
float smooth_prevtime;
float viewheightavg;
float autocvar_cl_bobfall;
float autocvar_cl_bobfallcycle;
float autocvar_cl_bobfallminspeed;
float bobfall_swing;
float bobfall_speed;
vector CSQCPlayer_ApplySmoothing(entity this, vector v)
{
	if(this.csqcmodel_teleported || !IS_ONGROUND(this) || autocvar_cl_stairsmoothspeed <= 0)
		stairsmoothz = v.z;
	else
	{
		if(v.z > stairsmoothz)
			v.z = stairsmoothz = bound(v.z - PHYS_STEPHEIGHT(this), stairsmoothz + frametime * autocvar_cl_stairsmoothspeed, v.z);
		else if(v.z < stairsmoothz)
			v.z = stairsmoothz = bound(v.z, stairsmoothz - frametime * autocvar_cl_stairsmoothspeed, v.z + PHYS_STEPHEIGHT(this));
	}

	float viewheight = bound(0, (time - smooth_prevtime) / max(0.0001, autocvar_cl_smoothviewheight), 1);
	viewheightavg = viewheightavg * (1 - viewheight) + this.view_ofs.z * viewheight;
	v.z += viewheightavg;

	if(autocvar_cl_bobfall && autocvar_cl_bobfallcycle)
	{
		if(!IS_ONGROUND(this))
		{
			bobfall_speed = bound(-400, this.velocity.z, 0) * bound(0, autocvar_cl_bobfall, 0.1);
			if(this.velocity.z < -autocvar_cl_bobfallminspeed)
				bobfall_swing = 1;
			else
				bobfall_swing = 0; // really?
		}
		else
		{
			bobfall_swing = max(0, bobfall_swing - autocvar_cl_bobfallcycle * frametime);
			float bobfall = sin(M_PI * bobfall_swing) * bobfall_speed;
			v.z += bobfall;
		}
	}

	smooth_prevtime = time;

	return v;
}

bool autocvar_v_deathtilt;
float autocvar_v_deathtiltangle;
void CSQCPlayer_ApplyDeathTilt(entity this)
{
	if(!autocvar_v_deathtilt)
		return;
	view_angles.y = autocvar_v_deathtiltangle;
}

float autocvar_v_idlescale;
float autocvar_v_ipitch_cycle;
float autocvar_v_iyaw_cycle;
float autocvar_v_iroll_cycle;
float autocvar_v_ipitch_level;
float autocvar_v_iyaw_level;
float autocvar_v_iroll_level;
void CSQCPlayer_ApplyIdleScaling(entity this)
{
	if(!autocvar_v_idlescale)
		return;
	view_angles.x += autocvar_v_idlescale * sin(time * autocvar_v_ipitch_cycle) * autocvar_v_ipitch_level;
	view_angles.y += autocvar_v_idlescale * sin(time * autocvar_v_iyaw_cycle) * autocvar_v_iyaw_level;
	view_angles.z += autocvar_v_idlescale * sin(time * autocvar_v_iroll_cycle) * autocvar_v_iroll_level;
	//setproperty(VF_CL_VIEWANGLES, view_angles); // update view angles as well so we can aim
}

float autocvar_chase_back;
float autocvar_chase_up;
bool autocvar_chase_overhead;
float autocvar_chase_pitchangle;
vector CSQCPlayer_ApplyChase(entity this, vector v)
{
	// don't need to do offset for view height here, it's done in smoothing!
	//v += this.view_ofs;
	vector forward;
	vector chase_dest;

	if(autocvar_chase_overhead)
	{
		view_angles.x = 0;
		makevectors(view_angles);
		forward = v_forward;
		vector up = v_up;
		// trace a little further so it hits a surface more consistently (to avoid 'snapping' on the edge of the range)
		chase_dest.x = v.x - forward.x * autocvar_chase_back + up.x * autocvar_chase_up;
		chase_dest.y = v.y - forward.y * autocvar_chase_back + up.y * autocvar_chase_up;
		chase_dest.z = v.z - forward.z * autocvar_chase_back + up.z * autocvar_chase_up;

		// trace from first person view location to our chosen third person view location
		traceline(v, chase_dest, MOVE_NOMONSTERS, NULL);

		vector bestvieworg = trace_endpos;
		vector offset = '0 0 0';
		for(offset.x = -16; offset.x <= 16; offset.x += 8)
		{
			for(offset.y = -16; offset.y <= 16; offset.y += 8)
			{
				makevectors(view_angles);
				up = v_up;
				chase_dest.x = v.x - forward.x * autocvar_chase_back + up.x * autocvar_chase_up + offset.x;
				chase_dest.y = v.y - forward.y * autocvar_chase_back + up.y * autocvar_chase_up + offset.y;
				chase_dest.z = v.z - forward.z * autocvar_chase_back + up.z * autocvar_chase_up + offset.z;
				traceline(v, chase_dest, MOVE_NOMONSTERS, NULL);
				if(bestvieworg.z > trace_endpos.z)
					bestvieworg.z = trace_endpos.z;
			}
		}
		bestvieworg.z -= 8;
		v = bestvieworg;

		view_angles.x = autocvar_chase_pitchangle;
		//setproperty(VF_CL_VIEWANGLES, view_angles); // update view angles as well so we can aim
	}
	else
	{
		makevectors(view_angles);
		forward = v_forward;
		// trace a little further so it hits a surface more consistently (to avoid 'snapping' on the edge of the range)
		float cdist = -autocvar_chase_back - 8;
		chase_dest.x = v.x + forward.x * cdist;
		chase_dest.y = v.y + forward.y * cdist;
		chase_dest.z = v.z + forward.z * cdist + autocvar_chase_up;
		traceline(v, chase_dest, MOVE_NOMONSTERS, NULL);
		v.x = 1 * trace_endpos.x + 8 * forward.x + 4 * trace_plane_normal.x;
		v.y = 1 * trace_endpos.y + 8 * forward.y + 4 * trace_plane_normal.y;
		v.z = 1 * trace_endpos.z + 8 * forward.z + 4 * trace_plane_normal.z;
	}

#if 0
	tracebox(v, '-4 -4 -4', '4 4 4', v - v_forward * autocvar_chase_back, MOVE_NORMAL, this);
	v = trace_endpos;
	tracebox(v, '-4 -4 -4', '4 4 4', v + v_up * autocvar_chase_up, MOVE_NORMAL, this);
	v = trace_endpos;
#endif
	return v;
}

bool autocvar_cl_useenginerefdef;

/** Called once per CSQC_UpdateView() */
void CSQCPlayer_SetCamera()
{
	vector v0 = ((intermission && !autocvar_cl_movement_intermissionrunning) ? '0 0 0' : pmove_vel); // TRICK: pmove_vel is set by the engine when we get here. No need to network velocity
	float vh = PHYS_VIEWHEIGHT(NULL);
	vector pl_viewofs = PHYS_PL_VIEWOFS(NULL);
	vector pl_viewofs_crouch = PHYS_PL_CROUCH_VIEWOFS(NULL);
	entity e = csqcplayer;
	if (e)
	{
		if (servercommandframe == 0 || clientcommandframe == 0)
		{
			InterpolateOrigin_Do(e);
			e.view_ofs = '0 0 1' * vh;

			// get crouch state from the server
			if (vh == pl_viewofs.z) e.flags &= ~FL_DUCKED;
			else if (vh == pl_viewofs_crouch.z) e.flags |= FL_DUCKED;

			// get onground state from the server
			e.flags = BITSET(e.flags, FL_ONGROUND, pmove_onground);

			CSQCPlayer_SetMinsMaxs(e);

			// override it back just in case
			e.view_ofs = '0 0 1' * vh;

			// set velocity
			e.velocity = v0;
		}
		else
		{
			int flg = e.iflags; e.iflags &= ~(IFLAG_ORIGIN | IFLAG_ANGLES);
			InterpolateOrigin_Do(e);
			e.iflags = flg;

			if (csqcplayer_status == CSQCPLAYERSTATUS_FROMSERVER)
			{
				vector o = e.origin;
				csqcplayer_status = CSQCPLAYERSTATUS_PREDICTED;
				CSQCPlayer_PredictTo(e, servercommandframe + 1, false);
				CSQCPlayer_SetPredictionError(e.origin - o, e.velocity - v0, pmove_onground - IS_ONGROUND(e));
				e.origin = o;
				e.velocity = v0;

				// get crouch state from the server
				if (vh == pl_viewofs.z) e.flags &= ~FL_DUCKED;
				else if(vh == pl_viewofs_crouch.z) e.flags |= FL_DUCKED;

				// get onground state from the server
				e.flags = BITSET(e.flags, FL_ONGROUND, pmove_onground);

				CSQCPlayer_SavePrediction(e);
			}
			CSQCPlayer_PredictTo(e, clientcommandframe + 1, true);

#ifdef CSQCMODEL_SERVERSIDE_CROUCH
			// get crouch state from the server (LAG)
			if (vh == pl_viewofs.z) e.flags &= ~FL_DUCKED;
			else if (vh == pl_viewofs_crouch.z) e.flags |= FL_DUCKED;
#endif
			CSQCPlayer_SetMinsMaxs(e);

			e.angles_y = input_angles.y;
		}

		// relink
		setorigin(e, e.origin);
	}

	const entity view = CSQCModel_server2csqc(player_localentnum - 1);
	if (view)
	{
		if (view != csqcplayer)
		{
			InterpolateOrigin_Do(view);
			view.view_ofs = '0 0 1' * vh;
		}
		if(autocvar_cl_useenginerefdef)
		{
			int refdefflags = 0;
			if (view.csqcmodel_teleported) refdefflags |= REFDEFFLAG_TELEPORTED;
			if (input_buttons & BIT(1)) refdefflags |= REFDEFFLAG_JUMPING;
			// note: these two only work in WIP2, but are harmless in WIP1
			if (PHYS_HEALTH(NULL) <= 0 && PHYS_HEALTH(NULL) != -666 && PHYS_HEALTH(NULL) != -2342) refdefflags |= REFDEFFLAG_DEAD;
			if (intermission) refdefflags |= REFDEFFLAG_INTERMISSION;
			V_CalcRefdef(view, refdefflags); // TODO? uses .health stat in the engine when this isn't called here, may be broken!
		}
		else
		{
			vector vieworg = view.origin;
			vieworg = CSQCPlayer_ApplySmoothing(view, vieworg);
			if(autocvar_chase_active)
				vieworg = CSQCPlayer_ApplyChase(view, vieworg);
			else if(IS_DEAD(view))
				CSQCPlayer_ApplyDeathTilt(view);
			CSQCPlayer_ApplyIdleScaling(view);
			setproperty(VF_ORIGIN, vieworg);
			setproperty(VF_ANGLES, view_angles);
		}
			
	}
	else
	{
		// FIXME by CSQC spec we have to do this:
		// but it breaks chase cam
		/*
		setproperty(VF_ORIGIN, pmove_org + '0 0 1' * vh);
		setproperty(VF_ANGLES, view_angles);
		*/
	}
	CSQCPLAYER_HOOK_POSTCAMERASETUP();
}

void CSQCPlayer_Remove(entity this)
{
	csqcplayer = NULL;
	cvar_settemp("cl_movement_replay", "1");
}

bool CSQCPlayer_PreUpdate(entity this)
{
	if (this != csqcplayer) return false;
	if (csqcplayer_status != CSQCPLAYERSTATUS_FROMSERVER) CSQCPlayer_Unpredict(this);
	return true;
}

bool CSQCPlayer_PostUpdate(entity this)
{
	if (this.entnum != player_localnum + 1) return false;
	csqcplayer = this;
	csqcplayer_status = CSQCPLAYERSTATUS_FROMSERVER;
	cvar_settemp("cl_movement_replay", "0");
	this.entremove = CSQCPlayer_Remove;
	return true;
}
