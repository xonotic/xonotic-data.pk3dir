#ifndef MENUQC
bool M_Shambler(int);
#endif
REGISTER_MONSTER_SIMPLE(
/* MON_##id   */ SHAMBLER,
/* spawnflags */ MONSTER_SIZE_BROKEN | MON_FLAG_SUPERMONSTER | MON_FLAG_MELEE | MON_FLAG_RANGED,
/* mins,maxs  */ '-41 -41 -31', '41 41 65',
/* model      */ "shambler.mdl",
/* netname    */ "shambler",
/* fullname   */ _("Shambler")
) {
#ifndef MENUQC
	this.monster_func = M_Shambler;
	this.monster_func(MR_PRECACHE);
#endif
}

#ifdef SVQC
float autocvar_g_monster_shambler_health;
float autocvar_g_monster_shambler_damageforcescale = 0.1;
float autocvar_g_monster_shambler_attack_smash_damage;
float autocvar_g_monster_shambler_attack_smash_range;
float autocvar_g_monster_shambler_attack_claw_damage;
float autocvar_g_monster_shambler_attack_lightning_damage;
float autocvar_g_monster_shambler_attack_lightning_damage_zap = 15;
float autocvar_g_monster_shambler_attack_lightning_force;
float autocvar_g_monster_shambler_attack_lightning_radius;
float autocvar_g_monster_shambler_attack_lightning_radius_zap;
float autocvar_g_monster_shambler_attack_lightning_speed;
float autocvar_g_monster_shambler_attack_lightning_speed_up;
float autocvar_g_monster_shambler_speed_stop;
float autocvar_g_monster_shambler_speed_run;
float autocvar_g_monster_shambler_speed_walk;

/*
const float shambler_anim_stand		= 0;
const float shambler_anim_walk		= 1;
const float shambler_anim_run		= 2;
const float shambler_anim_smash		= 3;
const float shambler_anim_swingr	= 4;
const float shambler_anim_swingl	= 5;
const float shambler_anim_magic		= 6;
const float shambler_anim_pain		= 7;
const float shambler_anim_death		= 8;
*/

.float shambler_lastattack; // delay attacks separately

void M_Shambler_Attack_Smash()
{SELFPARAM();
	makevectors(self.angles);
	Send_Effect(EFFECT_EXPLOSION_MEDIUM, (self.origin + (v_forward * 150)) - ('0 0 1' * self.maxs.z), '0 0 0', 1);
	sound(self, CH_SHOTS, SND_ROCKET_IMPACT, VOL_BASE, ATTEN_NORM);

	// RadiusDamage does NOT support custom starting location, which means we must use this hack...

	tracebox(self.origin + v_forward * 50, self.mins * 0.5, self.maxs * 0.5, self.origin + v_forward * autocvar_g_monster_shambler_attack_smash_range, MOVE_NORMAL, self);

	if(trace_ent.takedamage)
		Damage(trace_ent, self, self, (autocvar_g_monster_shambler_attack_smash_damage) * MONSTER_SKILLMOD(self), DEATH_MONSTER_SHAMBLER_SMASH, trace_ent.origin, normalize(trace_ent.origin - self.origin));
}

void M_Shambler_Attack_Swing()
{SELFPARAM();
	float r = (random() < 0.5);
	if(r && Monster_Attack_Melee(self.enemy, (autocvar_g_monster_shambler_attack_claw_damage), ((r) ? self.anim_melee2 : self.anim_melee3), self.attack_range, 0.8, DEATH_MONSTER_SHAMBLER_CLAW, true))
	{
		Monster_Delay(1, 0, 0.5, M_Shambler_Attack_Swing);
		self.attack_finished_single += 0.5;
		self.anim_finished = self.attack_finished_single;
	}
}

void M_Shambler_Attack_Lightning_Explode()
{SELFPARAM();
	entity head;

	sound(self, CH_SHOTS, SND_ELECTRO_IMPACT, VOL_BASE, ATTEN_NORM);
	Send_Effect(EFFECT_ELECTRO_IMPACT, '0 0 0', '0 0 0', 1);

	self.event_damage = func_null;
	self.takedamage = DAMAGE_NO;
	self.movetype = MOVETYPE_NONE;
	self.velocity = '0 0 0';

	if(self.movetype == MOVETYPE_NONE)
		self.velocity = self.oldvelocity;

	RadiusDamage (self, self.realowner, (autocvar_g_monster_shambler_attack_lightning_damage), (autocvar_g_monster_shambler_attack_lightning_damage), (autocvar_g_monster_shambler_attack_lightning_radius), world, world, (autocvar_g_monster_shambler_attack_lightning_force), self.projectiledeathtype, other);

	for(head = findradius(self.origin, (autocvar_g_monster_shambler_attack_lightning_radius_zap)); head; head = head.chain) if(head != self.realowner) if(head.takedamage)
	{
		te_csqc_lightningarc(self.origin, head.origin);
		Damage(head, self, self.realowner, (autocvar_g_monster_shambler_attack_lightning_damage_zap) * MONSTER_SKILLMOD(self), DEATH_MONSTER_SHAMBLER_ZAP, head.origin, '0 0 0');
	}

	self.think = SUB_Remove;
	self.nextthink = time + 0.2;
}

void M_Shambler_Attack_Lightning_Damage(entity inflictor, entity attacker, float damage, int deathtype, vector hitloc, vector force)
{SELFPARAM();
	if (self.health <= 0)
		return;

	if (!W_CheckProjectileDamage(inflictor.realowner, self.realowner, deathtype, -1)) // no exceptions
		return; // g_projectiles_damage says to halt

	self.health = self.health - damage;

	if (self.health <= 0)
		W_PrepareExplosionByDamage(attacker, self.use);
}

void M_Shambler_Attack_Lightning_Touch()
{SELFPARAM();
	PROJECTILE_TOUCH;

	self.use ();
}

void M_Shambler_Attack_Lightning_Think()
{SELFPARAM();
	self.nextthink = time;
	if (time > self.cnt)
	{
		other = world;
		M_Shambler_Attack_Lightning_Explode();
		return;
	}
}

void M_Shambler_Attack_Lightning()
{SELFPARAM();
	entity gren;

	monster_makevectors(self.enemy);

	gren = spawn ();
	gren.owner = gren.realowner = self;
	gren.classname = "grenade";
	gren.bot_dodge = true;
	gren.bot_dodgerating = (autocvar_g_monster_shambler_attack_lightning_damage);
	gren.movetype = MOVETYPE_BOUNCE;
	PROJECTILE_MAKETRIGGER(gren);
	gren.projectiledeathtype = DEATH_MONSTER_SHAMBLER_ZAP;
	setorigin(gren, CENTER_OR_VIEWOFS(self));
	setsize(gren, '-8 -8 -8', '8 8 8');
	gren.scale = 2.5;

	gren.cnt = time + 5;
	gren.nextthink = time;
	gren.think = M_Shambler_Attack_Lightning_Think;
	gren.use = M_Shambler_Attack_Lightning_Explode;
	gren.touch = M_Shambler_Attack_Lightning_Touch;

	gren.takedamage = DAMAGE_YES;
	gren.health = 50;
	gren.damageforcescale = 0;
	gren.event_damage = M_Shambler_Attack_Lightning_Damage;
	gren.damagedbycontents = true;
	gren.missile_flags = MIF_SPLASH | MIF_ARC;
	W_SetupProjVelocity_Explicit(gren, v_forward, v_up, (autocvar_g_monster_shambler_attack_lightning_speed), (autocvar_g_monster_shambler_attack_lightning_speed_up), 0, 0, false);

	gren.angles = vectoangles (gren.velocity);
	gren.flags = FL_PROJECTILE;

	CSQCProjectile(gren, true, PROJECTILE_SHAMBLER_LIGHTNING, true);
}

float M_Shambler_Attack(float attack_type)
{SELFPARAM();
	switch(attack_type)
	{
		case MONSTER_ATTACK_MELEE:
		{
			M_Shambler_Attack_Swing();
			return true;
		}
		case MONSTER_ATTACK_RANGED:
		{
			float randomness = random(), enemy_len = vlen(self.enemy.origin - self.origin);

			if(time >= self.shambler_lastattack) // shambler doesn't attack much
			if(self.flags & FL_ONGROUND)
			if(randomness <= 0.5 && enemy_len <= autocvar_g_monster_shambler_attack_smash_range)
			{
				setanim(self, self.anim_melee2, true, true, false);
				Monster_Delay(1, 0, 0.7, M_Shambler_Attack_Smash);
				self.attack_finished_single = time + 1.1;
				self.anim_finished = time + 1.1;
				self.state = MONSTER_ATTACK_MELEE; // kinda a melee attack
				self.shambler_lastattack = time + 3 + random() * 1.5;
				return true;
			}
			else if(randomness <= 0.1 && enemy_len >= autocvar_g_monster_shambler_attack_smash_range * 1.5) // small chance, don't want this spammed
			{
				setanim(self, self.anim_shoot, true, true, false);
				self.state = MONSTER_ATTACK_MELEE; // maybe we should rename this to something more general
				self.attack_finished_single = time + 1.1;
				self.anim_finished = 1.1;
				self.shambler_lastattack = time + 3 + random() * 1.5;
				Monster_Delay(1, 0, 0.6, M_Shambler_Attack_Lightning);
				return true;
			}

			return false;
		}
	}

	return false;
}

void spawnfunc_monster_shambler() { Monster_Spawn(MON_SHAMBLER.monsterid); }
#endif // SVQC

bool M_Shambler(int req)
{SELFPARAM();
	switch(req)
	{
		#ifdef SVQC
		case MR_THINK:
		{
			return true;
		}
		case MR_PAIN:
		{
			self.pain_finished = time + 0.5;
			setanim(self, self.anim_pain1, true, true, false);
			return true;
		}
		case MR_DEATH:
		{
			setanim(self, self.anim_die1, false, true, true);
			return true;
		}
		#endif
		#ifndef MENUQC
		case MR_ANIM:
		{
			vector none = '0 0 0';
			self.anim_die1 = animfixfps(self, '8 1 0.5', none); // 2 seconds
			self.anim_walk = animfixfps(self, '1 1 1', none);
			self.anim_idle = animfixfps(self, '0 1 1', none);
			self.anim_pain1 = animfixfps(self, '7 1 2', none); // 0.5 seconds
			self.anim_melee1 = animfixfps(self, '3 1 5', none); // analyze models and set framerate
			self.anim_melee2 = animfixfps(self, '4 1 5', none); // analyze models and set framerate
			self.anim_melee3 = animfixfps(self, '5 1 5', none); // analyze models and set framerate
			self.anim_shoot = animfixfps(self, '6 1 5', none); // analyze models and set framerate
			self.anim_run = animfixfps(self, '2 1 1', none);

			return true;
		}
		#endif
		#ifdef SVQC
		case MR_SETUP:
		{
			if(!self.health) self.health = (autocvar_g_monster_shambler_health);
			if(!self.attack_range) self.attack_range = 150;
			if(!self.speed) { self.speed = (autocvar_g_monster_shambler_speed_walk); }
			if(!self.speed2) { self.speed2 = (autocvar_g_monster_shambler_speed_run); }
			if(!self.stopspeed) { self.stopspeed = (autocvar_g_monster_shambler_speed_stop); }
			if(!self.damageforcescale) { self.damageforcescale = (autocvar_g_monster_shambler_damageforcescale); }

			self.monster_loot = spawnfunc_item_health_mega;
			self.weapon = WEP_ELECTRO.m_id; // matches attacks better than WEP_VORTEX

			setanim(self, self.anim_shoot, false, true, true);
			self.spawn_time = self.animstate_endtime;
			self.spawnshieldtime = self.spawn_time;
			self.monster_attackfunc	= M_Shambler_Attack;

			return true;
		}
		case MR_PRECACHE:
		{
			return true;
		}
		#endif
	}

	return true;
}
