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

void monster_item_spawn()
{
	self.monster_delayedattack();
		
	self.think = monster_item_spawn;
	self.nextthink = time + 0.1;
	self.gravity = 1;
	self.velocity = randomvec() * 175 + '0 0 325';
	self.touch = M_Item_Touch;
	
	SUB_SetFade(self, time + 5, 1);
}

void Monster_DropItem (string itype, string itemsize)
{
	vector org = self.origin + ((self.mins + self.maxs) * 0.5);
	entity e = spawn();
	
	setorigin(e, org);
	
	switch(itype)
	{
		case "armor":
		{
			switch(itemsize)
			{
				case "mega": e.monster_delayedattack = spawnfunc_item_armor_large; break;
				case "large": e.monster_delayedattack = spawnfunc_item_armor_big; break;
				case "medium": e.monster_delayedattack = spawnfunc_item_armor_medium; break;
				case "small": e.monster_delayedattack = spawnfunc_item_armor_small; break;
				default: break;
			}
			break; // break here?
		}
		case "health":
		{
			switch(itemsize)
			{
				case "mega": e.monster_delayedattack = spawnfunc_item_health_mega; break;
				case "large": e.monster_delayedattack = spawnfunc_item_health_large; break;
				case "medium": e.monster_delayedattack = spawnfunc_item_health_medium; break;
				case "small": e.monster_delayedattack = spawnfunc_item_health_small; break;
				default: break;
			}
			break; // break here?
		}
		case "ammo":
		{
			switch(itemsize)
			{
				case "shells": e.monster_delayedattack = spawnfunc_item_shells; break;
				case "cells": e.monster_delayedattack = spawnfunc_item_cells; break;
				case "rockets": e.monster_delayedattack = spawnfunc_item_rockets; break;
				case "bullets":
				case "nails": e.monster_delayedattack = spawnfunc_item_bullets; break;
				default: break;
			}
			break;
		}
		default: break;
	}
	
	if(g_minstagib)
		e.monster_delayedattack = spawnfunc_item_minst_cells;
		
	e.think = monster_item_spawn;
	e.nextthink = time + 0.1;
}

void monsters_setframe(float _frame)
{
	if(self.frame == _frame)
		return;
		
	self.anim_start_time = time;
	self.frame = _frame;
	self.SendFlags |= MSF_ANIM;
}

float monster_isvalidtarget (entity targ, entity ent)
{
	if(!targ || !ent)
		return FALSE; // this check should fix a crash
		
	if(time < game_starttime)
		return FALSE; // monsters do nothing before the match has started
		
	WarpZone_TraceLine(ent.origin, targ.origin, MOVE_NORMAL, ent);
	
	if(vlen(targ.origin - ent.origin) >= ent.target_range)
		return FALSE; // enemy is too far away
		
	if not(targ.vehicle_flags & VHF_ISVEHICLE)
	if(trace_ent != targ)
		return FALSE; // we can't see the enemy
		
	if(targ.takedamage == DAMAGE_NO)
		return FALSE; // enemy can't be damaged
		
	if(targ.items & IT_INVISIBILITY)
		return FALSE; // enemy is invisible
	
	if(IS_SPEC(targ) || IS_OBSERVER(targ))
		return FALSE; // enemy is a spectator
	
	if not(targ.vehicle_flags & VHF_ISVEHICLE) // vehicles dont count as alive?
	if(targ.deadflag != DEAD_NO || ent.deadflag != DEAD_NO || targ.health <= 0 || ent.health <= 0)
		return FALSE; // enemy/self is dead
	
	if(targ.monster_owner == ent || ent.monster_owner == targ)
		return FALSE; // enemy owns us, or we own them
	
	if not(targ.vehicle_flags & VHF_ISVEHICLE)
	if(targ.flags & FL_NOTARGET)
		return FALSE; // enemy can't be targetted
	
	if not(autocvar_g_monsters_typefrag)
	if(targ.BUTTON_CHAT)
		return FALSE; // no typefragging!
	
	if not(IsDifferentTeam(targ, ent))
		return FALSE; // enemy is on our team
	
	return TRUE;
}

entity FindTarget (entity ent) 
{
	if(MUTATOR_CALLHOOK(MonsterFindTarget)) { return ent.enemy; } // Handled by a mutator
	entity e;
	
	for(e = world; (e = findflags(e, monster_attack, TRUE)); ) 
	if(monster_isvalidtarget(e, ent))
		return e;

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

	sound(self, CHAN_AUTO, msound, VOL_BASE, ATTN_NORM);

	self.msound_delay = time + sound_delay;
}

void monster_precachesounds(entity e)
{
	precache_sound(e.msound_idle);
	precache_sound(e.msound_death);
	precache_sound(e.msound_attack_melee);
	precache_sound(e.msound_attack_ranged);
	precache_sound(e.msound_sight);
	precache_sound(e.msound_pain);
}

void monster_setupsounds(string mon)
{
	if(self.msound_idle == "") self.msound_idle = strzone(strcat("monsters/", mon, "_idle.wav"));
	if(self.msound_death == "") self.msound_death = strzone(strcat("monsters/", mon, "_death.wav"));
	if(self.msound_pain == "") self.msound_pain = strzone(strcat("monsters/", mon, "_pain.wav"));
	if(self.msound_attack_melee == "") self.msound_attack_melee = strzone(strcat("monsters/", mon, "_melee.wav"));
	if(self.msound_attack_ranged == "") self.msound_attack_ranged = strzone(strcat("monsters/", mon, "_attack.wav"));
	if(self.msound_sight == "") self.msound_sight = strzone(strcat("monsters/", mon, "_sight.wav"));
}

void monster_melee (entity targ, float damg, float er, float deathtype, float dostop)
{
	float bigdmg, dot, rdmg = damg * random();

	if (self.health <= 0)
		return;
	if (targ == world)
		return;
		
	if(dostop)
	{
		self.velocity_x = 0;
		self.velocity_y = 0;
		self.state = MONSTER_STATE_ATTACK_MELEE;
		self.SendFlags |= MSF_MOVE;
	}

	makevectors (self.angles);
	dot = normalize (targ.origin - self.origin) * v_forward;
	
	bigdmg = rdmg * self.scale;
	
	if(dot > er)
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

void ScaleMonster (float scle, vector min_s, vector max_s)
{
	// this should prevent monster from falling through floor when scale changes
	self.scale = scle;
	setsize(self, min_s * scle, max_s * scle);
	setorigin(self, self.origin + ('0 0 30' * scle));
	self.SendFlags |= MSF_SIZE | MSF_MOVE;
}

void Monster_CheckMinibossFlag ()
{
	if(MUTATOR_CALLHOOK(MonsterCheckBossFlag))
		return;
		
	if(self.spawnflags & MONSTERFLAG_GIANT)
		return; // 1 size modifier at a time
		
	float chance = random() * 100;

	// g_monsters_miniboss_chance cvar or spawnflags 64 causes a monster to be a miniboss
	if ((self.spawnflags & MONSTERFLAG_MINIBOSS) || (chance < autocvar_g_monsters_miniboss_chance))
	{
		self.health += autocvar_g_monsters_miniboss_healthboost;
		ScaleMonster(1.5, self.mins, self.maxs);
		self.flags |= MONSTERFLAG_MINIBOSS;
		if not(self.weapon)
			self.weapon = WEP_NEX;
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
		self.think = self.monster_spawnfunc;
		self.nextthink = time + self.respawntime;
		if(self.spawnflags & MONSTER_RESPAWN_DEATHPOINT)
		{
			self.pos1 = self.origin;
			self.pos2 = self.angles;
		}
		self.event_damage = func_null;
		self.takedamage = DAMAGE_NO;
		setorigin(self, self.pos1);
		self.angles = self.pos2;
		self.health = self.max_health; // TODO: check if resetting to max_health is wise here
		self.SendFlags |= MSF_MOVE;
		return;
	}
	SUB_SetFade(self, time + 3, 1);
}

float Monster_CanJump (vector vel)
{
	if(self.state)
		return FALSE; // already attacking
	if not(self.flags & FL_ONGROUND)
		return FALSE; // not on the ground
	if(self.health <= 0)
		return FALSE; // called when dead?
	if(time < self.attack_finished_single)
		return FALSE; // still attacking

	vector old = self.velocity;
	
	self.velocity = vel;
	tracetoss(self, self);
	self.velocity = old;
	if (trace_ent != self.enemy)
		return FALSE;

	return TRUE;
}

float monster_leap (float anm, void() touchfunc, vector vel, float anim_finished)
{
	if(!Monster_CanJump(vel))
		return FALSE;
		
	monsters_setframe(anm);
	self.state = MONSTER_STATE_ATTACK_LEAP;
	self.touch = touchfunc;
	self.origin_z += 1;
	self.velocity = vel;
	self.flags &~= FL_ONGROUND;
		
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
		
	if(self.attack_melee)
	if(vlen(self.enemy.origin - self.origin) <= 100 * self.scale)
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

.float last_trace;
vector monster_pickmovetarget(entity targ)
{
	// enemy is always preferred target
	if(self.enemy)
	{
		self.monster_movestate = MONSTER_MOVE_ENEMY;
		self.last_trace = time + 0.1;
		return self.enemy.origin;
	}
	if(targ)
	{
		self.monster_movestate = MONSTER_MOVE_WANDER;
		self.last_trace = time + 0.5;
		return targ.origin;
	}
	
	switch(self.monster_moveflags)
	{
		case MONSTER_MOVE_OWNER:
		{
			self.monster_movestate = MONSTER_MOVE_OWNER;
			self.last_trace = time + 0.3;
			if(self.monster_owner && self.monster_owner.classname != "monster_swarm")
				return self.monster_owner.origin;
		}
		case MONSTER_MOVE_WANDER:
		{
			self.monster_movestate = MONSTER_MOVE_WANDER;
			self.last_trace = time + 2;
				
			self.angles_y = random() * 500;
			makevectors(self.angles);
			return self.origin + v_forward * 600;
		}
		case MONSTER_MOVE_SPAWNLOC:
		{
			self.monster_movestate = MONSTER_MOVE_SPAWNLOC;
			self.last_trace = time + 2;
			return self.pos1;
		}
		default:
		case MONSTER_MOVE_NOMOVE:
		{
			self.monster_movestate = MONSTER_MOVE_NOMOVE;
			self.last_trace = time + 2;
			return self.origin;
		}
	}
}

void monster_move(float runspeed, float walkspeed, float stopspeed, float manim_run, float manim_walk, float manim_idle)
{
	if(self.target2)
		self.goalentity = find(world, targetname, self.target2);
		
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
				
				Damage (self, world, world, 2, DEATH_DROWN, self.origin, '0 0 0');
				self.angles = '90 90 0';
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
				self.velocity_z += random() * 150;
			}
				
			
			self.movetype = MOVETYPE_BOUNCE;
			//self.velocity_z = -200;
				
			self.SendFlags |= MSF_MOVE | MSF_ANG;
			
			return;
		}
		else
		{
			self.angles = '0 0 0';
			self.movetype = MOVETYPE_WALK;
		}
	}
	
	if(gameover || time < game_starttime || (autocvar_g_campaign && !campaign_bots_may_start))
	{
		runspeed = walkspeed = 0;
		monsters_setframe(manim_idle);
		movelib_beak_simple(stopspeed);
		self.SendFlags |= MSF_MOVE;
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
		
	if not(monster_isvalidtarget(self.enemy, self))
		self.enemy = world; // check enemy each think frame?
		
	if not(self.enemy)
	{
		self.enemy = FindTarget(self);
		if(self.enemy)
			monster_sound(self.msound_sight, 0, FALSE);
	}
	
	if(self.state == MONSTER_STATE_ATTACK_MELEE && time >= self.attack_finished_single)
		self.state = 0;
		
	if(self.state != MONSTER_STATE_ATTACK_MELEE) // don't move if set
	if(time >= self.last_trace || self.enemy) // update enemy instantly
		self.moveto = monster_pickmovetarget(targ);

	if not(self.enemy)
		monster_sound(self.msound_idle, 5, TRUE);
	
	vector angles_face = vectoangles(self.moveto - self.origin);
	vector owner_face = vectoangles(self.monster_owner.origin - self.origin);
	vector enemy_face = vectoangles(self.enemy.origin - self.origin);
	
	if(self.state != MONSTER_STATE_ATTACK_LEAP)
	{
		self.angles_y = angles_face_y;
		self.v_angle = self.angles;
	}
	
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

	if(vlen(self.origin - self.moveto) > 64 * self.scale)
	{
		if(self.flags & FL_FLY || self.flags & FL_SWIM)
			movelib_move_simple(v_forward, ((self.enemy) ? runspeed : walkspeed), 0.6);
		else
			movelib_move_simple_gravity(v_forward, ((self.enemy) ? runspeed : walkspeed), 0.6);
		if(time > self.pain_finished)
		if(time > self.attack_finished_single)
			monsters_setframe((self.enemy) ? manim_run : manim_walk);
	}
	else
	{
		if(self.goalentity.target)
			self.target2 = self.goalentity.target;
		else if(self.goalentity.target2)
			self.target2 = self.goalentity.target2;
		else
		{
			movelib_beak_simple(stopspeed);
			if(time > self.attack_finished_single)
			if(time > self.pain_finished)
			if (vlen(self.velocity) <= 30)
			{
				monsters_setframe(manim_idle);
				if(self.enemy)
					self.angles_y = enemy_face_y;
				else
					self.angles_y = ((self.monster_owner) ? owner_face_y : self.pos2_y); // reset looking angle now?
			}
		}
	}
		
	if(self.enemy && self.checkattack)
		self.checkattack();
		
	self.SendFlags |= MSF_ANG;
	self.SendFlags |= MSF_MOVE;
}

void monster_dead_think()
{
	self.think = monster_dead_think;
	self.nextthink = time + 0.3; // don't need to update so often now

	if(time >= self.ltime)
	{
		Monster_Fade();
		return;
	}
	
	self.SendFlags |= MSF_MOVE; // keep up to date on the monster's location
}

void monsters_setstatus()
{
	self.stat_monsters_total = monsters_total;
	self.stat_monsters_killed = monsters_killed;
}

void Monster_Appear()
{
	self.enemy = activator;
	self.spawnflags &~= MONSTERFLAG_APPEAR;
	self.monster_spawnfunc();
}

float Monster_CheckAppearFlags(entity ent)
{
	if not(ent.spawnflags & MONSTERFLAG_APPEAR)
		return FALSE;
	
	ent.think = func_null;
	ent.nextthink = 0;
	ent.use = Monster_Appear;
	ent.flags = FL_MONSTER; // set so this monster can get butchered
	
	return TRUE;
}

void monsters_reset()
{
	setorigin(self, self.pos1);
	self.angles = self.pos2;
	
	self.health = self.max_health;
	self.velocity = '0 0 0';
	self.enemy = world;
	self.goalentity = world;
	self.attack_finished_single = 0;
	self.moveto = self.origin;
	
	WaypointSprite_UpdateHealth(self.sprite, self.health);
}

float monster_send(entity to, float sf)
{
	WriteByte(MSG_ENTITY, ENT_CLIENT_MONSTER);    
	WriteByte(MSG_ENTITY, sf);
	if(sf & MSF_SETUP)
	{
	    WriteByte(MSG_ENTITY, self.monsterid);
	    
	    WriteCoord(MSG_ENTITY, self.origin_x);
	    WriteCoord(MSG_ENTITY, self.origin_y);
	    WriteCoord(MSG_ENTITY, self.origin_z);
	    
	    WriteAngle(MSG_ENTITY, self.angles_x);
	    WriteAngle(MSG_ENTITY, self.angles_y);
		
		WriteByte(MSG_ENTITY, self.scale);
		WriteByte(MSG_ENTITY, self.skin);
    }
	
	if(sf & MSF_SIZE)
	{
		WriteByte(MSG_ENTITY, self.scale);
		
		WriteCoord(MSG_ENTITY, self.mins_x);
	    WriteCoord(MSG_ENTITY, self.mins_y);
	    WriteCoord(MSG_ENTITY, self.mins_z);
		
		WriteCoord(MSG_ENTITY, self.maxs_x);
	    WriteCoord(MSG_ENTITY, self.maxs_y);
	    WriteCoord(MSG_ENTITY, self.maxs_z);
	}
    
    if(sf & MSF_ANG)
    {
        WriteShort(MSG_ENTITY, rint(self.angles_x));
        WriteShort(MSG_ENTITY, rint(self.angles_y));
    }
    
    if(sf & MSF_MOVE)
    {
        WriteShort(MSG_ENTITY, rint(self.origin_x));
        WriteShort(MSG_ENTITY, rint(self.origin_y));
        WriteShort(MSG_ENTITY, rint(self.origin_z));

        WriteShort(MSG_ENTITY, rint(self.velocity_x));
        WriteShort(MSG_ENTITY, rint(self.velocity_y));
        WriteShort(MSG_ENTITY, rint(self.velocity_z));        
        
        WriteShort(MSG_ENTITY, rint(self.angles_y));        
    }
    
    if(sf & MSF_ANIM)
    {
        WriteCoord(MSG_ENTITY, self.anim_start_time);
        WriteByte(MSG_ENTITY, self.frame);
    }
    
    if(sf & MSF_STATUS)
    {
		WriteByte(MSG_ENTITY, self.skin);
		
        WriteByte(MSG_ENTITY, self.team);
        
        if(self.health <= 0)
            WriteByte(MSG_ENTITY, 0);
        else
            WriteByte(MSG_ENTITY, ceil((self.health / self.max_health) * 255));
    }
    
	return TRUE;
}

void monster_link(void() spawnproc)
{
    Net_LinkEntity(self, TRUE, 0, monster_send);
    self.think      = spawnproc;
    self.nextthink  = time;
}

void monsters_corpse_damage (entity inflictor, entity attacker, float damage, float deathtype, vector hitloc, vector force)
{
	self.health -= damage;
		
	Violence_GibSplash_At(hitloc, force, 2, bound(0, damage, 200) / 16, self, attacker);
		
	if(self.health <= -100) // 100 health until gone?
	{
		Violence_GibSplash(self, 1, 0.5, attacker);
		
		self.think = SUB_Remove;
		self.nextthink = time + 0.1;
	}
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
		
	if(deathtype != DEATH_KILL)
		damage *= self.armorvalue;
		
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
			
		// TODO: fix this?
		activator = attacker;
		other = self.enemy;
		SUB_UseTargets();
		self.target2 = self.oldtarget2; // reset to original target on death, incase we respawn
	
		self.monster_die();
		
		frag_attacker = attacker;
		frag_target = self;
		MUTATOR_CALLHOOK(MonsterDies);
		
		if(self.health <= -100) // check if we're already gibbed
		{
			Violence_GibSplash(self, 1, 0.5, attacker);
		
			self.think = SUB_Remove;
			self.nextthink = time + 0.1;
		}
	}
	
	self.SendFlags |= MSF_STATUS;
}

// used to hook into monster post death functions without a mutator
void monster_hook_death()
{
	WaypointSprite_Kill(self.sprite);
		
	if(self.weaponentity)
	{
		remove(self.weaponentity);
		self.weaponentity = world;
	}
		
	monster_sound(self.msound_death, 0, FALSE);
		
	if(!(self.spawnflags & MONSTERFLAG_SPAWNED) && !self.monster_respawned)
		monsters_killed += 1;
		
	if(self.candrop && self.weapon)
		W_ThrowNewWeapon(self, self.weapon, 0, self.origin, randomvec() * 150 + '0 0 325');	
		
	if(IS_CLIENT(self.realowner))
		self.realowner.monstercount -= 1;
		
	self.event_damage 	= monsters_corpse_damage;
	self.solid		  	= SOLID_CORPSE;
	self.takedamage	 	= DAMAGE_AIM;
	self.enemy		  	= world;
	self.movetype		= MOVETYPE_TOSS;
	self.moveto			= self.origin;
	
	if not(self.flags & FL_FLY)
		self.velocity = '0 0 0';
	
	self.SendFlags |= MSF_MOVE;
		
	totalspawned -= 1;
}

// used to hook into monster post spawn functions without a mutator
void monster_hook_spawn()
{
	if not(self.monster_respawned)
		Monster_CheckMinibossFlag();

	self.max_health = self.health;
	self.pain_finished = self.nextthink;
	self.anim_start_time = time;

	monster_precachesounds(self);
	
	if(teamplay)
		self.monster_attack = TRUE; // we can have monster enemies in team games
		
	if(autocvar_g_monsters_healthbars)
	{
		WaypointSprite_Spawn(strzone(strdecolorize(self.netname)), 0, 600, self, '0 0 1' * (self.maxs_z + 15), world, 0, self, sprite, FALSE, RADARICON_DANGER, ((self.team) ? Team_ColorRGB(self.team) : '1 0 0'));	
		WaypointSprite_UpdateMaxHealth(self.sprite, self.max_health);
		WaypointSprite_UpdateHealth(self.sprite, self.health);
	}
	
	monster_sound(self.msound_spawn, 0, FALSE);

	MUTATOR_CALLHOOK(MonsterSpawn);
	
	self.SendFlags = MSF_SETUP;
}

float monster_initialize(string  net_name, float mon_id,
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

	if(self.netname == "")
		self.netname = ((net_name == "") ? self.classname : net_name);
	
	if(autocvar_g_monsters_giants_only)
		self.spawnflags |= MONSTERFLAG_GIANT;
	
	if not(self.scale)
		self.scale = 1;
		
	if(self.spawnflags & MONSTERFLAG_GIANT && !autocvar_g_monsters_nogiants)
		self.scale = 5;
	
	if(self.team && !teamplay)
		self.team = 0;

	self.flags = FL_MONSTER;
		
	if not(self.spawnflags & MONSTERFLAG_SPAWNED) // naturally spawned monster
	if not(self.monster_respawned)
		monsters_total += 1;

	ScaleMonster(self.scale, min_s, max_s);

	self.takedamage		 	= DAMAGE_AIM;
	self.bot_attack		 	= TRUE;
	self.iscreature		 	= TRUE;
	self.teleportable	   	= TRUE;
	self.damagedbycontents	= TRUE;
	self.monsterid			= mon_id;
	self.damageforcescale   = 0.003;
	self.monster_die		= dieproc;
	self.event_damage	   	= monsters_damage;
	self.touch			  	= MonsterTouch;
	self.use				= monster_use;
	self.solid				= SOLID_BBOX;
	self.movetype			= MOVETYPE_WALK;
	self.delay				= -1; // used in attack delay code
	monsters_spawned	   += 1;
	self.enemy				= world;
	self.velocity			= '0 0 0';
	self.moveto				= self.origin;
	self.pos2				= self.angles;
	self.reset				= monsters_reset;
	self.candrop			= TRUE;
	self.view_ofs			= '0 0 1' * (self.maxs_z * 0.5);
	self.oldtarget2			= self.target2;
	
	if not(self.ticrate)
		self.ticrate = autocvar_g_monsters_think_delay;
		
	self.ticrate = bound(sys_frametime, self.ticrate, 60);
	
	if not(self.armorvalue)
		self.armorvalue = 1; // multiplier
	
	if not(self.target_range)
		self.target_range = autocvar_g_monsters_target_range;
	
	if not(self.respawntime)
		self.respawntime = autocvar_g_monsters_respawn_delay;
	
	if not(self.monster_moveflags)
		self.monster_moveflags = MONSTER_MOVE_WANDER;

	if not(nodrop)
	{
		setorigin(self, self.origin);
		tracebox(self.origin + '0 0 100', self.mins, self.maxs, self.origin - '0 0 10000', MOVE_WORLDONLY, self);
		setorigin(self, trace_endpos);
	}
	
	self.pos1 = self.origin;
	
	monster_link(spawnproc);

	return TRUE;
}
