#include "client.qh"

#include <common/csqcmodel_settings.qh>
#include <common/deathtypes/all.qh>
#include <common/debug.qh>
#include <common/effects/all.qh>
#include <common/effects/qc/globalsound.qh>
#include <common/ent_cs.qh>
#include <common/gametypes/_mod.qh>
#include <common/gametypes/gametype/nexball/sv_nexball.qh>
#include <common/items/_mod.qh>
#include <common/items/inventory.qh>
#include <common/mapobjects/func/conveyor.qh>
#include <common/mapobjects/func/ladder.qh>
#include <common/mapobjects/subs.qh>
#include <common/mapobjects/target/spawnpoint.qh>
#include <common/mapobjects/teleporters.qh>
#include <common/mapobjects/trigger/counter.qh>
#include <common/mapobjects/trigger/secret.qh>
#include <common/mapobjects/trigger/swamp.qh>
#include <common/mapobjects/triggers.qh>
#include <common/minigames/sv_minigames.qh>
#include <common/monsters/sv_monsters.qh>
#include <common/mutators/mutator/instagib/sv_instagib.qh>
#include <common/mutators/mutator/nades/_mod.qh>
#include <common/mutators/mutator/overkill/oknex.qh>
#include <common/mutators/mutator/status_effects/_mod.qh>
#include <common/mutators/mutator/waypoints/all.qh>
#include <common/net_linked.qh>
#include <common/net_notice.qh>
#include <common/notifications/all.qh>
#include <common/physics/player.qh>
#include <common/playerstats.qh>
#include <common/resources/sv_resources.qh>
#include <common/state.qh>
#include <common/stats.qh>
#include <common/vehicles/all.qh>
#include <common/vehicles/sv_vehicles.qh>
#include <common/viewloc.qh>
#include <common/weapons/_all.qh>
#include <common/weapons/weapon/vortex.qh>
#include <common/wepent.qh>
#include <lib/csqcmodel/sv_model.qh>
#include <lib/warpzone/common.qh>
#include <lib/warpzone/server.qh>
#include <server/anticheat.qh>
#include <server/antilag.qh>
#include <server/bot/api.qh>
#include <server/bot/default/cvars.qh>
#include <server/bot/default/waypoints.qh>
#include <server/campaign.qh>
#include <server/chat.qh>
#include <server/cheats.qh>
#include <server/clientkill.qh>
#include <server/command/banning.qh>
#include <server/command/cmd.qh>
#include <server/command/common.qh>
#include <server/command/vote.qh>
#include <server/compat/quake3.qh>
#include <server/damage.qh>
#include <server/gamelog.qh>
#include <server/handicap.qh>
#include <server/hook.qh>
#include <server/impulse.qh>
#include <server/intermission.qh>
#include <server/ipban.qh>
#include <server/main.qh>
#include <server/mutators/_mod.qh>
#include <server/player.qh>
#include <server/portals.qh>
#include <server/race.qh>
#include <server/scores.qh>
#include <server/scores_rules.qh>
#include <server/spawnpoints.qh>
#include <server/teamplay.qh>
#include <server/weapons/accuracy.qh>
#include <server/weapons/common.qh>
#include <server/weapons/hitplot.qh>
#include <server/weapons/selection.qh>
#include <server/weapons/tracing.qh>
#include <server/weapons/weaponsystem.qh>
#include <server/world.qh>

STATIC_METHOD(Client, Add, void(Client this, int _team))
{
	ClientConnect(this);
	TRANSMUTE(Player, this);
	this.frame = 12; // 7
	this.team = _team;
	PutClientInServer(this);
}

STATIC_METHOD(Client, Remove, void(Client this))
{
	TRANSMUTE(Observer, this);
	PutClientInServer(this);
	ClientDisconnect(this);
}

int CountSpectators(entity player, entity to)
{
	if(!player) return 0; // not sure how, but best to be safe

	int spec_count = 0;

	FOREACH_CLIENT(IS_REAL_CLIENT(it) && IS_SPEC(it) && it != to && it.enemy == player,
	{
		spec_count++;
	});

	return spec_count;
}

void WriteSpectators(entity player, entity to)
{
	if(!player) return; // not sure how, but best to be safe

	int spec_count = 0;
	FOREACH_CLIENT(IS_REAL_CLIENT(it) && IS_SPEC(it) && it != to && it.enemy == player,
	{
		if(spec_count >= MAX_SPECTATORS)
			break;
		WriteByte(MSG_ENTITY, num_for_edict(it));
		++spec_count;
	});
}

bool ClientData_Send(entity this, entity to, int sf)
{
	assert(to == this.owner, return false);

	entity e = to;
	if (IS_SPEC(e)) e = e.enemy;

	sf = 0;
	if (CS(e).race_completed)       sf |= BIT(0); // forced scoreboard
	if (CS(to).spectatee_status)    sf |= BIT(1); // spectator ent number follows
	if (CS(e).zoomstate)            sf |= BIT(2); // zoomed
	if (observe_blocked_if_eliminated && INGAME(to))
	                                sf |= BIT(3); // observing blocked
	if (autocvar_sv_showspectators == 1 || (autocvar_sv_showspectators && IS_SPEC(to)))
	                                sf |= BIT(4); // show spectators
	if (autocvar_sv_teamnagger && teamplay && !(autocvar_bot_vs_human && AVAILABLE_TEAMS == 2))
	                                sf |= (autocvar_sv_teamnagger & 0x03) << 5; // BIT(5) | BIT(6)

	WriteHeader(MSG_ENTITY, ENT_CLIENT_CLIENTDATA);
	WriteByte(MSG_ENTITY, sf);

	if (sf & BIT(1))
		WriteByte(MSG_ENTITY, CS(to).spectatee_status);

	if(sf & BIT(4))
	{
		float specs = CountSpectators(e, to);
		WriteByte(MSG_ENTITY, specs);
		WriteSpectators(e, to);
	}

	return true;
}

void ClientData_Attach(entity this)
{
	Net_LinkEntity(CS(this).clientdata = new_pure(clientdata), false, 0, ClientData_Send);
	CS(this).clientdata.drawonlytoclient = this;
	CS(this).clientdata.owner = this;
}

void ClientData_Detach(entity this)
{
	delete(CS(this).clientdata);
	CS(this).clientdata = NULL;
}

void ClientData_Touch(entity e)
{
	entity cd = CS(e).clientdata;
	if (cd) cd.SendFlags = 1;

	// make it spectatable
	FOREACH_CLIENT(IS_REAL_CLIENT(it) && it != e && IS_SPEC(it) && it.enemy == e,
	{
		entity cd = CS(it).clientdata;
		if (cd) cd.SendFlags = 1;
	});
}


/*
=============
CheckPlayerModel

Checks if the argument string can be a valid playermodel.
Returns a valid one in doubt.
=============
*/
string FallbackPlayerModel;
string CheckPlayerModel(string plyermodel)
{
	if(FallbackPlayerModel != cvar_defstring("_cl_playermodel"))
	{
		// note: we cannot summon Don Strunzone here, some player may
		// still have the model string set. In case anyone manages how
		// to change a cvar default, we'll have a small leak here.
		FallbackPlayerModel = strzone(cvar_defstring("_cl_playermodel"));
	}
	// only in right path
	if(substring(plyermodel, 0, 14) != "models/player/")
		return FallbackPlayerModel;
	// only good file extensions
	if(substring(plyermodel, -4, 4) != ".iqm"
	&& substring(plyermodel, -4, 4) != ".zym"
	&& substring(plyermodel, -4, 4) != ".dpm"
	&& substring(plyermodel, -4, 4) != ".md3"
	&& substring(plyermodel, -4, 4) != ".psk")
		return FallbackPlayerModel;

	// forbid the LOD models
	if(substring(plyermodel, -9, 5) == "_lod1" || substring(plyermodel, -9, 5) == "_lod2")
		return FallbackPlayerModel;
	if(plyermodel != strtolower(plyermodel))
		return FallbackPlayerModel;
	// also, restrict to server models
	if(autocvar_sv_servermodelsonly)
		if(!fexists(plyermodel))
			return FallbackPlayerModel;

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

entity SelectObservePoint(entity this)
{
	RandomSelection_Init();
	IL_EACH(g_observepoints, true,
	{
		RandomSelection_AddEnt(it, 1, 1);
	});
	return RandomSelection_chosen_ent;
}

/** putting a client as observer in the server */
void PutObserverInServer(entity this, bool is_forced, bool use_spawnpoint)
{
	bool mutator_returnvalue = MUTATOR_CALLHOOK(MakePlayerObserver, this, is_forced);
	bool recount_ready = false;
	PlayerState_detach(this);

	bool was_player = false;
	if (IS_PLAYER(this))
	{
		if(GetResource(this, RES_HEALTH) >= 1)
		{
			// despawn effect
			Send_Effect(EFFECT_SPAWN, this.origin, '0 0 0', 1);
		}

		// was a player, recount votes and ready status
		if(IS_REAL_CLIENT(this))
		{
			if (vote_called) { VoteCount(false); }
			this.ready = false;
			if (warmup_stage || game_starttime > time) /* warmup OR countdown */ recount_ready = true;
		}
		entcs_update_players(this);
		was_player = true;
	}

	if (use_spawnpoint)
	{
		// first try to find a random "nice" location to view from
		entity spot = SelectObservePoint(this);
		bool is_observepoint = (spot != NULL);
		if(!spot) // otherwise just use the player spawn points
			spot = SelectSpawnPoint(this, true);
		if (!spot) LOG_FATAL("No spawnpoints for observers?!?");

		this.angles = vec2(spot.angles);
		// offset it so that the spectator spawns higher off the ground, looks better this way
		setorigin(this, spot.origin + (is_observepoint ? '0 0 0' : autocvar_sv_player_viewoffset));
	}
	else // change origin to restore previous view origin
		setorigin(this, this.origin + STAT(PL_VIEW_OFS, this) - STAT(PL_CROUCH_VIEW_OFS, this));
	this.fixangle = true;

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

	RemoveGrapplingHooks(this);
	Portal_ClearAll(this);
	SetSpectatee(this, NULL);

	if (this.alivetime_start)
	{
		if (!warmup_stage)
			PlayerStats_GameReport_Event_Player(this, PLAYERSTATS_ALIVETIME, max(0, time - this.alivetime_start));
		this.alivetime_start = 0;
	}

	if (this.vehicle) vehicles_exit(this.vehicle, VHEF_RELEASE);

	TRANSMUTE(Observer, this);

	WaypointSprite_PlayerDead(this);
	accuracy_resend(this);

	if (CS(this).killcount != FRAGS_SPECTATOR && !game_stopped && CHAT_NOSPECTATORS())
		Send_Notification(NOTIF_ONE_ONLY, this, MSG_INFO, INFO_CHAT_NOSPECTATORS);

	CS(this).spectatortime = time;
	if (!autocvar_sv_spectate && CS(this).autojoin_checked) // unnecessary if autojoin succeeds, on failure it notifies
		Send_Notification(NOTIF_ONE_ONLY, this, MSG_MULTI, SPECTATE_WARNING, autocvar_g_maxplayers_spectator_blocktime);

	if(this.bot_attack)
		IL_REMOVE(g_bot_targets, this);
	this.bot_attack = false;
	if(this.monster_attack)
		IL_REMOVE(g_monster_targets, this);
	this.monster_attack = false;
	STAT(HUD, this) = HUD_NORMAL;
	this.iscreature = false;
	this.teleportable = TELEPORT_SIMPLE;
	if(this.damagedbycontents)
		IL_REMOVE(g_damagedbycontents, this);
	this.damagedbycontents = false;
	SetResourceExplicit(this, RES_HEALTH, FRAGS_SPECTATOR);
	SetSpectatee_status(this, etof(this));
	this.takedamage = DAMAGE_NO;
	this.solid = SOLID_NOT;
	set_movetype(this, MOVETYPE_FLY_WORLDONLY); // user preference is controlled by playerprethink
	this.flags = FL_CLIENT | FL_NOTARGET;
	this.effects = 0;
	SetResourceExplicit(this, RES_ARMOR, autocvar_g_balance_armor_start); // was 666?!
	this.pauserotarmor_finished = 0;
	this.pauserothealth_finished = 0;
	this.pauseregen_finished = 0;
	this.damageforcescale = 0;
	this.death_time = 0;
	this.respawn_flags = 0;
	this.respawn_time = 0;
	STAT(RESPAWN_TIME, this) = 0;
	this.alpha = 0;
	this.scale = 0;
	this.fade_time = 0;
	this.pain_finished = 0;
	STAT(AIR_FINISHED, this) = 0;
	//this.dphitcontentsmask = 0;
	this.dphitcontentsmask = DPCONTENTS_SOLID;
	if (autocvar_g_playerclip_collisions)
		this.dphitcontentsmask |= DPCONTENTS_PLAYERCLIP;
	this.pushltime = 0;
	this.istypefrag = 0;
	setthink(this, func_null);
	this.nextthink = 0;
	this.deadflag = DEAD_NO;
	UNSET_DUCKED(this);
	this.draggable = drag_undraggable;

	player_powerups_remove_all(this, was_player);
	this.items = 0;
	STAT(WEAPONS, this) = '0 0 0';
	this.drawonlytoclient = this;

	this.viewloc = NULL;

	//this.spawnpoint_targ = NULL; // keep it so they can return to where they were?

	this.weaponmodel = "";
	for (int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	{
		this.weaponentities[slot] = NULL;
	}
	this.exteriorweaponentity = NULL;
	CS(this).killcount = FRAGS_SPECTATOR;
	this.velocity = '0 0 0';
	this.avelocity = '0 0 0';
	this.punchangle = '0 0 0';
	this.punchvector = '0 0 0';
	this.oldvelocity = this.velocity;
	this.event_damage = func_null;
	this.event_heal = func_null;

	for(int slot = 0; slot < MAX_AXH; ++slot)
	{
		entity axh = this.(AuxiliaryXhair[slot]);
		this.(AuxiliaryXhair[slot]) = NULL;

		if(axh.owner == this && axh != NULL && !wasfreed(axh))
			delete(axh);
	}

	if (mutator_returnvalue)
	{
		// mutator prevents resetting teams+score
	}
	else
	{
		SetPlayerTeam(this, -1, TEAM_CHANGE_SPECTATOR); // clears scores too in gametypes without teams
		this.frags = FRAGS_SPECTATOR;
	}

	bot_relinkplayerlist();

	if (CS(this).just_joined)
		CS(this).just_joined = false;

	if (recount_ready)
		ReadyCount(); // must be called after SetPlayerTeam() and TRANSMUTE(Observer
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
				case NUM_TEAM_1: defaultmodel = autocvar_sv_defaultplayermodel_red;    defaultskin = autocvar_sv_defaultplayerskin_red; break;
				case NUM_TEAM_2: defaultmodel = autocvar_sv_defaultplayermodel_blue;   defaultskin = autocvar_sv_defaultplayerskin_blue; break;
				case NUM_TEAM_3: defaultmodel = autocvar_sv_defaultplayermodel_yellow; defaultskin = autocvar_sv_defaultplayerskin_yellow; break;
				case NUM_TEAM_4: defaultmodel = autocvar_sv_defaultplayermodel_pink;   defaultskin = autocvar_sv_defaultplayerskin_pink; break;
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
			defaultmodel = argv(floor(n * CS(player).model_randomizer));
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
	}
	else
	{
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

void GiveWarmupResources(entity this)
{
	SetResource(this, RES_SHELLS, warmup_start_ammo_shells);
	SetResource(this, RES_BULLETS, warmup_start_ammo_nails);
	SetResource(this, RES_ROCKETS, warmup_start_ammo_rockets);
	SetResource(this, RES_CELLS, warmup_start_ammo_cells);
	SetResource(this, RES_FUEL, warmup_start_ammo_fuel);
	SetResource(this, RES_HEALTH, warmup_start_health);
	SetResource(this, RES_ARMOR, warmup_start_armorvalue);
	STAT(WEAPONS, this) = WARMUP_START_WEAPONS;
}

void PutPlayerInServer(entity this)
{
	if (MUTATOR_CALLHOOK(ForbidSpawn, this))
		return;

	if (this.vehicle) vehicles_exit(this.vehicle, VHEF_RELEASE);

	PlayerState_attach(this);
	accuracy_resend(this);

	if (teamplay)
	{
		if (this.bot_forced_team)
			SetPlayerTeam(this, this.bot_forced_team, TEAM_CHANGE_MANUAL);
		else if (this.team <= 0)
		{
			if (this.wants_join > 0)
				SetPlayerTeam(this, this.wants_join, TEAM_CHANGE_MANUAL);
			else
				TeamBalance_JoinBestTeam(this);
		}
	}

	entity spot = SelectSpawnPoint(this, false);
	if (!spot)
	{
		Send_Notification(NOTIF_ONE_ONLY, this, MSG_CENTER, CENTER_JOIN_NOSPAWNS);
		return; // spawn failed
	}

	TRANSMUTE(Player, this);

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

	if (warmup_stage)
		GiveWarmupResources(this);
	else
	{
		SetResource(this, RES_SHELLS, start_ammo_shells);
		SetResource(this, RES_BULLETS, start_ammo_nails);
		SetResource(this, RES_ROCKETS, start_ammo_rockets);
		SetResource(this, RES_CELLS, start_ammo_cells);
		SetResource(this, RES_FUEL, start_ammo_fuel);
		SetResource(this, RES_HEALTH, start_health);
		SetResource(this, RES_ARMOR, start_armorvalue);
		STAT(WEAPONS, this) = start_weapons;
		if (MUTATOR_CALLHOOK(ForbidRandomStartWeapons, this) == false)
		{
			GiveRandomWeapons(this, random_start_weapons_count,
				autocvar_g_random_start_weapons, random_start_ammo);
		}
	}
	SetSpectatee_status(this, 0);

	PS(this).dual_weapons = '0 0 0';

	if(STAT(WEAPONS, this) & WEPSET_SUPERWEAPONS)
		StatusEffects_apply(STATUSEFFECT_Superweapon, this, time + autocvar_g_balance_superweapons_time, 0);

	this.items = start_items;

	float shieldtime = time + autocvar_g_spawnshieldtime;

	this.pauserotarmor_finished = time + autocvar_g_balance_pause_armor_rot_spawn;
	this.pauserothealth_finished = time + autocvar_g_balance_pause_health_rot_spawn;
	this.pauserotfuel_finished = time + autocvar_g_balance_pause_fuel_rot_spawn;
	this.pauseregen_finished = time + autocvar_g_balance_pause_health_regen_spawn;
	if (!sv_ready_restart_after_countdown && time < game_starttime)
	{
		float f = game_starttime - time;
		shieldtime += f;
		this.pauserotarmor_finished += f;
		this.pauserothealth_finished += f;
		this.pauseregen_finished += f;
	}

	StatusEffects_apply(STATUSEFFECT_SpawnShield, this, shieldtime, 0);

	this.damageforcescale = autocvar_g_player_damageforcescale;
	this.death_time = 0;
	this.respawn_flags = 0;
	this.respawn_time = 0;
	STAT(RESPAWN_TIME, this) = 0;
	this.scale = ((q3compat && autocvar_sv_q3compat_changehitbox) || !autocvar_sv_mapformat_is_quake3)
	             ? 0.8125 // DP model scaling uses 1/16 accuracy and 13/16 is closest to 56/69
	             : autocvar_sv_player_scale;
	this.fade_time = 0;
	this.pain_finished = 0;
	this.pushltime = 0;
	setthink(this, func_null); // players have no think function
	this.nextthink = 0;
	this.dmg_team = 0;
	PS(this).ballistics_density = autocvar_g_ballistics_density_player;

	this.deadflag = DEAD_NO;

	this.angles = spot.angles;
	this.angles_z = 0; // never spawn tilted even if the spot says to
	if (IS_BOT_CLIENT(this))
	{
		this.v_angle = this.angles;
		bot_aim_reset(this);
	}
	this.fixangle = true; // turn this way immediately
	this.oldvelocity = this.velocity = '0 0 0';
	this.avelocity = '0 0 0';
	this.punchangle = '0 0 0';
	this.punchvector = '0 0 0';

	STAT(AIR_FINISHED, this) = 0;
	this.waterlevel = WATERLEVEL_NONE;
	this.watertype = CONTENT_EMPTY;

	entity spawnevent = new_pure(spawnevent);
	spawnevent.owner = this;
	Net_LinkEntity(spawnevent, false, 0.5, SpawnEvent_Send);

	// Cut off any still running player sounds.
	stopsound(this, CH_PLAYER_SINGLE);

	this.model = "";
	FixPlayermodel(this);
	this.drawonlytoclient = NULL;

	this.viewloc = NULL;

	for(int slot = 0; slot < MAX_AXH; ++slot)
	{
		entity axh = this.(AuxiliaryXhair[slot]);
		this.(AuxiliaryXhair[slot]) = NULL;

		if(axh.owner == this && axh != NULL && !wasfreed(axh))
			delete(axh);
	}

	this.spawnpoint_targ = NULL;

	UNSET_DUCKED(this);
	this.view_ofs = STAT(PL_VIEW_OFS, this);
	setsize(this, STAT(PL_MIN, this), STAT(PL_MAX, this));
	this.spawnorigin = spot.origin;
	setorigin(this, spot.origin + '0 0 1' * (1 - this.mins.z - 24));
	// don't reset back to last position, even if new position is stuck in solid
	this.oldorigin = this.origin;
	if(this.conveyor)
		IL_REMOVE(g_conveyed, this);
	this.conveyor = NULL; // prevent conveyors at the previous location from moving a freshly spawned player
	if(this.swampslug)
		IL_REMOVE(g_swamped, this);
	this.swampslug = NULL;
	this.swamp_interval = 0;
	if(this.ladder_entity)
		IL_REMOVE(g_ladderents, this);
	this.ladder_entity = NULL;
	IL_EACH(g_counters, it.realowner == this,
	{
		delete(it);
	});
	STAT(HUD, this) = HUD_NORMAL;

	this.event_damage = PlayerDamage;
	this.event_heal = PlayerHeal;

	this.draggable = func_null;

	if(!this.bot_attack)
		IL_PUSH(g_bot_targets, this);
	this.bot_attack = true;
	if(!this.monster_attack)
		IL_PUSH(g_monster_targets, this);
	this.monster_attack = true;
	navigation_dynamicgoal_init(this, false);

	PHYS_INPUT_BUTTON_ATCK(this) = PHYS_INPUT_BUTTON_JUMP(this) = PHYS_INPUT_BUTTON_ATCK2(this) = false;

	// player was spectator
	if (CS(this).killcount == FRAGS_SPECTATOR)
	{
		PlayerScore_Clear(this);
		CS(this).killcount = 0;
		CS(this).startplaytime = time;
	}

	for (int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	{
		.entity weaponentity = weaponentities[slot];
		CL_SpawnWeaponentity(this, weaponentity);
	}
	this.alpha = default_player_alpha;
	this.colormod = '1 1 1' * autocvar_g_player_brightness;
	this.exteriorweaponentity.alpha = default_weapon_alpha;

	this.speedrunning = false;

	this.counter_cnt = 0;
	this.fragsfilter_cnt = 0;

	target_voicescript_clear(this);

	// reset fields the weapons may use
	FOREACH(Weapons, true,
	{
		it.wr_resetplayer(it, this);
			// reload all reloadable weapons
		if (it.spawnflags & WEP_FLAG_RELOADABLE)
		{
			for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
			{
				.entity weaponentity = weaponentities[slot];
				this.(weaponentity).weapon_load[it.m_id] = it.reloading_ammo;
			}
		}
	});

	MUTATOR_CALLHOOK(PlayerSpawn, this, spot);
	{
		string s = spot.target;
		if(g_assault || g_race) // TODO: make targeting work in assault & race without this hack
			spot.target = string_null;
		SUB_UseTargets(spot, this, NULL);
		if(g_assault || g_race)
			spot.target = s;
	}

	if (autocvar_spawn_debug)
	{
		sprint(this, strcat("spawnpoint origin:  ", vtos(spot.origin), "\n"));
		delete(spot); // usefull for checking if there are spawnpoints, that let drop through the floor
	}

	for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	{
		.entity weaponentity = weaponentities[slot];
		entity w_ent = this.(weaponentity);
		if(slot == 0 || autocvar_g_weaponswitch_debug == 1)
			w_ent.m_switchweapon = w_getbestweapon(this, weaponentity);
		else
			w_ent.m_switchweapon = WEP_Null;
		w_ent.m_weapon = WEP_Null;
		w_ent.weaponname = "";
		w_ent.m_switchingweapon = WEP_Null;
		w_ent.cnt = -1;
	}

	MUTATOR_CALLHOOK(PlayerWeaponSelect, this);

	if (CS(this).impulse) ImpulseCommands(this);

	W_ResetGunAlign(this, CS_CVAR(this).cvar_cl_gunalign);
	for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	{
		.entity weaponentity = weaponentities[slot];
		W_WeaponFrame(this, weaponentity);
	}

	if (!warmup_stage && !this.alivetime_start)
		this.alivetime_start = max(time, game_starttime);

	antilag_clear(this, CS(this));

	if (warmup_stage)
		ReadyCount();
}

/** Called when a client spawns in the server */
void PutClientInServer(entity this)
{
	if (IS_REAL_CLIENT(this))
	{
		msg_entity = this;
		WriteByte(MSG_ONE, SVC_SETVIEW);
		WriteEntity(MSG_ONE, this);
	}
	if (game_stopped)
		TRANSMUTE(Observer, this);

	bool use_spawnpoint = (!this.enemy); // check this.enemy here since SetSpectatee will clear it
	SetSpectatee(this, NULL);

	// reset player keys
	if(PS(this))
		PS(this).itemkeys = 0;

	MUTATOR_CALLHOOK(PutClientInServer, this);

	if (IS_OBSERVER(this))
		PutObserverInServer(this, false, use_spawnpoint);
	else if (IS_PLAYER(this))
		PutPlayerInServer(this);

	bot_relinkplayerlist();
}

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

	if(autocvar_sv_foginterval && world.fog != "")
		WriteString(channel, world.fog);
	else
		WriteString(channel, "");
	WriteByte(channel, this.count * 255.0); // g_balance_armor_blockpercent
	WriteByte(channel, this.cnt * 255.0); // g_balance_damagepush_speedfactor
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
	if(this.cnt != autocvar_g_balance_damagepush_speedfactor)
	{
		this.cnt = autocvar_g_balance_damagepush_speedfactor;
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
	parm1 = CS(this).parm_idlesince - time;

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
	CS(this).parm_idlesince = parm1;
	if (CS(this).parm_idlesince == -(86400 * 366))
		CS(this).parm_idlesince = time;

	// whatever happens, allow 60 seconds of idling directly after connect for map loading
	CS(this).parm_idlesince = max(CS(this).parm_idlesince, time - autocvar_sv_maxidle + 60);

	MUTATOR_CALLHOOK(DecodeLevelParms);
}

void FixClientCvars(entity e)
{
	// send prediction settings to the client
	if(autocvar_g_antilag == 3) // client side hitscan
		stuffcmd(e, "cl_cmd settemp cl_prydoncursor_notrace 0\n");
	if(autocvar_sv_gentle)
		stuffcmd(e, "cl_cmd settemp cl_gentle 1\n");

	stuffcmd(e, sprintf("\ncl_jumpspeedcap_min \"%s\"\n", autocvar_sv_jumpspeedcap_min));
	stuffcmd(e, sprintf("\ncl_jumpspeedcap_max \"%s\"\n", autocvar_sv_jumpspeedcap_max));

	stuffcmd(e, sprintf("\ncl_shootfromfixedorigin \"%s\"\n", autocvar_g_shootfromfixedorigin));

	MUTATOR_CALLHOOK(FixClientCvars, e);
}

bool findinlist_abbrev(string tofind, string list)
{
	if(list == "" || tofind == "")
		return false; // empty list or search, just return

	// this function allows abbreviated strings!
	FOREACH_WORD(list, it != "" && it == substring(tofind, 0, strlen(it)),
	{
		return true;
	});

	return false;
}

bool PlayerInIPList(entity p, string iplist)
{
	// some safety checks (never allow local?)
	if(p.netaddress == "local" || p.netaddress == "" || !IS_REAL_CLIENT(p))
		return false;

	return findinlist_abbrev(p.netaddress, iplist);
}

bool PlayerInIDList(entity p, string idlist)
{
	// NOTE: we do NOT check crypto_idfp_signed here, an unsigned ID is fine too for this
	if(!p.crypto_idfp)
		return false;

	return findinlist_abbrev(p.crypto_idfp, idlist);
}

bool PlayerInList(entity player, string list)
{
	if (list == "")
		return false;
	return boolean(PlayerInIDList(player, list) || PlayerInIPList(player, list));
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
		                    IS_REAL_CLIENT(this) ? this.netaddress : "bot"));
	}
}
#endif

// NOTE csqc uses the active mutators list sent by this function
// to understand which mutators are enabled
// also note that they aren't all registered mutators, e.g. jetpack, low gravity
void SendWelcomeMessage(entity this, int msg_type)
{
	if (boolean(autocvar_g_campaign))
	{
		WriteByte(msg_type, 1);
		WriteByte(msg_type, Campaign_GetLevelNum());
		return;
	}

	int flags = 0;
	if (CS(this).version_mismatch)
		flags |= 2;
	if (CS(this).version < autocvar_gameversion)
		flags |= 4;
	MapInfo_Get_ByName(mi_shortname, 0, NULL);
	if (MapInfo_Map_author != "")
		flags |= 8;
	WriteByte(msg_type, flags);

	WriteString(msg_type, autocvar_hostname);
	WriteString(msg_type, autocvar_g_xonoticversion);

	WriteString(msg_type, MapInfo_Map_titlestring);
	if (flags & 8)
		WriteString(msg_type, MapInfo_Map_author);
	MapInfo_ClearTemps();

	WriteByte(msg_type, autocvar_g_warmup > 1 ? autocvar_g_warmup : map_minplayers);
	WriteByte(msg_type, GetPlayerLimit());

	MUTATOR_CALLHOOK(BuildMutatorsPrettyString, "");
	string modifications = M_ARGV(0, string);

	if (!g_weaponarena && cvar("g_balance_blaster_weaponstartoverride") == 0)
		modifications = strcat(modifications, ", No start weapons");
	if(cvar("sv_gravity") < stof(cvar_defstring("sv_gravity")))
		modifications = strcat(modifications, ", Low gravity");
	if(g_weapon_stay && !g_cts)
		modifications = strcat(modifications, ", Weapons stay");
	if(autocvar_g_jetpack)
		modifications = strcat(modifications, ", Jetpack");
	modifications = substring(modifications, 2, strlen(modifications) - 2);

	WriteString(msg_type, modifications);

	WriteString(msg_type, g_weaponarena_list);

	if(cache_lastmutatormsg != autocvar_g_mutatormsg)
	{
		strcpy(cache_lastmutatormsg, autocvar_g_mutatormsg);
		strcpy(cache_mutatormsg, cache_lastmutatormsg);
	}

	WriteString(msg_type, cache_mutatormsg);

	WriteString(msg_type, strreplace("\\n", "\n", autocvar_sv_motd));
}

/**
=============
ClientConnect

Called when a client connects to the server
Do not send temp entity headers directly here, they may arrive before CSQC is ready.
=============
*/
void ClientConnect(entity this)
{
	if (Ban_MaybeEnforceBanOnce(this)) return;
	assert(!IS_CLIENT(this), return);
	this.flags |= FL_CLIENT;
	assert(player_count >= 0, player_count = 0);

	TRANSMUTE(Client, this);
	CS(this).version_nagtime = time + 10 + random() * 10;

	Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_JOIN_CONNECT, this.netname);

	bot_clientconnect(this);

	this.team = -1;
	Player_DetermineForcedTeam(this);

	TRANSMUTE(Observer, this);

	PlayerStats_GameReport_AddEvent(sprintf("kills-%d", this.playerid));

	// always track bots, don't ask for cl_allow_uidtracking
	if (IS_BOT_CLIENT(this))
		PlayerStats_GameReport_AddPlayer(this);
	else
		CS(this).allowed_timeouts = autocvar_sv_timeout_number;

	if (autocvar_sv_eventlog)
		GameLogEcho(strcat(":join:", ftos(this.playerid), ":", ftos(etof(this)), ":", ((IS_REAL_CLIENT(this)) ? GameLog_ProcessIP(this.netaddress) : "bot"), ":", playername(this.netname, this.team, false)));

	CS(this).just_joined = true;  // stop spamming the eventlog with additional lines when the client connects
	this.wants_join = 0;

	stuffcmd(this, clientstuff, "\n");
	stuffcmd(this, "cl_particles_reloadeffects\n"); // TODO do we still need this?

	FixClientCvars(this);

	// get version info from player
	stuffcmd(this, "cmd clientversion $gameversion\n");

	// notify about available teams
	if (teamplay)
	{
		entity balance = TeamBalance_CheckAllowedTeams(this);
		int t = TeamBalance_GetAllowedTeams(balance);
		TeamBalance_Destroy(balance);
		stuffcmd(this, sprintf("set _teams_available %d\n", t));
	}
	else
	{
		stuffcmd(this, "set _teams_available 0\n");
	}

	bot_relinkplayerlist();

	CS(this).spectatortime = time;
	CS(this).jointime = time;

	if (IS_REAL_CLIENT(this))
	{
		if (g_weaponarena_weapons == WEPSET(TUBA))
			stuffcmd(this, "cl_cmd settemp chase_active 1\n");
		// quickmenu file must be put in a subfolder with an unique name
		// to reduce chances of overriding custom client quickmenus
		if (waypointeditor_enabled)
			stuffcmd(this, sprintf("cl_cmd settemp _hud_panel_quickmenu_file_from_server %s\n", "wpeditor.txt"));
		else if (autocvar_sv_quickmenu_file != "" && strstrofs(autocvar_sv_quickmenu_file, "/", 0) && fexists(autocvar_sv_quickmenu_file))
			stuffcmd(this, sprintf("cl_cmd settemp _hud_panel_quickmenu_file_from_server %s\n", autocvar_sv_quickmenu_file));
	}

	if (!autocvar_sv_foginterval && world.fog != "")
		stuffcmd(this, strcat("\nfog ", world.fog, "\nr_fog_exp2 0\nr_drawfog 1\n"));

	CSQCMODEL_AUTOINIT(this);

	CS(this).model_randomizer = random();

	if (IS_REAL_CLIENT(this))
		sv_notice_join(this);

	this.move_qcphysics = true;

	// update physics stats (players can spawn before physics runs)
	Physics_UpdateStats(this);

	IL_EACH(g_initforplayer, it.init_for_player,
	{
		it.init_for_player(it, this);
	});

	Handicap_Initialize(this);

	// playban
	if (PlayerInList(this, autocvar_g_playban_list))
		TRANSMUTE(Observer, this);

	if (PlayerInList(this, autocvar_g_chatban_list)) // chatban
		CS(this).muted = true;

	MUTATOR_CALLHOOK(ClientConnect, this);

	if (player_count == 1)
	{
		if (autocvar_sv_autopause && server_is_dedicated)
			setpause(0);
		localcmd("\nsv_hook_firstjoin\n");
	}

	if (get_nextmap() != "")
		Send_NextMap_To_Player(this);

	// cvar hook/callback TODO: recheck this when the cvar is changed
	if (autocvar_sv_vote_master_ids != "" && this.crypto_idfp_signed)
		if (strstrofs(autocvar_sv_vote_master_ids, this.crypto_idfp, 0) >= 0)
			this.vote_master = true;
}

.string shootfromfixedorigin;
.entity chatbubbleentity;
void player_powerups_remove_all(entity this, bool allow_poweroff_sound);

/*
=============
ClientDisconnect

Called when a client disconnects from the server
=============
*/
void ClientDisconnect(entity this)
{
	assert(IS_CLIENT(this), return);

	/* from "ignore" command */
	strfree(this.ignore_list);
	FOREACH_CLIENT(IS_REAL_CLIENT(it) && it.ignore_list,
	{
		if(it.crypto_idfp && it.crypto_idfp != "")
			continue;
		string mylist = ignore_removefromlist(it, this);
		if(it.ignore_list)
			strunzone(it.ignore_list);

		it.ignore_list = strzone(mylist);
	});
	/* from "ignore" command */

	PlayerStats_GameReport_FinalizePlayer(this);
	if (this.vehicle) vehicles_exit(this.vehicle, VHEF_RELEASE);
	if (CS(this).active_minigame) part_minigame(this);
	if (IS_PLAYER(this)) Send_Effect(EFFECT_SPAWN, this.origin, '0 0 0', 1);

	if (autocvar_sv_eventlog)
		GameLogEcho(strcat(":part:", ftos(this.playerid)));

	Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_QUIT_DISCONNECT, this.netname);

	if(IS_SPEC(this))
		SetSpectatee(this, NULL);

	MUTATOR_CALLHOOK(ClientDisconnect, this);

	strfree(CS(this).netname_previous); // needs to be before the CS entity is removed!
	strfree(CS_CVAR(this).weaponorder_byimpulse);
	ClientState_detach(this);

	Portal_ClearAll(this);

	RemoveGrapplingHooks(this);

	strfree(this.shootfromfixedorigin);

	// Here, everything has been done that requires this player to be a client.

	this.flags &= ~FL_CLIENT;

	if (this.chatbubbleentity) delete(this.chatbubbleentity);
	if (this.killindicator) delete(this.killindicator);

	IL_EACH(g_counters, it.realowner == this,
	{
		delete(it);
	});

	WaypointSprite_PlayerGone(this);

	bot_relinkplayerlist();

	strfree(this.clientstatus);
	if (this.personal) delete(this.personal);

	this.playerid = 0;
	if (warmup_stage || game_starttime > time) /* warmup OR countdown */ ReadyCount();
	if (vote_called && IS_REAL_CLIENT(this)) VoteCount(false);

	player_powerups_remove_all(this, IS_PLAYER(this)); // stop powerup sound

	ONREMOVE(this);

	if (player_count == 0)
		localcmd("\nsv_hook_lastleave\n");

	if (!intermission_running)
	if (!TeamBalance_QueuedPlayersTagIn(this))
	if (autocvar_g_balance_teams_remove)
		TeamBalance_RemoveExcessPlayers(NULL);
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

	if ( !IS_DEAD(this.owner) && IS_PLAYER(this.owner) && !MUTATOR_CALLHOOK(ShowChatBubble, this.owner, this) )
	{
		if ( CS(this.owner).active_minigame && PHYS_INPUT_BUTTON_MINIGAME(this.owner) )
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

void calculate_player_respawn_time(entity this)
{
	if(MUTATOR_CALLHOOK(CalculateRespawnTime, this))
		return;

	float gametype_setting_tmp;
	float sdelay_max = GAMETYPE_DEFAULTED_SETTING(respawn_delay_max);
	float sdelay_small = GAMETYPE_DEFAULTED_SETTING(respawn_delay_small);
	float sdelay_large = GAMETYPE_DEFAULTED_SETTING(respawn_delay_large);
	float sdelay_small_count = GAMETYPE_DEFAULTED_SETTING(respawn_delay_small_count);
	float sdelay_large_count = GAMETYPE_DEFAULTED_SETTING(respawn_delay_large_count);
	float waves = GAMETYPE_DEFAULTED_SETTING(respawn_waves);

	float pcount = 1;  // Include myself whether or not team is already set right and I'm a "player".
	if (teamplay)
	{
		FOREACH_CLIENT(IS_PLAYER(it) && it != this,
		{
			if(it.team == this.team)
				++pcount;
		});
		if (sdelay_small_count == 0)
			sdelay_small_count = 1;
		if (sdelay_large_count == 0)
			sdelay_large_count = 1;
	}
	else
	{
		FOREACH_CLIENT(IS_PLAYER(it) && it != this,
		{
			++pcount;
		});
		if (sdelay_small_count == 0)
		{
			if (IS_INDEPENDENT_PLAYER(this))
			{
				// Players play independently. No point in requiring enemies.
				sdelay_small_count = 1;
			}
			else
			{
				// Players play AGAINST each other. Enemies required.
				sdelay_small_count = 2;
			}
		}
		if (sdelay_large_count == 0)
		{
			if (IS_INDEPENDENT_PLAYER(this))
			{
				// Players play independently. No point in requiring enemies.
				sdelay_large_count = 1;
			}
			else
			{
				// Players play AGAINST each other. Enemies required.
				sdelay_large_count = 2;
			}
		}
	}

	float sdelay;

	if (pcount <= sdelay_small_count)
		sdelay = sdelay_small;
	else if (pcount >= sdelay_large_count)
		sdelay = sdelay_large;
	else  // NOTE: this case implies sdelay_large_count > sdelay_small_count.
		sdelay = sdelay_small + (sdelay_large - sdelay_small) * (pcount - sdelay_small_count) / (sdelay_large_count - sdelay_small_count);

	if(waves)
		this.respawn_time = ceil((time + sdelay) / waves) * waves;
	else
		this.respawn_time = time + sdelay;

	if(sdelay < sdelay_max)
		this.respawn_time_max = time + sdelay_max;
	else
		this.respawn_time_max = this.respawn_time;

	if((sdelay + waves >= 5.0) && (this.respawn_time - time > 1.75))
		this.respawn_countdown = 10; // first number to count down from is 10
	else
		this.respawn_countdown = -1; // do not count down

	if(autocvar_g_forced_respawn)
		this.respawn_flags = this.respawn_flags | RESPAWN_FORCE;
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
	bool damagedbycontents_prev = this.damagedbycontents;
	if(this.alpha >= 0)
	{
		if(autocvar_g_respawn_ghosts)
		{
			this.solid = SOLID_NOT;
			this.takedamage = DAMAGE_NO;
			this.damagedbycontents = false;
			set_movetype(this, MOVETYPE_FLY);
			this.velocity = '0 0 1' * autocvar_g_respawn_ghosts_speed;
			this.avelocity = randomvec() * autocvar_g_respawn_ghosts_speed * 3 - randomvec() * autocvar_g_respawn_ghosts_speed * 3;
			this.effects |= CSQCMODEL_EF_RESPAWNGHOST;
			this.alpha = min(this.alpha, autocvar_g_respawn_ghosts_alpha);
			Send_Effect(EFFECT_RESPAWN_GHOST, this.origin, '0 0 0', 1);
			if(autocvar_g_respawn_ghosts_time > 0)
				SUB_SetFade(this, time + autocvar_g_respawn_ghosts_time, autocvar_g_respawn_ghosts_fadetime);
		}
		else
			SUB_SetFade (this, time, 1); // fade out the corpse immediately
	}

	CopyBody(this, 1);
	this.damagedbycontents = damagedbycontents_prev;

	this.effects |= EF_NODRAW; // prevent another CopyBody
	PutClientInServer(this);
}

void play_countdown(entity this, float finished, Sound samp)
{
	TC(Sound, samp);
	float time_left = finished - time;
	if(IS_REAL_CLIENT(this) && time_left < 6 && floor(time_left - frametime) != floor(time_left))
		sound(this, CH_INFO, samp, VOL_BASE, ATTEN_NORM);
}

// it removes special powerups not handled by StatusEffects
void player_powerups_remove_all(entity this, bool allow_poweroff_sound)
{
	if (this.items & (IT_SUPERWEAPON | IT_UNLIMITED_AMMO | IT_UNLIMITED_SUPERWEAPONS))
	{
		// don't play the poweroff sound when the game restarts or the player disconnects
		if (allow_poweroff_sound && time > game_starttime + 1 && IS_CLIENT(this)
		&& !(start_items & (IT_UNLIMITED_AMMO | IT_UNLIMITED_SUPERWEAPONS)))
			sound(this, CH_INFO, SND_POWEROFF, VOL_BASE, ATTEN_NORM);

		if (this.items & (IT_UNLIMITED_AMMO | IT_UNLIMITED_SUPERWEAPONS))
			stopsound(this, CH_TRIGGER_SINGLE); // get rid of the pickup sound

		this.items -= (this.items & (IT_SUPERWEAPON | IT_UNLIMITED_AMMO | IT_UNLIMITED_SUPERWEAPONS));
	}
}

void player_powerups(entity this)
{
	if((this.items & IT_USING_JETPACK) && !IS_DEAD(this) && !game_stopped)
		this.modelflags |= MF_ROCKET;
	else
		this.modelflags &= ~MF_ROCKET;

	this.effects &= ~EF_NODEPTHTEST;

	if (IS_DEAD(this))
		player_powerups_remove_all(this, true);

	if((this.alpha < 0 || IS_DEAD(this)) && !this.vehicle) // don't apply the flags if the player is gibbed
		return;

	// add a way to see what the items were BEFORE all of these checks for the mutator hook
	int items_prev = this.items;

	if (!MUTATOR_IS_ENABLED(mutator_instagib))
	{
		// NOTE: superweapons are a special case and as such are handled here instead of the status effects system
		if (this.items & IT_SUPERWEAPON)
		{
			if (!(STAT(WEAPONS, this) & WEPSET_SUPERWEAPONS))
			{
				StatusEffects_remove(STATUSEFFECT_Superweapon, this, STATUSEFFECT_REMOVE_NORMAL);
				this.items &= ~IT_SUPERWEAPON;
				//Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_SUPERWEAPON_LOST, this.netname);
				Send_Notification(NOTIF_ONE, this, MSG_CENTER, CENTER_SUPERWEAPON_LOST);
			}
			else if (this.items & IT_UNLIMITED_SUPERWEAPONS)
			{
				// don't let them run out
			}
			else
			{
				play_countdown(this, StatusEffects_gettime(STATUSEFFECT_Superweapon, this), SND_POWEROFF);
				if (time >= StatusEffects_gettime(STATUSEFFECT_Superweapon, this))
				{
					this.items &= ~IT_SUPERWEAPON;
					STAT(WEAPONS, this) &= ~WEPSET_SUPERWEAPONS;
					//Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_SUPERWEAPON_BROKEN, this.netname);
					Send_Notification(NOTIF_ONE, this, MSG_CENTER, CENTER_SUPERWEAPON_BROKEN);
				}
			}
		}
		else if(STAT(WEAPONS, this) & WEPSET_SUPERWEAPONS)
		{
			if (time < StatusEffects_gettime(STATUSEFFECT_Superweapon, this) || (this.items & IT_UNLIMITED_SUPERWEAPONS))
			{
				this.items |= IT_SUPERWEAPON;
				if(!(this.items & IT_UNLIMITED_SUPERWEAPONS))
				{
					if(!g_cts)
						Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_SUPERWEAPON_PICKUP, this.netname);
					Send_Notification(NOTIF_ONE, this, MSG_CENTER, CENTER_SUPERWEAPON_PICKUP);
				}
			}
			else
			{
				if(StatusEffects_active(STATUSEFFECT_Superweapon, this))
					StatusEffects_remove(STATUSEFFECT_Superweapon, this, STATUSEFFECT_REMOVE_TIMEOUT);
				STAT(WEAPONS, this) &= ~WEPSET_SUPERWEAPONS;
			}
		}
		else if(StatusEffects_active(STATUSEFFECT_Superweapon, this)) // cheaper to check than to update each frame!
		{
			StatusEffects_remove(STATUSEFFECT_Superweapon, this, STATUSEFFECT_REMOVE_CLEAR);
		}
	}

	if(autocvar_g_nodepthtestplayers)
		this.effects |= EF_NODEPTHTEST;

	if(autocvar_g_fullbrightplayers)
		this.effects |= EF_FULLBRIGHT;

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

void RotRegen(entity this, Resource res, float limit_mod,
              float regenstable, float regenfactor, float regenlinear, float regenframetime,
              float rotstable, float rotfactor, float rotlinear, float rotframetime)
{
	float old = GetResource(this, res);
	float current = old;
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

	float limit = GetResourceLimit(this, res) * limit_mod;
	if(current > limit)
		current = limit;

	if (current != old)
		SetResource(this, res, current);
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

	float rotstable, regenstable, rotframetime, regenframetime;

	if(!mutator_returnvalue)
	{
		regenstable = autocvar_g_balance_armor_regenstable;
		rotstable = autocvar_g_balance_armor_rotstable;
		regenframetime = (time > this.pauseregen_finished) ? (regen_mod * frametime) : 0;
		rotframetime = (time > this.pauserotarmor_finished) ? (rot_mod * frametime) : 0;
		RotRegen(this, RES_ARMOR, limit_mod,
		         regenstable, autocvar_g_balance_armor_regen, autocvar_g_balance_armor_regenlinear, regenframetime,
		         rotstable, autocvar_g_balance_armor_rot, autocvar_g_balance_armor_rotlinear, rotframetime);

		// NOTE: max_mod is only applied to health
		regenstable = regen_health_stable * max_mod;
		rotstable = regen_health_rotstable * max_mod;
		regenframetime = (time > this.pauseregen_finished) ? (regen_mod * frametime) : 0;
		rotframetime = (time > this.pauserothealth_finished) ? (rot_mod * frametime) : 0;
		RotRegen(this, RES_HEALTH, limit_mod,
		         regenstable, regen_health, regen_health_linear, regenframetime,
		         rotstable, regen_health_rot, regen_health_rotlinear, rotframetime);
	}

	// if player rotted to death...  die!
	// check this outside above checks, as player may still be able to rot to death
	if(GetResource(this, RES_HEALTH) < 1)
	{
		if(this.vehicle)
			vehicles_exit(this.vehicle, VHEF_RELEASE);
		if(this.event_damage)
			this.event_damage(this, this, this, 1, DEATH_ROT.m_id, DMG_NOWEP, this.origin, '0 0 0');
	}

	if (!(this.items & IT_UNLIMITED_AMMO))
	{
		regenstable = autocvar_g_balance_fuel_regenstable;
		rotstable = autocvar_g_balance_fuel_rotstable;
		regenframetime = ((time > this.pauseregen_finished) && (this.items & ITEM_FuelRegen.m_itemid)) ? frametime : 0;
		rotframetime = (time > this.pauserotfuel_finished) ? frametime : 0;
		RotRegen(this, RES_FUEL, 1,
		         regenstable, autocvar_g_balance_fuel_regen, autocvar_g_balance_fuel_regenlinear, regenframetime,
		         rotstable, autocvar_g_balance_fuel_rot, autocvar_g_balance_fuel_rotlinear, rotframetime);
	}
}

bool zoomstate_set;
void SetZoomState(entity this, float newzoom)
{
	if(newzoom != CS(this).zoomstate)
	{
		CS(this).zoomstate = newzoom;
		ClientData_Touch(this);
	}
	zoomstate_set = true;
}

void GetPressedKeys(entity this)
{
	MUTATOR_CALLHOOK(GetPressedKeys, this);
	if (game_stopped)
	{
		CS(this).pressedkeys = 0;
		STAT(PRESSED_KEYS, this) = 0;
		return;
	}

	// NOTE: GetPressedKeys and PM_dodging_GetPressedKeys use similar code
	int keys = STAT(PRESSED_KEYS, this);
	keys = BITSET(keys, KEY_FORWARD,   CS(this).movement.x > 0);
	keys = BITSET(keys, KEY_BACKWARD,  CS(this).movement.x < 0);
	keys = BITSET(keys, KEY_RIGHT,     CS(this).movement.y > 0);
	keys = BITSET(keys, KEY_LEFT,      CS(this).movement.y < 0);

	keys = BITSET(keys, KEY_JUMP,      PHYS_INPUT_BUTTON_JUMP(this));
	keys = BITSET(keys, KEY_CROUCH,    IS_DUCKED(this)); // workaround: player can't un-crouch until their path is clear, so we keep the button held here
	keys = BITSET(keys, KEY_ATCK,      PHYS_INPUT_BUTTON_ATCK(this));
	keys = BITSET(keys, KEY_ATCK2,     PHYS_INPUT_BUTTON_ATCK2(this));
	CS(this).pressedkeys = keys; // store for other users

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
	SetResourceExplicit(this, RES_ARMOR, GetResource(spectatee, RES_ARMOR));
	SetResourceExplicit(this, RES_CELLS, GetResource(spectatee, RES_CELLS));
	SetResourceExplicit(this, RES_SHELLS, GetResource(spectatee, RES_SHELLS));
	SetResourceExplicit(this, RES_BULLETS, GetResource(spectatee, RES_BULLETS));
	SetResourceExplicit(this, RES_ROCKETS, GetResource(spectatee, RES_ROCKETS));
	SetResourceExplicit(this, RES_FUEL, GetResource(spectatee, RES_FUEL));
	this.effects = spectatee.effects & EFMASK_CHEAP; // eat performance
	SetResourceExplicit(this, RES_HEALTH, GetResource(spectatee, RES_HEALTH));
	CS(this).impulse = 0;
	this.disableclientprediction = 1; // no need to run prediction on a spectator
	this.items = spectatee.items;
	STAT(LAST_PICKUP, this) = STAT(LAST_PICKUP, spectatee);
	STAT(HIT_TIME, this) = STAT(HIT_TIME, spectatee);
	STAT(AIR_FINISHED, this) = STAT(AIR_FINISHED, spectatee);
	STAT(PRESSED_KEYS, this) = STAT(PRESSED_KEYS, spectatee);
	STAT(WEAPONS, this) = STAT(WEAPONS, spectatee);
	this.punchangle = spectatee.punchangle;
	this.view_ofs = spectatee.view_ofs;
	this.velocity = spectatee.velocity;
	this.dmg_take = spectatee.dmg_take;
	this.dmg_save = spectatee.dmg_save;
	this.dmg_inflictor = spectatee.dmg_inflictor;
	this.v_angle = spectatee.v_angle;
	this.angles = spectatee.v_angle;
	this.viewloc = spectatee.viewloc;
	if(!PHYS_INPUT_BUTTON_USE(this) && STAT(CAMERA_SPECTATOR, this) != 2)
		this.fixangle = true;
	setorigin(this, spectatee.origin);
	setsize(this, spectatee.mins, spectatee.maxs);
	SetZoomState(this, CS(spectatee).zoomstate);

	anticheat_spectatecopy(this, spectatee);
	STAT(HUD, this) = STAT(HUD, spectatee);
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
	if (IS_OBSERVER(this))
		TRANSMUTE(Spectator, this);

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
		PutObserverInServer(this, false, true);

	return true;
}

void SetSpectatee_status(entity this, int spectatee_num)
{
	int oldspectatee_status = CS(this).spectatee_status;
	CS(this).spectatee_status = spectatee_num;

	if (CS(this).spectatee_status != oldspectatee_status)
	{
		if (STAT(PRESSED_KEYS, this))
		{
			CS(this).pressedkeys = 0;
			STAT(PRESSED_KEYS, this) = 0;
		}

		ClientData_Touch(this);

		// init or clear race data
		if ((g_race || g_cts) && g_race_qualifying && IS_REAL_CLIENT(this))
		{
			msg_entity = this;

			if (this.enemy && this.enemy.race_laptime)
			{
				// init
				race_SendNextCheckpoint(this.enemy, 1);
			}
			else
			{
				// send reset to this spectator
				WriteHeader(MSG_ONE, TE_CSQC_RACE);
				WriteByte(MSG_ONE, RACE_NET_CHECKPOINT_CLEAR);
			}
		}
	}
}

void SetSpectatee(entity this, entity spectatee)
{
	if(IS_BOT_CLIENT(this))
		return; // bots abuse .enemy, this code is useless to them

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
				old_spectatee.(weaponentity).arc_beam.SendFlags |= ARC_SF_UPDATE;
		}
	}
	if(spectatee)
	{
		for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
		{
			.entity weaponentity = weaponentities[slot];
			if(spectatee.(weaponentity).arc_beam)
				spectatee.(weaponentity).arc_beam.SendFlags |= ARC_SF_UPDATE;
		}
	}

	if (spectatee)
		SetSpectatee_status(this, etof(spectatee));

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

	if(ent) SetSpectatee(this, ent);

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
				Send_Notification(NOTIF_ONE, this, MSG_ANNCE, Announcer_PickNumber(CNT_RESPAWN, number));
		}
	}
}

bool ShowTeamSelection(entity this)
{
	if (!teamplay || autocvar_g_campaign || autocvar_g_balance_teams || this.team_selected || Player_HasRealForcedTeam(this))
		return false;
	if (QueuedPlayersReady(this, true))
		return false;
	if (frametime) // once per frame is more than enough
		stuffcmd(this, "_scoreboard_team_selection 1\n");
	return true;
}

/// it's assumed this isn't called for bots (campaign_bots_may_start, centreprints)
void Join(entity this, bool queued_join)
{
	entity player_with_dibs = NULL;

	if (autocvar_g_campaign)
	{
		if (!campaign_bots_may_start && !game_stopped && time >= game_starttime)
			ReadyRestart(true);
		campaign_bots_may_start = true;
	}

	if(queued_join
	&& TeamBalance_AreEqual(this, true)) // if a player couldn't tag in for balance, don't join them here as it would cause a stack
	{
		// First we must join player(s) queued for specific team(s) (they chose first)
		// so TeamBalance_JoinBestTeam() (if necessary) won't select the same team(s).
		// Relies on `this` skipping the queue (this.team already set, this.wants_join not set) or using autoselect.
		FOREACH_CLIENT(it != this && it.wants_join > 0,
		{
			// detect any conflict between `this` and a queued player (queuePlayer() handles other conflicts)
			if (this.team < 0 && this.team_selected > 0 // `this` can't have their preference
			&& it.wants_join == this.team_selected) // `it` is the player who already chose the team `this` wanted
				player_with_dibs = it;

			Join(it, false);
		});

		// Second pass: queued players whose team will be autoselected
		FOREACH_CLIENT(it != this && it.wants_join < 0,
		{
			Join(it, false);
		});
	}

	Kill_Notification(NOTIF_ONE_ONLY, this, MSG_CENTER, CPID_PREVENT_JOIN);

	TRANSMUTE(Player, this);
	PutClientInServer(this);

	if(IS_PLAYER(this)) // could be false due to PutClientInServer() mutator hook
	{
		if (!teamplay)
			Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_JOIN_PLAY, this.netname);
		else if (player_with_dibs)
			// limitation: notifications support only 1 translated team name
			// so the team `this` preferred can't be mentioned, only the team they got assigned to.
			Send_Notification(NOTIF_ONE_ONLY, this, MSG_CENTER, APP_TEAM_NUM(this.team, CENTER_JOIN_PLAY_TEAM_QUEUECONFLICT), player_with_dibs.netname);
		else
		{
			if (this.wants_join && game_starttime < time && !warmup_stage) // No countdown running && not returning to warmup via ReadyRestart_force
				Send_Notification(NOTIF_ONE_ONLY, this, MSG_ANNCE, ANNCE_BEGIN); // Get queued player's attention
			Send_Notification(NOTIF_ONE_ONLY, this, MSG_CENTER, APP_TEAM_NUM(this.team, CENTER_JOIN_PLAY_TEAM));
		}
	}

	this.team_selected = 0;
	this.wants_join = 0;
}

int GetPlayerLimit()
{
	if(g_duel)
		return 2; // TODO: this workaround is needed since the mutator hook from duel can't be activated before the gametype is loaded (e.g. switching modes via gametype vote screen)
	// don't return map_maxplayers during intermission as it would interfere with MapHasRightSize()
	int player_limit = (autocvar_g_maxplayers >= 0 || intermission_running) ? autocvar_g_maxplayers : map_maxplayers;
	MUTATOR_CALLHOOK(GetPlayerLimit, player_limit);
	player_limit = M_ARGV(0, int);
	return player_limit < maxclients && player_limit > 0 ? player_limit : 0;
}

/**
 * Determines how many player slots are free. This depends on cvar g_maxplayers
 * and other limits that apply to all clients which aren't specifically excepted.
 * @return int number of free slots for players, 0 if none
 */
int nJoinAllowed(entity this)
{
	if(!this)
	// this is called that way when checking if anyone may be able to join (to build qcstatus)
	// so report 0 free slots if restricted
	{
		if(autocvar_g_forced_team_otherwise == "spectate"
		|| autocvar_g_forced_team_otherwise == "spectator"
		|| (teamplay && lockteams))
			return 0;
	}

	int totalClients = 0;
	int currentlyPlaying = 0;
	FOREACH_CLIENT(it != this,
	{
		++totalClients;
		if(IS_PLAYER(it) || INGAME(it))
			++currentlyPlaying;
	});

	int player_limit = GetPlayerLimit();

	int free_slots = max(0, (player_limit ? player_limit : maxclients) - currentlyPlaying);
	if (this || maxclients - totalClients) // don't add bot slots in the getstatus case if nobody can connect
		free_slots += bots_would_leave;
	if (!this) // getstatus case
		free_slots = min(free_slots, maxclients - totalClients);

	if(this && !free_slots)
		Send_Notification(NOTIF_ONE_ONLY, this, MSG_CENTER, CENTER_JOIN_PREVENT, player_limit);

	return free_slots;
}

// Callsites other than ClientCommand_selectteam() should pass this.wants_join as team_index
// so the player won't accidentally reset a specific preference by pressing +jump
// and will see the centreprint with their current preference each time they press +jump.
bool queuePlayer(entity this, int team_index)
{
	// check if a queued player already chose the selected team
	if (team_index > 0)
	{
		FOREACH_CLIENT(it != this && it.wants_join == team_index,
		{
			if (QueuedPlayersReady(this, false))
			{
				// Join() will handle the notification so it can mention the team `player` will actually get
				this.team = -1; // force autoselect in Join() (last player skips queue)
				this.team_selected = team_index; // tell it which team to check for to find the conflict
			}
			else // > 2 teams
			{
				Send_Notification(NOTIF_ONE_ONLY, this, MSG_CENTER, APP_TEAM_NUM(Team_IndexToTeam(team_index), CENTER_JOIN_PREVENT_QUEUE_TEAM_CONFLICT), it.netname);
				this.wants_join = -1; // force autoselect in Join()
				this.team_selected = -1; // prevents clobbering by CENTER_JOIN_PREVENT_QUEUE
			}
			return true;
		});
	}

	if (QueuedPlayersReady(this, false))
		return false;

	if (team_index <= 0) // team auto select deferred until Join()
	{
		if (team_index != this.wants_join || !this.wants_join) // prevents chatcon spam
			Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_JOIN_WANTS, this.netname);
		if (this.team_selected >= 0) // prevents CENTER_JOIN_PREVENT_QUEUE_TEAM_CONFLICT getting clobbered
			Send_Notification(NOTIF_ONE_ONLY, this, MSG_CENTER, CENTER_JOIN_PREVENT_QUEUE);
		this.wants_join = -1;
		this.team_selected = 0;
	}
	else
	{
		int team_num = Team_IndexToTeam(team_index);
		if (team_index != this.wants_join) // prevents chatcon spam
			Send_Notification(NOTIF_ALL, NULL, MSG_INFO, APP_TEAM_NUM(team_num, INFO_JOIN_WANTS_TEAM), this.netname);
		Send_Notification(NOTIF_ONE_ONLY, this, MSG_CENTER, APP_TEAM_NUM(team_num, CENTER_JOIN_PREVENT_QUEUE_TEAM));
		this.wants_join = team_index; // Player queued to join
		this.team_selected = team_index;
	}

	return true;
}

float autocvar_g_maxping;
bool joinAllowed(entity this, int team_index)
{
	if (CS(this).version_mismatch)
	{
		Send_Notification(NOTIF_ONE_ONLY, this, MSG_CENTER, CENTER_JOIN_PREVENT_VERSIONMISMATCH);
		return false;
	}
	if (time < CS(this).jointime + MIN_SPEC_TIME) return false;
	if (teamplay && lockteams)
	{
		Send_Notification(NOTIF_ONE_ONLY, this, MSG_CENTER, CENTER_TEAMCHANGE_LOCKED);
		return false;
	}

	if (Player_GetForcedTeamIndex(this) == TEAM_FORCE_SPECTATOR) return false;

	if (!INGAME(this) && PlayerInList(this, autocvar_g_playban_list))
	{
		Send_Notification(NOTIF_ONE_ONLY, this, MSG_CENTER, CENTER_JOIN_PLAYBAN);
		return false;
	}

	// IS_PLAYER for most gametypes, INGAME for ca, lms, surv
	if (autocvar_g_maxping && !(IS_PLAYER(this) || INGAME(this)) && !this.wants_join)
	{
		if (this.ping <= 0) return false; // too soon
		if (this.ping > autocvar_g_maxping)
		{
			Send_Notification(NOTIF_ONE_ONLY, this, MSG_CENTER, CENTER_JOIN_PREVENT_PING);
			return false;
		}
	}

	if (QueueNeeded(this))
	{
		if (team_index == 0) // so ClientCommand_selectteam() can check joinAllowed() before calling SetPlayerTeam() without chicken/egg problem
			if (ShowTeamSelection(this)) return false; // only needed by callsites other than selectteam
		// queuePlayer called here so that only conditions above block queuing (g_maxplayers shouldn't)
		if (queuePlayer(this, team_index)) return false;
		if (!nJoinAllowed(this)) return false;
	}
	else
	{
		if (!nJoinAllowed(this)) return false;
		if (team_index == 0) // so ClientCommand_selectteam() can check joinAllowed() before calling SetPlayerTeam() without chicken/egg problem
			if (ShowTeamSelection(this)) return false; // only needed by callsites other than selectteam
	}

	return true;
}

void show_entnum(entity this)
{
	// waypoint editor implements a similar feature for waypoints
	if (waypointeditor_enabled)
		return;

	if (wasfreed(this.wp_aimed))
		this.wp_aimed = NULL;

	WarpZone_crosshair_trace_plusvisibletriggers(this);
	entity ent = NULL;
	if (trace_ent)
	{
		ent = trace_ent;
		if (ent != this.wp_aimed)
		{
			string str = sprintf(
				"^7ent #%d\n^8 netname: ^3%s\n^8 classname: ^5%s\n^8 origin: ^2'%s'",
				etof(ent), ent.netname, ent.classname, vtos(ent.origin));
			debug_text_3d((ent.absmin + ent.absmax) * 0.5, str, 0, 7, '0 0 0');
		}
	}
	if (this.wp_aimed != ent)
		this.wp_aimed = ent;
}

.bool dualwielding_prev;
bool PlayerThink(entity this)
{
	if (game_stopped || intermission_running)
	{
		this.modelflags &= ~MF_ROCKET;
		if(intermission_running)
			IntermissionThink(this);
		return false;
	}

	if (timeout_status == TIMEOUT_ACTIVE)
	{
		// don't allow the player to turn around while game is paused
		// FIXME turn this into CSQC stuff
		this.v_angle = this.lastV_angle;
		this.angles = this.lastV_angle;
		this.fixangle = true;
	}

	if (frametime) player_powerups(this);

	if (frametime && autocvar_sv_show_entnum) show_entnum(this);

	if (IS_DEAD(this))
	{
		if (this.personal && g_race_qualifying
		&& (autocvar_g_allow_checkpoints || CheatsAllowed(this, CHIMPULSE_SPEEDRUN.impulse, 0, 0, false, true)))
		{
			if (time > this.respawn_time)
			{
				STAT(RESPAWN_TIME, this) = this.respawn_time = time + 1; // only retry once a second
				respawn(this);
				CS(this).impulse = CHIMPULSE_SPEEDRUN.impulse;
			}
		}
		else
		{
			if (frametime) player_anim(this);

			if (this.respawn_flags & RESPAWN_DENY)
			{
				STAT(RESPAWN_TIME, this) = 0;
				return false;
			}

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

		return false;
	}

	FixPlayermodel(this);

	if (this.shootfromfixedorigin != autocvar_g_shootfromfixedorigin)
	{
		strcpy(this.shootfromfixedorigin, autocvar_g_shootfromfixedorigin);
		stuffcmd(this, sprintf("\ncl_shootfromfixedorigin \"%s\"\n", autocvar_g_shootfromfixedorigin));
	}

	// reset gun alignment when dual wielding status changes
	// to ensure guns are always aligned right and left
	bool dualwielding = W_DualWielding(this);
	if(this.dualwielding_prev != dualwielding)
	{
		W_ResetGunAlign(this, CS_CVAR(this).cvar_cl_gunalign);
		this.dualwielding_prev = dualwielding;
	}

	// LordHavoc: allow firing on move frames (sub-ticrate), this gives better timing on slow servers
	//if(frametime)
	{
		for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
		{
			.entity weaponentity = weaponentities[slot];
			if(WEP_CVAR(WEP_VORTEX, charge_always))
				W_Vortex_Charge(this, weaponentity, frametime);
			W_WeaponFrame(this, weaponentity);
		}
	}

	if (frametime)
	{
		// WEAPONTODO: Add a weapon request for this
		// rot vortex charge to the charge limit
		for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
		{
			.entity weaponentity = weaponentities[slot];
			if (WEP_CVAR(WEP_VORTEX, charge_rot_rate) && this.(weaponentity).vortex_charge > WEP_CVAR(WEP_VORTEX, charge_limit) && this.(weaponentity).vortex_charge_rottime < time)
				this.(weaponentity).vortex_charge = bound(WEP_CVAR(WEP_VORTEX, charge_limit), this.(weaponentity).vortex_charge - WEP_CVAR(WEP_VORTEX, charge_rot_rate) * frametime / W_TICSPERFRAME, 1);
		}

		player_regen(this);
		player_anim(this);
		this.dmg_team = max(0, this.dmg_team - autocvar_g_teamdamage_resetspeed * frametime);
	}

	monsters_setstatus(this);

	return true;
}

.bool would_spectate;
// merged SpectatorThink and ObserverThink (old names are here so you can grep for them)
void ObserverOrSpectatorThink(entity this)
{
	bool is_spec = IS_SPEC(this);
	if ( CS(this).impulse )
	{
		int r = MinigameImpulse(this, CS(this).impulse);
		if (!is_spec || r)
			CS(this).impulse = 0;

		if (is_spec && CS(this).impulse == IMP_weapon_drop.impulse)
		{
			STAT(CAMERA_SPECTATOR, this) = (STAT(CAMERA_SPECTATOR, this) + 1) % 3;
			CS(this).impulse = 0;
			return;
		}
	}

	if (frametime && autocvar_sv_show_entnum) show_entnum(this);

	if (IS_BOT_CLIENT(this) && !CS(this).autojoin_checked)
	{
		CS(this).autojoin_checked = 1;
		TRANSMUTE(Player, this);
		PutClientInServer(this);

		.entity weaponentity = weaponentities[0];
		if(this.(weaponentity).m_weapon == WEP_Null)
			W_NextWeapon(this, 0, weaponentity);

		return;
	}

	if (this.flags & FL_JUMPRELEASED)
	{
		if (PHYS_INPUT_BUTTON_JUMP(this) && (joinAllowed(this, this.wants_join) || time < CS(this).jointime + MIN_SPEC_TIME))
		{
			this.flags &= ~FL_JUMPRELEASED;
			this.flags |= FL_SPAWNING;
		}
		else if((is_spec && (PHYS_INPUT_BUTTON_ATCK(this) || CS(this).impulse == 10 || CS(this).impulse == 15 || CS(this).impulse == 18 || (CS(this).impulse >= 200 && CS(this).impulse <= 209)))
		|| (!is_spec && ((PHYS_INPUT_BUTTON_ATCK(this) && !CS(this).version_mismatch) || this.would_spectate)))
		{
			this.flags &= ~FL_JUMPRELEASED;
			if (autocvar_sv_spectate == 2 && !warmup_stage && !this.vote_master)
				Send_Notification(NOTIF_ONE_ONLY, this, MSG_CENTER, CENTER_SPECTATE_SPEC_NOTALLOWED);
			else if(SpectateNext(this))
				{ }
			else if (is_spec)
			{
				TRANSMUTE(Observer, this);
				PutClientInServer(this);
			}
			else
				this.would_spectate = false; // unable to spectate anyone

			if (is_spec)
				CS(this).impulse = 0;
		}
		else if (is_spec)
		{
			if(CS(this).impulse == 12 || CS(this).impulse == 16  || CS(this).impulse == 19 || (CS(this).impulse >= 220 && CS(this).impulse <= 229))
			{
				this.flags &= ~FL_JUMPRELEASED;
				if (!SpectatePrev(this))
				{
					TRANSMUTE(Observer, this);
					PutClientInServer(this);
				}
				CS(this).impulse = 0;
			}
			else if(PHYS_INPUT_BUTTON_ATCK2(this))
			{
				if(!observe_blocked_if_eliminated || !INGAME(this))
				{
					this.would_spectate = false;
					this.flags &= ~FL_JUMPRELEASED;
					TRANSMUTE(Observer, this);
					PutClientInServer(this);
				}
			}
			else if(!SpectateUpdate(this) && !SpectateNext(this))
			{
				PutObserverInServer(this, false, true);
				this.would_spectate = true;
			}
		}
		else
		{
			bool wouldclip = CS_CVAR(this).cvar_cl_clippedspectating;
			if (PHYS_INPUT_BUTTON_USE(this))
				wouldclip = !wouldclip;
			int preferred_movetype = (wouldclip ? MOVETYPE_FLY_WORLDONLY : MOVETYPE_NOCLIP);
			set_movetype(this, preferred_movetype);
		}
	}
	else
	{ // jump pressed
		if ((is_spec && !(PHYS_INPUT_BUTTON_ATCK(this) || PHYS_INPUT_BUTTON_ATCK2(this)))
		|| (!is_spec && !(PHYS_INPUT_BUTTON_ATCK(this) || PHYS_INPUT_BUTTON_JUMP(this))))
		{
			this.flags |= FL_JUMPRELEASED;
			// primary attack pressed
			if(this.flags & FL_SPAWNING)
			{
				this.flags &= ~FL_SPAWNING;
				if(joinAllowed(this, this.wants_join))
					Join(this, teamplay);
				else if(time < CS(this).jointime + MIN_SPEC_TIME)
					CS(this).autojoin_checked = -1;
				return;
			}
		}
		if(is_spec && !SpectateUpdate(this))
			PutObserverInServer(this, false, true);
	}
	if (is_spec)
		this.flags |= FL_CLIENT | FL_NOTARGET;
}

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
		if(!game_stopped && !STAT(FROZEN, this) && !StatusEffects_active(STATUSEFFECT_Frozen, this) && !IS_DEAD(this) && !IS_INDEPENDENT_PLAYER(this))
		{
			entity head, closest_target = NULL;
			head = WarpZone_FindRadius(this.origin, autocvar_g_vehicles_enter_radius, true);

			while(head) // find the closest acceptable target to enter
			{
				if(IS_VEHICLE(head) && !IS_DEAD(head) && head.takedamage != DAMAGE_NO)
				if(!head.owner || ((head.vehicle_flags & VHF_MULTISLOT) && SAME_TEAM(head.owner, this)))
				{
					if(closest_target)
					{
						if(vlen2(this.origin - head.origin) < vlen2(this.origin - closest_target.origin))
							closest_target = head;
					}
					else
						closest_target = head;
				}

				head = head.chain;
			}

			if(closest_target)
			{
				vehicles_enter(this, closest_target);
				return;
			}
		}
	}

	// a use key was pressed; call handlers
	MUTATOR_CALLHOOK(PlayerUseKey, this);
}


/*
=============
PlayerPreThink

Called every frame for each real client by DP (and for each bot by StartFrame()),
and when executing every asynchronous move, so only include things that MUST be done then.
Use PlayerFrame() instead for code that only needs to run once per server frame.
frametime == 0 in the asynchronous code path.

TODO: move more stuff from here and PlayerThink() and ObserverOrSpectatorThink() to PlayerFrame() (frametime is always set there)
=============
*/
.float last_vehiclecheck;
void PlayerPreThink (entity this)
{
	WarpZone_PlayerPhysics_FixVAngle(this);

	zoomstate_set = false;

	MUTATOR_CALLHOOK(PlayerPreThink, this);

	if(PHYS_INPUT_BUTTON_USE(this) && !CS(this).usekeypressed)
		PlayerUseKey(this);
	CS(this).usekeypressed = PHYS_INPUT_BUTTON_USE(this);

	if (IS_PLAYER(this))
	{
		if (IS_REAL_CLIENT(this) && time < CS(this).jointime + MIN_SPEC_TIME)
			error("Client can't be spawned as player on connection!");
		if(!PlayerThink(this))
			return;
	}
	else if (game_stopped || intermission_running)
	{
		if(intermission_running)
			IntermissionThink(this);
		return;
	}
	else if (IS_REAL_CLIENT(this) && CS(this).autojoin_checked <= 0 && time >= CS(this).jointime + MIN_SPEC_TIME
	&& this.ping > 0) // delay until centreprints could work (still on loading screen but timers start when it disappears)
	{
		bool early_join_requested = (CS(this).autojoin_checked < 0);
		CS(this).autojoin_checked = 1;
		// don't do this in ClientConnect
		// many things can go wrong if a client is spawned as player on connection
		if (early_join_requested || MUTATOR_CALLHOOK(AutoJoinOnConnection, this)
		|| (!(autocvar_sv_spectate || autocvar_g_campaign || (Player_GetForcedTeamIndex(this) == TEAM_FORCE_SPECTATOR))
		    && (!teamplay || autocvar_g_balance_teams)))
		{
			if(joinAllowed(this, this.wants_join))
				Join(this, teamplay);
			else if (!autocvar_sv_spectate) // we really want to join and some blockers may be brief (g_maxping)
				if (time < CS(this).spectatortime + MIN_SPEC_TIME) // centreprints don't appear while spamming
					CS(this).autojoin_checked = -1; // keep trying for MIN_SPEC_TIME
			return;
		}
	}
	else if (IS_OBSERVER(this) || IS_SPEC(this))
		ObserverOrSpectatorThink(this);

	// WEAPONTODO: Add weapon request for this
	if (!zoomstate_set)
	{
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

	// Voice sound effects
	if (CS(this).teamkill_soundtime && time > CS(this).teamkill_soundtime)
	{
		CS(this).teamkill_soundtime = 0;

		entity e = CS(this).teamkill_soundsource;
		entity oldpusher = e.pusher;
		e.pusher = this;
		PlayerSound(e, playersound_teamshoot, CH_VOICE, VOL_BASEVOICE, VOICETYPE_LASTATTACKER_ONLY);
		e.pusher = oldpusher;
	}

	if (CS(this).taunt_soundtime && time > CS(this).taunt_soundtime)
	{
		CS(this).taunt_soundtime = 0;
		PlayerSound(this, playersound_taunt, CH_VOICE, VOL_BASEVOICE, VOICETYPE_AUTOTAUNT);
	}

	target_voicescript_next(this);
}

void DrownPlayer(entity this)
{
	// TODO: mutator hook to prevent drowning?
	if(IS_DEAD(this) || game_stopped || time < game_starttime || this.vehicle
	|| STAT(FROZEN, this) || this.watertype != CONTENT_WATER)
	{
		STAT(AIR_FINISHED, this) = 0;
		return;
	}

	if (this.waterlevel != WATERLEVEL_SUBMERGED)
	{
		if(STAT(AIR_FINISHED, this) && STAT(AIR_FINISHED, this) < time)
			PlayerSound(this, playersound_gasp, CH_PLAYER, VOL_BASE, VOICETYPE_PLAYERSOUND);
		STAT(AIR_FINISHED, this) = 0;
	}
	else
	{
		if (!STAT(AIR_FINISHED, this))
			STAT(AIR_FINISHED, this) = time + autocvar_g_balance_contents_drowndelay;
		if (STAT(AIR_FINISHED, this) < time)
		{	// drown!
			if (this.pain_finished < time)
			{
				Damage (this, NULL, NULL, autocvar_g_balance_contents_playerdamage_drowning * autocvar_g_balance_contents_damagerate, DEATH_DROWN.m_id, DMG_NOWEP, this.origin, '0 0 0');
				this.pain_finished = time + 0.5;
			}
		}
	}
}

.bool move_qcphysics;

void Player_Physics(entity this)
{
	this.movetype = (this.move_qcphysics) ? MOVETYPE_QCPLAYER : this.move_movetype;

	if(!this.move_qcphysics)
		return;

	if(!frametime && !CS(this).pm_frametime)
		return;

	Movetype_Physics_NoMatchTicrate(this, CS(this).pm_frametime, true);

	CS(this).pm_frametime = 0;
}

/*
=============
PlayerPostThink

Called every frame for each real client by DP (and for each bot by StartFrame()),
and when executing every asynchronous move, so only include things that MUST be done then.
Use PlayerFrame() instead for code that only needs to run once per server frame.
frametime == 0 in the asynchronous code path.
=============
*/
void PlayerPostThink (entity this)
{
	Player_Physics(this);

	if (IS_PLAYER(this))
	{
		DrownPlayer(this);
		UpdateChatBubble(this);
		if (CS(this).impulse)
			ImpulseCommands(this);
		GetPressedKeys(this);
		if (game_stopped)
		{
			CSQCMODEL_AUTOUPDATE(this);
			return;
		}
	}
	else if (IS_OBSERVER(this) && STAT(PRESSED_KEYS, this))
	{
		CS(this).pressedkeys = 0;
		STAT(PRESSED_KEYS, this) = 0;
	}

	CSQCMODEL_AUTOUPDATE(this);
}

/*
=============
PlayerFrame

Called every frame for each client by StartFrame().
Use this for code that only needs to run once per server frame.
frametime is always set here.
=============
*/
void PlayerFrame (entity this)
{
// formerly PreThink code

	if (this.score_frame_dmg)
	{
		this.handicap_avg_given_sum += this.score_frame_dmg * Handicap_GetTotalHandicap(this, false);
		GameRules_scoring_add(this, DMG, this.score_frame_dmg);
		this.score_frame_dmg = 0;
	}
	if (this.score_frame_dmgtaken)
	{
		this.handicap_avg_taken_sum += this.score_frame_dmgtaken * Handicap_GetTotalHandicap(this, true);
		GameRules_scoring_add(this, DMGTAKEN, this.score_frame_dmgtaken);
		this.score_frame_dmgtaken = 0;
	}

	STAT(GUNALIGN, this) = CS_CVAR(this).cvar_cl_gunalign; // TODO
	STAT(MOVEVARS_CL_TRACK_CANJUMP, this) = CS_CVAR(this).cvar_cl_movement_track_canjump;

	// physics frames: update anticheat stuff
	anticheat_prethink(this);

	// Check if spectating is allowed
	// cvar hook/callback TODO: make this event-driven
	if (!autocvar_sv_spectate && IS_REAL_CLIENT(this)
	&& (IS_SPEC(this) || IS_OBSERVER(this)) && !INGAME(this))
	{
		float cutoff = CS(this).spectatortime + autocvar_g_maxplayers_spectator_blocktime;
		if (time > cutoff + MIN_SPEC_TIME * 0.5 // sv_spectate was disabled recently (or the server was stalled far too long)
		|| CS(this).autojoin_checked == 0) // or too soon to have tried to autojoin
		{
			CS(this).spectatortime = time; // reset the grace period
			if (CS(this).autojoin_checked) // only notify when sv_spectate was disabled recently, to prevent spam
				Send_Notification(NOTIF_ONE_ONLY, this, MSG_MULTI, SPECTATE_WARNING, autocvar_g_maxplayers_spectator_blocktime);
		}
		else if (time > cutoff)
			if (dropclient_schedule(this))
				Send_Notification(NOTIF_ONE_ONLY, this, MSG_INFO, INFO_QUIT_KICK_SPECTATING);
	}

	// Check for nameless players
	if (this.netname == "" || this.netname != CS(this).netname_previous)
	{
		bool assume_unchanged = (CS(this).netname_previous == "");
		if (autocvar_sv_name_maxlength > 0 && strlennocol(this.netname) > autocvar_sv_name_maxlength)
		{
			int new_length = textLengthUpToLength(this.netname, autocvar_sv_name_maxlength, strlennocol);
			this.netname = strzone(strcat(substring(this.netname, 0, new_length), "^7"));
			sprint(this, sprintf("Warning: your name is longer than %d characters, it has been truncated.\n", autocvar_sv_name_maxlength));
			assume_unchanged = false;
			// stuffcmd(this, strcat("name ", this.netname, "\n")); // maybe?
		}
		if (isInvisibleString(this.netname))
		{
			this.netname = strzone(sprintf("Player#%d", this.playerid));
			sprint(this, "Warning: invisible names are not allowed.\n");
			assume_unchanged = false;
			// stuffcmd(this, strcat("name ", this.netname, "\n")); // maybe?
		}
		if (!assume_unchanged && autocvar_sv_eventlog)
			GameLogEcho(strcat(":name:", ftos(this.playerid), ":", playername(this.netname, this.team, false)));
		strcpy(CS(this).netname_previous, this.netname);
	}

	// version nagging
	if (CS(this).version_nagtime && CS_CVAR(this).cvar_g_xonoticversion && time > CS(this).version_nagtime)
	{
		CS(this).version_nagtime = 0;
		if (strstrofs(CS_CVAR(this).cvar_g_xonoticversion, "git", 0) >= 0 || strstrofs(CS_CVAR(this).cvar_g_xonoticversion, "autobuild", 0) >= 0)
		{
			// git client
		}
		else if (strstrofs(autocvar_g_xonoticversion, "git", 0) >= 0 || strstrofs(autocvar_g_xonoticversion, "autobuild", 0) >= 0)
		{
			// git server
			Send_Notification(NOTIF_ONE_ONLY, this, MSG_INFO, INFO_VERSION_BETA, autocvar_g_xonoticversion, CS_CVAR(this).cvar_g_xonoticversion);
		}
		else
		{
			int r = vercmp(CS_CVAR(this).cvar_g_xonoticversion, autocvar_g_xonoticversion);
			if (r < 0) // old client
				Send_Notification(NOTIF_ONE_ONLY, this, MSG_INFO, INFO_VERSION_OUTDATED, autocvar_g_xonoticversion, CS_CVAR(this).cvar_g_xonoticversion);
			else if (r > 0) // old server
				Send_Notification(NOTIF_ONE_ONLY, this, MSG_INFO, INFO_VERSION_OLD, autocvar_g_xonoticversion, CS_CVAR(this).cvar_g_xonoticversion);
		}
	}

	// GOD MODE info
	if (!(this.flags & FL_GODMODE) && this.max_armorvalue)
	{
		Send_Notification(NOTIF_ONE_ONLY, this, MSG_INFO, INFO_GODMODE_OFF, this.max_armorvalue);
		this.max_armorvalue = 0;
	}

	// Vehicles
	if(autocvar_g_vehicles_enter && (time > this.last_vehiclecheck) && !game_stopped && !this.vehicle)
	if(IS_PLAYER(this) && !STAT(FROZEN, this) && !StatusEffects_active(STATUSEFFECT_Frozen, this) && !IS_DEAD(this) && !IS_INDEPENDENT_PLAYER(this))
	{
		FOREACH_ENTITY_RADIUS(this.origin, autocvar_g_vehicles_enter_radius, IS_VEHICLE(it) && !IS_DEAD(it) && it.takedamage != DAMAGE_NO,
		{
			if(!it.owner)
			{
				if(!it.team || SAME_TEAM(this, it))
					Send_Notification(NOTIF_ONE, this, MSG_CENTER, CENTER_VEHICLE_ENTER);
				else if(autocvar_g_vehicles_steal)
					Send_Notification(NOTIF_ONE, this, MSG_CENTER, CENTER_VEHICLE_ENTER_STEAL);
			}
			else if((it.vehicle_flags & VHF_MULTISLOT) && SAME_TEAM(it.owner, this))
			{
				Send_Notification(NOTIF_ONE, this, MSG_CENTER, CENTER_VEHICLE_ENTER_GUNNER);
			}
		});

		this.last_vehiclecheck = time + 1;
	}



// formerly PostThink code
	if (autocvar_sv_maxidle > 0 || ((IS_PLAYER(this) || this.wants_join) && autocvar_sv_maxidle_playertospectator > 0))
	if (IS_REAL_CLIENT(this))
	if (IS_PLAYER(this) || this.wants_join || autocvar_sv_maxidle_alsokickspectators)
	if (!intermission_running) // NextLevel() kills all centerprints after setting this true
	{
		int totalClients = 0;
		if(autocvar_sv_maxidle > 0 && autocvar_sv_maxidle_slots > 0)
		{
			// maxidle disabled in local matches by not counting clients (totalClients 0)
			if (server_is_dedicated)
			{
				FOREACH_CLIENT(IS_REAL_CLIENT(it) || autocvar_sv_maxidle_slots_countbots,
				{
					++totalClients;
				});
				if (maxclients - totalClients > autocvar_sv_maxidle_slots)
					totalClients = 0;
			}
		}
		else if ((IS_PLAYER(this) || this.wants_join) && autocvar_sv_maxidle_playertospectator > 0)
		{
			FOREACH_CLIENT(IS_REAL_CLIENT(it),
			{
				++totalClients;
			});
		}

		if (totalClients < autocvar_sv_maxidle_minplayers)
		{
			// idle kick disabled
			CS(this).parm_idlesince = time;
		}
		else if (time - CS(this).parm_idlesince < 1) // instead of (time == this.parm_idlesince) to support sv_maxidle <= 10
		{
			if (CS(this).idlekick_lasttimeleft)
			{
				CS(this).idlekick_lasttimeleft = 0;
				Kill_Notification(NOTIF_ONE_ONLY, this, MSG_CENTER, CPID_IDLING);
			}
		}
		else
		{
			float maxidle_time = autocvar_sv_maxidle;
			if ((IS_PLAYER(this) || this.wants_join)
			&& autocvar_sv_maxidle_playertospectator > 0)
				maxidle_time = autocvar_sv_maxidle_playertospectator;
			float timeleft = ceil(maxidle_time - (time - CS(this).parm_idlesince));
			float countdown_time = max(min(10, maxidle_time - 1), ceil(maxidle_time * 0.33)); // - 1 to support maxidle_time <= 10
			if (timeleft == countdown_time && !CS(this).idlekick_lasttimeleft)
			{
				if ((IS_PLAYER(this) || this.wants_join) && autocvar_sv_maxidle_playertospectator > 0)
				{
					if (!this.wants_join) // no countdown centreprint when getting kicked off the join queue
						Send_Notification(NOTIF_ONE_ONLY, this, MSG_CENTER, CENTER_MOVETOSPEC_IDLING, timeleft);
				}
				else
					Send_Notification(NOTIF_ONE_ONLY, this, MSG_CENTER, CENTER_DISCONNECT_IDLING, timeleft);
			}
			if (timeleft <= 0)
			{
				if ((IS_PLAYER(this) || this.wants_join)
				&& autocvar_sv_maxidle_playertospectator > 0)
				{
					if (this.wants_join)
						Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_MOVETOSPEC_IDLING_QUEUE, this.netname, maxidle_time);
					else
						Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_MOVETOSPEC_IDLING, this.netname, maxidle_time);
					PutObserverInServer(this, true, true);
					// Can't do this in PutObserverInServer() or SetPlayerTeam() cos it causes
					// mouse2 (change spectate mode) to kick the player off the join queue.
					this.wants_join = 0;
					this.team_selected = 0;
					// when the player is kicked off the server, these are called in ClientDisconnect()
					if (!TeamBalance_QueuedPlayersTagIn(this))
					if (autocvar_g_balance_teams_remove)
						TeamBalance_RemoveExcessPlayers(this);
				}
				else
				{
					if (dropclient_schedule(this))
						Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_QUIT_KICK_IDLING, this.netname, maxidle_time);
				}
				return;
			}
			else if (timeleft <= countdown_time
			&& !this.wants_join) // no countdown bangs when getting kicked off the join queue
			{
				if (timeleft != CS(this).idlekick_lasttimeleft)
					play2(this, SND(TALK2));
				CS(this).idlekick_lasttimeleft = timeleft;
			}
		}
	}

	CheatFrame(this);

	if (game_stopped)
	{
		this.solid = SOLID_NOT;
		this.takedamage = DAMAGE_NO;
		set_movetype(this, MOVETYPE_NONE);
		CS(this).teamkill_complain = 0;
		CS(this).teamkill_soundtime = 0;
		CS(this).teamkill_soundsource = NULL;
	}

	if (this.waypointsprite_attachedforcarrier) {
		float hp = healtharmor_maxdamage(GetResource(this, RES_HEALTH), GetResource(this, RES_ARMOR), autocvar_g_balance_armor_blockpercent, DEATH_WEAPON.m_id).x;
		WaypointSprite_UpdateHealth(this.waypointsprite_attachedforcarrier, hp);
	}
}

// hack to copy the button fields from the client entity to the Client State
void PM_UpdateButtons(entity this, entity store)
{
	if(this.impulse)
		store.impulse = this.impulse;
	this.impulse = 0;

	bool typing = this.buttonchat || this.button12;

	store.button0 = (typing) ? 0 : this.button0;
	//button1?!
	store.button2 = (typing) ? 0 : this.button2;
	store.button3 = (typing) ? 0 : this.button3;
	store.button4 = this.button4;
	store.button5 = (typing) ? 0 : this.button5;
	store.button6 = this.button6;
	store.button7 = this.button7;
	store.button8 = this.button8;
	store.button9 = this.button9;
	store.button10 = this.button10;
	store.button11 = this.button11;
	store.button12 = this.button12;
	store.button13 = this.button13;
	store.button14 = this.button14;
	store.button15 = this.button15;
	store.button16 = this.button16;
	store.buttonuse = this.buttonuse;
	store.buttonchat = this.buttonchat;

	store.cursor_active = this.cursor_active;
	store.cursor_screen = this.cursor_screen;
	store.cursor_trace_start = this.cursor_trace_start;
	store.cursor_trace_endpos = this.cursor_trace_endpos;
	store.cursor_trace_ent = this.cursor_trace_ent;

	store.ping = this.ping;
	store.ping_packetloss = this.ping_packetloss;
	store.ping_movementloss = this.ping_movementloss;

	store.v_angle = this.v_angle;
	store.movement = this.movement;
}

NET_HANDLE(fpsreport, bool)
{
	int fps = ReadShort();
	PlayerScore_Set(sender, SP_FPS, fps);
	return true;
}
