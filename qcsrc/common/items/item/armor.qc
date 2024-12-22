#include "armor.qh"

#ifdef MENUQC
METHOD(ArmorSmall, describe, string(ArmorSmall this))
{
    TC(ArmorSmall, this);
    return sprintf(_("The %s provides you a small amount of armor when picked up, "
        "protecting you from damage by absorbing incoming hits until it is depleted"),
    COLORED_NAME(this));
}

METHOD(ArmorMedium, describe, string(ArmorMedium this))
{
    TC(ArmorMedium, this);
    return sprintf(_("The %s provides you a medium amount of armor when picked up, "
        "protecting you from damage by absorbing incoming hits until it is depleted"),
    COLORED_NAME(this));
}

METHOD(ArmorBig, describe, string(ArmorBig this))
{
    TC(ArmorBig, this);
    return sprintf(_("The %s provides you a large amount of armor when picked up, "
        "protecting you from damage by absorbing incoming hits until it is depleted"),
    COLORED_NAME(this));
}

METHOD(ArmorMega, describe, string(ArmorMega this))
{
    TC(ArmorMega, this);
    return sprintf(_("The %s provides you a huge amount of armor when picked up, "
        "protecting you from damage by absorbing incoming hits until it is depleted\n\n"
        "It tends to be one of the most highly contested items on a map, particularly in game modes like Duel"),
    COLORED_NAME(this));
}
#endif
