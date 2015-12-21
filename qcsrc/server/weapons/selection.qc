#include "selection.qh"

#include "weaponsystem.qh"
#include "../t_items.qh"
#include "../../common/constants.qh"
#include "../../common/util.qh"
#include "../../common/items/item.qh"
#include "../../common/weapons/all.qh"
#include "../../common/mutators/mutator/waypoints/waypointsprites.qh"

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
	for (entity it = NULL; (it = findfloat(it, weapon, this.m_id)); )
	{
		if (it.classname == "droppedweapon" && autocvar_g_showweaponspawns < 2)
			continue;
		if (!(it.flags & FL_ITEM))
			continue;
		entity wp = WaypointSprite_Spawn(
			WP_Weapon,
			1, 0,
			NULL, it.origin + ('0 0 1' * it.maxs.z) * 1.2,
			cl, 0,
			NULL, enemy,
			0,
			RADARICON_NONE
		);
		wp.wp_extra = this.m_id;
	}
}

bool client_hasweapon(entity cl, Weapon wpn, float andammo, bool complain)
{
	float f = 0;

	if (time < cl.hasweapon_complain_spam)
		complain = 0;

	// ignore hook button when using other offhand equipment
	if (cl.offhand != OFFHAND_HOOK)
	if (wpn == WEP_HOOK && !((cl.weapons | weaponsInMap) & WepSet_FromWeapon(wpn)))
	    complain = 0;

	if (complain)
		cl.hasweapon_complain_spam = time + 0.2;

	if (wpn == WEP_Null)
	{
		if (complain)
			sprint(cl, "Invalid weapon\n");
		return false;
	}
	if (cl.weapons & WepSet_FromWeapon(wpn))
	{
		if (andammo)
		{
			if(cl.items & IT_UNLIMITED_WEAPON_AMMO)
			{
				f = 1;
			}
			else
			{
				WITH(entity, self, cl, f = wpn.wr_checkammo1(wpn) + wpn.wr_checkammo2(wpn));

				// always allow selecting the Mine Layer if we placed mines, so that we can detonate them
				entity mine;
				if(wpn == WEP_MINE_LAYER)
				for(mine = world; (mine = find(mine, classname, "mine")); ) if(mine.owner == cl)
					f = 1;

			}
			if (!f)
			{
				if (complain)
				if(IS_REAL_CLIENT(cl))
				{
					play2(cl, SND(UNAVAILABLE));
					Send_WeaponComplain (cl, wpn.m_id, 0);
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
			Send_WeaponComplain(cl, wpn.m_id, 1);
			Weapon_whereis(wpn, cl);
		}
		else
		{
			Send_WeaponComplain (cl, wpn.m_id, 2);
		}

		play2(cl, SND(UNAVAILABLE));
	}
	return false;
}

float W_GetCycleWeapon(entity pl, string weaponorder, float dir, float imp, float complain, float skipmissing)
{SELFPARAM();
	// We cannot tokenize in this function, as GiveItems calls this
	// function. Thus we must use car/cdr.
	float weaponwant, first_valid, prev_valid, switchtonext, switchtolast;
	WepSet wepset = '0 0 0';
	switchtonext = switchtolast = 0;
	first_valid = prev_valid = 0;
	float weaponcur;
	entity wep;

	if(skipmissing || pl.selectweapon == 0)
		weaponcur = PS(pl).m_switchweapon.m_id;
	else
		weaponcur = pl.selectweapon;

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
			if((pl.weapons & (it.m_wepset)) || (weaponsInMap & (it.m_wepset)))
				have_other = true;
		});

		// skip weapons we don't own that aren't normal and aren't in the map
		if(!(pl.weapons & wepset))
		if(!(weaponsInMap & wepset))
		if((wep.spawnflags & WEP_FLAG_MUTATORBLOCKED) || have_other)
			continue;

		++c;

		if(!skipmissing || client_hasweapon(pl, wep, true, false))
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
		self.weaponcomplainindex += 1;
		c = (self.weaponcomplainindex % c) + 1;
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
				if((pl.weapons & (it.m_wepset)) || (weaponsInMap & (it.m_wepset)))
					have_other = true;
			});

			// skip weapons we don't own that aren't normal and aren't in the map
			if(!(pl.weapons & wepset))
			if(!(weaponsInMap & wepset))
			if((wep.spawnflags & WEP_FLAG_MUTATORBLOCKED) || have_other)
				continue;

			--c;
			if(c == 0)
			{
				client_hasweapon(pl, wep, true, true);
				break;
			}
		}
	}
	return 0;
}

void W_SwitchWeapon_Force(entity e, Weapon wep)
{
	e.cnt = PS(e).m_switchweapon.m_id;
	PS(e).m_switchweapon = wep;
	e.selectweapon = wep.m_id;
}

// perform weapon to attack (weaponstate and attack_finished check is here)
void W_SwitchToOtherWeapon(entity pl)
{
	// hack to ensure it switches to an OTHER weapon (in case the other fire mode still has ammo, we want that anyway)
	Weapon ww;
	WepSet set = WepSet_FromWeapon(PS(pl).m_weapon);
	if (pl.weapons & set)
	{
		pl.weapons &= ~set;
		ww = w_getbestweapon(pl);
		pl.weapons |= set;
	}
	else
	{
		ww = w_getbestweapon(pl);
	}
	if (ww == WEP_Null) return;
	W_SwitchWeapon_Force(pl, ww);
}

void W_SwitchWeapon(Weapon w)
{SELFPARAM();
	if (PS(self).m_switchweapon != w)
	{
		if (client_hasweapon(self, w, true, true))
			W_SwitchWeapon_Force(self, w);
		else
			self.selectweapon = w.m_id; // update selectweapon ANYWAY
	}
	else if(!forbidWeaponUse(self)) {
		w.wr_reload(w);
	}
}

void W_CycleWeapon(string weaponorder, float dir)
{SELFPARAM();
	float w;
	w = W_GetCycleWeapon(self, weaponorder, dir, -1, 1, true);
	if(w > 0)
		W_SwitchWeapon(Weapons_from(w));
}

void W_NextWeaponOnImpulse(float imp)
{SELFPARAM();
	float w;
	w = W_GetCycleWeapon(self, self.cvar_cl_weaponpriority, +1, imp, 1, (self.cvar_cl_weaponimpulsemode == 0));
	if(w > 0)
		W_SwitchWeapon(Weapons_from(w));
}

// next weapon
void W_NextWeapon(float list)
{SELFPARAM();
	if(list == 0)
		W_CycleWeapon(weaponorder_byid, -1);
	else if(list == 1)
		W_CycleWeapon(self.weaponorder_byimpulse, -1);
	else if(list == 2)
		W_CycleWeapon(self.cvar_cl_weaponpriority, -1);
}

// prev weapon
void W_PreviousWeapon(float list)
{SELFPARAM();
	if(list == 0)
		W_CycleWeapon(weaponorder_byid, +1);
	else if(list == 1)
		W_CycleWeapon(self.weaponorder_byimpulse, +1);
	else if(list == 2)
		W_CycleWeapon(self.cvar_cl_weaponpriority, +1);
}

// previously used if exists and has ammo, (second) best otherwise
void W_LastWeapon(entity this)
{
	Weapon wep = Weapons_from(this.cnt);
	if (client_hasweapon(this, wep, true, false))
		W_SwitchWeapon(wep);
	else
		W_SwitchToOtherWeapon(this);
}
