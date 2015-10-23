#include "weaponsystem.qh"

#include "selection.qh"

#include "../command/common.qh"
#include "../mutators/mutators_include.qh"
#include "../round_handler.qh"
#include "../t_items.qh"
#include "../../common/animdecide.qh"
#include "../../common/constants.qh"
#include "../../common/monsters/all.qh"
#include "../../common/notifications.qh"
#include "../../common/util.qh"
#include "../../common/weapons/all.qh"
#include "../../lib/csqcmodel/sv_model.qh"

vector shotorg_adjustfromclient(vector vecs, float y_is_right, float algn)
{
	switch(algn)
	{
		default: case 3: break; // right alignment
		case 4: vecs.y = -vecs.y; break; // left
		case 1: case 2: vecs.y = 0; vecs.z -= 2; break; // center
	}

	return vecs;
}

vector shotorg_adjust_values(vector vecs, bool y_is_right, bool visual, int algn)
{
	string s;

	if(visual)
		vecs = shotorg_adjustfromclient(vecs, y_is_right, algn);
	else if(autocvar_g_shootfromeye)
		vecs.y = vecs.z = 0;
	else if(autocvar_g_shootfromcenter)
	{
		vecs.y = 0;
		vecs.z -= 2;
	}
	else if((s = autocvar_g_shootfromfixedorigin) != "")
	{
		vector v = stov(s);
		if(y_is_right) { v.y = -v.y; }
		if(v.x != 0) { vecs.x = v.x; }
		vecs.y = v.y;
		vecs.z = v.z;
	}
	else // just do the same as top
		vecs = shotorg_adjustfromclient(vecs, y_is_right, algn);

	return vecs;
}

vector shotorg_adjust(vector vecs, bool y_is_right, bool visual, int algn)
{
	return shotorg_adjust_values(vecs, y_is_right, visual, algn);
}

.int state;

.float weapon_frametime;

float W_WeaponRateFactor()
{
	float t = 1.0 / g_weaponratefactor;

	MUTATOR_CALLHOOK(WeaponRateFactor, t);
	t = weapon_rate;

	return t;
}

float W_WeaponSpeedFactor()
{
	float t = 1.0 * g_weaponspeedfactor;

	MUTATOR_CALLHOOK(WeaponSpeedFactor, t);
	t = ret_float;

	return t;
}


void weapon_thinkf(entity actor, float fr, float t, void(Weapon thiswep, entity actor, bool fire1, bool fire2) func);

float CL_Weaponentity_CustomizeEntityForClient()
{SELFPARAM();
	self.viewmodelforclient = self.owner;
	if(IS_SPEC(other))
		if(other.enemy == self.owner)
			self.viewmodelforclient = other;
	return true;
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
{SELFPARAM();
	float v_shot_idx;
	if (name != "")
	{
		// if there is a child entity, hide it until we're sure we use it
		if (self.weaponentity)
			self.weaponentity.model = "";
		_setmodel(self, W_Model(strcat("v_", name, ".md3")));
		v_shot_idx = gettagindex(self, "shot"); // used later
		if(!v_shot_idx)
			v_shot_idx = gettagindex(self, "tag_shot");

		_setmodel(self, W_Model(strcat("h_", name, ".iqm")));
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
			_setmodel(self.weaponentity, W_Model(strcat("v_", name, ".md3")));
			setattachment(self.weaponentity, self, "weapon");
		}
		else if(gettagindex(self, "tag_weapon"))
		{
			if (!self.weaponentity)
				self.weaponentity = spawn();
			_setmodel(self.weaponentity, W_Model(strcat("v_", name, ".md3")));
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
				LOG_INFO("WARNING: weapon model ", self.model, " does not support the 'shot' tag, will display shots TOTALLY wrong\n");
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
				LOG_INFO("WARNING: weapon model ", self.model, " does not support the 'shell' tag, will display casings wrong\n");
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
				LOG_INFO("WARNING: weapon model ", self.model, " does not support the 'handle' tag and neither does the v_ model support the 'shot' tag, will display muzzle flashes TOTALLY wrong\n");
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

	if(self.movedir.x >= 0)
	{
		vector v0;
		v0 = self.movedir;
		self.movedir = shotorg_adjust(v0, false, false, self.owner.cvar_cl_gunalign);
		self.view_ofs = shotorg_adjust(v0, false, true, self.owner.cvar_cl_gunalign) - v0;
	}
	self.owner.stat_shotorg = compressShotOrigin(self.movedir);
	self.movedir = decompressShotOrigin(self.owner.stat_shotorg); // make them match perfectly

	self.spawnorigin += self.view_ofs; // offset the casings origin by the same amount

	// check if an instant weapon switch occurred
	setorigin(self, self.view_ofs);
	// reset animstate now
	self.wframe = WFRAME_IDLE;
	setanim(self, self.anim_idle, true, false, true);
}

vector CL_Weapon_GetShotOrg(float wpn)
{SELFPARAM();
	entity wi = get_weaponinfo(wpn);
	setself(spawn());
	CL_WeaponEntity_SetModel(wi.mdl);
	vector ret = self.movedir;
	CL_WeaponEntity_SetModel("");
	remove(self);
	setself(this);
	return ret;
}

void CL_Weaponentity_Think()
{SELFPARAM();
	int tb;
	self.nextthink = time;
	if (intermission_running)
		self.frame = self.anim_idle.x;
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
	self.effects &= ~EF_LOWPRECISION;
	self.effects &= ~EF_FULLBRIGHT; // can mask team color, so get rid of it
	self.effects &= ~EF_TELEPORT_BIT;
	self.effects &= ~EF_RESTARTANIM_BIT;
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
		self.angles_x = -90 * f * f;
	}
	else if (self.state == WS_DROP && !intermission_running)
	{
		entity oldwep = get_weaponinfo(self.owner.weapon);
		f = 1 - f * g_weaponratefactor / max(f, oldwep.switchdelay_drop);
		self.angles_x = -90 * f * f;
	}
	else if (self.state == WS_CLEAR)
	{
		f = 1;
		self.angles_x = -90 * f * f;
	}
}

void CL_ExteriorWeaponentity_Think()
{SELFPARAM();
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
			_setmodel(self, W_Model(strcat("v_", self.owner.weaponname, ".md3")));
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

	CSQCMODEL_AUTOUPDATE(self);
}

// spawning weaponentity for client
void CL_SpawnWeaponentity(entity e)
{
	entity view = e.weaponentity = spawn();
	view.classname = "weaponentity";
	view.solid = SOLID_NOT;
	view.owner = e;
	setmodel(view, MDL_Null); // precision set when changed
	setorigin(view, '0 0 0');
	view.angles = '0 0 0';
	view.viewmodelforclient = e;
	view.flags = 0;
	view.think = CL_Weaponentity_Think;
	view.customizeentityforclient = CL_Weaponentity_CustomizeEntityForClient;
	view.nextthink = time;

	entity exterior = e.exteriorweaponentity = spawn();
	exterior.classname = "exteriorweaponentity";
	exterior.solid = SOLID_NOT;
	exterior.exteriorweaponentity = exterior;
	exterior.owner = e;
	setorigin(exterior, '0 0 0');
	exterior.angles = '0 0 0';
	exterior.think = CL_ExteriorWeaponentity_Think;
	exterior.nextthink = time;

	CSQCMODEL_AUTOINIT(exterior);
}

// Weapon subs
void w_clear(Weapon thiswep, entity actor, bool fire1, bool fire2)
{
	if (actor.weapon != -1)
	{
		actor.weapon = 0;
		actor.switchingweapon = 0;
	}
	if (actor.weaponentity)
	{
		actor.weaponentity.state = WS_CLEAR;
		actor.weaponentity.effects = 0;
	}
}

void w_ready(Weapon thiswep, entity actor, bool fire1, bool fire2)
{
	if (actor.weaponentity)
		actor.weaponentity.state = WS_READY;
	weapon_thinkf(actor, WFRAME_IDLE, 1000000, w_ready);
}

.float prevdryfire;
.float prevwarntime;
bool weapon_prepareattack_checkammo(Weapon thiswep, entity actor, float secondary)
{
	if ((actor.items & IT_UNLIMITED_WEAPON_AMMO)) return true;
	bool ammo = false;
	if (secondary) {
		WITH(entity, self, actor, ammo = thiswep.wr_checkammo2(thiswep));
	} else {
		WITH(entity, self, actor, ammo = thiswep.wr_checkammo1(thiswep));
	}
	if (ammo) return true;
	// always keep the Mine Layer if we placed mines, so that we can detonate them
	entity mine;
	if(actor.weapon == WEP_MINE_LAYER.m_id)
	for(mine = world; (mine = find(mine, classname, "mine")); ) if(mine.owner == actor)
		return false;

	if(actor.weapon == WEP_SHOTGUN.m_id)
	if(!secondary && WEP_CVAR(shotgun, secondary) == 1)
		return false; // no clicking, just allow

	if(actor.weapon == actor.switchweapon && time - actor.prevdryfire > 1) // only play once BEFORE starting to switch weapons
	{
		sound (actor, CH_WEAPON_A, SND_DRYFIRE, VOL_BASE, ATTEN_NORM);
		actor.prevdryfire = time;
	}

	// check if the other firing mode has enough ammo
	bool ammo_other = false;
	if (secondary) {
		WITH(entity, self, actor, ammo = thiswep.wr_checkammo1(thiswep));
	} else {
		WITH(entity, self, actor, ammo = thiswep.wr_checkammo2(thiswep));
	}
	if (ammo_other)
	{
		if (time - actor.prevwarntime > 1)
		{
			Send_Notification(
				NOTIF_ONE,
				actor,
				MSG_MULTI,
				ITEM_WEAPON_PRIMORSEC,
				actor.weapon,
				secondary,
				(1 - secondary)
			);
		}
		actor.prevwarntime = time;
	}
	else // this weapon is totally unable to fire, switch to another one
	{
		W_SwitchToOtherWeapon(actor);
	}

	return false;
}
.float race_penalty;
bool weapon_prepareattack_check(Weapon thiswep, entity actor, bool secondary, float attacktime)
{
	if(!weapon_prepareattack_checkammo(thiswep, actor, secondary))
		return false;

	//if sv_ready_restart_after_countdown is set, don't allow the player to shoot
	//if all players readied up and the countdown is running
	if(time < game_starttime || time < actor.race_penalty) {
		return false;
	}

	if (timeout_status == TIMEOUT_ACTIVE) //don't allow the player to shoot while game is paused
		return false;

	// do not even think about shooting if switching
	if(actor.switchweapon != actor.weapon)
		return false;

	if(attacktime >= 0)
	{
		// don't fire if previous attack is not finished
		if (ATTACK_FINISHED(actor) > time + actor.weapon_frametime * 0.5)
			return false;
		// don't fire while changing weapon
		if (actor.weaponentity.state != WS_READY)
			return false;
	}
	return true;
}
void weapon_prepareattack_do(entity actor, bool secondary, float attacktime)
{
	actor.weaponentity.state = WS_INUSE;

	actor.spawnshieldtime = min(actor.spawnshieldtime, time); // kill spawn shield when you fire

	// if the weapon hasn't been firing continuously, reset the timer
	if(attacktime >= 0)
	{
		if (ATTACK_FINISHED(actor) < time - actor.weapon_frametime * 1.5)
		{
			ATTACK_FINISHED(actor) = time;
			//dprint("resetting attack finished to ", ftos(time), "\n");
		}
		ATTACK_FINISHED(actor) = ATTACK_FINISHED(actor) + attacktime * W_WeaponRateFactor();
	}
	actor.bulletcounter += 1;
	//dprint("attack finished ", ftos(ATTACK_FINISHED(actor)), "\n");
}
bool weapon_prepareattack(Weapon thiswep, entity actor, bool secondary, float attacktime)
{
	if (weapon_prepareattack_check(thiswep, actor, secondary, attacktime)) {
		weapon_prepareattack_do(actor, secondary, attacktime);
		return true;
	}
	return false;
}

void weapon_thinkf(entity actor, float fr, float t, void(Weapon thiswep, entity actor, bool fire1, bool fire2) func)
{
	vector a;
	vector of, or, ou;
	float restartanim;

	if(fr == WFRAME_DONTCHANGE)
	{
		fr = actor.weaponentity.wframe;
		restartanim = false;
	}
	else if (fr == WFRAME_IDLE)
		restartanim = false;
	else
		restartanim = true;

	of = v_forward;
	or = v_right;
	ou = v_up;

	if (actor.weaponentity)
	{
		actor.weaponentity.wframe = fr;
		a = '0 0 0';
		if (fr == WFRAME_IDLE)
			a = actor.weaponentity.anim_idle;
		else if (fr == WFRAME_FIRE1)
			a = actor.weaponentity.anim_fire1;
		else if (fr == WFRAME_FIRE2)
			a = actor.weaponentity.anim_fire2;
		else // if (fr == WFRAME_RELOAD)
			a = actor.weaponentity.anim_reload;
		a.z *= g_weaponratefactor;
		setanim(actor.weaponentity, a, restartanim == false, restartanim, restartanim);
	}

	v_forward = of;
	v_right = or;
	v_up = ou;

	if(actor.weapon_think == w_ready && func != w_ready && actor.weaponentity.state == WS_RAISE)
	{
		backtrace("Tried to override initial weapon think function - should this really happen?");
	}

	t *= W_WeaponRateFactor();

	// VorteX: haste can be added here
	if (actor.weapon_think == w_ready)
	{
		actor.weapon_nextthink = time;
		//dprint("started firing at ", ftos(time), "\n");
	}
	if (actor.weapon_nextthink < time - actor.weapon_frametime * 1.5 || actor.weapon_nextthink > time + actor.weapon_frametime * 1.5)
	{
		actor.weapon_nextthink = time;
		//dprint("reset weapon animation timer at ", ftos(time), "\n");
	}
	actor.weapon_nextthink = actor.weapon_nextthink + t;
	actor.weapon_think = func;
	//dprint("next ", ftos(actor.weapon_nextthink), "\n");

	if((fr == WFRAME_FIRE1 || fr == WFRAME_FIRE2) && t)
	{
		if((actor.weapon == WEP_SHOCKWAVE.m_id || actor.weapon == WEP_SHOTGUN.m_id) && fr == WFRAME_FIRE2)
			animdecide_setaction(actor, ANIMACTION_MELEE, restartanim);
		else
			animdecide_setaction(actor, ANIMACTION_SHOOT, restartanim);
	}
	else
	{
		if(actor.anim_upper_action == ANIMACTION_SHOOT || actor.anim_upper_action == ANIMACTION_MELEE)
			actor.anim_upper_action = 0;
	}
}

float forbidWeaponUse(entity player)
{
	if(time < game_starttime && !autocvar_sv_ready_restart_after_countdown)
		return 1;
	if(round_handler_IsActive() && !round_handler_IsRoundStarted())
		return 1;
	if(player.player_blocked)
		return 1;
	if(player.frozen)
		return 1;
	if(player.weapon_blocked)
		return 1;
	return 0;
}

.bool hook_switchweapon;

void W_WeaponFrame(entity actor)
{
	vector fo, ri, up;

	if (frametime)
		actor.weapon_frametime = frametime;

	if (!actor.weaponentity || actor.health < 1)
		return; // Dead player can't use weapons and injure impulse commands

	if(forbidWeaponUse(actor))
	if(actor.weaponentity.state != WS_CLEAR)
	{
		Weapon wpn = get_weaponinfo(actor.weapon);
		w_ready(wpn, actor, actor.BUTTON_ATCK, actor.BUTTON_ATCK2);
		return;
	}

	if(!actor.switchweapon)
	{
		actor.weapon = 0;
		actor.switchingweapon = 0;
		actor.weaponentity.state = WS_CLEAR;
		actor.weaponname = "";
		//actor.items &= ~IT_AMMO;
		return;
	}

	makevectors(actor.v_angle);
	fo = v_forward; // save them in case the weapon think functions change it
	ri = v_right;
	up = v_up;

	// Change weapon
	if (actor.weapon != actor.switchweapon)
	{
		if (actor.weaponentity.state == WS_CLEAR)
		{
			// end switching!
			actor.switchingweapon = actor.switchweapon;
			entity newwep = get_weaponinfo(actor.switchweapon);

			// the two weapon entities will notice this has changed and update their models
			actor.weapon = actor.switchweapon;
			actor.weaponname = newwep.mdl;
			actor.bulletcounter = 0;
			actor.ammo_field = newwep.ammo_field;
			Weapon w = get_weaponinfo(actor.switchweapon);
			w.wr_setup(w);
			actor.weaponentity.state = WS_RAISE;

			// set our clip load to the load of the weapon we switched to, if it's reloadable
			if(newwep.spawnflags & WEP_FLAG_RELOADABLE && newwep.reloading_ammo) // prevent accessing undefined cvars
			{
				actor.clip_load = actor.(weapon_load[actor.switchweapon]);
				actor.clip_size = newwep.reloading_ammo;
			}
			else
				actor.clip_load = actor.clip_size = 0;

			weapon_thinkf(actor, WFRAME_IDLE, newwep.switchdelay_raise, w_ready);
		}
		else if (actor.weaponentity.state == WS_DROP)
		{
			// in dropping phase we can switch at any time
			actor.switchingweapon = actor.switchweapon;
		}
		else if (actor.weaponentity.state == WS_READY)
		{
			// start switching!
			actor.switchingweapon = actor.switchweapon;
			entity oldwep = get_weaponinfo(actor.weapon);

			// set up weapon switch think in the future, and start drop anim
			#ifndef INDEPENDENT_ATTACK_FINISHED
			if(ATTACK_FINISHED(actor) <= time + actor.weapon_frametime * 0.5)
			{
			#endif
				sound(actor, CH_WEAPON_SINGLE, SND_WEAPON_SWITCH, VOL_BASE, ATTN_NORM);
				actor.weaponentity.state = WS_DROP;
				weapon_thinkf(actor, WFRAME_DONTCHANGE, oldwep.switchdelay_drop, w_clear);
			#ifndef INDEPENDENT_ATTACK_FINISHED
			}
			#endif
		}
	}

	// LordHavoc: network timing test code
	//if (actor.button0)
	//	print(ftos(frametime), " ", ftos(time), " >= ", ftos(ATTACK_FINISHED(actor)), " >= ", ftos(actor.weapon_nextthink), "\n");

	float w;
	w = actor.weapon;

	// call the think code which may fire the weapon
	// and do so multiple times to resolve framerate dependency issues if the
	// server framerate is very low and the weapon fire rate very high
	float c;
	c = 0;
	while (c < W_TICSPERFRAME)
	{
		c = c + 1;
		if(w && !(actor.weapons & WepSet_FromWeapon(w)))
		{
			if(actor.weapon == actor.switchweapon)
				W_SwitchWeapon_Force(actor, w_getbestweapon(actor));
			w = 0;
		}

		v_forward = fo;
		v_right = ri;
		v_up = up;

		bool block_weapon = false;
		{
			bool key_pressed = actor.BUTTON_HOOK && !actor.vehicle;
        	Weapon off = actor.offhand;
        	if (off && !(actor.weapons & WEPSET(HOOK))) {
        		if (off.offhand_think) off.offhand_think(off, actor, key_pressed);
        	} else {
        		if (key_pressed && actor.switchweapon != WEP_HOOK.m_id && !actor.hook_switchweapon) {
					W_SwitchWeapon(WEP_HOOK.m_id);
				}
				actor.hook_switchweapon = key_pressed;
				Weapon h = WEP_HOOK;
				block_weapon = (actor.weapon == h.m_id && (actor.BUTTON_ATCK || key_pressed));
				h.wr_think(h, actor, block_weapon, false);
        	}
        }

		if (!block_weapon)
		if (w) {
			Weapon e = get_weaponinfo(actor.weapon);
			e.wr_think(e, actor, actor.BUTTON_ATCK, actor.BUTTON_ATCK2);
		} else {
			Weapon w = get_weaponinfo(actor.weapon);
			w.wr_gonethink(w);
		}

		if (time + actor.weapon_frametime * 0.5 >= actor.weapon_nextthink)
		{
			if(actor.weapon_think)
			{
				v_forward = fo;
				v_right = ri;
				v_up = up;
				Weapon wpn = get_weaponinfo(actor.weapon);
				actor.weapon_think(wpn, actor, actor.BUTTON_ATCK, actor.BUTTON_ATCK2);
			}
			else
				bprint("\{1}^1ERROR: undefined weapon think function for ", actor.netname, "\n");
		}
	}
}

void W_AttachToShotorg(entity actor, entity flash, vector offset)
{
	entity xflash;
	flash.owner = actor;
	flash.angles_z = random() * 360;

	if(gettagindex(actor.weaponentity, "shot"))
		setattachment(flash, actor.weaponentity, "shot");
	else
		setattachment(flash, actor.weaponentity, "tag_shot");
	setorigin(flash, offset);

	xflash = spawn();
	copyentity(flash, xflash);

	flash.viewmodelforclient = actor;

	if(actor.weaponentity.oldorigin.x > 0)
	{
		setattachment(xflash, actor.exteriorweaponentity, "");
		setorigin(xflash, actor.weaponentity.oldorigin + offset);
	}
	else
	{
		if(gettagindex(actor.exteriorweaponentity, "shot"))
			setattachment(xflash, actor.exteriorweaponentity, "shot");
		else
			setattachment(xflash, actor.exteriorweaponentity, "tag_shot");
		setorigin(xflash, offset);
	}
}

void W_DecreaseAmmo(Weapon wep, entity actor, float ammo_use)
{

	if(cvar("g_overkill"))
	if(actor.ok_use_ammocharge)
	{
		ok_DecreaseCharge(actor, actor.weapon);
		return; // TODO
	}

	if((actor.items & IT_UNLIMITED_WEAPON_AMMO) && !wep.reloading_ammo)
		return;

	// if this weapon is reloadable, decrease its load. Else decrease the player's ammo
	if(wep.reloading_ammo)
	{
		actor.clip_load -= ammo_use;
		actor.(weapon_load[actor.weapon]) = actor.clip_load;
	}
	else if(wep.ammo_field != ammo_none)
	{
		actor.(wep.ammo_field) -= ammo_use;
		if(actor.(wep.ammo_field) < 0)
		{
			backtrace(sprintf(
				"W_DecreaseAmmo(%.2f): '%s' subtracted too much %s from '%s', resulting with '%.2f' left... "
				"Please notify Samual immediately with a copy of this backtrace!\n",
				ammo_use,
				wep.netname,
				GetAmmoPicture(wep.ammo_field),
				actor.netname,
				actor.(wep.ammo_field)
			));
		}
	}
}

// weapon reloading code

.float reload_ammo_amount, reload_ammo_min, reload_time;
.float reload_complain;
.string reload_sound;

void W_ReloadedAndReady(Weapon thiswep, entity actor, bool fire1, bool fire2)
{
	// finish the reloading process, and do the ammo transfer

	actor.clip_load = actor.old_clip_load; // restore the ammo counter, in case we still had ammo in the weapon before reloading

	// if the gun uses no ammo, max out weapon load, else decrease ammo as we increase weapon load
	if(!actor.reload_ammo_min || actor.items & IT_UNLIMITED_WEAPON_AMMO || actor.ammo_field == ammo_none)
		actor.clip_load = actor.reload_ammo_amount;
	else
	{
		// make sure we don't add more ammo than we have
		float load = min(actor.reload_ammo_amount - actor.clip_load, actor.(actor.ammo_field));
        actor.clip_load += load;
        actor.(actor.ammo_field) -= load;
	}
	actor.(weapon_load[actor.weapon]) = actor.clip_load;

	// do not set ATTACK_FINISHED in reload code any more. This causes annoying delays if eg: You start reloading a weapon,
	// then quickly switch to another weapon and back. Reloading is canceled, but the reload delay is still there,
	// so your weapon is disabled for a few seconds without reason

	//ATTACK_FINISHED(actor) -= actor.reload_time - 1;

	Weapon wpn = get_weaponinfo(actor.weapon);
	w_ready(wpn, actor, actor.BUTTON_ATCK, actor.BUTTON_ATCK2);
}

void W_Reload(entity actor, float sent_ammo_min, string sent_sound)
{
	// set global values to work with
	entity e;
	e = get_weaponinfo(actor.weapon);

	if(cvar("g_overkill"))
	if(actor.ok_use_ammocharge)
		return; // TODO

	actor.reload_ammo_min = sent_ammo_min;
	actor.reload_ammo_amount = e.reloading_ammo;
	actor.reload_time = e.reloading_time;
	actor.reload_sound = sent_sound;

	// don't reload weapons that don't have the RELOADABLE flag
	if (!(e.spawnflags & WEP_FLAG_RELOADABLE))
	{
		LOG_TRACE("Warning: Attempted to reload a weapon that does not have the WEP_FLAG_RELOADABLE flag. Fix your code!\n");
		return;
	}

	// return if reloading is disabled for this weapon
	if(!actor.reload_ammo_amount)
		return;

	// our weapon is fully loaded, no need to reload
	if (actor.clip_load >= actor.reload_ammo_amount)
		return;

	// no ammo, so nothing to load
	if(actor.ammo_field != ammo_none)
	if(!actor.(actor.ammo_field) && actor.reload_ammo_min)
	if (!(actor.items & IT_UNLIMITED_WEAPON_AMMO))
	{
		if(IS_REAL_CLIENT(actor) && actor.reload_complain < time)
		{
			play2(actor, SND(UNAVAILABLE));
			sprint(actor, strcat("You don't have enough ammo to reload the ^2", WEP_NAME(actor.weapon), "\n"));
			actor.reload_complain = time + 1;
		}
		// switch away if the amount of ammo is not enough to keep using this weapon
		Weapon w = get_weaponinfo(actor.weapon);
		if (!(w.wr_checkammo1(w) + w.wr_checkammo2(w)))
		{
			actor.clip_load = -1; // reload later
			W_SwitchToOtherWeapon(actor);
		}
		return;
	}

	if (actor.weaponentity)
	{
		if (actor.weaponentity.wframe == WFRAME_RELOAD)
			return;

		// allow switching away while reloading, but this will cause a new reload!
		actor.weaponentity.state = WS_READY;
	}

	// now begin the reloading process

	_sound(actor, CH_WEAPON_SINGLE, actor.reload_sound, VOL_BASE, ATTEN_NORM);

	// do not set ATTACK_FINISHED in reload code any more. This causes annoying delays if eg: You start reloading a weapon,
	// then quickly switch to another weapon and back. Reloading is canceled, but the reload delay is still there,
	// so your weapon is disabled for a few seconds without reason

	//ATTACK_FINISHED(actor) = max(time, ATTACK_FINISHED(actor)) + actor.reload_time + 1;

	weapon_thinkf(actor, WFRAME_RELOAD, actor.reload_time, W_ReloadedAndReady);

	if(actor.clip_load < 0)
		actor.clip_load = 0;
	actor.old_clip_load = actor.clip_load;
	actor.clip_load = actor.(weapon_load[actor.weapon]) = -1;
}

void W_DropEvent(.void(Weapon) event, entity player, float weapon_type, entity weapon_item)
{SELFPARAM();
	setself(player);
	weapon_dropevent_item = weapon_item;
	Weapon w = get_weaponinfo(weapon_type);
	w.event(w);
	setself(this);
}
