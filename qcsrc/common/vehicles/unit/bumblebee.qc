#ifndef VEHICLE_BUMBLEBEE
#define VEHICLE_BUMBLEBEE
#include "bumblebee.qh"
#ifndef MENUQC
int v_bumblebee(int);
#endif
REGISTER_VEHICLE_SIMPLE(
/* VEH_##id   */ BUMBLEBEE,
/* spawnflags */ VHF_DMGSHAKE,
/* mins,maxs  */ '-245 -130 -130', '230 130 130',
/* model	  */ "models/vehicles/bumblebee_body.dpm",
/* head_model */ "",
/* hud_model  */ "models/vehicles/spiderbot_cockpit.dpm",
/* tags	   	  */ "", "", "tag_viewport",
/* netname	  */ "bumblebee",
/* fullname   */ _("Bumblebee")
) {
    this.m_icon = "vehicle_bumble";
#ifndef MENUQC
    this.vehicle_func = v_bumblebee;
#endif
}
#endif

#ifdef IMPLEMENTATION

const float BRG_SETUP = 2;
const float BRG_START = 4;
const float BRG_END = 8;

#ifdef SVQC
float autocvar_g_vehicle_bumblebee_speed_forward;
float autocvar_g_vehicle_bumblebee_speed_strafe;
float autocvar_g_vehicle_bumblebee_speed_up;
float autocvar_g_vehicle_bumblebee_speed_down;
float autocvar_g_vehicle_bumblebee_turnspeed;
float autocvar_g_vehicle_bumblebee_pitchspeed;
float autocvar_g_vehicle_bumblebee_pitchlimit;
float autocvar_g_vehicle_bumblebee_friction;

float autocvar_g_vehicle_bumblebee_energy;
float autocvar_g_vehicle_bumblebee_energy_regen;
float autocvar_g_vehicle_bumblebee_energy_regen_pause;

float autocvar_g_vehicle_bumblebee_health;
float autocvar_g_vehicle_bumblebee_health_regen;
float autocvar_g_vehicle_bumblebee_health_regen_pause;

float autocvar_g_vehicle_bumblebee_shield;
float autocvar_g_vehicle_bumblebee_shield_regen;
float autocvar_g_vehicle_bumblebee_shield_regen_pause;

float autocvar_g_vehicle_bumblebee_cannon_cost;
float autocvar_g_vehicle_bumblebee_cannon_damage;
float autocvar_g_vehicle_bumblebee_cannon_radius;
float autocvar_g_vehicle_bumblebee_cannon_refire;
float autocvar_g_vehicle_bumblebee_cannon_speed;
float autocvar_g_vehicle_bumblebee_cannon_spread;
float autocvar_g_vehicle_bumblebee_cannon_force;

float autocvar_g_vehicle_bumblebee_cannon_ammo;
float autocvar_g_vehicle_bumblebee_cannon_ammo_regen;
float autocvar_g_vehicle_bumblebee_cannon_ammo_regen_pause;

float autocvar_g_vehicle_bumblebee_cannon_lock = 0;

float autocvar_g_vehicle_bumblebee_cannon_turnspeed;
float autocvar_g_vehicle_bumblebee_cannon_pitchlimit_down;
float autocvar_g_vehicle_bumblebee_cannon_pitchlimit_up;
float autocvar_g_vehicle_bumblebee_cannon_turnlimit_in;
float autocvar_g_vehicle_bumblebee_cannon_turnlimit_out;


float autocvar_g_vehicle_bumblebee_raygun_turnspeed;
float autocvar_g_vehicle_bumblebee_raygun_pitchlimit_down;
float autocvar_g_vehicle_bumblebee_raygun_pitchlimit_up;
float autocvar_g_vehicle_bumblebee_raygun_turnlimit_sides;

float autocvar_g_vehicle_bumblebee_raygun_range;
float autocvar_g_vehicle_bumblebee_raygun_dps;
float autocvar_g_vehicle_bumblebee_raygun_aps;
float autocvar_g_vehicle_bumblebee_raygun_fps;

float autocvar_g_vehicle_bumblebee_raygun;
float autocvar_g_vehicle_bumblebee_healgun_hps;
float autocvar_g_vehicle_bumblebee_healgun_hmax;
float autocvar_g_vehicle_bumblebee_healgun_aps;
float autocvar_g_vehicle_bumblebee_healgun_amax;
float autocvar_g_vehicle_bumblebee_healgun_sps;
float autocvar_g_vehicle_bumblebee_healgun_locktime;

float autocvar_g_vehicle_bumblebee_respawntime;

float autocvar_g_vehicle_bumblebee_blowup_radius;
float autocvar_g_vehicle_bumblebee_blowup_coredamage;
float autocvar_g_vehicle_bumblebee_blowup_edgedamage;
float autocvar_g_vehicle_bumblebee_blowup_forceintensity;
vector autocvar_g_vehicle_bumblebee_bouncepain;

bool autocvar_g_vehicle_bumblebee = 0;

float bumble_raygun_send(entity to, int sf);

void bumblebee_fire_cannon(entity _gun, string _tagname, entity _owner)
{
	vector v = gettaginfo(_gun, gettagindex(_gun, _tagname));
	vehicles_projectile(EFFECT_BIGPLASMA_MUZZLEFLASH.eent_eff_name, SND(VEH_BUMBLEBEE_FIRE),
						v, normalize(v_forward + randomvec() * autocvar_g_vehicle_bumblebee_cannon_spread) * autocvar_g_vehicle_bumblebee_cannon_speed,
						autocvar_g_vehicle_bumblebee_cannon_damage, autocvar_g_vehicle_bumblebee_cannon_radius, autocvar_g_vehicle_bumblebee_cannon_force,  0,
						DEATH_VH_BUMB_GUN, PROJECTILE_BUMBLE_GUN, 0, true, true, _owner);
}

float bumblebee_gunner_frame()
{SELFPARAM();
	entity vehic    = self.vehicle.owner;
	entity gun      = self.vehicle;
	entity gunner   = self;
	setself(vehic);

	vehic.solid = SOLID_NOT;
	//setorigin(gunner, vehic.origin);
	gunner.velocity = vehic.velocity;

	float _in, _out;
	vehic.angles_x *= -1;
	makevectors(vehic.angles);
	vehic.angles_x *= -1;
	if(gun == vehic.gun1)
	{
		_in = autocvar_g_vehicle_bumblebee_cannon_turnlimit_in;
		_out = autocvar_g_vehicle_bumblebee_cannon_turnlimit_out;
		setorigin(gunner, vehic.origin + v_up * -16 + v_forward * -16 + v_right * 128);
	}
	else
	{
		_in = autocvar_g_vehicle_bumblebee_cannon_turnlimit_out;
		_out = autocvar_g_vehicle_bumblebee_cannon_turnlimit_in;
		setorigin(gunner, vehic.origin + v_up * -16 + v_forward * -16 + v_right * -128);
	}

	crosshair_trace(gunner);
	vector _ct = trace_endpos;
	vector ad;

	if(autocvar_g_vehicle_bumblebee_cannon_lock)
	{
		if(gun.lock_time < time)
			gun.enemy = world;

		if(trace_ent)
			if(trace_ent.movetype)
				if(trace_ent.takedamage)
					if(!trace_ent.deadflag)
					{
						if(DIFF_TEAM(trace_ent, gunner))
						{
							gun.enemy = trace_ent;
							gun.lock_time = time + 5;
						}
					}
	}

	if(gun.enemy)
	{
		float distance, impact_time;

		vector vf = real_origin(gun.enemy);
		vector _vel = gun.enemy.velocity;
		if(gun.enemy.movetype == MOVETYPE_WALK)
			_vel.z *= 0.1;


		ad = vf;
		distance = vlen(ad - gunner.origin);
		impact_time = distance / autocvar_g_vehicle_bumblebee_cannon_speed;
		ad = vf + _vel * impact_time;
		trace_endpos = ad;


		UpdateAuxiliaryXhair(gunner, ad, '1 0 1', 1);
		vehicle_aimturret(vehic, trace_endpos, gun, "fire",
						  autocvar_g_vehicle_bumblebee_cannon_pitchlimit_down * -1, autocvar_g_vehicle_bumblebee_cannon_pitchlimit_up,
						  _out * -1,  _in,  autocvar_g_vehicle_bumblebee_cannon_turnspeed);

	}
	else
		vehicle_aimturret(vehic, _ct, gun, "fire",
						  autocvar_g_vehicle_bumblebee_cannon_pitchlimit_down * -1, autocvar_g_vehicle_bumblebee_cannon_pitchlimit_up,
						  _out * -1,  _in,  autocvar_g_vehicle_bumblebee_cannon_turnspeed);

	if(!forbidWeaponUse(gunner))
	if(gunner.BUTTON_ATCK)
		if(time > gun.attack_finished_single)
			if(gun.vehicle_energy >= autocvar_g_vehicle_bumblebee_cannon_cost)
			{
				gun.vehicle_energy -= autocvar_g_vehicle_bumblebee_cannon_cost;
				bumblebee_fire_cannon(gun, "fire", gunner);
				gun.delay = time;
				gun.attack_finished_single = time + autocvar_g_vehicle_bumblebee_cannon_refire;
			}

	VEHICLE_UPDATE_PLAYER(gunner, health, bumblebee);

	if(vehic.vehicle_flags & VHF_HASSHIELD)
		VEHICLE_UPDATE_PLAYER(gunner, shield, bumblebee);

	ad = gettaginfo(gun, gettagindex(gun, "fire"));
	traceline(ad, ad + v_forward * MAX_SHOT_DISTANCE, MOVE_NORMAL, gun);

	UpdateAuxiliaryXhair(gunner, trace_endpos, ('1 0 0' * gunner.vehicle_reload1) + ('0 1 0' *(1 - gunner.vehicle_reload1)), 0);

	if(vehic.owner)
		UpdateAuxiliaryXhair(vehic.owner, trace_endpos, ('1 0 0' * gunner.vehicle_reload1) + ('0 1 0' *(1 - gunner.vehicle_reload1)), ((gunner == vehic.gunner1) ? 1 : 2));

	vehic.solid = SOLID_BBOX;
	gunner.BUTTON_ATCK = gunner.BUTTON_ATCK2 = gunner.BUTTON_CROUCH = 0;
	gunner.vehicle_energy = (gun.vehicle_energy / autocvar_g_vehicle_bumblebee_cannon_ammo) * 100;

	setself(gunner);
	return 1;
}

vector bumblebee_gunner_findgoodexit(vector prefer_spot, entity gunner, entity player)
{
	//vector exitspot;
	float mysize;

	tracebox(gunner.origin + '0 0 32', PL_MIN, PL_MAX, prefer_spot, MOVE_NORMAL, player);
	if(trace_fraction == 1.0 && !trace_startsolid && !trace_allsolid)
		return prefer_spot;

	mysize = 1.5 * vlen(PL_MAX - PL_MIN); // can't use gunner's size, as they don't have a size
	float i;
	vector v, v2;
	v2 = 0.5 * (gunner.absmin + gunner.absmax);
	for(i = 0; i < 100; ++i)
	{
		v = randomvec();
		v_z = 0;
		v = v2 + normalize(v) * mysize;
		tracebox(v2, PL_MIN, PL_MAX, v, MOVE_NORMAL, player);
		if(trace_fraction == 1.0 && !trace_startsolid && !trace_allsolid)
			return v;
	}

	return prefer_spot; // this should be considered a fallback?!
}

void bumblebee_gunner_exit(int _exitflag)
{SELFPARAM();
	entity player = self;
	entity gunner = player.vehicle;
	entity vehic = gunner.owner;

	if(IS_REAL_CLIENT(player))
	{
		msg_entity = player;
		WriteByte(MSG_ONE, SVC_SETVIEWPORT);
		WriteEntity(MSG_ONE, player);

		WriteByte(MSG_ONE, SVC_SETVIEWANGLES);
		WriteAngle(MSG_ONE, 0);
		WriteAngle(MSG_ONE, vehic.angles.y);
		WriteAngle(MSG_ONE, 0);
	}

	CSQCVehicleSetup(player, HUD_NORMAL);
	setsize(player, PL_MIN, PL_MAX);

	player.takedamage     = DAMAGE_AIM;
	player.solid          = SOLID_SLIDEBOX;
	player.movetype       = MOVETYPE_WALK;
	player.effects       &= ~EF_NODRAW;
	player.alpha          = 1;
	player.PlayerPhysplug = func_null;
	player.view_ofs       = PL_VIEW_OFS;
	player.event_damage   = PlayerDamage;
	player.hud            = HUD_NORMAL;
	player.teleportable	  = TELEPORT_NORMAL;
	player.switchweapon   = gunner.switchweapon;
	player.vehicle_enter_delay = time + 2;

	fixedmakevectors(vehic.angles);

	if(player == vehic.gunner1) { vehic.gunner1 = world; }
	if(player == vehic.gunner2) { vehic.gunner2 = world; v_right *= -1; }

	vector spot = real_origin(gunner);
	spot = spot + v_up * 128 + v_forward * 300 + v_right * 150;
	spot = bumblebee_gunner_findgoodexit(spot, gunner, player);

	// TODO: figure a way to move player out of the gunner

	player.velocity = 0.75 * vehic.velocity + normalize(spot - vehic.origin) * 200;
	player.velocity_z += 10;

	gunner.phase = time + 5;
	gunner.vehicle_hudmodel.viewmodelforclient = gunner;

	MUTATOR_CALLHOOK(VehicleExit, player, gunner);

	player.vehicle = world;
}

bool bumblebee_gunner_enter()
{SELFPARAM();
	entity vehic = self;
	entity player = other;
	entity gunner = world;

	if(!vehic.gunner1 && !vehic.gunner2 && ((time >= vehic.gun1.phase) + (time >= vehic.gun2.phase)) == 2)
	{
		// we can have some fun
		if(vlen(real_origin(vehic.gun2) - player.origin) < vlen(real_origin(vehic.gun1) - player.origin))
		{
			gunner = vehic.gun2;
			vehic.gunner2 = player;
		}
		else
		{
			gunner = vehic.gun1;
			vehic.gunner1 = player;
		}
	}
	else if(!vehic.gunner1 && time >= vehic.gun1.phase) 	{ gunner = vehic.gun1; vehic.gunner1 = player; }
	else if(!vehic.gunner2 && time >= vehic.gun2.phase)		{ gunner = vehic.gun2; vehic.gunner2 = player; }
	else { LOG_TRACE("Vehicle is full, fail\n"); return false; }

	player.vehicle 			= gunner;
	player.angles 			= vehic.angles;
	player.takedamage 		= DAMAGE_NO;
	player.solid 			= SOLID_NOT;
	player.alpha 			= -1;
	player.movetype 		= MOVETYPE_NOCLIP;
	player.event_damage 	= func_null;
	player.view_ofs 		= '0 0 0';
	player.hud 				= gunner.hud;
	player.teleportable 	= false;
	player.PlayerPhysplug 	= gunner.PlayerPhysplug;
	player.vehicle_ammo1 	= vehic.vehicle_ammo1;
	player.vehicle_ammo2 	= vehic.vehicle_ammo2;
	player.vehicle_reload1 	= vehic.vehicle_reload1;
	player.vehicle_reload2 	= vehic.vehicle_reload2;
	player.vehicle_energy 	= vehic.vehicle_energy;
	player.flags 		   &= ~FL_ONGROUND;

	RemoveGrapplingHook(player);

	gunner.switchweapon = player.switchweapon;
	gunner.vehicle_exit = bumblebee_gunner_exit;
	gunner.vehicle_hudmodel.viewmodelforclient = player;

	if(IS_REAL_CLIENT(player))
	{
		msg_entity = player;
		WriteByte(MSG_ONE, 		SVC_SETVIEWPORT);
		WriteEntity(MSG_ONE, 	gunner.vehicle_viewport);

		WriteByte(MSG_ONE, 		SVC_SETVIEWANGLES);
		WriteAngle(MSG_ONE, 	gunner.angles_x + vehic.angles_x); // tilt
		WriteAngle(MSG_ONE, 	gunner.angles_y + vehic.angles_y); // yaw
		WriteAngle(MSG_ONE, 	0); // roll
	}

	CSQCVehicleSetup(player, player.hud);

	MUTATOR_CALLHOOK(VehicleEnter, player, gunner);

	return true;
}

bool vehicles_valid_pilot()
{SELFPARAM();
	if(IS_BOT_CLIENT(other) && !autocvar_g_vehicles_allow_bots)
		return false;

	if((!IS_PLAYER(other))
	|| (other.deadflag != DEAD_NO)
	|| (other.vehicle)
	|| (DIFF_TEAM(other, self))
	) { return false; }

	return true;
}

void bumblebee_touch()
{SELFPARAM();
	if(autocvar_g_vehicles_enter) { return; }

	if(self.gunner1 != world && self.gunner2 != world)
	{
		vehicles_touch();
		return;
	}

	if(vehicles_valid_pilot())
	{
		float phase_time = (time >= self.gun1.phase) + (time >= self.gun2.phase);

		if(time >= other.vehicle_enter_delay && phase_time)
		if(bumblebee_gunner_enter())
			return;
	}

	vehicles_touch();
}

void bumblebee_regen()
{SELFPARAM();
	if(self.gun1.delay + autocvar_g_vehicle_bumblebee_cannon_ammo_regen_pause < time)
		self.gun1.vehicle_energy = min(autocvar_g_vehicle_bumblebee_cannon_ammo,
									   self.gun1.vehicle_energy + autocvar_g_vehicle_bumblebee_cannon_ammo_regen * frametime);

	if(self.gun2.delay + autocvar_g_vehicle_bumblebee_cannon_ammo_regen_pause < time)
		self.gun2.vehicle_energy = min(autocvar_g_vehicle_bumblebee_cannon_ammo,
									   self.gun2.vehicle_energy + autocvar_g_vehicle_bumblebee_cannon_ammo_regen * frametime);

	if(self.vehicle_flags  & VHF_SHIELDREGEN)
		vehicles_regen(self.dmg_time, vehicle_shield, autocvar_g_vehicle_bumblebee_shield, autocvar_g_vehicle_bumblebee_shield_regen_pause, autocvar_g_vehicle_bumblebee_shield_regen, frametime, true);

	if(self.vehicle_flags  & VHF_HEALTHREGEN)
		vehicles_regen(self.dmg_time, vehicle_health, autocvar_g_vehicle_bumblebee_health, autocvar_g_vehicle_bumblebee_health_regen_pause, autocvar_g_vehicle_bumblebee_health_regen, frametime, false);

	if(self.vehicle_flags  & VHF_ENERGYREGEN)
		vehicles_regen(self.wait, vehicle_energy, autocvar_g_vehicle_bumblebee_energy, autocvar_g_vehicle_bumblebee_energy_regen_pause, autocvar_g_vehicle_bumblebee_energy_regen, frametime, false);

}

float bumblebee_pilot_frame()
{SELFPARAM();
	entity pilot, vehic;
	vector newvel;

	if(intermission_running)
	{
		self.vehicle.velocity = '0 0 0';
		self.vehicle.avelocity = '0 0 0';
		return 1;
	}

	pilot = self;
	vehic = self.vehicle;
	setself(vehic);

	if(vehic.deadflag != DEAD_NO)
	{
		setself(pilot);
		pilot.BUTTON_ATCK = pilot.BUTTON_ATCK2 = 0;
		return 1;
	}

	bumblebee_regen();

	crosshair_trace(pilot);

	vector vang;
	float ftmp;

	vang = vehic.angles;
	newvel = vectoangles(normalize(trace_endpos - self.origin + '0 0 32'));
	vang.x *= -1;
	newvel.x *= -1;
	if(newvel.x > 180)  newvel.x -= 360;
	if(newvel.x < -180) newvel.x += 360;
	if(newvel.y > 180)  newvel.y -= 360;
	if(newvel.y < -180) newvel.y += 360;

	ftmp = shortangle_f(pilot.v_angle.y - vang.y, vang.y);
	if(ftmp > 180)  ftmp -= 360;
	if(ftmp < -180) ftmp += 360;
	vehic.avelocity_y = bound(-autocvar_g_vehicle_bumblebee_turnspeed, ftmp + vehic.avelocity.y * 0.9, autocvar_g_vehicle_bumblebee_turnspeed);

	// Pitch
	ftmp = 0;
	if(pilot.movement.x > 0 && vang.x < autocvar_g_vehicle_bumblebee_pitchlimit)
		ftmp = 4;
	else if(pilot.movement.x < 0 && vang.x > -autocvar_g_vehicle_bumblebee_pitchlimit)
		ftmp = -8;

	newvel.x = bound(-autocvar_g_vehicle_bumblebee_pitchlimit, newvel.x , autocvar_g_vehicle_bumblebee_pitchlimit);
	ftmp = vang.x - bound(-autocvar_g_vehicle_bumblebee_pitchlimit, newvel.x + ftmp, autocvar_g_vehicle_bumblebee_pitchlimit);
	vehic.avelocity_x = bound(-autocvar_g_vehicle_bumblebee_pitchspeed, ftmp + vehic.avelocity.x * 0.9, autocvar_g_vehicle_bumblebee_pitchspeed);

	vehic.angles_x = anglemods(vehic.angles.x);
	vehic.angles_y = anglemods(vehic.angles.y);
	vehic.angles_z = anglemods(vehic.angles.z);

	makevectors('0 1 0' * vehic.angles.y);
	newvel = vehic.velocity * -autocvar_g_vehicle_bumblebee_friction;

	if(pilot.movement.x != 0)
	{
		if(pilot.movement.x > 0)
			newvel += v_forward  * autocvar_g_vehicle_bumblebee_speed_forward;
		else if(pilot.movement.x < 0)
			newvel -= v_forward  * autocvar_g_vehicle_bumblebee_speed_forward;
	}

	if(pilot.movement.y != 0)
	{
		if(pilot.movement.y < 0)
			newvel -= v_right * autocvar_g_vehicle_bumblebee_speed_strafe;
		else if(pilot.movement.y > 0)
			newvel += v_right * autocvar_g_vehicle_bumblebee_speed_strafe;
		ftmp = newvel * v_right;
		ftmp *= frametime * 0.1;
		vehic.angles_z = bound(-15, vehic.angles.z + ftmp, 15);
	}
	else
	{
		vehic.angles_z *= 0.95;
		if(vehic.angles.z >= -1 && vehic.angles.z <= -1)
			vehic.angles_z = 0;
	}

	if(pilot.BUTTON_CROUCH)
		newvel -=   v_up * autocvar_g_vehicle_bumblebee_speed_down;
	else if(pilot.BUTTON_JUMP)
		newvel +=  v_up * autocvar_g_vehicle_bumblebee_speed_up;

	vehic.velocity  += newvel * frametime;
	pilot.velocity = pilot.movement  = vehic.velocity;


	if(autocvar_g_vehicle_bumblebee_healgun_locktime)
	{
		if(vehic.tur_head.lock_time < time || vehic.tur_head.enemy.deadflag)
			vehic.tur_head.enemy = world;

		if(trace_ent)
		if(trace_ent.movetype)
		if(trace_ent.takedamage)
		if(!trace_ent.deadflag)
		{
			if(teamplay)
			{
				if(trace_ent.team == pilot.team)
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
			UpdateAuxiliaryXhair(pilot, trace_endpos, '0 0.75 0', 0);
		}
	}

	vang = vehicle_aimturret(vehic, trace_endpos, self.gun3, "fire",
					  autocvar_g_vehicle_bumblebee_raygun_pitchlimit_down * -1,  autocvar_g_vehicle_bumblebee_raygun_pitchlimit_up,
					  autocvar_g_vehicle_bumblebee_raygun_turnlimit_sides * -1,  autocvar_g_vehicle_bumblebee_raygun_turnlimit_sides,  autocvar_g_vehicle_bumblebee_raygun_turnspeed);

	if(!forbidWeaponUse(pilot))
	if((pilot.BUTTON_ATCK || pilot.BUTTON_ATCK2) && (vehic.vehicle_energy > autocvar_g_vehicle_bumblebee_raygun_dps * sys_frametime || autocvar_g_vehicle_bumblebee_raygun == 0))
	{
		vehic.gun3.enemy.realowner = pilot;
		vehic.gun3.enemy.effects &= ~EF_NODRAW;

		vehic.gun3.enemy.hook_start = gettaginfo(vehic.gun3, gettagindex(vehic.gun3, "fire"));
		vehic.gun3.enemy.SendFlags |= BRG_START;

		traceline(vehic.gun3.enemy.hook_start, vehic.gun3.enemy.hook_start + v_forward * autocvar_g_vehicle_bumblebee_raygun_range, MOVE_NORMAL, vehic);

		if(trace_ent)
		{
			if(autocvar_g_vehicle_bumblebee_raygun)
			{
				Damage(trace_ent, vehic, pilot, autocvar_g_vehicle_bumblebee_raygun_dps * sys_frametime, DEATH_GENERIC, trace_endpos, v_forward * autocvar_g_vehicle_bumblebee_raygun_fps * sys_frametime);
				vehic.vehicle_energy -= autocvar_g_vehicle_bumblebee_raygun_aps * sys_frametime;
			}
			else
			{
				if(trace_ent.deadflag == DEAD_NO)
					if((teamplay && trace_ent.team == pilot.team) || !teamplay)
					{

						if(trace_ent.vehicle_flags & VHF_ISVEHICLE)
						{
							if(autocvar_g_vehicle_bumblebee_healgun_sps && trace_ent.vehicle_health <= trace_ent.max_health)
								trace_ent.vehicle_shield = min(trace_ent.vehicle_shield + autocvar_g_vehicle_bumblebee_healgun_sps * frametime, trace_ent.tur_head.max_health);

							if(autocvar_g_vehicle_bumblebee_healgun_hps)
								trace_ent.vehicle_health = min(trace_ent.vehicle_health + autocvar_g_vehicle_bumblebee_healgun_hps * frametime, trace_ent.max_health);
						}
						else if(IS_CLIENT(trace_ent))
						{
							if(trace_ent.health <= autocvar_g_vehicle_bumblebee_healgun_hmax && autocvar_g_vehicle_bumblebee_healgun_hps)
								trace_ent.health = min(trace_ent.health + autocvar_g_vehicle_bumblebee_healgun_hps * frametime, autocvar_g_vehicle_bumblebee_healgun_hmax);

							if(trace_ent.armorvalue <= autocvar_g_vehicle_bumblebee_healgun_amax && autocvar_g_vehicle_bumblebee_healgun_aps)
								trace_ent.armorvalue = min(trace_ent.armorvalue + autocvar_g_vehicle_bumblebee_healgun_aps * frametime, autocvar_g_vehicle_bumblebee_healgun_amax);

							trace_ent.health = min(trace_ent.health + autocvar_g_vehicle_bumblebee_healgun_hps * frametime, autocvar_g_vehicle_bumblebee_healgun_hmax);
						}
						else if(IS_TURRET(trace_ent))
						{
							if(trace_ent.health  <= trace_ent.max_health && autocvar_g_vehicle_bumblebee_healgun_hps)
								trace_ent.health = min(trace_ent.health + autocvar_g_vehicle_bumblebee_healgun_hps * frametime, trace_ent.max_health);
							//else ..hmmm what? ammo?

							trace_ent.SendFlags |= TNSF_STATUS;
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

		vehic.gun3.enemy = world;
	}
	*/

	VEHICLE_UPDATE_PLAYER(pilot, health, bumblebee);
	VEHICLE_UPDATE_PLAYER(pilot, energy, bumblebee);

	pilot.vehicle_ammo1 = (vehic.gun1.vehicle_energy / autocvar_g_vehicle_bumblebee_cannon_ammo) * 100;
	pilot.vehicle_ammo2 = (vehic.gun2.vehicle_energy / autocvar_g_vehicle_bumblebee_cannon_ammo) * 100;

	if(vehic.vehicle_flags & VHF_HASSHIELD)
		VEHICLE_UPDATE_PLAYER(pilot, shield, bumblebee);

	vehic.angles_x *= -1;
	makevectors(vehic.angles);
	vehic.angles_x *= -1;
	setorigin(pilot, vehic.origin + v_up * 48 + v_forward * 160);

	pilot.BUTTON_ATCK = pilot.BUTTON_ATCK2 = pilot.BUTTON_CROUCH = 0;
	setself(pilot);

	return 1;
}

void bumblebee_land()
{SELFPARAM();
	float hgt;

	hgt = raptor_altitude(512);
	self.velocity = (self.velocity * 0.9) + ('0 0 -1800' * (hgt / 256) * sys_frametime);
	self.angles_x *= 0.95;
	self.angles_z *= 0.95;

	if(hgt < 16)
		self.think	= vehicles_think;

	self.nextthink = time;

	CSQCMODEL_AUTOUPDATE(self);
}

void bumblebee_exit(float eject)
{SELFPARAM();
	if(self.owner.vehicleid == VEH_BUMBLEBEE.vehicleid)
	{
		bumblebee_gunner_exit(eject);
		return;
	}

	self.touch = vehicles_touch;

	if(self.deadflag == DEAD_NO)
	{
		self.think = bumblebee_land;
		self.nextthink  = time;
	}

	self.movetype = MOVETYPE_TOSS;

	if(!self.owner)
		return;

	fixedmakevectors(self.angles);
	vector spot;
	if(vlen(self.velocity) > autocvar_g_vehicle_bumblebee_speed_forward * 0.5)
		spot = self.origin + v_up * 128 + v_forward * 300;
	else
		spot = self.origin + v_up * 128 - v_forward * 300;

	spot = vehicles_findgoodexit(spot);

	// Hide beam
	if(self.gun3.enemy || !wasfreed(self.gun3.enemy)) {
		self.gun3.enemy.effects |= EF_NODRAW;
	}

	self.owner.velocity = 0.75 * self.vehicle.velocity + normalize(spot - self.vehicle.origin) * 200;
	self.owner.velocity_z += 10;
	setorigin(self.owner, spot);

	antilag_clear(self.owner);
	self.owner = world;
}

void bumblebee_blowup()
{SELFPARAM();
	RadiusDamage(self, self.enemy, autocvar_g_vehicle_bumblebee_blowup_coredamage,
				 autocvar_g_vehicle_bumblebee_blowup_edgedamage,
				 autocvar_g_vehicle_bumblebee_blowup_radius, self, world,
				 autocvar_g_vehicle_bumblebee_blowup_forceintensity,
				 DEATH_VH_BUMB_DEATH, world);

	sound(self, CH_SHOTS, SND_ROCKET_IMPACT, VOL_BASE, ATTEN_NORM);
	Send_Effect(EFFECT_EXPLOSION_BIG, (self.origin + '0 0 100') + (randomvec() * 80), '0 0 0', 1);

	if(self.owner.deadflag == DEAD_DYING)
		self.owner.deadflag = DEAD_DEAD;

	remove(self);
}

void bumblebee_diethink()
{SELFPARAM();
	if(time >= self.wait)
		self.think = bumblebee_blowup;

	if(random() < 0.1)
	{
		sound(self, CH_SHOTS, SND_ROCKET_IMPACT, VOL_BASE, ATTEN_NORM);
		Send_Effect(EFFECT_EXPLOSION_SMALL, randomvec() * 80 + (self.origin + '0 0 100'), '0 0 0', 1);
	}

	self.nextthink = time + 0.1;
}

float bumble_raygun_send(entity to, float sf)
{SELFPARAM();
	WriteByte(MSG_ENTITY, ENT_CLIENT_BUMBLE_RAYGUN);

	WriteByte(MSG_ENTITY, sf);
	if(sf & BRG_SETUP)
	{
		WriteByte(MSG_ENTITY, num_for_edict(self.realowner));
		WriteByte(MSG_ENTITY, self.realowner.team);
		WriteByte(MSG_ENTITY, self.cnt);
	}

	if(sf & BRG_START)
	{
		WriteCoord(MSG_ENTITY, self.hook_start_x);
		WriteCoord(MSG_ENTITY, self.hook_start_y);
		WriteCoord(MSG_ENTITY, self.hook_start_z);
	}

	if(sf & BRG_END)
	{
		WriteCoord(MSG_ENTITY, self.hook_end_x);
		WriteCoord(MSG_ENTITY, self.hook_end_y);
		WriteCoord(MSG_ENTITY, self.hook_end_z);
	}

	return true;
}

void spawnfunc_vehicle_bumblebee()
{SELFPARAM();
	if(!autocvar_g_vehicle_bumblebee) { remove(self); return; }
	if(!vehicle_initialize(VEH_BUMBLEBEE, false)) { remove(self); return; }
}

float v_bumblebee(float req)
{SELFPARAM();
	switch(req)
	{
		case VR_IMPACT:
		{
			if(autocvar_g_vehicle_bumblebee_bouncepain)
				vehicles_impact(autocvar_g_vehicle_bumblebee_bouncepain_x, autocvar_g_vehicle_bumblebee_bouncepain_y, autocvar_g_vehicle_bumblebee_bouncepain_z);

			return true;
		}
		case VR_ENTER:
		{
			self.touch = bumblebee_touch;
			self.nextthink = 0;
			self.movetype = MOVETYPE_BOUNCEMISSILE;
			return true;
		}
		case VR_THINK:
		{
			self.angles_z *= 0.8;
			self.angles_x *= 0.8;

			self.nextthink = time;

			if(!self.owner)
			{
				entity oldself = self;
				if(self.gunner1)
				{
					setself(self.gunner1);
					oldself.gun1.vehicle_exit(VHEF_EJECT);
					entity oldother = other;
					other = self;
					setself(oldself);
					self.phase = 0;
					self.touch();
					other = oldother;
					return true;
				}

				if(self.gunner2)
				{
					setself(self.gunner2);
					oldself.gun2.vehicle_exit(VHEF_EJECT);
					entity oldother = other;
					other = self;
					setself(oldself);
					self.phase = 0;
					self.touch();
					other = oldother;
					return true;
				}
			}

			return true;
		}
		case VR_DEATH:
		{
			entity oldself = self;

			CSQCModel_UnlinkEntity();

			// Hide beam
			if(self.gun3.enemy || !wasfreed(self.gun3.enemy))
				self.gun3.enemy.effects |= EF_NODRAW;

			if(self.gunner1)
			{
				setself(self.gunner1);
				oldself.gun1.vehicle_exit(VHEF_EJECT);
				setself(oldself);
			}

			if(self.gunner2)
			{
				setself(self.gunner2);
				oldself.gun2.vehicle_exit(VHEF_EJECT);
				setself(oldself);
			}

			self.vehicle_exit(VHEF_EJECT);

			fixedmakevectors(self.angles);
			vehicle_tossgib(self.gun1, self.velocity + v_right * 300 + v_up * 100 + randomvec() * 200, "cannon_right", rint(random()), rint(random()), 6, randomvec() * 200);
			vehicle_tossgib(self.gun2, self.velocity + v_right * -300 + v_up * 100 + randomvec() * 200, "cannon_left", rint(random()), rint(random()), 6, randomvec() * 200);
			vehicle_tossgib(self.gun3, self.velocity + v_forward * 300 + v_up * -100 + randomvec() * 200, "raygun", rint(random()), rint(random()), 6, randomvec() * 300);

			entity _body = vehicle_tossgib(self, self.velocity + randomvec() * 200, "", rint(random()), rint(random()), 6, randomvec() * 100);

			if(random() > 0.5)
				_body.touch = bumblebee_blowup;
			else
				_body.touch = func_null;

			_body.think = bumblebee_diethink;
			_body.nextthink = time;
			_body.wait = time + 2 + (random() * 8);
			_body.owner = self;
			_body.enemy = self.enemy;
			_body.scale = 1.5;
			_body.angles = self.angles;

			Send_Effect(EFFECT_EXPLOSION_MEDIUM, findbetterlocation(self.origin, 16), '0 0 0', 1);

			self.health			= 0;
			self.event_damage	= func_null;
			self.solid			= SOLID_NOT;
			self.takedamage		= DAMAGE_NO;
			self.deadflag		= DEAD_DYING;
			self.movetype		= MOVETYPE_NONE;
			self.effects		= EF_NODRAW;
			self.colormod		= '0 0 0';
			self.avelocity		= '0 0 0';
			self.velocity		= '0 0 0';
			self.touch 			= func_null;
			self.nextthink 		= 0;

			setorigin(self, self.pos1);
			return true;
		}
		case VR_SPAWN:
		{
			if(!self.gun1)
			{
				// for some reason, autosizing of the shield entity refuses to work for this one so set it up in advance.
				self.vehicle_shieldent = spawn();
				self.vehicle_shieldent.effects = EF_LOWPRECISION;
				setmodel(self.vehicle_shieldent, MDL_VEH_BUMBLEBEE_SHIELD);
				setattachment(self.vehicle_shieldent, self, "");
				setorigin(self.vehicle_shieldent, real_origin(self) - self.origin);
				self.vehicle_shieldent.scale       = 512 / vlen(self.maxs - self.mins);
				self.vehicle_shieldent.think       = shieldhit_think;
				self.vehicle_shieldent.alpha = -1;
				self.vehicle_shieldent.effects = EF_LOWPRECISION | EF_NODRAW;

				self.gun1 = spawn();
				self.gun2 = spawn();
				self.gun3 = spawn();

				self.vehicle_flags |= VHF_MULTISLOT;

				self.gun1.owner = self;
				self.gun2.owner = self;
				self.gun3.owner = self;

				self.gun1.classname = self.gun2.classname = "vehicle_playerslot";

				setmodel(self.gun1, MDL_VEH_BUMBLEBEE_CANNON_RIGHT);
				setmodel(self.gun2, MDL_VEH_BUMBLEBEE_CANNON_LEFT);
				setmodel(self.gun3, MDL_VEH_BUMBLEBEE_CANNON_CENTER);

				setattachment(self.gun1, self, "cannon_right");
				setattachment(self.gun2, self, "cannon_left");

				// Angled bones are no fun, messes up gun-aim; so work arround it.
				self.gun3.pos1 = self.angles;
				self.angles = '0 0 0';
				vector ofs = gettaginfo(self, gettagindex(self, "raygun"));
				ofs -= self.origin;
				setattachment(self.gun3, self, "");
				setorigin(self.gun3, ofs);
				self.angles = self.gun3.pos1;

				vehicle_addplayerslot(self, self.gun1, HUD_BUMBLEBEE_GUN, "models/vehicles/wakizashi_cockpit.dpm", bumblebee_gunner_frame, bumblebee_gunner_exit, bumblebee_gunner_enter);
				vehicle_addplayerslot(self, self.gun2, HUD_BUMBLEBEE_GUN, "models/vehicles/wakizashi_cockpit.dpm", bumblebee_gunner_frame, bumblebee_gunner_exit, bumblebee_gunner_enter);

				setorigin(self.vehicle_hudmodel, '50 0 -5');    // Move cockpit forward - down.
				setorigin(self.vehicle_viewport, '5 0 2');    // Move camera forward up

				//fixme-model-bones
				setorigin(self.gun1.vehicle_hudmodel, '90 -27 -23');
				setorigin(self.gun1.vehicle_viewport, '-85 0 50');
				//fixme-model-bones
				setorigin(self.gun2.vehicle_hudmodel, '90 27 -23');
				setorigin(self.gun2.vehicle_viewport, '-85 0 50');

				self.scale = 1.5;

				// Raygun beam
				if(self.gun3.enemy == world)
				{
					self.gun3.enemy = spawn();
					Net_LinkEntity(self.gun3.enemy, true, 0, bumble_raygun_send);
					self.gun3.enemy.SendFlags = BRG_SETUP;
					self.gun3.enemy.cnt = autocvar_g_vehicle_bumblebee_raygun;
					self.gun3.enemy.effects = EF_NODRAW | EF_LOWPRECISION;
				}
			}

			self.vehicle_health = autocvar_g_vehicle_bumblebee_health;
			self.vehicle_shield = autocvar_g_vehicle_bumblebee_shield;
			self.solid = SOLID_BBOX;
			self.movetype = MOVETYPE_TOSS;
			self.damageforcescale = 0.025;

			self.PlayerPhysplug = bumblebee_pilot_frame;

			setorigin(self, self.origin + '0 0 25');
			return true;
		}
		case VR_SETUP:
		{
			if(autocvar_g_vehicle_bumblebee_energy)
			if(autocvar_g_vehicle_bumblebee_energy_regen)
				self.vehicle_flags |= VHF_ENERGYREGEN;

			if(autocvar_g_vehicle_bumblebee_shield)
				self.vehicle_flags |= VHF_HASSHIELD;

			if(autocvar_g_vehicle_bumblebee_shield_regen)
				self.vehicle_flags |= VHF_SHIELDREGEN;

			if(autocvar_g_vehicle_bumblebee_health_regen)
				self.vehicle_flags |= VHF_HEALTHREGEN;

			self.vehicle_exit = bumblebee_exit;
			self.respawntime = autocvar_g_vehicle_bumblebee_respawntime;
			self.vehicle_health = autocvar_g_vehicle_bumblebee_health;
			self.max_health = self.vehicle_health;
			self.vehicle_shield = autocvar_g_vehicle_bumblebee_shield;

			return true;
		}
		case VR_PRECACHE:
		{
			return true;
		}
	}

	return true;
}

#endif // SVQC
#ifdef CSQC

void CSQC_BUMBLE_GUN_HUD()
{
	Vehicles_drawHUD("vehicle_gunner", "vehicle_gunner_weapon1", string_null,
					 "vehicle_icon_ammo1", autocvar_hud_progressbar_vehicles_ammo1_color,
					 string_null, '0 0 0',
					 string_null);
}

void bumble_raygun_draw()
{SELFPARAM();
	float _len;
	vector _dir;
	vector _vtmp1, _vtmp2;

	_len = vlen(self.origin - self.move_origin);
	_dir = normalize(self.move_origin - self.origin);

	if(self.total_damages < time)
	{
		boxparticles(self.traileffect, self, self.origin, self.origin + _dir * -64, _dir * -_len , _dir * -_len, 1, PARTICLES_USEALPHA);
		boxparticles(self.lip, self, self.move_origin, self.move_origin + _dir * -64, _dir * -200 , _dir * -200, 1, PARTICLES_USEALPHA);
		self.total_damages = time + 0.1;
	}

	float i, df, sz, al;
	for(i = -0.1; i < 0.2; i += 0.1)
	{
		df = DRAWFLAG_NORMAL; //((random() < 0.5) ? DRAWFLAG_ADDITIVE : DRAWFLAG_SCREEN);
		sz = 5 + random() * 5;
		al = 0.25 + random() * 0.5;
		_vtmp1 = self.origin + _dir * _len * (0.25 + i);
		_vtmp1 += (randomvec() * (_len * 0.2) * (frametime * 2));       //self.raygun_l1;
		Draw_CylindricLine(self.origin, _vtmp1, sz, "gfx/colors/white.tga", 1, 1, self.colormod, al, df, view_origin);

		_vtmp2 = self.origin + _dir * _len * (0.5 + i);
		_vtmp2 += (randomvec() * (_len * 0.2) * (frametime * 5));       //self.raygun_l2;
		Draw_CylindricLine(_vtmp1, _vtmp2, sz, "gfx/colors/white.tga", 1, 1, self.colormod, al, df, view_origin);

		_vtmp1 = self.origin + _dir * _len * (0.75 + i);
		_vtmp1 += randomvec() * (_len * 0.2) * (frametime * 10);     //self.raygun_l3;
		Draw_CylindricLine(_vtmp2, _vtmp1, sz, "gfx/colors/white.tga", 1, 1, self.colormod, al, df, view_origin);

		Draw_CylindricLine(_vtmp1, self.move_origin +  randomvec() * 32, sz, "gfx/colors/white.tga", 1, 1, self.colormod, al, df, view_origin);
	}
}

void bumble_raygun_read(bool bIsNew)
{SELFPARAM();
	int sf = ReadByte();

	if(sf & BRG_SETUP)
	{
		self.cnt  = ReadByte();
		self.team = ReadByte();
		self.cnt  = ReadByte();

		if(self.cnt)
			self.colormod = '1 0 0';
		else
			self.colormod = '0 1 0';

		self.traileffect = particleeffectnum(EFFECT_BUMBLEBEE_HEAL_MUZZLEFLASH);
		self.lip = particleeffectnum(EFFECT_BUMBLEBEE_HEAL_IMPACT);

		self.draw = bumble_raygun_draw;
	}


	if(sf & BRG_START)
	{
		self.origin_x = ReadCoord();
		self.origin_y = ReadCoord();
		self.origin_z = ReadCoord();
		setorigin(self, self.origin);
	}

	if(sf & BRG_END)
	{
		self.move_origin_x = ReadCoord();
		self.move_origin_y = ReadCoord();
		self.move_origin_z = ReadCoord();
	}
}

float v_bumblebee(float req)
{
	switch(req)
	{
		case VR_HUD:
		{
			Vehicles_drawHUD(VEH_BUMBLEBEE.m_icon, "vehicle_bumble_weapon1", "vehicle_bumble_weapon2",
							 "vehicle_icon_ammo1", autocvar_hud_progressbar_vehicles_ammo1_color,
							 "vehicle_icon_ammo1", autocvar_hud_progressbar_vehicles_ammo1_color,
							 vCROSS_HEAL);
			return true;
		}
		case VR_SETUP:
		{
			AuxiliaryXhair[0].axh_image = vCROSS_LOCK;  // Raygun-locked
			AuxiliaryXhair[1].axh_image = vCROSS_BURST; // Gunner1
			AuxiliaryXhair[2].axh_image = vCROSS_BURST; // Gunner2
			return true;
		}
		case VR_PRECACHE:
		{
			return true;
		}
	}

	return true;
}

#endif // CSQC
#endif // REGISTER_VEHICLE
