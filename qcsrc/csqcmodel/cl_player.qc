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

var float autocvar_cl_predictionerrorcompensation = 0;
var float autocvar_chase_active;
var float autocvar_chase_back;

.float pmove_flags;
float pmove_onground; // weird engine flag we shouldn't really use but have to for now

#define PMF_DUCKED 4
#define PMF_TELEPORTED 16
#define PMF_ONGROUND 32

entity csqcplayer;
vector csqcplayer_origin, csqcplayer_velocity;
float csqcplayer_sequence, player_pmflags;
float csqcplayer_moveframe;
vector csqcplayer_predictionerror;
float csqcplayer_predictionerrortime;

vector CSQCPlayer_GetPredictionError()
{
	if(!autocvar_cl_predictionerrorcompensation)
		return '0 0 0';
	if(time < csqcplayer_predictionerrortime)
		return csqcplayer_predictionerror * (csqcplayer_predictionerrortime - time) * autocvar_cl_predictionerrorcompensation;
	return '0 0 0';
}

void CSQCPlayer_SetPredictionError(vector v)
{
	if(!autocvar_cl_predictionerrorcompensation)
		return;
	csqcplayer_predictionerror = (csqcplayer_predictionerrortime - time) * autocvar_cl_predictionerrorcompensation * csqcplayer_predictionerror + v;
	csqcplayer_predictionerrortime = time + 1.0 / autocvar_cl_predictionerrorcompensation;
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

void CSQCPlayer_PredictTo(float endframe)
{
	CSQCPlayer_Unpredict();
	CSQCPlayer_SetMinsMaxs();

	csqcplayer_status = CSQCPLAYERSTATUS_PREDICTED;

	if (getstatf(STAT_HEALTH) <= 0)
	{
		csqcplayer_moveframe = clientcommandframe;
		getinputstate(csqcplayer_moveframe-1);
		return;
	}

	while(csqcplayer_moveframe < endframe)
	{
		if (!getinputstate(csqcplayer_moveframe))
		{
			break;
		}
		runstandardplayerphysics(self);
		CSQCPlayer_SetMinsMaxs();
		csqcplayer_moveframe++;
	}

	//add in anything that was applied after (for low packet rate protocols)
	input_angles = view_angles;
}

float CSQCPlayer_IsLocalPlayer()
{
	return (self == csqcplayer);
}

void(entity e) V_CalcRefdef = #640; // DP_CSQC_V_CALCREFDEF

void CSQCPlayer_SetCamera()
{
	if(csqcplayer)
	{
		vector org, ang;
		entity oldself;
		oldself = self;
		self = csqcplayer;

		if(servercommandframe == 0)
		{
			InterpolateOrigin_Do();
			self.view_ofs = '0 0 1' * getstati(STAT_VIEWHEIGHT);

			// get crouch state from the server
			if(getstati(STAT_VIEWHEIGHT) == PL_VIEW_OFS_z)
				self.pmove_flags &~= PMF_DUCKED;
			else if(getstati(STAT_VIEWHEIGHT) == PL_CROUCH_VIEW_OFS_z)
				self.pmove_flags |= PMF_DUCKED;

			// get onground state from the server
			if(pmove_onground)
				self.pmove_flags |= PMF_ONGROUND;
			else
				self.pmove_flags &~= PMF_ONGROUND;

			CSQCPlayer_SetMinsMaxs();

			self.view_ofs_z = getstati(STAT_VIEWHEIGHT);
			print(vtos(self.view_ofs), "\n");
		}
		else
		{
			if(csqcplayer_status == CSQCPLAYERSTATUS_FROMSERVER)
			{
				vector o, v;
				o = self.origin;
				v = pmove_vel; // TRICK: pmove_vel is set by the engine when we get here. No need to network velocity
				csqcplayer_status = CSQCPLAYERSTATUS_PREDICTED;
				CSQCPlayer_PredictTo(servercommandframe + 1);
				CSQCPlayer_SetPredictionError(o - self.origin);
				self.origin = o;
				self.velocity = v;

				// get crouch state from the server
				if(getstati(STAT_VIEWHEIGHT) == PL_VIEW_OFS_z)
					self.pmove_flags &~= PMF_DUCKED;
				else if(getstati(STAT_VIEWHEIGHT) == PL_CROUCH_VIEW_OFS_z)
					self.pmove_flags |= PMF_DUCKED;

				// get onground state from the server
				if(pmove_onground)
					self.pmove_flags |= PMF_ONGROUND;
				else
					self.pmove_flags &~= PMF_ONGROUND;

				CSQCPlayer_SavePrediction();
			}
			CSQCPlayer_PredictTo(clientcommandframe);

			CSQCPlayer_SetMinsMaxs();
		}

		// relink
		setorigin(self, self.origin);

		if(checkextension("DP_CSQC_V_CALCREFDEF"))
		{
			// set teleport bit
			if(self.csqcmodel_teleported)
			{
				self.pmove_flags |= PMF_TELEPORTED;
				self.csqcmodel_teleported = 0;
			}
			else
				self.pmove_flags &~= PMF_TELEPORTED;

			V_CalcRefdef(self);
		}
		else
			R_SetView3fv(VF_ORIGIN, self.origin + self.view_ofs);

		{ CSQCPLAYER_HOOK_POSTCAMERASETUP }

		self = oldself;
	}
}

void CSQCPlayer_Remove()
{
	if(self.entnum != player_localentnum)
		return;
	csqcplayer = world;
	cvar_clientsettemp("cl_movement_replay", "1");
}

float CSQCPlayer_PreUpdate()
{
	if(self.entnum != player_localentnum)
		return 0;
	cvar_clientsettemp("cl_movement_replay", "0");
	if(csqcplayer_status != CSQCPLAYERSTATUS_FROMSERVER)
		CSQCPlayer_Unpredict();
	return 1;
}

float CSQCPlayer_PostUpdate()
{
	/*
	if(self.entnum == player_localentnum)
		self.renderflags |= RF_EXTERNALMODEL;
	else
		self.renderflags &~= RF_EXTERNALMODEL;
	*/

	if(self.entnum != player_localentnum)
		return 0;
	csqcplayer_status = CSQCPLAYERSTATUS_FROMSERVER;
	csqcplayer = self;
	self.entremove = CSQCPlayer_Remove;
	return 1;
}

entity CSQCPlayer_GetPlayer(float pl)
{
	return findfloat(world, entnum, pl); // FIXME optimize this using an array
}
