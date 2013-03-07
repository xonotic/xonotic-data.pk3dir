// TODO: clean up this file?

void M_Item_Touch ()
{
	if(self && IS_PLAYER(other) && other.deadflag == DEAD_NO)
	{
		Item_Touch();
		self.think = SUB_Remove;
		self.nextthink = time + 0.1;
	}
}

void Monster_DropItem (string itype, string itemsize)
{
	vector backuporigin = self.origin + ((self.mins + self.maxs) * 0.5);
	entity oldself;
	
	oldself = self;
	self = spawn();
	
	if (itype == "armor")
	{
		if(itemsize == "large") spawnfunc_item_armor_large();
		else if (itemsize == "small") spawnfunc_item_armor_small();
		else if (itemsize == "medium") spawnfunc_item_armor_medium();
		else dprint("Invalid monster drop item selected.\n");
	}
	else if (itype == "health")
	{
		if(itemsize == "large") spawnfunc_item_health_large();
		else if (itemsize == "small") spawnfunc_item_health_small();
		else if (itemsize == "medium") spawnfunc_item_health_medium();
		else if (itemsize == "mega") spawnfunc_item_health_mega();
		else dprint("Invalid monster drop item selected.\n");
	}
	else if (itype == "ammo")
	{
		if(itemsize == "shells") spawnfunc_item_shells();
		else if (itemsize == "cells") spawnfunc_item_cells();
		else if (itemsize == "bullets") spawnfunc_item_bullets();
		else if (itemsize == "rockets") spawnfunc_item_rockets();
		else dprint("Invalid monster drop item selected.\n");
	}
	else
	{
		dprint("Invalid monster drop item selected.\n");
		self = oldself;
		return;
	}
	
	self.velocity = randomvec() * 175 + '0 0 325';
	
	self.gravity = 1;
	self.origin = backuporigin;
	
	self.touch = M_Item_Touch;
	
	SUB_SetFade(self, time + 5, 1);
	
	self = oldself;
}

float monster_isvalidtarget (entity targ, entity ent)
{
	if(!targ || !ent)
		return FALSE; // this check should fix a crash
		
	if(targ.vehicle_flags & VHF_ISVEHICLE)
		targ = targ.vehicle;
		
	if(time < game_starttime)
		return FALSE; // monsters do nothing before the match has started
		
	traceline(ent.origin, targ.origin, FALSE, ent);
	
	if(vlen(targ.origin - ent.origin) >= ent.target_range)
		return FALSE; // enemy is too far away

	if(trace_ent != targ)
		return FALSE; // we can't see the enemy
		
	if(targ.takedamage == DAMAGE_NO)
		return FALSE; // enemy can't be damaged
		
	if(targ.items & IT_INVISIBILITY)
		return FALSE; // enemy is invisible
	
	if(IS_SPEC(targ) || IS_OBSERVER(targ))
		return FALSE; // enemy is a spectator
	
	if(targ.deadflag != DEAD_NO || ent.deadflag != DEAD_NO || targ.health <= 0 || ent.health <= 0)
		return FALSE; // enemy/self is dead
	
	if(targ.monster_owner == ent || ent.monster_owner == targ)
		return FALSE; // enemy owns us, or we own them
	
	if(targ.flags & FL_NOTARGET)
		return FALSE; // enemy can't be targetted
	
	if not(autocvar_g_monsters_typefrag)
	if(targ.BUTTON_CHAT)
		return FALSE; // no typefragging!
	
	if not(IsDifferentTeam(targ, ent))
		return FALSE; // enemy is on our team
	
	return TRUE;
}

float enemy_stillvalidtarget(entity targ, entity e)
{
	if(targ.health < 1 || targ.deadflag)
		return FALSE; // let's not keep hurting a corpse
		
	if not(autocvar_g_monsters_typefrag)
	if(targ.BUTTON_CHAT)
		return FALSE; // no typefrags!
		
	if(vlen(targ.origin - e.origin) > e.target_range)
		return FALSE; // out of our reach
		
	if not(targ.takedamage)
		return FALSE; // can't hurt it
		
	if(targ.flags & FL_NOTARGET)
		return FALSE; // can't target it
		
	if(targ.items & IT_INVISIBILITY)
		return FALSE; // currently not used
		
	if(!IsDifferentTeam(targ, e))
		return FALSE;
		
	return TRUE; // all is good, keep going!
}

entity FindTarget (entity ent) 
{
	if(MUTATOR_CALLHOOK(MonsterFindTarget)) { return ent.enemy; } // Handled by a mutator
	local entity e;
	for(e = world; (e = findflags(e, monster_attack, TRUE)); ) 
	{
		if(monster_isvalidtarget(e, ent))
		{
			return e;
		}
	}
	return world;
}

void MonsterTouch ()
{
	if(other == world)
		return;
		
	if(self.enemy != other)
	if not(other.flags & FL_MONSTER)
	if(monster_isvalidtarget(other, self))
		self.enemy = other;
}

void monster_sound(string msound, float sound_delay, float delaytoo)
{
	if(delaytoo && time < self.msound_delay)
		return; // too early
		
	if(msound == "")
		return; // sound doesn't exist

	sound(self, CH_PAIN_SINGLE, msound, VOL_BASE, ATTN_NORM);

	self.msound_delay = time + sound_delay;
}

void monster_precachesounds()
{
	precache_sound(self.msound_idle);
	precache_sound(self.msound_death);
	precache_sound(self.msound_attack_melee);
	precache_sound(self.msound_attack_ranged);
	precache_sound(self.msound_sight);
	precache_sound(self.msound_pain);
}

void monster_melee (entity targ, float damg, float er, float deathtype)
{
	float bigdmg = 0, rdmg = damg * random();

	if (self.health <= 0)
		return;
	if (targ == world)
		return;

	if (vlen(self.origin - targ.origin) > er * self.scale)
		return;
		
	bigdmg = rdmg * self.scale;
	
	Damage(targ, self, self, bigdmg * monster_skill, deathtype, targ.origin, normalize(targ.origin - self.origin));
}

void Monster_CheckDropCvars (string mon)
{
	if not(self.candrop)
		return; // forced off
	
	string dropitem;
	string dropsize;
	
	dropitem = cvar_string(strcat("g_monster_", mon, "_drop"));
	dropsize = cvar_string(strcat("g_monster_", mon, "_drop_size"));
	
	monster_dropitem = dropitem;
	monster_dropsize = dropsize;
	MUTATOR_CALLHOOK(MonsterDropItem);
	dropitem = monster_dropitem;
	dropsize = monster_dropsize;
	
	if(autocvar_g_monsters_forcedrop)
		Monster_DropItem(autocvar_g_monsters_drop_type, autocvar_g_monsters_drop_size);
	else if(dropitem != "")
		Monster_DropItem(dropitem, dropsize);	   
	else
		Monster_DropItem("armor", "medium");
}

void ScaleMonster (float scle)
{
	// this should prevent monster from falling through floor when scale changes
	self.scale = scle;
	setorigin(self, self.origin + ('0 0 30' * scle));
}

void Monster_CheckMinibossFlag ()
{
	if(MUTATOR_CALLHOOK(MonsterCheckBossFlag))
		return;
		
	float r = random() * 4, chance = random() * 100;

	// g_monsters_miniboss_chance cvar or spawnflags 64 causes a monster to be a miniboss
	if ((self.spawnflags & MONSTERFLAG_MINIBOSS) || (chance < autocvar_g_monsters_miniboss_chance))
	{
		self.health += autocvar_g_monsters_miniboss_healthboost;
		ScaleMonster(1.5);
		self.flags |= MONSTERFLAG_MINIBOSS;
		
		if (r < 2 || self.team == NUM_TEAM_2)
		{
			self.strength_finished = -1;  
			self.effects |= (EF_FULLBRIGHT | EF_BLUE);
		}
		else if (r >= 1 || self.team == NUM_TEAM_1)
		{
			self.invincible_finished = -1;
			self.effects |= (EF_FULLBRIGHT | EF_RED);
		}
		else
			self.effects |= (EF_FULLBRIGHT | EF_RED | EF_BLUE);
		
		if(teamplay)
		if(self.team)
			return;
			
		self.colormod = randomvec() * 4;
	}
}

float Monster_CanRespawn(entity ent)
{
	other = ent;
	if(MUTATOR_CALLHOOK(MonsterRespawn))
		return TRUE; // enabled by a mutator
		
	if(ent.spawnflags & MONSTERFLAG_NORESPAWN)
		return FALSE;
		
	if not(autocvar_g_monsters_respawn)
		return FALSE;
		
	return TRUE;
}

void Monster_Fade ()
{
	if(Monster_CanRespawn(self))
	{
		self.monster_respawned = TRUE;
		setmodel(self, "");
		self.think = self.monster_spawnfunc;
		self.nextthink = time + self.respawntime;
		setorigin(self, self.pos1);
		self.angles = self.pos2;
		self.health = self.max_health; // TODO: check if resetting to max_health is wise here
		return;
	}
	self.think = SUB_Remove;
	self.nextthink = time + 4;
	SUB_SetFade(self, time + 3, 1);
}

float Monster_CanJump (vector vel)
{
	local vector old = self.velocity;
	
	self.velocity = vel;
	tracetoss(self, self);
	self.velocity = old;
	if (trace_ent != self.enemy)
		return FALSE;

	return TRUE;
}

float monster_leap (float anm, void() touchfunc, vector vel, float anim_finished)
{
	if not(self.flags & FL_ONGROUND)
		return FALSE;
	if(self.health < 1)
		return FALSE; // called when dead?
	if not(Monster_CanJump(vel))
		return FALSE;
		
	self.frame = anm;
	self.state = MONSTER_STATE_ATTACK_LEAP;
	self.touch = touchfunc;
	self.origin_z += 1;
	self.velocity = vel;
	if (self.flags & FL_ONGROUND)
		self.flags -= FL_ONGROUND;
		
	self.attack_finished_single = time + anim_finished;
	
	return TRUE;
}

float GenericCheckAttack ()
{
	// checking attack while dead?
	if (self.health <= 0 || self.enemy == world)
		return FALSE;
		
	if(self.monster_delayedattack && self.delay != -1)
	{
		if(time < self.delay)
			return FALSE;
			
		self.monster_delayedattack();
	}
	
	if (time < self.attack_finished_single)
		return FALSE;
	
	if (enemy_range() > 2000) // long traces are slow
		return FALSE;	
		
	if(self.attack_melee)
	if(enemy_range() <= 100 * self.scale)
	{
		monster_sound(self.msound_attack_melee, 0, FALSE); // no delay for attack sounds
		self.attack_melee(); // don't wait for nextthink - too slow
		return TRUE;
	}
	
	// monster doesn't have a ranged attack function, so stop here
	if not(self.attack_ranged)
		return FALSE;

	// see if any entities are in the way of the shot
	if not(findtrajectorywithleading(self.origin, '0 0 0', '0 0 0', self.enemy, 800, 0, 2.5, 0, self))
		return FALSE;

	if(self.attack_ranged())
	{
		monster_sound(self.msound_attack_ranged, 0, FALSE); // no delay for attack sounds
		return TRUE;
	}

	return FALSE;
}

void monster_use ()
{
	if (self.enemy)
		return;
	if (self.health <= 0)
		return;

	if(!monster_isvalidtarget(activator, self))
		return;

	self.enemy = activator;
}

float trace_path(vector from, vector to)
{
	vector dir = normalize(to - from) * 15, offset = '0 0 0';
	float trace1 = trace_fraction;
	
	offset_x = dir_y;
	offset_y = -dir_x;
	traceline (from+offset, to+offset, TRUE, self);
	
	traceline(from-offset, to-offset, TRUE, self);
		
	return ((trace1 < trace_fraction) ? trace1 : trace_fraction);
}

vector monster_pickmovetarget(entity targ)
{
	// enemy is always preferred target
	if(self.enemy)
	{
		self.monster_movestate = MONSTER_MOVE_ENEMY;
		return self.enemy.origin;
	}
	if(targ)
	{
		self.monster_movestate = MONSTER_MOVE_WANDER;
		return targ.origin;
	}
	
	switch(self.monster_moveflags)
	{
		case MONSTER_MOVE_OWNER:
		{
			self.monster_movestate = MONSTER_MOVE_OWNER;
			if(self.monster_owner && self.monster_owner.classname != "monster_swarm")
				return self.monster_owner.origin;
		}
		case MONSTER_MOVE_WANDER:
		{
			self.monster_movestate = MONSTER_MOVE_WANDER;
				
			self.angles_y = random() * 500;
			makevectors(self.angles);
			return self.origin + v_forward * 600;
		}
		case MONSTER_MOVE_SPAWNLOC:
		{
			self.monster_movestate = MONSTER_MOVE_SPAWNLOC;
			return self.pos1;
		}
		default:
		case MONSTER_MOVE_NOMOVE:
		{
			self.monster_movestate = MONSTER_MOVE_NOMOVE;
			return self.origin;
		}
	}
}

.float last_trace;
void monster_move(float runspeed, float walkspeed, float stopspeed, float manim_run, float manim_walk, float manim_idle)
{
	if(self.target)
		self.goalentity = find(world, targetname, self.target);
		
	entity targ;

	if(self.frozen)
	{
		self.revive_progress = bound(0, self.revive_progress + frametime * self.revive_speed, 1);
		self.health = max(1, self.max_health * self.revive_progress);
		
		if(self.sprite) WaypointSprite_UpdateHealth(self.sprite, self.health);
			
		movelib_beak_simple(stopspeed);
			
		self.velocity = '0 0 0';
		self.enemy = world;
		self.nextthink = time + 0.1;
		
		if(self.revive_progress >= 1)
			Unfreeze(self); // wait for next think before attacking
			
		return; // no moving while frozen
	}
	
	if(self.flags & FL_SWIM)
	{
		if(self.waterlevel < WATERLEVEL_WETFEET)
		{
			if(time >= self.last_trace)
			{
				self.last_trace = time + 0.4;
				self.angles = '0 0 -90';
				Damage (self, world, world, 2, DEATH_DROWN, self.origin, '0 0 0');
				if(random() < 0.5)
				{
					self.velocity_y += random() * 50;
					self.velocity_x -= random() * 50;
				}
				else
				{
					self.velocity_y -= random() * 50;
					self.velocity_x += random() * 50;
				}
				//self.velocity_z += random() * 150;
				self.movetype = MOVETYPE_BOUNCE;
				self.velocity_z = -200;
			}
			return;
		}
		else
		{
			self.angles = '0 0 0';
			self.movetype = MOVETYPE_WALK;
		}
	}
	
	if(gameover || time < game_starttime)
	{
		runspeed = walkspeed = 0;
		self.frame = manim_idle;
		movelib_beak_simple(stopspeed);
		return;
	}
	
	targ = self.goalentity;
	
	monster_target = targ;
	monster_speed_run = runspeed;
	monster_speed_walk = walkspeed;
	MUTATOR_CALLHOOK(MonsterMove);
	targ = monster_target;
	runspeed = monster_speed_run;
	walkspeed = monster_speed_walk;
		
	if(IsDifferentTeam(self.monster_owner, self))
		self.monster_owner = world;
		
	if(!enemy_stillvalidtarget(self.enemy, self))
		self.enemy = world;
		
	if not(self.enemy)
	{
		self.enemy = FindTarget(self);
		if(self.enemy)
			monster_sound(self.msound_sight, 0, FALSE);
	}
		
	if(time >= self.last_trace)
	{
		if(self.monster_movestate == MONSTER_MOVE_WANDER && self.goalentity.classname != "td_waypoint")
			self.last_trace = time + 2;
		else
			self.last_trace = time + 0.5;
		self.moveto = monster_pickmovetarget(targ);
	}

	if not(self.enemy)
		monster_sound(self.msound_idle, 5, TRUE);
	
	vector angles_face = vectoangles(self.moveto - self.origin);
	vector owner_face = vectoangles(self.monster_owner.origin - self.origin);
	vector enemy_face = vectoangles(self.enemy.origin - self.origin);
	self.angles_y = angles_face_y;
	
	if(self.state == MONSTER_STATE_ATTACK_LEAP && (self.flags & FL_ONGROUND))
	{
		self.state = 0;
		self.touch = MonsterTouch;
	}
	 
	v_forward = normalize(self.moveto - self.origin);
	
	float l = vlen(self.moveto - self.origin);
	float t1 = trace_path(self.origin+'0 0 10', self.moveto+'0 0 10');
	float t2 = trace_path(self.origin-'0 0 15', self.moveto-'0 0 15'); 
	
	if(t1*l-t2*l>50 && (t1*l > 100 || t1 > 0.8))
	if(self.flags & FL_ONGROUND)
		movelib_jump_simple(100);

	if(vlen(self.origin - self.moveto) > 64)
	{
		if(self.flags & FL_FLY)
			movelib_move_simple(v_forward, ((self.enemy) ? runspeed : walkspeed), 0.6);
		else
			movelib_move_simple_gravity(v_forward, ((self.enemy) ? runspeed : walkspeed), 0.6);
		if(time > self.pain_finished)
		if(time > self.attack_finished_single)
			self.frame = ((self.enemy) ? manim_run : manim_walk);
	}
	else
	{
		movelib_beak_simple(stopspeed);
		if(time > self.attack_finished_single)
		if(time > self.pain_finished)
		if (vlen(self.velocity) <= 30)
		{
			self.frame = manim_idle;
			if(self.enemy)
				self.angles_y = enemy_face_y;
			else
				self.angles_y = ((self.monster_owner) ? owner_face_y : self.pos2_y); // reset looking angle now?
		}
	}
		
	if(self.enemy && self.checkattack)
		self.checkattack();
}

void monsters_setstatus()
{
	self.stat_monsters_total = monsters_total;
	self.stat_monsters_killed = monsters_killed;
}

void Monster_Appear ()
{
	self.enemy = activator;
	self.spawnflags &~= MONSTERFLAG_APPEAR;
	self.monster_spawnfunc();
}

void monsters_damage (entity inflictor, entity attacker, float damage, float deathtype, vector hitloc, vector force)
{
	if(self.frozen && deathtype != DEATH_KILL)
		return;
		
	if(time < self.pain_finished && deathtype != DEATH_KILL)
		return;
		
	if((ignore_turrets && !(attacker.turrcaps_flags & TFL_TURRCAPS_ISTURRET)) || !ignore_turrets)
	if(monster_isvalidtarget(attacker, self))
		self.enemy = attacker;
	
	self.health -= damage;
	
	if(self.sprite)
		WaypointSprite_UpdateHealth(self.sprite, self.health);
		
	self.dmg_time = time;

	if(sound_allowed(MSG_BROADCAST, attacker) && deathtype != DEATH_DROWN)
		spamsound (self, CH_PAIN, "misc/bodyimpact1.wav", VOL_BASE, ATTN_NORM);  // FIXME: PLACEHOLDER
	
	self.velocity += force * self.damageforcescale;
		
	if(deathtype != DEATH_DROWN)
	{
		Violence_GibSplash_At(hitloc, force, 2, bound(0, damage, 200) / 16, self, attacker);
		if (damage > 50)
			Violence_GibSplash_At(hitloc, force * -0.1, 3, 1, self, attacker);
		if (damage > 100)
			Violence_GibSplash_At(hitloc, force * -0.2, 3, 1, self, attacker);
	}
		
	if(self.health <= 0)
	{	 
		if(self.sprite)
		{
			// Update one more time to avoid waypoint fading without emptying healthbar
			WaypointSprite_UpdateHealth(self.sprite, 0);
		}
		
		if(deathtype == DEATH_KILL)
			self.candrop = FALSE; // killed by mobkill command
		
		if(self.flags & MONSTERFLAG_MINIBOSS && self.candrop)
			W_ThrowNewWeapon(self, WEP_NEX, 0, self.origin, self.velocity);
			
		activator = attacker;
		other = self.enemy;
		self.target = self.target2;
		self.target2 = "";
		SUB_UseTargets();
	
		self.monster_die();
		
		frag_attacker = attacker;
		frag_target = self;
		MUTATOR_CALLHOOK(MonsterDies);
	}
}

// used to hook into monster post death functions without a mutator
void monster_hook_death()
{
	if(self.sprite)
        WaypointSprite_Kill(self.sprite);
		
	monster_sound(self.msound_death, 0, FALSE);
		
	if(!(self.spawnflags & MONSTERFLAG_SPAWNED) && !self.monster_respawned)
		monsters_killed += 1;
		
	if(self.realowner.classname == "monster_spawner")
		self.realowner.spawner_monstercount -= 1;
		
	if(IS_CLIENT(self.realowner))
		self.realowner.monstercount -= 1;
		
	totalspawned -= 1;
}

// used to hook into monster post spawn functions without a mutator
void monster_hook_spawn()
{
	Monster_CheckMinibossFlag();

	self.max_health = self.health;
	self.pain_finished = self.nextthink;

	monster_precachesounds();
	
	if(teamplay && self.team)
	{
		self.colormod = Team_ColorRGB(self.team);
		self.monster_attack = TRUE;
	}
	
	if (self.target)
	{
		self.target2 = self.target;
		self.goalentity = find(world, targetname, self.target);
	}
		
	if(autocvar_g_monsters_healthbars)
	{
		WaypointSprite_Spawn(self.netname, 0, 600, self, '0 0 1' * self.sprite_height, world, 0, self, sprite, FALSE, RADARICON_DANGER, ((self.team) ? Team_ColorRGB(self.team) : '1 0 0'));	
		WaypointSprite_UpdateMaxHealth(self.sprite, self.max_health);
		WaypointSprite_UpdateHealth(self.sprite, self.health);
	}
	
	monster_sound(self.msound_spawn, 0, FALSE);

	MUTATOR_CALLHOOK(MonsterSpawn);
}

float monster_initialize(string  net_name,
						 string  bodymodel,
						 vector  min_s,
						 vector  max_s,
						 float   nodrop,
						 void() dieproc,
						 void() spawnproc)
{
	if not(autocvar_g_monsters)
		return FALSE;
		
	// support for quake style removing monsters based on skill
	if(monster_skill <= autocvar_g_monsters_skill_easy && (self.spawnflags & MONSTERSKILL_NOTEASY)) { return FALSE; }
	if(monster_skill == autocvar_g_monsters_skill_normal && (self.spawnflags & MONSTERSKILL_NOTMEDIUM)) { return FALSE; }
	if(monster_skill == autocvar_g_monsters_skill_hard && (self.spawnflags & MONSTERSKILL_NOTHARD)) { return FALSE; }
	if(monster_skill == autocvar_g_monsters_skill_insane && (self.spawnflags & MONSTERSKILL_NOTINSANE)) { return FALSE; }
	if(monster_skill >= autocvar_g_monsters_skill_nightmare && (self.spawnflags & MONSTERSKILL_NOTNIGHTMARE)) { return FALSE; }

	if(self.model == "")
	if(bodymodel == "")
		error("monsters: missing bodymodel!");

	if(self.netname == "")
	{
		if(net_name != "" && IS_PLAYER(self.realowner))
			net_name = strzone(strdecolorize(sprintf("%s's %s", self.realowner.netname, net_name)));
		self.netname = ((net_name == "") ? self.classname : net_name);
	}
	
	if not(self.scale)
		self.scale = 1;
	
	if(self.spawnflags & MONSTERFLAG_GIANT && !autocvar_g_monsters_nogiants)
		ScaleMonster(5);
	else
		ScaleMonster(self.scale);
		
	min_s *= self.scale;
	max_s *= self.scale;

	if(self.team && !teamplay)
		self.team = 0;

	self.flags = FL_MONSTER;
	
	if(self.model != "")
		bodymodel = self.model;
		
	if not(self.spawnflags & MONSTERFLAG_SPAWNED) // naturally spawned monster
	if not(self.monster_respawned)
		monsters_total += 1;
	
	precache_model(bodymodel);

	setmodel(self, bodymodel);
	
	setsize(self, min_s, max_s);

	self.takedamage		 	= DAMAGE_AIM;
	self.bot_attack		 	= TRUE;
	self.iscreature		 	= TRUE;
	self.teleportable	   	= TRUE;
	self.damagedbycontents	= TRUE;
	self.damageforcescale   = 0.003;
	self.monster_die		= dieproc;
	self.event_damage	   	= monsters_damage;
	self.touch			  	= MonsterTouch;
	self.use				= monster_use;
	self.solid				= SOLID_BBOX;
	self.movetype			= MOVETYPE_WALK;
	self.delay				= -1; // used in attack delay code
	monsters_spawned	   += 1;
	self.think				= spawnproc;
	self.nextthink			= time;
	self.enemy				= world;
	self.velocity			= '0 0 0';
	self.moveto				= self.origin;
	self.pos1				= self.origin;
	self.pos2				= self.angles;
	self.candrop			= TRUE;
	
	if not(self.target_range)
		self.target_range = autocvar_g_monsters_target_range;
	
	if not(self.respawntime)
		self.respawntime = autocvar_g_monsters_respawn_delay;
	
	if not(self.monster_moveflags)
		self.monster_moveflags = MONSTER_MOVE_WANDER;

	if(autocvar_g_nodepthtestplayers)
		self.effects |= EF_NODEPTHTEST;

	if(autocvar_g_fullbrightplayers)
		self.effects |= EF_FULLBRIGHT;

	if not(nodrop)
	{
		setorigin(self, self.origin);
		tracebox(self.origin + '0 0 100', min_s, max_s, self.origin - '0 0 10000', MOVE_WORLDONLY, self);
		setorigin(self, trace_endpos);
	}

	return TRUE;
}
