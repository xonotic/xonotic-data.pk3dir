#include "client.qh"

#include "anticheat.qh"
#include "impulse.qh"
#include "player.qh"
#include "ipban.qh"
#include "miscfunctions.qh"
#include "portals.qh"
#include "teamplay.qh"
#include "playerdemo.qh"
#include "spawnpoints.qh"
#include "g_damage.qh"
#include "g_hook.qh"
#include "command/common.qh"
#include "cheats.qh"
#include "g_world.qh"
#include "race.qh"
#include "antilag.qh"
#include "campaign.qh"
#include "command/common.qh"
#include "scores_rules.qh"

#include "bot/api.qh"

#include "../common/ent_cs.qh"
#include "../common/wepent.qh"
#include <common/state.qh>

#include <common/effects/qc/globalsound.qh>

#include "../common/triggers/func/conveyor.qh"
#include "../common/triggers/teleporters.qh"

#include "../common/vehicles/all.qh"

#include "weapons/hitplot.qh"
#include "weapons/weaponsystem.qh"

#include "../common/net_notice.qh"
#include "../common/net_linked.qh"
#include "../common/physics/player.qh"

#include "../common/items/_mod.qh"

#include "../common/mutators/mutator/waypoints/all.qh"

#include "../common/triggers/subs.qh"
#include "../common/triggers/triggers.qh"
#include "../common/triggers/trigger/secret.qh"

#include "../common/minigames/sv_minigames.qh"

#include "../common/items/inventory.qh"

#include "../common/monsters/sv_monsters.qh"

#include "../lib/warpzone/server.qh"

STATIC_METHOD(Client, Add, void(Client this, int _team))
{
    ClientConnect(this);
    TRANSMUTE(Player, this);
    this.frame = 12; // 7
    this.team = _team;
    PutClientInServer(this);
}

void PutObserverInServer(entity this);

STATIC_METHOD(Client, Remove, void(Client this))
{
    TRANSMUTE(Observer, this);
    PutClientInServer(this);
    ClientDisconnect(this);
}

void send_CSQC_teamnagger() {
	WriteHeader(MSG_BROADCAST, TE_CSQC_TEAMNAGGER);
}

int CountSpectators(entity player, entity to)
{
	if(!player) { return 0; } // not sure how, but best to be safe

	int spec_count = 0;

	FOREACH_CLIENT(IS_REAL_CLIENT(it) && IS_SPEC(it) && it != to && it.enemy == player,
	{
		spec_count++;
	});

	return spec_count;
}

void WriteSpectators(entity player, entity to)
{
	if(!player) { return; } // not sure how, but best to be safe

	FOREACH_CLIENT(IS_REAL_CLIENT(it) && IS_SPEC(it) && it != to && it.enemy == player,
	{
		WriteByte(MSG_ENTITY, num_for_edict(it));
	});
}

bool ClientData_Send(entity this, entity to, int sf)
{
	assert(to == this.owner, return false);

	entity e = to;
	if (IS_SPEC(e)) e = e.enemy;

	sf = 0;
	if (e.race_completed)       sf |= 1; // forced scoreboard
	if (to.spectatee_status)    sf |= 2; // spectator ent number follows
	if (e.zoomstate)            sf |= 4; // zoomed
	if (autocvar_sv_showspectators) sf |= 16; // show spectators

	WriteHeader(MSG_ENTITY, ENT_CLIENT_CLIENTDATA);
	WriteByte(MSG_ENTITY, sf);

	if (sf & 2)
	{
		WriteByte(MSG_ENTITY, to.spectatee_status);
	}

	if(sf & 16)
	{
		float specs = CountSpectators(e, to);
		WriteByte(MSG_ENTITY, specs);
		WriteSpectators(e, to);
	}

	return true;
}

void ClientData_Attach(entity this)
{
	Net_LinkEntity(this.clientdata = new_pure(clientdata), false, 0, ClientData_Send);
	this.clientdata.drawonlytoclient = this;
	this.clientdata.owner = this;
}

void ClientData_Detach(entity this)
{
	delete(this.clientdata);
	this.clientdata = NULL;
}

void ClientData_Touch(entity e)
{
	e.clientdata.SendFlags = 1;

	// make it spectatable
	FOREACH_CLIENT(IS_REAL_CLIENT(it) && it != e && IS_SPEC(it) && it.enemy == e, LAMBDA(it.clientdata.SendFlags = 1));
}

.string netname_previous;

void SetSpectatee(entity this, entity spectatee);
void SetSpectatee_status(entity this, int spectatee_num);


/*
=============
CheckPlayerModel

Checks if the argument string can be a valid playermodel.
Returns a valid one in doubt.
=============
*/
string FallbackPlayerModel;
string CheckPlayerModel(string plyermodel) {
	if(FallbackPlayerModel != cvar_defstring("_cl_playermodel"))
	{
		// note: we cannot summon Don Strunzone here, some player may
		// still have the model string set. In case anyone manages how
		// to change a cvar default, we'll have a small leak here.
		FallbackPlayerModel = strzone(cvar_defstring("_cl_playermodel"));
	}
	// only in right path
	if( substring(plyermodel,0,14) != "models/player/")
		return FallbackPlayerModel;
	// only good file extensions
	if(substring(plyermodel,-4,4) != ".zym")
	if(substring(plyermodel,-4,4) != ".dpm")
	if(substring(plyermodel,-4,4) != ".iqm")
	if(substring(plyermodel,-4,4) != ".md3")
	if(substring(plyermodel,-4,4) != ".psk")
		return FallbackPlayerModel;
	// forbid the LOD models
	if(substring(plyermodel, -9,5) == "_lod1")
		return FallbackPlayerModel;
	if(substring(plyermodel, -9,5) == "_lod2")
		return FallbackPlayerModel;
	if(plyermodel != strtolower(plyermodel))
		return FallbackPlayerModel;
	// also, restrict to server models
	if(autocvar_sv_servermodelsonly)
	{
		if(!fexists(plyermodel))
			return FallbackPlayerModel;
	}
	return plyermodel;
}

void setplayermodel(entity e, string modelname)
{
	precache_model(modelname);
	_setmodel(e, modelname);
	player_setupanimsformodel(e);
	if(!autocvar_g_debug_globalsounds)
		UpdatePlayerSounds(e);
}

void FixPlayermodel(entity player);
/** putting a client as observer in the server */
void PutObserverInServer(entity this)
{
    bool mutator_returnvalue = MUTATOR_CALLHOOK(MakePlayerObserver, this);
	PlayerState_detach(this);

	if (IS_PLAYER(this) && this.health >= 1) {
        // despawn effect
		Send_Effect(EFFECT_SPAWN_NEUTRAL, this.origin, '0 0 0', 1);
    }

    {
        entity spot = SelectSpawnPoint(this, true);
        if (!spot) LOG_FATAL("No spawnpoints for observers?!?");
        this.angles = spot.angles;
        this.angles_z = 0;
        this.fixangle = true;
        // offset it so that the spectator spawns higher off the ground, looks better this way
        setorigin(this, spot.origin + STAT(PL_VIEW_OFS, this));
        this.prevorigin = this.origin;
        if (IS_REAL_CLIENT(this))
        {
            msg_entity = this;
            WriteByte(MSG_ONE, SVC_SETVIEW);
            WriteEntity(MSG_ONE, this);
        }
        // give the spectator some space between walls for MOVETYPE_FLY_WORLDONLY
        // so that your view doesn't go into the ceiling with MOVETYPE_FLY_WORLDONLY, previously "PL_VIEW_OFS"
        if(!autocvar_g_debug_globalsounds)
        {
        	// needed for player sounds
        	this.model = "";
	        FixPlayermodel(this);
        }
        setmodel(this, MDL_Null);
        setsize(this, STAT(PL_CROUCH_MIN, this), STAT(PL_CROUCH_MAX, this));
        this.view_ofs = '0 0 0';
    }

    RemoveGrapplingHooks(this);
	Portal_ClearAll(this);
	Unfreeze(this);
	SetSpectatee(this, NULL);

	if (this.alivetime)
	{
		if (!warmup_stage)
			PS_GR_P_ADDVAL(this, PLAYERSTATS_ALIVETIME, time - this.alivetime);
		this.alivetime = 0;
	}

	if (this.vehicle) vehicles_exit(this.vehicle, VHEF_RELEASE);

	WaypointSprite_PlayerDead(this);

	if (mutator_returnvalue) {
	    // mutator prevents resetting teams+score
	} else {
		this.team = -1;  // move this as it is needed to log the player spectating in eventlog
        this.frags = FRAGS_SPECTATOR;
        PlayerScore_Clear(this);  // clear scores when needed
    }

	if (this.killcount != FRAGS_SPECTATOR)
	{
		Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_QUIT_SPECTATE, this.netname);
		if(!game_stopped)
		if(autocvar_g_chat_nospectators == 1 || (!warmup_stage && autocvar_g_chat_nospectators == 2))
			Send_Notification(NOTIF_ONE_ONLY, this, MSG_INFO, INFO_CHAT_NOSPECTATORS);

		if(this.just_joined == false) {
			LogTeamchange(this.playerid, -1, 4);
		} else
			this.just_joined = false;
	}

	accuracy_resend(this);

	this.spectatortime = time;
	if(this.bot_attack)
		IL_REMOVE(g_bot_targets, this);
	this.bot_attack = false;
    this.hud = HUD_NORMAL;
	TRANSMUTE(Observer, this);
	this.iscreature = false;
	this.teleportable = TELEPORT_SIMPLE;
	if(this.damagedbycontents)
		IL_REMOVE(g_damagedbycontents, this);
	this.damagedbycontents = false;
	this.health = FRAGS_SPECTATOR;
	SetSpectatee_status(this, etof(this));
	this.takedamage = DAMAGE_NO;
	this.solid = SOLID_NOT;
	set_movetype(this, MOVETYPE_FLY_WORLDONLY); // user preference is controlled by playerprethink
	this.flags = FL_CLIENT | FL_NOTARGET;
	this.armorvalue = 666;
	this.effects = 0;
	this.armorvalue = autocvar_g_balance_armor_start;
	this.pauserotarmor_finished = 0;
	this.pauserothealth_finished = 0;
	this.pauseregen_finished = 0;
	this.damageforcescale = 0;
	this.death_time = 0;
	this.respawn_flags = 0;
	this.respawn_time = 0;
	this.stat_respawn_time = 0;
	this.alpha = 0;
	this.scale = 0;
	this.fade_time = 0;
	this.pain_frame = 0;
	this.pain_finished = 0;
	this.strength_finished = 0;
	this.invincible_finished = 0;
	this.superweapons_finished = 0;
	this.pushltime = 0;
	this.istypefrag = 0;
	setthink(this, func_null);
	this.nextthink = 0;
	this.deadflag = DEAD_NO;
	this.crouch = false;
	this.revive_progress = 0;
	this.revival_time = 0;

	this.items = 0;
	this.weapons = '0 0 0';
	this.drawonlytoclient = this;

	this.weaponmodel = "";
	for (int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	{
		this.weaponentities[slot] = NULL;
	}
	this.exteriorweaponentity = NULL;
	this.killcount = FRAGS_SPECTATOR;
	this.velocity = '0 0 0';
	this.avelocity = '0 0 0';
	this.punchangle = '0 0 0';
	this.punchvector = '0 0 0';
	this.oldvelocity = this.velocity;
	this.fire_endtime = -1;
	this.event_damage = func_null;

	for(int slot = 0; slot < MAX_AXH; ++slot)
	{
		entity axh = this.(AuxiliaryXhair[slot]);
		this.(AuxiliaryXhair[slot]) = NULL;

		if(axh.owner == this && axh != NULL && !wasfreed(axh))
			delete(axh);
	}
}

int player_getspecies(entity this)
{
	get_model_parameters(this.model, this.skin);
	int s = get_model_parameters_species;
	get_model_parameters(string_null, 0);
	if (s < 0) return SPECIES_HUMAN;
	return s;
}

.float model_randomizer;
void FixPlayermodel(entity player)
{
	string defaultmodel = "";
	int defaultskin = 0;
	if(autocvar_sv_defaultcharacter)
	{
		if(teamplay)
		{
			switch(player.team)
			{
				case NUM_TEAM_1: defaultmodel = autocvar_sv_defaultplayermodel_red; defaultskin = autocvar_sv_defaultplayerskin_red; break;
				case NUM_TEAM_2: defaultmodel = autocvar_sv_defaultplayermodel_blue; defaultskin = autocvar_sv_defaultplayerskin_blue; break;
				case NUM_TEAM_3: defaultmodel = autocvar_sv_defaultplayermodel_yellow; defaultskin = autocvar_sv_defaultplayerskin_yellow; break;
				case NUM_TEAM_4: defaultmodel = autocvar_sv_defaultplayermodel_pink; defaultskin = autocvar_sv_defaultplayerskin_pink; break;
			}
		}

		if(defaultmodel == "")
		{
			defaultmodel = autocvar_sv_defaultplayermodel;
			defaultskin = autocvar_sv_defaultplayerskin;
		}

		int n = tokenize_console(defaultmodel);
		if(n > 0)
		{
			defaultmodel = argv(floor(n * player.model_randomizer));
			// However, do NOT randomize if the player-selected model is in the list.
			for (int i = 0; i < n; ++i)
				if ((argv(i) == player.playermodel && defaultskin == stof(player.playerskin)) || argv(i) == strcat(player.playermodel, ":", player.playerskin))
					defaultmodel = argv(i);
		}

		int i = strstrofs(defaultmodel, ":", 0);
		if(i >= 0)
		{
			defaultskin = stof(substring(defaultmodel, i+1, -1));
			defaultmodel = substring(defaultmodel, 0, i);
		}
	}
	if(autocvar_sv_defaultcharacterskin && !defaultskin)
	{
		if(teamplay)
		{
			switch(player.team)
			{
				case NUM_TEAM_1: defaultskin = autocvar_sv_defaultplayerskin_red; break;
				case NUM_TEAM_2: defaultskin = autocvar_sv_defaultplayerskin_blue; break;
				case NUM_TEAM_3: defaultskin = autocvar_sv_defaultplayerskin_yellow; break;
				case NUM_TEAM_4: defaultskin = autocvar_sv_defaultplayerskin_pink; break;
			}
		}

		if(!defaultskin)
			defaultskin = autocvar_sv_defaultplayerskin;
	}

	MUTATOR_CALLHOOK(FixPlayermodel, defaultmodel, defaultskin, player);
	defaultmodel = M_ARGV(0, string);
	defaultskin = M_ARGV(1, int);

	bool chmdl = false;
	int oldskin;
	if(defaultmodel != "")
	{
		if (defaultmodel != player.model)
		{
			vector m1 = player.mins;
			vector m2 = player.maxs;
			setplayermodel (player, defaultmodel);
			setsize (player, m1, m2);
			chmdl = true;
		}

		oldskin = player.skin;
		player.skin = defaultskin;
	} else {
		if (player.playermodel != player.model || player.playermodel == "")
		{
			player.playermodel = CheckPlayerModel(player.playermodel); // this is never "", so no endless loop
			vector m1 = player.mins;
			vector m2 = player.maxs;
			setplayermodel (player, player.playermodel);
			setsize (player, m1, m2);
			chmdl = true;
		}

		if(!autocvar_sv_defaultcharacterskin)
		{
			oldskin = player.skin;
			player.skin = stof(player.playerskin);
		}
		else
		{
			oldskin = player.skin;
			player.skin = defaultskin;
		}
	}

	if(chmdl || oldskin != player.skin) // model or skin has changed
	{
		player.species = player_getspecies(player); // update species
		if(!autocvar_g_debug_globalsounds)
			UpdatePlayerSounds(player); // update skin sounds
	}

	if(!teamplay)
		if(strlen(autocvar_sv_defaultplayercolors))
			if(player.clientcolors != stof(autocvar_sv_defaultplayercolors))
				setcolor(player, stof(autocvar_sv_defaultplayercolors));
}


/** Called when a client spawns in the server */
void PutClientInServer(entity this)
{
	if (IS_BOT_CLIENT(this)) {
		TRANSMUTE(Player, this);
	} else if (IS_REAL_CLIENT(this)) {
		msg_entity = this;
		WriteByte(MSG_ONE, SVC_SETVIEW);
		WriteEntity(MSG_ONE, this);
	}
	if (game_stopped)
		TRANSMUTE(Observer, this);

	SetSpectatee(this, NULL);

	// reset player keys
	this.itemkeys = 0;

	MUTATOR_CALLHOOK(PutClientInServer, this);

	if (IS_OBSERVER(this)) {
		PutObserverInServer(this);
	} else if (IS_PLAYER(this)) {
		if (this.vehicle) vehicles_exit(this.vehicle, VHEF_RELEASE);

		PlayerState_attach(this);
		accuracy_resend(this);

		if (this.team < 0)
			JoinBestTeam(this, false, true);

		entity spot = SelectSpawnPoint(this, false);
		if (!spot) {
			Send_Notification(NOTIF_ONE_ONLY, this, MSG_CENTER, CENTER_JOIN_NOSPAWNS);
			return; // spawn failed
		}

		TRANSMUTE(Player, this);

		this.wasplayer = true;
		this.iscreature = true;
		this.teleportable = TELEPORT_NORMAL;
		if(!this.damagedbycontents)
			IL_PUSH(g_damagedbycontents, this);
		this.damagedbycontents = true;
		set_movetype(this, MOVETYPE_WALK);
		this.solid = SOLID_SLIDEBOX;
		this.dphitcontentsmask = DPCONTENTS_BODY | DPCONTENTS_SOLID;
		if (autocvar_g_playerclip_collisions)
			this.dphitcontentsmask |= DPCONTENTS_PLAYERCLIP;
		if (IS_BOT_CLIENT(this) && autocvar_g_botclip_collisions)
			this.dphitcontentsmask |= DPCONTENTS_BOTCLIP;
		this.frags = FRAGS_PLAYER;
		if (INDEPENDENT_PLAYERS) MAKE_INDEPENDENT_PLAYER(this);
		this.flags = FL_CLIENT | FL_PICKUPITEMS;
		if (autocvar__notarget)
			this.flags |= FL_NOTARGET;
		this.takedamage = DAMAGE_AIM;
		this.effects = EF_TELEPORT_BIT | EF_RESTARTANIM_BIT;
		this.dmg = 2; // WTF

		if (warmup_stage) {
			this.ammo_shells = warmup_start_ammo_shells;
			this.ammo_nails = warmup_start_ammo_nails;
			this.ammo_rockets = warmup_start_ammo_rockets;
			this.ammo_cells = warmup_start_ammo_cells;
			this.ammo_plasma = warmup_start_ammo_plasma;
			this.ammo_fuel = warmup_start_ammo_fuel;
			this.health = warmup_start_health;
			this.armorvalue = warmup_start_armorvalue;
			this.weapons = WARMUP_START_WEAPONS;
		} else {
			this.ammo_shells = start_ammo_shells;
			this.ammo_nails = start_ammo_nails;
			this.ammo_rockets = start_ammo_rockets;
			this.ammo_cells = start_ammo_cells;
			this.ammo_plasma = start_ammo_plasma;
			this.ammo_fuel = start_ammo_fuel;
			this.health = start_health;
			this.armorvalue = start_armorvalue;
			this.weapons = start_weapons;
		}
		SetSpectatee_status(this, 0);

		this.superweapons_finished = (this.weapons & WEPSET_SUPERWEAPONS) ? time + autocvar_g_balance_superweapons_time : 0;

		this.items = start_items;

		this.spawnshieldtime = time + autocvar_g_spawnshieldtime;
		this.pauserotarmor_finished = time + autocvar_g_balance_pause_armor_rot_spawn;
		this.pauserothealth_finished = time + autocvar_g_balance_pause_health_rot_spawn;
		this.pauserotfuel_finished = time + autocvar_g_balance_pause_fuel_rot_spawn;
		this.pauseregen_finished = time + autocvar_g_balance_pause_health_regen_spawn;
		// extend the pause of rotting if client was reset at the beginning of the countdown
		if (!autocvar_sv_ready_restart_after_countdown && time < game_starttime) { // TODO why is this cvar NOTted?
			float f = game_starttime - time;
			this.spawnshieldtime += f;
			this.pauserotarmor_finished += f;
			this.pauserothealth_finished += f;
			this.pauseregen_finished += f;
		}
		this.damageforcescale = 2;
		this.death_time = 0;
		this.respawn_flags = 0;
		this.respawn_time = 0;
		this.stat_respawn_time = 0;
		this.scale = autocvar_sv_player_scale;
		this.fade_time = 0;
		this.pain_frame = 0;
		this.pain_finished = 0;
		this.pushltime = 0;
		setthink(this, func_null); // players have no think function
		this.nextthink = 0;
		this.dmg_team = 0;
		this.ballistics_density = autocvar_g_ballistics_density_player;

		this.deadflag = DEAD_NO;

		this.angles = spot.angles;
		this.angles_z = 0; // never spawn tilted even if the spot says to
		if (IS_BOT_CLIENT(this))
			this.v_angle = this.angles;
		this.fixangle = true; // turn this way immediately
		this.oldvelocity = this.velocity = '0 0 0';
		this.avelocity = '0 0 0';
		this.punchangle = '0 0 0';
		this.punchvector = '0 0 0';

		this.strength_finished = 0;
		this.invincible_finished = 0;
		this.fire_endtime = -1;
		this.revive_progress = 0;
		this.revival_time = 0;
		this.air_finished = time + 12;

		entity spawnevent = new_pure(spawnevent);
		spawnevent.owner = this;
		Net_LinkEntity(spawnevent, false, 0.5, SpawnEvent_Send);

		// Cut off any still running player sounds.
		stopsound(this, CH_PLAYER_SINGLE);

		this.model = "";
		FixPlayermodel(this);
		this.drawonlytoclient = NULL;

		this.viewloc = NULL;

		this.crouch = false;
		this.view_ofs = STAT(PL_VIEW_OFS, this);
		setsize(this, STAT(PL_MIN, this), STAT(PL_MAX, this));
		this.spawnorigin = spot.origin;
		setorigin(this, spot.origin + '0 0 1' * (1 - this.mins.z - 24));
		// don't reset back to last position, even if new position is stuck in solid
		this.oldorigin = this.origin;
		this.prevorigin = this.origin;
		this.lastteleporttime = time; // prevent insane speeds due to changing origin
		if(this.conveyor)
			IL_REMOVE(g_conveyed, this);
		this.conveyor = NULL; // prevent conveyors at the previous location from moving a freshly spawned player
		this.hud = HUD_NORMAL;

		this.event_damage = PlayerDamage;

		if(!this.bot_attack)
			IL_PUSH(g_bot_targets, this);
		this.bot_attack = true;
		this.monster_attack = true;
		navigation_dynamicgoal_init(this, false);

		PHYS_INPUT_BUTTON_ATCK(this) = PHYS_INPUT_BUTTON_JUMP(this) = PHYS_INPUT_BUTTON_ATCK2(this) = false;

		if (this.killcount == FRAGS_SPECTATOR) {
			PlayerScore_Clear(this);
			this.killcount = 0;
		}

		for (int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
		{
			.entity weaponentity = weaponentities[slot];
			entity oldwep = this.(weaponentity);
			CL_SpawnWeaponentity(this, weaponentity);
			if(oldwep && oldwep.owner == this)
				this.(weaponentity).m_gunalign = oldwep.m_gunalign;
		}
		this.alpha = default_player_alpha;
		this.colormod = '1 1 1' * autocvar_g_player_brightness;
		this.exteriorweaponentity.alpha = default_weapon_alpha;

		this.speedrunning = false;

		target_voicescript_clear(this);

		// reset fields the weapons may use
		FOREACH(Weapons, true, LAMBDA(
			it.wr_resetplayer(it, this);
			// reload all reloadable weapons
			if (it.spawnflags & WEP_FLAG_RELOADABLE) {
				for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
				{
					.entity weaponentity = weaponentities[slot];
					this.(weaponentity).weapon_load[it.m_id] = it.reloading_ammo;
				}
			}
		));

		{
			string s = spot.target;
			spot.target = string_null;
			SUB_UseTargets(spot, this, NULL);
			spot.target = s;
		}

		Unfreeze(this);

		MUTATOR_CALLHOOK(PlayerSpawn, this, spot);

		if (autocvar_spawn_debug)
		{
			sprint(this, strcat("spawnpoint origin:  ", vtos(spot.origin), "\n"));
			delete(spot); // usefull for checking if there are spawnpoints, that let drop through the floor
		}

		for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
		{
			.entity weaponentity = weaponentities[slot];
			if(slot == 0)
				this.(weaponentity).m_switchweapon = w_getbestweapon(this, weaponentity);
			else
				this.(weaponentity).m_switchweapon = WEP_Null;
			this.(weaponentity).m_weapon = WEP_Null;
			this.(weaponentity).weaponname = "";
			this.(weaponentity).m_switchingweapon = WEP_Null;
			this.(weaponentity).cnt = -1;
		}

		MUTATOR_CALLHOOK(PlayerWeaponSelect, this);

		if (!warmup_stage && !this.alivetime)
			this.alivetime = time;

		antilag_clear(this, CS(this));
	}
}

void ClientInit_misc(entity this);

// TODO do we need all these fields, or should we stop autodetecting runtime
// changes and just have a console command to update this?
bool ClientInit_SendEntity(entity this, entity to, int sf)
{
	WriteHeader(MSG_ENTITY, _ENT_CLIENT_INIT);
	return = true;
	msg_entity = to;
	// MSG_INIT replacement
	// TODO: make easier to use
	Registry_send_all();
	W_PROP_reload(MSG_ONE, to);
	ClientInit_misc(this);
	MUTATOR_CALLHOOK(Ent_Init);
}
void ClientInit_misc(entity this)
{
	int channel = MSG_ONE;
	WriteHeader(channel, ENT_CLIENT_INIT);
	WriteByte(channel, g_nexball_meter_period * 32);
	WriteInt24_t(channel, compressShotOrigin(hook_shotorigin[0]));
	WriteInt24_t(channel, compressShotOrigin(hook_shotorigin[1]));
	WriteInt24_t(channel, compressShotOrigin(hook_shotorigin[2]));
	WriteInt24_t(channel, compressShotOrigin(hook_shotorigin[3]));
	WriteInt24_t(channel, compressShotOrigin(arc_shotorigin[0]));
	WriteInt24_t(channel, compressShotOrigin(arc_shotorigin[1]));
	WriteInt24_t(channel, compressShotOrigin(arc_shotorigin[2]));
	WriteInt24_t(channel, compressShotOrigin(arc_shotorigin[3]));

	if(sv_foginterval && world.fog != "")
		WriteString(channel, world.fog);
	else
		WriteString(channel, "");
	WriteByte(channel, this.count * 255.0); // g_balance_armor_blockpercent
	WriteByte(channel, serverflags);
	WriteCoord(channel, autocvar_g_trueaim_minrange);
}

void ClientInit_CheckUpdate(entity this)
{
	this.nextthink = time;
	if(this.count != autocvar_g_balance_armor_blockpercent)
	{
		this.count = autocvar_g_balance_armor_blockpercent;
		this.SendFlags |= 1;
	}
}

void ClientInit_Spawn()
{
	entity e = new_pure(clientinit);
	setthink(e, ClientInit_CheckUpdate);
	Net_LinkEntity(e, false, 0, ClientInit_SendEntity);

	ClientInit_CheckUpdate(e);
}

/*
=============
SetNewParms
=============
*/
void SetNewParms ()
{
	// initialize parms for a new player
	parm1 = -(86400 * 366);

	MUTATOR_CALLHOOK(SetNewParms);
}

/*
=============
SetChangeParms
=============
*/
void SetChangeParms (entity this)
{
	// save parms for level change
	parm1 = this.parm_idlesince - time;

	MUTATOR_CALLHOOK(SetChangeParms);
}

/*
=============
DecodeLevelParms
=============
*/
void DecodeLevelParms(entity this)
{
	// load parms
	this.parm_idlesince = parm1;
	if (this.parm_idlesince == -(86400 * 366))
		this.parm_idlesince = time;

	// whatever happens, allow 60 seconds of idling directly after connect for map loading
	this.parm_idlesince = max(this.parm_idlesince, time - sv_maxidle + 60);

	MUTATOR_CALLHOOK(DecodeLevelParms);
}

/*
=============
ClientKill

Called when a client types 'kill' in the console
=============
*/

.float clientkill_nexttime;
void ClientKill_Now_TeamChange(entity this)
{
	if(this.killindicator_teamchange == -1)
	{
		JoinBestTeam( this, false, true );
	}
	else if(this.killindicator_teamchange == -2)
	{
		if(blockSpectators)
			Send_Notification(NOTIF_ONE_ONLY, this, MSG_INFO, INFO_SPECTATE_WARNING, autocvar_g_maxplayers_spectator_blocktime);
		PutObserverInServer(this);
	}
	else
		SV_ChangeTeam(this, this.killindicator_teamchange - 1);
	this.killindicator_teamchange = 0;
}

void ClientKill_Now(entity this)
{
	if(this.vehicle)
	{
	    vehicles_exit(this.vehicle, VHEF_RELEASE);
	    if(!this.killindicator_teamchange)
	    {
            this.vehicle_health = -1;
            Damage(this, this, this, 1 , DEATH_KILL.m_id, this.origin, '0 0 0');
	    }
	}

	if(this.killindicator && !wasfreed(this.killindicator))
		delete(this.killindicator);

	this.killindicator = NULL;

	if(this.killindicator_teamchange)
		ClientKill_Now_TeamChange(this);

	if(!IS_SPEC(this) && !IS_OBSERVER(this))
		Damage(this, this, this, 100000, DEATH_KILL.m_id, this.origin, '0 0 0');

	// now I am sure the player IS dead
}
void KillIndicator_Think(entity this)
{
	if (game_stopped)
	{
		this.owner.killindicator = NULL;
		delete(this);
		return;
	}

	if (this.owner.alpha < 0 && !this.owner.vehicle)
	{
		this.owner.killindicator = NULL;
		delete(this);
		return;
	}

	if(this.cnt <= 0)
	{
		ClientKill_Now(this.owner);
		return;
	}
    else if(g_cts && this.health == 1) // health == 1 means that it's silent
    {
        this.nextthink = time + 1;
        this.cnt -= 1;
    }
	else
	{
		if(this.cnt <= 10)
			setmodel(this, MDL_NUM(this.cnt));
		if(IS_REAL_CLIENT(this.owner))
		{
			if(this.cnt <= 10)
				{ Send_Notification(NOTIF_ONE, this.owner, MSG_ANNCE, Announcer_PickNumber(CNT_KILL, this.cnt)); }
		}
		this.nextthink = time + 1;
		this.cnt -= 1;
	}
}

float clientkilltime;
void ClientKill_TeamChange (entity this, float targetteam) // 0 = don't change, -1 = auto, -2 = spec
{
	float killtime;
	float starttime;

	if (game_stopped)
		return;

	killtime = autocvar_g_balance_kill_delay;

	if(g_race_qualifying || g_cts)
		killtime = 0;

    if(MUTATOR_CALLHOOK(ClientKill, this, killtime))
    	return;

	this.killindicator_teamchange = targetteam;

    if(!this.killindicator)
	{
		if(!IS_DEAD(this))
		{
			killtime = max(killtime, this.clientkill_nexttime - time);
			this.clientkill_nexttime = time + killtime + autocvar_g_balance_kill_antispam;
		}

		if(killtime <= 0 || !IS_PLAYER(this) || IS_DEAD(this))
		{
			ClientKill_Now(this);
		}
		else
		{
			starttime = max(time, clientkilltime);

			this.killindicator = spawn();
			this.killindicator.owner = this;
			this.killindicator.scale = 0.5;
			setattachment(this.killindicator, this, "");
			setorigin(this.killindicator, '0 0 52');
			setthink(this.killindicator, KillIndicator_Think);
			this.killindicator.nextthink = starttime + (this.lip) * 0.05;
			clientkilltime = max(clientkilltime, this.killindicator.nextthink + 0.05);
			this.killindicator.cnt = ceil(killtime);
			this.killindicator.count = bound(0, ceil(killtime), 10);
			//sprint(this, strcat("^1You'll be dead in ", ftos(this.killindicator.cnt), " seconds\n"));

			IL_EACH(g_clones, it.enemy == this && !(it.effects & CSQCMODEL_EF_RESPAWNGHOST),
			{
				it.killindicator = spawn();
				it.killindicator.owner = it;
				it.killindicator.scale = 0.5;
				setattachment(it.killindicator, it, "");
				setorigin(it.killindicator, '0 0 52');
				setthink(it.killindicator, KillIndicator_Think);
				it.killindicator.nextthink = starttime + (it.lip) * 0.05;
				//clientkilltime = max(clientkilltime, it.killindicator.nextthink + 0.05);
				it.killindicator.cnt = ceil(killtime);
			});
			this.lip = 0;
		}
	}
	if(this.killindicator)
	{
		if(targetteam == 0) // just die
		{
			this.killindicator.colormod = '0 0 0';
			if(IS_REAL_CLIENT(this))
			if(this.killindicator.cnt > 0)
				Send_Notification(NOTIF_ONE_ONLY, this, MSG_CENTER, CENTER_TEAMCHANGE_SUICIDE, this.killindicator.cnt);
		}
		else if(targetteam == -1) // auto
		{
			this.killindicator.colormod = '0 1 0';
			if(IS_REAL_CLIENT(this))
			if(this.killindicator.cnt > 0)
				Send_Notification(NOTIF_ONE_ONLY, this, MSG_CENTER, CENTER_TEAMCHANGE_AUTO, this.killindicator.cnt);
		}
		else if(targetteam == -2) // spectate
		{
			this.killindicator.colormod = '0.5 0.5 0.5';
			if(IS_REAL_CLIENT(this))
			if(this.killindicator.cnt > 0)
				Send_Notification(NOTIF_ONE_ONLY, this, MSG_CENTER, CENTER_TEAMCHANGE_SPECTATE, this.killindicator.cnt);
		}
		else
		{
			this.killindicator.colormod = Team_ColorRGB(targetteam);
			if(IS_REAL_CLIENT(this))
			if(this.killindicator.cnt > 0)
				Send_Notification(NOTIF_ONE_ONLY, this, MSG_CENTER, APP_TEAM_NUM(targetteam, CENTER_TEAMCHANGE), this.killindicator.cnt);
		}
	}

}

void ClientKill (entity this)
{
	if(game_stopped) return;
	if(this.player_blocked) return;
	if(STAT(FROZEN, this)) return;

	ClientKill_TeamChange(this, 0);
}

void FixClientCvars(entity e)
{
	// send prediction settings to the client
	stuffcmd(e, "\nin_bindmap 0 0\n");
	if(autocvar_g_antilag == 3) // client side hitscan
		stuffcmd(e, "cl_cmd settemp cl_prydoncursor_notrace 0\n");
	if(autocvar_sv_gentle)
		stuffcmd(e, "cl_cmd settemp cl_gentle 1\n");

	MUTATOR_CALLHOOK(FixClientCvars, e);
}

float PlayerInIDList(entity p, string idlist)
{
	float n, i;
	string s;

	// NOTE: we do NOT check crypto_idfp_signed here, an unsigned ID is fine too for this
	if (!p.crypto_idfp)
		return 0;

	// this function allows abbreviated player IDs too!
	n = tokenize_console(idlist);
	for(i = 0; i < n; ++i)
	{
		s = argv(i);
		if(s == substring(p.crypto_idfp, 0, strlen(s)))
			return 1;
	}

	return 0;
}

#ifdef DP_EXT_PRECONNECT
/*
=============
ClientPreConnect

Called once (not at each match start) when a client begins a connection to the server
=============
*/
void ClientPreConnect(entity this)
{
	if(autocvar_sv_eventlog)
	{
		GameLogEcho(sprintf(":connect:%d:%d:%s",
			this.playerid,
			etof(this),
			((IS_REAL_CLIENT(this)) ? this.netaddress : "bot")
		));
	}
}
#endif

/**
=============
ClientConnect

Called when a client connects to the server
=============
*/
void ClientConnect(entity this)
{
	if (Ban_MaybeEnforceBanOnce(this)) return;
	assert(!IS_CLIENT(this), return);
	this.flags |= FL_CLIENT;
	assert(player_count >= 0, player_count = 0);

#ifdef WATERMARK
	Send_Notification(NOTIF_ONE_ONLY, this, MSG_INFO, INFO_WATERMARK, WATERMARK);
#endif
	this.version_nagtime = time + 10 + random() * 10;
	TRANSMUTE(Client, this);

	// identify the right forced team
	if (autocvar_g_campaign)
	{
		if (IS_REAL_CLIENT(this)) // only players, not bots
		{
			switch (autocvar_g_campaign_forceteam)
			{
				case 1: this.team_forced = NUM_TEAM_1; break;
				case 2: this.team_forced = NUM_TEAM_2; break;
				case 3: this.team_forced = NUM_TEAM_3; break;
				case 4: this.team_forced = NUM_TEAM_4; break;
				default: this.team_forced = 0;
			}
		}
	}
	else if (PlayerInIDList(this, autocvar_g_forced_team_red))    this.team_forced = NUM_TEAM_1;
	else if (PlayerInIDList(this, autocvar_g_forced_team_blue))   this.team_forced = NUM_TEAM_2;
	else if (PlayerInIDList(this, autocvar_g_forced_team_yellow)) this.team_forced = NUM_TEAM_3;
	else if (PlayerInIDList(this, autocvar_g_forced_team_pink))   this.team_forced = NUM_TEAM_4;
	else switch (autocvar_g_forced_team_otherwise)
	{
		default: this.team_forced = 0; break;
		case "red": this.team_forced = NUM_TEAM_1; break;
		case "blue": this.team_forced = NUM_TEAM_2; break;
		case "yellow": this.team_forced = NUM_TEAM_3; break;
		case "pink": this.team_forced = NUM_TEAM_4; break;
		case "spectate":
		case "spectator":
			this.team_forced = -1;
			break;
	}
	if (!teamplay && this.team_forced > 0) this.team_forced = 0;

    {
        int id = this.playerid;
        this.playerid = 0; // silent
	    JoinBestTeam(this, false, false); // if the team number is valid, keep it
	    this.playerid = id;
    }

	if (autocvar_sv_spectate || autocvar_g_campaign || this.team_forced < 0) {
		TRANSMUTE(Observer, this);
	} else {
		if (!teamplay || autocvar_g_balance_teams) {
			TRANSMUTE(Player, this);
			campaign_bots_may_start = true;
		} else {
			TRANSMUTE(Observer, this); // do it anyway
		}
	}

	PlayerStats_GameReport_AddEvent(sprintf("kills-%d", this.playerid));

	// always track bots, don't ask for cl_allow_uidtracking
    if (IS_BOT_CLIENT(this)) PlayerStats_GameReport_AddPlayer(this);

	if (autocvar_sv_eventlog)
		GameLogEcho(strcat(":join:", ftos(this.playerid), ":", ftos(etof(this)), ":", ((IS_REAL_CLIENT(this)) ? this.netaddress : "bot"), ":", playername(this, false)));

	LogTeamchange(this.playerid, this.team, 1);

	this.just_joined = true;  // stop spamming the eventlog with additional lines when the client connects

	this.netname_previous = strzone(this.netname);

	if(teamplay && IS_PLAYER(this))
		Send_Notification(NOTIF_ALL, NULL, MSG_INFO, APP_TEAM_NUM(this.team, INFO_JOIN_CONNECT_TEAM), this.netname);
	else
		Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_JOIN_CONNECT, this.netname);

	stuffcmd(this, clientstuff, "\n");
	stuffcmd(this, "cl_particles_reloadeffects\n"); // TODO do we still need this?

	FixClientCvars(this);

	// get version info from player
	stuffcmd(this, "cmd clientversion $gameversion\n");

	// notify about available teams
	if (teamplay)
	{
		CheckAllowedTeams(this);
		int t = 0;
		if (c1 >= 0) t |= BIT(0);
		if (c2 >= 0) t |= BIT(1);
		if (c3 >= 0) t |= BIT(2);
		if (c4 >= 0) t |= BIT(3);
		stuffcmd(this, sprintf("set _teams_available %d\n", t));
	}
	else
	{
		stuffcmd(this, "set _teams_available 0\n");
	}

	bot_relinkplayerlist();

	this.spectatortime = time;
	if (blockSpectators)
	{
		Send_Notification(NOTIF_ONE_ONLY, this, MSG_INFO, INFO_SPECTATE_WARNING, autocvar_g_maxplayers_spectator_blocktime);
	}

	this.jointime = time;
	this.allowed_timeouts = autocvar_sv_timeout_number;

	if (IS_REAL_CLIENT(this))
	{
		if (g_weaponarena_weapons == WEPSET(TUBA))
			stuffcmd(this, "cl_cmd settemp chase_active 1\n");
	}

	if (!sv_foginterval && world.fog != "")
		stuffcmd(this, strcat("\nfog ", world.fog, "\nr_fog_exp2 0\nr_drawfog 1\n"));

	if (autocvar_sv_teamnagger && !(autocvar_bot_vs_human && AvailableTeams() == 2))
		if(!MUTATOR_CALLHOOK(HideTeamNagger, this))
			send_CSQC_teamnagger();

	CSQCMODEL_AUTOINIT(this);

	this.model_randomizer = random();

	if (IS_REAL_CLIENT(this))
		sv_notice_join(this);

	// update physics stats (players can spawn before physics runs)
	STAT(MOVEVARS_HIGHSPEED, this) = autocvar_g_movement_highspeed;
	MUTATOR_CALLHOOK(PlayerPhysics_UpdateStats, this); // do it BEFORE the function so we can modify highspeed!
	Physics_UpdateStats(this, PHYS_HIGHSPEED(this));

	IL_EACH(g_initforplayer, it.init_for_player, {
		it.init_for_player(it, this);
	});

	MUTATOR_CALLHOOK(ClientConnect, this);

	if (IS_REAL_CLIENT(this))
	{
		if (!autocvar_g_campaign && !IS_PLAYER(this))
		{
			this.motd_actived_time = -1;
			Send_Notification(NOTIF_ONE_ONLY, this, MSG_CENTER, CENTER_MOTD, getwelcomemessage(this));
		}
	}
}
/*
=============
ClientDisconnect

Called when a client disconnects from the server
=============
*/
.entity chatbubbleentity;
void ReadyCount();
void ClientDisconnect(entity this)
{
	assert(IS_CLIENT(this), return);

	PlayerStats_GameReport_FinalizePlayer(this);
	if (this.vehicle) vehicles_exit(this.vehicle, VHEF_RELEASE);
	if (this.active_minigame) part_minigame(this);
	if (IS_PLAYER(this)) Send_Effect(EFFECT_SPAWN_NEUTRAL, this.origin, '0 0 0', 1);

	if (autocvar_sv_eventlog)
		GameLogEcho(strcat(":part:", ftos(this.playerid)));

	Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_QUIT_DISCONNECT, this.netname);

	if(IS_SPEC(this))
		SetSpectatee(this, NULL);

    MUTATOR_CALLHOOK(ClientDisconnect, this);

	ClientState_detach(this);

	Portal_ClearAll(this);

	Unfreeze(this);

	RemoveGrapplingHooks(this);

	// Here, everything has been done that requires this player to be a client.

	this.flags &= ~FL_CLIENT;

	if (this.chatbubbleentity) delete(this.chatbubbleentity);
	if (this.killindicator) delete(this.killindicator);

	WaypointSprite_PlayerGone(this);

	bot_relinkplayerlist();

	if (this.netname_previous) strunzone(this.netname_previous);
	if (this.clientstatus) strunzone(this.clientstatus);
	if (this.weaponorder_byimpulse) strunzone(this.weaponorder_byimpulse);
	if (this.personal) delete(this.personal);

	this.playerid = 0;
	ReadyCount();
	if (vote_called && IS_REAL_CLIENT(this)) VoteCount(false);

	ONREMOVE(this);
}

void ChatBubbleThink(entity this)
{
	this.nextthink = time;
	if ((this.owner.alpha < 0) || this.owner.chatbubbleentity != this)
	{
		if(this.owner) // but why can that ever be NULL?
			this.owner.chatbubbleentity = NULL;
		delete(this);
		return;
	}

	this.mdl = "";

	if ( !IS_DEAD(this.owner) && IS_PLAYER(this.owner) )
	{
		if ( this.owner.active_minigame )
			this.mdl = "models/sprites/minigame_busy.iqm";
		else if (PHYS_INPUT_BUTTON_CHAT(this.owner))
			this.mdl = "models/misc/chatbubble.spr";
	}

	if ( this.model != this.mdl )
		_setmodel(this, this.mdl);

}

void UpdateChatBubble(entity this)
{
	if (this.alpha < 0)
		return;
	// spawn a chatbubble entity if needed
	if (!this.chatbubbleentity)
	{
		this.chatbubbleentity = new(chatbubbleentity);
		this.chatbubbleentity.owner = this;
		this.chatbubbleentity.exteriormodeltoclient = this;
		setthink(this.chatbubbleentity, ChatBubbleThink);
		this.chatbubbleentity.nextthink = time;
		setmodel(this.chatbubbleentity, MDL_CHAT); // precision set below
		//setorigin(this.chatbubbleentity, this.origin + '0 0 15' + this.maxs_z * '0 0 1');
		setorigin(this.chatbubbleentity, '0 0 15' + this.maxs_z * '0 0 1');
		setattachment(this.chatbubbleentity, this, "");  // sticks to moving player better, also conserves bandwidth
		this.chatbubbleentity.mdl = this.chatbubbleentity.model;
		//this.chatbubbleentity.model = "";
		this.chatbubbleentity.effects = EF_LOWPRECISION;
	}
}


// LordHavoc: this hack will be removed when proper _pants/_shirt layers are
// added to the model skins
/*void UpdateColorModHack()
{
	float c;
	c = this.clientcolors & 15;
	// LordHavoc: only bothering to support white, green, red, yellow, blue
	     if (!teamplay) this.colormod = '0 0 0';
	else if (c ==  0) this.colormod = '1.00 1.00 1.00';
	else if (c ==  3) this.colormod = '0.10 1.73 0.10';
	else if (c ==  4) this.colormod = '1.73 0.10 0.10';
	else if (c == 12) this.colormod = '1.22 1.22 0.10';
	else if (c == 13) this.colormod = '0.10 0.10 1.73';
	else this.colormod = '1 1 1';
}*/

void respawn(entity this)
{
	if(this.alpha >= 0 && autocvar_g_respawn_ghosts)
	{
		this.solid = SOLID_NOT;
		this.takedamage = DAMAGE_NO;
		set_movetype(this, MOVETYPE_FLY);
		this.velocity = '0 0 1' * autocvar_g_respawn_ghosts_speed;
		this.avelocity = randomvec() * autocvar_g_respawn_ghosts_speed * 3 - randomvec() * autocvar_g_respawn_ghosts_speed * 3;
		this.effects |= CSQCMODEL_EF_RESPAWNGHOST;
		Send_Effect(EFFECT_RESPAWN_GHOST, this.origin, '0 0 0', 1);
		if(autocvar_g_respawn_ghosts_maxtime)
			SUB_SetFade (this, time + autocvar_g_respawn_ghosts_maxtime / 2 + random () * (autocvar_g_respawn_ghosts_maxtime - autocvar_g_respawn_ghosts_maxtime / 2), 1.5);
	}

	CopyBody(this, 1);

	this.effects |= EF_NODRAW; // prevent another CopyBody
	PutClientInServer(this);
}

void play_countdown(entity this, float finished, Sound samp)
{
    TC(Sound, samp);
	if(IS_REAL_CLIENT(this))
		if(floor(finished - time - frametime) != floor(finished - time))
			if(finished - time < 6)
				sound (this, CH_INFO, samp, VOL_BASE, ATTEN_NORM);
}

void player_powerups(entity this)
{
	// add a way to see what the items were BEFORE all of these checks for the mutator hook
	int items_prev = this.items;

	if((this.items & IT_USING_JETPACK) && !IS_DEAD(this) && !game_stopped)
		this.modelflags |= MF_ROCKET;
	else
		this.modelflags &= ~MF_ROCKET;

	this.effects &= ~(EF_RED | EF_BLUE | EF_ADDITIVE | EF_FULLBRIGHT | EF_FLAME | EF_NODEPTHTEST);

	if((this.alpha < 0 || IS_DEAD(this)) && !this.vehicle) // don't apply the flags if the player is gibbed
		return;

	Fire_ApplyDamage(this);
	Fire_ApplyEffect(this);

	if (!g_instagib)
	{
		if (this.items & ITEM_Strength.m_itemid)
		{
			play_countdown(this, this.strength_finished, SND_POWEROFF);
			this.effects = this.effects | (EF_BLUE | EF_ADDITIVE | EF_FULLBRIGHT);
			if (time > this.strength_finished)
			{
				this.items = this.items - (this.items & ITEM_Strength.m_itemid);
				//Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_POWERDOWN_STRENGTH, this.netname);
				Send_Notification(NOTIF_ONE, this, MSG_CENTER, CENTER_POWERDOWN_STRENGTH);
			}
		}
		else
		{
			if (time < this.strength_finished)
			{
				this.items = this.items | ITEM_Strength.m_itemid;
				Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_POWERUP_STRENGTH, this.netname);
				Send_Notification(NOTIF_ONE, this, MSG_CENTER, CENTER_POWERUP_STRENGTH);
			}
		}
		if (this.items & ITEM_Shield.m_itemid)
		{
			play_countdown(this, this.invincible_finished, SND_POWEROFF);
			this.effects = this.effects | (EF_RED | EF_ADDITIVE | EF_FULLBRIGHT);
			if (time > this.invincible_finished)
			{
				this.items = this.items - (this.items & ITEM_Shield.m_itemid);
				//Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_POWERDOWN_SHIELD, this.netname);
				Send_Notification(NOTIF_ONE, this, MSG_CENTER, CENTER_POWERDOWN_SHIELD);
			}
		}
		else
		{
			if (time < this.invincible_finished)
			{
				this.items = this.items | ITEM_Shield.m_itemid;
				Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_POWERUP_SHIELD, this.netname);
				Send_Notification(NOTIF_ONE, this, MSG_CENTER, CENTER_POWERUP_SHIELD);
			}
		}
		if (this.items & IT_SUPERWEAPON)
		{
			if (!(this.weapons & WEPSET_SUPERWEAPONS))
			{
				this.superweapons_finished = 0;
				this.items = this.items - (this.items & IT_SUPERWEAPON);
				//Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_SUPERWEAPON_LOST, this.netname);
				Send_Notification(NOTIF_ONE, this, MSG_CENTER, CENTER_SUPERWEAPON_LOST);
			}
			else if (this.items & IT_UNLIMITED_SUPERWEAPONS)
			{
				// don't let them run out
			}
			else
			{
				play_countdown(this, this.superweapons_finished, SND_POWEROFF);
				if (time > this.superweapons_finished)
				{
					this.items = this.items - (this.items & IT_SUPERWEAPON);
					this.weapons &= ~WEPSET_SUPERWEAPONS;
					//Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_SUPERWEAPON_BROKEN, this.netname);
					Send_Notification(NOTIF_ONE, this, MSG_CENTER, CENTER_SUPERWEAPON_BROKEN);
				}
			}
		}
		else if(this.weapons & WEPSET_SUPERWEAPONS)
		{
			if (time < this.superweapons_finished || (this.items & IT_UNLIMITED_SUPERWEAPONS))
			{
				this.items = this.items | IT_SUPERWEAPON;
				Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_SUPERWEAPON_PICKUP, this.netname);
				Send_Notification(NOTIF_ONE, this, MSG_CENTER, CENTER_SUPERWEAPON_PICKUP);
			}
			else
			{
				this.superweapons_finished = 0;
				this.weapons &= ~WEPSET_SUPERWEAPONS;
			}
		}
		else
		{
			this.superweapons_finished = 0;
		}
	}

	if(autocvar_g_nodepthtestplayers)
		this.effects = this.effects | EF_NODEPTHTEST;

	if(autocvar_g_fullbrightplayers)
		this.effects = this.effects | EF_FULLBRIGHT;

	if (time >= game_starttime)
	if (time < this.spawnshieldtime)
		this.effects = this.effects | (EF_ADDITIVE | EF_FULLBRIGHT);

	MUTATOR_CALLHOOK(PlayerPowerups, this, items_prev);
}

float CalcRegen(float current, float stable, float regenfactor, float regenframetime)
{
	if(current > stable)
		return current;
	else if(current > stable - 0.25) // when close enough, "snap"
		return stable;
	else
		return min(stable, current + (stable - current) * regenfactor * regenframetime);
}

float CalcRot(float current, float stable, float rotfactor, float rotframetime)
{
	if(current < stable)
		return current;
	else if(current < stable + 0.25) // when close enough, "snap"
		return stable;
	else
		return max(stable, current + (stable - current) * rotfactor * rotframetime);
}

float CalcRotRegen(float current, float regenstable, float regenfactor, float regenlinear, float regenframetime, float rotstable, float rotfactor, float rotlinear, float rotframetime, float limit)
{
	if(current > rotstable)
	{
		if(rotframetime > 0)
		{
			current = CalcRot(current, rotstable, rotfactor, rotframetime);
			current = max(rotstable, current - rotlinear * rotframetime);
		}
	}
	else if(current < regenstable)
	{
		if(regenframetime > 0)
		{
			current = CalcRegen(current, regenstable, regenfactor, regenframetime);
			current = min(regenstable, current + regenlinear * regenframetime);
		}
	}

	if(current > limit)
		current = limit;

	return current;
}

void player_regen(entity this)
{
	float max_mod, regen_mod, rot_mod, limit_mod;
	max_mod = regen_mod = rot_mod = limit_mod = 1;

	float regen_health = autocvar_g_balance_health_regen;
	float regen_health_linear = autocvar_g_balance_health_regenlinear;
	float regen_health_rot = autocvar_g_balance_health_rot;
	float regen_health_rotlinear = autocvar_g_balance_health_rotlinear;
	float regen_health_stable = autocvar_g_balance_health_regenstable;
	float regen_health_rotstable = autocvar_g_balance_health_rotstable;
	bool mutator_returnvalue = MUTATOR_CALLHOOK(PlayerRegen, this, max_mod, regen_mod, rot_mod, limit_mod, regen_health, regen_health_linear, regen_health_rot,
		regen_health_rotlinear, regen_health_stable, regen_health_rotstable);
	max_mod = M_ARGV(1, float);
	regen_mod = M_ARGV(2, float);
	rot_mod = M_ARGV(3, float);
	limit_mod = M_ARGV(4, float);
	regen_health = M_ARGV(5, float);
	regen_health_linear = M_ARGV(6, float);
	regen_health_rot = M_ARGV(7, float);
	regen_health_rotlinear = M_ARGV(8, float);
	regen_health_stable = M_ARGV(9, float);
	regen_health_rotstable = M_ARGV(10, float);


	if(!mutator_returnvalue)
	if(!STAT(FROZEN, this))
	{
		float mina, maxa, limith, limita;
		maxa = autocvar_g_balance_armor_rotstable;
		mina = autocvar_g_balance_armor_regenstable;
		limith = autocvar_g_balance_health_limit;
		limita = autocvar_g_balance_armor_limit;

		regen_health_rotstable = regen_health_rotstable * max_mod;
		regen_health_stable = regen_health_stable * max_mod;
		limith = limith * limit_mod;
		limita = limita * limit_mod;

		this.armorvalue = CalcRotRegen(this.armorvalue, mina, autocvar_g_balance_armor_regen, autocvar_g_balance_armor_regenlinear, regen_mod * frametime * (time > this.pauseregen_finished), maxa, autocvar_g_balance_armor_rot, autocvar_g_balance_armor_rotlinear, rot_mod * frametime * (time > this.pauserotarmor_finished), limita);
		this.health = CalcRotRegen(this.health, regen_health_stable, regen_health, regen_health_linear, regen_mod * frametime * (time > this.pauseregen_finished), regen_health_rotstable, regen_health_rot, regen_health_rotlinear, rot_mod * frametime * (time > this.pauserothealth_finished), limith);
	}

	// if player rotted to death...  die!
	// check this outside above checks, as player may still be able to rot to death
	if(this.health < 1)
	{
		if(this.vehicle)
			vehicles_exit(this.vehicle, VHEF_RELEASE);
		if(this.event_damage)
			this.event_damage(this, this, this, 1, DEATH_ROT.m_id, this.origin, '0 0 0');
	}

	if (!(this.items & IT_UNLIMITED_WEAPON_AMMO))
	{
		float minf, maxf, limitf;

		maxf = autocvar_g_balance_fuel_rotstable;
		minf = autocvar_g_balance_fuel_regenstable;
		limitf = autocvar_g_balance_fuel_limit;

		this.ammo_fuel = CalcRotRegen(this.ammo_fuel, minf, autocvar_g_balance_fuel_regen, autocvar_g_balance_fuel_regenlinear, frametime * (time > this.pauseregen_finished) * ((this.items & ITEM_JetpackRegen.m_itemid) != 0), maxf, autocvar_g_balance_fuel_rot, autocvar_g_balance_fuel_rotlinear, frametime * (time > this.pauserotfuel_finished), limitf);
	}
}

bool zoomstate_set;
void SetZoomState(entity this, float newzoom)
{
	if(newzoom != this.zoomstate)
	{
		this.zoomstate = newzoom;
		ClientData_Touch(this);
	}
	zoomstate_set = true;
}

void GetPressedKeys(entity this)
{
	MUTATOR_CALLHOOK(GetPressedKeys, this);
	int keys = STAT(PRESSED_KEYS, this);
	keys = BITSET(keys, KEY_FORWARD, 	this.movement.x > 0);
	keys = BITSET(keys, KEY_BACKWARD, 	this.movement.x < 0);
	keys = BITSET(keys, KEY_RIGHT, 		this.movement.y > 0);
	keys = BITSET(keys, KEY_LEFT, 		this.movement.y < 0);

	keys = BITSET(keys, KEY_JUMP, 		PHYS_INPUT_BUTTON_JUMP(this));
	keys = BITSET(keys, KEY_CROUCH, 	PHYS_INPUT_BUTTON_CROUCH(this));
	keys = BITSET(keys, KEY_ATCK, 		PHYS_INPUT_BUTTON_ATCK(this));
	keys = BITSET(keys, KEY_ATCK2, 		PHYS_INPUT_BUTTON_ATCK2(this));
	this.pressedkeys = keys; // store for other users

	STAT(PRESSED_KEYS, this) = keys;
}

/*
======================
spectate mode routines
======================
*/

void SpectateCopy(entity this, entity spectatee)
{
    TC(Client, this); TC(Client, spectatee);

	MUTATOR_CALLHOOK(SpectateCopy, spectatee, this);
	PS(this) = PS(spectatee);
	this.armortype = spectatee.armortype;
	this.armorvalue = spectatee.armorvalue;
	this.ammo_cells = spectatee.ammo_cells;
	this.ammo_plasma = spectatee.ammo_plasma;
	this.ammo_shells = spectatee.ammo_shells;
	this.ammo_nails = spectatee.ammo_nails;
	this.ammo_rockets = spectatee.ammo_rockets;
	this.ammo_fuel = spectatee.ammo_fuel;
	this.clip_load = spectatee.clip_load;
	this.clip_size = spectatee.clip_size;
	this.effects = spectatee.effects & EFMASK_CHEAP; // eat performance
	this.health = spectatee.health;
	this.impulse = 0;
	this.items = spectatee.items;
	this.last_pickup = spectatee.last_pickup;
	this.hit_time = spectatee.hit_time;
	this.strength_finished = spectatee.strength_finished;
	this.invincible_finished = spectatee.invincible_finished;
	this.superweapons_finished = spectatee.superweapons_finished;
	STAT(PRESSED_KEYS, this) = STAT(PRESSED_KEYS, spectatee);
	this.weapons = spectatee.weapons;
	this.vortex_charge = spectatee.vortex_charge;
	this.vortex_chargepool_ammo = spectatee.vortex_chargepool_ammo;
	this.hagar_load = spectatee.hagar_load;
	this.arc_heat_percent = spectatee.arc_heat_percent;
	this.minelayer_mines = spectatee.minelayer_mines;
	this.punchangle = spectatee.punchangle;
	this.view_ofs = spectatee.view_ofs;
	this.velocity = spectatee.velocity;
	this.dmg_take = spectatee.dmg_take;
	this.dmg_save = spectatee.dmg_save;
	this.dmg_inflictor = spectatee.dmg_inflictor;
	this.v_angle = spectatee.v_angle;
	this.angles = spectatee.v_angle;
	STAT(FROZEN, this) = STAT(FROZEN, spectatee);
	this.revive_progress = spectatee.revive_progress;
	this.viewloc = spectatee.viewloc;
	if(!PHYS_INPUT_BUTTON_USE(this) && STAT(CAMERA_SPECTATOR, this) != 2)
		this.fixangle = true;
	setorigin(this, spectatee.origin);
	setsize(this, spectatee.mins, spectatee.maxs);
	SetZoomState(this, spectatee.zoomstate);

	for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	{
		.entity weaponentity = weaponentities[slot];
		this.(weaponentity) = spectatee.(weaponentity);
	}

	for(int slot = 0; slot < MAX_AXH; ++slot)
	{
		this.(AuxiliaryXhair[slot]) = spectatee.(AuxiliaryXhair[slot]);
	}

    anticheat_spectatecopy(this, spectatee);
	this.hud = spectatee.hud;
	if(spectatee.vehicle)
    {
    	this.angles = spectatee.v_angle;

        //this.fixangle = false;
        //this.velocity = spectatee.vehicle.velocity;
        this.vehicle_health = spectatee.vehicle_health;
        this.vehicle_shield = spectatee.vehicle_shield;
        this.vehicle_energy = spectatee.vehicle_energy;
        this.vehicle_ammo1 = spectatee.vehicle_ammo1;
        this.vehicle_ammo2 = spectatee.vehicle_ammo2;
        this.vehicle_reload1 = spectatee.vehicle_reload1;
        this.vehicle_reload2 = spectatee.vehicle_reload2;

        //msg_entity = this;

       // WriteByte (MSG_ONE, SVC_SETVIEWANGLES);
            //WriteAngle(MSG_ONE,  spectatee.v_angle.x);
           // WriteAngle(MSG_ONE,  spectatee.v_angle.y);
           // WriteAngle(MSG_ONE,  spectatee.v_angle.z);

        //WriteByte (MSG_ONE, SVC_SETVIEW);
        //    WriteEntity(MSG_ONE, this);
        //makevectors(spectatee.v_angle);
        //setorigin(this, spectatee.origin - v_forward * 400 + v_up * 300);*/
    }
}

bool SpectateUpdate(entity this)
{
	if(!this.enemy)
		return false;

	if(!IS_PLAYER(this.enemy) || this == this.enemy)
	{
		SetSpectatee(this, NULL);
		return false;
	}

	SpectateCopy(this, this.enemy);

	return true;
}

bool SpectateSet(entity this)
{
	if(!IS_PLAYER(this.enemy))
		return false;

	ClientData_Touch(this.enemy);

	msg_entity = this;
	WriteByte(MSG_ONE, SVC_SETVIEW);
	WriteEntity(MSG_ONE, this.enemy);
	set_movetype(this, MOVETYPE_NONE);
	accuracy_resend(this);

	if(!SpectateUpdate(this))
		PutObserverInServer(this);

	return true;
}

void SetSpectatee_status(entity this, int spectatee_num)
{
	int oldspectatee_status = this.spectatee_status;
	this.spectatee_status = spectatee_num;

	if (this.spectatee_status != oldspectatee_status)
	{
		ClientData_Touch(this);
		if (g_race || g_cts) race_InitSpectator();
	}
}

void SetSpectatee(entity this, entity spectatee)
{
	entity old_spectatee = this.enemy;

	this.enemy = spectatee;

	// WEAPONTODO
	// these are required to fix the spectator bug with arc
	if(old_spectatee)
	{
		for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
		{
			.entity weaponentity = weaponentities[slot];
			if(old_spectatee.(weaponentity).arc_beam)
				old_spectatee.(weaponentity).arc_beam.SendFlags |= ARC_SF_SETTINGS;
		}
	}
	if(this.enemy)
	{
		for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
		{
			.entity weaponentity = weaponentities[slot];
			if(this.enemy.(weaponentity).arc_beam)
				this.enemy.(weaponentity).arc_beam.SendFlags |= ARC_SF_SETTINGS;
		}
	}

	if (this.enemy)
		SetSpectatee_status(this, etof(this.enemy));

	// needed to update spectator list
	if(old_spectatee) { ClientData_Touch(old_spectatee); }
}

bool Spectate(entity this, entity pl)
{
	if(MUTATOR_CALLHOOK(SpectateSet, this, pl))
		return false;
	pl = M_ARGV(1, entity);

	SetSpectatee(this, pl);
	return SpectateSet(this);
}

bool SpectateNext(entity this)
{
	entity ent = find(this.enemy, classname, STR_PLAYER);

	if (MUTATOR_CALLHOOK(SpectateNext, this, ent))
		ent = M_ARGV(1, entity);
	else if (!ent)
		ent = find(ent, classname, STR_PLAYER);

	if(ent) { SetSpectatee(this, ent); }

	return SpectateSet(this);
}

bool SpectatePrev(entity this)
{
	// NOTE: chain order is from the highest to the lower entnum (unlike find)
	entity ent = findchain(classname, STR_PLAYER);
	if (!ent) // no player
		return false;

	entity first = ent;
	// skip players until current spectated player
	if(this.enemy)
	while(ent && ent != this.enemy)
		ent = ent.chain;

	switch (MUTATOR_CALLHOOK(SpectatePrev, this, ent, first))
	{
		case MUT_SPECPREV_FOUND:
		    ent = M_ARGV(1, entity);
		    break;
		case MUT_SPECPREV_RETURN:
		    return true;
		case MUT_SPECPREV_CONTINUE:
		default:
		{
			if(ent.chain)
				ent = ent.chain;
			else
				ent = first;
			break;
		}
	}

	SetSpectatee(this, ent);
	return SpectateSet(this);
}

/*
=============
ShowRespawnCountdown()

Update a respawn countdown display.
=============
*/
void ShowRespawnCountdown(entity this)
{
	float number;
	if(!IS_DEAD(this)) // just respawned?
		return;
	else
	{
		number = ceil(this.respawn_time - time);
		if(number <= 0)
			return;
		if(number <= this.respawn_countdown)
		{
			this.respawn_countdown = number - 1;
			if(ceil(this.respawn_time - (time + 0.5)) == number) // only say it if it is the same number even in 0.5s; to prevent overlapping sounds
				{ Send_Notification(NOTIF_ONE, this, MSG_ANNCE, Announcer_PickNumber(CNT_RESPAWN, number)); }
		}
	}
}

.bool team_selected;
bool ShowTeamSelection(entity this)
{
	if(!teamplay || autocvar_g_campaign || autocvar_g_balance_teams || this.team_selected || (this.wasplayer && autocvar_g_changeteam_banned) || this.team_forced > 0)
		return false;
	stuffcmd(this, "menu_showteamselect\n");
	return true;
}
void Join(entity this)
{
	TRANSMUTE(Player, this);

	if(!this.team_selected)
	if(autocvar_g_campaign || autocvar_g_balance_teams)
		JoinBestTeam(this, false, true);

	if(autocvar_g_campaign)
		campaign_bots_may_start = true;

	Kill_Notification(NOTIF_ONE_ONLY, this, MSG_CENTER, CPID_PREVENT_JOIN);

	PutClientInServer(this);

	if(teamplay && this.team != -1)
		Send_Notification(NOTIF_ALL, NULL, MSG_INFO, APP_TEAM_NUM(this.team, INFO_JOIN_PLAY_TEAM), this.netname);
	else
		Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_JOIN_PLAY, this.netname);
	this.team_selected = false;
}

/**
 * Determines whether the player is allowed to join. This depends on cvar
 * g_maxplayers, if it isn't used this function always return true, otherwise
 * it checks whether the number of currently playing players exceeds g_maxplayers.
 * @return int number of free slots for players, 0 if none
 */
int nJoinAllowed(entity this, entity ignore)
{
	if(!ignore)
	// this is called that way when checking if anyone may be able to join (to build qcstatus)
	// so report 0 free slots if restricted
	{
		if(autocvar_g_forced_team_otherwise == "spectate")
			return 0;
		if(autocvar_g_forced_team_otherwise == "spectator")
			return 0;
	}

	if(this && this.team_forced < 0)
		return 0; // forced spectators can never join

	// TODO simplify this
	int totalClients = 0;
	int currentlyPlaying = 0;
	FOREACH_CLIENT(true, LAMBDA(
		if(it != ignore)
			++totalClients;
		if(IS_REAL_CLIENT(it))
		if(IS_PLAYER(it) || it.caplayer)
			++currentlyPlaying;
	));

	float free_slots = 0;
	if (!autocvar_g_maxplayers)
		free_slots = maxclients - totalClients;
	else if(currentlyPlaying < autocvar_g_maxplayers)
		free_slots = min(maxclients - totalClients, autocvar_g_maxplayers - currentlyPlaying);

	static float join_prevent_msg_time = 0;
	if(this && ignore && !free_slots && time > join_prevent_msg_time)
	{
		Send_Notification(NOTIF_ONE_ONLY, this, MSG_CENTER, CENTER_JOIN_PREVENT);
		join_prevent_msg_time = time + 3;
	}

	return free_slots;
}

/**
 * Checks whether the client is an observer or spectator, if so, he will get kicked after
 * g_maxplayers_spectator_blocktime seconds
 */
void checkSpectatorBlock(entity this)
{
	if(IS_SPEC(this) || IS_OBSERVER(this))
	if(!this.caplayer)
	if(IS_REAL_CLIENT(this))
	{
		if( time > (this.spectatortime + autocvar_g_maxplayers_spectator_blocktime) ) {
			Send_Notification(NOTIF_ONE_ONLY, this, MSG_INFO, INFO_QUIT_KICK_SPECTATING);
			dropclient(this);
		}
	}
}

void PrintWelcomeMessage(entity this)
{
	if(this.motd_actived_time == 0)
	{
		if (autocvar_g_campaign) {
			if ((IS_PLAYER(this) && PHYS_INPUT_BUTTON_INFO(this)) || (!IS_PLAYER(this))) {
				this.motd_actived_time = time;
				Send_Notification(NOTIF_ONE_ONLY, this, MSG_CENTER, CENTER_MOTD, campaign_message);
			}
		} else {
			if (PHYS_INPUT_BUTTON_INFO(this)) {
				this.motd_actived_time = time;
				Send_Notification(NOTIF_ONE_ONLY, this, MSG_CENTER, CENTER_MOTD, getwelcomemessage(this));
			}
		}
	}
	else if(this.motd_actived_time > 0) // showing MOTD or campaign message
	{
		if (autocvar_g_campaign) {
			if (PHYS_INPUT_BUTTON_INFO(this))
				this.motd_actived_time = time;
			else if ((time - this.motd_actived_time > 2) && IS_PLAYER(this)) { // hide it some seconds after BUTTON_INFO has been released
				this.motd_actived_time = 0;
				Kill_Notification(NOTIF_ONE_ONLY, this, MSG_CENTER, CPID_MOTD);
			}
		} else {
			if (PHYS_INPUT_BUTTON_INFO(this))
				this.motd_actived_time = time;
			else if (time - this.motd_actived_time > 2) { // hide it some seconds after BUTTON_INFO has been released
				this.motd_actived_time = 0;
				Kill_Notification(NOTIF_ONE_ONLY, this, MSG_CENTER, CPID_MOTD);
			}
		}
	}
	else //if(this.motd_actived_time < 0) // just connected, motd is active
	{
		if(PHYS_INPUT_BUTTON_INFO(this)) // BUTTON_INFO hides initial MOTD
			this.motd_actived_time = -2; // wait until BUTTON_INFO gets released
		else if(this.motd_actived_time == -2 || IS_PLAYER(this) || IS_SPEC(this))
		{
			// instanctly hide MOTD
			this.motd_actived_time = 0;
			Kill_Notification(NOTIF_ONE_ONLY, this, MSG_CENTER, CPID_MOTD);
		}
	}
}

bool joinAllowed(entity this)
{
	if (this.version_mismatch) return false;
	if (!nJoinAllowed(this, this)) return false;
	if (teamplay && lockteams) return false;
	if (ShowTeamSelection(this)) return false;
	if (MUTATOR_CALLHOOK(ForbidSpawn, this)) return false;
	return true;
}

void ObserverThink(entity this)
{
	if ( this.impulse )
	{
		MinigameImpulse(this, this.impulse);
		this.impulse = 0;
	}

	if (this.flags & FL_JUMPRELEASED) {
		if (PHYS_INPUT_BUTTON_JUMP(this) && joinAllowed(this)) {
			this.flags &= ~FL_JUMPRELEASED;
			this.flags |= FL_SPAWNING;
		} else if(PHYS_INPUT_BUTTON_ATCK(this) && !this.version_mismatch) {
			this.flags &= ~FL_JUMPRELEASED;
			if(SpectateNext(this)) {
				TRANSMUTE(Spectator, this);
			}
		} else {
			int preferred_movetype = ((!PHYS_INPUT_BUTTON_USE(this) ? this.cvar_cl_clippedspectating : !this.cvar_cl_clippedspectating) ? MOVETYPE_FLY_WORLDONLY : MOVETYPE_NOCLIP);
			set_movetype(this, preferred_movetype);
		}
	} else {
		if (!(PHYS_INPUT_BUTTON_ATCK(this) || PHYS_INPUT_BUTTON_JUMP(this))) {
			this.flags |= FL_JUMPRELEASED;
			if(this.flags & FL_SPAWNING)
			{
				this.flags &= ~FL_SPAWNING;
				Join(this);
				return;
			}
		}
	}
}

void SpectatorThink(entity this)
{
	if ( this.impulse )
	{
		if(MinigameImpulse(this, this.impulse))
			this.impulse = 0;

		if (this.impulse == IMP_weapon_drop.impulse)
		{
			STAT(CAMERA_SPECTATOR, this) = (STAT(CAMERA_SPECTATOR, this) + 1) % 3;
			this.impulse = 0;
			return;
		}
	}

	if (this.flags & FL_JUMPRELEASED) {
		if (PHYS_INPUT_BUTTON_JUMP(this) && joinAllowed(this)) {
			this.flags &= ~FL_JUMPRELEASED;
			this.flags |= FL_SPAWNING;
		} else if(PHYS_INPUT_BUTTON_ATCK(this) || this.impulse == 10 || this.impulse == 15 || this.impulse == 18 || (this.impulse >= 200 && this.impulse <= 209)) {
			this.flags &= ~FL_JUMPRELEASED;
			if(SpectateNext(this)) {
				TRANSMUTE(Spectator, this);
			} else {
				TRANSMUTE(Observer, this);
				PutClientInServer(this);
			}
			this.impulse = 0;
		} else if(this.impulse == 12 || this.impulse == 16  || this.impulse == 19 || (this.impulse >= 220 && this.impulse <= 229)) {
			this.flags &= ~FL_JUMPRELEASED;
			if(SpectatePrev(this)) {
				TRANSMUTE(Spectator, this);
			} else {
				TRANSMUTE(Observer, this);
				PutClientInServer(this);
			}
			this.impulse = 0;
		} else if (PHYS_INPUT_BUTTON_ATCK2(this)) {
			this.flags &= ~FL_JUMPRELEASED;
			TRANSMUTE(Observer, this);
			PutClientInServer(this);
		} else {
			if(!SpectateUpdate(this))
				PutObserverInServer(this);
		}
	} else {
		if (!(PHYS_INPUT_BUTTON_ATCK(this) || PHYS_INPUT_BUTTON_ATCK2(this))) {
			this.flags |= FL_JUMPRELEASED;
			if(this.flags & FL_SPAWNING)
			{
				this.flags &= ~FL_SPAWNING;
				Join(this);
				return;
			}
		}
		if(!SpectateUpdate(this))
			PutObserverInServer(this);
	}

	this.flags |= FL_CLIENT | FL_NOTARGET;
}

void vehicles_enter (entity pl, entity veh);
void PlayerUseKey(entity this)
{
	if (!IS_PLAYER(this))
		return;

	if(this.vehicle)
	{
		if(!game_stopped)
		{
			vehicles_exit(this.vehicle, VHEF_NORMAL);
			return;
		}
	}
	else if(autocvar_g_vehicles_enter)
	{
		if(!STAT(FROZEN, this))
		if(!IS_DEAD(this))
		if(!game_stopped)
		{
			entity head, closest_target = NULL;
			head = WarpZone_FindRadius(this.origin, autocvar_g_vehicles_enter_radius, true);

			while(head) // find the closest acceptable target to enter
			{
				if(IS_VEHICLE(head))
				if(!IS_DEAD(head))
				if(!head.owner || ((head.vehicle_flags & VHF_MULTISLOT) && SAME_TEAM(head.owner, this)))
				if(head.takedamage != DAMAGE_NO)
				{
					if(closest_target)
					{
						if(vlen2(this.origin - head.origin) < vlen2(this.origin - closest_target.origin))
						{ closest_target = head; }
					}
					else { closest_target = head; }
				}

				head = head.chain;
			}

			if(closest_target) { vehicles_enter(this, closest_target); return; }
		}
	}

	// a use key was pressed; call handlers
	MUTATOR_CALLHOOK(PlayerUseKey, this);
}


/*
=============
PlayerPreThink

Called every frame for each client before the physics are run
=============
*/
.float usekeypressed;
.float last_vehiclecheck;
.int items_added;
void PlayerPreThink (entity this)
{
	WarpZone_PlayerPhysics_FixVAngle(this);

    STAT(GAMESTARTTIME, this) = game_starttime;
	STAT(ROUNDSTARTTIME, this) = round_starttime;
	STAT(ALLOW_OLDVORTEXBEAM, this) = autocvar_g_allow_oldvortexbeam;
	STAT(LEADLIMIT, this) = autocvar_leadlimit;

	STAT(WEAPONSINMAP, this) = weaponsInMap;

	if (frametime) {
		// physics frames: update anticheat stuff
		anticheat_prethink(this);
	}

	if (blockSpectators && frametime) {
		// WORKAROUND: only use dropclient in server frames (frametime set).
		// Never use it in cl_movement frames (frametime zero).
		checkSpectatorBlock(this);
    }

	zoomstate_set = false;

	// Check for nameless players
	if (isInvisibleString(this.netname)) {
		this.netname = strzone(sprintf("Player#%d", this.playerid));
		// stuffcmd(this, strcat("name ", this.netname, "\n")); // maybe?
	}
	if (this.netname != this.netname_previous) {
		if (autocvar_sv_eventlog) {
			GameLogEcho(strcat(":name:", ftos(this.playerid), ":", playername(this, false)));
        }
		if (this.netname_previous) strunzone(this.netname_previous);
		this.netname_previous = strzone(this.netname);
	}

	// version nagging
	if (this.version_nagtime && this.cvar_g_xonoticversion && time > this.version_nagtime) {
        this.version_nagtime = 0;
        if (strstrofs(this.cvar_g_xonoticversion, "git", 0) >= 0 || strstrofs(this.cvar_g_xonoticversion, "autobuild", 0) >= 0) {
            // git client
        } else if (strstrofs(autocvar_g_xonoticversion, "git", 0) >= 0 || strstrofs(autocvar_g_xonoticversion, "autobuild", 0) >= 0) {
            // git server
            Send_Notification(NOTIF_ONE_ONLY, this, MSG_INFO, INFO_VERSION_BETA, autocvar_g_xonoticversion, this.cvar_g_xonoticversion);
        } else {
            int r = vercmp(this.cvar_g_xonoticversion, autocvar_g_xonoticversion);
            if (r < 0) { // old client
                Send_Notification(NOTIF_ONE_ONLY, this, MSG_INFO, INFO_VERSION_OUTDATED, autocvar_g_xonoticversion, this.cvar_g_xonoticversion);
            } else if (r > 0) { // old server
                Send_Notification(NOTIF_ONE_ONLY, this, MSG_INFO, INFO_VERSION_OLD, autocvar_g_xonoticversion, this.cvar_g_xonoticversion);
            }
        }
    }

	// GOD MODE info
	if (!(this.flags & FL_GODMODE) && this.max_armorvalue)
	{
		Send_Notification(NOTIF_ONE_ONLY, this, MSG_INFO, INFO_GODMODE_OFF, this.max_armorvalue);
		this.max_armorvalue = 0;
	}

	if (STAT(FROZEN, this) == 2)
	{
		this.revive_progress = bound(0, this.revive_progress + frametime * this.revive_speed, 1);
		this.health = max(1, this.revive_progress * start_health);
		this.iceblock.alpha = bound(0.2, 1 - this.revive_progress, 1);

		if (this.revive_progress >= 1)
			Unfreeze(this);
	}
	else if (STAT(FROZEN, this) == 3)
	{
		this.revive_progress = bound(0, this.revive_progress - frametime * this.revive_speed, 1);
		this.health = max(0, autocvar_g_nades_ice_health + (start_health-autocvar_g_nades_ice_health) * this.revive_progress );

		if (this.health < 1)
		{
			if (this.vehicle)
				vehicles_exit(this.vehicle, VHEF_RELEASE);
			if(this.event_damage)
				this.event_damage(this, this, this.frozen_by, 1, DEATH_NADE_ICE_FREEZE.m_id, this.origin, '0 0 0');
		}
		else if (this.revive_progress <= 0)
			Unfreeze(this);
	}

	MUTATOR_CALLHOOK(PlayerPreThink, this);

	if(autocvar_g_vehicles_enter && (time > this.last_vehiclecheck) && !game_stopped && !this.vehicle)
	if(IS_PLAYER(this) && !STAT(FROZEN, this) && !IS_DEAD(this))
	{
		FOREACH_ENTITY_RADIUS(this.origin, autocvar_g_vehicles_enter_radius, IS_VEHICLE(it),
		{
			if(!IS_DEAD(it) && it.takedamage != DAMAGE_NO)
			if((it.vehicle_flags & VHF_MULTISLOT) && SAME_TEAM(it.owner, this))
			{
				Send_Notification(NOTIF_ONE, this, MSG_CENTER, CENTER_VEHICLE_ENTER_GUNNER);
			}
			else if(!it.owner)
			{
				if(!it.team || SAME_TEAM(this, it))
					Send_Notification(NOTIF_ONE, this, MSG_CENTER, CENTER_VEHICLE_ENTER);
				else if(autocvar_g_vehicles_steal)
					Send_Notification(NOTIF_ONE, this, MSG_CENTER, CENTER_VEHICLE_ENTER_STEAL);
			}
		});

		this.last_vehiclecheck = time + 1;
	}

	if(!this.cvar_cl_newusekeysupported) // FIXME remove this - it was a stupid idea to begin with, we can JUST use the button
	{
		if(PHYS_INPUT_BUTTON_USE(this) && !this.usekeypressed)
			PlayerUseKey(this);
		this.usekeypressed = PHYS_INPUT_BUTTON_USE(this);
	}

	if (IS_REAL_CLIENT(this))
		PrintWelcomeMessage(this);

	if (IS_PLAYER(this)) {
		CheckRules_Player(this);

		if (game_stopped || intermission_running) {
			this.modelflags &= ~MF_ROCKET;
			if(intermission_running)
				IntermissionThink(this);
			return;
		}

		if (timeout_status == TIMEOUT_ACTIVE) {
            // don't allow the player to turn around while game is paused
			// FIXME turn this into CSQC stuff
			this.v_angle = this.lastV_angle;
			this.angles = this.lastV_angle;
			this.fixangle = true;
		}

		if (frametime) player_powerups(this);

		if (IS_DEAD(this)) {
			if (this.personal && g_race_qualifying) {
				if (time > this.respawn_time) {
					STAT(RESPAWN_TIME, this) = this.respawn_time = time + 1; // only retry once a second
					respawn(this);
					this.impulse = CHIMPULSE_SPEEDRUN.impulse;
				}
			} else {
				if (frametime) player_anim(this);
				bool button_pressed = (PHYS_INPUT_BUTTON_ATCK(this) || PHYS_INPUT_BUTTON_JUMP(this) || PHYS_INPUT_BUTTON_ATCK2(this) || PHYS_INPUT_BUTTON_HOOK(this) || PHYS_INPUT_BUTTON_USE(this));

				switch(this.deadflag)
				{
					case DEAD_DYING:
					{
						if ((this.respawn_flags & RESPAWN_FORCE) && !(this.respawn_time < this.respawn_time_max))
							this.deadflag = DEAD_RESPAWNING;
						else if (!button_pressed || (time >= this.respawn_time_max && (this.respawn_flags & RESPAWN_FORCE)))
							this.deadflag = DEAD_DEAD;
						break;
					}
					case DEAD_DEAD:
					{
						if (button_pressed)
							this.deadflag = DEAD_RESPAWNABLE;
						else if (time >= this.respawn_time_max && (this.respawn_flags & RESPAWN_FORCE))
							this.deadflag = DEAD_RESPAWNING;
						break;
					}
					case DEAD_RESPAWNABLE:
					{
						if (!button_pressed || (this.respawn_flags & RESPAWN_FORCE))
							this.deadflag = DEAD_RESPAWNING;
						break;
					}
					case DEAD_RESPAWNING:
					{
						if (time > this.respawn_time)
						{
							this.respawn_time = time + 1; // only retry once a second
							this.respawn_time_max = this.respawn_time;
							respawn(this);
						}
						break;
					}
				}

				ShowRespawnCountdown(this);

				if (this.respawn_flags & RESPAWN_SILENT)
					STAT(RESPAWN_TIME, this) = 0;
				else if ((this.respawn_flags & RESPAWN_FORCE) && this.respawn_time < this.respawn_time_max)
				{
					if (time < this.respawn_time)
						STAT(RESPAWN_TIME, this) = this.respawn_time;
					else if (this.deadflag != DEAD_RESPAWNING)
						STAT(RESPAWN_TIME, this) = -this.respawn_time_max;
				}
				else
					STAT(RESPAWN_TIME, this) = this.respawn_time;
			}

			// if respawning, invert stat_respawn_time to indicate this, the client translates it
			if (this.deadflag == DEAD_RESPAWNING && STAT(RESPAWN_TIME, this) > 0)
				STAT(RESPAWN_TIME, this) *= -1;

			return;
		}

		this.prevorigin = this.origin;

		bool have_hook = false;
		for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
		{
			.entity weaponentity = weaponentities[slot];
			if(this.(weaponentity).hook.state)
			{
				have_hook = true;
				break;
			}
		}
		bool do_crouch = PHYS_INPUT_BUTTON_CROUCH(this);
		if (have_hook) {
			do_crouch = false;
		} else if (this.waterlevel >= WATERLEVEL_SWIMMING) {
			do_crouch = false;
		} else if (this.vehicle) {
			do_crouch = false;
		} else if (STAT(FROZEN, this)) {
			do_crouch = false;
        }

		if (do_crouch) {
			if (!this.crouch) {
				this.crouch = true;
				this.view_ofs = STAT(PL_CROUCH_VIEW_OFS, this);
				setsize(this, STAT(PL_CROUCH_MIN, this), STAT(PL_CROUCH_MAX, this));
				// setanim(this, this.anim_duck, false, true, true); // this anim is BROKEN anyway
			}
		} else if (this.crouch) {
            tracebox(this.origin, STAT(PL_MIN, this), STAT(PL_MAX, this), this.origin, false, this);
            if (!trace_startsolid) {
                this.crouch = false;
                this.view_ofs = STAT(PL_VIEW_OFS, this);
                setsize(this, STAT(PL_MIN, this), STAT(PL_MAX, this));
            }
		}

		FixPlayermodel(this);

		// LordHavoc: allow firing on move frames (sub-ticrate), this gives better timing on slow servers
		//if(frametime)
		{
			this.items &= ~this.items_added;

			for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
			{
				.entity weaponentity = weaponentities[slot];
				W_WeaponFrame(this, weaponentity);

				if(slot == 0)
				{
					this.clip_load = this.(weaponentity).clip_load;
					this.clip_size = this.(weaponentity).clip_size;
				}
			}

			this.items_added = 0;
			if (this.items & ITEM_Jetpack.m_itemid && (this.items & ITEM_JetpackRegen.m_itemid || this.ammo_fuel >= 0.01))
                this.items_added |= IT_FUEL;

			this.items |= this.items_added;
		}

		player_regen(this);

		// WEAPONTODO: Add a weapon request for this
		// rot vortex charge to the charge limit
		for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
		{
			.entity weaponentity = weaponentities[slot];
			if (WEP_CVAR(vortex, charge_rot_rate) && this.(weaponentity).vortex_charge > WEP_CVAR(vortex, charge_limit) && this.(weaponentity).vortex_charge_rottime < time)
				this.(weaponentity).vortex_charge = bound(WEP_CVAR(vortex, charge_limit), this.(weaponentity).vortex_charge - WEP_CVAR(vortex, charge_rot_rate) * frametime / W_TICSPERFRAME, 1);
		}

		if (frametime) player_anim(this);

		// secret status
		secrets_setstatus(this);

		// monsters status
		monsters_setstatus(this);

		this.dmg_team = max(0, this.dmg_team - autocvar_g_teamdamage_resetspeed * frametime);
	}
	else if (game_stopped || intermission_running) {
		if(intermission_running)
			IntermissionThink(this);
		return;
	}
	else if (IS_OBSERVER(this)) {
		ObserverThink(this);
	}
	else if (IS_SPEC(this)) {
		SpectatorThink(this);
	}

	// WEAPONTODO: Add weapon request for this
	if (!zoomstate_set) {
		bool wep_zoomed = false;
		for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
		{
			.entity weaponentity = weaponentities[slot];
			Weapon thiswep = this.(weaponentity).m_weapon;
			if(thiswep != WEP_Null && thiswep.wr_zoom)
				wep_zoomed += thiswep.wr_zoom(thiswep, this);
		}
		SetZoomState(this, PHYS_INPUT_BUTTON_ZOOM(this) || PHYS_INPUT_BUTTON_ZOOMSCRIPT(this) || wep_zoomed);
    }

	if (this.teamkill_soundtime && time > this.teamkill_soundtime)
	{
		this.teamkill_soundtime = 0;

		entity e = this.teamkill_soundsource;
		entity oldpusher = e.pusher;
		e.pusher = this;
		PlayerSound(e, playersound_teamshoot, CH_VOICE, VOL_BASEVOICE, VOICETYPE_LASTATTACKER_ONLY);
		e.pusher = oldpusher;
	}

	if (this.taunt_soundtime && time > this.taunt_soundtime) {
		this.taunt_soundtime = 0;
		PlayerSound(this, playersound_taunt, CH_VOICE, VOL_BASEVOICE, VOICETYPE_AUTOTAUNT);
	}

	target_voicescript_next(this);

	// WEAPONTODO: Move into weaponsystem somehow
	// if a player goes unarmed after holding a loaded weapon, empty his clip size and remove the crosshair ammo ring
	for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	{
		.entity weaponentity = weaponentities[slot];
		if(this.(weaponentity).m_weapon == WEP_Null)
			this.(weaponentity).clip_load = this.(weaponentity).clip_size = 0;
	}
}

void DrownPlayer(entity this)
{
	if(IS_DEAD(this))
		return;

	if (this.waterlevel != WATERLEVEL_SUBMERGED || this.vehicle)
	{
		if(this.air_finished < time)
			PlayerSound(this, playersound_gasp, CH_PLAYER, VOL_BASE, VOICETYPE_PLAYERSOUND);
		this.air_finished = time + autocvar_g_balance_contents_drowndelay;
		this.dmg = 2;
	}
	else if (this.air_finished < time)
	{	// drown!
		if (this.pain_finished < time)
		{
			Damage (this, NULL, NULL, autocvar_g_balance_contents_playerdamage_drowning * autocvar_g_balance_contents_damagerate, DEATH_DROWN.m_id, this.origin, '0 0 0');
			this.pain_finished = time + 0.5;
		}
	}
}

.bool move_qcphysics;

void Player_Physics(entity this)
{
	set_movetype(this, this.move_movetype);

	if(!this.move_qcphysics)
		return;

	if(!frametime && !this.pm_frametime)
		return;

	Movetype_Physics_NoMatchTicrate(this, this.pm_frametime, true);

	this.pm_frametime = 0;
}

/*
=============
PlayerPostThink

Called every frame for each client after the physics are run
=============
*/
.float idlekick_lasttimeleft;
void PlayerPostThink (entity this)
{
	Player_Physics(this);

	if (sv_maxidle > 0)
	if (frametime) // WORKAROUND: only use dropclient in server frames (frametime set). Never use it in cl_movement frames (frametime zero).
	if (IS_REAL_CLIENT(this))
	if (IS_PLAYER(this) || sv_maxidle_spectatorsareidle)
	{
		int totalClients = 0;
		if(sv_maxidle_slots > 0)
		{
			FOREACH_CLIENT(IS_REAL_CLIENT(it) || sv_maxidle_slots_countbots,
			{
				++totalClients;
			});
		}

		if (sv_maxidle_slots > 0 && (maxclients - totalClients) > sv_maxidle_slots)
		{ /* do nothing */ }
		else if (time - this.parm_idlesince < 1) // instead of (time == this.parm_idlesince) to support sv_maxidle <= 10
		{
			if (this.idlekick_lasttimeleft)
			{
				this.idlekick_lasttimeleft = 0;
				Kill_Notification(NOTIF_ONE_ONLY, this, MSG_CENTER, CPID_IDLING);
			}
		}
		else
		{
			float timeleft = ceil(sv_maxidle - (time - this.parm_idlesince));
			if (timeleft == min(10, sv_maxidle - 1)) { // - 1 to support sv_maxidle <= 10
				if (!this.idlekick_lasttimeleft)
					Send_Notification(NOTIF_ONE_ONLY, this, MSG_CENTER, CENTER_DISCONNECT_IDLING, timeleft);
			}
			if (timeleft <= 0) {
				Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_QUIT_KICK_IDLING, this.netname);
				dropclient(this);
				return;
			}
			else if (timeleft <= 10) {
				if (timeleft != this.idlekick_lasttimeleft) {
				    Send_Notification(NOTIF_ONE, this, MSG_ANNCE, Announcer_PickNumber(CNT_IDLE, timeleft));
                }
				this.idlekick_lasttimeleft = timeleft;
			}
		}
	}

	CheatFrame(this);

	//CheckPlayerJump();
	if (game_stopped)
	{
		this.solid = SOLID_NOT;
		this.takedamage = DAMAGE_NO;
		set_movetype(this, MOVETYPE_NONE);
	}

	if (IS_PLAYER(this)) {
		DrownPlayer(this);
		CheckRules_Player(this);
		UpdateChatBubble(this);
		if (this.impulse) ImpulseCommands(this);
		if (game_stopped)
		{
			CSQCMODEL_AUTOUPDATE(this);
			return;
		}
		GetPressedKeys(this);
	}

	if (this.waypointsprite_attachedforcarrier) {
	    vector v = healtharmor_maxdamage(this.health, this.armorvalue, autocvar_g_balance_armor_blockpercent, DEATH_WEAPON.m_id);
		WaypointSprite_UpdateHealth(this.waypointsprite_attachedforcarrier, '1 0 0' * v);
    }

	playerdemo_write(this);

	CSQCMODEL_AUTOUPDATE(this);
}
