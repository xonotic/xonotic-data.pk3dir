void thrown_wep_think()
{
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
{
	entity oldself, wep;
	float wa, thisammo, i, j;
	string s;
	var .float ammofield;

	wep = spawn();

	setorigin(wep, org);
	wep.classname = "droppedweapon";
	wep.velocity = velo;
	wep.owner = wep.enemy = own;
	wep.flags |= FL_TOSSED;
	wep.colormap = own.colormap;

	if(WepSet_FromWeapon(wpn) & WEPSET_SUPERWEAPONS)
	{
		if(own.items & IT_UNLIMITED_SUPERWEAPONS)
		{
			wep.superweapons_finished = time + autocvar_g_balance_superweapons_time;
		}
		else
		{
			float superweapons = 1;
			for(i = WEP_FIRST; i <= WEP_LAST; ++i)
				if(WepSet_FromWeapon(i) & WEPSET_SUPERWEAPONS)
					if(own.weapons & WepSet_FromWeapon(i))
						++superweapons;
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

	wa = W_AmmoItemCode(wpn);
	if(wa == 0)
	{
		oldself = self;
		self = wep;
		weapon_defaultspawnfunc(wpn);
		self = oldself;
		if(startitem_failed)
			return string_null;
		wep.glowmod = own.weaponentity_glowmod;
		wep.think = thrown_wep_think;
		wep.savenextthink = wep.nextthink;
		wep.nextthink = min(wep.nextthink, time + 0.5);
		wep.pickup_anyway = TRUE; // these are ALWAYS pickable
		return "";
	}
	else
	{
		s = "";
		oldself = self;
		self = wep;
		weapon_defaultspawnfunc(wpn);
		self = oldself;
		if(startitem_failed)
			return string_null;
		if(doreduce && g_weapon_stay == 2)
		{
			for(i = 0, j = 1; i < 24; ++i, j *= 2)
			{
				if(wa & j)
				{
					ammofield = Item_CounterField(j);

					// if our weapon is loaded, give its load back to the player
					if(self.(weapon_load[self.weapon]) > 0)
					{
						own.ammofield += self.(weapon_load[self.weapon]);
						self.(weapon_load[self.weapon]) = -1; // schedule the weapon for reloading
					}

					wep.ammofield = 0;
				}
			}
		}
		else if(doreduce)
		{
			for(i = 0, j = 1; i < 24; ++i, j *= 2)
			{
				if(wa & j)
				{
					ammofield = Item_CounterField(j);

					// if our weapon is loaded, give its load back to the player
					if(self.(weapon_load[self.weapon]) > 0)
					{
						own.ammofield += self.(weapon_load[self.weapon]);
						self.(weapon_load[self.weapon]) = -1; // schedule the weapon for reloading
					}

					thisammo = min(own.ammofield, wep.ammofield);
					wep.ammofield = thisammo;
					own.ammofield -= thisammo;
					s = strcat(s, " and ", ftos(thisammo), " ", Item_CounterFieldName(j));
				}
			}
			s = substring(s, 5, -1);
		}
		wep.glowmod = own.weaponentity_glowmod;
		wep.think = thrown_wep_think;
		wep.savenextthink = wep.nextthink;
		wep.nextthink = min(wep.nextthink, time + 0.5);
		wep.pickup_anyway = TRUE; // these are ALWAYS pickable

		return s;
	}
}

float W_IsWeaponThrowable(float w)
{
	float wa;

	if (!autocvar_g_pickup_items)
		return 0;
	if (g_weaponarena)
		return 0;
	if (g_cts)
		return 0;
	if (g_nexball && w == WEP_GRENADE_LAUNCHER)
		return 0;
    if(w == 0)
        return 0;
	
	wa = W_AmmoItemCode(w);
	if(start_weapons & WepSet_FromWeapon(w))
	{
		// start weapons that take no ammo can't be dropped (this prevents dropping the laser, as long as it continues to use no ammo)
		if(start_items & IT_UNLIMITED_WEAPON_AMMO)
			return 0;
		if(wa == 0)
			return 0;
	}

	return 1;
}

// toss current weapon
void W_ThrowWeapon(vector velo, vector delta, float doreduce)
{
	float w;
	string a;

	w = self.weapon;
	if (w == 0)
		return; // just in case
	if(MUTATOR_CALLHOOK(ForbidThrowCurrentWeapon))
		return;
	if(!autocvar_g_weapon_throwable)
		return;
	if(self.weaponentity.state != WS_READY)
		return;
	if(!W_IsWeaponThrowable(w))
		return;

	if(!(self.weapons & WepSet_FromWeapon(w)))
		return;
	self.weapons &= ~WepSet_FromWeapon(w);

	W_SwitchWeapon_Force(self, w_getbestweapon(self));
	a = W_ThrowNewWeapon(self, w, doreduce, self.origin + delta, velo);
	
	if not(a) return;
	Send_Notification(NOTIF_ONE, self, MSG_MULTI, ITEM_WEAPON_DROP, a, w);
}
