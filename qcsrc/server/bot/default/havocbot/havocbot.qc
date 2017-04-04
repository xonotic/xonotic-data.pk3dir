#include "havocbot.qh"

#include "../cvars.qh"

#include "../aim.qh"
#include "../bot.qh"
#include "../navigation.qh"
#include "../scripting.qh"
#include "../waypoints.qh"

#include <common/constants.qh>
#include <common/impulses/all.qh>
#include <common/net_linked.qh>
#include <common/physics/player.qh>
#include <common/state.qh>
#include <common/items/_mod.qh>
#include <common/wepent.qh>

#include <common/triggers/teleporters.qh>
#include <common/triggers/trigger/jumppads.qh>

#include <lib/warpzone/common.qh>

.float speed;

void havocbot_ai(entity this)
{
	if(this.draggedby)
		return;

	if(bot_execute_commands(this))
		return;

	if (bot_strategytoken == this)
	if (!bot_strategytoken_taken)
	{
		if(this.havocbot_blockhead)
		{
			this.havocbot_blockhead = false;
		}
		else
		{
			if (!this.jumppadcount && !STAT(FROZEN, this))
				this.havocbot_role(this); // little too far down the rabbit hole
		}

		// TODO: tracewalk() should take care of this job (better path finding under water)
		// if we don't have a goal and we're under water look for a waypoint near the "shore" and push it
		if(!(IS_DEAD(this) || STAT(FROZEN, this)))
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

	if(IS_DEAD(this) || STAT(FROZEN, this))
		return;

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
	lag_update(this);
	if (this.bot_aimtarg)
	{
		this.aistatus |= AI_STATUS_ATTACKING;
		this.aistatus &= ~AI_STATUS_ROAMING;

		if(this.weapons)
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
			if(IS_PLAYER(this.bot_aimtarg))
				bot_aimdir(this, this.bot_aimtarg.origin + this.bot_aimtarg.view_ofs - this.origin - this.view_ofs , -1);
		}
	}
	else if (this.goalcurrent)
	{
		this.aistatus |= AI_STATUS_ROAMING;
		this.aistatus &= ~AI_STATUS_ATTACKING;

		vector now,v,next;//,heading;
		float aimdistance,skillblend,distanceblend,blend;
		next = now = ( (this.goalcurrent.absmin + this.goalcurrent.absmax) * 0.5) - (this.origin + this.view_ofs);
		aimdistance = vlen(now);
		//heading = this.velocity;
		//dprint(this.goalstack01.classname,etos(this.goalstack01),"\n");
		if(
			this.goalstack01 != this && this.goalstack01 && !wasfreed(this.goalstack01) && ((this.aistatus & AI_STATUS_RUNNING) == 0) &&
			!(this.goalcurrent.wpflags & WAYPOINTFLAG_TELEPORT)
		)
			next = ((this.goalstack01.absmin + this.goalstack01.absmax) * 0.5) - (this.origin + this.view_ofs);

		skillblend=bound(0,(skill+this.bot_moveskill-2.5)*0.5,1); //lower skill player can't preturn
		distanceblend=bound(0,aimdistance/autocvar_bot_ai_keyboard_distance,1);
		blend = skillblend * (1-distanceblend);
		//v = (now * (distanceblend) + next * (1-distanceblend)) * (skillblend) + now * (1-skillblend);
		//v = now * (distanceblend) * (skillblend) + next * (1-distanceblend) * (skillblend) + now * (1-skillblend);
		//v = now * ((1-skillblend) + (distanceblend) * (skillblend)) + next * (1-distanceblend) * (skillblend);
		v = now + blend * (next - now);
		//dprint(etos(this), " ");
		//dprint(vtos(now), ":", vtos(next), "=", vtos(v), " (blend ", ftos(blend), ")\n");
		//v = now * (distanceblend) + next * (1-distanceblend);
		if (this.waterlevel < WATERLEVEL_SWIMMING)
			v.z = 0;
		//dprint("walk at:", vtos(v), "\n");
		//te_lightning2(NULL, this.origin, this.goalcurrent.origin);
		bot_aimdir(this, v, -1);
	}
	havocbot_movetogoal(this);

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
				this.impulse = IMP_weapon_reload.impulse; // not sure if this is done right

			// if we're not reloading a weapon, switch to any weapon in our invnetory that's not fully loaded to reload it next
			// the code above executes next frame, starting the reloading then
			if(skill >= 5) // bots can only look for unloaded weapons past this skill
			if(this.(weaponentity).clip_load >= 0) // only if we're not reloading a weapon already
			{
				FOREACH(Weapons, it != WEP_Null, LAMBDA(
					if((this.weapons & (it.m_wepset)) && (it.spawnflags & WEP_FLAG_RELOADABLE) && (this.(weaponentity).weapon_load[it.m_id] < it.reloading_ammo))
					{
						this.(weaponentity).m_switchweapon = it;
						break;
					}
				));
			}
		}
	}
}

void havocbot_keyboard_movement(entity this, vector destorg)
{
	vector keyboard;

	if (time > this.havocbot_keyboardtime)
	{
		float sk = skill + this.bot_moveskill;
		this.havocbot_keyboardtime =
			max(
				this.havocbot_keyboardtime
					+ 0.05 / max(1, sk + this.havocbot_keyboardskill)
					+ random() * 0.025 / max(0.00025, skill + this.havocbot_keyboardskill)
			, time);
		keyboard = this.movement / autocvar_sv_maxspeed;

		float trigger = autocvar_bot_ai_keyboard_threshold;
		float trigger1 = -trigger;

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
		else if (keyboard.x < trigger1 && sk > 1.5)
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
		else if (keyboard.y < trigger1)
			keyboard.y = -1;
		else
			keyboard.y = 0;

		if (keyboard.z > trigger)
			keyboard.z = 1;
		else if (keyboard.z < trigger1)
			keyboard.z = -1;
		else
			keyboard.z = 0;

		this.havocbot_keyboard = keyboard * autocvar_sv_maxspeed;
		if (this.havocbot_ducktime > time)
			PHYS_INPUT_BUTTON_CROUCH(this) = true;
	}

	keyboard = this.havocbot_keyboard;
	float blend = bound(0, vlen(destorg - this.origin) / autocvar_bot_ai_keyboard_distance, 1); // When getting close move with 360 degree
	//dprint("movement ", vtos(this.movement), " keyboard ", vtos(keyboard), " blend ", ftos(blend), "\n");
	this.movement = this.movement + (keyboard - this.movement) * blend;
}

void havocbot_bunnyhop(entity this, vector dir)
{
	float bunnyhopdistance;
	vector deviation;
	float maxspeed;
	vector gco, gno;

	// Don't jump when attacking
	if(this.aistatus & AI_STATUS_ATTACKING)
		return;

	if(IS_PLAYER(this.goalcurrent))
		return;

	maxspeed = autocvar_sv_maxspeed;

	if(this.aistatus & AI_STATUS_RUNNING && vdist(this.velocity, <, autocvar_sv_maxspeed * 0.75)
		|| this.aistatus & AI_STATUS_DANGER_AHEAD)
	{
		this.aistatus &= ~AI_STATUS_RUNNING;
		PHYS_INPUT_BUTTON_JUMP(this) = false;
		this.bot_canruntogoal = 0;
		this.bot_timelastseengoal = 0;
		return;
	}

	if(this.waterlevel > WATERLEVEL_WETFEET)
	{
		this.aistatus &= ~AI_STATUS_RUNNING;
		return;
	}

	if(this.bot_lastseengoal != this.goalcurrent && !(this.aistatus & AI_STATUS_RUNNING))
	{
		this.bot_canruntogoal = 0;
		this.bot_timelastseengoal = 0;
	}

	gco = (this.goalcurrent.absmin + this.goalcurrent.absmax) * 0.5;
	bunnyhopdistance = vlen(this.origin - gco);

	// Run only to visible goals
	if(IS_ONGROUND(this))
	if(vlen(this.velocity - eZ * this.velocity.z) >= autocvar_sv_maxspeed) // if -really- running
	if(checkpvs(this.origin + this.view_ofs, this.goalcurrent))
	{
			this.bot_lastseengoal = this.goalcurrent;

			// seen it before
			if(this.bot_timelastseengoal)
			{
				// for a period of time
				if(time - this.bot_timelastseengoal > autocvar_bot_ai_bunnyhop_firstjumpdelay)
				{
					float checkdistance;
					checkdistance = true;

					// don't run if it is too close
					if(this.bot_canruntogoal==0)
					{
						if(bunnyhopdistance > autocvar_bot_ai_bunnyhop_startdistance)
							this.bot_canruntogoal = 1;
						else
							this.bot_canruntogoal = -1;
					}

					if(this.bot_canruntogoal != 1)
						return;

					if(this.aistatus & AI_STATUS_ROAMING)
					if(this.goalcurrent.classname=="waypoint")
					if (!(this.goalcurrent.wpflags & WAYPOINTFLAG_PERSONAL))
					if(fabs(gco.z - this.origin.z) < this.maxs.z - this.mins.z)
					if(this.goalstack01 && !wasfreed(this.goalstack01))
					{
						gno = (this.goalstack01.absmin + this.goalstack01.absmax) * 0.5;
						deviation = vectoangles(gno - this.origin) - vectoangles(gco - this.origin);
						while (deviation.y < -180) deviation.y = deviation.y + 360;
						while (deviation.y > 180) deviation.y = deviation.y - 360;

						if(fabs(deviation.y) < 20)
						if(bunnyhopdistance < vlen(this.origin - gno))
						if(fabs(gno.z - gco.z) < this.maxs.z - this.mins.z)
						{
							if(vdist(gco - gno, >, autocvar_bot_ai_bunnyhop_startdistance))
							if(checkpvs(this.origin + this.view_ofs, this.goalstack01))
							{
								checkdistance = false;
							}
						}
					}

					if(checkdistance)
					{
						this.aistatus &= ~AI_STATUS_RUNNING;
						// increase stop distance in case the goal is on a slope or a lower platform 
						if(bunnyhopdistance > autocvar_bot_ai_bunnyhop_stopdistance + (this.origin.z - gco.z))
							PHYS_INPUT_BUTTON_JUMP(this) = true;
					}
					else
					{
						this.aistatus |= AI_STATUS_RUNNING;
						PHYS_INPUT_BUTTON_JUMP(this) = true;
					}
				}
			}
			else
			{
				this.bot_timelastseengoal = time;
			}
	}
	else
	{
		this.bot_timelastseengoal = 0;
	}

#if 0
	// Release jump button
	if(!cvar("sv_pogostick"))
	if((IS_ONGROUND(this)) == 0)
	{
		if(this.velocity.z < 0 || vlen(this.velocity)<maxspeed)
			PHYS_INPUT_BUTTON_JUMP(this) = false;

		// Strafe
		if(this.aistatus & AI_STATUS_RUNNING)
		if(vlen(this.velocity)>maxspeed)
		{
			deviation = vectoangles(dir) - vectoangles(this.velocity);
			while (deviation.y < -180) deviation.y = deviation.y + 360;
			while (deviation.y > 180) deviation.y = deviation.y - 360;

			if(fabs(deviation.y)>10)
				this.movement_x = 0;

			if(deviation.y>10)
				this.movement_y = maxspeed * -1;
			else if(deviation.y<10)
				this.movement_y = maxspeed;

		}
	}
#endif
}

.entity goalcurrent_prev;
.float goalcurrent_distance;
.float goalcurrent_distance_time;
void havocbot_movetogoal(entity this)
{
	vector destorg;
	vector diff;
	vector dir;
	vector flatdir;
	vector m1;
	vector m2;
	vector evadeobstacle;
	vector evadelava;
	float maxspeed;
	vector gco;
	//float dist;
	vector dodge;
	//if (this.goalentity)
	//	te_lightning2(this, this.origin, (this.goalentity.absmin + this.goalentity.absmax) * 0.5);
	this.movement = '0 0 0';
	maxspeed = autocvar_sv_maxspeed;

	// Jetpack navigation
	if(this.goalcurrent)
	if(this.navigation_jetpack_goal)
	if(this.goalcurrent==this.navigation_jetpack_goal)
	if(this.ammo_fuel)
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
			float db, v, d;
			vector dxy;

			dxy = this.origin - ( ( this.goalcurrent.absmin + this.goalcurrent.absmax ) * 0.5 ); dxy.z = 0;
			d = vlen(dxy);
			v = vlen(this.velocity -  this.velocity.z * '0 0 1');
			db = ((v ** 2) / (autocvar_g_jetpack_acceleration_side * 2)) + 100;
		//	dprint("distance ", ftos(ceil(d)), " velocity ", ftos(ceil(v)), " brake at ", ftos(ceil(db)), "\n");
			if(d < db || d < 500)
			{
				// Brake
				if(fabs(this.velocity.x)>maxspeed*0.3)
				{
					this.movement_x = dir * v_forward * -maxspeed;
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
		PHYS_INPUT_BUTTON_HOOK(this) = true;
		if(this.navigation_jetpack_point.z - STAT(PL_MAX, this).z + STAT(PL_MIN, this).z < this.origin.z)
		{
			this.movement_x = dir * v_forward * maxspeed;
			this.movement_y = dir * v_right * maxspeed;
		}
		return;
	}

	// Handling of jump pads
	if(this.jumppadcount)
	{
		// If got stuck on the jump pad try to reach the farthest visible waypoint
		// but with some randomness so it can try out different paths
		if(this.aistatus & AI_STATUS_OUT_JUMPPAD)
		{
			if(fabs(this.velocity.z)<50)
			{
				entity newgoal = NULL;
				if (vdist(this.origin - this.goalcurrent.origin, <, 150))
					this.aistatus &= ~AI_STATUS_OUT_JUMPPAD;
				else IL_EACH(g_waypoints, vdist(it.origin - this.origin, <=, 1000),
				{
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
			else
				return;
		}
		else
		{
			if(time - this.lastteleporttime > 0.3 && this.velocity.z > 0)
			{
				vector velxy = this.velocity; velxy_z = 0;
				if(vdist(velxy, <, autocvar_sv_maxspeed * 0.2))
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
	if(skill>6)
	if (!(IS_ONGROUND(this)))
	{
		tracebox(this.origin, this.mins, this.maxs, this.origin + '0 0 -65536', MOVE_NOMONSTERS, this);
		if(tracebox_hits_trigger_hurt(this.origin, this.mins, this.maxs, trace_endpos ))
		if(this.items & IT_JETPACK)
		{
			tracebox(this.origin, this.mins, this.maxs, this.origin + '0 0 65536', MOVE_NOMONSTERS, this);
			if(tracebox_hits_trigger_hurt(this.origin, this.mins, this.maxs, trace_endpos + '0 0 1' ))
			{
				if(this.velocity.z<0)
				{
					PHYS_INPUT_BUTTON_HOOK(this) = true;
				}
			}
			else
				PHYS_INPUT_BUTTON_HOOK(this) = true;

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
					this.movement_x = dir * v_forward * maxspeed;
					this.movement_y = dir * v_right * maxspeed;
					if (skill < 10)
						havocbot_keyboard_movement(this, this.origin + dir * 100);
				}
			}

			this.havocbot_blockhead = true;

			return;
		}
		else if(this.health > WEP_CVAR(devastator, damage) * 0.5 * ((this.strength_finished < time) ? autocvar_g_balance_powerup_strength_selfdamage : 1))
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
						this.movement_x = maxspeed;

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
						this.rocketjumptime = time + WEP_CVAR(devastator, detonatedelay);
						return;
					}
				}
			}
		}
		else
		{
			// If there is no goal try to move forward
			if(this.goalcurrent==NULL)
				this.movement_x = maxspeed;
		}
	}

	// If we are under water with no goals, swim up
	if(this.waterlevel)
	if(this.goalcurrent==NULL)
	{
		dir = '0 0 0';
		if(this.waterlevel>WATERLEVEL_SWIMMING)
			dir.z = 1;
		else if(this.velocity.z >= 0 && !(this.waterlevel == WATERLEVEL_WETFEET && this.watertype == CONTENT_WATER))
			PHYS_INPUT_BUTTON_JUMP(this) = true;
		else
			PHYS_INPUT_BUTTON_JUMP(this) = false;
		makevectors(this.v_angle.y * '0 1 0');
		this.movement_x = dir * v_forward * maxspeed;
		this.movement_y = dir * v_right * maxspeed;
		this.movement_z = dir * v_up * maxspeed;
	}

	// if there is nowhere to go, exit
	if (this.goalcurrent == NULL)
		return;


	bool locked_goal = false;
	if(this.goalentity && wasfreed(this.goalentity))
	{
		navigation_clearroute(this);
		this.bot_strategytime = 0;
		return;
	}
	else if(this.goalentity.bot_pickup)
	{
		if(this.goalentity.bot_pickup_respawning)
		{
			if(this.goalentity.solid) // item respawned
				this.goalentity.bot_pickup_respawning = false;
			else if(time < this.goalentity.scheduledrespawntime - 10) // item already taken (by someone else)
			{
				this.goalentity.bot_pickup_respawning = false;
				navigation_clearroute(this);
				this.bot_strategytime = 0;
				return;
			}
			else if(this.goalentity == this.goalcurrent)
				locked_goal = true; // wait for item to respawn
		}
		else if(!this.goalentity.solid)
		{
			navigation_clearroute(this);
			this.bot_strategytime = 0;
			return;
		}
	}
	if(!locked_goal)
		navigation_poptouchedgoals(this);

	// if ran out of goals try to use an alternative goal or get a new strategy asap
	if(this.goalcurrent == NULL)
	{
		this.bot_strategytime = 0;
		return;
	}


	if(autocvar_bot_debug_goalstack)
		debuggoalstack(this);

	m1 = this.goalcurrent.origin + this.goalcurrent.mins;
	m2 = this.goalcurrent.origin + this.goalcurrent.maxs;
	destorg = this.origin;
	destorg.x = bound(m1_x, destorg.x, m2_x);
	destorg.y = bound(m1_y, destorg.y, m2_y);
	destorg.z = bound(m1_z, destorg.z, m2_z);
	diff = destorg - this.origin;
	//dist = vlen(diff);
	dir = normalize(diff);
	flatdir = diff;flatdir.z = 0;
	flatdir = normalize(flatdir);
	gco = (this.goalcurrent.absmin + this.goalcurrent.absmax) * 0.5;

	//if (this.bot_dodgevector_time < time)
	{
	//	this.bot_dodgevector_time = time + cvar("bot_ai_dodgeupdateinterval");
	//	this.bot_dodgevector_jumpbutton = 1;
		evadeobstacle = '0 0 0';
		evadelava = '0 0 0';

		this.aistatus &= ~AI_STATUS_DANGER_AHEAD;
		makevectors(this.v_angle.y * '0 1 0');
		if (this.waterlevel)
		{
			if(this.waterlevel>WATERLEVEL_SWIMMING)
			{
			//	flatdir_z = 1;
				this.aistatus |= AI_STATUS_OUT_WATER;
			}
			else
			{
				if(this.velocity.z >= 0 && !(this.watertype == CONTENT_WATER && gco.z < this.origin.z) &&
					( !(this.waterlevel == WATERLEVEL_WETFEET && this.watertype == CONTENT_WATER) || this.aistatus & AI_STATUS_OUT_WATER))
					PHYS_INPUT_BUTTON_JUMP(this) = true;
				else
					PHYS_INPUT_BUTTON_JUMP(this) = false;
			}
			dir = normalize(flatdir);
		}
		else
		{
			float s;
			vector offset;
			if(this.aistatus & AI_STATUS_OUT_WATER)
				this.aistatus &= ~AI_STATUS_OUT_WATER;

			// jump if going toward an obstacle that doesn't look like stairs we
			// can walk up directly
			offset = (vdist(this.velocity, >, 32) ? this.velocity * 0.2 : v_forward * 32);
			tracebox(this.origin, this.mins, this.maxs, this.origin + offset, false, this);
			if (trace_fraction < 1)
			if (trace_plane_normal.z < 0.7)
			{
				s = trace_fraction;
				tracebox(this.origin + stepheightvec, this.mins, this.maxs, this.origin + offset + stepheightvec, false, this);
				if (trace_fraction < s + 0.01)
				if (trace_plane_normal.z < 0.7)
				{
					s = trace_fraction;
					tracebox(this.origin + jumpstepheightvec, this.mins, this.maxs, this.origin + offset + jumpstepheightvec, false, this);
					if (trace_fraction > s)
						PHYS_INPUT_BUTTON_JUMP(this) = true;
				}
			}

			// if bot for some reason doesn't get close to the current goal find another one
			if(!IS_PLAYER(this.goalcurrent) && !(this.goalcurrent.bot_pickup_respawning && this.goalcurrent_distance < 50))
			{
				float curr_dist = vlen(this.origin - this.goalcurrent.origin);
				if(this.goalcurrent != this.goalcurrent_prev)
				{
					this.goalcurrent_prev = this.goalcurrent;
					this.goalcurrent_distance = curr_dist;
					this.goalcurrent_distance_time = 0;
				}
				else if(curr_dist > this.goalcurrent_distance)
				{
					if(!this.goalcurrent_distance_time)
						this.goalcurrent_distance_time = time;
					else if (time - this.goalcurrent_distance_time > 0.5)
					{
						this.goalcurrent_prev = NULL;
						navigation_clearroute(this);
						this.bot_strategytime = 0;
						return;
					}
				}
				else
				{
					// reduce it a little bit so it works even with very small approaches to the goal
					this.goalcurrent_distance = max(20, curr_dist - 15);
					this.goalcurrent_distance_time = 0;
				}
			}

			// Check for water/slime/lava and dangerous edges
			// (only when the bot is on the ground or jumping intentionally)

			vector dst_ahead = this.origin + this.view_ofs + offset;
			vector dst_down = dst_ahead - '0 0 3000';
			traceline(this.origin + this.view_ofs, dst_ahead, true, NULL);

			bool unreachable = false;
			bool ignorehazards = false;
			s = CONTENT_SOLID;
			if(trace_fraction == 1 && this.jumppadcount == 0 && !this.goalcurrent.wphardwired )
			if((IS_ONGROUND(this)) || (this.aistatus & AI_STATUS_RUNNING) || (this.aistatus & AI_STATUS_ROAMING) || PHYS_INPUT_BUTTON_JUMP(this))
			{
				// Look downwards
				traceline(dst_ahead , dst_down, true, NULL);
				//te_lightning2(NULL, this.origin + this.view_ofs, dst_ahead); // Draw "ahead" look
				//te_lightning2(NULL, dst_ahead, dst_down); // Draw "downwards" look
				if(trace_endpos.z < this.origin.z + this.mins.z)
				{
					s = pointcontents(trace_endpos + '0 0 1');
					if (s != CONTENT_SOLID)
					if (s == CONTENT_LAVA || s == CONTENT_SLIME)
					{
						evadelava = normalize(this.velocity) * -1;
						if(this.waterlevel >= WATERLEVEL_WETFEET && (this.watertype == CONTENT_LAVA || this.watertype == CONTENT_SLIME))
							ignorehazards = true;
					}
					else if (s == CONTENT_WATER)
					{
						if(this.waterlevel >= WATERLEVEL_WETFEET && this.watertype == CONTENT_WATER)
							ignorehazards = true;
					}
					else if (s == CONTENT_SKY)
						evadeobstacle = normalize(this.velocity) * -1;
					else if (tracebox_hits_trigger_hurt(dst_ahead, this.mins, this.maxs, trace_endpos))
					{
						// the traceline check isn't enough but is good as optimization,
						// when not true (most of the time) this tracebox call is avoided
						tracebox(dst_ahead, this.mins, this.maxs, dst_down, true, this);
						if (tracebox_hits_trigger_hurt(dst_ahead, this.mins, this.maxs, trace_endpos))
						{
							if (gco.z > this.origin.z + jumpstepheightvec.z)
							{
								// the goal is probably on an upper platform, assume bot can't get there
								unreachable = true;
							}
							else
								evadelava = normalize(this.velocity) * -1;
						}
					}
				}
			}

			dir = flatdir;
			evadeobstacle.z = 0;
			evadelava.z = 0;
			makevectors(this.v_angle.y * '0 1 0');

			if(evadeobstacle || evadelava || (s == CONTENT_WATER))
			{
				if(!ignorehazards)
					this.aistatus |= AI_STATUS_DANGER_AHEAD;
				if(IS_PLAYER(this.goalcurrent))
					unreachable = true;
			}
			if(unreachable)
			{
				navigation_clearroute(this);
				this.bot_strategytime = 0;
			}
		}

		dodge = havocbot_dodge(this);
		dodge = dodge * bound(0,0.5+(skill+this.bot_dodgeskill)*0.1,1);
		evadelava = evadelava * bound(1,3-(skill+this.bot_dodgeskill),3); //Noobs fear lava a lot and take more distance from it
		traceline(this.origin, ( ( this.enemy.absmin + this.enemy.absmax ) * 0.5 ), true, NULL);
		if(IS_PLAYER(trace_ent))
			dir = dir * bound(0,(skill+this.bot_dodgeskill)/7,1);

		dir = normalize(dir + dodge + evadeobstacle + evadelava);
	//	this.bot_dodgevector = dir;
	//	this.bot_dodgevector_jumpbutton = PHYS_INPUT_BUTTON_JUMP(this);
	}

	if(time < this.ladder_time)
	{
		if(this.goalcurrent.origin.z + this.goalcurrent.mins.z > this.origin.z + this.mins.z)
		{
			if(this.origin.z + this.mins.z  < this.ladder_entity.origin.z + this.ladder_entity.maxs.z)
				dir.z = 1;
		}
		else
		{
			if(this.origin.z + this.mins.z  > this.ladder_entity.origin.z + this.ladder_entity.mins.z)
				dir.z = -1;
		}
	}

	//dir = this.bot_dodgevector;
	//if (this.bot_dodgevector_jumpbutton)
	//	PHYS_INPUT_BUTTON_JUMP(this) = true;
	this.movement_x = dir * v_forward * maxspeed;
	this.movement_y = dir * v_right * maxspeed;
	this.movement_z = dir * v_up * maxspeed;

	// Emulate keyboard interface
	if (skill < 10)
		havocbot_keyboard_movement(this, destorg);

	// Bunnyhop!
//	if(this.aistatus & AI_STATUS_ROAMING)
	if(this.goalcurrent)
	if(skill+this.bot_moveskill >= autocvar_bot_ai_bunnyhop_skilloffset)
		havocbot_bunnyhop(this, dir);

	if ((dir * v_up) >= autocvar_sv_jumpvelocity*0.5 && (IS_ONGROUND(this))) PHYS_INPUT_BUTTON_JUMP(this) = true;
	if (((dodge * v_up) > 0) && random()*frametime >= 0.2*bound(0,(10-skill-this.bot_dodgeskill)*0.1,1)) PHYS_INPUT_BUTTON_JUMP(this) = true;
	if (((dodge * v_up) < 0) && random()*frametime >= 0.5*bound(0,(10-skill-this.bot_dodgeskill)*0.1,1)) this.havocbot_ducktime=time+0.3/bound(0.1,skill+this.bot_dodgeskill,10);
}

entity havocbot_gettarget(entity this, bool secondary)
{
	entity best = NULL;
	vector eye = CENTER_OR_VIEWOFS(this);
	IL_EACH(g_bot_targets, boolean((secondary) ? it.classname == "misc_breakablemodel" : it.classname != "misc_breakablemodel"),
	{
		vector v = CENTER_OR_VIEWOFS(it);
		if(vdist(v - eye, <, autocvar_bot_ai_enemydetectionradius))
		if(!best || vlen2(CENTER_OR_VIEWOFS(best) - eye) > vlen2(v - eye))
		if(bot_shouldattack(this, it))
		{
			traceline(eye, v, true, this);
			if (trace_ent == it || trace_fraction >= 1)
				best = it;
		}
	});

	return best;
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
		else if (this.havocbot_stickenemy)
		{
			// tracking last chosen enemy
			// if enemy is visible
			// and not really really far away
			// and we're not severely injured
			// then keep tracking for a half second into the future
			traceline(this.origin+this.view_ofs, ( this.enemy.absmin + this.enemy.absmax ) * 0.5,false,NULL);
			if (trace_ent == this.enemy || trace_fraction == 1)
			if (vdist(((this.enemy.absmin + this.enemy.absmax) * 0.5) - this.origin, <, 1000))
			if (this.health > 30)
			{
				// remain tracking him for a shot while (case he went after a small corner or pilar
				this.havocbot_chooseenemy_finished = time + 0.5;
				return;
			}
			// enemy isn't visible, or is far away, or we're injured severely
			// so stop preferring this enemy
			// (it will still take a half second until a new one is chosen)
			this.havocbot_stickenemy = 0;
		}
	}
	if (time < this.havocbot_chooseenemy_finished)
		return;
	this.havocbot_chooseenemy_finished = time + autocvar_bot_ai_enemydetectioninterval;
	vector eye = this.origin + this.view_ofs;
	entity best = NULL;
	float bestrating = 100000000;

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
			float rating = vlen2(v - eye);
			if (vdist(v - eye, <, autocvar_bot_ai_enemydetectionradius))
			if (bestrating > rating)
			if (bot_shouldattack(this, it))
			{
				traceline(eye, v, true, this);
				if (trace_ent == it || trace_fraction >= 1)
				{
					best = it;
					bestrating = rating;
				}
			}
		});

		if(!best && have_secondary_targets && !scan_secondary_targets)
		{
			scan_secondary_targets = true;
			// restart the loop
			bestrating = 100000000;
			goto scan_targets;
		}

		// I want to do a second scan if no enemy was found or I don't have weapons
		// TODO: Perform the scan when using the rifle (requires changes on the rifle code)
		if(best || this.weapons) // || this.weapon == WEP_RIFLE.m_id
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
	this.havocbot_stickenemy = true;
	if(best && best.classname == "misc_breakablemodel")
		this.havocbot_stickenemy = false;
}

float havocbot_chooseweapon_checkreload(entity this, .entity weaponentity, int new_weapon)
{
	// bots under this skill cannot find unloaded weapons to reload idly when not in combat,
	// so skip this for them, or they'll never get to reload their weapons at all.
	// this also allows bots under this skill to be more stupid, and reload more often during combat :)
	if(skill < 5)
		return false;

	// if this weapon is scheduled for reloading, don't switch to it during combat
	if (this.(weaponentity).weapon_load[new_weapon] < 0)
	{
		FOREACH(Weapons, it != WEP_Null, LAMBDA(
			if(it.wr_checkammo1(it, this, weaponentity) + it.wr_checkammo2(it, this, weaponentity))
				return true; // other weapon available
		));
	}

	return false;
}

void havocbot_chooseweapon(entity this, .entity weaponentity)
{
	int i;

	// ;)
	if(g_weaponarena_weapons == WEPSET(TUBA))
	{
		this.(weaponentity).m_switchweapon = WEP_TUBA;
		return;
	}

	// TODO: clean this up by moving it to weapon code
	if(this.enemy==NULL)
	{
		// If no weapon was chosen get the first available weapon
		if(this.(weaponentity).m_weapon==WEP_Null)
		FOREACH(Weapons, it != WEP_Null, LAMBDA(
			if(client_hasweapon(this, it, weaponentity, true, false))
			{
				this.(weaponentity).m_switchweapon = it;
				return;
			}
		));
		return;
	}

	// Do not change weapon during the next second after a combo
	float f = time - this.lastcombotime;
	if(f < 1)
		return;

	float w;
	float distance; distance=bound(10,vlen(this.origin-this.enemy.origin)-200,10000);

	// Should it do a weapon combo?
	float af, ct, combo_time, combo;

	af = ATTACK_FINISHED(this, 0);
	ct = autocvar_bot_ai_weapon_combo_threshold;

	// Bots with no skill will be 4 times more slower than "godlike" bots when doing weapon combos
	// Ideally this 4 should be calculated as longest_weapon_refire / bot_ai_weapon_combo_threshold
	combo_time = time + ct + (ct * ((-0.3*(skill+this.bot_weaponskill))+3));

	combo = false;

	if(autocvar_bot_ai_weapon_combo)
	if(this.(weaponentity).m_weapon.m_id == this.(weaponentity).lastfiredweapon)
	if(af > combo_time)
	{
		combo = true;
		this.lastcombotime = time;
	}

	distance *= (2 ** this.bot_rangepreference);

	// Custom weapon list based on distance to the enemy
	if(bot_custom_weapon){

		// Choose weapons for far distance
		if ( distance > bot_distance_far ) {
			for(i=0; i < Weapons_COUNT && bot_weapons_far[i] != -1 ; ++i){
				w = bot_weapons_far[i];
				if ( client_hasweapon(this, Weapons_from(w), weaponentity, true, false) )
				{
					if ((this.(weaponentity).m_weapon.m_id == w && combo) || havocbot_chooseweapon_checkreload(this, weaponentity, w))
						continue;
					this.(weaponentity).m_switchweapon = Weapons_from(w);
					return;
				}
			}
		}

		// Choose weapons for mid distance
		if ( distance > bot_distance_close) {
			for(i=0; i < Weapons_COUNT && bot_weapons_mid[i] != -1 ; ++i){
				w = bot_weapons_mid[i];
				if ( client_hasweapon(this, Weapons_from(w), weaponentity, true, false) )
				{
					if ((this.(weaponentity).m_weapon.m_id == w && combo) || havocbot_chooseweapon_checkreload(this, weaponentity, w))
						continue;
					this.(weaponentity).m_switchweapon = Weapons_from(w);
					return;
				}
			}
		}

		// Choose weapons for close distance
		for(i=0; i < Weapons_COUNT && bot_weapons_close[i] != -1 ; ++i){
			w = bot_weapons_close[i];
			if ( client_hasweapon(this, Weapons_from(w), weaponentity, true, false) )
			{
				if ((this.(weaponentity).m_weapon.m_id == w && combo) || havocbot_chooseweapon_checkreload(this, weaponentity, w))
					continue;
				this.(weaponentity).m_switchweapon = Weapons_from(w);
				return;
			}
		}
	}
}

void havocbot_aim(entity this)
{
	if (time < this.nextaim)
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
		lag_additem(this, time + this.ping, 0, 0, this.enemy, this.origin, myvel, (this.enemy.absmin + this.enemy.absmax) * 0.5, enemyvel);
	}
	else
		lag_additem(this, time + this.ping, 0, 0, NULL, this.origin, myvel, ( this.goalcurrent.absmin + this.goalcurrent.absmax ) * 0.5, '0 0 0');
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

		// Heading
		vector dir = ( ( this.goalcurrent.absmin + this.goalcurrent.absmax ) * 0.5 ) - (this.origin + this.view_ofs);
		dir.z = 0;
		bot_aimdir(this, dir, -1);

		// Go!
		havocbot_movetogoal(this);

		if(this.aistatus & AI_STATUS_WAYPOINT_PERSONAL_REACHED)
		{
			// Step 5: Waypoint reached
			LOG_TRACE(this.netname, "'s personal waypoint reached");
			delete(this.havocbot_personal_waypoint);
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

	havocbot_chooserole(this);
}

vector havocbot_dodge(entity this)
{
	// LordHavoc: disabled because this is too expensive
	return '0 0 0';
#if 0
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
					// calculate direction and distance from the flight path, by removing the forward axis
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
#endif
}
