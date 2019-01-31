#include "impulse.qh"
#include "round_handler.qh"

#include "weapons/throwing.qh"
#include "command/common.qh"
#include "cheats.qh"
#include "clientkill.qh"
#include "weapons/selection.qh"
#include "weapons/tracing.qh"
#include "weapons/weaponsystem.qh"

#include <common/state.qh>

#include "../common/minigames/sv_minigames.qh"

#include <common/weapons/_all.qh>
#include "../common/vehicles/sv_vehicles.qh"

#include "../common/mutators/mutator/waypoints/waypointsprites.qh"

.entity vehicle;

#define IMPULSE(id) _IMPULSE(IMP_##id)
#define _IMPULSE(id) \
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

#define X(i) \
	IMPULSE(weapon_group_##i) \
	{ \
		if (IS_DEAD(this)) \
		{ \
			this.impulse = IMP_weapon_group_##i.impulse; \
			return; \
		} \
		for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot) \
		{ \
			.entity weaponentity = weaponentities[slot]; \
			W_NextWeaponOnImpulse(this, i, weaponentity); \
			if(autocvar_g_weaponswitch_debug != 1) \
				break; \
		} \
	}
X(1)
X(2)
X(3)
X(4)
X(5)
X(6)
X(7)
X(8)
X(9)
X(0)
#undef X

// custom order weapon cycling

#define X(i, dir) \
	IMPULSE(weapon_priority_##i##_##dir) \
	{ \
		if (this.vehicle) return; \
		if (IS_DEAD(this)) \
		{ \
			this.impulse = IMP_weapon_priority_##i##_##dir.impulse; \
			return; \
		} \
		noref int prev = -1; \
		noref int best =  0; \
		noref int next = +1; \
		for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot) \
		{ \
			.entity weaponentity = weaponentities[slot]; \
			W_CycleWeapon(this, CS(this).cvar_cl_weaponpriorities[i], dir, weaponentity); \
			if(autocvar_g_weaponswitch_debug != 1) \
				break; \
		} \
	}
X(0, prev)
X(1, prev)
X(2, prev)
X(3, prev)
X(4, prev)
X(5, prev)
X(6, prev)
X(7, prev)
X(8, prev)
X(9, prev)

X(0, best)
X(1, best)
X(2, best)
X(3, best)
X(4, best)
X(5, best)
X(6, best)
X(7, best)
X(8, best)
X(9, best)

X(0, next)
X(1, next)
X(2, next)
X(3, next)
X(4, next)
X(5, next)
X(6, next)
X(7, next)
X(8, next)
X(9, next)
#undef X

// direct weapons

#define X(i) \
	IMPULSE(weapon_byid_##i) \
	{ \
		if (this.vehicle) return; \
		if (IS_DEAD(this)) \
		{ \
			this.impulse = IMP_weapon_byid_##i.impulse; \
			return; \
		} \
		for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot) \
		{ \
			.entity weaponentity = weaponentities[slot]; \
			W_SwitchWeapon_TryOthers(this, Weapons_from(WEP_FIRST + i), weaponentity); \
			if(autocvar_g_weaponswitch_debug != 1) \
				break; \
		} \
	}
X(0)
X(1)
X(2)
X(3)
X(4)
X(5)
X(6)
X(7)
X(8)
X(9)
X(10)
X(11)
X(12)
X(13)
X(14)
X(15)
X(16)
X(17)
X(18)
X(19)
X(20)
X(21)
X(22)
X(23)
#undef X

IMPULSE(weapon_next_byid)
{
	if (this.vehicle) return;
	if (IS_DEAD(this))
	{
		this.impulse = IMP_weapon_next_byid.impulse;
		return;
	}
	for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	{
		.entity weaponentity = weaponentities[slot];
		W_NextWeapon(this, 0, weaponentity);

		if(autocvar_g_weaponswitch_debug != 1)
			break;
	}
}

IMPULSE(weapon_prev_byid)
{
	if (this.vehicle) return;
	if (IS_DEAD(this))
	{
		this.impulse = IMP_weapon_prev_byid.impulse;
		return;
	}
	for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	{
		.entity weaponentity = weaponentities[slot];
		W_PreviousWeapon(this, 0, weaponentity);

		if(autocvar_g_weaponswitch_debug != 1)
			break;
	}
}

IMPULSE(weapon_next_bygroup)
{
	if (this.vehicle) return;
	if (IS_DEAD(this))
	{
		this.impulse = IMP_weapon_next_bygroup.impulse;
		return;
	}
	for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	{
		.entity weaponentity = weaponentities[slot];
		W_NextWeapon(this, 1, weaponentity);

		if(autocvar_g_weaponswitch_debug != 1)
			break;
	}
}

IMPULSE(weapon_prev_bygroup)
{
	if (this.vehicle) return;
	if (IS_DEAD(this))
	{
		this.impulse = IMP_weapon_prev_bygroup.impulse;
		return;
	}
	for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	{
		.entity weaponentity = weaponentities[slot];
		W_PreviousWeapon(this, 1, weaponentity);

		if(autocvar_g_weaponswitch_debug != 1)
			break;
	}
}

IMPULSE(weapon_next_bypriority)
{
	if (this.vehicle) return;
	if (IS_DEAD(this))
	{
		this.impulse = IMP_weapon_next_bypriority.impulse;
		return;
	}
	for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	{
		.entity weaponentity = weaponentities[slot];
		W_NextWeapon(this, 2, weaponentity);

		if(autocvar_g_weaponswitch_debug != 1)
			break;
	}
}

IMPULSE(weapon_prev_bypriority)
{
	if (this.vehicle) return;
	if (IS_DEAD(this))
	{
		this.impulse = IMP_weapon_prev_bypriority.impulse;
		return;
	}
	for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	{
		.entity weaponentity = weaponentities[slot];
		W_PreviousWeapon(this, 2, weaponentity);

		if(autocvar_g_weaponswitch_debug != 1)
			break;
	}
}

IMPULSE(weapon_last)
{
	if (this.vehicle) return;
	if (IS_DEAD(this)) return;
	for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	{
		.entity weaponentity = weaponentities[slot];
		W_LastWeapon(this, weaponentity);

		if(autocvar_g_weaponswitch_debug != 1)
			break;
	}
}

IMPULSE(weapon_best)
{
	if (this.vehicle) return;
	if (IS_DEAD(this)) return;
	for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	{
		.entity weaponentity = weaponentities[slot];
		W_SwitchWeapon(this, w_getbestweapon(this, weaponentity), weaponentity);

		if(autocvar_g_weaponswitch_debug != 1)
			break;
	}
}

IMPULSE(weapon_drop)
{
	if (this.vehicle) return;
	if (IS_DEAD(this)) return;
	for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	{
		.entity weaponentity = weaponentities[slot];
		W_ThrowWeapon(this, weaponentity, W_CalculateProjectileVelocity(this, this.velocity, v_forward * 750, false), '0 0 0', true);

		if(autocvar_g_weaponswitch_debug != 1)
			break;
	}
}

IMPULSE(weapon_reload)
{
	if (this.vehicle) return;
	if (IS_DEAD(this)) return;
	if (forbidWeaponUse(this)) return;
	entity actor = this;
	for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	{
		.entity weaponentity = weaponentities[slot];
		Weapon w = this.(weaponentity).m_weapon;
		w.wr_reload(w, actor, weaponentity);

		// allow reloading all active slots?
		//if(autocvar_g_weaponswitch_debug != 1)
			//break;
	}
}

void ImpulseCommands(entity this)
{
	if (game_stopped) return;

	int imp = CS(this).impulse;
	if (!imp) return;
	CS(this).impulse = 0;

	if (MinigameImpulse(this, imp)) return;

	if (timeout_status == TIMEOUT_ACTIVE) return;  // don't allow any impulses while the game is paused

	// allow only weapon change impulses when not in round time
	if (round_handler_IsActive() && !round_handler_IsRoundStarted())
	{
		#define X(id) case IMP_##id.impulse:
		switch (imp)
		{
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
            X(weapon_byid_0)
            X(weapon_byid_1)
            X(weapon_byid_2)
            X(weapon_byid_3)
            X(weapon_byid_4)
            X(weapon_byid_5)
            X(weapon_byid_6)
            X(weapon_byid_7)
            X(weapon_byid_8)
            X(weapon_byid_9)
            X(weapon_byid_10)
            X(weapon_byid_11)
            X(weapon_byid_12)
            X(weapon_byid_13)
            X(weapon_byid_14)
            X(weapon_byid_15)
            X(weapon_byid_16)
            X(weapon_byid_17)
            X(weapon_byid_18)
            X(weapon_byid_19)
            X(weapon_byid_20)
            X(weapon_byid_21)
            X(weapon_byid_22)
            X(weapon_byid_23)
			break;
			default: return;
		}
#undef X
	}

	if (vehicle_impulse(this, imp)) return;

	if (CheatImpulse(this, imp)) return;

	FOREACH(IMPULSES, it.impulse == imp, {
		void(entity) f = it.impulse_handle;
		if (!f) continue;
		f(this);
		return;
	});
}

IMPULSE(use)
{
	PlayerUseKey(this);
}

IMPULSE(waypoint_personal_here)
{
	entity wp = WaypointSprite_DeployPersonal(WP_Waypoint, this, this.origin, RADARICON_WAYPOINT);
	if (wp) WaypointSprite_Ping(wp);
	sprint(this, "personal waypoint spawned at location\n");
}

IMPULSE(waypoint_personal_crosshair)
{
	WarpZone_crosshair_trace(this);
	entity wp = WaypointSprite_DeployPersonal(WP_Waypoint, this, trace_endpos, RADARICON_WAYPOINT);
	if (wp) WaypointSprite_Ping(wp);
	sprint(this, "personal waypoint spawned at crosshair\n");
}

IMPULSE(waypoint_personal_death)
{
	if (!this.death_origin) return;
	entity wp = WaypointSprite_DeployPersonal(WP_Waypoint, this, this.death_origin, RADARICON_WAYPOINT);
	if (wp) WaypointSprite_Ping(wp);
	sprint(this, "personal waypoint spawned at death location\n");
}

IMPULSE(waypoint_here_follow)
{
	if (!teamplay) return;
	if (IS_DEAD(this)) return;
	if (!MUTATOR_CALLHOOK(HelpMePing, this))
	{
		entity wp = WaypointSprite_Attach(WP_Helpme, this, true, RADARICON_HELPME);
		if (!wp) WaypointSprite_HelpMePing(this.waypointsprite_attachedforcarrier);
		else WaypointSprite_Ping(wp);
	}
	sprint(this, "HELP ME attached\n");
}

IMPULSE(waypoint_here_here)
{
	entity wp = WaypointSprite_DeployFixed(WP_Here, false, this, this.origin, RADARICON_HERE);
	if (wp) WaypointSprite_Ping(wp);
	sprint(this, "HERE spawned at location\n");
}

IMPULSE(waypoint_here_crosshair)
{
	WarpZone_crosshair_trace(this);
	entity wp = WaypointSprite_DeployFixed(WP_Here, false, this, trace_endpos, RADARICON_HERE);
	if (wp) WaypointSprite_Ping(wp);
	sprint(this, "HERE spawned at crosshair\n");
}

IMPULSE(waypoint_here_death)
{
	if (!this.death_origin) return;
	entity wp = WaypointSprite_DeployFixed(WP_Here, false, this, this.death_origin, RADARICON_HERE);
	if (wp) WaypointSprite_Ping(wp);
	sprint(this, "HERE spawned at death location\n");
}

IMPULSE(waypoint_danger_here)
{
	entity wp = WaypointSprite_DeployFixed(WP_Danger, false, this, this.origin, RADARICON_DANGER);
	if (wp) WaypointSprite_Ping(wp);
	sprint(this, "DANGER spawned at location\n");
}

IMPULSE(waypoint_danger_crosshair)
{
	WarpZone_crosshair_trace(this);
	entity wp = WaypointSprite_DeployFixed(WP_Danger, false, this, trace_endpos, RADARICON_DANGER);
	if (wp) WaypointSprite_Ping(wp);
	sprint(this, "DANGER spawned at crosshair\n");
}

IMPULSE(waypoint_danger_death)
{
	if (!this.death_origin) return;
	entity wp = WaypointSprite_DeployFixed(WP_Danger, false, this, this.death_origin, RADARICON_DANGER);
	if (wp) WaypointSprite_Ping(wp);
	sprint(this, "DANGER spawned at death location\n");
}

IMPULSE(waypoint_clear_personal)
{
	WaypointSprite_ClearPersonal(this);
	if (this.personal)
	{
		delete(this.personal);
		this.personal = NULL;

		if((g_cts || g_race) && autocvar_g_allow_checkpoints)
			ClientKill(this);
	}
	sprint(this, "personal waypoint cleared\n");
}

IMPULSE(waypoint_clear)
{
	WaypointSprite_ClearOwned(this);
	if (this.personal)
	{
		delete(this.personal);
		this.personal = NULL;
		if((g_cts || g_race) && autocvar_g_allow_checkpoints)
			ClientKill(this);
	}
	sprint(this, "all waypoints cleared\n");
}
