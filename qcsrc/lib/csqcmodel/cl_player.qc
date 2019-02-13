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
