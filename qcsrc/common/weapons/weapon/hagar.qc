#ifndef IMPLEMENTATION
CLASS(Hagar, Weapon)
/* ammotype  */ ATTRIB(Hagar, ammo_field, .int, ammo_rockets)
/* impulse   */ ATTRIB(Hagar, impulse, int, 8)
/* flags     */ ATTRIB(Hagar, spawnflags, int, WEP_FLAG_NORMAL | WEP_FLAG_RELOADABLE | WEP_FLAG_CANCLIMB | WEP_TYPE_SPLASH);
/* rating    */ ATTRIB(Hagar, bot_pickupbasevalue, float, BOT_PICKUP_RATING_MID);
/* color     */ ATTRIB(Hagar, wpcolor, vector, '1 1 0.5');
/* modelname */ ATTRIB(Hagar, mdl, string, "hagar");
#ifndef MENUQC
/* model     */ ATTRIB(Hagar, m_model, Model, MDL_HAGAR_ITEM);
#endif
/* crosshair */ ATTRIB(Hagar, w_crosshair, string, "gfx/crosshairhagar");
/* crosshair */ ATTRIB(Hagar, w_crosshair_size, float, 0.8);
/* wepimg    */ ATTRIB(Hagar, model2, string, "weaponhagar");
/* refname   */ ATTRIB(Hagar, netname, string, "hagar");
/* wepname   */ ATTRIB(Hagar, m_name, string, _("Hagar"));

#define X(BEGIN, P, END, class, prefix) \
	BEGIN(class) \
		P(class, prefix, ammo, float, BOTH) \
        P(class, prefix, damageforcescale, float, BOTH) \
        P(class, prefix, damage, float, BOTH) \
        P(class, prefix, edgedamage, float, BOTH) \
        P(class, prefix, force, float, BOTH) \
        P(class, prefix, health, float, BOTH) \
        P(class, prefix, lifetime, float, PRI) \
        P(class, prefix, lifetime_min, float, SEC) \
        P(class, prefix, lifetime_rand, float, SEC) \
        P(class, prefix, load, float, SEC) \
        P(class, prefix, load_abort, float, SEC) \
        P(class, prefix, load_animtime, float, SEC) \
        P(class, prefix, load_hold, float, SEC) \
        P(class, prefix, load_linkexplode, float, SEC) \
        P(class, prefix, load_max, float, SEC) \
        P(class, prefix, load_releasedeath, float, SEC) \
        P(class, prefix, load_speed, float, SEC) \
        P(class, prefix, load_spread, float, SEC) \
        P(class, prefix, load_spread_bias, float, SEC) \
        P(class, prefix, radius, float, BOTH) \
        P(class, prefix, refire, float, BOTH) \
        P(class, prefix, reload_ammo, float, NONE) \
        P(class, prefix, reload_time, float, NONE) \
        P(class, prefix, secondary, float, NONE) \
        P(class, prefix, speed, float, BOTH) \
        P(class, prefix, spread, float, BOTH) \
        P(class, prefix, switchdelay_drop, float, NONE) \
        P(class, prefix, switchdelay_raise, float, NONE) \
        P(class, prefix, weaponreplace, string,NONE) \
        P(class, prefix, weaponstartoverride, float, NONE) \
        P(class, prefix, weaponstart, float, NONE) \
        P(class, prefix, weaponthrowable, float, NONE) \
	END()
    W_PROPS(X, Hagar, hagar)
#undef X

ENDCLASS(Hagar)
REGISTER_WEAPON(HAGAR, hagar, NEW(Hagar));

#endif
#ifdef IMPLEMENTATION
#ifdef SVQC
spawnfunc(weapon_hagar) { weapon_defaultspawnfunc(this, WEP_HAGAR); }

// NO bounce protection, as bounces are limited!

void W_Hagar_Explode()
{SELFPARAM();
	self.event_damage = func_null;
	RadiusDamage(self, self.realowner, WEP_CVAR_PRI(hagar, damage), WEP_CVAR_PRI(hagar, edgedamage), WEP_CVAR_PRI(hagar, radius), world, world, WEP_CVAR_PRI(hagar, force), self.projectiledeathtype, other);

	remove(self);
}

void W_Hagar_Explode2()
{SELFPARAM();
	self.event_damage = func_null;
	RadiusDamage(self, self.realowner, WEP_CVAR_SEC(hagar, damage), WEP_CVAR_SEC(hagar, edgedamage), WEP_CVAR_SEC(hagar, radius), world, world, WEP_CVAR_SEC(hagar, force), self.projectiledeathtype, other);

	remove(self);
}

void W_Hagar_Damage(entity inflictor, entity attacker, float damage, int deathtype, vector hitloc, vector force)
{SELFPARAM();
	if(self.health <= 0)
		return;

	float is_linkexplode = ( ((inflictor.owner != world) ? (inflictor.owner == self.owner) : true)
		&& (inflictor.projectiledeathtype & HITTYPE_SECONDARY)
		&& (self.projectiledeathtype & HITTYPE_SECONDARY));

	if(is_linkexplode)
		is_linkexplode = (is_linkexplode && WEP_CVAR_SEC(hagar, load_linkexplode));
	else
		is_linkexplode = -1; // not secondary load, so continue as normal without exception.

	if(!W_CheckProjectileDamage(inflictor.realowner, self.realowner, deathtype, is_linkexplode))
		return; // g_projectiles_damage says to halt

	self.health = self.health - damage;
	self.angles = vectoangles(self.velocity);

	if(self.health <= 0)
		W_PrepareExplosionByDamage(attacker, self.think);
}

void W_Hagar_Touch()
{SELFPARAM();
	PROJECTILE_TOUCH;
	self.use();
}

void W_Hagar_Touch2()
{SELFPARAM();
	PROJECTILE_TOUCH;

	if(self.cnt > 0 || other.takedamage == DAMAGE_AIM) {
		self.use();
	} else {
		self.cnt++;
		Send_Effect(EFFECT_HAGAR_BOUNCE, self.origin, self.velocity, 1);
		self.angles = vectoangles(self.velocity);
		self.owner = world;
		self.projectiledeathtype |= HITTYPE_BOUNCE;
	}
}

void W_Hagar_Attack(Weapon thiswep)
{SELFPARAM();
	entity missile;

	W_DecreaseAmmo(thiswep, self, WEP_CVAR_PRI(hagar, ammo));

	W_SetupShot(self, false, 2, SND(HAGAR_FIRE), CH_WEAPON_A, WEP_CVAR_PRI(hagar, damage));

	Send_Effect(EFFECT_HAGAR_MUZZLEFLASH, w_shotorg, w_shotdir * 1000, 1);

	missile = new(missile);
	missile.owner = missile.realowner = self;
	missile.bot_dodge = true;
	missile.bot_dodgerating = WEP_CVAR_PRI(hagar, damage);

	missile.takedamage = DAMAGE_YES;
	missile.health = WEP_CVAR_PRI(hagar, health);
	missile.damageforcescale = WEP_CVAR_PRI(hagar, damageforcescale);
	missile.event_damage = W_Hagar_Damage;
	missile.damagedbycontents = true;

	missile.touch = W_Hagar_Touch;
	missile.use = W_Hagar_Explode;
	missile.think = adaptor_think2use_hittype_splash;
	missile.nextthink = time + WEP_CVAR_PRI(hagar, lifetime);
	PROJECTILE_MAKETRIGGER(missile);
	missile.projectiledeathtype = WEP_HAGAR.m_id;
	setorigin(missile, w_shotorg);
	setsize(missile, '0 0 0', '0 0 0');

	missile.movetype = MOVETYPE_FLY;
	W_SetupProjVelocity_PRI(missile, hagar);

	missile.angles = vectoangles(missile.velocity);
	missile.flags = FL_PROJECTILE;
	missile.missile_flags = MIF_SPLASH;

	CSQCProjectile(missile, true, PROJECTILE_HAGAR, true);

	MUTATOR_CALLHOOK(EditProjectile, self, missile);
}

void W_Hagar_Attack2(Weapon thiswep)
{SELFPARAM();
	entity missile;

	W_DecreaseAmmo(thiswep, self, WEP_CVAR_SEC(hagar, ammo));

	W_SetupShot(self, false, 2, SND(HAGAR_FIRE), CH_WEAPON_A, WEP_CVAR_SEC(hagar, damage));

	Send_Effect(EFFECT_HAGAR_MUZZLEFLASH, w_shotorg, w_shotdir * 1000, 1);

	missile = new(missile);
	missile.owner = missile.realowner = self;
	missile.bot_dodge = true;
	missile.bot_dodgerating = WEP_CVAR_SEC(hagar, damage);

	missile.takedamage = DAMAGE_YES;
	missile.health = WEP_CVAR_SEC(hagar, health);
	missile.damageforcescale = WEP_CVAR_SEC(hagar, damageforcescale);
	missile.event_damage = W_Hagar_Damage;
	missile.damagedbycontents = true;

	missile.touch = W_Hagar_Touch2;
	missile.cnt = 0;
	missile.use = W_Hagar_Explode2;
	missile.think = adaptor_think2use_hittype_splash;
	missile.nextthink = time + WEP_CVAR_SEC(hagar, lifetime_min) + random() * WEP_CVAR_SEC(hagar, lifetime_rand);
	PROJECTILE_MAKETRIGGER(missile);
	missile.projectiledeathtype = WEP_HAGAR.m_id | HITTYPE_SECONDARY;
	setorigin(missile, w_shotorg);
	setsize(missile, '0 0 0', '0 0 0');

	missile.movetype = MOVETYPE_BOUNCEMISSILE;
	W_SetupProjVelocity_SEC(missile, hagar);

	missile.angles = vectoangles(missile.velocity);
	missile.flags = FL_PROJECTILE;
	missile.missile_flags = MIF_SPLASH;

	CSQCProjectile(missile, true, PROJECTILE_HAGAR_BOUNCING, true);

	MUTATOR_CALLHOOK(EditProjectile, self, missile);
}

.float hagar_loadstep, hagar_loadblock, hagar_loadbeep, hagar_warning;
void W_Hagar_Attack2_Load_Release(.entity weaponentity)
{SELFPARAM();
	// time to release the rockets we've loaded

	entity missile;
	float counter, shots, spread_pershot;
	vector s;
	vector forward, right, up;

	if(!self.hagar_load)
		return;

	weapon_prepareattack_do(self, weaponentity, true, WEP_CVAR_SEC(hagar, refire));

	W_SetupShot(self, false, 2, SND(HAGAR_FIRE), CH_WEAPON_A, WEP_CVAR_SEC(hagar, damage));
	Send_Effect(EFFECT_HAGAR_MUZZLEFLASH, w_shotorg, w_shotdir * 1000, 1);

	forward = v_forward;
	right = v_right;
	up = v_up;

	shots = self.hagar_load;
	missile = world;
	for(counter = 0; counter < shots; ++counter)
	{
		missile = new(missile);
		missile.owner = missile.realowner = self;
		missile.bot_dodge = true;
		missile.bot_dodgerating = WEP_CVAR_SEC(hagar, damage);

		missile.takedamage = DAMAGE_YES;
		missile.health = WEP_CVAR_SEC(hagar, health);
		missile.damageforcescale = WEP_CVAR_SEC(hagar, damageforcescale);
		missile.event_damage = W_Hagar_Damage;
		missile.damagedbycontents = true;

		missile.touch = W_Hagar_Touch; // not bouncy
		missile.use = W_Hagar_Explode2;
		missile.think = adaptor_think2use_hittype_splash;
		missile.nextthink = time + WEP_CVAR_SEC(hagar, lifetime_min) + random() * WEP_CVAR_SEC(hagar, lifetime_rand);
		PROJECTILE_MAKETRIGGER(missile);
		missile.projectiledeathtype = WEP_HAGAR.m_id | HITTYPE_SECONDARY;
		setorigin(missile, w_shotorg);
		setsize(missile, '0 0 0', '0 0 0');
		missile.movetype = MOVETYPE_FLY;
		missile.missile_flags = MIF_SPLASH;

		// per-shot spread calculation: the more shots there are, the less spread is applied (based on the bias cvar)
		spread_pershot = ((shots - 1) / (WEP_CVAR_SEC(hagar, load_max) - 1));
		spread_pershot = (1 - (spread_pershot * WEP_CVAR_SEC(hagar, load_spread_bias)));
		spread_pershot = (WEP_CVAR_SEC(hagar, spread) * spread_pershot * g_weaponspreadfactor);

		// pattern spread calculation
		s = '0 0 0';
		if(counter == 0)
			s = '0 0 0';
		else
		{
			makevectors('0 360 0' * (0.75 + (counter - 0.5) / (shots - 1)));
			s.y = v_forward.x;
			s.z = v_forward.y;
		}
		s = s * WEP_CVAR_SEC(hagar, load_spread) * g_weaponspreadfactor;

		W_SetupProjVelocity_Explicit(missile, w_shotdir + right * s.y + up * s.z, v_up, WEP_CVAR_SEC(hagar, speed), 0, 0, spread_pershot, false);

		missile.angles = vectoangles(missile.velocity);
		missile.flags = FL_PROJECTILE;

		CSQCProjectile(missile, true, PROJECTILE_HAGAR, true);

		MUTATOR_CALLHOOK(EditProjectile, self, missile);
	}

	weapon_thinkf(self, weaponentity, WFRAME_FIRE2, WEP_CVAR_SEC(hagar, load_animtime), w_ready);
	self.hagar_loadstep = time + WEP_CVAR_SEC(hagar, refire) * W_WeaponRateFactor();
	self.hagar_load = 0;
}

void W_Hagar_Attack2_Load(Weapon thiswep, .entity weaponentity)
{SELFPARAM();
	// loadable hagar secondary attack, must always run each frame

	if(time < game_starttime)
		return;

	bool loaded = self.hagar_load >= WEP_CVAR_SEC(hagar, load_max);

	// this is different than WR_CHECKAMMO when it comes to reloading
	bool enough_ammo;
	if(self.items & IT_UNLIMITED_WEAPON_AMMO)
		enough_ammo = true;
	else if(autocvar_g_balance_hagar_reload_ammo)
		enough_ammo = self.(weapon_load[WEP_HAGAR.m_id]) >= WEP_CVAR_SEC(hagar, ammo);
	else
		enough_ammo = self.(thiswep.ammo_field) >= WEP_CVAR_SEC(hagar, ammo);

	bool stopped = loaded || !enough_ammo;

	if(self.BUTTON_ATCK2)
	{
		if(self.BUTTON_ATCK && WEP_CVAR_SEC(hagar, load_abort))
		{
			if(self.hagar_load)
			{
				// if we pressed primary fire while loading, unload all rockets and abort
				self.(weaponentity).state = WS_READY;
				W_DecreaseAmmo(thiswep, self, WEP_CVAR_SEC(hagar, ammo) * self.hagar_load * -1); // give back ammo
				self.hagar_load = 0;
				sound(self, CH_WEAPON_A, SND_HAGAR_BEEP, VOL_BASE, ATTN_NORM);

				// pause until we can load rockets again, once we re-press the alt fire button
				self.hagar_loadstep = time + WEP_CVAR_SEC(hagar, load_speed) * W_WeaponRateFactor();

				// require letting go of the alt fire button before we can load again
				self.hagar_loadblock = true;
			}
		}
		else
		{
			// check if we can attempt to load another rocket
			if(!stopped)
			{
				if(!self.hagar_loadblock && self.hagar_loadstep < time)
				{
					W_DecreaseAmmo(thiswep, self, WEP_CVAR_SEC(hagar, ammo));
					self.(weaponentity).state = WS_INUSE;
					self.hagar_load += 1;
					sound(self, CH_WEAPON_B, SND_HAGAR_LOAD, VOL_BASE * 0.8, ATTN_NORM); // sound is too loud according to most

					if(self.hagar_load >= WEP_CVAR_SEC(hagar, load_max))
						stopped = true;
					else
						self.hagar_loadstep = time + WEP_CVAR_SEC(hagar, load_speed) * W_WeaponRateFactor();
				}
			}
			if(stopped && !self.hagar_loadbeep && self.hagar_load) // prevents the beep from playing each frame
			{
				// if this is the last rocket we can load, play a beep sound to notify the player
				sound(self, CH_WEAPON_A, SND_HAGAR_BEEP, VOL_BASE, ATTN_NORM);
				self.hagar_loadbeep = true;
				self.hagar_loadstep = time + WEP_CVAR_SEC(hagar, load_hold) * W_WeaponRateFactor();
			}
		}
	}
	else if(self.hagar_loadblock)
	{
		// the alt fire button has been released, so re-enable loading if blocked
		self.hagar_loadblock = false;
	}

	if(self.hagar_load)
	{
		// play warning sound if we're about to release
		if(stopped && self.hagar_loadstep - 0.5 < time && WEP_CVAR_SEC(hagar, load_hold) >= 0)
		{
			if(!self.hagar_warning) // prevents the beep from playing each frame
			{
				// we're about to automatically release after holding time, play a beep sound to notify the player
				sound(self, CH_WEAPON_A, SND_HAGAR_BEEP, VOL_BASE, ATTN_NORM);
				self.hagar_warning = true;
			}
		}

		// release if player let go of button or if they've held it in too long
		if(!self.BUTTON_ATCK2 || (stopped && self.hagar_loadstep < time && WEP_CVAR_SEC(hagar, load_hold) >= 0))
		{
			self.(weaponentity).state = WS_READY;
			W_Hagar_Attack2_Load_Release(weaponentity);
		}
	}
	else
	{
		self.hagar_loadbeep = false;
		self.hagar_warning = false;

		// we aren't checking ammo during an attack, so we must do it here
		if(!(thiswep.wr_checkammo1(thiswep) + thiswep.wr_checkammo2(thiswep)))
		if(!(self.items & IT_UNLIMITED_WEAPON_AMMO))
		{
			// note: this doesn't force the switch
			W_SwitchToOtherWeapon(self);
			return;
		}
	}
}

		METHOD(Hagar, wr_aim, void(entity thiswep))
		{
			if(random()>0.15)
				self.BUTTON_ATCK = bot_aim(WEP_CVAR_PRI(hagar, speed), 0, WEP_CVAR_PRI(hagar, lifetime), false);
			else // not using secondary_speed since these are only 15% and should cause some ricochets without re-aiming
				self.BUTTON_ATCK2 = bot_aim(WEP_CVAR_PRI(hagar, speed), 0, WEP_CVAR_PRI(hagar, lifetime), false);
		}
		METHOD(Hagar, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
		{
			float loadable_secondary;
			loadable_secondary = (WEP_CVAR_SEC(hagar, load) && WEP_CVAR(hagar, secondary));

			if(loadable_secondary)
				W_Hagar_Attack2_Load(thiswep, weaponentity); // must always run each frame
			if(autocvar_g_balance_hagar_reload_ammo && actor.clip_load < min(WEP_CVAR_PRI(hagar, ammo), WEP_CVAR_SEC(hagar, ammo))) { // forced reload
				thiswep.wr_reload(thiswep);
			} else if((fire & 1) && !actor.hagar_load && !actor.hagar_loadblock) // not while secondary is loaded or awaiting reset
			{
				if(weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR_PRI(hagar, refire)))
				{
					W_Hagar_Attack(thiswep);
					weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_PRI(hagar, refire), w_ready);
				}
			}
			else if((fire & 2) && !loadable_secondary && WEP_CVAR(hagar, secondary))
			{
				if(weapon_prepareattack(thiswep, actor, weaponentity, true, WEP_CVAR_SEC(hagar, refire)))
				{
					W_Hagar_Attack2(thiswep);
					weapon_thinkf(actor, weaponentity, WFRAME_FIRE2, WEP_CVAR_SEC(hagar, refire), w_ready);
				}
			}
		}
		METHOD(Hagar, wr_gonethink, void(entity thiswep))
		{
			// we lost the weapon and want to prepare switching away
			if(self.hagar_load)
			{
				.entity weaponentity = weaponentities[0]; // TODO: unhardcode
				self.(weaponentity).state = WS_READY;
				W_Hagar_Attack2_Load_Release(weaponentity);
			}
		}
		METHOD(Hagar, wr_setup, void(entity thiswep))
		{
			self.hagar_loadblock = false;

			if(self.hagar_load)
			{
				W_DecreaseAmmo(thiswep, self, WEP_CVAR_SEC(hagar, ammo) * self.hagar_load * -1); // give back ammo if necessary
				self.hagar_load = 0;
			}
		}
		METHOD(Hagar, wr_checkammo1, bool(entity thiswep))
		{
			float ammo_amount = self.(thiswep.ammo_field) >= WEP_CVAR_PRI(hagar, ammo);
			ammo_amount += self.(weapon_load[WEP_HAGAR.m_id]) >= WEP_CVAR_PRI(hagar, ammo);
			return ammo_amount;
		}
		METHOD(Hagar, wr_checkammo2, bool(entity thiswep))
		{
			float ammo_amount = self.(thiswep.ammo_field) >= WEP_CVAR_SEC(hagar, ammo);
			ammo_amount += self.(weapon_load[WEP_HAGAR.m_id]) >= WEP_CVAR_SEC(hagar, ammo);
			return ammo_amount;
		}
		METHOD(Hagar, wr_resetplayer, void(entity thiswep))
		{
			self.hagar_load = 0;
		}
		METHOD(Hagar, wr_playerdeath, void(entity thiswep))
		{
			.entity weaponentity = weaponentities[0]; // TODO: unhardcode
			// if we have any rockets loaded when we die, release them
			if(self.hagar_load && WEP_CVAR_SEC(hagar, load_releasedeath))
				W_Hagar_Attack2_Load_Release(weaponentity);
		}
		METHOD(Hagar, wr_reload, void(entity thiswep))
		{
			if(!self.hagar_load) // require releasing loaded rockets first
				W_Reload(self, min(WEP_CVAR_PRI(hagar, ammo), WEP_CVAR_SEC(hagar, ammo)), SND(RELOAD));
		}
		METHOD(Hagar, wr_suicidemessage, int(entity thiswep))
		{
			return WEAPON_HAGAR_SUICIDE;
		}
		METHOD(Hagar, wr_killmessage, int(entity thiswep))
		{
			if(w_deathtype & HITTYPE_SECONDARY)
				return WEAPON_HAGAR_MURDER_BURST;
			else
				return WEAPON_HAGAR_MURDER_SPRAY;
		}

#endif
#ifdef CSQC

		METHOD(Hagar, wr_impacteffect, void(entity thiswep))
		{
			vector org2;
			org2 = w_org + w_backoff * 6;
			pointparticles(EFFECT_HAGAR_EXPLODE, org2, '0 0 0', 1);
			if(!w_issilent)
			{
				if(w_random<0.15)
					sound(self, CH_SHOTS, SND_HAGEXP1, VOL_BASE, ATTN_NORM);
				else if(w_random<0.7)
					sound(self, CH_SHOTS, SND_HAGEXP2, VOL_BASE, ATTN_NORM);
				else
					sound(self, CH_SHOTS, SND_HAGEXP3, VOL_BASE, ATTN_NORM);
			}
		}

#endif
#endif
