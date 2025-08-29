#include "sv_controlpoint.qh"

.bool iscaptured;

bool cpicon_send(entity this, entity to, int sf)
{
	WriteHeader(MSG_ENTITY, ENT_CLIENT_CONTROLPOINT_ICON);
	if(sf & CPSF_SETUP)
		sf &= ~CPSF_STATUS;
	WriteByte(MSG_ENTITY, sf);
	if(sf & CPSF_SETUP)
	{
		WriteVector(MSG_ENTITY, this.origin);

		WriteByte(MSG_ENTITY, GetResource(this, RES_HEALTH));
		WriteByte(MSG_ENTITY, this.max_health);
		WriteByte(MSG_ENTITY, this.count);
		WriteByte(MSG_ENTITY, this.team);
		WriteByte(MSG_ENTITY, this.owner.iscaptured);
	}

	if(sf & CPSF_STATUS)
	{
		WriteByte(MSG_ENTITY, this.team);

		if(GetResource(this, RES_HEALTH) <= 0)
			WriteByte(MSG_ENTITY, 0);
		else
			WriteByte(MSG_ENTITY, ceil((GetResource(this, RES_HEALTH) / this.max_health) * 255));
	}

	return true;
}

void onslaught_controlpoint_icon_link(entity e, void(entity this) spawnproc)
{
	Net_LinkEntity(e, true, 0, cpicon_send);
	setthink(e, spawnproc);
	e.nextthink	= time + sys_frametime;
}
