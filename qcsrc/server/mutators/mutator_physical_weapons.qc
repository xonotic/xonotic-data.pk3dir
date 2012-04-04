void thrown_wep_ode_think()
{
	self.nextthink = time;
	if(!self.owner.modelindex)
		remove(self); // the real weapon is gone, remove this
}

MUTATOR_HOOKFUNCTION(item_spawning)
{
	if(!autocvar_physics_ode)
		return FALSE;
	if(self.classname != "droppedweapon")
		return FALSE;

	// make the dropped weapon physical
	entity wep;
	wep = spawn();
	setsize(wep, self.mins, self.maxs);
	setorigin(wep, self.origin);
	wep.angles = self.angles;
	wep.velocity = self.velocity;

	wep.classname = "droppedweapon2";
	wep.owner = self;
	wep.solid = SOLID_CORPSE;
	wep.movetype = MOVETYPE_PHYSICS;
	wep.takedamage = DAMAGE_AIM;
	wep.damageforcescale = autocvar_g_ode_weapons_damageforcescale;

	wep.think = thrown_wep_ode_think;
	wep.nextthink = time;

	self.effects |= EF_NOMODELFLAGS; // disable the spinning
	self.movetype = MOVETYPE_FOLLOW;
	self.aiment = wep;

	return FALSE;
}

MUTATOR_DEFINITION(mutator_physical_weapons)
{
	MUTATOR_HOOK(Item_Spawn, item_spawning, CBC_ORDER_ANY);

	return FALSE;
}
