#ifndef CHAOS
const float WEP_REVOLVER = 1337; // abuse
#else
#ifdef REGISTER_WEAPON
REGISTER_WEAPON(
/* WEP_##id  */ REVOLVER,
/* function  */ W_Revolver,
/* ammotype  */ ammo_shells,
/* impulse   */ 2,
/* flags     */ WEP_FLAG_NORMAL | WEP_FLAG_RELOADABLE | WEP_TYPE_HITSCAN,
/* rating    */ BOT_PICKUP_RATING_LOW,
/* color     */ '1 1 0.3',
/* modelname */ "revolver",
/* simplemdl */ "foobar",
/* crosshair */ "gfx/crosshairrevolver 0.4",
/* wepimg    */ "weaponrevolver",
/* refname   */ "revolver",
/* wepname   */ _("Revolver")
);

#define REVOLVER_SETTINGS(w_cvar,w_prop) REVOLVER_SETTINGS_LIST(w_cvar, w_prop, REVOLVER, revolver)
#define REVOLVER_SETTINGS_LIST(w_cvar,w_prop,id,sn) \
	w_cvar(id, sn, NONE, ammo) \
	w_cvar(id, sn, NONE, animtime) \
	w_cvar(id, sn, NONE, refire) \
	w_cvar(id, sn, NONE, damage) \
	w_cvar(id, sn, NONE, force) \
	w_cvar(id, sn, NONE, solidpenetration) \
	w_cvar(id, sn, NONE, spread) \
	w_cvar(id, sn, NONE, load_time) \
	w_cvar(id, sn, NONE, load_refire) \
	w_prop(id, sn, float,  reloading_ammo, reload_ammo) \
	w_prop(id, sn, float,  reloading_time, reload_time) \
	w_prop(id, sn, float,  switchdelay_raise, switchdelay_raise) \
	w_prop(id, sn, float,  switchdelay_drop, switchdelay_drop) \
	w_prop(id, sn, string, weaponreplace, weaponreplace) \
	w_prop(id, sn, float,  weaponstart, weaponstart) \
	w_prop(id, sn, float,  weaponstartoverride, weaponstartoverride) \
	w_prop(id, sn, float,  weaponthrowable, weaponthrowable)

#ifdef SVQC
REVOLVER_SETTINGS(WEP_ADD_CVAR, WEP_ADD_PROP)
#endif
#else
#ifdef SVQC
void spawnfunc_weapon_revolver(void) { weapon_defaultspawnfunc(WEP_REVOLVER); }

void W_Revolver_Attack()
{
	entity flash;

	W_DecreaseAmmo(WEP_CVAR(revolver, ammo));

	W_SetupShot(self, TRUE, 5, W_Sound("revolver_fire"), CH_WEAPON_A, WEP_CVAR(revolver, damage));
	fireBullet(w_shotorg, w_shotdir, WEP_CVAR(revolver, spread), WEP_CVAR(revolver, solidpenetration), WEP_CVAR(revolver, damage), WEP_CVAR(revolver, force), WEP_REVOLVER, 0);

	Send_Effect(EFFECT_SHOTGUN_MUZZLEFLASH, w_shotorg, w_shotdir * 1000, WEP_CVAR(revolver, ammo));

	// muzzle flash for 1st person view
	flash = spawn();
	setmodel(flash, "models/uziflash.md3"); // precision set below
	flash.think = SUB_Remove;
	flash.nextthink = time + 0.06;
	flash.effects = EF_ADDITIVE | EF_FULLBRIGHT | EF_LOWPRECISION;
	W_AttachToShotorg(flash, '5 0 0');
}

.float revolver_primarytime;
.float revolver_load;
.float revolver_loadspamtime;

void W_Revolver_SetLoad(float newload)
{
	if(newload == self.revolver_load) { return; }

	self.revolver_load = newload;

	self.weaponname = ((newload) ? "revolver-cocked" : "revolver");

	// casing code
	if(autocvar_g_casings >= 1)
	if(!newload)
		SpawnCasing(((random() * 50 + 50) * v_right) - (v_forward * (random() * 25 + 25)) - ((random() * 5 - 30) * v_up), 2, vectoangles(v_forward),'0 250 0', 100, 1, self);
}

float W_Revolver_CheckLoad()
{
	if(!self.revolver_load) { return TRUE; }
	else if(time >= self.revolver_loadspamtime && IS_REAL_CLIENT(self) && self.BUTTON_ATCK && !self.BUTTON_ATCK2) // TODO
	{
		self.revolver_loadspamtime = time + WEP_CVAR(revolver, refire) * W_WeaponRateFactor();
		play2(self, W_Sound("dryfire"));
		sprint(self, "Please use secondary fire to load the revolver!\n");
		return FALSE;
	}

	return FALSE;
}

float W_Revolver(float req)
{
	float ammo_amount;
	switch(req)
	{
		case WR_AIM:
		{
			if(!W_Revolver_CheckLoad())
				self.BUTTON_ATCK2 = TRUE;
			else
				self.BUTTON_ATCK = bot_aim(1000000, 0, 0.001, FALSE);

			return TRUE;
		}
		case WR_THINK:
		{
			if(WEP_CVAR(revolver, reload_ammo) && self.clip_load < WEP_CVAR(revolver, ammo)) // forced reload
			{
				WEP_ACTION(self.weapon, WR_RELOAD);
			}
			else
			{
				if(self.BUTTON_ATCK)
				if(W_Revolver_CheckLoad())
				if(time >= self.revolver_primarytime) // handle refire separately so the secondary can be fired straight after a primary
				{
					if(weapon_prepareattack(0, WEP_CVAR(revolver, animtime)))
					{
						W_Revolver_Attack();
						self.revolver_primarytime = time + WEP_CVAR(revolver, refire) * W_WeaponRateFactor();
						self.revolver_loadspamtime = time + self.revolver_primarytime; // just enough to not spam it this frame
						W_Revolver_SetLoad(1);
						weapon_thinkf(WFRAME_FIRE1, WEP_CVAR(revolver, animtime), w_ready);
					}
				}
			}
			if(self.BUTTON_ATCK2)
			if(!W_Revolver_CheckLoad())
			if(weapon_prepareattack(1, WEP_CVAR(revolver, load_refire)))
			{
				W_Revolver_SetLoad(0);
				weapon_thinkf(WFRAME_FIRE1, WEP_CVAR(revolver, load_time), w_ready);
			}
			
			return TRUE;
		}
		case WR_INIT:
		{
			precache_model("models/uziflash.md3");
			precache_model(W_Model("g_revolver.md3"));
			precache_model(W_Model("v_revolver.md3"));
			precache_model(W_Model("h_revolver.iqm"));
			precache_model(W_Model("v_revolver-cocked.md3"));
			precache_model(W_Model("h_revolver-cocked.iqm"));
			precache_sound("misc/itempickup.wav");
			precache_sound(W_Sound("revolver_fire"));
			REVOLVER_SETTINGS(WEP_SKIP_CVAR, WEP_SET_PROP)
			return TRUE;
		}
		case WR_SETUP:
		{
			W_Revolver_SetLoad(0);
			return TRUE;
		}
		case WR_CHECKAMMO1:
		{
			ammo_amount = self.WEP_AMMO(REVOLVER) >= WEP_CVAR(revolver, ammo);
			ammo_amount += self.(weapon_load[WEP_REVOLVER]) >= WEP_CVAR(revolver, ammo);
			return ammo_amount;
		}
		case WR_CHECKAMMO2:
		{
			ammo_amount = self.WEP_AMMO(REVOLVER) >= WEP_CVAR(revolver, ammo);
			ammo_amount += self.(weapon_load[WEP_REVOLVER]) >= WEP_CVAR(revolver, ammo);
			if(ammo_amount >= 1)
				return !W_Revolver_CheckLoad();
			else
				return FALSE;
		}
		case WR_CONFIG:
		{
			REVOLVER_SETTINGS(WEP_CONFIG_WRITE_CVARS, WEP_CONFIG_WRITE_PROPS)
			return TRUE;
		}
		case WR_RELOAD:
		{
			W_Reload(WEP_CVAR(revolver, ammo), W_Sound("reload")); // WEAPONTODO
			return TRUE;
		}
		case WR_SUICIDEMESSAGE:
		{
			return WEAPON_THINKING_WITH_PORTALS;
		}
		case WR_KILLMESSAGE:
		{
			return WEAPON_REVOLVER_MURDER;
		}
	}
	return FALSE;
}
#endif
#ifdef CSQC
.float prevric;
float W_Revolver(float req)
{
	switch(req)
	{
		case WR_IMPACTEFFECT:
		{
			vector org2;
			org2 = w_org + w_backoff * 2;
			pointparticles(particleeffectnum("shotgun_impact"), org2, w_backoff * 1000, 1);
			if(!w_issilent && time - self.prevric > 0.25)
			{
				if(w_random < 0.0165)
					sound(self, CH_SHOTS, "weapons/ric1.wav", VOL_BASE, ATTEN_NORM);
				else if(w_random < 0.033)
					sound(self, CH_SHOTS, "weapons/ric2.wav", VOL_BASE, ATTEN_NORM);
				else if(w_random < 0.05)
					sound(self, CH_SHOTS, "weapons/ric3.wav", VOL_BASE, ATTEN_NORM);
				self.prevric = time;
			}

			return TRUE;
		}
		case WR_INIT:
		{
			precache_sound("weapons/ric1.wav");
			precache_sound("weapons/ric2.wav");
			precache_sound("weapons/ric3.wav");
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
#endif
