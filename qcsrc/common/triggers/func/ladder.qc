#include "ladder.qh"
REGISTER_NET_LINKED(ENT_CLIENT_LADDER)

void func_ladder_touch(entity this, entity toucher)
{
#ifdef SVQC
	if (!toucher.iscreature)
		return;
	if(IS_VEHICLE(toucher))
		return;
#elif defined(CSQC)
	if(!toucher.isplayermodel)
		return;
#endif

	EXACTTRIGGER_TOUCH(this, toucher);

	toucher.ladder_time = time + 0.1;
	toucher.ladder_entity = this;
}

#ifdef SVQC
bool func_ladder_send(entity this, entity to, int sf)
{
	WriteHeader(MSG_ENTITY, ENT_CLIENT_LADDER);

	WriteString(MSG_ENTITY, this.classname);
	WriteByte(MSG_ENTITY, this.skin);
	WriteCoord(MSG_ENTITY, this.speed);

	trigger_common_write(this, false);

	return true;
}

void func_ladder_link(entity this)
{
	trigger_link(this, func_ladder_send);
	//this.model = "null";
}

void func_ladder_init(entity this)
{
	settouch(this, func_ladder_touch);

	trigger_init(this);
	func_ladder_link(this);
}

spawnfunc(func_ladder)
{
	func_ladder_init(this);
}

spawnfunc(func_water)
{
	func_ladder_init(this);
}

#elif defined(CSQC)
.float speed;

void func_ladder_remove(entity this)
{
	if(this.classname) { strunzone(this.classname); }
	this.classname = string_null;
}

NET_HANDLE(ENT_CLIENT_LADDER, bool isnew)
{
	this.classname = strzone(ReadString());
	this.skin = ReadByte();
	this.speed = ReadCoord();

	trigger_common_read(this, false);

	this.solid = SOLID_TRIGGER;
	settouch(this, func_ladder_touch);
	this.drawmask = MASK_NORMAL;
	this.move_time = time;
	this.entremove = func_ladder_remove;

	return true;
}
#endif
