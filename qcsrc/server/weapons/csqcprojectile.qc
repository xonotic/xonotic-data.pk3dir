#include "csqcprojectile.qh"
#include "../_all.qh"

#include "../t_items.qh"

#include "../command/common.qh"

#include "../../common/constants.qh"
#include "../../common/weapons/weapons.qh"

.float csqcprojectile_type;

bool CSQCProjectile_SendEntity(entity to, int sf)
{
	float ft, fr;

	// note: flag 0x08 = no trail please (teleport bit)
	sf = sf & 0x0F;

	if(self.csqcprojectile_clientanimate)
		sf |= 0x80; // client animated, not interpolated

	if(self.flags & FL_ONGROUND)
		sf |= 0x40;

	ft = fr = 0;
	if(self.fade_time != 0 || self.fade_rate != 0)
	{
		ft = (self.fade_time - time) / sys_frametime;
		fr = (1 / self.fade_rate) / sys_frametime;
		if(ft <= 255 && fr <= 255 && fr >= 1)
			sf |= 0x20;
	}

	if(self.gravity != 0)
		sf |= 0x10;

	WriteByte(MSG_ENTITY, ENT_CLIENT_PROJECTILE);
	WriteByte(MSG_ENTITY, sf);

	if(sf & 1)
	{
		WriteCoord(MSG_ENTITY, self.origin.x);
		WriteCoord(MSG_ENTITY, self.origin.y);
		WriteCoord(MSG_ENTITY, self.origin.z);

		if(sf & 0x80)
		{
			WriteCoord(MSG_ENTITY, self.velocity.x);
			WriteCoord(MSG_ENTITY, self.velocity.y);
			WriteCoord(MSG_ENTITY, self.velocity.z);
			if(sf & 0x10)
				WriteCoord(MSG_ENTITY, self.gravity);
		}

		if(sf & 0x20)
		{
			WriteByte(MSG_ENTITY, ft);
			WriteByte(MSG_ENTITY, fr);
		}

		WriteByte(MSG_ENTITY, self.realowner.team);
	}

	if(sf & 2)
		WriteByte(MSG_ENTITY, self.csqcprojectile_type); // TODO maybe put this into sf?

	return true;
}

.vector csqcprojectile_oldorigin;
void CSQCProjectile_Check(entity e)
{
	if(e.csqcprojectile_clientanimate)
	if(e.flags & FL_ONGROUND)
	if(e.origin != e.csqcprojectile_oldorigin)
		UpdateCSQCProjectile(e);
	e.csqcprojectile_oldorigin = e.origin;
}

void CSQCProjectile(entity e, float clientanimate, int type, float docull)
{
	Net_LinkEntity(e, docull, 0, CSQCProjectile_SendEntity);

	e.csqcprojectile_clientanimate = clientanimate;

	if(e.movetype == MOVETYPE_TOSS || e.movetype == MOVETYPE_BOUNCE)
	{
		if(e.gravity == 0)
			e.gravity = 1;
	}
	else
		e.gravity = 0;

	if(!sound_allowed(MSG_BROADCAST, e))
		type |= 0x80;
	e.csqcprojectile_type = type;
}

void UpdateCSQCProjectile(entity e)
{
	if(e.SendEntity == CSQCProjectile_SendEntity)
	{
		// send new origin data
		e.SendFlags |= 0x01;
	}
// FIXME HACK
	else if(e.SendEntity == ItemSend)
	{
		ItemUpdate(e);
	}
// END HACK
}

void UpdateCSQCProjectileAfterTeleport(entity e)
{
	if(e.SendEntity == CSQCProjectile_SendEntity)
	{
		// send new origin data
		e.SendFlags |= 0x01;
		// mark as teleported
		e.SendFlags |= 0x08;
	}
}
