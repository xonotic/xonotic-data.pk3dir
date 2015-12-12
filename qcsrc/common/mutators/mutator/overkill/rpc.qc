#ifndef IMPLEMENTATION
CLASS(RocketPropelledChainsaw, Weapon)
/* ammotype  */ ATTRIB(RocketPropelledChainsaw, ammo_field, .int, ammo_rockets)
/* impulse   */ ATTRIB(RocketPropelledChainsaw, impulse, int, 7)
/* flags     */ ATTRIB(RocketPropelledChainsaw, spawnflags, int, WEP_FLAG_MUTATORBLOCKED | WEP_FLAG_HIDDEN | WEP_FLAG_NORMAL | WEP_FLAG_CANCLIMB | WEP_FLAG_RELOADABLE | WEP_TYPE_SPLASH | WEP_FLAG_SUPERWEAPON);
/* rating    */ ATTRIB(RocketPropelledChainsaw, bot_pickupbasevalue, float, BOT_PICKUP_RATING_HIGH);
/* color     */ ATTRIB(RocketPropelledChainsaw, wpcolor, vector, '0.5 0.5 0');
/* modelname */ ATTRIB(RocketPropelledChainsaw, mdl, string, "ok_rl");
#ifndef MENUQC
/* model     */ ATTRIB(RocketPropelledChainsaw, m_model, Model, MDL_RPC_ITEM);
#endif
/* crosshair */ ATTRIB(RocketPropelledChainsaw, w_crosshair, string, "gfx/crosshairrocketlauncher");
/* crosshair */ ATTRIB(RocketPropelledChainsaw, w_crosshair_size, float, 0.6);
/* wepimg    */ ATTRIB(RocketPropelledChainsaw, model2, string, "weaponrpc");
/* refname   */ ATTRIB(RocketPropelledChainsaw, netname, string, "rpc");
/* wepname   */ ATTRIB(RocketPropelledChainsaw, m_name, string, _("Rocket Propelled Chainsaw"));

#define X(BEGIN, P, END, class, prefix) \
	BEGIN(class) \
		P(class, prefix, ammo, float, NONE) \
		P(class, prefix, animtime, float, NONE) \
		P(class, prefix, damage2, float, NONE) \
		P(class, prefix, damageforcescale, float, NONE) \
		P(class, prefix, damage, float, NONE) \
		P(class, prefix, edgedamage, float, NONE) \
		P(class, prefix, force, float, NONE) \
		P(class, prefix, health, float, NONE) \
		P(class, prefix, lifetime, float, NONE) \
		P(class, prefix, radius, float, NONE) \
		P(class, prefix, refire, float, NONE) \
		P(class, prefix, reload_ammo, float, NONE) \
        P(class, prefix, reload_time, float, NONE) \
		P(class, prefix, speedaccel, float, NONE) \
		P(class, prefix, speed, float, NONE) \
        P(class, prefix, switchdelay_drop, float, NONE) \
        P(class, prefix, switchdelay_raise, float, NONE) \
        P(class, prefix, weaponreplace, string, NONE) \
        P(class, prefix, weaponstartoverride, float, NONE) \
        P(class, prefix, weaponstart, float, NONE) \
        P(class, prefix, weaponthrowable, float, NONE) \
    END()
    W_PROPS(X, RocketPropelledChainsaw, rpc)
#undef X

ENDCLASS(RocketPropelledChainsaw)
REGISTER_WEAPON(RPC, rpc, NEW(RocketPropelledChainsaw));

#endif
#ifdef IMPLEMENTATION
#ifdef SVQC
spawnfunc(weapon_rpc) { weapon_defaultspawnfunc(this, WEP_RPC); }

void W_RocketPropelledChainsaw_Explode()
{SELFPARAM();
	self.event_damage = func_null;
	self.takedamage = DAMAGE_NO;

	RadiusDamage (self, self.realowner, WEP_CVAR(rpc, damage), WEP_CVAR(rpc, edgedamage), WEP_CVAR(rpc, radius), world, world, WEP_CVAR(rpc, force), self.projectiledeathtype, other);

	remove (self);
}

void W_RocketPropelledChainsaw_Touch ()
{SELFPARAM();
	if(WarpZone_Projectile_Touch())
		if(wasfreed(self))
			return;

	W_RocketPropelledChainsaw_Explode();
}

void W_RocketPropelledChainsaw_Damage (entity inflictor, entity attacker, float damage, int deathtype, vector hitloc, vector force)
{SELFPARAM();
	if (self.health <= 0)
		return;

	if (!W_CheckProjectileDamage(inflictor.realowner, self.realowner, deathtype, -1)) // no exceptions
		return; // g_projectiles_damage says to halt

	self.health = self.health - damage;

	if (self.health <= 0)
		W_PrepareExplosionByDamage(attacker, W_RocketPropelledChainsaw_Explode);
}

void W_RocketPropelledChainsaw_Think()
{SELFPARAM();
	if(self.cnt <= time)
	{
		remove(self);
		return;
	}

	self.cnt = vlen(self.velocity);
	self.wait = self.cnt * sys_frametime;
	self.pos1 = normalize(self.velocity);

	tracebox(self.origin, self.mins, self.maxs, self.origin + self.pos1 * (2 * self.wait), MOVE_NORMAL, self);
	if(IS_PLAYER(trace_ent))
		Damage (trace_ent, self, self.realowner, WEP_CVAR(rpc, damage2), self.projectiledeathtype, self.origin, normalize(self.origin - other.origin) * WEP_CVAR(rpc, force));

	self.velocity = self.pos1 * (self.cnt + (WEP_CVAR(rpc, speedaccel) * sys_frametime));

	UpdateCSQCProjectile(self);
	self.nextthink = time;
}

void W_RocketPropelledChainsaw_Attack (Weapon thiswep)
{SELFPARAM();
	entity missile = spawn(); //WarpZone_RefSys_SpawnSameRefSys(self);
	entity flash = spawn ();

	W_DecreaseAmmo(thiswep, self, WEP_CVAR(rpc, ammo));
	W_SetupShot_ProjectileSize (self, '-3 -3 -3', '3 3 3', false, 5, SND(ROCKET_FIRE), CH_WEAPON_A, WEP_CVAR(rpc, damage));
	Send_Effect(EFFECT_ROCKET_MUZZLEFLASH, w_shotorg, w_shotdir * 1000, 1);
	PROJECTILE_MAKETRIGGER(missile);

	missile.owner = missile.realowner = self;
	missile.bot_dodge = true;
	missile.bot_dodgerating = WEP_CVAR(rpc, damage) * 2;

	missile.takedamage = DAMAGE_YES;
	missile.damageforcescale = WEP_CVAR(rpc, damageforcescale);
	missile.health = WEP_CVAR(rpc, health);
	missile.event_damage = W_RocketPropelledChainsaw_Damage;
	missile.damagedbycontents = true;
	missile.movetype = MOVETYPE_FLY;

	missile.projectiledeathtype = WEP_RPC.m_id;
	setsize (missile, '-3 -3 -3', '3 3 3'); // give it some size so it can be shot

	setorigin (missile, w_shotorg - v_forward * 3); // move it back so it hits the wall at the right point
	W_SetupProjVelocity_Basic(missile, WEP_CVAR(rpc, speed), 0);

	missile.touch = W_RocketPropelledChainsaw_Touch;

	missile.think = W_RocketPropelledChainsaw_Think;
	missile.cnt = time + WEP_CVAR(rpc, lifetime);
	missile.nextthink = time;
	missile.flags = FL_PROJECTILE;

	CSQCProjectile(missile, true, PROJECTILE_RPC, false);

	setmodel(flash, MDL_RPC_MUZZLEFLASH); // precision set below
	SUB_SetFade (flash, time, 0.1);
	flash.effects = EF_ADDITIVE | EF_FULLBRIGHT | EF_LOWPRECISION;
	W_AttachToShotorg(self, flash, '5 0 0');
	missile.pos1 = missile.velocity;

	MUTATOR_CALLHOOK(EditProjectile, self, missile);
}

		METHOD(RocketPropelledChainsaw, wr_aim, void(entity thiswep))
		{
			self.BUTTON_ATCK = bot_aim(WEP_CVAR(rpc, speed), 0, WEP_CVAR(rpc, lifetime), false);
		}
		METHOD(RocketPropelledChainsaw, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
		{
			if(WEP_CVAR(rpc, reload_ammo) && actor.clip_load < WEP_CVAR(rpc, ammo)) {
				thiswep.wr_reload(thiswep);
			} else
			{
				if (fire & 1)
				{
					if(weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR(rpc, refire)))
					{
						W_RocketPropelledChainsaw_Attack(thiswep);
						weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR(rpc, animtime), w_ready);
					}
				}

				if (fire & 2)
				{
					// to-do
				}
			}
		}
		METHOD(RocketPropelledChainsaw, wr_checkammo1, bool(entity thiswep))
		{
			float ammo_amount = self.(thiswep.ammo_field) >= WEP_CVAR(rpc, ammo);
			ammo_amount += self.(weapon_load[WEP_RPC.m_id]) >= WEP_CVAR(rpc, ammo);
			return ammo_amount;
		}
		METHOD(RocketPropelledChainsaw, wr_checkammo2, bool(entity thiswep))
		{
			return false;
		}
		METHOD(RocketPropelledChainsaw, wr_reload, void(entity thiswep))
		{
			W_Reload(self, WEP_CVAR(rpc, ammo), SND(RELOAD));
		}
		METHOD(RocketPropelledChainsaw, wr_suicidemessage, int(entity thiswep))
		{
			if((w_deathtype & HITTYPE_BOUNCE) || (w_deathtype & HITTYPE_SPLASH))
				return WEAPON_RPC_SUICIDE_SPLASH;
			else
				return WEAPON_RPC_SUICIDE_DIRECT;
		}
		METHOD(RocketPropelledChainsaw, wr_killmessage, int(entity thiswep))
		{
			if(w_deathtype & HITTYPE_SECONDARY)
				return WEAPON_BLASTER_MURDER;
			else if((w_deathtype & HITTYPE_BOUNCE) || (w_deathtype & HITTYPE_SPLASH))
				return WEAPON_RPC_MURDER_SPLASH;
			else
				return WEAPON_RPC_MURDER_DIRECT;
		}

#endif

#ifdef CSQC

		METHOD(RocketPropelledChainsaw, wr_impacteffect, void(entity thiswep))
		{
			vector org2;
			org2 = w_org + w_backoff * 12;
			pointparticles(EFFECT_ROCKET_EXPLODE, org2, '0 0 0', 1);
			if(!w_issilent)
				sound(self, CH_SHOTS, SND_ROCKET_IMPACT, VOL_BASE, ATTEN_NORM);
		}

#endif
#endif
