#ifndef MENUQC
bool M_Spider(int);
#endif
REGISTER_MONSTER_SIMPLE(
/* MON_##id   */ SPIDER,
/* spawnflags */ MON_FLAG_MELEE | MON_FLAG_RANGED | MON_FLAG_RIDE,
/* mins,maxs  */ '-18 -18 -25', '18 18 30',
/* model      */ "spider.dpm",
/* netname    */ "spider",
/* fullname   */ _("Spider")
) {
#ifndef MENUQC
	this.monster_func = M_Spider;
	this.monster_func(MR_PRECACHE);
#endif
}

#ifdef SVQC
float autocvar_g_monster_spider_health;
float autocvar_g_monster_spider_damageforcescale = 0.6;
float autocvar_g_monster_spider_attack_bite_damage;
float autocvar_g_monster_spider_attack_bite_delay;
float autocvar_g_monster_spider_attack_web_damagetime;
float autocvar_g_monster_spider_attack_web_speed;
float autocvar_g_monster_spider_attack_web_speed_up;
float autocvar_g_monster_spider_attack_web_delay;
float autocvar_g_monster_spider_speed_stop;
float autocvar_g_monster_spider_speed_run;
float autocvar_g_monster_spider_speed_walk;

/*
const float spider_anim_idle		= 0;
const float spider_anim_walk		= 1;
const float spider_anim_attack		= 2;
const float spider_anim_attack2		= 3;
*/

.float spider_web_delay;

void M_Spider_Attack_Web_Explode()
{
	entity e;
	if(self)
	{
		Send_Effect(EFFECT_ELECTRO_IMPACT, self.origin, '0 0 0', 1);
		RadiusDamage(self, self.realowner, 0, 0, 25, world, world, 25, self.projectiledeathtype, world);

		for(e = findradius(self.origin, 25); e; e = e.chain) if(e != self) if(e.takedamage && e.deadflag == DEAD_NO) if(e.health > 0) if(e.monsterid != MON_SPIDER.monsterid)
			e.spider_slowness = time + (autocvar_g_monster_spider_attack_web_damagetime);

		remove(self);
	}
}

void M_Spider_Attack_Web_Touch()
{
	PROJECTILE_TOUCH;

	M_Spider_Attack_Web_Explode();
}

void M_Spider_Attack_Web()
{
	monster_makevectors(self.enemy);

	sound(self, CH_SHOTS, W_Sound("electro_fire2"), VOL_BASE, ATTEN_NORM);

	entity proj = spawn ();
	proj.classname = "plasma";
	proj.owner = proj.realowner = self;
	proj.use = M_Spider_Attack_Web_Explode;
	proj.think = adaptor_think2use_hittype_splash;
	proj.bot_dodge = true;
	proj.bot_dodgerating = 0;
	proj.nextthink = time + 5;
	PROJECTILE_MAKETRIGGER(proj);
	proj.projectiledeathtype = DEATH_MONSTER_SPIDER;
	setorigin(proj, CENTER_OR_VIEWOFS(self));

	//proj.glow_size = 50;
	//proj.glow_color = 45;
	proj.movetype = MOVETYPE_BOUNCE;
	W_SetupProjVelocity_Explicit(proj, v_forward, v_up, (autocvar_g_monster_spider_attack_web_speed), (autocvar_g_monster_spider_attack_web_speed_up), 0, 0, false);
	proj.touch = M_Spider_Attack_Web_Touch;
	setsize(proj, '-4 -4 -4', '4 4 4');
	proj.takedamage = DAMAGE_NO;
	proj.damageforcescale = 0;
	proj.health = 500;
	proj.event_damage = func_null;
	proj.flags = FL_PROJECTILE;
	proj.damagedbycontents = true;

	proj.bouncefactor = 0.3;
	proj.bouncestop = 0.05;
	proj.missile_flags = MIF_SPLASH | MIF_ARC;

	CSQCProjectile(proj, true, PROJECTILE_ELECTRO, true);
}

bool M_Spider_Attack(int attack_type)
{
	switch(attack_type)
	{
		case MONSTER_ATTACK_MELEE:
		{
			return Monster_Attack_Melee(self.enemy, (autocvar_g_monster_spider_attack_bite_damage), ((random() > 0.5) ? self.anim_melee : self.anim_shoot), self.attack_range, (autocvar_g_monster_spider_attack_bite_delay), DEATH_MONSTER_SPIDER, true);
		}
		case MONSTER_ATTACK_RANGED:
		{
			if(time >= self.spider_web_delay)
			{
				setanim(self, self.anim_shoot, true, true, true);
				self.attack_finished_single = time + (autocvar_g_monster_spider_attack_web_delay);
				self.anim_finished = time + 1;
				M_Spider_Attack_Web();
				self.spider_web_delay = time + 3;
				return true;
			}

			return false;
		}
	}

	return false;
}

void spawnfunc_monster_spider() { Monster_Spawn(MON_SPIDER.monsterid); }
#endif // SVQC

bool M_Spider(int req)
{
	switch(req)
	{
		#ifdef SVQC
		case MR_THINK:
		{
			return true;
		}
		case MR_PAIN:
		{
			return true;
		}
		case MR_DEATH:
		{
			setanim(self, self.anim_melee, false, true, true);
			self.angles_x = 180;
			return true;
		}
		#endif
		#ifndef MENUQC
		case MR_ANIM:
		{
			vector none = '0 0 0';
			self.anim_walk = animfixfps(self, '1 1 1', none);
			self.anim_idle = animfixfps(self, '0 1 1', none);
			self.anim_melee = animfixfps(self, '2 1 5', none); // analyze models and set framerate
			self.anim_shoot = animfixfps(self, '3 1 5', none); // analyze models and set framerate
			self.anim_run = animfixfps(self, '1 1 1', none);

			return true;
		}
		#endif
		#ifdef SVQC
		case MR_SETUP:
		{
			if(!self.health) self.health = (autocvar_g_monster_spider_health);
			if(!self.speed) { self.speed = (autocvar_g_monster_spider_speed_walk); }
			if(!self.speed2) { self.speed2 = (autocvar_g_monster_spider_speed_run); }
			if(!self.stopspeed) { self.stopspeed = (autocvar_g_monster_spider_speed_stop); }
			if(!self.damageforcescale) { self.damageforcescale = (autocvar_g_monster_spider_damageforcescale); }

			self.monster_loot = spawnfunc_item_health_medium;
			self.monster_attackfunc = M_Spider_Attack;

			return true;
		}
		case MR_PRECACHE:
		{
			precache_model("models/monsters/spider.dpm");
			precache_sound (W_Sound("electro_fire2"));
			return true;
		}
		#endif
	}

	return true;
}
