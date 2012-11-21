// implicit anim state
.float anim_implicit_state;
.float anim_implicit_time;

// actions
.float anim_lower_action;
.float anim_lower_time;
.float anim_upper_action;
.float anim_upper_time;

// player animation data for this model
// each vector is as follows:
// _x = startframe
// _y = numframes
// _z = framerate
.vector anim_die1; // player dies
.vector anim_die2; // player dies differently
.vector anim_draw; // player pulls out a weapon
.vector anim_duckwalk; // player walking while crouching
.vector anim_duckjump; // player jumping from a crouch
.vector anim_duckidle; // player idling while crouching
.vector anim_idle; // player standing
.vector anim_jump; // player jump
.vector anim_pain1; // player flinches from pain
.vector anim_pain2; // player flinches from pain, differently
.vector anim_shoot; // player shoots
.vector anim_taunt; // player taunts others (FIXME: no code references this)
.vector anim_run; // player running forward
.vector anim_runbackwards; // player running backward
.vector anim_strafeleft; // player shuffling left quickly
.vector anim_straferight; // player shuffling right quickly
.vector anim_forwardright; // player running forward and right
.vector anim_forwardleft; // player running forward and left
.vector anim_backright; // player running backward and right
.vector anim_backleft; // player running back and left
.vector anim_melee; // player doing the melee action
.vector anim_duck; // player doing the melee action
.vector anim_duckwalkbackwards;
.vector anim_duckwalkstrafeleft;
.vector anim_duckwalkstraferight;
.vector anim_duckwalkforwardright;
.vector anim_duckwalkforwardleft;
.vector anim_duckwalkbackright;
.vector anim_duckwalkbackleft;

void animdecide_init(entity e)
{
	self.anim_die1 = animfixfps(self, '0 1 0.5'); // 2 seconds
	self.anim_die2 = animfixfps(self, '1 1 0.5'); // 2 seconds
	self.anim_draw = animfixfps(self, '2 1 3');
	self.anim_duckwalk = animfixfps(self, '4 1 1');
	self.anim_duckjump = '5 1 100'; // NOTE: zym anims keep playing until changed, so this only has to start the anim, landing will end it
	self.anim_duckidle = animfixfps(self, '6 1 1');
	self.anim_idle = animfixfps(self, '7 1 1');
	self.anim_jump = '8 1 100'; // NOTE: zym anims keep playing until changed, so this only has to start the anim, landing will end it
	self.anim_pain1 = animfixfps(self, '9 1 2'); // 0.5 seconds
	self.anim_pain2 = animfixfps(self, '10 1 2'); // 0.5 seconds
	self.anim_shoot = animfixfps(self, '11 1 5'); // analyze models and set framerate
	self.anim_taunt = animfixfps(self, '12 1 0.33');
	self.anim_run = animfixfps(self, '13 1 1');
	self.anim_runbackwards = animfixfps(self, '14 1 1');
	self.anim_strafeleft = animfixfps(self, '15 1 1');
	self.anim_straferight = animfixfps(self, '16 1 1');
	self.anim_forwardright = animfixfps(self, '19 1 1');
	self.anim_forwardleft = animfixfps(self, '20 1 1');
	self.anim_backright = animfixfps(self, '21 1 1');
	self.anim_backleft  = animfixfps(self, '22 1 1');
	self.anim_melee = animfixfps(self, '23 1 1');
	self.anim_duckwalkbackwards = animfixfps(self, '24 1 1');
	self.anim_duckwalkstrafeleft = animfixfps(self, '25 1 1');
	self.anim_duckwalkstraferight = animfixfps(self, '26 1 1');
	self.anim_duckwalkforwardright = animfixfps(self, '27 1 1');
	self.anim_duckwalkforwardleft = animfixfps(self, '28 1 1');
	self.anim_duckwalkbackright = animfixfps(self, '29 1 1');
	self.anim_duckwalkbackleft  = animfixfps(self, '30 1 1');
}

#define ANIMPRIO_IDLE 0
#define ANIMPRIO_STATIC 1
#define ANIMPRIO_ACTIVE 2
#define ANIMPRIO_DEAD 3

vector animdecide_getupperanim(entity e)
{
	// is there an action?
	vector outframe = '-1 0 0';
	switch(e.anim_upper_action)
	{
		case ANIMACTION_DRAW: outframe = e.anim_draw; break;
		case ANIMACTION_PAIN1: outframe = e.anim_pain1; break;
		case ANIMACTION_PAIN2: outframe = e.anim_pain2; break;
		case ANIMACTION_SHOOT: outframe = e.anim_shoot; break;
		case ANIMACTION_TAUNT: outframe = e.anim_taunt; break;
		case ANIMACTION_MELEE: outframe = e.anim_melee; break;
	}
	if(outframe_x >= 0)
	{
		if(time <= e.anim_upper_time + outframe_y / outframe_z)
		{
			// animation is running!
			return vec3(outframe_x, e.anim_upper_time, ANIMPRIO_ACTIVE);
		}
	}
	float t = max(e.anim_time, e.anim_implicit_time);
	// or, decide the anim by state
	// but all states are for lower body!
	return vec3(e.anim_idle_x, t, ANIMPRIO_IDLE);
}

vector animdecide_getloweranim(entity e)
{
	// death etc.
	if(e.anim_state & ANIMSTATE_FROZEN)
		return vec3(e.anim_idle_x, e.anim_time, ANIMPRIO_DEAD);
	if(e.anim_state & ANIMSTATE_DEAD1)
		return vec3(e.anim_die1_x, e.anim_time, ANIMPRIO_DEAD);
	if(e.anim_state & ANIMSTATE_DEAD2)
		return vec3(e.anim_die2_x, e.anim_time, ANIMPRIO_DEAD);

	// is there an action?
	vector outframe = '-1 0 0';
	switch(e.anim_lower_action)
	{
		case ANIMACTION_JUMP: if(e.anim_state & ANIMSTATE_DUCK) outframe = e.anim_duckjump; else outframe = e.anim_jump; break;
	}
	if(outframe_x >= 0)
	{
		if(time <= e.anim_lower_time + outframe_y / outframe_z)
		{
			// animation is running!
			return vec3(outframe_x, e.anim_lower_time, ANIMPRIO_ACTIVE);
		}
	}
	float t = max(e.anim_time, e.anim_implicit_time);
	// or, decide the anim by state
	if(e.anim_state & ANIMSTATE_DUCK)
	{
		switch(self.anim_implicit_state & (ANIMIMPLICITSTATE_FORWARD | ANIMIMPLICITSTATE_BACKWARDS | ANIMIMPLICITSTATE_LEFT | ANIMIMPLICITSTATE_RIGHT))
		{
			case ANIMIMPLICITSTATE_FORWARD:
				return vec3(e.anim_duckwalk_x, t, ANIMPRIO_ACTIVE);
			case ANIMIMPLICITSTATE_BACKWARDS:
				return vec3(e.anim_duckwalkbackwards_x, t, ANIMPRIO_ACTIVE);
			case ANIMIMPLICITSTATE_RIGHT:
				return vec3(e.anim_duckwalkstraferight_x, t, ANIMPRIO_ACTIVE);
			case ANIMIMPLICITSTATE_LEFT:
				return vec3(e.anim_duckwalkstrafeleft_x, t, ANIMPRIO_ACTIVE);
			case ANIMIMPLICITSTATE_FORWARD | ANIMIMPLICITSTATE_RIGHT:
				return vec3(e.anim_duckwalkforwardright_x, t, ANIMPRIO_ACTIVE);
			case ANIMIMPLICITSTATE_FORWARD | ANIMIMPLICITSTATE_LEFT:
				return vec3(e.anim_duckwalkforwardleft_x, t, ANIMPRIO_ACTIVE);
			case ANIMIMPLICITSTATE_BACKWARDS | ANIMIMPLICITSTATE_RIGHT:
				return vec3(e.anim_duckwalkbackright_x, t, ANIMPRIO_ACTIVE);
			case ANIMIMPLICITSTATE_BACKWARDS | ANIMIMPLICITSTATE_LEFT:
				return vec3(e.anim_duckwalkbackleft_x, t, ANIMPRIO_ACTIVE);
			default:
				return vec3(e.anim_duckidle_x, t, ANIMPRIO_STATIC);
		}
	}
	else if(e.anim_implicit_state & ANIMIMPLICITSTATE_RUN)
	{
		switch(self.anim_implicit_state & (ANIMIMPLICITSTATE_FORWARD | ANIMIMPLICITSTATE_BACKWARDS | ANIMIMPLICITSTATE_LEFT | ANIMIMPLICITSTATE_RIGHT))
		{
			case ANIMIMPLICITSTATE_FORWARD:
				return vec3(e.anim_run_x, t, ANIMPRIO_ACTIVE);
			case ANIMIMPLICITSTATE_BACKWARDS:
				return vec3(e.anim_runbackwards_x, t, ANIMPRIO_ACTIVE);
			case ANIMIMPLICITSTATE_RIGHT:
				return vec3(e.anim_straferight_x, t, ANIMPRIO_ACTIVE);
			case ANIMIMPLICITSTATE_LEFT:
				return vec3(e.anim_strafeleft_x, t, ANIMPRIO_ACTIVE);
			case ANIMIMPLICITSTATE_FORWARD | ANIMIMPLICITSTATE_RIGHT:
				return vec3(e.anim_forwardright_x, t, ANIMPRIO_ACTIVE);
			case ANIMIMPLICITSTATE_FORWARD | ANIMIMPLICITSTATE_LEFT:
				return vec3(e.anim_forwardleft_x, t, ANIMPRIO_ACTIVE);
			case ANIMIMPLICITSTATE_BACKWARDS | ANIMIMPLICITSTATE_RIGHT:
				return vec3(e.anim_backright_x, t, ANIMPRIO_ACTIVE);
			case ANIMIMPLICITSTATE_BACKWARDS | ANIMIMPLICITSTATE_LEFT:
				return vec3(e.anim_backleft_x, t, ANIMPRIO_ACTIVE);
			default:
				return vec3(e.anim_run_x, t, ANIMPRIO_STATIC);
		}
	}
	return vec3(e.anim_idle_x, t, ANIMPRIO_IDLE);
}

void animdecide_setimplicitstate(entity e)
{
	float s;
	s = 0;

	makevectors(self.angles);
	if(self.velocity * v_forward > 0)
		s |= ANIMIMPLICITSTATE_FORWARD;
	if(self.velocity * v_forward < 0)
		s |= ANIMIMPLICITSTATE_BACKWARDS;
	if(self.velocity * v_right > 0)
		s |= ANIMIMPLICITSTATE_RIGHT;
	if(self.velocity * v_right < 0)
		s |= ANIMIMPLICITSTATE_LEFT;
	if(vlen(self.velocity) > 100)
		s |= ANIMIMPLICITSTATE_RUN;

	// TODO infer jumping too!
}
void animdecide_setframes(entity e, float support_blending)
{
	animdecide_setimplicitstate(e);
	// _x: frame
	// _y: priority
	// _z: start time
	vector upper = animdecide_getupperanim(e);
	vector lower = animdecide_getloweranim(e);
	if(upper_y > lower_y)
		lower = upper;
	else if(lower_y > upper_y)
		upper = lower;
	if(support_blending)
	{
		self.frame = upper_x;
		self.frame1time = upper_z;
		self.frame2 = lower_x;
		self.frame2time = lower_z;
	}
	else
	{
		self.frame = upper_x;
		self.frame1time = upper_z;
	}
}

void animdecide_setstate(entity e, float newstate, float restart)
{
	if(!restart)
		if(newstate == e.anim_state)
			return;
	e.anim_state = newstate;
	e.anim_time = time;
}
void animdecide_setaction(entity e, float action, float restart)
{
	if(action < 0)
	{
		if(!restart)
			if(action == e.anim_lower_action)
				return;
		e.anim_lower_action = action;
		e.anim_lower_time = time;
	}
	else
	{
		if(!restart)
			if(action == e.anim_upper_action)
				return;
		e.anim_upper_action = action;
		e.anim_upper_time = time;
	}
}
