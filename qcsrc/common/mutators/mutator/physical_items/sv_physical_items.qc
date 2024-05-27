#include "sv_physical_items.qh"

int autocvar_g_physical_items;
float autocvar_g_physical_items_damageforcescale;
float autocvar_g_physical_items_reset;

REGISTER_MUTATOR(physical_items, autocvar_g_physical_items)
{
	// check if we have a physics engine
	MUTATOR_ONADD
	{
		if (!(autocvar_physics_ode && checkextension("DP_PHYSICS_ODE")))
		{
			LOG_TRACE("Warning: Physical items are enabled but no physics engine can be used. Reverting to old items.");
			return -1;
		}
	}

	MUTATOR_ONROLLBACK_OR_REMOVE
	{
		// nothing to roll back
	}

	MUTATOR_ONREMOVE
	{
		LOG_INFO("This cannot be removed at runtime");
		return -1;
	}

	return 0;
}

.vector spawn_origin, spawn_angles;

void physical_item_think(entity this)
{
	this.nextthink = time;

	this.alpha = this.owner.alpha; // apply fading and ghosting

	if(!this.cnt) // map item, not dropped
	{
		// copy ghost item properties
		this.colormap = this.owner.colormap;
		this.colormod = this.owner.colormod;
		this.glowmod = this.owner.glowmod;

		// if the item is not spawned, make sure the invisible / ghost item returns to its origin and stays there
		if(autocvar_g_physical_items_reset)
		{
			if(this.owner.wait > time) // awaiting respawn
			{
				setorigin(this, this.spawn_origin);
				this.angles = this.spawn_angles;
				this.solid = SOLID_NOT;
				this.alpha = -1;
				set_movetype(this, MOVETYPE_NONE);
			}
			else
			{
				this.alpha = 1;
				this.solid = SOLID_CORPSE;
				set_movetype(this, MOVETYPE_PHYSICS);
			}
		}
	}

	if(!this.owner.modelindex)
		delete(this); // the real item is gone, remove this
}

void physical_item_touch(entity this, entity toucher)
{
	if(!this.cnt) // not for dropped items
	if (ITEM_TOUCH_NEEDKILL())
	{
		setorigin(this, this.spawn_origin);
		this.angles = this.spawn_angles;
	}
}

void physical_item_damage(entity this, entity inflictor, entity attacker, float damage, int deathtype, .entity weaponentity, vector hitloc, vector force)
{
	if(!this.cnt) // not for dropped items
	if(ITEM_DAMAGE_NEEDKILL(deathtype))
	{
		setorigin(this, this.spawn_origin);
		this.angles = this.spawn_angles;
	}
}

MUTATOR_HOOKFUNCTION(physical_items, Item_Spawn)
{
	entity item = M_ARGV(0, entity);

	if(item.owner == NULL && autocvar_g_physical_items <= 1)
		return;
	if (item.spawnflags & 1) // floating item
		return;

	// The actual item can't be physical and trigger at the same time, so make it invisible and use a second entity for physics.
	// Ugly hack, but unless SOLID_TRIGGER is gotten to work with MOVETYPE_PHYSICS in the engine it can't be fixed.
	entity wep = spawn();
	_setmodel(wep, item.model);
	setsize(wep, item.mins, item.maxs);
	setorigin(wep, item.origin);
	wep.angles = item.angles;
	wep.velocity = item.velocity;

	wep.owner = item;
	wep.solid = SOLID_CORPSE;
	set_movetype(wep, MOVETYPE_PHYSICS);
	wep.takedamage = DAMAGE_AIM;
	wep.effects |= EF_NOMODELFLAGS; // disable the spinning
	wep.colormap = item.owner.colormap;
	wep.glowmod = item.owner.glowmod;
	wep.damageforcescale = autocvar_g_physical_items_damageforcescale;
	wep.dphitcontentsmask = item.dphitcontentsmask;
	wep.cnt = (item.owner != NULL);

	setthink(wep, physical_item_think);
	wep.nextthink = time;
	settouch(wep, physical_item_touch);
	wep.event_damage = physical_item_damage;

	if(!wep.cnt)
		DropToFloor_QC_DelayedInit(wep);

	wep.spawn_origin = wep.origin;
	wep.spawn_angles = item.angles;

	item.effects |= EF_NODRAW; // hide the original weapon
	set_movetype(item, MOVETYPE_FOLLOW);
	item.aiment = wep; // attach the original weapon
	setSendEntity(item, func_null);
}
