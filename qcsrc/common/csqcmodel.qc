// generic CSQC model code

.vector glowmod;
.vector view_ofs;

#define ALLPROPERTIES \
	PROPERTY(1, ReadCoord, WriteCoord, origin_x) \
	PROPERTY(1, ReadCoord, WriteCoord, origin_y) \
	PROPERTY(1, ReadCoord, WriteCoord, origin_z) \
	PROPERTY(1, ReadCoord, WriteCoord, velocity_x) \
	PROPERTY(1, ReadCoord, WriteCoord, velocity_y) \
	PROPERTY(1, ReadCoord, WriteCoord, velocity_z) \
	PROPERTY(2, ReadAngle, WriteAngle, angles_x) \
	PROPERTY(2, ReadAngle, WriteAngle, angles_y) \
	PROPERTY(2, ReadAngle, WriteAngle, angles_z) \
	PROPERTY(4, ReadShort, WriteShort, modelindex) \
	PROPERTY(8, ReadByte, WriteByte, frame) \
	PROPERTY(16, ReadByte, WriteByte, skin) \
	PROPERTY(32, ReadInt24_t, WriteInt24_t, effects) \
	PROPERTY_SCALED(64, ReadByte, WriteByte, alpha, 255, 0, 255) \
	PROPERTY_SCALED(128, ReadByte, WriteByte, glowmod_x, 32, 0, 255) \
	PROPERTY_SCALED(128, ReadByte, WriteByte, glowmod_y, 32, 0, 255) \
	PROPERTY_SCALED(128, ReadByte, WriteByte, glowmod_z, 32, 0, 255) \
	PROPERTY(256, ReadChar, WriteChar, view_ofs_z) \
	PROPERTY(512, ReadShort, WriteShort, colormap)

#ifdef SVQC

#define PROPERTY(flag,r,w,f) \
	.float csqcmodel_##f;
#define PROPERTY_SCALED(flag,r,w,f,s,mi,ma) PROPERTY(flag,r,w,f)
	ALLPROPERTIES
#undef PROPERTY_SCALED
#undef PROPERTY

float CSQCModel_Send(entity to, float sf)
{
	WriteByte(MSG_ENTITY, ENT_CLIENT_MODEL);
	WriteShort(MSG_ENTITY, sf);

#define PROPERTY(flag,r,w,f) \
	if(sf & flag) \
	{ \
		w(MSG_ENTITY, self.csqcmodel_##f); \
	}
#define PROPERTY_SCALED(flag,r,w,f,s,mi,ma) PROPERTY(flag,r,w,f)
	ALLPROPERTIES
#undef PROPERTY_SCALED
#undef PROPERTY

	return TRUE;
}

void CSQCModel_CheckUpdate()
{
	float tmp;
#define PROPERTY(flag,r,w,f) \
	tmp = self.f; \
	if(tmp != self.csqcmodel_##f) \
	{ \
		self.csqcmodel_##f = tmp; \
		self.SendFlags |= flag; \
	}
#define PROPERTY_SCALED(flag,r,w,f,s,mi,ma) \
	tmp = bound(mi, s * self.f, ma); \
	if(tmp != self.csqcmodel_##f) \
	{ \
		self.csqcmodel_##f = tmp; \
		self.SendFlags |= flag; \
	}
	ALLPROPERTIES
#undef PROPERTY_SCALED
#undef PROPERTY
}

void CSQCModel_LinkEntity()
{
	Net_LinkEntity(self, TRUE, 0, CSQCModel_Send);
}

#endif

#ifdef CSQC

void CSQCModel_Draw()
{
	if(self.entnum != player_localentnum)
		InterpolateOrigin_Do();
}

vector player_org, player_vel;
float player_sequence, player_pmflags;
float pmoveframe;
.float status; // 1 = have new origin, need to run prediction to servercommandframe; 2 = current values are predicted
.float pmove_flags;
vector prediction_error;
float prediction_errortime;
float autocvar_cl_predictionerrorcompensation = 0;

vector GetPredictionError()
{
	if(!autocvar_cl_predictionerrorcompensation)
		return '0 0 0';
	if(time < prediction_errortime)
		return prediction_error * (prediction_errortime - time) * autocvar_cl_predictionerrorcompensation;
	return '0 0 0';
}

void SetPredictionError(vector v)
{
	if(!autocvar_cl_predictionerrorcompensation)
		return;
	prediction_error = (prediction_errortime - time) * autocvar_cl_predictionerrorcompensation * prediction_error + v;
	prediction_errortime = time + 1.0 / autocvar_cl_predictionerrorcompensation;
}

void Unpredict()
{
	if(self.status == 0)
		return;
	if(self.status != 2)
		error("Cannot unpredict in current status");
	self.origin = player_org;
	self.velocity = player_vel;
	pmoveframe = player_sequence+1; //+1 because the recieved frame has the move already done (server side)
	self.pmove_flags = player_pmflags;
	/*
	if (pmoveframe < clientcommandframe-128)
		pmoveframe = clientcommandframe-128; // don't want to loop infinitely
	*/
}

void SavePrediction()
{
	player_pmflags = self.pmove_flags;
	player_org = self.origin;
	player_vel = self.velocity;
	player_sequence = servercommandframe;
	self.status = 0;
}

void PredictTo(float endframe)
{
	Unpredict();

	self.status = 2;

	if (getstatf(STAT_HEALTH) <= 0)
	{
		pmoveframe = clientcommandframe;
		getinputstate(pmoveframe-1);
		return;
	}

	while(pmoveframe < endframe)
	{
		if (!getinputstate(pmoveframe))
		{
			break;
		}
		runstandardplayerphysics(self);

		pmoveframe++;
	}

	//add in anything that was applied after (for low packet rate protocols)
	input_angles = view_angles;
}

entity csqcmodel_me;
float autocvar_chase_active;
float autocvar_chase_back;
void CSQCModel_SetCamera()
{
	if(csqcmodel_me)
	{
		vector org, ang;
		entity oldself;
		oldself = self;
		self = csqcmodel_me;
		if(self.status == 1)
		{
			vector o, v;
			o = self.origin;
			v = self.velocity;
			self.status = 2;
			PredictTo(servercommandframe + 1);
			SetPredictionError(o - self.origin);
			self.origin = o;
			self.velocity = v;
			SavePrediction();
			Unpredict();
		}
		PredictTo(clientcommandframe);
		self = oldself;

		org = csqcmodel_me.origin + csqcmodel_me.view_ofs + GetPredictionError();
		ang = R_SetView3fv(VF_ANGLES);

		// simulate missing engine features
		if(autocvar_chase_active)
		{
			float dist;
			vector chase_dest;
			dist = -autocvar_chase_back - 8;
			makevectors(ang);
			chase_dest = org + v_forward * dist;
			traceline(org, chase_dest, MOVE_NOMONSTERS, csqcmodel_me);
			org = trace_endpos + 8 * v_forward + 4 * trace_plane_normal;
		}

		R_SetView3fv(VF_ORIGIN, org);
		R_SetView3fv(VF_ANGLES, ang);
	}
}

void CSQCModel_Read()
{
	float sf;
	sf = ReadShort();

	if(self.entnum == player_localentnum)
	{
		if(self.status != 1)
			Unpredict();
	}
	else
		InterpolateOrigin_Undo();

#define PROPERTY(flag,r,w,f) \
	if(sf & flag) \
		self.f = r();
#define PROPERTY_SCALED(flag,r,w,f,s,mi,ma) \
	if(sf & flag) \
		self.f = r() / s;
	ALLPROPERTIES
#undef PROPERTY_SCALED
#undef PROPERTY
	
	// interpolation
	if(self.entnum == player_localentnum)
	{
		self.status = 1;
		csqcmodel_me = self;
	}
	else
		InterpolateOrigin_Note();

	// draw it
	if(self.entnum <= maxclients)
		self.renderflags = RF_EXTERNALMODEL;
	self.drawmask = MASK_NORMAL;
	self.predraw = CSQCModel_Draw;
}

#endif
