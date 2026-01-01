#include "sv_monsters.qh"

#include <common/checkextension.qh>
#include <common/constants.qh>
#include <common/deathtypes/all.qh>
#include <common/items/_mod.qh>
#include <common/mapobjects/teleporters.qh>
#include <common/mapobjects/triggers.qh>
#include <common/monsters/all.qh>
#include <common/mutators/mutator/nades/_mod.qh>
#include <common/mutators/mutator/status_effects/_mod.qh>
#include <common/physics/movelib.qh>
#include <common/stats.qh>
#include <common/teams.qh>
#include <common/turrets/sv_turrets.qh>
#include <common/turrets/util.qh>
#include <common/util.qh>
#include <common/vehicles/all.qh>
#include <common/weapons/_all.qh>
#include <common/weapons/_mod.qh>
#include <lib/csqcmodel/sv_model.qh>
#include <lib/warpzone/common.qh>
#include <server/campaign.qh>
#include <server/cheats.qh>
#include <server/client.qh>
#include <server/command/_mod.qh>
#include <server/damage.qh>
#include <server/items/items.qh>
#include <server/mutators/_mod.qh>
#include <server/round_handler.qh>
#include <server/steerlib.qh>
#include <server/weapons/_mod.qh>

void monsters_setstatus(entity this)
{
	STAT(MONSTERS_TOTAL, this) = monsters_total;
	STAT(MONSTERS_KILLED, this) = monsters_killed;
}

void monster_dropitem(entity this, entity attacker)
{
	if(!this.candrop || autocvar_g_monsters_drop_time <= 0)
		return;

	// TODO: mapper customization (different field?)
	string itemlist = this.monster_loot;

	if(this.spawnflags & MONSTERFLAG_MINIBOSS)
		itemlist = autocvar_g_monsters_miniboss_loot;

	MUTATOR_CALLHOOK(MonsterDropItem, this, itemlist, attacker);
	itemlist = M_ARGV(1, string);

	entity loot_itemdef = Item_RandomFromList(itemlist);
	if (!loot_itemdef)
		return;

	entity e = spawn();
	e.monster_item = true;
	ITEM_SET_LOOT(e, true);
	e.colormap = this.colormap;
	e.itemdef = loot_itemdef;
	setorigin(e, CENTER_OR_VIEWOFS(this));
	e.velocity = randomvec() * 175 + '0 0 325';
	e.lifetime = autocvar_g_monsters_drop_time;

	Item_Initialise(e);
}

bool monster_facing(entity this, entity targ)
{
	// relies on target having an origin
	makevectors(this.angles);
	vector targ_org = targ.origin, my_org = this.origin;
	if(autocvar_g_monsters_target_infront_2d)
	{
		targ_org = vec2(targ_org);
		my_org = vec2(my_org);
	}
	float dot = normalize(targ_org - my_org) * v_forward;

	return !(dot <= autocvar_g_monsters_target_infront_range);
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

bool Monster_ValidTarget(entity this, entity targ, bool skipfacing)
{
	// ensure we're not checking nonexistent monster/target
	if(!this || !targ) { return false; }

	if((targ == this)
	|| (IS_VEHICLE(targ) && !(this.monsterdef.spawnflags & MON_FLAG_RANGED)) // melee vs vehicle is useless
	|| (time < game_starttime) // monsters do nothing before match has started
	|| (targ.takedamage == DAMAGE_NO)
	|| (game_stopped)
	|| (IS_SPEC(targ) || IS_OBSERVER(targ)) // don't attack spectators
	|| (!IS_VEHICLE(targ) && (IS_DEAD(targ) || IS_DEAD(this) || GetResource(targ, RES_HEALTH) <= 0 || GetResource(this, RES_HEALTH) <= 0))
	|| (this.monster_follow == targ || targ.monster_follow == this)
	|| (!IS_VEHICLE(targ) && (targ.flags & FL_NOTARGET))
	|| (!autocvar_g_monsters_typefrag && PHYS_INPUT_BUTTON_CHAT(targ))
	|| (SAME_TEAM(targ, this))
	|| (targ.alpha != 0 && targ.alpha < 0.5)
	|| (autocvar_g_monsters_lineofsight && !checkpvs(this.origin + this.view_ofs, targ)) // enemy cannot be seen
	|| (MUTATOR_CALLHOOK(MonsterValidTarget, this, targ))
	)
	{
		// if any of the above checks fail, target is not valid
		return false;
	}

	vector targ_origin = ((targ.absmin + targ.absmax) * 0.5);
	traceline(this.origin + this.view_ofs, targ_origin, MOVE_NOMONSTERS, this); // TODO: maybe we can rely a bit on PVS data instead?

	if(trace_fraction < 1 && trace_ent != targ)
		return false; // solid

	if(!skipfacing && (autocvar_g_monsters_target_infront || (this.spawnflags & MONSTERFLAG_INFRONT)))
	if(this.enemy != targ)
	{
		if(!monster_facing(this, targ))
			return false;
	}

	return true; // this target is valid!
}

entity Monster_FindTarget(entity this)
{
	if(MUTATOR_CALLHOOK(MonsterFindTarget)) { return this.enemy; } // Handled by a mutator

	entity closest_target = NULL;
	vector my_center = CENTER_OR_VIEWOFS(this);

	// find the closest acceptable target to pass to
	IL_EACH(g_monster_targets, it.monster_attack,
	{
		float trange = this.target_range;
		if(PHYS_INPUT_BUTTON_CROUCH(it))
			trange *= 0.75; // TODO cvar this
		vector theirmid = (it.absmin + it.absmax) * 0.5;
		if(vdist(theirmid - this.origin, >, trange))
			continue;
		if(!Monster_ValidTarget(this, it, false))
			continue;

		// if it's a player, use the view origin as reference (stolen from RadiusDamage functions in g_damage.qc)
		vector targ_center = CENTER_OR_VIEWOFS(it);

		if(closest_target)
		{
			vector closest_target_center = CENTER_OR_VIEWOFS(closest_target);
			if(vlen2(my_center - targ_center) < vlen2(my_center - closest_target_center))
				{ closest_target = it; }
		}
		else { closest_target = it; }
	});

	return closest_target;
}

void monster_setupcolors(entity this)
{
	if(teamplay && this.team)
		this.colormap = 1024 + (this.team - 1) * 17;
	else if(IS_PLAYER(this.realowner))
		this.colormap = this.realowner.colormap;
	else
	{
		if(this.monster_skill <= MONSTER_SKILL_EASY)
			this.colormap = 1126;
		else if(this.monster_skill <= MONSTER_SKILL_MEDIUM)
			this.colormap = 1075;
		else if(this.monster_skill <= MONSTER_SKILL_HARD)
			this.colormap = 1228;
		else if(this.monster_skill <= MONSTER_SKILL_INSANE)
			this.colormap = 1092;
		else if(this.monster_skill <= MONSTER_SKILL_NIGHTMARE)
			this.colormap = 1160;
		else
			this.colormap = 1024;
	}

	if(this.colormap > 0)
		this.glowmod = colormapPaletteColor(this.colormap & 0x0F, false);
	else
		this.glowmod = '1 1 1';
}

void monster_changeteam(entity this, int newteam)
{
	if(!teamplay) { return; }

	this.team = newteam;
	if(!this.monster_attack)
		IL_PUSH(g_monster_targets, this);
	this.monster_attack = true; // new team, activate attacking
	monster_setupcolors(this);

	if(this.sprite)
	{
		WaypointSprite_UpdateTeamRadar(this.sprite, RADARICON_DANGER, ((newteam) ? Team_ColorRGB(newteam) : '1 0 0'));

		this.sprite.team = newteam;
		this.sprite.SendFlags |= 1;
	}
}

.void(entity) monster_delayedfunc;
void Monster_Delay_Action(entity this)
{
	// TODO: maybe do check for facing here
	if(Monster_ValidTarget(this.owner, this.owner.enemy, false))
	{
		monster_makevectors(this.owner, this.owner.enemy);
		this.monster_delayedfunc(this.owner);
	}

	if(this.cnt > 1)
	{
		this.cnt -= 1;
		setthink(this, Monster_Delay_Action);
		this.nextthink = time + this.count;
	}
	else
	{
		setthink(this, SUB_Remove);
		this.nextthink = time;
	}
}

void Monster_Delay(entity this, int repeat_count, float defer_amnt, void(entity) func)
{
	// deferred attacking, checks if monster is still alive and target is still valid before attacking
	entity e = new_pure(Monster_Delay);

	setthink(e, Monster_Delay_Action);
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
			//LOG_DEBUG("Invalid sound info line: ", s); // probably a comment, no need to spam warnings
			continue;
		}
		PrecacheGlobalSound(strcat(argv(1), " ", argv(2)));
	}
	fclose(fh);
}

void Monster_Sounds_Precache(entity this)
{
	string m = this.monsterdef.m_model.model_str();
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
#define _MSOUND(m) strfree(this.monstersound_##m);
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
	string s;
	var .string field;
	float fh = fopen(f, FILE_READ);
	if(fh < 0)
	{
		//LOG_DEBUG("Monster sound file not found: ", f); // no biggie, monster has no sounds, let's not spam it
		return false;
	}
	while((s = fgets(fh)))
	{
		if(tokenize_console(s) != 3)
			continue;
		field = Monster_Sound_SampleField(argv(0));
		if(GetMonsterSoundSampleField_notFound)
			continue;
		strcpy(this.(field), strcat(argv(1), " ", argv(2)));
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

void Monster_Sound(entity this, .string samplefield, float sound_delay, bool delaytoo, float chan)
{
	if(!autocvar_g_monsters_sounds) { return; }

	if(delaytoo)
	if(time < this.msound_delay)
		return; // too early
	string sample = this.(samplefield);
	if (sample != "") sample = GlobalSound_sample(sample, random());
	float myscale = ((this.scale) ? this.scale : 1); // safety net
	sound7(this, chan, sample, VOL_BASE, ATTEN_NORM, 100 / myscale, 0);

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

	traceline(this.origin + this.view_ofs, this.origin + v_forward * er, 0, this);

	if(trace_ent.takedamage)
		Damage(trace_ent, this, this, damg * MONSTER_SKILLMOD(this), deathtype, DMG_NOWEP, trace_ent.origin, normalize(trace_ent.origin - this.origin));

	return true;
}

bool Monster_Attack_Leap_Check(entity this, vector vel)
{
	if(this.state && IS_MONSTER(this))
		return false; // already attacking
	if(!IS_ONGROUND(this))
		return false; // not on the ground
	if(GetResource(this, RES_HEALTH) <= 0 || IS_DEAD(this))
		return false; // called when dead?
	if(time < this.attack_finished_single[0])
		return false; // still attacking

	vector old = this.velocity;

	this.velocity = vel;
	tracetoss(this, this);
	this.velocity = old;
	if(trace_ent != this.enemy)
		return false;

	return true;
}

bool Monster_Attack_Leap(entity this, vector anm, void(entity this, entity toucher) touchfunc, vector vel, float animtime)
{
	if(!Monster_Attack_Leap_Check(this, vel))
		return false;

	setanim(this, anm, false, true, false);

	if(this.animstate_endtime > time && IS_MONSTER(this))
		this.attack_finished_single[0] = this.anim_finished = this.animstate_endtime;
	else
		this.attack_finished_single[0] = this.anim_finished = time + animtime;

	if(IS_MONSTER(this))
		this.state = MONSTER_ATTACK_RANGED;
	settouch(this, touchfunc);
	this.origin_z += 1;
	this.velocity = vel;
	UNSET_ONGROUND(this);

	return true;
}

void Monster_Attack_Check(entity this, entity targ, .entity weaponentity)
{
	int slot = weaponslot(weaponentity);

	if((!this || !targ)
	|| (!this.monster_attackfunc)
	|| (game_stopped)
	|| (time < this.attack_finished_single[slot])
	|| ((autocvar_g_monsters_target_infront || (this.spawnflags & MONSTERFLAG_INFRONT)) && !monster_facing(this, targ))
	) { return; }

	if(vdist(targ.origin - this.origin, <=, this.attack_range))
	{
		monster_makevectors(this, targ);
		int attack_success = this.monster_attackfunc(MONSTER_ATTACK_MELEE, this, targ, weaponentity);
		if(attack_success == 1)
			Monster_Sound(this, monstersound_melee, 0, false, CH_VOICE);
		else if(attack_success > 0)
			return;
	}

	if(vdist(targ.origin - this.origin, >, this.attack_range))
	{
		monster_makevectors(this, targ);
		int attack_success = this.monster_attackfunc(MONSTER_ATTACK_RANGED, this, targ, weaponentity);
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
	Monster mon = this.monsterdef;
	mon.mr_anim(mon, this);
}

void Monster_Touch(entity this, entity toucher)
{
	if(!toucher) { return; }

	if(toucher.monster_attack && this.enemy != toucher && !IS_MONSTER(toucher) && time >= this.spawn_time)
	if(Monster_ValidTarget(this, toucher, true))
		this.enemy = toucher;
}

void Monster_Miniboss_Setup(entity this)
{
	if(this.spawnflags & MONSTERFLAG_RESPAWNED)
	{
		// already performed initial setup, just reapply statuses as needed
		if(this.spawnflags & MONSTERFLAG_MINIBOSS)
			this.effects |= EF_RED;
		return;
	}

	if(MUTATOR_CALLHOOK(MonsterCheckBossFlag, this))
	{
		// prevent other code from identifying the monster as a miniboss
		this.spawnflags &= ~MONSTERFLAG_MINIBOSS;
		return;
	}

	// g_monsters_miniboss_chance cvar or spawnflags 64 causes a monster to be a miniboss
	if ((this.spawnflags & MONSTERFLAG_MINIBOSS) || ((random() * 100) < autocvar_g_monsters_miniboss_chance))
	{
		GiveResource(this, RES_HEALTH, autocvar_g_monsters_miniboss_healthboost);
		this.effects |= EF_RED;
		this.spawnflags |= MONSTERFLAG_MINIBOSS; // identifier for other code
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

void Monster_Respawn(entity this) { Monster_Spawn(this, true, this.monsterdef); }

.vector	pos1, pos2;

void Monster_Dead_Fade(entity this)
{
	if(Monster_Respawn_Check(this))
	{
		this.spawnflags |= MONSTERFLAG_RESPAWNED;
		setthink(this, Monster_Respawn);
		this.nextthink = time + this.respawntime;
		this.monster_lifetime = 0;
		this.deadflag = DEAD_RESPAWNING;
		if(this.spawnflags & MONSTER_RESPAWN_DEATHPOINT)
		{
			this.pos1 = this.origin;
			this.pos2 = this.angles;
		}
		this.event_damage = func_null;
		this.event_heal = func_null;
		this.takedamage = DAMAGE_NO;
		setorigin(this, this.pos1);
		this.angles = this.pos2;
		SetResourceExplicit(this, RES_HEALTH, this.max_health);
		setmodel(this, MDL_Null);
	}
	else
	{
		// number of monsters spawned with mobspawn command
		totalspawned -= 1;

		SUB_SetFade(this, time + 3, 1);
	}
}

void Monster_Use(entity this, entity actor, entity trigger)
{
	if(Monster_ValidTarget(this, actor, true)) { this.enemy = actor; }
}

/// Returns an origin that's near targetorigin and visible to this monster.
vector Monster_WanderTarget(entity this, vector targetorigin)
{
	vector pos, ang;

	ang_y = rint(random() * 500);
	ang_x = this.angles_x;
	ang_z = this.angles_z;
	makevectors(ang);
	pos = targetorigin + v_forward * this.wander_distance;
	if(((this.flags & FL_FLY) && (this.spawnflags & MONSTERFLAG_FLY_VERTICAL)) || (this.flags & FL_SWIM))
	{
		pos.z = random() * 200;
		if(random() >= 0.5)
			pos.z *= -1;
	}
	// truncate movement so we don't do walking into walls animations
	traceline(this.origin + this.view_ofs, pos, MOVE_NORMAL, this);
	return trace_endpos;
}

vector Monster_Move_Target(entity this, entity targ)
{
	// enemy is always preferred target
	if(this.enemy)
	{
		vector targ_origin = ((this.enemy.absmin + this.enemy.absmax) * 0.5);
		targ_origin = WarpZone_RefSys_TransformOrigin(this.enemy, this, targ_origin); // origin of target as seen by the monster (us)

		if(this.enemy)
		{
			/*WarpZone_TrailParticles(NULL, particleeffectnum(EFFECT_RED_PASS), this.origin, targ_origin);
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
			if (this.monster_follow)
			{
				if (vdist(this.origin - this.monster_follow.origin, <, this.wander_distance))
					this.last_trace = time + this.wander_delay;
				return Monster_WanderTarget(this, this.monster_follow.origin);
			}
			else
				return this.origin;
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
			this.monster_movestate = MONSTER_MOVE_WANDER;
			if(this.monster_moveto)
			{
				this.last_trace = time + 0.5;
				return this.monster_moveto;
			}
			else if(targ)
			{
				this.last_trace = time + 0.5;
				return targ.origin;
			}
			else
			{
				this.last_trace = time + this.wander_delay;
				return Monster_WanderTarget(this, this.origin);
			}
		}
	}
}

// Check for water/slime/lava and dangerous edges
// (only when the bot is on the ground or jumping intentionally)
// returns a number > 0 for danger
// based on havocbot_checkdanger()
int Monster_CheckDanger(entity this, vector dst_ahead)
{
	float s;

	if(this.flags & (FL_FLY | FL_SWIM))
	{
		// Look ahead
		traceline(this.origin + this.view_ofs, dst_ahead, true, NULL);

		// Only care about the skybox if it's below
		// bones_was_here: does this even matter when flying/swimming?
		if (trace_endpos.z < this.origin.z + this.mins.z
		&& trace_dphitq3surfaceflags & Q3SURFACEFLAG_SKY)
			return 1;

		s = pointcontents(trace_endpos + '0 0 1');
		if (s != CONTENT_SOLID)
		{
			if (s == CONTENT_LAVA || s == CONTENT_SLIME)
				return 3;

			if (tracebox_hits_trigger_hurt(dst_ahead, this.mins, this.maxs, trace_endpos))
			{
				// the traceline check isn't enough but is good as optimization,
				// when not true (most of the time) this tracebox call is avoided
				tracebox(this.origin + this.view_ofs, this.mins, this.maxs, dst_ahead, true, this);
				if (tracebox_hits_trigger_hurt(dst_ahead, this.mins, this.maxs, trace_endpos))
					return 4;
			}
		}
	}
	else
	{
		vector dst_down = dst_ahead - '0 0 3000';

		// Look downwards
		traceline(dst_ahead, dst_down, true, NULL);
		//te_lightning2(NULL, this.origin + this.view_ofs, dst_ahead); // Draw "ahead" look
		//te_lightning2(NULL, dst_ahead, trace_endpos); // Draw "downwards" look
		if (trace_endpos.z < this.origin.z + this.mins.z)
		{
			if (trace_dphitq3surfaceflags & Q3SURFACEFLAG_SKY)
				return 1;

			// If following an enemy ignore probably-non-fatal falls,
			// if wandering only ignore small falls.
			if (trace_endpos.z < (this.origin.z + this.mins.z) - (this.enemy ? 1024 : 100))
				return 2;

			s = pointcontents(trace_endpos + '0 0 1');
			if (s != CONTENT_SOLID)
			{
				if (s == CONTENT_LAVA || s == CONTENT_SLIME)
					return 3;

				if (tracebox_hits_trigger_hurt(dst_ahead, this.mins, this.maxs, trace_endpos))
				{
					// the traceline check isn't enough but is good as optimization,
					// when not true (most of the time) this tracebox call is avoided
					tracebox(dst_ahead, this.mins, this.maxs, dst_down, true, this);
					if (tracebox_hits_trigger_hurt(dst_ahead, this.mins, this.maxs, trace_endpos))
						return 4;
				}
			}
		}
	}

	return 0;
}

.entity draggedby;
void Monster_Move(entity this, float runspeed, float walkspeed, float stpspeed)
{
	// update goal entity if lost
	if(this.target2 && this.target2 != "" && this.goalentity.targetname != this.target2)
		this.goalentity = find(NULL, targetname, this.target2);

	if(StatusEffects_active(STATUSEFFECT_Frozen, this))
	{
		movelib_brake_simple(this, stpspeed);
		setanim(this, this.anim_idle, true, false, false);
		return; // no physics while frozen!
	}

	if(this.flags & FL_SWIM)
	{
		if(this.waterlevel < WATERLEVEL_WETFEET)
		{
			if(time >= this.last_trace)
			{
				this.last_trace = time + 0.4;

				Damage (this, NULL, NULL, 2, DEATH_DROWN.m_id, DMG_NOWEP, this.origin, '0 0 0');
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


			set_movetype(this, MOVETYPE_BOUNCE);
			//this.velocity_z = -200;

			return;
		}
		else if(this.move_movetype == MOVETYPE_BOUNCE)
		{
			this.angles_x = 0;
			set_movetype(this, MOVETYPE_WALK);
		}
	}

	entity targ = this.goalentity;

	if (MUTATOR_CALLHOOK(MonsterMove, this, runspeed, walkspeed, targ)
		|| game_stopped
		|| this.draggedby != NULL
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

	targ = M_ARGV(3, entity);
	runspeed = bound(0, M_ARGV(1, float) * MONSTER_SKILLMOD(this), runspeed * 2.5); // limit maxspeed to prevent craziness
	walkspeed = bound(0, M_ARGV(2, float) * MONSTER_SKILLMOD(this), walkspeed * 2.5); // limit maxspeed to prevent craziness

	if(this.monster_follow)
	if((teamplay && autocvar_g_monsters_teams && DIFF_TEAM(this.monster_follow, this))
	|| IS_SPEC(this.monster_follow) || IS_OBSERVER(this.monster_follow))
		this.monster_follow = NULL;

	if(this.state == MONSTER_ATTACK_RANGED && IS_ONGROUND(this))
	{
		this.state = 0;
		settouch(this, Monster_Touch);
	}

	if(this.state && time >= this.attack_finished_single[0])
		this.state = 0; // attack is over

// Select destination
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

// Steer towards destination
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

// Update velocity
	fixedmakevectors(this.angles);
	float vz = this.velocity_z;

	// Check for danger ahead
	float bboxwidth = min(this.maxs_x - this.mins_x, this.maxs_y - this.mins_y);
	int danger = Monster_CheckDanger(this, this.origin + this.view_ofs
		+ (vdist(this.velocity, >, bboxwidth * 5) ? this.velocity * 0.2 : v_forward * bboxwidth));

	if(!danger && !turret_closetotarget(this, this.moveto, 16))
	{
		bool do_run = (this.enemy || this.monster_moveto);
		movelib_move_simple(this, v_forward, ((do_run) ? runspeed : walkspeed), 0.4);

		if(time > this.pain_finished && time > this.anim_finished)
		if(!this.state)
		{
			if(vdist(this.velocity, >, 10))
				setanim(this, ((do_run) ? this.anim_run : this.anim_walk), true, false, false);
			else
				setanim(this, this.anim_idle, true, false, false);
		}
	}
	else
	{
		entity e = this.goalentity; //find(NULL, targetname, this.target2);
		if(e.target2 && e.target2 != "")
			this.target2 = e.target2;
		else if(e.target && e.target != "") // compatibility
			this.target2 = e.target;

		movelib_brake_simple(this, stpspeed);
		if(time > this.anim_finished && time > this.pain_finished)
		if(!this.state)
		if(vdist(this.velocity, <=, 30))
			setanim(this, this.anim_idle, true, false, false);
	}

	if(!((this.flags & FL_FLY) || (this.flags & FL_SWIM)))
		this.velocity_z = vz;

// If this path is dangerous try to find a different one next frame
	if (danger)
	{
		this.last_trace = time + 0.3;
		this.moveto = Monster_WanderTarget(this, this.origin);
	}
}

void Monster_Remove(entity this)
{
	if(IS_CLIENT(this))
		return; // don't remove it?

	if(!this) { return; }

	if(!MUTATOR_CALLHOOK(MonsterRemove, this))
		Send_Effect(EFFECT_ITEM_PICKUP, this.origin, '0 0 0', 1);

	for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	{
		.entity weaponentity = weaponentities[slot];
		if(this.(weaponentity))
			delete(this.(weaponentity));
	}
	WaypointSprite_Kill(this.sprite);
	delete(this);
}

void Monster_Dead_Think(entity this)
{
	this.nextthink = time;

	Monster mon = REGISTRY_GET(Monsters, this.monsterid);
	mon.mr_deadthink(mon, this);

	if(this.monster_lifetime != 0)
	if(time >= this.monster_lifetime)
	{
		Monster_Dead_Fade(this);
		return;
	}
}

void Monster_Appear(entity this, entity actor, entity trigger)
{
	this.enemy = actor;
	Monster_Spawn(this, false, this.monsterdef);
}

bool Monster_Appear_Check(entity this, Monster monster_id)
{
	if(!(this.spawnflags & MONSTERFLAG_APPEAR))
		return false;

	setthink(this, func_null);
	this.monsterdef = monster_id; // set so this monster is properly registered (otherwise, normal initialization is used)
	this.nextthink = 0;
	this.use = Monster_Appear;
	this.flags = FL_MONSTER; // set so this monster can get butchered

	return true;
}

void Monster_Reset(entity this)
{
	if(this.spawnflags & MONSTERFLAG_SPAWNED)
	{
		Monster_Remove(this);
		return;
	}

	setorigin(this, this.pos1);
	this.angles = this.pos2;

	SetResourceExplicit(this, RES_HEALTH, this.max_health);
	this.velocity = '0 0 0';
	this.enemy = NULL;
	this.goalentity = NULL;
	this.attack_finished_single[0] = 0;
	this.moveto = this.origin;
}

void Monster_Dead_Damage(entity this, entity inflictor, entity attacker, float damage, int deathtype, .entity weaponentity, vector hitloc, vector force)
{
	TakeResource(this, RES_HEALTH, damage);

	Violence_GibSplash_At(hitloc, force, 2, bound(0, damage, 200) / 16, this, attacker);

	if(GetResource(this, RES_HEALTH) <= -50) // 100 health until gone?
	{
		Violence_GibSplash_At(hitloc, force, 2, bound(0, damage, 200) / 16, this, attacker);

		// number of monsters spawned with mobspawn command
		totalspawned -= 1;

		setthink(this, SUB_Remove);
		this.nextthink = time + 0.1;
		this.event_damage = func_null;
	}
}

void Monster_Dead(entity this, entity attacker, float gibbed)
{
	setthink(this, Monster_Dead_Think);
	this.nextthink = time;
	this.monster_lifetime = time + 5;

	monster_dropitem(this, attacker);

	Monster_Sound(this, monstersound_death, 0, false, CH_VOICE);

	if(!(this.spawnflags & (MONSTERFLAG_SPAWNED | MONSTERFLAG_RESPAWNED)))
		monsters_killed += 1;

	if(IS_PLAYER(attacker))
	if(autocvar_g_monsters_score_spawned || !(this.spawnflags & (MONSTERFLAG_SPAWNED | MONSTERFLAG_RESPAWNED)))
		GameRules_scoring_add(attacker, SCORE, +autocvar_g_monsters_score_kill);

	if(gibbed)
	{
		// number of monsters spawned with mobspawn command
		totalspawned -= 1;
	}

	if(!gibbed && this.mdl_dead && this.mdl_dead != "")
		_setmodel(this, this.mdl_dead);

	this.event_damage	= ((gibbed) ? func_null : Monster_Dead_Damage);
	this.event_heal 	= func_null;
	this.solid			= SOLID_CORPSE;
	this.takedamage		= DAMAGE_AIM;
	this.deadflag		= DEAD_DEAD;
	this.enemy			= NULL;
	set_movetype(this, MOVETYPE_TOSS);
	this.moveto			= this.origin;
	settouch(this, Monster_Touch); // reset incase monster was pouncing
	this.reset			= func_null;
	this.state			= 0;
	this.attack_finished_single[0] = 0;
	this.effects = 0;
	this.dphitcontentsmask &= ~DPCONTENTS_BODY;

	if(!((this.flags & FL_FLY) || (this.flags & FL_SWIM)))
		this.velocity = '0 0 0';

	CSQCModel_UnlinkEntity(this);

	Monster mon = this.monsterdef;
	mon.mr_death(mon, this);
}

void Monster_Damage(entity this, entity inflictor, entity attacker, float damage, int deathtype, .entity weaponentity, vector hitloc, vector force)
{
	if((this.spawnflags & MONSTERFLAG_INVINCIBLE) && deathtype != DEATH_KILL.m_id && !ITEM_DAMAGE_NEEDKILL(deathtype))
		return;

	//if(time < this.pain_finished && deathtype != DEATH_KILL.m_id)
		//return;

	if(StatusEffects_active(STATUSEFFECT_SpawnShield, this) && deathtype != DEATH_KILL.m_id)
		return;

	if(deathtype == DEATH_FALL.m_id && this.draggedby != NULL)
		return;

	vector v = healtharmor_applydamage(100, GetResource(this, RES_ARMOR) / 100, deathtype, damage);
	float take = v.x;
	//float save = v.y;

	Monster mon = this.monsterdef;
	take = mon.mr_pain(mon, this, take, attacker, deathtype);

	if(take)
	{
		TakeResource(this, RES_HEALTH, take);
		Monster_Sound(this, monstersound_pain, 1.2, true, CH_PAIN);
	}

	if(this.sprite)
		WaypointSprite_UpdateHealth(this.sprite, GetResource(this, RES_HEALTH));

	this.dmg_time = time;

	if(deathtype != DEATH_DROWN.m_id && deathtype != DEATH_FIRE.m_id && sound_allowed(MSG_BROADCAST, attacker))
		spamsound (this, CH_PAIN, SND_BODYIMPACT1, VOL_BASE, ATTEN_NORM);  // FIXME: PLACEHOLDER

	this.velocity += force * this.damageforcescale;

	if(deathtype != DEATH_DROWN.m_id && take)
	{
		Violence_GibSplash_At(hitloc, force, 2, bound(0, take, 200) / 16, this, attacker);
		if (take > 50)
			Violence_GibSplash_At(hitloc, force * -0.1, 3, 1, this, attacker);
		if (take > 100)
			Violence_GibSplash_At(hitloc, force * -0.2, 3, 1, this, attacker);
	}

	if(GetResource(this, RES_HEALTH) <= 0)
	{
		if(deathtype == DEATH_KILL.m_id)
			this.candrop = false; // killed by mobkill command

		// TODO: fix this?
		SUB_UseTargets(this, attacker, this.enemy);
		this.target2 = this.oldtarget2; // reset to original target on death, incase we respawn

		Monster_Dead(this, attacker, (GetResource(this, RES_HEALTH) <= -100 || deathtype == DEATH_KILL.m_id));

		WaypointSprite_Kill(this.sprite);

		MUTATOR_CALLHOOK(MonsterDies, this, attacker, deathtype);

		if(GetResource(this, RES_HEALTH) <= -100 || deathtype == DEATH_KILL.m_id) // check if we're already gibbed
		{
			Violence_GibSplash(this, 1, 0.5, attacker);

			setthink(this, SUB_Remove);
			this.nextthink = time + 0.1;
		}
	}
}

bool Monster_Heal(entity targ, entity inflictor, float amount, float limit)
{
	float true_limit = ((limit != RES_LIMIT_NONE) ? limit : targ.max_health);
	if(GetResource(targ, RES_HEALTH) <= 0 || GetResource(targ, RES_HEALTH) >= true_limit)
		return false;

	GiveResourceWithLimit(targ, RES_HEALTH, amount, true_limit);
	if(targ.sprite)
		WaypointSprite_UpdateHealth(targ.sprite, GetResource(targ, RES_HEALTH));
	return true;
}

// don't check for enemies, just keep walking in a straight line
void Monster_Move_2D(entity this, float mspeed, bool allow_jumpoff)
{
	if(game_stopped || (round_handler_IsActive() && !round_handler_IsRoundStarted()) || this.draggedby != NULL || time < game_starttime || (autocvar_g_campaign && !campaign_bots_may_start) || time < this.spawn_time)
	{
		mspeed = 0;
		if(time >= this.spawn_time)
			setanim(this, this.anim_idle, true, false, false);
		movelib_brake_simple(this, 0.6);
		return;
	}

	makevectors(this.angles);
	vector a = CENTER_OR_VIEWOFS(this);
	vector b = CENTER_OR_VIEWOFS(this) + v_forward * 32;

	traceline(a, b, MOVE_NORMAL, this);

	bool reverse = false;
	if(trace_fraction != 1.0)
		reverse = true;
	if(trace_ent && IS_PLAYER(trace_ent))
		reverse = false;
	if(trace_ent && IS_MONSTER(trace_ent))
		reverse = true;

	if(!allow_jumpoff && IS_ONGROUND(this))
	{
		traceline(b, b - '0 0 32', MOVE_NORMAL, this);
		if(trace_fraction == 1.0)
			reverse = true;
	}

	if(reverse)
	{
		this.angles_y = anglemods(this.angles_y - 180);
		makevectors(this.angles);
	}

	movelib_move_simple_gravity(this, v_forward, mspeed, 1);

	if(time > this.pain_finished && time > this.attack_finished_single[0])
	{
		if(vdist(this.velocity, >, 10))
			setanim(this, this.anim_walk, true, false, false);
		else
			setanim(this, this.anim_idle, true, false, false);
	}
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
	if(StatusEffects_active(STATUSEFFECT_Frozen, this))
		animbits |= ANIMSTATE_FROZEN;
	if(IS_DUCKED(this))
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

void Monster_Enemy_Check(entity this)
{
	if(this.enemy)
	{
		vector targ_origin = ((this.enemy.absmin + this.enemy.absmax) * 0.5);
		targ_origin = WarpZone_RefSys_TransformOrigin(this.enemy, this, targ_origin); // origin of target as seen by the monster (us)
		WarpZone_TraceLine(this.origin, targ_origin, MOVE_NOMONSTERS, this);

		// cases where the enemy may have changed their state (don't need to check everything here)
		// TODO: mutator hook
		if(    (IS_DEAD(this.enemy) || GetResource(this.enemy, RES_HEALTH) < 1)
			|| (STAT(FROZEN, this.enemy))
			|| (this.enemy.flags & FL_NOTARGET)
			|| (this.enemy.alpha < 0.5 && this.enemy.alpha != 0)
			|| (this.enemy.takedamage == DAMAGE_NO)
			|| (vdist(this.origin - targ_origin, >, this.target_range))
			|| ((trace_fraction < 1) && (trace_ent != this.enemy))
			)
		{
			this.enemy = NULL;
		}
		else
		{
			return;
		}
	}

	this.enemy = Monster_FindTarget(this);
	if(this.enemy)
	{
		WarpZone_RefSys_Copy(this.enemy, this);
		WarpZone_RefSys_AddInverse(this.enemy, this); // wz1^-1 ... wzn^-1 receiver
		// update move target immediately?
		this.moveto = WarpZone_RefSys_TransformOrigin(this.enemy, this, (0.5 * (this.enemy.absmin + this.enemy.absmax)));
		this.monster_moveto = '0 0 0';
		this.monster_face = '0 0 0';

		Monster_Sound(this, monstersound_sight, 0, false, CH_VOICE);
	}
}

void Monster_Think(entity this)
{
	setthink(this, Monster_Think);
	this.nextthink = time;

	if(this.monster_lifetime && time >= this.monster_lifetime)
	{
		Damage(this, this, this, GetResource(this, RES_HEALTH) + this.max_health, DEATH_KILL.m_id, DMG_NOWEP, this.origin, this.origin);
		return;
	}

	// TODO: mutator hook to control monster thinking
	if(StatusEffects_active(STATUSEFFECT_Frozen, this))
	{
		this.enemy = NULL; // TODO: save enemy, and attack when revived?
	}
	else if(time >= this.last_enemycheck)
	{
		Monster_Enemy_Check(this);
		this.last_enemycheck = time + 1; // check for enemies every second
	}

	Monster mon = this.monsterdef;
	if(mon.mr_think(mon, this))
	{
		Monster_Move(this, this.speed2, this.speed, this.stopspeed);

		.entity weaponentity = weaponentities[0]; // TODO?
		Monster_Attack_Check(this, this.enemy, weaponentity);
	}

	Monster_Anim(this);

	CSQCMODEL_AUTOUPDATE(this);
}

bool Monster_Spawn_Setup(entity this)
{
	Monster mon = this.monsterdef;
	mon.mr_setup(mon, this);

	// ensure some basic needs are met
	if(!GetResource(this, RES_HEALTH)) { SetResourceExplicit(this, RES_HEALTH, 100); }
	if(!GetResource(this, RES_ARMOR)) { SetResourceExplicit(this, RES_ARMOR, bound(0.2, 0.5 * MONSTER_SKILLMOD(this), 0.9)); }
	if(!this.target_range) { this.target_range = autocvar_g_monsters_target_range; }
	if(!this.respawntime) { this.respawntime = autocvar_g_monsters_respawn_delay; }
	if(!this.monster_moveflags) { this.monster_moveflags = MONSTER_MOVE_WANDER; }
	if(!this.attack_range) { this.attack_range = autocvar_g_monsters_attack_range; }
	if(!this.damageforcescale) { this.damageforcescale = autocvar_g_monsters_damageforcescale; }

	Monster_Miniboss_Setup(this);

	if(!(this.spawnflags & MONSTERFLAG_RESPAWNED))
	{
		SetResourceExplicit(this, RES_HEALTH, GetResource(this, RES_HEALTH) * MONSTER_SKILLMOD(this));

		if(!this.skin)
			this.skin = rint(random() * 4);
	}

	this.max_health = GetResource(this, RES_HEALTH);
	this.pain_finished = this.nextthink;
	this.last_enemycheck = this.spawn_time + random(); // slight delay

	if(!this.wander_delay) { this.wander_delay = 2; }
	if(!this.wander_distance) { this.wander_distance = 600; }

	Monster_Sounds_Precache(this);
	Monster_Sounds_Update(this);

	if(teamplay)
	{
		if(!this.monster_attack)
			IL_PUSH(g_monster_targets, this);
		this.monster_attack = true; // we can have monster enemies in team games
	}

	Monster_Sound(this, monstersound_spawn, 0, false, CH_VOICE);

	if(autocvar_g_monsters_healthbars)
	{
		entity wp = WaypointSprite_Spawn(WP_Monster, 0, 1024, this, '0 0 1' * (this.maxs.z + 15), NULL, this.team, this, sprite, true, RADARICON_DANGER);
		wp.wp_extra = this.monsterdef.monsterid;
		wp.colormod = ((this.team) ? Team_ColorRGB(this.team) : '1 0 0');
		if(!(this.spawnflags & MONSTERFLAG_INVINCIBLE))
		{
			WaypointSprite_UpdateMaxHealth(this.sprite, this.max_health);
			WaypointSprite_UpdateHealth(this.sprite, GetResource(this, RES_HEALTH));
		}
	}

	setthink(this, Monster_Think);
	this.nextthink = time;

	if(MUTATOR_CALLHOOK(MonsterSpawn, this))
		return false;

	return true;
}

bool Monster_Spawn(entity this, bool check_appear, Monster mon)
{
	// setup the basic required properties for a monster

	if(!mon || mon == MON_Null) { return false; } // invalid monster
	if(!autocvar_g_monsters) { Monster_Remove(this); return false; }

	if(!(this.spawnflags & MONSTERFLAG_RESPAWNED) && !(this.flags & FL_MONSTER))
	{
		IL_PUSH(g_monsters, this);
		if(this.mdl && this.mdl != "")
			precache_model(this.mdl);
		if(this.mdl_dead && this.mdl_dead != "")
			precache_model(this.mdl_dead);
	}

	if(check_appear && Monster_Appear_Check(this, mon)) { return true; } // return true so the monster isn't removed

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

	if(this.mdl && this.mdl != "")
		_setmodel(this, this.mdl);
	else
		setmodel(this, mon.m_model);

	if(!this.m_name || this.m_name == "")
		this.m_name = mon.m_name;

	if(this.statuseffects && this.statuseffects.owner == this)
	{
		StatusEffects_clearall(this.statuseffects);
		StatusEffects_update(this);
	}
	else
		this.statuseffects = NULL;

	this.flags				= FL_MONSTER;
	this.classname			= "monster";
	this.takedamage			= DAMAGE_AIM;
	if(!this.bot_attack)
		IL_PUSH(g_bot_targets, this);
	this.bot_attack			= true;
	this.iscreature			= true;
	this.teleportable		= true;
	if(!this.damagedbycontents)
		IL_PUSH(g_damagedbycontents, this);
	this.damagedbycontents	= true;
	this.monsterdef			= mon;
	this.event_damage		= Monster_Damage;
	this.event_heal			= Monster_Heal;
	settouch(this, Monster_Touch);
	this.use				= Monster_Use;
	this.solid				= SOLID_BBOX;
	set_movetype(this, MOVETYPE_WALK);
	StatusEffects_apply(STATUSEFFECT_SpawnShield, this, time + autocvar_g_monsters_spawnshieldtime, 0);
	this.enemy				= NULL;
	this.velocity			= '0 0 0';
	this.moveto				= this.origin;
	this.pos1				= this.origin;
	this.pos2				= this.angles;
	this.reset				= Monster_Reset;
	this.netname			= mon.netname;
	this.monster_attackfunc	= mon.monster_attackfunc;
	this.candrop			= true;
	this.oldtarget2			= this.target2;
	this.deadflag			= DEAD_NO;
	this.spawn_time			= time;
	this.gravity			= 1;
	this.monster_moveto		= '0 0 0';
	this.monster_face 		= '0 0 0';
	this.dphitcontentsmask	= DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_BOTCLIP | DPCONTENTS_MONSTERCLIP;

	if(!this.noalign) { this.noalign = (mon.spawnflags & (MONSTER_TYPE_FLY | MONSTER_TYPE_SWIM)); }
	if(!this.scale) { this.scale = 1; }
	if(autocvar_g_monsters_edit) { this.grab = 1; }
	if(autocvar_g_fullbrightplayers) { this.effects |= EF_FULLBRIGHT; }
	if(autocvar_g_nodepthtestplayers) { this.effects |= EF_NODEPTHTEST; }
	if(mon.spawnflags & MONSTER_TYPE_SWIM) { this.flags |= FL_SWIM; }

	if(autocvar_g_monsters_playerclip_collisions)
		this.dphitcontentsmask |= DPCONTENTS_PLAYERCLIP;

	if(mon.spawnflags & MONSTER_TYPE_FLY)
	{
		this.flags |= FL_FLY;
		set_movetype(this, MOVETYPE_FLY);
	}

	if((mon.spawnflags & MONSTER_SIZE_QUAKE) && autocvar_g_monsters_quake_resize && !(this.spawnflags & MONSTERFLAG_RESPAWNED))
		this.scale *= 1.3;

	setsize(this, RoundPerfectVector(mon.m_mins * this.scale), RoundPerfectVector(mon.m_maxs * this.scale));
	this.view_ofs			= '0 0 0.7' * (this.maxs_z * 0.5);

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

	if (!nudgeoutofsolid_OrFallback(this))
	{
		// Stuck and not fixable
		Monster_Remove(this);
		return false;
	}

	if(!(this.spawnflags & MONSTERFLAG_RESPAWNED))
		monster_setupcolors(this);

	CSQCMODEL_AUTOINIT(this);

	return true;
}
