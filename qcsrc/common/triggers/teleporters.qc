#include "teleporters.qh"

#if defined(CSQC)
#elif defined(MENUQC)
#elif defined(SVQC)
    #include "../../lib/warpzone/common.qh"
    #include "../../lib/warpzone/util_server.qh"
    #include "../../lib/warpzone/server.qh"
    #include "../constants.qh"
	#include "../triggers/subs.qh"
    #include "../util.qh"
    #include "../../server/weapons/csqcprojectile.qh"
    #include "../../server/autocvars.qh"
    #include "../../server/constants.qh"
    #include "../../server/defs.qh"
    #include "../deathtypes/all.qh"
    #include "../turrets/sv_turrets.qh"
    #include "../vehicles/all.qh"
    #include "../mapinfo.qh"
    #include "../../server/anticheat.qh"
#endif

float check_tdeath(entity player, vector org, vector telefragmin, vector telefragmax)
{
	if (IS_PLAYER(player) && !PHYS_DEAD(player))
	{
		TDEATHLOOP(org)
		{
		#ifdef SVQC
			if (!(teamplay && autocvar_g_telefrags_teamplay && head.team == player.team))
		#endif
				if(IS_PLAYER(head))
					if(!PHYS_DEAD(head))
						return 1;
		}
	}
	return 0;
}

#ifdef SVQC

void trigger_teleport_link(entity this);

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
				Damage (head, teleporter, telefragger, 10000, DEATH_TELEFRAG.m_id, head.origin, '0 0 0');
			}
		}
		else // dead bodies and monsters gib themselves instead of telefragging
			Damage (telefragger, teleporter, telefragger, 10000, DEATH_TELEFRAG.m_id, telefragger.origin, '0 0 0');
	}
}

void spawn_tdeath(vector v0, entity e, vector v)
{
	tdeath(e, e, e, '0 0 0', '0 0 0');
}

#endif

void TeleportPlayer(entity teleporter, entity player, vector to, vector to_angles, vector to_velocity, vector telefragmin, vector telefragmax, float tflags)
{SELFPARAM();
	entity telefragger;
	vector from;

	if(teleporter.owner)
		telefragger = teleporter.owner;
	else
		telefragger = player;

	makevectors (to_angles);

#ifdef SVQC
	if(player.teleportable == TELEPORT_NORMAL) // don't play sounds or show particles for anything that isn't a player, maybe change later to block only observers
	{
		if(self.pushltime < time) // only show one teleport effect per teleporter per 0.2 seconds, for better fps
		{
			if(tflags & TELEPORT_FLAG_SOUND)
				sound (player, CH_TRIGGER, SND_TELEPORT, VOL_BASE, ATTEN_NORM);
			if(tflags & TELEPORT_FLAG_PARTICLES)
			{
				Send_Effect(EFFECT_TELEPORT, player.origin, '0 0 0', 1);
				Send_Effect(EFFECT_TELEPORT, to + v_forward * 32, '0 0 0', 1);
			}
			self.pushltime = time + 0.2;
		}
	}
#endif

	// Relocate the player
	// assuming to allows PL_MIN to PL_MAX box and some more
#ifdef SVQC
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
	UpdateItemAfterTeleport(player);
#elif defined(CSQC)
	from = player.move_origin;
	player.move_origin = to;
	player.move_angles = to_angles;
	player.move_velocity = to_velocity;
	player.move_flags &= ~FL_ONGROUND;
	player.iflags |= IFLAG_TELEPORTED | IFLAG_V_ANGLE | IFLAG_ANGLES;
	player.csqcmodel_teleported = 1;
	player.v_angle = to_angles;

	if(player.isplayermodel) // not for anything but the main player
	{
		setproperty(VF_ANGLES, player.move_angles);
		setproperty(VF_CL_VIEWANGLES, player.move_angles);
	}

	makevectors(player.move_angles);
#endif

#ifdef SVQC
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
#endif
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
			if(STAT(TELEPORT_TELEFRAG_AVOID, player))
			{
			#ifdef SVQC
				locout = e.origin + '0 0 1' * (1 - player.mins.z - 24);
			#elif defined(CSQC)
				locout = e.origin + '0 0 1' * (1 - player.mins.z - 24);
			#endif
				if(check_tdeath(player, locout, '0 0 0', '0 0 0'))
					p = 0;
			}
			RandomSelection_Add(e, 0, string_null, (e.cnt ? e.cnt : 1), p);
		}
		e = RandomSelection_chosen_ent;
	}

#ifdef SVQC
	if(!e) { sprint(player, "Teleport destination vanished. Sorry... please complain to the mapper.\n"); }
#elif defined(CSQC)
	if(!e) { LOG_INFO("Teleport destination could not be found from CSQC.\n"); }
#endif

	makevectors(e.mangle);

#ifdef SVQC
	if(e.speed)
		if(vlen(player.velocity) > e.speed)
			player.velocity = normalize(player.velocity) * max(0, e.speed);
#elif defined(CSQC)
	if(e.speed)
		if(vlen(player.move_velocity) > e.speed)
			player.move_velocity = normalize(player.move_velocity) * max(0, e.speed);
#endif

#ifdef SVQC
	if(STAT(TELEPORT_MAXSPEED, player))
		if(vlen(player.velocity) > STAT(TELEPORT_MAXSPEED, player))
			player.velocity = normalize(player.velocity) * max(0, STAT(TELEPORT_MAXSPEED, player));
#elif defined(CSQC)
	if(STAT(TELEPORT_MAXSPEED, player))
		if(vlen(player.move_velocity) > STAT(TELEPORT_MAXSPEED, player))
			player.move_velocity = normalize(player.move_velocity) * max(0, STAT(TELEPORT_MAXSPEED, player));
#endif

#ifdef SVQC
	locout = e.origin + '0 0 1' * (1 - player.mins.z - 24);

	TeleportPlayer(teleporter, player, locout, e.mangle, v_forward * vlen(player.velocity), '0 0 0', '0 0 0', TELEPORT_FLAGS_TELEPORTER);
#elif defined(CSQC)
	locout = e.origin + '0 0 1' * (1 - player.mins.z - 24);

	TeleportPlayer(teleporter, player, locout, e.mangle, v_forward * vlen(player.move_velocity), '0 0 0', '0 0 0', TELEPORT_FLAGS_TELEPORTER);
#endif

	return e;
}

void teleport_findtarget()
{
	int n = 0;
	entity e;
	for(e = world; (e = find(e, targetname, self.target)); )
	{
		++n;
#ifdef SVQC
		if(e.movetype == MOVETYPE_NONE)
			waypoint_spawnforteleporter(self, e.origin, 0);
		if(e.classname != "info_teleport_destination")
			LOG_INFO("^3MAPPER ERROR: teleporter does target an invalid teleport destination entity. Angles will not work.\n");
#endif
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
#ifdef SVQC
	self.touch = Teleport_Touch;

	trigger_teleport_link(self);
#elif defined(CSQC)
	self.move_touch = Teleport_Touch;
#endif
}

entity Teleport_Find(vector mi, vector ma)
{
	entity e;
	for(e = world; (e = find(e, classname, "trigger_teleport")); )
		if(WarpZoneLib_BoxTouchesBrush(mi, ma, e, world))
			return e;
	return world;
}

void WarpZone_PostTeleportPlayer_Callback(entity pl)
{SELFPARAM();
#ifdef SVQC
	makevectors(pl.angles);
	Reset_ArcBeam(pl, v_forward);
	UpdateCSQCProjectileAfterTeleport(pl);
	UpdateItemAfterTeleport(pl);
	{
		WITH(entity, self, pl, anticheat_fixangle());
	}
#endif
	// "disown" projectiles after teleport
	if(pl.owner)
	if(pl.owner == pl.realowner)
	{
	#ifdef SVQC
		if(!(pl.flags & FL_PROJECTILE))
	#elif defined(CSQC)
		if(!(pl.move_flags & BIT(15))) // FL_PROJECTILE
	#endif
			LOG_INFO("A non-projectile got through a warpzone and its owner cleared. It's a ", pl.classname, ".\n");
		pl.owner = world;
	}
	if(IS_PLAYER(pl))
	{
		// reset tracking of oldvelocity for impact damage (sudden velocity changes)
	#ifdef SVQC
		pl.oldvelocity = pl.velocity;
	#endif
		// reset teleport time tracking too (or multijump can cause insane speeds)
		pl.lastteleporttime = time;
	}
}
