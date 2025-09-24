#include "armor.qh"

#ifdef MENUQC
#include <common/gametypes/gametype/duel/duel.qh>

#define PAR_DEFAULT_PICKUP_ARMOR(s) \
	PAR(_("By default, the pickup gives you %s armor."), strcat("^9", cvar_defstring(strcat("g_pickup_armor", s)), "^7"));

METHOD(ArmorSmall, describe, string(ArmorSmall this))
{
	TC(ArmorSmall, this);
	PAGE_TEXT_INIT();
	PAR(_("The %s provides you a small amount of armor when picked up, "
	      "protecting you from damage by absorbing incoming hits until it is depleted."), COLORED_NAME(this));
	PAR_DEFAULT_PICKUP_ARMOR("small");
	return PAGE_TEXT;
}

METHOD(ArmorMedium, describe, string(ArmorMedium this))
{
	TC(ArmorMedium, this);
	PAGE_TEXT_INIT();
	PAR(_("The %s provides you a medium amount of armor when picked up, "
	      "protecting you from damage by absorbing incoming hits until it is depleted."), COLORED_NAME(this));
	PAR_DEFAULT_PICKUP_ARMOR("medium");
	return PAGE_TEXT;
}

METHOD(ArmorBig, describe, string(ArmorBig this))
{
	TC(ArmorBig, this);
	PAGE_TEXT_INIT();
	PAR(_("The %s provides you a large amount of armor when picked up, "
	      "protecting you from damage by absorbing incoming hits until it is depleted."), COLORED_NAME(this));
	PAR_DEFAULT_PICKUP_ARMOR("big");
	return PAGE_TEXT;
}

METHOD(ArmorMega, describe, string(ArmorMega this))
{
	TC(ArmorMega, this);
	PAGE_TEXT_INIT();
	PAR(_("The %s provides you a huge amount of armor when picked up, "
	      "protecting you from damage by absorbing incoming hits until it is depleted."), COLORED_NAME(this));
	PAR(_("It tends to be one of the most highly contested items on a map, particularly in gametypes like %s."), COLORED_NAME(MAPINFO_TYPE_DUEL));
	PAR_DEFAULT_PICKUP_ARMOR("mega");
	return PAGE_TEXT;
}

#undef DEFAULT_PICKUP_ARMOR
#endif
