#include "navigation.qh"

#include <common/constants.qh>
#include <common/items/_mod.qh>
#include <common/mapobjects/func/ladder.qh>
#include <common/mapobjects/trigger/hurt.qh>
#include <common/mapobjects/trigger/jumppads.qh>
#include <common/mutators/mutator/status_effects/_mod.qh>
#include <common/net_linked.qh>
#include <common/stats.qh>
#include <common/weapons/_all.qh>
#include <server/bot/api.qh>
#include <server/bot/default/bot.qh>
#include <server/bot/default/cvars.qh>
#include <server/bot/default/waypoints.qh>
#include <server/items/items.qh>

.float speed;

void navigation_goalrating_timeout_set(entity this)
{
	if(IS_MOVABLE(this.goalentity))
		this.bot_strategytime = time + autocvar_bot_ai_strategyinterval_movingtarget;
	else
		this.bot_strategytime = time + autocvar_bot_ai_strategyinterval;
}

// use this when current goal must be discarded immediately
void navigation_goalrating_timeout_force(entity this)
{
	navigation_goalrating_timeout_expire(this, 0);
}

// use this when current goal can be kept for a short while to increase the chance
// of bot touching a waypoint, which helps to find a new goal more efficiently
void navigation_goalrating_timeout_expire(entity this, float seconds)
{
	if (seconds <= 0)
		this.bot_strategytime = 0;
	else if (this.bot_strategytime > time + seconds)
		this.bot_strategytime = time + seconds;
}

bool navigation_goalrating_timeout(entity this)
{
	return this.bot_strategytime < time;
}

ERASEABLE
void navigation_goalrating_timeout_extend_if_needed(entity this, float seconds)
{
	this.bot_strategytime = max(this.bot_strategytime, time + seconds);
}

#define MAX_CHASE_DISTANCE 700
bool navigation_goalrating_timeout_can_be_anticipated(entity this)
{
	vector gco = (this.goalentity.absmin + this.goalentity.absmax) * 0.5;
	if (vdist(gco - this.origin, >, autocvar_sv_maxspeed * 1.5)
		&& time > this.bot_strategytime - (IS_MOVABLE(this.goalentity) ? 3 : 2))
	{
		return true;
	}

	if (this.goalentity.bot_pickup && time > this.bot_strategytime - 5)
	{
		if(!havocbot_goalrating_item_pickable_check_players(this, this.origin, this.goalentity, gco))
		{
			this.ignoregoal = this.goalentity;
			this.ignoregoaltime = time + autocvar_bot_ai_ignoregoal_timeout;
			return true;
		}
	}
	return false;
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

void navigation_dynamicgoal_set(entity this, entity dropper)
{
	this.nearestwaypointtimeout = time;
	if (dropper && dropper.nearestwaypointtimeout && dropper.nearestwaypointtimeout < time + 2)
		this.nearestwaypoint = dropper.nearestwaypoint;
	if (this.nearestwaypoint)
		this.nearestwaypointtimeout += 2;
}

void navigation_dynamicgoal_unset(entity this)
{
	if(this.bot_basewaypoint)
		this.nearestwaypoint = this.bot_basewaypoint;
	this.nearestwaypointtimeout = -1;
}

// returns point of ent closer to org
vector get_closer_dest(entity ent, vector org)
{
	vector dest = '0 0 0';
	if ((ent.classname != "waypoint") || ent.wpisbox)
	{
		vector wm1 = ent.origin + ent.mins;
		vector wm2 = ent.origin + ent.maxs;
		dest.x = bound(wm1.x, org.x, wm2.x);
		dest.y = bound(wm1.y, org.y, wm2.y);
		dest.z = bound(wm1.z, org.z, wm2.z);
	}
	else
		dest = ent.origin;
	return dest;
}

void set_tracewalk_dest(entity ent, vector org, bool fix_player_dest)
{
	if ((ent.classname != "waypoint") || ent.wpisbox)
	{
		vector wm1 = ent.origin + ent.mins;
		vector wm2 = ent.origin + ent.maxs;
		if (IS_PLAYER(ent) || IS_MONSTER(ent))
		{
			// move destination point out of player bbox otherwise tracebox always fails
			// (if bot_navigation_ignoreplayers is false)
			wm1 += vec2(PL_MIN_CONST) + '-1 -1 0';
			wm2 += vec2(PL_MAX_CONST) + '1 1 0';
		}
		// set destination point to x and y coords of ent that are closer to org
		// z coord is set to ent's min height
		tracewalk_dest.x = bound(wm1.x, org.x, wm2.x);
		tracewalk_dest.y = bound(wm1.y, org.y, wm2.y);
		if ((IS_PLAYER(ent) || IS_MONSTER(ent))
			&& org.x == tracewalk_dest.x && org.y == tracewalk_dest.y && org.z > tracewalk_dest.z)
		{
			tracewalk_dest.z = wm2.z - PL_MIN_CONST.z;
			tracewalk_dest_height = 0;
			fix_player_dest = false;
		}
		else
		{
			tracewalk_dest.z = wm1.z;
			tracewalk_dest_height = wm2.z - wm1.z;
		}
	}
	else
	{
		tracewalk_dest = ent.origin;
		tracewalk_dest_height = 0;
	}
	if (fix_player_dest && IS_PLAYER(ent) && !IS_ONGROUND(ent))
	{
		// snap player to the ground
		if (org.x == tracewalk_dest.x && org.y == tracewalk_dest.y)
		{
			// bot is right under the player
			tracebox(ent.origin, ent.mins, ent.maxs, ent.origin - '0 0 700', MOVE_NORMAL, ent);
			tracewalk_dest = trace_endpos;
			tracewalk_dest_height = 0;
		}
		else
		{
			tracebox(tracewalk_dest, ent.mins, ent.maxs, tracewalk_dest - '0 0 700', MOVE_NORMAL, ent);
			if (!trace_startsolid && tracewalk_dest.z - trace_endpos.z > 0)
			{
				tracewalk_dest_height = tracewalk_dest.z - trace_endpos.z;
				tracewalk_dest.z = trace_endpos.z;
			}
		}
	}
}

// returns point of ent closer to org
vector set_tracewalk_dest_2(entity ent, vector org)
{
	vector closer_dest = '0 0 0';
	if ((ent.classname != "waypoint") || ent.wpisbox)
	{
		vector wm1 = ent.origin + ent.mins;
		vector wm2 = ent.origin + ent.maxs;
		closer_dest.x = bound(wm1.x, org.x, wm2.x);
		closer_dest.y = bound(wm1.y, org.y, wm2.y);
		closer_dest.z = bound(wm1.z, org.z, wm2.z);
		// set destination point to x and y coords of ent that are closer to org
		// z coord is set to ent's min height
		tracewalk_dest.x = closer_dest.x;
		tracewalk_dest.y = closer_dest.y;
		tracewalk_dest.z = wm1.z;
		tracewalk_dest_height = wm2.z - wm1.z; // destination height
	}
	else
	{
		closer_dest = ent.origin;
		tracewalk_dest = closer_dest;
		tracewalk_dest_height = 0;
	}
	return closer_dest;
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
	IL_EACH(g_ladders, true,
	{
		if(it.bot_pickup)
		if(boxesoverlap(org + m1, org + m2, it.absmin, it.absmax))
		if(boxesoverlap(end, end2, it.absmin + vec2(m1), it.absmax + vec2(m2)))
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

// Unfortuntely we can't use trace_inwater since it doesn't hold the fraction of the total
// distance that was traveled before impact as the description in the engine (collision.h) says.
// It would have helped to speed up tracewalk underwater
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
// INFO: the command sv_cmd trace walk is useful to test this function in game
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
	if (IN_LAVA(start))
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
	this.lastteleporttime = 0;
	this.goalcurrent_prev = this.goalcurrent;
	this.goalcurrent_distance_2d = FLOAT_MAX;
	this.goalcurrent_distance_z = FLOAT_MAX;
	this.goalcurrent_distance_time = 0;
	this.goalentity_lock_timeout = 0;
	this.goalentity_shouldbefrozen = false;
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
	this.goalcurrent_distance_2d = FLOAT_MAX;
	this.goalcurrent_distance_z = FLOAT_MAX;
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
	this.goalcurrent_distance_2d = FLOAT_MAX;
	this.goalcurrent_distance_z = FLOAT_MAX;
	this.goalcurrent_distance_time = 0;
	//print("bot ", etos(this), " pop\n");
	if(this.goalcurrent == this.goalentity)
	{
		this.goalentity = NULL;
		this.goalentity_lock_timeout = 0;
	}
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

	if (waypointeditor_enabled && !IS_BOT_CLIENT(ent))
	{
		// this code allows removing waypoints in the air and seeing jumppad/telepport waypoint links
		// FIXME it causes a bug where a waypoint spawned really close to another one (max 16 qu)
		// isn't detected as the nearest waypoint
		IL_EACH(g_waypoints, it != ent && it != except,
		{
			if (boxesoverlap(pm1, pm2, it.absmin, it.absmax))
				return it;
		});
	}
	else
	{
		// do two scans, because box test is cheaper
		IL_EACH(g_waypoints, it != ent && it != except && !(it.wpflags & (WAYPOINTFLAG_TELEPORT | WAYPOINTFLAG_JUMP)),
		{
			if(boxesoverlap(pm1, pm2, it.absmin, it.absmax))
			{
				if(walkfromwp && !ent.navigation_dynamicgoal)
					waypoint_clearlinks(ent); // initialize wpXXmincost fields
				return it;
			}
		});
	}

	vector org = ent.origin;
	if (navigation_testtracewalk)
		te_plasmaburn(org);

	entity best = NULL;
	vector v = '0 0 0';

	if(ent.size && !IS_PLAYER(ent))
	{
		org += 0.5 * (ent.mins + ent.maxs);
		org.z = ent.origin.z + ent.mins.z - PL_MIN_CONST.z; // player height
	}

	// box check failed, try walk
	IL_EACH(g_waypoints, it != ent,
	{
		if (walkfromwp && (it.wpflags & WPFLAGMASK_NORELINK))
			continue;
		v = it.origin;

		if (walkfromwp)
		{
			set_tracewalk_dest(ent, v, true);
			if (trace_ent == ent)
			{
				bestdist = 0;
				best = it;
				break;
			}
		}
		else
			set_tracewalk_dest(it, org, false);

		if (navigation_waypoint_will_link(v, org, ent,
			tracewalk_dest, tracewalk_dest_height,
			tracewalk_dest, tracewalk_dest_height, walkfromwp, bestdist))
		{
			if (walkfromwp)
				bestdist = vlen(tracewalk_dest - v);
			else
				bestdist = vlen(v - org);
			best = it;
		}
	});
	if(!best && !ent.navigation_dynamicgoal)
	{
		int solid_save = ent.solid;
		ent.solid = SOLID_BSP;
		IL_EACH(g_jumppads, true,
		{
			if(trigger_push_test(it, ent))
			{
				best = it.nearestwaypoint;
				break;
			}
		});
		ent.solid = solid_save;
	}
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
	//navigation_testtracewalk = true;
	int c = 0;
	IL_EACH(g_waypoints, !it.wpconsidered,
	{
		set_tracewalk_dest(it, this.origin, false);

		vector diff = tracewalk_dest - this.origin;
		diff.z = max(0, diff.z);
		if(vdist(diff, <, maxdist))
		{
			it.wpconsidered = true;
			if (tracewalk(this, this.origin, this.mins, this.maxs,
				tracewalk_dest, tracewalk_dest_height, bot_navigation_movemode))
			{
				it.wpnearestpoint = tracewalk_dest;
				it.wpcost = waypoint_gettravelcost(this.origin, tracewalk_dest, this, it) + it.dmg;
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
	if (!e || e.blacklisted) { return; }

	rangebias = waypoint_getlinearcost(rangebias);
	f = waypoint_getlinearcost(f);

	if (IS_PLAYER(e))
	{
		bool rate_wps = false;
		if (e.watertype < CONTENT_WATER || (e.waterlevel > WATERLEVEL_WETFEET && !STAT(FROZEN, e))
			|| (e.flags & FL_PARTIALGROUND))
		{
			rate_wps = true;
		}

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
			float best_dist = FLOAT_MAX;
			IL_EACH(g_waypoints, !(it.wpflags & WAYPOINTFLAG_TELEPORT)
				&& vdist(it.origin - theEnemy.origin, <, 500)
				&& vdist(it.origin - this.origin, >, 100)
				&& vdist(it.origin - this.origin, <, 10000),
			{
				float dist = vlen2(it.origin - theEnemy.origin);
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

			LOG_DEBUG("jetpack ai: required fuel ", ftos(fuel), ", have ", ftos(GetResource(this, RES_FUEL)));

			// enough fuel ?
			if(GetResource(this, RES_FUEL) > fuel || (this.items & IT_UNLIMITED_AMMO))
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
		if(waypointeditor_enabled && e.nearestwaypointtimeout >= 0 && time > e.nearestwaypointtimeout)
			e.nearestwaypoint = NULL;

		if ((!e.nearestwaypoint || e.navigation_dynamicgoal)
			&& e.nearestwaypointtimeout >= 0 && time > e.nearestwaypointtimeout)
		{
			if(IS_BOT_CLIENT(e) && e.goalcurrent && e.goalcurrent.classname == "waypoint")
				e.nearestwaypoint = nwp = e.goalcurrent;
			else
				e.nearestwaypoint = nwp = navigation_findnearestwaypoint(e, true);
			if(!nwp)
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
			else if(waypointeditor_enabled)
				e.nearestwaypointtimeout = time + 3 + random() * 2;
		}
		nwp = e.nearestwaypoint;
	}

	if (nwp && nwp.wpcost < 10000000)
	{
		//te_wizspike(nwp.wpnearestpoint);
		float nwptoitem_cost = 0;
		if(nwp.wpflags & WAYPOINTFLAG_TELEPORT)
			nwptoitem_cost = nwp.wp00mincost;
		else
			nwptoitem_cost = waypoint_gettravelcost(nwp.wpnearestpoint, goal_org, nwp, e);
		float cost = nwp.wpcost + nwptoitem_cost;
		LOG_DEBUG("checking ^5", e.classname, "^7 with base rating ^xf04", ftos(f), "^7 and rangebias ^xf40", ftos(rangebias));
		f = f * rangebias / (rangebias + cost);
		LOG_DEBUG("         ^5", e.classname, "^7 with cost ^6", ftos(cost), "^7 and final rating ^2", ftos(f));
		if (navigation_bestrating < f)
		{
			LOG_DEBUG(" ground path: ^3added goal ^5", e.classname);
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

	if((this.items & IT_JETPACK) && e == this.navigation_jetpack_goal)
		return true;

	// if it can reach the goal there is nothing more to do
	set_tracewalk_dest(e, startposition, true);
	if ((!IS_MOVABLE(this.goalcurrent) || vdist(tracewalk_dest - this.origin, <, MAX_CHASE_DISTANCE))
		&& (trace_ent == this || tracewalk(this, startposition, STAT(PL_MIN, this), STAT(PL_MAX, this),
		tracewalk_dest, tracewalk_dest_height, bot_navigation_movemode)))
	{
		return true;
	}

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

	if(nearest_wp && nearest_wp.enemy && !(nearest_wp.enemy.wpflags & WPFLAGMASK_NORELINK))
	{
		// often path can be optimized by not adding the nearest waypoint
		if (this.goalentity.navigation_dynamicgoal || waypointeditor_enabled)
		{
			if (nearest_wp.enemy.wpcost < autocvar_bot_ai_strategyinterval_movingtarget)
			{
				if (vdist(vec2(this.goalentity.origin - nearest_wp.origin), <, 32))
					e = nearest_wp.enemy;
				else
				{
					set_tracewalk_dest(this.goalentity, nearest_wp.enemy.origin, true);
					if (trace_ent == this || (vdist(tracewalk_dest - nearest_wp.enemy.origin, <, 1050)
						&& vlen2(tracewalk_dest - nearest_wp.enemy.origin) < vlen2(nearest_wp.origin - nearest_wp.enemy.origin)
						&& tracewalk(this, nearest_wp.enemy.origin, STAT(PL_MIN, this), STAT(PL_MAX, this),
						tracewalk_dest, tracewalk_dest_height, bot_navigation_movemode)))
					{
						e = nearest_wp.enemy;
					}
				}
			}
		}
		else
		{
			// NOTE unlike waypoints, items hold incoming links
			navigation_item_initlinks_ifneeded(this.goalentity);
			int link_num = navigation_item_getlinknum(this.goalentity, nearest_wp.enemy);
			if (link_num >= 0)
			{
				if (navigation_item_iswalkablelink(this.goalentity, link_num))
					e = nearest_wp.enemy;
			}
			else // untested link
			{
				entity wp = nearest_wp.enemy;
				entity goal = this.goalentity;
				bool walkable = false;
				if (checkpvs(wp.origin, goal))
				{
					set_tracewalk_dest(goal, wp.origin, false);
					if (vdist(tracewalk_dest - wp.origin, <, 1050)
						&& tracewalk(goal, wp.origin, PL_MIN_CONST, PL_MAX_CONST,
						tracewalk_dest, tracewalk_dest_height, bot_navigation_movemode))
					{
						walkable = true;
						e = nearest_wp.enemy;
					}
				}
				navigation_item_add_link(wp, goal, walkable);
			}
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

// shorten path by removing intermediate goals
bool navigation_shortenpath(entity this)
{
	if (!this.goalstack01 || wasfreed(this.goalstack01))
		return false;
	if (this.bot_tracewalk_time > time)
		return false;
	this.bot_tracewalk_time = max(time, this.bot_tracewalk_time) + 0.25;

	bool cut_allowed = false;
	entity next = this.goalentity;
	// evaluate whether bot can discard current route and chase directly a player, trying to
	// keep waypoint route as long as possible, as it is safer and faster (bot can bunnyhop)
	if (IS_MOVABLE(next))
	{
		set_tracewalk_dest(next, this.origin, true);
		if (vdist(this.origin - tracewalk_dest, <, 200))
			cut_allowed = true;
		else if (vdist(tracewalk_dest - this.origin, <, MAX_CHASE_DISTANCE)
			&& vdist(tracewalk_dest - this.goalcurrent.origin, >, 200)
			&& vdist(this.origin - this.goalcurrent.origin, >, 100)
			&& checkpvs(this.origin + this.view_ofs, next))
		{
			if (vlen2(next.origin - this.origin) < vlen2(this.goalcurrent.origin - this.origin))
				cut_allowed = true;
			else
			{
				vector deviation = vectoangles(this.goalcurrent.origin - this.origin) - vectoangles(next.origin - this.origin);
				while (deviation.y < -180) deviation.y += 360;
				while (deviation.y > 180) deviation.y -= 360;
				if (fabs(deviation.y) > 25)
					cut_allowed = true;
			}
		}
		if (cut_allowed)
		{
			if (trace_ent == this || tracewalk(this, this.origin, this.mins, this.maxs,
				tracewalk_dest, tracewalk_dest_height, bot_navigation_movemode))
			{
				LOG_DEBUG("path optimized for ", this.netname, ", route cleared");
				do
				{
					navigation_poproute(this);
				}
				while (this.goalcurrent != next);
				return true;
			}
			return false;
		}
	}

	next = this.goalstack01;
	// if for some reason the bot is closer to the next goal, pop the current one
	if (!IS_MOVABLE(next) && !(this.goalcurrent.wpflags & (WAYPOINTFLAG_TELEPORT | WAYPOINTFLAG_JUMP))
		&& vlen2(this.goalcurrent.origin - next.origin) > vlen2(next.origin - this.origin)
		&& checkpvs(this.origin + this.view_ofs, next))
	{
		set_tracewalk_dest(next, this.origin, true);
		cut_allowed = true;
	}

	if (cut_allowed)
	{
		if (trace_ent == this || tracewalk(this, this.origin, this.mins, this.maxs,
			tracewalk_dest, tracewalk_dest_height, bot_navigation_movemode))
		{
			LOG_DEBUG("path optimized for ", this.netname, ", removed a goal from the queue");
			navigation_poproute(this);
			return true;
		}
	}
	return false;
}

// removes any currently touching waypoints from the goal stack
// (this is how bots detect if they reached a goal)
int navigation_poptouchedgoals(entity this)
{
	int removed_goals = 0;

	if(!this.goalcurrent)
		return removed_goals;

	if(this.goalcurrent.wpflags & WAYPOINTFLAG_TELEPORT)
	{
		if (!this.goalcurrent.wpisbox // warpzone
			&& vlen2(this.origin - this.goalstack01.origin) < vlen2(this.origin - this.goalcurrent.origin))
		{
			// immediately remove origin and destination waypoints
			navigation_poproute(this);
			++removed_goals;
			navigation_poproute(this);
			++removed_goals;
			this.lastteleporttime = 0;
		}

		// make sure jumppad is really hit, don't rely on distance based checks
		// as they may report a touch even if it didn't really happen
		if(this.lastteleporttime > 0 && TELEPORT_USED(this, this.goalcurrent))
		{
			if(this.aistatus & AI_STATUS_WAYPOINT_PERSONAL_GOING)
			if((this.goalcurrent.wpflags & WAYPOINTFLAG_PERSONAL) && this.goalcurrent.owner==this)
			{
				this.aistatus &= ~AI_STATUS_WAYPOINT_PERSONAL_GOING;
				this.aistatus |= AI_STATUS_WAYPOINT_PERSONAL_REACHED;
			}
			if(this.jumppadcount)
			{
				// remove jumppad waypoint after a random delay to prevent bots getting
				// stuck on certain jumppads that require an extra initial horizontal speed
				float max_delay = 0.1;
				if (vdist(vec2(this.velocity), >, 2 * autocvar_sv_maxspeed))
					max_delay = 0.05;
				if (time - this.lastteleporttime < random() * max_delay)
					return removed_goals;
			}
			else if (this.goalcurrent.wpisbox) // teleport
			{
				// immediately remove origin and destination waypoints
				navigation_poproute(this);
				++removed_goals;
			}
			navigation_poproute(this);
			this.lastteleporttime = 0;
			++removed_goals;
		}
		return removed_goals;
	}
	else if (this.lastteleporttime > 0)
	{
		// sometimes bot is pushed so hard (by a jumppad or a shot) that ends up touching the next
		// teleport / jumppad / warpzone present in its path skipping check of one or more goals
		// if so immediately fix bot path by removing skipped goals
		entity tele_ent = NULL;
		if (this.goalstack01 && (this.goalstack01.wpflags & WAYPOINTFLAG_TELEPORT))
			tele_ent = this.goalstack01;
		else if (this.goalstack02 && (this.goalstack02.wpflags & WAYPOINTFLAG_TELEPORT))
			tele_ent = this.goalstack02;
		else if (this.goalstack03 && (this.goalstack03.wpflags & WAYPOINTFLAG_TELEPORT))
			tele_ent = this.goalstack03;
		if (tele_ent && TELEPORT_USED(this, tele_ent))
		{
			if (this.aistatus & AI_STATUS_WAYPOINT_PERSONAL_GOING)
			if ((tele_ent.wpflags & WAYPOINTFLAG_PERSONAL) && tele_ent.owner == this)
			{
				this.aistatus &= ~AI_STATUS_WAYPOINT_PERSONAL_GOING;
				this.aistatus |= AI_STATUS_WAYPOINT_PERSONAL_REACHED;
			}
			while (this.goalcurrent != tele_ent)
			{
				navigation_poproute(this);
				++removed_goals;
			}
			navigation_poproute(this);
			this.lastteleporttime = 0;
			++removed_goals;
			return removed_goals;
		}
		// reset of lastteleporttime can be overriden by a jumppad when it's set
		// in more than one frame: make sure it's reset
		this.lastteleporttime = 0;
	}

	// Loose goal touching check when running
	// check goalstack01 to make sure waypoint isn't the final goal
	if((this.aistatus & AI_STATUS_RUNNING) && this.goalcurrent.classname == "waypoint" && !(this.goalcurrent.wpflags & WAYPOINTFLAG_JUMP)
		&& this.goalstack01 && !wasfreed(this.goalstack01) && vdist(vec2(this.velocity), >=, autocvar_sv_maxspeed))
	{
		vector gco = this.goalcurrent.origin;
		float min_dist = BOT_BUNNYHOP_WP_DETECTION_RANGE;
		// also detect waypoints when bot is way above them but with a narrower horizontal range
		// so to increase chances bot ends up in the standard range (optimizes nearest waypoint finding)
		if(vdist(this.origin - gco, <, min_dist)
			|| (vdist(vec2(this.origin - gco), <, min_dist * 0.5) && vdist(this.origin - eZ * 1.5 * min_dist - gco, <, min_dist)))
		{
			traceline(this.origin + this.view_ofs , this.goalcurrent.origin, true, NULL);
			if(trace_fraction==1)
			{
				// Detect personal waypoints
				if(this.aistatus & AI_STATUS_WAYPOINT_PERSONAL_GOING)
				if((this.goalcurrent.wpflags & WAYPOINTFLAG_PERSONAL) && this.goalcurrent.owner==this)
				{
					this.aistatus &= ~AI_STATUS_WAYPOINT_PERSONAL_GOING;
					this.aistatus |= AI_STATUS_WAYPOINT_PERSONAL_REACHED;
				}

				navigation_poproute(this);
				++removed_goals;
				if(this.goalcurrent && (this.goalcurrent.wpflags & WAYPOINTFLAG_TELEPORT))
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
			gc_max = this.goalcurrent.origin + '1 1 1' * 12 + eZ * (jumpheight_vec.z + STAT(PL_MIN, this).z);
		}
		if (this.ladder_entity)
		{
			if (!boxesoverlap(this.absmin, this.absmax - eZ * STAT(PL_MAX, this).z, gc_min, gc_max))
				break;
		}
		else
		{
			if (!boxesoverlap(this.absmin, this.absmax, gc_min, gc_max))
				break;
		}

		// Detect personal waypoints
		if(this.aistatus & AI_STATUS_WAYPOINT_PERSONAL_GOING)
		if((this.goalcurrent.wpflags & WAYPOINTFLAG_PERSONAL) && this.goalcurrent.owner==this)
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
	if(!wp)
		wp = this.goalcurrent_prev;
	if(!wp)
		return NULL;
	float min_dist = ((this.aistatus & AI_STATUS_RUNNING) ? BOT_BUNNYHOP_WP_DETECTION_RANGE : 50);
	if(wp != this.goalcurrent_prev && vdist(wp.origin - this.origin, >, min_dist))
	{
		wp = this.goalcurrent_prev;
		if(!wp)
			return NULL;
	}
	if(wp.classname != "waypoint")
	{
		wp = wp.nearestwaypoint;
		if(!wp)
			return NULL;
	}
	if(vdist(wp.origin - this.origin, >, min_dist))
	{
		wp = NULL;
		IL_EACH(g_waypoints, !(it.wpflags & (WAYPOINTFLAG_TELEPORT | WAYPOINTFLAG_JUMP)),
		{
			if(vdist(it.origin - this.origin, <, min_dist))
			{
				wp = it;
				break;
			}
		});
		if(!wp)
			return NULL;
	}
	if(wp.wpflags & WAYPOINTFLAG_TELEPORT)
		return NULL;

	set_tracewalk_dest(wp, this.origin, false);
	if (!tracewalk(this, this.origin, STAT(PL_MIN, this), STAT(PL_MAX, this),
		tracewalk_dest, tracewalk_dest_height, bot_navigation_movemode))
	{
		return NULL;
	}
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
	this.goalstack31 = wp; // temporarly save the really close waypoint
}

// ends a goal selection session (updates goal stack to the best goal)
void navigation_goalrating_end(entity this)
{
	if(this.aistatus & AI_STATUS_STUCK)
		return;

	entity wp = this.goalstack31; // save to wp as this.goalstack31 is set by navigation_routetogoal
	this.goalstack31 = NULL;

	navigation_routetogoal(this, navigation_bestgoal, this.origin);
	LOG_DEBUG("best goal ", navigation_bestgoal.classname);

	if (wp && this.goalcurrent == wp)
		navigation_poproute(this);

	// If the bot got stuck then try to reach the farthest waypoint
	if (!this.goalentity)
	{
		if (autocvar_bot_wander_enable && !(this.aistatus & AI_STATUS_STUCK))
		{
			LOG_DEBUG(this.netname, " cannot walk to any goal");
			this.aistatus |= AI_STATUS_STUCK;
		}
		this.goalentity_shouldbefrozen = false;
	}
	else
		this.goalentity_shouldbefrozen = boolean(STAT(FROZEN, this.goalentity));
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
	if (!autocvar_bot_wander_enable)
		return;

	bool has_user_waypoints = false;
	IL_EACH(g_waypoints, !(it.wpflags & WAYPOINTFLAG_GENERATED),
	{
		has_user_waypoints = true;
		break;
	});
	if (!has_user_waypoints)
		return;

	float search_radius = 1000;

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
		LOG_DEBUG(this.netname, " evaluating ", bot_waypoint_queue_goal.classname, " with squared distance ", ftos(d));
		set_tracewalk_dest(bot_waypoint_queue_goal, this.origin, false);
		if (tracewalk(this, this.origin, STAT(PL_MIN, this), STAT(PL_MAX, this),
			tracewalk_dest, tracewalk_dest_height, bot_navigation_movemode))
		{
			if( d > bot_waypoint_queue_bestgoalrating)
			{
				bot_waypoint_queue_bestgoalrating = d;
				bot_waypoint_queue_bestgoal = bot_waypoint_queue_goal;
			}
		}

		// move to a random waypoint while bot is searching for a walkable path;
		// this is usually sufficient to unstuck bots from bad spots or when other
		// bots of the same team block all their ways
		if (!bot_waypoint_queue_bestgoal && (!this.goalentity || random() < 0.1))
		{
			navigation_clearroute(this);
			navigation_routetogoal(this, bot_waypoint_queue_goal, this.origin);
			navigation_goalrating_timeout_expire(this, 1 + random() * 2);
		}

		bot_waypoint_queue_goal = bot_waypoint_queue_goal.bot_waypoint_queue_nextgoal;

		if (!bot_waypoint_queue_goal)
		{
			if (bot_waypoint_queue_bestgoal)
			{
				LOG_DEBUG(this.netname, " stuck, reachable waypoint found, heading to it");
				navigation_clearroute(this);
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
