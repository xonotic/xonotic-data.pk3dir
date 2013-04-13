#ifndef MENUQC
// size
const vector SHAMBLER_MIN = '-32 -32 -24';
const vector SHAMBLER_MAX = '32 32 64';

// model
string SHAMBLER_MODEL = "models/monsters/shambler.mdl";

#endif

#ifdef SVQC
// cvars
float autocvar_g_monster_shambler;
float autocvar_g_monster_shambler_health;
float autocvar_g_monster_shambler_damage;
float autocvar_g_monster_shambler_attack_lightning_damage;
float autocvar_g_monster_shambler_attack_claw_damage;
float autocvar_g_monster_shambler_speed_walk;
float autocvar_g_monster_shambler_speed_run;

// animations
const float shambler_anim_stand 	= 0;
const float shambler_anim_walk 		= 1;
const float shambler_anim_run 		= 2;
const float shambler_anim_smash 	= 3;
const float shambler_anim_swingr 	= 4;
const float shambler_anim_swingl 	= 5;
const float shambler_anim_magic 	= 6;
const float shambler_anim_pain 		= 7;
const float shambler_anim_death 	= 8;

void shambler_think ()
{
	self.think = shambler_think;
	self.nextthink = time + self.ticrate;
	
	monster_move(autocvar_g_monster_shambler_speed_run, autocvar_g_monster_shambler_speed_walk, 300, shambler_anim_run, shambler_anim_walk, shambler_anim_stand);
}

void shambler_smash ()
{
	float bigdmg = autocvar_g_monster_shambler_damage * self.scale;
	
	self.think = shambler_think;
	self.attack_finished_single = time + 0.4;
	self.nextthink = self.attack_finished_single;

	if (!self.enemy)
		return;

	if (vlen(self.enemy.origin - self.origin) > 100 * self.scale)
		return;
	
	Damage(self.enemy, self, self, bigdmg * monster_skill, DEATH_MONSTER_SHAMBLER_SMASH, self.enemy.origin, normalize(self.enemy.origin - self.origin));
}

void shambler_delayedsmash ()
{
	monsters_setframe(shambler_anim_smash);
	self.think = shambler_smash;
	self.nextthink = time + 0.7;
}

void ShamClaw (float side)
{
	monster_melee(self.enemy, autocvar_g_monster_shambler_attack_claw_damage, 0.3, DEATH_MONSTER_SHAMBLER_CLAW, TRUE);
}

void() shambler_swing_right;
void shambler_swing_left ()
{
	monsters_setframe(shambler_anim_swingl);
	ShamClaw(250);
	self.attack_finished_single = time + 0.8;
	self.nextthink = self.attack_finished_single;
	self.think = shambler_think;
	if(random() < 0.5)
		self.think = shambler_swing_right;
}

void shambler_swing_right ()
{
	monsters_setframe(shambler_anim_swingr);
	ShamClaw(-250);
	self.attack_finished_single = time + 0.8;
	self.nextthink = self.attack_finished_single;
	self.think = shambler_think;
	if(random() < 0.5)
		self.think = shambler_swing_left;
}

void sham_melee ()
{
	local float chance = random();

	if (chance > 0.6)
		shambler_delayedsmash();
	else if (chance > 0.3)
		shambler_swing_right ();
	else
		shambler_swing_left ();
}

void CastLightning ()
{
	self.monster_delayedattack = func_null;
	self.delay = -1;

	local vector org = '0 0 0', dir = '0 0 0';
	vector v = '0 0 0';

	self.effects |= EF_MUZZLEFLASH;

	org = self.origin + '0 0 40' * self.scale;

	dir = self.enemy.origin + '0 0 16' - org;
	dir = normalize (dir);

	traceline (org, self.origin + dir * 1000, TRUE, self);
		
	FireRailgunBullet (org, org + dir * 1000, autocvar_g_monster_shambler_attack_lightning_damage * monster_skill, 0, 0, 0, 0, 0, DEATH_MONSTER_SHAMBLER_ZAP);
	
	// teamcolor / hit beam effect
	v = WarpZone_UnTransformOrigin(WarpZone_trace_transform, trace_endpos);
	WarpZone_TrailParticles(world, particleeffectnum("TE_TEI_G3"), org, v);
}

void shambler_magic ()
{
	monsters_setframe(shambler_anim_magic);
	self.attack_finished_single = time + 1.1;
	self.monster_delayedattack = CastLightning;
	self.delay = time + 0.6;
}
	
float sham_lightning ()
{
	shambler_magic();
	return TRUE;
}

void shambler_die ()
{
	Monster_CheckDropCvars ("shambler");
	
	self.think = Monster_Fade;
	self.nextthink = time + 5;
	monsters_setframe(shambler_anim_death);
	
	monster_hook_death(); // for post-death mods
}

void shambler_spawn ()
{
	if not(self.health)
		self.health = autocvar_g_monster_shambler_health * self.scale;

	self.damageforcescale   = 0.003;
	self.classname			= "monster_shambler";
	self.attack_melee		= sham_melee;
	self.checkattack	 	= GenericCheckAttack;
	self.attack_ranged	  	= sham_lightning;
	self.nextthink		 	= time + random() * 0.5 + 0.1;
	self.think			  	= shambler_think;
	self.sprite_height	  	= 70;
	self.weapon				= WEP_NEX;
	
	monsters_setframe(shambler_anim_stand);
	
	monster_setupsounds("shambler");
	
	monster_hook_spawn(); // for post-spawn mods
}

void spawnfunc_monster_shambler ()
{	
	if not(autocvar_g_monster_shambler) { remove(self); return; }
	
	self.monster_spawnfunc = spawnfunc_monster_shambler;
	
	if(Monster_CheckAppearFlags(self))
		return;
	
	self.scale = 1.3;
	
	if not (monster_initialize(
			 "Shambler", MONSTER_SHAMBLER,
			 SHAMBLER_MIN, SHAMBLER_MAX,
			 FALSE,
			 shambler_die, shambler_spawn))
	{
		remove(self);
		return;
	}
}

#endif // SVQC
