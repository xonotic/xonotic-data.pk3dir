#ifndef VEHICLE_SPIDERBOT
#define VEHICLE_SPIDERBOT
#ifndef MENUQC
int v_spiderbot(int);
#endif
REGISTER_VEHICLE_SIMPLE(
/* VEH_##id   */ SPIDERBOT,
/* spawnflags */ VHF_DMGSHAKE,
/* mins,maxs  */ '-75 -75 10', '75 75 125',
/* model	  */ "models/vehicles/spiderbot.dpm",
/* head_model */ "models/vehicles/spiderbot_top.dpm",
/* hud_model  */ "models/vehicles/spiderbot_cockpit.dpm",
/* tags	   	  */ "tag_head", "tag_hud", "",
/* netname	  */ "spiderbot",
/* fullname   */ _("Spiderbot")
) {
    this.m_icon = "vehicle_spider";
#ifndef MENUQC
    this.vehicle_func = v_spiderbot;
#endif
}
#endif

#ifdef IMPLEMENTATION

const int SBRM_FIRST = 1;
const int SBRM_VOLLY = 1;
const int SBRM_GUIDE = 2;
const int SBRM_ARTILLERY = 3;
const int SBRM_LAST = 3;

#ifdef SVQC
bool autocvar_g_vehicle_spiderbot;

float autocvar_g_vehicle_spiderbot_respawntime;

float autocvar_g_vehicle_spiderbot_speed_stop;
float autocvar_g_vehicle_spiderbot_speed_strafe;
float autocvar_g_vehicle_spiderbot_speed_walk;
float autocvar_g_vehicle_spiderbot_speed_run = 700;
float autocvar_g_vehicle_spiderbot_turnspeed;
float autocvar_g_vehicle_spiderbot_turnspeed_strafe;
float autocvar_g_vehicle_spiderbot_movement_inertia;

float autocvar_g_vehicle_spiderbot_springlength;
float autocvar_g_vehicle_spiderbot_springup;
float autocvar_g_vehicle_spiderbot_springblend;
float autocvar_g_vehicle_spiderbot_tiltlimit;

float autocvar_g_vehicle_spiderbot_head_pitchlimit_down;
float autocvar_g_vehicle_spiderbot_head_pitchlimit_up;
float autocvar_g_vehicle_spiderbot_head_turnlimit;
float autocvar_g_vehicle_spiderbot_head_turnspeed;

int autocvar_g_vehicle_spiderbot_health;
float autocvar_g_vehicle_spiderbot_health_regen;
float autocvar_g_vehicle_spiderbot_health_regen_pause;

int autocvar_g_vehicle_spiderbot_shield;
float autocvar_g_vehicle_spiderbot_shield_regen;
float autocvar_g_vehicle_spiderbot_shield_regen_pause;

float autocvar_g_vehicle_spiderbot_minigun_damage;
float autocvar_g_vehicle_spiderbot_minigun_refire;
float autocvar_g_vehicle_spiderbot_minigun_spread;
int autocvar_g_vehicle_spiderbot_minigun_ammo_cost;
int autocvar_g_vehicle_spiderbot_minigun_ammo_max;
int autocvar_g_vehicle_spiderbot_minigun_ammo_regen;
float autocvar_g_vehicle_spiderbot_minigun_ammo_regen_pause;
float autocvar_g_vehicle_spiderbot_minigun_force;
float autocvar_g_vehicle_spiderbot_minigun_solidpenetration;

float autocvar_g_vehicle_spiderbot_rocket_damage;
float autocvar_g_vehicle_spiderbot_rocket_force;
float autocvar_g_vehicle_spiderbot_rocket_radius;
float autocvar_g_vehicle_spiderbot_rocket_speed;
float autocvar_g_vehicle_spiderbot_rocket_spread;
float autocvar_g_vehicle_spiderbot_rocket_refire;
float autocvar_g_vehicle_spiderbot_rocket_refire2;
float autocvar_g_vehicle_spiderbot_rocket_reload;
float autocvar_g_vehicle_spiderbot_rocket_health;
float autocvar_g_vehicle_spiderbot_rocket_noise;
float autocvar_g_vehicle_spiderbot_rocket_turnrate;
float autocvar_g_vehicle_spiderbot_rocket_lifetime;

vector autocvar_g_vehicle_spiderbot_bouncepain;

void spiderbot_rocket_artillery()
{SELFPARAM();
	self.nextthink = time;
	UpdateCSQCProjectile(self);
}

void spiderbot_rocket_unguided()
{SELFPARAM();
	vector newdir, olddir;

	self.nextthink  = time;

	olddir = normalize(self.velocity);
	newdir = normalize(self.pos1 - self.origin) + randomvec() * autocvar_g_vehicle_spiderbot_rocket_noise;
	self.velocity = normalize(olddir + newdir * autocvar_g_vehicle_spiderbot_rocket_turnrate) * autocvar_g_vehicle_spiderbot_rocket_speed;

	UpdateCSQCProjectile(self);

	if (self.owner.deadflag != DEAD_NO || self.cnt < time || vlen(self.pos1 - self.origin) < 16)
		self.use();
}

void spiderbot_rocket_guided()
{SELFPARAM();
	vector newdir, olddir;

	self.nextthink  = time;

	if(!self.realowner.vehicle)
		self.think = spiderbot_rocket_unguided;

	crosshair_trace(self.realowner);
	olddir = normalize(self.velocity);
	newdir = normalize(trace_endpos - self.origin) + randomvec() * autocvar_g_vehicle_spiderbot_rocket_noise;
	self.velocity = normalize(olddir + newdir * autocvar_g_vehicle_spiderbot_rocket_turnrate) * autocvar_g_vehicle_spiderbot_rocket_speed;

	UpdateCSQCProjectile(self);

	if (self.owner.deadflag != DEAD_NO || self.cnt < time)
		self.use();
}

void spiderbot_guide_release()
{SELFPARAM();
	entity rkt;
	rkt = findchainentity(realowner, self.owner);
	if(!rkt)
		return;

	crosshair_trace(self.owner);
	while(rkt)
	{
		if(rkt.think == spiderbot_rocket_guided)
		{
			rkt.pos1 = trace_endpos;
			rkt.think = spiderbot_rocket_unguided;
		}
		rkt = rkt.chain;
	}
}

float spiberbot_calcartillery_flighttime;
vector spiberbot_calcartillery(vector org, vector tgt, float ht)
{
	float grav, sdist, zdist, vs, vz, jumpheight;
	vector sdir;

	grav  = autocvar_sv_gravity;
	zdist = tgt_z - org_z;
	sdist = vlen(tgt - org - zdist * '0 0 1');
	sdir  = normalize(tgt - org - zdist * '0 0 1');

	// how high do we need to go?
	jumpheight = fabs(ht);
	if(zdist > 0)
		jumpheight = jumpheight + zdist;

	// push so high...
	vz = sqrt(2 * grav * jumpheight); // NOTE: sqrt(positive)!

	// we start with downwards velocity only if it's a downjump and the jump apex should be outside the jump!
	if(ht < 0)
		if(zdist < 0)
			vz = -vz;

	vector solution;
	solution = solve_quadratic(0.5 * grav, -vz, zdist); // equation "z(ti) = zdist"
	// ALWAYS solvable because jumpheight >= zdist
	if(!solution_z)
		solution_y = solution_x; // just in case it is not solvable due to roundoff errors, assume two equal solutions at their center (this is mainly for the usual case with ht == 0)
	if(zdist == 0)
		solution_x = solution_y; // solution_x is 0 in this case, so don't use it, but rather use solution_y (which will be sqrt(0.5 * jumpheight / grav), actually)

	if(zdist < 0)
	{
		// down-jump
		if(ht < 0)
		{
			// almost straight line type
			// jump apex is before the jump
			// we must take the larger one
			spiberbot_calcartillery_flighttime = solution_y;
		}
		else
		{
			// regular jump
			// jump apex is during the jump
			// we must take the larger one too
			spiberbot_calcartillery_flighttime = solution_y;
		}
	}
	else
	{
		// up-jump
		if(ht < 0)
		{
			// almost straight line type
			// jump apex is after the jump
			// we must take the smaller one
			spiberbot_calcartillery_flighttime = solution_x;
		}
		else
		{
			// regular jump
			// jump apex is during the jump
			// we must take the larger one
			spiberbot_calcartillery_flighttime = solution_y;
		}
	}
	vs = sdist / spiberbot_calcartillery_flighttime;

	// finally calculate the velocity
	return sdir * vs + '0 0 1' * vz;
}

void spiderbot_rocket_do()
{SELFPARAM();
	vector v;
	entity rocket = world;

	if (self.wait != -10)
	{
		if (self.owner.BUTTON_ATCK2 && self.vehicle_weapon2mode == SBRM_GUIDE)
		{
			if (self.wait == 1)
			if (self.tur_head.frame == 9 || self.tur_head.frame == 1)
			{
				if(self.gun2.cnt < time && self.tur_head.frame == 9)
					self.tur_head.frame = 1;

				return;
			}
			self.wait = 1;
		}
		else
		{
			if(self.wait)
				spiderbot_guide_release();

			self.wait = 0;
		}
	}

	if(self.gun2.cnt > time)
		return;

	if (self.tur_head.frame >= 9)
	{
		self.tur_head.frame = 1;
		self.wait = 0;
	}

	if(self.wait != -10)
	if(!self.owner.BUTTON_ATCK2)
		return;

	if(forbidWeaponUse(self.owner))
		return;

	v = gettaginfo(self.tur_head,gettagindex(self.tur_head,"tag_fire"));

	switch(self.vehicle_weapon2mode)
	{
		case SBRM_VOLLY:
			rocket = vehicles_projectile(EFFECT_SPIDERBOT_ROCKETLAUNCH.eent_eff_name, SND(ROCKET_FIRE),
								   v, normalize(randomvec() * autocvar_g_vehicle_spiderbot_rocket_spread + v_forward) * autocvar_g_vehicle_spiderbot_rocket_speed,
								   autocvar_g_vehicle_spiderbot_rocket_damage, autocvar_g_vehicle_spiderbot_rocket_radius, autocvar_g_vehicle_spiderbot_rocket_force, 1,
								   DEATH_VH_SPID_ROCKET, PROJECTILE_SPIDERROCKET, autocvar_g_vehicle_spiderbot_rocket_health, false, true, self.owner);
			crosshair_trace(self.owner);
			float _dist = (random() * autocvar_g_vehicle_spiderbot_rocket_radius) + vlen(v - trace_endpos);
			_dist -= (random() * autocvar_g_vehicle_spiderbot_rocket_radius) ;
			rocket.nextthink  = time + (_dist / autocvar_g_vehicle_spiderbot_rocket_speed);
			rocket.think	 = vehicles_projectile_explode;

			if(self.owner.BUTTON_ATCK2 && self.tur_head.frame == 1)
				self.wait = -10;
			break;
		case SBRM_GUIDE:
			rocket = vehicles_projectile(EFFECT_SPIDERBOT_ROCKETLAUNCH.eent_eff_name, SND(ROCKET_FIRE),
								   v, normalize(v_forward) * autocvar_g_vehicle_spiderbot_rocket_speed,
								   autocvar_g_vehicle_spiderbot_rocket_damage, autocvar_g_vehicle_spiderbot_rocket_radius, autocvar_g_vehicle_spiderbot_rocket_force, 1,
								   DEATH_VH_SPID_ROCKET, PROJECTILE_SPIDERROCKET, autocvar_g_vehicle_spiderbot_rocket_health, false, false, self.owner);
			crosshair_trace(self.owner);
			rocket.pos1	   = trace_endpos;
			rocket.nextthink  = time;
			rocket.think	  = spiderbot_rocket_guided;


		break;
		case SBRM_ARTILLERY:
			rocket = vehicles_projectile(EFFECT_SPIDERBOT_ROCKETLAUNCH.eent_eff_name, SND(ROCKET_FIRE),
								   v, normalize(v_forward) * autocvar_g_vehicle_spiderbot_rocket_speed,
								   autocvar_g_vehicle_spiderbot_rocket_damage, autocvar_g_vehicle_spiderbot_rocket_radius, autocvar_g_vehicle_spiderbot_rocket_force, 1,
								   DEATH_VH_SPID_ROCKET, PROJECTILE_SPIDERROCKET, autocvar_g_vehicle_spiderbot_rocket_health, false, true, self.owner);

			crosshair_trace(self.owner);

			rocket.pos1	   = trace_endpos + randomvec() * (0.75 * autocvar_g_vehicle_spiderbot_rocket_radius);
			rocket.pos1_z	   = trace_endpos_z;

			traceline(v, v + '0 0 1' * MAX_SHOT_DISTANCE, MOVE_WORLDONLY, self);
			float h1 = 0.75 * vlen(v - trace_endpos);

			//v = trace_endpos;
			traceline(v , rocket.pos1 + '0 0 1' * MAX_SHOT_DISTANCE, MOVE_WORLDONLY, self);
			float h2 = 0.75 * vlen(rocket.pos1 - v);

			rocket.velocity  = spiberbot_calcartillery(v, rocket.pos1, ((h1 < h2) ? h1 : h2));
			rocket.movetype  = MOVETYPE_TOSS;
			rocket.gravity   = 1;
			//rocket.think	 = spiderbot_rocket_artillery;
		break;
	}
	rocket.classname  = "spiderbot_rocket";

	rocket.cnt = time + autocvar_g_vehicle_spiderbot_rocket_lifetime;

	self.tur_head.frame += 1;
	if (self.tur_head.frame == 9)
		self.attack_finished_single = autocvar_g_vehicle_spiderbot_rocket_reload;
	else
		self.attack_finished_single = ((self.vehicle_weapon2mode ==  SBRM_VOLLY) ? autocvar_g_vehicle_spiderbot_rocket_refire2 : autocvar_g_vehicle_spiderbot_rocket_refire);

	self.gun2.cnt = time + self.attack_finished_single;
}

.float jump_delay;
float spiderbot_frame()
{SELFPARAM();
	vector ad, vf;
	entity player, spider;
	float ftmp;

	if(intermission_running)
	{
		self.vehicle.velocity = '0 0 0';
		self.vehicle.avelocity = '0 0 0';
		return 1;
	}

	player = self;
	spider = self.vehicle;
	setself(spider);

	vehicles_painframe();

	player.BUTTON_ZOOM	  = 0;
	player.BUTTON_CROUCH	= 0;
	player.switchweapon	 = 0;
	player.vehicle_weapon2mode = spider.vehicle_weapon2mode;


#if 1 // 0 to enable per-gun impact aux crosshairs
	// Avarage gun impact point's -> aux cross
	ad = gettaginfo(spider.tur_head, gettagindex(spider.tur_head, "tag_hardpoint01"));
	vf = v_forward;
	ad += gettaginfo(spider.tur_head, gettagindex(spider.tur_head, "tag_hardpoint02"));
	vf += v_forward;
	ad = ad * 0.5;
	v_forward = vf * 0.5;
	traceline(ad, ad + v_forward * MAX_SHOT_DISTANCE, MOVE_NORMAL, spider);
	UpdateAuxiliaryXhair(player, trace_endpos, ('1 0 0' * player.vehicle_reload1) + ('0 1 0' * (1 - player.vehicle_reload1)), 0);
#else
	ad = gettaginfo(spider.gun1, gettagindex(spider.gun1, "barrels"));
	traceline(ad, ad + v_forward * MAX_SHOT_DISTANCE, MOVE_NORMAL, spider);
	UpdateAuxiliaryXhair(player, trace_endpos, ('1 0 0' * player.vehicle_reload1) + ('0 1 0' * (1 - player.vehicle_reload1)), 0);
	vf = ad;
	ad = gettaginfo(spider.gun2, gettagindex(spider.gun2, "barrels"));
	traceline(ad, ad + v_forward * MAX_SHOT_DISTANCE, MOVE_NORMAL, spider);
	UpdateAuxiliaryXhair(player, trace_endpos, ('1 0 0' * player.vehicle_reload1) + ('0 1 0' * (1 - player.vehicle_reload1)), 1);
	ad = 0.5 * (ad + vf);
#endif

	crosshair_trace(player);
	ad = vectoangles(normalize(trace_endpos - ad));
	ad = AnglesTransform_ToAngles(AnglesTransform_LeftDivide(AnglesTransform_FromAngles(spider.angles), AnglesTransform_FromAngles(ad))) - spider.tur_head.angles;
	ad = AnglesTransform_Normalize(ad, true);
	//UpdateAuxiliaryXhair(player, trace_endpos, ('1 0 0' * player.vehicle_reload2) + ('0 1 0' * (1 - player.vehicle_reload2)), 2);

	// Rotate head
	ftmp = autocvar_g_vehicle_spiderbot_head_turnspeed * sys_frametime;
	ad_y = bound(-ftmp, ad_y, ftmp);
	spider.tur_head.angles_y = bound(autocvar_g_vehicle_spiderbot_head_turnlimit * -1, spider.tur_head.angles_y + ad_y, autocvar_g_vehicle_spiderbot_head_turnlimit);

	// Pitch head
	ad_x = bound(ftmp * -1, ad_x, ftmp);
	spider.tur_head.angles_x = bound(autocvar_g_vehicle_spiderbot_head_pitchlimit_down, spider.tur_head.angles_x + ad_x, autocvar_g_vehicle_spiderbot_head_pitchlimit_up);


	//fixedmakevectors(spider.angles);
	makevectors(spider.angles + '-2 0 0' * spider.angles_x);

	movelib_groundalign4point(autocvar_g_vehicle_spiderbot_springlength, autocvar_g_vehicle_spiderbot_springup, autocvar_g_vehicle_spiderbot_springblend, autocvar_g_vehicle_spiderbot_tiltlimit);

	if(spider.flags & FL_ONGROUND)
		spider.jump_delay = time; // reset now so movement can begin

	//if(spider.flags & FL_ONGROUND)
	{
		if(spider.flags & FL_ONGROUND)
		if(spider.frame == 4 && self.tur_head.wait != 0)
		{
			sound (self, CH_TRIGGER_SINGLE, SND_VEH_SPIDERBOT_LAND, VOL_VEHICLEENGINE, ATTEN_NORM);
			spider.frame = 5;
		}

		if(!player.BUTTON_JUMP)
			spider.BUTTON_JUMP = 0;

		if((spider.flags & FL_ONGROUND) && player.BUTTON_JUMP && !spider.BUTTON_JUMP && self.tur_head.wait < time)
		{
			sound (self, CH_TRIGGER_SINGLE, SND_VEH_SPIDERBOT_JUMP, VOL_VEHICLEENGINE, ATTEN_NORM);
			//dprint("spiderbot_jump:", ftos(soundlength("vehicles/spiderbot_jump.wav")), "\n");
			self.delay = 0;

			self.tur_head.wait = time + 2;
			spider.jump_delay = time + 2;
			spider.BUTTON_JUMP = 1; // set spider's jump
			//player.BUTTON_JUMP = 0;

			vector movefix = '0 0 0';
			if(player.movement_x > 0) movefix_x = 1;
			if(player.movement_x < 0) movefix_x = -1;
			if(player.movement_y > 0) movefix_y = 1;
			if(player.movement_y < 0) movefix_y = -1;

			vector rt = movefix_y * v_right;
			vector sd = movefix_x * v_forward;
			if(movefix_y == 0 && movefix_x == 0)
				sd = v_forward; // always do forward

			spider.flags &= ~FL_ONGROUND;

			spider.velocity = sd * 700 + rt * 600 + v_up * 600;
			spider.frame = 4;
		}
		else if(time >= spider.jump_delay)
		{
			if(vlen(player.movement) == 0)
			{
				if(spider.flags & FL_ONGROUND)
				{
					if(self.sound_nexttime < time || self.delay != 3)
					{
						self.delay = 3;
						self.sound_nexttime = time + 6.486500; //soundlength("vehicles/spiderbot_idle.wav");
						//dprint("spiderbot_idle:", ftos(soundlength("vehicles/spiderbot_idle.wav")), "\n");
						sound (self, CH_TRIGGER_SINGLE, SND_VEH_SPIDERBOT_IDLE, VOL_VEHICLEENGINE, ATTEN_NORM);
					}
					movelib_beak_simple(autocvar_g_vehicle_spiderbot_speed_stop);
					spider.frame = 5;
				}
			}
			else
			{
				// Turn Body
				if(player.movement_x == 0 && player.movement_y != 0)
					ftmp = autocvar_g_vehicle_spiderbot_turnspeed_strafe * sys_frametime;
				else
					ftmp = autocvar_g_vehicle_spiderbot_turnspeed * sys_frametime;

				ftmp = bound(-ftmp, spider.tur_head.angles_y, ftmp);
				spider.angles_y = anglemods(spider.angles_y + ftmp);
				spider.tur_head.angles_y -= ftmp;

				if(player.movement_x != 0)
				{
					if(player.movement_x > 0)
					{
						player.movement_x = 1;
						if(spider.flags & FL_ONGROUND)
							spider.frame = 0;
					}
					else if(player.movement_x < 0)
					{
						player.movement_x = -1;
						if(spider.flags & FL_ONGROUND)
							spider.frame = 1;
					}
					player.movement_y = 0;
					float oldvelz = spider.velocity_z;
					movelib_move_simple(normalize(v_forward * player.movement_x),((player.BUTTON_JUMP) ? autocvar_g_vehicle_spiderbot_speed_run : autocvar_g_vehicle_spiderbot_speed_walk),autocvar_g_vehicle_spiderbot_movement_inertia);
					spider.velocity_z = oldvelz;
					float g = ((autocvar_sv_gameplayfix_gravityunaffectedbyticrate) ? 0.5 : 1);
					if(spider.velocity_z <= 20) // not while jumping
						spider.velocity_z -= g * sys_frametime * autocvar_sv_gravity;
					if(spider.flags & FL_ONGROUND)
					if(self.sound_nexttime < time || self.delay != 1)
					{
						self.delay = 1;
						self.sound_nexttime = time + 6.486500; //soundlength("vehicles/spiderbot_walk.wav");
						sound (self, CH_TRIGGER_SINGLE, SND_VEH_SPIDERBOT_WALK, VOL_VEHICLEENGINE, ATTEN_NORM);
						//dprint("spiderbot_walk:", ftos(soundlength("vehicles/spiderbot_walk.wav")), "\n");
					}
				}
				else if(player.movement_y != 0)
				{
					if(player.movement_y < 0)
					{
						player.movement_y = -1;
						if(spider.flags & FL_ONGROUND)
							spider.frame = 2;
					}
					else if(player.movement_y > 0)
					{
						player.movement_y = 1;
						if(spider.flags & FL_ONGROUND)
							spider.frame = 3;
					}

					float oldvelz = spider.velocity_z;
					movelib_move_simple(normalize(v_right * player.movement_y),autocvar_g_vehicle_spiderbot_speed_strafe,autocvar_g_vehicle_spiderbot_movement_inertia);
					spider.velocity_z = oldvelz;
					float g = ((autocvar_sv_gameplayfix_gravityunaffectedbyticrate) ? 0.5 : 1);
					if(spider.velocity_z <= 20) // not while jumping
						spider.velocity_z -= g * sys_frametime * autocvar_sv_gravity;
					if(spider.flags & FL_ONGROUND)
					if(self.sound_nexttime < time || self.delay != 2)
					{
						self.delay = 2;
						self.sound_nexttime = time + 6.486500; //soundlength("vehicles/spiderbot_strafe.wav");
						sound (self, CH_TRIGGER_SINGLE, SND_VEH_SPIDERBOT_STRAFE, VOL_VEHICLEENGINE, ATTEN_NORM);
						//dprint("spiderbot_strafe:", ftos(soundlength("vehicles/spiderbot_strafe.wav")), "\n");
					}
				}
			}
		}
	}

	self.angles_x = bound(-autocvar_g_vehicle_spiderbot_tiltlimit, self.angles_x, autocvar_g_vehicle_spiderbot_tiltlimit);
	self.angles_z = bound(-autocvar_g_vehicle_spiderbot_tiltlimit, self.angles_z, autocvar_g_vehicle_spiderbot_tiltlimit);

	if(!forbidWeaponUse(player))
	if(player.BUTTON_ATCK)
	{
		spider.cnt = time;
		if(spider.vehicle_ammo1 >= autocvar_g_vehicle_spiderbot_minigun_ammo_cost && spider.tur_head.attack_finished_single <= time)
		{
			entity gun;
			vector v;
			spider.misc_bulletcounter += 1;

			setself(player);

			gun = (spider.misc_bulletcounter % 2) ? spider.gun1 : spider.gun2;

			v = gettaginfo(gun, gettagindex(gun, "barrels"));
			v_forward = normalize(v_forward);
			v += v_forward * 50;

			fireBullet(v, v_forward, autocvar_g_vehicle_spiderbot_minigun_spread, autocvar_g_vehicle_spiderbot_minigun_solidpenetration,
                                autocvar_g_vehicle_spiderbot_minigun_damage, autocvar_g_vehicle_spiderbot_minigun_force, DEATH_VH_SPID_MINIGUN, 0);

			sound (gun, CH_WEAPON_A, SND_UZI_FIRE, VOL_BASE, ATTEN_NORM);
			//trailparticles(self, _particleeffectnum("spiderbot_minigun_trail"), v, trace_endpos);
			pointparticles(particleeffectnum(EFFECT_SPIDERBOT_MINIGUN_MUZZLEFLASH), v, v_forward * 2500, 1);

			setself(spider);

			spider.vehicle_ammo1 -= autocvar_g_vehicle_spiderbot_minigun_ammo_cost;
			spider.tur_head.attack_finished_single = time + autocvar_g_vehicle_spiderbot_minigun_refire;
			player.vehicle_ammo1 = (spider.vehicle_ammo1 / autocvar_g_vehicle_spiderbot_minigun_ammo_max) * 100;
			spider.gun1.angles_z += 45;
			spider.gun2.angles_z -= 45;
			if(spider.gun1.angles_z >= 360)
			{
				spider.gun1.angles_z = 0;
				spider.gun2.angles_z = 0;
			}
		}
	}
	else
		vehicles_regen(spider.cnt, vehicle_ammo1, autocvar_g_vehicle_spiderbot_minigun_ammo_max,
										   autocvar_g_vehicle_spiderbot_minigun_ammo_regen_pause,
										   autocvar_g_vehicle_spiderbot_minigun_ammo_regen, frametime, false);


	spiderbot_rocket_do();

	if(self.vehicle_flags  & VHF_SHIELDREGEN)
		vehicles_regen(spider.dmg_time, vehicle_shield, autocvar_g_vehicle_spiderbot_shield, autocvar_g_vehicle_spiderbot_shield_regen_pause, autocvar_g_vehicle_spiderbot_shield_regen, frametime, true);

	if(self.vehicle_flags  & VHF_HEALTHREGEN)
		vehicles_regen(spider.dmg_time, vehicle_health, autocvar_g_vehicle_spiderbot_health, autocvar_g_vehicle_spiderbot_health_regen_pause, autocvar_g_vehicle_spiderbot_health_regen, frametime, false);

	player.BUTTON_ATCK = player.BUTTON_ATCK2 = 0;
	//player.vehicle_ammo2 = spider.tur_head.frame;
	player.vehicle_ammo2 = (9 - spider.tur_head.frame) / 8 * 100; // Percentage, like ammo1

	if(spider.gun2.cnt <= time)
		player.vehicle_reload2 = 100;
	else
		player.vehicle_reload2 = 100 - ((spider.gun2.cnt - time) / spider.attack_finished_single) * 100;

	setorigin(player, spider.origin + '0 0 1' * spider.maxs_z);
	player.velocity = spider.velocity;

	VEHICLE_UPDATE_PLAYER(player, health, spiderbot);

	if(self.vehicle_flags & VHF_HASSHIELD)
		VEHICLE_UPDATE_PLAYER(player, shield, spiderbot);

	setself(player);
	return 1;
}

void spiderbot_exit(float eject)
{SELFPARAM();
	entity e;
	vector spot;

	e = findchain(classname,"spiderbot_rocket");
	while(e)
	{
		if(e.owner == self.owner)
		{
			e.realowner = self.owner;
			e.owner = world;
		}
		e = e.chain;
	}

	self.think = vehicles_think;
	self.nextthink = time;
	self.frame = 5;
	self.movetype = MOVETYPE_WALK;

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
		if(vlen(self.velocity) > autocvar_g_vehicle_spiderbot_speed_strafe)
		{
			self.owner.velocity = normalize(self.velocity) * vlen(self.velocity);
			self.owner.velocity_z += 200;
			spot = self.origin + v_forward * 128 + '0 0 64';
			spot = vehicles_findgoodexit(spot);
		}
		else
		{
			self.owner.velocity = self.velocity * 0.5;
			self.owner.velocity_z += 10;
			spot = self.origin + v_forward * 256 + '0 0 64';
			spot = vehicles_findgoodexit(spot);
		}
		self.owner.oldvelocity = self.owner.velocity;
		setorigin(self.owner , spot);
	}

	antilag_clear(self.owner);
	self.owner = world;
}

void spiderbot_headfade()
{SELFPARAM();
	self.think = spiderbot_headfade;
	self.nextthink = self.fade_time;
	self.alpha = 1 - (time - self.fade_time) * self.fade_rate;

	if(self.cnt < time || self.alpha < 0.1)
	{
		if(self.alpha > 0.1)
		{
			sound (self, CH_SHOTS, SND_ROCKET_IMPACT, VOL_BASE, ATTEN_NORM);
			Send_Effect(EFFECT_EXPLOSION_BIG, self.origin + '0 0 100', '0 0 0', 1);
		}
		remove(self);
	}
}

void spiderbot_blowup()
{SELFPARAM();
	if(self.cnt > time)
	{
		if(random() < 0.1)
		{
			sound (self, CH_SHOTS, SND_ROCKET_IMPACT, VOL_BASE, ATTEN_NORM);
			Send_Effect(EFFECT_EXPLOSION_SMALL, randomvec() * 80 + (self.origin + '0 0 100'), '0 0 0', 1);
		}
		self.nextthink = time + 0.1;
		return;
	}

	entity h, g1, g2, b;
	b = spawn();
	h = spawn();
	g1 = spawn();
	g2 = spawn();

	setmodel(b, MDL_VEH_SPIDERBOT_BODY);
	setmodel(h, MDL_VEH_SPIDERBOT_TOP);
	setmodel(g1, MDL_VEH_SPIDERBOT_GUN);
	setmodel(g2, MDL_VEH_SPIDERBOT_GUN);

	setorigin(b, self.origin);
	b.frame = 11;
	b.angles = self.angles;
	setsize(b, self.mins, self.maxs);

	setorigin(h, gettaginfo(self, gettagindex(self, "tag_head")));
	h.movetype = MOVETYPE_BOUNCE;
	h.solid = SOLID_BBOX;
	h.velocity = v_up * (500 + random() * 500) + randomvec() * 128;
	h.modelflags = MF_ROCKET;
	h.effects = EF_FLAME | EF_LOWPRECISION;
	h.avelocity = randomvec() * 360;

	h.alpha = 1;
	h.cnt = time + (3.5 * random());
	h.fade_rate = 1 / min(self.respawntime, 10);
	h.fade_time = time;
	h.think = spiderbot_headfade;
	h.nextthink = time;

	setorigin(g1, gettaginfo(self.tur_head, gettagindex(self.tur_head, "tag_hardpoint01")));
	g1.movetype = MOVETYPE_TOSS;
	g1.solid = SOLID_CORPSE;
	g1.velocity = v_forward * 700 + (randomvec() * 32);
	g1.avelocity = randomvec() * 180;

	setorigin(g2, gettaginfo(self.tur_head, gettagindex(self.tur_head, "tag_hardpoint02")));
	g2.movetype = MOVETYPE_TOSS;
	g2.solid = SOLID_CORPSE;
	g2.velocity = v_forward * 700 + (randomvec() * 32);
	g2.avelocity = randomvec() * 180;

	h.colormod = b.colormod = g1.colormod = g2.colormod = '-2 -2 -2';

	SUB_SetFade(b,  time + 5, min(self.respawntime, 1));
	//SUB_SetFade(h,  time, min(self.respawntime, 10));
	SUB_SetFade(g1, time, min(self.respawntime, 10));
	SUB_SetFade(g2, time, min(self.respawntime, 10));

	RadiusDamage (self, self.enemy, 250, 15, 250, world, world, 250, DEATH_VH_SPID_DEATH, world);

	self.alpha = self.tur_head.alpha = self.gun1.alpha = self.gun2.alpha = -1;
	self.movetype = MOVETYPE_NONE;
	self.deadflag = DEAD_DEAD;
	self.solid = SOLID_NOT;
	self.tur_head.effects &= ~EF_FLAME;
	self.vehicle_hudmodel.viewmodelforclient = self;
}

bool spiderbot_impulse(int _imp)
{SELFPARAM();
	switch(_imp)
	{
		case 1:
		case 230:
			self.vehicle.vehicle_weapon2mode = SBRM_VOLLY;
			CSQCVehicleSetup(self, 0);
			return true;
		case 2:
		case 231:
			self.vehicle.vehicle_weapon2mode = SBRM_GUIDE;
			CSQCVehicleSetup(self, 0);
			return true;
		case 3:
		case 232:
		case 251:
			self.vehicle.vehicle_weapon2mode = SBRM_ARTILLERY;
			CSQCVehicleSetup(self, 0);
			return true;

		case 10:
		case 15:
		case 18:
			self.vehicle.vehicle_weapon2mode += 1;
			if(self.vehicle.vehicle_weapon2mode > SBRM_LAST)
				self.vehicle.vehicle_weapon2mode = SBRM_FIRST;

			//centerprint(self, strcat("Rocket mode is ", ftos(self.vehicle.vehicle_weapon2mode)));
			CSQCVehicleSetup(self, 0);
			return true;
		case 11:
		case 12:
		case 16:
		case 19:
			self.vehicle.vehicle_weapon2mode -= 1;
			if(self.vehicle.vehicle_weapon2mode < SBRM_FIRST)
				self.vehicle.vehicle_weapon2mode = SBRM_LAST;

			//centerprint(self, strcat("Rocket mode is ", ftos(self.vehicle.vehicle_weapon2mode)));
			CSQCVehicleSetup(self, 0);
			return true;

		/*
		case 17: // toss gun, could be used to exit?
			break;
		case 20: // Manual minigun reload?
			break;
		*/
	}
	return false;
}

spawnfunc(vehicle_spiderbot)
{
	if(!autocvar_g_vehicle_spiderbot) { remove(self); return; }
	if(!vehicle_initialize(VEH_SPIDERBOT, false)) { remove(self); return; }
}

float v_spiderbot(float req)
{SELFPARAM();
	switch(req)
	{
		case VR_IMPACT:
		{
			if(autocvar_g_vehicle_spiderbot_bouncepain)
				vehicles_impact(autocvar_g_vehicle_spiderbot_bouncepain_x, autocvar_g_vehicle_spiderbot_bouncepain_y, autocvar_g_vehicle_spiderbot_bouncepain_z);

			return true;
		}
		case VR_ENTER:
		{
			self.vehicle_weapon2mode = SBRM_GUIDE;
			self.movetype = MOVETYPE_WALK;
			CSQCVehicleSetup(self.owner, 0);
			self.owner.vehicle_health = (self.vehicle_health / autocvar_g_vehicle_spiderbot_health) * 100;
			self.owner.vehicle_shield = (self.vehicle_shield / autocvar_g_vehicle_spiderbot_shield) * 100;

			if(self.owner.flagcarried)
			{
				setattachment(self.owner.flagcarried, self.tur_head, "");
				setorigin(self.owner.flagcarried, '-20 0 120');
			}

			return true;
		}
		case VR_THINK:
		{
			if(self.flags & FL_ONGROUND)
				movelib_beak_simple(autocvar_g_vehicle_spiderbot_speed_stop);

			return true;
		}
		case VR_DEATH:
		{
			self.health				= 0;
			self.event_damage		= func_null;
			self.takedamage			= DAMAGE_NO;
			self.touch				= func_null;
			self.cnt				= 3.4 + time + random() * 2;
			self.think				= spiderbot_blowup;
			self.nextthink			= time;
			self.deadflag			= DEAD_DYING;
			self.frame				= 5;
			self.tur_head.effects  |= EF_FLAME;
			self.colormod			= self.tur_head.colormod = '-1 -1 -1';
			self.frame				= 10;
			self.movetype			= MOVETYPE_TOSS;

			CSQCModel_UnlinkEntity(); // networking the death scene would be a nightmare

			return true;
		}
		case VR_SPAWN:
		{
			if(!self.gun1)
			{
				self.vehicles_impulse = spiderbot_impulse;
				self.gun1 = spawn();
				self.gun2 = spawn();
				setmodel(self.gun1, MDL_VEH_SPIDERBOT_GUN);
				setmodel(self.gun2, MDL_VEH_SPIDERBOT_GUN);
				setattachment(self.gun1, self.tur_head, "tag_hardpoint01");
				setattachment(self.gun2, self.tur_head, "tag_hardpoint02");
				self.gravity = 2;
				self.mass = 5000;
			}

			self.frame = 5;
			self.tur_head.frame = 1;
			self.movetype = MOVETYPE_WALK;
			self.solid = SOLID_SLIDEBOX;
			self.alpha = self.tur_head.alpha = self.gun1.alpha = self.gun2.alpha = 1;
			self.tur_head.angles = '0 0 0';
			self.vehicle_exit = spiderbot_exit;

			setorigin(self, self.pos1 + '0 0 128');
			self.angles = self.pos2;
			self.damageforcescale = 0.03;
			self.vehicle_health = autocvar_g_vehicle_spiderbot_health;
			self.vehicle_shield = autocvar_g_vehicle_spiderbot_shield;

			self.PlayerPhysplug = spiderbot_frame;

			return true;
		}
		case VR_SETUP:
		{
			if(autocvar_g_vehicle_spiderbot_shield)
				self.vehicle_flags |= VHF_HASSHIELD;

			if(autocvar_g_vehicle_spiderbot_shield_regen)
				self.vehicle_flags |= VHF_SHIELDREGEN;

			if(autocvar_g_vehicle_spiderbot_health_regen)
				self.vehicle_flags |= VHF_HEALTHREGEN;

			self.respawntime = autocvar_g_vehicle_spiderbot_respawntime;
			self.vehicle_health = autocvar_g_vehicle_spiderbot_health;
			self.vehicle_shield = autocvar_g_vehicle_spiderbot_shield;
			self.max_health = self.vehicle_health;
			self.pushable = true; // spiderbot can use jumppads

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
float autocvar_cl_vehicle_spiderbot_cross_alpha = 0.6;
float autocvar_cl_vehicle_spiderbot_cross_size = 1;

float v_spiderbot(float req)
{
	switch(req)
	{
		case VR_HUD:
		{
			string crosshair;

			switch(weapon2mode)
			{
				case SBRM_VOLLY:     crosshair = vCROSS_BURST; break;
				case SBRM_GUIDE:     crosshair = vCROSS_GUIDE; break;
				case SBRM_ARTILLERY: crosshair = vCROSS_RAIN;  break;
				default:             crosshair = vCROSS_BURST;
			}

			Vehicles_drawHUD(VEH_SPIDERBOT.m_icon, "vehicle_spider_weapon1", "vehicle_spider_weapon2",
							 "vehicle_icon_ammo1", autocvar_hud_progressbar_vehicles_ammo1_color,
							 "vehicle_icon_ammo2", autocvar_hud_progressbar_vehicles_ammo2_color,
							 crosshair);
			return true;
		}
		case VR_SETUP:
		{
			AuxiliaryXhair[0].axh_image = vCROSS_HINT; // Minigun1
			AuxiliaryXhair[1].axh_image = vCROSS_HINT; // Minigun2

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
