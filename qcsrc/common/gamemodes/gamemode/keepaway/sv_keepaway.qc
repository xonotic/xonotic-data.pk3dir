#include "sv_keepaway.qh"

#include <common/effects/all.qh>
#include <server/client.qh>
#include <server/gamelog.qh>
#include <server/damage.qh>
#include <server/items/items.qh>
#include <server/world.qh>

.entity ballcarried;

int autocvar_g_keepaway_ballcarrier_effects;
float autocvar_g_keepaway_ballcarrier_damage;
float autocvar_g_keepaway_ballcarrier_force;
float autocvar_g_keepaway_ballcarrier_highspeed;
float autocvar_g_keepaway_ballcarrier_selfdamage;
float autocvar_g_keepaway_ballcarrier_selfforce;
float autocvar_g_keepaway_noncarrier_damage;
float autocvar_g_keepaway_noncarrier_force;
float autocvar_g_keepaway_noncarrier_selfdamage;
float autocvar_g_keepaway_noncarrier_selfforce;
bool autocvar_g_keepaway_noncarrier_warn;
int autocvar_g_keepaway_score_bckill;
int autocvar_g_keepaway_score_killac;
int autocvar_g_keepaway_score_timepoints;
float autocvar_g_keepaway_score_timeinterval;
float autocvar_g_keepawayball_damageforcescale;
int autocvar_g_keepawayball_effects;
float autocvar_g_keepawayball_respawntime;
int autocvar_g_keepawayball_trail_color;

bool ka_ballcarrier_waypointsprite_visible_for_player(entity this, entity player, entity view) // runs on waypoints which are attached to ballcarriers, updates once per frame
{
	if(view.ballcarried)
		if(IS_SPEC(player))
			return false; // we don't want spectators of the ballcarrier to see the attached waypoint on the top of their screen

	// TODO: Make the ballcarrier lack a waypointsprite whenever they have the invisibility powerup

	return true;
}

void ka_EventLog(string mode, entity actor) // use an alias for easy changing and quick editing later
{
	if(autocvar_sv_eventlog)
		GameLogEcho(strcat(":ka:", mode, ((actor != NULL) ? (strcat(":", ftos(actor.playerid))) : "")));
}

void ka_RespawnBall(entity this) // runs whenever the ball needs to be relocated
{
	if(game_stopped) return;
	vector oldballorigin = this.origin;

	if(!MoveToRandomMapLocation(this, DPCONTENTS_SOLID | DPCONTENTS_CORPSE | DPCONTENTS_PLAYERCLIP, DPCONTENTS_SLIME | DPCONTENTS_LAVA | DPCONTENTS_SKY | DPCONTENTS_BODY | DPCONTENTS_DONOTENTER, Q3SURFACEFLAG_SKY, 10, 1024, 256))
	{
		entity spot = SelectSpawnPoint(this, true);
		setorigin(this, spot.origin);
		this.angles = spot.angles;
	}

	makevectors(this.angles);
	set_movetype(this, MOVETYPE_BOUNCE);
	this.velocity = '0 0 200';
	this.angles = '0 0 0';
	this.effects = autocvar_g_keepawayball_effects;
	settouch(this, ka_TouchEvent);
	setthink(this, ka_RespawnBall);
	this.nextthink = time + autocvar_g_keepawayball_respawntime;
	navigation_dynamicgoal_set(this, NULL);

	Send_Effect(EFFECT_ELECTRO_COMBO, oldballorigin, '0 0 0', 1);
	Send_Effect(EFFECT_ELECTRO_COMBO, this.origin, '0 0 0', 1);

	WaypointSprite_Spawn(WP_KaBall, 0, 0, this, '0 0 64', NULL, this.team, this, waypointsprite_attachedforcarrier, false, RADARICON_FLAGCARRIER);
	WaypointSprite_Ping(this.waypointsprite_attachedforcarrier);

	sound(this, CH_TRIGGER, SND_KA_RESPAWN, VOL_BASE, ATTEN_NONE); // ATTEN_NONE (it's a sound intended to be heard anywhere)
}

.float timepoints_counter;
MUTATOR_HOOKFUNCTION(ka, reset_map_global)
{
	FOREACH_CLIENT(true,
	{
		it.timepoints_counter = 0;
	});
	return true;
}

void ka_TimeScoring(entity this)
{
	if(this.owner.ballcarried)
	{ // add points for holding the ball after a certain amount of time
		float timescore = 0;
		if(autocvar_g_keepaway_score_timepoints)
			timescore = autocvar_g_keepaway_score_timepoints / max(0.001, autocvar_g_keepaway_score_timeinterval);

		if (timescore)
			GameRules_scoring_add_float2int(this.owner, SCORE, timescore, timepoints_counter, 1);

		GameRules_scoring_add(this.owner, KEEPAWAY_BCTIME, 1);
		this.nextthink = time + 1;
	}
}

void ka_DamageEvent(entity this, entity inflictor, entity attacker, float damage, int deathtype, .entity weaponentity, vector hitloc, vector force)
{
	if(ITEM_DAMAGE_NEEDKILL(deathtype))
		ka_RespawnBall(this);
}

void ka_TouchEvent(entity this, entity toucher) // runs any time that the ball comes in contact with something
{
	if (!this || game_stopped)
		return;

	if(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT)
	{ // The ball fell off the map, respawn it since players can't get to it
		ka_RespawnBall(this);
		return;
	}
	if(toucher.ballcarried) { return; }
	if(IS_DEAD(toucher)) { return; }
	if(STAT(FROZEN, toucher)) { return; }
	if (!IS_PLAYER(toucher))
	{  // The ball just touched an object, most likely the world
		Send_Effect(EFFECT_BALL_SPARKS, this.origin, '0 0 0', 1);
		sound(this, CH_TRIGGER, SND_KA_TOUCH, VOL_BASE, ATTEN_NORM);
		return;
	}
	else if(this.wait > time) { return; }

	// attach the ball to the player
	this.owner = toucher;
	toucher.ballcarried = this;
	GameRules_scoring_vip(toucher, true);
	setattachment(this, toucher, "");
	setorigin(this, '0 0 0');

	// make the ball invisible/unable to do anything/set up time scoring
	this.velocity = '0 0 0';
	set_movetype(this, MOVETYPE_NONE);
	this.effects |= EF_NODRAW;
	settouch(this, func_null);
	setthink(this, ka_TimeScoring);
	this.nextthink = time + 1;
	this.takedamage = DAMAGE_NO;
	this.event_damage = func_null;
	this.damagedbycontents = false;
	IL_REMOVE(g_damagedbycontents, this);
	navigation_dynamicgoal_unset(this);

	// apply effects to player
	toucher.glow_color = autocvar_g_keepawayball_trail_color;
	toucher.glow_trail = true;
	toucher.effects |= autocvar_g_keepaway_ballcarrier_effects;

	// messages and sounds
	ka_EventLog("pickup", toucher);
	Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_KEEPAWAY_PICKUP, toucher.netname);
	Send_Notification(NOTIF_ALL_EXCEPT, toucher, MSG_CENTER, CENTER_KEEPAWAY_PICKUP, toucher.netname);
	Send_Notification(NOTIF_ONE, toucher, MSG_CENTER, CENTER_KEEPAWAY_PICKUP_SELF);
	sound(this.owner, CH_TRIGGER, SND_KA_PICKEDUP, VOL_BASE, ATTEN_NONE); // ATTEN_NONE (it's a sound intended to be heard anywhere)

	// scoring
	GameRules_scoring_add(toucher, KEEPAWAY_PICKUPS, 1);

	// waypoints
	WaypointSprite_AttachCarrier(WP_KaBallCarrier, toucher, RADARICON_FLAGCARRIER);
	toucher.waypointsprite_attachedforcarrier.waypointsprite_visible_for_player = ka_ballcarrier_waypointsprite_visible_for_player;
	WaypointSprite_UpdateRule(toucher.waypointsprite_attachedforcarrier, 0, SPRITERULE_DEFAULT);
	WaypointSprite_Ping(toucher.waypointsprite_attachedforcarrier);
	WaypointSprite_Kill(this.waypointsprite_attachedforcarrier);
}

void ka_PlayerReset(entity player)
{
	player.ballcarried = NULL;
	GameRules_scoring_vip(player, false);
	WaypointSprite_Kill(player.waypointsprite_attachedforcarrier);

	// reset the player effects
	player.glow_trail = false;
	player.effects &= ~autocvar_g_keepaway_ballcarrier_effects;
}

void ka_DropEvent(entity player) // runs any time that a player is supposed to lose the ball
{
	entity ball = player.ballcarried;

	if(!ball) { return; }

	// reset the ball
	setattachment(ball, NULL, "");
	set_movetype(ball, MOVETYPE_BOUNCE);
	ball.wait = time + 1;
	settouch(ball, ka_TouchEvent);
	setthink(ball, ka_RespawnBall);
	ball.nextthink = time + autocvar_g_keepawayball_respawntime;
	ball.takedamage = DAMAGE_YES;
	ball.event_damage = ka_DamageEvent;
	ball.damagedbycontents = true;
	IL_PUSH(g_damagedbycontents, ball);
	ball.effects &= ~EF_NODRAW;
	setorigin(ball, player.origin + '0 0 10');
	ball.velocity = '0 0 200' + '0 100 0'*crandom() + '100 0 0'*crandom();
	ball.owner = NULL;
	navigation_dynamicgoal_set(ball, player);

	// messages and sounds
	ka_EventLog("dropped", player);
	Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_KEEPAWAY_DROPPED, player.netname);
	Send_Notification(NOTIF_ALL, NULL, MSG_CENTER, CENTER_KEEPAWAY_DROPPED, player.netname);
	sound(NULL, CH_TRIGGER, SND_KA_DROPPED, VOL_BASE, ATTEN_NONE); // ATTEN_NONE (it's a sound intended to be heard anywhere)

	// waypoints
	WaypointSprite_Spawn(WP_KaBall, 0, 0, ball, '0 0 64', NULL, ball.team, ball, waypointsprite_attachedforcarrier, false, RADARICON_FLAGCARRIER);
	WaypointSprite_UpdateRule(ball.waypointsprite_attachedforcarrier, 0, SPRITERULE_DEFAULT);
	WaypointSprite_Ping(ball.waypointsprite_attachedforcarrier);

	ka_PlayerReset(player);
}

.bool pushable;

MODEL(KA_BALL, "models/orbs/orbblue.md3");

void ka_RemoveBall(entity ball)
{
	entity player = ball.owner;
	if (player) // it was attached
		ka_PlayerReset(player);
	else
		WaypointSprite_DetachCarrier(ball);
	delete(ball);
}

void ka_RemoveBalls()
{
	IL_EACH(g_kaballs, true,
	{
		ka_RemoveBall(it);
	});
}

void ka_SpawnBall()
{
	entity e = new(keepawayball);
	setmodel(e, MDL_KA_BALL);
	setsize(e, '-16 -16 -20', '16 16 20'); // 20 20 20 was too big, player is only 16 16 24... gotta cheat with the Z (20) axis so that the particle isn't cut off
	e.damageforcescale = autocvar_g_keepawayball_damageforcescale;
	e.takedamage = DAMAGE_YES;
	e.event_damage = ka_DamageEvent;
	e.damagedbycontents = true;
	IL_PUSH(g_damagedbycontents, e);
	e.solid = SOLID_TRIGGER;
	set_movetype(e, MOVETYPE_BOUNCE);
	e.glow_color = autocvar_g_keepawayball_trail_color;
	e.glow_trail = true;
	e.flags = FL_ITEM;
	IL_PUSH(g_items, e);
	e.pushable = true;
	settouch(e, ka_TouchEvent);
	e.owner = NULL;
	IL_PUSH(g_kaballs, e);
	navigation_dynamicgoal_init(e, false);

	InitializeEntity(e, ka_RespawnBall, INITPRIO_SETLOCATION); // is this the right priority? Neh, I have no idea.. Well-- it works! So.
}

void ka_SpawnBalls(int ballcount)
{
	int realballcount = max(1, ballcount); // never allow less than 1 ball to spawn
	for(int j = 0; j < realballcount; ++j)
	{
		ka_SpawnBall();
	}
}

void ka_Handler_CheckBall(entity this)
{
	if(time < game_starttime)
	{
		if (!IL_EMPTY(g_kaballs))
			ka_RemoveBalls();
	}
	else
	{
		if (IL_EMPTY(g_kaballs))
			ka_SpawnBalls(KA_BALL_COUNT); // ;)
	}

	this.nextthink = time;
}

void ka_Initialize() // run at the start of a match, initiates game mode
{
	g_kaballs = IL_NEW();
	ka_Handler = new_pure(ka_Handler);
	setthink(ka_Handler, ka_Handler_CheckBall);
	ka_Handler.nextthink = time;
}


// ================
// Bot player logic
// ================

void havocbot_goalrating_ball(entity this, float ratingscale, vector org)
{
	entity ball = NULL, ball_carried = NULL;

	// stops at last ball, prefers ball without carrier
	IL_EACH(g_kaballs, it.owner != this,
	{
		if(it.owner)
			ball_carried = it.owner;
		else
			ball = it;
	});

	if(ball)
		navigation_routerating(this, ball, ratingscale, 2000);
	else if(ball_carried)
		navigation_routerating(this, ball_carried, ratingscale, 2000);
}

void havocbot_role_ka_carrier(entity this)
{
	if (IS_DEAD(this))
		return;

	if (navigation_goalrating_timeout(this))
	{
		navigation_goalrating_start(this);
		havocbot_goalrating_items(this, 10000, this.origin, 10000);
		havocbot_goalrating_enemyplayers(this, 10000, this.origin, 10000);
		havocbot_goalrating_waypoints(this, 1, this.origin, 3000);
		navigation_goalrating_end(this);

		navigation_goalrating_timeout_set(this);
	}

	if (!this.ballcarried)
	{
		this.havocbot_role = havocbot_role_ka_collector;
		navigation_goalrating_timeout_expire(this, 2);
	}
}

void havocbot_role_ka_collector(entity this)
{
	if (IS_DEAD(this))
		return;

	if (navigation_goalrating_timeout(this))
	{
		navigation_goalrating_start(this);
		havocbot_goalrating_items(this, 10000, this.origin, 10000);
		havocbot_goalrating_enemyplayers(this, 500, this.origin, 10000);
		havocbot_goalrating_ball(this, 8000, this.origin);
		navigation_goalrating_end(this);

		navigation_goalrating_timeout_set(this);
	}

	if (this.ballcarried)
	{
		this.havocbot_role = havocbot_role_ka_carrier;
		navigation_goalrating_timeout_expire(this, 2);
	}
}


// ==============
// Hook Functions
// ==============

MUTATOR_HOOKFUNCTION(ka, PlayerDies)
{
	entity frag_attacker = M_ARGV(1, entity);
	entity frag_target = M_ARGV(2, entity);

	if((frag_attacker != frag_target) && (IS_PLAYER(frag_attacker)))
	{
		if(frag_target.ballcarried) { // add to amount of times killing carrier
			GameRules_scoring_add(frag_attacker, KEEPAWAY_CARRIERKILLS, 1);
			if(autocvar_g_keepaway_score_bckill) // add bckills to the score
				GameRules_scoring_add(frag_attacker, SCORE, autocvar_g_keepaway_score_bckill);
		}
		else if(!frag_attacker.ballcarried)
			if(autocvar_g_keepaway_noncarrier_warn)
				Send_Notification(NOTIF_ONE_ONLY, frag_attacker, MSG_CENTER, CENTER_KEEPAWAY_WARN);

		if(frag_attacker.ballcarried) // add to amount of kills while ballcarrier
			GameRules_scoring_add(frag_attacker, SCORE, autocvar_g_keepaway_score_killac);
	}

	if(frag_target.ballcarried) { ka_DropEvent(frag_target); } // a player with the ball has died, drop it
}

MUTATOR_HOOKFUNCTION(ka, GiveFragsForKill)
{
	M_ARGV(2, float) = 0; // no frags counted in keepaway
	return true; // you deceptive little bugger ;3 This needs to be true in order for this function to even count.
}

MUTATOR_HOOKFUNCTION(ka, Scores_CountFragsRemaining)
{
	// announce remaining frags, but only when timed scoring is off
	return !autocvar_g_keepaway_score_timepoints;
}

MUTATOR_HOOKFUNCTION(ka, PlayerPreThink)
{
	entity player = M_ARGV(0, entity);

	// if the player has the ball, make sure they have the item for it (Used for HUD primarily)
	STAT(OBJECTIVE_STATUS, player) = BITSET(STAT(OBJECTIVE_STATUS, player), KA_CARRYING, player.ballcarried != NULL);
}

MUTATOR_HOOKFUNCTION(ka, PlayerUseKey)
{
	entity player = M_ARGV(0, entity);

	if(MUTATOR_RETURNVALUE == 0)
	if(player.ballcarried)
	{
		ka_DropEvent(player);
		return true;
	}
}

MUTATOR_HOOKFUNCTION(ka, Damage_Calculate) // for changing damage and force values that are applied to players in damage.qc
{
	entity frag_attacker = M_ARGV(1, entity);
	entity frag_target = M_ARGV(2, entity);

	// as a gamemode rule, only apply scaling to player versus player combat
	if(!IS_PLAYER(frag_attacker) || !IS_PLAYER(frag_target))
		return;

	if(frag_attacker.ballcarried) // if the attacker is a ballcarrier
	{
		if(frag_target == frag_attacker) // damage done to yourself
		{
			M_ARGV(4, float) *= autocvar_g_keepaway_ballcarrier_selfdamage;
			M_ARGV(6, vector) *= autocvar_g_keepaway_ballcarrier_selfforce;
		}
		else // damage done to noncarriers
		{
			M_ARGV(4, float) *= autocvar_g_keepaway_ballcarrier_damage;
			M_ARGV(6, vector) *= autocvar_g_keepaway_ballcarrier_force;
		}
	}
	else // if the target is a noncarrier
	{
		if(frag_target == frag_attacker) // damage done to yourself
		{
			M_ARGV(4, float) *= autocvar_g_keepaway_noncarrier_selfdamage;
			M_ARGV(6, vector) *= autocvar_g_keepaway_noncarrier_selfforce;
		}
		else // damage done to other noncarriers
		{
			M_ARGV(4, float) *= autocvar_g_keepaway_noncarrier_damage;
			M_ARGV(6, vector) *= autocvar_g_keepaway_noncarrier_force;
		}
	}
}

MUTATOR_HOOKFUNCTION(ka, ClientDisconnect)
{
	entity player = M_ARGV(0, entity);

	if(player.ballcarried) { ka_DropEvent(player); } // a player with the ball has left the match, drop it
}

MUTATOR_HOOKFUNCTION(ka, MakePlayerObserver)
{
	entity player = M_ARGV(0, entity);

	if(player.ballcarried) { ka_DropEvent(player); } // a player with the ball has left the match, drop it
}

MUTATOR_HOOKFUNCTION(ka, PlayerPowerups)
{
	entity player = M_ARGV(0, entity);

	// In the future this hook is supposed to allow me to do some extra stuff with waypointsprites and invisibility powerup
	// So bare with me until I can fix a certain bug with ka_ballcarrier_waypointsprite_visible_for_player()

	player.effects &= ~autocvar_g_keepaway_ballcarrier_effects;

	if(player.ballcarried)
		player.effects |= autocvar_g_keepaway_ballcarrier_effects;
}


MUTATOR_HOOKFUNCTION(ka, PlayerPhysics_UpdateStats)
{
	entity player = M_ARGV(0, entity);
	// these automatically reset, no need to worry

	if(player.ballcarried)
		STAT(MOVEVARS_HIGHSPEED, player) *= autocvar_g_keepaway_ballcarrier_highspeed;
}

MUTATOR_HOOKFUNCTION(ka, BotShouldAttack)
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
	if(!targ.ballcarried && !bot.ballcarried && have_held_ball)
		return true;
}

MUTATOR_HOOKFUNCTION(ka, HavocBot_ChooseRole)
{
	entity bot = M_ARGV(0, entity);

	if (bot.ballcarried)
		bot.havocbot_role = havocbot_role_ka_carrier;
	else
		bot.havocbot_role = havocbot_role_ka_collector;
	return true;
}

MUTATOR_HOOKFUNCTION(ka, DropSpecialItems)
{
	entity frag_target = M_ARGV(0, entity);

	if(frag_target.ballcarried)
		ka_DropEvent(frag_target);
}
