MUTATOR_HOOKFUNCTION(sandbox_PlayerCommand)
{
	if(MUTATOR_RETURNVALUE) // command was already handled?
		return FALSE;
	if(cmd_name == "g_sandbox")
	{
		if(cmd_argc < 2)
		{
			print_to(self, "Sandbox mode is active. For more information, use 'g_sandbox help'");
			return TRUE;
		}

		if(argv(1) == "help")
		{
			print_to(self, "You can use the following sandbox commands:");
			print_to(self, "^7\"^2spawn ^3models/foo/bar.md3^7\" spawns a new object in front of the player, and gives it the specified model");
			return TRUE;
		}
		else if(argv(1) == "spawn")
		{
			// spawn a new object with the default settings

			// don't allow spawning objects without a model
			if(cmd_argc < 3)
			{
				print_to(self, "WARNING: Attempted to spawn an object without specifying a model. Please specify the path to your model file after the 'spawn' command");
				return TRUE;
			}
			else if not(fexists(argv(2)))
			{
				print_to(self, "WARNING: Attempted to spawn an object with a non-existent model. Make sure the path to your model file is correct");
				return TRUE;
			}

			entity e;
			e = spawn();
			e.classname = "object";
			makevectors(self.v_angle);
			traceline(self.origin + self.view_ofs, self.origin + self.view_ofs + v_forward * autocvar_g_sandbox_editor_distance, MOVE_NOMONSTERS, self);
			setorigin(e, trace_endpos);
			setmodel(e, argv(2));
			e.angles = self.v_angle; // give the player's angles to the object, as he spawns it from behind

			if(autocvar_g_sandbox_info)
				print(strcat(self.netname, " spawned an object at origin ", vtos(e.origin), "\n"));

			return TRUE;
		}
	}
	return FALSE;
}

MUTATOR_DEFINITION(sandbox)
{
	MUTATOR_HOOK(SV_ParseClientCommand, sandbox_PlayerCommand, CBC_ORDER_ANY);

	return 0;
}
