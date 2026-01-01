#include "fireball.qh"

#ifdef SVQC

void W_Fireball_Explode(entity this, entity directhitentity)
{
	entity e;
	float dist;
	float points;
	vector dir;
	float d;

	this.event_damage = func_null;
	this.takedamage = DAMAGE_NO;

	// 1. dist damage
	d = (GetResource(this.realowner, RES_HEALTH) + GetResource(this.realowner, RES_ARMOR));

	RadiusDamage(
		this,
		this.realowner,
		WEP_CVAR_PRI(WEP_FIREBALL, damage),
		WEP_CVAR_PRI(WEP_FIREBALL, edgedamage),
		WEP_CVAR_PRI(WEP_FIREBALL, radius),
		NULL,
		NULL,
		WEP_CVAR_PRI(WEP_FIREBALL, force),
		this.projectiledeathtype,
		this.weaponentity_fld, directhitentity
	);

	if(GetResource(this.realowner, RES_HEALTH) + GetResource(this.realowner, RES_ARMOR) >= d)
	if(!this.cnt)
	{
		modeleffect_spawn("models/sphere/sphere.md3", 0, 0, this.origin, '0 0 0', '0 0 0', '0 0 0', 0, WEP_CVAR_PRI(WEP_FIREBALL, bfgradius), 0.2, 0.05, 0.25);

		// 2. bfg effect
		// NOTE: this cannot be made warpzone aware by design. So, better intentionally ignore warpzones here.
		for(e = findradius(this.origin, WEP_CVAR_PRI(WEP_FIREBALL, bfgradius)); e; e = e.chain)
		{
			if(e != this.realowner && e.takedamage == DAMAGE_AIM && !IS_INDEPENDENT_PLAYER(e))
			if(!IS_PLAYER(e) || !this.realowner || DIFF_TEAM(e, this))
			{

				// can we see fireball?
				traceline(e.origin + e.view_ofs, this.origin, MOVE_NORMAL, e);
				if(/* trace_startsolid || */ trace_fraction != 1) // startsolid should be never happening anyway
					continue;
				// can we see player who shot fireball?
				traceline(e.origin + e.view_ofs, this.realowner.origin + this.realowner.view_ofs, MOVE_NORMAL, e);
				if(trace_ent != this.realowner)
				if(/* trace_startsolid || */ trace_fraction != 1)
					continue;
				dist = vlen(this.origin - e.origin - e.view_ofs);
				points = (1 - sqrt(dist / WEP_CVAR_PRI(WEP_FIREBALL, bfgradius)));
				if(points <= 0)
					continue;
				dir = normalize(e.origin + e.view_ofs - this.origin);

				if(accuracy_isgooddamage(this.realowner, e))
					accuracy_add(this.realowner, WEP_FIREBALL, 0, WEP_CVAR_PRI(WEP_FIREBALL, bfgdamage) * points, 0); // add to hit

				Damage(
					e,
					this,
					this.realowner,
					WEP_CVAR_PRI(WEP_FIREBALL, bfgdamage) * points,
					this.projectiledeathtype | HITTYPE_BOUNCE | HITTYPE_SPLASH,
					this.weaponentity_fld,
					e.origin + e.view_ofs,
					WEP_CVAR_PRI(WEP_FIREBALL, bfgforce) * dir
				);

				Send_Effect(EFFECT_FIREBALL_BFGDAMAGE, e.origin, -1 * dir, 1);
			}
		}
	}

	delete(this);
}

void W_Fireball_Explode_think(entity this)
{
	W_Fireball_Explode(this, NULL);
}

void W_Fireball_Explode_use(entity this, entity actor, entity trigger)
{
	W_Fireball_Explode(this, trigger);
}

void W_Fireball_TouchExplode(entity this, entity toucher)
{
	PROJECTILE_TOUCH(this, toucher);
	W_Fireball_Explode(this, toucher);
}

void W_Fireball_LaserPlay(entity this, float dt, float dist, float damage, float edgedamage, float burntime)
{
	entity e;
	float d;
	vector p;

	if(damage <= 0)
		return;

	RandomSelection_Init();
	for(e = WarpZone_FindRadius(this.origin, dist, true); e; e = e.chain)
	{
		if(STAT(FROZEN, e) || StatusEffects_active(STATUSEFFECT_Frozen, e)) continue;
		if(e == this.realowner) continue;
		if(IS_INDEPENDENT_PLAYER(e)) continue;
		if(e.takedamage != DAMAGE_AIM) continue;
		if(IS_PLAYER(e) && this.realowner && SAME_TEAM(e, this)) continue;

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
		Fire_AddDamage(RandomSelection_chosen_ent, this.realowner, d * burntime, burntime, this.projectiledeathtype | HITTYPE_BOUNCE);
		//trailparticles(this, particleeffectnum(EFFECT_FIREBALL_LASER), this.origin, RandomSelection_chosen_ent.fireball_impactvec);
		Send_Effect(EFFECT_FIREBALL_LASER, this.origin, RandomSelection_chosen_ent.fireball_impactvec - this.origin, 1);
	}
}

void W_Fireball_Think(entity this)
{
	if(time > this.pushltime)
	{
		this.cnt = 1;
		this.projectiledeathtype |= HITTYPE_SPLASH;
		W_Fireball_Explode(this, NULL);
		return;
	}

	W_Fireball_LaserPlay(this, 0.1, WEP_CVAR_PRI(WEP_FIREBALL, laserradius), WEP_CVAR_PRI(WEP_FIREBALL, laserdamage), WEP_CVAR_PRI(WEP_FIREBALL, laseredgedamage), WEP_CVAR_PRI(WEP_FIREBALL, laserburntime));

	this.nextthink = time + 0.1;
}

void W_Fireball_Damage(entity this, entity inflictor, entity attacker, float damage, int deathtype, .entity weaponentity, vector hitloc, vector force)
{
	if(GetResource(this, RES_HEALTH) <= 0)
		return;

	if(!W_CheckProjectileDamage(inflictor.realowner, this.realowner, deathtype, -1)) // no exceptions
		return; // g_projectiles_damage says to halt

	TakeResource(this, RES_HEALTH, damage);
	if(GetResource(this, RES_HEALTH) <= 0)
	{
		this.cnt = 1;
		W_PrepareExplosionByDamage(this, attacker, W_Fireball_Explode_think);
	}
}

void W_Fireball_Attack1(entity actor, .entity weaponentity)
{
	W_SetupShot_ProjectileSize(actor, weaponentity, '-16 -16 -16', '16 16 16', false, 2, SND_FIREBALL_FIRE2, CH_WEAPON_A, WEP_CVAR_PRI(WEP_FIREBALL, damage) + WEP_CVAR_PRI(WEP_FIREBALL, bfgdamage), WEP_FIREBALL.m_id);

	W_MuzzleFlash(WEP_FIREBALL, actor, weaponentity, w_shotorg, w_shotdir);

	entity proj = new(plasma_prim);
	proj.owner = proj.realowner = actor;
	proj.bot_dodge = true;
	proj.bot_dodgerating = WEP_CVAR_PRI(WEP_FIREBALL, damage);
	proj.pushltime = time + WEP_CVAR_PRI(WEP_FIREBALL, lifetime);
	proj.use = W_Fireball_Explode_use;
	setthink(proj, W_Fireball_Think);
	proj.nextthink = time;
	SetResourceExplicit(proj, RES_HEALTH, WEP_CVAR_PRI(WEP_FIREBALL, health));
	proj.team = actor.team;
	proj.event_damage = W_Fireball_Damage;
	proj.takedamage = DAMAGE_YES;
	proj.damageforcescale = WEP_CVAR_PRI(WEP_FIREBALL, damageforcescale);
	PROJECTILE_MAKETRIGGER(proj);
	proj.projectiledeathtype = WEP_FIREBALL.m_id;
	proj.weaponentity_fld = weaponentity;
	setorigin(proj, w_shotorg);

	set_movetype(proj, MOVETYPE_FLY);
	W_SetupProjVelocity_PRI(proj, WEP_FIREBALL);
	proj.angles = vectoangles(proj.velocity);
	settouch(proj, W_Fireball_TouchExplode);
	setsize(proj, '-16 -16 -16', '16 16 16');
	proj.flags = FL_PROJECTILE;
	IL_PUSH(g_projectiles, proj);
	IL_PUSH(g_bot_dodge, proj);
	proj.missile_flags = MIF_SPLASH | MIF_PROXY;

	CSQCProjectile(proj, true, PROJECTILE_FIREBALL, true);

	MUTATOR_CALLHOOK(EditProjectile, actor, proj);
}

void W_Fireball_AttackEffect(entity actor, .entity weaponentity, float i, vector f_diff)
{
	W_SetupShot_ProjectileSize(actor, weaponentity, '-16 -16 -16', '16 16 16', false, 0, SND_Null, 0, 0, WEP_FIREBALL.m_id); // TODO: probably doesn't need deathtype, just a prefire effect
	w_shotorg += f_diff.x * v_up + f_diff.y * v_right;
	Send_Effect(EFFECT_FIREBALL_PRE_MUZZLEFLASH, w_shotorg, w_shotdir * 1000, 1);
}

void W_Fireball_Attack1_Frame4(Weapon thiswep, entity actor, .entity weaponentity, int fire)
{
	W_Fireball_Attack1(actor, weaponentity);
	weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_PRI(WEP_FIREBALL, animtime), w_ready);
}

void W_Fireball_Attack1_Frame3(Weapon thiswep, entity actor, .entity weaponentity, int fire)
{
	W_Fireball_AttackEffect(actor, weaponentity, 0, '+1.25 +3.75 0');
	weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_PRI(WEP_FIREBALL, animtime), W_Fireball_Attack1_Frame4);
}

void W_Fireball_Attack1_Frame2(Weapon thiswep, entity actor, .entity weaponentity, int fire)
{
	W_Fireball_AttackEffect(actor, weaponentity, 0, '-1.25 +3.75 0');
	weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_PRI(WEP_FIREBALL, animtime), W_Fireball_Attack1_Frame3);
}

void W_Fireball_Attack1_Frame1(Weapon thiswep, entity actor, .entity weaponentity, int fire)
{
	W_Fireball_AttackEffect(actor, weaponentity, 1, '+1.25 -3.75 0');
	weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_PRI(WEP_FIREBALL, animtime), W_Fireball_Attack1_Frame2);
}

void W_Fireball_Attack1_Frame0(Weapon thiswep, entity actor, .entity weaponentity, int fire)
{
	W_Fireball_AttackEffect(actor, weaponentity, 0, '-1.25 -3.75 0');
	sound(actor, CH_WEAPON_SINGLE, SND_FIREBALL_PREFIRE2, VOL_BASE, ATTEN_NORM);
	weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_PRI(WEP_FIREBALL, animtime), W_Fireball_Attack1_Frame1);
}

void W_Fireball_Firemine_Think(entity this)
{
	if(time > this.pushltime)
	{
		delete(this);
		return;
	}

	// make it "hot" once it leaves its owner
	if(this.owner)
	{
		if(vdist(this.origin - this.owner.origin - this.owner.view_ofs, >, WEP_CVAR_SEC(WEP_FIREBALL, laserradius)))
		{
			this.cnt += 1;
			if(this.cnt == 3)
				this.owner = NULL;
		}
		else
			this.cnt = 0;
	}

	W_Fireball_LaserPlay(this, 0.1, WEP_CVAR_SEC(WEP_FIREBALL, laserradius), WEP_CVAR_SEC(WEP_FIREBALL, laserdamage), WEP_CVAR_SEC(WEP_FIREBALL, laseredgedamage), WEP_CVAR_SEC(WEP_FIREBALL, laserburntime));

	this.nextthink = time + 0.1;
}

void W_Fireball_Firemine_Touch(entity this, entity toucher)
{
	PROJECTILE_TOUCH(this, toucher);
	if(toucher.takedamage == DAMAGE_AIM)
	if(Fire_AddDamage(toucher, this.realowner, WEP_CVAR_SEC(WEP_FIREBALL, damage), WEP_CVAR_SEC(WEP_FIREBALL, damagetime), this.projectiledeathtype) >= 0)
	{
		delete(this);
		return;
	}
	this.projectiledeathtype |= HITTYPE_BOUNCE;
}

void W_Fireball_Attack2(entity actor, .entity weaponentity)
{
	entity proj;
	vector f_diff;
	float c;

	c = actor.(weaponentity).bulletcounter % 4;
	switch(c)
	{
		case 0:
			f_diff = '-1.25 -3.75 0';
			break;
		case 1:
			f_diff = '+1.25 -3.75 0';
			break;
		case 2:
			f_diff = '-1.25 +3.75 0';
			break;
		case 3:
		default:
			f_diff = '+1.25 +3.75 0';
			break;
	}
	W_SetupShot_ProjectileSize(actor, weaponentity, '-4 -4 -4', '4 4 4', false, 2, SND_FIREBALL_FIRE, CH_WEAPON_A, WEP_CVAR_SEC(WEP_FIREBALL, damage), WEP_FIREBALL.m_id | HITTYPE_SECONDARY);
	traceline(w_shotorg, w_shotorg + f_diff_x * v_up + f_diff_y * v_right, MOVE_NORMAL, actor);
	w_shotorg = trace_endpos;

	W_MuzzleFlash(WEP_FIREBALL, actor, weaponentity, w_shotorg, w_shotdir);

	proj = new(grenade);
	proj.owner = proj.realowner = actor;
	proj.bot_dodge = true;
	proj.bot_dodgerating = WEP_CVAR_SEC(WEP_FIREBALL, damage);
	set_movetype(proj, MOVETYPE_BOUNCE);
	proj.projectiledeathtype = WEP_FIREBALL.m_id | HITTYPE_SECONDARY;
	settouch(proj, W_Fireball_Firemine_Touch);
	PROJECTILE_MAKETRIGGER(proj);
	setsize(proj, '-4 -4 -4', '4 4 4');
	setorigin(proj, w_shotorg);
	setthink(proj, W_Fireball_Firemine_Think);
	proj.nextthink = time;
	proj.damageforcescale = WEP_CVAR_SEC(WEP_FIREBALL, damageforcescale);
	proj.pushltime = time + WEP_CVAR_SEC(WEP_FIREBALL, lifetime);
	W_SetupProjVelocity_UP_SEC(proj, WEP_FIREBALL);

	proj.angles = vectoangles(proj.velocity);
	proj.flags = FL_PROJECTILE;
	IL_PUSH(g_projectiles, proj);
	IL_PUSH(g_bot_dodge, proj);
	proj.missile_flags = MIF_SPLASH | MIF_PROXY | MIF_ARC;

	CSQCProjectile(proj, true, PROJECTILE_FIREMINE, true);

	MUTATOR_CALLHOOK(EditProjectile, actor, proj);
}

METHOD(Fireball, wr_aim, void(entity thiswep, entity actor, .entity weaponentity))
{
	PHYS_INPUT_BUTTON_ATCK(actor) = false;
	PHYS_INPUT_BUTTON_ATCK2(actor) = false;
	if(actor.bot_primary_fireballmooth == 0)
	{
		if(bot_aim(actor, weaponentity, WEP_CVAR_PRI(WEP_FIREBALL, speed), 0, WEP_CVAR_PRI(WEP_FIREBALL, lifetime), false, false))
		{
			PHYS_INPUT_BUTTON_ATCK(actor) = true;
			if(random() < 0.02) actor.bot_primary_fireballmooth = 1;
		}
	}
	else
	{
		if(bot_aim(actor, weaponentity, WEP_CVAR_SEC(WEP_FIREBALL, speed), WEP_CVAR_SEC(WEP_FIREBALL, speed_up), WEP_CVAR_SEC(WEP_FIREBALL, lifetime), true, false))
		{
			PHYS_INPUT_BUTTON_ATCK2(actor) = true;
			if(random() < 0.01) actor.bot_primary_fireballmooth = 0;
		}
	}
}

METHOD(Fireball, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
{
	if(fire & 1)
	{
		if(time >= actor.(weaponentity).fireball_primarytime)
		if(weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR_PRI(WEP_FIREBALL, refire)))
		{
			W_Fireball_Attack1_Frame0(thiswep, actor, weaponentity, fire);
			actor.(weaponentity).fireball_primarytime = time + WEP_CVAR_PRI(WEP_FIREBALL, refire2) * W_WeaponRateFactor(actor);
		}
	}
	else if(fire & 2)
	{
		if(weapon_prepareattack(thiswep, actor, weaponentity, true, WEP_CVAR_SEC(WEP_FIREBALL, refire)))
		{
			W_Fireball_Attack2(actor, weaponentity);
			weapon_thinkf(actor, weaponentity, WFRAME_FIRE2, WEP_CVAR_SEC(WEP_FIREBALL, animtime), w_ready);
		}
	}
}

METHOD(Fireball, wr_checkammo1, bool(entity thiswep, entity actor, .entity weaponentity))
{
	return true; // infinite ammo
}

METHOD(Fireball, wr_checkammo2, bool(entity thiswep, entity actor, .entity weaponentity))
{
	return true; // fireball has infinite ammo
}

METHOD(Fireball, wr_resetplayer, void(entity thiswep, entity actor))
{
	for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	{
		.entity weaponentity = weaponentities[slot];
		actor.(weaponentity).fireball_primarytime = time;
	}
}

METHOD(Fireball, wr_suicidemessage, Notification(entity thiswep))
{
	if(w_deathtype & HITTYPE_SECONDARY)
		return WEAPON_FIREBALL_SUICIDE_FIREMINE;
	else
		return WEAPON_FIREBALL_SUICIDE_BLAST;
}

METHOD(Fireball, wr_killmessage, Notification(entity thiswep))
{
	if(w_deathtype & HITTYPE_SECONDARY)
		return WEAPON_FIREBALL_MURDER_FIREMINE;
	else
		return WEAPON_FIREBALL_MURDER_BLAST;
}

#endif
#ifdef CSQC

METHOD(Fireball, wr_impacteffect, void(entity thiswep, entity actor))
{
	if(w_deathtype & HITTYPE_SECONDARY)
	{
		// firemine goes out silently
	}
	else
	{
		vector org2 = w_org + w_backoff * 2;
		pointparticles(EFFECT_FIREBALL_EXPLODE, org2, '0 0 0', 1);
		if(!w_issilent)
			sound(actor, CH_SHOTS, SND_FIREBALL_IMPACT2, VOL_BASE, ATTEN_NORM * 0.25); // long range boom
	}
}

#endif
#ifdef MENUQC

METHOD(Fireball, describe, string(Fireball this))
{
	TC(Fireball, this);
	PAGE_TEXT_INIT();
	PAR(_("The %s supercharges then fires a massive fireball in a straight line, dealing heaps of splash damage over a large radius on impact."), COLORED_NAME(this));
	PAR(_("The secondary fire launches flaming balls that set nearby players alight."));
	PAR(_("It is a superweapon, so isn't often found in game."));
	PAR(_("It doesn't require ammo, but it is destroyed after some time."));
	PAR(_("Since the %s takes a moment to charge and the fireball travels slowly, using it effectively may be difficult, "
	      "but if done properly it can deal a ton of damage."), COLORED_NAME(this));
	PAR(W_Guide_Keybinds(this));
	PAR(W_Guide_DPS(this.netname, "primary", "secondary"));
	return PAGE_TEXT;
}

#endif
