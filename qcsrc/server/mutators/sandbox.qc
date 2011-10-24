MUTATOR_HOOKFUNCTION(sandbox_PlayerCommand)
{
	if(MUTATOR_RETURNVALUE) // command was already handled?
		return 0;
	if(cmd_name == "g_sandbox")
	{
		if(cmd_argc < 2)
		{
			print_to(self, "Sandbox mode is active. For more information, use 'g_sandbox help'");
			return 1;
		}

		if(argv(1) == "help")
		{
			print_to(self, "You can use the following sandbox commands:");
			print_to(self, "^7\"^2spawn ^3models/foo/bar.md3^7\" spawns a new object in front of the player, and gives it the specified model");
			return 1;
		}
		else if(argv(1) == "spawn")
		{
			// spawn a new object with the default settings

			entity e;
			e = spawn();
			makevectors(self.v_angle);
			traceline(self.origin + self.view_ofs, self.origin + self.view_ofs + v_forward * 250, MOVE_NOMONSTERS, self);
			setorigin(e, trace_endpos);
			setmodel(e, "models/vehicles-static/raptor.md3");

			if(autocvar_g_sandbox_info)
				print(strcat(self.netname, " spawned an object at origin ", vtos(e.origin), "\n"));

			return 1;
		}
	}
	return 0;
}

MUTATOR_DEFINITION(sandbox)
{
	MUTATOR_HOOK(SV_ParseClientCommand, sandbox_PlayerCommand, CBC_ORDER_ANY);

	return 0;
}
