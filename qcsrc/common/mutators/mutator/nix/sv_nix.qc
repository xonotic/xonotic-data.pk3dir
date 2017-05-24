#include "sv_nix.qh"

int autocvar_g_balance_nix_ammo_cells;
int autocvar_g_balance_nix_ammo_plasma;
int autocvar_g_balance_nix_ammo_fuel;
int autocvar_g_balance_nix_ammo_nails;
int autocvar_g_balance_nix_ammo_rockets;
int autocvar_g_balance_nix_ammo_shells;
int autocvar_g_balance_nix_ammoincr_cells;
int autocvar_g_balance_nix_ammoincr_plasma;
int autocvar_g_balance_nix_ammoincr_fuel;
int autocvar_g_balance_nix_ammoincr_nails;
int autocvar_g_balance_nix_ammoincr_rockets;
int autocvar_g_balance_nix_ammoincr_shells;
float autocvar_g_balance_nix_incrtime;
float autocvar_g_balance_nix_roundtime;
bool autocvar_g_nix_with_healtharmor;
bool autocvar_g_nix_with_blaster;
bool autocvar_g_nix_with_powerups;
int autocvar_g_pickup_cells_max;
int autocvar_g_pickup_plasma_max;
int autocvar_g_pickup_fuel_max;
int autocvar_g_pickup_nails_max;
int autocvar_g_pickup_rockets_max;
int autocvar_g_pickup_shells_max;

float g_nix_with_blaster;
// WEAPONTODO
int nix_weapon;
float nix_nextchange;
float nix_nextweapon;
.float nix_lastchange_id;
.float nix_lastinfotime;
.float nix_nextincr;

bool NIX_CanChooseWeapon(int wpn);

REGISTER_MUTATOR(nix, cvar("g_nix") && !cvar("g_instagib") && !cvar("g_overkill"))
{
	MUTATOR_ONADD
	{
		g_nix_with_blaster = autocvar_g_nix_with_blaster;

		nix_nextchange = 0;
		nix_nextweapon = 0;

		FOREACH(Weapons, it != WEP_Null && NIX_CanChooseWeapon(it.m_id), LAMBDA(it.wr_init(it)));
	}

	MUTATOR_ONROLLBACK_OR_REMOVE
	{
		// nothing to roll back
	}

	MUTATOR_ONREMOVE
	{
		// as the PlayerSpawn hook will no longer run, NIX is turned off by this!
		FOREACH_CLIENT(IS_PLAYER(it) && !IS_DEAD(it), {
			it.ammo_cells = start_ammo_cells;
			it.ammo_plasma = start_ammo_plasma;
			it.ammo_shells = start_ammo_shells;
			it.ammo_nails = start_ammo_nails;
			it.ammo_rockets = start_ammo_rockets;
			it.ammo_fuel = start_ammo_fuel;
			it.weapons = start_weapons;
			for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
			{
				.entity weaponentity = weaponentities[slot];
				if(it.(weaponentity).m_weapon == WEP_Null && slot != 0)
					continue;
				if(!client_hasweapon(it, it.(weaponentity).m_weapon, weaponentity, true, false))
					it.(weaponentity).m_switchweapon = w_getbestweapon(it, weaponentity);
			}
		});
	}

	return false;
}

bool NIX_CanChooseWeapon(int wpn)
{
	entity e = Weapons_from(wpn);
	if (e == WEP_Null) return false; // skip dummies
	if(g_weaponarena)
	{
		if(!(g_weaponarena_weapons & e.m_wepset))
			return false;
	}
	else
	{
		if(wpn == WEP_BLASTER.m_id && g_nix_with_blaster)
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
	RandomSelection_Init();
	FOREACH(Weapons, it != WEP_Null, LAMBDA(
		if(NIX_CanChooseWeapon(it.m_id))
			RandomSelection_AddFloat(it.m_id, 1, (it.m_id != nix_weapon));
	));
	nix_nextweapon = RandomSelection_chosen_float;
}

void NIX_GiveCurrentWeapon(entity this)
{
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
		// Weapon w = Weapons_from(nix_weapon);
		// w.wr_init(w); // forget it, too slow
	}

	// get weapon info
	entity e = Weapons_from(nix_weapon);

	if(nix_nextchange != this.nix_lastchange_id) // this shall only be called once per round!
	{
		this.ammo_shells = this.ammo_nails = this.ammo_rockets = this.ammo_cells = this.ammo_plasma = this.ammo_fuel = 0;

		if(this.items & IT_UNLIMITED_WEAPON_AMMO)
		{
			switch(e.ammo_field)
			{
				case ammo_shells:  this.ammo_shells  = autocvar_g_pickup_shells_max;  break;
				case ammo_nails:   this.ammo_nails   = autocvar_g_pickup_nails_max;   break;
				case ammo_rockets: this.ammo_rockets = autocvar_g_pickup_rockets_max; break;
				case ammo_cells:   this.ammo_cells   = autocvar_g_pickup_cells_max;   break;
				case ammo_plasma:  this.ammo_plasma  = autocvar_g_pickup_plasma_max;   break;
				case ammo_fuel:    this.ammo_fuel    = autocvar_g_pickup_fuel_max;    break;
			}
		}
		else
		{
			switch(e.ammo_field)
			{
				case ammo_shells:  this.ammo_shells  = autocvar_g_balance_nix_ammo_shells;  break;
				case ammo_nails:   this.ammo_nails   = autocvar_g_balance_nix_ammo_nails;   break;
				case ammo_rockets: this.ammo_rockets = autocvar_g_balance_nix_ammo_rockets; break;
				case ammo_cells:   this.ammo_cells   = autocvar_g_balance_nix_ammo_cells;   break;
				case ammo_plasma:  this.ammo_plasma  = autocvar_g_balance_nix_ammo_plasma;   break;
				case ammo_fuel:    this.ammo_fuel    = autocvar_g_balance_nix_ammo_fuel;    break;
			}
		}

		this.nix_nextincr = time + autocvar_g_balance_nix_incrtime;
		if(dt >= 1 && dt <= 5)
			this.nix_lastinfotime = -42;
		else
			Send_Notification(NOTIF_ONE_ONLY, this, MSG_CENTER, CENTER_NIX_NEWWEAPON, nix_weapon);

		e.wr_resetplayer(e, this);

		// all weapons must be fully loaded when we spawn
		if(e.spawnflags & WEP_FLAG_RELOADABLE) // prevent accessing undefined cvars
		{
			for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
			{
				.entity weaponentity = weaponentities[slot];
				this.(weaponentity).(weapon_load[nix_weapon]) = e.reloading_ammo;
			}
		}

		// vortex too
		if(WEP_CVAR(vortex, charge))
		{
			if(WEP_CVAR_SEC(vortex, chargepool))
				this.vortex_chargepool_ammo = 1;
			for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
			{
				.entity weaponentity = weaponentities[slot];
				this.(weaponentity).vortex_charge = WEP_CVAR(vortex, charge_start);
			}
		}

		// set last change info
		this.nix_lastchange_id = nix_nextchange;
	}
	if(this.nix_lastinfotime != dt)
	{
		this.nix_lastinfotime = dt; // initial value 0 should count as "not seen"
		if(dt >= 1 && dt <= 5)
			Send_Notification(NOTIF_ONE_ONLY, this, MSG_CENTER, CENTER_NIX_COUNTDOWN, nix_nextweapon, dt);
	}

	if(!(this.items & IT_UNLIMITED_WEAPON_AMMO) && time > this.nix_nextincr)
	{
		switch(e.ammo_field)
		{
			case ammo_shells:  this.ammo_shells  += autocvar_g_balance_nix_ammoincr_shells;  break;
			case ammo_nails:   this.ammo_nails   += autocvar_g_balance_nix_ammoincr_nails;   break;
			case ammo_rockets: this.ammo_rockets += autocvar_g_balance_nix_ammoincr_rockets; break;
			case ammo_cells:   this.ammo_cells   += autocvar_g_balance_nix_ammoincr_cells;   break;
			case ammo_plasma:  this.ammo_plasma  += autocvar_g_balance_nix_ammoincr_plasma;   break;
			case ammo_fuel:    this.ammo_fuel    += autocvar_g_balance_nix_ammoincr_fuel;    break;
		}

		this.nix_nextincr = time + autocvar_g_balance_nix_incrtime;
	}

	this.weapons = '0 0 0';
	if(g_nix_with_blaster)
		this.weapons |= WEPSET(BLASTER);
	this.weapons |= e.m_wepset;

    Weapon w = Weapons_from(nix_weapon);
    for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
    {
    	.entity weaponentity = weaponentities[slot];
    	if(this.(weaponentity).m_weapon == WEP_Null && slot != 0)
    		continue;

		if(this.(weaponentity).m_switchweapon != w)
		if(!client_hasweapon(this, this.(weaponentity).m_switchweapon, weaponentity, true, false))
		{
			if(client_hasweapon(this, w, weaponentity, true, false))
				W_SwitchWeapon(this, w, weaponentity);
		}
	}
}

MUTATOR_HOOKFUNCTION(nix, ForbidThrowCurrentWeapon)
{
	return true; // no throwing in NIX
}

MUTATOR_HOOKFUNCTION(nix, BuildMutatorsString)
{
	M_ARGV(0, string) = strcat(M_ARGV(0, string), ":NIX");
}

MUTATOR_HOOKFUNCTION(nix, BuildMutatorsPrettyString)
{
	M_ARGV(0, string) = strcat(M_ARGV(0, string), ", NIX");
}

MUTATOR_HOOKFUNCTION(nix, FilterItem)
{
	entity item = M_ARGV(0, entity);

	if(item.itemdef.instanceOfHealth || item.itemdef.instanceOfArmor)
	{
		return !autocvar_g_nix_with_healtharmor;
	}
	else if(item.itemdef.instanceOfPowerup)
	{
		return !autocvar_g_nix_with_powerups;
	}

	return true; // delete all other items
}

MUTATOR_HOOKFUNCTION(nix, OnEntityPreSpawn)
{
	entity ent = M_ARGV(0, entity);

	if(ent.classname == "target_items") // items triggers cannot work in nix (as they change weapons/ammo)
		return true;
}

MUTATOR_HOOKFUNCTION(nix, PlayerPreThink)
{
	entity player = M_ARGV(0, entity);

	if(!game_stopped)
	if(!IS_DEAD(player))
	if(IS_PLAYER(player))
		NIX_GiveCurrentWeapon(player);
}

MUTATOR_HOOKFUNCTION(nix, PlayerSpawn)
{
	entity player = M_ARGV(0, entity);

	player.nix_lastchange_id = -1;
	NIX_GiveCurrentWeapon(player); // overrides the weapons you got when spawning
	player.items |= IT_UNLIMITED_SUPERWEAPONS;
}

MUTATOR_HOOKFUNCTION(nix, SetModname, CBC_ORDER_LAST)
{
	M_ARGV(0, string) = "NIX";
}
