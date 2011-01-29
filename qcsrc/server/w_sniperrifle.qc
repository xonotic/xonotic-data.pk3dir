#ifdef REGISTER_WEAPON
REGISTER_WEAPON(SNIPERRIFLE, w_sniperrifle, IT_NAILS, 7, WEP_FLAG_NORMAL | WEP_TYPE_HITSCAN, BOT_PICKUP_RATING_MID, "campingrifle", "sniperrifle", _("Sniper Rifle"))
#else
#ifdef SVQC
//Sniper rifle Primary mode: manually operated bolt*, Secondary: full automatic**
//* Manually operating the bolt means that all the power of the gas is used to propell the bullet. In this mode the bolt is prevented from moving backwards in response to the firing of the bullet.
//** In fully automatic mode some of the gas is used to extract and reload the next cartrige, thus there is less power and range.

.float sniperrifle_accumulator;

float W_SniperRifle_CheckMaxBullets(float checkammo)
{
	float maxbulls;
	maxbulls = autocvar_g_balance_sniperrifle_magazinecapacity;
	if(!maxbulls)
		maxbulls = 8; // match HUD
	if(checkammo)
		if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
			maxbulls = min(maxbulls, floor(self.ammo_nails / min(autocvar_g_balance_sniperrifle_primary_ammo, autocvar_g_balance_sniperrifle_secondary_ammo)));
	if(self.sniperrifle_bulletcounter > maxbulls || !autocvar_g_balance_sniperrifle_magazinecapacity)
		self.sniperrifle_bulletcounter = maxbulls;
	return (self.sniperrifle_bulletcounter == maxbulls);
}

void W_SniperRifle_ReloadedAndReady()
{
	float t;
	self.sniperrifle_bulletcounter = autocvar_g_balance_sniperrifle_magazinecapacity;
	W_SniperRifle_CheckMaxBullets(TRUE);
	t = ATTACK_FINISHED(self) - autocvar_g_balance_sniperrifle_reloadtime - 1;
	ATTACK_FINISHED(self) = t;
	w_ready();
}

float W_SniperRifle_Reload()
{
	float t;

	W_SniperRifle_CheckMaxBullets(TRUE);

	if(self.ammo_nails < min(autocvar_g_balance_sniperrifle_primary_ammo, autocvar_g_balance_sniperrifle_secondary_ammo)) // when we get here, bulletcounter must be 0 or -1
	{
		print("cannot reload... not enough bullets\n");
		self.sniperrifle_bulletcounter = -1; // reload later
		W_SwitchToOtherWeapon(self);
		return 0;
	}
	
	if (self.sniperrifle_bulletcounter >= autocvar_g_balance_sniperrifle_magazinecapacity)
		return 0;

	if (self.weaponentity)
	{
		if (self.weaponentity.wframe == WFRAME_RELOAD)
			return 0;

		// allow to switch away while reloading, but this will cause a new reload!
		self.weaponentity.state = WS_READY;
	}

	sound (self, CHAN_WEAPON2, "weapons/campingrifle_reload.wav", VOL_BASE, ATTN_NORM);

	t = max(time, ATTACK_FINISHED(self)) + autocvar_g_balance_sniperrifle_reloadtime + 1;
	ATTACK_FINISHED(self) = t;

	weapon_thinkf(WFRAME_RELOAD, autocvar_g_balance_sniperrifle_reloadtime, W_SniperRifle_ReloadedAndReady);

	self.sniperrifle_bulletcounter = -1;

	return 1;
}

void W_SniperRifle_CheckReloadAndReady()
{
	w_ready();
	if(self.sniperrifle_bulletcounter <= 0)
		if(W_SniperRifle_Reload())
			return;
}

void W_SniperRifle_FireBullet(float pSpread, float pDamage, float pHeadshotAddedDamage, float pForce, float pSpeed, float pLifetime, float pAmmo, float deathtype, float pBulletConstant)
{
	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
		self.ammo_nails -= pAmmo;

	if(deathtype & HITTYPE_SECONDARY)
		W_SetupShot (self, autocvar_g_antilag_bullets && pSpeed >= autocvar_g_antilag_bullets, 2, "weapons/campingrifle_fire2.wav", CHAN_WEAPON, autocvar_g_balance_sniperrifle_secondary_damage + autocvar_g_balance_sniperrifle_secondary_headshotaddeddamage);
	else
		W_SetupShot (self, autocvar_g_antilag_bullets && pSpeed >= autocvar_g_antilag_bullets, 2, "weapons/campingrifle_fire.wav", CHAN_WEAPON, autocvar_g_balance_sniperrifle_primary_damage + autocvar_g_balance_sniperrifle_primary_headshotaddeddamage);

	pointparticles(particleeffectnum("shotgun_muzzleflash"), w_shotorg, w_shotdir * 2000, 1);

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
	
	self.sniperrifle_bulletcounter = self.sniperrifle_bulletcounter - 1;
	W_SniperRifle_CheckMaxBullets(TRUE);
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
	W_SniperRifle_CheckReloadAndReady();
	if(self.sniperrifle_bulletcounter < 0)
		return; // reloading, so we are done
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
		weapon_thinkf(fr, animtime, W_SniperRifle_CheckReloadAndReady);
	}
}

.float bot_secondary_sniperriflemooth;
float w_sniperrifle(float req)
{
	float full;
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
		if(self.sniperrifle_bulletcounter < 0) // forced reload (e.g. because interrupted)
		{
            self.wish_reload = 1;
		}
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
                        self.wish_reload = 1;
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
		precache_sound ("weapons/campingrifle_reload.wav");
		precache_sound ("weapons/campingrifle_fire.wav");
		precache_sound ("weapons/campingrifle_fire2.wav");
	}
	else if (req == WR_SETUP)
	{
		weapon_setup(WEP_SNIPERRIFLE);

		full = W_SniperRifle_CheckMaxBullets(TRUE);
		if(autocvar_g_balance_sniperrifle_auto_reload_on_switch)
			if(!full)
				self.sniperrifle_bulletcounter = -1;
	}
	else if (req == WR_CHECKAMMO1)
		return self.ammo_nails >= autocvar_g_balance_sniperrifle_primary_ammo;
	else if (req == WR_CHECKAMMO2)
		return self.ammo_nails >= autocvar_g_balance_sniperrifle_secondary_ammo;
	else if (req == WR_RELOAD)
	{
        self.wish_reload = 1;
	}
	else if (req == WR_RESETPLAYER)
	{
		self.sniperrifle_accumulator = time - autocvar_g_balance_sniperrifle_bursttime;
		self.sniperrifle_bulletcounter = autocvar_g_balance_sniperrifle_magazinecapacity;
		W_SniperRifle_CheckMaxBullets(FALSE);
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
			w_deathtypestring = _("%s shot themself automatically");
		else
			w_deathtypestring = _("%s sniped themself somehow");
	}
	else if (req == WR_KILLMESSAGE)
	{
		if(w_deathtype & HITTYPE_SECONDARY)
		{
			if(w_deathtype & HITTYPE_BOUNCE)
				w_deathtypestring = _("%s failed to hide from %s's bullet hail");
			else
				w_deathtypestring = _("%s died in %s's bullet hail");
		}
		else
		{
			if(w_deathtype & HITTYPE_BOUNCE)
			{
				// TODO special headshot message here too?
				w_deathtypestring = _("%s failed to hide from %s's rifle");
			}
			else
			{
				if(w_deathtype & HITTYPE_HEADSHOT)
					w_deathtypestring = _("%s got hit in the head by %s");
				else
					w_deathtypestring = _("%s was sniped by %s");
			}
		}
	}
	return TRUE;
}
#endif
#endif
