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
		if (imp == 17 || (imp >= 20 && imp < 200) || imp > 253) return;

	if (vehicle_impulse(this, imp)) return;

	if (CheatImpulse(imp)) return;

	FOREACH(IMPULSES, it.impulse == imp, {
		void(entity) f = it.impulse_handle;
		if (!f) continue;
		f(this);
		return;
	});

	if (imp >= 200 && imp <= 229)
	{
		if (!this.vehicle && this.deadflag == DEAD_NO)
		{
			// custom order weapon cycling
			int i = imp % 10;
			int m = (imp - (210 + i));  // <0 for prev, =0 for best, >0 for next
			W_CycleWeapon(this.(cvar_cl_weaponpriorities[i]), m);
		}
		// else // don't retry, as this can break weaplast bind
		// this.impulse = imp; // retry in next frame
	}
	else if (imp >= WEP_IMPULSE_BEGIN && imp <= WEP_IMPULSE_END)
	{
		if (!this.vehicle && this.deadflag == DEAD_NO) W_SwitchWeapon(imp - WEP_IMPULSE_BEGIN + WEP_FIRST);
		// else // don't retry, as this can break weaplast bind
		// this.impulse = imp; // retry in next frame
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
