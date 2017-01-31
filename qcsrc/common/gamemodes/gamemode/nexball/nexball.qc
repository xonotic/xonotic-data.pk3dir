#include "nexball.qh"

#ifdef CSQC
int autocvar_cl_eventchase_nexball = 1;

REGISTER_MUTATOR(cl_nb, true);

MUTATOR_HOOKFUNCTION(cl_nb, WantEventchase)
{
	if(autocvar_cl_eventchase_nexball && gametype == MAPINFO_TYPE_NEXBALL && !(WepSet_GetFromStat() & WEPSET(NEXBALL)))
		return true;
	return false;
}
#endif
#ifdef SVQC
.float metertime = _STAT(NB_METERSTART);

int autocvar_g_nexball_goalleadlimit;
#define autocvar_g_nexball_goallimit cvar("g_nexball_goallimit")

bool autocvar_g_nexball_basketball_jumppad = true;
float autocvar_g_nexball_basketball_bouncefactor;
float autocvar_g_nexball_basketball_bouncestop;
float autocvar_g_nexball_basketball_carrier_highspeed;
bool autocvar_g_nexball_basketball_meter;
float autocvar_g_nexball_basketball_meter_maxpower;
float autocvar_g_nexball_basketball_meter_minpower;
float autocvar_g_nexball_delay_collect;
float autocvar_g_nexball_delay_goal;
float autocvar_g_nexball_delay_start;
bool autocvar_g_nexball_football_jumppad = true;
float autocvar_g_nexball_football_bouncefactor;
float autocvar_g_nexball_football_bouncestop;
bool autocvar_g_nexball_radar_showallplayers;
bool autocvar_g_nexball_sound_bounce;
int autocvar_g_nexball_trail_color;
bool autocvar_g_nexball_playerclip_collisions = true;

float autocvar_g_nexball_safepass_turnrate;
float autocvar_g_nexball_safepass_maxdist;
float autocvar_g_nexball_safepass_holdtime;
float autocvar_g_nexball_viewmodel_scale;
float autocvar_g_nexball_tackling;
vector autocvar_g_nexball_viewmodel_offset;

float autocvar_g_balance_nexball_primary_animtime;
float autocvar_g_balance_nexball_primary_refire;
float autocvar_g_balance_nexball_primary_speed;
float autocvar_g_balance_nexball_secondary_animtime;
float autocvar_g_balance_nexball_secondary_force;
float autocvar_g_balance_nexball_secondary_lifetime;
float autocvar_g_balance_nexball_secondary_refire;
float autocvar_g_balance_nexball_secondary_speed;

void basketball_touch(entity this, entity toucher);
void football_touch(entity this, entity toucher);
void ResetBall(entity this);
const int NBM_NONE = 0;
const int NBM_FOOTBALL = 2;
const int NBM_BASKETBALL = 4;
float nexball_mode;

float OtherTeam(float t)  //works only if there are two teams on the map!
{
	entity e;
	e = find(NULL, classname, "nexball_team");
	if(e.team == t)
		e = find(e, classname, "nexball_team");
	return e.team;
}

const float ST_NEXBALL_GOALS = 1;
void nb_ScoreRules(int teams)
{
	ScoreRules_basics(teams, 0, 0, true);
	ScoreInfo_SetLabel_TeamScore(   ST_NEXBALL_GOALS,  "goals", SFL_SORT_PRIO_PRIMARY);
	ScoreInfo_SetLabel_PlayerScore( SP_NEXBALL_GOALS,  "goals", SFL_SORT_PRIO_PRIMARY);
	ScoreInfo_SetLabel_PlayerScore(SP_NEXBALL_FAULTS, "faults", SFL_SORT_PRIO_SECONDARY | SFL_LOWER_IS_BETTER);
	ScoreRules_basics_end();
}

void LogNB(string mode, entity actor)
{
	string s;
	if(!autocvar_sv_eventlog)
		return;
	s = strcat(":nexball:", mode);
	if(actor != NULL)
		s = strcat(s, ":", ftos(actor.playerid));
	GameLogEcho(s);
}

void ball_restart(entity this)
{
	if(this.owner)
		DropBall(this, this.owner.origin, '0 0 0');
	ResetBall(this);
}

void nexball_setstatus(entity this)
{
	this.items &= ~IT_KEY1;
	if(this.ballcarried)
	{
		if(this.ballcarried.teamtime && (this.ballcarried.teamtime < time))
		{
			Send_Notification(NOTIF_ALL, NULL, MSG_INFO, APP_TEAM_NUM(this.team, INFO_NEXBALL_RETURN_HELD));
			entity e = this.ballcarried;
			DropBall(this.ballcarried, this.ballcarried.owner.origin, '0 0 0');
			ResetBall(e);
		}
		else
			this.items |= IT_KEY1;
	}
}

void relocate_nexball(entity this)
{
	tracebox(this.origin, BALL_MINS, BALL_MAXS, this.origin, true, this);
	if(trace_startsolid)
	{
		vector o;
		o = this.origin;
		if(!move_out_of_solid(this))
			objerror(this, "could not get out of solid at all!");
		LOG_INFO("^1NOTE: this map needs FIXING. ", this.classname, " at ", vtos(o - '0 0 1'));
		LOG_INFO(" needs to be moved out of solid, e.g. by '", ftos(this.origin.x - o.x));
		LOG_INFO(" ", ftos(this.origin.y - o.y));
		LOG_INFO(" ", ftos(this.origin.z - o.z), "'\n");
		this.origin = o;
	}
}

void DropOwner(entity this)
{
	entity ownr;
	ownr = this.owner;
	DropBall(this, ownr.origin, ownr.velocity);
	makevectors(ownr.v_angle.y * '0 1 0');
	ownr.velocity += ('0 0 0.75' - v_forward) * 1000;
	UNSET_ONGROUND(ownr);
}

void GiveBall(entity plyr, entity ball)
{
	.entity weaponentity = weaponentities[0]; // TODO: find ballstealer
	entity ownr = ball.owner;
	if(ownr)
	{
		ownr.effects &= ~autocvar_g_nexball_basketball_effects_default;
		ownr.ballcarried = NULL;
		if(ownr.metertime)
		{
			ownr.metertime = 0;
			ownr.(weaponentity).state = WS_READY;
		}
		WaypointSprite_Kill(ownr.waypointsprite_attachedforcarrier);
	}
	else
	{
		WaypointSprite_Kill(ball.waypointsprite_attachedforcarrier);
	}

	//setattachment(ball, plyr, "");
	setorigin(ball, plyr.origin + plyr.view_ofs);

	if(ball.team != plyr.team)
		ball.teamtime = time + autocvar_g_nexball_basketball_delay_hold_forteam;

	ball.owner = ball.pusher = plyr; //"owner" is set to the player carrying, "pusher" to the last player who touched it
	ball.weaponentity_fld = weaponentity;
	ball.team = plyr.team;
	plyr.ballcarried = ball;
	ball.nb_dropper = plyr;

	plyr.effects |= autocvar_g_nexball_basketball_effects_default;
	ball.effects &= ~autocvar_g_nexball_basketball_effects_default;

	ball.velocity = '0 0 0';
	set_movetype(ball, MOVETYPE_NONE);
	settouch(ball, func_null);
	ball.effects |= EF_NOSHADOW;
	ball.scale = 1; // scale down.

	WaypointSprite_AttachCarrier(WP_NbBall, plyr, RADARICON_FLAGCARRIER);
	WaypointSprite_UpdateRule(plyr.waypointsprite_attachedforcarrier, 0, SPRITERULE_DEFAULT);

	if(autocvar_g_nexball_basketball_delay_hold)
	{
		setthink(ball, DropOwner);
		ball.nextthink = time + autocvar_g_nexball_basketball_delay_hold;
	}

	plyr.(weaponentity).weapons = plyr.weapons;
	plyr.m_switchweapon = plyr.(weaponentity).m_weapon;
	plyr.weapons = WEPSET(NEXBALL);
	Weapon w = WEP_NEXBALL;
	w.wr_resetplayer(w, plyr);
	plyr.(weaponentity).m_switchweapon = WEP_NEXBALL;
	W_SwitchWeapon(plyr, WEP_NEXBALL, weaponentity);
}

void DropBall(entity ball, vector org, vector vel)
{
	ball.effects |= autocvar_g_nexball_basketball_effects_default;
	ball.effects &= ~EF_NOSHADOW;
	ball.owner.effects &= ~autocvar_g_nexball_basketball_effects_default;

	setattachment(ball, NULL, "");
	setorigin(ball, org);
	set_movetype(ball, MOVETYPE_BOUNCE);
	UNSET_ONGROUND(ball);
	ball.scale = ball_scale;
	ball.velocity = vel;
	ball.nb_droptime = time;
	settouch(ball, basketball_touch);
	setthink(ball, ResetBall);
	ball.nextthink = min(time + autocvar_g_nexball_delay_idle, ball.teamtime);

	if(ball.owner.metertime)
	{
		ball.owner.metertime = 0;
		.entity weaponentity = ball.weaponentity_fld;
		ball.owner.(weaponentity).state = WS_READY;
	}

	WaypointSprite_Kill(ball.owner.waypointsprite_attachedforcarrier);
	WaypointSprite_Spawn(WP_NbBall, 0, 0, ball, '0 0 64', NULL, ball.team, ball, waypointsprite_attachedforcarrier, false, RADARICON_FLAGCARRIER); // no health bar please
	WaypointSprite_UpdateRule(ball.waypointsprite_attachedforcarrier, 0, SPRITERULE_DEFAULT);

	ball.owner.ballcarried = NULL;
	ball.owner = NULL;
}

void InitBall(entity this)
{
	if(game_stopped) return;
	UNSET_ONGROUND(this);
	set_movetype(this, MOVETYPE_BOUNCE);
	if(this.classname == "nexball_basketball")
		settouch(this, basketball_touch);
	else if(this.classname == "nexball_football")
		settouch(this, football_touch);
	this.cnt = 0;
	setthink(this, ResetBall);
	this.nextthink = time + autocvar_g_nexball_delay_idle + 3;
	this.teamtime = 0;
	this.pusher = NULL;
	this.team = false;
	_sound(this, CH_TRIGGER, this.noise1, VOL_BASE, ATTEN_NORM);
	WaypointSprite_Ping(this.waypointsprite_attachedforcarrier);
	LogNB("init", NULL);
}

void ResetBall(entity this)
{
	if(this.cnt < 2)	// step 1
	{
		if(time == this.teamtime)
			Send_Notification(NOTIF_ALL, NULL, MSG_INFO, APP_TEAM_NUM(this.team, INFO_NEXBALL_RETURN_HELD));

		settouch(this, func_null);
		set_movetype(this, MOVETYPE_NOCLIP);
		this.velocity = '0 0 0'; // just in case?
		if(!this.cnt)
			LogNB("resetidle", NULL);
		this.cnt = 2;
		this.nextthink = time;
	}
	else if(this.cnt < 4)	  // step 2 and 3
	{
//		dprint("Step ", ftos(this.cnt), ": Calculated velocity: ", vtos(this.spawnorigin - this.origin), ", time: ", ftos(time), "\n");
		this.velocity = (this.spawnorigin - this.origin) * (this.cnt - 1); // 1 or 0.5 second movement
		this.nextthink = time + 0.5;
		this.cnt += 1;
	}
	else	 // step 4
	{
//		dprint("Step 4: time: ", ftos(time), "\n");
		if(vdist(this.origin - this.spawnorigin, >, 10)) // should not happen anymore
			LOG_TRACE("The ball moved too far away from its spawn origin.\nOffset: ",
				   vtos(this.origin - this.spawnorigin), " Velocity: ", vtos(this.velocity), "\n");
		this.velocity = '0 0 0';
		setorigin(this, this.spawnorigin); // make sure it's positioned correctly anyway
		set_movetype(this, MOVETYPE_NONE);
		setthink(this, InitBall);
		this.nextthink = max(time, game_starttime) + autocvar_g_nexball_delay_start;
	}
}

void football_touch(entity this, entity toucher)
{
	if(toucher.solid == SOLID_BSP)
	{
		if(time > this.lastground + 0.1)
		{
			_sound(this, CH_TRIGGER, this.noise, VOL_BASE, ATTEN_NORM);
			this.lastground = time;
		}
		if(this.velocity && !this.cnt)
			this.nextthink = time + autocvar_g_nexball_delay_idle;
		return;
	}
	if (!IS_PLAYER(toucher))
		return;
	if(toucher.health < 1)
		return;
	if(!this.cnt)
		this.nextthink = time + autocvar_g_nexball_delay_idle;

	this.pusher = toucher;
	this.team = toucher.team;

	if(autocvar_g_nexball_football_physics == -1)	// MrBougo try 1, before decompiling Rev's original
	{
		if(toucher.velocity)
			this.velocity = toucher.velocity * 1.5 + '0 0 1' * autocvar_g_nexball_football_boost_up;
	}
	else if(autocvar_g_nexball_football_physics == 1)	  // MrBougo's modded Rev style: partially independant of the height of the aiming point
	{
		makevectors(toucher.v_angle);
		this.velocity = toucher.velocity + v_forward * autocvar_g_nexball_football_boost_forward + '0 0 1' * autocvar_g_nexball_football_boost_up;
	}
	else if(autocvar_g_nexball_football_physics == 2)	  // 2nd mod try: totally independant. Really playable!
	{
		makevectors(toucher.v_angle.y * '0 1 0');
		this.velocity = toucher.velocity + v_forward * autocvar_g_nexball_football_boost_forward + v_up * autocvar_g_nexball_football_boost_up;
	}
	else	 // Revenant's original style (from the original mod's disassembly, acknowledged by Revenant)
	{
		makevectors(toucher.v_angle);
		this.velocity = toucher.velocity + v_forward * autocvar_g_nexball_football_boost_forward + v_up * autocvar_g_nexball_football_boost_up;
	}
	this.avelocity = -250 * v_forward;  // maybe there is a way to make it look better?
}

void basketball_touch(entity this, entity toucher)
{
	if(toucher.ballcarried)
	{
		football_touch(this, toucher);
		return;
	}
	if(!this.cnt && IS_PLAYER(toucher) && !STAT(FROZEN, toucher) && !IS_DEAD(toucher) && (toucher != this.nb_dropper || time > this.nb_droptime + autocvar_g_nexball_delay_collect))
	{
		if(toucher.health <= 0)
			return;
		LogNB("caught", toucher);
		GiveBall(toucher, this);
	}
	else if(toucher.solid == SOLID_BSP)
	{
		_sound(this, CH_TRIGGER, this.noise, VOL_BASE, ATTEN_NORM);
		if(this.velocity && !this.cnt)
			this.nextthink = min(time + autocvar_g_nexball_delay_idle, this.teamtime);
	}
}

void GoalTouch(entity this, entity toucher)
{
	entity ball;
	float isclient, pscore, otherteam;
	string pname;

	if(game_stopped) return;
	if((this.spawnflags & GOAL_TOUCHPLAYER) && toucher.ballcarried)
		ball = toucher.ballcarried;
	else
		ball = toucher;
	if(ball.classname != "nexball_basketball")
		if(ball.classname != "nexball_football")
			return;
	if((!ball.pusher && this.team != GOAL_OUT) || ball.cnt)
		return;
	EXACTTRIGGER_TOUCH(this, toucher);


	if(NumTeams(nb_teams) == 2)
		otherteam = OtherTeam(ball.team);
	else
		otherteam = 0;

	if((isclient = IS_CLIENT(ball.pusher)))
		pname = ball.pusher.netname;
	else
		pname = "Someone (?)";

	if(ball.team == this.team)		 //owngoal (regular goals)
	{
		LogNB("owngoal", ball.pusher);
		bprint("Boo! ", pname, "^7 scored a goal against their own team!\n");
		pscore = -1;
	}
	else if(this.team == GOAL_FAULT)
	{
		LogNB("fault", ball.pusher);
		if(NumTeams(nb_teams) == 2)
			bprint(Team_ColoredFullName(otherteam), " gets a point due to ", pname, "^7's silliness.\n");
		else
			bprint(Team_ColoredFullName(ball.team), " loses a point due to ", pname, "^7's silliness.\n");
		pscore = -1;
	}
	else if(this.team == GOAL_OUT)
	{
		LogNB("out", ball.pusher);
		if((this.spawnflags & GOAL_TOUCHPLAYER) && ball.owner)
			bprint(pname, "^7 went out of bounds.\n");
		else
			bprint("The ball was returned.\n");
		pscore = 0;
	}
	else							   //score
	{
		LogNB(strcat("goal:", ftos(this.team)), ball.pusher);
		bprint("Goaaaaal! ", pname, "^7 scored a point for the ", Team_ColoredFullName(ball.team), ".\n");
		pscore = 1;
	}

	_sound(ball, CH_TRIGGER, this.noise, VOL_BASE, ATTEN_NONE);

	if(ball.team && pscore)
	{
		if(NumTeams(nb_teams) == 2 && pscore < 0)
			TeamScore_AddToTeam(otherteam, ST_NEXBALL_GOALS, -pscore);
		else
			TeamScore_AddToTeam(ball.team, ST_NEXBALL_GOALS, pscore);
	}
	if(isclient)
	{
		if(pscore > 0)
			PlayerScore_Add(ball.pusher, SP_NEXBALL_GOALS, pscore);
		else if(pscore < 0)
			PlayerScore_Add(ball.pusher, SP_NEXBALL_FAULTS, -pscore);
	}

	if(ball.owner)  // Happens on spawnflag GOAL_TOUCHPLAYER
		DropBall(ball, ball.owner.origin, ball.owner.velocity);

	WaypointSprite_Ping(ball.waypointsprite_attachedforcarrier);

	ball.cnt = 1;
	setthink(ball, ResetBall);
	if(ball.classname == "nexball_basketball")
		settouch(ball, football_touch); // better than func_null: football control until the ball gets reset
	ball.nextthink = time + autocvar_g_nexball_delay_goal * (this.team != GOAL_OUT);
}

//=======================//
//	   team ents	   //
//=======================//
spawnfunc(nexball_team)
{
	if(!g_nexball)
	{
		delete(this);
		return;
	}
	this.team = this.cnt + 1;
}

void nb_spawnteam(string teamname, float teamcolor)
{
	LOG_TRACE("^2spawned team ", teamname);
	entity e = new(nexball_team);
	e.netname = teamname;
	e.cnt = teamcolor;
	e.team = e.cnt + 1;
	//nb_teams += 1;
}

void nb_spawnteams()
{
	bool t_red = false, t_blue = false, t_yellow = false, t_pink = false;
	entity e;
	for(e = NULL; (e = find(e, classname, "nexball_goal"));)
	{
		switch(e.team)
		{
		case NUM_TEAM_1:
			if(!t_red)
			{
				nb_spawnteam("Red", e.team-1)   ;
				nb_teams |= BIT(0);
				t_red = true;
			}
			break;
		case NUM_TEAM_2:
			if(!t_blue)
			{
				nb_spawnteam("Blue", e.team-1)  ;
				t_blue = true;
				nb_teams |= BIT(1);
			}
			break;
		case NUM_TEAM_3:
			if(!t_yellow)
			{
				nb_spawnteam("Yellow", e.team-1);
				t_yellow = true;
				nb_teams |= BIT(2);
			}
			break;
		case NUM_TEAM_4:
			if(!t_pink)
			{
				nb_spawnteam("Pink", e.team-1)  ;
				t_pink = true;
				nb_teams |= BIT(3);
			}
			break;
		}
	}
}

void nb_delayedinit(entity this)
{
	if(find(NULL, classname, "nexball_team") == NULL)
		nb_spawnteams();
	nb_ScoreRules(nb_teams);
}


//=======================//
//	  spawnfuncs	   //
//=======================//

void SpawnBall(entity this)
{
	if(!g_nexball) { delete(this); return; }

//	balls += 4; // using the remaining bits to count balls will leave more than the max edict count, so it's fine

	if(this.model == "")
	{
		this.model = "models/nexball/ball.md3";
		this.scale = 1.3;
	}

	precache_model(this.model);
	_setmodel(this, this.model);
	setsize(this, BALL_MINS, BALL_MAXS);
	ball_scale = this.scale;

	relocate_nexball(this);
	this.spawnorigin = this.origin;

	this.effects = this.effects | EF_LOWPRECISION;

	if(cvar(strcat("g_", this.classname, "_trail")))  //nexball_basketball :p
	{
		this.glow_color = autocvar_g_nexball_trail_color;
		this.glow_trail = true;
	}

	set_movetype(this, MOVETYPE_FLY);

	if(autocvar_g_nexball_playerclip_collisions)
		this.dphitcontentsmask = DPCONTENTS_BODY | DPCONTENTS_SOLID | DPCONTENTS_PLAYERCLIP;

	if(!autocvar_g_nexball_sound_bounce)
		this.noise = "";
	else if(this.noise == "")
		this.noise = strzone(SND(NB_BOUNCE));
	//bounce sound placeholder (FIXME)
	if(this.noise1 == "")
		this.noise1 = strzone(SND(NB_DROP));
	//ball drop sound placeholder (FIXME)
	if(this.noise2 == "")
		this.noise2 = strzone(SND(NB_STEAL));
	//stealing sound placeholder (FIXME)
	if(this.noise) precache_sound(this.noise);
	precache_sound(this.noise1);
	precache_sound(this.noise2);

	WaypointSprite_AttachCarrier(WP_NbBall, this, RADARICON_FLAGCARRIER); // the ball's team is not set yet, no rule update needed

	this.reset = ball_restart;
	setthink(this, InitBall);
	this.nextthink = game_starttime + autocvar_g_nexball_delay_start;
}

spawnfunc(nexball_basketball)
{
	nexball_mode |= NBM_BASKETBALL;
	this.classname = "nexball_basketball";
	if (!(balls & BALL_BASKET))
	{
		/*
		CVTOV(g_nexball_basketball_effects_default);
		CVTOV(g_nexball_basketball_delay_hold);
		CVTOV(g_nexball_basketball_delay_hold_forteam);
		CVTOV(g_nexball_basketball_teamsteal);
		*/
		autocvar_g_nexball_basketball_effects_default = autocvar_g_nexball_basketball_effects_default & BALL_EFFECTMASK;
	}
	if(!this.effects)
		this.effects = autocvar_g_nexball_basketball_effects_default;
	this.solid = SOLID_TRIGGER;
	this.pushable = autocvar_g_nexball_basketball_jumppad;
	balls |= BALL_BASKET;
	this.bouncefactor = autocvar_g_nexball_basketball_bouncefactor;
	this.bouncestop = autocvar_g_nexball_basketball_bouncestop;
	SpawnBall(this);
}

spawnfunc(nexball_football)
{
	nexball_mode |= NBM_FOOTBALL;
	this.classname = "nexball_football";
	this.solid = SOLID_TRIGGER;
	balls |= BALL_FOOT;
	this.pushable = autocvar_g_nexball_football_jumppad;
	this.bouncefactor = autocvar_g_nexball_football_bouncefactor;
	this.bouncestop = autocvar_g_nexball_football_bouncestop;
	SpawnBall(this);
}

bool nb_Goal_Customize(entity this, entity client)
{
	entity e = WaypointSprite_getviewentity(client);
	entity wp_owner = this.owner;
	if(SAME_TEAM(e, wp_owner)) { return false; }

	return true;
}

void SpawnGoal(entity this)
{
	if(!g_nexball) { delete(this); return; }

	EXACTTRIGGER_INIT;

	if(this.team != GOAL_OUT && Team_TeamToNumber(this.team) != -1)
	{
		entity wp = WaypointSprite_SpawnFixed(WP_NbGoal, (this.absmin + this.absmax) * 0.5, this, sprite, RADARICON_NONE);
		wp.colormod = ((this.team) ? Team_ColorRGB(this.team) : '1 0.5 0');
		setcefc(this.sprite, nb_Goal_Customize);
	}

	this.classname = "nexball_goal";
	if(this.noise == "")
		this.noise = "ctf/respawn.wav";
	precache_sound(this.noise);
	settouch(this, GoalTouch);
}

spawnfunc(nexball_redgoal)
{
	this.team = NUM_TEAM_1;
	SpawnGoal(this);
}
spawnfunc(nexball_bluegoal)
{
	this.team = NUM_TEAM_2;
	SpawnGoal(this);
}
spawnfunc(nexball_yellowgoal)
{
	this.team = NUM_TEAM_3;
	SpawnGoal(this);
}
spawnfunc(nexball_pinkgoal)
{
	this.team = NUM_TEAM_4;
	SpawnGoal(this);
}

spawnfunc(nexball_fault)
{
	this.team = GOAL_FAULT;
	if(this.noise == "")
		this.noise = strzone(SND(TYPEHIT));
	SpawnGoal(this);
}

spawnfunc(nexball_out)
{
	this.team = GOAL_OUT;
	if(this.noise == "")
		this.noise = strzone(SND(TYPEHIT));
	SpawnGoal(this);
}

//
//Spawnfuncs preserved for compatibility
//

spawnfunc(ball)
{
	spawnfunc_nexball_football(this);
}
spawnfunc(ball_football)
{
	spawnfunc_nexball_football(this);
}
spawnfunc(ball_basketball)
{
	spawnfunc_nexball_basketball(this);
}
// The "red goal" is defended by blue team. A ball in there counts as a point for red.
spawnfunc(ball_redgoal)
{
	spawnfunc_nexball_bluegoal(this);	// I blame Revenant
}
spawnfunc(ball_bluegoal)
{
	spawnfunc_nexball_redgoal(this);	// but he didn't mean to cause trouble :p
}
spawnfunc(ball_fault)
{
	spawnfunc_nexball_fault(this);
}
spawnfunc(ball_bound)
{
	spawnfunc_nexball_out(this);
}

//=======================//
//	  Weapon code	  //
//=======================//


void W_Nexball_Think(entity this)
{
	//dprint("W_Nexball_Think\n");
	//vector new_dir = steerlib_arrive(this.enemy.origin, 2500);
	vector new_dir = normalize(this.enemy.origin + '0 0 50' - this.origin);
	vector old_dir = normalize(this.velocity);
	float _speed = vlen(this.velocity);
	vector new_vel = normalize(old_dir + (new_dir * autocvar_g_nexball_safepass_turnrate)) * _speed;
	//vector new_vel = (new_dir * autocvar_g_nexball_safepass_turnrate

	this.velocity = new_vel;

	this.nextthink = time;
}

void W_Nexball_Touch(entity this, entity toucher)
{
	entity ball, attacker;
	attacker = this.owner;
	//this.think = func_null;
	//this.enemy = NULL;

	PROJECTILE_TOUCH(this, toucher);
	if(attacker.team != toucher.team || autocvar_g_nexball_basketball_teamsteal)
		if((ball = toucher.ballcarried) && !STAT(FROZEN, toucher) && !IS_DEAD(toucher) && (IS_PLAYER(attacker)))
		{
			toucher.velocity = toucher.velocity + normalize(this.velocity) * toucher.damageforcescale * autocvar_g_balance_nexball_secondary_force;
			UNSET_ONGROUND(toucher);
			if(!attacker.ballcarried)
			{
				LogNB("stole", attacker);
				_sound(toucher, CH_TRIGGER, ball.noise2, VOL_BASE, ATTEN_NORM);

				if(SAME_TEAM(attacker, toucher) && time > attacker.teamkill_complain)
				{
					attacker.teamkill_complain = time + 5;
					attacker.teamkill_soundtime = time + 0.4;
					attacker.teamkill_soundsource = toucher;
				}

				GiveBall(attacker, toucher.ballcarried);
			}
		}
	delete(this);
}

void W_Nexball_Attack(entity actor, .entity weaponentity, float t)
{
	entity ball;
	float mul, mi, ma;
	if(!(ball = actor.ballcarried))
		return;

	W_SetupShot(actor, weaponentity, false, 4, SND_NB_SHOOT1, CH_WEAPON_A, 0);
	tracebox(w_shotorg, BALL_MINS, BALL_MAXS, w_shotorg, MOVE_WORLDONLY, NULL);
	if(trace_startsolid)
	{
		if(actor.metertime)
			actor.metertime = 0; // Shot failed, hide the power meter
		return;
	}

	//Calculate multiplier
	if(t < 0)
		mul = 1;
	else
	{
		mi = autocvar_g_nexball_basketball_meter_minpower;
		ma = max(mi, autocvar_g_nexball_basketball_meter_maxpower); // avoid confusion
		//One triangle wave period with 1 as max
		mul = 2 * (t % g_nexball_meter_period) / g_nexball_meter_period;
		if(mul > 1)
			mul = 2 - mul;
		mul = mi + (ma - mi) * mul; // range from the minimal power to the maximal power
	}

	DropBall(ball, w_shotorg, W_CalculateProjectileVelocity(actor, actor.velocity, w_shotdir * autocvar_g_balance_nexball_primary_speed * mul, false));


	//TODO: use the speed_up cvar too ??
}

vector trigger_push_calculatevelocity(vector org, entity tgt, float ht);

void W_Nexball_Attack2(entity actor, .entity weaponentity)
{
	if(actor.ballcarried.enemy)
	{
		entity _ball = actor.ballcarried;
		W_SetupShot(actor, weaponentity, false, 4, SND_NB_SHOOT1, CH_WEAPON_A, 0);
		DropBall(_ball, w_shotorg, trigger_push_calculatevelocity(_ball.origin, _ball.enemy, 32));
		setthink(_ball, W_Nexball_Think);
		_ball.nextthink = time;
		return;
	}

	if(!autocvar_g_nexball_tackling)
		return;

	W_SetupShot(actor, weaponentity, false, 2, SND_NB_SHOOT2, CH_WEAPON_A, 0);
	entity missile = new(ballstealer);

	missile.owner = actor;

	set_movetype(missile, MOVETYPE_FLY);
	PROJECTILE_MAKETRIGGER(missile);

	//setmodel(missile, "models/elaser.mdl");  // precision set below
	setsize(missile, '0 0 0', '0 0 0');
	setorigin(missile, w_shotorg);

	W_SetupProjVelocity_Basic(missile, autocvar_g_balance_nexball_secondary_speed, 0);
	missile.angles = vectoangles(missile.velocity);
	settouch(missile, W_Nexball_Touch);
	setthink(missile, SUB_Remove);
	missile.nextthink = time + autocvar_g_balance_nexball_secondary_lifetime; //FIXME: use a distance instead?

	missile.effects = EF_BRIGHTFIELD | EF_LOWPRECISION;
	missile.flags = FL_PROJECTILE;
	IL_PUSH(g_projectiles, missile);
	IL_PUSH(g_bot_dodge, missile);

	CSQCProjectile(missile, true, PROJECTILE_ELECTRO, true);
}

bool ball_customize(entity this, entity client)
{
	if(!this.owner)
	{
		this.effects &= ~EF_FLAME;
		this.scale = 1;
		setcefc(this, func_null);
		return true;
	}

	if(client == this.owner)
	{
		this.scale = autocvar_g_nexball_viewmodel_scale;
		if(this.enemy)
			this.effects |= EF_FLAME;
		else
			this.effects &= ~EF_FLAME;
	}
	else
	{
		this.effects &= ~EF_FLAME;
		this.scale = 1;
	}

	return true;
}

METHOD(BallStealer, wr_think, void(BallStealer thiswep, entity actor, .entity weaponentity, int fire))
{
    TC(BallStealer, thiswep);
    if(fire & 1)
        if(weapon_prepareattack(thiswep, actor, weaponentity, false, autocvar_g_balance_nexball_primary_refire))
            if(autocvar_g_nexball_basketball_meter)
            {
                if(actor.ballcarried && !actor.metertime)
                    actor.metertime = time;
                else
                    weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, autocvar_g_balance_nexball_primary_animtime, w_ready);
            }
            else
            {
                W_Nexball_Attack(actor, weaponentity, -1);
                weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, autocvar_g_balance_nexball_primary_animtime, w_ready);
            }
    if(fire & 2)
        if(weapon_prepareattack(thiswep, actor, weaponentity, true, autocvar_g_balance_nexball_secondary_refire))
        {
            W_Nexball_Attack2(actor, weaponentity);
            weapon_thinkf(actor, weaponentity, WFRAME_FIRE2, autocvar_g_balance_nexball_secondary_animtime, w_ready);
        }

    if(!(fire & 1) && actor.metertime && actor.ballcarried)
    {
        W_Nexball_Attack(actor, weaponentity, time - actor.metertime);
        // DropBall or stealing will set metertime back to 0
        weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, autocvar_g_balance_nexball_primary_animtime, w_ready);
    }
}

METHOD(BallStealer, wr_setup, void(BallStealer this, entity actor, .entity weaponentity))
{
    TC(BallStealer, this);
    //weapon_setup(WEP_PORTO.m_id);
}

METHOD(BallStealer, wr_reload, void(entity thiswep, entity actor, .entity weaponentity))
{
    TC(BallStealer, this);
}

METHOD(BallStealer, wr_checkammo1, bool(BallStealer this, entity actor, .entity weaponentity))
{
    TC(BallStealer, this);
    return true;
}

METHOD(BallStealer, wr_checkammo2, bool(BallStealer this, entity actor, .entity weaponentity))
{
    TC(BallStealer, this);
    return true;
}

void nb_DropBall(entity player)
{
	if(player.ballcarried && g_nexball)
		DropBall(player.ballcarried, player.origin, player.velocity);
}

MUTATOR_HOOKFUNCTION(nb, ClientDisconnect)
{
	entity player = M_ARGV(0, entity);

	nb_DropBall(player);
}

MUTATOR_HOOKFUNCTION(nb, PlayerDies)
{
	entity frag_target = M_ARGV(2, entity);

	nb_DropBall(frag_target);
}

MUTATOR_HOOKFUNCTION(nb, MakePlayerObserver)
{
	entity player = M_ARGV(0, entity);

	nb_DropBall(player);
	return false;
}

MUTATOR_HOOKFUNCTION(nb, PlayerPreThink)
{
	entity player = M_ARGV(0, entity);

	makevectors(player.v_angle);
	if(nexball_mode & NBM_BASKETBALL)
	{
		if(player.ballcarried)
		{
			// 'view ball'
			player.ballcarried.velocity = player.velocity;
			setcefc(player.ballcarried, ball_customize);

			vector org = player.origin + player.view_ofs +
					  v_forward * autocvar_g_nexball_viewmodel_offset.x +
					  v_right * autocvar_g_nexball_viewmodel_offset.y +
					  v_up * autocvar_g_nexball_viewmodel_offset.z;
			setorigin(player.ballcarried, org);

			// 'safe passing'
			if(autocvar_g_nexball_safepass_maxdist)
			{
				if(player.ballcarried.wait < time && player.ballcarried.enemy)
				{
					//centerprint(player, sprintf("Lost lock on %s", player.ballcarried.enemy.netname));
					player.ballcarried.enemy = NULL;
				}


				//tracebox(player.origin + player.view_ofs, '-2 -2 -2', '2 2 2', player.origin + player.view_ofs + v_forward * autocvar_g_nexball_safepass_maxdist);
				crosshair_trace(player);
				if( trace_ent &&
					IS_CLIENT(trace_ent) &&
					!IS_DEAD(trace_ent) &&
					trace_ent.team == player.team &&
					vdist(trace_ent.origin - player.origin, <=, autocvar_g_nexball_safepass_maxdist) )
				{

					//if(player.ballcarried.enemy != trace_ent)
					//	centerprint(player, sprintf("Locked to %s", trace_ent.netname));
					player.ballcarried.enemy = trace_ent;
					player.ballcarried.wait = time + autocvar_g_nexball_safepass_holdtime;


				}
			}
		}
		else
		{
			for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
			{
				.entity weaponentity = weaponentities[slot];

				if(player.(weaponentity).weapons)
				{
					player.weapons = player.(weaponentity).weapons;
					Weapon w = WEP_NEXBALL;
					w.wr_resetplayer(w, player);
					player.(weaponentity).m_switchweapon = player.m_switchweapon;
					W_SwitchWeapon(player, player.(weaponentity).m_switchweapon, weaponentity);

					player.(weaponentity).weapons = '0 0 0';
				}
			}
		}

	}

	nexball_setstatus(player);
}

MUTATOR_HOOKFUNCTION(nb, SpectateCopy)
{
	entity spectatee = M_ARGV(0, entity);
	entity client = M_ARGV(1, entity);

	client.metertime = spectatee.metertime;
}

MUTATOR_HOOKFUNCTION(nb, PlayerSpawn)
{
	entity player = M_ARGV(0, entity);

	player.metertime = 0;
	for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	{
		.entity weaponentity = weaponentities[slot];
		player.(weaponentity).weapons = '0 0 0';
	}

	if (nexball_mode & NBM_BASKETBALL)
		player.weapons |= WEPSET(NEXBALL);
	else
		player.weapons = '0 0 0';

	return false;
}

.float stat_sv_airspeedlimit_nonqw;
.float stat_sv_maxspeed;

MUTATOR_HOOKFUNCTION(nb, PlayerPhysics)
{
	entity player = M_ARGV(0, entity);

	if(player.ballcarried)
	{
		player.stat_sv_airspeedlimit_nonqw *= autocvar_g_nexball_basketball_carrier_highspeed;
		player.stat_sv_maxspeed *= autocvar_g_nexball_basketball_carrier_highspeed;
	}
}

MUTATOR_HOOKFUNCTION(nb, ForbidThrowCurrentWeapon)
{
	//entity player = M_ARGV(0, entity);
	entity wepent = M_ARGV(1, entity);

	return wepent.m_weapon == WEP_NEXBALL;
}

MUTATOR_HOOKFUNCTION(nb, ForbidDropCurrentWeapon)
{
	//entity player = M_ARGV(0, entity);
	int wep = M_ARGV(1, int);

	return wep == WEP_MORTAR.m_id; // TODO: what is this for?
}

MUTATOR_HOOKFUNCTION(nb, FilterItem)
{
	entity item = M_ARGV(0, entity);

	if(item.classname == "droppedweapon")
	if(item.weapon == WEP_NEXBALL.m_id)
		return true;

	return false;
}

MUTATOR_HOOKFUNCTION(nb, ItemTouch)
{
	entity item = M_ARGV(0, entity);
	entity toucher = M_ARGV(1, entity);

	if(item.weapon && toucher.ballcarried)
		return MUT_ITEMTOUCH_RETURN; // no new weapons for you, mister!

	return MUT_ITEMTOUCH_CONTINUE;
}

MUTATOR_HOOKFUNCTION(nb, CheckAllowedTeams)
{
	M_ARGV(1, string) = "nexball_team";
	return true;
}

MUTATOR_HOOKFUNCTION(nb, WantWeapon)
{
	M_ARGV(1, float) = 0; // weapon is set a few lines later, apparently
	return true;
}

MUTATOR_HOOKFUNCTION(nb, DropSpecialItems)
{
	entity frag_target = M_ARGV(0, entity);

	if(frag_target.ballcarried)
		DropBall(frag_target.ballcarried, frag_target.origin, frag_target.velocity);

	return false;
}

MUTATOR_HOOKFUNCTION(nb, SendWaypoint)
{
	M_ARGV(2, int) &= ~0x80;
}

REGISTER_MUTATOR(nb, g_nexball)
{
	MUTATOR_ONADD
	{
		g_nexball_meter_period = autocvar_g_nexball_meter_period;
		if(g_nexball_meter_period <= 0)
			g_nexball_meter_period = 2; // avoid division by zero etc. due to silly users
		g_nexball_meter_period = rint(g_nexball_meter_period * 32) / 32; //Round to 1/32ths to send as a byte multiplied by 32

		// General settings
		/*
		CVTOV(g_nexball_football_boost_forward);   //100
		CVTOV(g_nexball_football_boost_up);		//200
		CVTOV(g_nexball_delay_idle);			   //10
		CVTOV(g_nexball_football_physics);		 //0
		*/
		radar_showennemies = autocvar_g_nexball_radar_showallplayers;

		InitializeEntity(NULL, nb_delayedinit, INITPRIO_GAMETYPE);
		WEP_NEXBALL.spawnflags &= ~WEP_FLAG_MUTATORBLOCKED;

		ActivateTeamplay();
		SetLimits(autocvar_g_nexball_goallimit, autocvar_g_nexball_goalleadlimit, autocvar_timelimit_override, -1);
		have_team_spawns = -1; // request team spawns
	}

	MUTATOR_ONROLLBACK_OR_REMOVE
	{
		WEP_NEXBALL.spawnflags |= WEP_FLAG_MUTATORBLOCKED;
		// we actually cannot roll back nb_delayedinit here
		// BUT: we don't need to! If this gets called, adding always
		// succeeds.
	}

	MUTATOR_ONREMOVE
	{
		LOG_INFO("This is a game type and it cannot be removed at runtime.");
		return -1;
	}

	return 0;
}

#endif
