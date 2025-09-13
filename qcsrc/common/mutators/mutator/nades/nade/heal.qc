#include "heal.qh"

#ifdef SVQC
#include <common/items/item/health.qh>
#include <common/items/item/armor.qh>

void nade_heal_touch(entity this, entity toucher)
{
	if ((!IS_PLAYER(toucher) && !IS_MONSTER(toucher) && !IS_VEHICLE(toucher))
	|| IS_DEAD(toucher) || STAT(FROZEN, toucher))
		return;

	float health_factor = autocvar_g_nades_heal_rate * frametime * 0.5;
	if (toucher != this.realowner)
		health_factor *= (SAME_TEAM(toucher, this.realowner))
			? autocvar_g_nades_heal_friend
			: autocvar_g_nades_heal_foe;

	if (health_factor > 0)
	{
		float maxhealth = (IS_MONSTER(toucher))
			? toucher.max_health
			: autocvar_g_pickup_healthmega_max;
		if (GetResource(toucher, RES_HEALTH) < maxhealth)
		{
			if (this.nade_show_particles)
				Send_Effect(EFFECT_HEALING, toucher.origin, '0 0 0', 1);

			GiveResourceWithLimit(toucher, RES_HEALTH, health_factor, maxhealth);
		}
	}
	else if (health_factor < 0)
		Damage(toucher, this, this.realowner,
			-health_factor,
			DEATH_NADE_HEAL.m_id,
			DMG_NOWEP,
			toucher.origin,
			'0 0 0'
		);

	float armor_factor = autocvar_g_nades_heal_armor_rate * frametime * 0.5;
	if (toucher != this.realowner)
		armor_factor *= autocvar_g_nades_heal_friend;

	if (SAME_TEAM(toucher, this))
	{
		float maxarmor = autocvar_g_pickup_armormega_max;
		if (GetResource(toucher, RES_ARMOR) < maxarmor)
			GiveResourceWithLimit(toucher, RES_ARMOR, armor_factor, maxarmor);
	}
}

void nade_heal_boom(entity this)
{
	entity orb = nades_spawn_orb(this.owner, this.realowner, this.origin, autocvar_g_nades_heal_time, autocvar_g_nades_heal_radius);

	settouch(orb, nade_heal_touch);
	orb.colormod = '1 0 0';
}
#endif // SVQC
#ifdef MENUQC
METHOD(HealNade, describe, string(HealNade this))
{
	TC(HealNade, this);
	PAGE_TEXT_INIT();
	PAR(_("The %s detonates after a short delay, temporarily creating a healing orb around the point where it detonated for several seconds. "
	      "If your team members enter the orb they will recover health, and if enemies enter the sphere they will be harmed."), COLORED_NAME(this));
	return PAGE_TEXT;
}
#endif // MENUQC
