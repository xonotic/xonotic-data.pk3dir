// size
const vector SHALRATH_MIN = '-36 -36 -24';
const vector SHALRATH_MAX = '36 36 50';

// model
string SHALRATH_MODEL = "models/monsters/mage.dpm";

#ifdef SVQC
// cvars
float autocvar_g_monster_shalrath;
float autocvar_g_monster_shalrath_health;
float autocvar_g_monster_shalrath_speed;
float autocvar_g_monster_shalrath_attack_spike_damage;
float autocvar_g_monster_shalrath_attack_spike_radius;
float autocvar_g_monster_shalrath_attack_spike_delay;
float autocvar_g_monster_shalrath_attack_melee_damage;
float autocvar_g_monster_shalrath_attack_melee_delay;
float autocvar_g_monster_shalrath_heal_self;
float autocvar_g_monster_shalrath_heal_friends;
float autocvar_g_monster_shalrath_heal_minhealth;
float autocvar_g_monster_shalrath_heal_range;
float autocvar_g_monster_shalrath_heal_delay;
float autocvar_g_monster_shalrath_shield_time;
float autocvar_g_monster_shalrath_shield_delay;
float autocvar_g_monster_shalrath_shield_blockpercent;
float autocvar_g_monster_shalrath_attack_grenade_damage;
float autocvar_g_monster_shalrath_attack_grenade_edgedamage;
float autocvar_g_monster_shalrath_attack_grenade_radius;
float autocvar_g_monster_shalrath_attack_grenade_lifetime;
float autocvar_g_monster_shalrath_attack_grenade_force;
float autocvar_g_monster_shalrath_attack_grenade_chance;

// animations
const float shalrath_anim_idle		= 0;
const float shalrath_anim_walk 		= 1;
const float shalrath_anim_attack 	= 2;
const float shalrath_anim_pain 		= 3;
const float shalrath_anim_death 	= 4;
const float shalrath_anim_run		= 5;

void() ShalMissile;
float() shal_missile;
void() shalrath_heal;
void() shalrath_shield;
void() shalrath_shield_die;

void shalrath_think ()
{
	entity head;
	float friend_needshelp = FALSE;
	
	FOR_EACH_PLAYER(head)
	{
		if not(IsDifferentTeam(head, self))
		if(head.health > 0)
		if(vlen(head.origin - self.origin) < autocvar_g_monster_shalrath_heal_range)
		if((!g_minstagib && head.health < autocvar_g_balance_health_regenstable) || (g_minstagib && head.ammo_cells < start_ammo_cells))
		{
			friend_needshelp = TRUE;
			break; // found 1 player near us who is low on health
		}
	}
	FOR_EACH_MONSTER(head)
	{
		if not(IsDifferentTeam(head, self))
		if(head.health > 0)
		if(vlen(head.origin - self.origin) < autocvar_g_monster_shalrath_heal_range)
		if(head.health < head.max_health)
		{
			friend_needshelp = TRUE;
			break; // found 1 player near us who is low on health
		}
	}
	
	self.think = shalrath_think;
	self.nextthink = time + self.ticrate;
	
	if(self.weaponentity)
	if(time >= self.weaponentity.ltime)
		shalrath_shield_die();
		
	if(self.health < autocvar_g_monster_shalrath_heal_minhealth || friend_needshelp)
	if(time >= self.attack_finished_single)
	if(random() < 0.5)
		shalrath_heal();
		
	if(self.enemy)
	if(self.health < self.max_health)
	if(time >= self.lastshielded)
	if(random() < 0.5)
		shalrath_shield();
	
	monster_move(autocvar_g_monster_shalrath_speed, autocvar_g_monster_shalrath_speed, 50, shalrath_anim_walk, shalrath_anim_run, shalrath_anim_idle);
}

void shalrath_attack ()
{
	monsters_setframe(shalrath_anim_attack);
	self.delay = time + 0.2;
	self.attack_finished_single = time + autocvar_g_monster_shalrath_attack_spike_delay;
	self.monster_delayedattack = ShalMissile;
}

void shalrathattack_melee ()
{
	monster_melee(self.enemy, autocvar_g_monster_shalrath_attack_melee_damage, 0.3, DEATH_MONSTER_MAGE, TRUE);
}

void shalrath_attack_melee ()
{
	self.monster_delayedattack = shalrathattack_melee;
	self.delay = time + 0.2;
	monsters_setframe(shalrath_anim_attack);
	self.attack_finished_single = time + autocvar_g_monster_shalrath_attack_melee_delay;
}

void shalrath_grenade_explode()
{
	pointparticles(particleeffectnum("explosion_small"), self.origin, '0 0 0', 1);
	
	sound(self, CH_SHOTS, "weapons/grenade_impact.wav", VOL_BASE, ATTN_NORM);
	RadiusDamage (self, self.realowner, autocvar_g_monster_shalrath_attack_grenade_damage, autocvar_g_monster_shalrath_attack_grenade_edgedamage, autocvar_g_monster_shalrath_attack_grenade_radius, world, autocvar_g_monster_shalrath_attack_grenade_force, DEATH_MONSTER_MAGE, other);
	remove(self);
}

void shalrath_grenade_touch()
{
	if(IS_PLAYER(other))
	{
		PROJECTILE_TOUCH;
		shalrath_grenade_explode();
		return;
	}
}

void shalrath_throw_itemgrenade()
{
	makevectors(self.angles);

	W_SetupShot_ProjectileSize (self, '-64 -64 -64', '64 64 64', FALSE, 4, "", CH_WEAPON_A, autocvar_g_monster_shalrath_attack_grenade_damage);
	w_shotdir = v_forward; // no TrueAim for grenades please

	entity gren = spawn ();
	gren.owner = gren.realowner = self;
	gren.classname = "grenade";
	gren.bot_dodge = FALSE;
	gren.movetype = MOVETYPE_BOUNCE;
	gren.solid = SOLID_TRIGGER;
	gren.projectiledeathtype = DEATH_MONSTER_MAGE;
	setorigin(gren, w_shotorg);
	setsize(gren, '-64 -64 -64', '64 64 64');

	gren.nextthink = time + autocvar_g_monster_shalrath_attack_grenade_lifetime;
	gren.think = shalrath_grenade_explode;
	gren.use = shalrath_grenade_explode;
	gren.touch = shalrath_grenade_touch;

	gren.missile_flags = MIF_SPLASH | MIF_ARC;
	W_SETUPPROJECTILEVELOCITY_UP(gren, g_monster_shalrath_attack_grenade);
	
	gren.flags = FL_PROJECTILE;
	
	setmodel(gren, "models/items/g_h50.md3");
	
	self.attack_finished_single = time + 1.5;
}

float shal_missile ()
{
	if(random() < autocvar_g_monster_shalrath_attack_grenade_chance / 100)
	{
		shalrath_throw_itemgrenade();
		return TRUE;
	}
	
	shalrath_attack();
	
	return TRUE;
}

void ShalHome ()
{
	local vector dir = '0 0 0', vtemp = self.enemy.origin + '0 0 10';
	
	if (self.enemy.health <= 0 || self.owner.health <= 0 || time >= self.ltime)
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

void shal_spike_explode ()
{
	self.event_damage = func_null;

	pointparticles(particleeffectnum("explosion_small"), self.origin, '0 0 0', 1);
	RadiusDamage (self, self.realowner, autocvar_g_monster_shalrath_attack_spike_damage, autocvar_g_monster_shalrath_attack_spike_damage * 0.5, autocvar_g_monster_shalrath_attack_spike_radius, world, 0, DEATH_MONSTER_MAGE, other);

	remove (self);
}

void shal_spike_touchexplode()
{
	PROJECTILE_TOUCH;

	shal_spike_explode();
}

void ShalMissile ()
{
	local	entity 	missile = world;
	local	vector	dir = '0 0 0';
	local	float	dist = 0;
	
	self.effects |= EF_MUZZLEFLASH;

	missile = spawn ();
	missile.owner = missile.realowner = self;
	
	self.v_angle = self.angles;
	makevectors (self.angles);
	
	dir = normalize((self.enemy.origin + '0 0 10') - self.origin);
	dist = vlen (self.enemy.origin - self.origin);

	missile.think = ShalHome;
	missile.ltime = time + 7;
	missile.nextthink = time;
	missile.solid = SOLID_BBOX;
	missile.movetype = MOVETYPE_FLYMISSILE;
	missile.flags = FL_PROJECTILE;
	setorigin (missile, self.origin + v_forward * 14 + '0 0 30' + v_right * -14);
	setsize (missile, '0 0 0', '0 0 0');	
	missile.velocity = dir * 400;
	missile.avelocity = '300 300 300';
	missile.enemy = self.enemy;
	missile.touch = shal_spike_touchexplode;
	
	CSQCProjectile(missile, TRUE, PROJECTILE_VORE_SPIKE, TRUE);
}

float ShalrathCheckAttack ()
{
	vector spot1 = '0 0 0', spot2 = '0 0 0';

	if (self.health <= 0)
		return FALSE;
		
	// reset delays when we have no enemy
	if not(self.enemy)
	{
		self.monster_delayedattack = func_null;
		self.delay = -1;
	}
	
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
			monster_sound(self.msound_attack_melee, 0, FALSE); // no delay for attack sounds
			self.attack_melee();
			return TRUE;
		}
	}

// see if any entities are in the way of the shot
	spot1 = self.origin + self.view_ofs;
	spot2 = self.enemy.origin + self.enemy.view_ofs;

	traceline (spot1, spot2, FALSE, self);

	if (trace_ent != self.enemy && trace_fraction < 1)
		return FALSE; // don't have a clear shot

	//if (trace_inopen && trace_inwater)
	//	return FALSE; // sight line crossed contents

	if (self.attack_ranged())
		return TRUE;

	return FALSE;
}

void shalrath_heal()
{
	entity head;
	if(self.health < self.max_health) // only show our effect if we are healing ourself too
		pointparticles(particleeffectnum("healing_fx"), self.origin, '0 0 0', 1);
	self.health = bound(0, self.health + autocvar_g_monster_shalrath_heal_self, self.max_health);
	WaypointSprite_UpdateHealth(self.sprite, self.health);
	monsters_setframe(shalrath_anim_attack);
	self.attack_finished_single = time + autocvar_g_monster_shalrath_heal_delay;
	
	for(head = world; (head = findfloat(head, monster_attack, TRUE)); )
	{
		if(head.health > 0)
		if not(head.frozen)
		if(vlen(head.origin - self.origin) < autocvar_g_monster_shalrath_heal_range)
		if not(IsDifferentTeam(head, self))
		{
			if(IS_PLAYER(head))
			{
				if((g_minstagib && head.ammo_cells < start_ammo_cells) || head.health < g_pickup_healthmedium_max)
					pointparticles(particleeffectnum(((g_minstagib) ? "ammoregen_fx" : "healing_fx")), head.origin, '0 0 0', 1);
				if(g_minstagib)
					head.ammo_cells = bound(0, head.ammo_cells + 1, start_ammo_cells);
				else
					head.health = bound(0, head.health + autocvar_g_monster_shalrath_heal_friends, g_pickup_healthmedium_max);
			}
			else
			{
				if(head.health < head.max_health)
					pointparticles(particleeffectnum("healing_fx"), head.origin, '0 0 0', 1);
				head.health = bound(0, head.health + autocvar_g_monster_shalrath_heal_friends, head.max_health);
				WaypointSprite_UpdateHealth(head.sprite, head.health);
			}
		}
	}
}

void shalrath_shield_die()
{
	if not(self.weaponentity)
		return; // why would this be called without a shield?
	
	self.armorvalue = 1;
	
	remove(self.weaponentity);
	
	self.weaponentity = world;
}

void shalrath_shield()
{
	if(self.weaponentity)
		return; // already have a shield
		
	entity shield = spawn();

	shield.owner = self;
	shield.team = self.team;
	shield.ltime = time + autocvar_g_monster_shalrath_shield_time;
	shield.health = 70;
	shield.classname = "shield";
	shield.effects = EF_ADDITIVE;
	shield.movetype = MOVETYPE_NOCLIP;
	shield.solid = SOLID_TRIGGER;
	shield.avelocity = '7 0 11';
	shield.scale = self.scale * 0.6;
	
	setattachment(shield, self, "");
	setmodel(shield, "models/ctf/shield.md3");
	setsize(shield, shield.scale * shield.mins, shield.scale * shield.maxs);
	
	self.weaponentity = shield;
	
	self.lastshielded = time + autocvar_g_monster_shalrath_shield_delay;
	
	monsters_setframe(shalrath_anim_attack);
	self.attack_finished_single = time + 1;
	
	self.armorvalue = autocvar_g_monster_shalrath_shield_blockpercent / 100;
}

void shalrath_die ()
{
	Monster_CheckDropCvars ("shalrath");
	
	self.think = monster_dead_think;
	self.nextthink = time + self.ticrate;
	self.ltime = time + 5;
	monsters_setframe(shalrath_anim_death);
	
	monster_hook_death(); // for post-death mods
}

void shalrath_spawn ()
{
	if not(self.health)
		self.health = autocvar_g_monster_shalrath_health;

	self.damageforcescale   = 0.003;
	self.classname			= "monster_shalrath";
	self.checkattack	 	= ShalrathCheckAttack;
	self.attack_ranged	  	= shal_missile;
	self.attack_melee		= shalrath_attack_melee;
	self.nextthink		  	= time + random() * 0.5 + 0.1;
	self.think			  	= shalrath_think;
	
	monsters_setframe(shalrath_anim_walk);
	
	monster_setupsounds("shalrath");
	
	monster_hook_spawn(); // for post-spawn mods
}

void spawnfunc_monster_shalrath ()
{	
	if not(autocvar_g_monster_shalrath) { remove(self); return; }
	
	self.monster_spawnfunc = spawnfunc_monster_shalrath;
	
	if(Monster_CheckAppearFlags(self))
		return;
	
	if not (monster_initialize(
			 "Mage", MONSTER_MAGE,
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

#endif // SVQC
