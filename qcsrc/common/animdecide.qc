#include "animdecide.qh"

#if defined(CSQC)
	#include <common/monsters/_mod.qh>
#elif defined(MENUQC)
#elif defined(SVQC)
	#include <common/monsters/_mod.qh>
	#include <common/stats.qh>
	#include <common/util.qh>
	#include <common/weapons/_all.qh>
#endif

bool monsters_animoverride(entity this)
{
	Monster monster_id = NULL;
	FOREACH(Monsters, it != MON_Null && it.m_model.model_str() == this.model, {
        monster_id = it;
        break;
	});

	if(!monster_id) { return false; }

	monster_id.mr_anim(monster_id, this);

	vector none = '0 0 0';
	this.anim_duckwalk = this.anim_walk;
	this.anim_duckjump = animfixfps(this, '5 1 10', none);
	this.anim_duckidle = this.anim_idle;
	this.anim_jump = animfixfps(this, '8 1 10', none);
	this.anim_taunt = animfixfps(this, '12 1 0.33', none);
	this.anim_runbackwards = this.anim_run;
	this.anim_strafeleft = this.anim_run;
	this.anim_straferight = this.anim_run;
	this.anim_forwardright = this.anim_run;
	this.anim_forwardleft = this.anim_run;
	this.anim_backright = this.anim_run;
	this.anim_backleft  = this.anim_run;
	this.anim_duckwalkbackwards = this.anim_walk;
	this.anim_duckwalkstrafeleft = this.anim_walk;
	this.anim_duckwalkstraferight = this.anim_walk;
	this.anim_duckwalkforwardright = this.anim_walk;
	this.anim_duckwalkforwardleft = this.anim_walk;
	this.anim_duckwalkbackright = this.anim_walk;
	this.anim_duckwalkbackleft  = this.anim_walk;

	// these anims ought to stay until stopped explicitly by weaponsystem
	this.anim_shoot_z = 0.001;
	this.anim_melee_z = 0.001;

	return true;
}

void animdecide_load_if_needed(entity e)
{
	int mdlidx = e.modelindex;
	if (mdlidx == e.animdecide_modelindex) return;
	e.animdecide_modelindex = mdlidx;

	if(substring(e.model, 0, 16) == "models/monsters/")
	{
		if(monsters_animoverride(e))
			return;
	}

#define ANIM_VEC(a, frames, rate) anim_vec(ANIM_##a, mdlidx, frames, rate)

	vector none = '0 0 0';
	e.anim_die1 = animfixfps(e, ANIM_VEC(die1, 1, 0.5), none); // 2 seconds
	e.anim_die2 = animfixfps(e, ANIM_VEC(die2, 1, 0.5), none); // 2 seconds
	e.anim_draw = animfixfps(e, ANIM_VEC(draw, 1, 3), none);
	e.anim_duckwalk = animfixfps(e, ANIM_VEC(duckwalk, 1, 1), none);
	e.anim_duckjump = animfixfps(e, ANIM_VEC(duckjump, 1, 10), none);
	e.anim_duckidle = animfixfps(e, ANIM_VEC(duckidle, 1, 1), none);
	e.anim_idle = animfixfps(e, ANIM_VEC(idle, 1, 1), none);
	e.anim_jump = animfixfps(e, ANIM_VEC(jump, 1, 10), none);
	e.anim_pain1 = animfixfps(e, ANIM_VEC(pain1, 1, 2), none); // 0.5 seconds
	e.anim_pain2 = animfixfps(e, ANIM_VEC(pain2, 1, 2), none); // 0.5 seconds
	e.anim_shoot = animfixfps(e, ANIM_VEC(shoot, 1, 5), none); // analyze models and set framerate
	e.anim_taunt = animfixfps(e, ANIM_VEC(taunt, 1, 0.33), none);
	e.anim_run = animfixfps(e, ANIM_VEC(run, 1, 1), none);
	e.anim_runbackwards = animfixfps(e, ANIM_VEC(runbackwards, 1, 1), none);
	e.anim_strafeleft = animfixfps(e, ANIM_VEC(strafeleft, 1, 1), none);
	e.anim_straferight = animfixfps(e, ANIM_VEC(straferight, 1, 1), none);
	e.anim_forwardright = animfixfps(e, ANIM_VEC(forwardright, 1, 1), ANIM_VEC(straferight, 1, 1));
	e.anim_forwardleft = animfixfps(e, ANIM_VEC(forwardleft, 1, 1), ANIM_VEC(strafeleft, 1, 1));
	e.anim_backright = animfixfps(e, ANIM_VEC(backright, 1, 1), ANIM_VEC(straferight, 1, 1));
	e.anim_backleft  = animfixfps(e, ANIM_VEC(backleft , 1, 1), ANIM_VEC(strafeleft, 1, 1));
	e.anim_melee = animfixfps(e, ANIM_VEC(melee, 1, 1), ANIM_VEC(shoot, 1, 1));
	e.anim_duckwalkbackwards = animfixfps(e, ANIM_VEC(duckwalkbackwards, 1, 1), ANIM_VEC(duckwalk, 1, 1));
	e.anim_duckwalkstrafeleft = animfixfps(e, ANIM_VEC(duckwalkstrafeleft, 1, 1), ANIM_VEC(duckwalk, 1, 1));
	e.anim_duckwalkstraferight = animfixfps(e, ANIM_VEC(duckwalkstraferight, 1, 1), ANIM_VEC(duckwalk, 1, 1));
	e.anim_duckwalkforwardright = animfixfps(e, ANIM_VEC(duckwalkforwardright, 1, 1), ANIM_VEC(duckwalk, 1, 1));
	e.anim_duckwalkforwardleft = animfixfps(e, ANIM_VEC(duckwalkforwardleft, 1, 1), ANIM_VEC(duckwalk, 1, 1));
	e.anim_duckwalkbackright = animfixfps(e, ANIM_VEC(duckwalkbackright, 1,  1), ANIM_VEC(duckwalk, 1, 1));
	e.anim_duckwalkbackleft  = animfixfps(e, ANIM_VEC(duckwalkbackleft , 1,  1), ANIM_VEC(duckwalk, 1, 1));

#undef ANIM_VEC

	// these anims ought to stay until stopped explicitly by weaponsystem
	e.anim_shoot_z = 0.001;
	e.anim_melee_z = 0.001;
}

const float ANIMPRIO_IDLE = 0;
const float ANIMPRIO_ACTIVE = 1;
const float ANIMPRIO_CROUCH = 2;
const float ANIMPRIO_DEAD = 3;

vector animdecide_getupperanim(entity e)
{
	// death etc.
	if(e.anim_state & ANIMSTATE_FROZEN)
		return vec3(e.anim_idle.x, e.anim_time, ANIMPRIO_DEAD);
	if(e.anim_state & ANIMSTATE_DEAD1)
		return vec3(e.anim_die1_x, e.anim_time, ANIMPRIO_DEAD);
	if(e.anim_state & ANIMSTATE_DEAD2)
		return vec3(e.anim_die2_x, e.anim_time, ANIMPRIO_DEAD);

	// is there an action?
	vector outframe = '-1 0 0';
	float t, a;
	if(e.anim_upper_time >= e.anim_upper_implicit_time)
	{
		a = e.anim_upper_action;
		t = e.anim_upper_time;
	}
	else
	{
		a = e.anim_upper_implicit_action;
		t = e.anim_upper_implicit_time;
	}
	switch(a)
	{
		case ANIMACTION_DRAW: outframe = e.anim_draw; break;
		case ANIMACTION_PAIN1: outframe = e.anim_pain1; break;
		case ANIMACTION_PAIN2: outframe = e.anim_pain2; break;
		case ANIMACTION_SHOOT: outframe = e.anim_shoot; break;
		case ANIMACTION_TAUNT: outframe = e.anim_taunt; break;
		case ANIMACTION_MELEE: outframe = e.anim_melee; break;
	}
	if(outframe.x >= 0)
	{
		if(time <= t + outframe.y / outframe.z)
		{
			// animation is running!
			return vec3(outframe.x, t, ANIMPRIO_ACTIVE);
		}
	}
	// or, decide the anim by state
	t = max(e.anim_time, e.anim_implicit_time);
	// but all states are for lower body!
	return vec3(e.anim_idle.x, t, ANIMPRIO_IDLE);
}

vector animdecide_getloweranim(entity e)
{
	// death etc.
	if(e.anim_state & ANIMSTATE_FOLLOW)
		return vec3(((e.anim_state & ANIMSTATE_DUCK) ? e.anim_duckidle_x : e.anim_idle_x), e.anim_time, ANIMPRIO_DEAD); // dead priority so it's above all
	if(e.anim_state & ANIMSTATE_FROZEN)
		return vec3(e.anim_idle.x, e.anim_time, ANIMPRIO_DEAD);
	if(e.anim_state & ANIMSTATE_DEAD1)
		return vec3(e.anim_die1_x, e.anim_time, ANIMPRIO_DEAD);
	if(e.anim_state & ANIMSTATE_DEAD2)
		return vec3(e.anim_die2_x, e.anim_time, ANIMPRIO_DEAD);

	// is there an action?
	vector outframe = '-1 0 0';
	float t, a;
	if(e.anim_lower_time >= e.anim_lower_implicit_time)
	{
		a = e.anim_lower_action;
		t = e.anim_lower_time;
	}
	else
	{
		a = e.anim_lower_implicit_action;
		t = e.anim_lower_implicit_time;
	}
	switch(a)
	{
		case ANIMACTION_JUMP: if(e.anim_implicit_state & ANIMIMPLICITSTATE_INAIR) { if(e.anim_state & ANIMSTATE_DUCK) outframe = e.anim_duckjump; else outframe = e.anim_jump; } break;
	}
	if(outframe.x >= 0)
	{
		if(time <= t + outframe.y / outframe.z)
		{
			// animation is running!
			return vec3(outframe.x, t, ANIMPRIO_ACTIVE);
		}
	}
	// or, decide the anim by state
	t = max(e.anim_time, e.anim_implicit_time);
	if(e.anim_state & ANIMSTATE_DUCK)
	{
		if(e.anim_implicit_state & ANIMIMPLICITSTATE_INAIR)
			return vec3(e.anim_duckjump.x, 0, ANIMPRIO_CROUCH); // play the END of the jump anim
		else switch(e.anim_implicit_state & (ANIMIMPLICITSTATE_FORWARD | ANIMIMPLICITSTATE_BACKWARDS | ANIMIMPLICITSTATE_LEFT | ANIMIMPLICITSTATE_RIGHT))
		{
			case ANIMIMPLICITSTATE_FORWARD:
				return vec3(e.anim_duckwalk.x, t, ANIMPRIO_CROUCH);
			case ANIMIMPLICITSTATE_BACKWARDS:
				return vec3(e.anim_duckwalkbackwards.x, t, ANIMPRIO_CROUCH);
			case ANIMIMPLICITSTATE_RIGHT:
				return vec3(e.anim_duckwalkstraferight.x, t, ANIMPRIO_CROUCH);
			case ANIMIMPLICITSTATE_LEFT:
				return vec3(e.anim_duckwalkstrafeleft.x, t, ANIMPRIO_CROUCH);
			case ANIMIMPLICITSTATE_FORWARD | ANIMIMPLICITSTATE_RIGHT:
				return vec3(e.anim_duckwalkforwardright.x, t, ANIMPRIO_CROUCH);
			case ANIMIMPLICITSTATE_FORWARD | ANIMIMPLICITSTATE_LEFT:
				return vec3(e.anim_duckwalkforwardleft.x, t, ANIMPRIO_CROUCH);
			case ANIMIMPLICITSTATE_BACKWARDS | ANIMIMPLICITSTATE_RIGHT:
				return vec3(e.anim_duckwalkbackright.x, t, ANIMPRIO_CROUCH);
			case ANIMIMPLICITSTATE_BACKWARDS | ANIMIMPLICITSTATE_LEFT:
				return vec3(e.anim_duckwalkbackleft.x, t, ANIMPRIO_CROUCH);
		}
		return vec3(e.anim_duckidle.x, t, ANIMPRIO_CROUCH);
	}
	else
	{
		if(e.anim_implicit_state & ANIMIMPLICITSTATE_INAIR)
			return vec3(e.anim_jump.x, 0, ANIMPRIO_ACTIVE); // play the END of the jump anim
		else switch(e.anim_implicit_state & (ANIMIMPLICITSTATE_FORWARD | ANIMIMPLICITSTATE_BACKWARDS | ANIMIMPLICITSTATE_LEFT | ANIMIMPLICITSTATE_RIGHT))
		{
			case ANIMIMPLICITSTATE_FORWARD:
				return vec3(e.anim_run.x, t, ANIMPRIO_ACTIVE);
			case ANIMIMPLICITSTATE_BACKWARDS:
				return vec3(e.anim_runbackwards.x, t, ANIMPRIO_ACTIVE);
			case ANIMIMPLICITSTATE_RIGHT:
				return vec3(e.anim_straferight.x, t, ANIMPRIO_ACTIVE);
			case ANIMIMPLICITSTATE_LEFT:
				return vec3(e.anim_strafeleft.x, t, ANIMPRIO_ACTIVE);
			case ANIMIMPLICITSTATE_FORWARD | ANIMIMPLICITSTATE_RIGHT:
				return vec3(e.anim_forwardright.x, t, ANIMPRIO_ACTIVE);
			case ANIMIMPLICITSTATE_FORWARD | ANIMIMPLICITSTATE_LEFT:
				return vec3(e.anim_forwardleft.x, t, ANIMPRIO_ACTIVE);
			case ANIMIMPLICITSTATE_BACKWARDS | ANIMIMPLICITSTATE_RIGHT:
				return vec3(e.anim_backright.x, t, ANIMPRIO_ACTIVE);
			case ANIMIMPLICITSTATE_BACKWARDS | ANIMIMPLICITSTATE_LEFT:
				return vec3(e.anim_backleft.x, t, ANIMPRIO_ACTIVE);
		}
		return vec3(e.anim_idle.x, t, ANIMPRIO_IDLE);
	}
	// can't get here
	//return vec3(e.anim_idle.x, t, ANIMPRIO_IDLE);
}

void animdecide_setimplicitstate(entity e, float onground)
{
	int s = 0;

	makevectors(e.angles);
	vector v;
	v.x = e.velocity * v_forward;
	v.y = e.velocity * v_right;
	v.z = 0;

	// we want to match like this:
	// the 8 directions shall be "evenly spaced"
	// that means, the forward key includes anything from -67.5 to +67.5 degrees
	// which then means x > |y| * cot(3pi/8)
	//
	// BUT, the engine's clip-movement-to-keyboard function uses 0.5 here,
	// which would be an angle range from -63.43 to +63.43 degrees, making
	// it slightly less likely to "hit two keys at once", so let's do this
	// here too

	if(vdist(v, >, 10))
	{
		if(v.x >  fabs(v.y) * 0.5)
			s |= ANIMIMPLICITSTATE_FORWARD;
		if(v.x < -fabs(v.y) * 0.5)
			s |= ANIMIMPLICITSTATE_BACKWARDS;
		if(v.y >  fabs(v.x) * 0.5)
			s |= ANIMIMPLICITSTATE_RIGHT;
		if(v.y < -fabs(v.x) * 0.5)
			s |= ANIMIMPLICITSTATE_LEFT;
	}
	if(!onground)
		s |= ANIMIMPLICITSTATE_INAIR;

	// detect some kinds of otherwise misdetected jumps (ground to air transition)
	// NOTE: currently, in CSQC this is the only jump detection, as the explicit jump action is never called!
	if(!(e.anim_implicit_state & ANIMIMPLICITSTATE_INAIR) && (s & ANIMIMPLICITSTATE_INAIR))
	{
		e.anim_lower_implicit_action = ANIMACTION_JUMP;
		e.anim_lower_implicit_time = time;
	}

	if(s != e.anim_implicit_state)
	{
		e.anim_implicit_state = s;
		e.anim_implicit_time = time;
	}
}
void animdecide_setframes(entity e, float support_blending, .float fld_frame, .float fld_frame1time, .float fld_frame2, .float fld_frame2time)
{
	// _x: frame
	// _y: start time
	// _z: priority
	vector upper = animdecide_getupperanim(e);
	vector lower = animdecide_getloweranim(e);
	//print("UPPER: ", vtos(upper), ", LOWER: ", vtos(lower), "\n");
	if(support_blending)
	{
		if(upper.z && !lower.z)
			lower = upper;
		else if(lower.z && !upper.z)
			upper = lower;
		if(e.frame1time != upper.y || e.frame2time != lower.y)
			BITXOR_ASSIGN(e.effects, EF_RESTARTANIM_BIT);
		e.(fld_frame) = upper.x;
		e.(fld_frame1time) = upper.y;
		e.(fld_frame2) = lower.x;
		e.(fld_frame2time) = lower.y;
	}
	else
	{
		if(upper.z > lower.z)
			lower = upper;
		else if(lower.z > upper.z)
			upper = lower;
		if(e.frame1time != upper.y)
			BITXOR_ASSIGN(e.effects, EF_RESTARTANIM_BIT);
		e.(fld_frame) = upper.x;
		e.(fld_frame1time) = upper.y;
	}
}

void animdecide_setstate(entity e, int newstate, float restart)
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
