#include "subs.qh"

void SUB_NullThink(entity this) { }

void SUB_CalcMoveDone(entity this);
void SUB_CalcAngleMoveDone(entity this);

#ifdef SVQC
spawnfunc(info_null)
{
	delete(this);
	// if anything breaks, tell the mapper to fix their map! info_null is meant to remove itself immediately.
}
#endif

/*
==================
SUB_Friction

Applies some friction to this
==================
*/
.float friction;
void SUB_Friction (entity this)
{
	this.nextthink = time;
	if(IS_ONGROUND(this))
		this.velocity = this.velocity * (1 - frametime * this.friction);
}

/*
==================
SUB_VanishOrRemove

Makes client invisible or removes non-client
==================
*/
void SUB_VanishOrRemove (entity ent)
{
	if (IS_CLIENT(ent))
	{
		// vanish
		ent.alpha = -1;
		ent.effects = 0;
#ifdef SVQC
		ent.glow_size = 0;
		ent.pflags = 0;
#endif
	}
	else
	{
		// remove
		delete(ent);
	}
}

void SUB_SetFade_Think (entity this)
{
	if(this.alpha == 0)
		this.alpha = 1;
	setthink(this, SUB_SetFade_Think);
	this.nextthink = time;
	this.alpha -= frametime * this.fade_rate;
	if (this.alpha < 0.01)
		SUB_VanishOrRemove(this);
	else
		this.nextthink = time;
}

/*
==================
SUB_SetFade

Fade ent out when time >= vanish_time
==================
*/
void SUB_SetFade(entity ent, float vanish_time, float fading_time)
{
	if (fading_time <= 0)
		fading_time = 0.01;
	ent.fade_rate = 1/fading_time;
	setthink(ent, SUB_SetFade_Think);
	ent.nextthink = vanish_time;
}

/*
=============
SUB_CalcMove

calculate this.velocity and this.nextthink to reach dest from
this.origin traveling at speed
===============
*/
void SUB_CalcMoveDone(entity this)
{
	// After moving, set origin to exact final destination

	setorigin (this, this.finaldest);
	this.velocity = '0 0 0';
	this.nextthink = -1;
	if (this.think1 && this.think1 != SUB_CalcMoveDone)
		this.think1 (this);
}

void SUB_CalcMovePause(entity this)
{
	if (!this.move_controller)
		return;
	this.move_controller.animstate_starttime += frametime;
	this.move_controller.animstate_endtime += frametime;
}

.float platmovetype_turn;
void SUB_CalcMove_controller_think (entity this)
{
	float traveltime;
	float phasepos;
	float nexttick;
	vector delta;
	vector delta2;
	vector veloc;
	vector angloc;
	vector nextpos;
	delta = this.destvec;
	delta2 = this.destvec2;
	if(time < this.animstate_endtime)
	{
		nexttick = time + PHYS_INPUT_FRAMETIME;

		traveltime = this.animstate_endtime - this.animstate_starttime;
		phasepos = (nexttick - this.animstate_starttime) / traveltime; // range: [0, 1]
		phasepos = cubic_speedfunc(this.platmovetype_start, this.platmovetype_end, phasepos);
		nextpos = this.origin + (delta * phasepos) + (delta2 * phasepos * phasepos);
		// derivative: delta + 2 * delta2 * phasepos (e.g. for angle positioning)

		if(this.owner.platmovetype_turn)
		{
			vector destangle;
			destangle = delta + 2 * delta2 * phasepos;
			destangle = vectoangles(destangle);
			destangle_x = -destangle_x; // flip up / down orientation

			// take the shortest distance for the angles
			vector v = this.owner.angles;
			v.x -= 360 * floor((v.x - destangle_x) / 360 + 0.5);
			v.y -= 360 * floor((v.y - destangle_y) / 360 + 0.5);
			v.z -= 360 * floor((v.z - destangle_z) / 360 + 0.5);
			this.owner.angles = v;
			angloc = destangle - this.owner.angles;
			angloc = angloc * (1 / PHYS_INPUT_FRAMETIME); // so it arrives for the next frame
			this.owner.avelocity = angloc;
		}
		if(nexttick < this.animstate_endtime)
			veloc = nextpos - this.owner.origin;
		else
			veloc = this.finaldest - this.owner.origin;
		veloc = veloc * (1 / PHYS_INPUT_FRAMETIME); // so it arrives for the next frame

		this.owner.velocity = veloc;
		this.nextthink = nexttick;
	}
	else
	{
		// derivative: delta + 2 * delta2 (e.g. for angle positioning)
		entity own = this.owner;
		setthink(own, this.think1);
		// set the owner's reference to this entity to NULL
		own.move_controller = NULL;
		delete(this);
		getthink(own)(own);
	}
}

void SUB_CalcMove_controller_setbezier (entity controller, vector org, vector control, vector destin)
{
	// 0 * (1-t) * (1-t) + 2 * control * t * (1-t) + destin * t * t
	// 2 * control * t - 2 * control * t * t + destin * t * t
	// 2 * control * t + (destin - 2 * control) * t * t

	//setorigin(controller, org); // don't link to the world
	controller.origin = org;
	control -= org;
	destin -= org;

	controller.destvec = 2 * control; // control point
	controller.destvec2 = destin - 2 * control; // quadratic part required to reach end point
	// also: initial d/dphasepos origin = 2 * control, final speed = 2 * (destin - control)
}

void SUB_CalcMove_controller_setlinear (entity controller, vector org, vector destin)
{
	// 0 * (1-t) * (1-t) + 2 * control * t * (1-t) + destin * t * t
	// 2 * control * t - 2 * control * t * t + destin * t * t
	// 2 * control * t + (destin - 2 * control) * t * t

	//setorigin(controller, org); // don't link to the world
	controller.origin = org;
	destin -= org;

	controller.destvec = destin; // end point
	controller.destvec2 = '0 0 0';
}

void SUB_CalcMove_Bezier (entity this, vector tcontrol, vector tdest, float tspeedtype, float tspeed, void(entity this) func)
{
	float	traveltime;
	entity controller;

	if (!tspeed)
		objerror (this, "No speed is defined!");

	this.think1 = func;
	this.finaldest = tdest;
	setthink(this, SUB_CalcMoveDone);

	switch(tspeedtype)
	{
		default:
		case TSPEED_START:
			traveltime = 2 * vlen(tcontrol - this.origin) / tspeed;
			break;
		case TSPEED_END:
			traveltime = 2 * vlen(tcontrol - tdest)       / tspeed;
			break;
		case TSPEED_LINEAR:
			traveltime = vlen(tdest - this.origin)        / tspeed;
			break;
		case TSPEED_TIME:
			traveltime = tspeed;
			break;
	}

	if (traveltime < 0.1) // useless anim
	{
		this.velocity = '0 0 0';
		this.nextthink = this.ltime + 0.1;
		return;
	}

	// delete the previous controller, otherwise changing movement midway is glitchy
	if (this.move_controller != NULL)
	{
		delete(this.move_controller);
	}
	controller = new_pure(SUB_CalcMove_controller);
	set_movetype(controller, MOVETYPE_NONE); // mark the entity as physics driven so that thinking is handled by QC
	controller.owner = this;
	this.move_controller = controller;
	controller.platmovetype = this.platmovetype;
	controller.platmovetype_start = this.platmovetype_start;
	controller.platmovetype_end = this.platmovetype_end;
	SUB_CalcMove_controller_setbezier(controller, this.origin, tcontrol, tdest);
	controller.finaldest = (tdest + '0 0 0.125'); // where do we want to end? Offset to overshoot a bit.
	controller.animstate_starttime = time;
	controller.animstate_endtime = time + traveltime;
	setthink(controller, SUB_CalcMove_controller_think);
	controller.think1 = getthink(this);

	// the thinking is now done by the controller
	setthink(this, SUB_NullThink); // for PushMove
	this.nextthink = this.ltime + traveltime;

	// invoke controller
	getthink(controller)(controller);
}

void SUB_CalcMove (entity this, vector tdest, float tspeedtype, float tspeed, void(entity this) func)
{
	vector	delta;
	float	traveltime;

	if (!tspeed)
		objerror (this, "No speed is defined!");

	this.think1 = func;
	this.finaldest = tdest;
	setthink(this, SUB_CalcMoveDone);

	if (tdest == this.origin)
	{
		this.velocity = '0 0 0';
		this.nextthink = this.ltime + 0.1;
		return;
	}

	delta = tdest - this.origin;

	switch(tspeedtype)
	{
		default:
		case TSPEED_START:
		case TSPEED_END:
		case TSPEED_LINEAR:
			traveltime = vlen (delta) / tspeed;
			break;
		case TSPEED_TIME:
			traveltime = tspeed;
			break;
	}

	// Q3 implements this fallback for all movers at the end of its InitMover()
	// If .speed is negative this applies, instead of the mover-specific default speed.
	if (traveltime <= 0)
		traveltime = 0.001;

	// Very short animations don't really show off the effect
	// of controlled animation, so let's just use linear movement.
	// Alternatively entities can choose to specify non-controlled movement.
	// The only currently implemented alternative movement is linear (value 1)
	if (traveltime < 0.15 || (this.platmovetype_start == 1 && this.platmovetype_end == 1)) // is this correct?
	{
		this.velocity = delta * (1/traveltime);	// QuakeC doesn't allow vector/float division
		this.nextthink = this.ltime + traveltime;
		return;
	}

	// now just run like a bezier curve...
	SUB_CalcMove_Bezier(this, (this.origin + tdest) * 0.5, tdest, tspeedtype, tspeed, func);
}

void SUB_CalcMoveEnt (entity ent, vector tdest, float tspeedtype, float tspeed, void(entity this) func)
{
	SUB_CalcMove(ent, tdest, tspeedtype, tspeed, func);
}

/*
=============
SUB_CalcAngleMove

calculate this.avelocity and this.nextthink to reach destangle from
this.angles rotating

The calling function should make sure this.setthink is valid
===============
*/
void SUB_CalcAngleMoveDone(entity this)
{
	// After rotating, set angle to exact final angle
	this.angles = this.finalangle;
	this.avelocity = '0 0 0';
	this.nextthink = -1;
	if (this.think1 && this.think1 != SUB_CalcAngleMoveDone) // avoid endless loops
		this.think1 (this);
}

// FIXME: I fixed this function only for rotation around the main axes
void SUB_CalcAngleMove (entity this, vector destangle, float tspeedtype, float tspeed, void(entity this) func)
{
	if (!tspeed)
		objerror (this, "No speed is defined!");

	// take the shortest distance for the angles
	this.angles_x -= 360 * floor((this.angles_x - destangle_x) / 360 + 0.5);
	this.angles_y -= 360 * floor((this.angles_y - destangle_y) / 360 + 0.5);
	this.angles_z -= 360 * floor((this.angles_z - destangle_z) / 360 + 0.5);
	vector delta = destangle - this.angles;
	float traveltime;

	switch(tspeedtype)
	{
		default:
		case TSPEED_START:
		case TSPEED_END:
		case TSPEED_LINEAR:
			traveltime = vlen (delta) / tspeed;
			break;
		case TSPEED_TIME:
			traveltime = tspeed;
			break;
	}

	this.think1 = func;
	this.finalangle = destangle;
	setthink(this, SUB_CalcAngleMoveDone);

	if (traveltime < 0.1)
	{
		this.avelocity = '0 0 0';
		this.nextthink = this.ltime + 0.1;
		return;
	}

	this.avelocity = delta * (1 / traveltime);
	this.nextthink = this.ltime + traveltime;
}

void SUB_CalcAngleMoveEnt (entity ent, vector destangle, float tspeedtype, float tspeed, void(entity this) func)
{
	SUB_CalcAngleMove (ent, destangle, tspeedtype, tspeed, func);
}

#ifdef SVQC
void ApplyMinMaxScaleAngles(entity e)
{
	if(e.angles.x != 0 || e.angles.z != 0 || e.avelocity.x != 0 || e.avelocity.z != 0) // "weird" rotation
	{
		e.maxs = '1 1 1' * vlen(
			'1 0 0' * max(-e.mins.x, e.maxs.x) +
			'0 1 0' * max(-e.mins.y, e.maxs.y) +
			'0 0 1' * max(-e.mins.z, e.maxs.z)
		);
		e.mins = -e.maxs;
	}
	else if(e.angles.y != 0 || e.avelocity.y != 0) // yaw only is a bit better
	{
		e.maxs_x = vlen(
			'1 0 0' * max(-e.mins.x, e.maxs.x) +
			'0 1 0' * max(-e.mins.y, e.maxs.y)
		);
		e.maxs_y = e.maxs.x;
		e.mins_x = -e.maxs.x;
		e.mins_y = -e.maxs.x;
	}
	if(e.scale)
		setsize(e, RoundPerfectVector(e.mins * e.scale), RoundPerfectVector(e.maxs * e.scale));
	else
		setsize(e, e.mins, e.maxs);
}

void SetBrushEntityModel(entity this, bool with_lod)
{
	// Ensure .solid is set correctly before calling this (for area grid linking/unlinking)

	if(this.model != "")
	{
		precache_model(this.model);
		if(this.mins != '0 0 0' || this.maxs != '0 0 0')
		{
			vector mi = this.mins;
			vector ma = this.maxs;
			_setmodel(this, this.model); // no precision needed
			setsize(this, mi, ma);
		}
		else
			_setmodel(this, this.model); // no precision needed
		if(with_lod)
			InitializeEntity(this, LODmodel_attach, INITPRIO_FINDTARGET);
	}
	setorigin(this, this.origin);
	ApplyMinMaxScaleAngles(this);
}

bool LOD_customize(entity this, entity client)
{
	if(autocvar_loddebug)
	{
		int d = autocvar_loddebug;
		if(d == 1)
			this.modelindex = this.lodmodelindex0;
		else if(d == 2 || !this.lodmodelindex2)
			this.modelindex = this.lodmodelindex1;
		else // if(d == 3)
			this.modelindex = this.lodmodelindex2;
		return true;
	}

	// TODO csqc network this so it only gets sent once
	vector near_point = NearestPointOnBox(this, client.origin);
	if(vdist(near_point - client.origin, <, this.loddistance1))
		this.modelindex = this.lodmodelindex0;
	else if(!this.lodmodelindex2 || vdist(near_point - client.origin, <, this.loddistance2))
		this.modelindex = this.lodmodelindex1;
	else
		this.modelindex = this.lodmodelindex2;

	return true;
}

void LOD_uncustomize(entity this)
{
	this.modelindex = this.lodmodelindex0;
}

void LODmodel_attach(entity this)
{
	entity e;

	if(!this.loddistance1)
		this.loddistance1 = 1000;
	if(!this.loddistance2)
		this.loddistance2 = 2000;
	this.lodmodelindex0 = this.modelindex;

	if(this.lodtarget1 != "")
	{
		e = find(NULL, targetname, this.lodtarget1);
		if(e)
		{
			this.lodmodel1 = e.model;
			delete(e);
		}
	}
	if(this.lodtarget2 != "")
	{
		e = find(NULL, targetname, this.lodtarget2);
		if(e)
		{
			this.lodmodel2 = e.model;
			delete(e);
		}
	}

	if(autocvar_loddebug < 0)
	{
		this.lodmodel1 = this.lodmodel2 = ""; // don't even initialize
	}

	if(this.lodmodel1 != "" && fexists(this.lodmodel1))
	{
		vector mi, ma;
		mi = this.mins;
		ma = this.maxs;

		precache_model(this.lodmodel1);
		_setmodel(this, this.lodmodel1);
		this.lodmodelindex1 = this.modelindex;

		if(this.lodmodel2 != "" && fexists(this.lodmodel2))
		{
			precache_model(this.lodmodel2);
			_setmodel(this, this.lodmodel2);
			this.lodmodelindex2 = this.modelindex;
		}

		this.modelindex = this.lodmodelindex0;
		setsize(this, mi, ma);
	}

	if(this.lodmodelindex1)
		if (!getSendEntity(this))
			SetCustomizer(this, LOD_customize, LOD_uncustomize);
}

/*
================
InitTrigger
================
*/

void SetMovedir(entity this)
{
	if(this.movedir != '0 0 0')
		this.movedir = normalize(this.movedir);
	else
	{
		makevectors(this.angles);
		this.movedir = v_forward;
	}

	this.angles = '0 0 0';
}

void InitTrigger(entity this)
{
// trigger angles are used for one-way touches.  An angle of 0 is assumed
// to mean no restrictions, so use a yaw of 360 instead.
	SetMovedir(this);
	this.solid = SOLID_TRIGGER;
	SetBrushEntityModel(this, false);
	set_movetype(this, MOVETYPE_NONE);
	this.modelindex = 0;
	this.model = "";
}

void InitSolidBSPTrigger(entity this)
{
// trigger angles are used for one-way touches.  An angle of 0 is assumed
// to mean no restrictions, so use a yaw of 360 instead.
	SetMovedir(this);
	this.solid = SOLID_BSP;
	SetBrushEntityModel(this, false);
	set_movetype(this, MOVETYPE_NONE); // why was this PUSH? -div0
//	this.modelindex = 0;
	this.model = "";
}

bool InitMovingBrushTrigger(entity this)
{
// trigger angles are used for one-way touches.  An angle of 0 is assumed
// to mean no restrictions, so use a yaw of 360 instead.
	this.solid = SOLID_BSP;
	SetBrushEntityModel(this, true);
	set_movetype(this, MOVETYPE_PUSH);
	if(this.modelindex == 0)
	{
		objerror(this, "InitMovingBrushTrigger: no brushes found!");
		return false;
	}
	return true;
}
#endif
