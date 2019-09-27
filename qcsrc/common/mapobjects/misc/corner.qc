#include "corner.qh"
REGISTER_NET_LINKED(ENT_CLIENT_CORNER)

#ifdef SVQC
bool corner_send(entity this, entity to, int sf)
{
	WriteHeader(MSG_ENTITY, ENT_CLIENT_CORNER);

	WriteString(MSG_ENTITY, this.platmovetype);

	WriteVector(MSG_ENTITY, this.origin);

	sf = 0;
	sf = BITSET(sf, BIT(0), this.target_random);

	sf = BITSET(sf, BIT(1), this.target && this.target != "");
	sf = BITSET(sf, BIT(2), this.target2 && this.target2 != "");
	sf = BITSET(sf, BIT(3), this.target3 && this.target3 != "");
	sf = BITSET(sf, BIT(4), this.target4 && this.target4 != "");
	sf = BITSET(sf, BIT(5), this.targetname && this.targetname != "");

	WriteByte(MSG_ENTITY, sf);
	if(sf & BIT(1))
		WriteString(MSG_ENTITY, this.target);
	if(sf & BIT(2))
		WriteString(MSG_ENTITY, this.target2);
	if(sf & BIT(3))
		WriteString(MSG_ENTITY, this.target3);
	if(sf & BIT(4))
		WriteString(MSG_ENTITY, this.target4);
	if(sf & BIT(5))
		WriteString(MSG_ENTITY, this.targetname);

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
	strfree(this.target);
	strfree(this.target2);
	strfree(this.target3);
	strfree(this.target4);
	strfree(this.targetname);
	strfree(this.platmovetype);
}

NET_HANDLE(ENT_CLIENT_CORNER, bool isnew)
{
	this.platmovetype = strzone(ReadString());

	this.origin = ReadVector();
	setorigin(this, this.origin);

	int targbits = ReadByte();
	this.target_random = (targbits & BIT(0));

	this.target = ((targbits & BIT(1)) ? strzone(ReadString()) : string_null);
	this.target2 = ((targbits & BIT(2)) ? strzone(ReadString()) : string_null);
	this.target3 = ((targbits & BIT(3)) ? strzone(ReadString()) : string_null);
	this.target4 = ((targbits & BIT(4)) ? strzone(ReadString()) : string_null);
	this.targetname = ((targbits & BIT(5)) ? strzone(ReadString()) : string_null);

	this.wait = ReadByte();

	return = true;

	this.classname = "path_corner";
	this.drawmask = MASK_NORMAL;
	this.entremove = corner_remove;

	set_platmovetype(this, this.platmovetype);
}

#endif
