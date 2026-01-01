#include "spawnpoints.qh"

#include <common/constants.qh>
#include <common/gametypes/_mod.qh>
#include <common/mapobjects/subs.qh>
#include <common/mapobjects/target/spawnpoint.qh>
#include <common/mapobjects/triggers.qh>
#include <common/net_linked.qh>
#include <common/stats.qh>
#include <common/teams.qh>
#include <common/util.qh>
#include <common/weapons/_all.qh>
#include <lib/warpzone/common.qh>
#include <lib/warpzone/util_server.qh>
#include <server/command/vote.qh>
#include <server/intermission.qh>
#include <server/mutators/_mod.qh>
#include <server/race.qh>
#include <server/utils.qh>
#include <server/world.qh>

bool SpawnPoint_Send(entity this, entity to, int sf)
{
	WriteHeader(MSG_ENTITY, ENT_CLIENT_SPAWNPOINT);

	WriteByte(MSG_ENTITY, this.team);
	WriteVector(MSG_ENTITY, this.origin);

	return true;
}

bool SpawnEvent_Send(entity this, entity to, int sf)
{
	float send;

	WriteHeader(MSG_ENTITY, ENT_CLIENT_SPAWNEVENT);

	if(autocvar_g_spawn_alloweffects)
	{
		WriteByte(MSG_ENTITY, etof(this.owner));
		WriteVector(MSG_ENTITY, this.owner.origin);
		WriteByte(MSG_ENTITY, this.owner.team);
		WriteByte(MSG_ENTITY, autocvar_g_spawn_alloweffects);
		send = true;
	}
	else if((to == this.owner) || (IS_SPEC(to) && (to.enemy == this.owner)) )
	{
		WriteByte(MSG_ENTITY, 0);
		send = true;
	}
	else { send = false; }

	return send;
}

.vector spawnpoint_prevorigin;
void spawnpoint_think(entity this)
{
	this.nextthink = time + 0.1;
	if(this.origin != this.spawnpoint_prevorigin)
	{
		this.spawnpoint_prevorigin = this.origin;
		this.SendFlags |= 1;
	}
}

void spawnpoint_use(entity this, entity actor, entity trigger)
{
	if(teamplay)
	if(have_team_spawns > 0)
	{
		this.team = actor.team;
		some_spawn_has_been_used = true;
		this.SendFlags |= 1; // update team on the client side
	}
	//LOG_INFO("spawnpoint was used!\n");
}

bool spawnpoint_customize(entity this, entity client)
{
	return (this.active == ACTIVE_ACTIVE);
}

void spawnpoint_setactive(entity this, int act)
{
	int old_status = this.active;
	if(act == ACTIVE_TOGGLE)
		this.active = (this.active == ACTIVE_ACTIVE) ? ACTIVE_NOT : ACTIVE_ACTIVE;
	else
		this.active = act;

	if(this.active != old_status)
	{
		// mappers may attempt to let players disable enemy spawns
		if(teamplay && have_team_spawns > 0)
			some_spawn_has_been_used = true;
		this.SendFlags |= 1;
	}
}
void spawnpoint_reset(entity this)
{
	this.active = ACTIVE_ACTIVE;
	this.SendFlags |= 1; // update team since it was restored during reset
}

void link_spawnpoint(entity this)
{
	bool anypoint = (autocvar_g_spawn_useallspawns || (teamplay && have_team_spawns <= 0)); // TODO: check if available teams is equal to spawnpoints available

	// Don't show team spawns in non-team matches,
	// and don't show non-team spawns in team matches.
	// (Unless useallspawns is activated)
	if(anypoint || !((teamplay && !Team_IsValidTeam(this.team)) || (!teamplay && Team_IsValidTeam(this.team))))
		Net_LinkEntity(this, false, 0, SpawnPoint_Send);
}

void relocate_spawnpoint(entity this)
{
    // nudge off the floor
    setorigin(this, this.origin + '0 0 1');

    tracebox(this.origin, PL_MIN_CONST, PL_MAX_CONST, this.origin, true, this);
    if (trace_startsolid)
    {
        vector o;
        o = this.origin;
        this.mins = PL_MIN_CONST;
        this.maxs = PL_MAX_CONST;
        if (!move_out_of_solid(this))
            objerror(this, "could not get out of solid at all!");
        LOG_INFOF(
            "^1NOTE: this map needs FIXING. Spawnpoint at %s needs to be moved out of solid, e.g. by %s",
            vtos(o - '0 0 1'),
            vtos(this.origin - o)
        );
        if (autocvar_g_spawnpoints_auto_move_out_of_solid)
        {
            if (!spawnpoint_nag)
                LOG_INFO("\{1}^1NOTE: this map needs FIXING (it contains spawnpoints in solid, see server log)");
            spawnpoint_nag = 1;
        }
        else
        {
            setorigin(this, o);
            this.mins = this.maxs = '0 0 0';
            objerror(this, "player spawn point in solid, mapper sucks!\n");
            return;
        }
    }

    this.active = ACTIVE_ACTIVE;
    this.setactive = spawnpoint_setactive;
    setcefc(this, spawnpoint_customize);
    this.use = spawnpoint_use;
    setthink(this, spawnpoint_think);
    this.nextthink = time + 0.5 + random() * 2; // shouldn't need it for a little second
    this.reset2 = spawnpoint_reset; // restores team, allows re-sending the spawnpoint
    this.team_saved = this.team;
    IL_PUSH(g_saved_team, this);
    if (!this.cnt)
        this.cnt = 1;

    if (have_team_spawns != 0)
        if (this.team)
            have_team_spawns = 1;
    have_team_spawns_forteams |= BIT(this.team);

    if (autocvar_r_showbboxes)
    {
        // show where spawnpoints point at too
        vector forward, right, up;
        MAKE_VECTORS(this.angles, forward, right, up);
        entity e = new(info_player_foo);
        setorigin(e, this.origin + forward * 24);
        setsize(e, '-8 -8 -8', '8 8 8');
        e.solid = SOLID_TRIGGER;
    }

    // network it after all spawnpoints are setup, so that we can check if team spawnpoints are used
	InitializeEntity(this, link_spawnpoint, INITPRIO_FINDTARGET);
}

spawnfunc(info_player_survivor)
{
	spawnfunc_info_player_deathmatch(this);
}

spawnfunc(info_player_start)
{
	spawnfunc_info_player_deathmatch(this);
}

spawnfunc(info_player_deathmatch)
{
	IL_PUSH(g_spawnpoints, this);
	relocate_spawnpoint(this);
}

/*QUAKED spawnfunc_info_player_team1 (1 0 0) (-16 -16 -24) (16 16 24)
Starting point for a player in team one (Red).
Keys: "angle" viewing angle when spawning. */
spawnfunc(info_player_team1)
{
	this.team = NUM_TEAM_1; // red
	spawnfunc_info_player_deathmatch(this);
}


/*QUAKED spawnfunc_info_player_team2 (1 0 0) (-16 -16 -24) (16 16 24)
Starting point for a player in team two (Blue).
Keys: "angle" viewing angle when spawning. */
spawnfunc(info_player_team2)
{
	this.team = NUM_TEAM_2; // blue
	spawnfunc_info_player_deathmatch(this);
}

/*QUAKED spawnfunc_info_player_team3 (1 0 0) (-16 -16 -24) (16 16 24)
Starting point for a player in team three (Yellow).
Keys: "angle" viewing angle when spawning. */
spawnfunc(info_player_team3)
{
	this.team = NUM_TEAM_3; // yellow
	spawnfunc_info_player_deathmatch(this);
}


/*QUAKED spawnfunc_info_player_team4 (1 0 0) (-16 -16 -24) (16 16 24)
Starting point for a player in team four (Purple).
Keys: "angle" viewing angle when spawning. */
spawnfunc(info_player_team4)
{
	this.team = NUM_TEAM_4; // purple
	spawnfunc_info_player_deathmatch(this);
}

// Returns:
//   _x: prio (-1 if unusable)
//   _y: weight
vector Spawn_Score(entity this, entity spot, float mindist, float teamcheck, bool targetcheck)
{
	// filter out spots for the wrong team
	if(teamcheck >= 0)
		if(spot.team != teamcheck)
			return '-1 0 0';

	if(race_spawns)
		if(!spot.target || spot.target == "")
			return '-1 0 0';

	if(spot.active != ACTIVE_ACTIVE && targetcheck)
		return '-1 0 0';

	if(IS_REAL_CLIENT(this))
	{
		if(spot.restriction == 1)
			return '-1 0 0';
	}
	else
	{
		if(spot.restriction == 2)
			return '-1 0 0';
	}

	float prio = 0;
	float shortest = vlen(world.maxs - world.mins);
	FOREACH_CLIENT(IS_PLAYER(it) && !IS_DEAD(it) && it != this, {
		float thisdist = vlen(it.origin - spot.origin);
		if (thisdist < shortest)
			shortest = thisdist;
	});
	if(shortest > mindist)
		prio += SPAWN_PRIO_GOOD_DISTANCE;

	vector spawn_score = prio * '1 0 0' + shortest * '0 1 0';

	// filter out spots for assault
	if(spot.target && spot.target != "" && targetcheck)
	{
		int found = 0;
		for(entity targ = findchain(targetname, spot.target); targ; targ = targ.chain)
		{
			++found;
			if(targ.spawn_evalfunc)
			{
				spawn_score = targ.spawn_evalfunc(targ, this, spot, spawn_score);
				if(spawn_score.x < 0)
					return spawn_score;
			}
		}

		if(!found && !g_cts)
		{
			LOG_TRACE("WARNING: spawnpoint at ", vtos(spot.origin), " could not find its target ", spot.target);
			return '-1 0 0';
		}
	}

	MUTATOR_CALLHOOK(Spawn_Score, this, spot, spawn_score);
	spawn_score = M_ARGV(2, vector);
	return spawn_score;
}

void Spawn_ScoreAll(entity this, entity firstspot, float mindist, float teamcheck, bool targetcheck)
{
	entity spot;
	for(spot = firstspot; spot; spot = spot.chain)
		spot.spawnpoint_score = Spawn_Score(this, spot, mindist, teamcheck, targetcheck);
}

entity Spawn_FilterOutBadSpots(entity this, entity firstspot, float mindist, float teamcheck, bool targetcheck)
{
	entity spot, spotlist, spotlistend;

	spotlist = NULL;
	spotlistend = NULL;

	Spawn_ScoreAll(this, firstspot, mindist, teamcheck, targetcheck);

	for(spot = firstspot; spot; spot = spot.chain)
	{
		if(spot.spawnpoint_score.x >= 0) // spawning allowed here
		{
			if(spotlistend)
				spotlistend.chain = spot;
			spotlistend = spot;
			if(!spotlist)
				spotlist = spot;
		}
	}
	if(spotlistend)
		spotlistend.chain = NULL;

	return spotlist;
}

entity Spawn_WeightedPoint(entity firstspot, float lower, float upper, float exponent)
{
	// weight of a point: bound(lower, mindisttoplayer, upper)^exponent
	// multiplied by spot.cnt (useful if you distribute many spawnpoints in a small area)
	entity spot;

	RandomSelection_Init();
	for(spot = firstspot; spot; spot = spot.chain)
		RandomSelection_AddEnt(spot, (bound(lower, spot.spawnpoint_score.y, upper) ** exponent) * spot.cnt, (spot.spawnpoint_score.y >= lower) * 0.5 + spot.spawnpoint_score.x);

	return RandomSelection_chosen_ent;
}

/*
=============
SelectSpawnPoint

Finds a point to respawn
=============
*/
bool testspawn_checked;
entity testspawn_point;
entity SelectSpawnPoint(entity this, bool anypoint)
{
	float teamcheck;
	entity spot = NULL;

	if(!testspawn_checked)
	{
		testspawn_point = find(NULL, classname, "testplayerstart");
		testspawn_checked = true;
	}

	if(testspawn_point)
		return testspawn_point;

	if(this.spawnpoint_targ)
		return this.spawnpoint_targ;

	if(anypoint || autocvar_g_spawn_useallspawns)
		teamcheck = -1;
	else if(have_team_spawns > 0)
	{
		if(!(have_team_spawns_forteams & BIT(this.team)))
		{
			// we request a spawn for a team, and we have team
			// spawns, but that team has no spawns?
			if(have_team_spawns_forteams & BIT(0))
				// try noteam spawns
				teamcheck = 0;
			else
				// if not, any spawn has to do
				teamcheck = -1;
		}
		else
			teamcheck = this.team; // MUST be team
	}
	else if(have_team_spawns == 0 && (have_team_spawns_forteams & BIT(0)))
		teamcheck = 0; // MUST be noteam
	else
		teamcheck = -1;
		// if we get here, we either require team spawns but have none, or we require non-team spawns and have none; use any spawn then


	// get the entire list of spots
	//entity firstspot = findchain(classname, "info_player_deathmatch");
	entity firstspot = IL_FIRST(g_spawnpoints);
	entity prev = NULL;
	IL_EACH(g_spawnpoints, true,
	{
		if(prev)
			prev.chain = it;
		it.chain = NULL;
		prev = it;
	});
	// filter out the bad ones
	// (note this returns the original list if none survived)
	if(anypoint)
	{
		spot = Spawn_WeightedPoint(firstspot, 1, 1, 1);
	}
	else
	{
		firstspot = Spawn_FilterOutBadSpots(this, firstspot, 100, teamcheck, true);

		// emergency fallback! double check without targets
		// fixes some crashes with improperly repacked maps
		if(!firstspot)
		{
			firstspot = IL_FIRST(g_spawnpoints);
			prev = NULL;
			IL_EACH(g_spawnpoints, true,
			{
				if(prev)
					prev.chain = it;
				it.chain = NULL;
				prev = it;
			});
			firstspot = Spawn_FilterOutBadSpots(this, firstspot, 100, teamcheck, false);
		}

		// there is 50/50 chance of choosing a random spot or the furthest spot
		// (this means that roughly every other spawn will be furthest, so you
		// usually won't get fragged at spawn twice in a row)
		if (random() > autocvar_g_spawn_furthest)
			spot = Spawn_WeightedPoint(firstspot, 1, 1, 1);
		else
			spot = Spawn_WeightedPoint(firstspot, 1, 5000, 5); // chooses a far far away spawnpoint
	}

	if (!spot)
	{
		if(autocvar_spawn_debug)
			GotoNextMap(0);
		else
		{
			if(some_spawn_has_been_used)
				return NULL; // team can't spawn any more, because of actions of other team
			else
				error("Cannot find a spawn point - please fix the map!");
		}
	}

	return spot;
}
