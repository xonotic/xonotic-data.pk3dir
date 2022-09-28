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
#include "interpolate.qh"

// 1 = old, 2 = new
.vector iorigin1, iorigin2;
.vector ivelocity1, ivelocity2;
.vector iforward1, iforward2;
.vector iup1, iup2;
.vector ivforward1, ivforward2;
.vector ivup1, ivup2;
.float itime1, itime2;
void InterpolateOrigin_Reset(entity this)
{
	this.iflags &= ~IFLAG_INTERNALMASK;
	this.itime1 = this.itime2 = 0;
}
void InterpolateOrigin_Note(entity this)
{
	float dt = time - this.itime2;

	int f0 = this.iflags;
	if (this.iflags & IFLAG_PREVALID) this.iflags |= IFLAG_VALID;
	else this.iflags |= IFLAG_PREVALID;

	if (this.iflags & IFLAG_ORIGIN)
	{
		this.iorigin1 = this.iorigin2;
		this.iorigin2 = this.origin;
	}

	if ((this.iflags & IFLAG_AUTOANGLES) && this.iorigin2 != this.iorigin1)
		this.angles = vectoangles(this.iorigin2 - this.iorigin1);

	if ((this.iflags & IFLAG_AUTOVELOCITY) && this.itime2 != this.itime1)
		this.velocity = (this.iorigin2 - this.iorigin1) * (1.0 / (this.itime2 - this.itime1));

	if (this.iflags & IFLAG_ANGLES)
	{
		vector forward, right, up;
		FIXED_MAKE_VECTORS(this.angles, forward, right, up);
		if (f0 & IFLAG_VALID)
		{
			this.iforward1 = this.iforward2;
			this.iup1 = this.iup2;
		}
		else
		{
			this.iforward1 = forward;
			this.iup1 = up;
		}
		this.iforward2 = forward;
		this.iup2 = up;
	}

	if (this.iflags & IFLAG_V_ANGLE)
	{
		vector forward, right, up;
		FIXED_MAKE_VECTORS(this.v_angle, forward, right, up);
		if (f0 & IFLAG_VALID)
		{
			this.ivforward1 = this.ivforward2;
			this.ivup1 = this.ivup2;
		}
		else
		{
			this.ivforward1 = forward;
			this.ivup1 = up;
		}
		this.ivforward2 = forward;
		this.ivup2 = up;
	}
	else if (this.iflags & IFLAG_V_ANGLE_X)
	{
		this.ivforward1_x = this.ivforward2_x;
		this.ivforward2_x = this.v_angle.x;
	}

	if (this.iflags & IFLAG_VELOCITY)
	{
		this.ivelocity1 = this.ivelocity2;
		this.ivelocity2 = this.velocity;
	}

	if (this.iflags & IFLAG_TELEPORTED)
	{
		this.iflags &= ~IFLAG_TELEPORTED;
		this.itime1 = this.itime2 = time;  // don't lerp
	}
	else if (vdist(this.iorigin2 - this.iorigin1, >, 1000))
	{
		this.itime1 = this.itime2 = time;  // don't lerp
	}
	else if ((this.iflags & IFLAG_VELOCITY) && vdist(this.ivelocity2 - this.ivelocity1, >, 1000))
	{
		this.itime1 = this.itime2 = time;  // don't lerp
	}
	else if (dt >= 0.2)
	{
		this.itime1 = this.itime2 = time;
	}
	else
	{
		this.itime1 = serverprevtime;
		this.itime2 = time;
	}
}

/** set origin based on iorigin1 (old pos), iorigin2 (desired pos), and time */
void InterpolateOrigin_Do(entity this)
{
	if (this.itime1 && this.itime2 && this.itime1 != this.itime2)
	{
		float f = bound(0, (time - this.itime1) / (this.itime2 - this.itime1), 1 + autocvar_cl_lerpexcess);
		float f_1 = 1 - f;
		if (this.iflags & IFLAG_ORIGIN)
			setorigin(this, f_1 * this.iorigin1 + f * this.iorigin2);
		if (this.iflags & IFLAG_ANGLES)
		{
			vector forward = f_1 * this.iforward1 + f * this.iforward2;
			vector up = f_1 * this.iup1 + f * this.iup2;
			this.angles = fixedvectoangles2(forward, up);
		}
		if (this.iflags & IFLAG_V_ANGLE)
		{
			vector forward = f_1 * this.ivforward1 + f * this.ivforward2;
			vector up = f_1 * this.ivup1 + f * this.ivup2;
			this.v_angle = fixedvectoangles2(forward, up);
		}
		else if (this.iflags & IFLAG_V_ANGLE_X)
		{
			this.v_angle_x = f_1 * this.ivforward1.x + f * this.ivforward2.x;
		}
		if (this.iflags & IFLAG_VELOCITY)
			this.velocity = f_1 * this.ivelocity1 + f * this.ivelocity2;
	}
}

/** snap origin to iorigin2 (actual origin) */
void InterpolateOrigin_Undo(entity this)
{
	if (this.iflags & IFLAG_ORIGIN) setorigin(this, this.iorigin2);
	if (this.iflags & IFLAG_ANGLES) this.angles = fixedvectoangles2(this.iforward2, this.iup2);
	if (this.iflags & IFLAG_V_ANGLE) this.v_angle = fixedvectoangles2(this.ivforward2, this.ivup2);
	else if (this.iflags & IFLAG_V_ANGLE_X) this.v_angle_x = this.ivforward2_x;
	if (this.iflags & IFLAG_VELOCITY) this.velocity = this.ivelocity2;
}
