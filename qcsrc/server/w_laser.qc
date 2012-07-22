#ifdef REGISTER_WEAPON
REGISTER_WEAPON(LASER, w_laser, 0, 1, WEP_FLAG_NORMAL | WEP_FLAG_RELOADABLE | WEP_FLAG_CANCLIMB | WEP_TYPE_SPLASH, 0, "laser", "laser", _("Laser"))
#else
#ifdef SVQC
void(float imp) W_SwitchWeapon;
void() W_LastWeapon;

void SendCSQCShockwaveParticle(float spread, vector endpos) 
{
	//WarpZone_UnTransformOrigin(WarpZone_trace_transform, trace_endpos);
	WriteByte(MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte(MSG_BROADCAST, TE_CSQC_SHOCKWAVEPARTICLE);
	WriteCoord(MSG_BROADCAST, w_shotorg_x);
	WriteCoord(MSG_BROADCAST, w_shotorg_y);
	WriteCoord(MSG_BROADCAST, w_shotorg_z);
	WriteCoord(MSG_BROADCAST, endpos_x);
	WriteCoord(MSG_BROADCAST, endpos_y);
	WriteCoord(MSG_BROADCAST, endpos_z);
	WriteByte(MSG_BROADCAST, bound(0, 255 * spread, 255));
}

void W_Laser_Touch (void)
{
	PROJECTILE_TOUCH;

	self.event_damage = SUB_Null;
	if (self.dmg)
		RadiusDamage (self, self.realowner, autocvar_g_balance_laser_secondary_damage, autocvar_g_balance_laser_secondary_edgedamage, autocvar_g_balance_laser_secondary_radius, world, world, autocvar_g_balance_laser_secondary_force, self.projectiledeathtype, other);
	else
		RadiusDamage (self, self.realowner, autocvar_g_balance_laser_primary_damage, autocvar_g_balance_laser_primary_edgedamage, autocvar_g_balance_laser_primary_radius, world, world, autocvar_g_balance_laser_primary_force, self.projectiledeathtype, other);

	remove (self);
}

void W_Laser_Think()
{
	self.movetype = MOVETYPE_FLY;
	self.think = SUB_Remove;
	if (self.dmg)
		self.nextthink = time + autocvar_g_balance_laser_secondary_lifetime;
	else
		self.nextthink = time + autocvar_g_balance_laser_primary_lifetime;
	CSQCProjectile(self, TRUE, PROJECTILE_LASER, TRUE);
}


float W_Laser_Shockwave_CheckSpread(vector targetorg, vector nearest_on_line, vector sw_shotorg, vector attack_hitpos)
{
	float spreadlimit;
	float distance_of_attack = vlen(sw_shotorg - attack_hitpos);
	float distance_from_line = vlen(targetorg - nearest_on_line);
	
	spreadlimit = (vlen(sw_shotorg - nearest_on_line) / (distance_of_attack ? distance_of_attack : 1));
	spreadlimit = (autocvar_g_balance_laser_primary_spread_min * (1 - spreadlimit) + autocvar_g_balance_laser_primary_spread_max * spreadlimit);
	
	if(spreadlimit && (distance_from_line <= spreadlimit))
	{
		te_lightning2(world, targetorg, nearest_on_line);
		te_lightning2(world, targetorg, sw_shotorg);
		print("just in case: ", ftos(distance_from_line), ", ", ftos(spreadlimit), ".\n");
		
		return bound(0, (distance_from_line / spreadlimit), 1);
	}
	else
		return FALSE;
}

float W_Laser_Shockwave_IsVisible(entity head, vector nearest_on_line, vector sw_shotorg, vector attack_hitpos)
{
	vector nearest_to_attacker = head.WarpZone_findradius_nearest;
	vector center = (head.origin + (head.mins + head.maxs) * 0.5);
	vector corner;
	float i;

	// STEP ONE: Check if the nearest point is clear
	if(W_Laser_Shockwave_CheckSpread(nearest_to_attacker, nearest_on_line, sw_shotorg, attack_hitpos))
	{
		WarpZone_TraceLine(sw_shotorg, nearest_to_attacker, MOVE_WORLDONLY, self);
		if(trace_fraction == 1) { return TRUE; } // yes, the nearest point is clear and we can allow the damage
	}

	// STEP TWO: Check if shotorg to center point is clear
	if(W_Laser_Shockwave_CheckSpread(center, nearest_on_line, sw_shotorg, attack_hitpos))
	{
		WarpZone_TraceLine(sw_shotorg, center, MOVE_WORLDONLY, self);
		if(trace_fraction == 1) { return TRUE; } // yes, the center point is clear and we can allow the damage
	}

	// STEP THREE: Check each corner to see if they are clear
	for(i=1; i<=8; ++i)
	{
		corner = get_corner_position(head, i);
		if(W_Laser_Shockwave_CheckSpread(corner, nearest_on_line, sw_shotorg, attack_hitpos))
		{
			WarpZone_TraceLine(sw_shotorg, corner, MOVE_WORLDONLY, self);
			if(trace_fraction == 1) { return TRUE; } // yes, this corner is clear and we can allow the damage
		}
	}

	return FALSE;
}

void W_Laser_Shockwave (void)
{
	// declarations
	float final_damage, final_spread;
	entity head, next, aim_ent;
	vector nearest_to_attacker, nearest_on_line, attack_hitpos, final_force, center;
	
	// set up the shot direction
	vector wanted_shot_direction = (v_forward * cos(autocvar_g_balance_laser_primary_shotangle * DEG2RAD) + v_up * sin(autocvar_g_balance_laser_primary_shotangle * DEG2RAD));
	W_SetupShot_Dir(self, wanted_shot_direction, FALSE, 3, "weapons/lasergun_fire.wav", CH_WEAPON_B, autocvar_g_balance_laser_primary_damage);
	vector attack_endpos = (w_shotorg + (w_shotdir * autocvar_g_balance_laser_primary_radius));

	// find out what we're pointing at and acquire the warpzone transform
	WarpZone_TraceLine(w_shotorg, attack_endpos, FALSE, self);
	aim_ent = trace_ent;
	attack_hitpos = trace_endpos;
	
	// do the jump explosion now (also handles the impact effect)
	RadiusDamageForSource(self, trace_endpos, '0 0 0', self, autocvar_g_balance_laser_primary_damage, autocvar_g_balance_laser_primary_edgedamage, autocvar_g_balance_laser_primary_jumpradius, world, self, TRUE, autocvar_g_balance_laser_primary_force, WEP_LASER, world);
	
	// also do the firing effect now
	SendCSQCShockwaveParticle(autocvar_g_balance_laser_primary_spread, attack_hitpos);
	
	// did we hit a player directly?
	if(aim_ent.takedamage)
	{
		// if it's a player, use the view origin as reference (stolen from RadiusDamage functions in g_damage.qc) // todo
		if (aim_ent.classname == "player")
			center = aim_ent.origin + aim_ent.view_ofs;
		else
			center = aim_ent.origin + (aim_ent.mins + aim_ent.maxs) * 0.5;

		final_force = (normalize(center - attack_hitpos) * autocvar_g_balance_laser_primary_force);
		Damage(aim_ent, self, self, autocvar_g_balance_laser_primary_damage, WEP_LASER, aim_ent.origin, final_force);
	}

	// now figure out if I hit anything else than what my aim directly pointed at...
	head = WarpZone_FindRadius(w_shotorg, autocvar_g_balance_laser_primary_radius, FALSE);
	while(head)
	{
		next = head.chain;
		
		if((head != self && head != aim_ent) && (head.takedamage))
		{
			// if it's a player, use the view origin as reference (stolen from RadiusDamage functions in g_damage.qc) // todo
			if (head.classname == "player")
				center = head.origin + head.view_ofs;
			else
				center = head.origin + (head.mins + head.maxs) * 0.5;

			// find the closest point on the enemy to the center of the attack
			float h = vlen(center - self.origin);
			float ang = acos(dotproduct(normalize(center - self.origin), w_shotdir));
			float a = h * cos(ang);

			nearest_on_line = (w_shotorg + a * w_shotdir);
			
			// ang = angle between shotdir and h
			// h = hypotenuse, which is the distance between attacker to head
			// a = adjacent side, which is the distance between attacker and the point on w_shotdir that is closest to head.origin

			nearest_to_attacker = WarpZoneLib_NearestPointOnBox(center + head.mins, center + head.maxs, nearest_on_line);

			if(vlen(w_shotorg - nearest_to_attacker) <= autocvar_g_balance_laser_primary_radius)
			{
				if(W_Laser_Shockwave_IsVisible(head, nearest_on_line, w_shotorg, attack_hitpos))
				{
					final_damage = W_Laser_Shockwave_CheckSpread(nearest_to_attacker, nearest_on_line, w_shotorg, attack_hitpos); 

					//final_force = (normalize(nearest - w_shotorg) * autocvar_g_balance_laser_primary_force); // we dont want to use nearest here, because that would result in some rather weird force dirs for the attacker...
					print(strcat("head.origin: ", vtos(head.origin), ", (w_shotorg + a * w_shotdir): ", vtos(w_shotorg + a * w_shotdir), ".\n"));
					print("a = ", ftos(a), " h = ", ftos(h), " ang = ", ftos(ang), "\n");
					final_force = (normalize(center - (w_shotorg + a * w_shotdir)) * autocvar_g_balance_laser_primary_force);
					final_damage = (autocvar_g_balance_laser_primary_damage * final_damage + autocvar_g_balance_laser_primary_edgedamage * (1 - final_damage));
					
					print(strcat("damage: ", ftos(final_damage), ", force: ", vtos(final_force), ".\n"));
					
					Damage(head, self, self, final_damage, WEP_LASER, head.origin, final_force);
					//te_lightning2(world, nearest, w_shotorg);
					
					//pointparticles(particleeffectnum("rocket_guide"), w_shotorg, w_shotdir * 1000, 1);
					//SendCSQCShockwaveParticle(autocvar_g_balance_laser_primary_spread, trace_endpos);
				}
			}
		}
		head = next;
	}
}

void W_Laser_Attack (float issecondary)
{
	entity missile;
	vector s_forward;
	float a;
	float nodamage;

	if(issecondary == 2) // minstanex shot
		nodamage = g_minstagib;
	else
		nodamage = FALSE;

	a = autocvar_g_balance_laser_primary_shotangle;
	s_forward = v_forward * cos(a * DEG2RAD) + v_up * sin(a * DEG2RAD);

	if(nodamage)
		W_SetupShot_Dir (self, s_forward, FALSE, 3, "weapons/lasergun_fire.wav", CH_WEAPON_B, 0);
	else if(issecondary == 1)
		W_SetupShot_Dir (self, s_forward, FALSE, 3, "weapons/lasergun_fire.wav", CH_WEAPON_B, autocvar_g_balance_laser_secondary_damage);
	else
		W_SetupShot_Dir (self, s_forward, FALSE, 3, "weapons/lasergun_fire.wav", CH_WEAPON_B, autocvar_g_balance_laser_primary_damage);
	pointparticles(particleeffectnum("laser_muzzleflash"), w_shotorg, w_shotdir * 1000, 1);

	missile = spawn ();
	missile.owner = missile.realowner = self;
	missile.classname = "laserbolt";
	missile.dmg = 0;
	if(!nodamage)
	{
		missile.bot_dodge = TRUE;
		missile.bot_dodgerating = autocvar_g_balance_laser_primary_damage;
	}

	PROJECTILE_MAKETRIGGER(missile);
	missile.projectiledeathtype = WEP_LASER;

	setorigin (missile, w_shotorg);
	setsize(missile, '0 0 0', '0 0 0');

	W_SETUPPROJECTILEVELOCITY(missile, g_balance_laser_primary);
	missile.angles = vectoangles (missile.velocity);
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

.vector hook_start, hook_end;
float gauntletbeam_send(entity to, float sf)
{
	WriteByte(MSG_ENTITY, ENT_CLIENT_GAUNTLET);
	sf = sf & 0x7F;
	if(sound_allowed(MSG_BROADCAST, self.realowner))
		sf |= 0x80;
	WriteByte(MSG_ENTITY, sf);
	if(sf & 1)
	{
		WriteByte(MSG_ENTITY, num_for_edict(self.realowner));
	}
	if(sf & 2)
	{
		WriteCoord(MSG_ENTITY, self.hook_start_x);
		WriteCoord(MSG_ENTITY, self.hook_start_y);
		WriteCoord(MSG_ENTITY, self.hook_start_z);
	}
	if(sf & 4)
	{
		WriteCoord(MSG_ENTITY, self.hook_end_x);
		WriteCoord(MSG_ENTITY, self.hook_end_y);
		WriteCoord(MSG_ENTITY, self.hook_end_z);
	}
	return TRUE;
}
.entity gauntletbeam;
.float prevgauntletfire;
entity lgbeam_owner_ent;
void gauntletbeam_think()
{
	float damage, myforce, myradius;
	damage = autocvar_g_balance_laser_secondary_damage;
	myforce = autocvar_g_balance_laser_secondary_force;
	myradius = autocvar_g_balance_laser_secondary_radius;

	self.realowner.prevgauntletfire = time;
	if (self.realowner.weaponentity.state != WS_INUSE || self != self.realowner.gauntletbeam || self.realowner.deadflag != DEAD_NO || !self.realowner.BUTTON_ATCK2)
	{
		remove(self);
		return;
	}

	self.nextthink = time;

	makevectors(self.realowner.v_angle);

	float dt;
	dt = frametime;

	W_SetupShot_Range(self.realowner, TRUE, 0, "", 0, damage * dt, myradius);
	if(!lgbeam_owner_ent)
	{
		lgbeam_owner_ent = spawn();
		lgbeam_owner_ent.classname = "lgbeam_owner_ent";
	}
	WarpZone_traceline_antilag(lgbeam_owner_ent, w_shotorg, w_shotend, MOVE_NORMAL, lgbeam_owner_ent, ANTILAG_LATENCY(self.owner));

	// apply the damage
	if(trace_ent)
	{
		vector force;
		force = w_shotdir * myforce;
		if(accuracy_isgooddamage(self.owner, trace_ent))
			accuracy_add(self.owner, WEP_LASER, 0, damage * dt);
		Damage (trace_ent, self.owner, self.owner, damage * dt, WEP_LASER | HITTYPE_SECONDARY, trace_endpos, force * dt);
	}

	// draw effect
	if(w_shotorg != self.hook_start)
	{
		self.SendFlags |= 2;
		self.hook_start = w_shotorg;
	}
	if(w_shotend != self.hook_end)
	{
		self.SendFlags |= 4;
		self.hook_end = w_shotend;
	}
}

// experimental gauntlet
void W_Laser_Attack2 ()
{
	// only play fire sound if 0.5 sec has passed since player let go the fire button
	if(time - self.prevgauntletfire > 0.5)
	{
		sound (self, CH_WEAPON_A, "weapons/gauntlet_fire.wav", VOL_BASE, ATTN_NORM);
	}

	entity beam, oldself;

	self.gauntletbeam = beam = spawn();
	beam.solid = SOLID_NOT;
	beam.think = gauntletbeam_think;
	beam.owner = self;
	beam.movetype = MOVETYPE_NONE;
	beam.shot_spread = 0;
	beam.bot_dodge = TRUE;
	beam.bot_dodgerating = autocvar_g_balance_laser_primary_damage;
	Net_LinkEntity(beam, FALSE, 0, gauntletbeam_send);

	oldself = self;
	self = beam;
	self.think();
	self = oldself;
}

void LaserInit()
{
	weapon_action(WEP_LASER, WR_PRECACHE);
	gauntlet_shotorigin[0] = shotorg_adjust_values(CL_Weapon_GetShotOrg(WEP_LASER), FALSE, FALSE, 1);
	gauntlet_shotorigin[1] = shotorg_adjust_values(CL_Weapon_GetShotOrg(WEP_LASER), FALSE, FALSE, 2);
	gauntlet_shotorigin[2] = shotorg_adjust_values(CL_Weapon_GetShotOrg(WEP_LASER), FALSE, FALSE, 3);
	gauntlet_shotorigin[3] = shotorg_adjust_values(CL_Weapon_GetShotOrg(WEP_LASER), FALSE, FALSE, 4);
}

void spawnfunc_weapon_laser (void)
{
	weapon_defaultspawnfunc(WEP_LASER);
}

float w_laser(float req)
{
	float r1;
	float r2;
	if (req == WR_AIM)
	{
		if(autocvar_g_balance_laser_secondary)
		{
			r1 = autocvar_g_balance_laser_primary_damage;
			r2 = autocvar_g_balance_laser_secondary_damage;
			if (random() * (r2 + r1) > r1)
				self.BUTTON_ATCK2 = bot_aim(autocvar_g_balance_laser_secondary_speed, 0, autocvar_g_balance_laser_secondary_lifetime, FALSE);
			else
				self.BUTTON_ATCK = bot_aim(autocvar_g_balance_laser_primary_speed, 0, autocvar_g_balance_laser_primary_lifetime, FALSE);
		}
		else
			self.BUTTON_ATCK = bot_aim(autocvar_g_balance_laser_primary_speed, 0, autocvar_g_balance_laser_primary_lifetime, FALSE);
	}
	else if (req == WR_THINK)
	{
		if(autocvar_g_balance_laser_reload_ammo && self.clip_load < 1) // forced reload
			weapon_action(self.weapon, WR_RELOAD);
		else if (self.BUTTON_ATCK)
		{
			if (weapon_prepareattack(0, autocvar_g_balance_laser_primary_refire))
			{
				W_DecreaseAmmo(ammo_none, 1, TRUE);


				if not(autocvar_g_balance_laser_oldprimary)
					W_Laser_Shockwave();
				else
					W_Laser_Attack(FALSE);

				weapon_thinkf(WFRAME_FIRE1, autocvar_g_balance_laser_primary_animtime, w_ready);
			}
		}
		else if (self.BUTTON_ATCK2)
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
					if(weapon_prepareattack(0, autocvar_g_balance_laser_secondary_refire))
					{
						W_DecreaseAmmo(ammo_none, 1, TRUE);
						W_Laser_Attack(TRUE);
						weapon_thinkf(WFRAME_FIRE2, autocvar_g_balance_laser_secondary_animtime, w_ready);
					}

					break;
				}

				case 2: // gauntlet secondary
				{
					W_DecreaseAmmo(ammo_none, 1, TRUE);

					if (weapon_prepareattack(0, 0))
					{
						W_Laser_Attack2();
						weapon_thinkf(WFRAME_FIRE2, autocvar_g_balance_laser_secondary_animtime, w_ready);
					}

					break;
				}
			}
		}
	}
	else if (req == WR_PRECACHE)
	{
		precache_model ("models/weapons/g_laser.md3");
		precache_model ("models/weapons/v_laser.md3");
		precache_model ("models/weapons/h_laser.iqm");
		precache_sound ("weapons/lasergun_fire.wav");
		precache_sound ("weapons/gauntlet_fire.wav");
		//precache_sound ("weapons/reload.wav"); // until weapons have individual reload sounds, precache the reload sound somewhere else
	}
	else if (req == WR_SETUP)
	{
		weapon_setup(WEP_LASER);
		self.current_ammo = ammo_none;
	}
	else if (req == WR_CHECKAMMO1)
	{
		return TRUE;
	}
	else if (req == WR_CHECKAMMO2)
	{
		return TRUE;
	}
	else if (req == WR_RELOAD)
	{
		W_Reload(0, autocvar_g_balance_laser_reload_ammo, autocvar_g_balance_laser_reload_time, "weapons/reload.wav");
	}
	return TRUE;
}
#endif
#ifdef CSQC
float w_laser(float req)
{
	if(req == WR_IMPACTEFFECT)
	{
		vector org2;
		org2 = w_org + w_backoff * 6;
		pointparticles(particleeffectnum("new_laser_impact"), org2, w_backoff * 1000, 1);
		if(!w_issilent)
			sound(self, CH_SHOTS, "weapons/laserimpact.wav", VOL_BASE, ATTN_NORM);
	}
	else if(req == WR_PRECACHE)
	{
		precache_sound("weapons/laserimpact.wav");
	}
	else if (req == WR_SUICIDEMESSAGE)
		w_deathtypestring = _("%s lasered themself to hell");
	else if (req == WR_KILLMESSAGE)
	{
		if(w_deathtype & HITTYPE_SECONDARY)
			w_deathtypestring = _("%s was cut in half by %s's gauntlet"); // unchecked: SPLASH
		else
			w_deathtypestring = _("%s was lasered to death by %s"); // unchecked: SPLASH
	}
	return TRUE;
}
#endif
#endif
