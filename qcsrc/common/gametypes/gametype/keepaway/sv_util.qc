#include "sv_util.qh"

#include "sv_ball.qh"

#include <common/mutators/base.qh>
#include <common/mutators/mutator/waypoints/waypointsprites.qh>


// Mutator hook functions

/// Field where the decimal part of SCORE is accumulated (shared with other gametypes)
.float float2int_decimal_fld;
bool ka_util_reset_map_global()
{
	FOREACH_CLIENT(true, it.float2int_decimal_fld = 0);
	return true;
}

bool ka_util_GiveFragsForKill()
{
	M_ARGV(2, float) = 0; // no frags counted in keepaway
	return true; // you deceptive little bugger ;3 This needs to be true in order for this function to even count.
}

bool ka_util_PlayerUseKey(void(entity) DropEvent_func, void() BallStatuses_SendBalls_func)
{
	entity player = M_ARGV(0, entity);

	if (MUTATOR_RETURNVALUE == 0
	&& player.ballcarried)
	{
		DropEvent_func(player);
		BallStatuses_SendBalls_func();
		return true;
	}
	return false;
}

void ka_util_Damage_Calculate(vector carrier_damage, vector carrier_force, vector noncarrier_damage, vector noncarrier_force)
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
			M_ARGV(4, float) *= carrier_damage.x;
			M_ARGV(6, vector) *= carrier_force.x;
		}
		else if (frag_target.ballcarried) // damage done to other ballcarriers
		{
			M_ARGV(4, float) *= carrier_damage.y;
			M_ARGV(6, vector) *= carrier_force.y;
		}
		else // damage done to noncarriers
		{
			M_ARGV(4, float) *= carrier_damage.z;
			M_ARGV(6, vector) *= carrier_force.z;
		}
	}
	else
	{
		if (frag_target == frag_attacker) // damage done to themselves
		{
			M_ARGV(4, float) *= noncarrier_damage.x;
			M_ARGV(6, vector) *= noncarrier_force.x;
		}
		else if (frag_target.ballcarried) // damage done to ballcarriers
		{
			M_ARGV(4, float) *= noncarrier_damage.y;
			M_ARGV(6, vector) *= noncarrier_force.y;
		}
		else // damage done to other noncarriers
		{
			M_ARGV(4, float) *= noncarrier_damage.z;
			M_ARGV(6, vector) *= noncarrier_force.z;
		}
	}
}

void ka_util_ClientDisconnect(void(entity) DropPlayersBalls_func)
{
	entity player = M_ARGV(0, entity);

	if (player.ballcarried)
		DropPlayersBalls_func(player); // a player with ball(s) has left the match, drop them
}

void ka_util_MakePlayerObserver(void(entity) DropPlayersBalls_func)
{
	entity player = M_ARGV(0, entity);

	if (player.ballcarried)
		DropPlayersBalls_func(player); // a player with ball(s) has left the match, drop them
}

void ka_util_PlayerPhysics_UpdateStats(float highspeed)
{
	entity player = M_ARGV(0, entity);
	// these automatically reset, no need to worry

	if (player.ballcarried)
		STAT(MOVEVARS_HIGHSPEED, player) *= highspeed;
}

bool ka_util_HavocBot_ChooseRole(void(entity) havocbot_role_carrier_func, void(entity) havocbot_role_collector_func)
{
	entity bot = M_ARGV(0, entity);

	if (bot.ballcarried)
		bot.havocbot_role = havocbot_role_carrier_func;
	else
		bot.havocbot_role = havocbot_role_collector_func;
	return true;
}

void ka_util_DropSpecialItems(void(entity) DropPlayersBalls_func)
{
	entity frag_target = M_ARGV(0, entity);

	if (frag_target.ballcarried)
		DropPlayersBalls_func(frag_target);
}

bool ka_util_PreferPlayerScore_Clear()
{
	return true;
}


// Bot functions

bool ka_util_waypointsprite_visible_for_bot(entity this, entity e, bool dropped)
{
	entity ball_wp = e.waypointsprite_attachedforcarrier;
	if (!ball_wp // has no waypoint
	&& (dropped || !ball_wp.waypointsprite_visible_for_player(ball_wp, this, WaypointSprite_getviewentity(this))) // waypoint not visible
	&& !checkpvs(this.origin + this.view_ofs, e)) // ball cannot be seen
		return false;

	return true;
}

void ka_util_havocbot_goalrating_ball(entity this, void(entity, entity, entity, float, float) returns,
	IntrusiveList ball_list, float ratingscale, float ratingscale_sameteam, vector org)
{
	entity ball = NULL, ball_carried = NULL;

	// stops at last ball, prefers ball without carrier
	IL_EACH(ball_list, it.owner != this,
	{
		if (it.owner)
		{
			if (!ka_util_waypointsprite_visible_for_bot(this, it.owner, false))
				continue;
			ball_carried = it.owner;
		}
		else
		{
			if (!ka_util_waypointsprite_visible_for_bot(this, it, true))
				continue;
			ball = it;
		}
	});

	returns(this, ball, ball_carried, ratingscale, ratingscale_sameteam);
}

void ka_util_havocbot_role_carrier(entity this, void(entity) havocbot_role_collector_func)
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

void ka_util_havocbot_role_collector(entity this, void(entity, float, float, vector) havocbot_goalrating_func, void(entity) havocbot_role_carrier_func)
{
	if (IS_DEAD(this))
		return;

	if (navigation_goalrating_timeout(this))
	{
		navigation_goalrating_start(this);
		havocbot_goalrating_items(this, 10000, this.origin, 10000);
		havocbot_goalrating_enemyplayers(this, 500, this.origin, 10000);
		havocbot_goalrating_func(this, 8000, 4000, this.origin);
		navigation_goalrating_end(this);

		navigation_goalrating_timeout_set(this);
	}

	if (this.ballcarried)
	{
		this.havocbot_role = havocbot_role_carrier_func;
		navigation_goalrating_timeout_expire(this, 2);
	}
}
