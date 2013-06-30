#ifdef REGISTER_WEAPON
REGISTER_WEAPON(
/* WEP_##id */ LASER,
/* function */ W_Laser,
/* ammotype */ 0,
/* impulse  */ 1,
/* flags    */ WEP_FLAG_NORMAL | WEP_FLAG_RELOADABLE | WEP_FLAG_CANCLIMB | WEP_TYPE_SPLASH,
/* rating   */ 0,
/* model    */ "laser",
/* netname  */ "laser",
/* fullname */ _("Blaster")
);
#else
#ifdef SVQC
void spawnfunc_weapon_laser() { weapon_defaultspawnfunc(WEP_LASER); }
void(float imp) W_SwitchWeapon;
void() W_LastWeapon;
.float swing_prev;
.entity swing_alreadyhit;

void SendCSQCShockwaveParticle(vector endpos) 
{
	//endpos = WarpZone_UnTransformOrigin(transform, endpos);
	
	WriteByte(MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte(MSG_BROADCAST, TE_CSQC_SHOCKWAVEPARTICLE);
	WriteCoord(MSG_BROADCAST, w_shotorg_x);
	WriteCoord(MSG_BROADCAST, w_shotorg_y);
	WriteCoord(MSG_BROADCAST, w_shotorg_z);
	WriteCoord(MSG_BROADCAST, endpos_x);
	WriteCoord(MSG_BROADCAST, endpos_y);
	WriteCoord(MSG_BROADCAST, endpos_z);
	WriteByte(MSG_BROADCAST, bound(0, autocvar_g_balance_laser_shockwave_spread_max, 255));
	WriteByte(MSG_BROADCAST, bound(0, autocvar_g_balance_laser_shockwave_spread_min, 255));
	WriteByte(MSG_BROADCAST, num_for_edict(self));
}

void W_Laser_Touch()
{
	PROJECTILE_TOUCH;

	self.event_damage = func_null;
	
	if(self.dmg)
		RadiusDamage(self, self.realowner, autocvar_g_balance_laser_secondary_damage, autocvar_g_balance_laser_secondary_edgedamage, autocvar_g_balance_laser_secondary_radius, world, world, autocvar_g_balance_laser_secondary_force, self.projectiledeathtype, other);
	else
		RadiusDamage(self, self.realowner, autocvar_g_balance_laser_primary_damage, autocvar_g_balance_laser_primary_edgedamage, autocvar_g_balance_laser_primary_radius, world, world, autocvar_g_balance_laser_primary_force, self.projectiledeathtype, other);

	remove(self);
}

void W_Laser_Think()
{
	self.movetype = MOVETYPE_FLY;
	self.think = SUB_Remove;
	
	if(self.dmg)
		self.nextthink = time + autocvar_g_balance_laser_secondary_lifetime;
	else
		self.nextthink = time + autocvar_g_balance_laser_primary_lifetime;
		
	CSQCProjectile(self, TRUE, PROJECTILE_LASER, TRUE);
}


float W_Laser_Shockwave_CheckSpread(vector targetorg, vector nearest_on_line, vector sw_shotorg, vector attack_endpos)
{
	float spreadlimit;
	float distance_of_attack = vlen(sw_shotorg - attack_endpos);
	float distance_from_line = vlen(targetorg - nearest_on_line);
	
	spreadlimit = (distance_of_attack ? min(1, (vlen(sw_shotorg - nearest_on_line) / distance_of_attack)) : 1);
	spreadlimit = (autocvar_g_balance_laser_shockwave_spread_min * (1 - spreadlimit) + autocvar_g_balance_laser_shockwave_spread_max * spreadlimit);
	
	if(spreadlimit && (distance_from_line <= spreadlimit) && ((vlen(normalize(targetorg - sw_shotorg) - normalize(attack_endpos - sw_shotorg)) * RAD2DEG) <= 90))
		return bound(0, (distance_from_line / spreadlimit), 1);
	else
		return FALSE;
}

float W_Laser_Shockwave_IsVisible(entity head, vector nearest_on_line, vector sw_shotorg, vector attack_endpos)
{
	vector nearest_to_attacker = head.WarpZone_findradius_nearest;
	vector center = (head.origin + (head.mins + head.maxs) * 0.5);
	vector corner;
	float i;

	// STEP ONE: Check if the nearest point is clear
	if(W_Laser_Shockwave_CheckSpread(nearest_to_attacker, nearest_on_line, sw_shotorg, attack_endpos))
	{
		WarpZone_TraceLine(sw_shotorg, nearest_to_attacker, MOVE_NOMONSTERS, self);
		if(trace_fraction == 1) { return TRUE; } // yes, the nearest point is clear and we can allow the damage
	}

	// STEP TWO: Check if shotorg to center point is clear
	if(W_Laser_Shockwave_CheckSpread(center, nearest_on_line, sw_shotorg, attack_endpos))
	{
		WarpZone_TraceLine(sw_shotorg, center, MOVE_NOMONSTERS, self);
		if(trace_fraction == 1) { return TRUE; } // yes, the center point is clear and we can allow the damage
	}

	// STEP THREE: Check each corner to see if they are clear
	for(i=1; i<=8; ++i)
	{
		corner = get_corner_position(head, i);
		if(W_Laser_Shockwave_CheckSpread(corner, nearest_on_line, sw_shotorg, attack_endpos))
		{
			WarpZone_TraceLine(sw_shotorg, corner, MOVE_NOMONSTERS, self);
			if(trace_fraction == 1) { return TRUE; } // yes, this corner is clear and we can allow the damage
		}
	}

	return FALSE;
}

#define PLAYER_CENTER(ent) (ent.origin + ((ent.classname == "player") ? ent.view_ofs : ((ent.mins + ent.maxs) * 0.5)))

entity shockwave_hit[32];
float shockwave_hit_damage[32];
vector shockwave_hit_force[32];

float W_Laser_Shockwave_CheckHit(float queue, entity head, vector final_force, float final_damage)
{
	if not(head) { return FALSE; }
	float i;

	++queue;
	
	for(i = 1; i <= queue; ++i)
	{
		if(shockwave_hit[i] == head)
		{
			if(vlen(final_force) > vlen(shockwave_hit_force[i])) { shockwave_hit_force[i] = final_force; }
			if(final_damage > shockwave_hit_damage[i]) { shockwave_hit_damage[i] = final_damage; }
			return FALSE;
		}
	}

	shockwave_hit[queue] = head;
	shockwave_hit_force[queue] = final_force;
	shockwave_hit_damage[queue] = final_damage;
	return TRUE;
}

void W_Laser_Shockwave()
{
	// declarations
	float multiplier, multiplier_from_accuracy, multiplier_from_distance;
	float final_damage; //, final_spread;
	vector final_force, center, vel;
	entity head, next;

	float i, queue = 0;
	
	// set up the shot direction
	W_SetupShot(self, FALSE, 3, "weapons/lasergun_fire.wav", CH_WEAPON_B, autocvar_g_balance_laser_shockwave_damage);
	vector attack_endpos = (w_shotorg + (w_shotdir * autocvar_g_balance_laser_shockwave_distance));
	WarpZone_TraceLine(w_shotorg, attack_endpos, MOVE_NOMONSTERS, self);
	vector attack_hitpos = trace_endpos;
	float distance_to_end = vlen(w_shotorg - attack_endpos);
	float distance_to_hit = vlen(w_shotorg - attack_hitpos);
	//entity transform = WarpZone_trace_transform;

	// do the firing effect now
	SendCSQCShockwaveParticle(attack_endpos);
	Damage_DamageInfo(attack_hitpos, autocvar_g_balance_laser_shockwave_splash_damage, autocvar_g_balance_laser_shockwave_splash_edgedamage, autocvar_g_balance_laser_shockwave_splash_radius, w_shotdir * autocvar_g_balance_laser_shockwave_splash_force, WEP_LASER, 0, self);

	// splash damage/jumping trace
	head = WarpZone_FindRadius(attack_hitpos, max(autocvar_g_balance_laser_shockwave_splash_radius, autocvar_g_balance_laser_shockwave_jump_radius), FALSE);
	while(head)
	{
		next = head.chain;

		if(head.takedamage)
		{
			// if it's a player, use the view origin as reference (stolen from RadiusDamage functions in g_damage.qc)
			center = PLAYER_CENTER(head);

			float distance_to_head = vlen(attack_hitpos - head.WarpZone_findradius_nearest);
			
			if((head == self) && (distance_to_head <= autocvar_g_balance_laser_shockwave_jump_radius))
			{
				multiplier_from_accuracy = (1 - (distance_to_head ? min(1, (distance_to_head / autocvar_g_balance_laser_shockwave_jump_radius)) : 0));
				multiplier_from_distance = (1 - (distance_to_hit ? min(1, (distance_to_hit / distance_to_end)) : 0));
				multiplier = max(autocvar_g_balance_laser_shockwave_jump_multiplier_min, ((multiplier_from_accuracy * autocvar_g_balance_laser_shockwave_jump_multiplier_accuracy) + (multiplier_from_distance * autocvar_g_balance_laser_shockwave_jump_multiplier_distance)));

				final_force = ((normalize(center - attack_hitpos) * autocvar_g_balance_laser_shockwave_jump_force) * multiplier);
				vel = head.velocity; vel_z = 0;
				vel = normalize(vel) * bound(0, vlen(vel) / autocvar_sv_maxspeed, 1) * autocvar_g_balance_laser_shockwave_jump_force_velocitybias;
				final_force = (vlen(final_force) * normalize(normalize(final_force) + vel));
				final_force_z *= autocvar_g_balance_laser_shockwave_jump_force_zscale;
				final_damage = (autocvar_g_balance_laser_shockwave_jump_damage * multiplier + autocvar_g_balance_laser_shockwave_jump_edgedamage * (1 - multiplier));

				Damage(head, self, self, final_damage, WEP_LASER, head.origin, final_force);
				//print("SELF HIT: multiplier = ", ftos(multiplier), strcat(", damage = ", ftos(final_damage), ", force = ", ftos(vlen(final_force))),"... multiplier_from_accuracy = ", ftos(multiplier_from_accuracy), ", multiplier_from_distance = ", ftos(multiplier_from_distance), ".\n");
			}
			else if (distance_to_head <= autocvar_g_balance_laser_shockwave_splash_radius)
			{	
				multiplier_from_accuracy = (1 - (distance_to_head ? min(1, (distance_to_head / autocvar_g_balance_laser_shockwave_splash_radius)) : 0));
				multiplier_from_distance = (1 - (distance_to_hit ? min(1, (distance_to_hit / distance_to_end)) : 0));
				multiplier = max(autocvar_g_balance_laser_shockwave_splash_multiplier_min, ((multiplier_from_accuracy * autocvar_g_balance_laser_shockwave_splash_multiplier_accuracy) + (multiplier_from_distance * autocvar_g_balance_laser_shockwave_splash_multiplier_distance)));

				final_force = normalize(center - (attack_hitpos - (w_shotdir * autocvar_g_balance_laser_shockwave_splash_force_forwardbias)));
				//te_lightning2(world, attack_hitpos, (attack_hitpos + (final_force * 200)));
				final_force = ((final_force * autocvar_g_balance_laser_shockwave_splash_force) * multiplier);
				final_force_z *= autocvar_g_balance_laser_shockwave_force_zscale;
				final_damage = (autocvar_g_balance_laser_shockwave_splash_damage * multiplier + autocvar_g_balance_laser_shockwave_splash_edgedamage * (1 - multiplier));

				if(W_Laser_Shockwave_CheckHit(queue, head, final_force, final_damage)) { ++queue; }
				//print("SPLASH HIT: multiplier = ", ftos(multiplier), strcat(", damage = ", ftos(final_damage), ", force = ", ftos(vlen(final_force))),"... multiplier_from_accuracy = ", ftos(multiplier_from_accuracy), ", multiplier_from_distance = ", ftos(multiplier_from_distance), ".\n");
			}
		}
		head = next;
	}

	// cone damage trace
	head = WarpZone_FindRadius(w_shotorg, autocvar_g_balance_laser_shockwave_distance, FALSE);
	while(head)
	{
		next = head.chain;
		
		if((head != self) && head.takedamage)
		{
			// if it's a player, use the view origin as reference (stolen from RadiusDamage functions in g_damage.qc) 
			center = PLAYER_CENTER(head);

			// find the closest point on the enemy to the center of the attack
			float ang; // angle between shotdir and h
			float h; // hypotenuse, which is the distance between attacker to head
			float a; // adjacent side, which is the distance between attacker and the point on w_shotdir that is closest to head.origin
			
			h = vlen(center - self.origin);
			ang = acos(dotproduct(normalize(center - self.origin), w_shotdir));
			a = h * cos(ang);

			vector nearest_on_line = (w_shotorg + a * w_shotdir);
			vector nearest_to_attacker = WarpZoneLib_NearestPointOnBox(center + head.mins, center + head.maxs, nearest_on_line);
			float distance_to_target = vlen(w_shotorg - nearest_to_attacker); // todo: use the findradius function for this

			if((distance_to_target <= autocvar_g_balance_laser_shockwave_distance) 
				&& (W_Laser_Shockwave_IsVisible(head, nearest_on_line, w_shotorg, attack_endpos)))
			{
				multiplier_from_accuracy = (1 - W_Laser_Shockwave_CheckSpread(nearest_to_attacker, nearest_on_line, w_shotorg, attack_endpos));
				multiplier_from_distance = (1 - (distance_to_hit ? min(1, (distance_to_target / distance_to_end)) : 0));
				multiplier = max(autocvar_g_balance_laser_shockwave_multiplier_min, ((multiplier_from_accuracy * autocvar_g_balance_laser_shockwave_multiplier_accuracy) + (multiplier_from_distance * autocvar_g_balance_laser_shockwave_multiplier_distance)));

				final_force = normalize(center - (nearest_on_line - (w_shotdir * autocvar_g_balance_laser_shockwave_force_forwardbias)));
				//te_lightning2(world, nearest_on_line, (attack_hitpos + (final_force * 200)));
				final_force = ((final_force * autocvar_g_balance_laser_shockwave_force) * multiplier);
				final_force_z *= autocvar_g_balance_laser_shockwave_force_zscale;
				final_damage = (autocvar_g_balance_laser_shockwave_damage * multiplier + autocvar_g_balance_laser_shockwave_edgedamage * (1 - multiplier));

				if(W_Laser_Shockwave_CheckHit(queue, head, final_force, final_damage)) { ++queue; }
				//print("CONE HIT: multiplier = ", ftos(multiplier), strcat(", damage = ", ftos(final_damage), ", force = ", ftos(vlen(final_force))),"... multiplier_from_accuracy = ", ftos(multiplier_from_accuracy), ", multiplier_from_distance = ", ftos(multiplier_from_distance), ".\n");
			}
		}
		head = next;
	}

	for(i = 1; i <= queue; ++i)
	{
		head = shockwave_hit[i];
		final_force = shockwave_hit_force[i];
		final_damage = shockwave_hit_damage[i];
		
		Damage(head, self, self, final_damage, WEP_LASER, head.origin, final_force);
		print("SHOCKWAVE by ", self.netname, ": damage = ", ftos(final_damage), ", force = ", ftos(vlen(final_force)), ".\n");
		
		shockwave_hit[i] = world;
		shockwave_hit_force[i] = '0 0 0';
		shockwave_hit_damage[i] = 0;
	}
	//print("queue was ", ftos(queue), ".\n\n");
}

void W_Laser_Melee_Think()
{
	// declarations
	float i, f, swing, swing_factor, swing_damage, meleetime, is_player;
	entity target_victim;
	vector targpos;

	if(!self.cnt) // set start time of melee
	{
		self.cnt = time; 
		W_PlayStrengthSound(self.realowner);
	}

	makevectors(self.realowner.v_angle); // update values for v_* vectors
	
	// calculate swing percentage based on time
	meleetime = autocvar_g_balance_laser_melee_time * W_WeaponRateFactor();
	swing = bound(0, (self.cnt + meleetime - time) / meleetime, 10);
	f = ((1 - swing) * autocvar_g_balance_laser_melee_traces);
	
	// check to see if we can still continue, otherwise give up now
	if((self.realowner.deadflag != DEAD_NO) && autocvar_g_balance_laser_melee_no_doubleslap)
	{
		remove(self);
		return;
	}
	
	// if okay, perform the traces needed for this frame 
	for(i=self.swing_prev; i < f; ++i)
	{
		swing_factor = ((1 - (i / autocvar_g_balance_laser_melee_traces)) * 2 - 1);
		
		targpos = (self.realowner.origin + self.realowner.view_ofs 
			+ (v_forward * autocvar_g_balance_laser_melee_range)
			+ (v_up * swing_factor * autocvar_g_balance_laser_melee_swing_up)
			+ (v_right * swing_factor * autocvar_g_balance_laser_melee_swing_side));

		WarpZone_traceline_antilag(self.realowner, self.realowner.origin + self.realowner.view_ofs, targpos, FALSE, self.realowner, ANTILAG_LATENCY(self.realowner));
		
		// draw lightning beams for debugging
		te_lightning2(world, targpos, self.realowner.origin + self.realowner.view_ofs + v_forward * 5 - v_up * 5); 
		te_customflash(targpos, 40,  2, '1 1 1');
		
		is_player = (trace_ent.classname == "player" || trace_ent.classname == "body");

		if((trace_fraction < 1) // if trace is good, apply the damage and remove self
			&& (trace_ent.takedamage == DAMAGE_AIM)  
			&& (trace_ent != self.swing_alreadyhit)
			&& (is_player || autocvar_g_balance_laser_melee_nonplayerdamage))
		{
			target_victim = trace_ent; // so it persists through other calls
			
			if(is_player) // this allows us to be able to nerf the non-player damage done in e.g. assault or onslaught.
				swing_damage = (autocvar_g_balance_laser_melee_damage * min(1, swing_factor + 1));
			else
				swing_damage = (autocvar_g_balance_laser_melee_nonplayerdamage * min(1, swing_factor + 1));
			
			//print(strcat(self.realowner.netname, " hitting ", target_victim.netname, " with ", strcat(ftos(swing_damage), " damage (factor: ", ftos(swing_factor), ") at "), ftos(time), " seconds.\n"));
			
			Damage(target_victim, self.realowner, self.realowner, 
				swing_damage, WEP_LASER | HITTYPE_SECONDARY, 
				self.realowner.origin + self.realowner.view_ofs, 
				v_forward * autocvar_g_balance_laser_melee_force);
				
			if(accuracy_isgooddamage(self.realowner, target_victim)) { accuracy_add(self.realowner, WEP_LASER, 0, swing_damage); }
			
			if(autocvar_g_balance_laser_melee_multihit) // allow multiple hits with one swing, but not against the same player twice.
			{
				self.swing_alreadyhit = target_victim;
				continue; // move along to next trace
			}
			else
			{
				remove(self);
				return;
			}
		}
	}
	
	if(time >= self.cnt + meleetime)
	{
		// melee is finished
		remove(self);
		return;
	}
	else
	{
		// set up next frame 
		self.swing_prev = i;
		self.nextthink = time;
	}
}

void W_Laser_Melee()
{
	sound(self, CH_WEAPON_A, "weapons/shotgun_melee.wav", VOL_BASE, ATTN_NORM);
	weapon_thinkf(WFRAME_FIRE2, autocvar_g_balance_laser_melee_animtime, w_ready);

	entity meleetemp;
	meleetemp = spawn();
	meleetemp.owner = meleetemp.realowner = self;
	meleetemp.think = W_Laser_Melee_Think;
	meleetemp.nextthink = time + autocvar_g_balance_laser_melee_delay * W_WeaponRateFactor();
	W_SetupShot_Range(self, TRUE, 0, "", 0, autocvar_g_balance_laser_melee_damage, autocvar_g_balance_laser_melee_range);
}

void W_Laser_Attack(float issecondary)
{
	entity missile;
	vector s_forward;
	float a;

	a = autocvar_g_balance_laser_primary_shotangle;
	s_forward = v_forward * cos(a * DEG2RAD) + v_up * sin(a * DEG2RAD);

	//if(nodamage)
	//	W_SetupShot_Dir(self, s_forward, FALSE, 3, "weapons/lasergun_fire.wav", CH_WEAPON_B, 0);
	/*else*/if(issecondary == 1)
		W_SetupShot_Dir(self, s_forward, FALSE, 3, "weapons/lasergun_fire.wav", CH_WEAPON_B, autocvar_g_balance_laser_secondary_damage);
	else
		W_SetupShot_Dir(self, s_forward, FALSE, 3, "weapons/lasergun_fire.wav", CH_WEAPON_B, autocvar_g_balance_laser_primary_damage);
	pointparticles(particleeffectnum("laser_muzzleflash"), w_shotorg, w_shotdir * 1000, 1);

	missile = spawn();
	missile.owner = missile.realowner = self;
	missile.classname = "laserbolt";
	missile.dmg = 0;
	missile.bot_dodge = TRUE;
	missile.bot_dodgerating = autocvar_g_balance_laser_primary_damage;

	PROJECTILE_MAKETRIGGER(missile);
	missile.projectiledeathtype = WEP_LASER;

	setorigin(missile, w_shotorg);
	setsize(missile, '0 0 0', '0 0 0');

	W_SETUPPROJECTILEVELOCITY(missile, g_balance_laser_primary);
	missile.angles = vectoangles(missile.velocity);
	//missile.glow_color = 250; // 244, 250
	//missile.glow_size = 120;
	missile.touch = W_Laser_Touch;

	missile.flags = FL_PROJECTILE;
	missile.missile_flags = MIF_SPLASH; 

	missile.think = W_Laser_Think;
	missile.nextthink = time + autocvar_g_balance_laser_primary_delay;

	other = missile; MUTATOR_CALLHOOK(EditProjectile);

	if(time >= missile.nextthink)
	{
		entity oldself;
		oldself = self;
		self = missile;
		self.think();
		self = oldself;
	}
}

float W_Laser(float request)
{
	switch(request)
	{
		case WR_AIM:
		{
			if((autocvar_g_balance_laser_secondary == 2) && (vlen(self.origin-self.enemy.origin) <= autocvar_g_balance_laser_melee_range))
				self.BUTTON_ATCK2 = bot_aim(1000000, 0, 0.001, FALSE);
			else
				self.BUTTON_ATCK = bot_aim(1000000, 0, 1, FALSE);
			return TRUE;
		}
		
		case WR_THINK:
		{
			if(autocvar_g_balance_laser_reload_ammo && self.clip_load < 1) // forced reload
				WEP_ACTION(self.weapon, WR_RELOAD);
			else if(self.BUTTON_ATCK)
			{
				if(weapon_prepareattack(0, autocvar_g_balance_laser_primary_refire))
				{
					W_DecreaseAmmo(ammo_none, 1, TRUE);

					if not(autocvar_g_balance_laser_primary)
						W_Laser_Shockwave();
					else
						W_Laser_Attack(FALSE);

					weapon_thinkf(WFRAME_FIRE1, autocvar_g_balance_laser_primary_animtime, w_ready);
				}
			}
			else if(self.BUTTON_ATCK2)
			{
				switch(autocvar_g_balance_laser_secondary)
				{
					case 0: // switch to last used weapon
					{
						if(self.switchweapon == WEP_LASER) // don't do this if already switching
							W_LastWeapon();

						break;
					}

					case 1: // normal projectile secondary
					{
						if(weapon_prepareattack(1, autocvar_g_balance_laser_secondary_refire))
						{
							W_DecreaseAmmo(ammo_none, 1, TRUE);
							W_Laser_Attack(TRUE);
							weapon_thinkf(WFRAME_FIRE2, autocvar_g_balance_laser_secondary_animtime, w_ready);
						}

						break;
					}

					case 2: // melee attack secondary
					{
						if(!self.crouch) // we are not currently crouching; this fixes an exploit where your melee anim is not visible, and besides wouldn't make much sense
						if(weapon_prepareattack(1, autocvar_g_balance_laser_melee_refire))
						{
							// attempt forcing playback of the anim by switching to another anim (that we never play) here...
							W_Laser_Melee();
							weapon_thinkf(WFRAME_FIRE1, autocvar_g_balance_laser_melee_animtime, w_ready);
						}
					}
				}
			}
			return TRUE;
		}
		
		case WR_INIT: 
		{
			precache_model("models/weapons/g_laser.md3");
			precache_model("models/weapons/v_laser.md3");
			precache_model("models/weapons/h_laser.iqm");
			precache_sound("weapons/lasergun_fire.wav");
			return TRUE;
		}
		
		case WR_SETUP:
		{
			weapon_setup(WEP_LASER);
			self.current_ammo = ammo_none;
			return TRUE;
		}
		
		case WR_CHECKAMMO1:
		case WR_CHECKAMMO2:
		{
			return TRUE; // laser has infinite ammo
		}
		
		case WR_RELOAD:
		{
			W_Reload(0, autocvar_g_balance_laser_reload_ammo, autocvar_g_balance_laser_reload_time, "weapons/reload.wav");
			return TRUE;
		}
		
		case WR_SUICIDEMESSAGE:
		{
			return WEAPON_LASER_SUICIDE;
		}
		
		case WR_KILLMESSAGE:
		{
			return WEAPON_LASER_MURDER;
		}
	}
	
	return TRUE;
}
#endif
#ifdef CSQC
float W_Laser(float request)
{
	switch(request)
	{
		case WR_IMPACTEFFECT:
		{
			vector org2;
			org2 = w_org + w_backoff * 6;
			pointparticles(particleeffectnum("new_laser_impact"), org2, w_backoff * 1000, 1);
			if(!w_issilent) { sound(self, CH_SHOTS, "weapons/laserimpact.wav", VOL_BASE, ATTN_NORM); }
			return TRUE;
		}
		
		case WR_INIT:
		{
			precache_sound("weapons/laserimpact.wav");
			return TRUE;
		}
	}
	
	return TRUE;
}
#endif
#endif
