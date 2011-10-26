.string object_clipboard;
.float material;

const float MATERIAL_METAL = 1;
const float MATERIAL_STONE = 2;
const float MATERIAL_WOOD = 3;
const float MATERIAL_FLESH = 4;

entity sandbox_EditObject_Get()
{
	// returns the traced entity if the player can edit it, and world if not

	makevectors(self.v_angle);
	WarpZone_TraceLine(self.origin + self.view_ofs, self.origin + self.view_ofs + v_forward * autocvar_g_sandbox_editor_distance_edit, MOVE_NORMAL, self);
	if(trace_ent.classname == "object" && trace_ent.realowner == self)
		return trace_ent;
	else
		return world;
}

void sandbox_EditObject_Scale(entity e, float f)
{
	e.scale = f;
	if(e.scale)
	{
		e.scale = bound(autocvar_g_sandbox_object_scale_min, e.scale, autocvar_g_sandbox_object_scale_max);
		setsize(e, e.mins * e.scale, e.maxs * e.scale); // adapt bounding box size to model size
	}
}

void sandbox_Object_Touch()
{
	if not(vlen(self.velocity) >= autocvar_g_sandbox_object_matvel || vlen(other.velocity) >= autocvar_g_sandbox_object_matvel)
		return;

	switch(self.material)
	{
		case MATERIAL_METAL:
			sound(self, CH_TRIGGER, strcat("object/impact_metal_", ftos(ceil(random() * 5)) , ".ogg"), VOL_BASE, ATTN_NORM);
			break;
		case MATERIAL_STONE:
			sound(self, CH_TRIGGER, strcat("object/impact_stone_", ftos(ceil(random() * 5)) , ".ogg"), VOL_BASE, ATTN_NORM);
			break;
		case MATERIAL_WOOD:
			sound(self, CH_TRIGGER, strcat("object/impact_wood_", ftos(ceil(random() * 5)) , ".ogg"), VOL_BASE, ATTN_NORM);
			break;
		case MATERIAL_FLESH:
			sound(self, CH_TRIGGER, strcat("object/impact_flesh_", ftos(ceil(random() * 5)) , ".ogg"), VOL_BASE, ATTN_NORM);
			break;
		default:
			break;
	}
}

entity sandbox_SpawnObject()
{
	// spawn a new object with default properties

	entity e;
	e = spawn();
	e.realowner = self;
	e.classname = "object";
	e.takedamage = DAMAGE_AIM;
	e.damageforcescale = 1;
	e.solid = SOLID_BBOX; // SOLID_BSP would be best, but can lag the server badly
	e.movetype = MOVETYPE_TOSS;
	e.frame = 0;
	e.skin = 0;
	e.material = MATERIAL_METAL;

	e.touch = sandbox_Object_Touch;

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

		switch(argv(1))
		{
			entity e;

			// ---------------- COMMAND: HELP ----------------
			case "help":
				print_to(self, "You can use the following sandbox commands:");
				print_to(self, "^7\"^2spawn_item ^3item^7\" spawns the specified item in front of the player. Only weapons are currently supported");
				print_to(self, "^7\"^2spawn_object ^3models/foo/bar.md3^7\" spawns a new object in front of the player, and gives it the specified model");
				print_to(self, "^7\"^2remove_object^7\" removes the object the player is looking at. Players can only remove their own objects");
				print_to(self, "^7\"^2duplicate_object_copy^7\" copies the object the player is looking at. Players can only copy their own objects");
				print_to(self, "^7\"^2duplicate_object_paste^7\" pastes the copied object in front of the player");
				print_to(self, "^7\"^2edit_object ^3property value^7\" edits the given property of the object. Players can only edit their own objects");
				print_to(self, "^7Object properties for ^2edit_object^7:");
				print_to(self, "^3skin value ^7- changes the skin of the object");
				print_to(self, "^3alpha value ^7- sets object transparency");
				print_to(self, "^3colormod \"value_x value_y value_z\" ^7- main object color");
				print_to(self, "^3glowmod \"value_x value_y value_z\" ^7- glow object color");
				print_to(self, "^3frame value ^7- object animation frame, for self-animated models");
				print_to(self, "^3scale value ^7- changes object scale. 0.5 is half size and 2 is double size");
				print_to(self, "^3physics value ^7- object physics, 0 = static, 1 = movable, 2 = physical");
				print_to(self, "^3force value ^7- amount of force applied to objects that are shot");
				print_to(self, "^3material value ^7- sets the material of the object. Valid materials are: 1 (metal), 2 (stone), 3 (wood), 4 (flesh)");
				print_to(self, "^7The ^1drag object ^7key can be used to grab and carry objects. Players can only grab their own objects");
				return TRUE;

			// ---------------- COMMAND: SPAWN ITEM ----------------
			case "spawn_item":
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

			// ---------------- COMMAND: SPAWN OBJECT ----------------
			case "spawn_object":
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

			// ---------------- COMMAND: REMOVE OBJECT ----------------
			case "remove_object":
				e = sandbox_EditObject_Get();
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

			// ---------------- COMMAND: DUPLICATE OBJECT COPY ----------------
			case "duplicate_object_copy":
				// copies customizable properties of the selected object to the clipboard

				e = sandbox_EditObject_Get(); // you can only copy objects you can edit, so this works
				if(e != world)
				{
					if(self.object_clipboard)
						strunzone(self.object_clipboard);

					// set clipboard properties
					self.object_clipboard = strcat(e.model, " ");
					self.object_clipboard = strcat(self.object_clipboard, ftos(e.skin), " ");
					self.object_clipboard = strcat(self.object_clipboard, ftos(e.alpha), " ");
					self.object_clipboard = strcat(self.object_clipboard, sprintf("\"%.9v\"", e.colormod), " ");
					self.object_clipboard = strcat(self.object_clipboard, sprintf("\"%.9v\"", e.glowmod), " ");
					self.object_clipboard = strcat(self.object_clipboard, ftos(e.frame), " ");
					self.object_clipboard = strcat(self.object_clipboard, ftos(e.scale), " ");
					self.object_clipboard = strcat(self.object_clipboard, ftos(e.movetype), " ");
					self.object_clipboard = strcat(self.object_clipboard, ftos(e.damageforcescale), " ");
					self.object_clipboard = strcat(self.object_clipboard, ftos(e.material), " ");

					self.object_clipboard = strzone(self.object_clipboard);
					print_to(self, "Object copied to clipboard");
					return TRUE;
				}

				print_to(self, "WARNING: Object could not be copied. Make sure you are facing an object that belongs to you");
				return TRUE;

			// ---------------- COMMAND: DUPLICATE OBJECT PASTE ----------------
			case "duplicate_object_paste":
				// spawns a new object using the properties in the player's clipboard

				if(!self.object_clipboard) // no object in clipboard
				{
					print_to(self, "WARNING: No object in clipboard. You must copy an object before you can paste it");
					return TRUE;
				}

				e = sandbox_SpawnObject();
				tokenize_console(self.object_clipboard);

				// apply clipboard properties
				setmodel(e, argv(0));
				e.skin = stof(argv(1));
				e.alpha = stof(argv(2));
				e.colormod = stov(argv(3));
				e.glowmod = stov(argv(4));
				e.frame = stof(argv(5));
				sandbox_EditObject_Scale(e, stof(argv(6)));
				e.movetype = stof(argv(7));
				e.damageforcescale = stof(argv(8));
				e.material = stof(argv(9));

				print_to(self, "Object pasted");
				if(autocvar_g_sandbox_info)
					print(strcat(self.netname, " pasted an object at origin ", vtos(e.origin), "\n"));

				return TRUE;

			// ---------------- COMMAND: EDIT OBJECT ----------------
			case "edit_object":
				if(!argv(2) || !argv(3))
				{
					print_to(self, "WARNING: Too few parameters. You must specify a property to edit, followed by its value");
					return TRUE;
				}

				e = sandbox_EditObject_Get();
				if(e != world)
				{
					switch(argv(2))
					{
						case "skin":
							e.skin = stof(argv(3));
							break;
						case "alpha":
							e.alpha = stof(argv(3));
							break;
						case "color_main":
							e.colormod = stov(argv(3));
							break;
						case "color_glow":
							e.glowmod = stov(argv(3));
							break;
						case "frame":
							e.frame = stof(argv(3));
							break;
						case "scale":
							sandbox_EditObject_Scale(e, stof(argv(3)));
							break;
						case "physics":
							switch(argv(3))
							{
								case "0": // static
									e.movetype = MOVETYPE_NONE;
									break;
								case "1": // movable
									e.movetype = MOVETYPE_TOSS;
									break;
								case "2": // physical
									e.movetype = MOVETYPE_PHYSICS;
									break;
								default:
									break;
							}
							break;
						case "force":
							e.damageforcescale = stof(argv(3));
							break;
						case "material":
							e.material = stof(argv(3));
							break;
						default:
							print_to(self, "WARNING: Invalid object property. For usage information, type 'sandbox help'");
							break;
					}

					return TRUE;
				}

				print_to(self, "WARNING: Object could not be edited. Make sure you are facing an object that belongs to you");
				return TRUE;

			// ---------------- COMMAND: DEFAULT ----------------
			default:
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

	e = sandbox_EditObject_Get();
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

	MUTATOR_ONADD
	{
		float i;
		for (i = 1; i <= 5; i++)
		{
			// precache material sounds
			precache_sound(strcat("objects/impact_metal_", ftos(i), ".ogg"));
			precache_sound(strcat("objects/impact_stone_", ftos(i), ".ogg"));
			precache_sound(strcat("objects/impact_wood_", ftos(i), ".ogg"));
			precache_sound(strcat("objects/impact_flesh_", ftos(i), ".ogg"));
		}
	}

	return FALSE;
}

