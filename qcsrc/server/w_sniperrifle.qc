#ifdef REGISTER_WEAPON
REGISTER_WEAPON(SNIPERRIFLE, w_sniperrifle, IT_NAILS, 7, WEP_FLAG_NORMAL | WEP_TYPE_HITSCAN, BOT_PICKUP_RATING_MID, "campingrifle", "sniperrifle", _("Sniper Rifle"))
#else
#ifdef SVQC
//Sniper rifle Primary mode: manually operated bolt*, Secondary: full automatic**
//* Manually operating the bolt means that all the power of the gas is used to propell the bullet. In this mode the bolt is prevented from moving backwards in response to the firing of the bullet.
//** In fully automatic mode some of the gas is used to extract and reload the next cartrige, thus there is less power and range.

.float sniperrifle_accumulator;
.float sniperrifle_load;

void W_SniperRifle_SetAmmoCounter()
{
	// set clip_load to the weapon we have switched to, if the gun uses reloading
	if(!autocvar_g_balance_sniperrifle_reload_ammo)
		self.clip_load = 0; // also keeps crosshair ammo from displaying
	else
	{
		self.clip_load = self.sniperrifle_load;
		self.clip_size = autocvar_g_balance_sniperrifle_reload_ammo; // for the crosshair ammo display
	}
}

void W_SniperRifle_ReloadedAndReady()
{
	float t;

	// now do the ammo transfer
	self.clip_load = self.old_clip_load; // restore the ammo counter, in case we still had ammo in the weapon before reloading
	while(self.clip_load < autocvar_g_balance_sniperrifle_reload_ammo && self.ammo_nails) // make sure we don't add more ammo than we have
	{
		self.clip_load += 1;
		self.ammo_nails -= 1;
	}
	self.sniperrifle_load = self.clip_load;

	t = ATTACK_FINISHED(self) - autocvar_g_balance_sniperrifle_reload_time - 1;
	ATTACK_FINISHED(self) = t;
	w_ready();
}

void W_SniperRifle_Reload()
{
	// return if reloading is disabled for this weapon
	if(!autocvar_g_balance_sniperrifle_reload_ammo)
		return;

	if(!W_ReloadCheck(self.ammo_nails, min(autocvar_g_balance_sniperrifle_primary_ammo, autocvar_g_balance_sniperrifle_secondary_ammo)))
		return;

	float t;

	sound (self, CHAN_WEAPON2, "weapons/reload.wav", VOL_BASE, ATTN_NORM);

	t = max(time, ATTACK_FINISHED(self)) + autocvar_g_balance_sniperrifle_reload_time + 1;
	ATTACK_FINISHED(self) = t;

	weapon_thinkf(WFRAME_RELOAD, autocvar_g_balance_sniperrifle_reload_time, W_SniperRifle_ReloadedAndReady);

	self.old_clip_load = self.clip_load;
	self.clip_load = -1;
}

void W_SniperRifle_FireBullet(float pSpread, float pDamage, float pHeadshotAddedDamage, float pForce, float pSpeed, float pLifetime, float pAmmo, float deathtype, float pBulletConstant)
{
	// if there's not enough ammo for this attack (but we still have the weapon), reload
	if(autocvar_g_balance_sniperrifle_reload_ammo && self.clip_load < autocvar_g_balance_sniperrifle_primary_ammo)
	{
		W_SniperRifle_Reload();
		return;
	}

	// if this weapon is reloadable, decrease its load. Else decrease the player's ammo
	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
	{
		if(autocvar_g_balance_sniperrifle_reload_ammo)
		{
			self.clip_load -= pAmmo;
			self.sniperrifle_load = self.clip_load;
		}
		else
			self.ammo_nails -= pAmmo;
	}

	if(deathtype & HITTYPE_SECONDARY)
		W_SetupShot (self, autocvar_g_antilag_bullets && pSpeed >= autocvar_g_antilag_bullets, 2, "weapons/campingrifle_fire2.wav", CHAN_WEAPON, autocvar_g_balance_sniperrifle_secondary_damage + autocvar_g_balance_sniperrifle_secondary_headshotaddeddamage);
	else
		W_SetupShot (self, autocvar_g_antilag_bullets && pSpeed >= autocvar_g_antilag_bullets, 2, "weapons/campingrifle_fire.wav", CHAN_WEAPON, autocvar_g_balance_sniperrifle_primary_damage + autocvar_g_balance_sniperrifle_primary_headshotaddeddamage);

	pointparticles(particleeffectnum("sniperrifle_muzzleflash"), w_shotorg, w_shotdir * 2000, 1);

	if(self.BUTTON_ZOOM) // if zoomed, shoot from the eye
	{
		w_shotdir = v_forward;
		w_shotorg = self.origin + self.view_ofs + ((w_shotorg - self.origin - self.view_ofs) * v_forward) * v_forward;
	}

	if(deathtype & HITTYPE_SECONDARY)
		fireBallisticBullet(w_shotorg, w_shotdir, pSpread, pSpeed, pLifetime, pDamage, pHeadshotAddedDamage / pDamage, pForce, deathtype, (autocvar_g_balance_sniperrifle_secondary_tracer ? EF_RED : EF_BLUE), 1, pBulletConstant);
	else
		fireBallisticBullet(w_shotorg, w_shotdir, pSpread, pSpeed, pLifetime, pDamage, pHeadshotAddedDamage / pDamage, pForce, deathtype, (autocvar_g_balance_sniperrifle_primary_tracer ? EF_RED : EF_BLUE), 1, pBulletConstant);
	endFireBallisticBullet();

	if (autocvar_g_casings >= 2)
		SpawnCasing (((random () * 50 + 50) * v_right) - (v_forward * (random () * 25 + 25)) - ((random () * 5 - 70) * v_up), 2, vectoangles(v_forward),'0 250 0', 100, 3, self);
}

void W_SniperRifle_Attack()
{
	W_SniperRifle_FireBullet(autocvar_g_balance_sniperrifle_primary_spread, autocvar_g_balance_sniperrifle_primary_damage, autocvar_g_balance_sniperrifle_primary_headshotaddeddamage, autocvar_g_balance_sniperrifle_primary_force, autocvar_g_balance_sniperrifle_primary_speed, autocvar_g_balance_sniperrifle_primary_lifetime, autocvar_g_balance_sniperrifle_primary_ammo, WEP_SNIPERRIFLE, autocvar_g_balance_sniperrifle_primary_bulletconstant);
}

void W_SniperRifle_Attack2()
{
	W_SniperRifle_FireBullet(autocvar_g_balance_sniperrifle_secondary_spread, autocvar_g_balance_sniperrifle_secondary_damage, autocvar_g_balance_sniperrifle_secondary_headshotaddeddamage, autocvar_g_balance_sniperrifle_secondary_force, autocvar_g_balance_sniperrifle_secondary_speed, autocvar_g_balance_sniperrifle_secondary_lifetime, autocvar_g_balance_sniperrifle_secondary_ammo, WEP_SNIPERRIFLE | HITTYPE_SECONDARY, autocvar_g_balance_sniperrifle_secondary_bulletconstant);
}

void spawnfunc_weapon_sniperrifle (void)
{
	weapon_defaultspawnfunc(WEP_SNIPERRIFLE);
}

// compatibility alias
void spawnfunc_weapon_campingrifle (void)
{
	spawnfunc_weapon_sniperrifle();
}

.void(void) sniperrifle_bullethail_attackfunc;
.float sniperrifle_bullethail_frame;
.float sniperrifle_bullethail_animtime;
.float sniperrifle_bullethail_refire;
void W_SniperRifle_BulletHail_Continue()
{
	float r, sw, af;

	sw = self.switchweapon; // make it not detect weapon changes as reason to abort firing
	af = ATTACK_FINISHED(self);
	self.switchweapon = self.weapon;
	ATTACK_FINISHED(self) = time;
	print(ftos(self.ammo_nails), "\n");
	r = weapon_prepareattack(self.sniperrifle_bullethail_frame == WFRAME_FIRE2, self.sniperrifle_bullethail_refire);
	if(self.switchweapon == self.weapon)
		self.switchweapon = sw;
	if(r)
	{
		self.sniperrifle_bullethail_attackfunc();
		weapon_thinkf(self.sniperrifle_bullethail_frame, self.sniperrifle_bullethail_animtime, W_SniperRifle_BulletHail_Continue);
		print("thinkf set\n");
	}
	else
	{
		ATTACK_FINISHED(self) = af; // reset attack_finished if we didn't fire, so the last shot enforces the refire time
		print("out of ammo... ", ftos(self.weaponentity.state), "\n");
	}
}

void W_SniperRifle_BulletHail(float mode, void(void) AttackFunc, float fr, float animtime, float refire)
{
	// if we get here, we have at least one bullet to fire
	AttackFunc();
	if(mode)
	{
		// continue hail
		self.sniperrifle_bullethail_attackfunc = AttackFunc;
		self.sniperrifle_bullethail_frame = fr;
		self.sniperrifle_bullethail_animtime = animtime;
		self.sniperrifle_bullethail_refire = refire;
		weapon_thinkf(fr, animtime, W_SniperRifle_BulletHail_Continue);
	}
	else
	{
		// just one shot
		weapon_thinkf(fr, animtime, w_ready);
	}
}

.float bot_secondary_sniperriflemooth;
float w_sniperrifle(float req)
{
	if (req == WR_AIM)
	{
		self.BUTTON_ATCK=FALSE;
		self.BUTTON_ATCK2=FALSE;
		if(vlen(self.origin-self.enemy.origin) > 1000)
			self.bot_secondary_sniperriflemooth = 0;
		if(self.bot_secondary_sniperriflemooth == 0)
		{
			if(bot_aim(autocvar_g_balance_sniperrifle_primary_speed, 0, autocvar_g_balance_sniperrifle_primary_lifetime, TRUE))
			{
				self.BUTTON_ATCK = TRUE;
				if(random() < 0.01) self.bot_secondary_sniperriflemooth = 1;
			}
		}
		else
		{
			if(bot_aim(autocvar_g_balance_sniperrifle_secondary_speed, 0, autocvar_g_balance_sniperrifle_secondary_lifetime, TRUE))
			{
				self.BUTTON_ATCK2 = TRUE;
				if(random() < 0.03) self.bot_secondary_sniperriflemooth = 0;
			}
		}
	}
	else if (req == WR_THINK)
	{
		if(autocvar_g_balance_sniperrifle_reload_ammo && self.clip_load < min(autocvar_g_balance_sniperrifle_primary_ammo, autocvar_g_balance_sniperrifle_secondary_ammo)) // forced reload
            W_SniperRifle_Reload();
		else
		{
			self.sniperrifle_accumulator = bound(time - autocvar_g_balance_sniperrifle_bursttime, self.sniperrifle_accumulator, time);
			if (self.BUTTON_ATCK)
			if (weapon_prepareattack_check(0, autocvar_g_balance_sniperrifle_primary_refire))
			if (time >= self.sniperrifle_accumulator + autocvar_g_balance_sniperrifle_primary_burstcost)
			{
				weapon_prepareattack_do(0, autocvar_g_balance_sniperrifle_primary_refire);
				W_SniperRifle_BulletHail(autocvar_g_balance_sniperrifle_primary_bullethail, W_SniperRifle_Attack, WFRAME_FIRE1, autocvar_g_balance_sniperrifle_primary_animtime, autocvar_g_balance_sniperrifle_primary_refire);
				self.sniperrifle_accumulator += autocvar_g_balance_sniperrifle_primary_burstcost;
			}
			if (self.BUTTON_ATCK2)
			{	
				if (autocvar_g_balance_sniperrifle_secondary)
				{
                    if(autocvar_g_balance_sniperrifle_secondary_reload)
                        W_SniperRifle_Reload();
                    else
                    {
                        if (weapon_prepareattack_check(1, autocvar_g_balance_sniperrifle_secondary_refire))
                        if (time >= self.sniperrifle_accumulator + autocvar_g_balance_sniperrifle_secondary_burstcost)
                        {
                            weapon_prepareattack_do(1, autocvar_g_balance_sniperrifle_secondary_refire);
                            W_SniperRifle_BulletHail(autocvar_g_balance_sniperrifle_secondary_bullethail, W_SniperRifle_Attack2, WFRAME_FIRE2, autocvar_g_balance_sniperrifle_secondary_animtime, autocvar_g_balance_sniperrifle_primary_refire);
                            self.sniperrifle_accumulator += autocvar_g_balance_sniperrifle_secondary_burstcost;
                        }
                    }
				}
			}
		}
        if(self.wish_reload)
        {
            if(self.switchweapon == self.weapon)
            {
                if(self.weaponentity.state == WS_READY)
                {
                    self.wish_reload = 0;
                    W_SniperRifle_Reload();
                }
            }
        }
	}
	else if (req == WR_PRECACHE)
	{
		precache_model ("models/weapons/g_campingrifle.md3");
		precache_model ("models/weapons/v_campingrifle.md3");
		precache_model ("models/weapons/h_campingrifle.iqm");
		precache_sound ("weapons/campingrifle_fire.wav");
		precache_sound ("weapons/campingrifle_fire2.wav");
		precache_sound ("weapons/reload.wav");
	}
	else if (req == WR_SETUP)
	{
		weapon_setup(WEP_SNIPERRIFLE);
		W_SniperRifle_SetAmmoCounter();
	}
	else if (req == WR_CHECKAMMO1)
	{
		if(autocvar_g_balance_sniperrifle_reload_ammo)
			return self.sniperrifle_load >= autocvar_g_balance_sniperrifle_primary_ammo;
		else
			return self.ammo_nails >= autocvar_g_balance_sniperrifle_primary_ammo;
	}
	else if (req == WR_CHECKAMMO2)
	{
		if(autocvar_g_balance_sniperrifle_reload_ammo)
			return self.sniperrifle_load >= autocvar_g_balance_sniperrifle_primary_ammo;
		else
			return self.ammo_nails >= autocvar_g_balance_sniperrifle_secondary_ammo;
	}
	else if (req == WR_RELOAD)
	{
		W_SniperRifle_Reload();
	}
	else if (req == WR_RESETPLAYER)
	{
		self.sniperrifle_accumulator = time - autocvar_g_balance_sniperrifle_bursttime;
		self.clip_load = autocvar_g_balance_sniperrifle_reload_ammo;
	}
	return TRUE;
};
#endif
#ifdef CSQC
float w_sniperrifle(float req)
{
	if(req == WR_IMPACTEFFECT)
	{
		vector org2;
		org2 = w_org + w_backoff * 2;
		pointparticles(particleeffectnum("machinegun_impact"), org2, w_backoff * 1000, 1);
		if(!w_issilent)
		{
			if(w_random < 0.2)
				sound(self, CHAN_PROJECTILE, "weapons/ric1.wav", VOL_BASE, ATTN_NORM);
			else if(w_random < 0.4)
				sound(self, CHAN_PROJECTILE, "weapons/ric2.wav", VOL_BASE, ATTN_NORM);
			else if(w_random < 0.5)
				sound(self, CHAN_PROJECTILE, "weapons/ric3.wav", VOL_BASE, ATTN_NORM);
		}
	}
	else if(req == WR_PRECACHE)
	{
		precache_sound("weapons/ric1.wav");
		precache_sound("weapons/ric2.wav");
		precache_sound("weapons/ric3.wav");
	}
	else if (req == WR_SUICIDEMESSAGE)
	{
		if(w_deathtype & HITTYPE_SECONDARY)
			w_deathtypestring = "%s shot themself automatically";
		else
			w_deathtypestring = "%s sniped themself somehow";
	}
	else if (req == WR_KILLMESSAGE)
	{
		if(w_deathtype & HITTYPE_SECONDARY)
		{
			if(w_deathtype & HITTYPE_BOUNCE)
				w_deathtypestring = "%s failed to hide from %s's bullet hail";
			else
				w_deathtypestring = "%s died in %s's bullet hail";
		}
		else
		{
			if(w_deathtype & HITTYPE_BOUNCE)
			{
				// TODO special headshot message here too?
				w_deathtypestring = "%s failed to hide from %s's rifle";
			}
			else
			{
				if(w_deathtype & HITTYPE_HEADSHOT)
					w_deathtypestring = "%s got hit in the head by %s";
				else
					w_deathtypestring = "%s was sniped by %s";
			}
		}
	}
	return TRUE;
}
#endif
#endif
