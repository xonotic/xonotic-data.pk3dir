#ifdef REGISTER_WEAPON
REGISTER_WEAPON(SNIPERRIFLE, w_sniperrifle, IT_NAILS, 7, WEP_FLAG_NORMAL | WEP_FLAG_RELOADABLE | WEP_TYPE_HITSCAN, BOT_PICKUP_RATING_MID, "campingrifle", "sniperrifle", _("Sniper Rifle"))
#else
#ifdef SVQC

.float sniperrifle_accumulator;

void W_SniperRifle_FireBullet(float pSpread, float pDamage, float pHeadshotAddedDamage, float pForce, float pSpeed, float pLifetime, float pAmmo, float deathtype, float pBulletConstant, float pTracer, float pShots, string pSound)
{
	float i;

	W_DecreaseAmmo(ammo_nails, pAmmo, autocvar_g_balance_sniperrifle_reload_ammo);

	W_SetupShot (self, autocvar_g_antilag_bullets && pSpeed >= autocvar_g_antilag_bullets, 2, pSound, CHAN_WEAPON, (pDamage + pHeadshotAddedDamage) * pShots);

	pointparticles(particleeffectnum("sniperrifle_muzzleflash"), w_shotorg, w_shotdir * 2000, 1);

	if(self.BUTTON_ZOOM) // if zoomed, shoot from the eye
	{
		w_shotdir = v_forward;
		w_shotorg = self.origin + self.view_ofs + ((w_shotorg - self.origin - self.view_ofs) * v_forward) * v_forward;
	}

	for(i = 0; i < pShots; ++i)
		fireBallisticBullet(w_shotorg, w_shotdir, pSpread, pSpeed, pLifetime, pDamage, pHeadshotAddedDamage / pDamage, pForce, deathtype, (pTracer ? EF_RED : EF_BLUE), 1, pBulletConstant);
	endFireBallisticBullet();

	if (autocvar_g_casings >= 2)
		SpawnCasing (((random () * 50 + 50) * v_right) - (v_forward * (random () * 25 + 25)) - ((random () * 5 - 70) * v_up), 2, vectoangles(v_forward),'0 250 0', 100, 3, self);
}

void W_SniperRifle_Attack()
{
	W_SniperRifle_FireBullet(autocvar_g_balance_sniperrifle_primary_spread, autocvar_g_balance_sniperrifle_primary_damage, autocvar_g_balance_sniperrifle_primary_headshotaddeddamage, autocvar_g_balance_sniperrifle_primary_force, autocvar_g_balance_sniperrifle_primary_speed, autocvar_g_balance_sniperrifle_primary_lifetime, autocvar_g_balance_sniperrifle_primary_ammo, WEP_SNIPERRIFLE, autocvar_g_balance_sniperrifle_primary_bulletconstant, autocvar_g_balance_sniperrifle_primary_tracer, autocvar_g_balance_sniperrifle_primary_shots, "weapons/campingrifle_fire.wav");
}

void W_SniperRifle_Attack2()
{
	W_SniperRifle_FireBullet(autocvar_g_balance_sniperrifle_secondary_spread, autocvar_g_balance_sniperrifle_secondary_damage, autocvar_g_balance_sniperrifle_secondary_headshotaddeddamage, autocvar_g_balance_sniperrifle_secondary_force, autocvar_g_balance_sniperrifle_secondary_speed, autocvar_g_balance_sniperrifle_secondary_lifetime, autocvar_g_balance_sniperrifle_secondary_ammo, WEP_SNIPERRIFLE | HITTYPE_SECONDARY, autocvar_g_balance_sniperrifle_secondary_bulletconstant, autocvar_g_balance_sniperrifle_secondary_tracer, autocvar_g_balance_sniperrifle_secondary_shots, "weapons/campingrifle_fire2.wav");
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
	float ammo_amount;

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
            weapon_action(self.weapon, WR_RELOAD);
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
                        weapon_action(self.weapon, WR_RELOAD);
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
	}
	else if (req == WR_PRECACHE)
	{
		precache_model ("models/weapons/g_campingrifle.md3");
		precache_model ("models/weapons/v_campingrifle.md3");
		precache_model ("models/weapons/h_campingrifle.iqm");
		precache_sound ("weapons/campingrifle_fire.wav");
		precache_sound ("weapons/campingrifle_fire2.wav");
		//precache_sound ("weapons/reload.wav"); // until weapons have individual reload sounds, precache the reload sound somewhere else
	}
	else if (req == WR_SETUP)
	{
		weapon_setup(WEP_SNIPERRIFLE);
		self.current_ammo = ammo_nails;
	}
	else if (req == WR_CHECKAMMO1)
	{
		ammo_amount = self.ammo_nails >= autocvar_g_balance_sniperrifle_primary_ammo;
		ammo_amount += self.weapon_load[WEP_SNIPERRIFLE] >= autocvar_g_balance_sniperrifle_primary_ammo;
		return ammo_amount;
	}
	else if (req == WR_CHECKAMMO2)
	{
		ammo_amount = self.ammo_nails >= autocvar_g_balance_sniperrifle_secondary_ammo;
		ammo_amount += self.weapon_load[WEP_SNIPERRIFLE] >= autocvar_g_balance_sniperrifle_secondary_ammo;
		return ammo_amount;
	}
	else if (req == WR_RESETPLAYER)
	{
		self.sniperrifle_accumulator = time - autocvar_g_balance_sniperrifle_bursttime;
	}
	else if (req == WR_RELOAD)
	{
		W_Reload(min(autocvar_g_balance_sniperrifle_primary_ammo, autocvar_g_balance_sniperrifle_secondary_ammo), autocvar_g_balance_sniperrifle_reload_ammo, autocvar_g_balance_sniperrifle_reload_time, "weapons/reload.wav");
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
