#include "racer.qh"

#ifdef SVQC
	#include <common/gametypes/gametype/ctf/sv_ctf.qh>
	#include <common/mapobjects/trigger/impulse.qh>
#endif

#ifdef GAMEQC

#ifdef SVQC
bool autocvar_g_vehicle_racer = true;

float autocvar_g_vehicle_racer_thinkrate = 0.05; // TODO: any higher causes it to sink in liquids

float autocvar_g_vehicle_racer_speed_afterburn = 3000;
// energy consumed per second
float autocvar_g_vehicle_racer_afterburn_cost = 130;

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
float autocvar_g_vehicle_racer_springlength = 90;
float autocvar_g_vehicle_racer_upforcedamper = 2;
float autocvar_g_vehicle_racer_friction = 0.45;

float autocvar_g_vehicle_racer_water_time = 5;

//float autocvar_g_vehicle_racer_collision_multiplier = 0.05;

// 0 = hover, != 0 = maglev
int autocvar_g_vehicle_racer_hovertype = 0;
// NOTE!! x 4 (4 engines)
float autocvar_g_vehicle_racer_hoverpower = 8000;

float autocvar_g_vehicle_racer_turnroll = 30;
float autocvar_g_vehicle_racer_turnspeed = 220;
float autocvar_g_vehicle_racer_pitchspeed = 125;

float autocvar_g_vehicle_racer_energy = 100;
float autocvar_g_vehicle_racer_energy_regen = 90;
float autocvar_g_vehicle_racer_energy_regen_pause = 0.35;

float autocvar_g_vehicle_racer_health = 200;
float autocvar_g_vehicle_racer_health_regen = 0;
float autocvar_g_vehicle_racer_health_regen_pause = 0;

float autocvar_g_vehicle_racer_shield = 100;
float autocvar_g_vehicle_racer_shield_regen = 30;
float autocvar_g_vehicle_racer_shield_regen_pause = 1;

bool autocvar_g_vehicle_racer_rocket_locktarget = true;
float autocvar_g_vehicle_racer_rocket_locking_time = 0.35;
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
vector autocvar_g_vehicle_racer_bouncepain = '200 0.15 150';

.float racer_watertime;
.float racer_air_finished; // TODO: use a standard air meter for entities

var .vector(entity this, string tag_name, float spring_length, float max_power) racer_force_from_tag;

void racer_align4point(entity this, entity player, float _delta)
{
	vector push_vector;
	float fl_push, fr_push, bl_push, br_push;

	push_vector  = this.racer_force_from_tag(this, "tag_engine_fr", autocvar_g_vehicle_racer_springlength, autocvar_g_vehicle_racer_hoverpower);
	fr_push	  = force_fromtag_normpower;
	//vehicles_sweap_collision(force_fromtag_origin, this.velocity, _delta, v_add, autocvar_g_vehicle_racer_collision_multiplier);

	push_vector += this.racer_force_from_tag(this, "tag_engine_fl", autocvar_g_vehicle_racer_springlength, autocvar_g_vehicle_racer_hoverpower);
	fl_push	  = force_fromtag_normpower;
	//vehicles_sweap_collision(force_fromtag_origin, this.velocity, _delta, v_add, autocvar_g_vehicle_racer_collision_multiplier);

	push_vector += this.racer_force_from_tag(this, "tag_engine_br", autocvar_g_vehicle_racer_springlength, autocvar_g_vehicle_racer_hoverpower);
	br_push	  = force_fromtag_normpower;
	//vehicles_sweap_collision(force_fromtag_origin, this.velocity, _delta, v_add, autocvar_g_vehicle_racer_collision_multiplier);

	push_vector += this.racer_force_from_tag(this, "tag_engine_bl", autocvar_g_vehicle_racer_springlength, autocvar_g_vehicle_racer_hoverpower);
	bl_push	  = force_fromtag_normpower;
	//vehicles_sweap_collision(force_fromtag_origin, this.velocity, _delta, v_add, autocvar_g_vehicle_racer_collision_multiplier);

	this.velocity += push_vector * _delta;

	float uforce = autocvar_g_vehicle_racer_upforcedamper;

	int cont = pointcontents(this.origin - '0 0 64');
	if(cont == CONTENT_WATER || cont == CONTENT_LAVA || cont == CONTENT_SLIME)
	{
		uforce = autocvar_g_vehicle_racer_water_upforcedamper;

		if(PHYS_INPUT_BUTTON_CROUCH(player) && time < this.racer_air_finished)
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

void racer_fire_rocket_aim(entity this, entity player, string tagname, entity trg)
{
	vector v = gettaginfo(this, gettagindex(this, tagname));
	racer_fire_rocket(this, player, v, v_forward, trg);
}

bool racer_frame(entity this, float dt)
{
	entity player = this;
	entity vehic = player.vehicle;
	return = true;

#ifdef SVQC
	if(game_stopped)
	{
		vehic.solid = SOLID_NOT;
		vehic.takedamage = DAMAGE_NO;
		set_movetype(vehic, MOVETYPE_NONE);
		return;
	}
#endif

	vehicles_frame(vehic, player);

	int cont = Mod_Q1BSP_SuperContentsFromNativeContents(pointcontents(vehic.origin));
	if(!(cont & DPCONTENTS_WATER))
		vehic.racer_air_finished = 0;
	else if (!vehic.racer_air_finished)
		vehic.racer_air_finished = time + autocvar_g_vehicle_racer_water_time;

#ifdef SVQC
	if(IS_DEAD(vehic))
	{
		PHYS_INPUT_BUTTON_ATCK(player) = PHYS_INPUT_BUTTON_ATCK2(player) = false;
		return;
	}
#endif

	racer_align4point(vehic, player, dt);

#ifdef SVQC
	PHYS_INPUT_BUTTON_ZOOM(player) = PHYS_INPUT_BUTTON_CROUCH(player) = false;
#endif

	vehic.angles_x *= -1;

	// Yaw
	float ftmp = autocvar_g_vehicle_racer_turnspeed * dt;
	ftmp = bound(-ftmp, shortangle_f(player.v_angle_y - vehic.angles_y, vehic.angles_y), ftmp);
	vehic.angles_y = anglemods(vehic.angles_y + ftmp);

	// Roll
	vehic.angles_z += -ftmp * autocvar_g_vehicle_racer_turnroll * dt;

	// Pitch
	ftmp = autocvar_g_vehicle_racer_pitchspeed  * dt;
	ftmp = bound(-ftmp, shortangle_f(player.v_angle_x - vehic.angles_x, vehic.angles_x), ftmp);
	vehic.angles_x = bound(-autocvar_g_vehicle_racer_pitchlimit, anglemods(vehic.angles_x + ftmp), autocvar_g_vehicle_racer_pitchlimit);

	makevectors(vehic.angles);
	vehic.angles_x *= -1;

	//ftmp = vehic.velocity_z;
	vector df = vehic.velocity * -autocvar_g_vehicle_racer_friction;
	//vehic.velocity_z = ftmp;

	if(PHYS_CS(player).movement)
	{
		if(cont & DPCONTENTS_LIQUIDSMASK)
		{
			if(PHYS_CS(player).movement_x) { df += v_forward * ((PHYS_CS(player).movement_x > 0) ? autocvar_g_vehicle_racer_water_speed_forward : -autocvar_g_vehicle_racer_water_speed_forward); }
			if(PHYS_CS(player).movement_y) { df += v_right * ((PHYS_CS(player).movement_y > 0) ? autocvar_g_vehicle_racer_water_speed_strafe : -autocvar_g_vehicle_racer_water_speed_strafe); }
		}
		else
		{
			if(PHYS_CS(player).movement_x) { df += v_forward * ((PHYS_CS(player).movement_x > 0) ? autocvar_g_vehicle_racer_speed_forward : -autocvar_g_vehicle_racer_speed_forward); }
			if(PHYS_CS(player).movement_y) { df += v_right * ((PHYS_CS(player).movement_y > 0) ? autocvar_g_vehicle_racer_speed_strafe : -autocvar_g_vehicle_racer_speed_strafe); }
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
	if (PHYS_INPUT_BUTTON_JUMP(player) && vehic.vehicle_energy >= (autocvar_g_vehicle_racer_afterburn_cost * dt))
	{
#ifdef SVQC
		if(time - vehic.wait > 0.2)
			pointparticles(EFFECT_RACER_BOOSTER, vehic.origin - v_forward * 32, v_forward  * vlen(vehic.velocity), 1);
#endif

		vehic.wait = time;

		if(cont & DPCONTENTS_LIQUIDSMASK)
		{
			vehic.vehicle_energy -= autocvar_g_vehicle_racer_waterburn_cost * dt;
			df += (v_forward * autocvar_g_vehicle_racer_waterburn_speed);
		}
		else
		{
			vehic.vehicle_energy -= autocvar_g_vehicle_racer_afterburn_cost * dt;
			df += (v_forward * autocvar_g_vehicle_racer_speed_afterburn);
		}

#ifdef SVQC
		// TODO: move these to the client side where they belong
		// NOTE: reusing .invincible_finished here as delay counter for the smoke effect
		if(vehic.invincible_finished < time)
		{
			traceline(vehic.origin, vehic.origin - '0 0 256', MOVE_NORMAL, vehic);
			if(trace_fraction != 1.0)
				pointparticles(EFFECT_SMOKE_SMALL, trace_endpos, '0 0 0', 1);

			vehic.invincible_finished = time + 0.1 + (random() * 0.1);
		}

		// NOTE: reusing .strength_finished here as a sound delay counter
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

	if(cont & DPCONTENTS_LIQUIDSMASK)
		vehic.racer_watertime = time;

	float dforce = autocvar_g_vehicle_racer_downforce;
	if(time - vehic.racer_watertime <= 3)
		dforce = autocvar_g_vehicle_racer_water_downforce;

	df -= v_up * (vlen(vehic.velocity) * dforce);
	PHYS_CS(player).movement = vehic.velocity += df * dt;

#ifdef SVQC

	Weapon wep1 = WEP_RACER;
	.entity weaponentity = weaponentities[0]; // TODO: unhardcode
	if (!weaponLocked(player) && !weaponUseForbidden(player))
	if (PHYS_INPUT_BUTTON_ATCK(player))
	if (wep1.wr_checkammo1(wep1, vehic, weaponentity))
	{
		wep1.wr_think(wep1, vehic, weaponentity, 1);
	}

	if(autocvar_g_vehicle_racer_rocket_locktarget)
	{
		if(time >= vehic.vehicle_last_trace)
		{
			crosshair_trace(player);

			vehicles_locktarget(vehic, (1 / autocvar_g_vehicle_racer_rocket_locking_time) * dt,
							 (1 / autocvar_g_vehicle_racer_rocket_locking_releasetime) * dt,
							 autocvar_g_vehicle_racer_rocket_locked_time);

			vehic.vehicle_last_trace = time + autocvar_g_vehicle_racer_thinkrate;
		}

		if(vehic.lock_target)
		{
			if(vehic.lock_strength == 1)
				UpdateAuxiliaryXhair(player, real_origin(vehic.lock_target), '1 0 0', 0);
			else if(vehic.lock_strength > 0.5)
				UpdateAuxiliaryXhair(player, real_origin(vehic.lock_target), '0 1 0', 0);
			else if(vehic.lock_strength < 0.5)
				UpdateAuxiliaryXhair(player, real_origin(vehic.lock_target), '0 0 1', 0);
		}
	}

	if (!weaponLocked(player) && !weaponUseForbidden(player))
	if(time > vehic.delay)
	if(PHYS_INPUT_BUTTON_ATCK2(player))
	{
		vehic.misc_bulletcounter += 1;
		vehic.delay = time + 0.3;

		if(vehic.misc_bulletcounter == 1)
		{
			racer_fire_rocket_aim(vehic, player, "tag_rocket_r", (vehic.lock_strength == 1 && vehic.lock_target) ? vehic.lock_target : NULL);
			player.vehicle_ammo2 = 50;
		}
		else if(vehic.misc_bulletcounter == 2)
		{
			racer_fire_rocket_aim(vehic, player, "tag_rocket_l", (vehic.lock_strength == 1 && vehic.lock_target) ? vehic.lock_target : NULL);
			vehic.lock_strength  = 0;
			vehic.lock_target	= NULL;
			vehic.misc_bulletcounter = 0;
			vehic.delay = time + autocvar_g_vehicle_racer_rocket_refire;
			vehic.lip = time;
			player.vehicle_ammo2 = 0;
		}
	}
	else if(vehic.misc_bulletcounter == 0)
		player.vehicle_ammo2 = 100;

	player.vehicle_reload2 = bound(0, 100 * ((time - vehic.lip) / (vehic.delay - vehic.lip)), 100);

	if(vehic.vehicle_flags & VHF_SHIELDREGEN)
		vehicles_regen(vehic, vehic.dmg_time, vehicle_shield, autocvar_g_vehicle_racer_shield, autocvar_g_vehicle_racer_shield_regen_pause, autocvar_g_vehicle_racer_shield_regen, dt, true);

	if(vehic.vehicle_flags & VHF_HEALTHREGEN)
		vehicles_regen_resource(vehic, vehic.dmg_time, vehicle_health, autocvar_g_vehicle_racer_health, autocvar_g_vehicle_racer_health_regen_pause, autocvar_g_vehicle_racer_health_regen, dt, false, RES_HEALTH);

	if(vehic.vehicle_flags & VHF_ENERGYREGEN)
		vehicles_regen(vehic, vehic.wait, vehicle_energy, autocvar_g_vehicle_racer_energy, autocvar_g_vehicle_racer_energy_regen_pause, autocvar_g_vehicle_racer_energy_regen, dt, false);

	VEHICLE_UPDATE_PLAYER_RESOURCE(player, vehic, health, racer, RES_HEALTH);
	VEHICLE_UPDATE_PLAYER(player, vehic, energy, racer);

	if(vehic.vehicle_flags & VHF_HASSHIELD)
		VEHICLE_UPDATE_PLAYER(player, vehic, shield, racer);

	PHYS_INPUT_BUTTON_ATCK(player) = PHYS_INPUT_BUTTON_ATCK2(player) = false;
#endif

	setorigin(player, vehic.origin + '0 0 32');
#ifdef SVQC
	player.oldorigin = player.origin; // negate fall damage
#endif
	player.velocity = vehic.velocity;
}
#endif

#ifdef SVQC
void racer_think(entity this)
{
	float dt = autocvar_g_vehicle_racer_thinkrate;

	this.nextthink = time + dt;

	tracebox(this.origin, this.mins, this.maxs, this.origin - ('0 0 1' * autocvar_g_vehicle_racer_springlength), MOVE_NOMONSTERS, this);

	vector df = this.velocity * -autocvar_g_vehicle_racer_friction;
	df_z += (1 - trace_fraction) * autocvar_g_vehicle_racer_hoverpower + sin(time * 2) * (autocvar_g_vehicle_racer_springlength * 2);

	float forced = autocvar_g_vehicle_racer_upforcedamper;

	//int cont = pointcontents(this.origin - '0 0 64');
	traceline(this.origin - '0 0 64', this.origin - '0 0 64', MOVE_NOMONSTERS, this);
	//if(cont == CONTENT_WATER || cont == CONTENT_LAVA || cont == CONTENT_SLIME)
	if(trace_dpstartcontents & DPCONTENTS_LIQUIDSMASK)
	{
		forced = autocvar_g_vehicle_racer_water_upforcedamper;
		this.velocity_z += 200;
	}

	this.velocity += df * dt;
	if(this.velocity_z > 0)
		this.velocity_z *= 1 - forced * dt;

	this.angles_x *= 1 - (autocvar_g_vehicle_racer_anglestabilizer * dt);
	this.angles_z *= 1 - (autocvar_g_vehicle_racer_anglestabilizer * dt);

	CSQCMODEL_AUTOUPDATE(this);
}

void racer_exit(entity this, int eject)
{
	vector spot;

	setthink(this, racer_think);
	this.nextthink  = time;
	set_movetype(this, MOVETYPE_BOUNCE);
	sound (this.tur_head, CH_TRIGGER_SINGLE, SND_Null, VOL_VEHICLEENGINE, ATTEN_NORM);

	if(!this.owner)
		return;

	makevectors(this.angles);
	if(eject)
	{
		spot = this.origin + v_forward * 100 + '0 0 64';
		spot = vehicles_findgoodexit(this, this.owner, spot);
		setorigin(this.owner, spot);
		this.owner.velocity = (v_up + v_forward * 0.25) * 750;
		this.owner.oldvelocity = this.owner.velocity;
	}
	else
	{
		if(vdist(this.velocity, >, 2 * autocvar_sv_maxairspeed))
		{
			this.owner.velocity = normalize(this.velocity) * autocvar_sv_maxairspeed * 2;
			this.owner.velocity_z += 200;
			spot = this.origin + v_forward * 32 + '0 0 32';
			spot = vehicles_findgoodexit(this, this.owner, spot);
		}
		else
		{
			this.owner.velocity = this.velocity * 0.5;
			this.owner.velocity_z += 10;
			spot = this.origin - v_forward * 200 + '0 0 32';
			spot = vehicles_findgoodexit(this, this.owner, spot);
		}
		this.owner.oldvelocity = this.owner.velocity;
		setorigin(this.owner , spot);
	}
	antilag_clear(this.owner, CS(this.owner));
	this.owner = NULL;
}

void racer_blowup(entity this)
{
	this.deadflag = DEAD_DEAD;
	this.vehicle_exit(this, VHEF_NORMAL);

	RadiusDamage (this, this.enemy, autocvar_g_vehicle_racer_blowup_coredamage,
					autocvar_g_vehicle_racer_blowup_edgedamage,
					autocvar_g_vehicle_racer_blowup_radius, NULL, NULL,
					autocvar_g_vehicle_racer_blowup_forceintensity,
					DEATH_VH_WAKI_DEATH.m_id, DMG_NOWEP, NULL);

	this.nextthink  = time + autocvar_g_vehicle_racer_respawntime;
	setthink(this, vehicles_spawn);
	set_movetype(this, MOVETYPE_NONE);
	this.effects	= EF_NODRAW;
	this.solid = SOLID_NOT;

	this.colormod  = '0 0 0';
	this.avelocity = '0 0 0';
	this.velocity  = '0 0 0';

	setorigin(this, this.pos1);
}

void racer_blowup_think(entity this)
{
	this.nextthink = time;

	if(time >= this.delay)
		racer_blowup(this);

	//CSQCMODEL_AUTOUPDATE(this);
}

void racer_deadtouch(entity this, entity toucher)
{
	this.avelocity_x *= 0.7;
	this.cnt -= 1;
	if(this.cnt <= 0)
		racer_blowup(this);
}

spawnfunc(vehicle_racer)
{
	if(!autocvar_g_vehicle_racer) { delete(this); return; }
	if(!vehicle_initialize(this, VEH_RACER, false)) { delete(this); return; }
}

#endif // SVQC

METHOD(Racer, vr_impact, void(Racer thisveh, entity instance))
{
#ifdef SVQC
    if(autocvar_g_vehicle_racer_bouncepain)
        vehicles_impact(instance, autocvar_g_vehicle_racer_bouncepain_x, autocvar_g_vehicle_racer_bouncepain_y, autocvar_g_vehicle_racer_bouncepain_z);
#endif
}

METHOD(Racer, vr_enter, void(Racer thisveh, entity instance))
{
    set_movetype(instance, MOVETYPE_BOUNCE);
#ifdef SVQC
    instance.owner.vehicle_health = (GetResource(instance, RES_HEALTH) / autocvar_g_vehicle_racer_health)  * 100;
    instance.owner.vehicle_shield = (instance.vehicle_shield / autocvar_g_vehicle_racer_shield)  * 100;

    if(instance.owner.flagcarried)
       setorigin(instance.owner.flagcarried, '-190 0 96');
#endif
}

METHOD(Racer, vr_spawn, void(Racer thisveh, entity instance))
{
#ifdef SVQC
    if(autocvar_g_vehicle_racer_hovertype != 0)
        instance.racer_force_from_tag = vehicles_force_fromtag_maglev;
    else
        instance.racer_force_from_tag = vehicles_force_fromtag_hover;

    setthink(instance, racer_think);
    instance.nextthink	  = time;
    SetResourceExplicit(instance, RES_HEALTH, autocvar_g_vehicle_racer_health);
    instance.vehicle_shield = autocvar_g_vehicle_racer_shield;

    set_movetype(instance, MOVETYPE_TOSS);
    instance.solid		  = SOLID_SLIDEBOX;
    instance.delay		  = time;
    instance.scale		  = 0.5; // FIXME: this be hakkz, fix the models insted (scale body, add tag_viewport to the hudmodel).
    instance.mass		  = 900;

    setattachment(instance.vehicle_hudmodel, instance, "");
    setattachment(instance.vehicle_viewport, instance, "tag_viewport");

    instance.PlayerPhysplug = racer_frame;

    instance.bouncefactor = autocvar_g_vehicle_racer_bouncefactor;
    instance.bouncestop = autocvar_g_vehicle_racer_bouncestop;
    instance.damageforcescale = 0.5;
    SetResourceExplicit(instance, RES_HEALTH, autocvar_g_vehicle_racer_health);
    instance.vehicle_shield = autocvar_g_vehicle_racer_shield;
#endif
}

METHOD(Racer, vr_death, void(Racer thisveh, entity instance))
{
#ifdef SVQC
    setSendEntity(instance, func_null); // stop networking this racer (for now)
    SetResourceExplicit(instance, RES_HEALTH, 0);
    instance.event_damage	= func_null;
    instance.solid			= SOLID_CORPSE;
    instance.takedamage		= DAMAGE_NO;
    instance.deadflag		= DEAD_DYING;
    set_movetype(instance, MOVETYPE_BOUNCE);
    instance.wait			= time;
    instance.delay			= 2 + time + random() * 3;
    instance.cnt			= 1 + random() * 2;
    settouch(instance, racer_deadtouch);

    Send_Effect(EFFECT_EXPLOSION_MEDIUM, instance.origin, '0 0 0', 1);

    if(random() < 0.5)
        instance.avelocity_z = 32;
    else
        instance.avelocity_z = -32;

    instance.avelocity_x = -vlen(instance.velocity) * 0.2;
    instance.velocity += '0 0 700';
    instance.colormod = '-0.5 -0.5 -0.5';

    setthink(instance, racer_blowup_think);
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
METHOD(Racer, vr_crosshair, void(Racer thisveh, entity player))
{
    Vehicles_drawCrosshair(vCROSS_GUIDE);
}
#endif
METHOD(Racer, vr_setup, void(Racer thisveh, entity instance))
{
#ifdef SVQC
    instance.vehicle_exit = racer_exit;

    // we have no need to network energy
    if(autocvar_g_vehicle_racer_energy && autocvar_g_vehicle_racer_energy_regen)
        instance.vehicle_flags |= VHF_ENERGYREGEN;

    if(autocvar_g_vehicle_racer_shield)
        instance.vehicle_flags |= VHF_HASSHIELD;

    if(autocvar_g_vehicle_racer_shield_regen)
        instance.vehicle_flags |= VHF_SHIELDREGEN;

    if(autocvar_g_vehicle_racer_health_regen)
        instance.vehicle_flags |= VHF_HEALTHREGEN;

    instance.respawntime = autocvar_g_vehicle_racer_respawntime;
    SetResourceExplicit(instance, RES_HEALTH, autocvar_g_vehicle_racer_health);
    instance.vehicle_shield = autocvar_g_vehicle_racer_shield;
    instance.max_health = GetResource(instance, RES_HEALTH);
#endif

#ifdef CSQC
    AuxiliaryXhair[0].axh_image = vCROSS_LOCK; // Rocket
#endif
}

#endif
#ifdef MENUQC

METHOD(Racer, describe, string(Racer this))
{
	TC(Racer, this);
	PAGE_TEXT_INIT();
	PAR(_("The %s vehicle looks like a jet, but does not fly upwards very well. "
	      "It seats only one passenger, who becomes the pilot."), COLORED_NAME(this));
	PAR(_("It can be accelerated by pressing %s, which consumes power from the same source as the primary weapon."), strcat("^3", _("jump"), "^7"));
	PAR(_("The %s primary weapon is a laser and the secondary weapon shoots energy balls that explode on impact."), COLORED_NAME(this));
	return PAGE_TEXT;
}

#endif
