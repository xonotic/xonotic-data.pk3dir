#ifndef IMPLEMENTATION
CLASS(Vaporizer, Weapon)
/* ammotype  */ ATTRIB(Vaporizer, ammo_field, .int, ammo_cells)
/* impulse   */ ATTRIB(Vaporizer, impulse, int, 7)
/* flags     */ ATTRIB(Vaporizer, spawnflags, int, WEP_FLAG_RELOADABLE | WEP_FLAG_CANCLIMB | WEP_FLAG_SUPERWEAPON | WEP_TYPE_HITSCAN);
/* rating    */ ATTRIB(Vaporizer, bot_pickupbasevalue, float, BOT_PICKUP_RATING_HIGH);
/* color     */ ATTRIB(Vaporizer, wpcolor, vector, '0.5 1 1');
/* modelname */ ATTRIB(Vaporizer, mdl, string, "minstanex");
#ifndef MENUQC
/* model     */ ATTRIB(Vaporizer, m_model, Model, MDL_VAPORIZER_ITEM);
#endif
/* crosshair */ ATTRIB(Vaporizer, w_crosshair, string, "gfx/crosshairminstanex");
/* crosshair */ ATTRIB(Vaporizer, w_crosshair_size, float, 0.6);
/* wepimg    */ ATTRIB(Vaporizer, model2, string, "weaponminstanex");
/* refname   */ ATTRIB(Vaporizer, netname, string, "vaporizer");
/* wepname   */ ATTRIB(Vaporizer, message, string, _("Vaporizer"));
ENDCLASS(Vaporizer)
REGISTER_WEAPON(VAPORIZER, NEW(Vaporizer));

#define VAPORIZER_SETTINGS(w_cvar,w_prop) VAPORIZER_SETTINGS_LIST(w_cvar, w_prop, VAPORIZER, vaporizer)
#define VAPORIZER_SETTINGS_LIST(w_cvar,w_prop,id,sn) \
	w_cvar(id, sn, PRI, ammo) \
	w_cvar(id, sn, PRI, animtime) \
	w_cvar(id, sn, PRI, damage) \
	w_cvar(id, sn, PRI, refire) \
	w_cvar(id, sn, SEC, ammo) \
	w_cvar(id, sn, SEC, animtime) \
	w_cvar(id, sn, SEC, damage) \
	w_cvar(id, sn, SEC, delay) \
	w_cvar(id, sn, SEC, edgedamage) \
	w_cvar(id, sn, SEC, force) \
	w_cvar(id, sn, SEC, lifetime) \
	w_cvar(id, sn, SEC, radius) \
	w_cvar(id, sn, SEC, refire) \
	w_cvar(id, sn, SEC, shotangle) \
	w_cvar(id, sn, SEC, speed) \
	w_cvar(id, sn, SEC, spread) \
	w_prop(id, sn, float,  reloading_ammo, reload_ammo) \
	w_prop(id, sn, float,  reloading_time, reload_time) \
	w_prop(id, sn, float,  switchdelay_raise, switchdelay_raise) \
	w_prop(id, sn, float,  switchdelay_drop, switchdelay_drop) \
	w_prop(id, sn, string, weaponreplace, weaponreplace) \
	w_prop(id, sn, float,  weaponstart, weaponstart) \
	w_prop(id, sn, float,  weaponstartoverride, weaponstartoverride) \
	w_prop(id, sn, float,  weaponthrowable, weaponthrowable)

#ifdef SVQC
VAPORIZER_SETTINGS(WEP_ADD_CVAR, WEP_ADD_PROP)
.float vaporizer_lasthit;
.float jump_interval;
.float jump_interval2;
.bool held_down;
.float rm_force;
.float rm_damage;
.float rm_edmg;
#endif
#endif
#ifdef IMPLEMENTATION
#ifdef SVQC
spawnfunc(weapon_vaporizer) { weapon_defaultspawnfunc(WEP_VAPORIZER.m_id); }
spawnfunc(weapon_minstanex) { spawnfunc_weapon_vaporizer(this); }

void W_RocketMinsta_Explosion(vector loc)
{SELFPARAM();
	if(accuracy_canbegooddamage(self))
		accuracy_add(self, WEP_DEVASTATOR.m_id, autocvar_g_rm_damage, 0);
	entity dmgent = spawn();
	dmgent.owner = dmgent.realowner = self;
	setorigin(dmgent, loc);
	RadiusDamage (dmgent, self, autocvar_g_rm_damage, autocvar_g_rm_edgedamage, autocvar_g_rm_radius, world, world, autocvar_g_rm_force, WEP_DEVASTATOR.m_id | HITTYPE_SPLASH, other);
	remove(dmgent);
}

void W_Vaporizer_Attack(Weapon thiswep)
{SELFPARAM();
	bool flying = IsFlying(self); // do this BEFORE to make the trace values from FireRailgunBullet last
	float vaporizer_damage = ((WEP_CVAR_PRI(vaporizer, damage) > 0) ? WEP_CVAR_PRI(vaporizer, damage) : 10000);

	W_SetupShot(self, true, 0, "", CH_WEAPON_A, vaporizer_damage);
	// handle sound separately so we can change the volume
	// added bonus: no longer plays the strength sound (strength gives no bonus to instakill anyway)
	sound (self, CH_WEAPON_A, SND_MINSTANEXFIRE, VOL_BASE * 0.8, ATTEN_NORM);

	yoda = 0;
	damage_goodhits = 0;
	FireRailgunBullet(w_shotorg, w_shotorg + w_shotdir * MAX_SHOT_DISTANCE, vaporizer_damage, 800, 0, 0, 0, 0, WEP_VAPORIZER.m_id);

	if(yoda && flying)
		Send_Notification(NOTIF_ONE, self, MSG_ANNCE, ANNCE_ACHIEVEMENT_YODA);
	if(damage_goodhits && self.vaporizer_lasthit)
	{
		Send_Notification(NOTIF_ONE, self, MSG_ANNCE, ANNCE_ACHIEVEMENT_IMPRESSIVE);
		damage_goodhits = 0; // only every second time
	}

	self.vaporizer_lasthit = damage_goodhits;

	Send_Effect(EFFECT_VORTEX_MUZZLEFLASH, w_shotorg, w_shotdir * 1000, 1);

	// teamcolor / hit beam effect
	vector v = WarpZone_UnTransformOrigin(WarpZone_trace_transform, trace_endpos);
	Send_Effect((damage_goodhits ? EFFECT_VAPORIZER_HIT(self.team) : EFFECT_VAPORIZER(self.team)), w_shotorg, v, 1);

	if(autocvar_g_rm)
	if(!(trace_dphitq3surfaceflags & (Q3SURFACEFLAG_SKY | Q3SURFACEFLAG_NOIMPACT)))
		W_RocketMinsta_Explosion(trace_endpos);

	W_DecreaseAmmo(thiswep, self, ((g_instagib) ? 1 : WEP_CVAR_PRI(vaporizer, ammo)));
}

void W_RocketMinsta_Laser_Explode (void)
{SELFPARAM();
	if(other.takedamage == DAMAGE_AIM)
		if(IS_PLAYER(other))
			if(DIFF_TEAM(self.realowner, other))
				if(other.deadflag == DEAD_NO)
					if(IsFlying(other))
						Send_Notification(NOTIF_ONE, self.realowner, MSG_ANNCE, ANNCE_ACHIEVEMENT_ELECTROBITCH);

	self.event_damage = func_null;
	self.takedamage = DAMAGE_NO;
	RadiusDamage (self, self.realowner, self.rm_damage, self.rm_edmg, autocvar_g_rm_laser_radius, world, world, self.rm_force, self.projectiledeathtype, other);
	remove(self);
}

void W_RocketMinsta_Laser_Touch (void)
{SELFPARAM();
	PROJECTILE_TOUCH;
	//W_RocketMinsta_Laser_Explode ();
	RadiusDamage (self, self.realowner, self.rm_damage, self.rm_edmg, autocvar_g_rm_laser_radius, world, world, self.rm_force, self.projectiledeathtype, other);
	remove(self);
}

void W_RocketMinsta_Attack2(void)
{SELFPARAM();
	makevectors(self.v_angle);

	entity proj;
	float counter = 0;
	float total = autocvar_g_rm_laser_count;
	float spread = autocvar_g_rm_laser_spread;
	float rndspread = autocvar_g_rm_laser_spread_random;

	float w = self.weapon;
	self.weapon = WEP_ELECTRO.m_id;
	W_SetupShot_ProjectileSize (self, '0 0 -3', '0 0 -3', false, 2, SND(CRYLINK_FIRE), CH_WEAPON_A, autocvar_g_rm_laser_damage);
	self.weapon = w;

	Send_Effect(EFFECT_ELECTRO_MUZZLEFLASH, w_shotorg, w_shotdir * 1000, 1);

    while(counter < total)
	{
        proj = spawn ();
        proj.classname = "plasma_prim";
        proj.owner = proj.realowner = self;
        proj.bot_dodge = true;
        proj.bot_dodgerating = autocvar_g_rm_laser_damage;
        proj.use = W_RocketMinsta_Laser_Explode;
        proj.think = adaptor_think2use_hittype_splash;
        proj.nextthink = time + autocvar_g_rm_laser_lifetime;
        PROJECTILE_MAKETRIGGER(proj);
        proj.projectiledeathtype = WEP_ELECTRO.m_id;
        setorigin(proj, w_shotorg);

		proj.rm_force = autocvar_g_rm_laser_force / total;
		proj.rm_damage = autocvar_g_rm_laser_damage / total;
		proj.rm_edmg = proj.rm_damage;

        //W_SetupProjectileVelocity(proj, autocvar_g_rm_laser_speed, spread * (rndspread ? random() : 1) * autocvar_g_rm_laser_speed);

        proj.movetype = MOVETYPE_BOUNCEMISSILE;
        //W_SETUPPROJECTILEVELOCITY(proj, g_balance_minstanex_laser);
		proj.velocity = (w_shotdir + (((counter + 0.5) / total) * 2 - 1) * v_right * (spread * (rndspread ? random() : 1))) * cvar("g_rm_laser_speed");
		proj.velocity_z = proj.velocity_z + cvar("g_rm_laser_zspread") * (random() - 0.5);
		proj.velocity = W_CalculateProjectileVelocity(proj.realowner.velocity, proj.velocity, true);
        proj.angles = vectoangles(proj.velocity);
        proj.touch = W_RocketMinsta_Laser_Touch;
        setsize(proj, '0 0 -3', '0 0 -3');
        proj.flags = FL_PROJECTILE;
        proj.missile_flags = MIF_SPLASH;

        CSQCProjectile(proj, true, PROJECTILE_ROCKETMINSTA_LASER, true);

        MUTATOR_CALLHOOK(EditProjectile, self, proj);
        counter++;
    }
}

void W_RocketMinsta_Attack3 (void)
{SELFPARAM();
	makevectors(self.v_angle);

	entity proj;
	float counter = 0;
	float total = 1;

	int w = self.weapon;
	self.weapon = WEP_ELECTRO.m_id;
	W_SetupShot_ProjectileSize (self, '0 0 -3', '0 0 -3', false, 2, SND(ELECTRO_FIRE2), CH_WEAPON_A, autocvar_g_rm_laser_damage);
	self.weapon = w;

	Send_Effect(EFFECT_ELECTRO_MUZZLEFLASH, w_shotorg, w_shotdir * 1000, 1);

    while(counter < total)
	{
        proj = spawn ();
        proj.classname = "plasma_prim";
        proj.owner = proj.realowner = self;
        proj.bot_dodge = true;
        proj.bot_dodgerating = autocvar_g_rm_laser_damage;
        proj.use = W_RocketMinsta_Laser_Explode;
        proj.think = adaptor_think2use_hittype_splash;
        proj.nextthink = time + autocvar_g_rm_laser_lifetime;
        PROJECTILE_MAKETRIGGER(proj);
        proj.projectiledeathtype = WEP_ELECTRO.m_id;
        setorigin(proj, w_shotorg);

		proj.rm_force = autocvar_g_rm_laser_force / total;
		proj.rm_damage = autocvar_g_rm_laser_damage / total;
		proj.rm_edmg = proj.rm_damage;

        //W_SetupProjectileVelocity(proj, autocvar_g_rm_laser_speed, spread * (rndspread ? random() : 1) * autocvar_g_rm_laser_speed);

        proj.movetype = MOVETYPE_BOUNCEMISSILE;
		proj.velocity = w_shotdir * autocvar_g_rm_laser_speed;
		proj.velocity = W_CalculateProjectileVelocity(proj.realowner.velocity, proj.velocity, true);
        proj.angles = vectoangles(proj.velocity);
        proj.touch = W_RocketMinsta_Laser_Touch;
        setsize(proj, '0 0 -3', '0 0 -3');
        proj.flags = FL_PROJECTILE;
        proj.missile_flags = MIF_SPLASH;

        CSQCProjectile(proj, true, PROJECTILE_ROCKETMINSTA_LASER, true);

        MUTATOR_CALLHOOK(EditProjectile, self, proj);
        counter++;
    }
}

		METHOD(Vaporizer, wr_aim, void(entity thiswep))
		{
			if(self.WEP_AMMO(VAPORIZER) > 0)
				self.BUTTON_ATCK = bot_aim(1000000, 0, 1, false);
			else
				self.BUTTON_ATCK2 = bot_aim(WEP_CVAR_SEC(vaporizer, speed), 0, WEP_CVAR_SEC(vaporizer, lifetime), false); // WEAPONTODO: replace with proper vaporizer cvars
		}
		METHOD(Vaporizer, wr_think, void(entity thiswep, entity actor, bool fire1, bool fire2))
		{
			float vaporizer_ammo = ((g_instagib) ? 1 : WEP_CVAR_PRI(vaporizer, ammo));
			// if the laser uses load, we also consider its ammo for reloading
			if(WEP_CVAR(vaporizer, reload_ammo) && WEP_CVAR_SEC(vaporizer, ammo) && actor.clip_load < min(vaporizer_ammo, WEP_CVAR_SEC(vaporizer, ammo))) { // forced reload
				Weapon w = get_weaponinfo(actor.weapon);
				w.wr_reload(w);
			} else if(WEP_CVAR(vaporizer, reload_ammo) && actor.clip_load < vaporizer_ammo) { // forced reload
				Weapon w = get_weaponinfo(actor.weapon);
				w.wr_reload(w);
			}
			if(fire1 && (actor.ammo_cells || !autocvar_g_rm) && !forbidWeaponUse(actor))
			{
				if(weapon_prepareattack(thiswep, actor, false, WEP_CVAR_PRI(vaporizer, refire)))
				{
					W_Vaporizer_Attack(thiswep);
					weapon_thinkf(actor, WFRAME_FIRE1, WEP_CVAR_PRI(vaporizer, animtime), w_ready);
				}
			}
			if(fire2 || (fire1 && !actor.ammo_cells && autocvar_g_rm))
			{
				if((autocvar_g_rm && autocvar_g_rm_laser) || autocvar_g_rm_laser == 2)
				{
					bool rapid = autocvar_g_rm_laser_rapid;
					if(actor.jump_interval <= time && !actor.held_down)
					{
						if(rapid)
							actor.held_down = true;
						actor.jump_interval = time + autocvar_g_rm_laser_refire;
						actor.jump_interval2 = time + autocvar_g_rm_laser_rapid_delay;
						damage_goodhits = 0;
						W_RocketMinsta_Attack2();
					}
					else if(rapid && actor.jump_interval2 <= time && actor.held_down)
					{
						actor.jump_interval2 = time + autocvar_g_rm_laser_rapid_refire;
						damage_goodhits = 0;
						W_RocketMinsta_Attack3();
						//weapon_thinkf(actor, WFRAME_FIRE2, autocvar_g_rm_laser_rapid_animtime, w_ready);
					}
				}
				else if (actor.jump_interval <= time)
				{
					// handle refire manually, so that primary and secondary can be fired without conflictions (important for instagib)
					actor.jump_interval = time + WEP_CVAR_SEC(vaporizer, refire) * W_WeaponRateFactor();

					// decrease ammo for the laser?
					if(WEP_CVAR_SEC(vaporizer, ammo))
						W_DecreaseAmmo(thiswep, actor, WEP_CVAR_SEC(vaporizer, ammo));

					// ugly instagib hack to reuse the fire mode of the laser
					makevectors(actor.v_angle);
					int oldwep = actor.weapon; // we can't avoid this hack
					actor.weapon = WEP_BLASTER.m_id;
					W_Blaster_Attack(
						actor,
						WEP_BLASTER.m_id | HITTYPE_SECONDARY,
						WEP_CVAR_SEC(vaporizer, shotangle),
						WEP_CVAR_SEC(vaporizer, damage),
						WEP_CVAR_SEC(vaporizer, edgedamage),
						WEP_CVAR_SEC(vaporizer, radius),
						WEP_CVAR_SEC(vaporizer, force),
						WEP_CVAR_SEC(vaporizer, speed),
						WEP_CVAR_SEC(vaporizer, spread),
						WEP_CVAR_SEC(vaporizer, delay),
						WEP_CVAR_SEC(vaporizer, lifetime)
					);
					actor.weapon = oldwep;

					// now do normal refire
					weapon_thinkf(actor, WFRAME_FIRE2, WEP_CVAR_SEC(vaporizer, animtime), w_ready);
				}
			}
			else
				actor.held_down = false;
		}
		METHOD(Vaporizer, wr_init, void(entity thiswep))
		{
			//W_Blaster(WR_INIT); // Samual: Is this really the proper thing to do? Didn't we already run this previously?
			VAPORIZER_SETTINGS(WEP_SKIP_CVAR, WEP_SET_PROP);
		}
		METHOD(Vaporizer, wr_setup, void(entity thiswep))
		{
			self.ammo_field = WEP_AMMO(VAPORIZER);
			self.vaporizer_lasthit = 0;
		}
		METHOD(Vaporizer, wr_checkammo1, bool(entity thiswep))
		{
			float vaporizer_ammo = ((g_instagib) ? 1 : WEP_CVAR_PRI(vaporizer, ammo));
			float ammo_amount = self.WEP_AMMO(VAPORIZER) >= vaporizer_ammo;
			ammo_amount += self.(weapon_load[WEP_VAPORIZER.m_id]) >= vaporizer_ammo;
			return ammo_amount;
		}
		METHOD(Vaporizer, wr_checkammo2, bool(entity thiswep))
		{
			if(!WEP_CVAR_SEC(vaporizer, ammo))
				return true;
			float ammo_amount = self.WEP_AMMO(VAPORIZER) >= WEP_CVAR_SEC(vaporizer, ammo);
			ammo_amount += self.(weapon_load[WEP_VAPORIZER.m_id]) >= WEP_CVAR_SEC(vaporizer, ammo);
			return ammo_amount;
		}
		METHOD(Vaporizer, wr_config, void(entity thiswep))
		{
			VAPORIZER_SETTINGS(WEP_CONFIG_WRITE_CVARS, WEP_CONFIG_WRITE_PROPS);
		}
		METHOD(Vaporizer, wr_resetplayer, void(entity thiswep))
		{
			self.vaporizer_lasthit = 0;
		}
		METHOD(Vaporizer, wr_reload, void(entity thiswep))
		{
			float vaporizer_ammo = ((g_instagib) ? 1 : WEP_CVAR_PRI(vaporizer, ammo));
			float used_ammo;
			if(WEP_CVAR_SEC(vaporizer, ammo))
				used_ammo = min(vaporizer_ammo, WEP_CVAR_SEC(vaporizer, ammo));
			else
				used_ammo = vaporizer_ammo;

			W_Reload(self, used_ammo, SND(RELOAD));
		}
		METHOD(Vaporizer, wr_suicidemessage, int(entity thiswep))
		{
			return WEAPON_THINKING_WITH_PORTALS;
		}
		METHOD(Vaporizer, wr_killmessage, int(entity thiswep))
		{
			return WEAPON_VAPORIZER_MURDER;
		}

#endif
#ifdef CSQC

		METHOD(Vaporizer, wr_impacteffect, void(entity thiswep))
		{
			vector org2 = w_org + w_backoff * 6;
			if(w_deathtype & HITTYPE_SECONDARY)
			{
				pointparticles(particleeffectnum(EFFECT_BLASTER_IMPACT), org2, w_backoff * 1000, 1);
				if(!w_issilent) { sound(self, CH_SHOTS, SND_LASERIMPACT, VOL_BASE, ATTN_NORM); }
			}
			else
			{
				pointparticles(particleeffectnum(EFFECT_VORTEX_IMPACT), org2, '0 0 0', 1);
				if(!w_issilent) { sound(self, CH_SHOTS, SND_NEXIMPACT, VOL_BASE, ATTN_NORM); }
			}
		}
		METHOD(Vaporizer, wr_init, void(entity thiswep))
		{
			if(autocvar_cl_reticle && autocvar_cl_reticle_weapon)
			{
				precache_pic("gfx/reticle_nex");
			}
		}
		METHOD(Vaporizer, wr_zoomreticle, bool(entity thiswep))
		{
			if(button_zoom || zoomscript_caught)
			{
				reticle_image = "gfx/reticle_nex";
				return true;
			}
			else
			{
				// no weapon specific image for this weapon
				return false;
			}
		}

#endif
#endif
