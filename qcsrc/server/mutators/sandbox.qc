float object_count;
.string object_clipboard;
.entity object_attach;
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

	if(trace_ent.classname != "object")
		return world; // entity is not an object
	if(!trace_ent.crypto_idfp)
		return trace_ent; // the player who spawned this object did not have an UID, so anyone can edit it
	else if not(trace_ent.crypto_idfp != self.crypto_idfp && !autocvar_g_sandbox_editor_free)
		return trace_ent; // object does not belong to the player, and players can only edit their own objects on this server
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

entity sandbox_SpawnObject(float database)
{
	// spawn a new object with default properties

	entity e;
	e = spawn();
	e.classname = "object";
	e.takedamage = DAMAGE_AIM;
	e.damageforcescale = 1;
	e.solid = SOLID_BBOX; // SOLID_BSP would be best, but can lag the server badly
	e.movetype = MOVETYPE_TOSS;
	e.frame = 0;
	e.skin = 0;
	e.material = string_null;
	e.touch = sandbox_Object_Touch;

	if(!database)
	{
		// set the object's owner via player UID
		// if the player does not have an UID, the owner cannot be stored and his objects may be edited by anyone
		if(self.crypto_idfp != "")
			e.crypto_idfp = strzone(self.crypto_idfp);
		else
			print_to(self, "^1SANDBOX - WARNING: ^7You spawned an object, but lack a player UID. ^1Your objects are not secured and can be edited by any player!");

		// set origin and direction based on player position and view angle
		makevectors(self.v_angle);
		WarpZone_TraceLine(self.origin + self.view_ofs, self.origin + self.view_ofs + v_forward * autocvar_g_sandbox_editor_distance_spawn, MOVE_NORMAL, self);
		setorigin(e, trace_endpos);
		e.angles_y = self.v_angle_y;
	}

	object_count += 1;
	return e;
}

void sandbox_RemoveObject(entity e)
{
	sandbox_AttachObject_Remove(e); // detach child objects
	if(e.material)
	{
		strunzone(e.material);
		e.material = string_null;
	}
	if(e.crypto_idfp)
	{
		strunzone(e.crypto_idfp);
		e.crypto_idfp = string_null;
	}
	remove(e);
	e = world;

	object_count -= 1;
}

string sandbox_Storage_Save(entity e, float database)
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
	if(database)
	{
		s = strcat(s, e.crypto_idfp, " ");
		s = strcat(s, sprintf("\"%.9v\"", e.origin), " ");
		s = strcat(s, sprintf("\"%.9v\"", e.angles), " ");
	}

	return s;
}

void sandbox_Storage_Load(entity e, string s, float database)
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
	if(database)
	{
		if(e.crypto_idfp)	strunzone(e.crypto_idfp);	if(argv(10))	e.crypto_idfp = strzone(argv(10));	else	e.crypto_idfp = string_null;
		setorigin(e, stov(argv(11)));
		e.angles = stov(argv(12));
	}
}

void sandbox_Storage_DatabaseSave()
{
	// saves all objects to the database file
	if(!object_count)
		return; // nothing to store

	entity head;
	string fn;
	float fh, i;

	fn = strcat("sandbox/storage_", GetMapname(), ".txt");
	fh = fopen(fn, FILE_WRITE);
	fputs(fh, strcat("// sandbox storage for map ", GetMapname(), ", containing a total of ", ftos(object_count), " objects\n"));
	i = 1;
	for(head = world; (head = find(head, classname, "object")); )
	{
		// Unfortunately, attached objects cannot be persisted yet. That's because the parent is specified as an entity,
		// but only properties can be saved to this file, leaving no way to identify the owner once all objects are spawned
		// TODO: Find some way to fix this!
		if(head.owner != world)
			continue;

		// use a line for each object, listing all properties
		fputs(fh, strcat("object", ftos(i), " ", sandbox_Storage_Save(head, TRUE), "\n"));
		i++;
	}
	fclose(fh);
}

void sandbox_Storage_DatabaseLoad()
{
	// loads all objects from the database file
	string fn, rf;
	float fh;

	fn = strcat("sandbox/storage_", GetMapname(), ".txt");
	fh = fopen(fn, FILE_READ);
	if(fh < 0)
		{ } // message comes here
	else
	{
		for(;;)
		{
			rf = fgets(fh);
			if(!rf)
				break;
			if(substring(rf, 0, 2) == "//")
				continue;
			if(substring(rf, 0, 1) == "#")
				continue;
			dprint(strcat(rf, " --------\n"));
		}
	}
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
				print_to(self, "^7\"^2object_spawn ^3models/foo/bar.md3^7\" spawns a new object in front of the player, and gives it the specified model");
				print_to(self, "^7\"^2object_remove^7\" removes the object the player is looking at. Players can only remove their own objects");
				print_to(self, "^7\"^2object_duplicate ^3value^7\" duplicates the object. 'copy' copies the object, 'paste' puts it in front of the player");
				print_to(self, "^7\"^2object_claim^7\" sets the player as the owner of the object, if he has the right to edit it");
				print_to(self, "^7\"^2object_attach ^3property value^7\" attaches one object to another. Players can only attach their own objects");
				print_to(self, "^7Attachment properties for ^2object_attach^7:");
				print_to(self, "^3get ^7- selects the object you are facing as the object to be attached");
				print_to(self, "^3set value ^7- attaches the previously selected object to the object you are facing, on the specified bone");
				print_to(self, "^3remove ^7- detaches all objects from the object you are facing");
				print_to(self, "^7\"^2object_edit ^3property value^7\" edits the given property of the object. Players can only edit their own objects");
				print_to(self, "^7Object properties for ^2object_edit^7:");
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

			// ---------------- COMMAND: SPAWN OBJECT ----------------
			case "object_spawn":
				if(object_count >= autocvar_g_sandbox_editor_maxobjects)
				{
					print_to(self, strcat("^1SANDBOX - WARNING: ^7Cannot spawn any more objects. Up to ^3", ftos(autocvar_g_sandbox_editor_maxobjects), " ^7objects may exist at a time"));
					return TRUE;
				}
				if(cmd_argc < 3)
				{
					print_to(self, "^1SANDBOX - WARNING: ^7Attempted to spawn an object without specifying a model. Please specify the path to your model file after the 'object_spawn' command");
					return TRUE;
				}
				else if not(fexists(argv(2)))
				{
					print_to(self, "^1SANDBOX - WARNING: ^7Attempted to spawn an object with a non-existent model. Make sure the path to your model file is correct");
					return TRUE;
				}

				e = sandbox_SpawnObject(FALSE);
				setmodel(e, argv(2));

				if(autocvar_g_sandbox_info > 0)
					print(strcat("^3SANDBOX - SERVER: ^7", self.netname, " spawned an object at origin ^3", vtos(e.origin), "\n"));
				return TRUE;

			// ---------------- COMMAND: REMOVE OBJECT ----------------
			case "object_remove":
				e = sandbox_EditObject_Get();
				if(e != world)
				{
					if(autocvar_g_sandbox_info > 0)
						print(strcat("^3SANDBOX - SERVER: ^7", self.netname, " removed an object at origin ^3", vtos(e.origin), "\n"));
					sandbox_RemoveObject(e);
					return TRUE;
				}

				print_to(self, "^1SANDBOX - WARNING: ^7Object could not be removed. Make sure you are facing an object that you have edit rights over");
				return TRUE;

			// ---------------- COMMAND: DUPLICATE OBJECT ----------------
			case "object_duplicate":
				switch(argv(2))
				{
					case "copy":
						// copies customizable properties of the selected object to the clipboard
						e = sandbox_EditObject_Get(); // you can only copy objects you can edit, so this works
						if(e != world)
						{
							if(self.object_clipboard)
								strunzone(self.object_clipboard);
							self.object_clipboard = strzone(sandbox_Storage_Save(e, FALSE));

							print_to(self, "^2SANDBOX - INFO: ^7Object copied to clipboard");
							return TRUE;
						}
						print_to(self, "^1SANDBOX - WARNING: ^7Object could not be copied. Make sure you are facing an object that you have edit rights over");
						return TRUE;

					case "paste":
						// spawns a new object using the properties in the player's clipboard
						if(!self.object_clipboard) // no object in clipboard
						{
							print_to(self, "^1SANDBOX - WARNING: ^7No object in clipboard. You must copy an object before you can paste it");
							return TRUE;
						}
						if(object_count >= autocvar_g_sandbox_editor_maxobjects)
						{
							print_to(self, strcat("^1SANDBOX - WARNING: ^7Cannot spawn any more objects. Up to ^3", ftos(autocvar_g_sandbox_editor_maxobjects), " ^7objects may exist at a time"));
							return TRUE;
						}

						e = sandbox_SpawnObject(FALSE);
						sandbox_Storage_Load(e, self.object_clipboard, FALSE);

						print_to(self, "^2SANDBOX - INFO: ^7Object pasted successfully");
						if(autocvar_g_sandbox_info > 0)
							print(strcat("^3SANDBOX - SERVER: ^7", self.netname, " pasted an object at origin ^3", vtos(e.origin), "\n"));
						return TRUE;
				}
				return TRUE;

			// ---------------- COMMAND: CLAIM OBJECT ----------------
			case "object_claim":
				// if the player can edit an object but is not its owner, this can be used to claim that object
				if(self.crypto_idfp == "")
				{
					print_to(self, "^1SANDBOX - WARNING: ^7You do not have a player UID, and cannot claim objects");
					return TRUE;
				}
				e = sandbox_EditObject_Get();
				if(e != world)
				{
					if(e.crypto_idfp == self.crypto_idfp)
					{
						print_to(self, "^2SANDBOX - INFO: ^7Object is already yours, nothing to claim");
						return TRUE;
					}

					if(e.crypto_idfp)
						strunzone(e.crypto_idfp);
					e.crypto_idfp = self.crypto_idfp;
					print_to(self, "^2SANDBOX - INFO: ^7Object claimed successfully");
				}
				print_to(self, "^1SANDBOX - WARNING: ^7Object could not be claimed. Make sure you are facing an object that you have edit rights over");
				return TRUE;

			// ---------------- COMMAND: ATTACH OBJECT ----------------
			case "object_attach":
				switch(argv(2))
				{
					case "get":
						// select e as the object as meant to be attached
						e = sandbox_EditObject_Get();
						if(e != world)
						{
							self.object_attach = e;
							print_to(self, "^2SANDBOX - INFO: ^7Object selected for attachment");
							return TRUE;
						}
						print_to(self, "^1SANDBOX - WARNING: ^7Object could not be selected for attachment. Make sure you are facing an object that you have edit rights over");
						return TRUE;
					case "set":
						if(self.object_attach == world)
						{
							print_to(self, "^1SANDBOX - WARNING: ^7No object selected for attachment. Please select an object to be attached first.");
							return TRUE;
						}

						// attaches the previously selected object to e
						e = sandbox_EditObject_Get();
						if(e != world)
						{
							sandbox_AttachObject_Set(self.object_attach, e, argv(3));
							self.object_attach = world; // object was attached, no longer keep it scheduled for attachment
							print_to(self, "^2SANDBOX - INFO: ^7Object attached successfully");
							if(autocvar_g_sandbox_info > 1)
								print(strcat("^3SANDBOX - SERVER: ^7", self.netname, " attached objects at origin ^3", vtos(e.origin), "\n"));
							return TRUE;
						}
						print_to(self, "^1SANDBOX - WARNING: ^7Object could not be attached to the parent. Make sure you are facing an object that you have edit rights over");
						return TRUE;
					case "remove":
						// removes e if it was attached
						e = sandbox_EditObject_Get();
						if(e != world)
						{
							sandbox_AttachObject_Remove(e);
							print_to(self, "^2SANDBOX - INFO: ^7Child objects detached successfully");
							if(autocvar_g_sandbox_info > 1)
								print(strcat("^3SANDBOX - SERVER: ^7", self.netname, " detached objects at origin ^3", vtos(e.origin), "\n"));
							return TRUE;
						}
						print_to(self, "^1SANDBOX - WARNING: ^7Child objects could not be detached. Make sure you are facing an object that you have edit rights over");
						return TRUE;
				}
				return TRUE;

			// ---------------- COMMAND: EDIT OBJECT ----------------
			case "object_edit":
				if(!argv(2))
				{
					print_to(self, "^1SANDBOX - WARNING: ^7Too few parameters. You must specify a property to edit");
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
							print_to(self, "^1SANDBOX - WARNING: ^7Invalid object property. For usage information, type 'sandbox help'");
							break;
					}
					if(autocvar_g_sandbox_info > 1)
						print(strcat("^3SANDBOX - SERVER: ^7", self.netname, " edited property ^3", argv(2), " ^7of an object at origin ^3", vtos(e.origin), "\n"));
					return TRUE;
				}

				print_to(self, "^1SANDBOX - WARNING: ^7Object could not be edited. Make sure you are facing an object that you have edit rights over");
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
		return TRUE;

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

float autosave_time;
MUTATOR_HOOKFUNCTION(sandbox_StartFrame)
{
	if(!autocvar_g_sandbox_storage_autosave)
		return FALSE;
	if(time < autocvar_g_sandbox_storage_autosave)
		return FALSE;
	autosave_time = time + autocvar_g_sandbox_storage_autosave;

	sandbox_Storage_DatabaseSave();

	return TRUE;
}

MUTATOR_DEFINITION(sandbox)
{
	MUTATOR_HOOK(SV_ParseClientCommand, sandbox_PlayerCommand, CBC_ORDER_ANY);
	MUTATOR_HOOK(SV_StartFrame, sandbox_StartFrame, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerPreThink, sandbox_PlayerPreThink, CBC_ORDER_ANY);
	MUTATOR_HOOK(ClientDisconnect, sandbox_ClientDisconnect, CBC_ORDER_ANY);

	MUTATOR_ONADD
	{
		if(autocvar_g_sandbox_storage_autoload)
			sandbox_Storage_DatabaseLoad();
	}

	return FALSE;
}

