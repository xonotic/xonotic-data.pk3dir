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


bool CL_Weaponentity_CustomizeEntityForClient()
{
	SELFPARAM();
	this.viewmodelforclient = this.owner;
	if (IS_SPEC(other) && other.enemy == this.owner) this.viewmodelforclient = other;
	return true;
}

vector CL_Weapon_GetShotOrg(int wpn)
{
	entity wi = Weapons_from(wpn);
	entity e = spawn();
	CL_WeaponEntity_SetModel(e, wi.mdl);
	vector ret = e.movedir;
	CL_WeaponEntity_SetModel(e, "");
	remove(e);
	return ret;
}

..entity weaponentity_fld;
.float m_alpha;

void CL_Weaponentity_Think()
{
	SELFPARAM();
	this.nextthink = time;
	if (intermission_running) this.frame = this.anim_idle.x;
	.entity weaponentity = this.weaponentity_fld;
	if (this.owner.(weaponentity) != this)
	{
		// owner has new gun; remove self
		if (this.weaponchild) remove(this.weaponchild);
		remove(this);
		return;
	}
	if (this.owner.deadflag != DEAD_NO)
	{
		// owner died; disappear
		this.model = "";
		if (this.weaponchild) this.weaponchild.model = "";
		return;
	}
	if (this.weaponname != this.owner.weaponname
	    || this.dmg != this.owner.modelindex
	    || this.deadflag != this.owner.deadflag)
	{
		// owner changed weapons; update appearance
		this.weaponname = this.owner.weaponname;
		this.dmg = this.owner.modelindex;
		this.deadflag = this.owner.deadflag;

		CL_WeaponEntity_SetModel(this, this.owner.weaponname);
	}

	this.alpha = -1;  // TODO: don't render this entity at all

	if (this.owner.alpha == default_player_alpha) this.m_alpha = default_weapon_alpha;
	else if (this.owner.alpha != 0) this.m_alpha = this.owner.alpha;
	else this.m_alpha  = 1;

	if (this.weaponchild)
	{
		this.weaponchild.alpha = this.alpha;
		this.weaponchild.effects = this.effects;
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
void CL_SpawnWeaponentity(entity actor, .entity weaponentity)
{
	entity view = actor.(weaponentity) = new(weaponentity);
	make_pure(view);
	view.solid = SOLID_NOT;
	view.owner = actor;
	setmodel(view, MDL_Null);  // precision set when changed
	setorigin(view, '0 0 0');
	view.weaponentity_fld = weaponentity;
	view.think = CL_Weaponentity_Think;
	view.nextthink = time;
	view.viewmodelforclient = actor;
	view.customizeentityforclient = CL_Weaponentity_CustomizeEntityForClient;

	if (weaponentity == weaponentities[0])
	{
		entity exterior = actor.exteriorweaponentity = new(exteriorweaponentity);
		make_pure(exterior);
		exterior.solid = SOLID_NOT;
		exterior.owner = actor;
		setorigin(exterior, '0 0 0');
		exterior.think = CL_ExteriorWeaponentity_Think;
		exterior.nextthink = time;

		CSQCMODEL_AUTOINIT(exterior);
	}
}

// Weapon subs
void w_clear(Weapon thiswep, entity actor, .entity weaponentity, int fire)
{
	PS(actor).m_weapon = WEP_Null;
	PS(actor).m_switchingweapon = WEP_Null;
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
		if (!secondary && WEP_CVAR(shotgun, secondary) == 1) return false;           // no clicking, just allow

	if (thiswep == PS(actor).m_switchweapon && time - actor.prevdryfire > 1) // only play once BEFORE starting to switch weapons
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
	if (actor.weaponentity == NULL) return true;
	if (!weapon_prepareattack_checkammo(thiswep, actor, secondary)) return false;

	// if sv_ready_restart_after_countdown is set, don't allow the player to shoot
	// if all players readied up and the countdown is running
	if (time < game_starttime || time < actor.race_penalty) return false;

	if (timeout_status == TIMEOUT_ACTIVE)  // don't allow the player to shoot while game is paused
		return false;

	// do not even think about shooting if switching
	if (PS(actor).m_switchweapon != PS(actor).m_weapon) return false;

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
	if (this == NULL) return;
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

void wframe_send(entity actor, entity weaponentity, vector a, bool restartanim);

/**
 * @param t defer thinking until time + t
 * @param func next think function
 */
void weapon_thinkf(entity actor, .entity weaponentity, WFRAME fr, float t, void(Weapon thiswep, entity actor,
	.entity weaponentity, int fire) func)
{
	entity this = actor.(weaponentity);
	if (this == NULL) return;
	bool restartanim;
	if (fr == WFRAME_DONTCHANGE)
	{
		fr = this.wframe;
		restartanim = false;
	}
	else
	{
		restartanim = fr != WFRAME_IDLE;
	}

	vector of = v_forward;
	vector or = v_right;
	vector ou = v_up;

	vector a = '0 0 0';
    this.wframe = fr;
    if (fr == WFRAME_IDLE) a = this.anim_idle;
    else if (fr == WFRAME_FIRE1) a = this.anim_fire1;
    else if (fr == WFRAME_FIRE2) a = this.anim_fire2;
    else  // if (fr == WFRAME_RELOAD)
        a = this.anim_reload;
    a.z *= g_weaponratefactor;

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
	this.weapon_nextthink += t;
	if (weaponentity == weaponentities[0]) STAT(WEAPON_NEXTTHINK, actor) = this.weapon_nextthink;
	this.weapon_think = func;
	// dprint("next ", ftos(this.weapon_nextthink), "\n");

	if (this)
	{
		entity e;
		FOR_EACH_CLIENT(e) if (e == actor || (IS_SPEC(e) && e.enemy == actor)) wframe_send(e, this, a, restartanim);
	}

	if ((fr == WFRAME_FIRE1 || fr == WFRAME_FIRE2) && t)
	{
		int act = (fr == WFRAME_FIRE2 && (PS(actor).m_weapon == WEP_SHOCKWAVE || PS(actor).m_weapon == WEP_SHOTGUN))
			? ANIMACTION_MELEE
			: ANIMACTION_SHOOT
			;
		animdecide_setaction(actor, act, restartanim);
	}
	else if (actor.anim_upper_action == ANIMACTION_SHOOT || actor.anim_upper_action == ANIMACTION_MELEE)
	{
		actor.anim_upper_action = 0;
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
	.entity weaponentity = weaponentities[0];  // TODO: unhardcode
	entity this = actor.(weaponentity);
	if (frametime) actor.weapon_frametime = frametime;

	if (!this || actor.health < 1) return;  // Dead player can't use weapons and injure impulse commands


	if (forbidWeaponUse(actor))
	{
		if (actor.(weaponentity).state != WS_CLEAR)
		{
			Weapon wpn = PS(actor).m_weapon;
			w_ready(wpn, actor, weaponentity, (actor.BUTTON_ATCK ? 1 : 0) | (actor.BUTTON_ATCK2 ? 2 : 0));
			return;
		}
	}

	if (PS(actor).m_switchweapon == WEP_Null)
	{
		PS(actor).m_weapon = WEP_Null;
		PS(actor).m_switchingweapon = WEP_Null;
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
	if (PS(actor).m_weapon != PS(actor).m_switchweapon)
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
				Weapon newwep = PS(actor).m_switchweapon;
				PS(actor).m_switchingweapon = newwep;

				// the two weapon entities will notice this has changed and update their models
				PS(actor).m_weapon = newwep;
				actor.weaponname = newwep.mdl;
				actor.bulletcounter = 0;
				actor.ammo_field = newwep.ammo_field;
				newwep.wr_setup(newwep);
				this.state = WS_RAISE;

				// set our clip load to the load of the weapon we switched to, if it's reloadable
				if ((newwep.spawnflags & WEP_FLAG_RELOADABLE) && newwep.reloading_ammo)  // prevent accessing undefined cvars
				{
					actor.clip_load = actor.(weapon_load[PS(actor).m_switchweapon.m_id]);
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
				PS(actor).m_switchingweapon = PS(actor).m_switchweapon;
				break;
			}
			case WS_READY:
			{
				// start switching!
				PS(actor).m_switchingweapon = PS(actor).m_switchweapon;
				entity oldwep = PS(actor).m_weapon;

				// set up weapon switch think in the future, and start drop anim
				if (INDEPENDENT_ATTACK_FINISHED || ATTACK_FINISHED(actor, weaponslot(weaponentity)) <= time + actor.weapon_frametime * 0.5)
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

	int w = PS(actor).m_weapon.m_id;

	// call the think code which may fire the weapon
	// and do so multiple times to resolve framerate dependency issues if the
	// server framerate is very low and the weapon fire rate very high
	for (int c = 0; c < W_TICSPERFRAME; ++c)
	{
		if (w && !(actor.weapons & WepSet_FromWeapon(Weapons_from(w))))
		{
			if (PS(actor).m_weapon == PS(actor).m_switchweapon) W_SwitchWeapon_Force(actor, w_getbestweapon(actor));
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
				if (key_pressed && PS(actor).m_switchweapon != WEP_HOOK && !actor.hook_switchweapon)
					W_SwitchWeapon(WEP_HOOK);
				actor.hook_switchweapon = key_pressed;
				Weapon h = WEP_HOOK;
				block_weapon = (PS(actor).m_weapon == h && (actor.BUTTON_ATCK || key_pressed));
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
				Weapon e = PS(actor).m_weapon;
				e.wr_think(e, actor, weaponentity, (actor.BUTTON_ATCK ? 1 : 0) | (actor.BUTTON_ATCK2 ? 2 : 0));
			}
			else
			{
				Weapon w = PS(actor).m_weapon;
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
				Weapon wpn = PS(actor).m_weapon;
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

	entity view = actor.(weaponentity);
	entity exterior = actor.exteriorweaponentity;

	if (gettagindex(view, "shot")) setattachment(flash, view, "shot");
	else setattachment(flash, view, "tag_shot");
	setorigin(flash, offset);

	entity xflash = spawn();
	copyentity(flash, xflash);

	flash.viewmodelforclient = actor;

	if (view.oldorigin.x > 0)
	{
		setattachment(xflash, exterior, "");
		setorigin(xflash, view.oldorigin + offset);
	}
	else
	{
		if (gettagindex(exterior, "shot")) setattachment(xflash, exterior, "shot");
		else setattachment(xflash, exterior, "tag_shot");
		setorigin(xflash, offset);
	}
}

void W_DecreaseAmmo(Weapon wep, entity actor, float ammo_use)
{
	if (MUTATOR_CALLHOOK(W_DecreaseAmmo, actor)) return;

	if ((actor.items & IT_UNLIMITED_WEAPON_AMMO) && !wep.reloading_ammo) return;

	// if this weapon is reloadable, decrease its load. Else decrease the player's ammo
	if (wep.reloading_ammo)
	{
		actor.clip_load -= ammo_use;
		actor.(weapon_load[PS(actor).m_weapon.m_id]) = actor.clip_load;
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
	actor.(weapon_load[PS(actor).m_weapon.m_id]) = actor.clip_load;

	// do not set ATTACK_FINISHED in reload code any more. This causes annoying delays if eg: You start reloading a weapon,
	// then quickly switch to another weapon and back. Reloading is canceled, but the reload delay is still there,
	// so your weapon is disabled for a few seconds without reason

	// ATTACK_FINISHED(actor, slot) -= actor.reload_time - 1;

	Weapon wpn = Weapons_from(PS(actor).m_weapon.m_id);
	w_ready(wpn, actor, weaponentity, (actor.BUTTON_ATCK ? 1 : 0) | (actor.BUTTON_ATCK2 ? 2 : 0));
}

void W_Reload(entity actor, float sent_ammo_min, string sent_sound)
{
	.entity weaponentity = weaponentities[0];
	// set global values to work with
	Weapon e = PS(actor).m_weapon;

	if (MUTATOR_CALLHOOK(W_Reload, actor)) return;

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
					sprint(actor, strcat("You don't have enough ammo to reload the ^2", PS(actor).m_weapon.m_name, "\n"));
					actor.reload_complain = time + 1;
				}
				// switch away if the amount of ammo is not enough to keep using this weapon
				Weapon w = PS(actor).m_weapon;
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
	actor.clip_load = actor.(weapon_load[PS(actor).m_weapon.m_id]) = -1;
}

void W_DropEvent(.void(Weapon) event, entity player, float weapon_type, entity weapon_item)
{
	Weapon w = Weapons_from(weapon_type);
	weapon_dropevent_item = weapon_item;
	WITH(entity, self, player, w.event(w));
}
