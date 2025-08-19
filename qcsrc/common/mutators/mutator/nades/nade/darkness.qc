#include "darkness.qh"

#ifdef SVQC

void nade_darkness_think(entity this)
{
	if(round_handler_IsActive())
	if(!round_handler_IsRoundStarted())
	{
		delete(this);
		return;
	}

	if(time >= this.ltime)
	{
		if ( autocvar_g_nades_darkness_explode )
		{
			vector expcol_min = nades_PlayerColor(this.realowner, false);
			vector expcol_max = nades_PlayerColor(this.realowner, true);
			entity expef = EFFECT_NADE_EXPLODE;
			Send_Effect_Except(expef, this.origin + '0 0 1', '0 0 0', 1, expcol_min, expcol_max, NULL);
			sound(this, CH_SHOTS, SND_ROCKET_IMPACT, VOL_BASE, ATTEN_NORM);

			nade_normal_boom(this);
		}
		else
			Send_Effect_Except(EFFECT_SPAWN, this.origin + '0 0 1', '0 0 0', 1, '0.5 0 0.5', '0.5 0 0.5', NULL);

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
	Send_Effect(EFFECT_DARKFIELD, this.origin + randomp, '0 0 0', 1);

	if(time >= this.nade_special_time)
	{
		this.nade_special_time = time + 0.7;
		Send_Effect(EFFECT_DARKFIELD, this.origin, '0 0 0', 1);
	}


	float current_dark_time = this.ltime - time - 0.1;

	FOREACH_ENTITY_RADIUS(this.origin, autocvar_g_nades_nade_radius, it != this && it.takedamage
		&& !IS_DEAD(it) && GetResource(it, RES_HEALTH) > 0 && current_dark_time > 0 && IS_REAL_CLIENT(it),
	{
		switch (autocvar_g_nades_darkness_teamcheck)
		{
			case 0:  break; // affect everyone
			default:
			case 2:  if(SAME_TEAM(it, this.realowner)) continue; // don't affect teammates
			         // fall through (check case 1 condition too)
			case 1:  if(it == this.realowner) continue; // don't affect the player who threw the nade
		}
		STAT(NADE_DARKNESS_TIME, it) = time + 0.1;
	});
}

void nade_darkness_boom(entity this)
{
	entity fountain = new(nade_darkness_fountain);
	fountain.owner = this.owner;
	fountain.realowner = this.realowner;
	fountain.origin = this.origin;
	setorigin(fountain, fountain.origin);
	setthink(fountain, nade_darkness_think);
	fountain.nextthink = time;
	fountain.pushltime = fountain.wait = fountain.ltime = time + autocvar_g_nades_darkness_time;
	fountain.team = this.team;
	set_movetype(fountain, MOVETYPE_TOSS);
	fountain.projectiledeathtype = DEATH_NADE.m_id;
	fountain.bot_dodge = false;
	setsize(fountain, '-16 -16 -16', '16 16 16');
	fountain.nade_special_time = time + 0.3;
	fountain.angles = this.angles;

	if ( autocvar_g_nades_darkness_explode )
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
#ifdef CSQC

bool darkness_fadealpha;

void HUD_DarkBlinking()
{
	vector bottomright = vec2(vid_conwidth, vid_conheight);
	drawfill('0 0 0', bottomright, NADE_TYPE_DARKNESS.m_color, darkness_fadealpha, DRAWFLAG_NORMAL);
}

MUTATOR_HOOKFUNCTION(cl_nades, HUD_Draw_overlay)
{
	if (STAT(NADE_DARKNESS_TIME) > time)
	{
		if (!darkness_fadealpha)
			sound(csqcplayer, CH_PAIN, SND_BLIND, VOL_BASE, ATTEN_NORM);
		darkness_fadealpha = min(0.986, darkness_fadealpha + frametime * 7);
	}
	else if (darkness_fadealpha > 0)
		darkness_fadealpha = max(0, darkness_fadealpha - frametime * 7);

	if (darkness_fadealpha > 0)
	{
		HUD_DarkBlinking();
		M_ARGV(1, float) = 0; // alpha_multipl 0, don't draw normal overlay
		return true;
	}
	return false;
}
#endif // CSQC
#ifdef MENUQC
#include "darkness.qh"

METHOD(DarknessNade, describe, string(DarknessNade this))
{
	TC(DarknessNade, this);
	PAGE_TEXT_INIT();
	PAR(_("The %s detonates after a short delay, creating a dark field which temporarily blinds enemies who enter it."), COLORED_NAME(this));
	PAR(_("This is sort of the opposite of the %s."), COLORED_NAME(NADE_TYPE_VEIL));
	return PAGE_TEXT;
}
#endif // MENUQC
