#ifdef REGISTER_WEAPON
REGISTER_WEAPON(MINE_LAYER, w_minelayer, IT_ROCKETS, 9, WEP_FLAG_NORMAL | WEP_TYPE_SPLASH, BOT_PICKUP_RATING_HIGH, "minelayer", "minelayer", "Mine Layer");
#else
#ifdef SVQC
.float rl_release;
.float rl_detonate_later;

void spawnfunc_weapon_minelayer (void)
{
	weapon_defaultspawnfunc(WEP_MINE_LAYER);
}

void W_Mine_Unregister()
{
	if(self.owner && self.owner.lastrocket == self)
	{
		self.owner.lastrocket = world;
		// self.owner.rl_release = 1;
	}
}

void W_Mine_Explode ()
{
	W_Mine_Unregister();

	if(other.takedamage == DAMAGE_AIM)
		if(other.classname == "player")
			if(IsDifferentTeam(self.owner, other))
				if(IsFlying(other))
					AnnounceTo(self.owner, "airshot");

	self.event_damage = SUB_Null;
	self.takedamage = DAMAGE_NO;

	RadiusDamage (self, self.owner, cvar("g_balance_minelayer_damage"), cvar("g_balance_minelayer_edgedamage"), cvar("g_balance_minelayer_radius"), world, cvar("g_balance_minelayer_force"), self.projectiledeathtype, other);

	if (self.owner.weapon == WEP_MINE_LAYER)
	{
		if(self.owner.ammo_rockets < cvar("g_balance_minelayer_ammo"))
		{
			self.owner.cnt = WEP_MINE_LAYER;
			ATTACK_FINISHED(self.owner) = time;
			self.owner.switchweapon = w_getbestweapon(self.owner);
		}
		if(g_laserguided_missile)
			ATTACK_FINISHED(self.owner) = time + cvar("g_balance_minelayer_refire") * W_WeaponRateFactor();
	}
	remove (self);
}

void W_Mine_DoRemoteExplode ()
{
	W_Mine_Unregister();

	self.event_damage = SUB_Null;
	self.takedamage = DAMAGE_NO;

	RadiusDamage (self, self.owner, cvar("g_balance_minelayer_remote_damage"), cvar("g_balance_minelayer_remote_edgedamage"), cvar("g_balance_minelayer_remote_radius"), world, cvar("g_balance_minelayer_remote_force"), self.projectiledeathtype | HITTYPE_BOUNCE, world);

	if (self.owner.weapon == WEP_MINE_LAYER)
	{
		if(self.owner.ammo_rockets < cvar("g_balance_minelayer_ammo"))
		{
			self.owner.cnt = WEP_MINE_LAYER;
			ATTACK_FINISHED(self.owner) = time;
			self.owner.switchweapon = w_getbestweapon(self.owner);
		}
		if(g_laserguided_missile)
			ATTACK_FINISHED(self.owner) = time + cvar("g_balance_minelayer_refire") * W_WeaponRateFactor();
	}
	remove (self);
}

void W_Mine_RemoteExplode()
{
	if(self.owner.deadflag == DEAD_NO)
	if(self.owner.lastrocket)
	{
		if((self.spawnshieldtime >= 0)
			? (time >= self.spawnshieldtime) // timer
			: (vlen(NearestPointOnBox(self.owner, self.origin) - self.origin) > cvar("g_balance_minelayer_radius")) // safety device
		)
		{
			W_Mine_DoRemoteExplode();
		}
	}
}

void W_Mine_Think (void)
{
	entity e;
	vector desireddir, olddir, newdir, desiredorigin, goal;
#if 0
	float cosminang, cosmaxang, cosang;
#endif
	float turnrate, velspeed, f;
	self.nextthink = time;
	if (time > self.cnt)
	{
		other = world;
		self.projectiledeathtype |= HITTYPE_BOUNCE;
		W_Mine_Explode ();
		return;
	}

	if(g_laserguided_missile)
	{
		// accelerate
		makevectors(self.angles_x * '-1 0 0' + self.angles_y * '0 1 0');
		velspeed = cvar("g_balance_minelayer_laserguided_speed") * g_weaponspeedfactor - (self.velocity * v_forward);
		if (velspeed > 0)
			self.velocity = self.velocity + v_forward * min(cvar("g_balance_minelayer_laserguided_speedaccel") * frametime, velspeed);
	}
	else
	{
		// accelerate
		makevectors(self.angles_x * '-1 0 0' + self.angles_y * '0 1 0');
		velspeed = cvar("g_balance_minelayer_speed") * g_weaponspeedfactor - (self.velocity * v_forward);
		if (velspeed > 0)
			self.velocity = self.velocity + v_forward * min(cvar("g_balance_minelayer_speedaccel") * g_weaponspeedfactor * frametime, velspeed);
	}

	// laser guided, or remote detonation
	if (self.owner.weapon == WEP_MINE_LAYER)
	{
		if(g_laserguided_missile)
		{
			if(self.rl_detonate_later)
				W_Mine_RemoteExplode();

			if(cvar("g_balance_minelayer_laserguided_allow_steal"))
			{
				if(self.owner.laser_on)
				{
					if(self.attack_finished_single < time)
					{
						self.attack_finished_single = time + 0.2 + random()*0.3;
						//self.enemy = FindLaserTarget(self, 0.7, 0.7);
					}

					if(!self.enemy)
						self.enemy = self.owner.weaponentity.lasertarget;
				}
				else self.enemy = world;
			}
			else // don't allow stealing: always target my owner's laser (if it exists)
				self.enemy = self.owner.weaponentity.lasertarget;

			if(self.enemy != world)
			{
				//bprint("Targeting ", self.enemy.owner.netname, "'s laser\n");
				velspeed = vlen(self.velocity);
				e = self.enemy;//self.owner.weaponentity.lasertarget;
				turnrate = cvar("g_balance_minelayer_laserguided_turnrate");//0.65;						// how fast to turn
				desireddir = normalize(e.origin - self.origin);		// get direction from my position to the laser target
				olddir = normalize(self.velocity);					// get my current direction
				newdir = normalize(olddir + desireddir * turnrate);	// take the average of the 2 directions; not the best method but simple & easy
				self.velocity = newdir * velspeed;					// make me fly in the new direction at my flight speed
				self.angles = vectoangles(self.velocity);			// turn model in the new flight direction

				ATTACK_FINISHED(self.owner) = time + 0.2 * W_WeaponRateFactor();
			}
		}
		else
		{
			if(self == self.owner.lastrocket)
			if not(self.owner.rl_release)
			if not(self.BUTTON_ATCK2)
			if(cvar("g_balance_minelayer_guiderate"))
			if(time > self.pushltime)
			if(self.owner.deadflag == DEAD_NO)
			{
				f = cvar("g_balance_minelayer_guideratedelay");
				if(f)
					f = bound(0, (time - self.pushltime) / f, 1);
				else
					f = 1;

				velspeed = vlen(self.velocity);

				makevectors(self.owner.v_angle);
				desireddir = WarpZone_RefSys_TransformVelocity(self.owner, self, v_forward);
				desiredorigin = WarpZone_RefSys_TransformOrigin(self.owner, self, self.owner.origin + self.owner.view_ofs);
				olddir = normalize(self.velocity);

#if 0
				// disabled this code because it doesn't do what I want it to do :P
				cosminang = cos(cvar("g_balance_minelayer_guidefadeangle") * DEG2RAD);
				cosmaxang = cos(cvar("g_balance_minelayer_guidemaxangle") * DEG2RAD);
				cosang = desireddir * normalize(self.origin - desiredorigin);
				if(cosminang == cosmaxang)
					f *= (cosang >= cosminang);
				else
					f *= bound(0, (cosang - cosmaxang) / (cosminang - cosmaxang), 1);
#endif

				if(!self.count)
				{
					pointparticles(particleeffectnum("rocket_guide"), self.origin, self.velocity, 1);
					// TODO add a better sound here
					sound (self.owner, CHAN_WEAPON2, "weapons/rocket_mode.wav", VOL_BASE, ATTN_NORM);
					self.count = 1;
				}
			}

			if(self.rl_detonate_later)
				W_Mine_RemoteExplode();
		}
	}

	if(self.csqcprojectile_clientanimate == 0)
		UpdateCSQCProjectile(self);
}

void W_Mine_Touch (void)
{
	W_Mine_Unregister();

	PROJECTILE_TOUCH;
	W_Mine_Explode ();
}

void W_Mine_Damage (entity inflictor, entity attacker, float damage, float deathtype, vector hitloc, vector force)
{
	if (self.health <= 0)
		return;
	self.health = self.health - damage;
	self.angles = vectoangles(self.velocity);
	if (self.health <= 0)
		W_PrepareExplosionByDamage(attacker, W_Mine_Explode);
}

void W_Mine_Attack (void)
{
	local entity missile;
	local entity flash;

	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
		self.ammo_rockets = self.ammo_rockets - cvar("g_balance_minelayer_ammo");

	W_SetupShot_ProjectileSize (self, '-3 -3 -3', '3 3 3', FALSE, 5, "weapons/rocket_fire.wav", cvar("g_balance_minelayer_damage"));
	pointparticles(particleeffectnum("minelayer_muzzleflash"), w_shotorg, w_shotdir * 1000, 1);

	missile = WarpZone_RefSys_SpawnSameRefSys(self);
	missile.owner = self;
	self.lastrocket = missile;
	if(cvar("g_balance_minelayer_detonatedelay") >= 0)
		missile.spawnshieldtime = time + cvar("g_balance_minelayer_detonatedelay");
	else
		missile.spawnshieldtime = -1;
	missile.pushltime = time + cvar("g_balance_minelayer_guidedelay");
	missile.classname = "rocket";
	missile.bot_dodge = TRUE;
	missile.bot_dodgerating = cvar("g_balance_minelayer_damage") * 2; // * 2 because it can be detonated inflight which makes it even more dangerous

	missile.takedamage = DAMAGE_YES;
	missile.damageforcescale = cvar("g_balance_minelayer_damageforcescale");
	missile.health = cvar("g_balance_minelayer_health");
	missile.event_damage = W_Mine_Damage;

	missile.movetype = MOVETYPE_FLY;
	PROJECTILE_MAKETRIGGER(missile);
	missile.projectiledeathtype = WEP_MINE_LAYER;
	setsize (missile, '-3 -3 -3', '3 3 3'); // give it some size so it can be shot

	setorigin (missile, w_shotorg - v_forward * 3); // move it back so it hits the wall at the right point
	if(g_laserguided_missile && self.laser_on)
		W_SetupProjectileVelocity(missile, cvar("g_balance_minelayer_laserguided_speedstart"), 0);
	else
		W_SetupProjectileVelocity(missile, cvar("g_balance_minelayer_speedstart"), 0);
	missile.angles = vectoangles (missile.velocity);

	missile.touch = W_Mine_Touch;
	missile.think = W_Mine_Think;
	missile.nextthink = time;
	missile.cnt = time + cvar("g_balance_minelayer_lifetime");
	missile.flags = FL_PROJECTILE;

	CSQCProjectile(missile, cvar("g_balance_minelayer_guiderate") == 0 && cvar("g_balance_minelayer_speedaccel") == 0 && !g_laserguided_missile, PROJECTILE_ROCKET, FALSE); // because of fly sound

	// muzzle flash for 1st person view
	flash = spawn ();
	setmodel (flash, "models/flash.md3"); // precision set below
	SUB_SetFade (flash, time, 0.1);
	flash.effects = EF_ADDITIVE | EF_FULLBRIGHT | EF_LOWPRECISION;
	W_AttachToShotorg(flash, '5 0 0');

	// common properties
}

void spawnfunc_weapon_minelayer (void); // defined in t_items.qc

float w_minelayer(float req)
{
	entity rock;
	float rockfound;
	if (req == WR_AIM)
	{
		// aim and decide to fire if appropriate
		self.BUTTON_ATCK = bot_aim(cvar("g_balance_minelayer_speed"), 0, cvar("g_balance_minelayer_lifetime"), FALSE);
		if(skill >= 2) // skill 0 and 1 bots won't detonate rockets!
		{
			// decide whether to detonate rockets
			local entity missile, targetlist, targ;
			local float edgedamage, coredamage, edgeradius, recipricoledgeradius, d;
			local float selfdamage, teamdamage, enemydamage;
			edgedamage = cvar("g_balance_minelayer_edgedamage");
			coredamage = cvar("g_balance_minelayer_damage");
			edgeradius = cvar("g_balance_minelayer_radius");
			recipricoledgeradius = 1 / edgeradius;
			selfdamage = 0;
			teamdamage = 0;
			enemydamage = 0;
			targetlist = findchainfloat(bot_attack, TRUE);
			missile = find(world, classname, "rocket");
			while (missile)
			{
				if (missile.owner != self)
				{
					missile = find(missile, classname, "rocket");
					continue;
				}
				targ = targetlist;
				while (targ)
				{
					d = vlen(targ.origin + (targ.mins + targ.maxs) * 0.5 - missile.origin);
					d = bound(0, edgedamage + (coredamage - edgedamage) * sqrt(1 - d * recipricoledgeradius), 10000);
					// count potential damage according to type of target
					if (targ == self)
						selfdamage = selfdamage + d;
					else if (targ.team == self.team && teams_matter)
						teamdamage = teamdamage + d;
					else if (bot_shouldattack(targ))
						enemydamage = enemydamage + d;
					targ = targ.chain;
				}
				missile = find(missile, classname, "rocket");
			}
			local float desirabledamage;
			desirabledamage = enemydamage;
			if (teamplay != 1 && time > self.invincible_finished && time > self.spawnshieldtime)
				desirabledamage = desirabledamage - selfdamage * cvar("g_balance_selfdamagepercent");
			if (self.team && teamplay != 1)
				desirabledamage = desirabledamage - teamdamage;

			missile = find(world, classname, "rocket");
			while (missile)
			{
				if (missile.owner != self)
				{
					missile = find(missile, classname, "rocket");
					continue;
				}
				makevectors(missile.v_angle);
				targ = targetlist;
				if (skill > 9) // normal players only do this for the target they are tracking
				{
					targ = targetlist;
					while (targ)
					{
						if (
							(v_forward * normalize(missile.origin - targ.origin)< 0.1)
							&& desirabledamage > 0.1*coredamage
						)self.BUTTON_ATCK2 = TRUE;
						targ = targ.chain;
					}
				}else{
					local float distance; distance= bound(300,vlen(self.origin-self.enemy.origin),30000);
					//As the distance gets larger, a correct detonation gets near imposible
					//Bots are assumed to use the rocket spawnfunc_light to see if the rocket gets near a player
					if(v_forward * normalize(missile.origin - self.enemy.origin)< 0.1)
						if(self.enemy.classname == "player")
							if(desirabledamage >= 0.1*coredamage)
								if(random()/distance*300 > frametime*bound(0,(10-skill)*0.2,1))
									self.BUTTON_ATCK2 = TRUE;
				//	dprint(ftos(random()/distance*300),">");dprint(ftos(frametime*bound(0,(10-skill)*0.2,1)),"\n");
				}

				missile = find(missile, classname, "rocket");
			}
			// if we would be doing at X percent of the core damage, detonate it
			// but don't fire a new shot at the same time!
			if (desirabledamage >= 0.75 * coredamage) //this should do group damage in rare fortunate events
				self.BUTTON_ATCK2 = TRUE;
			if ((skill > 6.5) && (selfdamage > self.health))
				self.BUTTON_ATCK2 = FALSE;
			//if(self.BUTTON_ATCK2 == TRUE)
			//	dprint(ftos(desirabledamage),"\n");
			if (self.BUTTON_ATCK2 == TRUE) self.BUTTON_ATCK = FALSE;
		}
	}
	else if (req == WR_THINK)
	{
		if(g_laserguided_missile)
		{
			if (self.BUTTON_ATCK && self.rl_release)
			{
				rockfound = 0;
				for(rock = world; (rock = find(rock, classname, "rocket")); ) if(rock.owner == self)
				{
					if(!rock.rl_detonate_later)
					{
						rock.rl_detonate_later = TRUE;
						rockfound = 1;
					}
				}
				if(rockfound)
					sound (self, CHAN_WEAPON2, "weapons/rocket_det.wav", VOL_BASE, ATTN_NORM);
				else
				{
					if (weapon_prepareattack(0, cvar("g_balance_minelayer_refire")))
					{
						W_Mine_Attack();
						weapon_thinkf(WFRAME_FIRE1, cvar("g_balance_minelayer_animtime"), w_ready);
					}
				}
				self.rl_release = 0;
			}
			if (!self.BUTTON_ATCK)
				self.rl_release = 1;
			if (self.BUTTON_ATCK2)
			if(self.exteriorweaponentity.attack_finished_single < time)
			{
				self.exteriorweaponentity.attack_finished_single = time + 0.4;
				self.laser_on = !self.laser_on;
				// UGLY WORKAROUND: play this on CHAN_WEAPON2 so it can't cut off fire sounds
				sound (self, CHAN_WEAPON2, "weapons/rocket_mode.wav", VOL_BASE, ATTN_NORM);
			}
		}
		else
		{
			if (self.BUTTON_ATCK)
			{
				if(self.rl_release || cvar("g_balance_minelayer_guidestop"))
				if(weapon_prepareattack(0, cvar("g_balance_minelayer_refire")))
				{
					W_Mine_Attack();
					weapon_thinkf(WFRAME_FIRE1, cvar("g_balance_minelayer_animtime"), w_ready);
					self.rl_release = 0;
				}
			}
			else
				self.rl_release = 1;

			if (self.BUTTON_ATCK2)
			{
				rockfound = 0;
				for(rock = world; (rock = find(rock, classname, "rocket")); ) if(rock.owner == self)
				{
					if(!rock.rl_detonate_later)
					{
						rock.rl_detonate_later = TRUE;
						rockfound = 1;
					}
				}
				if(rockfound)
					sound (self, CHAN_WEAPON2, "weapons/rocket_det.wav", VOL_BASE, ATTN_NORM);
			}
		}
	}
	else if (req == WR_PRECACHE)
	{
		precache_model ("models/flash.md3");
		precache_model ("models/weapons/g_rl.md3");
		precache_model ("models/weapons/v_rl.md3");
		precache_model ("models/weapons/h_rl.iqm");
		precache_sound ("weapons/rocket_det.wav");
		precache_sound ("weapons/rocket_fire.wav");
		precache_sound ("weapons/rocket_mode.wav");
		if (g_laserguided_missile)
		{
			precache_model ("models/laser_dot.mdl"); // mine layer
		}
	}
	else if (req == WR_SETUP)
	{
		weapon_setup(WEP_MINE_LAYER);
		self.rl_release = 1;
	}
	else if (req == WR_CHECKAMMO1)
	{
		// don't switch while guiding a missile
		if ((ATTACK_FINISHED(self) <= time || self.weapon != WEP_MINE_LAYER)
			&& self.ammo_rockets < cvar("g_balance_minelayer_ammo"))
			return FALSE;
	}
	else if (req == WR_CHECKAMMO2)
		return FALSE;
	else if (req == WR_RESETPLAYER)
	{
		self.rl_release = 0;
	}
	return TRUE;
};
#endif
#ifdef CSQC
float w_minelayer(float req)
{
	if(req == WR_IMPACTEFFECT)
	{
		vector org2;
		org2 = w_org + w_backoff * 12;
		pointparticles(particleeffectnum("rocket_explode"), org2, '0 0 0', 1);
		if(!w_issilent)
			sound(self, CHAN_PROJECTILE, "weapons/rocket_impact.wav", VOL_BASE, ATTN_NORM);
	}
	else if(req == WR_PRECACHE)
	{
		precache_sound("weapons/rocket_impact.wav");
	}
	else if (req == WR_SUICIDEMESSAGE)
		w_deathtypestring = "%s exploded";
	else if (req == WR_KILLMESSAGE)
	{
		if(w_deathtype & HITTYPE_BOUNCE) // (remote detonation)
			w_deathtypestring = "%s got too close to %s's rocket";
		else if(w_deathtype & HITTYPE_SPLASH)
			w_deathtypestring = "%s almost dodged %s's rocket";
		else
			w_deathtypestring = "%s ate %s's rocket";
	}
	return TRUE;
}
#endif
#endif
