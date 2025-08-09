#include "sv_touchexplode.qh"

string autocvar_g_touchexplode;
float autocvar_g_touchexplode_radius;
float autocvar_g_touchexplode_damage;
float autocvar_g_touchexplode_edgedamage;
float autocvar_g_touchexplode_force;

SOUND(TOUCHEXPLODE, W_Sound("grenade_impact"));

REGISTER_MUTATOR(touchexplode, expr_evaluate(autocvar_g_touchexplode));

.float touchexplode_time;

void PlayerTouchExplode(entity p1, entity p2)
{
	vector org = (p1.origin + p2.origin) * 0.5;
	org.z += (p1.mins.z + p2.mins.z) * 0.5;

	sound(p1, CH_TRIGGER, SND_TOUCHEXPLODE, VOL_BASE, ATTEN_NORM);
	Send_Effect(EFFECT_EXPLOSION_SMALL, org, '0 0 0', 1);

	entity e = spawn();
	setorigin(e, org);
	RadiusDamage(e, NULL, autocvar_g_touchexplode_damage, autocvar_g_touchexplode_edgedamage, autocvar_g_touchexplode_radius, NULL, NULL, autocvar_g_touchexplode_force, DEATH_TOUCHEXPLODE.m_id, DMG_NOWEP, NULL);
	delete(e);
}

MUTATOR_HOOKFUNCTION(touchexplode, PlayerPreThink)
{
	entity player = M_ARGV(0, entity);

	if(time > player.touchexplode_time && !game_stopped && !IS_DEAD(player) && IS_PLAYER(player) && !STAT(FROZEN, player) && !IS_INDEPENDENT_PLAYER(player))
	{
		FOREACH_CLIENT(IS_PLAYER(it) && it != player, {
			if(time > it.touchexplode_time && !STAT(FROZEN, it) && !IS_DEAD(it) && !IS_INDEPENDENT_PLAYER(it))
			if(boxesoverlap(player.absmin, player.absmax, it.absmin, it.absmax))
			{
				PlayerTouchExplode(player, it);
				player.touchexplode_time = it.touchexplode_time = time + 0.2;
			}
		});
	}
}
