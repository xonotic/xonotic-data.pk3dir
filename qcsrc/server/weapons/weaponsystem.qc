#include "weaponsystem.qh"

#include <common/animdecide.qh>
#include <common/constants.qh>
#include <common/items/_mod.qh>
#include <common/mapobjects/platforms.qh>
#include <common/monsters/_mod.qh>
#include <common/mutators/mutator/status_effects/_mod.qh>
#include <common/net_linked.qh>
#include <common/notifications/all.qh>
#include <common/resources/sv_resources.qh>
#include <common/state.qh>
#include <common/util.qh>
#include <common/vehicles/all.qh>
#include <common/weapons/_all.qh>
#include <common/wepent.qh>
#include <lib/csqcmodel/sv_model.qh>
#include <server/cheats.qh>
#include <server/client.qh>
#include <server/command/common.qh>
#include <server/damage.qh>
#include <server/items/items.qh>
#include <server/hook.qh>
#include <server/mutators/_mod.qh>
#include <server/round_handler.qh>
#include <server/weapons/selection.qh>
#include <server/world.qh>

.int state;

.float weapon_frametime;

float W_WeaponRateFactor(entity this)
{
	float t = 1;
	if(autocvar_g_weaponratefactor > 0)
		t = 1.0 / autocvar_g_weaponratefactor;

	MUTATOR_CALLHOOK(WeaponRateFactor, t, this);
	t = M_ARGV(0, float);

	return t;
}

float W_WeaponSpeedFactor(entity this)
{
	float t = 1.0 * autocvar_g_weaponspeedfactor;

	MUTATOR_CALLHOOK(WeaponSpeedFactor, t, this);
	t = M_ARGV(0, float);

	return t;
}


bool CL_Weaponentity_CustomizeEntityForClient(entity this, entity client)
{
	this.viewmodelforclient = this.owner;
	if (IS_SPEC(client) && client.enemy == this.owner) this.viewmodelforclient = client;
	return false;
}

vector CL_Weapon_GetShotOrg(int wpn)
{
	entity wi = REGISTRY_GET(Weapons, wpn);
	entity e = spawn();
	CL_WeaponEntity_SetModel(e, wi.mdl, false);
	vector ret = e.movedir;
	CL_WeaponEntity_SetModel(e, "", false);
	delete(e);
	return ret;
}

.float m_alpha;
.string w_weaponname;
.int w_dmg;
.int w_deadflag;

void CL_Weaponentity_Think(entity this)
{
	this.nextthink = time;
	if (game_stopped) this.frame = this.anim_idle.x;
	.entity weaponentity = this.weaponentity_fld;
	if (this.owner.(weaponentity) != this)
	{
		// owner has new gun; remove old one
		if (this.weaponchild) delete(this.weaponchild);
		if (this.hook) delete(this.hook);
		delete(this);
		return;
	}
	if (IS_DEAD(this.owner))
	{
		// owner died; disappear
		this.model = "";
		if (this.weaponchild) this.weaponchild.model = "";
		return;
	}
	if (this.w_weaponname != this.weaponname || this.w_dmg != this.modelindex || this.w_deadflag != this.deadflag)
	{
		// owner changed weapons; update appearance
		this.w_weaponname = this.weaponname;
		this.w_dmg = this.modelindex;
		this.w_deadflag = this.deadflag;

		CL_WeaponEntity_SetModel(this, this.weaponname, true);
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

void CL_ExteriorWeaponentity_Think(entity this)
{
	this.nextthink = time;
	.entity weaponentity = this.weaponentity_fld;
	entity w_ent = this.owner.(weaponentity);
	if (this.owner.exteriorweaponentity != this)
	{
		delete(this);
		return;
	}
	if (IS_DEAD(this.owner))
	{
		this.model = "";
		return;
	}
	if (this.weaponname != w_ent.weaponname || this.dmg != w_ent.modelindex || this.deadflag != w_ent.deadflag)
	{
		this.weaponname = w_ent.weaponname;
		this.dmg = w_ent.modelindex;
		this.deadflag = w_ent.deadflag;
		if (w_ent.weaponname != "")
		{
			_setmodel(this, W_Model(strcat("v_", w_ent.weaponname, ".md3")));
			setsize(this, '0 0 0', '0 0 0');
		}
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

	Weapon wep = this.owner.(weaponentity).m_weapon;
	if (wep) this.glowmod = weaponentity_glowmod(wep, this.owner.clientcolors, this.owner.(weaponentity));
	this.colormap = this.owner.colormap;
	this.skin = w_ent.skin;

	CSQCMODEL_AUTOUPDATE(this);
}

// spawning weaponentity for client
void CL_SpawnWeaponentity(entity actor, .entity weaponentity)
{
	entity w_ent = actor.(weaponentity) = new(weaponentity);
	w_ent.solid = SOLID_NOT;
	w_ent.owner = actor;
	setmodel(w_ent, MDL_Null);  // precision set when changed
	setorigin(w_ent, '0 0 0');
	w_ent.weaponentity_fld = weaponentity;
	setthink(w_ent, CL_Weaponentity_Think);
	w_ent.nextthink = time;
	w_ent.viewmodelforclient = actor;
	w_ent.draggable = drag_undraggable;
	setcefc(w_ent, CL_Weaponentity_CustomizeEntityForClient);

	wepent_link(w_ent);

	if (weaponentity == weaponentities[0]) // only one exterior model, thank you very much
	{
		entity exterior = actor.exteriorweaponentity = new(exteriorweaponentity);
		exterior.solid = SOLID_NOT;
		exterior.owner = actor;
		exterior.draggable = drag_undraggable;
		exterior.weaponentity_fld = weaponentity;
		setorigin(exterior, '0 0 0');
		setthink(exterior, CL_ExteriorWeaponentity_Think);
		exterior.nextthink = time;

		CSQCMODEL_AUTOINIT(exterior);
	}
}

// Weapon subs
void w_clear(Weapon thiswep, entity actor, .entity weaponentity, int fire)
{
	entity w_ent = actor.(weaponentity);
	if (w_ent)
	{
		w_ent.m_weapon = WEP_Null;
		w_ent.m_switchingweapon = WEP_Null;
		w_ent.state = WS_CLEAR;
		w_ent.effects = 0;
	}
}

void w_ready(Weapon thiswep, entity actor, .entity weaponentity, int fire)
{
	entity w_ent = actor.(weaponentity);
	if (w_ent) w_ent.state = WS_READY;
	weapon_thinkf(actor, weaponentity, WFRAME_IDLE, 1000000, w_ready);
}

.float prevdryfire;
.float prevwarntime;
bool weapon_prepareattack_checkammo(Weapon thiswep, entity actor, bool secondary, .entity weaponentity)
{
	if ((actor.items & IT_UNLIMITED_AMMO)) return true;
	bool ammo = false;
	if (secondary) ammo = thiswep.wr_checkammo2(thiswep, actor, weaponentity);
	else ammo = thiswep.wr_checkammo1(thiswep, actor, weaponentity);
	if (ammo) return true;
	// always keep the Mine Layer if we placed mines, so that we can detonate them
	if (thiswep == WEP_MINE_LAYER)
	{
		IL_EACH(g_mines, it.owner == actor && it.weaponentity_fld == weaponentity,
		{
			return false;
		});
	}

	if (thiswep == WEP_SHOTGUN)
		if (!secondary && WEP_CVAR(WEP_SHOTGUN, secondary) == 1) return false;           // no clicking, just allow

	if (thiswep == actor.(weaponentity).m_switchweapon && time - actor.prevdryfire > 1) // only play once BEFORE starting to switch weapons
	{
		sound(actor, CH_WEAPON_A, SND_DRYFIRE, VOL_BASE, ATTEN_NORM);
		actor.prevdryfire = time;
	}

	// check if the other firing mode has enough ammo
	bool ammo_other = false;
	if (secondary) ammo_other = thiswep.wr_checkammo1(thiswep, actor, weaponentity);
	else ammo_other = thiswep.wr_checkammo2(thiswep, actor, weaponentity);
	if (ammo_other)
	{
		if (time - actor.prevwarntime > 1)
			Send_Notification(NOTIF_ONE, actor, MSG_MULTI, ITEM_WEAPON_PRIMORSEC, thiswep.m_id, secondary, (1 - secondary));
		actor.prevwarntime = time;
	}
	else  // this weapon is totally unable to fire, switch to another one
	{
		W_SwitchToOtherWeapon(actor, weaponentity);
	}

	return false;
}

.float race_penalty;
bool weapon_prepareattack_check(Weapon thiswep, entity actor, .entity weaponentity, bool secondary, float attacktime)
{
	if (actor.weaponentity == NULL) return true;
	if (!weapon_prepareattack_checkammo(thiswep, actor, secondary, weaponentity)) return false;

	// if sv_ready_restart_after_countdown is set, don't allow the player to shoot
	// if all players readied up and the countdown is running
	if (time < game_starttime || time < actor.race_penalty) return false;

	if (timeout_status == TIMEOUT_ACTIVE)  // don't allow the player to shoot while game is paused
		return false;

	// do not even think about shooting if switching
	if (actor.(weaponentity).m_switchweapon != actor.(weaponentity).m_weapon) return false;

	if (attacktime >= 0)
	{
		// don't fire if previous attack is not finished
		if (ATTACK_FINISHED(actor, weaponentity) > time + actor.(weaponentity).weapon_frametime * 0.5) return false;
		entity this = actor.(weaponentity);
		// don't fire while changing weapon
		if (!actor.vehicle && this.state != WS_READY) return false;
	}
	return true;
}

void weapon_prepareattack_do(entity actor, .entity weaponentity, bool secondary, float attacktime)
{
	entity this = actor.(weaponentity);
	if (this == NULL) return;
	this.state = WS_INUSE;

	if(StatusEffects_active(STATUSEFFECT_SpawnShield, actor)) // given this is performed often, perform a lighter check first
		StatusEffects_remove(STATUSEFFECT_SpawnShield, actor, STATUSEFFECT_REMOVE_CLEAR); // kill spawn shield when you fire

	// if the weapon hasn't been firing continuously, reset the timer
	if (attacktime >= 0)
	{
		if (ATTACK_FINISHED(actor, weaponentity) < time - this.weapon_frametime * 1.5)
		{
			ATTACK_FINISHED(actor, weaponentity) = time;
			// dprint("resetting attack finished to ", ftos(time), "\n");
		}
		float arate = W_WeaponRateFactor(actor);
		ATTACK_FINISHED(actor, weaponentity) = ATTACK_FINISHED(actor, weaponentity) + attacktime * arate;

		if(autocvar_g_weaponswitch_debug_alternate && W_DualWielding(actor))
		{
			int slot = weaponslot(weaponentity);
			for(int wepslot = 0; wepslot < MAX_WEAPONSLOTS; ++wepslot)
			{
				if(slot == wepslot)
					continue;
				.entity wepent = weaponentities[wepslot];
				if(actor.(wepent) && actor.(wepent).m_weapon != WEP_Null)
				{
					if(ATTACK_FINISHED(actor, wepent) > time + actor.(wepent).weapon_frametime * 0.5)
						continue; // still cooling down!
					if (ATTACK_FINISHED(actor, wepent) < time - actor.(wepent).weapon_frametime * 1.5)
						ATTACK_FINISHED(actor, wepent) = time;
					ATTACK_FINISHED(actor, wepent) = ATTACK_FINISHED(actor, wepent) + (attacktime * arate) / MAX_WEAPONSLOTS;
				}
			}
		}
	}
	this.bulletcounter += 1;
	// dprint("attack finished ", ftos(ATTACK_FINISHED(actor, weaponentity)), "\n");
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
		// this can happen when the weapon entity is newly spawned, since it has a clear state and no previous weapon frame
		if (this.wframe == WFRAME_DONTCHANGE)
			this.wframe = WFRAME_IDLE;
		fr = this.wframe;
		restartanim = false;
	}
	else
	{
		restartanim = fr != WFRAME_IDLE;
	}

	this.wframe = fr;

	if (this.weapon_think == w_ready && func != w_ready && this.state == WS_RAISE)
		backtrace("Tried to override initial weapon think function - should this really happen?");

	t *= W_WeaponRateFactor(actor);

	// VorteX: haste can be added here
	if (this.weapon_think == w_ready)
	{
		this.weapon_nextthink = time;
		// dprint("started firing at ", ftos(time), "\n");
	}
	float w_frametime_limit = this.weapon_frametime * 1.5;
	if (this.weapon_nextthink < time - w_frametime_limit || this.weapon_nextthink > time + w_frametime_limit)
	{
		this.weapon_nextthink = time;
		// dprint("reset weapon animation timer at ", ftos(time), "\n");
	}
	this.weapon_nextthink += t;
	this.weapon_think = func;
	// dprint("next ", ftos(this.weapon_nextthink), "\n");

	if (this)
	{
		FOREACH_CLIENT(true, {
			if(it == actor || (IS_SPEC(it) && it.enemy == actor))
				wframe_send(it, this, fr, autocvar_g_weaponratefactor, restartanim);
		});
	}

	if ((fr == WFRAME_FIRE1 || fr == WFRAME_FIRE2) && t)
	{
		bool primary_melee = boolean(fr == WFRAME_FIRE1 && (this.m_weapon.spawnflags & WEP_TYPE_MELEE_PRI));
		bool secondary_melee = boolean(fr == WFRAME_FIRE2 && (this.m_weapon.spawnflags & WEP_TYPE_MELEE_SEC));
		int act = (primary_melee || secondary_melee) ? ANIMACTION_MELEE : ANIMACTION_SHOOT;
		animdecide_setaction(actor, act, restartanim);
	}
	else if (actor.anim_upper_action == ANIMACTION_SHOOT || actor.anim_upper_action == ANIMACTION_MELEE)
	{
		actor.anim_upper_action = 0;
	}
}

bool weaponUseForbidden(entity player)
{
	if (round_handler_IsActive() && !round_handler_IsRoundStarted()) return true;
	if (MUTATOR_CALLHOOK(ForbidWeaponUse, player)) return true;
	return false;
}

bool weaponLocked(entity player)
{
	if (time < game_starttime && !sv_ready_restart_after_countdown) return true;
	if (player.player_blocked) return true;
	if (game_stopped) return true;
	if (StatusEffects_active(STATUSEFFECT_Frozen, player)) return true;
	if (MUTATOR_CALLHOOK(LockWeapon, player)) return true;
	return false;
}

void W_ResetGunAlign(entity player, int preferred_alignment)
{
	if(W_DualWielding(player))
		preferred_alignment = 3; // right align, the second gun will default to left

	// clear current weapon slots' alignments so we can redo the calculations!
	for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	{
		.entity weaponentity = weaponentities[slot];
		if (player.(weaponentity))
			player.(weaponentity).m_gunalign = 0;
	}

	// now set the new values
	for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	{
		.entity weaponentity = weaponentities[slot];
		if (player.(weaponentity))
			player.(weaponentity).m_gunalign = W_GunAlign(player.(weaponentity), preferred_alignment);
	}
}

.bool hook_switchweapon;

void W_WeaponFrame(Player actor, .entity weaponentity)
{
	TC(Player, actor);
	TC(PlayerState, PS(actor));
	entity this = actor.(weaponentity);
	if (frametime) this.weapon_frametime = frametime;

	if (!this || GetResource(actor, RES_HEALTH) < 1) return;  // Dead player can't use weapons and injure impulse commands

	int button_atck = PHYS_INPUT_BUTTON_ATCK(actor);
	int button_atck2 = PHYS_INPUT_BUTTON_ATCK2(actor);

	if (weaponUseForbidden(actor))
		button_atck = button_atck2 = 0; // forbid primary and secondary fire, switching is allowed

	if (weaponLocked(actor))
	{
		if (this.state != WS_CLEAR)
		{
			Weapon wpn = this.m_weapon;
			w_ready(wpn, actor, weaponentity, button_atck | (button_atck2 << 1));
			return;
		}
	}

	if(autocvar_g_weaponswitch_debug == 2 && weaponslot(weaponentity) > 0)
	{
		.entity wepe1 = weaponentities[0];
		entity wep1 = actor.(wepe1);
		this.m_switchweapon = wep1.m_switchweapon;
		entity store = IS_PLAYER(actor) ? PS(actor) : actor;
		if(!(this.m_switchweapon.spawnflags & WEP_FLAG_DUALWIELD) && !(store.dual_weapons & wep1.m_switchweapon.m_wepset))
		{
			this.m_weapon = WEP_Null;
			this.m_switchingweapon = WEP_Null;
			this.m_switchweapon = WEP_Null;
			this.state = WS_CLEAR;
			this.weaponname = "";
			this.clip_load = this.clip_size = this.old_clip_load = 0;
			return;
		}
	}

	if (this.m_switchweapon == WEP_Null)
	{
		if (this.state != WS_CLEAR)
			w_ready(this.m_weapon, actor, weaponentity, button_atck | (button_atck2 << 1));
		this.m_weapon = WEP_Null;
		this.m_switchingweapon = WEP_Null;
		this.state = WS_CLEAR;
		this.weaponname = "";
		this.clip_load = this.clip_size = this.old_clip_load = 0;
		return;
	}

	vector fo, ri, up;
	MAKE_VECTORS(actor.v_angle, fo, ri, up);

	// Change weapon
	if (this.m_weapon != this.m_switchweapon)
	{
		switch (this.state)
		{
			default:
				LOG_WARNF("unhandled weaponentity (%i) state for player (%i): %d", this, actor, this.state);
				break;
			case WS_INUSE:
			case WS_RAISE:
				break;
			case WS_CLEAR:
			{
				// end switching!
				Weapon newwep = this.m_switchweapon;
				this.m_switchingweapon = newwep;

				// the two weapon entities will notice this has changed and update their models
				this.m_weapon = newwep;
				this.weaponname = newwep.mdl;
				this.bulletcounter = 0;
				newwep.wr_setup(newwep, actor, weaponentity);
				this.state = WS_RAISE;

				// set our clip load to the load of the weapon we switched to, if it's reloadable
				if ((newwep.spawnflags & WEP_FLAG_RELOADABLE) && newwep.reloading_ammo)  // prevent accessing undefined cvars
				{
					this.clip_load = this.(weapon_load[this.m_switchweapon.m_id]);
					this.clip_size = newwep.reloading_ammo;
				}
				else
				{
					this.clip_load = this.clip_size = 0;
				}

				weapon_thinkf(actor, weaponentity, WFRAME_DONTCHANGE, newwep.switchdelay_raise, w_ready);
				break;
			}
			case WS_DROP:
			{
				// in dropping phase we can switch at any time
				this.m_switchingweapon = this.m_switchweapon;
				break;
			}
			case WS_READY:
			{
				// start switching!
				this.m_switchingweapon = this.m_switchweapon;
				entity oldwep = this.m_weapon;

				// set up weapon switch think in the future, and start drop anim
				if (INDEPENDENT_ATTACK_FINISHED || ATTACK_FINISHED(actor, weaponentity) <= time + this.weapon_frametime * 0.5)
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
	//	print(ftos(frametime), " ", ftos(time), " >= ", ftos(ATTACK_FINISHED(actor, weaponentity)), " >= ", ftos(this.weapon_nextthink), "\n");

	Weapon w = this.m_weapon;

	// call the think code which may fire the weapon
	// and do so multiple times to resolve framerate dependency issues if the
	// server framerate is very low and the weapon fire rate very high
	for (int c = 0; c < W_TICSPERFRAME; ++c)
	{
		if (w != WEP_Null && !(STAT(WEAPONS, actor) & WepSet_FromWeapon(w)))
		{
			if (this.m_weapon == this.m_switchweapon)
				W_SwitchWeapon_Force(actor, w_getbestweapon(actor, weaponentity), weaponentity);
			w = WEP_Null;
		}

		v_forward = fo;
		v_right = ri;
		v_up = up;

		bool block_weapon = false;
		{
			bool key_pressed = PHYS_INPUT_BUTTON_HOOK(actor) && !actor.vehicle;
			if (weaponUseForbidden(actor))
				key_pressed = false;

			Weapon off = actor.offhand;
			if (off && (!(STAT(WEAPONS, actor) & WEPSET(HOOK)) || off != OFFHAND_HOOK))
			{
				if (off.offhand_think) off.offhand_think(off, actor, key_pressed);
			}
			else
			{
				if (key_pressed && this.m_switchweapon != WEP_HOOK && !actor.hook_switchweapon)
					W_SwitchWeapon(actor, WEP_HOOK, weaponentity);
				actor.hook_switchweapon = key_pressed;
				Weapon h = WEP_HOOK;
				block_weapon = (this.m_weapon == h && (button_atck || key_pressed));
				h.wr_think(h, actor, weaponentity, block_weapon ? 1 : 0);
			}
		}

		v_forward = fo;
		v_right = ri;
		v_up = up;

		if (!block_weapon)
		{
			Weapon e = this.m_weapon;
			TC(Weapon, e);
			if (w != WEP_Null)
			{
				e.wr_think(e, actor, weaponentity, button_atck | (button_atck2 << 1));
			}
			else if (e)
			{
				e.wr_gonethink(e, actor, weaponentity);
			}
		}

		if (time + this.weapon_frametime * 0.5 >= this.weapon_nextthink)
		{
			if (this.weapon_think)
			{
				v_forward = fo;
				v_right = ri;
				v_up = up;
				Weapon wpn = this.m_weapon;
				this.weapon_think(wpn, actor, weaponentity, button_atck | (button_atck2 << 1));
			}
			else
			{
				bprint("\{1}^1ERROR: undefined weapon think function for ", actor.netname, "\n");
			}
		}
	}
}

void W_AttachToShotorg(entity actor, .entity weaponentity, entity flash, vector offset)
{
	flash.owner = actor;
	flash.angles_z = random() * 360;

	entity w_ent = actor.(weaponentity);
	entity exterior = actor.exteriorweaponentity;

	if (gettagindex(w_ent, "shot")) setattachment(flash, w_ent, "shot");
	else setattachment(flash, w_ent, "tag_shot");
	setorigin(flash, offset);

	entity xflash = spawn();
	copyentity_qc(flash, xflash);

	flash.viewmodelforclient = actor;

	if (w_ent.oldorigin.x > 0)
	{
		setattachment(xflash, exterior, "");
		setorigin(xflash, w_ent.oldorigin + offset);
	}
	else
	{
		if (gettagindex(exterior, "shot")) setattachment(xflash, exterior, "shot");
		else setattachment(xflash, exterior, "tag_shot");
		setorigin(xflash, offset);
	}
}

void W_DecreaseAmmo(Weapon wep, entity actor, float ammo_use, .entity weaponentity)
{
	if (MUTATOR_CALLHOOK(W_DecreaseAmmo, actor, actor.(weaponentity), ammo_use)) return;
	if ((actor.items & IT_UNLIMITED_AMMO) && !wep.reloading_ammo) return;

	ammo_use = M_ARGV(2, float);

	entity w_ent = actor.(weaponentity);

	// if this weapon is reloadable, decrease its load. Else decrease the player's ammo
	if (wep.reloading_ammo)
	{
		w_ent.clip_load -= ammo_use;
		w_ent.(weapon_load[w_ent.m_weapon.m_id]) = w_ent.clip_load;
	}
	else if (wep.ammo_type != RES_NONE)
	{
		float ammo = GetResource(actor, wep.ammo_type);
		if (ammo < ammo_use)
		{
			backtrace(sprintf(
				"W_DecreaseAmmo(%.2f): '%s' subtracted too much %s from '%s', resulting with '%.2f' left... "
				"Please notify the developers immediately with a copy of this backtrace!\n",
				ammo_use, wep.netname, wep.ammo_type.netname, actor.netname, ammo));
		}
		SetResource(actor, wep.ammo_type, ammo - ammo_use);
	}
}

// weapon reloading code

.float reload_ammo_amount, reload_ammo_min, reload_time;
.float reload_complain;
.string reload_sound;

void W_ReloadedAndReady(Weapon thiswep, entity actor, .entity weaponentity, int fire)
{
	// finish the reloading process, and do the ammo transfer

	entity w_ent = actor.(weaponentity);
	Weapon wpn = w_ent.m_weapon;

	w_ent.clip_load = w_ent.old_clip_load;  // restore the ammo counter, in case we still had ammo in the weapon before reloading

	// if the gun uses no ammo, max out weapon load, else decrease ammo as we increase weapon load
	if (!w_ent.reload_ammo_min || (actor.items & IT_UNLIMITED_AMMO) || wpn.ammo_type == RES_NONE)
	{
		w_ent.clip_load = w_ent.reload_ammo_amount;
	}
	else
	{
		// make sure we don't add more ammo than we have
		float ammo = GetResource(actor, wpn.ammo_type);
		float load = min(w_ent.reload_ammo_amount - w_ent.clip_load, ammo);
		w_ent.clip_load += load;
		SetResource(actor, wpn.ammo_type, ammo - load);
	}
	w_ent.(weapon_load[w_ent.m_weapon.m_id]) = w_ent.clip_load;

	// do not set ATTACK_FINISHED in reload code any more. This causes annoying delays if eg: You start reloading a weapon,
	// then quickly switch to another weapon and back. Reloading is canceled, but the reload delay is still there,
	// so your weapon is disabled for a few seconds without reason

	// ATTACK_FINISHED(actor, weaponentity) -= w_ent.reload_time - 1;

	w_ready(wpn, actor, weaponentity, PHYS_INPUT_BUTTON_ATCK(actor) | (PHYS_INPUT_BUTTON_ATCK2(actor) << 1));
}

void W_Reload(entity actor, .entity weaponentity, float sent_ammo_min, Sound sent_sound)
{
	TC(Sound, sent_sound);
	// set global values to work with
	entity this = actor.(weaponentity);
	Weapon e = this.m_weapon;

	if (MUTATOR_CALLHOOK(W_Reload, actor)) return;

	this.reload_ammo_min = sent_ammo_min;
	this.reload_ammo_amount = e.reloading_ammo;
	this.reload_time = e.reloading_time;
	strcpy(actor.reload_sound, Sound_fixpath(sent_sound));

	// don't reload weapons that don't have the RELOADABLE flag
	if (!(e.spawnflags & WEP_FLAG_RELOADABLE))
	{
		LOG_TRACE(
			"Warning: Attempted to reload a weapon that does not have the WEP_FLAG_RELOADABLE flag. Fix your code!\n");
		return;
	}

	// return if reloading is disabled for this weapon
	if (!this.reload_ammo_amount) return;

	// our weapon is fully loaded, no need to reload
	if (this.clip_load >= this.reload_ammo_amount) return;

	// no ammo, so nothing to load
	if (e.ammo_type != RES_NONE)
	{
		if (!GetResource(actor, e.ammo_type) && this.reload_ammo_min)
		{
			if (!(actor.items & IT_UNLIMITED_AMMO))
			{
				if (autocvar_g_weaponswitch_debug == 2 && weaponslot(weaponentity) > 0)
					return; // in this case the primary weapon will do the switching when it runs out of ammo (TODO: do this same check but for other slots)
				if (IS_REAL_CLIENT(actor) && actor.reload_complain < time)
				{
					play2(actor, SND(UNAVAILABLE));
					sprint(actor, strcat("You don't have enough ammo to reload the ^2", this.m_weapon.m_name, "\n"));
					actor.reload_complain = time + 1;
				}
				// switch away if the amount of ammo is not enough to keep using this weapon
				if (!(e.wr_checkammo1(e, actor, weaponentity) + e.wr_checkammo2(e, actor, weaponentity)))
				{
					this.clip_load = -1;  // reload later
					W_SwitchToOtherWeapon(actor, weaponentity);
				}
				return;
			}
		}
	}
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

	// ATTACK_FINISHED(actor, weaponentity) = max(time, ATTACK_FINISHED(actor, weaponentity)) + this.reload_time + 1;

	weapon_thinkf(actor, weaponentity, WFRAME_RELOAD, this.reload_time, W_ReloadedAndReady);

	if (this.clip_load < 0) this.clip_load = 0;
	this.old_clip_load = this.clip_load;
	this.clip_load = this.(weapon_load[this.m_weapon.m_id]) = -1;
}

void W_DropEvent(.void(Weapon, entity actor, .entity) event, entity player, int weapon_type, entity weapon_item, .entity weaponentity)
{
	Weapon w = REGISTRY_GET(Weapons, weapon_type);
	weapon_dropevent_item = weapon_item;
	w.event(w, player, weaponentity);
}
