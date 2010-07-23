#ifdef REGISTER_WEAPON
REGISTER_WEAPON(LASER, w_laser, 0, 1, WEP_FLAG_NORMAL | WEP_FLAG_CANCLIMB | WEP_TYPE_SPLASH, 0, "laser", "laser", "Laser");
#else
#ifdef SVQC
void(float imp) W_SwitchWeapon;

void W_Laser_Touch (void)
{
	PROJECTILE_TOUCH;

	self.event_damage = SUB_Null;
	if (self.dmg)
		RadiusDamage (self, self.owner, cvar("g_balance_laser_secondary_damage"), cvar("g_balance_laser_secondary_edgedamage"), cvar("g_balance_laser_secondary_radius"), world, cvar("g_balance_laser_secondary_force"), self.projectiledeathtype, other);
	else
		RadiusDamage (self, self.owner, cvar("g_balance_laser_primary_damage"), cvar("g_balance_laser_primary_edgedamage"), cvar("g_balance_laser_primary_radius"), world, cvar("g_balance_laser_primary_force"), self.projectiledeathtype, other);

	remove (self);
}

void W_Laser_Think()
{
	self.movetype = MOVETYPE_FLY;
	self.think = SUB_Remove;
	if (self.dmg)
		self.nextthink = time + cvar("g_balance_laser_secondary_lifetime");
	else
		self.nextthink = time + cvar("g_balance_laser_primary_lifetime");
	CSQCProjectile(self, TRUE, PROJECTILE_LASER, TRUE);
}

void W_Laser_Attack (float issecondary)
{
	local entity missile;
	vector s_forward;
	float a;
	float nodamage;

	if(issecondary == 2) // minstanex shot
		nodamage = g_minstagib;
	else
		nodamage = FALSE;

	if (issecondary == 1)
		a = cvar("g_balance_laser_secondary_shotangle");
	else
		a = cvar("g_balance_laser_primary_shotangle");
	s_forward = v_forward * cos(a * DEG2RAD) + v_up * sin(a * DEG2RAD);

	if(nodamage)
		W_SetupShot_Dir (self, s_forward, FALSE, 3, "weapons/lasergun_fire.wav", 0);
	else if(issecondary == 1)
		W_SetupShot_Dir (self, s_forward, FALSE, 3, "weapons/lasergun_fire.wav", cvar("g_balance_laser_secondary_damage"));
	else
		W_SetupShot_Dir (self, s_forward, FALSE, 3, "weapons/lasergun_fire.wav", cvar("g_balance_laser_primary_damage"));
	pointparticles(particleeffectnum("laser_muzzleflash"), w_shotorg, w_shotdir * 1000, 1);

	missile = spawn ();
	missile.owner = self;
	missile.classname = "laserbolt";
	missile.dmg = (issecondary == 1);
	if(!nodamage)
	{
		missile.bot_dodge = TRUE;
		if (issecondary == 1)
			missile.bot_dodgerating = cvar("g_balance_laser_secondary_damage");
		else
			missile.bot_dodgerating = cvar("g_balance_laser_primary_damage");
	}

	PROJECTILE_MAKETRIGGER(missile);
	missile.projectiledeathtype = WEP_LASER;
	if(issecondary == 1)
		missile.projectiledeathtype |= HITTYPE_SECONDARY;

	setorigin (missile, w_shotorg);
	setsize(missile, '0 0 0', '0 0 0');

	if (issecondary == 1)
		W_SETUPPROJECTILEVELOCITY(missile, g_balance_laser_secondary);
	else
		W_SETUPPROJECTILEVELOCITY(missile, g_balance_laser_primary);
	missile.angles = vectoangles (missile.velocity);
	//missile.glow_color = 250; // 244, 250
	//missile.glow_size = 120;
	missile.touch = W_Laser_Touch;

	missile.flags = FL_PROJECTILE;

	missile.think = W_Laser_Think;
	if (issecondary == 1)
		missile.nextthink = time + cvar("g_balance_laser_secondary_delay");
	else
		missile.nextthink = time + cvar("g_balance_laser_primary_delay");
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
	if(sound_allowed(MSG_BROADCAST, self.owner))
		sf |= 0x80;
	WriteByte(MSG_ENTITY, sf);
	if(sf & 1)
	{
		WriteByte(MSG_ENTITY, num_for_edict(self.owner));
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
void gauntletbeam_think()
{
	vector endpos;
	float oldsolid;

	float damage, myforce, myradius;
	if(self.cnt)
	{
		damage = cvar("g_balance_laser_secondary_damage");
		myforce = cvar("g_balance_laser_secondary_force");
		myradius = cvar("g_balance_laser_secondary_radius");
	}
	else
	{
		damage = cvar("g_balance_laser_primary_damage");
		myforce = cvar("g_balance_laser_primary_force");
		myradius = cvar("g_balance_laser_primary_radius");
	}

	self.owner.prevgauntletfire = time;
	if (self.owner.weaponentity.state != WS_INUSE || self != self.owner.gauntletbeam || self.owner.deadflag != DEAD_NO || (!self.owner.BUTTON_ATCK2 && self.cnt) || (!self.owner.BUTTON_ATCK && !self.cnt))
	{
		remove(self);
		return;
	}

	self.nextthink = time;

	makevectors(self.owner.v_angle);
	vector angle;
	angle = v_forward;
	// get effect origin
	vector vecs, org;
	if(self.owner.weaponentity.movedir_x > 0)
		vecs = self.owner.weaponentity.movedir;
	else
		vecs = '0 0 0';
	if(debug_shotorg != '0 0 0')
		vecs = debug_shotorg;
	org = self.owner.origin + self.owner.view_ofs + v_forward * vecs_x + v_right * -vecs_y + v_up * vecs_z;
	
	oldsolid = self.owner.dphitcontentsmask;
	self.owner.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_CORPSE;

	WarpZone_traceline_antilag(self.owner, self.owner.origin + self.owner.view_ofs, self.owner.origin + self.owner.view_ofs + angle * myradius, MOVE_NORMAL, self.owner, ANTILAG_LATENCY(self.owner));
	endpos = WarpZone_UnTransformOrigin(WarpZone_trace_transform, trace_endpos);
	WarpZone_traceline_antilag(self.owner, org, endpos + 4 * normalize(endpos - org), MOVE_NORMAL, self.owner, ANTILAG_LATENCY(self.owner));

	self.owner.dphitcontentsmask = oldsolid;

	// apply the damage
	if(trace_fraction < 1)
	{
		vector force;
		force = angle * myforce;
		Damage (trace_ent, self.owner, self.owner, damage * frametime, WEP_ELECTRO, trace_endpos, force * frametime);
	}

	// draw effect
	if(org != self.hook_start)
	{
		self.SendFlags |= 2;
		self.hook_start = org;
	}
	if(endpos != self.hook_end)
	{
		self.SendFlags |= 4;
		self.hook_end = endpos;
	}
}

// experimental gauntlet
void W_Laser_Attack2 (float issecondary)
{
	// only play fire sound if 0.5 sec has passed since player let go the fire button
	if(time - self.prevgauntletfire > 0.5)
	{
		sound (self, CHAN_WEAPON, "weapons/gauntlet_fire.wav", VOL_BASE, ATTN_NORM);
	}

	entity beam, oldself;

	self.gauntletbeam = beam = spawn();
	beam.solid = SOLID_NOT;
	beam.think = gauntletbeam_think;
	beam.owner = self;
	beam.movetype = MOVETYPE_NONE;
	beam.shot_spread = 0;
	beam.bot_dodge = TRUE;
	beam.bot_dodgerating = cvar("g_balance_laser_primary_damage");
	beam.cnt = issecondary;
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
	local float r1;
	local float r2;
	if (req == WR_AIM)
	{
		if(cvar("g_balance_laser_secondary"))
		{
			r1 = cvar("g_balance_laser_primary_damage");
			r2 = cvar("g_balance_laser_secondary_damage");
			if (random() * (r2 + r1) > r1)
				self.BUTTON_ATCK2 = bot_aim(cvar("g_balance_laser_secondary_speed"), 0, cvar("g_balance_laser_secondary_lifetime"), FALSE);
			else
				self.BUTTON_ATCK = bot_aim(cvar("g_balance_laser_primary_speed"), 0, cvar("g_balance_laser_primary_lifetime"), FALSE);
		}
		else
			self.BUTTON_ATCK = bot_aim(cvar("g_balance_laser_primary_speed"), 0, cvar("g_balance_laser_primary_lifetime"), FALSE);
	}
	else if (req == WR_THINK)
	{
		if (self.BUTTON_ATCK)
		if (weapon_prepareattack(0, (cvar("g_balance_laser_primary_gauntlet") ? 0 : cvar("g_balance_laser_primary_refire"))))
		{
			if(cvar("g_balance_laser_primary_gauntlet"))
				W_Laser_Attack2(0);
			else
				W_Laser_Attack(0);
			weapon_thinkf(WFRAME_FIRE1, cvar("g_balance_laser_primary_animtime"), w_ready);
		}
		if (self.BUTTON_ATCK2)
		{
			if(cvar("g_balance_laser_secondary"))
			{
				if (weapon_prepareattack(0, (cvar("g_balance_laser_secondary_gauntlet") ? 0 : cvar("g_balance_laser_secondary_refire"))))
				{
					if(cvar("g_balance_laser_secondary_gauntlet"))
						W_Laser_Attack2(1);
					else
						W_Laser_Attack(1);
					weapon_thinkf(WFRAME_FIRE2, cvar("g_balance_laser_secondary_animtime"), w_ready);
				}
			}
			else
			{
				if(self.switchweapon == WEP_LASER) // don't do this if already switching
					W_SwitchWeapon (self.cnt);
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
	}
	else if (req == WR_SETUP)
		weapon_setup(WEP_LASER);
	else if (req == WR_CHECKAMMO1)
		return TRUE;
	else if (req == WR_CHECKAMMO2)
		return TRUE;
	return TRUE;
};
#endif
#ifdef CSQC
float w_laser(float req)
{
	if(req == WR_IMPACTEFFECT)
	{
		vector org2;
		org2 = w_org + w_backoff * 6;
		pointparticles(particleeffectnum("laser_impact"), org2, w_backoff * 1000, 1);
		if(!w_issilent)
			sound(self, CHAN_PROJECTILE, "weapons/laserimpact.wav", VOL_BASE, ATTN_NORM);
	}
	else if(req == WR_PRECACHE)
	{
		precache_sound("weapons/laserimpact.wav");
	}
	else if (req == WR_SUICIDEMESSAGE)
		w_deathtypestring = "lasered themself to hell";
	else if (req == WR_KILLMESSAGE)
	{
		w_deathtypestring = "was lasered to death by"; // unchecked: SPLASH
	}
	return TRUE;
}
#endif
#endif
