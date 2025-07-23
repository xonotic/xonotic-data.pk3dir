#include "armor.qh"

#ifdef MENUQC
#include <common/gamemodes/gamemode/duel/duel.qh>

#define DEFAULT_PICKUP_ARMOR(s) \
	sprintf(_("By default, the pickup gives you ^9%s^7 armor."), cvar_defstring(strcat("g_pickup_armor", s)))

METHOD(ArmorSmall, describe, string(ArmorSmall this))
{
    TC(ArmorSmall, this);
    return sprintf(_("The %s provides you a small amount of armor when picked up, "
        "protecting you from damage by absorbing incoming hits until it is depleted.\n\n%s"),
    COLORED_NAME(this), DEFAULT_PICKUP_ARMOR("small"));
}

METHOD(ArmorMedium, describe, string(ArmorMedium this))
{
    TC(ArmorMedium, this);
    return sprintf(_("The %s provides you a medium amount of armor when picked up, "
        "protecting you from damage by absorbing incoming hits until it is depleted.\n\n%s"),
    COLORED_NAME(this), DEFAULT_PICKUP_ARMOR("medium"));
}

METHOD(ArmorBig, describe, string(ArmorBig this))
{
    TC(ArmorBig, this);
    return sprintf(_("The %s provides you a large amount of armor when picked up, "
        "protecting you from damage by absorbing incoming hits until it is depleted.\n\n%s"),
    COLORED_NAME(this), DEFAULT_PICKUP_ARMOR("big"));
}

METHOD(ArmorMega, describe, string(ArmorMega this))
{
    TC(ArmorMega, this);
    return sprintf(_("The %s provides you a huge amount of armor when picked up, "
        "protecting you from damage by absorbing incoming hits until it is depleted.\n\n"
        "It tends to be one of the most highly contested items on a map, particularly in game modes like %s.\n\n%s"),
    COLORED_NAME(this), COLORED_NAME(MAPINFO_TYPE_DUEL), DEFAULT_PICKUP_ARMOR("mega"));
}

#undef DEFAULT_PICKUP_ARMOR
#endif
