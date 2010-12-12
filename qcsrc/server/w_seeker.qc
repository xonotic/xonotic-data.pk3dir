#ifdef REGISTER_WEAPON
REGISTER_WEAPON(SEEKER, w_seeker, IT_ROCKETS, 9, WEP_FLAG_NORMAL | WEP_TYPE_SPLASH, BOT_PICKUP_RATING_MID, "seeker", "seeker", "T.A.G. Seeker");
#else
#ifdef SVQC
//.float proxytime; = autoswitch
//.float tl; = wait

void Seeker_Missile_Explode ()
{
	self.event_damage = SUB_Null;
	RadiusDamage (self, self.owner, autocvar_g_balance_seeker_missile_damage, autocvar_g_balance_seeker_missile_edgedamage, autocvar_g_balance_seeker_missile_radius, world, autocvar_g_balance_seeker_missile_force, self.projectiledeathtype, other);

	remove (self);
}

void Seeker_Missile_Touch()
{
	PROJECTILE_TOUCH;

	Seeker_Missile_Explode();
}

void Seeker_Missile_Think()
{
	entity e;
	vector desireddir, olddir, newdir, eorg;
	float turnrate;
	float dist;
	float spd;

	if (time > self.cnt)
	{
		self.projectiledeathtype |= HITTYPE_SPLASH;
		Seeker_Missile_Explode();
	}

	spd = vlen(self.velocity);
	spd = bound(
		spd - autocvar_g_balance_seeker_missile_decel * frametime,
		autocvar_g_balance_seeker_missile_speed_max,
		spd + autocvar_g_balance_seeker_missile_accel * frametime
	);

	if (self.enemy != world)
		if (self.enemy.takedamage != DAMAGE_AIM || self.enemy.deadflag != DEAD_NO)
			self.enemy = world;

	if (self.enemy != world)
	{
		e               = self.enemy;
		eorg            = 0.5 * (e.absmin + e.absmax);
		turnrate        = autocvar_g_balance_seeker_missile_turnrate; // how fast to turn
		desireddir      = normalize(eorg - self.origin);
		olddir          = normalize(self.velocity); // get my current direction
		dist            = vlen(eorg - self.origin);

		// Do evasive maneuvers for world objects? ( this should be a cpu hog. :P )
		if (autocvar_g_balance_seeker_missile_smart && (dist > autocvar_g_balance_seeker_missile_smart_mindist))
		{
			// Is it a better idea (shorter distance) to trace to the target itself?
			if ( vlen(self.origin + olddir * self.wait) < dist)
				traceline(self.origin, self.origin + olddir * self.wait, FALSE, self);
			else
				traceline(self.origin, eorg, FALSE, self);

			// Setup adaptive tracelength
			self.wait = bound(autocvar_g_balance_seeker_missile_smart_trace_min, vlen(self.origin - trace_endpos), self.wait = autocvar_g_balance_seeker_missile_smart_trace_max);

			// Calc how important it is that we turn and add this to the desierd (enemy) dir.
			desireddir  = normalize(((trace_plane_normal * (1 - trace_fraction)) + (desireddir * trace_fraction)) * 0.5);
		}
		
		newdir = normalize(olddir + desireddir * turnrate); // take the average of the 2 directions; not the best method but simple & easy
		self.velocity = newdir * spd; // make me fly in the new direction at my flight speed
	}

	// Proxy
	if (autocvar_g_balance_seeker_missile_proxy)
	{
		if ( dist <= autocvar_g_balance_seeker_missile_proxy_maxrange)
		{
			if (self.autoswitch == 0)
			{
				self.autoswitch = time + autocvar_g_balance_seeker_missile_proxy_delay;
			}
			else
			{
				if (self.autoswitch <= time)
				{
					Seeker_Missile_Explode();
					self.autoswitch = 0;
				}
			}
		}
		else
		{
			if (self.autoswitch != 0)
				self.autoswitch = 0;
		}
	}
	///////////////

	if (self.enemy.deadflag != DEAD_NO)
	{
		self.enemy = world;
		self.cnt = time + 1 + (random() * 4);
		self.nextthink = self.cnt;
		return;
	}

	//self.angles = vectoangles(self.velocity);			// turn model in the new flight direction
	self.nextthink = time;// + 0.05; // csqc projectiles
	UpdateCSQCProjectile(self);
}



void Seeker_Missile_Damage (entity inflictor, entity attacker, float damage, float deathtype, vector hitloc, vector force)
{
	if (self.health <= 0)
		return;

	if (self.owner == attacker)
		self.health = self.health - (damage * 0.25);
	else
		self.health = self.health - damage;
		
	if (self.health <= 0)
		W_PrepareExplosionByDamage(attacker, Seeker_Missile_Explode);
}

/*
void Seeker_Missile_Animate()
{
	self.frame = self.frame +1;
	self.nextthink = time + 0.05;

	if (self.enemy != world)
		if (self.enemy.takedamage != DAMAGE_AIM || self.enemy.deadflag != DEAD_NO)
			self.enemy = world;

	if(self.frame == 5)
	{
		self.think           = Seeker_Missile_Think;
		self.nextthink       = time;// + cvar("g_balance_seeker_missile_activate_delay"); // cant dealy with csqc projectiles

		if (autocvar_g_balance_seeker_missile_proxy)
			self.movetype    = MOVETYPE_BOUNCEMISSILE;
		else
			self.movetype    = MOVETYPE_FLYMISSILE;
	}

	UpdateCSQCProjectile(self);
}
*/

void Seeker_Fire_Missile(vector f_diff)
{
	local entity missile;

	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
		self.ammo_rockets = self.ammo_rockets - autocvar_g_balance_seeker_missile_ammo;

	makevectors(self.v_angle);
	W_SetupShot_ProjectileSize (self, '-2 -2 -2', '2 2 2', FALSE, 2, "weapons/seeker_fire.wav", CHAN_WEAPON, 0);
	w_shotorg += f_diff;
	pointparticles(particleeffectnum("seeker_muzzleflash"), w_shotorg, w_shotdir * 1000, 1);

	//self.detornator         = FALSE;

	missile                 = spawn();
	missile.owner           = self;
	missile.classname       = "seeker_missile";
	missile.bot_dodge       = TRUE;
	missile.bot_dodgerating = autocvar_g_balance_seeker_missile_damage;

	missile.think           = Seeker_Missile_Think;
	missile.touch           = Seeker_Missile_Touch;
	missile.event_damage    = Seeker_Missile_Damage;
	missile.nextthink       = time;// + 0.2;// + cvar("g_balance_seeker_missile_activate_delay");
	missile.cnt             = time + autocvar_g_balance_seeker_missile_lifetime;
	missile.enemy           = self.enemy;
	missile.solid           = SOLID_BBOX;
	missile.scale           = 2;
	missile.takedamage      = DAMAGE_YES;
	missile.health          = autocvar_g_balance_seeker_missile_health;
	missile.damageforcescale = autocvar_g_balance_seeker_missile_damageforcescale;
	missile.projectiledeathtype = WEP_SEEKER;
	//missile.think           = Seeker_Missile_Animate; // csqc projectiles.


	setorigin (missile, w_shotorg);
	setsize (missile, '-4 -4 -4', '4 4 4');
	missile.movetype    = MOVETYPE_FLYMISSILE;
	missile.flags       = FL_PROJECTILE;
	W_SETUPPROJECTILEVELOCITY_UP(missile, g_balance_seeker_missile);

	missile.angles = vectoangles (missile.velocity);

	CSQCProjectile(missile, FALSE, PROJECTILE_SEEKER, TRUE);

	other = missile; MUTATOR_CALLHOOK(EditProjectile);
}

void Seeker_Vollycontroler_Think()
{
	float c;
	entity oldself,oldenemy;
	self.cnt = self.cnt - 1;

	if((!(self.owner.items & IT_UNLIMITED_AMMO) && self.owner.ammo_rockets < autocvar_g_balance_seeker_missile_ammo) || (self.cnt <= -1) || (self.owner.deadflag != DEAD_NO) || (self.owner.switchweapon != WEP_SEEKER))
	{
		remove(self);
		return;
	}

	self.nextthink = time + autocvar_g_balance_seeker_missile_delay;

	oldself = self;
	self = self.owner;

	oldenemy = self.enemy;
	self.enemy = oldself.enemy;

	c = mod(oldself.cnt, 4);
	switch(c)
	{
		case 0:
			Seeker_Fire_Missile('-1.25 -3.75 0');
			break;
		case 1:
			Seeker_Fire_Missile('+1.25 -3.75 0');
			break;
		case 2:
			Seeker_Fire_Missile('-1.25 +3.75 0');
			break;
		case 3:
		default:
			Seeker_Fire_Missile('+1.25 +3.75 0');
			break;
	}

	self.enemy = oldenemy;
	self = oldself;
}

void Seeker_Tag_Explode ()
{
	//if(other==self.owner)
	//    return;
	Damage_DamageInfo(self.origin, 0, 0, 0, self.velocity, WEP_SEEKER | HITTYPE_BOUNCE, self);

	remove (self);
}

void Seeker_Tag_Damage (entity inflictor, entity attacker, float damage, float deathtype, vector hitloc, vector force)
{
	if (self.health <= 0)
		return;
	self.health = self.health - damage;
	if (self.health <= 0)
		Seeker_Tag_Explode();
}


void Seeker_Tag_Touch()
{
	vector dir;
	vector org2;
	entity e;
	
	dir     = normalize (self.owner.origin - self.origin);
	org2    = findbetterlocation (self.origin, 8);

	te_knightspike(org2);

	self.event_damage = SUB_Null;
	Damage_DamageInfo(self.origin, 0, 0, 0, self.velocity, WEP_SEEKER | HITTYPE_HEADSHOT, self);

	if (other.takedamage == DAMAGE_AIM && other.deadflag == DEAD_NO)
	{		
		e           = spawn();
		e.cnt       = autocvar_g_balance_seeker_missile_count;
		e.owner     = self.owner;
		e.enemy     = other;
		e.think     = Seeker_Vollycontroler_Think;
		e.nextthink = time;
	}

	remove(self);
	return;
}

void Seeker_Fire_Tag()
{
	local entity missile;
	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
		self.ammo_rockets = self.ammo_rockets - autocvar_g_balance_seeker_tag_ammo;

	W_SetupShot_ProjectileSize (self, '-2 -2 -2', '2 2 2', FALSE, 2, "weapons/tag_fire.wav", CHAN_WEAPON, autocvar_g_balance_seeker_missile_damage * autocvar_g_balance_seeker_missile_count);

	missile                 = spawn();
	missile.owner           = self;
	missile.classname       = "seeker_tag";
	missile.bot_dodge       = TRUE;
	missile.bot_dodgerating = 50;
	missile.touch           = Seeker_Tag_Touch;
	missile.think           = SUB_Remove;
	missile.nextthink       = time + autocvar_g_balance_seeker_tag_lifetime;
	missile.movetype        = MOVETYPE_FLY;
	missile.solid           = SOLID_BBOX;
	missile.owner           = self;

	missile.takedamage       = DAMAGE_YES;
	missile.event_damage    = Seeker_Tag_Explode;
	missile.health          = autocvar_g_balance_seeker_tag_health;
	missile.damageforcescale = autocvar_g_balance_seeker_tag_damageforcescale;

	setorigin (missile, w_shotorg);
	setsize (missile, '-2 -2 -2', '2 2 2');

	missile.flags       = FL_PROJECTILE;

	missile.movetype    = MOVETYPE_FLY;
	W_SETUPPROJECTILEVELOCITY(missile, g_balance_seeker_tag);
	missile.angles = vectoangles (missile.velocity);

	CSQCProjectile(missile, TRUE, PROJECTILE_TAG, FALSE); // has sound

	other = missile; MUTATOR_CALLHOOK(EditProjectile);
}


void Seeker_Flac_Explode ()
{
	self.event_damage = SUB_Null;

	RadiusDamage (self, self.owner, autocvar_g_balance_seeker_flac_damage, autocvar_g_balance_seeker_flac_edgedamage, autocvar_g_balance_seeker_flac_radius, world, autocvar_g_balance_seeker_flac_force, self.projectiledeathtype, other);

	remove (self);
}

void Seeker_Flac_Touch()
{
	PROJECTILE_TOUCH;

	Seeker_Flac_Explode();
}

void Seeker_Fire_Flac()
{
	local entity missile;
	vector f_diff;
	float c;

	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
		self.ammo_rockets = self.ammo_rockets - autocvar_g_balance_seeker_flac_ammo;

	c = mod(self.bulletcounter, 4);
	switch(c)
	{
		case 0:
			f_diff = '-1.25 -3.75 0';
			break;
		case 1:
			f_diff = '+1.25 -3.75 0';
			break;
		case 2:
			f_diff = '-1.25 +3.75 0';
			break;
		case 3:
		default:
			f_diff = '+1.25 +3.75 0';
			break;
	}
	W_SetupShot_ProjectileSize (self, '-2 -2 -2', '2 2 2', FALSE, 2, "weapons/flac_fire.wav", CHAN_WEAPON, autocvar_g_balance_seeker_flac_damage);
	w_shotorg += f_diff;

	pointparticles(particleeffectnum("hagar_muzzleflash"), w_shotorg, w_shotdir * 1000, 1);

	missile 				= spawn ();
	missile.owner 			= missile.realowner = self;
	missile.classname 		= "missile";
	missile.bot_dodge 		= TRUE;
	missile.bot_dodgerating = autocvar_g_balance_seeker_flac_damage;
	missile.touch 			= Seeker_Flac_Explode;
	missile.use 			= Seeker_Flac_Explode; 
	missile.think 			= adaptor_think2use_hittype_splash;
	missile.nextthink 		= time + autocvar_g_balance_seeker_flac_lifetime + autocvar_g_balance_seeker_flac_lifetime_rand;
	missile.solid 			= SOLID_BBOX;
	missile.movetype 		= MOVETYPE_FLY;	
	missile.projectiledeathtype = WEP_SEEKER;
	missile.projectiledeathtype = WEP_SEEKER | HITTYPE_SECONDARY;
	missile.flags 				= FL_PROJECTILE;
	
	// csqc projectiles
	//missile.angles 				= vectoangles (missile.velocity);	
	//missile.scale = 0.4; // BUG: the model is too big 
	
	setorigin (missile, w_shotorg);
	setsize (missile, '-2 -2 -2', '2 2 2');
		
	W_SETUPPROJECTILEVELOCITY_UP(missile, g_balance_seeker_flac);
	CSQCProjectile(missile, TRUE, PROJECTILE_FLAC, TRUE);

	other = missile; MUTATOR_CALLHOOK(EditProjectile);
}

void spawnfunc_weapon_seeker (void)
{
	weapon_defaultspawnfunc(WEP_SEEKER);
}

float w_seeker(float req)
{
	if (req == WR_AIM)
		self.BUTTON_ATCK = bot_aim(autocvar_g_balance_seeker_tag_speed, 0, 20, FALSE);

	else if (req == WR_THINK)
	{
		if (self.BUTTON_ATCK)
			if (weapon_prepareattack(0, autocvar_g_balance_seeker_tag_refire))
			{
				Seeker_Fire_Tag();
				weapon_thinkf(WFRAME_FIRE1, autocvar_g_balance_seeker_tag_animtime, w_ready);
			}

		if (self.BUTTON_ATCK2)
			if (weapon_prepareattack(1, autocvar_g_balance_seeker_flac_refire))
			{
				Seeker_Fire_Flac();
				weapon_thinkf(WFRAME_FIRE2, autocvar_g_balance_seeker_flac_animtime, w_ready);
			}

	}
	else if (req == WR_PRECACHE)
	{
		precache_model ("models/weapons/g_seeker.md3");
		precache_model ("models/weapons/v_seeker.md3");
		precache_model ("models/weapons/h_seeker.iqm");
		precache_sound ("weapons/tag_fire.wav");
		precache_sound ("weapons/flac_fire.wav");
		precache_sound ("weapons/seeker_fire.wav");
	}
	else if (req == WR_SETUP)
		weapon_setup(WEP_SEEKER);
	else if (req == WR_CHECKAMMO1)
		return self.ammo_rockets >= autocvar_g_balance_seeker_tag_ammo + autocvar_g_balance_seeker_missile_ammo;
	else if (req == WR_CHECKAMMO2)
		return self.ammo_rockets >= autocvar_g_balance_seeker_flac_ammo;
	return TRUE;
};
#endif
#ifdef CSQC
float w_seeker(float req)
{
	if(req == WR_IMPACTEFFECT)
	{
		vector org2;
		org2 = w_org + w_backoff * 6;
		if(w_deathtype & HITTYPE_SECONDARY)
		{
			pointparticles(particleeffectnum("flac_explode"), org2, '0 0 0', 1);
			if(!w_issilent)
			{
				if (w_random<0.15)
					sound(self, CHAN_PROJECTILE, "weapons/flacexp1.wav", 1, ATTN_NORM);
				else if (w_random<0.7)
					sound(self, CHAN_PROJECTILE, "weapons/flacexp2.wav", 1, ATTN_NORM);
				else
					sound(self, CHAN_PROJECTILE, "weapons/flacexp3.wav", 1, ATTN_NORM);
			}
		}
		else
		{
			if(w_deathtype & HITTYPE_BOUNCE)
			{
				pointparticles(particleeffectnum("hagar_explode"), org2, '0 0 0', 1);
				if(!w_issilent)
				{
					if (w_random<0.15)
						sound(self, CHAN_PROJECTILE, "weapons/tagexp1.wav", 1, ATTN_NORM);
					else if (w_random<0.7)
						sound(self, CHAN_PROJECTILE, "weapons/tagexp2.wav", 1, ATTN_NORM);
					else
						sound(self, CHAN_PROJECTILE, "weapons/tagexp3.wav", 1, ATTN_NORM);
				}
			}
			else if(w_deathtype & HITTYPE_HEADSHOT)
			{
				if(!w_issilent)
					sound(self, CHAN_PROJECTILE, "weapons/tag_impact.wav", 1, ATTN_NORM);
			}
			else
			{
				pointparticles(particleeffectnum("hagar_explode"), org2, '0 0 0', 1);
				if(!w_issilent)
				{
					if (w_random<0.15)
						sound(self, CHAN_PROJECTILE, "weapons/seekerexp1.wav", 1, ATTN_NORM);
					else if (w_random<0.7)
						sound(self, CHAN_PROJECTILE, "weapons/seekerexp2.wav", 1, ATTN_NORM);
					else
						sound(self, CHAN_PROJECTILE, "weapons/seekerexp3.wav", 1, ATTN_NORM);
				}
			}
		}
	}
	else if(req == WR_PRECACHE)
	{
		precache_sound("weapons/flacexp1.wav");
		precache_sound("weapons/flacexp2.wav");
		precache_sound("weapons/flacexp3.wav");
		precache_sound("weapons/seekerexp1.wav");
		precache_sound("weapons/seekerexp2.wav");
		precache_sound("weapons/seekerexp3.wav");
		precache_sound("weapons/tagexp1.wav");
		precache_sound("weapons/tagexp2.wav");
		precache_sound("weapons/tagexp3.wav");
		precache_sound("weapons/tag_impact.wav");
	}
	else if (req == WR_SUICIDEMESSAGE)
		w_deathtypestring = "%s played with tiny rockets";
	else if (req == WR_KILLMESSAGE)
	{
		if(w_deathtype & HITTYPE_SECONDARY)
			w_deathtypestring = "%s ran into %s's flac";
		else
			w_deathtypestring = "%s was tagged by %s";
	}
	return TRUE;
}
#endif
#endif
