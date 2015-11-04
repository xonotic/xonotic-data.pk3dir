#include "weaponsystem.qh"

#include "selection.qh"

#include "../command/common.qh"
#include "../mutators/all.qh"
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
	switch (algn)
	{
		default: case 3: break; // right alignment
		case 4: vecs.y = -vecs.y;
			break;              // left
		case 1: case 2: vecs.y = 0;
			vecs.z -= 2;
			break;              // center
	}

	return vecs;
}

vector shotorg_adjust_values(vector vecs, bool y_is_right, bool visual, int algn)
{
	string s;

	if (visual)
	{
		vecs = shotorg_adjustfromclient(vecs, y_is_right, algn);
	}
	else if (autocvar_g_shootfromeye)
	{
		vecs.y = vecs.z = 0;
	}
	else if (autocvar_g_shootfromcenter)
	{
		vecs.y = 0;
		vecs.z -= 2;
	}
	else if ((s = autocvar_g_shootfromfixedorigin) != "")
	{
		vector v = stov(s);
		if (y_is_right) v.y = -v.y;
		if (v.x != 0) vecs.x = v.x;
		vecs.y = v.y;
		vecs.z = v.z;
	}
	else  // just do the same as top
	{
		vecs = shotorg_adjustfromclient(vecs, y_is_right, algn);
	}

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


void weapon_thinkf(entity actor, .entity weaponentity, float fr, float t, void(Weapon thiswep, entity actor,
    .entity weaponentity, int fire) func);

bool CL_Weaponentity_CustomizeEntityForClient()
{
	SELFPARAM();
	this.viewmodelforclient = this.owner;
	if (IS_SPEC(other) && other.enemy == this.owner) this.viewmodelforclient = other;
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
//   this.origin, this.angles
//   this.weaponentity
//   this.movedir, this.view_ofs
//   attachment stuff
//   anim stuff
// to free:
//   call again with ""
//   remove the ent
void CL_WeaponEntity_SetModel(entity this, .entity weaponentity, string name)
{
	if (name != "")
	{
		// if there is a child entity, hide it until we're sure we use it
		if (this.(weaponentity)) this.(weaponentity).model = "";
		_setmodel(this, W_Model(strcat("v_", name, ".md3")));
		int v_shot_idx = gettagindex(this, "shot");  // used later
		if (!v_shot_idx) v_shot_idx = gettagindex(this, "tag_shot");

		_setmodel(this, W_Model(strcat("h_", name, ".iqm")));
		// preset some defaults that work great for renamed zym files (which don't need an animinfo)
		this.anim_fire1  = animfixfps(this, '0 1 0.01', '0 0 0');
		this.anim_fire2  = animfixfps(this, '1 1 0.01', '0 0 0');
		this.anim_idle   = animfixfps(this, '2 1 0.01', '0 0 0');
		this.anim_reload = animfixfps(this, '3 1 0.01', '0 0 0');

		// if we have a "weapon" tag, let's attach the v_ model to it ("invisible hand" style model)
		// if we don't, this is a "real" animated model
		if (gettagindex(this, "weapon"))
		{
			if (!this.(weaponentity)) this.(weaponentity) = new(weaponentity);
			_setmodel(this.(weaponentity), W_Model(strcat("v_", name, ".md3")));
			setattachment(this.(weaponentity), this, "weapon");
		}
		else if (gettagindex(this, "tag_weapon"))
		{
			if (!this.(weaponentity)) this.(weaponentity) = new(weaponentity);
			_setmodel(this.(weaponentity), W_Model(strcat("v_", name, ".md3")));
			setattachment(this.(weaponentity), this, "tag_weapon");
		}
		else
		{
			if (this.(weaponentity)) remove(this.(weaponentity));
			this.(weaponentity) = NULL;
		}

		setorigin(this, '0 0 0');
		this.angles = '0 0 0';
		this.frame = 0;
		this.viewmodelforclient = NULL;

		float idx;

		if (v_shot_idx)  // v_ model attached to invisible h_ model
		{
			this.movedir = gettaginfo(this.(weaponentity), v_shot_idx);
		}
		else
		{
			idx = gettagindex(this, "shot");
			if (!idx) idx = gettagindex(this, "tag_shot");
			if (idx)
			{
				this.movedir = gettaginfo(this, idx);
			}
			else
			{
				LOG_INFO("WARNING: weapon model ", this.model,
					" does not support the 'shot' tag, will display shots TOTALLY wrong\n");
				this.movedir = '0 0 0';
			}
		}

		if (this.(weaponentity))  // v_ model attached to invisible h_ model
		{
			idx = gettagindex(this.(weaponentity), "shell");
			if (!idx) idx = gettagindex(this.(weaponentity), "tag_shell");
			if (idx) this.spawnorigin = gettaginfo(this.(weaponentity), idx);
		}
		else
		{
			idx = 0;
		}
		if (!idx)
		{
			idx = gettagindex(this, "shell");
			if (!idx) idx = gettagindex(this, "tag_shell");
			if (idx)
			{
				this.spawnorigin = gettaginfo(this, idx);
			}
			else
			{
				LOG_INFO("WARNING: weapon model ", this.model,
					" does not support the 'shell' tag, will display casings wrong\n");
				this.spawnorigin = this.movedir;
			}
		}

		if (v_shot_idx)
		{
			this.oldorigin = '0 0 0';  // use regular attachment
		}
		else
		{
			if (this.(weaponentity))
			{
				idx = gettagindex(this, "weapon");
				if (!idx) idx = gettagindex(this, "tag_weapon");
			}
			else
			{
				idx = gettagindex(this, "handle");
				if (!idx) idx = gettagindex(this, "tag_handle");
			}
			if (idx)
			{
				this.oldorigin = this.movedir - gettaginfo(this, idx);
			}
			else
			{
				LOG_INFO("WARNING: weapon model ", this.model,
					" does not support the 'handle' tag and neither does the v_ model support the 'shot' tag, will display muzzle flashes TOTALLY wrong\n");
				this.oldorigin = '0 0 0';  // there is no way to recover from this
			}
		}

		this.viewmodelforclient = this.owner;
	}
	else
	{
		this.model = "";
		if (this.(weaponentity)) remove(this.(weaponentity));
		this.(weaponentity) = NULL;
		this.movedir = '0 0 0';
		this.spawnorigin = '0 0 0';
		this.oldorigin = '0 0 0';
		this.anim_fire1  = '0 1 0.01';
		this.anim_fire2  = '0 1 0.01';
		this.anim_idle   = '0 1 0.01';
		this.anim_reload = '0 1 0.01';
	}

	this.view_ofs = '0 0 0';

	if (this.movedir.x >= 0)
	{
		vector v0 = this.movedir;
		this.movedir = shotorg_adjust(v0, false, false, this.owner.cvar_cl_gunalign);
		this.view_ofs = shotorg_adjust(v0, false, true, this.owner.cvar_cl_gunalign) - v0;
	}
	this.owner.stat_shotorg = compressShotOrigin(this.movedir);
	this.movedir = decompressShotOrigin(this.owner.stat_shotorg); // make them match perfectly

	this.spawnorigin += this.view_ofs;                            // offset the casings origin by the same amount

	// check if an instant weapon switch occurred
	setorigin(this, this.view_ofs);
	// reset animstate now
	this.wframe = WFRAME_IDLE;
	setanim(this, this.anim_idle, true, false, true);
}

vector CL_Weapon_GetShotOrg(float wpn)
{
	entity wi = Weapons_from(wpn);
	entity e = spawn();
	.entity weaponentity = weaponentities[0];
	CL_WeaponEntity_SetModel(e, weaponentity, wi.mdl);
	vector ret = e.movedir;
	CL_WeaponEntity_SetModel(e, weaponentity, "");
	remove(e);
	return ret;
}

..entity weaponentity_fld;

void CL_Weaponentity_Think()
{
	SELFPARAM();
	this.nextthink = time;
	if (intermission_running) this.frame = this.anim_idle.x;
	.entity weaponentity = this.weaponentity_fld;
	if (this.owner.(weaponentity) != this)
	{
		if (this.(weaponentity)) remove(this.(weaponentity));
		remove(this);
		return;
	}
	if (this.owner.deadflag != DEAD_NO)
	{
		this.model = "";
		if (this.(weaponentity)) this.(weaponentity).model = "";
		return;
	}
	if (this.weaponname != this.owner.weaponname || this.dmg != this.owner.modelindex
	    || this.deadflag != this.owner.deadflag)
	{
		this.weaponname = this.owner.weaponname;
		this.dmg = this.owner.modelindex;
		this.deadflag = this.owner.deadflag;

		CL_WeaponEntity_SetModel(this, weaponentity, this.owner.weaponname);
	}

	int tb = (this.effects & (EF_TELEPORT_BIT | EF_RESTARTANIM_BIT));
	this.effects = this.owner.effects & EFMASK_CHEAP;
	this.effects &= ~EF_LOWPRECISION;
	this.effects &= ~EF_FULLBRIGHT;  // can mask team color, so get rid of it
	this.effects &= ~EF_TELEPORT_BIT;
	this.effects &= ~EF_RESTARTANIM_BIT;
	this.effects |= tb;
	if (weaponentity != weaponentities[0]) this.effects |= EF_NODRAW;

	if (this.owner.alpha == default_player_alpha) this.alpha = default_weapon_alpha;
	else if (this.owner.alpha != 0) this.alpha = this.owner.alpha;
	else this.alpha = 1;

	this.glowmod = this.owner.weaponentity_glowmod;
	this.colormap = this.owner.colormap;
	if (this.(weaponentity))
	{
		this.(weaponentity).effects = this.effects;
		this.(weaponentity).alpha = this.alpha;
		this.(weaponentity).colormap = this.colormap;
		this.(weaponentity).glowmod = this.glowmod;
	}

	this.angles = '0 0 0';

	float f = this.weapon_nextthink - time;
	if (this.state == WS_RAISE && !intermission_running)
	{
		entity newwep = Weapons_from(this.owner.switchweapon);
		f = f * g_weaponratefactor / max(f, newwep.switchdelay_raise);
		this.angles_x = -90 * f * f;
	}
	else if (this.state == WS_DROP && !intermission_running)
	{
		entity oldwep = Weapons_from(this.owner.weapon);
		f = 1 - f * g_weaponratefactor / max(f, oldwep.switchdelay_drop);
		this.angles_x = -90 * f * f;
	}
	else if (this.state == WS_CLEAR)
	{
		f = 1;
		this.angles_x = -90 * f * f;
	}
}

void CL_ExteriorWeaponentity_Think()
{
	SELFPARAM();
	this.nextthink = time;
	if (this.owner.exteriorweaponentity != this)
	{
		remove(this);
		return;
	}
	if (this.owner.deadflag != DEAD_NO)
	{
		this.model = "";
		return;
	}
	if (this.weaponname != this.owner.weaponname || this.dmg != this.owner.modelindex
	    || this.deadflag != this.owner.deadflag)
	{
		this.weaponname = this.owner.weaponname;
		this.dmg = this.owner.modelindex;
		this.deadflag = this.owner.deadflag;
		if (this.owner.weaponname != "") _setmodel(this, W_Model(strcat("v_", this.owner.weaponname, ".md3")));
		else this.model = "";

		int tag_found;
		if ((tag_found = gettagindex(this.owner, "tag_weapon")))
		{
			this.tag_index = tag_found;
			this.tag_entity = this.owner;
		}
		else
		{
			setattachment(this, this.owner, "bip01 r hand");
		}
	}
	this.effects = this.owner.effects;
	this.effects |= EF_LOWPRECISION;
	this.effects = this.effects & EFMASK_CHEAP;  // eat performance
	if (this.owner.alpha == default_player_alpha) this.alpha = default_weapon_alpha;
	else if (this.owner.alpha != 0) this.alpha = this.owner.alpha;
	else this.alpha = 1;

	this.glowmod = this.owner.weaponentity_glowmod;
	this.colormap = this.owner.colormap;

	CSQCMODEL_AUTOUPDATE(this);
}

// spawning weaponentity for client
void CL_SpawnWeaponentity(entity e, .entity weaponentity)
{
	entity view = e.(weaponentity) = new(weaponentity);
	view.solid = SOLID_NOT;
	view.owner = e;
	setmodel(view, MDL_Null);  // precision set when changed
	setorigin(view, '0 0 0');
	view.angles = '0 0 0';
	view.viewmodelforclient = e;
	view.flags = 0;
	view.weaponentity_fld = weaponentity;
	view.think = CL_Weaponentity_Think;
	view.customizeentityforclient = CL_Weaponentity_CustomizeEntityForClient;
	view.nextthink = time;

	if (weaponentity == weaponentities[0])
	{
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
}

// Weapon subs
void w_clear(Weapon thiswep, entity actor, .entity weaponentity, int fire)
{
	if (actor.weapon != -1)
	{
		actor.weapon = 0;
		actor.switchingweapon = 0;
	}
	entity this = actor.(weaponentity);
	if (this)
	{
		this.state = WS_CLEAR;
		this.effects = 0;
	}
}

void w_ready(Weapon thiswep, entity actor, .entity weaponentity, int fire)
{
	entity this = actor.(weaponentity);
	if (this) this.state = WS_READY;
	weapon_thinkf(actor, weaponentity, WFRAME_IDLE, 1000000, w_ready);
}

.float prevdryfire;
.float prevwarntime;
bool weapon_prepareattack_checkammo(Weapon thiswep, entity actor, bool secondary)
{
	if ((actor.items & IT_UNLIMITED_WEAPON_AMMO)) return true;
	bool ammo = false;
	if (secondary) WITH(entity, self, actor, ammo = thiswep.wr_checkammo2(thiswep));
	else WITH(entity, self, actor, ammo = thiswep.wr_checkammo1(thiswep));
	if (ammo) return true;
	// always keep the Mine Layer if we placed mines, so that we can detonate them
	if (thiswep == WEP_MINE_LAYER)
		for (entity mine; (mine = find(mine, classname, "mine")); )
			if (mine.owner == actor) return false;

	if (thiswep == WEP_SHOTGUN)
		if (!secondary && WEP_CVAR(shotgun, secondary) == 1) return false;             // no clicking, just allow

	if (thiswep == Weapons_from(actor.switchweapon) && time - actor.prevdryfire > 1) // only play once BEFORE starting to switch weapons
	{
		sound(actor, CH_WEAPON_A, SND_DRYFIRE, VOL_BASE, ATTEN_NORM);
		actor.prevdryfire = time;
	}

	// check if the other firing mode has enough ammo
	bool ammo_other = false;
	if (secondary) WITH(entity, self, actor, ammo_other = thiswep.wr_checkammo1(thiswep));
	else WITH(entity, self, actor, ammo_other = thiswep.wr_checkammo2(thiswep));
	if (ammo_other)
	{
		if (time - actor.prevwarntime > 1)
		{
			Send_Notification(
				NOTIF_ONE,
				actor,
				MSG_MULTI,
				ITEM_WEAPON_PRIMORSEC,
				thiswep.m_id,
				secondary,
				(1 - secondary)
			                 );
		}
		actor.prevwarntime = time;
	}
	else  // this weapon is totally unable to fire, switch to another one
	{
		W_SwitchToOtherWeapon(actor);
	}

	return false;
}

.float race_penalty;
bool weapon_prepareattack_check(Weapon thiswep, entity actor, .entity weaponentity, bool secondary, float attacktime)
{
	if (!weapon_prepareattack_checkammo(thiswep, actor, secondary)) return false;

	// if sv_ready_restart_after_countdown is set, don't allow the player to shoot
	// if all players readied up and the countdown is running
	if (time < game_starttime || time < actor.race_penalty) return false;

	if (timeout_status == TIMEOUT_ACTIVE)  // don't allow the player to shoot while game is paused
		return false;

	// do not even think about shooting if switching
	if (actor.switchweapon != actor.weapon) return false;

	if (attacktime >= 0)
	{
		int slot = weaponslot(weaponentity);
		// don't fire if previous attack is not finished
		if (ATTACK_FINISHED(actor, slot) > time + actor.weapon_frametime * 0.5) return false;
		entity this = actor.(weaponentity);
		// don't fire while changing weapon
		if (this.state != WS_READY) return false;
	}
	return true;
}

void weapon_prepareattack_do(entity actor, .entity weaponentity, bool secondary, float attacktime)
{
	entity this = actor.(weaponentity);
	this.state = WS_INUSE;

	actor.spawnshieldtime = min(actor.spawnshieldtime, time);  // kill spawn shield when you fire

	// if the weapon hasn't been firing continuously, reset the timer
	if (attacktime >= 0)
	{
		int slot = weaponslot(weaponentity);
		if (ATTACK_FINISHED(actor, slot) < time - actor.weapon_frametime * 1.5)
		{
			ATTACK_FINISHED(actor, slot) = time;
			// dprint("resetting attack finished to ", ftos(time), "\n");
		}
		ATTACK_FINISHED(actor, slot) = ATTACK_FINISHED(actor, slot) + attacktime * W_WeaponRateFactor();
	}
	actor.bulletcounter += 1;
	// dprint("attack finished ", ftos(ATTACK_FINISHED(actor, slot)), "\n");
}

bool weapon_prepareattack(Weapon thiswep, entity actor, .entity weaponentity, bool secondary, float attacktime)
{
	if (weapon_prepareattack_check(thiswep, actor, weaponentity, secondary, attacktime))
	{
		weapon_prepareattack_do(actor, weaponentity, secondary, attacktime);
		return true;
	}
	return false;
}

void weapon_thinkf(entity actor, .entity weaponentity, float fr, float t, void(Weapon thiswep, entity actor,
	.entity weaponentity, int fire) func)
{
	entity this = actor.(weaponentity);
	bool restartanim;
	if (fr == WFRAME_DONTCHANGE)
	{
		fr = this.wframe;
		restartanim = false;
	}
	else if (fr == WFRAME_IDLE)
	{
		restartanim = false;
	}
	else
	{
		restartanim = true;
	}

	vector of = v_forward;
	vector or = v_right;
	vector ou = v_up;

	if (this)
	{
		this.wframe = fr;
		vector a = '0 0 0';
		if (fr == WFRAME_IDLE) a = this.anim_idle;
		else if (fr == WFRAME_FIRE1) a = this.anim_fire1;
		else if (fr == WFRAME_FIRE2) a = this.anim_fire2;
		else  // if (fr == WFRAME_RELOAD)
			a = this.anim_reload;
		a.z *= g_weaponratefactor;
		setanim(this, a, restartanim == false, restartanim, restartanim);
	}

	v_forward = of;
	v_right = or;
	v_up = ou;

	if (this.weapon_think == w_ready && func != w_ready && this.state == WS_RAISE) backtrace(
			"Tried to override initial weapon think function - should this really happen?");

	t *= W_WeaponRateFactor();

	// VorteX: haste can be added here
	if (this.weapon_think == w_ready)
	{
		this.weapon_nextthink = time;
		// dprint("started firing at ", ftos(time), "\n");
	}
	if (this.weapon_nextthink < time - actor.weapon_frametime * 1.5
	    || this.weapon_nextthink > time + actor.weapon_frametime * 1.5)
	{
		this.weapon_nextthink = time;
		// dprint("reset weapon animation timer at ", ftos(time), "\n");
	}
	this.weapon_nextthink = this.weapon_nextthink + t;
	this.weapon_think = func;
	// dprint("next ", ftos(this.weapon_nextthink), "\n");

	if ((fr == WFRAME_FIRE1 || fr == WFRAME_FIRE2) && t)
	{
		if ((actor.weapon == WEP_SHOCKWAVE.m_id || actor.weapon == WEP_SHOTGUN.m_id)
		    && fr == WFRAME_FIRE2) animdecide_setaction(actor, ANIMACTION_MELEE, restartanim);
		else animdecide_setaction(actor, ANIMACTION_SHOOT, restartanim);
	}
	else
	{
		if (actor.anim_upper_action == ANIMACTION_SHOOT
		    || actor.anim_upper_action == ANIMACTION_MELEE) actor.anim_upper_action = 0;
	}
}

bool forbidWeaponUse(entity player)
{
	if (time < game_starttime && !autocvar_sv_ready_restart_after_countdown) return true;
	if (round_handler_IsActive() && !round_handler_IsRoundStarted()) return true;
	if (player.player_blocked) return true;
	if (player.frozen) return true;
	if (player.weapon_blocked) return true;
	return false;
}

.bool hook_switchweapon;

void W_WeaponFrame(entity actor)
{
	.entity weaponentity = weaponentities[0]; // TODO: unhardcode
	entity this = actor.(weaponentity);
	if (frametime) actor.weapon_frametime = frametime;

	if (!this || actor.health < 1) return; // Dead player can't use weapons and injure impulse commands


	if (forbidWeaponUse(actor))
	{
		if (actor.(weaponentity).state != WS_CLEAR)
		{
			Weapon wpn = Weapons_from(actor.weapon);
			w_ready(wpn, actor, weaponentity, (actor.BUTTON_ATCK ? 1 : 0) | (actor.BUTTON_ATCK2 ? 2 : 0));
			return;
		}
	}

	if (actor.switchweapon == 0)
	{
		actor.weapon = 0;
		actor.switchingweapon = 0;
		this.state = WS_CLEAR;
		actor.weaponname = "";
		// actor.items &= ~IT_AMMO;
		return;
	}

	makevectors(actor.v_angle);
	vector fo = v_forward;  // save them in case the weapon think functions change it
	vector ri = v_right;
	vector up = v_up;

	// Change weapon
	if (actor.weapon != actor.switchweapon)
	{
		switch (this.state)
		{
			default:
				LOG_WARNINGF("unhandled weaponentity (%i) state for player (%i): %d\n", this, actor, this.state);
				break;
			case WS_INUSE:
			case WS_RAISE:
				break;
			case WS_CLEAR:
			{
				// end switching!
				actor.switchingweapon = actor.switchweapon;
				entity newwep = Weapons_from(actor.switchweapon);

				// the two weapon entities will notice this has changed and update their models
				actor.weapon = actor.switchweapon;
				actor.weaponname = newwep.mdl;
				actor.bulletcounter = 0;
				actor.ammo_field = newwep.ammo_field;
				newwep.wr_setup(newwep);
				this.state = WS_RAISE;

				// set our clip load to the load of the weapon we switched to, if it's reloadable
				if ((newwep.spawnflags & WEP_FLAG_RELOADABLE) && newwep.reloading_ammo)  // prevent accessing undefined cvars
				{
					actor.clip_load = actor.(weapon_load[actor.switchweapon]);
					actor.clip_size = newwep.reloading_ammo;
				}
				else
				{
					actor.clip_load = actor.clip_size = 0;
				}

				weapon_thinkf(actor, weaponentity, WFRAME_IDLE, newwep.switchdelay_raise, w_ready);
				break;
			}
			case WS_DROP:
			{
				// in dropping phase we can switch at any time
				actor.switchingweapon = actor.switchweapon;
				break;
			}
			case WS_READY:
			{
				// start switching!
				actor.switchingweapon = actor.switchweapon;
				entity oldwep = Weapons_from(actor.weapon);

				// set up weapon switch think in the future, and start drop anim
				if (
#if INDEPENDENT_ATTACK_FINISHED
					    true
#else
					    ATTACK_FINISHED(actor, slot) <= time + actor.weapon_frametime * 0.5
#endif
				   )
				{
					sound(actor, CH_WEAPON_SINGLE, SND_WEAPON_SWITCH, VOL_BASE, ATTN_NORM);
					this.state = WS_DROP;
					weapon_thinkf(actor, weaponentity, WFRAME_DONTCHANGE, oldwep.switchdelay_drop, w_clear);
				}
				break;
			}
		}
	}

	// LordHavoc: network timing test code
	// if (actor.button0)
	//	print(ftos(frametime), " ", ftos(time), " >= ", ftos(ATTACK_FINISHED(actor, slot)), " >= ", ftos(this.weapon_nextthink), "\n");

	int w = actor.weapon;

	// call the think code which may fire the weapon
	// and do so multiple times to resolve framerate dependency issues if the
	// server framerate is very low and the weapon fire rate very high
	for (int c = 0; c < W_TICSPERFRAME; ++c)
	{
		if (w && !(actor.weapons & WepSet_FromWeapon(w)))
		{
			if (actor.weapon == actor.switchweapon) W_SwitchWeapon_Force(actor, w_getbestweapon(actor));
			w = 0;
		}

		v_forward = fo;
		v_right = ri;
		v_up = up;

		bool block_weapon = false;
		{
			bool key_pressed = actor.BUTTON_HOOK && !actor.vehicle;
			Weapon off = actor.offhand;
			if (off && !(actor.weapons & WEPSET(HOOK)))
			{
				if (off.offhand_think) off.offhand_think(off, actor, key_pressed);
			}
			else
			{
				if (key_pressed && actor.switchweapon != WEP_HOOK.m_id && !actor.hook_switchweapon) W_SwitchWeapon(
						WEP_HOOK.m_id);
				actor.hook_switchweapon = key_pressed;
				Weapon h = WEP_HOOK;
				block_weapon = (actor.weapon == h.m_id && (actor.BUTTON_ATCK || key_pressed));
				h.wr_think(h, actor, weaponentity, block_weapon ? 1 : 0);
			}
		}

		v_forward = fo;
		v_right = ri;
		v_up = up;

		if (!block_weapon)
		{
			if (w)
			{
				Weapon e = Weapons_from(actor.weapon);
				e.wr_think(e, actor, weaponentity, (actor.BUTTON_ATCK ? 1 : 0) | (actor.BUTTON_ATCK2 ? 2 : 0));
			}
			else
			{
				Weapon w = Weapons_from(actor.weapon);
				w.wr_gonethink(w);
			}
		}

		if (time + actor.weapon_frametime * 0.5 >= this.weapon_nextthink)
		{
			if (this.weapon_think)
			{
				v_forward = fo;
				v_right = ri;
				v_up = up;
				Weapon wpn = Weapons_from(actor.weapon);
				this.weapon_think(wpn, actor, weaponentity,
					(actor.BUTTON_ATCK ? 1 : 0) | (actor.BUTTON_ATCK2 ? 2 : 0));
			}
			else
			{
				bprint("\{1}^1ERROR: undefined weapon think function for ", actor.netname, "\n");
			}
		}
	}
}

void W_AttachToShotorg(entity actor, entity flash, vector offset)
{
	.entity weaponentity = weaponentities[0];
	flash.owner = actor;
	flash.angles_z = random() * 360;

	entity this = actor.(weaponentity);
	if (gettagindex(this, "shot")) setattachment(flash, this, "shot");
	else setattachment(flash, this, "tag_shot");
	setorigin(flash, offset);

	entity xflash = spawn();
	copyentity(flash, xflash);

	flash.viewmodelforclient = actor;

	if (this.oldorigin.x > 0)
	{
		setattachment(xflash, actor.exteriorweaponentity, "");
		setorigin(xflash, this.oldorigin + offset);
	}
	else
	{
		if (gettagindex(actor.exteriorweaponentity, "shot")) setattachment(xflash, actor.exteriorweaponentity, "shot");
		else setattachment(xflash, actor.exteriorweaponentity, "tag_shot");
		setorigin(xflash, offset);
	}
}

void W_DecreaseAmmo(Weapon wep, entity actor, float ammo_use)
{
	if (cvar("g_overkill"))
	{
		if (actor.ok_use_ammocharge)
		{
			ok_DecreaseCharge(actor, actor.weapon);
			return;  // TODO
		}
	}

	if ((actor.items & IT_UNLIMITED_WEAPON_AMMO) && !wep.reloading_ammo) return;

	// if this weapon is reloadable, decrease its load. Else decrease the player's ammo
	if (wep.reloading_ammo)
	{
		actor.clip_load -= ammo_use;
		actor.(weapon_load[actor.weapon]) = actor.clip_load;
	}
	else if (wep.ammo_field != ammo_none)
	{
		actor.(wep.ammo_field) -= ammo_use;
		if (actor.(wep.ammo_field) < 0)
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

void W_ReloadedAndReady(Weapon thiswep, entity actor, .entity weaponentity, int fire)
{
	// finish the reloading process, and do the ammo transfer

	actor.clip_load = actor.old_clip_load;  // restore the ammo counter, in case we still had ammo in the weapon before reloading

	// if the gun uses no ammo, max out weapon load, else decrease ammo as we increase weapon load
	if (!actor.reload_ammo_min || actor.items & IT_UNLIMITED_WEAPON_AMMO || actor.ammo_field == ammo_none)
	{
		actor.clip_load = actor.reload_ammo_amount;
	}
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

	// ATTACK_FINISHED(actor, slot) -= actor.reload_time - 1;

	Weapon wpn = Weapons_from(actor.weapon);
	w_ready(wpn, actor, weaponentity, (actor.BUTTON_ATCK ? 1 : 0) | (actor.BUTTON_ATCK2 ? 2 : 0));
}

void W_Reload(entity actor, float sent_ammo_min, string sent_sound)
{
	.entity weaponentity = weaponentities[0];
	// set global values to work with
	entity e = Weapons_from(actor.weapon);

	if (cvar("g_overkill"))
		if (actor.ok_use_ammocharge) return;
	// TODO

	actor.reload_ammo_min = sent_ammo_min;
	actor.reload_ammo_amount = e.reloading_ammo;
	actor.reload_time = e.reloading_time;
	actor.reload_sound = sent_sound;

	// don't reload weapons that don't have the RELOADABLE flag
	if (!(e.spawnflags & WEP_FLAG_RELOADABLE))
	{
		LOG_TRACE(
			"Warning: Attempted to reload a weapon that does not have the WEP_FLAG_RELOADABLE flag. Fix your code!\n");
		return;
	}

	// return if reloading is disabled for this weapon
	if (!actor.reload_ammo_amount) return;

	// our weapon is fully loaded, no need to reload
	if (actor.clip_load >= actor.reload_ammo_amount) return;

	// no ammo, so nothing to load
	if (actor.ammo_field != ammo_none)
	{
		if (!actor.(actor.ammo_field) && actor.reload_ammo_min)
		{
			if (!(actor.items & IT_UNLIMITED_WEAPON_AMMO))
			{
				if (IS_REAL_CLIENT(actor) && actor.reload_complain < time)
				{
					play2(actor, SND(UNAVAILABLE));
					sprint(actor, strcat("You don't have enough ammo to reload the ^2", WEP_NAME(actor.weapon), "\n"));
					actor.reload_complain = time + 1;
				}
				// switch away if the amount of ammo is not enough to keep using this weapon
				Weapon w = Weapons_from(actor.weapon);
				if (!(w.wr_checkammo1(w) + w.wr_checkammo2(w)))
				{
					actor.clip_load = -1;  // reload later
					W_SwitchToOtherWeapon(actor);
				}
				return;
			}
		}
	}

	entity this = actor.(weaponentity);
	if (this)
	{
		if (this.wframe == WFRAME_RELOAD) return;

		// allow switching away while reloading, but this will cause a new reload!
		this.state = WS_READY;
	}

	// now begin the reloading process

	_sound(actor, CH_WEAPON_SINGLE, actor.reload_sound, VOL_BASE, ATTEN_NORM);

	// do not set ATTACK_FINISHED in reload code any more. This causes annoying delays if eg: You start reloading a weapon,
	// then quickly switch to another weapon and back. Reloading is canceled, but the reload delay is still there,
	// so your weapon is disabled for a few seconds without reason

	// ATTACK_FINISHED(actor, slot) = max(time, ATTACK_FINISHED(actor, slot)) + actor.reload_time + 1;

	weapon_thinkf(actor, weaponentity, WFRAME_RELOAD, actor.reload_time, W_ReloadedAndReady);

	if (actor.clip_load < 0) actor.clip_load = 0;
	actor.old_clip_load = actor.clip_load;
	actor.clip_load = actor.(weapon_load[actor.weapon]) = -1;
}

void W_DropEvent(.void(Weapon) event, entity player, float weapon_type, entity weapon_item)
{
	Weapon w = Weapons_from(weapon_type);
	weapon_dropevent_item = weapon_item;
	WITH(entity, self, player, w.event(w));
}
