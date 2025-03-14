#include "sv_nix.qh"

#include <server/weapons/selection.qh>
#include <server/world.qh>

//string autocvar_g_nix;
int autocvar_g_balance_nix_ammo_cells;
int autocvar_g_balance_nix_ammo_fuel;
int autocvar_g_balance_nix_ammo_nails;
int autocvar_g_balance_nix_ammo_rockets;
int autocvar_g_balance_nix_ammo_shells;
int autocvar_g_balance_nix_ammoincr_cells;
int autocvar_g_balance_nix_ammoincr_fuel;
int autocvar_g_balance_nix_ammoincr_nails;
int autocvar_g_balance_nix_ammoincr_rockets;
int autocvar_g_balance_nix_ammoincr_shells;
float autocvar_g_balance_nix_incrtime;
float autocvar_g_balance_nix_roundtime;
bool autocvar_g_nix_with_healtharmor;
bool autocvar_g_nix_with_blaster;
bool autocvar_g_nix_with_powerups;

float g_nix_with_blaster;
// WEAPONTODO
int nix_weapon;
float nix_nextchange;
float nix_nextweapon;
.float nix_lastchange_id;
.float nix_lastinfotime;
.float nix_nextincr;

bool NIX_CanChooseWeapon(int wpn);

REGISTER_MUTATOR(nix, expr_evaluate(cvar_string("g_nix")) && !MUTATOR_IS_ENABLED(mutator_instagib) && !MUTATOR_IS_ENABLED(ok) && !MapInfo_LoadedGametype.m_weaponarena)
{
	MUTATOR_ONADD
	{
		g_nix_with_blaster = autocvar_g_nix_with_blaster;

		nix_nextchange = 0;
		nix_nextweapon = 0;

		FOREACH(Weapons, it != WEP_Null && NIX_CanChooseWeapon(it.m_id), { it.wr_init(it); });
	}

	MUTATOR_ONROLLBACK_OR_REMOVE
	{
		// nothing to roll back
	}

	MUTATOR_ONREMOVE
	{
		// as the PlayerSpawn hook will no longer run, NIX is turned off by this!
		FOREACH_CLIENT(IS_PLAYER(it) && !IS_DEAD(it), {
			SetResource(it, RES_SHELLS, start_ammo_shells);
			SetResource(it, RES_BULLETS, start_ammo_nails);
			SetResource(it, RES_ROCKETS, start_ammo_rockets);
			SetResource(it, RES_CELLS, start_ammo_cells);
			SetResource(it, RES_FUEL, start_ammo_fuel);
			STAT(WEAPONS, it) = start_weapons;
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
	entity e = REGISTRY_GET(Weapons, wpn);
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
	FOREACH(Weapons, it != WEP_Null, {
		if(NIX_CanChooseWeapon(it.m_id))
			RandomSelection_AddFloat(it.m_id, 1, (it.m_id != nix_weapon));
	});
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
		// Weapon w = REGISTRY_GET(Weapons, nix_weapon);
		// w.wr_init(w); // forget it, too slow
	}

	// get weapon info
	entity wpn = REGISTRY_GET(Weapons, nix_weapon);

	// TODO: registry handles
	if(nix_nextchange != this.nix_lastchange_id) // this shall only be called once per round!
	{
		SetResource(this, RES_SHELLS, 0);
		SetResource(this, RES_BULLETS, 0);
		SetResource(this, RES_ROCKETS, 0);
		SetResource(this, RES_CELLS, 0);
		SetResource(this, RES_FUEL, 0);
		if(this.items & IT_UNLIMITED_AMMO)
		{
			switch (wpn.ammo_type)
			{
				case RES_SHELLS:  SetResource(this, RES_SHELLS, autocvar_g_pickup_shells_max);  break;
				case RES_BULLETS: SetResource(this, RES_BULLETS, autocvar_g_pickup_nails_max);   break;
				case RES_ROCKETS: SetResource(this, RES_ROCKETS, autocvar_g_pickup_rockets_max); break;
				case RES_CELLS:   SetResource(this, RES_CELLS, autocvar_g_pickup_cells_max);   break;
				case RES_FUEL:    SetResource(this, RES_FUEL, autocvar_g_pickup_fuel_max);    break;
			}
		}
		else
		{
			switch (wpn.ammo_type)
			{
				case RES_SHELLS:  SetResource(this, RES_SHELLS, autocvar_g_balance_nix_ammo_shells);  break;
				case RES_BULLETS: SetResource(this, RES_BULLETS, autocvar_g_balance_nix_ammo_nails);   break;
				case RES_ROCKETS: SetResource(this, RES_ROCKETS, autocvar_g_balance_nix_ammo_rockets); break;
				case RES_CELLS:   SetResource(this, RES_CELLS, autocvar_g_balance_nix_ammo_cells);   break;
				case RES_FUEL:    SetResource(this, RES_FUEL, autocvar_g_balance_nix_ammo_fuel);    break;
			}
		}

		this.nix_nextincr = time + autocvar_g_balance_nix_incrtime;
		if(dt >= 1 && dt <= 5)
			this.nix_lastinfotime = -42;
		else
			Send_Notification(NOTIF_ONE_ONLY, this, MSG_CENTER, CENTER_NIX_NEWWEAPON, nix_weapon);

		wpn.wr_resetplayer(wpn, this);

		// all weapons must be fully loaded when we spawn
		if (wpn.spawnflags & WEP_FLAG_RELOADABLE) // prevent accessing undefined cvars
		{
			for (int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
			{
				.entity weaponentity = weaponentities[slot];
				this.(weaponentity).(weapon_load[nix_weapon]) = wpn.reloading_ammo;
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

	if(!(this.items & IT_UNLIMITED_AMMO) && time > this.nix_nextincr)
	{
		switch (wpn.ammo_type)
		{
			case RES_SHELLS:  GiveResource(this, RES_SHELLS, autocvar_g_balance_nix_ammoincr_shells);  break;
			case RES_BULLETS: GiveResource(this, RES_BULLETS, autocvar_g_balance_nix_ammoincr_nails);   break;
			case RES_ROCKETS: GiveResource(this, RES_ROCKETS, autocvar_g_balance_nix_ammoincr_rockets); break;
			case RES_CELLS:   GiveResource(this, RES_CELLS, autocvar_g_balance_nix_ammoincr_cells);   break;
			case RES_FUEL:    GiveResource(this, RES_FUEL, autocvar_g_balance_nix_ammoincr_fuel);    break;
		}

		this.nix_nextincr = time + autocvar_g_balance_nix_incrtime;
	}

	STAT(WEAPONS, this) = '0 0 0';
	if(g_nix_with_blaster)
		STAT(WEAPONS, this) |= WEPSET(BLASTER);
	STAT(WEAPONS, this) |= wpn.m_wepset;

	for (int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	{
		.entity weaponentity = weaponentities[slot];
		if (this.(weaponentity).m_weapon == WEP_Null && slot != 0)
			continue;

		if (this.(weaponentity).m_switchweapon != wpn)
		if (!client_hasweapon(this, this.(weaponentity).m_switchweapon, weaponentity, true, false))
		{
			if (client_hasweapon(this, wpn, weaponentity, true, false))
				W_SwitchWeapon(this, wpn, weaponentity);
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

MUTATOR_HOOKFUNCTION(nix, FilterItemDefinition)
{
	entity definition = M_ARGV(0, entity);

	if (definition.instanceOfHealth || definition.instanceOfArmor)
	{
		return !autocvar_g_nix_with_healtharmor;
	}
	else if (definition.instanceOfPowerup)
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

MUTATOR_HOOKFUNCTION(nix, ForbidRandomStartWeapons)
{
	return true;
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
