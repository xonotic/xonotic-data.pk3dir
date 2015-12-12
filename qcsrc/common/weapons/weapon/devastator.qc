#ifndef IMPLEMENTATION
CLASS(Devastator, Weapon)
/* ammotype  */ ATTRIB(Devastator, ammo_field, .int, ammo_rockets)
/* impulse   */ ATTRIB(Devastator, impulse, int, 9)
/* flags     */ ATTRIB(Devastator, spawnflags, int, WEP_FLAG_NORMAL | WEP_FLAG_RELOADABLE | WEP_FLAG_CANCLIMB | WEP_TYPE_SPLASH);
/* rating    */ ATTRIB(Devastator, bot_pickupbasevalue, float, BOT_PICKUP_RATING_HIGH);
/* color     */ ATTRIB(Devastator, wpcolor, vector, '1 1 0');
/* modelname */ ATTRIB(Devastator, mdl, string, "rl");
#ifndef MENUQC
/* model     */ ATTRIB(Devastator, m_model, Model, MDL_DEVASTATOR_ITEM);
#endif
/* crosshair */ ATTRIB(Devastator, w_crosshair, string, "gfx/crosshairrocketlauncher");
/* crosshair */ ATTRIB(Devastator, w_crosshair_size, float, 0.7);
/* wepimg    */ ATTRIB(Devastator, model2, string, "weaponrocketlauncher");
/* refname   */ ATTRIB(Devastator, netname, string, "devastator");
/* wepname   */ ATTRIB(Devastator, m_name, string, _("Devastator"));

#define X(BEGIN, P, END, class, prefix) \
	BEGIN(class) \
		P(class, prefix, ammo, float, NONE) \
        P(class, prefix, animtime, float, NONE) \
        P(class, prefix, damageforcescale, float, NONE) \
        P(class, prefix, damage, float, NONE) \
        P(class, prefix, detonatedelay, float, NONE) \
        P(class, prefix, edgedamage, float, NONE) \
        P(class, prefix, force, float, NONE) \
        P(class, prefix, guidedelay, float, NONE) \
        P(class, prefix, guidegoal, float, NONE) \
        P(class, prefix, guideratedelay, float, NONE) \
        P(class, prefix, guiderate, float, NONE) \
        P(class, prefix, guidestop, float, NONE) \
        P(class, prefix, health, float, NONE) \
        P(class, prefix, lifetime, float, NONE) \
        P(class, prefix, radius, float, NONE) \
        P(class, prefix, refire, float, NONE) \
		P(class, prefix, reload_ammo, float, NONE) \
		P(class, prefix, reload_time, float, NONE) \
        P(class, prefix, remote_damage, float, NONE) \
        P(class, prefix, remote_edgedamage, float, NONE) \
        P(class, prefix, remote_force, float, NONE) \
        P(class, prefix, remote_jump_damage, float, NONE) \
        P(class, prefix, remote_jump_radius, float, NONE) \
        P(class, prefix, remote_jump_velocity_z_add, float, NONE) \
        P(class, prefix, remote_jump_velocity_z_max, float, NONE) \
        P(class, prefix, remote_jump_velocity_z_min, float, NONE) \
        P(class, prefix, remote_radius, float, NONE) \
        P(class, prefix, speedaccel, float, NONE) \
        P(class, prefix, speedstart, float, NONE) \
        P(class, prefix, speed, float, NONE) \
		P(class, prefix, switchdelay_drop, float, NONE) \
		P(class, prefix, switchdelay_raise, float, NONE) \
		P(class, prefix, weaponreplace, string,NONE) \
		P(class, prefix, weaponstartoverride, float, NONE) \
		P(class, prefix, weaponstart, float, NONE) \
		P(class, prefix, weaponthrowable, float, NONE) \
	END()
	W_PROPS(X, Devastator, devastator)
#undef X

ENDCLASS(Devastator)
REGISTER_WEAPON(DEVASTATOR, devastator, NEW(Devastator));

#ifdef SVQC
.float rl_release;
.float rl_detonate_later;
#endif
#endif
#ifdef IMPLEMENTATION
#ifdef SVQC
spawnfunc(weapon_devastator) { weapon_defaultspawnfunc(this, WEP_DEVASTATOR); }
spawnfunc(weapon_rocketlauncher) { spawnfunc_weapon_devastator(this); }

.entity lastrocket;

void W_Devastator_Unregister()
{SELFPARAM();
	if(self.realowner && self.realowner.lastrocket == self)
	{
		self.realowner.lastrocket = world;
		// self.realowner.rl_release = 1;
	}
}

void W_Devastator_Explode()
{SELFPARAM();
	W_Devastator_Unregister();

	if(other.takedamage == DAMAGE_AIM)
		if(IS_PLAYER(other))
			if(DIFF_TEAM(self.realowner, other))
				if(other.deadflag == DEAD_NO)
					if(IsFlying(other))
						Send_Notification(NOTIF_ONE, self.realowner, MSG_ANNCE, ANNCE_ACHIEVEMENT_AIRSHOT);

	self.event_damage = func_null;
	self.takedamage = DAMAGE_NO;

	RadiusDamage(
		self,
		self.realowner,
		WEP_CVAR(devastator, damage),
		WEP_CVAR(devastator, edgedamage),
		WEP_CVAR(devastator, radius),
		world,
		world,
		WEP_CVAR(devastator, force),
		self.projectiledeathtype,
		other
	);

	Weapon thiswep = WEP_DEVASTATOR;
	if(PS(self.realowner).m_weapon == thiswep)
	{
		if(self.realowner.(thiswep.ammo_field) < WEP_CVAR(devastator, ammo))
		if(!(self.realowner.items & IT_UNLIMITED_WEAPON_AMMO))
		{
			self.realowner.cnt = WEP_DEVASTATOR.m_id;
			int slot = 0; // TODO: unhardcode
			ATTACK_FINISHED(self.realowner, slot) = time;
			PS(self.realowner).m_switchweapon = w_getbestweapon(self.realowner);
		}
	}
	remove(self);
}

void W_Devastator_DoRemoteExplode(.entity weaponentity)
{SELFPARAM();
	W_Devastator_Unregister();

	self.event_damage = func_null;
	self.takedamage = DAMAGE_NO;

	float handled_as_rocketjump = false;

	entity head = WarpZone_FindRadius(
		self.origin,
		WEP_CVAR(devastator, remote_jump_radius),
		false
	);

	while(head)
	{
		if(head.takedamage && (head == self.realowner))
		{
			float distance_to_head = vlen(self.origin - head.WarpZone_findradius_nearest);
			if(distance_to_head <= WEP_CVAR(devastator, remote_jump_radius))
			{
				// we handled this as a rocketjump :)
				handled_as_rocketjump = true;

				// modify velocity
				head.velocity_x *= 0.9;
				head.velocity_y *= 0.9;
				head.velocity_z = bound(
					WEP_CVAR(devastator, remote_jump_velocity_z_min),
					head.velocity.z + WEP_CVAR(devastator, remote_jump_velocity_z_add),
					WEP_CVAR(devastator, remote_jump_velocity_z_max)
				);

				// now do the damage
				RadiusDamage(
					self,
					head,
					WEP_CVAR(devastator, remote_jump_damage),
					WEP_CVAR(devastator, remote_jump_damage),
					WEP_CVAR(devastator, remote_jump_radius),
					world,
					head,
					0,
					self.projectiledeathtype | HITTYPE_BOUNCE,
					world
				);
				break;
			}
		}
		head = head.chain;
	}

	RadiusDamage(
		self,
		self.realowner,
		WEP_CVAR(devastator, remote_damage),
		WEP_CVAR(devastator, remote_edgedamage),
		WEP_CVAR(devastator, remote_radius),
		(handled_as_rocketjump ? head : world),
		world,
		WEP_CVAR(devastator, remote_force),
		self.projectiledeathtype | HITTYPE_BOUNCE,
		world
	);

	Weapon thiswep = WEP_DEVASTATOR;
	if(PS(self.realowner).m_weapon == thiswep)
	{
		if(self.realowner.(thiswep.ammo_field) < WEP_CVAR(devastator, ammo))
		if(!(self.realowner.items & IT_UNLIMITED_WEAPON_AMMO))
		{
			self.realowner.cnt = WEP_DEVASTATOR.m_id;
			int slot = weaponslot(weaponentity);
			ATTACK_FINISHED(self.realowner, slot) = time;
			PS(self.realowner).m_switchweapon = w_getbestweapon(self.realowner);
		}
	}
	remove(self);
}

void W_Devastator_RemoteExplode(.entity weaponentity)
{SELFPARAM();
	if(self.realowner.deadflag == DEAD_NO)
	if(self.realowner.lastrocket)
	{
		if((self.spawnshieldtime >= 0)
			? (time >= self.spawnshieldtime) // timer
			: (vlen(NearestPointOnBox(self.realowner, self.origin) - self.origin) > WEP_CVAR(devastator, remote_radius)) // safety device
		)
		{
			W_Devastator_DoRemoteExplode(weaponentity);
		}
	}
}

vector W_Devastator_SteerTo(vector thisdir, vector goaldir, float maxturn_cos)
{
	if(thisdir * goaldir > maxturn_cos)
		return goaldir;
	if(thisdir * goaldir < -0.9998) // less than 1 degree and opposite
		return thisdir; // refuse to guide (better than letting a numerical error happen)
	float f, m2;
	vector v;
	// solve:
	//   g = normalize(thisdir + goaldir * X)
	//   thisdir * g = maxturn
	//
	//   gg = thisdir + goaldir * X
	//   (thisdir * gg)^2 = maxturn^2 * (gg * gg)
	//
	//   (1 + (thisdir * goaldir) * X)^2 = maxturn^2 * (1 + X*X + 2 * X * thisdir * goaldir)
	f = thisdir * goaldir;
	//   (1 + f * X)^2 = maxturn^2 * (1 + X*X + 2 * X * f)
	//   0 = (m^2 - f^2) * x^2 + (2 * f * (m^2 - 1)) * x + (m^2 - 1)
	m2 = maxturn_cos * maxturn_cos;
	v = solve_quadratic(m2 - f * f, 2 * f * (m2 - 1), m2 - 1);
	return normalize(thisdir + goaldir * v.y); // the larger solution!
}
// assume thisdir == -goaldir:
//   f == -1
//   v = solve_qadratic(m2 - 1, -2 * (m2 - 1), m2 - 1)
//   (m2 - 1) x^2 - 2 * (m2 - 1) * x + (m2 - 1) = 0
//   x^2 - 2 * x + 1 = 0
//   (x - 1)^2 = 0
//   x = 1
//   normalize(thisdir + goaldir)
//   normalize(0)

void W_Devastator_Think()
{SELFPARAM();
	vector desireddir, olddir, newdir, desiredorigin, goal;
	float velspeed, f;
	self.nextthink = time;
	if(time > self.cnt)
	{
		other = world;
		self.projectiledeathtype |= HITTYPE_BOUNCE;
		W_Devastator_Explode();
		return;
	}

	// accelerate
	makevectors(self.angles.x * '-1 0 0' + self.angles.y * '0 1 0');
	velspeed = WEP_CVAR(devastator, speed) * W_WeaponSpeedFactor() - (self.velocity * v_forward);
	if(velspeed > 0)
		self.velocity = self.velocity + v_forward * min(WEP_CVAR(devastator, speedaccel) * W_WeaponSpeedFactor() * frametime, velspeed);

	// laser guided, or remote detonation
	if(PS(self.realowner).m_weapon == WEP_DEVASTATOR)
	{
		if(self == self.realowner.lastrocket)
		if(!self.realowner.rl_release)
		if(!self.BUTTON_ATCK2)
		if(WEP_CVAR(devastator, guiderate))
		if(time > self.pushltime)
		if(self.realowner.deadflag == DEAD_NO)
		{
			f = WEP_CVAR(devastator, guideratedelay);
			if(f)
				f = bound(0, (time - self.pushltime) / f, 1);
			else
				f = 1;

			velspeed = vlen(self.velocity);

			makevectors(self.realowner.v_angle);
			desireddir = WarpZone_RefSys_TransformVelocity(self.realowner, self, v_forward);
			desiredorigin = WarpZone_RefSys_TransformOrigin(self.realowner, self, self.realowner.origin + self.realowner.view_ofs);
			olddir = normalize(self.velocity);

			// now it gets tricky... we want to move like some curve to approximate the target direction
			// but we are limiting the rate at which we can turn!
			goal = desiredorigin + ((self.origin - desiredorigin) * desireddir + WEP_CVAR(devastator, guidegoal)) * desireddir;
			newdir = W_Devastator_SteerTo(olddir, normalize(goal - self.origin), cos(WEP_CVAR(devastator, guiderate) * f * frametime * DEG2RAD));

			self.velocity = newdir * velspeed;
			self.angles = vectoangles(self.velocity);

			if(!self.count)
			{
				Send_Effect(EFFECT_ROCKET_GUIDE, self.origin, self.velocity, 1);
				// TODO add a better sound here
				sound(self.realowner, CH_WEAPON_B, SND_ROCKET_MODE, VOL_BASE, ATTN_NORM);
				self.count = 1;
			}
		}

		.entity weaponentity = weaponentities[0]; // TODO: unhardcode
		if(self.rl_detonate_later)
			W_Devastator_RemoteExplode(weaponentity);
	}

	if(self.csqcprojectile_clientanimate == 0)
		UpdateCSQCProjectile(self);
}

void W_Devastator_Touch()
{SELFPARAM();
	if(WarpZone_Projectile_Touch())
	{
		if(wasfreed(self))
			W_Devastator_Unregister();
		return;
	}
	W_Devastator_Unregister();
	W_Devastator_Explode();
}

void W_Devastator_Damage(entity inflictor, entity attacker, float damage, int deathtype, vector hitloc, vector force)
{SELFPARAM();
	if(self.health <= 0)
		return;

	if(!W_CheckProjectileDamage(inflictor.realowner, self.realowner, deathtype, -1)) // no exceptions
		return; // g_projectiles_damage says to halt

	self.health = self.health - damage;
	self.angles = vectoangles(self.velocity);

	if(self.health <= 0)
		W_PrepareExplosionByDamage(attacker, W_Devastator_Explode);
}

void W_Devastator_Attack(Weapon thiswep)
{SELFPARAM();
	entity missile;
	entity flash;

	W_DecreaseAmmo(thiswep, self, WEP_CVAR(devastator, ammo));

	W_SetupShot_ProjectileSize(self, '-3 -3 -3', '3 3 3', false, 5, SND(ROCKET_FIRE), CH_WEAPON_A, WEP_CVAR(devastator, damage));
	Send_Effect(EFFECT_ROCKET_MUZZLEFLASH, w_shotorg, w_shotdir * 1000, 1);

	missile = WarpZone_RefSys_SpawnSameRefSys(self);
	missile.owner = missile.realowner = self;
	self.lastrocket = missile;
	if(WEP_CVAR(devastator, detonatedelay) >= 0)
		missile.spawnshieldtime = time + WEP_CVAR(devastator, detonatedelay);
	else
		missile.spawnshieldtime = -1;
	missile.pushltime = time + WEP_CVAR(devastator, guidedelay);
	missile.classname = "rocket";
	missile.bot_dodge = true;
	missile.bot_dodgerating = WEP_CVAR(devastator, damage) * 2; // * 2 because it can be detonated inflight which makes it even more dangerous

	missile.takedamage = DAMAGE_YES;
	missile.damageforcescale = WEP_CVAR(devastator, damageforcescale);
	missile.health = WEP_CVAR(devastator, health);
	missile.event_damage = W_Devastator_Damage;
	missile.damagedbycontents = true;

	missile.movetype = MOVETYPE_FLY;
	PROJECTILE_MAKETRIGGER(missile);
	missile.projectiledeathtype = WEP_DEVASTATOR.m_id;
	setsize(missile, '-3 -3 -3', '3 3 3'); // give it some size so it can be shot

	setorigin(missile, w_shotorg - v_forward * 3); // move it back so it hits the wall at the right point
	W_SetupProjVelocity_Basic(missile, WEP_CVAR(devastator, speedstart), 0);
	missile.angles = vectoangles(missile.velocity);

	missile.touch = W_Devastator_Touch;
	missile.think = W_Devastator_Think;
	missile.nextthink = time;
	missile.cnt = time + WEP_CVAR(devastator, lifetime);
	missile.flags = FL_PROJECTILE;
	missile.missile_flags = MIF_SPLASH;

	CSQCProjectile(missile, WEP_CVAR(devastator, guiderate) == 0 && WEP_CVAR(devastator, speedaccel) == 0, PROJECTILE_ROCKET, false); // because of fly sound

	// muzzle flash for 1st person view
	flash = spawn();
	setmodel(flash, MDL_DEVASTATOR_MUZZLEFLASH); // precision set below
	SUB_SetFade(flash, time, 0.1);
	flash.effects = EF_ADDITIVE | EF_FULLBRIGHT | EF_LOWPRECISION;
	W_AttachToShotorg(self, flash, '5 0 0');

	// common properties
	MUTATOR_CALLHOOK(EditProjectile, self, missile);
}

		#if 0
		METHOD(Devastator, wr_aim, void(entity thiswep))
		{
			// aim and decide to fire if appropriate
			self.BUTTON_ATCK = bot_aim(WEP_CVAR(devastator, speed), 0, WEP_CVAR(devastator, lifetime), false);
			if(skill >= 2) // skill 0 and 1 bots won't detonate rockets!
			{
				// decide whether to detonate rockets
				entity missile, targetlist, targ;
				targetlist = findchainfloat(bot_attack, true);
				for(missile = world; (missile = find(missile, classname, "rocket")); ) if(missile.realowner == self)
				{
					targ = targetlist;
					while(targ)
					{
						if(targ != missile.realowner && vlen(targ.origin - missile.origin) < WEP_CVAR(devastator, radius))
						{
							self.BUTTON_ATCK2 = true;
							break;
						}
						targ = targ.chain;
					}
				}

				if(self.BUTTON_ATCK2) self.BUTTON_ATCK = false;
			}
		}
		#else
		METHOD(Devastator, wr_aim, void(entity thiswep))
		{
			// aim and decide to fire if appropriate
			self.BUTTON_ATCK = bot_aim(WEP_CVAR(devastator, speed), 0, WEP_CVAR(devastator, lifetime), false);
			if(skill >= 2) // skill 0 and 1 bots won't detonate rockets!
			{
				// decide whether to detonate rockets
				entity missile, targetlist, targ;
				float edgedamage, coredamage, edgeradius, recipricoledgeradius, d;
				float selfdamage, teamdamage, enemydamage;
				edgedamage = WEP_CVAR(devastator, edgedamage);
				coredamage = WEP_CVAR(devastator, damage);
				edgeradius = WEP_CVAR(devastator, radius);
				recipricoledgeradius = 1 / edgeradius;
				selfdamage = 0;
				teamdamage = 0;
				enemydamage = 0;
				targetlist = findchainfloat(bot_attack, true);
				missile = find(world, classname, "rocket");
				while(missile)
				{
					if(missile.realowner != self)
					{
						missile = find(missile, classname, "rocket");
						continue;
					}
					targ = targetlist;
					while(targ)
					{
						d = vlen(targ.origin + (targ.mins + targ.maxs) * 0.5 - missile.origin);
						d = bound(0, edgedamage + (coredamage - edgedamage) * sqrt(1 - d * recipricoledgeradius), 10000);
						// count potential damage according to type of target
						if(targ == self)
							selfdamage = selfdamage + d;
						else if(targ.team == self.team && teamplay)
							teamdamage = teamdamage + d;
						else if(bot_shouldattack(targ))
							enemydamage = enemydamage + d;
						targ = targ.chain;
					}
					missile = find(missile, classname, "rocket");
				}
				float desirabledamage;
				desirabledamage = enemydamage;
				if(time > self.invincible_finished && time > self.spawnshieldtime)
					desirabledamage = desirabledamage - selfdamage * autocvar_g_balance_selfdamagepercent;
				if(teamplay && self.team)
					desirabledamage = desirabledamage - teamdamage;

				missile = find(world, classname, "rocket");
				while(missile)
				{
					if(missile.realowner != self)
					{
						missile = find(missile, classname, "rocket");
						continue;
					}
					makevectors(missile.v_angle);
					targ = targetlist;
					if(skill > 9) // normal players only do this for the target they are tracking
					{
						targ = targetlist;
						while(targ)
						{
							if(
								(v_forward * normalize(missile.origin - targ.origin)< 0.1)
								&& desirabledamage > 0.1*coredamage
							)self.BUTTON_ATCK2 = true;
							targ = targ.chain;
						}
					}else{
						float distance; distance= bound(300,vlen(self.origin-self.enemy.origin),30000);
						//As the distance gets larger, a correct detonation gets near imposible
						//Bots are assumed to use the rocket spawnfunc_light to see if the rocket gets near a player
						if(v_forward * normalize(missile.origin - self.enemy.origin)< 0.1)
							if(IS_PLAYER(self.enemy))
								if(desirabledamage >= 0.1*coredamage)
									if(random()/distance*300 > frametime*bound(0,(10-skill)*0.2,1))
										self.BUTTON_ATCK2 = true;
					//	dprint(ftos(random()/distance*300),">");dprint(ftos(frametime*bound(0,(10-skill)*0.2,1)),"\n");
					}

					missile = find(missile, classname, "rocket");
				}
				// if we would be doing at X percent of the core damage, detonate it
				// but don't fire a new shot at the same time!
				if(desirabledamage >= 0.75 * coredamage) //this should do group damage in rare fortunate events
					self.BUTTON_ATCK2 = true;
				if((skill > 6.5) && (selfdamage > self.health))
					self.BUTTON_ATCK2 = false;
				//if(self.BUTTON_ATCK2 == true)
				//	dprint(ftos(desirabledamage),"\n");
				if(self.BUTTON_ATCK2 == true) self.BUTTON_ATCK = false;
			}
		}
		#endif
		METHOD(Devastator, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
		{
			if(WEP_CVAR(devastator, reload_ammo) && actor.clip_load < WEP_CVAR(devastator, ammo)) { // forced reload
				thiswep.wr_reload(thiswep);
			} else {
				if(fire & 1)
				{
					if(actor.rl_release || WEP_CVAR(devastator, guidestop))
					if(weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR(devastator, refire)))
					{
						W_Devastator_Attack(thiswep);
						weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR(devastator, animtime), w_ready);
						actor.rl_release = 0;
					}
				}
				else
					actor.rl_release = 1;

				if(fire & 2)
				if(PS(actor).m_switchweapon == WEP_DEVASTATOR)
				{
					entity rock;
					bool rockfound = false;
					for(rock = world; (rock = find(rock, classname, "rocket")); ) if(rock.realowner == actor)
					{
						if(!rock.rl_detonate_later)
						{
							rock.rl_detonate_later = true;
							rockfound = true;
						}
					}
					if(rockfound)
						sound(actor, CH_WEAPON_B, SND_ROCKET_DET, VOL_BASE, ATTN_NORM);
				}
			}
		}
		METHOD(Devastator, wr_setup, void(entity thiswep))
		{
			self.rl_release = 1;
		}
		METHOD(Devastator, wr_checkammo1, bool(entity thiswep))
		{
			#if 0
			// don't switch while guiding a missile
			if(ATTACK_FINISHED(self, slot) <= time || PS(self).m_weapon != WEP_DEVASTATOR)
			{
				ammo_amount = false;
				if(WEP_CVAR(devastator, reload_ammo))
				{
					if(self.(thiswep.ammo_field) < WEP_CVAR(devastator, ammo) && self.(weapon_load[WEP_DEVASTATOR.m_id]) < WEP_CVAR(devastator, ammo))
						ammo_amount = true;
				}
				else if(self.(thiswep.ammo_field) < WEP_CVAR(devastator, ammo))
					ammo_amount = true;
				return !ammo_amount;
			}
			#endif
			#if 0
			if(self.rl_release == 0)
			{
				LOG_INFOF("W_Devastator(WR_CHECKAMMO1): %d, %.2f, %d: TRUE\n", self.rl_release, self.(thiswep.ammo_field), WEP_CVAR(devastator, ammo));
				return true;
			}
			else
			{
				ammo_amount = self.(thiswep.ammo_field) >= WEP_CVAR(devastator, ammo);
				ammo_amount += self.(weapon_load[WEP_DEVASTATOR.m_id]) >= WEP_CVAR(devastator, ammo);
				LOG_INFOF("W_Devastator(WR_CHECKAMMO1): %d, %.2f, %d: %s\n", self.rl_release, self.(thiswep.ammo_field), WEP_CVAR(devastator, ammo), (ammo_amount ? "TRUE" : "FALSE"));
				return ammo_amount;
			}
			#else
			float ammo_amount = self.(thiswep.ammo_field) >= WEP_CVAR(devastator, ammo);
			ammo_amount += self.(weapon_load[WEP_DEVASTATOR.m_id]) >= WEP_CVAR(devastator, ammo);
			return ammo_amount;
			#endif
		}
		METHOD(Devastator, wr_checkammo2, bool(entity thiswep))
		{
			return false;
		}
		METHOD(Devastator, wr_resetplayer, void(entity thiswep))
		{
			self.lastrocket = NULL; // stop rocket guiding, no revenge from the grave!
			self.rl_release = 0;
		}
		METHOD(Devastator, wr_reload, void(entity thiswep))
		{
			W_Reload(self, WEP_CVAR(devastator, ammo), SND(RELOAD));
		}
		METHOD(Devastator, wr_suicidemessage, int(entity thiswep))
		{
			return WEAPON_DEVASTATOR_SUICIDE;
		}
		METHOD(Devastator, wr_killmessage, int(entity thiswep))
		{
			if((w_deathtype & HITTYPE_BOUNCE) || (w_deathtype & HITTYPE_SPLASH))
				return WEAPON_DEVASTATOR_MURDER_SPLASH;
			else
				return WEAPON_DEVASTATOR_MURDER_DIRECT;
		}

#endif
#ifdef CSQC

		METHOD(Devastator, wr_impacteffect, void(entity thiswep))
		{
			vector org2;
			org2 = w_org + w_backoff * 12;
			pointparticles(EFFECT_ROCKET_EXPLODE, org2, '0 0 0', 1);
			if(!w_issilent)
				sound(self, CH_SHOTS, SND_ROCKET_IMPACT, VOL_BASE, ATTN_NORM);
		}

#endif
#endif
