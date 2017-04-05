#include "throwing.qh"

#include "weaponsystem.qh"
#include "../mutators/_mod.qh"
#include <common/t_items.qh>
#include "../g_damage.qh"
#include <common/items/item.qh>
#include <common/mapinfo.qh>
#include <common/notifications/all.qh>
#include <common/triggers/subs.qh>
#include <common/util.qh>
#include <common/weapons/_all.qh>
#include <common/state.qh>
#include <common/wepent.qh>

void thrown_wep_think(entity this)
{
	this.nextthink = time;
	if(this.oldorigin != this.origin)
	{
		this.SendFlags |= ISF_LOCATION;
		this.oldorigin = this.origin;
	}
	this.owner = NULL;
	float timeleft = this.savenextthink - time;
	if(timeleft > 1)
		SUB_SetFade(this, this.savenextthink - 1, 1);
	else if(timeleft > 0)
		SUB_SetFade(this, time, timeleft);
	else
		SUB_VanishOrRemove(this);
}

// returns amount of ammo used as string, or -1 for failure, or 0 for no ammo count
string W_ThrowNewWeapon(entity own, float wpn, float doreduce, vector org, vector velo, .entity weaponentity)
{
	float thisammo;
	string s;
	Weapon info = Weapons_from(wpn);
	var .int ammotype = info.ammo_field;

	entity wep = new(droppedweapon);

	setorigin(wep, org);
	wep.velocity = velo;
	wep.owner = wep.enemy = own;
	wep.flags |= FL_TOSSED;
	wep.colormap = own.colormap;
	wep.glowmod = weaponentity_glowmod(info, own, own.clientcolors, own.(weaponentity));
	navigation_dynamicgoal_init(wep, false);

	W_DropEvent(wr_drop,own,wpn,wep,weaponentity);

	if(WepSet_FromWeapon(Weapons_from(wpn)) & WEPSET_SUPERWEAPONS)
	{
		if(own.items & IT_UNLIMITED_SUPERWEAPONS)
		{
			wep.superweapons_finished = time + autocvar_g_balance_superweapons_time;
		}
		else
		{
			int superweapons = 1;
			FOREACH(Weapons, it != WEP_Null, LAMBDA(
				WepSet set = it.m_wepset;
				if((set & WEPSET_SUPERWEAPONS) && (own.weapons & set)) ++superweapons;
			));
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
	setthink(wep, thrown_wep_think);
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
			int i = own.(weaponentity).m_weapon.m_id;
			if(own.(weaponentity).(weapon_load[i]) > 0)
			{
				own.(ammotype) += own.(weaponentity).(weapon_load[i]);
				own.(weaponentity).(weapon_load[i]) = -1; // schedule the weapon for reloading
			}

			wep.(ammotype) = 0;
		}
		else if(doreduce)
		{
			// if our weapon is loaded, give its load back to the player
			int i = own.(weaponentity).m_weapon.m_id;
			if(own.(weaponentity).(weapon_load[i]) > 0)
			{
				own.(ammotype) += own.(weaponentity).(weapon_load[i]);
				own.(weaponentity).(weapon_load[i]) = -1; // schedule the weapon for reloading
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

bool W_IsWeaponThrowable(entity this, int w)
{
	if (MUTATOR_CALLHOOK(ForbidDropCurrentWeapon, this, w))
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
void W_ThrowWeapon(entity this, .entity weaponentity, vector velo, vector delta, float doreduce)
{
	Weapon w = this.(weaponentity).m_weapon;
	if (w == WEP_Null)
		return; // just in case
	if(MUTATOR_CALLHOOK(ForbidThrowCurrentWeapon, this, this.(weaponentity)))
		return;
	if(!autocvar_g_weapon_throwable)
		return;
	if(this.(weaponentity).state != WS_READY)
		return;
	if(!W_IsWeaponThrowable(this, w.m_id))
		return;

	WepSet set = WepSet_FromWeapon(w);
	if(!(this.weapons & set)) return;
	this.weapons &= ~set;

	W_SwitchWeapon_Force(this, w_getbestweapon(this, weaponentity), weaponentity);
	string a = W_ThrowNewWeapon(this, w.m_id, doreduce, this.origin + delta, velo, weaponentity);

	if(!a) return;
	Send_Notification(NOTIF_ONE, this, MSG_MULTI, ITEM_WEAPON_DROP, a, w.m_id);
}

void SpawnThrownWeapon(entity this, vector org, Weapon wep, .entity weaponentity)
{
	//entity wep = this.(weaponentity).m_weapon;

	if(this.weapons & WepSet_FromWeapon(wep))
		if(W_IsWeaponThrowable(this, wep.m_id))
			W_ThrowNewWeapon(this, wep.m_id, false, org, randomvec() * 125 + '0 0 200', weaponentity);
}
