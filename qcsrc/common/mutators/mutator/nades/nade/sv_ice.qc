#include "sv_ice.qh"

void nade_ice_freeze(entity freezefield, entity frost_target, float freezetime)
{
	frost_target.frozen_by = freezefield.realowner;
	Send_Effect(EFFECT_ELECTRO_IMPACT, frost_target.origin, '0 0 0', 1);
	Freeze(frost_target, 1 / freezetime, FROZEN_TEMP_DYING, false);

	Drop_Special_Items(frost_target);
}

void nade_ice_think(entity this)
{
	if(round_handler_IsActive())
	if(!round_handler_IsRoundStarted())
	{
		delete(this);
		return;
	}

	if(time >= this.ltime)
	{
		if ( autocvar_g_nades_ice_explode )
		{
			vector expcol_min = nades_PlayerColor(this.realowner, false);
			vector expcol_max = nades_PlayerColor(this.realowner, true);
			entity expef = EFFECT_NADE_EXPLODE_NEUTRAL;
			Send_Effect_Except(expef, this.origin + '0 0 1', '0 0 0', 1, expcol_min, expcol_max, NULL);
			sound(this, CH_SHOTS, SND_ROCKET_IMPACT, VOL_BASE, ATTEN_NORM);

			normal_nade_boom(this);
		}
		delete(this);
		return;
	}


	this.nextthink = time + 0.1;

	// gaussian
	float randomr;
	randomr = random();
	randomr = exp(-5 * randomr * randomr) * autocvar_g_nades_nade_radius;
	float randomw;
	randomw = random() * (2 * M_PI);
	vector randomp;
	randomp.x = randomr * cos(randomw);
	randomp.y = randomr * sin(randomw);
	randomp.z = 1;
	Send_Effect(EFFECT_ELECTRO_MUZZLEFLASH, this.origin + randomp, '0 0 0', 1);

	if(time >= this.nade_special_time)
	{
		this.nade_special_time = time + 0.7;

		Send_Effect(EFFECT_ELECTRO_IMPACT, this.origin, '0 0 0', 1);
		Send_Effect(EFFECT_ICEFIELD, this.origin, '0 0 0', 1);
	}


	float current_freeze_time = this.ltime - time - 0.1;

	FOREACH_ENTITY_RADIUS(this.origin, autocvar_g_nades_nade_radius, it != this && it.takedamage
		&& !IS_DEAD(it) && GetResource(it, RES_HEALTH) > 0 && current_freeze_time > 0
		&& (!it.revival_time || ((time - it.revival_time) >= 1.5)) && !STAT(FROZEN, it),
	{
		switch (autocvar_g_nades_ice_teamcheck)
		{
			case 0:  break; // affect everyone
			default: 
			case 2:  if(SAME_TEAM(it, this.realowner)) continue; // don't affect teammates
			         // fall through (check case 1 condition too)
			case 1:  if(it == this.realowner) continue; // don't affect the player who threw the nade
		}
		nade_ice_freeze(this, it, current_freeze_time);
	});
}

void nade_ice_boom(entity this)
{
	entity fountain = new(nade_ice_fountain);
	fountain.owner = this.owner;
	fountain.realowner = this.realowner;
	fountain.origin = this.origin;
	setorigin(fountain, fountain.origin);
	setthink(fountain, nade_ice_think);
	fountain.nextthink = time;
	fountain.ltime = time + autocvar_g_nades_ice_freeze_time;
	fountain.pushltime = fountain.wait = fountain.ltime;
	fountain.team = this.team;
	set_movetype(fountain, MOVETYPE_TOSS);
	fountain.projectiledeathtype = DEATH_NADE_ICE.m_id;
	fountain.bot_dodge = false;
	setsize(fountain, '-16 -16 -16', '16 16 16');
	fountain.nade_special_time = time + 0.3;
	fountain.angles = this.angles;

	if ( autocvar_g_nades_ice_explode )
	{
		setmodel(fountain, MDL_PROJECTILE_GRENADE);
		entity timer = new(nade_timer);
		setmodel(timer, MDL_NADE_TIMER);
		setattachment(timer, fountain, "");
		timer.colormap = this.colormap;
		timer.glowmod = this.glowmod;
		setthink(timer, nade_timer_think);
		timer.nextthink = time;
		timer.wait = fountain.ltime;
		timer.owner = fountain;
		timer.skin = 10;
	}
	else
		setmodel(fountain, MDL_Null);
}
