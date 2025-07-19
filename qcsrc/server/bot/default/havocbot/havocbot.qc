#include "havocbot.qh"

#include <common/constants.qh>
#include <common/impulses/all.qh>
#include <common/items/_mod.qh>
#include <common/mapobjects/func/ladder.qh>
#include <common/mapobjects/teleporters.qh>
#include <common/mapobjects/trigger/hurt.qh>
#include <common/mapobjects/trigger/jumppads.qh>
#include <common/mutators/mutator/powerups/_mod.qh>
#include <common/mutators/mutator/status_effects/_mod.qh>
#include <common/net_linked.qh>
#include <common/physics/player.qh>
#include <common/state.qh>
#include <common/stats.qh>
#include <common/weapons/_all.qh>
#include <common/wepent.qh>
#include <lib/warpzone/common.qh>
#include <server/bot/api.qh>
#include <server/bot/default/aim.qh>
#include <server/bot/default/bot.qh>
#include <server/bot/default/cvars.qh>
#include <server/bot/default/havocbot/roles.qh>
#include <server/bot/default/navigation.qh>
#include <server/bot/default/scripting.qh>
#include <server/bot/default/waypoints.qh>
#include <server/client.qh>
#include <server/damage.qh>
#include <server/items/items.qh>
#include <server/mutators/_mod.qh>
#include <server/weapons/selection.qh>
#include <server/weapons/weaponsystem.qh>
#include <server/world.qh>

void havocbot_ai(entity this)
{
	if(this.draggedby)
		return;

	this.bot_aimdir_executed = false;
	// lock aim if teleported or passing through a warpzone
	if (this.lastteleporttime && !this.jumppadcount)
		this.bot_aimdir_executed = true;

	if(bot_execute_commands(this))
		return;

	// after bot_execute_commands otherwise bots can't be unpaused
	if (bot_ispaused(this))
		return;

	if (bot_strategytoken == this && !bot_strategytoken_taken)
	{
		if(this.havocbot_blockhead)
		{
			this.havocbot_blockhead = false;
		}
		else
		{
			if (!this.jumppadcount && !STAT(FROZEN, this) && !StatusEffects_active(STATUSEFFECT_Frozen, this)
				&& !(this.goalcurrent_prev && (this.goalcurrent_prev.wpflags & WAYPOINTFLAG_JUMP) && !IS_ONGROUND(this)))
			{
				// find a new goal
				this.havocbot_role(this); // little too far down the rabbit hole
			}
		}

		// if we don't have a goal and we're under water look for a waypoint near the "shore" and push it
		if(!(IS_DEAD(this) || STAT(FROZEN, this) || StatusEffects_active(STATUSEFFECT_Frozen, this)))
		if(!this.goalcurrent)
		if(this.waterlevel == WATERLEVEL_SWIMMING || (this.aistatus & AI_STATUS_OUT_WATER))
		{
			// Look for the closest waypoint out of water
			entity newgoal = NULL;
			IL_EACH(g_waypoints, vdist(it.origin - this.origin, <=, 10000),
			{
				if(it.origin.z < this.origin.z)
					continue;

				if(it.origin.z - this.origin.z - this.view_ofs.z > 100)
					continue;

				if (pointcontents(it.origin + it.maxs + '0 0 1') != CONTENT_EMPTY)
					continue;

				traceline(this.origin + this.view_ofs, ((it.absmin + it.absmax) * 0.5), true, this);

				if(trace_fraction < 1)
					continue;

				if(!newgoal || vlen2(it.origin - this.origin) < vlen2(newgoal.origin - this.origin))
					newgoal = it;
			});

			if(newgoal)
			{
			//	te_wizspike(newgoal.origin);
				navigation_pushroute(this, newgoal);
			}
		}

		// token has been used this frame
		bot_strategytoken_taken = true;
	}

	if (this.goalcurrent && wasfreed(this.goalcurrent))
	{
		navigation_clearroute(this);
		navigation_goalrating_timeout_force(this);
		return;
	}

	if(IS_DEAD(this) || STAT(FROZEN, this) || StatusEffects_active(STATUSEFFECT_Frozen, this))
	{
		if (this.goalcurrent)
			navigation_clearroute(this);
		this.enemy = NULL;
		return;
	}

	havocbot_chooseenemy(this);

	for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	{
		.entity weaponentity = weaponentities[slot];
		if(this.(weaponentity).m_weapon != WEP_Null || slot == 0)
		if(this.(weaponentity).bot_chooseweapontime < time)
		{
			this.(weaponentity).bot_chooseweapontime = time + autocvar_bot_ai_chooseweaponinterval;
			havocbot_chooseweapon(this, weaponentity);
		}
	}
	havocbot_aim(this);

	if (this.enemy)
	{
		this.aistatus |= AI_STATUS_ATTACKING;
		this.aistatus &= ~AI_STATUS_ROAMING;

		if(STAT(WEAPONS, this))
		{
			if (autocvar_bot_nofire || IS_INDEPENDENT_PLAYER(this))
			{
				PHYS_INPUT_BUTTON_ATCK(this) = false;
				PHYS_INPUT_BUTTON_ATCK2(this) = false;
			}
			else
			{
				for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
				{
					.entity weaponentity = weaponentities[slot];
					Weapon w = this.(weaponentity).m_weapon;
					if(w == WEP_Null && slot != 0)
						continue;
					w.wr_aim(w, this, weaponentity);
					if(PHYS_INPUT_BUTTON_ATCK(this) || PHYS_INPUT_BUTTON_ATCK2(this)) // TODO: what if we didn't fire this weapon, but the previous?
						this.(weaponentity).lastfiredweapon = this.(weaponentity).m_weapon.m_id;
				}
			}
		}
		else
		{
			if(IS_PLAYER(this.enemy))
				bot_aimdir(this, this.enemy.origin + this.enemy.view_ofs - this.origin - this.view_ofs, 0);
		}
	}
	else if (this.goalcurrent)
	{
		this.aistatus |= AI_STATUS_ROAMING;
		this.aistatus &= ~AI_STATUS_ATTACKING;
	}

	havocbot_movetogoal(this);
	if (!this.bot_aimdir_executed && this.goalcurrent)
	{
		// Heading
		vector dir = get_closer_dest(this.goalcurrent, this.origin);
		dir -= this.origin + this.view_ofs;
		dir.z = 0;
		bot_aimdir(this, dir, 0);
	}

	// if the bot is not attacking, consider reloading weapons
	if (!(this.aistatus & AI_STATUS_ATTACKING))
	{
		for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
		{
			.entity weaponentity = weaponentities[slot];

			if(this.(weaponentity).m_weapon == WEP_Null && slot != 0)
				continue;

			// we are currently holding a weapon that's not fully loaded, reload it
			if(skill >= 2) // bots can only reload the held weapon on purpose past this skill
			if(this.(weaponentity).clip_load < this.(weaponentity).clip_size)
				CS(this).impulse = IMP_weapon_reload.impulse; // not sure if this is done right

			// if we're not reloading a weapon, switch to any weapon in our invnetory that's not fully loaded to reload it next
			// the code above executes next frame, starting the reloading then
			if(skill >= 5) // bots can only look for unloaded weapons past this skill
			if(this.(weaponentity).clip_load >= 0) // only if we're not reloading a weapon already
			{
				FOREACH(Weapons, it != WEP_Null, {
					if((STAT(WEAPONS, this) & (it.m_wepset)) && (it.spawnflags & WEP_FLAG_RELOADABLE) && (this.(weaponentity).weapon_load[it.m_id] < it.reloading_ammo))
					{
						this.(weaponentity).m_switchweapon = it;
						break;
					}
				});
			}
		}
	}
}

void havocbot_bunnyhop(entity this, vector dir)
{
	bool can_run = false;
	if (!(this.aistatus & AI_STATUS_ATTACKING) && this.goalcurrent && !IS_PLAYER(this.goalcurrent)
		&& vdist(vec2(this.velocity), >=, autocvar_sv_maxspeed) && !(this.aistatus & AI_STATUS_DANGER_AHEAD)
		&& this.waterlevel <= WATERLEVEL_WETFEET && !IS_DUCKED(this)
		&& IS_ONGROUND(this) && !(this.goalcurrent_prev && (this.goalcurrent_prev.wpflags & WAYPOINTFLAG_JUMP)))
	{
		vector vel_angles = vectoangles(this.velocity);
		vector deviation = vel_angles - vectoangles(dir);
		while (deviation.y < -180) deviation.y = deviation.y + 360;
		while (deviation.y > 180) deviation.y = deviation.y - 360;
		if (fabs(deviation.y) < autocvar_bot_ai_bunnyhop_dir_deviation_max)
		{
			vector gco = get_closer_dest(this.goalcurrent, this.origin);
			float vel = vlen(vec2(this.velocity));

			// with the current physics, jump distance grows linearly with the speed
			float jump_distance = 52.661 + 0.606 * vel;
			jump_distance += this.origin.z - gco.z; // roughly take into account vertical distance too
			if (vdist(vec2(gco - this.origin), >, max(0, jump_distance)))
				can_run = true;
			else if (!(this.goalcurrent.wpflags & WAYPOINTFLAG_JUMP)
				&& !(this.goalcurrent.wpflags & WAYPOINTFLAG_TELEPORT)
				&& this.goalstack01 && !wasfreed(this.goalstack01) && !(this.goalstack01.wpflags & WAYPOINTFLAG_JUMP)
				&& vdist(vec2(gco - this.goalstack01.origin), >, 70))
			{
				vector gno = (this.goalstack01.absmin + this.goalstack01.absmax) * 0.5;
				vector ang = vectoangles(gco - this.origin);
				deviation = vectoangles(gno - gco) - vel_angles;
				while (deviation.y < -180) deviation.y = deviation.y + 360;
				while (deviation.y > 180) deviation.y = deviation.y - 360;

				float max_turn_angle = autocvar_bot_ai_bunnyhop_turn_angle_max;
				max_turn_angle -= autocvar_bot_ai_bunnyhop_turn_angle_reduction * ((vel - autocvar_sv_maxspeed) / autocvar_sv_maxspeed);
				if ((ang.x < 90 || ang.x > 360 - autocvar_bot_ai_bunnyhop_downward_pitch_max)
					&& fabs(deviation.y) < max(autocvar_bot_ai_bunnyhop_turn_angle_min, max_turn_angle))
				{
					can_run = true;
				}
			}
		}
	}

	if (can_run)
	{
		PHYS_INPUT_BUTTON_JUMP(this) = true;
		this.bot_jump_time = time;
		this.aistatus |= AI_STATUS_RUNNING;
	}
	else
	{
		if (IS_ONGROUND(this) || this.waterlevel > WATERLEVEL_WETFEET)
			this.aistatus &= ~AI_STATUS_RUNNING;
	}
}

void havocbot_keyboard_movement(entity this, vector destorg)
{
	if(time <= this.havocbot_keyboardtime)
		return;

	float sk = skill + this.bot_moveskill;
	this.havocbot_keyboardtime =
		max(
			this.havocbot_keyboardtime
				+ 0.05 / max(1, sk + this.havocbot_keyboardskill)
				+ random() * 0.025 / max(0.00025, skill + this.havocbot_keyboardskill)
		, time);
	// TODO: Consider changing this back to `/ autocvar_sv_maxspeed` after https://github.com/graphitemaster/gmqcc/issues/210.
	vector keyboard = CS(this).movement * (1 / autocvar_sv_maxspeed);

	float trigger = autocvar_bot_ai_keyboard_threshold;

	// categorize forward movement
	// at skill < 1.5 only forward
	// at skill < 2.5 only individual directions
	// at skill < 4.5 only individual directions, and forward diagonals
	// at skill >= 4.5, all cases allowed
	if (keyboard.x > trigger)
	{
		keyboard.x = 1;
		if (sk < 2.5)
			keyboard.y = 0;
	}
	else if (keyboard.x < -trigger && sk > 1.5)
	{
		keyboard.x = -1;
		if (sk < 4.5)
			keyboard.y = 0;
	}
	else
	{
		keyboard.x = 0;
		if (sk < 1.5)
			keyboard.y = 0;
	}
	if (sk < 4.5)
		keyboard.z = 0;

	if (keyboard.y > trigger)
		keyboard.y = 1;
	else if (keyboard.y < -trigger)
		keyboard.y = -1;
	else
		keyboard.y = 0;

	if (keyboard.z > trigger)
		keyboard.z = 1;
	else if (keyboard.z < -trigger)
		keyboard.z = -1;
	else
		keyboard.z = 0;

	// make sure bots don't get stuck if havocbot_keyboardtime is very high
	if (keyboard == '0 0 0')
		this.havocbot_keyboardtime = min(this.havocbot_keyboardtime, time + 0.2);

	this.havocbot_keyboard = keyboard * autocvar_sv_maxspeed;
	if (this.havocbot_ducktime > time)
		PHYS_INPUT_BUTTON_CROUCH(this) = true;

	keyboard = this.havocbot_keyboard;
	float blend = bound(0, vlen(destorg - this.origin) / autocvar_bot_ai_keyboard_distance, 1); // When getting close move with 360 degree
	//dprint("movement ", vtos(CS(this).movement), " keyboard ", vtos(keyboard), " blend ", ftos(blend), "\n");
	CS(this).movement = CS(this).movement + (keyboard - CS(this).movement) * blend;
}

// return true when bot isn't getting closer to the current goal
bool havocbot_checkgoaldistance(entity this, vector gco)
{
	if (this.bot_stop_moving_timeout > time)
		return false;
	float curr_dist_z = max(20, fabs(this.origin.z - gco.z));
	float curr_dist_2d = max(20, vlen(vec2(this.origin - gco)));
	float distance_time = this.goalcurrent_distance_time;
	if(distance_time < 0)
		distance_time = -distance_time;
	if(curr_dist_z >= this.goalcurrent_distance_z && curr_dist_2d >= this.goalcurrent_distance_2d)
	{
		if(!distance_time)
			this.goalcurrent_distance_time = time;
		else if (time - distance_time > 0.5)
			return true;
	}
	else
	{
		// reduce it a little bit so it works even with very small approaches to the goal
		this.goalcurrent_distance_z = max(20, curr_dist_z - 10);
		this.goalcurrent_distance_2d = max(20, curr_dist_2d - 10);
		this.goalcurrent_distance_time = 0;
	}
	return false;
}

entity havocbot_select_an_item_of_group(entity this, int gr)
{
	entity selected = NULL;
	float selected_dist2 = 0;
	// select farthest item of this group from bot's position
	IL_EACH(g_items, it.item_group == gr && it.solid,
	{
		float dist2 = vlen2(this.origin - it.origin);
		if (dist2 < 600 ** 2 && dist2 > selected_dist2)
		{
			selected = it;
			selected_dist2 = vlen2(this.origin - selected.origin);
		}
	});

	if (!selected)
		return NULL;

	set_tracewalk_dest(selected, this.origin, false);
	if (!tracewalk(this, this.origin, STAT(PL_MIN, this), STAT(PL_MAX, this),
		tracewalk_dest, tracewalk_dest_height, bot_navigation_movemode))
	{
		return NULL;
	}

	return selected;
}

// Check for water/slime/lava and dangerous edges
// (only when the bot is on the ground or jumping intentionally)
// returns a number > 0 for danger
int havocbot_checkdanger(entity this, vector dst_ahead)
{
	vector dst_down = dst_ahead - '0 0 3000';
	traceline(this.origin + this.view_ofs, dst_ahead, true, NULL);

	float s = CONTENT_SOLID;
	if (trace_fraction == 1 && !this.jumppadcount
		&& !waypoint_is_hardwiredlink(this.goalcurrent_prev, this.goalcurrent)
		&& !(this.goalcurrent_prev && (this.goalcurrent_prev.wpflags & WAYPOINTFLAG_JUMP)))
	if ((IS_ONGROUND(this)) || (this.aistatus & (AI_STATUS_RUNNING | AI_STATUS_ROAMING)) || PHYS_INPUT_BUTTON_JUMP(this))
	{
		// Look downwards
		traceline(dst_ahead , dst_down, true, NULL);
		//te_lightning2(NULL, this.origin + this.view_ofs, dst_ahead); // Draw "ahead" look
		//te_lightning2(NULL, dst_ahead, trace_endpos); // Draw "downwards" look
		if (trace_endpos.z < this.origin.z + this.mins.z)
		{
			if (trace_dphitq3surfaceflags & Q3SURFACEFLAG_SKY)
				return 1;
			else if (trace_endpos.z < min(this.origin.z + this.mins.z, this.goalcurrent.origin.z) - 100)
				return 2;
			else
			{
				s = pointcontents(trace_endpos + '0 0 1');
				if (s != CONTENT_SOLID)
				{
					if (s == CONTENT_LAVA || s == CONTENT_SLIME)
						return 3;
					else if (tracebox_hits_trigger_hurt(dst_ahead, this.mins, this.maxs, trace_endpos))
					{
						// the traceline check isn't enough but is good as optimization,
						// when not true (most of the time) this tracebox call is avoided
						tracebox(dst_ahead, this.mins, this.maxs, dst_down, true, this);
						if (tracebox_hits_trigger_hurt(dst_ahead, this.mins, this.maxs, trace_endpos))
						{
							return 4;
						}
					}
				}
			}
		}
	}
	return false;
}

void havocbot_movetogoal(entity this)
{
	vector diff;
	vector dir;
	vector flatdir;
	float dodge_enemy_factor = 1;
	float maxspeed = autocvar_sv_maxspeed;
	//float dist;
	vector dodge;
	//if (this.goalentity)
	//	te_lightning2(this, this.origin, (this.goalentity.absmin + this.goalentity.absmax) * 0.5);
	CS(this).movement = '0 0 0';

	PHYS_INPUT_BUTTON_CROUCH(this) = boolean(this.goalcurrent.wpflags & WAYPOINTFLAG_CROUCH);

	PHYS_INPUT_BUTTON_JETPACK(this) = false;
	// Jetpack navigation
	if(this.navigation_jetpack_goal)
	if(this.goalcurrent==this.navigation_jetpack_goal)
	if(GetResource(this, RES_FUEL) > 0 || (this.items & IT_UNLIMITED_AMMO))
	{
		if(autocvar_bot_debug_goalstack)
		{
			debuggoalstack(this);
			te_wizspike(this.navigation_jetpack_point);
		}

		// Take off
		if (!(this.aistatus & AI_STATUS_JETPACK_FLYING))
		{
			// Brake almost completely so it can get a good direction
			if(vdist(this.velocity, >, 10))
				return;
			this.aistatus |= AI_STATUS_JETPACK_FLYING;
		}

		makevectors(this.v_angle.y * '0 1 0');
		dir = normalize(this.navigation_jetpack_point - this.origin);

		// Landing
		if(this.aistatus & AI_STATUS_JETPACK_LANDING)
		{
			// Calculate brake distance in xy
			float d = vlen(vec2(this.origin - (this.goalcurrent.absmin + this.goalcurrent.absmax) * 0.5));
			float vel2 = vlen2(vec2(this.velocity));
			float db = (vel2 / (autocvar_g_jetpack_acceleration_side * 2)) + 100;
			//LOG_INFOF("distance %d, velocity %d, brake at %d ", ceil(d), ceil(v), ceil(db));
			if(d < db || d < 500)
			{
				// Brake
				if (vel2 > (maxspeed * 0.3) ** 2)
				{
					CS(this).movement_x = dir * v_forward * -maxspeed;
					return;
				}
				// Switch to normal mode
				this.navigation_jetpack_goal = NULL;
				this.aistatus &= ~AI_STATUS_JETPACK_LANDING;
				this.aistatus &= ~AI_STATUS_JETPACK_FLYING;
				return;
			}
		}
		else if(checkpvs(this.origin,this.goalcurrent))
		{
			// If I can see the goal switch to landing code
			this.aistatus &= ~AI_STATUS_JETPACK_FLYING;
			this.aistatus |= AI_STATUS_JETPACK_LANDING;
			return;
		}

		// Flying
		PHYS_INPUT_BUTTON_JETPACK(this) = true;
		if(this.navigation_jetpack_point.z - STAT(PL_MAX, this).z + STAT(PL_MIN, this).z < this.origin.z)
		{
			CS(this).movement_x = dir * v_forward * maxspeed;
			CS(this).movement_y = dir * v_right * maxspeed;
		}
		return;
	}

	// Handling of jump pads
	if(this.jumppadcount)
	{
		if(this.goalcurrent.wpflags & WAYPOINTFLAG_TELEPORT)
		{
			this.aistatus |= AI_STATUS_OUT_JUMPPAD;
			if(navigation_poptouchedgoals(this))
				return;
		}
		else if(this.aistatus & AI_STATUS_OUT_JUMPPAD)
		{
			// If got stuck on the jump pad try to reach the farthest visible waypoint
			// but with some randomness so it can try out different paths
			if(!this.goalcurrent)
			{
				entity newgoal = NULL;
				IL_EACH(g_waypoints, vdist(it.origin - this.origin, <=, 1000),
				{
					if(it.wpflags & WAYPOINTFLAG_TELEPORT)
					if(it.origin.z < this.origin.z - 100 && vdist(vec2(it.origin - this.origin), <, 100))
						continue;

					traceline(this.origin + this.view_ofs, ((it.absmin + it.absmax) * 0.5), true, this);

					if(trace_fraction < 1)
						continue;

					if(!newgoal || ((random() < 0.8) && vlen2(it.origin - this.origin) > vlen2(newgoal.origin - this.origin)))
						newgoal = it;
				});

				if(newgoal)
				{
					this.ignoregoal = this.goalcurrent;
					this.ignoregoaltime = time + autocvar_bot_ai_ignoregoal_timeout;
					navigation_clearroute(this);
					navigation_routetogoal(this, newgoal, this.origin);
					if(autocvar_bot_debug_goalstack)
						debuggoalstack(this);
					this.aistatus &= ~AI_STATUS_OUT_JUMPPAD;
				}
			}
			else //if (this.goalcurrent)
			{
				if (this.goalcurrent.bot_pickup)
				{
					entity jumppad_wp = this.goalcurrent_prev;
					navigation_poptouchedgoals(this);
					if(!this.goalcurrent && jumppad_wp.wp00)
					{
						// head to the jumppad destination once bot reaches the goal item
						navigation_pushroute(this, jumppad_wp.wp00);
					}
				}
				vector gco = (this.goalcurrent.absmin + this.goalcurrent.absmax) * 0.5;
				if (this.origin.z > gco.z && vdist(vec2(this.velocity), <, maxspeed))
				{
					if (this.velocity.z < 0)
						this.aistatus &= ~AI_STATUS_OUT_JUMPPAD;
				}
				else if(havocbot_checkgoaldistance(this, gco))
				{
					navigation_clearroute(this);
					navigation_goalrating_timeout_force(this);
				}
				else
					return;
			}
		}
		else //if (!(this.aistatus & AI_STATUS_OUT_JUMPPAD))
		{
			if(this.velocity.z > 0 && this.origin.z - this.lastteleport_origin.z > (this.maxs.z - this.mins.z) * 0.5)
			{
				vector velxy = this.velocity; velxy_z = 0;
				if(vdist(velxy, <, maxspeed * 0.2))
				{
					LOG_TRACE("Warning: ", this.netname, " got stuck on a jumppad (velocity in xy is ", vtos(velxy), "), trying to get out of it now");
					this.aistatus |= AI_STATUS_OUT_JUMPPAD;
				}
				return;
			}

			// Don't chase players while using a jump pad
			if(IS_PLAYER(this.goalcurrent) || IS_PLAYER(this.goalstack01))
				return;
		}
	}
	else if(this.aistatus & AI_STATUS_OUT_JUMPPAD)
		this.aistatus &= ~AI_STATUS_OUT_JUMPPAD;

	// If there is a trigger_hurt right below try to use the jetpack or make a rocketjump
	if (skill > 6 && !(IS_ONGROUND(this)))
	{
		#define ROCKETJUMP_DAMAGE() WEP_CVAR(WEP_DEVASTATOR, damage) * 0.8 \
			* ((StatusEffects_active(STATUSEFFECT_Strength, this)) ? autocvar_g_balance_powerup_strength_selfdamage : 1) \
			* ((StatusEffects_active(STATUSEFFECT_Shield, this)) ? autocvar_g_balance_powerup_invincible_takedamage : 1)

		// save some CPU cycles by checking trigger_hurt after checking
		// that something can be done to evade it (cheaper checks)
		int action_for_trigger_hurt = 0;
		if (this.items & IT_JETPACK)
			action_for_trigger_hurt = 1;
		else if (!this.jumppadcount && !waypoint_is_hardwiredlink(this.goalcurrent_prev, this.goalcurrent)
			&& !(this.goalcurrent_prev && (this.goalcurrent_prev.wpflags & WAYPOINTFLAG_JUMP))
			&& GetResource(this, RES_HEALTH) + GetResource(this, RES_ARMOR) > ROCKETJUMP_DAMAGE())
		{
			action_for_trigger_hurt = 2;
		}
		else if (!this.goalcurrent)
			action_for_trigger_hurt = 3;

		if (action_for_trigger_hurt)
		{
			tracebox(this.origin, this.mins, this.maxs, this.origin + '0 0 -65536', MOVE_NOMONSTERS, this);
			if(!tracebox_hits_trigger_hurt(this.origin, this.mins, this.maxs, trace_endpos))
				action_for_trigger_hurt = 0;
		}

		if(action_for_trigger_hurt == 1) // jetpack
		{
			tracebox(this.origin, this.mins, this.maxs, this.origin + '0 0 65536', MOVE_NOMONSTERS, this);
			if(tracebox_hits_trigger_hurt(this.origin, this.mins, this.maxs, trace_endpos + '0 0 1' ))
			{
				if(this.velocity.z<0)
					PHYS_INPUT_BUTTON_JETPACK(this) = true;
			}
			else
				PHYS_INPUT_BUTTON_JETPACK(this) = true;

			// If there is no goal try to move forward

			if(this.goalcurrent==NULL)
				dir = v_forward;
			else
				dir = normalize(( ( this.goalcurrent.absmin + this.goalcurrent.absmax ) * 0.5 ) - this.origin);

			vector xyvelocity = this.velocity; xyvelocity_z = 0;
			float xyspeed = xyvelocity * dir;

			if(xyspeed < (maxspeed / 2))
			{
				makevectors(this.v_angle.y * '0 1 0');
				tracebox(this.origin, this.mins, this.maxs, this.origin + (dir * maxspeed * 3), MOVE_NOMONSTERS, this);
				if(trace_fraction==1)
				{
					CS(this).movement_x = dir * v_forward * maxspeed;
					CS(this).movement_y = dir * v_right * maxspeed;
					if (skill < 10)
						havocbot_keyboard_movement(this, this.origin + dir * 100);
				}
			}

			this.havocbot_blockhead = true;

			return;
		}
		else if(action_for_trigger_hurt == 2) // rocketjump
		{
			if(this.velocity.z < 0)
			{
				for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
				{
					.entity weaponentity = weaponentities[slot];

					if(this.(weaponentity).m_weapon == WEP_Null && slot != 0)
						continue;

					if(client_hasweapon(this, WEP_DEVASTATOR, weaponentity, true, false))
					{
						CS(this).movement_x = maxspeed;

						if(this.rocketjumptime)
						{
							if(time > this.rocketjumptime)
							{
								PHYS_INPUT_BUTTON_ATCK2(this) = true;
								this.rocketjumptime = 0;
							}
							return;
						}

						this.(weaponentity).m_switchweapon = WEP_DEVASTATOR;
						this.v_angle_x = 90;
						PHYS_INPUT_BUTTON_ATCK(this) = true;
						this.rocketjumptime = time + WEP_CVAR(WEP_DEVASTATOR, detonatedelay);
						return;
					}
				}
			}
		}
		else if(action_for_trigger_hurt == 3) // no goal
		{
			// If there is no goal try to move forward
			CS(this).movement_x = maxspeed;
		}
	}

	// If we are under water with no goals, swim up
	if(this.waterlevel && !this.goalcurrent)
	{
		dir = '0 0 0';
		if(this.waterlevel>WATERLEVEL_SWIMMING)
			dir.z = 1;
		else if(this.velocity.z >= 0 && !(this.waterlevel == WATERLEVEL_WETFEET && this.watertype == CONTENT_WATER))
			PHYS_INPUT_BUTTON_JUMP(this) = true;
		makevectors(this.v_angle.y * '0 1 0');
		vector v = dir * maxspeed;
		CS(this).movement.x = v * v_forward;
		CS(this).movement.y = v * v_right;
		CS(this).movement.z = v * v_up;
	}

	// if there is nowhere to go, exit
	if (this.goalcurrent == NULL)
		return;


	bool locked_goal = false;
	if((this.goalentity && wasfreed(this.goalentity))
		|| (this.goalcurrent == this.goalentity && this.goalentity.tag_entity))
	{
		navigation_clearroute(this);
		navigation_goalrating_timeout_force(this);
		return;
	}
	else if(this.goalentity.tag_entity)
	{
		navigation_goalrating_timeout_expire(this, 2);
	}
	else if(this.goalentity.bot_pickup)
	{
		if(this.goalentity.bot_pickup_respawning)
		{
			if(this.goalentity.solid) // item respawned
				this.goalentity.bot_pickup_respawning = false;
			else if(time < this.goalentity.scheduledrespawntime - 10) // item already taken (by someone else)
			{
				if(checkpvs(this.origin, this.goalentity))
				{
					this.goalentity.bot_pickup_respawning = false;
					navigation_goalrating_timeout_expire(this, random());
				}
				locked_goal = true; // wait for item to respawn
			}
			else if(this.goalentity == this.goalcurrent)
				locked_goal = true; // wait for item to respawn
		}
		else if(!this.goalentity.solid && !boxesoverlap(this.goalentity.absmin, this.goalentity.absmax, this.absmin, this.absmax))
		{
			if(checkpvs(this.origin, this.goalentity))
			{
				navigation_goalrating_timeout_expire(this, random());
			}
		}
	}
	if (this.goalcurrent == this.goalentity && this.goalentity_lock_timeout > time)
		locked_goal = true;

	if (navigation_shortenpath(this))
	{
		if (vdist(this.origin - this.goalcurrent_prev.origin, <, 50)
			&& navigation_goalrating_timeout_can_be_anticipated(this))
		{
			navigation_goalrating_timeout_force(this);
		}
	}

	bool goalcurrent_can_be_removed = false;
	if (IS_PLAYER(this.goalcurrent) || IS_MONSTER(this.goalcurrent))
	{
		bool freeze_state_changed = (boolean(STAT(FROZEN, this.goalentity)) != this.goalentity_shouldbefrozen);
		if (IS_DEAD(this.goalcurrent) || (this.goalentity == this.goalcurrent && freeze_state_changed))
		{
			goalcurrent_can_be_removed = true;
			// don't remove if not visible
			if (checkpvs(this.origin + this.view_ofs, this.goalcurrent))
			{
				if (IS_DEAD(this.goalcurrent))
				{
					IL_EACH(g_items, it.enemy == this.goalcurrent && ITEM_IS_LOOT(it),
					{
						if (vdist(it.origin - this.goalcurrent.death_origin, <, 50))
						{
							navigation_clearroute(this);
							navigation_pushroute(this, it);
							// loot can't be immediately rated since it isn't on ground yet
							// it will be rated after a second when on ground, meanwhile head to it
							navigation_goalrating_timeout_expire(this, 1);
							return;
						}
					});
				}
				if (!ITEM_IS_LOOT(this.goalcurrent))
				{
					navigation_goalrating_timeout_force(this);
					return;
				}
			}
		}
		else if (!(STAT(FROZEN, this.goalentity)) && this.bot_tracewalk_time < time)
		{
			set_tracewalk_dest(this.goalcurrent, this.origin, true);
			if (!(trace_ent == this || tracewalk(this, this.origin, this.mins, this.maxs,
				tracewalk_dest, tracewalk_dest_height, bot_navigation_movemode)))
			{
				navigation_goalrating_timeout_force(this);
				return;
			}
			this.bot_tracewalk_time = max(time, this.bot_tracewalk_time) + 0.25;
		}
	}

	if(!locked_goal)
	{
		// optimize path finding by anticipating goalrating when bot is near a waypoint;
		// in this case path finding can start directly from a waypoint instead of
		// looking for all the reachable waypoints up to a certain distance
		if (navigation_poptouchedgoals(this))
		{
			if (this.goalcurrent)
			{
				if (goalcurrent_can_be_removed)
				{
					// remove even if not visible
					navigation_goalrating_timeout_force(this);
					return;
				}
				else if (navigation_goalrating_timeout_can_be_anticipated(this))
					navigation_goalrating_timeout_force(this);
			}
			else
			{
				entity old_goal = this.goalcurrent_prev;
				if (old_goal.item_group && this.item_group != old_goal.item_group)
				{
					// Avoid multiple costly calls of path finding code that selects one of the closest
					// item of the group by telling the bot to head directly to the farthest item.
					// Next time we let the bot select a goal as usual which can be another item
					// of this group (the closest one) and so on
					this.item_group = old_goal.item_group;
					entity new_goal = havocbot_select_an_item_of_group(this, old_goal.item_group);
					if (new_goal)
						navigation_pushroute(this, new_goal);
				}
			}
		}
	}

	// if ran out of goals try to use an alternative goal or get a new strategy asap
	if(this.goalcurrent == NULL)
	{
		navigation_goalrating_timeout_force(this);
		return;
	}


	if(autocvar_bot_debug_goalstack)
		debuggoalstack(this);

	bool bunnyhop_forbidden = false;
	vector destorg = get_closer_dest(this.goalcurrent, this.origin);
	if (this.jumppadcount && (this.goalcurrent.wpflags & WAYPOINTFLAG_TELEPORT))
	{
		// if bot used the jumppad, push towards jumppad origin until jumppad waypoint gets removed
		destorg = this.goalcurrent.origin;
	}
	else if (this.goalcurrent.wpisbox)
	{
		// if bot is inside the teleport waypoint, head to teleport origin until teleport gets used
		// do it even if bot is on a ledge above a teleport/jumppad so it doesn't get stuck
		if (boxesoverlap(this.goalcurrent.absmin, this.goalcurrent.absmax, this.origin + eZ * this.mins.z, this.origin + eZ * this.maxs.z)
			|| (this.absmin.z > destorg.z && destorg.x == this.origin.x && destorg.y == this.origin.y))
		{
			bunnyhop_forbidden = true;
			destorg = this.goalcurrent.origin;
			if(destorg.z > this.origin.z)
				PHYS_INPUT_BUTTON_JUMP(this) = true;
		}
	}

	diff = destorg - this.origin;

	if (time < this.bot_stop_moving_timeout
		|| (this.goalcurrent == this.goalentity && time < this.goalentity_lock_timeout && vdist(diff, <, 10)))
	{
		// stop if the locked goal has been reached
		destorg = this.origin;
		diff = dir = '0 0 0';
	}
	else if (IS_PLAYER(this.goalcurrent) || IS_MONSTER(this.goalcurrent))
	{
		if (vdist(diff, <, 80))
		{
			// stop if too close to target player (even if frozen)
			destorg = this.origin;
			diff = dir = '0 0 0';
		}
		else
		{
			// move destorg out of target players, otherwise bot will consider them
			// an obstacle that needs to be jumped (especially if frozen)
			dir = normalize(diff);
			destorg -= dir * PL_MAX_CONST.x * M_SQRT2;
			diff = destorg - this.origin;
		}
	}
	else
		dir = normalize(diff);
	flatdir = (diff.z == 0) ? dir : normalize(vec2(diff));

	bool danger_detected = false;
	vector do_break = '0 0 0';

	//if (this.bot_dodgevector_time < time)
	{
		//this.bot_dodgevector_time = time + cvar("bot_ai_dodgeupdateinterval");
		//this.bot_dodgevector_jumpbutton = 1;

		this.aistatus &= ~AI_STATUS_DANGER_AHEAD;
		makevectors(this.v_angle.y * '0 1 0');
		if (this.waterlevel > WATERLEVEL_WETFEET)
		{
			if (this.waterlevel > WATERLEVEL_SWIMMING)
			{
				if(!this.goalcurrent)
					this.aistatus |= AI_STATUS_OUT_WATER;
				else if(destorg.z > this.origin.z)
					PHYS_INPUT_BUTTON_JUMP(this) = true;
			}
			else
			{
				if(this.velocity.z >= 0 && !(this.watertype == CONTENT_WATER && destorg.z < this.origin.z) &&
					(this.aistatus & AI_STATUS_OUT_WATER))
				{
					PHYS_INPUT_BUTTON_JUMP(this) = true;
					dir = flatdir;
				}
				else
				{
					if (destorg.z > this.origin.z)
						dir = flatdir;
				}
			}
		}
		else
		{
			float s = 0;
			vector offset;
			if(this.aistatus & AI_STATUS_OUT_WATER)
				this.aistatus &= ~AI_STATUS_OUT_WATER;

			// jump if going toward an obstacle that doesn't look like stairs we
			// can walk up directly
			vector deviation = '0 0 0';
			float current_speed = vlen(vec2(this.velocity));
			if (current_speed < maxspeed * 0.2)
				current_speed = maxspeed * 0.2;
			else
			{
				deviation = vectoangles(diff) - vectoangles(this.velocity);
				while (deviation.y < -180) deviation.y += 360;
				while (deviation.y > 180) deviation.y -= 360;
			}
			float turning = false;
			vector flat_diff = vec2(diff);
			offset = max(32, current_speed * cos(deviation.y * DEG2RAD) * 0.3) * flatdir;
			vector actual_destorg = this.origin + offset;
			if (this.goalcurrent_prev && (this.goalcurrent_prev.wpflags & WAYPOINTFLAG_JUMP))
			{
				if (time > this.bot_stop_moving_timeout
					&& fabs(deviation.y) > 20 && current_speed > maxspeed * 0.4
					&& vdist(vec2(this.origin - this.goalcurrent_prev.origin), <, 50))
				{
					this.bot_stop_moving_timeout = time + 0.1;
				}
				if (current_speed > autocvar_sv_maxspeed * 0.9
					&& vlen2(flat_diff) < vlen2(vec2(this.goalcurrent_prev.origin - destorg))
					&& vdist(vec2(this.origin - this.goalcurrent_prev.origin), >, 50)
					&& vdist(vec2(this.origin - this.goalcurrent_prev.origin), <, 150)
				)
				{
					PHYS_INPUT_BUTTON_JUMP(this) = true;
					this.bot_jump_time = time;
				}
			}
			else if (!this.goalstack01 || (this.goalcurrent.wpflags & (WAYPOINTFLAG_TELEPORT | WAYPOINTFLAG_LADDER)))
			{
				if (vlen2(flat_diff) < vlen2(offset))
				{
					if ((this.goalcurrent.wpflags & WAYPOINTFLAG_JUMP) && this.goalstack01)
					{
						// oblique warpzones need a jump otherwise bots gets stuck
						PHYS_INPUT_BUTTON_JUMP(this) = true;
					}
					else
					{
						actual_destorg.x = destorg.x;
						actual_destorg.y = destorg.y;
					}
				}
			}
			else if (vdist(flat_diff, <, 32) && diff.z < -16) // destination is under the bot
			{
				actual_destorg.x = destorg.x;
				actual_destorg.y = destorg.y;
			}
			else if (vlen2(flat_diff) < vlen2(offset))
			{
				vector next_goal_org = (this.goalstack01.absmin + this.goalstack01.absmax) * 0.5;
				vector next_dir = normalize(vec2(next_goal_org - destorg));
				float dist = vlen(vec2(this.origin + offset - destorg));
				// if current and next goal are close to each other make sure
				// actual_destorg isn't set beyond next_goal_org
				if (dist ** 2 > vlen2(vec2(next_goal_org - destorg)))
					actual_destorg = next_goal_org;
				else
					actual_destorg = vec2(destorg) + dist * next_dir;
				actual_destorg.z = this.origin.z;
				turning = true;
			}

			LABEL(jumpobstacle_check);
			dir = flatdir = normalize(actual_destorg - this.origin);

			bool jump_forbidden = false;
			if (!turning && fabs(deviation.y) > 50)
				jump_forbidden = true;
			else if (IS_DUCKED(this))
			{
				tracebox(this.origin, PL_MIN_CONST, PL_MAX_CONST, this.origin, false, this);
				if (trace_startsolid)
					jump_forbidden = true;
			}

			if (!jump_forbidden)
			{
				tracebox(this.origin, this.mins, this.maxs, actual_destorg, false, this);
				if (trace_fraction < 1 && trace_plane_normal.z < 0.7)
				{
					s = trace_fraction;
					tracebox(this.origin + stepheightvec, this.mins, this.maxs, actual_destorg + stepheightvec, false, this);
					if (trace_fraction < s + 0.01 && trace_plane_normal.z < 0.7)
					{
						// found an obstacle
						if (turning && fabs(deviation.y) > 5)
						{
							// check if the obstacle is still there without turning
							actual_destorg = destorg;
							turning = false;
							this.bot_tracewalk_time = time + 0.25;
							goto jumpobstacle_check;
						}
						s = trace_fraction;
						// don't artificially reduce max jump height in real-time
						// (jumpstepheightvec is reduced a bit to make the jumps easy in tracewalk)
						vector jump_height = (IS_ONGROUND(this)) ? stepheightvec + jumpheight_vec : jumpstepheightvec;
						tracebox(this.origin + jump_height, this.mins, this.maxs, actual_destorg + jump_height, false, this);
						if (trace_fraction > s)
						{
							PHYS_INPUT_BUTTON_JUMP(this) = true;
							this.bot_jump_time = time;
						}
						else
						{
							jump_height = stepheightvec + jumpheight_vec * 0.5;
							tracebox(this.origin + jump_height, this.mins, this.maxs, actual_destorg + jump_height, false, this);
							if (trace_fraction > s)
							{
								PHYS_INPUT_BUTTON_JUMP(this) = true;
								this.bot_jump_time = time;
							}
						}
					}
				}
			}

			// if bot for some reason doesn't get close to the current goal find another one
			if(!this.jumppadcount && !IS_PLAYER(this.goalcurrent))
			if(!(locked_goal && this.goalcurrent_distance_z < 50 && this.goalcurrent_distance_2d < 50))
			if(havocbot_checkgoaldistance(this, destorg))
			{
				if(this.goalcurrent_distance_time < 0) // can't get close for the second time
				{
					navigation_clearroute(this);
					navigation_goalrating_timeout_force(this);
					return;
				}

				set_tracewalk_dest(this.goalcurrent, this.origin, false);
				if (!tracewalk(this, this.origin, this.mins, this.maxs,
					tracewalk_dest, tracewalk_dest_height, bot_navigation_movemode))
				{
					navigation_clearroute(this);
					navigation_goalrating_timeout_force(this);
					return;
				}

				// give bot only another chance to prevent bot getting stuck
				// in case it thinks it can walk but actually can't
				this.goalcurrent_distance_z = FLOAT_MAX;
				this.goalcurrent_distance_2d = FLOAT_MAX;
				this.goalcurrent_distance_time = -time; // mark second try
			}

			if (skill + this.bot_moveskill <= 3 && time > this.bot_stop_moving_timeout
				&& current_speed > maxspeed * 0.9 && fabs(deviation.y) > 70)
			{
				this.bot_stop_moving_timeout = time + 0.4 + random() * 0.2;
			}

			// Check for water/slime/lava and dangerous edges
			// (only when the bot is on the ground or jumping intentionally)
			offset = (vdist(this.velocity, >, 32) ? this.velocity * 0.2 : flatdir * 32);
			vector dst_ahead = this.origin + this.view_ofs + offset;
			bool unreachable = false;
			int r = havocbot_checkdanger(this, dst_ahead);
			if (r > 0 && r < 4)
				danger_detected = true;
			else if (r == 4)
			{
				if (destorg.z > this.origin.z + jumpstepheightvec.z)
				{
					// the goal is probably on an upper platform, assume bot can't get there
					unreachable = true;
				}
				else
					danger_detected = true;
			}

			dir = flatdir;
			makevectors(this.v_angle.y * '0 1 0');

			if (danger_detected || (s == CONTENT_WATER))
			{
				this.aistatus |= AI_STATUS_DANGER_AHEAD;
				if(IS_PLAYER(this.goalcurrent))
					unreachable = true;
			}

			// slow down if bot is in the air and goal is under it
			if (!waypoint_is_hardwiredlink(this.goalcurrent_prev, this.goalcurrent)
				&& vdist(flat_diff, <, 250) && this.origin.z - destorg.z > 120
				&& (!IS_ONGROUND(this) || vdist(vec2(this.velocity), >, maxspeed * 0.3)))
			{
				// tracebox wouldn't work when bot is still on the ledge
				traceline(this.origin, this.origin - '0 0 200', true, this);
				if (this.origin.z - trace_endpos.z > 120)
					do_break = normalize(this.velocity) * -1;
			}

			if(unreachable)
			{
				navigation_clearroute(this);
				navigation_goalrating_timeout_force(this);
				this.ignoregoal = this.goalcurrent;
				this.ignoregoaltime = time + autocvar_bot_ai_ignoregoal_timeout;
			}
		}

		dodge = havocbot_dodge(this);
		if (dodge)
			dodge *= bound(0, 0.5 + (skill + this.bot_dodgeskill) * 0.1, 1);
		// midair sets moveskill to 0 so avoid jumping when dodging in midair mutator
		if (dodge.z > 0 && this.bot_moveskill == 0)
			dodge.z = 0;
		if (this.enemy)
		{
			traceline(this.origin, (this.enemy.absmin + this.enemy.absmax) * 0.5, true, NULL);
			if (IS_PLAYER(trace_ent))
				dodge_enemy_factor = bound(0, (skill + this.bot_dodgeskill) / 7, 1);
		}
		//this.bot_dodgevector = dir;
		//this.bot_dodgevector_jumpbutton = PHYS_INPUT_BUTTON_JUMP(this);

		// don't dodge to danger
		if (havocbot_checkdanger(this, this.origin + this.view_ofs + dodge * 32))
		{
			dodge = '0 0 0';
		}
	}

	float ladder_zdir = 0;
	if(this.ladder_entity)
	{
		if(this.goalcurrent.origin.z + this.goalcurrent.mins.z > this.origin.z + this.mins.z)
		{
			if(this.origin.z + this.mins.z  < this.ladder_entity.origin.z + this.ladder_entity.maxs.z)
				ladder_zdir = 1;
		}
		else
		{
			if(this.origin.z + this.mins.z  > this.ladder_entity.origin.z + this.ladder_entity.mins.z)
				ladder_zdir = -1;
		}
		if (ladder_zdir)
		{
			if (vdist(vec2(diff), <, 40))
				dir.z = ladder_zdir * 4;
			else
				dir.z = ladder_zdir * 2;
			dir = normalize(dir);
		}
	}

	if (this.goalcurrent.wpisbox
		&& boxesoverlap(this.goalcurrent.absmin, this.goalcurrent.absmax, this.origin, this.origin))
	{
		// bot is inside teleport waypoint but hasn't touched the real teleport yet
		// head to teleport origin
		dir = (this.goalcurrent.origin - this.origin);
		dir.z = 0;
		dir = normalize(dir);
	}

	// already executed when bot targets an enemy
	if (!this.bot_aimdir_executed)
	{
		if (time < this.bot_stop_moving_timeout)
			bot_aimdir(this, normalize(this.goalcurrent.origin - this.origin), 0);
		else
			bot_aimdir(this, dir, 0);
	}

	vector evadedanger = '0 0 0';
	if (!ladder_zdir)
	{
		dir *= dodge_enemy_factor;
		if (danger_detected && vdist(this.velocity, >, maxspeed * 0.8) && this.goalcurrent_prev
			&& this.goalcurrent.classname == "waypoint")
		{
			vector p = this.origin + this.velocity * 0.2;
			vector evadedanger = point_line_vec(p, vec2(this.goalcurrent_prev.origin) + eZ * p.z,
				vec2(destorg - this.goalcurrent_prev.origin));
			if (vdist(evadedanger, >, 20))
			{
				if (vdist(evadedanger, >, 40))
					do_break = normalize(this.velocity) * -1;
				evadedanger = normalize(evadedanger);
				evadedanger *= bound(1, 3 - (skill + this.bot_dodgeskill), 3); // Noobs fear dangers a lot and take more distance from them
			}
			else
				evadedanger = '0 0 0';
		}
		dir = normalize(dir + dodge + do_break + evadedanger);
	}

	makevectors(this.v_angle);
	//dir = this.bot_dodgevector;
	//if (this.bot_dodgevector_jumpbutton)
	//	PHYS_INPUT_BUTTON_JUMP(this) = true;
	CS(this).movement_x = dir * v_forward * maxspeed;
	CS(this).movement_y = dir * v_right * maxspeed;
	CS(this).movement_z = dir * v_up * maxspeed;

	// when high enough skill bots engage in combat they move randomly
	if (SUPERBOT && this.aistatus == AI_STATUS_ATTACKING && !dodge)
	{
		if (!this.randomdirectiontime || this.randomdirectiontime + 0.35 < time)
		{
			// 75% chance to generate a random direction to follow for
			// 0.3 seconds, there's a 15% chance to fail the generation
			// and only generation attempt one every 0.35s so bots move
			// towards their goal slightly
			if (random() < 0.15)
				this.randomdirection = '0 0 0';
			else
			{
				// random values from -1 to 1
				this.randomdirection.x = crandom() * maxspeed;
				this.randomdirection.y = crandom() * maxspeed;
				//this.randomdirection.z = crandom() * maxspeed;
			}

			this.randomdirectiontime = time;
		}
		if (this.randomdirectiontime + 0.3 >= time && this.randomdirection)
		{
			CS(this).movement_x = this.randomdirection.x;
			CS(this).movement_y = this.randomdirection.y;
			// no random vertical direction
		}
	}


	// Emulate keyboard interface
	if (skill < 10)
		havocbot_keyboard_movement(this, destorg);

	// Bunnyhop!
	if (!bunnyhop_forbidden && !evadedanger && !do_break && skill + this.bot_moveskill >= autocvar_bot_ai_bunnyhop_skilloffset)
		havocbot_bunnyhop(this, dir);

	if (dir * v_up >= autocvar_sv_jumpvelocity * 0.5 && IS_ONGROUND(this))
		PHYS_INPUT_BUTTON_JUMP(this) = true;
	if (dodge)
	{
		if (dodge * v_up > 0 && random() * frametime >= 0.2 * bound(0, (10 - skill - this.bot_dodgeskill) * 0.1, 1))
			PHYS_INPUT_BUTTON_JUMP(this) = true;
		if (dodge * v_up < 0 && random() * frametime >= 0.5 * bound(0, (10 - skill - this.bot_dodgeskill) * 0.1, 1))
		{
			if(IS_ONGROUND(this))
				PHYS_INPUT_BUTTON_JUMP(this) = false;
			this.havocbot_ducktime = time + 0.3 / bound(0.1, skill + this.bot_dodgeskill, 10);
			PHYS_INPUT_BUTTON_CROUCH(this) = true;
		}
	}
}

void havocbot_chooseenemy(entity this)
{
	if (autocvar_bot_nofire || IS_INDEPENDENT_PLAYER(this))
	{
		this.enemy = NULL;
		return;
	}

	if (this.enemy)
	{
		if (!bot_shouldattack(this, this.enemy))
		{
			// enemy died or something, find a new target
			this.enemy = NULL;
			this.havocbot_chooseenemy_finished = time;
		}
		else if (this.havocbot_stickenemy_time && time < this.havocbot_stickenemy_time)
		{
			// tracking last chosen enemy
			vector targ_pos = (this.enemy.absmin + this.enemy.absmax) * 0.5;
			traceline(this.origin + this.view_ofs, targ_pos, false, NULL);
			if (trace_ent == this.enemy || trace_fraction == 1)
			if (vdist(targ_pos - this.origin, <, 1000))
			{
				// remain tracking them for a shot while (case they went after a small corner or pilar
				this.havocbot_chooseenemy_finished = time + 0.5;
				return;
			}

			// stop preferring this enemy
			this.havocbot_stickenemy_time = 0;
		}
	}
	if (time < this.havocbot_chooseenemy_finished)
		return;
	// don't limit the detection interval to several seconds for bots with enough skill
	if (SUPERBOT)
		this.havocbot_chooseenemy_finished = time + 0.1;
	else
		this.havocbot_chooseenemy_finished = time + autocvar_bot_ai_enemydetectioninterval;

	vector eye = this.origin + this.view_ofs;
	entity best = NULL;
	float bestrating = autocvar_bot_ai_enemydetectionradius ** 2;

	// Backup hit flags
	int hf = this.dphitcontentsmask;

	// Search for enemies, if no enemy can be seen directly try to look through transparent objects

	this.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_CORPSE;

	bool scan_transparent = false;
	bool scan_secondary_targets = false;
	bool have_secondary_targets = false;
	while(true)
	{
		scan_secondary_targets = false;
		LABEL(scan_targets)
		IL_EACH(g_bot_targets, it.bot_attack,
		{
			if(!scan_secondary_targets)
			{
				if(it.classname == "misc_breakablemodel")
				{
					have_secondary_targets = true;
					continue;
				}
			}
			else if(it.classname != "misc_breakablemodel")
				continue;

			vector v = (it.absmin + it.absmax) * 0.5;
			float distance = vlen2(v - eye);

			if (SUPERBOT)
			{
				if (bot_shouldattack(this, it))
				{
					// skilled enough bots take account target health and distance
					float health = GetResource(it, RES_HEALTH);
					float armor  = GetResource(it, RES_ARMOR);
					float rating = bound(50, health + armor, 250) * distance;
					if (!best || (rating < bestrating))
					{
						traceline(eye, v, true, this);
						if (trace_ent == it || trace_fraction >= 1)
						{
							best = it;
							bestrating = rating;
						}
					}
				}
			}
			else
			{
				if (distance < bestrating && bot_shouldattack(this, it))
				{
					traceline(eye, v, true, this);
					if (trace_ent == it || trace_fraction >= 1)
					{
						best = it;
						bestrating = distance;
					}
				}
			}
		});

		if(!best && have_secondary_targets && !scan_secondary_targets)
		{
			scan_secondary_targets = true;
			// restart the loop
			bestrating = autocvar_bot_ai_enemydetectionradius ** 2;

			goto scan_targets;
		}

		// I want to do a second scan if no enemy was found or I don't have weapons
		// TODO: Perform the scan when using the rifle (requires changes on the rifle code)
		if(best || STAT(WEAPONS, this)) // || this.weapon == WEP_RIFLE.m_id
			break;
		if(scan_transparent)
			break;

		// Set flags to see through transparent objects
		this.dphitcontentsmask |= DPCONTENTS_OPAQUE;

		scan_transparent = true;
	}

	// Restore hit flags
	this.dphitcontentsmask = hf;

	this.enemy = best;
	this.havocbot_stickenemy_time = time + autocvar_bot_ai_enemydetectioninterval_stickingtoenemy;
	if(best && best.classname == "misc_breakablemodel")
		this.havocbot_stickenemy_time = 0;
}

bool havocbot_chooseweapon_checkreload(entity this, .entity weaponentity, int new_weapon)
{
	// bots under this skill cannot find unloaded weapons to reload idly when not in combat,
	// so skip this for them, or they'll never get to reload their weapons at all.
	// this also allows bots under this skill to be more stupid, and reload more often during combat :)
	if(skill < 5)
		return false;

	// if this weapon is scheduled for reloading, don't switch to it during combat
	if (this.(weaponentity).weapon_load[new_weapon] < 0)
	{
		if(this.items & IT_UNLIMITED_AMMO)
			return true;
		FOREACH(Weapons, it != WEP_Null, {
			if(it.wr_checkammo1(it, this, weaponentity) + it.wr_checkammo2(it, this, weaponentity))
				return true; // other weapon available
		});
	}

	return false;
}

void havocbot_chooseweapon(entity this, .entity weaponentity)
{
	int i;
	float w;

	// ;)
	if(g_weaponarena_weapons == WEPSET(TUBA))
	{
		this.(weaponentity).m_switchweapon = WEP_TUBA;
		return;
	}

	// TODO: clean this up by moving it to weapon code
	if (this.enemy == NULL)
	{
		// Choose the first available weapon from medium range weaponlist
		// TODO: don't do this but don't make bots hold out a blaster out either
		for (i = 0; i < REGISTRY_COUNT(Weapons) && bot_weapons_mid[i] != -1 ; ++i){
			w = bot_weapons_mid[i];
			if (bot_custom_weapon)
			{
				if (client_hasweapon(this, REGISTRY_GET(Weapons, w), weaponentity, true, false))
				{
					if ((this.(weaponentity).m_weapon == WEP_Null) || havocbot_chooseweapon_checkreload(this, weaponentity, w))
						continue;
					this.(weaponentity).m_switchweapon = REGISTRY_GET(Weapons, w);
					return;
				}
			}
		}

		// If no weapon was chosen get the first available weapon
		if (this.(weaponentity).m_weapon == WEP_Null)
			FOREACH(Weapons, it != WEP_Null, {
				if (client_hasweapon(this, it, weaponentity, true, false))
				{
					this.(weaponentity).m_switchweapon = it;
					return;
				}
			});
		return;
	}

	// Do not change weapon during the next second after a combo
	if(time - this.lastcombotime < 1)
		return;

	// Should it do a weapon combo?

	float af = ((this.weaponentity.m_weapon == WEP_Null) ? 0 : ATTACK_FINISHED(this, weaponentity));
	float ct = autocvar_bot_ai_weapon_combo_threshold;

	// Bots with no skill will be 4 times slower than "godlike" bots when doing weapon combos
	// Ideally this 4 should be calculated as longest_weapon_refire / bot_ai_weapon_combo_threshold
	float combo_time = time + ct * (4 - 0.3 * (skill + this.bot_weaponskill));

	bool combo = false;

	if(autocvar_bot_ai_weapon_combo)
	if(this.(weaponentity).m_weapon.m_id == this.(weaponentity).lastfiredweapon)
	if(af > combo_time)
	{
		combo = true;
		this.lastcombotime = time;
	}

	// Custom weapon list based on distance to the enemy
	if(bot_custom_weapon)
	{
		float distance = bound(10, vlen(this.origin - this.enemy.origin) - 200, 10000);
		distance *= (2 ** this.bot_rangepreference);

		// Choose weapons for far distance
		if ( distance > bot_distance_far ) {
			for(i=0; i < REGISTRY_COUNT(Weapons) && bot_weapons_far[i] != -1 ; ++i){
				w = bot_weapons_far[i];
				if ( client_hasweapon(this, REGISTRY_GET(Weapons, w), weaponentity, true, false) )
				{
					if ((this.(weaponentity).m_weapon.m_id == w && combo) || havocbot_chooseweapon_checkreload(this, weaponentity, w))
						continue;
					this.(weaponentity).m_switchweapon = REGISTRY_GET(Weapons, w);
					return;
				}
			}
		}

		// Choose weapons for mid distance
		if ( distance > bot_distance_close) {
			for(i=0; i < REGISTRY_COUNT(Weapons) && bot_weapons_mid[i] != -1 ; ++i){
				w = bot_weapons_mid[i];
				if ( client_hasweapon(this, REGISTRY_GET(Weapons, w), weaponentity, true, false) )
				{
					if ((this.(weaponentity).m_weapon.m_id == w && combo) || havocbot_chooseweapon_checkreload(this, weaponentity, w))
						continue;
					this.(weaponentity).m_switchweapon = REGISTRY_GET(Weapons, w);
					return;
				}
			}
		}

		// Choose weapons for close distance
		for(i=0; i < REGISTRY_COUNT(Weapons) && bot_weapons_close[i] != -1 ; ++i){
			w = bot_weapons_close[i];
			if ( client_hasweapon(this, REGISTRY_GET(Weapons, w), weaponentity, true, false) )
			{
				if ((this.(weaponentity).m_weapon.m_id == w && combo) || havocbot_chooseweapon_checkreload(this, weaponentity, w))
					continue;
				this.(weaponentity).m_switchweapon = REGISTRY_GET(Weapons, w);
				return;
			}
		}
	}
}

void havocbot_aim(entity this)
{
	// if aim rate is a multiple of think rate due to precision errors the sum of multiple think times
	// can be slightly greater than aim time and cause a jump of a whole think time (bot_netxtthink)
	// in that case this small tolerance time makes so that aim time snaps to think time
	if (time < this.nextaim - 0.01)
		return;
	this.nextaim = time + 0.1;

	vector myvel = this.velocity;
	if (!this.waterlevel)
		myvel.z = 0;
	if(MUTATOR_CALLHOOK(HavocBot_Aim, this)) { /* do nothing */ }
	else if (this.enemy)
	{
		vector enemyvel = this.enemy.velocity;
		if (!this.enemy.waterlevel)
			enemyvel.z = 0;
	}
}

bool havocbot_moveto_refresh_route(entity this)
{
	// Refresh path to goal if necessary
	entity wp;
	wp = this.havocbot_personal_waypoint;
	navigation_goalrating_start(this);
	navigation_routerating(this, wp, 10000, 10000);
	navigation_goalrating_end(this);
	return (this.goalentity != NULL);
}

float havocbot_moveto(entity this, vector pos)
{
	entity wp;

	if(this.aistatus & AI_STATUS_WAYPOINT_PERSONAL_GOING)
	{
		// Step 4: Move to waypoint
		if(this.havocbot_personal_waypoint==NULL)
		{
			LOG_TRACE("Error: ", this.netname, " trying to walk to a non existent personal waypoint");
			this.aistatus &= ~AI_STATUS_WAYPOINT_PERSONAL_GOING;
			return CMD_STATUS_ERROR;
		}

		if (!bot_strategytoken_taken)
		if(this.havocbot_personal_waypoint_searchtime<time)
		{
			bot_strategytoken_taken = true;
			if(havocbot_moveto_refresh_route(this))
			{
				LOG_TRACE(this.netname, " walking to its personal waypoint (after ", ftos(this.havocbot_personal_waypoint_failcounter), " failed attempts)");
				this.havocbot_personal_waypoint_searchtime = time + 10;
				this.havocbot_personal_waypoint_failcounter = 0;
			}
			else
			{
				this.havocbot_personal_waypoint_failcounter += 1;
				this.havocbot_personal_waypoint_searchtime = time + 2;
				if(this.havocbot_personal_waypoint_failcounter >= 30)
				{
					LOG_TRACE("Warning: can't walk to the personal waypoint located at ", vtos(this.havocbot_personal_waypoint.origin));
					this.aistatus &= ~AI_STATUS_WAYPOINT_PERSONAL_LINKING;
					delete(this.havocbot_personal_waypoint);
					return CMD_STATUS_ERROR;
				}
				else
					LOG_TRACE(this.netname, " can't walk to its personal waypoint (after ", ftos(this.havocbot_personal_waypoint_failcounter), " failed attempts), trying later");
			}
		}

		if(autocvar_bot_debug_goalstack)
			debuggoalstack(this);


		// Go!
		havocbot_movetogoal(this);

		if (!this.bot_aimdir_executed && this.goalcurrent)
		{
			// Heading
			vector dir = get_closer_dest(this.goalcurrent, this.origin);
			dir -= this.origin + this.view_ofs;
			dir.z = 0;
			bot_aimdir(this, dir, 0);
		}

		if(this.aistatus & AI_STATUS_WAYPOINT_PERSONAL_REACHED)
		{
			// Step 5: Waypoint reached
			LOG_TRACE(this.netname, "'s personal waypoint reached");
			waypoint_remove(this.havocbot_personal_waypoint);
			this.aistatus &= ~AI_STATUS_WAYPOINT_PERSONAL_REACHED;
			return CMD_STATUS_FINISHED;
		}

		return CMD_STATUS_EXECUTING;
	}

	// Step 2: Linking waypoint
	if(this.aistatus & AI_STATUS_WAYPOINT_PERSONAL_LINKING)
	{
		// Wait until it is linked
		if(!this.havocbot_personal_waypoint.wplinked)
		{
			LOG_TRACE(this.netname, " waiting for personal waypoint to be linked");
			return CMD_STATUS_EXECUTING;
		}

		this.havocbot_personal_waypoint_searchtime = time; // so we set the route next frame
		this.aistatus &= ~AI_STATUS_WAYPOINT_PERSONAL_LINKING;
		this.aistatus |= AI_STATUS_WAYPOINT_PERSONAL_GOING;

		// Step 3: Route to waypoint
		LOG_TRACE(this.netname, " walking to its personal waypoint");

		return CMD_STATUS_EXECUTING;
	}

	// Step 1: Spawning waypoint
	wp = waypoint_spawnpersonal(this, pos);
	if(wp==NULL)
	{
		LOG_TRACE("Error: Can't spawn personal waypoint at ",vtos(pos));
		return CMD_STATUS_ERROR;
	}

	this.havocbot_personal_waypoint = wp;
	this.havocbot_personal_waypoint_failcounter = 0;
	this.aistatus |= AI_STATUS_WAYPOINT_PERSONAL_LINKING;

	// if pos is inside a teleport, then let's mark it as teleport waypoint
	IL_EACH(g_teleporters, WarpZoneLib_BoxTouchesBrush(pos, pos, it, NULL),
	{
		wp.wpflags |= WAYPOINTFLAG_TELEPORT;
		this.lastteleporttime = 0;
	});

/*
	if(wp.wpflags & WAYPOINTFLAG_TELEPORT)
		print("routing to a teleporter\n");
	else
		print("routing to a non-teleporter\n");
*/

	return CMD_STATUS_EXECUTING;
}

float havocbot_resetgoal(entity this)
{
	navigation_clearroute(this);
	return CMD_STATUS_FINISHED;
}

void havocbot_setupbot(entity this)
{
	this.bot_ai = havocbot_ai;
	this.cmd_moveto = havocbot_moveto;
	this.cmd_resetgoal = havocbot_resetgoal;

	// NOTE: bot is not player yet
	havocbot_chooserole(this);
}

vector havocbot_dodge(entity this)
{
	// LordHavoc: disabled because this is too expensive
	// Dr. Jaska: re-enable this but only for bots with high enough skill
	if (!SUPERBOT)
		return '0 0 0';

#if 1
	entity head;
	vector dodge, v, n;
	float danger, bestdanger, vl, d;
	dodge = '0 0 0';
	bestdanger = -20;
	// check for dangerous objects near bot or approaching bot
	head = findchainfloat(bot_dodge, true);
	while(head)
	{
		if (head.owner != this)
		{
			vl = vlen(head.velocity);
			if (vl > autocvar_sv_maxspeed * 0.3)
			{
				n = normalize(head.velocity);
				v = this.origin - head.origin;
				d = v * n;
				if (d > (0 - head.bot_dodgerating))
				if (d < (vl * 0.2 + head.bot_dodgerating))
				{
					// calculate direction and distance from the
					// flight path by removing the forward axis
					v = v - (n * (v * n));
					danger = head.bot_dodgerating - vlen(v);
					if (bestdanger < danger)
					{
						bestdanger = danger;
						// dodge to the side of the object
						dodge = normalize(v);
					}
				}
			}
			else
			{
				danger = head.bot_dodgerating - vlen(head.origin - this.origin);
				if (bestdanger < danger)
				{
					bestdanger = danger;
					dodge = normalize(this.origin - head.origin);
				}
			}
		}
		head = head.chain;
	}
	return dodge;
#else
	return '0 0 0';
#endif
}
