void SUB_NullThink(entity this) { }

void SUB_CalcMoveDone(entity this);
void SUB_CalcAngleMoveDone(entity this);

/*
==================
SUB_Friction

Applies some friction to self
==================
*/
.float friction;
void SUB_Friction (entity this)
{
	self.SUB_NEXTTHINK = time;
	if(self.SUB_FLAGS & FL_ONGROUND)
		self.SUB_VELOCITY = self.SUB_VELOCITY * (1 - frametime * self.friction);
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
		remove (ent);
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

calculate self.SUB_VELOCITY and self.SUB_NEXTTHINK to reach dest from
self.SUB_ORIGIN traveling at speed
===============
*/
void SUB_CalcMoveDone(entity this)
{
	// After moving, set origin to exact final destination

	SUB_SETORIGIN (self, self.finaldest);
	self.SUB_VELOCITY = '0 0 0';
	self.SUB_NEXTTHINK = -1;
	if (self.think1)
		self.think1 (self);
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
	delta = self.destvec;
	delta2 = self.destvec2;
	if(time < self.animstate_endtime)
	{
		nexttick = time + PHYS_INPUT_FRAMETIME;

		traveltime = self.animstate_endtime - self.animstate_starttime;
		phasepos = (nexttick - self.animstate_starttime) / traveltime; // range: [0, 1]
		phasepos = cubic_speedfunc(self.platmovetype_start, self.platmovetype_end, phasepos);
		nextpos = self.origin + (delta * phasepos) + (delta2 * phasepos * phasepos);
		// derivative: delta + 2 * delta2 * phasepos (e.g. for angle positioning)

		if(self.owner.platmovetype_turn)
		{
			vector destangle;
			destangle = delta + 2 * delta2 * phasepos;
			destangle = vectoangles(destangle);
			destangle_x = -destangle_x; // flip up / down orientation

			// take the shortest distance for the angles
			vector v = SUB_ANGLES(self.owner);
			v.x -= 360 * floor((v.x - destangle_x) / 360 + 0.5);
			v.y -= 360 * floor((v.y - destangle_y) / 360 + 0.5);
			v.z -= 360 * floor((v.z - destangle_z) / 360 + 0.5);
			SUB_ANGLES(self.owner) = v;
			angloc = destangle - SUB_ANGLES(self.owner);
			angloc = angloc * (1 / PHYS_INPUT_FRAMETIME); // so it arrives for the next frame
			self.owner.SUB_AVELOCITY = angloc;
		}
		if(nexttick < self.animstate_endtime)
			veloc = nextpos - self.owner.SUB_ORIGIN;
		else
			veloc = self.finaldest - self.owner.SUB_ORIGIN;
		veloc = veloc * (1 / PHYS_INPUT_FRAMETIME); // so it arrives for the next frame

		self.owner.SUB_VELOCITY = veloc;
		self.nextthink = nexttick;
	}
	else
	{
		// derivative: delta + 2 * delta2 (e.g. for angle positioning)
		entity own = self.owner;
		SUB_THINK(own, self.think1);
		remove(self);
		WITHSELF(own, SUB_THUNK(own)(own));
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
		objerror ("No speed is defined!");

	self.think1 = func;
	self.finaldest = tdest;
	SUB_THINK(self, SUB_CalcMoveDone);

	switch(tspeedtype)
	{
		default:
		case TSPEED_START:
			traveltime = 2 * vlen(tcontrol - self.SUB_ORIGIN) / tspeed;
			break;
		case TSPEED_END:
			traveltime = 2 * vlen(tcontrol - tdest)       / tspeed;
			break;
		case TSPEED_LINEAR:
			traveltime = vlen(tdest - self.SUB_ORIGIN)        / tspeed;
			break;
		case TSPEED_TIME:
			traveltime = tspeed;
			break;
	}

	if (traveltime < 0.1) // useless anim
	{
		self.SUB_VELOCITY = '0 0 0';
		self.SUB_NEXTTHINK = self.SUB_LTIME + 0.1;
		return;
	}

	controller = new(SUB_CalcMove_controller);
	controller.owner = self;
	controller.platmovetype = self.platmovetype;
	controller.platmovetype_start = self.platmovetype_start;
	controller.platmovetype_end = self.platmovetype_end;
	SUB_CalcMove_controller_setbezier(controller, self.SUB_ORIGIN, tcontrol, tdest);
	controller.finaldest = (tdest + '0 0 0.125'); // where do we want to end? Offset to overshoot a bit.
	controller.animstate_starttime = time;
	controller.animstate_endtime = time + traveltime;
	setthink(controller, SUB_CalcMove_controller_think);
	controller.think1 = SUB_THUNK(self);

	// the thinking is now done by the controller
	SUB_THINK(self, SUB_NullThink); // for PushMove
	self.SUB_NEXTTHINK = self.SUB_LTIME + traveltime;

	// invoke controller
	WITHSELF(controller, getthink(controller)(controller));
}

void SUB_CalcMove (entity this, vector tdest, float tspeedtype, float tspeed, void(entity this) func)
{
	vector	delta;
	float	traveltime;

	if (!tspeed)
		objerror ("No speed is defined!");

	self.think1 = func;
	self.finaldest = tdest;
	SUB_THINK(self, SUB_CalcMoveDone);

	if (tdest == self.SUB_ORIGIN)
	{
		self.SUB_VELOCITY = '0 0 0';
		self.SUB_NEXTTHINK = self.SUB_LTIME + 0.1;
		return;
	}

	delta = tdest - self.SUB_ORIGIN;

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
	if (traveltime < 0.15 || (self.platmovetype_start == 1 && self.platmovetype_end == 1)) // is this correct?
	{
		self.SUB_VELOCITY = delta * (1/traveltime);	// QuakeC doesn't allow vector/float division
		self.SUB_NEXTTHINK = self.SUB_LTIME + traveltime;
		return;
	}

	// now just run like a bezier curve...
	SUB_CalcMove_Bezier(self, (self.SUB_ORIGIN + tdest) * 0.5, tdest, tspeedtype, tspeed, func);
}

void SUB_CalcMoveEnt (entity ent, vector tdest, float tspeedtype, float tspeed, void(entity this) func)
{
	WITHSELF(ent, SUB_CalcMove(ent, tdest, tspeedtype, tspeed, func));
}

/*
=============
SUB_CalcAngleMove

calculate self.SUB_AVELOCITY and self.SUB_NEXTTHINK to reach destangle from
self.angles rotating

The calling function should make sure self.SUB_THINK is valid
===============
*/
void SUB_CalcAngleMoveDone(entity this)
{
	// After rotating, set angle to exact final angle
	self.angles = self.finalangle;
	self.SUB_AVELOCITY = '0 0 0';
	self.SUB_NEXTTHINK = -1;
	if (self.think1)
		self.think1 (self);
}

// FIXME: I fixed this function only for rotation around the main axes
void SUB_CalcAngleMove (entity this, vector destangle, float tspeedtype, float tspeed, void(entity this) func)
{
	vector	delta;
	float	traveltime;

	if (!tspeed)
		objerror ("No speed is defined!");

	// take the shortest distance for the angles
	self.angles_x -= 360 * floor((self.angles_x - destangle_x) / 360 + 0.5);
	self.angles_y -= 360 * floor((self.angles_y - destangle_y) / 360 + 0.5);
	self.angles_z -= 360 * floor((self.angles_z - destangle_z) / 360 + 0.5);
	delta = destangle - self.angles;

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

	self.think1 = func;
	self.finalangle = destangle;
	SUB_THINK(self, SUB_CalcAngleMoveDone);

	if (traveltime < 0.1)
	{
		self.SUB_AVELOCITY = '0 0 0';
		self.SUB_NEXTTHINK = self.SUB_LTIME + 0.1;
		return;
	}

	self.SUB_AVELOCITY = delta * (1 / traveltime);
	self.SUB_NEXTTHINK = self.SUB_LTIME + traveltime;
}

void SUB_CalcAngleMoveEnt (entity ent, vector destangle, float tspeedtype, float tspeed, void(entity this) func)
{
	WITHSELF(ent, SUB_CalcAngleMove (ent, destangle, tspeedtype, tspeed, func));
}
