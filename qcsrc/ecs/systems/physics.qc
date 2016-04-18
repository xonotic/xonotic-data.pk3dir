#include "physics.qh"

const int PHYSICS_TRACE_PLANE_MAX = 5;

// NOTE: currently unsuitable for players
void sys_phys_update(entity this, float dt)
{
	// x: { 60: 0.5, 45: ~0.7, 30: ~0.9 }, from: 'vec2(0, 1) * vec2(cos(90 - x), sin(90 - x))'
	// read as 'within x degrees'
	float maxgrounddot = 0.5;
	float maxstepdot = 0.7;
	vector upvec = '0 0 1';
	float groundsnap = 1;
	bool jump = this.com_in_jump;
	bool jumpstep = true;

	vector mn = this.mins;
	vector mx = this.maxs;

	vector acc = this.com_phys_acc;
	vector vel = this.com_phys_vel;
	vector pos = this.com_phys_pos_prev = this.com_phys_pos;
	bool onground = this.com_phys_grounded;

	bool nogravityonground = this.com_phys_nogravityonground;
	float stepheight = this.com_phys_stepheight;
	float stepdownheight = -stepheight;
	float jumpvel = this.com_phys_jumpvel;
	float bounce = this.com_phys_bounce;
	float friction = this.com_phys_friction;
	float gravity = this.com_phys_gravity;
	bool noclip = this.com_phys_noclip;
	if (noclip) {
	    jump = false;
	    nogravityonground = false;
	}

	vector g = upvec * -gravity;

	// apply accelaration in two steps: https://www.niksula.hut.fi/~hkankaan/Homepages/gravity.html
	// alternatives: rk4, verlet, euler
	vel += (acc + g) * dt / 2;
	{
		if (onground || noclip)
		{
			if (nogravityonground)
			{
                g = '0 0 0';
			    if (vel * upvec < 0) vel = vec_reflect(vel, upvec, 0);  // kill downward velocity
			}
			if (jump)
			{
				vel += upvec * jumpvel;
			}
			else  // the first landing frame is free
			{
				// friction
				vector slide = noclip ? vel : vec_reflect(vel, upvec, 0);
				vector push = vel - slide;
				// TODO: slick
				slide *= 1 - friction * dt;
				vel = slide + push;
			}
		}
		vector step = vel * dt;
		bool pass = false;
		bool foundground = false;                  // assume until proven otherwise
		if (nogravityonground) foundground = true; // override
		bool steplimit = 1;
		if (noclip) pass = true; else
		for (int i = 0; i < PHYSICS_TRACE_PLANE_MAX; ++i)
		{
			vector p0 = pos;
			vector p1 = p0 + step;
			tracebox(p0, mn, mx, p1, MOVE_NORMAL, this);
			float frac = trace_fraction;
			vector norm = trace_plane_normal;
			if (frac == 1)
			{
				// all clear
				if (steplimit > 0 && onground && vel * upvec <= 0)
				{
					// can we step down?
					tracebox(p1, mn, mx, p1 + upvec * stepdownheight, MOVE_NORMAL, this);
					if (trace_fraction == 1)
					{
						// no stairs here
					}
					else if (trace_plane_normal * upvec >= maxstepdot)
					{
						// step down
						step += upvec * (stepdownheight * trace_fraction);
					}
				}
				pass = true;
				break;
			}
			// hit something
			if (norm * upvec >= maxgrounddot) foundground = true;
			if (steplimit > 0 && (jumpstep || onground))    // try: vel * upvec >= 0
			{
				// can we step up?
				vector slide = vec_reflect(step, upvec, 0); // remove fall component
				vector p1 = p0 + slide;                     // step is here
				tracebox(p1 + upvec * stepheight, mn, mx, p1, MOVE_NORMAL, this);
				if (trace_fraction < 1 && trace_plane_normal * upvec >= maxstepdot)
				{
					// there is a step in front of us, get above it
					// TODO: not if it's slippery (slick)
					vector stepup = upvec * (1 - trace_fraction) * stepheight;
					tracebox(p0, mn, mx, p0 + stepup, MOVE_NORMAL, this);
					if (trace_fraction == 1)
					{
						// go over
						tracebox(p0 + stepup, mn, mx, p1 + stepup, MOVE_NORMAL, this);
						if (trace_fraction == 1)
						{
							// all clear
							steplimit -= 1;
							pos += stepup;
							if (vel * upvec < 0) vel = vec_reflect(vel, upvec, 0);  // kill downward velocity
							step = p1 - p0;
							pass = true;
							break;
						}
					}
				}
			}
			// no stairs here
			pos += frac * step;
			vel = vec_reflect(vel, norm, bounce);
			step = (1 - frac) * vel * dt;
			continue;
		}
		if (nogravityonground)
		{
			vector p1 = pos + step;
			tracebox(p1, mn, mx, p1 - groundsnap * upvec, MOVE_NORMAL, this);
			foundground = trace_plane_normal * upvec >= maxgrounddot;
		}
		if (pass)
		{
			pos += step;
			if (!foundground)
			{
				if (onground) emit(phys_stepfall, this);
			}
			else
			{
				if (!onground) emit(phys_stepland, this);
			}
			onground = foundground;
		}
	}
	vel += (acc + g) * dt / 2;

	this.com_phys_acc = acc;
	this.com_phys_vel = vel;
	this.com_phys_pos = pos;
	this.com_phys_grounded = onground;
}
