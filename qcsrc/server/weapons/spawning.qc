#include "spawning.qh"

#include <common/resources/sv_resources.qh>
#include <common/weapons/_all.qh>
#include <server/items/items.qh>
#include <server/items/spawning.qh>
#include <server/mutators/_mod.qh>
#include <server/weapons/weaponsystem.qh>
#include <server/world.qh>

.bool m_isreplaced; ///< Holds whether the weapon has been replaced.

string W_Apply_Weaponreplace(string in)
{
	string out = "";
	FOREACH_WORD(in, true, {
		string replacement = "";
		Weapon w = Weapon_from_name(it);
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

void weapon_defaultspawnfunc(entity this, Weapon wpn)
{
	wpn = wpn.m_spawnfunc_hookreplace(wpn, this);
	this.classname = wpn.m_canonical_spawnfunc;
	if (!Item_IsLoot(this) && !this.m_isreplaced)
	{
		if (wpn.spawnflags & WEP_FLAG_MUTATORBLOCKED)
		{
			//LOG_WARNF("Attempted to spawn a mutator-blocked weapon rejected: prvm_edict server %i", this);
			startitem_failed = true;
			return;
		}

		string s = W_Apply_Weaponreplace(wpn.netname);
		MUTATOR_CALLHOOK(SetWeaponreplace, this, wpn, s);
		s = M_ARGV(2, string);
		if (s == "")
		{
			delete(this);
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
				Weapon wep = Weapon_from_name(s);
				if(wep != WEP_Null)
				{
					entity replacement = spawn();
					copyentity(this, replacement);
					replacement.m_isreplaced = true;
					weapon_defaultspawnfunc(replacement, wep);
				}
			}
		}
		if (t >= 1) // always the case!
		{
			s = argv(0);
			wpn = Weapon_from_name(s);
		}
		if (wpn == WEP_Null)
		{
			delete(this);
			startitem_failed = true;
			return;
		}
	}

	if(!Item_IsLoot(this))
		weaponsInMapAll |= WepSet_FromWeapon(wpn);

	if (!Item_IsDefinitionAllowed(wpn.m_pickup))
	{
		delete(this);
		startitem_failed = true;
		return;
	}

	if (!this.respawntime)
	{
		if (wpn.spawnflags & WEP_FLAG_SUPERWEAPON)
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

	if (wpn.spawnflags & WEP_FLAG_SUPERWEAPON)
		if (!this.superweapons_finished)
			this.superweapons_finished = autocvar_g_balance_superweapons_time;

	// if we don't already have ammo, give us some ammo
	// TODO: registry handles
	if ((wpn.ammo_type != RES_NONE) && !GetResource(this, wpn.ammo_type))
	{
		int ammo = 0;
		if (q3compat && this.count > 0)
			ammo = this.count * GetAmmoConsumptionQ3(wpn.netname);
			// WEAPONTODO: magazines of MG, rifle and OK weapons are unaccounted for
		else
		{
			switch (wpn.ammo_type)
			{
				case RES_SHELLS:  ammo = cvar("g_pickup_shells_weapon");  break;
				case RES_BULLETS: ammo = cvar("g_pickup_nails_weapon");   break;
				case RES_ROCKETS: ammo = cvar("g_pickup_rockets_weapon"); break;
				case RES_CELLS:   ammo = cvar("g_pickup_cells_weapon");   break;
				case RES_PLASMA:  ammo = cvar("g_pickup_plasma_weapon");  break;
				case RES_FUEL:    ammo = cvar("g_pickup_fuel_weapon");    break;
			}
		}

		SetResource(this, wpn.ammo_type, ammo);
	}

	#if 0 // WEAPONTODO
	if (wpn.items)
	{
		for (int i = 0, j = 1; i < 24; ++i, j <<= 1)
		{
			if (wpn.items & j)
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

	if(!this.owner)
		this.glowmod = wpn.wpcolor;
	else
		this.glowmod = colormapPaletteColor(this.owner.clientcolors & 0x0F, true) * 2;

	GameItem def = wpn.m_pickup;
	_StartItem(
		this,
		this.itemdef = def,
		this.respawntime, // defaultrespawntime
		this.respawntimejitter // defaultrespawntimejitter
	);
	#if 0 // WEAPONTODO
	if (this.modelindex) { // don't precache if this was removed
		wpn.wr_init(wpn);
	}
	#endif
}
