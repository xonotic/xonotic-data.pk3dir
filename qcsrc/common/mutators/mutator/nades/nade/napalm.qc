#include "napalm.qh"

#ifdef SVQC
bool napalm_damage_cond(entity e)
{
	return (e.takedamage == DAMAGE_AIM
		&& (e != WarpZone_SearchInRadius_otherent.realowner || autocvar_g_nades_napalm_selfdamage)
		&& (!IS_PLAYER(e) || !WarpZone_SearchInRadius_otherent.realowner || DIFF_TEAM(e, WarpZone_SearchInRadius_otherent))
		&& !STAT(FROZEN, e));
}

void napalm_ball_think(entity this)
{
	if ((round_handler_IsActive() && !round_handler_IsRoundStarted())
	|| time > this.pushltime)
	{
		delete(this);
		return;
	}

	vector midpoint = (this.absmin + this.absmax) * 0.5;
	if (pointcontents(midpoint) == CONTENT_WATER)
	{
		this.velocity *= 0.5;

		if (pointcontents(midpoint + '0 0 16') == CONTENT_WATER)
			this.velocity.z = 200;
	}

	this.angles = vectoangles(this.velocity);

	W_LaserPlay(this,
		autocvar_g_nades_napalm_ball_radius,
		autocvar_g_nades_napalm_ball_damage,
		autocvar_g_nades_napalm_ball_damage, // TODO: missing cvar
		autocvar_g_nades_napalm_burntime,
		napalm_damage_cond);

	this.nextthink = time + 0.1;
}

void nade_napalm_ball(entity this)
{
	spamsound(this, CH_SHOTS, SND_NADE_NAPALM_FIRE, VOL_BASE, ATTEN_NORM);

	entity proj = new(grenade);
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

	vector kick;
	kick.x = autocvar_g_nades_napalm_ball_spread * crandom();
	kick.y = autocvar_g_nades_napalm_ball_spread * crandom();
	kick.z = autocvar_g_nades_napalm_ball_spread * (random() * 0.5 + 0.5);
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
	if ((round_handler_IsActive() && !round_handler_IsRoundStarted())
	|| time >= this.ltime)
	{
		delete(this);
		return;
	}

	vector midpoint = (this.absmin + this.absmax) * 0.5;
	if (pointcontents(midpoint) == CONTENT_WATER)
	{
		this.velocity *= 0.5;

		if (pointcontents(midpoint + '0 0 16') == CONTENT_WATER)
			this.velocity.z = 200;

		UpdateCSQCProjectile(this);
	}

	W_LaserPlay(this,
		autocvar_g_nades_napalm_fountain_radius,
		autocvar_g_nades_napalm_fountain_damage,
		autocvar_g_nades_napalm_fountain_edgedamage,
		autocvar_g_nades_napalm_burntime,
		napalm_damage_cond);

	this.nextthink = time + 0.1;
	if (time >= this.nade_special_time)
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
