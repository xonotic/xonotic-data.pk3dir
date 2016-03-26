#ifndef VEHICLE_RACER
#define VEHICLE_RACER

#include "racer_weapon.qh"

CLASS(Racer, Vehicle)
/* spawnflags */ ATTRIB(Racer, spawnflags, int, VHF_DMGSHAKE | VHF_DMGROLL);
/* mins       */ ATTRIB(Racer, mins, vector, '-120 -120 -40' * 0.5);
/* maxs       */ ATTRIB(Racer, maxs, vector, '120 120 40' * 0.5);
/* view offset*/ ATTRIB(Racer, view_ofs, vector, '0 0 50');
/* view dist  */ ATTRIB(Racer, height, float, 200);
/* model	  */ ATTRIB(Racer, mdl, string, "models/vehicles/wakizashi.dpm");
/* model	  */ ATTRIB(Racer, model, string, "models/vehicles/wakizashi.dpm");
/* head_model */ ATTRIB(Racer, head_model, string, "null");
/* hud_model  */ ATTRIB(Racer, hud_model, string, "models/vehicles/wakizashi_cockpit.dpm");
/* tags       */ ATTRIB(Racer, tag_head, string, "");
/* tags       */ ATTRIB(Racer, tag_hud, string, "");
/* tags       */ ATTRIB(Racer, tag_view, string, "tag_viewport");
/* netname    */ ATTRIB(Racer, netname, string, "racer");
/* fullname   */ ATTRIB(Racer, vehicle_name, string, _("Racer"));
/* icon       */ ATTRIB(Racer, m_icon, string, "vehicle_racer");
ENDCLASS(Racer)
REGISTER_VEHICLE(RACER, NEW(Racer));

#endif

#ifdef IMPLEMENTATION

#ifdef SVQC
#include <common/triggers/trigger/impulse.qh>

bool autocvar_g_vehicle_racer = true;

float autocvar_g_vehicle_racer_speed_afterburn = 3000;
// energy consumed per second
float autocvar_g_vehicle_racer_afterburn_cost = 100;

float autocvar_g_vehicle_racer_waterburn_cost = 5;
float autocvar_g_vehicle_racer_waterburn_speed = 750;

float autocvar_g_vehicle_racer_water_speed_forward = 600;
float autocvar_g_vehicle_racer_water_speed_strafe = 600;

float autocvar_g_vehicle_racer_pitchlimit = 30;

float autocvar_g_vehicle_racer_water_downforce = 0.03;
float autocvar_g_vehicle_racer_water_upforcedamper = 15;

float autocvar_g_vehicle_racer_anglestabilizer = 1.75;
float autocvar_g_vehicle_racer_downforce = 0.01;

float autocvar_g_vehicle_racer_speed_forward = 650;
float autocvar_g_vehicle_racer_speed_strafe = 650;
float autocvar_g_vehicle_racer_springlength = 70;
float autocvar_g_vehicle_racer_upforcedamper = 10;
float autocvar_g_vehicle_racer_friction = 0.45;

float autocvar_g_vehicle_racer_water_time = 5;

float autocvar_g_vehicle_racer_collision_multiplier = 0.05;

// 0 = hover, != 0 = maglev
int autocvar_g_vehicle_racer_hovertype = 0;
// NOTE!! x 4 (4 engines)
float autocvar_g_vehicle_racer_hoverpower = 8000;

float autocvar_g_vehicle_racer_turnroll = 30;
float autocvar_g_vehicle_racer_turnspeed = 220;
float autocvar_g_vehicle_racer_pitchspeed = 125;

float autocvar_g_vehicle_racer_energy = 100;
float autocvar_g_vehicle_racer_energy_regen = 50;
float autocvar_g_vehicle_racer_energy_regen_pause = 1;

float autocvar_g_vehicle_racer_health = 200;
float autocvar_g_vehicle_racer_health_regen = 0;
float autocvar_g_vehicle_racer_health_regen_pause = 0;

float autocvar_g_vehicle_racer_shield = 100;
float autocvar_g_vehicle_racer_shield_regen = 30;
float autocvar_g_vehicle_racer_shield_regen_pause = 1;

bool autocvar_g_vehicle_racer_rocket_locktarget = true;
float autocvar_g_vehicle_racer_rocket_locking_time = 0.9;
float autocvar_g_vehicle_racer_rocket_locking_releasetime = 0.5;
float autocvar_g_vehicle_racer_rocket_locked_time = 4;

float autocvar_g_vehicle_racer_respawntime = 35;

float autocvar_g_vehicle_racer_blowup_radius = 250;
float autocvar_g_vehicle_racer_blowup_coredamage = 250;
float autocvar_g_vehicle_racer_blowup_edgedamage = 15;
float autocvar_g_vehicle_racer_blowup_forceintensity = 250;

// Factor of old velocity to keep after collision
float autocvar_g_vehicle_racer_bouncefactor = 0.25;
// if != 0, New veloctiy after bounce = 0 if new velocity < this
float autocvar_g_vehicle_racer_bouncestop = 0;
// "minspeed_for_pain speedchange_to_pain_factor max_damage"
vector autocvar_g_vehicle_racer_bouncepain = '60 0.75 300';

.float racer_watertime;

var vector racer_force_from_tag(entity this, string tag_name, float spring_length, float max_power);

void racer_align4point(entity this, float _delta)
{
	vector push_vector;
	float fl_push, fr_push, bl_push, br_push;

	push_vector  = racer_force_from_tag(this, "tag_engine_fr", autocvar_g_vehicle_racer_springlength, autocvar_g_vehicle_racer_hoverpower);
	fr_push	  = force_fromtag_normpower;
	//vehicles_sweap_collision(force_fromtag_origin, this.velocity, _delta, v_add, autocvar_g_vehicle_racer_collision_multiplier);

	push_vector += racer_force_from_tag(this, "tag_engine_fl", autocvar_g_vehicle_racer_springlength, autocvar_g_vehicle_racer_hoverpower);
	fl_push	  = force_fromtag_normpower;
	//vehicles_sweap_collision(force_fromtag_origin, this.velocity, _delta, v_add, autocvar_g_vehicle_racer_collision_multiplier);

	push_vector += racer_force_from_tag(this, "tag_engine_br", autocvar_g_vehicle_racer_springlength, autocvar_g_vehicle_racer_hoverpower);
	br_push	  = force_fromtag_normpower;
	//vehicles_sweap_collision(force_fromtag_origin, this.velocity, _delta, v_add, autocvar_g_vehicle_racer_collision_multiplier);

	push_vector += racer_force_from_tag(this, "tag_engine_bl", autocvar_g_vehicle_racer_springlength, autocvar_g_vehicle_racer_hoverpower);
	bl_push	  = force_fromtag_normpower;
	//vehicles_sweap_collision(force_fromtag_origin, this.velocity, _delta, v_add, autocvar_g_vehicle_racer_collision_multiplier);

	this.velocity += push_vector * _delta;

	float uforce = autocvar_g_vehicle_racer_upforcedamper;

	int cont = pointcontents(this.origin - '0 0 64');
	if(cont == CONTENT_WATER || cont == CONTENT_LAVA || cont == CONTENT_SLIME)
	{
		uforce = autocvar_g_vehicle_racer_water_upforcedamper;

		if(PHYS_INPUT_BUTTON_CROUCH(this.owner) && time < this.air_finished)
			this.velocity_z += 30;
		else
			this.velocity_z += 200;
	}


	// Anti ocilation
	if(this.velocity_z > 0)
		this.velocity_z *= 1 - uforce * _delta;

	push_vector_x =  (fl_push - bl_push);
	push_vector_x += (fr_push - br_push);
	push_vector_x *= 360;

	push_vector_z = (fr_push - fl_push);
	push_vector_z += (br_push - bl_push);
	push_vector_z *= 360;

	// Apply angle diffrance
	this.angles_z += push_vector_z * _delta;
	this.angles_x += push_vector_x * _delta;

	// Apply stabilizer
	this.angles_x *= 1 - (autocvar_g_vehicle_racer_anglestabilizer * _delta);
	this.angles_z *= 1 - (autocvar_g_vehicle_racer_anglestabilizer * _delta);
}

void racer_fire_rocket_aim(entity player, string tagname, entity trg)
{
	entity racer = player.vehicle;
	vector v = gettaginfo(racer, gettagindex(racer, tagname));
	racer_fire_rocket(player, v, v_forward, trg);
}

bool racer_frame(entity this)
{
	entity vehic = this.vehicle;
	return = true;

	if(intermission_running)
	{
		vehic.velocity = '0 0 0';
		vehic.avelocity = '0 0 0';
		return;
	}

	vehicles_frame(vehic, this);

	if(pointcontents(vehic.origin) != CONTENT_WATER)
		vehic.air_finished = time + autocvar_g_vehicle_racer_water_time;

	if(IS_DEAD(vehic))
	{
		PHYS_INPUT_BUTTON_ATCK(this) = PHYS_INPUT_BUTTON_ATCK2(this) = false;
		return;
	}

	racer_align4point(vehic, PHYS_INPUT_TIMELENGTH);

	PHYS_INPUT_BUTTON_ZOOM(this) = PHYS_INPUT_BUTTON_CROUCH(this) = false;

	//crosshair_trace(this);

	vehic.angles_x *= -1;

	// Yaw
	float ftmp = autocvar_g_vehicle_racer_turnspeed * PHYS_INPUT_TIMELENGTH;
	ftmp = bound(-ftmp, shortangle_f(this.v_angle_y - vehic.angles_y, vehic.angles_y), ftmp);
	vehic.angles_y = anglemods(vehic.angles_y + ftmp);

	// Roll
	vehic.angles_z += -ftmp * autocvar_g_vehicle_racer_turnroll * PHYS_INPUT_TIMELENGTH;

	// Pitch
	ftmp = autocvar_g_vehicle_racer_pitchspeed  * PHYS_INPUT_TIMELENGTH;
	ftmp = bound(-ftmp, shortangle_f(this.v_angle_x - vehic.angles_x, vehic.angles_x), ftmp);
	vehic.angles_x = bound(-autocvar_g_vehicle_racer_pitchlimit, anglemods(vehic.angles_x + ftmp), autocvar_g_vehicle_racer_pitchlimit);

	makevectors(vehic.angles);
	vehic.angles_x *= -1;

	//ftmp = vehic.velocity_z;
	vector df = vehic.velocity * -autocvar_g_vehicle_racer_friction;
	//vehic.velocity_z = ftmp;

	int cont = pointcontents(vehic.origin);
	if(this.movement)
	{
		if(cont == CONTENT_WATER || cont == CONTENT_LAVA || cont == CONTENT_SLIME)
		{
			if(this.movement_x) { df += v_forward * ((this.movement_x > 0) ? autocvar_g_vehicle_racer_water_speed_forward : -autocvar_g_vehicle_racer_water_speed_forward); }
			if(this.movement_y) { df += v_right * ((this.movement_y > 0) ? autocvar_g_vehicle_racer_water_speed_strafe : -autocvar_g_vehicle_racer_water_speed_strafe); }
		}
		else
		{
			if(this.movement_x) { df += v_forward * ((this.movement_x > 0) ? autocvar_g_vehicle_racer_speed_forward : -autocvar_g_vehicle_racer_speed_forward); }
			if(this.movement_y) { df += v_right * ((this.movement_y > 0) ? autocvar_g_vehicle_racer_speed_strafe : -autocvar_g_vehicle_racer_speed_strafe); }
		}

#ifdef SVQC
		if(vehic.sound_nexttime < time || vehic.sounds != 1)
		{
			vehic.sounds = 1;
			vehic.sound_nexttime = time + 10.922667; //soundlength("vehicles/racer_move.wav");
			sound (vehic, CH_TRIGGER_SINGLE, SND_VEH_RACER_MOVE, VOL_VEHICLEENGINE, ATTEN_NORM);
		}
#endif
	}
#ifdef SVQC
	else
	{
		if(vehic.sound_nexttime < time || vehic.sounds != 0)
		{
			vehic.sounds = 0;
			vehic.sound_nexttime = time + 11.888604; //soundlength("vehicles/racer_idle.wav");
			sound (vehic, CH_TRIGGER_SINGLE, SND_VEH_RACER_IDLE, VOL_VEHICLEENGINE, ATTEN_NORM);
		}
	}
#endif

	// Afterburn
	if (PHYS_INPUT_BUTTON_JUMP(this) && vehic.vehicle_energy >= (autocvar_g_vehicle_racer_afterburn_cost * PHYS_INPUT_TIMELENGTH))
	{
#ifdef SVQC
		if(time - vehic.wait > 0.2)
			pointparticles(EFFECT_RACER_BOOSTER, vehic.origin - v_forward * 32, v_forward  * vlen(vehic.velocity), 1);
#endif

		vehic.wait = time;

		if(cont == CONTENT_WATER || cont == CONTENT_LAVA || cont == CONTENT_SLIME)
		{
			vehic.vehicle_energy -= autocvar_g_vehicle_racer_waterburn_cost * PHYS_INPUT_TIMELENGTH;
			df += (v_forward * autocvar_g_vehicle_racer_waterburn_speed);
		}
		else
		{
			vehic.vehicle_energy -= autocvar_g_vehicle_racer_afterburn_cost * PHYS_INPUT_TIMELENGTH;
			df += (v_forward * autocvar_g_vehicle_racer_speed_afterburn);
		}

#ifdef SVQC
		if(vehic.invincible_finished < time)
		{
			traceline(vehic.origin, vehic.origin - '0 0 256', MOVE_NORMAL, vehic);
			if(trace_fraction != 1.0)
				pointparticles(EFFECT_SMOKE_SMALL, trace_endpos, '0 0 0', 1);

			vehic.invincible_finished = time + 0.1 + (random() * 0.1);
		}

		if(vehic.strength_finished < time)
		{
			vehic.strength_finished = time + 10.922667; //soundlength("vehicles/racer_boost.wav");
			sound (vehic.tur_head, CH_TRIGGER_SINGLE, SND_VEH_RACER_BOOST, VOL_VEHICLEENGINE, ATTEN_NORM);
		}
#endif
	}
	else
	{
		vehic.strength_finished = 0;
		sound (vehic.tur_head, CH_TRIGGER_SINGLE, SND_Null, VOL_VEHICLEENGINE, ATTEN_NORM);
	}

	if(cont == CONTENT_WATER || cont == CONTENT_LAVA || cont == CONTENT_SLIME)
		vehic.racer_watertime = time;

	float dforce = autocvar_g_vehicle_racer_downforce;
	if(time - vehic.racer_watertime <= 3)
		dforce = autocvar_g_vehicle_racer_water_downforce;

	df -= v_up * (vlen(vehic.velocity) * dforce);
	this.movement = vehic.velocity += df * PHYS_INPUT_TIMELENGTH;

#ifdef SVQC
	setself(vehic);

	Weapon wep1 = WEP_RACER;
	if (!forbidWeaponUse(this))
	if (PHYS_INPUT_BUTTON_ATCK(this))
	if (wep1.wr_checkammo1(wep1))
	{
		string tagname = (vehic.cnt)
		    ? (vehic.cnt = 0, "tag_fire1")
		    : (vehic.cnt = 1, "tag_fire2");
		vector org = gettaginfo(vehic, gettagindex(vehic, tagname));
		w_shotorg = org;
		w_shotdir = v_forward;
		// Fix z-aim (for chase mode)
		crosshair_trace(this);
		w_shotdir.z = normalize(trace_endpos - org).z * 0.5;
		.entity weaponentity = weaponentities[0];
		wep1.wr_think(wep1, vehic, weaponentity, 1);
	}

	setself(this);

	if(autocvar_g_vehicle_racer_rocket_locktarget)
	{
		vehicles_locktarget(vehic, (1 / autocvar_g_vehicle_racer_rocket_locking_time) * frametime,
						 (1 / autocvar_g_vehicle_racer_rocket_locking_releasetime) * frametime,
						 autocvar_g_vehicle_racer_rocket_locked_time);

		if(vehic.lock_target)
		{
			if(vehic.lock_strength == 1)
				UpdateAuxiliaryXhair(this, real_origin(vehic.lock_target), '1 0 0', 0);
			else if(vehic.lock_strength > 0.5)
				UpdateAuxiliaryXhair(this, real_origin(vehic.lock_target), '0 1 0', 0);
			else if(vehic.lock_strength < 0.5)
				UpdateAuxiliaryXhair(this, real_origin(vehic.lock_target), '0 0 1', 0);
		}
	}

	if(!forbidWeaponUse(this))
	if(time > vehic.delay)
	if(PHYS_INPUT_BUTTON_ATCK2(this))
	{
		vehic.misc_bulletcounter += 1;
		vehic.delay = time + 0.3;

		if(vehic.misc_bulletcounter == 1)
		{
			racer_fire_rocket_aim(this, "tag_rocket_r", (vehic.lock_strength == 1 && vehic.lock_target) ? vehic.lock_target : world);
			this.vehicle_ammo2 = 50;
		}
		else if(vehic.misc_bulletcounter == 2)
		{
			racer_fire_rocket_aim(this, "tag_rocket_l", (vehic.lock_strength == 1 && vehic.lock_target) ? vehic.lock_target : world);
			vehic.lock_strength  = 0;
			vehic.lock_target	= world;
			vehic.misc_bulletcounter = 0;
			vehic.delay = time + autocvar_g_vehicle_racer_rocket_refire;
			vehic.lip = time;
			this.vehicle_ammo2 = 0;
		}
	}
	else if(vehic.misc_bulletcounter == 0)
		this.vehicle_ammo2 = 100;

	this.vehicle_reload2 = bound(0, 100 * ((time - vehic.lip) / (vehic.delay - vehic.lip)), 100);

	if(vehic.vehicle_flags  & VHF_SHIELDREGEN)
		vehicles_regen(vehic, vehic.dmg_time, vehicle_shield, autocvar_g_vehicle_racer_shield, autocvar_g_vehicle_racer_shield_regen_pause, autocvar_g_vehicle_racer_shield_regen, frametime, true);

	if(vehic.vehicle_flags  & VHF_HEALTHREGEN)
		vehicles_regen(vehic, vehic.dmg_time, vehicle_health, autocvar_g_vehicle_racer_health, autocvar_g_vehicle_racer_health_regen_pause, autocvar_g_vehicle_racer_health_regen, frametime, false);

	if(vehic.vehicle_flags  & VHF_ENERGYREGEN)
		vehicles_regen(vehic, vehic.wait, vehicle_energy, autocvar_g_vehicle_racer_energy, autocvar_g_vehicle_racer_energy_regen_pause, autocvar_g_vehicle_racer_energy_regen, frametime, false);

	VEHICLE_UPDATE_PLAYER(this, vehic, health, racer);
	VEHICLE_UPDATE_PLAYER(this, vehic, energy, racer);

	if(vehic.vehicle_flags & VHF_HASSHIELD)
		VEHICLE_UPDATE_PLAYER(this, vehic, shield, racer);

	PHYS_INPUT_BUTTON_ATCK(this) = PHYS_INPUT_BUTTON_ATCK2(this) = false;
#endif

	setorigin(this, vehic.origin + '0 0 32');
	this.velocity = vehic.velocity;
}

void racer_think()
{SELFPARAM();
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

	CSQCMODEL_AUTOUPDATE(self);
}

void racer_exit(float eject)
{SELFPARAM();
	vector spot;

	self.think	  = racer_think;
	self.nextthink  = time;
	self.movetype   = MOVETYPE_BOUNCE;
	sound (self.tur_head, CH_TRIGGER_SINGLE, SND_Null, VOL_VEHICLEENGINE, ATTEN_NORM);

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
		if(vdist(self.velocity, >, 2 * autocvar_sv_maxairspeed))
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
	antilag_clear(self.owner, CS(self.owner));
	self.owner = world;
}

void racer_blowup()
{SELFPARAM();
	self.deadflag	= DEAD_DEAD;
	self.vehicle_exit(VHEF_NORMAL);

	RadiusDamage (self, self.enemy, autocvar_g_vehicle_racer_blowup_coredamage,
					autocvar_g_vehicle_racer_blowup_edgedamage,
					autocvar_g_vehicle_racer_blowup_radius, world, world,
					autocvar_g_vehicle_racer_blowup_forceintensity,
					DEATH_VH_WAKI_DEATH.m_id, world);

	self.nextthink  = time + autocvar_g_vehicle_racer_respawntime;
	self.think	  = vehicles_spawn;
	self.movetype   = MOVETYPE_NONE;
	self.effects	= EF_NODRAW;
	self.solid = SOLID_NOT;

	self.colormod  = '0 0 0';
	self.avelocity = '0 0 0';
	self.velocity  = '0 0 0';

	setorigin(self, self.pos1);
}

void racer_blowup_think()
{SELFPARAM();
	self.nextthink = time;

	if(time >= self.delay)
		racer_blowup();

	CSQCMODEL_AUTOUPDATE(self);
}

void racer_deadtouch()
{SELFPARAM();
	self.avelocity_x *= 0.7;
	self.cnt -= 1;
	if(self.cnt <= 0)
		racer_blowup();
}

spawnfunc(vehicle_racer)
{
	if(!autocvar_g_vehicle_racer) { remove(this); return; }
	if(!vehicle_initialize(this, VEH_RACER, false)) { remove(this); return; }
}

#endif // SVQC

#ifdef CSQC
#if 0
void racer_draw()
{SELFPARAM();
	float pushdeltatime = time - self.lastpushtime;
	if (pushdeltatime > 0.15) pushdeltatime = 0;
	self.lastpushtime = time;
	if(!pushdeltatime) return;

	tracebox(self.move_origin, self.mins, self.maxs, self.move_origin - ('0 0 1' * STAT(VEH_RACER_SPRINGLENGTH)), MOVE_NOMONSTERS, self);

	vector df = self.move_velocity * -STAT(VEH_RACER_FRICTION);
	df_z += (1 - trace_fraction) * STAT(VEH_RACER_HOVERPOWER) + sin(time * 2) * (STAT(VEH_RACER_SPRINGLENGTH) * 2);

	float forced = STAT(VEH_RACER_UPFORCEDAMPER);

	int cont = pointcontents(self.move_origin - '0 0 64');
	if(cont == CONTENT_WATER || cont == CONTENT_LAVA || cont == CONTENT_SLIME)
	{
		forced = STAT(VEH_RACER_WATER_UPFORCEDAMPER);
		self.move_velocity_z += 200;
	}

	self.move_velocity += df * pushdeltatime;
	if(self.move_velocity_z > 0)
		self.move_velocity_z *= 1 - forced * pushdeltatime;

	self.move_angles_x *= 1 - (STAT(VEH_RACER_ANGLESTABILIZER) * pushdeltatime);
	self.move_angles_z *= 1 - (STAT(VEH_RACER_ANGLESTABILIZER) * pushdeltatime);

	Movetype_Physics_MatchServer(false);
}
#endif
#endif

METHOD(Racer, vr_impact, void(Racer thisveh, entity instance))
{
#ifdef SVQC
    if(autocvar_g_vehicle_racer_bouncepain)
        vehicles_impact(instance, autocvar_g_vehicle_racer_bouncepain_x, autocvar_g_vehicle_racer_bouncepain_y, autocvar_g_vehicle_racer_bouncepain_z);
#endif
}

METHOD(Racer, vr_enter, void(Racer thisveh, entity instance))
{
#ifdef SVQC
    SELFPARAM();
    self.movetype = MOVETYPE_BOUNCE;
    self.owner.vehicle_health = (self.vehicle_health / autocvar_g_vehicle_racer_health)  * 100;
    self.owner.vehicle_shield = (self.vehicle_shield / autocvar_g_vehicle_racer_shield)  * 100;

    if(self.owner.flagcarried)
       setorigin(self.owner.flagcarried, '-190 0 96');
#elif defined(CSQC)
    SELFPARAM();
    self.move_movetype = MOVETYPE_BOUNCE;
#endif
}

METHOD(Racer, vr_spawn, void(Racer thisveh, entity instance))
{
#ifdef SVQC
    SELFPARAM();
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
}

METHOD(Racer, vr_death, void(Racer thisveh, entity instance))
{
#ifdef SVQC
    instance.SendEntity		= func_null; // stop networking this racer (for now)
    instance.health			= 0;
    instance.event_damage	= func_null;
    instance.solid			= SOLID_CORPSE;
    instance.takedamage		= DAMAGE_NO;
    instance.deadflag		= DEAD_DYING;
    instance.movetype		= MOVETYPE_BOUNCE;
    instance.wait			= time;
    instance.delay			= 2 + time + random() * 3;
    instance.cnt			= 1 + random() * 2;
    instance.touch			= racer_deadtouch;

    Send_Effect(EFFECT_EXPLOSION_MEDIUM, instance.origin, '0 0 0', 1);

    if(random() < 0.5)
        instance.avelocity_z = 32;
    else
        instance.avelocity_z = -32;

    instance.avelocity_x = -vlen(instance.velocity) * 0.2;
    instance.velocity += '0 0 700';
    instance.colormod = '-0.5 -0.5 -0.5';

    instance.think = racer_blowup_think;
    instance.nextthink = time;
#endif
}

#ifdef CSQC
METHOD(Racer, vr_hud, void(Racer thisveh))
{
    Vehicles_drawHUD(VEH_RACER.m_icon, "vehicle_racer_weapon1", "vehicle_racer_weapon2",
                     "vehicle_icon_ammo1", autocvar_hud_progressbar_vehicles_ammo1_color,
                     "vehicle_icon_ammo2", autocvar_hud_progressbar_vehicles_ammo2_color);
}
METHOD(Racer, vr_crosshair, void(Racer thisveh))
{
    Vehicles_drawCrosshair(vCROSS_GUIDE);
}
#endif
METHOD(Racer, vr_setup, void(Racer thisveh, entity instance))
{
#ifdef SVQC
    instance.vehicle_exit = racer_exit;

    // we have no need to network energy
    if(autocvar_g_vehicle_racer_energy)
    if(autocvar_g_vehicle_racer_energy_regen)
        instance.vehicle_flags |= VHF_ENERGYREGEN;

    if(autocvar_g_vehicle_racer_shield)
        instance.vehicle_flags |= VHF_HASSHIELD;

    if(autocvar_g_vehicle_racer_shield_regen)
        instance.vehicle_flags |= VHF_SHIELDREGEN;

    if(autocvar_g_vehicle_racer_health_regen)
        instance.vehicle_flags |= VHF_HEALTHREGEN;

    instance.respawntime = autocvar_g_vehicle_racer_respawntime;
    instance.vehicle_health = autocvar_g_vehicle_racer_health;
    instance.vehicle_shield = autocvar_g_vehicle_racer_shield;
    instance.max_health = instance.vehicle_health;
#endif

#ifdef CSQC
    AuxiliaryXhair[0].axh_image = vCROSS_LOCK; // Rocket
#endif
}

#endif
