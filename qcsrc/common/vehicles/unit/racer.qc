#ifndef VEHICLE_RACER
#define VEHICLE_RACER
#ifndef MENUQC
int v_racer(int);
#endif
REGISTER_VEHICLE_SIMPLE(
/* VEH_##id   */ RACER,
/* spawnflags */ VHF_DMGSHAKE | VHF_DMGROLL,
/* mins,maxs  */ '-120 -120 -40' * 0.5, '120 120 40' * 0.5,
/* model	  */ "models/vehicles/wakizashi.dpm",
/* head_model */ "null",
/* hud_model  */ "models/vehicles/wakizashi_cockpit.dpm",
/* tags	   	  */ "", "", "tag_viewport",
/* netname	  */ "racer",
/* fullname   */ _("Racer")
) {
    this.m_icon = "vehicle_racer";
#ifndef MENUQC
    this.vehicle_func = v_racer;
#endif
}
#endif

#ifdef IMPLEMENTATION
#ifdef SVQC
#include "../../effects.qh"
#include "../../triggers/trigger/impulse.qh"

bool autocvar_g_vehicle_racer;

float autocvar_g_vehicle_racer_speed_afterburn;
float autocvar_g_vehicle_racer_afterburn_cost;

float autocvar_g_vehicle_racer_waterburn_cost;
float autocvar_g_vehicle_racer_waterburn_speed;

float autocvar_g_vehicle_racer_water_speed_forward;
float autocvar_g_vehicle_racer_water_speed_strafe;

float autocvar_g_vehicle_racer_pitchlimit = 30;

float autocvar_g_vehicle_racer_water_downforce = 0.03;
float autocvar_g_vehicle_racer_water_upforcedamper = 15;

float autocvar_g_vehicle_racer_anglestabilizer;
float autocvar_g_vehicle_racer_downforce;

float autocvar_g_vehicle_racer_speed_forward;
float autocvar_g_vehicle_racer_speed_strafe;
float autocvar_g_vehicle_racer_springlength;
float autocvar_g_vehicle_racer_upforcedamper;
float autocvar_g_vehicle_racer_friction;

float autocvar_g_vehicle_racer_water_time = 5;

float autocvar_g_vehicle_racer_hovertype;
float autocvar_g_vehicle_racer_hoverpower;

float autocvar_g_vehicle_racer_turnroll;
float autocvar_g_vehicle_racer_turnspeed;
float autocvar_g_vehicle_racer_pitchspeed;

float autocvar_g_vehicle_racer_energy;
float autocvar_g_vehicle_racer_energy_regen;
float autocvar_g_vehicle_racer_energy_regen_pause;

float autocvar_g_vehicle_racer_health;
float autocvar_g_vehicle_racer_health_regen;
float autocvar_g_vehicle_racer_health_regen_pause;

float autocvar_g_vehicle_racer_shield;
float autocvar_g_vehicle_racer_shield_regen;
float autocvar_g_vehicle_racer_shield_regen_pause;

float autocvar_g_vehicle_racer_cannon_cost;
float autocvar_g_vehicle_racer_cannon_damage;
float autocvar_g_vehicle_racer_cannon_radius;
float autocvar_g_vehicle_racer_cannon_refire;
float autocvar_g_vehicle_racer_cannon_speed;
float autocvar_g_vehicle_racer_cannon_spread;
float autocvar_g_vehicle_racer_cannon_force;

float autocvar_g_vehicle_racer_rocket_accel;
float autocvar_g_vehicle_racer_rocket_damage;
float autocvar_g_vehicle_racer_rocket_radius;
float autocvar_g_vehicle_racer_rocket_force;
float autocvar_g_vehicle_racer_rocket_refire;
float autocvar_g_vehicle_racer_rocket_speed;
float autocvar_g_vehicle_racer_rocket_turnrate;

float autocvar_g_vehicle_racer_rocket_locktarget;
float autocvar_g_vehicle_racer_rocket_locking_time;
float autocvar_g_vehicle_racer_rocket_locking_releasetime;
float autocvar_g_vehicle_racer_rocket_locked_time;
float autocvar_g_vehicle_racer_rocket_locked_maxangle;
float autocvar_g_vehicle_racer_rocket_climbspeed;

float autocvar_g_vehicle_racer_respawntime;

float autocvar_g_vehicle_racer_blowup_radius;
float autocvar_g_vehicle_racer_blowup_coredamage;
float autocvar_g_vehicle_racer_blowup_edgedamage;
float autocvar_g_vehicle_racer_blowup_forceintensity;

float autocvar_g_vehicle_racer_bouncefactor;
float autocvar_g_vehicle_racer_bouncestop;
vector autocvar_g_vehicle_racer_bouncepain;

.float racer_watertime;

var vector racer_force_from_tag(string tag_name, float spring_length, float max_power);

void racer_align4point(float _delta)
{
	vector push_vector;
	float fl_push, fr_push, bl_push, br_push;

	push_vector  = racer_force_from_tag("tag_engine_fr", autocvar_g_vehicle_racer_springlength, autocvar_g_vehicle_racer_hoverpower);
	fr_push	  = force_fromtag_normpower;
	//vehicles_sweap_collision(force_fromtag_origin, self.velocity, _delta, v_add, autocvar_g_vehicle_racer_collision_multiplier);

	push_vector += racer_force_from_tag("tag_engine_fl", autocvar_g_vehicle_racer_springlength, autocvar_g_vehicle_racer_hoverpower);
	fl_push	  = force_fromtag_normpower;
	//vehicles_sweap_collision(force_fromtag_origin, self.velocity, _delta, v_add, autocvar_g_vehicle_racer_collision_multiplier);

	push_vector += racer_force_from_tag("tag_engine_br", autocvar_g_vehicle_racer_springlength, autocvar_g_vehicle_racer_hoverpower);
	br_push	  = force_fromtag_normpower;
	//vehicles_sweap_collision(force_fromtag_origin, self.velocity, _delta, v_add, autocvar_g_vehicle_racer_collision_multiplier);

	push_vector += racer_force_from_tag("tag_engine_bl", autocvar_g_vehicle_racer_springlength, autocvar_g_vehicle_racer_hoverpower);
	bl_push	  = force_fromtag_normpower;
	//vehicles_sweap_collision(force_fromtag_origin, self.velocity, _delta, v_add, autocvar_g_vehicle_racer_collision_multiplier);

	self.velocity += push_vector * _delta;

	float uforce = autocvar_g_vehicle_racer_upforcedamper;

	int cont = pointcontents(self.origin - '0 0 64');
	if(cont == CONTENT_WATER || cont == CONTENT_LAVA || cont == CONTENT_SLIME)
	{
		uforce = autocvar_g_vehicle_racer_water_upforcedamper;

		if(self.owner.BUTTON_CROUCH && time < self.air_finished)
			self.velocity_z += 30;
		else
			self.velocity_z += 200;
	}


	// Anti ocilation
	if(self.velocity_z > 0)
		self.velocity_z *= 1 - uforce * _delta;

	push_vector_x =  (fl_push - bl_push);
	push_vector_x += (fr_push - br_push);
	push_vector_x *= 360;

	push_vector_z = (fr_push - fl_push);
	push_vector_z += (br_push - bl_push);
	push_vector_z *= 360;

	// Apply angle diffrance
	self.angles_z += push_vector_z * _delta;
	self.angles_x += push_vector_x * _delta;

	// Apply stabilizer
	self.angles_x *= 1 - (autocvar_g_vehicle_racer_anglestabilizer * _delta);
	self.angles_z *= 1 - (autocvar_g_vehicle_racer_anglestabilizer * _delta);
}

void racer_fire_cannon(string tagname)
{
	vector v;
	entity bolt;

	v = gettaginfo(self, gettagindex(self, tagname));
	bolt = vehicles_projectile("wakizashi_gun_muzzleflash", "weapons/lasergun_fire.wav",
						   v, normalize(v_forward + randomvec() * autocvar_g_vehicle_racer_cannon_spread) * autocvar_g_vehicle_racer_cannon_speed,
						   autocvar_g_vehicle_racer_cannon_damage, autocvar_g_vehicle_racer_cannon_radius, autocvar_g_vehicle_racer_cannon_force,  0,
						   DEATH_VH_WAKI_GUN, PROJECTILE_WAKICANNON, 0, true, true, self.owner);

	// Fix z-aim (for chase mode)
	v = normalize(trace_endpos - bolt.origin);
	v_forward_z = v_z * 0.5;
	bolt.velocity = v_forward * autocvar_g_vehicle_racer_cannon_speed;
}

void racer_rocket_groundhugger()
{
	vector olddir, newdir;
	float oldvel, newvel;

	self.nextthink  = time;

	if(self.owner.deadflag != DEAD_NO || self.cnt < time)
	{
		self.use();
		return;
	}

	if(!self.realowner.vehicle)
	{
		UpdateCSQCProjectile(self);
		return;
	}

	olddir = normalize(self.velocity);
	oldvel = vlen(self.velocity);
	newvel = oldvel + self.lip;

	tracebox(self.origin, self.mins, self.maxs, self.origin + olddir * 64, MOVE_WORLDONLY,self);
	if(trace_fraction <= 0.5)
	{
		// Hitting somethign soon, just speed ahead
		self.velocity = olddir * newvel;
		UpdateCSQCProjectile(self);
		return;
	}

	traceline(trace_endpos, trace_endpos - '0 0 64', MOVE_NORMAL, self);
	if(trace_fraction != 1.0)
	{
		newdir = normalize(trace_endpos + '0 0 64' - self.origin) * autocvar_g_vehicle_racer_rocket_turnrate;
		self.velocity = normalize(olddir + newdir) * newvel;
	}
	else
	{
		self.velocity = olddir * newvel;
		self.velocity_z -= 1600 * sys_frametime; // 2x grav looks better for this one
	}

	int cont = pointcontents(self.origin - '0 0 32');
	if(cont == CONTENT_WATER || cont == CONTENT_LAVA || cont == CONTENT_SLIME)
		self.velocity_z += 200;

	UpdateCSQCProjectile(self);
	return;
}

void racer_rocket_tracker()
{
	vector olddir, newdir;
	float oldvel, newvel;

	self.nextthink  = time;

	if (self.owner.deadflag != DEAD_NO || self.cnt < time)
	{
		self.use();
		return;
	}

	if(!self.realowner.vehicle)
	{
		UpdateCSQCProjectile(self);
		return;
	}

	olddir = normalize(self.velocity);
	oldvel = vlen(self.velocity);
	newvel = oldvel + self.lip;
	makevectors(vectoangles(olddir));

	float time_to_impact = min(vlen(self.enemy.origin - self.origin) / vlen(self.velocity), 1);
	vector predicted_origin = self.enemy.origin + self.enemy.velocity * time_to_impact;

	traceline(self.origin, self.origin + v_forward * 64 - '0 0 32', MOVE_NORMAL, self);
	newdir = normalize(predicted_origin - self.origin);

	//vector
	float height_diff = predicted_origin_z - self.origin_z;

	if(vlen(newdir - v_forward) > autocvar_g_vehicle_racer_rocket_locked_maxangle)
	{
		//bprint("Target lost!\n");
		//dprint("OF:", ftos(vlen(newdir - v_forward)), "\n");
		self.think = racer_rocket_groundhugger;
		return;
	}

	if(trace_fraction != 1.0 && trace_ent != self.enemy)
		newdir_z += 16 * sys_frametime;

	self.velocity = normalize(olddir + newdir * autocvar_g_vehicle_racer_rocket_turnrate) * newvel;
	self.velocity_z -= 800 * sys_frametime;
	self.velocity_z += max(height_diff, autocvar_g_vehicle_racer_rocket_climbspeed) * sys_frametime ;

	UpdateCSQCProjectile(self);
	return;
}

void racer_fire_rocket(string tagname, entity trg)
{
	vector v = gettaginfo(self, gettagindex(self, tagname));
	entity rocket = vehicles_projectile("wakizashi_rocket_launch", "weapons/rocket_fire.wav",
						   v, v_forward * autocvar_g_vehicle_racer_rocket_speed,
						   autocvar_g_vehicle_racer_rocket_damage, autocvar_g_vehicle_racer_rocket_radius, autocvar_g_vehicle_racer_rocket_force, 3,
						   DEATH_VH_WAKI_ROCKET, PROJECTILE_WAKIROCKET, 20, false, false, self.owner);

	rocket.lip			  = autocvar_g_vehicle_racer_rocket_accel * sys_frametime;
	rocket.wait			 = autocvar_g_vehicle_racer_rocket_turnrate;
	rocket.nextthink		= time;
	rocket.enemy			= trg;
	rocket.cnt			  = time + 15;

	if(trg)
		rocket.think			= racer_rocket_tracker;
	else
		rocket.think			= racer_rocket_groundhugger;
}

float racer_frame()
{
	entity player, racer;
	vector df;
	float ftmp;

	if(intermission_running)
	{
		self.vehicle.velocity = '0 0 0';
		self.vehicle.avelocity = '0 0 0';
		return 1;
	}

	player  = self;
	racer   = self.vehicle;
	self	= racer;

	vehicles_painframe();

	if(pointcontents(racer.origin) != CONTENT_WATER)
		racer.air_finished = time + autocvar_g_vehicle_racer_water_time;

	if(racer.deadflag != DEAD_NO)
	{
		self = player;
		player.BUTTON_ATCK = player.BUTTON_ATCK2 = 0;
		return 1;
	}

	racer_align4point(PHYS_INPUT_TIMELENGTH);

	player.BUTTON_ZOOM = player.BUTTON_CROUCH = 0;

	crosshair_trace(player);

	racer.angles_x *= -1;

	// Yaw
	ftmp = autocvar_g_vehicle_racer_turnspeed * PHYS_INPUT_TIMELENGTH;
	ftmp = bound(-ftmp, shortangle_f(player.v_angle_y - racer.angles_y, racer.angles_y), ftmp);
	racer.angles_y = anglemods(racer.angles_y + ftmp);

	// Roll
	racer.angles_z += -ftmp * autocvar_g_vehicle_racer_turnroll * PHYS_INPUT_TIMELENGTH;

	// Pitch
	ftmp = autocvar_g_vehicle_racer_pitchspeed  * PHYS_INPUT_TIMELENGTH;
	ftmp = bound(-ftmp, shortangle_f(player.v_angle_x - racer.angles_x, racer.angles_x), ftmp);
	racer.angles_x = bound(-autocvar_g_vehicle_racer_pitchlimit, anglemods(racer.angles_x + ftmp), autocvar_g_vehicle_racer_pitchlimit);

	makevectors(racer.angles);
	racer.angles_x *= -1;

	//ftmp = racer.velocity_z;
	df = racer.velocity * -autocvar_g_vehicle_racer_friction;
	//racer.velocity_z = ftmp;

	int cont = pointcontents(racer.origin);
	if(vlen(player.movement) != 0)
	{
		if(cont == CONTENT_WATER || cont == CONTENT_LAVA || cont == CONTENT_SLIME)
		{
			if(player.movement_x) { df += v_forward * ((player.movement_x > 0) ? autocvar_g_vehicle_racer_water_speed_forward : -autocvar_g_vehicle_racer_water_speed_forward); }
			if(player.movement_y) { df += v_right * ((player.movement_y > 0) ? autocvar_g_vehicle_racer_water_speed_strafe : -autocvar_g_vehicle_racer_water_speed_strafe); }
		}
		else
		{
			if(player.movement_x) { df += v_forward * ((player.movement_x > 0) ? autocvar_g_vehicle_racer_speed_forward : -autocvar_g_vehicle_racer_speed_forward); }
			if(player.movement_y) { df += v_right * ((player.movement_y > 0) ? autocvar_g_vehicle_racer_speed_strafe : -autocvar_g_vehicle_racer_speed_strafe); }
		}

#ifdef SVQC
		if(self.sound_nexttime < time || self.sounds != 1)
		{
			self.sounds = 1;
			self.sound_nexttime = time + 10.922667; //soundlength("vehicles/racer_move.wav");
			sound (self, CH_TRIGGER_SINGLE, "vehicles/racer_move.wav", VOL_VEHICLEENGINE, ATTEN_NORM);
		}
#endif
	}
#ifdef SVQC
	else
	{
		if(self.sound_nexttime < time || self.sounds != 0)
		{
			self.sounds = 0;
			self.sound_nexttime = time + 11.888604; //soundlength("vehicles/racer_idle.wav");
			sound (self, CH_TRIGGER_SINGLE, "vehicles/racer_idle.wav", VOL_VEHICLEENGINE, ATTEN_NORM);
		}
	}
#endif

	// Afterburn
	if (PHYS_INPUT_BUTTON_JUMP(player) && racer.vehicle_energy >= (autocvar_g_vehicle_racer_afterburn_cost * PHYS_INPUT_TIMELENGTH))
	{
#ifdef SVQC
		if(time - racer.wait > 0.2)
			pointparticles(particleeffectnum("wakizashi_booster_smoke"), self.origin - v_forward * 32, v_forward  * vlen(self.velocity), 1);
#endif

		racer.wait = time;

		if(cont == CONTENT_WATER || cont == CONTENT_LAVA || cont == CONTENT_SLIME)
		{
			racer.vehicle_energy -= autocvar_g_vehicle_racer_waterburn_cost * PHYS_INPUT_TIMELENGTH;
			df += (v_forward * autocvar_g_vehicle_racer_waterburn_speed);
		}
		else
		{
			racer.vehicle_energy -= autocvar_g_vehicle_racer_afterburn_cost * PHYS_INPUT_TIMELENGTH;
			df += (v_forward * autocvar_g_vehicle_racer_speed_afterburn);
		}

#ifdef SVQC
		if(racer.invincible_finished < time)
		{
			traceline(racer.origin, racer.origin - '0 0 256', MOVE_NORMAL, self);
			if(trace_fraction != 1.0)
				pointparticles(particleeffectnum("smoke_small"), trace_endpos, '0 0 0', 1);

			racer.invincible_finished = time + 0.1 + (random() * 0.1);
		}

		if(racer.strength_finished < time)
		{
			racer.strength_finished = time + 10.922667; //soundlength("vehicles/racer_boost.wav");
			sound (racer.tur_head, CH_TRIGGER_SINGLE, "vehicles/racer_boost.wav", VOL_VEHICLEENGINE, ATTEN_NORM);
		}
#endif
	}
	else
	{
		racer.strength_finished = 0;
		sound (racer.tur_head, CH_TRIGGER_SINGLE, "misc/null.wav", VOL_VEHICLEENGINE, ATTEN_NORM);
	}

	if(cont == CONTENT_WATER || cont == CONTENT_LAVA || cont == CONTENT_SLIME)
		racer.racer_watertime = time;

	float dforce = autocvar_g_vehicle_racer_downforce;
	if(time - racer.racer_watertime <= 3)
		dforce = autocvar_g_vehicle_racer_water_downforce;

	df -= v_up * (vlen(racer.velocity) * dforce);
	player.movement = racer.velocity += df * PHYS_INPUT_TIMELENGTH;

#ifdef SVQC
	if(!forbidWeaponUse(player))
	if(player.BUTTON_ATCK)
	if(time > racer.attack_finished_single)
	if(racer.vehicle_energy >= autocvar_g_vehicle_racer_cannon_cost)
	{
		racer.vehicle_energy -= autocvar_g_vehicle_racer_cannon_cost;
		racer.wait = time;

		crosshair_trace(player);
		if(racer.cnt)
		{
			racer_fire_cannon("tag_fire1");
			racer.cnt = 0;
		}
		else
		{
			racer_fire_cannon("tag_fire2");
			racer.cnt = 1;
		}
		racer.attack_finished_single = time + autocvar_g_vehicle_racer_cannon_refire;
	}

	if(autocvar_g_vehicle_racer_rocket_locktarget)
	{
		vehicles_locktarget((1 / autocvar_g_vehicle_racer_rocket_locking_time) * frametime,
						 (1 / autocvar_g_vehicle_racer_rocket_locking_releasetime) * frametime,
						 autocvar_g_vehicle_racer_rocket_locked_time);

		if(self.lock_target)
		{
			if(racer.lock_strength == 1)
				UpdateAuxiliaryXhair(player, real_origin(self.lock_target), '1 0 0', 0);
			else if(self.lock_strength > 0.5)
				UpdateAuxiliaryXhair(player, real_origin(self.lock_target), '0 1 0', 0);
			else if(self.lock_strength < 0.5)
				UpdateAuxiliaryXhair(player, real_origin(self.lock_target), '0 0 1', 0);
		}
	}

	if(!forbidWeaponUse(player))
	if(time > racer.delay)
	if(player.BUTTON_ATCK2)
	{
		racer.misc_bulletcounter += 1;
		racer.delay = time + 0.3;

		if(racer.misc_bulletcounter == 1)
		{
			racer_fire_rocket("tag_rocket_r", (racer.lock_strength == 1 && racer.lock_target) ? racer.lock_target : world);
			player.vehicle_ammo2 = 50;
		}
		else if(racer.misc_bulletcounter == 2)
		{
			racer_fire_rocket("tag_rocket_l", (racer.lock_strength == 1 && racer.lock_target) ? racer.lock_target : world);
			racer.lock_strength  = 0;
			racer.lock_target	= world;
			racer.misc_bulletcounter = 0;
			racer.delay = time + autocvar_g_vehicle_racer_rocket_refire;
			racer.lip = time;
			player.vehicle_ammo2 = 0;
		}
	}
	else if(racer.misc_bulletcounter == 0)
		player.vehicle_ammo2 = 100;

	player.vehicle_reload2 = bound(0, 100 * ((time - racer.lip) / (racer.delay - racer.lip)), 100);

	if(racer.vehicle_flags  & VHF_SHIELDREGEN)
		vehicles_regen(racer.dmg_time, vehicle_shield, autocvar_g_vehicle_racer_shield, autocvar_g_vehicle_racer_shield_regen_pause, autocvar_g_vehicle_racer_shield_regen, frametime, true);

	if(racer.vehicle_flags  & VHF_HEALTHREGEN)
		vehicles_regen(racer.dmg_time, vehicle_health, autocvar_g_vehicle_racer_health, autocvar_g_vehicle_racer_health_regen_pause, autocvar_g_vehicle_racer_health_regen, frametime, false);

	if(racer.vehicle_flags  & VHF_ENERGYREGEN)
		vehicles_regen(racer.wait, vehicle_energy, autocvar_g_vehicle_racer_energy, autocvar_g_vehicle_racer_energy_regen_pause, autocvar_g_vehicle_racer_energy_regen, frametime, false);


	VEHICLE_UPDATE_PLAYER(player, health, racer);
	VEHICLE_UPDATE_PLAYER(player, energy, racer);

	if(racer.vehicle_flags & VHF_HASSHIELD)
		VEHICLE_UPDATE_PLAYER(player, shield, racer);

	player.BUTTON_ATCK = player.BUTTON_ATCK2 = 0;
#endif

	setorigin(player,racer.origin + '0 0 32');
	player.velocity = racer.velocity;

	self = player;
	return 1;
}

void racer_think()
{
	self.nextthink = time;

	float pushdeltatime = time - self.lastpushtime;
	if (pushdeltatime > 0.15) pushdeltatime = 0;
	self.lastpushtime = time;
	if(!pushdeltatime) return;

	tracebox(self.origin, self.mins, self.maxs, self.origin - ('0 0 1' * autocvar_g_vehicle_racer_springlength), MOVE_NOMONSTERS, self);

	vector df = self.velocity * -autocvar_g_vehicle_racer_friction;
	df_z += (1 - trace_fraction) * autocvar_g_vehicle_racer_hoverpower + sin(time * 2) * (autocvar_g_vehicle_racer_springlength * 2);

	float forced = autocvar_g_vehicle_racer_upforcedamper;

	int cont = pointcontents(self.origin - '0 0 64');
	if(cont == CONTENT_WATER || cont == CONTENT_LAVA || cont == CONTENT_SLIME)
	{
		forced = autocvar_g_vehicle_racer_water_upforcedamper;
		self.velocity_z += 200;
	}

	self.velocity += df * pushdeltatime;
	if(self.velocity_z > 0)
		self.velocity_z *= 1 - forced * pushdeltatime;

	self.angles_x *= 1 - (autocvar_g_vehicle_racer_anglestabilizer * pushdeltatime);
	self.angles_z *= 1 - (autocvar_g_vehicle_racer_anglestabilizer * pushdeltatime);

	CSQCMODEL_AUTOUPDATE();
}

void racer_exit(float eject)
{
	vector spot;

	self.think	  = racer_think;
	self.nextthink  = time;
	self.movetype   = MOVETYPE_BOUNCE;
	sound (self.tur_head, CH_TRIGGER_SINGLE, "misc/null.wav", VOL_VEHICLEENGINE, ATTEN_NORM);

	if(!self.owner)
		return;

	makevectors(self.angles);
	if(eject)
	{
		spot = self.origin + v_forward * 100 + '0 0 64';
		spot = vehicles_findgoodexit(spot);
		setorigin(self.owner , spot);
		self.owner.velocity = (v_up + v_forward * 0.25) * 750;
		self.owner.oldvelocity = self.owner.velocity;
	}
	else
	{
		if(vlen(self.velocity) > 2 * autocvar_sv_maxairspeed)
		{
			self.owner.velocity = normalize(self.velocity) * autocvar_sv_maxairspeed * 2;
			self.owner.velocity_z += 200;
			spot = self.origin + v_forward * 32 + '0 0 32';
			spot = vehicles_findgoodexit(spot);
		}
		else
		{
			self.owner.velocity = self.velocity * 0.5;
			self.owner.velocity_z += 10;
			spot = self.origin - v_forward * 200 + '0 0 32';
			spot = vehicles_findgoodexit(spot);
		}
		self.owner.oldvelocity = self.owner.velocity;
		setorigin(self.owner , spot);
	}
	antilag_clear(self.owner);
	self.owner = world;
}

void racer_blowup()
{
	self.deadflag	= DEAD_DEAD;
	self.vehicle_exit(VHEF_NORMAL);

	RadiusDamage (self, self.enemy, autocvar_g_vehicle_racer_blowup_coredamage,
					autocvar_g_vehicle_racer_blowup_edgedamage,
					autocvar_g_vehicle_racer_blowup_radius, world, world,
					autocvar_g_vehicle_racer_blowup_forceintensity,
					DEATH_VH_WAKI_DEATH, world);

	self.nextthink  = time + autocvar_g_vehicle_racer_respawntime;
	self.think	  = vehicles_spawn;
	self.movetype   = MOVETYPE_NONE;
	self.effects	= EF_NODRAW;

	self.colormod  = '0 0 0';
	self.avelocity = '0 0 0';
	self.velocity  = '0 0 0';

	setorigin(self, self.pos1);
}

void racer_blowup_think()
{
	self.nextthink = time;

	if(time >= self.delay)
		racer_blowup();

	CSQCMODEL_AUTOUPDATE();
}

void racer_deadtouch()
{
	self.avelocity_x *= 0.7;
	self.cnt -= 1;
	if(self.cnt <= 0)
		racer_blowup();
}

void spawnfunc_vehicle_racer()
{
	if(!autocvar_g_vehicle_racer) { remove(self); return; }
	if(!vehicle_initialize(VEH_RACER, false)) { remove(self); return; }
}

#endif // SVQC

#ifdef CSQC
#if 0
void racer_draw()
{
	float pushdeltatime = time - self.lastpushtime;
	if (pushdeltatime > 0.15) pushdeltatime = 0;
	self.lastpushtime = time;
	if(!pushdeltatime) return;

	tracebox(self.move_origin, self.mins, self.maxs, self.move_origin - ('0 0 1' * getstatf(STAT_VEH_RACER_SPRINGLENGTH)), MOVE_NOMONSTERS, self);

	vector df = self.move_velocity * -getstatf(STAT_VEH_RACER_FRICTION);
	df_z += (1 - trace_fraction) * getstatf(STAT_VEH_RACER_HOVERPOWER) + sin(time * 2) * (getstatf(STAT_VEH_RACER_SPRINGLENGTH) * 2);

	float forced = getstatf(STAT_VEH_RACER_UPFORCEDAMPER);

	int cont = pointcontents(self.move_origin - '0 0 64');
	if(cont == CONTENT_WATER || cont == CONTENT_LAVA || cont == CONTENT_SLIME)
	{
		forced = getstatf(STAT_VEH_RACER_WATER_UPFORCEDAMPER);
		self.move_velocity_z += 200;
	}

	self.move_velocity += df * pushdeltatime;
	if(self.move_velocity_z > 0)
		self.move_velocity_z *= 1 - forced * pushdeltatime;

	self.move_angles_x *= 1 - (getstatf(STAT_VEH_RACER_ANGLESTABILIZER) * pushdeltatime);
	self.move_angles_z *= 1 - (getstatf(STAT_VEH_RACER_ANGLESTABILIZER) * pushdeltatime);

	Movetype_Physics_MatchServer(false);
}
#endif
#endif

bool v_racer(int req)
{
	switch(req)
	{
		case VR_IMPACT:
		{
		#ifdef SVQC
			if(autocvar_g_vehicle_racer_bouncepain)
				vehicles_impact(autocvar_g_vehicle_racer_bouncepain_x, autocvar_g_vehicle_racer_bouncepain_y, autocvar_g_vehicle_racer_bouncepain_z);
		#endif
			return true;
		}

		case VR_ENTER:
		{
		#ifdef SVQC
			self.movetype = MOVETYPE_BOUNCE;
			self.owner.vehicle_health = (self.vehicle_health / autocvar_g_vehicle_racer_health)  * 100;
			self.owner.vehicle_shield = (self.vehicle_shield / autocvar_g_vehicle_racer_shield)  * 100;

			if(self.owner.flagcarried)
			   setorigin(self.owner.flagcarried, '-190 0 96');
		#elif defined(CSQC)

			self.move_movetype = MOVETYPE_BOUNCE;
		#endif

			return true;
		}

		case VR_SPAWN:
		{
		#ifdef SVQC
			if(self.scale != 0.5)
			{
				if(autocvar_g_vehicle_racer_hovertype != 0)
					racer_force_from_tag = vehicles_force_fromtag_maglev;
				else
					racer_force_from_tag = vehicles_force_fromtag_hover;

				// FIXME: this be hakkz, fix the models insted (scale body, add tag_viewport to the hudmodel).
				self.scale = 0.5;
				setattachment(self.vehicle_hudmodel, self, "");
				setattachment(self.vehicle_viewport, self, "tag_viewport");

				self.mass			   = 900;
			}

			self.think		  = racer_think;
			self.nextthink	  = time;
			self.vehicle_health = autocvar_g_vehicle_racer_health;
			self.vehicle_shield = autocvar_g_vehicle_racer_shield;

			self.movetype	  = MOVETYPE_TOSS;
			self.solid		  = SOLID_SLIDEBOX;
			self.delay		  = time;
			self.scale		  = 0.5;

			self.PlayerPhysplug = racer_frame;

			self.bouncefactor = autocvar_g_vehicle_racer_bouncefactor;
			self.bouncestop = autocvar_g_vehicle_racer_bouncestop;
			self.damageforcescale = 0.5;
			self.vehicle_health = autocvar_g_vehicle_racer_health;
			self.vehicle_shield = autocvar_g_vehicle_racer_shield;
		#endif
			return true;
		}

		case VR_DEATH:
		{
		#ifdef SVQC
			self.SendEntity		= func_null; // stop networking this racer (for now)
			self.health			= 0;
			self.event_damage	= func_null;
			self.solid			= SOLID_CORPSE;
			self.takedamage		= DAMAGE_NO;
			self.deadflag		= DEAD_DYING;
			self.movetype		= MOVETYPE_BOUNCE;
			self.wait			= time;
			self.delay			= 2 + time + random() * 3;
			self.cnt			= 1 + random() * 2;
			self.touch			= racer_deadtouch;

			Send_Effect("explosion_medium", self.origin, '0 0 0', 1);

			if(random() < 0.5)
				self.avelocity_z = 32;
			else
				self.avelocity_z = -32;

			self.avelocity_x = -vlen(self.velocity) * 0.2;
			self.velocity += '0 0 700';
			self.colormod = '-0.5 -0.5 -0.5';

			self.think = racer_blowup_think;
			self.nextthink = time;
		#endif
			return true;
		}

#ifdef CSQC
		case VR_HUD:
		{
			Vehicles_drawHUD(VEH_RACER.m_icon, "vehicle_racer_weapon1", "vehicle_racer_weapon2",
							 "vehicle_icon_ammo1", autocvar_hud_progressbar_vehicles_ammo1_color,
							 "vehicle_icon_ammo2", autocvar_hud_progressbar_vehicles_ammo2_color,
							 vCROSS_GUIDE);
			return true;
		}
#endif
		case VR_SETUP:
		{
		#ifdef SVQC
			self.vehicle_exit = racer_exit;
		#endif

		#ifdef SVQC
			// we have no need to network energy
			if(autocvar_g_vehicle_racer_energy)
			if(autocvar_g_vehicle_racer_energy_regen)
				self.vehicle_flags |= VHF_ENERGYREGEN;

			if(autocvar_g_vehicle_racer_shield)
				self.vehicle_flags |= VHF_HASSHIELD;

			if(autocvar_g_vehicle_racer_shield_regen)
				self.vehicle_flags |= VHF_SHIELDREGEN;

			if(autocvar_g_vehicle_racer_health_regen)
				self.vehicle_flags |= VHF_HEALTHREGEN;

			self.respawntime = autocvar_g_vehicle_racer_respawntime;
			self.vehicle_health = autocvar_g_vehicle_racer_health;
			self.vehicle_shield = autocvar_g_vehicle_racer_shield;
			self.max_health = self.vehicle_health;
		#endif

		#ifdef CSQC
			AuxiliaryXhair[0].axh_image = vCROSS_LOCK; // Rocket
		#endif
			return true;
		}

		case VR_PRECACHE:
		{
		#ifdef SVQC
			precache_sound ("weapons/lasergun_fire.wav");
			precache_sound ("weapons/rocket_fire.wav");

			precache_sound ("vehicles/racer_idle.wav");
			precache_sound ("vehicles/racer_move.wav");
			precache_sound ("vehicles/racer_boost.wav");

			precache_model ("models/vhshield.md3");
		#endif
		#ifndef MENUQC
			precache_model ("models/vehicles/wakizashi.dpm");
			precache_model ("models/vehicles/wakizashi_cockpit.dpm");
		#endif
			return true;
		}
	}

	return true;
}

#endif // REGISTER_VEHICLE
