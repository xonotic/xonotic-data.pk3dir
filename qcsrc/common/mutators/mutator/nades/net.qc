#include "nades.qh"

#ifdef IMPLEMENTATION

#ifdef CSQC
.float ltime;
void healer_draw(entity this)
{
	float dt = time - self.move_time;
	self.move_time = time;
	if(dt <= 0)
		return;

	self.alpha = (self.ltime - time) / self.healer_lifetime;
	self.scale = min((1 - self.alpha)*self.healer_lifetime*4,1)*self.healer_radius;
}

void healer_setup(entity e)
{
	setmodel(e, MDL_NADE_HEAL);

	setorigin(e, e.origin);

	float model_radius = e.maxs.x;
	vector size = '1 1 1' * e.healer_radius / 2;
	setsize(e,-size,size);
	e.healer_radius = e.healer_radius/model_radius*0.6;

	e.draw = healer_draw;
	e.health = 255;
	e.movetype = MOVETYPE_NONE;
	e.solid = SOLID_NOT;
	e.drawmask = MASK_NORMAL;
	e.scale = 0.01;
	e.avelocity = e.move_avelocity = '7 0 11';
	e.colormod = '1 0 0';
	e.renderflags |= RF_ADDITIVE;
}
#endif

REGISTER_NET_LINKED(Nade_Heal)

#ifdef CSQC
NET_HANDLE(Nade_Heal, bool isNew)
{
	Net_Accept(Nade_Heal);
	int sf = ReadByte();
	if (sf & 1) {
		this.origin_x = ReadCoord();
		this.origin_y = ReadCoord();
		this.origin_z = ReadCoord();
		setorigin(this, this.origin);
		this.healer_lifetime = ReadByte();
		this.healer_radius = ReadShort();
		this.ltime = time + ReadByte()/10.0;
		// this.ltime = time + this.healer_lifetime;
		healer_setup(this);
	}
	return true;
}
#endif

#ifdef SVQC
bool healer_send(entity this, entity to, int sf)
{
	int channel = MSG_ENTITY;
	WriteHeader(channel, Nade_Heal);
	WriteByte(channel, sf);
	if (sf & 1) {
		WriteCoord(channel, this.origin.x);
		WriteCoord(channel, this.origin.y);
		WriteCoord(channel, this.origin.z);

		WriteByte(channel, this.healer_lifetime);
		//WriteByte(MSG_ENTITY, this.ltime - time + 1);
		WriteShort(channel, this.healer_radius);
		// round time delta to a 1/10th of a second
		WriteByte(channel, (this.ltime - time)*10.0+0.5);
	}
	return true;
}
#endif

#endif
