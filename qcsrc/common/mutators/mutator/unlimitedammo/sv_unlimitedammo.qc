#include "sv_unlimitedammo.qh"

bool autocvar_g_unlimitedammo_remove_loot;

REGISTER_MUTATOR(unlimitedammo, cvar("g_unlimitedammo"));
MUTATOR_HOOKFUNCTION(unlimitedammo, SetStartItems)
{
	start_items |= IT_UNLIMITED_AMMO;
}

MUTATOR_HOOKFUNCTION(unlimitedammo, FilterItem)
{
	entity item = M_ARGV(0, entity);

	//Check is item a loot and is item a weapon
	if (autocvar_g_unlimitedammo_remove_loot && Item_IsLoot(item) && item.itemdef.instanceOfWeaponPickup) {
		// remove(item); //Hmm interesting, when use return true, weapon doesn't spawns, but if remove returning line, and uncomment this, it sends a lot of error when kill bot
		return true;
	}
}