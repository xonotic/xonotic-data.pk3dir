#include "navigation.qh"

#include <server/defs.qh>
#include <server/miscfunctions.qh>
#include "cvars.qh"

#include "bot.qh"
#include "waypoints.qh"

#include <common/t_items.qh>

#include <common/items/_mod.qh>

#include <common/constants.qh>
#include <common/net_linked.qh>
#include <common/triggers/trigger/jumppads.qh>

.float speed;

void navigation_goalrating_timeout_set(entity this)
{
	if((IS_PLAYER(this.goalentity) || IS_MONSTER(this.goalentity)) && !STAT(FROZEN, this.goalentity))
		this.bot_strategytime = time + autocvar_bot_ai_strategyinterval_movingtarget;
	else
		this.bot_strategytime = time + autocvar_bot_ai_strategyinterval;
}

void navigation_goalrating_timeout_force(entity this)
{
	this.bot_strategytime = 0;
}

bool navigation_goalrating_timeout(entity this)
{
	return this.bot_strategytime < time;
}

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

bool navigation_check_submerged_state(entity ent, vector pos)
{
	bool submerged;
	if(IS_PLAYER(ent))
		submerged = (ent.waterlevel == WATERLEVEL_SUBMERGED);
	else if(ent.nav_submerged_state != SUBMERGED_UNDEFINED)
		submerged = (ent.nav_submerged_state == SUBMERGED_YES);
	else
	{
		submerged = SUBMERGED(pos);
		// NOTE: SUBMERGED check of box waypoint origin may fail even if origin
		//  is actually submerged because often they are inside some solid.
		//  That's why submerged state is saved now that we know current pos is
		//  not stuck in solid (previous tracewalk call to this pos was successfully)
		if(!ent.navigation_dynamicgoal)
			ent.nav_submerged_state = (submerged) ? SUBMERGED_YES : SUBMERGED_NO;
	}
	return submerged;
}

bool navigation_checkladders(entity e, vector org, vector m1, vector m2, vector end, vector end2, int movemode)
{
	IL_EACH(g_ladders, it.classname == "func_ladder",
	{
		if(it.bot_pickup)
		if(boxesoverlap(org + m1 + '-1 -1 -1', org + m2 + '1 1 1', it.absmin, it.absmax))
		if(boxesoverlap(end, end2, it.absmin + vec2(m1) + '-1 -1 0', it.absmax + vec2(m2) + '1 1 0'))
		{
			vector top = org;
			top.z = it.absmax.z + (PL_MAX_CONST.z - PL_MIN_CONST.z);
			tracebox(org, m1, m2, top, movemode, e);
			if(trace_fraction == 1)
				return true;
		}
	});
	return false;
}

vector resurface_limited(vector org, float lim, vector m1)
{
	if (WETFEET(org + eZ * (lim - org.z)))
		org.z = lim;
	else
	{
		float RES_min_h = org.z;
		float RES_max_h = lim;
		do {
			org.z = 0.5 * (RES_min_h + RES_max_h);
			if(WETFEET(org))
				RES_min_h = org.z;
			else
				RES_max_h = org.z;
		} while (RES_max_h - RES_min_h >= 1);
		org.z = RES_min_h;
	}
	return org;
}
#define RESURFACE_LIMITED(org, lim) org = resurface_limited(org, lim, m1)

#define NAV_WALK 0
#define NAV_SWIM_ONWATER 1
#define NAV_SWIM_UNDERWATER 2

// rough simulation of walking from one point to another to test if a path
// can be traveled, used for waypoint linking and havocbot
// if end_height is > 0 destination is any point in the vertical segment [end, end + end_height * eZ]
bool tracewalk(entity e, vector start, vector m1, vector m2, vector end, float end_height, float movemode)
{
	if(autocvar_bot_debug_tracewalk)
	{
		debugresetnodes();
		debugnode(e, start);
	}

	vector org = start;
	vector flatdir = end - start;
	flatdir.z = 0;
	float flatdist = vlen(flatdir);
	flatdir = normalize(flatdir);
	float stepdist = 32;
	bool ignorehazards = false;
	int nav_action;

	// Analyze starting point
	traceline(start, start, MOVE_NORMAL, e);
	if (trace_dpstartcontents & (DPCONTENTS_SLIME | DPCONTENTS_LAVA))
		ignorehazards = true;

	tracebox(start, m1, m2, start, MOVE_NOMONSTERS, e);
	if (trace_startsolid)
	{
		// Bad start
		if(autocvar_bot_debug_tracewalk)
			debugnodestatus(start, DEBUG_NODE_FAIL);

		//print("tracewalk: ", vtos(start), " is a bad start\n");
		return false;
	}

	vector end2 = end;
	if(end_height)
		end2.z += end_height;

	vector fixed_end = end;
	vector move;

	if (flatdist > 0 && WETFEET(org))
	{
		if (SUBMERGED(org))
			nav_action = NAV_SWIM_UNDERWATER;
		else
		{
			// tracebox down by player's height
			// useful to know if water level is so low that bot can still walk
			tracebox(org, m1, m2, org - eZ * (m2.z - m1.z), movemode, e);
			if (SUBMERGED(trace_endpos))
			{
				org = trace_endpos;
				nav_action = NAV_SWIM_UNDERWATER;
			}
			else
				nav_action = NAV_WALK;
		}
	}
	else
		nav_action =  NAV_WALK;

	// Movement loop
	while (true)
	{
		if (flatdist <= 0)
		{
			bool success = true;
			if (org.z > end2.z + 1)
			{
				tracebox(org, m1, m2, end2, movemode, e);
				org = trace_endpos;
				if (org.z > end2.z + 1)
					success = false;
			}
			else if (org.z < end.z - 1)
			{
				tracebox(org, m1, m2, org - jumpheight_vec, movemode, e);
				if (SUBMERGED(trace_endpos))
				{
					vector v = trace_endpos;
					tracebox(v, m1, m2, end, movemode, e);
					if(trace_endpos.z >= end.z - 1)
					{
						RESURFACE_LIMITED(v, trace_endpos.z);
						trace_endpos = v;
					}
				}
				else if (trace_endpos.z > org.z - jumpheight_vec.z)
					tracebox(trace_endpos, m1, m2, trace_endpos + jumpheight_vec, movemode, e);
				org = trace_endpos;
				if (org.z < end.z - 1)
					success = false;
			}

			if (success)
			{
				// Succeeded
				if(autocvar_bot_debug_tracewalk)
				{
					debugnode(e, org);
					debugnodestatus(org, DEBUG_NODE_SUCCESS);
				}

				//print("tracewalk: ", vtos(start), " can reach ", vtos(end), "\n");
				return true;
			}
		}

		if(autocvar_bot_debug_tracewalk)
			debugnode(e, org);

		if (flatdist <= 0)
			break;

		if (stepdist > flatdist)
			stepdist = flatdist;
		if(nav_action == NAV_SWIM_UNDERWATER || (nav_action == NAV_SWIM_ONWATER && org.z > end2.z))
		{
			// can't use movement direction here to calculate move because of
			// precision errors especially when direction has a high enough z value
			//water_dir = normalize(water_end - org);
			//move = org + water_dir * stepdist;
			fixed_end.z = bound(end.z, org.z, end2.z);
			if (stepdist == flatdist) {
				move = fixed_end;
				flatdist = 0;
			} else {
				move = org + (fixed_end - org) * (stepdist / flatdist);
				flatdist = vlen(vec2(fixed_end - move));
			}
		}
		else // horiz. direction
		{
			flatdist -= stepdist;
			move = org + flatdir * stepdist;
		}

		if(nav_action == NAV_SWIM_ONWATER)
		{
			tracebox(org, m1, m2, move, movemode, e); // swim

			// hit something
			if (trace_fraction < 1)
			{
				// stepswim
				tracebox(org + stepheightvec, m1, m2, move + stepheightvec, movemode, e);

				if (trace_fraction < 1 || trace_startsolid) // can't jump obstacle out of water
				{
					org = trace_endpos;
					if(navigation_checkladders(e, org, m1, m2, end, end2, movemode))
					{
						if(autocvar_bot_debug_tracewalk)
						{
							debugnode(e, org);
							debugnodestatus(org, DEBUG_NODE_SUCCESS);
						}

						//print("tracewalk: ", vtos(start), " can reach ", vtos(end), "\n");
						return true;
					}

					if(autocvar_bot_debug_tracewalk)
						debugnodestatus(org, DEBUG_NODE_FAIL);

					return false;
					//print("tracewalk: ", vtos(start), " hit something when trying to reach ", vtos(end), "\n");
				}

				//succesful stepswim

				if (flatdist <= 0)
				{
					org = trace_endpos;
					continue;
				}

				if (org.z <= move.z) // going horiz.
				{
					tracebox(trace_endpos, m1, m2, move, movemode, e);
					org = trace_endpos;
					nav_action = NAV_WALK;
					continue;
				}
			}

			if (org.z <= move.z) // going horiz.
			{
				org = trace_endpos;
				nav_action = NAV_SWIM_ONWATER;
			}
			else // going down
			{
				org = trace_endpos;
				if (SUBMERGED(org))
					nav_action = NAV_SWIM_UNDERWATER;
				else
					nav_action = NAV_SWIM_ONWATER;
			}
		}
		else if(nav_action == NAV_SWIM_UNDERWATER)
		{
			if (move.z >= org.z) // swimming upwards or horiz.
			{
				tracebox(org, m1, m2, move, movemode, e); // swim

				bool stepswum = false;

				// hit something
				if (trace_fraction < 1)
				{
					// stepswim
					vector stepswim_move = move + stepheightvec;
					if (flatdist > 0 && stepswim_move.z > end2.z + stepheightvec.z) // don't allow stepswim to go higher than destination
						stepswim_move.z = end2.z;

					tracebox(org + stepheightvec, m1, m2, stepswim_move, movemode, e);

					// hit something
					if (trace_startsolid)
					{
						if(autocvar_bot_debug_tracewalk)
							debugnodestatus(org, DEBUG_NODE_FAIL);

						//print("tracewalk: ", vtos(start), " hit something when trying to reach ", vtos(end), "\n");
						return false;
					}

					if (trace_fraction < 1)
					{
						float org_z_prev = org.z;
						RESURFACE_LIMITED(org, end2.z);
						if(org.z == org_z_prev)
						{
							if(autocvar_bot_debug_tracewalk)
								debugnodestatus(org, DEBUG_NODE_FAIL);

							//print("tracewalk: ", vtos(start), " can't reach ", vtos(end), "\n");
							return false;
						}
						if(SUBMERGED(org))
							nav_action = NAV_SWIM_UNDERWATER;
						else
							nav_action = NAV_SWIM_ONWATER;

						// we didn't advance horiz. in this step, flatdist decrease should be reverted
						// but we can't do it properly right now... apply this workaround instead
						if (flatdist <= 0)
							flatdist = 1;

						continue;
					}

					//succesful stepswim

					if (flatdist <= 0)
					{
						org = trace_endpos;
						continue;
					}

					stepswum = true;
				}

				if (!WETFEET(trace_endpos))
				{
					tracebox(trace_endpos, m1, m2, trace_endpos - eZ * (stepdist + (m2.z - m1.z)), movemode, e);
					// if stepswum we'll land on the obstacle, avoid the SUBMERGED check
					if (!stepswum && SUBMERGED(trace_endpos))
					{
						RESURFACE_LIMITED(trace_endpos, end2.z);
						org = trace_endpos;
						nav_action = NAV_SWIM_ONWATER;
						continue;
					}

					// not submerged
					org = trace_endpos;
					nav_action = NAV_WALK;
					continue;
				}

				// wetfeet
				org = trace_endpos;
				nav_action = NAV_SWIM_UNDERWATER;
				continue;
			}
			else //if (move.z < org.z) // swimming downwards
			{
				tracebox(org, m1, m2, move, movemode, e); // swim

				// hit something
				if (trace_fraction < 1)
				{
					// stepswim
					tracebox(org + stepheightvec, m1, m2, move + stepheightvec, movemode, e);

					// hit something
					if (trace_fraction < 1 || trace_startsolid) // can't jump obstacle out of water
					{
						if(autocvar_bot_debug_tracewalk)
							debugnodestatus(move, DEBUG_NODE_FAIL);

						//print("tracewalk: ", vtos(start), " hit something when trying to reach ", vtos(end), "\n");
						return false;
					}

					//succesful stepswim

					if (flatdist <= 0)
					{
						org = trace_endpos;
						continue;
					}

					if (trace_endpos.z > org.z && !SUBMERGED(trace_endpos))
					{
						// stepswim caused upwards direction
						tracebox(trace_endpos, m1, m2, trace_endpos - stepheightvec, movemode, e);
						if (!SUBMERGED(trace_endpos))
						{
							org = trace_endpos;
							nav_action = NAV_WALK;
							continue;
						}
					}
				}

				org = trace_endpos;
				nav_action = NAV_SWIM_UNDERWATER;
				continue;
			}
		}
		else if(nav_action == NAV_WALK)
		{
			// walk
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
					if (trace_startsolid) // hit ceiling above org
					{
						// reduce stepwalk height
						tracebox(org, m1, m2, org + stepheightvec, movemode, e);
						tracebox(trace_endpos, m1, m2, move + eZ * (trace_endpos.z - move.z), movemode, e);
					}
					else //if (trace_fraction < 1)
					{
						tracebox(org + jumpstepheightvec, m1, m2, move + jumpstepheightvec, movemode, e);
						if (trace_startsolid) // hit ceiling above org
						{
							// reduce jumpstepwalk height
							tracebox(org, m1, m2, org + jumpstepheightvec, movemode, e);
							tracebox(trace_endpos, m1, m2, move + eZ * (trace_endpos.z - move.z), movemode, e);
						}
					}

					if (trace_fraction < 1)
					{
						vector v = trace_endpos;
						v.z = org.z + jumpheight_vec.z;
						if(navigation_checkladders(e, v, m1, m2, end, end2, movemode))
						{
							if(autocvar_bot_debug_tracewalk)
							{
								debugnode(e, v);
								debugnodestatus(v, DEBUG_NODE_SUCCESS);
							}

							//print("tracewalk: ", vtos(start), " can reach ", vtos(end), "\n");
							return true;
						}

						if(autocvar_bot_debug_tracewalk)
							debugnodestatus(trace_endpos, DEBUG_NODE_WARNING);

						traceline( org, move, movemode, e);

						if ( trace_ent.classname == "door_rotating" || trace_ent.classname == "door")
						{
							vector nextmove;
							move = trace_endpos;
							while(trace_ent.classname == "door_rotating" || trace_ent.classname == "door")
							{
								nextmove = move + (flatdir * stepdist);
								traceline( move, nextmove, movemode, e);
								move = nextmove;
							}
							flatdist = vlen(vec2(end - move));
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

			org = trace_endpos;

			if (!ignorehazards)
			{
				if (IN_LAVA(org))
				{
					if(autocvar_bot_debug_tracewalk)
					{
						debugnode(e, trace_endpos);
						debugnodestatus(org, DEBUG_NODE_FAIL);
					}

					//print("tracewalk: ", vtos(start), " hits a hazard when trying to reach ", vtos(end), "\n");
					return false;
				}
			}

			if (flatdist <= 0)
			{
				if(move.z >= end2.z && org.z < end2.z)
					org.z = end2.z;
				continue;
			}

			if(org.z > move.z - 1 || !SUBMERGED(org))
			{
				nav_action = NAV_WALK;
				continue;
			}

			// ended up submerged while walking
			if(autocvar_bot_debug_tracewalk)
				debugnode(e, org);

			RESURFACE_LIMITED(org, move.z);
			nav_action = NAV_SWIM_ONWATER;
			continue;
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
	this.goalcurrent_prev = this.goalcurrent;
	this.goalcurrent_distance = 10000000;
	this.goalcurrent_distance_time = 0;
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
	this.goalcurrent_prev = this.goalcurrent;
	this.goalcurrent_distance = 10000000;
	this.goalcurrent_distance_time = 0;
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
	this.goalcurrent_prev = this.goalcurrent;
	this.goalcurrent_distance = 10000000;
	this.goalcurrent_distance_time = 0;
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

// walking to wp (walkfromwp == false) v2 and v2_height will be used as
// waypoint destination coordinates instead of v (only useful for box waypoints)
// for normal waypoints v2 == v and v2_height == 0
float navigation_waypoint_will_link(vector v, vector org, entity ent, vector v2, float v2_height, vector o2, float o2_height, float walkfromwp, float bestdist)
{
	if (vdist(v - org, <, bestdist))
	{
		traceline(v, org, true, ent);
		if (trace_fraction == 1)
		{
			if (walkfromwp)
			{
				if (tracewalk(ent, v, PL_MIN_CONST, PL_MAX_CONST, v2, v2_height, bot_navigation_movemode))
					return true;
			}
			else
			{
				if (tracewalk(ent, org, PL_MIN_CONST, PL_MAX_CONST, o2, o2_height, bot_navigation_movemode))
					return true;
			}
		}
	}
	return false;
}

// find the spawnfunc_waypoint near a dynamic goal such as a dropped weapon
entity navigation_findnearestwaypoint_withdist_except(entity ent, float walkfromwp, float bestdist, entity except)
{
	if(ent.tag_entity)
		ent = ent.tag_entity;

	vector pm1 = ent.origin + ent.mins;
	vector pm2 = ent.origin + ent.maxs;

	// do two scans, because box test is cheaper
	IL_EACH(g_waypoints, it != ent && it != except,
	{
		if(boxesoverlap(pm1, pm2, it.absmin, it.absmax))
			return it;
	});

	vector org = ent.origin;
	if (navigation_testtracewalk)
		te_plasmaburn(org);

	entity best = NULL;
	vector v = '0 0 0', v2 = '0 0 0';
	float v2_height = 0;

	if(ent.size && !IS_PLAYER(ent))
	{
		org += 0.5 * (ent.mins + ent.maxs);
		org.z = ent.origin.z + ent.mins.z - PL_MIN_CONST.z; // player height
	}

	if(!autocvar_g_waypointeditor && walkfromwp && !ent.navigation_dynamicgoal)
	{
		waypoint_clearlinks(ent); // initialize wpXXmincost fields
		IL_EACH(g_waypoints, it != ent,
		{
			if(walkfromwp && (it.wpflags & WAYPOINTFLAG_NORELINK))
				continue;

			SET_TRACEWALK_DESTCOORDS(it, org, v2, v2_height);
			if(vdist(v2 - org, <, 1050))
			if(tracewalk(ent, org, PL_MIN_CONST, PL_MAX_CONST, v2, v2_height, bot_navigation_movemode))
				navigation_item_addlink(it, ent);
		});
	}

	// box check failed, try walk
	IL_EACH(g_waypoints, it != ent,
	{
		if(walkfromwp && (it.wpflags & WAYPOINTFLAG_NORELINK))
			continue;
		v = it.origin;
		if(walkfromwp)
			SET_TRACEWALK_DESTCOORDS(ent, v, v2, v2_height);
		else
			SET_TRACEWALK_DESTCOORDS(it, org, v2, v2_height);
		if(navigation_waypoint_will_link(v, org, ent, v2, v2_height, v2, v2_height, walkfromwp, bestdist))
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
	vector v = '0 0 0';
	//navigation_testtracewalk = true;
	int c = 0;
	float v_height = 0;
	IL_EACH(g_waypoints, !it.wpconsidered,
	{
		SET_TRACEWALK_DESTCOORDS(it, this.origin, v, v_height);

		vector diff = v - this.origin;
		diff.z = max(0, diff.z);
		if(vdist(diff, <, maxdist))
		{
			it.wpconsidered = true;
			if (tracewalk(this, this.origin, this.mins, this.maxs, v, v_height, bot_navigation_movemode))
			{
				it.wpnearestpoint = v;
				it.wpcost = waypoint_gettravelcost(this.origin, v, this, it) + it.dmg;
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
void navigation_markroutes_checkwaypoint(entity w, entity wp, float cost, vector p)
{
	vector m1, m2;
	vector v;
	if (wp.wpisbox)
	{
		m1 = wp.origin + wp.mins;
		m2 = wp.origin + wp.maxs;
		v.x = bound(m1_x, p.x, m2_x);
		v.y = bound(m1_y, p.y, m2_y);
		v.z = bound(m1_z, p.z, m2_z);
	}
	else
		v = wp.origin;
	if (w.wpflags & WAYPOINTFLAG_TELEPORT)
		cost += w.wp00mincost; // assuming teleport has exactly one destination
	else
		cost += waypoint_gettravelcost(p, v, w, wp);
	if (wp.wpcost > cost)
	{
		wp.wpcost = cost;
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
			IL_EACH(g_waypoints, it != wp,
			{
				if(!waypoint_islinked(it, wp))
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

	rangebias = waypoint_getlinearcost(rangebias);
	f = waypoint_getlinearcost(f);

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

	vector goal_org = (e.absmin + e.absmax) * 0.5;

	//print("routerating ", etos(e), " = ", ftos(f), " - ", ftos(rangebias), "\n");

	// Evaluate path using jetpack
	if(g_jetpack)
	if(this.items & IT_JETPACK)
	if(autocvar_bot_ai_navigation_jetpack)
	if(vdist(this.origin - goal_org, >, autocvar_bot_ai_navigation_jetpack_mindistance))
	{
		vector pointa, pointb;

		LOG_DEBUG("jetpack ai: evaluating path for ", e.classname);

		// Point A
		traceline(this.origin, this.origin + '0 0 65535', MOVE_NORMAL, this);
		pointa = trace_endpos - '0 0 1';

		// Point B
		traceline(goal_org, goal_org + '0 0 65535', MOVE_NORMAL, e);
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
			{
				e.nearestwaypoint = nwp;

				vector m1 = nwp.absmin, m2 = nwp.absmax;
				m1.x = nwp.origin.x; m1.y = nwp.origin.y;
				m2.x = nwp.origin.x; m2.y = nwp.origin.y;
				vector ve = (e.absmin - e.absmax) * 0.5;
				ve.x = bound(m1.x, ve.x, m2.x);
				ve.y = bound(m1.y, ve.y, m2.y);
				ve.z = bound(m1.z, ve.z, m2.z);

				m1 = e.absmin; m2 = e.absmax;
				m1.x = e.origin.x; m1.y = e.origin.y;
				m2.x = e.origin.x; m2.y = e.origin.y;
				vector vnwp = nwp.origin;
				vnwp.x = bound(m1.x, vnwp.x, m2.x);
				vnwp.y = bound(m1.y, vnwp.y, m2.y);
				vnwp.z = bound(m1.z, vnwp.z, m2.z);
				e.nearestwaypoint_dist = vlen(ve - vnwp);
			}
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
		float cost = nwp.wpcost + waypoint_gettravelcost(nwp.wpnearestpoint, goal_org, nwp, e);
		LOG_DEBUG(e.classname, " ", ftos(f), "/(1+", ftos(cost), "/", ftos(rangebias), ") = ");
		f = f * rangebias / (rangebias + cost);
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

	entity teleport_goal = NULL;

	this.goalentity = e;

	if(e.wpflags & WAYPOINTFLAG_TELEPORT)
	{
		// force teleport destination as route destination
		teleport_goal = e;
		navigation_pushroute(this, e.wp00);
		this.goalentity = e.wp00;
	}

	// put the entity on the goal stack
	//print("routetogoal ", etos(e), "\n");
	navigation_pushroute(this, e);

	if(teleport_goal)
		e = this.goalentity;

	if(e.classname == "waypoint" && !(e.wpflags & WAYPOINTFLAG_PERSONAL))
	{
		this.wp_goal_prev1 = this.wp_goal_prev0;
		this.wp_goal_prev0 = e;
	}

	if(g_jetpack)
	if(e==this.navigation_jetpack_goal)
		return true;

	// if it can reach the goal there is nothing more to do
	vector dest = '0 0 0';
	float dest_height = 0;
	SET_TRACEWALK_DESTCOORDS(e, startposition, dest, dest_height);
	if (tracewalk(this, startposition, STAT(PL_MIN, this), STAT(PL_MAX, this), dest, dest_height, bot_navigation_movemode))
		return true;

	entity nearest_wp = NULL;
	// see if there are waypoints describing a path to the item
	if(e.classname != "waypoint" || (e.wpflags & WAYPOINTFLAG_PERSONAL))
	{
		e = e.nearestwaypoint;
		nearest_wp = e;
	}
	else if(teleport_goal)
		e = teleport_goal;
	else
		e = e.enemy; // we already have added it, so...

	if(e == NULL)
		return false;

	if(nearest_wp && nearest_wp.enemy)
	{
		// often path can be optimized by not adding the nearest waypoint
		if (this.goalentity.nearestwaypoint_dist < 8)
			e = nearest_wp.enemy;
		else
		{
			if (this.goalentity.navigation_dynamicgoal || autocvar_g_waypointeditor)
			{
				SET_TRACEWALK_DESTCOORDS(e, nearest_wp.enemy.origin, dest, dest_height);
				if(vdist(dest - nearest_wp.enemy.origin, <, 1050))
				if(tracewalk(this, nearest_wp.enemy.origin, STAT(PL_MIN, this), STAT(PL_MAX, this), dest, dest_height, bot_navigation_movemode))
					e = nearest_wp.enemy;
			}
			else if(navigation_item_islinked(nearest_wp.enemy, this.goalentity))
				e = nearest_wp.enemy;
		}
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
int navigation_poptouchedgoals(entity this)
{
	int removed_goals = 0;
	if(this.goalcurrent.wpflags & WAYPOINTFLAG_TELEPORT)
	{
		// make sure jumppad is really hit, don't rely on distance based checks
		// as they may report a touch even if it didn't really happen
		if(this.lastteleporttime > 0
			&& time - this.lastteleporttime < ((this.goalcurrent.wpflags & WAYPOINTFLAG_PERSONAL) ? 2 : 0.15))
		{
			if(this.aistatus & AI_STATUS_WAYPOINT_PERSONAL_GOING)
			if(this.goalcurrent.wpflags & WAYPOINTFLAG_PERSONAL && this.goalcurrent.owner==this)
			{
				this.aistatus &= ~AI_STATUS_WAYPOINT_PERSONAL_GOING;
				this.aistatus |= AI_STATUS_WAYPOINT_PERSONAL_REACHED;
			}
			navigation_poproute(this);
			++removed_goals;
		}
		else
			return removed_goals;
	}

	// If for some reason the bot is closer to the next goal, pop the current one
	if(this.goalstack01 && !wasfreed(this.goalstack01))
	if(vlen2(this.goalcurrent.origin - this.origin) > vlen2(this.goalstack01.origin - this.origin))
	if(checkpvs(this.origin + this.view_ofs, this.goalstack01))
	{
		vector dest = '0 0 0';
		float dest_height = 0;
		SET_TRACEWALK_DESTCOORDS(this.goalstack01, this.origin, dest, dest_height);
		if(tracewalk(this, this.origin, this.mins, this.maxs, dest, dest_height, bot_navigation_movemode))
		{
			LOG_DEBUG("path optimized for ", this.netname, ", removed a goal from the queue");
			navigation_poproute(this);
			++removed_goals;
			if(this.goalcurrent && this.goalcurrent.wpflags & WAYPOINTFLAG_TELEPORT)
				return removed_goals;
			// TODO this may also be a nice idea to do "early" (e.g. by
			// manipulating the vlen() comparisons) to shorten paths in
			// general - this would make bots walk more "on rails" than
			// "zigzagging" which they currently do with sufficiently
			// random-like waypoints, and thus can make a nice bot
			// personality property
		}
	}

	// Loose goal touching check when running
	if(this.aistatus & AI_STATUS_RUNNING)
	if(this.goalcurrent.classname=="waypoint")
	if(vdist(vec2(this.velocity), >=, autocvar_sv_maxspeed)) // if -really- running
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
				++removed_goals;
				if(this.goalcurrent && this.goalcurrent.wpflags & WAYPOINTFLAG_TELEPORT)
					return removed_goals;
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
		if(!boxesoverlap(this.absmin, this.absmax, gc_min, gc_max))
			break;

		// Detect personal waypoints
		if(this.aistatus & AI_STATUS_WAYPOINT_PERSONAL_GOING)
		if(this.goalcurrent.wpflags & WAYPOINTFLAG_PERSONAL && this.goalcurrent.owner==this)
		{
			this.aistatus &= ~AI_STATUS_WAYPOINT_PERSONAL_GOING;
			this.aistatus |= AI_STATUS_WAYPOINT_PERSONAL_REACHED;
		}

		navigation_poproute(this);
		++removed_goals;
		if(this.goalcurrent && this.goalcurrent.wpflags & WAYPOINTFLAG_TELEPORT)
			return removed_goals;
	}
	return removed_goals;
}

entity navigation_get_really_close_waypoint(entity this)
{
	entity wp = this.goalcurrent;
	if(!wp || vdist(wp.origin - this.origin, >, 50))
		wp = this.goalcurrent_prev;
	if(!wp)
		return NULL;
	if(wp.classname != "waypoint")
	{
		wp = wp.nearestwaypoint;
		if(!wp)
			return NULL;
	}
	if(vdist(wp.origin - this.origin, >, 50))
	{
		IL_EACH(g_waypoints, !(it.wpflags & WAYPOINTFLAG_TELEPORT),
		{
			if(vdist(it.origin - this.origin, <, 50))
			{
				wp = it;
				break;
			}
		});
	}
	if(wp.wpflags & WAYPOINTFLAG_TELEPORT)
		return NULL;

	vector dest = '0 0 0';
	float dest_height = 0;
	SET_TRACEWALK_DESTCOORDS(wp, this.origin, dest, dest_height);
	if (!tracewalk(this, this.origin, STAT(PL_MIN, this), STAT(PL_MAX, this), dest, dest_height, bot_navigation_movemode))
		return NULL;
	return wp;
}

// begin a goal selection session (queries spawnfunc_waypoint network)
void navigation_goalrating_start(entity this)
{
	if(this.aistatus & AI_STATUS_STUCK)
		return;

	this.navigation_jetpack_goal = NULL;
	navigation_bestrating = -1;
	entity wp = navigation_get_really_close_waypoint(this);
	navigation_clearroute(this);
	navigation_bestgoal = NULL;
	navigation_markroutes(this, wp);
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
	entity wp_cur;
	IL_EACH(g_waypoints, true,
	{
		danger = 0;
		m1 = it.absmin;
		m2 = it.absmax;
		wp_cur = it;
		IL_EACH(g_bot_dodge, it.bot_dodge,
		{
			v = it.origin;
			v.x = bound(m1_x, v.x, m2_x);
			v.y = bound(m1_y, v.y, m2_y);
			v.z = bound(m1_z, v.z, m2_z);
			o = (it.absmin + it.absmax) * 0.5;
			d = waypoint_getlinearcost(it.bot_dodgerating) - waypoint_gettravelcost(o, v, it, wp_cur);
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
		vector dest = '0 0 0';
		float dest_height = 0;
		SET_TRACEWALK_DESTCOORDS(bot_waypoint_queue_goal, this.origin, dest, dest_height);
		if(tracewalk(bot_waypoint_queue_goal, this.origin, STAT(PL_MIN, this), STAT(PL_MAX, this), dest, dest_height, bot_navigation_movemode))
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
				navigation_goalrating_timeout_set(this);
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
