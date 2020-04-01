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
#include "sv_model.qh"

#include "common.qh"

// generic CSQC model code

bool CSQCModel_Send(entity this, entity to, int sf)
{
	// some nice flags for CSQCMODEL_IF
	noref bool isplayer = IS_CLIENT(this);
	noref bool islocalplayer = (this == to);
	noref bool isnolocalplayer = (isplayer && (this != to));

	int psf = 0;
	psf = BITSET(psf, ISPLAYER_CLIENT, isplayer);
	psf = BITSET(psf, ISPLAYER_LOCAL, islocalplayer);
	psf = BITSET(psf, ISPLAYER_PLAYER, IS_PLAYER(this));

	WriteHeader(MSG_ENTITY, ENT_CLIENT_MODEL);
	WriteInt24_t(MSG_ENTITY, sf);
	WriteByte(MSG_ENTITY, psf);

#define CSQCMODEL_IF(cond) if(cond) {
#define CSQCMODEL_ENDIF }
#define CSQCMODEL_PROPERTY(flag,t,r,w,f) \
	if(sf & flag) \
	{ \
		w(MSG_ENTITY, this.csqcmodel_##f); \
	}
#define CSQCMODEL_PROPERTY_SCALED(flag,t,r,w,f,s,mi,ma) \
	if(sf & flag) \
	{ \
		w(MSG_ENTITY, this.csqcmodel_##f); \
	}
	ALLPROPERTIES
#undef CSQCMODEL_PROPERTY_SCALED
#undef CSQCMODEL_PROPERTY
#undef CSQCMODEL_ENDIF
#undef CSQCMODEL_IF

	return true;
}

#if CSQCPLAYER_FORCE_UPDATES
.float csqcmodel_nextforcedupdate;
#endif
void CSQCModel_CheckUpdate(entity e)
{
	// some nice flags for CSQCMODEL_IF
	noref float isplayer = IS_CLIENT(e);
	noref float islocalplayer = isplayer; // we set BOTH to 1 here as we need the sendflags
	noref float isnolocalplayer = isplayer; // we set BOTH to 1 here as we need the sendflags

#if CSQCPLAYER_FORCE_UPDATES
	if(isplayer && time > e.csqcmodel_nextforcedupdate)
	{
		e.SendFlags |= CSQCMODEL_PROPERTY_ORIGIN;
		e.csqcmodel_nextforcedupdate = time + (1 / (CSQCPLAYER_FORCE_UPDATES)) * (0.5 + random()); // ensure about 4 origin sends per sec
	}
#endif

	if(e.effects & EF_RESTARTANIM_BIT)
	{
		e.SendFlags |= CSQCMODEL_PROPERTY_FRAME | CSQCMODEL_PROPERTY_FRAME2; // full anim resend please
		e.effects &= ~EF_RESTARTANIM_BIT;
	}

	if(e.effects & EF_TELEPORT_BIT)
	{
		e.SendFlags |= CSQCMODEL_PROPERTY_TELEPORTED; // no interpolation please
		e.effects &= ~EF_TELEPORT_BIT;
	}

#define CSQCMODEL_IF(cond) if(cond) {
#define CSQCMODEL_ENDIF }
#define CSQCMODEL_PROPERTY(flag,t,r,w,f) \
	{ \
		t tmp = e.f; \
		if(tmp != e.csqcmodel_##f) \
		{ \
			e.csqcmodel_##f = tmp; \
			e.SendFlags |= flag; \
		} \
	}
#define CSQCMODEL_PROPERTY_SCALED(flag,t,r,w,f,s,mi,ma) \
	{ \
		t tmp = rint(bound(mi, s * e.f, ma) - mi); \
		if(tmp != e.csqcmodel_##f) \
		{ \
			e.csqcmodel_##f = tmp; \
			e.SendFlags |= flag; \
		} \
	}
	ALLPROPERTIES
#undef CSQCMODEL_PROPERTY_SCALED
#undef CSQCMODEL_PROPERTY
#undef CSQCMODEL_ENDIF
#undef CSQCMODEL_IF
}

void CSQCModel_LinkEntity(entity e)
{
	setSendEntity(e, CSQCModel_Send);
	e.SendFlags = 0xFFFFFF;
	CSQCModel_CheckUpdate(e);
}

void CSQCModel_UnlinkEntity(entity e)
{
	setSendEntity(e, func_null);
}
