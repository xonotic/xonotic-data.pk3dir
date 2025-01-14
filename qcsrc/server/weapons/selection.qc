#include "selection.qh"

#include <common/constants.qh>
#include <common/items/item.qh>
#include <common/mapobjects/triggers.qh>
#include <common/mutators/mutator/waypoints/waypointsprites.qh>
#include <common/net_linked.qh>
#include <common/replicate.qh>
#include <common/state.qh>
#include <common/util.qh>
#include <common/weapons/_all.qh>
#include <common/wepent.qh>
#include <server/items/items.qh>
#include <server/items/spawning.qh>
#include <server/weapons/weaponsystem.qh>

// switch between weapons
void Send_WeaponComplain(entity e, float wpn, float type)
{
	msg_entity = e;
	WriteHeader(MSG_ONE, TE_CSQC_WEAPONCOMPLAIN);
	WriteByte(MSG_ONE, wpn);
	WriteByte(MSG_ONE, type);
}

void Weapon_whereis(Weapon this, entity cl)
{
	if (!autocvar_g_showweaponspawns) return;
	IL_EACH(g_items, it.weapon == this.m_id && (!it.team || (it.ItemStatus & ITS_AVAILABLE)),
	{
		if (ITEM_IS_LOOT(it) && (autocvar_g_showweaponspawns < 2))
		{
			continue;
		}
		entity wp = WaypointSprite_Spawn(
			WP_Weapon,
			-2, 0,
			NULL, it.origin + ('0 0 1' * it.maxs.z) * 1.2,
			cl, 0,
			NULL, enemy,
			0,
			RADARICON_NONE
		);
		wp.wp_extra = this.m_id;
	});
}

bool client_hasweapon(entity this, Weapon wpn, .entity weaponentity, float andammo, bool complain)
{
	float f = 0;

	if (time < CS(this).hasweapon_complain_spam)
		complain = 0;

	// ignore hook button when using other offhand equipment
	if (this.offhand != OFFHAND_HOOK)
	if (wpn == WEP_HOOK && !((STAT(WEAPONS, this) | weaponsInMap) & WepSet_FromWeapon(wpn)))
	    complain = 0;

	if (complain)
		CS(this).hasweapon_complain_spam = time + 0.2;

	if (wpn == WEP_Null)
	{
		if (complain)
			sprint(this, "Invalid weapon\n");
		return false;
	}
	if (autocvar_g_weaponswitch_debug == 2 && weaponslot(weaponentity) > 0 && !(wpn.spawnflags & WEP_FLAG_DUALWIELD) && !(PS(this).dual_weapons & wpn.m_wepset))
		return false; // no complaints needed
	if (STAT(WEAPONS, this) & WepSet_FromWeapon(wpn))
	{
		if (andammo)
		{
			if(this.items & IT_UNLIMITED_AMMO)
			{
				f = 1;
			}
			else
			{
				f = wpn.wr_checkammo1(wpn, this, weaponentity) + wpn.wr_checkammo2(wpn, this, weaponentity);

				// always allow selecting the Mine Layer if we placed mines, so that we can detonate them
				if(wpn == WEP_MINE_LAYER)
					IL_EACH(g_mines, it.owner == this && it.weaponentity_fld == weaponentity,
					{
						f = 1;
						break; // no need to continue
					});
			}
			if (!f)
			{
				if (complain)
				if(IS_REAL_CLIENT(this))
				{
					play2(this, SND(UNAVAILABLE));
					Send_WeaponComplain (this, wpn.m_id, 0);
				}
				return false;
			}
		}
		return true;
	}
	if (complain)
	if(IS_REAL_CLIENT(this))
	{
		// DRESK - 3/16/07
		// Report Proper Weapon Status / Modified Weapon Ownership Message
		if (weaponsInMap & WepSet_FromWeapon(wpn))
		{
			Send_WeaponComplain(this, wpn.m_id, 1);
			if(autocvar_g_showweaponspawns < 3)
				Weapon_whereis(wpn, this);
			else
			{
				FOREACH(Weapons, it.impulse == wpn.impulse,
				{
					Weapon_whereis(it, this);
				});
			}
		}
		else
		{
			Send_WeaponComplain (this, wpn.m_id, 2);
		}

		play2(this, SND(UNAVAILABLE));
	}
	return false;
}

float W_GetCycleWeapon(entity this, string weaponorder, float dir, float imp, bool complain, bool skipmissing, .entity weaponentity)
{
	// We cannot tokenize in this function, as GiveItems calls this
	// function. Thus we must use car/cdr.
	float weaponwant, first_valid, prev_valid, switchtonext, switchtolast;
	switchtonext = switchtolast = 0;
	first_valid = prev_valid = 0;
	float weaponcur;
	entity wep;
	string rest;

	if(skipmissing || this.(weaponentity).selectweapon == 0)
		weaponcur = this.(weaponentity).m_switchweapon.m_id;
	else
		weaponcur = this.(weaponentity).selectweapon;

	if(dir == 0)
		switchtonext = 1;

	// complain-specific vars
	int c = 0;
	entity wepcomplain = NULL;
	int wepcomplainindex = 0;
	bool have_other = false;

	// see if we have or can locate (not hidden), some other weapon in the group
	WepSet customgroup = '0 0 0';
	if(imp < 0) // custom cl_weaponpriorityN group
	{
		// These groups are client-specific, and (imp == -1) here,
		// so generate a weapon set bitmask to represent the group.
		rest = weaponorder;
		while(rest != "")
		{
			weaponwant = stof(car(rest)); rest = cdr(rest);
			customgroup |= REGISTRY_GET(Weapons, weaponwant).m_wepset;
		}
	}
	else {} // standard weapon_group, defined by impulse sharing
	FOREACH(Weapons, (imp >= 0 && it.impulse == imp) || (imp < 0 && (it.m_wepset & customgroup)),
	{
		if ((it.m_wepset & STAT(WEAPONS, this))
		|| ((it.m_wepset & weaponsInMap) && !(it.spawnflags & WEP_FLAG_HIDDEN)))
		{
			have_other = true;
			break;
		}
	});

	rest = weaponorder;
	while(rest != "")
	{
		weaponwant = stof(car(rest)); rest = cdr(rest);
		wep = REGISTRY_GET(Weapons, weaponwant);
		if(imp >= 0)
		if(wep.impulse != imp)
			continue;

		// skip weapons we don't own that aren't normal and aren't in the map
		if(!(STAT(WEAPONS, this) & wep.m_wepset))
		{
			if(wep.spawnflags & WEP_FLAG_HIDDEN)
				continue;

			if(!(weaponsInMap & wep.m_wepset))
			if((wep.spawnflags & WEP_FLAG_MUTATORBLOCKED) || have_other)
				continue;
		}

		if(complain)
		{
			if(!wepcomplain || this.weaponcomplainindex == c)
			{
				wepcomplain = wep;
				wepcomplainindex = c;
			}
			++c;
		}

		if(!skipmissing || client_hasweapon(this, wep, weaponentity, true, false))
		{
			if(switchtonext)
				return weaponwant;
			if(!first_valid)
				first_valid = weaponwant;
			if(weaponwant == weaponcur)
			{
				if(dir >= 0)
					switchtonext = 1;
				else if(prev_valid)
					return prev_valid;
				else
					switchtolast = 1;
			}
			prev_valid = weaponwant;
		}
	}
	if(first_valid)
	{
		if(switchtolast)
			return prev_valid;
		else
			return first_valid;
	}

	// complain (but only for one weapon on the button that has been pressed)
	if(wepcomplain)
	{
		this.weaponcomplainindex = wepcomplainindex + 1;
		client_hasweapon(this, wepcomplain, weaponentity, true, true);
	}
	return 0;
}

void W_SwitchWeapon_Force(Player this, Weapon wep, .entity weaponentity)
{
	TC(Weapon, wep);
	entity w_ent = this.(weaponentity);
	w_ent.cnt = w_ent.m_switchweapon.m_id;
	w_ent.m_switchweapon = wep;
	w_ent.selectweapon = wep.m_id;
}

// perform weapon to attack (weaponstate and attack_finished check is here)
void W_SwitchToOtherWeapon(entity this, .entity weaponentity)
{
	// hack to ensure it switches to an OTHER weapon (in case the other fire mode still has ammo, we want that anyway)
	Weapon ww;
	WepSet set = WepSet_FromWeapon(this.(weaponentity).m_weapon);
	if (STAT(WEAPONS, this) & set)
	{
		STAT(WEAPONS, this) &= ~set;
		ww = w_getbestweapon(this, weaponentity);
		STAT(WEAPONS, this) |= set;
	}
	else
	{
		ww = w_getbestweapon(this, weaponentity);
	}
	if (ww == WEP_Null) return;
	W_SwitchWeapon_Force(this, ww, weaponentity);
}

bool W_SwitchWeapon(entity this, Weapon w, .entity weaponentity)
{
	if(this.(weaponentity).m_switchweapon != w)
	{
		if(client_hasweapon(this, w, weaponentity, true, true))
		{
			W_SwitchWeapon_Force(this, w, weaponentity);
			return true;
		}
		else
		{
			this.(weaponentity).selectweapon = w.m_id; // update selectweapon anyway
			return false;
		}
	}
	else if(!weaponLocked(this) && CS_CVAR(this).cvar_cl_weapon_switch_reload)
	{
		entity actor = this;
		w.wr_reload(w, actor, weaponentity);
	}

	return true; // player already has the weapon out or needs to reload
}

void W_SwitchWeapon_TryOthers(entity this, Weapon w, .entity weaponentity)
{
	if(!W_SwitchWeapon(this, w, weaponentity) && CS_CVAR(this).cvar_cl_weapon_switch_fallback_to_impulse)
		W_NextWeaponOnImpulse(this, w.impulse, weaponentity);
}

void W_CycleWeapon(entity this, string weaponorder, float dir, .entity weaponentity)
{
	float w;
	w = W_GetCycleWeapon(this, weaponorder, dir, -1, true, true, weaponentity);
	if(w > 0)
		W_SwitchWeapon(this, REGISTRY_GET(Weapons, w), weaponentity);
}

void W_NextWeaponOnImpulse(entity this, float imp, .entity weaponentity)
{
	float w;
	w = W_GetCycleWeapon(this, CS_CVAR(this).cvar_cl_weaponpriority, +1, imp, true, (CS_CVAR(this).cvar_cl_weaponimpulsemode == 0), weaponentity);
	if(w > 0)
		W_SwitchWeapon(this, REGISTRY_GET(Weapons, w), weaponentity);
}

// next weapon
void W_NextWeapon(entity this, int list, .entity weaponentity)
{
	if(list == 0)
		W_CycleWeapon(this, weaponorder_byid, -1, weaponentity);
	else if(list == 1)
		W_CycleWeapon(this, CS_CVAR(this).weaponorder_byimpulse, -1, weaponentity);
	else if(list == 2)
		W_CycleWeapon(this, CS_CVAR(this).cvar_cl_weaponpriority, -1, weaponentity);
}

// prev weapon
void W_PreviousWeapon(entity this, float list, .entity weaponentity)
{
	if(list == 0)
		W_CycleWeapon(this, weaponorder_byid, +1, weaponentity);
	else if(list == 1)
		W_CycleWeapon(this, CS_CVAR(this).weaponorder_byimpulse, +1, weaponentity);
	else if(list == 2)
		W_CycleWeapon(this, CS_CVAR(this).cvar_cl_weaponpriority, +1, weaponentity);
}

// previously used if exists and has ammo, (second) best otherwise
void W_LastWeapon(entity this, .entity weaponentity)
{
	Weapon wep = REGISTRY_GET(Weapons, this.(weaponentity).cnt);
	if (client_hasweapon(this, wep, weaponentity, true, false))
		W_SwitchWeapon(this, wep, weaponentity);
	else
		W_SwitchToOtherWeapon(this, weaponentity);
}

// fix switchweapon (needed when spectating is disabled, as PutClientInServer comes too early)
REPLICATE_APPLYCHANGE("cl_weaponpriority",
	for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	{
		.entity weaponentity = weaponentities[slot];
		if (this.(weaponentity) && (this.(weaponentity).m_weapon != WEP_Null || slot == 0))
			this.(weaponentity).m_switchweapon = w_getbestweapon(this, weaponentity);
	}
);
