#ifndef IMPLEMENTATION
CLASS(Hook, Weapon)
/* ammotype  */ ATTRIB(Hook, ammo_field, .int, ammo_fuel)
/* impulse   */ ATTRIB(Hook, impulse, int, 0)
/* flags     */ ATTRIB(Hook, spawnflags, int, WEP_FLAG_CANCLIMB | WEP_TYPE_SPLASH);
/* rating    */ ATTRIB(Hook, bot_pickupbasevalue, float, 0);
/* color     */ ATTRIB(Hook, wpcolor, vector, '0 0.5 0');
/* modelname */ ATTRIB(Hook, mdl, string, "hookgun");
#ifndef MENUQC
/* model     */ ATTRIB(Hook, m_model, Model, MDL_HOOK_ITEM);
#endif
/* crosshair */ ATTRIB(Hook, w_crosshair, string, "gfx/crosshairhook");
/* crosshair */ ATTRIB(Hook, w_crosshair_size, float, 0.5);
/* wepimg    */ ATTRIB(Hook, model2, string, "weaponhook");
/* refname   */ ATTRIB(Hook, netname, string, "hook");
/* wepname   */ ATTRIB(Hook, message, string, _("Grappling Hook"));
	ATTRIB(Hook, ammo_factor, float, 1)
ENDCLASS(Hook)
REGISTER_WEAPON(HOOK, NEW(Hook));

CLASS(OffhandHook, OffhandWeapon)
    METHOD(OffhandHook, offhand_think, void(OffhandHook this, entity actor, bool key_pressed))
    {
    	Weapon wep = WEP_HOOK;
    	wep.wr_think(wep, actor, key_pressed, false);
    }
ENDCLASS(OffhandHook)
OffhandHook OFFHAND_HOOK; STATIC_INIT(OFFHAND_HOOK) { OFFHAND_HOOK = NEW(OffhandHook); }

#define HOOK_SETTINGS(w_cvar,w_prop) HOOK_SETTINGS_LIST(w_cvar, w_prop, HOOK, hook)
#define HOOK_SETTINGS_LIST(w_cvar,w_prop,id,sn) \
	w_cvar(id, sn, BOTH, animtime) \
	w_cvar(id, sn, BOTH, refire) \
	w_cvar(id, sn, PRI,  ammo) \
	w_cvar(id, sn, PRI,  hooked_ammo) \
	w_cvar(id, sn, PRI,  hooked_time_free) \
	w_cvar(id, sn, PRI,  hooked_time_max) \
	w_cvar(id, sn, SEC,  damage) \
	w_cvar(id, sn, SEC,  duration) \
	w_cvar(id, sn, SEC,  edgedamage) \
	w_cvar(id, sn, SEC,  force) \
	w_cvar(id, sn, SEC,  gravity) \
	w_cvar(id, sn, SEC,  lifetime) \
	w_cvar(id, sn, SEC,  power) \
	w_cvar(id, sn, SEC,  radius) \
	w_cvar(id, sn, SEC,  speed) \
	w_cvar(id, sn, SEC,  health) \
	w_cvar(id, sn, SEC,  damageforcescale) \
	w_prop(id, sn, float,  switchdelay_raise, switchdelay_raise) \
	w_prop(id, sn, float,  switchdelay_drop, switchdelay_drop) \
	w_prop(id, sn, string, weaponreplace, weaponreplace) \
	w_prop(id, sn, float,  weaponstart, weaponstart) \
	w_prop(id, sn, float,  weaponstartoverride, weaponstartoverride) \
	w_prop(id, sn, float,  weaponthrowable, weaponthrowable)

#ifdef SVQC
HOOK_SETTINGS(WEP_ADD_CVAR, WEP_ADD_PROP)

.float dmg;
.float dmg_edge;
.float dmg_radius;
.float dmg_force;
.float dmg_power;
.float dmg_duration;
.float dmg_last;
.float hook_refire;
.float hook_time_hooked;
.float hook_time_fueldecrease;
#endif
#endif
#ifdef IMPLEMENTATION
#ifdef SVQC

spawnfunc(weapon_hook) { weapon_defaultspawnfunc(WEP_HOOK.m_id); }

void W_Hook_ExplodeThink(void)
{SELFPARAM();
	float dt, dmg_remaining_next, f;

	dt = time - self.teleport_time;
	dmg_remaining_next = pow(bound(0, 1 - dt / self.dmg_duration, 1), self.dmg_power);

	f = self.dmg_last - dmg_remaining_next;
	self.dmg_last = dmg_remaining_next;

	RadiusDamage(self, self.realowner, self.dmg * f, self.dmg_edge * f, self.dmg_radius, self.realowner, world, self.dmg_force * f, self.projectiledeathtype, world);
	self.projectiledeathtype |= HITTYPE_BOUNCE;
	//RadiusDamage(self, world, self.dmg * f, self.dmg_edge * f, self.dmg_radius, world, world, self.dmg_force * f, self.projectiledeathtype, world);

	if(dt < self.dmg_duration)
		self.nextthink = time + 0.05; // soon
	else
		remove(self);
}

void W_Hook_Explode2(void)
{SELFPARAM();
	self.event_damage = func_null;
	self.touch = func_null;
	self.effects |= EF_NODRAW;

	self.think = W_Hook_ExplodeThink;
	self.nextthink = time;
	self.dmg = WEP_CVAR_SEC(hook, damage);
	self.dmg_edge = WEP_CVAR_SEC(hook, edgedamage);
	self.dmg_radius = WEP_CVAR_SEC(hook, radius);
	self.dmg_force = WEP_CVAR_SEC(hook, force);
	self.dmg_power = WEP_CVAR_SEC(hook, power);
	self.dmg_duration = WEP_CVAR_SEC(hook, duration);
	self.teleport_time = time;
	self.dmg_last = 1;
	self.movetype = MOVETYPE_NONE;
}

void W_Hook_Damage(entity inflictor, entity attacker, float damage, int deathtype, vector hitloc, vector force)
{SELFPARAM();
	if(self.health <= 0)
		return;

	if(!W_CheckProjectileDamage(inflictor.realowner, self.realowner, deathtype, -1)) // no exceptions
		return; // g_projectiles_damage says to halt

	self.health = self.health - damage;

	if(self.health <= 0)
		W_PrepareExplosionByDamage(self.realowner, W_Hook_Explode2);
}

void W_Hook_Touch2(void)
{SELFPARAM();
	PROJECTILE_TOUCH;
	self.use();
}

void W_Hook_Attack2(Weapon thiswep, entity actor)
{
	//W_DecreaseAmmo(thiswep, actor, WEP_CVAR_SEC(hook, ammo)); // WEAPONTODO: Figure out how to handle ammo with hook secondary (gravitybomb)
	W_SetupShot(actor, false, 4, SND(HOOKBOMB_FIRE), CH_WEAPON_A, WEP_CVAR_SEC(hook, damage));

	entity gren = new(hookbomb);
	gren.owner = gren.realowner = actor;
	gren.bot_dodge = true;
	gren.bot_dodgerating = WEP_CVAR_SEC(hook, damage);
	gren.movetype = MOVETYPE_TOSS;
	PROJECTILE_MAKETRIGGER(gren);
	gren.projectiledeathtype = WEP_HOOK.m_id | HITTYPE_SECONDARY;
	setorigin(gren, w_shotorg);
	setsize(gren, '0 0 0', '0 0 0');

	gren.nextthink = time + WEP_CVAR_SEC(hook, lifetime);
	gren.think = adaptor_think2use_hittype_splash;
	gren.use = W_Hook_Explode2;
	gren.touch = W_Hook_Touch2;

	gren.takedamage = DAMAGE_YES;
	gren.health = WEP_CVAR_SEC(hook, health);
	gren.damageforcescale = WEP_CVAR_SEC(hook, damageforcescale);
	gren.event_damage = W_Hook_Damage;
	gren.damagedbycontents = true;
	gren.missile_flags = MIF_SPLASH | MIF_ARC;

	gren.velocity = '0 0 1' * WEP_CVAR_SEC(hook, speed);
	if (autocvar_g_projectiles_newton_style)
		gren.velocity = gren.velocity + actor.velocity;

	gren.gravity = WEP_CVAR_SEC(hook, gravity);
	//W_SetupProjVelocity_Basic(gren); // just falling down!

	gren.angles = '0 0 0';
	gren.flags = FL_PROJECTILE;

	CSQCProjectile(gren, true, PROJECTILE_HOOKBOMB, true);

	MUTATOR_CALLHOOK(EditProjectile, actor, gren);
}

		METHOD(Hook, wr_think, void(entity thiswep, entity actor, bool fire1, bool fire2))
		{
			if (fire1) {
				if(!actor.hook)
				if(!(actor.hook_state & HOOK_WAITING_FOR_RELEASE))
				if(time > actor.hook_refire)
				if(weapon_prepareattack(thiswep, actor, false, -1))
				{
					W_DecreaseAmmo(thiswep, actor, thiswep.ammo_factor * WEP_CVAR_PRI(hook, ammo));
					actor.hook_state |= HOOK_FIRING;
					actor.hook_state |= HOOK_WAITING_FOR_RELEASE;
					weapon_thinkf(actor, WFRAME_FIRE1, WEP_CVAR_PRI(hook, animtime), w_ready);
				}
			} else {
				actor.hook_state |= HOOK_REMOVING;
				actor.hook_state &= ~HOOK_WAITING_FOR_RELEASE;
			}

			if(fire2)
			{
				if(weapon_prepareattack(thiswep, actor, true, WEP_CVAR_SEC(hook, refire)))
				{
					W_Hook_Attack2(thiswep, actor);
					weapon_thinkf(actor, WFRAME_FIRE2, WEP_CVAR_SEC(hook, animtime), w_ready);
				}
			}

			if(actor.hook)
			{
				// if hooked, no bombs, and increase the timer
				actor.hook_refire = max(actor.hook_refire, time + WEP_CVAR_PRI(hook, refire) * W_WeaponRateFactor());

				// hook also inhibits health regeneration, but only for 1 second
				if(!(actor.items & IT_UNLIMITED_WEAPON_AMMO))
					actor.pauseregen_finished = max(actor.pauseregen_finished, time + autocvar_g_balance_pause_fuel_regen);
			}

			if(actor.hook && actor.hook.state == 1)
			{
				float hooked_time_max = WEP_CVAR_PRI(hook, hooked_time_max);
				if(hooked_time_max > 0)
				{
					if( time > actor.hook_time_hooked + hooked_time_max )
						actor.hook_state |= HOOK_REMOVING;
				}

				float hooked_fuel = thiswep.ammo_factor * WEP_CVAR_PRI(hook, hooked_ammo);
				if(hooked_fuel > 0)
				{
					if( time > actor.hook_time_fueldecrease )
					{
						if(!(actor.items & IT_UNLIMITED_WEAPON_AMMO))
						{
							if( actor.ammo_fuel >= (time - actor.hook_time_fueldecrease) * hooked_fuel )
							{
								W_DecreaseAmmo(thiswep, actor, (time - actor.hook_time_fueldecrease) * hooked_fuel);
								actor.hook_time_fueldecrease = time;
								// decrease next frame again
							}
							else
							{
								actor.ammo_fuel = 0;
								actor.hook_state |= HOOK_REMOVING;
								W_SwitchWeapon_Force(actor, w_getbestweapon(actor));
							}
						}
					}
				}
			}
			else
			{
				actor.hook_time_hooked = time;
				actor.hook_time_fueldecrease = time + WEP_CVAR_PRI(hook, hooked_time_free);
			}

			actor.hook_state = BITSET(actor.hook_state, HOOK_PULLING, (!actor.BUTTON_CROUCH || !autocvar_g_balance_grapplehook_crouchslide));

			if (actor.hook_state & HOOK_FIRING)
			{
				if (actor.hook)
					RemoveGrapplingHook(actor);
				WITH(entity, self, actor, FireGrapplingHook());
				actor.hook_state &= ~HOOK_FIRING;
				actor.hook_refire = max(actor.hook_refire, time + autocvar_g_balance_grapplehook_refire * W_WeaponRateFactor());
			}
			else if (actor.hook_state & HOOK_REMOVING)
			{
				if (actor.hook)
					RemoveGrapplingHook(actor);
				actor.hook_state &= ~HOOK_REMOVING;
			}
		}
		METHOD(Hook, wr_init, void(entity thiswep))
		{
			HOOK_SETTINGS(WEP_SKIP_CVAR, WEP_SET_PROP);
		}
		METHOD(Hook, wr_setup, void(entity thiswep))
		{
			self.hook_state &= ~HOOK_WAITING_FOR_RELEASE;
		}
		METHOD(Hook, wr_checkammo1, bool(Hook thiswep))
		{
			if (!thiswep.ammo_factor) return true;
			if(self.hook)
				return self.ammo_fuel > 0;
			else
				return self.ammo_fuel >= WEP_CVAR_PRI(hook, ammo);
		}
		METHOD(Hook, wr_checkammo2, bool(Hook thiswep))
		{
			// infinite ammo for now
			return true; // self.ammo_cells >= WEP_CVAR_SEC(hook, ammo); // WEAPONTODO: see above
		}
		METHOD(Hook, wr_config, void(entity thiswep))
		{
			HOOK_SETTINGS(WEP_CONFIG_WRITE_CVARS, WEP_CONFIG_WRITE_PROPS);
		}
		METHOD(Hook, wr_resetplayer, void(entity thiswep))
		{
			self.hook_refire = time;
		}
		METHOD(Hook, wr_suicidemessage, int(entity thiswep))
		{
			return false;
		}
		METHOD(Hook, wr_killmessage, int(entity thiswep))
		{
			return WEAPON_HOOK_MURDER;
		}

#endif
#ifdef CSQC

		METHOD(Hook, wr_impacteffect, void(entity thiswep))
		{
			vector org2;
			org2 = w_org + w_backoff * 2;
			pointparticles(particleeffectnum(EFFECT_HOOK_EXPLODE), org2, '0 0 0', 1);
			if(!w_issilent)
				sound(self, CH_SHOTS, SND_HOOKBOMB_IMPACT, VOL_BASE, ATTN_NORM);
		}

#endif
#endif
