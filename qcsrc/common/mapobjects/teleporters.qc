#include "teleporters.qh"

#if defined(CSQC)
#elif defined(MENUQC)
#elif defined(SVQC)
	#include <common/constants.qh>
	#include <common/deathtypes/all.qh>
	#include <common/gametypes/_mod.qh>
	#include <common/mapobjects/subs.qh>
	#include <common/stats.qh>
	#include <common/turrets/sv_turrets.qh>
	#include <common/util.qh>
	#include <common/vehicles/all.qh>
	#include <common/weapons/_all.qh>
	#include <lib/warpzone/common.qh>
	#include <lib/warpzone/server.qh>
	#include <lib/warpzone/util_server.qh>
	#include <server/anticheat.qh>
	#include <server/weapons/csqcprojectile.qh>
#endif

#ifdef SVQC
float check_tdeath(entity player, vector org, vector telefragmin, vector telefragmax)
{
	if (IS_PLAYER(player) && !IS_DEAD(player))
	{
		TDEATHLOOP(org)
		{
		#ifdef SVQC
			if (!(teamplay && autocvar_g_telefrags_teamplay && head.team == player.team))
		#endif
				if(IS_PLAYER(head))
					if(!IS_DEAD(head))
						return 1;
		}
	}
	return 0;
}

void trigger_teleport_link(entity this);

void tdeath(entity player, entity teleporter, entity telefragger, vector telefragmin, vector telefragmax)
{
	TDEATHLOOP(player.origin)
	{
		if (IS_PLAYER(player) && GetResource(player, RES_HEALTH) >= 1)
		{
			if (!(teamplay && autocvar_g_telefrags_teamplay && head.team == player.team))
			{
				if(IS_PLAYER(head))
					if(GetResource(head, RES_HEALTH) >= 1)
						++tdeath_hit;
				Damage (head, teleporter, telefragger, 10000, DEATH_TELEFRAG.m_id, DMG_NOWEP, head.origin, '0 0 0');
			}
		}
		else // dead bodies and monsters gib themselves instead of telefragging
			Damage (telefragger, teleporter, telefragger, 10000, DEATH_TELEFRAG.m_id, DMG_NOWEP, telefragger.origin, '0 0 0');
	}
}

void spawn_tdeath(vector v0, entity e, vector v)
{
	tdeath(e, e, e, '0 0 0', '0 0 0');
}
#endif

void TeleportPlayer(entity teleporter, entity player, vector to, vector to_angles, vector to_velocity, vector telefragmin, vector telefragmax, float tflags)
{
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
		if(teleporter.pushltime < time) // only show one teleport effect per teleporter per 0.2 seconds, for better fps
		{
			if(tflags & TELEPORT_FLAG_SOUND)
			{
				string thesound = SND(TELEPORT);
				if(teleporter.noise != "")
				{
					RandomSelection_Init();
					FOREACH_WORD(teleporter.noise, true,
					{
						RandomSelection_AddString(it, 1, 1);
					});
					thesound = RandomSelection_chosen_string;
				}
				_sound (player, CH_TRIGGER, thesound, VOL_BASE, ATTEN_NORM);
			}
			if(tflags & TELEPORT_FLAG_PARTICLES)
			{
				Send_Effect(EFFECT_TELEPORT, player.origin, '0 0 0', 1);
				Send_Effect(EFFECT_TELEPORT, to + v_forward * 32, '0 0 0', 1);
			}
			teleporter.pushltime = time + 0.2;
		}
	}
#endif

	// Relocate the player
	// assuming to allows PL_MIN to PL_MAX box and some more
#ifdef SVQC
	from = player.origin;
	setorigin(player, to);
	player.oldorigin = to; // don't undo the teleport by unsticking
	player.angles = to_angles;
	if (IS_BOT_CLIENT(player))
	{
		player.v_angle = player.angles;
		bot_aim_reset(player);
	}
	player.fixangle = true;
	player.velocity = to_velocity;
	BITXOR_ASSIGN(player.effects, EF_TELEPORT_BIT);

	makevectors(player.angles);
	Reset_ArcBeam(player, v_forward);
	UpdateCSQCProjectileAfterTeleport(player);
	UpdateItemAfterTeleport(player);
#elif defined(CSQC)
	from = player.origin;
	setorigin(player, to);
	player.angles = to_angles;
	player.velocity = to_velocity;
	UNSET_ONGROUND(player);
	player.iflags |= IFLAG_TELEPORTED | IFLAG_V_ANGLE | IFLAG_ANGLES;
	player.csqcmodel_teleported = 1;
	player.v_angle = to_angles;

	if(player == csqcplayer) // not for anything but the main player
	{
		setproperty(VF_ANGLES, player.angles);
		setproperty(VF_CL_VIEWANGLES, player.angles);
	}
#endif

#ifdef SVQC
	if(IS_PLAYER(player))
	{
		if((tflags & TELEPORT_FLAG_TDEATH) && player.takedamage && !IS_DEAD(player)
			&& !g_race && !g_cts && (autocvar_g_telefrags || (tflags & TELEPORT_FLAG_FORCE_TDEATH))
			&& !(round_handler_IsActive() && !round_handler_IsRoundStarted()))
		{
			tdeath(player, teleporter, telefragger, telefragmin, telefragmax);
		}

		// player no longer is on ground
		UNSET_ONGROUND(player);

		// reset tracking of oldvelocity for impact damage (sudden velocity changes)
		player.oldvelocity = player.velocity;

		// reset tracking of who pushed you into a hazard (for kill credit)
		if(teleporter.owner)
		{
			player.pusher = teleporter.owner;
			player.pushltime = time + autocvar_g_maxpushtime;
			player.istypefrag = PHYS_INPUT_BUTTON_CHAT(player);
		}
		else
		{
			player.pushltime = 0;
			player.istypefrag = 0;
		}

		player.lastteleporttime = time;
		player.lastteleport_origin = from;
	}
#endif
}

entity Simple_TeleportPlayer(entity teleporter, entity player)
{
	vector locout;
	entity e = NULL;

	// Find the output teleporter
	if(teleporter.enemy)
	{
		e = teleporter.enemy;
	}
	else
	{
		// sorry CSQC, random stuff ain't gonna happen
#ifdef SVQC
		RandomSelection_Init();
		FOREACH_ENTITY_STRING(targetname, teleporter.target,
		{
			bool p = true;
			if(STAT(TELEPORT_TELEFRAG_AVOID, player))
			{
			#ifdef SVQC
				locout = it.origin + '0 0 1' * (1 - player.mins.z - 24);
			#elif defined(CSQC)
				locout = it.origin + '0 0 1' * (1 - player.mins.z - 24);
			#endif
				if(check_tdeath(player, locout, '0 0 0', '0 0 0'))
					p = false;
			}
			RandomSelection_AddEnt(it, (it.cnt ? it.cnt : 1), p);
		});
		e = RandomSelection_chosen_ent;
#endif
	}

#ifdef SVQC
	if(!e) { sprint(player, "Teleport destination vanished. Sorry... please complain to the mapper.\n"); }
#elif defined(CSQC)
	if(!e) { LOG_INFO("Teleport destination could not be found from CSQC."); }
#endif

	makevectors(e.mangle);

	if(e.speed)
		if(vdist(player.velocity, >, e.speed))
			player.velocity = normalize(player.velocity) * max(0, e.speed);

	if(!(teleporter.classname == "trigger_teleport" && (teleporter.spawnflags & TELEPORT_KEEP_SPEED)) &&
	   !(teleporter.classname == "target_teleporter" && (teleporter.spawnflags & TARGET_TELEPORTER_KEEP_SPEED)))
	{
		// test if player is slower than min
		if(STAT(TELEPORT_MINSPEED, player))
			if(vdist(player.velocity, <, STAT(TELEPORT_MINSPEED, player)))
				player.velocity = normalize(player.velocity) * max(0, STAT(TELEPORT_MINSPEED, player));
		// test if player is faster than max (or if min is above max)
		if(STAT(TELEPORT_MAXSPEED, player))
			if(vdist(player.velocity, >, STAT(TELEPORT_MAXSPEED, player)))
				player.velocity = normalize(player.velocity) * max(0, STAT(TELEPORT_MAXSPEED, player));
	}

	locout = e.origin + '0 0 1' * (1 - player.mins.z - 24);

	TeleportPlayer(teleporter, player, locout, e.mangle, v_forward * vlen(player.velocity), '0 0 0', '0 0 0', TELEPORT_FLAGS_TELEPORTER);

	return e;
}

void teleport_findtarget(entity this)
{
	bool istrigger = (this.solid == SOLID_TRIGGER);

	int n = 0;
	for(entity e = NULL; (e = find(e, targetname, this.target)); )
	{
		++n;
#ifdef SVQC
		if(e.move_movetype == MOVETYPE_NONE)
		{
			entity tracetest_ent = spawn();
			setsize(tracetest_ent, PL_MIN_CONST, PL_MAX_CONST);
			tracetest_ent.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_PLAYERCLIP | DPCONTENTS_BOTCLIP;
			waypoint_spawnforteleporter(this, e.origin, 0, tracetest_ent);
			delete(tracetest_ent);
		}
		if(e.classname != "info_teleport_destination")
			LOG_INFO("^3MAPPER ERROR: teleporter does target an invalid teleport destination entity. Angles will not work.");
#endif
	}

	if(n == 0)
	{
		// no dest!
		objerror (this, "Teleporter with nonexistent target");
		return;
	}
	else if(n == 1)
	{
		// exactly one dest - bots love that
		this.enemy = find(NULL, targetname, this.target);
	}
	else
	{
		// have to use random selection every single time
		this.enemy = NULL;
	}

	// now enable touch
	if(istrigger)
		settouch(this, Teleport_Touch);
#ifdef SVQC
	if(istrigger)
		trigger_teleport_link(this);
#endif
}

entity Teleport_Find(vector mi, vector ma)
{
	IL_EACH(g_teleporters, WarpZoneLib_BoxTouchesBrush(mi, ma, it, NULL),
	{
		return it;
	});
	return NULL;
}

void WarpZone_PostTeleportPlayer_Callback(entity pl)
{
#ifdef SVQC
	makevectors(pl.angles);
	Reset_ArcBeam(pl, v_forward);
	UpdateCSQCProjectileAfterTeleport(pl);
	UpdateItemAfterTeleport(pl);
    if (IS_PLAYER(pl)) anticheat_fixangle(pl);
#endif
	// "disown" projectiles after teleport
	if(pl.owner)
	if(pl.owner == pl.realowner)
	{
	#ifdef SVQC
		if(!(pl.flags & FL_PROJECTILE))
	#elif defined(CSQC)
		if(!(pl.flags & BIT(15))) // FL_PROJECTILE
	#endif
			LOG_INFO("A non-projectile got through a warpzone and its owner cleared. It's a ", pl.classname, ".");
		pl.owner = NULL;
	}
	if(IS_PLAYER(pl))
	{
		// reset tracking of oldvelocity for impact damage (sudden velocity changes)
	#ifdef SVQC
		pl.oldvelocity = pl.velocity;
	#endif
	}
}
