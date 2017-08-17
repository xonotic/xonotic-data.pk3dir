#include "sv_dodging.qh"

// TODO the CSQC blocks in this sv_ file are currently not compiled but will be when dodging prediction gets enabled

#define PHYS_DODGING 						g_dodging
#define PHYS_DODGING_DELAY 					autocvar_sv_dodging_delay
#define PHYS_DODGING_DISTANCE_THRESHOLD 	autocvar_sv_dodging_wall_distance_threshold
#define PHYS_DODGING_FROZEN_DOUBLETAP		autocvar_sv_dodging_frozen_doubletap
#define PHYS_DODGING_HEIGHT_THRESHOLD 		autocvar_sv_dodging_height_threshold
#define PHYS_DODGING_HORIZ_SPEED_MIN		autocvar_sv_dodging_horiz_speed_min
#define PHYS_DODGING_HORIZ_SPEED_MAX		autocvar_sv_dodging_horiz_speed_max
#define PHYS_DODGING_HORIZ_FORCE_SLOWEST	autocvar_sv_dodging_horiz_force_slowest
#define PHYS_DODGING_HORIZ_FORCE_FASTEST	autocvar_sv_dodging_horiz_force_fastest
#define PHYS_DODGING_HORIZ_FORCE_FROZEN 	autocvar_sv_dodging_horiz_force_frozen
#define PHYS_DODGING_RAMP_TIME 				autocvar_sv_dodging_ramp_time
#define PHYS_DODGING_UP_SPEED 				autocvar_sv_dodging_up_speed
#define PHYS_DODGING_WALL 					autocvar_sv_dodging_wall_dodging
#define PHYS_DODGING_AIR 					autocvar_sv_dodging_air_dodging
#define PHYS_DODGING_MAXSPEED 				autocvar_sv_dodging_maxspeed // TODO separate max air speed, fix frozen dodging

// we ran out of stats slots! TODO: re-enable this when prediction is available for dodging
#if 0
#define PHYS_DODGING 						STAT(DODGING, this)
#define PHYS_DODGING_DELAY 					STAT(DODGING_DELAY, this)
#define PHYS_DODGING_DISTANCE_THRESHOLD 	STAT(DODGING_DISTANCE_THRESHOLD, this)
#define PHYS_DODGING_FROZEN_DOUBLETAP		STAT(DODGING_FROZEN_DOUBLETAP, this)
#define PHYS_DODGING_HEIGHT_THRESHOLD 		STAT(DODGING_HEIGHT_THRESHOLD, this)
#define PHYS_DODGING_HORIZ_SPEED_MIN		STAT(DODGING_HORIZ_SPEED_MIN, this)
#define PHYS_DODGING_HORIZ_SPEED_MAX		STAT(DODGING_HORIZ_SPEED_MAX, this)
#define PHYS_DODGING_HORIZ_FORCE_SLOWEST	STAT(DODGING_HORIZ_FORCE_SLOWEST, this)
#define PHYS_DODGING_HORIZ_FORCE_FASTEST	STAT(DODGING_HORIZ_FORCE_FASTEST, this)
#define PHYS_DODGING_HORIZ_FORCE_FROZEN 	STAT(DODGING_HORIZ_FORCE_FROZEN, this)
#define PHYS_DODGING_RAMP_TIME 				STAT(DODGING_RAMP_TIME, this)
#define PHYS_DODGING_UP_SPEED 				STAT(DODGING_UP_SPEED, this)
#define PHYS_DODGING_WALL 					STAT(DODGING_WALL, this)
#define PHYS_DODGING_AIR 					STAT(DODGING_AIR, this)
#define PHYS_DODGING_MAXSPEED 				STAT(DODGING_MAXSPEED, this)
#endif

#ifdef CSQC
	#define PHYS_DODGING_FRAMETIME				(1 / (frametime <= 0 ? 60 : frametime))
	#define PHYS_DODGING_TIMEOUT(s) 			STAT(DODGING_TIMEOUT)
	#define PHYS_DODGING_PRESSED_KEYS(s)		(s).pressedkeys
#elif defined(SVQC)
	#define PHYS_DODGING_FRAMETIME				sys_frametime
	#define PHYS_DODGING_TIMEOUT(s) 			CS(s).cvar_cl_dodging_timeout
	#define PHYS_DODGING_PRESSED_KEYS(s)		CS(s).pressedkeys
#endif

#ifdef SVQC

bool autocvar_sv_dodging_sound;

#include <common/animdecide.qh>
#include <common/physics/player.qh>

.float cvar_cl_dodging_timeout;

REGISTER_MUTATOR(dodging, cvar("g_dodging"))
{
	// this just turns on the cvar.
	MUTATOR_ONADD
	{
		g_dodging = cvar("g_dodging");
	}

	// this just turns off the cvar.
	MUTATOR_ONROLLBACK_OR_REMOVE
	{
		g_dodging = 0;
	}

	return false;
}

#elif defined(CSQC)
REGISTER_MUTATOR(dodging, true);
#endif

// set to 1 to indicate dodging has started.. reset by physics hook after dodge has been done..
.float dodging_action;

// the jump part of the dodge cannot be ramped
.float dodging_single_action;

// these are used to store the last key press time for each of the keys..
.float last_FORWARD_KEY_time;
.float last_BACKWARD_KEY_time;
.float last_LEFT_KEY_time;
.float last_RIGHT_KEY_time;

// these store the movement direction at the time of the dodge action happening.
.vector dodging_direction;

// this indicates the last time a dodge was executed. used to check if another one is allowed
// and to ramp up the dodge acceleration in the physics hook.
.float last_dodging_time;

// the total speed that will be added over the ramp time
.float dodging_force_total;
// the part of total yet to be added
.float dodging_force_remaining;

#ifdef CSQC
.int pressedkeys;
#endif

#define X(dir) \
	tracebox(this.origin, this.mins, this.maxs, this.origin + threshold * dir, true, this); \
	if (trace_fraction < 1 && !(trace_dphitq3surfaceflags & Q3SURFACEFLAG_SKY)) \
		return true;

// returns true if the player is close to a wall
bool is_close_to_wall(entity this, float threshold)
{
	X(v_right);
	X(-v_right);
	X(v_forward);
	X(-v_forward);

	return false;
}

bool is_close_to_ground(entity this, float threshold)
{
	if (IS_ONGROUND(this)) return true;
	X(-v_up); // necessary for dodging down a slope using doubletap (using `+dodge` works anyway)

	return false;
}

#undef X

float determine_force(entity player) {
	if (PHYS_FROZEN(player)) return PHYS_DODGING_HORIZ_FORCE_FROZEN;

	float horiz_vel = vlen(vec2(player.velocity));
	return map_bound_ranges(horiz_vel,
	                        PHYS_DODGING_HORIZ_SPEED_MIN, PHYS_DODGING_HORIZ_SPEED_MAX,
	                        PHYS_DODGING_HORIZ_FORCE_SLOWEST, PHYS_DODGING_HORIZ_FORCE_FASTEST);
}

bool PM_dodging_checkpressedkeys(entity this)
{
	// first check if the last dodge is far enough back in time so we can dodge again
	if ((time - this.last_dodging_time) < PHYS_DODGING_DELAY)
		return false;

	bool frozen_dodging = (PHYS_FROZEN(this) && PHYS_DODGING_FROZEN(this));
	bool frozen_no_doubletap = (frozen_dodging && !PHYS_DODGING_FROZEN_DOUBLETAP);

	float tap_direction_x = 0;
	float tap_direction_y = 0;
	bool dodge_detected = false;
	vector mymovement = PHYS_CS(this).movement;

	#define X(COND,BTN,RESULT)															\
	if (mymovement_##COND)												\
		/* is this a state change? */													\
		if(!(PHYS_DODGING_PRESSED_KEYS(this) & KEY_##BTN) || frozen_no_doubletap) {		\
			tap_direction_##RESULT;													\
			if ((time - this.last_##BTN##_KEY_time) < PHYS_DODGING_TIMEOUT(this) || frozen_no_doubletap)	\
				dodge_detected = true;												\
			if(PHYS_INPUT_BUTTON_DODGE(this))										\
				dodge_detected = true;												\
			this.last_##BTN##_KEY_time = time;										\
		}
	X(x < 0, BACKWARD,	x--);
	X(x > 0, FORWARD,	x++);
	X(y < 0, LEFT,		y--);
	X(y > 0, RIGHT,		y++);
	#undef X

	if (!dodge_detected) return false;

	makevectors(this.angles);

	bool wall_dodge = false;

	if(!PHYS_DODGING_AIR)
	if(!is_close_to_ground(this, PHYS_DODGING_HEIGHT_THRESHOLD)) // TODO first check wall wallldodging - this fails for sloped walls
	{
		wall_dodge = (PHYS_DODGING_WALL && is_close_to_wall(this, PHYS_DODGING_DISTANCE_THRESHOLD));
		if(!wall_dodge) // we're not on the ground, and wall dodging isn't allowed, end it!
			return false;
	}

	if(!wall_dodge && PHYS_DODGING_MAXSPEED && vdist(this.velocity, >, PHYS_DODGING_MAXSPEED))
		return false;

	this.last_dodging_time = time;

	this.dodging_action = 1;
	this.dodging_single_action = 1;

	this.dodging_force_total = determine_force(this);
	this.dodging_force_remaining = this.dodging_force_total;

	this.dodging_direction.x = tap_direction_x;
	this.dodging_direction.y = tap_direction_y;

	// normalize the dodging_direction vector.. (unlike UT99) XD
	float length = sqrt(this.dodging_direction.x ** 2 + this.dodging_direction.y ** 2);

	this.dodging_direction.x = this.dodging_direction.x / length;
	this.dodging_direction.y = this.dodging_direction.y / length;

	return true;
}

void PM_dodging(entity this)
{
	// can't use return value from PM_dodging_checkpressedkeys because they're called from different hooks
	if (!this.dodging_action) return;

	// when swimming or dead, no dodging allowed..
	if (this.waterlevel >= WATERLEVEL_SWIMMING || IS_DEAD(this))
	{
		this.dodging_action = 0;
		this.dodging_direction.x = 0;
		this.dodging_direction.y = 0;
		return;
	}

	// make sure v_up, v_right and v_forward are sane
	if(PHYS_DODGING_AIR)
		makevectors(this.v_angle);
	else
		makevectors(this.angles);

	// fraction of the force to apply each frame
	// if we have e.g. 0.5 sec ramptime and a frametime of 0.25, then the ramp code
	// will be called ramp_time/frametime times = 2 times. so, we need to
	// add 0.5 * the total speed each frame until the dodge action is done..
	float common_factor = PHYS_DODGING_FRAMETIME / PHYS_DODGING_RAMP_TIME;
	//common_factor /= 2; // FIXME this is WRONG but this function is called twice per frame!!!

	// if ramp time is smaller than frametime we get problems ;D
	common_factor = min(common_factor, 1); // TODO necessary with dodging_force_remaining?

	float velocity_increase = min(common_factor * this.dodging_force_total, this.dodging_force_remaining);
	this.dodging_force_remaining -= velocity_increase;
	LOG_INFOF("time %f velocity_increase: %f\n", time, velocity_increase);
	this.velocity += this.dodging_direction.x * velocity_increase * v_forward
	               + this.dodging_direction.y * velocity_increase * v_right;

	// the up part of the dodge is a single shot action
	if (this.dodging_single_action == 1)
	{
		UNSET_ONGROUND(this);

		this.velocity += PHYS_DODGING_UP_SPEED * v_up;

#ifdef SVQC
		if (autocvar_sv_dodging_sound)
			PlayerSound(this, playersound_jump, CH_PLAYER, VOL_BASE, VOICETYPE_PLAYERSOUND);

		animdecide_setaction(this, ANIMACTION_JUMP, true);
#endif

		this.dodging_single_action = 0;
	}

	if(this.dodging_force_remaining <= 0)
	{
		// reset state so next dodge can be done correctly
		this.dodging_action = 0;
		this.dodging_direction.x = 0;
		this.dodging_direction.y = 0;
	}
}

#ifdef CSQC
void PM_dodging_GetPressedKeys(entity this)
{
	PM_dodging_checkpressedkeys(this);

	int keys = this.pressedkeys;
	keys = BITSET(keys, KEY_FORWARD, 	PHYS_CS(this).movement.x > 0);
	keys = BITSET(keys, KEY_BACKWARD, 	PHYS_CS(this).movement.x < 0);
	keys = BITSET(keys, KEY_RIGHT, 		PHYS_CS(this).movement.y > 0);
	keys = BITSET(keys, KEY_LEFT, 		PHYS_CS(this).movement.y < 0);

	keys = BITSET(keys, KEY_JUMP, 		PHYS_INPUT_BUTTON_JUMP(this));
	keys = BITSET(keys, KEY_CROUCH, 	PHYS_INPUT_BUTTON_CROUCH(this));
	keys = BITSET(keys, KEY_ATCK, 		PHYS_INPUT_BUTTON_ATCK(this));
	keys = BITSET(keys, KEY_ATCK2, 		PHYS_INPUT_BUTTON_ATCK2(this));
	this.pressedkeys = keys;
}
#endif

MUTATOR_HOOKFUNCTION(dodging, PlayerPhysics)
{
	entity player = M_ARGV(0, entity);
	//LOG_INFOF("player %s, physics %f\n", player.netname, time);

#ifdef CSQC
	PM_dodging_GetPressedKeys(player);
#endif
	PM_dodging(player);
}

#ifdef SVQC

REPLICATE(cvar_cl_dodging_timeout, float, "cl_dodging_timeout");

MUTATOR_HOOKFUNCTION(dodging, GetPressedKeys)
{
	entity player = M_ARGV(0, entity);
	//LOG_INFOF("player %s, keys %f\n", player.netname, time);

	PM_dodging_checkpressedkeys(player);
}

#endif
