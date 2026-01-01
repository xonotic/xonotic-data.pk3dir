#include "napalm.qh"

#ifdef SVQC
void napalm_damage(entity this, float dist, float damage, float edgedamage, float burntime)
{
	entity e;
	float d;
	vector p;

	if ( damage < 0 )
		return;

	RandomSelection_Init();
	for(e = WarpZone_FindRadius(this.origin, dist, true); e; e = e.chain)
		if(e.takedamage == DAMAGE_AIM)
		if(this.realowner != e || autocvar_g_nades_napalm_selfdamage)
		if(!IS_PLAYER(e) || !this.realowner || DIFF_TEAM(e, this))
		if(!STAT(FROZEN, e))
		{
			p = e.origin;
			p.x += e.mins.x + random() * (e.maxs.x - e.mins.x);
			p.y += e.mins.y + random() * (e.maxs.y - e.mins.y);
			p.z += e.mins.z + random() * (e.maxs.z - e.mins.z);
			d = vlen(WarpZone_UnTransformOrigin(e, this.origin) - p);
			if(d < dist)
			{
				e.fireball_impactvec = p;
				RandomSelection_AddEnt(e, 1 / (1 + d), !StatusEffects_active(STATUSEFFECT_Burning, e));
			}
		}
	if(RandomSelection_chosen_ent)
	{
		d = vlen(WarpZone_UnTransformOrigin(RandomSelection_chosen_ent, this.origin) - RandomSelection_chosen_ent.fireball_impactvec);
		d = damage + (edgedamage - damage) * (d / dist);
		Fire_AddDamage(RandomSelection_chosen_ent, this.realowner, d * burntime, burntime, this.projectiledeathtype);
		//trailparticles(this, particleeffectnum(EFFECT_FIREBALL_LASER), this.origin, RandomSelection_chosen_ent.fireball_impactvec);
		Send_Effect(EFFECT_FIREBALL_LASER, this.origin, RandomSelection_chosen_ent.fireball_impactvec - this.origin, 1);
	}
}

void napalm_ball_think(entity this)
{
	if(round_handler_IsActive())
	if(!round_handler_IsRoundStarted())
	{
		delete(this);
		return;
	}

	if(time > this.pushltime)
	{
		delete(this);
		return;
	}

	vector midpoint = ((this.absmin + this.absmax) * 0.5);
	if(pointcontents(midpoint) == CONTENT_WATER)
	{
		this.velocity = this.velocity * 0.5;

		if(pointcontents(midpoint + '0 0 16') == CONTENT_WATER)
			{ this.velocity_z = 200; }
	}

	this.angles = vectoangles(this.velocity);

	napalm_damage(this, autocvar_g_nades_napalm_ball_radius,autocvar_g_nades_napalm_ball_damage,
				  autocvar_g_nades_napalm_ball_damage,autocvar_g_nades_napalm_burntime);

	this.nextthink = time + 0.1;
}

void nade_napalm_ball(entity this)
{
	entity proj;
	vector kick;

	spamsound(this, CH_SHOTS, SND_NADE_NAPALM_FIRE, VOL_BASE, ATTEN_NORM);

	proj = new(grenade);
	proj.owner = this.owner;
	proj.realowner = this.realowner;
	proj.team = this.owner.team;
	proj.bot_dodge = true;
	proj.bot_dodgerating = autocvar_g_nades_napalm_ball_damage;
	set_movetype(proj, MOVETYPE_BOUNCE);
	proj.projectiledeathtype = DEATH_NADE_NAPALM.m_id;
	PROJECTILE_MAKETRIGGER(proj);
	setmodel(proj, MDL_Null);
	proj.scale = 1;//0.5;
	setsize(proj, '-4 -4 -4', '4 4 4');
	setorigin(proj, this.origin);
	setthink(proj, napalm_ball_think);
	proj.nextthink = time;
	proj.damageforcescale = autocvar_g_nades_napalm_ball_damageforcescale;
	proj.effects = EF_LOWPRECISION | EF_FLAME;

	kick.x =(random() - 0.5) * 2 * autocvar_g_nades_napalm_ball_spread;
	kick.y = (random() - 0.5) * 2 * autocvar_g_nades_napalm_ball_spread;
	kick.z = (random()/2+0.5) * autocvar_g_nades_napalm_ball_spread;
	proj.velocity = kick;

	proj.pushltime = time + autocvar_g_nades_napalm_ball_lifetime;

	proj.angles = vectoangles(proj.velocity);
	proj.flags = FL_PROJECTILE;
	IL_PUSH(g_projectiles, proj);
	IL_PUSH(g_bot_dodge, proj);
	proj.missile_flags = MIF_SPLASH | MIF_PROXY | MIF_ARC;

	//CSQCProjectile(proj, true, PROJECTILE_NAPALM_FIRE, true);
}

void napalm_fountain_think(entity this)
{

	if(round_handler_IsActive())
	if(!round_handler_IsRoundStarted())
	{
		delete(this);
		return;
	}

	if(time >= this.ltime)
	{
		delete(this);
		return;
	}

	vector midpoint = ((this.absmin + this.absmax) * 0.5);
	if(pointcontents(midpoint) == CONTENT_WATER)
	{
		this.velocity = this.velocity * 0.5;

		if(pointcontents(midpoint + '0 0 16') == CONTENT_WATER)
			{ this.velocity_z = 200; }

		UpdateCSQCProjectile(this);
	}

	napalm_damage(this, autocvar_g_nades_napalm_fountain_radius, autocvar_g_nades_napalm_fountain_damage,
		autocvar_g_nades_napalm_fountain_edgedamage, autocvar_g_nades_napalm_burntime);

	this.nextthink = time + 0.1;
	if(time >= this.nade_special_time)
	{
		this.nade_special_time = time + autocvar_g_nades_napalm_fountain_delay;
		nade_napalm_ball(this);
	}
}

void nade_napalm_boom(entity this)
{
	for (int c = 0; c < autocvar_g_nades_napalm_ball_count; ++c)
		nade_napalm_ball(this);

	entity fountain = new(nade_napalm_fountain);
	fountain.owner = this.owner;
	fountain.realowner = this.realowner;
	fountain.origin = this.origin;
	fountain.flags = FL_PROJECTILE;
	IL_PUSH(g_projectiles, fountain);
	IL_PUSH(g_bot_dodge, fountain);
	setorigin(fountain, fountain.origin);
	setthink(fountain, napalm_fountain_think);
	fountain.nextthink = time;
	fountain.ltime = time + autocvar_g_nades_napalm_fountain_lifetime;
	fountain.pushltime = fountain.ltime;
	fountain.team = this.team;
	set_movetype(fountain, MOVETYPE_TOSS);
	fountain.projectiledeathtype = DEATH_NADE_NAPALM.m_id;
	fountain.bot_dodge = true;
	fountain.bot_dodgerating = autocvar_g_nades_napalm_fountain_damage;
	fountain.nade_special_time = time;
	setsize(fountain, '-16 -16 -16', '16 16 16');
	CSQCProjectile(fountain, true, PROJECTILE_NAPALM_FOUNTAIN, true);
}
#endif // SVQC
#ifdef MENUQC
METHOD(NapalmNade, describe, string(NapalmNade this))
{
	TC(NapalmNade, this);
	PAGE_TEXT_INIT();
	PAR(_("The %s detonates after a short delay, spreading fiery napalm globs around in a fountain. "
	      "The napalm fire balls burn for a while, and damage players who get too close."), COLORED_NAME(this));
	return PAGE_TEXT;
}
#endif // MENUQC
