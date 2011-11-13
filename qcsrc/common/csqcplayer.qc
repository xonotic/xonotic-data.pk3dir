float autocvar_cl_predictionerrorcompensation = 0;
float autocvar_cl_movement_replay;
float autocvar_chase_active;
float autocvar_chase_back;

.float pmove_flags;

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

		csqcplayer_moveframe++;
	}

	//add in anything that was applied after (for low packet rate protocols)
	input_angles = view_angles;
}

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
				CSQCPlayer_SavePrediction();
			}
			CSQCPlayer_PredictTo(clientcommandframe);
		}

		self = oldself;

		org = csqcplayer.origin + csqcplayer.view_ofs + CSQCPlayer_GetPredictionError();
		ang = R_SetView3fv(VF_ANGLES);

		// simulate missing engine features
		if(autocvar_chase_active)
		{
			float dist;
			vector chase_dest;
			dist = -autocvar_chase_back - 8;
			makevectors(ang);
			chase_dest = org + v_forward * dist;
			traceline(org, chase_dest, MOVE_NOMONSTERS, csqcplayer);
			org = trace_endpos + 8 * v_forward + 4 * trace_plane_normal;
		}

		R_SetView3fv(VF_ORIGIN, org);
		R_SetView3fv(VF_ANGLES, ang);
	}
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
	if(self.entnum <= maxclients)
		self.renderflags |= RF_EXTERNALMODEL;
	else
		self.renderflags &~= RF_EXTERNALMODEL;
	if(self.entnum != player_localentnum)
		return 0;
	csqcplayer_status = CSQCPLAYERSTATUS_FROMSERVER;
	csqcplayer = self;
	return 1;
}
