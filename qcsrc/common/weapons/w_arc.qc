#ifdef REGISTER_WEAPON
REGISTER_WEAPON(
/* WEP_##id */ ARC,
/* function */ W_Arc,
/* ammotype */ ammo_cells,
/* impulse  */ 3,
/* flags    */ WEP_FLAG_NORMAL,
/* rating   */ BOT_PICKUP_RATING_HIGH,
/* color	*/ '1 1 1',
/* model    */ "arc",
/* netname  */ "arc",
/* fullname */ _("Arc")
);

#define ARC_SETTINGS(w_cvar,w_prop) ARC_SETTINGS_LIST(w_cvar, w_prop, ARC, arc)
#define ARC_SETTINGS_LIST(w_cvar,w_prop,id,sn) \
	w_cvar(id, sn, BOTH, ammo) \
	w_cvar(id, sn, PRI,  animtime) \
	w_cvar(id, sn, PRI,  damage) \
	w_cvar(id, sn, PRI,  falloff_halflifedist) \
	w_cvar(id, sn, PRI,  falloff_maxdist) \
	w_cvar(id, sn, PRI,  falloff_mindist) \
	w_cvar(id, sn, PRI,  force) \
	w_cvar(id, sn, PRI,  range) \
	w_cvar(id, sn, PRI,  refire) \
	w_prop(id, sn, float,  switchdelay_raise, switchdelay_raise) \
	w_prop(id, sn, float,  switchdelay_drop, switchdelay_drop) \
	w_prop(id, sn, string, weaponreplace, weaponreplace) \
	w_prop(id, sn, float,  weaponstart, weaponstart) \
	w_prop(id, sn, float,  weaponstartoverride, weaponstartoverride)

#ifndef MENUQC
vector arc_shotorigin[4];
#endif
#ifdef SVQC
ARC_SETTINGS(WEP_ADD_CVAR, WEP_ADD_PROP)
void ArcInit();
.vector hook_start, hook_end; // used for beam
.entity arc_beam; // used for beam
.float BUTTON_ATCK_prev; // for better animation control
.float lg_fire_prev; // for better animation control
#endif
#else
#ifdef SVQC
void spawnfunc_weapon_arc() { weapon_defaultspawnfunc(WEP_ARC); }

float W_Arc_Beam_Send(entity to, float sf)
{
	WriteByte(MSG_ENTITY, ENT_CLIENT_ARC_BEAM);
	sf = sf & 0x7F;
	if(sound_allowed(MSG_BROADCAST, self.owner))
		sf |= 0x80;
	WriteByte(MSG_ENTITY, sf);
	if(sf & 1)
	{
		WriteByte(MSG_ENTITY, num_for_edict(self.owner));
		WriteCoord(MSG_ENTITY, WEP_CVAR_PRI(arc, range));
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

void W_Arc_Beam_Think()
{
	self.owner.lg_fire_prev = time;
	if (self != self.owner.arc_beam)
	{
		remove(self);
		return;
	}
	if (self.owner.weaponentity.state != WS_INUSE || (self.owner.WEP_AMMO(WEP_ARC) <= 0 && !(self.owner.items & IT_UNLIMITED_WEAPON_AMMO)) || self.owner.deadflag != DEAD_NO || !self.owner.BUTTON_ATCK || self.owner.freezetag_frozen)
	{
		if(self == self.owner.arc_beam)
			self.owner.arc_beam = world;
		remove(self);
		return;
	}

	self.nextthink = time;

	makevectors(self.owner.v_angle);

	float dt, f;
	dt = frametime;
	if(!(self.owner.items & IT_UNLIMITED_WEAPON_AMMO))
	{
		if(WEP_CVAR_PRI(arc, ammo))
		{
			dt = min(dt, self.owner.WEP_AMMO(WEP_ARC) / WEP_CVAR_PRI(arc, ammo));
			self.owner.WEP_AMMO(WEP_ARC) = max(0, self.owner.WEP_AMMO(WEP_ARC) - WEP_CVAR_PRI(arc, ammo) * frametime);
		}
	}

	W_SetupShot_Range(self.owner, TRUE, 0, "", 0, WEP_CVAR_PRI(arc, damage) * dt, WEP_CVAR_PRI(arc, range));
	WarpZone_traceline_antilag(self.owner, w_shotorg, w_shotend, MOVE_NORMAL, self.owner, ANTILAG_LATENCY(self.owner));

	// apply the damage
	if(trace_ent)
	{
		vector force;
		force = w_shotdir * WEP_CVAR_PRI(arc, force);

		f = ExponentialFalloff(WEP_CVAR_PRI(arc, falloff_mindist), WEP_CVAR_PRI(arc, falloff_maxdist), WEP_CVAR_PRI(arc, falloff_halflifedist), vlen(WarpZone_UnTransformOrigin(WarpZone_trace_transform, trace_endpos) - w_shotorg));

		if(accuracy_isgooddamage(self.owner, trace_ent))
			accuracy_add(self.owner, WEP_ARC, 0, WEP_CVAR_PRI(arc, damage) * dt * f);
		Damage (trace_ent, self.owner, self.owner, WEP_CVAR_PRI(arc, damage) * dt * f, WEP_ARC, trace_endpos, force * dt);
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
void W_Arc_Attack1 (void)
{
	// only play fire sound if 0.5 sec has passed since player let go the fire button
	if(time - self.lg_fire_prev > 0.5)
		sound (self, CH_WEAPON_A, "weapons/lgbeam_fire.wav", VOL_BASE, ATTN_NORM);

	entity beam, oldself;

	self.arc_beam = beam = spawn();
	beam.classname = "W_Arc_Beam";
	beam.solid = SOLID_NOT;
	beam.think = W_Arc_Beam_Think;
	beam.owner = self;
	beam.movetype = MOVETYPE_NONE;
	beam.shot_spread = 1;
	beam.bot_dodge = TRUE;
	beam.bot_dodgerating = WEP_CVAR_PRI(arc, damage);
	Net_LinkEntity(beam, FALSE, 0, W_Arc_Beam_Send);

	oldself = self;
	self = beam;
	self.think();
	self = oldself;
}

float W_Arc(float req)
{
	switch(req)
	{
		case WR_AIM:
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

				if(autocvar_g_balance_arc_primary_speed)
					shoot = bot_aim(autocvar_g_balance_arc_primary_speed, 0, autocvar_g_balance_arc_primary_lifetime, FALSE);
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
				//if(bot_aim(autocvar_g_balance_arc_secondary_speed, autocvar_g_balance_grenadelauncher_secondary_speed_up, autocvar_g_balance_arc_secondary_lifetime, TRUE))
				//{
				//	self.BUTTON_ATCK2 = TRUE;
				//	if(random() < 0.03) self.bot_aim_whichfiretype = 0;
				//}
			}
			*/
			
			return TRUE;
		}
		case WR_THINK:
		{
			if (self.BUTTON_ATCK)
			{
				if(self.BUTTON_ATCK_prev) // TODO: Find another way to implement this!
					/*if(self.animstate_startframe == self.anim_shoot_x && self.animstate_numframes == self.anim_shoot_y)
						weapon_thinkf(WFRAME_DONTCHANGE, autocvar_g_balance_arc_primary_animtime, w_ready);
					else*/
						weapon_thinkf(WFRAME_FIRE1, WEP_CVAR_PRI(arc, animtime), w_ready);
				
				if (weapon_prepareattack(0, 0))
				{
					if ((!self.arc_beam) || wasfreed(self.arc_beam))
						W_Arc_Attack1();
					
					if(!self.BUTTON_ATCK_prev)
					{
						weapon_thinkf(WFRAME_FIRE1, WEP_CVAR_PRI(arc, animtime), w_ready);
						self.BUTTON_ATCK_prev = 1;
					}
				}
			} 
			else // todo
			{
				if (self.BUTTON_ATCK_prev != 0)
				{
					weapon_thinkf(WFRAME_FIRE1, WEP_CVAR_PRI(arc, animtime), w_ready);
					ATTACK_FINISHED(self) = time + WEP_CVAR_PRI(arc, refire) * W_WeaponRateFactor();
				}
				self.BUTTON_ATCK_prev = 0;
			}

			//if (self.BUTTON_ATCK2)
				//if (weapon_prepareattack(1, autocvar_g_balance_arc_secondary_refire))
				//{
				//	W_Arc_Attack2();
				//	self.arc_count = autocvar_g_balance_arc_secondary_count;
				//	weapon_thinkf(WFRAME_FIRE2, autocvar_g_balance_arc_secondary_animtime, w_arc_checkattack);
				//	self.arc_secondarytime = time + autocvar_g_balance_arc_secondary_refire2 * W_WeaponRateFactor();
				//}
				
			return TRUE;
		}
		case WR_INIT:
		{
			precache_model ("models/weapons/g_arc.md3");
			precache_model ("models/weapons/v_arc.md3");
			precache_model ("models/weapons/h_arc.iqm");
			//precache_sound ("weapons/arc_bounce.wav");
			precache_sound ("weapons/arc_fire.wav");
			precache_sound ("weapons/arc_fire2.wav");
			precache_sound ("weapons/arc_impact.wav");
			//precache_sound ("weapons/arc_impact_combo.wav");
			//precache_sound ("weapons/W_Arc_Beam_fire.wav");
			return TRUE;
		}
		case WR_CHECKAMMO1:
		{
			return !WEP_CVAR_PRI(arc, ammo) || (self.WEP_AMMO(WEP_ARC) > 0);
		}
		case WR_CHECKAMMO2:
		{
			return self.WEP_AMMO(WEP_ARC) >= WEP_CVAR_SEC(arc, ammo);
		}
		case WR_CONFIG:
		{
			ARC_SETTINGS(WEP_CONFIG_WRITE_CVARS, WEP_CONFIG_WRITE_PROPS)
			return TRUE;
		}
		case WR_KILLMESSAGE:
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
		case WR_RESETPLAYER:
		{
			//self.arc_secondarytime = time;
			return TRUE;
		}
	}
	return TRUE;
}

void ArcInit()
{
	WEP_ACTION(WEP_ARC, WR_INIT);
	arc_shotorigin[0] = shotorg_adjust_values(CL_Weapon_GetShotOrg(WEP_ARC), FALSE, FALSE, 1);
	arc_shotorigin[1] = shotorg_adjust_values(CL_Weapon_GetShotOrg(WEP_ARC), FALSE, FALSE, 2);
	arc_shotorigin[2] = shotorg_adjust_values(CL_Weapon_GetShotOrg(WEP_ARC), FALSE, FALSE, 3);
	arc_shotorigin[3] = shotorg_adjust_values(CL_Weapon_GetShotOrg(WEP_ARC), FALSE, FALSE, 4);
	ARC_SETTINGS(WEP_SKIPCVAR, WEP_SET_PROP)
}
#endif
#ifdef CSQC
float W_Arc(float req)
{
	switch(req)
	{
		case WR_IMPACTEFFECT:
		{
			vector org2;
			org2 = w_org + w_backoff * 6;
			
			if(w_deathtype & HITTYPE_SECONDARY)
			{
				pointparticles(particleeffectnum("arc_ballexplode"), org2, '0 0 0', 1);
				if(!w_issilent)
					sound(self, CH_SHOTS, "weapons/arc_impact.wav", VOL_BASE, ATTN_NORM);
			}
			else
			{
				pointparticles(particleeffectnum("arc_impact"), org2, '0 0 0', 1);
				if(!w_issilent)
					sound(self, CH_SHOTS, "weapons/arc_impact.wav", VOL_BASE, ATTN_NORM);
			}
			
			return TRUE;
		}
		case WR_INIT:
		{
			precache_sound("weapons/arc_impact.wav");
			precache_sound("weapons/arc_impact_combo.wav");
			return TRUE;
		}
		case WR_ZOOMRETICLE:
		{
			// no weapon specific image for this weapon
			return FALSE;
		}
	}
	return TRUE;
}
#endif
#endif
