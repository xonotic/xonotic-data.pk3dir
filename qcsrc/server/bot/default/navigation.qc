#include "navigation.qh"

#include "cvars.qh"

#include "bot.qh"
#include "waypoints.qh"

#include <common/t_items.qh>

#include <common/items/_mod.qh>

#include <common/constants.qh>
#include <common/net_linked.qh>
#include <common/triggers/trigger/jumppads.qh>

.float speed;

void navigation_dynamicgoal_init(entity this, bool initially_static)
{
	this.navigation_dynamicgoal = true;
	this.bot_basewaypoint = this.nearestwaypoint;
	if(initially_static)
		this.nearestwaypointtimeout = -1;
	else
		this.nearestwaypointtimeout = time;
}

void navigation_dynamicgoal_set(entity this)
{
	this.nearestwaypointtimeout = time;
}

void navigation_dynamicgoal_unset(entity this)
{
	if(this.bot_basewaypoint)
		this.nearestwaypoint = this.bot_basewaypoint;
	this.nearestwaypointtimeout = -1;
}

// rough simulation of walking from one point to another to test if a path
// can be traveled, used for waypoint linking and havocbot

bool tracewalk(entity e, vector start, vector m1, vector m2, vector end, float movemode)
{
	vector org;
	vector move;
	vector dir;
	float dist;
	float totaldist;
	float stepdist;
	float ignorehazards;
	float swimming;
	entity tw_ladder = NULL;

	if(autocvar_bot_debug_tracewalk)
	{
		debugresetnodes();
		debugnode(e, start);
	}

	move = end - start;
	move.z = 0;
	org = start;
	dist = totaldist = vlen(move);
	dir = normalize(move);
	stepdist = 32;
	ignorehazards = false;
	swimming = false;

	// Analyze starting point
	traceline(start, start, MOVE_NORMAL, e);
	if (trace_dpstartcontents & (DPCONTENTS_SLIME | DPCONTENTS_LAVA))
		ignorehazards = true;
	else
	{
		traceline( start, start + '0 0 -65536', MOVE_NORMAL, e);
		if (trace_dpstartcontents & (DPCONTENTS_SLIME | DPCONTENTS_LAVA))
		{
			ignorehazards = true;
			swimming = true;
		}
	}
	tracebox(start, m1, m2, start, MOVE_NOMONSTERS, e);
	if (trace_startsolid)
	{
		// Bad start
		if(autocvar_bot_debug_tracewalk)
			debugnodestatus(start, DEBUG_NODE_FAIL);

		//print("tracewalk: ", vtos(start), " is a bad start\n");
		return false;
	}

	// Movement loop
	move = end - org;
	for (;;)
	{
		if (boxesoverlap(end, end, org + m1 + '-1 -1 -1', org + m2 + '1 1 1'))
		{
			// Succeeded
			if(autocvar_bot_debug_tracewalk)
				debugnodestatus(org, DEBUG_NODE_SUCCESS);

			//print("tracewalk: ", vtos(start), " can reach ", vtos(end), "\n");
			return true;
		}
		if(autocvar_bot_debug_tracewalk)
			debugnode(e, org);

		if (dist <= 0)
			break;
		if (stepdist > dist)
			stepdist = dist;
		dist = dist - stepdist;
		traceline(org, org, MOVE_NORMAL, e);
		if (!ignorehazards)
		{
			if (trace_dpstartcontents & (DPCONTENTS_SLIME | DPCONTENTS_LAVA))
			{
				// hazards blocking path
				if(autocvar_bot_debug_tracewalk)
					debugnodestatus(org, DEBUG_NODE_FAIL);

				//print("tracewalk: ", vtos(start), " hits a hazard when trying to reach ", vtos(end), "\n");
				return false;
			}
		}
		if (trace_dpstartcontents & DPCONTENTS_LIQUIDSMASK)
		{
			move = normalize(end - org);
			tracebox(org, m1, m2, org + move * stepdist, movemode, e);

			if(autocvar_bot_debug_tracewalk)
				debugnode(e, trace_endpos);

			if (trace_fraction < 1)
			{
				swimming = true;
				org = trace_endpos - normalize(org - trace_endpos) * stepdist;
				for (; org.z < end.z + e.maxs.z; org.z += stepdist)
				{
					if(autocvar_bot_debug_tracewalk)
						debugnode(e, org);

					if(pointcontents(org) == CONTENT_EMPTY)
						break;
				}

				if(pointcontents(org + '0 0 1') != CONTENT_EMPTY)
				{
					if(autocvar_bot_debug_tracewalk)
						debugnodestatus(org, DEBUG_NODE_FAIL);

					return false;
					//print("tracewalk: ", vtos(start), " failed under water\n");
				}
				continue;

			}
			else
				org = trace_endpos;
		}
		else
		{
			move = dir * stepdist + org;
			tracebox(org, m1, m2, move, movemode, e);

			if(autocvar_bot_debug_tracewalk)
				debugnode(e, trace_endpos);

			// hit something
			if (trace_fraction < 1)
			{
				// check if we can walk over this obstacle, possibly by jumpstepping
				tracebox(org + stepheightvec, m1, m2, move + stepheightvec, movemode, e);
				if (trace_fraction < 1 || trace_startsolid)
				{
					tracebox(org + jumpstepheightvec, m1, m2, move + jumpstepheightvec, movemode, e);
					if (trace_fraction < 1 || trace_startsolid)
					{
						if(autocvar_bot_debug_tracewalk)
							debugnodestatus(trace_endpos, DEBUG_NODE_WARNING);

						FOREACH_ENTITY_CLASS("func_ladder", true,
							{ it.solid = SOLID_BSP; });

						traceline( org, move, movemode, e);

						FOREACH_ENTITY_CLASS("func_ladder", true,
							{ it.solid = SOLID_TRIGGER; });

						if ( trace_ent.classname == "door_rotating" || trace_ent.classname == "door")
						{
							vector nextmove;
							move = trace_endpos;
							while(trace_ent.classname == "door_rotating" || trace_ent.classname == "door")
							{
								nextmove = move + (dir * stepdist);
								traceline( move, nextmove, movemode, e);
								move = nextmove;
							}
						}
						else if (trace_ent.classname == "func_ladder")
						{
							tw_ladder = trace_ent;
							vector ladder_bottom = trace_endpos - dir * m2.x;
							vector ladder_top = ladder_bottom;
							ladder_top.z = trace_ent.absmax.z + (-m1.z + 1);
							tracebox(ladder_bottom, m1, m2, ladder_top, movemode, e);
							if (trace_fraction < 1 || trace_startsolid)
							{
								if(autocvar_bot_debug_tracewalk)
									debugnodestatus(trace_endpos, DEBUG_NODE_FAIL);

								return false; // failed
							}
							org = ladder_top + dir * m2.x;
							move = org + dir * stepdist;
							continue;
						}
						else
						{
							if(autocvar_bot_debug_tracewalk)
								debugnodestatus(trace_endpos, DEBUG_NODE_FAIL);

							//print("tracewalk: ", vtos(start), " hit something when trying to reach ", vtos(end), "\n");
							//te_explosion(trace_endpos);
							//print(ftos(e.dphitcontentsmask), "\n");
							return false; // failed
						}
					}
					else
						move = trace_endpos;
				}
				else
					move = trace_endpos;
			}
			else
				move = trace_endpos;

			// trace down from stepheight as far as possible and move there,
			// if this starts in solid we try again without the stepup, and
			// if that also fails we assume it is a wall
			// (this is the same logic as the Quake walkmove function used)
			tracebox(move, m1, m2, move + '0 0 -65536', movemode, e);

			// moved successfully
			if(swimming)
			{
				float c;
				c = pointcontents(org + '0 0 1');
				if (!(c == CONTENT_WATER || c == CONTENT_LAVA || c == CONTENT_SLIME))
					swimming = false;
				else
					continue;
			}

			org = trace_endpos;
		}

		if(tw_ladder && org.z < tw_ladder.absmax.z)
		{
			// stop tracewalk if destination height is lower than the top of the ladder
			// otherwise bot can't easily figure out climbing direction
			if(autocvar_bot_debug_tracewalk)
				debugnodestatus(org, DEBUG_NODE_FAIL);

			return false;
		}
	}

	//print("tracewalk: ", vtos(start), " did not arrive at ", vtos(end), " but at ", vtos(org), "\n");

	// moved but didn't arrive at the intended destination
	if(autocvar_bot_debug_tracewalk)
		debugnodestatus(org, DEBUG_NODE_FAIL);

	return false;
}

/////////////////////////////////////////////////////////////////////////////
// goal stack
/////////////////////////////////////////////////////////////////////////////

// completely empty the goal stack, used when deciding where to go
void navigation_clearroute(entity this)
{
	//print("bot ", etos(this), " clear\n");
	this.goalentity = NULL;
	this.goalcurrent = NULL;
	this.goalstack01 = NULL;
	this.goalstack02 = NULL;
	this.goalstack03 = NULL;
	this.goalstack04 = NULL;
	this.goalstack05 = NULL;
	this.goalstack06 = NULL;
	this.goalstack07 = NULL;
	this.goalstack08 = NULL;
	this.goalstack09 = NULL;
	this.goalstack10 = NULL;
	this.goalstack11 = NULL;
	this.goalstack12 = NULL;
	this.goalstack13 = NULL;
	this.goalstack14 = NULL;
	this.goalstack15 = NULL;
	this.goalstack16 = NULL;
	this.goalstack17 = NULL;
	this.goalstack18 = NULL;
	this.goalstack19 = NULL;
	this.goalstack20 = NULL;
	this.goalstack21 = NULL;
	this.goalstack22 = NULL;
	this.goalstack23 = NULL;
	this.goalstack24 = NULL;
	this.goalstack25 = NULL;
	this.goalstack26 = NULL;
	this.goalstack27 = NULL;
	this.goalstack28 = NULL;
	this.goalstack29 = NULL;
	this.goalstack30 = NULL;
	this.goalstack31 = NULL;
}

// add a new goal at the beginning of the stack
// (in other words: add a new prerequisite before going to the later goals)
// NOTE: when a waypoint is added, the WP gets pushed first, then the
// next-closest WP on the shortest path to the WP
// That means, if the stack overflows, the bot will know how to do the FIRST 32
// steps to the goal, and then recalculate the path.
void navigation_pushroute(entity this, entity e)
{
	//print("bot ", etos(this), " push ", etos(e), "\n");
	if(this.goalstack31 == this.goalentity)
		this.goalentity = NULL;
	this.goalstack31 = this.goalstack30;
	this.goalstack30 = this.goalstack29;
	this.goalstack29 = this.goalstack28;
	this.goalstack28 = this.goalstack27;
	this.goalstack27 = this.goalstack26;
	this.goalstack26 = this.goalstack25;
	this.goalstack25 = this.goalstack24;
	this.goalstack24 = this.goalstack23;
	this.goalstack23 = this.goalstack22;
	this.goalstack22 = this.goalstack21;
	this.goalstack21 = this.goalstack20;
	this.goalstack20 = this.goalstack19;
	this.goalstack19 = this.goalstack18;
	this.goalstack18 = this.goalstack17;
	this.goalstack17 = this.goalstack16;
	this.goalstack16 = this.goalstack15;
	this.goalstack15 = this.goalstack14;
	this.goalstack14 = this.goalstack13;
	this.goalstack13 = this.goalstack12;
	this.goalstack12 = this.goalstack11;
	this.goalstack11 = this.goalstack10;
	this.goalstack10 = this.goalstack09;
	this.goalstack09 = this.goalstack08;
	this.goalstack08 = this.goalstack07;
	this.goalstack07 = this.goalstack06;
	this.goalstack06 = this.goalstack05;
	this.goalstack05 = this.goalstack04;
	this.goalstack04 = this.goalstack03;
	this.goalstack03 = this.goalstack02;
	this.goalstack02 = this.goalstack01;
	this.goalstack01 = this.goalcurrent;
	this.goalcurrent = e;
}

// remove first goal from stack
// (in other words: remove a prerequisite for reaching the later goals)
// (used when a spawnfunc_waypoint is reached)
void navigation_poproute(entity this)
{
	//print("bot ", etos(this), " pop\n");
	if(this.goalcurrent == this.goalentity)
		this.goalentity = NULL;
	this.goalcurrent = this.goalstack01;
	this.goalstack01 = this.goalstack02;
	this.goalstack02 = this.goalstack03;
	this.goalstack03 = this.goalstack04;
	this.goalstack04 = this.goalstack05;
	this.goalstack05 = this.goalstack06;
	this.goalstack06 = this.goalstack07;
	this.goalstack07 = this.goalstack08;
	this.goalstack08 = this.goalstack09;
	this.goalstack09 = this.goalstack10;
	this.goalstack10 = this.goalstack11;
	this.goalstack11 = this.goalstack12;
	this.goalstack12 = this.goalstack13;
	this.goalstack13 = this.goalstack14;
	this.goalstack14 = this.goalstack15;
	this.goalstack15 = this.goalstack16;
	this.goalstack16 = this.goalstack17;
	this.goalstack17 = this.goalstack18;
	this.goalstack18 = this.goalstack19;
	this.goalstack19 = this.goalstack20;
	this.goalstack20 = this.goalstack21;
	this.goalstack21 = this.goalstack22;
	this.goalstack22 = this.goalstack23;
	this.goalstack23 = this.goalstack24;
	this.goalstack24 = this.goalstack25;
	this.goalstack25 = this.goalstack26;
	this.goalstack26 = this.goalstack27;
	this.goalstack27 = this.goalstack28;
	this.goalstack28 = this.goalstack29;
	this.goalstack29 = this.goalstack30;
	this.goalstack30 = this.goalstack31;
	this.goalstack31 = NULL;
}

float navigation_waypoint_will_link(vector v, vector org, entity ent, float walkfromwp, float bestdist)
{
	float dist;
	dist = vlen(v - org);
	if (bestdist > dist)
	{
		traceline(v, org, true, ent);
		if (trace_fraction == 1)
		{
			if (walkfromwp)
			{
				if (tracewalk(ent, v, PL_MIN_CONST, PL_MAX_CONST, org, bot_navigation_movemode))
					return true;
			}
			else
			{
				if (tracewalk(ent, org, PL_MIN_CONST, PL_MAX_CONST, v, bot_navigation_movemode))
					return true;
			}
		}
	}
	return false;
}

// find the spawnfunc_waypoint near a dynamic goal such as a dropped weapon
entity navigation_findnearestwaypoint_withdist_except(entity ent, float walkfromwp, float bestdist, entity except)
{
	vector pm1 = ent.origin + ent.mins;
	vector pm2 = ent.origin + ent.maxs;

	// do two scans, because box test is cheaper
	IL_EACH(g_waypoints, it != ent && it != except,
	{
		if(boxesoverlap(pm1, pm2, it.absmin, it.absmax))
			return it;
	});

	vector org = ent.origin + 0.5 * (ent.mins + ent.maxs);
	org.z = ent.origin.z + ent.mins.z - PL_MIN_CONST.z; // player height
	// TODO possibly make other code have the same support for bboxes
	if(ent.tag_entity)
		org = org + ent.tag_entity.origin;
	if (navigation_testtracewalk)
		te_plasmaburn(org);

	entity best = NULL;
	vector v;

	// box check failed, try walk
	IL_EACH(g_waypoints, it != ent,
	{
		if(it.wpisbox)
		{
			vector wm1 = it.origin + it.mins;
			vector wm2 = it.origin + it.maxs;
			v.x = bound(wm1_x, org.x, wm2_x);
			v.y = bound(wm1_y, org.y, wm2_y);
			v.z = bound(wm1_z, org.z, wm2_z);
		}
		else
			v = it.origin;
		if(navigation_waypoint_will_link(v, org, ent, walkfromwp, bestdist))
		{
			bestdist = vlen(v - org);
			best = it;
		}
	});
	return best;
}
entity navigation_findnearestwaypoint(entity ent, float walkfromwp)
{
	entity wp = navigation_findnearestwaypoint_withdist_except(ent, walkfromwp, 1050, NULL);
	if (autocvar_g_waypointeditor_auto)
	{
		entity wp2 = navigation_findnearestwaypoint_withdist_except(ent, walkfromwp, 1050, wp);
		if (wp && !wp2)
			wp.wpflags |= WAYPOINTFLAG_PROTECTED;
	}
	return wp;
}

// finds the waypoints near the bot initiating a navigation query
float navigation_markroutes_nearestwaypoints(entity this, float maxdist)
{
	vector v, m1, m2;
//	navigation_testtracewalk = true;
	int c = 0;
	IL_EACH(g_waypoints, !it.wpconsidered,
	{
		if (it.wpisbox)
		{
			m1 = it.origin + it.mins;
			m2 = it.origin + it.maxs;
			v = this.origin;
			v.x = bound(m1_x, v.x, m2_x);
			v.y = bound(m1_y, v.y, m2_y);
			v.z = bound(m1_z, v.z, m2_z);
		}
		else
			v = it.origin;
		vector diff = v - this.origin;
		diff.z = max(0, diff.z);
		if(vdist(diff, <, maxdist))
		{
			it.wpconsidered = true;
			if (tracewalk(this, this.origin, this.mins, this.maxs, v, bot_navigation_movemode))
			{
				it.wpnearestpoint = v;
				it.wpcost = vlen(v - this.origin) + it.dmg;
				it.wpfire = 1;
				it.enemy = NULL;
				c = c + 1;
			}
		}
	});
	//navigation_testtracewalk = false;
	return c;
}

// updates a path link if a spawnfunc_waypoint link is better than the current one
void navigation_markroutes_checkwaypoint(entity w, entity wp, float cost2, vector p)
{
	vector m1;
	vector m2;
	vector v;
	if (wp.wpisbox)
	{
		m1 = wp.absmin;
		m2 = wp.absmax;
		v.x = bound(m1_x, p.x, m2_x);
		v.y = bound(m1_y, p.y, m2_y);
		v.z = bound(m1_z, p.z, m2_z);
	}
	else
		v = wp.origin;
	cost2 = cost2 + vlen(v - p);
	if (wp.wpcost > cost2)
	{
		wp.wpcost = cost2;
		wp.enemy = w;
		wp.wpfire = 1;
		wp.wpnearestpoint = v;
	}
}

// queries the entire spawnfunc_waypoint network for pathes leading away from the bot
void navigation_markroutes(entity this, entity fixed_source_waypoint)
{
	float cost, cost2;
	vector p;

	IL_EACH(g_waypoints, true,
	{
		it.wpconsidered = false;
		it.wpnearestpoint = '0 0 0';
		it.wpcost = 10000000;
		it.wpfire = 0;
		it.enemy = NULL;
	});

	if(fixed_source_waypoint)
	{
		fixed_source_waypoint.wpconsidered = true;
		fixed_source_waypoint.wpnearestpoint = fixed_source_waypoint.origin + 0.5 * (fixed_source_waypoint.mins + fixed_source_waypoint.maxs);
		fixed_source_waypoint.wpcost = fixed_source_waypoint.dmg;
		fixed_source_waypoint.wpfire = 1;
		fixed_source_waypoint.enemy = NULL;
	}
	else
	{
		// try a short range search for the nearest waypoints, and expand the search repeatedly if none are found
		// as this search is expensive we will use lower values if the bot is on the air
		float increment, maxdistance;
		if(IS_ONGROUND(this))
		{
			increment = 750;
			maxdistance = 50000;
		}
		else
		{
			increment = 500;
			maxdistance = 1500;
		}

		for(int j = increment; !navigation_markroutes_nearestwaypoints(this, j) && j < maxdistance; j += increment);
	}

	bool searching = true;
	while (searching)
	{
		searching = false;
		IL_EACH(g_waypoints, it.wpfire,
		{
			searching = true;
			it.wpfire = 0;
			cost = it.wpcost;
			p = it.wpnearestpoint;
			entity wp;
			wp = it.wp00;if (wp){cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + it.wp00mincost) navigation_markroutes_checkwaypoint(it, wp, cost2, p);
			wp = it.wp01;if (wp){cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + it.wp01mincost) navigation_markroutes_checkwaypoint(it, wp, cost2, p);
			wp = it.wp02;if (wp){cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + it.wp02mincost) navigation_markroutes_checkwaypoint(it, wp, cost2, p);
			wp = it.wp03;if (wp){cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + it.wp03mincost) navigation_markroutes_checkwaypoint(it, wp, cost2, p);
			wp = it.wp04;if (wp){cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + it.wp04mincost) navigation_markroutes_checkwaypoint(it, wp, cost2, p);
			wp = it.wp05;if (wp){cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + it.wp05mincost) navigation_markroutes_checkwaypoint(it, wp, cost2, p);
			wp = it.wp06;if (wp){cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + it.wp06mincost) navigation_markroutes_checkwaypoint(it, wp, cost2, p);
			wp = it.wp07;if (wp){cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + it.wp07mincost) navigation_markroutes_checkwaypoint(it, wp, cost2, p);
			wp = it.wp08;if (wp){cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + it.wp08mincost) navigation_markroutes_checkwaypoint(it, wp, cost2, p);
			wp = it.wp09;if (wp){cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + it.wp09mincost) navigation_markroutes_checkwaypoint(it, wp, cost2, p);
			wp = it.wp10;if (wp){cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + it.wp10mincost) navigation_markroutes_checkwaypoint(it, wp, cost2, p);
			wp = it.wp11;if (wp){cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + it.wp11mincost) navigation_markroutes_checkwaypoint(it, wp, cost2, p);
			wp = it.wp12;if (wp){cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + it.wp12mincost) navigation_markroutes_checkwaypoint(it, wp, cost2, p);
			wp = it.wp13;if (wp){cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + it.wp13mincost) navigation_markroutes_checkwaypoint(it, wp, cost2, p);
			wp = it.wp14;if (wp){cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + it.wp14mincost) navigation_markroutes_checkwaypoint(it, wp, cost2, p);
			wp = it.wp15;if (wp){cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + it.wp15mincost) navigation_markroutes_checkwaypoint(it, wp, cost2, p);
			wp = it.wp16;if (wp){cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + it.wp16mincost) navigation_markroutes_checkwaypoint(it, wp, cost2, p);
			wp = it.wp17;if (wp){cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + it.wp17mincost) navigation_markroutes_checkwaypoint(it, wp, cost2, p);
			wp = it.wp18;if (wp){cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + it.wp18mincost) navigation_markroutes_checkwaypoint(it, wp, cost2, p);
			wp = it.wp19;if (wp){cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + it.wp19mincost) navigation_markroutes_checkwaypoint(it, wp, cost2, p);
			wp = it.wp20;if (wp){cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + it.wp20mincost) navigation_markroutes_checkwaypoint(it, wp, cost2, p);
			wp = it.wp21;if (wp){cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + it.wp21mincost) navigation_markroutes_checkwaypoint(it, wp, cost2, p);
			wp = it.wp22;if (wp){cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + it.wp22mincost) navigation_markroutes_checkwaypoint(it, wp, cost2, p);
			wp = it.wp23;if (wp){cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + it.wp23mincost) navigation_markroutes_checkwaypoint(it, wp, cost2, p);
			wp = it.wp24;if (wp){cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + it.wp24mincost) navigation_markroutes_checkwaypoint(it, wp, cost2, p);
			wp = it.wp25;if (wp){cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + it.wp25mincost) navigation_markroutes_checkwaypoint(it, wp, cost2, p);
			wp = it.wp26;if (wp){cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + it.wp26mincost) navigation_markroutes_checkwaypoint(it, wp, cost2, p);
			wp = it.wp27;if (wp){cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + it.wp27mincost) navigation_markroutes_checkwaypoint(it, wp, cost2, p);
			wp = it.wp28;if (wp){cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + it.wp28mincost) navigation_markroutes_checkwaypoint(it, wp, cost2, p);
			wp = it.wp29;if (wp){cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + it.wp29mincost) navigation_markroutes_checkwaypoint(it, wp, cost2, p);
			wp = it.wp30;if (wp){cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + it.wp30mincost) navigation_markroutes_checkwaypoint(it, wp, cost2, p);
			wp = it.wp31;if (wp){cost2 = cost + wp.dmg;if (wp.wpcost > cost2 + it.wp31mincost) navigation_markroutes_checkwaypoint(it, wp, cost2, p);
			}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}
		});
	}
}

// queries the entire spawnfunc_waypoint network for pathes leading to the bot
void navigation_markroutes_inverted(entity fixed_source_waypoint)
{
	float cost, cost2;
	vector p;
	IL_EACH(g_waypoints, true,
	{
		it.wpconsidered = false;
		it.wpnearestpoint = '0 0 0';
		it.wpcost = 10000000;
		it.wpfire = 0;
		it.enemy = NULL;
	});

	if(fixed_source_waypoint)
	{
		fixed_source_waypoint.wpconsidered = true;
		fixed_source_waypoint.wpnearestpoint = fixed_source_waypoint.origin + 0.5 * (fixed_source_waypoint.mins + fixed_source_waypoint.maxs);
		fixed_source_waypoint.wpcost = fixed_source_waypoint.dmg; // the cost to get from X to fixed_source_waypoint
		fixed_source_waypoint.wpfire = 1;
		fixed_source_waypoint.enemy = NULL;
	}
	else
	{
		error("need to start with a waypoint\n");
	}

	bool searching = true;
	while (searching)
	{
		searching = false;
		IL_EACH(g_waypoints, it.wpfire,
		{
			searching = true;
			it.wpfire = 0;
			cost = it.wpcost; // cost to walk from it to home
			p = it.wpnearestpoint;
			entity wp = it;
			IL_EACH(g_waypoints, true,
			{
				if(wp != it.wp00) if(wp != it.wp01) if(wp != it.wp02) if(wp != it.wp03)
				if(wp != it.wp04) if(wp != it.wp05) if(wp != it.wp06) if(wp != it.wp07)
				if(wp != it.wp08) if(wp != it.wp09) if(wp != it.wp10) if(wp != it.wp11)
				if(wp != it.wp12) if(wp != it.wp13) if(wp != it.wp14) if(wp != it.wp15)
				if(wp != it.wp16) if(wp != it.wp17) if(wp != it.wp18) if(wp != it.wp19)
				if(wp != it.wp20) if(wp != it.wp21) if(wp != it.wp22) if(wp != it.wp23)
				if(wp != it.wp24) if(wp != it.wp25) if(wp != it.wp26) if(wp != it.wp27)
				if(wp != it.wp28) if(wp != it.wp29) if(wp != it.wp30) if(wp != it.wp31)
					continue;
				cost2 = cost + it.dmg;
				navigation_markroutes_checkwaypoint(wp, it, cost2, p);
			});
		});
	}
}

// updates the best goal according to a weighted calculation of travel cost and item value of a new proposed item
void navigation_routerating(entity this, entity e, float f, float rangebias)
{
	if (!e)
		return;

	if(e.blacklisted)
		return;

	if (IS_PLAYER(e))
	{
		bool rate_wps = false;
		if((e.flags & FL_INWATER) || (e.flags & FL_PARTIALGROUND))
			rate_wps = true;

		if(!IS_ONGROUND(e))
		{
			traceline(e.origin, e.origin + '0 0 -1500', true, NULL);
			int t = pointcontents(trace_endpos + '0 0 1');
			if(t != CONTENT_SOLID )
			{
				if(t == CONTENT_WATER || t == CONTENT_SLIME || t == CONTENT_LAVA)
					rate_wps = true;
				else if(tracebox_hits_trigger_hurt(e.origin, e.mins, e.maxs, trace_endpos))
					return;
			}
		}

		if(rate_wps)
		{
			entity theEnemy = e;
			entity best_wp = NULL;
			float best_dist = 10000;
			IL_EACH(g_waypoints, vdist(it.origin - theEnemy.origin, <, 500)
				&& vdist(it.origin - this.origin, >, 100)
				&& !(it.wpflags & WAYPOINTFLAG_TELEPORT),
			{
				float dist = vlen(it.origin - theEnemy.origin);
				if (dist < best_dist)
				{
					best_wp = it;
					best_dist = dist;
				}
			});
			if (!best_wp)
				return;
			e = best_wp;
		}
	}

	vector o = (e.absmin + e.absmax) * 0.5;

	//print("routerating ", etos(e), " = ", ftos(f), " - ", ftos(rangebias), "\n");

	// Evaluate path using jetpack
	if(g_jetpack)
	if(this.items & IT_JETPACK)
	if(autocvar_bot_ai_navigation_jetpack)
	if(vdist(this.origin - o, >, autocvar_bot_ai_navigation_jetpack_mindistance))
	{
		vector pointa, pointb;

		LOG_DEBUG("jetpack ai: evaluating path for ", e.classname);

		// Point A
		traceline(this.origin, this.origin + '0 0 65535', MOVE_NORMAL, this);
		pointa = trace_endpos - '0 0 1';

		// Point B
		traceline(o, o + '0 0 65535', MOVE_NORMAL, e);
		pointb = trace_endpos - '0 0 1';

		// Can I see these two points from the sky?
		traceline(pointa, pointb, MOVE_NORMAL, this);

		if(trace_fraction==1)
		{
			LOG_DEBUG("jetpack ai: can bridge these two points");

			// Lower the altitude of these points as much as possible
			float zdistance, xydistance, cost, t, fuel;
			vector down, npa, npb;

			down = '0 0 -1' * (STAT(PL_MAX, this).z - STAT(PL_MIN, this).z) * 10;

			do{
				npa = pointa + down;
				npb = pointb + down;

				if(npa.z<=this.absmax.z)
					break;

				if(npb.z<=e.absmax.z)
					break;

				traceline(npa, npb, MOVE_NORMAL, this);
				if(trace_fraction==1)
				{
					pointa = npa;
					pointb = npb;
				}
			}
			while(trace_fraction == 1);


			// Rough estimation of fuel consumption
			// (ignores acceleration and current xyz velocity)
			xydistance = vlen(pointa - pointb);
			zdistance = fabs(pointa.z - this.origin.z);

			t = zdistance / autocvar_g_jetpack_maxspeed_up;
			t += xydistance / autocvar_g_jetpack_maxspeed_side;
			fuel = t * autocvar_g_jetpack_fuel * 0.8;

			LOG_DEBUG("jetpack ai: required fuel ", ftos(fuel), " this.ammo_fuel ", ftos(this.ammo_fuel));

			// enough fuel ?
			if(this.ammo_fuel>fuel)
			{
				// Estimate cost
				// (as onground costs calculation is mostly based on distances, here we do the same establishing some relationship
				//  - between air and ground speeds)

				cost = xydistance / (autocvar_g_jetpack_maxspeed_side/autocvar_sv_maxspeed);
				cost += zdistance / (autocvar_g_jetpack_maxspeed_up/autocvar_sv_maxspeed);
				cost *= 1.5;

				// Compare against other goals
				f = f * rangebias / (rangebias + cost);

				if (navigation_bestrating < f)
				{
					LOG_DEBUG("jetpack path: added goal ", e.classname, " (with rating ", ftos(f), ")");
					navigation_bestrating = f;
					navigation_bestgoal = e;
					this.navigation_jetpack_goal = e;
					this.navigation_jetpack_point = pointb;
				}
				return;
			}
		}
	}

	entity nwp;
	//te_wizspike(e.origin);
	//bprint(etos(e));
	//bprint("\n");
	// update the cached spawnfunc_waypoint link on a dynamic item entity
	if(e.classname == "waypoint" && !(e.wpflags & WAYPOINTFLAG_PERSONAL))
	{
		nwp = e;
	}
	else
	{
		if(autocvar_g_waypointeditor && e.nearestwaypointtimeout >= 0 && time > e.nearestwaypointtimeout)
			e.nearestwaypoint = NULL;

		if ((!e.nearestwaypoint || e.navigation_dynamicgoal)
			&& e.nearestwaypointtimeout >= 0 && time > e.nearestwaypointtimeout)
		{
			nwp = navigation_findnearestwaypoint(e, true);
			if(nwp)
				e.nearestwaypoint = nwp;
			else
			{
				LOG_DEBUG("FAILED to find a nearest waypoint to '", e.classname, "' #", etos(e));

				if(!e.navigation_dynamicgoal)
					e.blacklisted = true;

				if(e.blacklisted)
				{
					LOG_DEBUG("The entity '", e.classname, "' is going to be excluded from path finding during this match");
					return;
				}
			}

			if(e.navigation_dynamicgoal)
				e.nearestwaypointtimeout = time + 2;
			else if(autocvar_g_waypointeditor)
				e.nearestwaypointtimeout = time + 3 + random() * 2;
		}
		nwp = e.nearestwaypoint;
	}

	LOG_DEBUG("-- checking ", e.classname, " (with cost ", ftos(nwp.wpcost), ")");
	if (nwp)
	if (nwp.wpcost < 10000000)
	{
		//te_wizspike(nwp.wpnearestpoint);
		LOG_DEBUG(e.classname, " ", ftos(f), "/(1+", ftos((nwp.wpcost + vlen(e.origin - nwp.wpnearestpoint))), "/", ftos(rangebias), ") = ");
		f = f * rangebias / (rangebias + (nwp.wpcost + vlen(o - nwp.wpnearestpoint)));
		LOG_DEBUG("considering ", e.classname, " (with rating ", ftos(f), ")");
		if (navigation_bestrating < f)
		{
			LOG_DEBUG("ground path: added goal ", e.classname, " (with rating ", ftos(f), ")");
			navigation_bestrating = f;
			navigation_bestgoal = e;
		}
	}
}

// adds an item to the the goal stack with the path to a given item
bool navigation_routetogoal(entity this, entity e, vector startposition)
{
	// if there is no goal, just exit
	if (!e)
		return false;

	this.goalentity = e;

	// put the entity on the goal stack
	//print("routetogoal ", etos(e), "\n");
	navigation_pushroute(this, e);

	if(e.classname == "waypoint" && !(e.wpflags & WAYPOINTFLAG_PERSONAL))
	{
		this.wp_goal_prev1 = this.wp_goal_prev0;
		this.wp_goal_prev0 = e;
	}

	if(g_jetpack)
	if(e==this.navigation_jetpack_goal)
		return true;

	// if it can reach the goal there is nothing more to do
	if (tracewalk(this, startposition, STAT(PL_MIN, this), STAT(PL_MAX, this), (e.absmin + e.absmax) * 0.5, bot_navigation_movemode))
		return true;

	entity nearest_wp = NULL;
	// see if there are waypoints describing a path to the item
	if(e.classname != "waypoint" || (e.wpflags & WAYPOINTFLAG_PERSONAL))
	{
		e = e.nearestwaypoint;
		nearest_wp = e;
	}
	else
		e = e.enemy; // we already have added it, so...

	if(e == NULL)
		return false;

	if(nearest_wp && nearest_wp.enemy)
	{
		// often path can be optimized by not adding the nearest waypoint
		if(tracewalk(this, nearest_wp.enemy.origin, STAT(PL_MIN, this), STAT(PL_MAX, this), (this.goalentity.absmin + this.goalentity.absmax) * 0.5, bot_navigation_movemode))
			e = nearest_wp.enemy;
	}

	for (;;)
	{
		// add the spawnfunc_waypoint to the path
		navigation_pushroute(this, e);
		e = e.enemy;

		if(e==NULL)
			break;
	}

	return false;
}

// removes any currently touching waypoints from the goal stack
// (this is how bots detect if they reached a goal)
void navigation_poptouchedgoals(entity this)
{
	vector org, m1, m2;
	org = this.origin;
	m1 = org + this.mins;
	m2 = org + this.maxs;

	if(this.goalcurrent.wpflags & WAYPOINTFLAG_TELEPORT)
	{
		// make sure jumppad is really hit, don't rely on distance based checks
		// as they may report a touch even if it didn't really happen
		if(this.lastteleporttime>0)
		if(time - this.lastteleporttime < ((this.goalcurrent.wpflags & WAYPOINTFLAG_PERSONAL) ? 2 : 0.15))
		{
			if(this.aistatus & AI_STATUS_WAYPOINT_PERSONAL_GOING)
			if(this.goalcurrent.wpflags & WAYPOINTFLAG_PERSONAL && this.goalcurrent.owner==this)
			{
				this.aistatus &= ~AI_STATUS_WAYPOINT_PERSONAL_GOING;
				this.aistatus |= AI_STATUS_WAYPOINT_PERSONAL_REACHED;
			}
			navigation_poproute(this);
			return;
		}
	}

	// If for some reason the bot is closer to the next goal, pop the current one
	if(this.goalstack01 && !wasfreed(this.goalstack01))
	if(vlen2(this.goalcurrent.origin - this.origin) > vlen2(this.goalstack01.origin - this.origin))
	if(checkpvs(this.origin + this.view_ofs, this.goalstack01))
	if(tracewalk(this, this.origin, this.mins, this.maxs, (this.goalstack01.absmin + this.goalstack01.absmax) * 0.5, bot_navigation_movemode))
	{
		LOG_DEBUG("path optimized for ", this.netname, ", removed a goal from the queue");
		navigation_poproute(this);
		// TODO this may also be a nice idea to do "early" (e.g. by
		// manipulating the vlen() comparisons) to shorten paths in
		// general - this would make bots walk more "on rails" than
		// "zigzagging" which they currently do with sufficiently
		// random-like waypoints, and thus can make a nice bot
		// personality property
	}

	// Loose goal touching check when running
	if(this.aistatus & AI_STATUS_RUNNING)
	if(this.goalcurrent.classname=="waypoint")
	if(!(this.goalcurrent.wpflags & WAYPOINTFLAG_TELEPORT))
	if(vlen(this.velocity - eZ * this.velocity.z) >= autocvar_sv_maxspeed) // if -really- running
	{
		if(vdist(this.origin - this.goalcurrent.origin, <, 150))
		{
			traceline(this.origin + this.view_ofs , this.goalcurrent.origin, true, NULL);
			if(trace_fraction==1)
			{
				// Detect personal waypoints
				if(this.aistatus & AI_STATUS_WAYPOINT_PERSONAL_GOING)
				if(this.goalcurrent.wpflags & WAYPOINTFLAG_PERSONAL && this.goalcurrent.owner==this)
				{
					this.aistatus &= ~AI_STATUS_WAYPOINT_PERSONAL_GOING;
					this.aistatus |= AI_STATUS_WAYPOINT_PERSONAL_REACHED;
				}

				navigation_poproute(this);
			}
		}
	}

	while (this.goalcurrent && !IS_PLAYER(this.goalcurrent))
	{
		vector gc_min = this.goalcurrent.absmin;
		vector gc_max = this.goalcurrent.absmax;
		if(this.goalcurrent.classname == "waypoint" && !this.goalcurrent.wpisbox)
		{
			gc_min = this.goalcurrent.origin - '1 1 1' * 12;
			gc_max = this.goalcurrent.origin + '1 1 1' * 12;
		}
		if(!boxesoverlap(m1, m2, gc_min, gc_max))
			break;

		if((this.goalcurrent.wpflags & WAYPOINTFLAG_TELEPORT))
			break;

		// Detect personal waypoints
		if(this.aistatus & AI_STATUS_WAYPOINT_PERSONAL_GOING)
		if(this.goalcurrent.wpflags & WAYPOINTFLAG_PERSONAL && this.goalcurrent.owner==this)
		{
			this.aistatus &= ~AI_STATUS_WAYPOINT_PERSONAL_GOING;
			this.aistatus |= AI_STATUS_WAYPOINT_PERSONAL_REACHED;
		}

		navigation_poproute(this);
	}
}

// begin a goal selection session (queries spawnfunc_waypoint network)
void navigation_goalrating_start(entity this)
{
	if(this.aistatus & AI_STATUS_STUCK)
		return;

	this.navigation_jetpack_goal = NULL;
	navigation_bestrating = -1;
	navigation_clearroute(this);
	navigation_bestgoal = NULL;
	navigation_markroutes(this, NULL);
}

// ends a goal selection session (updates goal stack to the best goal)
void navigation_goalrating_end(entity this)
{
	if(this.aistatus & AI_STATUS_STUCK)
		return;

	navigation_routetogoal(this, navigation_bestgoal, this.origin);
	LOG_DEBUG("best goal ", this.goalcurrent.classname);

	// If the bot got stuck then try to reach the farthest waypoint
	if (!this.goalentity && autocvar_bot_wander_enable)
	{
		if (!(this.aistatus & AI_STATUS_STUCK))
		{
			LOG_DEBUG(this.netname, " cannot walk to any goal");
			this.aistatus |= AI_STATUS_STUCK;
		}
	}
}

void botframe_updatedangerousobjects(float maxupdate)
{
	vector m1, m2, v, o;
	float c, d, danger;
	c = 0;
	IL_EACH(g_waypoints, true,
	{
		danger = 0;
		m1 = it.mins;
		m2 = it.maxs;
		IL_EACH(g_bot_dodge, it.bot_dodge,
		{
			v = it.origin;
			v.x = bound(m1_x, v.x, m2_x);
			v.y = bound(m1_y, v.y, m2_y);
			v.z = bound(m1_z, v.z, m2_z);
			o = (it.absmin + it.absmax) * 0.5;
			d = it.bot_dodgerating - vlen(o - v);
			if (d > 0)
			{
				traceline(o, v, true, NULL);
				if (trace_fraction == 1)
					danger = danger + d;
			}
		});
		it.dmg = danger;
		c = c + 1;
		if (c >= maxupdate)
			break;
	});
}

void navigation_unstuck(entity this)
{
	float search_radius = 1000;

	if (!autocvar_bot_wander_enable)
		return;

	if (!bot_waypoint_queue_owner)
	{
		LOG_DEBUG(this.netname, " stuck, taking over the waypoints queue");
		bot_waypoint_queue_owner = this;
		bot_waypoint_queue_bestgoal = NULL;
		bot_waypoint_queue_bestgoalrating = 0;
	}

	if(bot_waypoint_queue_owner!=this)
		return;

	if (bot_waypoint_queue_goal)
	{
		// evaluate the next goal on the queue
		float d = vlen2(this.origin - bot_waypoint_queue_goal.origin);
		LOG_DEBUG(this.netname, " evaluating ", bot_waypoint_queue_goal.classname, " with distance ", ftos(d));
		if(tracewalk(bot_waypoint_queue_goal, this.origin, STAT(PL_MIN, this), STAT(PL_MAX, this), bot_waypoint_queue_goal.origin, bot_navigation_movemode))
		{
			if( d > bot_waypoint_queue_bestgoalrating)
			{
				bot_waypoint_queue_bestgoalrating = d;
				bot_waypoint_queue_bestgoal = bot_waypoint_queue_goal;
			}
		}
		bot_waypoint_queue_goal = bot_waypoint_queue_goal.bot_waypoint_queue_nextgoal;

		if (!bot_waypoint_queue_goal)
		{
			if (bot_waypoint_queue_bestgoal)
			{
				LOG_DEBUG(this.netname, " stuck, reachable waypoint found, heading to it");
				navigation_routetogoal(this, bot_waypoint_queue_bestgoal, this.origin);
				this.bot_strategytime = time + autocvar_bot_ai_strategyinterval;
				this.aistatus &= ~AI_STATUS_STUCK;
			}
			else
			{
				LOG_DEBUG(this.netname, " stuck, cannot walk to any waypoint at all");
			}

			bot_waypoint_queue_owner = NULL;
		}
	}
	else
	{
		if(bot_strategytoken!=this)
			return;

		// build a new queue
		LOG_DEBUG(this.netname, " stuck, scanning reachable waypoints within ", ftos(search_radius)," qu");

		entity first = NULL;

		FOREACH_ENTITY_RADIUS(this.origin, search_radius, it.classname == "waypoint" && !(it.wpflags & WAYPOINTFLAG_GENERATED),
		{
			if(bot_waypoint_queue_goal)
				bot_waypoint_queue_goal.bot_waypoint_queue_nextgoal = it;
			else
				first = it;

			bot_waypoint_queue_goal = it;
			bot_waypoint_queue_goal.bot_waypoint_queue_nextgoal = NULL;
		});

		if (first)
			bot_waypoint_queue_goal = first;
		else
		{
			LOG_DEBUG(this.netname, " stuck, cannot walk to any waypoint at all");
			bot_waypoint_queue_owner = NULL;
		}
	}
}

// Support for debugging tracewalk visually

void debugresetnodes()
{
	debuglastnode = '0 0 0';
}

void debugnode(entity this, vector node)
{
	if (!IS_PLAYER(this))
		return;

	if(debuglastnode=='0 0 0')
	{
		debuglastnode = node;
		return;
	}

	te_lightning2(NULL, node, debuglastnode);
	debuglastnode = node;
}

void debugnodestatus(vector position, float status)
{
	vector c;

	switch (status)
	{
		case DEBUG_NODE_SUCCESS:
			c = '0 15 0';
			break;
		case DEBUG_NODE_WARNING:
			c = '15 15 0';
			break;
		case DEBUG_NODE_FAIL:
			c = '15 0 0';
			break;
		default:
			c = '15 15 15';
	}

	te_customflash(position, 40,  2, c);
}

// Support for debugging the goal stack visually

.float goalcounter;
.vector lastposition;

// Debug the goal stack visually
void debuggoalstack(entity this)
{
	entity goal;
	vector org, go;

	if(this.goalcounter==0)goal=this.goalcurrent;
	else if(this.goalcounter==1)goal=this.goalstack01;
	else if(this.goalcounter==2)goal=this.goalstack02;
	else if(this.goalcounter==3)goal=this.goalstack03;
	else if(this.goalcounter==4)goal=this.goalstack04;
	else if(this.goalcounter==5)goal=this.goalstack05;
	else if(this.goalcounter==6)goal=this.goalstack06;
	else if(this.goalcounter==7)goal=this.goalstack07;
	else if(this.goalcounter==8)goal=this.goalstack08;
	else if(this.goalcounter==9)goal=this.goalstack09;
	else if(this.goalcounter==10)goal=this.goalstack10;
	else if(this.goalcounter==11)goal=this.goalstack11;
	else if(this.goalcounter==12)goal=this.goalstack12;
	else if(this.goalcounter==13)goal=this.goalstack13;
	else if(this.goalcounter==14)goal=this.goalstack14;
	else if(this.goalcounter==15)goal=this.goalstack15;
	else if(this.goalcounter==16)goal=this.goalstack16;
	else if(this.goalcounter==17)goal=this.goalstack17;
	else if(this.goalcounter==18)goal=this.goalstack18;
	else if(this.goalcounter==19)goal=this.goalstack19;
	else if(this.goalcounter==20)goal=this.goalstack20;
	else if(this.goalcounter==21)goal=this.goalstack21;
	else if(this.goalcounter==22)goal=this.goalstack22;
	else if(this.goalcounter==23)goal=this.goalstack23;
	else if(this.goalcounter==24)goal=this.goalstack24;
	else if(this.goalcounter==25)goal=this.goalstack25;
	else if(this.goalcounter==26)goal=this.goalstack26;
	else if(this.goalcounter==27)goal=this.goalstack27;
	else if(this.goalcounter==28)goal=this.goalstack28;
	else if(this.goalcounter==29)goal=this.goalstack29;
	else if(this.goalcounter==30)goal=this.goalstack30;
	else if(this.goalcounter==31)goal=this.goalstack31;
	else goal=NULL;

	if(goal==NULL)
	{
		this.goalcounter = 0;
		this.lastposition='0 0 0';
		return;
	}

	if(this.lastposition=='0 0 0')
		org = this.origin;
	else
		org = this.lastposition;


	go = ( goal.absmin + goal.absmax ) * 0.5;
	te_lightning2(NULL, org, go);
	this.lastposition = go;

	this.goalcounter++;
}
