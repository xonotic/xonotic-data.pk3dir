#include "rainsnow.qh"
REGISTER_NET_LINKED(ENT_CLIENT_RAINSNOW)

#ifdef SVQC
bool rainsnow_SendEntity(entity this, entity to, float sf)
{
	vector myorg = this.origin + this.mins;
	vector mysize = this.maxs - this.mins;
	WriteHeader(MSG_ENTITY, ENT_CLIENT_RAINSNOW);
	WriteByte(MSG_ENTITY, this.state);
	WriteVector(MSG_ENTITY, myorg);
	WriteVector(MSG_ENTITY, mysize);
	WriteShort(MSG_ENTITY, compressShortVector(this.dest));
	WriteShort(MSG_ENTITY, this.count);
	WriteByte(MSG_ENTITY, this.cnt);
	return true;
}

/*QUAKED spawnfunc_func_rain (0 .5 .8) ?
This is an invisible area like a trigger, which rain falls inside of.

Keys:
"velocity"
 falling direction (should be something like '0 0 -700', use the X and Y velocity for wind)
"cnt"
 sets color of rain (default 12 - white)
"count"
 adjusts density, this many particles fall every second for a 1024x1024 area, default is 2000
*/
spawnfunc(func_rain)
{
	this.dest = this.velocity;
	this.velocity = '0 0 0';
	if (!this.dest)
		this.dest = '0 0 -700';
	this.angles = '0 0 0';
	set_movetype(this, MOVETYPE_NONE);
	this.solid = SOLID_NOT;
	SetBrushEntityModel(this, true);
	if (!this.cnt)
	{
		this.cnt = 12;
	}
	if (!this.count)
		this.count = 2000;
	// relative to absolute particle count
	this.count = 0.1 * this.count * (this.size_x / 1024) * (this.size_y / 1024);
	if (this.count < 1)
		this.count = 1;
	if(this.count > 65535)
		this.count = 65535;

	this.state = RAINSNOW_RAIN;

	Net_LinkEntity(this, false, 0, rainsnow_SendEntity);
}


/*QUAKED spawnfunc_func_snow (0 .5 .8) ?
This is an invisible area like a trigger, which snow falls inside of.

Keys:
"velocity"
 falling direction (should be something like '0 0 -300', use the X and Y velocity for wind)
"cnt"
 sets color of rain (default 12 - white)
"count"
 adjusts density, this many particles fall every second for a 1024x1024 area, default is 2000
*/
spawnfunc(func_snow)
{
	this.dest = this.velocity;
	this.velocity = '0 0 0';
	if (!this.dest)
		this.dest = '0 0 -300';
	this.angles = '0 0 0';
	set_movetype(this, MOVETYPE_NONE);
	this.solid = SOLID_NOT;
	SetBrushEntityModel(this, true);
	if (!this.cnt)
	{
		this.cnt = 12;
	}
	if (!this.count)
		this.count = 2000;
	// relative to absolute particle count
	this.count = 0.1 * this.count * (this.size_x / 1024) * (this.size_y / 1024);
	if (this.count < 1)
		this.count = 1;
	if(this.count > 65535)
		this.count = 65535;

	this.state = RAINSNOW_SNOW;

	Net_LinkEntity(this, false, 0, rainsnow_SendEntity);
}
#elif defined(CSQC)
float autocvar_cl_rainsnow_maxdrawdist = 2048;

void Draw_Rain(entity this)
{
	vector maxdist = '1 1 0' * autocvar_cl_rainsnow_maxdrawdist;
	maxdist.z = 5;
	if(boxesoverlap(vec2(view_origin) - maxdist, vec2(view_origin) + maxdist, vec2(this.absmin) - '0 0 5', vec2(this.absmax) + '0 0 5'))
	//if(autocvar_cl_rainsnow_maxdrawdist <= 0 || vdist(vec2(this.origin) - vec2(this.absmin + this.absmax * 0.5), <=, autocvar_cl_rainsnow_maxdrawdist))
    	te_particlerain(this.origin + this.mins, this.origin + this.maxs, this.velocity, floor(this.count * drawframetime + random()), this.glow_color);
}

void Draw_Snow(entity this)
{
	vector maxdist = '1 1 0' * autocvar_cl_rainsnow_maxdrawdist;
	maxdist.z = 5;
	if(boxesoverlap(vec2(view_origin) - maxdist, vec2(view_origin) + maxdist, vec2(this.absmin) - '0 0 5', vec2(this.absmax) + '0 0 5'))
	//if(autocvar_cl_rainsnow_maxdrawdist <= 0 || vdist(vec2(this.origin) - vec2(this.absmin + this.absmax * 0.5), <=, autocvar_cl_rainsnow_maxdrawdist))
    	te_particlesnow(this.origin + this.mins, this.origin + this.maxs, this.velocity, floor(this.count * drawframetime + random()), this.glow_color);
}

NET_HANDLE(ENT_CLIENT_RAINSNOW, bool isnew)
{
	this.state = ReadByte(); // Rain, Snow, or Whatever
	this.origin = ReadVector();
	this.maxs = ReadVector();
	this.velocity = decompressShortVector(ReadShort());
	this.count = ReadShort();
	this.glow_color = ReadByte(); // color

	return = true;

	this.mins    = -0.5 * this.maxs;
	this.maxs    =  0.5 * this.maxs;
	this.origin  = this.origin - this.mins;

	setorigin(this, this.origin);
	setsize(this, this.mins, this.maxs);
	this.solid = SOLID_NOT;
	if (isnew) IL_PUSH(g_drawables, this);
	if(this.state == RAINSNOW_RAIN)
		this.draw = Draw_Rain;
	else
		this.draw = Draw_Snow;
}
#endif
