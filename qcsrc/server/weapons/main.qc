/*
===========================================================================

  CLIENT WEAPONSYSTEM CODE
  Bring back W_Weaponframe

===========================================================================
*/

.float weapon_frametime;

float W_WeaponRateFactor()
{
	float t;
	t = 1.0 / g_weaponratefactor;

	return t;
}

void W_SwitchWeapon_Force(entity e, float w)
{
	e.cnt = e.switchweapon;
	e.switchweapon = w;
	e.selectweapon = w;
}

.float antilag_debug;

// VorteX: static frame globals
float WFRAME_DONTCHANGE = -1;
float WFRAME_FIRE1 = 0;
float WFRAME_FIRE2 = 1;
float WFRAME_IDLE = 2;
float WFRAME_RELOAD = 3;
.float wframe;

void(float fr, float t, void() func) weapon_thinkf;

vector w_shotorg;
vector w_shotdir;
vector w_shotend;

.float prevstrengthsound;
.float prevstrengthsoundattempt;
void W_PlayStrengthSound(entity player) // void W_PlayStrengthSound
{
	if((player.items & IT_STRENGTH)
		&& ((time > player.prevstrengthsound + autocvar_sv_strengthsound_antispam_time) // prevent insane sound spam
		|| (time > player.prevstrengthsoundattempt + autocvar_sv_strengthsound_antispam_refire_threshold)))
		{
			sound(player, CH_TRIGGER, "weapons/strength_fire.wav", VOL_BASE, ATTN_NORM);
			player.prevstrengthsound = time;
		}
		player.prevstrengthsoundattempt = time;
}

// this function calculates w_shotorg and w_shotdir based on the weapon model
// offset, trueaim and antilag, and won't put w_shotorg inside a wall.
// make sure you call makevectors first (FIXME?)
void W_SetupShot_Dir_ProjectileSize_Range(entity ent, vector s_forward, vector mi, vector ma, float antilag, float recoil, string snd, float chan, float maxdamage, float range)
{
	float nudge = 1; // added to traceline target and subtracted from result
	float oldsolid;
	vector vecs, dv;
	oldsolid = ent.dphitcontentsmask;
	if(ent.weapon == WEP_RIFLE)
		ent.dphitcontentsmask = DPCONTENTS_BODY | DPCONTENTS_CORPSE;
	else
		ent.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_CORPSE;
	if(antilag)
		WarpZone_traceline_antilag(world, ent.origin + ent.view_ofs, ent.origin + ent.view_ofs + s_forward * range, MOVE_NORMAL, ent, ANTILAG_LATENCY(ent));
		// passing world, because we do NOT want it to touch dphitcontentsmask
	else
		WarpZone_TraceLine(ent.origin + ent.view_ofs, ent.origin + ent.view_ofs + s_forward * range, MOVE_NOMONSTERS, ent);
	ent.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_CORPSE;

	vector vf, vr, vu;
	vf = v_forward;
	vr = v_right;
	vu = v_up;
	w_shotend = WarpZone_UnTransformOrigin(WarpZone_trace_transform, trace_endpos); // warpzone support
	v_forward = vf;
	v_right = vr;
	v_up = vu;

	// un-adjust trueaim if shotend is too close
	if(vlen(w_shotend - (ent.origin + ent.view_ofs)) < autocvar_g_trueaim_minrange)
		w_shotend = ent.origin + ent.view_ofs + s_forward * autocvar_g_trueaim_minrange;

	// track max damage
	if(accuracy_canbegooddamage(ent))
		accuracy_add(ent, ent.weapon, maxdamage, 0);

	W_HitPlotAnalysis(ent, v_forward, v_right, v_up);

	if(ent.weaponentity.movedir_x > 0)
		vecs = ent.weaponentity.movedir;
	else
		vecs = '0 0 0';

	dv = v_right * -vecs_y + v_up * vecs_z;
	w_shotorg = ent.origin + ent.view_ofs + dv;

	// now move the shotorg forward as much as requested if possible
	if(antilag)
	{
		if(ent.antilag_debug)
			tracebox_antilag(ent, w_shotorg, mi, ma, w_shotorg + v_forward * (vecs_x + nudge), MOVE_NORMAL, ent, ent.antilag_debug);
		else
			tracebox_antilag(ent, w_shotorg, mi, ma, w_shotorg + v_forward * (vecs_x + nudge), MOVE_NORMAL, ent, ANTILAG_LATENCY(ent));
	}
	else
		tracebox(w_shotorg, mi, ma, w_shotorg + v_forward * (vecs_x + nudge), MOVE_NORMAL, ent);
	w_shotorg = trace_endpos - v_forward * nudge;
	// calculate the shotdir from the chosen shotorg
	w_shotdir = normalize(w_shotend - w_shotorg);

	if (antilag)
	if (!ent.cvar_cl_noantilag)
	{
		if (autocvar_g_antilag == 1) // switch to "ghost" if not hitting original
		{
			traceline(w_shotorg, w_shotorg + w_shotdir * range, MOVE_NORMAL, ent);
			if (!trace_ent.takedamage)
			{
				traceline_antilag_force (ent, w_shotorg, w_shotorg + w_shotdir * range, MOVE_NORMAL, ent, ANTILAG_LATENCY(ent));
				if (trace_ent.takedamage && IS_PLAYER(trace_ent))
				{
					entity e;
					e = trace_ent;
					traceline(w_shotorg, e.origin, MOVE_NORMAL, ent);
					if(trace_ent == e)
						w_shotdir = normalize(trace_ent.origin - w_shotorg);
				}
			}
		}
		else if(autocvar_g_antilag == 3) // client side hitscan
		{
			// this part MUST use prydon cursor
			if (ent.cursor_trace_ent)                 // client was aiming at someone
			if (ent.cursor_trace_ent != ent)         // just to make sure
			if (ent.cursor_trace_ent.takedamage)      // and that person is killable
			if (IS_PLAYER(ent.cursor_trace_ent)) // and actually a player
			{
				// verify that the shot would miss without antilag
				// (avoids an issue where guns would always shoot at their origin)
				traceline(w_shotorg, w_shotorg + w_shotdir * range, MOVE_NORMAL, ent);
				if (!trace_ent.takedamage)
				{
					// verify that the shot would hit if altered
					traceline(w_shotorg, ent.cursor_trace_ent.origin, MOVE_NORMAL, ent);
					if (trace_ent == ent.cursor_trace_ent)
						w_shotdir = normalize(ent.cursor_trace_ent.origin - w_shotorg);
					else
						print("antilag fail\n");
				}
			}
		}
	}

	ent.dphitcontentsmask = oldsolid; // restore solid type (generally SOLID_SLIDEBOX)

	if (!g_norecoil)
		ent.punchangle_x = recoil * -1;

	if (snd != "")
	{
		sound (ent, chan, snd, VOL_BASE, ATTN_NORM);
		W_PlayStrengthSound(ent);
	}

	// nudge w_shotend so a trace to w_shotend hits
	w_shotend = w_shotend + normalize(w_shotend - w_shotorg) * nudge;
}

#define W_SetupShot_Dir_ProjectileSize(ent,s_forward,mi,ma,antilag,recoil,snd,chan,maxdamage) W_SetupShot_Dir_ProjectileSize_Range(ent, s_forward, mi, ma, antilag, recoil, snd, chan, maxdamage, MAX_SHOT_DISTANCE)
#define W_SetupShot_ProjectileSize(ent,mi,ma,antilag,recoil,snd,chan,maxdamage) W_SetupShot_Dir_ProjectileSize(ent, v_forward, mi, ma, antilag, recoil, snd, chan, maxdamage)
#define W_SetupShot_Dir(ent,s_forward,antilag,recoil,snd,chan,maxdamage) W_SetupShot_Dir_ProjectileSize(ent, s_forward, '0 0 0', '0 0 0', antilag, recoil, snd, chan, maxdamage)
#define W_SetupShot(ent,antilag,recoil,snd,chan,maxdamage) W_SetupShot_ProjectileSize(ent, '0 0 0', '0 0 0', antilag, recoil, snd, chan, maxdamage)
#define W_SetupShot_Range(ent,antilag,recoil,snd,chan,maxdamage,range) W_SetupShot_Dir_ProjectileSize_Range(ent, v_forward, '0 0 0', '0 0 0', antilag, recoil, snd, chan, maxdamage, range)

float CL_Weaponentity_CustomizeEntityForClient()
{
	self.viewmodelforclient = self.owner;
	if(IS_SPEC(other))
		if(other.enemy == self.owner)
			self.viewmodelforclient = other;
	return TRUE;
}

/*
 * supported formats:
 *
 * 1. simple animated model, muzzle flash handling on h_ model:
 *    h_tuba.dpm, h_tuba.dpm.framegroups - invisible model controlling the animation
 *      tags:
 *        shot = muzzle end (shot origin, also used for muzzle flashes)
 *        shell = casings ejection point (must be on the right hand side of the gun)
 *        weapon = attachment for v_tuba.md3
 *    v_tuba.md3 - first and third person model
 *    g_tuba.md3 - pickup model
 *
 * 2. simple animated model, muzzle flash handling on v_ model:
 *    h_tuba.dpm, h_tuba.dpm.framegroups - invisible model controlling the animation
 *      tags:
 *        weapon = attachment for v_tuba.md3
 *    v_tuba.md3 - first and third person model
 *      tags:
 *        shot = muzzle end (shot origin, also used for muzzle flashes)
 *        shell = casings ejection point (must be on the right hand side of the gun)
 *    g_tuba.md3 - pickup model
 *
 * 3. fully animated model, muzzle flash handling on h_ model:
 *    h_tuba.dpm, h_tuba.dpm.framegroups - animated first person model
 *      tags:
 *        shot = muzzle end (shot origin, also used for muzzle flashes)
 *        shell = casings ejection point (must be on the right hand side of the gun)
 *        handle = corresponding to the origin of v_tuba.md3 (used for muzzle flashes)
 *    v_tuba.md3 - third person model
 *    g_tuba.md3 - pickup model
 *
 * 4. fully animated model, muzzle flash handling on v_ model:
 *    h_tuba.dpm, h_tuba.dpm.framegroups - animated first person model
 *      tags:
 *        shot = muzzle end (shot origin)
 *        shell = casings ejection point (must be on the right hand side of the gun)
 *    v_tuba.md3 - third person model
 *      tags:
 *        shot = muzzle end (for muzzle flashes)
 *    g_tuba.md3 - pickup model
 */

// writes:
//   self.origin, self.angles
//   self.weaponentity
//   self.movedir, self.view_ofs
//   attachment stuff
//   anim stuff
// to free:
//   call again with ""
//   remove the ent
void CL_WeaponEntity_SetModel(string name)
{
	float v_shot_idx;
	if (name != "")
	{
		// if there is a child entity, hide it until we're sure we use it
		if (self.weaponentity)
			self.weaponentity.model = "";
		setmodel(self, strcat("models/weapons/v_", name, ".md3")); // precision set below
		v_shot_idx = gettagindex(self, "shot"); // used later
		if(!v_shot_idx)
			v_shot_idx = gettagindex(self, "tag_shot");

		setmodel(self, strcat("models/weapons/h_", name, ".iqm")); // precision set below
		// preset some defaults that work great for renamed zym files (which don't need an animinfo)
		self.anim_fire1  = animfixfps(self, '0 1 0.01', '0 0 0');
		self.anim_fire2  = animfixfps(self, '1 1 0.01', '0 0 0');
		self.anim_idle   = animfixfps(self, '2 1 0.01', '0 0 0');
		self.anim_reload = animfixfps(self, '3 1 0.01', '0 0 0');

		// if we have a "weapon" tag, let's attach the v_ model to it ("invisible hand" style model)
		// if we don't, this is a "real" animated model
		if(gettagindex(self, "weapon"))
		{
			if (!self.weaponentity)
				self.weaponentity = spawn();
			setmodel(self.weaponentity, strcat("models/weapons/v_", name, ".md3")); // precision does not matter
			setattachment(self.weaponentity, self, "weapon");
		}
		else if(gettagindex(self, "tag_weapon"))
		{
			if (!self.weaponentity)
				self.weaponentity = spawn();
			setmodel(self.weaponentity, strcat("models/weapons/v_", name, ".md3")); // precision does not matter
			setattachment(self.weaponentity, self, "tag_weapon");
		}
		else
		{
			if(self.weaponentity)
				remove(self.weaponentity);
			self.weaponentity = world;
		}

		setorigin(self,'0 0 0');
		self.angles = '0 0 0';
		self.frame = 0;
		self.viewmodelforclient = world;

		float idx;

		if(v_shot_idx) // v_ model attached to invisible h_ model
		{
			self.movedir = gettaginfo(self.weaponentity, v_shot_idx);
		}
		else
		{
			idx = gettagindex(self, "shot");
			if(!idx)
				idx = gettagindex(self, "tag_shot");
			if(idx)
				self.movedir = gettaginfo(self, idx);
			else
			{
				print("WARNING: weapon model ", self.model, " does not support the 'shot' tag, will display shots TOTALLY wrong\n");
				self.movedir = '0 0 0';
			}
		}

		if(self.weaponentity) // v_ model attached to invisible h_ model
		{
			idx = gettagindex(self.weaponentity, "shell");
			if(!idx)
				idx = gettagindex(self.weaponentity, "tag_shell");
			if(idx)
				self.spawnorigin = gettaginfo(self.weaponentity, idx);
		}
		else
			idx = 0;
		if(!idx)
		{
			idx = gettagindex(self, "shell");
			if(!idx)
				idx = gettagindex(self, "tag_shell");
			if(idx)
				self.spawnorigin = gettaginfo(self, idx);
			else
			{
				print("WARNING: weapon model ", self.model, " does not support the 'shell' tag, will display casings wrong\n");
				self.spawnorigin = self.movedir;
			}
		}

		if(v_shot_idx)
		{
			self.oldorigin = '0 0 0'; // use regular attachment
		}
		else
		{
			if(self.weaponentity)
			{
				idx = gettagindex(self, "weapon");
				if(!idx)
					idx = gettagindex(self, "tag_weapon");
			}
			else
			{
				idx = gettagindex(self, "handle");
				if(!idx)
					idx = gettagindex(self, "tag_handle");
			}
			if(idx)
			{
				self.oldorigin = self.movedir - gettaginfo(self, idx);
			}
			else
			{
				print("WARNING: weapon model ", self.model, " does not support the 'handle' tag and neither does the v_ model support the 'shot' tag, will display muzzle flashes TOTALLY wrong\n");
				self.oldorigin = '0 0 0'; // there is no way to recover from this
			}
		}

		self.viewmodelforclient = self.owner;
	}
	else
	{
		self.model = "";
		if(self.weaponentity)
			remove(self.weaponentity);
		self.weaponentity = world;
		self.movedir = '0 0 0';
		self.spawnorigin = '0 0 0';
		self.oldorigin = '0 0 0';
		self.anim_fire1  = '0 1 0.01';
		self.anim_fire2  = '0 1 0.01';
		self.anim_idle   = '0 1 0.01';
		self.anim_reload = '0 1 0.01';
	}

	self.view_ofs = '0 0 0';

	if(self.movedir_x >= 0)
	{
		vector v0;
		v0 = self.movedir;
		self.movedir = shotorg_adjust(v0, FALSE, FALSE);
		self.view_ofs = shotorg_adjust(v0, FALSE, TRUE) - v0;
	}
	self.owner.stat_shotorg = compressShotOrigin(self.movedir);
	self.movedir = decompressShotOrigin(self.owner.stat_shotorg); // make them match perfectly

	self.spawnorigin += self.view_ofs; // offset the casings origin by the same amount

	// check if an instant weapon switch occurred
	setorigin(self, self.view_ofs);
	// reset animstate now
	self.wframe = WFRAME_IDLE;
	setanim(self, self.anim_idle, TRUE, FALSE, TRUE);
}

vector CL_Weapon_GetShotOrg(float wpn)
{
	entity wi, oldself;
	vector ret;
	wi = get_weaponinfo(wpn);
	oldself = self;
	self = spawn();
	CL_WeaponEntity_SetModel(wi.mdl);
	ret = self.movedir;
	CL_WeaponEntity_SetModel("");
	remove(self);
	self = oldself;
	return ret;
}

void CL_Weaponentity_Think()
{
	float tb;
	self.nextthink = time;
	if (intermission_running)
		self.frame = self.anim_idle_x;
	if (self.owner.weaponentity != self)
	{
		if (self.weaponentity)
			remove(self.weaponentity);
		remove(self);
		return;
	}
	if (self.owner.deadflag != DEAD_NO)
	{
		self.model = "";
		if (self.weaponentity)
			self.weaponentity.model = "";
		return;
	}
	if (self.weaponname != self.owner.weaponname || self.dmg != self.owner.modelindex || self.deadflag != self.owner.deadflag)
	{
		self.weaponname = self.owner.weaponname;
		self.dmg = self.owner.modelindex;
		self.deadflag = self.owner.deadflag;

		CL_WeaponEntity_SetModel(self.owner.weaponname);
	}

	tb = (self.effects & (EF_TELEPORT_BIT | EF_RESTARTANIM_BIT));
	self.effects = self.owner.effects & EFMASK_CHEAP;
	self.effects &~= EF_LOWPRECISION;
	self.effects &~= EF_FULLBRIGHT; // can mask team color, so get rid of it
	self.effects &~= EF_TELEPORT_BIT;
	self.effects &~= EF_RESTARTANIM_BIT;
	self.effects |= tb;

	if(self.owner.alpha == default_player_alpha)
		self.alpha = default_weapon_alpha;
	else if(self.owner.alpha != 0)
		self.alpha = self.owner.alpha;
	else
		self.alpha = 1;

	self.glowmod = self.owner.weaponentity_glowmod;
	self.colormap = self.owner.colormap;
	if (self.weaponentity)
	{
		self.weaponentity.effects = self.effects;
		self.weaponentity.alpha = self.alpha;
		self.weaponentity.colormap = self.colormap;
		self.weaponentity.glowmod = self.glowmod;
	}

	self.angles = '0 0 0';
	
	float f = (self.owner.weapon_nextthink - time);
	if (self.state == WS_RAISE && !intermission_running)
	{
		entity newwep = get_weaponinfo(self.owner.switchweapon);
		f = f * g_weaponratefactor / max(f, newwep.switchdelay_raise);
		//print(sprintf("CL_Weaponentity_Think(): cvar: %s, value: %f, nextthink: %f\n", sprintf("g_balance_%s_switchdelay_raise", newwep.netname), cvar(sprintf("g_balance_%s_switchdelay_raise", newwep.netname)), (self.owner.weapon_nextthink - time)));
		self.angles_x = -90 * f * f;
	}
	else if (self.state == WS_DROP && !intermission_running)
	{
		entity oldwep = get_weaponinfo(self.owner.weapon);
		f = 1 - f * g_weaponratefactor / max(f, oldwep.switchdelay_drop);
		//print(sprintf("CL_Weaponentity_Think(): cvar: %s, value: %f, nextthink: %f\n", sprintf("g_balance_%s_switchdelay_drop", oldwep.netname), cvar(sprintf("g_balance_%s_switchdelay_drop", oldwep.netname)), (self.owner.weapon_nextthink - time)));
		self.angles_x = -90 * f * f;
	}
	else if (self.state == WS_CLEAR)
	{
		f = 1;
		self.angles_x = -90 * f * f;
	}
}

void CL_ExteriorWeaponentity_Think()
{
	float tag_found;
	self.nextthink = time;
	if (self.owner.exteriorweaponentity != self)
	{
		remove(self);
		return;
	}
	if (self.owner.deadflag != DEAD_NO)
	{
		self.model = "";
		return;
	}
	if (self.weaponname != self.owner.weaponname || self.dmg != self.owner.modelindex || self.deadflag != self.owner.deadflag)
	{
		self.weaponname = self.owner.weaponname;
		self.dmg = self.owner.modelindex;
		self.deadflag = self.owner.deadflag;
		if (self.owner.weaponname != "")
			setmodel(self, strcat("models/weapons/v_", self.owner.weaponname, ".md3")); // precision set below
		else
			self.model = "";

		if((tag_found = gettagindex(self.owner, "tag_weapon")))
		{
			self.tag_index = tag_found;
			self.tag_entity = self.owner;
		}
		else
			setattachment(self, self.owner, "bip01 r hand");
	}
	self.effects = self.owner.effects;
	self.effects |= EF_LOWPRECISION;
	self.effects = self.effects & EFMASK_CHEAP; // eat performance
	if(self.owner.alpha == default_player_alpha)
		self.alpha = default_weapon_alpha;
	else if(self.owner.alpha != 0)
		self.alpha = self.owner.alpha;
	else
		self.alpha = 1;

	self.glowmod = self.owner.weaponentity_glowmod;
	self.colormap = self.owner.colormap;

	CSQCMODEL_AUTOUPDATE();
}

// spawning weaponentity for client
void CL_SpawnWeaponentity()
{
	self.weaponentity = spawn();
	self.weaponentity.classname = "weaponentity";
	self.weaponentity.solid = SOLID_NOT;
	self.weaponentity.owner = self;
	setmodel(self.weaponentity, ""); // precision set when changed
	setorigin(self.weaponentity, '0 0 0');
	self.weaponentity.angles = '0 0 0';
	self.weaponentity.viewmodelforclient = self;
	self.weaponentity.flags = 0;
	self.weaponentity.think = CL_Weaponentity_Think;
	self.weaponentity.customizeentityforclient = CL_Weaponentity_CustomizeEntityForClient;
	self.weaponentity.nextthink = time;

	self.exteriorweaponentity = spawn();
	self.exteriorweaponentity.classname = "exteriorweaponentity";
	self.exteriorweaponentity.solid = SOLID_NOT;
	self.exteriorweaponentity.exteriorweaponentity = self.exteriorweaponentity;
	self.exteriorweaponentity.owner = self;
	setorigin(self.exteriorweaponentity, '0 0 0');
	self.exteriorweaponentity.angles = '0 0 0';
	self.exteriorweaponentity.think = CL_ExteriorWeaponentity_Think;
	self.exteriorweaponentity.nextthink = time;

	{
		entity oldself = self;
		self = self.exteriorweaponentity;
		CSQCMODEL_AUTOINIT();
		self = oldself;
	}
}

// Weapon subs
void w_clear()
{
	if (self.weapon != -1)
	{
		self.weapon = 0;
		self.switchingweapon = 0;
	}
	if (self.weaponentity)
	{
		self.weaponentity.state = WS_CLEAR;
		self.weaponentity.effects = 0;
	}
}

void w_ready()
{
	if (self.weaponentity)
		self.weaponentity.state = WS_READY;
	weapon_thinkf(WFRAME_IDLE, 1000000, w_ready);
}

.float prevdryfire;
.float prevwarntime;
float weapon_prepareattack_checkammo(float secondary)
{
	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
	if (!WEP_ACTION(self.weapon, WR_CHECKAMMO1 + secondary))
	{
		// always keep the Mine Layer if we placed mines, so that we can detonate them
		entity mine;
		if(self.weapon == WEP_MINE_LAYER)
		for(mine = world; (mine = find(mine, classname, "mine")); ) if(mine.owner == self)
			return FALSE;

		if(self.weapon == self.switchweapon && time - self.prevdryfire > 1) // only play once BEFORE starting to switch weapons
		{
			sound (self, CH_WEAPON_A, "weapons/dryfire.wav", VOL_BASE, ATTN_NORM);
			self.prevdryfire = time;
		}

		if(WEP_ACTION(self.weapon, WR_CHECKAMMO2 - secondary)) // check if the other firing mode has enough ammo
		{
			if(time - self.prevwarntime > 1)
			{
				Send_Notification(
					NOTIF_ONE,
					self,
					MSG_MULTI,
					ITEM_WEAPON_PRIMORSEC,
					self.weapon,
					secondary,
					(1 - secondary)
				);
			}
			self.prevwarntime = time;
		}
		else // this weapon is totally unable to fire, switch to another one
		{
			W_SwitchToOtherWeapon(self);
		}
		
		return FALSE;
	}
	return TRUE;
}
.float race_penalty;
float weapon_prepareattack_check(float secondary, float attacktime)
{
	if(!weapon_prepareattack_checkammo(secondary))
		return FALSE;

	//if sv_ready_restart_after_countdown is set, don't allow the player to shoot
	//if all players readied up and the countdown is running
	if(time < game_starttime || time < self.race_penalty) {
		return FALSE;
	}

	if (timeout_status == TIMEOUT_ACTIVE) //don't allow the player to shoot while game is paused
		return FALSE;

	// do not even think about shooting if switching
	if(self.switchweapon != self.weapon)
		return FALSE;

	if(attacktime >= 0)
	{
		// don't fire if previous attack is not finished
		if (ATTACK_FINISHED(self) > time + self.weapon_frametime * 0.5)
			return FALSE;
		// don't fire while changing weapon
		if (self.weaponentity.state != WS_READY)
			return FALSE;
	}

	return TRUE;
}
float weapon_prepareattack_do(float secondary, float attacktime)
{
	self.weaponentity.state = WS_INUSE;

	self.spawnshieldtime = min(self.spawnshieldtime, time); // kill spawn shield when you fire

	// if the weapon hasn't been firing continuously, reset the timer
	if(attacktime >= 0)
	{
		if (ATTACK_FINISHED(self) < time - self.weapon_frametime * 1.5)
		{
			ATTACK_FINISHED(self) = time;
			//dprint("resetting attack finished to ", ftos(time), "\n");
		}
		ATTACK_FINISHED(self) = ATTACK_FINISHED(self) + attacktime * W_WeaponRateFactor();
	}
	self.bulletcounter += 1;
	//dprint("attack finished ", ftos(ATTACK_FINISHED(self)), "\n");
	return TRUE;
}
float weapon_prepareattack(float secondary, float attacktime)
{
	if(weapon_prepareattack_check(secondary, attacktime))
	{
		weapon_prepareattack_do(secondary, attacktime);
		return TRUE;
	}
	else
		return FALSE;
}

void weapon_thinkf(float fr, float t, void() func)
{
	vector a;
	vector of, or, ou;
	float restartanim;

	if(fr == WFRAME_DONTCHANGE)
	{
		fr = self.weaponentity.wframe;
		restartanim = FALSE;
	}
	else if (fr == WFRAME_IDLE)
		restartanim = FALSE;
	else
		restartanim = TRUE;

	of = v_forward;
	or = v_right;
	ou = v_up;

	if (self.weaponentity)
	{
		self.weaponentity.wframe = fr;
		a = '0 0 0';
		if (fr == WFRAME_IDLE)
			a = self.weaponentity.anim_idle;
		else if (fr == WFRAME_FIRE1)
			a = self.weaponentity.anim_fire1;
		else if (fr == WFRAME_FIRE2)
			a = self.weaponentity.anim_fire2;
		else // if (fr == WFRAME_RELOAD)
			a = self.weaponentity.anim_reload;
		a_z *= g_weaponratefactor;
		setanim(self.weaponentity, a, restartanim == FALSE, restartanim, restartanim);
	}

	v_forward = of;
	v_right = or;
	v_up = ou;

	if(self.weapon_think == w_ready && func != w_ready && self.weaponentity.state == WS_RAISE)
	{
		backtrace("Tried to override initial weapon think function - should this really happen?");
	}

	t *= W_WeaponRateFactor();

	// VorteX: haste can be added here
	if (self.weapon_think == w_ready)
	{
		self.weapon_nextthink = time;
		//dprint("started firing at ", ftos(time), "\n");
	}
	if (self.weapon_nextthink < time - self.weapon_frametime * 1.5 || self.weapon_nextthink > time + self.weapon_frametime * 1.5)
	{
		self.weapon_nextthink = time;
		//dprint("reset weapon animation timer at ", ftos(time), "\n");
	}
	self.weapon_nextthink = self.weapon_nextthink + t;
	self.weapon_think = func;
	//dprint("next ", ftos(self.weapon_nextthink), "\n");

	if((fr == WFRAME_FIRE1 || fr == WFRAME_FIRE2) && t)
	{
		if(self.weapon == WEP_SHOTGUN && fr == WFRAME_FIRE2)
			animdecide_setaction(self, ANIMACTION_MELEE, restartanim);
		else
			animdecide_setaction(self, ANIMACTION_SHOOT, restartanim);
	}
	else
	{
		if(self.anim_upper_action == ANIMACTION_SHOOT || self.anim_upper_action == ANIMACTION_MELEE)
			self.anim_upper_action = 0;
	}
}

void weapon_boblayer1(float spd, vector org)
{
	// VorteX: haste can be added here
}

vector W_CalculateProjectileVelocity(vector pvelocity, vector mvelocity, float forceAbsolute)
{
	vector mdirection;
	float mspeed;
	vector outvelocity;

	mvelocity = mvelocity * g_weaponspeedfactor;

	mdirection = normalize(mvelocity);
	mspeed = vlen(mvelocity);

	outvelocity = get_shotvelocity(pvelocity, mdirection, mspeed, (forceAbsolute ? 0 : autocvar_g_projectiles_newton_style), autocvar_g_projectiles_newton_style_2_minfactor, autocvar_g_projectiles_newton_style_2_maxfactor);

	return outvelocity;
}

void W_AttachToShotorg(entity flash, vector offset)
{
	entity xflash;
	flash.owner = self;
	flash.angles_z = random() * 360;

	if(gettagindex(self.weaponentity, "shot"))
		setattachment(flash, self.weaponentity, "shot");
	else
		setattachment(flash, self.weaponentity, "tag_shot");
	setorigin(flash, offset);

	xflash = spawn();
	copyentity(flash, xflash);

	flash.viewmodelforclient = self;

	if(self.weaponentity.oldorigin_x > 0)
	{
		setattachment(xflash, self.exteriorweaponentity, "");
		setorigin(xflash, self.weaponentity.oldorigin + offset);
	}
	else
	{
		if(gettagindex(self.exteriorweaponentity, "shot"))
			setattachment(xflash, self.exteriorweaponentity, "shot");
		else
			setattachment(xflash, self.exteriorweaponentity, "tag_shot");
		setorigin(xflash, offset);
	}
}

#if 0
float mspercallsum;
float mspercallsstyle;
float mspercallcount;
#endif
void W_SetupProjectileVelocityEx(entity missile, vector dir, vector upDir, float pSpeed, float pUpSpeed, float pZSpeed, float spread, float forceAbsolute)
{
	if(missile.owner == world)
		error("Unowned missile");

	dir = dir + upDir * (pUpSpeed / pSpeed);
	dir_z += pZSpeed / pSpeed;
	pSpeed *= vlen(dir);
	dir = normalize(dir);

#if 0
	if(autocvar_g_projectiles_spread_style != mspercallsstyle)
	{
		mspercallsum = mspercallcount = 0;
		mspercallsstyle = autocvar_g_projectiles_spread_style;
	}
	mspercallsum -= gettime(GETTIME_HIRES);
#endif
	dir = W_CalculateSpread(dir, spread, g_weaponspreadfactor, autocvar_g_projectiles_spread_style);
#if 0
	mspercallsum += gettime(GETTIME_HIRES);
	mspercallcount += 1;
	print("avg: ", ftos(mspercallcount / mspercallsum), " per sec\n");
#endif

	missile.velocity = W_CalculateProjectileVelocity(missile.owner.velocity, pSpeed * dir, forceAbsolute);
}

void W_SetupProjectileVelocity(entity missile, float pSpeed, float spread)
{
	W_SetupProjectileVelocityEx(missile, w_shotdir, v_up, pSpeed, 0, 0, spread, FALSE);
}

#define W_SETUPPROJECTILEVELOCITY_UP(m,s) W_SetupProjectileVelocityEx(m, w_shotdir, v_up, cvar(#s "_speed"), cvar(#s "_speed_up"), cvar(#s "_speed_z"), cvar(#s "_spread"), FALSE)
#define W_SETUPPROJECTILEVELOCITY(m,s) W_SetupProjectileVelocityEx(m, w_shotdir, v_up, cvar(#s "_speed"), 0, 0, cvar(#s "_spread"), FALSE)

void W_DecreaseAmmo(.float ammo_type, float ammo_use, float ammo_reload) // WEAPONTODO: why does this have ammo_type?
{
	if((self.items & IT_UNLIMITED_WEAPON_AMMO) && !ammo_reload)
		return;

	// if this weapon is reloadable, decrease its load. Else decrease the player's ammo
	if(ammo_reload)
	{
		self.clip_load -= ammo_use;
		self.(weapon_load[self.weapon]) = self.clip_load;
	}
	else
		self.(self.current_ammo) -= ammo_use;
}

// weapon reloading code

.float reload_ammo_amount, reload_ammo_min, reload_time;
.float reload_complain;
.string reload_sound;

void W_ReloadedAndReady()
{
	// finish the reloading process, and do the ammo transfer

	self.clip_load = self.old_clip_load; // restore the ammo counter, in case we still had ammo in the weapon before reloading

	// if the gun uses no ammo, max out weapon load, else decrease ammo as we increase weapon load
	if(!self.reload_ammo_min || self.items & IT_UNLIMITED_WEAPON_AMMO)
		self.clip_load = self.reload_ammo_amount;
	else
	{
		while(self.clip_load < self.reload_ammo_amount && self.(self.current_ammo)) // make sure we don't add more ammo than we have
		{
			self.clip_load += 1;
			self.(self.current_ammo) -= 1;
		}
	}
	self.(weapon_load[self.weapon]) = self.clip_load;

	// do not set ATTACK_FINISHED in reload code any more. This causes annoying delays if eg: You start reloading a weapon,
	// then quickly switch to another weapon and back. Reloading is canceled, but the reload delay is still there,
	// so your weapon is disabled for a few seconds without reason

	//ATTACK_FINISHED(self) -= self.reload_time - 1;

	w_ready();
}

void W_Reload(float sent_ammo_min, float sent_ammo_amount, float sent_time, string sent_sound)
{
	// set global values to work with

	self.reload_ammo_min = sent_ammo_min;
	self.reload_ammo_amount = sent_ammo_amount;
	self.reload_time = sent_time;
	self.reload_sound = sent_sound;

	// check if we meet the necessary conditions to reload

	entity e;
	e = get_weaponinfo(self.weapon);

	// don't reload weapons that don't have the RELOADABLE flag
	if not(e.spawnflags & WEP_FLAG_RELOADABLE)
	{
		dprint("Warning: Attempted to reload a weapon that does not have the WEP_FLAG_RELOADABLE flag. Fix your code!\n");
		return;
	}

	// return if reloading is disabled for this weapon
	if(!self.reload_ammo_amount)
		return;

	// our weapon is fully loaded, no need to reload
	if (self.clip_load >= self.reload_ammo_amount)
		return;

	// no ammo, so nothing to load
	if(!self.(self.current_ammo) && self.reload_ammo_min)
	if not(self.items & IT_UNLIMITED_WEAPON_AMMO)
	{
		if(IS_REAL_CLIENT(self) && self.reload_complain < time)
		{
			play2(self, "weapons/unavailable.wav");
			sprint(self, strcat("You don't have enough ammo to reload the ^2", W_Name(self.weapon), "\n"));
			self.reload_complain = time + 1;
		}
		// switch away if the amount of ammo is not enough to keep using this weapon
		if not(WEP_ACTION(self.weapon, WR_CHECKAMMO1) + WEP_ACTION(self.weapon, WR_CHECKAMMO2))
		{
			self.clip_load = -1; // reload later
			W_SwitchToOtherWeapon(self);
		}
		return;
	}

	if (self.weaponentity)
	{
		if (self.weaponentity.wframe == WFRAME_RELOAD)
			return;

		// allow switching away while reloading, but this will cause a new reload!
		self.weaponentity.state = WS_READY;
	}

	// now begin the reloading process

	sound (self, CH_WEAPON_SINGLE, self.reload_sound, VOL_BASE, ATTN_NORM);

	// do not set ATTACK_FINISHED in reload code any more. This causes annoying delays if eg: You start reloading a weapon,
	// then quickly switch to another weapon and back. Reloading is canceled, but the reload delay is still there,
	// so your weapon is disabled for a few seconds without reason

	//ATTACK_FINISHED(self) = max(time, ATTACK_FINISHED(self)) + self.reload_time + 1;

	weapon_thinkf(WFRAME_RELOAD, self.reload_time, W_ReloadedAndReady);

	if(self.clip_load < 0)
		self.clip_load = 0;
	self.old_clip_load = self.clip_load;
	self.clip_load = self.(weapon_load[self.weapon]) = -1;
}
