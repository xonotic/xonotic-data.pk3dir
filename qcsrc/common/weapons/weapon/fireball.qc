#include "fireball.qh"
#ifndef IMPLEMENTATION
CLASS(Fireball, Weapon)
/* ammotype  */ //ATTRIB(Fireball, ammo_field, .int, ammo_none);
/* impulse   */ ATTRIB(Fireball, impulse, int, 9);
/* flags     */ ATTRIB(Fireball, spawnflags, int, WEP_FLAG_SUPERWEAPON | WEP_TYPE_SPLASH);
/* rating    */ ATTRIB(Fireball, bot_pickupbasevalue, float, 5000);
/* color     */ ATTRIB(Fireball, wpcolor, vector, '1 0.5 0');
/* modelname */ ATTRIB(Fireball, mdl, string, "fireball");
#ifdef GAMEQC
/* model     */ ATTRIB(Fireball, m_model, Model, MDL_FIREBALL_ITEM);
#endif
/* crosshair */ ATTRIB(Fireball, w_crosshair, string, "gfx/crosshairfireball");
/* crosshair */ //ATTRIB(Fireball, w_crosshair_size, float, 0.65);
/* wepimg    */ ATTRIB(Fireball, model2, string, "weaponfireball");
/* refname   */ ATTRIB(Fireball, netname, string, "fireball");
/* wepname   */ ATTRIB(Fireball, m_name, string, _("Fireball"));

#define X(BEGIN, P, END, class, prefix) \
	BEGIN(class) \
		P(class, prefix, animtime, float, BOTH) \
		P(class, prefix, bfgdamage, float, PRI) \
		P(class, prefix, bfgforce, float, PRI) \
		P(class, prefix, bfgradius, float, PRI) \
		P(class, prefix, damageforcescale, float, BOTH) \
		P(class, prefix, damagetime, float, SEC) \
		P(class, prefix, damage, float, BOTH) \
		P(class, prefix, edgedamage, float, PRI) \
		P(class, prefix, force, float, PRI) \
		P(class, prefix, health, float, PRI) \
		P(class, prefix, laserburntime, float, BOTH) \
		P(class, prefix, laserdamage, float, BOTH) \
		P(class, prefix, laseredgedamage, float, BOTH) \
		P(class, prefix, laserradius, float, BOTH) \
		P(class, prefix, lifetime, float, BOTH) \
		P(class, prefix, radius, float, PRI) \
		P(class, prefix, refire2, float, PRI) \
		P(class, prefix, refire, float, BOTH) \
		P(class, prefix, speed, float, BOTH) \
		P(class, prefix, speed_up, float, SEC) \
		P(class, prefix, speed_z, float, SEC) \
		P(class, prefix, spread, float, BOTH) \
		P(class, prefix, switchdelay_drop, float, NONE) \
		P(class, prefix, switchdelay_raise, float, NONE) \
		P(class, prefix, weaponreplace, string,NONE) \
		P(class, prefix, weaponstartoverride, float, NONE) \
		P(class, prefix, weaponstart, float, NONE) \
		P(class, prefix, weaponthrowable, float, NONE) \
	END()
	W_PROPS(X, Fireball, fireball)
#undef X

ENDCLASS(Fireball)
REGISTER_WEAPON(FIREBALL, fireball, NEW(Fireball));

#ifdef SVQC
.float bot_primary_fireballmooth; // whatever a mooth is
.vector fireball_impactvec;
.float fireball_primarytime;
#endif
#endif
#ifdef IMPLEMENTATION
#ifdef SVQC
spawnfunc(weapon_fireball) { weapon_defaultspawnfunc(this, WEP_FIREBALL); }

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
	d = (this.realowner.health + this.realowner.armorvalue);
	RadiusDamage(this, this.realowner, WEP_CVAR_PRI(fireball, damage), WEP_CVAR_PRI(fireball, edgedamage), WEP_CVAR_PRI(fireball, radius), NULL, NULL, WEP_CVAR_PRI(fireball, force), this.projectiledeathtype, directhitentity);
	if(this.realowner.health + this.realowner.armorvalue >= d)
	if(!this.cnt)
	{
		modeleffect_spawn("models/sphere/sphere.md3", 0, 0, this.origin, '0 0 0', '0 0 0', '0 0 0', 0, WEP_CVAR_PRI(fireball, bfgradius), 0.2, 0.05, 0.25);

		// 2. bfg effect
		// NOTE: this cannot be made warpzone aware by design. So, better intentionally ignore warpzones here.
		for(e = findradius(this.origin, WEP_CVAR_PRI(fireball, bfgradius)); e; e = e.chain)
		if(e != this.realowner) if(e.takedamage == DAMAGE_AIM) if(!IS_PLAYER(e) || !this.realowner || DIFF_TEAM(e, this))
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
			points = (1 - sqrt(dist / WEP_CVAR_PRI(fireball, bfgradius)));
			if(points <= 0)
				continue;
			dir = normalize(e.origin + e.view_ofs - this.origin);

			if(accuracy_isgooddamage(this.realowner, e))
				accuracy_add(this.realowner, WEP_FIREBALL.m_id, 0, WEP_CVAR_PRI(fireball, bfgdamage) * points);

			Damage(e, this, this.realowner, WEP_CVAR_PRI(fireball, bfgdamage) * points, this.projectiledeathtype | HITTYPE_BOUNCE | HITTYPE_SPLASH, e.origin + e.view_ofs, WEP_CVAR_PRI(fireball, bfgforce) * dir);
			Send_Effect(EFFECT_FIREBALL_BFGDAMAGE, e.origin, -1 * dir, 1);
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
	if(e != this.realowner) if(e.takedamage == DAMAGE_AIM) if(!IS_PLAYER(e) || !this.realowner || DIFF_TEAM(e, this))
	{
		p = e.origin;
		p.x += e.mins.x + random() * (e.maxs.x - e.mins.x);
		p.y += e.mins.y + random() * (e.maxs.y - e.mins.y);
		p.z += e.mins.z + random() * (e.maxs.z - e.mins.z);
		d = vlen(WarpZone_UnTransformOrigin(e, this.origin) - p);
		if(d < dist)
		{
			e.fireball_impactvec = p;
			RandomSelection_AddEnt(e, 1 / (1 + d), !Fire_IsBurning(e));
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

	W_Fireball_LaserPlay(this, 0.1, WEP_CVAR_PRI(fireball, laserradius), WEP_CVAR_PRI(fireball, laserdamage), WEP_CVAR_PRI(fireball, laseredgedamage), WEP_CVAR_PRI(fireball, laserburntime));

	this.nextthink = time + 0.1;
}

void W_Fireball_Damage(entity this, entity inflictor, entity attacker, float damage, int deathtype, vector hitloc, vector force)
{
	if(this.health <= 0)
		return;

	if(!W_CheckProjectileDamage(inflictor.realowner, this.realowner, deathtype, -1)) // no exceptions
		return; // g_projectiles_damage says to halt

	this.health = this.health - damage;
	if(this.health <= 0)
	{
		this.cnt = 1;
		W_PrepareExplosionByDamage(this, attacker, W_Fireball_Explode_think);
	}
}

void W_Fireball_Attack1(entity actor, .entity weaponentity)
{
	W_SetupShot_ProjectileSize(actor, weaponentity, '-16 -16 -16', '16 16 16', false, 2, SND_FIREBALL_FIRE2, CH_WEAPON_A, WEP_CVAR_PRI(fireball, damage) + WEP_CVAR_PRI(fireball, bfgdamage));

	Send_Effect(EFFECT_FIREBALL_MUZZLEFLASH, w_shotorg, w_shotdir * 1000, 1);

	entity proj = new(plasma_prim);
	proj.owner = proj.realowner = actor;
	proj.bot_dodge = true;
	proj.bot_dodgerating = WEP_CVAR_PRI(fireball, damage);
	proj.pushltime = time + WEP_CVAR_PRI(fireball, lifetime);
	proj.use = W_Fireball_Explode_use;
	setthink(proj, W_Fireball_Think);
	proj.nextthink = time;
	proj.health = WEP_CVAR_PRI(fireball, health);
	proj.team = actor.team;
	proj.event_damage = W_Fireball_Damage;
	proj.takedamage = DAMAGE_YES;
	proj.damageforcescale = WEP_CVAR_PRI(fireball, damageforcescale);
	PROJECTILE_MAKETRIGGER(proj);
	proj.projectiledeathtype = WEP_FIREBALL.m_id;
	setorigin(proj, w_shotorg);

	set_movetype(proj, MOVETYPE_FLY);
	W_SetupProjVelocity_PRI(proj, fireball);
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
	W_SetupShot_ProjectileSize(actor, weaponentity, '-16 -16 -16', '16 16 16', false, 0, SND_Null, 0, 0);
	w_shotorg += f_diff.x * v_up + f_diff.y * v_right;
	Send_Effect(EFFECT_FIREBALL_PRE_MUZZLEFLASH, w_shotorg, w_shotdir * 1000, 1);
}

void W_Fireball_Attack1_Frame4(Weapon thiswep, entity actor, .entity weaponentity, int fire)
{
	W_Fireball_Attack1(actor, weaponentity);
	weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_PRI(fireball, animtime), w_ready);
}

void W_Fireball_Attack1_Frame3(Weapon thiswep, entity actor, .entity weaponentity, int fire)
{
	W_Fireball_AttackEffect(actor, weaponentity, 0, '+1.25 +3.75 0');
	weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_PRI(fireball, animtime), W_Fireball_Attack1_Frame4);
}

void W_Fireball_Attack1_Frame2(Weapon thiswep, entity actor, .entity weaponentity, int fire)
{
	W_Fireball_AttackEffect(actor, weaponentity, 0, '-1.25 +3.75 0');
	weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_PRI(fireball, animtime), W_Fireball_Attack1_Frame3);
}

void W_Fireball_Attack1_Frame1(Weapon thiswep, entity actor, .entity weaponentity, int fire)
{
	W_Fireball_AttackEffect(actor, weaponentity, 1, '+1.25 -3.75 0');
	weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_PRI(fireball, animtime), W_Fireball_Attack1_Frame2);
}

void W_Fireball_Attack1_Frame0(Weapon thiswep, entity actor, .entity weaponentity, int fire)
{
	W_Fireball_AttackEffect(actor, weaponentity, 0, '-1.25 -3.75 0');
	sound(actor, CH_WEAPON_SINGLE, SND_FIREBALL_PREFIRE2, VOL_BASE, ATTEN_NORM);
	weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_PRI(fireball, animtime), W_Fireball_Attack1_Frame1);
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
		if(vdist(this.origin - this.owner.origin - this.owner.view_ofs, >, WEP_CVAR_SEC(fireball, laserradius)))
		{
			this.cnt += 1;
			if(this.cnt == 3)
				this.owner = NULL;
		}
		else
			this.cnt = 0;
	}

	W_Fireball_LaserPlay(this, 0.1, WEP_CVAR_SEC(fireball, laserradius), WEP_CVAR_SEC(fireball, laserdamage), WEP_CVAR_SEC(fireball, laseredgedamage), WEP_CVAR_SEC(fireball, laserburntime));

	this.nextthink = time + 0.1;
}

void W_Fireball_Firemine_Touch(entity this, entity toucher)
{
	PROJECTILE_TOUCH(this, toucher);
	if(toucher.takedamage == DAMAGE_AIM)
	if(Fire_AddDamage(toucher, this.realowner, WEP_CVAR_SEC(fireball, damage), WEP_CVAR_SEC(fireball, damagetime), this.projectiledeathtype) >= 0)
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
	W_SetupShot_ProjectileSize(actor, weaponentity, '-4 -4 -4', '4 4 4', false, 2, SND_FIREBALL_FIRE, CH_WEAPON_A, WEP_CVAR_SEC(fireball, damage));
	traceline(w_shotorg, w_shotorg + f_diff_x * v_up + f_diff_y * v_right, MOVE_NORMAL, actor);
	w_shotorg = trace_endpos;

	Send_Effect(EFFECT_FIREBALL_MUZZLEFLASH, w_shotorg, w_shotdir * 1000, 1);

	proj = new(grenade);
	proj.owner = proj.realowner = actor;
	proj.bot_dodge = true;
	proj.bot_dodgerating = WEP_CVAR_SEC(fireball, damage);
	set_movetype(proj, MOVETYPE_BOUNCE);
	proj.projectiledeathtype = WEP_FIREBALL.m_id | HITTYPE_SECONDARY;
	settouch(proj, W_Fireball_Firemine_Touch);
	PROJECTILE_MAKETRIGGER(proj);
	setsize(proj, '-4 -4 -4', '4 4 4');
	setorigin(proj, w_shotorg);
	setthink(proj, W_Fireball_Firemine_Think);
	proj.nextthink = time;
	proj.damageforcescale = WEP_CVAR_SEC(fireball, damageforcescale);
	proj.pushltime = time + WEP_CVAR_SEC(fireball, lifetime);
	W_SetupProjVelocity_UP_SEC(proj, fireball);

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
        if(bot_aim(actor, weaponentity, WEP_CVAR_PRI(fireball, speed), 0, WEP_CVAR_PRI(fireball, lifetime), false))
        {
            PHYS_INPUT_BUTTON_ATCK(actor) = true;
            if(random() < 0.02) actor.bot_primary_fireballmooth = 0;
        }
    }
    else
    {
        if(bot_aim(actor, weaponentity, WEP_CVAR_SEC(fireball, speed), WEP_CVAR_SEC(fireball, speed_up), WEP_CVAR_SEC(fireball, lifetime), true))
        {
            PHYS_INPUT_BUTTON_ATCK2(actor) = true;
            if(random() < 0.01) actor.bot_primary_fireballmooth = 1;
        }
    }
}
METHOD(Fireball, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
{
    if(fire & 1)
    {
        if(time >= actor.(weaponentity).fireball_primarytime)
        if(weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR_PRI(fireball, refire)))
        {
            W_Fireball_Attack1_Frame0(thiswep, actor, weaponentity, fire);
            actor.(weaponentity).fireball_primarytime = time + WEP_CVAR_PRI(fireball, refire2) * W_WeaponRateFactor(actor);
        }
    }
    else if(fire & 2)
    {
        if(weapon_prepareattack(thiswep, actor, weaponentity, true, WEP_CVAR_SEC(fireball, refire)))
        {
            W_Fireball_Attack2(actor, weaponentity);
            weapon_thinkf(actor, weaponentity, WFRAME_FIRE2, WEP_CVAR_SEC(fireball, animtime), w_ready);
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
    vector org2;
    if(w_deathtype & HITTYPE_SECONDARY)
    {
        // firemine goes out silently
    }
    else
    {
        org2 = w_org + w_backoff * 16;
        pointparticles(EFFECT_FIREBALL_EXPLODE, org2, '0 0 0', 1);
        if(!w_issilent)
            sound(actor, CH_SHOTS, SND_FIREBALL_IMPACT2, VOL_BASE, ATTEN_NORM * 0.25); // long range boom
    }
}

#endif
#endif
