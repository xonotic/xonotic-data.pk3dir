// generic CSQC model code

#define ALLPROPERTIES \
	PROPERTY(1, ReadCoord, WriteCoord, origin_x) \
	PROPERTY(1, ReadCoord, WriteCoord, origin_y) \
	PROPERTY(1, ReadCoord, WriteCoord, origin_z) \
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
	PROPERTY_SCALED(128, ReadByte, WriteByte, glowmod_z, 32, 0, 255)

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

void CSQCModel_Read()
{
	float sf;
	sf = ReadShort();

#define PROPERTY(flag,r,w,f) \
	if(sf & flag) \
		self.f = r();
#define PROPERTY_SCALED(flag,r,w,f,s,mi,ma) \
	if(sf & flag) \
		self.f = r() / s;
	ALLPROPERTIES
#undef PROPERTY_SCALED
#undef PROPERTY
	
	// if it is the local player, prediction and make sure camera gets set up by it
	// interpolation
	// draw it
}

#endif
