#include "items.qh"

#ifdef MENUQC
#include "instagib.qh"
#include <common/weapons/weapon/vaporizer.qh>

METHOD(VaporizerCells, describe, string(VaporizerCells this))
{
    TC(VaporizerCells, this);
    return sprintf(_("The %s is sometimes present on maps when %s is enabled, providing ammo for the %s"),
    COLORED_NAME(this), COLORED_NAME(MUTATOR_mutator_instagib), COLORED_NAME(WEP_VAPORIZER));
}

METHOD(ExtraLife, describe, string(ExtraLife this))
{
    TC(ExtraLife, this);
    return sprintf(_("The %s powerup acts as armor in %s. "
        "If a player is shot while having one or more extra lives, they will survive the shot but suffer strong knockback"),
    COLORED_NAME(this), COLORED_NAME(MUTATOR_mutator_instagib));
}
#endif
