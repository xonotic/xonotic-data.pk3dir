#include "sv_generator.qh"

bool generator_send(entity this, entity to, int sf)
{
	WriteHeader(MSG_ENTITY, ENT_CLIENT_GENERATOR);
	WriteByte(MSG_ENTITY, sf);
	if(sf & GSF_SETUP)
	{
		WriteVector(MSG_ENTITY, this.origin);

		WriteByte(MSG_ENTITY, GetResource(this, RES_HEALTH));
		WriteByte(MSG_ENTITY, this.max_health);
		WriteByte(MSG_ENTITY, this.count);
		WriteByte(MSG_ENTITY, this.team);
	}

	if(sf & GSF_STATUS)
	{
		WriteByte(MSG_ENTITY, this.team);

		if(GetResource(this, RES_HEALTH) <= 0)
			WriteByte(MSG_ENTITY, 0);
		else
			WriteByte(MSG_ENTITY, ceil((GetResource(this, RES_HEALTH) / this.max_health) * 255));
	}

	return true;
}
