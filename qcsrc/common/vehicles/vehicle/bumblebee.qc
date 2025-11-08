#include "bumblebee.qh"

#ifdef SVQC
	#include <common/mutators/mutator/instagib/sv_instagib.qh>
#endif

#ifdef GAMEQC

const float BRG_SETUP = 2;
const float BRG_START = 4;
const float BRG_END = 8;

#ifdef SVQC
float autocvar_g_vehicle_bumblebee_respawntime = 60;

float autocvar_g_vehicle_bumblebee_speed_forward = 350;
float autocvar_g_vehicle_bumblebee_speed_strafe = 350;
float autocvar_g_vehicle_bumblebee_speed_up = 350;
float autocvar_g_vehicle_bumblebee_speed_down = 350;
float autocvar_g_vehicle_bumblebee_turnspeed = 120;
float autocvar_g_vehicle_bumblebee_pitchspeed = 60;
float autocvar_g_vehicle_bumblebee_pitchlimit = 60;
float autocvar_g_vehicle_bumblebee_friction = 0.5;
bool autocvar_g_vehicle_bumblebee_swim = true;

float autocvar_g_vehicle_bumblebee_energy = 500;
float autocvar_g_vehicle_bumblebee_energy_regen = 50;
float autocvar_g_vehicle_bumblebee_energy_regen_pause = 1;

float autocvar_g_vehicle_bumblebee_health = 1000;
float autocvar_g_vehicle_bumblebee_health_regen = 65;
float autocvar_g_vehicle_bumblebee_health_regen_pause = 10;

float autocvar_g_vehicle_bumblebee_shield = 400;
float autocvar_g_vehicle_bumblebee_shield_regen = 150;
float autocvar_g_vehicle_bumblebee_shield_regen_pause = 0.75;

float autocvar_g_vehicle_bumblebee_cannon_ammo = 100;
float autocvar_g_vehicle_bumblebee_cannon_ammo_regen = 100;
float autocvar_g_vehicle_bumblebee_cannon_ammo_regen_pause = 1;

float autocvar_g_vehicle_bumblebee_cannon_lock = 1;

float autocvar_g_vehicle_bumblebee_cannon_turnspeed = 260;
float autocvar_g_vehicle_bumblebee_cannon_pitchlimit_down = 60;
float autocvar_g_vehicle_bumblebee_cannon_pitchlimit_up = 60;
float autocvar_g_vehicle_bumblebee_cannon_turnlimit_in = 20;
float autocvar_g_vehicle_bumblebee_cannon_turnlimit_out = 80;


float autocvar_g_vehicle_bumblebee_raygun_turnspeed = 180;
float autocvar_g_vehicle_bumblebee_raygun_pitchlimit_down = 20;
float autocvar_g_vehicle_bumblebee_raygun_pitchlimit_up = 5;
float autocvar_g_vehicle_bumblebee_raygun_turnlimit_sides = 35;

bool autocvar_g_vehicle_bumblebee_raygun = false;
float autocvar_g_vehicle_bumblebee_raygun_range = 2048;
float autocvar_g_vehicle_bumblebee_raygun_dps = 250;
float autocvar_g_vehicle_bumblebee_raygun_aps = 100;
float autocvar_g_vehicle_bumblebee_raygun_fps = 100;

float autocvar_g_vehicle_bumblebee_healgun_hps = 150;
float autocvar_g_vehicle_bumblebee_healgun_hmax = 100;
float autocvar_g_vehicle_bumblebee_healgun_aps = 75;
float autocvar_g_vehicle_bumblebee_healgun_amax = 100;
float autocvar_g_vehicle_bumblebee_healgun_sps = 100;
float autocvar_g_vehicle_bumblebee_healgun_locktime = 2.5;

float autocvar_g_vehicle_bumblebee_blowup_radius = 500;
float autocvar_g_vehicle_bumblebee_blowup_coredamage = 500;
float autocvar_g_vehicle_bumblebee_blowup_edgedamage = 100;
float autocvar_g_vehicle_bumblebee_blowup_forceintensity = 600;
vector autocvar_g_vehicle_bumblebee_bouncepain = '1 100 200';

bool autocvar_g_vehicle_bumblebee = true;

bool bumblebee_gunner_frame(entity this, float dt)
{
	entity vehic = this.vehicle.owner;
	entity gun = this.vehicle;
	return = true;

	// this isn't technically a vehicle (yet), let's not do frame functions on it (yet)
	//vehicles_frame(gun, player);

	vehic.solid = SOLID_NOT;
	//setorigin(this, vehic.origin);
	this.velocity = vehic.velocity;

	float _in, _out;
	vehic.angles_x *= -1;
	makevectors(vehic.angles);
	vehic.angles_x *= -1;
	if(gun == vehic.gun1)
	{
		_in = autocvar_g_vehicle_bumblebee_cannon_turnlimit_in;
		_out = autocvar_g_vehicle_bumblebee_cannon_turnlimit_out;
		setorigin(this, vehic.origin + v_up * -16 + v_forward * -16 + v_right * 128);
	}
	else
	{
		_in = autocvar_g_vehicle_bumblebee_cannon_turnlimit_out;
		_out = autocvar_g_vehicle_bumblebee_cannon_turnlimit_in;
		setorigin(this, vehic.origin + v_up * -16 + v_forward * -16 + v_right * -128);
	}
	this.oldorigin = this.origin; // negate fall damage

	crosshair_trace(this);
	vector _ct = trace_endpos;
	vector ad;

	if(autocvar_g_vehicle_bumblebee_cannon_lock)
	{
		if(gun.lock_time < time || IS_DEAD(gun.enemy) || STAT(FROZEN, gun.enemy))
			gun.enemy = NULL;

		if(trace_ent)
		if(trace_ent.move_movetype)
		if(trace_ent.takedamage)
		if(!IS_DEAD(trace_ent) && !STAT(FROZEN, trace_ent))
		{
			if(teamplay)
			{
				if(DIFF_TEAM(trace_ent, this))
				{
					gun.enemy = trace_ent;
					gun.lock_time = time + 2.5;
				}
			}
			else
			{
				gun.enemy = trace_ent;
				gun.lock_time = time + 0.5;
			}
		}
	}

	if(gun.enemy)
	{
		float distance, impact_time;

		vector vf = real_origin(gun.enemy);
		vector _vel = gun.enemy.velocity;
		if(gun.enemy.move_movetype == MOVETYPE_WALK)
			_vel.z *= 0.1;


		ad = vf;
		distance = vlen(ad - this.origin);
		impact_time = distance / autocvar_g_vehicle_bumblebee_cannon_speed;
		ad = vf + _vel * impact_time;
		trace_endpos = ad;


		UpdateAuxiliaryXhair(this, ad, '1 0 1', 1);
		vehicle_aimturret(vehic, trace_endpos, gun, "fire",
						  autocvar_g_vehicle_bumblebee_cannon_pitchlimit_down * -1, autocvar_g_vehicle_bumblebee_cannon_pitchlimit_up,
						  _out * -1,  _in,  autocvar_g_vehicle_bumblebee_cannon_turnspeed, dt);

	}
	else
		vehicle_aimturret(vehic, _ct, gun, "fire",
						  autocvar_g_vehicle_bumblebee_cannon_pitchlimit_down * -1, autocvar_g_vehicle_bumblebee_cannon_pitchlimit_up,
						  _out * -1,  _in,  autocvar_g_vehicle_bumblebee_cannon_turnspeed, dt);

	if(!weaponLocked(this) && !weaponUseForbidden(this))
	if(PHYS_INPUT_BUTTON_ATCK(this))
		if(time > gun.attack_finished_single[0])
			if(gun.vehicle_energy >= autocvar_g_vehicle_bumblebee_cannon_cost)
			{
				gun.vehicle_energy -= autocvar_g_vehicle_bumblebee_cannon_cost;
				bumblebee_fire_cannon(vehic, gun, "fire", this);
				gun.delay = time;
				gun.attack_finished_single[0] = time + autocvar_g_vehicle_bumblebee_cannon_refire;
			}

	VEHICLE_UPDATE_PLAYER_RESOURCE(this, vehic, health, bumblebee, RES_HEALTH);

	if(vehic.vehicle_flags & VHF_HASSHIELD)
		VEHICLE_UPDATE_PLAYER(this, vehic, shield, bumblebee);

	ad = gettaginfo(gun, gettagindex(gun, "fire"));
	traceline(ad, ad + v_forward * max_shot_distance, MOVE_NORMAL, gun);

	UpdateAuxiliaryXhair(this, trace_endpos, ('1 0 0' * this.vehicle_reload1) + ('0 1 0' *(1 - this.vehicle_reload1)), 0);

	if(vehic.owner)
		UpdateAuxiliaryXhair(vehic.owner, trace_endpos, ('1 0 0' * this.vehicle_reload1) + ('0 1 0' *(1 - this.vehicle_reload1)), ((this == vehic.gunner1) ? 1 : 2));

	vehic.solid = SOLID_BBOX;
	PHYS_INPUT_BUTTON_ATCK(this) = PHYS_INPUT_BUTTON_ATCK2(this) = PHYS_INPUT_BUTTON_CROUCH(this) = false;
	this.vehicle_energy = (gun.vehicle_energy / autocvar_g_vehicle_bumblebee_cannon_ammo) * 100;
}

vector bumblebee_gunner_findgoodexit(vector prefer_spot, entity gunner, entity player)
{
	//vector exitspot;
	float mysize;

	tracebox(gunner.origin + '0 0 32', STAT(PL_MIN, player), STAT(PL_MAX, player), prefer_spot, MOVE_NORMAL, player);
	if(trace_fraction == 1.0 && !trace_startsolid && !trace_allsolid)
		return prefer_spot;

	mysize = 1.5 * vlen(STAT(PL_MAX, player) - STAT(PL_MIN, player)); // can't use gunner's size, as they don't have a size
	float i;
	vector v, v2;
	v2 = 0.5 * (gunner.absmin + gunner.absmax);
	for(i = 0; i < 100; ++i)
	{
		v = randomvec();
		v_z = 0;
		v = v2 + normalize(v) * mysize;
		tracebox(v2, STAT(PL_MIN, player), STAT(PL_MAX, player), v, MOVE_NORMAL, player);
		if(trace_fraction == 1.0 && !trace_startsolid && !trace_allsolid)
			return v;
	}

	return prefer_spot; // this should be considered a fallback?!
}

void bumblebee_gunner_exit(entity this, int _exitflag)
{
	entity player = ((this.owner.gun1 == this) ? this.owner.gunner1 : this.owner.gunner2);
	entity gunner = this;
	entity vehic = gunner.owner;

	if(IS_REAL_CLIENT(player))
	{
		msg_entity = player;
		WriteByte(MSG_ONE, SVC_SETVIEWPORT);
		WriteEntity(MSG_ONE, player);

		// NOTE: engine networked
		WriteByte(MSG_ONE, SVC_SETVIEWANGLES);
		WriteAngle(MSG_ONE, 0);
		WriteAngle(MSG_ONE, vehic.angles.y);
		WriteAngle(MSG_ONE, 0);
	}

	CSQCVehicleSetup(player, HUD_NORMAL);

	player.takedamage     = DAMAGE_AIM;
	player.solid          = SOLID_SLIDEBOX;
	set_movetype(player, MOVETYPE_WALK);
	player.effects       &= ~EF_NODRAW;
	player.alpha          = 1;
	player.PlayerPhysplug = func_null;
	player.view_ofs       = STAT(PL_VIEW_OFS, player);
	player.event_damage   = PlayerDamage;
	STAT(HUD, player)     = HUD_NORMAL;
	player.teleportable	  = TELEPORT_NORMAL;
	for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	{
		.entity weaponentity = weaponentities[slot];
		player.(weaponentity).m_switchweapon = gunner.(weaponentity).m_switchweapon;
		delete(gunner.(weaponentity));
	}
	player.vehicle_enter_delay = time + 2;
	setsize(player, STAT(PL_MIN, player), STAT(PL_MAX, player));

	fixedmakevectors(vehic.angles);

	if(player == vehic.gunner1) { vehic.gunner1 = NULL; }
	if(player == vehic.gunner2) { vehic.gunner2 = NULL; v_right *= -1; }

	vector spot = real_origin(gunner);
	spot = spot + v_up * 128 + v_forward * 300 + v_right * 150;
	spot = bumblebee_gunner_findgoodexit(spot, gunner, player);

	// TODO: figure a way to move player out of the gunner

	player.velocity = 0.75 * vehic.velocity + normalize(spot - vehic.origin) * 200;
	player.velocity_z += 10;

	gunner.phase = time + 5;
	gunner.vehicle_hudmodel.viewmodelforclient = gunner;

	MUTATOR_CALLHOOK(VehicleExit, player, gunner);

	player.vehicle = NULL;
}

bool bumblebee_gunner_enter(entity this, entity player)
{
	entity vehic = this;
	entity gunner = NULL;

	if(!vehic.gunner1 && !vehic.gunner2 && ((time >= vehic.gun1.phase) + (time >= vehic.gun2.phase)) == 2)
	{
		// we can have some fun
		vector v1 = gettaginfo(vehic, gettagindex(vehic, "cannon_right"));
		vector v2 = gettaginfo(vehic, gettagindex(vehic, "cannon_left"));
		if(vlen2(player.origin - v1) < vlen2(player.origin - v2))
		{
			gunner = vehic.gun1;
			vehic.gunner1 = player;
		}
		else
		{
			gunner = vehic.gun2;
			vehic.gunner2 = player;
		}
	}
	else if(!vehic.gunner1 && time >= vehic.gun1.phase) 	{ gunner = vehic.gun1; vehic.gunner1 = player; }
	else if(!vehic.gunner2 && time >= vehic.gun2.phase)		{ gunner = vehic.gun2; vehic.gunner2 = player; }
	else { LOG_TRACE("Vehicle is full, fail"); return false; }

	player.vehicle 			= gunner;
	player.angles 			= vehic.angles;
	player.takedamage 		= DAMAGE_NO;
	player.solid 			= SOLID_NOT;
	player.alpha 			= -1;
	set_movetype(player, MOVETYPE_NOCLIP);
	player.event_damage 	= func_null;
	player.view_ofs 		= '0 0 0';
	STAT(HUD, player) 		= STAT(HUD, gunner);
	player.teleportable 	= false;
	player.PlayerPhysplug 	= gunner.PlayerPhysplug;
	player.vehicle_ammo1 	= vehic.vehicle_ammo1;
	player.vehicle_ammo2 	= vehic.vehicle_ammo2;
	player.vehicle_reload1 	= vehic.vehicle_reload1;
	player.vehicle_reload2 	= vehic.vehicle_reload2;
	player.vehicle_energy 	= vehic.vehicle_energy;
	UNSET_ONGROUND(player);

	RemoveGrapplingHooks(player);

	for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	{
		.entity weaponentity = weaponentities[slot];

		gunner.(weaponentity) = new(temp_wepent);
		gunner.(weaponentity).m_switchweapon = player.(weaponentity).m_switchweapon;
	}
	gunner.vehicle_exit = bumblebee_gunner_exit;
	gunner.vehicle_hudmodel.viewmodelforclient = player;

	if(IS_REAL_CLIENT(player))
	{
		msg_entity = player;
		WriteByte(MSG_ONE, 		SVC_SETVIEWPORT);
		WriteEntity(MSG_ONE, 	gunner.vehicle_viewport);

		// NOTE: engine networked
		WriteByte(MSG_ONE, 		SVC_SETVIEWANGLES);
		WriteAngle(MSG_ONE, 	gunner.angles_x + vehic.angles_x); // tilt
		WriteAngle(MSG_ONE, 	gunner.angles_y + vehic.angles_y); // yaw
		WriteAngle(MSG_ONE, 	0); // roll
	}

	CSQCVehicleSetup(player, STAT(HUD, player));

	MUTATOR_CALLHOOK(VehicleEnter, player, gunner);

	return true;
}

bool vehicles_valid_pilot(entity this, entity toucher)
{
	if(IS_BOT_CLIENT(toucher) && !autocvar_g_vehicles_allow_bots)
		return false;

	if((!IS_PLAYER(toucher))
	|| (IS_DEAD(toucher))
	|| (toucher.vehicle)
	|| (DIFF_TEAM(toucher, this))
	) { return false; }

	return true;
}

void bumblebee_touch(entity this, entity toucher)
{
	if(autocvar_g_vehicles_enter) { return; }

	if(this.gunner1 != NULL && this.gunner2 != NULL)
	{
		vehicles_touch(this, toucher);
		return;
	}

	if(vehicles_valid_pilot(this, toucher))
	{
		float phase_time = (time >= this.gun1.phase) + (time >= this.gun2.phase);

		if(time >= toucher.vehicle_enter_delay && phase_time)
		if(bumblebee_gunner_enter(this, toucher))
			return;
	}

	vehicles_touch(this, toucher);
}

void bumblebee_regen(entity this, float dt)
{
	if(this.gun1.delay + autocvar_g_vehicle_bumblebee_cannon_ammo_regen_pause < time)
		this.gun1.vehicle_energy = min(autocvar_g_vehicle_bumblebee_cannon_ammo,
									   this.gun1.vehicle_energy + autocvar_g_vehicle_bumblebee_cannon_ammo_regen * dt);

	if(this.gun2.delay + autocvar_g_vehicle_bumblebee_cannon_ammo_regen_pause < time)
		this.gun2.vehicle_energy = min(autocvar_g_vehicle_bumblebee_cannon_ammo,
									   this.gun2.vehicle_energy + autocvar_g_vehicle_bumblebee_cannon_ammo_regen * dt);

	if(this.vehicle_flags  & VHF_SHIELDREGEN)
		vehicles_regen(this, this.dmg_time, vehicle_shield, autocvar_g_vehicle_bumblebee_shield, autocvar_g_vehicle_bumblebee_shield_regen_pause, autocvar_g_vehicle_bumblebee_shield_regen, dt, true);

	if(this.vehicle_flags  & VHF_HEALTHREGEN)
		vehicles_regen_resource(this, this.dmg_time, vehicle_health, autocvar_g_vehicle_bumblebee_health, autocvar_g_vehicle_bumblebee_health_regen_pause, autocvar_g_vehicle_bumblebee_health_regen, dt, false, RES_HEALTH);

	if(this.vehicle_flags  & VHF_ENERGYREGEN)
		vehicles_regen(this, this.wait, vehicle_energy, autocvar_g_vehicle_bumblebee_energy, autocvar_g_vehicle_bumblebee_energy_regen_pause, autocvar_g_vehicle_bumblebee_energy_regen, dt, false);

}

bool bumblebee_pilot_frame(entity this, float dt)
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

	if(IS_DEAD(vehic))
	{
		PHYS_INPUT_BUTTON_ATCK(this) = PHYS_INPUT_BUTTON_ATCK2(this) = false;
		return;
	}

	bumblebee_regen(vehic, dt);

	crosshair_trace(this);

	vector vang = vehic.angles;
	vector newvel = vectoangles(normalize(trace_endpos - vehic.origin + '0 0 32'));
	vang.x *= -1;
	newvel.x *= -1;
	if(newvel.x > 180)  newvel.x -= 360;
	if(newvel.x < -180) newvel.x += 360;
	if(newvel.y > 180)  newvel.y -= 360;
	if(newvel.y < -180) newvel.y += 360;

	float ftmp = shortangle_f(this.v_angle.y - vang.y, vang.y);
	if(ftmp > 180)  ftmp -= 360;
	if(ftmp < -180) ftmp += 360;
	vehic.avelocity_y = bound(-autocvar_g_vehicle_bumblebee_turnspeed, ftmp + vehic.avelocity.y * 0.9, autocvar_g_vehicle_bumblebee_turnspeed);

	// Pitch
	ftmp = 0;
	if(CS(this).movement.x > 0 && vang.x < autocvar_g_vehicle_bumblebee_pitchlimit)
		ftmp = 4;
	else if(CS(this).movement.x < 0 && vang.x > -autocvar_g_vehicle_bumblebee_pitchlimit)
		ftmp = -8;

	newvel.x = bound(-autocvar_g_vehicle_bumblebee_pitchlimit, newvel.x , autocvar_g_vehicle_bumblebee_pitchlimit);
	ftmp = vang.x - bound(-autocvar_g_vehicle_bumblebee_pitchlimit, newvel.x + ftmp, autocvar_g_vehicle_bumblebee_pitchlimit);
	vehic.avelocity_x = bound(-autocvar_g_vehicle_bumblebee_pitchspeed, ftmp + vehic.avelocity.x * 0.9, autocvar_g_vehicle_bumblebee_pitchspeed);

	vehic.angles_x = anglemods(vehic.angles.x);
	vehic.angles_y = anglemods(vehic.angles.y);
	vehic.angles_z = anglemods(vehic.angles.z);

	makevectors('0 1 0' * vehic.angles.y);
	newvel = vehic.velocity * -autocvar_g_vehicle_bumblebee_friction;

	if(CS(this).movement.x != 0)
	{
		if(CS(this).movement.x > 0)
			newvel += v_forward  * autocvar_g_vehicle_bumblebee_speed_forward;
		else if(CS(this).movement.x < 0)
			newvel -= v_forward  * autocvar_g_vehicle_bumblebee_speed_forward;
	}

	if(CS(this).movement.y != 0)
	{
		if(CS(this).movement.y < 0)
			newvel -= v_right * autocvar_g_vehicle_bumblebee_speed_strafe;
		else if(CS(this).movement.y > 0)
			newvel += v_right * autocvar_g_vehicle_bumblebee_speed_strafe;
		ftmp = newvel * v_right;
		ftmp *= dt * 0.1;
		vehic.angles_z = bound(-15, vehic.angles.z + ftmp, 15);
	}
	else
	{
		vehic.angles_z *= 0.95;
		if(vehic.angles.z >= -1 && vehic.angles.z <= -1)
			vehic.angles_z = 0;
	}

	if(PHYS_INPUT_BUTTON_CROUCH(this))
		newvel -=   v_up * autocvar_g_vehicle_bumblebee_speed_down;
	else if(PHYS_INPUT_BUTTON_JUMP(this))
		newvel +=  v_up * autocvar_g_vehicle_bumblebee_speed_up;

	vehic.velocity  += newvel * dt;
	this.velocity = CS(this).movement  = vehic.velocity;


	if(autocvar_g_vehicle_bumblebee_healgun_locktime)
	{
		if(vehic.tur_head.lock_time < time || IS_DEAD(vehic.tur_head.enemy) || STAT(FROZEN, vehic.tur_head.enemy))
			vehic.tur_head.enemy = NULL;

		if(trace_ent)
		if(trace_ent.move_movetype)
		if(trace_ent.takedamage)
		if(!IS_DEAD(trace_ent) && !STAT(FROZEN, trace_ent))
		{
			if(teamplay)
			{
				if(trace_ent.team == this.team)
				{
					vehic.tur_head.enemy = trace_ent;
					vehic.tur_head.lock_time = time + autocvar_g_vehicle_bumblebee_healgun_locktime;
				}
			}
			else
			{
				vehic.tur_head.enemy = trace_ent;
				vehic.tur_head.lock_time = time + autocvar_g_vehicle_bumblebee_healgun_locktime;
			}
		}

		if(vehic.tur_head.enemy)
		{
			trace_endpos = real_origin(vehic.tur_head.enemy);
			UpdateAuxiliaryXhair(this, trace_endpos, '0 0.75 0', 0);
		}
	}

	vang = vehicle_aimturret(vehic, trace_endpos, vehic.gun3, "fire",
					  autocvar_g_vehicle_bumblebee_raygun_pitchlimit_down * -1,  autocvar_g_vehicle_bumblebee_raygun_pitchlimit_up,
					  autocvar_g_vehicle_bumblebee_raygun_turnlimit_sides * -1,  autocvar_g_vehicle_bumblebee_raygun_turnlimit_sides,  autocvar_g_vehicle_bumblebee_raygun_turnspeed, dt);

	if(!weaponLocked(this) && !weaponUseForbidden(this))
	if((PHYS_INPUT_BUTTON_ATCK(this) || PHYS_INPUT_BUTTON_ATCK2(this)) && (vehic.vehicle_energy > autocvar_g_vehicle_bumblebee_raygun_dps * PHYS_INPUT_FRAMETIME || autocvar_g_vehicle_bumblebee_raygun == 0))
	{
		vehic.gun3.enemy.realowner = this;
		vehic.gun3.enemy.effects &= ~EF_NODRAW;

		vehic.gun3.enemy.hook_start = gettaginfo(vehic.gun3, gettagindex(vehic.gun3, "fire"));
		vehic.gun3.enemy.SendFlags |= BRG_START;

		traceline(vehic.gun3.enemy.hook_start, vehic.gun3.enemy.hook_start + v_forward * autocvar_g_vehicle_bumblebee_raygun_range, MOVE_NORMAL, vehic);

		if(trace_ent)
		{
			if(autocvar_g_vehicle_bumblebee_raygun)
			{
				Damage(trace_ent, vehic, this, autocvar_g_vehicle_bumblebee_raygun_dps * PHYS_INPUT_FRAMETIME, DEATH_GENERIC.m_id, DMG_NOWEP, trace_endpos, v_forward * autocvar_g_vehicle_bumblebee_raygun_fps * PHYS_INPUT_FRAMETIME);
				vehic.vehicle_energy -= autocvar_g_vehicle_bumblebee_raygun_aps * PHYS_INPUT_FRAMETIME;
			}
			else
			{
				if(!IS_DEAD(trace_ent))
				{
					if((teamplay && trace_ent.team == this.team) || !teamplay)
					{
						if(autocvar_g_vehicle_bumblebee_healgun_hps)
						{
							float hplimit = ((IS_PLAYER(trace_ent)) ? autocvar_g_vehicle_bumblebee_healgun_hmax : RES_LIMIT_NONE);
							Heal(trace_ent, this, autocvar_g_vehicle_bumblebee_healgun_hps * dt, hplimit);
						}

						if(IS_VEHICLE(trace_ent))
						{
							if(autocvar_g_vehicle_bumblebee_healgun_sps && GetResource(trace_ent, RES_HEALTH) <= trace_ent.max_health)
								trace_ent.vehicle_shield = min(trace_ent.vehicle_shield + autocvar_g_vehicle_bumblebee_healgun_sps * dt, trace_ent.tur_head.max_health);
						}
						else if(IS_CLIENT(trace_ent))
						{
							float maxarmor = ((MUTATOR_IS_ENABLED(mutator_instagib)) ? autocvar_g_instagib_extralives : autocvar_g_vehicle_bumblebee_healgun_amax);
							if(GetResource(trace_ent, RES_ARMOR) <= maxarmor && autocvar_g_vehicle_bumblebee_healgun_aps)
								GiveResourceWithLimit(trace_ent, RES_ARMOR, autocvar_g_vehicle_bumblebee_healgun_aps * dt, maxarmor);
						}
					}
				}
			}
		}

		vehic.gun3.enemy.hook_end = trace_endpos;
		setorigin(vehic.gun3.enemy, trace_endpos);
		vehic.gun3.enemy.SendFlags |= BRG_END;

		vehic.wait = time + 1;
	}
	else
		vehic.gun3.enemy.effects |= EF_NODRAW;
	/*{
		if(vehic.gun3.enemy)
			remove(vehic.gun3.enemy);

		vehic.gun3.enemy = NULL;
	}
	*/

	VEHICLE_UPDATE_PLAYER_RESOURCE(this, vehic, health, bumblebee, RES_HEALTH);
	VEHICLE_UPDATE_PLAYER(this, vehic, energy, bumblebee);

	this.vehicle_ammo1 = (vehic.gun1.vehicle_energy / autocvar_g_vehicle_bumblebee_cannon_ammo) * 100;
	this.vehicle_ammo2 = (vehic.gun2.vehicle_energy / autocvar_g_vehicle_bumblebee_cannon_ammo) * 100;

	if(vehic.vehicle_flags & VHF_HASSHIELD)
		VEHICLE_UPDATE_PLAYER(this, vehic, shield, bumblebee);

	vehic.angles_x *= -1;
	makevectors(vehic.angles);
	vehic.angles_x *= -1;
	setorigin(this, vehic.origin + v_up * 48 + v_forward * 160);
	this.oldorigin = this.origin; // negate fall damage

	PHYS_INPUT_BUTTON_ATCK(this) = PHYS_INPUT_BUTTON_ATCK2(this) = PHYS_INPUT_BUTTON_CROUCH(this) = false;
}

void bumblebee_land(entity this)
{
	float hgt;

	hgt = vehicle_altitude(this, 512);
	this.velocity = (this.velocity * 0.9) + ('0 0 -1800' * (hgt / 256) * PHYS_INPUT_FRAMETIME);
	this.angles_x *= 0.95;
	this.angles_z *= 0.95;

	if(hgt < 16)
		setthink(this, vehicles_think);

	this.nextthink = time;

	CSQCMODEL_AUTOUPDATE(this);
}

void bumblebee_exit(entity this, int eject)
{
	if(this.owner.vehicleid == VEH_BUMBLEBEE.vehicleid)
	{
		bumblebee_gunner_exit(this, eject);
		return;
	}

	settouch(this, vehicles_touch);

	if(!IS_DEAD(this))
	{
		setthink(this, bumblebee_land);
		this.nextthink  = time;
	}

	set_movetype(this, MOVETYPE_TOSS);

	if(!this.owner)
		return;

	fixedmakevectors(this.angles);
	vector spot;
	if(vdist(this.velocity, >, autocvar_g_vehicle_bumblebee_speed_forward * 0.5))
		spot = this.origin + v_up * 128 + v_forward * 300;
	else
		spot = this.origin + v_up * 128 - v_forward * 300;

	spot = vehicles_findgoodexit(this, this.owner, spot);

	// Hide beam
	if(this.gun3.enemy || !wasfreed(this.gun3.enemy))
		this.gun3.enemy.effects |= EF_NODRAW;

	this.owner.velocity = 0.75 * this.vehicle.velocity + normalize(spot - this.vehicle.origin) * 200;
	this.owner.velocity_z += 10;
	setorigin(this.owner, spot);

	antilag_clear(this.owner, CS(this.owner));
	this.owner = NULL;
}

void bumblebee_blowup(entity this)
{
	RadiusDamage(this, this.enemy, autocvar_g_vehicle_bumblebee_blowup_coredamage,
				 autocvar_g_vehicle_bumblebee_blowup_edgedamage,
				 autocvar_g_vehicle_bumblebee_blowup_radius, this, NULL,
				 autocvar_g_vehicle_bumblebee_blowup_forceintensity,
				 DEATH_VH_BUMB_DEATH.m_id, DMG_NOWEP, NULL);

	sound(this, CH_SHOTS, SND_ROCKET_IMPACT, VOL_BASE, ATTEN_NORM);
	Send_Effect(EFFECT_EXPLOSION_BIG, (this.origin + '0 0 100') + (randomvec() * 80), '0 0 0', 1);

	if(this.owner.deadflag == DEAD_DYING)
		this.owner.deadflag = DEAD_DEAD;

	delete(this);
}

void bumblebee_dead_touch(entity this, entity toucher)
{
	bumblebee_blowup(this);
}

void bumblebee_diethink(entity this)
{
	if(time >= this.wait)
		setthink(this, bumblebee_blowup);

	if(random() < 0.1)
	{
		sound(this, CH_SHOTS, SND_ROCKET_IMPACT, VOL_BASE, ATTEN_NORM);
		Send_Effect(EFFECT_EXPLOSION_SMALL, randomvec() * 80 + (this.origin + '0 0 100'), '0 0 0', 1);
	}

	this.nextthink = time + 0.1;
}

spawnfunc(vehicle_bumblebee)
{
	if(!autocvar_g_vehicle_bumblebee) { delete(this); return; }
	if(!vehicle_initialize(this, VEH_BUMBLEBEE, false)) { delete(this); return; }
}

METHOD(Bumblebee, vr_impact, void(Bumblebee thisveh, entity instance))
{
    if(autocvar_g_vehicle_bumblebee_bouncepain)
        vehicles_impact(instance, autocvar_g_vehicle_bumblebee_bouncepain_x, autocvar_g_vehicle_bumblebee_bouncepain_y, autocvar_g_vehicle_bumblebee_bouncepain_z);
}
METHOD(Bumblebee, vr_enter, void(Bumblebee thisveh, entity instance))
{
    settouch(instance, bumblebee_touch);
    instance.nextthink = 0;
    set_movetype(instance, MOVETYPE_BOUNCEMISSILE);
}
METHOD(Bumblebee, vr_gunner_enter, void(Bumblebee thisveh, entity instance, entity actor))
{
	if(!instance.gunner1)
	if(time >= instance.gun1.phase)
	if(instance.gun1.vehicle_enter)
	if(instance.gun1.vehicle_enter(instance, actor))
		return;

	if(!instance.gunner2)
	if(time >= instance.gun2.phase)
	if(instance.gun2.vehicle_enter)
	if(instance.gun2.vehicle_enter(instance, actor))
		return;
}
METHOD(Bumblebee, vr_think, void(Bumblebee thisveh, entity instance))
{
    instance.angles_z *= 0.8;
    instance.angles_x *= 0.8;

    instance.nextthink = time;

    if(!instance.owner)
    {
        if(instance.gunner1)
        {
        	entity e = instance.gunner1;
        	instance.gun1.vehicle_exit(instance.gun1, VHEF_EJECT);
        	instance.phase = 0;
        	gettouch(instance)(instance, e);
        	return;
        }

        if(instance.gunner2)
        {
        	entity e = instance.gunner2;
        	instance.gun2.vehicle_exit(instance.gun2, VHEF_EJECT);
        	instance.phase = 0;
        	gettouch(instance)(instance, e);
            return;
        }
    }
}
METHOD(Bumblebee, vr_death, void(Bumblebee thisveh, entity instance))
{
	CSQCModel_UnlinkEntity(instance);

	// hide beam
	if(instance.gun3.enemy || !wasfreed(instance.gun3.enemy))
		instance.gun3.enemy.effects |= EF_NODRAW;

	if(instance.gunner1)
		instance.gun1.vehicle_exit(instance.gun1, VHEF_EJECT);

	if(instance.gunner2)
		instance.gun2.vehicle_exit(instance.gun2, VHEF_EJECT);

	instance.vehicle_exit(instance, VHEF_EJECT);

    fixedmakevectors(instance.angles);
    vehicle_tossgib(instance, instance.gun1, instance.velocity + v_right * 300 + v_up * 100 + randomvec() * 200, "cannon_right", rint(random()), rint(random()), 6, randomvec() * 200);
    vehicle_tossgib(instance, instance.gun2, instance.velocity + v_right * -300 + v_up * 100 + randomvec() * 200, "cannon_left", rint(random()), rint(random()), 6, randomvec() * 200);
    vehicle_tossgib(instance, instance.gun3, instance.velocity + v_forward * 300 + v_up * -100 + randomvec() * 200, "raygun", rint(random()), rint(random()), 6, randomvec() * 300);

    entity _body = vehicle_tossgib(instance, instance, instance.velocity + randomvec() * 200, "", rint(random()), rint(random()), 6, randomvec() * 100);

    if(random() > 0.5)
        settouch(_body, bumblebee_dead_touch);
    else
        settouch(_body, func_null);

    setthink(_body, bumblebee_diethink);
    _body.nextthink = time;
    _body.wait = time + 2 + (random() * 8);
    _body.owner = instance;
    _body.enemy = instance.enemy;
    _body.scale = 1.5;
    _body.angles = instance.angles;

    Send_Effect(EFFECT_EXPLOSION_MEDIUM, findbetterlocation(instance.origin, 16), '0 0 0', 1);

    SetResourceExplicit(instance, RES_HEALTH, 0);
    instance.event_damage	= func_null;
    instance.solid			= SOLID_NOT;
    instance.takedamage		= DAMAGE_NO;
    instance.deadflag		= DEAD_DYING;
    set_movetype(instance, MOVETYPE_NONE);
    instance.effects		= EF_NODRAW;
    instance.colormod		= '0 0 0';
    instance.avelocity		= '0 0 0';
    instance.velocity		= '0 0 0';
    settouch(instance, func_null);
    instance.nextthink 		= 0;

    setorigin(instance, instance.pos1);
}
METHOD(Bumblebee, vr_spawn, void(Bumblebee thisveh, entity instance))
{
    if(!instance.gun1)
    {
        // for some reason, autosizing of the shield entity refuses to work for this one so set it up in advance.
        instance.vehicle_shieldent = new(vehicle_shieldent);
        instance.vehicle_shieldent.effects = EF_LOWPRECISION;
        setmodel(instance.vehicle_shieldent, MDL_VEH_BUMBLEBEE_SHIELD);
        setattachment(instance.vehicle_shieldent, instance, "");
        setorigin(instance.vehicle_shieldent, real_origin(instance) - instance.origin);
        instance.vehicle_shieldent.scale       = 512 / vlen(instance.maxs - instance.mins);
        setthink(instance.vehicle_shieldent, shieldhit_think);
        instance.vehicle_shieldent.alpha = -1;
        instance.vehicle_shieldent.effects = EF_LOWPRECISION | EF_NODRAW;

        instance.gun1 = new(vehicle_playerslot);
        instance.gun2 = new(vehicle_playerslot);
        instance.gun3 = new(bumblebee_raygun);

        instance.vehicle_flags |= VHF_MULTISLOT;

        instance.gun1.owner = instance;
        instance.gun2.owner = instance;
        instance.gun3.owner = instance;

        setmodel(instance.gun1, MDL_VEH_BUMBLEBEE_CANNON_RIGHT);
        setmodel(instance.gun2, MDL_VEH_BUMBLEBEE_CANNON_LEFT);
        setmodel(instance.gun3, MDL_VEH_BUMBLEBEE_CANNON_CENTER);

        setattachment(instance.gun1, instance, "cannon_right");
        setattachment(instance.gun2, instance, "cannon_left");

        // Angled bones are no fun, messes up gun-aim; so work arround it.
        instance.gun3.pos1 = instance.angles;
        instance.angles = '0 0 0';
        vector ofs = gettaginfo(instance, gettagindex(instance, "raygun"));
        ofs -= instance.origin;
        setattachment(instance.gun3, instance, "");
        setorigin(instance.gun3, ofs);
        instance.angles = instance.gun3.pos1;

        vehicle_addplayerslot(instance, instance.gun1, HUD_BUMBLEBEE_GUN, MDL_VEH_BUMBLEBEE_GUNCOCKPIT, bumblebee_gunner_frame, bumblebee_gunner_exit, bumblebee_gunner_enter);
        vehicle_addplayerslot(instance, instance.gun2, HUD_BUMBLEBEE_GUN, MDL_VEH_BUMBLEBEE_GUNCOCKPIT, bumblebee_gunner_frame, bumblebee_gunner_exit, bumblebee_gunner_enter);

        setorigin(instance.vehicle_hudmodel, '50 0 -5');    // Move cockpit forward - down.
        setorigin(instance.vehicle_viewport, '5 0 2');    // Move camera forward up

        //fixme-model-bones
        setorigin(instance.gun1.vehicle_hudmodel, '90 -27 -23');
        setorigin(instance.gun1.vehicle_viewport, '-85 0 50');
        //fixme-model-bones
        setorigin(instance.gun2.vehicle_hudmodel, '90 27 -23');
        setorigin(instance.gun2.vehicle_viewport, '-85 0 50');

        instance.scale = 1.5;

        // Raygun beam
        if(instance.gun3.enemy == NULL)
        {
            instance.gun3.enemy = new(bumble_raygun);
            Net_LinkEntity(instance.gun3.enemy, true, 0, bumble_raygun_send);
            instance.gun3.enemy.SendFlags = BRG_SETUP;
            instance.gun3.enemy.cnt = autocvar_g_vehicle_bumblebee_raygun;
            instance.gun3.enemy.effects = EF_NODRAW | EF_LOWPRECISION;
        }
    }

    if(!autocvar_g_vehicle_bumblebee_swim)
    	instance.dphitcontentsmask |= DPCONTENTS_LIQUIDSMASK;

    SetResourceExplicit(instance, RES_HEALTH, autocvar_g_vehicle_bumblebee_health);
    instance.vehicle_shield = autocvar_g_vehicle_bumblebee_shield;
    instance.solid = SOLID_BBOX;
    set_movetype(instance, MOVETYPE_TOSS);
    instance.damageforcescale = 0.025;

    instance.PlayerPhysplug = bumblebee_pilot_frame;

    setorigin(instance, instance.origin + '0 0 25');
}
METHOD(Bumblebee, vr_setup, void(Bumblebee thisveh, entity instance))
{
    if(autocvar_g_vehicle_bumblebee_energy)
    if(autocvar_g_vehicle_bumblebee_energy_regen)
        instance.vehicle_flags |= VHF_ENERGYREGEN;

    if(autocvar_g_vehicle_bumblebee_shield)
        instance.vehicle_flags |= VHF_HASSHIELD;

    if(autocvar_g_vehicle_bumblebee_shield_regen)
        instance.vehicle_flags |= VHF_SHIELDREGEN;

    if(autocvar_g_vehicle_bumblebee_health_regen)
        instance.vehicle_flags |= VHF_HEALTHREGEN;

    instance.vehicle_exit = bumblebee_exit;
    instance.respawntime = autocvar_g_vehicle_bumblebee_respawntime;
    SetResourceExplicit(instance, RES_HEALTH, autocvar_g_vehicle_bumblebee_health);
    instance.max_health = GetResource(instance, RES_HEALTH);
    instance.vehicle_shield = autocvar_g_vehicle_bumblebee_shield;
}

#endif // SVQC
#ifdef CSQC

void CSQC_BUMBLE_GUN_HUD()
{
	Vehicles_drawHUD("vehicle_gunner", "vehicle_gunner_weapon1", string_null,
					 "vehicle_icon_ammo1", autocvar_hud_progressbar_vehicles_ammo1_color,
					 string_null, '0 0 0');
}

METHOD(Bumblebee, vr_hud, void(Bumblebee thisveh))
{
    Vehicles_drawHUD(VEH_BUMBLEBEE.m_icon, "vehicle_bumble_weapon1", "vehicle_bumble_weapon2",
                     "vehicle_icon_ammo1", autocvar_hud_progressbar_vehicles_ammo1_color,
                     "vehicle_icon_ammo1", autocvar_hud_progressbar_vehicles_ammo1_color);

    float hudAlpha = autocvar_hud_panel_fg_alpha;
    float blinkValue = 0.55 + sin(time * 7) * 0.45;
    vector tmpPos  = '0 0 0';
    vector tmpSize = hud_fontsize;
    tmpPos.x = vehicleHud_Pos.x + vehicleHud_Size.x * (520/768);

    if(!AuxiliaryXhair[1].draw2d)
    {
        tmpPos.y = vehicleHud_Pos.y + vehicleHud_Size.y * (96/256) - tmpSize.y;
        drawstring(tmpPos, _("No right gunner!"), tmpSize, '1 1 1', hudAlpha * blinkValue, DRAWFLAG_NORMAL);
    }

    if(!AuxiliaryXhair[2].draw2d)
    {
        tmpPos.y = vehicleHud_Pos.y + vehicleHud_Size.y * (160/256);
        drawstring(tmpPos, _("No left gunner!"), tmpSize, '1 1 1', hudAlpha * blinkValue, DRAWFLAG_NORMAL);
    }
}
METHOD(Bumblebee, vr_crosshair, void(Bumblebee thisveh, entity player))
{
    Vehicles_drawCrosshair(vCROSS_HEAL);
}
METHOD(Bumblebee, vr_setup, void(Bumblebee thisveh, entity instance))
{
    AuxiliaryXhair[0].axh_image = vCROSS_LOCK;  // Raygun-locked
    AuxiliaryXhair[1].axh_image = vCROSS_BURST; // Gunner1
    AuxiliaryXhair[2].axh_image = vCROSS_BURST; // Gunner2
}

#endif

#endif
#ifdef MENUQC

METHOD(Bumblebee, describe, string(Bumblebee this))
{
	TC(Bumblebee, this);
	PAGE_TEXT_INIT();
	PAR(_("The %s vehicle seats up to three passengers, who are given different roles based on the order they enter."), COLORED_NAME(this));
	PAR(_("The first player to enter will be the pilot, flying the vehicle up into the skies. "
	      "The first player can also shoot a green healing wave to heal other teammates on the ground."));
	PAR(_("The second player to enter is the right gunner and the third player to enter is the left gunner."));
	PAR(_("When the pilot exits the vehicle, the players switch roles by moving up in position."));
	return PAGE_TEXT;
}

#endif
