#include "cl_client.qh"

#include "anticheat.qh"
#include "cl_impulse.qh"
#include "cl_player.qh"
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

#include "bot/bot.qh"
#include "bot/navigation.qh"

#include "../common/ent_cs.qh"
#include "../common/state.qh"

#include "../common/triggers/teleporters.qh"

#include "../common/vehicles/all.qh"

#include "weapons/hitplot.qh"
#include "weapons/weaponsystem.qh"

#include "../common/net_notice.qh"
#include "../common/physics.qh"

#include "../common/items/all.qc"

#include "../common/mutators/mutator/waypoints/all.qh"

#include "../common/triggers/subs.qh"
#include "../common/triggers/triggers.qh"
#include "../common/triggers/trigger/secret.qh"

#include "../common/minigames/sv_minigames.qh"

#include "../common/items/inventory.qh"

#include "../common/monsters/sv_monsters.qh"

#include "../lib/warpzone/server.qh"


void send_CSQC_teamnagger() {
	WriteHeader(MSG_BROADCAST, TE_CSQC_TEAMNAGGER);
}

bool ClientData_Send(entity this, entity to, int sf)
{
	if(to != self.owner)
	{
		error("wtf");
		return false;
	}

	entity e;

	e = to;
	if(IS_SPEC(to))
		e = to.enemy;

	sf = 0;

	if(e.race_completed)
		sf |= 1; // forced scoreboard
	if(to.spectatee_status)
		sf |= 2; // spectator ent number follows
	if(e.zoomstate)
		sf |= 4; // zoomed
	if(e.porto_v_angle_held)
		sf |= 8; // angles held

	WriteHeader(MSG_ENTITY, ENT_CLIENT_CLIENTDATA);
	WriteByte(MSG_ENTITY, sf);

	if(sf & 2)
		WriteByte(MSG_ENTITY, to.spectatee_status);

	if(sf & 8)
	{
		WriteAngle(MSG_ENTITY, e.v_angle.x);
		WriteAngle(MSG_ENTITY, e.v_angle.y);
	}

	return true;
}

void ClientData_Attach()
{SELFPARAM();
	Net_LinkEntity(this.clientdata = new(clientdata), false, 0, ClientData_Send);
	make_pure(this.clientdata);
	self.clientdata.drawonlytoclient = this;
	self.clientdata.owner = this;
}

void ClientData_Detach()
{SELFPARAM();
	remove(self.clientdata);
	self.clientdata = world;
}

void ClientData_Touch(entity e)
{
	e.clientdata.SendFlags = 1;

	// make it spectatable
	entity e2;
	FOR_EACH_REALCLIENT(e2)
	{
		if(e2 != e)
			if(IS_SPEC(e2))
				if(e2.enemy == e)
					e2.clientdata.SendFlags = 1;
	}
}

.string netname_previous;

void SetSpectatee(entity player, entity spectatee);


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
	player_setupanimsformodel();
}

/*
=============
PutObserverInServer

putting a client as observer in the server
=============
*/
void FixPlayermodel(entity player);
void PutObserverInServer()
{
	SELFPARAM();
	PlayerState_detach(this);
	entity	spot;
    self.hud = HUD_NORMAL;

	if(IS_PLAYER(self)) { Send_Effect(EFFECT_SPAWN_NEUTRAL, self.origin, '0 0 0', 1); }

	spot = SelectSpawnPoint (true);
	if(!spot)
		error("No spawnpoints for observers?!?\n");
	RemoveGrapplingHook(self); // Wazat's Grappling Hook

	if(IS_REAL_CLIENT(self))
	{
		msg_entity = self;
		WriteByte(MSG_ONE, SVC_SETVIEW);
		WriteEntity(MSG_ONE, self);
	}

	self.frags = FRAGS_SPECTATOR;
	self.bot_attack = false;

	bool mutator_returnvalue = MUTATOR_CALLHOOK(MakePlayerObserver);

	Portal_ClearAll(self);

	Unfreeze(self);

	if(self.alivetime)
	{
		if(!warmup_stage)
			PS_GR_P_ADDVAL(self, PLAYERSTATS_ALIVETIME, time - self.alivetime);
		self.alivetime = 0;
	}

	if(self.vehicle)
		vehicles_exit(VHEF_RELEASE);

	WaypointSprite_PlayerDead();

	if(!mutator_returnvalue)  // mutator prevents resetting teams
		self.team = -1;  // move this as it is needed to log the player spectating in eventlog

	if(self.killcount != FRAGS_SPECTATOR)
	{
		Send_Notification(NOTIF_ALL, world, MSG_INFO, INFO_QUIT_SPECTATE, self.netname);
		if(!intermission_running)
		if(autocvar_g_chat_nospectators == 1 || (!(warmup_stage || gameover) && autocvar_g_chat_nospectators == 2))
			Send_Notification(NOTIF_ONE_ONLY, self, MSG_INFO, INFO_CHAT_NOSPECTATORS);

		if(self.just_joined == false) {
			LogTeamchange(self.playerid, -1, 4);
		} else
			self.just_joined = false;
	}

	PlayerScore_Clear(self); // clear scores when needed

	accuracy_resend(self);

	self.spectatortime = time;

	self.classname = STR_OBSERVER;
	self.iscreature = false;
	self.teleportable = TELEPORT_SIMPLE;
	self.damagedbycontents = false;
	self.health = FRAGS_SPECTATOR;
	self.takedamage = DAMAGE_NO;
	self.solid = SOLID_NOT;
	self.movetype = MOVETYPE_FLY_WORLDONLY; // user preference is controlled by playerprethink
	self.flags = FL_CLIENT | FL_NOTARGET;
	self.armorvalue = 666;
	self.effects = 0;
	self.armorvalue = autocvar_g_balance_armor_start;
	self.pauserotarmor_finished = 0;
	self.pauserothealth_finished = 0;
	self.pauseregen_finished = 0;
	self.damageforcescale = 0;
	self.death_time = 0;
	self.respawn_flags = 0;
	self.respawn_time = 0;
	self.stat_respawn_time = 0;
	self.alpha = 0;
	self.scale = 0;
	self.fade_time = 0;
	self.pain_frame = 0;
	self.pain_finished = 0;
	self.strength_finished = 0;
	self.invincible_finished = 0;
	self.superweapons_finished = 0;
	self.pushltime = 0;
	self.istypefrag = 0;
	self.think = func_null;
	self.nextthink = 0;
	self.hook_time = 0;
	self.deadflag = DEAD_NO;
	self.angles = spot.angles;
	self.angles_z = 0;
	self.fixangle = true;
	self.crouch = false;
	self.revival_time = 0;

	setorigin (self, (spot.origin + PL_VIEW_OFS)); // offset it so that the spectator spawns higher off the ground, looks better this way
	self.prevorigin = self.origin;
	self.items = 0;
	self.weapons = '0 0 0';
	self.model = "";
	FixPlayermodel(self);
	setmodel(self, MDL_Null);
	self.drawonlytoclient = self;

	setsize (self, PL_CROUCH_MIN, PL_CROUCH_MAX); // give the spectator some space between walls for MOVETYPE_FLY_WORLDONLY
	self.view_ofs = '0 0 0'; // so that your view doesn't go into the ceiling with MOVETYPE_FLY_WORLDONLY, previously "PL_VIEW_OFS"

	PS(self).m_weapon = WEP_Null;
	self.weaponname = "";
	PS(self).m_switchingweapon = WEP_Null;
	self.weaponmodel = "";
	for (int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	{
		self.weaponentities[slot] = NULL;
	}
	self.exteriorweaponentity = world;
	self.killcount = FRAGS_SPECTATOR;
	self.velocity = '0 0 0';
	self.avelocity = '0 0 0';
	self.punchangle = '0 0 0';
	self.punchvector = '0 0 0';
	self.oldvelocity = self.velocity;
	self.fire_endtime = -1;
	self.event_damage = func_null;
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
			string s = Static_Team_ColorName_Lower(player.team);
			if (s != "neutral")
			{
				defaultmodel = cvar_string(strcat("sv_defaultplayermodel_", s));
				defaultskin = cvar(strcat("sv_defaultplayerskin_", s));
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
	MUTATOR_CALLHOOK(FixPlayermodel, defaultmodel, defaultskin);
	defaultmodel = ret_string;
	defaultskin = ret_int;

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

		oldskin = player.skin;
		player.skin = stof(player.playerskin);
	}

	if(chmdl || oldskin != player.skin) // model or skin has changed
	{
		player.species = player_getspecies(player); // update species
	}

	if(!teamplay)
		if(strlen(autocvar_sv_defaultplayercolors))
			if(player.clientcolors != stof(autocvar_sv_defaultplayercolors))
				setcolor(player, stof(autocvar_sv_defaultplayercolors));
}


/** Called when a client spawns in the server */
void PutClientInServer()
{
	SELFPARAM();
	if (IS_BOT_CLIENT(this)) {
		this.classname = STR_PLAYER;
	} else if (IS_REAL_CLIENT(this)) {
		msg_entity = this;
		WriteByte(MSG_ONE, SVC_SETVIEW);
		WriteEntity(MSG_ONE, this);
	}
	if (gameover) {
		this.classname = STR_OBSERVER;
	}

	SetSpectatee(this, NULL);

	// reset player keys
	this.itemkeys = 0;

	MUTATOR_CALLHOOK(PutClientInServer, this);

	if (IS_OBSERVER(this)) {
		PutObserverInServer();
	} else if (IS_PLAYER(this)) {
		PlayerState_attach(this);
		accuracy_resend(this);

		if (this.team < 0)
			JoinBestTeam(this, false, true);

		entity spot = SelectSpawnPoint(false);
		if (!spot) {
			Send_Notification(NOTIF_ONE_ONLY, this, MSG_CENTER, CENTER_JOIN_NOSPAWNS);
			return; // spawn failed
		}

		this.classname = STR_PLAYER;
		this.wasplayer = true;
		this.iscreature = true;
		this.teleportable = TELEPORT_NORMAL;
		this.damagedbycontents = true;
		this.movetype = MOVETYPE_WALK;
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
		this.think = func_null; // players have no think function
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
		this.revival_time = 0;
		this.air_finished = time + 12;

		entity spawnevent = new(spawnevent);
		make_pure(spawnevent);
		spawnevent.owner = this;
		Net_LinkEntity(spawnevent, false, 0.5, SpawnEvent_Send);

		// Cut off any still running player sounds.
		stopsound(this, CH_PLAYER_SINGLE);

		this.model = "";
		FixPlayermodel(this);
		this.drawonlytoclient = NULL;

		this.crouch = false;
		this.view_ofs = PL_VIEW_OFS;
		setsize(this, PL_MIN, PL_MAX);
		this.spawnorigin = spot.origin;
		setorigin(this, spot.origin + '0 0 1' * (1 - this.mins.z - 24));
		// don't reset back to last position, even if new position is stuck in solid
		this.oldorigin = this.origin;
		this.prevorigin = this.origin;
		this.lastteleporttime = time; // prevent insane speeds due to changing origin
        this.hud = HUD_NORMAL;

		this.event_damage = PlayerDamage;

		this.bot_attack = true;
		this.monster_attack = true;

		this.BUTTON_ATCK = this.BUTTON_JUMP = this.BUTTON_ATCK2 = false;

		if (this.killcount == FRAGS_SPECTATOR) {
			PlayerScore_Clear(this);
			this.killcount = 0;
		}

		for (int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
		{
			CL_SpawnWeaponentity(this, weaponentities[slot]);
		}
		this.alpha = default_player_alpha;
		this.colormod = '1 1 1' * autocvar_g_player_brightness;
		this.exteriorweaponentity.alpha = default_weapon_alpha;

		this.speedrunning = false;

		target_voicescript_clear(this);

		// reset fields the weapons may use
		FOREACH(Weapons, true, LAMBDA(
			it.wr_resetplayer(it);
			// reload all reloadable weapons
			if (it.spawnflags & WEP_FLAG_RELOADABLE) {
				this.weapon_load[it.m_id] = it.reloading_ammo;
			}
		));

		{
			string s = spot.target;
			spot.target = string_null;
			WITH(entity, activator, this, LAMBDA(
				WITH(entity, self, spot, SUB_UseTargets())
			));
			spot.target = s;
		}

		Unfreeze(this);

		MUTATOR_CALLHOOK(PlayerSpawn, spot);

		if (autocvar_spawn_debug)
		{
			sprint(this, strcat("spawnpoint origin:  ", vtos(spot.origin), "\n"));
			remove(spot); // usefull for checking if there are spawnpoints, that let drop through the floor
		}

		PS(this).m_switchweapon = w_getbestweapon(this);
		this.cnt = -1; // W_LastWeapon will not complain
		PS(this).m_weapon = WEP_Null;
		this.weaponname = "";
		PS(this).m_switchingweapon = WEP_Null;

		if (!warmup_stage && !this.alivetime)
			this.alivetime = time;

		antilag_clear(this);
	}
}

void ClientInit_misc();

.float ebouncefactor, ebouncestop; // electro's values
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
	ClientInit_misc();
	MUTATOR_CALLHOOK(Ent_Init);
}
void ClientInit_misc()
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
	WriteByte(channel, self.count * 255.0); // g_balance_armor_blockpercent
	WriteByte(channel, serverflags); // client has to know if it should zoom or not
	WriteCoord(channel, autocvar_g_trueaim_minrange);
}

void ClientInit_CheckUpdate()
{SELFPARAM();
	self.nextthink = time;
	if(self.count != autocvar_g_balance_armor_blockpercent)
	{
		self.count = autocvar_g_balance_armor_blockpercent;
		self.SendFlags |= 1;
	}
}

void ClientInit_Spawn()
{SELFPARAM();

	entity e = new(clientinit);
	make_pure(e);
	e.think = ClientInit_CheckUpdate;
	Net_LinkEntity(e, false, 0, ClientInit_SendEntity);

	WITH(entity, self, e, ClientInit_CheckUpdate());
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
void SetChangeParms ()
{SELFPARAM();
	// save parms for level change
	parm1 = self.parm_idlesince - time;

	MUTATOR_CALLHOOK(SetChangeParms);
}

/*
=============
DecodeLevelParms
=============
*/
void DecodeLevelParms ()
{SELFPARAM();
	// load parms
	self.parm_idlesince = parm1;
	if(self.parm_idlesince == -(86400 * 366))
		self.parm_idlesince = time;

	// whatever happens, allow 60 seconds of idling directly after connect for map loading
	self.parm_idlesince = max(self.parm_idlesince, time - sv_maxidle + 60);

	MUTATOR_CALLHOOK(DecodeLevelParms);
}

/*
=============
ClientKill

Called when a client types 'kill' in the console
=============
*/

.float clientkill_nexttime;
void ClientKill_Now_TeamChange()
{SELFPARAM();
	if(self.killindicator_teamchange == -1)
	{
		JoinBestTeam( self, false, true );
	}
	else if(self.killindicator_teamchange == -2)
	{
		if(blockSpectators)
			Send_Notification(NOTIF_ONE_ONLY, self, MSG_INFO, INFO_SPECTATE_WARNING, autocvar_g_maxplayers_spectator_blocktime);
		PutObserverInServer();
	}
	else
		SV_ChangeTeam(self.killindicator_teamchange - 1);
	self.killindicator_teamchange = 0;
}

void ClientKill_Now()
{SELFPARAM();
	if(self.vehicle)
	{
	    vehicles_exit(VHEF_RELEASE);
	    if(!self.killindicator_teamchange)
	    {
            self.vehicle_health = -1;
            Damage(self, self, self, 1 , DEATH_KILL.m_id, self.origin, '0 0 0');
	    }
	}

	if(self.killindicator && !wasfreed(self.killindicator))
		remove(self.killindicator);

	self.killindicator = world;

	if(self.killindicator_teamchange)
		ClientKill_Now_TeamChange();

	if(IS_PLAYER(self))
		Damage(self, self, self, 100000, DEATH_KILL.m_id, self.origin, '0 0 0');

	// now I am sure the player IS dead
}
void KillIndicator_Think()
{SELFPARAM();
	if (gameover)
	{
		self.owner.killindicator = world;
		remove(self);
		return;
	}

	if (self.owner.alpha < 0 && !self.owner.vehicle)
	{
		self.owner.killindicator = world;
		remove(self);
		return;
	}

	if(self.cnt <= 0)
	{
		WITH(entity, self, self.owner, ClientKill_Now());
		return;
	}
    else if(g_cts && self.health == 1) // health == 1 means that it's silent
    {
        self.nextthink = time + 1;
        self.cnt -= 1;
    }
	else
	{
		if(self.cnt <= 10)
			setmodel(self, MDL_NUM(self.cnt));
		if(IS_REAL_CLIENT(self.owner))
		{
			if(self.cnt <= 10)
				{ Send_Notification(NOTIF_ONE, self.owner, MSG_ANNCE, Announcer_PickNumber(CNT_KILL, self.cnt)); }
		}
		self.nextthink = time + 1;
		self.cnt -= 1;
	}
}

float clientkilltime;
void ClientKill_TeamChange (float targetteam) // 0 = don't change, -1 = auto, -2 = spec
{SELFPARAM();
	float killtime;
	float starttime;
	entity e;

	if (gameover)
		return;

	killtime = autocvar_g_balance_kill_delay;

	if(g_race_qualifying || g_cts)
		killtime = 0;

    if(MUTATOR_CALLHOOK(ClientKill, self, killtime))
    	return;

	self.killindicator_teamchange = targetteam;

    if(!self.killindicator)
	{
		if(self.deadflag == DEAD_NO)
		{
			killtime = max(killtime, self.clientkill_nexttime - time);
			self.clientkill_nexttime = time + killtime + autocvar_g_balance_kill_antispam;
		}

		if(killtime <= 0 || !IS_PLAYER(self) || self.deadflag != DEAD_NO)
		{
			ClientKill_Now();
		}
		else
		{
			starttime = max(time, clientkilltime);

			self.killindicator = spawn();
			self.killindicator.owner = self;
			self.killindicator.scale = 0.5;
			setattachment(self.killindicator, self, "");
			setorigin(self.killindicator, '0 0 52');
			self.killindicator.think = KillIndicator_Think;
			self.killindicator.nextthink = starttime + (self.lip) * 0.05;
			clientkilltime = max(clientkilltime, self.killindicator.nextthink + 0.05);
			self.killindicator.cnt = ceil(killtime);
			self.killindicator.count = bound(0, ceil(killtime), 10);
			//sprint(self, strcat("^1You'll be dead in ", ftos(self.killindicator.cnt), " seconds\n"));

			for(e = world; (e = find(e, classname, "body")) != world; )
			{
				if(e.enemy != self)
					continue;
				e.killindicator = spawn();
				e.killindicator.owner = e;
				e.killindicator.scale = 0.5;
				setattachment(e.killindicator, e, "");
				setorigin(e.killindicator, '0 0 52');
				e.killindicator.think = KillIndicator_Think;
				e.killindicator.nextthink = starttime + (e.lip) * 0.05;
				clientkilltime = max(clientkilltime, e.killindicator.nextthink + 0.05);
				e.killindicator.cnt = ceil(killtime);
			}
			self.lip = 0;
		}
	}
	if(self.killindicator)
	{
		if(targetteam == 0) // just die
		{
			self.killindicator.colormod = '0 0 0';
			if(IS_REAL_CLIENT(self))
			if(self.killindicator.cnt > 0)
				Send_Notification(NOTIF_ONE_ONLY, self, MSG_CENTER, CENTER_TEAMCHANGE_SUICIDE, self.killindicator.cnt);
		}
		else if(targetteam == -1) // auto
		{
			self.killindicator.colormod = '0 1 0';
			if(IS_REAL_CLIENT(self))
			if(self.killindicator.cnt > 0)
				Send_Notification(NOTIF_ONE_ONLY, self, MSG_CENTER, CENTER_TEAMCHANGE_AUTO, self.killindicator.cnt);
		}
		else if(targetteam == -2) // spectate
		{
			self.killindicator.colormod = '0.5 0.5 0.5';
			if(IS_REAL_CLIENT(self))
			if(self.killindicator.cnt > 0)
				Send_Notification(NOTIF_ONE_ONLY, self, MSG_CENTER, CENTER_TEAMCHANGE_SPECTATE, self.killindicator.cnt);
		}
		else
		{
			self.killindicator.colormod = Team_ColorRGB(targetteam);
			if(IS_REAL_CLIENT(self))
			if(self.killindicator.cnt > 0)
				Send_Notification(NOTIF_ONE_ONLY, self, MSG_CENTER, APP_TEAM_NUM_4(targetteam, CENTER_TEAMCHANGE_), self.killindicator.cnt);
		}
	}

}

void ClientKill ()
{SELFPARAM();
	if(gameover) return;
	if(self.player_blocked) return;
	if(self.frozen) return;

	ClientKill_TeamChange(0);
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
void ClientPreConnect ()
{SELFPARAM();
	if(autocvar_sv_eventlog)
	{
		GameLogEcho(sprintf(":connect:%d:%d:%s",
			self.playerid,
			etof(self),
			((IS_REAL_CLIENT(self)) ? self.netaddress : "bot")
		));
	}
}
#endif

/*
=============
ClientConnect

Called when a client connects to the server
=============
*/
void DecodeLevelParms ();
void ClientConnect ()
{
	SELFPARAM();
	ClientState_attach(this);
	float t;

	if(IS_CLIENT(self))
	{
		LOG_INFO("Warning: ClientConnect, but already connected!\n");
		return;
	}

	if(Ban_MaybeEnforceBanOnce(self))
		return;

	DecodeLevelParms();

#ifdef WATERMARK
	Send_Notification(NOTIF_ONE_ONLY, self, MSG_INFO, INFO_WATERMARK, WATERMARK);
#endif

	self.classname = "player_joining";

	self.flags = FL_CLIENT;
	self.version_nagtime = time + 10 + random() * 10;

	if(player_count<0)
	{
		LOG_TRACE("BUG player count is lower than zero, this cannot happen!\n");
		player_count = 0;
	}

	// TODO: xonstat elo.txt support, until then just 404s
	if(false && IS_REAL_CLIENT(self)) { PlayerStats_PlayerBasic_CheckUpdate(self); }

	PlayerScore_Attach(self);
	ClientData_Attach();
	accuracy_init(self);
	Inventory_new(self);

	bot_clientconnect();

	playerdemo_init();

	anticheat_init();

	// identify the right forced team
	if(autocvar_g_campaign)
	{
		if(IS_REAL_CLIENT(self)) // only players, not bots
		{
			switch(autocvar_g_campaign_forceteam)
			{
				case 1: self.team_forced = NUM_TEAM_1; break;
				case 2: self.team_forced = NUM_TEAM_2; break;
				case 3: self.team_forced = NUM_TEAM_3; break;
				case 4: self.team_forced = NUM_TEAM_4; break;
				default: self.team_forced = 0;
			}
		}
	}
	else if(PlayerInIDList(self, autocvar_g_forced_team_red))
		self.team_forced = NUM_TEAM_1;
	else if(PlayerInIDList(self, autocvar_g_forced_team_blue))
		self.team_forced = NUM_TEAM_2;
	else if(PlayerInIDList(self, autocvar_g_forced_team_yellow))
		self.team_forced = NUM_TEAM_3;
	else if(PlayerInIDList(self, autocvar_g_forced_team_pink))
		self.team_forced = NUM_TEAM_4;
	else if(autocvar_g_forced_team_otherwise == "red")
		self.team_forced = NUM_TEAM_1;
	else if(autocvar_g_forced_team_otherwise == "blue")
		self.team_forced = NUM_TEAM_2;
	else if(autocvar_g_forced_team_otherwise == "yellow")
		self.team_forced = NUM_TEAM_3;
	else if(autocvar_g_forced_team_otherwise == "pink")
		self.team_forced = NUM_TEAM_4;
	else if(autocvar_g_forced_team_otherwise == "spectate")
		self.team_forced = -1;
	else if(autocvar_g_forced_team_otherwise == "spectator")
		self.team_forced = -1;
	else
		self.team_forced = 0;

	if(!teamplay)
		if(self.team_forced > 0)
			self.team_forced = 0;

	JoinBestTeam(self, false, false); // if the team number is valid, keep it

	if((autocvar_sv_spectate == 1) || autocvar_g_campaign || self.team_forced < 0) {
		self.classname = STR_OBSERVER;
	} else {
		if(teamplay)
		{
			if(autocvar_g_balance_teams)
			{
				self.classname = STR_PLAYER;
				campaign_bots_may_start = 1;
			}
			else
			{
				self.classname = STR_OBSERVER; // do it anyway
			}
		}
		else
		{
			self.classname = STR_PLAYER;
			campaign_bots_may_start = 1;
		}
	}

	self.playerid = (playerid_last = playerid_last + 1);

	PlayerStats_GameReport_AddEvent(sprintf("kills-%d", self.playerid));

    if(IS_BOT_CLIENT(self))
        PlayerStats_GameReport_AddPlayer(self);

	if(autocvar_sv_eventlog)
		GameLogEcho(strcat(":join:", ftos(self.playerid), ":", ftos(etof(self)), ":", ((IS_REAL_CLIENT(self)) ? self.netaddress : "bot"), ":", self.netname));

	LogTeamchange(self.playerid, self.team, 1);

	self.just_joined = true;  // stop spamming the eventlog with additional lines when the client connects

	self.netname_previous = strzone(self.netname);

	if(IS_PLAYER(self) && teamplay)
		Send_Notification(NOTIF_ALL, world, MSG_INFO, APP_TEAM_ENT_4(self, INFO_JOIN_CONNECT_TEAM_), self.netname);
	else
		Send_Notification(NOTIF_ALL, world, MSG_INFO, INFO_JOIN_CONNECT, self.netname);

	stuffcmd(self, strcat(clientstuff, "\n"));
	stuffcmd(self, "cl_particles_reloadeffects\n"); // TODO do we still need this?

	FixClientCvars(self);

	// spawnfunc_waypoint sprites
	WaypointSprite_InitClient(self);

	// Wazat's grappling hook
	SetGrappleHookBindings();

	// Jetpack binds
	stuffcmd(self, "alias +jetpack +button10\n");
	stuffcmd(self, "alias -jetpack -button10\n");

	// get version info from player
	stuffcmd(self, "cmd clientversion $gameversion\n");

	// get other cvars from player
	GetCvars(0);

	// notify about available teams
	if(teamplay)
	{
		CheckAllowedTeams(self);
		t = 0; if(c1 >= 0) t |= 1; if(c2 >= 0) t |= 2; if(c3 >= 0) t |= 4; if(c4 >= 0) t |= 8;
		stuffcmd(self, strcat("set _teams_available ", ftos(t), "\n"));
	}
	else
		stuffcmd(self, "set _teams_available 0\n");

	entcs_attach(self);

	bot_relinkplayerlist();

	self.spectatortime = time;
	if(blockSpectators)
	{
		Send_Notification(NOTIF_ONE_ONLY, self, MSG_INFO, INFO_SPECTATE_WARNING, autocvar_g_maxplayers_spectator_blocktime);
	}

	self.jointime = time;
	self.allowed_timeouts = autocvar_sv_timeout_number;

	if(IS_REAL_CLIENT(self))
	{
		if(!autocvar_g_campaign)
		{
			self.motd_actived_time = -1;
			Send_Notification(NOTIF_ONE_ONLY, self, MSG_CENTER, CENTER_MOTD, getwelcomemessage());
		}

		if(g_weaponarena_weapons == WEPSET(TUBA))
			stuffcmd(self, "cl_cmd settemp chase_active 1\n");
	}

	if(!sv_foginterval && world.fog != "")
		stuffcmd(self, strcat("\nfog ", world.fog, "\nr_fog_exp2 0\nr_drawfog 1\n"));

	W_HitPlotOpen(self);

	if(autocvar_sv_teamnagger && !(autocvar_bot_vs_human && (c3==-1 && c4==-1)) && !g_ca && !g_cts && !g_race) // teamnagger is currently bad for ca, race & cts
		send_CSQC_teamnagger();

	CheatInitClient();

	CSQCMODEL_AUTOINIT(self);

	self.model_randomizer = random();

	if(IS_REAL_CLIENT(self))
		sv_notice_join(self);

	for (entity e = world; (e = findfloat(e, init_for_player_needed, 1)); ) {
		WITH(entity, self, e, e.init_for_player(this));
	}

	MUTATOR_CALLHOOK(ClientConnect, self);
}
/*
=============
ClientDisconnect

Called when a client disconnects from the server
=============
*/
.entity chatbubbleentity;
void ReadyCount();
void ClientDisconnect ()
{
	SELFPARAM();
	ClientState_detach(this);
	if(self.vehicle)
	    vehicles_exit(VHEF_RELEASE);

	if (!IS_CLIENT(self))
	{
		LOG_INFO("Warning: ClientDisconnect without ClientConnect\n");
		return;
	}

	PlayerStats_GameReport_FinalizePlayer(self);

	if ( self.active_minigame )
		part_minigame(self);

	if(IS_PLAYER(self)) { Send_Effect(EFFECT_SPAWN_NEUTRAL, self.origin, '0 0 0', 1); }

	CheatShutdownClient();

	W_HitPlotClose(self);

	anticheat_report();
	anticheat_shutdown();

	playerdemo_shutdown();

	bot_clientdisconnect();

	entcs_detach(self);

	if(autocvar_sv_eventlog)
		GameLogEcho(strcat(":part:", ftos(self.playerid)));

	Send_Notification(NOTIF_ALL, world, MSG_INFO, INFO_QUIT_DISCONNECT, self.netname);

	MUTATOR_CALLHOOK(ClientDisconnect);

	Portal_ClearAll(self);

	Unfreeze(self);

	RemoveGrapplingHook(self);

	// Here, everything has been done that requires this player to be a client.

	self.flags &= ~FL_CLIENT;

	if (self.chatbubbleentity)
		remove (self.chatbubbleentity);

	if (self.killindicator)
		remove (self.killindicator);

	WaypointSprite_PlayerGone();

	bot_relinkplayerlist();

	accuracy_free(self);
	Inventory_delete(self);
	ClientData_Detach();
	PlayerScore_Detach(self);

	if(self.netname_previous)
		strunzone(self.netname_previous);
	if(self.clientstatus)
		strunzone(self.clientstatus);
	if(self.weaponorder_byimpulse)
		strunzone(self.weaponorder_byimpulse);

	if(self.personal)
		remove(self.personal);

	self.playerid = 0;
	ReadyCount();

	// free cvars
	GetCvars(-1);
}

.float BUTTON_CHAT;
void ChatBubbleThink()
{SELFPARAM();
	self.nextthink = time;
	if ((self.owner.alpha < 0) || self.owner.chatbubbleentity != self)
	{
		if(self.owner) // but why can that ever be world?
			self.owner.chatbubbleentity = world;
		remove(self);
		return;
	}

	self.mdl = "";

	if ( !self.owner.deadflag && IS_PLAYER(self.owner) )
	{
		if ( self.owner.active_minigame )
			self.mdl = "models/sprites/minigame_busy.iqm";
		else if ( self.owner.BUTTON_CHAT )
			self.mdl = "models/misc/chatbubble.spr";
	}

	if ( self.model != self.mdl )
		_setmodel(self, self.mdl);

}

void UpdateChatBubble()
{SELFPARAM();
	if (self.alpha < 0)
		return;
	// spawn a chatbubble entity if needed
	if (!self.chatbubbleentity)
	{
		self.chatbubbleentity = new(chatbubbleentity);
		self.chatbubbleentity.owner = self;
		self.chatbubbleentity.exteriormodeltoclient = self;
		self.chatbubbleentity.think = ChatBubbleThink;
		self.chatbubbleentity.nextthink = time;
		setmodel(self.chatbubbleentity, MDL_CHAT); // precision set below
		//setorigin(self.chatbubbleentity, self.origin + '0 0 15' + self.maxs_z * '0 0 1');
		setorigin(self.chatbubbleentity, '0 0 15' + self.maxs_z * '0 0 1');
		setattachment(self.chatbubbleentity, self, "");  // sticks to moving player better, also conserves bandwidth
		self.chatbubbleentity.mdl = self.chatbubbleentity.model;
		//self.chatbubbleentity.model = "";
		self.chatbubbleentity.effects = EF_LOWPRECISION;
	}
}


// LordHavoc: this hack will be removed when proper _pants/_shirt layers are
// added to the model skins
/*void UpdateColorModHack()
{
	float c;
	c = self.clientcolors & 15;
	// LordHavoc: only bothering to support white, green, red, yellow, blue
	     if (!teamplay) self.colormod = '0 0 0';
	else if (c ==  0) self.colormod = '1.00 1.00 1.00';
	else if (c ==  3) self.colormod = '0.10 1.73 0.10';
	else if (c ==  4) self.colormod = '1.73 0.10 0.10';
	else if (c == 12) self.colormod = '1.22 1.22 0.10';
	else if (c == 13) self.colormod = '0.10 0.10 1.73';
	else self.colormod = '1 1 1';
}*/

void respawn()
{SELFPARAM();
	if(self.alpha >= 0 && autocvar_g_respawn_ghosts)
	{
		self.solid = SOLID_NOT;
		self.takedamage = DAMAGE_NO;
		self.movetype = MOVETYPE_FLY;
		self.velocity = '0 0 1' * autocvar_g_respawn_ghosts_speed;
		self.avelocity = randomvec() * autocvar_g_respawn_ghosts_speed * 3 - randomvec() * autocvar_g_respawn_ghosts_speed * 3;
		self.effects |= CSQCMODEL_EF_RESPAWNGHOST;
		Send_Effect(EFFECT_RESPAWN_GHOST, self.origin, '0 0 0', 1);
		if(autocvar_g_respawn_ghosts_maxtime)
			SUB_SetFade (self, time + autocvar_g_respawn_ghosts_maxtime / 2 + random () * (autocvar_g_respawn_ghosts_maxtime - autocvar_g_respawn_ghosts_maxtime / 2), 1.5);
	}

	CopyBody(1);

	self.effects |= EF_NODRAW; // prevent another CopyBody
	PutClientInServer();
}

void play_countdown(float finished, string samp)
{SELFPARAM();
	if(IS_REAL_CLIENT(self))
		if(floor(finished - time - frametime) != floor(finished - time))
			if(finished - time < 6)
				_sound (self, CH_INFO, samp, VOL_BASE, ATTEN_NORM);
}

void player_powerups ()
{SELFPARAM();
	// add a way to see what the items were BEFORE all of these checks for the mutator hook
	int items_prev = self.items;

	if((self.items & IT_USING_JETPACK) && !self.deadflag && !gameover)
		self.modelflags |= MF_ROCKET;
	else
		self.modelflags &= ~MF_ROCKET;

	self.effects &= ~(EF_RED | EF_BLUE | EF_ADDITIVE | EF_FULLBRIGHT | EF_FLAME | EF_NODEPTHTEST);

	if((self.alpha < 0 || self.deadflag) && !self.vehicle) // don't apply the flags if the player is gibbed
		return;

	Fire_ApplyDamage(self);
	Fire_ApplyEffect(self);

	if (!g_instagib)
	{
		if (self.items & ITEM_Strength.m_itemid)
		{
			play_countdown(self.strength_finished, SND(POWEROFF));
			self.effects = self.effects | (EF_BLUE | EF_ADDITIVE | EF_FULLBRIGHT);
			if (time > self.strength_finished)
			{
				self.items = self.items - (self.items & ITEM_Strength.m_itemid);
				//Send_Notification(NOTIF_ALL, world, MSG_INFO, INFO_POWERDOWN_STRENGTH, self.netname);
				Send_Notification(NOTIF_ONE, self, MSG_CENTER, CENTER_POWERDOWN_STRENGTH);
			}
		}
		else
		{
			if (time < self.strength_finished)
			{
				self.items = self.items | ITEM_Strength.m_itemid;
				Send_Notification(NOTIF_ALL, world, MSG_INFO, INFO_POWERUP_STRENGTH, self.netname);
				Send_Notification(NOTIF_ONE, self, MSG_CENTER, CENTER_POWERUP_STRENGTH);
			}
		}
		if (self.items & ITEM_Shield.m_itemid)
		{
			play_countdown(self.invincible_finished, SND(POWEROFF));
			self.effects = self.effects | (EF_RED | EF_ADDITIVE | EF_FULLBRIGHT);
			if (time > self.invincible_finished)
			{
				self.items = self.items - (self.items & ITEM_Shield.m_itemid);
				//Send_Notification(NOTIF_ALL, world, MSG_INFO, INFO_POWERDOWN_SHIELD, self.netname);
				Send_Notification(NOTIF_ONE, self, MSG_CENTER, CENTER_POWERDOWN_SHIELD);
			}
		}
		else
		{
			if (time < self.invincible_finished)
			{
				self.items = self.items | ITEM_Shield.m_itemid;
				Send_Notification(NOTIF_ALL, world, MSG_INFO, INFO_POWERUP_SHIELD, self.netname);
				Send_Notification(NOTIF_ONE, self, MSG_CENTER, CENTER_POWERUP_SHIELD);
			}
		}
		if (self.items & IT_SUPERWEAPON)
		{
			if (!(self.weapons & WEPSET_SUPERWEAPONS))
			{
				self.superweapons_finished = 0;
				self.items = self.items - (self.items & IT_SUPERWEAPON);
				//Send_Notification(NOTIF_ALL, world, MSG_INFO, INFO_SUPERWEAPON_LOST, self.netname);
				Send_Notification(NOTIF_ONE, self, MSG_CENTER, CENTER_SUPERWEAPON_LOST);
			}
			else if (self.items & IT_UNLIMITED_SUPERWEAPONS)
			{
				// don't let them run out
			}
			else
			{
				play_countdown(self.superweapons_finished, SND(POWEROFF));
				if (time > self.superweapons_finished)
				{
					self.items = self.items - (self.items & IT_SUPERWEAPON);
					self.weapons &= ~WEPSET_SUPERWEAPONS;
					//Send_Notification(NOTIF_ALL, world, MSG_INFO, INFO_SUPERWEAPON_BROKEN, self.netname);
					Send_Notification(NOTIF_ONE, self, MSG_CENTER, CENTER_SUPERWEAPON_BROKEN);
				}
			}
		}
		else if(self.weapons & WEPSET_SUPERWEAPONS)
		{
			if (time < self.superweapons_finished || (self.items & IT_UNLIMITED_SUPERWEAPONS))
			{
				self.items = self.items | IT_SUPERWEAPON;
				Send_Notification(NOTIF_ALL, world, MSG_INFO, INFO_SUPERWEAPON_PICKUP, self.netname);
				Send_Notification(NOTIF_ONE, self, MSG_CENTER, CENTER_SUPERWEAPON_PICKUP);
			}
			else
			{
				self.superweapons_finished = 0;
				self.weapons &= ~WEPSET_SUPERWEAPONS;
			}
		}
		else
		{
			self.superweapons_finished = 0;
		}
	}

	if(autocvar_g_nodepthtestplayers)
		self.effects = self.effects | EF_NODEPTHTEST;

	if(autocvar_g_fullbrightplayers)
		self.effects = self.effects | EF_FULLBRIGHT;

	if (time >= game_starttime)
	if (time < self.spawnshieldtime)
		self.effects = self.effects | (EF_ADDITIVE | EF_FULLBRIGHT);

	MUTATOR_CALLHOOK(PlayerPowerups, self, items_prev);
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

void player_regen ()
{SELFPARAM();
	float max_mod, regen_mod, rot_mod, limit_mod;
	max_mod = regen_mod = rot_mod = limit_mod = 1;
	regen_mod_max = max_mod;
	regen_mod_regen = regen_mod;
	regen_mod_rot = rot_mod;
	regen_mod_limit = limit_mod;

	regen_health = autocvar_g_balance_health_regen;
	regen_health_linear = autocvar_g_balance_health_regenlinear;
	regen_health_rot = autocvar_g_balance_health_rot;
	regen_health_rotlinear = autocvar_g_balance_health_rotlinear;
	regen_health_stable = autocvar_g_balance_health_regenstable;
	regen_health_rotstable = autocvar_g_balance_health_rotstable;
	if(!MUTATOR_CALLHOOK(PlayerRegen))
	if(!self.frozen)
	{
		float mina, maxa, limith, limita;
		maxa = autocvar_g_balance_armor_rotstable;
		mina = autocvar_g_balance_armor_regenstable;
		limith = autocvar_g_balance_health_limit;
		limita = autocvar_g_balance_armor_limit;

		max_mod = regen_mod_max;
		regen_mod = regen_mod_regen;
		rot_mod = regen_mod_rot;
		limit_mod = regen_mod_limit;

		regen_health_rotstable = regen_health_rotstable * max_mod;
		regen_health_stable = regen_health_stable * max_mod;
		limith = limith * limit_mod;
		limita = limita * limit_mod;

		self.armorvalue = CalcRotRegen(self.armorvalue, mina, autocvar_g_balance_armor_regen, autocvar_g_balance_armor_regenlinear, regen_mod * frametime * (time > self.pauseregen_finished), maxa, autocvar_g_balance_armor_rot, autocvar_g_balance_armor_rotlinear, rot_mod * frametime * (time > self.pauserotarmor_finished), limita);
		self.health = CalcRotRegen(self.health, regen_health_stable, regen_health, regen_health_linear, regen_mod * frametime * (time > self.pauseregen_finished), regen_health_rotstable, regen_health_rot, regen_health_rotlinear, rot_mod * frametime * (time > self.pauserothealth_finished), limith);
	}

	// if player rotted to death...  die!
	// check this outside above checks, as player may still be able to rot to death
	if(self.health < 1)
	{
		if(self.vehicle)
			vehicles_exit(VHEF_RELEASE);
		if(self.event_damage)
			self.event_damage(self, self, 1, DEATH_ROT.m_id, self.origin, '0 0 0');
	}

	if (!(self.items & IT_UNLIMITED_WEAPON_AMMO))
	{
		float minf, maxf, limitf;

		maxf = autocvar_g_balance_fuel_rotstable;
		minf = autocvar_g_balance_fuel_regenstable;
		limitf = autocvar_g_balance_fuel_limit;

		self.ammo_fuel = CalcRotRegen(self.ammo_fuel, minf, autocvar_g_balance_fuel_regen, autocvar_g_balance_fuel_regenlinear, frametime * (time > self.pauseregen_finished) * ((self.items & ITEM_JetpackRegen.m_itemid) != 0), maxf, autocvar_g_balance_fuel_rot, autocvar_g_balance_fuel_rotlinear, frametime * (time > self.pauserotfuel_finished), limitf);
	}
}

float zoomstate_set;
void SetZoomState(float z)
{SELFPARAM();
	if(z != self.zoomstate)
	{
		self.zoomstate = z;
		ClientData_Touch(self);
	}
	zoomstate_set = 1;
}

void GetPressedKeys()
{
	SELFPARAM();
	MUTATOR_CALLHOOK(GetPressedKeys);
	int keys = this.pressedkeys;
	keys = BITSET(keys, KEY_FORWARD, 	this.movement.x > 0);
	keys = BITSET(keys, KEY_BACKWARD, 	this.movement.x < 0);
	keys = BITSET(keys, KEY_RIGHT, 		this.movement.y > 0);
	keys = BITSET(keys, KEY_LEFT, 		this.movement.y < 0);

	keys = BITSET(keys, KEY_JUMP, 		PHYS_INPUT_BUTTON_JUMP(this));
	keys = BITSET(keys, KEY_CROUCH, 	PHYS_INPUT_BUTTON_CROUCH(this));
	keys = BITSET(keys, KEY_ATCK, 		PHYS_INPUT_BUTTON_ATCK(this));
	keys = BITSET(keys, KEY_ATCK2, 		PHYS_INPUT_BUTTON_ATCK2(this));
	this.pressedkeys = keys;
}

/*
======================
spectate mode routines
======================
*/

void SpectateCopy(entity this, entity spectatee)
{
	MUTATOR_CALLHOOK(SpectateCopy, spectatee, self);
	self.armortype = spectatee.armortype;
	self.armorvalue = spectatee.armorvalue;
	self.ammo_cells = spectatee.ammo_cells;
	self.ammo_plasma = spectatee.ammo_plasma;
	self.ammo_shells = spectatee.ammo_shells;
	self.ammo_nails = spectatee.ammo_nails;
	self.ammo_rockets = spectatee.ammo_rockets;
	self.ammo_fuel = spectatee.ammo_fuel;
	self.clip_load = spectatee.clip_load;
	self.clip_size = spectatee.clip_size;
	self.effects = spectatee.effects & EFMASK_CHEAP; // eat performance
	self.health = spectatee.health;
	self.impulse = 0;
	self.items = spectatee.items;
	self.last_pickup = spectatee.last_pickup;
	self.hit_time = spectatee.hit_time;
	self.strength_finished = spectatee.strength_finished;
	self.invincible_finished = spectatee.invincible_finished;
	self.pressedkeys = spectatee.pressedkeys;
	self.weapons = spectatee.weapons;
	PS(self).m_switchweapon = PS(spectatee).m_switchweapon;
	PS(self).m_switchingweapon = PS(spectatee).m_switchingweapon;
	PS(self).m_weapon = PS(spectatee).m_weapon;
	self.vortex_charge = spectatee.vortex_charge;
	self.vortex_chargepool_ammo = spectatee.vortex_chargepool_ammo;
	self.hagar_load = spectatee.hagar_load;
	self.arc_heat_percent = spectatee.arc_heat_percent;
	self.minelayer_mines = spectatee.minelayer_mines;
	self.punchangle = spectatee.punchangle;
	self.view_ofs = spectatee.view_ofs;
	self.velocity = spectatee.velocity;
	self.dmg_take = spectatee.dmg_take;
	self.dmg_save = spectatee.dmg_save;
	self.dmg_inflictor = spectatee.dmg_inflictor;
	self.v_angle = spectatee.v_angle;
	self.angles = spectatee.v_angle;
	self.frozen = spectatee.frozen;
	self.revive_progress = spectatee.revive_progress;
	if(!self.BUTTON_USE)
		self.fixangle = true;
	setorigin(self, spectatee.origin);
	setsize(self, spectatee.mins, spectatee.maxs);
	SetZoomState(spectatee.zoomstate);

    anticheat_spectatecopy(spectatee);
	self.hud = spectatee.hud;
	if(spectatee.vehicle)
    {
        self.fixangle = false;
        //self.velocity = spectatee.vehicle.velocity;
        self.vehicle_health = spectatee.vehicle_health;
        self.vehicle_shield = spectatee.vehicle_shield;
        self.vehicle_energy = spectatee.vehicle_energy;
        self.vehicle_ammo1 = spectatee.vehicle_ammo1;
        self.vehicle_ammo2 = spectatee.vehicle_ammo2;
        self.vehicle_reload1 = spectatee.vehicle_reload1;
        self.vehicle_reload2 = spectatee.vehicle_reload2;

        msg_entity = self;

        WriteByte (MSG_ONE, SVC_SETVIEWANGLES);
            WriteAngle(MSG_ONE,  spectatee.v_angle.x);
            WriteAngle(MSG_ONE,  spectatee.v_angle.y);
            WriteAngle(MSG_ONE,  spectatee.v_angle.z);

        //WriteByte (MSG_ONE, SVC_SETVIEW);
        //    WriteEntity(MSG_ONE, self);
        //makevectors(spectatee.v_angle);
        //setorigin(self, spectatee.origin - v_forward * 400 + v_up * 300);*/
    }
}

bool SpectateUpdate()
{SELFPARAM();
	if(!self.enemy)
	    return false;

	if(!IS_PLAYER(self.enemy) || self == self.enemy)
	{
		SetSpectatee(self, NULL);
		return false;
	}

	SpectateCopy(this, this.enemy);

	return true;
}

bool SpectateSet()
{SELFPARAM();
	if(!IS_PLAYER(self.enemy))
		return false;

	msg_entity = self;
	WriteByte(MSG_ONE, SVC_SETVIEW);
	WriteEntity(MSG_ONE, self.enemy);
	self.movetype = MOVETYPE_NONE;
	accuracy_resend(self);

	if(!SpectateUpdate())
		PutObserverInServer();

	return true;
}

void SetSpectatee(entity player, entity spectatee)
{
	entity old_spectatee = player.enemy;

	player.enemy = spectatee;

	// WEAPONTODO
	// these are required to fix the spectator bug with arc
	if(old_spectatee && old_spectatee.arc_beam) { old_spectatee.arc_beam.SendFlags |= ARC_SF_SETTINGS; }
	if(player.enemy && player.enemy.arc_beam) { player.enemy.arc_beam.SendFlags |= ARC_SF_SETTINGS; }
}

bool Spectate(entity pl)
{SELFPARAM();
	if(MUTATOR_CALLHOOK(SpectateSet, self, pl))
		return false;
	pl = spec_player;

	SetSpectatee(self, pl);
	return SpectateSet();
}

bool SpectateNext()
{SELFPARAM();
	other = find(self.enemy, classname, "player");

	if (MUTATOR_CALLHOOK(SpectateNext, self, other))
		other = spec_player;
	else if (!other)
		other = find(other, classname, "player");

	if(other) { SetSpectatee(self, other); }

	return SpectateSet();
}

bool SpectatePrev()
{SELFPARAM();
	// NOTE: chain order is from the highest to the lower entnum (unlike find)
	other = findchain(classname, "player");
	if (!other) // no player
		return false;

	entity first = other;
	// skip players until current spectated player
	if(self.enemy)
	while(other && other != self.enemy)
		other = other.chain;

	switch (MUTATOR_CALLHOOK(SpectatePrev, self, other, first))
	{
		case MUT_SPECPREV_FOUND:
		    other = spec_player;
		    break;
		case MUT_SPECPREV_RETURN:
		    other = spec_player;
		    return true;
		case MUT_SPECPREV_CONTINUE:
		default:
		{
			if(other.chain)
				other = other.chain;
			else
				other = first;
			break;
		}
	}

	SetSpectatee(self, other);
	return SpectateSet();
}

/*
=============
ShowRespawnCountdown()

Update a respawn countdown display.
=============
*/
void ShowRespawnCountdown()
{SELFPARAM();
	float number;
	if(self.deadflag == DEAD_NO) // just respawned?
		return;
	else
	{
		number = ceil(self.respawn_time - time);
		if(number <= 0)
			return;
		if(number <= self.respawn_countdown)
		{
			self.respawn_countdown = number - 1;
			if(ceil(self.respawn_time - (time + 0.5)) == number) // only say it if it is the same number even in 0.5s; to prevent overlapping sounds
				{ Send_Notification(NOTIF_ONE, self, MSG_ANNCE, Announcer_PickNumber(CNT_RESPAWN, number)); }
		}
	}
}

void LeaveSpectatorMode()
{SELFPARAM();
	if(self.caplayer)
		return;
	if(nJoinAllowed(self))
	{
		if(!teamplay || autocvar_g_campaign || autocvar_g_balance_teams || (self.wasplayer && autocvar_g_changeteam_banned) || self.team_forced > 0)
		{
			self.classname = STR_PLAYER;

			if(autocvar_g_campaign || autocvar_g_balance_teams)
				{ JoinBestTeam(self, false, true); }

			if(autocvar_g_campaign)
				{ campaign_bots_may_start = 1; }

			Kill_Notification(NOTIF_ONE_ONLY, self, MSG_CENTER_CPID, CPID_PREVENT_JOIN);

			PutClientInServer();

			if(IS_PLAYER(self)) { Send_Notification(NOTIF_ALL, world, MSG_INFO, INFO_JOIN_PLAY, self.netname); }
		}
		else
			stuffcmd(self, "menu_showteamselect\n");
	}
	else
	{
		// Player may not join because g_maxplayers is set
		Send_Notification(NOTIF_ONE_ONLY, self, MSG_CENTER, CENTER_JOIN_PREVENT);
	}
}

/**
 * Determines whether the player is allowed to join. This depends on cvar
 * g_maxplayers, if it isn't used this function always return true, otherwise
 * it checks whether the number of currently playing players exceeds g_maxplayers.
 * @return int number of free slots for players, 0 if none
 */
float nJoinAllowed(entity ignore)
{SELFPARAM();
	if(!ignore)
	// this is called that way when checking if anyone may be able to join (to build qcstatus)
	// so report 0 free slots if restricted
	{
		if(autocvar_g_forced_team_otherwise == "spectate")
			return 0;
		if(autocvar_g_forced_team_otherwise == "spectator")
			return 0;
	}

	if(self.team_forced < 0)
		return 0; // forced spectators can never join

	// TODO simplify this
	entity e;
	float totalClients = 0;
	FOR_EACH_CLIENT(e)
		if(e != ignore)
			totalClients += 1;

	if (!autocvar_g_maxplayers)
		return maxclients - totalClients;

	float currentlyPlaying = 0;
	FOR_EACH_REALCLIENT(e)
		if(IS_PLAYER(e) || e.caplayer)
			currentlyPlaying += 1;

	if(currentlyPlaying < autocvar_g_maxplayers)
		return min(maxclients - totalClients, autocvar_g_maxplayers - currentlyPlaying);

	return 0;
}

/**
 * Checks whether the client is an observer or spectator, if so, he will get kicked after
 * g_maxplayers_spectator_blocktime seconds
 */
void checkSpectatorBlock()
{SELFPARAM();
	if(IS_SPEC(self) || IS_OBSERVER(self))
	if(!self.caplayer)
	if(IS_REAL_CLIENT(self))
	{
		if( time > (self.spectatortime + autocvar_g_maxplayers_spectator_blocktime) ) {
			Send_Notification(NOTIF_ONE_ONLY, self, MSG_INFO, INFO_QUIT_KICK_SPECTATING);
			dropclient(self);
		}
	}
}

void PrintWelcomeMessage()
{SELFPARAM();
	if(self.motd_actived_time == 0)
	{
		if (autocvar_g_campaign) {
			if ((IS_PLAYER(self) && self.BUTTON_INFO) || (!IS_PLAYER(self))) {
				self.motd_actived_time = time;
				Send_Notification(NOTIF_ONE_ONLY, self, MSG_CENTER, CENTER_MOTD, campaign_message);
			}
		} else {
			if (self.BUTTON_INFO) {
				self.motd_actived_time = time;
				Send_Notification(NOTIF_ONE_ONLY, self, MSG_CENTER, CENTER_MOTD, getwelcomemessage());
			}
		}
	}
	else if(self.motd_actived_time > 0) // showing MOTD or campaign message
	{
		if (autocvar_g_campaign) {
			if (self.BUTTON_INFO)
				self.motd_actived_time = time;
			else if ((time - self.motd_actived_time > 2) && IS_PLAYER(self)) { // hide it some seconds after BUTTON_INFO has been released
				self.motd_actived_time = 0;
				Kill_Notification(NOTIF_ONE_ONLY, self, MSG_CENTER_CPID, CPID_MOTD);
			}
		} else {
			if (self.BUTTON_INFO)
				self.motd_actived_time = time;
			else if (time - self.motd_actived_time > 2) { // hide it some seconds after BUTTON_INFO has been released
				self.motd_actived_time = 0;
				Kill_Notification(NOTIF_ONE_ONLY, self, MSG_CENTER_CPID, CPID_MOTD);
			}
		}
	}
	else //if(self.motd_actived_time < 0) // just connected, motd is active
	{
		if(self.BUTTON_INFO) // BUTTON_INFO hides initial MOTD
			self.motd_actived_time = -2; // wait until BUTTON_INFO gets released
		else if(self.motd_actived_time == -2 || IS_PLAYER(self) || IS_SPEC(self))
		{
			// instanctly hide MOTD
			self.motd_actived_time = 0;
			Kill_Notification(NOTIF_ONE_ONLY, self, MSG_CENTER_CPID, CPID_MOTD);
		}
	}
}

void ObserverThink()
{SELFPARAM();
	if ( self.impulse )
	{
		MinigameImpulse(self, self.impulse);
		self.impulse = 0;
	}
	float prefered_movetype;
	if (self.flags & FL_JUMPRELEASED) {
		if (self.BUTTON_JUMP && !self.version_mismatch) {
			self.flags &= ~FL_JUMPRELEASED;
			self.flags |= FL_SPAWNING;
		} else if(self.BUTTON_ATCK && !self.version_mismatch) {
			self.flags &= ~FL_JUMPRELEASED;
			if(SpectateNext()) {
				self.classname = STR_SPECTATOR;
			}
		} else {
			prefered_movetype = ((!self.BUTTON_USE ? self.cvar_cl_clippedspectating : !self.cvar_cl_clippedspectating) ? MOVETYPE_FLY_WORLDONLY : MOVETYPE_NOCLIP);
			if (self.movetype != prefered_movetype)
				self.movetype = prefered_movetype;
		}
	} else {
		if (!(self.BUTTON_ATCK || self.BUTTON_JUMP)) {
			self.flags |= FL_JUMPRELEASED;
			if(self.flags & FL_SPAWNING)
			{
				self.flags &= ~FL_SPAWNING;
				LeaveSpectatorMode();
				return;
			}
		}
	}
}

void SpectatorThink()
{SELFPARAM();
	if ( self.impulse )
	{
		if(MinigameImpulse(self, self.impulse))
			self.impulse = 0;
	}
	if (self.flags & FL_JUMPRELEASED) {
		if (self.BUTTON_JUMP && !self.version_mismatch) {
			self.flags &= ~FL_JUMPRELEASED;
			self.flags |= FL_SPAWNING;
		} else if(self.BUTTON_ATCK || self.impulse == 10 || self.impulse == 15 || self.impulse == 18 || (self.impulse >= 200 && self.impulse <= 209)) {
			self.flags &= ~FL_JUMPRELEASED;
			if(SpectateNext()) {
				self.classname = STR_SPECTATOR;
			} else {
				self.classname = STR_OBSERVER;
				PutClientInServer();
			}
			self.impulse = 0;
		} else if(self.impulse == 12 || self.impulse == 16  || self.impulse == 19 || (self.impulse >= 220 && self.impulse <= 229)) {
			self.flags &= ~FL_JUMPRELEASED;
			if(SpectatePrev()) {
				self.classname = STR_SPECTATOR;
			} else {
				self.classname = STR_OBSERVER;
				PutClientInServer();
			}
			self.impulse = 0;
		} else if (self.BUTTON_ATCK2) {
			self.flags &= ~FL_JUMPRELEASED;
			self.classname = STR_OBSERVER;
			PutClientInServer();
		} else {
			if(!SpectateUpdate())
				PutObserverInServer();
		}
	} else {
		if (!(self.BUTTON_ATCK || self.BUTTON_ATCK2)) {
			self.flags |= FL_JUMPRELEASED;
			if(self.flags & FL_SPAWNING)
			{
				self.flags &= ~FL_SPAWNING;
				LeaveSpectatorMode();
				return;
			}
		}
		if(!SpectateUpdate())
			PutObserverInServer();
	}

	self.flags |= FL_CLIENT | FL_NOTARGET;
}

void vehicles_enter (entity pl, entity veh);
void PlayerUseKey()
{SELFPARAM();
	if (!IS_PLAYER(self))
		return;

	if(self.vehicle)
	{
		if(!gameover)
		{
			vehicles_exit(VHEF_NORMAL);
			return;
		}
	}
	else if(autocvar_g_vehicles_enter)
	{
		if(!self.frozen)
		if(self.deadflag == DEAD_NO)
		if(!gameover)
		{
			entity head, closest_target = world;
			head = WarpZone_FindRadius(self.origin, autocvar_g_vehicles_enter_radius, TRUE);

			while(head) // find the closest acceptable target to enter
			{
				if(head.vehicle_flags & VHF_ISVEHICLE)
				if(head.deadflag == DEAD_NO)
				if(!head.owner || ((head.vehicle_flags & VHF_MULTISLOT) && SAME_TEAM(head.owner, self)))
				if(head.takedamage != DAMAGE_NO)
				{
					if(closest_target)
					{
						if(vlen(self.origin - head.origin) < vlen(self.origin - closest_target.origin))
						{ closest_target = head; }
					}
					else { closest_target = head; }
				}

				head = head.chain;
			}

			if(closest_target) { vehicles_enter(self, closest_target); return; }
		}
	}

	// a use key was pressed; call handlers
	MUTATOR_CALLHOOK(PlayerUseKey);
}


/*
=============
PlayerPreThink

Called every frame for each client before the physics are run
=============
*/
.float usekeypressed;
void() nexball_setstatus;
.float last_vehiclecheck;
.int items_added;
void PlayerPreThink ()
{SELFPARAM();
	WarpZone_PlayerPhysics_FixVAngle();

	self.stat_game_starttime = game_starttime;
	self.stat_round_starttime = round_starttime;
	self.stat_allow_oldvortexbeam = autocvar_g_allow_oldvortexbeam;
	self.stat_leadlimit = autocvar_leadlimit;

	self.weaponsinmap = weaponsInMap;

	if(frametime)
	{
		// physics frames: update anticheat stuff
		anticheat_prethink();
	}

	if(blockSpectators && frametime)
		// WORKAROUND: only use dropclient in server frames (frametime set). Never use it in cl_movement frames (frametime zero).
		checkSpectatorBlock();

	zoomstate_set = 0;

	// Savage: Check for nameless players
	if (isInvisibleString(self.netname)) {
		string new_name = strzone(strcat("Player@", ftos(self.playerid)));
		if(autocvar_sv_eventlog)
			GameLogEcho(strcat(":name:", ftos(self.playerid), ":", new_name));
		if(self.netname_previous)
			strunzone(self.netname_previous);
		self.netname_previous = strzone(new_name);
		self.netname = self.netname_previous;
		// stuffcmd(self, strcat("name ", self.netname, "\n"));
	} else if(self.netname_previous != self.netname) {
		if(autocvar_sv_eventlog)
			GameLogEcho(strcat(":name:", ftos(self.playerid), ":", self.netname));
		if(self.netname_previous)
			strunzone(self.netname_previous);
		self.netname_previous = strzone(self.netname);
	}

	// version nagging
	if(self.version_nagtime)
		if(self.cvar_g_xonoticversion)
			if(time > self.version_nagtime)
			{
				// don't notify git users
				if(strstr(self.cvar_g_xonoticversion, "git", 0) < 0 && strstr(self.cvar_g_xonoticversion, "autobuild", 0) < 0)
				{
					if(strstr(autocvar_g_xonoticversion, "git", 0) >= 0 || strstr(autocvar_g_xonoticversion, "autobuild", 0) >= 0)
					{
						// notify release users if connecting to git
						LOG_TRACE("^1NOTE^7 to ", self.netname, "^7 - the server is running ^3Xonotic ", autocvar_g_xonoticversion, " (beta)^7, you have ^3Xonotic ", self.cvar_g_xonoticversion, "^1\n");
						Send_Notification(NOTIF_ONE_ONLY, self, MSG_INFO, INFO_VERSION_BETA, autocvar_g_xonoticversion, self.cvar_g_xonoticversion);
					}
					else
					{
						float r;
						r = vercmp(self.cvar_g_xonoticversion, autocvar_g_xonoticversion);
						if(r < 0)
						{
							// give users new version
							LOG_TRACE("^1NOTE^7 to ", self.netname, "^7 - ^3Xonotic ", autocvar_g_xonoticversion, "^7 is out, and you still have ^3Xonotic ", self.cvar_g_xonoticversion, "^1 - get the update from ^4http://www.xonotic.org/^1!\n");
							Send_Notification(NOTIF_ONE_ONLY, self, MSG_INFO, INFO_VERSION_OUTDATED, autocvar_g_xonoticversion, self.cvar_g_xonoticversion);
						}
						else if(r > 0)
						{
							// notify users about old server version
							LOG_INFO("^1NOTE^7 to ", self.netname, "^7 - the server is running ^3Xonotic ", autocvar_g_xonoticversion, "^7, you have ^3Xonotic ", self.cvar_g_xonoticversion, "^1\n");
							Send_Notification(NOTIF_ONE_ONLY, self, MSG_INFO, INFO_VERSION_OLD, autocvar_g_xonoticversion, self.cvar_g_xonoticversion);
						}
					}
				}
				self.version_nagtime = 0;
			}

	// GOD MODE info
	if(!(self.flags & FL_GODMODE)) if(self.max_armorvalue)
	{
		Send_Notification(NOTIF_ONE_ONLY, self, MSG_INFO, INFO_GODMODE_OFF, self.max_armorvalue);
		self.max_armorvalue = 0;
	}

	if(self.frozen == 2)
	{
		self.revive_progress = bound(0, self.revive_progress + frametime * self.revive_speed, 1);
		self.health = max(1, self.revive_progress * start_health);
		self.iceblock.alpha = bound(0.2, 1 - self.revive_progress, 1);

		if(self.revive_progress >= 1)
			Unfreeze(self);
	}
	else if(self.frozen == 3)
	{
		self.revive_progress = bound(0, self.revive_progress - frametime * self.revive_speed, 1);
		self.health = max(0, autocvar_g_nades_ice_health + (start_health-autocvar_g_nades_ice_health) * self.revive_progress );

		if(self.health < 1)
		{
			if(self.vehicle)
				vehicles_exit(VHEF_RELEASE);
			self.event_damage(self, self.frozen_by, 1, DEATH_NADE_ICE_FREEZE.m_id, self.origin, '0 0 0');
		}
		else if ( self.revive_progress <= 0 )
			Unfreeze(self);
	}

	MUTATOR_CALLHOOK(PlayerPreThink);

	if(autocvar_g_vehicles_enter)
	if(time > self.last_vehiclecheck)
	if(IS_PLAYER(self))
	if(!gameover)
	if(!self.frozen)
	if(!self.vehicle)
	if(self.deadflag == DEAD_NO)
	{
		entity veh;
		for(veh = world; (veh = findflags(veh, vehicle_flags, VHF_ISVEHICLE)); )
		if(vlen(veh.origin - self.origin) < autocvar_g_vehicles_enter_radius)
		if(veh.deadflag == DEAD_NO)
		if(veh.takedamage != DAMAGE_NO)
		if((veh.vehicle_flags & VHF_MULTISLOT) && SAME_TEAM(veh.owner, self))
			Send_Notification(NOTIF_ONE, self, MSG_CENTER, CENTER_VEHICLE_ENTER_GUNNER);
		else if(!veh.owner)
		if(!veh.team || SAME_TEAM(self, veh))
			Send_Notification(NOTIF_ONE, self, MSG_CENTER, CENTER_VEHICLE_ENTER);
		else if(autocvar_g_vehicles_steal)
			Send_Notification(NOTIF_ONE, self, MSG_CENTER, CENTER_VEHICLE_ENTER_STEAL);

		self.last_vehiclecheck = time + 1;
	}

	if(!self.cvar_cl_newusekeysupported) // FIXME remove this - it was a stupid idea to begin with, we can JUST use the button
	{
		if(self.BUTTON_USE && !self.usekeypressed)
			PlayerUseKey();
		self.usekeypressed = self.BUTTON_USE;
	}

	if(IS_REAL_CLIENT(self))
		PrintWelcomeMessage();

	if(IS_PLAYER(self))
	{

		CheckRules_Player();

		if (intermission_running)
		{
			IntermissionThink ();	// otherwise a button could be missed between
			return;					// the think tics
		}

		//don't allow the player to turn around while game is paused!
		if(timeout_status == TIMEOUT_ACTIVE) {
			// FIXME turn this into CSQC stuff
			self.v_angle = self.lastV_angle;
			self.angles = self.lastV_angle;
			self.fixangle = true;
		}

		if(frametime)
		{
			player_powerups();
		}

		if (self.deadflag != DEAD_NO)
		{
			if(self.personal && g_race_qualifying)
			{
				if(time > self.respawn_time)
				{
					self.respawn_time = time + 1; // only retry once a second
					self.stat_respawn_time = self.respawn_time;
					respawn();
					self.impulse = 141;
				}
			}
			else
			{
				float button_pressed;
				if(frametime)
					player_anim();
				button_pressed = (self.BUTTON_ATCK || self.BUTTON_JUMP || self.BUTTON_ATCK2 || self.BUTTON_HOOK || self.BUTTON_USE);

				if (self.deadflag == DEAD_DYING)
				{
					if((self.respawn_flags & RESPAWN_FORCE) && !autocvar_g_respawn_delay_max)
						self.deadflag = DEAD_RESPAWNING;
					else if(!button_pressed)
						self.deadflag = DEAD_DEAD;
				}
				else if (self.deadflag == DEAD_DEAD)
				{
					if(button_pressed)
						self.deadflag = DEAD_RESPAWNABLE;
					else if(time >= self.respawn_time_max && (self.respawn_flags & RESPAWN_FORCE))
						self.deadflag = DEAD_RESPAWNING;
				}
				else if (self.deadflag == DEAD_RESPAWNABLE)
				{
					if(!button_pressed)
						self.deadflag = DEAD_RESPAWNING;
				}
				else if (self.deadflag == DEAD_RESPAWNING)
				{
					if(time > self.respawn_time)
					{
						self.respawn_time = time + 1; // only retry once a second
						self.respawn_time_max = self.respawn_time;
						respawn();
					}
				}

				ShowRespawnCountdown();

				if(self.respawn_flags & RESPAWN_SILENT)
					self.stat_respawn_time = 0;
				else if((self.respawn_flags & RESPAWN_FORCE) && autocvar_g_respawn_delay_max)
					self.stat_respawn_time = self.respawn_time_max;
				else
					self.stat_respawn_time = self.respawn_time;
			}

			// if respawning, invert stat_respawn_time to indicate this, the client translates it
			if(self.deadflag == DEAD_RESPAWNING && self.stat_respawn_time > 0)
				self.stat_respawn_time *= -1;

			return;
		}

		self.prevorigin = self.origin;

		float do_crouch = self.BUTTON_CROUCH;
		if(self.hook.state)
			do_crouch = 0;
		if(self.vehicle)
			do_crouch = 0;
		if(self.frozen)
			do_crouch = 0;

		// WEAPONTODO: THIS SHIT NEEDS TO GO EVENTUALLY
		// It cannot be predicted by the engine!
		.entity weaponentity = weaponentities[0]; // TODO: unhardcode
		if((PS(self).m_weapon == WEP_SHOCKWAVE || PS(self).m_weapon == WEP_SHOTGUN) && self.(weaponentity).wframe == WFRAME_FIRE2 && time < self.(weaponentity).weapon_nextthink)
			do_crouch = 0;

		if (do_crouch)
		{
			if (!self.crouch)
			{
				self.crouch = true;
				self.view_ofs = STAT(PL_CROUCH_VIEW_OFS, self);
				setsize (self, STAT(PL_CROUCH_MIN, self), STAT(PL_CROUCH_MAX, self));
				// setanim(self, self.anim_duck, false, true, true); // this anim is BROKEN anyway
			}
		}
		else
		{
			if (self.crouch)
			{
				tracebox(self.origin, STAT(PL_MIN, self), STAT(PL_MAX, self), self.origin, false, self);
				if (!trace_startsolid)
				{
					self.crouch = false;
					self.view_ofs = STAT(PL_VIEW_OFS, self);
					setsize (self, STAT(PL_MIN, self), STAT(PL_MAX, self));
				}
			}
		}

		FixPlayermodel(self);

		// LordHavoc: allow firing on move frames (sub-ticrate), this gives better timing on slow servers
		//if(frametime)
		{
			self.items &= ~self.items_added;

			W_WeaponFrame(self);

			self.items_added = 0;
			if(self.items & ITEM_Jetpack.m_itemid)
				if(self.items & ITEM_JetpackRegen.m_itemid || self.ammo_fuel >= 0.01)
					self.items_added |= IT_FUEL;

			self.items |= self.items_added;
		}

		player_regen();

		// WEAPONTODO: Add a weapon request for this
		// rot vortex charge to the charge limit
		if(WEP_CVAR(vortex, charge_rot_rate) && self.vortex_charge > WEP_CVAR(vortex, charge_limit) && self.vortex_charge_rottime < time)
			self.vortex_charge = bound(WEP_CVAR(vortex, charge_limit), self.vortex_charge - WEP_CVAR(vortex, charge_rot_rate) * frametime / W_TICSPERFRAME, 1);

		if(frametime)
			player_anim();

		// secret status
		secrets_setstatus();

		// monsters status
		monsters_setstatus();

		self.dmg_team = max(0, self.dmg_team - autocvar_g_teamdamage_resetspeed * frametime);

		//self.angles_y=self.v_angle_y + 90;   // temp
	} else if(gameover) {
		if (intermission_running)
			IntermissionThink ();	// otherwise a button could be missed between
		return;
	} else if(IS_OBSERVER(self)) {
		ObserverThink();
	} else if(IS_SPEC(self)) {
		SpectatorThink();
	}

	// WEAPONTODO: Add weapon request for this
	if(!zoomstate_set)
		SetZoomState(
			self.BUTTON_ZOOM
			|| self.BUTTON_ZOOMSCRIPT
			|| (self.BUTTON_ATCK2 && PS(self).m_weapon == WEP_VORTEX)
			|| (self.BUTTON_ATCK2 && PS(self).m_weapon == WEP_RIFLE && WEP_CVAR(rifle, secondary) == 0)
		); // WEAPONTODO

	float oldspectatee_status;
	oldspectatee_status = self.spectatee_status;
	if(IS_SPEC(self))
		self.spectatee_status = etof(self.enemy);
	else if(IS_OBSERVER(self))
		self.spectatee_status = etof(self);
	else
		self.spectatee_status = 0;
	if(self.spectatee_status != oldspectatee_status)
	{
		ClientData_Touch(self);
		if(g_race || g_cts)
			race_InitSpectator();
	}

	if(self.teamkill_soundtime)
	if(time > self.teamkill_soundtime)
	{
		self.teamkill_soundtime = 0;

		entity e = self.teamkill_soundsource;
		entity oldpusher = e.pusher;
		e.pusher = this;
		PlayerSound(e, playersound_teamshoot, CH_VOICE, VOICETYPE_LASTATTACKER_ONLY);
		e.pusher = oldpusher;
	}

	if(self.taunt_soundtime)
	if(time > self.taunt_soundtime)
	{
		self.taunt_soundtime = 0;
		PlayerSound(self, playersound_taunt, CH_VOICE, VOICETYPE_AUTOTAUNT);
	}

	target_voicescript_next(self);

	// WEAPONTODO: Move into weaponsystem somehow
	// if a player goes unarmed after holding a loaded weapon, empty his clip size and remove the crosshair ammo ring
	if (PS(self).m_weapon == WEP_Null)
		self.clip_load = self.clip_size = 0;
}

void DrownPlayer(entity this)
{
	if(this.deadflag != DEAD_NO)
		return;

	if (this.waterlevel != WATERLEVEL_SUBMERGED)
	{
		if(this.air_finished < time)
			PlayerSound(this, playersound_gasp, CH_PLAYER, VOICETYPE_PLAYERSOUND);
		this.air_finished = time + autocvar_g_balance_contents_drowndelay;
		this.dmg = 2;
	}
	else if (this.air_finished < time)
	{	// drown!
		if (this.pain_finished < time)
		{
			Damage (this, world, world, autocvar_g_balance_contents_playerdamage_drowning * autocvar_g_balance_contents_damagerate, DEATH_DROWN.m_id, this.origin, '0 0 0');
			this.pain_finished = time + 0.5;
		}
	}
}

/*
=============
PlayerPostThink

Called every frame for each client after the physics are run
=============
*/
.float idlekick_lasttimeleft;
void PlayerPostThink ()
{SELFPARAM();
	if(sv_maxidle > 0 && frametime) // WORKAROUND: only use dropclient in server frames (frametime set). Never use it in cl_movement frames (frametime zero).
	if(IS_REAL_CLIENT(self))
	if(IS_PLAYER(self) || sv_maxidle_spectatorsareidle)
	{
		if (time - self.parm_idlesince < 1) // instead of (time == self.parm_idlesince) to support sv_maxidle <= 10
		{
			if(self.idlekick_lasttimeleft)
			{
				self.idlekick_lasttimeleft = 0;
				Kill_Notification(NOTIF_ONE_ONLY, self, MSG_CENTER_CPID, CPID_IDLING);
			}
		}
		else
		{
			float timeleft;
			timeleft = ceil(sv_maxidle - (time - self.parm_idlesince));
			if(timeleft == min(10, sv_maxidle - 1)) // - 1 to support sv_maxidle <= 10
			{
				if(!self.idlekick_lasttimeleft)
					Send_Notification(NOTIF_ONE_ONLY, self, MSG_CENTER, CENTER_DISCONNECT_IDLING, timeleft);
			}
			if(timeleft <= 0)
			{
				Send_Notification(NOTIF_ALL, world, MSG_INFO, INFO_QUIT_KICK_IDLING, self.netname);
				dropclient(self);
				return;
			}
			else if(timeleft <= 10)
			{
				if(timeleft != self.idlekick_lasttimeleft)
					{ Send_Notification(NOTIF_ONE, self, MSG_ANNCE, Announcer_PickNumber(CNT_IDLE, timeleft)); }
				self.idlekick_lasttimeleft = timeleft;
			}
		}
	}

	CheatFrame();

	//CheckPlayerJump();

	if(IS_PLAYER(self)) {
		DrownPlayer(self);
		CheckRules_Player();
		UpdateChatBubble();
		if (self.impulse)
			ImpulseCommands(self);
		if (intermission_running)
			return;		// intermission or finale
		GetPressedKeys();
	}

	/*
	float i;
	for(i = 0; i < 1000; ++i)
	{
		vector end;
		end = self.origin + '0 0 1024' + 512 * randomvec();
		tracebox(self.origin, self.mins, self.maxs, end, MOVE_NORMAL, self);
		if(trace_fraction < 1)
		if(!(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT))
		{
			print("I HIT SOLID: ", vtos(self.origin), " -> ", vtos(end), "\n");
			break;
		}
	}
	*/

	if(self.waypointsprite_attachedforcarrier)
		WaypointSprite_UpdateHealth(self.waypointsprite_attachedforcarrier, '1 0 0' * healtharmor_maxdamage(self.health, self.armorvalue, autocvar_g_balance_armor_blockpercent, DEATH_WEAPON.m_id));

	playerdemo_write();

	CSQCMODEL_AUTOUPDATE(self);
}
