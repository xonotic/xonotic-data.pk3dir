#include "health.qh"

#ifdef MENUQC
#include <common/gamemodes/gamemode/duel/duel.qh>

#define DEFAULT_PICKUP_HEALTH(s) \
	sprintf(_("By default, the pickup gives you %s health."), cvar_defstring(strcat("g_pickup_health", s)))

METHOD(HealthSmall, describe, string(HealthSmall this))
{
    TC(HealthSmall, this);
    return sprintf(_("The %s restores a small amount of health when picked up, "
        "helping you recover from damage taken during combat.\n\n%s"),
    COLORED_NAME(this), DEFAULT_PICKUP_HEALTH("small"));
}

METHOD(HealthMedium, describe, string(HealthMedium this))
{
    TC(HealthMedium, this);
    return sprintf(_("The %s restores a medium amount of health when picked up, "
        "helping you recover from damage taken during combat.\n\n%s"),
    COLORED_NAME(this), DEFAULT_PICKUP_HEALTH("medium"));
}

METHOD(HealthBig, describe, string(HealthBig this))
{
    TC(HealthBig, this);
    return sprintf(_("The %s restores a large amount of health when picked up, "
        "helping you recover from damage taken during combat.\n\n%s"),
    COLORED_NAME(this), DEFAULT_PICKUP_HEALTH("big"));
}

METHOD(HealthMega, describe, string(HealthMega this))
{
    TC(HealthMega, this);
    return sprintf(_("The %s restores a huge amount of health when picked up, "
        "helping you recover from damage taken during combat.\n\n"
        "It tends to be one of the most highly contested items on a map, particularly in game modes like %s.\n\n%s"),
    COLORED_NAME(this), COLORED_NAME(MAPINFO_TYPE_DUEL), DEFAULT_PICKUP_HEALTH("mega"));
}

#undef DEFAULT_PICKUP_HEALTH
#endif
