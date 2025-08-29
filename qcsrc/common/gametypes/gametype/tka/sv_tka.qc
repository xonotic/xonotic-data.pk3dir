#include "sv_tka.qh"

#include <common/checkextension.qh>
#include <common/effects/all.qh>

.entity ballcarried;
.entity previous_owner; // also used on kh keys

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

bool tka_ballcarrier_waypointsprite_visible_for_player(entity this, entity player, entity view) // runs on waypoints which are attached to ballcarriers, updates once per frame
{
	if(view.ballcarried && IS_SPEC(player))
		return false; // we don't want spectators of the ballcarrier to see the attached waypoint on the top of their screen
	if(IS_SPEC(player) || warmup_stage || SAME_TEAM(player, this.owner))
		return true;
	if(IS_INVISIBLE(this.owner))
		return false; // hide the waypointsprite if the owner is invisible

	return autocvar_g_tkaball_tracking == 1;
}

void tka_EventLog(string mode, entity actor) // use an alias for easy changing and quick editing later
{
	if(autocvar_sv_eventlog)
		GameLogEcho(strcat(":tka:", mode, ((actor != NULL) ? (strcat(":", ftos(actor.team), ":", ftos(actor.playerid))) : "")));
}

void tka_TouchEvent(entity this, entity toucher);
void tka_RespawnBall(entity this) // runs whenever the ball needs to be relocated
{
	if(game_stopped) return;
	vector oldballorigin = this.origin;

	if(!MoveToRandomMapLocation(this, DPCONTENTS_SOLID | DPCONTENTS_CORPSE | DPCONTENTS_PLAYERCLIP, DPCONTENTS_SLIME | DPCONTENTS_LAVA | DPCONTENTS_SKY | DPCONTENTS_BODY | DPCONTENTS_DONOTENTER, Q3SURFACEFLAG_SKY, 10, 1024, 256))
		setorigin(this, SelectSpawnPoint(this, true).origin);

	set_movetype(this, MOVETYPE_BOUNCE);
	this.velocity = '0 0 200';
	this.angles = '0 0 0';
	this.effects = autocvar_g_tkaball_effects;
	setthink(this, tka_RespawnBall);
	this.nextthink = time + autocvar_g_tkaball_respawntime;
	navigation_dynamicgoal_set(this, NULL);

	Send_Effect(EFFECT_KA_BALL_RESPAWN, oldballorigin, '0 0 0', 1);
	Send_Effect(EFFECT_KA_BALL_RESPAWN, this.origin, '0 0 0', 1);

	if(autocvar_g_tkaball_tracking || warmup_stage)
	{
		WaypointSprite_Spawn(WP_KaBall, 0, 0, this, '0 0 64', NULL, this.team, this, waypointsprite_attachedforcarrier, false, RADARICON_FLAGCARRIER);
		WaypointSprite_Ping(this.waypointsprite_attachedforcarrier);
	}

	sound(this, CH_TRIGGER, SND_KA_RESPAWN, VOL_BASE, ATTEN_NONE); // ATTEN_NONE (it's a sound intended to be heard anywhere)
}

// field where the decimal part of SCORE is accumulated (shared with other gametypes)
.float float2int_decimal_fld;
MUTATOR_HOOKFUNCTION(tka, reset_map_global)
{
	FOREACH_CLIENT(true,
	{
		it.float2int_decimal_fld = 0;
	});
	return true;
}

/// runs (only) while a player is carrying the ball
void tka_BallThink_Carried(entity this)
{
	if (autocvar_g_tka_score_timepoints)
		GameRules_scoring_add_team_float2int(this.owner, SCORE, autocvar_g_tka_score_timepoints * frametime, float2int_decimal_fld, 1);
	GameRules_scoring_add(this.owner, TKA_BCTIME, frametime);

	this.nextthink = time;

	// animate, this is ~copied from KH
#define BALL_XYSPEED 100 // KH 45
#define BALL_XYDIST 24 // KH 24
	makevectors(vec3(0, (360 * this.cnt / this.owner.ballcarried.cnt) + (time % 360) * BALL_XYSPEED, 0));
	setorigin(this, vec3(v_forward.x * BALL_XYDIST, v_forward.y * BALL_XYDIST, this.origin.z));

	// sync any invisibility effect
	this.alpha = this.owner.alpha;
}

void tka_TouchEvent(entity this, entity toucher) // runs any time that the ball comes in contact with something
{
	if (!this || game_stopped)
		return;

	if(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT)
	{ // The ball fell off the map, respawn it since players can't get to it
		tka_RespawnBall(this);
		return;
	}
	if(IS_INDEPENDENT_PLAYER(toucher)) { return; }
	if(IS_DEAD(toucher)) { return; }
	if (!IS_PLAYER(toucher))
	{  // The ball just touched an object, most likely the world
		Send_Effect(EFFECT_BALL_SPARKS, this.origin, '0 0 0', 1);
		sound(this, CH_TRIGGER, SND_KA_TOUCH, VOL_BASE, ATTEN_NORM);
		return;
	}
	else if(this.wait > time && this.previous_owner == toucher)
		return;

	if (toucher.ballcarried) // multiple balls exist
	{
		if (toucher.ballcarried.cnt >= autocvar_g_tka_ballcarrier_maxballs)
			return;
		this.ballcarried = toucher.ballcarried; // new ball will be inserted at start of chain
		this.cnt = toucher.ballcarried.cnt + 1; // for orbit animation offset
	}
	else
		this.cnt = 1;

	// attach the ball to the player
	this.owner = toucher;
	toucher.ballcarried = this;
	GameRules_scoring_vip(toucher, true);
	setattachment(this, toucher, "");
	this.solid = SOLID_NOT; // before setorigin to ensure area grid unlinking
	setorigin(this, '0 0 0');

	// make the ball unable to do anything, set up time scoring
	this.velocity = '0 0 0';
	set_movetype(this, MOVETYPE_NONE);
	this.scale = 12/16; // somewhat smaller while carried
	setthink(this, tka_BallThink_Carried);
	this.nextthink = time;
	this.takedamage = DAMAGE_NO;
	navigation_dynamicgoal_unset(this);

	// messages and sounds
	tka_EventLog("pickup", toucher);
	Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_KEEPAWAY_PICKUP, toucher.netname);
	Send_Notification(NOTIF_ALL_EXCEPT, toucher, MSG_CENTER, CENTER_KEEPAWAY_PICKUP, toucher.netname);
	Send_Notification(NOTIF_ONE, toucher, MSG_CENTER, CENTER_KEEPAWAY_PICKUP_SELF);
	sound(this.owner, CH_TRIGGER, SND_KA_PICKEDUP, VOL_BASE, ATTEN_NONE); // ATTEN_NONE (it's a sound intended to be heard anywhere)

	// scoring
	GameRules_scoring_add(toucher, TKA_PICKUPS, 1);

	// waypoints
	WaypointSprite_AttachCarrier(WP_Null, toucher, RADARICON_FLAGCARRIER);
	toucher.waypointsprite_attachedforcarrier.colormod = colormapPaletteColor(toucher.team - 1, 0);
	toucher.waypointsprite_attachedforcarrier.waypointsprite_visible_for_player = tka_ballcarrier_waypointsprite_visible_for_player;
	WaypointSprite_UpdateRule(toucher.waypointsprite_attachedforcarrier, toucher.team, SPRITERULE_TEAMPLAY);
	if(toucher.team == NUM_TEAM_1)
		WaypointSprite_UpdateSprites(toucher.waypointsprite_attachedforcarrier, WP_TkaBallCarrierRed, WP_KaBallCarrier, WP_TkaBallCarrierRed);
	else if(toucher.team == NUM_TEAM_2)
		WaypointSprite_UpdateSprites(toucher.waypointsprite_attachedforcarrier, WP_TkaBallCarrierBlue, WP_KaBallCarrier, WP_TkaBallCarrierBlue);
	else if(toucher.team == NUM_TEAM_3)
		WaypointSprite_UpdateSprites(toucher.waypointsprite_attachedforcarrier, WP_TkaBallCarrierYellow, WP_KaBallCarrier, WP_TkaBallCarrierYellow);
	else if(toucher.team == NUM_TEAM_4)
		WaypointSprite_UpdateSprites(toucher.waypointsprite_attachedforcarrier, WP_TkaBallCarrierPink, WP_KaBallCarrier, WP_TkaBallCarrierPink);
	WaypointSprite_Ping(toucher.waypointsprite_attachedforcarrier);
	WaypointSprite_Kill(this.waypointsprite_attachedforcarrier);
}

void tka_PlayerReset(entity player)
{
	player.ballcarried = NULL;
	GameRules_scoring_vip(player, false);
	WaypointSprite_Kill(player.waypointsprite_attachedforcarrier);
}

void tka_DropEvent(entity player) // runs any time that a player is supposed to lose the ball
{
	entity ball;
	ball = player.ballcarried;

	if(!ball) { return; }

	// reset the ball
	setattachment(ball, NULL, "");
	set_movetype(ball, MOVETYPE_BOUNCE);
	ball.previous_owner = player;
	ball.wait = time + 0.5; // same as for thrown weapons
	setthink(ball, tka_RespawnBall);
	ball.nextthink = time + autocvar_g_tkaball_respawntime;
	ball.takedamage = DAMAGE_YES;
	ball.scale = 1; // it's smaller while carried
	ball.alpha = 1; // in case the carrier had an invisibility effect
	ball.solid = SOLID_TRIGGER; // before setorigin to ensure area grid linking
	setorigin(ball, player.origin + ball.origin + '0 0 10'); // include attachment offset to reduce jump
	nudgeoutofsolid_OrFallback(ball); // a ball has a horizontally bigger bbox than a player
	ball.velocity = '0 0 200' + '0 100 0'*crandom() + '100 0 0'*crandom();
	ball.owner = NULL;
	navigation_dynamicgoal_set(ball, player);

	// messages and sounds
	tka_EventLog("dropped", player);
	Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_KEEPAWAY_DROPPED, player.netname);
	Send_Notification(NOTIF_ALL, NULL, MSG_CENTER, CENTER_KEEPAWAY_DROPPED, player.netname);
	sound(NULL, CH_TRIGGER, SND_KA_DROPPED, VOL_BASE, ATTEN_NONE); // ATTEN_NONE (it's a sound intended to be heard anywhere)

	// waypoints
	if(autocvar_g_tkaball_tracking || warmup_stage)
	{
		WaypointSprite_Spawn(WP_KaBall, 0, 0, ball, '0 0 64', NULL, ball.team, ball, waypointsprite_attachedforcarrier, false, RADARICON_FLAGCARRIER);
		WaypointSprite_UpdateRule(ball.waypointsprite_attachedforcarrier, 0, SPRITERULE_DEFAULT);
		WaypointSprite_Ping(ball.waypointsprite_attachedforcarrier);
	}

	if (ball.ballcarried) // >1 ball was chained, first one was just dropped
	{
		player.ballcarried = ball.ballcarried; // move the next one up
		ball.ballcarried = NULL; // prevent infinite loop
	}
	else // no balls remaining so remove bc status
		tka_PlayerReset(player);
}

.bool pushable;

MODEL(TKA_BALL, "models/orbs/orbblue.md3");

void tka_RemoveBalls()
{
	IL_EACH(g_tkaballs, true,
	{
		if (it.owner) // it was attached
			tka_PlayerReset(it.owner);
		else
			WaypointSprite_DetachCarrier(it);
		delete(it);
	});
}

void tka_SpawnBalls()
{
	int i = 0;
	do // never allow less than 1 ball to spawn
	{
		entity e = new(keepawayball);
		setmodel(e, MDL_TKA_BALL);
		// 20 20 20 was too big, player is only 16 16 24... gotta cheat with the Z (20) axis so that the particle isn't cut off
		// bones_was_here: that was WITH sv_legacy_bbox_expand 1 and FL_ITEM (mins -= '15 15 1'; maxs += '15 15 1')
		// it's round so should have a symmetrical bbox, same height as pickup items so it can't be jumped over in any physics
		setsize(e, '-24 -24 -24', '24 24 24');
		e.damageforcescale = autocvar_g_tkaball_damageforcescale;
		e.takedamage = DAMAGE_YES;
		e.solid = SOLID_TRIGGER;
		set_movetype(e, MOVETYPE_BOUNCE);
		e.glow_color = autocvar_g_tkaball_trail_color;
		e.glow_trail = true;
		e.flags = FL_ITEM;
		IL_PUSH(g_items, e);
		e.pushable = true;
		settouch(e, tka_TouchEvent);
		e.owner = NULL;
		IL_PUSH(g_tkaballs, e);
		navigation_dynamicgoal_init(e, false);

		tka_RespawnBall(e);

		++i;
	}
	while (i < autocvar_g_tkaball_count);
}

void tka_Handler_CheckBall(entity this)
{
	if(time < game_starttime)
	{
		if (!IL_EMPTY(g_tkaballs))
			tka_RemoveBalls();
	}
	else
	{
		if (IL_EMPTY(g_tkaballs))
			tka_SpawnBalls();
	}

	this.nextthink = time;
}


// ================
// Bot player logic
// ================

bool tka_waypointsprite_visible_for_bot(entity this, entity e, bool dropped)
{
	entity ball_wp = e.waypointsprite_attachedforcarrier;
	if (!ball_wp)
	if (dropped || !ball_wp.waypointsprite_visible_for_player(ball_wp, this, WaypointSprite_getviewentity(this)))
	{ // has no waypoint, or waypoint not visible
		if (!checkpvs(this.origin + this.view_ofs, e)) // ball cannot be seen
			return false;
	}
	return true;
}

void havocbot_goalrating_tkaball(entity this, float ratingscale, float ratingscale_sameteam, vector org)
{
	entity ball = NULL, ball_carried = NULL;

	// stops at last ball, prefers ball without carrier
	IL_EACH(g_tkaballs, it.owner != this,
	{
		if (it.owner)
		{
			if (!tka_waypointsprite_visible_for_bot(this, it.owner, false))
				continue;
			ball_carried = it.owner;
		}
		else
		{
			if (!tka_waypointsprite_visible_for_bot(this, it, true))
				continue;
			ball = it;
		}
	});

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

void havocbot_role_tka_carrier(entity this)
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
		this.havocbot_role = havocbot_role_tka_collector;
		navigation_goalrating_timeout_expire(this, 2);
	}
}

void havocbot_role_tka_collector(entity this)
{
	if (IS_DEAD(this))
		return;

	if (navigation_goalrating_timeout(this))
	{
		navigation_goalrating_start(this);
		havocbot_goalrating_items(this, 10000, this.origin, 10000);
		havocbot_goalrating_enemyplayers(this, 500, this.origin, 10000);
		havocbot_goalrating_tkaball(this, 8000, 4000, this.origin);
		navigation_goalrating_end(this);

		navigation_goalrating_timeout_set(this);
	}

	if (this.ballcarried)
	{
		this.havocbot_role = havocbot_role_tka_carrier;
		navigation_goalrating_timeout_expire(this, 2);
	}
}


// ==============
// Hook Functions
// ==============

MUTATOR_HOOKFUNCTION(tka, PlayerDies)
{
	entity frag_attacker = M_ARGV(1, entity);
	entity frag_target = M_ARGV(2, entity);

	if(frag_attacker != frag_target && IS_PLAYER(frag_attacker) && DIFF_TEAM(frag_attacker, frag_target))
	{
		bool team_has_ball = false;
		IL_EACH(g_tkaballs, it.owner != frag_attacker && SAME_TEAM(it.owner, frag_attacker),
		{
			team_has_ball = true;
			break;
		});
		if(frag_target.ballcarried) // add to amount of times killing carrier
		{
			GameRules_scoring_add(frag_attacker, TKA_CARRIERKILLS, 1);
			if(autocvar_g_tka_score_bckill) // add bckills to the score
				GameRules_scoring_add_team(frag_attacker, SCORE, autocvar_g_tka_score_bckill);
		}
		else if(!frag_attacker.ballcarried && !(autocvar_g_tka_score_team && team_has_ball))
		{
			if(autocvar_g_tka_noncarrier_warn)
				Send_Notification(NOTIF_ONE_ONLY, frag_attacker, MSG_CENTER, CENTER_KEEPAWAY_WARN);
		}

		if(frag_attacker.ballcarried || (autocvar_g_tka_score_team && team_has_ball)) // add to amount of kills while ballcarrier (or if team scoring is enabled)
			GameRules_scoring_add_team(frag_attacker, SCORE, autocvar_g_tka_score_killac);
	}

	while (frag_target.ballcarried)
		tka_DropEvent(frag_target); // a player with ball(s) has died, drop them
}

MUTATOR_HOOKFUNCTION(tka, GiveFragsForKill)
{
	M_ARGV(2, float) = 0; // no frags counted in keepaway
	return true; // you deceptive little bugger ;3 This needs to be true in order for this function to even count.
}

MUTATOR_HOOKFUNCTION(tka, Scores_CountFragsRemaining)
{
	// announce remaining frags, but only when timed scoring is off
	return !autocvar_g_tka_score_timepoints;
}

MUTATOR_HOOKFUNCTION(tka, PlayerPreThink)
{
	entity player = M_ARGV(0, entity);

	// clear the item used for the ball in keepaway
	STAT(TKA_BALLSTATUS, player) = 0;

	// if the player has the ball, make sure they have the item for it (Used for HUD primarily)
	if(player.ballcarried)
		STAT(TKA_BALLSTATUS, player) |= TKA_BALL_CARRYING;

	IL_EACH(g_tkaballs, true,
	{
		if(!it.owner)
			STAT(TKA_BALLSTATUS, player) |= TKA_BALL_DROPPED;
		else
		{
			// TODO: teamless carrier?
			switch(it.owner.team)
			{
				case NUM_TEAM_1: STAT(TKA_BALLSTATUS, player) |= TKA_BALL_TAKEN_RED; break;
				case NUM_TEAM_2: STAT(TKA_BALLSTATUS, player) |= TKA_BALL_TAKEN_BLUE; break;
				case NUM_TEAM_3: STAT(TKA_BALLSTATUS, player) |= TKA_BALL_TAKEN_YELLOW; break;
				case NUM_TEAM_4: STAT(TKA_BALLSTATUS, player) |= TKA_BALL_TAKEN_PINK; break;
			}
		}
	});
}

MUTATOR_HOOKFUNCTION(tka, PlayerUseKey)
{
	entity player = M_ARGV(0, entity);

	if(MUTATOR_RETURNVALUE == 0)
	if(player.ballcarried)
	{
		tka_DropEvent(player);
		return true;
	}
}

MUTATOR_HOOKFUNCTION(tka, Damage_Calculate) // for changing damage and force values that are applied to players
{
	entity frag_attacker = M_ARGV(1, entity);
	entity frag_target = M_ARGV(2, entity);

	// as a gametype rule, only apply scaling to player versus player combat
	if (!IS_PLAYER(frag_attacker) || !IS_PLAYER(frag_target))
		return;

	if (frag_attacker.ballcarried) // if the attacker is a ballcarrier
	{
		if (frag_target == frag_attacker) // damage done to themselves
		{
			M_ARGV(4, float) *= autocvar_g_tka_ballcarrier_damage.x;
			M_ARGV(6, vector) *= autocvar_g_tka_ballcarrier_force.x;
		}
		else if (frag_target.ballcarried) // damage done to other ballcarriers
		{
			M_ARGV(4, float) *= autocvar_g_tka_ballcarrier_damage.y;
			M_ARGV(6, vector) *= autocvar_g_tka_ballcarrier_force.y;
		}
		else // damage done to noncarriers
		{
			M_ARGV(4, float) *= autocvar_g_tka_ballcarrier_damage.z;
			M_ARGV(6, vector) *= autocvar_g_tka_ballcarrier_force.z;
		}
	}
	else
	{
		if (frag_target == frag_attacker) // damage done to themselves
		{
			M_ARGV(4, float) *= autocvar_g_tka_noncarrier_damage.x;
			M_ARGV(6, vector) *= autocvar_g_tka_noncarrier_force.x;
		}
		else if (frag_target.ballcarried) // damage done to ballcarriers
		{
			M_ARGV(4, float) *= autocvar_g_tka_noncarrier_damage.y;
			M_ARGV(6, vector) *= autocvar_g_tka_noncarrier_force.y;
		}
		else // damage done to other noncarriers
		{
			M_ARGV(4, float) *= autocvar_g_tka_noncarrier_damage.z;
			M_ARGV(6, vector) *= autocvar_g_tka_noncarrier_force.z;
		}
	}
}

MUTATOR_HOOKFUNCTION(tka, ClientDisconnect)
{
	entity player = M_ARGV(0, entity);

	while (player.ballcarried)
		tka_DropEvent(player); // a player with ball(s) has left the match, drop them
}

MUTATOR_HOOKFUNCTION(tka, MakePlayerObserver)
{
	entity player = M_ARGV(0, entity);

	while (player.ballcarried)
		tka_DropEvent(player); // a player with ball(s) has left the match, drop them
}

MUTATOR_HOOKFUNCTION(tka, PlayerPowerups)
{
//	entity player = M_ARGV(0, entity);

	// In the future this hook is supposed to allow me to do some extra stuff with waypointsprites and invisibility powerup
	// So bare with me until I can fix a certain bug with tka_ballcarrier_waypointsprite_visible_for_player()
}


MUTATOR_HOOKFUNCTION(tka, PlayerPhysics_UpdateStats)
{
	entity player = M_ARGV(0, entity);
	// these automatically reset, no need to worry

	if(player.ballcarried)
		STAT(MOVEVARS_HIGHSPEED, player) *= autocvar_g_tka_ballcarrier_highspeed;
}

MUTATOR_HOOKFUNCTION(tka, BotShouldAttack)
{
	entity bot = M_ARGV(0, entity);
	entity targ = M_ARGV(1, entity);

	// if neither player has ball then don't attack unless the ball is on the ground
	bool have_held_ball = false, team_has_ball = false;
	IL_EACH(g_tkaballs, it.owner,
	{
		have_held_ball = true;
		if(SAME_TEAM(bot, it.owner))
			team_has_ball = true;
	});

	if(!targ.ballcarried && !bot.ballcarried && have_held_ball && !(autocvar_g_tka_score_team && team_has_ball))
		return true;
}

MUTATOR_HOOKFUNCTION(tka, HavocBot_ChooseRole)
{
	entity bot = M_ARGV(0, entity);

	if (bot.ballcarried)
		bot.havocbot_role = havocbot_role_tka_carrier;
	else
		bot.havocbot_role = havocbot_role_tka_collector;
	return true;
}

MUTATOR_HOOKFUNCTION(tka, DropSpecialItems)
{
	entity frag_target = M_ARGV(0, entity);

	while (frag_target.ballcarried)
		tka_DropEvent(frag_target);
}

MUTATOR_HOOKFUNCTION(tka, SpectateCopy)
{
	entity spectatee = M_ARGV(0, entity);
	entity client = M_ARGV(1, entity);

	STAT(TKA_BALLSTATUS, client) = STAT(TKA_BALLSTATUS, spectatee);
}

MUTATOR_HOOKFUNCTION(tka, TeamBalance_CheckAllowedTeams, CBC_ORDER_EXCLUSIVE)
{
	M_ARGV(0, float) = tka_teams;
	return true;
}

void tka_Initialize()
{
	tka_teams = autocvar_g_tka_teams_override;
	if(tka_teams < 2)
		tka_teams = cvar("g_tka_teams"); // read the cvar directly as it gets written earlier in the same frame
	tka_teams = BITS(bound(2, tka_teams, 4));
	GameRules_scoring(tka_teams, SFL_SORT_PRIO_PRIMARY, SFL_SORT_PRIO_PRIMARY, {
		field(SP_TKA_PICKUPS, "pickups", 0);
		field(SP_TKA_CARRIERKILLS, "bckills", 0);
		field(SP_TKA_BCTIME, "bctime", SFL_SORT_PRIO_SECONDARY);
	});

	g_tkaballs = IL_NEW();
	entity tka_Handler = new_pure(tka_Handler);
	setthink(tka_Handler, tka_Handler_CheckBall);
	InitializeEntity(tka_Handler, tka_Handler_CheckBall, INITPRIO_GAMETYPE);
}
