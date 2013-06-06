float gravity_delay;
float old_gravity;
MUTATOR_HOOKFUNCTION(gravity_StartFrame)
{
	if(gameover || !cvar("g_random_gravity"))
	{
		if(autocvar_sv_gravity != old_gravity)
		{
			cvar_set("sv_gravity", ftos(old_gravity));
			old_gravity = autocvar_sv_gravity; // update now so it can be changed during match end
		}
		
		return FALSE;
	}
		
	if(time < gravity_delay) return FALSE;
	if(time < game_starttime) return FALSE;
	if(round_handler_IsActive() && !round_handler_IsRoundStarted()) return FALSE;
	
    if(random() >= autocvar_g_random_gravity_negative_chance) 
        cvar_set("sv_gravity", ftos(bound(autocvar_g_random_gravity_min, random() - random() * -autocvar_g_random_gravity_negative, autocvar_g_random_gravity_max)));
    else
        cvar_set("sv_gravity", ftos(bound(autocvar_g_random_gravity_min, random() * autocvar_g_random_gravity_positive, autocvar_g_random_gravity_max)));
	
	gravity_delay = time + autocvar_g_random_gravity_delay;
	
	dprint("Gravity is now: ", ftos(autocvar_sv_gravity), "\n");
	
	return FALSE;
}

MUTATOR_HOOKFUNCTION(gravity_BuildMutatorsString)
{
	ret_string = strcat(ret_string, ":RandomGravity");
	return 0;
}

MUTATOR_HOOKFUNCTION(gravity_BuildMutatorsPrettyString)
{
	ret_string = strcat(ret_string, ", Random gravity");
	return 0;
}

MUTATOR_DEFINITION(mutator_random_gravity)
{
	MUTATOR_HOOK(SV_StartFrame, gravity_StartFrame, CBC_ORDER_ANY);
	MUTATOR_HOOK(BuildMutatorsString, gravity_BuildMutatorsString, CBC_ORDER_ANY);
	MUTATOR_HOOK(BuildMutatorsPrettyString, gravity_BuildMutatorsPrettyString, CBC_ORDER_ANY);
	
	MUTATOR_ONADD
	{
		old_gravity = autocvar_sv_gravity;
	}
	
	MUTATOR_ONREMOVE
	{
		cvar_set("sv_gravity", ftos(old_gravity));
	}

	return FALSE;
}
