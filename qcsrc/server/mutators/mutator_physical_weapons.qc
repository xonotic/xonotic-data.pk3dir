MUTATOR_HOOKFUNCTION(item_spawning)
{
	dprint("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n");

	return 0;
}

MUTATOR_DEFINITION(mutator_physical_weapons)
{
	MUTATOR_HOOK(Item_Spawn, item_spawning, CBC_ORDER_ANY);

	return 0;
}
