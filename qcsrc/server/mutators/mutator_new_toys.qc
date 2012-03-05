/*

CORE    laser   nex     lg      rl      cry     gl      elec    hagar   fireb   hook
									minsta  porto
									tuba

NEW             rifle   hlac    minel                           seeker   
IDEAS                                   OPEN    flak    OPEN            FUN FUN FUN FUN



How this mutator works:
 =======================

When a gun tries to spawn, this mutator is called. It will provide alternate
default values of weaponreplace lists.

Entity:

{
"classname" "weapon_nex"
"new_toys" "rifle"
}
-> This will spawn as Rifle in this mutator ONLY, and as Nex otherwise.

{
"classname" "weapon_nex"
"new_toys" "nex rifle"
}
-> This will spawn as either Nex or Rifle in this mutator ONLY, and as Nex otherwise.

{
"classname" "weapon_nex"
"new_toys" "nex"
}
-> This is always a Nex.

If the map specifies no "new_toys" argument

There will be two default replacements selectable: "replace all" and "replace random".
In "replace all" mode, e.g. Nex will have the default replacement "rifle".
In "replace random" mode, Nex will have the default replacement "nex rifle".

This mutator's replacements run BEFORE regular weaponreplace!

The New Toys guns do NOT get a spawn function, so they can only ever be spawned
when this mutator is active.

Likewise, warmup, give all, give ALL and impulse 99 will not give them unless
this mutator is active.

Outside this mutator, they still can be spawned by:
- setting their start weapon cvar to 1
- give weaponname
- weaponreplace
- weaponarena (but all and most weapons arena again won't include them)

Also, this mutator performs the default replacements on the DEFAULTS of the
start weapon selection.

Also: these weapons appear in the menu's priority list, BUT get a suffix
"(Mutator weapon)".

Picking up a "new toys" weapon will not play standard weapon pickup sound, but
roflsound "New toys, new toys!" sound.

*/

string i_herd_yo_liek_weaponreplace(string replacement)
{
	string newlist;
	float n = tokenize_console(replacement);
	string out = "";
	for(i = 0; i < n; ++i)
	{
		string s = argv(i);
		string r = cvar_string(strcat("g_weaponreplace_", s));
		if(r == "")
			out = strcat(out, " ", s);
		else if(r != "0")
			out = strcat(out, " ", r);
	}
	return substring(out, 1);
}

MUTATOR_HOOKFUNCTION(nt_SetModname)
{
	modname = "NewToys";
	return 0;
}

MUTATOR_HOOKFUNCTION(nt_SetStartItems)
{
	// rearrange start_weapon_default
	// apply those bits that are set by start_weapon_defaultmask
	// same for warmup
	// TODO
	return 0;
}

MUTATOR_DEFINITION(mutator_new_toys)
{
	MUTATOR_HOOK(SetModname, nt_SetModname, CBC_ORDER_ANY);
	MUTATOR_HOOK(SetStartItems, nix_SetStartItems, CBC_ORDER_ANY);

	MUTATOR_ONADD
	{
		if(time > 1) // game loads at time 1
			error("This cannot be added at runtime\n");
	}
	MUTATOR_ONREMOVE
	{
		error("This cannot be removed at runtime\n");
	}

	return 0;
}
