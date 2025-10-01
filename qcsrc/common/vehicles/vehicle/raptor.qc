#include "raptor.qh"

#if defined(SVQC)
	#include <common/gametypes/gametype/ctf/sv_ctf.qh>
#elif defined(MENUQC)
	#include "spiderbot.qh"
#endif

#ifdef GAMEQC

#ifdef SVQC

bool autocvar_g_vehicle_raptor = true;

float autocvar_g_vehicle_raptor_respawntime = 40;
float autocvar_g_vehicle_raptor_takeofftime = 1.5;

// 0: go where player aims, +forward etc relative to aim angles
// 1: ignore aim for up/down movement. +forward always moved forward, +jump always moves up
int autocvar_g_vehicle_raptor_movestyle = 1;
float autocvar_g_vehicle_raptor_turnspeed = 200;
float autocvar_g_vehicle_raptor_pitchspeed = 50;
float autocvar_g_vehicle_raptor_pitchlimit = 45;

float autocvar_g_vehicle_raptor_speed_forward = 1700;
float autocvar_g_vehicle_raptor_speed_strafe = 2200;
float autocvar_g_vehicle_raptor_speed_up = 2300;
float autocvar_g_vehicle_raptor_speed_down = 2000;
float autocvar_g_vehicle_raptor_friction = 2;

bool autocvar_g_vehicle_raptor_swim = false;

float autocvar_g_vehicle_raptor_cannon_turnspeed = 120;
float autocvar_g_vehicle_raptor_cannon_turnlimit = 20;
float autocvar_g_vehicle_raptor_cannon_pitchlimit_up = 12;
float autocvar_g_vehicle_raptor_cannon_pitchlimit_down = 32;

bool autocvar_g_vehicle_raptor_cannon_locktarget = true;
float autocvar_g_vehicle_raptor_cannon_locking_time = 0.2;
float autocvar_g_vehicle_raptor_cannon_locking_releasetime = 0.45;
float autocvar_g_vehicle_raptor_cannon_locked_time = 1;
float autocvar_g_vehicle_raptor_cannon_predicttarget = 1;

float autocvar_g_vehicle_raptor_energy = 100;
float autocvar_g_vehicle_raptor_energy_regen = 25;
float autocvar_g_vehicle_raptor_energy_regen_pause = 0.25;

float autocvar_g_vehicle_raptor_health = 250;
float autocvar_g_vehicle_raptor_health_regen = 0;
float autocvar_g_vehicle_raptor_health_regen_pause = 0;

float autocvar_g_vehicle_raptor_shield = 200;
float autocvar_g_vehicle_raptor_shield_regen = 25;
float autocvar_g_vehicle_raptor_shield_regen_pause = 1.5;

float autocvar_g_vehicle_raptor_bouncefactor = 0.2;
float autocvar_g_vehicle_raptor_bouncestop = 0;
vector autocvar_g_vehicle_raptor_bouncepain = '1 4 1000';

.entity bomb1;
.entity bomb2;

void raptor_land(entity this)
{
	float hgt;

	hgt = vehicle_altitude(this, 512);
	this.velocity = (this.velocity * 0.9) + ('0 0 -1800' * (hgt / 256) * PHYS_INPUT_FRAMETIME);
	this.angles_x *= 0.95;
	this.angles_z *= 0.95;

	if(hgt < 128 && hgt > 0)
		this.frame = (hgt / 128) * 25;

	this.bomb1.gun1.avelocity_y = 90 + ((this.frame / 25) * 2000);
	this.bomb1.gun2.avelocity_y = -this.bomb1.gun1.avelocity_y;

	if(hgt < 16)
	{
		set_movetype(this, MOVETYPE_TOSS);
		setthink(this, vehicles_think);
		this.frame	= 0;
	}

	this.nextthink  = time;

	CSQCMODEL_AUTOUPDATE(this);
}

void raptor_exit(entity this, int eject)
{
	entity player = this.owner;

	this.tur_head.exteriormodeltoclient = NULL;

	if(!IS_DEAD(this))
	{
		setthink(this, raptor_land);
		this.nextthink = time;
	}

	if(!player)
		return;

	makevectors(this.angles);
	vector spot;
	if(eject)
	{
		spot = this.origin + v_forward * 100 + '0 0 64';
		spot = vehicles_findgoodexit(this, player, spot);
		setorigin(player, spot);
		player.velocity = (v_up + v_forward * 0.25) * 750;
		player.oldvelocity = player.velocity;
	}
	else
	{
		if(vdist(this.velocity, >, 2 * autocvar_sv_maxairspeed))
		{
			player.velocity = normalize(this.velocity) * autocvar_sv_maxairspeed * 2;
			player.velocity_z += 200;
			spot = this.origin + v_forward * 32 + '0 0 64';
			spot = vehicles_findgoodexit(this, player, spot);
		}
		else
		{
			player.velocity = this.velocity * 0.5;
			player.velocity_z += 10;
			spot = this.origin - v_forward * 200 + '0 0 64';
			spot = vehicles_findgoodexit(this, player, spot);
		}
		player.oldvelocity = player.velocity;
		setorigin(player, spot);
	}

	this.owner = NULL;
	antilag_clear(player, CS(player));
}

bool raptor_frame(entity this, float dt)
{
	entity vehic = this.vehicle;
	return = true;

	if(game_stopped)
	{
		vehic.solid = SOLID_NOT;
		vehic.takedamage = DAMAGE_NO;
		set_movetype(vehic, MOVETYPE_NONE);
		return;
	}

	vehicles_frame(vehic, this);

	/*
	ftmp = vlen(vehic.velocity);
	if(ftmp > autocvar_g_vehicle_raptor_speed_forward)
		ftmp = 1;
	else
		ftmp = ftmp / autocvar_g_vehicle_raptor_speed_forward;
	*/

	if(vehic.sound_nexttime < time)
	{
		vehic.sound_nexttime = time + 7.955812;
		//sound (vehic.tur_head, CH_TRIGGER_SINGLE, SND_VEH_RAPTOR_FLY, 1 - ftmp,   ATTEN_NORM );
		sound (vehic, CH_TRIGGER_SINGLE, SND_VEH_RAPTOR_SPEED, 1, ATTEN_NORM);
		vehic.wait = 0;
	}
	/*
	else if(fabs(ftmp - vehic.wait) > 0.2)
	{
		sound (vehic.tur_head, CH_TRIGGER_SINGLE, SND_Null, 1 - ftmp,   ATTEN_NORM );
		sound (vehic, CH_TRIGGER_SINGLE, SND_Null, ftmp, ATTEN_NORM);
		vehic.wait = ftmp;
	}
	*/

	if(IS_DEAD(vehic))
	{
		PHYS_INPUT_BUTTON_ATCK(this) = PHYS_INPUT_BUTTON_ATCK2(this) = false;
		return;
	}
	crosshair_trace(this);

	//if(time - vehic.lastteleporttime < 1)
	//{
		if(vehic.angles_z > 50 || vehic.angles_z < -50)
		{
			if(PHYS_INPUT_BUTTON_JUMP(this))
			{
				PHYS_INPUT_BUTTON_CROUCH(this) = true;
				PHYS_INPUT_BUTTON_JUMP(this) = false;
			}
		}
	//}

	vector vang;
	vang = vehic.angles;
	vector df = vectoangles(normalize(trace_endpos - vehic.origin + '0 0 32'));
	vang_x *= -1;
	df_x *= -1;
	if(df_x > 180)  df_x -= 360;
	if(df_x < -180) df_x += 360;
	if(df_y > 180)  df_y -= 360;
	if(df_y < -180) df_y += 360;

	float ftmp = shortangle_f(this.v_angle_y - vang_y, vang_y);
	if(ftmp > 180)  ftmp -= 360; if(ftmp < -180) ftmp += 360;
	vehic.avelocity_y = bound(-autocvar_g_vehicle_raptor_turnspeed, ftmp + vehic.avelocity_y * 0.9, autocvar_g_vehicle_raptor_turnspeed);

	// Pitch
	ftmp = 0;
	if(CS(this).movement_x > 0 && vang_x < autocvar_g_vehicle_raptor_pitchlimit) ftmp = 5;
	else if(CS(this).movement_x < 0 && vang_x > -autocvar_g_vehicle_raptor_pitchlimit) ftmp = -20;

	df_x = bound(-autocvar_g_vehicle_raptor_pitchlimit, df_x , autocvar_g_vehicle_raptor_pitchlimit);
	ftmp = vang_x - bound(-autocvar_g_vehicle_raptor_pitchlimit, df_x + ftmp, autocvar_g_vehicle_raptor_pitchlimit);
	vehic.avelocity_x = bound(-autocvar_g_vehicle_raptor_pitchspeed, ftmp + vehic.avelocity_x * 0.9, autocvar_g_vehicle_raptor_pitchspeed);

	vehic.angles_x = anglemods(vehic.angles_x);
	vehic.angles_y = anglemods(vehic.angles_y);
	vehic.angles_z = anglemods(vehic.angles_z);

	if(autocvar_g_vehicle_raptor_movestyle == 1)
		makevectors('0 1 0' * vehic.angles_y);
	else
		makevectors(this.v_angle);

	df = vehic.velocity * -autocvar_g_vehicle_raptor_friction;

	if(CS(this).movement_x != 0)
	{
		if(CS(this).movement_x > 0)
			df += v_forward  * autocvar_g_vehicle_raptor_speed_forward;
		else if(CS(this).movement_x < 0)
			df -= v_forward  * autocvar_g_vehicle_raptor_speed_forward;
	}

	if(CS(this).movement_y != 0)
	{
		if(CS(this).movement_y < 0)
			df -= v_right * autocvar_g_vehicle_raptor_speed_strafe;
		else if(CS(this).movement_y > 0)
			df += v_right * autocvar_g_vehicle_raptor_speed_strafe;

		vehic.angles_z = bound(-30,vehic.angles_z + (CS(this).movement_y / autocvar_g_vehicle_raptor_speed_strafe),30);
	}
	else
	{
		vehic.angles_z *= 0.95;
		if(vehic.angles_z >= -1 && vehic.angles_z <= -1)
			vehic.angles_z = 0;
	}

	if(PHYS_INPUT_BUTTON_CROUCH(this))
		df -=   v_up * autocvar_g_vehicle_raptor_speed_down;
	else if (PHYS_INPUT_BUTTON_JUMP(this))
		df +=  v_up * autocvar_g_vehicle_raptor_speed_up;

	vehic.velocity  += df * dt;
	this.velocity = CS(this).movement  = vehic.velocity;
	setorigin(this, vehic.origin + '0 0 32');
	this.oldorigin = this.origin; // negate fall damage

	STAT(VEHICLESTAT_W2MODE, this) = STAT(VEHICLESTAT_W2MODE, vehic);

	vector vf, ad;
	// Target lock & predict
	if(autocvar_g_vehicle_raptor_cannon_locktarget == 2)
	{
		if(vehic.gun1.lock_time < time || IS_DEAD(vehic.gun1.enemy) || STAT(FROZEN, vehic.gun1.enemy))
			vehic.gun1.enemy = NULL;

		if(trace_ent)
		if(trace_ent.move_movetype)
		if(trace_ent.takedamage)
		if(!IS_DEAD(trace_ent) && !STAT(FROZEN, trace_ent))
		{
			if(teamplay)
			{
				if(trace_ent.team != this.team)
				{
					vehic.gun1.enemy = trace_ent;
					vehic.gun1.lock_time = time + 5;
				}
			}
			else
			{
				vehic.gun1.enemy = trace_ent;
				vehic.gun1.lock_time = time + 0.5;
			}
		}

		if(vehic.gun1.enemy)
		{
			float distance, impact_time;

			vf = real_origin(vehic.gun1.enemy);
			UpdateAuxiliaryXhair(this, vf, '1 0 0', 1);
			vector _vel = vehic.gun1.enemy.velocity;
			if(vehic.gun1.enemy.move_movetype == MOVETYPE_WALK)
				_vel_z *= 0.1;

			if(autocvar_g_vehicle_raptor_cannon_predicttarget)
			{
				ad = vf;
				distance = vlen(ad - this.origin);
				impact_time = distance / autocvar_g_vehicle_raptor_cannon_speed;
				ad = vf + _vel * impact_time;
				trace_endpos = ad;
			}
			else
				trace_endpos = vf;
		}
	}
	else if(autocvar_g_vehicle_raptor_cannon_locktarget == 1)
	{

		vehicles_locktarget(vehic, (1 / autocvar_g_vehicle_raptor_cannon_locking_time) * dt,
							 (1 / autocvar_g_vehicle_raptor_cannon_locking_releasetime) * dt,
							 autocvar_g_vehicle_raptor_cannon_locked_time);

		if(vehic.lock_target != NULL)
		if(autocvar_g_vehicle_raptor_cannon_predicttarget)
		if(vehic.lock_strength == 1)
		{
			float i, distance, impact_time;

			vf = real_origin(vehic.lock_target);
			ad = vf;
			for(i = 0; i < 4; ++i)
			{
				distance = vlen(ad - vehic.origin);
				impact_time = distance / autocvar_g_vehicle_raptor_cannon_speed;
				ad = vf + vehic.lock_target.velocity * impact_time;
			}
			trace_endpos = ad;
		}

		if(vehic.lock_target)
		{
			if(vehic.lock_strength == 1)
				UpdateAuxiliaryXhair(this, real_origin(vehic.lock_target), '1 0 0', 1);
			else if(vehic.lock_strength > 0.5)
				UpdateAuxiliaryXhair(this, real_origin(vehic.lock_target), '0 1 0', 1);
			else if(vehic.lock_strength < 0.5)
				UpdateAuxiliaryXhair(this, real_origin(vehic.lock_target), '0 0 1', 1);
		}
	}


	vehicle_aimturret(vehic, trace_endpos, vehic.gun1, "fire1",
						  autocvar_g_vehicle_raptor_cannon_pitchlimit_down * -1,  autocvar_g_vehicle_raptor_cannon_pitchlimit_up,
						  autocvar_g_vehicle_raptor_cannon_turnlimit * -1,  autocvar_g_vehicle_raptor_cannon_turnlimit,  autocvar_g_vehicle_raptor_cannon_turnspeed, dt);

	vehicle_aimturret(vehic, trace_endpos, vehic.gun2, "fire1",
						  autocvar_g_vehicle_raptor_cannon_pitchlimit_down * -1,  autocvar_g_vehicle_raptor_cannon_pitchlimit_up,
						  autocvar_g_vehicle_raptor_cannon_turnlimit * -1,  autocvar_g_vehicle_raptor_cannon_turnlimit,  autocvar_g_vehicle_raptor_cannon_turnspeed, dt);

	/*
	ad = ad * 0.5;
	v_forward = vf * 0.5;
	traceline(ad, ad + v_forward * max_shot_distance, MOVE_NORMAL, vehic);
	UpdateAuxiliaryXhair(this, trace_endpos, '0 1 0', 0);
	*/

	Weapon wep1 = WEP_RAPTOR;
	.entity weaponentity = weaponentities[0];
	if(!weaponLocked(this) && !weaponUseForbidden(this))
	if(PHYS_INPUT_BUTTON_ATCK(this))
	if (wep1.wr_checkammo1(wep1, vehic, weaponentity))
	{
		wep1.wr_think(wep1, vehic, weaponentity, 1);
	}

	if(vehic.vehicle_flags  & VHF_SHIELDREGEN)
		vehicles_regen(vehic, vehic.dmg_time, vehicle_shield, autocvar_g_vehicle_raptor_shield, autocvar_g_vehicle_raptor_shield_regen_pause, autocvar_g_vehicle_raptor_shield_regen, dt, true);

	if(vehic.vehicle_flags  & VHF_HEALTHREGEN)
		vehicles_regen_resource(vehic, vehic.dmg_time, vehicle_health, autocvar_g_vehicle_raptor_health, autocvar_g_vehicle_raptor_health_regen_pause, autocvar_g_vehicle_raptor_health_regen, dt, false, RES_HEALTH);

	if(vehic.vehicle_flags  & VHF_ENERGYREGEN)
		vehicles_regen(vehic, vehic.cnt, vehicle_energy, autocvar_g_vehicle_raptor_energy, autocvar_g_vehicle_raptor_energy_regen_pause, autocvar_g_vehicle_raptor_energy_regen, dt, false);

	Weapon wep2a = WEP_RAPTOR_BOMB;
	if(!weaponLocked(this) && !weaponUseForbidden(this))
	if(STAT(VEHICLESTAT_W2MODE, vehic) == RSM_BOMB)
	{
		if(time > vehic.lip + autocvar_g_vehicle_raptor_bombs_refire)
		if(PHYS_INPUT_BUTTON_ATCK2(this))
		{
		    .entity weaponentity = weaponentities[1];
			wep2a.wr_think(wep2a, vehic, weaponentity, 2);
			vehic.delay = time + autocvar_g_vehicle_raptor_bombs_refire;
			vehic.lip   = time;
		}
	}
	else
	{
		Weapon wep2b = WEP_RAPTOR_FLARE;
		if(time > vehic.lip + autocvar_g_vehicle_raptor_flare_refire)
		if(PHYS_INPUT_BUTTON_ATCK2(this))
		{
		    .entity weaponentity = weaponentities[1];
			wep2b.wr_think(wep2b, vehic, weaponentity, 2);
			vehic.delay = time + autocvar_g_vehicle_raptor_flare_refire;
			vehic.lip   = time;
		}
	}

	vehic.bomb1.alpha = vehic.bomb2.alpha = (time - vehic.lip) / (vehic.delay - vehic.lip);
	this.vehicle_reload2 = bound(0, vehic.bomb1.alpha * 100, 100);
	this.vehicle_ammo2 = (this.vehicle_reload2 == 100) ? 100 : 0;

	if(vehic.bomb1.cnt < time)
	{
		bool incoming = false;
		IL_EACH(g_projectiles, it.enemy == vehic,
		{
			if(it.missile_flags & MIF_GUIDED_TRACKING)
			if(vdist(vehic.origin - it.origin, <, 2 * autocvar_g_vehicle_raptor_flare_range))
			{
				incoming = true;
				break;
			}
		});

		if(incoming)
		{
			msg_entity = this;
			soundto(MSG_ONE, vehic, CH_PAIN_SINGLE, SND(VEH_MISSILE_ALARM), VOL_BASE, ATTEN_NONE, 0);
		}

		vehic.bomb1.cnt = time + 1;
	}


	VEHICLE_UPDATE_PLAYER_RESOURCE(this, vehic, health, raptor, RES_HEALTH);
	VEHICLE_UPDATE_PLAYER(this, vehic, energy, raptor);
	if(vehic.vehicle_flags & VHF_HASSHIELD)
		VEHICLE_UPDATE_PLAYER(this, vehic, shield, raptor);

	PHYS_INPUT_BUTTON_ATCK(this) = PHYS_INPUT_BUTTON_ATCK2(this) = PHYS_INPUT_BUTTON_CROUCH(this) = false;
}

bool raptor_takeoff(entity this, float dt)
{
	entity vehic = this.vehicle;
	return = true;

	vehic.nextthink = time;
	CSQCMODEL_AUTOUPDATE(vehic);
	vehic.nextthink = 0; // will this work?

	if(vehic.sound_nexttime < time)
	{
		vehic.sound_nexttime = time + 7.955812; //soundlength("vehicles/raptor_fly.wav");
		sound (vehic, CH_TRIGGER_SINGLE, SND_VEH_RAPTOR_SPEED, VOL_VEHICLEENGINE, ATTEN_NORM);
	}

	// Takeoff sequense
	if(vehic.frame < 25)
	{
		vehic.frame += 25 / (autocvar_g_vehicle_raptor_takeofftime / dt);
		vehic.velocity_z = min(vehic.velocity_z * 1.5, 256);
		vehic.bomb1.gun1.avelocity_y = 90 + ((vehic.frame / 25) * 25000);
		vehic.bomb1.gun2.avelocity_y = -vehic.bomb1.gun1.avelocity_y;
		PHYS_INPUT_BUTTON_ATCK(this) = PHYS_INPUT_BUTTON_ATCK2(this) = PHYS_INPUT_BUTTON_CROUCH(this) = false;

		setorigin(this, vehic.origin + '0 0 32');
		this.oldorigin = this.origin;
	}
	else
		this.PlayerPhysplug = raptor_frame;

	STAT(VEHICLESTAT_W2MODE, this) = STAT(VEHICLESTAT_W2MODE, vehic);

	if(vehic.vehicle_flags  & VHF_SHIELDREGEN)
		vehicles_regen(vehic, vehic.dmg_time, vehicle_shield, autocvar_g_vehicle_raptor_shield, autocvar_g_vehicle_raptor_shield_regen_pause, autocvar_g_vehicle_raptor_shield_regen, dt, true);

	if(vehic.vehicle_flags  & VHF_HEALTHREGEN)
		vehicles_regen_resource(vehic, vehic.dmg_time, vehicle_health, autocvar_g_vehicle_raptor_health, autocvar_g_vehicle_raptor_health_regen_pause, autocvar_g_vehicle_raptor_health_regen, dt, false, RES_HEALTH);

	if(vehic.vehicle_flags  & VHF_ENERGYREGEN)
		vehicles_regen(vehic, vehic.cnt, vehicle_energy, autocvar_g_vehicle_raptor_energy, autocvar_g_vehicle_raptor_energy_regen_pause, autocvar_g_vehicle_raptor_energy_regen, dt, false);


	vehic.bomb1.alpha = vehic.bomb2.alpha = (time - vehic.lip) / (vehic.delay - vehic.lip);
	this.vehicle_reload2 = bound(0, vehic.bomb1.alpha * 100, 100);
	this.vehicle_ammo2 = (this.vehicle_reload2 == 100) ? 100 : 0;

	VEHICLE_UPDATE_PLAYER_RESOURCE(this, vehic, health, raptor, RES_HEALTH);
	VEHICLE_UPDATE_PLAYER(this, vehic, energy, raptor);
	if(vehic.vehicle_flags & VHF_HASSHIELD)
		VEHICLE_UPDATE_PLAYER(this, vehic, shield, raptor);

	PHYS_INPUT_BUTTON_ATCK(this) = PHYS_INPUT_BUTTON_ATCK2(this) = PHYS_INPUT_BUTTON_CROUCH(this) = false;
}

void raptor_blowup(entity this, entity toucher)
{
	this.deadflag	= DEAD_DEAD;
	this.vehicle_exit(this, VHEF_NORMAL);
	RadiusDamage (this, this.enemy, 250, 15, 250, NULL, NULL, 250, DEATH_VH_RAPT_DEATH.m_id, DMG_NOWEP, NULL);

	this.alpha		  = -1;
	set_movetype(this, MOVETYPE_NONE);
	this.effects		= EF_NODRAW;
	this.colormod	   = '0 0 0';
	this.avelocity	  = '0 0 0';
	this.velocity	   = '0 0 0';

	setorigin(this, this.pos1);
	settouch(this, func_null);
	this.nextthink = 0;
}

void raptor_diethink(entity this)
{
	if(time >= this.wait)
	{
		raptor_blowup(this, NULL);
		return;
	}

	if(random() < 0.05)
	{
		sound (this, CH_SHOTS, SND_ROCKET_IMPACT, VOL_BASE, ATTEN_NORM);
		Send_Effect(EFFECT_EXPLOSION_SMALL, randomvec() * 80 + (this.origin + '0 0 100'), '0 0 0', 1);
	}
	this.nextthink = time;

	CSQCMODEL_AUTOUPDATE(this);
}

// If we dont do this ever now and then, the raptors rotors
// stop working, presumably due to angle overflow. cute.
void raptor_rotor_anglefix(entity this)
{
	this.gun1.angles_y = anglemods(this.gun1.angles_y);
	this.gun2.angles_y = anglemods(this.gun2.angles_y);
	this.nextthink = time + 15;
}

bool raptor_impulse(entity this, int _imp)
{
	switch(_imp)
	{
		case IMP_weapon_group_1.impulse:
			STAT(VEHICLESTAT_W2MODE, this.vehicle) = RSM_BOMB;
			CSQCVehicleSetup(this, 0);
			return true;
		case IMP_weapon_group_2.impulse:
			STAT(VEHICLESTAT_W2MODE, this.vehicle) = RSM_FLARE;
			CSQCVehicleSetup(this, 0);
			return true;

		case IMP_weapon_next_byid.impulse:
		case IMP_weapon_next_bypriority.impulse:
		case IMP_weapon_next_bygroup.impulse:
			STAT(VEHICLESTAT_W2MODE, this.vehicle) += 1;
			if(STAT(VEHICLESTAT_W2MODE, this.vehicle) > RSM_LAST)
				STAT(VEHICLESTAT_W2MODE, this.vehicle) = RSM_FIRST;

			CSQCVehicleSetup(this, 0);
			return true;
		case IMP_weapon_last.impulse:
		case IMP_weapon_prev_byid.impulse:
		case IMP_weapon_prev_bypriority.impulse:
		case IMP_weapon_prev_bygroup.impulse:
			STAT(VEHICLESTAT_W2MODE, this.vehicle) -= 1;
			if(STAT(VEHICLESTAT_W2MODE, this.vehicle) < RSM_FIRST)
				STAT(VEHICLESTAT_W2MODE, this.vehicle) = RSM_LAST;

			CSQCVehicleSetup(this, 0);
			return true;

		/*
		case IMP_weapon_drop.impulse: // toss gun, could be used to exit?
			break;
		case IMP_weapon_reload.impulse: // Manual minigun reload?
			break;
		*/
	}
	return false;
}

spawnfunc(vehicle_raptor)
{
	if(!autocvar_g_vehicle_raptor) { delete(this); return; }
	if(!vehicle_initialize(this, VEH_RAPTOR, false)) { delete(this); return; }
}

METHOD(Raptor, vr_impact, void(Raptor thisveh, entity instance))
{
    if(autocvar_g_vehicle_raptor_bouncepain)
        vehicles_impact(instance, autocvar_g_vehicle_raptor_bouncepain_x, autocvar_g_vehicle_raptor_bouncepain_y, autocvar_g_vehicle_raptor_bouncepain_z);
}
METHOD(Raptor, vr_enter, void(Raptor thisveh, entity instance))
{
    STAT(VEHICLESTAT_W2MODE, instance) = RSM_BOMB;
    instance.owner.PlayerPhysplug = raptor_takeoff;
    set_movetype(instance, MOVETYPE_BOUNCEMISSILE);
    instance.solid		  = SOLID_SLIDEBOX;
    instance.owner.vehicle_health = (GetResource(instance, RES_HEALTH) / autocvar_g_vehicle_raptor_health) * 100;
    instance.owner.vehicle_shield = (instance.vehicle_shield / autocvar_g_vehicle_raptor_shield) * 100;
    instance.velocity = '0 0 1'; // nudge upwards so takeoff sequence can work
    instance.tur_head.exteriormodeltoclient = instance.owner;

    instance.delay = time + autocvar_g_vehicle_raptor_bombs_refire;
    instance.lip   = time;

    if(instance.owner.flagcarried)
       setorigin(instance.owner.flagcarried, '-20 0 96');

    CSQCVehicleSetup(instance.owner, 0);
}
METHOD(Raptor, vr_death, void(Raptor thisveh, entity instance))
{
	SetResourceExplicit(instance, RES_HEALTH, 0);
    instance.event_damage		= func_null;
    instance.solid				= SOLID_CORPSE;
    instance.takedamage			= DAMAGE_NO;
    instance.deadflag			= DEAD_DYING;
    set_movetype(instance, MOVETYPE_BOUNCE);
    setthink(instance, raptor_diethink);
    instance.nextthink			= time;
    instance.wait				= time + 5 + (random() * 5);

    Send_Effect(EFFECT_EXPLOSION_MEDIUM, findbetterlocation (instance.origin, 16), '0 0 0', 1);

    instance.velocity_z += 600;

    instance.avelocity = '0 0.5 1' * (random() * 400);
    instance.avelocity -= '0 0.5 1' * (random() * 400);

    instance.colormod = '-0.5 -0.5 -0.5';
    settouch(instance, raptor_blowup);
}
METHOD(Raptor, vr_spawn, void(Raptor thisveh, entity instance))
{
    if(!instance.gun1)
    {
        entity spinner;
        vector ofs;

        //FIXME: Camera is in a bad place in HUD model.
        //setorigin(instance.vehicle_viewport, '25 0 5');

        instance.vehicles_impulse = raptor_impulse;

        instance.frame = 0;

        instance.bomb1 = new(raptor_bomb);
        instance.bomb2 = new(raptor_bomb);
        instance.gun1  = new(raptor_gun);
        instance.gun2  = new(raptor_gun);

        setmodel(instance.bomb1, MDL_VEH_RAPTOR_CB_FOLDED);
        setmodel(instance.bomb2, MDL_VEH_RAPTOR_CB_FOLDED);
        setmodel(instance.gun1, MDL_VEH_RAPTOR_GUN);
        setmodel(instance.gun2, MDL_VEH_RAPTOR_GUN);
        setmodel(instance.tur_head, MDL_VEH_RAPTOR_TAIL);

        setattachment(instance.bomb1, instance, "bombmount_left");
        setattachment(instance.bomb2, instance, "bombmount_right");
        setattachment(instance.tur_head, instance,"root");

        // FIXMODEL Guns mounts to angled bones
        instance.bomb1.angles = instance.angles;
        instance.angles = '0 0 0';
        // This messes up gun-aim, so work arround it.
        //setattachment(instance.gun1, instance, "gunmount_left");
        ofs = gettaginfo(instance, gettagindex(instance, "gunmount_left"));
        ofs -= instance.origin;
        setattachment(instance.gun1, instance, "");
        setorigin(instance.gun1, ofs);

        //setattachment(instance.gun2, instance, "gunmount_right");
        ofs = gettaginfo(instance, gettagindex(instance, "gunmount_right"));
        ofs -= instance.origin;
        setattachment(instance.gun2, instance, "");
        setorigin(instance.gun2, ofs);

        instance.angles = instance.bomb1.angles;
        instance.bomb1.angles = '0 0 0';

        spinner = new(raptor_spinner);
        spinner.owner = instance;
        setmodel(spinner, MDL_VEH_RAPTOR_PROP);
        setattachment(spinner, instance, "engine_left");
        set_movetype(spinner, MOVETYPE_NOCLIP);
        spinner.avelocity = '0 90 0';
        instance.bomb1.gun1 = spinner;

        spinner = new(raptor_spinner);
        spinner.owner = instance;
        setmodel(spinner, MDL_VEH_RAPTOR_PROP);
        setattachment(spinner, instance, "engine_right");
        set_movetype(spinner, MOVETYPE_NOCLIP);
        spinner.avelocity = '0 -90 0';
        instance.bomb1.gun2 = spinner;

        // Sigh.
        setthink(instance.bomb1, raptor_rotor_anglefix);
        instance.bomb1.nextthink = time;

        instance.mass			   = 1 ;
    }

    instance.frame		  = 0;
    SetResourceExplicit(instance, RES_HEALTH, autocvar_g_vehicle_raptor_health);
    instance.vehicle_shield = autocvar_g_vehicle_raptor_shield;
    set_movetype(instance, MOVETYPE_TOSS);
    instance.solid		  = SOLID_SLIDEBOX;
    instance.vehicle_energy = 1;

    if(!autocvar_g_vehicle_raptor_swim)
    	instance.dphitcontentsmask |= DPCONTENTS_LIQUIDSMASK;

    instance.PlayerPhysplug = raptor_frame;

    instance.bomb1.gun1.avelocity_y = 90;
    instance.bomb1.gun2.avelocity_y = -90;

    instance.delay = time;

    instance.bouncefactor = autocvar_g_vehicle_raptor_bouncefactor;
    instance.bouncestop = autocvar_g_vehicle_raptor_bouncestop;
    instance.damageforcescale = 0.25;
    SetResourceExplicit(instance, RES_HEALTH, autocvar_g_vehicle_raptor_health);
    instance.vehicle_shield = autocvar_g_vehicle_raptor_shield;
}
METHOD(Raptor, vr_setup, void(Raptor thisveh, entity instance))
{
    if(autocvar_g_vehicle_raptor_shield)
        instance.vehicle_flags |= VHF_HASSHIELD;

    if(autocvar_g_vehicle_raptor_shield_regen)
        instance.vehicle_flags |= VHF_SHIELDREGEN;

    if(autocvar_g_vehicle_raptor_health_regen)
        instance.vehicle_flags |= VHF_HEALTHREGEN;

    if(autocvar_g_vehicle_raptor_energy_regen)
        instance.vehicle_flags |= VHF_ENERGYREGEN;

    instance.vehicle_exit = raptor_exit;
    instance.respawntime = autocvar_g_vehicle_raptor_respawntime;
    SetResourceExplicit(instance, RES_HEALTH, autocvar_g_vehicle_raptor_health);
    instance.vehicle_shield = autocvar_g_vehicle_raptor_shield;
    instance.max_health = GetResource(instance, RES_HEALTH);

    if(!autocvar_g_vehicle_raptor_swim)
    	instance.dphitcontentsmask |= DPCONTENTS_LIQUIDSMASK;
}

#endif
#ifdef CSQC

METHOD(Raptor, vr_hud, void(Raptor thisveh))
{
    Vehicles_drawHUD(VEH_RAPTOR.m_icon, "vehicle_raptor_weapon1", "vehicle_raptor_weapon2",
                     "vehicle_icon_ammo1", autocvar_hud_progressbar_vehicles_ammo1_color,
                     "vehicle_icon_ammo2", autocvar_hud_progressbar_vehicles_ammo2_color);
}
METHOD(Raptor, vr_crosshair, void(Raptor thisveh, entity player))
{
    string crosshair;

    switch(weapon2mode)
    {
        case RSM_FLARE: crosshair = vCROSS_RAIN;  break;
        case RSM_BOMB:  crosshair = vCROSS_BURST; break;
        default:        crosshair = vCROSS_BURST;
    }

    vector tmpSize = '0 0 0';
    if(weapon2mode != RSM_FLARE && !spectatee_status)
    {
        vector where;

        if(!dropmark)
        {
            dropmark = new(raptor_dropmark);
            dropmark.owner = player;
            dropmark.gravity = 1;
            dropmark.dphitcontentsmask = DPCONTENTS_SOLID;
            dropmark.solid = SOLID_CORPSE;
			set_movetype(dropmark, MOVETYPE_BOUNCE);
        }

        float reload2 = STAT(VEHICLESTAT_RELOAD2) * 0.01;
        if(reload2 == 1)
        {
            setorigin(dropmark, pmove_org);
            dropmark.velocity = pmove_vel;
            tracetoss(dropmark, player);

            where = project_3d_to_2d(trace_endpos);

            setorigin(dropmark, trace_endpos);

            if (!(where.z < 0 || where.x < 0 || where.y < 0 || where.x > vid_conwidth || where.y > vid_conheight))
            {
                tmpSize = draw_getimagesize(vCROSS_DROP) * autocvar_cl_vehicles_crosshair_size;
                where.x -= tmpSize.x * 0.5;
                where.y -= tmpSize.y * 0.5;
                where.z = 0;
                drawpic(where, vCROSS_DROP, tmpSize, '0 1 0', autocvar_crosshair_alpha * 0.9, DRAWFLAG_ADDITIVE);
                drawpic(where, vCROSS_DROP, tmpSize, '0 1 0', autocvar_crosshair_alpha * 0.6, DRAWFLAG_NORMAL); // Ensure visibility against bright bg
            }
            dropmark.cnt = time + 5;
        }
        else
        {
            if(dropmark.cnt > time)
            {
                where = project_3d_to_2d(dropmark.origin);

                if (!(where.z < 0 || where.x < 0 || where.y < 0 || where.x > vid_conwidth || where.y > vid_conheight))
                {
                    tmpSize = draw_getimagesize(vCROSS_DROP) * autocvar_cl_vehicles_crosshair_size * 1.25;
                    where.x -= tmpSize.x * 0.5;
                    where.y -= tmpSize.y * 0.5;
                    where.z = 0;
                    drawpic(where, vCROSS_DROP, tmpSize, '1 0 0', autocvar_crosshair_alpha * 0.9, DRAWFLAG_ADDITIVE);
                    drawpic(where, vCROSS_DROP, tmpSize, '1 0 0', autocvar_crosshair_alpha * 0.6, DRAWFLAG_NORMAL); // Ensure visibility against bright bg
                }
            }
        }
    }

    Vehicles_drawCrosshair(crosshair);
}
METHOD(Raptor, vr_setup, void(Raptor thisveh, entity instance))
{
    AuxiliaryXhair[1].axh_image = vCROSS_LOCK;
}

#endif

#endif
#ifdef MENUQC

METHOD(Raptor, describe, string(Raptor this))
{
	TC(Raptor, this);
	PAGE_TEXT_INIT();
	PAR(_("The %s vehicle is a flying vehicle that takes only one pilot, who can operate both of the weapons."), COLORED_NAME(this));
	PAR(_("The two weapons have different reticles for them similar to the %s. "
	      "The primary weapon is laser-based, shooting toward the white reticle. "
	      "The secondary weapon drops bombs to the ground, aiming towards the green reticle. "
	      "The white reticle always points to the head of the vehicle, while the green reticle's location is determined by the momentum of the vehicle."), COLORED_NAME(VEH_SPIDERBOT));
	return PAGE_TEXT;
}

#endif
