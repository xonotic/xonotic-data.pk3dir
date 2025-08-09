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
	if(dt <= 0)
		return;

	this.alpha = (this.ltime - time) / this.orb_lifetime;
	this.scale = min((1 - this.alpha)*this.orb_lifetime*4,1)*this.orb_radius;
	this.angles = this.angles + dt * this.avelocity;
}

float orb_drawtime; // global storage of last drawn orb frame, to counter overlapping orbs
void orb_draw2d(entity this)
{
	if(time <= orb_drawtime)
		return;

	if(boxesoverlap(view_origin - '1 1 1', view_origin + '1 1 1', this.absmin, this.absmax))
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
	vector size = '.5 .5 .5' * e.orb_radius;
	setsize(e,-size,size);
	e.orb_radius = e.orb_radius/model_radius*0.6;

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
#endif

REGISTER_NET_LINKED(Nade_Orb)

#ifdef CSQC
NET_HANDLE(Nade_Orb, bool isNew)
{
	Net_Accept(Nade_Orb);
	int sf = ReadByte();
	if (sf & 1) {
		this.origin = ReadVector();
		setorigin(this, this.origin);
		this.colormod = ReadVector();
		this.orb_lifetime = ReadByte();
		this.orb_radius = ReadShort();
		this.ltime = time + ReadByte()/10.0;
		// this.ltime = time + this.orb_lifetime;
		orb_setup(this);
	}
	return true;
}
#endif

#ifdef SVQC
bool orb_send(entity this, entity to, int sf)
{
	int channel = MSG_ENTITY;
	WriteHeader(channel, Nade_Orb);
	WriteByte(channel, sf);
	if (sf & 1) {
		WriteVector(channel, this.origin);

		WriteVector(channel, this.colormod);

		WriteByte(channel, this.orb_lifetime);
		//WriteByte(MSG_ENTITY, this.ltime - time + 1);
		WriteShort(channel, this.orb_radius);
		// round time delta to a 1/10th of a second
		WriteByte(channel, (this.ltime - time)*10.0+0.5);
	}
	return true;
}
#endif

#endif
