#include "_all.qh"

#include "../common/util.qh"

float Casing_SendEntity(entity to, int sf)
{
	WriteByte(MSG_ENTITY, ENT_CLIENT_CASING);
	WriteByte(MSG_ENTITY, self.state); // actually type
	WriteCoord(MSG_ENTITY, self.origin.x);
	WriteCoord(MSG_ENTITY, self.origin.y);
	WriteCoord(MSG_ENTITY, self.origin.z);
	WriteShort(MSG_ENTITY, self.oldorigin.x); // acrually compressed velocity
	WriteByte(MSG_ENTITY, self.angles.x * 256 / 360);
	WriteByte(MSG_ENTITY, self.angles.y * 256 / 360);
	WriteByte(MSG_ENTITY, self.angles.z * 256 / 360);
	return true;
}

void SpawnCasing(vector vel, float randomvel, vector ang, vector avel, float randomavel, int casingtype, entity casingowner)
{
	entity e;
	vector org;

	org = self.origin + self.view_ofs + self.weaponentity.spawnorigin.x * v_forward - self.weaponentity.spawnorigin.y * v_right + self.weaponentity.spawnorigin.z * v_up;

	if(!sound_allowed(MSG_BROADCAST, casingowner))
		casingtype |= 0x80;

	e = spawn();
	e.state = casingtype;
	setorigin(e, org);
	e.velocity = vel;
	e.angles = ang;
	e.oldorigin_x = compressShortVector(e.velocity);

	Net_LinkEntity(e, true, 0.2, Casing_SendEntity);
		// 0.2s should be enough time for all clients to receive this ent once, do the gibbage and be done with it
}
