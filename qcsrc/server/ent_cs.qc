#include "ent_cs.qh"

#include "mutators/gamemode_ca.qh"

float entcs_customize()
{
	SELFPARAM();
	entity o = self.owner;
	if(o.deadflag != DEAD_NO)
		return false;
	if (!IS_PLAYER(o))
		return false;
	if(other == o)
		return false;
	if((IS_PLAYER(other)) || other.caplayer)
		if(!teamplay || o.team != other.team)
			if (!radar_showennemies)
				return false;
	return true;
}

bool entcs_send(entity this, entity to, int sf)
{
	WriteByte(MSG_ENTITY, ENT_CLIENT_ENTCS);
	WriteByte(MSG_ENTITY, sf);
	if(sf & BIT(0))
		WriteByte(MSG_ENTITY, num_for_edict(self.owner) - 1);
	if(sf & BIT(1))
	{
		WriteShort(MSG_ENTITY, self.origin.x);
		WriteShort(MSG_ENTITY, self.origin.y);
		WriteShort(MSG_ENTITY, self.origin.z);
	}
	if(sf & BIT(2))
		WriteByte(MSG_ENTITY, self.angles.y * 256.0 / 360);
	if(sf & BIT(3))
		WriteByte(MSG_ENTITY, self.health / 10); // FIXME use a better scale?
	if(sf & BIT(4))
		WriteByte(MSG_ENTITY, self.armorvalue / 10); // FIXME use a better scale?
	return true;
}

void entcs_think()
{
	SELFPARAM();
	self.nextthink = time + 0.033333333333; // increase this to like 0.15 once the client can do smoothing
	entity o = self.owner;
	if (o.origin != self.origin)
	{
		setorigin(self, o.origin);
		self.SendFlags |= BIT(1);
	}
	if (o.angles.y != self.angles.y)
	{
		self.angles = o.angles;
		self.SendFlags |= BIT(2);
	}
	if (o.health != self.health)
	{
		self.health = o.health;
		self.SendFlags |= BIT(3);
	}
	if (o.armorvalue != self.armorvalue)
	{
		self.armorvalue = o.armorvalue;
		self.SendFlags |= BIT(4);
	}
}

entity attach_entcs(entity e)
{
	entity ent = e.entcs = new(entcs_sender);
	ent.owner = e;
	ent.think = entcs_think;
	ent.nextthink = time;

	Net_LinkEntity(ent, false, 0, entcs_send);
	ent.customizeentityforclient = entcs_customize;

	return ent;
}

void detach_entcs(entity e)
{
	if (!e.entcs) return;
	remove(e.entcs);
	e.entcs = NULL;
}
