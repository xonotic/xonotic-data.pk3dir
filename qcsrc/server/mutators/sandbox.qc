.string object_clipboard;
.entity object_attach;
.float object_count;
.string material;

.float touch_timer;
void sandbox_Object_Touch()
{
	// apply material impact effects

	if(!self.material)
		return;
	if(self.touch_timer > time)
		return; // don't execute each frame
	self.touch_timer = time + 0.1;

	// make particle count and sound volume depend on impact speed
	float intensity;
	intensity = vlen(self.velocity) + vlen(other.velocity);
	if(intensity) // avoid divisions by 0
		intensity /= 2; // average the two velocities
	if not(intensity >= autocvar_g_sandbox_object_material_velocity_min)
		return; // impact not strong enough to do anything
	// now offset intensity and apply it to the effects
	intensity -= autocvar_g_sandbox_object_material_velocity_min; // start from minimum velocity, not actual velocity
	intensity = bound(0, intensity * autocvar_g_sandbox_object_material_velocity_factor, 1);

	sound(self, CH_TRIGGER, strcat("object/impact_", self.material, "_", ftos(ceil(random() * 5)) , ".ogg"), VOL_BASE * intensity, ATTN_NORM);
	pointparticles(particleeffectnum(strcat("impact_", self.material)), self.origin, '0 0 0', ceil(intensity * 10)); // allow a count from 1 to 10
}

entity sandbox_EditObject_Get()
{
	// returns the traced entity if the player can edit it, and world if not
	// attached objects are SOLID_NOT and don't risk getting traced

	makevectors(self.v_angle);
	WarpZone_TraceLine(self.origin + self.view_ofs, self.origin + self.view_ofs + v_forward * autocvar_g_sandbox_editor_distance_edit, MOVE_NORMAL, self);
	if(trace_ent.classname == "object" && !(trace_ent.realowner != self && !autocvar_g_sandbox_editor_free))
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

.float old_movetype;
void sandbox_AttachObject_Set(entity e, entity parent, string s)
{
	// attaches e to parent on string s

	e.old_movetype = e.movetype; // persist this

	e.movetype = MOVETYPE_FOLLOW;
	e.solid = SOLID_NOT;
	e.takedamage = DAMAGE_NO;

	setattachment(e, parent, s);
	e.owner = parent;
}

void sandbox_AttachObject_Remove(entity e)
{
	// detaches any object attached to e

	entity head;
	for(head = world; (head = find(head, classname, "object")); )
	{
		if(head.owner == e)
		{
			head.movetype = head.old_movetype; // revert to previous physics
			head.solid = SOLID_BBOX;
			head.takedamage = DAMAGE_AIM;

			setattachment(head, world, "");
			head.owner = world;

			// objects reset origin and angles when detached, so apply the parent's to prevent teleporting
			setorigin(head, e.origin);
			head.angles = e.angles;
		}
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
	e.material = string_null;

	e.touch = sandbox_Object_Touch;

	// set origin and direction based on player position and view angle
	makevectors(self.v_angle);
	WarpZone_TraceLine(self.origin + self.view_ofs, self.origin + self.view_ofs + v_forward * autocvar_g_sandbox_editor_distance_spawn, MOVE_NORMAL, self);
	setorigin(e, trace_endpos);
	e.angles_y = self.v_angle_y;

	e.realowner.object_count += 1;

	return e;
}

void sandbox_RemoveObject(entity e)
{
	e.realowner.object_count -= 1;

	if(e.material)
	{
		strunzone(e.material);
		e.material = string_null;
	}
	remove(e);
	e = world;
}

string sandbox_Storage_Save(entity e)
{
	// save object properties
	string s;

	s = strcat(e.model, " ");
	s = strcat(s, ftos(e.skin), " ");
	s = strcat(s, ftos(e.alpha), " ");
	s = strcat(s, sprintf("\"%.9v\"", e.colormod), " ");
	s = strcat(s, sprintf("\"%.9v\"", e.glowmod), " ");
	s = strcat(s, ftos(e.frame), " ");
	s = strcat(s, ftos(e.scale), " ");
	s = strcat(s, ftos(e.movetype), " ");
	s = strcat(s, ftos(e.damageforcescale), " ");
	s = strcat(s, e.material, " ");

	return s;
}

void sandbox_Storage_Load(entity e, string s)
{
	// load object properties
	tokenize_console(s);

	setmodel(e, argv(0));
	e.skin = stof(argv(1));
	e.alpha = stof(argv(2));
	e.colormod = stov(argv(3));
	e.glowmod = stov(argv(4));
	e.frame = stof(argv(5));
	sandbox_EditObject_Scale(e, stof(argv(6)));
	e.movetype = stof(argv(7));
	e.damageforcescale = stof(argv(8));
	if(e.material)	strunzone(e.material);	if(argv(9))	e.material = strzone(argv(9));	else	e.material = string_null;
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
			float i;

			// ---------------- COMMAND: HELP ----------------
			case "help":
				print_to(self, "You can use the following sandbox commands:");
				print_to(self, "^7\"^2spawn_item ^3item^7\" spawns the specified item in front of the player. Only weapons are currently supported");
				print_to(self, "^7\"^2spawn_object ^3models/foo/bar.md3^7\" spawns a new object in front of the player, and gives it the specified model");
				print_to(self, "^7\"^2remove_object^7\" removes the object the player is looking at. Players can only remove their own objects");
				print_to(self, "^7\"^2duplicate_object_copy^7\" copies the object the player is looking at. Players can only copy their own objects");
				print_to(self, "^7\"^2duplicate_object_paste^7\" pastes the copied object in front of the player");
				print_to(self, "^7\"^2attach_object ^3property value^7\" attaches one object to another. Players can only attach their own objects");
				print_to(self, "^7Attachment properties for ^2attach_object^7:");
				print_to(self, "^3get ^7- selects the object you are facing as the object to be attached");
				print_to(self, "^3set value ^7- attaches the previously selected object to the object you are facing, on the specified bone");
				print_to(self, "^3remove ^7- detaches all objects from the object you are facing");
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
				print_to(self, "^3material value ^7- sets the material of the object. Default materials are: metal, stone, wood, flesh");
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
				if(self.object_count >= autocvar_g_sandbox_editor_maxobjects)
				{
					print_to(self, strcat("WARNING: Cannot spawn any more objects. Each player may have up to ^3", ftos(autocvar_g_sandbox_editor_maxobjects), " ^7objects at a time"));
					return TRUE;
				}
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
					sandbox_RemoveObject(e);
					return TRUE;
				}

				print_to(self, "WARNING: Object could not be removed. Make sure you are facing an object that belongs to you (default)");
				return TRUE;

			// ---------------- COMMAND: DUPLICATE OBJECT COPY ----------------
			case "duplicate_object_copy":
				// copies customizable properties of the selected object to the clipboard

				e = sandbox_EditObject_Get(); // you can only copy objects you can edit, so this works
				if(e != world)
				{
					if(self.object_clipboard)
						strunzone(self.object_clipboard);
					self.object_clipboard = strzone(sandbox_Storage_Save(e));

					print_to(self, "Object copied to clipboard");
					return TRUE;
				}

				print_to(self, "WARNING: Object could not be copied. Make sure you are facing an object that belongs to you (default)");
				return TRUE;

			// ---------------- COMMAND: DUPLICATE OBJECT PASTE ----------------
			case "duplicate_object_paste":
				// spawns a new object using the properties in the player's clipboard

				if(!self.object_clipboard) // no object in clipboard
				{
					print_to(self, "WARNING: No object in clipboard. You must copy an object before you can paste it");
					return TRUE;
				}
				if(self.object_count >= autocvar_g_sandbox_editor_maxobjects)
				{
					print_to(self, strcat("WARNING: Cannot spawn any more objects. Each player may have up to ^3", ftos(autocvar_g_sandbox_editor_maxobjects), " ^7objects at a time"));
					return TRUE;
				}

				e = sandbox_SpawnObject();
				sandbox_Storage_Load(e, self.object_clipboard);

				print_to(self, "Object pasted successfully");
				if(autocvar_g_sandbox_info)
					print(strcat(self.netname, " pasted an object at origin ", vtos(e.origin), "\n"));

				return TRUE;

			// ---------------- COMMAND: ATTACH OBJECT ----------------
			case "attach_object":
				switch(argv(2))
				{
					case "get":
						// select e as the object as meant to be attached
						e = sandbox_EditObject_Get();
						if(e != world)
						{
							self.object_attach = e;
							print_to(self, "Object selected for attachment");
							return TRUE;
						}
						print_to(self, "WARNING: Object could not be selected for attachment. Make sure you are facing an object that belongs to you (default)");
						return TRUE;
					case "set":
						if(self.object_attach == world)
						{
							print_to(self, "WARNING: No object selected for attachment. Please select an object to be attached first.");
							return TRUE;
						}

						// attaches the previously selected object to e
						e = sandbox_EditObject_Get();
						if(e != world)
						{
							sandbox_AttachObject_Set(self.object_attach, e, argv(3));
							print_to(self, "Object attached successfully");
							self.object_attach = world; // object was attached, no longer keep it scheduled for attachment
							return TRUE;
						}
						print_to(self, "WARNING: Object could not be attached to the parent. Make sure you are facing an object that belongs to you (default)");
						return TRUE;
					case "remove":
						// removes e if it was attached
						e = sandbox_EditObject_Get();
						if(e != world)
						{
							sandbox_AttachObject_Remove(e);
							print_to(self, "Child objects detached successfully");
							return TRUE;
						}
						print_to(self, "WARNING: Child objects could not be detached. Make sure you are facing an object that belongs to you (default)");
						return TRUE;
				}
				return TRUE;

			// ---------------- COMMAND: EDIT OBJECT ----------------
			case "edit_object":
				if(!argv(2))
				{
					print_to(self, "WARNING: Too few parameters. You must specify a property to edit");
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
							if(e.material)
								strunzone(e.material);
							if(argv(3))
							{
								for (i = 1; i <= 5; i++) // precache material sounds, 5 in total
									precache_sound(strcat("object/impact_", argv(3), "_", ftos(i), ".ogg"));
								e.material = strzone(argv(3));
							}
							else
								e.material = string_null; // no material
							break;
						default:
							print_to(self, "WARNING: Invalid object property. For usage information, type 'sandbox help'");
							break;
					}
					return TRUE;
				}

				print_to(self, "WARNING: Object could not be edited. Make sure you are facing an object that belongs to you (default)");
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

