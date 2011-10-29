const float MAX_STORAGE_ATTACHMENTS = 16;
float object_count;
.string object_clipboard;
.entity object_attach;
.string material;

.float touch_timer;
void sandbox_ObjectFunction_Touch()
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

entity sandbox_ObjectEdit_Get(float permissions)
{
	// returns the traced entity if the player can edit it, and world if not
	// if permissions if FALSE, the object is returned regardless of editing rights
	// attached objects are SOLID_NOT and don't risk getting traced

	makevectors(self.v_angle);
	WarpZone_TraceLine(self.origin + self.view_ofs, self.origin + self.view_ofs + v_forward * autocvar_g_sandbox_editor_distance_edit, MOVE_NORMAL, self);

	if(trace_ent.classname != "object")
		return world; // entity is not an object
	if(!permissions)
		return trace_ent; // don't check permissions, anyone can edit this object
	if(!trace_ent.crypto_idfp)
		return trace_ent; // the player who spawned this object did not have an UID, so anyone can edit it
	if not(trace_ent.crypto_idfp != self.crypto_idfp && autocvar_g_sandbox_editor_free < 2)
		return trace_ent; // object does not belong to the player, and players can only edit their own objects on this server
	return world;
}

void sandbox_ObjectEdit_Scale(entity e, float f)
{
	e.scale = f;
	if(e.scale)
	{
		e.scale = bound(autocvar_g_sandbox_object_scale_min, e.scale, autocvar_g_sandbox_object_scale_max);
		setsize(e, e.mins * e.scale, e.maxs * e.scale); // adapt bounding box size to model size
	}
}

.float old_movetype;
void sandbox_ObjectAttach_Remove(entity e);
void sandbox_ObjectAttach_Set(entity e, entity parent, string s)
{
	// attaches e to parent on string s

	// we can't attach to an attachment, for obvious reasons
	sandbox_ObjectAttach_Remove(e);

	e.old_movetype = e.movetype; // persist physics
	e.movetype = MOVETYPE_FOLLOW;
	e.solid = SOLID_NOT;
	e.takedamage = DAMAGE_NO;

	setattachment(e, parent, s);
	e.owner = parent;
}

void sandbox_ObjectAttach_Remove(entity e)
{
	// detaches any object attached to e

	entity head;
	for(head = world; (head = find(head, classname, "object")); )
	{
		if(head.owner == e)
		{
			vector org;
			head.movetype = head.old_movetype; // restore persisted physics
			head.solid = SOLID_BBOX;
			head.takedamage = DAMAGE_AIM;

			org = gettaginfo(head, 0);
			setattachment(head, world, "");
			head.owner = world;

			// objects change origin and angles when detached, so apply previous position
			setorigin(head, org);
			head.angles = e.angles; // don't allow detached objects to spin or roll
		}
	}
}

entity sandbox_ObjectSpawn(float database)
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
	e.touch = sandbox_ObjectFunction_Touch;

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

void sandbox_ObjectRemove(entity e)
{
	sandbox_ObjectAttach_Remove(e); // detach child objects
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

string port_string[MAX_STORAGE_ATTACHMENTS]; // fteqcc crashes if this isn't defined as a global

string sandbox_ObjectPort_Save(entity e, float database)
{
	// save object properties, and return them as a string
	float i;
	string s;
	entity head;

	for(head = world; (head = find(head, classname, "object")); )
	{
		// the main object needs to be first in the array [0] with attached objects following
		float slot, physics;
		if(head == e) // this is the main object, place it first
		{
			slot = 0;
			physics = head.movetype; // applied physics are normal physics for parents
		}
		else if(head.owner == e) // child object, list them in order
		{
			i += 1; // children start from 1
			slot = i;
			physics = head.old_movetype; // persisted physics are normal physics for children
			gettaginfo(head.owner, head.tag_index); // get the name of the tag our object is attached to, used further below
		}
		else
			continue;

		// ---------------- OBJECT PROPERTY STORAGE: SAVE ----------------
		if(slot)
		{
			// properties stored only for child objects
			if(gettaginfo_name)	port_string[slot] = strcat(port_string[slot], "\"", gettaginfo_name, "\" ");	else	port_string[slot] = strcat(port_string[slot], "- "); // none
		}
		else
		{
			// properties stored only for parent objects
			if(database)
			{
				port_string[slot] = strcat(port_string[slot], sprintf("\"%.9v\"", head.origin), " ");
				port_string[slot] = strcat(port_string[slot], sprintf("\"%.9v\"", head.angles), " ");
			}
		}
		// properties stored for all objects
		port_string[slot] = strcat(port_string[slot], "\"", head.model, "\" ");
		port_string[slot] = strcat(port_string[slot], ftos(head.skin), " ");
		port_string[slot] = strcat(port_string[slot], ftos(head.alpha), " ");
		port_string[slot] = strcat(port_string[slot], sprintf("\"%.9v\"", head.colormod), " ");
		port_string[slot] = strcat(port_string[slot], sprintf("\"%.9v\"", head.glowmod), " ");
		port_string[slot] = strcat(port_string[slot], ftos(head.frame), " ");
		port_string[slot] = strcat(port_string[slot], ftos(head.scale), " ");
		port_string[slot] = strcat(port_string[slot], ftos(physics), " ");
		port_string[slot] = strcat(port_string[slot], ftos(head.damageforcescale), " ");
		if(head.material)	port_string[slot] = strcat(port_string[slot], "\"", head.material, "\" ");	else	port_string[slot] = strcat(port_string[slot], "- "); // none
		if(database)
		{
			// properties stored only for the database
			if(head.crypto_idfp)	port_string[slot] = strcat(port_string[slot], "\"", head.crypto_idfp, "\" ");	else	port_string[slot] = strcat(port_string[slot], "- "); // none
		}
	}

	// now apply the array to a simple string, with the ; symbol separating objects
	for(i = 0; i <= MAX_STORAGE_ATTACHMENTS; ++i)
	{
		if(port_string[i])
			s = strcat(s, port_string[i], "; ");
		port_string[i] = string_null; // fully clear the string
	}

	return s;
}

entity sandbox_ObjectPort_Load(string s, float database)
{
	// load object properties, and spawn a new object with them
	float n, i;
	entity e, parent;

	// separate objects between the ; symbols
	n = tokenizebyseparator(s, "; ");
	for(i = 0; i < n; ++i)
		port_string[i] = argv(i);

	// now separate and apply the properties of each object
	for(i = 0; i < n; ++i)
	{
		float argv_num;
		string tagname;
		argv_num = 0;
		tokenize_console(port_string[i]);
		e = sandbox_ObjectSpawn(database);

		// ---------------- OBJECT PROPERTY STORAGE: LOAD ----------------
		if(i)
		{
			// properties stored only for child objects
			if(argv(argv_num) != "-")	tagname = argv(argv_num);	else tagname = string_null;	++argv_num;
		}
		else
		{
			// properties stored only for parent objects
			if(database)
			{
				setorigin(e, stov(argv(argv_num)));	++argv_num;
				e.angles = stov(argv(argv_num));	++argv_num;
			}
			parent = e; // mark parent objects as such
		}
		// properties stored for all objects
		setmodel(e, argv(argv_num));	++argv_num;
		e.skin = stof(argv(argv_num));	++argv_num;
		e.alpha = stof(argv(argv_num));	++argv_num;
		e.colormod = stov(argv(argv_num));	++argv_num;
		e.glowmod = stov(argv(argv_num));	++argv_num;
		e.frame = stof(argv(argv_num));	++argv_num;
		sandbox_ObjectEdit_Scale(e, stof(argv(argv_num)));	++argv_num;
		e.movetype = e.old_movetype = stof(argv(argv_num));	++argv_num;
		e.damageforcescale = stof(argv(argv_num));	++argv_num;
		if(e.material)	strunzone(e.material);	if(argv(argv_num) != "-")	e.material = strzone(argv(argv_num));	else	e.material = string_null;	++argv_num;
		if(database)
		{
			// properties stored only for the database
			if(e.crypto_idfp)	strunzone(e.crypto_idfp);	if(argv(argv_num) != "-")	e.crypto_idfp = strzone(argv(argv_num));	else	e.crypto_idfp = string_null;	++argv_num;
		}

		// attach last
		if(i)
			sandbox_ObjectAttach_Set(e, parent, tagname);
	}

	for(i = 0; i <= MAX_STORAGE_ATTACHMENTS; ++i)
		port_string[i] = string_null; // fully clear the string

	return e;
}

void sandbox_Database_Save()
{
	// saves all objects to the database file
	entity head;
	string file_name;
	float file_get;

	file_name = strcat("sandbox/storage_", autocvar_g_sandbox_storage_name, "_", GetMapname(), ".txt");
	file_get = fopen(file_name, FILE_WRITE);
	fputs(file_get, strcat("// sandbox storage \"", autocvar_g_sandbox_storage_name, "\" for map \"", GetMapname(), "\" last updated ", strftime(TRUE, "%d-%m-%Y %H:%M:%S")));
	fputs(file_get, strcat(" containing ", ftos(object_count), " objects\n"));

	for(head = world; (head = find(head, classname, "object")); )
	{
		// attached objects are persisted separately, ignore them here
		if(head.owner != world)
			continue;

		// use a line of text for each object, listing all properties
		fputs(file_get, strcat(sandbox_ObjectPort_Save(head, TRUE), "\n"));
	}
	fclose(file_get);
}

void sandbox_Database_Load()
{
	// loads all objects from the database file
	string file_read, file_name;
	float file_get, i;

	file_name = strcat("sandbox/storage_", autocvar_g_sandbox_storage_name, "_", GetMapname(), ".txt");
	file_get = fopen(file_name, FILE_READ);
	if(file_get < 0)
	{
		if(autocvar_g_sandbox_info > 0)
			print(strcat("^3SANDBOX - SERVER: ^7could not find storage file ^3", file_name, "^7, no objects were loaded\n"));
	}
	else
	{
		for(;;)
		{
			file_read = fgets(file_get);
			if(!file_read)
				break;
			if(substring(file_read, 0, 2) == "//")
				continue;
			if(substring(file_read, 0, 1) == "#")
				continue;

			entity e;
			e = sandbox_ObjectPort_Load(file_read, TRUE);

			if(e.material)
			{
				// since objects are being loaded for the first time, precache material sounds for each
				for (i = 1; i <= 5; i++) // 5 sounds in total
					precache_sound(strcat("object/impact_", e.material, "_", ftos(i), ".ogg"));
			}
		}
		if(autocvar_g_sandbox_info > 0)
			print(strcat("^3SANDBOX - SERVER: ^7successfully loaded storage file ^3", file_name, "\n"));
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
				print_to(self, "^7\"^2object_claim^7\" sets the player as the owner of the object, if he has the right to edit it");
				print_to(self, "^7\"^2object_info ^3value^7\" shows public information about the object. 'mesh' shows model information");
				print_to(self, "^7The ^1drag object ^7key can be used to grab and carry objects. Players can only grab their own objects");
				return TRUE;

			// ---------------- COMMAND: OBJECT, SPAWN ----------------
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

				e = sandbox_ObjectSpawn(FALSE);
				setmodel(e, argv(2));

				if(autocvar_g_sandbox_info > 0)
					print(strcat("^3SANDBOX - SERVER: ^7", self.netname, " spawned an object at origin ^3", vtos(e.origin), "\n"));
				return TRUE;

			// ---------------- COMMAND: OBJECT, REMOVE ----------------
			case "object_remove":
				e = sandbox_ObjectEdit_Get(TRUE);
				if(e != world)
				{
					if(autocvar_g_sandbox_info > 0)
						print(strcat("^3SANDBOX - SERVER: ^7", self.netname, " removed an object at origin ^3", vtos(e.origin), "\n"));
					sandbox_ObjectRemove(e);
					return TRUE;
				}

				print_to(self, "^1SANDBOX - WARNING: ^7Object could not be removed. Make sure you are facing an object that you have edit rights over");
				return TRUE;

			// ---------------- COMMAND: OBJECT, DUPLICATE ----------------
			case "object_duplicate":
				switch(argv(2))
				{
					case "copy":
						// copies customizable properties of the selected object to the clipboard
						e = sandbox_ObjectEdit_Get(autocvar_g_sandbox_editor_free); // can we copy objects we can't edit?
						if(e != world)
						{
							if(self.object_clipboard)
								strunzone(self.object_clipboard);
							self.object_clipboard = strzone(sandbox_ObjectPort_Save(e, FALSE));

							print_to(self, "^2SANDBOX - INFO: ^7Object copied to clipboard");
							return TRUE;
						}
						print_to(self, "^1SANDBOX - WARNING: ^7Object could not be copied. Make sure you are facing an object that you have copy rights over");
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

						e = sandbox_ObjectPort_Load(self.object_clipboard, FALSE);

						print_to(self, "^2SANDBOX - INFO: ^7Object pasted successfully");
						if(autocvar_g_sandbox_info > 0)
							print(strcat("^3SANDBOX - SERVER: ^7", self.netname, " pasted an object at origin ^3", vtos(e.origin), "\n"));
						return TRUE;
				}
				return TRUE;

			// ---------------- COMMAND: OBJECT, ATTACH ----------------
			case "object_attach":
				switch(argv(2))
				{
					case "get":
						// select e as the object as meant to be attached
						e = sandbox_ObjectEdit_Get(TRUE);
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
						e = sandbox_ObjectEdit_Get(TRUE);
						if(e != world)
						{
							sandbox_ObjectAttach_Set(self.object_attach, e, argv(3));
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
						e = sandbox_ObjectEdit_Get(TRUE);
						if(e != world)
						{
							sandbox_ObjectAttach_Remove(e);
							print_to(self, "^2SANDBOX - INFO: ^7Child objects detached successfully");
							if(autocvar_g_sandbox_info > 1)
								print(strcat("^3SANDBOX - SERVER: ^7", self.netname, " detached objects at origin ^3", vtos(e.origin), "\n"));
							return TRUE;
						}
						print_to(self, "^1SANDBOX - WARNING: ^7Child objects could not be detached. Make sure you are facing an object that you have edit rights over");
						return TRUE;
				}
				return TRUE;

			// ---------------- COMMAND: OBJECT, EDIT ----------------
			case "object_edit":
				if(!argv(2))
				{
					print_to(self, "^1SANDBOX - WARNING: ^7Too few parameters. You must specify a property to edit");
					return TRUE;
				}

				e = sandbox_ObjectEdit_Get(TRUE);
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
							sandbox_ObjectEdit_Scale(e, stof(argv(3)));
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

			// ---------------- COMMAND: OBJECT, CLAIM ----------------
			case "object_claim":
				// if the player can edit an object but is not its owner, this can be used to claim that object
				if(self.crypto_idfp == "")
				{
					print_to(self, "^1SANDBOX - WARNING: ^7You do not have a player UID, and cannot claim objects");
					return TRUE;
				}
				e = sandbox_ObjectEdit_Get(TRUE);
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

			// ---------------- COMMAND: OBJECT, INFO ----------------
			case "object_info":
				// prints public information about the object to the player
				e = sandbox_ObjectEdit_Get(FALSE);
				if(e != world)
				{
					switch(argv(2))
					{
						case "mesh":
							string tags;
							for(i = 1; gettaginfo(e, i); i++)
								tags = strcat(tags, "^5", gettaginfo_name, "^7, ");
							print_to(self, strcat("^2SANDBOX - INFO: ^7Object mesh is ^3", e.model, "^7 at animation frame ^3", ftos(e.frame), " ^7containing the following tags: ", tags));
							return TRUE;
					}
				}
				print_to(self, "^1SANDBOX - WARNING: ^7No information could not be found. Make sure you are facing an object");
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

	e = sandbox_ObjectEdit_Get(TRUE);
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
	if(time < autosave_time)
		return FALSE;
	autosave_time = time + autocvar_g_sandbox_storage_autosave;

	sandbox_Database_Save();

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
		autosave_time = time + autocvar_g_sandbox_storage_autosave; // don't save the first server frame
		if(autocvar_g_sandbox_storage_autoload)
			sandbox_Database_Load();
	}

	return FALSE;
}

