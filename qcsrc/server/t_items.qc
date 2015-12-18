#include "t_items.qh"

#include "../common/items/all.qc"

#if defined(SVQC)

    #include "bot/bot.qh"
    #include "bot/waypoints.qh"

    #include "mutators/all.qh"

    #include "weapons/common.qh"
    #include "weapons/selection.qh"
    #include "weapons/weaponsystem.qh"

    #include "../common/constants.qh"
    #include "../common/deathtypes/all.qh"
    #include "../common/notifications.qh"
	#include "../common/triggers/subs.qh"
    #include "../common/util.qh"

    #include "../common/monsters/all.qh"

    #include "../common/weapons/all.qh"

    #include "../lib/warpzone/util_server.qh"
#endif

REGISTER_NET_LINKED(ENT_CLIENT_ITEM)

#ifdef CSQC
void ItemDraw(entity this)
{
    if(this.gravity)
    {
        Movetype_Physics_MatchServer(this, false);
        if(this.move_flags & FL_ONGROUND)
        { // For some reason move_avelocity gets set to '0 0 0' here ...
            this.oldorigin = this.origin;
            this.gravity = 0;

            if(autocvar_cl_animate_items)
            { // ... so reset it if animations are requested.
                if(this.ItemStatus & ITS_ANIMATE1)
                    this.move_avelocity = '0 180 0';

                if(this.ItemStatus & ITS_ANIMATE2)
                    this.move_avelocity = '0 -90 0';
            }
        }
    }
    else if (autocvar_cl_animate_items)
    {
        if(this.ItemStatus & ITS_ANIMATE1)
        {
            this.angles += this.move_avelocity * frametime;
            setorigin(this, '0 0 10' + this.oldorigin + '0 0 8' * sin(time * 2));
        }

        if(this.ItemStatus & ITS_ANIMATE2)
        {
            this.angles += this.move_avelocity * frametime;
            setorigin(this, '0 0 8' + this.oldorigin + '0 0 4' * sin(time * 3));
        }
    }
}

void ItemDrawSimple(entity this)
{
    if(this.gravity)
    {
        Movetype_Physics_MatchServer(this, false);

        if(this.move_flags & FL_ONGROUND)
            this.gravity = 0;
    }
}

void Item_PreDraw()
{SELFPARAM();
	vector org;
	float alph;
	org = getpropertyvec(VF_ORIGIN);
	if(!checkpvs(org, self)) // this makes sense as long as we don't support recursive warpzones
		alph = 0;
	else if(self.fade_start)
		alph = bound(0, (self.fade_end - vlen(org - self.origin - 0.5 * (self.mins + self.maxs))) / (self.fade_end - self.fade_start), 1);
	else
		alph = 1;
	//printf("%v <-> %v\n", view_origin, self.origin + 0.5 * (self.mins + self.maxs));
	if(self.ItemStatus & ITS_AVAILABLE)
		self.alpha = alph;
	if(alph <= 0)
		self.drawmask = 0;
	else
		self.drawmask = MASK_NORMAL;
}

void ItemRemove()
{SELFPARAM();
	if (self.mdl)
		strunzone(self.mdl);
}

NET_HANDLE(ENT_CLIENT_ITEM, bool isnew)
{
    int sf = ReadByte();

    if(sf & ISF_LOCATION)
    {
        self.origin_x = ReadCoord();
        self.origin_y = ReadCoord();
        self.origin_z = ReadCoord();
        setorigin(self, self.origin);
        self.oldorigin = self.origin;
    }

    if(sf & ISF_ANGLES)
    {
        self.angles_x = ReadAngle();
        self.angles_y = ReadAngle();
        self.angles_z = ReadAngle();
        self.move_angles = self.angles;
    }

    if(sf & ISF_SIZE)
    {
        float use_bigsize = ReadByte();
        setsize(self, '-16 -16 0', (use_bigsize) ? '16 16 48' : '16 16 32');
    }

    if(sf & ISF_STATUS) // need to read/write status frist so model can handle simple, fb etc.
    {
        self.ItemStatus = ReadByte();

        if(self.ItemStatus & ITS_AVAILABLE)
        {
            self.alpha = 1;
            self.colormod = self.glowmod = '1 1 1';
        }
        else
        {
            if (autocvar_cl_ghost_items_color)
            {
                self.alpha = autocvar_cl_ghost_items;
                self.colormod = self.glowmod = autocvar_cl_ghost_items_color;
            }
            else
                self.alpha = -1;
        }

        if(autocvar_cl_fullbright_items)
            if(self.ItemStatus & ITS_ALLOWFB)
                self.effects |= EF_FULLBRIGHT;

        if(self.ItemStatus & ITS_STAYWEP)
        {
            self.colormod = self.glowmod = autocvar_cl_weapon_stay_color;
            self.alpha = autocvar_cl_weapon_stay_alpha;

        }

        if(self.ItemStatus & ITS_POWERUP)
        {
            if(self.ItemStatus & ITS_AVAILABLE)
                self.effects |= (EF_ADDITIVE | EF_FULLBRIGHT);
            else
                 self.effects &= ~(EF_ADDITIVE | EF_FULLBRIGHT);
        }
    }

    if(sf & ISF_MODEL)
    {
        self.drawmask  = MASK_NORMAL;
		self.move_movetype = MOVETYPE_TOSS;
        self.draw       = ItemDraw;
        self.solid = SOLID_TRIGGER;
        //self.move_flags |= FL_ITEM;

        bool use_bigsize = ReadByte();

        self.fade_end = ReadShort();
        self.fade_start = ReadShort();
        if(self.fade_start && !autocvar_cl_items_nofade)
        	self.predraw = Item_PreDraw;

        if(self.mdl)
            strunzone(self.mdl);

        self.mdl = "";
        string _fn = ReadString();

        if(autocvar_cl_simple_items && (self.ItemStatus & ITS_ALLOWSI))
        {
            string _fn2 = substring(_fn, 0 , strlen(_fn) -4);
            self.draw = ItemDrawSimple;

            if(fexists(sprintf("%s%s.md3", _fn2, autocvar_cl_simpleitems_postfix)))
                self.mdl = strzone(sprintf("%s%s.md3", _fn2, autocvar_cl_simpleitems_postfix));
            else if(fexists(sprintf("%s%s.dpm", _fn2, autocvar_cl_simpleitems_postfix)))
                self.mdl = strzone(sprintf("%s%s.dpm", _fn2, autocvar_cl_simpleitems_postfix));
            else if(fexists(sprintf("%s%s.iqm", _fn2, autocvar_cl_simpleitems_postfix)))
                self.mdl = strzone(sprintf("%s%s.iqm", _fn2, autocvar_cl_simpleitems_postfix));
            else if(fexists(sprintf("%s%s.mdl", _fn2, autocvar_cl_simpleitems_postfix)))
                self.mdl = strzone(sprintf("%s%s.mdl", _fn2, autocvar_cl_simpleitems_postfix));
            else
            {
                self.draw = ItemDraw;
                LOG_TRACE("Simple item requested for ", _fn, " but no model exists for it\n");
            }
        }

        if(self.draw != ItemDrawSimple)
            self.mdl = strzone(_fn);


        if(self.mdl == "")
            LOG_TRACE("^1WARNING!^7 self.mdl is unset for item ", self.classname, ", tell tZork about this!\n");

        precache_model(self.mdl);
        _setmodel(self, self.mdl);

        setsize(self, '-16 -16 0', (use_bigsize) ? '16 16 48' : '16 16 32');
    }

    if(sf & ISF_COLORMAP)
        self.colormap = ReadShort();

    if(sf & ISF_DROP)
    {
        self.gravity = 1;
        self.pushable = true;
        //self.move_angles = '0 0 0';
        self.move_movetype = MOVETYPE_TOSS;
        self.move_velocity_x = ReadCoord();
        self.move_velocity_y = ReadCoord();
        self.move_velocity_z = ReadCoord();
        self.velocity = self.move_velocity;
        self.move_origin = self.oldorigin;

        if(!self.move_time)
        {
            self.move_time = time;
            self.spawntime = time;
        }
        else
            self.move_time = max(self.move_time, time);
    }

    if(autocvar_cl_animate_items)
    {
        if(self.ItemStatus & ITS_ANIMATE1)
            self.move_avelocity = '0 180 0';

        if(self.ItemStatus & ITS_ANIMATE2)
            self.move_avelocity = '0 -90 0';
    }

    self.entremove = ItemRemove;

    return true;
}

#endif

#ifdef SVQC
bool ItemSend(entity this, entity to, int sf)
{
	if(self.gravity)
		sf |= ISF_DROP;
	else
		sf &= ~ISF_DROP;

	WriteHeader(MSG_ENTITY, ENT_CLIENT_ITEM);
	WriteByte(MSG_ENTITY, sf);

	//WriteByte(MSG_ENTITY, self.cnt);
	if(sf & ISF_LOCATION)
	{
		WriteCoord(MSG_ENTITY, self.origin.x);
		WriteCoord(MSG_ENTITY, self.origin.y);
		WriteCoord(MSG_ENTITY, self.origin.z);
	}

	if(sf & ISF_ANGLES)
	{
		WriteAngle(MSG_ENTITY, self.angles_x);
		WriteAngle(MSG_ENTITY, self.angles_y);
		WriteAngle(MSG_ENTITY, self.angles_z);
	}

	if(sf & ISF_SIZE)
	{
		Pickup p = this.itemdef;
		WriteByte(MSG_ENTITY, p.instanceOfPowerup || p.instanceOfHealth || p.instanceOfArmor);
	}

	if(sf & ISF_STATUS)
		WriteByte(MSG_ENTITY, self.ItemStatus);

	if(sf & ISF_MODEL)
	{
		Pickup p = this.itemdef;
		WriteByte(MSG_ENTITY, p.instanceOfPowerup || p.instanceOfHealth || p.instanceOfArmor);
		WriteShort(MSG_ENTITY, self.fade_end);
		WriteShort(MSG_ENTITY, self.fade_start);

		if(self.mdl == "")
			LOG_TRACE("^1WARNING!^7 self.mdl is unset for item ", self.classname, "exspect a crash just aboute now\n");

		WriteString(MSG_ENTITY, self.mdl);
	}


	if(sf & ISF_COLORMAP)
		WriteShort(MSG_ENTITY, self.colormap);

	if(sf & ISF_DROP)
	{
		WriteCoord(MSG_ENTITY, self.velocity.x);
		WriteCoord(MSG_ENTITY, self.velocity.y);
		WriteCoord(MSG_ENTITY, self.velocity.z);
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
	if(this.SendEntity3 == ItemSend)
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
			if(this.weapons || (this.items & IT_AMMO)) // no item or ammo pickups in weaponarena
				return false;
	}
	return true;
}

/*
float Item_Customize()
{
	if(self.spawnshieldtime)
		return true;
	if(self.weapons & ~other.weapons)
	{
		self.colormod = '0 0 0';
		self.glowmod = self.colormod;
		self.alpha = 0.5 + 0.5 * g_ghost_items; // halfway more alpha
		return true;
	}
	else
	{
		if(g_ghost_items)
		{
			self.colormod = stov(autocvar_g_ghost_items_color);
			self.glowmod = self.colormod;
			self.alpha = g_ghost_items;
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
	entity def = e.itemdef;
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
		e.glowmod = e.colormod;
		e.spawnshieldtime = 1;
		e.ItemStatus &= ~ITS_AVAILABLE;
	}}

	if (e.items & ITEM_Strength.m_itemid || e.items & ITEM_Shield.m_itemid)
		e.ItemStatus |= ITS_POWERUP;

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

void Item_Think()
{SELFPARAM();
	self.nextthink = time;
	if(self.origin != self.oldorigin)
		ItemUpdate(self);
}

bool Item_ItemsTime_SpectatorOnly(GameItem it);
bool Item_ItemsTime_Allow(GameItem it, WepSet _weapons);
float Item_ItemsTime_UpdateTime(entity e, float t);
void Item_ItemsTime_SetTime(entity e, float t);
void Item_ItemsTime_SetTimesForAllPlayers();

void Item_Respawn ()
{SELFPARAM();
	Item_Show(self, 1);
	// this is ugly...
	if(self.items == ITEM_Strength.m_itemid)
		sound (self, CH_TRIGGER, SND_STRENGTH_RESPAWN, VOL_BASE, ATTEN_NORM);	// play respawn sound
	else if(self.items == ITEM_Shield.m_itemid)
		sound (self, CH_TRIGGER, SND_SHIELD_RESPAWN, VOL_BASE, ATTEN_NORM);	// play respawn sound
	else
		sound (self, CH_TRIGGER, SND_ITEMRESPAWN, VOL_BASE, ATTEN_NORM);	// play respawn sound
	setorigin (self, self.origin);

    if (Item_ItemsTime_Allow(self.itemdef, self.weapons))
	{
		float t = Item_ItemsTime_UpdateTime(self, 0);
		Item_ItemsTime_SetTime(self, t);
		Item_ItemsTime_SetTimesForAllPlayers();
	}

	self.think = Item_Think;
	self.nextthink = time;

	//Send_Effect(EFFECT_ITEM_RESPAWN, self.origin + self.mins_z * '0 0 1' + '0 0 48', '0 0 0', 1);
	Send_Effect(EFFECT_ITEM_RESPAWN, CENTER_OR_VIEWOFS(self), '0 0 0', 1);
}

void Item_RespawnCountdown ()
{SELFPARAM();
	if(self.count >= ITEM_RESPAWN_TICKS)
	{
		if(self.waypointsprite_attached)
			WaypointSprite_Kill(self.waypointsprite_attached);
		Item_Respawn();
	}
	else
	{
		self.nextthink = time + 1;
		self.count += 1;
		if(self.count == 1)
		{
			MUTATOR_CALLHOOK(Item_RespawnCountdown, string_null, '0 0 0');
			do {
				{
					entity wi = Weapons_from(self.weapon);
					if (wi != WEP_Null) {
						entity wp = WaypointSprite_Spawn(WP_Weapon, 0, 0, self, '0 0 64', world, 0, self, waypointsprite_attached, true, RADARICON_Weapon);
						wp.wp_extra = wi.m_id;
						break;
					}
				}
				{
					entity ii = self.itemdef;
					if (ii != NULL) {
						entity wp = WaypointSprite_Spawn(WP_Item, 0, 0, self, '0 0 64', world, 0, self, waypointsprite_attached, true, RADARICON_Item);
						wp.wp_extra = ii.m_id;
						break;
					}
				}
			} while (0);
            if(self.waypointsprite_attached)
            {
                GameItem def = self.itemdef;
                if (Item_ItemsTime_SpectatorOnly(def))
                    WaypointSprite_UpdateRule(self.waypointsprite_attached, 0, SPRITERULE_SPECTATOR);
                WaypointSprite_UpdateBuildFinished(self.waypointsprite_attached, time + ITEM_RESPAWN_TICKS);
            }
		}

		if(self.waypointsprite_attached)
		{
			setself(self.waypointsprite_attached);
			entity e;
			FOR_EACH_REALCLIENT(e)
				if(self.waypointsprite_visible_for_player(e))
				{
					msg_entity = e;
					soundto(MSG_ONE, this, CH_TRIGGER, SND(ITEMRESPAWNCOUNTDOWN), VOL_BASE, ATTEN_NORM);	// play respawn sound
				}
			setself(this);

			WaypointSprite_Ping(self.waypointsprite_attached);
			//WaypointSprite_UpdateHealth(self.waypointsprite_attached, self.count);
		}
	}
}

void Item_RespawnThink()
{SELFPARAM();
	self.nextthink = time;
	if(self.origin != self.oldorigin)
		ItemUpdate(self);

	if(time >= self.wait)
		Item_Respawn();
}

void Item_ScheduleRespawnIn(entity e, float t)
{
	if (Item_ItemsTime_Allow(e.itemdef, e.weapons))
	{
		e.think = Item_RespawnCountdown;
		e.nextthink = time + max(0, t - ITEM_RESPAWN_TICKS);
		e.scheduledrespawntime = e.nextthink + ITEM_RESPAWN_TICKS;
		e.count = 0;
		t = Item_ItemsTime_UpdateTime(e, e.scheduledrespawntime);
		Item_ItemsTime_SetTime(e, t);
		Item_ItemsTime_SetTimesForAllPlayers();
	}
	else
	{
		e.think = Item_RespawnThink;
		e.nextthink = time;
		e.scheduledrespawntime = time + t;
		e.wait = time + t;
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
	Item_ScheduleRespawnIn(e, game_starttime - time + ITEM_RESPAWNTIME_INITIAL(e));
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

:YEAH
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
	float _switchweapon;
	float pickedup;
	float it;
	float i;

	// if nothing happens to player, just return without taking the item
	pickedup = false;
	_switchweapon = false;
	// in case the player has autoswitch enabled do the following:
	// if the player is using their best weapon before items are given, they
	// probably want to switch to an even better weapon after items are given
	if (player.autoswitch)
	if (PS(player).m_switchweapon == w_getbestweapon(player))
		_switchweapon = true;

	if (!(player.weapons & WepSet_FromWeapon(PS(player).m_switchweapon)))
		_switchweapon = true;

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
		WepSet it;
		it = item.weapons;
		it &= ~player.weapons;

		if (it || (item.spawnshieldtime && item.pickup_anyway > 0))
		{
			pickedup = true;
			for(i = WEP_FIRST; i <= WEP_LAST; ++i)
			if(it & WepSet_FromWeapon(Weapons_from(i)))
			{
				W_DropEvent(wr_pickup, player, i, item);
				W_GiveWeapon(player, i);
			}
		}
	}

	if((it = (item.items - (item.items & player.items)) & IT_PICKUPMASK))
	{
		pickedup = true;
		player.items |= it;
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

:skip

	// always eat teamed entities
	if(item.team)
		pickedup = true;

	if (!pickedup)
		return 0;

	// crude hack to enforce switching weapons
	if(g_cts && item.itemdef.instanceOfWeaponPickup)
	{
		W_SwitchWeapon_Force(player, Weapons_from(item.weapon));
		return 1;
	}

	if (_switchweapon)
		if (PS(player).m_switchweapon != w_getbestweapon(player))
			W_SwitchWeapon_Force(player, w_getbestweapon(player));

	return 1;
}

void Item_Touch()
{
	SELFPARAM();

	// remove the item if it's currnetly in a NODROP brush or hits a NOIMPACT surface (such as sky)
	if (this.classname == "droppedweapon")
	{
		if (ITEM_TOUCH_NEEDKILL())
		{
			remove(this);
			return;
		}
	}

	if(!(other.flags & FL_PICKUPITEMS)
	|| other.frozen
	|| other.deadflag
	|| (this.solid != SOLID_TRIGGER)
	|| (this.owner == other)
	|| (time < this.item_spawnshieldtime)
	) { return; }

	switch (MUTATOR_CALLHOOK(ItemTouch, this, other))
	{
		case MUT_ITEMTOUCH_RETURN: { return; }
		case MUT_ITEMTOUCH_PICKUP: { goto pickup; }
	}

	if (this.classname == "droppedweapon")
	{
		this.strength_finished = max(0, this.strength_finished - time);
		this.invincible_finished = max(0, this.invincible_finished - time);
		this.superweapons_finished = max(0, this.superweapons_finished - time);
	}
	entity it = this.itemdef;
	bool gave = ITEM_HANDLE(Pickup, it, this, other);
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

	:pickup

	other.last_pickup = time;

	Send_Effect(EFFECT_ITEM_PICKUP, CENTER_OR_VIEWOFS(this), '0 0 0', 1);
	_sound (other, CH_TRIGGER, (this.item_pickupsound ? this.item_pickupsound : Sound_fixpath(this.item_pickupsound_ent)), VOL_BASE, ATTEN_NORM);

	if (this.classname == "droppedweapon")
		remove (this);
	else if (this.spawnshieldtime)
	{
		entity e;
		if(this.team)
		{
			RandomSelection_Init();
			for(entity head = world; (head = findfloat(head, team, this.team)); )
			{
				if(head.flags & FL_ITEM)
				if(head.classname != "item_flag_team" && head.classname != "item_key_team")
				{
					Item_Show(head, -1);
					RandomSelection_Add(head, 0, string_null, head.cnt, 0);
				}
			}
			e = RandomSelection_chosen_ent;

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
		this.think = Item_Think;
		this.nextthink = time;

		if (this.waypointsprite_attached)
			WaypointSprite_Kill(this.waypointsprite_attached);

		if (this.itemdef.instanceOfPowerup || (this.weapons & WEPSET_SUPERWEAPONS)) // do not spawn powerups initially!
			Item_ScheduleInitialRespawn(this);
	}
}
void Item_Reset_self() { SELFPARAM(); Item_Reset(this); }

void Item_FindTeam()
{SELFPARAM();
	entity head, e;

	if(self.effects & EF_NODRAW)
	{
		// marker for item team search
		LOG_TRACE("Initializing item team ", ftos(self.team), "\n");
		RandomSelection_Init();
		for(head = world; (head = findfloat(head, team, self.team)); )
		if(head.flags & FL_ITEM)
		if(head.classname != "item_flag_team" && head.classname != "item_key_team")
			RandomSelection_Add(head, 0, string_null, head.cnt, 0);
		e = RandomSelection_chosen_ent;
		e.state = 0;
		Item_Show(e, 1);

		for(head = world; (head = findfloat(head, team, self.team)); )
		if(head.flags & FL_ITEM)
		if(head.classname != "item_flag_team" && head.classname != "item_key_team")
		{
			if(head != e)
			{
				// make it a non-spawned item
				Item_Show(head, -1);
				head.state = 1; // state 1 = initially hidden item
			}
			head.effects &= ~EF_NODRAW;
		}

		Item_Reset(self);
	}
}

// Savage: used for item garbage-collection
// TODO: perhaps nice special effect?
void RemoveItem()
{SELFPARAM();
	if(wasfreed(self) || !self) { return; }
	Send_Effect(EFFECT_ITEM_PICKUP, CENTER_OR_VIEWOFS(self), '0 0 0', 1);
	remove(self);
}

// pickup evaluation functions
// these functions decide how desirable an item is to the bots

float generic_pickupevalfunc(entity player, entity item) {return item.bot_pickupbasevalue;}

float weapon_pickupevalfunc(entity player, entity item)
{
	float c;

	// See if I have it already
	if(item.weapons & ~player.weapons)
	{
		// If I can pick it up
		if(!item.spawnshieldtime)
			c = 0;
		else if(player.ammo_cells || player.ammo_shells || player.ammo_plasma || player.ammo_nails || player.ammo_rockets)
		{
			// Skilled bots will grab more
			c = bound(0, skill / 10, 1) * 0.5;
		}
		else
			c = 0;
	}
	else
		c = 1;

	// If custom weapon priorities for bots is enabled rate most wanted weapons higher
	if( bot_custom_weapon && c )
	{
		// Find the highest position on any range
		int position = -1;
		for (int j = 0; j < WEP_LAST ; ++j){
			if(
					bot_weapons_far[j] == item.weapon ||
					bot_weapons_mid[j] == item.weapon ||
					bot_weapons_close[j] == item.weapon
			  )
			{
				position = j;
				break;
			}
		}

		// Rate it
		if (position >= 0 )
		{
			position = WEP_LAST - position;
			// item.bot_pickupbasevalue is overwritten here
			return (BOT_PICKUP_RATING_LOW + ( (BOT_PICKUP_RATING_HIGH - BOT_PICKUP_RATING_LOW) * (position / WEP_LAST ))) * c;
		}
	}

	return item.bot_pickupbasevalue * c;
}

float commodity_pickupevalfunc(entity player, entity item)
{
	float c, i;
	float need_shells = false, need_nails = false, need_rockets = false, need_cells = false, need_plasma = false, need_fuel = false;
	entity wi;
	c = 0;

	// Detect needed ammo
	for(i = WEP_FIRST; i <= WEP_LAST ; ++i)
	{
		wi = Weapons_from(i);

		if (!(player.weapons & (wi.m_wepset)))
			continue;

		if(wi.items & ITEM_Shells.m_itemid)
			need_shells = true;
		else if(wi.items & ITEM_Bullets.m_itemid)
			need_nails = true;
		else if(wi.items & ITEM_Rockets.m_itemid)
			need_rockets = true;
		else if(wi.items & ITEM_Cells.m_itemid)
			need_cells = true;
		else if(wi.items & ITEM_Plasma.m_itemid)
			need_plasma = true;
		else if(wi.items & ITEM_JetpackFuel.m_itemid)
			need_fuel = true;
	}

	// TODO: figure out if the player even has the weapon this ammo is for?
	// may not affect strategy much though...
	// find out how much more ammo/armor/health the player can hold
	if (need_shells)
	if (item.ammo_shells)
	if (player.ammo_shells < g_pickup_shells_max)
		c = c + max(0, 1 - player.ammo_shells / g_pickup_shells_max);
	if (need_nails)
	if (item.ammo_nails)
	if (player.ammo_nails < g_pickup_nails_max)
		c = c + max(0, 1 - player.ammo_nails / g_pickup_nails_max);
	if (need_rockets)
	if (item.ammo_rockets)
	if (player.ammo_rockets < g_pickup_rockets_max)
		c = c + max(0, 1 - player.ammo_rockets / g_pickup_rockets_max);
	if (need_cells)
	if (item.ammo_cells)
	if (player.ammo_cells < g_pickup_cells_max)
		c = c + max(0, 1 - player.ammo_cells / g_pickup_cells_max);
	if (need_plasma)
	if (item.ammo_plasma)
	if (player.ammo_plasma < g_pickup_plasma_max)
		c = c + max(0, 1 - player.ammo_plasma / g_pickup_plasma_max);
	if (need_fuel)
	if (item.ammo_fuel)
	if (player.ammo_fuel < g_pickup_fuel_max)
		c = c + max(0, 1 - player.ammo_fuel / g_pickup_fuel_max);
	if (item.armorvalue)
	if (player.armorvalue < item.max_armorvalue)
		c = c + max(0, 1 - player.armorvalue / item.max_armorvalue);
	if (item.health)
	if (player.health < item.max_health)
		c = c + max(0, 1 - player.health / item.max_health);

	return item.bot_pickupbasevalue * c;
}

void Item_Damage(entity inflictor, entity attacker, float damage, int deathtype, vector hitloc, vector force)
{
	if(ITEM_DAMAGE_NEEDKILL(deathtype))
		RemoveItem();
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

	if(!this.respawntime) // both need to be set
	{
		this.respawntime = defaultrespawntime;
		this.respawntimejitter = defaultrespawntimejitter;
	}

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

	if(MUTATOR_CALLHOOK(FilterItem, this)) // error means we do not want the item
	{
		startitem_failed = true;
		remove(this);
		return;
	}

	// is it a dropped weapon?
	if (this.classname == "droppedweapon")
	{
		this.reset = SUB_Remove;
		// it's a dropped weapon
		this.movetype = MOVETYPE_TOSS;

		// Savage: remove thrown items after a certain period of time ("garbage collection")
		this.think = RemoveItem;
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
			remove(this);
			return;
		}
	}
	else
	{
		if(!have_pickup_item(this))
		{
			startitem_failed = true;
			remove (this);
			return;
		}

		if(this.angles != '0 0 0')
			this.SendFlags |= ISF_ANGLES;

		this.reset = Item_Reset;
		// it's a level item
		if(this.spawnflags & 1)
			this.noalign = 1;
		if (this.noalign > 0)
			this.movetype = MOVETYPE_NONE;
		else
			this.movetype = MOVETYPE_TOSS;
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
				WITH(entity, self, this, droptofloor());
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

		if(autocvar_spawn_debug >= 2)
		{
			for(entity otheritem = findradius(this.origin, 3); otheritem; otheritem = otheritem.chain)
			{
			    // why not flags & fl_item?
				if(otheritem.is_item)
				{
					LOG_TRACE("XXX Found duplicated item: ", itemname, vtos(this.origin));
					LOG_TRACE(" vs ", otheritem.netname, vtos(otheritem.origin), "\n");
					error("Mapper sucks.");
				}
			}
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
	this.touch = Item_Touch;
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
		this.ItemStatus |= ISF_COLORMAP;
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
		remove(this);
		return;
	}
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

spawnfunc(item_rockets)
{
	if(!this.ammo_rockets)
		this.ammo_rockets = g_pickup_rockets;
	if(!this.pickup_anyway)
		this.pickup_anyway = g_pickup_ammo_anyway;
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

	if(!this.ammo_nails)
		this.ammo_nails = g_pickup_nails;
	if(!this.pickup_anyway)
		this.pickup_anyway = g_pickup_ammo_anyway;
    StartItem(this, ITEM_Bullets);
}

spawnfunc(item_cells)
{
	if(!this.ammo_cells)
		this.ammo_cells = g_pickup_cells;
	if(!this.pickup_anyway)
		this.pickup_anyway = g_pickup_ammo_anyway;
	StartItem(this, ITEM_Cells);
}

spawnfunc(item_plasma)
{
	if(!this.ammo_plasma)
		this.ammo_plasma = g_pickup_plasma;
	if(!this.pickup_anyway)
		this.pickup_anyway = g_pickup_ammo_anyway;
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

	if(!this.ammo_shells)
		this.ammo_shells = g_pickup_shells;
	if(!this.pickup_anyway)
		this.pickup_anyway = g_pickup_ammo_anyway;
	StartItem(this, ITEM_Shells);
}

spawnfunc(item_armor_small)
{
	if(!this.armorvalue)
		this.armorvalue = g_pickup_armorsmall;
	if(!this.max_armorvalue)
		this.max_armorvalue = g_pickup_armorsmall_max;
	if(!this.pickup_anyway)
		this.pickup_anyway = g_pickup_armorsmall_anyway;
	StartItem(this, ITEM_ArmorSmall);
}

spawnfunc(item_armor_medium)
{
	if(!this.armorvalue)
		this.armorvalue = g_pickup_armormedium;
	if(!this.max_armorvalue)
		this.max_armorvalue = g_pickup_armormedium_max;
	if(!this.pickup_anyway)
		this.pickup_anyway = g_pickup_armormedium_anyway;
	StartItem(this, ITEM_ArmorMedium);
}

spawnfunc(item_armor_big)
{
	if(!this.armorvalue)
		this.armorvalue = g_pickup_armorbig;
	if(!this.max_armorvalue)
		this.max_armorvalue = g_pickup_armorbig_max;
	if(!this.pickup_anyway)
		this.pickup_anyway = g_pickup_armorbig_anyway;
	StartItem(this, ITEM_ArmorLarge);
}

spawnfunc(item_armor_large)
{
	if(!this.armorvalue)
		this.armorvalue = g_pickup_armorlarge;
	if(!this.max_armorvalue)
		this.max_armorvalue = g_pickup_armorlarge_max;
	if(!this.pickup_anyway)
		this.pickup_anyway = g_pickup_armorlarge_anyway;
	StartItem(this, ITEM_ArmorMega);
}

spawnfunc(item_health_small)
{
	if(!this.max_health)
		this.max_health = g_pickup_healthsmall_max;
	if(!this.health)
		this.health = g_pickup_healthsmall;
	if(!this.pickup_anyway)
		this.pickup_anyway = g_pickup_healthsmall_anyway;
	StartItem(this, ITEM_HealthSmall);
}

spawnfunc(item_health_medium)
{
	if(!this.max_health)
		this.max_health = g_pickup_healthmedium_max;
	if(!this.health)
		this.health = g_pickup_healthmedium;
	if(!this.pickup_anyway)
		this.pickup_anyway = g_pickup_healthmedium_anyway;
    StartItem(this, ITEM_HealthMedium);
}

spawnfunc(item_health_large)
{
	if(!this.max_health)
		this.max_health = g_pickup_healthlarge_max;
	if(!this.health)
		this.health = g_pickup_healthlarge;
	if(!this.pickup_anyway)
		this.pickup_anyway = g_pickup_healthlarge_anyway;
	StartItem(this, ITEM_HealthLarge);
}

spawnfunc(item_health_mega)
{
    if(!this.max_health)
        this.max_health = g_pickup_healthmega_max;
    if(!this.health)
        this.health = g_pickup_healthmega;
    if(!this.pickup_anyway)
        this.pickup_anyway = g_pickup_healthmega_anyway;
    StartItem(this, ITEM_HealthMega);
}

// support old misnamed entities
spawnfunc(item_armor1) { spawnfunc_item_armor_small(this); }  // FIXME: in Quake this is green armor, in Xonotic maps it is an armor shard
spawnfunc(item_armor25) { spawnfunc_item_armor_large(this); }
spawnfunc(item_health1) { spawnfunc_item_health_small(this); }
spawnfunc(item_health25) { spawnfunc_item_health_medium(this); }
spawnfunc(item_health100) { spawnfunc_item_health_mega(this); }

spawnfunc(item_strength)
{
		if(!this.strength_finished)
			this.strength_finished = autocvar_g_balance_powerup_strength_time;
		StartItem(this, ITEM_Strength);
}

spawnfunc(item_invincible)
{
		if(!this.invincible_finished)
			this.invincible_finished = autocvar_g_balance_powerup_invincible_time;
		StartItem(this, ITEM_Shield);
}

// compatibility:
spawnfunc(item_quad) { this.classname = "item_strength";spawnfunc_item_strength(this);}

void target_items_use()
{SELFPARAM();
	if(activator.classname == "droppedweapon")
	{
		EXACTTRIGGER_TOUCH;
		remove(activator);
		return;
	}

	if (!IS_PLAYER(activator))
		return;
	if(activator.deadflag != DEAD_NO)
		return;
	EXACTTRIGGER_TOUCH;

	entity e;
	for(e = world; (e = find(e, classname, "droppedweapon")); )
		if(e.enemy == activator)
			remove(e);

	if(GiveItems(activator, 0, tokenize_console(self.netname)))
		centerprint(activator, self.message);
}

spawnfunc(target_items)
{
	float n, i, j;
	entity e;
	string s;

	self.use = target_items_use;
	if(!self.strength_finished)
		self.strength_finished = autocvar_g_balance_powerup_strength_time;
	if(!self.invincible_finished)
		self.invincible_finished = autocvar_g_balance_powerup_invincible_time;
	if(!self.superweapons_finished)
		self.superweapons_finished = autocvar_g_balance_superweapons_time;

	n = tokenize_console(self.netname);
	if(argv(0) == "give")
	{
		self.netname = substring(self.netname, argv_start_index(1), argv_end_index(-1) - argv_start_index(1));
	}
	else
	{
		for(i = 0; i < n; ++i)
		{
			if     (argv(i) == "unlimited_ammo")         self.items |= IT_UNLIMITED_AMMO;
			else if(argv(i) == "unlimited_weapon_ammo")  self.items |= IT_UNLIMITED_WEAPON_AMMO;
			else if(argv(i) == "unlimited_superweapons") self.items |= IT_UNLIMITED_SUPERWEAPONS;
			else if(argv(i) == "strength")               self.items |= ITEM_Strength.m_itemid;
			else if(argv(i) == "invincible")             self.items |= ITEM_Shield.m_itemid;
			else if(argv(i) == "superweapons")           self.items |= IT_SUPERWEAPON;
			else if(argv(i) == "jetpack")                self.items |= ITEM_Jetpack.m_itemid;
			else if(argv(i) == "fuel_regen")             self.items |= ITEM_JetpackRegen.m_itemid;
			else
			{
				for(j = WEP_FIRST; j <= WEP_LAST; ++j)
				{
					e = Weapons_from(j);
					s = W_UndeprecateName(argv(i));
					if(s == e.netname)
					{
						self.weapons |= (e.m_wepset);
						if(self.spawnflags == 0 || self.spawnflags == 2) {
							e.wr_init(e);
						}
						break;
					}
				}
				if(j > WEP_LAST)
					LOG_INFO("target_items: invalid item ", argv(i), "\n");
			}
		}

		string itemprefix, valueprefix;
		if(self.spawnflags == 0)
		{
			itemprefix = "";
			valueprefix = "";
		}
		else if(self.spawnflags == 1)
		{
			itemprefix = "max ";
			valueprefix = "max ";
		}
		else if(self.spawnflags == 2)
		{
			itemprefix = "min ";
			valueprefix = "min ";
		}
		else if(self.spawnflags == 4)
		{
			itemprefix = "minus ";
			valueprefix = "max ";
		}
		else
		{
			error("invalid spawnflags");
			itemprefix = valueprefix = string_null;
		}

		self.netname = "";
		self.netname = sprintf("%s %s%d %s", self.netname, itemprefix, boolean(self.items & IT_UNLIMITED_WEAPON_AMMO), "unlimited_weapon_ammo");
		self.netname = sprintf("%s %s%d %s", self.netname, itemprefix, boolean(self.items & IT_UNLIMITED_SUPERWEAPONS), "unlimited_superweapons");
		self.netname = sprintf("%s %s%d %s", self.netname, valueprefix, self.strength_finished * boolean(self.items & ITEM_Strength.m_itemid), "strength");
		self.netname = sprintf("%s %s%d %s", self.netname, valueprefix, self.invincible_finished * boolean(self.items & ITEM_Shield.m_itemid), "invincible");
		self.netname = sprintf("%s %s%d %s", self.netname, valueprefix, self.superweapons_finished * boolean(self.items & IT_SUPERWEAPON), "superweapons");
		self.netname = sprintf("%s %s%d %s", self.netname, itemprefix, boolean(self.items & ITEM_Jetpack.m_itemid), "jetpack");
		self.netname = sprintf("%s %s%d %s", self.netname, itemprefix, boolean(self.items & ITEM_JetpackRegen.m_itemid), "fuel_regen");
		if(self.ammo_shells != 0) self.netname = sprintf("%s %s%d %s", self.netname, valueprefix, max(0, self.ammo_shells), "shells");
		if(self.ammo_nails != 0) self.netname = sprintf("%s %s%d %s", self.netname, valueprefix, max(0, self.ammo_nails), "nails");
		if(self.ammo_rockets != 0) self.netname = sprintf("%s %s%d %s", self.netname, valueprefix, max(0, self.ammo_rockets), "rockets");
		if(self.ammo_cells != 0) self.netname = sprintf("%s %s%d %s", self.netname, valueprefix, max(0, self.ammo_cells), "cells");
		if(self.ammo_plasma != 0) self.netname = sprintf("%s %s%d %s", self.netname, valueprefix, max(0, self.ammo_plasma), "plasma");
		if(self.ammo_fuel != 0) self.netname = sprintf("%s %s%d %s", self.netname, valueprefix, max(0, self.ammo_fuel), "fuel");
		if(self.health != 0) self.netname = sprintf("%s %s%d %s", self.netname, valueprefix, max(0, self.health), "health");
		if(self.armorvalue != 0) self.netname = sprintf("%s %s%d %s", self.netname, valueprefix, max(0, self.health), "armor");
		for(j = WEP_FIRST; j <= WEP_LAST; ++j)
		{
			e = Weapons_from(j);
			if(e == WEP_Null) continue;
			self.netname = sprintf("%s %s%d %s", self.netname, itemprefix, !!(self.weapons & (e.m_wepset)), e.netname);
		}
	}
	self.netname = strzone(self.netname);
	//print(self.netname, "\n");

	n = tokenize_console(self.netname);
	for(i = 0; i < n; ++i)
	{
		for(j = WEP_FIRST; j <= WEP_LAST; ++j)
		{
			e = Weapons_from(j);
			if(argv(i) == e.netname)
			{
				e.wr_init(e);
				break;
			}
		}
	}
}

spawnfunc(item_fuel)
{
	if(!this.ammo_fuel)
		this.ammo_fuel = g_pickup_fuel;
	if(!this.pickup_anyway)
		this.pickup_anyway = g_pickup_ammo_anyway;
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
	if(!this.ammo_fuel)
		this.ammo_fuel = g_pickup_fuel_jetpack;
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

void GiveSound(entity e, float v0, float v1, float t, string snd_incr, string snd_decr)
{
	if(v1 == v0)
		return;
	if(v1 <= v0 - t)
	{
		if(snd_decr != "")
			_sound (e, CH_TRIGGER, snd_decr, VOL_BASE, ATTEN_NORM);
	}
	else if(v0 >= v0 + t)
	{
		if(snd_incr != "")
			_sound (e, CH_TRIGGER, snd_incr, VOL_BASE, ATTEN_NORM);
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
{SELFPARAM();
	float got, i, j, val, op;
	float _switchweapon;
	entity wi;
	string cmd;

	val = 999;
	op = OP_SET;

	got = 0;

	_switchweapon = false;
	if (e.autoswitch)
		if (PS(e).m_switchweapon == w_getbestweapon(e))
			_switchweapon = true;

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
				for(j = WEP_FIRST; j <= WEP_LAST; ++j)
				{
					wi = Weapons_from(j);
					if(wi == WEP_Null) continue;
					if (!(wi.spawnflags & WEP_FLAG_MUTATORBLOCKED))
						got += GiveWeapon(e, j, op, val);
				}
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
				for(j = WEP_FIRST; j <= WEP_LAST; ++j)
				{
					wi = Weapons_from(j);
					if(cmd == wi.netname)
					{
						got += GiveWeapon(e, j, op, val);
						break;
					}
				}
				if(j > WEP_LAST)
					LOG_INFO("give: invalid item ", cmd, "\n");
				break;
		}
		val = 999;
		op = OP_SET;
	}

	POSTGIVE_BIT(e, items, ITEM_JetpackRegen.m_itemid, SND(ITEMPICKUP), string_null);
	POSTGIVE_BIT(e, items, IT_UNLIMITED_SUPERWEAPONS, SND(POWERUP), SND(POWEROFF));
	POSTGIVE_BIT(e, items, IT_UNLIMITED_WEAPON_AMMO, SND(POWERUP), SND(POWEROFF));
	POSTGIVE_BIT(e, items, ITEM_Jetpack.m_itemid, SND(ITEMPICKUP), string_null);
	for(j = WEP_FIRST; j <= WEP_LAST; ++j)
	{
		wi = Weapons_from(j);
		if (wi == WEP_Null) continue;
		POSTGIVE_WEAPON(e, Weapons_from(j), SND(WEAPONPICKUP), string_null);
		if (!(save_weapons & (wi.m_wepset)))
			if(e.weapons & (wi.m_wepset)) {
				wi.wr_init(wi);
			}
	}
	POSTGIVE_VALUE(e, strength_finished, 1, SND(POWERUP), SND(POWEROFF));
	POSTGIVE_VALUE(e, invincible_finished, 1, "misc/powerup_shield.wav", SND(POWEROFF));
	POSTGIVE_VALUE(e, ammo_nails, 0, SND(ITEMPICKUP), string_null);
	POSTGIVE_VALUE(e, ammo_cells, 0, SND(ITEMPICKUP), string_null);
	POSTGIVE_VALUE(e, ammo_plasma, 0, SND(ITEMPICKUP), string_null);
	POSTGIVE_VALUE(e, ammo_shells, 0, SND(ITEMPICKUP), string_null);
	POSTGIVE_VALUE(e, ammo_rockets, 0, SND(ITEMPICKUP), string_null);
	POSTGIVE_VALUE_ROT(e, ammo_fuel, 1, pauserotfuel_finished, autocvar_g_balance_pause_fuel_rot, pauseregen_finished, autocvar_g_balance_pause_fuel_regen, SND(ITEMPICKUP), string_null);
	POSTGIVE_VALUE_ROT(e, armorvalue, 1, pauserotarmor_finished, autocvar_g_balance_pause_armor_rot, pauseregen_finished, autocvar_g_balance_pause_health_regen, SND(ARMOR25), string_null);
	POSTGIVE_VALUE_ROT(e, health, 1, pauserothealth_finished, autocvar_g_balance_pause_health_rot, pauseregen_finished, autocvar_g_balance_pause_health_regen, SND(MEGAHEALTH), string_null);

	if(e.superweapons_finished <= 0)
		if(self.weapons & WEPSET_SUPERWEAPONS)
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

	if (!(e.weapons & WepSet_FromWeapon(PS(e).m_switchweapon)))
		_switchweapon = true;
	if(_switchweapon)
		W_SwitchWeapon_Force(e, w_getbestweapon(e));

	return got;
}
#endif
