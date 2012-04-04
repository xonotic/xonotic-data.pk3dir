void thrown_wep_ode_think()
{
	self.nextthink = time;

	self.alpha = self.owner.alpha; // apply fading and ghosting

	if(!self.cnt) // map item, not dropped weapon
	{
		// copy ghost item properties
		self.colormap = self.owner.colormap;
		self.colormod = self.owner.colormod;
		self.glowmod = self.owner.glowmod;
	}

	if(!self.owner.modelindex)
		remove(self); // the real weapon is gone, remove this
}

MUTATOR_HOOKFUNCTION(item_spawning)
{
	if(self.classname != "droppedweapon")
	{
		if(autocvar_g_ode_items <= 1)
			return FALSE;
	}

	// The actual item can't be physical and trigger at the same time, so make it invisible and use a second entity for physics.
	// Ugly hack, but unless SOLID_TRIGGER is gotten to work with MOVETYPE_PHYSICS in the engine it can't be fixed.
	entity wep;
	wep = spawn();
	setmodel(wep, self.model);
	setsize(wep, self.mins, self.maxs);
	setorigin(wep, self.origin);
	wep.angles = self.angles;
	wep.velocity = self.velocity;

	wep.owner = self;
	wep.solid = SOLID_CORPSE;
	wep.movetype = MOVETYPE_PHYSICS;
	wep.takedamage = DAMAGE_AIM;
	wep.effects |= EF_NOMODELFLAGS; // disable the spinning
	wep.colormap = self.owner.colormap;
	wep.glowmod = self.owner.glowmod;
	wep.damageforcescale = autocvar_g_ode_items_damageforcescale;

	wep.think = thrown_wep_ode_think;
	wep.nextthink = time;
	wep.cnt = (self.classname == "droppedweapon");

	self.effects |= EF_NODRAW; // hide the original weapon
	self.movetype = MOVETYPE_FOLLOW;
	self.aiment = wep; // attach the original weapon

	return FALSE;
}

MUTATOR_DEFINITION(mutator_physical_weapons)
{
	if(!autocvar_physics_ode)
		return FALSE;

	MUTATOR_HOOK(Item_Spawn, item_spawning, CBC_ORDER_ANY);

	return FALSE;
}
