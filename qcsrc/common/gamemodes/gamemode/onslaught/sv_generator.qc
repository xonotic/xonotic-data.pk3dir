#include "sv_generator.qh"

bool generator_send(entity this, entity to, int sf)
{
	WriteHeader(MSG_ENTITY, ENT_CLIENT_GENERATOR);
	WriteByte(MSG_ENTITY, sf);
	if(sf & GSF_SETUP)
	{
		WriteCoord(MSG_ENTITY, this.origin_x);
		WriteCoord(MSG_ENTITY, this.origin_y);
		WriteCoord(MSG_ENTITY, this.origin_z);

		WriteByte(MSG_ENTITY, this.health);
		WriteByte(MSG_ENTITY, this.max_health);
		WriteByte(MSG_ENTITY, this.count);
		WriteByte(MSG_ENTITY, this.team);
	}

	if(sf & GSF_STATUS)
	{
		WriteByte(MSG_ENTITY, this.team);

		if(this.health <= 0)
			WriteByte(MSG_ENTITY, 0);
		else
			WriteByte(MSG_ENTITY, ceil((this.health / this.max_health) * 255));
	}

	return true;
}
