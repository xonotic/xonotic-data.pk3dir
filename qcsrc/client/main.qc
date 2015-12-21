#include "main.qh"

#include "../common/effects/qc/all.qh"
#include "hook.qh"
#include "hud/all.qh"
#include "mapvoting.qh"
#include "mutators/events.qh"
#include "quickmenu.qh"
#include "scoreboard.qh"
#include "shownames.qh"
#include "tuba.qh"
#include "t_items.qh"
#include "wall.qh"
#include "weapons/projectile.qh"
#include "../common/deathtypes/all.qh"
#include "../common/items/all.qh"
#include "../common/mapinfo.qh"
#include "../common/minigames/cl_minigames.qh"
#include "../common/minigames/cl_minigames_hud.qh"
#include "../common/net_notice.qh"
#include "../common/triggers/include.qh"
#include "../common/vehicles/all.qh"
#include "../lib/csqcmodel/cl_model.qh"
#include "../lib/csqcmodel/interpolate.qh"
#include "../lib/warpzone/client.qh"

// --------------------------------------------------------------------------
// BEGIN REQUIRED CSQC FUNCTIONS
//include "main.qh"

#define DP_CSQC_ENTITY_REMOVE_IS_B0RKED

// CSQC_Init : Called every time the CSQC code is initialized (essentially at map load)
// Useful for precaching things

void ConsoleCommand_macro_init();
void CSQC_Init()
{
	prvm_language = strzone(cvar_string("prvm_language"));

#ifdef WATERMARK
	LOG_INFOF("^4CSQC Build information: ^1%s\n", WATERMARK);
#endif

	{
		int i = 0;
		for ( ; i < 255; ++i)
			if (getplayerkeyvalue(i, "viewentity") == "")
				break;
		maxclients = i;
	}

	// needs to be done so early because of the constants they create
	static_init();
	static_init_late();
	static_init_precache();

	binddb = db_create();
	tempdb = db_create();
	ClientProgsDB = db_load("client.db");
	compressShortVector_init();

	draw_endBoldFont();

	//registercommand("hud_configure");
	//registercommand("hud_save");
	//registercommand("menu_action");

	ConsoleCommand_macro_init();

	registercvar("hud_usecsqc", "1");
	registercvar("scoreboard_columns", "default");

	registercvar("cl_nade_type", "3");
	registercvar("cl_pokenade_type", "zombie");

	registercvar("cl_jumpspeedcap_min", "");
	registercvar("cl_jumpspeedcap_max", "");

	registercvar("cl_multijump", "0");

	registercvar("cl_spawn_near_teammate", "1");

	gametype = 0;

	// hud_fields uses strunzone on the titles!
	for(int i = 0; i < MAX_HUD_FIELDS; ++i)
		hud_title[i] = strzone("(null)");

	Cmd_HUD_SetFields(0);

	postinit = false;

	calledhooks = 0;

	teams = Sort_Spawn();
	players = Sort_Spawn();

	GetTeam(NUM_SPECTATOR, true); // add specs first

	// precaches

	if(autocvar_cl_reticle)
	{
		precache_pic("gfx/reticle_normal");
		// weapon reticles are precached in weapon files
	}

	{
		get_mi_min_max_texcoords(1); // try the CLEVER way first
		minimapname = strcat("gfx/", mi_shortname, "_radar.tga");
		shortmapname = mi_shortname;

		if (precache_pic(minimapname) == "")
		{
			// but maybe we have a non-clever minimap
			minimapname = strcat("gfx/", mi_shortname, "_mini.tga");
			if (precache_pic(minimapname) == "")
				minimapname = ""; // FAIL
			else
				get_mi_min_max_texcoords(0); // load new texcoords
		}

		mi_center = (mi_min + mi_max) * 0.5;
		mi_scale = mi_max - mi_min;
		minimapname = strzone(minimapname);
	}

	hud_skin_path = strzone(strcat("gfx/hud/", autocvar_hud_skin));
	draw_currentSkin = strzone(strcat("gfx/menu/", cvar_string("menu_skin")));
}

// CSQC_Shutdown : Called every time the CSQC code is shutdown (changing maps, quitting, etc)
void Shutdown()
{
	WarpZone_Shutdown();

	remove(teams);
	remove(players);
	db_close(binddb);
	db_close(tempdb);
	if(autocvar_cl_db_saveasdump)
		db_dump(ClientProgsDB, "client.db");
	else
		db_save(ClientProgsDB, "client.db");
	db_close(ClientProgsDB);

	if(camera_active)
		cvar_set("chase_active",ftos(chase_active_backup));

	// unset the event chasecam's chase_active
	if(autocvar_chase_active < 0)
		cvar_set("chase_active", "0");

	if (!isdemo())
	{
		if (!(calledhooks & HOOK_START))
			localcmd("\n_cl_hook_gamestart nop\n");
		if (!(calledhooks & HOOK_END))
			localcmd("\ncl_hook_gameend\n");
	}

	deactivate_minigame();
	HUD_MinigameMenu_Close();
}

.float has_team;
float SetTeam(entity o, int Team)
{
	devassert_once(Team);
	entity tm;
	if(teamplay)
	{
		switch(Team)
		{
			case -1:
			case NUM_TEAM_1:
			case NUM_TEAM_2:
			case NUM_TEAM_3:
			case NUM_TEAM_4:
				break;
			default:
				if(GetTeam(Team, false) == world)
				{
					LOG_TRACEF("trying to switch to unsupported team %d\n", Team);
					Team = NUM_SPECTATOR;
				}
				break;
		}
	}
	else
	{
		switch(Team)
		{
			case -1:
			case 0:
				break;
			default:
				if(GetTeam(Team, false) == world)
				{
					LOG_TRACEF("trying to switch to unsupported team %d\n", Team);
					Team = NUM_SPECTATOR;
				}
				break;
		}
	}
	if(Team == -1) // leave
	{
		if(o.has_team)
		{
			tm = GetTeam(o.team, false);
			tm.team_size -= 1;
			o.has_team = 0;
			return true;
		}
	}
	else
	{
		if (!o.has_team)
		{
			o.team = Team;
			tm = GetTeam(Team, true);
			tm.team_size += 1;
			o.has_team = 1;
			return true;
		}
		else if(Team != o.team)
		{
			tm = GetTeam(o.team, false);
			tm.team_size -= 1;
			o.team = Team;
			tm = GetTeam(Team, true);
			tm.team_size += 1;
			return true;
		}
	}
	return false;
}

void Playerchecker_Think()
{
	SELFPARAM();
    int i;
	entity e;
	for(i = 0; i < maxclients; ++i)
	{
		e = playerslots[i];
		if(entcs_GetName(i) == "")
		{
			if(e.sort_prev)
			{
				// player disconnected
				SetTeam(e, -1);
				RemovePlayer(e);
				e.sort_prev = world;
				//e.gotscores = 0;
			}
		}
		else
		{
			if (!e.sort_prev)
			{
				// player connected
				if (!e)
				{
					playerslots[i] = e = new(playerslot);
					make_pure(e);
				}
				e.sv_entnum = i;
				e.ping = 0;
				e.ping_packetloss = 0;
				e.ping_movementloss = 0;
				//e.gotscores = 0; // we might already have the scores...
				int t = entcs_GetScoreTeam(i);
				if (t) SetTeam(e, t); // will not hurt; later updates come with HUD_UpdatePlayerTeams
				RegisterPlayer(e);
				HUD_UpdatePlayerPos(e);
			}
		}
	}
	this.nextthink = time + 0.2;
}

void Porto_Init();
void TrueAim_Init();
void PostInit()
{
	entity playerchecker = new(playerchecker);
	make_pure(playerchecker);
	playerchecker.think = Playerchecker_Think;
	playerchecker.nextthink = time + 0.2;

	Porto_Init();
	TrueAim_Init();

	postinit = true;
}

// CSQC_InputEvent : Used to perform actions based on any key pressed, key released and mouse on the client.
// Return value should be 1 if CSQC handled the input, otherwise return 0 to have the input passed to the engine.
// All keys are in ascii.
// bInputType = 0 is key pressed, 1 is key released, 2 and 3 are mouse input.
// In the case of keyboard input, nPrimary is the ascii code, and nSecondary is 0.
// In the case of mouse input, nPrimary is xdelta, nSecondary is ydelta.
// In the case of mouse input after a setcursormode(1) call, nPrimary is xpos, nSecondary is ypos.
float CSQC_InputEvent(float bInputType, float nPrimary, float nSecondary)
{
	if (HUD_Panel_InputEvent(bInputType, nPrimary, nSecondary))
		return true;

	if (QuickMenu_InputEvent(bInputType, nPrimary, nSecondary))
		return true;

	if (HUD_Radar_InputEvent(bInputType, nPrimary, nSecondary))
		return true;

	if (MapVote_InputEvent(bInputType, nPrimary, nSecondary))
		return true;

	if (HUD_Minigame_InputEvent(bInputType, nPrimary, nSecondary))
		return true;

	return false;
}

// END REQUIRED CSQC FUNCTIONS
// --------------------------------------------------------------------------

// --------------------------------------------------------------------------
// BEGIN OPTIONAL CSQC FUNCTIONS

void Ent_Remove();

void Ent_RemovePlayerScore()
{
	SELFPARAM();
	if(this.owner) {
		SetTeam(this.owner, -1);
		this.owner.gotscores = 0;
		for(int i = 0; i < MAX_SCORE; ++i) {
			this.owner.(scores[i]) = 0; // clear all scores
		}
	}
}

NET_HANDLE(ENT_CLIENT_SCORES, bool isnew)
{
	make_pure(this);
	int i, n;
	bool isNew;
	entity o;

	// damnit -.- don't want to go change every single .sv_entnum in hud.qc AGAIN
	// (no I've never heard of M-x replace-string, sed, or anything like that)
	isNew = !this.owner; // workaround for DP bug
	n = ReadByte()-1;

#ifdef DP_CSQC_ENTITY_REMOVE_IS_B0RKED
	if(!isNew && n != this.sv_entnum)
	{
		//print("A CSQC entity changed its owner!\n");
		LOG_INFOF("A CSQC entity changed its owner! (edict: %d, classname: %s)\n", etof(this), this.classname);
		isNew = true;
		Ent_Remove();
	}
#endif

	this.sv_entnum = n;

	o = playerslots[this.sv_entnum];
	if (!o)
	{
		o = playerslots[this.sv_entnum] = new(playerslot);
		make_pure(o);
	}
	this.owner = o;
	o.sv_entnum = this.sv_entnum;
	o.gotscores = 1;

	//if (!o.sort_prev)
	//	RegisterPlayer(o);
	//playerchecker will do this for us later, if it has not already done so

    int sf, lf;
#if MAX_SCORE <= 8
	sf = ReadByte();
	lf = ReadByte();
#else
	sf = ReadShort();
	lf = ReadShort();
#endif
    int p;
	for(i = 0, p = 1; i < MAX_SCORE; ++i, p *= 2)
		if(sf & p)
		{
			if(lf & p)
				o.(scores[i]) = ReadInt24_t();
			else
				o.(scores[i]) = ReadChar();
		}

	return = true;

	if(o.sort_prev)
		HUD_UpdatePlayerPos(o); // if not registered, we cannot do this yet!

	this.entremove = Ent_RemovePlayerScore;
}

NET_HANDLE(ENT_CLIENT_TEAMSCORES, bool isnew)
{
	make_pure(this);
	int i;
	entity o;

	this.team = ReadByte();
	o = this.owner = GetTeam(this.team, true); // these team numbers can always be trusted

    int sf, lf;
#if MAX_TEAMSCORE <= 8
	sf = ReadByte();
	lf = ReadByte();
#else
	sf = ReadShort();
	lf = ReadShort();
#endif
	int p;
	for(i = 0, p = 1; i < MAX_TEAMSCORE; ++i, p *= 2)
		if(sf & p)
		{
			if(lf & p)
				o.(teamscores[i]) = ReadInt24_t();
			else
				o.(teamscores[i]) = ReadChar();
		}

	return = true;

	HUD_UpdateTeamPos(o);
}

NET_HANDLE(ENT_CLIENT_CLIENTDATA, bool isnew)
{
	make_pure(this);
	float newspectatee_status;

    int f = ReadByte();

	scoreboard_showscores_force = (f & 1);

	if(f & 2)
	{
		newspectatee_status = ReadByte();
		if(newspectatee_status == player_localnum + 1)
			newspectatee_status = -1; // observing
	}
	else
		newspectatee_status = 0;

	spectatorbutton_zoom = (f & 4);

	if(f & 8)
	{
		angles_held_status = 1;
		angles_held.x = ReadAngle();
		angles_held.y = ReadAngle();
		angles_held.z = 0;
	}
	else
		angles_held_status = 0;

	return = true;

	if(newspectatee_status != spectatee_status)
	{
		// clear race stuff
		race_laptime = 0;
		race_checkpointtime = 0;
	}
	if (autocvar_hud_panel_healtharmor_progressbar_gfx)
	{
		if ( (spectatee_status == -1 && newspectatee_status > 0) //before observing, now spectating
		  || (spectatee_status > 0 && newspectatee_status > 0 && spectatee_status != newspectatee_status) //changed spectated player
		)
			prev_p_health = -1;
		else if(spectatee_status && !newspectatee_status) //before observing/spectating, now playing
			prev_health = -1;
	}
	spectatee_status = newspectatee_status;

	// we could get rid of spectatee_status, and derive it from player_localentnum and player_localnum
}

NET_HANDLE(ENT_CLIENT_NAGGER, bool isnew)
{
	make_pure(this);
    int i, j, b, f;

    int nags = ReadByte(); // NAGS NAGS NAGS NAGS NAGS NAGS NADZ NAGS NAGS NAGS

	if(!(nags & BIT(2)))
	{
		if(vote_called_vote)
			strunzone(vote_called_vote);
		vote_called_vote = string_null;
		vote_active = 0;
	}
	else
	{
		vote_active = 1;
	}

	if(nags & BIT(6))
	{
		vote_yescount = ReadByte();
		vote_nocount = ReadByte();
		vote_needed = ReadByte();
		vote_highlighted = ReadChar();
	}

	if(nags & BIT(7))
	{
		if(vote_called_vote)
			strunzone(vote_called_vote);
		vote_called_vote = strzone(ColorTranslateRGB(ReadString()));
	}

	if(nags & 1)
	{
		for(j = 0; j < maxclients; ++j)
			if(playerslots[j])
				playerslots[j].ready = 1;
		for(i = 1; i <= maxclients; i += 8)
		{
			f = ReadByte();
			for(j = i-1, b = 1; b < 256; b *= 2, ++j)
				if (!(f & b))
					if(playerslots[j])
						playerslots[j].ready = 0;
		}
	}

	return = true;

	ready_waiting = (nags & BIT(0));
	ready_waiting_for_me = (nags & BIT(1));
	vote_waiting = (nags & BIT(2));
	vote_waiting_for_me = (nags & BIT(3));
	warmup_stage = (nags & BIT(4));
}

NET_HANDLE(ENT_CLIENT_ELIMINATEDPLAYERS, bool isnew)
{
	make_pure(this);
    int i, j, b, f;

    int sf = ReadByte();
	if(sf & 1)
	{
		for(j = 0; j < maxclients; ++j)
			if(playerslots[j])
				playerslots[j].eliminated = 1;
		for(i = 1; i <= maxclients; i += 8)
		{
			f = ReadByte();
			for(j = i-1, b = 1; b < 256; b *= 2, ++j)
				if (!(f & b))
					if(playerslots[j])
						playerslots[j].eliminated = 0;
		}
	}
	return true;
}

NET_HANDLE(ENT_CLIENT_RANDOMSEED, bool isnew)
{
	make_pure(this);
	prandom_debug();
	float s = ReadShort();
	psrandom(s);
	return true;
}

NET_HANDLE(ENT_CLIENT_ACCURACY, bool isnew)
{
	make_pure(this);
    int sf = ReadInt24_t();
	if (sf == 0) {
		for (int w = 0; w <= WEP_LAST - WEP_FIRST; ++w)
			weapon_accuracy[w] = -1;
		return true;
	}

	int f = 1;
	for (int w = 0; w <= WEP_LAST - WEP_FIRST; ++w) {
		if (sf & f) {
            int b = ReadByte();
			if (b == 0)
				weapon_accuracy[w] = -1;
			else if (b == 255)
				weapon_accuracy[w] = 1.0; // no better error handling yet, sorry
			else
				weapon_accuracy[w] = (b - 1.0) / 100.0;
		}
		f = (f == 0x800000) ? 1 : f * 2;
	}
	return true;
}

void Spawn_Draw(entity this)
{
	__pointparticles(this.cnt, this.origin + '0 0 28', '0 0 2', bound(0, frametime, 0.1));
}

NET_HANDLE(ENT_CLIENT_SPAWNPOINT, bool is_new)
{
	float teamnum = (ReadByte() - 1);
	vector spn_origin;
	spn_origin.x = ReadShort();
	spn_origin.y = ReadShort();
	spn_origin.z = ReadShort();

	//if(is_new)
	//{
		this.origin = spn_origin;
		setsize(this, PL_MIN_CONST, PL_MAX_CONST);
		//droptofloor();

		/*if(autocvar_cl_spawn_point_model) // needs a model first
		{
			this.mdl = "models/spawnpoint.md3";
			this.colormod = Team_ColorRGB(teamnum);
			precache_model(this.mdl);
			setmodel(this, this.mdl);
			this.drawmask = MASK_NORMAL;
			//this.movetype = MOVETYPE_NOCLIP;
			//this.draw = Spawn_Draw;
		}*/
		if(autocvar_cl_spawn_point_particles)
		{
			if((serverflags & SERVERFLAG_TEAMPLAY))
			{
				switch(teamnum)
				{
					case NUM_TEAM_1: this.cnt = particleeffectnum(EFFECT_SPAWNPOINT_RED); break;
					case NUM_TEAM_2: this.cnt = particleeffectnum(EFFECT_SPAWNPOINT_BLUE); break;
					case NUM_TEAM_3: this.cnt = particleeffectnum(EFFECT_SPAWNPOINT_YELLOW); break;
					case NUM_TEAM_4: this.cnt = particleeffectnum(EFFECT_SPAWNPOINT_PINK); break;
					default: this.cnt = particleeffectnum(EFFECT_SPAWNPOINT_NEUTRAL); break;
				}
			}
			else { this.cnt = particleeffectnum(EFFECT_SPAWNPOINT_NEUTRAL); }

			this.draw = Spawn_Draw;
		}
	//}

	//printf("Ent_ReadSpawnPoint(is_new = %d); origin = %s, team = %d, effect = %d\n", is_new, vtos(this.origin), teamnum, this.cnt);
	return true;
}

NET_HANDLE(ENT_CLIENT_SPAWNEVENT, bool is_new)
{
	// If entnum is 0, ONLY do the local spawn actions
	// this way the server can disable the sending of
	// spawn origin or such to clients if wanted.
	float entnum = ReadByte();

	if(entnum)
	{
		this.origin_x = ReadShort();
		this.origin_y = ReadShort();
		this.origin_z = ReadShort();

		if(is_new)
		{
			float teamnum = entcs_GetTeam(entnum - 1);

			if(autocvar_cl_spawn_event_particles)
			{
				switch(teamnum)
				{
					case NUM_TEAM_1: pointparticles(EFFECT_SPAWN_RED, this.origin, '0 0 0', 1); break;
					case NUM_TEAM_2: pointparticles(EFFECT_SPAWN_BLUE, this.origin, '0 0 0', 1); break;
					case NUM_TEAM_3: pointparticles(EFFECT_SPAWN_YELLOW, this.origin, '0 0 0', 1); break;
					case NUM_TEAM_4: pointparticles(EFFECT_SPAWN_PINK, this.origin, '0 0 0', 1); break;
					default: pointparticles(EFFECT_SPAWN_NEUTRAL, this.origin, '0 0 0', 1); break;
				}
			}
			if(autocvar_cl_spawn_event_sound)
			{
				sound(this, CH_TRIGGER, SND_SPAWN, VOL_BASE, ATTEN_NORM);
			}
		}
	}
	return = true;

	// local spawn actions
	if(is_new && (!entnum || (entnum == player_localentnum)))
	{
		zoomin_effect = 1;
		current_viewzoom = (1 / bound(1, autocvar_cl_spawnzoom_factor, 16));

		if(autocvar_cl_unpress_zoom_on_spawn)
		{
			localcmd("-zoom\n");
			button_zoom = false;
		}
	}
	HUD_Radar_Hide_Maximized();
	//printf("Ent_ReadSpawnEvent(is_new = %d); origin = %s, entnum = %d, localentnum = %d\n", is_new, vtos(this.origin), entnum, player_localentnum);
}

// CSQC_Ent_Update : Called every frame that the server has indicated an update to the SSQC / CSQC entity has occured.
// The only parameter reflects if the entity is "new" to the client, meaning it just came into the client's PVS.
void CSQC_Ent_Update(bool isnew)
{
	SELFPARAM();
	this.sourceLocLine = __LINE__;
	this.sourceLocFile = __FILE__;
	int t = ReadByte();

	// set up the "time" global for received entities to be correct for interpolation purposes
	float savetime = time;
	if(servertime)
	{
		time = servertime;
	}
	else
	{
		serverprevtime = time;
		serverdeltatime = STAT(MOVEVARS_TICRATE) * STAT(MOVEVARS_TIMESCALE);
		time = serverprevtime + serverdeltatime;
	}

#ifdef DP_CSQC_ENTITY_REMOVE_IS_B0RKED
	if (this.enttype)
	{
		if (t != this.enttype || isnew)
		{
			LOG_INFOF("A CSQC entity changed its type! (edict: %d, server: %d, type: %d -> %d)\n", etof(this), this.entnum, this.enttype, t);
			Ent_Remove();
			clearentity(this);
			isnew = true;
		}
	}
	else
	{
		if (!isnew)
		{
			LOG_INFOF("A CSQC entity appeared out of nowhere! (edict: %d, server: %d, type: %d)\n", etof(this), this.entnum, t);
			isnew = true;
		}
	}
#endif
	this.enttype = t;
	bool done = false;
	FOREACH(LinkedEntities, it.m_id == t, LAMBDA(
		if (isnew) this.classname = it.netname;
		if (autocvar_developer_csqcentities)
            LOG_INFOF("CSQC_Ent_Update(%d) at %f with this=%i {.entnum=%d, .enttype=%d} t=%s (%d)\n", isnew, savetime, this, this.entnum, this.enttype, this.classname, t);
		done = it.m_read(this, NULL, isnew);
		break;
	));
	time = savetime;
	if (!done)
	{
		LOG_FATALF("CSQC_Ent_Update(%d) at %f with this=%i {.entnum=%d, .enttype=%d} t=%s (%d)\n", isnew, savetime, this, this.entnum, this.enttype, this.classname, t);
	}
}

// Destructor, but does NOT deallocate the entity by calling remove(). Also
// used when an entity changes its type. For an entity that someone interacts
// with others, make sure it can no longer do so.
void Ent_Remove()
{
	SELFPARAM();
	if(this.entremove) this.entremove();

	if(this.skeletonindex)
	{
		skel_delete(this.skeletonindex);
		this.skeletonindex = 0;
	}

	if(this.snd_looping > 0)
	{
		sound(this, this.snd_looping, SND_Null, VOL_BASE, autocvar_g_jetpack_attenuation);
		this.snd_looping = 0;
	}

	this.enttype = 0;
	this.classname = "";
	this.draw = func_null;
	this.entremove = func_null;
	// TODO possibly set more stuff to defaults
}
// CSQC_Ent_Remove : Called when the server requests a SSQC / CSQC entity to be removed.  Essentially call remove(this) as well.
void CSQC_Ent_Remove()
{
	SELFPARAM();
	if (autocvar_developer_csqcentities) LOG_INFOF("CSQC_Ent_Remove() with this=%i {.entnum=%d, .enttype=%d}\n", this, this.entnum, this.enttype);
	if (wasfreed(this))
	{
		LOG_WARNING("CSQC_Ent_Remove called for already removed entity. Packet loss?\n");
		return;
	}
	if (this.enttype) Ent_Remove();
	remove(this);
}

void Gamemode_Init()
{
	if (!isdemo())
	{
		if(!(calledhooks & HOOK_START))
			localcmd("\n_cl_hook_gamestart ", MapInfo_Type_ToString(gametype), "\n");
		calledhooks |= HOOK_START;
	}
}
// CSQC_Parse_StuffCmd : Provides the stuffcmd string in the first parameter that the server provided.  To execute standard behavior, simply execute localcmd with the string.
void CSQC_Parse_StuffCmd(string strMessage)
{
	if (autocvar_developer_csqcentities) LOG_INFOF("CSQC_Parse_StuffCmd(\"%s\")\n", strMessage);
	localcmd(strMessage);
}
// CSQC_Parse_Print : Provides the print string in the first parameter that the server provided.  To execute standard behavior, simply execute print with the string.
void CSQC_Parse_Print(string strMessage)
{
	if (autocvar_developer_csqcentities) LOG_INFOF("CSQC_Parse_Print(\"%s\")\n", strMessage);
	print(ColorTranslateRGB(strMessage));
}

// CSQC_Parse_CenterPrint : Provides the centerprint_hud string in the first parameter that the server provided.
void CSQC_Parse_CenterPrint(string strMessage)
{
	if (autocvar_developer_csqcentities) LOG_INFOF("CSQC_Parse_CenterPrint(\"%s\")\n", strMessage);
	centerprint_hud(strMessage);
}

// CSQC_Parse_TempEntity : Handles all temporary entity network data in the CSQC layer.
// You must ALWAYS first acquire the temporary ID, which is sent as a byte.
// Return value should be 1 if CSQC handled the temporary entity, otherwise return 0 to have the engine process the event.
bool CSQC_Parse_TempEntity()
{
	// Acquire TE ID
	int nTEID = ReadByte();

	FOREACH(TempEntities, it.m_id == nTEID, LAMBDA(
		if (autocvar_developer_csqcentities)
			LOG_INFOF("CSQC_Parse_TempEntity() nTEID=%s (%d)\n", it.netname, nTEID);
		return it.m_read(NULL, NULL, true);
	));

	if (autocvar_developer_csqcentities)
		LOG_INFOF("CSQC_Parse_TempEntity() with nTEID=%d\n", nTEID);

	// No special logic for this temporary entity; return 0 so the engine can handle it
	return false;
}

/** TODO somehow thwart prvm_globalset client ... */
string forcefog;
void Fog_Force()
{
	if (autocvar_cl_orthoview && autocvar_cl_orthoview_nofog)
		localcmd("\nr_drawfog 0\n");
	else if (forcefog != "")
		localcmd(sprintf("\nfog %s\nr_fog_exp2 0\nr_drawfog 1\n", forcefog));
}

void Gamemode_Init();
NET_HANDLE(ENT_CLIENT_SCORES_INFO, bool isnew)
{
	make_pure(this);
	gametype = ReadInt24_t();
	HUD_ModIcons_SetFunc();
	for (int i = 0; i < MAX_SCORE; ++i)
	{
		if (scores_label[i]) strunzone(scores_label[i]);
		scores_label[i] = strzone(ReadString());
		scores_flags[i] = ReadByte();
	}
	for (int i = 0; i < MAX_TEAMSCORE; ++i)
	{
		if (teamscores_label[i]) strunzone(teamscores_label[i]);
		teamscores_label[i] = strzone(ReadString());
		teamscores_flags[i] = ReadByte();
	}
	return = true;
	HUD_InitScores();
	Gamemode_Init();
}

NET_HANDLE(ENT_CLIENT_INIT, bool isnew)
{
	nb_pb_period = ReadByte() / 32; //Accuracy of 1/32th

	hook_shotorigin[0] = decompressShotOrigin(ReadInt24_t());
	hook_shotorigin[1] = decompressShotOrigin(ReadInt24_t());
	hook_shotorigin[2] = decompressShotOrigin(ReadInt24_t());
	hook_shotorigin[3] = decompressShotOrigin(ReadInt24_t());
	arc_shotorigin[0] = decompressShotOrigin(ReadInt24_t());
	arc_shotorigin[1] = decompressShotOrigin(ReadInt24_t());
	arc_shotorigin[2] = decompressShotOrigin(ReadInt24_t());
	arc_shotorigin[3] = decompressShotOrigin(ReadInt24_t());

	if (forcefog) strunzone(forcefog);
	forcefog = strzone(ReadString());

	armorblockpercent = ReadByte() / 255.0;

	serverflags = ReadByte();

	g_trueaim_minrange = ReadCoord();

	return = true;

	MUTATOR_CALLHOOK(Ent_Init);

	if (!postinit) PostInit();
}

NET_HANDLE(TE_CSQC_RACE, bool isNew)
{
	int b = ReadByte();

	switch (b)
	{
		case RACE_NET_CHECKPOINT_HIT_QUALIFYING:
			race_checkpoint = ReadByte();
			race_time = ReadInt24_t();
			race_previousbesttime = ReadInt24_t();
			if(race_previousbestname)
				strunzone(race_previousbestname);
			race_previousbestname = strzone(ColorTranslateRGB(ReadString()));

			race_checkpointtime = time;

			if(race_checkpoint == 0 || race_checkpoint == 254)
			{
				race_penaltyaccumulator = 0;
				race_laptime = time; // valid
			}

			break;

		case RACE_NET_CHECKPOINT_CLEAR:
			race_laptime = 0;
			race_checkpointtime = 0;
			break;

		case RACE_NET_CHECKPOINT_NEXT_SPEC_QUALIFYING:
			race_laptime = ReadCoord();
			race_checkpointtime = -99999;
			// fall through
		case RACE_NET_CHECKPOINT_NEXT_QUALIFYING:
			race_nextcheckpoint = ReadByte();

			race_nextbesttime = ReadInt24_t();
			if(race_nextbestname)
				strunzone(race_nextbestname);
			race_nextbestname = strzone(ColorTranslateRGB(ReadString()));
			break;

		case RACE_NET_CHECKPOINT_HIT_RACE:
			race_mycheckpoint = ReadByte();
			race_mycheckpointtime = time;
			race_mycheckpointdelta = ReadInt24_t();
			race_mycheckpointlapsdelta = ReadByte();
			if(race_mycheckpointlapsdelta >= 128)
				race_mycheckpointlapsdelta -= 256;
			if(race_mycheckpointenemy)
				strunzone(race_mycheckpointenemy);
			race_mycheckpointenemy = strzone(ColorTranslateRGB(ReadString()));
			break;

		case RACE_NET_CHECKPOINT_HIT_RACE_BY_OPPONENT:
			race_othercheckpoint = ReadByte();
			race_othercheckpointtime = time;
			race_othercheckpointdelta = ReadInt24_t();
			race_othercheckpointlapsdelta = ReadByte();
			if(race_othercheckpointlapsdelta >= 128)
				race_othercheckpointlapsdelta -= 256;
			if(race_othercheckpointenemy)
				strunzone(race_othercheckpointenemy);
			race_othercheckpointenemy = strzone(ColorTranslateRGB(ReadString()));
			break;

		case RACE_NET_PENALTY_RACE:
			race_penaltyeventtime = time;
			race_penaltytime = ReadShort();
			//race_penaltyaccumulator += race_penaltytime;
			if(race_penaltyreason)
				strunzone(race_penaltyreason);
			race_penaltyreason = strzone(ReadString());
			break;

		case RACE_NET_PENALTY_QUALIFYING:
			race_penaltyeventtime = time;
			race_penaltytime = ReadShort();
			race_penaltyaccumulator += race_penaltytime;
			if(race_penaltyreason)
				strunzone(race_penaltyreason);
			race_penaltyreason = strzone(ReadString());
			break;

		case RACE_NET_SERVER_RECORD:
			race_server_record = ReadInt24_t();
			break;
		case RACE_NET_SPEED_AWARD:
			race_speedaward = ReadInt24_t();
			if(race_speedaward_holder)
				strunzone(race_speedaward_holder);
			race_speedaward_holder = strzone(ReadString());
			break;
		case RACE_NET_SPEED_AWARD_BEST:
			race_speedaward_alltimebest = ReadInt24_t();
			if(race_speedaward_alltimebest_holder)
				strunzone(race_speedaward_alltimebest_holder);
			race_speedaward_alltimebest_holder = strzone(ReadString());
			break;
		case RACE_NET_SERVER_RANKINGS:
			float prevpos, del;
            int pos = ReadShort();
			prevpos = ReadShort();
			del = ReadShort();

			// move other rankings out of the way
            int i;
			if (prevpos) {
				for (i=prevpos-1;i>pos-1;--i) {
					grecordtime[i] = grecordtime[i-1];
					if(grecordholder[i])
						strunzone(grecordholder[i]);
					grecordholder[i] = strzone(grecordholder[i-1]);
				}
			} else if (del) { // a record has been deleted by the admin
				for (i=pos-1; i<= RANKINGS_CNT-1; ++i) {
					if (i == RANKINGS_CNT-1) { // clear out last record
						grecordtime[i] = 0;
						if (grecordholder[i])
							strunzone(grecordholder[i]);
						grecordholder[i] = string_null;
					}
					else {
						grecordtime[i] = grecordtime[i+1];
						if (grecordholder[i])
							strunzone(grecordholder[i]);
						grecordholder[i] = strzone(grecordholder[i+1]);
					}
				}
			} else { // player has no ranked record yet
				for (i=RANKINGS_CNT-1;i>pos-1;--i) {
					grecordtime[i] = grecordtime[i-1];
					if(grecordholder[i])
						strunzone(grecordholder[i]);
					grecordholder[i] = strzone(grecordholder[i-1]);
				}
			}

			// store new ranking
			if(grecordholder[pos-1] != "")
				strunzone(grecordholder[pos-1]);
			grecordholder[pos-1] = strzone(ReadString());
			grecordtime[pos-1] = ReadInt24_t();
			if(grecordholder[pos-1] == entcs_GetName(player_localnum))
				race_myrank = pos;
			break;
		case RACE_NET_SERVER_STATUS:
			race_status = ReadShort();
			if(race_status_name)
				strunzone(race_status_name);
			race_status_name = strzone(ReadString());
	}
	return true;
}

NET_HANDLE(TE_CSQC_TEAMNAGGER, bool isNew)
{
	teamnagger = 1;
	return true;
}

NET_HANDLE(TE_CSQC_PINGPLREPORT, bool isNew)
{
	int i = ReadByte();
	int pi = ReadShort();
	int pl = ReadByte();
	int ml = ReadByte();
	return = true;
	entity e = playerslots[i];
	if (!e) return;
	e.ping = pi;
	e.ping_packetloss = pl / 255.0;
	e.ping_movementloss = ml / 255.0;
}

NET_HANDLE(TE_CSQC_WEAPONCOMPLAIN, bool isNew)
{
	complain_weapon = ReadByte();
	if (complain_weapon_name) strunzone(complain_weapon_name);
	complain_weapon_name = strzone(Weapons_from(complain_weapon).m_name);
	complain_weapon_type = ReadByte();
	return = true;

	complain_weapon_time = time;
	weapontime = time; // ping the weapon panel

	switch(complain_weapon_type)
	{
		case 0: Local_Notification(MSG_MULTI, ITEM_WEAPON_NOAMMO, complain_weapon); break;
		case 1: Local_Notification(MSG_MULTI, ITEM_WEAPON_DONTHAVE, complain_weapon); break;
		default: Local_Notification(MSG_MULTI, ITEM_WEAPON_UNAVAILABLE, complain_weapon); break;
	}
}

string getcommandkey(string text, string command)
{
	string keys;
	float n, j, k, l = 0;

	if (!autocvar_hud_showbinds)
		return text;

	keys = db_get(binddb, command);
	if (keys == "")
	{
		n = tokenize(findkeysforcommand(command, 0)); // uses '...' strings
		for(j = 0; j < n; ++j)
		{
			k = stof(argv(j));
			if(k != -1)
			{
				if ("" == keys)
					keys = keynumtostring(k);
				else
					keys = strcat(keys, ", ", keynumtostring(k));

				++l;
				if (autocvar_hud_showbinds_limit > 0 && autocvar_hud_showbinds_limit <= l)
					break;
			}

		}
		if (keys == "")
			keys = "NO_KEY";
		db_put(binddb, command, keys);
	}

	if (keys == "NO_KEY") {
		if (autocvar_hud_showbinds > 1)
			return sprintf(_("%s (not bound)"), text);
		else
			return text;
	}
	else if (autocvar_hud_showbinds > 1)
		return sprintf("%s (%s)", text, keys);
	else
		return keys;
}
