// size
const vector WIZARD_MIN = '-16 -16 -45';
const vector WIZARD_MAX = '16 16 16';

// model
string WIZARD_MODEL = "models/monsters/wizard.mdl";

#ifdef SVQC
// cvars
float autocvar_g_monster_wizard;
float autocvar_g_monster_wizard_health;
float autocvar_g_monster_wizard_speed_walk;
float autocvar_g_monster_wizard_speed_run;
float autocvar_g_monster_wizard_spike_damage;
float autocvar_g_monster_wizard_spike_edgedamage;
float autocvar_g_monster_wizard_spike_radius;
float autocvar_g_monster_wizard_spike_speed;

// animations
const float wizard_anim_hover 	= 0;
const float wizard_anim_fly 	= 1;
const float wizard_anim_magic 	= 2;
const float wizard_anim_pain 	= 3;
const float wizard_anim_death 	= 4;

void Wiz_FastExplode()
{
	self.event_damage = func_null;
	self.takedamage = DAMAGE_NO;
	RadiusDamage (self, self.realowner, autocvar_g_monster_wizard_spike_damage, autocvar_g_monster_wizard_spike_edgedamage, autocvar_g_monster_wizard_spike_radius, world, 0, self.projectiledeathtype, other);

	remove (self);
}

void Wiz_FastTouch ()
{
	if(other == self.owner)
		return;
		
	PROJECTILE_TOUCH;
		
	pointparticles(particleeffectnum("TE_WIZSPIKE"), self.origin, '0 0 0', 1);
	
	Wiz_FastExplode();
}

void Wiz_StartFast ()
{
	entity missile;
	vector dir = normalize((self.enemy.origin + '0 0 10') - self.origin);
	
	self.attack_finished_single = time + 0.2;
	
	self.v_angle = self.angles;
	makevectors (self.angles);

	missile = spawn ();
	missile.owner = missile.realowner = self;
	setsize (missile, '0 0 0', '0 0 0');		
	setorigin (missile, self.origin + v_forward * 14 + '0 0 30' + v_right * 14);
	missile.enemy = self.enemy;
	missile.nextthink = time + 3;
	missile.think = Wiz_FastExplode;
	missile.velocity = dir * autocvar_g_monster_wizard_spike_speed;
	missile.avelocity = '300 300 300';
	missile.solid = SOLID_BBOX;
	missile.movetype = MOVETYPE_FLYMISSILE;
	missile.touch = Wiz_FastTouch;
	missile.projectiledeathtype = DEATH_MONSTER_SCRAG;
	CSQCProjectile(missile, TRUE, PROJECTILE_CRYLINK, TRUE);
	
	missile = spawn ();
	missile.owner = missile.realowner = self;
	setsize (missile, '0 0 0', '0 0 0');		
	setorigin (missile, self.origin + v_forward * 14 + '0 0 30' + v_right * -14);
	missile.enemy = self.enemy;
	missile.nextthink = time + 3;
	missile.touch = Wiz_FastTouch;
	missile.solid = SOLID_BBOX;
	missile.movetype = MOVETYPE_FLYMISSILE;
	missile.think = Wiz_FastExplode;
	missile.velocity = dir * autocvar_g_monster_wizard_spike_speed;
	missile.avelocity = '300 300 300';
	missile.projectiledeathtype = DEATH_MONSTER_SCRAG;
	CSQCProjectile(missile, TRUE, PROJECTILE_CRYLINK, TRUE);
}

void wizard_think ()
{
	self.think = wizard_think;
	self.nextthink = time + self.ticrate;
	
	monster_move(autocvar_g_monster_wizard_speed_run, autocvar_g_monster_wizard_speed_walk, 300, wizard_anim_fly, wizard_anim_hover, wizard_anim_hover);
}

void wizard_fastattack ()
{
	Wiz_StartFast();
}

void wizard_die ()
{
	Monster_CheckDropCvars ("wizard");
	
	self.think 			= monster_dead_think;
	self.nextthink 		= time + self.ticrate;
	self.ltime 			= time + 5;
	self.velocity_x 	= -200 + 400 * random();
	self.velocity_y 	= -200 + 400 * random();
	self.velocity_z 	= 100 + 100 * random();
	
	monsters_setframe(wizard_anim_death);
	
	monster_hook_death(); // for post-death mods
}

float Wiz_Missile ()
{
	wizard_fastattack();
	return TRUE;
}

void wizard_spawn ()
{
	if not(self.health)
		self.health = autocvar_g_monster_wizard_health;
	
	self.classname			= "monster_wizard";
	self.checkattack	 	= GenericCheckAttack;
	self.attack_ranged	  	= Wiz_Missile;
	self.nextthink		  	= time + random() * 0.5 + 0.1;
	self.movetype		   	= MOVETYPE_FLY; // TODO: make it fly up/down
	self.flags			   |= FL_FLY;
	self.think			  	= wizard_think;
	
	monster_setupsounds("wizard");
	
	monster_hook_spawn(); // for post-spawn mods
}

void spawnfunc_monster_wizard ()
{	
	if not(autocvar_g_monster_wizard) { remove(self); return; }
	
	self.monster_spawnfunc = spawnfunc_monster_wizard;
	
	if(Monster_CheckAppearFlags(self))
		return;
	
	self.scale = 1.3;
	
	if not (monster_initialize(
			 "Scrag", MONSTER_SCRAG,
			 WIZARD_MIN, WIZARD_MAX,
			 TRUE,
			 wizard_die, wizard_spawn))
	{
		remove(self);
		return;
	}
}

// compatibility with old spawns
void spawnfunc_monster_scrag () { spawnfunc_monster_wizard(); }

#endif // SVQC
