#ifdef REGISTER_WEAPON
REGISTER_WEAPON(
/* WEP_##id */ MINSTANEX,
/* function */ w_minstanex,
/* ammotype */ ammo_cells,
/* impulse  */ 7,
/* flags    */ WEP_FLAG_RELOADABLE | WEP_FLAG_CANCLIMB | WEP_FLAG_SUPERWEAPON | WEP_TYPE_HITSCAN,
/* rating   */ BOT_PICKUP_RATING_HIGH,
/* model    */ "minstanex",
/* netname  */ "minstanex",
/* fullname */ _("Vaporizer")
);

#define MINSTANEX_SETTINGS(w_cvar,w_prop) MINSTANEX_SETTINGS_LIST(w_cvar, w_prop, MINSTANEX, minstanex)
#define MINSTANEX_SETTINGS_LIST(w_cvar,w_prop,id,sn) \
	w_cvar(id, sn, MO_PRI, ammo) \
	w_cvar(id, sn, MO_PRI, animtime) \
	w_cvar(id, sn, MO_PRI, refire) \
	w_cvar(id, sn, MO_SEC, ammo) \
	w_cvar(id, sn, MO_SEC, animtime) \
	w_cvar(id, sn, MO_SEC, damage) \
	w_cvar(id, sn, MO_SEC, delay) \
	w_cvar(id, sn, MO_SEC, edgedamage) \
	w_cvar(id, sn, MO_SEC, force) \
	w_cvar(id, sn, MO_SEC, lifetime) \
	w_cvar(id, sn, MO_SEC, radius) \
	w_cvar(id, sn, MO_SEC, refire) \
	w_cvar(id, sn, MO_SEC, shotangle) \
	w_cvar(id, sn, MO_SEC, speed) \
	w_cvar(id, sn, MO_SEC, spread) \
	w_prop(id, sn, float,  reloading_ammo, reload_ammo) \
	w_prop(id, sn, float,  reloading_time, reload_time) \
	w_prop(id, sn, float,  switchdelay_raise, switchdelay_raise) \
	w_prop(id, sn, float,  switchdelay_drop, switchdelay_drop) \
	w_prop(id, sn, string, weaponreplace, weaponreplace) \
	w_prop(id, sn, float,  weaponstart, weaponstart) \
	w_prop(id, sn, float,  weaponstartoverride, weaponstartoverride)

#ifdef SVQC
MINSTANEX_SETTINGS(WEP_ADD_CVAR, WEP_ADD_PROP)
.float minstanex_lasthit;
.float jump_interval;
#endif
#else
#ifdef SVQC
void spawnfunc_weapon_minstanex (void) { weapon_defaultspawnfunc(WEP_MINSTANEX); }

void W_MinstaNex_Attack (void)
{
	float flying;
	flying = IsFlying(self); // do this BEFORE to make the trace values from FireRailgunBullet last

	W_SetupShot (self, TRUE, 0, "weapons/minstanexfire.wav", CH_WEAPON_A, 10000);

	yoda = 0;
	damage_goodhits = 0;
	FireRailgunBullet (w_shotorg, w_shotorg + w_shotdir * MAX_SHOT_DISTANCE, 10000, 800, 0, 0, 0, 0, WEP_MINSTANEX);

	if(yoda && flying)
		Send_Notification(NOTIF_ONE, self, MSG_ANNCE, ANNCE_ACHIEVEMENT_YODA);
	if(damage_goodhits && self.minstanex_lasthit)
	{
		Send_Notification(NOTIF_ONE, self, MSG_ANNCE, ANNCE_ACHIEVEMENT_IMPRESSIVE);
		damage_goodhits = 0; // only every second time
	}

	self.minstanex_lasthit = damage_goodhits;

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
	
	W_DecreaseAmmo(((g_minstagib) ? 1 : WEP_CVAR_PRI(minstanex, ammo)));
}

float w_minstanex(float req)
{
	float ammo_amount;
	float minstanex_ammo;

	// now multiple WR_s use this
	minstanex_ammo = ((g_minstagib) ? 1 : WEP_CVAR_PRI(minstanex, ammo));

	switch(req)
	{
		case WR_AIM:
		{
			if(self.ammo_cells > 0)
				self.BUTTON_ATCK = bot_aim(1000000, 0, 1, FALSE);
			else
				self.BUTTON_ATCK2 = bot_aim(WEP_CVAR_SEC(minstanex, speed), 0, WEP_CVAR_SEC(minstanex, lifetime), FALSE); // WEAPONTODO: replace with proper minstanex cvars
				
			return TRUE;
		}
		case WR_THINK:
		{
			// if the laser uses load, we also consider its ammo for reloading
			if(WEP_CVAR(minstanex, reload_ammo) && WEP_CVAR_SEC(minstanex, ammo) && self.clip_load < min(minstanex_ammo, WEP_CVAR_SEC(minstanex, ammo))) // forced reload
				WEP_ACTION(self.weapon, WR_RELOAD);
			else if(WEP_CVAR(minstanex, reload_ammo) && self.clip_load < minstanex_ammo) // forced reload
				WEP_ACTION(self.weapon, WR_RELOAD);
			else if (self.BUTTON_ATCK)
			{
				if (weapon_prepareattack(0, WEP_CVAR_PRI(minstanex, refire)))
				{
					W_MinstaNex_Attack();
					weapon_thinkf(WFRAME_FIRE1, WEP_CVAR_PRI(minstanex, animtime), w_ready);
				}
			}
			else if (self.BUTTON_ATCK2)
			{
				if (self.jump_interval <= time)
				if (weapon_prepareattack(1, -1))
				{
					// handle refire manually, so that primary and secondary can be fired without conflictions (important for minstagib)
					self.jump_interval = time + WEP_CVAR_SEC(minstanex, refire) * W_WeaponRateFactor();
					
					// decrease ammo for the laser?
					if(WEP_CVAR_SEC(minstanex, ammo))
						W_DecreaseAmmo(WEP_CVAR_SEC(minstanex, ammo));

					// ugly minstagib hack to reuse the fire mode of the laser
					float w;
					w = self.weapon;
					self.weapon = WEP_BLASTER;
					W_Blaster_Attack(
						WEP_CVAR_SEC(minstanex, shotangle),
						WEP_CVAR_SEC(minstanex, damage),
						WEP_CVAR_SEC(minstanex, edgedamage),
						WEP_CVAR_SEC(minstanex, radius),
						WEP_CVAR_SEC(minstanex, force),
						WEP_CVAR_SEC(minstanex, speed),
						WEP_CVAR_SEC(minstanex, spread),
						WEP_CVAR_SEC(minstanex, delay),
						WEP_CVAR_SEC(minstanex, lifetime)
					);
					self.weapon = w;
					
					// now do normal refire
					weapon_thinkf(WFRAME_FIRE2, WEP_CVAR_SEC(minstanex, animtime), w_ready);
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
			MINSTANEX_SETTINGS(WEP_SKIPCVAR, WEP_SET_PROP)
			return TRUE;
		}
		case WR_SETUP:
		{
			self.current_ammo = ammo_cells;
			self.minstanex_lasthit = 0;
			return TRUE;
		}
		case WR_CHECKAMMO1:
		{
			ammo_amount = self.ammo_cells >= minstanex_ammo;
			ammo_amount += self.(weapon_load[WEP_MINSTANEX]) >= minstanex_ammo;
			return ammo_amount;
		}
		case WR_CHECKAMMO2:
		{
			if(!WEP_CVAR_SEC(minstanex, ammo))
				return TRUE;
			ammo_amount = self.ammo_cells >= WEP_CVAR_SEC(minstanex, ammo);
			ammo_amount += self.(weapon_load[WEP_MINSTANEX]) >= WEP_CVAR_SEC(minstanex, ammo);
			return ammo_amount;
		}
		case WR_CONFIG:
		{
			MINSTANEX_SETTINGS(WEP_CONFIG_WRITE_CVARS, WEP_CONFIG_WRITE_PROPS)
			return TRUE;
		}
		case WR_RESETPLAYER:
		{
			self.minstanex_lasthit = 0;
			return TRUE;
		}
		case WR_RELOAD:
		{
			float used_ammo;
			if(WEP_CVAR_SEC(minstanex, ammo))
				used_ammo = min(minstanex_ammo, WEP_CVAR_SEC(minstanex, ammo));
			else
				used_ammo = minstanex_ammo;

			W_Reload(used_ammo, "weapons/reload.wav");
			return TRUE;
		}
		case WR_SUICIDEMESSAGE:
		{
			return WEAPON_THINKING_WITH_PORTALS;
		}
		case WR_KILLMESSAGE:
		{
			return WEAPON_MINSTANEX_MURDER;
		}
	}
	return TRUE;
}
#endif
#ifdef CSQC
float w_minstanex(float req)
{
	switch(req)
	{
		case WR_IMPACTEFFECT:
		{
			vector org2;
			org2 = w_org + w_backoff * 6;
			pointparticles(particleeffectnum("nex_impact"), org2, '0 0 0', 1);
			if(!w_issilent)
				sound(self, CH_SHOTS, "weapons/neximpact.wav", VOL_BASE, ATTN_NORM);
				
			return TRUE;
		}
		case WR_INIT:
		{
			precache_sound("weapons/neximpact.wav");
			return TRUE;
		}
	}
	return TRUE;
}
#endif
#endif
