#include "nades.qh"

#include "../overkill/okmachinegun.qh"
#include "../overkill/okshotgun.qh"

#ifdef SVQC
bool autocvar_g_nades_nade_small;
float autocvar_g_nades_spread = 0.04;
#endif

REGISTER_STAT(NADES_SMALL, int, autocvar_g_nades_nade_small)

#ifdef GAMEQC

REPLICATE(cvar_cl_nade_type, int, "cl_nade_type");
REPLICATE(cvar_cl_pokenade_type, string, "cl_pokenade_type");

entity Nade_TrailEffect(int proj, int nade_team)
{
    switch (proj)
    {
        case PROJECTILE_NADE:       return EFFECT_NADE_TRAIL(nade_team);
        case PROJECTILE_NADE_BURN:  return EFFECT_NADE_TRAIL_BURN(nade_team);
    }

    FOREACH(Nades, true, {
        for (int j = 0; j < 2; j++)
        {
            if (it.m_projectile[j] == proj)
            {
                string trail = it.m_trail[j].eent_eff_name;
                if (trail) return it.m_trail[j];
                break;
            }
        }
    });

    return EFFECT_Null;
}
#endif

#ifdef CSQC
REGISTER_MUTATOR(cl_nades, true);
MUTATOR_HOOKFUNCTION(cl_nades, HUD_Draw_overlay)
{
	// TODO: make a common orb state!
	if (STAT(HEALING_ORB) > time)
	{
		M_ARGV(0, vector) = NADE_TYPE_HEAL.m_color;
		M_ARGV(1, float) = STAT(HEALING_ORB_ALPHA);
		return true;
	}
	if (STAT(ENTRAP_ORB) > time)
	{
		M_ARGV(0, vector) = NADE_TYPE_ENTRAP.m_color;
		M_ARGV(1, float) = STAT(ENTRAP_ORB_ALPHA);
		return true;
	}
	if (STAT(VEIL_ORB) > time)
	{
		M_ARGV(0, vector) = NADE_TYPE_VEIL.m_color;
		M_ARGV(1, float) = STAT(VEIL_ORB_ALPHA);
		return true;
	}
	return false;
}
MUTATOR_HOOKFUNCTION(cl_nades, Ent_Projectile)
{
	entity proj = M_ARGV(0, entity);

	if (proj.cnt == PROJECTILE_NAPALM_FOUNTAIN)
	{
		proj.modelindex = 0;
		proj.traileffect = EFFECT_FIREBALL.m_id;
		return true;
	}
	if (Nade_FromProjectile(proj.cnt) != NADE_TYPE_Null)
	{
		setmodel(proj, MDL_PROJECTILE_NADE);
		entity trail = Nade_TrailEffect(proj.cnt, proj.team);
		if (trail.eent_eff_name) proj.traileffect = trail.m_id;
		return true;
	}
}
MUTATOR_HOOKFUNCTION(cl_nades, EditProjectile)
{
	entity proj = M_ARGV(0, entity);

	if (proj.cnt == PROJECTILE_NAPALM_FOUNTAIN)
	{
		loopsound(proj, CH_SHOTS_SINGLE, SND_FIREBALL_FLY2, VOL_BASE, ATTEN_NORM);
		proj.mins = '-16 -16 -16';
		proj.maxs = '16 16 16';
	}

	entity nade_type = Nade_FromProjectile(proj.cnt);
	if (nade_type == NADE_TYPE_Null) return;
	if(STAT(NADES_SMALL))
	{
		proj.mins = '-8 -8 -8';
		proj.maxs = '8 8 8';
	}
	else
	{
		proj.mins = '-16 -16 -16';
		proj.maxs = '16 16 16';
	}
	proj.colormod = nade_type.m_color;
	set_movetype(proj, MOVETYPE_BOUNCE);
	settouch(proj, func_null);
	proj.scale = 1.5;
	proj.avelocity = randomvec() * 720;
	proj.alphamod = nade_type.m_alpha;

	if (nade_type == NADE_TYPE_TRANSLOCATE || nade_type == NADE_TYPE_SPAWN)
		proj.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_PLAYERCLIP | DPCONTENTS_BOTCLIP;
	else
		proj.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY;
}
bool Projectile_isnade(int p)
{
	return Nade_FromProjectile(p) != NADE_TYPE_Null;
}
void DrawAmmoNades(vector myPos, vector mySize, bool draw_expanding, float expand_time)
{
	float bonusNades    = STAT(NADE_BONUS);
	float bonusProgress = STAT(NADE_BONUS_SCORE);
	float bonusType     = STAT(NADE_BONUS_TYPE);
	Nade def = REGISTRY_GET(Nades, bonusType);
	vector nadeColor    = def.m_color;
	string nadeIcon     = def.m_icon;

	vector iconPos, textPos;

	if(autocvar_hud_panel_ammo_iconalign)
	{
		iconPos = myPos + eX * 2 * mySize.y;
		textPos = myPos;
	}
	else
	{
		iconPos = myPos;
		textPos = myPos + eX * mySize.y;
	}

	if(bonusNades > 0 || bonusProgress > 0)
	{
		DrawNadeProgressBar(myPos, mySize, bonusProgress, nadeColor);

		if(autocvar_hud_panel_ammo_text)
			drawstring_aspect(textPos, ftos(bonusNades), vec2((2/3) * mySize.x, mySize.y), '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);

		if(draw_expanding)
			drawpic_aspect_skin_expanding(iconPos, nadeIcon, '1 1 0' * mySize.y, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL, expand_time);

		drawpic_aspect_skin(iconPos, nadeIcon, '1 1 0' * mySize.y, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	}
}
#endif

#ifdef SVQC

#include <common/gamemodes/_mod.qh>
#include <common/monsters/sv_spawn.qh>
#include <common/monsters/sv_monsters.qh>

.float nade_time_primed;
.float nade_lifetime;

.entity nade_spawnloc;


void nade_timer_think(entity this)
{
	this.skin = 8 - (this.owner.wait - time) / (this.owner.nade_lifetime / 10);
	this.nextthink = time;
	if(!this.owner || wasfreed(this.owner))
		delete(this);
}

void nade_burn_spawn(entity _nade)
{
	CSQCProjectile(_nade, true, REGISTRY_GET(Nades, STAT(NADE_BONUS_TYPE, _nade)).m_projectile[true], true);
}

void nade_spawn(entity _nade)
{
	entity timer = new(nade_timer);
	setmodel(timer, MDL_NADE_TIMER);
	setattachment(timer, _nade, "");
	timer.colormap = _nade.colormap;
	timer.glowmod = _nade.glowmod;
	setthink(timer, nade_timer_think);
	timer.nextthink = time;
	timer.wait = _nade.wait;
	timer.owner = _nade;
	timer.skin = 10;

	_nade.effects |= EF_LOWPRECISION;

	CSQCProjectile(_nade, true, REGISTRY_GET(Nades, STAT(NADE_BONUS_TYPE, _nade)).m_projectile[false], true);
}

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

	spamsound(this, CH_SHOTS, SND_FIREBALL_FIRE, VOL_BASE, ATTEN_NORM);

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
	for (int c = 0; c < autocvar_g_nades_napalm_ball_count; c++)
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
			entity expef = EFFECT_NADE_EXPLODE(this.realowner.team);
			Send_Effect(expef, this.origin + '0 0 1', '0 0 0', 1);
			sound(this, CH_SHOTS, SND_ROCKET_IMPACT, VOL_BASE, ATTEN_NORM);

			RadiusDamage(this, this.realowner, autocvar_g_nades_nade_damage, autocvar_g_nades_nade_edgedamage,
				autocvar_g_nades_nade_radius, this, NULL, autocvar_g_nades_nade_force, this.projectiledeathtype, DMG_NOWEP, this.enemy);
			Damage_DamageInfo(this.origin, autocvar_g_nades_nade_damage, autocvar_g_nades_nade_edgedamage,
				autocvar_g_nades_nade_radius, '1 1 1' * autocvar_g_nades_nade_force, this.projectiledeathtype, 0, this);
		}
		delete(this);
		return;
	}


	this.nextthink = time+0.1;

	// gaussian
	float randomr;
	randomr = random();
	randomr = exp(-5*randomr*randomr)*autocvar_g_nades_nade_radius;
	float randomw;
	randomw = random()*M_PI*2;
	vector randomp;
	randomp.x = randomr*cos(randomw);
	randomp.y = randomr*sin(randomw);
	randomp.z = 1;
	Send_Effect(EFFECT_ELECTRO_MUZZLEFLASH, this.origin + randomp, '0 0 0', 1);

	if(time >= this.nade_special_time)
	{
		this.nade_special_time = time+0.7;

		Send_Effect(EFFECT_ELECTRO_IMPACT, this.origin, '0 0 0', 1);
		Send_Effect(EFFECT_ICEFIELD, this.origin, '0 0 0', 1);
	}


	float current_freeze_time = this.ltime - time - 0.1;

	FOREACH_ENTITY_RADIUS(this.origin, autocvar_g_nades_nade_radius, it != this && it.takedamage && !IS_DEAD(it) && GetResource(it, RES_HEALTH) > 0 && current_freeze_time > 0,
	{
		if(!autocvar_g_nades_ice_teamcheck || (DIFF_TEAM(it, this.realowner) || it == this.realowner))
		if(!it.revival_time || ((time - it.revival_time) >= 1.5))
		if(!STAT(FROZEN, it))
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
	fountain.nade_special_time = time+0.3;
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

void nade_translocate_boom(entity this)
{
	if(this.realowner.vehicle)
		return;

	vector locout = this.origin + '0 0 1' * (1 - this.realowner.mins.z - 24);
	tracebox(locout, this.realowner.mins, this.realowner.maxs, locout, MOVE_NOMONSTERS, this.realowner);
	locout = trace_endpos;

	makevectors(this.realowner.angles);

	MUTATOR_CALLHOOK(PortalTeleport, this.realowner);

	TeleportPlayer(this, this.realowner, locout, this.realowner.angles, v_forward * vlen(this.realowner.velocity), '0 0 0', '0 0 0', TELEPORT_FLAGS_TELEPORTER);
}

void nade_spawn_boom(entity this)
{
	entity player = this.realowner;
	entity spawnloc = new(nade_spawn_loc);
	setorigin(spawnloc, this.origin);
	setsize(spawnloc, player.mins, player.maxs);
	set_movetype(spawnloc, MOVETYPE_NONE);
	spawnloc.solid = SOLID_NOT;
	spawnloc.drawonlytoclient = player;
	spawnloc.effects = EF_STARDUST;
	spawnloc.cnt = autocvar_g_nades_spawn_count;

	if(player.nade_spawnloc)
		delete(player.nade_spawnloc);

	player.nade_spawnloc = spawnloc;
}

void nades_orb_think(entity this)
{
	if(time >= this.ltime)
	{
		delete(this);
		return;
	}

	this.nextthink = time;

	if(time >= this.nade_special_time)
	{
		this.nade_special_time = time+0.25;
		this.nade_show_particles = 1;
	}
	else
		this.nade_show_particles = 0;
}

entity nades_spawn_orb(entity own, entity realown, vector org, float orb_ltime, float orb_rad)
{
	// NOTE: this function merely places an orb
	// you must add a custom touch function to the returned entity if desired
	// also set .colormod if you wish to have it colorized
	entity orb = new(nades_spawn_orb);
	orb.owner = own;
	orb.realowner = realown;
	setorigin(orb, org);

	orb.orb_lifetime = orb_ltime; // required for timers
	orb.ltime = time + orb.orb_lifetime;
	orb.bot_dodge = false;
	orb.team = realown.team;
	orb.solid = SOLID_TRIGGER;

	setmodel(orb, MDL_NADE_ORB);
	orb.skin = 1;
	orb.orb_radius = orb_rad; // required for fading
	vector size = '1 1 1' * orb.orb_radius / 2;
	setsize(orb, -size, size);

	Net_LinkEntity(orb, true, 0, orb_send);
	orb.SendFlags |= 1;

	setthink(orb, nades_orb_think);
	orb.nextthink = time;

	return orb;
}

void nade_entrap_touch(entity this, entity toucher)
{
	if(DIFF_TEAM(toucher, this.realowner)) // TODO: what if realowner changes team or disconnects?
	{
		if (!isPushable(toucher))
			return;

		float pushdeltatime = time - toucher.lastpushtime;
		if (pushdeltatime > 0.15) pushdeltatime = 0;
		toucher.lastpushtime = time;
		if(!pushdeltatime) return;

		// div0: ticrate independent, 1 = identity (not 20)
		toucher.velocity = toucher.velocity * (autocvar_g_nades_entrap_strength ** pushdeltatime);

	#ifdef SVQC
		UpdateCSQCProjectile(toucher);
	#endif
	}

	if ( IS_REAL_CLIENT(toucher) || (IS_VEHICLE(toucher) && toucher.owner) )
	{
		entity show_tint = (IS_VEHICLE(toucher) && toucher.owner) ? toucher.owner : toucher;
		STAT(ENTRAP_ORB, show_tint) = time + 0.1;

		float tint_alpha = 0.75;
		if(SAME_TEAM(toucher, this.realowner))
			tint_alpha = 0.45;
		STAT(ENTRAP_ORB_ALPHA, show_tint) = tint_alpha * (this.ltime - time) / this.orb_lifetime;
	}
}

void nade_entrap_boom(entity this)
{
	entity orb = nades_spawn_orb(this.owner, this.realowner, this.origin, autocvar_g_nades_entrap_time, autocvar_g_nades_entrap_radius);

	settouch(orb, nade_entrap_touch);
	orb.colormod = NADE_TYPE_ENTRAP.m_color;
}

void nade_heal_touch(entity this, entity toucher)
{
	float maxhealth;
	float health_factor;
	if(IS_PLAYER(toucher) || IS_MONSTER(toucher))
	if(!IS_DEAD(toucher))
	if(!STAT(FROZEN, toucher))
	{
		health_factor = autocvar_g_nades_heal_rate*frametime/2;
		if ( toucher != this.realowner )
		{
			if ( SAME_TEAM(toucher,this) )
				health_factor *= autocvar_g_nades_heal_friend;
			else
				health_factor *= autocvar_g_nades_heal_foe;
		}
		if ( health_factor > 0 )
		{
			maxhealth = (IS_MONSTER(toucher)) ? toucher.max_health : g_pickup_healthmega_max;
			float hp = GetResource(toucher, RES_HEALTH);
			if (hp < maxhealth)
			{
				if (this.nade_show_particles)
				{
					Send_Effect(EFFECT_HEALING, toucher.origin, '0 0 0', 1);
				}
				GiveResourceWithLimit(toucher, RES_HEALTH, health_factor, maxhealth);
			}
		}
		else if ( health_factor < 0 )
		{
			Damage(toucher,this,this.realowner,-health_factor,DEATH_NADE_HEAL.m_id,DMG_NOWEP,toucher.origin,'0 0 0');
		}

	}

	if ( IS_REAL_CLIENT(toucher) || (IS_VEHICLE(toucher) && toucher.owner) )
	{
		entity show_red = (IS_VEHICLE(toucher) && toucher.owner) ? toucher.owner : toucher;
		STAT(HEALING_ORB, show_red) = time+0.1;
		STAT(HEALING_ORB_ALPHA, show_red) = 0.75 * (this.ltime - time) / this.orb_lifetime;
	}
}

void nade_heal_boom(entity this)
{
	entity orb = nades_spawn_orb(this.owner, this.realowner, this.origin, autocvar_g_nades_heal_time, autocvar_g_nades_nade_radius);

	settouch(orb, nade_heal_touch);
	orb.colormod = '1 0 0';
}

void nade_monster_boom(entity this)
{
	entity e = spawn();
	e.noalign = true; // don't drop to floor
	e = spawnmonster(e, this.pokenade_type, MON_Null, this.realowner, this.realowner, this.origin, false, false, 1);

	if(autocvar_g_nades_pokenade_monster_lifetime > 0)
		e.monster_lifetime = time + autocvar_g_nades_pokenade_monster_lifetime;
	e.monster_skill = MONSTER_SKILL_INSANE;
}

void nade_veil_touch(entity this, entity toucher)
{
	if ( IS_REAL_CLIENT(toucher) || (IS_VEHICLE(toucher) && toucher.owner) )
	{
		entity show_tint = (IS_VEHICLE(toucher) && toucher.owner) ? toucher.owner : toucher;

		float tint_alpha = 0.75;
		if(SAME_TEAM(toucher, this.realowner))
		{
			tint_alpha = 0.45;
			if(!STAT(VEIL_ORB, show_tint))
			{
				toucher.nade_veil_prevalpha = toucher.alpha;
				toucher.alpha = -1;
			}
		}
		STAT(VEIL_ORB, show_tint) = time + 0.1;
		STAT(VEIL_ORB_ALPHA, show_tint) = tint_alpha * (this.ltime - time) / this.orb_lifetime;
	}
}

void nade_veil_boom(entity this)
{
	entity orb = nades_spawn_orb(this.owner, this.realowner, this.origin, autocvar_g_nades_veil_time, autocvar_g_nades_veil_radius);

	settouch(orb, nade_veil_touch);
	orb.colormod = NADE_TYPE_VEIL.m_color;
}

void nade_boom(entity this)
{
	entity expef = NULL;
	bool nade_blast = true;

	switch ( REGISTRY_GET(Nades, STAT(NADE_BONUS_TYPE, this)) )
	{
		case NADE_TYPE_NAPALM:
			nade_blast = autocvar_g_nades_napalm_blast;
			expef = EFFECT_EXPLOSION_MEDIUM;
			break;
		case NADE_TYPE_ICE:
			nade_blast = false;
			expef = EFFECT_ELECTRO_COMBO; // hookbomb_explode electro_combo bigplasma_impact
			break;
		case NADE_TYPE_TRANSLOCATE:
			nade_blast = false;
			break;
		case NADE_TYPE_MONSTER:
		case NADE_TYPE_SPAWN:
			nade_blast = false;
			switch(this.realowner.team)
			{
				case NUM_TEAM_1: expef = EFFECT_SPAWN_RED; break;
				case NUM_TEAM_2: expef = EFFECT_SPAWN_BLUE; break;
				case NUM_TEAM_3: expef = EFFECT_SPAWN_YELLOW; break;
				case NUM_TEAM_4: expef = EFFECT_SPAWN_PINK; break;
				default: expef = EFFECT_SPAWN_NEUTRAL; break;
			}
			break;
		case NADE_TYPE_HEAL:
			nade_blast = false;
			expef = EFFECT_SPAWN_RED;
			break;

		case NADE_TYPE_ENTRAP:
			nade_blast = false;
			expef = EFFECT_SPAWN_YELLOW;
			break;

		case NADE_TYPE_VEIL:
			nade_blast = false;
			expef = EFFECT_SPAWN_NEUTRAL;
			break;

		default:
		case NADE_TYPE_NORMAL:
			expef = EFFECT_NADE_EXPLODE(this.realowner.team);
			break;
	}

	if(expef)
		Send_Effect(expef, findbetterlocation(this.origin, 8), '0 0 0', 1);

	sound(this, CH_SHOTS_SINGLE, SND_Null, VOL_BASE, ATTEN_NORM);
	sound(this, CH_SHOTS, SND_ROCKET_IMPACT, VOL_BASE, ATTEN_NORM);

	this.event_damage = func_null; // prevent somehow calling damage in the next call

	if(nade_blast)
	{
		RadiusDamage(this, this.realowner, autocvar_g_nades_nade_damage, autocvar_g_nades_nade_edgedamage,
				 autocvar_g_nades_nade_radius, this, NULL, autocvar_g_nades_nade_force, this.projectiledeathtype, DMG_NOWEP, this.enemy);
		Damage_DamageInfo(this.origin, autocvar_g_nades_nade_damage, autocvar_g_nades_nade_edgedamage, autocvar_g_nades_nade_radius, '1 1 1' * autocvar_g_nades_nade_force, this.projectiledeathtype, 0, this);
	}

	if(this.takedamage)
	switch ( REGISTRY_GET(Nades, STAT(NADE_BONUS_TYPE, this)) )
	{
		case NADE_TYPE_NAPALM: nade_napalm_boom(this); break;
		case NADE_TYPE_ICE: nade_ice_boom(this); break;
		case NADE_TYPE_TRANSLOCATE: nade_translocate_boom(this); break;
		case NADE_TYPE_SPAWN: nade_spawn_boom(this); break;
		case NADE_TYPE_HEAL: nade_heal_boom(this); break;
		case NADE_TYPE_MONSTER: nade_monster_boom(this); break;
		case NADE_TYPE_ENTRAP: nade_entrap_boom(this); break;
		case NADE_TYPE_VEIL: nade_veil_boom(this); break;
	}

	IL_EACH(g_projectiles, it.classname == "grapplinghook" && it.aiment == this,
	{
		RemoveHook(it);
	});

	delete(this);
}

void spawn_held_nade(entity player, entity nowner, float ntime, int ntype, string pntype);
void nade_pickup(entity this, entity thenade)
{
	spawn_held_nade(this, thenade.realowner, autocvar_g_nades_pickup_time, STAT(NADE_BONUS_TYPE, thenade), thenade.pokenade_type);

	// set refire so player can't even
	this.nade_refire = time + autocvar_g_nades_nade_refire;
	STAT(NADE_TIMER, this) = 0;

	if(this.nade)
		this.nade.nade_time_primed = thenade.nade_time_primed;
}

bool CanThrowNade(entity this);
void nade_touch(entity this, entity toucher)
{
	if(toucher)
		UpdateCSQCProjectile(this);

	if(toucher == this.realowner)
		return; // no this impacts

	if(autocvar_g_nades_pickup)
	if(time >= this.spawnshieldtime)
	if(!toucher.nade && GetResource(this, RES_HEALTH) == this.max_health) // no boosted shot pickups, thank you very much
	if(CanThrowNade(toucher)) // prevent some obvious things, like dead players
	if(IS_REAL_CLIENT(toucher)) // above checks for IS_PLAYER, don't need to do it here
	{
		nade_pickup(toucher, this);
		sound(this, CH_SHOTS_SINGLE, SND_Null, VOL_BASE, 0.5 *(ATTEN_LARGE + ATTEN_MAX));
		delete(this);
		return;
	}
	/*float is_weapclip = 0;
	if(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NODRAW)
	if (!(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NONSOLID))
	if (!(trace_dphitcontents & DPCONTENTS_OPAQUE))
		is_weapclip = 1;*/
	if(ITEM_TOUCH_NEEDKILL()) // || is_weapclip)
	{
		IL_EACH(g_projectiles, it.classname == "grapplinghook" && it.aiment == this,
		{
			RemoveHook(it);
		});
		delete(this);
		return;
	}

	PROJECTILE_TOUCH(this, toucher);

	//setsize(this, '-2 -2 -2', '2 2 2');
	//UpdateCSQCProjectile(this);
	if(GetResource(this, RES_HEALTH) == this.max_health)
	{
		spamsound(this, CH_SHOTS, SND_GRENADE_BOUNCE_RANDOM(), VOL_BASE, ATTEN_NORM);
		return;
	}

	this.enemy = toucher;
	nade_boom(this);
}

void nade_beep(entity this)
{
	sound(this, CH_SHOTS_SINGLE, SND_NADE_BEEP, VOL_BASE, 0.5 *(ATTEN_LARGE + ATTEN_MAX));
	setthink(this, nade_boom);
	this.nextthink = max(this.wait, time);
}

void nade_damage(entity this, entity inflictor, entity attacker, float damage, int deathtype, .entity weaponentity, vector hitloc, vector force)
{
	if(ITEM_DAMAGE_NEEDKILL(deathtype))
	{
		this.takedamage = DAMAGE_NO;
		nade_boom(this);
		return;
	}

	if(STAT(NADE_BONUS_TYPE, this) == NADE_TYPE_TRANSLOCATE.m_id || STAT(NADE_BONUS_TYPE, this) == NADE_TYPE_SPAWN.m_id)
		return;

	if (MUTATOR_CALLHOOK(Nade_Damage, this, DEATH_WEAPONOF(deathtype), force, damage)) {}
	else if(DEATH_ISWEAPON(deathtype, WEP_BLASTER))
	{
		force *= 1.5;
		damage = 0;
	}
	else if(DEATH_ISWEAPON(deathtype, WEP_VAPORIZER) && (deathtype & HITTYPE_SECONDARY))
	{
		force *= 0.5; // too much
		damage = 0;
	}
	else if(DEATH_ISWEAPON(deathtype, WEP_VORTEX) || DEATH_ISWEAPON(deathtype, WEP_VAPORIZER) || DEATH_ISWEAPON(deathtype, WEP_OVERKILL_NEX))
	{
		force *= 6;
		damage = this.max_health * 0.55;
	}
	else if(DEATH_ISWEAPON(deathtype, WEP_MACHINEGUN) || DEATH_ISWEAPON(deathtype, WEP_OVERKILL_MACHINEGUN))
		damage = this.max_health * 0.1;
	else if(DEATH_ISWEAPON(deathtype, WEP_SHOCKWAVE) || DEATH_ISWEAPON(deathtype, WEP_SHOTGUN) || DEATH_ISWEAPON(deathtype, WEP_OVERKILL_SHOTGUN)) // WEAPONTODO
	{
		if(!(deathtype & HITTYPE_SECONDARY))
			damage = this.max_health * 1.15;
	}

	// melee slaps
	entity death_weapon = DEATH_WEAPONOF(deathtype);
	if(((deathtype & HITTYPE_SECONDARY) ? (death_weapon.spawnflags & WEP_TYPE_MELEE_SEC) : (death_weapon.spawnflags & WEP_TYPE_MELEE_PRI)))
	{
		damage = this.max_health * 0.1;
		force *= 10;
	}

	this.velocity += force;
	UpdateCSQCProjectile(this);

	if(damage <= 0 || ((IS_ONGROUND(this)) && IS_PLAYER(attacker)))
		return;

	float hp = GetResource(this, RES_HEALTH);
	if(hp == this.max_health)
	{
		sound(this, CH_SHOTS_SINGLE, SND_Null, VOL_BASE, 0.5 *(ATTEN_LARGE + ATTEN_MAX));
		this.nextthink = max(time + this.nade_lifetime, time);
		setthink(this, nade_beep);
	}

	hp -= damage;
	SetResource(this, RES_HEALTH, hp);


	if ( STAT(NADE_BONUS_TYPE, this) != NADE_TYPE_HEAL.m_id || IS_PLAYER(attacker) )
		this.realowner = attacker;

	if(hp <= 0)
		W_PrepareExplosionByDamage(this, attacker, nade_boom);
	else
		nade_burn_spawn(this);
}

void toss_nade(entity e, bool set_owner, vector _velocity, float _time)
{
	if(e.nade == NULL)
		return;

	entity _nade = e.nade;
	e.nade = NULL;

	if(e.fake_nade)
		delete(e.fake_nade);
	e.fake_nade = NULL;

	Kill_Notification(NOTIF_ONE_ONLY, e, MSG_CENTER, CPID_NADES);

	makevectors(e.v_angle);

	// NOTE: always throw from first weapon entity?
	W_SetupShot(e, _nade.weaponentity_fld, false, false, SND_Null, CH_WEAPON_A, 0, DEATH_NADE.m_id);

	vector offset = (v_forward * autocvar_g_nades_throw_offset.x)
	              + (v_right * autocvar_g_nades_throw_offset.y)
	              + (v_up * autocvar_g_nades_throw_offset.z);

	setorigin(_nade, w_shotorg + offset);
	//setmodel(_nade, MDL_PROJECTILE_NADE);
	//setattachment(_nade, NULL, "");
	PROJECTILE_MAKETRIGGER(_nade);
	if(STAT(NADES_SMALL, e))
		setsize(_nade, '-8 -8 -8', '8 8 8');
	else
		setsize(_nade, '-16 -16 -16', '16 16 16');
	set_movetype(_nade, MOVETYPE_BOUNCE);

	tracebox(_nade.origin, _nade.mins, _nade.maxs, _nade.origin, MOVE_NOMONSTERS, _nade);
	if (trace_startsolid)
		setorigin(_nade, e.origin);

	if(e.v_angle.x >= 70 && e.v_angle.x <= 110 && PHYS_INPUT_BUTTON_CROUCH(e))
		_nade.velocity = '0 0 100';
	else if(autocvar_g_nades_nade_newton_style == 1)
		_nade.velocity = e.velocity + _velocity;
	else if(autocvar_g_nades_nade_newton_style == 2)
		_nade.velocity = _velocity;
	else
		_nade.velocity = W_CalculateProjectileVelocity(e, e.velocity, _velocity, true);

	if(set_owner)
		_nade.realowner = e;

	settouch(_nade, nade_touch);
	_nade.spawnshieldtime = time + 0.1; // prevent instantly picking up again
	SetResource(_nade, RES_HEALTH, autocvar_g_nades_nade_health);
	_nade.max_health = GetResource(_nade, RES_HEALTH);
	_nade.takedamage = DAMAGE_AIM;
	_nade.event_damage = nade_damage;
	setcefc(_nade, func_null);
	_nade.exteriormodeltoclient = NULL;
	_nade.traileffectnum = 0;
	_nade.teleportable = true;
	_nade.pushable = true;
	_nade.gravity = 1;
	_nade.missile_flags = MIF_SPLASH | MIF_ARC;
	_nade.damagedbycontents = true;
	IL_PUSH(g_damagedbycontents, _nade);
	_nade.angles = vectoangles(_nade.velocity);
	_nade.flags = FL_PROJECTILE;
	IL_PUSH(g_projectiles, _nade);
	IL_PUSH(g_bot_dodge, _nade);
	_nade.projectiledeathtype = DEATH_NADE.m_id;
	_nade.toss_time = time;
	_nade.solid = SOLID_CORPSE; //((STAT(NADE_BONUS_TYPE, _nade) == NADE_TYPE_TRANSLOCATE) ? SOLID_CORPSE : SOLID_BBOX);

	if(STAT(NADE_BONUS_TYPE, _nade) == NADE_TYPE_TRANSLOCATE.m_id || STAT(NADE_BONUS_TYPE, _nade) == NADE_TYPE_SPAWN.m_id)
		_nade.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_PLAYERCLIP | DPCONTENTS_BOTCLIP;
	else
		_nade.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY;

	nade_spawn(_nade);

	if(_time)
	{
		setthink(_nade, nade_boom);
		_nade.nextthink = _time;
	}

	e.nade_refire = time + autocvar_g_nades_nade_refire;
	STAT(NADE_TIMER, e) = 0;
}

void nades_GiveBonus(entity player, float score)
{
	if (autocvar_g_nades)
	if (autocvar_g_nades_bonus)
	if (IS_REAL_CLIENT(player))
	if (IS_PLAYER(player) && STAT(NADE_BONUS, player) < autocvar_g_nades_bonus_max)
	if (!STAT(FROZEN, player))
	if (!IS_DEAD(player))
	{
		if ( STAT(NADE_BONUS_SCORE, player) < 1 )
			STAT(NADE_BONUS_SCORE, player) += score/autocvar_g_nades_bonus_score_max;

		if ( STAT(NADE_BONUS_SCORE, player) >= 1 )
		{
			Send_Notification(NOTIF_ONE, player, MSG_CENTER, CENTER_NADE_BONUS);
			play2(player, SND(NADE_BONUS));
			STAT(NADE_BONUS, player)++;
			STAT(NADE_BONUS_SCORE, player) -= 1;
		}
	}
}

/** Remove all bonus nades from a player */
void nades_RemoveBonus(entity player)
{
	STAT(NADE_BONUS, player) = STAT(NADE_BONUS_SCORE, player) = 0;
}

MUTATOR_HOOKFUNCTION(nades, PutClientInServer)
{
    entity player = M_ARGV(0, entity);

	nades_RemoveBonus(player);
}

bool nade_customize(entity this, entity client)
{
	//if(IS_SPEC(client)) { return false; }
	if(client == this.exteriormodeltoclient || (IS_SPEC(client) && client.enemy == this.exteriormodeltoclient))
	{
		// somewhat hide the model, but keep the glow
		//this.effects = 0;
		if(this.traileffectnum)
			this.traileffectnum = 0;
		this.alpha = -1;
	}
	else
	{
		//this.effects = EF_ADDITIVE | EF_FULLBRIGHT | EF_LOWPRECISION;
		if(!this.traileffectnum)
		{
			entity nade = REGISTRY_GET(Nades, STAT(NADE_BONUS_TYPE, this));
			this.traileffectnum = _particleeffectnum(Nade_TrailEffect(nade.m_projectile[false], this.team).eent_eff_name);
		}
		this.alpha = 1;
	}

	return true;
}

void spawn_held_nade(entity player, entity nowner, float ntime, int ntype, string pntype)
{
	entity n = new(nade), fn = new(fake_nade);

	STAT(NADE_BONUS_TYPE, n) = max(1, ntype);
	n.pokenade_type = pntype;

	if(REGISTRY_GET(Nades, STAT(NADE_BONUS_TYPE, n)) == NADE_TYPE_Null)
		STAT(NADE_BONUS_TYPE, n) = NADE_TYPE_NORMAL.m_id;

	.entity weaponentity = weaponentities[0]; // TODO: unhardcode

	setmodel(n, MDL_PROJECTILE_NADE);
	//setattachment(n, player, "bip01 l hand");
	n.exteriormodeltoclient = player;
	setcefc(n, nade_customize);
	n.traileffectnum = _particleeffectnum(Nade_TrailEffect(REGISTRY_GET(Nades, STAT(NADE_BONUS_TYPE, n)).m_projectile[false], player.team).eent_eff_name);
	n.colormod = REGISTRY_GET(Nades, STAT(NADE_BONUS_TYPE, n)).m_color;
	n.realowner = nowner;
	n.colormap = player.colormap;
	n.glowmod = player.glowmod;
	n.wait = time + max(0, ntime);
	n.nade_time_primed = time;
	setthink(n, nade_beep);
	n.nextthink = max(n.wait - 3, time);
	n.projectiledeathtype = DEATH_NADE.m_id;
	n.weaponentity_fld = weaponentity;
	n.nade_lifetime = ntime;
	n.alpha = REGISTRY_GET(Nades, STAT(NADE_BONUS_TYPE, n)).m_alpha;

	setmodel(fn, MDL_NADE_VIEW);
	//setattachment(fn, player.(weaponentity), "");
	fn.viewmodelforclient = player;
	fn.realowner = fn.owner = player;
	fn.colormod = REGISTRY_GET(Nades, STAT(NADE_BONUS_TYPE, n)).m_color;
	fn.colormap = player.colormap;
	fn.glowmod = player.glowmod;
	setthink(fn, SUB_Remove);
	fn.nextthink = n.wait;
	fn.weaponentity_fld = weaponentity;
	fn.alpha = REGISTRY_GET(Nades, STAT(NADE_BONUS_TYPE, n)).m_alpha;

	player.nade = n;
	player.fake_nade = fn;
}

void nade_prime(entity this)
{
	if(autocvar_g_nades_bonus_only && !STAT(NADE_BONUS, this))
		return; // only allow bonus nades

	// TODO: handle old nade if it exists?
	if(this.nade)
		delete(this.nade);
	this.nade = NULL;

	if(this.fake_nade)
		delete(this.fake_nade);
	this.fake_nade = NULL;

	int ntype;
	string pntype = this.pokenade_type;

	if(StatusEffects_active(STATUSEFFECT_Strength, this) && autocvar_g_nades_bonus_onstrength)
		ntype = STAT(NADE_BONUS_TYPE, this);
	else if (STAT(NADE_BONUS, this) >= 1)
	{
		ntype = STAT(NADE_BONUS_TYPE, this);
		pntype = this.pokenade_type;
		STAT(NADE_BONUS, this) -= 1;
	}
	else
	{
		ntype = ((autocvar_g_nades_client_select) ? CS_CVAR(this).cvar_cl_nade_type : autocvar_g_nades_nade_type);
		pntype = ((autocvar_g_nades_client_select) ? CS_CVAR(this).cvar_cl_pokenade_type : autocvar_g_nades_pokenade_monster_type);
	}

	spawn_held_nade(this, this, autocvar_g_nades_nade_lifetime, ntype, pntype);
}

bool CanThrowNade(entity this)
{
	return !(this.vehicle || !autocvar_g_nades || IS_DEAD(this) || !IS_PLAYER(this) || weaponLocked(this));
}

.bool nade_altbutton;

void nades_CheckThrow(entity this)
{
	if(!CanThrowNade(this))
		return;

	entity held_nade = this.nade;
	if (!held_nade)
	{
		this.nade_altbutton = true;
		if(time > this.nade_refire)
		{
			nade_prime(this);
			this.nade_refire = time + autocvar_g_nades_nade_refire;
		}
	}
	else
	{
		this.nade_altbutton = false;
		if (time >= held_nade.nade_time_primed + 1) {
			makevectors(this.v_angle);
			float _force = time - held_nade.nade_time_primed;
			_force /= autocvar_g_nades_nade_lifetime;
			_force = autocvar_g_nades_nade_minforce + (_force * (autocvar_g_nades_nade_maxforce - autocvar_g_nades_nade_minforce));
			vector dir = (v_forward * 0.75 + v_up * 0.2 + v_right * 0.05);
			dir = W_CalculateSpread(dir, autocvar_g_nades_spread, autocvar_g_weaponspreadfactor, autocvar_g_projectiles_spread_style);
			toss_nade(this, true, dir * _force, 0);
		}
	}
}

void nades_Clear(entity player)
{
	if(player.nade)
		delete(player.nade);
	if(player.fake_nade)
		delete(player.fake_nade);

	player.nade = player.fake_nade = NULL;
	STAT(NADE_TIMER, player) = 0;
}

MUTATOR_HOOKFUNCTION(nades, VehicleEnter)
{
	entity player = M_ARGV(0, entity);

	if(player.nade)
		toss_nade(player, true, '0 0 100', max(player.nade.wait, time + 0.05));
}

CLASS(NadeOffhand, OffhandWeapon)
    METHOD(NadeOffhand, offhand_think, void(NadeOffhand this, entity player, bool key_pressed))
    {
    	entity held_nade = player.nade;

        if (!CanThrowNade(player)) return;
        if (!(time > player.nade_refire)) return;
		if (key_pressed) {
			if (!held_nade) {
				nade_prime(player);
				held_nade = player.nade;
			}
		} else if (time >= held_nade.nade_time_primed + 1) {
			if (held_nade) {
				makevectors(player.v_angle);
				float _force = time - held_nade.nade_time_primed;
				_force /= autocvar_g_nades_nade_lifetime;
				_force = autocvar_g_nades_nade_minforce + (_force * (autocvar_g_nades_nade_maxforce - autocvar_g_nades_nade_minforce));
				vector dir = (v_forward * 0.7 + v_up * 0.2 + v_right * 0.1);
				dir = W_CalculateSpread(dir, autocvar_g_nades_spread, autocvar_g_weaponspreadfactor, autocvar_g_projectiles_spread_style);
				toss_nade(player, false, dir * _force, 0);
			}
		}
    }
ENDCLASS(NadeOffhand)
NadeOffhand OFFHAND_NADE;
REGISTER_MUTATOR(nades, autocvar_g_nades)
{
	MUTATOR_ONADD
	{
		OFFHAND_NADE = NEW(NadeOffhand);
	}
	return 0;
}

MUTATOR_HOOKFUNCTION(nades, ForbidThrowCurrentWeapon, CBC_ORDER_LAST)
{
    entity player = M_ARGV(0, entity);

	if (player.offhand != OFFHAND_NADE || (STAT(WEAPONS, player) & WEPSET(HOOK)) || autocvar_g_nades_override_dropweapon) {
		nades_CheckThrow(player);
		return true;
	}
}

#ifdef IN_REVIVING_RANGE
	#undef IN_REVIVING_RANGE
#endif

// returns true if player is reviving it
#define IN_REVIVING_RANGE(player, it, revive_extra_size) \
	(it != player && !IS_DEAD(it) && SAME_TEAM(it, player) \
	&& boxesoverlap(player.absmin - revive_extra_size, player.absmax + revive_extra_size, it.absmin, it.absmax))

MUTATOR_HOOKFUNCTION(nades, PlayerPreThink)
{
	entity player = M_ARGV(0, entity);

	if (!IS_PLAYER(player)) { return; }

	if (player.nade && (player.offhand != OFFHAND_NADE || (STAT(WEAPONS, player) & WEPSET(HOOK))))
		OFFHAND_NADE.offhand_think(OFFHAND_NADE, player, player.nade_altbutton);

	entity held_nade = player.nade;
	if (held_nade)
	{
		STAT(NADE_TIMER, player) = bound(0, (time - held_nade.nade_time_primed) / held_nade.nade_lifetime, 1);
		// LOG_TRACEF("%d %d", STAT(NADE_TIMER, player), time - held_nade.nade_time_primed);
		makevectors(player.angles);
		held_nade.velocity = player.velocity;
		setorigin(held_nade, player.origin + player.view_ofs + v_forward * 8 + v_right * -8 + v_up * 0);
		held_nade.angles_y = player.angles.y;

		if (time + 0.1 >= held_nade.wait)
		{
			toss_nade(player, false, '0 0 0', time + 0.05);
			Send_Notification(NOTIF_ONE, player, MSG_CENTER, CENTER_NADE_THROW);
		}
	}

	if(IS_PLAYER(player))
	{
		if ( autocvar_g_nades_bonus && autocvar_g_nades )
		{
			entity key;
			float key_count = 0;
			FOR_EACH_KH_KEY(key) if(key.owner == player) { ++key_count; }

			float time_score;
			if(GameRules_scoring_is_vip(player))
				time_score = autocvar_g_nades_bonus_score_time_flagcarrier;
			else
				time_score = autocvar_g_nades_bonus_score_time;

			if(key_count)
				time_score = autocvar_g_nades_bonus_score_time_flagcarrier * key_count; // multiply by the number of keys the player is holding

			if(autocvar_g_nades_bonus_client_select)
			{
				STAT(NADE_BONUS_TYPE, player) = CS_CVAR(player).cvar_cl_nade_type;
				player.pokenade_type = CS_CVAR(player).cvar_cl_pokenade_type;
			}
			else
			{
				STAT(NADE_BONUS_TYPE, player) = autocvar_g_nades_bonus_type;
				player.pokenade_type = autocvar_g_nades_pokenade_monster_type;
			}

			STAT(NADE_BONUS_TYPE, player) = bound(1, STAT(NADE_BONUS_TYPE, player), Nades_COUNT);

			if(STAT(NADE_BONUS_SCORE, player) >= 0 && autocvar_g_nades_bonus_score_max)
				nades_GiveBonus(player, time_score / autocvar_g_nades_bonus_score_max);
		}
		else
		{
			STAT(NADE_BONUS, player) = STAT(NADE_BONUS_SCORE, player) = 0;
		}

		if(STAT(VEIL_ORB, player) && STAT(VEIL_ORB, player) <= time)
		{
			STAT(VEIL_ORB, player) = 0;
			if(player.vehicle)
				player.vehicle.alpha = player.vehicle.nade_veil_prevalpha;
			else
				player.alpha = player.nade_veil_prevalpha;
		}
	}

	if (!(frametime && IS_PLAYER(player)))
		return true;

	entity revivers_last = NULL;
	entity revivers_first = NULL;

	bool player_is_reviving = false;
	int n = 0;
	vector revive_extra_size = '1 1 1' * autocvar_g_freezetag_revive_extra_size;
	FOREACH_CLIENT(IS_PLAYER(it) && IN_REVIVING_RANGE(player, it, revive_extra_size), {
		// check if player is reviving anyone
		if (STAT(FROZEN, it) == FROZEN_TEMP_DYING)
		{
			if ((STAT(FROZEN, player) == FROZEN_TEMP_DYING))
				continue;
			if (!IN_REVIVING_RANGE(player, it, revive_extra_size))
				continue;
			player_is_reviving = true;
			break;
		}

		if (!(STAT(FROZEN, player) == FROZEN_TEMP_DYING))
			continue; // both player and it are NOT frozen
		if (revivers_last)
			revivers_last.chain = it;
		revivers_last = it;
		if (!revivers_first)
			revivers_first = it;
		++n;
	});
	if (revivers_last)
		revivers_last.chain = NULL;

	if (!n) // no teammate nearby
	{
		// freezetag already resets revive progress
		if (!g_freezetag && !STAT(FROZEN, player) && !player_is_reviving)
			STAT(REVIVE_PROGRESS, player) = 0; // thawing nobody
	}
	else if (n > 0 && STAT(FROZEN, player) == FROZEN_TEMP_DYING) // OK, there is at least one teammate reviving us
	{
		STAT(REVIVE_PROGRESS, player) = bound(0, STAT(REVIVE_PROGRESS, player) + frametime * max(1/60, autocvar_g_freezetag_revive_speed), 1);
		// undo what PlayerPreThink did
		STAT(REVIVE_PROGRESS, player) = bound(0, STAT(REVIVE_PROGRESS, player) + frametime * player.revive_speed, 1);
		SetResource(player, RES_HEALTH, max(1, STAT(REVIVE_PROGRESS, player) * start_health));

		if(STAT(REVIVE_PROGRESS, player) >= 1)
		{
			Unfreeze(player, false);

			Send_Notification(NOTIF_ONE, player, MSG_CENTER, CENTER_FREEZETAG_REVIVED, revivers_first.netname);
			Send_Notification(NOTIF_ONE, revivers_first, MSG_CENTER, CENTER_FREEZETAG_REVIVE, player.netname);
		}

		for(entity it = revivers_first; it; it = it.chain)
			STAT(REVIVE_PROGRESS, it) = STAT(REVIVE_PROGRESS, player);
	}
}

MUTATOR_HOOKFUNCTION(nades, PlayerPhysics_UpdateStats)
{
	entity player = M_ARGV(0, entity);
	// these automatically reset, no need to worry

	if(STAT(ENTRAP_ORB, player) > time)
		STAT(MOVEVARS_HIGHSPEED, player) *= autocvar_g_nades_entrap_speed;
}

MUTATOR_HOOKFUNCTION(nades, MonsterMove)
{
    entity mon = M_ARGV(0, entity);

	if (STAT(ENTRAP_ORB, mon) > time)
	{
		M_ARGV(1, float) *= autocvar_g_nades_entrap_speed; // run speed
		M_ARGV(2, float) *= autocvar_g_nades_entrap_speed; // walk speed
	}

	if (STAT(VEIL_ORB, mon) && STAT(VEIL_ORB, mon) <= time)
	{
		mon.alpha = mon.nade_veil_prevalpha;
		STAT(VEIL_ORB, mon) = 0;
	}
}

MUTATOR_HOOKFUNCTION(nades, PlayerSpawn)
{
	entity player = M_ARGV(0, entity);

	if(autocvar_g_nades_spawn)
		player.nade_refire = time + autocvar_g_spawnshieldtime;
	else
		player.nade_refire  = time + autocvar_g_nades_nade_refire;

	if(autocvar_g_nades_bonus_client_select)
		STAT(NADE_BONUS_TYPE, player) = CS_CVAR(player).cvar_cl_nade_type;

	STAT(NADE_TIMER, player) = 0;

	if (!player.offhand) player.offhand = OFFHAND_NADE;

	if(player.nade_spawnloc)
	{
		setorigin(player, player.nade_spawnloc.origin);
		player.nade_spawnloc.cnt -= 1;

		if(player.nade_spawnloc.cnt <= 0)
		{
			delete(player.nade_spawnloc);
			player.nade_spawnloc = NULL;
		}
	}
}

MUTATOR_HOOKFUNCTION(nades, PlayerDies, CBC_ORDER_LAST)
{
	entity frag_attacker = M_ARGV(1, entity);
	entity frag_target = M_ARGV(2, entity);

	if(frag_target.nade)
	if(!STAT(FROZEN, frag_target) || !autocvar_g_freezetag_revive_nade)
		toss_nade(frag_target, true, '0 0 100', max(frag_target.nade.wait, time + 0.05));

	if(IS_PLAYER(frag_attacker))
	{
		float killcount_bonus = ((CS(frag_attacker).killcount >= 1) ? bound(0, autocvar_g_nades_bonus_score_minor * CS(frag_attacker).killcount, autocvar_g_nades_bonus_score_medium) 
																	: autocvar_g_nades_bonus_score_minor);
		if (SAME_TEAM(frag_attacker, frag_target) || frag_attacker == frag_target)
			nades_RemoveBonus(frag_attacker);
		else if(GameRules_scoring_is_vip(frag_target))
			nades_GiveBonus(frag_attacker, autocvar_g_nades_bonus_score_medium);
		else if(autocvar_g_nades_bonus_score_spree && CS(frag_attacker).killcount > 1)
		{
			#define SPREE_ITEM(counta,countb,center,normal,gentle) \
				case counta: { nades_GiveBonus(frag_attacker, autocvar_g_nades_bonus_score_spree); break; }
			switch(CS(frag_attacker).killcount)
			{
				KILL_SPREE_LIST
				default: nades_GiveBonus(frag_attacker, autocvar_g_nades_bonus_score_minor); break;
			}
			#undef SPREE_ITEM
		}
		else
			nades_GiveBonus(frag_attacker, killcount_bonus);
	}

	nades_RemoveBonus(frag_target);
}

MUTATOR_HOOKFUNCTION(nades, Damage_Calculate)
{
	entity frag_inflictor = M_ARGV(0, entity);
	entity frag_attacker = M_ARGV(1, entity);
	entity frag_target = M_ARGV(2, entity);
	float frag_deathtype = M_ARGV(3, float);

	if(autocvar_g_freezetag_revive_nade && STAT(FROZEN, frag_target) && frag_attacker == frag_target && frag_deathtype == DEATH_NADE.m_id)
	if(time - frag_inflictor.toss_time <= 0.1)
	{
		Unfreeze(frag_target, false);
		SetResource(frag_target, RES_HEALTH, autocvar_g_freezetag_revive_nade_health);
		Send_Effect(EFFECT_ICEORGLASS, frag_target.origin, '0 0 0', 3);
		M_ARGV(4, float) = 0;
		M_ARGV(6, vector) = '0 0 0';
		Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_FREEZETAG_REVIVED_NADE, frag_target.netname);
		Send_Notification(NOTIF_ONE, frag_target, MSG_CENTER, CENTER_FREEZETAG_REVIVE_SELF);
	}
}

MUTATOR_HOOKFUNCTION(nades, MonsterDies)
{
	entity frag_target = M_ARGV(0, entity);
	entity frag_attacker = M_ARGV(1, entity);

	if(IS_PLAYER(frag_attacker))
	if(DIFF_TEAM(frag_attacker, frag_target))
	if(!(frag_target.spawnflags & MONSTERFLAG_SPAWNED))
		nades_GiveBonus(frag_attacker, autocvar_g_nades_bonus_score_minor);
}

MUTATOR_HOOKFUNCTION(nades, DropSpecialItems)
{
	entity frag_target = M_ARGV(0, entity);

	if(frag_target.nade)
		toss_nade(frag_target, true, '0 0 0', time + 0.05);
}

void nades_RemovePlayer(entity this)
{
	nades_Clear(this);
	nades_RemoveBonus(this);
}

MUTATOR_HOOKFUNCTION(nades, MakePlayerObserver) { entity player = M_ARGV(0, entity); nades_RemovePlayer(player); }
MUTATOR_HOOKFUNCTION(nades, ClientDisconnect) { entity player = M_ARGV(0, entity); nades_RemovePlayer(player); }
MUTATOR_HOOKFUNCTION(nades, reset_map_global)
{
	FOREACH_CLIENT(IS_PLAYER(it),
	{
		nades_RemovePlayer(it);
	});
}

MUTATOR_HOOKFUNCTION(nades, SpectateCopy)
{
	entity spectatee = M_ARGV(0, entity);
	entity client = M_ARGV(1, entity);

	STAT(NADE_TIMER, client) = STAT(NADE_TIMER, spectatee);
	STAT(NADE_BONUS_TYPE, client) = STAT(NADE_BONUS_TYPE, spectatee);
	client.pokenade_type = spectatee.pokenade_type;
	STAT(NADE_BONUS, client) = STAT(NADE_BONUS, spectatee);
	STAT(NADE_BONUS_SCORE, client) = STAT(NADE_BONUS_SCORE, spectatee);
	STAT(HEALING_ORB, client) = STAT(HEALING_ORB, spectatee);
	STAT(HEALING_ORB_ALPHA, client) = STAT(HEALING_ORB_ALPHA, spectatee);
	STAT(ENTRAP_ORB, client) = STAT(ENTRAP_ORB, spectatee);
	STAT(ENTRAP_ORB_ALPHA, client) = STAT(ENTRAP_ORB_ALPHA, spectatee);
	STAT(VEIL_ORB, client) = STAT(VEIL_ORB, spectatee);
	STAT(VEIL_ORB_ALPHA, client) = STAT(VEIL_ORB_ALPHA, spectatee);
}

MUTATOR_HOOKFUNCTION(nades, BuildMutatorsString)
{
	M_ARGV(0, string) = strcat(M_ARGV(0, string), ":Nades");
}

MUTATOR_HOOKFUNCTION(nades, BuildGameplayTipsString)
{
	M_ARGV(0, string) = strcat(M_ARGV(0, string), "\n\n^3nades^8 are enabled, press 'g' (dropweapon) to use them\n");
}

#endif
