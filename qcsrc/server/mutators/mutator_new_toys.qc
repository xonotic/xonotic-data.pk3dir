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
