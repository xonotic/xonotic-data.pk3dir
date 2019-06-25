#include "waypoints.qh"

#include <server/defs.qh>
#include <server/miscfunctions.qh>
#include "cvars.qh"

#include "bot.qh"
#include "navigation.qh"

#include <common/state.qh>

#include "../../antilag.qh"

#include <common/constants.qh>
#include <common/debug.qh>
#include <common/net_linked.qh>
#include <common/physics/player.qh>

#include <lib/warpzone/common.qh>
#include <lib/warpzone/util_server.qh>

.entity spawnpointmodel;
void waypoint_unreachable(entity pl)
{
	IL_EACH(g_waypoints, true,
	{
		it.colormod = '0.5 0.5 0.5';
		it.effects &= ~(EF_NODEPTHTEST | EF_RED | EF_BLUE);
	});

	entity e2 = navigation_findnearestwaypoint(pl, false);
	if(!e2)
	{
		LOG_INFO("Can't find any waypoint nearby\n");
		return;
	}

	navigation_markroutes(pl, e2);

	int j = 0;
	int m = 0;
	IL_EACH(g_waypoints, it.wpcost >= 10000000,
	{
		LOG_INFO("unreachable: ", etos(it), " ", vtos(it.origin), "\n");
		it.colormod_z = 8;
		it.effects |= EF_NODEPTHTEST | EF_BLUE;
		j++;
		m++;
	});
	if (j) LOG_INFOF("%d waypoints cannot be reached from here in any way (marked with blue light)\n", j);
	navigation_markroutes_inverted(e2);

	j = 0;
	IL_EACH(g_waypoints, it.wpcost >= 10000000,
	{
		LOG_INFO("cannot reach me: ", etos(it), " ", vtos(it.origin), "\n");
		it.colormod_x = 8;
		if (!(it.effects & EF_NODEPTHTEST))  // not already reported before
			m++;
		it.effects |= EF_NODEPTHTEST | EF_RED;
		j++;
	});
	if (j) LOG_INFOF("%d waypoints cannot walk to here in any way (marked with red light)\n", j);
	if (m) LOG_INFOF("%d waypoints have been marked total\n", m);

	j = 0;
	IL_EACH(g_spawnpoints, true,
	{
		if (navigation_findnearestwaypoint(it, false))
		{
			if(it.spawnpointmodel)
			{
				delete(it.spawnpointmodel);
				it.spawnpointmodel = NULL;
			}
		}
		else
		{
			if(!it.spawnpointmodel)
			{
				tracebox(it.origin, PL_MIN_CONST, PL_MAX_CONST, it.origin - '0 0 512', MOVE_NOMONSTERS, NULL);
				entity e = new(spawnpointmodel);
				vector org = trace_endpos + eZ;
				setorigin(e, org);
				e.solid = SOLID_TRIGGER;
				it.spawnpointmodel = e;
			}
			LOG_INFO("spawn without waypoint: ", etos(it), " ", vtos(it.origin), "\n");
			it.spawnpointmodel.effects |= EF_NODEPTHTEST;
			_setmodel(it.spawnpointmodel, pl.model);
			it.spawnpointmodel.frame = pl.frame;
			it.spawnpointmodel.skin = pl.skin;
			it.spawnpointmodel.colormap = pl.colormap;
			it.spawnpointmodel.colormod = pl.colormod;
			it.spawnpointmodel.glowmod = pl.glowmod;
			setsize(it.spawnpointmodel, PL_MIN_CONST, PL_MAX_CONST);
			j++;
		}
	});
	if (j) LOG_INFOF("%d spawnpoints have no nearest waypoint (marked by player model)\n", j);

	j = 0;
	IL_EACH(g_items, true,
	{
		it.effects &= ~(EF_NODEPTHTEST | EF_RED | EF_BLUE);
		it.colormod = '0.5 0.5 0.5';
	});
	IL_EACH(g_items, true,
	{
		if (navigation_findnearestwaypoint(it, false))
			continue;
		LOG_INFO("item without waypoint: ", etos(it), " ", vtos(it.origin), "\n");
		it.effects |= EF_NODEPTHTEST | EF_RED;
		it.colormod_x = 8;
		j++;
	});
	if (j) LOG_INFOF("%d items have no nearest waypoint and cannot be walked away from (marked with red light)\n", j);

	j = 0;
	IL_EACH(g_items, true,
	{
		if (navigation_findnearestwaypoint(it, true))
			continue;
		LOG_INFO("item without waypoint: ", etos(it), " ", vtos(it.origin), "\n");
		it.effects |= EF_NODEPTHTEST | EF_BLUE;
		it.colormod_z = 8;
		j++;
	});
	if (j) LOG_INFOF("%d items have no nearest waypoint and cannot be walked to (marked with blue light)\n", j);
}

void waypoint_getSymmetricalAxis_cmd(entity caller, bool save, int arg_idx)
{
	vector v1 = stov(argv(arg_idx++));
	vector v2 = stov(argv(arg_idx++));
	vector mid = (v1 + v2) / 2;

	float diffy = (v2.y - v1.y);
	float diffx = (v2.x - v1.x);
	if (v1.y == v2.y)
		diffy = 0.000001;
	if (v1.x == v2.x)
		diffx = 0.000001;
	float m = - diffx / diffy;
	float q = - m * mid.x + mid.y;
	if (fabs(m) <= 0.000001) m = 0;
	if (fabs(q) <= 0.000001) q = 0;

	string axis_str =  strcat(ftos(m), " ", ftos(q));
	if (save)
		cvar_set("g_waypointeditor_symmetrical_axis", axis_str);
	axis_str = strcat("\"", axis_str, "\"");
	sprint(caller, strcat("Axis of symmetry based on input points: ", axis_str, "\n"));
	if (save)
		sprint(caller, sprintf(" ^3saved to %s\n", "g_waypointeditor_symmetrical_axis"));
	if (save)
	{
		cvar_set("g_waypointeditor_symmetrical", "-2");
		sprint(caller, strcat("g_waypointeditor_symmetrical", " has been set to ",
			cvar_string("g_waypointeditor_symmetrical"), "\n"));
	}
}

void waypoint_getSymmetricalOrigin_cmd(entity caller, bool save, int arg_idx)
{
	vector org = '0 0 0';
	int ctf_flags = 0;
	for (int i = 0; i < 6; i++)
	{
		if (argv(arg_idx + i) != "")
			ctf_flags++;
	}
	if (ctf_flags < 2)
	{
		ctf_flags = 0;
		org = vec2(havocbot_middlepoint);
		if (argv(arg_idx) != "")
			sprint(caller, "WARNING: Ignoring single input point\n");
		if (havocbot_middlepoint_radius == 0)
		{
			sprint(caller, "Origin of symmetry can't be automatically determined\n");
			return;
		}
	}
	else
	{
		vector v1, v2, v3, v4, v5, v6;
		for (int i = 1; i <= ctf_flags; i++)
		{
			if (i == 1) { v1 = stov(argv(arg_idx++)); org = v1 / ctf_flags; }
			else if (i == 2) { v2 = stov(argv(arg_idx++)); org += v2 / ctf_flags; }
			else if (i == 3) { v3 = stov(argv(arg_idx++)); org += v3 / ctf_flags; }
			else if (i == 4) { v4 = stov(argv(arg_idx++)); org += v4 / ctf_flags; }
			else if (i == 5) { v5 = stov(argv(arg_idx++)); org += v5 / ctf_flags; }
			else if (i == 6) { v6 = stov(argv(arg_idx++)); org += v6 / ctf_flags; }
		}
	}

	if (fabs(org.x) <= 0.000001) org.x = 0;
	if (fabs(org.y) <= 0.000001) org.y = 0;
	string org_str = strcat(ftos(org.x), " ", ftos(org.y));
	if (save)
	{
		cvar_set("g_waypointeditor_symmetrical_origin", org_str);
		cvar_set("g_waypointeditor_symmetrical_order", ftos(ctf_flags));
	}
	org_str = strcat("\"", org_str, "\"");

	if (ctf_flags < 2)
		sprint(caller, strcat("Origin of symmetry based on flag positions: ", org_str, "\n"));
	else
		sprint(caller, strcat("Origin of symmetry based on input points: ", org_str, "\n"));
	if (save)
		sprint(caller, sprintf(" ^3saved to %s\n", "g_waypointeditor_symmetrical_origin"));

	if (ctf_flags < 2)
		sprint(caller, "Order of symmetry: 0 (autodetected)\n");
	else
		sprint(caller, strcat("Order of symmetry: ", ftos(ctf_flags), "\n"));
	if (save)
		sprint(caller, sprintf(" ^3saved to %s\n", "g_waypointeditor_symmetrical_order"));

	if (save)
	{
		if (ctf_flags < 2)
			cvar_set("g_waypointeditor_symmetrical", "0");
		else
			cvar_set("g_waypointeditor_symmetrical", "-1");
		sprint(caller, strcat("g_waypointeditor_symmetrical", " has been set to ",
			cvar_string("g_waypointeditor_symmetrical"), "\n"));
	}
}

vector waypoint_getSymmetricalPoint(vector org, int ctf_flags)
{
	vector new_org = org;
	if (fabs(autocvar_g_waypointeditor_symmetrical) == 1)
	{
		vector map_center = havocbot_middlepoint;
		if (autocvar_g_waypointeditor_symmetrical == -1)
			map_center = autocvar_g_waypointeditor_symmetrical_origin;

		new_org = Rotate(org - map_center, 360 * DEG2RAD / ctf_flags) + map_center;
	}
	else if (fabs(autocvar_g_waypointeditor_symmetrical) == 2)
	{
		float m = havocbot_symmetry_axis_m;
		float q = havocbot_symmetry_axis_q;
		if (autocvar_g_waypointeditor_symmetrical == -2)
		{
			m = autocvar_g_waypointeditor_symmetrical_axis.x;
			q = autocvar_g_waypointeditor_symmetrical_axis.y;
		}

		new_org.x = (1 / (1 + m*m)) * ((1 - m*m) * org.x + 2 * m * org.y - 2 * m * q);
		new_org.y = (1 / (1 + m*m)) * (2 * m * org.x + (m*m - 1) * org.y + 2 * q);
	}
	new_org.z = org.z;
	return new_org;
}

void waypoint_setupmodel(entity wp)
{
	if (autocvar_g_waypointeditor)
	{
		// TODO: add some sort of visible box in edit mode for box waypoints
		vector m1 = wp.mins;
		vector m2 = wp.maxs;
		setmodel(wp, MDL_WAYPOINT);
		setsize(wp, m1, m2);
		wp.effects = EF_LOWPRECISION;
		if (wp.wpflags & WAYPOINTFLAG_ITEM)
			wp.colormod = '1 0 0';
		else if (wp.wpflags & WAYPOINTFLAG_GENERATED)
			wp.colormod = '1 1 0';
		else if (wp.wphardwired)
			wp.colormod = '0.5 0 1';
		else
			wp.colormod = '1 1 1';
	}
	else
		wp.model = "";
}

entity waypoint_spawn(vector m1, vector m2, float f)
{
	if(!(f & (WAYPOINTFLAG_PERSONAL | WAYPOINTFLAG_GENERATED)) && m1 == m2)
	{
		vector em1 = m1 - '8 8 8';
		vector em2 = m2 + '8 8 8';
		IL_EACH(g_waypoints, boxesoverlap(em1, em2, it.absmin, it.absmax),
		{
			return it;
		});
	}
	// spawn only one destination waypoint for teleports teleporting player to the exact same spot
	// otherwise links loaded from file would be applied only to the first destination
	// waypoint since link format doesn't specify waypoint entities but just positions
	if((f & WAYPOINTFLAG_GENERATED) && !(f & (WAYPOINTFLAG_NORELINK | WAYPOINTFLAG_PERSONAL)) && m1 == m2)
	{
		IL_EACH(g_waypoints, boxesoverlap(m1, m2, it.absmin, it.absmax),
		{
			return it;
		});
	}

	entity w = new(waypoint);
	IL_PUSH(g_waypoints, w);
	w.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_PLAYERCLIP | DPCONTENTS_BOTCLIP;
	w.wpflags = f;
	w.solid = SOLID_TRIGGER;
	setorigin(w, (m1 + m2) * 0.5);
	setsize(w, m1 - w.origin, m2 - w.origin);
	if (w.size)
		w.wpisbox = true;

	if(!w.wpisbox)
	{
		setsize(w, PL_MIN_CONST - '1 1 0', PL_MAX_CONST + '1 1 0');
		if(!move_out_of_solid(w))
		{
			if(!(f & WAYPOINTFLAG_GENERATED))
			{
				LOG_TRACE("Killed a waypoint that was stuck in solid at ", vtos(w.origin));
				delete(w);
				return NULL;
			}
			else
			{
				if(autocvar_developer)
				{
					LOG_INFO("A generated waypoint is stuck in solid at ", vtos(w.origin));
					backtrace("Waypoint stuck");
				}
			}
		}
		setsize(w, '0 0 0', '0 0 0');
	}

	waypoint_clearlinks(w);
	//waypoint_schedulerelink(w);

	waypoint_setupmodel(w);

	return w;
}

void waypoint_spawn_fromeditor(entity pl)
{
	entity e;
	vector org = pl.origin;
	int ctf_flags = havocbot_symmetry_origin_order;
	bool sym = ((autocvar_g_waypointeditor_symmetrical > 0 && ctf_flags >= 2)
	           || (autocvar_g_waypointeditor_symmetrical < 0));
	if(autocvar_g_waypointeditor_symmetrical_order >= 2)
		ctf_flags = autocvar_g_waypointeditor_symmetrical_order;
	if (sym && ctf_flags < 2)
		ctf_flags = 2;
	int wp_num = ctf_flags;

	if(!PHYS_INPUT_BUTTON_CROUCH(pl))
	{
		// snap waypoint to item's origin if close enough
		IL_EACH(g_items, true,
		{
			vector item_org = (it.absmin + it.absmax) * 0.5;
			item_org.z = it.absmin.z - PL_MIN_CONST.z;
			if (vlen(item_org - org) < 20)
			{
				org = item_org;
				break;
			}
		});
	}

	LABEL(add_wp);
	e = waypoint_spawn(org, org, 0);
	if(!e)
	{
		LOG_INFOF("Couldn't spawn waypoint at %v\n", org);
		return;
	}
	waypoint_schedulerelink(e);
	bprint(strcat("Waypoint spawned at ", vtos(e.origin), "\n"));
	if(sym)
	{
		org = waypoint_getSymmetricalPoint(e.origin, ctf_flags);
		if (vdist(org - pl.origin, >, 32))
		{
			if(wp_num > 2)
				wp_num--;
			else
				sym = false;
			goto add_wp;
		}
	}
}

void waypoint_remove(entity wp)
{
	IL_EACH(g_waypoints, it != wp,
	{
		if (waypoint_islinked(it, wp))
			waypoint_removelink(it, wp);
	});
	delete(wp);
}

void waypoint_remove_fromeditor(entity pl)
{
	entity e = navigation_findnearestwaypoint(pl, false);

	int ctf_flags = havocbot_symmetry_origin_order;
	bool sym = ((autocvar_g_waypointeditor_symmetrical > 0 && ctf_flags >= 2)
	           || (autocvar_g_waypointeditor_symmetrical < 0));
	if(autocvar_g_waypointeditor_symmetrical_order >= 2)
		ctf_flags = autocvar_g_waypointeditor_symmetrical_order;
	if (sym && ctf_flags < 2)
		ctf_flags = 2;
	int wp_num = ctf_flags;

	LABEL(remove_wp);
	if (!e) return;
	if (e.wpflags & WAYPOINTFLAG_GENERATED) return;

	if (e.wphardwired)
	{
		LOG_INFO("^1Warning: ^7Removal of hardwired waypoints is not allowed in the editor. Please remove links from/to this waypoint (", vtos(e.origin), ") by hand from maps/", mapname, ".waypoints.hardwired\n");
		return;
	}

	entity wp_sym = NULL;
	if (sym)
	{
		vector org = waypoint_getSymmetricalPoint(e.origin, ctf_flags);
		FOREACH_ENTITY_CLASS("waypoint", !(it.wpflags & WAYPOINTFLAG_GENERATED), {
			if(vdist(org - it.origin, <, 3))
			{
				wp_sym = it;
				break;
			}
		});
	}

	bprint(strcat("Waypoint removed at ", vtos(e.origin), "\n"));
	waypoint_remove(e);

	if (sym && wp_sym)
	{
		e = wp_sym;
		if(wp_num > 2)
			wp_num--;
		else
			sym = false;
		goto remove_wp;
	}
}

void waypoint_removelink(entity from, entity to)
{
	if (from == to || (from.wpflags & WAYPOINTFLAG_NORELINK))
		return;

	entity fromwp31_prev = from.wp31;

	switch (waypoint_getlinknum(from, to))
	{
		// fallthrough all the way
		case  0: from.wp00 = from.wp01; from.wp00mincost = from.wp01mincost;
		case  1: from.wp01 = from.wp02; from.wp01mincost = from.wp02mincost;
		case  2: from.wp02 = from.wp03; from.wp02mincost = from.wp03mincost;
		case  3: from.wp03 = from.wp04; from.wp03mincost = from.wp04mincost;
		case  4: from.wp04 = from.wp05; from.wp04mincost = from.wp05mincost;
		case  5: from.wp05 = from.wp06; from.wp05mincost = from.wp06mincost;
		case  6: from.wp06 = from.wp07; from.wp06mincost = from.wp07mincost;
		case  7: from.wp07 = from.wp08; from.wp07mincost = from.wp08mincost;
		case  8: from.wp08 = from.wp09; from.wp08mincost = from.wp09mincost;
		case  9: from.wp09 = from.wp10; from.wp09mincost = from.wp10mincost;
		case 10: from.wp10 = from.wp11; from.wp10mincost = from.wp11mincost;
		case 11: from.wp11 = from.wp12; from.wp11mincost = from.wp12mincost;
		case 12: from.wp12 = from.wp13; from.wp12mincost = from.wp13mincost;
		case 13: from.wp13 = from.wp14; from.wp13mincost = from.wp14mincost;
		case 14: from.wp14 = from.wp15; from.wp14mincost = from.wp15mincost;
		case 15: from.wp15 = from.wp16; from.wp15mincost = from.wp16mincost;
		case 16: from.wp16 = from.wp17; from.wp16mincost = from.wp17mincost;
		case 17: from.wp17 = from.wp18; from.wp17mincost = from.wp18mincost;
		case 18: from.wp18 = from.wp19; from.wp18mincost = from.wp19mincost;
		case 19: from.wp19 = from.wp20; from.wp19mincost = from.wp20mincost;
		case 20: from.wp20 = from.wp21; from.wp20mincost = from.wp21mincost;
		case 21: from.wp21 = from.wp22; from.wp21mincost = from.wp22mincost;
		case 22: from.wp22 = from.wp23; from.wp22mincost = from.wp23mincost;
		case 23: from.wp23 = from.wp24; from.wp23mincost = from.wp24mincost;
		case 24: from.wp24 = from.wp25; from.wp24mincost = from.wp25mincost;
		case 25: from.wp25 = from.wp26; from.wp25mincost = from.wp26mincost;
		case 26: from.wp26 = from.wp27; from.wp26mincost = from.wp27mincost;
		case 27: from.wp27 = from.wp28; from.wp27mincost = from.wp28mincost;
		case 28: from.wp28 = from.wp29; from.wp28mincost = from.wp29mincost;
		case 29: from.wp29 = from.wp30; from.wp29mincost = from.wp30mincost;
		case 30: from.wp30 = from.wp31; from.wp30mincost = from.wp31mincost;
		case 31: from.wp31 = NULL; from.wp31mincost = 10000000;
	}

	if (fromwp31_prev && !from.wp31)
		waypoint_schedulerelink(from);
}

int waypoint_getlinknum(entity from, entity to)
{
	if (from.wp00 == to) return  0; if (from.wp01 == to) return  1; if (from.wp02 == to) return  2; if (from.wp03 == to) return  3;
	if (from.wp04 == to) return  4; if (from.wp05 == to) return  5; if (from.wp06 == to) return  6; if (from.wp07 == to) return  7;
	if (from.wp08 == to) return  8; if (from.wp09 == to) return  9; if (from.wp10 == to) return 10; if (from.wp11 == to) return 11;
	if (from.wp12 == to) return 12; if (from.wp13 == to) return 13; if (from.wp14 == to) return 14; if (from.wp15 == to) return 15;
	if (from.wp16 == to) return 16; if (from.wp17 == to) return 17; if (from.wp18 == to) return 18; if (from.wp19 == to) return 19;
	if (from.wp20 == to) return 20; if (from.wp21 == to) return 21; if (from.wp22 == to) return 22; if (from.wp23 == to) return 23;
	if (from.wp24 == to) return 24; if (from.wp25 == to) return 25; if (from.wp26 == to) return 26; if (from.wp27 == to) return 27;
	if (from.wp28 == to) return 28; if (from.wp29 == to) return 29; if (from.wp30 == to) return 30; if (from.wp31 == to) return 31;
	return -1;
}

bool waypoint_islinked(entity from, entity to)
{
	return (waypoint_getlinknum(from, to) >= 0);
}

void waypoint_updatecost_foralllinks()
{
	IL_EACH(g_waypoints, !(it.wpflags & WAYPOINTFLAG_TELEPORT),
	{
		if(it.wp00) it.wp00mincost = waypoint_getlinkcost(it, it.wp00);
		if(it.wp01) it.wp01mincost = waypoint_getlinkcost(it, it.wp01);
		if(it.wp02) it.wp02mincost = waypoint_getlinkcost(it, it.wp02);
		if(it.wp03) it.wp03mincost = waypoint_getlinkcost(it, it.wp03);
		if(it.wp04) it.wp04mincost = waypoint_getlinkcost(it, it.wp04);
		if(it.wp05) it.wp05mincost = waypoint_getlinkcost(it, it.wp05);
		if(it.wp06) it.wp06mincost = waypoint_getlinkcost(it, it.wp06);
		if(it.wp07) it.wp07mincost = waypoint_getlinkcost(it, it.wp07);
		if(it.wp08) it.wp08mincost = waypoint_getlinkcost(it, it.wp08);
		if(it.wp09) it.wp09mincost = waypoint_getlinkcost(it, it.wp09);
		if(it.wp10) it.wp10mincost = waypoint_getlinkcost(it, it.wp10);
		if(it.wp11) it.wp11mincost = waypoint_getlinkcost(it, it.wp11);
		if(it.wp12) it.wp12mincost = waypoint_getlinkcost(it, it.wp12);
		if(it.wp13) it.wp13mincost = waypoint_getlinkcost(it, it.wp13);
		if(it.wp14) it.wp14mincost = waypoint_getlinkcost(it, it.wp14);
		if(it.wp15) it.wp15mincost = waypoint_getlinkcost(it, it.wp15);
		if(it.wp16) it.wp16mincost = waypoint_getlinkcost(it, it.wp16);
		if(it.wp17) it.wp17mincost = waypoint_getlinkcost(it, it.wp17);
		if(it.wp18) it.wp18mincost = waypoint_getlinkcost(it, it.wp18);
		if(it.wp19) it.wp19mincost = waypoint_getlinkcost(it, it.wp19);
		if(it.wp20) it.wp20mincost = waypoint_getlinkcost(it, it.wp20);
		if(it.wp21) it.wp21mincost = waypoint_getlinkcost(it, it.wp21);
		if(it.wp22) it.wp22mincost = waypoint_getlinkcost(it, it.wp22);
		if(it.wp23) it.wp23mincost = waypoint_getlinkcost(it, it.wp23);
		if(it.wp24) it.wp24mincost = waypoint_getlinkcost(it, it.wp24);
		if(it.wp25) it.wp25mincost = waypoint_getlinkcost(it, it.wp25);
		if(it.wp26) it.wp26mincost = waypoint_getlinkcost(it, it.wp26);
		if(it.wp27) it.wp27mincost = waypoint_getlinkcost(it, it.wp27);
		if(it.wp28) it.wp28mincost = waypoint_getlinkcost(it, it.wp28);
		if(it.wp29) it.wp29mincost = waypoint_getlinkcost(it, it.wp29);
		if(it.wp30) it.wp30mincost = waypoint_getlinkcost(it, it.wp30);
		if(it.wp31) it.wp31mincost = waypoint_getlinkcost(it, it.wp31);
	});
}

float waypoint_getlinearcost(float dist)
{
	if(skill >= autocvar_bot_ai_bunnyhop_skilloffset)
		return dist / (autocvar_sv_maxspeed * 1.25);
	return dist / autocvar_sv_maxspeed;
}
float waypoint_getlinearcost_underwater(float dist)
{
	// NOTE: underwater speed factor is hardcoded in the engine too, see SV_WaterMove
	return dist / (autocvar_sv_maxspeed * 0.7);
}

float waypoint_gettravelcost(vector from, vector to, entity from_ent, entity to_ent)
{
	bool submerged_from = navigation_check_submerged_state(from_ent, from);
	bool submerged_to = navigation_check_submerged_state(to_ent, to);

	if (submerged_from && submerged_to)
		return waypoint_getlinearcost_underwater(vlen(to - from));

	float c = waypoint_getlinearcost(vlen(to - from));

	float height = from.z - to.z;
	if(height > jumpheight_vec.z && autocvar_sv_gravity > 0)
	{
		float height_cost = sqrt(height / (autocvar_sv_gravity / 2));
		c = waypoint_getlinearcost(vlen(vec2(to - from))); // xy distance cost
		if(height_cost > c)
			c = height_cost;
	}

	if (submerged_from || submerged_to)
		return (c + waypoint_getlinearcost_underwater(vlen(to - from))) / 2;
	return c;
}

float waypoint_getlinkcost(entity from, entity to)
{
	vector v1 = from.origin;
	vector v2 = to.origin;
	if (from.wpisbox)
	{
		vector m1 = from.absmin, m2 = from.absmax;
		v1.x = bound(m1.x, v2.x, m2.x);
		v1.y = bound(m1.y, v2.y, m2.y);
		v1.z = bound(m1.z, v2.z, m2.z);
	}
	if (to.wpisbox)
	{
		vector m1 = to.absmin, m2 = to.absmax;
		v2.x = bound(m1.x, v1.x, m2.x);
		v2.y = bound(m1.y, v1.y, m2.y);
		v2.z = bound(m1.z, v1.z, m2.z);
	}
	return waypoint_gettravelcost(v1, v2, from, to);
}

// add a new link to the spawnfunc_waypoint, replacing the furthest link it already has
// if c == -1 automatically determine cost of the link
void waypoint_addlink_customcost(entity from, entity to, float c)
{
	if (from == to || waypoint_islinked(from, to))
		return;
	if (c == -1 && (from.wpflags & WAYPOINTFLAG_NORELINK))
		return;

	if(c == -1)
		c = waypoint_getlinkcost(from, to);

	if (from.wp31mincost < c) return;
	if (from.wp30mincost < c) {from.wp31 = to;from.wp31mincost = c;return;} from.wp31 = from.wp30;from.wp31mincost = from.wp30mincost;
	if (from.wp29mincost < c) {from.wp30 = to;from.wp30mincost = c;return;} from.wp30 = from.wp29;from.wp30mincost = from.wp29mincost;
	if (from.wp28mincost < c) {from.wp29 = to;from.wp29mincost = c;return;} from.wp29 = from.wp28;from.wp29mincost = from.wp28mincost;
	if (from.wp27mincost < c) {from.wp28 = to;from.wp28mincost = c;return;} from.wp28 = from.wp27;from.wp28mincost = from.wp27mincost;
	if (from.wp26mincost < c) {from.wp27 = to;from.wp27mincost = c;return;} from.wp27 = from.wp26;from.wp27mincost = from.wp26mincost;
	if (from.wp25mincost < c) {from.wp26 = to;from.wp26mincost = c;return;} from.wp26 = from.wp25;from.wp26mincost = from.wp25mincost;
	if (from.wp24mincost < c) {from.wp25 = to;from.wp25mincost = c;return;} from.wp25 = from.wp24;from.wp25mincost = from.wp24mincost;
	if (from.wp23mincost < c) {from.wp24 = to;from.wp24mincost = c;return;} from.wp24 = from.wp23;from.wp24mincost = from.wp23mincost;
	if (from.wp22mincost < c) {from.wp23 = to;from.wp23mincost = c;return;} from.wp23 = from.wp22;from.wp23mincost = from.wp22mincost;
	if (from.wp21mincost < c) {from.wp22 = to;from.wp22mincost = c;return;} from.wp22 = from.wp21;from.wp22mincost = from.wp21mincost;
	if (from.wp20mincost < c) {from.wp21 = to;from.wp21mincost = c;return;} from.wp21 = from.wp20;from.wp21mincost = from.wp20mincost;
	if (from.wp19mincost < c) {from.wp20 = to;from.wp20mincost = c;return;} from.wp20 = from.wp19;from.wp20mincost = from.wp19mincost;
	if (from.wp18mincost < c) {from.wp19 = to;from.wp19mincost = c;return;} from.wp19 = from.wp18;from.wp19mincost = from.wp18mincost;
	if (from.wp17mincost < c) {from.wp18 = to;from.wp18mincost = c;return;} from.wp18 = from.wp17;from.wp18mincost = from.wp17mincost;
	if (from.wp16mincost < c) {from.wp17 = to;from.wp17mincost = c;return;} from.wp17 = from.wp16;from.wp17mincost = from.wp16mincost;
	if (from.wp15mincost < c) {from.wp16 = to;from.wp16mincost = c;return;} from.wp16 = from.wp15;from.wp16mincost = from.wp15mincost;
	if (from.wp14mincost < c) {from.wp15 = to;from.wp15mincost = c;return;} from.wp15 = from.wp14;from.wp15mincost = from.wp14mincost;
	if (from.wp13mincost < c) {from.wp14 = to;from.wp14mincost = c;return;} from.wp14 = from.wp13;from.wp14mincost = from.wp13mincost;
	if (from.wp12mincost < c) {from.wp13 = to;from.wp13mincost = c;return;} from.wp13 = from.wp12;from.wp13mincost = from.wp12mincost;
	if (from.wp11mincost < c) {from.wp12 = to;from.wp12mincost = c;return;} from.wp12 = from.wp11;from.wp12mincost = from.wp11mincost;
	if (from.wp10mincost < c) {from.wp11 = to;from.wp11mincost = c;return;} from.wp11 = from.wp10;from.wp11mincost = from.wp10mincost;
	if (from.wp09mincost < c) {from.wp10 = to;from.wp10mincost = c;return;} from.wp10 = from.wp09;from.wp10mincost = from.wp09mincost;
	if (from.wp08mincost < c) {from.wp09 = to;from.wp09mincost = c;return;} from.wp09 = from.wp08;from.wp09mincost = from.wp08mincost;
	if (from.wp07mincost < c) {from.wp08 = to;from.wp08mincost = c;return;} from.wp08 = from.wp07;from.wp08mincost = from.wp07mincost;
	if (from.wp06mincost < c) {from.wp07 = to;from.wp07mincost = c;return;} from.wp07 = from.wp06;from.wp07mincost = from.wp06mincost;
	if (from.wp05mincost < c) {from.wp06 = to;from.wp06mincost = c;return;} from.wp06 = from.wp05;from.wp06mincost = from.wp05mincost;
	if (from.wp04mincost < c) {from.wp05 = to;from.wp05mincost = c;return;} from.wp05 = from.wp04;from.wp05mincost = from.wp04mincost;
	if (from.wp03mincost < c) {from.wp04 = to;from.wp04mincost = c;return;} from.wp04 = from.wp03;from.wp04mincost = from.wp03mincost;
	if (from.wp02mincost < c) {from.wp03 = to;from.wp03mincost = c;return;} from.wp03 = from.wp02;from.wp03mincost = from.wp02mincost;
	if (from.wp01mincost < c) {from.wp02 = to;from.wp02mincost = c;return;} from.wp02 = from.wp01;from.wp02mincost = from.wp01mincost;
	if (from.wp00mincost < c) {from.wp01 = to;from.wp01mincost = c;return;} from.wp01 = from.wp00;from.wp01mincost = from.wp00mincost;
	from.wp00 = to;from.wp00mincost = c;return;
}

void waypoint_addlink(entity from, entity to)
{
	waypoint_addlink_customcost(from, to, -1);
}

// relink this spawnfunc_waypoint
// (precompile a list of all reachable waypoints from this spawnfunc_waypoint)
// (SLOW!)
void waypoint_think(entity this)
{
	vector sv = '0 0 0', sv2 = '0 0 0', ev = '0 0 0', ev2 = '0 0 0', dv;
	float sv2_height = 0, ev2_height = 0;

	bot_calculate_stepheightvec();

	int dphitcontentsmask_save = this.dphitcontentsmask;
	this.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_PLAYERCLIP | DPCONTENTS_BOTCLIP;

	bot_navigation_movemode = ((autocvar_bot_navigation_ignoreplayers) ? MOVE_NOMONSTERS : MOVE_NORMAL);

	//dprint("waypoint_think wpisbox = ", ftos(this.wpisbox), "\n");
	IL_EACH(g_waypoints, this != it,
	{
		if (boxesoverlap(this.absmin, this.absmax, it.absmin, it.absmax))
		{
			waypoint_addlink(this, it);
			waypoint_addlink(it, this);
		}
		else
		{
			++relink_total;
			if(!checkpvs(this.origin, it))
			{
				++relink_pvsculled;
				continue;
			}

			sv = set_tracewalk_dest_2(this, it.origin);
			sv2 = tracewalk_dest;
			sv2_height = tracewalk_dest_height;
			ev = set_tracewalk_dest_2(it, this.origin);
			ev2 = tracewalk_dest;
			ev2_height = tracewalk_dest_height;

			dv = ev - sv;
			dv.z = 0;
			if(vdist(dv, >=, 1050)) // max search distance in XY
			{
				++relink_lengthculled;
				continue;
			}

			navigation_testtracewalk = 0;

			//traceline(this.origin, it.origin, false, NULL);
			//if (trace_fraction == 1)
			if (this.wpisbox)
				relink_walkculled += 0.5;
			else
			{
				if (tracewalk(this, sv, PL_MIN_CONST, PL_MAX_CONST, ev2, ev2_height, MOVE_NOMONSTERS))
					waypoint_addlink(this, it);
				else
					relink_walkculled += 0.5;
			}

			if (it.wpisbox)
				relink_walkculled += 0.5;
			else
			{
				if (tracewalk(this, ev, PL_MIN_CONST, PL_MAX_CONST, sv2, sv2_height, MOVE_NOMONSTERS))
					waypoint_addlink(it, this);
				else
					relink_walkculled += 0.5;
			}
		}
	});
	navigation_testtracewalk = 0;
	this.wplinked = true;
	this.dphitcontentsmask = dphitcontentsmask_save;
}

void waypoint_clearlinks(entity wp)
{
	// clear links to other waypoints
	float f = 10000000;
	wp.wp00 = wp.wp01 = wp.wp02 = wp.wp03 = wp.wp04 = wp.wp05 = wp.wp06 = wp.wp07 = NULL;
	wp.wp08 = wp.wp09 = wp.wp10 = wp.wp11 = wp.wp12 = wp.wp13 = wp.wp14 = wp.wp15 = NULL;
	wp.wp16 = wp.wp17 = wp.wp18 = wp.wp19 = wp.wp20 = wp.wp21 = wp.wp22 = wp.wp23 = NULL;
	wp.wp24 = wp.wp25 = wp.wp26 = wp.wp27 = wp.wp28 = wp.wp29 = wp.wp30 = wp.wp31 = NULL;

	wp.wp00mincost = wp.wp01mincost = wp.wp02mincost = wp.wp03mincost = wp.wp04mincost = wp.wp05mincost = wp.wp06mincost = wp.wp07mincost = f;
	wp.wp08mincost = wp.wp09mincost = wp.wp10mincost = wp.wp11mincost = wp.wp12mincost = wp.wp13mincost = wp.wp14mincost = wp.wp15mincost = f;
	wp.wp16mincost = wp.wp17mincost = wp.wp18mincost = wp.wp19mincost = wp.wp20mincost = wp.wp21mincost = wp.wp22mincost = wp.wp23mincost = f;
	wp.wp24mincost = wp.wp25mincost = wp.wp26mincost = wp.wp27mincost = wp.wp28mincost = wp.wp29mincost = wp.wp30mincost = wp.wp31mincost = f;

	wp.wplinked = false;
}

// tell a spawnfunc_waypoint to relink
void waypoint_schedulerelink(entity wp)
{
	if (wp == NULL)
		return;

	waypoint_setupmodel(wp);
	wp.wpisbox = vdist(wp.size, >, 0);
	wp.enemy = NULL;
	if (!(wp.wpflags & WAYPOINTFLAG_PERSONAL))
		wp.owner = NULL;
	if (!(wp.wpflags & WAYPOINTFLAG_NORELINK))
		waypoint_clearlinks(wp);
	// schedule an actual relink on next frame
	setthink(wp, waypoint_think);
	wp.nextthink = time;
	wp.effects = EF_LOWPRECISION;
}

// spawnfunc_waypoint map entity
spawnfunc(waypoint)
{
	IL_PUSH(g_waypoints, this);

	setorigin(this, this.origin);
	// schedule a relink after other waypoints have had a chance to spawn
	waypoint_clearlinks(this);
	//waypoint_schedulerelink(this);
}

// tell all waypoints to relink
// actually this is useful only to update relink_* stats
void waypoint_schedulerelinkall()
{
	relink_total = relink_walkculled = relink_pvsculled = relink_lengthculled = 0;
	IL_EACH(g_waypoints, true,
	{
		waypoint_schedulerelink(it);
	});
	waypoint_load_links_hardwired();
}

#define GET_GAMETYPE_EXTENSION() ((g_race) ? ".race" : "")

// Load waypoint links from file
bool waypoint_load_links()
{
	string s;
	float file, tokens, c = 0, found;
	entity wp_from = NULL, wp_to;
	vector wp_to_pos, wp_from_pos;

	string gt_ext = GET_GAMETYPE_EXTENSION();

	string filename = sprintf("maps/%s.waypoints.cache", strcat(mapname, gt_ext));
	file = fopen(filename, FILE_READ);

	if (gt_ext != "" && file < 0)
	{
		// if race waypoint file doesn't exist load the default one
		filename = sprintf("maps/%s.waypoints.cache", mapname);
		file = fopen(filename, FILE_READ);
	}

	if (file < 0)
	{
		LOG_TRACE("waypoint links load from ", filename, " failed");
		waypoint_schedulerelinkall();
		return false;
	}

	bool parse_comments = true;
	float ver = 0;
	string links_time = string_null;

	while ((s = fgets(file)))
	{
		if(parse_comments)
		{
			if(substring(s, 0, 2) == "//")
			{
				if(substring(s, 2, 17) == "WAYPOINT_VERSION ")
					ver = stof(substring(s, 19, -1));
				else if(substring(s, 2, 14) == "WAYPOINT_TIME ")
					links_time = substring(s, 16, -1);
				continue;
			}
			else
			{
				if(ver < WAYPOINT_VERSION || links_time != waypoint_time)
				{
					if (links_time != waypoint_time)
						LOG_TRACE("waypoint links for this map are not made for these waypoints.");
					else
						LOG_TRACE("waypoint links for this map are outdated.");
					if (g_assault)
					{
						LOG_TRACE("Assault waypoint links need to be manually updated in the editor");
					}
					else
					{
						LOG_TRACE("automatically updating...");
						waypoint_schedulerelinkall();
						fclose(file);
						return false;
					}
				}
				parse_comments = false;
			}
		}

		tokens = tokenizebyseparator(s, "*");

		if (tokens!=2)
		{
			// bad file format
			fclose(file);
			waypoint_schedulerelinkall(); // link all the autogenerated waypoints (teleporters)
			return false;
		}

		wp_from_pos	= stov(argv(0));
		wp_to_pos	= stov(argv(1));

		// Search "from" waypoint
		if(!wp_from || wp_from.origin!=wp_from_pos)
		{
			wp_from = findradius(wp_from_pos, 1);
			found = false;
			while(wp_from)
			{
				if(vdist(wp_from.origin - wp_from_pos, <, 1))
				if(wp_from.classname == "waypoint")
				{
					found = true;
					break;
				}
				wp_from = wp_from.chain;
			}

			if(!found)
			{
				LOG_TRACE("waypoint_load_links: couldn't find 'from' waypoint at ", vtos(wp_from_pos));
				continue;
			}
		}

		// Search "to" waypoint
		wp_to = findradius(wp_to_pos, 1);
		found = false;
		while(wp_to)
		{
			if(vdist(wp_to.origin - wp_to_pos, <, 1))
			if(wp_to.classname == "waypoint")
			{
				found = true;
				break;
			}
			wp_to = wp_to.chain;
		}

		if(!found)
		{
			LOG_TRACE("waypoint_load_links: couldn't find 'to' waypoint at ", vtos(wp_to_pos));
			continue;
		}

		++c;
		waypoint_addlink(wp_from, wp_to);
	}

	fclose(file);

	LOG_TRACE("loaded ", ftos(c), " waypoint links from ", filename);

	bool scheduled = false;
	IL_EACH(g_waypoints, it.wpflags & WAYPOINTFLAG_ITEM,
	{
		if (!it.wp00)
		{
			waypoint_schedulerelink(it);
			scheduled = true;
		}
	});
	if (scheduled)
		return false;

	botframe_cachedwaypointlinks = true;
	return true;
}

void waypoint_load_or_remove_links_hardwired(bool removal_mode)
{
	string s;
	float file, tokens, c = 0, found;
	entity wp_from = NULL, wp_to;
	vector wp_to_pos, wp_from_pos;

	string gt_ext = GET_GAMETYPE_EXTENSION();

	string filename = sprintf("maps/%s.waypoints.hardwired", strcat(mapname, gt_ext));
	file = fopen(filename, FILE_READ);

	if (gt_ext != "" && file < 0)
	{
		// if race waypoint file doesn't exist load the default one
		filename = sprintf("maps/%s.waypoints.hardwired", mapname);
		file = fopen(filename, FILE_READ);
	}

	botframe_loadedforcedlinks = true;

	if (file < 0)
	{
		if(!removal_mode)
			LOG_TRACE("waypoint links load from ", filename, " failed");
		return;
	}

	while ((s = fgets(file)))
	{
		if(substring(s, 0, 2)=="//")
			continue;

		if(substring(s, 0, 1)=="#")
			continue;

		tokens = tokenizebyseparator(s, "*");

		if (tokens!=2)
			continue;

		wp_from_pos	= stov(argv(0));
		wp_to_pos	= stov(argv(1));

		// Search "from" waypoint
		if(!wp_from || wp_from.origin!=wp_from_pos)
		{
			wp_from = findradius(wp_from_pos, 5);
			found = false;
			while(wp_from)
			{
				if(vdist(wp_from.origin - wp_from_pos, <, 5))
				if(wp_from.classname == "waypoint")
				{
					found = true;
					break;
				}
				wp_from = wp_from.chain;
			}

			if(!found)
			{
				if(!removal_mode)
					LOG_INFO("NOTICE: Can not find origin waypoint for the hardwired link ", s, ". Path skipped");
				continue;
			}
		}

		// Search "to" waypoint
		wp_to = findradius(wp_to_pos, 5);
		found = false;
		while(wp_to)
		{
			if(vdist(wp_to.origin - wp_to_pos, <, 5))
			if(wp_to.classname == "waypoint")
			{
				found = true;
				break;
			}
			wp_to = wp_to.chain;
		}

		if(!found)
		{
			if(!removal_mode)
				LOG_INFO("NOTICE: Can not find destination waypoint for the hardwired link ", s, ". Path skipped");
			continue;
		}

		++c;
		if(removal_mode)
		{
			waypoint_removelink(wp_from, wp_to);
			continue;
		}

		waypoint_addlink(wp_from, wp_to);
		wp_from.wphardwired = true;
		wp_to.wphardwired = true;
		waypoint_setupmodel(wp_from);
		waypoint_setupmodel(wp_to);
	}

	fclose(file);

	LOG_TRACE(((removal_mode) ? "unloaded " : "loaded "),
		ftos(c), " waypoint links from maps/", mapname, ".waypoints.hardwired");
}

entity waypoint_get_link(entity w, float i)
{
	switch(i)
	{
		case  0:return w.wp00;
		case  1:return w.wp01;
		case  2:return w.wp02;
		case  3:return w.wp03;
		case  4:return w.wp04;
		case  5:return w.wp05;
		case  6:return w.wp06;
		case  7:return w.wp07;
		case  8:return w.wp08;
		case  9:return w.wp09;
		case 10:return w.wp10;
		case 11:return w.wp11;
		case 12:return w.wp12;
		case 13:return w.wp13;
		case 14:return w.wp14;
		case 15:return w.wp15;
		case 16:return w.wp16;
		case 17:return w.wp17;
		case 18:return w.wp18;
		case 19:return w.wp19;
		case 20:return w.wp20;
		case 21:return w.wp21;
		case 22:return w.wp22;
		case 23:return w.wp23;
		case 24:return w.wp24;
		case 25:return w.wp25;
		case 26:return w.wp26;
		case 27:return w.wp27;
		case 28:return w.wp28;
		case 29:return w.wp29;
		case 30:return w.wp30;
		case 31:return w.wp31;
		default:return NULL;
	}
}

// Save all waypoint links to a file
void waypoint_save_links()
{
	// temporarily remove hardwired links so they don't get saved among normal links
	waypoint_remove_links_hardwired();

	string gt_ext = GET_GAMETYPE_EXTENSION();

	string filename = sprintf("maps/%s.waypoints.cache", strcat(mapname, gt_ext));
	int file = fopen(filename, FILE_WRITE);
	if (file < 0)
	{
		LOG_INFOF("waypoint link save to %s failed", filename);
		return;
	}

	fputs(file, strcat("//", "WAYPOINT_VERSION ", ftos_decimals(WAYPOINT_VERSION, 2), "\n"));
	if (waypoint_time != "")
		fputs(file, strcat("//", "WAYPOINT_TIME ", waypoint_time, "\n"));

	int c = 0;
	IL_EACH(g_waypoints, true,
	{
		for(int j = 0; j < 32; ++j)
		{
			entity link = waypoint_get_link(it, j);
			if(link)
			{
				// NOTE: vtos rounds vector components to 1 decimal place
				string s = strcat(vtos(it.origin), "*", vtos(link.origin), "\n");
				fputs(file, s);
				++c;
			}
		}
	});
	fclose(file);

	botframe_cachedwaypointlinks = true;

	LOG_INFOF("saved %d waypoint links to %s", c, filename);

	waypoint_load_links_hardwired();
}

// save waypoints to gamedir/data/maps/mapname.waypoints
void waypoint_saveall()
{
	string gt_ext = GET_GAMETYPE_EXTENSION();

	string filename = sprintf("maps/%s.waypoints", strcat(mapname, gt_ext));
	int file = fopen(filename, FILE_WRITE);
	if (file < 0)
	{
		waypoint_save_links(); // save anyway?
		botframe_loadedforcedlinks = false;

		LOG_INFOF("waypoint links: save to %s failed", filename);
		return;
	}

	float sym = autocvar_g_waypointeditor_symmetrical;
	string sym_str = ftos(sym);
	if (sym == -1 || (sym == 1 && autocvar_g_waypointeditor_symmetrical_order >= 2))
	{
		if (sym == 1)
		{
			sym_str = cons(sym_str, "-");
			sym_str = cons(sym_str, "-");
		}
		else
		{
			sym_str = cons(sym_str, ftos(autocvar_g_waypointeditor_symmetrical_origin.x));
			sym_str = cons(sym_str, ftos(autocvar_g_waypointeditor_symmetrical_origin.y));
		}
		if (autocvar_g_waypointeditor_symmetrical_order >= 2)
			sym_str = cons(sym_str, ftos(autocvar_g_waypointeditor_symmetrical_order));
	}
	else if (autocvar_g_waypointeditor_symmetrical == -2)
	{
		sym_str = cons(sym_str, ftos(autocvar_g_waypointeditor_symmetrical_axis.x));
		sym_str = cons(sym_str, ftos(autocvar_g_waypointeditor_symmetrical_axis.y));
	}

	// a group of 3 comments doesn't break compatibility with older Xonotic versions
	// (they are read as a waypoint with origin '0 0 0' and flag 0 though)
	fputs(file, strcat("//", "WAYPOINT_VERSION ", ftos_decimals(WAYPOINT_VERSION, 2), "\n"));
	fputs(file, strcat("//", "WAYPOINT_SYMMETRY ", sym_str, "\n"));

	strcpy(waypoint_time, strftime(true, "%Y-%m-%d %H:%M:%S"));
	fputs(file, strcat("//", "WAYPOINT_TIME ", waypoint_time, "\n"));
	//fputs(file, strcat("//", "\n"));
	//fputs(file, strcat("//", "\n"));
	//fputs(file, strcat("//", "\n"));

	int c = 0;
	IL_EACH(g_waypoints, true,
	{
		if(it.wpflags & WAYPOINTFLAG_GENERATED)
			continue;

		string s;
		// NOTE: vtos rounds vector components to 1 decimal place
		s = strcat(vtos(it.origin + it.mins), "\n");
		s = strcat(s, vtos(it.origin + it.maxs));
		s = strcat(s, "\n");
		s = strcat(s, ftos(it.wpflags));
		s = strcat(s, "\n");
		fputs(file, s);
		c++;
	});
	fclose(file);
	waypoint_save_links();
	botframe_loadedforcedlinks = false;

	LOG_INFOF("saved %d waypoints to %s", c, filename);
}

// load waypoints from file
float waypoint_loadall()
{
	string s;
	float file, cwp, cwb, fl;
	vector m1, m2;
	cwp = 0;
	cwb = 0;

	string gt_ext = GET_GAMETYPE_EXTENSION();

	string filename = sprintf("maps/%s.waypoints", strcat(mapname, gt_ext));
	file = fopen(filename, FILE_READ);

	if (gt_ext != "" && file < 0)
	{
		// if race waypoint file doesn't exist load the default one
		filename = sprintf("maps/%s.waypoints", mapname);
		file = fopen(filename, FILE_READ);
	}

	if (file < 0)
	{
		LOG_TRACE("waypoint load from ", filename, " failed");
		return 0;
	}

	bool parse_comments = true;
	float ver = 0;
	float sym = 0;
	float sym_param1 = 0, sym_param2 = 0, sym_param3 = 0;

	while ((s = fgets(file)))
	{
		if(parse_comments)
		{
			if(substring(s, 0, 2) == "//")
			{
				if(substring(s, 2, 17) == "WAYPOINT_VERSION ")
					ver = stof(substring(s, 19, -1));
				else if(substring(s, 2, 18) == "WAYPOINT_SYMMETRY ")
				{
					int tokens = tokenizebyseparator(substring(s, 20, -1), " ");
					if (tokens) { sym = stof(argv(0)); }
					if (tokens > 1) { sym_param1 = stof(argv(1)); }
					if (tokens > 2) { sym_param2 = stof(argv(2)); }
					if (tokens > 3) { sym_param3 = stof(argv(3)); }
				}
				else if(substring(s, 2, 14) == "WAYPOINT_TIME ")
					strcpy(waypoint_time, substring(s, 16, -1));
				continue;
			}
			else
			{
				if(floor(ver) < floor(WAYPOINT_VERSION))
				{
					LOG_TRACE("waypoints for this map are outdated");
					LOG_TRACE("please update them in the editor");
				}
				parse_comments = false;
			}
		}
		m1 = stov(s);
		s = fgets(file);
		if (!s)
			break;
		m2 = stov(s);
		s = fgets(file);
		if (!s)
			break;
		fl = stof(s);
		waypoint_spawn(m1, m2, fl);
		if (m1 == m2)
			cwp = cwp + 1;
		else
			cwb = cwb + 1;
	}
	fclose(file);
	LOG_TRACE("loaded ", ftos(cwp), " waypoints and ", ftos(cwb), " wayboxes from maps/", mapname, ".waypoints");

	if (autocvar_g_waypointeditor && autocvar_g_waypointeditor_symmetrical_allowload)
	{
		cvar_set("g_waypointeditor_symmetrical", ftos(sym));
		if (sym == 1 && sym_param3 < 2)
			cvar_set("g_waypointeditor_symmetrical_order", "0"); // make sure this is reset if not loaded
		if (sym == -1 || (sym == 1 && sym_param3 >= 2))
		{
			string params;
			if (sym == 1)
				params = cons("-", "-");
			else
			{
				params = cons(ftos(sym_param1), ftos(sym_param2));
				cvar_set("g_waypointeditor_symmetrical_origin", params);
			}
			cvar_set("g_waypointeditor_symmetrical_order", ftos(sym_param3));
			LOG_INFO("Waypoint editor: loaded symmetry ", ftos(sym), " with origin ", params, " and order ", ftos(sym_param3));
		}
		else if (sym == -2)
		{
			string params = strcat(ftos(sym_param1), " ", ftos(sym_param2));
			cvar_set("g_waypointeditor_symmetrical_axis", params);
			LOG_INFO("Waypoint editor: loaded symmetry ", ftos(sym), " with axis ", params);
		}
		else
			LOG_INFO("Waypoint editor: loaded symmetry ", ftos(sym));
		LOG_INFO(strcat("g_waypointeditor_symmetrical", " has been set to ", cvar_string("g_waypointeditor_symmetrical")));
	}

	return cwp + cwb;
}

#define waypoint_fixorigin(position, tracetest_ent) \
	waypoint_fixorigin_down_dir(position, tracetest_ent, '0 0 -1')

vector waypoint_fixorigin_down_dir(vector position, entity tracetest_ent, vector down_dir)
{
	vector endpos = position + down_dir * 3000;
	tracebox(position + '0 0 1', PL_MIN_CONST, PL_MAX_CONST, endpos, MOVE_NOMONSTERS, tracetest_ent);
	if(trace_startsolid)
		tracebox(position + '0 0 1' * (1 - PL_MIN_CONST.z / 2), PL_MIN_CONST, PL_MAX_CONST, endpos, MOVE_NOMONSTERS, tracetest_ent);
	if(trace_startsolid)
		tracebox(position + '0 0 1' * (1 - PL_MIN_CONST.z), PL_MIN_CONST, PL_MAX_CONST, endpos, MOVE_NOMONSTERS, tracetest_ent);
	if(trace_fraction < 1)
		position = trace_endpos;
	return position;
}

void waypoint_spawnforitem_force(entity e, vector org)
{
	// Fix the waypoint altitude if necessary
	org = waypoint_fixorigin(org, NULL);

	// don't spawn an item spawnfunc_waypoint if it already exists
	IL_EACH(g_waypoints, true,
	{
		if(it.wpisbox)
		{
			if(boxesoverlap(org, org, it.absmin, it.absmax))
			{
				e.nearestwaypoint = it;
				return;
			}
		}
		else
		{
			if(vdist(it.origin - org, <, 16))
			{
				e.nearestwaypoint = it;
				return;
			}
		}
	});

	e.nearestwaypoint = waypoint_spawn(org, org, WAYPOINTFLAG_GENERATED | WAYPOINTFLAG_ITEM);
}

void waypoint_spawnforitem(entity e)
{
	if(!bot_waypoints_for_items)
		return;

	waypoint_spawnforitem_force(e, e.origin);
}

void waypoint_spawnforteleporter_boxes(entity e, int teleport_flag, vector org1, vector org2, vector destination1, vector destination2, float timetaken)
{
	entity w;
	entity dw;
	w = waypoint_spawn(org1, org2, WAYPOINTFLAG_GENERATED | teleport_flag | WAYPOINTFLAG_NORELINK);
	dw = waypoint_spawn(destination1, destination2, WAYPOINTFLAG_GENERATED);
	// one way link to the destination
	w.wp00 = dw;
	w.wp00mincost = timetaken; // this is just for jump pads
	// the teleporter's nearest spawnfunc_waypoint is this one
	// (teleporters are not goals, so this is probably useless)
	e.nearestwaypoint = w;
	e.nearestwaypointtimeout = -1;
}

void waypoint_spawnforteleporter_wz(entity e, entity tracetest_ent)
{
	float src_angle = e.warpzone_angles.x;
	while (src_angle < -180) src_angle += 360;
	while (src_angle > 180) src_angle -= 360;

	float dest_angle = e.enemy.warpzone_angles.x;
	while (dest_angle < -180) dest_angle += 360;
	while (dest_angle > 180) dest_angle -= 360;

	// no waypoints for warpzones pointing upwards, they can't be used by the bots
	if (src_angle == -90 || dest_angle == -90)
		return;

	makevectors(e.warpzone_angles);
	vector src = (e.absmin + e.absmax) * 0.5;
	src += ((e.warpzone_origin - src) * v_forward) * v_forward + 16 * v_right;
	vector down_dir_src = -v_up;

	makevectors(e.enemy.warpzone_angles);
	vector dest = (e.enemy.absmin + e.enemy.absmax) * 0.5;
	dest += ((e.enemy.warpzone_origin - dest) * v_forward) * v_forward - 16 * v_right;
	vector down_dir_dest = -v_up;

	int extra_flag = 0;
	// don't snap to the ground waypoints for source warpzones pointing downwards
	if (src_angle != 90)
	{
		src = waypoint_fixorigin_down_dir(src, tracetest_ent, down_dir_src);
		dest = waypoint_fixorigin_down_dir(dest, tracetest_ent, down_dir_dest);
		// oblique warpzones need a jump otherwise bots gets stuck
		if (src_angle != 0)
			extra_flag = WAYPOINTFLAG_JUMP;
	}

	waypoint_spawnforteleporter_boxes(e, WAYPOINTFLAG_TELEPORT | extra_flag, src, src, dest, dest, 0);
}

void waypoint_spawnforteleporter(entity e, vector destination, float timetaken, entity tracetest_ent)
{
	destination = waypoint_fixorigin(destination, tracetest_ent);
	waypoint_spawnforteleporter_boxes(e, WAYPOINTFLAG_TELEPORT, e.absmin - PL_MAX_CONST + '1 1 1', e.absmax - PL_MIN_CONST + '-1 -1 -1', destination, destination, timetaken);
}

entity waypoint_spawnpersonal(entity this, vector position)
{
	entity w;

	// drop the waypoint to a proper location:
	//   first move it up by a player height
	//   then move it down to hit the floor with player bbox size
	position = waypoint_fixorigin(position, this);

	w = waypoint_spawn(position, position, WAYPOINTFLAG_GENERATED | WAYPOINTFLAG_PERSONAL);
	w.nearestwaypoint = NULL;
	w.nearestwaypointtimeout = 0;
	w.owner = this;

	waypoint_schedulerelink(w);

	return w;
}

void waypoint_showlink(entity wp1, entity wp2, int display_type)
{
	if (!(wp1 && wp2))
		return;

	if (wp1.wphardwired && wp2.wphardwired)
		te_beam(NULL, wp1.origin, wp2.origin);
	else if (display_type == 1)
		te_lightning2(NULL, wp1.origin, wp2.origin);
}

void waypoint_showlinks_to(entity wp, int display_type)
{
	IL_EACH(g_waypoints, it != wp,
	{
		if (waypoint_islinked(it, wp))
			waypoint_showlink(it, wp, display_type);
	});
}

void waypoint_showlinks_from(entity wp, int display_type)
{
	waypoint_showlink(wp.wp00, wp, display_type); waypoint_showlink(wp.wp16, wp, display_type);
	waypoint_showlink(wp.wp01, wp, display_type); waypoint_showlink(wp.wp17, wp, display_type);
	waypoint_showlink(wp.wp02, wp, display_type); waypoint_showlink(wp.wp18, wp, display_type);
	waypoint_showlink(wp.wp03, wp, display_type); waypoint_showlink(wp.wp19, wp, display_type);
	waypoint_showlink(wp.wp04, wp, display_type); waypoint_showlink(wp.wp20, wp, display_type);
	waypoint_showlink(wp.wp05, wp, display_type); waypoint_showlink(wp.wp21, wp, display_type);
	waypoint_showlink(wp.wp06, wp, display_type); waypoint_showlink(wp.wp22, wp, display_type);
	waypoint_showlink(wp.wp07, wp, display_type); waypoint_showlink(wp.wp23, wp, display_type);
	waypoint_showlink(wp.wp08, wp, display_type); waypoint_showlink(wp.wp24, wp, display_type);
	waypoint_showlink(wp.wp09, wp, display_type); waypoint_showlink(wp.wp25, wp, display_type);
	waypoint_showlink(wp.wp10, wp, display_type); waypoint_showlink(wp.wp26, wp, display_type);
	waypoint_showlink(wp.wp11, wp, display_type); waypoint_showlink(wp.wp27, wp, display_type);
	waypoint_showlink(wp.wp12, wp, display_type); waypoint_showlink(wp.wp28, wp, display_type);
	waypoint_showlink(wp.wp13, wp, display_type); waypoint_showlink(wp.wp29, wp, display_type);
	waypoint_showlink(wp.wp14, wp, display_type); waypoint_showlink(wp.wp30, wp, display_type);
	waypoint_showlink(wp.wp15, wp, display_type); waypoint_showlink(wp.wp31, wp, display_type);
}

void crosshair_trace_waypoints(entity pl)
{
	IL_EACH(g_waypoints, true, {
		it.solid = SOLID_BSP;
		if (!it.wpisbox)
			setsize(it, '-16 -16 -16', '16 16 16');
	});

	crosshair_trace(pl);

	IL_EACH(g_waypoints, true, {
		it.solid = SOLID_TRIGGER;
		if (!it.wpisbox)
			setsize(it, '0 0 0', '0 0 0');
	});
	if (trace_ent.classname != "waypoint")
		trace_ent = NULL;
}

void botframe_showwaypointlinks()
{
	if (time < botframe_waypointeditorlightningtime)
		return;
	botframe_waypointeditorlightningtime = time + 0.5;
	FOREACH_CLIENT(IS_PLAYER(it) && !it.isbot,
	{
		int display_type = 0;
		if (wasfreed(it.wp_aimed))
			it.wp_aimed = NULL;
		if (wasfreed(it.wp_locked))
			it.wp_locked = NULL;
		if (PHYS_INPUT_BUTTON_USE(it))
			it.wp_locked = it.wp_aimed;
		entity head = it.wp_locked;
		if (!head)
			head = navigation_findnearestwaypoint(it, false);
		it.nearestwaypoint = head; // mainly useful for debug
		it.nearestwaypointtimeout = time + 2; // while I'm at it...
		if (IS_ONGROUND(it) || it.waterlevel > WATERLEVEL_NONE || it.wp_locked)
			display_type = 1; // default
		else if(head && (head.wphardwired))
			display_type = 2; // only hardwired

		if (display_type)
		{
			//navigation_testtracewalk = true;
			//print("currently selected WP is ", etos(head), "\n");
			//navigation_testtracewalk = false;
			if (head)
			{
				te_lightning2(NULL, head.origin, it.origin);
				if(PHYS_INPUT_BUTTON_CROUCH(it))
					waypoint_showlinks_to(head, display_type);
				else
					waypoint_showlinks_from(head, display_type);
			}
		}
		string str;
		entity wp = NULL;
		if (vdist(vec2(it.velocity), <, autocvar_sv_maxspeed * 1.1))
		{
			crosshair_trace_waypoints(it);
			if (trace_ent)
			{
				wp = trace_ent;
				if (wp != it.wp_aimed)
				{
					str = sprintf("\necho ^2WP info^7: entity: %d, flags: %d, origin: '%s'\n", etof(wp), wp.wpflags, vtos(wp.origin));
					if (wp.wpisbox)
						str = strcat(str, sprintf("echo \" absmin: '%s', absmax: '%s'\"\n", vtos(wp.absmin), vtos(wp.absmax)));
					stuffcmd(it, str);
					str = sprintf("entity: %d\nflags: %d\norigin: \'%s\'", etof(wp), wp.wpflags, vtos(wp.origin));
					if (wp.wpisbox)
						str = strcat(str, sprintf(" \nabsmin: '%s'\nabsmax: '%s'", vtos(wp.absmin), vtos(wp.absmax)));
					debug_text_3d(wp.origin, str, 0, 7, '0 0 0');
				}
			}
		}
		if (it.wp_aimed != wp)
			it.wp_aimed = wp;
	});
}

float botframe_autowaypoints_fixdown(vector v)
{
	tracebox(v, PL_MIN_CONST, PL_MAX_CONST, v + '0 0 -64', MOVE_NOMONSTERS, NULL);
	if(trace_fraction >= 1)
		return 0;
	return 1;
}

float botframe_autowaypoints_createwp(vector v, entity p, .entity fld, float f)
{
	IL_EACH(g_waypoints, boxesoverlap(v - '32 32 32', v + '32 32 32', it.absmin, it.absmax),
	{
		// if a matching spawnfunc_waypoint already exists, don't add a duplicate
		return 0;
	});

	waypoint_schedulerelink(p.(fld) = waypoint_spawn(v, v, f));
	return 1;
}

// return value:
//    1 = WP created
//    0 = no action needed
//   -1 = temp fail, try from world too
//   -2 = permanent fail, do not retry
float botframe_autowaypoints_fix_from(entity p, float walkfromwp, entity wp, .entity fld)
{
	// make it possible to go from p to wp, if we can
	// if wp is NULL, nearest is chosen

	entity w;
	vector porg;
	float t, tmin, tmax;
	vector o;
	vector save;

	if(!botframe_autowaypoints_fixdown(p.origin))
		return -2;
	porg = trace_endpos;

	if(wp)
	{
		// if any WP w fulfills wp -> w -> porg and w is closer than wp, then switch from wp to w

		// if wp -> porg, then OK
		float maxdist;
		if(navigation_waypoint_will_link(wp.origin, porg, p, porg, 0, wp.origin, 0, walkfromwp, 1050))
		{
			// we may find a better one
			maxdist = vlen(wp.origin - porg);
		}
		else
		{
			// accept any "good"
			maxdist = 2100;
		}

		float bestdist = maxdist;
		IL_EACH(g_waypoints, it != wp && !(it.wpflags & WAYPOINTFLAG_NORELINK),
		{
			float d = vlen(wp.origin - it.origin) + vlen(it.origin - porg);
			if(d < bestdist)
			if(navigation_waypoint_will_link(wp.origin, it.origin, p, it.origin, 0, wp.origin, 0, walkfromwp, 1050))
			if(navigation_waypoint_will_link(it.origin, porg, p, porg, 0, it.origin, 0, walkfromwp, 1050))
			{
				bestdist = d;
				p.(fld) = it;
			}
		});
		if(bestdist < maxdist)
		{
			LOG_INFO("update chain to new nearest WP ", etos(p.(fld)));
			return 0;
		}

		if(bestdist < 2100)
		{
			// we know maxdist < 2100
			// so wp -> porg is still valid
			// all is good
			p.(fld) = wp;
			return 0;
		}

		// otherwise, no existing WP can fix our issues
	}
	else
	{
		save = p.origin;
		setorigin(p, porg);
		w = navigation_findnearestwaypoint(p, walkfromwp);
		setorigin(p, save);
		if(w)
		{
			p.(fld) = w;
			return 0;
		}
	}

	tmin = 0;
	tmax = 1;
	for (;;)
	{
		if(tmax - tmin < 0.001)
		{
			// did not get a good candidate
			return -1;
		}

		t = (tmin + tmax) * 0.5;
		o = antilag_takebackorigin(p, CS(p), time - t);
		if(!botframe_autowaypoints_fixdown(o))
			return -2;
		o = trace_endpos;

		if(wp)
		{
			if(!navigation_waypoint_will_link(wp.origin, o, p, o, 0, wp.origin, 0, walkfromwp, 1050))
			{
				// we cannot walk from wp.origin to o
				// get closer to tmax
				tmin = t;
				continue;
			}
		}
		else
		{
			save = p.origin;
			setorigin(p, o);
			w = navigation_findnearestwaypoint(p, walkfromwp);
			setorigin(p, save);
			if(!w)
			{
				// we cannot walk from any WP to o
				// get closer to tmax
				tmin = t;
				continue;
			}
		}

		// if we get here, o is valid regarding waypoints
		// check if o is connected right to the player
		// we break if it succeeds, as that means o is a good waypoint location
		if(navigation_waypoint_will_link(o, porg, p, porg, 0, o, 0, walkfromwp, 1050))
			break;

		// o is no good, we need to get closer to the player
		tmax = t;
	}

	LOG_INFO("spawning a waypoint for connecting to ", etos(wp));
	botframe_autowaypoints_createwp(o, p, fld, 0);
	return 1;
}

// automatically create missing waypoints
.entity botframe_autowaypoints_lastwp0, botframe_autowaypoints_lastwp1;
void botframe_autowaypoints_fix(entity p, float walkfromwp, .entity fld)
{
	float r = botframe_autowaypoints_fix_from(p, walkfromwp, p.(fld), fld);
	if(r != -1)
		return;
	r = botframe_autowaypoints_fix_from(p, walkfromwp, NULL, fld);
	if(r != -1)
		return;

	LOG_INFO("emergency: got no good nearby WP to build a link from, starting a new chain");
	if(!botframe_autowaypoints_fixdown(p.origin))
		return; // shouldn't happen, caught above
	botframe_autowaypoints_createwp(trace_endpos, p, fld, WAYPOINTFLAG_PROTECTED);
}

void botframe_deleteuselesswaypoints()
{
	IL_EACH(g_items, it.bot_pickup,
	{
		// NOTE: this protects waypoints if they're the ONLY nearest
		// waypoint. That's the intention.
		navigation_findnearestwaypoint(it, false);  // Walk TO item.
		navigation_findnearestwaypoint(it, true);  // Walk FROM item.
	});
	IL_EACH(g_waypoints, true,
	{
		it.wpflags |= WAYPOINTFLAG_DEAD_END;
		it.wpflags &= ~WAYPOINTFLAG_USEFUL;
		// WP is useful if:
		if (it.wpflags & WAYPOINTFLAG_ITEM)
			it.wpflags |= WAYPOINTFLAG_USEFUL;
		if (it.wpflags & WAYPOINTFLAG_TELEPORT)
			it.wpflags |= WAYPOINTFLAG_USEFUL;
		if (it.wpflags & WAYPOINTFLAG_LADDER)
			it.wpflags |= WAYPOINTFLAG_USEFUL;
		if (it.wpflags & WAYPOINTFLAG_PROTECTED)
			it.wpflags |= WAYPOINTFLAG_USEFUL;
		// b) WP is closest WP for an item/spawnpoint/other entity
		//    This has been done above by protecting these WPs.
	});
	// c) There are w1, w, w2 so that w1 -> w, w -> w2 and not w1 -> w2.
	IL_EACH(g_waypoints, !(it.wpflags & WAYPOINTFLAG_PERSONAL),
	{
		for (int m = 0; m < 32; ++m)
		{
			entity w = waypoint_get_link(it, m);
			if (!w)
				break;
			if (w.wpflags & WAYPOINTFLAG_PERSONAL)
				continue;
			if (w.wpflags & WAYPOINTFLAG_USEFUL)
				continue;
			for (int j = 0; j < 32; ++j)
			{
				entity w2 = waypoint_get_link(w, j);
				if (!w2)
					break;
				if (it == w2)
					continue;
				if (w2.wpflags & WAYPOINTFLAG_PERSONAL)
					continue;
				// If we got here, it != w2 exist with it -> w
				// and w -> w2. That means the waypoint is not
				// a dead end.
				w.wpflags &= ~WAYPOINTFLAG_DEAD_END;
				for (int k = 0; k < 32; ++k)
				{
					if (waypoint_get_link(it, k) == w2)
						continue;
					// IF WE GET HERE, w is proven useful
					// to get from it to w2!
					w.wpflags |= WAYPOINTFLAG_USEFUL;
					goto next;
				}
			}
LABEL(next)
		}
	});
	// d) The waypoint is a dead end. Dead end waypoints must be kept as
	//     they are needed to complete routes while autowaypointing.

	IL_EACH(g_waypoints, !(it.wpflags & (WAYPOINTFLAG_USEFUL | WAYPOINTFLAG_DEAD_END)),
	{
		LOG_INFOF("Removed a waypoint at %v. Try again for more!", it.origin);
		te_explosion(it.origin);
		waypoint_remove(it);
		break;
	});

	IL_EACH(g_waypoints, true,
	{
		it.wpflags &= ~(WAYPOINTFLAG_USEFUL | WAYPOINTFLAG_DEAD_END); // temp flag
	});
}

void botframe_autowaypoints()
{
	FOREACH_CLIENT(IS_PLAYER(it) && IS_REAL_CLIENT(it) && !IS_DEAD(it), {
		// going back is broken, so only fix waypoints to walk TO the player
		//botframe_autowaypoints_fix(p, false, botframe_autowaypoints_lastwp0);
		botframe_autowaypoints_fix(it, true, botframe_autowaypoints_lastwp1);
		//te_explosion(p.botframe_autowaypoints_lastwp0.origin);
	});

	if (autocvar_g_waypointeditor_auto >= 2) {
		botframe_deleteuselesswaypoints();
	}
}

