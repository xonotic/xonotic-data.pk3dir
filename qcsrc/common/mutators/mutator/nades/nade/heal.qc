#include "heal.qh"

#ifdef SVQC
void nade_heal_touch(entity this, entity toucher)
{
	float maxhealth;
	float health_factor;

	if(IS_PLAYER(toucher) || IS_MONSTER(toucher) || IS_VEHICLE(toucher))
	if(!IS_DEAD(toucher))
	if(!STAT(FROZEN, toucher))
	{
		health_factor = autocvar_g_nades_heal_rate*frametime/2;
		if ( toucher != this.realowner )
			health_factor *= (SAME_TEAM(toucher,this)) ? autocvar_g_nades_heal_friend : autocvar_g_nades_heal_foe;

		if ( health_factor > 0 )
		{
			maxhealth = (IS_MONSTER(toucher)) ? toucher.max_health : autocvar_g_pickup_healthmega_max;
			float hp = GetResource(toucher, RES_HEALTH);
			if (hp < maxhealth)
			{
				if (this.nade_show_particles)
					Send_Effect(EFFECT_HEALING, toucher.origin, '0 0 0', 1);
				
				GiveResourceWithLimit(toucher, RES_HEALTH, health_factor, maxhealth);
			}
		}
		else if ( health_factor < 0 )
			Damage(toucher,this,this.realowner,-health_factor,DEATH_NADE_HEAL.m_id,DMG_NOWEP,toucher.origin,'0 0 0');
	}
}

void nade_heal_boom(entity this)
{
	entity orb = nades_spawn_orb(this.owner, this.realowner, this.origin, autocvar_g_nades_heal_time, autocvar_g_nades_nade_radius);

	settouch(orb, nade_heal_touch);
	orb.colormod = '1 0 0';
}
#endif // SVQC
