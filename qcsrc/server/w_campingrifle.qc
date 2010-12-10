#ifdef REGISTER_WEAPON
REGISTER_WEAPON(CAMPINGRIFLE, w_campingrifle, IT_NAILS, 7, WEP_FLAG_NORMAL | WEP_TYPE_HITSCAN, BOT_PICKUP_RATING_MID, "campingrifle", "campingrifle", "Sniper Rifle");
#else
#ifdef SVQC
//Camping rifle Primary mode: manually operated bolt*, Secondary: full automatic**
//* Manually operating the bolt means that all the power of the gas is used to propell the bullet. In this mode the bolt is prevented from moving backwards in response to the firing of the bullet.
//** In fully automatic mode some of the gas is used to extract and reload the next cartrige, thus there is less power and range.

.float campingrifle_accumulator;

float W_CampingRifle_CheckMaxBullets(float checkammo)
{
	float maxbulls;
	maxbulls = autocvar_g_balance_campingrifle_magazinecapacity;
	if(!maxbulls)
		maxbulls = 8; // match HUD
	if(checkammo)
		if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
			maxbulls = min(maxbulls, floor(self.ammo_nails / min(autocvar_g_balance_campingrifle_primary_ammo, autocvar_g_balance_campingrifle_secondary_ammo)));
	if(self.campingrifle_bulletcounter > maxbulls || !autocvar_g_balance_campingrifle_magazinecapacity)
		self.campingrifle_bulletcounter = maxbulls;
	return (self.campingrifle_bulletcounter == maxbulls);
}

void W_CampingRifle_ReloadedAndReady()
{
	float t;
	self.campingrifle_bulletcounter = autocvar_g_balance_campingrifle_magazinecapacity;
	W_CampingRifle_CheckMaxBullets(TRUE);
	t = ATTACK_FINISHED(self) - autocvar_g_balance_campingrifle_reloadtime - 1;
	ATTACK_FINISHED(self) = t;
	w_ready();
}

float W_CampingRifle_Reload()
{
	float t;

	W_CampingRifle_CheckMaxBullets(TRUE);

	if(self.ammo_nails < min(autocvar_g_balance_campingrifle_primary_ammo, autocvar_g_balance_campingrifle_secondary_ammo)) // when we get here, bulletcounter must be 0 or -1
	{
		print("cannot reload... not enough bullets\n");
		self.campingrifle_bulletcounter = -1; // reload later
		W_SwitchToOtherWeapon(self);
		return 0;
	}
	
	if (self.campingrifle_bulletcounter >= autocvar_g_balance_campingrifle_magazinecapacity)
		return 0;

	if (self.weaponentity)
	{
		if (self.weaponentity.wframe == WFRAME_RELOAD)
			return 0;

		// allow to switch away while reloading, but this will cause a new reload!
		self.weaponentity.state = WS_READY;
	}

	sound (self, CHAN_WEAPON2, "weapons/campingrifle_reload.wav", VOL_BASE, ATTN_NORM);

	t = max(time, ATTACK_FINISHED(self)) + autocvar_g_balance_campingrifle_reloadtime + 1;
	ATTACK_FINISHED(self) = t;

	weapon_thinkf(WFRAME_RELOAD, autocvar_g_balance_campingrifle_reloadtime, W_CampingRifle_ReloadedAndReady);

	self.campingrifle_bulletcounter = -1;

	return 1;
}

void W_CampingRifle_CheckReloadAndReady()
{
	w_ready();
	if(self.campingrifle_bulletcounter <= 0)
		if(W_CampingRifle_Reload())
			return;
}

void W_CampingRifle_FireBullet(float pSpread, float pDamage, float pHeadshotAddedDamage, float pForce, float pSpeed, float pLifetime, float pAmmo, float deathtype, float pBulletConstant)
{
	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
		self.ammo_nails -= pAmmo;

	if(deathtype & HITTYPE_SECONDARY)
		W_SetupShot (self, autocvar_g_antilag_bullets && pSpeed >= autocvar_g_antilag_bullets, 2, "weapons/campingrifle_fire2.wav", CHAN_WEAPON, autocvar_g_balance_campingrifle_secondary_damage + autocvar_g_balance_campingrifle_secondary_headshotaddeddamage);
	else
		W_SetupShot (self, autocvar_g_antilag_bullets && pSpeed >= autocvar_g_antilag_bullets, 2, "weapons/campingrifle_fire.wav", CHAN_WEAPON, autocvar_g_balance_campingrifle_primary_damage + autocvar_g_balance_campingrifle_primary_headshotaddeddamage);

	pointparticles(particleeffectnum("shotgun_muzzleflash"), w_shotorg, w_shotdir * 2000, 1);

	if(self.BUTTON_ZOOM) // if zoomed, shoot from the eye
	{
		w_shotdir = v_forward;
		w_shotorg = self.origin + self.view_ofs + ((w_shotorg - self.origin - self.view_ofs) * v_forward) * v_forward;
	}

	if(deathtype & HITTYPE_SECONDARY)
		fireBallisticBullet(w_shotorg, w_shotdir, pSpread, pSpeed, pLifetime, pDamage, pHeadshotAddedDamage / pDamage, pForce, deathtype, (autocvar_g_balance_campingrifle_secondary_tracer ? EF_RED : EF_BLUE), 1, pBulletConstant);
	else
		fireBallisticBullet(w_shotorg, w_shotdir, pSpread, pSpeed, pLifetime, pDamage, pHeadshotAddedDamage / pDamage, pForce, deathtype, (autocvar_g_balance_campingrifle_primary_tracer ? EF_RED : EF_BLUE), 1, pBulletConstant);
	endFireBallisticBullet();

	if (autocvar_g_casings >= 2)
		SpawnCasing (((random () * 50 + 50) * v_right) - (v_forward * (random () * 25 + 25)) - ((random () * 5 - 70) * v_up), 2, vectoangles(v_forward),'0 250 0', 100, 3, self);
	
	self.campingrifle_bulletcounter = self.campingrifle_bulletcounter - 1;
	W_CampingRifle_CheckMaxBullets(TRUE);
}

void W_CampingRifle_Attack()
{
	W_CampingRifle_FireBullet(autocvar_g_balance_campingrifle_primary_spread, autocvar_g_balance_campingrifle_primary_damage, autocvar_g_balance_campingrifle_primary_headshotaddeddamage, autocvar_g_balance_campingrifle_primary_force, autocvar_g_balance_campingrifle_primary_speed, autocvar_g_balance_campingrifle_primary_lifetime, autocvar_g_balance_campingrifle_primary_ammo, WEP_CAMPINGRIFLE, autocvar_g_balance_campingrifle_primary_bulletconstant);
}

void W_CampingRifle_Attack2()
{
	W_CampingRifle_FireBullet(autocvar_g_balance_campingrifle_secondary_spread, autocvar_g_balance_campingrifle_secondary_damage, autocvar_g_balance_campingrifle_secondary_headshotaddeddamage, autocvar_g_balance_campingrifle_secondary_force, autocvar_g_balance_campingrifle_secondary_speed, autocvar_g_balance_campingrifle_secondary_lifetime, autocvar_g_balance_campingrifle_secondary_ammo, WEP_CAMPINGRIFLE | HITTYPE_SECONDARY, autocvar_g_balance_campingrifle_secondary_bulletconstant);
}

void spawnfunc_weapon_campingrifle (void)
{
	weapon_defaultspawnfunc(WEP_CAMPINGRIFLE);
}

.void(void) campingrifle_bullethail_attackfunc;
.float campingrifle_bullethail_frame;
.float campingrifle_bullethail_animtime;
.float campingrifle_bullethail_refire;
void W_CampingRifle_BulletHail_Continue()
{
	float r, sw, af;
	W_CampingRifle_CheckReloadAndReady();
	if(self.campingrifle_bulletcounter < 0)
		return; // reloading, so we are done
	sw = self.switchweapon; // make it not detect weapon changes as reason to abort firing
	af = ATTACK_FINISHED(self);
	self.switchweapon = self.weapon;
	ATTACK_FINISHED(self) = time;
	print(ftos(self.ammo_nails), "\n");
	r = weapon_prepareattack(self.campingrifle_bullethail_frame == WFRAME_FIRE2, self.campingrifle_bullethail_refire);
	if(self.switchweapon == self.weapon)
		self.switchweapon = sw;
	if(r)
	{
		self.campingrifle_bullethail_attackfunc();
		weapon_thinkf(self.campingrifle_bullethail_frame, self.campingrifle_bullethail_animtime, W_CampingRifle_BulletHail_Continue);
		print("thinkf set\n");
	}
	else
	{
		ATTACK_FINISHED(self) = af; // reset attack_finished if we didn't fire, so the last shot enforces the refire time
		print("out of ammo... ", ftos(self.weaponentity.state), "\n");
	}
}

void W_CampingRifle_BulletHail(float mode, void(void) AttackFunc, float fr, float animtime, float refire)
{
	// if we get here, we have at least one bullet to fire
	AttackFunc();
	if(mode)
	{
		// continue hail
		self.campingrifle_bullethail_attackfunc = AttackFunc;
		self.campingrifle_bullethail_frame = fr;
		self.campingrifle_bullethail_animtime = animtime;
		self.campingrifle_bullethail_refire = refire;
		weapon_thinkf(fr, animtime, W_CampingRifle_BulletHail_Continue);
	}
	else
	{
		// just one shot
		weapon_thinkf(fr, animtime, W_CampingRifle_CheckReloadAndReady);
	}
}

.float bot_secondary_campingriflemooth;
float w_campingrifle(float req)
{
	float full;
	if (req == WR_AIM)
	{
		self.BUTTON_ATCK=FALSE;
		self.BUTTON_ATCK2=FALSE;
		if(vlen(self.origin-self.enemy.origin) > 1000)
			self.bot_secondary_campingriflemooth = 0;
		if(self.bot_secondary_campingriflemooth == 0)
		{
			if(bot_aim(autocvar_g_balance_campingrifle_primary_speed, 0, autocvar_g_balance_campingrifle_primary_lifetime, TRUE))
			{
				self.BUTTON_ATCK = TRUE;
				if(random() < 0.01) self.bot_secondary_campingriflemooth = 1;
			}
		}
		else
		{
			if(bot_aim(autocvar_g_balance_campingrifle_secondary_speed, 0, autocvar_g_balance_campingrifle_secondary_lifetime, TRUE))
			{
				self.BUTTON_ATCK2 = TRUE;
				if(random() < 0.03) self.bot_secondary_campingriflemooth = 0;
			}
		}
	}
	else if (req == WR_THINK)
	{
		if(self.campingrifle_bulletcounter < 0) // forced reload (e.g. because interrupted)
		{
			if(self.switchweapon == self.weapon)
			if(self.weaponentity.state == WS_READY)
				W_CampingRifle_Reload();
		}
		else
		{
			self.campingrifle_accumulator = bound(time - autocvar_g_balance_campingrifle_bursttime, self.campingrifle_accumulator, time);
			if (self.BUTTON_ATCK)
			if (weapon_prepareattack_check(0, autocvar_g_balance_campingrifle_primary_refire))
			if (time >= self.campingrifle_accumulator + autocvar_g_balance_campingrifle_primary_burstcost)
			{
				weapon_prepareattack_do(0, autocvar_g_balance_campingrifle_primary_refire);
				W_CampingRifle_BulletHail(autocvar_g_balance_campingrifle_primary_bullethail, W_CampingRifle_Attack, WFRAME_FIRE1, autocvar_g_balance_campingrifle_primary_animtime, autocvar_g_balance_campingrifle_primary_refire);
				self.campingrifle_accumulator += autocvar_g_balance_campingrifle_primary_burstcost;
			}
			if (self.BUTTON_ATCK2)
			{	
				if (autocvar_g_balance_campingrifle_secondary)
				{
					if (weapon_prepareattack_check(1, autocvar_g_balance_campingrifle_secondary_refire))
					if (time >= self.campingrifle_accumulator + autocvar_g_balance_campingrifle_secondary_burstcost)
					{
						weapon_prepareattack_do(1, autocvar_g_balance_campingrifle_secondary_refire);
						W_CampingRifle_BulletHail(autocvar_g_balance_campingrifle_secondary_bullethail, W_CampingRifle_Attack2, WFRAME_FIRE2, autocvar_g_balance_campingrifle_secondary_animtime, autocvar_g_balance_campingrifle_primary_refire);
						self.campingrifle_accumulator += autocvar_g_balance_campingrifle_secondary_burstcost;
					}
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
		weapon_setup(WEP_CAMPINGRIFLE);

		full = W_CampingRifle_CheckMaxBullets(TRUE);
		if(autocvar_g_balance_campingrifle_auto_reload_on_switch)
			if(!full)
				self.campingrifle_bulletcounter = -1;
	}
	else if (req == WR_CHECKAMMO1)
		return self.ammo_nails >= autocvar_g_balance_campingrifle_primary_ammo;
	else if (req == WR_CHECKAMMO2)
		return self.ammo_nails >= autocvar_g_balance_campingrifle_secondary_ammo;
	else if (req == WR_RELOAD)
	{
		W_CampingRifle_Reload();
	}
	else if (req == WR_RESETPLAYER)
	{
		self.campingrifle_accumulator = time - autocvar_g_balance_campingrifle_bursttime;
		self.campingrifle_bulletcounter = autocvar_g_balance_campingrifle_magazinecapacity;
		W_CampingRifle_CheckMaxBullets(FALSE);
	}
	return TRUE;
};
#endif
#ifdef CSQC
float w_campingrifle(float req)
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
