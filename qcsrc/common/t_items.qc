#include "t_items.qh"

#include "items/_mod.qh"

#if defined(SVQC)

    #include "../server/bot/api.qh"

    #include <server/mutators/_mod.qh>

    #include "../server/weapons/common.qh"
    #include "../server/weapons/selection.qh"
    #include "../server/weapons/weaponsystem.qh"

    #include "constants.qh"
    #include <common/deathtypes/all.qh>
    #include <common/notifications/all.qh>
	#include "triggers/subs.qh"
    #include "util.qh"

    #include <common/monsters/_mod.qh>

    #include <common/weapons/_all.qh>

    #include <common/mutators/mutator/buffs/buffs.qh>

    #include "../lib/warpzone/util_server.qh"
#elif defined(CSQC)
	#include "physics/movetypes/movetypes.qh"
	#include <common/weapons/_all.qh>
	#include "../lib/csqcmodel/cl_model.qh"
	#include "../lib/csqcmodel/common.qh"
#endif

REGISTER_NET_LINKED(ENT_CLIENT_ITEM)

#ifdef CSQC
bool autocvar_cl_ghost_items_vehicle = true;
.vector item_glowmod;
void Item_SetAlpha(entity this)
{
	bool veh_hud = (hud && autocvar_cl_ghost_items_vehicle);

	if(!veh_hud && (this.ItemStatus & ITS_AVAILABLE))
	{
		this.alpha = 1;
		this.colormod = '1 1 1';
		this.glowmod = this.item_glowmod;
	}
	else
	{
		if (autocvar_cl_ghost_items_color)
		{
			this.alpha = autocvar_cl_ghost_items;
			this.colormod = this.glowmod = autocvar_cl_ghost_items_color;
		}
		else
			this.alpha = -1;
	}

	if(!veh_hud)
	if(this.ItemStatus & ITS_STAYWEP)
	{
		this.colormod = this.glowmod = autocvar_cl_weapon_stay_color;
		this.alpha = autocvar_cl_weapon_stay_alpha;
	}
}

void ItemDraw(entity this)
{
    if(this.gravity)
    {
        Movetype_Physics_MatchServer(this, false);
        if(IS_ONGROUND(this))
        { // For some reason avelocity gets set to '0 0 0' here ...
            this.oldorigin = this.origin;
            this.gravity = 0;

            if(autocvar_cl_animate_items)
            { // ... so reset it if animations are requested.
                if(this.ItemStatus & ITS_ANIMATE1)
                    this.avelocity = '0 180 0';

                if(this.ItemStatus & ITS_ANIMATE2)
                    this.avelocity = '0 -90 0';
            }

            // delay is for blocking item's position for a while;
            // it's a workaround for dropped weapons that receive the position
            // another time right after they spawn overriding animation position
            this.onground_time = time + 0.5;
        }
    }
    else if (autocvar_cl_animate_items)
    {
        if(this.ItemStatus & ITS_ANIMATE1)
        {
            this.angles += this.avelocity * frametime;
            float fade_in = bound(0, time - this.onground_time, 1);
            setorigin(this, this.oldorigin + fade_in * ('0 0 10' + '0 0 8' * sin((time - this.onground_time) * 2)));
        }

        if(this.ItemStatus & ITS_ANIMATE2)
        {
            this.angles += this.avelocity * frametime;
            float fade_in = bound(0, time - this.onground_time, 1);
            setorigin(this, this.oldorigin + fade_in * ('0 0 8' + '0 0 4' * sin((time - this.onground_time) * 3)));
        }
    }

    Item_SetAlpha(this);
}

void ItemDrawSimple(entity this)
{
    if(this.gravity)
    {
        Movetype_Physics_MatchServer(this, false);

        if(IS_ONGROUND(this))
            this.gravity = 0;
    }

    Item_SetAlpha(this);
}

void Item_PreDraw(entity this)
{
	if(warpzone_warpzones_exist)
	{
		// just incase warpzones were initialized last, reset these
		//this.alpha = 1; // alpha is already set by the draw function
		this.drawmask = MASK_NORMAL;
		return;
	}
	float alph;
	vector org = getpropertyvec(VF_ORIGIN);
	if(!checkpvs(org, this)) // this makes sense as long as we don't support recursive warpzones
		alph = 0;
	else if(this.fade_start)
		alph = bound(0, (this.fade_end - vlen(org - this.origin - 0.5 * (this.mins + this.maxs))) / (this.fade_end - this.fade_start), 1);
	else
		alph = 1;
	//printf("%v <-> %v\n", view_origin, this.origin + 0.5 * (this.mins + this.maxs));
	if(!hud && (this.ItemStatus & ITS_AVAILABLE))
		this.alpha = alph;
	if(alph <= 0)
		this.drawmask = 0;
	else
		this.drawmask = MASK_NORMAL;
}

void ItemRemove(entity this)
{
	if(this.mdl)
		strunzone(this.mdl);
}

NET_HANDLE(ENT_CLIENT_ITEM, bool isnew)
{
    int sf = ReadByte();

    if(sf & ISF_LOCATION)
    {
        this.origin_x = ReadCoord();
        this.origin_y = ReadCoord();
        this.origin_z = ReadCoord();
        setorigin(this, this.origin);
        this.oldorigin = this.origin;
    }

    if(sf & ISF_ANGLES)
    {
        this.angles_x = ReadAngle();
        this.angles_y = ReadAngle();
        this.angles_z = ReadAngle();
    }

    if(sf & ISF_SIZE)
    {
        float use_bigsize = ReadByte();
        setsize(this, '-16 -16 0', (use_bigsize) ? '16 16 48' : '16 16 32');
    }

    if(sf & ISF_STATUS) // need to read/write status frist so model can handle simple, fb etc.
    {
        this.ItemStatus = ReadByte();

        Item_SetAlpha(this);

        if(autocvar_cl_fullbright_items)
            if(this.ItemStatus & ITS_ALLOWFB)
                this.effects |= EF_FULLBRIGHT;

        if(this.ItemStatus & ITS_GLOW)
        {
            if(this.ItemStatus & ITS_AVAILABLE)
                this.effects |= (EF_ADDITIVE | EF_FULLBRIGHT);
            else
                 this.effects &= ~(EF_ADDITIVE | EF_FULLBRIGHT);
        }
    }

    if(sf & ISF_MODEL)
    {
        this.drawmask  = MASK_NORMAL;
		set_movetype(this, MOVETYPE_TOSS);
		if (isnew) IL_PUSH(g_drawables, this);
        this.draw       = ItemDraw;
        this.solid = SOLID_TRIGGER;
        //this.flags |= FL_ITEM;

        bool use_bigsize = ReadByte();

        this.fade_end = ReadShort();
        this.fade_start = ReadShort();
        if(this.fade_start && !autocvar_cl_items_nofade)
        	setpredraw(this, Item_PreDraw);

        if(this.mdl)
            strunzone(this.mdl);

        this.mdl = "";
        string _fn = ReadString();

        if(autocvar_cl_simple_items && (this.ItemStatus & ITS_ALLOWSI))
        {
            string _fn2 = substring(_fn, 0 , strlen(_fn) -4);
            this.draw = ItemDrawSimple;

            if(fexists(sprintf("%s%s.md3", _fn2, autocvar_cl_simpleitems_postfix)))
                this.mdl = strzone(sprintf("%s%s.md3", _fn2, autocvar_cl_simpleitems_postfix));
            else if(fexists(sprintf("%s%s.dpm", _fn2, autocvar_cl_simpleitems_postfix)))
                this.mdl = strzone(sprintf("%s%s.dpm", _fn2, autocvar_cl_simpleitems_postfix));
            else if(fexists(sprintf("%s%s.iqm", _fn2, autocvar_cl_simpleitems_postfix)))
                this.mdl = strzone(sprintf("%s%s.iqm", _fn2, autocvar_cl_simpleitems_postfix));
            else if(fexists(sprintf("%s%s.mdl", _fn2, autocvar_cl_simpleitems_postfix)))
                this.mdl = strzone(sprintf("%s%s.mdl", _fn2, autocvar_cl_simpleitems_postfix));
            else
            {
                this.draw = ItemDraw;
                LOG_TRACE("Simple item requested for ", _fn, " but no model exists for it");
            }
        }

        if(this.draw != ItemDrawSimple)
            this.mdl = strzone(_fn);


        if(this.mdl == "")
            LOG_TRACE("^1WARNING!^7 this.mdl is unset for item ", this.classname, ", tell tZork about this!");

        precache_model(this.mdl);
        _setmodel(this, this.mdl);

        setsize(this, '-16 -16 0', (use_bigsize) ? '16 16 48' : '16 16 32');
    }

    if(sf & ISF_COLORMAP)
    {
        this.colormap = ReadShort();
        this.item_glowmod_x = ReadByte() / 255.0;
        this.item_glowmod_y = ReadByte() / 255.0;
        this.item_glowmod_z = ReadByte() / 255.0;
    }

    if(sf & ISF_DROP)
    {
        this.gravity = 1;
        this.pushable = true;
        //this.angles = '0 0 0';
        set_movetype(this, MOVETYPE_TOSS);
        this.velocity_x = ReadCoord();
        this.velocity_y = ReadCoord();
        this.velocity_z = ReadCoord();
        setorigin(this, this.oldorigin);

        if(!this.move_time)
        {
            this.move_time = time;
            this.spawntime = time;
        }
        else
            this.move_time = max(this.move_time, time);
    }

    if(autocvar_cl_animate_items)
    {
        if(this.ItemStatus & ITS_ANIMATE1)
            this.avelocity = '0 180 0';

        if(this.ItemStatus & ITS_ANIMATE2)
            this.avelocity = '0 -90 0';
    }

    this.entremove = ItemRemove;

    return true;
}

#endif

#ifdef SVQC
bool ItemSend(entity this, entity to, int sf)
{
	if(this.gravity)
		sf |= ISF_DROP;
	else
		sf &= ~ISF_DROP;

	WriteHeader(MSG_ENTITY, ENT_CLIENT_ITEM);
	WriteByte(MSG_ENTITY, sf);

	//WriteByte(MSG_ENTITY, this.cnt);
	if(sf & ISF_LOCATION)
	{
		WriteCoord(MSG_ENTITY, this.origin.x);
		WriteCoord(MSG_ENTITY, this.origin.y);
		WriteCoord(MSG_ENTITY, this.origin.z);
	}

	if(sf & ISF_ANGLES)
	{
		WriteAngle(MSG_ENTITY, this.angles_x);
		WriteAngle(MSG_ENTITY, this.angles_y);
		WriteAngle(MSG_ENTITY, this.angles_z);
	}

	if(sf & ISF_SIZE)
	{
		Pickup p = this.itemdef;
		WriteByte(MSG_ENTITY, p.instanceOfPowerup || p.instanceOfHealth || p.instanceOfArmor);
	}

	if(sf & ISF_STATUS)
		WriteByte(MSG_ENTITY, this.ItemStatus);

	if(sf & ISF_MODEL)
	{
		Pickup p = this.itemdef;
		WriteByte(MSG_ENTITY, p.instanceOfPowerup || p.instanceOfHealth || p.instanceOfArmor);
		WriteShort(MSG_ENTITY, this.fade_end);
		WriteShort(MSG_ENTITY, this.fade_start);

		if(this.mdl == "")
			LOG_TRACE("^1WARNING!^7 this.mdl is unset for item ", this.classname, "expect a crash just about now");

		WriteString(MSG_ENTITY, this.mdl);
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
		WriteCoord(MSG_ENTITY, this.velocity.x);
		WriteCoord(MSG_ENTITY, this.velocity.y);
		WriteCoord(MSG_ENTITY, this.velocity.z);
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
	if(this.itemdef.instanceOfPowerup)
	{
		if(autocvar_g_powerups > 0)
			return true;
		if(autocvar_g_powerups == 0)
			return false;
	}
	else
	{
		if(autocvar_g_pickup_items > 0)
			return true;
		if(autocvar_g_pickup_items == 0)
			return false;
		if(g_weaponarena)
			if(this.weapons || this.itemdef.instanceOfAmmo) // no item or ammo pickups in weaponarena
				return false;
	}
	return true;
}

/*
float Item_Customize()
{
	if(this.spawnshieldtime)
		return true;
	if(this.weapons & ~other.weapons)
	{
		this.colormod = '0 0 0';
		this.glowmod = this.colormod;
		this.alpha = 0.5 + 0.5 * g_ghost_items; // halfway more alpha
		return true;
	}
	else
	{
		if(g_ghost_items)
		{
			this.colormod = stov(autocvar_g_ghost_items_color);
			this.glowmod = this.colormod;
			this.alpha = g_ghost_items;
			return true;
		}
		else
			return false;
	}
}
*/

void Item_Show (entity e, float mode)
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
	else {
	bool nostay = def.instanceOfWeaponPickup ? !!(def.m_weapon.weapons & WEPSET_SUPERWEAPONS) : false // no weapon-stay on superweapons
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
		//setmodel(e, "null");
		e.solid = SOLID_NOT;
		e.colormod = '0 0 0';
		//e.glowmod = e.colormod;
		e.spawnshieldtime = 1;
		e.ItemStatus &= ~ITS_AVAILABLE;
	}}

	if (def.m_glow)
		e.ItemStatus |= ITS_GLOW;

	if (autocvar_g_nodepthtestitems)
		e.effects |= EF_NODEPTHTEST;


	if (autocvar_g_fullbrightitems)
		e.ItemStatus |= ITS_ALLOWFB;

	if (autocvar_sv_simple_items)
		e.ItemStatus |= ITS_ALLOWSI;

	// relink entity (because solid may have changed)
	setorigin(e, e.origin);
	e.SendFlags |= ISF_STATUS;
}

void Item_Think(entity this)
{
	this.nextthink = time;
	if(this.origin != this.oldorigin)
		ItemUpdate(this);
}

bool Item_ItemsTime_SpectatorOnly(GameItem it);
bool Item_ItemsTime_Allow(GameItem it);
float Item_ItemsTime_UpdateTime(entity e, float t);
void Item_ItemsTime_SetTime(entity e, float t);
void Item_ItemsTime_SetTimesForAllPlayers();

void Item_Respawn (entity this)
{
	Item_Show(this, 1);
	sound(this, CH_TRIGGER, this.itemdef.m_respawnsound, VOL_BASE, ATTEN_NORM);	// play respawn sound
	setorigin(this, this.origin);

    if (Item_ItemsTime_Allow(this.itemdef) || (this.weapons & WEPSET_SUPERWEAPONS))
	{
		float t = Item_ItemsTime_UpdateTime(this, 0);
		Item_ItemsTime_SetTime(this, t);
		Item_ItemsTime_SetTimesForAllPlayers();
	}

	setthink(this, Item_Think);
	this.nextthink = time;

	//Send_Effect(EFFECT_ITEM_RESPAWN, this.origin + this.mins_z * '0 0 1' + '0 0 48', '0 0 0', 1);
	Send_Effect(EFFECT_ITEM_RESPAWN, CENTER_OR_VIEWOFS(this), '0 0 0', 1);
}

void Item_RespawnCountdown (entity this)
{
	if(this.count >= ITEM_RESPAWN_TICKS)
	{
		if(this.waypointsprite_attached)
			WaypointSprite_Kill(this.waypointsprite_attached);
		Item_Respawn(this);
	}
	else
	{
		this.nextthink = time + 1;
		this.count += 1;
		if(this.count == 1)
		{
			do {
				{
					entity wi = Weapons_from(this.weapon);
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
					soundto(MSG_ONE, this, CH_TRIGGER, SND(ITEMRESPAWNCOUNTDOWN), VOL_BASE, ATTEN_NORM);	// play respawn sound
				}
			});

			WaypointSprite_Ping(this.waypointsprite_attached);
			//WaypointSprite_UpdateHealth(this.waypointsprite_attached, this.count);
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
	if ((Item_ItemsTime_Allow(e.itemdef) || (e.weapons & WEPSET_SUPERWEAPONS) || MUTATOR_CALLHOOK(Item_ScheduleRespawn, e, t)) && (t - ITEM_RESPAWN_TICKS) > 0)
	{
		setthink(e, Item_RespawnCountdown);
		e.nextthink = time + max(0, t - ITEM_RESPAWN_TICKS);
		e.scheduledrespawntime = e.nextthink + ITEM_RESPAWN_TICKS;
		e.count = 0;
		if(Item_ItemsTime_Allow(e.itemdef) || (e.weapons & WEPSET_SUPERWEAPONS))
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

		if(Item_ItemsTime_Allow(e.itemdef) || (e.weapons & WEPSET_SUPERWEAPONS))
		{
			t = Item_ItemsTime_UpdateTime(e, e.scheduledrespawntime);
			Item_ItemsTime_SetTime(e, t);
			Item_ItemsTime_SetTimesForAllPlayers();
		}
	}
}

void Item_ScheduleRespawn(entity e)
{
	if(e.respawntime > 0)
	{
		Item_Show(e, 0);
		Item_ScheduleRespawnIn(e, ITEM_RESPAWNTIME(e));
	}
	else // if respawntime is -1, this item does not respawn
		Item_Show(e, -1);
}

void Item_ScheduleInitialRespawn(entity e)
{
	Item_Show(e, 0);
	Item_ScheduleRespawnIn(e, max(0, game_starttime - time) + ((e.respawntimestart) ? e.respawntimestart : ITEM_RESPAWNTIME_INITIAL(e)));
}

float Item_GiveAmmoTo(entity item, entity player, .float ammotype, float ammomax, float mode)
{
	if (!item.(ammotype))
		return false;

	if (item.spawnshieldtime)
	{
		if ((player.(ammotype) < ammomax) || item.pickup_anyway > 0)
		{
			player.(ammotype) = bound(player.(ammotype), ammomax, player.(ammotype) + item.(ammotype));
			goto YEAH;
		}
	}
	else if(g_weapon_stay == 2)
	{
		float mi = min(item.(ammotype), ammomax);
		if (player.(ammotype) < mi)
		{
			player.(ammotype) = mi;
			goto YEAH;
		}
	}

	return false;

LABEL(YEAH)
	switch(mode)
	{
		case ITEM_MODE_FUEL:
			player.pauserotfuel_finished = max(player.pauserotfuel_finished, time + autocvar_g_balance_pause_fuel_rot);
			break;
		case ITEM_MODE_HEALTH:
			player.pauserothealth_finished = max(player.pauserothealth_finished, time + autocvar_g_balance_pause_health_rot);
			break;
		case ITEM_MODE_ARMOR:
			player.pauserotarmor_finished = max(player.pauserotarmor_finished, time + autocvar_g_balance_pause_armor_rot);
			break;
		default:
			break;
	}
	return true;
}

float Item_GiveTo(entity item, entity player)
{
	float pickedup;

	// if nothing happens to player, just return without taking the item
	pickedup = false;
	int _switchweapon = 0;
	// in case the player has autoswitch enabled do the following:
	// if the player is using their best weapon before items are given, they
	// probably want to switch to an even better weapon after items are given

	if(player.autoswitch)
	{
		for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
		{
			.entity weaponentity = weaponentities[slot];
			if(player.(weaponentity).m_weapon != WEP_Null || slot == 0)
			{
				if(player.(weaponentity).m_switchweapon == w_getbestweapon(player, weaponentity))
					_switchweapon |= BIT(slot);

				if(!(player.weapons & WepSet_FromWeapon(player.(weaponentity).m_switchweapon)))
					_switchweapon |= BIT(slot);
			}
		}
	}

	pickedup |= Item_GiveAmmoTo(item, player, ammo_fuel, g_pickup_fuel_max, ITEM_MODE_FUEL);
	pickedup |= Item_GiveAmmoTo(item, player, ammo_shells, g_pickup_shells_max, ITEM_MODE_NONE);
	pickedup |= Item_GiveAmmoTo(item, player, ammo_nails, g_pickup_nails_max, ITEM_MODE_NONE);
	pickedup |= Item_GiveAmmoTo(item, player, ammo_rockets, g_pickup_rockets_max, ITEM_MODE_NONE);
	pickedup |= Item_GiveAmmoTo(item, player, ammo_cells, g_pickup_cells_max, ITEM_MODE_NONE);
	pickedup |= Item_GiveAmmoTo(item, player, ammo_plasma, g_pickup_plasma_max, ITEM_MODE_NONE);
	pickedup |= Item_GiveAmmoTo(item, player, health, item.max_health, ITEM_MODE_HEALTH);
	pickedup |= Item_GiveAmmoTo(item, player, armorvalue, item.max_armorvalue, ITEM_MODE_ARMOR);

	if (item.itemdef.instanceOfWeaponPickup)
	{
		WepSet w;
		w = item.weapons;
		w &= ~player.weapons;

		if (w || (item.spawnshieldtime && item.pickup_anyway > 0))
		{
			pickedup = true;
			FOREACH(Weapons, it != WEP_Null, {
				if(w & (it.m_wepset))
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
		if ((item.itemdef == ITEM_JetpackRegen) && !(player.items & IT_FUEL_REGEN))
			Send_Notification(NOTIF_ONE, player, MSG_CENTER, CENTER_ITEM_FUELREGEN_GOT);
		else if ((item.itemdef == ITEM_Jetpack) && !(player.items & IT_JETPACK))
			Send_Notification(NOTIF_ONE, player, MSG_CENTER, CENTER_ITEM_JETPACK_GOT);
	}

	int its;
	if((its = (item.items - (item.items & player.items)) & IT_PICKUPMASK))
	{
		pickedup = true;
		player.items |= its;
		Send_Notification(NOTIF_ONE, player, MSG_INFO, INFO_ITEM_WEAPON_GOT, item.netname);
	}

	if (item.strength_finished)
	{
		pickedup = true;
		player.strength_finished = max(player.strength_finished, time) + item.strength_finished;
	}
	if (item.invincible_finished)
	{
		pickedup = true;
		player.invincible_finished = max(player.invincible_finished, time) + item.invincible_finished;
	}
	if (item.superweapons_finished)
	{
		pickedup = true;
		player.superweapons_finished = max(player.superweapons_finished, time) + item.superweapons_finished;
	}

LABEL(skip)

	// always eat teamed entities
	if(item.team)
		pickedup = true;

	if (!pickedup)
		return 0;

	// crude hack to enforce switching weapons
	if(g_cts && item.itemdef.instanceOfWeaponPickup)
	{
		for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
		{
			.entity weaponentity = weaponentities[slot];
			if(player.(weaponentity).m_weapon != WEP_Null || slot == 0)
				W_SwitchWeapon_Force(player, Weapons_from(item.weapon), weaponentity);
		}
		return 1;
	}

	if(_switchweapon)
	{
		for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
		{
			.entity weaponentity = weaponentities[slot];
			if(_switchweapon & BIT(slot))
			if(player.(weaponentity).m_switchweapon != w_getbestweapon(player, weaponentity))
				W_SwitchWeapon_Force(player, w_getbestweapon(player, weaponentity), weaponentity);
		}
	}

	return 1;
}

void Item_Touch(entity this, entity toucher)
{

	// remove the item if it's currnetly in a NODROP brush or hits a NOIMPACT surface (such as sky)
	if (this.classname == "droppedweapon")
	{
		if (ITEM_TOUCH_NEEDKILL())
		{
			delete(this);
			return;
		}
	}

	if(!(toucher.flags & FL_PICKUPITEMS)
	|| STAT(FROZEN, toucher)
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

	if (this.classname == "droppedweapon")
	{
		this.strength_finished = max(0, this.strength_finished - time);
		this.invincible_finished = max(0, this.invincible_finished - time);
		this.superweapons_finished = max(0, this.superweapons_finished - time);
	}
	entity it = this.itemdef;
	bool gave = ITEM_HANDLE(Pickup, it, this, toucher);
	if (!gave)
	{
		if (this.classname == "droppedweapon")
		{
			// undo what we did above
			this.strength_finished += time;
			this.invincible_finished += time;
			this.superweapons_finished += time;
		}
		return;
	}

LABEL(pickup)

	toucher.last_pickup = time;

	Send_Effect(EFFECT_ITEM_PICKUP, CENTER_OR_VIEWOFS(this), '0 0 0', 1);
	_sound (toucher, (this.itemdef.instanceOfPowerup ? CH_TRIGGER_SINGLE : CH_TRIGGER), (this.item_pickupsound ? this.item_pickupsound : Sound_fixpath(this.item_pickupsound_ent)), VOL_BASE, ATTEN_NORM);

	if (this.classname == "droppedweapon")
		delete (this);
	else if (this.spawnshieldtime)
	{
		entity e;
		if(this.team)
		{
			RandomSelection_Init();
			IL_EACH(g_items, it.team == this.team,
			{
				if(it.itemdef) // is a registered item
				{
					Item_Show(it, -1);
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
}

void Item_Reset(entity this)
{
	Item_Show(this, !this.state);
	setorigin(this, this.origin);

	if (this.classname != "droppedweapon")
	{
		setthink(this, Item_Think);
		this.nextthink = time;

		if (this.waypointsprite_attached)
			WaypointSprite_Kill(this.waypointsprite_attached);

		if (this.itemdef.instanceOfPowerup || (this.weapons & WEPSET_SUPERWEAPONS)) // do not spawn powerups initially!
			Item_ScheduleInitialRespawn(this);
	}
}

void Item_FindTeam(entity this)
{
	entity e;

	if(this.effects & EF_NODRAW)
	{
		// marker for item team search
		LOG_TRACE("Initializing item team ", ftos(this.team));
		RandomSelection_Init();
		IL_EACH(g_items, it.team == this.team,
		{
			if(it.itemdef) // is a registered item
				RandomSelection_AddEnt(it, it.cnt, 0);
		});

		e = RandomSelection_chosen_ent;
		e.state = 0;
		Item_Show(e, 1);

		IL_EACH(g_items, it.team == this.team,
		{
			if(it.itemdef) // is a registered item
			{
				if(it != e)
				{
					// make it non-spawned
					Item_Show(it, -1);
					it.state = 1; // state 1 = initially hidden item, apparently
				}
				it.effects &= ~EF_NODRAW;
			}
		});

		Item_Reset(this);
	}
}

// Savage: used for item garbage-collection
void RemoveItem(entity this)
{
	if(wasfreed(this) || !this) { return; }
	Send_Effect(EFFECT_ITEM_PICKUP, CENTER_OR_VIEWOFS(this), '0 0 0', 1);
	delete(this);
}

// pickup evaluation functions
// these functions decide how desirable an item is to the bots

float generic_pickupevalfunc(entity player, entity item) {return item.bot_pickupbasevalue;}

float weapon_pickupevalfunc(entity player, entity item)
{
	// See if I have it already
	if(player.weapons & item.weapons)
	{
		// If I can pick it up
		if(!item.spawnshieldtime)
			return 0;
		return ammo_pickupevalfunc(player, item);
	}

	// reduce weapon value if bot already got a good arsenal
	float c = 1;
	int weapons_value = 0;
	FOREACH(Weapons, it != WEP_Null && (player.weapons & it.m_wepset), {
		weapons_value += it.bot_pickupbasevalue;
	});
	c -= bound(0, weapons_value / 20000, 1) * 0.5;

	return item.bot_pickupbasevalue * c;
}

float ammo_pickupevalfunc(entity player, entity item)
{
	bool need_shells = false, need_nails = false, need_rockets = false, need_cells = false, need_plasma = false, need_fuel = false;
	entity wpn = NULL;
	float c = 0;
	float rating = 0;

	// Detect needed ammo
	if(item.itemdef.instanceOfWeaponPickup)
	{
		entity ammo = NULL;
		if(item.ammo_shells)       { need_shells  = true; ammo = ITEM_Shells;      }
		else if(item.ammo_nails)   { need_nails   = true; ammo = ITEM_Bullets;     }
		else if(item.ammo_rockets) { need_rockets = true; ammo = ITEM_Rockets;     }
		else if(item.ammo_cells)   { need_cells   = true; ammo = ITEM_Cells;       }
		else if(item.ammo_plasma)  { need_plasma  = true; ammo = ITEM_Plasma;      }
		else if(item.ammo_fuel)    { need_fuel    = true; ammo = ITEM_JetpackFuel; }

		if(!ammo)
			return 0;
		wpn = item;
		rating = ammo.m_botvalue;
	}
	else
	{
		FOREACH(Weapons, it != WEP_Null, {
			if(!(player.weapons & (it.m_wepset)))
				continue;

			switch(it.ammo_field)
			{
				case ammo_shells:  need_shells  = true; break;
				case ammo_shells:  need_shells  = true; break;
				case ammo_nails:   need_nails   = true; break;
				case ammo_rockets: need_rockets = true; break;
				case ammo_cells:   need_cells   = true; break;
				case ammo_plasma:  need_plasma  = true; break;
				case ammo_fuel:    need_fuel    = true; break;
			}
		});
		rating = item.bot_pickupbasevalue;
	}

	if (need_shells)
	if (item.ammo_shells)
	if (player.ammo_shells < g_pickup_shells_max)
		c = item.ammo_shells / player.ammo_shells;
	if (need_nails)
	if (item.ammo_nails)
	if (player.ammo_nails < g_pickup_nails_max)
		c = item.ammo_nails / player.ammo_nails;
	if (need_rockets)
	if (item.ammo_rockets)
	if (player.ammo_rockets < g_pickup_rockets_max)
		c = item.ammo_rockets / player.ammo_rockets;
	if (need_cells)
	if (item.ammo_cells)
	if (player.ammo_cells < g_pickup_cells_max)
		c = item.ammo_cells / player.ammo_cells;
	if (need_plasma)
	if (item.ammo_plasma)
	if (player.ammo_plasma < g_pickup_plasma_max)
		c = item.ammo_plasma / player.ammo_plasma;
	if (need_fuel)
	if (item.ammo_fuel)
	if (player.ammo_fuel < g_pickup_fuel_max)
		c = item.ammo_fuel / player.ammo_fuel;

	rating *= min(2, c);
	if(wpn)
		rating += wpn.bot_pickupbasevalue * 0.1;
	return rating;
}

.int item_group;
.int item_group_count;
float healtharmor_pickupevalfunc(entity player, entity item)
{
	float c = 0;
	float rating = item.bot_pickupbasevalue;

	float itemarmor = item.armorvalue;
	float itemhealth = item.health;
	if(item.item_group)
	{
		itemarmor *= min(4, item.item_group_count);
		itemhealth *= min(4, item.item_group_count);
	}
	if (itemarmor)
	if (player.armorvalue < item.max_armorvalue)
		c = itemarmor / max(1, player.armorvalue * 2/3 + player.health * 1/3);
	if (itemhealth)
	if (player.health < item.max_health)
		c = itemhealth / max(1, player.health);

	rating *= min(2, c);
	return rating;
}

void Item_Damage(entity this, entity inflictor, entity attacker, float damage, int deathtype, vector hitloc, vector force)
{
	if(ITEM_DAMAGE_NEEDKILL(deathtype))
		RemoveItem(this);
}

void item_use(entity this, entity actor, entity trigger)
{
	// use the touch function to handle collection
	gettouch(this)(this, actor);
}

void _StartItem(entity this, entity def, float defaultrespawntime, float defaultrespawntimejitter)
{
	string itemname = def.m_name;
	Model itemmodel = def.m_model;
    Sound pickupsound = def.m_sound;
	float(entity player, entity item) pickupevalfunc = def.m_pickupevalfunc;
	float pickupbasevalue = def.m_botvalue;
	int itemflags = def.m_itemflags;

	startitem_failed = false;

	this.item_model_ent = itemmodel;
    this.item_pickupsound_ent = pickupsound;

    if(def.m_iteminit)
    	def.m_iteminit(this);

	if(!this.respawntime) // both need to be set
	{
		this.respawntime = defaultrespawntime;
		this.respawntimejitter = defaultrespawntimejitter;
	}

	if(!this.pickup_anyway && def.m_pickupanyway)
		this.pickup_anyway = def.m_pickupanyway();

	int itemid = def.m_itemid;
	this.items = itemid;
	int weaponid = def.instanceOfWeaponPickup ? def.m_weapon.m_id : 0;
	this.weapon = weaponid;

	if(!this.fade_end)
	{
		this.fade_start = autocvar_g_items_mindist;
		this.fade_end = autocvar_g_items_maxdist;
	}

	if(weaponid)
		this.weapons = WepSet_FromWeapon(Weapons_from(weaponid));

	this.flags = FL_ITEM | itemflags;
	IL_PUSH(g_items, this);

	if(MUTATOR_CALLHOOK(FilterItem, this)) // error means we do not want the item
	{
		startitem_failed = true;
		delete(this);
		return;
	}

	// is it a dropped weapon?
	if (this.classname == "droppedweapon")
	{
		this.reset = SUB_Remove;
		// it's a dropped weapon
		set_movetype(this, MOVETYPE_TOSS);

		// Savage: remove thrown items after a certain period of time ("garbage collection")
		setthink(this, RemoveItem);
		this.nextthink = time + 20;

		this.takedamage = DAMAGE_YES;
		this.event_damage = Item_Damage;

		if(this.strength_finished || this.invincible_finished || this.superweapons_finished)
		{
			// if item is worthless after a timer, have it expire then
			this.nextthink = max(this.strength_finished, this.invincible_finished, this.superweapons_finished);
		}

		// don't drop if in a NODROP zone (such as lava)
		traceline(this.origin, this.origin, MOVE_NORMAL, this);
		if (trace_dpstartcontents & DPCONTENTS_NODROP)
		{
			startitem_failed = true;
			delete(this);
			return;
		}
	}
	else
	{
		if(!have_pickup_item(this))
		{
			startitem_failed = true;
			delete (this);
			return;
		}

		if(this.angles != '0 0 0')
			this.SendFlags |= ISF_ANGLES;

		this.reset = Item_Reset;
		// it's a level item
		if(this.spawnflags & 1)
			this.noalign = 1;
		if (this.noalign > 0)
			set_movetype(this, MOVETYPE_NONE);
		else
			set_movetype(this, MOVETYPE_TOSS);
		// do item filtering according to game mode and other things
		if (this.noalign <= 0)
		{
			// first nudge it off the floor a little bit to avoid math errors
			setorigin(this, this.origin + '0 0 1');
			// set item size before we spawn a spawnfunc_waypoint
			setsize(this, def.m_mins, def.m_maxs);
			this.SendFlags |= ISF_SIZE;
			// note droptofloor returns false if stuck/or would fall too far
			if (!this.noalign)
				droptofloor(this);
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
			startitem_failed = true;
			remove (this);
			return;
		}
		*/

		if(this.targetname != "" && (this.spawnflags & 16))
			this.use = item_use;

		if(autocvar_spawn_debug >= 2)
		{
            // why not flags & fl_item?
		    FOREACH_ENTITY_RADIUS(this.origin, 3, it.is_item, {
                LOG_TRACE("XXX Found duplicated item: ", itemname, vtos(this.origin));
                LOG_TRACE(" vs ", it.netname, vtos(it.origin));
                error("Mapper sucks.");
            });
			this.is_item = true;
		}

		weaponsInMap |= WepSet_FromWeapon(Weapons_from(weaponid));

		precache_model(this.model);
		precache_sound(this.item_pickupsound);

		if (   def.instanceOfPowerup
			|| def.instanceOfWeaponPickup
			|| (def.instanceOfHealth && def != ITEM_HealthSmall)
			|| (def.instanceOfArmor && def != ITEM_ArmorSmall)
			|| (itemid & (IT_KEY1 | IT_KEY2))
		) this.target = "###item###"; // for finding the nearest item using find()

		Item_ItemsTime_SetTime(this, 0);
	}

	this.bot_pickup = true;
	this.bot_pickupevalfunc = pickupevalfunc;
	this.bot_pickupbasevalue = pickupbasevalue;
	this.mdl = this.model ? this.model : strzone(this.item_model_ent.model_str());
	this.netname = itemname;
	settouch(this, Item_Touch);
	setmodel(this, MDL_Null); // precision set below
	//this.effects |= EF_LOWPRECISION;

	setsize (this, this.pos1 =  def.m_mins, this.pos2 = def.m_maxs);

	this.SendFlags |= ISF_SIZE;

	if (!(this.spawnflags & 1024)) {
		if(def.instanceOfPowerup)
			this.ItemStatus |= ITS_ANIMATE1;

		if(this.armorvalue || this.health)
			this.ItemStatus |= ITS_ANIMATE2;
	}

	if(def.instanceOfWeaponPickup)
	{
		if (this.classname != "droppedweapon") // if dropped, colormap is already set up nicely
			this.colormap = 1024; // color shirt=0 pants=0 grey
		else
			this.gravity = 1;
		if (!(this.spawnflags & 1024))
			this.ItemStatus |= ITS_ANIMATE1;
		this.SendFlags |= ISF_COLORMAP;
	}

	this.state = 0;
	if(this.team) // broken, no idea why.
	{
		if(!this.cnt)
			this.cnt = 1; // item probability weight

		this.effects |= EF_NODRAW; // marker for item team search
		InitializeEntity(this, Item_FindTeam, INITPRIO_FINDTARGET);
	}
	else
		Item_Reset(this);

	Net_LinkEntity(this, !(def.instanceOfPowerup || def.instanceOfHealth || def.instanceOfArmor), 0, ItemSend);

	// call this hook after everything else has been done
	if (MUTATOR_CALLHOOK(Item_Spawn, this))
	{
		startitem_failed = true;
		delete(this);
		return;
	}

	setItemGroup(this);
}

void StartItem(entity this, GameItem def)
{
    _StartItem(
    	this,
    	this.itemdef = def,
    	def.m_respawntime(), // defaultrespawntime
    	def.m_respawntimejitter() // defaultrespawntimejitter
	);
}

#define IS_SMALL(def) ((def.instanceOfHealth && def == ITEM_HealthSmall) || (def.instanceOfArmor && def == ITEM_ArmorSmall))
int group_count = 1;

void setItemGroup(entity this)
{
	if(!IS_SMALL(this.itemdef))
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
	for (int k = 1; k <= group_count; k++)
	{
		int count = 0;
		IL_EACH(g_items, IS_SMALL(it.itemdef) && it.item_group == k, { count++; });
		if (count)
			IL_EACH(g_items, IS_SMALL(it.itemdef) && it.item_group == k, { it.item_group_count = count; });
	}
}

spawnfunc(item_rockets)
{
    StartItem(this, ITEM_Rockets);
}

spawnfunc(item_bullets)
{
	if(!weaponswapping)
	if(autocvar_sv_q3acompat_machineshotgunswap)
	if(this.classname != "droppedweapon")
	{
		weaponswapping = true;
		spawnfunc_item_shells(this);
		weaponswapping = false;
		return;
	}

    StartItem(this, ITEM_Bullets);
}

spawnfunc(item_cells)
{
	StartItem(this, ITEM_Cells);
}

spawnfunc(item_plasma)
{
	StartItem(this, ITEM_Plasma);
}

spawnfunc(item_shells)
{
	if(!weaponswapping)
	if(autocvar_sv_q3acompat_machineshotgunswap)
	if(this.classname != "droppedweapon")
	{
		weaponswapping = true;
		spawnfunc_item_bullets(this);
		weaponswapping = false;
		return;
	}

	StartItem(this, ITEM_Shells);
}

spawnfunc(item_armor_small)
{
	StartItem(this, ITEM_ArmorSmall);
}

spawnfunc(item_armor_medium)
{
	StartItem(this, ITEM_ArmorMedium);
}

spawnfunc(item_armor_big)
{
	StartItem(this, ITEM_ArmorBig);
}

spawnfunc(item_armor_mega)
{
	StartItem(this, ITEM_ArmorMega);
}

spawnfunc(item_health_small)
{
	StartItem(this, ITEM_HealthSmall);
}

spawnfunc(item_health_medium)
{
    StartItem(this, ITEM_HealthMedium);
}

spawnfunc(item_health_big)
{
	StartItem(this, ITEM_HealthBig);
}

spawnfunc(item_health_mega)
{
    StartItem(this, ITEM_HealthMega);
}

// support old misnamed entities
spawnfunc(item_armor1) { spawnfunc_item_armor_small(this); }  // FIXME: in Quake this is green armor, in Xonotic maps it is an armor shard
spawnfunc(item_armor25) { spawnfunc_item_armor_mega(this); }
spawnfunc(item_armor_large) { spawnfunc_item_armor_mega(this); }
spawnfunc(item_health1) { spawnfunc_item_health_small(this); }
spawnfunc(item_health25) { spawnfunc_item_health_medium(this); }
spawnfunc(item_health_large) { spawnfunc_item_health_big(this); }
spawnfunc(item_health100) { spawnfunc_item_health_mega(this); }

spawnfunc(item_strength)
{
	StartItem(this, ITEM_Strength);
}

spawnfunc(item_invincible)
{
	StartItem(this, ITEM_Shield);
}

// compatibility:
spawnfunc(item_quad) { this.classname = "item_strength";spawnfunc_item_strength(this);}

void target_items_use(entity this, entity actor, entity trigger)
{
	if(actor.classname == "droppedweapon")
	{
		EXACTTRIGGER_TOUCH(this, trigger);
		delete(actor);
		return;
	}

	if (!IS_PLAYER(actor))
		return;
	if(IS_DEAD(actor))
		return;
	if(trigger.solid == SOLID_TRIGGER)
	{
		EXACTTRIGGER_TOUCH(this, trigger);
	}

	IL_EACH(g_items, it.enemy == actor && it.classname == "droppedweapon",
	{
		delete(it);
	});

	if(GiveItems(actor, 0, tokenize_console(this.netname)))
		centerprint(actor, this.message);
}

spawnfunc(target_items)
{
	int n, j;
	string s;

	this.use = target_items_use;
	if(!this.strength_finished)
		this.strength_finished = autocvar_g_balance_powerup_strength_time;
	if(!this.invincible_finished)
		this.invincible_finished = autocvar_g_balance_powerup_invincible_time;
	if(!this.superweapons_finished)
		this.superweapons_finished = autocvar_g_balance_superweapons_time;

	n = tokenize_console(this.netname);
	if(argv(0) == "give")
	{
		this.netname = substring(this.netname, argv_start_index(1), argv_end_index(-1) - argv_start_index(1));
	}
	else
	{
		for(j = 0; j < n; ++j)
		{
			if     (argv(j) == "unlimited_ammo")         this.items |= IT_UNLIMITED_AMMO;
			else if(argv(j) == "unlimited_weapon_ammo")  this.items |= IT_UNLIMITED_WEAPON_AMMO;
			else if(argv(j) == "unlimited_superweapons") this.items |= IT_UNLIMITED_SUPERWEAPONS;
			else if(argv(j) == "strength")               this.items |= ITEM_Strength.m_itemid;
			else if(argv(j) == "invincible")             this.items |= ITEM_Shield.m_itemid;
			else if(argv(j) == "superweapons")           this.items |= IT_SUPERWEAPON;
			else if(argv(j) == "jetpack")                this.items |= ITEM_Jetpack.m_itemid;
			else if(argv(j) == "fuel_regen")             this.items |= ITEM_JetpackRegen.m_itemid;
			else
			{
				FOREACH(Buffs, it != BUFF_Null,
				{
					s = Buff_UndeprecateName(argv(j));
					if(s == it.m_name)
					{
						this.buffs |= (it.m_itemid);
						break;
					}
				});
				FOREACH(Weapons, it != WEP_Null, {
					s = W_UndeprecateName(argv(j));
					if(s == it.netname)
					{
						this.weapons |= (it.m_wepset);
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

		this.netname = "";
		this.netname = sprintf("%s %s%d %s", this.netname, itemprefix, boolean(this.items & IT_UNLIMITED_WEAPON_AMMO), "unlimited_weapon_ammo");
		this.netname = sprintf("%s %s%d %s", this.netname, itemprefix, boolean(this.items & IT_UNLIMITED_SUPERWEAPONS), "unlimited_superweapons");
		this.netname = sprintf("%s %s%d %s", this.netname, valueprefix, this.strength_finished * boolean(this.items & ITEM_Strength.m_itemid), "strength");
		this.netname = sprintf("%s %s%d %s", this.netname, valueprefix, this.invincible_finished * boolean(this.items & ITEM_Shield.m_itemid), "invincible");
		this.netname = sprintf("%s %s%d %s", this.netname, valueprefix, this.superweapons_finished * boolean(this.items & IT_SUPERWEAPON), "superweapons");
		this.netname = sprintf("%s %s%d %s", this.netname, itemprefix, boolean(this.items & ITEM_Jetpack.m_itemid), "jetpack");
		this.netname = sprintf("%s %s%d %s", this.netname, itemprefix, boolean(this.items & ITEM_JetpackRegen.m_itemid), "fuel_regen");
		if(this.ammo_shells != 0) this.netname = sprintf("%s %s%d %s", this.netname, valueprefix, max(0, this.ammo_shells), "shells");
		if(this.ammo_nails != 0) this.netname = sprintf("%s %s%d %s", this.netname, valueprefix, max(0, this.ammo_nails), "nails");
		if(this.ammo_rockets != 0) this.netname = sprintf("%s %s%d %s", this.netname, valueprefix, max(0, this.ammo_rockets), "rockets");
		if(this.ammo_cells != 0) this.netname = sprintf("%s %s%d %s", this.netname, valueprefix, max(0, this.ammo_cells), "cells");
		if(this.ammo_plasma != 0) this.netname = sprintf("%s %s%d %s", this.netname, valueprefix, max(0, this.ammo_plasma), "plasma");
		if(this.ammo_fuel != 0) this.netname = sprintf("%s %s%d %s", this.netname, valueprefix, max(0, this.ammo_fuel), "fuel");
		if(this.health != 0) this.netname = sprintf("%s %s%d %s", this.netname, valueprefix, max(0, this.health), "health");
		if(this.armorvalue != 0) this.netname = sprintf("%s %s%d %s", this.netname, valueprefix, max(0, this.armorvalue), "armor");
		FOREACH(Buffs, it != BUFF_Null, this.netname = sprintf("%s %s%d %s", this.netname, itemprefix, !!(this.buffs & (it.m_itemid)), it.m_name));
		FOREACH(Weapons, it != WEP_Null, this.netname = sprintf("%s %s%d %s", this.netname, itemprefix, !!(this.weapons & (it.m_wepset)), it.netname));
	}
	this.netname = strzone(this.netname);
	//print(this.netname, "\n");

	n = tokenize_console(this.netname);
	for(j = 0; j < n; ++j)
	{
		FOREACH(Weapons, it != WEP_Null && W_UndeprecateName(argv(j)) == it.netname, {
            it.wr_init(it);
            break;
		});
	}
}

spawnfunc(item_fuel)
{
	StartItem(this, ITEM_JetpackFuel);
}

spawnfunc(item_fuel_regen)
{
	if(start_items & ITEM_JetpackRegen.m_itemid)
	{
		spawnfunc_item_fuel(this);
		return;
	}
	StartItem(this, ITEM_JetpackRegen);
}

spawnfunc(item_jetpack)
{
	if(start_items & ITEM_Jetpack.m_itemid)
	{
		spawnfunc_item_fuel(this);
		return;
	}
	StartItem(this, ITEM_Jetpack);
}

float GiveWeapon(entity e, float wpn, float op, float val)
{
	WepSet v0, v1;
	WepSet s = WepSet_FromWeapon(Weapons_from(wpn));
	v0 = (e.weapons & s);
	switch(op)
	{
		case OP_SET:
			if(val > 0)
				e.weapons |= s;
			else
				e.weapons &= ~s;
			break;
		case OP_MIN:
		case OP_PLUS:
			if(val > 0)
				e.weapons |= s;
			break;
		case OP_MAX:
			if(val <= 0)
				e.weapons &= ~s;
			break;
		case OP_MINUS:
			if(val > 0)
				e.weapons &= ~s;
			break;
	}
	v1 = (e.weapons & s);
	return (v0 != v1);
}

bool GiveBuff(entity e, Buff thebuff, int op, int val)
{
	bool had_buff = (e.buffs & thebuff.m_itemid);
	switch(op)
	{
		case OP_SET:
			if(val > 0)
				e.buffs |= thebuff.m_itemid;
			else
				e.buffs &= ~thebuff.m_itemid;
			break;
		case OP_MIN:
		case OP_PLUS:
			if(val > 0)
				e.buffs |= thebuff.m_itemid;
			break;
		case OP_MAX:
			if(val <= 0)
				e.buffs &= ~thebuff.m_itemid;
			break;
		case OP_MINUS:
			if(val > 0)
				e.buffs &= ~thebuff.m_itemid;
			break;
	}
	bool have_buff = (e.buffs & thebuff.m_itemid);
	return (had_buff != have_buff);
}

void GiveSound(entity e, float v0, float v1, float t, Sound snd_incr, Sound snd_decr)
{
	if(v1 == v0)
		return;
	if(v1 <= v0 - t)
	{
		if(snd_decr != NULL)
			sound (e, CH_TRIGGER, snd_decr, VOL_BASE, ATTEN_NORM);
	}
	else if(v0 >= v0 + t)
	{
		if(snd_incr != NULL)
			sound (e, CH_TRIGGER, snd_incr, VOL_BASE, ATTEN_NORM);
	}
}

void GiveRot(entity e, float v0, float v1, .float rotfield, float rottime, .float regenfield, float regentime)
{
	if(v0 < v1)
		e.(rotfield) = max(e.(rotfield), time + rottime);
	else if(v0 > v1)
		e.(regenfield) = max(e.(regenfield), time + regentime);
}
float GiveItems(entity e, float beginarg, float endarg)
{
	float got, i, val, op;
	string cmd;

	val = 999;
	op = OP_SET;

	got = 0;

	int _switchweapon = 0;

	if(e.autoswitch)
	{
		for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
		{
			.entity weaponentity = weaponentities[slot];
			if(e.(weaponentity).m_weapon != WEP_Null || slot == 0)
			if(e.(weaponentity).m_switchweapon == w_getbestweapon(e, weaponentity))
				_switchweapon |= BIT(slot);
		}
	}

	e.strength_finished = max(0, e.strength_finished - time);
	e.invincible_finished = max(0, e.invincible_finished - time);
	e.superweapons_finished = max(0, e.superweapons_finished - time);

	PREGIVE(e, items);
	PREGIVE_WEAPONS(e);
	PREGIVE(e, strength_finished);
	PREGIVE(e, invincible_finished);
	PREGIVE(e, superweapons_finished);
	PREGIVE(e, ammo_nails);
	PREGIVE(e, ammo_cells);
	PREGIVE(e, ammo_plasma);
	PREGIVE(e, ammo_shells);
	PREGIVE(e, ammo_rockets);
	PREGIVE(e, ammo_fuel);
	PREGIVE(e, armorvalue);
	PREGIVE(e, health);

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
				got += GiveBit(e, items, ITEM_JetpackRegen.m_itemid, op, val);
				got += GiveValue(e, strength_finished, op, val);
				got += GiveValue(e, invincible_finished, op, val);
				got += GiveValue(e, superweapons_finished, op, val);
				got += GiveBit(e, items, IT_UNLIMITED_AMMO, op, val);
			case "all":
				got += GiveBit(e, items, ITEM_Jetpack.m_itemid, op, val);
				got += GiveValue(e, health, op, val);
				got += GiveValue(e, armorvalue, op, val);
			case "allweapons":
				FOREACH(Weapons, it != WEP_Null && !(it.spawnflags & WEP_FLAG_MUTATORBLOCKED), got += GiveWeapon(e, it.m_id, op, val));
			//case "allbuffs": // all buffs makes a player god, do not want!
				//FOREACH(Buffs, it != BUFF_Null, got += GiveBuff(e, it.m_itemid, op, val));
			case "allammo":
				got += GiveValue(e, ammo_cells, op, val);
				got += GiveValue(e, ammo_plasma, op, val);
				got += GiveValue(e, ammo_shells, op, val);
				got += GiveValue(e, ammo_nails, op, val);
				got += GiveValue(e, ammo_rockets, op, val);
				got += GiveValue(e, ammo_fuel, op, val);
				break;
			case "unlimited_ammo":
				got += GiveBit(e, items, IT_UNLIMITED_AMMO, op, val);
				break;
			case "unlimited_weapon_ammo":
				got += GiveBit(e, items, IT_UNLIMITED_WEAPON_AMMO, op, val);
				break;
			case "unlimited_superweapons":
				got += GiveBit(e, items, IT_UNLIMITED_SUPERWEAPONS, op, val);
				break;
			case "jetpack":
				got += GiveBit(e, items, ITEM_Jetpack.m_itemid, op, val);
				break;
			case "fuel_regen":
				got += GiveBit(e, items, ITEM_JetpackRegen.m_itemid, op, val);
				break;
			case "strength":
				got += GiveValue(e, strength_finished, op, val);
				break;
			case "invincible":
				got += GiveValue(e, invincible_finished, op, val);
				break;
			case "superweapons":
				got += GiveValue(e, superweapons_finished, op, val);
				break;
			case "cells":
				got += GiveValue(e, ammo_cells, op, val);
				break;
			case "plasma":
				got += GiveValue(e, ammo_plasma, op, val);
				break;
			case "shells":
				got += GiveValue(e, ammo_shells, op, val);
				break;
			case "nails":
			case "bullets":
				got += GiveValue(e, ammo_nails, op, val);
				break;
			case "rockets":
				got += GiveValue(e, ammo_rockets, op, val);
				break;
			case "health":
				got += GiveValue(e, health, op, val);
				break;
			case "armor":
				got += GiveValue(e, armorvalue, op, val);
				break;
			case "fuel":
				got += GiveValue(e, ammo_fuel, op, val);
				break;
			default:
				FOREACH(Buffs, it != BUFF_Null && Buff_UndeprecateName(cmd) == it.m_name,
				{
					got += GiveBuff(e, it, op, val);
					break;
				});
				FOREACH(Weapons, it != WEP_Null && W_UndeprecateName(cmd) == it.netname, {
                    got += GiveWeapon(e, it.m_id, op, val);
                    break;
				});
				break;
		}
		val = 999;
		op = OP_SET;
	}

	POSTGIVE_BIT(e, items, ITEM_JetpackRegen.m_itemid, SND_ITEMPICKUP, SND_Null);
	POSTGIVE_BIT(e, items, IT_UNLIMITED_SUPERWEAPONS, SND_POWERUP, SND_POWEROFF);
	POSTGIVE_BIT(e, items, IT_UNLIMITED_WEAPON_AMMO, SND_POWERUP, SND_POWEROFF);
	POSTGIVE_BIT(e, items, ITEM_Jetpack.m_itemid, SND_ITEMPICKUP, SND_Null);
	FOREACH(Weapons, it != WEP_Null, {
		POSTGIVE_WEAPON(e, it, SND_WEAPONPICKUP, SND_Null);
		if(!(save_weapons & (it.m_wepset)))
			if(e.weapons & (it.m_wepset))
				it.wr_init(it);
	});
	POSTGIVE_VALUE(e, strength_finished, 1, SND_POWERUP, SND_POWEROFF);
	POSTGIVE_VALUE(e, invincible_finished, 1, SND_Shield, SND_POWEROFF);
	//POSTGIVE_VALUE(e, superweapons_finished, 1, SND_Null, SND_Null);
	POSTGIVE_VALUE(e, ammo_nails, 0, SND_ITEMPICKUP, SND_Null);
	POSTGIVE_VALUE(e, ammo_cells, 0, SND_ITEMPICKUP, SND_Null);
	POSTGIVE_VALUE(e, ammo_plasma, 0, SND_ITEMPICKUP, SND_Null);
	POSTGIVE_VALUE(e, ammo_shells, 0, SND_ITEMPICKUP, SND_Null);
	POSTGIVE_VALUE(e, ammo_rockets, 0, SND_ITEMPICKUP, SND_Null);
	POSTGIVE_VALUE_ROT(e, ammo_fuel, 1, pauserotfuel_finished, autocvar_g_balance_pause_fuel_rot, pauseregen_finished, autocvar_g_balance_pause_fuel_regen, SND_ITEMPICKUP, SND_Null);
	POSTGIVE_VALUE_ROT(e, armorvalue, 1, pauserotarmor_finished, autocvar_g_balance_pause_armor_rot, pauseregen_finished, autocvar_g_balance_pause_health_regen, SND_ARMOR25, SND_Null);
	POSTGIVE_VALUE_ROT(e, health, 1, pauserothealth_finished, autocvar_g_balance_pause_health_rot, pauseregen_finished, autocvar_g_balance_pause_health_regen, SND_MEGAHEALTH, SND_Null);

	if(e.superweapons_finished <= 0)
		if(e.weapons & WEPSET_SUPERWEAPONS)
			e.superweapons_finished = autocvar_g_balance_superweapons_time;

	if(e.strength_finished <= 0)
		e.strength_finished = 0;
	else
		e.strength_finished += time;
	if(e.invincible_finished <= 0)
		e.invincible_finished = 0;
	else
		e.invincible_finished += time;
	if(e.superweapons_finished <= 0)
		e.superweapons_finished = 0;
	else
		e.superweapons_finished += time;

	for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	{
		.entity weaponentity = weaponentities[slot];
		if(e.(weaponentity).m_weapon != WEP_Null || slot == 0)
		if(!(e.weapons & WepSet_FromWeapon(e.(weaponentity).m_switchweapon)))
			_switchweapon |= BIT(slot);
	}

	if(_switchweapon)
	{
		for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
		{
			.entity weaponentity = weaponentities[slot];
			if(_switchweapon & BIT(slot))
			{
				Weapon wep = w_getbestweapon(e, weaponentity);
				if(wep != e.(weaponentity).m_switchweapon)
					W_SwitchWeapon_Force(e, wep, weaponentity);
			}
		}
	}

	return got;
}
#endif
