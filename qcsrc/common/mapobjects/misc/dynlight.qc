#include "dynlight.qh"

#ifdef SVQC
#include <common/weapons/_all.qh>
#include <common/stats.qh>

const float LOOP = 1;

.float speed;

//const int DNOSHADOW = 2;
const int DFOLLOW = 4;
.float light_lev;
.float lefty;
.vector color;
.string dtagname;

/*QUAKED dynlight (0 1 0) (-8 -8 -8) (8 8 8) START_OFF NOSHADOW FOLLOW
Dynamic spawnfunc_light.
Can do one of these things: sit still and be just a silly spawnfunc_light, travel along a path, follow an entity around, attach to a tag on an entity.
It can spin around it's own axis in all the above cases.
If targeted, it will toggle between on or off.
keys:
"light_lev" spawnfunc_light radius, default 200
"color" spawnfunc_light color in rgb and brightness, 1 1 1 produces bright white, up to 255 255 255 (nuclear blast), recommended values up to 1 1 1, default 1 1 1
"style" lightstyle, same as for static lights
"angles" initial orientation
"avelocity" a vector value, the direction and speed it rotates in
"skin" cubemap number, must be 16 or above
"dtagname" will attach to this tag on the entity which "targetname" matches "target". If the "target" is either not an md3 model or is missing tags, it will attach to the targets origin. Note that the "target" must be visible to the spawnfunc_light
"targetname" will toggle on and off when triggered
"target" if issued with a target, preferrably spawnfunc_path_corner, it will move along the path. If also issued with the FOLLOW spawnflag, then this is the entity it will follow. If issued with the "tagname" key it will attach it to this targets tag called "tagname", does not work together with FOLLOW or path movement
"speed" the speed it will travel along the path, default 100
flags:
"START_OFF" spawnfunc_light will be in off state until targeted
"NOSHADOW" will not cast shadows in realtime lighting mode
"FOLLOW" will follow the entity which "targetname" matches "target"
*/
void dynlight_think(entity this)
{
	if(!this.owner)
		delete(this);

	this.nextthink = time + 0.1;
}
void dynlight_find_aiment(entity this)
{
	entity targ;
	if (!this.target || this.target == "")
		objerror (this, "dynlight: no target to follow");

	targ = find(NULL, targetname, this.target);
	set_movetype(this, MOVETYPE_FOLLOW);
	this.aiment = targ;
	this.owner = targ;
	this.punchangle = targ.angles;
	this.view_ofs = this.origin - targ.origin;
	this.v_angle = this.angles - targ.angles;
	setthink(this, dynlight_think);
	this.nextthink = time + 0.1;
}
void dynlight_find_path(entity this)
{
	entity targ;
	if (!this.target || this.target == "")
		objerror (this, "dynlight: no target to follow");

	targ = find(NULL, targetname, this.target);
	this.target = targ.target;
	setorigin(this, targ.origin);
	setthink(this, train_next); // TODO: reliant on the train's pathing functions
	this.nextthink = time + 0.1;
}
void dynlight_find_target(entity this)
{
	entity targ;
	if (!this.target || this.target == "")
		objerror (this, "dynlight: no target to follow");

	targ = find(NULL, targetname, this.target);
	setattachment(this, targ, this.dtagname);
	this.owner = targ;
	setthink(this, dynlight_think);
	this.nextthink = time + 0.1;
}
void dynlight_use(entity this, entity actor, entity trigger)
{
	if(this.active != ACTIVE_ACTIVE)
		return;
	if (this.light_lev == 0)
		this.light_lev = this.lefty;
	else
		this.light_lev = 0;
}
void dynlight_setactive(entity this, int act)
{
	int old_status = this.active;
	if(act == ACTIVE_TOGGLE)
		this.active = (this.active == ACTIVE_ACTIVE) ? ACTIVE_NOT : ACTIVE_ACTIVE;
	else
		this.active = act;

	if(this.active != old_status)
		this.light_lev = (this.active == ACTIVE_ACTIVE) ? this.lefty : 0;
}
void dynlight_reset(entity this)
{
	// TODO should anything else be reset here?
	this.active = ACTIVE_ACTIVE;
	this.light_lev = this.lefty;
}
spawnfunc(dynlight)
{
	if (!this.light_lev)
		this.light_lev = 200;
	if (!this.color)
		this.color = '1 1 1';
	this.lefty = this.light_lev;
	this.use = dynlight_use;
	this.active = ACTIVE_ACTIVE;
	this.setactive = dynlight_setactive;
	this.reset = dynlight_reset;
	setsize (this, '0 0 0', '0 0 0');
	setorigin(this, this.origin);
	//this.pflags = PFLAGS_FULLDYNAMIC;
	this.solid = SOLID_NOT;
	//this.blocked = func_null;
	//if (this.spawnflags & DNOSHADOW)
	//	this.pflags = this.pflags + PFLAGS_NOSHADOW;
	//if (this.spawnflags & START_OFF)
	//	this.light_lev = 0;

//tag attaching
	if (this.dtagname)
	{
		InitializeEntity(this, dynlight_find_target, INITPRIO_FINDTARGET);
		return;
	}

// entity following
	if (this.spawnflags & DFOLLOW)
	{
		InitializeEntity(this, dynlight_find_aiment, INITPRIO_FINDTARGET);
		return;
	}
// path following
	if (this.target)
//	if (!(this.spawnflags & DFOLLOW))
	{
		set_movetype(this, MOVETYPE_NOCLIP);
		if (!this.speed)
			this.speed = 100;
		InitializeEntity(this, dynlight_find_path, INITPRIO_FINDTARGET);
		return;
	}
}
#endif
