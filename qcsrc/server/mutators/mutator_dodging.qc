.float last_FORWARD_KEY_time;
.float last_BACKWARD_KEY_time;
.float last_LEFT_KEY_time;
.float last_RIGHT_KEY_time;

// this indicates the last time a dodge was executed. used to check if another one is allowed
// and to ramp up the dodge acceleration in the physics hook.
.float last_dodge_time;

// set to 1 to indicate dodging has started.. reset by physics hook after dodge has been done..
.float dodge_action;

void dodging_Initialize() {
	self.last_FORWARD_KEY_time = 0;
	self.last_BACKWARD_KEY_time = 0;
	self.last_RIGHT_KEY_time = 0;
	self.last_LEFT_KEY_time = 0;
	self.last_dodge_time = 0;
	self.dodge_action = 0;
}

MUTATOR_HOOKFUNCTION(dodging_PlayerPhysics) {
	// print("physics hook\n");
	if (g_dodging == 0)
		return 0;

	

	return 0;
}

MUTATOR_HOOKFUNCTION(dodging_GetPressedKeys) {
	//print("dodging_hook\n");

	if (g_dodging == 0)
		return 0;

	if (self.movement_x > 0) // get if movement keys are pressed
   {       // forward key pressed
   	if (!(self.pressedkeys & KEY_FORWARD)) {        // is this a state change?
 			if (
				((time - self.last_FORWARD_KEY_time) < self.cvar_cl_dodging_timeout) &&
				(self.lastflags & FL_ONGROUND) &&
				((time - self.last_dodge_time) > cvar("sv_dodging_delay"))
 			) { // are we allowed to dodge?
				self.dodge_action = 1;
				// self.velocity = self.velocity + (cvar("sv_dodging_horiz_speed") * v_forward) + (cvar("sv_dodging_up_speed") * v_up);//'100 0 50';
				self.last_dodge_time = time;
			}
 			self.last_FORWARD_KEY_time = time;
 		}
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

	// this just turns on the cvar. TODO: implement :D
	MUTATOR_ONADD
	{
		g_dodging = 1;
		dodging_Initialize();
	}

	// this just turns off the cvar. TODO: implement :D
	MUTATOR_ONREMOVE
	{	 
		g_dodging = 0;
	}

	return 0;
}