#include "sv_ball.qh"

#include <common/effects/all.qh>
#include <common/mutators/mutator/waypoints/waypointsprites.qh>
#include <common/notifications/all.qh>
#include <common/stats.qh>
#include <server/spawnpoints.qh>
#include <server/world.qh>


void kaball_BallStatuses_SendBalls(IntrusiveList ball_list, int ball_count)
{
	WriteShort(MSG_ENTITY, max(1, ball_count));
	IL_EACH(ball_list, true, WriteByte(MSG_ENTITY, (it.owner ? etof(it.owner) : 0)));
}

void kaball_RespawnBall(entity this, void(entity) think_func, int fx, float respawntime, int tracking)
{
	if (game_stopped)
		return;
	vector oldballorigin = this.origin;

	if (!MoveToRandomMapLocation(this, DPCONTENTS_SOLID | DPCONTENTS_CORPSE | DPCONTENTS_PLAYERCLIP, DPCONTENTS_SLIME | DPCONTENTS_LAVA | DPCONTENTS_SKY | DPCONTENTS_BODY | DPCONTENTS_DONOTENTER, Q3SURFACEFLAG_SKY, 10, 1024, 256))
		setorigin(this, SelectSpawnPoint(this, true).origin);

	set_movetype(this, MOVETYPE_BOUNCE);
	this.velocity = '0 0 200';
	this.angles = '0 0 0';
	this.effects = fx;
	setthink(this, think_func);
	this.nextthink = time + respawntime;
	navigation_dynamicgoal_set(this, NULL);

	Send_Effect(EFFECT_ITEM_TELEPORT, oldballorigin, '0 0 0', 1);
	Send_Effect(EFFECT_ITEM_TELEPORT, this.origin, '0 0 0', 1);

	if (tracking || warmup_stage)
	{
		WaypointSprite_Spawn(WP_KaBall, 0, 0, this, '0 0 64', NULL, this.team, this, waypointsprite_attachedforcarrier, false, RADARICON_FLAGCARRIER);
		WaypointSprite_Ping(this.waypointsprite_attachedforcarrier);
	}

	sound(this, CH_TRIGGER, SND_KA_RESPAWN, VOL_BASE, ATTEN_NONE); // ATTEN_NONE (it's a sound intended to be heard anywhere)
}

void kaball_BallThink_Carried(entity this)
{
	this.nextthink = time;

	// animate, this is ~copied from KH
#define BALL_XYSPEED 100 /* KH 45 */
#define BALL_XYDIST 24 /* KH 24 */
	makevectors(vec3(0, 360 * this.cnt / this.owner.ballcarried.cnt + (time % 360) * BALL_XYSPEED, 0));
	setorigin(this, vec3(v_forward.x * BALL_XYDIST, v_forward.y * BALL_XYDIST, this.origin.z));
#undef BALL_XYSPEED
#undef BALL_XYDIST

	// sync any invisibility effect
	this.alpha = this.owner.alpha;
}

void kaball_TouchEvent(entity this, entity toucher,
	void(entity) modify_ball_func, void(entity) RespawnBall_func, void(entity) BallThink_Carried_func, void(string, entity) EventLog_func, void() BallStatuses_SendBalls_func,
	int maxballs)
{
	if (!this || game_stopped)
		return;

	if (trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT) // the ball fell off the map, respawn it since players can't get to it
	{
		RespawnBall_func(this);
		return;
	}

	// TODO: mutator hook to prevent picking up objectives
	if (IS_INDEPENDENT_PLAYER(toucher) || IS_DEAD(toucher))
		return;
	if (!IS_PLAYER(toucher)) // the ball just touched an object, most likely the world
	{
		Send_Effect(EFFECT_BALL_SPARKS, this.origin, '0 0 0', 1);
		sound(this, CH_TRIGGER, SND_KA_TOUCH, VOL_BASE, ATTEN_NORM);
		return;
	}
	else if (this.wait > time && this.previous_owner == toucher)
		return;

	if (toucher.ballcarried) // multiple balls exist
	{
		if (toucher.ballcarried.cnt >= maxballs)
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
	setthink(this, BallThink_Carried_func);
	this.nextthink = time;
	this.takedamage = DAMAGE_NO;
	if (modify_ball_func)
		modify_ball_func(this);
	navigation_dynamicgoal_unset(this);

	// messages and sounds
	EventLog_func("pickup", toucher);
	Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_KEEPAWAY_PICKUP, toucher.netname);
	Send_Notification(NOTIF_ALL_EXCEPT, toucher, MSG_CENTER, CENTER_KEEPAWAY_PICKUP, toucher.netname);
	Send_Notification(NOTIF_ONE, toucher, MSG_CENTER, CENTER_KEEPAWAY_PICKUP_SELF);
	sound(this.owner, CH_TRIGGER, SND_KA_PICKEDUP, VOL_BASE, ATTEN_NONE); // ATTEN_NONE (it's a sound intended to be heard anywhere)

	BallStatuses_SendBalls_func();
}

void kaball_PlayerReset(entity player)
{
	player.ballcarried = NULL;
	GameRules_scoring_vip(player, false);
	WaypointSprite_Kill(player.waypointsprite_attachedforcarrier);
}

void kaball_DropEvent(entity player,
	void(entity) modify_ball_func, void(entity) RespawnBall_func, void(string, entity) EventLog_func,
	float respawntime, int tracking)
{
	entity ball = player.ballcarried;
	if (!ball)
		return;

	// reset the ball
	setattachment(ball, NULL, "");
	set_movetype(ball, MOVETYPE_BOUNCE);
	ball.previous_owner = player;
	ball.wait = time + 0.5; // same as for thrown weapons
	setthink(ball, RespawnBall_func);
	ball.nextthink = time + respawntime;
	ball.takedamage = DAMAGE_YES;
	if (modify_ball_func)
		modify_ball_func(ball);
	ball.scale = 1; // it's smaller while carried
	ball.alpha = 1; // in case the carrier had an invisibility effect
	ball.solid = SOLID_TRIGGER; // before setorigin to ensure area grid linking
	setorigin(ball, player.origin + ball.origin + '0 0 10'); // include attachment offset to reduce jump
	nudgeoutofsolid_OrFallback(ball); // a ball has a horizontally bigger bbox than a player
	ball.velocity.z = 200;
	ball.velocity.y = 100 * crandom();
	ball.velocity.x = 100 * crandom();
	ball.owner = NULL;
	navigation_dynamicgoal_set(ball, player);

	// messages and sounds
	EventLog_func("dropped", player);
	Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_KEEPAWAY_DROPPED, player.netname);
	Send_Notification(NOTIF_ALL, NULL, MSG_CENTER, CENTER_KEEPAWAY_DROPPED, player.netname);
	sound(NULL, CH_TRIGGER, SND_KA_DROPPED, VOL_BASE, ATTEN_NONE); // ATTEN_NONE (it's a sound intended to be heard anywhere)

	// waypoints
	if (tracking || warmup_stage)
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
		kaball_PlayerReset(player);

	return;
}

/// Assumed they have some, confirm before calling
void kaball_DropPlayersBalls(entity player, void(entity) DropEvent_func, void() BallStatuses_SendBalls_func)
{
	do
		DropEvent_func(player);
	while (player.ballcarried);
	BallStatuses_SendBalls_func();
}

void kaball_RemoveBalls(IntrusiveList ball_list)
{
	IL_EACH(ball_list, true,
	{
		if (it.owner) // it was attached
			kaball_PlayerReset(it.owner);
		else
			WaypointSprite_DetachCarrier(it);
		delete(it);
	});
}

.bool pushable;
void kaball_SpawnBalls(Model model, bool set_solid, float dfs, int trail_color, int ball_count,
	void(entity) modify_ball_func, void(entity, entity) TouchEvent_func, void(entity) RespawnBall_func, void() BallStatuses_SendBalls_func)
{
	int i = 0;
	do // do: never allow less than 1 ball to spawn
	{
		entity e = new(keepawayball);
		setmodel(e, model);
		e.solid = SOLID_TRIGGER; // before setsize to ensure area grid linking
		// 20 20 20 was too big, player is only 16 16 24... gotta cheat with the Z (20) axis so that the particle isn't cut off
		// bones_was_here: that was WITH sv_legacy_bbox_expand 1 and FL_ITEM (mins -= '15 15 1'; maxs += '15 15 1')
		// it's round so should have a symmetrical bbox, same height as pickup items so it can't be jumped over in any physics
		setsize(e, '-24 -24 -24', '24 24 24');
		e.damageforcescale = dfs;
		e.takedamage = DAMAGE_YES;
		if (modify_ball_func)
			modify_ball_func(e);
		set_movetype(e, MOVETYPE_BOUNCE);
		e.glow_color = trail_color;
		e.glow_trail = true;
		e.flags = FL_ITEM;
		IL_PUSH(g_items, e);
		e.pushable = true;
		settouch(e, TouchEvent_func);
		e.owner = NULL;
		IL_PUSH(g_tkaballs, e);
		navigation_dynamicgoal_init(e, false);

		RespawnBall_func(e);
	}
	while (++i < ball_count);

	BallStatuses_SendBalls_func();
}

void kaball_Handler_CheckBall(entity this, IntrusiveList ball_list,
	void() RemoveBalls_func, void() SpawnBalls_func)
{
	if (time < game_starttime)
	{
		if (!IL_EMPTY(ball_list))
			RemoveBalls_func();
	}
	else
	{
		if (IL_EMPTY(ball_list))
			SpawnBalls_func(); // ;)
	}

	this.nextthink = time;
}
