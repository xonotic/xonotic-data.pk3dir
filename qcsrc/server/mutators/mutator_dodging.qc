
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

void dodging_Initialize() {
	self.last_FORWARD_KEY_time = 0;
	self.last_BACKWARD_KEY_time = 0;
	self.last_RIGHT_KEY_time = 0;
	self.last_LEFT_KEY_time = 0;
	self.last_dodging_time = 0;
	self.dodging_action = 0;
	self.dodging_direction_x = 0;
	self.dodging_direction_y = 0;
}

MUTATOR_HOOKFUNCTION(dodging_PlayerPhysics) {
	// print("physics hook\n");
	if (g_dodging == 0)
		return 0;

	// ramp up dodging speed by adding some velocity each frame.. TODO: do it! :D
	if (self.dodging_action == 1) {
		//print(vtos(self.v_up), "\n");
		//self.velocity_z = self.velocity_z + cvar("sv_dodging_up_speed") * v_up;
		//self.velocity_x = self.velocity_x + self.dodging_direction_x * cvar("sv_dodging_horiz_speed") * v_forward;
		//self.velocity_y = self.velocity_y + self.dodging_direction_y * cvar("sv_dodging_horiz_speed") * v_right;
		self.velocity = self.velocity + ((self.dodging_direction_y * cvar("sv_dodging_horiz_speed")) * v_right) + ((self.dodging_direction_x * cvar("sv_dodging_horiz_speed")) * v_forward) + (cvar("sv_dodging_up_speed") * v_up);

		// reset state so next dodge can be done correctly
		self.dodging_action = 0;
		self.dodging_direction_x = 0;
		self.dodging_direction_y = 0;
	}

	// are we done with the dodging ramp yet?
	if((self.dodging_action == 1) && ((time - self.last_dodging_time) > cvar("sv_dodging_ramp_time")))
		self.dodging_action = 0;

	return 0;
}

MUTATOR_HOOKFUNCTION(dodging_GetPressedKeys) {
	float length;
	float dodge_detected;
	//print("dodging_hook\n");

	if (g_dodging == 0)
		return 0;

	dodge_detected = 0;
	if (self.movement_x > 0) // get if movement keys are pressed
   {       // forward key pressed
   	if (!(self.pressedkeys & KEY_FORWARD)) {        // is this a state change?
 			if ( // are we allowed to dodge?
				((time - self.last_FORWARD_KEY_time) < self.cvar_cl_dodging_timeout) &&
				(self.lastflags & FL_ONGROUND) &&
				((time - self.last_dodging_time) > cvar("sv_dodging_delay"))
 			) { 
				dodge_detected = 1;
				self.dodging_action = 1;
				self.dodging_direction_x = 1.0;
				self.last_dodging_time = time;
			}
 			self.last_FORWARD_KEY_time = time;
 		}
	}

	if (self.movement_x < 0) 
   {
		if (!(self.pressedkeys & KEY_BACKWARD)) {        // is this a state change?
 			if ( // are we allowed to dodge?
				((time - self.last_BACKWARD_KEY_time) < self.cvar_cl_dodging_timeout) &&
				(self.lastflags & FL_ONGROUND) &&
				((time - self.last_dodging_time) > cvar("sv_dodging_delay"))
 			) { 
				dodge_detected = 1;
				self.dodging_action = 1;
				self.dodging_direction_x = -1.0;
				self.last_dodging_time = time;
			}
 			self.last_BACKWARD_KEY_time = time;
 		}
	}


//	if (dodge_detected == 1) {
//		// normalize the dodging_direction vector.. 
//		length = length + self.dodging_direction_x * self.dodging_direction_x;
//		length = length + self.dodging_direction_y * self.dodging_direction_y;
//		length = sqrt(length);
//
//		self.dodging_direction_x = self.dodging_direction_x * 1.0/length;
//		self.dodging_direction_y = self.dodging_direction_y * 1.0/length;
//	}
//
	return 0;
}

MUTATOR_DEFINITION(dodging)
{
	// we need to be called before GetPressedKey does its thing so we can
	// detect state changes and therefore dodging actions..
	MUTATOR_HOOK(GetPressedKeys, dodging_GetPressedKeys, CBC_ORDER_ANY);

	// in the physics hook we actually implement the dodge..
	MUTATOR_HOOK(PlayerPhysics, dodging_PlayerPhysics, CBC_ORDER_ANY);

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