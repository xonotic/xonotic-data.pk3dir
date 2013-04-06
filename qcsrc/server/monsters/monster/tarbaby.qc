// size
const vector TARBABY_MIN = '-16 -16 -24';
const vector TARBABY_MAX = '16 16 16';

// cvars
float autocvar_g_monster_tarbaby;
float autocvar_g_monster_tarbaby_health;
float autocvar_g_monster_tarbaby_speed_walk;
float autocvar_g_monster_tarbaby_speed_run;

// animations
#define tarbaby_anim_walk		0
#define tarbaby_anim_run		1
#define tarbaby_anim_jump		2
#define tarbaby_anim_fly		3
#define tarbaby_anim_explode	4

void tarbaby_think ()
{
	self.think = tarbaby_think;
	self.nextthink = time + 0.1;
	
	monster_move(autocvar_g_monster_tarbaby_speed_run, autocvar_g_monster_tarbaby_speed_walk, 20, tarbaby_anim_run, tarbaby_anim_walk, tarbaby_anim_walk);
}

void Tar_JumpTouch ()
{
	// dunno why this would be called when dead, but to be safe
	if (self.health <= 0)
		return;
		
	if (other.takedamage)
	if (vlen(self.velocity) > 200)
	{
		// make the monster die
		self.event_damage(self, self, self.health + self.max_health, DEATH_MONSTER_TARBABY, self.origin, '0 0 0');
			
		return;
	}

	if (trace_dphitcontents)
	{
		if not(self.flags & FL_ONGROUND)
		{
			self.touch = MonsterTouch;
			self.flags |= FL_ONGROUND;
			self.movetype = MOVETYPE_WALK;
		}
	}
}

void tarbaby_jump ()
{
	if not(self.flags & FL_ONGROUND)
		return;
	self.frame = tarbaby_anim_jump;
	// dunno why this would be called when dead, but to be safe
	if (self.health <= 0)
		return;
	self.movetype = MOVETYPE_BOUNCE;
	self.touch = Tar_JumpTouch;
	makevectors (self.angles);
	self.origin_z += 1;
	self.velocity = v_forward * 600 + '0 0 200';
	self.velocity_z += random()*150;
	if (self.flags & FL_ONGROUND)
		self.flags -= FL_ONGROUND;
		
	self.attack_finished_single = time + 0.5;
}

float tbaby_jump ()
{
	tarbaby_jump();
	return TRUE;
}

void tarbaby_blowup ()
{
	float bigboom = 250 * (self.scale * 0.7);
	RadiusDamage(self, self, 250 * monster_skill, 15, bigboom * (monster_skill * 0.7), world, 250, DEATH_MONSTER_TARBABY, world);
	pointparticles(particleeffectnum(((self.scale > 3) ? "explosion_big" : "explosion_medium")), self.origin, '0 0 0', 1);
	sound(self, CH_SHOTS, "weapons/rocket_impact.wav", VOL_BASE, ATTN_NORM);
	
	Monster_CheckDropCvars ("tarbaby"); // drop items after exploding to prevent player picking up item before dying
	
	setmodel(self, "");
}

void tarbaby_explode()
{
	tarbaby_blowup();
	
	monster_hook_death(); // calling this next frame should be ok...
}

void tarbaby_die ()
{
	self.solid		  	= SOLID_NOT;
	self.takedamage	 	= DAMAGE_NO;
	self.event_damage   = func_null;
	self.movetype		= MOVETYPE_NONE;
	self.enemy		  	= world;
	self.think			= tarbaby_explode;
	self.nextthink		= time + 0.1;
}

void tarbaby_spawn ()
{
	if not(self.health)
		self.health = autocvar_g_monster_tarbaby_health * self.scale;
	
	self.damageforcescale   = 0.003;
	self.classname			= "monster_tarbaby";
	self.checkattack	 	= GenericCheckAttack;
	self.attack_ranged	  	= tbaby_jump;
	self.attack_melee	   	= tarbaby_jump;
	self.nextthink		  	= time + random() * 0.5 + 0.1;
	self.think			  	= tarbaby_think;
	self.sprite_height	  	= 20;
	self.frame				= tarbaby_anim_walk;
	
	monster_hook_spawn(); // for post-spawn mods
}

void spawnfunc_monster_tarbaby ()
{	
	if not(autocvar_g_monster_tarbaby) { remove(self); return; }
	
	self.monster_spawnfunc = spawnfunc_monster_tarbaby;
	
	if(self.spawnflags & MONSTERFLAG_APPEAR)
	{
		self.think = func_null;
		self.nextthink = -1;
		self.use = Monster_Appear;
		return;
	}
	
	self.scale = 1.3;
	
	if not (monster_initialize(
			 "Spawn",
			 "models/monsters/tarbaby.mdl",
			 TARBABY_MIN, TARBABY_MAX,
			 FALSE,
			 tarbaby_die, tarbaby_spawn))
	{
		remove(self);
		return;
	}
	
	precache_sound ("weapons/rocket_impact.wav");
}

// compatibility with old spawns
void spawnfunc_monster_spawn () { spawnfunc_monster_tarbaby(); }
