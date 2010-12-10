#ifdef REGISTER_WEAPON
REGISTER_WEAPON(MINE_LAYER, w_minelayer, IT_ROCKETS, 4, WEP_FLAG_NORMAL | WEP_TYPE_SPLASH, BOT_PICKUP_RATING_HIGH, "minelayer", "minelayer", "Mine Layer");
#else
#ifdef SVQC
void W_Mine_Think (void);
.float minelayer_detonate, minelayer_mines;
.float mine_time;

void spawnfunc_weapon_minelayer (void)
{
	weapon_defaultspawnfunc(WEP_MINE_LAYER);
}

void W_Mine_Stick ()
{
	spamsound (self, CHAN_PROJECTILE, "weapons/mine_stick.wav", VOL_BASE, ATTN_NORM);

	// in order for mines to face properly when sticking to the ground, they must be a server side entity rather than a csqc projectile

	entity newmine;
	newmine = spawn();
	newmine.classname = self.classname;

	newmine.bot_dodge = self.bot_dodge;
	newmine.bot_dodgerating = self.bot_dodgerating;

	newmine.owner = self.owner;
	setsize(newmine, '-4 -4 -4', '4 4 4');
	setorigin(newmine, self.origin);
	setmodel(newmine, "models/mine.md3");
	newmine.angles = vectoangles(-trace_plane_normal); // face against the surface

	newmine.takedamage = self.takedamage;
	newmine.damageforcescale = self.damageforcescale;
	newmine.health = self.health;
	newmine.event_damage = self.event_damage;
	newmine.spawnshieldtime = self.spawnshieldtime;

	newmine.movetype = MOVETYPE_NONE; // lock the mine in place
	newmine.projectiledeathtype = self.projectiledeathtype;

	newmine.mine_time = self.mine_time;

	newmine.touch = SUB_Null;
	newmine.think = W_Mine_Think;
	newmine.nextthink = time;
	newmine.cnt = self.cnt;
	newmine.flags = self.flags;

	remove(self);
	self = newmine;
}

void W_Mine_Explode ()
{
	if(other.takedamage == DAMAGE_AIM)
		if(other.classname == "player")
			if(IsDifferentTeam(self.owner, other))
				if(IsFlying(other))
					AnnounceTo(self.owner, "airshot");

	self.event_damage = SUB_Null;
	self.takedamage = DAMAGE_NO;

	RadiusDamage (self, self.owner, autocvar_g_balance_minelayer_damage, autocvar_g_balance_minelayer_edgedamage, autocvar_g_balance_minelayer_radius, world, autocvar_g_balance_minelayer_force, self.projectiledeathtype, other);

	if (self.owner.weapon == WEP_MINE_LAYER)
	{
		if(self.owner.ammo_rockets < autocvar_g_balance_minelayer_ammo)
		{
			self.owner.cnt = WEP_MINE_LAYER;
			ATTACK_FINISHED(self.owner) = time;
			self.owner.switchweapon = w_getbestweapon(self.owner);
		}
	}
	remove (self);
}

void W_Mine_DoRemoteExplode ()
{
	self.event_damage = SUB_Null;
	self.takedamage = DAMAGE_NO;

	RadiusDamage (self, self.owner, autocvar_g_balance_minelayer_remote_damage, autocvar_g_balance_minelayer_remote_edgedamage, autocvar_g_balance_minelayer_remote_radius, world, autocvar_g_balance_minelayer_remote_force, self.projectiledeathtype | HITTYPE_BOUNCE, world);

	if (self.owner.weapon == WEP_MINE_LAYER)
	{
		if(self.owner.ammo_rockets < autocvar_g_balance_minelayer_ammo)
		{
			self.owner.cnt = WEP_MINE_LAYER;
			ATTACK_FINISHED(self.owner) = time;
			self.owner.switchweapon = w_getbestweapon(self.owner);
		}
	}
	remove (self);
}

void W_Mine_RemoteExplode ()
{
	if(self.owner.deadflag == DEAD_NO)
		if((self.spawnshieldtime >= 0)
			? (time >= self.spawnshieldtime) // timer
			: (vlen(NearestPointOnBox(self.owner, self.origin) - self.origin) > autocvar_g_balance_minelayer_remote_radius) // safety device
		)
		{
			W_Mine_DoRemoteExplode();
		}
}

void W_Mine_ProximityExplode ()
{
	// make sure no friend is in the mine's radius. If there is any, explosion is delayed until he's at a safe distance
	if(autocvar_g_balance_minelayer_protection)
	{
		entity head;
		head = findradius(self.origin, autocvar_g_balance_minelayer_radius);
		while(head)
		{
			if(head == self.owner || !IsDifferentTeam(head, self.owner))
				return;
			head = head.chain;
		}
	}

	self.mine_time = 0;
	W_Mine_Explode();
}

void W_Mine_Think (void)
{
	entity head;

	self.nextthink = time;
	if (time > self.cnt)
	{
		other = world;
		self.projectiledeathtype |= HITTYPE_BOUNCE;
		W_Mine_Explode();
		return;
	}

	// a player's mines shall explode if he disconnects or dies
	// TODO: Do this on team change too
	if(self.owner.classname != "player" || self.owner.deadflag != DEAD_NO)
	{
		other = world;
		self.projectiledeathtype |= HITTYPE_BOUNCE;
		W_Mine_Explode();
		return;
	}

	// set the mine for detonation when a foe gets close enough
	head = findradius(self.origin, autocvar_g_balance_minelayer_proximityradius);
	while(head)
	{
		if(head.classname == "player" && head.deadflag == DEAD_NO)
		if(head != self.owner && IsDifferentTeam(head, self.owner)) // don't trigger for team mates
		if(!self.mine_time)
		{
			spamsound (self, CHAN_PROJECTILE, "weapons/mine_trigger.wav", VOL_BASE, ATTN_NORM);
			self.mine_time = time + autocvar_g_balance_minelayer_time;
		}
		head = head.chain;
	}

	// explode if it's time to
	if(self.mine_time && time >= self.mine_time)
		W_Mine_ProximityExplode();

	// remote detonation
	if (self.owner.weapon == WEP_MINE_LAYER)
	if (self.owner.deadflag == DEAD_NO)
	if (self.minelayer_detonate)
		W_Mine_RemoteExplode();
}

void W_Mine_Touch (void)
{
	PROJECTILE_TOUCH;
	if(!other || (other.takedamage != DAMAGE_AIM && other.movetype == MOVETYPE_NONE))
		W_Mine_Stick();
	else if(self.movetype != MOVETYPE_NONE) // don't unstick a locked mine when someone touches it
		self.velocity = '0 0 0';
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
	entity mine;
	entity flash;

	// scan how many mines we placed, and return if we reached our limit
	if(autocvar_g_balance_minelayer_limit)
	{
		self.minelayer_mines = 0;
		for(mine = world; (mine = find(mine, classname, "mine")); ) if(mine.owner == self)
			self.minelayer_mines += 1;

		if(self.minelayer_mines >= autocvar_g_balance_minelayer_limit)
		{
			// the refire delay keeps this message from being spammed
			sprint(self, strcat("You cannot place more than ^2", ftos(autocvar_g_balance_minelayer_limit), " ^7mines at a time\n") );
			play2(self, "weapons/unavailable.wav");
			return;
		}
	}

	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
		self.ammo_rockets = self.ammo_rockets - autocvar_g_balance_minelayer_ammo;

	W_SetupShot_ProjectileSize (self, '-4 -4 -4', '4 4 4', FALSE, 5, "weapons/mine_fire.wav", CHAN_WEAPON, autocvar_g_balance_minelayer_damage);
	pointparticles(particleeffectnum("rocketlauncher_muzzleflash"), w_shotorg, w_shotdir * 1000, 1);

	mine = WarpZone_RefSys_SpawnSameRefSys(self);
	mine.owner = self;
	if(autocvar_g_balance_minelayer_detonatedelay >= 0)
		mine.spawnshieldtime = time + autocvar_g_balance_minelayer_detonatedelay;
	else
		mine.spawnshieldtime = -1;
	mine.classname = "mine";
	mine.bot_dodge = TRUE;
	mine.bot_dodgerating = autocvar_g_balance_minelayer_damage * 2; // * 2 because it can detonate inflight which makes it even more dangerous

	mine.takedamage = DAMAGE_YES;
	mine.damageforcescale = autocvar_g_balance_minelayer_damageforcescale;
	mine.health = autocvar_g_balance_minelayer_health;
	mine.event_damage = W_Mine_Damage;

	mine.movetype = MOVETYPE_TOSS;
	PROJECTILE_MAKETRIGGER(mine);
	mine.projectiledeathtype = WEP_MINE_LAYER;
	setsize (mine, '-4 -4 -4', '4 4 4'); // give it some size so it can be shot

	setorigin (mine, w_shotorg - v_forward * 4); // move it back so it hits the wall at the right point
	W_SetupProjectileVelocity(mine, autocvar_g_balance_minelayer_speed, 0);
	mine.angles = vectoangles (mine.velocity);

	mine.touch = W_Mine_Touch;
	mine.think = W_Mine_Think;
	mine.nextthink = time;
	mine.cnt = time + autocvar_g_balance_minelayer_lifetime;
	mine.flags = FL_PROJECTILE;

	CSQCProjectile(mine, TRUE, PROJECTILE_MINE, TRUE);

	// muzzle flash for 1st person view
	flash = spawn ();
	setmodel (flash, "models/flash.md3"); // precision set below
	SUB_SetFade (flash, time, 0.1);
	flash.effects = EF_ADDITIVE | EF_FULLBRIGHT | EF_LOWPRECISION;
	W_AttachToShotorg(flash, '5 0 0');

	// common properties

	other = mine; MUTATOR_CALLHOOK(EditProjectile);
}

void spawnfunc_weapon_minelayer (void); // defined in t_items.qc

float w_minelayer(float req)
{
	entity mine;
	float minfound;
	if (req == WR_AIM)
	{
		// aim and decide to fire if appropriate
		self.BUTTON_ATCK = bot_aim(autocvar_g_balance_minelayer_speed, 0, autocvar_g_balance_minelayer_lifetime, FALSE);
		if(skill >= 2) // skill 0 and 1 bots won't detonate mines!
		{
			// decide whether to detonate mines
			entity targetlist, targ;
			float edgedamage, coredamage, edgeradius, recipricoledgeradius, d;
			float selfdamage, teamdamage, enemydamage;
			edgedamage = autocvar_g_balance_minelayer_edgedamage;
			coredamage = autocvar_g_balance_minelayer_damage;
			edgeradius = autocvar_g_balance_minelayer_radius;
			recipricoledgeradius = 1 / edgeradius;
			selfdamage = 0;
			teamdamage = 0;
			enemydamage = 0;
			targetlist = findchainfloat(bot_attack, TRUE);
			mine = find(world, classname, "mine");
			while (mine)
			{
				if (mine.owner != self)
				{
					mine = find(mine, classname, "mine");
					continue;
				}
				targ = targetlist;
				while (targ)
				{
					d = vlen(targ.origin + (targ.mins + targ.maxs) * 0.5 - mine.origin);
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
				mine = find(mine, classname, "mine");
			}
			float desirabledamage;
			desirabledamage = enemydamage;
			if (time > self.invincible_finished && time > self.spawnshieldtime)
				desirabledamage = desirabledamage - selfdamage * autocvar_g_balance_selfdamagepercent;
			if (teams_matter && self.team)
				desirabledamage = desirabledamage - teamdamage;

			mine = find(world, classname, "mine");
			while (mine)
			{
				if (mine.owner != self)
				{
					mine = find(mine, classname, "mine");
					continue;
				}
				makevectors(mine.v_angle);
				targ = targetlist;
				if (skill > 9) // normal players only do this for the target they are tracking
				{
					targ = targetlist;
					while (targ)
					{
						if (
							(v_forward * normalize(mine.origin - targ.origin)< 0.1)
							&& desirabledamage > 0.1*coredamage
						)self.BUTTON_ATCK2 = TRUE;
						targ = targ.chain;
					}
				}else{
					float distance; distance= bound(300,vlen(self.origin-self.enemy.origin),30000);
					//As the distance gets larger, a correct detonation gets near imposible
					//Bots are assumed to use the mine spawnfunc_light to see if the mine gets near a player
					if(v_forward * normalize(mine.origin - self.enemy.origin)< 0.1)
						if(self.enemy.classname == "player")
							if(desirabledamage >= 0.1*coredamage)
								if(random()/distance*300 > frametime*bound(0,(10-skill)*0.2,1))
									self.BUTTON_ATCK2 = TRUE;
				//	dprint(ftos(random()/distance*300),">");dprint(ftos(frametime*bound(0,(10-skill)*0.2,1)),"\n");
				}

				mine = find(mine, classname, "mine");
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
		if (self.BUTTON_ATCK)
		{
			if(weapon_prepareattack(0, autocvar_g_balance_minelayer_refire))
			{
				W_Mine_Attack();
				weapon_thinkf(WFRAME_FIRE1, autocvar_g_balance_minelayer_animtime, w_ready);
			}
		}

		if (self.BUTTON_ATCK2)
		{
			minfound = 0;
			for(mine = world; (mine = find(mine, classname, "mine")); ) if(mine.owner == self)
			{
				if(!mine.minelayer_detonate)
				{
					mine.minelayer_detonate = TRUE;
					minfound = 1;
				}
			}
			if(minfound)
				sound (self, CHAN_WEAPON2, "weapons/mine_det.wav", VOL_BASE, ATTN_NORM);
		}
	}
	else if (req == WR_PRECACHE)
	{
		precache_model ("models/flash.md3");
		precache_model ("models/mine.md3");
		precache_model ("models/weapons/g_minelayer.md3");
		precache_model ("models/weapons/v_minelayer.md3");
		precache_model ("models/weapons/h_minelayer.iqm");
		precache_sound ("weapons/mine_det.wav");
		precache_sound ("weapons/mine_fire.wav");
		precache_sound ("weapons/mine_stick.wav");
		precache_sound ("weapons/mine_trigger.wav");
	}
	else if (req == WR_SETUP)
	{
		weapon_setup(WEP_MINE_LAYER);
	}
	else if (req == WR_CHECKAMMO1)
	{
		// don't switch while placing a mine
		if ((ATTACK_FINISHED(self) <= time || self.weapon != WEP_MINE_LAYER)
			&& self.ammo_rockets < autocvar_g_balance_minelayer_ammo)
			return FALSE;
	}
	else if (req == WR_CHECKAMMO2)
		return FALSE;
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
			sound(self, CHAN_PROJECTILE, "weapons/mine_exp.wav", VOL_BASE, ATTN_NORM);
	}
	else if(req == WR_PRECACHE)
	{
		precache_sound("weapons/mine_exp.wav");
	}
	else if (req == WR_SUICIDEMESSAGE)
		w_deathtypestring = "%s exploded";
	else if (req == WR_KILLMESSAGE)
	{
		if(w_deathtype & HITTYPE_BOUNCE) // (remote detonation)
			w_deathtypestring = "%s got too close to %s's mine";
		else if(w_deathtype & HITTYPE_SPLASH)
			w_deathtypestring = "%s almost dodged %s's mine";
		else
			w_deathtypestring = "%s stepped on %s's mine";
	}
	return TRUE;
}
#endif
#endif
