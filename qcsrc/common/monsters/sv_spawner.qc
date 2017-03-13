#include "sv_spawn.qh"

bool autocvar_g_monster_spawner_copyfields = false; // just incase this gets too nasty

.bool use_trigger_origin;
.float spawn_range; // using a new field here, so as to not interfere with anything monsters might use

void spawner_use(entity this, entity actor, entity trigger)
{
	int moncount = 0;
	IL_EACH(g_monsters, it.realowner == this,
	{
		++moncount;
	});

	if(moncount >= this.count)
		return;

	entity e = spawn();
	if(autocvar_g_monster_spawner_copyfields)
	{
		copyentity(this, e);
		// we don't NEED to reset these, but might as well
		e.classname = "monster";
		e.use = func_null;
		e.count = 0;
	}
	else
	{
		e.noalign = this.noalign;
		e.angles = this.angles;
		e.monster_skill = this.monster_skill;
	}

	vector org = this.origin;
	if(this.use_trigger_origin)
	{
		org = trigger.origin; // TODO: doesn't support brushes
		e.angles = trigger.angles;
	}
	e = spawnmonster(e, this.spawnmob, 0, this, this, org, false, true, this.monster_moveflags);
}

void spawner_trigger_touch(entity this, entity toucher)
{
	if(!toucher.iscreature || IS_DEAD(toucher) || toucher.health < 1)
		return; // only players

	spawner_use(this.owner, toucher, this);
}

void spawner_settargets(entity this)
{
	// if the spawner isn't targeted by anything, create a trigger around it based on its spawn range
	if(this.spawn_range <= 0)
		return;

	IFTARGETED
		return;

	entity trigger = new(spawnertriggerfield);
	set_movetype(trigger, MOVETYPE_NONE);
	trigger.solid = SOLID_TRIGGER;
	trigger.owner = this;
	settouch(trigger, spawner_trigger_touch);

	vector offset = '1 1 1.5' * this.spawn_range;
	setsize(trigger, this.origin - offset, this.origin + offset);
}

spawnfunc(monster_spawner)
{
	if(!autocvar_g_monsters || !this.spawnmob || this.spawnmob == "") { delete(this); return; }

	this.use = spawner_use;

	if(!this.spawn_range)
		this.spawn_range = 500; // default it so we can work without targets

	InitializeEntity(this, spawner_settargets, INITPRIO_FINDTARGET);
}
