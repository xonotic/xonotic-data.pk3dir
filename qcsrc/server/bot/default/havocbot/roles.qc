#include "roles.qh"

#include <server/defs.qh>
#include <server/miscfunctions.qh>
#include <server/items.qh>
#include <server/resources.qh>
#include "havocbot.qh"

#include "../cvars.qh"

#include "../bot.qh"
#include "../navigation.qh"

.float bot_ratingscale;
.float bot_ratingscale_time;
.float max_armorvalue;
.float havocbot_role_timeout;

.void(entity this) havocbot_previous_role;
.void(entity this) havocbot_role;

void havocbot_goalrating_waypoints(entity this, float ratingscale, vector org, float sradius)
{
	// rate waypoints only if there's no alternative goal
	if(navigation_bestgoal)
		return;

	float f;
	float range = 500;
	sradius = max(range, (0.5 + random() * 0.5) * sradius);
	while(sradius > 100)
	{
		IL_EACH(g_waypoints, vdist(it.origin - org, <, sradius)
			&& vdist(it.origin - org, >, max(100, sradius - range))
			&& !(it.wpflags & WAYPOINTFLAG_TELEPORT),
		{
			if(vdist(it.origin - this.wp_goal_prev0.origin, <, range * 1.5))
				f = 0.1;
			else if(vdist(it.origin - this.wp_goal_prev1.origin, <, range * 1.5))
				f = 0.1;
			else
				f = 0.5 + random() * 0.5;
			navigation_routerating(this, it, ratingscale * f, 2000);
		});
		if(navigation_bestgoal)
			break;
		sradius -= range;
	}
};

bool havocbot_goalrating_item_can_be_left_to_teammate(entity this, entity player, entity item)
{
	if (GetResource(item, RES_HEALTH) && GetResource(player, RES_HEALTH) <= GetResource(this, RES_HEALTH)) {return true;}
	if (GetResource(item, RES_ARMOR) && GetResource(player, RES_ARMOR) <= GetResource(this, RES_ARMOR)) {return true;}
	if (STAT(WEAPONS, item) && !(STAT(WEAPONS, player) & STAT(WEAPONS, item))) {return true;}
	if (GetResource(item, RES_SHELLS) && GetResource(player, RES_SHELLS) <= GetResource(this, RES_SHELLS)) {return true;}
	if (GetResource(item, RES_BULLETS) && GetResource(player, RES_BULLETS) <= GetResource(this, RES_BULLETS)) {return true;}
	if (GetResource(item, RES_ROCKETS) && GetResource(player, RES_ROCKETS) <= GetResource(this, RES_ROCKETS)) {return true;}
	if (GetResource(item, RES_CELLS) && GetResource(player, RES_CELLS) <= GetResource(this, RES_CELLS)) {return true;}
	if (GetResource(item, RES_PLASMA) && GetResource(player, RES_PLASMA) <= GetResource(this, RES_PLASMA)) {return true;}
	if (item.itemdef.instanceOfPowerup) {return true;}

	return false;
};

bool havocbot_goalrating_item_pickable_check_players(entity this, vector org, entity item, vector item_org)
{
	if(!teamplay)
		return true;

	// actually these variables hold the squared distances in order to optimize code
	float friend_distance = FLOAT_MAX;
	float enemy_distance = FLOAT_MAX;
	float dist;

	FOREACH_CLIENT(IS_PLAYER(it) && it != this && !(IS_DEAD(it) || STAT(FROZEN, it)),
	{
		if (it.team == this.team)
		{
			if (!IS_REAL_CLIENT(it))
				continue;

			dist = vlen2(it.origin - item_org);
			if(dist > friend_distance)
				continue;

			if(havocbot_goalrating_item_can_be_left_to_teammate(this, it, item))
			{
				friend_distance = dist;
				continue;
			}
		}
		else
		{
			// If enemy only track distances
			// TODO: track only if visible ?
			dist = vlen2(it.origin - item_org);
			if(dist < enemy_distance)
				enemy_distance = dist;
		}
	});

	// Rate the item only if no one needs it, or if an enemy is closer to it
	dist = vlen2(item_org - org);
	if ((enemy_distance < friend_distance && dist < enemy_distance) ||
		(friend_distance > autocvar_bot_ai_friends_aware_pickup_radius ** 2) ||
		(dist < friend_distance && dist < 200 ** 2))
		return true;
	return false;
};

void havocbot_goalrating_items(entity this, float ratingscale, vector org, float sradius)
{
	float rating;
	vector o;
	ratingscale = ratingscale * 0.0001;

	IL_EACH(g_items, it.bot_pickup,
	{
		// ignore if bot already rated this item with a higher ratingscale
		// NOTE: this code assumes each bot rates items in a different frame
		if(it.bot_ratingscale_time == time && ratingscale < it.bot_ratingscale)
			continue;

		if(!it.solid)
		{
			if(!autocvar_bot_ai_timeitems)
				continue;
			if(!it.scheduledrespawntime)
				continue;
			if(it.respawntime < max(11, autocvar_bot_ai_timeitems_minrespawndelay))
				continue;
			if(it.respawntimejitter && !it.itemdef.instanceOfPowerup)
				continue;

			float t = 0;
			if(it.itemdef.instanceOfPowerup)
				t = bound(0, skill / 10, 1) * 6;
			else if(skill >= 9)
				t = 4;

			if(time < it.scheduledrespawntime - t)
				continue;

			it.bot_pickup_respawning = true;
		}
		o = (it.absmin + it.absmax) * 0.5;
		if(vdist(o - org, >, sradius) || (it == this.ignoregoal && time < this.ignoregoaltime) )
			continue;

		// Check if the item can be picked up safely
		if(Item_IsLoot(it))
		{
			if(!IS_ONGROUND(it))
				continue;
			traceline(o, o + '0 0 -1500', true, NULL);

			if(IN_LAVA(trace_endpos + '0 0 1'))
				continue;

			// this tracebox_hits_trigger_hurt call isn't needed:
			// dropped weapons are removed as soon as they fall on a trigger_hurt
			// and can't be rated while they are in the air
			//if(tracebox_hits_trigger_hurt(it.origin, it.mins, it.maxs, trace_endpos))
			//	continue;
		}
		else
		{
			if(IN_LAVA(it.origin + (it.mins + it.maxs) * 0.5))
				continue;
		}

		if(!havocbot_goalrating_item_pickable_check_players(this, org, it, o))
			continue;

		it.bot_ratingscale_time = time;
		it.bot_ratingscale = ratingscale;
		rating = it.bot_pickupevalfunc(this, it);
		if(rating > 0)
			navigation_routerating(this, it, rating * ratingscale, 2000);
	});
}

#define BOT_RATING_ENEMY 2500
void havocbot_goalrating_enemyplayers(entity this, float ratingscale, vector org, float sradius)
{
	if (autocvar_bot_nofire)
		return;

	// don't chase players if we're under water
	if(this.waterlevel>WATERLEVEL_WETFEET)
		return;

	ratingscale = ratingscale * 0.0001;

	float t;
	FOREACH_CLIENT(IS_PLAYER(it) && bot_shouldattack(this, it), {
		// TODO: Merge this logic with the bot_shouldattack function
		if(vdist(it.origin - org, <, 100) || vdist(it.origin - org, >, sradius))
			continue;
		if(vdist(vec2(it.velocity), >, autocvar_sv_maxspeed * 2))
			continue;

		// rate only visible enemies
		/*
		traceline(this.origin + this.view_ofs, it.origin, MOVE_NOMONSTERS, this);
		if (trace_fraction < 1 || trace_ent != it)
			continue;
		*/

		t = ((GetResource(this, RES_HEALTH) + GetResource(this, RES_ARMOR)) - (GetResource(it, RES_HEALTH) + GetResource(it, RES_ARMOR))) / 150;
		t = bound(0, 1 + t, 3);
		if (skill > 3)
		{
			if (time < this.strength_finished - 1) t += 0.5;
			if (time < it.strength_finished - 1) t -= 0.5;
			if (time < this.invincible_finished - 1) t += 0.2;
			if (time < it.invincible_finished - 1) t -= 0.4;
		}
		t += max(0, 8 - skill) * 0.05; // less skilled bots attack more mindlessly
		ratingscale *= t;
		if (ratingscale > 0)
			navigation_routerating(this, it, ratingscale * BOT_RATING_ENEMY, 2000);
	});
}

// legacy bot role for standard gamemodes
// go to best items
void havocbot_role_generic(entity this)
{
	if(IS_DEAD(this))
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
}

void havocbot_chooserole_generic(entity this)
{
	this.havocbot_role = havocbot_role_generic;
}

void havocbot_chooserole(entity this)
{
	LOG_TRACE("choosing a role...");
	navigation_goalrating_timeout_force(this);
	if(!MUTATOR_CALLHOOK(HavocBot_ChooseRole, this))
		havocbot_chooserole_generic(this);
}
