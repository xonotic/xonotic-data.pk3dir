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

var float autocvar_cl_lerpanim_maxdelta_framegroups = 0.1;
var float autocvar_cl_nolerp = 0;

.float csqcmodel_lerpfrac;
.float csqcmodel_lerpfrac2;
.float csqcmodel_lerpfractime;

void CSQCModel_InterpolateAnimation_PreNote(float sf)
{
#ifdef CSQCMODELS_HAVE_TWO_FRAMES
	if(sf & PROPERTY_FRAME)
	{
		self.frame3 = self.frame;
		self.frame3time = self.frame1time;
	}
	if(sf & PROPERTY_FRAME2)
	{
		self.frame4 = self.frame2;
		self.frame4time = self.frame2time;
	}
	if(sf & PROPERTY_LERPFRAC)
	{
		self.csqcmodel_lerpfrac2 = self.csqcmodel_lerpfrac;
		self.lerpfrac = self.csqcmodel_lerpfrac;
	}
#else
	if(sf & PROPERTY_FRAME)
	{
		self.frame2 = self.frame;
		self.frame2time = self.frame1time;
		self.frame1time = time;
	}
#endif
}

void CSQCModel_InterpolateAnimation_Note(float sf)
{
#ifdef CSQCMODELS_HAVE_TWO_FRAMES
	if(sf & PROPERTY_FRAME)
	{
		self.frame1time = time;
	}
	if(sf & PROPERTY_FRAME2)
	{
		self.frame2time = time;
	}
	if(sf & PROPERTY_LERPFRAC)
	{
		self.csqcmodel_lerpfrac = self.lerpfrac;
		self.csqcmodel_lerpfractime = time;
	}
#else
	if(sf & PROPERTY_FRAME)
	{
		self.frame2 = self.frame;
		self.frame2time = self.frame1time;
		self.frame1time = time;
	}
#endif
}

void CSQCModel_InterpolateAnimation_Do()
{
#ifdef CSQCMODELS_HAVE_TWO_FRAMES
	if(autocvar_cl_nolerp || (autocvar_cl_lerpanim_maxdelta_framegroups == 0))
	{
		self.lerpfrac = self.csqcmodel_lerpfrac;
		self.lerpfrac3 = 0;
		self.lerpfrac4 = 0;
	}
	else
	{
		float l13, l24, llf;
		float l24_13;
		l13 = bound(0, (time - self.frame1time) / autocvar_cl_lerpanim_maxdelta_framegroups, 1);
		l24 = bound(0, (time - self.frame2time) / autocvar_cl_lerpanim_maxdelta_framegroups, 1);
		llf = bound(0, (time - self.csqcmodel_lerpfractime) / autocvar_cl_lerpanim_maxdelta_framegroups, 1);
		l24_13 = self.csqcmodel_lerpfrac * llf + self.csqcmodel_lerpfrac2 * (1 - llf);

		self.lerpfrac  = l24 * l24_13;
		self.lerpfrac4 = (1 - l24) * l24_13;
		self.lerpfrac3 = (1 - l13) * (1 - l24_13);
	}
#else
	if(autocvar_cl_nolerp || (autocvar_cl_lerpanim_maxdelta_framegroups == 0))
	{
		self.lerpfrac = 0;
	}
	else
	{
		self.lerpfrac = 1 - bound(0, (time - self.frame1time) / autocvar_cl_lerpanim_maxdelta_framegroups, 1);
	}
#endif
}

void CSQCModel_Draw()
{
	InterpolateOrigin_Do();
	CSQCModel_InterpolateAnimation_Do();
}

void CSQCModel_Read()
{
	float sf;
	sf = ReadShort();

	self.iflags |= IFLAG_ANGLES; // interpolate angles too

	CSQCPlayer_PreUpdate();
	InterpolateOrigin_Undo();
	CSQCModel_InterpolateAnimation_PreNote(sf);

#define PROPERTY(flag,r,w,f) \
	if(sf & flag) \
		self.f = r();
#define PROPERTY_SCALED(flag,r,w,f,s,mi,ma) \
	if(sf & flag) \
		self.f = r() / s;
	ALLPROPERTIES
#undef PROPERTY_SCALED
#undef PROPERTY
	
	CSQCModel_InterpolateAnimation_Note(sf);
	InterpolateOrigin_Note();
	CSQCPlayer_PostUpdate();

#ifdef CSQCMODELS_SUPPORT_GETTAGINFO_BEFORE_DRAW
	InterpolateOrigin_Do();
	CSQCModel_InterpolateAnimation_Do();
#endif

	// draw it
	self.drawmask = MASK_NORMAL;
	self.predraw = CSQCModel_Draw;
}
