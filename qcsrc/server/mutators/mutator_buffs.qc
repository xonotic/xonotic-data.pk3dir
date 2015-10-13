#include "../../common/triggers/target/music.qh"
#include "mutator_buffs.qh"

#include "mutator.qh"

#include "../../common/gamemodes/all.qh"
#include "../../common/buffs/all.qh"

entity buff_FirstFromFlags(int _buffs)
{
	if (flags)
	{
		FOREACH(Buffs, it.m_itemid & _buffs, LAMBDA(return it));
	}
	return BUFF_Null;
}

bool buffs_BuffModel_Customize()
{SELFPARAM();
	entity player, myowner;
	bool same_team;

	player = WaypointSprite_getviewentity(other);
	myowner = self.owner;
	same_team = (SAME_TEAM(player, myowner) || SAME_TEAM(player, myowner));

	if(myowner.alpha <= 0.5 && !same_team && myowner.alpha != 0)
		return false;

	if(MUTATOR_CALLHOOK(BuffModel_Customize, self, player))
		return false;

	if(player == myowner || (IS_SPEC(other) && other.enemy == myowner))
	{
		// somewhat hide the model, but keep the glow
		self.effects = 0;
		self.alpha = -1;
	}
	else
	{
		self.effects = EF_FULLBRIGHT | EF_LOWPRECISION;
		self.alpha = 1;
	}
	return true;
}

void buffs_BuffModel_Spawn(entity player)
{
	player.buff_model = spawn();
	setmodel(player.buff_model, MDL_BUFF);
	setsize(player.buff_model, '0 0 -40', '0 0 40');
	setattachment(player.buff_model, player, "");
	setorigin(player.buff_model, '0 0 1' * (player.buff_model.maxs.z * 1));
	player.buff_model.owner = player;
	player.buff_model.scale = 0.7;
	player.buff_model.pflags = PFLAGS_FULLDYNAMIC;
	player.buff_model.light_lev = 200;
	player.buff_model.customizeentityforclient = buffs_BuffModel_Customize;
}

vector buff_GlowColor(entity buff)
{
	//if(buff.team) { return Team_ColorRGB(buff.team); }
	return buff.m_color;
}

void buff_Effect(entity player, string eff)
{SELFPARAM();
	if(!autocvar_g_buffs_effects) { return; }

	if(time >= self.buff_effect_delay)
	{
		Send_Effect_(eff, player.origin + ((player.mins + player.maxs) * 0.5), '0 0 0', 1);
		self.buff_effect_delay = time + 0.05; // prevent spam
	}
}

// buff item
float buff_Waypoint_visible_for_player(entity plr)
{SELFPARAM();
	if(!self.owner.buff_active && !self.owner.buff_activetime)
		return false;

	if (plr.buffs)
	{
		return plr.cvar_cl_buffs_autoreplace == false || plr.buffs != self.owner.buffs;
	}

	return WaypointSprite_visible_for_player(plr);
}

void buff_Waypoint_Spawn(entity e)
{
	entity buff = buff_FirstFromFlags(e.buffs);
	entity wp = WaypointSprite_Spawn(WP_Buff, 0, autocvar_g_buffs_waypoint_distance, e, '0 0 1' * e.maxs.z, world, e.team, e, buff_waypoint, true, RADARICON_Buff);
	wp.wp_extra = buff.m_id;
	WaypointSprite_UpdateTeamRadar(e.buff_waypoint, RADARICON_Buff, e.glowmod);
	e.buff_waypoint.waypointsprite_visible_for_player = buff_Waypoint_visible_for_player;
}

void buff_SetCooldown(float cd)
{SELFPARAM();
	cd = max(0, cd);

	if(!self.buff_waypoint)
		buff_Waypoint_Spawn(self);

	WaypointSprite_UpdateBuildFinished(self.buff_waypoint, time + cd);
	self.buff_activetime = cd;
	self.buff_active = !cd;
}

void buff_Respawn(entity ent)
{SELFPARAM();
	if(gameover) { return; }

	vector oldbufforigin = ent.origin;

	if(!MoveToRandomMapLocation(ent, DPCONTENTS_SOLID | DPCONTENTS_CORPSE | DPCONTENTS_PLAYERCLIP, DPCONTENTS_SLIME | DPCONTENTS_LAVA | DPCONTENTS_SKY | DPCONTENTS_BODY | DPCONTENTS_DONOTENTER, Q3SURFACEFLAG_SKY, ((autocvar_g_buffs_random_location_attempts > 0) ? autocvar_g_buffs_random_location_attempts : 10), 1024, 256))
	{
		entity spot = SelectSpawnPoint(true);
		setorigin(ent, ((spot.origin + '0 0 200') + (randomvec() * 300)));
		ent.angles = spot.angles;
	}

	tracebox(ent.origin, ent.mins * 1.5, self.maxs * 1.5, ent.origin, MOVE_NOMONSTERS, ent);

	setorigin(ent, trace_endpos); // attempt to unstick

	ent.movetype = MOVETYPE_TOSS;

	makevectors(ent.angles);
	ent.velocity = '0 0 200';
	ent.angles = '0 0 0';
	if(autocvar_g_buffs_random_lifetime > 0)
		ent.lifetime = time + autocvar_g_buffs_random_lifetime;

	Send_Effect(EFFECT_ELECTRO_COMBO, oldbufforigin + ((ent.mins + ent.maxs) * 0.5), '0 0 0', 1);
	Send_Effect(EFFECT_ELECTRO_COMBO, CENTER_OR_VIEWOFS(ent), '0 0 0', 1);

	WaypointSprite_Ping(ent.buff_waypoint);

	sound(ent, CH_TRIGGER, SND_KA_RESPAWN, VOL_BASE, ATTEN_NONE); // ATTEN_NONE (it's a sound intended to be heard anywhere)
}

void buff_Touch()
{SELFPARAM();
	if(gameover) { return; }

	if(ITEM_TOUCH_NEEDKILL())
	{
		buff_Respawn(self);
		return;
	}

	if((self.team && DIFF_TEAM(other, self))
	|| (other.frozen)
	|| (other.vehicle)
	|| (!self.buff_active)
	)
	{
		// can't touch this
		return;
	}

	if(MUTATOR_CALLHOOK(BuffTouch, self, other))
		return;

	if(!IS_PLAYER(other))
		return; // incase mutator changed other

	if (other.buffs)
	{
		if (other.cvar_cl_buffs_autoreplace && other.buffs != self.buffs)
		{
			int buffid = buff_FirstFromFlags(other.buffs).m_id;
			//Send_Notification(NOTIF_ONE, other, MSG_MULTI, ITEM_BUFF_DROP, other.buffs);
			Send_Notification(NOTIF_ALL, world, MSG_INFO, INFO_ITEM_BUFF_LOST, other.netname, buffid);

			other.buffs = 0;
			//sound(other, CH_TRIGGER, SND_BUFF_LOST, VOL_BASE, ATTN_NORM);
		}
		else { return; } // do nothing
	}

	self.owner = other;
	self.buff_active = false;
	self.lifetime = 0;
	int buffid = buff_FirstFromFlags(self.buffs).m_id;
	Send_Notification(NOTIF_ONE, other, MSG_MULTI, ITEM_BUFF_GOT, buffid);
	Send_Notification(NOTIF_ALL_EXCEPT, other, MSG_INFO, INFO_ITEM_BUFF, other.netname, buffid);

	Send_Effect(EFFECT_ITEM_PICKUP, CENTER_OR_VIEWOFS(self), '0 0 0', 1);
	sound(other, CH_TRIGGER, SND_SHIELD_RESPAWN, VOL_BASE, ATTN_NORM);
	other.buffs |= (self.buffs);
}

float buff_Available(entity buff)
{
	if (buff == BUFF_Null)
		return false;
	if (buff == BUFF_AMMO && ((start_items & IT_UNLIMITED_WEAPON_AMMO) || (start_items & IT_UNLIMITED_AMMO) || (cvar("g_melee_only"))))
		return false;
	if (buff == BUFF_VAMPIRE && cvar("g_vampire"))
		return false;
	return cvar(strcat("g_buffs_", buff.m_name));
}

.int buff_seencount;

void buff_NewType(entity ent, float cb)
{
	RandomSelection_Init();
	FOREACH(Buffs, buff_Available(it), LAMBDA(
		it.buff_seencount += 1;
		// if it's already been chosen, give it a lower priority
		RandomSelection_Add(world, it.m_itemid, string_null, 1, max(0.2, 1 / it.buff_seencount));
	));
	ent.buffs = RandomSelection_chosen_float;
}

void buff_Think()
{SELFPARAM();
	if(self.buffs != self.oldbuffs)
	{
		entity buff = buff_FirstFromFlags(self.buffs);
		self.color = buff.m_color;
		self.glowmod = buff_GlowColor(buff);
		self.skin = buff.m_skin;

		setmodel(self, MDL_BUFF);

		if(self.buff_waypoint)
		{
			//WaypointSprite_Disown(self.buff_waypoint, 1);
			WaypointSprite_Kill(self.buff_waypoint);
			buff_Waypoint_Spawn(self);
			if(self.buff_activetime)
				WaypointSprite_UpdateBuildFinished(self.buff_waypoint, time + self.buff_activetime - frametime);
		}

		self.oldbuffs = self.buffs;
	}

	if(!gameover)
	if((round_handler_IsActive() && !round_handler_IsRoundStarted()) || time >= game_starttime)
	if(!self.buff_activetime_updated)
	{
		buff_SetCooldown(self.buff_activetime);
		self.buff_activetime_updated = true;
	}

	if(!self.buff_active && !self.buff_activetime)
	if(!self.owner || self.owner.frozen || self.owner.deadflag != DEAD_NO || !self.owner.iscreature || !(self.owner.buffs & self.buffs))
	{
		buff_SetCooldown(autocvar_g_buffs_cooldown_respawn + frametime);
		self.owner = world;
		if(autocvar_g_buffs_randomize)
			buff_NewType(self, self.buffs);

		if(autocvar_g_buffs_random_location || (self.spawnflags & 64))
			buff_Respawn(self);
	}

	if(self.buff_activetime)
	if(!gameover)
	if((round_handler_IsActive() && !round_handler_IsRoundStarted()) || time >= game_starttime)
	{
		self.buff_activetime = max(0, self.buff_activetime - frametime);

		if(!self.buff_activetime)
		{
			self.buff_active = true;
			sound(self, CH_TRIGGER, SND_STRENGTH_RESPAWN, VOL_BASE, ATTN_NORM);
			Send_Effect(EFFECT_ITEM_RESPAWN, CENTER_OR_VIEWOFS(self), '0 0 0', 1);
		}
	}

	if(self.buff_active)
	{
		if(self.team && !self.buff_waypoint)
			buff_Waypoint_Spawn(self);

		if(self.lifetime)
		if(time >= self.lifetime)
			buff_Respawn(self);
	}

	self.nextthink = time;
	//self.angles_y = time * 110.1;
}

void buff_Waypoint_Reset()
{SELFPARAM();
	WaypointSprite_Kill(self.buff_waypoint);

	if(self.buff_activetime) { buff_Waypoint_Spawn(self); }
}

void buff_Reset()
{SELFPARAM();
	if(autocvar_g_buffs_randomize)
		buff_NewType(self, self.buffs);
	self.owner = world;
	buff_SetCooldown(autocvar_g_buffs_cooldown_activate);
	buff_Waypoint_Reset();
	self.buff_activetime_updated = false;

	if(autocvar_g_buffs_random_location || (self.spawnflags & 64))
		buff_Respawn(self);
}

float buff_Customize()
{SELFPARAM();
	entity player = WaypointSprite_getviewentity(other);
	if(!self.buff_active || (self.team && DIFF_TEAM(player, self)))
	{
		self.alpha = 0.3;
		if(self.effects & EF_FULLBRIGHT) { self.effects &= ~(EF_FULLBRIGHT); }
		self.pflags = 0;
	}
	else
	{
		self.alpha = 1;
		if(!(self.effects & EF_FULLBRIGHT)) { self.effects |= EF_FULLBRIGHT; }
		self.light_lev = 220 + 36 * sin(time);
		self.pflags = PFLAGS_FULLDYNAMIC;
	}
	return true;
}

void buff_Init(entity ent)
{SELFPARAM();
	if(!cvar("g_buffs")) { remove(ent); return; }

	if(!teamplay && ent.team) { ent.team = 0; }

	entity buff = buff_FirstFromFlags(self.buffs);

	setself(ent);
	if(!self.buffs || buff_Available(buff))
		buff_NewType(self, 0);

	self.classname = "item_buff";
	self.solid = SOLID_TRIGGER;
	self.flags = FL_ITEM;
	self.think = buff_Think;
	self.touch = buff_Touch;
	self.reset = buff_Reset;
	self.nextthink = time + 0.1;
	self.gravity = 1;
	self.movetype = MOVETYPE_TOSS;
	self.scale = 1;
	self.skin = buff.m_skin;
	self.effects = EF_FULLBRIGHT | EF_STARDUST | EF_NOSHADOW;
	self.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY;
	self.customizeentityforclient = buff_Customize;
	//self.gravity = 100;
	self.color = buff.m_color;
	self.glowmod = buff_GlowColor(self);
	buff_SetCooldown(autocvar_g_buffs_cooldown_activate + game_starttime);
	self.buff_active = !self.buff_activetime;
	self.pflags = PFLAGS_FULLDYNAMIC;

	if(self.spawnflags & 1)
		self.noalign = true;

	if(self.noalign)
		self.movetype = MOVETYPE_NONE; // reset by random location

	setmodel(self, MDL_BUFF);
	setsize(self, BUFF_MIN, BUFF_MAX);

	if(cvar("g_buffs_random_location") || (self.spawnflags & 64))
		buff_Respawn(self);

	setself(this);
}

void buff_Init_Compat(entity ent, entity replacement)
{
	if (ent.spawnflags & 2)
		ent.team = NUM_TEAM_1;
	else if (ent.spawnflags & 4)
		ent.team = NUM_TEAM_2;

	ent.buffs = replacement.m_itemid;

	buff_Init(ent);
}

void buff_SpawnReplacement(entity ent, entity old)
{
	setorigin(ent, old.origin);
	ent.angles = old.angles;
	ent.noalign = (old.noalign || (old.spawnflags & 1));

	buff_Init(ent);
}

void buff_Vengeance_DelayedDamage()
{SELFPARAM();
	if(self.enemy)
		Damage(self.enemy, self.owner, self.owner, self.dmg, DEATH_BUFF.m_id, self.enemy.origin, '0 0 0');

	remove(self);
	return;
}

float buff_Inferno_CalculateTime(float x, float offset_x, float offset_y, float intersect_x, float intersect_y, float base)
{
	return offset_y + (intersect_y - offset_y) * logn(((x - offset_x) * ((base - 1) / intersect_x)) + 1, base);
}

// mutator hooks
MUTATOR_HOOKFUNCTION(buffs_PlayerDamage_SplitHealthArmor)
{
	if(frag_deathtype == DEATH_BUFF.m_id) { return false; }

	if(frag_target.buffs & BUFF_RESISTANCE.m_itemid)
	{
		vector v = healtharmor_applydamage(50, autocvar_g_buffs_resistance_blockpercent, frag_deathtype, frag_damage);
		damage_take = v.x;
		damage_save = v.y;
	}

	return false;
}

MUTATOR_HOOKFUNCTION(buffs_PlayerDamage_Calculate)
{
	if(frag_deathtype == DEATH_BUFF.m_id) { return false; }

	if(frag_target.buffs & BUFF_SPEED.m_itemid)
	if(frag_target != frag_attacker)
		frag_damage *= autocvar_g_buffs_speed_damage_take;

	if(frag_target.buffs & BUFF_MEDIC.m_itemid)
	if((frag_target.health - frag_damage) <= 0)
	if(!ITEM_DAMAGE_NEEDKILL(frag_deathtype))
	if(frag_attacker)
	if(random() <= autocvar_g_buffs_medic_survive_chance)
		frag_damage = max(5, frag_target.health - autocvar_g_buffs_medic_survive_health);

	if(frag_target.buffs & BUFF_JUMP.m_itemid)
	if(frag_deathtype == DEATH_FALL.m_id)
		frag_damage = 0;

	if(frag_target.buffs & BUFF_VENGEANCE.m_itemid)
	if(frag_attacker)
	if(frag_attacker != frag_target)
	if(!ITEM_DAMAGE_NEEDKILL(frag_deathtype))
	{
		entity dmgent = spawn();

		dmgent.dmg = frag_damage * autocvar_g_buffs_vengeance_damage_multiplier;
		dmgent.enemy = frag_attacker;
		dmgent.owner = frag_target;
		dmgent.think = buff_Vengeance_DelayedDamage;
		dmgent.nextthink = time + 0.1;
	}

	if(frag_target.buffs & BUFF_BASH.m_itemid)
	if(frag_attacker != frag_target)
	if(vlen(frag_force))
		frag_force = '0 0 0';

	if(frag_attacker.buffs & BUFF_BASH.m_itemid)
	if(vlen(frag_force))
	if(frag_attacker == frag_target)
		frag_force *= autocvar_g_buffs_bash_force_self;
	else
		frag_force *= autocvar_g_buffs_bash_force;

	if(frag_attacker.buffs & BUFF_DISABILITY.m_itemid)
	if(frag_target != frag_attacker)
		frag_target.buff_disability_time = time + autocvar_g_buffs_disability_slowtime;

	if(frag_attacker.buffs & BUFF_MEDIC.m_itemid)
	if(DEATH_WEAPONOF(frag_deathtype) != WEP_ARC)
	if(SAME_TEAM(frag_attacker, frag_target))
	if(frag_attacker != frag_target)
	{
		frag_target.health = min(g_pickup_healthmega_max, frag_target.health + frag_damage);
		frag_damage = 0;
	}

	if(frag_attacker.buffs & BUFF_INFERNO.m_itemid)
	if(frag_target != frag_attacker) {
		float time = buff_Inferno_CalculateTime(
			frag_damage,
			0,
			autocvar_g_buffs_inferno_burntime_min_time,
			autocvar_g_buffs_inferno_burntime_target_damage,
			autocvar_g_buffs_inferno_burntime_target_time,
			autocvar_g_buffs_inferno_burntime_factor
		);
		Fire_AddDamage(frag_target, frag_attacker, (frag_damage * autocvar_g_buffs_inferno_damagemultiplier) * time, time, DEATH_BUFF.m_id);
	}

	// this... is ridiculous (TODO: fix!)
	if(frag_attacker.buffs & BUFF_VAMPIRE.m_itemid)
	if(!frag_target.vehicle)
	if(DEATH_WEAPONOF(frag_deathtype) != WEP_ARC)
	if(!ITEM_DAMAGE_NEEDKILL(frag_deathtype))
	if(frag_target.deadflag == DEAD_NO)
	if(IS_PLAYER(frag_target) || IS_MONSTER(frag_target))
	if(frag_attacker != frag_target)
	if(!frag_target.frozen)
	if(frag_target.takedamage)
	if(DIFF_TEAM(frag_attacker, frag_target))
	{
		frag_attacker.health = bound(0, frag_attacker.health + bound(0, frag_damage * autocvar_g_buffs_vampire_damage_steal, frag_target.health), g_pickup_healthsmall_max);
		if(frag_target.armorvalue)
			frag_attacker.armorvalue = bound(0, frag_attacker.armorvalue + bound(0, frag_damage * autocvar_g_buffs_vampire_damage_steal, frag_target.armorvalue), g_pickup_armorsmall_max);
	}

	return false;
}

MUTATOR_HOOKFUNCTION(buffs_PlayerSpawn)
{SELFPARAM();
	self.buffs = 0;
	// reset timers here to prevent them continuing after re-spawn
	self.buff_disability_time = 0;
	self.buff_disability_effect_time = 0;
	return false;
}

.float stat_sv_maxspeed;
.float stat_sv_airspeedlimit_nonqw;
.float stat_sv_jumpvelocity;

MUTATOR_HOOKFUNCTION(buffs_PlayerPhysics)
{SELFPARAM();
	if(self.buffs & BUFF_SPEED.m_itemid)
	{
		self.stat_sv_maxspeed *= autocvar_g_buffs_speed_speed;
		self.stat_sv_airspeedlimit_nonqw *= autocvar_g_buffs_speed_speed;
	}

	if(time < self.buff_disability_time)
	{
		self.stat_sv_maxspeed *= autocvar_g_buffs_disability_speed;
		self.stat_sv_airspeedlimit_nonqw *= autocvar_g_buffs_disability_speed;
	}

	if(self.buffs & BUFF_JUMP.m_itemid)
	{
		// automatically reset, no need to worry
		self.stat_sv_jumpvelocity = autocvar_g_buffs_jump_height;
	}

	return false;
}

MUTATOR_HOOKFUNCTION(buffs_PlayerJump)
{SELFPARAM();
	if(self.buffs & BUFF_JUMP.m_itemid)
		player_jumpheight = autocvar_g_buffs_jump_height;

	return false;
}

MUTATOR_HOOKFUNCTION(buffs_MonsterMove)
{SELFPARAM();
	if(time < self.buff_disability_time)
	{
		monster_speed_walk *= autocvar_g_buffs_disability_speed;
		monster_speed_run *= autocvar_g_buffs_disability_speed;
	}

	return false;
}

MUTATOR_HOOKFUNCTION(buffs_PlayerDies)
{SELFPARAM();
	if(self.buffs)
	{
		int buffid = buff_FirstFromFlags(self.buffs).m_id;
		Send_Notification(NOTIF_ALL_EXCEPT, self, MSG_INFO, INFO_ITEM_BUFF_LOST, self.netname, buffid);
		self.buffs = 0;

		if(self.buff_model)
		{
			remove(self.buff_model);
			self.buff_model = world;
		}
	}
	return false;
}

MUTATOR_HOOKFUNCTION(buffs_PlayerUseKey)
{SELFPARAM();
	if(MUTATOR_RETURNVALUE || gameover) { return false; }
	if(self.buffs)
	{
		int buffid = buff_FirstFromFlags(self.buffs).m_id;
		Send_Notification(NOTIF_ONE, self, MSG_MULTI, ITEM_BUFF_DROP, buffid);
		Send_Notification(NOTIF_ALL_EXCEPT, self, MSG_INFO, INFO_ITEM_BUFF_LOST, self.netname, buffid);

		self.buffs = 0;
		sound(self, CH_TRIGGER, SND_BUFF_LOST, VOL_BASE, ATTN_NORM);
		return true;
	}
	return false;
}

MUTATOR_HOOKFUNCTION(buffs_PlayerThrowKey)
{SELFPARAM();
	if(MUTATOR_RETURNVALUE || gameover) { return false; }

	if(self.buffs & BUFF_SWAPPER.m_itemid)
	{
		float best_distance = autocvar_g_buffs_swapper_range;
		entity closest = world;
		entity player;
		FOR_EACH_PLAYER(player)
		if(DIFF_TEAM(self, player))
		if(player.deadflag == DEAD_NO && !player.frozen && !player.vehicle)
		if(vlen(self.origin - player.origin) <= best_distance)
		{
			best_distance = vlen(self.origin - player.origin);
			closest = player;
		}

		if(closest)
		{
			vector my_org, my_vel, my_ang, their_org, their_vel, their_ang;

			my_org = self.origin;
			my_vel = self.velocity;
			my_ang = self.angles;
			their_org = closest.origin;
			their_vel = closest.velocity;
			their_ang = closest.angles;

			if(closest.ballcarried)
			if(g_keepaway) { ka_DropEvent(closest); }
			else { DropBall(closest.ballcarried, closest.origin, closest.velocity);}
			if(closest.flagcarried) { ctf_Handle_Throw(closest, world, DROP_THROW); }
			if(closest.nade) { toss_nade(closest, '0 0 0', time + 0.05); }

			MUTATOR_CALLHOOK(PortalTeleport, self); // initiate flag dropper

			setorigin(self, their_org);
			setorigin(closest, my_org);

			closest.velocity = my_vel;
			closest.angles = my_ang;
			closest.fixangle = true;
			closest.oldorigin = my_org;
			closest.oldvelocity = my_vel;
			self.velocity = their_vel;
			self.angles = their_ang;
			self.fixangle = true;
			self.oldorigin = their_org;
			self.oldvelocity = their_vel;

			// set pusher so self gets the kill if they fall into void
			closest.pusher = self;
			closest.pushltime = time + autocvar_g_maxpushtime;
			closest.istypefrag = closest.BUTTON_CHAT;

			Send_Effect(EFFECT_ELECTRO_COMBO, their_org, '0 0 0', 1);
			Send_Effect(EFFECT_ELECTRO_COMBO, my_org, '0 0 0', 1);

			sound(self, CH_TRIGGER, SND_KA_RESPAWN, VOL_BASE, ATTEN_NORM);
			sound(closest, CH_TRIGGER, SND_KA_RESPAWN, VOL_BASE, ATTEN_NORM);

			// TODO: add a counter to handle how many times one can teleport, and a delay to prevent spam
			self.buffs = 0;
			return true;
		}
	}
	return false;
}

MUTATOR_HOOKFUNCTION(buffs_RemovePlayer)
{SELFPARAM();
	if(self.buff_model)
	{
		remove(self.buff_model);
		self.buff_model = world;
	}

	// also reset timers here to prevent them continuing after spectating
	self.buff_disability_time = 0;
	self.buff_disability_effect_time = 0;

	return false;
}

MUTATOR_HOOKFUNCTION(buffs_CustomizeWaypoint)
{SELFPARAM();
	entity e = WaypointSprite_getviewentity(other);

	// if you have the invisibility powerup, sprites ALWAYS are restricted to your team
	// but only apply this to real players, not to spectators
	if((self.owner.flags & FL_CLIENT) && (self.owner.buffs & BUFF_INVISIBLE.m_itemid) && (e == other))
	if(DIFF_TEAM(self.owner, e))
		return true;

	return false;
}

MUTATOR_HOOKFUNCTION(buffs_OnEntityPreSpawn)
{SELFPARAM();
	if(autocvar_g_buffs_replace_powerups)
	switch(self.classname)
	{
		case "item_strength":
		case "item_invincible":
		{
			entity e = spawn();
			buff_SpawnReplacement(e, self);
			return true;
		}
	}
	return false;
}

MUTATOR_HOOKFUNCTION(buffs_WeaponRate)
{SELFPARAM();
	if(self.buffs & BUFF_SPEED.m_itemid)
		weapon_rate *= autocvar_g_buffs_speed_rate;

	if(time < self.buff_disability_time)
		weapon_rate *= autocvar_g_buffs_disability_rate;

	return false;
}

MUTATOR_HOOKFUNCTION(buffs_WeaponSpeed)
{SELFPARAM();
	if(self.buffs & BUFF_SPEED.m_itemid)
		ret_float *= autocvar_g_buffs_speed_weaponspeed;

	if(time < self.buff_disability_time)
		ret_float *= autocvar_g_buffs_disability_weaponspeed;

	return false;
}

.float buff_time;

MUTATOR_HOOKFUNCTION(buffs_PlayerThink)
{SELFPARAM();
	if(gameover || self.deadflag != DEAD_NO) { return false; }

	if(time < self.buff_disability_time)
	if(time >= self.buff_disability_effect_time)
	{
		Send_Effect(EFFECT_SMOKING, self.origin + ((self.mins + self.maxs) * 0.5), '0 0 0', 1);
		self.buff_disability_effect_time = time + 0.5;
	}

	// handle buff lost status
	// 1: notify everyone else
	// 2: notify carrier as well
	int buff_lost = 0;

	if(self.buff_time)
	if(time >= self.buff_time)
		buff_lost = 2;

	if(self.frozen) { buff_lost = 1; }

	if(buff_lost)
	{
		if(self.buffs)
		{
			int buffid = buff_FirstFromFlags(self.buffs).m_id;
			Send_Notification(NOTIF_ALL_EXCEPT, self, MSG_INFO, INFO_ITEM_BUFF_LOST, self.netname, buffid);
			if(buff_lost >= 2)
			{
				Send_Notification(NOTIF_ONE, self, MSG_MULTI, ITEM_BUFF_DROP, buffid); // TODO: special timeout message?
				sound(self, CH_TRIGGER, SND_BUFF_LOST, VOL_BASE, ATTN_NORM);
			}
			self.buffs = 0;
		}
	}

	if(self.buffs & BUFF_MAGNET.m_itemid)
	{
		vector pickup_size = '1 1 1' * autocvar_g_buffs_magnet_range_item;
		for(other = world; (other = findflags(other, flags, FL_ITEM)); )
		if(boxesoverlap(self.absmin - pickup_size, self.absmax + pickup_size, other.absmin, other.absmax))
		{
			setself(other);
			other = this;
			if(self.touch)
				self.touch();
			other = self;
			setself(this);
		}
	}

	if(self.buffs & BUFF_AMMO.m_itemid)
	if(self.clip_size)
		self.clip_load = self.(weapon_load[self.switchweapon]) = self.clip_size;

	if((self.buffs & BUFF_INVISIBLE.m_itemid) && (self.oldbuffs & BUFF_INVISIBLE.m_itemid))
	if(self.alpha != autocvar_g_buffs_invisible_alpha)
		self.alpha = autocvar_g_buffs_invisible_alpha; // powerups reset alpha, so we must enforce this (TODO)

#define BUFF_ONADD(b) if ( (self.buffs & (b).m_itemid) && !(self.oldbuffs & (b).m_itemid))
#define BUFF_ONREM(b) if (!(self.buffs & (b).m_itemid) &&  (self.oldbuffs & (b).m_itemid))

	if(self.buffs != self.oldbuffs)
	{
		entity buff = buff_FirstFromFlags(self.buffs);
		float bufftime = buff != BUFF_Null ? buff.m_time(buff) : 0;
		self.buff_time = (bufftime) ? time + bufftime : 0;

		BUFF_ONADD(BUFF_AMMO)
		{
			self.buff_ammo_prev_infitems = (self.items & IT_UNLIMITED_WEAPON_AMMO);
			self.items |= IT_UNLIMITED_WEAPON_AMMO;

			if(self.clip_load)
				self.buff_ammo_prev_clipload = self.clip_load;
			self.clip_load = self.(weapon_load[self.switchweapon]) = self.clip_size;
		}

		BUFF_ONREM(BUFF_AMMO)
		{
			if(self.buff_ammo_prev_infitems)
				self.items |= IT_UNLIMITED_WEAPON_AMMO;
			else
				self.items &= ~IT_UNLIMITED_WEAPON_AMMO;

			if(self.buff_ammo_prev_clipload)
				self.clip_load = self.buff_ammo_prev_clipload;
		}

		BUFF_ONADD(BUFF_INVISIBLE)
		{
			if(time < self.strength_finished && g_instagib)
				self.alpha = autocvar_g_instagib_invis_alpha;
			else
				self.alpha = self.buff_invisible_prev_alpha;
			self.alpha = autocvar_g_buffs_invisible_alpha;
		}

		BUFF_ONREM(BUFF_INVISIBLE)
			self.alpha = self.buff_invisible_prev_alpha;

		BUFF_ONADD(BUFF_FLIGHT)
		{
			self.buff_flight_prev_gravity = self.gravity;
			self.gravity = autocvar_g_buffs_flight_gravity;
		}

		BUFF_ONREM(BUFF_FLIGHT)
			self.gravity = self.buff_flight_prev_gravity;

		self.oldbuffs = self.buffs;
		if(self.buffs)
		{
			if(!self.buff_model)
				buffs_BuffModel_Spawn(self);

			self.buff_model.color = buff.m_color;
			self.buff_model.glowmod = buff_GlowColor(self.buff_model);
			self.buff_model.skin = buff.m_skin;

			self.effects |= EF_NOSHADOW;
		}
		else
		{
			remove(self.buff_model);
			self.buff_model = world;

			self.effects &= ~(EF_NOSHADOW);
		}
	}

	if(self.buff_model)
	{
		self.buff_model.effects = self.effects;
		self.buff_model.effects |= EF_LOWPRECISION;
		self.buff_model.effects = self.buff_model.effects & EFMASK_CHEAP; // eat performance

		self.buff_model.alpha = self.alpha;
	}

#undef BUFF_ONADD
#undef BUFF_ONREM
	return false;
}

MUTATOR_HOOKFUNCTION(buffs_SpectateCopy)
{SELFPARAM();
	self.buffs = other.buffs;
	return false;
}

MUTATOR_HOOKFUNCTION(buffs_VehicleEnter)
{
	vh_vehicle.buffs = vh_player.buffs;
	vh_player.buffs = 0;
	return false;
}

MUTATOR_HOOKFUNCTION(buffs_VehicleExit)
{
	vh_player.buffs = vh_vehicle.buffs;
	vh_vehicle.buffs = 0;
	return false;
}

MUTATOR_HOOKFUNCTION(buffs_PlayerRegen)
{SELFPARAM();
	if(self.buffs & BUFF_MEDIC.m_itemid)
	{
		regen_mod_rot = autocvar_g_buffs_medic_rot;
		regen_mod_limit = regen_mod_max = autocvar_g_buffs_medic_max;
		regen_mod_regen = autocvar_g_buffs_medic_regen;
	}

	if(self.buffs & BUFF_SPEED.m_itemid)
		regen_mod_regen = autocvar_g_buffs_speed_regen;

	return false;
}

MUTATOR_HOOKFUNCTION(buffs_GetCvars)
{
	GetCvars_handleFloat(get_cvars_s, get_cvars_f, cvar_cl_buffs_autoreplace, "cl_buffs_autoreplace");
	return false;
}

MUTATOR_HOOKFUNCTION(buffs_BuildMutatorsString)
{
	ret_string = strcat(ret_string, ":Buffs");
	return false;
}

MUTATOR_HOOKFUNCTION(buffs_BuildMutatorsPrettyString)
{
	ret_string = strcat(ret_string, ", Buffs");
	return false;
}

void buffs_DelayedInit()
{
	if(autocvar_g_buffs_spawn_count > 0)
	if(find(world, classname, "item_buff") == world)
	{
		float i;
		for(i = 0; i < autocvar_g_buffs_spawn_count; ++i)
		{
			entity e = spawn();
			e.spawnflags |= 64; // always randomize
			e.velocity = randomvec() * 250; // this gets reset anyway if random location works
			buff_Init(e);
		}
	}
}

void buffs_Initialize()
{
	addstat(STAT_BUFFS, AS_INT, buffs);
	addstat(STAT_BUFF_TIME, AS_FLOAT, buff_time);

	InitializeEntity(world, buffs_DelayedInit, INITPRIO_FINDTARGET);
}

MUTATOR_DEFINITION(mutator_buffs)
{
	MUTATOR_HOOK(PlayerDamage_SplitHealthArmor, buffs_PlayerDamage_SplitHealthArmor, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerDamage_Calculate, buffs_PlayerDamage_Calculate, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerSpawn, buffs_PlayerSpawn, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerPhysics, buffs_PlayerPhysics, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerJump, buffs_PlayerJump, CBC_ORDER_ANY);
	MUTATOR_HOOK(MonsterMove, buffs_MonsterMove, CBC_ORDER_ANY);
	MUTATOR_HOOK(SpectateCopy, buffs_SpectateCopy, CBC_ORDER_ANY);
	MUTATOR_HOOK(VehicleEnter, buffs_VehicleEnter, CBC_ORDER_ANY);
	MUTATOR_HOOK(VehicleExit, buffs_VehicleExit, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerRegen, buffs_PlayerRegen, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerDies, buffs_PlayerDies, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerUseKey, buffs_PlayerUseKey, CBC_ORDER_FIRST);
	MUTATOR_HOOK(ForbidThrowCurrentWeapon, buffs_PlayerThrowKey, CBC_ORDER_ANY);
	MUTATOR_HOOK(MakePlayerObserver, buffs_RemovePlayer, CBC_ORDER_ANY);
	MUTATOR_HOOK(ClientDisconnect, buffs_RemovePlayer, CBC_ORDER_ANY);
	MUTATOR_HOOK(OnEntityPreSpawn, buffs_OnEntityPreSpawn, CBC_ORDER_LAST);
	MUTATOR_HOOK(CustomizeWaypoint, buffs_CustomizeWaypoint, CBC_ORDER_ANY);
	MUTATOR_HOOK(WeaponRateFactor, buffs_WeaponRate, CBC_ORDER_ANY);
	MUTATOR_HOOK(WeaponSpeedFactor, buffs_WeaponSpeed, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerPreThink, buffs_PlayerThink, CBC_ORDER_ANY);
	MUTATOR_HOOK(GetCvars, buffs_GetCvars, CBC_ORDER_ANY);
	MUTATOR_HOOK(BuildMutatorsString, buffs_BuildMutatorsString, CBC_ORDER_ANY);
	MUTATOR_HOOK(BuildMutatorsPrettyString, buffs_BuildMutatorsPrettyString, CBC_ORDER_ANY);

	MUTATOR_ONADD
	{
		buffs_Initialize();
	}

	return false;
}
