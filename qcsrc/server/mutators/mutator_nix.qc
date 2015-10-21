
#include "mutator.qh"

float g_nix_with_blaster;
// WEAPONTODO
int nix_weapon;
float nix_nextchange;
float nix_nextweapon;
.float nix_lastchange_id;
.float nix_lastinfotime;
.float nix_nextincr;

float NIX_CanChooseWeapon(float wpn)
{
	entity e;
	e = get_weaponinfo(wpn);
	if(!e.weapon) // skip dummies
		return false;
	if(g_weaponarena)
	{
		if(!(g_weaponarena_weapons & WepSet_FromWeapon(wpn)))
			return false;
	}
	else
	{
		if(wpn == WEP_BLASTER.m_id && g_nix_with_blaster) // WEAPONTODO: rename to g_nix_with_blaster
			return false;
		if(e.spawnflags & WEP_FLAG_MUTATORBLOCKED)
			return false;
		if (!(e.spawnflags & WEP_FLAG_NORMAL))
			return false;
	}
	return true;
}
void NIX_ChooseNextWeapon()
{
	float j;
	RandomSelection_Init();
	for(j = WEP_FIRST; j <= WEP_LAST; ++j)
		if(NIX_CanChooseWeapon(j))
			RandomSelection_Add(world, j, string_null, 1, (j != nix_weapon));
	nix_nextweapon = RandomSelection_chosen_float;
}

void NIX_GiveCurrentWeapon()
{SELFPARAM();
	float dt;

	if(!nix_nextweapon)
		NIX_ChooseNextWeapon();

	dt = ceil(nix_nextchange - time);

	if(dt <= 0)
	{
		nix_weapon = nix_nextweapon;
		nix_nextweapon = 0;
		if (!nix_nextchange) // no round played yet?
			nix_nextchange = time; // start the first round now!
		else
			nix_nextchange = time + autocvar_g_balance_nix_roundtime;
		// Weapon w = get_weaponinfo(nix_weapon);
		// w.wr_init(w); // forget it, too slow
	}

	// get weapon info
	entity e = get_weaponinfo(nix_weapon);

	if(nix_nextchange != self.nix_lastchange_id) // this shall only be called once per round!
	{
		self.ammo_shells = self.ammo_nails = self.ammo_rockets = self.ammo_cells = self.ammo_plasma = self.ammo_fuel = 0;

		if(self.items & IT_UNLIMITED_WEAPON_AMMO)
		{
			switch(e.ammo_field)
			{
				case ammo_shells:  self.ammo_shells  = autocvar_g_pickup_shells_max;  break;
				case ammo_nails:   self.ammo_nails   = autocvar_g_pickup_nails_max;   break;
				case ammo_rockets: self.ammo_rockets = autocvar_g_pickup_rockets_max; break;
				case ammo_cells:   self.ammo_cells   = autocvar_g_pickup_cells_max;   break;
				case ammo_plasma:  self.ammo_plasma  = autocvar_g_pickup_plasma_max;   break;
				case ammo_fuel:    self.ammo_fuel    = autocvar_g_pickup_fuel_max;    break;
			}
		}
		else
		{
			switch(e.ammo_field)
			{
				case ammo_shells:  self.ammo_shells  = autocvar_g_balance_nix_ammo_shells;  break;
				case ammo_nails:   self.ammo_nails   = autocvar_g_balance_nix_ammo_nails;   break;
				case ammo_rockets: self.ammo_rockets = autocvar_g_balance_nix_ammo_rockets; break;
				case ammo_cells:   self.ammo_cells   = autocvar_g_balance_nix_ammo_cells;   break;
				case ammo_plasma:  self.ammo_plasma  = autocvar_g_balance_nix_ammo_plasma;   break;
				case ammo_fuel:    self.ammo_fuel    = autocvar_g_balance_nix_ammo_fuel;    break;
			}
		}

		self.nix_nextincr = time + autocvar_g_balance_nix_incrtime;
		if(dt >= 1 && dt <= 5)
			self.nix_lastinfotime = -42;
		else
			Send_Notification(NOTIF_ONE_ONLY, self, MSG_CENTER, CENTER_NIX_NEWWEAPON, nix_weapon);

		Weapon w = get_weaponinfo(nix_weapon);
		w.wr_resetplayer(w);

		// all weapons must be fully loaded when we spawn
		if(e.spawnflags & WEP_FLAG_RELOADABLE) // prevent accessing undefined cvars
			self.(weapon_load[nix_weapon]) = e.reloading_ammo;

		// vortex too
		if(WEP_CVAR(vortex, charge))
		{
			if(WEP_CVAR_SEC(vortex, chargepool))
				self.vortex_chargepool_ammo = 1;
			self.vortex_charge = WEP_CVAR(vortex, charge_start);
		}

		// set last change info
		self.nix_lastchange_id = nix_nextchange;
	}
	if(self.nix_lastinfotime != dt)
	{
		self.nix_lastinfotime = dt; // initial value 0 should count as "not seen"
		if(dt >= 1 && dt <= 5)
			Send_Notification(NOTIF_ONE_ONLY, self, MSG_CENTER, CENTER_NIX_COUNTDOWN, nix_nextweapon, dt);
	}

	if(!(self.items & IT_UNLIMITED_WEAPON_AMMO) && time > self.nix_nextincr)
	{
		switch(e.ammo_field)
		{
			case ammo_shells:  self.ammo_shells  += autocvar_g_balance_nix_ammoincr_shells;  break;
			case ammo_nails:   self.ammo_nails   += autocvar_g_balance_nix_ammoincr_nails;   break;
			case ammo_rockets: self.ammo_rockets += autocvar_g_balance_nix_ammoincr_rockets; break;
			case ammo_cells:   self.ammo_cells   += autocvar_g_balance_nix_ammoincr_cells;   break;
			case ammo_plasma:  self.ammo_plasma  += autocvar_g_balance_nix_ammoincr_plasma;   break;
			case ammo_fuel:    self.ammo_fuel    += autocvar_g_balance_nix_ammoincr_fuel;    break;
		}

		self.nix_nextincr = time + autocvar_g_balance_nix_incrtime;
	}

	self.weapons = '0 0 0';
	if(g_nix_with_blaster)
		self.weapons |= WEPSET(BLASTER);
	self.weapons |= WepSet_FromWeapon(nix_weapon);

	if(self.switchweapon != nix_weapon)
		if(!client_hasweapon(self, self.switchweapon, true, false))
			if(client_hasweapon(self, nix_weapon, true, false))
				W_SwitchWeapon(nix_weapon);
}

void NIX_precache()
{
	float i;
	for (i = WEP_FIRST; i <= WEP_LAST; ++i)
		if (NIX_CanChooseWeapon(i)) {
			Weapon w = get_weaponinfo(i);
			w.wr_init(w);
		}
}

MUTATOR_HOOKFUNCTION(nix_ForbidThrowCurrentWeapon)
{
	return 1; // no throwing in NIX
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
{SELFPARAM();
	switch (self.items)
	{
		case ITEM_HealthSmall.m_itemid:
		case ITEM_HealthMedium.m_itemid:
		case ITEM_HealthLarge.m_itemid:
		case ITEM_HealthMega.m_itemid:
		case ITEM_ArmorSmall.m_itemid:
		case ITEM_ArmorMedium.m_itemid:
		case ITEM_ArmorLarge.m_itemid:
		case ITEM_ArmorMega.m_itemid:
			if (autocvar_g_nix_with_healtharmor)
				return 0;
			break;
		case ITEM_Strength.m_itemid:
		case ITEM_Shield.m_itemid:
			if (autocvar_g_nix_with_powerups)
				return 0;
			break;
	}

	return 1; // delete all other items
}

MUTATOR_HOOKFUNCTION(nix_OnEntityPreSpawn)
{SELFPARAM();
	if(self.classname == "target_items") // items triggers cannot work in nix (as they change weapons/ammo)
		return 1;
	return 0;
}

MUTATOR_HOOKFUNCTION(nix_PlayerPreThink)
{SELFPARAM();
	if(!intermission_running)
	if(self.deadflag == DEAD_NO)
	if(IS_PLAYER(self))
		NIX_GiveCurrentWeapon();
	return 0;
}

MUTATOR_HOOKFUNCTION(nix_PlayerSpawn)
{SELFPARAM();
	self.nix_lastchange_id = -1;
	NIX_GiveCurrentWeapon(); // overrides the weapons you got when spawning
	self.items |= IT_UNLIMITED_SUPERWEAPONS;
	return 0;
}

MUTATOR_HOOKFUNCTION(nix_SetModname)
{
	modname = "NIX";
	return 0;
}

MUTATOR_DEFINITION(mutator_nix)
{SELFPARAM();
	entity e;

	MUTATOR_HOOK(ForbidThrowCurrentWeapon, nix_ForbidThrowCurrentWeapon, CBC_ORDER_ANY);
	MUTATOR_HOOK(BuildMutatorsString, nix_BuildMutatorsString, CBC_ORDER_ANY);
	MUTATOR_HOOK(BuildMutatorsPrettyString, nix_BuildMutatorsPrettyString, CBC_ORDER_ANY);
	MUTATOR_HOOK(FilterItem, nix_FilterItem, CBC_ORDER_ANY);
	MUTATOR_HOOK(OnEntityPreSpawn, nix_OnEntityPreSpawn, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerPreThink, nix_PlayerPreThink, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerSpawn, nix_PlayerSpawn, CBC_ORDER_ANY);
	MUTATOR_HOOK(SetModname, nix_SetModname, CBC_ORDER_LAST);

	MUTATOR_ONADD
	{
		g_nix_with_blaster = autocvar_g_nix_with_blaster;

		nix_nextchange = 0;
		nix_nextweapon = 0;

		NIX_precache();
	}

	MUTATOR_ONROLLBACK_OR_REMOVE
	{
		// nothing to roll back
	}

	MUTATOR_ONREMOVE
	{
		// as the PlayerSpawn hook will no longer run, NIX is turned off by this!

		FOR_EACH_PLAYER(e) if(e.deadflag == DEAD_NO)
		{
			e.ammo_cells = start_ammo_cells;
			e.ammo_plasma = start_ammo_plasma;
			e.ammo_shells = start_ammo_shells;
			e.ammo_nails = start_ammo_nails;
			e.ammo_rockets = start_ammo_rockets;
			e.ammo_fuel = start_ammo_fuel;
			e.weapons = start_weapons;
			if(!client_hasweapon(e, e.weapon, true, false))
				e.switchweapon = w_getbestweapon(self);
		}
	}

	return 0;
}
