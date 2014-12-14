#ifdef REGISTER_WEAPON
REGISTER_WEAPON(
/* WEP_##id  */ VAPORIZER,
/* function  */ W_Vaporizer,
/* ammotype  */ ammo_cells,
/* impulse   */ 7,
/* flags     */ WEP_FLAG_RELOADABLE | WEP_FLAG_CANCLIMB | WEP_FLAG_SUPERWEAPON | WEP_TYPE_HITSCAN,
/* rating    */ BOT_PICKUP_RATING_HIGH,
/* color     */ '0.5 1 1',
/* modelname */ "minstanex",
/* simplemdl */ "foobar",
/* crosshair */ "gfx/crosshairminstanex 0.4",
/* wepimg    */ "weaponminstanex",
/* refname   */ "vaporizer",
/* wepname   */ _("Vaporizer")
);

#define VAPORIZER_SETTINGS(w_cvar,w_prop) VAPORIZER_SETTINGS_LIST(w_cvar, w_prop, VAPORIZER, vaporizer)
#define VAPORIZER_SETTINGS_LIST(w_cvar,w_prop,id,sn) \
	w_cvar(id, sn, PRI, ammo) \
	w_cvar(id, sn, PRI, animtime) \
	w_cvar(id, sn, PRI, refire) \
	w_cvar(id, sn, SEC, ammo) \
	w_cvar(id, sn, SEC, animtime) \
	w_cvar(id, sn, SEC, damage) \
	w_cvar(id, sn, SEC, delay) \
	w_cvar(id, sn, SEC, edgedamage) \
	w_cvar(id, sn, SEC, force) \
	w_cvar(id, sn, SEC, lifetime) \
	w_cvar(id, sn, SEC, radius) \
	w_cvar(id, sn, SEC, refire) \
	w_cvar(id, sn, SEC, shotangle) \
	w_cvar(id, sn, SEC, speed) \
	w_cvar(id, sn, SEC, spread) \
	w_prop(id, sn, float,  reloading_ammo, reload_ammo) \
	w_prop(id, sn, float,  reloading_time, reload_time) \
	w_prop(id, sn, float,  switchdelay_raise, switchdelay_raise) \
	w_prop(id, sn, float,  switchdelay_drop, switchdelay_drop) \
	w_prop(id, sn, string, weaponreplace, weaponreplace) \
	w_prop(id, sn, float,  weaponstart, weaponstart) \
	w_prop(id, sn, float,  weaponstartoverride, weaponstartoverride) \
	w_prop(id, sn, float,  weaponthrowable, weaponthrowable)

#ifdef SVQC
VAPORIZER_SETTINGS(WEP_ADD_CVAR, WEP_ADD_PROP)
.float vaporizer_lasthit;
.float jump_interval;
#endif
#else
#ifdef SVQC
void spawnfunc_weapon_vaporizer(void) { weapon_defaultspawnfunc(WEP_VAPORIZER); }
void spawnfunc_weapon_minstanex(void) { spawnfunc_weapon_vaporizer(); }

void W_Vaporizer_Attack(void)
{
	float flying;
	flying = IsFlying(self); // do this BEFORE to make the trace values from FireRailgunBullet last

	W_SetupShot(self, TRUE, 0, "", CH_WEAPON_A, 10000);
	// handle sound separately so we can change the volume
	// added bonus: no longer plays the strength sound (strength gives no bonus to instakill anyway)
	sound (self, CH_WEAPON_A, "weapons/minstanexfire.wav", VOL_BASE * 0.8, ATTEN_NORM);

	yoda = 0;
	damage_goodhits = 0;
	FireRailgunBullet(w_shotorg, w_shotorg + w_shotdir * MAX_SHOT_DISTANCE, 10000, 800, 0, 0, 0, 0, WEP_VAPORIZER);

	if(yoda && flying)
		Send_Notification(NOTIF_ONE, self, MSG_ANNCE, ANNCE_ACHIEVEMENT_YODA);
	if(damage_goodhits && self.vaporizer_lasthit)
	{
		Send_Notification(NOTIF_ONE, self, MSG_ANNCE, ANNCE_ACHIEVEMENT_IMPRESSIVE);
		damage_goodhits = 0; // only every second time
	}

	self.vaporizer_lasthit = damage_goodhits;

	pointparticles(particleeffectnum("nex_muzzleflash"), w_shotorg, w_shotdir * 1000, 1);

	// teamcolor / hit beam effect
	vector v;
	v = WarpZone_UnTransformOrigin(WarpZone_trace_transform, trace_endpos);
	switch(self.team)
	{
		case NUM_TEAM_1:   // Red
			if(damage_goodhits)
				WarpZone_TrailParticles(world, particleeffectnum("TE_TEI_G3RED_HIT"), w_shotorg, v);
			else
				WarpZone_TrailParticles(world, particleeffectnum("TE_TEI_G3RED"), w_shotorg, v);
			break;
		case NUM_TEAM_2:   // Blue
			if(damage_goodhits)
				WarpZone_TrailParticles(world, particleeffectnum("TE_TEI_G3BLUE_HIT"), w_shotorg, v);
			else
				WarpZone_TrailParticles(world, particleeffectnum("TE_TEI_G3BLUE"), w_shotorg, v);
			break;
		case NUM_TEAM_3:   // Yellow
			if(damage_goodhits)
				WarpZone_TrailParticles(world, particleeffectnum("TE_TEI_G3YELLOW_HIT"), w_shotorg, v);
			else
				WarpZone_TrailParticles(world, particleeffectnum("TE_TEI_G3YELLOW"), w_shotorg, v);
			break;
		case NUM_TEAM_4:   // Pink
			if(damage_goodhits)
				WarpZone_TrailParticles(world, particleeffectnum("TE_TEI_G3PINK_HIT"), w_shotorg, v);
			else
				WarpZone_TrailParticles(world, particleeffectnum("TE_TEI_G3PINK"), w_shotorg, v);
			break;
		default:
			if(damage_goodhits)
				WarpZone_TrailParticles(world, particleeffectnum("TE_TEI_G3_HIT"), w_shotorg, v);
			else
				WarpZone_TrailParticles(world, particleeffectnum("TE_TEI_G3"), w_shotorg, v);
			break;
	}
	
	W_DecreaseAmmo(((g_instagib) ? 1 : WEP_CVAR_PRI(vaporizer, ammo)));
}

float W_Vaporizer(float req)
{
	float ammo_amount;
	float vaporizer_ammo;

	// now multiple WR_s use this
	vaporizer_ammo = ((g_instagib) ? 1 : WEP_CVAR_PRI(vaporizer, ammo));

	switch(req)
	{
		case WR_AIM:
		{
			if(self.WEP_AMMO(VAPORIZER) > 0)
				self.BUTTON_ATCK = bot_aim(1000000, 0, 1, FALSE);
			else
				self.BUTTON_ATCK2 = bot_aim(WEP_CVAR_SEC(vaporizer, speed), 0, WEP_CVAR_SEC(vaporizer, lifetime), FALSE); // WEAPONTODO: replace with proper vaporizer cvars
				
			return TRUE;
		}
		case WR_THINK:
		{
			// if the laser uses load, we also consider its ammo for reloading
			if(WEP_CVAR(vaporizer, reload_ammo) && WEP_CVAR_SEC(vaporizer, ammo) && self.clip_load < min(vaporizer_ammo, WEP_CVAR_SEC(vaporizer, ammo))) // forced reload
				WEP_ACTION(self.weapon, WR_RELOAD);
			else if(WEP_CVAR(vaporizer, reload_ammo) && self.clip_load < vaporizer_ammo) // forced reload
				WEP_ACTION(self.weapon, WR_RELOAD);
			else if(self.BUTTON_ATCK)
			{
				if(weapon_prepareattack(0, WEP_CVAR_PRI(vaporizer, refire)))
				{
					W_Vaporizer_Attack();
					weapon_thinkf(WFRAME_FIRE1, WEP_CVAR_PRI(vaporizer, animtime), w_ready);
				}
			}
			else if(self.BUTTON_ATCK2)
			{
				if(self.jump_interval <= time)
				if(weapon_prepareattack(1, -1))
				{
					// handle refire manually, so that primary and secondary can be fired without conflictions (important for instagib)
					self.jump_interval = time + WEP_CVAR_SEC(vaporizer, refire) * W_WeaponRateFactor();
					
					// decrease ammo for the laser?
					if(WEP_CVAR_SEC(vaporizer, ammo))
						W_DecreaseAmmo(WEP_CVAR_SEC(vaporizer, ammo));

					// ugly instagib hack to reuse the fire mode of the laser
					W_Blaster_Attack(
						WEP_VAPORIZER | HITTYPE_SECONDARY,
						WEP_CVAR_SEC(vaporizer, shotangle),
						WEP_CVAR_SEC(vaporizer, damage),
						WEP_CVAR_SEC(vaporizer, edgedamage),
						WEP_CVAR_SEC(vaporizer, radius),
						WEP_CVAR_SEC(vaporizer, force),
						WEP_CVAR_SEC(vaporizer, speed),
						WEP_CVAR_SEC(vaporizer, spread),
						WEP_CVAR_SEC(vaporizer, delay),
						WEP_CVAR_SEC(vaporizer, lifetime)
					);
					
					// now do normal refire
					weapon_thinkf(WFRAME_FIRE2, WEP_CVAR_SEC(vaporizer, animtime), w_ready);
				}
			}
			
			return TRUE;
		}
		case WR_INIT:
		{
			precache_model("models/nexflash.md3");
			precache_model("models/weapons/g_minstanex.md3");
			precache_model("models/weapons/v_minstanex.md3");
			precache_model("models/weapons/h_minstanex.iqm");
			precache_sound("weapons/minstanexfire.wav");
			precache_sound("weapons/nexwhoosh1.wav");
			precache_sound("weapons/nexwhoosh2.wav");
			precache_sound("weapons/nexwhoosh3.wav");
			//W_Blaster(WR_INIT); // Samual: Is this really the proper thing to do? Didn't we already run this previously?
			VAPORIZER_SETTINGS(WEP_SKIP_CVAR, WEP_SET_PROP)
			return TRUE;
		}
		case WR_SETUP:
		{
			self.ammo_field = WEP_AMMO(VAPORIZER);
			self.vaporizer_lasthit = 0;
			return TRUE;
		}
		case WR_CHECKAMMO1:
		{
			ammo_amount = self.WEP_AMMO(VAPORIZER) >= vaporizer_ammo;
			ammo_amount += self.(weapon_load[WEP_VAPORIZER]) >= vaporizer_ammo;
			return ammo_amount;
		}
		case WR_CHECKAMMO2:
		{
			if(!WEP_CVAR_SEC(vaporizer, ammo))
				return TRUE;
			ammo_amount = self.WEP_AMMO(VAPORIZER) >= WEP_CVAR_SEC(vaporizer, ammo);
			ammo_amount += self.(weapon_load[WEP_VAPORIZER]) >= WEP_CVAR_SEC(vaporizer, ammo);
			return ammo_amount;
		}
		case WR_CONFIG:
		{
			VAPORIZER_SETTINGS(WEP_CONFIG_WRITE_CVARS, WEP_CONFIG_WRITE_PROPS)
			return TRUE;
		}
		case WR_RESETPLAYER:
		{
			self.vaporizer_lasthit = 0;
			return TRUE;
		}
		case WR_RELOAD:
		{
			float used_ammo;
			if(WEP_CVAR_SEC(vaporizer, ammo))
				used_ammo = min(vaporizer_ammo, WEP_CVAR_SEC(vaporizer, ammo));
			else
				used_ammo = vaporizer_ammo;

			W_Reload(used_ammo, "weapons/reload.wav");
			return TRUE;
		}
		case WR_SUICIDEMESSAGE:
		{
			return WEAPON_THINKING_WITH_PORTALS;
		}
		case WR_KILLMESSAGE:
		{
			return WEAPON_VAPORIZER_MURDER;
		}
	}
	return FALSE;
}
#endif
#ifdef CSQC
float W_Vaporizer(float req)
{
	switch(req)
	{
		case WR_IMPACTEFFECT:
		{
			vector org2;
			org2 = w_org + w_backoff * 6;
			if(w_deathtype & HITTYPE_SECONDARY)
			{
				pointparticles(particleeffectnum("laser_impact"), org2, w_backoff * 1000, 1);
				if(!w_issilent) { sound(self, CH_SHOTS, "weapons/laserimpact.wav", VOL_BASE, ATTN_NORM); }
			}
			else
			{
				pointparticles(particleeffectnum("nex_impact"), org2, '0 0 0', 1);
				if(!w_issilent) { sound(self, CH_SHOTS, "weapons/neximpact.wav", VOL_BASE, ATTN_NORM); }
			}
			return TRUE;
		}
		case WR_INIT:
		{
			precache_sound("weapons/laserimpact.wav");
			precache_sound("weapons/neximpact.wav");
			if(autocvar_cl_reticle && autocvar_cl_reticle_weapon)
			{
				precache_pic("gfx/reticle_nex");
			}
			return TRUE;
		}
		case WR_ZOOMRETICLE:
		{
			if(button_zoom || zoomscript_caught)
			{
				reticle_image = "gfx/reticle_nex";
				return TRUE;
			}
			else
			{
				// no weapon specific image for this weapon
				return FALSE;
			}
		}
	}
	return FALSE;
}
#endif
#endif
