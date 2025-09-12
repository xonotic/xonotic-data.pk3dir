#include "net.qh"

#ifdef GAMEQC

#include "nades.qh"

#ifdef CSQC
#include <client/view.qh>

void orb_draw(entity this)
{
	float age = time - (this.ltime - this.lifetime);
	float dt = time - this.update_time;
	this.update_time = time;

	if (dt > 0)
	{
		this.avelocity *= 24 ** (dt / this.orb_lifetime); // speed up, frametime independent
		this.angles += dt * this.avelocity;
	}
	if (age > 0)
	{
		this.scale = this.orb_radius * (age >= this.animstate_endtime
			? 1
			: (this.height * age * (age - this.animstate_endtime * 2))); // increases at decreasing pace up to .orb_radius, as age -> .animstate_endtime
		this.alpha = sqrt(1 - age / this.orb_lifetime); // slowly fade out
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

void orb_setup(entity orb)
{
	orb.update_time = time; // used to calculate dt
	orb.animstate_endtime = 0.25 * min(orb.orb_lifetime, 1); // when the orb will stop expanding
	orb.height = -4 * (2 * orb.animstate_endtime) ** -2; // amplitude used in scaling calculation

	setmodel(orb, MDL_NADE_ORB);
	orb.skin = 1;

	float model_radius = orb.maxs.x;
	vector size = '0.5 0.5 0.5' * orb.orb_radius;
	setsize(orb, -size, size);
	orb.orb_radius *= 0.6 / model_radius;

	orb.draw = orb_draw;
	orb.draw2d = orb_draw2d;
	IL_PUSH(g_drawables, orb);
	IL_PUSH(g_drawables_2d, orb);
	SetResourceExplicit(orb, RES_HEALTH, 255);
	set_movetype(orb, MOVETYPE_NONE);
	orb.solid = SOLID_NOT;
	orb.drawmask = MASK_NORMAL;
	orb.renderflags |= RF_ADDITIVE;
	orb.scale = 0.01;
	float spin_dir = 2*M_PI * random();
	orb.avelocity = '6 0 0' * sin(spin_dir) + '0 0 6' * cos(spin_dir);

	float age = time - (orb.ltime - orb.lifetime);
	if (age > 0)
		orb.avelocity *= 24 ** (age / orb.lifetime);
}
#endif // CSQC

REGISTER_NET_LINKED(Nade_Orb)

#ifdef CSQC
NET_HANDLE(Nade_Orb, bool isNew)
{
	Net_Accept(Nade_Orb);

	int sf = ReadByte();
	setorigin(this, ReadVector());
	this.colormod = ReadVector();
	this.ltime = ReadFloat();
	//this.ltime = time + ReadByte() / 10.0;
	this.orb_lifetime = (sf & SF_NADEORB_LIFETIME_FLOAT)
		? ReadFloat()
		: (ReadByte() + 1) * 0.125;
	this.orb_radius = (sf & SF_NADEORB_RADIUS_FLOAT)
		? ReadFloat()
		: (ReadByte() + 1) * 5;

	if (isNew)
		orb_setup(this);
	return true;
}
#endif // CSQC
#ifdef SVQC
bool orb_send(entity this, entity to, int sf)
{
	sf = 0;
	float byte_lifetime = this.orb_lifetime * 8 - 1; // range: 0.125..32 in increments of 0.125
	if (byte_lifetime < 0 || byte_lifetime >= BIT(8) || byte_lifetime != floor(byte_lifetime))
		sf |= SF_NADEORB_LIFETIME_FLOAT;
	float byte_radius = this.orb_radius * 0.2 - 1; // range: 5..1280 in increments of 5
	if (byte_radius < 0 || byte_radius >= BIT(8) || byte_radius != floor(byte_radius))
		sf |= SF_NADEORB_RADIUS_FLOAT;

	WriteHeader(MSG_ENTITY, Nade_Orb);
	WriteByte(MSG_ENTITY, sf);
	WriteVector(MSG_ENTITY, this.origin);
	WriteVector(MSG_ENTITY, this.colormod);
	WriteFloat(MSG_ENTITY, this.ltime);
	//WriteByte(MSG_ENTITY, (this.ltime - time) * 10.0 + 0.5); // round time delta to a 1/10th of a second
	if (sf & SF_NADEORB_LIFETIME_FLOAT)
		WriteFloat(MSG_ENTITY, this.orb_lifetime);
	else
		WriteByte(MSG_ENTITY, rint(byte_lifetime));
	if (sf & SF_NADEORB_RADIUS_FLOAT)
		WriteFloat(MSG_ENTITY, this.orb_radius);
	else
		WriteByte(MSG_ENTITY, rint(byte_radius));

	return true;
}
#endif // SVQC

#endif // GAMEQC
