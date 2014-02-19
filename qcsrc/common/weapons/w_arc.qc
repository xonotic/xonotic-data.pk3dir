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
	w_cvar(id, sn, NONE, beam_ammo) \
	w_cvar(id, sn, NONE, beam_animtime) \
	w_cvar(id, sn, NONE, beam_botaimspeed) \
	w_cvar(id, sn, NONE, beam_botaimlifetime) \
	w_cvar(id, sn, NONE, beam_damage) \
	w_cvar(id, sn, NONE, beam_degreespersegment) \
	w_cvar(id, sn, NONE, beam_distancepersegment) \
	w_cvar(id, sn, NONE, beam_falloff_halflifedist) \
	w_cvar(id, sn, NONE, beam_falloff_maxdist) \
	w_cvar(id, sn, NONE, beam_falloff_mindist) \
	w_cvar(id, sn, NONE, beam_force) \
	w_cvar(id, sn, NONE, beam_maxangle) \
	w_cvar(id, sn, NONE, beam_nonplayerdamage) \
	w_cvar(id, sn, NONE, beam_range) \
	w_cvar(id, sn, NONE, beam_refire) \
	w_cvar(id, sn, NONE, beam_returnspeed) \
	w_cvar(id, sn, NONE, beam_tightness) \
	w_prop(id, sn, float,  switchdelay_raise, switchdelay_raise) \
	w_prop(id, sn, float,  switchdelay_drop, switchdelay_drop) \
	w_prop(id, sn, string, weaponreplace, weaponreplace) \
	w_prop(id, sn, float,  weaponstart, weaponstart) \
	w_prop(id, sn, float,  weaponstartoverride, weaponstartoverride) \
	w_prop(id, sn, float,  weaponthrowable, weaponthrowable)

#ifndef MENUQC
vector arc_shotorigin[4];
.vector beam_start;
.vector beam_dir;
.vector beam_wantdir;
.float beam_type;
#define ARC_BT_MISS        0
#define ARC_BT_WALL        1
#define ARC_BT_HEAL        2
#define ARC_BT_HIT         3
#define ARC_BT_BURST_MISS  10
#define ARC_BT_BURST_WALL  11
#define ARC_BT_BURST_HEAL  12
#define ARC_BT_BURST_HIT   13
#define ARC_BT_BURSTMASK   10
#endif
#ifdef SVQC
#define ARC_MAX_SEGMENTS 20
ARC_SETTINGS(WEP_ADD_CVAR, WEP_ADD_PROP)
void ArcInit(void);
.entity arc_beam; // used for beam
.float BUTTON_ATCK_prev; // for better animation control
.float lg_fire_prev; // for better animation control
.float beam_initialized;
#endif
#else
#ifdef SVQC
void spawnfunc_weapon_arc(void) { weapon_defaultspawnfunc(WEP_ARC); }

float W_Arc_Beam_Send(entity to, float sf)
{
	WriteByte(MSG_ENTITY, ENT_CLIENT_ARC_BEAM);

	// Truncate information when this beam is displayed to the owner client
	// - The owner client has no use for beam start position or directions,
	//    it always figures this information out for itself with csqc code.
	// - Spectating the owner also truncates this information.
	float drawlocal = ((to == self.owner) || ((to.enemy == self.owner) && IS_SPEC(to)));
	if(drawlocal)
	{
		#if 0
		sf &= ~2;
		sf &= ~4;
		sf &= ~8;
		#else
		sf &= ~14;
		#endif
	}

	WriteByte(MSG_ENTITY, sf);

	if(sf & 1) // settings information
	{
		WriteShort(MSG_ENTITY, WEP_CVAR(arc, beam_maxangle));
		WriteCoord(MSG_ENTITY, WEP_CVAR(arc, beam_range));
		WriteShort(MSG_ENTITY, WEP_CVAR(arc, beam_returnspeed));
		WriteByte(MSG_ENTITY, WEP_CVAR(arc, beam_tightness) * 10);

		WriteByte(MSG_ENTITY, drawlocal);
	}
	if(sf & 2) // starting location
	{
		WriteCoord(MSG_ENTITY, self.beam_start_x);
		WriteCoord(MSG_ENTITY, self.beam_start_y);
		WriteCoord(MSG_ENTITY, self.beam_start_z);
	}
	if(sf & 4) // want/aim direction
	{
		WriteCoord(MSG_ENTITY, self.beam_wantdir_x);
		WriteCoord(MSG_ENTITY, self.beam_wantdir_y);
		WriteCoord(MSG_ENTITY, self.beam_wantdir_z);
	}
	if(sf & 8) // beam direction
	{
		WriteCoord(MSG_ENTITY, self.beam_dir_x);
		WriteCoord(MSG_ENTITY, self.beam_dir_y);
		WriteCoord(MSG_ENTITY, self.beam_dir_z);
	}
	if(sf & 16) // beam type
	{
		WriteByte(MSG_ENTITY, self.beam_type);
	}

	return TRUE;
}

void W_Arc_Beam_Think(void)
{
	float i, burst = 0;
	if(self != self.owner.arc_beam)
	{
		remove(self);
		return;
	}
	if((self.owner.WEP_AMMO(ARC) <= 0 && !(self.owner.items & IT_UNLIMITED_WEAPON_AMMO)) || self.owner.deadflag != DEAD_NO || !self.owner.BUTTON_ATCK || self.owner.freezetag_frozen)
	{
		if(self == self.owner.arc_beam) { self.owner.arc_beam = world; } // is this needed? I thought this is changed to world when removed ANYWAY
		remove(self);
		return;
	}

	if(self.owner.BUTTON_ATCK2)
	{
		burst = ARC_BT_BURSTMASK;
	}

	// decrease ammo // todo: support burst ammo
	float dt = frametime;
	if(!(self.owner.items & IT_UNLIMITED_WEAPON_AMMO))
	{
		if(WEP_CVAR(arc, beam_ammo))
		{
			dt = min(dt, self.owner.WEP_AMMO(ARC) / WEP_CVAR(arc, beam_ammo));
			self.owner.WEP_AMMO(ARC) = max(0, self.owner.WEP_AMMO(ARC) - WEP_CVAR(arc, beam_ammo) * frametime);
		}
	}

	makevectors(self.owner.v_angle);

	W_SetupShot_Range(self.owner, TRUE, 0, "", 0, WEP_CVAR(arc, beam_damage) * dt, WEP_CVAR(arc, beam_range));

	// network information: shot origin and want/aim direction
	if(self.beam_start != w_shotorg)
	{
		self.SendFlags |= 2;
		self.beam_start = w_shotorg;
	}
	if(self.beam_wantdir != w_shotdir)
	{
		self.SendFlags |= 4;
		self.beam_wantdir = w_shotdir;
	}

	if(!self.beam_initialized)
	{
		#ifdef ARC_DEBUG
		for(i = 0; i < ARC_MAX_SEGMENTS; ++i)
			self.lg_ents[i] = spawn();
		#endif
		
		self.beam_dir = w_shotdir;
		self.beam_initialized = TRUE;
	}

	float segments; 
	if(self.beam_dir != w_shotdir)
	{
		float angle = ceil(vlen(w_shotdir - self.beam_dir) * RAD2DEG);
		float anglelimit;
		if(angle && (angle > WEP_CVAR(arc, beam_maxangle)))
		{
			// if the angle is greater than maxangle, force the blendfactor to make this the maximum factor
			anglelimit = min(WEP_CVAR(arc, beam_maxangle) / angle, 1);
		}
		else
		{
			// the radius is not too far yet, no worries :D
			anglelimit = 1;
		}

		// calculate how much we're going to move the end of the beam to the want position
		float blendfactor = bound(0, anglelimit * (1 - (WEP_CVAR(arc, beam_returnspeed) * dt)), 1);
		self.beam_dir = normalize((w_shotdir * (1 - blendfactor)) + (self.beam_dir * blendfactor));

		// todo: figure out a way so that blendfactor becomes 0 at some point,
		// currently self.beam_dir and w_shotdir never really become equal as there is no rounding/snapping point
		// printf("blendfactor = %f\n", blendfactor);

		// network information: beam direction
		self.SendFlags |= 8;

		// calculate how many segments are needed
		float max_allowed_segments;

		if(WEP_CVAR(arc, beam_distancepersegment))
			max_allowed_segments = min(ARC_MAX_SEGMENTS, 1 + (vlen(w_shotdir / WEP_CVAR(arc, beam_distancepersegment))));
		else
			max_allowed_segments = ARC_MAX_SEGMENTS;

		if(WEP_CVAR(arc, beam_degreespersegment))
		{
			segments = min( max(1, ( min(angle, WEP_CVAR(arc, beam_maxangle)) / WEP_CVAR(arc, beam_degreespersegment) ) ), max_allowed_segments );
		}
		else { segments = 1; }
	}
	else
	{
		segments = 1;
	}

	vector beam_endpos_estimate = (w_shotorg + (self.beam_dir * WEP_CVAR(arc, beam_range)));

	float new_beam_type = 0;
	vector last_origin = w_shotorg;
	for(i = 1; i <= segments; ++i)
	{
		// WEAPONTODO (server and client):
		// Segment blend and distance should probably really be calculated in a better way,
		// however I am not sure how to do it properly. There are a few things I have tried,
		// but most of them do not work properly due to my lack of understanding regarding
		// the mathematics behind them.

		// Ideally, we should calculate the positions along a perfect curve
		// between wantdir and self.beam_dir with an option for depth of arc

		// Another issue is that (on the client code) we must separate the
		// curve into multiple rendered curves when handling warpzones.
		
		// I can handle this by detecting it for each segment, however that
		// is a fairly inefficient method in comparison to having a curved line
		// drawing function similar to Draw_CylindricLine that accepts
		// top and bottom origins as input, this way there would be no
		// overlapping edges when connecting the curved pieces.

		// WEAPONTODO (client):
		// In order to do nice fading and pointing on the starting segment, we must always
		// have that drawn as a separate triangle... However, that is difficult to do when
		// keeping in mind the above problems and also optimizing the amount of segments
		// drawn on screen at any given time. (Automatic beam quality scaling, essentially)

		// calculate this on every segment to ensure that we always reach the full length of the attack
		float segmentblend = bound(0, (i/segments) + WEP_CVAR(arc, beam_tightness), 1);
		float segmentdist = vlen(beam_endpos_estimate - last_origin) * (i/segments);

		vector new_dir = normalize( (w_shotdir * (1 - segmentblend)) + (normalize(beam_endpos_estimate - last_origin) * segmentblend) );
		vector new_origin = last_origin + (new_dir * segmentdist);

		WarpZone_traceline_antilag(
			self.owner,
			last_origin,
			new_origin,
			MOVE_NORMAL,
			self.owner,
			ANTILAG_LATENCY(self.owner)
		);

		float is_player = (trace_ent.classname == "player" || trace_ent.classname == "body" || (trace_ent.flags & FL_MONSTER));
		if(trace_ent && trace_ent.takedamage && (is_player || WEP_CVAR(arc, beam_nonplayerdamage)))
		{
			// calculate our own hit origin as trace_endpos tends to jump around annoyingly (to player origin?)
			vector hitorigin = last_origin + (new_dir * segmentdist * trace_fraction);

			float falloff = ExponentialFalloff(
				WEP_CVAR(arc, beam_falloff_mindist),
				WEP_CVAR(arc, beam_falloff_maxdist),
				WEP_CVAR(arc, beam_falloff_halflifedist),
				vlen(WarpZone_UnTransformOrigin(WarpZone_trace_transform, hitorigin) - w_shotorg)
			);

			if(is_player && SAME_TEAM(self.owner, trace_ent))
			{
				// hit a team mate heal them now
				new_beam_type = ARC_BT_HEAL;
			}
			else
			{
				float rootdamage;
				if(is_player)
					rootdamage = WEP_CVAR(arc, beam_damage);
				else
					rootdamage = WEP_CVAR(arc, beam_nonplayerdamage);

				if(accuracy_isgooddamage(self.owner, trace_ent))
				{
					accuracy_add(
						self.owner,
						WEP_ARC,
						0,
						rootdamage * dt * falloff
					);
				}

				Damage(
					trace_ent,
					self.owner,
					self.owner,
					rootdamage * dt * falloff,
					WEP_ARC,
					hitorigin,
					WEP_CVAR(arc, beam_force) * new_dir * dt * falloff
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
		else
		{
			last_origin = new_origin;
		}
	}

	// if we're bursting, use burst visual effects
	new_beam_type += burst;

	// network information: beam type
	if(new_beam_type != self.beam_type)
	{
		self.SendFlags |= 16;
		self.beam_type = new_beam_type;
	}

	self.owner.lg_fire_prev = time;
	self.nextthink = time;
}

// Attack functions ========================= 
void W_Arc_Beam(void)
{
	print("W_Arc_Beam();\n");
	// only play fire sound if 1 sec has passed since player let go the fire button
	if(time - self.lg_fire_prev > 1)
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
	beam.bot_dodgerating = WEP_CVAR(arc, beam_damage);
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
			if(WEP_CVAR(arc, beam_botaimspeed))
				self.BUTTON_ATCK = bot_aim(WEP_CVAR(arc, beam_botaimspeed), 0, WEP_CVAR(arc, beam_botaimlifetime), FALSE);
			else
				self.BUTTON_ATCK = bot_aim(1000000, 0, 0.001, FALSE);
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
						weapon_thinkf(WFRAME_FIRE1, WEP_CVAR(arc, beam_animtime), w_ready);
				
				if(weapon_prepareattack(0, 0))
				{
					if((!self.arc_beam) || wasfreed(self.arc_beam))
						W_Arc_Beam();
					
					if(!self.BUTTON_ATCK_prev)
					{
						weapon_thinkf(WFRAME_FIRE1, WEP_CVAR(arc, beam_animtime), w_ready);
						self.BUTTON_ATCK_prev = 1;
					}
				}
			} 
			else // todo
			{
				if(self.BUTTON_ATCK_prev != 0)
				{
					weapon_thinkf(WFRAME_FIRE1, WEP_CVAR(arc, beam_animtime), w_ready);
					ATTACK_FINISHED(self) = time + WEP_CVAR(arc, beam_refire) * W_WeaponRateFactor();
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
			return !WEP_CVAR(arc, beam_ammo) || (self.WEP_AMMO(ARC) > 0);
		}
		case WR_CHECKAMMO2:
		{
			//return self.WEP_AMMO(ARC) >= WEP_CVAR_SEC(arc, ammo);
			return TRUE;
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
