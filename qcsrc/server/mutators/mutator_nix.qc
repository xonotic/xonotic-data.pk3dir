float g_nix, g_nix_with_laser;

float nix_weapon;
float nix_weapon_ammo;
float nix_nextchange;
float nix_nextweapon;
float nix_nextweapon_ammo;
.float nix_lastchange_id;
.float nix_lastinfotime;
.float nix_nextincr;

float NIX_CanChooseWeapon(float wpn)
{
	entity e;
	e = get_weaponinfo(wpn);
	if(!e.weapons) // skip dummies
		return FALSE;
	if(g_weaponarena)
	{
		if not(g_weaponarena & e.weapons)
			return FALSE;
	}
	else
	{
		if(wpn == WEP_LASER && g_nix_with_laser)
			return FALSE;
		if not(e.spawnflags & WEP_FLAG_NORMAL)
			return FALSE;
	}
	return TRUE;
}
void NIX_ChooseNextWeapon()
{
	float j;
	RandomSelection_Init();
	for(j = WEP_FIRST; j <= WEP_LAST; ++j)
		if(NIX_CanChooseWeapon(j))
			RandomSelection_Add(world, j, string_null, 1, (j != nix_weapon));
	nix_nextweapon = RandomSelection_chosen_float;
	nix_nextweapon_ammo = W_AmmoItemCode(nix_nextweapon);
}

void NIX_GiveCurrentWeapon()
{
	float dt;

	if(!nix_nextweapon)
		NIX_ChooseNextWeapon();

	dt = ceil(nix_nextchange - time);

	if(dt <= 0)
	{
		nix_weapon = nix_nextweapon;
		nix_weapon_ammo = nix_nextweapon_ammo;
		nix_nextweapon = 0;
		nix_nextchange = time + cvar("g_balance_nix_roundtime");
		//weapon_action(nix_weapon, WR_PRECACHE); // forget it, too slow
	}
	
	if(nix_nextchange != self.nix_lastchange_id) // this shall only be called once per round!
	{
		self.nix_lastchange_id = nix_nextchange;
		if (self.items & IT_UNLIMITED_WEAPON_AMMO)
		{
			self.ammo_shells = (nix_weapon_ammo & IT_SHELLS) ?
				cvar("g_pickup_shells_max") : 0;
			self.ammo_nails = (nix_weapon_ammo & IT_NAILS) ?
				cvar("g_pickup_nails_max") : 0;
			self.ammo_rockets = (nix_weapon_ammo & IT_ROCKETS) ?
				cvar("g_pickup_rockets_max") : 0;
			self.ammo_cells = (nix_weapon_ammo & IT_CELLS) ?
				cvar("g_pickup_cells_max") : 0;
			self.ammo_fuel = (nix_weapon_ammo & IT_FUEL) ?
				cvar("g_pickup_fuel_max") : 0;
		}
		else
		{
			self.ammo_shells = (nix_weapon_ammo & IT_SHELLS) ?
				cvar("g_balance_nix_ammo_shells") : 0;
			self.ammo_nails = (nix_weapon_ammo & IT_NAILS) ?
				cvar("g_balance_nix_ammo_nails") : 0;
			self.ammo_rockets = (nix_weapon_ammo & IT_ROCKETS) ?
				cvar("g_balance_nix_ammo_rockets") : 0;
			self.ammo_cells = (nix_weapon_ammo & IT_CELLS) ?
				cvar("g_balance_nix_ammo_cells") : 0;
			self.ammo_fuel = (nix_weapon_ammo & IT_FUEL) ?
				cvar("g_balance_nix_ammo_fuel") : 0;
		}
		self.nix_nextincr = time + cvar("g_balance_nix_incrtime");
		if(dt >= 1 && dt <= 5)
			self.nix_lastinfotime = -42;
		else
			centerprint(self, strcat("\n\n^2Active weapon: ^3", W_Name(nix_weapon)));
	}
	if(self.nix_lastinfotime != dt)
	{
		self.nix_lastinfotime = dt; // initial value 0 should count as "not seen"
		if(dt >= 1 && dt <= 5)
			centerprint(self, strcat("^3", ftos(dt), "^2 seconds until weapon change...\n\nNext weapon: ^3", W_Name(nix_nextweapon), "\n"));
	}

	if(!(self.items & IT_UNLIMITED_WEAPON_AMMO) && time > self.nix_nextincr)
	{
		if (nix_weapon_ammo & IT_SHELLS)
			self.ammo_shells = self.ammo_shells + cvar("g_balance_nix_ammoincr_shells");
		else if (nix_weapon_ammo & IT_NAILS)
			self.ammo_nails = self.ammo_nails + cvar("g_balance_nix_ammoincr_nails");
		else if (nix_weapon_ammo & IT_ROCKETS)
			self.ammo_rockets = self.ammo_rockets + cvar("g_balance_nix_ammoincr_rockets");
		else if (nix_weapon_ammo & IT_CELLS)
			self.ammo_cells = self.ammo_cells + cvar("g_balance_nix_ammoincr_cells");
		if (nix_weapon_ammo & IT_FUEL) // hook uses cells and fuel
			self.ammo_fuel = self.ammo_fuel + cvar("g_balance_nix_ammoincr_fuel");
		self.nix_nextincr = time + cvar("g_balance_nix_incrtime");
	}

	self.weapons = 0;
	if(g_nix_with_laser)
		self.weapons = self.weapons | WEPBIT_LASER;
	self.weapons = self.weapons | W_WeaponBit(nix_weapon);

	if(self.switchweapon != nix_weapon)
		if(!client_hasweapon(self, self.switchweapon, TRUE, FALSE))
			if(client_hasweapon(self, nix_weapon, TRUE, FALSE))
				W_SwitchWeapon(nix_weapon);
}

MUTATOR_HOOKFUNCTION(nix_ForbidThrowCurrentWeapon)
{
	return 1; // no throwing in NIX
}

MUTATOR_HOOKFUNCTION(nix_SetStartItems)
{
	float i;
	start_weapons = 0; // will be done later, when player spawns
	warmup_start_weapons = 0; // will be done later, when player spawns
	for (i = WEP_FIRST; i <= WEP_LAST; ++i)
		if (NIX_CanChooseWeapon(i))
			weapon_action(i, WR_PRECACHE);
	return 0;
}

MUTATOR_HOOKFUNCTION(nix_BuildMutatorsString)
{
	ret_string = strcat(ret_string, ":NIX");
	return 0;
}

MUTATOR_HOOKFUNCTION(nix_BuildMutatorsPrettyString)
{
	ret_string = strcat(ret_string, ", NIX");
	return 0;
}

MUTATOR_HOOKFUNCTION(nix_FilterItem)
{
	switch (self.items)
	{
		case IT_HEALTH:
		case IT_5HP:
		case IT_25HP:
		case IT_ARMOR:
		case IT_ARMOR_SHARD:
			if (cvar("g_nix_with_healtharmor"))
				return 0;
			break;
		case IT_STRENGTH:
		case IT_INVINCIBLE:
			if (cvar("g_nix_with_powerups"))
				return 0;
			break;
	}

	return 1; // delete all other items
}

MUTATOR_HOOKFUNCTION(nix_OnEntityPreSpawn)
{
	if(self.classname == "target_items") // items triggers cannot work in nixnex (as they change weapons/ammo)
		return 1;
	return 0;
}

MUTATOR_HOOKFUNCTION(nix_PlayerPreThink)
{
	if(!intermission_running)
	if(self.deadflag == DEAD_NO)
	if(self.classname == "player")
		NIX_GiveCurrentWeapon();
	return 0;
}

MUTATOR_HOOKFUNCTION(nix_PlayerSpawn)
{
	self.nix_lastchange_id = -1;
	return 0;
}

MUTATOR_DEFINITION(mutator_nix)
{
	MUTATOR_HOOK(ForbidThrowCurrentWeapon, nix_ForbidThrowCurrentWeapon, CBC_ORDER_ANY);
	MUTATOR_HOOK(SetStartItems, nix_SetStartItems, CBC_ORDER_EXCLUSIVE);
	MUTATOR_HOOK(BuildMutatorsString, nix_BuildMutatorsString, CBC_ORDER_ANY);
	MUTATOR_HOOK(BuildMutatorsPrettyString, nix_BuildMutatorsPrettyString, CBC_ORDER_ANY);
	MUTATOR_HOOK(FilterItem, nix_FilterItem, CBC_ORDER_ANY);
	MUTATOR_HOOK(OnEntityPreSpawn, nix_OnEntityPreSpawn, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerPreThink, nix_PlayerPreThink, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerSpawn, nix_PlayerSpawn, CBC_ORDER_ANY);

	MUTATOR_ONADD
	{
		g_nix = 1;
		g_nix_with_laser = cvar("g_nix_with_laser");

		nix_nextchange = time;
	}

	MUTATOR_ONREMOVE
	{
		error("NIX currently cannot be shut down.");
		g_nix = 0;
	}

	return 0;
}
