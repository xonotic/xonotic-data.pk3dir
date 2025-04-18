#include "sv_turrets.qh"

#ifdef SVQC
#include <common/mapobjects/defs.qh>
#include <server/bot/api.qh>
#include <server/damage.qh>
#include <server/weapons/common.qh>
#include <server/weapons/weaponsystem.qh>
#include <server/world.qh>

// Generic aiming
vector turret_aim_generic(entity this)
{
	vector pre_pos, prep;
	float distance, impact_time = 0, i, mintime;

	turret_tag_fire_update(this);

	if(this.aim_flags & TFL_AIM_SIMPLE)
		return real_origin(this.enemy);

	mintime = max(this.attack_finished_single[0] - time,0) + sys_frametime;

	// Baseline
	pre_pos = real_origin(this.enemy);

	// Lead?
	if (this.aim_flags & TFL_AIM_LEAD)
	{
		if (this.aim_flags & TFL_AIM_SHOTTIMECOMPENSATE)	   // Need to conpensate for shot traveltime
		{
			prep = pre_pos;

			distance = vlen(prep - this.tur_shotorg);
			impact_time = distance / this.shot_speed;

			prep = pre_pos + (this.enemy.velocity * (impact_time + mintime));

			if(this.aim_flags & TFL_AIM_ZPREDICT)
			if(!IS_ONGROUND(this.enemy))
			if(this.enemy.move_movetype == MOVETYPE_WALK || this.enemy.move_movetype == MOVETYPE_TOSS || this.enemy.move_movetype == MOVETYPE_BOUNCE)
			{
				float vz;
				prep_z = pre_pos_z;
				vz = this.enemy.velocity_z;
				for(i = 0; i < impact_time; i += sys_frametime)
				{
					vz = vz - (autocvar_sv_gravity * sys_frametime);
					prep_z = prep_z + vz * sys_frametime;
				}
			}
			pre_pos = prep;
		}
		else
			pre_pos = pre_pos + this.enemy.velocity * mintime;
	}

	if(this.aim_flags & TFL_AIM_SPLASH)
	{
		//tracebox(pre_pos + '0 0 32',this.enemy.mins,this.enemy.maxs,pre_pos -'0 0 64',MOVE_WORLDONLY,this.enemy);
		traceline(pre_pos + '0 0 32',pre_pos -'0 0 64',MOVE_WORLDONLY,this.enemy);
		if(trace_fraction != 1.0)
			pre_pos = trace_endpos;
	}

	return pre_pos;
}

float turret_targetscore_support(entity _turret, entity _target)
{
	float score;		// Total score
	float s_score = 0, d_score;

	if (_turret.enemy == _target) s_score = 1;

	d_score = min(_turret.target_range_optimal,tvt_dist) / max(_turret.target_range_optimal,tvt_dist);

	score = (d_score * _turret.target_select_rangebias) +
			(s_score * _turret.target_select_samebias);

	return score;
}

/*
* Generic bias aware score system.
*/
float turret_targetscore_generic(entity _turret, entity _target)
{
	float d_dist;	   // Defendmode Distance
	float score;		// Total score
	float d_score;	  // Distance score
	float a_score;	  // Angular score
	float m_score = 0;  // missile score
	float p_score = 0;  // player score
	float ikr;		  // ideal kill range

	if (_turret.tur_defend)
	{
		d_dist = vlen(real_origin(_target) - _turret.tur_defend.origin);
		ikr = vlen(_turret.origin - _turret.tur_defend.origin);
		d_score = 1 - d_dist / _turret.target_range;
	}
	else
	{
		// Make a normlized value base on the targets distance from our optimal killzone
		ikr = _turret.target_range_optimal;
		d_score = min(ikr, tvt_dist) / max(ikr, tvt_dist);
	}

	a_score = 1 - tvt_thadf / _turret.aim_maxrot;

	if ((_turret.target_select_missilebias > 0) && (_target.flags & FL_PROJECTILE))
		m_score = 1;

	if ((_turret.target_select_playerbias > 0) && IS_CLIENT(_target))
		p_score = 1;

	d_score = max(d_score, 0);
	a_score = max(a_score, 0);
	m_score = max(m_score, 0);
	p_score = max(p_score, 0);

	score = (d_score * _turret.target_select_rangebias) +
			(a_score * _turret.target_select_anglebias) +
			(m_score * _turret.target_select_missilebias) +
			(p_score * _turret.target_select_playerbias);

	if(vdist((_turret.tur_shotorg - real_origin(_target)), >, _turret.target_range))
	{
		//dprint("Wtf?\n");
		score *= 0.001;
	}

#ifdef TURRET_DEBUG
	string sd,sa,sm,sp,ss;
	string sdt,sat,smt,spt;

	sd = ftos(d_score);
	d_score *= _turret.target_select_rangebias;
	sdt = ftos(d_score);

	//sv = ftos(v_score);
	//v_score *= _turret.target_select_samebias;
	//svt = ftos(v_score);

	sa = ftos(a_score);
	a_score *= _turret.target_select_anglebias;
	sat = ftos(a_score);

	sm = ftos(m_score);
	m_score *= _turret.target_select_missilebias;
	smt = ftos(m_score);

	sp = ftos(p_score);
	p_score *= _turret.target_select_playerbias;
	spt = ftos(p_score);


	ss = ftos(score);
	bprint("^3Target scores^7 \[  ",_turret.netname, "  \] ^3for^7 \[  ", _target.netname,"  \]\n");
	bprint("^5Range:\[  ",sd,  "  \]^2+bias:\[  ",sdt,"  \]\n");
	bprint("^5Angle:\[  ",sa,  "  \]^2+bias:\[  ",sat,"  \]\n");
	bprint("^5Missile:\[  ",sm,"  \]^2+bias:\[  ",smt,"  \]\n");
	bprint("^5Player:\[  ",sp, "  \]^2+bias:\[  ",spt,"  \]\n");
	bprint("^3Total (w/bias):\[^1",ss,"\]\n");

#endif

	return score;
}

// Generic damage handling
void turret_hide(entity this)
{
	this.effects   |= EF_NODRAW;
	this.nextthink = time + this.respawntime - 0.2;
	setthink(this, turret_respawn);
}

void turret_die(entity this)
{
	this.deadflag		  = DEAD_DEAD;
	this.tur_head.deadflag = this.deadflag;

	// Unsolidify and hide real parts
	this.solid			 = SOLID_NOT;
	this.tur_head.solid	 = this.solid;

	this.event_damage		  = func_null;
	this.event_heal = func_null;
	this.takedamage			 = DAMAGE_NO;

	SetResourceExplicit(this, RES_HEALTH, 0);

	// Go boom
	//RadiusDamage (this,this, min(this.ammo,50),min(this.ammo,50) * 0.25,250,NULL,min(this.ammo,50)*5,DEATH_TURRET,NULL);

	Turret tur = get_turretinfo(this.m_id);
	if(this.damage_flags & TFL_DMG_DEATH_NORESPAWN)
	{
		// do a simple explosion effect here, since CSQC can't do it on a to-be-removed entity
		sound(this, CH_SHOTS, SND_ROCKET_IMPACT, VOL_BASE, ATTEN_NORM);
		Send_Effect(EFFECT_ROCKET_EXPLODE, this.origin, '0 0 0', 1);

		tur.tr_death(tur, this);

		delete(this.tur_head);
		delete(this);
	}
	else
	{
		// Setup respawn
		this.SendFlags	  |= TNSF_STATUS;
		this.nextthink	 = time + 0.2;
		setthink(this, turret_hide);

		tur.tr_death(tur, this);
	}
}

void turret_damage(entity this, entity inflictor, entity attacker, float damage, int deathtype, .entity weaponentity, vector hitloc, vector vforce)
{
	// Enough already!
	if(this.deadflag == DEAD_DEAD)
		return;

	// Inactive turrets take no damage. (hm..)
	if(!this.active)
		return;

	if(SAME_TEAM(this, attacker))
	{
		if(autocvar_g_friendlyfire)
			damage = damage * autocvar_g_friendlyfire;
		else
			return;
	}

	TakeResource(this, RES_HEALTH, damage);

	// thorw head slightly off aim when hit?
	if (this.damage_flags & TFL_DMG_HEADSHAKE)
	{
		this.tur_head.angles_x = this.tur_head.angles_x + (-0.5 + random()) * damage;
		this.tur_head.angles_y = this.tur_head.angles_y + (-0.5 + random()) * damage;

		this.SendFlags  |= TNSF_ANG;
	}

	if (this.turret_flags & TUR_FLAG_MOVE)
		this.velocity = this.velocity + vforce;

	if (GetResource(this, RES_HEALTH) <= 0)
	{
		this.event_damage		  = func_null;
		this.tur_head.event_damage = func_null;
		this.event_heal = func_null;
		this.tur_head.event_heal = func_null;
		this.takedamage			 = DAMAGE_NO;
		this.nextthink = time;
		setthink(this, turret_die);
	}

	this.SendFlags  |= TNSF_STATUS;
}

bool turret_heal(entity targ, entity inflictor, float amount, float limit)
{
	float true_limit = ((limit != RES_LIMIT_NONE) ? limit : targ.max_health);
	if(GetResource(targ, RES_HEALTH) <= 0 || GetResource(targ, RES_HEALTH) >= true_limit)
		return false;

	GiveResourceWithLimit(targ, RES_HEALTH, amount, true_limit);
	targ.SendFlags |= TNSF_STATUS;
	return true;
}

void turret_think(entity this);
void turret_respawn(entity this)
{
	// Make sure all parts belong to the same team since
	// this function doubles as "teamchange" function.
	this.tur_head.team 	= this.team;
	this.effects			   &= ~EF_NODRAW;
	this.deadflag				= DEAD_NO;
	this.effects				= EF_LOWPRECISION;
	this.solid					= SOLID_BBOX;
	this.takedamage 			= DAMAGE_AIM;
	this.event_damage			= turret_damage;
	this.event_heal 			= turret_heal;
	this.avelocity				= '0 0 0';
	this.tur_head.avelocity		= this.avelocity;
	this.tur_head.angles		= this.idle_aim;
	SetResourceExplicit(this, RES_HEALTH, this.max_health);
	this.enemy					= NULL;
	this.volly_counter			= this.shot_volly;
	this.ammo					= this.ammo_max;

	this.nextthink = time;
	setthink(this, turret_think);

	this.SendFlags = TNSF_FULL_UPDATE;

	Turret tur = get_turretinfo(this.m_id);
	tur.tr_setup(tur, this);

	setorigin(this, this.origin); // make sure it's linked to the area grid
}


// Main functions
.float clientframe;
void turrets_setframe(entity this, float _frame, float client_only)
{
	if((client_only ? this.clientframe : this.frame ) != _frame)
	{
		this.SendFlags |= TNSF_ANIM;
		this.anim_start_time = time;
	}

	if(client_only)
		this.clientframe = _frame;
	else
		this.frame = _frame;

}

bool turret_send(entity this, entity to, float sf)
{
	WriteHeader(MSG_ENTITY, ENT_CLIENT_TURRET);
	WriteByte(MSG_ENTITY, sf);
	if(sf & TNSF_SETUP)
	{
		WriteByte(MSG_ENTITY, this.m_id);

		WriteVector(MSG_ENTITY, this.origin);

		WriteAngleVector2D(MSG_ENTITY, this.angles);
	}

	if(sf & TNSF_ANG)
	{
		WriteShort(MSG_ENTITY, rint(this.tur_head.angles_x));
		WriteShort(MSG_ENTITY, rint(this.tur_head.angles_y));
	}

	if(sf & TNSF_AVEL)
	{
		WriteShort(MSG_ENTITY, rint(this.tur_head.avelocity_x));
		WriteShort(MSG_ENTITY, rint(this.tur_head.avelocity_y));
	}

	if(sf & TNSF_MOVE)
	{
		WriteVector(MSG_ENTITY, this.origin);

		WriteVector(MSG_ENTITY, this.velocity);

		WriteShort(MSG_ENTITY, rint(this.angles_y));
	}

	if(sf & TNSF_ANIM)
	{
		WriteCoord(MSG_ENTITY, this.anim_start_time);
		WriteByte(MSG_ENTITY, this.frame);
	}

	if(sf & TNSF_STATUS)
	{
		WriteByte(MSG_ENTITY, this.team);

		if(GetResource(this, RES_HEALTH) <= 0)
			WriteByte(MSG_ENTITY, 0);
		else
			WriteByte(MSG_ENTITY, ceil((GetResource(this, RES_HEALTH) / this.max_health) * 255));
	}

	return true;
}

void load_unit_settings(entity ent, bool is_reload)
{
	if (ent == NULL)
		return;

	if(!ent.turret_scale_damage)	ent.turret_scale_damage = 1;
	if(!ent.turret_scale_range)		ent.turret_scale_range  = 1;
	if(!ent.turret_scale_refire)	ent.turret_scale_refire = 1;
	if(!ent.turret_scale_ammo)		ent.turret_scale_ammo	= 1;
	if(!ent.turret_scale_aim)		ent.turret_scale_aim	 = 1;
	if(!ent.turret_scale_health)	ent.turret_scale_health = 1;
	if(!ent.turret_scale_respawn)	ent.turret_scale_respawn = 1;

	if (is_reload)
	{
		ent.enemy = NULL;
		ent.tur_head.avelocity = '0 0 0';

		ent.tur_head.angles = '0 0 0';
	}

	string unitname = ent.netname;
	#define X(class, prefix, fld, type) ent.fld = cvar(strcat("g_turrets_unit_", prefix, "_", #fld));
	TR_PROPS_COMMON(X, , unitname)
	#undef X

	ent.ammo_max             *= ent.turret_scale_ammo;
	ent.ammo_recharge        *= ent.turret_scale_ammo;
	ent.aim_speed            *= ent.turret_scale_aim;
	SetResourceExplicit(ent, RES_HEALTH, GetResource(ent, RES_HEALTH) * ent.turret_scale_health);
	ent.respawntime          *= ent.turret_scale_respawn;
	ent.shot_dmg             *= ent.turret_scale_damage;
	ent.shot_refire          *= ent.turret_scale_refire;
	ent.shot_radius          *= ent.turret_scale_damage;
	ent.shot_force           *= ent.turret_scale_damage;
	ent.shot_volly_refire    *= ent.turret_scale_refire;
	ent.target_range         *= ent.turret_scale_range;
	ent.target_range_min     *= ent.turret_scale_range;
	ent.target_range_optimal *= ent.turret_scale_range;

	if(is_reload) {
		Turret tur = get_turretinfo(ent.m_id);
		tur.tr_setup(tur, ent);
	}
}

void turret_projectile_explode(entity this)
{
	this.takedamage = DAMAGE_NO;
	this.event_damage = func_null;
#ifdef TURRET_DEBUG
	float d;
	d = RadiusDamage (this, this.owner, this.owner.shot_dmg, 0, this.owner.shot_radius, this, NULL, this.owner.shot_force, this.projectiledeathtype, DMG_NOWEP, NULL);
	this.owner.tur_debug_dmg_t_h = this.owner.tur_debug_dmg_t_h + d;
	this.owner.tur_debug_dmg_t_f = this.owner.tur_debug_dmg_t_f + this.owner.shot_dmg;
#else
	RadiusDamage (this, this.realowner, this.owner.shot_dmg, 0, this.owner.shot_radius, this, NULL, this.owner.shot_force, this.projectiledeathtype, DMG_NOWEP, NULL);
#endif
	delete(this);
}

void turret_projectile_touch(entity this, entity toucher)
{
	PROJECTILE_TOUCH(this, toucher);
	turret_projectile_explode(this);
}

void turret_projectile_damage(entity this, entity inflictor, entity attacker, float damage, int deathtype, .entity weaponentity, vector hitloc, vector vforce)
{
	this.velocity  += vforce;
	TakeResource(this, RES_HEALTH, damage);
	//this.realowner = attacker; // Dont change realowner, it does not make much sense for turrets
	if(GetResource(this, RES_HEALTH) <= 0)
		W_PrepareExplosionByDamage(this, this.owner, turret_projectile_explode);
}

entity turret_projectile(entity actor, Sound _snd, float _size, float _health, float _death, float _proj_type, float _cull, float _cli_anim)
{
	TC(Sound, _snd);
	entity proj;

	sound (actor, CH_WEAPON_A, _snd, VOL_BASE, ATTEN_NORM);
	proj				 = spawn ();
	setorigin(proj, actor.tur_shotorg);
	setsize(proj, '-0.5 -0.5 -0.5' * _size, '0.5 0.5 0.5' * _size);
	proj.owner		  = actor;
	proj.realowner	  = actor;
	proj.bot_dodge	  = true;
	proj.bot_dodgerating = actor.shot_dmg;
	setthink(proj, turret_projectile_explode);
	settouch(proj, turret_projectile_touch);
	proj.nextthink	  = time + 9;
	set_movetype(proj, MOVETYPE_FLYMISSILE);
	proj.velocity		= normalize(actor.tur_shotdir_updated + randomvec() * actor.shot_spread) * actor.shot_speed;
	proj.flags = FL_PROJECTILE;
	IL_PUSH(g_projectiles, proj);
	IL_PUSH(g_bot_dodge, proj);
	proj.enemy		  = actor.enemy;
	proj.projectiledeathtype	 = _death;
	PROJECTILE_MAKETRIGGER(proj);
	if(_health)
	{
		SetResourceExplicit(proj, RES_HEALTH, _health);
		proj.takedamage	 = DAMAGE_YES;
		proj.event_damage  = turret_projectile_damage;
	}
	else
		proj.flags |= FL_NOTARGET;

	CSQCProjectile(proj, _cli_anim, _proj_type, _cull);

	return proj;
}

/**
** updates enemy distances, predicted impact point/time
** and updated aim<->predict impact distance.
**/
void turret_do_updates(entity t_turret)
{
	vector enemy_pos = real_origin(t_turret.enemy);

	turret_tag_fire_update(t_turret);

	t_turret.tur_shotdir_updated = v_forward;
	t_turret.tur_dist_enemy = vlen(t_turret.tur_shotorg - enemy_pos);
	t_turret.tur_dist_aimpos = vlen(t_turret.tur_shotorg - t_turret.tur_aimpos);

	/*if((t_turret.firecheck_flags & TFL_FIRECHECK_VERIFIED) && (t_turret.enemy))
	{
		oldpos = t_turret.enemy.origin;
		setorigin(t_turret.enemy, t_turret.tur_aimpos);
		tracebox(t_turret.tur_shotorg, '-1 -1 -1', '1 1 1', t_turret.tur_shotorg + (t_turret.tur_shotdir_updated * t_turret.tur_dist_aimpos), MOVE_NORMAL,t_turret);
		setorigin(t_turret.enemy, oldpos);

		if(trace_ent == t_turret.enemy)
			t_turret.tur_dist_impact_to_aimpos = 0;
		else
			t_turret.tur_dist_impact_to_aimpos = vlen(trace_endpos - t_turret.tur_aimpos);
	}
	else*/
		tracebox(t_turret.tur_shotorg, '-1 -1 -1','1 1 1', t_turret.tur_shotorg + (t_turret.tur_shotdir_updated * t_turret.tur_dist_aimpos), MOVE_NORMAL,t_turret);

	t_turret.tur_dist_impact_to_aimpos = vlen(trace_endpos - t_turret.tur_aimpos) - (vlen(t_turret.enemy.maxs - t_turret.enemy.mins) * 0.5);
	t_turret.tur_impactent			 = trace_ent;
	t_turret.tur_impacttime			= vlen(t_turret.tur_shotorg - trace_endpos) / t_turret.shot_speed;
}

/**
** Handles head rotation according to
** the units .track_type and .track_flags
**/
.float turret_framecounter;
void turret_track(entity this)
{
	vector target_angle; // This is where we want to aim
	vector move_angle;   // This is where we can aim
	float f_tmp;
	vector v1, v2;
	v1 = this.tur_head.angles;
	v2 = this.tur_head.avelocity;

	if (this.track_flags == TFL_TRACK_NO)
		return;

	if(!this.active)
		target_angle = this.idle_aim - ('1 0 0' * this.aim_maxpitch);
	else if (this.enemy == NULL)
	{
		if(time > this.lip)
			target_angle = this.idle_aim + this.angles;
		else
			target_angle = vectoangles(normalize(this.tur_aimpos - this.tur_shotorg));
	}
	else
	{
		target_angle = vectoangles(normalize(this.tur_aimpos - this.tur_shotorg));
	}

	this.tur_head.angles_x = anglemods(this.tur_head.angles_x);
	this.tur_head.angles_y = anglemods(this.tur_head.angles_y);

	// Find the diffrence between where we currently aim and where we want to aim
	//move_angle = target_angle - (this.angles + this.tur_head.angles);
	//move_angle = shortangle_vxy(move_angle,(this.angles + this.tur_head.angles));

	move_angle = AnglesTransform_ToAngles(AnglesTransform_LeftDivide(AnglesTransform_FromAngles(this.angles), AnglesTransform_FromAngles(target_angle))) - this.tur_head.angles;
	move_angle = shortangle_vxy(move_angle, this.tur_head.angles);

	switch(this.track_type)
	{
		case TFL_TRACKTYPE_STEPMOTOR:
			f_tmp = this.aim_speed * frametime;
			if (this.track_flags & TFL_TRACK_PITCH)
			{
				this.tur_head.angles_x += bound(-f_tmp, move_angle_x, f_tmp);
				if(this.tur_head.angles_x > this.aim_maxpitch)
					this.tur_head.angles_x = this.aim_maxpitch;

				if(this.tur_head.angles_x  < -this.aim_maxpitch)
					this.tur_head.angles_x = this.aim_maxpitch;
			}

			if (this.track_flags & TFL_TRACK_ROTATE)
			{
				this.tur_head.angles_y += bound(-f_tmp, move_angle_y, f_tmp);
				if(this.tur_head.angles_y > this.aim_maxrot)
					this.tur_head.angles_y = this.aim_maxrot;

				if(this.tur_head.angles_y  < -this.aim_maxrot)
					this.tur_head.angles_y = this.aim_maxrot;
			}

			// CSQC
			this.SendFlags  |= TNSF_ANG;

			return;

		case TFL_TRACKTYPE_FLUIDINERTIA:
			f_tmp = this.aim_speed * frametime;
			move_angle_x = bound(-this.aim_speed, move_angle_x * this.track_accel_pitch * f_tmp, this.aim_speed);
			move_angle_y = bound(-this.aim_speed, move_angle_y * this.track_accel_rot * f_tmp, this.aim_speed);
			move_angle = (this.tur_head.avelocity * this.track_blendrate) + (move_angle * (1 - this.track_blendrate));
			break;

		case TFL_TRACKTYPE_FLUIDPRECISE:

			move_angle_y = bound(-this.aim_speed, move_angle_y, this.aim_speed);
			move_angle_x = bound(-this.aim_speed, move_angle_x, this.aim_speed);

			break;
	}

	//  pitch
	if (this.track_flags & TFL_TRACK_PITCH)
	{
		this.tur_head.avelocity_x = move_angle_x;
		if((this.tur_head.angles_x + this.tur_head.avelocity_x * frametime) > this.aim_maxpitch)
		{
			this.tur_head.avelocity_x = 0;
			this.tur_head.angles_x = this.aim_maxpitch;

			this.SendFlags  |= TNSF_ANG;
		}

		if((this.tur_head.angles_x + this.tur_head.avelocity_x * frametime) < -this.aim_maxpitch)
		{
			this.tur_head.avelocity_x = 0;
			this.tur_head.angles_x = -this.aim_maxpitch;

			this.SendFlags  |= TNSF_ANG;
		}
	}

	//  rot
	if (this.track_flags & TFL_TRACK_ROTATE)
	{
		this.tur_head.avelocity_y = move_angle_y;

		if((this.tur_head.angles_y + this.tur_head.avelocity_y * frametime) > this.aim_maxrot)
		{
			this.tur_head.avelocity_y = 0;
			this.tur_head.angles_y = this.aim_maxrot;

			this.SendFlags  |= TNSF_ANG;
		}

		if((this.tur_head.angles_y + this.tur_head.avelocity_y * frametime) < -this.aim_maxrot)
		{
			this.tur_head.avelocity_y = 0;
			this.tur_head.angles_y = -this.aim_maxrot;

			this.SendFlags  |= TNSF_ANG;
		}
	}

	this.SendFlags  |= TNSF_AVEL;

	// Force a angle update every 10'th frame
	this.turret_framecounter += 1;
	if(this.turret_framecounter >= 10)
	{
		this.SendFlags |= TNSF_ANG;
		this.turret_framecounter = 0;
	}
}

/*
 + TFL_TARGETSELECT_NO
 + TFL_TARGETSELECT_LOS
 + TFL_TARGETSELECT_PLAYERS
 + TFL_TARGETSELECT_MISSILES
 + TFL_TARGETSELECT_VEHICLES
 - TFL_TARGETSELECT_TRIGGERTARGET
 + TFL_TARGETSELECT_ANGLELIMITS
 + TFL_TARGETSELECT_RANGELIMITS
 + TFL_TARGETSELECT_TEAMCHECK
 - TFL_TARGETSELECT_NOBUILTIN
 + TFL_TARGETSELECT_OWNTEAM
*/

/**
** Evaluate a entity for target valitity based on validate_flags
** NOTE: the caller must check takedamage before calling this, to inline this check.
**/
float turret_validate_target(entity e_turret, entity e_target, float validate_flags)
{
	vector v_tmp;

	//if(!validate_flags & TFL_TARGETSELECT_NOBUILTIN)
	//	return -0.5;

	if(!e_target)
		return -2;

	// Don't attack against owner
	if(e_target.owner == e_turret || e_target == e_turret.realowner)
		return -0.5;

	if(!checkpvs(e_target.origin, e_turret))
		return -1;

	if(e_target.alpha != 0 && e_target.alpha <= 0.3)
		return -1;

	if(MUTATOR_CALLHOOK(TurretValidateTarget, e_turret, e_target, validate_flags))
		return M_ARGV(3, float);

	if (validate_flags & TFL_TARGETSELECT_NO)
		return -4;

	// If only this was used more..
	if (e_target.flags & FL_NOTARGET)
		return -5;

	// Cant touch this
	if (GetResource(e_target, RES_HEALTH) <= 0)
		return -6;

	// vehicle
	if(IS_VEHICLE(e_target))
	{
		if ((validate_flags & TFL_TARGETSELECT_VEHICLES) && !e_target.owner)
			return -7;
	}

	// player
	if (IS_CLIENT(e_target))
	{
		if(!(validate_flags & TFL_TARGETSELECT_PLAYERS))
			return -7;

		if (IS_DEAD(e_target))
			return -8;
	}

	// enemy turrets
	if(validate_flags & TFL_TARGETSELECT_NOTURRETS)
	if(e_target.owner.tur_head == e_target)
	if(e_target.team != e_turret.team) // Dont break support units.
		return -9;

	// Missile
	if (e_target.flags & FL_PROJECTILE)
	if(!(validate_flags & TFL_TARGETSELECT_MISSILES))
		return -10;

	if (validate_flags & TFL_TARGETSELECT_MISSILESONLY)
	if(!(e_target.flags & FL_PROJECTILE))
		return -10.5;

	// Team check
	if (validate_flags & TFL_TARGETSELECT_TEAMCHECK)
	{
		if (validate_flags & TFL_TARGETSELECT_OWNTEAM)
		{
			if (e_target.team != e_turret.team)
				return -11;

			if (e_turret.team != e_target.owner.team)
				return -12;

			if (e_turret.team != e_target.aiment.team)
				return -12; // portals
		}
		else
		{
			if (e_target.team == e_turret.team)
				return -13;

			if (e_turret.team == e_target.owner.team)
				return -14;

			if (e_turret.team == e_target.aiment.team)
				return -14; // portals
		}
	}

	// Range limits?
	tvt_dist = vlen(e_turret.origin - real_origin(e_target));
	if (validate_flags & TFL_TARGETSELECT_RANGELIMITS)
	{
		if (tvt_dist < e_turret.target_range_min)
			return -15;

		if (tvt_dist > e_turret.target_range)
			return -16;
	}

	// Can we even aim this thing?
	tvt_thadv = angleofs3(e_turret.tur_head.origin, e_turret.angles + e_turret.tur_head.angles, e_target.origin);
	tvt_tadv = shortangle_vxy(angleofs(e_turret, e_target), e_turret.angles);
	tvt_thadf = vlen(tvt_thadv);

	/*
	if(validate_flags & TFL_TARGETSELECT_FOV)
	{
		if(e_turret.target_select_fov < tvt_thadf)
			return -21;
	}
	*/

	if (validate_flags & TFL_TARGETSELECT_ANGLELIMITS)
	{
		if (fabs(tvt_tadv_x) > e_turret.aim_maxpitch)
			return -17;

		if (fabs(tvt_tadv_y) > e_turret.aim_maxrot)
			return -18;
	}

	// Line of sight?
	if (validate_flags & TFL_TARGETSELECT_LOS)
	{
		v_tmp = real_origin(e_target) + ((e_target.mins + e_target.maxs) * 0.5);

		traceline(e_turret.origin + '0 0 16', v_tmp, 0, e_turret);

		if(vdist(v_tmp - trace_endpos, >, e_turret.aim_firetolerance_dist))
			return -19;
	}

	if (e_target.classname == "grapplinghook")
		return -20;

	/*
	if (e_target.classname == "func_button")
		return -21;
	*/

#ifdef TURRET_DEBUG_TARGETSELECT
	LOG_TRACE("Target:",e_target.netname," is a valid target for ",e_turret.netname);
#endif

	return 1;
}

entity turret_select_target(entity this)
{
	entity e;		// target looper entity
	float  score;	// target looper entity score
	entity e_enemy;  // currently best scoreing target
	float  m_score;  // currently best scoreing target's score

	m_score = 0;
	if(this.enemy && this.enemy.takedamage && turret_validate_target(this,this.enemy,this.target_validate_flags) > 0)
	{
		e_enemy = this.enemy;
		m_score = this.turret_score_target(this,e_enemy) * this.target_select_samebias;
	}
	else
		e_enemy = this.enemy = NULL;

	e = findradius(this.origin, this.target_range);

	// Nothing to aim at?
	if (!e)
		return NULL;

	while (e)
	{
		if(e.takedamage)
		{
			float f = turret_validate_target(this, e, this.target_select_flags);
			//dprint("F is: ", ftos(f), "\n");
			if ( f > 0)
			{
				score = this.turret_score_target(this,e);
				if ((score > m_score) && (score > 0))
				{
					e_enemy = e;
					m_score = score;
				}
			}
		}
		e = e.chain;
	}

	return e_enemy;
}


/*
 + = implemented
 - = not implemented

 + TFL_FIRECHECK_NO
 + TFL_FIRECHECK_WORLD
 + TFL_FIRECHECK_DEAD
 + TFL_FIRECHECK_DISTANCES
 - TFL_FIRECHECK_LOS
 + TFL_FIRECHECK_AIMDIST
 + TFL_FIRECHECK_REALDIST
 - TFL_FIRECHECK_ANGLEDIST
 - TFL_FIRECHECK_TEAMCECK
 + TFL_FIRECHECK_AFF
 + TFL_FIRECHECK_AMMO_OWN
 + TFL_FIRECHECK_AMMO_OTHER
 + TFL_FIRECHECK_REFIRE
*/

/**
** Preforms pre-fire checks based on the uints firecheck_flags
**/
bool turret_firecheck(entity this)
{
	// This one just dont care =)
	if (this.firecheck_flags & TFL_FIRECHECK_NO)
		return true;

	if (this.enemy == NULL)
		return false;

	// Ready?
	if (this.firecheck_flags & TFL_FIRECHECK_REFIRE)
		if (this.attack_finished_single[0] > time) return false;

	// Special case: volly fire turret that has to fire a full volly if a shot was fired.
	if (this.shoot_flags & TFL_SHOOT_VOLLYALWAYS)
		if (this.volly_counter != this.shot_volly)
			if(this.ammo >= this.shot_dmg)
				return true;

	// Lack of zombies makes shooting dead things unnecessary :P
	if (this.firecheck_flags & TFL_FIRECHECK_DEAD)
		if (IS_DEAD(this.enemy))
			return false;

	// Own ammo?
	if (this.firecheck_flags & TFL_FIRECHECK_AMMO_OWN)
		if (this.ammo < this.shot_dmg)
			return false;

	// Other's ammo? (support-supply units)
	if (this.firecheck_flags & TFL_FIRECHECK_AMMO_OTHER)
		if (this.enemy.ammo >= this.enemy.ammo_max)
			return false;

	// Target of opertunity?
	if(turret_validate_target(this, this.tur_impactent, this.target_validate_flags) > 0)
	{
		this.enemy = this.tur_impactent;
		return true;
	}

	if (this.firecheck_flags & TFL_FIRECHECK_DISTANCES)
	{
		// To close?
		if (this.tur_dist_aimpos < this.target_range_min)
		{
			if(turret_validate_target(this, this.tur_impactent, this.target_validate_flags) > 0)
				return true; // Target of opertunity?
			return false;
		}
	}

	// Try to avoid FF?
	if (this.firecheck_flags & TFL_FIRECHECK_AFF)
		if (this.tur_impactent.team == this.team)
			return false;

	// aim<->predicted impact
	if (this.firecheck_flags & TFL_FIRECHECK_AIMDIST)
		if (this.tur_dist_impact_to_aimpos > this.aim_firetolerance_dist)
			return false;

	// Volly status
	if (this.shot_volly > 1)
		if (this.volly_counter == this.shot_volly)
			if (this.ammo < (this.shot_dmg * this.shot_volly))
				return false;

	/*if(this.firecheck_flags & TFL_FIRECHECK_VERIFIED)
		if(this.tur_impactent != this.enemy)
			return false;*/

	return true;
}

bool turret_checkfire(entity this)
{
	if(MUTATOR_CALLHOOK(Turret_CheckFire, this))
		return M_ARGV(1, bool);

	return this.turret_firecheckfunc(this);
}

void turret_fire(entity this)
{
	if (autocvar_g_turrets_nofire != 0)
		return;

	if(MUTATOR_CALLHOOK(TurretFire, this))
		return;

	Turret info = get_turretinfo(this.m_id);
	info.tr_attack(info, this);

	this.attack_finished_single[0] = time + this.shot_refire;
	this.ammo -= this.shot_dmg;
	this.volly_counter = this.volly_counter - 1;

	if (this.volly_counter <= 0)
	{
		this.volly_counter = this.shot_volly;

		if (this.shoot_flags & TFL_SHOOT_CLEARTARGET)
			this.enemy = NULL;

		if (this.shot_volly > 1)
			this.attack_finished_single[0] = time + this.shot_volly_refire;
	}

#ifdef TURRET_DEBUG
	if (this.enemy) paint_target3(this.tur_aimpos, 64, this.tur_debug_rvec, this.tur_impacttime + 0.25);
#endif
}

void turret_think(entity this)
{
	this.nextthink = time;

	MUTATOR_CALLHOOK(TurretThink, this);

#ifdef TURRET_DEBUG
	if (this.tur_debug_tmr1 < time)
	{
		if (this.enemy) paint_target (this.enemy,128,this.tur_debug_rvec,0.9);
		paint_target(this,256,this.tur_debug_rvec,0.9);
		this.tur_debug_tmr1 = time + 1;
	}
#endif

	// Handle ammo
	if (!(this.spawnflags & TSF_NO_AMMO_REGEN))
	if (this.ammo < this.ammo_max)
		this.ammo = min(this.ammo + this.ammo_recharge * frametime, this.ammo_max);

	// Inactive turrets needs to run the think loop,
	// So they can handle animation and wake up if need be.
	if(!this.active)
	{
		turret_track(this);
		return;
	}

	// This is typicaly used for zaping every target in range
	// turret_fusionreactor uses this to recharge friendlys.
	if (this.shoot_flags & TFL_SHOOT_HITALLVALID)
	{
		// Do a this.turret_fire for every valid target.
		entity e = findradius(this.origin,this.target_range);
		while (e)
		{
			if(e.takedamage)
			{
				if (turret_validate_target(this,e,this.target_validate_flags))
				{
					this.enemy = e;

					turret_do_updates(this);

					if (turret_checkfire(this))
						turret_fire(this);
				}
			}

			e = e.chain;
		}
		this.enemy = NULL;
	}
	else if(this.shoot_flags & TFL_SHOOT_CUSTOM)
	{
		// This one is doing something.. oddball. assume its handles what needs to be handled.

		// Predict?
		if(!(this.aim_flags & TFL_AIM_NO))
			this.tur_aimpos = turret_aim_generic(this);

		// Turn & pitch?
		if(!(this.track_flags & TFL_TRACK_NO))
			turret_track(this);

		turret_do_updates(this);

		// Fire?
		if (turret_checkfire(this))
			turret_fire(this);
	}
	else
	{
		// Special case for volly always. if it fired once it must compleate the volly.
		if(this.shoot_flags & TFL_SHOOT_VOLLYALWAYS)
			if(this.volly_counter != this.shot_volly)
			{
				// Predict or whatnot
				if(!(this.aim_flags & TFL_AIM_NO))
					this.tur_aimpos = turret_aim_generic(this);

				// Turn & pitch
				if(!(this.track_flags & TFL_TRACK_NO))
					turret_track(this);

				turret_do_updates(this);

				// Fire!
				if (turret_checkfire(this))
					turret_fire(this);

				Turret tur = get_turretinfo(this.m_id);
				tur.tr_think(tur, this);

				return;
			}

		// Check if we have a vailid enemy, and try to find one if we dont.

		// g_turrets_targetscan_maxdelay forces a target re-scan at least this often
		float do_target_scan = 0;
		if((this.target_select_time + autocvar_g_turrets_targetscan_maxdelay) < time)
			do_target_scan = 1;

		// Old target (if any) invalid?
		if(this.target_validate_time < time)
		if (turret_validate_target(this, this.enemy, this.target_validate_flags) <= 0)
		{
			this.enemy = NULL;
			this.target_validate_time = time + 0.5;
			do_target_scan = 1;
		}

		// But never more often then g_turrets_targetscan_mindelay!
		if (this.target_select_time + autocvar_g_turrets_targetscan_mindelay > time)
			do_target_scan = 0;

		if(do_target_scan)
		{
			this.enemy = turret_select_target(this);
			this.target_select_time = time;
		}

		// No target, just go to idle, do any custom stuff and bail.
		if (this.enemy == NULL)
		{
			// Turn & pitch
			if(!(this.track_flags & TFL_TRACK_NO))
				turret_track(this);

			Turret tur = get_turretinfo(this.m_id);
			tur.tr_think(tur, this);

			// And bail.
			return;
		}
		else
			this.lip = time + autocvar_g_turrets_aimidle_delay; // Keep track of the last time we had a target.

		// Predict?
		if(!(this.aim_flags & TFL_AIM_NO))
			this.tur_aimpos = turret_aim_generic(this);

		// Turn & pitch?
		if(!(this.track_flags & TFL_TRACK_NO))
			turret_track(this);

		turret_do_updates(this);

		// Fire?
		if (turret_checkfire(this))
			turret_fire(this);
	}

	Turret tur = get_turretinfo(this.m_id);
	tur.tr_think(tur, this);
}

/*
	When .used a turret switch team to activator.team.
	If activator is NULL, the turret go inactive.
*/
void turret_use(entity this, entity actor, entity trigger)
{
	LOG_TRACE("Turret ", this.netname, " used by ", actor.classname);

	this.team = actor.team;

	if(this.team == 0)
		this.active = ACTIVE_NOT;
	else
		this.active = ACTIVE_ACTIVE;
}

void turret_link(entity this)
{
	Net_LinkEntity(this, true, 0, turret_send);
	setthink(this, turret_think);
	this.nextthink = time;
	this.tur_head.effects = EF_NODRAW;
}

void turrets_manager_think(entity this)
{
	this.nextthink = time + 1;

	if (autocvar_g_turrets_reloadcvars == 1)
	{
		IL_EACH(g_turrets, true,
		{
			load_unit_settings(it, true);
			Turret tur = get_turretinfo(it.m_id);
			tur.tr_think(tur, it);
		});
		cvar_set("g_turrets_reloadcvars", "0");
	}
}

void turret_initparams(entity tur)
{
	#define TRY(x) (x) ? (x)
	tur.respawntime                 = max  (-1,              (TRY(tur.respawntime)               :  60                                         ));
	tur.shot_refire                 = bound(0.01,            (TRY(tur.shot_refire)               :  1                                          ), 9999);
	tur.shot_dmg                    = max  (1,               (TRY(tur.shot_dmg)                  :  tur.shot_refire * 50                       ));
	tur.shot_radius                 = max  (1,               (TRY(tur.shot_radius)               :  tur.shot_dmg * 0.5                         ));
	tur.shot_speed                  = max  (1,               (TRY(tur.shot_speed)                :  2500                                       ));
	tur.shot_spread                 = bound(0.0001,          (TRY(tur.shot_spread)               :  0.0125                                     ), 500);
	tur.shot_force                  = bound(0.001,           (TRY(tur.shot_force)                :  tur.shot_dmg * 0.5 + tur.shot_radius * 0.5 ), 5000);
	tur.shot_volly                  = bound(1,               (TRY(tur.shot_volly)                :  1                                          ), floor(tur.ammo_max / tur.shot_dmg));
	tur.shot_volly_refire           = bound(tur.shot_refire, (TRY(tur.shot_volly_refire)         :  tur.shot_refire * tur.shot_volly           ), 60);
	tur.target_range                = bound(0,               (TRY(tur.target_range)              :  tur.shot_speed * 0.5                       ), max_shot_distance);
	tur.target_range_min            = bound(0,               (TRY(tur.target_range_min)          :  tur.shot_radius * 2                        ), max_shot_distance);
	tur.target_range_optimal        = bound(0,               (TRY(tur.target_range_optimal)      :  tur.target_range * 0.5                     ), max_shot_distance);
	tur.aim_maxrot                  = bound(0,               (TRY(tur.aim_maxrot)                :  90                                         ), 360);
	tur.aim_maxpitch                = bound(0,               (TRY(tur.aim_maxpitch)              :  20                                         ), 90);
	tur.aim_speed                   = bound(0.1,             (TRY(tur.aim_speed)                 :  36                                         ), 1000);
	tur.aim_firetolerance_dist      = bound(0.1,             (TRY(tur.aim_firetolerance_dist)    :  5 + (tur.shot_radius * 2)                  ), max_shot_distance);
	tur.target_select_rangebias     = bound(-10,             (TRY(tur.target_select_rangebias)   :  1                                          ), 10);
	tur.target_select_samebias      = bound(-10,             (TRY(tur.target_select_samebias)    :  1                                          ), 10);
	tur.target_select_anglebias     = bound(-10,             (TRY(tur.target_select_anglebias)   :  1                                          ), 10);
	tur.target_select_missilebias   = bound(-10,             (TRY(tur.target_select_missilebias) :  1                                          ), 10);
	tur.target_select_playerbias    = bound(-10,             (TRY(tur.target_select_playerbias)  :  1                                          ), 10);
	tur.ammo_max                    = max  (tur.shot_dmg,    (TRY(tur.ammo_max)                  :  tur.shot_dmg * 10                          ));
	tur.ammo_recharge               = max  (0,               (TRY(tur.ammo_recharge)             :  tur.shot_dmg * 0.5                         ));
	#undef TRY
}

bool turret_closetotarget(entity this, vector targ, float range)
{
	vector path_extra_size = '1 1 1' * range;
	return boxesoverlap(targ - path_extra_size, targ + path_extra_size, this.absmin - path_extra_size, this.absmax + path_extra_size);
}

void turret_findtarget(entity this)
{
	entity e = find(NULL, classname, "turret_manager");
	if(!e)
	{
		e = new_pure(turret_manager);
		setthink(e, turrets_manager_think);
		e.nextthink = time + 2;
	}

	entity targ = find(NULL, targetname, this.target);
	if(targ.classname == "turret_checkpoint")
		return; // turrets don't defend checkpoints?

	if (!targ)
	{
		this.target = "";
		LOG_TRACE("Turret has invalid defendpoint!");
	}

	this.tur_defend = targ;
	this.idle_aim = this.tur_head.angles + angleofs(this.tur_head, targ);
}

void turret_reset(entity this)
{
	turret_respawn(this);
}

bool turret_initialize(entity this, Turret tur)
{
	if(!autocvar_g_turrets)
		return false;

	if(tur.m_id == 0)
		return false; // invalid turret

	// if tur_head exists, we can assume this turret re-spawned
	if(!this.tur_head) {
		tur.tr_precache(tur);
		IL_PUSH(g_turrets, this);
		IL_PUSH(g_bot_targets, this);
	}

	if(!(this.spawnflags & TSF_SUSPENDED))
		DropToFloor_QC_DelayedInit(this);

	this.netname = tur.netname;
	load_unit_settings(this, 0);

	if(!this.team || !teamplay)		{ this.team = FLOAT_MAX; }
	if(!GetResource(this, RES_HEALTH)) { SetResourceExplicit(this, RES_HEALTH, 1000); }
	if(!this.shot_refire)			{ this.shot_refire = 1; }
	if(!this.tur_shotorg)			{ this.tur_shotorg = '50 0 50'; }
	if(!this.turret_flags)			{ this.turret_flags = TUR_FLAG_SPLASH | TUR_FLAG_MEDPROJ | TUR_FLAG_PLAYER; }
	if(!this.damage_flags)			{ this.damage_flags = TFL_DMG_YES | TFL_DMG_RETALIATE | TFL_DMG_AIMSHAKE; }
	if(!this.aim_flags)				{ this.aim_flags = TFL_AIM_LEAD | TFL_AIM_SHOTTIMECOMPENSATE; }
	if(!this.track_type)			{ this.track_type = TFL_TRACKTYPE_STEPMOTOR; }
	if(!this.track_flags)			{ this.track_flags = TFL_TRACK_PITCH | TFL_TRACK_ROTATE; }
	if(!this.ammo_flags)			{ this.ammo_flags = TFL_AMMO_ENERGY | TFL_AMMO_RECHARGE; }
	if(!this.target_select_flags)	{ this.target_select_flags = TFL_TARGETSELECT_LOS | TFL_TARGETSELECT_TEAMCHECK | TFL_TARGETSELECT_RANGELIMITS | TFL_TARGETSELECT_ANGLELIMITS; }
	if(!this.firecheck_flags)		{ this.firecheck_flags = TFL_FIRECHECK_DEAD | TFL_FIRECHECK_DISTANCES | TFL_FIRECHECK_LOS
														   | TFL_FIRECHECK_AIMDIST | TFL_FIRECHECK_TEAMCHECK | TFL_FIRECHECK_AMMO_OWN | TFL_FIRECHECK_REFIRE; }

	if(this.track_type != TFL_TRACKTYPE_STEPMOTOR)
	{
		// Fluid / Ineria mode. Looks mutch nicer.
		// Can reduce aim preformance alot, needs a bit diffrent aimspeed

		this.aim_speed = bound(0.1, ((!this.aim_speed) ? 180 : this.aim_speed), 1000);

		if(!this.track_accel_pitch)		{ this.track_accel_pitch = 0.5; }
		if(!this.track_accel_rot)		{ this.track_accel_rot = 0.5; }
		if(!this.track_blendrate)		{ this.track_blendrate = 0.35; }
	}

	turret_initparams(this);

	this.turret_flags = TUR_FLAG_ISTURRET | (tur.spawnflags);

	if(this.turret_flags & TUR_FLAG_SPLASH)
		this.aim_flags |= TFL_AIM_SPLASH;

	if(this.turret_flags & TUR_FLAG_MISSILE)
		this.target_select_flags |= TFL_TARGETSELECT_MISSILES;

	if(this.turret_flags & TUR_FLAG_PLAYER)
		this.target_select_flags |= TFL_TARGETSELECT_PLAYERS;

	if(this.spawnflags & TSL_NO_RESPAWN)
		this.damage_flags |= TFL_DMG_DEATH_NORESPAWN;

	if (this.turret_flags & TUR_FLAG_SUPPORT)
		this.turret_score_target = turret_targetscore_support;
	else
		this.turret_score_target = turret_targetscore_generic;

	++turret_count;

	_setmodel(this, tur.model);
	setsize(this, tur.m_mins, tur.m_maxs);

	this.m_id					= tur.m_id;
	this.active					= ACTIVE_ACTIVE;
	this.effects				= EF_NODRAW;
	this.netname				= tur.m_name;
	this.max_health				= GetResource(this, RES_HEALTH);
	this.target_validate_flags	= this.target_select_flags;
	this.ammo					= this.ammo_max;
	this.solid					= SOLID_BBOX;
	this.takedamage				= DAMAGE_AIM;
	set_movetype(this, MOVETYPE_NOCLIP);
	this.view_ofs				= '0 0 0';
	this.idle_aim 				= '0 0 0';
	this.turret_firecheckfunc	= turret_firecheck;
	this.event_damage			= turret_damage;
	this.event_heal 			= turret_heal;
	this.use					= turret_use;
	this.bot_attack				= true;
	this.nextthink				= time + 1;
	this.reset					= turret_reset;

	this.tur_head = new(turret_head);
	_setmodel(this.tur_head, tur.head_model);
	setsize(this.tur_head, '0 0 0', '0 0 0');
	setorigin(this.tur_head, '0 0 0');
	setattachment(this.tur_head, this, "tag_head");

	this.tur_head.netname		= this.tur_head.classname;
	this.tur_head.team			= this.team;
	this.tur_head.owner			= this;
	this.tur_head.takedamage	= DAMAGE_NO;
	this.tur_head.solid			= SOLID_NOT;
	set_movetype(this.tur_head, this.move_movetype);

	this.weaponentities[0] = this; // lol

	if(!this.tur_defend && this.target != "")
		InitializeEntity(this, turret_findtarget, INITPRIO_FINDTARGET);

#ifdef TURRET_DEBUG
	this.tur_debug_start = this.nextthink;
	while(vdist(this.tur_debug_rvec, <, 2))
		this.tur_debug_rvec = randomvec() * 4;

	this.tur_debug_rvec_x = fabs(this.tur_debug_rvec_x);
	this.tur_debug_rvec_y = fabs(this.tur_debug_rvec_y);
	this.tur_debug_rvec_z = fabs(this.tur_debug_rvec_z);
#endif

	turret_link(this);
	turret_respawn(this);
	turret_tag_fire_update(this);

	tur.tr_setup(tur, this);

	if(MUTATOR_CALLHOOK(TurretSpawn, this))
		return false;

	return true;
}
#endif
