#include "main.qh"

#include <common/command/generic.qh>
#include <common/constants.qh>
#include <common/deathtypes/all.qh>
#include <common/debug.qh>
#include <common/mapinfo.qh>
#include <common/mapobjects/_mod.qh>
#include <common/monsters/sv_monsters.qh>
#include <common/util.qh>
#include <common/vehicles/all.qh>
#include <common/weapons/_all.qh>
#include <lib/csqcmodel/sv_model.qh>
#include <lib/warpzone/common.qh>
#include <lib/warpzone/server.qh>
#include <server/anticheat.qh>
#include <server/bot/api.qh>
#include <server/command/common.qh>
#include <server/compat/quake3.qh>
#include <server/damage.qh>
#include <server/gamelog.qh>
#include <server/hook.qh>
#include <server/ipban.qh>
#include <server/mutators/_mod.qh>
#include <server/spawnpoints.qh>
#include <server/weapons/common.qh>
#include <server/weapons/csqcprojectile.qh>
#include <server/world.qh>

void dropclient_do(entity this)
{
	if (this.owner)
		dropclient(this.owner);
	delete(this);
}

/**
 * Schedules dropclient for a player and returns true;
 * if dropclient is already scheduled (for that player) it does nothing and returns false.
 *
 * NOTE: this function exists only to allow sending a message to the kicked player with
 * Send_Notification, which doesn't work if called together with dropclient
 */
bool dropclient_schedule(entity this)
{
	bool scheduled = false;
	FOREACH_ENTITY_CLASS("dropclient_handler", true,
	{
		if(it.owner == this)
		{
			scheduled = true;
			break; // can't use return here, compiler shows a warning
		}
	});
	if (scheduled)
		return false;

	entity e = new_pure(dropclient_handler);
	setthink(e, dropclient_do);
	e.owner = this;
	e.nextthink = time + 0.1;

	// ignore this player for team balancing and queuing
	this.team = -1;
	this.wants_join = 0;
	this.classname = STR_OBSERVER;
	return true;
}

void CreatureFrame_hotliquids(entity this)
{
	if (this.contents_damagetime >= time)
	{
		return;
	}

	this.contents_damagetime = time + autocvar_g_balance_contents_damagerate;

	if (this.flags & FL_PROJECTILE)
	{
		if (this.watertype == CONTENT_LAVA)
			Damage (this, NULL, NULL, autocvar_g_balance_contents_projectiledamage * autocvar_g_balance_contents_damagerate * this.waterlevel, DEATH_LAVA.m_id, DMG_NOWEP, this.origin, '0 0 0');
		else if (this.watertype == CONTENT_SLIME)
			Damage (this, NULL, NULL, autocvar_g_balance_contents_projectiledamage * autocvar_g_balance_contents_damagerate * this.waterlevel, DEATH_SLIME.m_id, DMG_NOWEP, this.origin, '0 0 0');
	}
	else
	{
		// TODO: do we even need this hack? frozen players still die in lava!
		if (STAT(FROZEN, this))
		{
			if (this.watertype == CONTENT_LAVA)
				Damage(this, NULL, NULL, 10000, DEATH_LAVA.m_id, DMG_NOWEP, this.origin, '0 0 0');
			else if (this.watertype == CONTENT_SLIME)
				Damage(this, NULL, NULL, 10000, DEATH_SLIME.m_id, DMG_NOWEP, this.origin, '0 0 0');
		}
		else if (this.watertype == CONTENT_LAVA)
		{
			if (this.watersound_finished < time)
			{
				this.watersound_finished = time + 0.5;
				sound (this, CH_PLAYER_SINGLE, SND_LAVA, VOL_BASE, ATTEN_NORM);
			}
			Damage (this, NULL, NULL, autocvar_g_balance_contents_playerdamage_lava * autocvar_g_balance_contents_damagerate * this.waterlevel, DEATH_LAVA.m_id, DMG_NOWEP, this.origin, '0 0 0');
			if(autocvar_g_balance_contents_playerdamage_lava_burn)
				Fire_AddDamage(this, NULL, autocvar_g_balance_contents_playerdamage_lava_burn * this.waterlevel, autocvar_g_balance_contents_playerdamage_lava_burn_time * this.waterlevel, DEATH_LAVA.m_id);
		}
		else if (this.watertype == CONTENT_SLIME)
		{
			if (this.watersound_finished < time)
			{
				this.watersound_finished = time + 0.5;
				sound (this, CH_PLAYER_SINGLE, SND_SLIME, VOL_BASE, ATTEN_NORM);
			}
			Damage (this, NULL, NULL, autocvar_g_balance_contents_playerdamage_slime * autocvar_g_balance_contents_damagerate * this.waterlevel, DEATH_SLIME.m_id, DMG_NOWEP, this.origin, '0 0 0');
		}
	}
}

void CreatureFrame_Liquids(entity this)
{
	if (this.watertype <= CONTENT_WATER && this.waterlevel > 0) // workaround a retarded bug made by id software :P (yes, it's that old of a bug)
	{
		if (!(this.flags & FL_INWATER))
		{
			this.flags |= FL_INWATER;
			this.contents_damagetime = 0;
		}

		CreatureFrame_hotliquids(this);
	}
	else
	{
		if (this.flags & FL_INWATER)
		{
			// play leave water sound
			this.flags &= ~FL_INWATER;
			this.contents_damagetime = 0;
		}
	}
}

void CreatureFrame_FallDamage(entity this)
{
	if(IS_VEHICLE(this) || (this.flags & FL_PROJECTILE))
		return; // vehicles and projectiles don't receive fall damage
	if(!(this.velocity || this.oldvelocity))
		return; // if the entity hasn't moved and isn't moving, then don't do anything

	// check for falling damage
	bool have_hook = false;
	for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	{
		.entity weaponentity = weaponentities[slot];
		if(this.(weaponentity).hook && this.(weaponentity).hook.state)
		{
			have_hook = true;
			break;
		}
	}
	if(!have_hook)
	{
		float dm; // dm is the velocity DECREASE. Velocity INCREASE should never cause a sound or any damage.
		if(autocvar_g_balance_falldamage_onlyvertical)
			dm = fabs(this.oldvelocity.z) - vlen(this.velocity);
		else
			dm = vlen(this.oldvelocity) - vlen(this.velocity);
		if (IS_DEAD(this))
			dm = (dm - autocvar_g_balance_falldamage_deadminspeed) * autocvar_g_balance_falldamage_factor;
		else
			dm = min((dm - autocvar_g_balance_falldamage_minspeed) * autocvar_g_balance_falldamage_factor, autocvar_g_balance_falldamage_maxdamage);
		if (dm > 0)
		{
			tracebox(this.origin, this.mins, this.maxs, this.origin - '0 0 1', MOVE_NOMONSTERS, this);
			if (!(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NODAMAGE))
				Damage (this, NULL, NULL, dm, DEATH_FALL.m_id, DMG_NOWEP, this.origin, '0 0 0');
		}
	}

	if(autocvar_g_maxspeed > 0 && vdist(this.velocity, >, autocvar_g_maxspeed))
		Damage (this, NULL, NULL, 100000, DEATH_SHOOTING_STAR.m_id, DMG_NOWEP, this.origin, '0 0 0');
}

void CreatureFrame_All()
{
	if(game_stopped || time < game_starttime)
		return;

	IL_EACH(g_damagedbycontents, it.damagedbycontents,
	{
		if (it.move_movetype == MOVETYPE_NOCLIP) continue;
		CreatureFrame_Liquids(it);
		CreatureFrame_FallDamage(it);
		it.oldvelocity = it.velocity;
	});
}

// called shortly after map change in dedicated
void Pause_TryPause_Dedicated(entity this)
{
	if (player_count == 0 && !intermission_running && !autocvar__endmatch)
		setpause(1);
}

// called every normal frame in singleplayer/listen
void Pause_TryPause()
{
	int n = 0, p = 0;
	FOREACH_CLIENT(IS_REAL_CLIENT(it), {
		if (PHYS_INPUT_BUTTON_CHAT(it)) ++p;
		++n;
	});
	if (!n) return;
	if (n == p)
		setpause(1);
	else
		setpause(0);
}

// called every paused frame by DP
void SV_PausedTic(float elapsedtime)
{
	if (autocvar__endmatch) // `endmatch` while paused
		setpause(0); // proceed to intermission
	else if (!server_is_dedicated)
	{
		if (autocvar_sv_autopause)
			Pause_TryPause();
		else
			setpause(0);
	}
}

void dedicated_print(string input)
{
	if (server_is_dedicated) print(input);
}

void make_safe_for_remove(entity e)
{
	if (e.initialize_entity)
	{
		entity ent, prev = NULL;
		for (ent = initialize_entity_first; ent; )
		{
			if ((ent == e) || ((ent.classname == "initialize_entity") && (ent.enemy == e)))
			{
				//print("make_safe_for_remove: getting rid of initializer ", etos(ent), "\n");
				// skip it in linked list
				if (prev)
				{
					prev.initialize_entity_next = ent.initialize_entity_next;
					ent = prev.initialize_entity_next;
				}
				else
				{
					initialize_entity_first = ent.initialize_entity_next;
					ent = initialize_entity_first;
				}
			}
			else
			{
				prev = ent;
				ent = ent.initialize_entity_next;
			}
		}
	}
}

void remove_except_protected(entity e)
{
	if(e.remove_except_protected_forbidden)
		error("not allowed to remove this at this point");
	builtin_remove(e);
}

void remove_unsafely(entity e)
{
	if(e.classname == "spike")
		error("Removing spikes is forbidden (crylink bug), please report");
	builtin_remove(e);
}

void remove_safely(entity e)
{
	make_safe_for_remove(e);
	builtin_remove(e);
}

/*
=============
StartFrame

Called before each frame by the server
=============
*/

bool game_delay_last;

void systems_update();
void sys_phys_update(entity this, float dt);
void StartFrame()
{
	FOREACH_CLIENT(IS_FAKE_CLIENT(it),
	{
		// DP calls these for real clients only
		sys_phys_update(it, frametime); // called by SV_PlayerPhysics for players
		PlayerPreThink(it);
	});

	execute_next_frame();

	delete_fn = remove_unsafely; // not during spawning!
	serverprevtime = servertime;
	servertime = time;
	serverframetime = frametime;

#ifdef PROFILING
	if(time > client_cefc_accumulatortime + 1)
	{
		float t = client_cefc_accumulator / (time - client_cefc_accumulatortime);
		int c_seeing = 0;
		int c_seen = 0;
		FOREACH_CLIENT(true, {
			if(IS_REAL_CLIENT(it))
				++c_seeing;
			if(IS_PLAYER(it))
				++c_seen;
		});
		LOG_INFO(
			"CEFC time: ", ftos(t * 1000), "ms; ",
			"CEFC calls per second: ", ftos(c_seeing * (c_seen - 1) / t), "; ",
			"CEFC 100% load at: ", ftos(solve_quadratic(t, -t, -1) * '0 1 0')
		);
		client_cefc_accumulatortime = time;
		client_cefc_accumulator = 0;
	}
#endif

	IL_EACH(g_projectiles, it.csqcprojectile_clientanimate, CSQCProjectile_Check(it));

	if (RedirectionThink()) return;

	UncustomizeEntitiesRun();
	InitializeEntitiesRun();

	WarpZone_StartFrame();

	sys_frametime = autocvar_sys_ticrate * autocvar_slowmo;
	if (sys_frametime <= 0) sys_frametime = 1.0 / 60.0; // somewhat safe fallback

	if (timeout_status == TIMEOUT_LEADTIME) // just before the timeout (when timeout_status will be TIMEOUT_ACTIVE)
		orig_slowmo = autocvar_slowmo; // slowmo will be restored after the timeout

	// detect when the pre-game countdown (if any) has ended and the game has started
	bool game_delay = (time < game_starttime);
	if (autocvar_sv_eventlog && game_delay_last && !game_delay)
		GameLogEcho(":startdelay_ended");
	game_delay_last = game_delay;

	CreatureFrame_All();
	CheckRules_World();

	// after CheckRules_World() as it may set intermission_running, and after RedirectionThink() in case listen server is closing
	if (autocvar_sv_autopause && !server_is_dedicated && !intermission_running)
		Pause_TryPause();

	if (warmup_stage && !game_stopped && warmup_limit > 0 && time - game_starttime >= warmup_limit) {
		ReadyRestart(true);
		return;
	}

	bot_serverframe();
	anticheat_startframe();
	MUTATOR_CALLHOOK(SV_StartFrame);

	GlobalStats_updateglobal();
	FOREACH_CLIENT(true,
	{
		GlobalStats_update(it);
		if (IS_FAKE_CLIENT(it))
			PlayerPostThink(it); // DP calls this for real clients only
		PlayerFrame(it);
	});
}

.vector originjitter;
.vector anglesjitter;
.float anglejitter;
.string gametypefilter;
.string cvarfilter;

void SV_OnEntityPreSpawnFunction(entity this)
{
	if (this)
	if (this.gametypefilter != "")
	if (!isGametypeInFilter(MapInfo_LoadedGametype, teamplay, have_team_spawns, this.gametypefilter))
	{
		delete(this);
		return;
	}
	if (this.cvarfilter != "" && !expr_evaluate(this.cvarfilter)) {
		delete(this);
		return;
	}

	if (q3compat && DoesQ3ARemoveThisEntity(this)) {
		delete(this);
		return;
	}

	set_movetype(this, this.movetype);

	if (this.monster_attack) {
		IL_PUSH(g_monster_targets, this);
	}

	// support special -1 and -2 angle from radiant
	if (this.angles == '0 -1 0') {
		this.angles = '-90 0 0';
	} else if (this.angles == '0 -2 0') {
		this.angles = '+90 0 0';
	}

	#define X(out, in) MACRO_BEGIN \
		if (in != 0) { out = out + (random() * 2 - 1) * in; } \
	MACRO_END
	X(this.origin.x, this.originjitter.x); X(this.origin.y, this.originjitter.y); X(this.origin.z, this.originjitter.z);
	X(this.angles.x, this.anglesjitter.x); X(this.angles.y, this.anglesjitter.y); X(this.angles.z, this.anglesjitter.z);
	X(this.angles.y, this.anglejitter);
	#undef X

	if (MUTATOR_CALLHOOK(OnEntityPreSpawn, this)) {
		delete(this);
		return;
	}
}

/** Retrieves the value of a map entity field from fullspawndata.
 * This bypasses field value changes made by the engine,
 * eg string-to-float and escape sequence substitution.
 *
 * Avoids the need to declare fields just to read them once :)
 *
 * Returns the last instance of the field to match DarkPlaces behaviour.
 *
 * Path support: converts \ to / and checks the file exists, if vfspath is true.
 * Returns string_null if the entity does not have the field, or the file is not in the VFS.
 *
 * FIXME: entities with //comments are not supported.
 */
string GetField_fullspawndata(entity e, string fieldname, bool vfspath)
{
	string v = string_null;

	if (!e.fullspawndata) // Engine lacks support, warning spam in CheckEngineExtensions()
		return v;

	if (strstrofs(e.fullspawndata, "//", 0) >= 0)
	{
		// tokenize and tokenize_console return early if "//" is reached,
		// which can leave an odd number of tokens and break key:value pairing.
		LOG_WARNF("^1EDICT %s fullspawndata contains unsupported //comment^7%s", ftos(num_for_edict(e)), e.fullspawndata);
		return v;
	}

	//print(sprintf("%s(EDICT %s, FIELD %s)\n", __FUNC__, ftos(num_for_edict(e)), fieldname));
	//print(strcat("FULLSPAWNDATA:", e.fullspawndata, "\n"));

	// tokenize treats \ as an escape, but tokenize_console returns the required literal
	for (int t = tokenize_console(e.fullspawndata) - 3; t > 0; t -= 2)
	{
		//print(sprintf("\tTOKEN %s:%s\t%s:%s\n", ftos(t), ftos(t + 1), argv(t), argv(t + 1)));
		if (argv(t) == fieldname)
		{
			v = argv(t + 1);
			break;
		}
	}

	//print(strcat("RESULT: ", v, "\n\n"));

	if (v && vfspath)
	{
		v = strreplace("\\", "/", v);
		if (whichpack(v) == "")
			return string_null;
	}

	return v;
}

/*
=============
FindFileInMapPack

Returns the first matching VFS file path that exists in the current map's pack.
Returns string_null if no files match or the map isn't packaged.
=============
*/
string FindFileInMapPack(string pattern)
{
	if (!checkextension("DP_QC_FS_SEARCH_PACKFILE"))
		return string_null;

	string base_pack = whichpack(strcat("maps/", mapname, ".bsp"));
	if (base_pack == "" || !base_pack) // this map isn't packaged or there was an error
		return string_null;

	int glob = search_packfile_begin(pattern, true, true, base_pack);
	if (glob < 0)
		return string_null;

	string file = search_getfilename(glob, 0);
	search_end(glob);
	return file;
}

void WarpZone_PostInitialize_Callback()
{
	// create waypoint links for warpzones
	entity tracetest_ent = spawn();
	setsize(tracetest_ent, PL_MIN_CONST, PL_MAX_CONST);
	tracetest_ent.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_PLAYERCLIP | DPCONTENTS_BOTCLIP;
	//for(entity e = warpzone_first; e; e = e.warpzone_next)
	for(entity e = NULL; (e = find(e, classname, "trigger_warpzone")); )
		waypoint_spawnforteleporter_wz(e, tracetest_ent);
	delete(tracetest_ent);
}

/** engine callback */
void URI_Get_Callback(float id, float status, string data)
{
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
	else if (id >= URI_GET_IPBAN && id <= URI_GET_IPBAN_END)
	{
		// online ban list
		OnlineBanList_URI_Get_Callback(id, status, data);
	}
	else if (MUTATOR_CALLHOOK(URI_GetCallback, id, status, data))
	{
		// handled by a mutator
	}
	else
	{
		LOG_INFO("Received HTTP request data for an invalid id ", ftos(id), ".");
	}
}

/*
==================
main

unused but required by the engine
==================
*/
void main ()
{

}
