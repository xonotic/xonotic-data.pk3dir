#include "sv_tka.qh"

#include <common/gametypes/gametype/keepaway/sv_ball.qh>
#include <common/gametypes/gametype/keepaway/sv_util.qh>

#include <common/checkextension.qh>
#include <common/effects/all.qh>

int autocvar_g_tka_ballcarrier_maxballs;
float autocvar_g_tka_ballcarrier_highspeed;
vector autocvar_g_tka_ballcarrier_damage;
vector autocvar_g_tka_ballcarrier_force;
vector autocvar_g_tka_noncarrier_damage;
vector autocvar_g_tka_noncarrier_force;
bool autocvar_g_tka_noncarrier_warn;

int autocvar_g_tka_score_bckill;
int autocvar_g_tka_score_killac;
bool autocvar_g_tka_score_team;
int autocvar_g_tka_score_timepoints;
int autocvar_g_tkaball_count;
float autocvar_g_tkaball_damageforcescale;
int autocvar_g_tkaball_effects;
float autocvar_g_tkaball_respawntime;
int autocvar_g_tkaball_trail_color;
int autocvar_g_tkaball_tracking;


bool tka_BallStatuses_SendEntity(entity this, entity to, int sf)
{
	WriteHeader(MSG_ENTITY, ENT_CLIENT_TKA_BALLSTATUSES);
	WriteByte(MSG_ENTITY, sf);
	if (sf & SF_TKA_BALLS)
		kaball_BallStatuses_SendBalls(g_tkaballs, autocvar_g_tkaball_count);
	return true;
}

entity tkaballStatuses;
void tka_BallStatuses_Init()
{
	if (tkaballStatuses)
	{
		backtrace("Can't spawn tkaballStatuses again!");
		return;
	}
	Net_LinkEntity(tkaballStatuses = new_pure(tkaballStatuses), false, 0, tka_BallStatuses_SendEntity);
}

void tka_BallStatuses_SendBalls()
{
	tkaballStatuses.SendFlags |= SF_TKA_BALLS;
}

/// Runs on waypoints which are attached to ballcarriers, updates once per frame
bool tka_ballcarrier_waypointsprite_visible_for_player(entity this, entity player, entity view)
{
	if (view.ballcarried && IS_SPEC(player))
		return false; // we don't want spectators of the ballcarrier to see the attached waypoint on the top of their screen
	if (IS_SPEC(player) || warmup_stage || SAME_TEAM(player, this.owner))
		return true;
	if (IS_INVISIBLE(this.owner))
		return false; // hide the waypointsprite if the owner is invisible

	return autocvar_g_tkaball_tracking == 1;
}

void tka_EventLog(string mode, entity actor) // use an alias for easy changing and quick editing later
{
	if (autocvar_sv_eventlog)
		GameLogEcho(strcat(":tka:", mode, (actor != NULL ? strcat(":", itos(actor.team), ":", itos(actor.playerid)) : "")));
}

/// Runs whenever the ball needs to be relocated
void tka_RespawnBall(entity this)
{
	kaball_RespawnBall(this, tka_RespawnBall,
		autocvar_g_tkaball_effects,
		autocvar_g_tkaball_respawntime,
		autocvar_g_tkaball_tracking);
}

/// Runs (only) while a player is carrying the ball
void tka_BallThink_Carried(entity this)
{
	// Handle scoring
	if (autocvar_g_tka_score_timepoints)
		GameRules_scoring_add_team_float2int(this.owner, SCORE, autocvar_g_tka_score_timepoints * frametime, float2int_decimal_fld, 1);
	GameRules_scoring_add(this.owner, TKA_BCTIME, frametime);

	kaball_BallThink_Carried(this);
}

/// Runs any time that the ball comes in contact with something
void tka_TouchEvent(entity this, entity toucher)
{
	kaball_TouchEvent(this, toucher,
		func_null,
		tka_RespawnBall,
		tka_BallThink_Carried,
		tka_EventLog,
		tka_BallStatuses_SendBalls,
		autocvar_g_tka_ballcarrier_maxballs);

	GameRules_scoring_add(toucher, TKA_PICKUPS, 1);

	// waypoints
	WaypointSprite_AttachCarrier(WP_Null, toucher, RADARICON_FLAGCARRIER);
	toucher.waypointsprite_attachedforcarrier.colormod = colormapPaletteColor(toucher.team - 1, 0);
	toucher.waypointsprite_attachedforcarrier.waypointsprite_visible_for_player = tka_ballcarrier_waypointsprite_visible_for_player;
	WaypointSprite_UpdateRule(toucher.waypointsprite_attachedforcarrier, toucher.team, SPRITERULE_TEAMPLAY);
	if (toucher.team == NUM_TEAM_1)
		WaypointSprite_UpdateSprites(toucher.waypointsprite_attachedforcarrier, WP_TkaBallCarrierRed, WP_KaBallCarrier, WP_TkaBallCarrierRed);
	else if (toucher.team == NUM_TEAM_2)
		WaypointSprite_UpdateSprites(toucher.waypointsprite_attachedforcarrier, WP_TkaBallCarrierBlue, WP_KaBallCarrier, WP_TkaBallCarrierBlue);
	else if (toucher.team == NUM_TEAM_3)
		WaypointSprite_UpdateSprites(toucher.waypointsprite_attachedforcarrier, WP_TkaBallCarrierYellow, WP_KaBallCarrier, WP_TkaBallCarrierYellow);
	else if (toucher.team == NUM_TEAM_4)
		WaypointSprite_UpdateSprites(toucher.waypointsprite_attachedforcarrier, WP_TkaBallCarrierPink, WP_KaBallCarrier, WP_TkaBallCarrierPink);
	WaypointSprite_Ping(toucher.waypointsprite_attachedforcarrier);
	WaypointSprite_Kill(this.waypointsprite_attachedforcarrier);
}

/// Runs any time that a player is supposed to lose the ball
void tka_DropEvent(entity player)
{
	kaball_DropEvent(player,
		func_null,
		tka_RespawnBall,
		tka_EventLog,
		autocvar_g_tkaball_respawntime,
		autocvar_g_tkaball_tracking);
}

void tka_DropPlayersBalls(entity player)
{
	kaball_DropPlayersBalls(player, tka_DropEvent, tka_BallStatuses_SendBalls);
}

MODEL(TKA_BALL, "models/orbs/orbblue.md3");

void tka_RemoveBalls()
{
	kaball_RemoveBalls(g_tkaballs);
	tkaballStatuses.SendFlags = SF_TKA_RESET;
}

void tka_SpawnBalls()
{
	kaball_SpawnBalls(MDL_TKA_BALL, false,
		autocvar_g_tkaball_damageforcescale,
		autocvar_g_tkaball_trail_color,
		autocvar_g_tkaball_count,
		func_null,
		tka_TouchEvent,
		tka_RespawnBall,
		tka_BallStatuses_SendBalls);
}

void tka_Handler_CheckBall(entity this)
{
	kaball_Handler_CheckBall(this, g_tkaballs,
		tka_RemoveBalls,
		tka_SpawnBalls);
}


// ================
// Bot player logic
// ================

void _havocbot_goalrating_tkaball(entity this, entity ball, entity ball_carried, float ratingscale, float ratingscale_sameteam)
{
	if (ball)
		navigation_routerating(this, ball, ratingscale, 2000);
	else if (ball_carried)
	{
		if (DIFF_TEAM(ball_carried, this))
			navigation_routerating(this, ball_carried, ratingscale, 2000);
		else
			navigation_routerating(this, ball_carried, ratingscale_sameteam, 2000);
	}
}

void havocbot_goalrating_tkaball(entity this, float ratingscale, float ratingscale_sameteam, vector org)
{
	ka_util_havocbot_goalrating_ball(this, _havocbot_goalrating_tkaball, g_tkaballs,
		ratingscale, ratingscale_sameteam, org);
}

void havocbot_role_tka_carrier(entity this)
{
	ka_util_havocbot_role_carrier(this, havocbot_role_tka_collector);
}

void havocbot_role_tka_collector(entity this)
{
	ka_util_havocbot_role_collector(this,
		havocbot_goalrating_tkaball,
		havocbot_role_tka_carrier);
}


// ==============
// Hook Functions
// ==============

MUTATOR_HOOKFUNCTION(tka, reset_map_global)
{
	return ka_util_reset_map_global();
}

MUTATOR_HOOKFUNCTION(tka, PlayerDies)
{
	entity frag_attacker = M_ARGV(1, entity);
	entity frag_target = M_ARGV(2, entity);

	if (frag_attacker != frag_target && IS_PLAYER(frag_attacker) && DIFF_TEAM(frag_attacker, frag_target))
	{
		bool team_has_ball = false;
		IL_EACH(g_tkaballs, it.owner != frag_attacker && SAME_TEAM(it.owner, frag_attacker),
		{
			team_has_ball = true;
			break;
		});
		if (frag_target.ballcarried) // add to amount of times killing carrier
		{
			GameRules_scoring_add(frag_attacker, TKA_CARRIERKILLS, 1);
			if (autocvar_g_tka_score_bckill) // add bckills to the score
				GameRules_scoring_add_team(frag_attacker, SCORE, autocvar_g_tka_score_bckill);
		}
		else if (!frag_attacker.ballcarried && !(autocvar_g_tka_score_team && team_has_ball))
		{
			if (autocvar_g_tka_noncarrier_warn)
				Send_Notification(NOTIF_ONE_ONLY, frag_attacker, MSG_CENTER, CENTER_KEEPAWAY_WARN);
		}

		if (frag_attacker.ballcarried || (autocvar_g_tka_score_team && team_has_ball)) // add to amount of kills while ballcarrier (or if team scoring is enabled)
			GameRules_scoring_add_team(frag_attacker, SCORE, autocvar_g_tka_score_killac);
	}

	if (frag_target.ballcarried)
		tka_DropPlayersBalls(frag_target); // a player with ball(s) has died, drop them
}

MUTATOR_HOOKFUNCTION(tka, GiveFragsForKill)
{
	return ka_util_GiveFragsForKill();
}

MUTATOR_HOOKFUNCTION(tka, Scores_CountFragsRemaining)
{
	// announce remaining frags, but only when timed scoring is off
	return !autocvar_g_tka_score_timepoints;
}

MUTATOR_HOOKFUNCTION(tka, PlayerUseKey)
{
	if (ka_util_PlayerUseKey(tka_DropEvent, tka_BallStatuses_SendBalls))
		return true;
}

MUTATOR_HOOKFUNCTION(tka, Damage_Calculate) // for changing damage and force values that are applied to players
{
	ka_util_Damage_Calculate(autocvar_g_tka_ballcarrier_damage,
		autocvar_g_tka_ballcarrier_force,
		autocvar_g_tka_noncarrier_damage,
		autocvar_g_tka_noncarrier_force);
}

MUTATOR_HOOKFUNCTION(tka, ClientDisconnect)
{
	ka_util_ClientDisconnect(tka_DropPlayersBalls);
}

MUTATOR_HOOKFUNCTION(tka, MakePlayerObserver)
{
	ka_util_MakePlayerObserver(tka_DropPlayersBalls);
}

MUTATOR_HOOKFUNCTION(tka, PlayerPowerups)
{
	//entity player = M_ARGV(0, entity);

	// In the future this hook is supposed to allow me to do some extra stuff with waypointsprites and invisibility powerup
	// So bare with me until I can fix a certain bug with tka_ballcarrier_waypointsprite_visible_for_player()
}


MUTATOR_HOOKFUNCTION(tka, PlayerPhysics_UpdateStats)
{
	ka_util_PlayerPhysics_UpdateStats(autocvar_g_tka_ballcarrier_highspeed);
}

MUTATOR_HOOKFUNCTION(tka, Bot_ForbidAttack)
{
	entity bot = M_ARGV(0, entity);
	entity targ = M_ARGV(1, entity);

	// if neither player has ball then don't attack unless the ball is on the ground
	bool have_held_ball = false, team_has_ball = false;
	IL_EACH(g_tkaballs, it.owner,
	{
		have_held_ball = true;
		if (SAME_TEAM(bot, it.owner))
		{
			team_has_ball = true;
			break;
		}
	});

	if (!targ.ballcarried && !bot.ballcarried && have_held_ball && !(autocvar_g_tka_score_team && team_has_ball))
		return true;
}

MUTATOR_HOOKFUNCTION(tka, HavocBot_ChooseRole)
{
	return ka_util_HavocBot_ChooseRole(havocbot_role_tka_carrier, havocbot_role_tka_collector);
}

MUTATOR_HOOKFUNCTION(tka, DropSpecialItems)
{
	ka_util_DropSpecialItems(tka_DropPlayersBalls);
}

MUTATOR_HOOKFUNCTION(tka, PreferPlayerScore_Clear)
{
	return ka_util_PreferPlayerScore_Clear();
}

void tka_Initialize()
{
	int tka_teams = autocvar_g_tka_teams_override;
	if (tka_teams < 2)
		tka_teams = cvar("g_tka_teams"); // read the cvar directly as it gets written earlier in the same frame
	tka_teams = BITS(bound(2, tka_teams, 4));
	GameRules_scoring(tka_teams, SFL_SORT_PRIO_PRIMARY, SFL_SORT_PRIO_PRIMARY,
	{
		field(SP_TKA_PICKUPS, "pickups", 0);
		field(SP_TKA_CARRIERKILLS, "bckills", 0);
		field(SP_TKA_BCTIME, "bctime", SFL_SORT_PRIO_SECONDARY);
	});

	g_tkaballs = IL_NEW();
	entity tka_Handler = new_pure(tka_Handler);
	setthink(tka_Handler, tka_Handler_CheckBall);
	InitializeEntity(tka_Handler, tka_Handler_CheckBall, INITPRIO_GAMETYPE);

	tka_BallStatuses_Init();
}
