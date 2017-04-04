#include "roles.qh"

#include "havocbot.qh"

#include "../cvars.qh"

#include "../bot.qh"
#include "../navigation.qh"

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

void havocbot_goalrating_items(entity this, float ratingscale, vector org, float sradius)
{
	float rating, d, discard, friend_distance, enemy_distance;
	vector o;
	ratingscale = ratingscale * 0.0001; // items are rated around 10000 already

	IL_EACH(g_items, it.bot_pickup,
	{
		rating = 0;

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
		if(it.classname == "droppedweapon")
		{
			if(!IS_ONGROUND(it))
				continue;
			traceline(o, o + '0 0 -1500', true, NULL);

			d = pointcontents(trace_endpos + '0 0 1');
			if(d == CONTENT_WATER || d == CONTENT_SLIME || d == CONTENT_LAVA)
				continue;
			// this tracebox_hits_trigger_hurt call isn't needed:
			// dropped weapons are removed as soon as they fall on a trigger_hurt
			// and can't be rated while they are in the air
			//if(tracebox_hits_trigger_hurt(it.origin, it.mins, it.maxs, trace_endpos))
			//	continue;
		}
		else
		{
			// Ignore items under water
			traceline(it.origin + it.maxs, it.origin + it.maxs, MOVE_NORMAL, it);
			if(trace_dpstartcontents & DPCONTENTS_LIQUIDSMASK)
				continue;
		}

		if(teamplay)
		{
			friend_distance = 10000; enemy_distance = 10000;
			discard = false;

			entity picker = it;
			FOREACH_CLIENT(IS_PLAYER(it) && it != this && !IS_DEAD(it),
			{
				d = vlen(it.origin - o); // distance between player and item

				if ( it.team == this.team )
				{
					if ( !IS_REAL_CLIENT(it) || discard )
						continue;

					if( d > friend_distance)
						continue;

					friend_distance = d;
					discard = true;

					if (picker.health && it.health > this.health) continue;
					if (picker.armorvalue && it.armorvalue > this.armorvalue) continue;

					if (picker.weapons && (picker.weapons & ~it.weapons)) continue;

					if (picker.ammo_shells && it.ammo_shells > this.ammo_shells) continue;
					if (picker.ammo_nails && it.ammo_nails > this.ammo_nails) continue;
					if (picker.ammo_rockets && it.ammo_rockets > this.ammo_rockets) continue;
					if (picker.ammo_cells && it.ammo_cells > this.ammo_cells) continue;
					if (picker.ammo_plasma && it.ammo_plasma > this.ammo_plasma) continue;

					discard = false;
				}
				else
				{
					// If enemy only track distances
					// TODO: track only if visible ?
					if( d < enemy_distance )
						enemy_distance = d;
				}
			});

			// Rate the item only if no one needs it, or if an enemy is closer to it
			if ( (enemy_distance < friend_distance && vdist(o - org, <, enemy_distance)) ||
				(friend_distance > autocvar_bot_ai_friends_aware_pickup_radius ) || !discard )
				rating = it.bot_pickupevalfunc(this, it);
		}
		else
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

	ratingscale = ratingscale * 0.00005; // enemies are rated around 20000 already

	float t;
	FOREACH_CLIENT(IS_PLAYER(it) && bot_shouldattack(this, it), LAMBDA(
		// TODO: Merge this logic with the bot_shouldattack function
		if(vdist(it.origin - org, <, 100) || vdist(it.origin - org, >, sradius))
			continue;

		// rate only visible enemies
		/*
		traceline(this.origin + this.view_ofs, it.origin, MOVE_NOMONSTERS, this);
		if (trace_fraction < 1 || trace_ent != it)
			continue;
		*/

		t = ((this.health + this.armorvalue) - (it.health + it.armorvalue)) / 150;
		t = bound(0, 1 + t, 3);
		if (skill > 3)
		{
			if (time < this.strength_finished - 1) t += 0.5;
			if (time < it.strength_finished - 1) t -= 0.5;
		}
		t += max(0, 8 - skill) * 0.05; // less skilled bots attack more mindlessly
		ratingscale *= t;
		if (ratingscale > 0)
			navigation_routerating(this, it, ratingscale * BOT_RATING_ENEMY, 2000);
	));
}

// legacy bot role for standard gamemodes
// go to best items
void havocbot_role_generic(entity this)
{
	if(IS_DEAD(this))
		return;

	if (this.bot_strategytime < time)
	{
		this.bot_strategytime = time + autocvar_bot_ai_strategyinterval;
		navigation_goalrating_start(this);
		havocbot_goalrating_items(this, 10000, this.origin, 10000);
		havocbot_goalrating_enemyplayers(this, 20000, this.origin, 10000);
		havocbot_goalrating_waypoints(this, 1, this.origin, 3000);
		navigation_goalrating_end(this);

		if(IS_PLAYER(this.goalentity))
			this.bot_strategytime = time + min(2, autocvar_bot_ai_strategyinterval);
	}
}

void havocbot_chooserole_generic(entity this)
{
	this.havocbot_role = havocbot_role_generic;
}

void havocbot_chooserole(entity this)
{
	LOG_TRACE("choosing a role...");
	this.bot_strategytime = 0;
	if(!MUTATOR_CALLHOOK(HavocBot_ChooseRole, this))
		havocbot_chooserole_generic(this);
}
