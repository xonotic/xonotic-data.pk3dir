// size
const vector HELLKNIGHT_MIN = '-16 -16 -24';
const vector HELLKNIGHT_MAX = '16 16 32';

// cvars
float autocvar_g_monster_hellknight;
float autocvar_g_monster_hellknight_health;
float autocvar_g_monster_hellknight_melee_damage;
float autocvar_g_monster_hellknight_inferno_damage;
float autocvar_g_monster_hellknight_inferno_damagetime;
float autocvar_g_monster_hellknight_inferno_chance;
float autocvar_g_monster_hellknight_speed_walk;
float autocvar_g_monster_hellknight_speed_run;
float autocvar_g_monster_hellknight_fireball_damage;
float autocvar_g_monster_hellknight_fireball_force;
float autocvar_g_monster_hellknight_fireball_radius;
float autocvar_g_monster_hellknight_fireball_chance;
float autocvar_g_monster_hellknight_fireball_edgedamage;
float autocvar_g_monster_hellknight_spike_chance;
float autocvar_g_monster_hellknight_spike_force;
float autocvar_g_monster_hellknight_spike_radius;
float autocvar_g_monster_hellknight_spike_edgedamage;
float autocvar_g_monster_hellknight_spike_damage;
float autocvar_g_monster_hellknight_jump_chance;
float autocvar_g_monster_hellknight_jump_damage;
float autocvar_g_monster_hellknight_jump_dist;

// animations
#define hellknight_anim_stand 	0
#define hellknight_anim_walk 	1
#define hellknight_anim_run 	2
#define hellknight_anim_pain 	3
#define hellknight_anim_death1 	4
#define hellknight_anim_death2 	5
#define hellknight_anim_charge1 6
#define hellknight_anim_magic1 	7
#define hellknight_anim_magic2 	8
#define hellknight_anim_charge2 9
#define hellknight_anim_slice 	10
#define hellknight_anim_smash 	11
#define hellknight_anim_wattack 12
#define hellknight_anim_magic3 	13

void hknight_spike_think()
{
	if(self)
	{
		RadiusDamage (self, self.realowner, autocvar_g_monster_hellknight_spike_damage * self.realowner.scale, autocvar_g_monster_hellknight_spike_edgedamage, autocvar_g_monster_hellknight_spike_force, world, autocvar_g_monster_hellknight_spike_radius, DEATH_MONSTER_HKNIGHT_SPIKE, other);
		remove(self);
	}
}

void hknight_spike_touch()
{
	PROJECTILE_TOUCH;
	
	pointparticles(particleeffectnum("TE_WIZSPIKE"), self.origin, '0 0 0', 1);
	
	hknight_spike_think();
}

void() hellknight_think;
void hknight_shoot ()
{
	local	entity 	missile = world;
	local	vector	dir = normalize((self.enemy.origin + '0 0 10') - self.origin);
	local	float	dist = vlen (self.enemy.origin - self.origin), flytime = 0;

	flytime = dist * 0.002;
	if (flytime < 0.1)
		flytime = 0.1;

	self.effects |= EF_MUZZLEFLASH;
	sound (self, CHAN_WEAPON, "weapons/spike.wav", 1, ATTN_NORM);

	missile = spawn ();
	missile.owner = missile.realowner = self;
	missile.solid = SOLID_TRIGGER;
	missile.movetype = MOVETYPE_FLYMISSILE;
	setsize (missile, '0 0 0', '0 0 0');		
	setorigin(missile, self.origin + '0 0 10' + v_forward * 14);
	missile.scale = self.scale;
	missile.flags = FL_PROJECTILE;
	missile.velocity = dir * 400;
	missile.avelocity = '300 300 300';
	missile.nextthink = time + 5;
	missile.think = hknight_spike_think;
	missile.enemy = self.enemy;
	missile.touch = hknight_spike_touch;
	CSQCProjectile(missile, TRUE, PROJECTILE_CRYLINK, TRUE);
}

void hknight_inferno ()
{
	traceline((self.absmin + self.absmax) * 0.5, (self.enemy.absmin + self.enemy.absmax) * 0.5, TRUE, world);
	if (trace_fraction != 1)
		return; // not visible
	if(enemy_range() <= 2000)
		Fire_AddDamage(self.enemy, self, autocvar_g_monster_hellknight_inferno_damage * monster_skill, autocvar_g_monster_hellknight_inferno_damagetime, DEATH_MONSTER_HKNIGHT_INFERNO);
}

void hknight_infernowarning ()
{
	if(!self.enemy)
		return;
		
	traceline((self.absmin + self.absmax) * 0.5, (self.enemy.absmin + self.enemy.absmax) * 0.5, TRUE, world);
	if (trace_fraction != 1)
		return; // not visible
	self.enemy.effects |= EF_MUZZLEFLASH;
	sound(self.enemy, CHAN_AUTO, "player/lava.wav", 1, ATTN_NORM);
	
	hknight_inferno();
}

float() hknight_magic;
float hknight_checkmagic ()
{
	local vector v1 = '0 0 0', v2 = '0 0 0';
	local float dot = 0;

	// use magic to kill zombies as they heal too fast for sword
	if (self.enemy.classname == "monster_zombie")
	{
		traceline((self.absmin + self.absmax) * 0.5, (self.enemy.absmin + self.enemy.absmax) * 0.5, FALSE, self);
		if (trace_ent == self.enemy)
		{
			hknight_magic();
			return TRUE;
		}
	}

	if (random() < 0.25)
		return FALSE; // 25% of the time it won't do anything
	v1 = normalize(self.enemy.velocity);
	v2 = normalize(self.enemy.origin - self.origin);
	dot = v1 * v2;
	if (dot >= 0.7) // moving away
	if (vlen(self.enemy.velocity) >= 150) // walking/running away
		return hknight_magic();
	return FALSE;
}

void() hellknight_charge;
void CheckForCharge ()
{
	// check for mad charge
	if (time < self.attack_finished_single)
		return;
	if (fabs(self.origin_z - self.enemy.origin_z) > 20)
		return;		// too much height change
	if (vlen (self.origin - self.enemy.origin) < 80)
		return;		// use regular attack
	if (hknight_checkmagic())
		return; // chose magic

	// charge
	hellknight_charge();
}

void CheckContinueCharge ()
{
	if(hknight_checkmagic())
		return; // chose magic
	if(time >= self.attack_finished_single)
	{
		hellknight_think();
		return;		// done charging
	}
}

void hellknight_think ()
{
	self.think = hellknight_think;
	self.nextthink = time + 0.1;
	
	monster_move(autocvar_g_monster_hellknight_speed_run, autocvar_g_monster_hellknight_speed_walk, 100, hellknight_anim_run, hellknight_anim_walk, hellknight_anim_stand);
}

.float hknight_cycles;
void hellknight_magic ()
{
	self.hknight_cycles += 1;
	self.think = hellknight_magic;
	
	if(self.hknight_cycles >= 5)
	{
		self.frame = hellknight_anim_magic1;
		self.attack_finished_single = time + 0.7;
		hknight_infernowarning();
		self.think = hellknight_think;
	}
	
	self.nextthink = time + 0.1;
}

void hknight_fireball_explode(entity targ)
{
	float scle = self.realowner.scale;
	if(self)
	{
		RadiusDamage (self, self.realowner, autocvar_g_monster_hellknight_fireball_damage * scle, autocvar_g_monster_hellknight_fireball_edgedamage * scle, autocvar_g_monster_hellknight_fireball_force * scle, world, autocvar_g_monster_hellknight_fireball_radius * scle, self.projectiledeathtype, targ);
		if(targ)
			Fire_AddDamage(targ, self, 5 * monster_skill, autocvar_g_monster_hellknight_inferno_damagetime, self.projectiledeathtype);
		remove(self);
	}
}

void hknight_fireball_think()
{
	hknight_fireball_explode(world);
}

void hknight_fireball_touch()
{
	PROJECTILE_TOUCH;
	
	hknight_fireball_explode(other);
}

void hellknight_fireball ()
{
	local	entity 	missile = spawn();
	local	vector	dir = normalize((self.enemy.origin + '0 0 10') - self.origin);
	vector fmins = ((self.scale >= 2) ? '-16 -16 -16' : '-4 -4 -4'), fmaxs = ((self.scale >= 2) ? '16 16 16' : '4 4 4');

	self.effects |= EF_MUZZLEFLASH;
	sound (self, CHAN_WEAPON, "weapons/fireball2.wav", 1, ATTN_NORM);

	missile.owner = missile.realowner = self;
	missile.solid = SOLID_TRIGGER;
	missile.movetype = MOVETYPE_FLYMISSILE;
	self.projectiledeathtype = DEATH_MONSTER_HKNIGHT_FBALL;
	setsize (missile, fmins, fmaxs);		
	setorigin(missile, self.origin + '0 0 10' + v_forward * 14);
	missile.flags = FL_PROJECTILE;
	missile.velocity = dir * 400;
	missile.avelocity = '300 300 300';
	missile.nextthink = time + 5;
	missile.think = hknight_fireball_think;
	missile.enemy = self.enemy;
	missile.touch = hknight_fireball_touch;
	CSQCProjectile(missile, TRUE, ((self.scale >= 2) ? PROJECTILE_FIREBALL : PROJECTILE_FIREMINE), TRUE);
	
	self.delay = -1;
}

void hellknight_magic2 ()
{
	self.frame = hellknight_anim_magic2;
	self.attack_finished_single = time + 1.2;
	self.delay = time + 0.4;
	self.monster_delayedattack = hellknight_fireball;
}

void hellknight_spikes ()
{
	self.think = hellknight_spikes;
	self.nextthink = time + 0.1;
	self.hknight_cycles += 1;
	hknight_shoot();
	if(self.hknight_cycles >= 7)
		self.think = hellknight_think;
}

void hellknight_magic3 ()
{
	self.frame = hellknight_anim_magic3;
	self.attack_finished_single = time + 1;
	self.think = hellknight_spikes;
	self.nextthink = time + 0.4;
}

void hellknight_charge ()
{
	self.frame = hellknight_anim_charge1;
	self.attack_finished_single = time + 0.5;
	
	hknight_checkmagic();
	monster_melee(self.enemy, autocvar_g_monster_hellknight_melee_damage, 70, DEATH_MONSTER_HKNIGHT_MELEE);
	hknight_checkmagic();
}

void hellknight_charge2 ()
{
	self.frame = hellknight_anim_charge2;
	self.attack_finished_single = time + 0.5;
	
	CheckContinueCharge ();
	monster_melee(self.enemy, autocvar_g_monster_hellknight_melee_damage, 70, DEATH_MONSTER_HKNIGHT_MELEE);
}

void hellknight_slice ()
{
	self.frame = hellknight_anim_slice;
	self.attack_finished_single = time + 0.7;
	monster_melee(self.enemy, autocvar_g_monster_hellknight_melee_damage, 70, DEATH_MONSTER_HKNIGHT_MELEE);
}

void hellknight_smash ()
{
	self.frame = hellknight_anim_smash;
	self.attack_finished_single = time + 0.7;
	monster_melee(self.enemy, autocvar_g_monster_hellknight_melee_damage, 70, DEATH_MONSTER_HKNIGHT_MELEE);
}

void hellknight_weapon_attack ()
{
	self.frame = hellknight_anim_wattack;
	self.attack_finished_single = time + 0.7;
	monster_melee(self.enemy, autocvar_g_monster_hellknight_melee_damage, 70, DEATH_MONSTER_HKNIGHT_MELEE);
}

float hknight_type;
void hknight_melee ()
{
	hknight_type += 1;

	if (hknight_type == 1)
		hellknight_slice();
	else if (hknight_type == 2)
		hellknight_smash();
	else
	{
		hellknight_weapon_attack();
		hknight_type = 0;
	}
}

float hknight_magic ()
{
	if not(self.flags & FL_ONGROUND)
		return FALSE;
		
	if not(self.enemy)
		return FALSE; // calling attack check with no enemy?!
		
	if(time < self.attack_finished_single)
		return FALSE;
		
	self.hknight_cycles = 0;

	if (self.enemy.classname == "monster_zombie")
	{
		// always use fireball to kill zombies
		hellknight_magic2();
		self.attack_finished_single = time + 2;
		return TRUE;
	}
	RandomSelection_Init();
	RandomSelection_Add(world, 0, "fireball", autocvar_g_monster_hellknight_fireball_chance, 1);
	RandomSelection_Add(world, 0, "inferno", autocvar_g_monster_hellknight_inferno_chance, 1);
	RandomSelection_Add(world, 0, "spikes", autocvar_g_monster_hellknight_spike_chance, 1);
	if(self.health >= 100)
		RandomSelection_Add(world, 0, "jump", ((enemy_range() > autocvar_g_monster_hellknight_jump_dist * self.scale) ? 1 : autocvar_g_monster_hellknight_jump_chance), 1);
	
	switch(RandomSelection_chosen_string)
	{
		case "fireball":
		{
			hellknight_magic2();
			self.attack_finished_single = time + 2;
			return TRUE;
		}
		case "spikes":
		{
			hellknight_magic3();
			self.attack_finished_single = time + 3;
			return TRUE;
		}
		case "inferno":
		{
			hellknight_magic();
			self.attack_finished_single = time + 3;
			return TRUE;
		}
		case "jump":
		{
			if (enemy_range() >= 400)
			if (findtrajectorywithleading(self.origin, self.mins, self.maxs, self.enemy, 1000, 0, 10, 0, self))
			{
				self.velocity = findtrajectory_velocity;
				Damage(self.enemy, self, self, autocvar_g_monster_hellknight_jump_damage * monster_skill, DEATH_MONSTER_HKNIGHT_CRUSH, self.enemy.origin, normalize(self.enemy.origin - self.origin));
				self.attack_finished_single = time + 2;
				return TRUE;
			}
			return FALSE;
		}
		default:
			return FALSE;
	}
	// never get here
}

void hellknight_die ()
{
	float chance = random();
	Monster_CheckDropCvars ("hellknight");
	
	self.solid		  	= SOLID_NOT;
	self.takedamage	 	= DAMAGE_NO;
	self.event_damage   = func_null;
	self.enemy		  	= world;
	self.movetype		= MOVETYPE_TOSS;
	self.think			= Monster_Fade;
	self.nextthink	  	= time + 2.1;
	
	if(chance < 0.10 || self.flags & MONSTERFLAG_MINIBOSS)
	{
		self.superweapons_finished = time + autocvar_g_balance_superweapons_time + 5; // give the player a few seconds to find the weapon
		W_ThrowNewWeapon(self, WEP_FIREBALL, 0, self.origin, self.velocity);
	}
	
	if (random() > 0.5)
		self.frame = hellknight_anim_death1;
	else
		self.frame = hellknight_anim_death2;
		
	monster_hook_death(); // for post-death mods
}

void hellknight_spawn ()
{
	if not(self.health)
		self.health = autocvar_g_monster_hellknight_health * self.scale;

	self.damageforcescale   = 0.003;
	self.classname			= "monster_hellknight";
	self.checkattack	 	= GenericCheckAttack;
	self.attack_melee	   	= hknight_melee;
	self.attack_ranged	  	= hknight_magic;
	self.nextthink		  	= time + random() * 0.5 + 0.1;
	self.think			  	= hellknight_think;
	self.sprite_height	  	= 30 * self.scale;
	self.frame				= hellknight_anim_stand;
	
	monster_hook_spawn(); // for post-spawn mods
}

void spawnfunc_monster_hell_knight ()
{	
	if not(autocvar_g_monster_hellknight) { remove(self); return; }
	
	self.monster_spawnfunc = spawnfunc_monster_hell_knight;
	
	if(self.spawnflags & MONSTERFLAG_APPEAR)
	{
		self.think = func_null;
		self.nextthink = -1;
		self.use = Monster_Appear;
		return;
	}
	
	self.scale = 1.3;
	
	if not (monster_initialize(
			 "Hell-knight",
			 "models/monsters/hknight.mdl",
			 HELLKNIGHT_MIN, HELLKNIGHT_MAX,
			 FALSE,
			 hellknight_die, hellknight_spawn))
	{
		remove(self);
		return;
	}
	
	precache_sound ("weapons/spike.wav");
}

// compatibility with old spawns
void spawnfunc_monster_hellknight () { spawnfunc_monster_hell_knight(); }
