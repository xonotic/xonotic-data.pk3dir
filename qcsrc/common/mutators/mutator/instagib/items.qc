#include "items.qh"

#ifdef MENUQC
METHOD(VaporizerCells, describe, string(VaporizerCells this))
{
    // can't include common/weapons/weapon/vaporizer.qh or else circular includes
#define VAPORIZER_COLOR strcat(rgb_to_hexcolor(COLOR_WEP_VAPORIZER), _("Vaporizer"), "^7")
    TC(VaporizerCells, this);
    return sprintf(_("The %s is sometimes present on maps when InstaGib is enabled, providing ammo for the %s"),
    COLORED_NAME(VaporizerCells), VAPORIZER_COLOR);
#undef VAPORIZER_COLOR
}

METHOD(ExtraLife, describe, string(ExtraLife this))
{
    TC(ExtraLife, this);
    return sprintf(_("The %s powerup acts as armor in InstaGib. "
        "If a player is shot while having one or more extra lives, they will survive the shot but suffer strong knockback"),
    COLORED_NAME(ExtraLife));
}
#endif
