#include "t_teleporters.qh"
#include "_all.qh"

#include "anticheat.qh"
#include "cl_player.qh"
#include "g_hook.qh"
#include "bot/waypoints.qh"
#include "tturrets/include/turrets_early.qh"
#include "vehicles/vehicle.qh"
#include "weapons/csqcprojectile.qh"
#include "../common/constants.qh"
#include "../common/deathtypes.qh"
#include "../common/mapinfo.qh"
#include "../common/util.qh"
#include "../warpzonelib/common.qh"
#include "../warpzonelib/server.qh"
#include "../warpzonelib/util_server.qh"

.float lastteleporttime;

void trigger_teleport_use()
{
	if(teamplay)
		self.team = activator.team;
}

float check_tdeath(entity player, vector org, vector telefragmin, vector telefragmax)
{
	if (IS_PLAYER(player) && player.health >= 1)
	{
		TDEATHLOOP(org)
		{
			if (!(teamplay && autocvar_g_telefrags_teamplay && head.team == player.team))
				if(IS_PLAYER(head))
					if(head.health >= 1)
						return 1;
		}
	}
	return 0;
}

void tdeath(entity player, entity teleporter, entity telefragger, vector telefragmin, vector telefragmax)
{
	TDEATHLOOP(player.origin)
	{
		if (IS_PLAYER(player) && player.health >= 1)
		{
			if (!(teamplay && autocvar_g_telefrags_teamplay && head.team == player.team))
			{
				if(IS_PLAYER(head))
					if(head.health >= 1)
						++tdeath_hit;
				Damage (head, teleporter, telefragger, 10000, DEATH_TELEFRAG, head.origin, '0 0 0');
			}
		}
		else // dead bodies and monsters gib themselves instead of telefragging
			Damage (telefragger, teleporter, telefragger, 10000, DEATH_TELEFRAG, telefragger.origin, '0 0 0');
	}
}

void spawn_tdeath(vector v0, entity e, vector v)
{
	tdeath(e, e, e, '0 0 0', '0 0 0');
}

void TeleportPlayer(entity teleporter, entity player, vector to, vector to_angles, vector to_velocity, vector telefragmin, vector telefragmax, float tflags)
{
	entity telefragger;
	vector from;

	if(teleporter.owner)
		telefragger = teleporter.owner;
	else
		telefragger = player;

	makevectors (to_angles);

	if(player.teleportable == TELEPORT_NORMAL) // don't play sounds or show particles for anything that isn't a player, maybe change later to block only observers
	{
		if(self.pushltime < time) // only show one teleport effect per teleporter per 0.2 seconds, for better fps
		{
			if(tflags & TELEPORT_FLAG_SOUND)
				sound (player, CH_TRIGGER, "misc/teleport.wav", VOL_BASE, ATTEN_NORM);
			if(tflags & TELEPORT_FLAG_PARTICLES)
			{
				pointparticles(particleeffectnum("teleport"), player.origin, '0 0 0', 1);
				pointparticles(particleeffectnum("teleport"), to + v_forward * 32, '0 0 0', 1);
			}
			self.pushltime = time + 0.2;
		}
	}

	// Relocate the player
	// assuming to allows PL_MIN to PL_MAX box and some more
	from = player.origin;
	setorigin (player, to);
	player.oldorigin = to; // don't undo the teleport by unsticking
	player.angles = to_angles;
	player.fixangle = true;
	player.velocity = to_velocity;
	BITXOR_ASSIGN(player.effects, EF_TELEPORT_BIT);

	makevectors(player.angles);
	Reset_ArcBeam(player, v_forward);
	UpdateCSQCProjectileAfterTeleport(player);

	if(IS_PLAYER(player))
	{
		if(tflags & TELEPORT_FLAG_TDEATH)
			if(player.takedamage && player.deadflag == DEAD_NO && !g_race && !g_cts && (autocvar_g_telefrags || (tflags & TELEPORT_FLAG_FORCE_TDEATH)))
				tdeath(player, teleporter, telefragger, telefragmin, telefragmax);

		// player no longer is on ground
		player.flags &= ~FL_ONGROUND;

		// reset tracking of oldvelocity for impact damage (sudden velocity changes)
		player.oldvelocity = player.velocity;

		// reset tracking of who pushed you into a hazard (for kill credit)
		if(teleporter.owner)
		{
			player.pusher = teleporter.owner;
			player.pushltime = time + autocvar_g_maxpushtime;
			player.istypefrag = player.BUTTON_CHAT;
		}
		else
		{
			player.pushltime = 0;
			player.istypefrag = 0;
		}

		player.lastteleporttime = time;
	}
}

entity Simple_TeleportPlayer(entity teleporter, entity player)
{
	vector locout;
	entity e;
	float p;

	// Find the output teleporter
	if(teleporter.enemy)
	{
		e = teleporter.enemy;
	}
	else
	{
		RandomSelection_Init();
		for(e = world; (e = find(e, targetname, teleporter.target)); )
		{
			p = 1;
			if(autocvar_g_telefrags_avoid)
			{
				locout = e.origin + '0 0 1' * (1 - player.mins.z - 24);
				if(check_tdeath(player, locout, '0 0 0', '0 0 0'))
					p = 0;
			}
			RandomSelection_Add(e, 0, string_null, (e.cnt ? e.cnt : 1), p);
		}
		e = RandomSelection_chosen_ent;
	}

	if(!e) { sprint(player, "Teleport destination vanished. Sorry... please complain to the mapper.\n"); }

	makevectors(e.mangle);

	if(e.speed)
		if(vlen(player.velocity) > e.speed)
			player.velocity = normalize(player.velocity) * max(0, e.speed);

	if(autocvar_g_teleport_maxspeed)
		if(vlen(player.velocity) > autocvar_g_teleport_maxspeed)
			player.velocity = normalize(player.velocity) * max(0, autocvar_g_teleport_maxspeed);

	locout = e.origin + '0 0 1' * (1 - player.mins.z - 24);
	TeleportPlayer(teleporter, player, locout, e.mangle, v_forward * vlen(player.velocity), '0 0 0', '0 0 0', TELEPORT_FLAGS_TELEPORTER);

	return e;
}

void Teleport_Touch (void)
{
	entity oldself;
	string s;

	if (self.active != ACTIVE_ACTIVE)
		return;

	if (!other.teleportable)
		return;

	if(other.vehicle)
	if(!other.vehicle.teleportable)
		return;

	if(other.turrcaps_flags & TFL_TURRCAPS_ISTURRET)
		return;

	if(other.deadflag != DEAD_NO)
		return;

	if(self.team)
		if(((self.spawnflags & 4) == 0) == (self.team != other.team))
			return;

	EXACTTRIGGER_TOUCH;

	if(IS_PLAYER(other))
		RemoveGrapplingHook(other);

	entity e;
	e = Simple_TeleportPlayer(self, other);

	activator = other;
	s = self.target; self.target = string_null;
	SUB_UseTargets();
	if (!self.target) self.target = s;

	oldself = self;
	self = e;
	SUB_UseTargets();
	self = oldself;
}

void spawnfunc_info_teleport_destination (void)
{
	self.classname = "info_teleport_destination";

	self.mangle = self.angles;
	self.angles = '0 0 0';

	//setorigin (self, self.origin + '0 0 27');	// To fix a mappers' habit as old as Quake
	setorigin (self, self.origin);

	IFTARGETED
	{
	}
	else
		objerror ("^3Teleport destination without a targetname");
}

void spawnfunc_misc_teleporter_dest (void)
{
	spawnfunc_info_teleport_destination();
}

void spawnfunc_target_teleporter (void)
{
	spawnfunc_info_teleport_destination();
}

void teleport_findtarget (void)
{
	entity e;
	float n;

	n = 0;
	for(e = world; (e = find(e, targetname, self.target)); )
	{
		++n;
		if(e.movetype == MOVETYPE_NONE)
			waypoint_spawnforteleporter(self, e.origin, 0);
		if(e.classname != "info_teleport_destination")
			print("^3MAPPER ERROR: teleporter does target an invalid teleport destination entity. Angles will not work.\n");
	}

	if(n == 0)
	{
		// no dest!
		objerror ("Teleporter with nonexistant target");
		return;
	}
	else if(n == 1)
	{
		// exactly one dest - bots love that
		self.enemy = find(e, targetname, self.target);
	}
	else
	{
		// have to use random selection every single time
		self.enemy = world;
	}

	// now enable touch
	self.touch = Teleport_Touch;
}

entity Teleport_Find(vector mi, vector ma)
{
	entity e;
	for(e = world; (e = find(e, classname, "trigger_teleport")); )
		if(WarpZoneLib_BoxTouchesBrush(mi, ma, e, world))
			return e;
	return world;
}

void spawnfunc_trigger_teleport (void)
{
	self.angles = '0 0 0';

	EXACTTRIGGER_INIT;

	self.active = ACTIVE_ACTIVE;

	self.use = trigger_teleport_use;

	// this must be called to spawn the teleport waypoints for bots
	InitializeEntity(self, teleport_findtarget, INITPRIO_FINDTARGET);

	if (self.target == "")
	{
		objerror ("Teleporter with no target");
		return;
	}

	self.teleport_next = teleport_first;
	teleport_first = self;
}

void WarpZone_PostTeleportPlayer_Callback(entity pl)
{
	makevectors(pl.angles);
	Reset_ArcBeam(pl, v_forward);
	UpdateCSQCProjectileAfterTeleport(pl);
	{
		entity oldself = self;
		self = pl;
		anticheat_fixangle();
		self = oldself;
	}
	// "disown" projectiles after teleport
	if(pl.owner)
	if(pl.owner == pl.realowner)
	{
		if(!(pl.flags & FL_PROJECTILE))
			print("A non-projectile got through a warpzone and its owner cleared. It's a ", pl.classname, ".\n");
		pl.owner = world;
	}
	if(IS_PLAYER(pl))
	{
		// reset tracking of oldvelocity for impact damage (sudden velocity changes)
		pl.oldvelocity = pl.velocity;
		// reset teleport time tracking too (or multijump can cause insane speeds)
		pl.lastteleporttime = time;
	}
}
