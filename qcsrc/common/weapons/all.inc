// ONLY EVER ADD NEW WEAPONS AT THE END. IF YOU REMOVE ONE, PUT THE LAST ONE ON
// ITS PLACE. THIS IS TO AVOID UNNECESSARY RENUMBERING OF WEAPON IMPULSES.
// IF YOU DISREGARD THIS NOTICE, I'LL KILL YOU WITH THE @!#%'N TUBA

// core weapons
#include "weapon/blaster.qh"
#include "weapon/shotgun.qh"
#include "weapon/machinegun.qh"
#include "weapon/mortar.qh"
#include "weapon/minelayer.qh"
#include "weapon/electro.qh"
#include "weapon/crylink.qh"
#include "weapon/vortex.qh"
#include "weapon/hagar.qh"
#include "weapon/devastator.qh"

// other weapons
#include "weapon/porto.qh"
#include "weapon/vaporizer.qh"
#include "weapon/hook.qh"
#include "weapon/hlac.qh"
#include "weapon/tuba.qh"
#include "weapon/rifle.qh"
#include "weapon/fireball.qh"
#include "weapon/seeker.qh"
#include "weapon/arc.qh"

// Weapon registry is sorted to allocate the weapons included above first, update the value below to the number of listed weapons
// TODO: remove eventually in a way that does not cause https://gitlab.com/xonotic/xonotic-data.pk3dir/-/issues/2714
#define WEP_HARDCODED_IMPULSES 19
