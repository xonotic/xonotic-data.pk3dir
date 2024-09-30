#include "common_physics.qh"

#include <lib/csqcmodel/cl_player.qh>
#include <common/physics/player.qh>
#include <common/physics/movetypes/movetypes.qh>

// non-local players
#include <common/animdecide.qh> // for anim_implicit_state
#include <common/ent_cs.qh> // for CSQCModel_server2csqc()

void HUD_Physics_Init()
{
	// find out whether the local csqcmodel entity is valid
	if(spectatee_status > 0 || isdemo())
	{
		islocal = false;
		strafeplayer = CSQCModel_server2csqc(player_localentnum - 1);
	}
	else
	{
		islocal = true;
		strafeplayer = csqcplayer;
	}

	if(csqcplayer && strafeplayer)
		csqc_and_strafe_player = true;
	else
	{
		csqc_and_strafe_player = false;
		// Since both huds return (essentially) when this is false, no variables beyond this point need to be computed
		return;
	}

	predicted = csqcplayer_status == CSQCPLAYERSTATUS_PREDICTED;

	// check the player waterlevel without affecting the player entity, this way we can fetch waterlevel even if client prediction is disabled
	{
		// store old values
		void old_contentstransition(int, int) = strafeplayer.contentstransition;
		float old_watertype = strafeplayer.watertype;
		float old_waterlevel = strafeplayer.waterlevel;

		strafeplayer.contentstransition = func_null; // unset the contentstransition function if present
		_Movetype_CheckWater(strafeplayer);
		strafe_waterlevel = strafeplayer.waterlevel; // store the player waterlevel

		// restore old values
		strafeplayer.contentstransition = old_contentstransition;
		strafeplayer.watertype = old_watertype;
		strafeplayer.waterlevel = old_waterlevel;
	}

	movement_phys = PHYS_INPUT_MOVEVALUES(strafeplayer);
	keys = STAT(PRESSED_KEYS);
	// try to ignore if track_canjump is enabled, doesn't work in spectator mode if spectated player uses +jetpack or cl_movement_track_canjump
	jumpheld = false;
	if(islocal)
	{
		if((PHYS_INPUT_BUTTON_JUMP(strafeplayer) || PHYS_INPUT_BUTTON_JETPACK(strafeplayer)) && !PHYS_CL_TRACK_CANJUMP(strafeplayer))
			jumpheld = true;
	}
	else
	{
		if((keys & KEY_JUMP) && !PHYS_TRACK_CANJUMP(strafeplayer))
			jumpheld = true;
	}

	// doesn't get changed by ground timeout and isn't affected by jump input
	real_onground = islocal ? IS_ONGROUND(strafeplayer) : !(strafeplayer.anim_implicit_state & ANIMIMPLICITSTATE_INAIR);
	// doesn't get changed by ground timeout
	real_onslick  = false;
	// if jump is held assume we are in air, avoids flickering of the hud when hitting the ground
	onground      = (real_onground && !jumpheld);
	onslick       = real_onslick;
	// the hud will not work well while swimming
	swimming      = strafe_waterlevel >= WATERLEVEL_SWIMMING;
	// use local csqcmodel entity for this even when spectating, flickers too much otherwise
	vel_phys      = csqcplayer.velocity;
	speed_phys    = vlen(vec2(vel_phys));
	speed3d_phys  = vlen(vel_phys);
	immobile      = speed_phys <= 0;

	// only the local csqcplayer entity contains this information even when spectating
	maxspeed_mod  = IS_DUCKED(csqcplayer) ? .5 : 1;
	maxspeed_phys = onground ? maxspeed_ground : maxspeed_air;
	maxspeed      = maxspeed_phys * maxspeed_mod;
	maxaccel_phys = onground ? maxaccel_ground : maxaccel_air;
	maxaccel      = maxaccel_phys;

	// change the range from 0° - 360° to -180° - 180° to match how view_angle represents angles
	vel_angle     = vectoangles(strafeplayer.velocity).y - (vectoangles(strafeplayer.velocity).y > 180 ? 360 : 0);
	view_angle    = PHYS_INPUT_ANGLES(strafeplayer).y;

	airstopaccel  = PHYS_AIRSTOPACCELERATE(strafeplayer);
	if(!airstopaccel)
		airstopaccel = 1; // values of 0 are equivalent to 1

	if(onground)
	{
		if(friction_phys == 0)
		{
			onslick = true;
		}
		else // don't use IS_ONSLICK(), it only works for the local player and only if client prediction is enabled
		{
			trace_dphitq3surfaceflags = 0;
			tracebox(strafeplayer.origin, strafeplayer.mins, strafeplayer.maxs, strafeplayer.origin - '0 0 1', MOVE_NOMONSTERS, strafeplayer);
			onslick = trace_dphitq3surfaceflags & Q3SURFACEFLAG_SLICK;
		}
		real_onslick = onslick;

		onground_lasttime = time;
		onslick_last = onslick;
	}
	else if(jumpheld || swimming)
	{
		onground_lasttime = 0;
	}

	strafefriction = onslick ? friction_slick : friction_phys;
	alive_player   = (!IS_DEAD(strafeplayer) && IS_PLAYER(strafeplayer));
}
