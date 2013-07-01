float forbidWeaponUse()
{
	if(time < game_starttime && !autocvar_sv_ready_restart_after_countdown)
		return 1;
	if(round_handler_IsActive() && !round_handler_IsRoundStarted())
		return 1;
	if(self.player_blocked)
		return 1;
	if(self.freezetag_frozen)
		return 1;
	return 0;
}

void W_WeaponFrame()
{
	vector fo, ri, up;

	if (frametime)
		self.weapon_frametime = frametime;

	if (!self.weaponentity || self.health < 1)
		return; // Dead player can't use weapons and injure impulse commands

	if(forbidWeaponUse())
	if(self.weaponentity.state != WS_CLEAR)
	{
		w_ready();
		return;
	}

	if(!self.switchweapon)
	{
		self.weapon = 0;
		self.switchingweapon = 0;
		self.weaponentity.state = WS_CLEAR;
		self.weaponname = "";
		self.items &~= IT_AMMO;
		return;
	}

	makevectors(self.v_angle);
	fo = v_forward; // save them in case the weapon think functions change it
	ri = v_right;
	up = v_up;

	// Change weapon
	if (self.weapon != self.switchweapon)
	{
		if (self.weaponentity.state == WS_CLEAR)
		{
			// end switching!
			self.switchingweapon = self.switchweapon;
			entity newwep = get_weaponinfo(self.switchweapon);

			self.items &~= IT_AMMO;
			self.items = self.items | (newwep.items & IT_AMMO);

			// the two weapon entities will notice this has changed and update their models
			self.weapon = self.switchweapon;
			self.weaponname = newwep.mdl;
			self.bulletcounter = 0; // WEAPONTODO
			WEP_ACTION(self.switchweapon, WR_SETUP);
			self.weaponentity.state = WS_RAISE;

			// set our clip load to the load of the weapon we switched to, if it's reloadable
			if(newwep.spawnflags & WEP_FLAG_RELOADABLE && cvar(strcat("g_balance_", newwep.netname, "_reload_ammo"))) // prevent accessing undefined cvars
			{
				self.clip_load = self.(weapon_load[self.switchweapon]);
				self.clip_size = cvar(strcat("g_balance_", newwep.netname, "_reload_ammo"));
			}
			else
				self.clip_load = self.clip_size = 0;

			// VorteX: add player model weapon select frame here
			// setcustomframe(PlayerWeaponRaise);
			weapon_thinkf(WFRAME_IDLE, newwep.switchdelay_raise, w_ready);
			//print(sprintf("W_WeaponFrame(): cvar: %s, value: %f\n", sprintf("g_balance_%s_switchdelay_raise", newwep.netname), cvar(sprintf("g_balance_%s_switchdelay_raise", newwep.netname))));
			weapon_boblayer1(PLAYER_WEAPONSELECTION_SPEED, '0 0 0');
		}
		else if (self.weaponentity.state == WS_DROP)
		{
			// in dropping phase we can switch at any time
			self.switchingweapon = self.switchweapon;
		}
		else if (self.weaponentity.state == WS_READY)
		{
			// start switching!
			self.switchingweapon = self.switchweapon;

			entity oldwep = get_weaponinfo(self.weapon);
			
#ifndef INDEPENDENT_ATTACK_FINISHED
			if(ATTACK_FINISHED(self) <= time + self.weapon_frametime * 0.5)
			{
#endif
			sound (self, CH_WEAPON_SINGLE, "weapons/weapon_switch.wav", VOL_BASE, ATTN_NORM);
			self.weaponentity.state = WS_DROP;
			// set up weapon switch think in the future, and start drop anim
			weapon_thinkf(WFRAME_DONTCHANGE, oldwep.switchdelay_drop, w_clear);
			//print(sprintf("W_WeaponFrame(): cvar: %s, value: %f\n", sprintf("g_balance_%s_switchdelay_drop", oldwep.netname), cvar(sprintf("g_balance_%s_switchdelay_drop", oldwep.netname))));
			weapon_boblayer1(PLAYER_WEAPONSELECTION_SPEED, PLAYER_WEAPONSELECTION_RANGE);
#ifndef INDEPENDENT_ATTACK_FINISHED
			}
#endif
		}
	}

	// LordHavoc: network timing test code
	//if (self.button0)
	//	print(ftos(frametime), " ", ftos(time), " >= ", ftos(ATTACK_FINISHED(self)), " >= ", ftos(self.weapon_nextthink), "\n");

	float w;
	w = self.weapon;

	// call the think code which may fire the weapon
	// and do so multiple times to resolve framerate dependency issues if the
	// server framerate is very low and the weapon fire rate very high
	float c;
	c = 0;
	while (c < W_TICSPERFRAME)
	{
		c = c + 1;
		if(w && !WEPSET_CONTAINS_EW(self, w))
		{
			if(self.weapon == self.switchweapon)
				W_SwitchWeapon_Force(self, w_getbestweapon(self));
			w = 0;
		}

		v_forward = fo;
		v_right = ri;
		v_up = up;

		if(w)
			WEP_ACTION(self.weapon, WR_THINK);
		else
			WEP_ACTION(self.weapon, WR_GONETHINK);

		if (time + self.weapon_frametime * 0.5 >= self.weapon_nextthink)
		{
			if(self.weapon_think)
			{
				v_forward = fo;
				v_right = ri;
				v_up = up;
				self.weapon_think();
			}
			else
				bprint("\{1}^1ERROR: undefined weapon think function for ", self.netname, "\n");
		}
	}

#if 0
	if (self.items & IT_CELLS)
		self.currentammo = self.ammo_cells;
	else if (self.items & IT_ROCKETS)
		self.currentammo = self.ammo_rockets;
	else if (self.items & IT_NAILS)
		self.currentammo = self.ammo_nails;
	else if (self.items & IT_SHELLS)
		self.currentammo = self.ammo_shells;
	else
		self.currentammo = 1;
#endif
}

string W_Apply_Weaponreplace(string in)
{
	float n = tokenize_console(in);
	string out = "";
	float i;
	for(i = 0; i < n; ++i)
	{
		string s = argv(i);
		string r = cvar_string(strcat("g_weaponreplace_", s));
		if(r == "")
			out = strcat(out, " ", s);
		else if(r != "0")
			out = strcat(out, " ", r);
	}
	return substring(out, 1, -1);
}

void weapon_defaultspawnfunc(float wpn)
{
	entity e;
	float t;
	var .float ammofield;
	string s;
	entity oldself;
	float i, j;
	float f;

	if(self.classname != "droppedweapon" && self.classname != "replacedweapon")
	{
		e = get_weaponinfo(wpn);

		if(e.spawnflags & WEP_FLAG_MUTATORBLOCKED)
		{
			objerror("Attempted to spawn a mutator-blocked weapon rejected");
			startitem_failed = TRUE;
			return;
		}

		s = W_Apply_Weaponreplace(e.netname);
		ret_string = s;
		other = e;
		MUTATOR_CALLHOOK(SetWeaponreplace);
		s = ret_string;
		if(s == "")
		{
			remove(self);
			startitem_failed = TRUE;
			return;
		}
		t = tokenize_console(s);
		if(t >= 2)
		{
			self.team = --internalteam;
			oldself = self;
			for(i = 1; i < t; ++i)
			{
				s = argv(i);
				for(j = WEP_FIRST; j <= WEP_LAST; ++j)
				{
					e = get_weaponinfo(j);
					if(e.netname == s)
					{
						self = spawn();
						copyentity(oldself, self);
						self.classname = "replacedweapon";
						weapon_defaultspawnfunc(j);
						break;
					}
				}
				if(j > WEP_LAST)
				{
					print("The weapon replace list for ", oldself.classname, " contains an unknown weapon ", s, ". Skipped.\n");
				}
			}
			self = oldself;
		}
		if(t >= 1) // always the case!
		{
			s = argv(0);
			wpn = 0;
			for(j = WEP_FIRST; j <= WEP_LAST; ++j)
			{
				e = get_weaponinfo(j);
				if(e.netname == s)
				{
					wpn = j;
					break;
				}
			}
			if(j > WEP_LAST)
			{
				print("The weapon replace list for ", self.classname, " contains an unknown weapon ", s, ". Skipped.\n");
			}
		}
		if(wpn == 0)
		{
			remove(self);
			startitem_failed = TRUE;
			return;
		}
	}

	e = get_weaponinfo(wpn);

	if(!self.respawntime)
	{
		if(WEPSET_CONTAINS_ANY_EA(e, WEPBIT_SUPERWEAPONS))
		{
			self.respawntime = g_pickup_respawntime_superweapon;
			self.respawntimejitter = g_pickup_respawntimejitter_superweapon;
		}
		else
		{
			self.respawntime = g_pickup_respawntime_weapon;
			self.respawntimejitter = g_pickup_respawntimejitter_weapon;
		}
	}

	if(WEPSET_CONTAINS_ANY_EA(e, WEPBIT_SUPERWEAPONS))
		if(!self.superweapons_finished)
			self.superweapons_finished = autocvar_g_balance_superweapons_time;

	if(e.items)
	{
		for(i = 0, j = 1; i < 24; ++i, j *= 2)
		{
			if(e.items & j)
			{
				ammofield = Item_CounterField(j);
				if(!self.ammofield)
					self.ammofield = cvar(strcat("g_pickup_", Item_CounterFieldName(j), "_weapon"));
			}
		}
	}

	// pickup anyway
	if(g_pickup_weapons_anyway)
		self.pickup_anyway = TRUE;

	f = FL_WEAPON;

	// no weapon-stay on superweapons
	if(WEPSET_CONTAINS_ANY_EA(e, WEPBIT_SUPERWEAPONS))
		f |= FL_NO_WEAPON_STAY;

	// weapon stay isn't supported for teamed weapons
	if(self.team)
		f |= FL_NO_WEAPON_STAY;

	StartItem(e.model, "weapons/weaponpickup.wav", self.respawntime, self.respawntimejitter, e.message, 0, e.weapon, f, weapon_pickupevalfunc, e.bot_pickupbasevalue);
	if (self.modelindex) // don't precache if self was removed
		WEP_ACTION(e.weapon, WR_INIT);
}
