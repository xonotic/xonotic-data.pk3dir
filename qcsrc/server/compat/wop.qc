#include "wop.qh"

#include <common/weapons/_all.qh>
// #include <server/mutators/gamemode.qh>

spawnfunc(weapon_arc);
spawnfunc(weapon_crylink);
spawnfunc(weapon_electro);
spawnfunc(weapon_mortar);
spawnfunc(weapon_hagar);
spawnfunc(weapon_machinegun);
spawnfunc(weapon_devastator);
spawnfunc(weapon_shotgun);
spawnfunc(weapon_vortex);

spawnfunc(item_armor_big);
spawnfunc(item_armor_mega);
spawnfunc(item_armor_small);

spawnfunc(item_bullets);
spawnfunc(item_cells);
spawnfunc(item_quad);
spawnfunc(item_rockets);
spawnfunc(item_shells);

spawnfunc(item_jetpack);

spawnfunc(item_haste);
spawnfunc(item_health_medium);
spawnfunc(item_health_mega);
spawnfunc(item_invis);

//***********************
//WORD OF PADMAN ENTITIES - So people can play wop maps with the xonotic weapons
//***********************

//spawnfunc(item_revival)     /* handled by buffs mutator */
//spawnfunc(item_jumper)      /* handled by buffs mutator */

spawnfunc(weapon_punchy)	{ spawnfunc_weapon_arc(this);			}
spawnfunc(weapon_nipper)	{ spawnfunc_weapon_machinegun(this);	}
spawnfunc(weapon_pumper)	{ spawnfunc_weapon_shotgun(this);		}
spawnfunc(weapon_boaster)	{ spawnfunc_weapon_electro(this);		}
spawnfunc(weapon_splasher)	{ spawnfunc_weapon_vortex(this);		}
spawnfunc(weapon_bubbleg)	{ spawnfunc_weapon_hagar(this);			}
spawnfunc(weapon_balloony)	{ spawnfunc_weapon_mortar(this);		}
spawnfunc(weapon_betty)		{ spawnfunc_weapon_devastator(this);	}
spawnfunc(weapon_imperius)	{ spawnfunc_weapon_crylink(this);		}

spawnfunc(ammo_pumper)		{ spawnfunc_item_shells(this);			}
spawnfunc(ammo_nipper)		{ spawnfunc_item_bullets(this);			}
spawnfunc(ammo_balloony)	{ spawnfunc_item_rockets(this);			}
spawnfunc(ammo_bubbleg)		{ spawnfunc_item_rockets(this);			}
spawnfunc(ammo_boaster)		{ spawnfunc_item_cells(this);			}
spawnfunc(ammo_betty)		{ spawnfunc_item_rockets(this);			}
spawnfunc(ammo_imperius)	{ spawnfunc_item_cells(this);			}

spawnfunc(item_padpower)	{ spawnfunc_item_quad(this);			}
spawnfunc(item_climber)		{ spawnfunc_item_invincible(this);		}
spawnfunc(item_speedy)		{ spawnfunc_item_haste(this);			}
spawnfunc(item_visionless)	{ spawnfunc_item_invis(this);			}
spawnfunc(item_armor_padshield)	{ spawnfunc_item_armor_mega(this);	}

spawnfunc(holdable_floater)		{ spawnfunc_item_jetpack(this);		}
