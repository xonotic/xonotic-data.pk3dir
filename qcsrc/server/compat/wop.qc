#include "wop.qh"

#include <common/stats.qh>
#include <common/mutators/mutator/powerups/_mod.qh>
#include <common/weapons/_all.qh>
#include <server/items/spawning.qh>

spawnfunc(item_speed);
spawnfunc(item_invisibility);

//***********************
//WORLD OF PADMAN ENTITIES - So people can play wop maps with the xonotic weapons
//***********************

//spawnfunc(item_revival)     /* handled by buffs mutator */
//spawnfunc(item_jumper)      /* handled by buffs mutator */

SPAWNFUNC_WEAPON(weapon_punchy, WEP_ARC)
SPAWNFUNC_WEAPON(weapon_nipper, WEP_MACHINEGUN)
SPAWNFUNC_WEAPON(weapon_pumper, WEP_SHOTGUN)
SPAWNFUNC_WEAPON(weapon_boaster, WEP_ELECTRO)
SPAWNFUNC_WEAPON(weapon_splasher, WEP_VORTEX)
SPAWNFUNC_WEAPON(weapon_bubbleg, WEP_HAGAR)
SPAWNFUNC_WEAPON(weapon_balloony, WEP_MORTAR)
SPAWNFUNC_WEAPON(weapon_betty, WEP_DEVASTATOR)
SPAWNFUNC_WEAPON(weapon_imperius, WEP_CRYLINK)

SPAWNFUNC_ITEM(ammo_pumper, ITEM_Shells)
SPAWNFUNC_ITEM(ammo_nipper, ITEM_Bullets)
SPAWNFUNC_ITEM(ammo_balloony, ITEM_Rockets)
SPAWNFUNC_ITEM(ammo_bubbleg, ITEM_Rockets)
SPAWNFUNC_ITEM(ammo_boaster, ITEM_Cells)
SPAWNFUNC_ITEM(ammo_betty, ITEM_Rockets)
SPAWNFUNC_ITEM(ammo_imperius, ITEM_Cells)

SPAWNFUNC_ITEM(item_padpower, ITEM_Strength)
SPAWNFUNC_ITEM(item_climber, ITEM_Shield)
spawnfunc(item_speedy)		{ spawnfunc_item_speed(this);			}
spawnfunc(item_visionless)	{ spawnfunc_item_invisibility(this);			}
SPAWNFUNC_ITEM(item_armor_padshield, ITEM_ArmorMega)

SPAWNFUNC_ITEM(holdable_floater, ITEM_Jetpack)
