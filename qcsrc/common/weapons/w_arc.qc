#ifdef REGISTER_WEAPON
REGISTER_WEAPON(
/* WEP_##id  */ ARC,
/* function  */ W_Arc,
/* ammotype  */ ammo_cells,
/* impulse   */ 3,
/* flags     */ WEP_FLAG_NORMAL,
/* rating    */ BOT_PICKUP_RATING_HIGH,
/* color     */ '1 1 1',
/* modelname */ "hlac",
/* simplemdl */ "foobar",
/* crosshair */ "gfx/crosshairhlac 0.7",
/* wepimg    */ "weaponhlac",
/* refname   */ "arc",
/* wepname   */ _("Arc")
);

#define ARC_SETTINGS(w_cvar,w_prop) ARC_SETTINGS_LIST(w_cvar, w_prop, ARC, arc)
#define ARC_SETTINGS_LIST(w_cvar,w_prop,id,sn) \
	w_cvar(id, sn, BOTH, ammo) \
	w_cvar(id, sn, PRI,  animtime) \
	w_cvar(id, sn, PRI,  damage) \
	w_cvar(id, sn, PRI,  degreespersegment) \
	w_cvar(id, sn, PRI,  distancepersegment) \
	w_cvar(id, sn, PRI,  falloff_halflifedist) \
	w_cvar(id, sn, PRI,  falloff_maxdist) \
	w_cvar(id, sn, PRI,  falloff_mindist) \
	w_cvar(id, sn, PRI,  force) \
	w_cvar(id, sn, PRI,  maxangle) \
	w_cvar(id, sn, PRI,  range) \
	w_cvar(id, sn, PRI,  refire) \
	w_cvar(id, sn, PRI,  returnspeed) \
	w_prop(id, sn, float,  switchdelay_raise, switchdelay_raise) \
	w_prop(id, sn, float,  switchdelay_drop, switchdelay_drop) \
	w_prop(id, sn, string, weaponreplace, weaponreplace) \
	w_prop(id, sn, float,  weaponstart, weaponstart) \
	w_prop(id, sn, float,  weaponstartoverride, weaponstartoverride) \
	w_prop(id, sn, float,  weaponthrowable, weaponthrowable)

#ifndef MENUQC
vector arc_shotorigin[4];
#endif
#ifdef SVQC
ARC_SETTINGS(WEP_ADD_CVAR, WEP_ADD_PROP)
void ArcInit(void);
.vector hook_start, hook_end; // used for beam
.entity arc_beam; // used for beam
.float BUTTON_ATCK_prev; // for better animation control
.float lg_fire_prev; // for better animation control
#endif
#else
#ifdef SVQC
void spawnfunc_weapon_arc(void) { weapon_defaultspawnfunc(WEP_ARC); }

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
#define ARC_DEBUG
#ifdef ARC_DEBUG
#define ARC_MAX_SEGMENTS 20
.entity lg_ents[ARC_MAX_SEGMENTS]; // debug
#endif
.vector beam_dir;
.float beam_initialized;
void W_Arc_Beam_Think(void)
{
	float i;
	//print("W_Arc_Beam_Think();\n");
	if(self != self.owner.arc_beam)
	{
		#ifdef ARC_DEBUG
		print("W_Arc_Beam_Think(): EXPIRING BEAM #1\n");
		#endif
		remove(self);
		return;
	}
	if((self.owner.WEP_AMMO(ARC) <= 0 && !(self.owner.items & IT_UNLIMITED_WEAPON_AMMO)) || self.owner.deadflag != DEAD_NO || !self.owner.BUTTON_ATCK || self.owner.freezetag_frozen)
	{
		if(self == self.owner.arc_beam) { self.owner.arc_beam = world; } // is this needed? I thought this is changed to world when removed ANYWAY
		#ifdef ARC_DEBUG
		if(self.lg_ents[0])
		{
			for(i = 0; i < ARC_MAX_SEGMENTS; ++i)
				remove(self.lg_ents[i]);
		}
		print("W_Arc_Beam_Think(): EXPIRING BEAM #2\n");
		#endif
		remove(self);
		return;
	}

	// decrease ammo
	float dt = frametime;
	if(!(self.owner.items & IT_UNLIMITED_WEAPON_AMMO))
	{
		if(WEP_CVAR_PRI(arc, ammo))
		{
			dt = min(dt, self.owner.WEP_AMMO(ARC) / WEP_CVAR_PRI(arc, ammo));
			self.owner.WEP_AMMO(ARC) = max(0, self.owner.WEP_AMMO(ARC) - WEP_CVAR_PRI(arc, ammo) * frametime);
		}
	}

	makevectors(self.owner.v_angle);
	
	W_SetupShot_Range(self.owner, TRUE, 0, "", 0, WEP_CVAR_PRI(arc, damage) * dt, WEP_CVAR_PRI(arc, range));
	//WarpZone_traceline_antilag(self.owner, w_shotorg, w_shotend, MOVE_NORMAL, self.owner, ANTILAG_LATENCY(self.owner));

	vector want_dir = w_shotdir;
	//vector want_pos = w_shotend;

	if(!self.beam_initialized)
	{
		#ifdef ARC_DEBUG
		for(i = 0; i < ARC_MAX_SEGMENTS; ++i)
			self.lg_ents[i] = spawn();
		#endif
		
		self.beam_dir = want_dir;
		self.beam_initialized = TRUE;
	}

	//vector newdir;
	//vector direction_to_want_pos = normalize(want_pos - w_shotorg);
	//float distance_to_want_pos = vlen(want_pos - w_shotorg);
	//printf("distance_to_want_pos: %f\n", distance_to_want_pos);
	float segments; 
	if(self.beam_dir != want_dir)
	{
		//vector direction_to_beam_pos = normalize(self.beam_endpos - w_shotorg);

		float angle = ceil(vlen(want_dir - self.beam_dir) * RAD2DEG);
		float anglelimit;
		if(angle && (angle > WEP_CVAR_PRI(arc, maxangle)))
		{
			// if the angle is greater than maxangle, force the blendfactor to make this the maximum factor
			#ifdef ARC_DEBUG
			printf("Correcting max angle: %f %f\n", angle, WEP_CVAR_PRI(arc, distancepersegment));
			#endif
			anglelimit = min(WEP_CVAR_PRI(arc, maxangle) / angle, 1);
		}
		else
		{
			// the radius is not too far yet, no worries :D
			anglelimit = 1;
		}
		
		float blendfactor = bound(0, anglelimit * (1 - (WEP_CVAR_PRI(arc, returnspeed) * dt)), 1);

		self.beam_dir = normalize((want_dir * (1 - blendfactor)) + (self.beam_dir * blendfactor));
		//self.beam_endpos = w_shotorg + (newdir * distance_to_want_pos);

		float max_allowed_segments = ARC_MAX_SEGMENTS;

		//if(WEP_CVAR_PRI(arc, distancepersegment))
		//	max_allowed_segments = min(ARC_MAX_SEGMENTS, 1 + (distance_to_want_pos / WEP_CVAR_PRI(arc, distancepersegment)));
		//else
		//	max_allowed_segments = ARC_MAX_SEGMENTS;

		// this is where we calculate how many segments are needed
		if(WEP_CVAR_PRI(arc, degreespersegment))
		{
			segments = min( max(1, ( min(angle, WEP_CVAR_PRI(arc, maxangle)) / WEP_CVAR_PRI(arc, degreespersegment) ) ), max_allowed_segments );
			//segments = min( min(angle, WEP_CVAR_PRI(arc, maxangle)) / WEP_CVAR_PRI(arc, degreespersegment), max_allowed_segments );
		}
		else { segments = 1; }
	}
	else
	{
		segments = 1;
	}

	vector beam_endpos_estimate = (w_shotorg + (self.beam_dir * WEP_CVAR_PRI(arc, range)));
	//te_customflash(beam_endpos_estimate, 40, 2, '1 1 1');

	#ifdef ARC_DEBUG
	printf("segment count: %d\n", segments);
	float hit_something = FALSE;
	#endif
	float segmentdist; // = WEP_CVAR_PRI(arc, range) / segments; // = vlen(self.beam_endpos - last_origin) * (1/segments);
	float segmentblend;// = (1/segments);
	vector last_origin = w_shotorg;
	for(i = 1; i <= segments; ++i)
	{
		segmentblend = (i/segments);
		segmentdist = vlen(beam_endpos_estimate - last_origin) * (i/segments);
		//direction_to_want_pos = normalize(self.beam_endpos - last_origin);
		vector blended = normalize((want_dir * (1 - segmentblend)) + (normalize(beam_endpos_estimate - last_origin) * segmentblend));
		vector new_origin = last_origin + (blended * segmentdist);

		WarpZone_traceline_antilag(self.owner, last_origin, new_origin, MOVE_NORMAL, self.owner, ANTILAG_LATENCY(self.owner));
		
		if(trace_ent)
		{
			//vector attackend = (last_origin * (1 - trace_fraction) + new_origin * trace_fraction); // trace_endpos jumps weirdly with playermodels... 
			float falloff = ExponentialFalloff(
				WEP_CVAR_PRI(arc, falloff_mindist),
				WEP_CVAR_PRI(arc, falloff_maxdist),
				WEP_CVAR_PRI(arc, falloff_halflifedist),
				vlen(WarpZone_UnTransformOrigin(WarpZone_trace_transform, trace_endpos) - w_shotorg)
			);

			if(accuracy_isgooddamage(self.owner, trace_ent))
				accuracy_add(self.owner, WEP_ARC, 0, WEP_CVAR_PRI(arc, damage) * dt * falloff);

			Damage(
				trace_ent,
				self.owner,
				self.owner,
				WEP_CVAR_PRI(arc, damage) * dt * falloff,
				WEP_ARC,
				trace_endpos,
				(blended * WEP_CVAR_PRI(arc, force)) * dt * falloff
			);

			#ifdef ARC_DEBUG
			te_lightning1(self.lg_ents[i - 1], last_origin, trace_endpos);
			te_customflash(trace_endpos, 80, 5, '1 0 0');
			hit_something = TRUE;
			#endif
			break; 
		}
		else if(trace_fraction != 1)
		{
			// we collided with geometry
			#ifdef ARC_DEBUG
			te_lightning1(self.lg_ents[i - 1], last_origin, trace_endpos);
			te_customflash(trace_endpos, 40, 2, '0 0 1');
			#endif
			break;
		}
		else
		{
			#ifdef ARC_DEBUG
			te_lightning1(self.lg_ents[i - 1], last_origin, new_origin);
			#endif
			last_origin = new_origin;
		}
	}

	#ifdef ARC_DEBUG
	if(!hit_something)
	{
		te_customflash(trace_endpos, 40, 2, '1 1 1');
	}
	#endif

	// draw effect
	/*if(w_shotorg != self.hook_start)
	{
		self.SendFlags |= 2;
		self.hook_start = w_shotorg;
	}
	if(w_shotend != self.hook_end)
	{
		self.SendFlags |= 4;
		self.hook_end = w_shotend;
	}*/

	self.owner.lg_fire_prev = time;
	self.nextthink = time;
}

// Attack functions ========================= 
void W_Arc_Beam(void)
{
	print("W_Arc_Beam();\n");
	// only play fire sound if 0.5 sec has passed since player let go the fire button
	if(time - self.lg_fire_prev > 0.5)
		sound(self, CH_WEAPON_A, "weapons/lgbeam_fire.wav", VOL_BASE, ATTN_NORM);

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
	//Net_LinkEntity(beam, FALSE, 0, W_Arc_Beam_Send);

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
			if(self.BUTTON_ATCK)
			{
				if(self.BUTTON_ATCK_prev) // TODO: Find another way to implement this!
					/*if(self.animstate_startframe == self.anim_shoot_x && self.animstate_numframes == self.anim_shoot_y)
						weapon_thinkf(WFRAME_DONTCHANGE, autocvar_g_balance_arc_primary_animtime, w_ready);
					else*/
						weapon_thinkf(WFRAME_FIRE1, WEP_CVAR_PRI(arc, animtime), w_ready);
				
				if(weapon_prepareattack(0, 0))
				{
					if((!self.arc_beam) || wasfreed(self.arc_beam))
						W_Arc_Beam();
					
					if(!self.BUTTON_ATCK_prev)
					{
						weapon_thinkf(WFRAME_FIRE1, WEP_CVAR_PRI(arc, animtime), w_ready);
						self.BUTTON_ATCK_prev = 1;
					}
				}
			} 
			else // todo
			{
				if(self.BUTTON_ATCK_prev != 0)
				{
					weapon_thinkf(WFRAME_FIRE1, WEP_CVAR_PRI(arc, animtime), w_ready);
					ATTACK_FINISHED(self) = time + WEP_CVAR_PRI(arc, refire) * W_WeaponRateFactor();
				}
				self.BUTTON_ATCK_prev = 0;
			}

			//if(self.BUTTON_ATCK2)
				//if(weapon_prepareattack(1, autocvar_g_balance_arc_secondary_refire))
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
			precache_model("models/weapons/g_arc.md3");
			precache_model("models/weapons/v_arc.md3");
			precache_model("models/weapons/h_arc.iqm");
			//precache_sound("weapons/arc_bounce.wav");
			precache_sound("weapons/arc_fire.wav");
			precache_sound("weapons/arc_fire2.wav");
			precache_sound("weapons/arc_impact.wav");
			//precache_sound("weapons/arc_impact_combo.wav");
			//precache_sound("weapons/W_Arc_Beam_fire.wav");
			return TRUE;
		}
		case WR_CHECKAMMO1:
		{
			return !WEP_CVAR_PRI(arc, ammo) || (self.WEP_AMMO(ARC) > 0);
		}
		case WR_CHECKAMMO2:
		{
			return self.WEP_AMMO(ARC) >= WEP_CVAR_SEC(arc, ammo);
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
	return FALSE;
}

void ArcInit(void)
{
	WEP_ACTION(WEP_ARC, WR_INIT);
	arc_shotorigin[0] = shotorg_adjust_values(CL_Weapon_GetShotOrg(WEP_ARC), FALSE, FALSE, 1);
	arc_shotorigin[1] = shotorg_adjust_values(CL_Weapon_GetShotOrg(WEP_ARC), FALSE, FALSE, 2);
	arc_shotorigin[2] = shotorg_adjust_values(CL_Weapon_GetShotOrg(WEP_ARC), FALSE, FALSE, 3);
	arc_shotorigin[3] = shotorg_adjust_values(CL_Weapon_GetShotOrg(WEP_ARC), FALSE, FALSE, 4);
	ARC_SETTINGS(WEP_SKIP_CVAR, WEP_SET_PROP)
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
	return FALSE;
}
#endif
#endif
