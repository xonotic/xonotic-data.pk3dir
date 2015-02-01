#ifndef CHAOS
const float WEP_LIGHTSABRE = 1337;
#else
#ifdef REGISTER_WEAPON
REGISTER_WEAPON(
/* WEP_##id  */ LIGHTSABRE,
/* function  */ W_Lightsabre,
/* ammotype  */ ammo_none,
/* impulse   */ 1,
/* flags     */ WEP_FLAG_NORMAL | WEP_FLAG_RELOADABLE,
/* rating    */ BOT_PICKUP_RATING_LOW,
/* color     */ '1 0.25 0.25',
/* modelname */ "lightsabre",
/* simplemdl */ "foobar",
/* crosshair */ "gfx/crosshairlightsabre 0.35",
/* wepimg    */ "weaponlightsabre",
/* refname   */ "lightsabre",
/* wepname   */ _("Lightsabre")
);

#define LIGHTSABRE_SETTINGS(w_cvar,w_prop) LIGHTSABRE_SETTINGS_LIST(w_cvar, w_prop, LIGHTSABRE, lightsabre)
#define LIGHTSABRE_SETTINGS_LIST(w_cvar,w_prop,id,sn) \
	w_cvar(id, sn, BOTH, animtime) \
	w_cvar(id, sn, BOTH, refire) \
	w_cvar(id, sn, BOTH, damage) \
	w_cvar(id, sn, BOTH, force) \
	w_cvar(id, sn, BOTH, melee_time) \
	w_cvar(id, sn, BOTH, melee_no_doubleslap) \
	w_cvar(id, sn, BOTH, melee_traces) \
	w_cvar(id, sn, BOTH, melee_swing_up) \
	w_cvar(id, sn, BOTH, melee_swing_side) \
	w_cvar(id, sn, BOTH, melee_nonplayerdamage) \
	w_cvar(id, sn, BOTH, melee_multihit) \
	w_cvar(id, sn, BOTH, melee_delay) \
	w_cvar(id, sn, BOTH, melee_range) \
	w_prop(id, sn, float,  reloading_ammo, reload_ammo) \
	w_prop(id, sn, float,  reloading_time, reload_time) \
	w_prop(id, sn, float,  switchdelay_raise, switchdelay_raise) \
	w_prop(id, sn, float,  switchdelay_drop, switchdelay_drop) \
	w_prop(id, sn, string, weaponreplace, weaponreplace) \
	w_prop(id, sn, float,  weaponstart, weaponstart) \
	w_prop(id, sn, float,  weaponstartoverride, weaponstartoverride) \
	w_prop(id, sn, float,  weaponthrowable, weaponthrowable)

#ifdef SVQC
LIGHTSABRE_SETTINGS(WEP_ADD_CVAR, WEP_ADD_PROP)
#endif
#else
#ifdef SVQC
void spawnfunc_weapon_lightsabre(void) { weapon_defaultspawnfunc(WEP_LIGHTSABRE); }

.float swing_prev;
.entity swing_alreadyhit;

float W_Lightsabre_Melee_Block(entity player)
{
	if(!IS_PLAYER(player)) { return FALSE; }

	entity player_melee = world, e;
	entity myowner = self.realowner;

	for(e = world; (e = find(e, classname, "melee_temp")); )
	if(e.realowner == player)
	{
		player_melee = e;
		break;
	}

	if(!player_melee) { return FALSE; }

	makevectors (player.v_angle);
	float dot = normalize (myowner.origin - player.origin) * v_forward;

	if(dot <= 0.3) { return FALSE; }

	//if((myowner.v_angle_x - player.v_angle_x < 70) && (myowner.v_angle_x - player.v_angle_x > -70)) //Look up and down
	//if((myowner.v_angle_y - player.v_angle_y > 160) || (myowner.v_angle_y - player.v_angle_y < -160)) //Side to side Facing eachother
		// fun stuff

	animdecide_setaction(myowner, ANIMACTION_SHOOT, 1);
	string thesound = strcat("lightsabre_hit", ftos(max(1, floor(random() * 4))));
	sound(myowner, CH_WEAPON_A, W_Sound(thesound), VOL_BASE, ATTEN_NORM);

	return TRUE;
}

void W_Lightsabre_Melee_Think(void)
{
	// declarations
	float i, f, swing, swing_factor, swing_damage, meleetime, is_player;
	entity target_victim;
	vector targpos;
	float isprimary = !(self.realowner.BUTTON_ATCK2);
	float deathtype = WEP_LIGHTSABRE;
	if(!isprimary)
		deathtype |= HITTYPE_SECONDARY;

	if(!self.cnt) // set start time of melee
	{
		self.cnt = time;
	}

	makevectors(self.realowner.v_angle); // update values for v_* vectors

	// calculate swing percentage based on time
	meleetime = WEP_CVAR_BOTH(lightsabre, isprimary, melee_time) * W_WeaponRateFactor();
	swing = bound(0, (self.cnt + meleetime - time) / meleetime, 10);
	f = ((1 - swing) * WEP_CVAR_BOTH(lightsabre, isprimary, melee_traces));

	// check to see if we can still continue, otherwise give up now
	if((self.realowner.deadflag != DEAD_NO) && WEP_CVAR_BOTH(lightsabre, isprimary, melee_no_doubleslap))
	{
		remove(self);
		return;
	}

	// if okay, perform the traces needed for this frame
	for(i=self.swing_prev; i < f; ++i)
	{
		swing_factor = ((1 - (i / WEP_CVAR_BOTH(lightsabre, isprimary, melee_traces))) * 2 - 1);

		targpos = (self.realowner.origin + self.realowner.view_ofs
			+ (v_forward * WEP_CVAR_BOTH(lightsabre, isprimary, melee_range))
			+ (v_up * swing_factor * WEP_CVAR_BOTH(lightsabre, isprimary, melee_swing_up))
			+ (v_right * swing_factor * WEP_CVAR_BOTH(lightsabre, isprimary, melee_swing_side)));

		WarpZone_traceline_antilag(self, self.realowner.origin + self.realowner.view_ofs, targpos, FALSE, self.realowner, ANTILAG_LATENCY(self.realowner));

		// draw lightning beams for debugging
		//te_lightning2(world, targpos, self.realowner.origin + self.realowner.view_ofs + v_forward * 5 - v_up * 5);
		//te_customflash(targpos, 40,  2, '1 1 1');

		is_player = (IS_PLAYER(trace_ent) || trace_ent.classname == "body" || (trace_ent.flags & FL_MONSTER));

		if((trace_fraction < 1) // if trace is good, apply the damage and remove self
			&& (trace_ent.takedamage == DAMAGE_AIM)
			&& (trace_ent != self.swing_alreadyhit)
			&& (is_player || WEP_CVAR_BOTH(lightsabre, isprimary, melee_nonplayerdamage)))
		{
			target_victim = trace_ent; // so it persists through other calls

			if(!W_Lightsabre_Melee_Block(trace_ent))
			{
				if(is_player) // this allows us to be able to nerf the non-player damage done in e.g. assault or onslaught.
					swing_damage = (WEP_CVAR_BOTH(lightsabre, isprimary, damage) * min(1, swing_factor + 1));
				else
					swing_damage = (WEP_CVAR_BOTH(lightsabre, isprimary, melee_nonplayerdamage) * min(1, swing_factor + 1));

				//print(strcat(self.realowner.netname, " hitting ", target_victim.netname, " with ", strcat(ftos(swing_damage), " damage (factor: ", ftos(swing_factor), ") at "), ftos(time), " seconds.\n"));

				Damage(target_victim, self.realowner, self.realowner,
					swing_damage, deathtype,
					self.realowner.origin + self.realowner.view_ofs,
					v_forward * WEP_CVAR_BOTH(lightsabre, isprimary, force));

				string thesound = strcat("lightsabre_hit", ftos(max(1, floor(random() * 4))));

				sound(self.realowner, CH_WEAPON_A, W_Sound(thesound), VOL_BASE, ATTEN_NORM);

				if(accuracy_isgooddamage(self.realowner, target_victim)) { accuracy_add(self.realowner, WEP_LIGHTSABRE, 0, swing_damage); }
			}

			// draw large red flash for debugging
			//te_customflash(targpos, 200, 2, '15 0 0');

			if(WEP_CVAR_BOTH(lightsabre, isprimary, melee_multihit)) // allow multiple hits with one swing, but not against the same player twice.
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

void W_Lightsabre_Attack(void)
{
	float isprimary = !(self.BUTTON_ATCK2);

	sound(self, CH_WEAPON_A, ((isprimary) ? W_Sound("lightsabre_melee2") : W_Sound("lightsabre_melee1")), VOL_BASE, ATTEN_NORM);
	weapon_thinkf(((isprimary) ? WFRAME_FIRE2 : WFRAME_FIRE1), WEP_CVAR_BOTH(lightsabre, isprimary, animtime), w_ready);

	entity meleetemp;
	meleetemp = spawn();
	meleetemp.classname = "melee_temp";
	meleetemp.realowner = self;
	meleetemp.think = W_Lightsabre_Melee_Think;
	meleetemp.nextthink = time + WEP_CVAR_BOTH(lightsabre, isprimary, melee_delay) * W_WeaponRateFactor();
	W_SetupShot_Range(self, TRUE, 0, "", 0, WEP_CVAR_BOTH(lightsabre, isprimary, damage), WEP_CVAR_BOTH(lightsabre, isprimary, melee_range));
}

.float lightsabre_active;

void W_LightSabre_SetActive(float newactive, float dosound)
{
	if(newactive)
	{
		self.lightsabre_active = TRUE;
		self.weaponname = "lightsabre_active";
		if(dosound)
			sound(self, CH_WEAPON_A, W_Sound("lightsabre_activate"), VOL_BASE, ATTEN_NORM);
	}
	else
	{
		self.lightsabre_active = FALSE;
		self.weaponname = "lightsabre";
		if(dosound)
			sound(self, CH_WEAPON_A, W_Sound("lightsabre_deactivate"), VOL_BASE, ATTEN_NORM);
	}
}

float W_Lightsabre(float req)
{
	switch(req)
	{
		case WR_AIM:
		{
			if(random() >= 0.5)
				self.BUTTON_ATCK2 = bot_aim(1000000, 0, 0.001, FALSE);
			else
				self.BUTTON_ATCK = bot_aim(1000000, 0, 0.001, FALSE);

			return TRUE;
		}
		case WR_THINK:
		{
			if(self.BUTTON_ATCK || self.BUTTON_ATCK2)
			if(weapon_prepareattack(self.BUTTON_ATCK2, WEP_CVAR_BOTH(lightsabre, self.BUTTON_ATCK2, refire)))
			{
				if(!self.lightsabre_active)
				{
					W_LightSabre_SetActive(1, TRUE);
					weapon_thinkf(WFRAME_RELOAD, WEP_CVAR_BOTH(lightsabre, self.BUTTON_ATCK2, animtime), w_ready);
				}
				else
					weapon_thinkf(WFRAME_FIRE1, 0, W_Lightsabre_Attack);
			}
			
			return TRUE;
		}
		case WR_INIT:
		{
			precache_model("models/uziflash.md3");
			precache_model(W_Model("g_lightsabre.md3"));
			precache_model(W_Model("v_lightsabre.md3"));
			precache_model(W_Model("h_lightsabre.iqm"));
			precache_model(W_Model("v_lightsabre_active.md3"));
			precache_model(W_Model("h_lightsabre_active.iqm"));
			precache_sound("misc/itempickup.wav");
			precache_sound(W_Sound("lightsabre_melee1"));
			precache_sound(W_Sound("lightsabre_melee2"));
			precache_sound(W_Sound("lightsabre_activate"));
			precache_sound(W_Sound("lightsabre_deactivate"));
			precache_sound(W_Sound("lightsabre_hit1"));
			precache_sound(W_Sound("lightsabre_hit2"));
			precache_sound(W_Sound("lightsabre_hit3"));
			LIGHTSABRE_SETTINGS(WEP_SKIP_CVAR, WEP_SET_PROP)
			return TRUE;
		}
		case WR_SETUP:
		{
			self.ammo_field = ammo_none;
			W_LightSabre_SetActive(0, FALSE);
			return TRUE;
		}
		case WR_CHECKAMMO1:
		{
			return TRUE;
		}
		case WR_CHECKAMMO2:
		{
			return TRUE;
		}
		case WR_CONFIG:
		{
			LIGHTSABRE_SETTINGS(WEP_CONFIG_WRITE_CVARS, WEP_CONFIG_WRITE_PROPS)
			return TRUE;
		}
		case WR_RELOAD:
		{
			W_LightSabre_SetActive(((self.lightsabre_active) ? 0 : 1), TRUE);
			return TRUE;
		}
		case WR_SUICIDEMESSAGE:
		{
			return WEAPON_THINKING_WITH_PORTALS;
		}
		case WR_KILLMESSAGE:
		{
			return WEAPON_LIGHTSABRE_MURDER;
		}
	}
	return FALSE;
}
#endif
#ifdef CSQC
.float prevric;
float W_Lightsabre(float req)
{
	switch(req)
	{
		case WR_IMPACTEFFECT:
		{
			return TRUE;
		}
		case WR_INIT:
		{
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
