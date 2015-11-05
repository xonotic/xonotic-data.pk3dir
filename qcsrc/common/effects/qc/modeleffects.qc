#ifdef IMPLEMENTATION

REGISTER_NET_LINKED(ENT_CLIENT_MODELEFFECT)

#ifdef SVQC

.float scale2;

bool modeleffect_SendEntity(entity this, entity to, int sf)
{
	float f;
	WriteHeader(MSG_ENTITY, ENT_CLIENT_MODELEFFECT);

	f = 0;
	if(self.velocity != '0 0 0')
		f |= 1;
	if(self.angles != '0 0 0')
		f |= 2;
	if(self.avelocity != '0 0 0')
		f |= 4;

	WriteByte(MSG_ENTITY, f);
	WriteShort(MSG_ENTITY, self.modelindex);
	WriteByte(MSG_ENTITY, self.skin);
	WriteByte(MSG_ENTITY, self.frame);
	WriteCoord(MSG_ENTITY, self.origin.x);
	WriteCoord(MSG_ENTITY, self.origin.y);
	WriteCoord(MSG_ENTITY, self.origin.z);
	if(f & 1)
	{
		WriteCoord(MSG_ENTITY, self.velocity.x);
		WriteCoord(MSG_ENTITY, self.velocity.y);
		WriteCoord(MSG_ENTITY, self.velocity.z);
	}
	if(f & 2)
	{
		WriteCoord(MSG_ENTITY, self.angles.x);
		WriteCoord(MSG_ENTITY, self.angles.y);
		WriteCoord(MSG_ENTITY, self.angles.z);
	}
	if(f & 4)
	{
		WriteCoord(MSG_ENTITY, self.avelocity.x);
		WriteCoord(MSG_ENTITY, self.avelocity.y);
		WriteCoord(MSG_ENTITY, self.avelocity.z);
	}
	WriteShort(MSG_ENTITY, self.scale * 256.0);
	WriteShort(MSG_ENTITY, self.scale2 * 256.0);
	WriteByte(MSG_ENTITY, self.teleport_time * 100.0);
	WriteByte(MSG_ENTITY, self.fade_time * 100.0);
	WriteByte(MSG_ENTITY, self.alpha * 255.0);

	return true;
}

void modeleffect_spawn(string m, float s, float f, vector o, vector v, vector ang, vector angv, float s0, float s2, float a, float t1, float t2)
{
	entity e = new(modeleffect);
	_setmodel(e, m);
	e.frame = f;
	setorigin(e, o);
	e.velocity = v;
	e.angles = ang;
	e.avelocity = angv;
	e.alpha = a;
	e.teleport_time = t1;
	e.fade_time = t2;
	e.skin = s;
	if(s0 >= 0)
		e.scale = s0 / max6(-e.mins.x, -e.mins.y, -e.mins.z, e.maxs.x, e.maxs.y, e.maxs.z);
	else
		e.scale = -s0;
	if(s2 >= 0)
		e.scale2 = s2 / max6(-e.mins.x, -e.mins.y, -e.mins.z, e.maxs.x, e.maxs.y, e.maxs.z);
	else
		e.scale2 = -s2;
	float sz = max(e.scale, e.scale2);
	setsize(e, e.mins * sz, e.maxs * sz);
	Net_LinkEntity(e, false, 0.1, modeleffect_SendEntity);
}

#endif

#ifdef CSQC

entityclass(ModelEffect);
class(ModelEffect) .float frame1time;
class(ModelEffect) .float lifetime, fadetime;
class(ModelEffect) .float teleport_time;
class(ModelEffect) .float scale1, scale2;

.float cnt;
.float scale;
.float alpha;

void ModelEffect_Draw(entity this)
{
	self.angles = self.angles + frametime * self.avelocity;
	setorigin(self, self.origin + frametime * self.velocity);
	self.scale = self.scale1 + (self.scale2 - self.scale1) * (time - self.teleport_time) / (self.lifetime + self.fadetime - self.teleport_time);
	self.alpha = self.cnt * bound(0, 1 - (time - self.lifetime) / self.fadetime, 1);
	if(self.alpha < ALPHA_MIN_VISIBLE)
	{
		remove(self);
		return;
	}
	self.drawmask = MASK_NORMAL;
	if(self.scale <= 0)
	{
		self.drawmask = 0;
		return;
	}
}

NET_HANDLE(ENT_CLIENT_MODELEFFECT, bool isnew)
{
	make_pure(self);

	int f = ReadByte();

	entity e = new(modeleffect);
	e.model = "from network";
	e.modelindex = ReadShort();
	e.skin = ReadByte();
	e.frame = ReadByte();
	e.frame1time = time;
	e.origin_x = ReadCoord();
	e.origin_y = ReadCoord();
	e.origin_z = ReadCoord();
	setorigin(e, e.origin);
	if(f & 1)
	{
		e.velocity_x = ReadCoord();
		e.velocity_y = ReadCoord();
		e.velocity_z = ReadCoord();
	}
	if(f & 2)
	{
		e.angles_x = ReadAngle();
		e.angles_y = ReadAngle();
		e.angles_z = ReadAngle();
	}
	if(f & 4)
	{
		e.avelocity_x = ReadAngle();
		e.avelocity_y = ReadAngle();
		e.avelocity_z = ReadAngle();
	}
	e.scale1 = ReadShort() / 256.0;
	e.scale2 = ReadShort() / 256.0;
	e.lifetime = time + ReadByte() * 0.01;
	e.fadetime = ReadByte() * 0.01;
	e.teleport_time = time;
	e.cnt = ReadByte() / 255.0; // actually alpha

	e.draw = ModelEffect_Draw;

	if (!isnew) remove(e); // yes, this IS stupid, but I don't need to duplicate all the read* stuff then
	return true;
}
#endif

#endif
