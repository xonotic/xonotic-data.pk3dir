#include "shockwave.qh"

REGISTER_NET_TEMP(TE_CSQC_SHOCKWAVEPARTICLE)

#ifdef SVQC

const float MAX_SHOCKWAVE_HITS = 10;
//#define DEBUG_SHOCKWAVE

.float swing_prev;
.entity swing_alreadyhit;
.float shockwave_blasttime;
entity shockwave_hit[MAX_SHOCKWAVE_HITS];
float shockwave_hit_damage[MAX_SHOCKWAVE_HITS];
vector shockwave_hit_force[MAX_SHOCKWAVE_HITS];

// MELEE ATTACK MODE
void W_Shockwave_Melee_Think(entity this)
{
	// declarations
	float i, f, swing, swing_factor, swing_damage, meleetime, is_player;
	entity target_victim;
	vector targpos;

	// check to see if we can still continue, otherwise give up now
	if(IS_DEAD(this.realowner) && WEP_CVAR(shockwave, melee_no_doubleslap))
	{
		delete(this);
		return;
	}

	// set start time of melee
	if(!this.cnt)
	{
		this.cnt = time;
		W_PlayStrengthSound(this.realowner);
	}

	// update values for v_* vectors
	makevectors(this.realowner.v_angle);

	// calculate swing percentage based on time
	meleetime = WEP_CVAR(shockwave, melee_time) * W_WeaponRateFactor(this.realowner);
	swing = bound(0, (this.cnt + meleetime - time) / meleetime, 10);
	f = ((1 - swing) * WEP_CVAR(shockwave, melee_traces));

	// perform the traces needed for this frame
	for(i=this.swing_prev; i < f; ++i)
	{
		swing_factor = ((1 - (i / WEP_CVAR(shockwave, melee_traces))) * 2 - 1);

		targpos = (this.realowner.origin + this.realowner.view_ofs
			+ (v_forward * WEP_CVAR(shockwave, melee_range))
			+ (v_up * swing_factor * WEP_CVAR(shockwave, melee_swing_up))
			+ (v_right * swing_factor * WEP_CVAR(shockwave, melee_swing_side)));

		WarpZone_traceline_antilag(
			this.realowner,
			(this.realowner.origin + this.realowner.view_ofs),
			targpos,
			false,
			this.realowner,
			ANTILAG_LATENCY(this.realowner)
		);

		// draw lightning beams for debugging
#ifdef DEBUG_SHOCKWAVE
		te_lightning2(NULL, targpos, this.realowner.origin + this.realowner.view_ofs + v_forward * 5 - v_up * 5);
		te_customflash(targpos, 40,  2, '1 1 1');
#endif

		is_player = (IS_PLAYER(trace_ent) || trace_ent.classname == "body" || IS_MONSTER(trace_ent));

		if((trace_fraction < 1) // if trace is good, apply the damage and remove this if necessary
			&& (trace_ent.takedamage == DAMAGE_AIM)
			&& (trace_ent != this.swing_alreadyhit)
			&& (is_player || WEP_CVAR(shockwave, melee_nonplayerdamage)))
		{
			target_victim = trace_ent; // so it persists through other calls

			if(is_player) // this allows us to be able to nerf the non-player damage done in e.g. assault or onslaught
				swing_damage = (WEP_CVAR(shockwave, melee_damage) * min(1, swing_factor + 1));
			else
				swing_damage = (WEP_CVAR(shockwave, melee_nonplayerdamage) * min(1, swing_factor + 1));

			// trigger damage with this calculated info
			Damage(
				target_victim,
				this.realowner,
				this.realowner,
				swing_damage,
				(WEP_SHOCKWAVE.m_id | HITTYPE_SECONDARY),
				this.weaponentity_fld,
				(this.realowner.origin + this.realowner.view_ofs),
				(v_forward * WEP_CVAR(shockwave, melee_force))
			);

			// handle accuracy
			if(accuracy_isgooddamage(this.realowner, target_victim))
				{ accuracy_add(this.realowner, WEP_SHOCKWAVE, 0, swing_damage); }

			#ifdef DEBUG_SHOCKWAVE
			LOG_INFOF(
				"MELEE: %s hitting %s with %f damage (factor: %f) at %f time.",
				this.realowner.netname,
				target_victim.netname,
				swing_damage,
				swing_factor,
				time
			);
			#endif

			// allow multiple hits with one swing, but not against the same player twice
			if(WEP_CVAR(shockwave, melee_multihit))
			{
				this.swing_alreadyhit = target_victim;
				continue; // move along to next trace
			}
			else
			{
				delete(this);
				return;
			}
		}
	}

	if(time >= this.cnt + meleetime)
	{
		// melee is finished
		delete(this);
		return;
	}
	else
	{
		// set up next frame
		this.swing_prev = i;
		this.nextthink = time;
	}
}

void W_Shockwave_Melee(Weapon thiswep, entity actor, .entity weaponentity, int fire)
{
	sound(actor, CH_WEAPON_A, SND_SHOTGUN_MELEE, VOL_BASE, ATTN_NORM);
	weapon_thinkf(actor, weaponentity, WFRAME_FIRE2, WEP_CVAR(shockwave, melee_animtime), w_ready);

	entity meleetemp = new_pure(meleetemp);
	meleetemp.owner = meleetemp.realowner = actor;
	setthink(meleetemp, W_Shockwave_Melee_Think);
	meleetemp.nextthink = time + WEP_CVAR(shockwave, melee_delay) * W_WeaponRateFactor(actor);
	meleetemp.weaponentity_fld = weaponentity;
	W_SetupShot_Range(actor, weaponentity, true, 0, SND_Null, 0, WEP_CVAR(shockwave, melee_damage), WEP_CVAR(shockwave, melee_range), thiswep.m_id | HITTYPE_SECONDARY);
}

// SHOCKWAVE ATTACK MODE
float W_Shockwave_Attack_CheckSpread(
	vector targetorg,
	vector nearest_on_line,
	vector sw_shotorg,
	vector attack_endpos)
{
	float spreadlimit;
	float distance_of_attack = vlen(sw_shotorg - attack_endpos);
	float distance_from_line = vlen(targetorg - nearest_on_line);

	spreadlimit = (distance_of_attack ? min(1, (vlen(sw_shotorg - nearest_on_line) / distance_of_attack)) : 1);
	spreadlimit =
		(
			(WEP_CVAR(shockwave, blast_spread_min) * (1 - spreadlimit))
			+
			(WEP_CVAR(shockwave, blast_spread_max) * spreadlimit)
		);

	if(
		(spreadlimit && (distance_from_line <= spreadlimit))
		&&
		((vlen(normalize(targetorg - sw_shotorg) - normalize(attack_endpos - sw_shotorg)) * RAD2DEG) <= 90)
	)
		{ return bound(0, (distance_from_line / spreadlimit), 1); }
	else
		{ return false; }
}

float W_Shockwave_Attack_IsVisible(
	entity actor,
	entity head,
	vector nearest_on_line,
	vector sw_shotorg,
	vector attack_endpos)
{
	vector nearest_to_attacker = head.WarpZone_findradius_nearest;
	vector center = (head.origin + (head.mins + head.maxs) * 0.5);
	vector corner;
	float i;

	// STEP ONE: Check if the nearest point is clear
	if(W_Shockwave_Attack_CheckSpread(nearest_to_attacker, nearest_on_line, sw_shotorg, attack_endpos))
	{
		WarpZone_TraceLine(sw_shotorg, nearest_to_attacker, MOVE_NOMONSTERS, actor);
		if(trace_fraction == 1) { return true; } // yes, the nearest point is clear and we can allow the damage
	}

	// STEP TWO: Check if shotorg to center point is clear
	if(W_Shockwave_Attack_CheckSpread(center, nearest_on_line, sw_shotorg, attack_endpos))
	{
		WarpZone_TraceLine(sw_shotorg, center, MOVE_NOMONSTERS, actor);
		if(trace_fraction == 1) { return true; } // yes, the center point is clear and we can allow the damage
	}

	// STEP THREE: Check each corner to see if they are clear
	for(i=1; i<=8; ++i)
	{
		corner = get_corner_position(head, i);
		if(W_Shockwave_Attack_CheckSpread(corner, nearest_on_line, sw_shotorg, attack_endpos))
		{
			WarpZone_TraceLine(sw_shotorg, corner, MOVE_NOMONSTERS, actor);
			if(trace_fraction == 1) { return true; } // yes, this corner is clear and we can allow the damage
		}
	}

	return false;
}

float W_Shockwave_Attack_CheckHit(
	float queue,
	entity head,
	vector final_force,
	float final_damage)
{
	if(!head) { return false; }
	float i;

	for(i = 0; i <= queue; ++i)
	{
		if(shockwave_hit[i] == head)
		{
			if(vlen2(final_force) > vlen2(shockwave_hit_force[i])) { shockwave_hit_force[i] = final_force; }
			if(final_damage > shockwave_hit_damage[i]) { shockwave_hit_damage[i] = final_damage; }
			return false;
		}
	}

	shockwave_hit[queue] = head;
	shockwave_hit_force[queue] = final_force;
	shockwave_hit_damage[queue] = final_damage;
	return true;
}

void W_Shockwave_Send(entity actor)
{
	WriteHeader(MSG_BROADCAST, TE_CSQC_SHOCKWAVEPARTICLE);
	WriteVector(MSG_BROADCAST, w_shotorg);
	WriteVector(MSG_BROADCAST, w_shotdir);
	WriteShort(MSG_BROADCAST, WEP_CVAR(shockwave, blast_distance));
	WriteByte(MSG_BROADCAST, bound(0, WEP_CVAR(shockwave, blast_spread_max), 255));
	WriteByte(MSG_BROADCAST, bound(0, WEP_CVAR(shockwave, blast_spread_min), 255));
	WriteByte(MSG_BROADCAST, etof(actor));
}

void W_Shockwave_Attack(Weapon thiswep, entity actor, .entity weaponentity)
{
	// declarations
	float multiplier, multiplier_from_accuracy, multiplier_from_distance;
	float final_damage;
	vector final_force, center, vel;
	entity head;

	float i, queue = 0;

	// set up the shot direction
	W_SetupShot(actor, weaponentity, true, 3, SND_LASERGUN_FIRE, CH_WEAPON_B, WEP_CVAR(shockwave, blast_damage), thiswep.m_id);
	vector attack_endpos = (w_shotorg + (w_shotdir * WEP_CVAR(shockwave, blast_distance)));
	WarpZone_TraceLine(w_shotorg, attack_endpos, MOVE_NOMONSTERS, actor);
	vector attack_hitpos = trace_endpos;
	float distance_to_end = vlen(w_shotorg - attack_endpos);
	float distance_to_hit = vlen(w_shotorg - attack_hitpos);
	//entity transform = WarpZone_trace_transform;

	// do the firing effect now
	W_Shockwave_Send(actor);
	Damage_DamageInfo(
		attack_hitpos,
		WEP_CVAR(shockwave, blast_splash_damage),
		WEP_CVAR(shockwave, blast_splash_edgedamage),
		WEP_CVAR(shockwave, blast_splash_radius),
		w_shotdir * WEP_CVAR(shockwave, blast_splash_force),
		thiswep.m_id,
		0,
		actor
	);

	// splash damage/jumping trace
	head = WarpZone_FindRadius(
		attack_hitpos,
		max(
			WEP_CVAR(shockwave, blast_splash_radius),
			WEP_CVAR(shockwave, blast_jump_radius)
		),
		false
	);

	float lag = ((IS_REAL_CLIENT(actor)) ? ANTILAG_LATENCY(actor) : 0);
	bool noantilag = ((IS_CLIENT(actor)) ? CS_CVAR(actor).cvar_cl_noantilag : false);
	if(lag < 0.001)
		lag = 0;
	if(autocvar_g_antilag == 0 || noantilag)
		lag = 0; // only do hitscan, but no antilag
	if(lag)
		antilag_takeback_all(actor, lag);

	while(head)
	{
		if(head.takedamage)
		{
			float distance_to_head = vlen(attack_hitpos - head.WarpZone_findradius_nearest);

			if((head == actor) && (distance_to_head <= WEP_CVAR(shockwave, blast_jump_radius)))
			{
				// ========================
				//  BLAST JUMP CALCULATION
				// ========================

				// calculate importance of distance and accuracy for this attack
				multiplier_from_accuracy = (1 -
					(distance_to_head ?
						min(1, (distance_to_head / WEP_CVAR(shockwave, blast_jump_radius)))
						:
						0
					)
				);
				multiplier_from_distance = (1 -
					(distance_to_hit ?
						min(1, (distance_to_hit / distance_to_end))
						:
						0
					)
				);
				multiplier =
					max(
						WEP_CVAR(shockwave, blast_jump_multiplier_min),
						(
							(multiplier_from_accuracy * WEP_CVAR(shockwave, blast_jump_multiplier_accuracy))
							+
							(multiplier_from_distance * WEP_CVAR(shockwave, blast_jump_multiplier_distance))
						)
					);

				// calculate damage from multiplier: 1 = "highest" damage, 0 = "lowest" edgedamage
				final_damage =
					(
						(WEP_CVAR(shockwave, blast_jump_damage) * multiplier)
						+
						(WEP_CVAR(shockwave, blast_jump_edgedamage) * (1 - multiplier))
					);

				// figure out the direction of force
				vel = normalize(vec2(head.velocity));
				vel *=
					(
						bound(0, (vlen(vel) / autocvar_sv_maxspeed), 1)
						*
						WEP_CVAR(shockwave, blast_jump_force_velocitybias)
					);
				final_force = normalize((CENTER_OR_VIEWOFS(head) - attack_hitpos) + vel);

				// now multiply the direction by force units
				final_force *= (WEP_CVAR(shockwave, blast_jump_force) * multiplier);
				final_force.z *= WEP_CVAR(shockwave, blast_jump_force_zscale);

				// trigger damage with this calculated info
				Damage(
					head,
					actor,
					actor,
					final_damage,
					thiswep.m_id,
					weaponentity,
					head.origin,
					final_force
				);

				#ifdef DEBUG_SHOCKWAVE
				LOG_INFOF(
					"SELF HIT: multiplier = %f, damage = %f, force = %f... "
					"multiplier_from_accuracy = %f, multiplier_from_distance = %f.",
					multiplier,
					final_damage,
					vlen(final_force),
					multiplier_from_accuracy,
					multiplier_from_distance
				);
				#endif
			}
			else if(distance_to_head <= WEP_CVAR(shockwave, blast_splash_radius))
			{
				// ==========================
				//  BLAST SPLASH CALCULATION
				// ==========================

				// calculate importance of distance and accuracy for this attack
				multiplier_from_accuracy = (1 -
					(distance_to_head ?
						min(1, (distance_to_head / WEP_CVAR(shockwave, blast_splash_radius)))
						:
						0
					)
				);
				multiplier_from_distance = (1 -
					(distance_to_hit ?
						min(1, (distance_to_hit / distance_to_end))
						:
						0
					)
				);
				multiplier =
					max(
						WEP_CVAR(shockwave, blast_splash_multiplier_min),
						(
							(multiplier_from_accuracy * WEP_CVAR(shockwave, blast_splash_multiplier_accuracy))
							+
							(multiplier_from_distance * WEP_CVAR(shockwave, blast_splash_multiplier_distance))
						)
					);

				// calculate damage from multiplier: 1 = "highest" damage, 0 = "lowest" edgedamage
				final_damage =
					(
						(WEP_CVAR(shockwave, blast_splash_damage) * multiplier)
						+
						(WEP_CVAR(shockwave, blast_splash_edgedamage) * (1 - multiplier))
					);

				// figure out the direction of force
				final_force = (w_shotdir * WEP_CVAR(shockwave, blast_splash_force_forwardbias));
				final_force = normalize(CENTER_OR_VIEWOFS(head) - (attack_hitpos - final_force));
				//te_lightning2(NULL, attack_hitpos, (attack_hitpos + (final_force * 200)));

				// now multiply the direction by force units
				final_force *= (WEP_CVAR(shockwave, blast_splash_force) * multiplier);
				final_force.z *= WEP_CVAR(shockwave, blast_force_zscale);

				// queue damage with this calculated info
				if(W_Shockwave_Attack_CheckHit(queue, head, final_force, final_damage)) { queue = min(queue + 1, MAX_SHOCKWAVE_HITS); }

				#ifdef DEBUG_SHOCKWAVE
				LOG_INFOF(
					"SPLASH HIT: multiplier = %f, damage = %f, force = %f... "
					"multiplier_from_accuracy = %f, multiplier_from_distance = %f.",
					multiplier,
					final_damage,
					vlen(final_force),
					multiplier_from_accuracy,
					multiplier_from_distance
				);
				#endif
			}
		}
		head = head.chain;
	}

	// cone damage trace
	head = WarpZone_FindRadius(w_shotorg, WEP_CVAR(shockwave, blast_distance), false);
	while(head)
	{
		if((head != actor) && head.takedamage)
		{
			// ========================
			//  BLAST CONE CALCULATION
			// ========================

			// if it's a player, use the view origin as reference (stolen from RadiusDamage functions in damage.qc)
			center = CENTER_OR_VIEWOFS(head);

			// find the closest point on the enemy to the center of the attack
			float h; // hypotenuse, which is the distance between attacker to head
			float a; // adjacent side, which is the distance between attacker and the point on w_shotdir that is closest to head.origin

			h = vlen(center - actor.origin);
			a = h * (normalize(center - actor.origin) * w_shotdir);
			// WEAPONTODO: replace with simpler method

			vector nearest_on_line = (w_shotorg + a * w_shotdir);
			vector nearest_to_attacker = NearestPointOnBoundingBox(center + head.mins, center + head.maxs, nearest_on_line);

			if((vdist(head.WarpZone_findradius_dist, <=, WEP_CVAR(shockwave, blast_distance)))
				&& (W_Shockwave_Attack_IsVisible(actor, head, nearest_on_line, w_shotorg, attack_endpos)))
			{
				// calculate importance of distance and accuracy for this attack
				multiplier_from_accuracy = (1 -
					W_Shockwave_Attack_CheckSpread(
						nearest_to_attacker,
						nearest_on_line,
						w_shotorg,
						attack_endpos
					)
				);
				multiplier_from_distance = (1 -
					(distance_to_hit ?
						min(1, (vlen(head.WarpZone_findradius_dist) / distance_to_end))
						:
						0
					)
				);
				multiplier =
					max(
						WEP_CVAR(shockwave, blast_multiplier_min),
						(
							(multiplier_from_accuracy * WEP_CVAR(shockwave, blast_multiplier_accuracy))
							+
							(multiplier_from_distance * WEP_CVAR(shockwave, blast_multiplier_distance))
						)
					);

				// calculate damage from multiplier: 1 = "highest" damage, 0 = "lowest" edgedamage
				final_damage =
					(
						(WEP_CVAR(shockwave, blast_damage) * multiplier)
						+
						(WEP_CVAR(shockwave, blast_edgedamage) * (1 - multiplier))
					);

				// figure out the direction of force
				final_force = (w_shotdir * WEP_CVAR(shockwave, blast_force_forwardbias));
				final_force = normalize(center - (nearest_on_line - final_force));
				//te_lightning2(NULL, nearest_on_line, (attack_hitpos + (final_force * 200)));

				// now multiply the direction by force units
				final_force *= (WEP_CVAR(shockwave, blast_force) * multiplier);
				final_force.z *= WEP_CVAR(shockwave, blast_force_zscale);

				// queue damage with this calculated info
				if(W_Shockwave_Attack_CheckHit(queue, head, final_force, final_damage)) { queue = min(queue + 1, MAX_SHOCKWAVE_HITS); }

				#ifdef DEBUG_SHOCKWAVE
				LOG_INFOF(
					"BLAST HIT: multiplier = %f, damage = %f, force = %f... "
					"multiplier_from_accuracy = %f, multiplier_from_distance = %f.",
					multiplier,
					final_damage,
					vlen(final_force),
					multiplier_from_accuracy,
					multiplier_from_distance
				);
				#endif
			}
		}
		head = head.chain;
	}

	for(i = 1; i <= queue; ++i)
	{
		head = shockwave_hit[i-1];
		final_force = shockwave_hit_force[i-1];
		final_damage = shockwave_hit_damage[i-1];

		Damage(
			head,
			actor,
			actor,
			final_damage,
			thiswep.m_id,
			weaponentity,
			head.origin,
			final_force
		);

		if(accuracy_isgooddamage(actor, head))
			accuracy_add(actor, thiswep, 0, final_damage);

		#ifdef DEBUG_SHOCKWAVE
		LOG_INFOF(
			"SHOCKWAVE by %s: damage = %f, force = %f.",
			actor.netname,
			final_damage,
			vlen(final_force)
		);
		#endif

		shockwave_hit[i-1] = NULL;
		shockwave_hit_force[i-1] = '0 0 0';
		shockwave_hit_damage[i-1] = 0;
	}

	if(lag)
		antilag_restore_all(actor);
}

METHOD(Shockwave, wr_aim, void(entity thiswep, entity actor, .entity weaponentity))
{
    if(vdist(actor.origin - actor.enemy.origin, <=, WEP_CVAR(shockwave, melee_range)))
        { PHYS_INPUT_BUTTON_ATCK2(actor) = bot_aim(actor, weaponentity, 1000000, 0, 0.001, false); }
    else
        { PHYS_INPUT_BUTTON_ATCK(actor) = bot_aim(actor, weaponentity, 1000000, 0, 0.001, false); }
}
METHOD(Shockwave, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
{
    if(fire & 1)
    {
        if(time >= actor.(weaponentity).shockwave_blasttime) // handle refire separately so the secondary can be fired straight after a primary
        {
            if(weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR(shockwave, blast_animtime)))
            {
                W_Shockwave_Attack(thiswep, actor, weaponentity);
                actor.(weaponentity).shockwave_blasttime = time + WEP_CVAR(shockwave, blast_refire) * W_WeaponRateFactor(actor);
                weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR(shockwave, blast_animtime), w_ready);
            }
        }
    }
    else if(fire & 2)
    {
        //if(actor.clip_load >= 0) // we are not currently reloading
        if(weapon_prepareattack(thiswep, actor, weaponentity, true, WEP_CVAR(shockwave, melee_refire)))
        {
            // attempt forcing playback of the anim by switching to another anim (that we never play) here...
            weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, 0, W_Shockwave_Melee);
        }
    }
}
METHOD(Shockwave, wr_checkammo1, bool(entity thiswep, entity actor, .entity weaponentity))
{
    return true; // infinite ammo
}
METHOD(Shockwave, wr_checkammo2, bool(entity thiswep, entity actor, .entity weaponentity))
{
    // shockwave has infinite ammo
    return true;
}
METHOD(Shockwave, wr_suicidemessage, Notification(entity thiswep))
{
    return WEAPON_THINKING_WITH_PORTALS;
}
METHOD(Shockwave, wr_killmessage, Notification(entity thiswep))
{
    if(w_deathtype & HITTYPE_SECONDARY)
        return WEAPON_SHOCKWAVE_MURDER_SLAP;
    else
        return WEAPON_SHOCKWAVE_MURDER;
}

#endif
#ifdef CSQC
// WEAPONTODO: add client side settings for these
const float SW_MAXALPHA = 0.5;
const float SW_FADETIME = 0.4;
const float SW_DISTTOMIN = 200;
void Draw_Shockwave(entity this)
{
	// fading/removal control
	float a = bound(0, (SW_MAXALPHA - ((time - this.sw_time) / SW_FADETIME)), SW_MAXALPHA);
	if(a < ALPHA_MIN_VISIBLE) { delete(this); }

	// WEAPONTODO: save this only once when creating the entity
	vector sw_color = entcs_GetColor(this.sv_entnum - 1); // Team_ColorRGB(entcs_GetTeam(this.sv_entnum));

	// WEAPONTODO: trace to find what we actually hit
	vector endpos = (this.sw_shotorg + (this.sw_shotdir * this.sw_distance));

	vector _forward, right, up;
	VECTOR_VECTORS(this.sw_shotdir, _forward, right, up);

	// WEAPONTODO: combine and simplify these calculations
	vector min_end = ((this.sw_shotorg + (this.sw_shotdir * SW_DISTTOMIN)) + (up * this.sw_spread_min));
	vector max_end = (endpos + (up * this.sw_spread_max));
	float spread_to_min = vlen(normalize(min_end - this.sw_shotorg) - this.sw_shotdir);
	float spread_to_max = vlen(normalize(max_end - min_end) - this.sw_shotdir);

	vector first_min_end = '0 0 0', prev_min_end = '0 0 0', new_min_end = '0 0 0';
	vector first_max_end = '0 0 0', prev_max_end = '0 0 0', new_max_end = '0 0 0';
	float new_max_dist, new_min_dist;

	vector deviation, angle = '0 0 0';
	float counter, divisions = 20;
	for(counter = 0; counter < divisions; ++counter)
	{
		// perfect circle effect lines
		makevectors('0 360 0' * (0.75 + (counter - 0.5) / divisions));
		angle.y = v_forward.x;
		angle.z = v_forward.y;

		// first do the spread_to_min effect
		deviation = angle * spread_to_min;
		deviation = ((this.sw_shotdir + (right * deviation.y) + (up * deviation.z)));
		new_min_dist = SW_DISTTOMIN;
		new_min_end = (this.sw_shotorg + (deviation * new_min_dist));
		//te_lightning2(NULL, new_min_end, this.sw_shotorg);

		// then calculate spread_to_max effect
		deviation = angle * spread_to_max;
		deviation = ((this.sw_shotdir + (right * deviation.y) + (up * deviation.z)));
		new_max_dist = vlen(new_min_end - endpos);
		new_max_end = (new_min_end + (deviation * new_max_dist));
		//te_lightning2(NULL, new_end, prev_min_end);


		if(counter == 0)
		{
			first_min_end = new_min_end;
			first_max_end = new_max_end;
		}

		if(counter >= 1)
		{
			// draw from shot origin to min spread radius
			R_BeginPolygon("", DRAWFLAG_NORMAL, false);
			R_PolygonVertex(prev_min_end, '0 0 0', sw_color, a);
			R_PolygonVertex(new_min_end, '0 0 0', sw_color, a);
			R_PolygonVertex(this.sw_shotorg, '0 0 0', sw_color, a);
			R_EndPolygon();

			// draw from min spread radius to max spread radius
			R_BeginPolygon("", DRAWFLAG_NORMAL, false);
			R_PolygonVertex(new_min_end, '0 0 0', sw_color, a);
			R_PolygonVertex(prev_min_end, '0 0 0', sw_color, a);
			R_PolygonVertex(prev_max_end, '0 0 0', sw_color, a);
			R_PolygonVertex(new_max_end, '0 0 0', sw_color, a);
			R_EndPolygon();
		}

		prev_min_end = new_min_end;
		prev_max_end = new_max_end;

		// last division only
		if((counter + 1) == divisions)
		{
			// draw from shot origin to min spread radius
			R_BeginPolygon("", DRAWFLAG_NORMAL, false);
			R_PolygonVertex(prev_min_end, '0 0 0', sw_color, a);
			R_PolygonVertex(first_min_end, '0 0 0', sw_color, a);
			R_PolygonVertex(this.sw_shotorg, '0 0 0', sw_color, a);
			R_EndPolygon();

			// draw from min spread radius to max spread radius
			R_BeginPolygon("", DRAWFLAG_NORMAL, false);
			R_PolygonVertex(first_min_end, '0 0 0', sw_color, a);
			R_PolygonVertex(prev_min_end, '0 0 0', sw_color, a);
			R_PolygonVertex(prev_max_end, '0 0 0', sw_color, a);
			R_PolygonVertex(first_max_end, '0 0 0', sw_color, a);
			R_EndPolygon();
		}
	}
}

NET_HANDLE(TE_CSQC_SHOCKWAVEPARTICLE, bool isNew)
{
	Net_ReadShockwaveParticle();
	return true;
}

void Net_ReadShockwaveParticle()
{
	entity shockwave = new(shockwave_cone);
	shockwave.draw = Draw_Shockwave;
	IL_PUSH(g_drawables, shockwave);

	shockwave.sw_shotorg = ReadVector();
	shockwave.sw_shotdir = ReadVector();

	shockwave.sw_distance = ReadShort();
	shockwave.sw_spread_max = ReadByte();
	shockwave.sw_spread_min = ReadByte();

	shockwave.sv_entnum = ReadByte();

	shockwave.sw_time = time;
}

METHOD(Shockwave, wr_impacteffect, void(entity thiswep, entity actor))
{
    // handled by Net_ReadShockwaveParticle
    //vector org2;
    //org2 = w_org + w_backoff * 2;
    //pointparticles(EFFECT_BLASTER_IMPACT, org2, w_backoff * 1000, 1);
}

#endif
