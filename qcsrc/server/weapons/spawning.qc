#include "spawning.qh"

#include "weaponsystem.qh"
#include "../mutators/all.qh"
#include "../t_items.qh"
#include "../../common/weapons/all.qh"

string W_Apply_Weaponreplace(string in)
{
	string out = "";
	FOREACH_WORD(in, true, {
		string replacement = "";
		Weapon w = Weapons_fromstr(it);
		if (w)
		{
            replacement = w.weaponreplace;
            if (replacement == "") replacement = it;
		}
		if (replacement == "0") continue;
		out = cons(out, replacement);
	});
	return out;
}

void weapon_defaultspawnfunc(entity this, Weapon e)
{
	int wpn = e.m_id;
	if (this.classname != "droppedweapon" && this.classname != "replacedweapon")
	{
		if (e.spawnflags & WEP_FLAG_MUTATORBLOCKED)
		{
			objerror("Attempted to spawn a mutator-blocked weapon rejected");
			startitem_failed = true;
			return;
		}

		string s = W_Apply_Weaponreplace(e.netname);
		MUTATOR_CALLHOOK(SetWeaponreplace, this, e, s);
		s = ret_string;
		if (s == "")
		{
			remove(this);
			startitem_failed = true;
			return;
		}
		int t = tokenize_console(s);
		if (t >= 2)
		{
			this.team = --internalteam;
			for (int i = 1; i < t; ++i)
			{
				s = argv(i);
				int j;
				for (j = WEP_FIRST; j <= WEP_LAST; ++j)
				{
					e = Weapons_from(j);
					if (e.netname == s)
					{
						entity replacement = spawn();
						copyentity(this, replacement);
						replacement.classname = "replacedweapon";
						weapon_defaultspawnfunc(replacement, e);
						break;
					}
				}
				if (j > WEP_LAST)
				{
					LOG_INFO("The weapon replace list for ", this.classname, " contains an unknown weapon ", s, ". Skipped.\n");
				}
			}
		}
		if (t >= 1) // always the case!
		{
			s = argv(0);
			wpn = 0;
			int j;
			for (j = WEP_FIRST; j <= WEP_LAST; ++j)
			{
				e = Weapons_from(j);
				if (e.netname == s)
				{
					wpn = j;
					break;
				}
			}
			if (j > WEP_LAST)
			{
				LOG_INFO("The weapon replace list for ", this.classname, " contains an unknown weapon ", s, ". Skipped.\n");
			}
		}
		if (wpn == 0)
		{
			remove(this);
			startitem_failed = true;
			return;
		}
	}

	e = Weapons_from(wpn);

	if (!this.respawntime)
	{
		if (e.spawnflags & WEP_FLAG_SUPERWEAPON)
		{
			this.respawntime = g_pickup_respawntime_superweapon;
			this.respawntimejitter = g_pickup_respawntimejitter_superweapon;
		}
		else
		{
			this.respawntime = g_pickup_respawntime_weapon;
			this.respawntimejitter = g_pickup_respawntimejitter_weapon;
		}
	}

	if (e.spawnflags & WEP_FLAG_SUPERWEAPON)
		if (!this.superweapons_finished)
			this.superweapons_finished = autocvar_g_balance_superweapons_time;

	// if we don't already have ammo, give us some ammo
	if (!this.(e.ammo_field))
	{
		switch (e.ammo_field)
		{
			case ammo_shells:  this.ammo_shells  = cvar("g_pickup_shells_weapon");  break;
			case ammo_nails:   this.ammo_nails   = cvar("g_pickup_nails_weapon");   break;
			case ammo_rockets: this.ammo_rockets = cvar("g_pickup_rockets_weapon"); break;
			case ammo_cells:   this.ammo_cells   = cvar("g_pickup_cells_weapon");   break;
			case ammo_plasma:  this.ammo_plasma  = cvar("g_pickup_plasma_weapon");  break;
			case ammo_fuel:    this.ammo_fuel    = cvar("g_pickup_fuel_weapon");    break;
		}
	}

	#if 0 // WEAPONTODO
	if (e.items)
	{
		for (int i = 0, j = 1; i < 24; ++i, j <<= 1)
		{
			if (e.items & j)
			{
				ammotype = Item_CounterField(j);
				if (!this.ammotype)
					this.ammotype = cvar(strcat("g_pickup_", Item_CounterFieldName(j), "_weapon"));
			}
		}
	}
	#endif

	// pickup anyway
	if (g_pickup_weapons_anyway)
		this.pickup_anyway = true;

	GameItem def = e.m_pickup;
	_StartItem(
		this,
		this.itemdef = def,
		this.respawntime, // defaultrespawntime
		this.respawntimejitter // defaultrespawntimejitter
	);
	#if 0 // WEAPONTODO
	if (this.modelindex) { // don't precache if this was removed
		e.wr_init(e);
	}
	#endif
}
