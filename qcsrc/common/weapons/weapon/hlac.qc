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
/* wepname   */ ATTRIB(HLAC, m_name, string, _("Heavy Laser Assault Cannon"));

#define X(BEGIN, P, END, class, prefix) \
	BEGIN(class) \
		P(class, prefix, ammo, float, BOTH) \
		P(class, prefix, animtime, float, BOTH) \
		P(class, prefix, damage, float, BOTH) \
		P(class, prefix, edgedamage, float, BOTH) \
		P(class, prefix, force, float, BOTH) \
		P(class, prefix, lifetime, float, BOTH) \
		P(class, prefix, radius, float, BOTH) \
		P(class, prefix, refire, float, BOTH) \
		P(class, prefix, reload_ammo, float, NONE) \
		P(class, prefix, reload_time, float, NONE) \
		P(class, prefix, secondary, float, NONE) \
		P(class, prefix, shots, float, SEC) \
		P(class, prefix, speed, float, BOTH) \
		P(class, prefix, spread, float, SEC) \
		P(class, prefix, spread_add, float, PRI) \
		P(class, prefix, spread_crouchmod, float, BOTH) \
		P(class, prefix, spread_max, float, PRI) \
		P(class, prefix, spread_min, float, PRI) \
		P(class, prefix, switchdelay_drop, float, NONE) \
		P(class, prefix, switchdelay_raise, float, NONE) \
		P(class, prefix, weaponreplace, string,NONE) \
		P(class, prefix, weaponstartoverride, float, NONE) \
		P(class, prefix, weaponstart, float, NONE) \
		P(class, prefix, weaponthrowable, float, NONE) \
	END()
    W_PROPS(X, HLAC, hlac)
#undef X

ENDCLASS(HLAC)
REGISTER_WEAPON(HLAC, hlac, NEW(HLAC));


#endif
#ifdef IMPLEMENTATION
#ifdef SVQC
spawnfunc(weapon_hlac) { weapon_defaultspawnfunc(this, WEP_HLAC); }

void W_HLAC_Touch()
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

	missile = new(hlacbolt);
	missile.owner = missile.realowner = self;
	missile.bot_dodge = true;

    missile.bot_dodgerating = WEP_CVAR_PRI(hlac, damage);

	missile.movetype = MOVETYPE_FLY;
	PROJECTILE_MAKETRIGGER(missile);

	setorigin(missile, w_shotorg);
	setsize(missile, '0 0 0', '0 0 0');

	W_SetupProjVelocity_Basic(missile, WEP_CVAR_PRI(hlac, speed), spread);
	//missile.angles = vectoangles(missile.velocity); // csqc

	missile.touch = W_HLAC_Touch;
	missile.think = SUB_Remove_self;

    missile.nextthink = time + WEP_CVAR_PRI(hlac, lifetime);

	missile.flags = FL_PROJECTILE;
	missile.projectiledeathtype = WEP_HLAC.m_id;

	CSQCProjectile(missile, true, PROJECTILE_HLAC, true);

	MUTATOR_CALLHOOK(EditProjectile, self, missile);
}

void W_HLAC_Attack2()
{SELFPARAM();
	entity missile;
    float spread;

    spread = WEP_CVAR_SEC(hlac, spread);


    if(self.crouch)
        spread = spread * WEP_CVAR_SEC(hlac, spread_crouchmod);

	W_SetupShot(self, false, 3, SND(LASERGUN_FIRE), CH_WEAPON_A, WEP_CVAR_SEC(hlac, damage));
	Send_Effect(EFFECT_BLASTER_MUZZLEFLASH, w_shotorg, w_shotdir * 1000, 1);

	missile = new(hlacbolt);
	missile.owner = missile.realowner = self;
	missile.bot_dodge = true;

    missile.bot_dodgerating = WEP_CVAR_SEC(hlac, damage);

	missile.movetype = MOVETYPE_FLY;
	PROJECTILE_MAKETRIGGER(missile);

	setorigin(missile, w_shotorg);
	setsize(missile, '0 0 0', '0 0 0');

	W_SetupProjVelocity_Basic(missile, WEP_CVAR_SEC(hlac, speed), spread);
	//missile.angles = vectoangles(missile.velocity); // csqc

	missile.touch = W_HLAC_Touch;
	missile.think = SUB_Remove_self;

    missile.nextthink = time + WEP_CVAR_SEC(hlac, lifetime);

	missile.flags = FL_PROJECTILE;
	missile.missile_flags = MIF_SPLASH;
	missile.projectiledeathtype = WEP_HLAC.m_id | HITTYPE_SECONDARY;

	CSQCProjectile(missile, true, PROJECTILE_HLAC, true);

	MUTATOR_CALLHOOK(EditProjectile, self, missile);
}

// weapon frames
void W_HLAC_Attack_Frame(Weapon thiswep, entity actor, .entity weaponentity, int fire)
{
	if(PS(actor).m_weapon != PS(actor).m_switchweapon) // abort immediately if switching
	{
		w_ready(thiswep, actor, weaponentity, fire);
		return;
	}

	if(actor.BUTTON_ATCK)
	{
		if(!thiswep.wr_checkammo1(thiswep))
		if(!(actor.items & IT_UNLIMITED_WEAPON_AMMO))
		{
			W_SwitchWeapon_Force(actor, w_getbestweapon(actor));
			w_ready(thiswep, actor, weaponentity, fire);
			return;
		}

		int slot = weaponslot(weaponentity);
		ATTACK_FINISHED(actor, slot) = time + WEP_CVAR_PRI(hlac, refire) * W_WeaponRateFactor();
		W_HLAC_Attack(WEP_HLAC);
		actor.misc_bulletcounter = actor.misc_bulletcounter + 1;
        weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_PRI(hlac, refire), W_HLAC_Attack_Frame);
	}
	else
	{
		weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_PRI(hlac, animtime), w_ready);
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
		METHOD(HLAC, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
		{
			if(autocvar_g_balance_hlac_reload_ammo && actor.clip_load < min(WEP_CVAR_PRI(hlac, ammo), WEP_CVAR_SEC(hlac, ammo))) { // forced reload
				thiswep.wr_reload(thiswep);
			} else if(fire & 1)
			{
				if(weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR_PRI(hlac, refire)))
				{
					actor.misc_bulletcounter = 0;
					W_HLAC_Attack(thiswep);
					weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_PRI(hlac, refire), W_HLAC_Attack_Frame);
				}
			}

			else if((fire & 2) && WEP_CVAR(hlac, secondary))
			{
				if(weapon_prepareattack(thiswep, actor, weaponentity, true, WEP_CVAR_SEC(hlac, refire)))
				{
					W_HLAC_Attack2_Frame(thiswep);
					weapon_thinkf(actor, weaponentity, WFRAME_FIRE2, WEP_CVAR_SEC(hlac, animtime), w_ready);
				}
			}
		}
		METHOD(HLAC, wr_checkammo1, bool(entity thiswep))
		{
			float ammo_amount = self.(thiswep.ammo_field) >= WEP_CVAR_PRI(hlac, ammo);
			ammo_amount += self.(weapon_load[WEP_HLAC.m_id]) >= WEP_CVAR_PRI(hlac, ammo);
			return ammo_amount;
		}
		METHOD(HLAC, wr_checkammo2, bool(entity thiswep))
		{
			float ammo_amount = self.(thiswep.ammo_field) >= WEP_CVAR_SEC(hlac, ammo);
			ammo_amount += self.(weapon_load[WEP_HLAC.m_id]) >= WEP_CVAR_SEC(hlac, ammo);
			return ammo_amount;
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
			pointparticles(EFFECT_BLASTER_IMPACT, org2, w_backoff * 1000, 1);
			if(!w_issilent)
				sound(self, CH_SHOTS, SND_LASERIMPACT, VOL_BASE, ATTN_NORM);
		}

#endif
#endif
