.string object_clipboard;

entity sandbox_EditObject()
{
	// returns the traced entity if the player can edit it, and world if not

	makevectors(self.v_angle);
	WarpZone_TraceLine(self.origin + self.view_ofs, self.origin + self.view_ofs + v_forward * autocvar_g_sandbox_editor_distance_edit, MOVE_NORMAL, self);
	if(trace_ent.classname == "object" && trace_ent.realowner == self)
		return trace_ent;
	else
		return world;
}

entity sandbox_SpawnObject()
{
	// spawn a new object with default properties

	entity e;
	e = spawn();
	e.realowner = self;
	e.classname = "object";
	e.takedamage = DAMAGE_NO;
	e.movetype = MOVETYPE_TOSS;
	e.solid = SOLID_BBOX; // SOLID_BSP would be best, but can lag a server horribly

	// set origin and direction based on player position and view angle
	makevectors(self.v_angle);
	WarpZone_TraceLine(self.origin + self.view_ofs, self.origin + self.view_ofs + v_forward * autocvar_g_sandbox_editor_distance_spawn, MOVE_NORMAL, self);
	setorigin(e, trace_endpos);
	e.angles_y = self.v_angle_y;

	return e;
}

MUTATOR_HOOKFUNCTION(sandbox_PlayerCommand)
{
	if(MUTATOR_RETURNVALUE) // command was already handled?
		return FALSE;
	if(cmd_name == "g_sandbox")
	{
		if(cmd_argc < 2)
		{
			print_to(self, "Sandbox mode is active. For usage information, type 'sandbox help'");
			return TRUE;
		}

		entity e;
		if(argv(1) == "help")
		{
			print_to(self, "You can use the following sandbox commands:");
			print_to(self, "^7\"^2spawn_item ^3item^7\" spawns the specified item in front of the player. Only weapons are currently supported");
			print_to(self, "^7\"^2spawn_object ^3models/foo/bar.md3^7\" spawns a new object in front of the player, and gives it the specified model");
			print_to(self, "^7\"^2remove_object^7\" removes the object the player is looking at. Players can only remove their own objects");
			print_to(self, "^7\"^2duplicate_object_copy^7\" copies the object the player is looking at. Players can only copy their own objects");
			print_to(self, "^7\"^2duplicate_object_paste^7\" pastes the copied object in front of the player");
			print_to(self, "^7The ^1drag object ^7key can be used to grab and carry objects. Players can only grab their own objects");
			return TRUE;
		}
		else if(argv(1) == "spawn_item")
		{
			// only weapons are currently supported

			if(cmd_argc < 3)
			{
				print_to(self, "WARNING: Attempted to spawn an item without specifying its type. Please specify the name of your item after the 'spawn_item' command");
				return TRUE;
			}

			// spawn a new item
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

			print_to(self, "WARNING: Attempted to spawn an invalid or unsupported item. See 'sandbox help' for allowed items");
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

			e = sandbox_SpawnObject();
			setmodel(e, argv(2));

			if(autocvar_g_sandbox_info)
				print(strcat(self.netname, " spawned an object at origin ", vtos(e.origin), "\n"));

			return TRUE;
		}
		else if(argv(1) == "remove_object")
		{
			e = sandbox_EditObject();
			if(e != world)
			{
				if(autocvar_g_sandbox_info)
					print(strcat(self.netname, " removed an object at origin ", vtos(e.origin), "\n"));
				remove(e);
				e = world;
				return TRUE;
			}

			print_to(self, "WARNING: Object could not be removed. Make sure you are facing an object that belongs to you");
			return TRUE;
		}
		else if(argv(1) == "duplicate_object_copy")
		{
			// copies customizable properties of the selected object to the clipboard

			e = sandbox_EditObject(); // you can only copy objects you can edit, so this works
			if(e != world)
			{
				if(self.object_clipboard)
					strunzone(self.object_clipboard);
				self.object_clipboard = strzone(strcat(e.model, " ", ftos(e.movetype)));

				print_to(self, "Object copied to clipboard");
				return TRUE;
			}

			print_to(self, "WARNING: Object could not be copied. Make sure you are facing an object that belongs to you");
			return TRUE;
		}
		else if(argv(1) == "duplicate_object_paste")
		{
			// spawns a new object using the properties in the player's clipboard

			if(!self.object_clipboard) // no object in clipboard
			{
				print_to(self, "WARNING: No object in clipboard. You must copy an object before you can paste it");
				return TRUE;
			}

			e = sandbox_SpawnObject();
			tokenize_console(self.object_clipboard);

			setmodel(e, argv(0));
			e.movetype = stof(argv(1));

			print_to(self, "Object pasted");
			if(autocvar_g_sandbox_info)
				print(strcat(self.netname, " pasted an object at origin ", vtos(e.origin), "\n"));

			return TRUE;
		}
		else
		{
			print_to(self, "Invalid command. For usage information, type 'sandbox help'");
			return TRUE;
		}
	}
	return FALSE;
}

MUTATOR_HOOKFUNCTION(sandbox_PlayerPreThink)
{
	// if the player is close enough to their object, they can drag it

	if(autocvar_sv_cheats)
		return FALSE; // cheat dragging is used instead

	// grab is TRUE if the object can be picked up. While an object is being carried, the Drag() function
	// must execute for it either way, otherwise it would cause bugs if it went out of the player's trace.
	// This also makes sure that an object can only pe picked up if in range, but does not get dropped if
	// it goes out of range while slinging it around.

	entity e;
	float grab;

	e = sandbox_EditObject();
	if(e != world && vlen(e.origin - self.origin) <= autocvar_g_sandbox_editor_distance_edit)
		grab = TRUE;

	if(Drag(e, grab)) // execute dragging
	{
		if(autocvar_g_sandbox_info)
			print(strcat(self.netname, " grabbed an object at origin ", vtos(e.origin), "\n"));
		return TRUE;
	}

	return FALSE;
}

MUTATOR_HOOKFUNCTION(sandbox_ClientDisconnect)
{
	// unzone the player's clipboard if it's not empty
	if(self.object_clipboard)
	{
		strunzone(self.object_clipboard);
		self.object_clipboard = string_null;
	}

	return FALSE;
}

MUTATOR_DEFINITION(sandbox)
{
	MUTATOR_HOOK(SV_ParseClientCommand, sandbox_PlayerCommand, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerPreThink, sandbox_PlayerPreThink, CBC_ORDER_ANY);
	MUTATOR_HOOK(ClientDisconnect, sandbox_ClientDisconnect, CBC_ORDER_ANY);

	return FALSE;
}
