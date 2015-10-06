#ifndef IMPLEMENTATION
CLASS(HLAC, Weapon)
/* ammotype  */ ATTRIB(HLAC, ammo_field, .int, ammo_cells)
/* impulse   */ ATTRIB(HLAC, impulse, int, 6)
/* flags     */ ATTRIB(HLAC, spawnflags, int, WEP_FLAG_MUTATORBLOCKED | WEP_FLAG_RELOADABLE | WEP_TYPE_SPLASH);
/* rating    */ ATTRIB(HLAC, bot_pickupbasevalue, float, BOT_PICKUP_RATING_MID);
/* color     */ ATTRIB(HLAC, wpcolor, vector, '0 1 0');
/* modelname */ ATTRIB(HLAC, mdl, string, "hlac");
#ifndef MENUQC
/* model     */ ATTRIB(HLAC, m_model, Model, MDL_HLAC_ITEM);
#endif
/* crosshair */ ATTRIB(HLAC, w_crosshair, string, "gfx/crosshairhlac");
/* crosshair */ ATTRIB(HLAC, w_crosshair_size, float, 0.6);
/* wepimg    */ ATTRIB(HLAC, model2, string, "weaponhlac");
/* refname   */ ATTRIB(HLAC, netname, string, "hlac");
/* wepname   */ ATTRIB(HLAC, message, string, _("Heavy Laser Assault Cannon"));
ENDCLASS(HLAC)
REGISTER_WEAPON(HLAC, NEW(HLAC));

#define HLAC_SETTINGS(w_cvar,w_prop) HLAC_SETTINGS_LIST(w_cvar, w_prop, HLAC, hlac)
#define HLAC_SETTINGS_LIST(w_cvar,w_prop,id,sn) \
	w_cvar(id, sn, BOTH, ammo) \
	w_cvar(id, sn, BOTH, animtime) \
	w_cvar(id, sn, BOTH, damage) \
	w_cvar(id, sn, BOTH, edgedamage) \
	w_cvar(id, sn, BOTH, force) \
	w_cvar(id, sn, BOTH, lifetime) \
	w_cvar(id, sn, BOTH, radius) \
	w_cvar(id, sn, BOTH, refire) \
	w_cvar(id, sn, BOTH, speed) \
	w_cvar(id, sn, BOTH, spread_crouchmod) \
	w_cvar(id, sn, PRI,  spread_add) \
	w_cvar(id, sn, PRI,  spread_max) \
	w_cvar(id, sn, PRI,  spread_min) \
	w_cvar(id, sn, NONE, secondary) \
	w_cvar(id, sn, SEC,  shots) \
	w_cvar(id, sn, SEC,  spread) \
	w_prop(id, sn, float,  reloading_ammo, reload_ammo) \
	w_prop(id, sn, float,  reloading_time, reload_time) \
	w_prop(id, sn, float,  switchdelay_raise, switchdelay_raise) \
	w_prop(id, sn, float,  switchdelay_drop, switchdelay_drop) \
	w_prop(id, sn, string, weaponreplace, weaponreplace) \
	w_prop(id, sn, float,  weaponstart, weaponstart) \
	w_prop(id, sn, float,  weaponstartoverride, weaponstartoverride) \
	w_prop(id, sn, float,  weaponthrowable, weaponthrowable)

#ifdef SVQC
HLAC_SETTINGS(WEP_ADD_CVAR, WEP_ADD_PROP)
#endif
#endif
#ifdef IMPLEMENTATION
#ifdef SVQC
spawnfunc(weapon_hlac) { weapon_defaultspawnfunc(WEP_HLAC.m_id); }

void W_HLAC_Touch(void)
{SELFPARAM();
	float isprimary;

	PROJECTILE_TOUCH;

	self.event_damage = func_null;

	isprimary = !(self.projectiledeathtype & HITTYPE_SECONDARY);

	RadiusDamage(self, self.realowner, WEP_CVAR_BOTH(hlac, isprimary, damage), WEP_CVAR_BOTH(hlac, isprimary, edgedamage), WEP_CVAR_BOTH(hlac, isprimary, radius), world, world, WEP_CVAR_BOTH(hlac, isprimary, force), self.projectiledeathtype, other);

	remove(self);
}

void W_HLAC_Attack(Weapon thiswep)
{SELFPARAM();
	entity missile;
    float spread;

	W_DecreaseAmmo(thiswep, self, WEP_CVAR_PRI(hlac, ammo));

    spread = WEP_CVAR_PRI(hlac, spread_min) + (WEP_CVAR_PRI(hlac, spread_add) * self.misc_bulletcounter);
    spread = min(spread,WEP_CVAR_PRI(hlac, spread_max));
    if(self.crouch)
        spread = spread * WEP_CVAR_PRI(hlac, spread_crouchmod);

	W_SetupShot(self, false, 3, SND(LASERGUN_FIRE), CH_WEAPON_A, WEP_CVAR_PRI(hlac, damage));
	Send_Effect(EFFECT_BLASTER_MUZZLEFLASH, w_shotorg, w_shotdir * 1000, 1);
	if(!autocvar_g_norecoil)
	{
		self.punchangle_x = random() - 0.5;
		self.punchangle_y = random() - 0.5;
	}

	missile = spawn();
	missile.owner = missile.realowner = self;
	missile.classname = "hlacbolt";
	missile.bot_dodge = true;

    missile.bot_dodgerating = WEP_CVAR_PRI(hlac, damage);

	missile.movetype = MOVETYPE_FLY;
	PROJECTILE_MAKETRIGGER(missile);

	setorigin(missile, w_shotorg);
	setsize(missile, '0 0 0', '0 0 0');

	W_SetupProjVelocity_Basic(missile, WEP_CVAR_PRI(hlac, speed), spread);
	//missile.angles = vectoangles(missile.velocity); // csqc

	missile.touch = W_HLAC_Touch;
	missile.think = SUB_Remove;

    missile.nextthink = time + WEP_CVAR_PRI(hlac, lifetime);

	missile.flags = FL_PROJECTILE;
	missile.projectiledeathtype = WEP_HLAC.m_id;

	CSQCProjectile(missile, true, PROJECTILE_HLAC, true);

	MUTATOR_CALLHOOK(EditProjectile, self, missile);
}

void W_HLAC_Attack2(void)
{SELFPARAM();
	entity missile;
    float spread;

    spread = WEP_CVAR_SEC(hlac, spread);


    if(self.crouch)
        spread = spread * WEP_CVAR_SEC(hlac, spread_crouchmod);

	W_SetupShot(self, false, 3, SND(LASERGUN_FIRE), CH_WEAPON_A, WEP_CVAR_SEC(hlac, damage));
	Send_Effect(EFFECT_BLASTER_MUZZLEFLASH, w_shotorg, w_shotdir * 1000, 1);

	missile = spawn();
	missile.owner = missile.realowner = self;
	missile.classname = "hlacbolt";
	missile.bot_dodge = true;

    missile.bot_dodgerating = WEP_CVAR_SEC(hlac, damage);

	missile.movetype = MOVETYPE_FLY;
	PROJECTILE_MAKETRIGGER(missile);

	setorigin(missile, w_shotorg);
	setsize(missile, '0 0 0', '0 0 0');

	W_SetupProjVelocity_Basic(missile, WEP_CVAR_SEC(hlac, speed), spread);
	//missile.angles = vectoangles(missile.velocity); // csqc

	missile.touch = W_HLAC_Touch;
	missile.think = SUB_Remove;

    missile.nextthink = time + WEP_CVAR_SEC(hlac, lifetime);

	missile.flags = FL_PROJECTILE;
	missile.missile_flags = MIF_SPLASH;
	missile.projectiledeathtype = WEP_HLAC.m_id | HITTYPE_SECONDARY;

	CSQCProjectile(missile, true, PROJECTILE_HLAC, true);

	MUTATOR_CALLHOOK(EditProjectile, self, missile);
}

// weapon frames
void W_HLAC_Attack_Frame(Weapon thiswep, entity actor, bool fire1, bool fire2)
{
	if(actor.weapon != actor.switchweapon) // abort immediately if switching
	{
		w_ready(thiswep, actor, fire1, fire2);
		return;
	}

	if(actor.BUTTON_ATCK)
	{
		Weapon w = get_weaponinfo(actor.weapon);
		if(!w.wr_checkammo1(w))
		if(!(actor.items & IT_UNLIMITED_WEAPON_AMMO))
		{
			W_SwitchWeapon_Force(actor, w_getbestweapon(actor));
			w_ready(thiswep, actor, fire1, fire2);
			return;
		}

		ATTACK_FINISHED(actor) = time + WEP_CVAR_PRI(hlac, refire) * W_WeaponRateFactor();
		W_HLAC_Attack(WEP_HLAC);
		actor.misc_bulletcounter = actor.misc_bulletcounter + 1;
        weapon_thinkf(actor, WFRAME_FIRE1, WEP_CVAR_PRI(hlac, refire), W_HLAC_Attack_Frame);
	}
	else
	{
		weapon_thinkf(actor, WFRAME_FIRE1, WEP_CVAR_PRI(hlac, animtime), w_ready);
	}
}

void W_HLAC_Attack2_Frame(Weapon thiswep)
{SELFPARAM();
    float i;

	W_DecreaseAmmo(thiswep, self, WEP_CVAR_SEC(hlac, ammo));

    for(i=WEP_CVAR_SEC(hlac, shots);i>0;--i)
        W_HLAC_Attack2();

	if(!autocvar_g_norecoil)
	{
		self.punchangle_x = random() - 0.5;
		self.punchangle_y = random() - 0.5;
	}
}

		METHOD(HLAC, wr_aim, void(entity thiswep))
		{
			self.BUTTON_ATCK = bot_aim(WEP_CVAR_PRI(hlac, speed), 0, WEP_CVAR_PRI(hlac, lifetime), false);
		}
		METHOD(HLAC, wr_think, void(entity thiswep, entity actor, bool fire1, bool fire2))
		{
			if(autocvar_g_balance_hlac_reload_ammo && actor.clip_load < min(WEP_CVAR_PRI(hlac, ammo), WEP_CVAR_SEC(hlac, ammo))) { // forced reload
				Weapon w = get_weaponinfo(actor.weapon);
				w.wr_reload(w);
			} else if(fire1)
			{
				if(weapon_prepareattack(thiswep, actor, false, WEP_CVAR_PRI(hlac, refire)))
				{
					actor.misc_bulletcounter = 0;
					W_HLAC_Attack(thiswep);
					weapon_thinkf(actor, WFRAME_FIRE1, WEP_CVAR_PRI(hlac, refire), W_HLAC_Attack_Frame);
				}
			}

			else if(fire2 && WEP_CVAR(hlac, secondary))
			{
				if(weapon_prepareattack(thiswep, actor, true, WEP_CVAR_SEC(hlac, refire)))
				{
					W_HLAC_Attack2_Frame(thiswep);
					weapon_thinkf(actor, WFRAME_FIRE2, WEP_CVAR_SEC(hlac, animtime), w_ready);
				}
			}
		}
		METHOD(HLAC, wr_init, void(entity thiswep))
		{
			HLAC_SETTINGS(WEP_SKIP_CVAR, WEP_SET_PROP);
		}
		METHOD(HLAC, wr_checkammo1, bool(entity thiswep))
		{
			float ammo_amount = self.WEP_AMMO(HLAC) >= WEP_CVAR_PRI(hlac, ammo);
			ammo_amount += self.(weapon_load[WEP_HLAC.m_id]) >= WEP_CVAR_PRI(hlac, ammo);
			return ammo_amount;
		}
		METHOD(HLAC, wr_checkammo2, bool(entity thiswep))
		{
			float ammo_amount = self.WEP_AMMO(HLAC) >= WEP_CVAR_SEC(hlac, ammo);
			ammo_amount += self.(weapon_load[WEP_HLAC.m_id]) >= WEP_CVAR_SEC(hlac, ammo);
			return ammo_amount;
		}
		METHOD(HLAC, wr_config, void(entity thiswep))
		{
			HLAC_SETTINGS(WEP_CONFIG_WRITE_CVARS, WEP_CONFIG_WRITE_PROPS);
		}
		METHOD(HLAC, wr_reload, void(entity thiswep))
		{
			W_Reload(self, min(WEP_CVAR_PRI(hlac, ammo), WEP_CVAR_SEC(hlac, ammo)), SND(RELOAD));
		}
		METHOD(HLAC, wr_suicidemessage, int(entity thiswep))
		{
			return WEAPON_HLAC_SUICIDE;
		}
		METHOD(HLAC, wr_killmessage, int(entity thiswep))
		{
			return WEAPON_HLAC_MURDER;
		}

#endif
#ifdef CSQC

		METHOD(HLAC, wr_impacteffect, void(entity thiswep))
		{
			vector org2;
			org2 = w_org + w_backoff * 6;
			pointparticles(particleeffectnum(EFFECT_BLASTER_IMPACT), org2, w_backoff * 1000, 1);
			if(!w_issilent)
				sound(self, CH_SHOTS, SND_LASERIMPACT, VOL_BASE, ATTN_NORM);
		}

#endif
#endif
