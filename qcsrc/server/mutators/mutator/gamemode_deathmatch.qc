#ifndef GAMEMODE_DEATHMATCH_H
#define GAMEMODE_DEATHMATCH_H

REGISTER_MUTATOR(dm, false)
{
	MUTATOR_ONADD
	{
		if (time > 1) // game loads at time 1
			error("This is a game type and it cannot be added at runtime.");
	}

	MUTATOR_ONROLLBACK_OR_REMOVE
	{
		// we actually cannot roll back dm_Initialize here
		// BUT: we don't need to! If this gets called, adding always
		// succeeds.
	}

	MUTATOR_ONREMOVE
	{
		error("This is a game type and it cannot be removed at runtime.");
		return -1;
	}

	return 0;
}

#endif

#ifdef IMPLEMENTATION
MUTATOR_HOOKFUNCTION(dm, Scores_CountFragsRemaining)
{
	// announce remaining frags
	return true;
}
#endif
