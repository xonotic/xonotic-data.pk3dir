#include "throwing.qh"

#include "weaponsystem.qh"
#include "../mutators/all.qh"
#include "../t_items.qh"
#include "../g_damage.qh"
#include "../../common/items/item.qh"
#include "../../common/mapinfo.qh"
#include "../../common/notifications.qh"
#include "../../common/triggers/subs.qh"
#include "../../common/util.qh"
#include "../../common/weapons/all.qh"

void thrown_wep_think()
{SELFPARAM();
	self.nextthink = time;
	if(self.oldorigin != self.origin)
	{
		self.SendFlags |= ISF_LOCATION;
		self.oldorigin = self.origin;
	}
	self.owner = world;
	float timeleft = self.savenextthink - time;
	if(timeleft > 1)
		SUB_SetFade(self, self.savenextthink - 1, 1);
	else if(timeleft > 0)
		SUB_SetFade(self, time, timeleft);
	else
		SUB_VanishOrRemove(self);
}

// returns amount of ammo used as string, or -1 for failure, or 0 for no ammo count
string W_ThrowNewWeapon(entity own, float wpn, float doreduce, vector org, vector velo)
{SELFPARAM();
	float thisammo, i;
	string s;
	Weapon info = Weapons_from(wpn);
	var .int ammotype = info.ammo_field;

	entity wep = new(droppedweapon);

	setorigin(wep, org);
	wep.velocity = velo;
	wep.owner = wep.enemy = own;
	wep.flags |= FL_TOSSED;
	wep.colormap = own.colormap;

	W_DropEvent(wr_drop,own,wpn,wep);

	if(WepSet_FromWeapon(Weapons_from(wpn)) & WEPSET_SUPERWEAPONS)
	{
		if(own.items & IT_UNLIMITED_SUPERWEAPONS)
		{
			wep.superweapons_finished = time + autocvar_g_balance_superweapons_time;
		}
		else
		{
			float superweapons = 1;
			for(i = WEP_FIRST; i <= WEP_LAST; ++i)
			{
				WepSet set = WepSet_FromWeapon(Weapons_from(i));
				if ((set & WEPSET_SUPERWEAPONS) && (own.weapons & set)) ++superweapons;
			}
			if(superweapons <= 1)
			{
				wep.superweapons_finished = own.superweapons_finished;
				own.superweapons_finished = 0;
			}
			else
			{
				float timeleft = own.superweapons_finished - time;
				float weptimeleft = timeleft / superweapons;
				wep.superweapons_finished = time + weptimeleft;
				own.superweapons_finished -= weptimeleft;
			}
		}
	}

	weapon_defaultspawnfunc(wep, info);
	if(startitem_failed)
		return string_null;
	wep.glowmod = own.weaponentity_glowmod;
	wep.think = thrown_wep_think;
	wep.savenextthink = wep.nextthink;
	wep.nextthink = min(wep.nextthink, time + 0.5);
	wep.pickup_anyway = true; // these are ALWAYS pickable

	//wa = W_AmmoItemCode(wpn);
	if(ammotype == ammo_none)
	{
		return "";
	}
	else
	{
		s = "";

		if(doreduce && g_weapon_stay == 2)
		{
			// if our weapon is loaded, give its load back to the player
			int i = PS(self).m_weapon.m_id;
			if(self.(weapon_load[i]) > 0)
			{
				own.(ammotype) += self.(weapon_load[i]);
				self.(weapon_load[i]) = -1; // schedule the weapon for reloading
			}

			wep.(ammotype) = 0;
		}
		else if(doreduce)
		{
			// if our weapon is loaded, give its load back to the player
			int i = PS(self).m_weapon.m_id;
			if(self.(weapon_load[i]) > 0)
			{
				own.(ammotype) += self.(weapon_load[i]);
				self.(weapon_load[i]) = -1; // schedule the weapon for reloading
			}

			thisammo = min(own.(ammotype), wep.(ammotype));
			wep.(ammotype) = thisammo;
			own.(ammotype) -= thisammo;

			switch(ammotype)
			{
				case ammo_shells:  s = sprintf("%s and %d shells", s, thisammo);  break;
				case ammo_nails:   s = sprintf("%s and %d nails", s, thisammo);   break;
				case ammo_rockets: s = sprintf("%s and %d rockets", s, thisammo); break;
				case ammo_cells:   s = sprintf("%s and %d cells", s, thisammo);   break;
				case ammo_plasma:  s = sprintf("%s and %d plasma", s, thisammo);  break;
				case ammo_fuel:    s = sprintf("%s and %d fuel", s, thisammo);    break;
			}

			s = substring(s, 5, -1);
		}
		return s;
	}
}

bool W_IsWeaponThrowable(bool w)
{
	if (MUTATOR_CALLHOOK(ForbidDropCurrentWeapon))
		return false;
	if (!autocvar_g_pickup_items)
		return false;
	if (g_weaponarena)
		return 0;
	if (g_cts)
		return 0;
    if(w == WEP_Null.m_id)
        return false;

	#if 0
	if(start_weapons & WepSet_FromWeapon(Weapons_from(w)))
	{
		// start weapons that take no ammo can't be dropped (this prevents dropping the laser, as long as it continues to use no ammo)
		if(start_items & IT_UNLIMITED_WEAPON_AMMO)
			return false;
		if((Weapons_from(w)).ammo_field == ammo_none)
			return false;
	}
	return true;
	#else
	return (Weapons_from(w)).weaponthrowable;
	#endif
}

// toss current weapon
void W_ThrowWeapon(vector velo, vector delta, float doreduce)
{SELFPARAM();
	Weapon w = PS(self).m_weapon;
	if (w == WEP_Null)
		return; // just in case
	if(MUTATOR_CALLHOOK(ForbidThrowCurrentWeapon))
		return;
	if(!autocvar_g_weapon_throwable)
		return;
	.entity weaponentity = weaponentities[0]; // TODO: unhardcode
	if(self.(weaponentity).state != WS_READY)
		return;
	if(!W_IsWeaponThrowable(w.m_id))
		return;

	WepSet set = WepSet_FromWeapon(w);
	if(!(self.weapons & set)) return;
	self.weapons &= ~set;

	W_SwitchWeapon_Force(self, w_getbestweapon(self));
	string a = W_ThrowNewWeapon(self, w.m_id, doreduce, self.origin + delta, velo);

	if(!a) return;
	Send_Notification(NOTIF_ONE, self, MSG_MULTI, ITEM_WEAPON_DROP, a, w.m_id);
}

void SpawnThrownWeapon(vector org, float w)
{SELFPARAM();
	if(self.weapons & WepSet_FromWeapon(PS(self).m_weapon))
		if(W_IsWeaponThrowable(PS(self).m_weapon.m_id))
			W_ThrowNewWeapon(self, PS(self).m_weapon.m_id, false, org, randomvec() * 125 + '0 0 200');
}
