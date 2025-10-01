#include "items.qh"

#include <common/checkextension.qh>
#include <common/constants.qh>
#include <common/deathtypes/all.qh>
#include <common/gametypes/gametype/cts/cts.qh>
#include <common/items/_mod.qh>
#include <common/mapobjects/subs.qh>
#include <common/mapobjects/triggers.qh>
#include <common/monsters/_mod.qh>
#include <common/mutators/mutator/buffs/_mod.qh>
#include <common/mutators/mutator/powerups/_mod.qh>
#include <common/mutators/mutator/status_effects/_mod.qh>
#include <common/net_linked.qh>
#include <common/notifications/all.qh>
#include <common/resources/resources.qh>
#include <common/util.qh>
#include <common/weapons/_all.qh>
#include <common/wepent.qh>
#include <lib/warpzone/common.qh>
#include <lib/warpzone/util_server.qh>
#include <server/bot/api.qh>
#include <server/command/vote.qh>
#include <server/damage.qh>
#include <server/mutators/_mod.qh>
#include <server/teamplay.qh>
#include <server/weapons/common.qh>
#include <server/weapons/selection.qh>
#include <server/weapons/weaponsystem.qh>
#include <server/world.qh>

bool ItemSend(entity this, entity to, int sf)
{
	if(this.gravity)
		sf |= ISF_DROP;
	else
		sf &= ~ISF_DROP;

	// if this item is being spawned (in CSQC's perspective)
	// reuse ISF_SIZE and ISF_SIZE2 to also tell CSQC its bbox size
	if(sf & ISF_SIZE)
	{
		if(this.maxs == ITEM_S_MAXS) // Small
		{
			sf |= ISF_SIZE;
			sf &= ~ISF_SIZE2;
		}
		else if(this.maxs == ITEM_L_MAXS) // Large
		{
			sf &= ~ISF_SIZE;
			sf |= ISF_SIZE2;
		}
		else // Default
			sf |= ISF_SIZE | ISF_SIZE2;
	}

	WriteHeader(MSG_ENTITY, ENT_CLIENT_ITEM);
	WriteByte(MSG_ENTITY, sf);

	//WriteByte(MSG_ENTITY, this.cnt);
	if(sf & ISF_LOCATION)
	{
		WriteVector(MSG_ENTITY, this.origin);
	}

	if(sf & ISF_ANGLES)
	{
		WriteAngleVector(MSG_ENTITY, this.angles);
	}

	if(sf & ISF_STATUS)
		WriteByte(MSG_ENTITY, this.ItemStatus);

	if(sf & (ISF_SIZE | ISF_SIZE2)) // always true when it's spawned (in CSQC's perspective)
	{
		WriteShort(MSG_ENTITY, bound(0, this.fade_end, 32767));

		if(this.mdl == "")
			LOG_TRACE("^1WARNING!^7 this.mdl is unset for item ", this.classname, "expect a crash just about now");

		WriteString(MSG_ENTITY, this.mdl);
		WriteByte(MSG_ENTITY, bound(0, this.skin, 255));
	}

	if(sf & ISF_COLORMAP)
	{
		WriteShort(MSG_ENTITY, this.colormap);
		WriteByte(MSG_ENTITY, this.glowmod.x * 255.0);
		WriteByte(MSG_ENTITY, this.glowmod.y * 255.0);
		WriteByte(MSG_ENTITY, this.glowmod.z * 255.0);
	}

	if(sf & ISF_DROP)
	{
		WriteVector(MSG_ENTITY, this.velocity);
	}

	return true;
}

void ItemUpdate(entity this)
{
	this.oldorigin = this.origin;
	this.SendFlags |= ISF_LOCATION;
}

void UpdateItemAfterTeleport(entity this)
{
	if(getSendEntity(this) == ItemSend)
		ItemUpdate(this);
}

bool have_pickup_item(entity this)
{
	if (this.itemdef.spawnflags & ITEM_FLAG_MUTATORBLOCKED)
		return false;

	if(!this.itemdef.instanceOfPowerup)
	{
		if(autocvar_g_pickup_items > 0)
			return true;
		if(autocvar_g_pickup_items == 0)
			return false;
		if(g_weaponarena)
			if(STAT(WEAPONS, this) || this.itemdef.instanceOfAmmo) // no item or ammo pickups in weaponarena
				return false;
	}
	return true;
}

void Item_Show(entity e, int mode)
{
	e.effects &= ~(EF_ADDITIVE | EF_STARDUST | EF_FULLBRIGHT | EF_NODEPTHTEST);
	e.ItemStatus &= ~ITS_STAYWEP;
	entity def = e.itemdef;
	if (mode > 0)
	{
		// make the item look normal, and be touchable
		e.model = e.mdl;
		e.solid = SOLID_TRIGGER;
		e.spawnshieldtime = 1;
		e.ItemStatus |= ITS_AVAILABLE;
	}
	else if (mode < 0)
	{
		// hide the item completely
		e.model = string_null;
		e.solid = SOLID_NOT;
		e.spawnshieldtime = 1;
		e.ItemStatus &= ~ITS_AVAILABLE;
	}
	else
	{
		bool nostay = def.instanceOfWeaponPickup ? !!(def.m_weapon.m_wepset & WEPSET_SUPERWEAPONS) : false // no weapon-stay on superweapons
			|| e.team // weapon stay isn't supported for teamed weapons
			;
		if(def.instanceOfWeaponPickup && !nostay && g_weapon_stay)
		{
			// make the item translucent and not touchable
			e.model = e.mdl;
			e.solid = SOLID_TRIGGER; // can STILL be picked up!
			e.effects |= EF_STARDUST;
			e.spawnshieldtime = 0; // field indicates whether picking it up may give you anything other than the weapon
			e.ItemStatus |= (ITS_AVAILABLE | ITS_STAYWEP);
		}
		else
		{
			e.solid = SOLID_NOT;
			e.spawnshieldtime = 1;
			e.ItemStatus &= ~ITS_AVAILABLE;
		}
	}

	if (def.m_glow)
		e.ItemStatus |= ITS_GLOW;

	if (autocvar_g_nodepthtestitems)
		e.effects |= EF_NODEPTHTEST;

	if (autocvar_g_fullbrightitems)
		e.ItemStatus |= ITS_ALLOWFB;
	else
		e.ItemStatus &= ~ITS_ALLOWFB;

	if (autocvar_sv_simple_items)
		e.ItemStatus |= ITS_ALLOWSI;

	// relink entity (because solid may have changed)
	setorigin(e, e.origin);
	e.SendFlags |= ISF_STATUS;
}

void Item_Think(entity this)
{
	if (ITEM_IS_LOOT(this))
	{
		if (time < this.wait - IT_DESPAWNFX_TIME)
			this.nextthink = min(time + IT_UPDATE_INTERVAL, this.wait - IT_DESPAWNFX_TIME); // ensuring full time for effects
		else
		{
			// despawning soon, start effects
			this.ItemStatus |= ITS_EXPIRING;
			this.SendFlags |= ISF_STATUS;
			if (time < this.wait - IT_UPDATE_INTERVAL)
				this.nextthink = time + IT_UPDATE_INTERVAL;
			else
			{
				setthink(this, RemoveItem);
				this.nextthink = this.wait;
			}
		}

		if (this.itemdef.instanceOfPowerup)
			powerups_DropItem_Think(this);

		// caution: kludge FIXME (with sv_legacy_bbox_expand)
		// this works around prediction errors caused by bbox discrepancy between SVQC and CSQC
		if (this.velocity == '0 0 0' && IS_ONGROUND(this))
			this.gravity = 0; // don't send ISF_DROP anymore

		// send slow updates even if the item didn't move
		// recovers prediction desyncs where server thinks item stopped, client thinks it didn't
		ItemUpdate(this);
	}
	else
	{
		// bones_was_here: TODO: predict movers, enable client prediction of items with a groundentity,
		// and then send those less often too (and not all on the same frame)
		this.nextthink = time;

		if(this.origin != this.oldorigin)
			ItemUpdate(this);
	}
}

bool Item_ItemsTime_SpectatorOnly(GameItem it);
bool Item_ItemsTime_Allow(GameItem it);
float Item_ItemsTime_UpdateTime(entity e, float t);
void Item_ItemsTime_SetTime(entity e, float t);
void Item_ItemsTime_SetTimesForAllPlayers();

void Item_Respawn(entity this)
{
	Item_Show(this, 1);
	sound(this, CH_TRIGGER, this.itemdef.m_respawnsound, VOL_BASE, ATTEN_NORM);	// play respawn sound

	if (Item_ItemsTime_Allow(this.itemdef) || (STAT(WEAPONS, this) & WEPSET_SUPERWEAPONS))
	{
		float t = Item_ItemsTime_UpdateTime(this, 0);
		Item_ItemsTime_SetTime(this, t);
		Item_ItemsTime_SetTimesForAllPlayers();
	}

	setthink(this, Item_Think);
	this.nextthink = time;
}

void Item_RespawnCountdown(entity this)
{
	if(this.item_respawncounter >= ITEM_RESPAWN_TICKS)
	{
		if(this.waypointsprite_attached)
			WaypointSprite_Kill(this.waypointsprite_attached);
		Item_Respawn(this);
	}
	else
	{
		this.nextthink = time + 1;
		this.item_respawncounter += 1;
		if(this.item_respawncounter == 1)
		{
			do {
				{
					entity wi = REGISTRY_GET(Weapons, this.weapon);
					if (wi != WEP_Null) {
						entity wp = WaypointSprite_Spawn(WP_Weapon, 0, 0, this, '0 0 64', NULL, 0, this, waypointsprite_attached, true, RADARICON_Weapon);
						wp.wp_extra = wi.m_id;
						break;
					}
				}
				{
					entity ii = this.itemdef;
					if (ii != NULL) {
						entity wp = WaypointSprite_Spawn(WP_Item, 0, 0, this, '0 0 64', NULL, 0, this, waypointsprite_attached, true, RADARICON_Item);
						wp.wp_extra = ii.m_id;
						break;
					}
				}
			} while (0);
			bool mutator_returnvalue = MUTATOR_CALLHOOK(Item_RespawnCountdown, this);
			if(this.waypointsprite_attached)
			{
				GameItem def = this.itemdef;
				if (Item_ItemsTime_SpectatorOnly(def) && !mutator_returnvalue)
					WaypointSprite_UpdateRule(this.waypointsprite_attached, 0, SPRITERULE_SPECTATOR);
				WaypointSprite_UpdateBuildFinished(this.waypointsprite_attached, time + ITEM_RESPAWN_TICKS);
			}
		}

		if(this.waypointsprite_attached)
		{
			FOREACH_CLIENT(IS_REAL_CLIENT(it), {
				if(this.waypointsprite_attached.waypointsprite_visible_for_player(this.waypointsprite_attached, it, it))
				{
					msg_entity = it;
					soundto(MSG_ONE, this, CH_TRIGGER, SND(ITEMRESPAWNCOUNTDOWN), VOL_BASE, ATTEN_NORM, 0);	// play respawn sound
				}
			});

			WaypointSprite_Ping(this.waypointsprite_attached);
			//WaypointSprite_UpdateHealth(this.waypointsprite_attached, this.item_respawncounter);
		}
	}
}

void Item_RespawnThink(entity this)
{
	this.nextthink = time;
	if(this.origin != this.oldorigin)
		ItemUpdate(this);

	if(time >= this.wait)
		Item_Respawn(this);
}

void Item_ScheduleRespawnIn(entity e, float t)
{
	// if the respawn time is longer than 10 seconds, show a waypoint, otherwise, just respawn normally
	if ((Item_ItemsTime_Allow(e.itemdef) || (STAT(WEAPONS, e) & WEPSET_SUPERWEAPONS) || MUTATOR_CALLHOOK(Item_ScheduleRespawn, e, t)) && (t - ITEM_RESPAWN_TICKS) > 0)
	{
		setthink(e, Item_RespawnCountdown);
		e.nextthink = time + max(0, t - ITEM_RESPAWN_TICKS);
		e.scheduledrespawntime = e.nextthink + ITEM_RESPAWN_TICKS;
		e.item_respawncounter = 0;
		if(Item_ItemsTime_Allow(e.itemdef) || (STAT(WEAPONS, e) & WEPSET_SUPERWEAPONS))
		{
			t = Item_ItemsTime_UpdateTime(e, e.scheduledrespawntime);
			Item_ItemsTime_SetTime(e, t);
			Item_ItemsTime_SetTimesForAllPlayers();
		}
	}
	else
	{
		setthink(e, Item_RespawnThink);
		e.nextthink = time;
		e.scheduledrespawntime = time + t;
		e.wait = time + t;

		if(Item_ItemsTime_Allow(e.itemdef) || (STAT(WEAPONS, e) & WEPSET_SUPERWEAPONS))
		{
			t = Item_ItemsTime_UpdateTime(e, e.scheduledrespawntime);
			Item_ItemsTime_SetTime(e, t);
			Item_ItemsTime_SetTimesForAllPlayers();
		}
	}
}

AUTOCVAR(g_pickup_respawntime_scaling_reciprocal, float, 0.0, "multiply respawn time by `reciprocal / (p + offset) + linear` where `p` is the current number of players, takes effect with 2 or more players present, `reciprocal` (with `offset` and `linear` set to \\\"0\\\") can be used to achieve a constant number of items spawned *per player*");
AUTOCVAR(g_pickup_respawntime_scaling_offset, float, 0.0, "multiply respawn time by `reciprocal / (p + offset) + linear` where `p` is the current number of players, takes effect with 2 or more players present, `offset` offsets the curve left or right (NOTE: results are not intuitive and it is recommend to plot the respawn time and the number of items per player to see what's happening)");
AUTOCVAR(g_pickup_respawntime_scaling_linear, float, 1.0, "multiply respawn time by `reciprocal / (p + offset) + linear` where `p` is the current number of players, takes effect with 2 or more players present, `linear` can be used to simply scale the respawn time linearly");

/// Adjust respawn time according to the number of players.
float adjust_respawntime(float normal_respawntime) {
	float r = autocvar_g_pickup_respawntime_scaling_reciprocal;
	float o = autocvar_g_pickup_respawntime_scaling_offset;
	float l = autocvar_g_pickup_respawntime_scaling_linear;

	if (r == 0 && l == 1) {
		return normal_respawntime;
	}

	entity balance = TeamBalance_CheckAllowedTeams(NULL);
	TeamBalance_GetTeamCounts(balance, NULL);
	int players = 0;
	for (int i = 1; i <= NUM_TEAMS; ++i)
	{
		if (TeamBalance_IsTeamAllowed(balance, i))
		{
			players += TeamBalance_GetNumberOfPlayers(balance, i);
		}
	}
	TeamBalance_Destroy(balance);

	if (players >= 2) {
		return normal_respawntime * (r / (players + o) + l);
	} else {
		return normal_respawntime;
	}
}

void Item_ScheduleRespawn(entity e)
{
	if(e.respawntime > 0)
	{
		Item_Show(e, 0);

		float adjusted_respawntime = adjust_respawntime(e.respawntime);
		//LOG_INFOF("item %s will respawn in %f", e.classname, adjusted_respawntime);

		// range: adjusted_respawntime - respawntimejitter .. adjusted_respawntime + respawntimejitter
		float respawn_in = adjusted_respawntime + crandom() * e.respawntimejitter;
		Item_ScheduleRespawnIn(e, respawn_in);
	}
	else // if respawntime is -1, this item does not respawn
		Item_Show(e, -1);
}

AUTOCVAR(g_pickup_respawntime_initial_random, int, 1,
	"for items that don't start spawned; \\\"0\\\" = spawn after their normal respawntime, \\\"1\\\" = spawn after `random * respawntime` with the *same* random, \\\"2\\\" = same as 1 but each item has separate random");

void Item_ScheduleInitialRespawn(entity e)
{
	Item_Show(e, 0);

	float spawn_in;
	if (autocvar_g_pickup_respawntime_initial_random == 0)
	{
		// range: respawntime .. respawntime + respawntimejitter
		spawn_in = e.respawntime + random() * e.respawntimejitter;
	}
	else
	{
		float rnd;
		if (autocvar_g_pickup_respawntime_initial_random == 1)
		{
			static float shared_random = 0;
			// NOTE this code works only if items are scheduled at the same time (normal case)
			// NOTE2 random() can't return exactly 1 so this check always work as intended
			if (!shared_random || floor(time) > shared_random)
				shared_random = floor(time) + random();
			rnd = shared_random - floor(time);
		}
		else
			rnd = random();

		// range:
		// if respawntime >= ITEM_RESPAWN_TICKS: ITEM_RESPAWN_TICKS .. respawntime + respawntimejitter
		// else: 0 .. ITEM_RESPAWN_TICKS
		// this is to prevent powerups spawning unexpectedly without waypoints
		spawn_in = ITEM_RESPAWN_TICKS + rnd * (e.respawntime + e.respawntimejitter - ITEM_RESPAWN_TICKS);
	}

	Item_ScheduleRespawnIn(e, max(0, game_starttime - time) + ((e.respawntimestart) ? e.respawntimestart : spawn_in));
}

void GiveRandomWeapons(entity receiver, int num_weapons, string weapon_names,
	entity ammo_entity)
{
	if (num_weapons == 0)
	{
		return;
	}
	int num_potential_weapons = tokenize_console(weapon_names);
	for (int give_attempt = 0; give_attempt < num_weapons; ++give_attempt)
	{
		RandomSelection_Init();
		for (int weapon_index = 0; weapon_index < num_potential_weapons;
			++weapon_index)
		{
			string weapon = argv(weapon_index);
			FOREACH(Weapons, it != WEP_Null,
			{
				// Finding a weapon which player doesn't have.
				if (!(STAT(WEAPONS, receiver) & it.m_wepset) && (it.netname == weapon))
				{
					RandomSelection_AddEnt(it, 1, 1);
					break;
				}
			});
		}
		if (RandomSelection_chosen_ent == NULL)
		{
			return;
		}
		STAT(WEAPONS, receiver) |= RandomSelection_chosen_ent.m_wepset;
		if (RandomSelection_chosen_ent.ammo_type == RES_NONE)
		{
			continue;
		}
		if (GetResource(receiver,
			RandomSelection_chosen_ent.ammo_type) != 0)
		{
			continue;
		}
		GiveResource(receiver, RandomSelection_chosen_ent.ammo_type,
			GetResource(ammo_entity,
			RandomSelection_chosen_ent.ammo_type));
	}
}

bool Item_GiveAmmoTo(entity item, entity player, Resource res_type, float ammomax)
{
	float amount = GetResource(item, res_type);
	if (amount == 0)
	{
		return false;
	}
	float player_amount = GetResource(player, res_type);
	if (item.spawnshieldtime)
	{
		if ((player_amount >= ammomax) && (item.pickup_anyway <= 0))
			return false;
	}
	else if (g_weapon_stay == 2)
	{
		ammomax = min(amount, ammomax);
		if(player_amount >= ammomax)
			return false;
	}
	else
		return false;
	if (amount < 0)
		TakeResourceWithLimit(player, res_type, -amount, ammomax);
	else
		GiveResourceWithLimit(player, res_type, amount, ammomax);
	return true;
}

void Item_NotifyWeapon(entity player, int wep)
{
	FOREACH_CLIENT(IS_REAL_CLIENT(it) && (it == player || (IS_SPEC(it) && it.enemy == player)), {
		msg_entity = it;
		WriteHeader(MSG_ONE, TE_CSQC_WEAPONPICKUP);
		WriteByte(MSG_ONE, wep);
	});
}

bool Item_GiveTo(entity item, entity player)
{
	// if nothing happens to player, just return without taking the item
	int _switchweapon = 0;
	// in case the player has cl_autoswitch enabled do the following:
	// if the player is using their best weapon before items are given, they
	// probably want to switch to an even better weapon after items are given

	bool use_cts_autoswitch = (g_cts && item.itemdef.instanceOfWeaponPickup && (CS_CVAR(player).cvar_cl_autoswitch_cts != -1));
	if (CS_CVAR(player).cvar_cl_autoswitch && !use_cts_autoswitch)
	{
		for (int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
		{
			.entity weaponentity = weaponentities[slot];
			if (player.(weaponentity).m_weapon != WEP_Null || slot == 0)
			{
				if (player.(weaponentity).m_switchweapon == w_getbestweapon(player, weaponentity))
					_switchweapon |= BIT(slot);

				if (!(STAT(WEAPONS, player) & WepSet_FromWeapon(player.(weaponentity).m_switchweapon)))
					_switchweapon |= BIT(slot);
			}
		}
	}
	bool pickedup = false;
	pickedup |= Item_GiveAmmoTo(item, player, RES_HEALTH, item.max_health);
	pickedup |= Item_GiveAmmoTo(item, player, RES_ARMOR, item.max_armorvalue);
	pickedup |= Item_GiveAmmoTo(item, player, RES_SHELLS, autocvar_g_pickup_shells_max);
	pickedup |= Item_GiveAmmoTo(item, player, RES_BULLETS, autocvar_g_pickup_nails_max);
	pickedup |= Item_GiveAmmoTo(item, player, RES_ROCKETS, autocvar_g_pickup_rockets_max);
	pickedup |= Item_GiveAmmoTo(item, player, RES_CELLS, autocvar_g_pickup_cells_max);
	pickedup |= Item_GiveAmmoTo(item, player, RES_FUEL, autocvar_g_pickup_fuel_max);
	if (item.itemdef.instanceOfWeaponPickup)
	{
		WepSet w, wp;
		w = STAT(WEAPONS, item);
		wp = w & ~STAT(WEAPONS, player);

		if (wp || (item.spawnshieldtime && item.pickup_anyway > 0))
		{
			pickedup = true;
			FOREACH(Weapons, it != WEP_Null, {
				if(w & (it.m_wepset))
					Item_NotifyWeapon(player, it.m_id);

				if(wp & (it.m_wepset))
				{
					for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
					{
						.entity weaponentity = weaponentities[slot];
						if(player.(weaponentity).m_weapon != WEP_Null || slot == 0)
							W_DropEvent(wr_pickup, player, it.m_id, item, weaponentity);
					}
					W_GiveWeapon(player, it.m_id);
				}
			});
		}
	}

	if (item.itemdef.instanceOfPowerup)
	{
		if ((item.itemdef == ITEM_FuelRegen) && !(player.items & IT_FUEL_REGEN))
			Send_Notification(NOTIF_ONE, player, MSG_CENTER, CENTER_ITEM_FUELREGEN_GOT);
		else if ((item.itemdef == ITEM_Jetpack) && !(player.items & IT_JETPACK))
			Send_Notification(NOTIF_ONE, player, MSG_CENTER, CENTER_ITEM_JETPACK_GOT);
	}

	int its = item.items & ~(player.items) & IT_PICKUPMASK;
	if (its)
	{
		pickedup = true;
		player.items |= its;
		// TODO: we probably want to show a message in the console, but not this one!
		//Send_Notification(NOTIF_ONE, player, MSG_INFO, INFO_ITEM_WEAPON_GOT, item.netname);
	}

	if (item.strength_finished)
	{
		pickedup = true;
		float t = StatusEffects_gettime(STATUSEFFECT_Strength, player);
		if (autocvar_g_powerups_stack)
			t += item.strength_finished;
		else
			t = max(t, time + item.strength_finished);
		StatusEffects_apply(STATUSEFFECT_Strength, player, t, 0);
	}
	if (item.invincible_finished)
	{
		pickedup = true;
		float t = StatusEffects_gettime(STATUSEFFECT_Shield, player);
		if (autocvar_g_powerups_stack)
			t += item.invincible_finished;
		else
			t = max(t, time + item.invincible_finished);
		StatusEffects_apply(STATUSEFFECT_Shield, player, t, 0);
	}
	if (item.speed_finished)
	{
		pickedup = true;
		float t = StatusEffects_gettime(STATUSEFFECT_Speed, player);
		if (autocvar_g_powerups_stack)
			t += item.speed_finished;
		else
			t = max(t, time + item.speed_finished);
		StatusEffects_apply(STATUSEFFECT_Speed, player, t, 0);
	}
	if (item.invisibility_finished)
	{
		pickedup = true;
		float t = StatusEffects_gettime(STATUSEFFECT_Invisibility, player);
		if (autocvar_g_powerups_stack)
			t += item.invisibility_finished;
		else
			t = max(t, time + item.invisibility_finished);
		StatusEffects_apply(STATUSEFFECT_Invisibility, player, t, 0);
	}
	if (item.superweapons_finished)
	{
		pickedup = true;
		float t = StatusEffects_gettime(STATUSEFFECT_Superweapon, player);
		StatusEffects_apply(STATUSEFFECT_Superweapon, player, t + item.superweapons_finished, 0);
	}

	// always eat teamed entities
	if(item.team)
		pickedup = true;

	if (!pickedup)
		return false;

	if(use_cts_autoswitch)
	{
		// CTS handling: never switch (0), always switch (1)
		if(CS_CVAR(player).cvar_cl_autoswitch_cts == 1)
		{
			// crude hack to enforce switching weapons
			for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
			{
				.entity weaponentity = weaponentities[slot];
				Weapon w = REGISTRY_GET(Weapons, item.weapon);
				if(player.(weaponentity).m_weapon != WEP_Null || slot == 0)
				if(client_hasweapon(player, w, weaponentity, true, false)) // ammo check
					W_SwitchWeapon_Force(player, w, weaponentity);
			}
		}
	}
	else if(_switchweapon)
	{
		// non-CTS handling: weaponpriority-based autoswitch
		for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
		{
			.entity weaponentity = weaponentities[slot];
			if(_switchweapon & BIT(slot))
			{
				Weapon best_wep = w_getbestweapon(player, weaponentity);
				if(player.(weaponentity).m_switchweapon != best_wep)
					W_SwitchWeapon_Force(player, best_wep, weaponentity);
			}
		}
	}

	return true;
}

void Item_Touch(entity this, entity toucher)
{
	// remove the item if it's currnetly in a NODROP brush or hits a NOIMPACT surface (such as sky)
	if (ITEM_IS_LOOT(this))
	{
		if (ITEM_TOUCH_NEEDKILL())
		{
			this.SendFlags |= ISF_REMOVEFX;
			RemoveItem(this);
			return;
		}
	}

	if(!(toucher.flags & FL_PICKUPITEMS)
	|| IS_DEAD(toucher)
	|| (this.solid != SOLID_TRIGGER)
	|| (this.owner == toucher)
	|| (time < this.item_spawnshieldtime)
	) { return; }

	switch (MUTATOR_CALLHOOK(ItemTouch, this, toucher))
	{
		case MUT_ITEMTOUCH_RETURN: { return; }
		case MUT_ITEMTOUCH_PICKUP: { toucher = M_ARGV(1, entity); goto pickup; }
	}

	toucher = M_ARGV(1, entity);

	if (ITEM_IS_EXPIRING(this))
	{
		this.strength_finished = max(0, this.strength_finished - time);
		this.invincible_finished = max(0, this.invincible_finished - time);
		this.speed_finished = max(0, this.speed_finished - time);
		this.invisibility_finished = max(0, this.invisibility_finished - time);
		this.superweapons_finished = max(0, this.superweapons_finished - time);
	}
	bool gave = ITEM_HANDLE(Pickup, this.itemdef, this, toucher);
	if (!gave)
	{
		if (ITEM_IS_EXPIRING(this))
		{
			// undo what we did above
			this.strength_finished += time;
			this.invincible_finished += time;
			this.speed_finished += time;
			this.invisibility_finished += time;
			this.superweapons_finished += time;
		}
		return;
	}

LABEL(pickup)

	if(this.target && this.target != "" && this.target != "###item###") // defrag support
		SUB_UseTargets(this, toucher, NULL);

	STAT(LAST_PICKUP, toucher) = time;

	GameItem def = this.itemdef;
	int ch = ((def.instanceOfPowerup && def.m_itemid != IT_RESOURCE) ? CH_TRIGGER_SINGLE : CH_TRIGGER);
	_sound(toucher, ch, this.item_pickupsound, VOL_BASE, ATTEN_NORM);

	MUTATOR_CALLHOOK(ItemTouched, this, toucher);
	if (wasfreed(this))
	{
		return;
	}

	if (ITEM_IS_LOOT(this))
	{
		this.SendFlags |= ISF_REMOVEFX;
		RemoveItem(this);
		return;
	}
	if (!this.spawnshieldtime)
	{
		return;
	}
	entity e;
	if (this.team)
	{
		RandomSelection_Init();
		IL_EACH(g_items, it.team == this.team,
		{
			if (it.itemdef) // is a registered item
			{
				Item_Show(it, -1);
				it.scheduledrespawntime = 0;
				RandomSelection_AddEnt(it, it.cnt, 0);
			}
		});
		e = RandomSelection_chosen_ent;
		Item_Show(e, 1); // reset its state so it is visible (extra sendflags doesn't matter, this happens anyway)
	}
	else
		e = this;
	Item_ScheduleRespawn(e);
}

void Item_Reset(entity this)
{
	Item_Show(this, !this.state);

	if (ITEM_IS_LOOT(this))
	{
		return;
	}
	setthink(this, Item_Think);
	this.nextthink = time;
	this.active = ACTIVE_ACTIVE;
	if (this.waypointsprite_attached)
	{
		WaypointSprite_Kill(this.waypointsprite_attached);
	}
	if (this.itemdef.instanceOfPowerup || (STAT(WEAPONS, this) & WEPSET_SUPERWEAPONS)) // do not spawn powerups initially!
	{
		Item_ScheduleInitialRespawn(this);
	}
}

void Item_FindTeam(entity this)
{
	if(!(this.effects & EF_NOGUNBOB)) // marker for item team search
		return;

	LOG_TRACE("Initializing item team ", ftos(this.team));
	RandomSelection_Init();
	IL_EACH(g_items, it.team == this.team,
	{
		if(it.itemdef) // is a registered item
			RandomSelection_AddEnt(it, it.cnt, 0);
	});

	entity e = RandomSelection_chosen_ent;
	if (!e)
		return;

	IL_EACH(g_items, it.team == this.team,
	{
		if(it.itemdef) // is a registered item
		{
			if(it != e)
			{
				Item_Show(it, -1); // make it non-spawned
				if (it.waypointsprite_attached)
					WaypointSprite_Kill(it.waypointsprite_attached);
				it.nextthink = 0; // disable any scheduled powerup spawn
			}
			else
				Item_Reset(it);

			// leave 'this' marked so Item_FindTeam() works when called again via this.reset
			if(it != this)
				it.effects &= ~EF_NOGUNBOB;
		}
	});
}

void Item_CopyFields(entity this, entity to)
{
	setorigin(to, this.origin);
	to.spawnflags = this.spawnflags;
	to.noalign = ITEM_SHOULD_KEEP_POSITION(this);
	to.cnt = this.cnt;
	to.team = this.team;
	to.spawnfunc_checked = true;
	// TODO: copy respawn times? this may not be desirable in some cases
	//to.respawntime = this.respawntime;
	//to.respawntimejitter = this.respawntimejitter;
}

// Savage: used for item garbage-collection
void RemoveItem(entity this)
{
	if(wasfreed(this) || !this) { return; }
	if(this.waypointsprite_attached)
		WaypointSprite_Kill(this.waypointsprite_attached);

	if (this.SendFlags & ISF_REMOVEFX)
	{
		// delay removal until ISF_REMOVEFX has been sent
		setthink(this, RemoveItem);
		this.nextthink = time + 2 * autocvar_sys_ticrate; // micro optimisation: next frame will be too soon
		this.solid = SOLID_NOT; // untouchable
	}
	else
		delete(this);
}

// pickup evaluation functions
// these functions decide how desirable an item is to the bots

float generic_pickupevalfunc(entity player, entity item) {return item.bot_pickupbasevalue;}

float weapon_pickupevalfunc(entity player, entity item)
{
	// See if I have it already
	if(STAT(WEAPONS, player) & STAT(WEAPONS, item))
	{
		// If I can pick it up
		if(!item.spawnshieldtime)
			return 0;
		return ammo_pickupevalfunc(player, item);
	}

	// reduce weapon value if bot already got a good arsenal
	float c = 1;
	int weapons_value = 0;
	FOREACH(Weapons, it != WEP_Null && (STAT(WEAPONS, player) & it.m_wepset), {
		weapons_value += it.bot_pickupbasevalue;
	});
	c -= bound(0, weapons_value / 20000, 1) * 0.5;

	return item.bot_pickupbasevalue * c;
}

float ammo_pickupevalfunc(entity player, entity item)
{
	entity item_resource = NULL; // pointer to the resource that may be associated with the given item
	entity wpn = NULL;
	float c = 0;
	float rating = 0;

	// detect needed ammo
	if(item.itemdef.instanceOfWeaponPickup)
	{
		entity res = item.itemdef.m_weapon.ammo_type;
		entity ammo = (res != RES_NONE) ? GetAmmoItem(res) : NULL;
		if(!ammo)
			return 0;
		if(res != RES_NONE && GetResource(item, res))
			item_resource = res;

		wpn = item;
		rating = ammo.m_botvalue;
	}
	else
	{
		FOREACH(Weapons, it != WEP_Null, {
			if(!(STAT(WEAPONS, player) & (it.m_wepset)))
				continue;
			if(it.ammo_type == RES_NONE)
				continue;

			if(GetResource(item, it.ammo_type))
			{
				item_resource = it.ammo_type;
				break;
			}
		});
		rating = item.bot_pickupbasevalue;
	}

	float noammorating = 0.5;

	if(item_resource && (GetResource(player, item_resource) < GetResourceLimit(player, item_resource)))
		c = GetResource(item, item_resource) / max(noammorating, GetResource(player, item_resource));

	rating *= min(c, 2);
	if(wpn)
		rating += wpn.bot_pickupbasevalue * 0.1;
	return rating;
}

float healtharmor_pickupevalfunc(entity player, entity item)
{
	float c = 0;
	float rating = item.bot_pickupbasevalue;

	float itemarmor = GetResource(item, RES_ARMOR);
	float itemhealth = GetResource(item, RES_HEALTH);

	if(item.item_group)
	{
		itemarmor *= min(4, item.item_group_count);
		itemhealth *= min(4, item.item_group_count);
	}

	if (itemarmor && (GetResource(player, RES_ARMOR) < item.max_armorvalue))
		c = itemarmor / max(1, GetResource(player, RES_ARMOR) * 2/3 + GetResource(player, RES_HEALTH) * 1/3);

	if (itemhealth && (GetResource(player, RES_HEALTH) < item.max_health))
		c = itemhealth / max(1, GetResource(player, RES_HEALTH));

	rating *= min(2, c);
	return rating;
}

void Item_Damage(entity this, entity inflictor, entity attacker, float damage, int deathtype, .entity weaponentity, vector hitloc, vector force)
{
	if(ITEM_DAMAGE_NEEDKILL(deathtype))
		RemoveItem(this);
}

void item_use(entity this, entity actor, entity trigger)
{
	// use the touch function to handle collection
	gettouch(this)(this, actor);
}

void item_setactive(entity this, int act)
{
	int old_status = this.active;
	if(act == ACTIVE_TOGGLE)
		this.active = (this.active == ACTIVE_ACTIVE) ? ACTIVE_NOT : ACTIVE_ACTIVE;
	else
		this.active = act;

	if(this.active != old_status)
		Item_Show(this, ((this.active == ACTIVE_ACTIVE) ? 1 : -1));
}

void StartItem(entity this, entity def)
{
	if (def.m_spawnfunc_hookreplace)
		def = def.m_spawnfunc_hookreplace(def, this);
	this.itemdef = def;
	if (def.m_canonical_spawnfunc != "") // FIXME why do weapons set itemdef to an entity that doesn't have this?
		this.classname = def.m_canonical_spawnfunc;

	startitem_failed = true; // early return means failure

	// some mutators check for resources set by m_iteminit in FilterItem
	if(def.m_iteminit)
		def.m_iteminit(def, this);

	// also checked by some mutators in FilterItem
	this.items = def.m_itemid;
	this.weapon = def.instanceOfWeaponPickup ? def.m_weapon.m_id : 0;
	if(this.weapon)
		STAT(WEAPONS, this) = WepSet_FromWeapon(REGISTRY_GET(Weapons, this.weapon));
	this.flags = FL_ITEM | def.m_itemflags;

	// FilterItem may change any field of a specific instance of an item, but
	// it must not change any itemdef field (would cause mutators to break other mutators),
	// and must not convert items into different ones (StartItem could be refactored to support that).
	if(MUTATOR_CALLHOOK(FilterItem, this))
	{
		delete(this);
		return;
	}

	if (!this.item_model_ent)
		this.item_model_ent = def.m_model;

	if (!this.item_pickupsound_ent)
		this.item_pickupsound_ent = def.m_sound;
	if (!this.item_pickupsound && this.item_pickupsound_ent)
		this.item_pickupsound = Sound_fixpath(this.item_pickupsound_ent);
	if (this.item_pickupsound == "")
		LOG_WARNF("No pickup sound set for a %s", this.classname);

	if(!this.pickup_anyway && def.m_pickupanyway)
		this.pickup_anyway = def.m_pickupanyway;

	// bones_was_here TODO: implement sv_cullentities_dist and replace g_items_maxdist with it
	if(!this.fade_end)
		this.fade_end = autocvar_g_items_maxdist;

	// bones_was_here TODO: can we do this after we're sure the entity won't be deleted?
	IL_PUSH(g_items, this);

	this.mdl = this.model ? this.model : strzone(this.item_model_ent.model_str());
	setmodel(this, MDL_Null); // precision set below
	// set item size before we spawn a waypoint or droptofloor or MoveOutOfSolid
	setsize (this, this.pos1 = def.m_mins, this.pos2 = def.m_maxs);

	if (ITEM_IS_LOOT(this))
	{
		this.reset = RemoveItem;

		set_movetype(this, MOVETYPE_TOSS);
		this.gravity = 1;

		setthink(this, Item_Think);
		this.nextthink = time + IT_UPDATE_INTERVAL;
		this.wait = time + autocvar_g_items_dropped_lifetime;

		this.owner = NULL; // anyone can pick this up, including the player who threw it
		this.item_spawnshieldtime = time + 0.5; // but not straight away

		this.takedamage = DAMAGE_YES;
		this.event_damage = Item_Damage;
		// enable this to have thrown items burn in lava
		//this.damagedbycontents = true;
		//IL_PUSH(g_damagedbycontents, this);

		if (ITEM_IS_EXPIRING(this))
		{
			// if item is worthless after a timer, have it expire then
			this.nextthink = max(this.strength_finished, this.invincible_finished, this.superweapons_finished);
		}

		// most loot items have a bigger horizontal size than a player
		nudgeoutofsolid_OrFallback(this);

		// don't drop if in a NODROP zone (such as lava)
		traceline(this.origin, this.origin, MOVE_NORMAL, this);
		if (trace_dpstartcontents & DPCONTENTS_NODROP)
		{
			delete(this);
			return;
		}
	}
	else
	{
		// must be done after def.m_iteminit() as that may set ITEM_FLAG_MUTATORBLOCKED
		if(!have_pickup_item(this))
		{
			delete(this);
			return;
		}

		// must be done before Item_Reset() and after MUTATORBLOCKED check (blocked items may be uninitialised)
		if(!this.respawntime)
		{
			if (def.m_respawntime)
				this.respawntime = def.m_respawntime;
			else
				LOG_WARNF("Default respawntime for a %s is unavailable from its itemdef", this.classname);
		}

		this.reset = Item_Reset;

		if(this.angles != '0 0 0')
			this.SendFlags |= ISF_ANGLES;

		if(q3compat)
		{
			if (!this.team)
			{
				string t = GetField_fullspawndata(this, "team", false);
				// bones_was_here: this hack is cheaper than changing to a .string strcmp()
				if(t) this.team = crc16(false, t);
			}

			// In Q3 the origin is in the middle of the bbox ("radius" 15), in Xon it's at the bottom
			// so we need to offset vertically (only for items placed by the mapper).
			this.origin.z += -15 - this.mins.z;
			setorigin(this, this.origin);
		}

		// it's a level item
		if(this.spawnflags & 1)
			this.noalign = 1;
		if (this.noalign > 0)
			set_movetype(this, MOVETYPE_NONE);
		else
			set_movetype(this, MOVETYPE_TOSS);
		// do item filtering according to gametype and other things
		if (this.noalign <= 0)
		{
			if (!this.noalign)
				DropToFloor_QC_DelayedInit(this);
			waypoint_spawnforitem(this);
		}

		/*
		 * can't do it that way, as it would break maps
		 * TODO make a target_give like entity another way, that perhaps has
		 * the weapon name in a key
		if(this.targetname)
		{
			// target_give not yet supported; maybe later
			print("removed targeted ", this.classname, "\n");
			delete(this);
			return;
		}
		*/

		if(this.targetname != "" && (this.spawnflags & 16))
			this.use = item_use;

		this.setactive = item_setactive;
		this.active = ACTIVE_ACTIVE;

		if(autocvar_spawn_debug >= 2)
		{
			// why not flags & fl_item?
			FOREACH_ENTITY_RADIUS(this.origin, 3, it.is_item, {
				LOG_TRACE("XXX Found duplicated item: ", def.m_name, vtos(this.origin));
				LOG_TRACE(" vs ", it.netname, vtos(it.origin));
				error("Mapper sucks.");
			});
			this.is_item = true;
		}

		weaponsInMap |= WepSet_FromWeapon(REGISTRY_GET(Weapons, this.weapon));

		if (	    def.instanceOfPowerup
			||  def.instanceOfWeaponPickup
			|| (def.instanceOfHealth && def != ITEM_HealthSmall)
			|| (def.instanceOfArmor && def != ITEM_ArmorSmall)
			|| (def.m_itemid & (IT_KEY1 | IT_KEY2))
		)
		{
			if(!this.target || this.target == "")
				this.target = "###item###"; // for finding the nearest item using findnearest
		}

		Item_ItemsTime_SetTime(this, 0);

		this.glowmod = def.m_color;
	}

	this.bot_pickup = true;
	this.bot_pickupevalfunc = def.m_pickupevalfunc;
	this.bot_pickupbasevalue = def.m_botvalue;
	this.netname = def.m_name;
	settouch(this, Item_Touch);
	//this.effects |= EF_LOWPRECISION;

	// support skinned models for powerups
	if(!this.skin)
		this.skin = def.m_skin;

	if (!(this.spawnflags & 1024)) {
		if(def.instanceOfPowerup)
			this.ItemStatus |= ITS_ANIMATE1;

		if(GetResource(this, RES_ARMOR) || GetResource(this, RES_HEALTH))
			this.ItemStatus |= ITS_ANIMATE2;
	}

	if(def.instanceOfWeaponPickup)
	{
		if (!ITEM_IS_LOOT(this)) // if dropped, colormap is already set up nicely
			this.colormap = 1024; // color shirt=0 pants=0 grey
		if (!(this.spawnflags & 1024))
			this.ItemStatus |= ITS_ANIMATE1;
		this.SendFlags |= ISF_COLORMAP;
	}

	this.state = 0;
	if(this.team)
	{
		if(!this.cnt)
			this.cnt = 1; // item probability weight

		this.effects |= EF_NOGUNBOB; // marker for item team search
		InitializeEntity(this, Item_FindTeam, INITPRIO_FINDTARGET);
		this.reset = Item_FindTeam;
	}
	else
		Item_Reset(this);

	Net_LinkEntity(this, !(def.instanceOfPowerup || def.instanceOfHealth || def.instanceOfArmor), 0, ItemSend);

	// call this hook after everything else has been done
	if (MUTATOR_CALLHOOK(Item_Spawn, this))
	{
		delete(this);
		return;
	}

	// we should be sure this item will spawn before loading its assets
	// CSQC handles model precaching: it may not use this model (eg simple items) and may not have connected yet
	//precache_model(this.mdl);
	precache_sound(this.item_pickupsound);

	setItemGroup(this);

	startitem_failed = false;
}

#define IS_SMALL(def) ((def.instanceOfHealth && def == ITEM_HealthSmall) || (def.instanceOfArmor && def == ITEM_ArmorSmall))
int group_count = 1;

void setItemGroup(entity this)
{
	if(!IS_SMALL(this.itemdef) || ITEM_IS_LOOT(this))
		return;

	FOREACH_ENTITY_RADIUS(this.origin, 120, (it != this) && IS_SMALL(it.itemdef),
	{
		if(!this.item_group)
		{
			if(!it.item_group)
			{
				it.item_group = group_count;
				group_count++;
			}
			this.item_group = it.item_group;
		}
		else // spawning item is already part of a item_group X
		{
			if(!it.item_group)
				it.item_group = this.item_group;
			else if(it.item_group != this.item_group) // found an item near the spawning item that is part of a different item_group Y
			{
				int grY = it.item_group;
				// move all items of item_group Y to item_group X
				IL_EACH(g_items, IS_SMALL(it.itemdef),
				{
					if(it.item_group == grY)
						it.item_group = this.item_group;
				});
			}
		}
	});
}

void setItemGroupCount()
{
	for (int k = 1; k <= group_count; ++k)
	{
		int count = 0;
		IL_EACH(g_items, IS_SMALL(it.itemdef) && it.item_group == k, { count++; });
		if (count)
			IL_EACH(g_items, IS_SMALL(it.itemdef) && it.item_group == k, { it.item_group_count = count; });
	}
}

void target_items_use(entity this, entity actor, entity trigger)
{
	if(ITEM_IS_LOOT(actor))
	{
		EXACTTRIGGER_TOUCH(this, trigger);
		delete(actor);
		return;
	}

	if (!IS_PLAYER(actor) || IS_DEAD(actor))
		return;

	if(trigger.solid == SOLID_TRIGGER)
	{
		EXACTTRIGGER_TOUCH(this, trigger);
	}

	IL_EACH(g_items, it.enemy == actor && ITEM_IS_LOOT(it),
	{
		delete(it);
	});

	if(GiveItems(actor, 0, tokenize_console(this.netname)))
		centerprint(actor, this.message);
}

spawnfunc(target_items)
{
	this.use = target_items_use;
	if(!this.strength_finished)
		this.strength_finished = autocvar_g_balance_powerup_strength_time;
	if(!this.invincible_finished)
		this.invincible_finished = autocvar_g_balance_powerup_invincible_time;
	if(!this.speed_finished)
		this.speed_finished = autocvar_g_balance_powerup_speed_time;
	if(!this.invisibility_finished)
		this.invisibility_finished = autocvar_g_balance_powerup_invisibility_time;
	if(!this.superweapons_finished)
		this.superweapons_finished = autocvar_g_balance_superweapons_time;

	string str;
	int n = tokenize_console(this.netname);
	if(argv(0) == "give")
	{
		str = substring(this.netname, argv_start_index(1), argv_end_index(-1) - argv_start_index(1));
	}
	else
	{
		for(int j = 0; j < n; ++j)
		{
			// this is from a time when unlimited superweapons were handled together with ammo in some parts of the code
			if     (argv(j) == "unlimited_ammo")         this.items |= IT_UNLIMITED_AMMO | IT_UNLIMITED_SUPERWEAPONS;
			else if(argv(j) == "unlimited_weapon_ammo")  this.items |= IT_UNLIMITED_AMMO;
			else if(argv(j) == "unlimited_superweapons") this.items |= IT_UNLIMITED_SUPERWEAPONS;
			else if(argv(j) == "strength")               this.items |= ITEM_Strength.m_itemid;
			else if(argv(j) == "invincible")             this.items |= ITEM_Shield.m_itemid;
			else if(argv(j) == "speed")                  this.items |= ITEM_Speed.m_itemid;
			else if(argv(j) == "invisibility")           this.items |= ITEM_Invisibility.m_itemid;
			else if(argv(j) == "superweapons")           this.items |= IT_SUPERWEAPON;
			else if(argv(j) == "jetpack")                this.items |= ITEM_Jetpack.m_itemid;
			else if(argv(j) == "fuel_regen")             this.items |= ITEM_FuelRegen.m_itemid;
			else
			{
				FOREACH(StatusEffects, it.instanceOfBuff,
				{
					string s = Buff_CompatName(argv(j));
					if(s == it.netname)
					{
						this.buffdef = it;
						if(!this.buffs_finished)
							this.buffs_finished = it.m_time(it);
						break;
					}
				});
				FOREACH(Weapons, it != WEP_Null, {
					string s = argv(j);
					if(s == it.netname || s == it.m_deprecated_netname)
					{
						STAT(WEAPONS, this) |= (it.m_wepset);
						if(this.spawnflags == 0 || this.spawnflags == 2)
							it.wr_init(it);
						break;
					}
				});
			}
		}

		string itemprefix, valueprefix;
		if(this.spawnflags == 0)
		{
			itemprefix = "";
			valueprefix = "";
		}
		else if(this.spawnflags == 1)
		{
			itemprefix = "max ";
			valueprefix = "max ";
		}
		else if(this.spawnflags == 2)
		{
			itemprefix = "min ";
			valueprefix = "min ";
		}
		else if(this.spawnflags == 4)
		{
			itemprefix = "minus ";
			valueprefix = "max ";
		}
		else
		{
			error("invalid spawnflags");
			itemprefix = valueprefix = string_null;
		}

		str = "";
		str = sprintf("%s %s%d %s", str, itemprefix, boolean(this.items & IT_UNLIMITED_AMMO), "unlimited_weapon_ammo");
		str = sprintf("%s %s%d %s", str, itemprefix, boolean(this.items & IT_UNLIMITED_SUPERWEAPONS), "unlimited_superweapons");
		str = sprintf("%s %s%d %s", str, valueprefix, this.strength_finished * boolean(this.items & ITEM_Strength.m_itemid), "strength");
		str = sprintf("%s %s%d %s", str, valueprefix, this.invincible_finished * boolean(this.items & ITEM_Shield.m_itemid), "invincible");
		str = sprintf("%s %s%d %s", str, valueprefix, this.invisibility_finished * boolean(this.items & ITEM_Invisibility.m_itemid), "invisibility");
		str = sprintf("%s %s%d %s", str, valueprefix, this.speed_finished * boolean(this.items & ITEM_Speed.m_itemid), "speed");
		str = sprintf("%s %s%d %s", str, valueprefix, this.superweapons_finished * boolean(this.items & IT_SUPERWEAPON), "superweapons");
		str = sprintf("%s %s%d %s", str, itemprefix, boolean(this.items & ITEM_Jetpack.m_itemid), "jetpack");
		str = sprintf("%s %s%d %s", str, itemprefix, boolean(this.items & ITEM_FuelRegen.m_itemid), "fuel_regen");
		float res;
		res = GetResource(this, RES_SHELLS);  if(res != 0) str = sprintf("%s %s%d %s", str, valueprefix, max(0, res), "shells");
		res = GetResource(this, RES_BULLETS); if(res != 0) str = sprintf("%s %s%d %s", str, valueprefix, max(0, res), "nails");
		res = GetResource(this, RES_ROCKETS); if(res != 0) str = sprintf("%s %s%d %s", str, valueprefix, max(0, res), "rockets");
		res = GetResource(this, RES_CELLS);   if(res != 0) str = sprintf("%s %s%d %s", str, valueprefix, max(0, res), "cells");
		res = GetResource(this, RES_FUEL);    if(res != 0) str = sprintf("%s %s%d %s", str, valueprefix, max(0, res), "fuel");
		res = GetResource(this, RES_HEALTH);  if(res != 0) str = sprintf("%s %s%d %s", str, valueprefix, max(0, res), "health");
		res = GetResource(this, RES_ARMOR);   if(res != 0) str = sprintf("%s %s%d %s", str, valueprefix, max(0, res), "armor");
		FOREACH(StatusEffects, it.instanceOfBuff, str = sprintf("%s %s%d %s", str, valueprefix, this.buffs_finished * boolean(this.buffdef == it), it.netname));
		FOREACH(Weapons, it != WEP_Null, str = sprintf("%s %s%d %s", str, itemprefix, !!(STAT(WEAPONS, this) & (it.m_wepset)), it.netname));
	}
	this.netname = strzone(str);

	n = tokenize_console(this.netname);
	for(int j = 0; j < n; ++j)
	{
		string cmd = argv(j);
		FOREACH(Weapons, it != WEP_Null && (cmd == it.netname || cmd == it.m_deprecated_netname), {
			it.wr_init(it);
			break;
		});
	}
}

float GiveWeapon(entity e, float wpn, float op, float val)
{
	WepSet v0, v1;
	WepSet s = WepSet_FromWeapon(REGISTRY_GET(Weapons, wpn));
	v0 = (STAT(WEAPONS, e) & s);
	switch(op)
	{
		case OP_SET:
			if(val > 0)
				STAT(WEAPONS, e) |= s;
			else
				STAT(WEAPONS, e) &= ~s;
			break;
		case OP_MIN:
		case OP_PLUS:
			if(val > 0)
				STAT(WEAPONS, e) |= s;
			break;
		case OP_MAX:
			if(val <= 0)
				STAT(WEAPONS, e) &= ~s;
			break;
		case OP_MINUS:
			if(val > 0)
				STAT(WEAPONS, e) &= ~s;
			break;
	}
	v1 = (STAT(WEAPONS, e) & s);
	return (v0 != v1);
}

bool GiveBuff(entity e, Buff thebuff, int op, int val)
{
	bool had_buff = StatusEffects_active(thebuff, e);
	float new_buff_time = ((had_buff) ? StatusEffects_gettime(thebuff, e) : time);
	switch (op)
	{
		case OP_SET:
			new_buff_time = time + val;
			break;
		case OP_MIN:
			new_buff_time = max(new_buff_time, time + val);
			break;
		case OP_MAX:
			new_buff_time = min(new_buff_time, time + val);
			break;
		case OP_PLUS:
			new_buff_time += val;
			break;
		case OP_MINUS:
			new_buff_time -= val;
			break;
	}
	if(new_buff_time <= time)
	{
		if(had_buff) // only trigger removal mechanics if there is an effect to remove!
			StatusEffects_remove(thebuff, e, STATUSEFFECT_REMOVE_NORMAL);
	}
	else
	{
		buff_RemoveAll(e, STATUSEFFECT_REMOVE_CLEAR); // clear old buffs on the player first!
		StatusEffects_apply(thebuff, e, new_buff_time, 0);
	}
	bool have_buff = StatusEffects_active(thebuff, e);
	return (had_buff != have_buff);
}

void GiveSound(entity e, float v0, float v1, float t, Sound snd_incr, Sound snd_decr)
{
	if(v1 == v0)
		return;
	if(v1 <= v0 - t)
	{
		if(snd_decr != NULL)
			sound(e, CH_TRIGGER, snd_decr, VOL_BASE, ATTEN_NORM);
	}
	else if(v0 >= v0 + t)
	{
		if(snd_incr != NULL)
			sound(e, ((snd_incr == SND_POWERUP) ? CH_TRIGGER_SINGLE : CH_TRIGGER), snd_incr, VOL_BASE, ATTEN_NORM);
	}
}

void GiveRot(entity e, float v0, float v1, .float rotfield, float rottime, .float regenfield, float regentime)
{
	if(v0 < v1)
		e.(rotfield) = max(e.(rotfield), time + rottime);
	else if(v0 > v1)
		e.(regenfield) = max(e.(regenfield), time + regentime);
}
bool GiveResourceValue(entity e, Resource res_type, int op, int val)
{
	int v0 = GetResource(e, res_type);
	float new_val = 0;
	switch (op)
	{
		// min 100 cells = at least 100 cells
		case OP_SET: new_val = val; break;
		case OP_MIN: new_val = max(v0, val); break;
		case OP_MAX: new_val = min(v0, val); break;
		case OP_PLUS: new_val = v0 + val; break;
		case OP_MINUS: new_val = v0 - val; break;
		default: return false;
	}

	return SetResourceExplicit(e, res_type, new_val);
}
bool GiveStatusEffect(entity e, StatusEffect this, int op, float val)
{
	bool had_eff = StatusEffects_active(this, e);
	float new_eff_time = ((had_eff) ? StatusEffects_gettime(this, e) : time);
	switch (op)
	{
		case OP_SET:
			new_eff_time = time + val;
			break;
		case OP_MIN:
			new_eff_time = max(new_eff_time, time + val);
			break;
		case OP_MAX:
			new_eff_time = min(new_eff_time, time + val);
			break;
		case OP_PLUS:
			new_eff_time += val;
			break;
		case OP_MINUS:
			new_eff_time -= val;
			break;
	}
	if(new_eff_time <= time)
	{
		if(had_eff) // only trigger removal mechanics if there is an effect to remove!
			StatusEffects_remove(this, e, STATUSEFFECT_REMOVE_NORMAL);
	}
	else
		StatusEffects_apply(this, e, new_eff_time, 0);
	bool have_eff = StatusEffects_active(this, e);
	return (had_eff != have_eff);
}

float GiveItems(entity e, float beginarg, float endarg)
{
	float got, i, val, op;
	string cmd;

	val = 999;
	op = OP_SET;

	got = 0;

	int _switchweapon = 0;

	bool use_cts_autoswitch = (g_cts && (CS_CVAR(e).cvar_cl_autoswitch_cts != -1));
	if(CS_CVAR(e).cvar_cl_autoswitch && !use_cts_autoswitch)
	{
		for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
		{
			.entity weaponentity = weaponentities[slot];
			if(e.(weaponentity).m_weapon != WEP_Null || slot == 0)
			if(e.(weaponentity).m_switchweapon == w_getbestweapon(e, weaponentity))
				_switchweapon |= BIT(slot);
		}
	}

	PREGIVE(e, items);
	PREGIVE_WEAPONS(e);
	PREGIVE_STATUSEFFECT(e, STATUSEFFECT_Strength);
	PREGIVE_STATUSEFFECT(e, STATUSEFFECT_Shield);
	PREGIVE_STATUSEFFECT(e, STATUSEFFECT_Speed);
	PREGIVE_STATUSEFFECT(e, STATUSEFFECT_Invisibility);
	//PREGIVE_STATUSEFFECT(e, STATUSEFFECT_Superweapon);
	PREGIVE_RESOURCE(e, RES_BULLETS);
	PREGIVE_RESOURCE(e, RES_CELLS);
	PREGIVE_RESOURCE(e, RES_SHELLS);
	PREGIVE_RESOURCE(e, RES_ROCKETS);
	PREGIVE_RESOURCE(e, RES_FUEL);
	PREGIVE_RESOURCE(e, RES_ARMOR);
	PREGIVE_RESOURCE(e, RES_HEALTH);

	Weapon last_wep = WEP_Null;
	for(i = beginarg; i < endarg; ++i)
	{
		cmd = argv(i);

		if(cmd == "0" || stof(cmd))
		{
			val = stof(cmd);
			continue;
		}
		switch(cmd)
		{
			case "no":
				op = OP_MAX;
				val = 0;
				continue;
			case "max":
				op = OP_MAX;
				continue;
			case "min":
				op = OP_MIN;
				continue;
			case "plus":
				op = OP_PLUS;
				continue;
			case "minus":
				op = OP_MINUS;
				continue;
			case "ALL":
				got += GiveBit(e, items, ITEM_FuelRegen.m_itemid, op, val);
				FOREACH(StatusEffects, it.instanceOfPowerupStatusEffect, got += GiveStatusEffect(e, it, op, val));
				got += GiveBit(e, items, IT_UNLIMITED_AMMO | IT_UNLIMITED_SUPERWEAPONS, op, val);
			case "all":
				got += GiveBit(e, items, ITEM_Jetpack.m_itemid, op, val);
				got += GiveResourceValue(e, RES_HEALTH, op, val);
				got += GiveResourceValue(e, RES_ARMOR, op, val);
			case "allweapons":
				FOREACH(Weapons, it != WEP_Null && !(it.spawnflags & (WEP_FLAG_MUTATORBLOCKED | WEP_FLAG_HIDDEN)),
					got += GiveWeapon(e, it.m_id, op, val));
			//case "allbuffs": // all buffs makes a player god, do not want!
				//FOREACH(StatusEffects, it.instanceOfBuff, got += GiveBuff(e, it, op, val));
			case "allammo":
				got += GiveResourceValue(e, RES_CELLS, op, val);
				got += GiveResourceValue(e, RES_SHELLS, op, val);
				got += GiveResourceValue(e, RES_BULLETS, op, val);
				got += GiveResourceValue(e, RES_ROCKETS, op, val);
				got += GiveResourceValue(e, RES_FUEL, op, val);
				break;
			case "unlimited_ammo":
				// this is from a time when unlimited superweapons were handled together with ammo in some parts of the code
				got += GiveBit(e, items, IT_UNLIMITED_AMMO | IT_UNLIMITED_SUPERWEAPONS, op, val);
				break;
			case "unlimited_weapon_ammo":
				got += GiveBit(e, items, IT_UNLIMITED_AMMO, op, val);
				break;
			case "unlimited_superweapons":
				got += GiveBit(e, items, IT_UNLIMITED_SUPERWEAPONS, op, val);
				break;
			case "jetpack":
				got += GiveBit(e, items, ITEM_Jetpack.m_itemid, op, val);
				break;
			case "fuel_regen":
				got += GiveBit(e, items, ITEM_FuelRegen.m_itemid, op, val);
				break;
			case "strength":
				got += GiveStatusEffect(e, STATUSEFFECT_Strength, op, val);
				break;
			case "invincible":
			case "shield":
				got += GiveStatusEffect(e, STATUSEFFECT_Shield, op, val);
				break;
			case "speed":
				got += GiveStatusEffect(e, STATUSEFFECT_Speed, op, val);
				break;
			case "invisibility":
				got += GiveStatusEffect(e, STATUSEFFECT_Invisibility, op, val);
				break;
			case "superweapons":
				got += GiveStatusEffect(e, STATUSEFFECT_Superweapon, op, val);
				break;
			case "cells":
				got += GiveResourceValue(e, RES_CELLS, op, val);
				break;
			case "shells":
				got += GiveResourceValue(e, RES_SHELLS, op, val);
				break;
			case "nails":
			case "bullets":
				got += GiveResourceValue(e, RES_BULLETS, op, val);
				break;
			case "rockets":
				got += GiveResourceValue(e, RES_ROCKETS, op, val);
				break;
			case "health":
				got += GiveResourceValue(e, RES_HEALTH, op, val);
				break;
			case "armor":
				got += GiveResourceValue(e, RES_ARMOR, op, val);
				break;
			case "fuel":
				got += GiveResourceValue(e, RES_FUEL, op, val);
				break;
			default:
				FOREACH(StatusEffects, it.instanceOfBuff && buff_Available(it) && Buff_CompatName(cmd) == it.netname,
				{
					got += GiveBuff(e, it, op, val);
					break;
				});
				FOREACH(Weapons, it != WEP_Null && (cmd == it.netname || cmd == it.m_deprecated_netname), {
					got += GiveWeapon(e, it.m_id, op, val);
					if(use_cts_autoswitch && CS_CVAR(e).cvar_cl_autoswitch_cts == 1)
					if(val > 0 && (op == OP_SET || op == OP_PLUS || op == OP_MIN)) // switch to any given weapons, even if we already had it
						last_wep = it; // (... non-CTS autoswitching can switch to a weapon we already have, so CTS autoswitch should be the same)
					break;
				});
				break;
		}
		val = 999;
		op = OP_SET;
	}

	POSTGIVE_BIT(e, items, ITEM_FuelRegen.m_itemid, SND_ITEMPICKUP, SND_Null);
	POSTGIVE_BIT(e, items, IT_UNLIMITED_SUPERWEAPONS, SND_POWERUP, SND_POWEROFF);
	POSTGIVE_BIT(e, items, IT_UNLIMITED_AMMO, SND_POWERUP, SND_POWEROFF);
	POSTGIVE_BIT(e, items, ITEM_Jetpack.m_itemid, SND_ITEMPICKUP, SND_Null);
	FOREACH(Weapons, it != WEP_Null, {
		POSTGIVE_WEAPON(e, it, SND_WEAPONPICKUP, SND_Null);
		if(!(save_weapons & (it.m_wepset)))
			if(STAT(WEAPONS, e) & (it.m_wepset))
				it.wr_init(it);
	});
	POSTGIVE_STATUSEFFECT(e, STATUSEFFECT_Strength, SND_POWERUP, SND_POWEROFF);
	POSTGIVE_STATUSEFFECT(e, STATUSEFFECT_Shield, SND_POWERUP, SND_POWEROFF);
	POSTGIVE_STATUSEFFECT(e, STATUSEFFECT_Speed, SND_POWERUP, SND_POWEROFF);
	POSTGIVE_STATUSEFFECT(e, STATUSEFFECT_Invisibility, SND_POWERUP, SND_POWEROFF);
	POSTGIVE_RESOURCE(e, RES_BULLETS, 0, SND_ITEMPICKUP, SND_Null);
	POSTGIVE_RESOURCE(e, RES_CELLS, 0, SND_ITEMPICKUP, SND_Null);
	POSTGIVE_RESOURCE(e, RES_SHELLS, 0, SND_ITEMPICKUP, SND_Null);
	POSTGIVE_RESOURCE(e, RES_ROCKETS, 0, SND_ITEMPICKUP, SND_Null);
	POSTGIVE_RES_ROT(e, RES_FUEL, 1, pauserotfuel_finished, autocvar_g_balance_pause_fuel_rot, pauseregen_finished, autocvar_g_balance_pause_fuel_regen, SND_ITEMPICKUP, SND_Null);
	POSTGIVE_RES_ROT(e, RES_ARMOR, 1, pauserotarmor_finished, autocvar_g_balance_pause_armor_rot, pauseregen_finished, autocvar_g_balance_pause_health_regen, SND_ARMOR25, SND_Null);
	POSTGIVE_RES_ROT(e, RES_HEALTH, 1, pauserothealth_finished, autocvar_g_balance_pause_health_rot, pauseregen_finished, autocvar_g_balance_pause_health_regen, SND_MEGAHEALTH, SND_Null);

	if(!StatusEffects_active(STATUSEFFECT_Superweapon, e))
	{
		// also give default superweapon time if player had no superweapons and just got one
		if(!g_weaponarena && !(save_weapons & WEPSET_SUPERWEAPONS) && (STAT(WEAPONS, e) & WEPSET_SUPERWEAPONS))
			StatusEffects_apply(STATUSEFFECT_Superweapon, e, time + autocvar_g_balance_superweapons_time, 0);
	}

	if(e.statuseffects)
		StatusEffects_update(e);

	if(use_cts_autoswitch)
	{
		// CTS handling: never switch (0), always switch (1)
		if(last_wep != WEP_Null)
		if(CS_CVAR(e).cvar_cl_autoswitch_cts == 1)
		{
			// crude hack to enforce switching weapons
			for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
			{
				.entity weaponentity = weaponentities[slot];
				if(e.(weaponentity).m_weapon != WEP_Null || slot == 0)
				if(client_hasweapon(e, last_wep, weaponentity, true, false)) // ammo check
					W_SwitchWeapon_Force(e, last_wep, weaponentity);
			}
		}
	}
	else
	{
		// non-CTS handling: weaponpriority-based autoswitch
		for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
		{
			.entity weaponentity = weaponentities[slot];
			if(e.(weaponentity).m_weapon != WEP_Null || slot == 0)
			if(!(STAT(WEAPONS, e) & WepSet_FromWeapon(e.(weaponentity).m_switchweapon)))
				_switchweapon |= BIT(slot);

			if(_switchweapon & BIT(slot))
			{
				Weapon best_wep = w_getbestweapon(e, weaponentity);
				if(e.(weaponentity).m_switchweapon != best_wep)
					W_SwitchWeapon_Force(e, best_wep, weaponentity);
			}
		}
	}

	return got;
}
