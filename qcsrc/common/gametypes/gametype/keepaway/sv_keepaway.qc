#include "sv_keepaway.qh"

#include "sv_ball.qh"
#include "sv_util.qh"

#include <common/checkextension.qh>
#include <common/effects/all.qh>
#include <server/client.qh>
#include <server/gamelog.qh>
#include <server/damage.qh>
#include <server/items/items.qh>
#include <server/world.qh>

int autocvar_g_keepaway_ballcarrier_maxballs;
float autocvar_g_keepaway_ballcarrier_highspeed;
vector autocvar_g_keepaway_ballcarrier_damage;
vector autocvar_g_keepaway_ballcarrier_force;
vector autocvar_g_keepaway_noncarrier_damage;
vector autocvar_g_keepaway_noncarrier_force;
bool autocvar_g_keepaway_noncarrier_warn;

int autocvar_g_keepaway_score_bckill;
int autocvar_g_keepaway_score_killac;
int autocvar_g_keepaway_score_timepoints;
int autocvar_g_keepawayball_count;
float autocvar_g_keepawayball_damageforcescale;
int autocvar_g_keepawayball_effects;
float autocvar_g_keepawayball_respawntime;
int autocvar_g_keepawayball_trail_color;
int autocvar_g_keepawayball_tracking;


bool ka_BallStatuses_SendEntity(entity this, entity to, int sf)
{
	WriteHeader(MSG_ENTITY, ENT_CLIENT_KA_BALLSTATUSES);
	WriteByte(MSG_ENTITY, sf);
	if (sf & SF_KA_BALLS)
		kaball_BallStatuses_SendBalls(g_kaballs, autocvar_g_keepawayball_count);
	return true;
}

entity kaballStatuses;
void ka_BallStatuses_Init()
{
	if (kaballStatuses)
	{
		backtrace("Can't spawn kaballStatuses again!");
		return;
	}
	Net_LinkEntity(kaballStatuses = new_pure(kaballStatuses), false, 0, ka_BallStatuses_SendEntity);
}

void ka_BallStatuses_SendBalls()
{
	kaballStatuses.SendFlags |= SF_KA_BALLS;
}

/// Runs on waypoints which are attached to ballcarriers, updates once per frame
bool ka_ballcarrier_waypointsprite_visible_for_player(entity this, entity player, entity view)
{
	if (view.ballcarried && IS_SPEC(player))
		return false; // we don't want spectators of the ballcarrier to see the attached waypoint on the top of their screen
	if (IS_SPEC(player) || warmup_stage)
		return true;
	if (IS_INVISIBLE(this.owner))
		return false; // hide the waypointsprite if the owner is invisible

	return autocvar_g_keepawayball_tracking == 1;
}

void ka_EventLog(string mode, entity actor) // use an alias for easy changing and quick editing later
{
	if (autocvar_sv_eventlog)
		GameLogEcho(strcat(":ka:", mode, (actor != NULL ? strcat(":", itos(actor.playerid)) : "")));
}

/// Runs whenever the ball needs to be relocated
void ka_RespawnBall(entity this)
{
	kaball_RespawnBall(this, ka_RespawnBall,
		autocvar_g_keepawayball_effects,
		autocvar_g_keepawayball_respawntime,
		autocvar_g_keepawayball_tracking);
}

/// Runs (only) while a player is carrying the ball
void ka_BallThink_Carried(entity this)
{
	// Handle scoring
	if (autocvar_g_keepaway_score_timepoints)
		GameRules_scoring_add_float2int(this.owner, SCORE, autocvar_g_keepaway_score_timepoints * frametime, float2int_decimal_fld, 1);
	GameRules_scoring_add(this.owner, KEEPAWAY_BCTIME, frametime);

	kaball_BallThink_Carried(this);
}

void ka_DamageEvent(entity this, entity inflictor, entity attacker, float damage, int deathtype, .entity weaponentity, vector hitloc, vector force)
{
	if (ITEM_DAMAGE_NEEDKILL(deathtype))
		ka_RespawnBall(this);
}

void ka_AllowDamagingBall(entity ball)
{
	ball.event_damage = ka_DamageEvent;
	ball.damagedbycontents = true;
	IL_PUSH(g_damagedbycontents, ball);
}
void ka_DisallowDamagingBall(entity ball)
{
	ball.event_damage = func_null;
	ball.damagedbycontents = false;
	IL_REMOVE(g_damagedbycontents, ball);
}

/// Runs any time that the ball comes in contact with something
void ka_TouchEvent(entity this, entity toucher)
{
	kaball_TouchEvent(this, toucher,
		ka_DisallowDamagingBall,
		ka_RespawnBall,
		ka_BallThink_Carried,
		ka_EventLog,
		ka_BallStatuses_SendBalls,
		autocvar_g_keepaway_ballcarrier_maxballs);

	GameRules_scoring_add(toucher, KEEPAWAY_PICKUPS, 1);

	// waypoints
	WaypointSprite_AttachCarrier(WP_KaBallCarrier, toucher, RADARICON_FLAGCARRIER);
	toucher.waypointsprite_attachedforcarrier.waypointsprite_visible_for_player = ka_ballcarrier_waypointsprite_visible_for_player;
	WaypointSprite_UpdateRule(toucher.waypointsprite_attachedforcarrier, 0, SPRITERULE_DEFAULT);
	WaypointSprite_Ping(toucher.waypointsprite_attachedforcarrier);
	WaypointSprite_Kill(this.waypointsprite_attachedforcarrier);
}

/// Runs any time that a player is supposed to lose the ball
void ka_DropEvent(entity player)
{
	kaball_DropEvent(player,
		ka_AllowDamagingBall,
		ka_RespawnBall,
		ka_EventLog,
		autocvar_g_keepawayball_respawntime,
		autocvar_g_keepawayball_tracking);
}

void ka_DropPlayersBalls(entity player)
{
	kaball_DropPlayersBalls(player, ka_DropEvent, ka_BallStatuses_SendBalls);
}

MODEL(KA_BALL, "models/orbs/orbblue.md3");

void ka_RemoveBalls()
{
	kaball_RemoveBalls(g_kaballs);
	kaballStatuses.SendFlags = SF_KA_RESET;
}

void ka_SpawnBalls()
{
	kaball_SpawnBalls(MDL_KA_BALL, false,
		autocvar_g_keepawayball_damageforcescale,
		autocvar_g_keepawayball_trail_color,
		autocvar_g_keepawayball_count,
		ka_AllowDamagingBall,
		ka_TouchEvent,
		ka_RespawnBall,
		ka_BallStatuses_SendBalls);
}

void ka_Handler_CheckBall(entity this)
{
	kaball_Handler_CheckBall(this, g_kaballs,
		ka_RemoveBalls,
		ka_SpawnBalls);
}


// ================
// Bot player logic
// ================

void _havocbot_goalrating_ball(entity this, entity ball, entity ball_carried, float ratingscale, float ratingscale_sameteam)
{
	if (ball)
		navigation_routerating(this, ball, ratingscale, 2000);
	else if (ball_carried)
		navigation_routerating(this, ball_carried, ratingscale, 2000);
}

void havocbot_goalrating_ball(entity this, float ratingscale, float ratingscale_sameteam, vector org)
{
	// ratingscale_sameteam unused above
	ka_util_havocbot_goalrating_ball(this, _havocbot_goalrating_ball, g_kaballs,
		ratingscale, ratingscale_sameteam, org);
}

void havocbot_role_ka_carrier(entity this)
{
	ka_util_havocbot_role_carrier(this, havocbot_role_ka_collector);
}

void havocbot_role_ka_collector(entity this)
{
	ka_util_havocbot_role_collector(this,
		havocbot_goalrating_ball,
		havocbot_role_ka_carrier);
}


// ==============
// Hook Functions
// ==============

MUTATOR_HOOKFUNCTION(ka, reset_map_global)
{
	return ka_util_reset_map_global();
}

MUTATOR_HOOKFUNCTION(ka, PlayerDies)
{
	entity frag_attacker = M_ARGV(1, entity);
	entity frag_target = M_ARGV(2, entity);

	if (frag_attacker != frag_target && IS_PLAYER(frag_attacker))
	{
		if (frag_target.ballcarried) // add to amount of times killing carrier
		{
			GameRules_scoring_add(frag_attacker, KEEPAWAY_CARRIERKILLS, 1);
			if (autocvar_g_keepaway_score_bckill) // add bckills to the score
				GameRules_scoring_add(frag_attacker, SCORE, autocvar_g_keepaway_score_bckill);
		}
		else if (!frag_attacker.ballcarried)
		{
			if (autocvar_g_keepaway_noncarrier_warn)
				Send_Notification(NOTIF_ONE_ONLY, frag_attacker, MSG_CENTER, CENTER_KEEPAWAY_WARN);
		}

		if (frag_attacker.ballcarried) // add to amount of kills while ballcarrier
			GameRules_scoring_add(frag_attacker, SCORE, autocvar_g_keepaway_score_killac);
	}

	if (frag_target.ballcarried)
		ka_DropPlayersBalls(frag_target); // a player with ball(s) has died, drop them
}

MUTATOR_HOOKFUNCTION(ka, GiveFragsForKill)
{
	return ka_util_GiveFragsForKill();
}

MUTATOR_HOOKFUNCTION(ka, Scores_CountFragsRemaining)
{
	// announce remaining frags, but only when timed scoring is off
	return !autocvar_g_keepaway_score_timepoints;
}

MUTATOR_HOOKFUNCTION(ka, PlayerUseKey)
{
	if (ka_util_PlayerUseKey(ka_DropEvent, ka_BallStatuses_SendBalls))
		return true;
}

MUTATOR_HOOKFUNCTION(ka, Damage_Calculate) // for changing damage and force values that are applied to players
{
	ka_util_Damage_Calculate(autocvar_g_keepaway_ballcarrier_damage,
		autocvar_g_keepaway_ballcarrier_force,
		autocvar_g_keepaway_noncarrier_damage,
		autocvar_g_keepaway_noncarrier_force);
}

MUTATOR_HOOKFUNCTION(ka, ClientDisconnect)
{
	ka_util_ClientDisconnect(ka_DropPlayersBalls);
}

MUTATOR_HOOKFUNCTION(ka, MakePlayerObserver)
{
	ka_util_MakePlayerObserver(ka_DropPlayersBalls);
}

MUTATOR_HOOKFUNCTION(ka, PlayerPowerups)
{
	//entity player = M_ARGV(0, entity);

	// In the future this hook is supposed to allow me to do some extra stuff with waypointsprites and invisibility powerup
	// So bare with me until I can fix a certain bug with ka_ballcarrier_waypointsprite_visible_for_player()
}


MUTATOR_HOOKFUNCTION(ka, PlayerPhysics_UpdateStats)
{
	ka_util_PlayerPhysics_UpdateStats(autocvar_g_keepaway_ballcarrier_highspeed);
}

MUTATOR_HOOKFUNCTION(ka, Bot_ForbidAttack)
{
	entity bot = M_ARGV(0, entity);
	entity targ = M_ARGV(1, entity);

	// if neither player has ball then don't attack unless the ball is on the ground
	bool have_held_ball = false;
	IL_EACH(g_kaballs, it.owner,
	{
		have_held_ball = true;
		break;
	});

	if (!targ.ballcarried && !bot.ballcarried && have_held_ball)
		return true;
}

MUTATOR_HOOKFUNCTION(ka, HavocBot_ChooseRole)
{
	return ka_util_HavocBot_ChooseRole(havocbot_role_ka_carrier, havocbot_role_ka_collector);
}

MUTATOR_HOOKFUNCTION(ka, DropSpecialItems)
{
	ka_util_DropSpecialItems(ka_DropPlayersBalls);
}

MUTATOR_HOOKFUNCTION(ka, PreferPlayerScore_Clear)
{
	return ka_util_PreferPlayerScore_Clear();
}
