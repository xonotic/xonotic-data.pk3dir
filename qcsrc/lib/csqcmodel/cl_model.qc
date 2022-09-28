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
#include "cl_model.qh"

#include "cl_player.qh"
#include "common.qh"
#include "interpolate.qh"
#include <common/csqcmodel_settings.qh>

float autocvar_cl_lerpanim_maxdelta_framegroups = 0.1;
float autocvar_cl_nolerp = 0;

.float csqcmodel_lerpfrac;
.float csqcmodel_lerpfrac2;
.float csqcmodel_lerpfractime;
.float csqcmodel_lerpfrac2time;

void CSQCModel_InterpolateAnimation_2To4_PreNote(entity this, int sf)
{
	if(sf & CSQCMODEL_PROPERTY_FRAME)
	{
		this.frame3 = this.frame;
		this.frame3time = this.frame1time;
	}
	if(sf & CSQCMODEL_PROPERTY_FRAME2)
	{
		this.frame4 = this.frame2;
		this.frame4time = this.frame2time;
	}
	if(sf & CSQCMODEL_PROPERTY_LERPFRAC)
	{
		this.csqcmodel_lerpfrac2 = this.csqcmodel_lerpfrac;
		this.csqcmodel_lerpfrac2time = this.csqcmodel_lerpfractime;
		this.lerpfrac = this.csqcmodel_lerpfrac;
	}
}
void CSQCModel_InterpolateAnimation_1To2_PreNote(entity this, int sf)
{
	if(sf & CSQCMODEL_PROPERTY_FRAME)
	{
		this.frame2 = this.frame;
		this.frame2time = this.frame1time;
	}
}
void CSQCModel_InterpolateAnimation_PreNote(entity this, int sf)
{
#ifdef CSQCMODEL_HAVE_TWO_FRAMES
	CSQCModel_InterpolateAnimation_2To4_PreNote(this, sf);
#else
	CSQCModel_InterpolateAnimation_1To2_PreNote(this, sf);
#endif
}

void CSQCModel_InterpolateAnimation_2To4_Note(entity this, int sf, bool set_times)
{
	if(sf & CSQCMODEL_PROPERTY_FRAME)
	{
		if(set_times)
			this.frame1time = time;
	}
	if(sf & CSQCMODEL_PROPERTY_FRAME2)
	{
		if(set_times)
			this.frame2time = time;
	}
	if(sf & CSQCMODEL_PROPERTY_LERPFRAC)
	{
		this.csqcmodel_lerpfrac = this.lerpfrac;
		if(set_times)
			this.csqcmodel_lerpfractime = time;
	}
}
void CSQCModel_InterpolateAnimation_1To2_Note(entity this, int sf, bool set_times)
{
	if(sf & CSQCMODEL_PROPERTY_FRAME)
	{
		if(set_times)
			this.frame1time = time;
	}
}
void CSQCModel_InterpolateAnimation_Note(entity this, int sf)
{
#ifdef CSQCMODEL_HAVE_TWO_FRAMES
	CSQCModel_InterpolateAnimation_2To4_Note(this, sf, true);
#else
	CSQCModel_InterpolateAnimation_1To2_Note(this, sf, true);
#endif
}

void CSQCModel_InterpolateAnimation_2To4_Do(entity this)
{
	if(autocvar_cl_nolerp || (autocvar_cl_lerpanim_maxdelta_framegroups == 0))
	{
		this.lerpfrac = this.csqcmodel_lerpfrac;
		this.lerpfrac3 = 0;
		this.lerpfrac4 = 0;
	}
	else
	{
		float l13, l24, llf;
		float l24_13;

		if(this.frame3time == 0) // if frame1/3 were not previously displayed, only frame1 can make sense
			l13 = 1;
		else
			l13 = bound(0, (time - this.frame1time) / autocvar_cl_lerpanim_maxdelta_framegroups, 1);

		if(this.frame4time == 0) // if frame2/4 were not previously displayed, only frame2 can make sense
			l24 = 1;
		else
			l24 = bound(0, (time - this.frame2time) / autocvar_cl_lerpanim_maxdelta_framegroups, 1);

		if(this.csqcmodel_lerpfrac2time == 0) // if there is no old lerpfrac (newly displayed model), only lerpfrac makes sense
			llf = 1;
		else
			llf = bound(0, (time - this.csqcmodel_lerpfractime) / autocvar_cl_lerpanim_maxdelta_framegroups, 1);

		l24_13 = this.csqcmodel_lerpfrac * llf + this.csqcmodel_lerpfrac2 * (1 - llf);

		this.lerpfrac  = l24 * l24_13;
		this.lerpfrac4 = (1 - l24) * l24_13;
		this.lerpfrac3 = (1 - l13) * (1 - l24_13);

		if(l24_13 == 0) // if frames 2/4 are not displayed, clear their frametime
		{
			this.frame2time = 0;
			this.frame4time = 0;
		}

		if(l24_13 == 1) // if frames 1/3 are not displayed, clear their frametime
		{
			this.frame1time = 0;
			this.frame3time = 0;
		}
	}
}
void CSQCModel_InterpolateAnimation_1To2_Do(entity this)
{
	if(autocvar_cl_nolerp || (autocvar_cl_lerpanim_maxdelta_framegroups == 0))
	{
		this.lerpfrac = 0;
	}
	else
	{
		if(this.frame2time == 0) // if frame2 was not previously displayed, only frame1 can make sense
			this.lerpfrac = 0;
		else
			this.lerpfrac = 1 - bound(0, (time - this.frame1time) / autocvar_cl_lerpanim_maxdelta_framegroups, 1);
	}
}
void CSQCModel_InterpolateAnimation_Do(entity this)
{
#ifdef CSQCMODEL_HAVE_TWO_FRAMES
	CSQCModel_InterpolateAnimation_2To4_Do(this);
#else
	CSQCModel_InterpolateAnimation_1To2_Do(this);
#endif
}

void CSQCModel_Draw(entity this)
{
	// some nice flags for CSQCMODEL_IF and the hooks
	bool isplayer = (this.isplayermodel & ISPLAYER_CLIENT);
	noref bool islocalplayer = (this.entnum == player_localnum + 1);
	noref bool isnolocalplayer = (isplayer && (this.entnum != player_localnum + 1));

	// we don't do this for the local player as that one is already handled
	// by CSQCPlayer_SetCamera()
	if (!CSQCPlayer_IsLocalPlayer(this)) InterpolateOrigin_Do(this);

	CSQCModel_InterpolateAnimation_Do(this);

	CSQCModel_Hook_PreDraw(this, isplayer);

	if(isplayer)
	{
		if(this.entnum == player_localentnum)
			this.renderflags |= RF_EXTERNALMODEL;
		else
			this.renderflags &= ~RF_EXTERNALMODEL;
	}

	// inherit draw flags easily
	entity root = this;
	while(root.tag_entity)
		root = root.tag_entity;
	if(this != root)
	{
		this.renderflags &= ~(RF_EXTERNALMODEL | RF_VIEWMODEL);
		this.renderflags |= (root.renderflags & (RF_EXTERNALMODEL | RF_VIEWMODEL));
	}

	// we're drawn, now teleporting is over
	this.csqcmodel_teleported = 0;
}

entity CSQCModel_players[255]; // 255 is engine limit on maxclients

void CSQCModel_remove(entity this)
{
	CSQCModel_players[this.entnum - 1] = NULL;
}

NET_HANDLE(ENT_CLIENT_MODEL, bool isnew)
{
	int sf = ReadInt24_t();
	int psf = ReadByte();

	// some nice flags for CSQCMODEL_IF and the hooks
	bool isplayer = (psf & ISPLAYER_CLIENT) || (this.entnum >= 1 && this.entnum <= maxclients);
	if (isnew && isplayer)
	{
		CSQCModel_players[this.entnum - 1] = this;
		this.entremove = CSQCModel_remove;
	}
	bool islocalplayer = (this.entnum == player_localnum + 1);
	noref bool isnolocalplayer = (isplayer && !islocalplayer);

	this.isplayermodel = BITSET(this.isplayermodel, ISPLAYER_CLIENT, isplayer);
	this.isplayermodel = BITSET(this.isplayermodel, ISPLAYER_LOCAL, islocalplayer);
	this.isplayermodel = BITSET(this.isplayermodel, ISPLAYER_PLAYER, (psf & ISPLAYER_PLAYER));

	this.iflags |= IFLAG_ORIGIN; // interpolate origin too
	this.iflags |= IFLAG_ANGLES; // interpolate angles too
	this.iflags |= IFLAG_VELOCITY | IFLAG_AUTOVELOCITY; // let's calculate velocity automatically

	CSQCModel_Hook_PreUpdate(this, isnew, isplayer, islocalplayer);

	CSQCPlayer_PreUpdate(this);
	InterpolateOrigin_Undo(this);
	CSQCModel_InterpolateAnimation_PreNote(this, sf);

#define CSQCMODEL_IF(cond) if(cond) {
#define CSQCMODEL_ENDIF }
#define CSQCMODEL_PROPERTY(flag,t,r,w,f) \
	if(sf & flag) \
		this.f = r();
#define CSQCMODEL_PROPERTY_SCALED(flag,t,r,w,f,s,mi,ma) \
	if(sf & flag) \
		this.f = (r() + mi) / s;
	ALLPROPERTIES
#undef CSQCMODEL_PROPERTY_SCALED
#undef CSQCMODEL_PROPERTY
#undef CSQCMODEL_ENDIF
#undef CSQCMODEL_IF

	if(sf & CSQCMODEL_PROPERTY_MODELINDEX)
	{
		vector pmin = this.mins, pmax = this.maxs;
		setmodelindex(this, this.modelindex); // this retrieves the .model key and sets mins/maxs/absmin/absmax
		setsize(this, pmin, pmax);
	}

	if(sf & CSQCMODEL_PROPERTY_TELEPORTED)
	{
		this.iflags |= IFLAG_TELEPORTED;
		this.csqcmodel_teleported = 1;
	}

	if(sf & BIT(3))
		this.alpha = this.m_alpha;

	if(sf & BIT(11))
		viewloc_SetTags(this);

	CSQCModel_InterpolateAnimation_Note(this, sf);
	InterpolateOrigin_Note(this);
	CSQCPlayer_PostUpdate(this);

	CSQCModel_Hook_PostUpdate(this, isnew, isplayer, islocalplayer);

#ifdef CSQCMODEL_SUPPORT_GETTAGINFO_BEFORE_DRAW
	InterpolateOrigin_Do(this);
	CSQCModel_InterpolateAnimation_Do(this);
#endif

	// relink
	setorigin(this, this.origin);

	// set obvious render flags
	if(this.entnum == player_localentnum)
		this.renderflags |= RF_EXTERNALMODEL;
	else
		this.renderflags &= ~RF_EXTERNALMODEL;

	// draw it
	this.drawmask = MASK_NORMAL;
	setpredraw(this, CSQCModel_Draw);
	return true;
}

/**
 * @param i zero indexed player
 */
entity CSQCModel_server2csqc(int i)
{
	if (i < maxclients) return CSQCModel_players[i];
	++i;
	LOG_DEBUGF("player out of bounds: %d", i);
	return findfloat(NULL, entnum, i);
}
