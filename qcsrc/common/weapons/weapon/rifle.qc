#ifndef IMPLEMENTATION
CLASS(Rifle, Weapon)
/* ammotype  */ ATTRIB(Rifle, ammo_field, .int, ammo_nails)
/* impulse   */ ATTRIB(Rifle, impulse, int, 7)
/* flags     */ ATTRIB(Rifle, spawnflags, int, WEP_FLAG_MUTATORBLOCKED | WEP_FLAG_RELOADABLE | WEP_TYPE_HITSCAN);
/* rating    */ ATTRIB(Rifle, bot_pickupbasevalue, float, BOT_PICKUP_RATING_MID);
/* color     */ ATTRIB(Rifle, wpcolor, vector, '0.5 1 0');
/* modelname */ ATTRIB(Rifle, mdl, string, "campingrifle");
#ifndef MENUQC
/* model     */ ATTRIB(Rifle, m_model, Model, MDL_RIFLE_ITEM);
#endif
/* crosshair */ ATTRIB(Rifle, w_crosshair, string, "gfx/crosshairrifle");
/* crosshair */ ATTRIB(Rifle, w_crosshair_size, float, 0.6);
/* wepimg    */ ATTRIB(Rifle, model2, string, "weaponrifle");
/* refname   */ ATTRIB(Rifle, netname, string, "rifle");
/* wepname   */ ATTRIB(Rifle, message, string, _("Rifle"));
ENDCLASS(Rifle)
REGISTER_WEAPON(RIFLE, NEW(Rifle));

#define RIFLE_SETTINGS(w_cvar,w_prop) RIFLE_SETTINGS_LIST(w_cvar, w_prop, RIFLE, rifle)
#define RIFLE_SETTINGS_LIST(w_cvar,w_prop,id,sn) \
	w_cvar(id, sn, BOTH, ammo) \
	w_cvar(id, sn, BOTH, animtime) \
	w_cvar(id, sn, BOTH, bullethail) \
	w_cvar(id, sn, BOTH, burstcost) \
	w_cvar(id, sn, BOTH, damage) \
	w_cvar(id, sn, BOTH, force) \
	w_cvar(id, sn, BOTH, refire) \
	w_cvar(id, sn, BOTH, shots) \
	w_cvar(id, sn, BOTH, solidpenetration) \
	w_cvar(id, sn, BOTH, spread) \
	w_cvar(id, sn, BOTH, tracer) \
	w_cvar(id, sn, NONE, bursttime) \
	w_cvar(id, sn, NONE, secondary) \
	w_cvar(id, sn, SEC,  reload) \
	w_prop(id, sn, float,  reloading_ammo, reload_ammo) \
	w_prop(id, sn, float,  reloading_time, reload_time) \
	w_prop(id, sn, float,  switchdelay_raise, switchdelay_raise) \
	w_prop(id, sn, float,  switchdelay_drop, switchdelay_drop) \
	w_prop(id, sn, string, weaponreplace, weaponreplace) \
	w_prop(id, sn, float,  weaponstart, weaponstart) \
	w_prop(id, sn, float,  weaponstartoverride, weaponstartoverride) \
	w_prop(id, sn, float,  weaponthrowable, weaponthrowable)

#ifdef SVQC
RIFLE_SETTINGS(WEP_ADD_CVAR, WEP_ADD_PROP)
.float rifle_accumulator;
#endif
#endif
#ifdef IMPLEMENTATION
#ifdef SVQC
void spawnfunc_weapon_rifle(void) { weapon_defaultspawnfunc(WEP_RIFLE.m_id); }
void spawnfunc_weapon_campingrifle(void) { spawnfunc_weapon_rifle(); }
void spawnfunc_weapon_sniperrifle(void) { spawnfunc_weapon_rifle(); }

void W_Rifle_FireBullet(Weapon thiswep, float pSpread, float pDamage, float pForce, float pSolidPenetration, float pAmmo, int deathtype, float pTracer, float pShots, string pSound)
{SELFPARAM();
	float i;

	W_DecreaseAmmo(thiswep, pAmmo);

	W_SetupShot(self, true, 2, pSound, CH_WEAPON_A, pDamage * pShots);

	Send_Effect(EFFECT_RIFLE_MUZZLEFLASH, w_shotorg, w_shotdir * 2000, 1);

	if(self.BUTTON_ZOOM | self.BUTTON_ZOOMSCRIPT) // if zoomed, shoot from the eye
	{
		w_shotdir = v_forward;
		w_shotorg = self.origin + self.view_ofs + ((w_shotorg - self.origin - self.view_ofs) * v_forward) * v_forward;
	}

	for(i = 0; i < pShots; ++i)
		fireBullet(w_shotorg, w_shotdir, pSpread, pSolidPenetration, pDamage, pForce, deathtype, (pTracer ? EF_RED : EF_BLUE));

	if(autocvar_g_casings >= 2)
		SpawnCasing(((random() * 50 + 50) * v_right) - (v_forward * (random() * 25 + 25)) - ((random() * 5 - 70) * v_up), 2, vectoangles(v_forward),'0 250 0', 100, 3, self);
}

void W_Rifle_Attack(void)
{
	W_Rifle_FireBullet(WEP_RIFLE, WEP_CVAR_PRI(rifle, spread), WEP_CVAR_PRI(rifle, damage), WEP_CVAR_PRI(rifle, force), WEP_CVAR_PRI(rifle, solidpenetration), WEP_CVAR_PRI(rifle, ammo), WEP_RIFLE.m_id, WEP_CVAR_PRI(rifle, tracer), WEP_CVAR_PRI(rifle, shots), SND(CAMPINGRIFLE_FIRE));
}

void W_Rifle_Attack2(void)
{
	W_Rifle_FireBullet(WEP_RIFLE, WEP_CVAR_SEC(rifle, spread), WEP_CVAR_SEC(rifle, damage), WEP_CVAR_SEC(rifle, force), WEP_CVAR_SEC(rifle, solidpenetration), WEP_CVAR_SEC(rifle, ammo), WEP_RIFLE.m_id | HITTYPE_SECONDARY, WEP_CVAR_SEC(rifle, tracer), WEP_CVAR_SEC(rifle, shots), SND(CAMPINGRIFLE_FIRE2));
}

.void(void) rifle_bullethail_attackfunc;
.float rifle_bullethail_frame;
.float rifle_bullethail_animtime;
.float rifle_bullethail_refire;
void W_Rifle_BulletHail_Continue(Weapon thiswep, bool fire1, bool fire2)
{SELFPARAM();
	float r, sw, af;

	sw = self.switchweapon; // make it not detect weapon changes as reason to abort firing
	af = ATTACK_FINISHED(self);
	self.switchweapon = self.weapon;
	ATTACK_FINISHED(self) = time;
	LOG_INFO(ftos(self.WEP_AMMO(RIFLE)), "\n");
	r = weapon_prepareattack(self.rifle_bullethail_frame == WFRAME_FIRE2, self.rifle_bullethail_refire);
	if(self.switchweapon == self.weapon)
		self.switchweapon = sw;
	if(r)
	{
		self.rifle_bullethail_attackfunc();
		weapon_thinkf(self.rifle_bullethail_frame, self.rifle_bullethail_animtime, W_Rifle_BulletHail_Continue);
		LOG_INFO("thinkf set\n");
	}
	else
	{
		ATTACK_FINISHED(self) = af; // reset attack_finished if we didn't fire, so the last shot enforces the refire time
		LOG_INFO("out of ammo... ", ftos(self.weaponentity.state), "\n");
	}
}

void W_Rifle_BulletHail(float mode, void(void) AttackFunc, float fr, float animtime, float refire)
{SELFPARAM();
	// if we get here, we have at least one bullet to fire
	AttackFunc();
	if(mode)
	{
		// continue hail
		self.rifle_bullethail_attackfunc = AttackFunc;
		self.rifle_bullethail_frame = fr;
		self.rifle_bullethail_animtime = animtime;
		self.rifle_bullethail_refire = refire;
		weapon_thinkf(fr, animtime, W_Rifle_BulletHail_Continue);
	}
	else
	{
		// just one shot
		weapon_thinkf(fr, animtime, w_ready);
	}
}

.float bot_secondary_riflemooth;

		METHOD(Rifle, wr_aim, bool(entity thiswep))
		{
			self.BUTTON_ATCK=false;
			self.BUTTON_ATCK2=false;
			if(vlen(self.origin-self.enemy.origin) > 1000)
				self.bot_secondary_riflemooth = 0;
			if(self.bot_secondary_riflemooth == 0)
			{
				if(bot_aim(1000000, 0, 0.001, false))
				{
					self.BUTTON_ATCK = true;
					if(random() < 0.01) self.bot_secondary_riflemooth = 1;
				}
			}
			else
			{
				if(bot_aim(1000000, 0, 0.001, false))
				{
					self.BUTTON_ATCK2 = true;
					if(random() < 0.03) self.bot_secondary_riflemooth = 0;
				}
			}

			return true;
		}
		METHOD(Rifle, wr_think, bool(entity thiswep, bool fire1, bool fire2))
		{
			if(autocvar_g_balance_rifle_reload_ammo && self.clip_load < min(WEP_CVAR_PRI(rifle, ammo), WEP_CVAR_SEC(rifle, ammo))) { // forced reload
				Weapon w = get_weaponinfo(self.weapon);
				w.wr_reload(w);
			} else
			{
				self.rifle_accumulator = bound(time - WEP_CVAR(rifle, bursttime), self.rifle_accumulator, time);
				if(fire1)
				if(weapon_prepareattack_check(false, WEP_CVAR_PRI(rifle, refire)))
				if(time >= self.rifle_accumulator + WEP_CVAR_PRI(rifle, burstcost))
				{
					weapon_prepareattack_do(false, WEP_CVAR_PRI(rifle, refire));
					W_Rifle_BulletHail(WEP_CVAR_PRI(rifle, bullethail), W_Rifle_Attack, WFRAME_FIRE1, WEP_CVAR_PRI(rifle, animtime), WEP_CVAR_PRI(rifle, refire));
					self.rifle_accumulator += WEP_CVAR_PRI(rifle, burstcost);
				}
				if(fire2)
				{
					if(WEP_CVAR(rifle, secondary))
					{
						if(WEP_CVAR_SEC(rifle, reload)) {
							Weapon w = get_weaponinfo(self.weapon);
							w.wr_reload(w);
						} else
						{
							if(weapon_prepareattack_check(true, WEP_CVAR_SEC(rifle, refire)))
							if(time >= self.rifle_accumulator + WEP_CVAR_SEC(rifle, burstcost))
							{
								weapon_prepareattack_do(true, WEP_CVAR_SEC(rifle, refire));
								W_Rifle_BulletHail(WEP_CVAR_SEC(rifle, bullethail), W_Rifle_Attack2, WFRAME_FIRE2, WEP_CVAR_SEC(rifle, animtime), WEP_CVAR_PRI(rifle, refire));
								self.rifle_accumulator += WEP_CVAR_SEC(rifle, burstcost);
							}
						}
					}
				}
			}

			return true;
		}
		METHOD(Rifle, wr_init, bool(entity thiswep))
		{
			RIFLE_SETTINGS(WEP_SKIP_CVAR, WEP_SET_PROP);
			return true;
		}
		METHOD(Rifle, wr_checkammo1, bool(entity thiswep))
		{
			float ammo_amount = self.WEP_AMMO(RIFLE) >= WEP_CVAR_PRI(rifle, ammo);
			ammo_amount += self.(weapon_load[WEP_RIFLE.m_id]) >= WEP_CVAR_PRI(rifle, ammo);
			return ammo_amount;
		}
		METHOD(Rifle, wr_checkammo2, bool(entity thiswep))
		{
			float ammo_amount = self.WEP_AMMO(RIFLE) >= WEP_CVAR_SEC(rifle, ammo);
			ammo_amount += self.(weapon_load[WEP_RIFLE.m_id]) >= WEP_CVAR_SEC(rifle, ammo);
			return ammo_amount;
		}
		METHOD(Rifle, wr_config, bool(entity thiswep))
		{
			RIFLE_SETTINGS(WEP_CONFIG_WRITE_CVARS, WEP_CONFIG_WRITE_PROPS);
			return true;
		}
		METHOD(Rifle, wr_resetplayer, bool(entity thiswep))
		{
			self.rifle_accumulator = time - WEP_CVAR(rifle, bursttime);
			return true;
		}
		METHOD(Rifle, wr_reload, bool(entity thiswep))
		{
			W_Reload(min(WEP_CVAR_PRI(rifle, ammo), WEP_CVAR_SEC(rifle, ammo)), SND(RELOAD));
			return true;
		}
		METHOD(Rifle, wr_suicidemessage, bool(entity thiswep))
		{
			return WEAPON_THINKING_WITH_PORTALS;
		}
		METHOD(Rifle, wr_killmessage, bool(entity thiswep))
		{
			if(w_deathtype & HITTYPE_SECONDARY)
			{
				if(w_deathtype & HITTYPE_BOUNCE)
					return WEAPON_RIFLE_MURDER_HAIL_PIERCING;
				else
					return WEAPON_RIFLE_MURDER_HAIL;
			}
			else
			{
				if(w_deathtype & HITTYPE_BOUNCE)
					return WEAPON_RIFLE_MURDER_PIERCING;
				else
					return WEAPON_RIFLE_MURDER;
			}
		}

#endif
#ifdef CSQC

		METHOD(Rifle, wr_impacteffect, bool(entity thiswep))
		{
			vector org2;
			org2 = w_org + w_backoff * 2;
			pointparticles(particleeffectnum(EFFECT_RIFLE_IMPACT), org2, w_backoff * 1000, 1);
			if(!w_issilent)
			{
				if(w_random < 0.2)
					sound(self, CH_SHOTS, SND_RIC1, VOL_BASE, ATTN_NORM);
				else if(w_random < 0.4)
					sound(self, CH_SHOTS, SND_RIC2, VOL_BASE, ATTN_NORM);
				else if(w_random < 0.5)
					sound(self, CH_SHOTS, SND_RIC3, VOL_BASE, ATTN_NORM);
			}

			return true;
		}
		METHOD(Rifle, wr_init, bool(entity thiswep))
		{
			if(autocvar_cl_reticle && autocvar_cl_reticle_weapon)
			{
				precache_pic("gfx/reticle_nex");
			}
			return true;
		}
		METHOD(Rifle, wr_zoomreticle, bool(entity thiswep))
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
