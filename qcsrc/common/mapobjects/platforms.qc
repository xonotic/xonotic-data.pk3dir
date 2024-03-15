#include "platforms.qh"

void generic_plat_blocked(entity this, entity blocker)
{
#ifdef SVQC
	if(this.dmg && blocker.takedamage != DAMAGE_NO)
	{
		if(this.dmgtime2 < time)
		{
			Damage (blocker, this, this, this.dmg, DEATH_HURTTRIGGER.m_id, DMG_NOWEP, blocker.origin, '0 0 0');
			this.dmgtime2 = time + this.dmgtime;
		}

		// Gib dead/dying stuff
		if(IS_DEAD(blocker))
			Damage (blocker, this, this, 10000, DEATH_HURTTRIGGER.m_id, DMG_NOWEP, blocker.origin, '0 0 0');
	}
#endif
}

void plat_spawn_inside_trigger(entity this)
{
	vector tmin, tmax;

	entity trigger = spawn();
	settouch(trigger, plat_center_touch);
	set_movetype(trigger, MOVETYPE_NONE);
	trigger.solid = SOLID_TRIGGER;
	trigger.enemy = this;

	tmin = this.absmin + '25 25 0';
	tmax = this.absmax - '25 25 -8';
	tmin_z = tmax_z - (this.pos1_z - this.pos2_z + 8);
	if (this.spawnflags & PLAT_LOW_TRIGGER)
		tmax_z = tmin_z + 8;

	if (this.size_x <= 50)
	{
		tmin_x = (this.mins_x + this.maxs_x) / 2;
		tmax_x = tmin_x + 1;
	}
	if (this.size_y <= 50)
	{
		tmin_y = (this.mins_y + this.maxs_y) / 2;
		tmax_y = tmin_y + 1;
	}

	if(tmin_x < tmax_x)
		if(tmin_y < tmax_y)
			if(tmin_z < tmax_z)
			{
				setsize (trigger, tmin, tmax);
				return;
			}

	// otherwise, something is fishy...
	delete(trigger);
	objerror(this, "plat_spawn_inside_trigger: platform has odd size or lip, can't spawn");
}

void plat_hit_top(entity this)
{
	_sound (this, CH_TRIGGER_SINGLE, this.noise1, VOL_BASE, ATTEN_NORM);
	this.state = STATE_TOP;

	setthink(this, plat_go_down);
	this.nextthink = this.ltime + 3;
}

void plat_hit_bottom(entity this)
{
	_sound (this, CH_TRIGGER_SINGLE, this.noise1, VOL_BASE, ATTEN_NORM);
	this.state = STATE_BOTTOM;
}

void plat_go_down(entity this)
{
	_sound (this, CH_TRIGGER_SINGLE, this.noise, VOL_BASE, ATTEN_NORM);
	this.state = STATE_DOWN;
	SUB_CalcMove (this, this.pos2, TSPEED_LINEAR, this.speed, plat_hit_bottom);
}

void plat_go_up(entity this)
{
	_sound (this, CH_TRIGGER_SINGLE, this.noise, VOL_BASE, ATTEN_NORM);
	this.state = STATE_UP;
	SUB_CalcMove (this, this.pos1, TSPEED_LINEAR, this.speed, plat_hit_top);
}

void plat_center_touch(entity this, entity toucher)
{
#ifdef SVQC
	if (!toucher.iscreature)
		return;

	if (GetResource(toucher, RES_HEALTH) <= 0)
		return;
#elif defined(CSQC)
	if (!IS_PLAYER(toucher))
		return;
	if(IS_DEAD(toucher))
		return;
#endif

	if (this.enemy.state == STATE_BOTTOM) {
		plat_go_up(this.enemy);
	} else if (this.enemy.state == STATE_TOP)
		this.enemy.nextthink = this.enemy.ltime + 1;
}

void plat_outside_touch(entity this, entity toucher)
{
#ifdef SVQC
	if (!toucher.iscreature)
		return;

	if (GetResource(toucher, RES_HEALTH) <= 0)
		return;
#elif defined(CSQC)
	if (!IS_PLAYER(toucher))
		return;
#endif

	if (this.enemy.state == STATE_TOP) {
	    entity e = this.enemy;
		plat_go_down(e);
    }
}

void plat_trigger_use(entity this, entity actor, entity trigger)
{
	if (getthink(this))
		return;		// already activated
	plat_go_down(this);
}


void plat_crush(entity this, entity blocker)
{
	if((this.spawnflags & CRUSH) && (blocker.takedamage != DAMAGE_NO))
	{ // KIll Kill Kill!!
#ifdef SVQC
		Damage (blocker, this, this, 10000, DEATH_HURTTRIGGER.m_id, DMG_NOWEP, blocker.origin, '0 0 0');
#endif
	}
	else
	{
#ifdef SVQC
		if((this.dmg) && (blocker.takedamage != DAMAGE_NO))
		{   // Shall we bite?
			Damage (blocker, this, this, this.dmg, DEATH_HURTTRIGGER.m_id, DMG_NOWEP, blocker.origin, '0 0 0');
			// Gib dead/dying stuff
			if(IS_DEAD(blocker))
				Damage (blocker, this, this, 10000, DEATH_HURTTRIGGER.m_id, DMG_NOWEP, blocker.origin, '0 0 0');
		}
#endif

		if (this.state == STATE_UP)
			plat_go_down (this);
		else if (this.state == STATE_DOWN)
			plat_go_up (this);
	// when in other states, then the plat_crush event came delayed after
	// plat state already had changed
	// this isn't a bug per se!
	}
}

void plat_use(entity this, entity actor, entity trigger)
{
	this.use = func_null;
	if (this.state != STATE_UP)
		objerror (this, "plat_use: not in up state");
	plat_go_down(this);
}

void plat_target_use(entity this, entity actor, entity trigger)
{
	if (this.state == STATE_TOP)
		this.nextthink = this.ltime + 1;
	else if (this.state != STATE_UP)
		plat_go_up(this);
}

// WARNING: backwards compatibility because people don't use already existing fields :(
// TODO: Check if any maps use these fields and remove these fields if it doesn't break maps
.string sound1, sound2;

void plat_reset(entity this)
{
	if (this.targetname && this.targetname != "" && !Q3COMPAT_COMMON)
	{
		setorigin(this, this.pos1);
		this.state = STATE_UP;
		this.use = plat_use;
	}
	else
	{
		setorigin(this, this.pos2);
		this.state = STATE_BOTTOM;
		this.use = (this.targetname != "" && Q3COMPAT_COMMON) ? plat_target_use : plat_trigger_use;
	}

#ifdef SVQC
	this.SendFlags |= SF_TRIGGER_RESET;
#endif
}

.float platmovetype_start_default, platmovetype_end_default;
bool set_platmovetype(entity e, string s)
{
	// sets platmovetype_start and platmovetype_end based on a string consisting of two values

	int n = tokenize_console(s);
	if(n > 0)
		e.platmovetype_start = stof(argv(0));
	else
		e.platmovetype_start = 0;

	if(n > 1)
		e.platmovetype_end = stof(argv(1));
	else
		e.platmovetype_end = e.platmovetype_start;

	if(n > 2)
		if(argv(2) == "force")
			return true; // no checking, return immediately

	if(!cubic_speedfunc_is_sane(e.platmovetype_start, e.platmovetype_end))
	{
		objerror(e, "Invalid platform move type; platform would go in reverse, which is not allowed.");
		return false;
	}

	return true;
}
