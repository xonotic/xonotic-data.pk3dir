#ifndef MENUQC
// size
const vector ENFORCER_MIN = '-32 -32 0';
const vector ENFORCER_MAX = '32 32 64';

// model
string ENFORCER_MODEL = "models/turrets/ewheel-base2.md3";

#endif

#ifdef SVQC
// cvars
float autocvar_g_monster_enforcer;
float autocvar_g_monster_enforcer_health;
float autocvar_g_monster_enforcer_speed_walk;
float autocvar_g_monster_enforcer_speed_run;
float autocvar_g_monster_enforcer_attack_uzi_bullets;

// animations
const float enforcer_anim_stop 		= 0;
const float enforcer_anim_walk 		= 1;
const float enforcer_anim_run 		= 2;
const float enforcer_anim_walkback 	= 3;
const float enforcer_anim_runback 	= 4;

void enforcer_think ()
{
	self.think = enforcer_think;
	self.nextthink = time + self.ticrate;
	
	if(self.delay != -1)
		self.nextthink = self.delay;
	
	monster_move(autocvar_g_monster_enforcer_speed_run, autocvar_g_monster_enforcer_speed_walk, 100, enforcer_anim_run, enforcer_anim_walk, enforcer_anim_stop);
}

.float enf_cycles;
void enforcer_uzi_fire ()
{
	self.enf_cycles += 1;
	
	if(self.enf_cycles > autocvar_g_monster_enforcer_attack_uzi_bullets)
	{
		self.monster_delayedattack = func_null;
		self.delay = -1;
		return;
	}
	W_UZI_Attack(DEATH_MONSTER_ENFORCER);
	self.delay = time + 0.1;
	self.monster_delayedattack = enforcer_uzi_fire;
}

float enforcer_attack()
{
	makevectors(self.angles);
	switch(self.weapon)
	{
		case WEP_ROCKET_LAUNCHER:
		{
			self.attack_finished_single = time + 0.8;
			W_Rocket_Attack();
			return TRUE;
		}
		case WEP_ELECTRO:
		{
			self.attack_finished_single = time + 0.8;
			W_Electro_Attack();
			return TRUE;
		}
		case WEP_SHOTGUN:
		{
			self.attack_finished_single = time + 0.8;
			W_Shotgun_Attack();
			return TRUE;
		}
		case WEP_UZI:
		{
			self.enf_cycles = 0;
			self.attack_finished_single = time + 0.8;
			self.delay = time + 0.1;
			self.monster_delayedattack = enforcer_uzi_fire;
			return TRUE;
		}
		case WEP_LASER:
		{
			self.attack_finished_single = time + 0.8;
			W_Laser_Attack(0);
		}
		default:
			return FALSE; // no weapon?
	}
	
	// never gets here
}

void enforcer_die ()
{
	Monster_CheckDropCvars ("enforcer");
	
	self.think = Monster_Fade;
	self.nextthink = time + 5;
	monsters_setframe(enforcer_anim_stop);
		
	monster_hook_death(); // for post-death mods
}

void enforcer_spawn ()
{
	if not(self.health)
		self.health = autocvar_g_monster_enforcer_health * self.scale;

	self.damageforcescale   = 0;
	self.classname			= "monster_enforcer";
	self.checkattack	 	= GenericCheckAttack;
	self.nextthink		  	= time + random() * 0.5 + 0.1;
	self.think			  	= enforcer_think;
	self.items				= (IT_SHELLS | IT_ROCKETS | IT_NAILS | IT_CELLS);
	self.sprite_height	  	= 45;
	self.attack_ranged		= enforcer_attack;
	self.view_ofs		   *= 0.5;
	
	monsters_setframe(enforcer_anim_stop);
	
	setmodel(self, ENFORCER_MODEL); // for weapon entity
	
	self.weaponentity = spawn();
	self.weaponentity.owner = self;
	self.weaponentity.team = self.team;
	self.weaponentity.solid = SOLID_NOT;
	self.weaponentity.owner = self.weaponentity.realowner = self;
	self.weaponentity.movetype = MOVETYPE_NOCLIP;
	setmodel(self.weaponentity, "models/turrets/ewheel-gun1.md3");
	setattachment(self.weaponentity, self, "tag_head");
	
	RandomSelection_Init();
	RandomSelection_Add(world, WEP_ROCKET_LAUNCHER, "", 1, 1);
	RandomSelection_Add(world, WEP_ELECTRO, "", 1, 1);
	RandomSelection_Add(world, WEP_SHOTGUN, "", 1, 1);
	RandomSelection_Add(world, WEP_UZI, "", 1, 1);
	RandomSelection_Add(world, WEP_LASER, "", 1, 1);
	
	self.weapon = RandomSelection_chosen_float;
		
	monster_hook_spawn(); // for post-spawn mods
}

void spawnfunc_monster_enforcer ()
{	
	if not(autocvar_g_monster_enforcer) { remove(self); return; }
	
	self.monster_spawnfunc = spawnfunc_monster_enforcer;
	
	if(Monster_CheckAppearFlags(self))
		return;
		
	precache_model("models/turrets/ewheel-gun1.md3");
	precache_model(ENFORCER_MODEL);
	
	if not (monster_initialize(
			 "Enforcer", MONSTER_ENFORCER,
			 ENFORCER_MIN, ENFORCER_MAX,
			 FALSE,
			 enforcer_die, enforcer_spawn))
	{
		remove(self);
		return;
	}
}

#endif // SVQC
