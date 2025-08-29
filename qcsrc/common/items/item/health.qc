#include "health.qh"

#ifdef MENUQC
#include <common/gametypes/gametype/duel/duel.qh>

#define PAR_DEFAULT_PICKUP_HEALTH(s) \
	PAR(_("By default, the pickup gives you %s health."), strcat("^9", cvar_defstring(strcat("g_pickup_health", s)), "^7"));

METHOD(HealthSmall, describe, string(HealthSmall this))
{
	TC(HealthSmall, this);
	PAGE_TEXT_INIT();
	PAR(_("The %s restores a small amount of health when picked up, "
	      "helping you recover from damage taken during combat."), COLORED_NAME(this));
	PAR_DEFAULT_PICKUP_HEALTH("small");
	return PAGE_TEXT;
}

METHOD(HealthMedium, describe, string(HealthMedium this))
{
	TC(HealthMedium, this);
	PAGE_TEXT_INIT();
	PAR(_("The %s restores a medium amount of health when picked up, "
	      "helping you recover from damage taken during combat."), COLORED_NAME(this));
	PAR_DEFAULT_PICKUP_HEALTH("medium");
	return PAGE_TEXT;
}

METHOD(HealthBig, describe, string(HealthBig this))
{
	TC(HealthBig, this);
	PAGE_TEXT_INIT();
	PAR(_("The %s restores a large amount of health when picked up, "
	      "helping you recover from damage taken during combat."), COLORED_NAME(this));
	PAR_DEFAULT_PICKUP_HEALTH("big");
	return PAGE_TEXT;
}

METHOD(HealthMega, describe, string(HealthMega this))
{
	TC(HealthMega, this);
	PAGE_TEXT_INIT();
	PAR(_("The %s restores a huge amount of health when picked up, "
	      "helping you recover from damage taken during combat."), COLORED_NAME(this));
	PAR(_("It tends to be one of the most highly contested items on a map, particularly in gametypes like %s."), COLORED_NAME(MAPINFO_TYPE_DUEL));
	PAR_DEFAULT_PICKUP_HEALTH("mega");
	return PAGE_TEXT;
}

#undef DEFAULT_PICKUP_HEALTH
#endif
