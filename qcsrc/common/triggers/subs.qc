#include "subs.qh"
void SUB_NullThink(entity this) { }

void SUB_CalcMoveDone(entity this);
void SUB_CalcAngleMoveDone(entity this);

/*
==================
SUB_Friction

Applies some friction to this
==================
*/
.float friction;
void SUB_Friction (entity this)
{
	this.SUB_NEXTTHINK = time;
	if(IS_ONGROUND(this))
		this.SUB_VELOCITY = this.SUB_VELOCITY * (1 - frametime * this.friction);
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
		delete (ent);
	}
}

void SUB_SetFade_Think (entity this)
{
	if(this.alpha == 0)
		this.alpha = 1;
	SUB_THINK(this, SUB_SetFade_Think);
	this.SUB_NEXTTHINK = time;
	this.alpha -= frametime * this.fade_rate;
	if (this.alpha < 0.01)
		SUB_VanishOrRemove(this);
	else
		this.SUB_NEXTTHINK = time;
}

/*
==================
SUB_SetFade

Fade 'ent' out when time >= 'when'
==================
*/
void SUB_SetFade (entity ent, float when, float fading_time)
{
	ent.fade_rate = 1/fading_time;
	SUB_THINK(ent, SUB_SetFade_Think);
	ent.SUB_NEXTTHINK = when;
}

/*
=============
SUB_CalcMove

calculate this.SUB_VELOCITY and this.SUB_NEXTTHINK to reach dest from
this.SUB_ORIGIN traveling at speed
===============
*/
void SUB_CalcMoveDone(entity this)
{
	// After moving, set origin to exact final destination

	SUB_SETORIGIN (this, this.finaldest);
	this.SUB_VELOCITY = '0 0 0';
	this.SUB_NEXTTHINK = -1;
	if (this.think1 && this.think1 != SUB_CalcMoveDone)
		this.think1 (this);
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
			vector v = SUB_ANGLES(this.owner);
			v.x -= 360 * floor((v.x - destangle_x) / 360 + 0.5);
			v.y -= 360 * floor((v.y - destangle_y) / 360 + 0.5);
			v.z -= 360 * floor((v.z - destangle_z) / 360 + 0.5);
			SUB_ANGLES(this.owner) = v;
			angloc = destangle - SUB_ANGLES(this.owner);
			angloc = angloc * (1 / PHYS_INPUT_FRAMETIME); // so it arrives for the next frame
			this.owner.SUB_AVELOCITY = angloc;
		}
		if(nexttick < this.animstate_endtime)
			veloc = nextpos - this.owner.SUB_ORIGIN;
		else
			veloc = this.finaldest - this.owner.SUB_ORIGIN;
		veloc = veloc * (1 / PHYS_INPUT_FRAMETIME); // so it arrives for the next frame

		this.owner.SUB_VELOCITY = veloc;
		this.nextthink = nexttick;
	}
	else
	{
		// derivative: delta + 2 * delta2 (e.g. for angle positioning)
		entity own = this.owner;
		SUB_THINK(own, this.think1);
		delete(this);
		SUB_THUNK(own)(own);
	}
}

void SUB_CalcMove_controller_setbezier (entity controller, vector org, vector control, vector destin)
{
	// 0 * (1-t) * (1-t) + 2 * control * t * (1-t) + destin * t * t
	// 2 * control * t - 2 * control * t * t + destin * t * t
	// 2 * control * t + (destin - 2 * control) * t * t

	setorigin(controller, org);
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

	setorigin(controller, org);
	destin -= org;

	controller.destvec = destin; // end point
	controller.destvec2 = '0 0 0';
}

float TSPEED_TIME = -1;
float TSPEED_LINEAR = 0;
float TSPEED_START = 1;
float TSPEED_END = 2;
// TODO average too?

void SUB_CalcMove_Bezier (entity this, vector tcontrol, vector tdest, float tspeedtype, float tspeed, void(entity this) func)
{
	float	traveltime;
	entity controller;

	if (!tspeed)
		objerror (this, "No speed is defined!");

	this.think1 = func;
	this.finaldest = tdest;
	SUB_THINK(this, SUB_CalcMoveDone);

	switch(tspeedtype)
	{
		default:
		case TSPEED_START:
			traveltime = 2 * vlen(tcontrol - this.SUB_ORIGIN) / tspeed;
			break;
		case TSPEED_END:
			traveltime = 2 * vlen(tcontrol - tdest)       / tspeed;
			break;
		case TSPEED_LINEAR:
			traveltime = vlen(tdest - this.SUB_ORIGIN)        / tspeed;
			break;
		case TSPEED_TIME:
			traveltime = tspeed;
			break;
	}

	if (traveltime < 0.1) // useless anim
	{
		this.SUB_VELOCITY = '0 0 0';
		this.SUB_NEXTTHINK = this.SUB_LTIME + 0.1;
		return;
	}

	controller = new(SUB_CalcMove_controller);
	controller.owner = this;
	controller.platmovetype = this.platmovetype;
	controller.platmovetype_start = this.platmovetype_start;
	controller.platmovetype_end = this.platmovetype_end;
	SUB_CalcMove_controller_setbezier(controller, this.SUB_ORIGIN, tcontrol, tdest);
	controller.finaldest = (tdest + '0 0 0.125'); // where do we want to end? Offset to overshoot a bit.
	controller.animstate_starttime = time;
	controller.animstate_endtime = time + traveltime;
	setthink(controller, SUB_CalcMove_controller_think);
	controller.think1 = SUB_THUNK(this);

	// the thinking is now done by the controller
	SUB_THINK(this, SUB_NullThink); // for PushMove
	this.SUB_NEXTTHINK = this.SUB_LTIME + traveltime;

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
	SUB_THINK(this, SUB_CalcMoveDone);

	if (tdest == this.SUB_ORIGIN)
	{
		this.SUB_VELOCITY = '0 0 0';
		this.SUB_NEXTTHINK = this.SUB_LTIME + 0.1;
		return;
	}

	delta = tdest - this.SUB_ORIGIN;

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

	// Very short animations don't really show off the effect
	// of controlled animation, so let's just use linear movement.
	// Alternatively entities can choose to specify non-controlled movement.
        // The only currently implemented alternative movement is linear (value 1)
	if (traveltime < 0.15 || (this.platmovetype_start == 1 && this.platmovetype_end == 1)) // is this correct?
	{
		this.SUB_VELOCITY = delta * (1/traveltime);	// QuakeC doesn't allow vector/float division
		this.SUB_NEXTTHINK = this.SUB_LTIME + traveltime;
		return;
	}

	// now just run like a bezier curve...
	SUB_CalcMove_Bezier(this, (this.SUB_ORIGIN + tdest) * 0.5, tdest, tspeedtype, tspeed, func);
}

void SUB_CalcMoveEnt (entity ent, vector tdest, float tspeedtype, float tspeed, void(entity this) func)
{
	SUB_CalcMove(ent, tdest, tspeedtype, tspeed, func);
}

/*
=============
SUB_CalcAngleMove

calculate this.SUB_AVELOCITY and this.SUB_NEXTTHINK to reach destangle from
this.angles rotating

The calling function should make sure this.SUB_THINK is valid
===============
*/
void SUB_CalcAngleMoveDone(entity this)
{
	// After rotating, set angle to exact final angle
	this.angles = this.finalangle;
	this.SUB_AVELOCITY = '0 0 0';
	this.SUB_NEXTTHINK = -1;
	if (this.think1 && this.think1 != SUB_CalcAngleMoveDone) // avoid endless loops
		this.think1 (this);
}

// FIXME: I fixed this function only for rotation around the main axes
void SUB_CalcAngleMove (entity this, vector destangle, float tspeedtype, float tspeed, void(entity this) func)
{
	vector	delta;
	float	traveltime;

	if (!tspeed)
		objerror (this, "No speed is defined!");

	// take the shortest distance for the angles
	this.angles_x -= 360 * floor((this.angles_x - destangle_x) / 360 + 0.5);
	this.angles_y -= 360 * floor((this.angles_y - destangle_y) / 360 + 0.5);
	this.angles_z -= 360 * floor((this.angles_z - destangle_z) / 360 + 0.5);
	delta = destangle - this.angles;

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
	SUB_THINK(this, SUB_CalcAngleMoveDone);

	if (traveltime < 0.1)
	{
		this.SUB_AVELOCITY = '0 0 0';
		this.SUB_NEXTTHINK = this.SUB_LTIME + 0.1;
		return;
	}

	this.SUB_AVELOCITY = delta * (1 / traveltime);
	this.SUB_NEXTTHINK = this.SUB_LTIME + traveltime;
}

void SUB_CalcAngleMoveEnt (entity ent, vector destangle, float tspeedtype, float tspeed, void(entity this) func)
{
	SUB_CalcAngleMove (ent, destangle, tspeedtype, tspeed, func);
}
