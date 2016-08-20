#include "selection.qh"

#include "weaponsystem.qh"
#include <common/t_items.qh>
#include <common/constants.qh>
#include <common/util.qh>
#include <common/items/item.qh>
#include <common/weapons/_all.qh>
#include <common/state.qh>
#include <common/mutators/mutator/waypoints/waypointsprites.qh>

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
	FOREACH_ENTITY_FLOAT(weapon, this.m_id,
	{
		if (it.classname == "droppedweapon" && autocvar_g_showweaponspawns < 2)
			continue;
		if (!(it.flags & FL_ITEM))
			continue;
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

bool client_hasweapon(entity this, Weapon wpn, float andammo, bool complain)
{
	float f = 0;

	if (time < this.hasweapon_complain_spam)
		complain = 0;

	// ignore hook button when using other offhand equipment
	if (this.offhand != OFFHAND_HOOK)
	if (wpn == WEP_HOOK && !((this.weapons | weaponsInMap) & WepSet_FromWeapon(wpn)))
	    complain = 0;

	if (complain)
		this.hasweapon_complain_spam = time + 0.2;

	if (wpn == WEP_Null)
	{
		if (complain)
			sprint(this, "Invalid weapon\n");
		return false;
	}
	if (this.weapons & WepSet_FromWeapon(wpn))
	{
		if (andammo)
		{
			if(this.items & IT_UNLIMITED_WEAPON_AMMO)
			{
				f = 1;
			}
			else
			{
				f = wpn.wr_checkammo1(wpn, this) + wpn.wr_checkammo2(wpn, this);

				// always allow selecting the Mine Layer if we placed mines, so that we can detonate them
				if(wpn == WEP_MINE_LAYER)
					IL_EACH(g_mines, it.owner == this,
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

float W_GetCycleWeapon(entity this, string weaponorder, float dir, float imp, float complain, float skipmissing)
{
	// We cannot tokenize in this function, as GiveItems calls this
	// function. Thus we must use car/cdr.
	float weaponwant, first_valid, prev_valid, switchtonext, switchtolast;
	WepSet wepset = '0 0 0';
	switchtonext = switchtolast = 0;
	first_valid = prev_valid = 0;
	float weaponcur;
	entity wep;

	if(skipmissing || this.selectweapon == 0)
		weaponcur = PS(this).m_switchweapon.m_id;
	else
		weaponcur = this.selectweapon;

	if(dir == 0)
		switchtonext = 1;

	int c = 0;

	string rest = weaponorder;
	while(rest != "")
	{
		weaponwant = stof(car(rest)); rest = cdr(rest);
		wep = Weapons_from(weaponwant);
		wepset = wep.m_wepset;
		if(imp >= 0)
		if(wep.impulse != imp)
			continue;

		bool have_other = false;
		FOREACH(Weapons, it != WEP_Null, {
			if(i != weaponwant)
			if(it.impulse == imp || imp < 0)
			if((this.weapons & (it.m_wepset)) || (weaponsInMap & (it.m_wepset)))
				have_other = true;
		});

		// skip weapons we don't own that aren't normal and aren't in the map
		if(!(this.weapons & wepset))
		if(!(weaponsInMap & wepset))
		if((wep.spawnflags & WEP_FLAG_MUTATORBLOCKED) || have_other)
			continue;

		++c;

		if(!skipmissing || client_hasweapon(this, wep, true, false))
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
	if(complain)
	{
		this.weaponcomplainindex += 1;
		c = (this.weaponcomplainindex % c) + 1;
		rest = weaponorder;
		while(rest != "")
		{
			weaponwant = stof(car(rest)); rest = cdr(rest);
			wep = Weapons_from(weaponwant);
			wepset = wep.m_wepset;
			if(imp >= 0)
				if(wep.impulse != imp)
					continue;

			bool have_other = false;
			FOREACH(Weapons, it != WEP_Null, {
				if(i != weaponwant)
				if(it.impulse == imp || imp < 0)
				if((this.weapons & (it.m_wepset)) || (weaponsInMap & (it.m_wepset)))
					have_other = true;
			});

			// skip weapons we don't own that aren't normal and aren't in the map
			if(!(this.weapons & wepset))
			if(!(weaponsInMap & wepset))
			if((wep.spawnflags & WEP_FLAG_MUTATORBLOCKED) || have_other)
				continue;

			--c;
			if(c == 0)
			{
				client_hasweapon(this, wep, true, true);
				break;
			}
		}
	}
	return 0;
}

void W_SwitchWeapon_Force(Player this, Weapon wep)
{
    TC(Player, this); TC(Weapon, wep);
	this.cnt = PS(this).m_switchweapon.m_id;
	PS(this).m_switchweapon = wep;
	this.selectweapon = wep.m_id;
}

// perform weapon to attack (weaponstate and attack_finished check is here)
void W_SwitchToOtherWeapon(entity this)
{
	// hack to ensure it switches to an OTHER weapon (in case the other fire mode still has ammo, we want that anyway)
	Weapon ww;
	WepSet set = WepSet_FromWeapon(PS(this).m_weapon);
	if (this.weapons & set)
	{
		this.weapons &= ~set;
		ww = w_getbestweapon(this);
		this.weapons |= set;
	}
	else
	{
		ww = w_getbestweapon(this);
	}
	if (ww == WEP_Null) return;
	W_SwitchWeapon_Force(this, ww);
}

void W_SwitchWeapon(entity this, Weapon w)
{
	if (PS(this).m_switchweapon != w)
	{
		if (client_hasweapon(this, w, true, true))
			W_SwitchWeapon_Force(this, w);
		else
			this.selectweapon = w.m_id; // update selectweapon ANYWAY
	}
	else if(!forbidWeaponUse(this)) {
		entity actor = this;
		for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
		{
			.entity weaponentity = weaponentities[slot];
			w.wr_reload(w, actor, weaponentity);
		}
	}
}

void W_CycleWeapon(entity this, string weaponorder, float dir)
{
	float w;
	w = W_GetCycleWeapon(this, weaponorder, dir, -1, 1, true);
	if(w > 0)
		W_SwitchWeapon(this, Weapons_from(w));
}

void W_NextWeaponOnImpulse(entity this, float imp)
{
	float w;
	w = W_GetCycleWeapon(this, this.cvar_cl_weaponpriority, +1, imp, 1, (this.cvar_cl_weaponimpulsemode == 0));
	if(w > 0)
		W_SwitchWeapon(this, Weapons_from(w));
}

// next weapon
void W_NextWeapon(entity this, int list)
{
	if(list == 0)
		W_CycleWeapon(this, weaponorder_byid, -1);
	else if(list == 1)
		W_CycleWeapon(this, this.weaponorder_byimpulse, -1);
	else if(list == 2)
		W_CycleWeapon(this, this.cvar_cl_weaponpriority, -1);
}

// prev weapon
void W_PreviousWeapon(entity this, float list)
{
	if(list == 0)
		W_CycleWeapon(this, weaponorder_byid, +1);
	else if(list == 1)
		W_CycleWeapon(this, this.weaponorder_byimpulse, +1);
	else if(list == 2)
		W_CycleWeapon(this, this.cvar_cl_weaponpriority, +1);
}

// previously used if exists and has ammo, (second) best otherwise
void W_LastWeapon(entity this)
{
	Weapon wep = Weapons_from(this.cnt);
	if (client_hasweapon(this, wep, true, false))
		W_SwitchWeapon(this, wep);
	else
		W_SwitchToOtherWeapon(this);
}
