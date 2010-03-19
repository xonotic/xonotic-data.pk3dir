.float last_FORWARD_KEY_time;
.float last_BACKWARD_KEY_time;
.float last_LEFT_KEY_time;
.float last_RIGHT_KEY_time;

void dodging_Initialize() {
	  self.last_FORWARD_KEY_time = 0;
	  self.last_BACKWARD_KEY_time = 0;
	  self.last_RIGHT_KEY_time = 0;
	  self.last_LEFT_KEY_time = 0;
}

MUTATOR_HOOKFUNCTION(dodging_GetPressedKeys) {
	print("dodging_hook\n");
	return 0;
}

MUTATOR_DEFINITION(dodging)
{
	// we need to be called before GetPressedKey does its thing so we can
	// detect state changes..
	MUTATOR_HOOK(GetPressedKeys, dodging_GetPressedKeys, CBC_ORDER_FIRST);

	// this just turns on the cvar. TODO: implement :D
	MUTATOR_ONADD
	{
		// g_dodging = 1;
		dodging_Initialize();
	}

	// this just turns off the cvar. TODO: implement :D
	MUTATOR_ONREMOVE
	{	 
		//g_dodging = 0;
	}

	return 0;
}