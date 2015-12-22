#ifdef IMPLEMENTATION

#define PHYS_DODGING 						STAT(DODGING, this)
#define PHYS_DODGING_DELAY 					STAT(DODGING_DELAY, this)
#define PHYS_DODGING_DISTANCE_THRESHOLD 	STAT(DODGING_DISTANCE_THRESHOLD, this)
#define PHYS_DODGING_FROZEN_NODOUBLETAP		STAT(DODGING_FROZEN_NO_DOUBLETAP, this)
#define PHYS_DODGING_HEIGHT_THRESHOLD 		STAT(DODGING_HEIGHT_THRESHOLD, this)
#define PHYS_DODGING_HORIZ_SPEED 			STAT(DODGING_HORIZ_SPEED, this)
#define PHYS_DODGING_HORIZ_SPEED_FROZEN 	STAT(DODGING_HORIZ_SPEED_FROZEN, this)
#define PHYS_DODGING_RAMP_TIME 				STAT(DODGING_RAMP_TIME, this)
#define PHYS_DODGING_UP_SPEED 				STAT(DODGING_UP_SPEED, this)
#define PHYS_DODGING_WALL 					STAT(DODGING_WALL, this)
#define PHYS_DODGING_PRESSED_KEYS(s)		(s).pressedkeys

#ifdef CSQC
	#define PHYS_DODGING_FRAMETIME				(1 / (frametime <= 0 ? 60 : frametime))
	#define PHYS_DODGING_TIMEOUT(s) 			STAT(DODGING_TIMEOUT)
#elif defined(SVQC)
	#define PHYS_DODGING_FRAMETIME				sys_frametime
	#define PHYS_DODGING_TIMEOUT(s) 			s.cvar_cl_dodging_timeout


#endif

#ifdef SVQC

bool autocvar_sv_dodging_sound;

// set to 1 to indicate dodging has started.. reset by physics hook after dodge has been done..
.float dodging_action;

// the jump part of the dodge cannot be ramped
.float dodging_single_action;

#include "../../../animdecide.qh"
#include "../../../physics.qh"

.float cvar_cl_dodging_timeout = _STAT(DODGING_TIMEOUT);

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

// This is the velocity gain to be added over the ramp time.
// It will decrease from frame to frame during dodging_action = 1
// until it's 0.
.float dodging_velocity_gain;

#ifdef CSQC
.int pressedkeys;
#endif

// returns 1 if the player is close to a wall
bool check_close_to_wall(entity this, float threshold)
{
	if (PHYS_DODGING_WALL == 0) { return false; }

	#define X(OFFSET)																\
	tracebox(this.origin, this.mins, this.maxs, this.origin + OFFSET, true, this);	\
	if (trace_fraction < 1 && vlen (this.origin - trace_endpos) < threshold)		\
		return true;
	X(1000*v_right);
	X(-1000*v_right);
	X(1000*v_forward);
	X(-1000*v_forward);
	#undef X

	return false;
}

bool check_close_to_ground(entity this, float threshold)
{
	return IS_ONGROUND(this) ? true : false;
}

float PM_dodging_checkpressedkeys(entity this)
{
	if(!PHYS_DODGING)
		return false;

	float frozen_dodging = (PHYS_FROZEN(this) && PHYS_DODGING_FROZEN(this));
	float frozen_no_doubletap = (frozen_dodging && !PHYS_DODGING_FROZEN_NODOUBLETAP);

	// first check if the last dodge is far enough back in time so we can dodge again
	if ((time - this.last_dodging_time) < PHYS_DODGING_DELAY)
		return false;

	makevectors(this.angles);

	if (check_close_to_ground(this, PHYS_DODGING_HEIGHT_THRESHOLD) != 1
		&& check_close_to_wall(this, PHYS_DODGING_DISTANCE_THRESHOLD) != 1)
		return true;

	float tap_direction_x = 0;
	float tap_direction_y = 0;
	bool dodge_detected = false;

	#define X(COND,BTN,RESULT)															\
	if (this.movement_##COND)												\
		/* is this a state change? */													\
		if(!(PHYS_DODGING_PRESSED_KEYS(this) & KEY_##BTN) || frozen_no_doubletap) {		\
				tap_direction_##RESULT;													\
				if ((time - this.last_##BTN##_KEY_time) < PHYS_DODGING_TIMEOUT(this))	\
					dodge_detected = true;													\
				this.last_##BTN##_KEY_time = time;										\
		}
 	X(x < 0, BACKWARD,	x--);
 	X(x > 0, FORWARD,	x++);
 	X(y < 0, LEFT,		y--);
 	X(y > 0, RIGHT,		y++);
 	#undef X

	if (dodge_detected)
	{
		this.last_dodging_time = time;

		this.dodging_action = 1;
		this.dodging_single_action = 1;

		this.dodging_velocity_gain = PHYS_DODGING_HORIZ_SPEED;

		this.dodging_direction_x = tap_direction_x;
		this.dodging_direction_y = tap_direction_y;

		// normalize the dodging_direction vector.. (unlike UT99) XD
		float length = this.dodging_direction_x * this.dodging_direction_x
					+ this.dodging_direction_y * this.dodging_direction_y;
		length = sqrt(length);

		this.dodging_direction_x = this.dodging_direction_x * 1.0 / length;
		this.dodging_direction_y = this.dodging_direction_y * 1.0 / length;
		return true;
	}
	return false;
}

void PM_dodging(entity this)
{
	if (!PHYS_DODGING)
		return;

    if (PHYS_DEAD(this))
        return;

	// when swimming, no dodging allowed..
	if (this.waterlevel >= WATERLEVEL_SWIMMING)
	{
		this.dodging_action = 0;
		this.dodging_direction_x = 0;
		this.dodging_direction_y = 0;
		return;
	}

	// make sure v_up, v_right and v_forward are sane
	makevectors(this.angles);

	// if we have e.g. 0.5 sec ramptime and a frametime of 0.25, then the ramp code
	// will be called ramp_time/frametime times = 2 times. so, we need to
	// add 0.5 * the total speed each frame until the dodge action is done..
	float common_factor = PHYS_DODGING_FRAMETIME / PHYS_DODGING_RAMP_TIME;

	// if ramp time is smaller than frametime we get problems ;D
	common_factor = min(common_factor, 1);

	float horiz_speed = PHYS_FROZEN(this) ? PHYS_DODGING_HORIZ_SPEED_FROZEN : PHYS_DODGING_HORIZ_SPEED;
	float new_velocity_gain = this.dodging_velocity_gain - (common_factor * horiz_speed);
	new_velocity_gain = max(0, new_velocity_gain);

	float velocity_difference = this.dodging_velocity_gain - new_velocity_gain;

	// ramp up dodging speed by adding some velocity each frame.. TODO: do it! :D
	if (this.dodging_action == 1)
	{
		//disable jump key during dodge accel phase
		if(this.movement_z > 0) { this.movement_z = 0; }

		this.velocity += ((this.dodging_direction_y * velocity_difference) * v_right)
					+ ((this.dodging_direction_x * velocity_difference) * v_forward);

		this.dodging_velocity_gain = this.dodging_velocity_gain - velocity_difference;
	}

	// the up part of the dodge is a single shot action
	if (this.dodging_single_action == 1)
	{
		UNSET_ONGROUND(this);

		this.velocity += PHYS_DODGING_UP_SPEED * v_up;

#ifdef SVQC
		if (autocvar_sv_dodging_sound)
			PlayerSound(this, playersound_jump, CH_PLAYER, VOICETYPE_PLAYERSOUND);

		animdecide_setaction(this, ANIMACTION_JUMP, true);
#endif

		this.dodging_single_action = 0;
	}

	// are we done with the dodging ramp yet?
	if((this.dodging_action == 1) && ((time - this.last_dodging_time) > PHYS_DODGING_RAMP_TIME))
	{
		// reset state so next dodge can be done correctly
		this.dodging_action = 0;
		this.dodging_direction_x = 0;
		this.dodging_direction_y = 0;
	}
}

void PM_dodging_GetPressedKeys(entity this)
{
#ifdef CSQC
	if(!PHYS_DODGING) { return; }

	PM_dodging_checkpressedkeys(this);

	int keys = this.pressedkeys;
	keys = BITSET(keys, KEY_FORWARD, 	this.movement.x > 0);
	keys = BITSET(keys, KEY_BACKWARD, 	this.movement.x < 0);
	keys = BITSET(keys, KEY_RIGHT, 		this.movement.y > 0);
	keys = BITSET(keys, KEY_LEFT, 		this.movement.y < 0);

	keys = BITSET(keys, KEY_JUMP, 		PHYS_INPUT_BUTTON_JUMP(this));
	keys = BITSET(keys, KEY_CROUCH, 	PHYS_INPUT_BUTTON_CROUCH(this));
	keys = BITSET(keys, KEY_ATCK, 		PHYS_INPUT_BUTTON_ATCK(this));
	keys = BITSET(keys, KEY_ATCK2, 		PHYS_INPUT_BUTTON_ATCK2(this));
	this.pressedkeys = keys;
#endif
}

MUTATOR_HOOKFUNCTION(dodging, PlayerPhysics)
{
	// print("dodging_PlayerPhysics\n");
	PM_dodging_GetPressedKeys(self);
	PM_dodging(self);
	return false;
}

#ifdef SVQC

MUTATOR_HOOKFUNCTION(dodging, GetCvars)
{
	GetCvars_handleFloat(get_cvars_s, get_cvars_f, cvar_cl_dodging_timeout, "cl_dodging_timeout");
	return false;
}

MUTATOR_HOOKFUNCTION(dodging, GetPressedKeys)
{
	PM_dodging_checkpressedkeys(self);
	return false;
}

#endif
#endif
