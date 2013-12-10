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
		if(e.weapons & WEPSET_SUPERWEAPONS)
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

	if(e.weapons & WEPSET_SUPERWEAPONS)
		if(!self.superweapons_finished)
			self.superweapons_finished = autocvar_g_balance_superweapons_time;

	// if we don't already have ammo, give us some ammo
	if(!self.(e.current_ammo))
	{
		switch(e.current_ammo)
		{
			case ammo_shells:  self.ammo_shells  = cvar("g_pickup_shells_weapon");  break;
			case ammo_nails:   self.ammo_nails   = cvar("g_pickup_nails_weapon");   break;
			case ammo_rockets: self.ammo_rockets = cvar("g_pickup_rockets_weapon"); break;
			case ammo_cells:   self.ammo_cells   = cvar("g_pickup_cells_weapon");   break;
			case ammo_fuel:    self.ammo_fuel    = cvar("g_pickup_fuel_weapon");    break;
		}
	}

	print(sprintf("defaultspawnfunc: current ammo count: %f\n", self.(e.current_ammo)));

	#if 0
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
	#endif

	// pickup anyway
	if(g_pickup_weapons_anyway)
		self.pickup_anyway = TRUE;

	f = FL_WEAPON;

	// no weapon-stay on superweapons
	if(e.weapons & WEPSET_SUPERWEAPONS)
		f |= FL_NO_WEAPON_STAY;

	// weapon stay isn't supported for teamed weapons
	if(self.team)
		f |= FL_NO_WEAPON_STAY;

	StartItem(e.model, "weapons/weaponpickup.wav", self.respawntime, self.respawntimejitter, e.message, 0, e.weapon, f, weapon_pickupevalfunc, e.bot_pickupbasevalue);
	if (self.modelindex) // don't precache if self was removed
		WEP_ACTION(e.weapon, WR_INIT);
}
