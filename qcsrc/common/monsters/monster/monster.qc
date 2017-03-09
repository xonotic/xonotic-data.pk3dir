#include "monster.qh"

#ifdef SVQC

const int MON_MOVE_NONE = BIT(0);
const int MON_MOVE_NORMAL = BIT(1);
const int MON_MOVE_2D = BIT(2);
const int MON_MOVE_BOUNCE = BIT(3);
const int MON_MOVE_TOUCH = BIT(4);
const int MON_MOVE_JUMP = BIT(5);

const int MON_ATTACK_MELEE = BIT(0);
const int MON_ATTACK_TOUCH = BIT(1);
const int MON_ATTACK_PROJECTILE = BIT(2);

const int MON_DAMAGE_NONE = BIT(0);
const int MON_DAMAGE_NOMONSTERS = BIT(1);

const int MON_ATTACKTYPE_GRENADE = 0;
const int MON_ATTACKTYPE_FIREBALL = 1;

.int frame_walk, frame_run, frame_idle, frame_melee, frame_shoot, frame_death, frame_pain;

// here come the fields
.bool mon_jumpoff;
.int mon_alwaysturn;
.float mon_touchdelay, mon_touchangle;
.float touch_timer; // reused field
.float mon_jumpdelay, mon_jumpheight;
.float jump_delay;
.float shot_dmg, shot_radius;
.float mon_proj_speed, mon_proj_speed_up;
.float mon_attack_delay;

.int mon_movetype, mon_attacks, mon_attacktype, mon_damageflags;

void M_CustomMonster_Touch(entity this, entity toucher)
{
	if((this.mon_movetype & MON_MOVE_TOUCH) && vdist(this.velocity, <, this.speed))
	{
		if(time < this.touch_timer)
			return; // just return
		if(IS_PLAYER(toucher))
		{
			fixedmakevectors(toucher.angles);
			this.angles = toucher.angles; // to make sidescrolling movement work
			this.velocity = v_forward * this.speed2;
			this.attack_finished_single[0] = time + this.mon_attack_delay; // don't immediately damage the player that pushed it
		}
		this.touch_timer = time + this.mon_touchdelay;
		return;
	}

	if(!(this.mon_attacks & MON_ATTACK_TOUCH))
		return;
	if(IS_DEAD(toucher))
		return;
	if(toucher.items & ITEM_Shield.m_itemid)
		return;
	if(toucher.takedamage == DAMAGE_NO)
		return;
	if(!toucher.iscreature)
		return;
	if(time < this.attack_finished_single[0])
		return;
	if(toucher.mdl == this.mdl || SAME_TEAM(this, toucher))
		return; // friendly
		
	vector vdir = normalize(toucher.origin - this.origin);
	if(vdir.z <= this.mon_touchangle)
	{
		Damage(toucher, this, this, this.dmg, DEATH_MONSTER_ZOMBIE_MELEE.m_id, toucher.origin, '0 0 0');
		this.attack_finished_single[0] = time + this.mon_attack_delay;
	}
}

void M_CustomMonster_Attack_Grenade_Touch(entity this, entity toucher)
{
	PROJECTILE_TOUCH(this, toucher);
	// only 'explode' if we touch a player (or equally humanoid creature)
	if((IS_PLAYER(toucher) || IS_MONSTER(toucher)) && this.velocity)
		turret_projectile_explode(this);
}

void M_CustomMonster_TargetEnemey(entity this)
{
	if(time >= this.last_enemycheck)
	{
		if(!this.enemy)
		{
			this.enemy = Monster_FindTarget(this);
			if(this.enemy)
				Monster_Sound(this, monstersound_sight, 0, false, CH_VOICE);
		}

		this.last_enemycheck = time + 1; // check for enemies every second
	}

	.entity weaponentity = weaponentities[0]; // TODO?
	Monster_Attack_Check(this, this.enemy, weaponentity);
}

bool M_CustomMonster_Attack(int attack_type, entity actor, entity targ, .entity weaponentity)
{
	switch(attack_type)
	{
		case MONSTER_ATTACK_MELEE:
		{
			if(actor.mon_attacks & MON_ATTACK_MELEE)
				return Monster_Attack_Melee(actor, actor.enemy, actor.dmg, actor.anim_melee, actor.attack_range, actor.mon_attack_delay, DEATH_MONSTER_ZOMBIE_MELEE.m_id, actor.wait); // just fall back to zombie melee deathtype
			return false;
		}
		case MONSTER_ATTACK_RANGED:
		{
			if(actor.mon_attacks & MON_ATTACK_PROJECTILE)
			{
				int ptype = PROJECTILE_GRENADE;
				float psize = 1.6;
				if(actor.mon_attacktype == MON_ATTACKTYPE_FIREBALL)
				{
					ptype = PROJECTILE_FIREMINE;
					psize = 0.8;
				}
				entity proj = turret_projectile(actor, SND_Null, psize, 0, DEATH_MONSTER_ZOMBIE_JUMP.m_id, ptype, true, true);
				setorigin(proj, CENTER_OR_VIEWOFS(actor));
				if(actor.mon_attacktype == MON_ATTACKTYPE_GRENADE)
				{
					proj.nextthink = time + 3;
					proj.gravity = 1.0;
					settouch(proj, M_CustomMonster_Attack_Grenade_Touch);
					set_movetype(proj, MOVETYPE_TOSS);
					proj.solid = SOLID_TRIGGER;
				}
				makevectors(actor.angles);
				W_SetupProjVelocity_Explicit(proj, v_forward, v_up, actor.mon_proj_speed, actor.mon_proj_speed_up, 0, 0, false);
				UpdateCSQCProjectile(proj);
				actor.attack_finished_single[0] = time + (actor.mon_attack_delay * random());
				return true;
			}
			return false;
		}
	}

	return false;
}

spawnfunc(monster_custom) { Monster_Spawn(this, true, MON_MONSTER.monsterid); }
#endif // SVQC

#ifdef SVQC
METHOD(CustomMonster, mr_think, bool(CustomMonster this, entity actor))
{
    TC(CustomMonster, this);
    if((actor.mon_movetype & MON_MOVE_JUMP) && time >= actor.jump_delay && IS_ONGROUND(actor))
    {
    	UNSET_ONGROUND(actor);
    	actor.velocity_z += actor.mon_jumpheight;
    	actor.jump_delay = time + (actor.mon_jumpdelay * random());
    }
    if(actor.mon_movetype & MON_MOVE_2D)
    {
    	if((actor.mon_movetype & MON_MOVE_TOUCH) && !vec2(actor.velocity))
    		return false; // wait until pushed
    	Monster_Move_2D(actor, actor.speed, actor.mon_jumpoff, actor.mon_alwaysturn);
    	M_CustomMonster_TargetEnemey(actor); // not called by regular code in this case
    	return false;
    }
    if(actor.mon_movetype & MON_MOVE_NORMAL)
    	return true;
    // none handled automatically
    M_CustomMonster_TargetEnemey(actor); // not called by regular code in this case
    return false;
}

METHOD(CustomMonster, mr_pain, float(CustomMonster this, entity actor, float damage_take, entity attacker, float deathtype))
{
    TC(CustomMonster, this);
    if((actor.mon_damageflags & MON_DAMAGE_NONE))
    	return 0;
    if((actor.mon_damageflags & MON_DAMAGE_NOMONSTERS) && IS_MONSTER(attacker))
    	return 0;

    setanim(actor, actor.anim_pain1, true, true, false);
    actor.pain_finished = actor.animstate_endtime;
    actor.velocity = '0 0 0'; // reset velocity
    return damage_take;
}

METHOD(CustomMonster, mr_death, bool(CustomMonster this, entity actor))
{
    TC(CustomMonster, this);
    setanim(actor, actor.anim_melee, false, true, true);
    return true;
}
#endif
#ifdef GAMEQC
METHOD(CustomMonster, mr_anim, bool(CustomMonster this, entity actor))
{
    TC(CustomMonster, this);
    // TODO? Can this even be made to work with CSQC?
#ifdef SVQC
    vector none = '0 0 0';
#define GF(fm,df) ((actor.(fm)) ? actor.(fm) - 1 : (df))
    actor.anim_walk = animfixfps(actor, vec3(GF(frame_walk, 1), 1, 1), none);
    actor.anim_idle = animfixfps(actor, vec3(GF(frame_idle, 0), 1, 1), none);
    actor.anim_melee = animfixfps(actor, vec3(GF(frame_melee, 2), 1, 5), none); // analyze models and set framerate
    actor.anim_shoot = animfixfps(actor, vec3(GF(frame_shoot, 3), 1, 5), none); // analyze models and set framerate
    actor.anim_run = animfixfps(actor, vec3(GF(frame_run, 1), 1, 1), none);
    actor.anim_die1 = animfixfps(actor, vec3(GF(frame_death, 2), 1, 1), none);
    actor.anim_pain1 = animfixfps(actor, vec3(GF(frame_pain, 0), 1, 1), none);
#undef GF
#endif
    return true;
}
#endif
#ifdef SVQC
METHOD(CustomMonster, mr_setup, bool(CustomMonster this, entity actor))
{
    TC(CustomMonster, this);
    // hardcode some defaults so it isn't completely b0rked
    if(!actor.health) actor.health = 100;
    if(!actor.attack_range) actor.attack_range = 150;
    //if(!actor.speed) { actor.speed = 200; }
    //if(!actor.speed2) { actor.speed2 = 400; }
    if(!actor.stopspeed) { actor.stopspeed = 100; }
    if(!actor.damageforcescale) { actor.damageforcescale = 0.15; }
    if(!actor.mon_touchdelay) { actor.mon_touchdelay = 0.2; }
    if(!actor.mon_jumpdelay) { actor.mon_jumpdelay = 4; } // note: randomized
    if(!actor.mon_jumpheight) { actor.mon_jumpheight = 300; }
    if(!actor.mon_touchangle) { actor.mon_touchangle = 0.7; }
    if(!actor.shot_dmg) { actor.shot_dmg = 50; }

    // need to do this here, as the main code doesn't check the monster's spawnflags
    if(actor.spawnflags & MONSTER_TYPE_SWIM)
    	actor.flags |= FL_SWIM;
    if(actor.spawnflags & MONSTER_TYPE_FLY)
	{
		actor.flags |= FL_FLY;
		set_movetype(actor, MOVETYPE_FLY);
	}

	if(actor.mon_movetype & MON_MOVE_BOUNCE)
		set_movetype(actor, MOVETYPE_BOUNCE); // LOL

    FOREACH(Items, it.netname == actor.debris,
    {
    	actor.monster_loot = it;
    	break;
    });

    if(actor.mon_movetype == MON_MOVE_2D)
    	actor.ticrate = sys_frametime; // accuracy required

    actor.monster_attackfunc = M_CustomMonster_Attack;
    settouch(actor, M_CustomMonster_Touch);

    return true;
}

METHOD(CustomMonster, mr_precache, bool(CustomMonster this))
{
    TC(CustomMonster, this);
    return true;
}
#endif
