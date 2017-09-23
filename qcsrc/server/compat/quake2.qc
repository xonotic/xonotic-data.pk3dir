#include "quake2.qh"

spawnfunc(item_armor_medium);

spawnfunc(item_invincible);


// ***********************
// QUAKE 2 ENTITIES - So people can play quake2 maps with the xonotic weapons
// ***********************
spawnfunc(item_armor_jacket)
{
	spawnfunc_item_armor_medium(this);
}

spawnfunc(item_invulnerability)
{
	spawnfunc_item_invincible(this);
}

// rest of the quake 2 entities are handled by q1 and q3 compat
