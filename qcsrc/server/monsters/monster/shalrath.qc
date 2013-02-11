// size
const vector SHALRATH_MIN = '-32 -32 -24';
const vector SHALRATH_MAX = '32 32 32';

// cvars
float autocvar_g_monster_shalrath;
float autocvar_g_monster_shalrath_health;
float autocvar_g_monster_shalrath_damage;
float autocvar_g_monster_shalrath_speed;

// animations
#define shalrath_anim_attack 	0
#define shalrath_anim_pain 		1
#define shalrath_anim_death 	2
#define shalrath_anim_walk 		3

void() ShalMissile;

void shalrath_think ()
{
	self.think = shalrath_think;
	self.nextthink = time + 0.1;
	
	if(self.delay != -1)
		self.nextthink = self.delay;
	
	monster_move(autocvar_g_monster_shalrath_speed, autocvar_g_monster_shalrath_speed, 50, shalrath_anim_walk, shalrath_anim_walk, shalrath_anim_walk);
}

void shalrath_attack ()
{
	self.frame = shalrath_anim_attack;
	self.delay = time + 0.1;
	self.attack_finished_single = time + 0.7;
	self.monster_delayedattack = ShalMissile;
}

void shalrathattack_melee ()
{
	float bigdmg = 0, rdmg = autocvar_g_monster_shalrath_damage * random();

	bigdmg = rdmg * self.scale;

	monster_melee(self.enemy, bigdmg * monster_skill, 120, DEATH_MONSTER_SHALRATH_MELEE);
}

void shalrath_attack_melee ()
{
	self.monster_delayedattack = shalrathattack_melee;
	self.delay = time + 0.2;
	self.frame = shalrath_anim_attack;
	self.attack_finished_single = time + 0.7;
}

float shal_missile ()
{
	// don't throw if it is blocked
	traceline(self.origin + '0 0 10', self.enemy.origin + '0 0 10', FALSE, self);
	if (enemy_range() > 1000)
		return FALSE;
	if (trace_ent != self.enemy)
		return FALSE;
	shalrath_attack();
	return TRUE;
}

.float shal_cycles;
void ShalHome ()
{
	local vector dir = '0 0 0', vtemp = self.enemy.origin + '0 0 10';
	
	self.shal_cycles += 1;
	if (self.enemy.health <= 0 || self.owner.health <= 0 || self.shal_cycles >= 20)
	{
		remove(self);
		return;
	}
	dir = normalize(vtemp - self.origin);
	UpdateCSQCProjectile(self);
	if (monster_skill == 3)
		self.velocity = dir * 350;
	else
		self.velocity = dir * 250;
	self.nextthink = time + 0.2;
	self.think = ShalHome;	
}

void ShalMissile ()
{
	local	entity 	missile = world;
	local	vector	dir = '0 0 0';
	local	float	dist = 0;
	
	self.effects |= EF_MUZZLEFLASH;

	sound (self, CHAN_WEAPON, "weapons/spike.wav", 1, ATTN_NORM);

	missile = spawn ();
	missile.owner = missile.realowner = self;
	
	self.v_angle = self.angles;
	makevectors (self.angles);
	
	dir = normalize((self.enemy.origin + '0 0 10') - self.origin);
	dist = vlen (self.enemy.origin - self.origin);

	missile.think = ShalHome;
	missile.nextthink = time;
	missile.solid = SOLID_BBOX;
	missile.movetype = MOVETYPE_FLYMISSILE;
	missile.flags = FL_PROJECTILE;
	setorigin (missile, self.origin + v_forward * 14 + '0 0 30' + v_right * -14);
	setsize (missile, '0 0 0', '0 0 0');	
	missile.velocity = dir * 400;
	missile.avelocity = '300 300 300';
	missile.enemy = self.enemy;
	missile.touch = W_Plasma_TouchExplode;
	
	CSQCProjectile(missile, TRUE, PROJECTILE_CRYLINK, TRUE);
}

float ShalrathCheckAttack ()
{
	local vector spot1 = '0 0 0', spot2 = '0 0 0';
	local entity targ = self.enemy;

	if (self.health <= 0 || targ == world || targ.health < 1)
		return FALSE;
	
	if(self.monster_delayedattack && self.delay != -1)
	{
		if(time < self.delay)
			return FALSE;
			
		self.monster_delayedattack();
		self.delay = -1;
		self.monster_delayedattack = func_null;
	}
	
	if(time < self.attack_finished_single)
		return FALSE;
	
	if (vlen(self.enemy.origin - self.origin) <= 120)
	{	// melee attack
		if (self.attack_melee)
		{
			self.attack_melee();
			return TRUE;
		}
	}

	if (vlen(targ.origin - self.origin) >= 2000) // long traces are slow
		return FALSE;

// see if any entities are in the way of the shot
	spot1 = self.origin + '0 0 10';
	spot2 = targ.origin + '0 0 10';

	traceline (spot1, spot2, FALSE, self);

	if (trace_ent != targ && trace_fraction < 1)
		return FALSE; // don't have a clear shot

	//if (trace_inopen && trace_inwater)
	//	return FALSE; // sight line crossed contents

	if (random() < 0.2)
	if (self.attack_ranged())
		return TRUE;

	return FALSE;
}

void shalrath_die ()
{
	Monster_CheckDropCvars ("shalrath");
	
	self.think		  	= Monster_Fade;
	self.frame			= shalrath_anim_death;
	self.solid		  	= SOLID_NOT;
	self.takedamage	 	= DAMAGE_NO;
	self.event_damage   = func_null;
	self.enemy		  	= world;
	self.nextthink	  	= time + 2.1;
	self.pain_finished  = self.nextthink;	
	self.movetype		= MOVETYPE_TOSS;
	
	monster_hook_death(); // for post-death mods
}

void shalrath_spawn ()
{
	if not(self.health)
		self.health = autocvar_g_monster_shalrath_health * self.scale;

	self.damageforcescale   = 0.003;
	self.classname			= "monster_shalrath";
	self.checkattack	 	= ShalrathCheckAttack;
	self.attack_ranged	  	= shal_missile;
	self.attack_melee		= shalrath_attack_melee;
	self.nextthink		  	= time + random() * 0.5 + 0.1;
	self.think			  	= shalrath_think;
	self.frame				= shalrath_anim_walk;
	self.sprite_height	  	= 40 * self.scale;
	
	monster_hook_spawn(); // for post-spawn mods
}

void spawnfunc_monster_shalrath ()
{	
	if not(autocvar_g_monster_shalrath) { remove(self); return; }
	
	self.monster_spawnfunc = spawnfunc_monster_shalrath;
	
	if(self.spawnflags & MONSTERFLAG_APPEAR)
	{
		self.think = func_null;
		self.nextthink = -1;
		self.use = Monster_Appear;
		
		return;
	}
	
	self.scale = 1.3;
	
	if not (monster_initialize(
			 "Vore",
			 "models/monsters/shalrath.mdl",
			 SHALRATH_MIN, SHALRATH_MAX,
			 FALSE,
			 shalrath_die, shalrath_spawn))
	{
		remove(self);
		return;
	}
}

// compatibility with old spawns
void spawnfunc_monster_vore () { spawnfunc_monster_shalrath(); }
