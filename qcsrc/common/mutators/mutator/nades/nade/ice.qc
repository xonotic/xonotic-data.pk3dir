#include "ice.qh"

#ifdef SVQC
void nade_ice_freeze(entity freezefield, entity frost_target, float freezetime)
{
	Send_Effect(EFFECT_ELECTRO_IMPACT, frost_target.origin, '0 0 0', 1);
	StatusEffects_apply(STATUSEFFECT_Frozen, frost_target, time + freezetime, 0);

	//Drop_Special_Items(frost_target);
}

float nade_current_freeze_time;
bool nade_ice_think_cond(entity e)
{
	return (e != WarpZone_SearchInRadius_otherent && e.takedamage
		&& (IS_PLAYER(e) || IS_MONSTER(e))
		&& !IS_DEAD(e) && GetResource(e, RES_HEALTH) > 0 && nade_current_freeze_time > 0
		&& (!e.revival_time || (time - e.revival_time) >= 1.5)
		&& !STAT(FROZEN, e) && !StatusEffects_active(STATUSEFFECT_Frozen, e));
}
void nade_ice_think(entity this)
{
	if (round_handler_IsActive() && !round_handler_IsRoundStarted())
	{
		delete(this);
		return;
	}

	if (time >= this.ltime)
	{
		if (autocvar_g_nades_ice_explode)
		{
			vector expcol_min = nades_PlayerColor(this.realowner, false);
			vector expcol_max = nades_PlayerColor(this.realowner, true);
			Send_Effect_Core(EFFECT_NADE_EXPLODE, this.origin + '0 0 1', '0 0 0', 1, expcol_min, expcol_max, -1, -1, -1, NULL);
			sound(this, CH_SHOTS, SND_ROCKET_IMPACT, VOL_BASE, ATTEN_NORM);

			nade_normal_boom(this);
		}
		delete(this);
		return;
	}

	this.nextthink = time + 0.1;

	// gaussian
	float randomr = random();
	randomr = exp(-5 * randomr * randomr) * autocvar_g_nades_ice_radius;
	float randomw = random() * (2 * M_PI);
	vector randomp;
	randomp.x = randomr * cos(randomw);
	randomp.y = randomr * sin(randomw);
	randomp.z = 1;
	Send_Effect(EFFECT_ELECTRO_MUZZLEFLASH, this.origin + randomp, '0 0 0', 1);

	if (time >= this.nade_special_time)
	{
		this.nade_special_time = time + 5/16; // 0.3125

		Send_Effect(EFFECT_ELECTRO_IMPACT, this.origin, '0 0 0', 1);
		Send_Effect(EFFECT_ICEFIELD, this.origin, '0 0 0', 1);
	}

	nade_current_freeze_time = this.ltime - this.nextthink;
	WarpZone_SearchInRadius_otherent = this;
	entity head = WarpZone_SearchInRadius(this.origin, autocvar_g_nades_ice_radius, MOVE_NOTHING, nade_ice_think_cond);
	for (; head; head = head.chain)
	{
		switch (autocvar_g_nades_ice_teamcheck)
		{
			case 0:  break; // affect everyone
			default:
			case 2:  if (SAME_TEAM(head, this.realowner)) continue; // don't affect teammates
			         // fall through (check case 1 condition too)
			case 1:  if (head == this.realowner) continue; // don't affect the player who threw the nade
		}
		nade_ice_freeze(this, head, nade_current_freeze_time);
	}
}

void nade_ice_boom(entity this)
{
	entity fountain = new(nade_ice_fountain);
	fountain.owner = this.owner;
	fountain.realowner = this.realowner;
	fountain.origin = this.origin;
	fountain.flags = FL_PROJECTILE;
	IL_PUSH(g_projectiles, fountain);
	setorigin(fountain, fountain.origin);
	setthink(fountain, nade_ice_think);
	fountain.nextthink = time;
	fountain.pushltime = fountain.wait = fountain.ltime = time + autocvar_g_nades_ice_freeze_time;
	fountain.team = this.team;
	set_movetype(fountain, MOVETYPE_TOSS);
	fountain.projectiledeathtype = DEATH_NADE_ICE.m_id;
	fountain.bot_dodge = false;
	setsize(fountain, '-16 -16 -16', '16 16 16');
	fountain.nade_special_time = time + 0.3;
	fountain.angles = this.angles;

	if (autocvar_g_nades_ice_explode)
	{
		setmodel(fountain, MDL_PROJECTILE_GRENADE);
		entity timer = new(nade_timer);
		setmodel(timer, MDL_NADE_TIMER);
		setattachment(timer, fountain, "");
		timer.colormap = this.colormap;
		timer.glowmod = this.glowmod;
		setthink(timer, nade_timer_think);
		timer.nextthink = time;
		timer.wait = fountain.wait;
		timer.nade_lifetime = this.nade_lifetime;
		timer.owner = fountain;
		timer.skin = 10;
	}
	else
		setmodel(fountain, MDL_Null);
}
#endif // SVQC
#ifdef MENUQC
METHOD(IceNade, describe, string(IceNade this))
{
	TC(IceNade, this);
	PAGE_TEXT_INIT();
	PAR(_("The %s detonates after a short delay, freezing any enemies who walk within the explosion radius for a few seconds after the explosion. "
	      "While frozen, players can't move or shoot, leaving them vulnerable to damage, but if left too long they'll unfreeze and run away!"), COLORED_NAME(this));
	return PAGE_TEXT;
}
#endif // MENUQC
