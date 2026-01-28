#include "net.qh"

#ifdef GAMEQC

#include "nades.qh"

#ifdef CSQC
#include <client/view.qh>

void orb_draw(entity this)
{
	float age = max(0, time - this.spawntime);
	float dt = max(0, time - this.update_time);
	this.update_time = time;

	if (dt > 0)
	{
		this.avelocity *= 24 ** (dt / this.lifetime); // speed up, frametime independent
		this.angles += dt * this.avelocity;
	}
	if (age > 0)
	{
		this.scale = this.radius * (age >= this.animstate_endtime
			? 1
			: (this.height * age * (age - this.animstate_endtime * 2))); // increases at decreasing pace up to .radius, as age -> .animstate_endtime
		this.alpha = sqrt(1 - age / this.lifetime); // slowly fade out
	}
}

void orb_draw2d(entity this)
{
	static float orb_drawtime; // last drawn orb frame, to counter overlapping orbs
	if (time <= orb_drawtime)
		return;

	if (boxesoverlap(view_origin - '1 1 1', view_origin + '1 1 1', this.absmin, this.absmax)) // nade orbs actually act as a cube
	{
		orb_drawtime = time; // prevent rendering more than one of these per frame!
		float orb_alpha = this.alpha * 0.6;
		drawfill('0 0 0', vec2(vid_conwidth, vid_conheight), this.colormod, autocvar_hud_colorflash_alpha * orb_alpha, DRAWFLAG_ADDITIVE);
	}
}

void orb_setup(entity e)
{
	e.spawntime = time;
	e.update_time = time; // used to calculate dt
	e.animstate_endtime = 0.25 * min(e.lifetime, 1); // when the orb will stop expanding
	e.height = -4 * (2 * e.animstate_endtime) ** -2; // amplitude used in scaling calculation

	setmodel(e, MDL_NADE_ORB);
	e.skin = 1;

	float model_radius = e.maxs.x;
	vector size = '0.5 0.5 0.5' * e.radius;
	setsize(e, -size, size);
	e.radius *= 0.6 / model_radius;

	e.draw = orb_draw;
	e.draw2d = orb_draw2d;
	IL_PUSH(g_drawables, e);
	IL_PUSH(g_drawables_2d, e);
	SetResourceExplicit(e, RES_HEALTH, 255);
	set_movetype(e, MOVETYPE_NONE);
	e.solid = SOLID_NOT;
	e.drawmask = MASK_NORMAL;
	e.renderflags |= RF_ADDITIVE;
	e.scale = 0.01;
	float spin_dir = 2*M_PI * random();
	e.avelocity = '6 0 0' * sin(spin_dir) + '0 0 6' * cos(spin_dir);
}
#endif // CSQC

REGISTER_NET_LINKED(Nade_Orb)

#ifdef CSQC
NET_HANDLE(Nade_Orb, bool isNew)
{
	Net_Accept(Nade_Orb);

	setorigin(this, ReadVector());
	this.colormod = ReadVector();
	this.lifetime = ReadFloat();
	this.radius = ReadShort();

	if (isNew)
		orb_setup(this);
	return true;
}
#endif // CSQC

#ifdef SVQC
bool orb_send(entity this, entity to, int sf)
{
	WriteHeader(MSG_ENTITY, Nade_Orb);
	WriteVector(MSG_ENTITY, this.origin);
	WriteVector(MSG_ENTITY, this.colormod);
	WriteFloat(MSG_ENTITY, this.lifetime);
	WriteShort(MSG_ENTITY, this.radius);
	return true;
}
#endif // SVQC

#endif // GAMEQC
