
#ifdef SVQC

.float cvar_cl_dodging_timeout;

.float stat_dodging;
.float stat_dodging_timeout;
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
.float dodging_direction_x;
.float dodging_direction_y;

// this indicates the last time a dodge was executed. used to check if another one is allowed
// and to ramp up the dodge acceleration in the physics hook.
.float last_dodging_time;

// This is the velocity gain to be added over the ramp time.
// It will decrease from frame to frame during dodging_action = 1
// until it's 0.
.float dodging_velocity_gain;

#ifdef CSQC
.float pressedkeys;

#define PHYS_INPUT_MOVEVALUES(s)			input_movevalues
#define PHYS_INPUT_BUTTONS(s)   			input_buttons
#define PHYS_INPUT_ANGLES(s)   				input_angles

#define UNSET_ONGROUND(s) 					s.pmove_flags &= ~PMF_ONGROUND
#define PHYS_FROZEN(s)						getstati(STAT_FROZEN)
#define IS_ONGROUND(s)    					(s.pmove_flags & PMF_ONGROUND)

#define PHYS_DEAD(s)						s.csqcmodel_isdead

#define PHYS_DODGING_FRAMETIME				1 / frametime
#define PHYS_DODGING 						getstati(STAT_DODGING)
#define PHYS_DODGING_DELAY 					getstatf(STAT_DODGING_DELAY)
#define PHYS_DODGING_TIMEOUT(s) 			getstatf(STAT_DODGING_TIMEOUT)
#define PHYS_DODGING_HORIZ_SPEED_FROZEN 	getstatf(STAT_DODGING_HORIZ_SPEED_FROZEN)
#define PHYS_DODGING_FROZEN					getstati(STAT_DODGING_FROZEN)
#define PHYS_DODGING_FROZEN_NODOUBLETAP		getstati(STAT_DODGING_FROZEN_NO_DOUBLETAP)
#define PHYS_DODGING_HORIZ_SPEED 			getstatf(STAT_DODGING_HORIZ_SPEED)
#define PHYS_DODGING_PRESSED_KEYS(s)		s.pressedkeys
#define PHYS_DODGING_HEIGHT_THRESHOLD 		getstatf(STAT_DODGING_HEIGHT_THRESHOLD)
#define PHYS_DODGING_DISTANCE_THRESHOLD 	getstatf(STAT_DODGING_DISTANCE_THRESHOLD)
#define PHYS_DODGING_RAMP_TIME 				getstatf(STAT_DODGING_RAMP_TIME)
#define PHYS_DODGING_UP_SPEED 				getstatf(STAT_DODGING_UP_SPEED)
#define PHYS_DODGING_WALL 					getstatf(STAT_DODGING_WALL)

#elif defined(SVQC)

#define PHYS_INPUT_ANGLES(s)   				s.angles
#define PHYS_INPUT_MOVEVALUES(s)			s.movement
#define PHYS_INPUT_BUTTONS(s)   			(s.BUTTON_ATCK + 2 * s.BUTTON_JUMP + 4 * s.BUTTON_ATCK2 + 8 * s.BUTTON_ZOOM + 16 * s.BUTTON_CROUCH + 32 * s.BUTTON_HOOK + 64 * s.BUTTON_USE + 128 * (s.movement_x < 0) + 256 * (s.movement_x > 0) + 512 * (s.movement_y < 0) + 1024 * (s.movement_y > 0))
#define UNSET_ONGROUND(s) 					s.flags &= ~FL_ONGROUND
#define PHYS_FROZEN(s)						s.frozen
#define IS_ONGROUND(s)    					(s.flags & FL_ONGROUND)

#define PHYS_DEAD(s)						s.deadflag != DEAD_NO

#define PHYS_DODGING_FRAMETIME				sys_frametime
#define PHYS_DODGING 						g_dodging
#define PHYS_DODGING_DELAY 					autocvar_sv_dodging_delay
#define PHYS_DODGING_TIMEOUT(s) 			s.cvar_cl_dodging_timeout
#define PHYS_DODGING_HORIZ_SPEED_FROZEN 	autocvar_sv_dodging_horiz_speed_frozen
#define PHYS_DODGING_FROZEN					autocvar_sv_dodging_frozen
#define PHYS_DODGING_FROZEN_NODOUBLETAP		autocvar_sv_dodging_frozen_doubletap
#define PHYS_DODGING_HORIZ_SPEED 			autocvar_sv_dodging_horiz_speed
#define PHYS_DODGING_PRESSED_KEYS(s)		s.pressedkeys
#define PHYS_DODGING_HEIGHT_THRESHOLD 		autocvar_sv_dodging_height_threshold
#define PHYS_DODGING_DISTANCE_THRESHOLD 	autocvar_sv_dodging_wall_distance_threshold
#define PHYS_DODGING_RAMP_TIME 				autocvar_sv_dodging_ramp_time
#define PHYS_DODGING_UP_SPEED 				autocvar_sv_dodging_up_speed
#define PHYS_DODGING_WALL 					autocvar_sv_dodging_wall_dodging


void dodging_UpdateStats()
{
	self.stat_dodging = PHYS_DODGING;
	self.stat_dodging_delay = PHYS_DODGING_DELAY;
	self.stat_dodging_timeout = PHYS_DODGING_TIMEOUT(self);
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
#ifdef CSQC
// instantly updates pressed keys, for use with dodging (may be out of date, but we can't care)
void PM_dodging_updatepressedkeys()
{
	if (PHYS_INPUT_MOVEVALUES(self)_x > 0) // get if movement keys are pressed
	{	// forward key pressed
		self.pressedkeys |= KEY_FORWARD;
		self.pressedkeys &= ~KEY_BACKWARD;
	}
	else if (PHYS_INPUT_MOVEVALUES(self)_x < 0)
	{	// backward key pressed
		self.pressedkeys |= KEY_BACKWARD;
		self.pressedkeys &= ~KEY_FORWARD;
	}
	else
	{	// no x input
		self.pressedkeys &= ~KEY_FORWARD;
		self.pressedkeys &= ~KEY_BACKWARD;
	}

	if (PHYS_INPUT_MOVEVALUES(self)_y > 0)
	{	// right key pressed
		self.pressedkeys |= KEY_RIGHT;
		self.pressedkeys &= ~KEY_LEFT;
	}
	else if (PHYS_INPUT_MOVEVALUES(self)_y < 0)
	{	// left key pressed
		self.pressedkeys |= KEY_LEFT;
		self.pressedkeys &= ~KEY_RIGHT;
	}
	else
	{	// no y input
		self.pressedkeys &= ~KEY_RIGHT;
		self.pressedkeys &= ~KEY_LEFT;
	}

	if (PHYS_INPUT_BUTTONS(self) & 2) // get if jump and crouch keys are pressed
		self.pressedkeys |= KEY_JUMP;
	else
		self.pressedkeys &= ~KEY_JUMP;
	if (PHYS_INPUT_BUTTONS(self) & 16)
		self.pressedkeys |= KEY_CROUCH;
	else
		self.pressedkeys &= ~KEY_CROUCH;

	if (PHYS_INPUT_BUTTONS(self) & 1)
		self.pressedkeys |= KEY_ATCK;
	else
		self.pressedkeys &= ~KEY_ATCK;
	if (PHYS_INPUT_BUTTONS(self) & 4)
		self.pressedkeys |= KEY_ATCK2;
	else
		self.pressedkeys &= ~KEY_ATCK2;
}
#endif

// returns 1 if the player is close to a wall
float check_close_to_wall(float threshold)
{
	if (PHYS_DODGING_WALL == 0) { return FALSE; }

	vector trace_start;
	vector trace_end;

	trace_start = self.origin;

	trace_end = self.origin + (1000*v_right);
	tracebox(trace_start, self.mins, self.maxs, trace_end, TRUE, self);
	if (trace_fraction < 1 && vlen (self.origin - trace_endpos) < threshold)
		return TRUE;

	trace_end = self.origin - (1000*v_right);
	tracebox(trace_start, self.mins, self.maxs, trace_end, TRUE, self);
	if (trace_fraction < 1 && vlen (self.origin - trace_endpos) < threshold)
		return TRUE;

	trace_end = self.origin + (1000*v_forward);
	tracebox(trace_start, self.mins, self.maxs, trace_end, TRUE, self);
	if (trace_fraction < 1 && vlen (self.origin - trace_endpos) < threshold)
		return TRUE;

	trace_end = self.origin - (1000*v_forward);
	tracebox(trace_start, self.mins, self.maxs, trace_end, TRUE, self);
	if (trace_fraction < 1 && vlen (self.origin - trace_endpos) < threshold)
		return TRUE;

	return FALSE;
}

float check_close_to_ground(float threshold)
{
	if (IS_ONGROUND(self))
		return TRUE;

	return FALSE;
}

void PM_dodging_checkpressedkeys()
{
	if(!PHYS_DODGING) { return; }

	float length;
	float tap_direction_x;
	float tap_direction_y;

	tap_direction_x = 0;
	tap_direction_y = 0;

	float frozen_dodging, frozen_no_doubletap;
	frozen_dodging = (PHYS_FROZEN(self) && PHYS_DODGING_FROZEN);
	frozen_no_doubletap = (frozen_dodging && !PHYS_DODGING_FROZEN_NODOUBLETAP);

	float dodge_detected = 0;

	// first check if the last dodge is far enough back in time so we can dodge again
	if ((time - self.last_dodging_time) < PHYS_DODGING_DELAY)
		return;

	makevectors(PHYS_INPUT_ANGLES(self));

	if (check_close_to_ground(PHYS_DODGING_HEIGHT_THRESHOLD) != 1
		&& check_close_to_wall(PHYS_DODGING_DISTANCE_THRESHOLD) != 1)
		return;

	if (PHYS_INPUT_MOVEVALUES(self)_x > 0)
	{
		// is this a state change?
		if (!(PHYS_DODGING_PRESSED_KEYS(self) & KEY_FORWARD) || frozen_no_doubletap)
		{
			if ((time - self.last_FORWARD_KEY_time) < PHYS_DODGING_TIMEOUT(self))
			{
				tap_direction_x = 1.0;
				dodge_detected = 1;
			}
 			self.last_FORWARD_KEY_time = time;
 		}
	}

	if (PHYS_INPUT_MOVEVALUES(self)_x < 0)
	{
		// is this a state change?
 		if (!(PHYS_DODGING_PRESSED_KEYS(self) & KEY_BACKWARD) || frozen_no_doubletap)
 		{
			tap_direction_x = -1.0;
			if ((time - self.last_BACKWARD_KEY_time) < PHYS_DODGING_TIMEOUT(self))
			{
				dodge_detected = 1;
			}
 			self.last_BACKWARD_KEY_time = time;
 		}
	}

	if (PHYS_INPUT_MOVEVALUES(self)_y > 0)
	{
		// is this a state change?
		if (!(PHYS_DODGING_PRESSED_KEYS(self) & KEY_RIGHT) || frozen_no_doubletap)
		{
			tap_direction_y = 1.0;
			if ((time - self.last_RIGHT_KEY_time) < PHYS_DODGING_TIMEOUT(self))
			{
				dodge_detected = 1;
			}
 			self.last_RIGHT_KEY_time = time;
 		}
	}

	if (PHYS_INPUT_MOVEVALUES(self)_y < 0)
	{
		// is this a state change?
		if (!(PHYS_DODGING_PRESSED_KEYS(self) & KEY_LEFT) || frozen_no_doubletap)
		{
			tap_direction_y = -1.0;
			if ((time - self.last_LEFT_KEY_time) < PHYS_DODGING_TIMEOUT(self))
			{
				dodge_detected = 1;
			}
 			self.last_LEFT_KEY_time = time;
 		}
	}

	if (dodge_detected == 1)
	{
		self.last_dodging_time = time;

		self.dodging_action = 1;
		self.dodging_single_action = 1;

		self.dodging_velocity_gain = PHYS_DODGING_HORIZ_SPEED;

		self.dodging_direction_x = tap_direction_x;
		self.dodging_direction_y = tap_direction_y;

		// normalize the dodging_direction vector.. (unlike UT99) XD
		length =          self.dodging_direction_x * self.dodging_direction_x;
		length = length + self.dodging_direction_y * self.dodging_direction_y;
		length = sqrt(length);

		self.dodging_direction_x = self.dodging_direction_x * 1.0/length;
		self.dodging_direction_y = self.dodging_direction_y * 1.0/length;
	}

#ifdef CSQC
	PM_dodging_updatepressedkeys();
#endif
}

void PM_dodging()
{
	if(!PHYS_DODGING) { return; }

	float common_factor;
	float new_velocity_gain;
	float velocity_difference;
	float clean_up_and_do_nothing;
	float horiz_speed = PHYS_DODGING_HORIZ_SPEED;

#ifdef SVQC
	dodging_UpdateStats();
#endif

	if(PHYS_FROZEN(self))
		horiz_speed = PHYS_DODGING_HORIZ_SPEED_FROZEN;

    if(PHYS_DEAD(self))
        return;

	new_velocity_gain = 0;
	clean_up_and_do_nothing = 0;

	// when swimming, no dodging allowed..
	if (self.waterlevel >= WATERLEVEL_SWIMMING)
		clean_up_and_do_nothing = 1;

	if (clean_up_and_do_nothing != 0)
	{
		self.dodging_action = 0;
		self.dodging_direction_x = 0;
		self.dodging_direction_y = 0;
		return;
	}

	// make sure v_up, v_right and v_forward are sane
	makevectors(PHYS_INPUT_ANGLES(self));

	// if we have e.g. 0.5 sec ramptime and a frametime of 0.25, then the ramp code
	// will be called ramp_time/frametime times = 2 times. so, we need to
	// add 0.5 * the total speed each frame until the dodge action is done..
	common_factor = PHYS_DODGING_FRAMETIME / PHYS_DODGING_RAMP_TIME;

	// if ramp time is smaller than frametime we get problems ;D
	if (common_factor > 1)
		common_factor = 1;

	new_velocity_gain = self.dodging_velocity_gain - (common_factor * horiz_speed);
	if (new_velocity_gain < 0)
		new_velocity_gain = 0;

	velocity_difference = self.dodging_velocity_gain - new_velocity_gain;

	// ramp up dodging speed by adding some velocity each frame.. TODO: do it! :D
	if (self.dodging_action == 1)
	{
		//disable jump key during dodge accel phase
		if(PHYS_INPUT_MOVEVALUES(self)_z > 0) { PHYS_INPUT_MOVEVALUES(self)_z = 0; }

		self.velocity =
			  self.velocity
			+ ((self.dodging_direction_y * velocity_difference) * v_right)
			+ ((self.dodging_direction_x * velocity_difference) * v_forward);

		self.dodging_velocity_gain = self.dodging_velocity_gain - velocity_difference;
	}

	// the up part of the dodge is a single shot action
	if (self.dodging_single_action == 1)
	{
		UNSET_ONGROUND(self);

		self.velocity =
			  self.velocity
			+ (PHYS_DODGING_UP_SPEED * v_up);

#ifdef SVQC
		if (autocvar_sv_dodging_sound == 1)
			PlayerSound(playersound_jump, CH_PLAYER, VOICETYPE_PLAYERSOUND);

		animdecide_setaction(self, ANIMACTION_JUMP, TRUE);
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

#ifdef CSQC
	PM_dodging_checkpressedkeys();
#endif
}

#ifdef SVQC

MUTATOR_HOOKFUNCTION(dodging_GetCvars)
{
	GetCvars_handleFloat(get_cvars_s, get_cvars_f, cvar_cl_dodging_timeout, "cl_dodging_timeout");
	return FALSE;
}

MUTATOR_HOOKFUNCTION(dodging_PlayerPhysics)
{
	// print("dodging_PlayerPhysics\n");
	PM_dodging();

	return FALSE;
}

MUTATOR_HOOKFUNCTION(dodging_GetPressedKeys)
{
	PM_dodging_checkpressedkeys();

	return FALSE;
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

	return FALSE;
}
#endif

// we use this elsewhere, but let's undefine it anyway
#undef PHYS_DODGING_FROZEN
#undef PHYS_INPUT_MOVEVALUES
#undef PHYS_INPUT_ANGLES
#undef PHYS_INPUT_BUTTONS
#undef UNSET_ONGROUND
#undef PHYS_FROZEN
#undef IS_ONGROUND
