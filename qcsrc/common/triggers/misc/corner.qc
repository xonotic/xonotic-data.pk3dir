#include "corner.qh"
REGISTER_NET_LINKED(ENT_CLIENT_CORNER)

#ifdef SVQC
bool corner_send(entity this, entity to, int sf)
{
	WriteHeader(MSG_ENTITY, ENT_CLIENT_CORNER);

	WriteString(MSG_ENTITY, this.platmovetype);

	WriteCoord(MSG_ENTITY, this.origin_x);
	WriteCoord(MSG_ENTITY, this.origin_y);
	WriteCoord(MSG_ENTITY, this.origin_z);

	WriteString(MSG_ENTITY, this.target);
	WriteString(MSG_ENTITY, this.target2);
	WriteString(MSG_ENTITY, this.target3);
	WriteString(MSG_ENTITY, this.target4);
	WriteString(MSG_ENTITY, this.targetname);
	WriteByte(MSG_ENTITY, this.target_random);

	WriteByte(MSG_ENTITY, this.wait);

	return true;
}

void corner_link(entity this)
{
	//Net_LinkEntity(this, false, 0, corner_send);
}

spawnfunc(path_corner)
{
	// setup values for overriding train movement
	// if a second value does not exist, both start and end speeds are the single value specified
	set_platmovetype(this, this.platmovetype);

	corner_link(this);
}
#elif defined(CSQC)

void corner_remove(entity this)
{
	if(this.target) { strunzone(this.target); }
	this.target = string_null;

	if(this.target2) { strunzone(this.target2); }
	this.target2 = string_null;

	if(this.target3) { strunzone(this.target3); }
	this.target3 = string_null;

	if(this.target4) { strunzone(this.target4); }
	this.target4 = string_null;

	if(this.targetname) { strunzone(this.targetname); }
	this.targetname = string_null;

	if(this.platmovetype) { strunzone(this.platmovetype); }
	this.platmovetype = string_null;
}

NET_HANDLE(ENT_CLIENT_CORNER, bool isnew)
{
	this.platmovetype = strzone(ReadString());

	this.origin_x = ReadCoord();
	this.origin_y = ReadCoord();
	this.origin_z = ReadCoord();
	setorigin(this, this.origin);

	this.target = strzone(ReadString());
	this.target2 = strzone(ReadString());
	this.target3 = strzone(ReadString());
	this.target4 = strzone(ReadString());
	this.targetname = strzone(ReadString());
	this.target_random = ReadByte();

	this.wait = ReadByte();

	return = true;

	this.classname = "path_corner";
	this.drawmask = MASK_NORMAL;
	this.entremove = corner_remove;

	set_platmovetype(this, this.platmovetype);
}

#endif
