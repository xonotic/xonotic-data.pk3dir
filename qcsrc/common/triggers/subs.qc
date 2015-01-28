void SUB_NullThink(void) { }

void()  SUB_CalcMoveDone;
void() SUB_CalcAngleMoveDone;
//void() SUB_UseTargets;

/*
==================
SUB_Remove

Remove self
==================
*/
void SUB_Remove()
{
	remove (self);
}

/*
==================
SUB_Friction

Applies some friction to self
==================
*/
.float friction;
void SUB_Friction (void)
{
	self.nextthink = time;
	if(self.flags & FL_ONGROUND)
		self.velocity = self.velocity * (1 - frametime * self.friction);
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

void SUB_SetFade_Think (void)
{
	if(self.alpha == 0)
		self.alpha = 1;
	self.think = SUB_SetFade_Think;
	self.nextthink = time;
	self.alpha -= frametime * self.fade_rate;
	if (self.alpha < 0.01)
		SUB_VanishOrRemove(self);
	else
		self.nextthink = time;
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
	ent.think = SUB_SetFade_Think;
	ent.nextthink = when;
}

/*
=============
SUB_CalcMove

calculate self.velocity and self.nextthink to reach dest from
self.origin traveling at speed
===============
*/
void SUB_CalcMoveDone (void)
{
	// After moving, set origin to exact final destination

	setorigin (self, self.finaldest);
	self.velocity = '0 0 0';
	self.nextthink = -1;
	if (self.think1)
		self.think1 ();
}

.float platmovetype_turn;
void SUB_CalcMove_controller_think (void)
{
	entity oldself;
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
	if(time < self.animstate_endtime) {
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
			self.owner.angles_x -= 360 * floor((self.owner.angles_x - destangle_x) / 360 + 0.5);
			self.owner.angles_y -= 360 * floor((self.owner.angles_y - destangle_y) / 360 + 0.5);
			self.owner.angles_z -= 360 * floor((self.owner.angles_z - destangle_z) / 360 + 0.5);
			angloc = destangle - self.owner.angles;
			angloc = angloc * (1 / PHYS_INPUT_FRAMETIME); // so it arrives for the next frame
			self.owner.avelocity = angloc;
		}
		if(nexttick < self.animstate_endtime)
			veloc = nextpos - self.owner.origin;
		else
			veloc = self.finaldest - self.owner.origin;
		veloc = veloc * (1 / PHYS_INPUT_FRAMETIME); // so it arrives for the next frame

		self.owner.velocity = veloc;
		self.nextthink = nexttick;
	} else {
		// derivative: delta + 2 * delta2 (e.g. for angle positioning)
		oldself = self;
		self.owner.think = self.think1;
		self = self.owner;
		remove(oldself);
		self.think();
	}
}

void SUB_CalcMove_controller_setbezier (entity controller, vector org, vector control, vector destin)
{
	// 0 * (1-t) * (1-t) + 2 * control * t * (1-t) + destin * t * t
	// 2 * control * t - 2 * control * t * t + destin * t * t
	// 2 * control * t + (destin - 2 * control) * t * t

	controller.origin = org; // starting point
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

	controller.origin = org; // starting point
	destin -= org;

	controller.destvec = destin; // end point
	controller.destvec2 = '0 0 0';
}

float TSPEED_TIME = -1;
float TSPEED_LINEAR = 0;
float TSPEED_START = 1;
float TSPEED_END = 2;
// TODO average too?

void SUB_CalcMove_Bezier (vector tcontrol, vector tdest, float tspeedtype, float tspeed, void() func)
{
	float	traveltime;
	entity controller;

	if (!tspeed)
		objerror ("No speed is defined!");

	self.think1 = func;
	self.finaldest = tdest;
	self.think = SUB_CalcMoveDone;

	switch(tspeedtype)
	{
		default:
		case TSPEED_START:
			traveltime = 2 * vlen(tcontrol - self.origin) / tspeed;
			break;
		case TSPEED_END:
			traveltime = 2 * vlen(tcontrol - tdest)       / tspeed;
			break;
		case TSPEED_LINEAR:
			traveltime = vlen(tdest - self.origin)        / tspeed;
			break;
		case TSPEED_TIME:
			traveltime = tspeed;
			break;
	}

	if (traveltime < 0.1) // useless anim
	{
		self.velocity = '0 0 0';
		self.nextthink = self.ltime + 0.1;
		return;
	}

	controller = spawn();
	controller.classname = "SUB_CalcMove_controller";
	controller.owner = self;
	controller.platmovetype = self.platmovetype;
	controller.platmovetype_start = self.platmovetype_start;
	controller.platmovetype_end = self.platmovetype_end;
	SUB_CalcMove_controller_setbezier(controller, self.origin, tcontrol, tdest);
	controller.finaldest = (tdest + '0 0 0.125'); // where do we want to end? Offset to overshoot a bit.
	controller.animstate_starttime = time;
	controller.animstate_endtime = time + traveltime;
	controller.think = SUB_CalcMove_controller_think;
	controller.think1 = self.think;

	// the thinking is now done by the controller
	self.think = SUB_NullThink; // for PushMove
	self.nextthink = self.ltime + traveltime;

	// invoke controller
	self = controller;
	self.think();
	self = self.owner;
}

void SUB_CalcMove (vector tdest, float tspeedtype, float tspeed, void() func)
{
	vector	delta;
	float	traveltime;

	if (!tspeed)
		objerror ("No speed is defined!");

	self.think1 = func;
	self.finaldest = tdest;
	self.think = SUB_CalcMoveDone;

	if (tdest == self.origin)
	{
		self.velocity = '0 0 0';
		self.nextthink = self.ltime + 0.1;
		return;
	}

	delta = tdest - self.origin;

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
		self.velocity = delta * (1/traveltime);	// QuakeC doesn't allow vector/float division
		self.nextthink = self.ltime + traveltime;
		return;
	}

	// now just run like a bezier curve...
	SUB_CalcMove_Bezier((self.origin + tdest) * 0.5, tdest, tspeedtype, tspeed, func);
}

void SUB_CalcMoveEnt (entity ent, vector tdest, float tspeedtype, float tspeed, void() func)
{
	entity	oldself;

	oldself = self;
	self = ent;

	SUB_CalcMove (tdest, tspeedtype, tspeed, func);

	self = oldself;
}

/*
=============
SUB_CalcAngleMove

calculate self.avelocity and self.nextthink to reach destangle from
self.angles rotating

The calling function should make sure self.think is valid
===============
*/
void SUB_CalcAngleMoveDone (void)
{
	// After rotating, set angle to exact final angle
	self.angles = self.finalangle;
	self.avelocity = '0 0 0';
	self.nextthink = -1;
	if (self.think1)
		self.think1 ();
}

// FIXME: I fixed this function only for rotation around the main axes
void SUB_CalcAngleMove (vector destangle, float tspeedtype, float tspeed, void() func)
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
	self.think = SUB_CalcAngleMoveDone;

	if (traveltime < 0.1)
	{
		self.avelocity = '0 0 0';
		self.nextthink = self.ltime + 0.1;
		return;
	}

	self.avelocity = delta * (1 / traveltime);
	self.nextthink = self.ltime + traveltime;
}

void SUB_CalcAngleMoveEnt (entity ent, vector destangle, float tspeedtype, float tspeed, void() func)
{
	entity	oldself;

	oldself = self;
	self = ent;

	SUB_CalcAngleMove (destangle, tspeedtype, tspeed, func);

	self = oldself;
}
