#include "hurt.qh"
#ifdef SVQC
void trigger_hurt_use(entity this, entity actor, entity trigger)
{
	if(IS_PLAYER(actor))
		this.enemy = actor;
	else
		this.enemy = world; // let's just destroy it, if taking over is too much work

	if (this.spawnflags & HURT_TOGGLE)
	{
		this.solid = this.solid ? SOLID_NOT : SOLID_TRIGGER;
		setorigin(this, this.origin);
	}
}

void trigger_hurt_touch(entity this, entity toucher)
{
	if (!toucher.takedamage)
		return;
	if (this.active != ACTIVE_ACTIVE)
		return;

	if(this.team)
		if(((this.spawnflags & INVERT_TEAMS) == 0) == (this.team != toucher.team))
			return;

	// only do the EXACTTRIGGER_TOUCH checks when really needed (saves some cpu)
	if (toucher.iscreature)
	{
		if (time >= toucher.dmgtime2 || toucher.last_dmger != this)
		{
			EXACTTRIGGER_TOUCH(this, toucher);
			toucher.dmgtime2 = time + (q3compat && !(this.spawnflags & HURT_SLOW) ? FRAMETIME_Q3 : 1);
			toucher.last_dmger = this;

			entity own = this.enemy;
			if (!IS_PLAYER(own))
			{
				own = this;
				this.enemy = world; // I still hate you all
			}

			Damage (toucher, this, own, this.dmg, DEATH_HURTTRIGGER.m_id, DMG_NOWEP, toucher.origin, '0 0 0');
		}
	}
	else if(toucher.damagedbytriggers)
	{
		EXACTTRIGGER_TOUCH(this, toucher);
		Damage(toucher, this, this, this.dmg, DEATH_HURTTRIGGER.m_id, DMG_NOWEP, toucher.origin, '0 0 0');
	}
}

void trigger_hurt_reset(entity this)
{
	this.solid = this.spawnflags & HURT_START_OFF ? SOLID_NOT : SOLID_TRIGGER;
	setorigin(this, this.origin);
}

/*QUAKED spawnfunc_trigger_hurt (.5 .5 .5) ?
Any object touching this will be hurt
set dmg to damage amount
default dmg = 10000
*/
.entity trigger_hurt_next;
entity trigger_hurt_last;
entity trigger_hurt_first;
spawnfunc(trigger_hurt)
{
	WarpZoneLib_ExactTrigger_Init(this, true, !(this.spawnflags & HURT_START_OFF));
	this.active = ACTIVE_ACTIVE;
	settouch(this, trigger_hurt_touch);
	this.use = trigger_hurt_use;
	this.reset = trigger_hurt_reset;
	this.enemy = world; // I hate you all
	if (!this.dmg)
		this.dmg = ((q3compat) ? 5 : 10000);
	if (this.message == "")
		this.message = "was in the wrong place";
	if (this.message2 == "")
		this.message2 = "was thrown into a world of hurt by";

	if(!trigger_hurt_first)
		trigger_hurt_first = this;
	if(trigger_hurt_last)
		trigger_hurt_last.trigger_hurt_next = this;
	trigger_hurt_last = this;
}

bool tracebox_hits_trigger_hurt(vector start, vector e_min, vector e_max, vector end)
{
	entity th;

	for(th = trigger_hurt_first; th; th = th.trigger_hurt_next)
		if(tracebox_hits_box(start, e_min, e_max, end, th.absmin, th.absmax))
			return true;

	return false;
}
#endif
