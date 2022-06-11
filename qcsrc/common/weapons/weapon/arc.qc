#include "arc.qh"

#ifdef SVQC
#include <common/gamemodes/gamemode/onslaught/sv_generator.qh>
#include <common/gamemodes/gamemode/onslaught/sv_onslaught.qh>

bool W_Arc_Beam_Send(entity this, entity to, int sf)
{
	WriteHeader(MSG_ENTITY, ENT_CLIENT_ARC_BEAM);

	// Truncate information when this beam is displayed to the owner client
	// - The owner client has no use for beam start position or directions,
	//    it always figures this information out for itself with csqc code.
	// - Spectating the owner also truncates this information.
	float drawlocal = ((to == this.owner) || ((to.enemy == this.owner) && IS_SPEC(to)));
	if(drawlocal) { sf &= ~ARC_SF_LOCALMASK; }

	WriteByte(MSG_ENTITY, sf);
	WriteByte(MSG_ENTITY, weaponslot(this.weaponentity_fld));

	if(sf & ARC_SF_SETTINGS) // settings information
	{
		WriteShort(MSG_ENTITY, WEP_CVAR(arc, beam_degreespersegment));
		WriteShort(MSG_ENTITY, WEP_CVAR(arc, beam_distancepersegment));
		WriteShort(MSG_ENTITY, WEP_CVAR(arc, beam_maxangle));
		WriteCoord(MSG_ENTITY, WEP_CVAR(arc, beam_range));
		WriteShort(MSG_ENTITY, WEP_CVAR(arc, beam_returnspeed));
		WriteByte(MSG_ENTITY, WEP_CVAR(arc, beam_tightness) * 10);

		WriteByte(MSG_ENTITY, drawlocal);
		WriteByte(MSG_ENTITY, etof(this.owner));
	}
	if(sf & ARC_SF_START) // starting location
	{
		WriteVector(MSG_ENTITY, this.beam_start);
	}
	if(sf & ARC_SF_WANTDIR) // want/aim direction
	{
		WriteVector(MSG_ENTITY, this.beam_wantdir);
	}
	if(sf & ARC_SF_BEAMDIR) // beam direction
	{
		WriteAngleVector(MSG_ENTITY, this.beam_dir);
	}
	if(sf & ARC_SF_BEAMTYPE) // beam type
	{
		WriteByte(MSG_ENTITY, this.beam_type);
	}

	return true;
}

void Reset_ArcBeam(entity player, vector forward)
{
	for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	{
		.entity weaponentity = weaponentities[slot];
		if(!player.(weaponentity).arc_beam)
			continue;
		player.(weaponentity).arc_beam.beam_dir = forward;
		player.(weaponentity).arc_beam.beam_teleporttime = time;
	}
}

float Arc_GetHeat_Percent(entity player, .entity weaponentity)
{
	if ( WEP_CVAR(arc, overheat_max) <= 0 ||  WEP_CVAR(arc, overheat_max) <= 0 )
	{
		player.arc_overheat = 0;
		return 0;
	}

	if ( player.(weaponentity).arc_beam )
		return player.(weaponentity).arc_beam.beam_heat/WEP_CVAR(arc, overheat_max);

	if ( player.arc_overheat > time )
	{
		return (player.arc_overheat-time) / WEP_CVAR(arc, overheat_max)
			* player.arc_cooldown;
	}

	return 0;
}
void Arc_Player_SetHeat(entity player, .entity weaponentity)
{
	player.(weaponentity).arc_heat_percent = Arc_GetHeat_Percent(player, weaponentity);
	//dprint("Heat: ",ftos(player.arc_heat_percent*100),"%\n");
}

void W_Arc_Bolt_Explode(entity this, entity directhitentity)
{
	this.event_damage = func_null;
	RadiusDamage(this, this.realowner, WEP_CVAR(arc, bolt_damage), WEP_CVAR(arc, bolt_edgedamage), WEP_CVAR(arc, bolt_radius), NULL, NULL, WEP_CVAR(arc, bolt_force), this.projectiledeathtype, this.weaponentity_fld, directhitentity);

	delete(this);
}

void W_Arc_Bolt_Explode_use(entity this, entity actor, entity trigger)
{
	W_Arc_Bolt_Explode(this, trigger);
}

void W_Arc_Bolt_Damage(entity this, entity inflictor, entity attacker, float damage, int deathtype, .entity weaponentity, vector hitloc, vector force)
{
	if(GetResource(this, RES_HEALTH) <= 0)
		return;

	if(!W_CheckProjectileDamage(inflictor.realowner, this.realowner, deathtype, -1))
		return; // g_projectiles_damage says to halt

	TakeResource(this, RES_HEALTH, damage);
	this.angles = vectoangles(this.velocity);

	if(GetResource(this, RES_HEALTH) <= 0)
		W_PrepareExplosionByDamage(this, attacker, getthink(this));
}

void W_Arc_Bolt_Touch(entity this, entity toucher)
{
	PROJECTILE_TOUCH(this, toucher);
	if(this.cnt >= WEP_CVAR(arc, bolt_bounce_count) || !WEP_CVAR(arc, bolt_bounce_count) || toucher.takedamage == DAMAGE_AIM) {
		this.use(this, NULL, toucher);
	} else {
		this.cnt++;
		Send_Effect(EFFECT_BALL_SPARKS, this.origin, this.velocity, 1);
		this.angles = vectoangles(this.velocity);
		this.owner = NULL;
		this.projectiledeathtype |= HITTYPE_BOUNCE;
		if(WEP_CVAR(arc, bolt_bounce_explode))
			RadiusDamage(this, this.realowner, WEP_CVAR(arc, bolt_damage), WEP_CVAR(arc, bolt_edgedamage), WEP_CVAR(arc, bolt_radius), NULL, NULL, WEP_CVAR(arc, bolt_force), this.projectiledeathtype, this.weaponentity_fld, toucher);
		if(this.cnt == 1 && WEP_CVAR(arc, bolt_bounce_lifetime))
			this.nextthink = time + WEP_CVAR(arc, bolt_bounce_lifetime);
	}
}

void W_Arc_Attack_Bolt(Weapon thiswep, entity actor, .entity weaponentity, int fire)
{
	W_SetupShot(actor, weaponentity, false, 2, SND_ELECTRO_FIRE2, CH_WEAPON_A, WEP_CVAR(arc, bolt_damage), thiswep.m_id | HITTYPE_SECONDARY);

	W_MuzzleFlash(thiswep, actor, weaponentity, w_shotorg, w_shotdir);

	entity missile = new(missile);
	missile.owner = missile.realowner = actor;
	missile.bot_dodge = true;
	IL_PUSH(g_bot_dodge, missile);
	missile.bot_dodgerating = WEP_CVAR(arc, bolt_damage);

	missile.takedamage = DAMAGE_YES;
	SetResourceExplicit(missile, RES_HEALTH, WEP_CVAR(arc, bolt_health));
	missile.damageforcescale = WEP_CVAR(arc, bolt_damageforcescale);
	missile.event_damage = W_Arc_Bolt_Damage;
	missile.damagedbycontents = true;
	IL_PUSH(g_damagedbycontents, missile);

	settouch(missile, W_Arc_Bolt_Touch);
	missile.cnt = 0;
	missile.use = W_Arc_Bolt_Explode_use;
	setthink(missile, adaptor_think2use_hittype_splash);
	missile.nextthink = time + WEP_CVAR(arc, bolt_lifetime);
	PROJECTILE_MAKETRIGGER(missile);
	missile.projectiledeathtype = thiswep.m_id | HITTYPE_SECONDARY;
	missile.weaponentity_fld = weaponentity;
	setorigin(missile, w_shotorg);
	setsize(missile, '0 0 0', '0 0 0');

	set_movetype(missile, MOVETYPE_BOUNCEMISSILE);
	W_SetupProjVelocity_PRE(missile, arc, bolt_);

	missile.angles = vectoangles(missile.velocity);
	missile.flags = FL_PROJECTILE;
	IL_PUSH(g_projectiles, missile);
	missile.missile_flags = MIF_SPLASH;

	CSQCProjectile(missile, true, PROJECTILE_ARC_BOLT, true);

	MUTATOR_CALLHOOK(EditProjectile, actor, missile);

	actor.(weaponentity).misc_bulletcounter = actor.(weaponentity).misc_bulletcounter + 1;
	if(actor.(weaponentity).misc_bulletcounter == 0)
	{
		ATTACK_FINISHED(actor, weaponentity) = time + WEP_CVAR(arc, bolt_refire2) * W_WeaponRateFactor(actor);
		weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR(arc, bolt_refire), w_ready);
	}
	else
	{
		weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR(arc, bolt_refire), W_Arc_Attack_Bolt);
	}
}

void W_Arc_Beam_Think(entity this)
{
	.entity weaponentity = this.weaponentity_fld;
	entity own = this.owner;
	if(this != own.(weaponentity).arc_beam)
	{
		delete(this);
		return;
	}

	float burst = 0;
	if( (PHYS_INPUT_BUTTON_ATCK2(own) && !WEP_CVAR(arc, bolt)) || this.beam_bursting)
	{
		if(!this.beam_bursting)
			this.beam_bursting = true;
		burst = ARC_BT_BURSTMASK;
	}

	Weapon thiswep = WEP_ARC;

	// TODO: use standard weapon use checks here!
	if(!IS_PLAYER(own) || IS_DEAD(own) || STAT(FROZEN, own) || game_stopped || own.vehicle
		|| !weapon_prepareattack_check(thiswep, own, weaponentity, this.beam_bursting, -1)
		|| own.(weaponentity).m_switchweapon != WEP_ARC
		|| (!PHYS_INPUT_BUTTON_ATCK(own) && !burst)
		|| (WEP_CVAR(arc, overheat_max) > 0 && this.beam_heat >= WEP_CVAR(arc, overheat_max)) )
	{
		if ( WEP_CVAR(arc, cooldown) > 0 )
		{
			float cooldown_speed = 0;
			if ( this.beam_heat > WEP_CVAR(arc, overheat_min) && WEP_CVAR(arc, cooldown) > 0 )
			{
				cooldown_speed = WEP_CVAR(arc, cooldown);
			}
			else if ( !burst )
			{
				cooldown_speed = this.beam_heat / WEP_CVAR(arc, beam_refire);
			}

			bool overheat = (WEP_CVAR(arc, overheat_max) > 0 && this.beam_heat >= WEP_CVAR(arc, overheat_max));
			if (overheat)
			{
				Send_Effect(EFFECT_ARC_OVERHEAT, this.beam_start, this.beam_wantdir, 1);
				sound(this, CH_WEAPON_A, SND_ARC_STOP, VOL_BASE, ATTN_NORM);
			}

			if ( cooldown_speed )
			{
				if (WEP_CVAR(arc, cooldown_release) || overheat)
					own.arc_overheat = time + this.beam_heat / cooldown_speed;
				own.arc_cooldown = cooldown_speed;
			}

		}

		if(this == own.(weaponentity).arc_beam) { own.(weaponentity).arc_beam = NULL; }
		if(!thiswep.wr_checkammo1(thiswep, own, weaponentity) && !(own.items & IT_UNLIMITED_AMMO))
		{
			// note: this doesn't force the switch
			W_SwitchToOtherWeapon(own, weaponentity);
		}
		own.(weaponentity).arc_BUTTON_ATCK_prev = false; // allow switching weapons
		delete(this);
		return;
	}

	// decrease ammo
	float coefficient = frametime;
	if(!(own.items & IT_UNLIMITED_AMMO))
	{
		float rootammo;
		if(burst)
			{ rootammo = WEP_CVAR(arc, burst_ammo); }
		else
			{ rootammo = WEP_CVAR(arc, beam_ammo); }

		if(rootammo)
		{
			coefficient = min(coefficient, GetResource(own, thiswep.ammo_type) / rootammo);
			SetResource(own, thiswep.ammo_type, max(0, GetResource(own, thiswep.ammo_type) - (rootammo * frametime)));
		}
	}
	float heat_speed = burst ? WEP_CVAR(arc, burst_heat) : WEP_CVAR(arc, beam_heat);
	this.beam_heat = min( WEP_CVAR(arc, overheat_max), this.beam_heat + heat_speed*frametime );

	makevectors(own.v_angle);

	W_SetupShot_Range(
		own,
		weaponentity,
		true,
		0,
		SND_Null,
		0,
		WEP_CVAR(arc, beam_damage) * coefficient,
		WEP_CVAR(arc, beam_range),
		thiswep.m_id
	);

	// After teleport, "lock" the beam until the teleport is confirmed.
	if (time < this.beam_teleporttime + ANTILAG_LATENCY(own)) {
		w_shotdir = this.beam_dir;
	}

	// network information: shot origin and want/aim direction
	if(this.beam_start != w_shotorg)
	{
		this.SendFlags |= ARC_SF_START;
		this.beam_start = w_shotorg;
	}
	if(this.beam_wantdir != w_shotdir)
	{
		this.SendFlags |= ARC_SF_WANTDIR;
		this.beam_wantdir = w_shotdir;
	}

	if(!this.beam_initialized)
	{
		this.beam_dir = w_shotdir;
		this.beam_initialized = true;
	}

	// WEAPONTODO: Detect player velocity so that the beam curves when moving too
	// idea: blend together this.beam_dir with the inverted direction the player is moving in
	// might have to make some special accomodation so that it only uses view_right and view_up

	// note that if we do this, it'll always be corrected to a maximum angle by beam_maxangle handling

	float segments;
	if(this.beam_dir != w_shotdir)
	{
		// calculate how much we're going to move the end of the beam to the want position
		// WEAPONTODO (server and client):
		// blendfactor never actually becomes 0 in this situation, which is a problem
		// regarding precision... this means that this.beam_dir and w_shotdir approach
		// eachother, however they never actually become the same value with this method.
		// Perhaps we should do some form of rounding/snapping?
		float angle = vlen(w_shotdir - this.beam_dir) * RAD2DEG;
		if(angle && (angle > WEP_CVAR(arc, beam_maxangle)))
		{
			// if the angle is greater than maxangle, force the blendfactor to make this the maximum factor
			float blendfactor = bound(
				0,
				(1 - (WEP_CVAR(arc, beam_returnspeed) * frametime)),
				min(WEP_CVAR(arc, beam_maxangle) / angle, 1)
			);
			if(vdist(this.beam_dir - w_shotdir, <, 0.01))
				this.beam_dir = w_shotdir;
			else
				this.beam_dir = normalize((w_shotdir * (1 - blendfactor)) + (this.beam_dir * blendfactor));
		}
		else
		{
			// the radius is not too far yet, no worries :D
			float blendfactor = bound(
				0,
				(1 - (WEP_CVAR(arc, beam_returnspeed) * frametime)),
				1
			);
			if(vdist(this.beam_dir - w_shotdir, <, 0.01))
				this.beam_dir = w_shotdir;
			else
				this.beam_dir = normalize((w_shotdir * (1 - blendfactor)) + (this.beam_dir * blendfactor));
		}

		// network information: beam direction
		this.SendFlags |= ARC_SF_BEAMDIR;

		// calculate how many segments are needed
		float max_allowed_segments;

		if(WEP_CVAR(arc, beam_distancepersegment))
		{
			max_allowed_segments = min(
				ARC_MAX_SEGMENTS,
				1 + (vlen(w_shotdir / WEP_CVAR(arc, beam_distancepersegment)))
			);
		}
		else { max_allowed_segments = ARC_MAX_SEGMENTS; }

		if(WEP_CVAR(arc, beam_degreespersegment))
		{
			segments = bound(
				1,
				(
					min(
						angle,
						WEP_CVAR(arc, beam_maxangle)
					)
					/
					WEP_CVAR(arc, beam_degreespersegment)
				),
				max_allowed_segments
			);
		}
		else { segments = 1; }
	}
	else { segments = 1; }

	vector beam_endpos = (w_shotorg + (this.beam_dir * WEP_CVAR(arc, beam_range)));
	vector beam_controlpoint = w_shotorg + w_shotdir * (WEP_CVAR(arc, beam_range) * (1 - WEP_CVAR(arc, beam_tightness)));

	float i;
	float new_beam_type = 0;
	vector last_origin = w_shotorg;
	for(i = 1; i <= segments; ++i)
	{
		// WEAPONTODO (client):
		// In order to do nice fading and pointing on the starting segment, we must always
		// have that drawn as a separate triangle... However, that is difficult to do when
		// keeping in mind the above problems and also optimizing the amount of segments
		// drawn on screen at any given time. (Automatic beam quality scaling, essentially)

		vector new_origin = bezier_quadratic_getpoint(
			w_shotorg,
			beam_controlpoint,
			beam_endpos,
			i / segments);
		vector new_dir = normalize(new_origin - last_origin);

		WarpZone_traceline_antilag(
			own,
			last_origin,
			new_origin,
			MOVE_NORMAL,
			own,
			ANTILAG_LATENCY(own)
		);

		// Do all the transforms for warpzones right now, as we already
		// "are" in the post-trace system (if we hit a player, that's
		// always BEHIND the last passed wz).
		last_origin = trace_endpos;
		w_shotorg = WarpZone_TransformOrigin(WarpZone_trace_transform, w_shotorg);
		beam_controlpoint = WarpZone_TransformOrigin(WarpZone_trace_transform, beam_controlpoint);
		beam_endpos = WarpZone_TransformOrigin(WarpZone_trace_transform, beam_endpos);
		new_dir = WarpZone_TransformVelocity(WarpZone_trace_transform, new_dir);

		if(trace_ent)
		{
			bool is_player = (IS_PLAYER(trace_ent) || trace_ent.classname == "body" || IS_MONSTER(trace_ent));
			if(SAME_TEAM(own, trace_ent))
			{
				float roothealth = ((burst) ? WEP_CVAR(arc, burst_healing_hps) : WEP_CVAR(arc, beam_healing_hps));
				float rootarmor = ((burst) ? WEP_CVAR(arc, burst_healing_aps) : WEP_CVAR(arc, beam_healing_aps));
				float hplimit = ((IS_PLAYER(trace_ent)) ? WEP_CVAR(arc, beam_healing_hmax) : RES_LIMIT_NONE);
				Heal(trace_ent, own, (roothealth * coefficient), hplimit);
				if(IS_PLAYER(trace_ent) && rootarmor)
				{
					if(GetResource(trace_ent, RES_ARMOR) <= WEP_CVAR(arc, beam_healing_amax))
					{
						GiveResourceWithLimit(trace_ent, RES_ARMOR, (rootarmor * coefficient), WEP_CVAR(arc, beam_healing_amax));
						trace_ent.pauserotarmor_finished = max(
							trace_ent.pauserotarmor_finished,
							time + autocvar_g_balance_pause_armor_rot
						);
					}
				}
				if(roothealth || rootarmor)
					new_beam_type = ARC_BT_HEAL;
			}
			else if(trace_ent.takedamage && (is_player || WEP_CVAR(arc, beam_nonplayerdamage)))
			{
				// calculate our own hit origin as trace_endpos tends to jump around annoyingly (to player origin?)
				// NO. trace_endpos should be just fine. If not,
				// that's an engine bug that needs proper debugging.
				vector hitorigin = trace_endpos;

				float falloff = ExponentialFalloff(
					WEP_CVAR(arc, beam_falloff_mindist),
					WEP_CVAR(arc, beam_falloff_maxdist),
					WEP_CVAR(arc, beam_falloff_halflifedist),
					vlen(WarpZone_UnTransformOrigin(WarpZone_trace_transform, hitorigin) - w_shotorg)
				);

				float rootdamage;
				if(is_player)
				{
					if(burst)
						{ rootdamage = WEP_CVAR(arc, burst_damage); }
					else
						{ rootdamage = WEP_CVAR(arc, beam_damage); }
				}
				else
					{ rootdamage = WEP_CVAR(arc, beam_nonplayerdamage); }

				if(accuracy_isgooddamage(own, trace_ent))
				{
					accuracy_add(
						own,
						WEP_ARC,
						0,
						rootdamage * coefficient * falloff
					);
				}

				Damage(
					trace_ent,
					own,
					own,
					rootdamage * coefficient * falloff,
					WEP_ARC.m_id,
					weaponentity,
					hitorigin,
					WEP_CVAR(arc, beam_force) * new_dir * coefficient * falloff
				);

				new_beam_type = ARC_BT_HIT;
			}
			break;
		}
		else if(trace_fraction != 1)
		{
			// we collided with geometry
			new_beam_type = ARC_BT_WALL;
			break;
		}
	}

	// te_explosion(trace_endpos);

	// if we're bursting, use burst visual effects
	new_beam_type |= burst;

	// network information: beam type
	if(new_beam_type != this.beam_type)
	{
		this.SendFlags |= ARC_SF_BEAMTYPE;
		this.beam_type = new_beam_type;
	}

	own.(weaponentity).beam_prev = time;
	this.nextthink = time;
}

void W_Arc_Beam(float burst, entity actor, .entity weaponentity)
{

	// only play fire sound if 1 sec has passed since player let go the fire button
	if(time - actor.(weaponentity).beam_prev > 1)
		sound(actor, CH_WEAPON_A, SND_ARC_FIRE, VOL_BASE, ATTN_NORM);

	entity beam = actor.(weaponentity).arc_beam = new(W_Arc_Beam);
	beam.weaponentity_fld = weaponentity;
	beam.solid = SOLID_NOT;
	setthink(beam, W_Arc_Beam_Think);
	beam.owner = actor;
	set_movetype(beam, MOVETYPE_NONE);
	beam.bot_dodge = true;
	IL_PUSH(g_bot_dodge, beam);
	beam.bot_dodgerating = WEP_CVAR(arc, beam_damage);
	beam.beam_bursting = burst;
	Net_LinkEntity(beam, false, 0, W_Arc_Beam_Send);

	getthink(beam)(beam);
}
void W_Arc_Attack(Weapon thiswep, entity actor, .entity weaponentity, int fire)
{
	if(!actor.(weaponentity).arc_beam || wasfreed(actor.(weaponentity).arc_beam))
	{
		w_ready(thiswep, actor, weaponentity, fire);
		return;
	}

	// attack handled by the beam itself, this is just a loop to keep the attack happening!

	// NOTE: arc doesn't use a refire
	//ATTACK_FINISHED(actor, weaponentity) = time + WEP_CVAR_PRI(arc, refire) * W_WeaponRateFactor(actor);
	actor.(weaponentity).wframe = WFRAME_FIRE1;
	weapon_thinkf(actor, weaponentity, WFRAME_DONTCHANGE, WEP_CVAR(arc, beam_animtime), W_Arc_Attack);
}
void Arc_Smoke(Weapon thiswep, entity actor, .entity weaponentity, int fire)
{
	// calculate a rough shot origin to show the effect from TODO: move this to the client side!
	makevectors(actor.v_angle);
	w_shotdir = v_forward;
	vector md = actor.(weaponentity).movedir;
	vector vecs = ((md.x > 0) ? md : '0 0 0');
	vector dv = v_forward * vecs.x + v_right * -vecs.y + v_up * vecs.z;
	w_shotorg = actor.origin + actor.view_ofs + dv;
	//W_SetupShot_Range(actor,weaponentity,false,0,SND_Null,0,0,0,thiswep.m_id);

	vector smoke_origin = w_shotorg + actor.velocity*frametime;
	if ( actor.arc_overheat > time )
	{
		if ( random() < actor.(weaponentity).arc_heat_percent )
			Send_Effect(EFFECT_ARC_SMOKE, smoke_origin, '0 0 0', 1 );
		if ( (fire & 1) || (fire & 2) )
		{
			Send_Effect(EFFECT_ARC_OVERHEAT_FIRE, smoke_origin, w_shotdir, 1 );
			if ( !actor.arc_smoke_sound )
			{
				actor.arc_smoke_sound = 1;
				sound(actor, CH_SHOTS_SINGLE, SND_ARC_LOOP_OVERHEAT, VOL_BASE, ATTN_NORM);
			}
		}
	}
	else if ( actor.(weaponentity).arc_beam && WEP_CVAR(arc, overheat_max) > 0 &&
			actor.(weaponentity).arc_beam.beam_heat > WEP_CVAR(arc, overheat_min) )
	{
		if ( random() < (actor.(weaponentity).arc_beam.beam_heat-WEP_CVAR(arc, overheat_min)) /
				( WEP_CVAR(arc, overheat_max)-WEP_CVAR(arc, overheat_min) ) )
			Send_Effect(EFFECT_ARC_SMOKE, smoke_origin, '0 0 0', 1 );
	}

	bool attacking = PHYS_INPUT_BUTTON_ATCK(actor) || PHYS_INPUT_BUTTON_ATCK2(actor);
	bool stop_smoke_sound = actor.arc_overheat <= time || !attacking;
	if ((actor.arc_smoke_sound && stop_smoke_sound) || actor.(weaponentity).m_switchweapon != thiswep)
	{
		actor.arc_smoke_sound = 0;
		sound(actor, CH_SHOTS_SINGLE, SND_Null, VOL_BASE, ATTEN_NORM);
	}
}

METHOD(Arc, wr_aim, void(entity thiswep, entity actor, .entity weaponentity))
{
    if(WEP_CVAR(arc, beam_botaimspeed))
    {
        PHYS_INPUT_BUTTON_ATCK(actor) = bot_aim(
        	actor,
        	weaponentity,
            WEP_CVAR(arc, beam_botaimspeed),
            0,
            WEP_CVAR(arc, beam_botaimlifetime),
            false
        );
    }
    else
    {
        PHYS_INPUT_BUTTON_ATCK(actor) = bot_aim(
        	actor,
        	weaponentity,
            1000000,
            0,
            0.001,
            false
        );
    }
}
METHOD(Arc, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
{
    Arc_Player_SetHeat(actor, weaponentity);
    Arc_Smoke(thiswep, actor, weaponentity, fire);

    bool beam_fire2 = ((fire & 2) && !WEP_CVAR(arc, bolt));

    if (time >= actor.arc_overheat)
    if ((fire & 1) || beam_fire2 || actor.(weaponentity).arc_beam.beam_bursting)
    {
    	#if 0
        if(actor.(weaponentity).arc_BUTTON_ATCK_prev)
        {
            #if 0
            if(actor.animstate_startframe == actor.anim_shoot.x && actor.animstate_numframes == actor.anim_shoot.y)
                weapon_thinkf(actor, weaponentity, WFRAME_DONTCHANGE, autocvar_g_balance_arc_primary_animtime, w_ready);
            else
            #endif
                weapon_thinkf(actor, weaponentity, WFRAME_DONTCHANGE, WEP_CVAR(arc, beam_animtime), w_ready);
        }
        #endif

        if((!actor.(weaponentity).arc_beam) || wasfreed(actor.(weaponentity).arc_beam))
        {
            if(weapon_prepareattack(thiswep, actor, weaponentity, boolean(beam_fire2), 0))
            {
                W_Arc_Beam(boolean(beam_fire2), actor, weaponentity);

                if(!actor.(weaponentity).arc_BUTTON_ATCK_prev)
                {
                	actor.(weaponentity).wframe = WFRAME_FIRE1;
                    weapon_thinkf(actor, weaponentity, WFRAME_DONTCHANGE, WEP_CVAR(arc, beam_animtime), W_Arc_Attack);
                    actor.(weaponentity).arc_BUTTON_ATCK_prev = true;
                }
            }
        }

        return;
    }
    else if(fire & 2)
    {
        if(weapon_prepareattack(thiswep, actor, weaponentity, true, 0))
        {
            if(!thiswep.wr_checkammo2(thiswep, actor, weaponentity))
            if(!(actor.items & IT_UNLIMITED_AMMO))
            {
                W_SwitchWeapon_Force(actor, w_getbestweapon(actor, weaponentity), weaponentity);
                w_ready(thiswep, actor, weaponentity, fire);
                return;
            }
            float ammo_available = GetResource(actor, thiswep.ammo_type);
            // We don't want to shoot 3 rounds if there's 2 left in the mag, so we'll use a fraction.
            // Also keep the fraction <= 1 otherwise we'd mag dump in one burst.
            float burst_fraction = min(1, ammo_available / WEP_CVAR(arc, bolt_ammo));
            int to_shoot = floor(WEP_CVAR(arc, bolt_count) * burst_fraction);

            // We also don't want to use 3 rounds if there's only 2 left.
            int to_use = min(WEP_CVAR(arc, bolt_ammo), ammo_available);
            W_DecreaseAmmo(thiswep, actor, to_use, weaponentity);

            // Bursting counts up to 0 from a negative.
            actor.(weaponentity).misc_bulletcounter = -to_shoot;
            W_Arc_Attack_Bolt(thiswep, actor, weaponentity, fire);
        }
    }

    if(actor.(weaponentity).arc_BUTTON_ATCK_prev)
    {
        sound(actor, CH_WEAPON_A, SND_ARC_STOP, VOL_BASE, ATTN_NORM);
        weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR(arc, beam_animtime), w_ready);
        ATTACK_FINISHED(actor, weaponentity) = time + WEP_CVAR(arc, beam_refire) * W_WeaponRateFactor(actor);
    }
    actor.(weaponentity).arc_BUTTON_ATCK_prev = false;

    #if 0
    if(fire & 2)
    if(weapon_prepareattack(thiswep, actor, weaponentity, true, autocvar_g_balance_arc_secondary_refire))
    {
        W_Arc_Attack2();
        actor.arc_count = autocvar_g_balance_arc_secondary_count;
        weapon_thinkf(actor, weaponentity, WFRAME_FIRE2, autocvar_g_balance_arc_secondary_animtime, w_arc_checkattack);
        actor.arc_secondarytime = time + autocvar_g_balance_arc_secondary_refire2 * W_WeaponRateFactor(actor);
    }
    #endif
}
METHOD(Arc, wr_init, void(entity thiswep))
{
    if(!arc_shotorigin[0])
    {
        arc_shotorigin[0] = shotorg_adjust_values(CL_Weapon_GetShotOrg(WEP_ARC.m_id), false, false, 1);
        arc_shotorigin[1] = shotorg_adjust_values(CL_Weapon_GetShotOrg(WEP_ARC.m_id), false, false, 2);
        arc_shotorigin[2] = shotorg_adjust_values(CL_Weapon_GetShotOrg(WEP_ARC.m_id), false, false, 3);
        arc_shotorigin[3] = shotorg_adjust_values(CL_Weapon_GetShotOrg(WEP_ARC.m_id), false, false, 4);
    }
}
METHOD(Arc, wr_checkammo1, bool(entity thiswep, entity actor, .entity weaponentity))
{
    return ((!WEP_CVAR(arc, beam_ammo)) || (GetResource(actor, thiswep.ammo_type) > 0));
}
METHOD(Arc, wr_checkammo2, bool(entity thiswep, entity actor, .entity weaponentity))
{
    if(WEP_CVAR(arc, bolt))
    {
        float ammo_amount = GetResource(actor, thiswep.ammo_type) >= WEP_CVAR(arc, bolt_ammo);
        ammo_amount += actor.(weaponentity).(weapon_load[WEP_ARC.m_id]) >= WEP_CVAR(arc, bolt_ammo);
        return ammo_amount;
    }
    else
        return WEP_CVAR(arc, overheat_max) > 0 &&
            ((!WEP_CVAR(arc, burst_ammo)) || (GetResource(actor, thiswep.ammo_type) > 0));
}
METHOD(Arc, wr_killmessage, Notification(entity thiswep))
{
    if(w_deathtype & HITTYPE_SECONDARY)
        return WEAPON_ARC_MURDER_SPRAY;
    else
        return WEAPON_ARC_MURDER;
}
METHOD(Arc, wr_drop, void(entity thiswep, entity actor, .entity weaponentity))
{
    weapon_dropevent_item.arc_overheat = actor.arc_overheat;
    weapon_dropevent_item.arc_cooldown = actor.arc_cooldown;
    actor.arc_overheat = 0;
    actor.arc_cooldown = 0;
    actor.(weaponentity).arc_BUTTON_ATCK_prev = false;
}
METHOD(Arc, wr_pickup, void(entity thiswep, entity actor, .entity weaponentity))
{
    if ( !client_hasweapon(actor, thiswep, weaponentity, false, false) &&
        weapon_dropevent_item.arc_overheat > time )
    {
        actor.arc_overheat = weapon_dropevent_item.arc_overheat;
        actor.arc_cooldown = weapon_dropevent_item.arc_cooldown;
    }
}
METHOD(Arc, wr_resetplayer, void(entity thiswep, entity actor))
{
    actor.arc_overheat = 0;
    actor.arc_cooldown = 0;
    for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
    {
    	.entity weaponentity = weaponentities[slot];
    	actor.(weaponentity).arc_BUTTON_ATCK_prev = false;
    }
}
METHOD(Arc, wr_playerdeath, void(entity thiswep, entity actor, .entity weaponentity))
{
    actor.arc_overheat = 0;
    actor.arc_cooldown = 0;
    actor.(weaponentity).arc_BUTTON_ATCK_prev = false;
}
#endif
#ifdef CSQC
bool autocvar_cl_arcbeam_teamcolor = true;
bool autocvar_cl_arcbeam_simple = true;

.int beam_slot;

METHOD(Arc, wr_impacteffect, void(entity thiswep, entity actor))
{
    if(w_deathtype & HITTYPE_SECONDARY)
    {
        vector org2;
        org2 = w_org + w_backoff * 6;
        pointparticles(EFFECT_ELECTRO_IMPACT, org2, w_backoff * 1000, 1);
        if(!w_issilent) { sound(actor, CH_SHOTS, SND_ELECTRO_IMPACT, VOL_BASE, ATTN_NORM); }
    }
}

void Draw_ArcBeam_callback(vector start, vector hit, vector end)
{
	entity beam = Draw_ArcBeam_callback_entity;
	vector transformed_view_org;
	transformed_view_org = WarpZone_TransformOrigin(WarpZone_trace_transform, view_origin);

	// Thickdir shall be perpendicular to the beam and to the view-to-beam direction (WEAPONTODO: WHY)
	// WEAPONTODO: Wouldn't it be better to be perpendicular to the beam and to the view FORWARD direction?
	vector thickdir = normalize(cross(normalize(start - hit), transformed_view_org - start));

	vector hitorigin;

	// draw segment
	#if 0
	if(trace_fraction != 1)
	{
		// calculate our own hit origin as trace_endpos tends to jump around annoyingly (to player origin?)
		hitorigin = start + (Draw_ArcBeam_callback_new_dir * Draw_ArcBeam_callback_segmentdist * trace_fraction);
		hitorigin = WarpZone_TransformOrigin(WarpZone_trace_transform, hitorigin);
	}
	else
	{
		hitorigin = hit;
	}
	#else
	hitorigin = hit;
	#endif

	// decide upon thickness
	float thickness = beam.beam_thickness;

	// draw primary beam render
	vector top    = hitorigin + (thickdir * thickness);
	vector bottom = hitorigin - (thickdir * thickness);

	vector last_top = WarpZone_TransformOrigin(WarpZone_trace_transform, Draw_ArcBeam_callback_last_top);
	vector last_bottom = WarpZone_TransformOrigin(WarpZone_trace_transform, Draw_ArcBeam_callback_last_bottom);

	if(autocvar_cl_arcbeam_simple)
		Draw_CylindricLine(start, end, thickness, beam.beam_image, 0.25, -time * 3, beam.beam_color, beam.beam_alpha, DRAWFLAG_NORMAL, transformed_view_org);
	else
	{
		R_BeginPolygon(beam.beam_image, DRAWFLAG_NORMAL, false); // DRAWFLAG_ADDITIVE
		R_PolygonVertex(
			top,
			'0 0.5 0' + ('0 0.5 0' * (thickness / beam.beam_thickness)),
			beam.beam_color,
			beam.beam_alpha
		);
		R_PolygonVertex(
			last_top,
			'0 0.5 0' + ('0 0.5 0' * (Draw_ArcBeam_callback_last_thickness / beam.beam_thickness)),
			beam.beam_color,
			beam.beam_alpha
		);
		R_PolygonVertex(
			last_bottom,
			'0 0.5 0' * (1 - (Draw_ArcBeam_callback_last_thickness / beam.beam_thickness)),
			beam.beam_color,
			beam.beam_alpha
		);
		R_PolygonVertex(
			bottom,
			'0 0.5 0' * (1 - (thickness / beam.beam_thickness)),
			beam.beam_color,
			beam.beam_alpha
		);
		R_EndPolygon();
	}

	// draw trailing particles
	// NOTES:
	//  - Don't use spammy particle counts here, use a FEW small particles around the beam
	//  - We're not using WarpZone_TrailParticles here because we will handle warpzones ourselves.
	if(beam.beam_traileffect)
	{
		trailparticles(beam, beam.beam_traileffect, start, hitorigin);
	}

	// set up for the next
	Draw_ArcBeam_callback_last_thickness = thickness;
	Draw_ArcBeam_callback_last_top = WarpZone_UnTransformOrigin(WarpZone_trace_transform, top);
	Draw_ArcBeam_callback_last_bottom = WarpZone_UnTransformOrigin(WarpZone_trace_transform, bottom);
}

void Reset_ArcBeam()
{
	entity e;
	for (e = NULL; (e = findfloat(e, beam_usevieworigin, 1)); ) {
		e.beam_initialized = false;
	}
	for (e = NULL; (e = findfloat(e, beam_usevieworigin, 2)); ) {
		e.beam_initialized = false;
	}
}

void Draw_ArcBeam(entity this)
{
	float dt = time - this.move_time;
	this.move_time = time;
	if(dt <= 0) { return; }

	if(!this.beam_usevieworigin)
	{
		InterpolateOrigin_Do(this);
	}

	// origin = beam starting origin
	// v_angle = wanted/aim direction
	// angles = current direction of beam

	vector start_pos;
	vector wantdir; //= view_forward;
	vector beamdir; //= this.beam_dir;

	float segments;
	if(this.beam_usevieworigin)
	{
		// WEAPONTODO:
		// Currently we have to replicate nearly the same method of figuring
		// out the shotdir that the server does... Ideally in the future we
		// should be able to acquire this from a generalized function built
		// into a weapon system for client code.

		// find where we are aiming
		vector myviewangle = view_angles;
		if (autocvar_chase_active)
		{
			if (autocvar_cl_lockview)
				myviewangle = eX * csqcplayer.v_angle.x + eY * csqcplayer.angles.y;
			else
				myviewangle = warpzone_save_view_angles;
		}
		vector forward, right, up;
		MAKE_VECTORS(myviewangle, forward, right, up);
		entity wepent = viewmodels[this.beam_slot];

		this.beam_usevieworigin = (autocvar_chase_active) ? 1 : 2;

		// decide upon start position
		if(this.beam_usevieworigin == 2)
			{ start_pos = warpzone_save_view_origin; }
		else if(csqcplayer)
			{ start_pos = csqcplayer.origin + csqcplayer.view_ofs; }
		else
			{ start_pos = this.origin; }

		// trace forward with an estimation
		WarpZone_TraceLine(
			start_pos,
			start_pos + forward * this.beam_range,
			MOVE_NOMONSTERS,
			this
		);

		int v_shot_idx;  // used later
		(v_shot_idx = gettagindex(wepent, "shot")) || (v_shot_idx = gettagindex(wepent, "tag_shot"));
		if(v_shot_idx && this.beam_usevieworigin == 2)
			start_pos = gettaginfo(wepent, v_shot_idx) - '0 0 2';

		// untransform in case our trace went through a warpzone
		vector end_pos = WarpZone_UnTransformOrigin(WarpZone_trace_transform, trace_endpos);

		// un-adjust trueaim if shotend is too close
		if(vdist(end_pos - start_pos, <, g_trueaim_minrange))
			end_pos = start_pos + (forward * g_trueaim_minrange);

		// move shot origin to the actual gun muzzle origin
		vector origin_offset = '0 0 0';
		if(!v_shot_idx || this.beam_usevieworigin != 2)
		{
			this.beam_shotorigin = wepent.movedir;
			origin_offset = right * -this.beam_shotorigin.y + up * this.beam_shotorigin.z;
		}
		else
			this.beam_shotorigin = '0 0 0';

		start_pos = start_pos + origin_offset;

		// Move it also forward, but only as far as possible without hitting anything. Don't poke into walls!
		traceline(start_pos, start_pos + forward * this.beam_shotorigin.x, MOVE_NORMAL, this);
		start_pos = trace_endpos;

		// calculate the aim direction now
		wantdir = normalize(end_pos - start_pos);

		if(!this.beam_initialized)
		{
			this.beam_dir = wantdir;
			this.beam_initialized = true;

			this.beam_muzzleentity.drawmask = MASK_NORMAL; // NOTE: this works around the muzzle entity flashing on the middle of the screen for a frame
		}

		if(this.beam_dir != wantdir)
		{
			// calculate how much we're going to move the end of the beam to the want position
			// WEAPONTODO (server and client):
			// blendfactor never actually becomes 0 in this situation, which is a problem
			// regarding precision... this means that this.beam_dir and w_shotdir approach
			// eachother, however they never actually become the same value with this method.
			// Perhaps we should do some form of rounding/snapping?
			float angle = vlen(wantdir - this.beam_dir) * RAD2DEG;
			if(angle && (angle > this.beam_maxangle))
			{
				// if the angle is greater than maxangle, force the blendfactor to make this the maximum factor
				float blendfactor = bound(
					0,
					(1 - (this.beam_returnspeed * dt)),
					min(this.beam_maxangle / angle, 1)
				);
				this.beam_dir = normalize((wantdir * (1 - blendfactor)) + (this.beam_dir * blendfactor));
			}
			else
			{
				// the radius is not too far yet, no worries :D
				float blendfactor = bound(
					0,
					(1 - (this.beam_returnspeed * dt)),
					1
				);
				this.beam_dir = normalize((wantdir * (1 - blendfactor)) + (this.beam_dir * blendfactor));
			}

			// calculate how many segments are needed
			float max_allowed_segments;

			if(this.beam_distancepersegment)
			{
				max_allowed_segments = min(
					ARC_MAX_SEGMENTS,
					1 + (vlen(wantdir / this.beam_distancepersegment))
				);
			}
			else { max_allowed_segments = ARC_MAX_SEGMENTS; }

			if(this.beam_degreespersegment)
			{
				segments = bound(
					1,
					(
						min(
							angle,
							this.beam_maxangle
						)
						/
						this.beam_degreespersegment
					),
					max_allowed_segments
				);
			}
			else { segments = 1; }
		}
		else { segments = 1; }

		// set the beam direction which the rest of the code will refer to
		beamdir = this.beam_dir;

		// finally, set this.angles to the proper direction so that muzzle attachment points in proper direction
		this.angles = fixedvectoangles2(forward, up); // TODO(Samual): is this == warpzone_save_view_angles?
	}
	else
	{
		// set the values from the provided info from the networked entity
		start_pos = this.origin;
		wantdir = this.v_angle;
		beamdir = this.angles;

		if(beamdir != wantdir)
		{
			float angle = vlen(wantdir - beamdir) * RAD2DEG;

			// calculate how many segments are needed
			float max_allowed_segments;

			if(this.beam_distancepersegment)
			{
				max_allowed_segments = min(
					ARC_MAX_SEGMENTS,
					1 + (vlen(wantdir / this.beam_distancepersegment))
				);
			}
			else { max_allowed_segments = ARC_MAX_SEGMENTS; }

			if(this.beam_degreespersegment)
			{
				segments = bound(
					1,
					(
						min(
							angle,
							this.beam_maxangle
						)
						/
						this.beam_degreespersegment
					),
					max_allowed_segments
				);
			}
			else { segments = 1; }
		}
		else { segments = 1; }
	}

	setorigin(this, start_pos);
	this.beam_muzzleentity.angles_z = random() * 360; // WEAPONTODO: use avelocity instead?

	vector beam_endpos = (start_pos + (beamdir * this.beam_range));
	vector beam_controlpoint = start_pos + wantdir * (this.beam_range * (1 - this.beam_tightness));

	Draw_ArcBeam_callback_entity = this;
	Draw_ArcBeam_callback_last_thickness = 0;
	Draw_ArcBeam_callback_last_top = start_pos;
	Draw_ArcBeam_callback_last_bottom = start_pos;

	vector last_origin = start_pos;
	vector original_start_pos = start_pos;

	float i;
	for(i = 1; i <= segments; ++i)
	{
		// WEAPONTODO (client):
		// In order to do nice fading and pointing on the starting segment, we must always
		// have that drawn as a separate triangle... However, that is difficult to do when
		// keeping in mind the above problems and also optimizing the amount of segments
		// drawn on screen at any given time. (Automatic beam quality scaling, essentially)

		vector new_origin = bezier_quadratic_getpoint(
			start_pos,
			beam_controlpoint,
			beam_endpos,
			i / segments);

		WarpZone_TraceBox_ThroughZone(
			last_origin,
			'0 0 0',
			'0 0 0',
			new_origin,
			MOVE_NORMAL,
			NULL,
			NULL,
			Draw_ArcBeam_callback
		);

		// Do all the transforms for warpzones right now, as we already "are" in the post-trace
		// system (if we hit a player, that's always BEHIND the last passed wz).
		last_origin = trace_endpos;
		start_pos = WarpZone_TransformOrigin(WarpZone_trace_transform, start_pos);
		beam_controlpoint = WarpZone_TransformOrigin(WarpZone_trace_transform, beam_controlpoint);
		beam_endpos = WarpZone_TransformOrigin(WarpZone_trace_transform, beam_endpos);
		beamdir = WarpZone_TransformVelocity(WarpZone_trace_transform, beamdir);
		Draw_ArcBeam_callback_last_top = WarpZone_TransformOrigin(WarpZone_trace_transform, Draw_ArcBeam_callback_last_top);
		Draw_ArcBeam_callback_last_bottom = WarpZone_TransformOrigin(WarpZone_trace_transform, Draw_ArcBeam_callback_last_bottom);

		if(trace_fraction < 1) { break; }
	}

	// visual effects for startpoint and endpoint
	if(this.beam_hiteffect)
	{
		// FIXME we really should do this on the server so it actually
		// matches gameplay. What this client side stuff is doing is no
		// more than guesswork.
		if((trace_ent || trace_fraction < 1) && !(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT))
		pointparticles(
			this.beam_hiteffect,
			last_origin,
			beamdir * -1,
			dt * 2
		);
	}
	if(this.beam_hitlight[0])
	{
		adddynamiclight(
			last_origin,
			this.beam_hitlight[0],
			vec3(
				this.beam_hitlight[1],
				this.beam_hitlight[2],
				this.beam_hitlight[3]
			)
		);
	}
	if(this.beam_muzzleeffect && autocvar_r_drawviewmodel)
	{
		pointparticles(
			this.beam_muzzleeffect,
			original_start_pos + wantdir * 20,
			wantdir * 1000,
			dt * 0.1
		);
	}
	if(this.beam_muzzlelight[0])
	{
		adddynamiclight(
			original_start_pos + wantdir * 20,
			this.beam_muzzlelight[0],
			vec3(
				this.beam_muzzlelight[1],
				this.beam_muzzlelight[2],
				this.beam_muzzlelight[3]
			)
		);
	}

	// cleanup
	Draw_ArcBeam_callback_entity = NULL;
	Draw_ArcBeam_callback_last_thickness = 0;
	Draw_ArcBeam_callback_last_top = '0 0 0';
	Draw_ArcBeam_callback_last_bottom = '0 0 0';
}

void Remove_ArcBeam(entity this)
{
	delete(this.beam_muzzleentity);
	sound(this, CH_SHOTS_SINGLE, SND_Null, VOL_BASE, ATTEN_NORM);
}

NET_HANDLE(ENT_CLIENT_ARC_BEAM, bool isnew)
{
	int sf = ReadByte();
	int slot = ReadByte();
	entity flash;

	this.beam_slot = slot;

	if(isnew)
	{
		int gunalign = W_GunAlign(viewmodels[slot], STAT(GUNALIGN)) - 1;

		this.beam_shotorigin = arc_shotorigin[gunalign]; // get a starting point

		// set other main attributes of the beam
		this.draw = Draw_ArcBeam;
		IL_PUSH(g_drawables, this);
		this.entremove = Remove_ArcBeam;
		this.move_time = time;
		loopsound(this, CH_SHOTS_SINGLE, SND_ARC_LOOP, VOL_BASE, ATTEN_NORM);

		flash = new(arc_flash);
		flash.owner = this;
		flash.effects = EF_ADDITIVE | EF_FULLBRIGHT;
		//flash.drawmask = MASK_NORMAL;
		flash.solid = SOLID_NOT;
		flash.avelocity_z = 5000;
		setattachment(flash, this, "");
		setorigin(flash, '0 0 0');

		this.beam_muzzleentity = flash;
	}
	else
	{
		flash = this.beam_muzzleentity;
	}

	if(sf & ARC_SF_SETTINGS) // settings information
	{
		this.beam_degreespersegment = ReadShort();
		this.beam_distancepersegment = ReadShort();
		this.beam_maxangle = ReadShort();
		this.beam_range = ReadCoord();
		this.beam_returnspeed = ReadShort();
		this.beam_tightness = (ReadByte() / 10);

		if(ReadByte())
		{
			this.beam_usevieworigin = (autocvar_chase_active) ? 1 : 2;
		}
		else
		{
			this.beam_usevieworigin = 0;
		}

		this.sv_entnum = ReadByte();
	}

	if(!this.beam_usevieworigin)
	{
		// this.iflags = IFLAG_ORIGIN | IFLAG_ANGLES | IFLAG_V_ANGLE; // why doesn't this work?
		this.iflags = IFLAG_ORIGIN;

		InterpolateOrigin_Undo(this);
	}

	if(sf & ARC_SF_START) // starting location
	{
		this.origin = ReadVector();
	}
	else if(this.beam_usevieworigin) // infer the location from player location
	{
		if(this.beam_usevieworigin == 2)
		{
			// use view origin
			this.origin = view_origin;
		}
		else
		{
			// use player origin so that third person display still works
			this.origin = entcs_receiver(player_localnum).origin + ('0 0 1' * STAT(VIEWHEIGHT));
		}
	}

	setorigin(this, this.origin);

	if(sf & ARC_SF_WANTDIR) // want/aim direction
	{
		this.v_angle = ReadVector();
	}

	if(sf & ARC_SF_BEAMDIR) // beam direction
	{
		this.angles = ReadAngleVector();
	}

	if(sf & ARC_SF_BEAMTYPE) // beam type
	{
		this.beam_type = ReadByte();

		vector beamcolor = ((autocvar_cl_arcbeam_teamcolor) ? colormapPaletteColor(entcs_GetClientColors(this.sv_entnum - 1) & 0x0F, true) : '1 1 1');
		switch(this.beam_type)
		{
			case ARC_BT_MISS:
			{
				this.beam_color = beamcolor;
				this.beam_alpha = 0.5;
				this.beam_thickness = 8;
				this.beam_traileffect = (EFFECT_ARC_BEAM);
				this.beam_hiteffect = (EFFECT_ARC_LIGHTNING);
				this.beam_hitlight[0] = 0;
				this.beam_hitlight[1] = 1;
				this.beam_hitlight[2] = 1;
				this.beam_hitlight[3] = 1;
				this.beam_muzzleeffect = EFFECT_Null;
				this.beam_muzzlelight[0] = 0;
				this.beam_muzzlelight[1] = 1;
				this.beam_muzzlelight[2] = 1;
				this.beam_muzzlelight[3] = 1;
				this.beam_image = "particles/lgbeam";
				if(this.beam_muzzleeffect && autocvar_r_drawviewmodel)
				{
					setmodel(flash, MDL_ARC_MUZZLEFLASH);
					flash.alpha = this.beam_alpha;
					flash.colormod = this.beam_color;
					flash.scale = 0.35;
				}
				break;
			}
			case ARC_BT_WALL: // grenadelauncher_muzzleflash healray_muzzleflash
			{
				this.beam_color = beamcolor;
				this.beam_alpha = 0.5;
				this.beam_thickness = 8;
				this.beam_traileffect = (EFFECT_ARC_BEAM);
				this.beam_hiteffect = (EFFECT_ARC_LIGHTNING);
				this.beam_hitlight[0] = 0;
				this.beam_hitlight[1] = 1;
				this.beam_hitlight[2] = 1;
				this.beam_hitlight[3] = 1;
				this.beam_muzzleeffect = EFFECT_Null; // (EFFECT_GRENADE_MUZZLEFLASH);
				this.beam_muzzlelight[0] = 0;
				this.beam_muzzlelight[1] = 1;
				this.beam_muzzlelight[2] = 1;
				this.beam_muzzlelight[3] = 1;
				this.beam_image = "particles/lgbeam";
				if(this.beam_muzzleeffect && autocvar_r_drawviewmodel)
				{
					setmodel(flash, MDL_ARC_MUZZLEFLASH);
					flash.alpha = this.beam_alpha;
					flash.colormod = this.beam_color;
					flash.scale = 0.35;
				}
				break;
			}
			case ARC_BT_HEAL:
			{
				this.beam_color = beamcolor;
				this.beam_alpha = 0.5;
				this.beam_thickness = 8;
				this.beam_traileffect = (EFFECT_ARC_BEAM_HEAL);
				this.beam_hiteffect = (EFFECT_ARC_BEAM_HEAL_IMPACT);
				this.beam_hitlight[0] = 0;
				this.beam_hitlight[1] = 1;
				this.beam_hitlight[2] = 1;
				this.beam_hitlight[3] = 1;
				this.beam_muzzleeffect = EFFECT_Null;
				this.beam_muzzlelight[0] = 0;
				this.beam_muzzlelight[1] = 1;
				this.beam_muzzlelight[2] = 1;
				this.beam_muzzlelight[3] = 1;
				this.beam_image = "particles/lgbeam";
				if(this.beam_muzzleeffect && autocvar_r_drawviewmodel)
				{
					setmodel(flash, MDL_ARC_MUZZLEFLASH);
					flash.alpha = this.beam_alpha;
					flash.colormod = this.beam_color;
					flash.scale = 0.35;
				}
				break;
			}
			case ARC_BT_HIT:
			{
				this.beam_color = beamcolor;
				this.beam_alpha = 0.5;
				this.beam_thickness = 8;
				this.beam_traileffect = (EFFECT_ARC_BEAM);
				this.beam_hiteffect = (EFFECT_ARC_LIGHTNING);
				this.beam_hitlight[0] = 20;
				this.beam_hitlight[1] = 1;
				this.beam_hitlight[2] = 0;
				this.beam_hitlight[3] = 0;
				this.beam_muzzleeffect = EFFECT_Null;
				this.beam_muzzlelight[0] = 50;
				this.beam_muzzlelight[1] = 1;
				this.beam_muzzlelight[2] = 0;
				this.beam_muzzlelight[3] = 0;
				this.beam_image = "particles/lgbeam";
				if(this.beam_muzzleeffect && autocvar_r_drawviewmodel)
				{
					setmodel(flash, MDL_ARC_MUZZLEFLASH);
					flash.alpha = this.beam_alpha;
					flash.colormod = this.beam_color;
					flash.scale = 0.35;
				}
				break;
			}
			case ARC_BT_BURST_MISS:
			{
				this.beam_color = beamcolor;
				this.beam_alpha = 0.5;
				this.beam_thickness = 14;
				this.beam_traileffect = (EFFECT_ARC_BEAM);
				this.beam_hiteffect = (EFFECT_ARC_LIGHTNING);
				this.beam_hitlight[0] = 0;
				this.beam_hitlight[1] = 1;
				this.beam_hitlight[2] = 1;
				this.beam_hitlight[3] = 1;
				this.beam_muzzleeffect = EFFECT_Null;
				this.beam_muzzlelight[0] = 0;
				this.beam_muzzlelight[1] = 1;
				this.beam_muzzlelight[2] = 1;
				this.beam_muzzlelight[3] = 1;
				this.beam_image = "particles/lgbeam";
				if(this.beam_muzzleeffect && autocvar_r_drawviewmodel)
				{
					setmodel(flash, MDL_ARC_MUZZLEFLASH);
					flash.alpha = this.beam_alpha;
					flash.colormod = this.beam_color;
					flash.scale = 0.35;
				}
				break;
			}
			case ARC_BT_BURST_WALL:
			{
				this.beam_color = beamcolor;
				this.beam_alpha = 0.5;
				this.beam_thickness = 14;
				this.beam_traileffect = (EFFECT_ARC_BEAM);
				this.beam_hiteffect = (EFFECT_ARC_LIGHTNING);
				this.beam_hitlight[0] = 0;
				this.beam_hitlight[1] = 1;
				this.beam_hitlight[2] = 1;
				this.beam_hitlight[3] = 1;
				this.beam_muzzleeffect = EFFECT_Null;
				this.beam_muzzlelight[0] = 0;
				this.beam_muzzlelight[1] = 1;
				this.beam_muzzlelight[2] = 1;
				this.beam_muzzlelight[3] = 1;
				this.beam_image = "particles/lgbeam";
				if(this.beam_muzzleeffect && autocvar_r_drawviewmodel)
				{
					setmodel(flash, MDL_ARC_MUZZLEFLASH);
					flash.alpha = this.beam_alpha;
					flash.colormod = this.beam_color;
					flash.scale = 0.35;
				}
				break;
			}
			case ARC_BT_BURST_HEAL:
			{
				this.beam_color = beamcolor;
				this.beam_alpha = 0.5;
				this.beam_thickness = 14;
				this.beam_traileffect = (EFFECT_ARC_BEAM_HEAL);
				this.beam_hiteffect = (EFFECT_ARC_BEAM_HEAL_IMPACT2);
				this.beam_hitlight[0] = 0;
				this.beam_hitlight[1] = 1;
				this.beam_hitlight[2] = 1;
				this.beam_hitlight[3] = 1;
				this.beam_muzzleeffect = EFFECT_Null;
				this.beam_muzzlelight[0] = 0;
				this.beam_muzzlelight[1] = 1;
				this.beam_muzzlelight[2] = 1;
				this.beam_muzzlelight[3] = 1;
				this.beam_image = "particles/lgbeam";
				if(this.beam_muzzleeffect && autocvar_r_drawviewmodel)
				{
					setmodel(flash, MDL_ARC_MUZZLEFLASH);
					flash.alpha = this.beam_alpha;
					flash.colormod = this.beam_color;
					flash.scale = 0.35;
				}
				break;
			}
			case ARC_BT_BURST_HIT:
			{
				this.beam_color = beamcolor;
				this.beam_alpha = 0.5;
				this.beam_thickness = 14;
				this.beam_traileffect = (EFFECT_ARC_BEAM);
				this.beam_hiteffect = (EFFECT_ARC_LIGHTNING);
				this.beam_hitlight[0] = 0;
				this.beam_hitlight[1] = 1;
				this.beam_hitlight[2] = 1;
				this.beam_hitlight[3] = 1;
				this.beam_muzzleeffect = EFFECT_Null;
				this.beam_muzzlelight[0] = 0;
				this.beam_muzzlelight[1] = 1;
				this.beam_muzzlelight[2] = 1;
				this.beam_muzzlelight[3] = 1;
				this.beam_image = "particles/lgbeam";
				if(this.beam_muzzleeffect && autocvar_r_drawviewmodel)
				{
					setmodel(flash, MDL_ARC_MUZZLEFLASH);
					flash.alpha = this.beam_alpha;
					flash.colormod = this.beam_color;
					flash.scale = 0.35;
				}
				break;
			}

			// shouldn't be possible, but lets make it colorful if it does :D
			default:
			{
				this.beam_color = randomvec();
				this.beam_alpha = 1;
				this.beam_thickness = 8;
				this.beam_traileffect = NULL;
				this.beam_hiteffect = NULL;
				this.beam_hitlight[0] = 0;
				this.beam_hitlight[1] = 1;
				this.beam_hitlight[2] = 1;
				this.beam_hitlight[3] = 1;
				this.beam_muzzleeffect = EFFECT_Null;
				this.beam_muzzlelight[0] = 0;
				this.beam_muzzlelight[1] = 1;
				this.beam_muzzlelight[2] = 1;
				this.beam_muzzlelight[3] = 1;
				this.beam_image = "particles/lgbeam";
				if(this.beam_muzzleeffect && autocvar_r_drawviewmodel)
				{
					setmodel(flash, MDL_ARC_MUZZLEFLASH);
					flash.alpha = this.beam_alpha;
					flash.colormod = this.beam_color;
					flash.scale = 0.35;
				}
				break;
			}
		}
	}

	if(!this.beam_usevieworigin)
	{
		InterpolateOrigin_Note(this);
	}
	return true;
}

#endif
