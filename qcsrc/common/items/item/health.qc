#include "health.qh"

#ifdef MENUQC
#include <common/gamemodes/gamemode/duel/duel.qh>

METHOD(HealthSmall, describe, string(HealthSmall this))
{
    TC(HealthSmall, this);
    return sprintf(_("The %s restores a small amount of health when picked up, "
        "helping you recover from damage taken during combat."),
    COLORED_NAME(this));
}

METHOD(HealthMedium, describe, string(HealthMedium this))
{
    TC(HealthMedium, this);
    return sprintf(_("The %s restores a medium amount of health when picked up, "
        "helping you recover from damage taken during combat."),
    COLORED_NAME(this));
}

METHOD(HealthBig, describe, string(HealthBig this))
{
    TC(HealthBig, this);
    return sprintf(_("The %s restores a large amount of health when picked up, "
        "helping you recover from damage taken during combat."),
    COLORED_NAME(this));
}

METHOD(HealthMega, describe, string(HealthMega this))
{
    TC(HealthMega, this);
    return sprintf(_("The %s restores a huge amount of health when picked up, "
        "helping you recover from damage taken during combat.\n\n"
        "It tends to be one of the most highly contested items on a map, particularly in game modes like %s."),
    COLORED_NAME(this), COLORED_NAME(MAPINFO_TYPE_DUEL));
}
#endif
