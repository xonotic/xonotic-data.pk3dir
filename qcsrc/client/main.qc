#include "main.qh"

#include <client/command/cl_cmd.qh>
#include <client/draw.qh>
#include <client/hud/_mod.qh>
#include <client/hud/panel/centerprint.qh>
#include <client/hud/panel/chat.qh>
#include <client/hud/panel/quickmenu.qh>
#include <client/hud/panel/scoreboard.qh>
#include <client/items/items.qh>
#include <client/mapvoting.qh>
#include <client/mutators/_mod.qh>
#include <client/shownames.qh>
#include <client/view.qh>
#include <client/weapons/projectile.qh>
#include <common/deathtypes/all.qh>
#include <common/effects/all.inc>
#include <common/effects/all.qh>
#include <common/effects/effect.qh>
#include <common/effects/qc/_mod.qh>
#include <common/ent_cs.qh>
#include <common/gamemodes/gamemode/nexball/cl_nexball.qh>
#include <common/items/_mod.qh>
#include <common/mapinfo.qh>
#include <common/mapobjects/_mod.qh>
#include <common/minigames/cl_minigames.qh>
#include <common/minigames/cl_minigames_hud.qh>
#include <common/net_linked.qh>
#include <common/net_notice.qh>
#include <common/scores.qh>
#include <common/vehicles/all.qh>
#include <lib/csqcmodel/cl_model.qh>
#include <lib/csqcmodel/interpolate.qh>
#include <lib/warpzone/client.qh>

// --------------------------------------------------------------------------
// BEGIN REQUIRED CSQC FUNCTIONS
//include "main.qh"

#define DP_CSQC_ENTITY_REMOVE_IS_B0RKED

// CSQC_Init : Called every time the CSQC code is initialized (essentially at map load)
// Useful for precaching things

void CSQC_Init()
{
	prvm_language = strzone(cvar_string("prvm_language"));

#ifdef WATERMARK
	LOG_TRACEF("^4CSQC Build information: ^1%s", WATERMARK);
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

	registercvar("cl_shootfromfixedorigin", "");

	registercvar("cl_multijump", "-1");

	registercvar("cl_dodging", "0");

	registercvar("cl_spawn_near_teammate", "1");

	registercvar("cl_weapon_switch_reload", "1");
	registercvar("cl_weapon_switch_fallback_to_impulse", "1");

	registercvar("cl_allow_uidranking", "1");

	if(autocvar_cl_lockview)
		cvar_set("cl_lockview", "0");

	gametype = NULL;

	postinit = false;

	calledhooks = 0;

	teams = Sort_Spawn();
	players = Sort_Spawn();

	GetTeam(NUM_SPECTATOR, true); // add specs first

	for (int w = 0; w <= WEP_LAST - WEP_FIRST; ++w)
		weapon_accuracy[w] = -1;

	// precaches

	if(autocvar_cl_reticle)
	{
		precache_pic("gfx/reticle_normal");
		// weapon reticles are precached in weapon files
	}

	{
		get_mi_min_max_texcoords(1); // try the CLEVER way first
		minimapname = strcat("gfx/", mi_shortname, "_radar");
		shortmapname = mi_shortname;

		if (precache_pic(minimapname) == "")
		{
			// but maybe we have a non-clever minimap
			minimapname = strcat("gfx/", mi_shortname, "_mini");
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
	LoadMenuSkinValues();
}

// CSQC_Shutdown : Called every time the CSQC code is shutdown (changing maps, quitting, etc)
void Shutdown()
{
	WarpZone_Shutdown();

	delete(teams);
	delete(players);
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

	if (autocvar_r_drawviewmodel < 0)
		cvar_set("r_drawviewmodel", "0");

	cvar_set("slowmo", cvar_defstring("slowmo")); // reset it back to 'default'

	if (!isdemo())
	{
		if (!(calledhooks & HOOK_START))
			localcmd("\n_cl_hook_gamestart nop\n");
		if (!(calledhooks & HOOK_END))
			localcmd("\ncl_hook_gameend\n");
	}

	localcmd("\ncl_hook_shutdown\n");

	localcmd("\n-button12\n");

	deactivate_minigame();
	HUD_MinigameMenu_Close(NULL, NULL, NULL);

	ReplicateVars(REPLICATEVARS_DESTROY);
}

void AuditLists()
{
	entity e;
	entity prev;

	prev = players;
	for(e = prev.sort_next; e; prev = e, e = e.sort_next)
	{
		if(prev != e.sort_prev)
			error(strcat("sort list chain error\nplease submit the output of 'prvm_edicts client' to the developers"));
	}

	prev = teams;
	for(e = prev.sort_next; e; prev = e, e = e.sort_next)
	{
		if(prev != e.sort_prev)
			error(strcat("sort list chain error\nplease submit the output of 'prvm_edicts client' to the developers"));
	}
}

float RegisterPlayer(entity player)
{
	entity pl;
	AuditLists();
	for(pl = players.sort_next; pl; pl = pl.sort_next)
		if(pl == player)
			error("Player already registered!");
	player.sort_next = players.sort_next;
	player.sort_prev = players;
	if(players.sort_next)
		players.sort_next.sort_prev = player;
	players.sort_next = player;
	AuditLists();
	return true;
}

void RemovePlayer(entity player)
{
	entity pl, parent;
	AuditLists();
	parent = players;
	for(pl = players.sort_next; pl && pl != player; pl = pl.sort_next)
		parent = pl;

	if(!pl)
	{
		error("Trying to remove a player which is not in the playerlist!");
		return;
	}
	parent.sort_next = player.sort_next;
	if(player.sort_next)
		player.sort_next.sort_prev = parent;
	AuditLists();
}

void MoveToLast(entity e)
{
	AuditLists();
	entity ent = e.sort_next;
	while(ent)
	{
		SORT_SWAP(ent, e);
		ent = e.sort_next;
	}
	AuditLists();
}

float RegisterTeam(entity Team)
{
	assert_once(Team.team, eprint(Team));
	entity tm;
	AuditLists();
	for(tm = teams.sort_next; tm; tm = tm.sort_next)
		if(tm == Team)
			error("Team already registered!");
	Team.sort_next = teams.sort_next;
	Team.sort_prev = teams;
	if(teams.sort_next)
		teams.sort_next.sort_prev = Team;
	teams.sort_next = Team;
	if(Team.team && Team.team != NUM_SPECTATOR)
		++team_count;
	AuditLists();
	return true;
}

void RemoveTeam(entity Team)
{
	entity tm, parent;
	AuditLists();
	parent = teams;
	for(tm = teams.sort_next; tm && tm != Team; tm = tm.sort_next)
		parent = tm;

	if(!tm)
	{
		LOG_INFO(_("Trying to remove a team which is not in the teamlist!"));
		return;
	}
	parent.sort_next = Team.sort_next;
	if(Team.sort_next)
		Team.sort_next.sort_prev = parent;
	if(Team.team && Team.team != NUM_SPECTATOR)
		--team_count;
	AuditLists();
}

entity GetTeam(int Team, bool add)
{
	TC(int, Team); TC(bool, add);
	int num = (Team == NUM_SPECTATOR) ? 16 : Team;
	if(teamslots[num])
		return teamslots[num];
	if (!add)
		return NULL;
	entity tm = new_pure(team);
	tm.team = Team;
	teamslots[num] = tm;
	RegisterTeam(tm);
	return tm;
}

.float has_team;
bool SetTeam(entity o, int Team)
{
	TC(int, Team);
	//devassert_once(Team);
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
				if(GetTeam(Team, false) == NULL)
				{
					LOG_TRACEF("trying to switch to unsupported team %d", Team);
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
				if(GetTeam(Team, false) == NULL)
				{
					LOG_TRACEF("trying to switch to unsupported team %d", Team);
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

void Playerchecker_Think(entity this)
{
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
				e.sort_prev = NULL;
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
					playerslots[i] = e = new_pure(playerslot);
				}
				e.sv_entnum = i;
				e.ping = 0;
				e.ping_packetloss = 0;
				e.ping_movementloss = 0;
				//e.gotscores = 0; // we might already have the scores...
				int t = entcs_GetScoreTeam(i);
				if (t) SetTeam(e, t); // will not hurt; later updates come with Scoreboard_UpdatePlayerTeams
				RegisterPlayer(e);
				Scoreboard_UpdatePlayerPos(e);
			}
		}
	}
	this.nextthink = time + 0.2;
}

void PostInit()
{
	entity playerchecker = new_pure(playerchecker);
	setthink(playerchecker, Playerchecker_Think);
	playerchecker.nextthink = time + 0.2;

	TrueAim_Init();

	// this can't be called in CSQC_Init as it'd send cvars too early
	ReplicateVars_Start();

	postinit = true;
}

// CSQC_InputEvent : Used to perform actions based on any key pressed, key released and mouse on the client.
// Return value should be 1 if CSQC handled the input, otherwise return 0 to have the input passed to the engine.
// All keys are in ascii.
// bInputType = 0 is key pressed, 1 is key released, 2 and 3 are mouse input.
// In the case of keyboard input, nPrimary is the ascii code, and nSecondary is 0.
// In the case of mouse input, nPrimary is xdelta, nSecondary is ydelta.
// In the case of mouse input after a setcursormode(1) call, nPrimary is xpos, nSecondary is ypos.
float CSQC_InputEvent(int bInputType, float nPrimary, float nSecondary)
{
	TC(int, bInputType);
	bool override = false;

	override |= HUD_Panel_InputEvent(bInputType, nPrimary, nSecondary);
	if (override)
		return true;

	override |= HUD_Panel_Chat_InputEvent(bInputType, nPrimary, nSecondary);

	override |= QuickMenu_InputEvent(bInputType, nPrimary, nSecondary);

	override |= HUD_Radar_InputEvent(bInputType, nPrimary, nSecondary);

	override |= MapVote_InputEvent(bInputType, nPrimary, nSecondary);

	override |= HUD_Minigame_InputEvent(bInputType, nPrimary, nSecondary);

	if(override)
		return true;

	if(bInputType == 3 || bInputType == 2)
		return false;

	// at this point bInputType can only be 0 or 1 (key pressed or released)
	bool key_pressed = (bInputType == 0);

	if(key_pressed) {
		if(nPrimary == K_ALT) hudShiftState |= S_ALT;
		if(nPrimary == K_CTRL) hudShiftState |= S_CTRL;
		if(nPrimary == K_SHIFT) hudShiftState |= S_SHIFT;
	}
	else {
		if(nPrimary == K_ALT) hudShiftState -= (hudShiftState & S_ALT);
		if(nPrimary == K_CTRL) hudShiftState -= (hudShiftState & S_CTRL);
		if(nPrimary == K_SHIFT) hudShiftState -= (hudShiftState & S_SHIFT);
	}

	if (nPrimary == K_ESCAPE && !(hudShiftState & S_SHIFT) && key_pressed)
	{
		if (!isdemo() && cvar("_menu_gamemenu_dialog_available"))
		{
			localcmd("\nmenu_showgamemenudialog\n");
			return true;
		}
	}

	return false;
}

// END REQUIRED CSQC FUNCTIONS
// --------------------------------------------------------------------------

// --------------------------------------------------------------------------
// BEGIN OPTIONAL CSQC FUNCTIONS

void Ent_RemovePlayerScore(entity this)
{
	if(this.owner) {
		SetTeam(this.owner, -1);
		this.owner.gotscores = 0;
		FOREACH(Scores, true, {
			this.owner.(scores(it)) = 0; // clear all scores
		});
	}
}

NET_HANDLE(ENT_CLIENT_SCORES, bool isnew)
{
	make_pure(this);
	entity o;

	// damnit -.- don't want to go change every single .sv_entnum in hud.qc AGAIN
	// (no I've never heard of M-x replace-string, sed, or anything like that)
	bool isNew = !this.owner; // workaround for DP bug
	int n = ReadByte()-1;

#ifdef DP_CSQC_ENTITY_REMOVE_IS_B0RKED
	if(!isNew && n != this.sv_entnum)
	{
		//print("A CSQC entity changed its owner!\n");
		LOG_INFOF("A CSQC entity changed its owner! (edict: %d, classname: %s)", etof(this), this.classname);
		isNew = true;
		Ent_Remove(this);
	}
#endif

	this.sv_entnum = n;

	o = playerslots[this.sv_entnum];
	if (!o)
	{
		o = playerslots[this.sv_entnum] = new_pure(playerslot);
	}
	this.owner = o;
	o.sv_entnum = this.sv_entnum;
	o.gotscores = 1;

	//if (!o.sort_prev)
	//	RegisterPlayer(o);
	//playerchecker will do this for us later, if it has not already done so

	int sf = ReadShort();
	int lf = ReadShort();
	FOREACH(Scores, true, {
		int p = 1 << (i % 16);
		if (sf & p)
		{
			if (lf & p)
				o.(scores(it)) = ReadInt24_t();
			else
				o.(scores(it)) = ReadChar();
		}
	});

	return = true;

	if(o.sort_prev)
		Scoreboard_UpdatePlayerPos(o); // if not registered, we cannot do this yet!

	this.entremove = Ent_RemovePlayerScore;
}

NET_HANDLE(ENT_CLIENT_TEAMSCORES, bool isnew)
{
	make_pure(this);
	int i;

	this.team = ReadByte();
	entity o = this.owner = GetTeam(this.team, true); // these team numbers can always be trusted

#if MAX_TEAMSCORE <= 8
	int sf = ReadByte();
	int lf = ReadByte();
#else
	int sf = ReadShort();
	int lf = ReadShort();
#endif
	for(i = 0; i < MAX_TEAMSCORE; ++i)
		if(sf & BIT(i))
		{
			if(lf & BIT(i))
				o.(teamscores(i)) = ReadInt24_t();
			else
				o.(teamscores(i)) = ReadChar();
		}

	return = true;

	Scoreboard_UpdateTeamPos(o);
}

NET_HANDLE(ENT_CLIENT_CLIENTDATA, bool isnew)
{
	make_pure(this);
	float newspectatee_status;

	int f = ReadByte();

	scoreboard_showscores_force = (f & BIT(0));

	if(f & BIT(1))
	{
		newspectatee_status = ReadByte();
		if(newspectatee_status == player_localnum + 1)
			newspectatee_status = -1; // observing
	}
	else
		newspectatee_status = 0;

	spectatorbutton_zoom = (f & BIT(2));

	if(f & BIT(4))
	{
		num_spectators = ReadByte();

		float i, slot;

		for(i = 0; i < MAX_SPECTATORS; ++i)
			spectatorlist[i] = 0; // reset list first

		int limit = min(num_spectators, MAX_SPECTATORS);
		for(i = 0; i < limit; ++i)
		{
			slot = ReadByte();
			spectatorlist[i] = slot - 1;
		}
	}
	else
	{
		for(int j = 0; j < MAX_SPECTATORS; ++j)
			spectatorlist[j] = 0; // reset list if showspectators has been turned off
		num_spectators = 0;
	}

	return = true;

	if(newspectatee_status != spectatee_status)
	{
		// clear race stuff
		race_laptime = 0;
		race_checkpointtime = 0;
		hud_dynamic_shake_factor = -1;
		spectatee_status_changed_time = time;
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
		strfree(vote_called_vote);
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
		strcpy(vote_called_vote, ReadString());
	}

	if(nags & 1)
	{
		for(j = 0; j < maxclients; ++j)
			if(playerslots[j])
				playerslots[j].ready = true;
		for(i = 1; i <= maxclients; i += 8)
		{
			f = ReadByte();
			for(j = i-1, b = BIT(0); b < BIT(8); b <<= 1, ++j)
				if (!(f & b))
					if(playerslots[j])
						playerslots[j].ready = false;
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
	int sf = 0;
	serialize(byte, 0, sf);
	if (sf & 1) {
		for (int j = 0; j < maxclients; ++j) {
			if (playerslots[j]) {
				playerslots[j].eliminated = true;
			}
		}
		for (int i = 1; i <= maxclients; i += 8) {
			int f = 0;
			serialize(byte, 0, f);
			for (int b = 0; b < 8; ++b) {
				if (f & BIT(b)) continue;
				int j = i - 1 + b;
				if (playerslots[j]) {
					playerslots[j].eliminated = false;
				}
			}
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
	bool dodraw = autocvar_cl_spawn_point_particles;
	if(dodraw && autocvar_cl_spawn_point_dist_max)
	{
		vector org = getpropertyvec(VF_ORIGIN);
		dodraw = vdist(org - this.origin, <, autocvar_cl_spawn_point_dist_max);
	}

	if(dodraw)
		pointparticles(((!teamplay) ? EFFECT_SPAWNPOINT_NEUTRAL : EFFECT_SPAWNPOINT(this.team - 1)), this.origin + '0 0 28', '0 0 2', bound(0, frametime, 0.1));
}

NET_HANDLE(ENT_CLIENT_SPAWNPOINT, bool is_new)
{
	float teamnum = (ReadByte() - 1);
	vector spn_origin = ReadVector();

	this.team = (teamnum + 1);

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
			//this.move_movetype = MOVETYPE_NOCLIP;
			//this.draw = Spawn_Draw;
			IL_PUSH(g_drawables, this);
		}*/
		this.draw = Spawn_Draw;
		if (is_new) IL_PUSH(g_drawables, this);
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
		this.origin = ReadVector();

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
		if(autocvar_cl_spawnzoom && !autocvar_cl_lockview)
		{
			zoomin_effect = 1;
			current_viewzoom = (1 / bound(1, autocvar_cl_spawnzoom_factor, 16));
		}

		if(autocvar_cl_unpress_zoom_on_spawn)
		{
			localcmd("-zoom\n");
			button_zoom = false;
		}
		HUD_Radar_Hide_Maximized();
	}
	//printf("Ent_ReadSpawnEvent(is_new = %d); origin = %s, entnum = %d, localentnum = %d\n", is_new, vtos(this.origin), entnum, player_localentnum);
}

// CSQC_Ent_Update : Called every frame that the server has indicated an update to the SSQC / CSQC entity has occured.
// The parameter isnew reflects if the entity is "new" to the client, meaning it just came into the client's PVS.
void CSQC_Ent_Update(entity this, bool isnew)
{
	this.sourceLoc = __FILE__":"STR(__LINE__);
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
			LOG_INFOF("A CSQC entity changed its type! (edict: %d, server: %d, type: %d -> %d)", etof(this), this.entnum, this.enttype, t);
			Ent_Remove(this);
			ONREMOVE(this);
			clearentity(this);
			isnew = true;
		}
	}
	else
	{
		if (!isnew)
		{
			LOG_INFOF("A CSQC entity appeared out of nowhere! (edict: %d, server: %d, type: %d)", etof(this), this.entnum, t);
			isnew = true;
		}
	}
#endif
	this.enttype = t;
	bool done = false;
	FOREACH(LinkedEntities, it.m_id == t, {
		if (isnew) this.classname = it.netname;
		if (autocvar_developer_csqcentities)
			LOG_INFOF("CSQC_Ent_Update(%i, %d) at %f {.entnum=%d, .enttype=%d} t=%s (%d)", this, isnew, savetime, this.entnum, this.enttype, this.classname, t);
		done = it.m_read(this, NULL, isnew);
		MUTATOR_CALLHOOK(Ent_Update, this, isnew);
		break;
	});
	time = savetime;
	if (!done)
	{
		LOG_FATALF("CSQC_Ent_Update(%i, %d) at %f {.entnum=%d, .enttype=%d} t=%s (%d)", this, isnew, savetime, this.entnum, this.enttype, this.classname, t);
	}
}

// Destructor, but does NOT deallocate the entity by calling remove(). Also
// used when an entity changes its type. For an entity that someone interacts
// with others, make sure it can no longer do so.
void Ent_Remove(entity this)
{
	if(this.entremove) this.entremove(this);

	if(this.skeletonindex)
	{
		skel_delete(this.skeletonindex);
		this.skeletonindex = 0;
	}

	if(this.snd_looping > 0)
	{
		sound(this, this.snd_looping, SND_Null, VOL_BASE, autocvar_cl_jetpack_attenuation);
		this.snd_looping = 0;
	}

	this.enttype = 0;
	this.classname = "";
	this.draw = func_null;
	this.entremove = func_null;
	// TODO possibly set more stuff to defaults
}
// CSQC_Ent_Remove : Called when the server requests a SSQC / CSQC entity to be removed.  Essentially call remove(this) as well.
void CSQC_Ent_Remove(entity this)
{
	if (autocvar_developer_csqcentities) LOG_INFOF("CSQC_Ent_Remove() with this=%i {.entnum=%d, .enttype=%d}", this, this.entnum, this.enttype);
	if (wasfreed(this))
	{
		LOG_WARN("CSQC_Ent_Remove called for already removed entity. Packet loss?");
		return;
	}
	if (this.enttype) Ent_Remove(this);
	delete(this);
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
	if (autocvar_developer_csqcentities) LOG_INFOF("CSQC_Parse_StuffCmd(\"%s\")", strMessage);
	localcmd(strMessage);
}
// CSQC_Parse_Print : Provides the print string in the first parameter that the server provided.  To execute standard behavior, simply execute print with the string.
void CSQC_Parse_Print(string strMessage)
{
	if (autocvar_developer_csqcentities) LOG_INFOF("CSQC_Parse_Print(\"%s\")", strMessage);
	print(ColorTranslateRGB(strMessage));
}

// CSQC_Parse_CenterPrint : Provides the centerprint_AddStandard string in the first parameter that the server provided.
void CSQC_Parse_CenterPrint(string strMessage)
{
	if (autocvar_developer_csqcentities) LOG_INFOF("CSQC_Parse_CenterPrint(\"%s\")", strMessage);
	centerprint_AddStandard(strMessage);
}

// CSQC_Parse_TempEntity : Handles all temporary entity network data in the CSQC layer.
// You must ALWAYS first acquire the temporary ID, which is sent as a byte.
// Return value should be 1 if CSQC handled the temporary entity, otherwise return 0 to have the engine process the event.
bool CSQC_Parse_TempEntity()
{
	// Acquire TE ID
	int nTEID = ReadByte();

	FOREACH(TempEntities, it.m_id == nTEID, {
		if (autocvar_developer_csqcentities)
			LOG_INFOF("CSQC_Parse_TempEntity() nTEID=%s (%d)", it.netname, nTEID);
		return it.m_read(NULL, NULL, true);
	});

	if (autocvar_developer_csqcentities)
		LOG_INFOF("CSQC_Parse_TempEntity() with nTEID=%d", nTEID);

	// No special logic for this temporary entity; return 0 so the engine can handle it
	return false;
}

string forcefog;
void Fog_Force()
{
	if (autocvar_cl_orthoview && autocvar_cl_orthoview_nofog)
		localcmd("\nr_drawfog 0\n");
	else if (forcefog != "")
		localcmd(sprintf("\nfog %s\nr_fog_exp2 0\nr_drawfog 1\n", forcefog));
}

bool net_handle_ServerWelcome();
NET_HANDLE(ENT_CLIENT_SCORES_INFO, bool isnew)
{
	make_pure(this);
	gametype = ReadRegistered(Gametypes);
	teamplay = _MapInfo_GetTeamPlayBool(gametype);
	HUD_ModIcons_SetFunc();
	FOREACH(Scores, true, {
		strcpy(scores_label(it), ReadString());
		scores_flags(it) = ReadByte();
	});
	for (int i = 0; i < MAX_TEAMSCORE; ++i)
	{
		strcpy(teamscores_label(i), ReadString());
		teamscores_flags(i) = ReadByte();
	}
	bool welcome_msg_too = ReadByte();
	if (welcome_msg_too)
		net_handle_ServerWelcome();
	return = true;
	Scoreboard_InitScores();
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

	strcpy(forcefog, ReadString());

	armorblockpercent = ReadByte() / 255.0;
	damagepush_speedfactor = ReadByte() / 255.0;

	serverflags = ReadByte();

	g_trueaim_minrange = ReadCoord();

	return = true;

	MUTATOR_CALLHOOK(Ent_Init);

	if (!postinit) PostInit();
}

float GetSpeedUnitFactor(int speed_unit)
{
	switch(speed_unit)
	{
		default:
		case 1: return 1.0;
		case 2: return 0.0254;
		case 3: return 0.0254 * 3.6;
		case 4: return 0.0254 * 3.6 * 0.6213711922;
		case 5: return 0.0254 * 1.943844492; // 1 m/s = 1.943844492 knots, because 1 knot = 1.852 km/h
	}
}

string GetSpeedUnit(int speed_unit)
{
	switch(speed_unit)
	{
		// translator-friendly strings without the initial space
		default:
		case 1: return strcat(" ", _("qu/s"));
		case 2: return strcat(" ", _("m/s"));
		case 3: return strcat(" ", _("km/h"));
		case 4: return strcat(" ", _("mph"));
		case 5: return strcat(" ", _("knots"));
	}
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
			race_mypreviousbesttime = ReadInt24_t();
			string pbestname = ReadString();
			if(autocvar_cl_race_cptimes_onlyself)
			{
				race_previousbesttime = race_mypreviousbesttime;
				race_mypreviousbesttime = 0;
				strcpy(race_previousbestname, "");
			}
			else
				strcpy(race_previousbestname, pbestname);

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
			if(b != RACE_NET_CHECKPOINT_NEXT_SPEC_QUALIFYING) // not while spectating (matches server)
				race_mybesttime = ReadInt24_t();
			string newname = ReadString();
			if(autocvar_cl_race_cptimes_onlyself && b != RACE_NET_CHECKPOINT_NEXT_SPEC_QUALIFYING)
			{
				race_nextbesttime = race_mybesttime;
				race_mybesttime = 0;
				strcpy(race_nextbestname, "");
			}
			else
				strcpy(race_nextbestname, newname);
			break;

		case RACE_NET_CHECKPOINT_HIT_RACE:
			race_mycheckpoint = ReadByte();
			race_mycheckpointtime = time;
			race_mycheckpointdelta = ReadInt24_t();
			race_mycheckpointlapsdelta = ReadByte();
			if(race_mycheckpointlapsdelta >= 128)
				race_mycheckpointlapsdelta -= 256;
			int who = ReadByte();
			if(who)
				strcpy(race_mycheckpointenemy, entcs_GetName(who - 1));
			else
				strcpy(race_mycheckpointenemy, ""); // TODO: maybe string_null works fine here?
			break;

		case RACE_NET_CHECKPOINT_HIT_RACE_BY_OPPONENT:
			race_othercheckpoint = ReadByte();
			race_othercheckpointtime = time;
			race_othercheckpointdelta = ReadInt24_t();
			race_othercheckpointlapsdelta = ReadByte();
			if(race_othercheckpointlapsdelta >= 128)
				race_othercheckpointlapsdelta -= 256;
			int what = ReadByte();
			if(what)
				strcpy(race_othercheckpointenemy, entcs_GetName(what - 1));
			else
				strcpy(race_othercheckpointenemy, ""); // TODO: maybe string_null works fine here?
			break;

		case RACE_NET_PENALTY_RACE:
		case RACE_NET_PENALTY_QUALIFYING:
			race_penaltyeventtime = time;
			race_penaltytime = ReadShort();
			string reason = ReadString();
			if (reason == "missing a checkpoint")
				reason = _("missing a checkpoint");
			strcpy(race_penaltyreason, reason);
			if (b == RACE_NET_PENALTY_QUALIFYING)
				race_penaltyaccumulator += race_penaltytime;
			break;

		case RACE_NET_SERVER_RECORD:
			race_server_record = ReadInt24_t();
			break;
		case RACE_NET_SPEED_AWARD:
			race_speedaward = ReadInt24_t() * GetSpeedUnitFactor(autocvar_hud_panel_physics_speed_unit);
			strcpy(race_speedaward_holder, ReadString());
			break;
		case RACE_NET_SPEED_AWARD_BEST:
			race_speedaward_alltimebest = ReadInt24_t() * GetSpeedUnitFactor(autocvar_hud_panel_physics_speed_unit);
			strcpy(race_speedaward_alltimebest_holder, ReadString());
			break;
		case RACE_NET_RANKINGS_CNT:
			RANKINGS_DISPLAY_CNT = ReadByte();
			break;
		case RACE_NET_SERVER_RANKINGS:
			float prevpos, del;
			int pos = ReadShort();
			prevpos = ReadShort();
			del = ReadShort();

			// move other rankings out of the way
			int i;
			if (prevpos) {
				int m = min(prevpos, RANKINGS_DISPLAY_CNT);
				for (i=m-1; i>pos-1; --i) {
					grecordtime[i] = grecordtime[i-1];
					strcpy(grecordholder[i], grecordholder[i-1]);
				}
			} else if (del) { // a record has been deleted by the admin
				for (i=pos-1; i<= RANKINGS_DISPLAY_CNT-1; ++i) {
					if (i == RANKINGS_DISPLAY_CNT-1) { // clear out last record
						grecordtime[i] = 0;
						strfree(grecordholder[i]);
					}
					else {
						grecordtime[i] = grecordtime[i+1];
						strcpy(grecordholder[i], grecordholder[i+1]);
					}
				}
			} else { // player has no ranked record yet
				for (i=RANKINGS_DISPLAY_CNT-1;i>pos-1;--i) {
					grecordtime[i] = grecordtime[i-1];
					strcpy(grecordholder[i], grecordholder[i-1]);
				}
			}

			if (grecordtime[RANKINGS_DISPLAY_CNT]) {
				// kick off the player who fell from the last displayed position
				grecordtime[RANKINGS_DISPLAY_CNT] = 0;
				strfree(grecordholder[RANKINGS_DISPLAY_CNT]);
			}

			// store new ranking
			strcpy(grecordholder[pos-1], ReadString());
			grecordtime[pos-1] = ReadInt24_t();
			if(strdecolorize(grecordholder[pos-1]) == strdecolorize(entcs_GetName(player_localnum)))
				race_myrank = pos;
			break;
		case RACE_NET_SERVER_STATUS:
			race_status = ReadShort();
			strcpy(race_status_name, ReadString());
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
	int weapon_id = ReadByte();
	complain_weapon = REGISTRY_GET(Weapons, weapon_id);
	complain_weapon_type = ReadByte();
	return = true;

	complain_weapon_time = time;
	weapontime = time; // ping the weapon panel

	switch(complain_weapon_type)
	{
		case 0: Local_Notification(MSG_MULTI, ITEM_WEAPON_NOAMMO, weapon_id); break;
		case 1: Local_Notification(MSG_MULTI, ITEM_WEAPON_DONTHAVE, weapon_id); break;
		default: Local_Notification(MSG_MULTI, ITEM_WEAPON_UNAVAILABLE, weapon_id); break;
	}
}

string translate_modifications(string s)
{
	return build_mutator_list(s);
}

string translate_weaponarena(string s)
{
	if (s == "") return s;
	if (s == "All Weapons Arena") return _("All Weapons Arena");
	if (s == "All Available Weapons Arena") return _("All Available Weapons Arena");
	if (s == "Most Weapons Arena") return _("Most Weapons Arena");
	if (s == "Most Available Weapons Arena") return _("Most Available Weapons Arena");
	if (s == "Dev All Weapons Arena") return s; // development option, do not translate
	if (s == "Dev All Available Weapons Arena") return s; // development option, do not translate
	if (s == "No Weapons Arena") return _("No Weapons Arena");

	int n = tokenizebyseparator(s, " & ");
	string wpn_list = "";
	for (int i = 0; i < n; i++)
	{
		Weapon wep = Weapon_from_name(argv(i));
		if (wep == WEP_Null)
			LOG_INFO("^3Warning: ^7server sent an invalid weapon name\n");
		wpn_list = cons_mid(wpn_list, " & ", wep.m_name);
	}
	if (wpn_list != "")
		return sprintf(_("%s Arena"), wpn_list);
	else
		return _("No Weapons Arena");
}

string GetVersionMessage(string hostversion, bool version_mismatch, bool version_check)
{
	string xonotic_hostversion = strcat("Xonotic ", hostversion);
	if (version_mismatch)
	{
		if(!version_check)
			return strcat(sprintf(_("This is %s"), xonotic_hostversion), "\n^3",
				_("Your client version is outdated."), "\n\n\n",
				_("### YOU WON'T BE ABLE TO PLAY ON THIS SERVER ###"), "\n\n\n",
				_("Please update!"));
		else
			return strcat(sprintf(_("This is %s"), xonotic_hostversion), "\n^3",
				_("This server is using an outdated Xonotic version."), "\n\n\n",
				_("### THIS SERVER IS INCOMPATIBLE AND THUS YOU CANNOT JOIN ###"));
	}
	return sprintf(_("Welcome to %s"), xonotic_hostversion);
}

bool net_handle_ServerWelcome()
{
	bool campaign = ReadByte();
	if (campaign)
	{
		string campaign_title = ReadString();
		int campaign_level = ReadByte();
		string campaign_msg = ReadString();
		string welcomedialog_args;
		welcomedialog_args = strcat("HOSTNAME \"", campaign_title, "\"");
		string key = getcommandkey(_("jump"), "+jump");
		string msg = strcat(
			CCR("^F1"), sprintf(_("Level %d:"), campaign_level),
			sprintf(CCR(" ^BG%s\n^3\n"), campaign_msg),
			sprintf(CCR(_("^BGPress ^F2%s^BG to enter the game")), key));
		msg = MakeConsoleSafe(strreplace("\n", "\\n", msg));
		welcomedialog_args = strcat(welcomedialog_args, " WELCOME \"", msg, "\"");
		localcmd("\nmenu_cmd directmenu Welcome ", welcomedialog_args, "\n");
		return true;
	}

	welcome_msg_force_centerprint = ReadByte();
	strcpy(hostname, ReadString());

	string hostversion = ReadString();
	bool version_mismatch = ReadByte();
	bool version_check = ReadByte();
	string ver = GetVersionMessage(hostversion, version_mismatch, version_check);

	string modifications = translate_modifications(ReadString());
	string weaponarena_list = translate_weaponarena(ReadString());
	string cache_mutatormsg = ReadString();
	string motd = ReadString();

	string msg = "";
	msg = strcat(msg, ver);
	msg = strcat(msg, "^8\n\n", strcat(_("Gametype:"), " ^1", MapInfo_Type_ToText(gametype)), "^8\n");

	modifications = cons_mid(modifications, ", ", weaponarena_list);
	if(modifications != "")
		msg = strcat(msg, "^8\n", _("Active modifications:"), " ^3", modifications, "^8\n");

	if (cache_mutatormsg != "")
		msg = strcat(msg, "\n\n^8", _("Special gameplay tips:"), " ^7", cache_mutatormsg);
	string mutator_msg = "";
	MUTATOR_CALLHOOK(BuildGameplayTipsString, mutator_msg);
	mutator_msg = M_ARGV(0, string);
	msg = strcat(msg, mutator_msg); // trust that the mutator will do proper formatting

	if (motd != "")
		msg = strcat(msg, "\n\n^8", _("MOTD:"), " ^7", motd);

	strcpy(welcome_msg, msg);
	welcome_msg_menu_check_maxtime = time + 1; // wait for menu to load before showing the welcome dialog
	return true;
}

void Welcome_Message_Show_Try()
{
	if (!welcome_msg_menu_check_maxtime)
		return;

	bool want_dialog = (!welcome_msg_force_centerprint && !isdemo() && autocvar_cl_welcome_in_menu_dialog);
	// if want dialog check if menu is initialized but for a short time
	if (!want_dialog || cvar("_menu_initialized") == 2 || time > welcome_msg_menu_check_maxtime)
	{
		if (want_dialog && cvar("_menu_welcome_dialog_available"))
		{
			string welcomedialog_args = strcat("HOSTNAME \"", hostname, "\"");
			string msg = MakeConsoleSafe(strreplace("\n", "\\n", welcome_msg));
			welcomedialog_args = strcat(welcomedialog_args, " WELCOME \"", msg, "\"");
			localcmd("\nmenu_cmd directmenu Welcome ", welcomedialog_args, "\n");
			if (intermission) // close it after it's been initialized so it can still be opened manually
				localcmd("\ntogglemenu 0\n");
		}
		else
			centerprint_Add(ORDINAL(CPID_MOTD), strcat(hostname, "\n\n\n", welcome_msg), -1, 0);

		strfree(welcome_msg);
		welcome_msg_menu_check_maxtime = 0;
	}
}

NET_HANDLE(TE_CSQC_SERVERWELCOME, bool isNew)
{
	return net_handle_ServerWelcome();
}

string _getcommandkey(string cmd_name, string command, bool forcename)
{
	string keys;
	float n, j, k, l = 0;

	if (!autocvar_hud_showbinds)
		return cmd_name;

	keys = db_get(binddb, command);
	if (keys == "")
	{
		bool joy_active = cvar("joy_active");
		n = tokenize(findkeysforcommand(command, 0)); // uses '...' strings
		for(j = 0; j < n; ++j)
		{
			k = stof(argv(j));
			if(k != -1)
			{
				string key = keynumtostring(k);
				if(!joy_active && substring(key, 0, 3) == "JOY")
					continue;

				key = translate_key(key);

				if (keys == "")
					keys = key;
				else
					keys = strcat(keys, ", ", key);

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
			return sprintf(_("%s (not bound)"), cmd_name);
		else
			return cmd_name;
	}
	else if (autocvar_hud_showbinds > 1 || forcename)
		return sprintf("%s (%s)", cmd_name, keys);
	else
		return keys;
}

/** engine callback */
void URI_Get_Callback(int id, int status, string data)
{
	TC(int, id); TC(int, status);
	if(url_URI_Get_Callback(id, status, data))
	{
		// handled
	}
	else if (id == URI_GET_DISCARD)
	{
		// discard
	}
	else if (id >= URI_GET_CURL && id <= URI_GET_CURL_END)
	{
		// sv_cmd curl
		Curl_URI_Get_Callback(id, status, data);
	}
	else
	{
		LOG_INFOF("Received HTTP request data for an invalid id %d.", id);
	}
}
