#include "net.qh"

#ifdef GAMEQC

#include "nades.qh"

#ifdef CSQC
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

void orb_setup(entity e)
{
	setmodel(e, MDL_NADE_ORB);
	e.skin = 1;

	setorigin(e, e.origin);

	float model_radius = e.maxs.x;
	vector size = '1 1 1' * e.orb_radius / 2;
	setsize(e,-size,size);
	e.orb_radius = e.orb_radius/model_radius*0.6;

	e.draw = orb_draw;
	IL_PUSH(g_drawables, e);
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
