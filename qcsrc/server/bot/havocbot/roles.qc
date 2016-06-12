#include "roles.qh"

#include "havocbot.qh"

#include "../bot.qh"
#include "../navigation.qh"

.float max_armorvalue;
.float havocbot_role_timeout;

.void(entity this) havocbot_previous_role;
.void(entity this) havocbot_role;

void havocbot_goalrating_items(entity this, float ratingscale, vector org, float sradius)
{
	entity head;
	float rating, d, discard, distance, friend_distance, enemy_distance;
	vector o;
	ratingscale = ratingscale * 0.0001; // items are rated around 10000 already
	head = findchainfloat(bot_pickup, true);

	while (head)
	{
		o = (head.absmin + head.absmax) * 0.5;
		distance = vlen(o - org);
		friend_distance = 10000; enemy_distance = 10000;
		rating = 0;

		if(!head.solid || distance > sradius || (head == this.ignoregoal && time < this.ignoregoaltime) )
		{
			head = head.chain;
			continue;
		}

		// Check if the item can be picked up safely
		if(head.classname == "droppedweapon")
		{
			traceline(o, o + '0 0 -1500', true, world);

			d = pointcontents(trace_endpos + '0 0 1');
			if(d & CONTENT_WATER || d & CONTENT_SLIME || d & CONTENT_LAVA)
			{
				head = head.chain;
				continue;
			}
			if(tracebox_hits_trigger_hurt(head.origin, head.mins, head.maxs, trace_endpos))
			{
				head = head.chain;
				continue;
			}
		}
		else
		{
			// Ignore items under water
			traceline(head.origin + head.maxs, head.origin + head.maxs, MOVE_NORMAL, head);
			if(trace_dpstartcontents & DPCONTENTS_LIQUIDSMASK)
			{
				head = head.chain;
				continue;
			}
		}

		if(teamplay)
		{
			discard = false;

			FOREACH_CLIENT(IS_PLAYER(it) && it != this && !IS_DEAD(it), LAMBDA(
				d = vlen(it.origin - o); // distance between player and item

				if ( it.team == this.team )
				{
					if ( !IS_REAL_CLIENT(it) || discard )
						continue;

					if( d > friend_distance)
						continue;

					friend_distance = d;

					discard = true;

					if( head.health && it.health > this.health )
						continue;

					if( head.armorvalue && it.armorvalue > this.armorvalue)
						continue;

					if( head.weapons )
					if( head.weapons & ~it.weapons )
						continue;

					if (head.ammo_shells && it.ammo_shells > this.ammo_shells)
						continue;

					if (head.ammo_nails && it.ammo_nails > this.ammo_nails)
						continue;

					if (head.ammo_rockets && it.ammo_rockets > this.ammo_rockets)
						continue;

					if (head.ammo_cells && it.ammo_cells > this.ammo_cells)
						continue;

					if (head.ammo_plasma && it.ammo_plasma > this.ammo_plasma)
						continue;

					discard = false;
				}
				else
				{
					// If enemy only track distances
					// TODO: track only if visible ?
					if( d < enemy_distance )
						enemy_distance = d;
				}
			));

			// Rate the item only if no one needs it, or if an enemy is closer to it
			if ( (enemy_distance < friend_distance && distance < enemy_distance) ||
				(friend_distance > autocvar_bot_ai_friends_aware_pickup_radius ) || !discard )
				rating = head.bot_pickupevalfunc(this, head);

		}
		else
			rating = head.bot_pickupevalfunc(this, head);

		if(rating > 0)
			navigation_routerating(this, head, rating * ratingscale, 2000);
		head = head.chain;
	}
}

void havocbot_goalrating_controlpoints(entity this, float ratingscale, vector org, float sradius)
{
	entity head;
	head = findchain(classname, "dom_controlpoint");
	while (head)
	{
		if(vdist((((head.absmin + head.absmax) * 0.5) - org), <, sradius))
		{
			if(head.cnt > -1) // this is just being fought for
				navigation_routerating(this, head, ratingscale, 5000);
			else if(head.goalentity.cnt == 0) // unclaimed point
				navigation_routerating(this, head, ratingscale * 0.5, 5000);
			else if(head.goalentity.team != this.team) // other team's point
				navigation_routerating(this, head, ratingscale * 0.2, 5000);
		}
		head = head.chain;
	}
}

void havocbot_goalrating_enemyplayers(entity this, float ratingscale, vector org, float sradius)
{
	if (autocvar_bot_nofire)
		return;

	// don't chase players if we're under water
	if(this.waterlevel>WATERLEVEL_WETFEET)
		return;

	int t;

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

		if((it.flags & FL_INWATER) || (it.flags & FL_PARTIALGROUND))
			continue;

		// not falling
		if((IS_ONGROUND(it)) == 0)
		{
			traceline(it.origin, it.origin + '0 0 -1500', true, world);
			t = pointcontents(trace_endpos + '0 0 1');
			if(t != CONTENT_SOLID )
			if(t & CONTENT_WATER || t & CONTENT_SLIME || t & CONTENT_LAVA)
				continue;
			if(tracebox_hits_trigger_hurt(it.origin, it.mins, it.maxs, trace_endpos))
				continue;
		}

		// TODO: rate waypoints near the targetted player at that moment, instead of the player itthis
		//		 adding a player as a goal seems to be quite dangerous, especially on space maps
		//		 remove hack in navigation_poptouchedgoals() after performing this change

		t = (this.health + this.armorvalue ) / (it.health + it.armorvalue );
		navigation_routerating(this, it, t * ratingscale, 2000);
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
		//havocbot_goalrating_waypoints(1, this.origin, 1000);
		navigation_goalrating_end(this);
	}
}

void havocbot_chooserole_generic(entity this)
{
	this.havocbot_role = havocbot_role_generic;
}

void havocbot_chooserole(entity this)
{
	LOG_TRACE("choosing a role...\n");
	this.bot_strategytime = 0;
	if(!MUTATOR_CALLHOOK(HavocBot_ChooseRole, this))
		havocbot_chooserole_generic(this);
}
