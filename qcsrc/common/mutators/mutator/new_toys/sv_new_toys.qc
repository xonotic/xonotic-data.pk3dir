#include "sv_new_toys.qh"

#include "new_toys.qh"

#include "../random_items/sv_random_items.qh"
#include <server/weapons/spawning.qh>

/*

CORE    laser   vortex     lg      rl      cry     gl      elec    hagar   fireb   hook
									vaporizer  porto
									tuba

NEW             rifle   hlac    minel                           seeker
IDEAS                                   OPEN    flak    OPEN            FUN FUN FUN FUN



How this mutator works:
 =======================

When a gun tries to spawn, this mutator is called. It will provide alternate
weaponreplace lists.

Entity:

{
"classname" "weapon_vortex"
"new_toys" "rifle"
}
-> This will spawn as Rifle in this mutator ONLY, and as Vortex otherwise.

{
"classname" "weapon_vortex"
"new_toys" "vortex rifle"
}
-> This will spawn as either Vortex or Rifle in this mutator ONLY, and as Vortex otherwise.

{
"classname" "weapon_vortex"
"new_toys" "vortex"
}
-> This is always a Vortex.

If the map specifies no "new_toys" argument

There will be two default replacements selectable: "replace all" and "replace random".
In "replace all" mode, e.g. Vortex will have the default replacement "rifle".
In "replace random" mode, Vortex will have the default replacement "vortex rifle".

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

This mutator performs the default replacements on the DEFAULTS of the
start weapon selection.

These weapons appear in the menu's priority list, BUT get a suffix
"(Mutator weapon)".

Picking up a "new toys" weapon will not play standard weapon pickup sound, but
roflsound "New toys, new toys!" sound.

*/

//string autocvar_g_new_toys;

REGISTER_MUTATOR(nt, expr_evaluate(cvar_string("g_new_toys")) && !MUTATOR_IS_ENABLED(mutator_instagib) && !MUTATOR_IS_ENABLED(ok))
{
	MUTATOR_ONADD
	{
		if(time > 1) // game loads at time 1
			error("This cannot be added at runtime\n");

		// mark the guns as ok to use by e.g. impulse 99
		FOREACH(Weapons, it != WEP_Null, {
			if(nt_IsNewToy(it.m_id))
				it.spawnflags &= ~WEP_FLAG_MUTATORBLOCKED;
		});
	}

	MUTATOR_ONROLLBACK_OR_REMOVE
	{
		FOREACH(Weapons, it != WEP_Null, {
			if(nt_IsNewToy(it.m_id))
				it.spawnflags |= WEP_FLAG_MUTATORBLOCKED;
		});
	}

	MUTATOR_ONREMOVE
	{
		LOG_INFO("This cannot be removed at runtime");
		return -1;
	}

	return 0;
}

.string new_toys;

float autocvar_g_new_toys_autoreplace;
bool autocvar_g_new_toys_use_pickupsound = false;
const float NT_AUTOREPLACE_NEVER = 0;
const float NT_AUTOREPLACE_ALWAYS = 1;
const float NT_AUTOREPLACE_RANDOM = 2;

string nt_GetFullReplacement(string w)
{
	switch(w)
	{
		case "hagar": return "seeker";
		case "devastator": return "minelayer";
		case "machinegun": return "hlac";
		case "vortex": return "rifle";
		default: return string_null;
	}
}

string nt_GetReplacement(string w, float m)
{
	if(m == NT_AUTOREPLACE_NEVER)
		return w;
	string s = nt_GetFullReplacement(w);
	if (!s)
		return w;
	if(m == NT_AUTOREPLACE_RANDOM)
		s = strcat(w, " ", s);
	return s;
}

MUTATOR_HOOKFUNCTION(nt, SetStartItems)
{
	// rearrange start_weapon_default
	// apply those bits that are set by start_weapon_defaultmask
	// same for warmup

	float j, n;

	WepSet newdefault;
	WepSet warmup_newdefault;

	newdefault = '0 0 0';
	warmup_newdefault = '0 0 0';

	WepSet seti = '0 0 0';

	FOREACH(Weapons, it != WEP_Null, {
		seti = it.m_wepset;
		n = tokenize_console(nt_GetReplacement(it.netname, autocvar_g_new_toys_autoreplace));

		for(j = 0; j < n; ++j)
			FOREACH(Weapons, it != WEP_Null, {
				if(it.netname == argv(j))
				{
					WepSet setk = it.m_wepset;
					if(start_weapons & seti) newdefault |= setk;
					if(warmup_start_weapons & seti) warmup_newdefault |= setk;
				}
			});
	});

	newdefault &= start_weapons_defaultmask;
	start_weapons &= ~start_weapons_defaultmask;
	start_weapons |= newdefault;

	warmup_newdefault &= warmup_start_weapons_defaultmask;
	warmup_start_weapons &= ~warmup_start_weapons_defaultmask;
	warmup_start_weapons |= warmup_newdefault;
}

MUTATOR_HOOKFUNCTION(nt, SetWeaponreplace)
{
	if (MUTATOR_IS_ENABLED(random_items))
	{
		// Do not replace weapons when random items are enabled.
		return;
	}
	entity wep = M_ARGV(0, entity);
	entity wepinfo = M_ARGV(1, entity);
	string ret_string = M_ARGV(2, string);

	// otherwise, we do replace
	if(wep.new_toys)
	{
		// map defined replacement:
		ret_string = wep.new_toys;
	}
	else
	{
		// auto replacement:
		ret_string = nt_GetReplacement(wepinfo.netname, autocvar_g_new_toys_autoreplace);
	}

	// apply regular weaponreplace
	ret_string = W_Apply_Weaponreplace(ret_string);

	M_ARGV(2, string) = ret_string;
}

MUTATOR_HOOKFUNCTION(nt, FilterItem)
{
	entity item = M_ARGV(0, entity);

	if(nt_IsNewToy(item.weapon) && autocvar_g_new_toys_use_pickupsound) {
		item.item_pickupsound = string_null;
		item.item_pickupsound_ent = SND_WEAPONPICKUP_NEW_TOYS;
	}
}
