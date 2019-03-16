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
	#include "mapobjects/subs.qh"
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
.bool item_simple; // probably not really needed, but better safe than sorry
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
		this.alpha = autocvar_cl_ghost_items;
		this.colormod = this.glowmod = autocvar_cl_ghost_items_color;
	}

	if((!veh_hud) && (this.ItemStatus & ITS_STAYWEP))
	{
		this.colormod = this.glowmod = autocvar_cl_weapon_stay_color;
		this.alpha = autocvar_cl_weapon_stay_alpha;
	}

	this.drawmask = ((this.alpha <= 0) ? 0 : MASK_NORMAL);
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
        	if(!this.item_simple)
            	this.angles += this.avelocity * frametime;
            float fade_in = bound(0, time - this.onground_time, 1);
            setorigin(this, this.oldorigin + fade_in * ('0 0 10' + '0 0 8' * sin((time - this.onground_time) * 2)));
        }

        if(this.ItemStatus & ITS_ANIMATE2)
        {
        	if(!this.item_simple)
            	this.angles += this.avelocity * frametime;
            float fade_in = bound(0, time - this.onground_time, 1);
            setorigin(this, this.oldorigin + fade_in * ('0 0 8' + '0 0 4' * sin((time - this.onground_time) * 3)));
        }
    }

    Item_SetAlpha(this);
}

void Item_PreDraw(entity this)
{
	if(warpzone_warpzones_exist)
	{
		setpredraw(this, func_null); // no need to keep running this
		return;
	}
	float alph;
	vector org = getpropertyvec(VF_ORIGIN);
	//if(!checkpvs(org, this)) // this makes sense as long as we don't support recursive warpzones
		//alph = 0; // this shouldn't be needed, since items behind walls are culled anyway
	if(this.fade_start)
	{
		if(vdist(org - this.origin, >, this.fade_end))
			alph = 0; // save on some processing
		else if(vdist(org - this.origin, <, this.fade_start))
			alph = 1; // more processing saved
		else
			alph = bound(0, (this.fade_end - vlen(org - this.origin - 0.5 * (this.mins + this.maxs))) / (this.fade_end - this.fade_start), 1);
	}
	else
		alph = 1;
	//printf("%v <-> %v\n", view_origin, this.origin + 0.5 * (this.mins + this.maxs));
	if(!hud && (this.ItemStatus & ITS_AVAILABLE))
		this.alpha = alph;
	if(alph <= 0)
		this.drawmask = 0;
	//else
		//this.drawmask = MASK_NORMAL; // reset by the setalpha function
}

void ItemRemove(entity this)
{
	strfree(this.mdl);
}

HashMap ENT_CLIENT_ITEM_simple;
STATIC_INIT(ENT_CLIENT_ITEM_simple)
{
	HM_NEW(ENT_CLIENT_ITEM_simple);
}
SHUTDOWN(ENT_CLIENT_ITEM_simple)
{
	HM_DELETE(ENT_CLIENT_ITEM_simple);
}

NET_HANDLE(ENT_CLIENT_ITEM, bool isnew)
{
    int sf = ReadByte();

    if(sf & ISF_LOCATION)
    {
        this.origin = ReadVector();
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

    if(sf & ISF_STATUS) // need to read/write status first so model can handle simple, fb etc.
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
        if(!warpzone_warpzones_exist && this.fade_start && !autocvar_cl_items_nofade)
        	setpredraw(this, Item_PreDraw);

		strfree(this.mdl);

        string _fn = ReadString();
        this.item_simple = false; // reset it!

        if(autocvar_cl_simple_items && (this.ItemStatus & ITS_ALLOWSI))
        {
            string _fn2 = substring(_fn, 0 , strlen(_fn) -4);
            this.item_simple = true;

			#define extensions(x) \
				x(md3) \
				x(dpm) \
				x(iqm) \
				x(mdl) \
				/**/
			#define tryext(ext) { \
				string s = strcat(_fn2, autocvar_cl_simpleitems_postfix, "." #ext); \
				string cached = HM_gets(ENT_CLIENT_ITEM_simple, s); \
				if (cached == "") { \
					HM_sets(ENT_CLIENT_ITEM_simple, s, cached = fexists(s) ? "1" : "0"); \
				} \
				if (cached != "0") { \
					strcpy(this.mdl, s); \
					break; \
				} \
			}
			do {
				extensions(tryext);
				this.item_simple = false;
                LOG_TRACEF("Simple item requested for %s but no model exists for it", _fn);
			} while (0);
			#undef tryext
			#undef extensions
        }

        if(!this.item_simple)
            strcpy(this.mdl, _fn);

        if(this.mdl == "")
            LOG_WARNF("this.mdl is unset for item %s", this.classname);

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
        this.velocity = ReadVector();
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
		WriteVector(MSG_ENTITY, this.origin);
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
			if(STAT(WEAPONS, this) || this.itemdef.instanceOfAmmo) // no item or ammo pickups in weaponarena
				return false;
	}
	return true;
}

void Item_Show (entity e, int mode)
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
			//setmodel(e, "null");
			e.solid = SOLID_NOT;
			e.colormod = '0 0 0';
			//e.glowmod = e.colormod;
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

    if (Item_ItemsTime_Allow(this.itemdef) || (STAT(WEAPONS, this) & WEPSET_SUPERWEAPONS))
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

AUTOCVAR(g_pickup_respawntime_scaling_reciprocal, float, 0.0, "Multiply respawn time by `reciprocal / (p + offset) + linear` where `p` is the current number of players, takes effect with 2 or more players present, `reciprocal` (with `offset` and `linear` set to 0) can be used to achieve a constant number of items spawned *per player*");
AUTOCVAR(g_pickup_respawntime_scaling_offset, float, 0.0, "Multiply respawn time by `reciprocal / (p + offset) + linear` where `p` is the current number of players, takes effect with 2 or more players present, `offset` offsets the curve left or right - the results are not intuitive and I recommend plotting the respawn time and the number of items per player to see what's happening");
AUTOCVAR(g_pickup_respawntime_scaling_linear, float, 1.0, "Multiply respawn time by `reciprocal / (p + offset) + linear` where `p` is the current number of players, takes effect with 2 or more players present, `linear` can be used to simply scale the respawn time linearly");

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
	"For items that don't start spawned: 0: spawn after their normal respawntime; 1: spawn after `random * respawntime` with the *same* random; 2: same as 1 but each item has separate random");

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

bool Item_GiveAmmoTo(entity item, entity player, int res_type, float ammomax)
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
		ammomax = min(amount, ammomax);
	else
		return false;
	if (amount < 0)
		TakeResourceWithLimit(player, res_type, -amount, ammomax);
	else
		GiveResourceWithLimit(player, res_type, amount, ammomax);
	return true;
}

bool Item_GiveTo(entity item, entity player)
{
	// if nothing happens to player, just return without taking the item
	int _switchweapon = 0;
	// in case the player has autoswitch enabled do the following:
	// if the player is using their best weapon before items are given, they
	// probably want to switch to an even better weapon after items are given

	if(CS(player).autoswitch)
	{
		for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
		{
			.entity weaponentity = weaponentities[slot];
			if(player.(weaponentity).m_weapon != WEP_Null || slot == 0)
			{
				if(player.(weaponentity).m_switchweapon == w_getbestweapon(player, weaponentity))
					_switchweapon |= BIT(slot);

				if(!(STAT(WEAPONS, player) & WepSet_FromWeapon(player.(weaponentity).m_switchweapon)))
					_switchweapon |= BIT(slot);
			}
		}
	}
	bool pickedup = false;
	pickedup = (pickedup || Item_GiveAmmoTo(item, player, RES_HEALTH, item.max_health));
	pickedup = (pickedup || Item_GiveAmmoTo(item, player, RES_ARMOR, item.max_armorvalue));
	pickedup = (pickedup || Item_GiveAmmoTo(item, player, RES_SHELLS, g_pickup_shells_max));
	pickedup = (pickedup || Item_GiveAmmoTo(item, player, RES_BULLETS, g_pickup_nails_max));
	pickedup = (pickedup || Item_GiveAmmoTo(item, player, RES_ROCKETS, g_pickup_rockets_max));
	pickedup = (pickedup || Item_GiveAmmoTo(item, player, RES_CELLS, g_pickup_cells_max));
	pickedup = (pickedup || Item_GiveAmmoTo(item, player, RES_PLASMA, g_pickup_plasma_max));
	pickedup = (pickedup || Item_GiveAmmoTo(item, player, RES_FUEL, g_pickup_fuel_max));
	if (item.itemdef.instanceOfWeaponPickup)
	{
		WepSet w;
		w = STAT(WEAPONS, item);
		w &= ~STAT(WEAPONS, player);

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
		// TODO: we probably want to show a message in the console, but not this one!
		//Send_Notification(NOTIF_ONE, player, MSG_INFO, INFO_ITEM_WEAPON_GOT, item.netname);
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

	// always eat teamed entities
	if(item.team)
		pickedup = true;

	if (!pickedup)
		return false;

	// crude hack to enforce switching weapons
	if(g_cts && item.itemdef.instanceOfWeaponPickup && !CS(player).cvar_cl_cts_noautoswitch)
	{
		for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
		{
			.entity weaponentity = weaponentities[slot];
			if(player.(weaponentity).m_weapon != WEP_Null || slot == 0)
				W_SwitchWeapon_Force(player, Weapons_from(item.weapon), weaponentity);
		}
		return true;
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

	return true;
}

void Item_Touch(entity this, entity toucher)
{
	// remove the item if it's currnetly in a NODROP brush or hits a NOIMPACT surface (such as sky)
	if (Item_IsLoot(this))
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

	if (Item_IsExpiring(this))
	{
		this.strength_finished = max(0, this.strength_finished - time);
		this.invincible_finished = max(0, this.invincible_finished - time);
		this.superweapons_finished = max(0, this.superweapons_finished - time);
	}
	bool gave = ITEM_HANDLE(Pickup, this.itemdef, this, toucher);
	if (!gave)
	{
		if (Item_IsExpiring(this))
		{
			// undo what we did above
			this.strength_finished += time;
			this.invincible_finished += time;
			this.superweapons_finished += time;
		}
		return;
	}

LABEL(pickup)

	STAT(LAST_PICKUP, toucher) = time;

	Send_Effect(EFFECT_ITEM_PICKUP, CENTER_OR_VIEWOFS(this), '0 0 0', 1);
	_sound (toucher, (this.itemdef.instanceOfPowerup ? CH_TRIGGER_SINGLE : CH_TRIGGER), (this.item_pickupsound ? this.item_pickupsound : Sound_fixpath(this.item_pickupsound_ent)), VOL_BASE, ATTEN_NORM);

	MUTATOR_CALLHOOK(ItemTouched, this, toucher);
	if (wasfreed(this))
	{
		return;
	}

	if (Item_IsLoot(this))
	{
		delete(this);
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
	setorigin(this, this.origin);

	if (Item_IsLoot(this))
	{
		return;
	}
	setthink(this, Item_Think);
	this.nextthink = time;
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
	bool need_shells = false, need_nails = false, need_rockets = false, need_cells = false, need_plasma = false, need_fuel = false;
	entity wpn = NULL;
	float c = 0;
	float rating = 0;

	// Detect needed ammo
	if(item.itemdef.instanceOfWeaponPickup)
	{
		entity ammo = NULL;
		if(GetResource(item, RES_SHELLS))       { need_shells  = true; ammo = ITEM_Shells;      }
		else if(GetResource(item, RES_BULLETS))   { need_nails   = true; ammo = ITEM_Bullets;     }
		else if(GetResource(item, RES_ROCKETS)) { need_rockets = true; ammo = ITEM_Rockets;     }
		else if(GetResource(item, RES_CELLS))   { need_cells   = true; ammo = ITEM_Cells;       }
		else if(GetResource(item, RES_PLASMA))  { need_plasma  = true; ammo = ITEM_Plasma;      }
		else if(GetResource(item, RES_FUEL))    { need_fuel    = true; ammo = ITEM_JetpackFuel; }

		if(!ammo)
			return 0;
		wpn = item;
		rating = ammo.m_botvalue;
	}
	else
	{
		FOREACH(Weapons, it != WEP_Null, {
			if(!(STAT(WEAPONS, player) & (it.m_wepset)))
				continue;

			switch(it.ammo_type)
			{
				case RES_SHELLS:  need_shells  = true; break;
				case RES_BULLETS: need_nails   = true; break;
				case RES_ROCKETS: need_rockets = true; break;
				case RES_CELLS:   need_cells   = true; break;
				case RES_PLASMA:  need_plasma  = true; break;
				case RES_FUEL:    need_fuel    = true; break;
			}
		});
		rating = item.bot_pickupbasevalue;
	}

	float noammorating = 0.5;

	if ((need_shells) && GetResource(item, RES_SHELLS) && (GetResource(player, RES_SHELLS) < g_pickup_shells_max))
		c = GetResource(item, RES_SHELLS) / max(noammorating, GetResource(player, RES_SHELLS));

	if ((need_nails) && GetResource(item, RES_BULLETS) && (GetResource(player, RES_BULLETS) < g_pickup_nails_max))
		c = GetResource(item, RES_BULLETS) / max(noammorating, GetResource(player, RES_BULLETS));

	if ((need_rockets) && GetResource(item, RES_ROCKETS) && (GetResource(player, RES_ROCKETS) < g_pickup_rockets_max))
		c = GetResource(item, RES_ROCKETS) / max(noammorating, GetResource(player, RES_ROCKETS));

	if ((need_cells) && GetResource(item, RES_CELLS) && (GetResource(player, RES_CELLS) < g_pickup_cells_max))
		c = GetResource(item, RES_CELLS) / max(noammorating, GetResource(player, RES_CELLS));

	if ((need_plasma) && GetResource(item, RES_PLASMA) && (GetResource(player, RES_PLASMA) < g_pickup_plasma_max))
		c = GetResource(item, RES_PLASMA) / max(noammorating, GetResource(player, RES_PLASMA));

	if ((need_fuel) && GetResource(item, RES_FUEL) && (GetResource(player, RES_FUEL) < g_pickup_fuel_max))
		c = GetResource(item, RES_FUEL) / max(noammorating, GetResource(player, RES_FUEL));

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
    	def.m_iteminit(def, this);

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
		STAT(WEAPONS, this) = WepSet_FromWeapon(Weapons_from(weaponid));

	this.flags = FL_ITEM | itemflags;
	IL_PUSH(g_items, this);

	if(MUTATOR_CALLHOOK(FilterItem, this)) // error means we do not want the item
	{
		startitem_failed = true;
		delete(this);
		return;
	}

	if (Item_IsLoot(this))
	{
		this.reset = SUB_Remove;
		set_movetype(this, MOVETYPE_TOSS);

		// Savage: remove thrown items after a certain period of time ("garbage collection")
		setthink(this, RemoveItem);
		this.nextthink = time + 20;

		this.takedamage = DAMAGE_YES;
		this.event_damage = Item_Damage;

		if (Item_IsExpiring(this))
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
			delete(this);
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
			delete(this);
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
		) this.target = "###item###"; // for finding the nearest item using findnearest

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

		if(GetResource(this, RES_ARMOR) || GetResource(this, RES_HEALTH))
			this.ItemStatus |= ITS_ANIMATE2;
	}

	if(def.instanceOfWeaponPickup)
	{
		if (!Item_IsLoot(this)) // if dropped, colormap is already set up nicely
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
    def = def.m_spawnfunc_hookreplace(def, this);
    if (def.spawnflags & ITEM_FLAG_MUTATORBLOCKED)
    {
        delete(this);
        return;
    }
    this.classname = def.m_canonical_spawnfunc;
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
	if(!IS_SMALL(this.itemdef) || Item_IsLoot(this))
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

void target_items_use(entity this, entity actor, entity trigger)
{
	if(Item_IsLoot(actor))
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

	IL_EACH(g_items, it.enemy == actor && Item_IsLoot(it),
	{
		delete(it);
	});

	if(GiveItems(actor, 0, tokenize_console(this.netname)))
		centerprint(actor, this.message);
}

spawnfunc(target_items)
{
	int n;
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
		for(int j = 0; j < n; ++j)
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
						STAT(BUFFS, this) |= (it.m_itemid);
						break;
					}
				});
				FOREACH(Weapons, it != WEP_Null, {
					s = W_UndeprecateName(argv(j));
					if(s == it.netname)
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

		this.netname = "";
		this.netname = sprintf("%s %s%d %s", this.netname, itemprefix, boolean(this.items & IT_UNLIMITED_WEAPON_AMMO), "unlimited_weapon_ammo");
		this.netname = sprintf("%s %s%d %s", this.netname, itemprefix, boolean(this.items & IT_UNLIMITED_SUPERWEAPONS), "unlimited_superweapons");
		this.netname = sprintf("%s %s%d %s", this.netname, valueprefix, this.strength_finished * boolean(this.items & ITEM_Strength.m_itemid), "strength");
		this.netname = sprintf("%s %s%d %s", this.netname, valueprefix, this.invincible_finished * boolean(this.items & ITEM_Shield.m_itemid), "invincible");
		this.netname = sprintf("%s %s%d %s", this.netname, valueprefix, this.superweapons_finished * boolean(this.items & IT_SUPERWEAPON), "superweapons");
		this.netname = sprintf("%s %s%d %s", this.netname, itemprefix, boolean(this.items & ITEM_Jetpack.m_itemid), "jetpack");
		this.netname = sprintf("%s %s%d %s", this.netname, itemprefix, boolean(this.items & ITEM_JetpackRegen.m_itemid), "fuel_regen");
		if(GetResource(this, RES_SHELLS) != 0) this.netname = sprintf("%s %s%d %s", this.netname, valueprefix, max(0, GetResource(this, RES_SHELLS)), "shells");
		if(GetResource(this, RES_BULLETS) != 0) this.netname = sprintf("%s %s%d %s", this.netname, valueprefix, max(0, GetResource(this, RES_BULLETS)), "nails");
		if(GetResource(this, RES_ROCKETS) != 0) this.netname = sprintf("%s %s%d %s", this.netname, valueprefix, max(0, GetResource(this, RES_ROCKETS)), "rockets");
		if(GetResource(this, RES_CELLS) != 0) this.netname = sprintf("%s %s%d %s", this.netname, valueprefix, max(0, GetResource(this, RES_CELLS)), "cells");
		if(GetResource(this, RES_PLASMA) != 0) this.netname = sprintf("%s %s%d %s", this.netname, valueprefix, max(0, GetResource(this, RES_PLASMA)), "plasma");
		if(GetResource(this, RES_FUEL) != 0) this.netname = sprintf("%s %s%d %s", this.netname, valueprefix, max(0, GetResource(this, RES_FUEL)), "fuel");
		if(GetResource(this, RES_HEALTH) != 0) this.netname = sprintf("%s %s%d %s", this.netname, valueprefix, max(0, GetResource(this, RES_HEALTH)), "health");
		if(GetResource(this, RES_ARMOR) != 0) this.netname = sprintf("%s %s%d %s", this.netname, valueprefix, max(0, GetResource(this, RES_ARMOR)), "armor");
		FOREACH(Buffs, it != BUFF_Null, this.netname = sprintf("%s %s%d %s", this.netname, itemprefix, !!(STAT(BUFFS, this) & (it.m_itemid)), it.m_name));
		FOREACH(Weapons, it != WEP_Null, this.netname = sprintf("%s %s%d %s", this.netname, itemprefix, !!(STAT(WEAPONS, this) & (it.m_wepset)), it.netname));
	}
	this.netname = strzone(this.netname);
	//print(this.netname, "\n");

	n = tokenize_console(this.netname);
	for(int j = 0; j < n; ++j)
	{
		FOREACH(Weapons, it != WEP_Null && W_UndeprecateName(argv(j)) == it.netname, {
            it.wr_init(it);
            break;
		});
	}
}

float GiveWeapon(entity e, float wpn, float op, float val)
{
	WepSet v0, v1;
	WepSet s = WepSet_FromWeapon(Weapons_from(wpn));
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
	bool had_buff = (STAT(BUFFS, e) & thebuff.m_itemid);
	switch(op)
	{
		case OP_SET:
			if(val > 0)
				STAT(BUFFS, e) |= thebuff.m_itemid;
			else
				STAT(BUFFS, e) &= ~thebuff.m_itemid;
			break;
		case OP_MIN:
		case OP_PLUS:
			if(val > 0)
				STAT(BUFFS, e) |= thebuff.m_itemid;
			break;
		case OP_MAX:
			if(val <= 0)
				STAT(BUFFS, e) &= ~thebuff.m_itemid;
			break;
		case OP_MINUS:
			if(val > 0)
				STAT(BUFFS, e) &= ~thebuff.m_itemid;
			break;
	}
	bool have_buff = (STAT(BUFFS, e) & thebuff.m_itemid);
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
bool GiveResourceValue(entity e, int res_type, int op, int val)
{
	int v0 = GetResource(e, res_type);
	switch (op)
	{
		// min 100 cells = at least 100 cells
		case OP_SET: SetResource(e, res_type, val); break;
		case OP_MIN: SetResource(e, res_type, max(v0, val)); break;
		case OP_MAX: SetResource(e, res_type, min(v0, val)); break;
		case OP_PLUS: SetResource(e, res_type, v0 + val); break;
		case OP_MINUS: SetResource(e, res_type, v0 - val); break;
	}
	int v1 = GetResource(e, res_type);
	return v0 != v1;
}

float GiveItems(entity e, float beginarg, float endarg)
{
	float got, i, val, op;
	string cmd;

	val = 999;
	op = OP_SET;

	got = 0;

	int _switchweapon = 0;

	if(CS(e).autoswitch)
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
	PREGIVE_RESOURCE(e, RES_BULLETS);
	PREGIVE_RESOURCE(e, RES_CELLS);
	PREGIVE_RESOURCE(e, RES_PLASMA);
	PREGIVE_RESOURCE(e, RES_SHELLS);
	PREGIVE_RESOURCE(e, RES_ROCKETS);
	PREGIVE_RESOURCE(e, RES_FUEL);
	PREGIVE_RESOURCE(e, RES_ARMOR);
	PREGIVE_RESOURCE(e, RES_HEALTH);

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
				got += GiveResourceValue(e, RES_HEALTH, op, val);
				got += GiveResourceValue(e, RES_ARMOR, op, val);
			case "allweapons":
				FOREACH(Weapons, it != WEP_Null && !(it.spawnflags & WEP_FLAG_MUTATORBLOCKED), got += GiveWeapon(e, it.m_id, op, val));
			//case "allbuffs": // all buffs makes a player god, do not want!
				//FOREACH(Buffs, it != BUFF_Null, got += GiveBuff(e, it.m_itemid, op, val));
			case "allammo":
				got += GiveResourceValue(e, RES_CELLS, op, val);
				got += GiveResourceValue(e, RES_PLASMA, op, val);
				got += GiveResourceValue(e, RES_SHELLS, op, val);
				got += GiveResourceValue(e, RES_BULLETS, op, val);
				got += GiveResourceValue(e, RES_ROCKETS, op, val);
				got += GiveResourceValue(e, RES_FUEL, op, val);
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
				got += GiveResourceValue(e, RES_CELLS, op, val);
				break;
			case "plasma":
				got += GiveResourceValue(e, RES_PLASMA, op, val);
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
			if(STAT(WEAPONS, e) & (it.m_wepset))
				it.wr_init(it);
	});
	POSTGIVE_VALUE(e, strength_finished, 1, SND_POWERUP, SND_POWEROFF);
	POSTGIVE_VALUE(e, invincible_finished, 1, SND_Shield, SND_POWEROFF);
	//POSTGIVE_VALUE(e, superweapons_finished, 1, SND_Null, SND_Null);
	POSTGIVE_RESOURCE(e, RES_BULLETS, 0, SND_ITEMPICKUP, SND_Null);
	POSTGIVE_RESOURCE(e, RES_CELLS, 0, SND_ITEMPICKUP, SND_Null);
	POSTGIVE_RESOURCE(e, RES_PLASMA, 0, SND_ITEMPICKUP, SND_Null);
	POSTGIVE_RESOURCE(e, RES_SHELLS, 0, SND_ITEMPICKUP, SND_Null);
	POSTGIVE_RESOURCE(e, RES_ROCKETS, 0, SND_ITEMPICKUP, SND_Null);
	POSTGIVE_RES_ROT(e, RES_FUEL, 1, pauserotfuel_finished, autocvar_g_balance_pause_fuel_rot, pauseregen_finished, autocvar_g_balance_pause_fuel_regen, SND_ITEMPICKUP, SND_Null);
	POSTGIVE_RES_ROT(e, RES_ARMOR, 1, pauserotarmor_finished, autocvar_g_balance_pause_armor_rot, pauseregen_finished, autocvar_g_balance_pause_health_regen, SND_ARMOR25, SND_Null);
	POSTGIVE_RES_ROT(e, RES_HEALTH, 1, pauserothealth_finished, autocvar_g_balance_pause_health_rot, pauseregen_finished, autocvar_g_balance_pause_health_regen, SND_MEGAHEALTH, SND_Null);

	if(e.superweapons_finished <= 0)
		if(STAT(WEAPONS, e) & WEPSET_SUPERWEAPONS)
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
		if(!(STAT(WEAPONS, e) & WepSet_FromWeapon(e.(weaponentity).m_switchweapon)))
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
