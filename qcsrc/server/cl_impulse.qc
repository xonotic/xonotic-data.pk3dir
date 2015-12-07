#include "round_handler.qh"

#include "bot/waypoints.qh"

#include "weapons/throwing.qh"
#include "command/common.qh"
#include "cheats.qh"
#include "bot/navigation.qh"
#include "weapons/selection.qh"
#include "weapons/tracing.qh"
#include "weapons/weaponsystem.qh"

#include "../common/minigames/sv_minigames.qh"

#include "../common/weapons/all.qh"
#include "../common/vehicles/sv_vehicles.qh"

#include "../common/mutators/mutator/waypoints/waypointsprites.qh"

.entity vehicle;

#define IMPULSE(id, n) _IMPULSE(IMP_##id, n)
#define _IMPULSE(id, n) \
	void id##_handle(entity this); \
	STATIC_INIT_LATE(id) \
	{ \
		id.impulse_handle = id##_handle; \
	} \
	void id##_handle(entity this)

/**
 * Impulse map:
 *
 * 0 reserved (no input)
 *
 * 99: loaded
 *
 * 140: moving clone
 * 141: ctf speedrun
 * 142: fixed clone
 * 143: emergency teleport
 * 148: unfairly eliminate
 *
 * TODO:
 * 200 to 209: prev weapon shortcuts
 * 210 to 219: best weapon shortcuts
 * 220 to 229: next weapon shortcuts
 * 230 to 253: individual weapons (up to 24)
 */

// weapon switching impulses

#define X(slot, imp) \
	IMPULSE(weapon_group_##slot, imp) \
	{ \
		if (this.deadflag != DEAD_NO) return; \
		W_NextWeaponOnImpulse(slot); \
	}
X(1, 1)
X(2, 2)
X(3, 3)
X(4, 4)
X(5, 5)
X(6, 6)
X(7, 7)
X(8, 8)
X(9, 9)
X(0, 14)
#undef X

// custom order weapon cycling

#define X(slot, dir, imp) \
	IMPULSE(weapon_priority_##slot##_##dir, imp) \
	{ \
		if (this.vehicle) return; \
		if (this.deadflag != DEAD_NO) return; \
		noref int prev = -1; \
		noref int best =  0; \
		noref int next = +1; \
		W_CycleWeapon(this.cvar_cl_weaponpriorities[slot], dir); \
	}
X(0, prev, 200)
X(1, prev, 201)
X(2, prev, 202)
X(3, prev, 203)
X(4, prev, 204)
X(5, prev, 205)
X(6, prev, 206)
X(7, prev, 207)
X(8, prev, 208)
X(9, prev, 209)

X(0, best, 210)
X(1, best, 211)
X(2, best, 212)
X(3, best, 213)
X(4, best, 214)
X(5, best, 215)
X(6, best, 216)
X(7, best, 217)
X(8, best, 218)
X(9, best, 219)

X(0, next, 220)
X(1, next, 221)
X(2, next, 222)
X(3, next, 223)
X(4, next, 224)
X(5, next, 225)
X(6, next, 226)
X(7, next, 227)
X(8, next, 228)
X(9, next, 229)
#undef X

IMPULSE(weapon_next_byid, 10)
{
	if (this.vehicle) return;
	if (this.deadflag != DEAD_NO) return;
	W_NextWeapon(0);
}

IMPULSE(weapon_prev_byid, 12)
{
	if (this.vehicle) return;
	if (this.deadflag != DEAD_NO) return;
	W_PreviousWeapon(0);
}

IMPULSE(weapon_next_bygroup, 18)
{
	if (this.vehicle) return;
	if (this.deadflag != DEAD_NO) return;
	W_NextWeapon(1);
}

IMPULSE(weapon_prev_bygroup, 19)
{
	if (this.vehicle) return;
	if (this.deadflag != DEAD_NO) return;
	W_PreviousWeapon(1);
}

IMPULSE(weapon_next_bypriority, 15)
{
	if (this.vehicle) return;
	if (this.deadflag != DEAD_NO) return;
	W_NextWeapon(2);
}

IMPULSE(weapon_prev_bypriority, 16)
{
	if (this.vehicle) return;
	if (this.deadflag != DEAD_NO) return;
	W_PreviousWeapon(2);
}

IMPULSE(weapon_last, 11)
{
	if (this.vehicle) return;
	if (this.deadflag != DEAD_NO) return;
	W_LastWeapon();
}

IMPULSE(weapon_best, 13)
{
	if (this.vehicle) return;
	if (this.deadflag != DEAD_NO) return;
	W_SwitchWeapon(w_getbestweapon(this));
}

IMPULSE(weapon_drop, 17)
{
	if (this.vehicle) return;
	if (this.deadflag != DEAD_NO) return;
	W_ThrowWeapon(W_CalculateProjectileVelocity(this.velocity, v_forward * 750, false), '0 0 0', true);
}

IMPULSE(weapon_reload, 20)
{
	if (this.vehicle) return;
	if (this.deadflag != DEAD_NO) return;
	if (forbidWeaponUse(this)) return;
	Weapon w = Weapons_from(this.weapon);
	w.wr_reload(w);
}

void ImpulseCommands(entity this)
{
	if (gameover) return;

	int imp = this.impulse;
	if (!imp) return;
	this.impulse = 0;

	if (MinigameImpulse(this, imp)) return;

	if (timeout_status == TIMEOUT_ACTIVE) return;  // don't allow any impulses while the game is paused

	// allow only weapon change impulses when not in round time
	if (round_handler_IsActive() && !round_handler_IsRoundStarted())
	{
		#define X(id) case IMP_##id.impulse:
		switch (imp)
		{
			case WEP_IMPULSE_BEGIN <= imp && imp <= WEP_IMPULSE_END:
			X(weapon_group_0)
			X(weapon_group_1)
			X(weapon_group_2)
			X(weapon_group_3)
			X(weapon_group_4)
			X(weapon_group_5)
			X(weapon_group_6)
			X(weapon_group_7)
			X(weapon_group_8)
			X(weapon_group_9)
			X(weapon_next_byid)
			X(weapon_prev_byid)
			X(weapon_next_bygroup)
			X(weapon_prev_bygroup)
			X(weapon_next_bypriority)
			X(weapon_prev_bypriority)
			X(weapon_last)
			X(weapon_best)
			X(weapon_reload)
			X(weapon_priority_0_prev)
            X(weapon_priority_1_prev)
            X(weapon_priority_2_prev)
            X(weapon_priority_3_prev)
            X(weapon_priority_4_prev)
            X(weapon_priority_5_prev)
            X(weapon_priority_6_prev)
            X(weapon_priority_7_prev)
            X(weapon_priority_8_prev)
            X(weapon_priority_9_prev)
            X(weapon_priority_0_next)
			X(weapon_priority_1_next)
			X(weapon_priority_2_next)
			X(weapon_priority_3_next)
			X(weapon_priority_4_next)
			X(weapon_priority_5_next)
			X(weapon_priority_6_next)
			X(weapon_priority_7_next)
			X(weapon_priority_8_next)
			X(weapon_priority_9_next)
			X(weapon_priority_0_best)
            X(weapon_priority_1_best)
            X(weapon_priority_2_best)
            X(weapon_priority_3_best)
            X(weapon_priority_4_best)
            X(weapon_priority_5_best)
            X(weapon_priority_6_best)
            X(weapon_priority_7_best)
            X(weapon_priority_8_best)
            X(weapon_priority_9_best)
			break;
			default: return;
		}
#undef X
	}

	if (vehicle_impulse(this, imp)) return;

	if (CheatImpulse(imp)) return;

	FOREACH(IMPULSES, it.impulse == imp, {
		void(entity) f = it.impulse_handle;
		if (!f) continue;
		f(this);
		return;
	});

	if (imp >= WEP_IMPULSE_BEGIN && imp <= WEP_IMPULSE_END)
	{
		if (!this.vehicle && this.deadflag == DEAD_NO) W_SwitchWeapon(imp - WEP_IMPULSE_BEGIN + WEP_FIRST);
	}
}

IMPULSE(use, 21)
{
	PlayerUseKey();
}

IMPULSE(waypoint_personal_here, 30)
{
	entity wp = WaypointSprite_DeployPersonal(WP_Waypoint, this.origin, RADARICON_WAYPOINT);
	if (wp) WaypointSprite_Ping(wp);
	sprint(this, "personal waypoint spawned at location\n");
}

IMPULSE(waypoint_personal_crosshair, 31)
{
	WarpZone_crosshair_trace(this);
	entity wp = WaypointSprite_DeployPersonal(WP_Waypoint, trace_endpos, RADARICON_WAYPOINT);
	if (wp) WaypointSprite_Ping(wp);
	sprint(this, "personal waypoint spawned at crosshair\n");
}

IMPULSE(waypoint_personal_death, 32)
{
	if (!this.death_origin) return;
	entity wp = WaypointSprite_DeployPersonal(WP_Waypoint, this.death_origin, RADARICON_WAYPOINT);
	if (wp) WaypointSprite_Ping(wp);
	sprint(this, "personal waypoint spawned at death location\n");
}

IMPULSE(waypoint_here_follow, 33)
{
	if (!teamplay) return;
	if (this.deadflag != DEAD_NO) return;
	if (!MUTATOR_CALLHOOK(HelpMePing, this))
	{
		entity wp = WaypointSprite_Attach(WP_Helpme, true, RADARICON_HELPME);
		if (!wp) WaypointSprite_HelpMePing(this.waypointsprite_attachedforcarrier);
		else WaypointSprite_Ping(wp);
	}
	sprint(this, "HELP ME attached\n");
}

IMPULSE(waypoint_here_here, 34)
{
	entity wp = WaypointSprite_DeployFixed(WP_Here, false, this.origin, RADARICON_HERE);
	if (wp) WaypointSprite_Ping(wp);
	sprint(this, "HERE spawned at location\n");
}

IMPULSE(waypoint_here_crosshair, 35)
{
	WarpZone_crosshair_trace(this);
	entity wp = WaypointSprite_DeployFixed(WP_Here, false, trace_endpos, RADARICON_HERE);
	if (wp) WaypointSprite_Ping(wp);
	sprint(this, "HERE spawned at crosshair\n");
}

IMPULSE(waypoint_here_death, 36)
{
	if (!this.death_origin) return;
	entity wp = WaypointSprite_DeployFixed(WP_Here, false, this.death_origin, RADARICON_HERE);
	if (wp) WaypointSprite_Ping(wp);
	sprint(this, "HERE spawned at death location\n");
}

IMPULSE(waypoint_danger_here, 37)
{
	entity wp = WaypointSprite_DeployFixed(WP_Danger, false, this.origin, RADARICON_DANGER);
	if (wp) WaypointSprite_Ping(wp);
	sprint(this, "DANGER spawned at location\n");
}

IMPULSE(waypoint_danger_crosshair, 38)
{
	WarpZone_crosshair_trace(this);
	entity wp = WaypointSprite_DeployFixed(WP_Danger, false, trace_endpos, RADARICON_DANGER);
	if (wp) WaypointSprite_Ping(wp);
	sprint(this, "DANGER spawned at crosshair\n");
}

IMPULSE(waypoint_danger_death, 39)
{
	if (!this.death_origin) return;
	entity wp = WaypointSprite_DeployFixed(WP_Danger, false, this.death_origin, RADARICON_DANGER);
	if (wp) WaypointSprite_Ping(wp);
	sprint(this, "DANGER spawned at death location\n");
}

IMPULSE(waypoint_clear_personal, 47)
{
	WaypointSprite_ClearPersonal();
	if (this.personal)
	{
		remove(this.personal);
		this.personal = NULL;
	}
	sprint(this, "personal waypoint cleared\n");
}

IMPULSE(waypoint_clear, 48)
{
	WaypointSprite_ClearOwned();
	if (this.personal)
	{
		remove(this.personal);
		this.personal = NULL;
	}
	sprint(this, "all waypoints cleared\n");
}

IMPULSE(navwaypoint_spawn, 103)
{
	if (!autocvar_g_waypointeditor) return;
	waypoint_schedulerelink(waypoint_spawn(this.origin, this.origin, 0));
	bprint(strcat("Waypoint spawned at ", vtos(this.origin), "\n"));
}

IMPULSE(navwaypoint_remove, 104)
{
	if (!autocvar_g_waypointeditor) return;
	entity e = navigation_findnearestwaypoint(this, false);
	if (!e) return;
	if (e.wpflags & WAYPOINTFLAG_GENERATED) return;
	bprint(strcat("Waypoint removed at ", vtos(e.origin), "\n"));
	waypoint_remove(e);
}

IMPULSE(navwaypoint_relink, 105)
{
	if (!autocvar_g_waypointeditor) return;
	waypoint_schedulerelinkall();
}

IMPULSE(navwaypoint_save, 106)
{
	if (!autocvar_g_waypointeditor) return;
	waypoint_saveall();
}

IMPULSE(navwaypoint_unreachable, 107)
{
	if (!autocvar_g_waypointeditor) return;
	for (entity e = findchain(classname, "waypoint"); e; e = e.chain)
	{
		e.colormod = '0.5 0.5 0.5';
		e.effects &= ~(EF_NODEPTHTEST | EF_RED | EF_BLUE);
	}
	entity e2 = navigation_findnearestwaypoint(this, false);
	navigation_markroutes(e2);

	int i, m;

	i = 0;
	m = 0;
	for (entity e = findchain(classname, "waypoint"); e; e = e.chain)
	{
		if (e.wpcost < 10000000) continue;
		LOG_INFO("unreachable: ", etos(e), " ", vtos(e.origin), "\n");
		e.colormod_z = 8;
		e.effects |= EF_NODEPTHTEST | EF_BLUE;
		++i;
		++m;
	}
	if (i) LOG_INFOF("%d waypoints cannot be reached from here in any way (marked with blue light)\n", i);
	navigation_markroutes_inverted(e2);

	i = 0;
	for (entity e = findchain(classname, "waypoint"); e; e = e.chain)
	{
		if (e.wpcost < 10000000) continue;
		LOG_INFO("cannot reach me: ", etos(e), " ", vtos(e.origin), "\n");
		e.colormod_x = 8;
		if (!(e.effects & EF_NODEPTHTEST))  // not already reported before
			++m;
		e.effects |= EF_NODEPTHTEST | EF_RED;
		++i;
	}
	if (i) LOG_INFOF("%d waypoints cannot walk to here in any way (marked with red light)\n", i);
	if (m) LOG_INFOF("%d waypoints have been marked total\n", m);

	i = 0;
	for (entity e = findchain(classname, "info_player_deathmatch"); e; e = e.chain)
	{
		vector org = e.origin;
		tracebox(e.origin, PL_MIN, PL_MAX, e.origin - '0 0 512', MOVE_NOMONSTERS, world);
		setorigin(e, trace_endpos);
		if (navigation_findnearestwaypoint(e, false))
		{
			setorigin(e, org);
			e.effects &= ~EF_NODEPTHTEST;
			e.model = "";
		}
		else
		{
			setorigin(e, org);
			LOG_INFO("spawn without waypoint: ", etos(e), " ", vtos(e.origin), "\n");
			e.effects |= EF_NODEPTHTEST;
			_setmodel(e, this.model);
			e.frame = this.frame;
			e.skin = this.skin;
			e.colormod = '8 0.5 8';
			setsize(e, '0 0 0', '0 0 0');
			++i;
		}
	}
	if (i) LOG_INFOF("%d spawnpoints have no nearest waypoint (marked by player model)\n", i);

	i = 0;
	entity start = findchainflags(flags, FL_ITEM);
	for (entity e = start; e; e = e.chain)
	{
		e.effects &= ~(EF_NODEPTHTEST | EF_RED | EF_BLUE);
		e.colormod = '0.5 0.5 0.5';
	}
	for (entity e = start; e; e = e.chain)
	{
		if (navigation_findnearestwaypoint(e, false)) continue;
		LOG_INFO("item without waypoint: ", etos(e), " ", vtos(e.origin), "\n");
		e.effects |= EF_NODEPTHTEST | EF_RED;
		e.colormod_x = 8;
		++i;
	}
	if (i) LOG_INFOF("%d items have no nearest waypoint and cannot be walked away from (marked with red light)\n", i);

	i = 0;
	for (entity e = start; e; e = e.chain)
	{
		if (navigation_findnearestwaypoint(e, true)) continue;
		LOG_INFO("item without waypoint: ", etos(e), " ", vtos(e.origin), "\n");
		e.effects |= EF_NODEPTHTEST | EF_BLUE;
		e.colormod_z = 8;
		++i;
	}
	if (i) LOG_INFOF("%d items have no nearest waypoint and cannot be walked to (marked with blue light)\n", i);
}
