#include "net.qh"

#ifdef GAMEQC

#include "nades.qh"

#ifdef CSQC
#include <client/view.qh>

.float ltime;
void orb_draw(entity this)
{
	float dt = time - this.move_time;
	this.move_time = time;
	if (dt <= 0)
		return;

	this.alpha = (this.ltime - time) / this.orb_lifetime;
	this.scale = min((1 - this.alpha) * this.orb_lifetime * 4, 1) * this.orb_radius;
	this.angles += dt * this.avelocity;
}

float orb_drawtime; // global storage of last drawn orb frame, to counter overlapping orbs
void orb_draw2d(entity this)
{
	if (time <= orb_drawtime)
		return;

	if (boxesoverlap(view_origin - '1 1 1', view_origin + '1 1 1', this.absmin, this.absmax)) // nade orbs actually act as a cube
	{
		orb_drawtime = time; // prevent rendering more than one of these per frame!
		float orb_alpha = 0.65 * (this.ltime - time) / this.orb_lifetime;
		drawfill('0 0 0', vec2(vid_conwidth, vid_conheight), this.colormod, autocvar_hud_colorflash_alpha * orb_alpha, DRAWFLAG_ADDITIVE);
	}
}

void orb_setup(entity e)
{
	setmodel(e, MDL_NADE_ORB);
	e.skin = 1;

	setorigin(e, e.origin);

	float model_radius = e.maxs.x;
	vector size = '0.5 0.5 0.5' * e.orb_radius;
	setsize(e, -size, size);
	e.orb_radius *= 0.6 / model_radius;

	e.draw = orb_draw;
	e.draw2d = orb_draw2d;
	IL_PUSH(g_drawables, e);
	IL_PUSH(g_drawables_2d, e);
	SetResourceExplicit(e, RES_HEALTH, 255);
	set_movetype(e, MOVETYPE_NONE);
	e.solid = SOLID_NOT;
	e.drawmask = MASK_NORMAL;
	e.scale = 0.01;
	e.avelocity = '7 0 11';
	e.renderflags |= RF_ADDITIVE;
}
#endif // CSQC

REGISTER_NET_LINKED(Nade_Orb)

#ifdef CSQC
NET_HANDLE(Nade_Orb, bool isNew)
{
	Net_Accept(Nade_Orb);

	setorigin(this, ReadVector());
	this.colormod = ReadVector();
	this.orb_lifetime = ReadFloat();
	this.orb_radius = ReadShort();
	//this.ltime = time + ReadByte() / 10.0;
	this.ltime = time + this.orb_lifetime;

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
	WriteFloat(MSG_ENTITY, this.orb_lifetime);
	WriteShort(MSG_ENTITY, this.orb_radius);
	//WriteByte(MSG_ENTITY, (this.ltime - time) * 10.0 + 0.5); // round time delta to a 1/10th of a second
	return true;
}
#endif // SVQC

#endif // GAMEQC
