#ifdef CSQC
	#define PHYS_DODGING_FRAMETIME				(1 / (frametime <= 0 ? 60 : frametime))
	#define PHYS_DODGING 						getstati(STAT_DODGING)
	#define PHYS_DODGING_DELAY 					getstatf(STAT_DODGING_DELAY)
	#define PHYS_DODGING_TIMEOUT(s) 			getstatf(STAT_DODGING_TIMEOUT)
	#define PHYS_DODGING_HORIZ_SPEED_FROZEN 	getstatf(STAT_DODGING_HORIZ_SPEED_FROZEN)
	#define PHYS_DODGING_FROZEN_NODOUBLETAP		getstati(STAT_DODGING_FROZEN_NO_DOUBLETAP)
	#define PHYS_DODGING_HORIZ_SPEED 			getstatf(STAT_DODGING_HORIZ_SPEED)
	#define PHYS_DODGING_PRESSED_KEYS(s)		s.pressedkeys
	#define PHYS_DODGING_HEIGHT_THRESHOLD 		getstatf(STAT_DODGING_HEIGHT_THRESHOLD)
	#define PHYS_DODGING_DISTANCE_THRESHOLD 	getstatf(STAT_DODGING_DISTANCE_THRESHOLD)
	#define PHYS_DODGING_RAMP_TIME 				getstatf(STAT_DODGING_RAMP_TIME)
	#define PHYS_DODGING_UP_SPEED 				getstatf(STAT_DODGING_UP_SPEED)
	#define PHYS_DODGING_WALL 					getstatf(STAT_DODGING_WALL)
#elif defined(SVQC)
	#define PHYS_DODGING_FRAMETIME				sys_frametime
	#define PHYS_DODGING 						g_dodging
	#define PHYS_DODGING_DELAY 					autocvar_sv_dodging_delay
	#define PHYS_DODGING_TIMEOUT(s) 			s.cvar_cl_dodging_timeout
	#define PHYS_DODGING_HORIZ_SPEED_FROZEN 	autocvar_sv_dodging_horiz_speed_frozen
	#define PHYS_DODGING_FROZEN_NODOUBLETAP		autocvar_sv_dodging_frozen_doubletap
	#define PHYS_DODGING_HORIZ_SPEED 			autocvar_sv_dodging_horiz_speed
	#define PHYS_DODGING_PRESSED_KEYS(s)		s.pressedkeys
	#define PHYS_DODGING_HEIGHT_THRESHOLD 		autocvar_sv_dodging_height_threshold
	#define PHYS_DODGING_DISTANCE_THRESHOLD 	autocvar_sv_dodging_wall_distance_threshold
	#define PHYS_DODGING_RAMP_TIME 				autocvar_sv_dodging_ramp_time
	#define PHYS_DODGING_UP_SPEED 				autocvar_sv_dodging_up_speed
	#define PHYS_DODGING_WALL 					autocvar_sv_dodging_wall_dodging
#endif

#ifdef SVQC
#include "mutator_dodging.qh"

#include "mutator.qh"

#include "../../common/animdecide.qh"
#include "../../common/physics.qh"

.float cvar_cl_dodging_timeout;

.float stat_dodging;
.float stat_dodging_delay;
.float stat_dodging_horiz_speed_frozen;
.float stat_dodging_frozen_nodoubletap;
.float stat_dodging_frozen;
.float stat_dodging_horiz_speed;
.float stat_dodging_height_threshold;
.float stat_dodging_distance_threshold;
.float stat_dodging_ramp_time;
.float stat_dodging_up_speed;
.float stat_dodging_wall;

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

// This is the velocity gain to be added over the ramp time.
// It will decrease from frame to frame during dodging_action = 1
// until it's 0.
.float dodging_velocity_gain;

#ifdef CSQC
.int pressedkeys;

#elif defined(SVQC)

void dodging_UpdateStats()
{SELFPARAM();
	self.stat_dodging = PHYS_DODGING;
	self.stat_dodging_delay = PHYS_DODGING_DELAY;
	self.stat_dodging_horiz_speed_frozen = PHYS_DODGING_HORIZ_SPEED_FROZEN;
	self.stat_dodging_frozen = PHYS_DODGING_FROZEN;
	self.stat_dodging_frozen_nodoubletap = PHYS_DODGING_FROZEN_NODOUBLETAP;
	self.stat_dodging_height_threshold = PHYS_DODGING_HEIGHT_THRESHOLD;
	self.stat_dodging_distance_threshold = PHYS_DODGING_DISTANCE_THRESHOLD;
	self.stat_dodging_ramp_time = PHYS_DODGING_RAMP_TIME;
	self.stat_dodging_up_speed = PHYS_DODGING_UP_SPEED;
	self.stat_dodging_wall = PHYS_DODGING_WALL;
}

void dodging_Initialize()
{
	addstat(STAT_DODGING, AS_INT, stat_dodging);
	addstat(STAT_DODGING_DELAY, AS_FLOAT, stat_dodging_delay);
	addstat(STAT_DODGING_TIMEOUT, AS_FLOAT, cvar_cl_dodging_timeout); // we stat this, so it is updated on the client when updated on server (otherwise, chaos)
	addstat(STAT_DODGING_FROZEN_NO_DOUBLETAP, AS_INT, stat_dodging_frozen_nodoubletap);
	addstat(STAT_DODGING_HORIZ_SPEED_FROZEN, AS_FLOAT, stat_dodging_horiz_speed_frozen);
	addstat(STAT_DODGING_FROZEN, AS_INT, stat_dodging_frozen);
	addstat(STAT_DODGING_HORIZ_SPEED, AS_FLOAT, stat_dodging_horiz_speed);
	addstat(STAT_DODGING_HEIGHT_THRESHOLD, AS_FLOAT, stat_dodging_height_threshold);
	addstat(STAT_DODGING_DISTANCE_THRESHOLD, AS_FLOAT, stat_dodging_distance_threshold);
	addstat(STAT_DODGING_RAMP_TIME, AS_FLOAT, stat_dodging_ramp_time);
	addstat(STAT_DODGING_UP_SPEED, AS_FLOAT, stat_dodging_up_speed);
	addstat(STAT_DODGING_WALL, AS_FLOAT, stat_dodging_wall);
}

#endif

// returns 1 if the player is close to a wall
bool check_close_to_wall(float threshold)
{SELFPARAM();
	if (PHYS_DODGING_WALL == 0) { return false; }

	#define X(OFFSET)																\
	tracebox(self.origin, self.mins, self.maxs, self.origin + OFFSET, true, self);	\
	if (trace_fraction < 1 && vlen (self.origin - trace_endpos) < threshold)		\
		return true;
	X(1000*v_right);
	X(-1000*v_right);
	X(1000*v_forward);
	X(-1000*v_forward);
	#undef X

	return false;
}

bool check_close_to_ground(float threshold)
{SELFPARAM();
	return IS_ONGROUND(self) ? true : false;
}

float PM_dodging_checkpressedkeys()
{SELFPARAM();
	if(!PHYS_DODGING)
		return false;

	float frozen_dodging = (PHYS_FROZEN(self) && PHYS_DODGING_FROZEN);
	float frozen_no_doubletap = (frozen_dodging && !PHYS_DODGING_FROZEN_NODOUBLETAP);

	// first check if the last dodge is far enough back in time so we can dodge again
	if ((time - self.last_dodging_time) < PHYS_DODGING_DELAY)
		return false;

	makevectors(self.angles);

	if (check_close_to_ground(PHYS_DODGING_HEIGHT_THRESHOLD) != 1
		&& check_close_to_wall(PHYS_DODGING_DISTANCE_THRESHOLD) != 1)
		return true;

	float tap_direction_x = 0;
	float tap_direction_y = 0;
	float dodge_detected = 0;

	#define X(COND,BTN,RESULT)															\
	if (self.movement_##COND)												\
		/* is this a state change? */													\
		if(!(PHYS_DODGING_PRESSED_KEYS(self) & KEY_##BTN) || frozen_no_doubletap) {		\
				tap_direction_##RESULT;													\
				if ((time - self.last_##BTN##_KEY_time) < PHYS_DODGING_TIMEOUT(self))	\
					dodge_detected = 1;													\
				self.last_##BTN##_KEY_time = time;										\
		}
 	X(x < 0, BACKWARD,	x--);
 	X(x > 0, FORWARD,	x++);
 	X(y < 0, LEFT,		y--);
 	X(y > 0, RIGHT,		y++);
 	#undef X

	if (dodge_detected == 1)
	{
		self.last_dodging_time = time;

		self.dodging_action = 1;
		self.dodging_single_action = 1;

		self.dodging_velocity_gain = PHYS_DODGING_HORIZ_SPEED;

		self.dodging_direction_x = tap_direction_x;
		self.dodging_direction_y = tap_direction_y;

		// normalize the dodging_direction vector.. (unlike UT99) XD
		float length = self.dodging_direction_x * self.dodging_direction_x
					+ self.dodging_direction_y * self.dodging_direction_y;
		length = sqrt(length);

		self.dodging_direction_x = self.dodging_direction_x * 1.0 / length;
		self.dodging_direction_y = self.dodging_direction_y * 1.0 / length;
		return true;
	}
	return false;
}

void PM_dodging()
{SELFPARAM();
	if (!PHYS_DODGING)
		return;

#ifdef SVQC
	dodging_UpdateStats();
#endif

    if (PHYS_DEAD(self))
        return;

	// when swimming, no dodging allowed..
	if (self.waterlevel >= WATERLEVEL_SWIMMING)
	{
		self.dodging_action = 0;
		self.dodging_direction_x = 0;
		self.dodging_direction_y = 0;
		return;
	}

	// make sure v_up, v_right and v_forward are sane
	makevectors(self.angles);

	// if we have e.g. 0.5 sec ramptime and a frametime of 0.25, then the ramp code
	// will be called ramp_time/frametime times = 2 times. so, we need to
	// add 0.5 * the total speed each frame until the dodge action is done..
	float common_factor = PHYS_DODGING_FRAMETIME / PHYS_DODGING_RAMP_TIME;

	// if ramp time is smaller than frametime we get problems ;D
	common_factor = min(common_factor, 1);

	float horiz_speed = PHYS_FROZEN(self) ? PHYS_DODGING_HORIZ_SPEED_FROZEN : PHYS_DODGING_HORIZ_SPEED;
	float new_velocity_gain = self.dodging_velocity_gain - (common_factor * horiz_speed);
	new_velocity_gain = max(0, new_velocity_gain);

	float velocity_difference = self.dodging_velocity_gain - new_velocity_gain;

	// ramp up dodging speed by adding some velocity each frame.. TODO: do it! :D
	if (self.dodging_action == 1)
	{
		//disable jump key during dodge accel phase
		if(self.movement_z > 0) { self.movement_z = 0; }

		self.velocity += ((self.dodging_direction_y * velocity_difference) * v_right)
					+ ((self.dodging_direction_x * velocity_difference) * v_forward);

		self.dodging_velocity_gain = self.dodging_velocity_gain - velocity_difference;
	}

	// the up part of the dodge is a single shot action
	if (self.dodging_single_action == 1)
	{
		UNSET_ONGROUND(self);

		self.velocity += PHYS_DODGING_UP_SPEED * v_up;

#ifdef SVQC
		if (autocvar_sv_dodging_sound)
			PlayerSound(playersound_jump, CH_PLAYER, VOICETYPE_PLAYERSOUND);

		animdecide_setaction(self, ANIMACTION_JUMP, true);
#endif

		self.dodging_single_action = 0;
	}

	// are we done with the dodging ramp yet?
	if((self.dodging_action == 1) && ((time - self.last_dodging_time) > PHYS_DODGING_RAMP_TIME))
	{
		// reset state so next dodge can be done correctly
		self.dodging_action = 0;
		self.dodging_direction_x = 0;
		self.dodging_direction_y = 0;
	}
}

#ifdef SVQC

MUTATOR_HOOKFUNCTION(dodging_GetCvars)
{
	GetCvars_handleFloat(get_cvars_s, get_cvars_f, cvar_cl_dodging_timeout, "cl_dodging_timeout");
	return false;
}

MUTATOR_HOOKFUNCTION(dodging_PlayerPhysics)
{
	// print("dodging_PlayerPhysics\n");
	PM_dodging();

	return false;
}

MUTATOR_HOOKFUNCTION(dodging_GetPressedKeys)
{
	PM_dodging_checkpressedkeys();

	return false;
}

MUTATOR_DEFINITION(mutator_dodging)
{
	// we need to be called before GetPressedKey does its thing so we can
	// detect state changes and therefore dodging actions..
	MUTATOR_HOOK(GetPressedKeys, dodging_GetPressedKeys, CBC_ORDER_ANY);

	// in the physics hook we actually implement the dodge..
	MUTATOR_HOOK(PlayerPhysics, dodging_PlayerPhysics, CBC_ORDER_ANY);

	// get timeout information from the client, so the client can configure it..
	MUTATOR_HOOK(GetCvars, dodging_GetCvars, CBC_ORDER_ANY);

	// this just turns on the cvar.
	MUTATOR_ONADD
	{
		g_dodging = cvar("g_dodging");
		dodging_Initialize();
	}

	// this just turns off the cvar.
	MUTATOR_ONROLLBACK_OR_REMOVE
	{
		g_dodging = 0;
	}

	return false;
}
#endif
