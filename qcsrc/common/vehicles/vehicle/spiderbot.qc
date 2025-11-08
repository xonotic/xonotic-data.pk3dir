#include "spiderbot.qh"

#if defined(SVQC)
	#include <common/gametypes/gametype/ctf/sv_ctf.qh>
#elif defined(MENUQC)
	#include "raptor.qh"
#endif

#ifdef GAMEQC

const int SBRM_FIRST = 1;
const int SBRM_VOLLY = 1;
const int SBRM_GUIDE = 2;
const int SBRM_ARTILLERY = 3;
const int SBRM_LAST = 3;

#ifdef SVQC
bool autocvar_g_vehicle_spiderbot = true;

float autocvar_g_vehicle_spiderbot_respawntime = 45;

float autocvar_g_vehicle_spiderbot_speed_stop = 50;
float autocvar_g_vehicle_spiderbot_speed_strafe = 400;
float autocvar_g_vehicle_spiderbot_speed_walk = 500;
float autocvar_g_vehicle_spiderbot_turnspeed = 90;
float autocvar_g_vehicle_spiderbot_turnspeed_strafe = 300;
float autocvar_g_vehicle_spiderbot_movement_inertia = 0.15;

float autocvar_g_vehicle_spiderbot_springlength = 150;
float autocvar_g_vehicle_spiderbot_springup = 20;
float autocvar_g_vehicle_spiderbot_springblend = 0.1;
float autocvar_g_vehicle_spiderbot_tiltlimit = 90;

float autocvar_g_vehicle_spiderbot_head_pitchlimit_down = -20;
float autocvar_g_vehicle_spiderbot_head_pitchlimit_up = 30;
float autocvar_g_vehicle_spiderbot_head_turnlimit = 90;
float autocvar_g_vehicle_spiderbot_head_turnspeed = 110;

int autocvar_g_vehicle_spiderbot_health = 800;
float autocvar_g_vehicle_spiderbot_health_regen = 10;
float autocvar_g_vehicle_spiderbot_health_regen_pause = 5;

int autocvar_g_vehicle_spiderbot_shield = 200;
float autocvar_g_vehicle_spiderbot_shield_regen = 25;
float autocvar_g_vehicle_spiderbot_shield_regen_pause = 0.35;

// 'minspeed_for_pain speedchange_to_pain_factor max_damage'
vector autocvar_g_vehicle_spiderbot_bouncepain = '0 0 0';

.float jump_delay;
bool spiderbot_frame(entity this, float dt)
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

	PHYS_INPUT_BUTTON_ZOOM(this) = false;
	PHYS_INPUT_BUTTON_CROUCH(this) = false;
	for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	{
		.entity weaponentity = weaponentities[slot];
		this.(weaponentity).m_switchweapon = WEP_Null;
	}
	STAT(VEHICLESTAT_W2MODE, this) = STAT(VEHICLESTAT_W2MODE, vehic);


#if 1 // 0 to enable per-gun impact aux crosshairs
	// Avarage gun impact point's -> aux cross
	vector ad = gettaginfo(vehic.tur_head, gettagindex(vehic.tur_head, "tag_hardpoint01"));
	vector vf = v_forward;
	ad += gettaginfo(vehic.tur_head, gettagindex(vehic.tur_head, "tag_hardpoint02"));
	vf += v_forward;
	ad = ad * 0.5;
	v_forward = vf * 0.5;
	traceline(ad, ad + v_forward * max_shot_distance, MOVE_NORMAL, vehic);
	UpdateAuxiliaryXhair(this, trace_endpos, ('1 0 0' * this.vehicle_reload1) + ('0 1 0' * (1 - this.vehicle_reload1)), 0);
#else
	vector ad = gettaginfo(vehic.gun1, gettagindex(vehic.gun1, "barrels"));
	traceline(ad, ad + v_forward * max_shot_distance, MOVE_NORMAL, vehic);
	UpdateAuxiliaryXhair(this, trace_endpos, ('1 0 0' * this.vehicle_reload1) + ('0 1 0' * (1 - this.vehicle_reload1)), 0);
	vector vf = ad;
	ad = gettaginfo(vehic.gun2, gettagindex(vehic.gun2, "barrels"));
	traceline(ad, ad + v_forward * max_shot_distance, MOVE_NORMAL, vehic);
	UpdateAuxiliaryXhair(this, trace_endpos, ('1 0 0' * this.vehicle_reload1) + ('0 1 0' * (1 - this.vehicle_reload1)), 1);
	ad = 0.5 * (ad + vf);
#endif

	crosshair_trace(this);
	ad = vectoangles(normalize(trace_endpos - ad));
	ad = AnglesTransform_ToAngles(AnglesTransform_LeftDivide(AnglesTransform_FromAngles(vehic.angles), AnglesTransform_FromAngles(ad))) - vehic.tur_head.angles;
	ad = AnglesTransform_Normalize(ad, true);
	//UpdateAuxiliaryXhair(this, trace_endpos, ('1 0 0' * this.vehicle_reload2) + ('0 1 0' * (1 - this.vehicle_reload2)), 2);

	// Rotate head
	float ftmp = autocvar_g_vehicle_spiderbot_head_turnspeed * PHYS_INPUT_FRAMETIME;
	ad_y = bound(-ftmp, ad_y, ftmp);
	vehic.tur_head.angles_y = bound(autocvar_g_vehicle_spiderbot_head_turnlimit * -1, vehic.tur_head.angles_y + ad_y, autocvar_g_vehicle_spiderbot_head_turnlimit);

	// Pitch head
	ad_x = bound(ftmp * -1, ad_x, ftmp);
	vehic.tur_head.angles_x = bound(autocvar_g_vehicle_spiderbot_head_pitchlimit_down, vehic.tur_head.angles_x + ad_x, autocvar_g_vehicle_spiderbot_head_pitchlimit_up);


	//fixedmakevectors(vehic.angles);
	makevectors(vehic.angles + '-2 0 0' * vehic.angles_x);

	movelib_groundalign4point(vehic, autocvar_g_vehicle_spiderbot_springlength, autocvar_g_vehicle_spiderbot_springup, autocvar_g_vehicle_spiderbot_springblend, autocvar_g_vehicle_spiderbot_tiltlimit);

	if(IS_ONGROUND(vehic))
		vehic.jump_delay = time; // reset now so movement can begin

	//if(IS_ONGROUND(vehic))
	{
		if(IS_ONGROUND(vehic))
		if(vehic.frame == 4 && vehic.tur_head.wait != 0)
		{
			sound (vehic, CH_TRIGGER_SINGLE, SND_VEH_SPIDERBOT_LAND, VOL_VEHICLEENGINE, ATTEN_NORM);
			vehic.frame = 5;
		}

		if (!PHYS_INPUT_BUTTON_JUMP(this))
			vehic.button2 = false;

		if((IS_ONGROUND(vehic)) && PHYS_INPUT_BUTTON_JUMP(this) && !vehic.button2 && vehic.tur_head.wait < time)
		{
			sound (vehic, CH_TRIGGER_SINGLE, SND_VEH_SPIDERBOT_JUMP, VOL_VEHICLEENGINE, ATTEN_NORM);
			//dprint("spiderbot_jump:", ftos(soundlength("vehicles/spiderbot_jump.wav")), "\n");
			vehic.delay = 0;

			vehic.tur_head.wait = time + 2;
			vehic.jump_delay = time + 2;
			vehic.button2 = true; // set spider's jump
			//PHYS_INPUT_BUTTON_JUMP(this) = false;

			vector movefix = '0 0 0';
			if(CS(this).movement_x > 0) movefix_x = 1;
			if(CS(this).movement_x < 0) movefix_x = -1;
			if(CS(this).movement_y > 0) movefix_y = 1;
			if(CS(this).movement_y < 0) movefix_y = -1;

			vector rt = movefix_y * v_right;
			vector sd = movefix_x * v_forward;
			if(movefix_y == 0 && movefix_x == 0)
				sd = v_forward; // always do forward

			UNSET_ONGROUND(vehic);

			vehic.velocity = sd * 700 + rt * 600 + v_up * 600;
			vehic.frame = 4;
		}
		else if(time >= vehic.jump_delay)
		{
			if(!CS(this).movement)
			{
				if(IS_ONGROUND(vehic))
				{
					if(vehic.sound_nexttime < time || vehic.delay != 3)
					{
						vehic.delay = 3;
						vehic.sound_nexttime = time + 6.486500; //soundlength("vehicles/spiderbot_idle.wav");
						//dprint("spiderbot_idle:", ftos(soundlength("vehicles/spiderbot_idle.wav")), "\n");
						sound (vehic, CH_TRIGGER_SINGLE, SND_VEH_SPIDERBOT_IDLE, VOL_VEHICLEENGINE, ATTEN_NORM);
					}
					movelib_brake_simple(vehic, autocvar_g_vehicle_spiderbot_speed_stop);
					vehic.frame = 5;
				}
			}
			else
			{
				// Turn Body
				if(CS(this).movement_x == 0 && CS(this).movement_y != 0)
					ftmp = autocvar_g_vehicle_spiderbot_turnspeed_strafe * PHYS_INPUT_FRAMETIME;
				else
					ftmp = autocvar_g_vehicle_spiderbot_turnspeed * PHYS_INPUT_FRAMETIME;

				ftmp = bound(-ftmp, vehic.tur_head.angles_y, ftmp);
				vehic.angles_y = anglemods(vehic.angles_y + ftmp);
				vehic.tur_head.angles_y -= ftmp;

				if(CS(this).movement_x != 0)
				{
					if(CS(this).movement_x > 0)
					{
						CS(this).movement_x = 1;
						if(IS_ONGROUND(vehic))
							vehic.frame = 0;
					}
					else if(CS(this).movement_x < 0)
					{
						CS(this).movement_x = -1;
						if(IS_ONGROUND(vehic))
							vehic.frame = 1;
					}
					CS(this).movement_y = 0;
					float oldvelz = vehic.velocity_z;
					movelib_move_simple(vehic, normalize(v_forward * CS(this).movement_x), autocvar_g_vehicle_spiderbot_speed_walk, autocvar_g_vehicle_spiderbot_movement_inertia);
					vehic.velocity_z = oldvelz;
					float g = ((autocvar_sv_gameplayfix_gravityunaffectedbyticrate) ? 0.5 : 1);
					if(vehic.velocity_z <= 20) // not while jumping
						vehic.velocity_z -= g * PHYS_INPUT_FRAMETIME * autocvar_sv_gravity;
					if(IS_ONGROUND(vehic))
					if(vehic.sound_nexttime < time || vehic.delay != 1)
					{
						vehic.delay = 1;
						vehic.sound_nexttime = time + 6.486500; //soundlength("vehicles/spiderbot_walk.wav");
						sound (vehic, CH_TRIGGER_SINGLE, SND_VEH_SPIDERBOT_WALK, VOL_VEHICLEENGINE, ATTEN_NORM);
						//dprint("spiderbot_walk:", ftos(soundlength("vehicles/spiderbot_walk.wav")), "\n");
					}
				}
				else if(CS(this).movement_y != 0)
				{
					if(CS(this).movement_y < 0)
					{
						CS(this).movement_y = -1;
						if(IS_ONGROUND(vehic))
							vehic.frame = 2;
					}
					else if(CS(this).movement_y > 0)
					{
						CS(this).movement_y = 1;
						if(IS_ONGROUND(vehic))
							vehic.frame = 3;
					}

					float oldvelz = vehic.velocity_z;
					movelib_move_simple(vehic, normalize(v_right * CS(this).movement_y),autocvar_g_vehicle_spiderbot_speed_strafe,autocvar_g_vehicle_spiderbot_movement_inertia);
					vehic.velocity_z = oldvelz;
					float g = ((autocvar_sv_gameplayfix_gravityunaffectedbyticrate) ? 0.5 : 1);
					if(vehic.velocity_z <= 20) // not while jumping
						vehic.velocity_z -= g * PHYS_INPUT_FRAMETIME * autocvar_sv_gravity;
					if(IS_ONGROUND(vehic))
					if(vehic.sound_nexttime < time || vehic.delay != 2)
					{
						vehic.delay = 2;
						vehic.sound_nexttime = time + 6.486500; //soundlength("vehicles/spiderbot_strafe.wav");
						sound (vehic, CH_TRIGGER_SINGLE, SND_VEH_SPIDERBOT_STRAFE, VOL_VEHICLEENGINE, ATTEN_NORM);
						//dprint("spiderbot_strafe:", ftos(soundlength("vehicles/spiderbot_strafe.wav")), "\n");
					}
				}
			}
		}
	}

	vehic.angles_x = bound(-autocvar_g_vehicle_spiderbot_tiltlimit, vehic.angles_x, autocvar_g_vehicle_spiderbot_tiltlimit);
	vehic.angles_z = bound(-autocvar_g_vehicle_spiderbot_tiltlimit, vehic.angles_z, autocvar_g_vehicle_spiderbot_tiltlimit);

	if(!weaponLocked(this) && !weaponUseForbidden(this))
	if(PHYS_INPUT_BUTTON_ATCK(this))
	{
		vehic.cnt = time;
		if(vehic.vehicle_ammo1 >= autocvar_g_vehicle_spiderbot_minigun_ammo_cost && vehic.tur_head.attack_finished_single[0] <= time)
		{
			entity gun;
			vector v;
			vehic.misc_bulletcounter += 1;

			gun = (vehic.misc_bulletcounter % 2) ? vehic.gun1 : vehic.gun2;

			v = gettaginfo(gun, gettagindex(gun, "barrels"));
			v_forward = normalize(v_forward);
			v += v_forward * 50;

			.entity weaponentity = weaponentities[0]; // TODO: unhardcode
			fireBullet(this, weaponentity, v, v_forward, autocvar_g_vehicle_spiderbot_minigun_spread, autocvar_g_vehicle_spiderbot_minigun_solidpenetration,
				autocvar_g_vehicle_spiderbot_minigun_damage, 0, autocvar_g_vehicle_spiderbot_minigun_force, DEATH_VH_SPID_MINIGUN.m_id, EFFECT_BULLET);

			sound (gun, CH_WEAPON_A, SND_VEH_SPIDERBOT_MINIGUN_FIRE, VOL_BASE, ATTEN_NORM);
			//trailparticles(this, _particleeffectnum("spiderbot_minigun_trail"), v, trace_endpos);
			Send_Effect(EFFECT_SPIDERBOT_MINIGUN_MUZZLEFLASH, v, v_forward * 2500, 1);

			vehic.vehicle_ammo1 -= autocvar_g_vehicle_spiderbot_minigun_ammo_cost;
			vehic.tur_head.attack_finished_single[0] = time + autocvar_g_vehicle_spiderbot_minigun_refire;
			this.vehicle_ammo1 = (vehic.vehicle_ammo1 / autocvar_g_vehicle_spiderbot_minigun_ammo_max) * 100;
			vehic.gun1.angles_z += 45;
			vehic.gun2.angles_z -= 45;
			if(vehic.gun1.angles_z >= 360)
			{
				vehic.gun1.angles_z = 0;
				vehic.gun2.angles_z = 0;
			}
		}
	}
	else
		vehicles_regen(vehic, vehic.cnt, vehicle_ammo1, autocvar_g_vehicle_spiderbot_minigun_ammo_max,
										   autocvar_g_vehicle_spiderbot_minigun_ammo_regen_pause,
										   autocvar_g_vehicle_spiderbot_minigun_ammo_regen, dt, false);


	spiderbot_rocket_do(vehic);

	if(vehic.vehicle_flags  & VHF_SHIELDREGEN)
		vehicles_regen(vehic, vehic.dmg_time, vehicle_shield, autocvar_g_vehicle_spiderbot_shield, autocvar_g_vehicle_spiderbot_shield_regen_pause, autocvar_g_vehicle_spiderbot_shield_regen, dt, true);

	if(vehic.vehicle_flags  & VHF_HEALTHREGEN)
		vehicles_regen_resource(vehic, vehic.dmg_time, vehicle_health, autocvar_g_vehicle_spiderbot_health, autocvar_g_vehicle_spiderbot_health_regen_pause, autocvar_g_vehicle_spiderbot_health_regen, dt, false, RES_HEALTH);

	PHYS_INPUT_BUTTON_ATCK(this) = PHYS_INPUT_BUTTON_ATCK2(this) = false;
	//this.vehicle_ammo2 = vehic.tur_head.frame;
	this.vehicle_ammo2 = (9 - vehic.tur_head.frame) / 8 * 100; // Percentage, like ammo1

	if(vehic.gun2.cnt <= time)
		this.vehicle_reload2 = 100;
	else
		this.vehicle_reload2 = 100 - ((vehic.gun2.cnt - time) / vehic.attack_finished_single[0]) * 100;

	setorigin(this, vehic.origin + '0 0 1' * vehic.maxs_z);
	this.oldorigin = this.origin; // negate fall damage
	this.velocity = vehic.velocity;

	VEHICLE_UPDATE_PLAYER_RESOURCE(this, vehic, health, spiderbot, RES_HEALTH);

	if(vehic.vehicle_flags & VHF_HASSHIELD)
		VEHICLE_UPDATE_PLAYER(this, vehic, shield, spiderbot);
}

void spiderbot_exit(entity this, int eject)
{
	entity player = this.owner;

	IL_EACH(g_projectiles, it.owner == player && it.classname == "spiderbot_rocket",
	{
		it.realowner = player;
		it.owner = NULL;
	});

	setthink(this, vehicles_think);
	this.nextthink = time;
	this.frame = 5;
	set_movetype(this, MOVETYPE_WALK);

	if(!player)
	{
		this.owner = NULL; // reset owner anyway?
		return;
	}

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
		if(vdist(this.velocity, >, autocvar_g_vehicle_spiderbot_speed_strafe))
		{
			player.velocity = normalize(this.velocity) * vlen(this.velocity);
			player.velocity_z += 200;
			spot = this.origin + v_forward * 128 + '0 0 64';
			spot = vehicles_findgoodexit(this, player, spot);
		}
		else
		{
			player.velocity = this.velocity * 0.5;
			player.velocity_z += 10;
			spot = this.origin + v_forward * 256 + '0 0 64';
			spot = vehicles_findgoodexit(this, player, spot);
		}
		player.oldvelocity = player.velocity;
		setorigin(player, spot);
	}

	antilag_clear(player, CS(player));
	this.owner = NULL;
}

void spiderbot_headfade(entity this)
{
	setthink(this, spiderbot_headfade);
	this.nextthink = this.fade_time;
	this.alpha = 1 - (time - this.fade_time) * this.fade_rate;

	if(this.cnt < time || this.alpha < 0.1)
	{
		if(this.alpha > 0.1)
		{
			sound (this, CH_SHOTS, SND_ROCKET_IMPACT, VOL_BASE, ATTEN_NORM);
			Send_Effect(EFFECT_EXPLOSION_BIG, this.origin + '0 0 100', '0 0 0', 1);
		}
		delete(this);
	}
}

void spiderbot_blowup(entity this)
{
	if(this.cnt > time)
	{
		if(random() < 0.1)
		{
			sound (this, CH_SHOTS, SND_ROCKET_IMPACT, VOL_BASE, ATTEN_NORM);
			Send_Effect(EFFECT_EXPLOSION_SMALL, randomvec() * 80 + (this.origin + '0 0 100'), '0 0 0', 1);
		}
		this.nextthink = time + 0.1;
		return;
	}

	entity h = new(spiderbot_top), g1 = new(spiderbot_gun), g2 = new(spiderbot_gun), b = new(spiderbot_body);

	setmodel(b, MDL_VEH_SPIDERBOT_BODY);
	setmodel(h, MDL_VEH_SPIDERBOT_TOP);
	setmodel(g1, MDL_VEH_SPIDERBOT_GUN);
	setmodel(g2, MDL_VEH_SPIDERBOT_GUN);

	setorigin(b, this.origin);
	b.frame = 11;
	b.angles = this.angles;
	setsize(b, this.mins, this.maxs);

	h.solid = SOLID_BBOX; // before setorigin for immediate area grid linking
	vector org = gettaginfo(this, gettagindex(this, "tag_head"));
	setorigin(h, org);
	set_movetype(h, MOVETYPE_BOUNCE);
	h.velocity = v_up * (500 + random() * 500) + randomvec() * 128;
	h.modelflags = MF_ROCKET;
	h.effects = EF_FLAME | EF_LOWPRECISION;
	h.avelocity = randomvec() * 360;

	h.alpha = 1;
	h.cnt = time + (3.5 * random());
	h.fade_rate = 1 / min(this.respawntime, 10);
	h.fade_time = time;
	setthink(h, spiderbot_headfade);
	h.nextthink = time;

	g1.solid = SOLID_CORPSE; // before setorigin for immediate area grid linking
	org = gettaginfo(this.tur_head, gettagindex(this.tur_head, "tag_hardpoint01"));
	setorigin(g1, org);
	set_movetype(g1, MOVETYPE_TOSS);
	g1.velocity = v_forward * 700 + (randomvec() * 32);
	g1.avelocity = randomvec() * 180;

	g2.solid = SOLID_CORPSE; // before setorigin for immediate area grid linking
	org = gettaginfo(this.tur_head, gettagindex(this.tur_head, "tag_hardpoint02"));
	setorigin(g2, org);
	set_movetype(g2, MOVETYPE_TOSS);
	g2.velocity = v_forward * 700 + (randomvec() * 32);
	g2.avelocity = randomvec() * 180;

	h.colormod = b.colormod = g1.colormod = g2.colormod = '-2 -2 -2';

	SUB_SetFade(b,  time + 5, min(this.respawntime, 1));
	//SUB_SetFade(h,  time, min(this.respawntime, 10));
	SUB_SetFade(g1, time, min(this.respawntime, 10));
	SUB_SetFade(g2, time, min(this.respawntime, 10));

	RadiusDamage (this, this.enemy, 250, 15, 250, NULL, NULL, 250, DEATH_VH_SPID_DEATH.m_id, DMG_NOWEP, NULL);

	this.alpha = this.tur_head.alpha = this.gun1.alpha = this.gun2.alpha = -1;
	set_movetype(this, MOVETYPE_NONE);
	this.deadflag = DEAD_DEAD;
	this.solid = SOLID_NOT;
	this.tur_head.effects &= ~EF_FLAME;
	this.vehicle_hudmodel.viewmodelforclient = this;
}

bool spiderbot_impulse(entity this, int _imp)
{
	switch(_imp)
	{
		case IMP_weapon_group_1.impulse:
			STAT(VEHICLESTAT_W2MODE, this.vehicle) = SBRM_VOLLY;
			CSQCVehicleSetup(this, 0);
			return true;
		case IMP_weapon_group_2.impulse:
			STAT(VEHICLESTAT_W2MODE, this.vehicle) = SBRM_GUIDE;
			CSQCVehicleSetup(this, 0);
			return true;
		case IMP_weapon_group_3.impulse:
			STAT(VEHICLESTAT_W2MODE, this.vehicle) = SBRM_ARTILLERY;
			CSQCVehicleSetup(this, 0);
			return true;

		case IMP_weapon_next_byid.impulse:
		case IMP_weapon_next_bypriority.impulse:
		case IMP_weapon_next_bygroup.impulse:
			STAT(VEHICLESTAT_W2MODE, this.vehicle) += 1;
			if(STAT(VEHICLESTAT_W2MODE, this.vehicle) > SBRM_LAST)
				STAT(VEHICLESTAT_W2MODE, this.vehicle) = SBRM_FIRST;

			//centerprint(this, strcat("Rocket mode is ", ftos(STAT(VEHICLESTAT_W2MODE, this.vehicle))));
			CSQCVehicleSetup(this, 0);
			return true;
		case IMP_weapon_last.impulse:
		case IMP_weapon_prev_byid.impulse:
		case IMP_weapon_prev_bypriority.impulse:
		case IMP_weapon_prev_bygroup.impulse:
			STAT(VEHICLESTAT_W2MODE, this.vehicle) -= 1;
			if(STAT(VEHICLESTAT_W2MODE, this.vehicle) < SBRM_FIRST)
				STAT(VEHICLESTAT_W2MODE, this.vehicle) = SBRM_LAST;

			//centerprint(this, strcat("Rocket mode is ", ftos(STAT(VEHICLESTAT_W2MODE, this.vehicle))));
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

spawnfunc(vehicle_spiderbot)
{
	if(!autocvar_g_vehicle_spiderbot) { delete(this); return; }
	if(!vehicle_initialize(this, VEH_SPIDERBOT, false)) { delete(this); return; }
}

METHOD(Spiderbot, vr_impact, void(Spiderbot thisveh, entity instance))
{
    if(autocvar_g_vehicle_spiderbot_bouncepain)
        vehicles_impact(instance, autocvar_g_vehicle_spiderbot_bouncepain_x, autocvar_g_vehicle_spiderbot_bouncepain_y, autocvar_g_vehicle_spiderbot_bouncepain_z);
}
METHOD(Spiderbot, vr_enter, void(Spiderbot thisveh, entity instance))
{
    STAT(VEHICLESTAT_W2MODE, instance) = SBRM_GUIDE;
    set_movetype(instance, MOVETYPE_WALK);
    CSQCVehicleSetup(instance.owner, 0);
    instance.owner.vehicle_health = (GetResource(instance, RES_HEALTH) / autocvar_g_vehicle_spiderbot_health) * 100;
    instance.owner.vehicle_shield = (instance.vehicle_shield / autocvar_g_vehicle_spiderbot_shield) * 100;

    if(instance.owner.flagcarried)
    {
        setattachment(instance.owner.flagcarried, instance.tur_head, "");
        setorigin(instance.owner.flagcarried, '-20 0 120');
    }
}
METHOD(Spiderbot, vr_think, void(Spiderbot thisveh, entity instance))
{
    if(IS_ONGROUND(instance))
        movelib_brake_simple(instance, autocvar_g_vehicle_spiderbot_speed_stop);
}
METHOD(Spiderbot, vr_death, void(Spiderbot thisveh, entity instance))
{
	SetResourceExplicit(instance, RES_HEALTH, 0);
    instance.event_damage		= func_null;
    instance.takedamage			= DAMAGE_NO;
    settouch(instance, func_null);
    instance.cnt				= 3.4 + time + random() * 2;
    setthink(instance, spiderbot_blowup);
    instance.nextthink			= time;
    instance.deadflag			= DEAD_DYING;
    instance.frame				= 5;
    instance.tur_head.effects  |= EF_FLAME;
    instance.colormod			= instance.tur_head.colormod = '-1 -1 -1';
    instance.frame				= 10;
    set_movetype(instance, MOVETYPE_TOSS);

    CSQCModel_UnlinkEntity(instance); // networking the death scene would be a nightmare
}
METHOD(Spiderbot, vr_spawn, void(Spiderbot thisveh, entity instance))
{
    if(!instance.gun1)
    {
        instance.vehicles_impulse = spiderbot_impulse;
        instance.gun1 = new(spiderbot_gun);
        instance.gun2 = new(spiderbot_gun);
        setmodel(instance.gun1, MDL_VEH_SPIDERBOT_GUN);
        setmodel(instance.gun2, MDL_VEH_SPIDERBOT_GUN);
        setattachment(instance.gun1, instance.tur_head, "tag_hardpoint01");
        setattachment(instance.gun2, instance.tur_head, "tag_hardpoint02");
        instance.gravity = 2;
        instance.mass = 5000;
    }

    instance.frame = 5;
    instance.tur_head.frame = 1;
    set_movetype(instance, MOVETYPE_WALK);
    instance.solid = SOLID_SLIDEBOX;
    instance.alpha = instance.tur_head.alpha = instance.gun1.alpha = instance.gun2.alpha = 1;
    instance.tur_head.angles = '0 0 0';
    instance.vehicle_exit = spiderbot_exit;

    setorigin(instance, instance.pos1 + '0 0 128');
    instance.angles = instance.pos2;
    instance.damageforcescale = 0.03;
    SetResourceExplicit(instance, RES_HEALTH, autocvar_g_vehicle_spiderbot_health);
    instance.vehicle_shield = autocvar_g_vehicle_spiderbot_shield;

    instance.PlayerPhysplug = spiderbot_frame;
}
METHOD(Spiderbot, vr_setup, void(Spiderbot thisveh, entity instance))
{
    if(autocvar_g_vehicle_spiderbot_shield)
        instance.vehicle_flags |= VHF_HASSHIELD;

    if(autocvar_g_vehicle_spiderbot_shield_regen)
        instance.vehicle_flags |= VHF_SHIELDREGEN;

    if(autocvar_g_vehicle_spiderbot_health_regen)
        instance.vehicle_flags |= VHF_HEALTHREGEN;

    instance.respawntime = autocvar_g_vehicle_spiderbot_respawntime;
    SetResourceExplicit(instance, RES_HEALTH, autocvar_g_vehicle_spiderbot_health);
    instance.vehicle_shield = autocvar_g_vehicle_spiderbot_shield;
    instance.max_health = GetResource(instance, RES_HEALTH);
    instance.pushable = true; // spiderbot can use jumppads
}

#endif // SVQC
#ifdef CSQC
//float autocvar_cl_vehicle_spiderbot_cross_alpha = 0.6;
//float autocvar_cl_vehicle_spiderbot_cross_size = 1;

METHOD(Spiderbot, vr_hud, void(Spiderbot thisveh))
{
    Vehicles_drawHUD(VEH_SPIDERBOT.m_icon, "vehicle_spider_weapon1", "vehicle_spider_weapon2",
                     "vehicle_icon_ammo1", autocvar_hud_progressbar_vehicles_ammo1_color,
                     "vehicle_icon_ammo2", autocvar_hud_progressbar_vehicles_ammo2_color);
}
METHOD(Spiderbot, vr_crosshair, void(Spiderbot thisveh, entity player))
{
    string crosshair;

    switch(weapon2mode)
    {
        case SBRM_VOLLY:     crosshair = vCROSS_BURST; break;
        case SBRM_GUIDE:     crosshair = vCROSS_GUIDE; break;
        case SBRM_ARTILLERY: crosshair = vCROSS_RAIN;  break;
        default:             crosshair = vCROSS_BURST;
    }

    Vehicles_drawCrosshair(crosshair);
}
METHOD(Spiderbot, vr_setup, void(Spiderbot thisveh, entity instance))
{
    AuxiliaryXhair[0].axh_image = vCROSS_HINT; // Minigun1
    AuxiliaryXhair[1].axh_image = vCROSS_HINT; // Minigun2
}

#endif

#endif
#ifdef MENUQC

METHOD(Spiderbot, describe, string(Spiderbot this))
{
	TC(Spiderbot, this);
	PAGE_TEXT_INIT();
	PAR(_("The %s vehicle walks and jumps around, and takes only one rider."), COLORED_NAME(this));
	PAR(_("It can jump from very high altitudes while protecting the rider."));
	PAR(_("It has two weapons the rider can control, which have different reticles for them similar to the %s. "
	      "The primary weapon is a machine gun, and is shot toward the green reticle. "
	      "The secondary weapon shoots rockets towards the white reticle. "
	      "The white reticle points to the front of the vehicle, while the green reticle also points to the front but with a bit of delay when the %s rotates."), COLORED_NAME(VEH_RAPTOR), COLORED_NAME(this));
	return PAGE_TEXT;
}

#endif
