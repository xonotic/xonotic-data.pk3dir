#include "teleport_dest.qh"
REGISTER_NET_LINKED(ENT_CLIENT_TELEPORT_DEST)

#ifdef SVQC

bool teleport_dest_send(entity this, entity to, int sendflags)
{
	WriteHeader(MSG_ENTITY, ENT_CLIENT_TELEPORT_DEST);
	WriteByte(MSG_ENTITY, sendflags);

	if(sendflags & SF_TRIGGER_INIT)
	{
		WriteByte(MSG_ENTITY, this.cnt);
		WriteCoord(MSG_ENTITY, this.speed);
		WriteString(MSG_ENTITY, this.targetname);
		WriteVector(MSG_ENTITY, this.origin);
		WriteAngleVector(MSG_ENTITY, this.mangle);
	}

	return true;
}

void teleport_dest_link(entity this)
{
	Net_LinkEntity(this, false, 0, teleport_dest_send);
	this.SendFlags |= SF_TRIGGER_INIT;
}

spawnfunc(info_teleport_destination)
{
	this.mangle = this.angles;
	this.angles = '0 0 0';

	//setorigin(this, this.origin + '0 0 27');	// To fix a mappers' habit as old as Quake
	setorigin(this, this.origin);

	if(!this.targetname || this.targetname == "")
	{
		objerror (this, "^3Teleport destination without a targetname");
		return; // don't link it to CSQC in this case!
	}

	teleport_dest_link(this);
}

spawnfunc(misc_teleporter_dest)
{
	spawnfunc_info_teleport_destination(this);
}

#elif defined(CSQC)

void teleport_dest_remove(entity this)
{
    // strfree(this.classname);
    strfree(this.targetname);
}

NET_HANDLE(ENT_CLIENT_TELEPORT_DEST, bool isnew)
{
	int sendflags = ReadByte();

	if(sendflags & SF_TRIGGER_INIT)
	{
		this.classname = "info_teleport_destination";
		this.cnt = ReadByte();
		this.speed = ReadCoord();
		this.targetname = strzone(ReadString());
		this.origin = ReadVector();
		this.mangle = ReadAngleVector();

		setorigin(this, this.origin);

		this.drawmask = MASK_NORMAL;
		this.entremove = teleport_dest_remove;
	}

	return = true;
}

#endif
