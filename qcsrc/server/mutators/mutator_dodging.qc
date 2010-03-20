
.float cvar_cl_dodging_timeout;


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

// set to 1 to indicate dodging has started.. reset by physics hook after dodge has been done..
.float dodging_action;

// the jump part of the dodge cannot be ramped
.float dodging_single_action;

void dodging_Initialize() {
	// print("dodging_Initialize\n");

	self.last_FORWARD_KEY_time = 0;
	self.last_BACKWARD_KEY_time = 0;
	self.last_RIGHT_KEY_time = 0;
	self.last_LEFT_KEY_time = 0;
	self.last_dodging_time = 0;
	self.dodging_action = 0;
	self.dodging_single_action = 0;
	self.dodging_direction_x = 0;
	self.dodging_direction_y = 0;
}

MUTATOR_HOOKFUNCTION(dodging_GetCvars) {
	// print("dodging_GetCvars\n");

	string s;
	s = strcat1(argv(get_cvars_f));

	GetCvars_handleFloat(s, get_cvars_f, cvar_cl_dodging_timeout, "cl_dodging_timeout");

	return 0;
}

MUTATOR_HOOKFUNCTION(dodging_PlayerPhysics) {
	// print("dodging_PlayerPhysics\n");

	float common_factor;

	// is dodging enabled at all? if not, do nothing..
	if (g_dodging == 0)
		return 0;

	// make sure v_up, v_right and v_forward are sane
	makevectors(self.angles);

	// if we have e.g. 0.5 sec ramptime and a frametime of 0.25, then the ramp code 
	// will be called ramp_time/frametime times = 2 times. so, we need to 
	// add 0.5 * the total speed each frame until the dodge action is done..
	common_factor = sys_frametime / cvar("sv_dodging_ramp_time");

	// if ramp time is smaller than frametime we get problems ;D
	if (common_factor > 1) 
		common_factor = 1;


	// ramp up dodging speed by adding some velocity each frame.. TODO: do it! :D
	if (self.dodging_action == 1) {
		//disable jump key during dodge accel phase
		if (self.movement_z > 0) self.movement_z = 0;

		self.velocity = 
			  self.velocity 
			+ (common_factor * (self.dodging_direction_y * cvar("sv_dodging_horiz_speed")) * v_right) 
			+ (common_factor * (self.dodging_direction_x * cvar("sv_dodging_horiz_speed")) * v_forward);
	}

	// the up part of the dodge is a single shot action
	if (self.dodging_single_action == 1) {
		self.velocity = 
			  self.velocity 
			+ (cvar("sv_dodging_up_speed") * v_up);

		self.dodging_single_action = 0;
	}

	// are we done with the dodging ramp yet?
	if((self.dodging_action == 1) && ((time - self.last_dodging_time) > cvar("sv_dodging_ramp_time")))
	{
		// reset state so next dodge can be done correctly
		self.dodging_action = 0;
		self.dodging_direction_x = 0;
		self.dodging_direction_y = 0;
	}

	return 0;
}

MUTATOR_HOOKFUNCTION(dodging_GetPressedKeys) {
	// print("dodging_PlayerPhysics\n");

	float length;
	float dodge_detected;
	vector trace_start;
	vector trace_end;
	float height_above_ground;

	if (g_dodging == 0)
		return 0;

	dodge_detected = 0;

	// no dodging and jumping at the same time..
	if (self.BUTTON_JUMP)
		return 0;

	// first check if the last dodge is far enough back in time so we can dodge again
	if ((time - self.last_dodging_time) < cvar("sv_dodging_delay"))
		return 0;

	// determine height above ground is below a threshold
	trace_start = self.origin;
	trace_end = self.origin - (100*v_up);

	traceline(trace_start, trace_end, TRUE, self);
	height_above_ground = self.origin_z - trace_endpos_z;

	if (height_above_ground > (fabs(PL_MIN_z) + cvar("sv_dodging_height_threshold")))
		return 0;

	// check if our feet are on the ground or at least close :D
	//if (!(self.lastflags & FL_ONGROUND))
	//	return 0;

	if (self.movement_x > 0) {
		// is this a state change?
		if (!(self.pressedkeys & KEY_FORWARD)) {
			if ((time - self.last_FORWARD_KEY_time) < self.cvar_cl_dodging_timeout)	{ 
				dodge_detected = 1;
				self.dodging_direction_x = 1.0;
			}
 			self.last_FORWARD_KEY_time = time;
 		}
	}

	if (self.movement_x < 0) {
		// is this a state change?
 		if (!(self.pressedkeys & KEY_BACKWARD)) {
			if ((time - self.last_BACKWARD_KEY_time) < self.cvar_cl_dodging_timeout)	{ 
				dodge_detected = 1;
				self.dodging_direction_x = -1.0;
			}
 			self.last_BACKWARD_KEY_time = time;
 		}
	}

	if (self.movement_y > 0) {
		// is this a state change?
		if (!(self.pressedkeys & KEY_RIGHT)) {
			if ((time - self.last_RIGHT_KEY_time) < self.cvar_cl_dodging_timeout)	{ 
				dodge_detected = 1;
				self.dodging_direction_y = 1.0;
			}
 			self.last_RIGHT_KEY_time = time;
 		}
	}

	if (self.movement_y < 0) {
		// is this a state change?
		if (!(self.pressedkeys & KEY_LEFT)) {
			if ((time - self.last_LEFT_KEY_time) < self.cvar_cl_dodging_timeout)	{ 
				dodge_detected = 1;
				self.dodging_direction_y = -1.0;
			}
 			self.last_LEFT_KEY_time = time;
 		}
	}



	if (dodge_detected == 1) {
		if (self.movement_z > 0)
			self.movement_z = 0;

		self.last_dodging_time = time;

		self.dodging_action = 1;
		self.dodging_single_action = 1;

		// normalize the dodging_direction vector.. (unlike UT99) XD
		length = length + self.dodging_direction_x * self.dodging_direction_x;
		length = length + self.dodging_direction_y * self.dodging_direction_y;
		length = sqrt(length);

		self.dodging_direction_x = self.dodging_direction_x * 1.0/length;
		self.dodging_direction_y = self.dodging_direction_y * 1.0/length;
	}

	return 0;
}

MUTATOR_DEFINITION(dodging)
{
	// we need to be called before GetPressedKey does its thing so we can
	// detect state changes and therefore dodging actions..
	MUTATOR_HOOK(GetPressedKeys, dodging_GetPressedKeys, CBC_ORDER_ANY);

	// in the physics hook we actually implement the dodge..
	MUTATOR_HOOK(PlayerPhysics, dodging_PlayerPhysics, CBC_ORDER_ANY);

	MUTATOR_HOOK(GetCvars, dodging_GetCvars, CBC_ORDER_ANY);

	// this just turns on the cvar.
	MUTATOR_ONADD
	{
		g_dodging = 1;
		dodging_Initialize();
	}

	// this just turns off the cvar.
	MUTATOR_ONREMOVE
	{	 
		g_dodging = 0;
	}

	return 0;
}
