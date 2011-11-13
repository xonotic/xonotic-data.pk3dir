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

// generic CSQC model code

.vector glowmod;
.vector view_ofs;

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
	InterpolateOrigin_Do();
}

void CSQCModel_Read()
{
	float sf;
	sf = ReadShort();

	CSQCPlayer_PreUpdate();
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
	
	InterpolateOrigin_Note();
	CSQCPlayer_PostUpdate();

	// draw it
	self.drawmask = MASK_NORMAL;
	self.predraw = CSQCModel_Draw;
}

#endif
