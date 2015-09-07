#include "generator.qh"

bool generator_send(entity to, int sf)
{SELFPARAM();
	WriteByte(MSG_ENTITY, ENT_CLIENT_GENERATOR);
	WriteByte(MSG_ENTITY, sf);
	if(sf & GSF_SETUP)
	{
		WriteCoord(MSG_ENTITY, self.origin_x);
		WriteCoord(MSG_ENTITY, self.origin_y);
		WriteCoord(MSG_ENTITY, self.origin_z);

		WriteByte(MSG_ENTITY, self.health);
		WriteByte(MSG_ENTITY, self.max_health);
		WriteByte(MSG_ENTITY, self.count);
		WriteByte(MSG_ENTITY, self.team);
	}

	if(sf & GSF_STATUS)
	{
		WriteByte(MSG_ENTITY, self.team);

		if(self.health <= 0)
			WriteByte(MSG_ENTITY, 0);
		else
			WriteByte(MSG_ENTITY, ceil((self.health / self.max_health) * 255));
	}

	return true;
}

void generator_link(void() spawnproc)
{SELFPARAM();
	Net_LinkEntity(self, true, 0, generator_send);
	self.think		= spawnproc;
	self.nextthink	= time;
}
