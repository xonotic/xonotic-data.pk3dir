#if defined(CSQC)
#elif defined(MENUQC)
#elif defined(SVQC)
    #include <lib/warpzone/common.qh>
    #include "../constants.qh"
    #include "../teams.qh"
    #include "../util.qh"
    #include "all.qh"
    #include "sv_monsters.qh"
	#include "../physics/movelib.qh"
    #include "../weapons/all.qh"
    #include <server/autocvars.qh>
    #include <server/defs.qh>
    #include "../deathtypes/all.qh"
    #include <server/mutators/all.qh>
	#include <server/steerlib.qh>
	#include "../turrets/sv_turrets.qh"
	#include "../turrets/util.qh"
    #include "../vehicles/all.qh"
    #include <server/campaign.qh>
    #include <server/command/common.qh>
    #include <server/command/cmd.qh>
	#include "../triggers/triggers.qh"
    #include <lib/csqcmodel/sv_model.qh>
    #include <server/round_handler.qh>
#endif

void monsters_setstatus(entity this)
{
	this.stat_monsters_total = monsters_total;
	this.stat_monsters_killed = monsters_killed;
}

void monster_dropitem(entity this)
{
	if(!this.candrop || !this.monster_loot)
		return;

	vector org = this.origin + ((this.mins + this.maxs) * 0.5);
	entity e = new(droppedweapon); // use weapon handling to remove it on touch
	e.spawnfunc_checked = true;

	e.monster_loot = this.monster_loot;

	MUTATOR_CALLHOOK(MonsterDropItem, e);
	e = other;

	if(e && e.monster_loot)
	{
		e.noalign = true;
		WITH(entity, self, e, e.monster_loot(e));
		e.gravity = 1;
		e.movetype = MOVETYPE_TOSS;
		e.reset = SUB_Remove;
		setorigin(e, org);
		e.velocity = randomvec() * 175 + '0 0 325';
		e.item_spawnshieldtime = time + 0.7;
		SUB_SetFade(e, time + autocvar_g_monsters_drop_time, 1);
	}
}

void monster_makevectors(entity this, entity targ)
{
	if(IS_MONSTER(this))
	{
		vector v = targ.origin + (targ.mins + targ.maxs) * 0.5;
		this.v_angle = vectoangles(v - (this.origin + this.view_ofs));
		this.v_angle_x = -this.v_angle_x;
	}

	makevectors(this.v_angle);
}

// ===============
// Target handling
// ===============

bool Monster_ValidTarget(entity this, entity targ)
{
	// ensure we're not checking nonexistent monster/target
	if(!this || !targ) { return false; }

	if((targ == this)
	|| (autocvar_g_monsters_lineofsight && !checkpvs(this.origin + this.view_ofs, targ)) // enemy cannot be seen
	|| (IS_VEHICLE(targ) && !((get_monsterinfo(this.monsterid)).spawnflags & MON_FLAG_RANGED)) // melee vs vehicle is useless
	|| (time < game_starttime) // monsters do nothing before match has started
	|| (targ.takedamage == DAMAGE_NO)
	|| (targ.items & IT_INVISIBILITY)
	|| (IS_SPEC(targ) || IS_OBSERVER(targ)) // don't attack spectators
	|| (!IS_VEHICLE(targ) && (IS_DEAD(targ) || IS_DEAD(this) || targ.health <= 0 || this.health <= 0))
	|| (this.monster_follow == targ || targ.monster_follow == this)
	|| (!IS_VEHICLE(targ) && (targ.flags & FL_NOTARGET))
	|| (!autocvar_g_monsters_typefrag && targ.BUTTON_CHAT)
	|| (SAME_TEAM(targ, this))
	|| (STAT(FROZEN, targ))
	|| (targ.alpha != 0 && targ.alpha < 0.5)
	)
	{
		// if any of the above checks fail, target is not valid
		return false;
	}

	traceline(this.origin + this.view_ofs, targ.origin, 0, this);

	if((trace_fraction < 1) && (trace_ent != targ))
		return false;

	if(autocvar_g_monsters_target_infront || (this.spawnflags & MONSTERFLAG_INFRONT))
	if(this.enemy != targ)
	{
		float dot;

		makevectors (this.angles);
		dot = normalize (targ.origin - this.origin) * v_forward;

		if(dot <= autocvar_g_monsters_target_infront_range) { return false; }
	}

	return true; // this target is valid!
}

entity Monster_FindTarget(entity mon)
{
	if(MUTATOR_CALLHOOK(MonsterFindTarget)) { return mon.enemy; } // Handled by a mutator

	entity head, closest_target = world;
	head = findradius(mon.origin, mon.target_range);

	while(head) // find the closest acceptable target to pass to
	{
		if(head.monster_attack)
		if(Monster_ValidTarget(mon, head))
		{
			// if it's a player, use the view origin as reference (stolen from RadiusDamage functions in g_damage.qc)
			vector head_center = CENTER_OR_VIEWOFS(head);
			vector ent_center = CENTER_OR_VIEWOFS(mon);

			if(closest_target)
			{
				vector closest_target_center = CENTER_OR_VIEWOFS(closest_target);
				if(vlen(ent_center - head_center) < vlen(ent_center - closest_target_center))
					{ closest_target = head; }
			}
			else { closest_target = head; }
		}

		head = head.chain;
	}

	return closest_target;
}

void monster_setupcolors(entity mon)
{
	if(IS_PLAYER(mon.realowner))
		mon.colormap = mon.realowner.colormap;
	else if(teamplay && mon.team)
		mon.colormap = 1024 + (mon.team - 1) * 17;
	else
	{
		if(mon.monster_skill <= MONSTER_SKILL_EASY)
			mon.colormap = 1029;
		else if(mon.monster_skill <= MONSTER_SKILL_MEDIUM)
			mon.colormap = 1027;
		else if(mon.monster_skill <= MONSTER_SKILL_HARD)
			mon.colormap = 1038;
		else if(mon.monster_skill <= MONSTER_SKILL_INSANE)
			mon.colormap = 1028;
		else if(mon.monster_skill <= MONSTER_SKILL_NIGHTMARE)
			mon.colormap = 1032;
		else
			mon.colormap = 1024;
	}
}

void monster_changeteam(entity ent, float newteam)
{
	if(!teamplay) { return; }

	ent.team = newteam;
	ent.monster_attack = true; // new team, activate attacking
	monster_setupcolors(ent);

	if(ent.sprite)
	{
		WaypointSprite_UpdateTeamRadar(ent.sprite, RADARICON_DANGER, ((newteam) ? Team_ColorRGB(newteam) : '1 0 0'));

		ent.sprite.team = newteam;
		ent.sprite.SendFlags |= 1;
	}
}

.void(entity) monster_delayedfunc;
void Monster_Delay_Action_self();
void Monster_Delay_Action(entity this)
{
	if(Monster_ValidTarget(this.owner, this.owner.enemy)) { this.monster_delayedfunc(this.owner); }

	if(this.cnt > 1)
	{
		this.cnt -= 1;
		this.think = Monster_Delay_Action_self;
		this.nextthink = time + this.count;
	}
	else
	{
		this.think = SUB_Remove_self;
		this.nextthink = time;
	}
}

void Monster_Delay_Action_self()
{
	Monster_Delay_Action(self);
}

void Monster_Delay(entity this, int repeat_count, float defer_amnt, void(entity) func)
{
	// deferred attacking, checks if monster is still alive and target is still valid before attacking
	entity e = spawn();

	e.think = Monster_Delay_Action_self;
	e.nextthink = time + defer_amnt;
	e.count = defer_amnt;
	e.owner = this;
	e.monster_delayedfunc = func;
	e.cnt = repeat_count;
}


// ==============
// Monster sounds
// ==============

string get_monster_model_datafilename(string m, float sk, string fil)
{
	if(m)
		m = strcat(m, "_");
	else
		m = "models/monsters/*_";
	if(sk >= 0)
		m = strcat(m, ftos(sk));
	else
		m = strcat(m, "*");
	return strcat(m, ".", fil);
}

void Monster_Sound_Precache(string f)
{
	float fh;
	string s;
	fh = fopen(f, FILE_READ);
	if(fh < 0)
		return;
	while((s = fgets(fh)))
	{
		if(tokenize_console(s) != 3)
		{
			LOG_TRACE("Invalid sound info line: ", s, "\n");
			continue;
		}
		PrecacheGlobalSound(strcat(argv(1), " ", argv(2)));
	}
	fclose(fh);
}

void Monster_Sounds_Precache(entity this)
{
	string m = (Monsters_from(this.monsterid)).m_model.model_str();
	float globhandle, n, i;
	string f;

	globhandle = search_begin(strcat(m, "_*.sounds"), true, false);
	if (globhandle < 0)
		return;
	n = search_getsize(globhandle);
	for (i = 0; i < n; ++i)
	{
		//print(search_getfilename(globhandle, i), "\n");
		f = search_getfilename(globhandle, i);
		Monster_Sound_Precache(f);
	}
	search_end(globhandle);
}

void Monster_Sounds_Clear(entity this)
{
#define _MSOUND(m) if(this.monstersound_##m) { strunzone(this.monstersound_##m); this.monstersound_##m = string_null; }
	ALLMONSTERSOUNDS
#undef _MSOUND
}

.string Monster_Sound_SampleField(string type)
{
	GetMonsterSoundSampleField_notFound = 0;
	switch(type)
	{
#define _MSOUND(m) case #m: return monstersound_##m;
		ALLMONSTERSOUNDS
#undef _MSOUND
	}
	GetMonsterSoundSampleField_notFound = 1;
	return string_null;
}

bool Monster_Sounds_Load(entity this, string f, int first)
{
	float fh;
	string s;
	var .string field;
	fh = fopen(f, FILE_READ);
	if(fh < 0)
	{
		LOG_TRACE("Monster sound file not found: ", f, "\n");
		return false;
	}
	while((s = fgets(fh)))
	{
		if(tokenize_console(s) != 3)
			continue;
		field = Monster_Sound_SampleField(argv(0));
		if(GetMonsterSoundSampleField_notFound)
			continue;
		if (this.(field))
			strunzone(this.(field));
		this.(field) = strzone(strcat(argv(1), " ", argv(2)));
	}
	fclose(fh);
	return true;
}

.int skin_for_monstersound;
void Monster_Sounds_Update(entity this)
{
	if(this.skin == this.skin_for_monstersound) { return; }

	this.skin_for_monstersound = this.skin;
	Monster_Sounds_Clear(this);
	if(!Monster_Sounds_Load(this, get_monster_model_datafilename(this.model, this.skin, "sounds"), 0))
		Monster_Sounds_Load(this, get_monster_model_datafilename(this.model, 0, "sounds"), 0);
}

void Monster_Sound(entity this, .string samplefield, float sound_delay, float delaytoo, float chan)
{
	if(!autocvar_g_monsters_sounds) { return; }

	if(delaytoo)
	if(time < this.msound_delay)
		return; // too early
	GlobalSound_string(this, this.(samplefield), chan, VOICETYPE_PLAYERSOUND);

	this.msound_delay = time + sound_delay;
}


// =======================
// Monster attack handlers
// =======================

bool Monster_Attack_Melee(entity this, entity targ, float damg, vector anim, float er, float animtime, int deathtype, bool dostop)
{
	if(dostop && IS_MONSTER(this)) { this.state = MONSTER_ATTACK_MELEE; }

	setanim(this, anim, false, true, false);

	if(this.animstate_endtime > time && IS_MONSTER(this))
		this.attack_finished_single[0] = this.anim_finished = this.animstate_endtime;
	else
		this.attack_finished_single[0] = this.anim_finished = time + animtime;

	monster_makevectors(this, targ);

	traceline(this.origin + this.view_ofs, this.origin + v_forward * er, 0, this);

	if(trace_ent.takedamage)
		Damage(trace_ent, this, this, damg * MONSTER_SKILLMOD(this), deathtype, trace_ent.origin, normalize(trace_ent.origin - this.origin));

	return true;
}

bool Monster_Attack_Leap_Check(entity this, vector vel)
{
	if(this.state && IS_MONSTER(this))
		return false; // already attacking
	if(!IS_ONGROUND(this))
		return false; // not on the ground
	if(this.health <= 0 || IS_DEAD(this))
		return false; // called when dead?
	if(time < this.attack_finished_single[0])
		return false; // still attacking

	vector old = this.velocity;

	this.velocity = vel;
	tracetoss(this, this);
	this.velocity = old;
	if (trace_ent != this.enemy)
		return false;

	return true;
}

bool Monster_Attack_Leap(entity this, vector anm, void() touchfunc, vector vel, float animtime)
{
	if(!Monster_Attack_Leap_Check(this, vel))
		return false;

	setanim(this, anm, false, true, false);

	if(this.animstate_endtime > time && (this.flags & FL_MONSTER))
		this.attack_finished_single[0] = this.anim_finished = this.animstate_endtime;
	else
		this.attack_finished_single[0] = this.anim_finished = time + animtime;

	if(this.flags & FL_MONSTER)
		this.state = MONSTER_ATTACK_RANGED;
	this.touch = touchfunc;
	this.origin_z += 1;
	this.velocity = vel;
	UNSET_ONGROUND(this);

	return true;
}

void Monster_Attack_Check(entity this, entity targ)
{
	if((this == world || targ == world)
	|| (!this.monster_attackfunc)
	|| (time < this.attack_finished_single[0])
	) { return; }

	float targ_vlen = vlen(targ.origin - this.origin);

	if(targ_vlen <= this.attack_range)
	{
		bool attack_success = this.monster_attackfunc(MONSTER_ATTACK_MELEE, this, targ);
		if(attack_success == 1)
			Monster_Sound(this, monstersound_melee, 0, false, CH_VOICE);
		else if(attack_success > 0)
			return;
	}

	if(targ_vlen > this.attack_range)
	{
		float attack_success = this.monster_attackfunc(MONSTER_ATTACK_RANGED, this, targ);
		if(attack_success == 1)
			Monster_Sound(this, monstersound_melee, 0, false, CH_VOICE);
		else if(attack_success > 0)
			return;
	}
}


// ======================
// Main monster functions
// ======================

void Monster_UpdateModel(entity this)
{
	// assume some defaults
	/*this.anim_idle   = animfixfps(this, '0 1 0.01', '0 0 0');
	this.anim_walk   = animfixfps(this, '1 1 0.01', '0 0 0');
	this.anim_run    = animfixfps(this, '2 1 0.01', '0 0 0');
	this.anim_fire1  = animfixfps(this, '3 1 0.01', '0 0 0');
	this.anim_fire2  = animfixfps(this, '4 1 0.01', '0 0 0');
	this.anim_melee  = animfixfps(this, '5 1 0.01', '0 0 0');
	this.anim_pain1  = animfixfps(this, '6 1 0.01', '0 0 0');
	this.anim_pain2  = animfixfps(this, '7 1 0.01', '0 0 0');
	this.anim_die1   = animfixfps(this, '8 1 0.01', '0 0 0');
	this.anim_die2   = animfixfps(this, '9 1 0.01', '0 0 0');*/

	// then get the real values
	Monster mon = get_monsterinfo(this.monsterid);
	mon.mr_anim(mon, this);
}

void Monster_Touch()
{SELFPARAM();
	if(other == world) { return; }

	if(other.monster_attack)
	if(self.enemy != other)
	if(!IS_MONSTER(other))
	if(Monster_ValidTarget(self, other))
		self.enemy = other;
}

void Monster_Miniboss_Check(entity this)
{
	if(MUTATOR_CALLHOOK(MonsterCheckBossFlag, this))
		return;

	float chance = random() * 100;

	// g_monsters_miniboss_chance cvar or spawnflags 64 causes a monster to be a miniboss
	if ((this.spawnflags & MONSTERFLAG_MINIBOSS) || (chance < autocvar_g_monsters_miniboss_chance))
	{
		this.health += autocvar_g_monsters_miniboss_healthboost;
		this.effects |= EF_RED;
		if(!this.weapon)
			this.weapon = WEP_VORTEX.m_id;
	}
}

bool Monster_Respawn_Check(entity this)
{
	if(this.deadflag == DEAD_DEAD) // don't call when monster isn't dead
	if(MUTATOR_CALLHOOK(MonsterRespawn, this))
		return true; // enabled by a mutator

	if(this.spawnflags & MONSTERFLAG_NORESPAWN)
		return false;

	if(!autocvar_g_monsters_respawn)
		return false;

	return true;
}

void Monster_Respawn() { SELFPARAM(); Monster_Spawn(self, self.monsterid); }

void Monster_Dead_Fade(entity this)
{
	if(Monster_Respawn_Check(this))
	{
		this.spawnflags |= MONSTERFLAG_RESPAWNED;
		this.think = Monster_Respawn;
		this.nextthink = time + this.respawntime;
		this.monster_lifetime = 0;
		this.deadflag = DEAD_RESPAWNING;
		if(this.spawnflags & MONSTER_RESPAWN_DEATHPOINT)
		{
			this.pos1 = this.origin;
			this.pos2 = this.angles;
		}
		this.event_damage = func_null;
		this.takedamage = DAMAGE_NO;
		setorigin(this, this.pos1);
		this.angles = this.pos2;
		this.health = this.max_health;
		setmodel(this, MDL_Null);
	}
	else
	{
		// number of monsters spawned with mobspawn command
		totalspawned -= 1;

		SUB_SetFade(this, time + 3, 1);
	}
}

void Monster_Use()
{SELFPARAM();
	if(Monster_ValidTarget(self, activator)) { self.enemy = activator; }
}

vector Monster_Move_Target(entity this, entity targ)
{
	// enemy is always preferred target
	if(this.enemy)
	{
		vector targ_origin = ((this.enemy.absmin + this.enemy.absmax) * 0.5);
		targ_origin = WarpZone_RefSys_TransformOrigin(this.enemy, this, targ_origin); // origin of target as seen by the monster (us)
		WarpZone_TraceLine(this.origin, targ_origin, MOVE_NOMONSTERS, this);

		if((this.enemy == world)
			|| (IS_DEAD(this.enemy) || this.enemy.health < 1)
			|| (STAT(FROZEN, this.enemy))
			|| (this.enemy.flags & FL_NOTARGET)
			|| (this.enemy.alpha < 0.5 && this.enemy.alpha != 0)
			|| (this.enemy.takedamage == DAMAGE_NO)
			|| (vlen(this.origin - targ_origin) > this.target_range)
			|| ((trace_fraction < 1) && (trace_ent != this.enemy)))
		{
			this.enemy = world;
			this.pass_distance = 0;
		}

		if(this.enemy)
		{
			/*WarpZone_TrailParticles(world, particleeffectnum(EFFECT_RED_PASS), this.origin, targ_origin);
			print("Trace origin: ", vtos(targ_origin), "\n");
			print("Target origin: ", vtos(this.enemy.origin), "\n");
			print("My origin: ", vtos(this.origin), "\n"); */

			this.monster_movestate = MONSTER_MOVE_ENEMY;
			this.last_trace = time + 1.2;
			if(this.monster_moveto)
				return this.monster_moveto; // assumes code is properly setting this when monster has an enemy
			else
				return targ_origin;
		}

		/*makevectors(this.angles);
		this.monster_movestate = MONSTER_MOVE_ENEMY;
		this.last_trace = time + 1.2;
		return this.enemy.origin; */
	}

	switch(this.monster_moveflags)
	{
		case MONSTER_MOVE_FOLLOW:
		{
			this.monster_movestate = MONSTER_MOVE_FOLLOW;
			this.last_trace = time + 0.3;
			return (this.monster_follow) ? this.monster_follow.origin : this.origin;
		}
		case MONSTER_MOVE_SPAWNLOC:
		{
			this.monster_movestate = MONSTER_MOVE_SPAWNLOC;
			this.last_trace = time + 2;
			return this.pos1;
		}
		case MONSTER_MOVE_NOMOVE:
		{
			if(this.monster_moveto)
			{
				this.last_trace = time + 0.5;
				return this.monster_moveto;
			}
			else
			{
				this.monster_movestate = MONSTER_MOVE_NOMOVE;
				this.last_trace = time + 2;
			}
			return this.origin;
		}
		default:
		case MONSTER_MOVE_WANDER:
		{
			vector pos;
			this.monster_movestate = MONSTER_MOVE_WANDER;

			if(this.monster_moveto)
			{
				this.last_trace = time + 0.5;
				pos = this.monster_moveto;
			}
			else if(targ)
			{
				this.last_trace = time + 0.5;
				pos = targ.origin;
			}
			else
			{
				this.last_trace = time + this.wander_delay;

				this.angles_y = rint(random() * 500);
				makevectors(this.angles);
				pos = this.origin + v_forward * this.wander_distance;

				if(((this.flags & FL_FLY) && (this.spawnflags & MONSTERFLAG_FLY_VERTICAL)) || (this.flags & FL_SWIM))
				{
					pos.z = random() * 200;
					if(random() >= 0.5)
						pos.z *= -1;
				}
			}

			return pos;
		}
	}
}

void Monster_CalculateVelocity(entity this, vector to, vector from, float turnrate, float movespeed)
{
	float current_distance = vlen((('1 0 0' * to.x) + ('0 1 0' * to.y)) - (('1 0 0' * from.x) + ('0 1 0' * from.y))); // for the sake of this check, exclude Z axis
	float initial_height = 0; //min(50, (targ_distance * tanh(20)));
	float current_height = (initial_height * min(1, (this.pass_distance) ? (current_distance / this.pass_distance) : current_distance));
	//print("current_height = ", ftos(current_height), ", initial_height = ", ftos(initial_height), ".\n");

	vector targpos;
	if(current_height) // make sure we can actually do this arcing path
	{
		targpos = (to + ('0 0 1' * current_height));
		WarpZone_TraceLine(this.origin, targpos, MOVE_NOMONSTERS, this);
		if(trace_fraction < 1)
		{
			//print("normal arc line failed, trying to find new pos...");
			WarpZone_TraceLine(to, targpos, MOVE_NOMONSTERS, this);
			targpos = (trace_endpos + '0 0 -10');
			WarpZone_TraceLine(this.origin, targpos, MOVE_NOMONSTERS, this);
			if(trace_fraction < 1) { targpos = to; /* print(" ^1FAILURE^7, reverting to original direction.\n"); */ }
			/*else { print(" ^3SUCCESS^7, using new arc line.\n"); } */
		}
	}
	else { targpos = to; }

	//this.angles = normalize(('0 1 0' * to_y) - ('0 1 0' * from_y));

	vector desired_direction = normalize(targpos - from);
	if(turnrate) { this.velocity = (normalize(normalize(this.velocity) + (desired_direction * 50)) * movespeed); }
	else { this.velocity = (desired_direction * movespeed); }

	//this.steerto = steerlib_attract2(targpos, 0.5, 500, 0.95);
	//this.angles = vectoangles(this.velocity);
}

void Monster_Move(entity this, float runspeed, float walkspeed, float stpspeed)
{
	if(this.target2) { this.goalentity = find(world, targetname, this.target2); }

	entity targ;

	if(STAT(FROZEN, this) == 2)
	{
		this.revive_progress = bound(0, this.revive_progress + this.ticrate * this.revive_speed, 1);
		this.health = max(1, this.revive_progress * this.max_health);
		this.iceblock.alpha = bound(0.2, 1 - this.revive_progress, 1);

		if(!(this.spawnflags & MONSTERFLAG_INVINCIBLE) && this.sprite)
			WaypointSprite_UpdateHealth(this.sprite, this.health);

		movelib_brake_simple(this, stpspeed);
		setanim(this, this.anim_idle, true, false, false);

		this.enemy = world;
		this.nextthink = time + this.ticrate;

		if(this.revive_progress >= 1)
			Unfreeze(this);

		return;
	}
	else if(STAT(FROZEN, this) == 3)
	{
		this.revive_progress = bound(0, this.revive_progress - this.ticrate * this.revive_speed, 1);
		this.health = max(0, autocvar_g_nades_ice_health + (this.max_health-autocvar_g_nades_ice_health) * this.revive_progress );

		if(!(this.spawnflags & MONSTERFLAG_INVINCIBLE) && this.sprite)
			WaypointSprite_UpdateHealth(this.sprite, this.health);

		movelib_brake_simple(this, stpspeed);
		setanim(this, this.anim_idle, true, false, false);

		this.enemy = world;
		this.nextthink = time + this.ticrate;

		if(this.health < 1)
		{
			Unfreeze(this);
			this.health = 0;
			if(this.event_damage)
				this.event_damage(this, this.frozen_by, 1, DEATH_NADE_ICE_FREEZE.m_id, this.origin, '0 0 0');
		}

		else if ( this.revive_progress <= 0 )
			Unfreeze(this);

		return;
	}

	if(this.flags & FL_SWIM)
	{
		if(this.waterlevel < WATERLEVEL_WETFEET)
		{
			if(time >= this.last_trace)
			{
				this.last_trace = time + 0.4;

				Damage (this, world, world, 2, DEATH_DROWN.m_id, this.origin, '0 0 0');
				this.angles = '90 90 0';
				if(random() < 0.5)
				{
					this.velocity_y += random() * 50;
					this.velocity_x -= random() * 50;
				}
				else
				{
					this.velocity_y -= random() * 50;
					this.velocity_x += random() * 50;
				}
				this.velocity_z += random() * 150;
			}


			this.movetype = MOVETYPE_BOUNCE;
			//this.velocity_z = -200;

			return;
		}
		else if(this.movetype == MOVETYPE_BOUNCE)
		{
			this.angles_x = 0;
			this.movetype = MOVETYPE_WALK;
		}
	}

	targ = this.goalentity;

	if (MUTATOR_CALLHOOK(MonsterMove, this, runspeed, walkspeed, targ)
		|| gameover
		|| this.draggedby != world
		|| (round_handler_IsActive() && !round_handler_IsRoundStarted())
		|| time < game_starttime
		|| (autocvar_g_campaign && !campaign_bots_may_start)
		|| time < this.spawn_time)
	{
		runspeed = walkspeed = 0;
		if(time >= this.spawn_time)
			setanim(this, this.anim_idle, true, false, false);
		movelib_brake_simple(this, stpspeed);
		return;
	}

	targ = monster_target;
	runspeed = bound(0, monster_speed_run * MONSTER_SKILLMOD(this), runspeed * 2.5); // limit maxspeed to prevent craziness
	walkspeed = bound(0, monster_speed_walk * MONSTER_SKILLMOD(this), walkspeed * 2.5); // limit maxspeed to prevent craziness

	if(teamplay)
	if(autocvar_g_monsters_teams)
	if(DIFF_TEAM(this.monster_follow, this))
		this.monster_follow = world;

	if(time >= this.last_enemycheck)
	{
		if(!this.enemy)
		{
			this.enemy = Monster_FindTarget(this);
			if(this.enemy)
			{
				WarpZone_RefSys_Copy(this.enemy, this);
				WarpZone_RefSys_AddInverse(this.enemy, this); // wz1^-1 ... wzn^-1 receiver
				this.moveto = WarpZone_RefSys_TransformOrigin(this.enemy, this, (0.5 * (this.enemy.absmin + this.enemy.absmax)));
				this.monster_moveto = '0 0 0';
				this.monster_face = '0 0 0';

				this.pass_distance = vlen((('1 0 0' * this.enemy.origin_x) + ('0 1 0' * this.enemy.origin_y)) - (('1 0 0' *  this.origin_x) + ('0 1 0' *  this.origin_y)));
				Monster_Sound(this, monstersound_sight, 0, false, CH_VOICE);
			}
		}

		this.last_enemycheck = time + 1; // check for enemies every second
	}

	if(this.state == MONSTER_ATTACK_RANGED && IS_ONGROUND(this))
	{
		this.state = 0;
		this.touch = Monster_Touch;
	}

	if(this.state && time >= this.attack_finished_single[0])
		this.state = 0; // attack is over

	if(this.state != MONSTER_ATTACK_MELEE) // don't move if set
	if(time >= this.last_trace || this.enemy) // update enemy or rider instantly
		this.moveto = Monster_Move_Target(this, targ);

	if(!this.enemy)
		Monster_Sound(this, monstersound_idle, 7, true, CH_VOICE);

	if(this.state == MONSTER_ATTACK_MELEE)
		this.moveto = this.origin;

	if(this.enemy && this.enemy.vehicle)
		runspeed = 0;

	if(!(this.spawnflags & MONSTERFLAG_FLY_VERTICAL) && !(this.flags & FL_SWIM))
		this.moveto_z = this.origin_z;

	if(vlen(this.origin - this.moveto) > 100)
	{
		float do_run = (this.enemy || this.monster_moveto);
		if(IS_ONGROUND(this) || ((this.flags & FL_FLY) || (this.flags & FL_SWIM)))
			Monster_CalculateVelocity(this, this.moveto, this.origin, true, ((do_run) ? runspeed : walkspeed));

		if(time > this.pain_finished) // TODO: use anim_finished instead!
		if(!this.state)
		if(time > this.anim_finished)
		if(vlen(this.velocity) > 10)
			setanim(this, ((do_run) ? this.anim_run : this.anim_walk), true, false, false);
		else
			setanim(this, this.anim_idle, true, false, false);
	}
	else
	{
		entity e = find(world, targetname, this.target2);
		if(e.target2)
			this.target2 = e.target2;
		else if(e.target)
			this.target2 = e.target;

		movelib_brake_simple(this, stpspeed);
		if(time > this.anim_finished)
		if(time > this.pain_finished)
		if(!this.state)
		if(vlen(this.velocity) <= 30)
			setanim(this, this.anim_idle, true, false, false);
	}

	this.steerto = steerlib_attract2(this, ((this.monster_face) ? this.monster_face : this.moveto), 0.5, 500, 0.95);

	vector real_angle = vectoangles(this.steerto) - this.angles;
	float turny = 25;
	if(this.state == MONSTER_ATTACK_MELEE)
		turny = 0;
	if(turny)
	{
		turny = bound(turny * -1, shortangle_f(real_angle.y, this.angles.y), turny);
		this.angles_y += turny;
	}

	Monster_Attack_Check(this, this.enemy);
}

void Monster_Remove(entity this)
{
	.entity weaponentity = weaponentities[0];
	if(!this) { return; }

	if(!MUTATOR_CALLHOOK(MonsterRemove, this))
		Send_Effect(EFFECT_ITEM_PICKUP, this.origin, '0 0 0', 1);

	if(this.(weaponentity)) { remove(this.(weaponentity)); }
	if(this.iceblock) { remove(this.iceblock); }
	WaypointSprite_Kill(this.sprite);
	remove(this);
}

void Monster_Dead_Think()
{SELFPARAM();
	self.nextthink = time + self.ticrate;

	if(self.monster_lifetime != 0)
	if(time >= self.monster_lifetime)
	{
		Monster_Dead_Fade(self);
		return;
	}
}

void Monster_Appear()
{SELFPARAM();
	self.enemy = activator;
	self.spawnflags &= ~MONSTERFLAG_APPEAR; // otherwise, we get an endless loop
	Monster_Spawn(self, self.monsterid);
}

bool Monster_Appear_Check(entity this, int monster_id)
{
	if(!(this.spawnflags & MONSTERFLAG_APPEAR))
		return false;

	this.think = func_null;
	this.monsterid = monster_id; // set so this monster is properly registered (otherwise, normal initialization is used)
	this.nextthink = 0;
	this.use = Monster_Appear;
	this.flags = FL_MONSTER; // set so this monster can get butchered

	return true;
}

void Monster_Reset(entity this)
{
	setorigin(this, this.pos1);
	this.angles = this.pos2;

	Unfreeze(this); // remove any icy remains

	this.health = this.max_health;
	this.velocity = '0 0 0';
	this.enemy = world;
	this.goalentity = world;
	this.attack_finished_single[0] = 0;
	this.moveto = this.origin;
}

void Monster_Dead_Damage(entity inflictor, entity attacker, float damage, int deathtype, vector hitloc, vector force)
{SELFPARAM();
	self.health -= damage;

	Violence_GibSplash_At(hitloc, force, 2, bound(0, damage, 200) / 16, self, attacker);

	if(self.health <= -50) // 100 health until gone?
	{
		Violence_GibSplash_At(hitloc, force, 2, bound(0, damage, 200) / 16, self, attacker);

		// number of monsters spawned with mobspawn command
		totalspawned -= 1;

		self.think = SUB_Remove_self;
		self.nextthink = time + 0.1;
		self.event_damage = func_null;
	}
}

void Monster_Dead(entity this, entity attacker, float gibbed)
{
	this.think = Monster_Dead_Think;
	this.nextthink = time;
	this.monster_lifetime = time + 5;

	if(STAT(FROZEN, this))
	{
		Unfreeze(this); // remove any icy remains
		this.health = 0; // reset by Unfreeze
	}

	monster_dropitem(this);

	Monster_Sound(this, monstersound_death, 0, false, CH_VOICE);

	if(!(this.spawnflags & MONSTERFLAG_SPAWNED) && !(this.spawnflags & MONSTERFLAG_RESPAWNED))
		monsters_killed += 1;

	if(IS_PLAYER(attacker))
	if(autocvar_g_monsters_score_spawned || !((this.spawnflags & MONSTERFLAG_SPAWNED) || (this.spawnflags & MONSTERFLAG_RESPAWNED)))
		PlayerScore_Add(attacker, SP_SCORE, +autocvar_g_monsters_score_kill);

	if(gibbed)
	{
		// number of monsters spawned with mobspawn command
		totalspawned -= 1;
	}

	this.event_damage	= ((gibbed) ? func_null : Monster_Dead_Damage);
	this.solid			= SOLID_CORPSE;
	this.takedamage		= DAMAGE_AIM;
	this.deadflag		= DEAD_DEAD;
	this.enemy			= world;
	this.movetype		= MOVETYPE_TOSS;
	this.moveto			= this.origin;
	this.touch			= Monster_Touch; // reset incase monster was pouncing
	this.reset			= func_null;
	this.state			= 0;
	this.attack_finished_single[0] = 0;
	this.effects = 0;

	if(!((this.flags & FL_FLY) || (this.flags & FL_SWIM)))
		this.velocity = '0 0 0';

	CSQCModel_UnlinkEntity(this);

	Monster mon = get_monsterinfo(this.monsterid);
	mon.mr_death(mon, this);

	if(this.candrop && this.weapon)
		W_ThrowNewWeapon(this, this.weapon, 0, this.origin, randomvec() * 150 + '0 0 325');
}

void Monster_Damage(entity inflictor, entity attacker, float damage, int deathtype, vector hitloc, vector force)
{SELFPARAM();
	if((self.spawnflags & MONSTERFLAG_INVINCIBLE) && deathtype != DEATH_KILL.m_id && !ITEM_DAMAGE_NEEDKILL(deathtype))
		return;

	if(STAT(FROZEN, self) && deathtype != DEATH_KILL.m_id && deathtype != DEATH_NADE_ICE_FREEZE.m_id)
		return;

	//if(time < self.pain_finished && deathtype != DEATH_KILL.m_id)
		//return;

	if(time < self.spawnshieldtime && deathtype != DEATH_KILL.m_id)
		return;

	if(deathtype == DEATH_FALL.m_id && self.draggedby != world)
		return;

	vector v;
	float take, save;

	v = healtharmor_applydamage(100, self.armorvalue / 100, deathtype, damage);
	take = v_x;
	save = v_y;

	damage_take = take;
	frag_attacker = attacker;
	frag_deathtype = deathtype;
	Monster mon = get_monsterinfo(self.monsterid);
	mon.mr_pain(mon, self);
	take = damage_take;

	if(take)
	{
		self.health -= take;
		Monster_Sound(self, monstersound_pain, 1.2, true, CH_PAIN);
	}

	if(self.sprite)
		WaypointSprite_UpdateHealth(self.sprite, self.health);

	self.dmg_time = time;

	if(sound_allowed(MSG_BROADCAST, attacker) && deathtype != DEATH_DROWN.m_id)
		spamsound (self, CH_PAIN, SND(BODYIMPACT1), VOL_BASE, ATTEN_NORM);  // FIXME: PLACEHOLDER

	self.velocity += force * self.damageforcescale;

	if(deathtype != DEATH_DROWN.m_id && take)
	{
		Violence_GibSplash_At(hitloc, force, 2, bound(0, take, 200) / 16, self, attacker);
		if (take > 50)
			Violence_GibSplash_At(hitloc, force * -0.1, 3, 1, self, attacker);
		if (take > 100)
			Violence_GibSplash_At(hitloc, force * -0.2, 3, 1, self, attacker);
	}

	if(self.health <= 0)
	{
		if(deathtype == DEATH_KILL.m_id)
			self.candrop = false; // killed by mobkill command

		// TODO: fix this?
		activator = attacker;
		other = self.enemy;
		SUB_UseTargets();
		self.target2 = self.oldtarget2; // reset to original target on death, incase we respawn

		Monster_Dead(self, attacker, (self.health <= -100 || deathtype == DEATH_KILL.m_id));

		WaypointSprite_Kill(self.sprite);

		frag_target = self;
		MUTATOR_CALLHOOK(MonsterDies, attacker);

		if(self.health <= -100 || deathtype == DEATH_KILL.m_id) // check if we're already gibbed
		{
			Violence_GibSplash(self, 1, 0.5, attacker);

			self.think = SUB_Remove_self;
			self.nextthink = time + 0.1;
		}
	}
}

// don't check for enemies, just keep walking in a straight line
void Monster_Move_2D(entity this, float mspeed, bool allow_jumpoff)
{
	if(gameover || (round_handler_IsActive() && !round_handler_IsRoundStarted()) || this.draggedby != world || time < game_starttime || (autocvar_g_campaign && !campaign_bots_may_start) || time < this.spawn_time)
	{
		mspeed = 0;
		if(time >= this.spawn_time)
			setanim(this, this.anim_idle, true, false, false);
		movelib_brake_simple(this, 0.6);
		return;
	}

	float reverse = false;
	vector a, b;

	makevectors(this.angles);
	a = this.origin + '0 0 16';
	b = this.origin + '0 0 16' + v_forward * 32;

	traceline(a, b, MOVE_NORMAL, this);

	if(trace_fraction != 1.0)
	{
		reverse = true;

		if(trace_ent)
		if(IS_PLAYER(trace_ent) && !(trace_ent.items & IT_STRENGTH))
			reverse = false;
	}

	// TODO: fix this... tracing is broken if the floor is thin
	/*
	if(!allow_jumpoff)
	{
		a = b - '0 0 32';
		traceline(b, a, MOVE_WORLDONLY, this);
		if(trace_fraction == 1.0)
			reverse = true;
	} */

	if(reverse)
	{
		this.angles_y = anglemods(this.angles_y - 180);
		makevectors(this.angles);
	}

	movelib_move_simple_gravity(this, v_forward, mspeed, 1);

	if(time > this.pain_finished)
	if(time > this.attack_finished_single[0])
	if(vlen(this.velocity) > 10)
		setanim(this, this.anim_walk, true, false, false);
	else
		setanim(this, this.anim_idle, true, false, false);
}

void Monster_Anim(entity this)
{
	int deadbits = (this.anim_state & (ANIMSTATE_DEAD1 | ANIMSTATE_DEAD2));
	if(IS_DEAD(this))
	{
		if (!deadbits)
		{
			// Decide on which death animation to use.
			if(random() < 0.5)
				deadbits = ANIMSTATE_DEAD1;
			else
				deadbits = ANIMSTATE_DEAD2;
		}
	}
	else
	{
		// Clear a previous death animation.
		deadbits = 0;
	}
	int animbits = deadbits;
	if(STAT(FROZEN, this))
		animbits |= ANIMSTATE_FROZEN;
	if(this.crouch)
		animbits |= ANIMSTATE_DUCK; // not that monsters can crouch currently...
	animdecide_setstate(this, animbits, false);
	animdecide_setimplicitstate(this, (IS_ONGROUND(this)));

	/* // weapon entities for monsters?
	if (this.weaponentity)
	{
		updateanim(this.weaponentity);
		if (!this.weaponentity.animstate_override)
			setanim(this.weaponentity, this.weaponentity.anim_idle, true, false, false);
	}
	*/
}

void Monster_Think()
{SELFPARAM();
	self.think = Monster_Think;
	self.nextthink = self.ticrate;

	if(self.monster_lifetime)
	if(time >= self.monster_lifetime)
	{
		Damage(self, self, self, self.health + self.max_health, DEATH_KILL.m_id, self.origin, self.origin);
		return;
	}

	Monster mon = get_monsterinfo(self.monsterid);
	if(mon.mr_think(mon, self))
		Monster_Move(self, self.speed2, self.speed, self.stopspeed);

	Monster_Anim(self);

	CSQCMODEL_AUTOUPDATE(self);
}

bool Monster_Spawn_Setup(entity this)
{
	Monster mon = Monsters_from(this.monsterid);
	mon.mr_setup(mon, this);

	// ensure some basic needs are met
	if(!this.health) { this.health = 100; }
	if(!this.armorvalue) { this.armorvalue = bound(0.2, 0.5 * MONSTER_SKILLMOD(this), 0.9); }
	if(!this.target_range) { this.target_range = autocvar_g_monsters_target_range; }
	if(!this.respawntime) { this.respawntime = autocvar_g_monsters_respawn_delay; }
	if(!this.monster_moveflags) { this.monster_moveflags = MONSTER_MOVE_WANDER; }
	if(!this.attack_range) { this.attack_range = autocvar_g_monsters_attack_range; }
	if(!this.damageforcescale) { this.damageforcescale = autocvar_g_monsters_damageforcescale; }

	if(!(this.spawnflags & MONSTERFLAG_RESPAWNED))
	{
		Monster_Miniboss_Check(this);
		this.health *= MONSTER_SKILLMOD(this);

		if(!this.skin)
			this.skin = rint(random() * 4);
	}

	this.max_health = this.health;
	this.pain_finished = this.nextthink;

	if(IS_PLAYER(this.monster_follow))
		this.effects |= EF_DIMLIGHT;

	if(!this.wander_delay) { this.wander_delay = 2; }
	if(!this.wander_distance) { this.wander_distance = 600; }

	Monster_Sounds_Precache(this);
	Monster_Sounds_Update(this);

	if(teamplay)
		this.monster_attack = true; // we can have monster enemies in team games

	Monster_Sound(this, monstersound_spawn, 0, false, CH_VOICE);

	if(autocvar_g_monsters_healthbars)
	{
		entity wp = WaypointSprite_Spawn(WP_Monster, 0, 1024, this, '0 0 1' * (this.maxs.z + 15), world, this.team, this, sprite, true, RADARICON_DANGER);
		wp.wp_extra = this.monsterid;
		wp.colormod = ((this.team) ? Team_ColorRGB(this.team) : '1 0 0');
		if(!(this.spawnflags & MONSTERFLAG_INVINCIBLE))
		{
			WaypointSprite_UpdateMaxHealth(this.sprite, this.max_health);
			WaypointSprite_UpdateHealth(this.sprite, this.health);
		}
	}

	this.think = Monster_Think;
	this.nextthink = time + this.ticrate;

	if(MUTATOR_CALLHOOK(MonsterSpawn, this))
		return false;

	return true;
}

bool Monster_Spawn(entity this, int mon_id)
{
	// setup the basic required properties for a monster
	entity mon = Monsters_from(mon_id);
	if(!mon.monsterid) { return false; } // invalid monster

	if(!autocvar_g_monsters) { Monster_Remove(this); return false; }

	if(Monster_Appear_Check(this, mon_id)) { return true; } // return true so the monster isn't removed

	if(!this.monster_skill)
		this.monster_skill = cvar("g_monsters_skill");

	// support for quake style removing monsters based on skill
	if(this.monster_skill == MONSTER_SKILL_EASY) if(this.spawnflags & MONSTERSKILL_NOTEASY) { Monster_Remove(this); return false; }
	if(this.monster_skill == MONSTER_SKILL_MEDIUM) if(this.spawnflags & MONSTERSKILL_NOTMEDIUM) { Monster_Remove(this); return false; }
	if(this.monster_skill == MONSTER_SKILL_HARD) if(this.spawnflags & MONSTERSKILL_NOTHARD) { Monster_Remove(this); return false; }

	if(this.team && !teamplay)
		this.team = 0;

	if(!(this.spawnflags & MONSTERFLAG_SPAWNED)) // naturally spawned monster
	if(!(this.spawnflags & MONSTERFLAG_RESPAWNED)) // don't count re-spawning monsters either
		monsters_total += 1;

	setmodel(this, mon.m_model);
	this.flags				= FL_MONSTER;
	this.classname			= "monster";
	this.takedamage			= DAMAGE_AIM;
	this.bot_attack			= true;
	this.iscreature			= true;
	this.teleportable		= true;
	this.damagedbycontents	= true;
	this.monsterid			= mon_id;
	this.event_damage		= Monster_Damage;
	this.touch				= Monster_Touch;
	this.use				= Monster_Use;
	this.solid				= SOLID_BBOX;
	this.movetype			= MOVETYPE_WALK;
	this.spawnshieldtime	= time + autocvar_g_monsters_spawnshieldtime;
	this.enemy				= world;
	this.velocity			= '0 0 0';
	this.moveto				= this.origin;
	this.pos1				= this.origin;
	this.pos2				= this.angles;
	this.reset				= Monster_Reset;
	this.netname			= mon.netname;
	this.monster_attackfunc	= mon.monster_attackfunc;
	this.monster_name		= mon.monster_name;
	this.candrop			= true;
	this.view_ofs			= '0 0 0.7' * (this.maxs_z * 0.5);
	this.oldtarget2			= this.target2;
	this.pass_distance		= 0;
	this.deadflag			= DEAD_NO;
	this.noalign			= ((mon.spawnflags & MONSTER_TYPE_FLY) || (mon.spawnflags & MONSTER_TYPE_SWIM));
	this.spawn_time			= time;
	this.gravity			= 1;
	this.monster_moveto		= '0 0 0';
	this.monster_face 		= '0 0 0';
	this.dphitcontentsmask	= DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_BOTCLIP | DPCONTENTS_MONSTERCLIP;

	if(!this.scale) { this.scale = 1; }
	if(autocvar_g_monsters_edit) { this.grab = 1; }
	if(autocvar_g_fullbrightplayers) { this.effects |= EF_FULLBRIGHT; }
	if(autocvar_g_nodepthtestplayers) { this.effects |= EF_NODEPTHTEST; }
	if(mon.spawnflags & MONSTER_TYPE_SWIM) { this.flags |= FL_SWIM; }

	if(mon.spawnflags & MONSTER_TYPE_FLY)
	{
		this.flags |= FL_FLY;
		this.movetype = MOVETYPE_FLY;
	}

	if(!(this.spawnflags & MONSTERFLAG_RESPAWNED))
	{
		if(mon.spawnflags & MONSTER_SIZE_BROKEN)
			this.scale *= 1.3;

		if(mon.spawnflags & MONSTER_SIZE_QUAKE)
		if(autocvar_g_monsters_quake_resize)
			this.scale *= 1.3;
	}

	setsize(this, mon.mins * this.scale, mon.maxs * this.scale);

	this.ticrate = bound(sys_frametime, ((!this.ticrate) ? autocvar_g_monsters_think_delay : this.ticrate), 60);

	Monster_UpdateModel(this);

	if(!Monster_Spawn_Setup(this))
	{
		Monster_Remove(this);
		return false;
	}

	if(!this.noalign)
	{
		setorigin(this, this.origin + '0 0 20');
		tracebox(this.origin + '0 0 64', this.mins, this.maxs, this.origin - '0 0 10000', MOVE_WORLDONLY, this);
		setorigin(this, trace_endpos);
	}

	if(!(this.spawnflags & MONSTERFLAG_RESPAWNED))
		monster_setupcolors(this);

	CSQCMODEL_AUTOINIT(this);

	return true;
}
