#include "player.qh"

#include <common/mapobjects/_mod.qh>
#include <common/viewloc.qh>

#ifdef GAMEQC
REPLICATE(cvar_cl_physics, string, "cl_physics");
REPLICATE(cvar_cl_jetpack_jump, bool, "cl_jetpack_jump");
REPLICATE(cvar_cl_movement_track_canjump, bool, "cl_movement_track_canjump");
#endif

#ifdef SVQC
#include <common/mapobjects/defs.qh>
#include <common/mapobjects/trigger/viewloc.qh>
#include <server/client.qh>

// client side physics
bool Physics_Valid(string thecvar)
{
	return thecvar != "" && thecvar && thecvar != "default" && strhasword(autocvar_g_physics_clientselect_options, thecvar);
}

float Physics_ClientOption(entity this, string option, float defaultval)
{
	if(!autocvar_g_physics_clientselect)
		return defaultval;

	if(IS_REAL_CLIENT(this) && Physics_Valid(CS_CVAR(this).cvar_cl_physics))
	{
		string s = strcat("g_physics_", CS_CVAR(this).cvar_cl_physics, "_", option);
		if(cvar_type(s) & CVAR_TYPEFLAG_EXISTS)
			return cvar(s);
	}
	if(autocvar_g_physics_clientselect_default && autocvar_g_physics_clientselect_default != "" && autocvar_g_physics_clientselect_default != "default")
	{
		// NOTE: not using Physics_Valid here, so the default can be forced to something normally unavailable
		string s = strcat("g_physics_", autocvar_g_physics_clientselect_default, "_", option);
		if(cvar_type(s) & CVAR_TYPEFLAG_EXISTS)
			return cvar(s);
	}
	return defaultval;
}

void Physics_UpdateStats(entity this)
{
	// update this first, as it's used on all stats (wouldn't want to update them all manually from a mutator hook now, would we?)
	STAT(MOVEVARS_HIGHSPEED, this) = autocvar_g_movement_highspeed;

	MUTATOR_CALLHOOK(PlayerPhysics_UpdateStats, this);
	float maxspd_mod = PHYS_HIGHSPEED(this) * ((this.swampslug.active == ACTIVE_ACTIVE) ? this.swampslug.swamp_slowdown : 1);
	STAT(MOVEVARS_MAXSPEED, this) = Physics_ClientOption(this, "maxspeed", autocvar_sv_maxspeed) * maxspd_mod; // also slow walking
	if (autocvar_g_movement_highspeed_q3_compat)
	{
		STAT(MOVEVARS_AIRACCEL_QW, this) = Physics_ClientOption(this, "airaccel_qw", autocvar_sv_airaccel_qw);
		STAT(MOVEVARS_AIRSTRAFEACCEL_QW, this) = Physics_ClientOption(this, "airstrafeaccel_qw", autocvar_sv_airstrafeaccel_qw);
		STAT(MOVEVARS_AIRSPEEDLIMIT_NONQW, this) = Physics_ClientOption(this, "airspeedlimit_nonqw", autocvar_sv_airspeedlimit_nonqw);
	}
	else
	{
		STAT(MOVEVARS_AIRACCEL_QW, this) = AdjustAirAccelQW(Physics_ClientOption(this, "airaccel_qw", autocvar_sv_airaccel_qw), maxspd_mod);
		STAT(MOVEVARS_AIRSTRAFEACCEL_QW, this) = (Physics_ClientOption(this, "airstrafeaccel_qw", autocvar_sv_airstrafeaccel_qw))
			? AdjustAirAccelQW(Physics_ClientOption(this, "airstrafeaccel_qw", autocvar_sv_airstrafeaccel_qw), maxspd_mod)
			: 0;
		STAT(MOVEVARS_AIRSPEEDLIMIT_NONQW, this) = Physics_ClientOption(this, "airspeedlimit_nonqw", autocvar_sv_airspeedlimit_nonqw) * maxspd_mod;
	}

	if (autocvar_sv_mapformat_is_quake3)
	{
		/* Q3 uses the following:
		 *                 MIN '-15 -15 -24'
		 *                 MAX '15 15 32'
		 *            VIEW_OFS '0 0 26'
		 *          CROUCH_MIN '-15 -15 -24'
		 *          CROUCH_MAX '15 15 16'
		 *     CROUCH_VIEW_OFS '0 0 12'
		 * but Xonotic player models have a different z offset to suit origin at 24/69.
		 * At q3compat hitbox dimensions and model scale the equivalent offset is origin at 20/56.
		 * See also: model .scale in PutPlayerInServer().
		 */
		bool q3hb = q3compat && autocvar_sv_q3compat_changehitbox;
		STAT(PL_MIN, this)             = q3hb ? '-15 -15 -20' : autocvar_sv_player_mins;
		STAT(PL_MAX, this)             = q3hb ? '15 15 36'    : autocvar_sv_player_maxs;
		STAT(PL_VIEW_OFS, this)        = q3hb ? '0 0 30'      : autocvar_sv_player_viewoffset;
		STAT(PL_CROUCH_MIN, this)      = q3hb ? '-15 -15 -20' : autocvar_sv_player_crouch_mins;
		STAT(PL_CROUCH_MAX, this)      = q3hb ? '15 15 20'    : autocvar_sv_player_crouch_maxs;
		STAT(PL_CROUCH_VIEW_OFS, this) = q3hb ? '0 0 16'      : autocvar_sv_player_crouch_viewoffset;
	}
	else
	{
		/* Quake and Q2 use a wider bbox matching the Q1BSP 32x32x56 cliphull:
		 *                 MIN '-16 -16 -24'
		 *                 MAX '16 16 32'
		 *            VIEW_OFS '0 0 22'
		 * Quake doesn't support crouching, Q2 has a very low crouch:
		 *          CROUCH_MIN '-16 -16 -24'
		 *          CROUCH_MAX '16 16 4'
		 *     CROUCH_VIEW_OFS '0 0 -2'
		 * We probably want a higher VIEW_OFS and Xonotic models don't crouch low enough for Q2 settings
		 * so these are the same heights as for Q3 above.
		 */
		STAT(PL_MIN, this)             = '-16 -16 -20';
		STAT(PL_MAX, this)             = '16 16 36';
		STAT(PL_VIEW_OFS, this)        = '0 0 30';
		STAT(PL_CROUCH_MIN, this)      = '-16 -16 -20';
		// Q1BSP has no cliphull to support crouching so disable it there, see PM_ClientMovement_UpdateStatus().
		STAT(PL_CROUCH_MAX, this)      = autocvar_sv_mapformat_is_quake2 ? '16 16 20' : STAT(PL_MAX, this);
		STAT(PL_CROUCH_VIEW_OFS, this) = autocvar_sv_mapformat_is_quake2 ? '0 0 16'   : STAT(PL_VIEW_OFS, this);
	}

	// old stats
	// fix some new settings
	STAT(MOVEVARS_AIRACCEL_QW_STRETCHFACTOR, this) = Physics_ClientOption(this, "airaccel_qw_stretchfactor", autocvar_sv_airaccel_qw_stretchfactor);
	STAT(MOVEVARS_MAXAIRSTRAFESPEED, this) = Physics_ClientOption(this, "maxairstrafespeed", autocvar_sv_maxairstrafespeed);
		if (autocvar_g_movement_highspeed_q3_compat)
			STAT(MOVEVARS_MAXAIRSPEED, this) = Physics_ClientOption(this, "maxairspeed", autocvar_sv_maxairspeed) * maxspd_mod;
		else
			STAT(MOVEVARS_MAXAIRSPEED, this) = Physics_ClientOption(this, "maxairspeed", autocvar_sv_maxairspeed);

	STAT(MOVEVARS_AIRSTRAFEACCELERATE, this) = Physics_ClientOption(this, "airstrafeaccelerate", autocvar_sv_airstrafeaccelerate);
	STAT(MOVEVARS_WARSOWBUNNY_TURNACCEL, this) = Physics_ClientOption(this, "warsowbunny_turnaccel", autocvar_sv_warsowbunny_turnaccel);
	STAT(MOVEVARS_AIRACCEL_SIDEWAYS_FRICTION, this) = Physics_ClientOption(this, "airaccel_sideways_friction", autocvar_sv_airaccel_sideways_friction);
	STAT(MOVEVARS_AIRCONTROL, this) = Physics_ClientOption(this, "aircontrol", autocvar_sv_aircontrol);
	STAT(MOVEVARS_AIRCONTROL_FLAGS, this) = Physics_ClientOption(this, "aircontrol_flags", autocvar_sv_aircontrol_flags);
	STAT(MOVEVARS_AIRCONTROL_POWER, this) = Physics_ClientOption(this, "aircontrol_power", autocvar_sv_aircontrol_power);
	STAT(MOVEVARS_AIRCONTROL_PENALTY, this) = Physics_ClientOption(this, "aircontrol_penalty", autocvar_sv_aircontrol_penalty);
	STAT(MOVEVARS_WARSOWBUNNY_AIRFORWARDACCEL, this) = Physics_ClientOption(this, "warsowbunny_airforwardaccel", autocvar_sv_warsowbunny_airforwardaccel);
	STAT(MOVEVARS_WARSOWBUNNY_TOPSPEED, this) = Physics_ClientOption(this, "warsowbunny_topspeed", autocvar_sv_warsowbunny_topspeed);
	STAT(MOVEVARS_WARSOWBUNNY_ACCEL, this) = Physics_ClientOption(this, "warsowbunny_accel", autocvar_sv_warsowbunny_accel);
	STAT(MOVEVARS_WARSOWBUNNY_BACKTOSIDERATIO, this) = Physics_ClientOption(this, "warsowbunny_backtosideratio", autocvar_sv_warsowbunny_backtosideratio);
	STAT(MOVEVARS_FRICTION, this) = Physics_ClientOption(this, "friction", autocvar_sv_friction);
	STAT(MOVEVARS_ACCELERATE, this) = Physics_ClientOption(this, "accelerate", autocvar_sv_accelerate);
	STAT(MOVEVARS_STOPSPEED, this) = Physics_ClientOption(this, "stopspeed", autocvar_sv_stopspeed);
	STAT(MOVEVARS_AIRACCELERATE, this) = Physics_ClientOption(this, "airaccelerate", autocvar_sv_airaccelerate);
	STAT(MOVEVARS_AIRSTOPACCELERATE, this) = Physics_ClientOption(this, "airstopaccelerate", autocvar_sv_airstopaccelerate);
	STAT(MOVEVARS_AIRSTOPACCELERATE_FULL, this) = Physics_ClientOption(this, "airstopaccelerate_full", autocvar_sv_airstopaccelerate_full);
	STAT(MOVEVARS_SLICKACCELERATE, this) = Physics_ClientOption(this, "slickaccelerate", autocvar_sv_slickaccelerate);
	STAT(MOVEVARS_JUMPVELOCITY, this) = Physics_ClientOption(this, "jumpvelocity", autocvar_sv_jumpvelocity);
	STAT(MOVEVARS_JUMPVELOCITY_CROUCH, this) = Physics_ClientOption(this, "jumpvelocity_crouch", autocvar_sv_jumpvelocity_crouch);
	STAT(MOVEVARS_TRACK_CANJUMP, this) = Physics_ClientOption(this, "track_canjump", autocvar_sv_track_canjump);

	MUTATOR_CALLHOOK(PlayerPhysics_PostUpdateStats, this, maxspd_mod);
}
#endif

float IsMoveInDirection(vector mv, float ang) // key mix factor
{
	if (mv_x == 0 && mv_y == 0)
		return 0; // avoid division by zero
	ang -= RAD2DEG * atan2(mv_y, mv_x);
	ang = remainder(ang, 360) / 45;
	return ang > 1 ? 0 : ang < -1 ? 0 : 1 - fabs(ang);
}

float GeomLerp(float a, float _lerp, float b)
{
	return a == 0 ? (_lerp < 1 ? 0 : b)
		: b == 0 ? (_lerp > 0 ? 0 : a)
		: a * (fabs(b / a) ** _lerp);
}

void PM_ClientMovement_UpdateStatus(entity this)
{
	if(!IS_PLAYER(this))
		return;

	bool have_hook = false;
	for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	{
	#if defined(CSQC)
		entity wepent = viewmodels[slot];
	#elif defined(SVQC)
		.entity weaponentity = weaponentities[slot];
		entity wepent = this.(weaponentity);
	#endif
		if(wepent.hook && !wasfreed(wepent.hook))
		{
			have_hook = true;
			break;
		}
	}
	bool do_crouch = PHYS_INPUT_BUTTON_CROUCH(this);
	if(this.viewloc && !(this.viewloc.spawnflags & VIEWLOC_FREEMOVE) && PHYS_CS(this).movement.x < 0)
		do_crouch = true;
	if (have_hook) {
		do_crouch = false;
	//} else if (this.waterlevel >= WATERLEVEL_SWIMMING) {
		//do_crouch = false;
	} else if (PHYS_INVEHICLE(this)) {
		do_crouch = false;
	} else if (PHYS_FROZEN(this) || IS_DEAD(this)) {
		do_crouch = false;
	}

	MUTATOR_CALLHOOK(PlayerCanCrouch, this, do_crouch);
	do_crouch = M_ARGV(1, bool);

	// Disable crouching on Q1BSP because it lacks a suitable cliphull (HLBSP added one).
	if (STAT(PL_CROUCH_MAX, this).z == STAT(PL_MAX, this).z)
		do_crouch = false;

	if (do_crouch) {
		if (!IS_DUCKED(this)) {
			SET_DUCKED(this);
			this.view_ofs = STAT(PL_CROUCH_VIEW_OFS, this);
			setsize(this, STAT(PL_CROUCH_MIN, this), STAT(PL_CROUCH_MAX, this));
			// setanim(this, this.anim_duck, false, true, true); // this anim is BROKEN anyway
		}
	} else if (IS_DUCKED(this)) {
		tracebox(this.origin, STAT(PL_MIN, this), STAT(PL_MAX, this), this.origin, MOVE_NORMAL, this);
		if (!trace_startsolid) {
			UNSET_DUCKED(this);
			this.view_ofs = STAT(PL_VIEW_OFS, this);
			setsize(this, STAT(PL_MIN, this), STAT(PL_MAX, this));
		}
	}

	_Movetype_CheckWater(this); // needs to be run on the client, might as well use the latest on the server too!
}

void CPM_PM_Aircontrol(entity this, float dt, vector wishdir, float wishspeed)
{
	float movity = IsMoveInDirection(PHYS_CS(this).movement, 0);
	if(PHYS_AIRCONTROL_FLAGS(this) & BIT(0)) // backwards
		movity += IsMoveInDirection(PHYS_CS(this).movement, 180);
	if(PHYS_AIRCONTROL_FLAGS(this) & BIT(1)) // sidewards
	{
		movity += IsMoveInDirection(PHYS_CS(this).movement, 90);
		movity += IsMoveInDirection(PHYS_CS(this).movement, -90);
	}

	float k = 2 * movity - 1;
	if (k <= 0)
		return;
	if (!(PHYS_AIRCONTROL_FLAGS(this) & BIT(2))) // crouching has an impact
		k *= bound(0, wishspeed / PHYS_MAXAIRSPEED(this), 1);

	const float zspeed = this.velocity_z;
	this.velocity_z = 0;
	float xyspeed = vlen(this.velocity);
	this.velocity = normalize(this.velocity);

	float dot = this.velocity * wishdir;

	if (dot > 0) // we can't change direction while slowing down
	{
		k *= (dot ** PHYS_AIRCONTROL_POWER(this)) * dt;
		xyspeed = max(0, xyspeed - PHYS_AIRCONTROL_PENALTY(this) * sqrt(max(0, 1 - dot*dot)) * k);
		k *= 32 * fabs(PHYS_AIRCONTROL(this));
		this.velocity = normalize(this.velocity * xyspeed + wishdir * k);
	}

	this.velocity = this.velocity * xyspeed;
	this.velocity_z = zspeed;
}

float AdjustAirAccelQW(float accelqw, float factor)
{
	return copysign(bound(0.000001, 1 - (1 - fabs(accelqw)) * factor, 1), accelqw);
}

// example config for alternate speed clamping:
//   sv_airaccel_qw 0.8
//   sv_airaccel_sideways_friction 0
//   prvm_globalset server speedclamp_mode 1
//     (or 2)
void PM_Accelerate(entity this, float dt, vector wishdir, float wishspeed, float wishspeed0, float accel, float accelqw, float stretchfactor, float sidefric, float speedlimit)
{
	float speedclamp = stretchfactor > 0 ? stretchfactor
	: accelqw < 0 ? 1 // full clamping, no stretch
	: -1; // no clamping

	accelqw = fabs(accelqw);

	if (GAMEPLAYFIX_Q2AIRACCELERATE)
		wishspeed0 = wishspeed; // don't need to emulate this Q1 bug

	float vel_straight = this.velocity * wishdir;
	float vel_z = this.velocity_z;
	vector vel_xy = vec2(this.velocity);
	vector vel_perpend = vel_xy - vel_straight * wishdir;

	float step = accel * dt * wishspeed0;

	float vel_xy_current  = vlen(vel_xy);
	if (speedlimit)
		accelqw = AdjustAirAccelQW(accelqw, (speedlimit - bound(wishspeed, vel_xy_current, speedlimit)) / max(1, speedlimit - wishspeed));
	float vel_xy_forward =  vel_xy_current  + bound(0, wishspeed - vel_xy_current, step) * accelqw + step * (1 - accelqw);
	float vel_xy_backward = vel_xy_current  - bound(0, wishspeed + vel_xy_current, step) * accelqw - step * (1 - accelqw);
	vel_xy_backward = max(0, vel_xy_backward); // not that it REALLY occurs that this would cause wrong behaviour afterwards
	vel_straight =          vel_straight    + bound(0, wishspeed - vel_straight,   step) * accelqw + step * (1 - accelqw);

	if (sidefric < 0 && (vel_perpend*vel_perpend))
		// negative: only apply so much sideways friction to stay below the speed you could get by "braking"
	{
		float f = max(0, 1 + dt * wishspeed * sidefric);
		float themin = (vel_xy_backward * vel_xy_backward - vel_straight * vel_straight) / (vel_perpend * vel_perpend);
		// assume: themin > 1
		// vel_xy_backward*vel_xy_backward - vel_straight*vel_straight > vel_perpend*vel_perpend
		// vel_xy_backward*vel_xy_backward > vel_straight*vel_straight + vel_perpend*vel_perpend
		// vel_xy_backward*vel_xy_backward > vel_xy * vel_xy
		// obviously, this cannot be
		if (themin <= 0)
			vel_perpend *= f;
		else
		{
			themin = sqrt(themin);
			vel_perpend *= max(themin, f);
		}
	}
	else
		vel_perpend *= max(0, 1 - dt * wishspeed * sidefric);

	vel_xy = vel_straight * wishdir + vel_perpend;

	if (speedclamp >= 0)
	{
		float vel_xy_preclamp;
		vel_xy_preclamp = vlen(vel_xy);
		if (vel_xy_preclamp > 0) // prevent division by zero
		{
			vel_xy_current += (vel_xy_forward - vel_xy_current) * speedclamp;
			if (vel_xy_current < vel_xy_preclamp)
				vel_xy *= (vel_xy_current / vel_xy_preclamp);
		}
	}

	this.velocity = vel_xy + vel_z * '0 0 1';
}

void PM_AirAccelerate(entity this, float dt, vector wishdir, float wishspeed)
{
	if (wishspeed == 0)
		return;

	vector curvel = this.velocity;
	curvel_z = 0;
	float curspeed = vlen(curvel);

	if (wishspeed > curspeed * 1.01)
		wishspeed = min(wishspeed, curspeed + PHYS_WARSOWBUNNY_AIRFORWARDACCEL(this) * PHYS_MAXSPEED(this) * dt);
	else
	{
		float f = max(0, (PHYS_WARSOWBUNNY_TOPSPEED(this) - curspeed) / (PHYS_WARSOWBUNNY_TOPSPEED(this) - PHYS_MAXSPEED(this)));
		wishspeed = max(curspeed, PHYS_MAXSPEED(this)) + PHYS_WARSOWBUNNY_ACCEL(this) * f * PHYS_MAXSPEED(this) * dt;
	}
	vector wishvel = wishdir * wishspeed;
	vector acceldir = wishvel - curvel;
	float addspeed = vlen(acceldir);
	acceldir = normalize(acceldir);

	float accelspeed = min(addspeed, PHYS_WARSOWBUNNY_TURNACCEL(this) * PHYS_MAXSPEED(this) * dt);

	if (PHYS_WARSOWBUNNY_BACKTOSIDERATIO(this) < 1)
	{
		vector curdir = normalize(curvel);
		float dot = acceldir * curdir;
		if (dot < 0)
			acceldir -= (1 - PHYS_WARSOWBUNNY_BACKTOSIDERATIO(this)) * dot * curdir;
	}

	this.velocity += accelspeed * acceldir;
}


/*
=============
PlayerJump

When you press the jump key
returns true if handled
=============
*/
bool PlayerJump(entity this)
{
	if (PHYS_FROZEN(this))
		return true; // no jumping in freezetag when frozen

	if(PHYS_INPUT_BUTTON_CHAT(this) || PHYS_INPUT_BUTTON_MINIGAME(this))
		return true; // no jumping while typing

#ifdef SVQC
	if (this.player_blocked)
		return true; // no jumping while blocked
#endif

	bool doublejump = false;
	float mjumpheight = ((PHYS_JUMPVELOCITY_CROUCH(this) && IS_DUCKED(this)) ? PHYS_JUMPVELOCITY_CROUCH(this) : PHYS_JUMPVELOCITY(this));
	bool track_jump = PHYS_CL_TRACK_CANJUMP(this);

	if (MUTATOR_CALLHOOK(PlayerJump, this, mjumpheight, doublejump))
		return true;

	mjumpheight = M_ARGV(1, float);
	doublejump = M_ARGV(2, bool);

	if (this.waterlevel >= WATERLEVEL_SWIMMING)
	{
		if(this.viewloc)
		{
			doublejump = true;
			mjumpheight *= 0.7;
			track_jump = true;
		}
		else
		{
			this.velocity_z = PHYS_MAXSPEED(this) * 0.7;
			return true;
		}
	}

	if (!doublejump)
		if (!IS_ONGROUND(this))
			return IS_JUMP_HELD(this);

	if(PHYS_TRACK_CANJUMP(this))
		track_jump = true;

	if (track_jump)
		if (IS_JUMP_HELD(this))
			return true;

	// sv_jumpspeedcap_min/sv_jumpspeedcap_max act as baseline
	// velocity bounds.  Final velocity is bound between (jumpheight *
	// min + jumpheight) and (jumpheight * max + jumpheight);

	if(PHYS_JUMPSPEEDCAP_MIN != "")
	{
		float minjumpspeed = mjumpheight * stof(PHYS_JUMPSPEEDCAP_MIN);

		if (this.velocity_z < minjumpspeed)
			mjumpheight += minjumpspeed - this.velocity_z;
	}

	if(PHYS_JUMPSPEEDCAP_MAX != "")
	{
		// don't do jump speedcaps on ramps to preserve old xonotic ramjump style
		tracebox(this.origin + '0 0 0.01', this.mins, this.maxs, this.origin - '0 0 0.01', MOVE_NORMAL, this);

		if (!(trace_fraction < 1 && trace_plane_normal_z < 0.98 && PHYS_JUMPSPEEDCAP_DISABLE_ONRAMPS(this)))
		{
			float maxjumpspeed = mjumpheight * stof(PHYS_JUMPSPEEDCAP_MAX);

			if (this.velocity_z > maxjumpspeed)
				mjumpheight -= this.velocity_z - maxjumpspeed;
		}
	}

	if (!WAS_ONGROUND(this) && !WAS_ONSLICK(this))
	{
#ifdef SVQC
		if(autocvar_speedmeter)
			LOG_TRACE("landing velocity: ", vtos(this.velocity), " (abs: ", ftos(vlen(this.velocity)), ")");
#endif
		if(this.lastground < time - 0.3)
		{
			float f = (1 - PHYS_FRICTION_ONLAND(this));
			f = bound(0, f, 1);
			this.velocity_x *= f;
			this.velocity_y *= f;
		}
#ifdef SVQC
		if(this.jumppadcount > 1)
			LOG_TRACE(ftos(this.jumppadcount), "x jumppad combo");
		this.jumppadcount = 0;
#endif
	}

	this.velocity_z += mjumpheight;

	UNSET_ONGROUND(this);
	UNSET_ONSLICK(this);
	SET_JUMP_HELD(this);

#ifdef SVQC
	animdecide_setaction(this, ANIMACTION_JUMP, true);

	if (autocvar_g_jump_grunt)
		PlayerSound(this, playersound_jump, CH_PLAYER, VOL_BASE, VOICETYPE_PLAYERSOUND);
#endif
	return true;
}

void CheckWaterJump(entity this)
{
// check for a jump-out-of-water
	makevectors(this.v_angle);
	vector start = this.origin;
	start_z += 8;
	v_forward_z = 0;
	normalize(v_forward);
	vector end = start + v_forward*24;
	traceline (start, end, true, this);
	if (trace_fraction < 1)
	{	// solid at waist
		start_z = start_z + this.maxs_z - 8;
		end = start + v_forward*24;
		this.movedir = trace_plane_normal * -50;
		traceline(start, end, true, this);
		if (trace_fraction == 1)
		{	// open at eye level
			this.velocity_z = 225;
			this.flags |= FL_WATERJUMP;
			this.teleport_time = time + 2; // safety net
			SET_JUMP_HELD(this);
		}
	}
}


#ifdef SVQC
	#define JETPACK_JUMP(s)	CS_CVAR(s).cvar_cl_jetpack_jump
#elif defined(CSQC)
	float autocvar_cl_jetpack_jump;
	#define JETPACK_JUMP(s)	autocvar_cl_jetpack_jump
#endif
.float jetpack_stopped;
void CheckPlayerJump(entity this)
{
#ifdef SVQC
	bool was_flying = boolean(ITEMS_STAT(this) & IT_USING_JETPACK);
#endif
	if (JETPACK_JUMP(this) < 2)
		ITEMS_STAT(this) &= ~IT_USING_JETPACK;

	if(PHYS_INPUT_BUTTON_JUMP(this) || PHYS_INPUT_BUTTON_JETPACK(this))
	{
		bool playerjump = PlayerJump(this); // required

		bool air_jump = !playerjump || M_ARGV(2, bool);
		bool activate = (JETPACK_JUMP(this) && air_jump && PHYS_INPUT_BUTTON_JUMP(this)) || PHYS_INPUT_BUTTON_JETPACK(this);
		bool has_fuel = !PHYS_JETPACK_FUEL(this) || PHYS_AMMO_FUEL(this) || (ITEMS_STAT(this) & IT_UNLIMITED_AMMO);

		if (!(ITEMS_STAT(this) & ITEM_Jetpack.m_itemid)) { }
		else if (this.jetpack_stopped) { }
		else if (!has_fuel)
		{
#ifdef SVQC
			if (was_flying) // TODO: ran out of fuel message
				Send_Notification(NOTIF_ONE, this, MSG_INFO, INFO_JETPACK_NOFUEL);
			else if (activate)
				Send_Notification(NOTIF_ONE, this, MSG_INFO, INFO_JETPACK_NOFUEL);
#endif
			this.jetpack_stopped = true;
			ITEMS_STAT(this) &= ~IT_USING_JETPACK;
		}
		else if (activate && !PHYS_FROZEN(this))
			ITEMS_STAT(this) |= IT_USING_JETPACK;
	}
	else
	{
		this.jetpack_stopped = false;
		ITEMS_STAT(this) &= ~IT_USING_JETPACK;
	}
	if (!PHYS_INPUT_BUTTON_JUMP(this))
		UNSET_JUMP_HELD(this);

	if (this.waterlevel == WATERLEVEL_SWIMMING)
		CheckWaterJump(this);
}

#ifdef SVQC
string specialcommand = "xwxwxsxsxaxdxaxdx1x ";
.float specialcommand_pos;
void SpecialCommand(entity this)
{
	if(autocvar_sv_cheats || this.maycheat)
	{
		if (!CheatImpulse(this, CHIMPULSE_GIVE_ALL.impulse))
			LOG_INFO("A hollow voice says \"Plugh\".");
	}
}
#endif

bool PM_check_specialcommand(entity this, int buttons)
{
#ifdef SVQC
	string c;
	switch (buttons)
	{
		// buttons mapped in PHYS_INPUT_BUTTON_MASK
		case 0: c = "x"; break;
		case BIT(0): c = "1"; break;
		case BIT(2): c = " "; break;
		case BIT(7): c = "s"; break;
		case BIT(8): c = "w"; break;
		case BIT(9): c = "a"; break;
		case BIT(10): c = "d"; break;
		default: c = "?";
	}

	if (c == substring(specialcommand, CS(this).specialcommand_pos, 1))
	{
		CS(this).specialcommand_pos += 1;
		if (CS(this).specialcommand_pos >= strlen(specialcommand))
		{
			CS(this).specialcommand_pos = 0;
			SpecialCommand(this);
			return true;
		}
	}
	else if (CS(this).specialcommand_pos && (c != substring(specialcommand, CS(this).specialcommand_pos - 1, 1)))
		CS(this).specialcommand_pos = 0;
#endif
	return false;
}

void PM_check_punch(entity this, float dt)
{
#ifdef SVQC
	if (this.punchangle != '0 0 0')
	{
		float f = vlen(this.punchangle) - 10 * dt;
		if (f > 0)
			this.punchangle = normalize(this.punchangle) * f;
		else
			this.punchangle = '0 0 0';
	}

	if (this.punchvector != '0 0 0')
	{
		float f = vlen(this.punchvector) - 30 * dt;
		if (f > 0)
			this.punchvector = normalize(this.punchvector) * f;
		else
			this.punchvector = '0 0 0';
	}
#endif
}

// predict frozen movement, as frozen players CAN move in some cases
void PM_check_frozen(entity this)
{
	if (!PHYS_FROZEN(this))
		return;
	if (PHYS_DODGING_FROZEN(this) && IS_CLIENT(this))
	{
		// bind movement to a very slow speed so dodging can use .movement for directional calculations
		PHYS_CS(this).movement_x = bound(-2, PHYS_CS(this).movement.x, 2);
		PHYS_CS(this).movement_y = bound(-2, PHYS_CS(this).movement.y, 2);
		PHYS_CS(this).movement_z = bound(-2, PHYS_CS(this).movement.z, 2);
	}
	else
		PHYS_CS(this).movement = '0 0 0';
}

void PM_check_hitground(entity this)
{
#ifdef SVQC
	if (!this.wasFlying) return;
	this.wasFlying = false;
	if (this.waterlevel >= WATERLEVEL_SWIMMING) return;
	if (this.ladder_entity) return;
	for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	{
		.entity weaponentity = weaponentities[slot];
		if(this.(weaponentity).hook)
			return;
	}
	this.nextstep = time + 0.3 + random() * 0.1;
	trace_dphitq3surfaceflags = 0;
	tracebox(this.origin, this.mins, this.maxs, this.origin - '0 0 1', MOVE_NOMONSTERS, this);
	if (trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOSTEPS) return;
	entity gs = (trace_dphitq3surfaceflags & Q3SURFACEFLAG_METALSTEPS)
		? GS_FALL_METAL
		: GS_FALL;
	float vol = ((IS_DUCKED(this)) ? VOL_MUFFLED : VOL_BASE);
	GlobalSound(this, gs, CH_PLAYER, vol, VOICETYPE_PLAYERSOUND);
#endif
}

void PM_Footsteps(entity this)
{
#ifdef SVQC
	if (!autocvar_g_footsteps) return;
	if (IS_DUCKED(this)) return;
	if (time >= this.lastground + 0.2) return;
	if (vdist(this.velocity, <=, autocvar_sv_maxspeed * 0.6)) return;
	if ((time > this.nextstep) || (time < (this.nextstep - 10.0)))
	{
		this.nextstep = time + 0.3 + random() * 0.1;
		trace_dphitq3surfaceflags = 0;
		tracebox(this.origin, this.mins, this.maxs, this.origin - '0 0 1', MOVE_NOMONSTERS, this);
		if (trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOSTEPS) return;
		entity gs = (trace_dphitq3surfaceflags & Q3SURFACEFLAG_METALSTEPS)
			? GS_STEP_METAL
			: GS_STEP;
		GlobalSound(this, gs, CH_PLAYER, VOL_BASE, VOICETYPE_PLAYERSOUND);
	}
#endif
}

void PM_check_slick(entity this)
{
	if(!IS_ONGROUND(this))
		return;

	trace_dphitq3surfaceflags = 0;
	tracebox(this.origin, this.mins, this.maxs, this.origin - '0 0 1', MOVE_NOMONSTERS, this);
	if (trace_dphitq3surfaceflags & Q3SURFACEFLAG_SLICK)
		SET_ONSLICK(this);
	else
		UNSET_ONSLICK(this);
}

void PM_check_blocked(entity this)
{
	if(PHYS_INPUT_BUTTON_CHAT(this) || PHYS_INPUT_BUTTON_MINIGAME(this))
		PHYS_CS(this).movement = '0 0 0';
#ifdef SVQC
	if (!this.player_blocked)
		return;
	PHYS_CS(this).movement = '0 0 0';
	this.disableclientprediction = 1;
#endif
}

void PM_jetpack(entity this, float maxspd_mod, float dt)
{
	//makevectors(this.v_angle.y * '0 1 0');
	makevectors(this.v_angle);
	vector wishvel = v_forward * PHYS_CS(this).movement_x
					+ v_right * PHYS_CS(this).movement_y;
	// add remaining speed as Z component
	float maxairspd = PHYS_MAXAIRSPEED(this) * max(1, maxspd_mod);
	// fix speedhacks :P
	wishvel = normalize(wishvel) * min(1, vlen(wishvel) / maxairspd);
	// add the unused velocity as up component
	wishvel_z = 0;

	// if (PHYS_INPUT_BUTTON_JUMP(this))
		wishvel_z = sqrt(max(0, 1 - wishvel * wishvel));

	// it is now normalized, so...
	float a_side = PHYS_JETPACK_ACCEL_SIDE(this);
	float a_up = PHYS_JETPACK_ACCEL_UP(this);
	float a_add = PHYS_JETPACK_ANTIGRAVITY(this) * PHYS_GRAVITY(this);

	if(PHYS_JETPACK_REVERSE_THRUST(this) && PHYS_INPUT_BUTTON_CROUCH(this)) { a_up = PHYS_JETPACK_REVERSE_THRUST(this); }

	wishvel_x *= a_side;
	wishvel_y *= a_side;
	wishvel_z *= a_up;
	wishvel_z += a_add;

	if(PHYS_JETPACK_REVERSE_THRUST(this) && PHYS_INPUT_BUTTON_CROUCH(this)) { wishvel_z *= -1; }

	float best = 0;
	//////////////////////////////////////////////////////////////////////////////////////
	// finding the maximum over all vectors of above form
	// with wishvel having an absolute value of 1
	//////////////////////////////////////////////////////////////////////////////////////
	// we're finding the maximum over
	//   f(a_side, a_up, a_add, z) := a_side * (1 - z^2) + (a_add + a_up * z)^2;
	// for z in the range from -1 to 1
	//////////////////////////////////////////////////////////////////////////////////////
	// maximum is EITHER attained at the single extreme point:
	float a_diff = a_side * a_side - a_up * a_up;
	float f;
	if (a_diff != 0)
	{
		f = a_add * a_up / a_diff; // this is the zero of diff(f(a_side, a_up, a_add, z), z)
		if (f > -1 && f < 1) // can it be attained?
		{
			best = (a_diff + a_add * a_add) * (a_diff + a_up * a_up) / a_diff;
			//print("middle\n");
		}
	}
	// OR attained at z = 1:
	f = (a_up + a_add) * (a_up + a_add);
	if (f > best)
	{
		best = f;
		//print("top\n");
	}
	// OR attained at z = -1:
	f = (a_up - a_add) * (a_up - a_add);
	if (f > best)
	{
		best = f;
		//print("bottom\n");
	}
	best = sqrt(best);
	//////////////////////////////////////////////////////////////////////////////////////

	//print("best possible acceleration: ", ftos(best), "\n");

	float fxy, fz;
	fxy = bound(0, 1 - (this.velocity * normalize(wishvel_x * '1 0 0' + wishvel_y * '0 1 0')) / PHYS_JETPACK_MAXSPEED_SIDE(this), 1);
	if (wishvel_z - PHYS_GRAVITY(this) > 0)
		fz = bound(0, 1 - this.velocity_z / PHYS_JETPACK_MAXSPEED_UP(this), 1);
	else
		fz = bound(0, 1 + this.velocity_z / PHYS_JETPACK_MAXSPEED_UP(this), 1);

	float fvel;
	fvel = vlen(wishvel);
	wishvel_x *= fxy;
	wishvel_y *= fxy;
	wishvel_z = (wishvel_z - PHYS_GRAVITY(this)) * fz + PHYS_GRAVITY(this);

	fvel = min(1, vlen(wishvel) / best);
	if (PHYS_JETPACK_FUEL(this) && !(ITEMS_STAT(this) & IT_UNLIMITED_AMMO))
		f = min(1, PHYS_AMMO_FUEL(this) / (PHYS_JETPACK_FUEL(this) * dt * fvel));
	else
		f = 1;

	//print("this acceleration: ", ftos(vlen(wishvel) * f), "\n");

	if (f > 0 && wishvel != '0 0 0')
	{
		this.velocity = this.velocity + wishvel * f * dt;
		UNSET_ONGROUND(this);

#ifdef SVQC
		if (!(ITEMS_STAT(this) & IT_UNLIMITED_AMMO))
			TakeResource(this, RES_FUEL, PHYS_JETPACK_FUEL(this) * dt * fvel * f);

		ITEMS_STAT(this) |= IT_USING_JETPACK;

		// jetpack also inhibits health regeneration, but only for 1 second
		this.pauseregen_finished = max(this.pauseregen_finished, time + autocvar_g_balance_pause_fuel_regen);
#endif
	}
}

// used for calculating airshots
bool IsFlying(entity this)
{
	if(IS_ONGROUND(this))
		return false;
	if(this.waterlevel >= WATERLEVEL_SWIMMING)
		return false;
	tracebox(this.origin, this.mins, this.maxs, this.origin - '0 0 24', MOVE_NORMAL, this);
	//traceline(this.origin, this.origin - '0 0 48', MOVE_NORMAL, this);
	if(trace_fraction < 1)
		return false;
	return true;
}


void sys_phys_update(entity this, float dt);
#if defined(SVQC)
void SV_PlayerPhysics(entity this)
#elif defined(CSQC)
void CSQC_ClientMovement_PlayerMove_Frame(entity this)
#endif
{
#ifdef SVQC
	// needs to be called before physics are run!
	if(IS_REAL_CLIENT(this))
		PM_UpdateButtons(this, CS(this));
#elif defined(CSQC)
	if(this.last_pushed && !WarpZoneLib_ExactTrigger_Touch(this.last_pushed, this, false))
		this.last_pushed = NULL;
#endif

	sys_phys_update(this, PHYS_INPUT_TIMELENGTH);

#ifdef SVQC
	CS(this).pm_frametime = frametime;
#elif defined(CSQC)
	if((ITEMS_STAT(this) & IT_USING_JETPACK) && !IS_DEAD(this) && !intermission)
		this.csqcmodel_modelflags |= MF_ROCKET;
	else
		this.csqcmodel_modelflags &= ~MF_ROCKET;
#endif
}
