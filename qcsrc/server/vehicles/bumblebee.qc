#define BRG_SETUP 2
#define BRG_START 4
#define BRG_END 8

#ifdef SVQC
// Auto cvars
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

var float autocvar_g_vehicle_bumblebee_cannon_lock = 0;

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

float autocvar_g_vehicle_bumblebee_respawntime;

float autocvar_g_vehicle_bumblebee_blowup_radius;
float autocvar_g_vehicle_bumblebee_blowup_coredamage;
float autocvar_g_vehicle_bumblebee_blowup_edgedamage;
float autocvar_g_vehicle_bumblebee_blowup_forceintensity;

var float autocvar_g_vehicle_bumblebee = 0;


float bumble_raygun_send(entity to, float sf);

#define BUMB_MIN '-120 -120 -120'
#define BUMB_MAX '120 120 120'

void bumb_fire_cannon(entity _gun, string _tagname, entity _owner)
{
	vector v = gettaginfo(_gun, gettagindex(_gun, _tagname));
	vehicles_projectile("bigplasma_muzzleflash", "weapons/flacexp3.wav",
						v, normalize(v_forward + randomvec() * autocvar_g_vehicle_bumblebee_cannon_spread) * autocvar_g_vehicle_bumblebee_cannon_speed,
						autocvar_g_vehicle_bumblebee_cannon_damage, autocvar_g_vehicle_bumblebee_cannon_radius, autocvar_g_vehicle_bumblebee_cannon_force,  0,
						DEATH_BUMB_GUN, PROJECTILE_BUMBLE_GUN, 0, TRUE, TRUE, _owner);
}

float bumb_gunner_frame()
{
	entity vehic    = self.vehicle.owner;
	entity gun      = self.vehicle;
	entity gunner   = self;
	self = vehic;

	vehic.solid = SOLID_NOT;
	setorigin(gunner, vehic.origin);
	gunner.velocity = vehic.velocity;
	crosshair_trace(gunner);
	vector _ct = trace_endpos;
	vector ad;

	float _in = ((gun == vehic.gun1) ? autocvar_g_vehicle_bumblebee_cannon_turnlimit_in : autocvar_g_vehicle_bumblebee_cannon_turnlimit_out);
	float _out = ((gun == vehic.gun1) ? autocvar_g_vehicle_bumblebee_cannon_turnlimit_out : autocvar_g_vehicle_bumblebee_cannon_turnlimit_in);

	if(autocvar_g_vehicle_bumblebee_cannon_lock)
	{
		if(gun.lock_time < time)
			gun.enemy = world;

		if(trace_ent)
			if(trace_ent.movetype)
				if(trace_ent.takedamage)
					if(!trace_ent.deadflag)
					{
						if(teamplay)
						{
							if(trace_ent.team != gunner.team)
							{
								gun.enemy = trace_ent;
								gun.lock_time = time + 5;
							}
						}
						else
						{
							gun.enemy = trace_ent;
							gun.lock_time = time + 5;
						}
					}
	}

	if(gun.enemy)
	{
		float i, distance, impact_time;

		vector vf = real_origin(gun.enemy);
		vector _vel = gun.enemy.velocity;
		if(gun.enemy.movetype == MOVETYPE_WALK)
			_vel_z *= 0.1;


		ad = vf;
		for(i = 0; i < 4; ++i)
		{
			distance = vlen(ad - gunner.origin);
			impact_time = distance / autocvar_g_vehicle_bumblebee_cannon_speed;
			ad = vf + _vel * impact_time;
		}
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

	if(gunner.BUTTON_ATCK)
		if(time > gun.attack_finished_single)
			if(gun.vehicle_energy >= autocvar_g_vehicle_bumblebee_cannon_cost)
			{
				gun.vehicle_energy -= autocvar_g_vehicle_bumblebee_cannon_cost;
				bumb_fire_cannon(gun, "fire", gunner);
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

	self = gunner;
	return 1;
}

void bumb_gunner_exit(float _exitflag)
{
	if(clienttype(self) == CLIENTTYPE_REAL)
	{
		msg_entity = self;
		WriteByte(MSG_ONE, SVC_SETVIEWPORT);
		WriteEntity(MSG_ONE, self);

		WriteByte(MSG_ONE, SVC_SETVIEWANGLES);
		WriteAngle(MSG_ONE, 0);
		WriteAngle(MSG_ONE, self.vehicle.angles_y);
		WriteAngle(MSG_ONE, 0);
	}
	
	CSQCVehicleSetup(self, HUD_NORMAL);
	setsize(self, PL_MIN, PL_MAX);

	self.takedamage     = DAMAGE_AIM;
	self.solid          = SOLID_SLIDEBOX;
	self.movetype       = MOVETYPE_WALK;
	self.effects        &~= EF_NODRAW;
	self.alpha          = 1;
	self.PlayerPhysplug = SUB_Null;
	self.view_ofs       = PL_VIEW_OFS;
	self.event_damage   = PlayerDamage;
	self.hud            = HUD_NORMAL;
	self.switchweapon   = self.vehicle.switchweapon;

	if(self.flagcarried)
	{
		self.flagcarried.scale = 0.6;
		setattachment(self.flagcarried, self, "");
		setorigin(self.flagcarried, FLAG_CARRY_POS);
	}

	self.vehicle.vehicle_hudmodel.viewmodelforclient = self.vehicle;

	if(self == self.vehicle.owner.gunner1)
		self.vehicle.owner.gunner1 = world;
	else if(self == self.vehicle.owner.gunner2)
		self.vehicle.owner.gunner2 = world;
	else
		dprint("^1self != gunner1 or gunner2, this is a BIG PROBLEM, tell tZork this happend.\n");

	self.vehicle.phase = time + 5;
	self.vehicle        = world;
}

float bumb_gunner_enter()
{
	RemoveGrapplingHook(other);
	entity _gun, _gunner;
	if(!self.gunner1)
	{
		_gun = self.gun1;
		_gunner = self.gunner1;
		self.gunner1 = other;
	}
	else if(!self.gunner2)
	{
		_gun = self.gun2;
		_gunner = self.gunner2;
		self.gunner2 = other;
	}
	else
	{
		dprint("^1ERROR:^7Tried to enter a fully occupied vehicle!\n");
		return FALSE;
	}

	_gunner            = other;
	_gunner.vehicle    = _gun;
	_gun.switchweapon  = other.switchweapon;
	_gun.vehicle_exit  = bumb_gunner_exit;

	other.angles            = self.angles;
	other.takedamage        = DAMAGE_NO;
	other.solid             = SOLID_NOT;
	other.movetype          = MOVETYPE_NOCLIP;
	other.alpha             = -1;
	other.event_damage      = SUB_Null;
	other.view_ofs          = '0 0 0';
	other.hud               = _gun.hud;
	other.PlayerPhysplug    = _gun.PlayerPhysplug;
	other.vehicle_ammo1     = self.vehicle_ammo1;
	other.vehicle_ammo2     = self.vehicle_ammo2;
	other.vehicle_reload1   = self.vehicle_reload1;
	other.vehicle_reload2   = self.vehicle_reload2;
	other.vehicle_energy    = self.vehicle_energy;
	other.PlayerPhysplug    = bumb_gunner_frame;
	other.flags             &~= FL_ONGROUND;

	msg_entity = other;
	WriteByte(MSG_ONE, SVC_SETVIEWPORT);
	WriteEntity(MSG_ONE, _gun.vehicle_viewport);
	WriteByte(MSG_ONE, SVC_SETVIEWANGLES);
	WriteAngle(MSG_ONE, _gun.angles_x + self.angles_x);    // tilt
	WriteAngle(MSG_ONE, _gun.angles_y + self.angles_y);    // yaw
	WriteAngle(MSG_ONE, 0);                             // roll
	_gun.vehicle_hudmodel.viewmodelforclient = other;

	CSQCVehicleSetup(other, other.hud);
	
    if(other.flagcarried)
    {
        if(!autocvar_g_vehicles_allow_flagcarry)
            DropFlag(other.flagcarried, world, world);
        else
        {
            other.flagcarried.scale = 1;
            setattachment(other.flagcarried, self, "");
            setorigin(other.flagcarried, '0 0 1' * self.maxs_z);
        }
    }

	return TRUE;
}

float vehicles_valid_pilot()
{
	if(other.classname != "player")
		return FALSE;

	if(other.deadflag != DEAD_NO)
		return FALSE;

	if(other.vehicle != world)
		return FALSE;

	if(clienttype(other) != CLIENTTYPE_REAL)
		if(!autocvar_g_vehicles_allow_bots)
			return FALSE;

	if(teamplay && other.team != self.team)
		return FALSE;

	return TRUE;
}

void bumb_touch()
{

	if(self.gunner1 != world && self.gunner2 != world)
	{
		vehicles_touch();
		return;
	}

	if(vehicles_valid_pilot())
	{
		if(self.gun1.phase <= time)
			if(bumb_gunner_enter())
				return;

		if(self.gun2.phase <= time)
			if(bumb_gunner_enter())
				return;
	}

	vehicles_touch();
}

void bumb_regen()
{
	if(self.gun1.delay + autocvar_g_vehicle_bumblebee_cannon_ammo_regen_pause < time)
		self.gun1.vehicle_energy = min(autocvar_g_vehicle_bumblebee_cannon_ammo,
									   self.gun1.vehicle_energy + autocvar_g_vehicle_bumblebee_cannon_ammo_regen * frametime);

	if(self.gun2.delay + autocvar_g_vehicle_bumblebee_cannon_ammo_regen_pause < time)
		self.gun2.vehicle_energy = min(autocvar_g_vehicle_bumblebee_cannon_ammo,
									   self.gun2.vehicle_energy + autocvar_g_vehicle_bumblebee_cannon_ammo_regen * frametime);

	if(self.vehicle_flags  & VHF_SHIELDREGEN)
		vehicles_regen(self.dmg_time, vehicle_shield, autocvar_g_vehicle_bumblebee_shield, autocvar_g_vehicle_bumblebee_shield_regen_pause, autocvar_g_vehicle_bumblebee_shield_regen, frametime, TRUE);

	if(self.vehicle_flags  & VHF_HEALTHREGEN)
		vehicles_regen(self.dmg_time, vehicle_health, autocvar_g_vehicle_bumblebee_health, autocvar_g_vehicle_bumblebee_health_regen_pause, autocvar_g_vehicle_bumblebee_health_regen, frametime, FALSE);

	if(self.vehicle_flags  & VHF_ENERGYREGEN)
		vehicles_regen(self.wait, vehicle_energy, autocvar_g_vehicle_bumblebee_energy, autocvar_g_vehicle_bumblebee_energy_regen_pause, autocvar_g_vehicle_bumblebee_energy_regen, frametime, FALSE);

}

float bumb_pilot_frame()
{
	entity pilot, vehic;
	vector newvel;

	pilot = self;
	vehic = self.vehicle;
	self   = vehic;


	if(vehic.deadflag != DEAD_NO)
	{
		self = pilot;
		pilot.BUTTON_ATCK = pilot.BUTTON_ATCK2 = 0;
		return 1;
	}

	bumb_regen();

	crosshair_trace(pilot);

	vector vang;
	float ftmp;

	vang = vehic.angles;
	newvel = vectoangles(normalize(trace_endpos - self.origin + '0 0 32'));
	vang_x *= -1;
	newvel_x *= -1;
	if(newvel_x > 180)  newvel_x -= 360;
	if(newvel_x < -180) newvel_x += 360;
	if(newvel_y > 180)  newvel_y -= 360;
	if(newvel_y < -180) newvel_y += 360;

	ftmp = shortangle_f(pilot.v_angle_y - vang_y, vang_y);
	if(ftmp > 180)  ftmp -= 360;
	if(ftmp < -180) ftmp += 360;
	vehic.avelocity_y = bound(-autocvar_g_vehicle_bumblebee_turnspeed, ftmp + vehic.avelocity_y * 0.9, autocvar_g_vehicle_bumblebee_turnspeed);

	// Pitch
	ftmp = 0;
	if(pilot.movement_x > 0 && vang_x < autocvar_g_vehicle_bumblebee_pitchlimit) ftmp = 5;
	else if(pilot.movement_x < 0 && vang_x > -autocvar_g_vehicle_bumblebee_pitchlimit) ftmp = -20;

	newvel_x = bound(-autocvar_g_vehicle_bumblebee_pitchlimit, newvel_x , autocvar_g_vehicle_bumblebee_pitchlimit);
	ftmp = vang_x - bound(-autocvar_g_vehicle_bumblebee_pitchlimit, newvel_x + ftmp, autocvar_g_vehicle_bumblebee_pitchlimit);
	vehic.avelocity_x = bound(-autocvar_g_vehicle_bumblebee_pitchspeed, ftmp + vehic.avelocity_x * 0.9, autocvar_g_vehicle_bumblebee_pitchspeed);

	vehic.angles_x = anglemods(vehic.angles_x);
	vehic.angles_y = anglemods(vehic.angles_y);
	vehic.angles_z = anglemods(vehic.angles_z);

	makevectors('0 1 0' * vehic.angles_y);
	newvel = vehic.velocity * -autocvar_g_vehicle_bumblebee_friction;

	if(pilot.movement_x != 0)
	{
		if(pilot.movement_x > 0)
			newvel += v_forward  * autocvar_g_vehicle_bumblebee_speed_forward;
		else if(pilot.movement_x < 0)
			newvel -= v_forward  * autocvar_g_vehicle_bumblebee_speed_forward;
	}

	if(pilot.movement_y != 0)
	{
		if(pilot.movement_y < 0)
			newvel -= v_right * autocvar_g_vehicle_bumblebee_speed_strafe;
		else if(pilot.movement_y > 0)
			newvel += v_right * autocvar_g_vehicle_bumblebee_speed_strafe;
		ftmp = newvel * v_right;
		ftmp *= frametime * 0.1;
		vehic.angles_z = bound(-15, vehic.angles_z + ftmp, 15);
	}
	else
	{
		vehic.angles_z *= 0.95;
		if(vehic.angles_z >= -1 && vehic.angles_z <= -1)
			vehic.angles_z = 0;
	}

	if(pilot.BUTTON_CROUCH)
		newvel -=   v_up * autocvar_g_vehicle_bumblebee_speed_down;
	else if(pilot.BUTTON_JUMP)
		newvel +=  v_up * autocvar_g_vehicle_bumblebee_speed_up;

	vehic.velocity  += newvel * frametime;
	pilot.velocity = pilot.movement  = vehic.velocity;
	setorigin(pilot, vehic.origin + '0 0 32');

	vehicle_aimturret(vehic, trace_endpos, self.gun3, "fire",
					  autocvar_g_vehicle_bumblebee_raygun_pitchlimit_down * -1,  autocvar_g_vehicle_bumblebee_raygun_pitchlimit_up,
					  autocvar_g_vehicle_bumblebee_raygun_turnlimit_sides * -1,  autocvar_g_vehicle_bumblebee_raygun_turnlimit_sides,  autocvar_g_vehicle_bumblebee_raygun_turnspeed);


	if((pilot.BUTTON_ATCK || pilot.BUTTON_ATCK2) && vehic.vehicle_energy > autocvar_g_vehicle_bumblebee_raygun_dps * sys_frametime)
	{

		if(vehic.gun3.enemy == world)
		{
			vehic.gun3.enemy = spawn();
			Net_LinkEntity(vehic.gun3.enemy, FALSE, 0, bumble_raygun_send);
			vehic.gun3.enemy.SendFlags = BRG_SETUP;
			vehic.gun3.enemy.think = SUB_Remove;
			vehic.gun3.enemy.realowner = pilot;
			vehic.gun3.enemy.cnt = autocvar_g_vehicle_bumblebee_raygun;
		}

		vehic.gun3.enemy.nextthink = time + 0.1;
		setorigin(vehic.gun3.enemy, gettaginfo(vehic.gun3, gettagindex(vehic.gun3, "fire")));
		traceline(vehic.gun3.enemy.origin, vehic.gun3.enemy.origin + v_forward * autocvar_g_vehicle_bumblebee_raygun_range, MOVE_NORMAL, vehic);
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
							if(autocvar_g_vehicle_bumblebee_healgun_sps && trace_ent.vehicle_health <= trace_ent.tur_health)
								trace_ent.vehicle_shield = min(trace_ent.vehicle_shield + autocvar_g_vehicle_bumblebee_healgun_sps * frametime, trace_ent.tur_head.tur_health);

							if(autocvar_g_vehicle_bumblebee_healgun_hps)
								trace_ent.vehicle_health = min(trace_ent.vehicle_health + autocvar_g_vehicle_bumblebee_healgun_hps * frametime, trace_ent.tur_health);
						}
						else if(trace_ent.flags & FL_CLIENT)
						{
							if(trace_ent.health <= autocvar_g_vehicle_bumblebee_healgun_hmax && autocvar_g_vehicle_bumblebee_healgun_hps)
								trace_ent.health = min(trace_ent.health + autocvar_g_vehicle_bumblebee_healgun_hps * frametime, autocvar_g_vehicle_bumblebee_healgun_hmax);

							if(trace_ent.armorvalue <= autocvar_g_vehicle_bumblebee_healgun_amax && autocvar_g_vehicle_bumblebee_healgun_aps)
								trace_ent.armorvalue = min(trace_ent.armorvalue + autocvar_g_vehicle_bumblebee_healgun_aps * frametime, autocvar_g_vehicle_bumblebee_healgun_amax);

							trace_ent.health = min(trace_ent.health + autocvar_g_vehicle_bumblebee_healgun_hps * frametime, autocvar_g_vehicle_bumblebee_healgun_hmax);
						}
						else if(trace_ent.turrcaps_flags & TFL_TURRCAPS_ISTURRET)
						{
							if(trace_ent.health  <= trace_ent.tur_health && autocvar_g_vehicle_bumblebee_healgun_hps)
								trace_ent.health = min(trace_ent.health + autocvar_g_vehicle_bumblebee_healgun_hps * frametime, trace_ent.tur_health);
							//else ..hmmm what? ammo?

							trace_ent.SendFlags |= TNSF_STATUS;
						}
					}
			}
		}
		vehic.gun3.enemy.hook_end = trace_endpos;
		vehic.gun3.enemy.SendFlags |= BRG_START;
		vehic.gun3.enemy.SendFlags |= BRG_END;
		vehic.wait = time + 1;
	}
	else
	{
		if(vehic.gun3.enemy)
			remove(vehic.gun3.enemy);

		vehic.gun3.enemy = world;
	}

	VEHICLE_UPDATE_PLAYER(pilot, health, bumblebee);
	VEHICLE_UPDATE_PLAYER(pilot, energy, bumblebee);

	pilot.vehicle_ammo1 = (vehic.gun1.vehicle_energy / autocvar_g_vehicle_bumblebee_cannon_ammo) * 100;
	pilot.vehicle_ammo2 = (vehic.gun2.vehicle_energy / autocvar_g_vehicle_bumblebee_cannon_ammo) * 100;

	if(vehic.vehicle_flags & VHF_HASSHIELD)
		VEHICLE_UPDATE_PLAYER(pilot, shield, bumblebee);


	pilot.BUTTON_ATCK = pilot.BUTTON_ATCK2 = pilot.BUTTON_CROUCH = 0;
	self = pilot;

	return 1;
}

void bumb_think()
{
	self.velocity = self.velocity * 0.99;
	self.nextthink = time + 0.1;
}

void bumb_enter()
{
	self.touch  = bumb_touch;
}

void bumb_exit(float eject)
{
	self.owner = world;
	self.touch = vehicles_touch;
}

void bumb_blowup()
{
	self.deadflag    = DEAD_DEAD;

	RadiusDamage(self, self.enemy, autocvar_g_vehicle_bumblebee_blowup_coredamage,
				 autocvar_g_vehicle_bumblebee_blowup_edgedamage,
				 autocvar_g_vehicle_bumblebee_blowup_radius, self,
				 autocvar_g_vehicle_bumblebee_blowup_forceintensity,
				 DEATH_WAKIBLOWUP, world);

	self.movetype       = MOVETYPE_NONE;
	self.effects        = EF_NODRAW;
	self.colormod       = '0 0 0';
	self.avelocity      = '0 0 0';
	self.velocity       = '0 0 0';

	//entity vehicle_tossgib(entity _template, vector _vel, string _tag, float _burn, float _explode, float _maxtime)
	fixedmakevectors(self.angles);
	vehicle_tossgib(self.gun1, self.velocity + v_right * 300 + v_up * 100 + randomvec() * 200, "cannon_right", rint(random()), rint(random()), 6, randomvec() * 300);
	vehicle_tossgib(self.gun2, self.velocity + v_right * -300 + v_up * 100 + randomvec() * 200, "cannon_left", rint(random()), rint(random()), 6, randomvec() * 300);
	vehicle_tossgib(self.gun3, self.velocity + v_forward * 300 + v_up * -100 + randomvec() * 200, "raygun", rint(random()), rint(random()), 6, randomvec() * 300);

	sound(self, CH_SHOTS, "weapons/rocket_impact.wav", VOL_BASE, ATTN_NORM);
	pointparticles(particleeffectnum("explosion_large"), randomvec() * 80 + (self.origin + '0 0 100'), '0 0 0', 1);

	setorigin(self, self.pos1);
	self.touch = SUB_Null;
	self.nextthink = 0;
}

void bumb_diethink()
{
	if(time >= self.wait)
		self.think = bumb_blowup;

	if(random() < 0.1)
	{
		sound(self, CH_SHOTS, "weapons/rocket_impact.wav", VOL_BASE, ATTN_NORM);
		pointparticles(particleeffectnum("explosion_small"), randomvec() * 80 + (self.origin + '0 0 100'), '0 0 0', 1);
	}

	self.nextthink = time + 0.1;
}

void bumb_die()
{
	entity oldself = self;
	if(self.gunner1)
	{
		self = self.gunner1;
		oldself.gun1.vehicle_exit(VHEF_EJECT);
		self = oldself;
	}

	if(self.gunner2)
	{
		self = self.gunner2;
		oldself.gun2.vehicle_exit(VHEF_EJECT);
		self = oldself;
	}

	self.vehicle_exit(VHEF_EJECT);

	self.health       = 0;
	self.event_damage = SUB_Null;
	self.solid        = SOLID_CORPSE;
	self.takedamage   = DAMAGE_NO;
	self.deadflag     = DEAD_DYING;
	self.movetype     = MOVETYPE_BOUNCE;
	self.think        = bumb_diethink;
	self.nextthink    = time;
	self.wait         = time + 2 + (random() * 8);

	self.avelocity = '0 0.5 1' * (random() * 400);
	self.avelocity -= '0 0.5 1' * (random() * 400);

	self.colormod = '-0.5 -0.5 -0.5';
	self.touch     = bumb_blowup;

	pointparticles(particleeffectnum("explosion_medium"), findbetterlocation(self.origin, 16), '0 0 0', 1);
}


void bumb_spawn(float _f)
{
	/*
	float i;
	for(i=1; gettaginfo(self.gun1, i), gettaginfo_name; ++i)
	{

	    dprint(" ------- ^1gettaginfo_name^2(",ftos(i),") ^3=", gettaginfo_name, "\n");
	}
	*/

	if(!self.gun1)
	{
		// for some reason, autosizing of the shiled entity refuses to work for this one so set it up in advance.
		self.vehicle_shieldent = spawn();
		self.vehicle_shieldent.effects = EF_LOWPRECISION;
		setmodel(self.vehicle_shieldent, "models/vhshield.md3");
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

		setmodel(self.gun1, "models/vehicles/bumblebee_plasma_right.dpm");
		setmodel(self.gun2, "models/vehicles/bumblebee_plasma_left.dpm");
		setmodel(self.gun3, "models/vehicles/bumblebee_ray.dpm");

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

		vehicle_addplayerslot(self, self.gun1, HUD_BUMBLEBEE_GUN, "models/vehicles/wakizashi_cockpit.dpm", bumb_gunner_frame, bumb_gunner_exit);
		vehicle_addplayerslot(self, self.gun2, HUD_BUMBLEBEE_GUN, "models/vehicles/wakizashi_cockpit.dpm", bumb_gunner_frame, bumb_gunner_exit);

		setorigin(self.vehicle_hudmodel, '45 0 45');    // Move cockpit up-forward.
		setorigin(self.vehicle_viewport, '8 0 5');    // Move camera up-forward too.

		//fixme-model-bones
		setorigin(self.gun1.vehicle_hudmodel, '90 -27 -23');
		setorigin(self.gun1.vehicle_viewport, '-85 0 50');
		//fixme-model-bones
		setorigin(self.gun2.vehicle_hudmodel, '90 27 -23');
		setorigin(self.gun2.vehicle_viewport, '-85 0 50');

		self.scale = 1.5;
	}

	self.vehicle_health = autocvar_g_vehicle_bumblebee_health;
	self.vehicle_shield = autocvar_g_vehicle_bumblebee_shield;
	self.movetype       = MOVETYPE_TOSS;
	self.solid          = SOLID_BBOX;
	self.movetype = MOVETYPE_FLY;
	setorigin(self, self.origin + '0 0 25');
}

void spawnfunc_vehicle_bumblebee()
{
	if(!autocvar_g_vehicle_bumblebee)
	{
		remove(self);
		return;
	}

	precache_model("models/vehicles/bumblebee_body.dpm");
	precache_model("models/vehicles/bumblebee_plasma_left.dpm");
	precache_model("models/vehicles/bumblebee_plasma_right.dpm");
	precache_model("models/vehicles/bumblebee_ray.dpm");
	precache_model("models/vehicles/wakizashi_cockpit.dpm");
	precache_model("models/vehicles/spiderbot_cockpit.dpm");
	precache_model("models/vehicles/raptor_cockpit.dpm");

	if(autocvar_g_vehicle_bumblebee_energy)
		if(autocvar_g_vehicle_bumblebee_energy_regen)
			self.vehicle_flags |= VHF_ENERGYREGEN;

	if(autocvar_g_vehicle_bumblebee_shield)
		self.vehicle_flags |= VHF_HASSHIELD;

	if(autocvar_g_vehicle_bumblebee_shield_regen)
		self.vehicle_flags |= VHF_SHIELDREGEN;

	if(autocvar_g_vehicle_bumblebee_health_regen)
		self.vehicle_flags |= VHF_HEALTHREGEN;

	if not(vehicle_initialize(
			   "Bumblebee", "models/vehicles/bumblebee_body.dpm",
			   "", "models/vehicles/spiderbot_cockpit.dpm", "", "", "tag_viewport",
			   HUD_BUMBLEBEE, BUMB_MIN, BUMB_MAX, FALSE,
			   bumb_spawn, autocvar_g_vehicle_bumblebee_respawntime,
			   bumb_pilot_frame, bumb_enter, bumb_exit,
			   bumb_die, bumb_think, FALSE, autocvar_g_vehicle_bumblebee_health, autocvar_g_vehicle_bumblebee_shield))
	{
		remove(self);
		return;
	}
}

float bumble_raygun_send(entity to, float sf)
{
	WriteByte(MSG_ENTITY, ENT_CLIENT_BUMBLE_RAYGUN);

	WriteByte(MSG_ENTITY, sf);
	if(sf & BRG_SETUP)
	{
		WriteByte(MSG_ENTITY, num_for_edict(self.realowner));
		WriteByte(MSG_ENTITY, self.realowner.team);
		WriteByte(MSG_ENTITY, self.cnt);

		//WriteCoord(MSG_ENTITY, autocvar_g_balance_electro_primary_range);
	}

	if(sf & BRG_START)
	{
		WriteCoord(MSG_ENTITY, self.origin_x);
		WriteCoord(MSG_ENTITY, self.origin_y);
		WriteCoord(MSG_ENTITY, self.origin_z);
	}

	if(sf & BRG_END)
	{
		WriteCoord(MSG_ENTITY, self.hook_end_x);
		WriteCoord(MSG_ENTITY, self.hook_end_y);
		WriteCoord(MSG_ENTITY, self.hook_end_z);
	}

	return TRUE;
}
#endif // SVQC

#ifdef CSQC
/*
.vector raygun_l1
.vector raygun_l2;
.vector raygun_l3;
*/

void bumble_raygun_draw()
{
	float _len;
	vector _dir;
	vector _vtmp1, _vtmp2;

	_len = vlen(self.origin - self.move_origin);
	_dir = normalize(self.move_origin - self.origin);

	float i, df, sz, al;

	for(i = -0.1; i < 0.2; i += 0.1)
	{
		df = DRAWFLAG_NORMAL; //((random() < 0.5) ? DRAWFLAG_ADDITIVE : DRAWFLAG_SCREEN);
		sz = 2 + random() * 6;
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

void bumble_raygun_read(float bIsNew)
{
	float sf = ReadByte();

	if(sf & BRG_SETUP)
	{
		self.cnt  = ReadByte();
		self.team = ReadByte();
		self.cnt  = ReadByte();
		if(self.cnt)
			self.colormod = '1 0 0';
		else
			self.colormod = '0 1 0';

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

void bumblebee_draw()
{

}

void bumblebee_draw2d()
{

}

void bumblebee_read_extra()
{

}

void vehicle_bumblebee_assemble()
{

}
#endif //CSQC
