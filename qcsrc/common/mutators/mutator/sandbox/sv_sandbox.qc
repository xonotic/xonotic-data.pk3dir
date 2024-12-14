#include "sv_sandbox.qh"

#include <server/intermission.qh>

string autocvar_g_sandbox;
int autocvar_g_sandbox_info;
bool autocvar_g_sandbox_readonly;
string autocvar_g_sandbox_storage_name;
float autocvar_g_sandbox_storage_autosave;
bool autocvar_g_sandbox_storage_autoload;
float autocvar_g_sandbox_editor_flood;
int autocvar_g_sandbox_editor_maxobjects;
int autocvar_g_sandbox_editor_free;
float autocvar_g_sandbox_editor_distance_spawn;
float autocvar_g_sandbox_editor_distance_edit;
float autocvar_g_sandbox_object_scale_min;
float autocvar_g_sandbox_object_scale_max;
float autocvar_g_sandbox_object_material_velocity_min;
float autocvar_g_sandbox_object_material_velocity_factor;

IntrusiveList g_sandbox_objects;
float autosave_time;
void sandbox_Database_Load();

REGISTER_MUTATOR(sandbox, expr_evaluate(autocvar_g_sandbox))
{
	MUTATOR_ONADD
	{
		g_sandbox_objects = IL_NEW();
		autosave_time = time + autocvar_g_sandbox_storage_autosave; // don't save the first server frame
		if(autocvar_g_sandbox_storage_autoload)
			sandbox_Database_Load();
	}
}

const float MAX_STORAGE_ATTACHMENTS = 16;
float object_count;
.float object_flood;
.entity object_attach;
.string material;

.float touch_timer;
void sandbox_ObjectFunction_Touch(entity this, entity toucher)
{
	// apply material impact effects

	if(!this.material)
		return;
	if(this.touch_timer > time)
		return; // don't execute each frame
	this.touch_timer = time + 0.1;

	// make particle count and sound volume depend on impact speed
	float intensity;
	intensity = vlen(this.velocity) + vlen(toucher.velocity);
	if(intensity) // avoid divisions by 0
		intensity /= 2; // average the two velocities
	if (!(intensity >= autocvar_g_sandbox_object_material_velocity_min))
		return; // impact not strong enough to do anything
	// now offset intensity and apply it to the effects
	intensity -= autocvar_g_sandbox_object_material_velocity_min; // start from minimum velocity, not actual velocity
	intensity = bound(0, intensity * autocvar_g_sandbox_object_material_velocity_factor, 1);

	_sound(this, CH_TRIGGER, strcat("object/impact_", this.material, "_", ftos(ceil(random() * 5)) , ".wav"), VOL_BASE * intensity, ATTEN_NORM);
	Send_Effect_(strcat("impact_", this.material), this.origin, '0 0 0', ceil(intensity * 10)); // allow a count from 1 to 10
}

void sandbox_ObjectFunction_Think(entity this)
{
	// decide if and how this object can be grabbed
	if(autocvar_g_sandbox_readonly || MUTATOR_CALLHOOK(Sandbox_DragAllowed, this))
		this.grab = 0; // no grabbing
	else if(autocvar_g_sandbox_editor_free < 2 && this.crypto_idfp)
		this.grab = 1; // owner only
	else
		this.grab = 3; // anyone

	// Object owner is stored via player UID, but we also need the owner as an entity (if the player is available on the server).
	// Therefore, scan for all players, and update the owner as long as the player is present. We must always do this,
	// since if the owning player disconnects, the object's owner should also be reset.

	// bots can't have objects
	FOREACH_CLIENT(IS_PLAYER(it) && IS_REAL_CLIENT(it), {
		if(this.crypto_idfp == it.crypto_idfp)
		{
			this.realowner = it;
			break;
		}
		this.realowner = NULL;
	});

	this.nextthink = time;

	CSQCMODEL_AUTOUPDATE(this);
}

.float old_solid, old_movetype;
entity sandbox_ObjectEdit_Get(entity this, float permissions)
{
	// Returns the traced entity if the player can edit it, and NULL if not.
	// If permissions if false, the object is returned regardless of editing rights.
	// Attached objects are SOLID_NOT and do not get traced.

	crosshair_trace_plusvisibletriggers(this);
	if(vdist(this.origin - trace_ent.origin, >, autocvar_g_sandbox_editor_distance_edit))
		return NULL; // out of trace range
	if(trace_ent.classname != "object")
		return NULL; // entity is not an object
	if(!permissions)
		return trace_ent; // don't check permissions, anyone can edit this object
	if(trace_ent.crypto_idfp == "")
		return trace_ent; // the player who spawned this object did not have an UID, so anyone can edit it
	if (!(trace_ent.realowner != this && autocvar_g_sandbox_editor_free < 2))
		return trace_ent; // object does not belong to the player, and players can only edit their own objects on this server
	return NULL;
}

void sandbox_ObjectEdit_Scale(entity e, float f)
{
	e.scale = f;
	if(e.scale)
	{
		e.scale = bound(autocvar_g_sandbox_object_scale_min, e.scale, autocvar_g_sandbox_object_scale_max);
		_setmodel(e, e.model); // reset mins and maxs based on mesh
		// apply object scaling and prevent any float precision issues like #2742
		setsize(e, RoundPerfectVector(e.mins * e.scale), RoundPerfectVector(e.maxs * e.scale));
	}
}

void sandbox_ObjectAttach_Remove(entity e);
void sandbox_ObjectAttach_Set(entity e, entity parent, string s)
{
	// attaches e to parent on string s

	// we can't attach to an attachment, for obvious reasons
	sandbox_ObjectAttach_Remove(e);

	e.old_solid = e.solid; // persist solidity
	e.old_movetype = e.move_movetype; // persist physics
	set_movetype(e, MOVETYPE_FOLLOW);
	e.solid = SOLID_NOT;
	e.takedamage = DAMAGE_NO;

	setattachment(e, parent, s);
	e.owner = parent;
}

void sandbox_ObjectAttach_Remove(entity e)
{
	// detaches any object attached to e

	IL_EACH(g_sandbox_objects, it.owner == e,
	{
		vector org = gettaginfo(it, 0);
		setattachment(it, NULL, "");
		it.owner = NULL;

		// objects change origin and angles when detached, so apply previous position
		setorigin(it, org);
		it.angles = e.angles; // don't allow detached objects to spin or roll

		it.solid = it.old_solid; // restore persisted solidity
		set_movetype(it, it.old_movetype); // restore persisted physics
		it.takedamage = DAMAGE_AIM;
	});
}

entity sandbox_ObjectSpawn(entity this, float database)
{
	// spawn a new object with default properties

	entity e = new(object);
	IL_PUSH(g_sandbox_objects, e);
	e.takedamage = DAMAGE_AIM;
	e.damageforcescale = 1;
	e.solid = SOLID_BBOX; // SOLID_BSP would be best, but can lag the server badly
	set_movetype(e, MOVETYPE_TOSS);
	e.frame = 0;
	e.skin = 0;
	e.material = string_null;
	settouch(e, sandbox_ObjectFunction_Touch);
	setthink(e, sandbox_ObjectFunction_Think);
	e.nextthink = time;
	//e.effects |= EF_SELECTABLE; // don't do this all the time, maybe just when editing objects?

	if(!database)
	{
		// set the object's owner via player UID
		// if the player does not have an UID, the owner cannot be stored and their objects may be edited by anyone
		if(this.crypto_idfp != "")
			e.crypto_idfp = strzone(this.crypto_idfp);
		else
			print_to(this, "^1SANDBOX - WARNING: ^7You spawned an object, but lack a player UID. ^1Your objects are not secured and can be edited by any player!");

		// set public object information
		e.netname = strzone(this.netname); // name of the owner
		e.message = strzone(strftime(true, "%d-%m-%Y %H:%M:%S")); // creation time
		e.message2 = strzone(strftime(true, "%d-%m-%Y %H:%M:%S")); // last editing time

		// set origin and direction based on player position and view angle
		makevectors(this.v_angle);
		WarpZone_TraceLine(this.origin + this.view_ofs, this.origin + this.view_ofs + v_forward * autocvar_g_sandbox_editor_distance_spawn, MOVE_NORMAL, this);
		setorigin(e, trace_endpos);
		e.angles_y = this.v_angle.y;
	}

	CSQCMODEL_AUTOINIT(e);

	object_count += 1;
	return e;
}

void sandbox_ObjectRemove(entity e)
{
	sandbox_ObjectAttach_Remove(e); // detach child objects

	// if the object being removed has been selected for attachment by a player, unset it
	FOREACH_CLIENT(IS_PLAYER(it) && IS_REAL_CLIENT(it) && it.object_attach == e, { it.object_attach = NULL; });

	strfree(e.material);
	strfree(e.crypto_idfp);
	strfree(e.netname);
	strfree(e.message);
	strfree(e.message2);
	delete(e);
	e = NULL;

	object_count -= 1;
}

string port_string[MAX_STORAGE_ATTACHMENTS]; // fteqcc crashes if this isn't defined as a global

string sandbox_ObjectPort_Save(entity e, bool database)
{
	// save object properties, and return them as a string
	int o = 0;

	// order doesn't really matter, as we're writing the file fresh
	IL_EACH(g_sandbox_objects, it == e || it.owner == e, LAMBDA(
		// the main object needs to be first in the array [0] with attached objects following
		int slot, physics, solidity;
		if(it == e) // this is the main object, place it first
		{
			slot = 0;
			solidity = it.solid; // applied solidity is normal solidity for children
			physics = it.move_movetype; // applied physics are normal physics for parents
		}
		else if(it.owner == e) // child object, list them in order
		{
			o += 1; // children start from 1
			slot = o;
			solidity = it.old_solid; // persisted solidity is normal solidity for children
			physics = it.old_movetype; // persisted physics are normal physics for children
			gettaginfo(it.owner, it.tag_index); // get the name of the tag our object is attached to, used further below
		}
		else
			continue;

		// ---------------- OBJECT PROPERTY STORAGE: SAVE ----------------
		if(slot)
		{
			// properties stored only for child objects
			if(gettaginfo_name)
				port_string[slot] = strcat(port_string[slot], "\"", gettaginfo_name, "\" ");
			else
				port_string[slot] = strcat(port_string[slot], "\"\" "); // none
		}
		else
		{
			// properties stored only for parent objects
			if(database)
			{
				port_string[slot] = strcat(port_string[slot], sprintf("\"%.9v\"", it.origin), " ");
				port_string[slot] = strcat(port_string[slot], sprintf("\"%.9v\"", it.angles), " ");
			}
		}
		// properties stored for all objects
		port_string[slot] = strcat(port_string[slot], "\"", it.model, "\" ");
		port_string[slot] = strcat(port_string[slot], ftos(it.skin), " ");
		port_string[slot] = strcat(port_string[slot], ftos(it.alpha), " ");
		port_string[slot] = strcat(port_string[slot], sprintf("\"%.9v\"", it.colormod), " ");
		port_string[slot] = strcat(port_string[slot], sprintf("\"%.9v\"", it.glowmod), " ");
		port_string[slot] = strcat(port_string[slot], ftos(it.frame), " ");
		port_string[slot] = strcat(port_string[slot], ftos(it.scale), " ");
		port_string[slot] = strcat(port_string[slot], ftos(solidity), " ");
		port_string[slot] = strcat(port_string[slot], ftos(physics), " ");
		port_string[slot] = strcat(port_string[slot], ftos(it.damageforcescale), " ");
		if(it.material)
			port_string[slot] = strcat(port_string[slot], "\"", it.material, "\" ");
		else
			port_string[slot] = strcat(port_string[slot], "\"\" "); // none
		if(database)
		{
			// properties stored only for the database
			if(it.crypto_idfp)
				port_string[slot] = strcat(port_string[slot], "\"", it.crypto_idfp, "\" ");
			else
				port_string[slot] = strcat(port_string[slot], "\"\" "); // none
			port_string[slot] = strcat(port_string[slot], "\"", e.netname, "\" ");
			port_string[slot] = strcat(port_string[slot], "\"", e.message, "\" ");
			port_string[slot] = strcat(port_string[slot], "\"", e.message2, "\" ");
		}
	));

	// now apply the array to a simple string, with the ; symbol separating objects
	string s = "";
	for(int j = 0; j <= MAX_STORAGE_ATTACHMENTS; ++j)
	{
		if(port_string[j])
			s = strcat(s, port_string[j], "; ");
		port_string[j] = string_null; // fully clear the string
	}

	return s;
}

entity sandbox_ObjectPort_Load(entity this, string s, float database)
{
	// load object properties, and spawn a new object with them
	int n, i;
	entity e = NULL, parent = NULL;
	string arg = string_null;

	// separate objects between the ; symbols
	n = tokenizebyseparator(s, "; ");
	for(i = 0; i < n; ++i)
		port_string[i] = argv(i);

	// now separate and apply the properties of each object
	for(i = 0; i < n; ++i)
	{
		#define SANDBOX_GETARG arg = argv(++argv_num);
		int argv_num = -1; // starts at -1 so I don't need postincrement

		string tagname = string_null;
		tokenize_console(port_string[i]);
		e = sandbox_ObjectSpawn(this, database);

		// ---------------- OBJECT PROPERTY STORAGE: LOAD ----------------
		if(i)
		{
			// properties stored only for child objects
			SANDBOX_GETARG; tagname = (arg != "") ? arg : string_null;
		}
		else
		{
			// properties stored only for parent objects
			if(database)
			{
				SANDBOX_GETARG; setorigin(e, stov(arg));
				SANDBOX_GETARG; e.angles = stov(arg);
			}
			parent = e; // mark parent objects as such
		}
		// properties stored for all objects
		SANDBOX_GETARG; precache_model(arg); _setmodel(e, arg);
		SANDBOX_GETARG; e.skin = stof(arg);
		SANDBOX_GETARG; e.alpha = stof(arg);
		SANDBOX_GETARG; e.colormod = stov(arg);
		SANDBOX_GETARG; e.glowmod = stov(arg);
		SANDBOX_GETARG; e.frame = stof(arg);
		SANDBOX_GETARG; sandbox_ObjectEdit_Scale(e, stof(arg));
		SANDBOX_GETARG; e.solid = e.old_solid = stof(arg);
		SANDBOX_GETARG; e.old_movetype = stof(arg);
		set_movetype(e, e.old_movetype);
		SANDBOX_GETARG; e.damageforcescale = stof(arg);
		strfree(e.material);
		SANDBOX_GETARG; e.material = (arg != "") ? strzone(arg) : string_null;
		if(database)
		{
			// properties stored only for the database
			strfree(e.crypto_idfp);
			SANDBOX_GETARG; e.crypto_idfp = (arg != "") ? strzone(arg) : string_null;
			SANDBOX_GETARG; strcpy(e.netname, arg);
			SANDBOX_GETARG; strcpy(e.message, arg);
			SANDBOX_GETARG; strcpy(e.message2, arg);
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
	if(MUTATOR_CALLHOOK(Sandbox_SaveAllowed))
		return;

	// saves all objects to the database file
	string file_name;
	float file_get;

	file_name = strcat("sandbox/storage_", autocvar_g_sandbox_storage_name, "_", GetMapname(), ".txt");
	file_get = fopen(file_name, FILE_WRITE);
	fputs(file_get, strcat("// sandbox storage \"", autocvar_g_sandbox_storage_name, "\" for map \"", GetMapname(), "\" last updated ", strftime(true, "%d-%m-%Y %H:%M:%S")));
	fputs(file_get, strcat(" containing ", ftos(object_count), " objects\n"));

	IL_EACH(g_sandbox_objects, !it.owner, // attached objects are persisted separately, ignore them here
	{
		// use a line of text for each object, listing all properties
		fputs(file_get, strcat(sandbox_ObjectPort_Save(it, true), "\n"));
	});
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
			LOG_INFO("^3SANDBOX - SERVER: ^7could not find storage file ^3", file_name, "^7, no objects were loaded");
		return;
	}
	else
	{
		for (;;)
		{
			file_read = fgets(file_get);
			if(file_read == "")
				break;
			if(substring(file_read, 0, 2) == "//")
				continue;
			if(substring(file_read, 0, 1) == "#")
				continue;

			entity e;
			e = sandbox_ObjectPort_Load(NULL, file_read, true);

			if(e.material)
			{
				// since objects are being loaded for the first time, precache material sounds for each
				for (i = 1; i <= 5; ++i) // 5 sounds in total
					precache_sound(strcat("object/impact_", e.material, "_", ftos(i), ".wav"));
			}
		}
		if(autocvar_g_sandbox_info > 0)
			LOG_INFO("^3SANDBOX - SERVER: ^7successfully loaded storage file ^3", file_name);
	}
	fclose(file_get);
}

MUTATOR_HOOKFUNCTION(sandbox, SV_ParseClientCommand)
{
	if(MUTATOR_RETURNVALUE) // command was already handled?
		return;

	entity player = M_ARGV(0, entity);
	string cmd_name = M_ARGV(1, string);
	int cmd_argc = M_ARGV(2, int);

	if(cmd_name == "g_sandbox")
	{
		if(autocvar_g_sandbox_readonly || MUTATOR_CALLHOOK(Sandbox_EditAllowed, player))
		{
			print_to(player, "^2SANDBOX - INFO: ^7Sandbox mode is active, but in read-only mode. Sandbox commands cannot be used");
			return true;
		}
		if(cmd_argc < 2)
		{
			print_to(player, "^2SANDBOX - INFO: ^7Sandbox mode is active. For usage information, type 'sandbox help'");
			return true;
		}

		switch(argv(1))
		{
			entity e;
			int j;
			string s;

			// ---------------- COMMAND: HELP ----------------
			case "help":
				print_to(player, "You can use the following sandbox commands:");
				print_to(player, "^7\"^2object_spawn ^3models/foo/bar.md3^7\" spawns a new object in front of the player, and gives it the specified model");
				print_to(player, "^7\"^2object_remove^7\" removes the object the player is looking at. Players can only remove their own objects");
				print_to(player, "^7\"^2object_duplicate ^3value^7\" duplicates the object, if the player has copying rights over the original");
				print_to(player, "^3copy value ^7- copies the properties of the object to the specified client cvar");
				print_to(player, "^3paste value ^7- spawns an object with the given properties. Properties or cvars must be specified as follows; eg1: \"0 1 2 ...\", eg2: \"$cl_cvar\"");
				print_to(player, "^7\"^2object_attach ^3property value^7\" attaches one object to another. Players can only attach their own objects");
				print_to(player, "^3get ^7- selects the object you are facing as the object to be attached");
				print_to(player, "^3set value ^7- attaches the previously selected object to the object you are facing, on the specified bone");
				print_to(player, "^3remove ^7- detaches all objects from the object you are facing");
				print_to(player, "^7\"^2object_edit ^3property value^7\" edits the given property of the object. Players can only edit their own objects");
				print_to(player, "^3skin value ^7- changes the skin of the object");
				print_to(player, "^3alpha value ^7- sets object transparency");
				print_to(player, "^3colormod \"value_x value_y value_z\" ^7- main object color");
				print_to(player, "^3glowmod \"value_x value_y value_z\" ^7- glow object color");
				print_to(player, "^3frame value ^7- object animation frame, for self-animated models");
				print_to(player, "^3scale value ^7- changes object scale. 0.5 is half size and 2 is double size");
				print_to(player, "^3solidity value ^7- object collisions, 0 = non-solid, 1 = solid");
				print_to(player, "^3physics value ^7- object physics, 0 = static, 1 = movable, 2 = physical");
				print_to(player, "^3force value ^7- amount of force applied to objects that are shot");
				print_to(player, "^3material value ^7- sets the material of the object. Default materials are: metal, stone, wood, flesh");
				print_to(player, "^7\"^2object_claim^7\" sets the player as the owner of the object, if they have the right to edit it");
				print_to(player, "^7\"^2object_info ^3value^7\" shows public information about the object");
				print_to(player, "^3object ^7- prints general information about the object, such as owner and creation / editing date");
				print_to(player, "^3mesh ^7- prints information about the object's mesh, including skeletal bones");
				print_to(player, "^3attachments ^7- prints information about the object's attachments");
				print_to(player, "^7The ^1drag object ^7key can be used to grab and carry objects. Players can only grab their own objects");
				return true;

			// ---------------- COMMAND: OBJECT, SPAWN ----------------
			case "object_spawn":
				if(time < player.object_flood)
				{
					print_to(player, strcat("^1SANDBOX - WARNING: ^7Flood protection active. Please wait ^3", ftos(player.object_flood - time), " ^7seconds beofore spawning another object"));
					return true;
				}
				player.object_flood = time + autocvar_g_sandbox_editor_flood;
				if(object_count >= autocvar_g_sandbox_editor_maxobjects)
				{
					print_to(player, strcat("^1SANDBOX - WARNING: ^7Cannot spawn any more objects. Up to ^3", ftos(autocvar_g_sandbox_editor_maxobjects), " ^7objects may exist at a time"));
					return true;
				}
				if(cmd_argc < 3)
				{
					print_to(player, "^1SANDBOX - WARNING: ^7Attempted to spawn an object without specifying a model. Please specify the path to your model file after the 'object_spawn' command");
					return true;
				}
				if (!(fexists(argv(2))))
				{
					print_to(player, "^1SANDBOX - WARNING: ^7Attempted to spawn an object with a non-existent model. Make sure the path to your model file is correct");
					return true;
				}

				e = sandbox_ObjectSpawn(player, false);
				precache_model(argv(2));
				_setmodel(e, argv(2));

				if(autocvar_g_sandbox_info > 0)
					LOG_INFO("^3SANDBOX - SERVER: ^7", player.netname, " spawned an object at origin ^3", vtos(e.origin));
				return true;

			// ---------------- COMMAND: OBJECT, REMOVE ----------------
			case "object_remove":
				e = sandbox_ObjectEdit_Get(player, true);
				if(e != NULL)
				{
					if(autocvar_g_sandbox_info > 0)
						LOG_INFO("^3SANDBOX - SERVER: ^7", player.netname, " removed an object at origin ^3", vtos(e.origin));
					sandbox_ObjectRemove(e);
					return true;
				}

				print_to(player, "^1SANDBOX - WARNING: ^7Object could not be removed. Make sure you are facing an object that you have edit rights over");
				return true;

			// ---------------- COMMAND: OBJECT, DUPLICATE ----------------
			case "object_duplicate":
				switch(argv(2))
				{
					case "copy":
						// copies customizable properties of the selected object to the clipboard cvar
						e = sandbox_ObjectEdit_Get(player, autocvar_g_sandbox_editor_free); // can we copy objects we can't edit?
						if(e != NULL)
						{
							s = sandbox_ObjectPort_Save(e, false);
							s = strreplace("\"", "\\\"", s);
							stuffcmd(player, strcat("set ", argv(3), " \"", s, "\""));

							print_to(player, "^2SANDBOX - INFO: ^7Object copied to clipboard");
							return true;
						}
						print_to(player, "^1SANDBOX - WARNING: ^7Object could not be copied. Make sure you are facing an object that you have copy rights over");
						return true;

					case "paste":
						// spawns a new object using the properties in the player's clipboard cvar
						if(time < player.object_flood)
						{
							print_to(player, strcat("^1SANDBOX - WARNING: ^7Flood protection active. Please wait ^3", ftos(player.object_flood - time), " ^7seconds beofore spawning another object"));
							return true;
						}
						player.object_flood = time + autocvar_g_sandbox_editor_flood;
						if(argv(3) == "") // no object in clipboard
						{
							print_to(player, "^1SANDBOX - WARNING: ^7No object in clipboard. You must copy an object before you can paste it");
							return true;
						}
						if(object_count >= autocvar_g_sandbox_editor_maxobjects)
						{
							print_to(player, strcat("^1SANDBOX - WARNING: ^7Cannot spawn any more objects. Up to ^3", ftos(autocvar_g_sandbox_editor_maxobjects), " ^7objects may exist at a time"));
							return true;
						}
						e = sandbox_ObjectPort_Load(player, argv(3), false);

						print_to(player, "^2SANDBOX - INFO: ^7Object pasted successfully");
						if(autocvar_g_sandbox_info > 0)
							LOG_INFO("^3SANDBOX - SERVER: ^7", player.netname, " pasted an object at origin ^3", vtos(e.origin));
						return true;
				}
				return true;

			// ---------------- COMMAND: OBJECT, ATTACH ----------------
			case "object_attach":
				switch(argv(2))
				{
					case "get":
						// select e as the object as meant to be attached
						e = sandbox_ObjectEdit_Get(player, true);
						if(e != NULL)
						{
							player.object_attach = e;
							print_to(player, "^2SANDBOX - INFO: ^7Object selected for attachment");
							return true;
						}
						print_to(player, "^1SANDBOX - WARNING: ^7Object could not be selected for attachment. Make sure you are facing an object that you have edit rights over");
						return true;
					case "set":
						if(player.object_attach == NULL)
						{
							print_to(player, "^1SANDBOX - WARNING: ^7No object selected for attachment. Please select an object to be attached first.");
							return true;
						}

						// attaches the previously selected object to e
						e = sandbox_ObjectEdit_Get(player, true);
						if(e != NULL)
						{
							sandbox_ObjectAttach_Set(player.object_attach, e, argv(3));
							player.object_attach = NULL; // object was attached, no longer keep it scheduled for attachment
							print_to(player, "^2SANDBOX - INFO: ^7Object attached successfully");
							if(autocvar_g_sandbox_info > 1)
								LOG_INFO("^3SANDBOX - SERVER: ^7", player.netname, " attached objects at origin ^3", vtos(e.origin));
							return true;
						}
						print_to(player, "^1SANDBOX - WARNING: ^7Object could not be attached to the parent. Make sure you are facing an object that you have edit rights over");
						return true;
					case "remove":
						// removes e if it was attached
						e = sandbox_ObjectEdit_Get(player, true);
						if(e != NULL)
						{
							sandbox_ObjectAttach_Remove(e);
							print_to(player, "^2SANDBOX - INFO: ^7Child objects detached successfully");
							if(autocvar_g_sandbox_info > 1)
								LOG_INFO("^3SANDBOX - SERVER: ^7", player.netname, " detached objects at origin ^3", vtos(e.origin));
							return true;
						}
						print_to(player, "^1SANDBOX - WARNING: ^7Child objects could not be detached. Make sure you are facing an object that you have edit rights over");
						return true;
				}
				return true;

			// ---------------- COMMAND: OBJECT, EDIT ----------------
			case "object_edit":
				if(argv(2) == "")
				{
					print_to(player, "^1SANDBOX - WARNING: ^7Too few parameters. You must specify a property to edit");
					return true;
				}

				e = sandbox_ObjectEdit_Get(player, true);
				if(e != NULL)
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
						case "solidity":
							switch(argv(3))
							{
								case "0": // non-solid
									e.solid = SOLID_TRIGGER;
									break;
								case "1": // solid
									e.solid = SOLID_BBOX;
									break;
								default:
									break;
							}
						case "physics":
							switch(argv(3))
							{
								case "0": // static
									set_movetype(e, MOVETYPE_NONE);
									break;
								case "1": // movable
									set_movetype(e, MOVETYPE_TOSS);
									break;
								case "2": // physical
									set_movetype(e, MOVETYPE_PHYSICS);
									break;
								default:
									break;
							}
							break;
						case "force":
							e.damageforcescale = stof(argv(3));
							break;
						case "material":
							strfree(e.material);
							if(argv(3))
							{
								for (j = 1; j <= 5; ++j) // precache material sounds, 5 in total
									precache_sound(strcat("object/impact_", argv(3), "_", ftos(j), ".wav"));
								e.material = strzone(argv(3));
							}
							else
								e.material = string_null; // no material
							break;
						default:
							print_to(player, "^1SANDBOX - WARNING: ^7Invalid object property. For usage information, type 'sandbox help'");
							return true;
					}

					// update last editing time
					strcpy(e.message2, strftime(true, "%d-%m-%Y %H:%M:%S"));

					if(autocvar_g_sandbox_info > 1)
						LOG_INFO("^3SANDBOX - SERVER: ^7", player.netname, " edited property ^3", argv(2), " ^7of an object at origin ^3", vtos(e.origin));
					return true;
				}

				print_to(player, "^1SANDBOX - WARNING: ^7Object could not be edited. Make sure you are facing an object that you have edit rights over");
				return true;

			// ---------------- COMMAND: OBJECT, CLAIM ----------------
			case "object_claim":
				// if the player can edit an object but is not its owner, this can be used to claim that object
				if(player.crypto_idfp == "")
				{
					print_to(player, "^1SANDBOX - WARNING: ^7You do not have a player UID, and cannot claim objects");
					return true;
				}
				e = sandbox_ObjectEdit_Get(player, true);
				if(e != NULL)
				{
					// update the owner's name
					// Do this before checking if you're already the owner and skipping if such, so we
					// also update the player's nickname if they changed it (but has the same player UID)
					if(e.netname != player.netname)
					{
						strcpy(e.netname, player.netname);
						print_to(player, "^2SANDBOX - INFO: ^7Object owner name updated");
					}

					if(e.crypto_idfp == player.crypto_idfp)
					{
						print_to(player, "^2SANDBOX - INFO: ^7Object is already yours, nothing to claim");
						return true;
					}

					strcpy(e.crypto_idfp, player.crypto_idfp);

					print_to(player, "^2SANDBOX - INFO: ^7Object claimed successfully");
				}
				print_to(player, "^1SANDBOX - WARNING: ^7Object could not be claimed. Make sure you are facing an object that you have edit rights over");
				return true;

			// ---------------- COMMAND: OBJECT, INFO ----------------
			case "object_info":
				// prints public information about the object to the player
				e = sandbox_ObjectEdit_Get(player, false);
				if(e != NULL)
				{
					switch(argv(2))
					{
						case "object":
							print_to(player, strcat("^2SANDBOX - INFO: ^7Object is owned by \"^7", e.netname, "^7\", created \"^3", e.message, "^7\", last edited \"^3", e.message2, "^7\""));
							return true;
						case "mesh":
							s = "";
							FOR_EACH_TAG(e)
								s = strcat(s, "^7\"^5", gettaginfo_name, "^7\", ");
							print_to(player, strcat("^2SANDBOX - INFO: ^7Object mesh is \"^3", e.model, "^7\" at animation frame ^3", ftos(e.frame), " ^7containing the following tags: ", s));
							return true;
						case "attachments":
							// this should show the same info as 'mesh' but for attachments
							s = "";
							j = 0;
							IL_EACH(g_sandbox_objects, it.owner == e,
							{
								++j; // start from 1
								gettaginfo(e, it.tag_index);
								s = strcat(s, "^1attachment ", ftos(j), "^7 has mesh \"^3", it.model, "^7\" at animation frame ^3", ftos(it.frame));
								s = strcat(s, "^7 and is attached to bone \"^5", gettaginfo_name, "^7\", ");
							});
							if(j) // object contains attachments
								print_to(player, strcat("^2SANDBOX - INFO: ^7Object contains the following ^1", ftos(j), "^7 attachment(s): ", s));
							else
								print_to(player, "^2SANDBOX - INFO: ^7Object contains no attachments");
							return true;
					}
				}
				print_to(player, "^1SANDBOX - WARNING: ^7No information could be found. Make sure you are facing an object");
				return true;

			// ---------------- COMMAND: DEFAULT ----------------
			default:
				print_to(player, "Invalid command. For usage information, type 'sandbox help'");
				return true;
		}
	}
}

MUTATOR_HOOKFUNCTION(sandbox, SV_StartFrame)
{
	if(!autocvar_g_sandbox_storage_autosave)
		return;
	if(time < autosave_time)
		return;
	autosave_time = time + autocvar_g_sandbox_storage_autosave;

	sandbox_Database_Save();

	return true;
}
