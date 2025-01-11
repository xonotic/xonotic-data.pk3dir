#include "throwing.qh"

#include <common/items/item.qh>
#include <common/mapinfo.qh>
#include <common/mapobjects/subs.qh>
#include <common/mutators/mutator/status_effects/_mod.qh>
#include <common/notifications/all.qh>
#include <common/resources/sv_resources.qh>
#include <common/state.qh>
#include <common/util.qh>
#include <common/weapons/_all.qh>
#include <common/wepent.qh>
#include <server/damage.qh>
#include <server/items/items.qh>
#include <server/items/spawning.qh>
#include <server/mutators/_mod.qh>
#include <server/weapons/selection.qh>
#include <server/weapons/weaponsystem.qh>
#include <server/world.qh>

// returns amount of ammo used, or -1 for failure, or 0 for no ammo count
float W_ThrowNewWeapon(entity own, float wpn, float doreduce, vector org, vector velo, .entity weaponentity)
{
	Weapon info = REGISTRY_GET(Weapons, wpn);
	Resource ammotype = info.ammo_type;

	entity wep = spawn();
	ITEM_SET_LOOT(wep, true);
	setorigin(wep, org);
	wep.velocity = velo;
	wep.owner = wep.enemy = own;
	wep.flags |= FL_TOSSED;
	wep.colormap = own.colormap;
	// wep.glowmod will be set in weapon_defaultspawnfunc
	navigation_dynamicgoal_init(wep, false);

	W_DropEvent(wr_drop,own,wpn,wep,weaponentity);

	if(WepSet_FromWeapon(REGISTRY_GET(Weapons, wpn)) & WEPSET_SUPERWEAPONS)
	{
		ITEM_SET_EXPIRING(wep, true);
		if(own.items & IT_UNLIMITED_SUPERWEAPONS)
		{
			wep.superweapons_finished = time + autocvar_g_balance_superweapons_time;
		}
		else
		{
			int superweapons = 1;
			FOREACH(Weapons, it != WEP_Null, {
				WepSet set = it.m_wepset;
				if((WEPSET_SUPERWEAPONS & STAT(WEAPONS, own)) & set) ++superweapons;
			});
			if(superweapons <= 1)
			{
				wep.superweapons_finished = StatusEffects_gettime(STATUSEFFECT_Superweapon, own);
				StatusEffects_remove(STATUSEFFECT_Superweapon, own, STATUSEFFECT_REMOVE_CLEAR);
			}
			else
			{
				float timeleft = StatusEffects_gettime(STATUSEFFECT_Superweapon, own) - time;
				float weptimeleft = timeleft / superweapons;
				wep.superweapons_finished = time + weptimeleft;
				if(own.statuseffects)
				{
					// TODO: this doesn't explicitly enable the effect, use apply here?
					own.statuseffects.statuseffect_time[STATUSEFFECT_Superweapon.m_id] -= weptimeleft;
					StatusEffects_update(own);
				}
			}
		}
	}

	weapon_defaultspawnfunc(wep, info);
	if(startitem_failed)
		return -1;

	wep.pickup_anyway = true; // these are ALWAYS pickable

	//wa = W_AmmoItemCode(wpn);
	if(ammotype == RES_NONE)
	{
		return 0;
	}
	else
	{
		if(doreduce && g_weapon_stay == 2)
		{
			// if our weapon is loaded, give its load back to the player
			int i = own.(weaponentity).m_weapon.m_id;
			if(own.(weaponentity).(weapon_load[i]) > 0)
			{
				GiveResource(own, ammotype, own.(weaponentity).(weapon_load[i]));
				own.(weaponentity).(weapon_load[i]) = -1; // schedule the weapon for reloading
			}
			SetResource(wep, ammotype, 0);
		}
		else if(doreduce)
		{
			// if our weapon is loaded, give its load back to the player
			int i = own.(weaponentity).m_weapon.m_id;
			if(own.(weaponentity).(weapon_load[i]) > 0)
			{
				GiveResource(own, ammotype, own.(weaponentity).(weapon_load[i]));
				own.(weaponentity).(weapon_load[i]) = -1; // schedule the weapon for reloading
			}

			float ownderammo = GetResource(own, ammotype);
			float thisammo = min(ownderammo, GetResource(wep, ammotype));
			SetResource(wep, ammotype, thisammo);
			SetResource(own, ammotype, ownderammo - thisammo);

			return thisammo;
		}
		return 0;
	}
}

bool W_IsWeaponThrowable(entity this, int w)
{
	if (MUTATOR_CALLHOOK(ForbidDropCurrentWeapon, this, w))
		return false;
	if (!autocvar_g_pickup_items)
		return false;
	if (g_weaponarena)
		return false;
	if (w == WEP_Null.m_id)
		return false;

	return (REGISTRY_GET(Weapons, w)).weaponthrowable;
}

// toss current weapon
void W_ThrowWeapon(entity this, .entity weaponentity, vector velo, vector delta, float doreduce)
{
	Weapon w = this.(weaponentity).m_weapon;
	if (w == WEP_Null)
		return; // just in case
	if (time < game_starttime)
		return;
	if(MUTATOR_CALLHOOK(ForbidThrowCurrentWeapon, this, this.(weaponentity)))
		return;
	if(!autocvar_g_weapon_throwable)
		return;
	if(this.(weaponentity).state != WS_READY)
		return;
	if(!W_IsWeaponThrowable(this, w.m_id))
		return;

	WepSet set = WepSet_FromWeapon(w);
	if(!(STAT(WEAPONS, this) & set)) return;
	STAT(WEAPONS, this) &= ~set;

	W_SwitchWeapon_Force(this, w_getbestweapon(this, weaponentity), weaponentity);
	float a = W_ThrowNewWeapon(this, w.m_id, doreduce, this.origin + delta, velo, weaponentity);

	if(a < 0) return;
	Send_Notification(NOTIF_ONE, this, MSG_MULTI, ITEM_WEAPON_DROP, w.m_id, a);
}

void SpawnThrownWeapon(entity this, vector org, Weapon wep, .entity weaponentity)
{
	//entity wep = this.(weaponentity).m_weapon;

	if(STAT(WEAPONS, this) & WepSet_FromWeapon(wep))
		if(W_IsWeaponThrowable(this, wep.m_id))
			W_ThrowNewWeapon(this, wep.m_id, false, org, randomvec() * 125 + '0 0 200', weaponentity);
}
