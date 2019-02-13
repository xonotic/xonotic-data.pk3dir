#include "g_world.qh"

#include "anticheat.qh"
#include "antilag.qh"
#include "bot/api.qh"
#include "campaign.qh"
#include "cheats.qh"
#include "client.qh"
#include "command/common.qh"
#include "command/getreplies.qh"
#include "command/sv_cmd.qh"
#include "command/vote.qh"
#include "g_hook.qh"
#include "ipban.qh"
#include "mapvoting.qh"
#include <server/mutators/_mod.qh>
#include "race.qh"
#include "scores.qh"
#include "scores_rules.qh"
#include "teamplay.qh"
#include "weapons/weaponstats.qh"
#include "../common/constants.qh"
#include <common/net_linked.qh>
#include "../common/deathtypes/all.qh"
#include "../common/gamemodes/sv_rules.qh"
#include "../common/mapinfo.qh"
#include "../common/monsters/_mod.qh"
#include "../common/monsters/sv_monsters.qh"
#include "../common/vehicles/all.qh"
#include "../common/notifications/all.qh"
#include "../common/physics/player.qh"
#include "../common/playerstats.qh"
#include "../common/stats.qh"
#include "../common/teams.qh"
#include "../common/mapobjects/trigger/secret.qh"
#include "../common/mapobjects/target/music.qh"
#include "../common/util.qh"
#include "../common/items/_mod.qh"
#include <common/weapons/_all.qh>
#include "../common/state.qh"

const float LATENCY_THINKRATE = 10;
.float latency_sum;
.float latency_cnt;
.float latency_time;
entity pingplreport;
void PingPLReport_Think(entity this)
{
	float delta;
	entity e;

	delta = 3 / maxclients;
	if(delta < sys_frametime)
		delta = 0;
	this.nextthink = time + delta;

	e = edict_num(this.cnt + 1);
	if(IS_CLIENT(e) && IS_REAL_CLIENT(e))
	{
		WriteHeader(MSG_BROADCAST, TE_CSQC_PINGPLREPORT);
		WriteByte(MSG_BROADCAST, this.cnt);
		WriteShort(MSG_BROADCAST, bound(1, CS(e).ping, 65535));
		WriteByte(MSG_BROADCAST, min(ceil(CS(e).ping_packetloss * 255), 255));
		WriteByte(MSG_BROADCAST, min(ceil(CS(e).ping_movementloss * 255), 255));

		// record latency times for clients throughout the match so we can report it to playerstats
		if(time > (CS(e).latency_time + LATENCY_THINKRATE))
		{
			CS(e).latency_sum += CS(e).ping;
			CS(e).latency_cnt += 1;
			CS(e).latency_time = time;
			//print("sum: ", ftos(CS(e).latency_sum), ", cnt: ", ftos(CS(e).latency_cnt), ", avg: ", ftos(CS(e).latency_sum / CS(e).latency_cnt), ".\n");
		}
	}
	else
	{
		WriteHeader(MSG_BROADCAST, TE_CSQC_PINGPLREPORT);
		WriteByte(MSG_BROADCAST, this.cnt);
		WriteShort(MSG_BROADCAST, 0);
		WriteByte(MSG_BROADCAST, 0);
		WriteByte(MSG_BROADCAST, 0);
	}
	this.cnt = (this.cnt + 1) % maxclients;
}
void PingPLReport_Spawn()
{
	pingplreport = new_pure(pingplreport);
	setthink(pingplreport, PingPLReport_Think);
	pingplreport.nextthink = time;
}

const float SPAWNFLAG_NO_WAYPOINTS_FOR_ITEMS = 1;
string redirection_target;
float world_initialized;

void SetDefaultAlpha()
{
	if (!MUTATOR_CALLHOOK(SetDefaultAlpha))
	{
		default_player_alpha = autocvar_g_player_alpha;
		if(default_player_alpha == 0)
			default_player_alpha = 1;
		default_weapon_alpha = default_player_alpha;
	}
}

void GotoFirstMap(entity this)
{
	float n;
	if(autocvar__sv_init)
	{
		// cvar_set("_sv_init", "0");
		// we do NOT set this to 0 any more, so someone "accidentally" changing
		// to this "init" map on a dedicated server will cause no permanent
		// harm
		if(autocvar_g_maplist_shuffle)
			ShuffleMaplist();
		n = tokenizebyseparator(autocvar_g_maplist, " ");
		cvar_set("g_maplist_index", ftos(n - 1)); // jump to map 0 in GotoNextMap

		MapInfo_Enumerate();
		MapInfo_FilterGametype(MapInfo_CurrentGametype(), MapInfo_CurrentFeatures(), MapInfo_RequiredFlags(), MapInfo_ForbiddenFlags(), 0);

		if(!DoNextMapOverride(1))
			GotoNextMap(1);

		return;
	}

	if(time < 5)
	{
		this.nextthink = time;
	}
	else
	{
		this.nextthink = time + 1;
		LOG_INFO("Waiting for _sv_init being set to 1 by initialization scripts...");
	}
}

void cvar_changes_init()
{
	float h;
	string k, v, d;
	float n, i, adding, pureadding;

	strfree(cvar_changes);
	strfree(cvar_purechanges);
	cvar_purechanges_count = 0;

	h = buf_create();
	buf_cvarlist(h, "", "_"); // exclude all _ cvars as they are temporary
	n = buf_getsize(h);

	adding = true;
	pureadding = true;

	for(i = 0; i < n; ++i)
	{
		k = bufstr_get(h, i);

#define BADPREFIX(p) if(substring(k, 0, strlen(p)) == p) continue
#define BADPRESUFFIX(p,s) if(substring(k, 0, strlen(p)) == p && substring(k, -strlen(s), -1) == s) continue
#define BADCVAR(p) if(k == p) continue

		// general excludes and namespaces for server admin used cvars
		BADPREFIX("help_"); // PN's server has this listed as changed, let's not rat him out for THAT

		// internal
		BADPREFIX("csqc_");
		BADPREFIX("cvar_check_");
		BADCVAR("gamecfg");
		BADCVAR("g_configversion");
		BADCVAR("halflifebsp");
		BADCVAR("sv_mapformat_is_quake2");
		BADCVAR("sv_mapformat_is_quake3");
		BADPREFIX("sv_world");

		// client
		BADPREFIX("chase_");
		BADPREFIX("cl_");
		BADPREFIX("con_");
		BADPREFIX("scoreboard_");
		BADPREFIX("g_campaign");
		BADPREFIX("g_waypointsprite_");
		BADPREFIX("gl_");
		BADPREFIX("joy");
		BADPREFIX("hud_");
		BADPREFIX("m_");
		BADPREFIX("menu_");
		BADPREFIX("net_slist_");
		BADPREFIX("r_");
		BADPREFIX("sbar_");
		BADPREFIX("scr_");
		BADPREFIX("snd_");
		BADPREFIX("show");
		BADPREFIX("sensitivity");
		BADPREFIX("userbind");
		BADPREFIX("v_");
		BADPREFIX("vid_");
		BADPREFIX("crosshair");
		BADCVAR("mod_q3bsp_lightmapmergepower");
		BADCVAR("mod_q3bsp_nolightmaps");
		BADCVAR("fov");
		BADCVAR("mastervolume");
		BADCVAR("volume");
		BADCVAR("bgmvolume");
		BADCVAR("in_pitch_min");
		BADCVAR("in_pitch_max");

		// private
		BADCVAR("developer");
		BADCVAR("log_dest_udp");
		BADCVAR("net_address");
		BADCVAR("net_address_ipv6");
		BADCVAR("port");
		BADCVAR("savedgamecfg");
		BADCVAR("serverconfig");
		BADCVAR("sv_autoscreenshot");
		BADCVAR("sv_heartbeatperiod");
		BADCVAR("sv_vote_master_password");
		BADCVAR("sys_colortranslation");
		BADCVAR("sys_specialcharactertranslation");
		BADCVAR("timeformat");
		BADCVAR("timestamps");
		BADCVAR("g_require_stats");
		BADPREFIX("developer_");
		BADPREFIX("g_ban_");
		BADPREFIX("g_banned_list");
		BADPREFIX("g_require_stats_");
		BADPREFIX("g_chat_flood_");
		BADPREFIX("g_ghost_items");
		BADPREFIX("g_playerstats_");
		BADPREFIX("g_voice_flood_");
		BADPREFIX("log_file");
		BADPREFIX("quit_");
		BADPREFIX("rcon_");
		BADPREFIX("sv_allowdownloads");
		BADPREFIX("sv_autodemo");
		BADPREFIX("sv_curl_");
		BADPREFIX("sv_eventlog");
		BADPREFIX("sv_logscores_");
		BADPREFIX("sv_master");
		BADPREFIX("sv_weaponstats_");
		BADPREFIX("sv_waypointsprite_");
		BADCVAR("rescan_pending");

		// these can contain player IDs, so better hide
		BADPREFIX("g_forced_team_");
		BADCVAR("sv_muteban_list");
		BADCVAR("sv_voteban_list");
		BADCVAR("sv_allow_customplayermodels_idlist");
		BADCVAR("sv_allow_customplayermodels_speciallist");

		// mapinfo
		BADCVAR("fraglimit");
		BADCVAR("g_arena");
		BADCVAR("g_assault");
		BADCVAR("g_ca");
		BADCVAR("g_ca_teams");
		BADCVAR("g_conquest");
		BADCVAR("g_ctf");
		BADCVAR("g_cts");
		BADCVAR("g_dotc");
		BADCVAR("g_dm");
		BADCVAR("g_domination");
		BADCVAR("g_domination_default_teams");
		BADCVAR("g_duel");
		BADCVAR("g_freezetag");
		BADCVAR("g_freezetag_teams");
		BADCVAR("g_invasion_teams");
		BADCVAR("g_invasion_type");
		BADCVAR("g_jailbreak");
		BADCVAR("g_jailbreak_teams");
		BADCVAR("g_keepaway");
		BADCVAR("g_keyhunt");
		BADCVAR("g_keyhunt_teams");
		BADCVAR("g_lms");
		BADCVAR("g_nexball");
		BADCVAR("g_onslaught");
		BADCVAR("g_race");
		BADCVAR("g_race_laps_limit");
		BADCVAR("g_race_qualifying_timelimit");
		BADCVAR("g_race_qualifying_timelimit_override");
		BADCVAR("g_runematch");
		BADCVAR("g_snafu");
		BADCVAR("g_tdm");
		BADCVAR("g_tdm_teams");
		BADCVAR("g_vip");
		BADCVAR("leadlimit");
		BADCVAR("nextmap");
		BADCVAR("teamplay");
		BADCVAR("timelimit");
		BADCVAR("g_mapinfo_ignore_warnings");

		// long
		BADCVAR("hostname");
		BADCVAR("g_maplist");
		BADCVAR("g_maplist_mostrecent");
		BADCVAR("sv_motd");

		v = cvar_string(k);
		d = cvar_defstring(k);
		if(v == d)
			continue;

		if(adding)
		{
			cvar_changes = strcat(cvar_changes, k, " \"", v, "\" // \"", d, "\"\n");
			if(strlen(cvar_changes) > 16384)
			{
				cvar_changes = "// too many settings have been changed to show them here\n";
				adding = 0;
			}
		}

		// now check if the changes are actually gameplay relevant

		// does nothing gameplay relevant
		BADCVAR("captureleadlimit_override");
		BADCVAR("condump_stripcolors");
		BADCVAR("gameversion");
		BADCVAR("g_allow_oldvortexbeam");
		BADCVAR("g_balance_kill_delay");
		BADCVAR("g_buffs_pickup_anyway");
		BADCVAR("g_buffs_randomize");
		BADCVAR("g_campcheck_distance");
		BADCVAR("g_ca_point_leadlimit");
		BADCVAR("g_ca_point_limit");
		BADCVAR("g_ctf_captimerecord_always");
		BADCVAR("g_ctf_flag_glowtrails");
		BADCVAR("g_ctf_flag_pickup_verbosename");
		BADCVAR("g_domination_point_leadlimit");
		BADCVAR("g_forced_respawn");
		BADCVAR("g_freezetag_point_leadlimit");
		BADCVAR("g_freezetag_point_limit");
		BADCVAR("g_hats");
		BADCVAR("g_invasion_point_limit");
		BADCVAR("g_jump_grunt");
		BADCVAR("g_keyhunt_point_leadlimit");
		BADCVAR("g_nexball_goalleadlimit");
		BADCVAR("g_new_toys_use_pickupsound");
		BADCVAR("g_physics_predictall");
		BADCVAR("g_piggyback");
		BADCVAR("g_playerclip_collisions");
		BADCVAR("g_tdm_point_leadlimit");
		BADCVAR("g_tdm_point_limit");
		BADCVAR("leadlimit_and_fraglimit");
		BADCVAR("leadlimit_override");
		BADCVAR("pausable");
		BADCVAR("sv_checkforpacketsduringsleep");
		BADCVAR("sv_damagetext");
		BADCVAR("sv_db_saveasdump");
		BADCVAR("sv_intermission_cdtrack");
		BADCVAR("sv_minigames");
		BADCVAR("sv_namechangetimer");
		BADCVAR("sv_precacheplayermodels");
		BADCVAR("sv_stepheight");
		BADCVAR("sv_timeout");
		BADCVAR("sv_weapons_modeloverride");
		BADCVAR("w_prop_interval");
		BADPREFIX("crypto_");
		BADPREFIX("gameversion_");
		BADPREFIX("g_chat_");
		BADPREFIX("g_ctf_captimerecord_");
		BADPREFIX("g_hats_");
		BADPREFIX("g_maplist_");
		BADPREFIX("g_mod_");
		BADPREFIX("g_respawn_");
		BADPREFIX("net_");
		BADPREFIX("notification_");
		BADPREFIX("prvm_");
		BADPREFIX("skill_");
		BADPREFIX("sv_allow_");
		BADPREFIX("sv_cullentities_");
		BADPREFIX("sv_maxidle_");
		BADPREFIX("sv_minigames_");
		BADPREFIX("sv_radio_");
		BADPREFIX("sv_timeout_");
		BADPREFIX("sv_vote_");
		BADPREFIX("timelimit_");

		// allowed changes to server admins (please sync this to server.cfg)
		// vi commands:
		//   :/"impure"/,$d
		//   :g!,^\/\/[^ /],d
		//   :%s,//\([^ ]*\).*,BADCVAR("\1");,
		//   :%!sort
		// yes, this does contain some redundant stuff, don't really care
		BADCVAR("bot_config_file");
		BADCVAR("bot_number");
		BADCVAR("bot_prefix");
		BADCVAR("bot_suffix");
		BADCVAR("capturelimit_override");
		BADCVAR("fraglimit_override");
		BADCVAR("gametype");
		BADCVAR("g_antilag");
		BADCVAR("g_balance_teams");
		BADCVAR("g_balance_teams_prevent_imbalance");
		BADCVAR("g_balance_teams_scorefactor");
		BADCVAR("g_ban_sync_trusted_servers");
		BADCVAR("g_ban_sync_uri");
		BADCVAR("g_buffs");
		BADCVAR("g_ca_teams_override");
		BADCVAR("g_ctf_ignore_frags");
		BADCVAR("g_ctf_leaderboard");
		BADCVAR("g_domination_point_limit");
		BADCVAR("g_domination_teams_override");
		BADCVAR("g_freezetag_teams_override");
		BADCVAR("g_friendlyfire");
		BADCVAR("g_fullbrightitems");
		BADCVAR("g_fullbrightplayers");
		BADCVAR("g_keyhunt_point_limit");
		BADCVAR("g_keyhunt_teams_override");
		BADCVAR("g_lms_lives_override");
		BADCVAR("g_maplist");
		BADCVAR("g_maxplayers");
		BADCVAR("g_mirrordamage");
		BADCVAR("g_nexball_goallimit");
		BADCVAR("g_norecoil");
		BADCVAR("g_physics_clientselect");
		BADCVAR("g_pinata");
		BADCVAR("g_powerups");
		BADCVAR("g_spawnshieldtime");
		BADCVAR("g_start_delay");
		BADCVAR("g_superspectate");
		BADCVAR("g_tdm_teams_override");
		BADCVAR("g_warmup");
		BADCVAR("g_weapon_stay"); BADPRESUFFIX("g_", "_weapon_stay");
		BADCVAR("hostname");
		BADCVAR("log_file");
		BADCVAR("maxplayers");
		BADCVAR("minplayers");
		BADCVAR("minplayers_per_team");
		BADCVAR("net_address");
		BADCVAR("port");
		BADCVAR("rcon_password");
		BADCVAR("rcon_restricted_commands");
		BADCVAR("rcon_restricted_password");
		BADCVAR("skill");
		BADCVAR("sv_adminnick");
		BADCVAR("sv_autoscreenshot");
		BADCVAR("sv_autotaunt");
		BADCVAR("sv_curl_defaulturl");
		BADCVAR("sv_defaultcharacter");
		BADCVAR("sv_defaultcharacterskin");
		BADCVAR("sv_defaultplayercolors");
		BADCVAR("sv_defaultplayermodel");
		BADCVAR("sv_defaultplayerskin");
		BADCVAR("sv_maxidle");
		BADCVAR("sv_maxrate");
		BADCVAR("sv_motd");
		BADCVAR("sv_public");
		BADCVAR("sv_ready_restart");
		BADCVAR("sv_status_privacy");
		BADCVAR("sv_taunt");
		BADCVAR("sv_vote_call");
		BADCVAR("sv_vote_commands");
		BADCVAR("sv_vote_majority_factor");
		BADCVAR("sv_vote_master");
		BADCVAR("sv_vote_master_commands");
		BADCVAR("sv_vote_master_password");
		BADCVAR("sv_vote_simple_majority_factor");
		BADCVAR("teamplay_mode");
		BADCVAR("timelimit_override");
		BADPREFIX("g_warmup_");
		BADPREFIX("sv_info_");
		BADPREFIX("sv_ready_restart_");

		// mutators that announce themselves properly to the server browser
		BADCVAR("g_instagib");
		BADCVAR("g_new_toys");
		BADCVAR("g_nix");
		BADCVAR("g_grappling_hook");
		BADCVAR("g_jetpack");

#undef BADPRESUFFIX
#undef BADPREFIX
#undef BADCVAR

		if(pureadding)
		{
			cvar_purechanges = strcat(cvar_purechanges, k, " \"", v, "\" // \"", d, "\"\n");
			if(strlen(cvar_purechanges) > 16384)
			{
				cvar_purechanges = "// too many settings have been changed to show them here\n";
				pureadding = 0;
			}
		}
		++cvar_purechanges_count;
		// WARNING: this variable is used for the server list
		// NEVER dare to skip this code!
		// Hacks to intentionally appearing as "pure server" even though you DO have
		// modified settings may be punished by removal from the server list.
		// You can do to the variables cvar_changes and cvar_purechanges all you want,
		// though.
	}
	buf_del(h);
	if(cvar_changes == "")
		cvar_changes = "// this server runs at default server settings\n";
	else
		cvar_changes = strcat("// this server runs at modified server settings:\n", cvar_changes);
	cvar_changes = strzone(cvar_changes);
	if(cvar_purechanges == "")
		cvar_purechanges = "// this server runs at default gameplay settings\n";
	else
		cvar_purechanges = strcat("// this server runs at modified gameplay settings:\n", cvar_purechanges);
	cvar_purechanges = strzone(cvar_purechanges);
}

entity randomseed;
bool RandomSeed_Send(entity this, entity to, int sf)
{
	WriteHeader(MSG_ENTITY, ENT_CLIENT_RANDOMSEED);
	WriteShort(MSG_ENTITY, this.cnt);
	return true;
}
void RandomSeed_Think(entity this)
{
	this.cnt = bound(0, floor(random() * 65536), 65535);
	this.nextthink = time + 5;

	this.SendFlags |= 1;
}
void RandomSeed_Spawn()
{
	randomseed = new_pure(randomseed);
	setthink(randomseed, RandomSeed_Think);
	Net_LinkEntity(randomseed, false, 0, RandomSeed_Send);

	getthink(randomseed)(randomseed); // sets random seed and nextthink
}

spawnfunc(__init_dedicated_server)
{
	// handler for _init/_init map (only for dedicated server initialization)

	world_initialized = -1; // don't complain
	cvar = cvar_normal;
	cvar_string = cvar_string_normal;
	cvar_set = cvar_set_normal;

	delete_fn = remove_unsafely;

	entity e = spawn();
	setthink(e, GotoFirstMap);
	e.nextthink = time; // this is usually 1 at this point

	e = new(info_player_deathmatch);  // safeguard against player joining

    // assign reflectively to avoid "assignment to world" warning
    for (int i = 0, n = numentityfields(); i < n; ++i) {
        string k = entityfieldname(i);
        if (k == "classname") {
            // safeguard against various stuff ;)
            putentityfieldstring(i, this, "worldspawn");
            break;
        }
    }

	// needs to be done so early because of the constants they create
	static_init();
	static_init_late();
	static_init_precache();

	IL_PUSH(g_spawnpoints, e); // just incase

	MapInfo_Enumerate();
	MapInfo_FilterGametype(MapInfo_CurrentGametype(), MapInfo_CurrentFeatures(), MapInfo_RequiredFlags(), MapInfo_ForbiddenFlags(), 0);
}

void __init_dedicated_server_shutdown() {
	MapInfo_Shutdown();
}

STATIC_INIT_EARLY(maxclients)
{
	maxclients = 0;
	for (entity head = nextent(NULL); head; head = nextent(head)) {
		++maxclients;
	}
}

void default_delayedinit(entity this)
{
	if(!scores_initialized)
		ScoreRules_generic();
}

void InitGameplayMode()
{
	VoteReset();

	// find out good world mins/maxs bounds, either the static bounds found by looking for solid, or the mapinfo specified bounds
	get_mi_min_max(1);
	// assign reflectively to avoid "assignment to world" warning
	int done = 0; for (int i = 0, n = numentityfields(); i < n; ++i) {
	    string k = entityfieldname(i); vector v = (k == "mins") ? mi_min : (k == "maxs") ? mi_max : '0 0 0';
	    if (v) {
            putentityfieldstring(i, world, sprintf("%v", v));
            if (++done == 2) break;
        }
	}
	// currently, NetRadiant's limit is 131072 qu for each side
	// distance from one corner of a 131072qu cube to the opposite corner is approx. 227023 qu
	// set the distance according to map size but don't go over the limit to avoid issues with float precision
	// in case somebody makes extremely large maps
	max_shot_distance = min(230000, vlen(world.maxs - world.mins));

	MapInfo_LoadMapSettings(mapname);
	GameRules_teams(false);

	if (!cvar_value_issafe(world.fog))
	{
		LOG_INFO("The current map contains a potentially harmful fog setting, ignored");
		world.fog = string_null;
	}
	if(MapInfo_Map_fog != "")
	{
		if(MapInfo_Map_fog == "none")
			world.fog = string_null;
		else
			world.fog = strzone(MapInfo_Map_fog);
	}
	clientstuff = strzone(MapInfo_Map_clientstuff);

	MapInfo_ClearTemps();

	gamemode_name = MapInfo_Type_ToText(MapInfo_LoadedGametype);

	cache_mutatormsg = strzone("");
	cache_lastmutatormsg = strzone("");

	InitializeEntity(NULL, default_delayedinit, INITPRIO_GAMETYPE_FALLBACK);
}

void Map_MarkAsRecent(string m);
float world_already_spawned;
spawnfunc(worldspawn)
{
	server_is_dedicated = boolean(stof(cvar_defstring("is_dedicated")));

    bool wantrestart = false;
	{
		if (!server_is_dedicated)
		{
			// force unloading of server pk3 files when starting a listen server
			// localcmd("\nfs_rescan\n"); // FIXME: does more harm than good, has unintended side effects. What we really want is to unload temporary pk3s only
			// restore csqc_progname too
			string expect = "csprogs.dat";
			wantrestart = cvar_string_normal("csqc_progname") != expect;
			cvar_set_normal("csqc_progname", expect);
		}
		else
		{
			// Try to use versioned csprogs from pk3
			// Only ever use versioned csprogs.dat files on dedicated servers;
			// we need to reset csqc_progname on clients ourselves, and it's easier if the client's release name is constant
			string pk3csprogs = "csprogs-" WATERMARK ".dat";
			// This always works; fall back to it if a versioned csprogs.dat is suddenly missing
			string select = "csprogs.dat";
			if (fexists(pk3csprogs)) select = pk3csprogs;
			if (cvar_string_normal("csqc_progname") != select)
			{
				cvar_set_normal("csqc_progname", select);
				wantrestart = true;
			}
			// Check for updates on startup
			// We do it this way for atomicity so that connecting clients still match the server progs and don't disconnect
			int sentinel = fopen("progs.txt", FILE_READ);
			if (sentinel >= 0)
			{
				string switchversion = fgets(sentinel);
				fclose(sentinel);
				if (switchversion != "" && switchversion != WATERMARK)
				{
					LOG_INFOF("Switching progs: " WATERMARK " -> %s", switchversion);
					// if it doesn't exist, assume either:
					//   a) the current program was overwritten
					//   b) this is a client only update
					string newprogs = sprintf("progs-%s.dat", switchversion);
					if (fexists(newprogs))
					{
						cvar_set_normal("sv_progs", newprogs);
						wantrestart = true;
					}
					string newcsprogs = sprintf("csprogs-%s.dat", switchversion);
					if (fexists(newcsprogs))
					{
						cvar_set_normal("csqc_progname", newcsprogs);
						wantrestart = true;
					}
				}
			}
		}
		if (wantrestart)
		{
			LOG_INFOF("Restart requested");
			changelevel(mapname);
			// let initialization continue, shutdown depends on it
		}
	}

	cvar = cvar_normal;
	cvar_string = cvar_string_normal;
	cvar_set = cvar_set_normal;

	if(world_already_spawned)
		error("world already spawned - you may have EXACTLY ONE worldspawn!");
	world_already_spawned = true;

	delete_fn = remove_safely; // during spawning, watch what you remove!

	cvar_changes_init(); // do this very early now so it REALLY matches the server config

	// needs to be done so early because of the constants they create
	static_init();

	ServerProgsDB = db_load(strcat("server.db", autocvar_sessionid));

	TemporaryDB = db_create();

	// 0 normal
	lightstyle(0, "m");

	// 1 FLICKER (first variety)
	lightstyle(1, "mmnmmommommnonmmonqnmmo");

	// 2 SLOW STRONG PULSE
	lightstyle(2, "abcdefghijklmnopqrstuvwxyzyxwvutsrqponmlkjihgfedcba");

	// 3 CANDLE (first variety)
	lightstyle(3, "mmmmmaaaaammmmmaaaaaabcdefgabcdefg");

	// 4 FAST STROBE
	lightstyle(4, "mamamamamama");

	// 5 GENTLE PULSE 1
	lightstyle(5,"jklmnopqrstuvwxyzyxwvutsrqponmlkj");

	// 6 FLICKER (second variety)
	lightstyle(6, "nmonqnmomnmomomno");

	// 7 CANDLE (second variety)
	lightstyle(7, "mmmaaaabcdefgmmmmaaaammmaamm");

	// 8 CANDLE (third variety)
	lightstyle(8, "mmmaaammmaaammmabcdefaaaammmmabcdefmmmaaaa");

	// 9 SLOW STROBE (fourth variety)
	lightstyle(9, "aaaaaaaazzzzzzzz");

	// 10 FLUORESCENT FLICKER
	lightstyle(10, "mmamammmmammamamaaamammma");

	// 11 SLOW PULSE NOT FADE TO BLACK
	lightstyle(11, "abcdefghijklmnopqrrqponmlkjihgfedcba");

	// styles 32-62 are assigned by the spawnfunc_light program for switchable lights

	// 63 testing
	lightstyle(63, "a");

	if(autocvar_g_campaign)
		CampaignPreInit();

	Map_MarkAsRecent(mapname);

	PlayerStats_GameReport_Init(); // we need this to be initiated before InitGameplayMode

	InitGameplayMode();
	static_init_late();
	static_init_precache();
	readlevelcvars();
	GrappleHookInit();

    GameRules_limit_fallbacks();

	if(warmup_limit == 0)
		warmup_limit = (autocvar_timelimit > 0) ? autocvar_timelimit * 60 : autocvar_timelimit;

	player_count = 0;
	bot_waypoints_for_items = autocvar_g_waypoints_for_items;
	if(bot_waypoints_for_items == 1)
		if(this.spawnflags & SPAWNFLAG_NO_WAYPOINTS_FOR_ITEMS)
			bot_waypoints_for_items = 0;

	precache();

	WaypointSprite_Init();

	GameLogInit(); // prepare everything
	// NOTE for matchid:
	// changing the logic generating it is okay. But:
	// it HAS to stay <= 64 chars
	// character set: ASCII 33-126 without the following characters: : ; ' " \ $
	if(autocvar_sv_eventlog)
	{
		string s = sprintf("%d.%s.%06d", itos(autocvar_sv_eventlog_files_counter), strftime(false, "%s"), floor(random() * 1000000));
		matchid = strzone(s);

		GameLogEcho(strcat(":gamestart:", GetGametype(), "_", GetMapname(), ":", s));
		s = ":gameinfo:mutators:LIST";

		MUTATOR_CALLHOOK(BuildMutatorsString, s);
		s = M_ARGV(0, string);

		// initialiation stuff, not good in the mutator system
		if(!autocvar_g_use_ammunition)
			s = strcat(s, ":no_use_ammunition");

		// initialiation stuff, not good in the mutator system
		if(autocvar_g_pickup_items == 0)
			s = strcat(s, ":no_pickup_items");
		if(autocvar_g_pickup_items > 0)
			s = strcat(s, ":pickup_items");

		// initialiation stuff, not good in the mutator system
		if(autocvar_g_weaponarena != "0")
			s = strcat(s, ":", autocvar_g_weaponarena, " arena");

		// TODO to mutator system
		if(autocvar_g_norecoil)
			s = strcat(s, ":norecoil");

		// TODO to mutator system
		if(autocvar_g_powerups == 0)
			s = strcat(s, ":no_powerups");
		if(autocvar_g_powerups > 0)
			s = strcat(s, ":powerups");

		GameLogEcho(s);
		GameLogEcho(":gameinfo:end");
	}
	else
		matchid = strzone(ftos(random()));

	cvar_set("nextmap", "");

	SetDefaultAlpha();

	if(autocvar_g_campaign)
		CampaignPostInit();

	Ban_LoadBans();

	MapInfo_Enumerate();
	MapInfo_FilterGametype(MapInfo_CurrentGametype(), MapInfo_CurrentFeatures(), MapInfo_RequiredFlags(), MapInfo_ForbiddenFlags(), 1);

	if(whichpack(strcat("maps/", mapname, ".cfg")) != "")
	{
		int fd = fopen(strcat("maps/", mapname, ".cfg"), FILE_READ);
		if(fd != -1)
		{
			string s;
			while((s = fgets(fd)))
			{
				int l = tokenize_console(s);
				if(l < 2)
					continue;
				if(argv(0) == "cd")
				{
					LOG_INFO("Found ^1UNSUPPORTED^7 cd loop command in .cfg file; put this line in mapinfo instead:");
					LOG_INFO("  cdtrack ", argv(2));
				}
				else if(argv(0) == "fog")
				{
					LOG_INFO("Found ^1UNSUPPORTED^7 fog command in .cfg file; put this line in worldspawn in the .map/.bsp/.ent file instead:");
					LOG_INFO("  \"fog\" \"", s, "\"");
				}
				else if(argv(0) == "set")
				{
					LOG_INFO("Found ^1UNSUPPORTED^7 set command in .cfg file; put this line in mapinfo instead:");
					LOG_INFO("  clientsettemp_for_type all ", argv(1), " ", argv(2));
				}
				else if(argv(0) != "//")
				{
					LOG_INFO("Found ^1UNSUPPORTED^7 set command in .cfg file; put this line in mapinfo instead:");
					LOG_INFO("  clientsettemp_for_type all ", argv(0), " ", argv(1));
				}
			}
			fclose(fd);
		}
	}

	WeaponStats_Init();

	Nagger_Init();

	next_pingtime = time + 5;

	// set up information replies for clients and server to use
	maplist_reply = strzone(getmaplist());
	lsmaps_reply = strzone(getlsmaps());
	monsterlist_reply = strzone(getmonsterlist());
	for(int i = 0; i < 10; ++i)
	{
		string s = getrecords(i);
		if (s)
			records_reply[i] = strzone(s);
	}
	ladder_reply = strzone(getladder());
	rankings_reply = strzone(getrankings());

	// begin other init
	ClientInit_Spawn();
	RandomSeed_Spawn();
	PingPLReport_Spawn();

	CheatInit();

	if (!wantrestart) localcmd("\n_sv_hook_gamestart ", GetGametype(), "\n");

	// fill sv_curl_serverpackages from .serverpackage files
	if (autocvar_sv_curl_serverpackages_auto)
	{
		string s = "csprogs-" WATERMARK ".txt";
		// remove automatically managed files from the list to prevent duplicates
		for (int i = 0, n = tokenize_console(cvar_string("sv_curl_serverpackages")); i < n; ++i)
		{
			string pkg = argv(i);
			if (startsWith(pkg, "csprogs-")) continue;
			if (endsWith(pkg, "-serverpackage.txt")) continue;
			if (endsWith(pkg, ".serverpackage")) continue;  // OLD legacy
			s = cons(s, pkg);
		}
		// add automatically managed files to the list
		#define X(match) MACRO_BEGIN \
			int fd = search_begin(match, true, false); \
			if (fd >= 0) \
			{ \
				for (int i = 0, j = search_getsize(fd); i < j; ++i) \
				{ \
					s = cons(s, search_getfilename(fd, i)); \
				} \
				search_end(fd); \
			} \
		MACRO_END
		X("*-serverpackage.txt");
		X("*.serverpackage");
		#undef X
		cvar_set("sv_curl_serverpackages", s);
	}

	// MOD AUTHORS: change this, and possibly remove a few of the blocks below to ignore certain changes
	modname = "Xonotic";
	// physics/balance/config changes that count as mod
	if(cvar_string("g_mod_physics") != cvar_defstring("g_mod_physics"))
		modname = cvar_string("g_mod_physics");
	if(cvar_string("g_mod_balance") != cvar_defstring("g_mod_balance"))
		modname = cvar_string("g_mod_balance");
	if(cvar_string("g_mod_config") != cvar_defstring("g_mod_config"))
		modname = cvar_string("g_mod_config");
	// extra mutators that deserve to count as mod
	MUTATOR_CALLHOOK(SetModname, modname);
	modname = M_ARGV(0, string);

	// save it for later
	modname = strzone(modname);

	WinningConditionHelper(this); // set worldstatus

	world_initialized = 1;
	__spawnfunc_spawn_all();
}

spawnfunc(light)
{
	//makestatic (this); // Who the f___ did that?
	delete(this);
}

string GetGametype()
{
	return MapInfo_Type_ToString(MapInfo_LoadedGametype);
}

string GetMapname()
{
	return mapname;
}

float Map_Count, Map_Current;
string Map_Current_Name;

// NOTE: this now expects the map list to be already tokenized and the count in Map_Count
float GetMaplistPosition()
{
	float pos, idx;
	string map;

	map = GetMapname();
	idx = autocvar_g_maplist_index;

	if(idx >= 0)
		if(idx < Map_Count)
			if(map == argv(idx))
				return idx;

	for(pos = 0; pos < Map_Count; ++pos)
		if(map == argv(pos))
			return pos;

	// resume normal maplist rotation if current map is not in g_maplist
	return idx;
}

bool MapHasRightSize(string map)
{
	int minplayers = max(0, floor(autocvar_minplayers));
	if (teamplay)
		minplayers = max(0, floor(autocvar_minplayers_per_team) * AvailableTeams());
	if (autocvar_g_maplist_check_waypoints
		&& (currentbots || autocvar_bot_number || player_count < minplayers))
	{
		string checkwp_msg = strcat("checkwp ", map);
		if(!fexists(strcat("maps/", map, ".waypoints")))
		{
			LOG_TRACE(checkwp_msg, ": no waypoints");
			return false;
		}
		LOG_TRACE(checkwp_msg, ": has waypoints");
	}

	// open map size restriction file
	string opensize_msg = strcat("opensize ", map);
	float fh = fopen(strcat("maps/", map, ".sizes"), FILE_READ);
	if(fh >= 0)
	{
		opensize_msg = strcat(opensize_msg, ": ok, ");
		int mapmin = stoi(fgets(fh));
		int mapmax = stoi(fgets(fh));
		fclose(fh);
		if(player_count < mapmin)
		{
			LOG_TRACE(opensize_msg, "not enough");
			return false;
		}
		if(mapmax && player_count > mapmax)
		{
			LOG_TRACE(opensize_msg, "too many");
			return false;
		}
		LOG_TRACE(opensize_msg, "right size");
		return true;
	}
	LOG_TRACE(opensize_msg, ": not found");
	return true;
}

string Map_Filename(float position)
{
	return strcat("maps/", argv(position), ".bsp");
}

void Map_MarkAsRecent(string m)
{
	cvar_set("g_maplist_mostrecent", strwords(strcat(m, " ", autocvar_g_maplist_mostrecent), max(0, autocvar_g_maplist_mostrecent_count)));
}

float Map_IsRecent(string m)
{
	return strhasword(autocvar_g_maplist_mostrecent, m);
}

float Map_Check(float position, float pass)
{
	string filename;
	string map_next;
	map_next = argv(position);
	if(pass <= 1)
	{
		if(Map_IsRecent(map_next))
			return 0;
	}
	filename = Map_Filename(position);
	if(MapInfo_CheckMap(map_next))
	{
		if(pass == 2)
			return 1;
		if(MapHasRightSize(map_next))
			return 1;
		return 0;
	}
	else
		LOG_DEBUG( "Couldn't select '", filename, "'..." );

	return 0;
}

void Map_Goto_SetStr(string nextmapname)
{
	if(getmapname_stored != "")
		strunzone(getmapname_stored);
	if(nextmapname == "")
		getmapname_stored = "";
	else
		getmapname_stored = strzone(nextmapname);
}

void Map_Goto_SetFloat(float position)
{
	cvar_set("g_maplist_index", ftos(position));
	Map_Goto_SetStr(argv(position));
}

void Map_Goto(float reinit)
{
	MapInfo_LoadMap(getmapname_stored, reinit);
}

// return codes of map selectors:
//   -1 = temporary failure (that is, try some method that is guaranteed to succeed)
//   -2 = permanent failure
float MaplistMethod_Iterate() // usual method
{
	float pass, i;

	LOG_TRACE("Trying MaplistMethod_Iterate");

	for(pass = 1; pass <= 2; ++pass)
	{
		for(i = 1; i < Map_Count; ++i)
		{
			float mapindex;
			mapindex = (i + Map_Current) % Map_Count;
			if(Map_Check(mapindex, pass))
				return mapindex;
		}
	}
	return -1;
}

float MaplistMethod_Repeat() // fallback method
{
	LOG_TRACE("Trying MaplistMethod_Repeat");

	if(Map_Check(Map_Current, 2))
		return Map_Current;
	return -2;
}

float MaplistMethod_Random() // random map selection
{
	float i, imax;

	LOG_TRACE("Trying MaplistMethod_Random");

	imax = 42;

	for(i = 0; i <= imax; ++i)
	{
		float mapindex;
		mapindex = (Map_Current + floor(random() * (Map_Count - 1) + 1)) % Map_Count; // any OTHER map
		if(Map_Check(mapindex, 1))
			return mapindex;
	}
	return -1;
}

float MaplistMethod_Shuffle(float exponent) // more clever shuffling
// the exponent sets a bias on the map selection:
// the higher the exponent, the less likely "shortly repeated" same maps are
{
	float i, j, imax, insertpos;

	LOG_TRACE("Trying MaplistMethod_Shuffle");

	imax = 42;

	for(i = 0; i <= imax; ++i)
	{
		string newlist;

		// now reinsert this at another position
		insertpos = (random() ** (1 / exponent));       // ]0, 1]
		insertpos = insertpos * (Map_Count - 1);       // ]0, Map_Count - 1]
		insertpos = ceil(insertpos) + 1;               // {2, 3, 4, ..., Map_Count}
		LOG_TRACE("SHUFFLE: insert pos = ", ftos(insertpos));

		// insert the current map there
		newlist = "";
		for(j = 1; j < insertpos; ++j)                 // i == 1: no loop, will be inserted as first; however, i == 1 has been excluded above
			newlist = strcat(newlist, " ", argv(j));
		newlist = strcat(newlist, " ", argv(0));       // now insert the just selected map
		for(j = insertpos; j < Map_Count; ++j)         // i == Map_Count: no loop, has just been inserted as last
			newlist = strcat(newlist, " ", argv(j));
		newlist = substring(newlist, 1, strlen(newlist) - 1);
		cvar_set("g_maplist", newlist);
		Map_Count = tokenizebyseparator(autocvar_g_maplist, " ");

		// NOTE: the selected map has just been inserted at (insertpos-1)th position
		Map_Current = insertpos - 1; // this is not really valid, but this way the fallback has a chance of working
		if(Map_Check(Map_Current, 1))
			return Map_Current;
	}
	return -1;
}

void Maplist_Init()
{
	Map_Count = tokenizebyseparator(autocvar_g_maplist, " ");
	float i;
	for (i = 0; i < Map_Count; ++i)
		if (Map_Check(i, 2))
			break;
	if (i == Map_Count)
	{
		bprint( "Maplist contains no usable maps!  Resetting it to default map list.\n" );
		cvar_set("g_maplist", MapInfo_ListAllAllowedMaps(MapInfo_RequiredFlags(), MapInfo_ForbiddenFlags() | MAPINFO_FLAG_NOAUTOMAPLIST));
		if(autocvar_g_maplist_shuffle)
			ShuffleMaplist();
		localcmd("\nmenu_cmd sync\n");
		Map_Count = tokenizebyseparator(autocvar_g_maplist, " ");
	}
	if(Map_Count == 0)
		error("empty maplist, cannot select a new map");
	Map_Current = bound(0, GetMaplistPosition(), Map_Count - 1);

	strcpy(Map_Current_Name, argv(Map_Current)); // will be automatically freed on exit thanks to DP
	// this may or may not be correct, but who cares, in the worst case a map
	// isn't chosen in the first pass that should have been
}

string GetNextMap()
{
	float nextMap;

	Maplist_Init();
	nextMap = -1;

	if(nextMap == -1)
		if(autocvar_g_maplist_shuffle > 0)
			nextMap = MaplistMethod_Shuffle(autocvar_g_maplist_shuffle + 1);

	if(nextMap == -1)
		if(autocvar_g_maplist_selectrandom)
			nextMap = MaplistMethod_Random();

	if(nextMap == -1)
		nextMap = MaplistMethod_Iterate();

	if(nextMap == -1)
		nextMap = MaplistMethod_Repeat();

	if(nextMap >= 0)
	{
		Map_Goto_SetFloat(nextMap);
		return getmapname_stored;
	}

	return "";
}

float DoNextMapOverride(float reinit)
{
	if(autocvar_g_campaign)
	{
		CampaignPostIntermission();
		alreadychangedlevel = true;
		return true;
	}
	if(autocvar_quit_when_empty)
	{
		if(player_count <= currentbots)
		{
			localcmd("quit\n");
			alreadychangedlevel = true;
			return true;
		}
	}
	if(autocvar_quit_and_redirect != "")
	{
		redirection_target = strzone(autocvar_quit_and_redirect);
		alreadychangedlevel = true;
		return true;
	}
	if (!reinit && autocvar_samelevel) // if samelevel is set, stay on same level
	{
		localcmd("restart\n");
		alreadychangedlevel = true;
		return true;
	}
	if(autocvar_nextmap != "")
	{
		string m;
		m = GameTypeVote_MapInfo_FixName(autocvar_nextmap);
		cvar_set("nextmap",m);

		if(!m || gametypevote)
			return false;
		if(autocvar_sv_vote_gametype)
		{
			Map_Goto_SetStr(m);
			return false;
		}

		if(MapInfo_CheckMap(m))
		{
			Map_Goto_SetStr(m);
			Map_Goto(reinit);
			alreadychangedlevel = true;
			return true;
		}
	}
	if(!reinit && autocvar_lastlevel)
	{
		cvar_settemp_restore();
		localcmd("set lastlevel 0\ntogglemenu 1\n");
		alreadychangedlevel = true;
		return true;
	}
	return false;
}

void GotoNextMap(float reinit)
{
	//string nextmap;
	//float n, nummaps;
	//string s;
	if (alreadychangedlevel)
		return;
	alreadychangedlevel = true;

	string nextMap;

	nextMap = GetNextMap();
	if(nextMap == "")
		error("Everything is broken - cannot find a next map. Please report this to the developers.");
	Map_Goto(reinit);
}


/*
============
IntermissionThink

When the player presses attack or jump, change to the next level
============
*/
.float autoscreenshot;
void IntermissionThink(entity this)
{
	FixIntermissionClient(this);

	float server_screenshot = (autocvar_sv_autoscreenshot && CS(this).cvar_cl_autoscreenshot);
	float client_screenshot = (CS(this).cvar_cl_autoscreenshot == 2);

	if( (server_screenshot || client_screenshot)
		&& ((this.autoscreenshot > 0) && (time > this.autoscreenshot)) )
	{
		this.autoscreenshot = -1;
		if(IS_REAL_CLIENT(this)) { stuffcmd(this, sprintf("\nscreenshot screenshots/autoscreenshot/%s-%s.jpg; echo \"^5A screenshot has been taken at request of the server.\"\n", GetMapname(), strftime(false, "%s"))); }
		return;
	}

	if (time < intermission_exittime)
		return;

	if(!mapvote_initialized)
		if (time < intermission_exittime + 10 && !(PHYS_INPUT_BUTTON_ATCK(this) || PHYS_INPUT_BUTTON_JUMP(this) || PHYS_INPUT_BUTTON_ATCK2(this) || PHYS_INPUT_BUTTON_HOOK(this) || PHYS_INPUT_BUTTON_USE(this)))
			return;

	MapVote_Start();
}

/*
============
FindIntermission

Returns the entity to view from
============
*/
/*
entity FindIntermission()
{
	local	entity spot;
	local	float cyc;

// look for info_intermission first
	spot = find(NULL, classname, "info_intermission");
	if (spot)
	{	// pick a random one
		cyc = random() * 4;
		while (cyc > 1)
		{
			spot = find(spot, classname, "info_intermission");
			if (!spot)
				spot = find(spot, classname, "info_intermission");
			cyc = cyc - 1;
		}
		return spot;
	}

// then look for the start position
	spot = find(NULL, classname, "info_player_start");
	if (spot)
		return spot;

// testinfo_player_start is only found in regioned levels
	spot = find(NULL, classname, "testplayerstart");
	if (spot)
		return spot;

// then look for the start position
	spot = find(NULL, classname, "info_player_deathmatch");
	if (spot)
		return spot;

	//objerror ("FindIntermission: no spot");
	return NULL;
}
*/

/*
===============================================================================

RULES

===============================================================================
*/

void DumpStats(float final)
{
	float file;
	string s;
	float to_console;
	float to_eventlog;
	float to_file;
	float i;

	to_console = autocvar_sv_logscores_console;
	to_eventlog = autocvar_sv_eventlog;
	to_file = autocvar_sv_logscores_file;

	if(!final)
	{
		to_console = true; // always print printstats replies
		to_eventlog = false; // but never print them to the event log
	}

	if(to_eventlog)
		if(autocvar_sv_eventlog_console)
			to_console = false; // otherwise we get the output twice

	if(final)
		s = ":scores:";
	else
		s = ":status:";
	s = strcat(s, GetGametype(), "_", GetMapname(), ":", ftos(rint(time)));

	if(to_console)
		LOG_INFO(s);
	if(to_eventlog)
		GameLogEcho(s);

	file = -1;
	if(to_file)
	{
		file = fopen(autocvar_sv_logscores_filename, FILE_APPEND);
		if(file == -1)
			to_file = false;
		else
			fputs(file, strcat(s, "\n"));
	}

	s = strcat(":labels:player:", GetPlayerScoreString(NULL, 0));
	if(to_console)
		LOG_INFO(s);
	if(to_eventlog)
		GameLogEcho(s);
	if(to_file)
		fputs(file, strcat(s, "\n"));

	FOREACH_CLIENT(IS_REAL_CLIENT(it) || (IS_BOT_CLIENT(it) && autocvar_sv_logscores_bots), {
		s = strcat(":player:see-labels:", GetPlayerScoreString(it, 0), ":");
		s = strcat(s, ftos(rint(time - CS(it).jointime)), ":");
		if(IS_PLAYER(it) || MUTATOR_CALLHOOK(GetPlayerStatus, it))
			s = strcat(s, ftos(it.team), ":");
		else
			s = strcat(s, "spectator:");

		if(to_console)
			LOG_INFO(s, playername(it, false));
		if(to_eventlog)
			GameLogEcho(strcat(s, ftos(it.playerid), ":", playername(it, false)));
		if(to_file)
			fputs(file, strcat(s, playername(it, false), "\n"));
	});

	if(teamplay)
	{
		s = strcat(":labels:teamscores:", GetTeamScoreString(0, 0));
		if(to_console)
			LOG_INFO(s);
		if(to_eventlog)
			GameLogEcho(s);
		if(to_file)
			fputs(file, strcat(s, "\n"));

		for(i = 1; i < 16; ++i)
		{
			s = strcat(":teamscores:see-labels:", GetTeamScoreString(i, 0));
			s = strcat(s, ":", ftos(i));
			if(to_console)
				LOG_INFO(s);
			if(to_eventlog)
				GameLogEcho(s);
			if(to_file)
				fputs(file, strcat(s, "\n"));
		}
	}

	if(to_console)
		LOG_INFO(":end");
	if(to_eventlog)
		GameLogEcho(":end");
	if(to_file)
	{
		fputs(file, ":end\n");
		fclose(file);
	}
}

void FixIntermissionClient(entity e)
{
	if(!e.autoscreenshot) // initial call
	{
		e.autoscreenshot = time + 0.8;	// used for autoscreenshot
		SetResourceExplicit(e, RES_HEALTH, -2342);
		// first intermission phase; voting phase has positive health (used to decide whether to send SVC_FINALE or not)
		for (int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
		{
		    .entity weaponentity = weaponentities[slot];
			if(e.(weaponentity))
			{
				e.(weaponentity).effects = EF_NODRAW;
				if (e.(weaponentity).weaponchild)
					e.(weaponentity).weaponchild.effects = EF_NODRAW;
			}
		}
		if(IS_REAL_CLIENT(e))
		{
			stuffcmd(e, "\nscr_printspeed 1000000\n");
			RandomSelection_Init();
			FOREACH_WORD(autocvar_sv_intermission_cdtrack, true, {
				RandomSelection_AddString(it, 1, 1);
			});
			if (RandomSelection_chosen_string != "")
			{
				stuffcmd(e, sprintf("\ncd loop %s\n", RandomSelection_chosen_string));
			}
			msg_entity = e;
			WriteByte(MSG_ONE, SVC_INTERMISSION);
		}
	}
}

/*
go to the next level for deathmatch
only called if a time or frag limit has expired
*/
void NextLevel()
{
	game_stopped = true;
	intermission_running = 1; // game over

	// enforce a wait time before allowing changelevel
	if(player_count > 0)
		intermission_exittime = time + autocvar_sv_mapchange_delay;
	else
		intermission_exittime = -1;

	/*
	WriteByte (MSG_ALL, SVC_CDTRACK);
	WriteByte (MSG_ALL, 3);
	WriteByte (MSG_ALL, 3);
	// done in FixIntermission
	*/

	//pos = FindIntermission ();

	VoteReset();

	DumpStats(true);

	// send statistics
	PlayerStats_GameReport(true);
	WeaponStats_Shutdown();

	Kill_Notification(NOTIF_ALL, NULL, MSG_CENTER, CPID_Null); // kill all centerprints now

	if(autocvar_sv_eventlog)
		GameLogEcho(":gameover");

	GameLogClose();

	FOREACH_CLIENT(IS_PLAYER(it), {
		FixIntermissionClient(it);
		if(it.winning)
			bprint(playername(it, false), " ^7wins.\n");
	});

	target_music_kill();

	if(autocvar_g_campaign)
		CampaignPreIntermission();

	MUTATOR_CALLHOOK(MatchEnd);

	localcmd("\nsv_hook_gameend\n");
}


float InitiateSuddenDeath()
{
	// Check first whether normal overtimes could be added before initiating suddendeath mode
	// - for this timelimit_overtime needs to be >0 of course
	// - also check the winning condition calculated in the previous frame and only add normal overtime
	//   again, if at the point at which timelimit would be extended again, still no winner was found
	if (!autocvar_g_campaign && checkrules_overtimesadded >= 0
		&& (checkrules_overtimesadded < autocvar_timelimit_overtimes || autocvar_timelimit_overtimes < 0)
		&& autocvar_timelimit_overtime && !(g_race && !g_race_qualifying))
	{
		return 1; // need to call InitiateOvertime later
	}
	else
	{
		if(!checkrules_suddendeathend)
		{
			if(autocvar_g_campaign)
				checkrules_suddendeathend = time; // no suddendeath in campaign
			else
				checkrules_suddendeathend = time + 60 * autocvar_timelimit_suddendeath;
			if(g_race && !g_race_qualifying)
				race_StartCompleting();
		}
		return 0;
	}
}

void InitiateOvertime() // ONLY call this if InitiateSuddenDeath returned true
{
	++checkrules_overtimesadded;
	//add one more overtime by simply extending the timelimit
	cvar_set("timelimit", ftos(autocvar_timelimit + autocvar_timelimit_overtime));
	Send_Notification(NOTIF_ALL, NULL, MSG_CENTER, CENTER_OVERTIME_TIME, autocvar_timelimit_overtime * 60);
}

float GetWinningCode(float fraglimitreached, float equality)
{
	if(autocvar_g_campaign == 1)
	{
		if(fraglimitreached)
			return WINNING_YES;
		else
			return WINNING_NO;
	}
	else
	{
		if(equality)
		{
			if(fraglimitreached)
				return WINNING_STARTSUDDENDEATHOVERTIME;
			else
				return WINNING_NEVER;
		}
		else
		{
			if(fraglimitreached)
				return WINNING_YES;
			else
				return WINNING_NO;
		}
	}
}

// set the .winning flag for exactly those players with a given field value
void SetWinners(.float field, float value)
{
	FOREACH_CLIENT(IS_PLAYER(it), { it.winning = (it.(field) == value); });
}

// set the .winning flag for those players with a given field value
void AddWinners(.float field, float value)
{
	FOREACH_CLIENT(IS_PLAYER(it), {
		if(it.(field) == value)
			it.winning = 1;
	});
}

// clear the .winning flags
void ClearWinners()
{
	FOREACH_CLIENT(IS_PLAYER(it), { it.winning = 0; });
}

void ShuffleMaplist()
{
	cvar_set("g_maplist", shufflewords(autocvar_g_maplist));
}

float leaderfrags;
float WinningCondition_Scores(float limit, float leadlimit)
{
	float limitreached;

	// TODO make everything use THIS winning condition (except LMS)
	WinningConditionHelper(NULL);

	if(teamplay)
	{
		for (int i = 1; i < 5; ++i)
		{
			Team_SetTeamScore(Team_GetTeamFromIndex(i),
				TeamScore_GetCompareValue(Team_IndexToTeam(i)));
		}
	}

	ClearWinners();
	if(WinningConditionHelper_winner)
		WinningConditionHelper_winner.winning = 1;
	if(WinningConditionHelper_winnerteam >= 0)
		SetWinners(team, WinningConditionHelper_winnerteam);

	if(WinningConditionHelper_lowerisbetter)
	{
		WinningConditionHelper_topscore = -WinningConditionHelper_topscore;
		WinningConditionHelper_secondscore = -WinningConditionHelper_secondscore;
		limit = -limit;
	}

	if(WinningConditionHelper_zeroisworst)
		leadlimit = 0; // not supported in this mode

	if(MUTATOR_CALLHOOK(Scores_CountFragsRemaining))
	// these modes always score in increments of 1, thus this makes sense
	{
		if(leaderfrags != WinningConditionHelper_topscore)
		{
			leaderfrags = WinningConditionHelper_topscore;

			if (limit)
			{
				if (leaderfrags == limit - 1)
					Send_Notification(NOTIF_ALL, NULL, MSG_ANNCE, ANNCE_REMAINING_FRAG_1);
				else if (leaderfrags == limit - 2)
					Send_Notification(NOTIF_ALL, NULL, MSG_ANNCE, ANNCE_REMAINING_FRAG_2);
				else if (leaderfrags == limit - 3)
					Send_Notification(NOTIF_ALL, NULL, MSG_ANNCE, ANNCE_REMAINING_FRAG_3);
			}
		}
	}

	limitreached = false;
	if (limit && WinningConditionHelper_topscore >= limit)
		limitreached = true;
	if(leadlimit)
	{
		float leadlimitreached;
		leadlimitreached = (WinningConditionHelper_topscore - WinningConditionHelper_secondscore >= leadlimit);
		if(autocvar_leadlimit_and_fraglimit)
			limitreached = (limitreached && leadlimitreached);
		else
			limitreached = (limitreached || leadlimitreached);
	}

	if(limit)
		game_completion_ratio = max(game_completion_ratio, bound(0, WinningConditionHelper_topscore / limit, 1));

	return GetWinningCode(
		WinningConditionHelper_topscore && limitreached,
		WinningConditionHelper_equality
	);
}

float WinningCondition_RanOutOfSpawns()
{
	if(have_team_spawns <= 0)
		return WINNING_NO;

	if(!autocvar_g_spawn_useallspawns)
		return WINNING_NO;

	if(!some_spawn_has_been_used)
		return WINNING_NO;

	for (int i = 1; i < 5; ++i)
	{
		Team_SetTeamScore(Team_GetTeamFromIndex(i), 0);
	}

	FOREACH_CLIENT(IS_PLAYER(it) && !IS_DEAD(it),
	{
		if (Team_IsValidTeam(it.team))
		{
			Team_SetTeamScore(Team_GetTeam(it.team), 1);
		}
	});

	IL_EACH(g_spawnpoints, true,
	{
		if (Team_IsValidTeam(it.team))
		{
			Team_SetTeamScore(Team_GetTeam(it.team), 1);
		}
	});

	ClearWinners();
	float team1_score = Team_GetTeamScore(Team_GetTeamFromIndex(1));
	float team2_score = Team_GetTeamScore(Team_GetTeamFromIndex(2));
	float team3_score = Team_GetTeamScore(Team_GetTeamFromIndex(3));
	float team4_score = Team_GetTeamScore(Team_GetTeamFromIndex(4));
	if(team1_score + team2_score + team3_score + team4_score == 0)
	{
		checkrules_equality = true;
		return WINNING_YES;
	}
	else if(team1_score + team2_score + team3_score + team4_score == 1)
	{
		float t, i;
		if(team1_score)
			t = 1;
		else if(team2_score)
			t = 2;
		else if(team3_score)
			t = 3;
		else // if(team4_score)
			t = 4;
		entity balance = TeamBalance_CheckAllowedTeams(NULL);
		for(i = 0; i < MAX_TEAMSCORE; ++i)
		{
			for (int j = 1; j <= NUM_TEAMS; ++j)
			{
				if (t == j)
				{
					continue;
				}
				if (!TeamBalance_IsTeamAllowed(balance, j))
				{
					continue;
				}
				TeamScore_AddToTeam(Team_IndexToTeam(j), i, -1000);
			}
		}

		AddWinners(team, t);
		return WINNING_YES;
	}
	else
		return WINNING_NO;
}

/*
============
CheckRules_World

Exit deathmatch games upon conditions
============
*/
void CheckRules_World()
{
	float timelimit;
	float fraglimit;
	float leadlimit;

	VoteThink();
	MapVote_Think();

	SetDefaultAlpha();

	if (intermission_running) // someone else quit the game already
	{
		if(player_count == 0) // Nobody there? Then let's go to the next map
			MapVote_Start();
			// this will actually check the player count in the next frame
			// again, but this shouldn't hurt
		return;
	}

	timelimit = autocvar_timelimit * 60;
	fraglimit = autocvar_fraglimit;
	leadlimit = autocvar_leadlimit;

	if(warmup_stage || time <= game_starttime) // NOTE: this is <= to prevent problems in the very tic where the game starts
	{
		if(timelimit > 0)
			timelimit = 0; // timelimit is not made for warmup
		if(fraglimit > 0)
			fraglimit = 0; // no fraglimit for now
		leadlimit = 0; // no leadlimit for now
	}

	if(timelimit > 0)
	{
		timelimit += game_starttime;
	}
	else if (timelimit < 0)
	{
		// endmatch
		NextLevel();
		return;
	}

	float wantovertime;
	wantovertime = 0;

	if(timelimit > game_starttime)
		game_completion_ratio = (time - game_starttime) / (timelimit - game_starttime);
	else
		game_completion_ratio = 0;

	if(checkrules_suddendeathend)
	{
		if(!checkrules_suddendeathwarning)
		{
			checkrules_suddendeathwarning = true;
			if(g_race && !g_race_qualifying)
				Send_Notification(NOTIF_ALL, NULL, MSG_CENTER, CENTER_RACE_FINISHLAP);
			else
				Send_Notification(NOTIF_ALL, NULL, MSG_CENTER, CENTER_OVERTIME_FRAG);
		}
	}
	else
	{
		if (timelimit && time >= timelimit)
		{
			if(g_race && (g_race_qualifying == 2) && timelimit > 0)
			{
				float totalplayers;
				float playerswithlaps;
				float readyplayers;
				totalplayers = playerswithlaps = readyplayers = 0;
				FOREACH_CLIENT(IS_PLAYER(it), {
					++totalplayers;
					if(GameRules_scoring_add(it, RACE_FASTEST, 0))
						++playerswithlaps;
					if(it.ready)
						++readyplayers;
				});

				// at least 2 of the players have completed a lap: start the RACE
				// otherwise, the players should end the qualifying on their own
				if(readyplayers || playerswithlaps >= 2)
				{
					checkrules_suddendeathend = 0;
					ReadyRestart(); // go to race
					return;
				}
				else
					wantovertime |= InitiateSuddenDeath();
			}
			else
				wantovertime |= InitiateSuddenDeath();
		}
	}

	if (checkrules_suddendeathend && time >= checkrules_suddendeathend)
	{
		NextLevel();
		return;
	}

	int checkrules_status = WinningCondition_RanOutOfSpawns();
	if(checkrules_status == WINNING_YES)
		bprint("Hey! Someone ran out of spawns!\n");
	else if(MUTATOR_CALLHOOK(CheckRules_World, checkrules_status, timelimit, fraglimit))
		checkrules_status = M_ARGV(0, float);
	else
		checkrules_status = WinningCondition_Scores(fraglimit, leadlimit);

	if(checkrules_status == WINNING_STARTSUDDENDEATHOVERTIME)
	{
		checkrules_status = WINNING_NEVER;
		checkrules_overtimesadded = -1;
		wantovertime |= InitiateSuddenDeath();
	}

	if(checkrules_status == WINNING_NEVER)
		// equality cases! Nobody wins if the overtime ends in a draw.
		ClearWinners();

	if(wantovertime)
	{
		if(checkrules_status == WINNING_NEVER)
			InitiateOvertime();
		else
			checkrules_status = WINNING_YES;
	}

	if(checkrules_suddendeathend)
		if(checkrules_status != WINNING_NEVER || time >= checkrules_suddendeathend)
			checkrules_status = WINNING_YES;

	if(checkrules_status == WINNING_YES)
	{
		//print("WINNING\n");
		NextLevel();
	}
}

string GotoMap(string m)
{
	m = GameTypeVote_MapInfo_FixName(m);
	if (!m)
		return "The map you suggested is not available on this server.";
	if (!autocvar_sv_vote_gametype)
	if(!MapInfo_CheckMap(m))
		return "The map you suggested does not support the current game mode.";
	cvar_set("nextmap", m);
	cvar_set("timelimit", "-1");
	if(mapvote_initialized || alreadychangedlevel)
	{
		if(DoNextMapOverride(0))
			return "Map switch initiated.";
		else
			return "Hm... no. For some reason I like THIS map more.";
	}
	else
		return "Map switch will happen after scoreboard.";
}

bool autocvar_sv_gameplayfix_multiplethinksperframe;
void RunThink(entity this)
{
	// don't let things stay in the past.
	// it is possible to start that way by a trigger with a local time.
	if(this.nextthink <= 0 || this.nextthink > time + frametime)
		return;

	float oldtime = time; // do we need to save this?

	for (int iterations = 0; iterations < 128 && !wasfreed(this); iterations++)
	{
		time = max(oldtime, this.nextthink);
		this.nextthink = 0;

		if(getthink(this))
			getthink(this)(this);
		// mods often set nextthink to time to cause a think every frame,
		// we don't want to loop in that case, so exit if the new nextthink is
		// <= the time the qc was told, also exit if it is past the end of the
		// frame
		if(this.nextthink <= time || this.nextthink > oldtime + frametime || !autocvar_sv_gameplayfix_multiplethinksperframe)
			break;
	}

	time = oldtime;
}

bool autocvar_sv_freezenonclients;
bool autocvar_sv_gameplayfix_delayprojectiles;
void Physics_Frame()
{
	if(autocvar_sv_freezenonclients)
		return;

	FOREACH_ENTITY_FLOAT(pure_data, false,
	{
		if(IS_CLIENT(it) || it.classname == "" || it.move_movetype == MOVETYPE_PUSH || it.move_movetype == MOVETYPE_FAKEPUSH || it.move_movetype == MOVETYPE_PHYSICS)
			continue;

		//set_movetype(it, it.move_movetype);
		// inline the set_movetype function, since this is called a lot
		it.movetype = (it.move_qcphysics) ? MOVETYPE_NONE : it.move_movetype;

		if(it.move_movetype == MOVETYPE_NONE)
			continue;

		if(it.move_qcphysics)
			Movetype_Physics_NoMatchTicrate(it, PHYS_INPUT_TIMELENGTH, false);

		if(it.movetype >= MOVETYPE_USER_FIRST && it.movetype <= MOVETYPE_USER_LAST) // these cases have no think handling
		{
			// handle thinking here
			if (getthink(it) && it.nextthink > 0 && it.nextthink <= time + frametime)
				RunThink(it);
		}
	});

	if(autocvar_sv_gameplayfix_delayprojectiles >= 0)
		return;

	FOREACH_ENTITY_FLOAT(move_qcphysics, true,
	{
		if(IS_CLIENT(it) || is_pure(it) || it.classname == "" || it.move_movetype == MOVETYPE_NONE)
			continue;
		Movetype_Physics_NoMatchTicrate(it, PHYS_INPUT_TIMELENGTH, false);
	});
}

void systems_update();
void EndFrame()
{
	anticheat_endframe();

	Physics_Frame();

	FOREACH_CLIENT(IS_REAL_CLIENT(it), {
		entity e = IS_SPEC(it) ? it.enemy : it;
		if (e.typehitsound) {
			STAT(TYPEHIT_TIME, it) = time;
		} else if (e.killsound) {
			STAT(KILL_TIME, it) = time;
		} else if (e.damage_dealt) {
			STAT(HIT_TIME, it) = time;
			STAT(DAMAGE_DEALT_TOTAL, it) += ceil(e.damage_dealt);
		}
	});
	// add 1 frametime because after this, engine SV_Physics
	// increases time by a frametime and then networks the frame
	// add another frametime because client shows everything with
	// 1 frame of lag (cl_nolerp 0). The last +1 however should not be
	// needed!
	float altime = time + frametime * (1 + autocvar_g_antilag_nudge);
	FOREACH_CLIENT(true, {
		it.typehitsound = false;
		it.damage_dealt = 0;
		it.killsound = false;
		antilag_record(it, CS(it), altime);
	});
	IL_EACH(g_monsters, true,
	{
		antilag_record(it, it, altime);
	});
	IL_EACH(g_projectiles, it.classname == "nade",
	{
		antilag_record(it, it, altime);
	});
	systems_update();
	IL_ENDFRAME();
}


/*
 * RedirectionThink:
 * returns true if redirecting
 */
float redirection_timeout;
float redirection_nextthink;
float RedirectionThink()
{
	float clients_found;

	if(redirection_target == "")
		return false;

	if(!redirection_timeout)
	{
		cvar_set("sv_public", "-2");
		redirection_timeout = time + 0.6; // this will only try twice... should be able to keep more clients
		if(redirection_target == "self")
			bprint("^3SERVER NOTICE:^7 restarting the server\n");
		else
			bprint("^3SERVER NOTICE:^7 redirecting everyone to ", redirection_target, "\n");
	}

	if(time < redirection_nextthink)
		return true;

	redirection_nextthink = time + 1;

	clients_found = 0;
	FOREACH_CLIENT(IS_REAL_CLIENT(it), {
		// TODO add timer
		LOG_INFO("Redirecting: sending connect command to ", it.netname);
		if(redirection_target == "self")
			stuffcmd(it, "\ndisconnect; defer ", ftos(autocvar_quit_and_redirect_timer), " reconnect\n");
		else
			stuffcmd(it, strcat("\ndisconnect; defer ", ftos(autocvar_quit_and_redirect_timer), " \"connect ", redirection_target, "\"\n"));
		++clients_found;
	});

	LOG_INFO("Redirecting: ", ftos(clients_found), " clients left.");

	if(time > redirection_timeout || clients_found == 0)
		localcmd("\nwait; wait; wait; quit\n");

	return true;
}

void RestoreGame()
{
	// Loaded from a save game
	// some things then break, so let's work around them...

	// Progs DB (capture records)
	ServerProgsDB = db_load(strcat("server.db", autocvar_sessionid));

	// Mapinfo
	MapInfo_Shutdown();
	MapInfo_Enumerate();
	MapInfo_FilterGametype(MapInfo_CurrentGametype(), MapInfo_CurrentFeatures(), MapInfo_RequiredFlags(), MapInfo_ForbiddenFlags(), 1);
	WeaponStats_Init();

	TargetMusic_RestoreGame();
}

void Shutdown()
{
	game_stopped = 2;

	if(world_initialized > 0)
	{
		world_initialized = 0;
		LOG_TRACE("Saving persistent data...");
		Ban_SaveBans();

		// playerstats with unfinished match
		PlayerStats_GameReport(false);

		if(!cheatcount_total)
		{
			if(autocvar_sv_db_saveasdump)
				db_dump(ServerProgsDB, strcat("server.db", autocvar_sessionid));
			else
				db_save(ServerProgsDB, strcat("server.db", autocvar_sessionid));
		}
		if(autocvar_developer)
		{
			if(autocvar_sv_db_saveasdump)
				db_dump(TemporaryDB, "server-temp.db");
			else
				db_save(TemporaryDB, "server-temp.db");
		}
		CheatShutdown(); // must be after cheatcount check
		db_close(ServerProgsDB);
		db_close(TemporaryDB);
		LOG_TRACE("Saving persistent data... done!");
		// tell the bot system the game is ending now
		bot_endgame();

		WeaponStats_Shutdown();
		MapInfo_Shutdown();
	}
	else if(world_initialized == 0)
	{
		LOG_INFO("NOTE: crashed before even initializing the world, not saving persistent data");
	}
	else
	{
		__init_dedicated_server_shutdown();
	}
}
