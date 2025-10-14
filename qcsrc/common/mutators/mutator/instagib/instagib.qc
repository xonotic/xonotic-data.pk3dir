#include "instagib.qh"

#ifdef MENUQC
#include "items.qh"
#include "../powerups/powerup/speed.qh"
#include "../powerups/powerup/invisibility.qh"
#include <common/gametypes/gametype/deathmatch/deathmatch.qh>
#include <common/items/item/ammo.qh>
#include <common/weapons/weapon/vaporizer.qh>

METHOD(MutatorInstagib, describe, string(MutatorInstagib this))
{
	TC(MutatorInstagib, this);
	PAGE_TEXT_INIT();
	PAR(_("%s is a mutator that removes all weapons and weapon pickups from the map, instead giving players the %s, "
	      "which immediately frags players in a single shot, hence the name \"InstaGib.\""), COLORED_NAME(this), COLORED_NAME(WEP_VAPORIZER));
	PAR(_("Precise aim and ammo conservation are important, since you will suicide after 10 seconds if you run out of ammo. "
	      "Ammo (%s) can be picked up on the map often, or collected from dropped %s guns."), COLORED_NAME(ITEM_Cells), COLORED_NAME(WEP_VAPORIZER));
	PAR(_("Maps often have an %s on them, which will save you from being fragged when picked up (total extra lives is displayed as armor). "
	      "Other powerups often present on maps include %s and %s."), COLORED_NAME(ITEM_ExtraLife), COLORED_NAME(ITEM_Speed), COLORED_NAME(ITEM_Invisibility));
	PAR(_("It is quite a common mutator present on many servers, mixing well with a lot of gametypes but particularly %s. "
	      "Sometimes it's enabled alongside other mutators such as %s for added movement possibilities."), COLORED_NAME(MAPINFO_TYPE_DEATHMATCH), COLORED_NAME(MUTATOR_hook));
	return PAGE_TEXT;
}
#endif
