#include "sv_domination.qh"

#include <server/client.qh>
#include <server/command/vote.qh>
#include <server/damage.qh>
#include <server/gamelog.qh>
#include <server/items/items.qh>
#include <server/teamplay.qh>
#include <server/world.qh>
#include <common/mapobjects/platforms.qh>
#include <common/mapobjects/triggers.qh>

bool g_domination;

int autocvar_g_domination_default_teams;
bool autocvar_g_domination_disable_frags;
int autocvar_g_domination_point_amt;
bool autocvar_g_domination_point_fullbright;
float autocvar_g_domination_round_timelimit;
float autocvar_g_domination_warmup;
float autocvar_g_domination_point_rate;
int autocvar_g_domination_teams_override;

void dom_EventLog(string mode, float team_before, entity actor) // use an alias for easy changing and quick editing later
{
	if(autocvar_sv_eventlog)
		GameLogEcho(strcat(":dom:", mode, ":", ftos(team_before), ((actor != NULL) ? (strcat(":", ftos(actor.playerid))) : "")));
}

void set_dom_state(entity e)
{
	STAT(DOM_TOTAL_PPS, e) = total_pps;
	STAT(DOM_PPS_RED, e) = pps_red;
	STAT(DOM_PPS_BLUE, e) = pps_blue;
	if(domination_teams & BIT(2))
		STAT(DOM_PPS_YELLOW, e) = pps_yellow;
	if(domination_teams & BIT(3))
		STAT(DOM_PPS_PINK, e) = pps_pink;
}

void dompoint_captured(entity this)
{
	float old_delay, old_team, real_team;

	// now that the delay has expired, switch to the latest team to lay claim to this point
	entity head = this.owner;

	real_team = this.cnt;
	this.cnt = -1;

	dom_EventLog("taken", this.team, this.dmg_inflictor);
	this.dmg_inflictor = NULL;

	this.goalentity = head;
	this.model = head.mdl;
	this.modelindex = head.dmg;
	this.skin = head.skin;

	float points, wait_time;
	if (autocvar_g_domination_point_amt)
		points = autocvar_g_domination_point_amt;
	else
		points = this.frags;
	if (autocvar_g_domination_point_rate)
		wait_time = autocvar_g_domination_point_rate;
	else
		wait_time = this.wait;

	if(domination_roundbased)
		bprint(sprintf("^3%s^3%s\n", head.netname, this.message));
	else
		Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_DOMINATION_CAPTURE_TIME, head.netname, this.message, points, wait_time);

	if(this.enemy.playerid == this.enemy_playerid)
		GameRules_scoring_add(this.enemy, DOM_TAKES, 1);
	else
		this.enemy = NULL;

	if (head.noise != "")
	{
		if(this.enemy)
			_sound(this.enemy, CH_TRIGGER, head.noise, VOL_BASE, ATTEN_NORM);
		else
			_sound(this, CH_TRIGGER, head.noise, VOL_BASE, ATTEN_NORM);
	}
	if (head.noise1 != "")
		play2all(head.noise1);

	this.delay = time + wait_time;

	// do trigger work
	old_delay = this.delay;
	old_team = this.team;
	this.team = real_team;
	this.delay = 0;
	SUB_UseTargets (this, this, NULL);
	this.delay = old_delay;
	this.team = old_team;

	entity msg = WP_DomNeut;
	switch(real_team)
	{
		case NUM_TEAM_1: msg = WP_DomRed; break;
		case NUM_TEAM_2: msg = WP_DomBlue; break;
		case NUM_TEAM_3: msg = WP_DomYellow; break;
		case NUM_TEAM_4: msg = WP_DomPink; break;
	}

	WaypointSprite_UpdateSprites(this.sprite, msg, WP_Null, WP_Null);

	total_pps = 0, pps_red = 0, pps_blue = 0, pps_yellow = 0, pps_pink = 0;
	IL_EACH(g_dompoints, true,
	{
		if (autocvar_g_domination_point_amt)
			points = autocvar_g_domination_point_amt;
		else
			points = it.frags;
		if (autocvar_g_domination_point_rate)
			wait_time = autocvar_g_domination_point_rate;
		else
			wait_time = it.wait;
		switch(it.goalentity.team)
		{
			case NUM_TEAM_1: pps_red += points/wait_time; break;
			case NUM_TEAM_2: pps_blue += points/wait_time; break;
			case NUM_TEAM_3: pps_yellow += points/wait_time; break;
			case NUM_TEAM_4: pps_pink += points/wait_time; break;
		}
		total_pps += points/wait_time;
	});

	WaypointSprite_UpdateTeamRadar(this.sprite, RADARICON_DOMPOINT, colormapPaletteColor(this.goalentity.team - 1, 0));
	WaypointSprite_Ping(this.sprite);

	this.captime = time;

	FOREACH_CLIENT(IS_REAL_CLIENT(it), { set_dom_state(it); });
}

void AnimateDomPoint(entity this)
{
	if(this.pain_finished > time)
		return;
	this.pain_finished = time + this.t_width;
	if(this.nextthink > this.pain_finished)
		this.nextthink = this.pain_finished;

	this.frame = this.frame + 1;
	if(this.frame > this.t_length)
		this.frame = 0;
}

void dompointthink(entity this)
{
	float fragamt;

	this.nextthink = time + 0.1;

	//this.frame = this.frame + 1;
	//if(this.frame > 119)
	//	this.frame = 0;
	AnimateDomPoint(this);

	// give points

	if (game_stopped || this.delay > time || time < game_starttime)	// game has ended, don't keep giving points
		return;

	if(autocvar_g_domination_point_rate)
		this.delay = time + autocvar_g_domination_point_rate;
	else
		this.delay = time + this.wait;

	// give credit to the team
	// NOTE: this defaults to 0
	if (!domination_roundbased)
	if (this.goalentity.netname != "")
	{
		if(autocvar_g_domination_point_amt)
			fragamt = autocvar_g_domination_point_amt;
		else
			fragamt = this.frags;
		TeamScore_AddToTeam(this.goalentity.team, ST_SCORE, fragamt);
		TeamScore_AddToTeam(this.goalentity.team, ST_DOM_TICKS, fragamt);

		// give credit to the individual player, if they are still there
		if (this.enemy.playerid == this.enemy_playerid)
		{
			GameRules_scoring_add(this.enemy, SCORE, fragamt);
			GameRules_scoring_add(this.enemy, DOM_TICKS, fragamt);
		}
		else
			this.enemy = NULL;
	}
}

void dompointtouch(entity this, entity toucher)
{
	if(!IS_PLAYER(toucher))
		return;
	if(IS_DEAD(toucher))
		return;
	if(IS_INDEPENDENT_PLAYER(toucher))
		return;

	if(round_handler_IsActive() && !round_handler_IsRoundStarted())
		return;

	if(time < this.captime + 0.3)
		return;

	// only valid teams can claim it
	entity head = find(NULL, classname, "dom_team");
	while (head && head.team != toucher.team)
		head = find(head, classname, "dom_team");
	if (!head || head.netname == "" || head == this.goalentity)
		return;

	// delay capture

	this.team = this.goalentity.team; // this stores the PREVIOUS team!

	this.cnt = toucher.team;
	this.owner = head; // team to switch to after the delay
	this.dmg_inflictor = toucher;

	// this.state = 1;
	// this.delay = time + cvar("g_domination_point_capturetime");
	//this.nextthink = time + cvar("g_domination_point_capturetime");
	//this.think = dompoint_captured;

	// go to neutral team in the mean time
	head = find(NULL, classname, "dom_team");
	while (head && head.netname != "")
		head = find(head, classname, "dom_team");
	if(head == NULL)
		return;

	WaypointSprite_UpdateSprites(this.sprite, WP_DomNeut, WP_Null, WP_Null);
	WaypointSprite_UpdateTeamRadar(this.sprite, RADARICON_DOMPOINT, '0 1 1');
	WaypointSprite_Ping(this.sprite);

	this.goalentity = head;
	this.model = head.mdl;
	this.modelindex = head.dmg;
	this.skin = head.skin;

	this.enemy = toucher; // individual player scoring
	this.enemy_playerid = toucher.playerid;
	dompoint_captured(this);
}

void dom_controlpoint_setup(entity this)
{
	entity head;
	// find the spawnfunc_dom_team representing unclaimed points
	head = find(NULL, classname, "dom_team");
	while(head && head.netname != "")
		head = find(head, classname, "dom_team");
	if (!head)
		objerror(this, "no spawnfunc_dom_team with netname \"\" found\n");

	// copy important properties from spawnfunc_dom_team entity
	this.goalentity = head;
	_setmodel(this, head.mdl); // precision already set
	this.skin = head.skin;

	this.cnt = -1;

	if(this.message == "")
		this.message = " has captured a control point";

	if(this.frags <= 0)
		this.frags = 1;
	if(this.wait <= 0)
		this.wait = 5;

	float points, waittime;
	if (autocvar_g_domination_point_amt)
		points = autocvar_g_domination_point_amt;
	else
		points = this.frags;
	if (autocvar_g_domination_point_rate)
		waittime = autocvar_g_domination_point_rate;
	else
		waittime = this.wait;

	total_pps += points/waittime;

	if(!this.t_width)
		this.t_width = 0.02; // frame animation rate
	if(!this.t_length)
		this.t_length = 239; // maximum frame

	setthink(this, dompointthink);
	this.nextthink = time;
	settouch(this, dompointtouch);
	this.solid = SOLID_TRIGGER;
	if(!this.flags & FL_ITEM)
		IL_PUSH(g_items, this);
	this.flags = FL_ITEM;
	setsize(this, '-48 -48 -32', '48 48 32'); // 0.8.6 used '-32 -32 -32', '32 32 32' with sv_legacy_bbox_expand 1 and FL_ITEM
	setorigin(this, this.origin + '0 0 20');
	DropToFloor_QC_DelayedInit(this);

	waypoint_spawnforitem(this);
	WaypointSprite_SpawnFixed(WP_DomNeut, this.origin + '0 0 32', this, sprite, RADARICON_DOMPOINT);
}

int total_control_points;
void Domination_count_controlpoints()
{
	total_control_points = 0;
	for (int i = 1; i <= NUM_TEAMS; ++i)
	{
		Team_SetNumberOfOwnedItems(Team_GetTeamFromIndex(i), 0);
	}
	IL_EACH(g_dompoints, true,
	{
		++total_control_points;
		if (!Entity_HasValidTeam(it.goalentity))
		{
			continue;
		}
		entity team_ = Entity_GetTeam(it.goalentity);
		int num_control_points = Team_GetNumberOfOwnedItems(team_);
		++num_control_points;
		Team_SetNumberOfOwnedItems(team_, num_control_points);
	});
}

bool Domination_CheckWinner()
{
	if(round_handler_GetEndTime() > 0 && round_handler_GetEndTime() - time <= 0)
	{
		Send_Notification(NOTIF_ALL, NULL, MSG_CENTER, CENTER_ROUND_OVER);
		Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_ROUND_OVER);

		game_stopped = true;
		round_handler_Init(5, autocvar_g_domination_warmup, autocvar_g_domination_round_timelimit);
		return true;
	}

	Domination_count_controlpoints();
	int winner_team = Team_GetWinnerTeam_WithOwnedItems(total_control_points);
	if (winner_team == -1)
		return 0;

	if(winner_team > 0)
	{
		Send_Notification(NOTIF_ALL, NULL, MSG_CENTER, APP_TEAM_NUM(winner_team, CENTER_ROUND_TEAM_WIN));
		Send_Notification(NOTIF_ALL, NULL, MSG_INFO, APP_TEAM_NUM(winner_team, INFO_ROUND_TEAM_WIN));
		TeamScore_AddToTeam(winner_team, ST_DOM_CAPS, +1);
	}

	game_stopped = true;
	round_handler_Init(5, autocvar_g_domination_warmup, autocvar_g_domination_round_timelimit);

	return true;
}

bool Domination_CheckPlayers()
{
	return true;
}

void Domination_RoundStart()
{
	FOREACH_CLIENT(IS_PLAYER(it), { it.player_blocked = false; });
}

//go to best items, or control points you don't own
void havocbot_goalrating_controlpoints(entity this, float ratingscale, vector org, float sradius)
{
	IL_EACH(g_dompoints, vdist((((it.absmin + it.absmax) * 0.5) - org), <, sradius),
	{
		if(it.cnt > -1) // this is just being fought
			navigation_routerating(this, it, ratingscale, 5000);
		else if(it.goalentity.cnt == 0) // unclaimed
			navigation_routerating(this, it, ratingscale, 5000);
		else if(it.goalentity.team != this.team) // other team's point
			navigation_routerating(this, it, ratingscale, 5000);
	});
}

void havocbot_role_dom(entity this)
{
	if(IS_DEAD(this))
		return;

	if (navigation_goalrating_timeout(this))
	{
		navigation_goalrating_start(this);
		havocbot_goalrating_controlpoints(this, 10000, this.origin, 15000);
		havocbot_goalrating_items(this, 20000, this.origin, 8000);
		//havocbot_goalrating_enemyplayers(this, 1500, this.origin, 2000);
		havocbot_goalrating_waypoints(this, 1, this.origin, 3000);
		navigation_goalrating_end(this);

		navigation_goalrating_timeout_set(this);
	}
}

MUTATOR_HOOKFUNCTION(dom, TeamBalance_CheckAllowedTeams)
{
	// fallback?
	M_ARGV(0, float) = domination_teams;
	string ret_string = "dom_team";

	entity head = find(NULL, classname, ret_string);
	while(head)
	{
		if(head.netname != "")
		{
			if (Team_IsValidTeam(head.team))
			{
				M_ARGV(0, float) |= Team_TeamToBit(head.team);
			}
		}

		head = find(head, classname, ret_string);
	}

	M_ARGV(1, string) = string_null;

	return true;
}

MUTATOR_HOOKFUNCTION(dom, reset_map_players)
{
	total_pps = 0, pps_red = 0, pps_blue = 0, pps_yellow = 0, pps_pink = 0;
	FOREACH_CLIENT(true, {
		if (IS_PLAYER(it))
		{
			PutClientInServer(it);
			if(domination_roundbased)
				it.player_blocked = 1;
		}
		if(IS_REAL_CLIENT(it))
			set_dom_state(it);
	});
	return true;
}

MUTATOR_HOOKFUNCTION(dom, PlayerSpawn)
{
	entity player = M_ARGV(0, entity);

	if(domination_roundbased)
		player.player_blocked = !round_handler_IsRoundStarted();
}

MUTATOR_HOOKFUNCTION(dom, ClientConnect)
{
	entity player = M_ARGV(0, entity);

	set_dom_state(player);
}

MUTATOR_HOOKFUNCTION(dom, HavocBot_ChooseRole)
{
	entity bot = M_ARGV(0, entity);

	bot.havocbot_role = havocbot_role_dom;
	return true;
}

/*QUAKED spawnfunc_dom_controlpoint (0 .5 .8) (-16 -16 -24) (16 16 32)
Control point for Domination gameplay.
*/
spawnfunc(dom_controlpoint)
{
	if(!g_domination)
	{
		delete(this);
		return;
	}
	setthink(this, dom_controlpoint_setup);
	this.nextthink = time + 0.1;
	this.reset = dom_controlpoint_setup;

	if(!this.scale)
		this.scale = 0.6;

	this.effects = this.effects | EF_LOWPRECISION;
	if (autocvar_g_domination_point_fullbright)
		this.effects |= EF_FULLBRIGHT;

	IL_PUSH(g_dompoints, this);
}

	// Quake Live CP
/*QUAKED team_dom_point (0 .2 1) (-16 -16 0) (16 16 88)
Domination capture point.
-------- KEYS --------
identifier : Set to 1, 2, or 3 to match to point 'A', 'B', or 'C'.
count : Adjust the range of the capture point (in units, eg: 64, 128... etc).
target : Target name for multiple info_player_deathmatch entities (to allow spawning near that particular dom point).
-------- NOTES --------
Do not assign a 'gametype' key to this item. It is used in all four team gametypes. The game will call for it as needed.
-------- MODEL FOR RADIANT ONLY - DO NOT SET THIS AS A KEY --------
model="models/powerups/domination/dompoint.md3"
*/
spawnfunc(team_dom_point)
{
	spawnfunc_dom_controlpoint(this);
}

/*QUAKED spawnfunc_dom_team (0 .5 .8) (-32 -32 -24) (32 32 32)
Team declaration for Domination gameplay, this allows you to decide what team
names and control point models are used in your map.

Note: If you use spawnfunc_dom_team entities you must define at least 3 and only two
can have netname set!  The nameless team owns all control points at start.

Keys:
"netname"
 Name of the team (for example Red Team, Blue Team, Green Team, Yellow Team, Life, Death, etc)
"cnt"
 Scoreboard color of the team (for example 4 is red and 13 is blue)
"model"
 Model to use for control points owned by this team (for example
 "progs/b_g_key.mdl" is a gold keycard, and "progs/b_s_key.mdl" is a silver
 keycard)
"skin"
 Skin of the model to use (for team skins on a single model)
"noise"
 Sound to play when this team captures a point.
 (this is a localized sound, like a small alarm or other effect)
"noise1"
 Narrator speech to play when this team captures a point.
 (this is a global sound, like "Red team has captured a control point")
*/

spawnfunc(dom_team)
{
	if(!g_domination || autocvar_g_domination_teams_override >= 2)
	{
		delete(this);
		return;
	}
	precache_model(this.model);
	if (this.noise != "")
		precache_sound(this.noise);
	if (this.noise1 != "")
		precache_sound(this.noise1);
	_setmodel(this, this.model); // precision not needed
	this.mdl = this.model;
	this.dmg = this.modelindex;
	this.model = "";
	this.modelindex = 0;
	// this would have to be changed if used in quakeworld
	if(this.cnt)
		this.team = this.cnt + 1; // WHY are these different anyway?
}

// scoreboard setup
void ScoreRules_dom(int teams)
{
	if(domination_roundbased)
	{
	    GameRules_scoring(teams, SFL_SORT_PRIO_PRIMARY, 0, {
            field_team(ST_DOM_CAPS, "caps", SFL_SORT_PRIO_PRIMARY);
            field(SP_DOM_TAKES, "takes", 0);
	    });
	}
	else
	{
		float sp_domticks, sp_score;
		sp_score = sp_domticks = 0;
		if(autocvar_g_domination_disable_frags)
			sp_domticks = SFL_SORT_PRIO_PRIMARY;
		else
			sp_score = SFL_SORT_PRIO_PRIMARY;
		GameRules_scoring(teams, sp_score, sp_score, {
            field_team(ST_DOM_TICKS, "ticks", sp_domticks);
            field(SP_DOM_TICKS, "ticks", sp_domticks);
            field(SP_DOM_TAKES, "takes", 0);
		});
	}
}

// code from here on is just to support maps that don't have control point and team entities
void dom_spawnteam(string teamname, float teamcolor, string pointmodel, float pointskin, Sound capsound, string capnarration, string capmessage)
{
	TC(Sound, capsound);
	entity e = new_pure(dom_team);
	e.netname = strzone(teamname);
	e.cnt = teamcolor;
	e.model = pointmodel;
	e.skin = pointskin;
	e.noise = strzone(Sound_fixpath(capsound));
	e.noise1 = strzone(capnarration);
	e.message = strzone(capmessage);

	// this code is identical to spawnfunc_dom_team
	_setmodel(e, e.model); // precision not needed
	e.mdl = e.model;
	e.dmg = e.modelindex;
	e.model = "";
	e.modelindex = 0;
	// this would have to be changed if used in quakeworld
	e.team = e.cnt + 1;

	//eprint(e);
}

void dom_spawnpoint(vector org)
{
	entity e = spawn();
	setthink(e, spawnfunc_dom_controlpoint);
	e.nextthink = time;
	setorigin(e, org);
	spawnfunc_dom_controlpoint(e);
}

// spawn some default teams if the map is not set up for domination
void dom_spawnteams(int teams)
{
	TC(int, teams);
	dom_spawnteam(Team_ColoredFullName(NUM_TEAM_1), NUM_TEAM_1-1, "models/domination/dom_red.md3", 0, SND_DOM_CLAIM, "", "Red team has captured a control point");
	dom_spawnteam(Team_ColoredFullName(NUM_TEAM_2), NUM_TEAM_2-1, "models/domination/dom_blue.md3", 0, SND_DOM_CLAIM, "", "Blue team has captured a control point");
	if(teams & BIT(2))
		dom_spawnteam(Team_ColoredFullName(NUM_TEAM_3), NUM_TEAM_3-1, "models/domination/dom_yellow.md3", 0, SND_DOM_CLAIM, "", "Yellow team has captured a control point");
	if(teams & BIT(3))
		dom_spawnteam(Team_ColoredFullName(NUM_TEAM_4), NUM_TEAM_4-1, "models/domination/dom_pink.md3", 0, SND_DOM_CLAIM, "", "Pink team has captured a control point");
	dom_spawnteam("", 0, "models/domination/dom_unclaimed.md3", 0, SND_Null, "", "");
}

void dom_DelayedInit(entity this) // Do this check with a delay so we can wait for teams to be set up.
{
	// if no teams are found, spawn defaults
	if(find(NULL, classname, "dom_team") == NULL || autocvar_g_domination_teams_override >= 2)
	{
		LOG_TRACE("No \"dom_team\" entities found on this map, creating them anyway.");
		domination_teams = autocvar_g_domination_teams_override;
		if (domination_teams < 2)
			domination_teams = autocvar_g_domination_default_teams;
		domination_teams = BITS(bound(2, domination_teams, 4));
		dom_spawnteams(domination_teams);
	}
	else
	{
		entity balance = TeamBalance_CheckAllowedTeams(NULL);
		domination_teams = TeamBalance_GetAllowedTeams(balance);
		TeamBalance_Destroy(balance);
	}

	domination_roundbased = autocvar_g_domination_roundbased;

	ScoreRules_dom(domination_teams);

	if(domination_roundbased)
	{
		round_handler_Spawn(Domination_CheckPlayers, Domination_CheckWinner, Domination_RoundStart);
		round_handler_Init(5, autocvar_g_domination_warmup, autocvar_g_domination_round_timelimit);
	}
}

void dom_Initialize()
{
	g_domination = true;
	g_dompoints = IL_NEW();

	InitializeEntity(NULL, dom_DelayedInit, INITPRIO_GAMETYPE);
}
