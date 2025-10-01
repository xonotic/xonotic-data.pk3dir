#include "world.qh"

#include <common/checkextension.qh>
#include <common/constants.qh>
#include <common/deathtypes/all.qh>
#include <common/gametypes/_mod.qh>
#include <common/gametypes/sv_rules.qh>
#include <common/items/_mod.qh>
#include <common/mapinfo.qh>
#include <common/mapobjects/target/music.qh>
#include <common/mapobjects/trigger/hurt.qh>
#include <common/mapobjects/trigger/secret.qh>
#include <common/mapobjects/triggers.qh>
#include <common/monsters/_mod.qh>
#include <common/monsters/sv_monsters.qh>
#include <common/mutators/mutator/powerups/_mod.qh>
#include <common/net_linked.qh>
#include <common/notifications/all.qh>
#include <common/physics/player.qh>
#include <common/playerstats.qh>
#include <common/state.qh>
#include <common/stats.qh>
#include <common/teams.qh>
#include <common/util.qh>
#include <common/vehicles/all.qh>
#include <common/weapons/_all.qh>
#include <lib/warpzone/common.qh>
#include <server/anticheat.qh>
#include <server/antilag.qh>
#include <server/bot/api.qh>
#include <server/campaign.qh>
#include <server/cheats.qh>
#include <server/client.qh>
#include <server/command/common.qh>
#include <server/command/getreplies.qh>
#include <server/command/sv_cmd.qh>
#include <server/command/vote.qh>
#include <server/damage.qh>
#include <server/gamelog.qh>
#include <server/hook.qh>
#include <server/ipban.qh>
#include <server/items/items.qh>
#include <server/main.qh>
#include <server/mapvoting.qh>
#include <server/mutators/_mod.qh>
#include <server/race.qh>
#include <server/scores.qh>
#include <server/scores_rules.qh>
#include <server/spawnpoints.qh>
#include <server/teamplay.qh>
#include <server/weapons/weaponstats.qh>

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
		WriteShort(MSG_BROADCAST, bound(1, rint(CS(e).ping), 32767));
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
		// to this "init" map on a dedicated server will cause no permanent harm

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

#define BADPREFIX_COND(p) (substring(k, 0, strlen(p)) == p)
#define BADSUFFIX_COND(s) (substring(k, -strlen(s), -1) == s)

#define BADPREFIX(p) if(BADPREFIX_COND(p)) continue
#define BADPRESUFFIX(p, s) if(BADPREFIX_COND(p) && BADSUFFIX_COND(s)) continue
#define BADCVAR(p) if(k == p) continue
#define BADVALUE(p, val) if (k == p && v == val) continue
#define BADPRESUFFIXVALUE(p, s, val) if(BADPREFIX_COND(p) && BADSUFFIX_COND(s) && v == val) continue

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
		BADPREFIX("notification_");
		BADPREFIX("prvm_");
		BADCVAR("mod_q3bsp_lightmapmergepower");
		BADCVAR("mod_q3bsp_nolightmaps");
		BADCVAR("fov");
		BADCVAR("mastervolume");
		BADCVAR("volume");
		BADCVAR("bgmvolume");
		BADCVAR("in_pitch_min");
		BADCVAR("in_pitch_max");
		BADCVAR("bottomcolor");
		BADCVAR("topcolor");
		BADCVAR("playermodel");

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
		BADCVAR("sv_vote_master_ids");
		BADCVAR("sv_vote_master_password");
		BADCVAR("sys_colortranslation");
		BADCVAR("sys_specialcharactertranslation");
		BADCVAR("timeformat");
		BADCVAR("timestamps");
		BADCVAR("g_require_stats");
		BADCVAR("g_chatban_list");
		BADCVAR("g_playban_list");
		BADCVAR("g_playban_minigames");
		BADCVAR("g_voteban_list");
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
		BADCVAR("sv_allow_customplayermodels_idlist");
		BADCVAR("sv_allow_customplayermodels_speciallist");

		// mapinfo
		BADCVAR("fraglimit");
		BADCVAR("g_arena");
		BADCVAR("g_assault");
		BADCVAR("g_ca");
		BADCVAR("g_ca_teams");
		BADCVAR("g_conquest");
		BADCVAR("g_conquest_teams");
		BADCVAR("g_ctf");
		BADCVAR("g_cts");
		BADCVAR("g_dotc");
		BADCVAR("g_dm");
		BADCVAR("g_domination");
		BADCVAR("g_domination_default_teams");
		BADCVAR("g_duel");
		BADCVAR("g_duel_not_dm_maps");
		BADCVAR("g_freezetag");
		BADCVAR("g_freezetag_teams");
		BADCVAR("g_invasion_type");
		BADCVAR("g_jailbreak");
		BADCVAR("g_jailbreak_teams");
		BADCVAR("g_keepaway");
		BADCVAR("g_keyhunt");
		BADCVAR("g_keyhunt_teams");
		BADCVAR("g_lms");
		BADCVAR("g_mayhem");
		BADCVAR("g_nexball");
		BADCVAR("g_onslaught");
		BADCVAR("g_race");
		BADCVAR("g_race_laps_limit");
		BADCVAR("g_race_qualifying_timelimit");
		BADCVAR("g_race_qualifying_timelimit_override");
		BADCVAR("g_runematch");
		BADCVAR("g_shootfromeye");
		BADCVAR("g_snafu");
		BADCVAR("g_survival");
		BADCVAR("g_survival_not_dm_maps");
		BADCVAR("g_tdm");
		BADCVAR("g_tdm_on_dm_maps");
		BADCVAR("g_tdm_teams");
		BADCVAR("g_tka");
		BADCVAR("g_tka_on_ka_maps");
		BADCVAR("g_tka_on_tdm_maps");
		BADCVAR("g_tka_teams");
		BADCVAR("g_tmayhem");
		BADCVAR("g_tmayhem_teams");
		BADCVAR("g_vip");
		BADCVAR("leadlimit");
		BADCVAR("teamplay");
		BADCVAR("timelimit");
		BADCVAR("g_mapinfo_q3compat");
		BADCVAR("g_mapinfo_settemp_acl");
		BADCVAR("g_mapinfo_ignore_warnings");
		BADCVAR("g_maplist_ignore_sizes");
		BADCVAR("g_maplist_sizes_count_bots");

		// long
		BADCVAR("hostname");
		BADCVAR("g_maplist");
		BADCVAR("g_maplist_mostrecent");
		BADCVAR("sv_motd");
		BADCVAR("sv_termsofservice_url");
		BADCVAR("sv_adminnick");

		v = cvar_string(k);
		d = cvar_defstring(k);
		if(v == d)
			continue;

		if(adding)
		{
			if (cvar_changes == "")
				cvar_changes = "// this server runs at modified server settings:\n";

			cvar_changes = strcat(cvar_changes, k, " \"", v, "\" // \"", d, "\"\n");
			if(strlen(cvar_changes) >= VM_TEMPSTRING_MAXSIZE)
			{
				cvar_changes = "// too many settings have been changed to show them here\n";
				adding = 0;
			}
		}

		// now check if the changes are actually gameplay relevant

		// does nothing gameplay relevant
		BADCVAR("captureleadlimit_override");
		BADCVAR("condump_stripcolors");
		BADCVAR("fs_gamedir");
		BADCVAR("g_allow_oldvortexbeam");
		BADCVAR("g_balance_kill_delay");
		BADCVAR("g_buffs_pickup_anyway");
		BADCVAR("g_buffs_randomize");
		BADCVAR("g_buffs_randomize_teamplay");
		BADCVAR("g_campcheck_distance");
		BADCVAR("g_chatsounds");
		BADCVAR("g_ca_point_leadlimit");
		BADCVAR("g_ca_point_limit");
		BADCVAR("g_ca_spectate_enemies");
		BADCVAR("g_ctf_captimerecord_always");
		BADCVAR("g_ctf_flag_glowtrails");
		BADCVAR("g_ctf_dynamiclights");
		BADCVAR("g_ctf_flag_pickup_verbosename");
		BADCVAR("g_ctf_flagcarrier_auto_helpme_damage");
		BADPRESUFFIX("g_ctf_flag_", "_model");
		BADPRESUFFIX("g_ctf_flag_", "_skin");
		BADCVAR("g_domination_point_leadlimit");
		BADCVAR("g_forced_respawn");
		BADCVAR("g_freezetag_point_leadlimit");
		BADCVAR("g_freezetag_point_limit");
		BADCVAR("g_glowtrails");
		BADCVAR("g_hats");
		BADCVAR("g_casings");
		BADCVAR("g_invasion_point_limit");
		BADCVAR("g_jump_grunt");
		BADCVAR("g_keepaway_ballcarrier_effects");
		BADCVAR("g_keepawayball_effects");
		BADCVAR("g_keyhunt_point_leadlimit");
		BADCVAR("g_nexball_goalleadlimit");
		BADCVAR("g_new_toys_autoreplace");
		BADCVAR("g_new_toys_use_pickupsound");
		BADCVAR("g_physics_predictall");
		BADCVAR("g_piggyback");
		BADCVAR("g_playerclip_collisions");
		BADCVAR("g_spawn_alloweffects");
		BADCVAR("g_tdm_point_leadlimit");
		BADCVAR("g_tdm_point_limit");
		BADCVAR("g_mayhem_point_limit");
		BADCVAR("g_mayhem_point_leadlimit");
		BADCVAR("g_tmayhem_point_limit");
		BADCVAR("g_tmayhem_point_leadlimit");
		BADCVAR("leadlimit_and_fraglimit");
		BADCVAR("leadlimit_override");
		BADCVAR("pausable");
		BADCVAR("sv_announcer");
		BADCVAR("sv_autopause");
		BADCVAR("sv_checkforpacketsduringsleep");
		BADCVAR("sv_damagetext");
		BADCVAR("sv_db_saveasdump");
		BADCVAR("sv_intermission_cdtrack");
		BADCVAR("sv_mapchange_delay");
		BADCVAR("sv_minigames");
		BADCVAR("sv_namechangetimer");
		BADCVAR("sv_precacheplayermodels");
		BADCVAR("sv_qcphysics");
		BADCVAR("sv_radio");
		BADCVAR("sv_stepheight");
		BADCVAR("sv_timeout");
		BADCVAR("sv_weapons_modeloverride");
		BADCVAR("w_prop_interval");
		BADPREFIX("chat_");
		BADPREFIX("crypto_");
		BADPREFIX("g_chat_");
		BADPREFIX("g_ctf_captimerecord_");
		BADPREFIX("g_hats_");
		BADPREFIX("g_maplist_");
		BADPREFIX("g_mod_");
		BADPREFIX("g_respawn_");
		BADPREFIX("net_");
		BADPREFIX("skill_");
		BADPREFIX("sv_allow_");
		BADPREFIX("sv_maxidle");
		BADPREFIX("sv_minigames_");
		BADPREFIX("sv_radio_");
		BADPREFIX("sv_timeout_");
		BADPREFIX("sv_vote_");
		BADPREFIX("timelimit_");
		BADPRESUFFIX("g_", "_round_timelimit");
		BADPRESUFFIX("g_", "_round_enddelay");

		// allowed changes to server admins (please sync this to server.cfg)
		// vi commands:
		//   :/"impure"/,$d
		//   :g!,^\/\/[^ /],d
		//   :%s,//\([^ ]*\).*,BADCVAR("\1");,
		//   :%!sort
		// yes, this does contain some redundant stuff, don't really care
		BADPREFIX("bot_ai_");
		BADCVAR("bot_config_file");
		BADCVAR("bot_number");
		BADCVAR("bot_prefix");
		BADCVAR("bot_suffix");
		BADCVAR("capturelimit_override");
		BADCVAR("fraglimit_override");
		BADCVAR("gametype");
		BADCVAR("g_antilag");
		BADCVAR("g_balance_teams");
		BADCVAR("g_balance_teams_queue");
		BADCVAR("g_balance_teams_remove");
		BADCVAR("g_balance_teams_remove_wait");
		BADCVAR("g_balance_teams_prevent_imbalance");
		BADCVAR("g_balance_teams_scorefactor");
		BADCVAR("g_ban_sync_trusted_servers");
		BADCVAR("g_ban_sync_uri");
		BADCVAR("g_buffs");
		BADCVAR("g_ca_teams_override");
		BADCVAR("g_ca_prevent_stalemate");
		BADCVAR("g_ctf_fullbrightflags");
		BADCVAR("g_ctf_ignore_frags");
		BADCVAR("g_ctf_leaderboard");
		BADCVAR("g_domination_point_limit");
		BADCVAR("g_domination_teams_override");
		BADCVAR("g_freezetag_revive_spawnshield");
		BADCVAR("g_freezetag_teams_override");
		BADCVAR("g_friendlyfire");
		BADCVAR("g_fullbrightitems");
		BADCVAR("g_fullbrightplayers");
		BADCVAR("g_keyhunt_point_limit");
		BADCVAR("g_keyhunt_teams_override");
		BADCVAR("g_lms_lives_override");
		BADCVAR("g_mayhem_powerups");
		BADCVAR("g_maplist");
		BADCVAR("g_maxplayers");
		BADCVAR("g_mirrordamage");
		BADCVAR("g_nexball_goallimit");
		BADCVAR("g_norecoil");
		BADCVAR("g_physics_clientselect");
		BADCVAR("g_pinata");
		BADCVAR("g_powerups");
		BADCVAR("g_powerups_drop_ondeath");
		BADCVAR("g_player_brightness");
		BADCVAR("g_rocket_flying");
		BADCVAR("g_rocket_flying_disabledelays");
		BADPREFIX("g_spawnshield");
		BADCVAR("g_start_delay");
		BADCVAR("g_superspectate");
		BADCVAR("g_tdm_teams_override");
		BADCVAR("g_tmayhem_teams_override");
		BADCVAR("g_tmayhem_powerups");
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
		BADCVAR("sv_autoscreenshot");
		BADCVAR("sv_autotaunt");
		BADCVAR("sv_curl_defaulturl");
		BADCVAR("sv_defaultcharacter");
		BADCVAR("sv_defaultcharacterskin");
		BADCVAR("sv_defaultplayercolors");
		BADCVAR("sv_defaultplayermodel");
		BADCVAR("sv_defaultplayerskin");
		BADCVAR("sv_maxrate");
		BADCVAR("sv_motd");
		BADCVAR("sv_public");
		BADCVAR("sv_showfps");
		BADCVAR("sv_showskill");
		BADCVAR("sv_showspectators");
		BADCVAR("sv_status_privacy");
		BADCVAR("sv_taunt");
		BADCVAR("sv_vote_call");
		BADCVAR("sv_vote_commands");
		BADCVAR("sv_vote_majority_factor");
		BADPREFIX("sv_vote_master");
		BADCVAR("sv_vote_simple_majority_factor");
		BADVALUE("sys_ticrate", "0.0078125");
		BADVALUE("sys_ticrate", "0.015625");
		BADVALUE("sys_ticrate", "0.03125");
		BADCVAR("teamplay_mode");
		BADCVAR("timelimit_override");
		BADPREFIX("g_warmup");
		BADPREFIX("sv_info_");
		BADPREFIX("sv_ready_restart_");
		BADCVAR("sv_teamnagger");

		BADPRESUFFIXVALUE("g_", "_weaponarena", "most");
		BADPRESUFFIXVALUE("g_", "_weaponarena", "most_available");

		// mutators that announce themselves properly to the server browser
		BADCVAR("g_instagib");
		BADCVAR("g_new_toys");
		BADCVAR("g_nix");
		BADCVAR("g_grappling_hook");
		BADCVAR("g_jetpack");

#undef BADPRESUFFIX
#undef BADPREFIX
#undef BADCVAR
#undef BADVALUE
#undef BADPRESUFFIXVALUE

		if(pureadding)
		{
			if (cvar_purechanges == "")
				cvar_purechanges = "// this server runs at modified gameplay settings:\n";

			cvar_purechanges = strcat(cvar_purechanges, k, " \"", v, "\" // \"", d, "\"\n");
			if(strlen(cvar_purechanges) >= VM_TEMPSTRING_MAXSIZE)
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
	cvar_changes = strzone(cvar_changes);

	if(cvar_purechanges == "")
		cvar_purechanges = "// this server runs at default gameplay settings\n";
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

	delete_fn = remove_unsafely;

	entity e = new(GotoFirstMap);
	setthink(e, GotoFirstMap);
	e.nextthink = time; // this is usually 1 at this point

	e = new(info_player_deathmatch);  // safeguard against player joining

	// assign reflectively to avoid "assignment to world" warning
	for (int i = 0, n = numentityfields(); i < n; ++i)
	{
		string k = entityfieldname(i);
		if (k == "classname")
		{
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

void GameplayMode_DelayedInit(entity this)
{
	// at this stage team entities are spawned, teamplay contains the number of them

	if(!scores_initialized)
		ScoreRules_generic();

	if (warmup_stage >= 0 && autocvar_g_maxplayers >= 0)
		return;
	if (!g_duel)
		MapReadSizes(mapname);

	if (autocvar_g_maxplayers < 0)
	{
		if (map_maxplayers <= 0)
			map_maxplayers = maxclients; // unlimited, but may need rounding
		map_maxplayers = bound(max(2, AVAILABLE_TEAMS * 2), map_maxplayers, maxclients);
		if (teamplay)
		{
			// automatic maxplayers should be a multiple of team count
			int down = map_maxplayers % AVAILABLE_TEAMS;
			int up = AVAILABLE_TEAMS - down;
			map_maxplayers += (up < down && up + map_maxplayers <= maxclients) ? up : -down;
		}
	}

	if (warmup_stage < 0)
	{
		int m = GetPlayerLimit();
		if (m <= 0)
			m = maxclients;
		map_minplayers = bound(max(2, AVAILABLE_TEAMS * 2), map_minplayers, m);
		if (teamplay)
		{
			// automatic minplayers should be a multiple of team count
			int down = map_minplayers % AVAILABLE_TEAMS;
			int up = AVAILABLE_TEAMS - down;
			map_minplayers += (up <= down && up + map_minplayers <= m) ? up : -down;
		}
	}
	else
		map_minplayers = 0; // don't display a minimum if it's not used (g_maxplayers < 0 && g_warmup >= 0)
}

void InitGameplayMode()
{
	VoteReset(false);

	// find out good world mins/maxs bounds, either the static bounds found by looking for solid, or the mapinfo specified bounds
	get_mi_min_max(1);
	// assign reflectively to avoid "assignment to world" warning
	for (int i = 0, done = 0, n = numentityfields(); i < n; ++i)
	{
		string k = entityfieldname(i);
		vector v = (k == "mins") ? mi_min : (k == "maxs") ? mi_max : '0 0 0';
		if (v)
		{
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

	strcpy(loaded_gametype_custom_string, autocvar__sv_vote_gametype_custom);
	gametype_custom_enabled = (loaded_gametype_custom_string != "");
	cvar_set("_sv_vote_gametype_custom", ""); // clear it immediately so it can't get stuck

	cache_mutatormsg = strzone("");
	cache_lastmutatormsg = strzone("");

	InitializeEntity(NULL, GameplayMode_DelayedInit, INITPRIO_GAMETYPE_FALLBACK);
}

bool world_already_spawned;
spawnfunc(worldspawn)
{
#ifdef WATERMARK
	string watermark_start = cvar_string("sv_watermark_start");
	if (watermark_start == "") // always true on Xonotic (re)start
		cvar_set("sv_watermark_start", WATERMARK);
	else if (watermark_start != WATERMARK) // true when qc code has been recompiled on a different git commit
	{
		LOG_INFOF(
			"\n^1    Warning: ^3the server QC program was updated without a full restart."
			"\n^3    Please restart the Xonotic executable otherwise you may get random bugs."
			"\n\n");
	}
#endif

	CheckEngineExtensions();

	cvar_set("_endmatch", "0");
	server_is_dedicated = boolean(stof(cvar_defstring("is_dedicated")));

	if (autocvar_sv_termsofservice_url && autocvar_sv_termsofservice_url != "")
	{
		strcpy(sv_termsofservice_url_escaped, strreplace(":", "|", autocvar_sv_termsofservice_url));
	}
	else
	{
		strcpy(sv_termsofservice_url_escaped, "INVALID");
	}

	bool wantrestart = false;
	{
		if (!server_is_dedicated)
		{
			// DP unloads dlcache pk3s before starting a listen server since https://gitlab.com/xonotic/darkplaces/-/merge_requests/134
			// restore csqc_progname too
			string expect = "csprogs.dat";
			wantrestart = cvar_string("csqc_progname") != expect;
			cvar_set("csqc_progname", expect);
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
			if (cvar_string("csqc_progname") != select)
			{
				cvar_set("csqc_progname", select);
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
						cvar_set("sv_progs", newprogs);
						wantrestart = true;
					}
					string newcsprogs = sprintf("csprogs-%s.dat", switchversion);
					if (fexists(newcsprogs))
					{
						cvar_set("csqc_progname", newcsprogs);
						wantrestart = true;
					}
				}
			}
		}
		if (wantrestart)
		{
			LOG_INFO("Restart requested");
			changelevel(mapname);
			// let initialization continue, shutdown depends on it
		}
	}

	if(world_already_spawned)
		error("world already spawned - you may have EXACTLY ONE worldspawn!");
	world_already_spawned = true;

	delete_fn = remove_safely; // during spawning, watch what you remove!

	cvar_changes_init(); // do this very early now so it REALLY matches the server config

	// default to RACE_RECORD, can be overwritten by gametypes
	record_type = RACE_RECORD;

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
	else
		PlayerStats_GameReport_Init(); // we need this to be initiated before InitGameplayMode

	Map_MarkAsRecent(mapname);

	InitGameplayMode();
	static_init_late();
	static_init_precache();
	readlevelcvars();

	GameRules_limit_fallbacks();

	player_count = 0;
	bot_waypoints_for_items = autocvar_g_waypoints_for_items;
	if(bot_waypoints_for_items == 1)
		if(this.spawnflags & SPAWNFLAG_NO_WAYPOINTS_FOR_ITEMS)
			bot_waypoints_for_items = 0;

	WaypointSprite_Init();

	// NOTE for matchid:
	// changing the logic generating it is okay. But:
	// it HAS to stay <= 64 chars
	// character set: ASCII 33-126 without the following characters: : ; ' " \ $
	// strftime(false, "%s") isn't reliable, see strftime_s description
	matchid = strzone(sprintf("%d.%s.%06d", autocvar_sv_eventlog_files_counter, strftime_s(), random() * 1000000));

	if(autocvar_sv_eventlog)
		GameLogInit(); // requires matchid to be set

	SetDefaultAlpha();

	if(autocvar_g_campaign)
		CampaignPostInit();

	Ban_LoadBans();

	MapInfo_Enumerate();
	MapInfo_FilterGametype(MapInfo_CurrentGametype(), MapInfo_CurrentFeatures(), MapInfo_RequiredFlags(), MapInfo_ForbiddenFlags(), 1);

	q3compat = BITSET(q3compat, Q3COMPAT_ARENA, _MapInfo_FindArenaFile(mapname, ".arena") != "");
	q3compat = BITSET(q3compat, Q3COMPAT_DEFI, _MapInfo_FindArenaFile(mapname, ".defi") != "");

	// quake 3 music support
	// bones_was_here: Q3 doesn't support .noise but the Nexuiz _MapInfo_Generate() does.
	// TODO: Q3 supports an optional intro file: "music/intro.wav music/loop.wav"
	string music = GetField_fullspawndata(world, "music", true);
	if (music || world.noise)
		// prefer .music over .noise
		strcpy(clientstuff, strcat(clientstuff, "cd loop \"", (music ? music : world.noise), "\"\n"));

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
					string trackname = argv(2);
					LOG_INFO("Found ^1UNSUPPORTED^7 cd loop command in .cfg file; put this line in mapinfo instead:");
					LOG_INFO("  cdtrack ", trackname);
					if (cvar_value_issafe(trackname))
					{
						string newstuff = strcat(clientstuff, "cd loop \"", trackname, "\"\n");
						strcpy(clientstuff, newstuff);
					}
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

	// set up information replies for clients and server to use
	maplist_reply = strzone(getmaplist());
	lsmaps_reply = strzone(getlsmaps());
	monsterlist_reply = strzone(getmonsterlist());
	bool records_available = false;
	for(int i = 0; i < 10; ++i)
	{
		string s = getrecords(i);
		if (s != "")
		{
			records_reply[i] = strzone(s);
			records_available = true;
		}
	}
	if (!records_available)
		records_reply[0] = "No records available for the current gametype.\n";
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
		string s = "csprogs-" WATERMARK ".dat";
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
	if(cvar_string("g_mod_balance") != cvar_defstring("g_mod_balance") && cvar_string("g_mod_balance") != "Testing")
		modname = cvar_string("g_mod_balance");
	if(cvar_string("g_mod_config") != cvar_defstring("g_mod_config"))
		modname = cvar_string("g_mod_config");
	// extra mutators that deserve to count as mod
	MUTATOR_CALLHOOK(SetModname, modname);
	modname = M_ARGV(0, string);

	// save it for later
	modname = strzone(modname);

	WinningConditionHelper(this); // set worldstatus

	if (autocvar_sv_autopause && server_is_dedicated && !wantrestart)
		// INITPRIO_LAST is too soon: bots either didn't join yet or didn't leave yet, see: bot_fixcount()
		defer(this, 5, Pause_TryPause_Dedicated);

	// load entity data outputted by create_scrshot_ent
	string filename = strcat("data/", mapname, "_scrshot_ent.txt");
	if(!find(NULL, classname, "info_autoscreenshot") && fexists(filename))
		loadfromfile(filename);

	world_initialized = 1;
	__spawnfunc_spawn_all();
}

spawnfunc(light)
{
	//makestatic (this); // Who the f___ did that?
	delete(this);
}

bool MoveToRandomLocationWithinBounds(entity e, vector boundmin, vector boundmax, float goodcontents, float badcontents, float badsurfaceflags, int attempts, float maxaboveground, float minviewdistance, bool frompos)
{
	float m = e.dphitcontentsmask;
	e.dphitcontentsmask = goodcontents | badcontents;

	vector org = boundmin;
	vector delta = boundmax - boundmin;

	vector start, end;
	start = end = org;
	int j; // used after the loop
	for(j = 0; j < attempts; ++j)
	{
		start.x = org.x + random() * delta.x;
		start.y = org.y + random() * delta.y;
		start.z = org.z + random() * delta.z;

		// rule 1: start inside world bounds, and outside
		// solid, and don't start from somewhere where you can
		// fall down to evil
		tracebox(start, e.mins, e.maxs, start - '0 0 1' * delta.z, MOVE_NORMAL, e);
		if (trace_fraction >= 1)
			continue;
		if (trace_startsolid)
			continue;
		if (trace_dphitcontents & badcontents)
			continue;
		if (trace_dphitq3surfaceflags & badsurfaceflags)
			continue;

		// rule 2: if we are too high, lower the point
		if (trace_fraction * delta.z > maxaboveground)
			start = trace_endpos + '0 0 1' * maxaboveground;
		vector enddown = trace_endpos;

		// rule 3: make sure we aren't outside the map. This only works
		// for somewhat well formed maps. A good rule of thumb is that
		// the map should have a convex outside hull.
		// these can be traceLINES as we already verified the starting box
		vector mstart = start + 0.5 * (e.mins + e.maxs);
		traceline(mstart, mstart + '1 0 0' * delta.x, MOVE_NORMAL, e);
		if (trace_fraction >= 1 || trace_dphittexturename == "common/caulk")
			continue;
		traceline(mstart, mstart - '1 0 0' * delta.x, MOVE_NORMAL, e);
		if (trace_fraction >= 1 || trace_dphittexturename == "common/caulk")
			continue;
		traceline(mstart, mstart + '0 1 0' * delta.y, MOVE_NORMAL, e);
		if (trace_fraction >= 1 || trace_dphittexturename == "common/caulk")
			continue;
		traceline(mstart, mstart - '0 1 0' * delta.y, MOVE_NORMAL, e);
		if (trace_fraction >= 1 || trace_dphittexturename == "common/caulk")
			continue;
		traceline(mstart, mstart + '0 0 1' * delta.z, MOVE_NORMAL, e);
		if (trace_fraction >= 1 || trace_dphittexturename == "common/caulk")
			continue;

		// rule 4: we must "see" some spawnpoint or item
		entity sp = NULL;
		if(frompos)
		{
			if((traceline(mstart, e.origin, MOVE_NORMAL, e), trace_fraction) >= 1)
				sp = e;
		}
		if(!sp)
		{
			IL_EACH(g_spawnpoints, checkpvs(mstart, it),
			{
				if((traceline(mstart, it.origin, MOVE_NORMAL, e), trace_fraction) >= 1)
				{
					sp = it;
					break;
				}
			});
		}
		if(!sp)
		{
			int items_checked = 0;
			IL_EACH(g_items, checkpvs(mstart, it),
			{
				if((traceline(mstart, it.origin + (it.mins + it.maxs) * 0.5, MOVE_NORMAL, e), trace_fraction) >= 1)
				{
					sp = it;
					break;
				}

				++items_checked;
				if(items_checked >= attempts)
					break; // sanity
			});

			if(!sp)
				continue;
		}

		// find a random vector to "look at"
		end.x = org.x + random() * delta.x;
		end.y = org.y + random() * delta.y;
		end.z = org.z + random() * delta.z;
		end = start + normalize(end - start) * vlen(delta);

		// rule 4: start TO end must not be too short
		tracebox(start, e.mins, e.maxs, end, MOVE_NORMAL, e);
		if(trace_startsolid)
			continue;
		if(trace_fraction < minviewdistance / vlen(delta))
			continue;

		// rule 5: don't want to look at sky
		if(trace_dphitq3surfaceflags & Q3SURFACEFLAG_SKY)
			continue;

		// rule 6: we must not end up in trigger_hurt
		if(tracebox_hits_trigger_hurt(start, e.mins, e.maxs, enddown))
			continue;

		break;
	}

	e.dphitcontentsmask = m;

	if(j < attempts)
	{
		setorigin(e, start);
		e.angles = vectoangles(end - start);
		LOG_DEBUG("Needed ", ftos(j + 1), " attempts");
		return true;
	}
	return false;
}

float MoveToRandomMapLocation(entity e, float goodcontents, float badcontents, float badsurfaceflags, float attempts, float maxaboveground, float minviewdistance)
{
	return MoveToRandomLocationWithinBounds(e, world.mins, world.maxs, goodcontents, badcontents, badsurfaceflags, attempts, maxaboveground, minviewdistance, false);
}

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
		LOG_HELP(s);
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
		LOG_HELP(s);
	if(to_eventlog)
		GameLogEcho(s);
	if(to_file)
		fputs(file, strcat(s, "\n"));

	FOREACH_CLIENT(IS_REAL_CLIENT(it) || (IS_BOT_CLIENT(it) && autocvar_sv_logscores_bots), {
		s = strcat(":player:see-labels:", GetPlayerScoreString(it, 0), ":");
		s = strcat(s, ftos(rint(time - CS(it).jointime)), ":");
		if(IS_PLAYER(it) || INGAME_JOINED(it))
			s = strcat(s, ftos(it.team), ":");
		else
			s = strcat(s, "spectator:");

		if(to_console)
			LOG_HELP(s, playername(it.netname, it.team, false));
		if(to_eventlog)
			GameLogEcho(strcat(s, ftos(it.playerid), ":", playername(it.netname, it.team, false)));
		if(to_file)
			fputs(file, strcat(s, playername(it.netname, it.team, false), "\n"));
	});

	if(teamplay)
	{
		s = strcat(":labels:teamscores:", GetTeamScoreString(0, 0));
		if(to_console)
			LOG_HELP(s);
		if(to_eventlog)
			GameLogEcho(s);
		if(to_file)
			fputs(file, strcat(s, "\n"));

		for(i = 1; i < 16; ++i)
		{
			s = strcat(":teamscores:see-labels:", GetTeamScoreString(i, 0));
			s = strcat(s, ":", ftos(i));
			if(to_console)
				LOG_HELP(s);
			if(to_eventlog)
				GameLogEcho(s);
			if(to_file)
				fputs(file, strcat(s, "\n"));
		}
	}

	if(to_console)
		LOG_HELP(":end");
	if(to_eventlog)
		GameLogEcho(":end");
	if(to_file)
	{
		fputs(file, ":end\n");
		fclose(file);
	}
}

// it should be called by gametypes where players can join a team but have to wait before playing
// it puts players who joined too late (without being able to play) back to spectators
// if prev_team_field is not team it also puts players who previously switched team (without being
// able to play on the new team) back to previous team
void MatchEnd_RestoreSpectatorAndTeamStatus(.int prev_team_field)
{
	bool fix_team = (teamplay && prev_team_field != team);
	FOREACH_CLIENT(true,
	{
		if (!IS_PLAYER(it) && INGAME_JOINING(it))
		{
			INGAME_STATUS_CLEAR(it);
			PutObserverInServer(it, true, false);
			bprint(playername(it.netname, it.team, false), " has been moved back to spectator");
			it.winning = false;
		}
		else if (fix_team && INGAME_JOINED(it) && it.(prev_team_field) && it.team != it.(prev_team_field))
		{
			Player_SetForcedTeamIndex(it, TEAM_FORCE_DEFAULT);
			if (MoveToTeam(it, Team_TeamToIndex(it.(prev_team_field)), 6))
			{
				string pl_name = playername(it.netname, it.team, false);
				bprint(pl_name, " has been moved back to the ", Team_ColoredFullName(it.team));
			}
			it.winning = (it.team == WinningConditionHelper_winnerteam);
		}
	});
}

void MatchEnd_RestoreSpectatorStatus()
{
	MatchEnd_RestoreSpectatorAndTeamStatus(team);
}

/*
go to the next level for deathmatch
only called if a time or frag limit has expired
*/
void NextLevel()
{
	cvar_set("_endmatch", "0");
	game_stopped = true;
	intermission_running = true; // game over

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

	VoteReset(true);

	MUTATOR_CALLHOOK(MatchEnd_BeforeScores);

	DumpStats(true);

	// send statistics
	PlayerStats_GameReport(true);
	WeaponStats_Shutdown();

	Kill_Notification(NOTIF_ALL, NULL, MSG_CENTER, CPID_Null); // kill all centerprints now

	if(autocvar_sv_eventlog)
		GameLogEcho(":gameover");

	GameLogClose();

	int winner_team = 0;
	FOREACH_CLIENT(IS_PLAYER(it) || INGAME(it), {
		FixIntermissionClient(it);
		if(it.winning)
		{
			if (teamplay && !winner_team)
			{
				winner_team = it.team;
				bprint(Team_ColorCode(winner_team), Team_ColorName_Upper(winner_team), "^7 team wins the match\n");
			}
			bprint(playername(it.netname, it.team, false), " ^7wins\n");
		}
	});

	target_music_kill();

	if(autocvar_g_campaign)
		CampaignPreIntermission();

	MUTATOR_CALLHOOK(MatchEnd);

	localcmd("\nsv_hook_gameend\n");
}


int InitiateSuddenDeath()
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
			{
				checkrules_suddendeathend = time; // no suddendeath in campaign
			}
			else
			{
				checkrules_suddendeathend = time + 60 * autocvar_timelimit_suddendeath;
				overtimes = OVERTIME_SUDDENDEATH;
			}
			if(g_race && !g_race_qualifying)
				race_StartCompleting();
		}
		return 0;
	}
}

void InitiateOvertime() // ONLY call this if InitiateSuddenDeath returned true
{
	++checkrules_overtimesadded;
	// NOTE: here overtimes can never be < 0 so it can be safely sent as (unsigned) int stat; we ignore
	// the upper limit of OVERTIME_SUDDENDEATH - 1 = 16777215 - 1 that in practice can never be reached in game
	overtimes = checkrules_overtimesadded;
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
	FOREACH_CLIENT(IS_PLAYER(it) || INGAME(it), { it.winning = (it.(field) == value); });
}

// set the .winning flag for those players with a given field value
void AddWinners(.float field, float value)
{
	FOREACH_CLIENT(IS_PLAYER(it) || INGAME(it), {
		if(it.(field) == value)
			it.winning = 1;
	});
}

// clear the .winning flags
void ClearWinners()
{
	FOREACH_CLIENT(IS_PLAYER(it) || INGAME(it), { it.winning = 0; });
}

int fragsleft_last;
float WinningCondition_Scores(float limit, float leadlimit)
{
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
	{
		float fragsleft;
		if (checkrules_suddendeathend && time >= checkrules_suddendeathend)
		{
			fragsleft = 1;
		}
		else
		{
			fragsleft = FLOAT_MAX;
			float leadingfragsleft = FLOAT_MAX;
			if (limit)
				fragsleft = limit - WinningConditionHelper_topscore;
			if (leadlimit)
				leadingfragsleft = WinningConditionHelper_secondscore + leadlimit - WinningConditionHelper_topscore;

			if (limit && leadlimit && autocvar_leadlimit_and_fraglimit)
				fragsleft = max(fragsleft, leadingfragsleft);
			else
				fragsleft = min(fragsleft, leadingfragsleft);
		}

		if (fragsleft_last != fragsleft) // do not announce same remaining frags multiple times
		{
			if (fragsleft == 1)
				Send_Notification(NOTIF_ALL, NULL, MSG_ANNCE, ANNCE_REMAINING_FRAG_1);
			else if (fragsleft == 2)
				Send_Notification(NOTIF_ALL, NULL, MSG_ANNCE, ANNCE_REMAINING_FRAG_2);
			else if (fragsleft == 3)
				Send_Notification(NOTIF_ALL, NULL, MSG_ANNCE, ANNCE_REMAINING_FRAG_3);

			fragsleft_last = fragsleft;
		}
	}

	bool fraglimit_reached = (limit && WinningConditionHelper_topscore >= limit);
	bool leadlimit_reached = (leadlimit && WinningConditionHelper_topscore - WinningConditionHelper_secondscore >= leadlimit);

	bool limit_reached;
	// only respect leadlimit_and_fraglimit when both limits are set or the game will never end
	if (limit && leadlimit && autocvar_leadlimit_and_fraglimit)
		limit_reached = (fraglimit_reached && leadlimit_reached);
	else
		limit_reached = (fraglimit_reached || leadlimit_reached);

	return GetWinningCode(
		WinningConditionHelper_topscore && limit_reached,
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

	float timelimit = autocvar_timelimit * 60;
	float fraglimit = autocvar_fraglimit;
	float leadlimit = autocvar_leadlimit;
	if (leadlimit < 0) leadlimit = 0;

	if(warmup_stage || time <= game_starttime) // NOTE: this is <= to prevent problems in the very tic where the game starts
	{
		if(timelimit > 0)
			timelimit = 0; // timelimit is not made for warmup
		if(fraglimit > 0)
			fraglimit = 0; // no fraglimit for now
		leadlimit = 0; // no leadlimit for now
	}

	if (autocvar__endmatch || timelimit < 0)
	{
		// endmatch
		NextLevel();
		return;
	}

	if(timelimit > 0)
		timelimit += game_starttime;

	int overtimes_prev = overtimes;
	int wantovertime = 0;

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
					ReadyRestart(true); // go to race
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
		if (overtimes == OVERTIME_SUDDENDEATH && overtimes != overtimes_prev)
		{
			// if suddendeathend overtime has just begun, revert it
			checkrules_suddendeathend = 0;
			overtimes = overtimes_prev;
		}
		//print("WINNING\n");
		NextLevel();
	}
}

int want_weapon(entity weaponinfo, int allguns)
{
	int d = 0;
	bool allow_mutatorblocked = false;

	if(!weaponinfo.m_id)
		return 0;

	bool mutator_returnvalue = MUTATOR_CALLHOOK(WantWeapon, weaponinfo, d, allguns, allow_mutatorblocked);
	d = M_ARGV(1, float);
	allguns = M_ARGV(2, int);
	allow_mutatorblocked = M_ARGV(3, bool);

	if(allguns == 1)
		d = boolean(!(weaponinfo.spawnflags & WEP_FLAG_HIDDEN));
	else if(allguns == 2)
		d = boolean((weaponinfo.spawnflags & WEP_FLAG_NORMAL) && !(weaponinfo.spawnflags & WEP_FLAG_HIDDEN));
	else if(!mutator_returnvalue)
		d = !(!weaponinfo.weaponstart);

	if(!allow_mutatorblocked && (weaponinfo.spawnflags & WEP_FLAG_MUTATORBLOCKED)) // never default mutator blocked guns
		d = 0;

	float t = weaponinfo.weaponstartoverride;

	//LOG_INFOF("want_weapon: %s - d: %d t: %d\n", weaponinfo.netname, d, t);

	// bit order in t:
	// 1: want or not
	// 2: is default?
	// 4: is set by default?
	if(t < 0)
		t = 4 | (3 * d);
	else
		t |= (2 * d);

	return t;
}

/// Weapons the player normally starts with outside weapon arena.
WepSet weapons_start()
{
	WepSet ret = '0 0 0';
	FOREACH(Weapons, it != WEP_Null, {
		int w = want_weapon(it, false);
		if (w & 1)
			ret |= it.m_wepset;
	});
	return ret;
}

WepSet weapons_all()
{
	WepSet ret = '0 0 0';
	FOREACH(Weapons, it != WEP_Null, {
		if (!(it.spawnflags & (WEP_FLAG_MUTATORBLOCKED | WEP_FLAG_HIDDEN)))
			ret |= it.m_wepset;
	});
	return ret;
}

WepSet weapons_devall()
{
	WepSet ret = '0 0 0';
	FOREACH(Weapons, it != WEP_Null,
	{
		ret |= it.m_wepset;
	});
	return ret;
}

WepSet weapons_most()
{
	WepSet ret = '0 0 0';
	FOREACH(Weapons, it != WEP_Null, {
		if ((it.spawnflags & WEP_FLAG_NORMAL) && !(it.spawnflags & (WEP_FLAG_MUTATORBLOCKED | WEP_FLAG_HIDDEN)))
			ret |= it.m_wepset;
	});
	return ret;
}

void weaponarena_available_all_update(entity this)
{
	if (weaponsInMapAll)
	{
		start_weapons = warmup_start_weapons = g_weaponarena_weapons = weapons_start() | (weaponsInMapAll & weapons_all());
	}
	else
	{
		// if no weapons are available on the map, just fall back to all weapons arena
		start_weapons = warmup_start_weapons = g_weaponarena_weapons = weapons_all();
	}
}

void weaponarena_available_devall_update(entity this)
{
	if (weaponsInMapAll)
	{
		start_weapons = warmup_start_weapons = g_weaponarena_weapons = weapons_start() | weaponsInMapAll;
	}
	else
	{
		// if no weapons are available on the map, just fall back to devall weapons arena
		start_weapons = warmup_start_weapons = g_weaponarena_weapons = weapons_devall();
	}
}

void weaponarena_available_most_update(entity this)
{
	if (weaponsInMapAll)
	{
		start_weapons = warmup_start_weapons = g_weaponarena_weapons = weapons_start() | (weaponsInMapAll & weapons_most());
	}
	else
	{
		// if no weapons are available on the map, just fall back to most weapons arena
		start_weapons = warmup_start_weapons = g_weaponarena_weapons = weapons_most();
	}
}

void readplayerstartcvars()
{
	// initialize starting values for players
	start_weapons = '0 0 0';
	start_weapons_default = '0 0 0';
	start_weapons_defaultmask = '0 0 0';
	start_items = 0;
	start_ammo_shells = 0;
	start_ammo_nails = 0;
	start_ammo_rockets = 0;
	start_ammo_cells = 0;
	if (random_start_ammo == NULL)
	{
		random_start_ammo = new_pure(random_start_ammo);
	}
	start_health = cvar("g_balance_health_start");
	start_armorvalue = cvar("g_balance_armor_start");

	g_weaponarena = 0;
	g_weaponarena_weapons = '0 0 0';

	string s = cvar_string("g_weaponarena");

	MUTATOR_CALLHOOK(SetWeaponArena, s);
	s = M_ARGV(0, string);

	if (s == "0" || s == "")
	{
		// no arena
	}
	else if (s == "off")
	{
		// forcibly turn off weaponarena
	}
	else if (s == "all" || s == "1")
	{
		g_weaponarena = 1;
		g_weaponarena_list = "All Weapons Arena";
		g_weaponarena_weapons = weapons_all();
	}
	else if (s == "devall")
	{
		g_weaponarena = 1;
		g_weaponarena_list = "Dev All Weapons Arena";
		g_weaponarena_weapons = weapons_devall();
	}
	else if (s == "most")
	{
		g_weaponarena = 1;
		g_weaponarena_list = "Most Weapons Arena";
		g_weaponarena_weapons = weapons_most();
	}
	else if (s == "all_available")
	{
		g_weaponarena = 1;
		g_weaponarena_list = "All Available Weapons Arena";

		// this needs to run after weaponsInMapAll is initialized
		InitializeEntity(NULL, weaponarena_available_all_update, INITPRIO_FINDTARGET);
	}
	else if (s == "devall_available")
	{
		g_weaponarena = 1;
		g_weaponarena_list = "Dev All Available Weapons Arena";

		// this needs to run after weaponsInMapAll is initialized
		InitializeEntity(NULL, weaponarena_available_devall_update, INITPRIO_FINDTARGET);
	}
	else if (s == "most_available")
	{
		g_weaponarena = 1;
		g_weaponarena_list = "Most Available Weapons Arena";

		// this needs to run after weaponsInMapAll is initialized
		InitializeEntity(NULL, weaponarena_available_most_update, INITPRIO_FINDTARGET);
	}
	else if (s == "none")
	{
		g_weaponarena = 1;
		g_weaponarena_list = "No Weapons Arena";
	}
	else
	{
		g_weaponarena = 1;
		float t = tokenize_console(s);
		g_weaponarena_list = "";
		for (int j = 0; j < t; ++j)
		{
			s = argv(j);
			Weapon wep = Weapon_from_name(s);
			if(wep != WEP_Null)
			{
				g_weaponarena_weapons |= (wep.m_wepset);
				g_weaponarena_list = strcat(g_weaponarena_list, wep.netname, " & ");
			}
		}
		if (g_weaponarena_list != "") // remove trailing " & "
			g_weaponarena_list = substring(g_weaponarena_list, 0, strlen(g_weaponarena_list) - 3);
		else // no valid weapon found
			g_weaponarena_list = "No Weapons Arena";
	}

	if (g_weaponarena)
	{
		g_weapon_stay = 0; // incompatible
		start_weapons = g_weaponarena_weapons;
		start_items |= IT_UNLIMITED_AMMO | IT_UNLIMITED_SUPERWEAPONS;
		g_weaponarena_list = strzone(g_weaponarena_list);
	}
	else
	{
		FOREACH(Weapons, it != WEP_Null, {
			int w = want_weapon(it, false);
			WepSet s = it.m_wepset;
			if(w & 1)
				start_weapons |= s;
			if(w & 2)
				start_weapons_default |= s;
			if(w & 4)
				start_weapons_defaultmask |= s;
		});
	}

	if(cvar("g_balance_superweapons_time") < 0)
		start_items |= IT_UNLIMITED_SUPERWEAPONS;

	if(!cvar("g_use_ammunition"))
		start_items |= IT_UNLIMITED_AMMO;

	start_ammo_shells = cvar("g_start_ammo_shells");
	start_ammo_nails = cvar("g_start_ammo_nails");
	start_ammo_rockets = cvar("g_start_ammo_rockets");
	start_ammo_cells = cvar("g_start_ammo_cells");
	start_ammo_fuel = cvar("g_start_ammo_fuel");
	random_start_weapons_count = cvar("g_random_start_weapons_count");
	SetResource(random_start_ammo, RES_SHELLS, cvar("g_random_start_shells"));
	SetResource(random_start_ammo, RES_BULLETS, cvar("g_random_start_bullets"));
	SetResource(random_start_ammo, RES_ROCKETS, cvar("g_random_start_rockets"));
	SetResource(random_start_ammo, RES_CELLS, cvar("g_random_start_cells"));

	warmup_start_ammo_shells = start_ammo_shells;
	warmup_start_ammo_nails = start_ammo_nails;
	warmup_start_ammo_rockets = start_ammo_rockets;
	warmup_start_ammo_cells = start_ammo_cells;
	warmup_start_ammo_fuel = start_ammo_fuel;
	warmup_start_health = start_health;
	warmup_start_armorvalue = start_armorvalue;
	warmup_start_weapons = start_weapons;
	warmup_start_weapons_default = start_weapons_default;
	warmup_start_weapons_defaultmask = start_weapons_defaultmask;

	if (!g_weaponarena)
	{
		warmup_start_ammo_shells = cvar("g_warmup_start_ammo_shells");
		warmup_start_ammo_nails = cvar("g_warmup_start_ammo_nails");
		warmup_start_ammo_rockets = cvar("g_warmup_start_ammo_rockets");
		warmup_start_ammo_cells = cvar("g_warmup_start_ammo_cells");
		warmup_start_ammo_fuel = cvar("g_warmup_start_ammo_fuel");
		warmup_start_health = cvar("g_warmup_start_health");
		warmup_start_armorvalue = cvar("g_warmup_start_armor");
		warmup_start_weapons = '0 0 0';
		warmup_start_weapons_default = '0 0 0';
		warmup_start_weapons_defaultmask = '0 0 0';
		FOREACH(Weapons, it != WEP_Null, {
			int w = want_weapon(it, autocvar_g_warmup_allguns);
			WepSet s = it.m_wepset;
			if(w & 1)
				warmup_start_weapons |= s;
			if(w & 2)
				warmup_start_weapons_default |= s;
			if(w & 4)
				warmup_start_weapons_defaultmask |= s;
		});
	}

	if (autocvar_g_jetpack)
		start_items |= ITEM_Jetpack.m_itemid;

	MUTATOR_CALLHOOK(SetStartItems);

	if (start_items & ITEM_Jetpack.m_itemid)
	{
		start_items |= ITEM_FuelRegen.m_itemid;
		start_ammo_fuel = max(start_ammo_fuel, cvar("g_balance_fuel_rotstable"));
		warmup_start_ammo_fuel = max(warmup_start_ammo_fuel, cvar("g_balance_fuel_rotstable"));
	}

	start_ammo_shells = max(0, start_ammo_shells);
	start_ammo_nails = max(0, start_ammo_nails);
	start_ammo_rockets = max(0, start_ammo_rockets);
	start_ammo_cells = max(0, start_ammo_cells);
	start_ammo_fuel = max(0, start_ammo_fuel);
	SetResource(random_start_ammo, RES_SHELLS, max(0, GetResource(random_start_ammo, RES_SHELLS)));
	SetResource(random_start_ammo, RES_BULLETS, max(0, GetResource(random_start_ammo, RES_BULLETS)));
	SetResource(random_start_ammo, RES_ROCKETS, max(0, GetResource(random_start_ammo, RES_ROCKETS)));
	SetResource(random_start_ammo, RES_CELLS, max(0, GetResource(random_start_ammo, RES_CELLS)));

	warmup_start_ammo_shells = max(0, warmup_start_ammo_shells);
	warmup_start_ammo_nails = max(0, warmup_start_ammo_nails);
	warmup_start_ammo_rockets = max(0, warmup_start_ammo_rockets);
	warmup_start_ammo_cells = max(0, warmup_start_ammo_cells);
	warmup_start_ammo_fuel = max(0, warmup_start_ammo_fuel);
}

void readlevelcvars()
{
	serverflags &= ~SERVERFLAG_ALLOW_FULLBRIGHT;
	if(cvar("sv_allow_fullbright"))
		serverflags |= SERVERFLAG_ALLOW_FULLBRIGHT;

	serverflags &= ~SERVERFLAG_FORBID_PICKUPTIMER;
	if(cvar("sv_forbid_pickuptimer"))
		serverflags |= SERVERFLAG_FORBID_PICKUPTIMER;

	sv_ready_restart_after_countdown = cvar("sv_ready_restart_after_countdown");

	if(cvar("g_campaign"))
		warmup_stage = 0; // no warmup during campaign
	else
	{
		warmup_stage = autocvar_g_warmup;
		if (warmup_stage < 0 || warmup_stage > 1)
			warmup_limit = -1; // don't start until there's enough players
		else if (warmup_stage == 1)
		{
			// this code is duplicated in ReadyCount()
			warmup_limit = cvar("g_warmup_limit");
			if(warmup_limit == 0)
				warmup_limit = autocvar_timelimit * 60;
		}
	}

	g_weapon_stay = cvar(strcat("g_", GetGametype(), "_weapon_stay"));
	if(!g_weapon_stay)
		g_weapon_stay = cvar("g_weapon_stay");

	MUTATOR_CALLHOOK(ReadLevelCvars);

	if (!warmup_stage && !autocvar_g_campaign)
		game_starttime = time + cvar("g_start_delay");

	FOREACH(Weapons, it != WEP_Null, { it.wr_init(it); });

	readplayerstartcvars();
}

void InitializeEntity(entity e, void(entity this) func, int order)
{
	entity prev, cur;

	if (!e || e.initialize_entity)
	{
		// make a proxy initializer entity
		entity e_old = e;
		e = new(initialize_entity);
		e.enemy = e_old;
	}

	e.initialize_entity = func;
	e.initialize_entity_order = order;

	cur = initialize_entity_first;
	prev = NULL;
	for (;;)
	{
		if (!cur || cur.initialize_entity_order > order)
		{
			// insert between prev and cur
			if (prev)
				prev.initialize_entity_next = e;
			else
				initialize_entity_first = e;
			e.initialize_entity_next = cur;
			return;
		}
		prev = cur;
		cur = cur.initialize_entity_next;
	}
}
void InitializeEntitiesRun()
{
	entity startoflist = initialize_entity_first;
	initialize_entity_first = NULL;
	delete_fn = remove_except_protected;
	for (entity e = startoflist; e; e = e.initialize_entity_next)
	{
		e.remove_except_protected_forbidden = 1;
	}
	for (entity e = startoflist; e; )
	{
		e.remove_except_protected_forbidden = 0;
		e.initialize_entity_order = 0;
		entity next = e.initialize_entity_next;
		e.initialize_entity_next = NULL;
		var void(entity this) func = e.initialize_entity;
		e.initialize_entity = func_null;
		if (e.classname == "initialize_entity")
		{
			entity wrappee = e.enemy;
			builtin_remove(e);
			e = wrappee;
		}
		//dprint("Delayed initialization: ", e.classname, "\n");
		if (func)
		{
			func(e);
		}
		else
		{
			eprint(e);
			backtrace(strcat("Null function in: ", e.classname, "\n"));
		}
		e = next;
	}
	delete_fn = remove_unsafely;
}

// originally ported from DP's droptofloor() builtin
// TODO: make a common function for the client-side?
// bones_was_here: when we have a use case for it, yes
void DropToFloor_QC(entity this)
{
	int nudgeresult;

	if(!this || wasfreed(this))
	{
		LOG_WARN("DropToFloor_QC: can not modify free entity");
		return;
	}

	/* Prior to sv_legacy_bbox_expand 0, both droptofloor and nudgeoutofsolid_OrFallback were done for items
	 * using box '-16 -16 0' '16 16 48' (without the FL_ITEM expansion applied),
	 * which often resulted in bboxes partially in solids once expansion was applied.
	 * We don't want bboxes in solids (bad for gameplay and culling),
	 * but we also don't want items to land on a "skirting board" or the base of a sloping wall.
	 * For initial nudgeoutofsolid_OrFallback and droptofloor stages we use a small box
	 * so they fall as far and in the same place as they traditionally would,
	 * then we nudge the full size box out of solid, in a direction appropriate for the plane(s).
	 */
	vector saved_mins = this.mins; // gmqcc's used-uninitialized check doesn't handle
	vector saved_maxs = this.maxs; // making these assignments FL_ITEM conditional.
	if (this.flags & FL_ITEM)
	{
		// Using the Q3 bbox for best compatibility with all maps, except...
		this.mins.x = -15;
		this.mins.y = -15;
		this.maxs.x = 15;
		this.maxs.y = 15;
		this.maxs.z = this.mins.z + 30; // ...Nex, Xon and Quake use a different vertical offset, see also: StartItem()
	}

	/* NOTE: sv_gameplayfix_droptofloorstartsolid_nudgetocorrect isn't checked, so it won't need to be networked to CSQC.
	 * It was enabled by default in all Xonotic releases and in Nexuiz, so now certain maps depend on it.
	 * Example: on erbium 0.8.6 the shards @ crylink are too low (in collision with the floor),
	 * so without this those fall through the floor.
	 * Q3, Q2 and Quake don't try to move items out of solid.
	 */
	if(!Q3COMPAT_COMMON && autocvar_sv_mapformat_is_quake3) // Xonotic, Nexuiz
	{
		nudgeresult = nudgeoutofsolid_OrFallback(this);
		if (!nudgeresult)
			LOG_WARNF("DropToFloor_QC at \"%v\": COULD NOT FIX badly placed entity \"%s\" before drop", this.origin, this.classname);
		else if (nudgeresult > 0)
			LOG_WARNF("DropToFloor_QC at \"%v\": FIXED badly placed entity \"%s\" before drop", this.origin, this.classname);
	}
	else if (!autocvar_sv_mapformat_is_quake3 && !autocvar_sv_mapformat_is_quake2) // Quake
	{
		if (this.flags & FL_ITEM)
			this.origin.z += 6;
		else
			this.origin.z += 1; // monsters 1, misc_explobox 2 but we don't support those currently
	}

	vector end = this.origin;
	if (autocvar_sv_mapformat_is_quake3)
		end.z -= 4096;
	else if (autocvar_sv_mapformat_is_quake2)
		end.z -= 128;
	else
		end.z -= 256; // Quake, QuakeWorld
	tracebox(this.origin, this.mins, this.maxs, end, MOVE_NOMONSTERS, this);

	if (!autocvar_sv_mapformat_is_quake3 && !autocvar_sv_mapformat_is_quake2 && (trace_allsolid || trace_fraction == 1)) // Quake
	{
		// Quake games just delete badly placed items (and misc_explobox)...
		if (this.flags & FL_ITEM)
		{
			LOG_WARNF("DropToFloor_QC at \"%v\" (Quake compat): DELETING badly placed item \"%s\"", this.origin, this.classname);
			delete(this);
			return;
		}
		// ...not monsters though...
		LOG_WARNF("DropToFloor_QC at \"%v\" (Quake compat): badly placed entity \"%s\"", this.origin, this.classname);
	}
	else if ((Q3COMPAT_COMMON || autocvar_sv_mapformat_is_quake2) && trace_startsolid) // Q3, Q2
	{
		// ...but we can't do that on Q3 maps like jamdm1
		// because our tracebox hits things Q3's trace doesn't (patches?).
		LOG_WARNF("DropToFloor_QC at \"%v\" (Quake 3 compat): badly placed entity \"%s\"", this.origin, this.classname);
	}

	/* NOTE: sv_gameplayfix_droptofloorstartsolid (fallback from tracebox to traceline) isn't implemented.
	 * It was disabled by default in all Xonotic releases and in Nexuiz.
	 * Q3 doesn't support it (always uses its '-15 -15 -15' '15 15 15' box when dropping items), neither does Quake or Q2.
	 */

	if (!autocvar_sv_mapformat_is_quake2) // Quake, Q3, Nexuiz, Xonotic
		// allow to ride movers (or unset if in freefall)
		this.groundentity = trace_ent;

	if (!autocvar_sv_mapformat_is_quake3)
		// if support is destroyed, keep suspended (gross hack for floating items in various maps)
		// bones_was_here: is this for Q1BSP only? Which maps use it? Do we need it at all? Intentions unclear in DP...
		this.move_suspendedinair = true;

	if (trace_fraction)
		this.origin = trace_endpos;

	if (this.flags & FL_ITEM)
	{
		this.mins = saved_mins;
		this.maxs = saved_maxs;

		// A side effect of using a small box to drop items (and do the initial nudge) is
		// the full size box can end up in collision with a sloping floor or terrain model.
		nudgeresult = nudgeoutofsolid_OrFallback(this);
		// No warns for successful nudge because it would spam about items on slopes/terrain.
	}
	else if (trace_allsolid && trace_fraction) // dropped using "proper" bbox but never left solid
	{
		nudgeresult = nudgeoutofsolid_OrFallback(this);
		if (nudgeresult > 0)
			LOG_WARNF("DropToFloor_QC at \"%v\": FIXED badly placed entity \"%s\" after drop", this.origin, this.classname);
	}
	else
		nudgeresult = -1;

	if (!nudgeresult)
	if (!Q3COMPAT_COMMON) // to be expected on Q3 maps like gu3-pewter because we use bigger final bboxes
		LOG_WARNF("DropToFloor_QC at \"%v\": COULD NOT FIX stuck entity \"%s\" after drop", this.origin, this.classname);

	setorigin(this, this.dropped_origin = this.origin);
}

void DropToFloor_QC_DelayedInit(entity this)
{
	InitializeEntity(this, DropToFloor_QC, INITPRIO_DROPTOFLOOR);
}

bool autocvar_sv_gameplayfix_multiplethinksperframe = true;
void RunThink(entity this, float dt)
{
	// don't let things stay in the past.
	// it is possible to start that way by a trigger with a local time.
	if(this.nextthink <= 0 || this.nextthink > time + dt)
		return;

	float oldtime = time; // do we need to save this?

	for (int iterations = 0; iterations < 128 && !wasfreed(this); ++iterations)
	{
		time = max(oldtime, this.nextthink);
		this.nextthink = 0;

		if(getthink(this))
			getthink(this)(this);
		// mods often set nextthink to time to cause a think every frame,
		// we don't want to loop in that case, so exit if the new nextthink is
		// <= the time the qc was told, also exit if it is past the end of the
		// frame
		if(this.nextthink <= time || this.nextthink > oldtime + dt || !autocvar_sv_gameplayfix_multiplethinksperframe)
			break;
	}

	time = oldtime;
}

bool autocvar_sv_freezenonclients;
void Physics_Frame()
{
	if(autocvar_sv_freezenonclients)
		return;

	IL_EACH(g_moveables, true,
	{
		if(IS_CLIENT(it) || it.move_movetype == MOVETYPE_PHYSICS)
			continue;

		//set_movetype(it, it.move_movetype);
		// inline the set_movetype function, since this is called a lot
		it.movetype = (it.move_qcphysics) ? MOVETYPE_QCENTITY : it.move_movetype;

		if(it.move_qcphysics && it.move_movetype != MOVETYPE_NONE)
			Movetype_Physics_NoMatchTicrate(it, PHYS_INPUT_TIMELENGTH, false);

		if(it.movetype >= MOVETYPE_USER_FIRST && it.movetype <= MOVETYPE_USER_LAST) // these cases have no think handling
		{
			if(it.move_movetype == MOVETYPE_PUSH || it.move_movetype == MOVETYPE_FAKEPUSH)
				continue; // these movetypes have no regular think function
			// handle thinking here
			if (getthink(it) && it.nextthink > 0 && it.nextthink <= time + PHYS_INPUT_TIMELENGTH)
				RunThink(it, PHYS_INPUT_TIMELENGTH);
		}
	});

	if(autocvar_sv_gameplayfix_delayprojectiles >= 0)
		return;

	// make a second pass to see if any ents spawned this frame and make
	// sure they run their move/think. this is verified by checking .move_time, which will never be 0 if the entity has moved
	// MOVETYPE_NONE is also checked as .move_time WILL be 0 with that movetype
	IL_EACH(g_moveables, it.move_qcphysics,
	{
		if(IS_CLIENT(it) || it.move_time || it.move_movetype == MOVETYPE_NONE || it.move_movetype == MOVETYPE_PHYSICS)
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
		} else if (e.hitsound_damage_dealt) {
			STAT(HIT_TIME, it) = time;
			// NOTE: this is not accurate as client code doesn't need so much accuracy for its purposes
			STAT(HITSOUND_DAMAGE_DEALT_TOTAL, it) += ceil(e.hitsound_damage_dealt);
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
		it.hitsound_damage_dealt = 0;
		it.killsound = false;
		antilag_record(it, CS(it), altime);
		if(it.death_time == time && IS_PLAYER(it) && IS_DEAD(it))
		{
			// player's bbox gets resized now, instead of in the damage event that killed the player,
			// once all the damage events of this frame have been processed with normal size
			float h = ceil((it.mins.z + it.maxs.z) * PL_CORPSE_SCALE * 10) / 10;
			it.maxs.z = max(h, it.mins.z + 1);
			setsize(it, it.mins, it.maxs);
		}
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

		// if a timeout is active, reset the slowmo value to normal
		if(timeout_status == TIMEOUT_ACTIVE)
			cvar_set("slowmo", ftos(orig_slowmo));

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
		if(autocvar_developer > 0)
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

		strfree(sv_termsofservice_url_escaped);
		strfree(loaded_gametype_custom_string);
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
