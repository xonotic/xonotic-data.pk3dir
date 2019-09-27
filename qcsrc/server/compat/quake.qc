#include "quake.qh"

#include <server/defs.qh>
#include <server/miscfunctions.qh>
#include <common/weapons/_all.qh>

//***********************
//QUAKE 1 ENTITIES - So people can play quake1 maps with the xonotic weapons
//***********************
SPAWNFUNC_WEAPON(weapon_nailgun, WEP_ELECTRO)
SPAWNFUNC_WEAPON(weapon_supernailgun, WEP_HAGAR)
SPAWNFUNC_WEAPON(weapon_supershotgun, WEP_MACHINEGUN)

SPAWNFUNC_ITEM(item_spikes, ITEM_Bullets)
//spawnfunc(item_armor1) {spawnfunc_item_armor_medium(this);}  // FIXME: in Quake this is green armor, in Xonotic maps it is an armor shard
SPAWNFUNC_ITEM(item_armor2, ITEM_ArmorMega)
SPAWNFUNC_ITEM(item_armorInv, ITEM_ArmorMega) // TODO: make sure we actually want this
SPAWNFUNC_ITEM_COND(item_health, (this.spawnflags & 2), ITEM_HealthMega, ITEM_HealthMedium)
