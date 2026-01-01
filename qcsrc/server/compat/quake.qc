#include "quake.qh"

#include <common/stats.qh>
#include <common/weapons/_all.qh>
#include <common/weapons/_all.qh>

/***********************
 * QUAKE 1 ENTITIES - So people can play quake1 maps with the xonotic weapons
 ***********************
 weapon_nailgun handled in quake3.qc
 item_armor1 handled in items/spawning.qc
*/

SPAWNFUNC_WEAPON(weapon_supernailgun, WEP_HAGAR)
SPAWNFUNC_WEAPON(weapon_supershotgun, WEP_MACHINEGUN)

SPAWNFUNC_ITEM(item_spikes, ITEM_Bullets)
SPAWNFUNC_ITEM(item_armor2, ITEM_ArmorMega)
SPAWNFUNC_ITEM(item_armorInv, ITEM_ArmorMega) // TODO: make sure we actually want this
SPAWNFUNC_ITEM(item_health, this.spawnflags & 2 ? ITEM_HealthMega : ITEM_HealthMedium)
