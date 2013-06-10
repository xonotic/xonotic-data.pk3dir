#ifdef REGISTER_WEAPON
REGISTER_WEAPON(
/* WEP_##id  */ LIGHTNING,
/* function  */ w_lightning,
/* ammotype  */ IT_CELLS,
/* impulse   */ 5,
/* flags     */ WEP_FLAG_NORMAL | WEP_TYPE_SPLASH,
/* rating    */ BOT_PICKUP_RATING_MID,
/* model     */ "lightning",
/* shortname */ "lightning",
/* fullname  */ _("Lightning")
);
#else
#ifdef SVQC

// Declarations ========================= 
.vector hook_start, hook_end; // used for beam
.entity lightning_beam; // used for beam
.float BUTTON_ATCK_prev; // for better animation control
.float lg_fire_prev; // for better animation control

// Lightning functions ========================= 
float W_Lightning_Beam_Send(entity to, float sf)
{
	WriteByte(MSG_ENTITY, ENT_CLIENT_LIGHTNING_BEAM);
	sf = sf & 0x7F;
	if(sound_allowed(MSG_BROADCAST, self.owner))
		sf |= 0x80;
	WriteByte(MSG_ENTITY, sf);
	if(sf & 1)
	{
		WriteByte(MSG_ENTITY, num_for_edict(self.owner));
		WriteCoord(MSG_ENTITY, autocvar_g_balance_lightning_primary_range);
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

void W_Lightning_Beam_Think()
{
	self.owner.lg_fire_prev = time;
	if (self != self.owner.lightning_beam)
	{
		remove(self);
		return;
	}
	if (self.owner.weaponentity.state != WS_INUSE || (self.owner.ammo_cells <= 0 && !(self.owner.items & IT_UNLIMITED_WEAPON_AMMO)) || self.owner.deadflag != DEAD_NO || !self.owner.BUTTON_ATCK || self.owner.freezetag_frozen)
	{
		if(self == self.owner.lightning_beam)
			self.owner.lightning_beam = world;
		remove(self);
		return;
	}

	self.nextthink = time;

	makevectors(self.owner.v_angle);

	float dt, f;
	dt = frametime;
	if not(self.owner.items & IT_UNLIMITED_WEAPON_AMMO)
	{
		if(autocvar_g_balance_lightning_primary_ammo)
		{
			dt = min(dt, self.owner.ammo_cells / autocvar_g_balance_lightning_primary_ammo);
			self.owner.ammo_cells = max(0, self.owner.ammo_cells - autocvar_g_balance_lightning_primary_ammo * frametime);
		}
	}

	W_SetupShot_Range(self.owner, TRUE, 0, "", 0, autocvar_g_balance_lightning_primary_damage * dt, autocvar_g_balance_lightning_primary_range);
	WarpZone_traceline_antilag(self.owner, w_shotorg, w_shotend, MOVE_NORMAL, self.owner, ANTILAG_LATENCY(self.owner));

	// apply the damage
	if(trace_ent)
	{
		vector force;
		force = w_shotdir * autocvar_g_balance_lightning_primary_force;

		f = ExponentialFalloff(autocvar_g_balance_lightning_primary_falloff_mindist, autocvar_g_balance_lightning_primary_falloff_maxdist, autocvar_g_balance_lightning_primary_falloff_halflifedist, vlen(WarpZone_UnTransformOrigin(WarpZone_trace_transform, trace_endpos) - w_shotorg));

		if(accuracy_isgooddamage(self.owner, trace_ent))
			accuracy_add(self.owner, WEP_LIGHTNING, 0, autocvar_g_balance_lightning_primary_damage * dt * f);
		Damage (trace_ent, self.owner, self.owner, autocvar_g_balance_lightning_primary_damage * dt * f, WEP_LIGHTNING, trace_endpos, force * dt);
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

// Attack functions ========================= 
void W_Lightning_Attack1 (void)
{
	// only play fire sound if 0.5 sec has passed since player let go the fire button
	if(time - self.lg_fire_prev > 0.5)
		sound (self, CH_WEAPON_A, "weapons/lgbeam_fire.wav", VOL_BASE, ATTN_NORM);

	entity beam, oldself;

	self.lightning_beam = beam = spawn();
	beam.classname = "W_Lightning_Beam";
	beam.solid = SOLID_NOT;
	beam.think = W_Lightning_Beam_Think;
	beam.owner = self;
	beam.movetype = MOVETYPE_NONE;
	beam.shot_spread = 1;
	beam.bot_dodge = TRUE;
	beam.bot_dodgerating = autocvar_g_balance_lightning_primary_damage;
	Net_LinkEntity(beam, FALSE, 0, W_Lightning_Beam_Send);

	oldself = self;
	self = beam;
	self.think();
	self = oldself;
}

float w_lightning(float req)
{
	if (req == WR_AIM)
	{
		self.BUTTON_ATCK = bot_aim(1000000, 0, 0.001, FALSE);
		/*
		self.BUTTON_ATCK=FALSE;
		self.BUTTON_ATCK2=FALSE;
		if(vlen(self.origin-self.enemy.origin) > 1000)
			self.bot_aim_whichfiretype = 0;
		if(self.bot_aim_whichfiretype == 0)
		{
			float shoot;

			if(autocvar_g_balance_lightning_primary_speed)
				shoot = bot_aim(autocvar_g_balance_lightning_primary_speed, 0, autocvar_g_balance_lightning_primary_lifetime, FALSE);
			else
				shoot = bot_aim(1000000, 0, 0.001, FALSE);

			if(shoot)
			{
				self.BUTTON_ATCK = TRUE;
				if(random() < 0.01) self.bot_aim_whichfiretype = 1;
			}
		}
		else // todo
		{
			//if(bot_aim(autocvar_g_balance_lightning_secondary_speed, autocvar_g_balance_grenadelauncher_secondary_speed_up, autocvar_g_balance_lightning_secondary_lifetime, TRUE))
			//{
			//	self.BUTTON_ATCK2 = TRUE;
			//	if(random() < 0.03) self.bot_aim_whichfiretype = 0;
			//}
		}
		*/
	}
	else if (req == WR_THINK)
	{
		if (self.BUTTON_ATCK)
		{
			if(self.BUTTON_ATCK_prev) // TODO: Find another way to implement this!
				/*if(self.animstate_startframe == self.anim_shoot_x && self.animstate_numframes == self.anim_shoot_y)
					weapon_thinkf(WFRAME_DONTCHANGE, autocvar_g_balance_lightning_primary_animtime, w_ready);
				else*/
					weapon_thinkf(WFRAME_FIRE1, autocvar_g_balance_lightning_primary_animtime, w_ready);
			
			if (weapon_prepareattack(0, 0))
			{
				if ((!self.lightning_beam) || wasfreed(self.lightning_beam))
					W_Lightning_Attack1();
				
				if(!self.BUTTON_ATCK_prev)
				{
					weapon_thinkf(WFRAME_FIRE1, autocvar_g_balance_lightning_primary_animtime, w_ready);
					self.BUTTON_ATCK_prev = 1;
				}
			}
		} 
		else // todo
		{
			if (self.BUTTON_ATCK_prev != 0)
			{
				weapon_thinkf(WFRAME_FIRE1, autocvar_g_balance_lightning_primary_animtime, w_ready);
				ATTACK_FINISHED(self) = time + autocvar_g_balance_lightning_primary_refire * W_WeaponRateFactor();
			}
			self.BUTTON_ATCK_prev = 0;
		}

		//if (self.BUTTON_ATCK2)
			//if (weapon_prepareattack(1, autocvar_g_balance_lightning_secondary_refire))
			//{
			//	W_Lightning_Attack2();
			//	self.lightning_count = autocvar_g_balance_lightning_secondary_count;
			//	weapon_thinkf(WFRAME_FIRE2, autocvar_g_balance_lightning_secondary_animtime, w_lightning_checkattack);
			//	self.lightning_secondarytime = time + autocvar_g_balance_lightning_secondary_refire2 * W_WeaponRateFactor();
			//}
	}
	else if (req == WR_PRECACHE)
	{
		precache_model ("models/weapons/g_lightning.md3");
		precache_model ("models/weapons/v_lightning.md3");
		precache_model ("models/weapons/h_lightning.iqm");
		//precache_sound ("weapons/lightning_bounce.wav");
		precache_sound ("weapons/lightning_fire.wav");
		precache_sound ("weapons/lightning_fire2.wav");
		precache_sound ("weapons/lightning_impact.wav");
		//precache_sound ("weapons/lightning_impact_combo.wav");
		//precache_sound ("weapons/W_Lightning_Beam_fire.wav");
	}
	else if (req == WR_SETUP)
		weapon_setup(WEP_LIGHTNING);
	else if (req == WR_CHECKAMMO1)
	{
		return !autocvar_g_balance_lightning_primary_ammo || (self.ammo_cells > 0);
	}
	else if (req == WR_CHECKAMMO2)
		return self.ammo_cells >= autocvar_g_balance_lightning_secondary_ammo;
	else if (req == WR_KILLMESSAGE)
	{
		if(w_deathtype & HITTYPE_SECONDARY)
		{
			return WEAPON_ELECTRO_MURDER_ORBS;
		}
		else
		{
			if(w_deathtype & HITTYPE_BOUNCE)
				return WEAPON_ELECTRO_MURDER_COMBO;
			else
				return WEAPON_ELECTRO_MURDER_BOLT;
		}
	}
	else if (req == WR_RESETPLAYER)
	{
		//self.lightning_secondarytime = time;
	}
	return TRUE;
};

void LightningInit()
{
	weapon_action(WEP_LIGHTNING, WR_PRECACHE);
	lightning_shotorigin[0] = shotorg_adjust_values(CL_Weapon_GetShotOrg(WEP_LIGHTNING), FALSE, FALSE, 1);
	lightning_shotorigin[1] = shotorg_adjust_values(CL_Weapon_GetShotOrg(WEP_LIGHTNING), FALSE, FALSE, 2);
	lightning_shotorigin[2] = shotorg_adjust_values(CL_Weapon_GetShotOrg(WEP_LIGHTNING), FALSE, FALSE, 3);
	lightning_shotorigin[3] = shotorg_adjust_values(CL_Weapon_GetShotOrg(WEP_LIGHTNING), FALSE, FALSE, 4);
}

void spawnfunc_weapon_lightning (void) // should this really be here?
{
	weapon_defaultspawnfunc(WEP_LIGHTNING);
}
#endif
#ifdef CSQC
float w_lightning(float req)
{
	if(req == WR_IMPACTEFFECT)
	{
		vector org2;
		org2 = w_org + w_backoff * 6;
		
		if(w_deathtype & HITTYPE_SECONDARY)
		{
			pointparticles(particleeffectnum("lightning_ballexplode"), org2, '0 0 0', 1);
			if(!w_issilent)
				sound(self, CH_SHOTS, "weapons/lightning_impact.wav", VOL_BASE, ATTN_NORM);
		}
		else
		{
			pointparticles(particleeffectnum("lightning_impact"), org2, '0 0 0', 1);
			if(!w_issilent)
				sound(self, CH_SHOTS, "weapons/lightning_impact.wav", VOL_BASE, ATTN_NORM);
		}
	}
	else if(req == WR_PRECACHE)
	{
		precache_sound("weapons/lightning_impact.wav");
		precache_sound("weapons/lightning_impact_combo.wav");
	}
	return TRUE;
}
#endif
#endif
