#include "teleport_dest.qh"
REGISTER_NET_LINKED(ENT_CLIENT_TELEPORT_DEST)

#ifdef SVQC

bool teleport_dest_send(entity this, entity to, int sf)
{
	WriteHeader(MSG_ENTITY, ENT_CLIENT_TELEPORT_DEST);
	WriteByte(MSG_ENTITY, sf);

	if(sf & 1)
	{
		WriteByte(MSG_ENTITY, this.cnt);
		WriteCoord(MSG_ENTITY, this.speed);
		WriteString(MSG_ENTITY, this.targetname);
		WriteCoord(MSG_ENTITY, this.origin_x);
		WriteCoord(MSG_ENTITY, this.origin_y);
		WriteCoord(MSG_ENTITY, this.origin_z);

		WriteAngle(MSG_ENTITY, this.mangle_x);
		WriteAngle(MSG_ENTITY, this.mangle_y);
		WriteAngle(MSG_ENTITY, this.mangle_z);
	}

	return true;
}

void teleport_dest_link(entity this)
{
	Net_LinkEntity(this, false, 0, teleport_dest_send);
	this.SendFlags |= 1; // update
}

spawnfunc(info_teleport_destination)
{
	this.classname = "info_teleport_destination";

	this.mangle = this.angles;
	this.angles = '0 0 0';

	//setorigin(this, this.origin + '0 0 27');	// To fix a mappers' habit as old as Quake
	setorigin(this, this.origin);

	IFTARGETED
	{
	}
	else
		objerror (this, "^3Teleport destination without a targetname");

	teleport_dest_link(this);
}

spawnfunc(misc_teleporter_dest)
{
	spawnfunc_info_teleport_destination(this);
}

spawnfunc(target_teleporter)
{
	spawnfunc_info_teleport_destination(this);
}

#elif defined(CSQC)

void teleport_dest_remove(entity this)
{
	//if(this.classname)
		//strunzone(this.classname);
	//this.classname = string_null;

	if(this.targetname)
		strunzone(this.targetname);
	this.targetname = string_null;
}

NET_HANDLE(ENT_CLIENT_TELEPORT_DEST, bool isnew)
{
	int sf = ReadByte();

	if(sf & 1)
	{
		this.classname = "info_teleport_destination";
		this.cnt = ReadByte();
		this.speed = ReadCoord();
		this.targetname = strzone(ReadString());
		this.origin_x = ReadCoord();
		this.origin_y = ReadCoord();
		this.origin_z = ReadCoord();

		this.mangle_x = ReadAngle();
		this.mangle_y = ReadAngle();
		this.mangle_z = ReadAngle();

		setorigin(this, this.origin);

		this.drawmask = MASK_NORMAL;
		this.entremove = teleport_dest_remove;
	}

	return = true;
}

#endif
