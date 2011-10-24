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
			print_to(self, "^7\"^2spawn_object ^3models/foo/bar.md3^7\" spawns a new object in front of the player, and gives it the specified model");
			print_to(self, "^7\"^2spawn_item ^3item^7\" spawns the specified item in front of the player. Only weapons are currently supported");
			return TRUE;
		}
		else if(argv(1) == "spawn_object")
		{
			// don't allow spawning objects without a model
			if(cmd_argc < 3)
			{
				print_to(self, "WARNING: Attempted to spawn an object without specifying a model. Please specify the path to your model file after the 'spawn_object' command");
				return TRUE;
			}
			else if not(fexists(argv(2)))
			{
				print_to(self, "WARNING: Attempted to spawn an object with a non-existent model. Make sure the path to your model file is correct");
				return TRUE;
			}

			// spawn a new object with default properties
			entity e;
			e = spawn();
			e.realowner = self;
			e.classname = "object";
			e.takedamage = DAMAGE_NO;
			e.movetype = MOVETYPE_TOSS;
			e.solid = SOLID_BSP;

			makevectors(self.v_angle);
			WarpZone_TraceLine(self.origin + self.view_ofs, self.origin + self.view_ofs + v_forward * autocvar_g_sandbox_editor_distance_spawn, MOVE_NORMAL, self);
			setorigin(e, trace_endpos);
			setmodel(e, argv(2));
			e.angles_y = self.v_angle_y; // apply the player's direction to the object, as he spawns it from behind

			if(autocvar_g_sandbox_info)
				print(strcat(self.netname, " spawned an object at origin ", vtos(e.origin), "\n"));

			return TRUE;
		}
		else if(argv(1) == "spawn_item")
		{
			// weapons are the only items currently supported

			if(cmd_argc < 3)
			{
				print_to(self, "WARNING: Attempted to spawn an item without specifying its type. Please specify the name of your item after the 'spawn_item' command");
				return TRUE;
			}

			// spawn a new item
			entity e;
			float i;
			makevectors(self.v_angle);
			WarpZone_TraceLine(self.origin + self.view_ofs, self.origin + self.view_ofs + v_forward * autocvar_g_sandbox_editor_distance_spawn, MOVE_NOMONSTERS, self);

			for(i = WEP_FIRST; i <= WEP_LAST; ++i)
			{
				e = get_weaponinfo(i);
				if(e.netname == argv(2))
				{
					W_ThrowNewWeapon(self, i, FALSE, trace_endpos, '0 0 0');
					if(autocvar_g_sandbox_info)
						print(strcat(self.netname, " spawned a ^2", e.netname, "^7 at origin ", vtos(e.origin), "\n"));
					return TRUE;
				}
			}

			print_to(self, "WARNING: Attempted to spawn an invalid or unsupported item. See 'g_sandbox help' for supported items");
			return TRUE;
		}
		else if(argv(1) == "remove_object")
		{
			makevectors(self.v_angle);
			WarpZone_TraceLine(self.origin + self.view_ofs, self.origin + self.view_ofs + v_forward * autocvar_g_sandbox_editor_distance_edit, MOVE_NORMAL, self);
			if(trace_ent.classname == "object")
			{
				if(autocvar_g_sandbox_info)
					print(strcat(self.netname, " removed an object at origin ", vtos(trace_ent.origin), "\n"));
				remove(trace_ent);
				trace_ent = world;
				return TRUE;
			}

			print_to(self, "WARNING: Object could not be removed. Make sure you are facing an object that you have spawned");
			return TRUE;
		}
	}
	return FALSE;
}

MUTATOR_HOOKFUNCTION(sandbox_PlayerPreThink)
{
	// if the player is close enough to their own object and facing it, they can grab it

	if(autocvar_sv_cheats)
		return FALSE; // cheats already allow dragging all objects

	makevectors(self.v_angle);
	WarpZone_TraceLine(self.origin + self.view_ofs, self.origin + self.view_ofs + v_forward * autocvar_g_sandbox_editor_distance_edit, MOVE_NORMAL, self);
	if(trace_ent.classname == "object")
		if(Drag(trace_ent)) // executes the dragging
			if(autocvar_g_sandbox_info)
				print(strcat(self.netname, " grabbed an object at origin ", vtos(trace_ent.origin), "\n"));

	return FALSE;
}

MUTATOR_DEFINITION(sandbox)
{
	MUTATOR_HOOK(SV_ParseClientCommand, sandbox_PlayerCommand, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerPreThink, sandbox_PlayerPreThink, CBC_ORDER_ANY);

	return 0;
}
