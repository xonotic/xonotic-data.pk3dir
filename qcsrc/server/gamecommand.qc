string GotoMap(string m);
void race_deleteTime(string map, float pos);

float FullTraceFraction(vector a, vector mi, vector ma, vector b)
{
	vector c;
	float white, black;

	white = 0.001;
	black = 0.001;

	c = a;

	float n, m;
	n = m = 0;

	while(vlen(c - b) > 1)
	{
		++m;

		tracebox(c, mi, ma, b, MOVE_WORLDONLY, world);
		++n;

		if(!trace_startsolid)
		{
			black += vlen(trace_endpos - c);
			c = trace_endpos;
		}

		n += tracebox_inverted(c, mi, ma, b, MOVE_WORLDONLY, world);

		white += vlen(trace_endpos - c);
		c = trace_endpos;
	}

	if(n > 200)
		dprint("HOLY SHIT! FullTraceFraction: ", ftos(n), " total traces, ", ftos(m), " iterations\n");

	return white / (black + white);
}

float RadarMapAtPoint_Trace(float x, float y, float w, float h, float zmin, float zsize, float q)
{
	vector a, b, mi, ma;

	mi = '0 0 0';
	ma = '1 0 0' * w + '0 1 0' * h;
	a = '1 0 0' * x + '0 1 0' * y + '0 0 1' * zmin;
	b = '1 0 0' * x + '0 1 0' * y + '0 0 1' * (zsize + zmin);

	return FullTraceFraction(a, mi, ma, b);
}
float RadarMapAtPoint_LineBlock(float x, float y, float w, float h, float zmin, float zsize, float q)
{
	vector o, mi, ma;
	float i, r;
	vector dz;

	q = 256 * q - 1;
	// 256q-1 is the ideal sample count to map equal amount of sample values to one pixel value

	mi = '0 0 0';
	dz = (zsize / q) * '0 0 1';
	ma = '1 0 0' * w + '0 1 0' * h + dz;
	o = '1 0 0' * x + '0 1 0' * y + '0 0 1' * zmin;

	if(x < world.absmin_x - w)
		return 0;
	if(y < world.absmin_y - h)
		return 0;
	if(x > world.absmax_x)
		return 0;
	if(y > world.absmax_y)
		return 0;

	r = 0;
	for(i = 0; i < q; ++i)
	{
		vector v1, v2;
		v1 = v2 = o + dz * i + mi;
		v1_x += random() * (ma_x - mi_x);
		v1_y += random() * (ma_y - mi_y);
		v1_z += random() * (ma_z - mi_z);
		v2_x += random() * (ma_x - mi_x);
		v2_y += random() * (ma_y - mi_y);
		v2_z += random() * (ma_z - mi_z);
		traceline(v1, v2, MOVE_WORLDONLY, world);
		if(trace_startsolid || trace_fraction < 1)
			++r;
	}
	return r / q;
}
float RadarMapAtPoint_Block(float x, float y, float w, float h, float zmin, float zsize, float q)
{
	vector o, mi, ma;
	float i, r;
	vector dz;

	q = 256 * q - 1;
	// 256q-1 is the ideal sample count to map equal amount of sample values to one pixel value

	mi = '0 0 0';
	dz = (zsize / q) * '0 0 1';
	ma = '1 0 0' * w + '0 1 0' * h + dz;
	o = '1 0 0' * x + '0 1 0' * y + '0 0 1' * zmin;

	if(x < world.absmin_x - w)
		return 0;
	if(y < world.absmin_y - h)
		return 0;
	if(x > world.absmax_x)
		return 0;
	if(y > world.absmax_y)
		return 0;

	r = 0;
	for(i = 0; i < q; ++i)
	{
		tracebox(o + dz * i, mi, ma, o + dz * i, MOVE_WORLDONLY, world);
		if(trace_startsolid)
			++r;
	}
	return r / q;
}
float RadarMapAtPoint_Sample(float x, float y, float w, float h, float zmin, float zsize, float q)
{
	vector a, b, mi, ma;

	q *= 4; // choose q so it matches the regular algorithm in speed

	q = 256 * q - 1;
	// 256q-1 is the ideal sample count to map equal amount of sample values to one pixel value

	mi = '0 0 0';
	ma = '1 0 0' * w + '0 1 0' * h;
	a = '1 0 0' * x + '0 1 0' * y + '0 0 1' * zmin;
	b = '1 0 0' * w + '0 1 0' * h + '0 0 1' * zsize;

	float c, i;
	c = 0;

	for(i = 0; i < q; ++i)
	{
		vector v;
		v_x = a_x + random() * b_x;
		v_y = a_y + random() * b_y;
		v_z = a_z + random() * b_z;
		traceline(v, v, MOVE_WORLDONLY, world);
		if(trace_startsolid)
			++c;
	}

	return c / q;
}

// FF is contained twice, to map 256 to FF too
// removes the need to bound()
string doublehex = "000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F202122232425262728292A2B2C2D2E2F303132333435363738393A3B3C3D3E3F404142434445464748494A4B4C4D4E4F505152535455565758595A5B5C5D5E5F606162636465666768696A6B6C6D6E6F707172737475767778797A7B7C7D7E7F808182838485868788898A8B8C8D8E8F909192939495969798999A9B9C9D9E9FA0A1A2A3A4A5A6A7A8A9AAABACADAEAFB0B1B2B3B4B5B6B7B8B9BABBBCBDBEBFC0C1C2C3C4C5C6C7C8C9CACBCCCDCECFD0D1D2D3D4D5D6D7D8D9DADBDCDDDEDFE0E1E2E3E4E5E6E7E8E9EAEBECEDEEEFF0F1F2F3F4F5F6F7F8F9FAFBFCFDFEFFFF";

float RADAR_WIDTH_MAX = 512;
float RADAR_HEIGHT_MAX = 512;
float sharpen_buffer[RADAR_WIDTH_MAX * 3];

void sharpen_set(float x, float v)
{
	sharpen_buffer[x + 2 * RADAR_WIDTH_MAX] = v;
}

float sharpen_getpixel(float x, float y)
{
	if(x < 0)
		return 0;
	if(x >= RADAR_WIDTH_MAX)
		return 0;
	if(y < 0)
		return 0;
	if(y > 2)
		return 0;
	return sharpen_buffer[x + y * RADAR_WIDTH_MAX];
}

float sharpen_get(float x, float a)
{
	float sum;
	sum = sharpen_getpixel(x, 1);
	if(a == 0)
		return sum;
	sum *= (8 + 1/a);
	sum -= sharpen_getpixel(x - 1, 0);
	sum -= sharpen_getpixel(x - 1, 1);
	sum -= sharpen_getpixel(x - 1, 2);
	sum -= sharpen_getpixel(x + 1, 0);
	sum -= sharpen_getpixel(x + 1, 1);
	sum -= sharpen_getpixel(x + 1, 2);
	sum -= sharpen_getpixel(x, 0);
	sum -= sharpen_getpixel(x, 2);
	return bound(0, sum * a, 1);
}

void sharpen_shift(float w)
{
	float i;
	for(i = 0; i < w; ++i)
	{
		sharpen_buffer[i] = sharpen_buffer[i + RADAR_WIDTH_MAX];
		sharpen_buffer[i + RADAR_WIDTH_MAX] = sharpen_buffer[i + 2 * RADAR_WIDTH_MAX];
		sharpen_buffer[i + 2 * RADAR_WIDTH_MAX] = 0;
	}
}

void sharpen_init(float w)
{
	float i;
	for(i = 0; i < w; ++i)
	{
		sharpen_buffer[i] = 0;
		sharpen_buffer[i + RADAR_WIDTH_MAX] = 0;
		sharpen_buffer[i + 2 * RADAR_WIDTH_MAX] = 0;
	}
}

entity radarmapper;
void RadarMap_Next()
{
	if(radarmapper.count & 4)
	{
		localcmd("quit\n");
	}
	else if(radarmapper.count & 2)
	{
		localcmd(strcat("defer 1 \"sv_cmd radarmap --flags ", ftos(radarmapper.count), strcat(" --res ", ftos(radarmapper.size_x), " ", ftos(radarmapper.size_y), " --sharpen ", ftos(radarmapper.ltime), " --qual ", ftos(radarmapper.size_z)), "\"\n"));
		GotoNextMap();
	}
	remove(radarmapper);
	radarmapper = world;
}

// rough map entity
//   cnt: current line
//   size: pixel width/height
//   maxs: cell width/height
//   frame: counter
void RadarMap_Think()
{
	float i, x, l;
	string si;

	if(self.frame == 0)
	{
		// initialize
		get_mi_min_max_texcoords(1);
		self.mins = mi_picmin;
		self.maxs_x = (mi_picmax_x - mi_picmin_x) / self.size_x;
		self.maxs_y = (mi_picmax_y - mi_picmin_y) / self.size_y;
		self.maxs_z = mi_max_z - mi_min_z;
		print("Picture mins/maxs: ", ftos(self.maxs_x), " and ", ftos(self.maxs_y), " should match\n");
		self.netname = strzone(strcat("gfx/", mi_shortname, "_radar.xpm"));
		if(!(self.count & 1))
		{
			self.cnt = fopen(self.netname, FILE_READ);
			if(self.cnt < 0)
				self.cnt = fopen(strcat("gfx/", mi_shortname, "_radar.tga"), FILE_READ);
			if(self.cnt < 0)
				self.cnt = fopen(strcat("gfx/", mi_shortname, "_radar.png"), FILE_READ);
			if(self.cnt < 0)
				self.cnt = fopen(strcat("gfx/", mi_shortname, "_radar.jpg"), FILE_READ);
			if(self.cnt < 0)
				self.cnt = fopen(strcat("gfx/", mi_shortname, "_mini.tga"), FILE_READ);
			if(self.cnt < 0)
				self.cnt = fopen(strcat("gfx/", mi_shortname, "_mini.png"), FILE_READ);
			if(self.cnt < 0)
				self.cnt = fopen(strcat("gfx/", mi_shortname, "_mini.jpg"), FILE_READ);
			if(self.cnt >= 0)
			{
				fclose(self.cnt);

				print(self.netname, " already exists, aborting (you may want to specify --force)\n");
				RadarMap_Next();
				return;
			}
		}
		self.cnt = fopen(self.netname, FILE_WRITE);
		if(self.cnt < 0)
		{
			print("Error writing ", self.netname, "\n");
			remove(self);
			radarmapper = world;
			return;
		}
		print("Writing to ", self.netname, "...\n");
		fputs(self.cnt, "/* XPM */\n");
		fputs(self.cnt, "static char *RadarMap[] = {\n");
		fputs(self.cnt, "/* columns rows colors chars-per-pixel */\n");
		fputs(self.cnt, strcat("\"", ftos(self.size_x), " ", ftos(self.size_y), " 256 2\",\n"));
		for(i = 0; i < 256; ++i)
		{
			si = substring(doublehex, i*2, 2);
			fputs(self.cnt, strcat("\"", si, " c #", si, si, si, "\",\n"));
		}
		self.frame += 1;
		self.nextthink = time;
		sharpen_init(self.size_x);
	}
	else if(self.frame <= self.size_y)
	{
		// fill the sharpen buffer with this line
		sharpen_shift(self.size_x);
		i = self.count & 24;

		switch(i)
		{
			case 0:
			default:
				for(x = 0; x < self.size_x; ++x)
				{
					l = RadarMapAtPoint_Block(self.mins_x + x * self.maxs_x, self.mins_y + (self.size_y - self.frame) * self.maxs_y, self.maxs_x, self.maxs_y, self.mins_z, self.maxs_z, self.size_z);
					sharpen_set(x, l);
				}
				break;
			case 8:
				for(x = 0; x < self.size_x; ++x)
				{
					l = RadarMapAtPoint_Trace(self.mins_x + x * self.maxs_x, self.mins_y + (self.size_y - self.frame) * self.maxs_y, self.maxs_x, self.maxs_y, self.mins_z, self.maxs_z, self.size_z);
					sharpen_set(x, l);
				}
				break;
			case 16:
				for(x = 0; x < self.size_x; ++x)
				{
					l = RadarMapAtPoint_Sample(self.mins_x + x * self.maxs_x, self.mins_y + (self.size_y - self.frame) * self.maxs_y, self.maxs_x, self.maxs_y, self.mins_z, self.maxs_z, self.size_z);
					sharpen_set(x, l);
				}
				break;
			case 24:
				for(x = 0; x < self.size_x; ++x)
				{
					l = RadarMapAtPoint_LineBlock(self.mins_x + x * self.maxs_x, self.mins_y + (self.size_y - self.frame) * self.maxs_y, self.maxs_x, self.maxs_y, self.mins_z, self.maxs_z, self.size_z);
					sharpen_set(x, l);
				}
				break;
		}

		// do we have enough lines?
		if(self.frame >= 2)
		{
			// write a pixel line
			fputs(self.cnt, "\"");
			for(x = 0; x < self.size_x; ++x)
			{
				l = sharpen_get(x, self.ltime);
				fputs(self.cnt, substring(doublehex, 2 * floor(l * 256.0), 2));
			}
			if(self.frame == self.size_y)
				fputs(self.cnt, "\"\n");
			else
			{
				fputs(self.cnt, "\",\n");
				print(ftos(self.size_y - self.frame), " lines left\n");
			}
		}

		// is this the last line? then write back the missing line
		if(self.frame == self.size_y)
		{
			sharpen_shift(self.size_x);
			// write a pixel line
			fputs(self.cnt, "\"");
			for(x = 0; x < self.size_x; ++x)
			{
				l = sharpen_get(x, self.ltime);
				fputs(self.cnt, substring(doublehex, 2 * floor(l * 256.0), 2));
			}
			if(self.frame == self.size_y)
				fputs(self.cnt, "\"\n");
			else
			{
				fputs(self.cnt, "\",\n");
				print(ftos(self.size_y - self.frame), " lines left\n");
			}
		}

		self.frame += 1;
		self.nextthink = time;
	}
	else
	{
		// close the file
		fputs(self.cnt, "};\n");
		fclose(self.cnt);
		print("Finished. Please edit data/", self.netname, " with an image editing application and place it in the TGA format in the gfx folder.\n");
		RadarMap_Next();
	}
}

void RadarMap(float argc)
{
	if(radarmapper)
		return;
	float i;
	radarmapper = spawn();
	radarmapper.classname = "radarmapper";
	radarmapper.think = RadarMap_Think;
	radarmapper.nextthink = time;
	radarmapper.count = 8; // default to the --trace method, as it is faster now
	radarmapper.ltime = 1;
	radarmapper.size_x = 512;
	radarmapper.size_y = 512;
	radarmapper.size_z = 1;

	for(i = 1; i < argc; ++i)
	{
		if(argv(i) == "--force")
			radarmapper.count |= 1;
		else if(argv(i) == "--loop")
			radarmapper.count |= 2;
		else if(argv(i) == "--quit")
			radarmapper.count |= 4;
		else if(argv(i) == "--block")
		{
			radarmapper.count &~= 24;
		}
		else if(argv(i) == "--trace")
		{
			radarmapper.count &~= 24;
			radarmapper.count |= 8;
		}
		else if(argv(i) == "--sample")
		{
			radarmapper.count &~= 24;
			radarmapper.count |= 16;
		}
		else if(argv(i) == "--lineblock")
		{
			radarmapper.count |= 24;
		}
		else if(argv(i) == "--flags") // for the recursive call
		{
			++i;
			radarmapper.count = stof(argv(i));
		}
		else if(argv(i) == "--sharpen") // for the recursive call
		{
			++i;
			radarmapper.ltime = stof(argv(i));
		}
		else if(argv(i) == "--res") // resolution
		{
			++i;
			radarmapper.size_x = stof(argv(i));
			++i;
			radarmapper.size_y = stof(argv(i));
		}
		else if(argv(i) == "--qual") // quality multiplier
		{
			++i;
			radarmapper.size_z = stof(argv(i));
		}
		else
		{
			remove(radarmapper);
			radarmapper = world;
			print("Usage: sv_cmd radarmap [--force] [--loop] [--quit] [--block | --trace | --sample | --lineblock] [--sharpen N] [--res W H] [--qual Q]\n");
			print("The quality factor Q is roughly proportional to the time taken.\n");
			print("--trace supports no quality factor; its result should look like --block with infinite quality factor.\n");
			print("--block \n");
			return;
		}
	}

	print("Radarmap entity spawned.\n");
}

void make_mapinfo_Think()
{
	if(MapInfo_FilterGametype(MAPINFO_TYPE_ALL, 0, 0, 0, 1))
	{
		print("Done rebuiling mapinfos.\n");
		MapInfo_FilterGametype(MapInfo_CurrentGametype(), MapInfo_CurrentFeatures(), MapInfo_RequiredFlags(), MapInfo_ForbiddenFlags(), 0);
		remove(self);
	}
	else
	{
		self.think = make_mapinfo_Think;
		self.nextthink = time;
	}
}

void changematchtime(float delta, float mi, float ma)
{
	float cur;
	float new;
	float lim;

	if(delta == 0)
		return;
	if(autocvar_timelimit < 0)
		return;

	if(mi <= 10)
		mi = 10; // at least ten sec in the future
	cur = time - game_starttime;
	if(cur > 0)
		mi += cur; // from current time!

	lim = autocvar_timelimit * 60;

	if(delta > 0)
	{
		if(lim == 0)
			return; // cannot increase any further
		else if(lim < ma)
			new = min(ma, lim + delta);
		else // already above maximum: FAIL
			return;
	}
	else
	{
		if(lim == 0) // infinite: try reducing to max, if we are allowed to
			new = max(mi, ma);
		else if(lim > mi) // above minimum: decrease
			new = max(mi, lim + delta);
		else // already below minimum: FAIL
			return;
	}

	cvar_set("timelimit", ftos(new / 60));
}

float g_clientmodel_genericsendentity (entity to, float sf);
void modelbug_make_svqc();
void modelbug_make_csqc()
{
	Net_LinkEntity(self, TRUE, 0, g_clientmodel_genericsendentity);
	self.think = modelbug_make_svqc;
	self.nextthink = time + 1;
	setorigin(self, self.origin - '0 0 8');
}
void modelbug_make_svqc()
{
	self.SendEntity = func_null;
	self.think = modelbug_make_csqc;
	self.nextthink = time + 1;
	setorigin(self, self.origin + '0 0 8');
}

void modelbug()
{
	entity e;
	e = spawn();
	setorigin(e, nextent(world).origin);
	precache_model("models_portal.md3");
	setmodel(e, "models/portal.md3");
	e.think = modelbug_make_svqc;
	e.nextthink = time + 1;
}

// ===================
//  Command Functions
// ===================
#define GC_REQUEST_HELP 1
#define GC_REQUEST_COMMAND 2
#define GC_REQUEST_USAGE 3

void GameCommand_adminmsg(float request, string command)
{
	entity client;
	float argc = tokenize_console(command);
	float entno = stof(argv(1)); 
	float n, i;
	string s;
	
	switch(request)
	{
		case GC_REQUEST_HELP:
			print("  ^2adminmsg^7: Send an admin message to a client directly\n");
			return;
			
		case GC_REQUEST_COMMAND:
			if(argc >= 3 && argc <= 4) {
				if((entno < 0) | (entno > maxclients)) {
					print("Player ", argv(1), " doesn't exist\n");
					return;
				}
				n = 0;
				for(i = (entno ? entno : 1); i <= (entno ? entno : maxclients); ++i)
				{
					client = edict_num(i);
					if(client.flags & FL_CLIENT)
					{
						if(argc == 4)
						{
							s = argv(2);
							s = strreplace("\n", "", s);
							s = strreplace("\\", "\\\\", s);
							s = strreplace("$", "$$", s);
							s = strreplace("\"", "\\\"", s);
							stuffcmd(client, sprintf("\ninfobar %f \"%s\"\n", stof(argv(3)), s));
						}
						else
						{
							centerprint_atprio(client, CENTERPRIO_ADMIN, strcat("^3", admin_name(), ":\n\n^7", argv(2)));
							sprint(client, strcat("\{1}\{13}^3", admin_name(), "^7: ", argv(2), "\n"));
						}
						dprint("Message sent to ", client.netname, "\n");
						++n;
					}
				}
				if(!n) { print("Client not found\n"); } 
				return;
			} 
			
		default:
			print("Incorrect parameters for \"adminmsg\"\n");
		case GC_REQUEST_USAGE:
			print("\nUsage:^3 sv_cmd adminmsg clientnumber \"message\" [infobartime]\n");
			print("  If infobartime is provided, the message will be sent to infobar.\n");
			print("  Otherwise, it will just be sent as a centerprint message.\n");
			print("Examples: adminmsg 4 \"this message will last for ten seconds\" 10\n");
			print("          adminmsg 2 \"this message will be a centerprint\"\n");
			return;
	}
}

void GameCommand_allready(float request)
{
	switch(request)
	{
		case GC_REQUEST_HELP:
			print("  ^2allready^7: Restart the server and reset the players\n");
			return;
			
		case GC_REQUEST_COMMAND:
			ReadyRestart();
			return;
			
		default:
		case GC_REQUEST_USAGE:
			print("\nUsage:^3 sv_cmd allready\n");
			print("  No arguments required.\n");
			return;
	}
}

void GameCommand_allspec(float request) // todo: Add ability to provide a reason string
{
	entity client;
	float i;
	switch(request)
	{
		case GC_REQUEST_HELP:
			print("  ^2allspec^7: Force all players to spectate\n");
			return;
			
		case GC_REQUEST_COMMAND:
			FOR_EACH_PLAYER(client)
			{
				self = client;
				PutObserverInServer();
				++i;
			}
			if(i) { bprint(strcat("Successfully forced all players to spectate (", ftos(i), ")\n")); } // should a message be added if no players were found? 
			return;
			
		default:
		case GC_REQUEST_USAGE:
			print("\nUsage:^3 sv_cmd allspec\n");
			print("  No arguments required.\n");
			print("  See also: ^2moveplayer^7\n");
			return;
	}
}

void GameCommand_anticheat(float request, string command) // FIXME: player entity is never found
{
	entity client;
	float argc = tokenize_console(command);
	float entno = stof(argv(1)); 
	
	switch(request)
	{
		case GC_REQUEST_HELP:
			print("  ^2anticheat^7: Create an anticheat report for a client\n");
			return;
			
		case GC_REQUEST_COMMAND:
			if((entno < 1) | (entno > maxclients)) {
				print("Player ", argv(1), " doesn't exist\n");
				return;
			}
			client = edict_num(entno);
			if(clienttype(client) != CLIENTTYPE_REAL && clienttype(client) != CLIENTTYPE_BOT) {
				print("Player ", client.netname, " is not active\n");
				return;
			}
			self = client;
			anticheat_report();
			return;
			
		default:
			print("Incorrect parameters for \"anticheat\"\n");
		case GC_REQUEST_USAGE:
			print("\nUsage:^3 sv_cmd anticheat clientnumber\n");
			print("  where clientnumber is player entity number.\n");
			return;
	}
}

void GameCommand_bbox(float request)
{
	switch(request)
	{
		case GC_REQUEST_HELP:
			print("  ^2bbox^7: Print detailed information about world size\n");
			return;
			
		case GC_REQUEST_COMMAND:
			print("Original size: ", ftos(world.absmin_x), " ", ftos(world.absmin_y), " ", ftos(world.absmin_z));
			print(" ", ftos(world.absmax_x), " ", ftos(world.absmax_y), " ", ftos(world.absmax_z), "\n");
			print("Currently set size: ", ftos(world.mins_x), " ", ftos(world.mins_y), " ", ftos(world.mins_z));
			print(" ", ftos(world.maxs_x), " ", ftos(world.maxs_y), " ", ftos(world.maxs_z), "\n");
			print("Solid bounding box size:");

			tracebox('1 0 0' * world.absmin_x,
							'0 1 0' * world.absmin_y + '0 0 1' * world.absmin_z,
							'0 1 0' * world.absmax_y + '0 0 1' * world.absmax_z,
							'1 0 0' * world.absmax_x,
					MOVE_WORLDONLY,
					world);
			if(trace_startsolid)
				print(" ", ftos(world.absmin_x));
			else
				print(" ", ftos(trace_endpos_x));

			tracebox('0 1 0' * world.absmin_y,
							'1 0 0' * world.absmin_x + '0 0 1' * world.absmin_z,
							'1 0 0' * world.absmax_x + '0 0 1' * world.absmax_z,
							'0 1 0' * world.absmax_y,
					MOVE_WORLDONLY,
					world);
			if(trace_startsolid)
				print(" ", ftos(world.absmin_y));
			else
				print(" ", ftos(trace_endpos_y));

			tracebox('0 0 1' * world.absmin_z,
							'1 0 0' * world.absmin_x + '0 1 0' * world.absmin_y,
							'1 0 0' * world.absmax_x + '0 1 0' * world.absmax_y,
							'0 0 1' * world.absmax_z,
					MOVE_WORLDONLY,
					world);
			if(trace_startsolid)
				print(" ", ftos(world.absmin_z));
			else
				print(" ", ftos(trace_endpos_z));

			tracebox('1 0 0' * world.absmax_x,
							'0 1 0' * world.absmin_y + '0 0 1' * world.absmin_z,
							'0 1 0' * world.absmax_y + '0 0 1' * world.absmax_z,
							'1 0 0' * world.absmin_x,
					MOVE_WORLDONLY,
					world);
			if(trace_startsolid)
				print(" ", ftos(world.absmax_x));
			else
				print(" ", ftos(trace_endpos_x));

			tracebox('0 1 0' * world.absmax_y,
							'1 0 0' * world.absmin_x + '0 0 1' * world.absmin_z,
							'1 0 0' * world.absmax_x + '0 0 1' * world.absmax_z,
							'0 1 0' * world.absmin_y,
					MOVE_WORLDONLY,
					world);
			if(trace_startsolid)
				print(" ", ftos(world.absmax_y));
			else
				print(" ", ftos(trace_endpos_y));

			tracebox('0 0 1' * world.absmax_z,
							'1 0 0' * world.absmin_x + '0 1 0' * world.absmin_y,
							'1 0 0' * world.absmax_x + '0 1 0' * world.absmax_y,
							'0 0 1' * world.absmin_z,
					MOVE_WORLDONLY,
					world);
			if(trace_startsolid)
				print(" ", ftos(world.absmax_z));
			else
				print(" ", ftos(trace_endpos_z));
				
			print("\n");
			return;
			
		default:
		case GC_REQUEST_USAGE:
			print("\nUsage:^3 sv_cmd bbox\n");
			print("  No arguments required.\n");
			print("  See also: ^2gettaginfo^7\n");
			return;
	}
}

void GameCommand_bot_cmd(float request, string command) // what a mess... old old code.
{
	entity bot;
	float argc = tokenize_console(command);
	
	switch(request)
	{
		case GC_REQUEST_HELP:
			print("  ^2bot_cmd^7: Control and send commands to bots\n");
			return;
			
		case GC_REQUEST_COMMAND:
			if(argv(1) == "reset")
			{
				bot_resetqueues();
				return;
			}
			else if(argv(1) == "load" && argc == 3)
			{
				float fh, i;
				string s;
				fh = fopen(argv(2), FILE_READ);
				if(fh < 0)
				{
					print("cannot open the file\n");
					return;
				}

				i = 0;
				while((s = fgets(fh)))
				{
					argc = tokenize_console(s);

					if(argc >= 3 && argv(0) == "sv_cmd" && argv(1) == "bot_cmd")
					{
						// let's start at token 2 so we can skip sv_cmd bot_cmd
						bot = find_bot_by_number(stof(argv(2)));
						if(bot == world)
							bot = find_bot_by_name(argv(2));
						if(bot)
							bot_queuecommand(bot, strcat(argv(3), " ", argv(4)));
					}
					else
						localcmd(strcat(s, "\n"));

					++i;
				}
				print(ftos(i), " commands read\n");
				fclose(fh);
				return;
			}
			else if(argv(1) == "help")
			{
				if(argv(2))
					bot_cmdhelp(argv(2));
				else
					bot_list_commands();
				return;
			}
			else if(argc >= 3) // this comes last
			{
				bot = find_bot_by_number(stof(argv(1)));
				if(bot == world)
					bot = find_bot_by_name(argv(1));
				if(bot)
				{
					print(strcat("Command '", (argv(2), " ", argv(3)), "' sent to bot ", bot.netname, "\n"));
					bot_queuecommand(bot, strcat(argv(2), " ", argv(3)));
					return;
				}
				else
					print(strcat("Error: Can't find bot with the name or id '", argv(1),"' - Did you mistype the command?\n")); // don't return so that usage is shown
			}
			
		default:
			print("Incorrect parameters for \"bot_cmd\"\n");
		case GC_REQUEST_USAGE:
			print("\nUsage:^3 sv_cmd bot_cmd client command [argument]\n");
			print("  'client' can be either the name or entity id of the bot\n");
			print("  For full list of commands, see bot_cmd help [command].\n");
			print("Examples: bot_cmd <id> cc \"say something\"\n");
			print("          bot_cmd <id> presskey jump\n");
			return;
	}
}

void GameCommand_cointoss(float request) // todo: Perhaps add the ability to give your own arguments to pick between? (Like player names)
{
	entity client;
	float choice = (random() > 0.5);
	
	switch(request)
	{
		case GC_REQUEST_HELP:
			print("  ^2cointoss^7: Flip a virtual coin and give random result\n");
			return;
			
		case GC_REQUEST_COMMAND:
			FOR_EACH_CLIENT(client)
				centerprint(client, strcat("^3Throwing coin... Result: ", (choice ? "^1HEADS^3!\n" : "^4TAILS^3!\n")));
			bprint(strcat("^3Throwing coin... Result: ", (choice ? "^1HEADS^3!\n" : "^4TAILS^3!\n")));
			return;
			
		default:
		case GC_REQUEST_USAGE:
			print("\nUsage:^3 sv_cmd cointoss\n");
			print("  No arguments required.\n");
			return;
	}
}

void GameCommand_cvar_changes(float request)
{
	switch(request)
	{
		case GC_REQUEST_HELP:
			print("  ^2cvar_changes^7: Prints a list of all changed server cvars\n");
			return;
			
		case GC_REQUEST_COMMAND:
			print(cvar_changes);
			return;
			
		default:
		case GC_REQUEST_USAGE:
			print("\nUsage:^3 sv_cmd \n");
			print("  No arguments required.\n");
			print("  See also: ^2cvar_purechanges^7\n");
			return;
	}
}

void GameCommand_cvar_purechanges(float request)
{
	switch(request)
	{
		case GC_REQUEST_HELP:
			print("  ^2cvar_purechanges^7: Prints a list of all changed gameplay cvars\n");
			return;
			
		case GC_REQUEST_COMMAND:
			print(cvar_purechanges);
			return;
			
		default:
		case GC_REQUEST_USAGE:
			print("\nUsage:^3 sv_cmd cvar_purechanges\n");
			print("  No arguments required.\n");
			print("  See also: ^2cvar_changes^7\n");
			return;
	}
}

void GameCommand_database(float request, string command)
{
	float argc = tokenize_console(command);
	
	switch(request)
	{
		case GC_REQUEST_HELP:
			print("  ^2database^7: Extra controls of the serverprogs database\n");
			return;
			
		case GC_REQUEST_COMMAND:
			if(argc == 3)
			{
				if(argv(1) == "save")
				{
					db_save(ServerProgsDB, argv(2));
					print(strcat("Copied serverprogs database to '", argv(2), "' in the data directory.\n"));
					return;
				}
				else if(argv(1) == "dump")
				{
					db_dump(ServerProgsDB, argv(2));
					print("DB dumped.\n"); // wtf does this do?
					return;
				}
				else if(argv(1) == "load")
				{
					db_close(ServerProgsDB);
					ServerProgsDB = db_load(argv(2));
					print(strcat("Loaded '", argv(2), "' as new serverprogs database.\n"));
					return;
				}
			}
			
		default:
			print("Incorrect parameters for \"database\"\n");
		case GC_REQUEST_USAGE:
			print("\nUsage:^3 sv_cmd database action filename\n");
			print("  Where 'action' is the command to complete,\n");
			print("  and 'filename' is what it acts upon.\n");
			print("  Full list of commands here: \"save, dump, load.\"\n");
			return;
	}
}

void GameCommand_defer_clear(float request, string command)
{
	entity client;
	float argc = tokenize_console(command);
	float entno = stof(argv(1));
	
	switch(request)
	{
		case GC_REQUEST_HELP:
			print("  ^2defer_clear^7: Clear all queued defer commands for client\n");
			return;
			
		case GC_REQUEST_COMMAND:
			if(argc == 2)
			{
				// player_id is out of range
				if((entno < 1) | (entno > maxclients)) {
					print("Player ", argv(1), " doesn't exist\n");
					return;
				}
				client = edict_num(entno);
				if not(client.flags & FL_CLIENT) {
					print("Player ", argv(1), " doesn't exist\n");
					return;
				}
				if(clienttype(client) == CLIENTTYPE_BOT) {
					print("Player ", argv(1), " (", client.netname, ") is a bot\n");
					return;
				}
				stuffcmd(client, "defer clear\n");
				print("defer clear stuffed to ", argv(1), " (", client.netname, ")\n");
				return;
			}
		
		default:
			print("Incorrect parameters for \"defer_clear\"\n");
		case GC_REQUEST_USAGE:
			print("\nUsage:^3 sv_cmd defer_clear clientnumber\n");
			print("  where 'clientnumber' is player entity number.\n");
			print("  See also: ^2defer_clear_all^7\n");
			return;
	}
}

void GameCommand_defer_clear_all(float request)
{
	entity client;
	float i;
	
	switch(request)
	{
		case GC_REQUEST_HELP:
			print("  ^2defer_clear_all^7: Clear all queued defer commands for all clients\n");
			return;
			
		case GC_REQUEST_COMMAND:
			FOR_EACH_CLIENT(client)
			{
				GameCommand_defer_clear(GC_REQUEST_COMMAND, strcat("defer_clear ", ftos(num_for_edict(client))));	
				++i;
			}
			if(i) { bprint(strcat("Successfully stuffed defer clear to all clients (", ftos(i), ")\n")); } // should a message be added if no players were found? 
			return;
		
		default:
		case GC_REQUEST_USAGE:
			print("\nUsage:^3 sv_cmd defer_clear_all\n");
			print("  No arguments required.\n");
			print("  See also: ^2defer_clear^7\n");
			return;
	}
}

void GameCommand_delrec(float request, string command) // UNTESTED
{
	float argc = tokenize_console(command);

	switch(request)
	{
		case GC_REQUEST_HELP:
			print("  ^2delrec^7: Delete race time record for a map\n");
			return;
			
		case GC_REQUEST_COMMAND:
			if(argv(1))
			{
				if(argv(2))
					race_deleteTime(argv(2), stof(argv(1)));
				else
					race_deleteTime(GetMapname(), stof(argv(1)));
				return;
			}
			
		default:
			print("Incorrect parameters for \"delrec\"\n");
		case GC_REQUEST_USAGE:
			print("\nUsage:^3 sv_cmd delrec ranking [map]\n");
			print("  'ranking' is which ranking level to clear up to, \n");
			print("  it will clear all records up to nth place.\n");
			print("  if 'map' is not provided it will use current map.\n");
			return;
	}
}

void GameCommand_effectindexdump(float request)
{
	float fh, d;
	string s;
	
	switch(request)
	{
		case GC_REQUEST_HELP:
			print("  ^2effectindexdump^7: Dump list of effects from code and effectinfo.txt\n");
			return;
			
		case GC_REQUEST_COMMAND:
			d = db_create();
			print("begin of effects list\n");
			db_put(d, "TE_GUNSHOT", "1"); print("effect TE_GUNSHOT is ", ftos(particleeffectnum("TE_GUNSHOT")), "\n");
			db_put(d, "TE_GUNSHOTQUAD", "1"); print("effect TE_GUNSHOTQUAD is ", ftos(particleeffectnum("TE_GUNSHOTQUAD")), "\n");
			db_put(d, "TE_SPIKE", "1"); print("effect TE_SPIKE is ", ftos(particleeffectnum("TE_SPIKE")), "\n");
			db_put(d, "TE_SPIKEQUAD", "1"); print("effect TE_SPIKEQUAD is ", ftos(particleeffectnum("TE_SPIKEQUAD")), "\n");
			db_put(d, "TE_SUPERSPIKE", "1"); print("effect TE_SUPERSPIKE is ", ftos(particleeffectnum("TE_SUPERSPIKE")), "\n");
			db_put(d, "TE_SUPERSPIKEQUAD", "1"); print("effect TE_SUPERSPIKEQUAD is ", ftos(particleeffectnum("TE_SUPERSPIKEQUAD")), "\n");
			db_put(d, "TE_WIZSPIKE", "1"); print("effect TE_WIZSPIKE is ", ftos(particleeffectnum("TE_WIZSPIKE")), "\n");
			db_put(d, "TE_KNIGHTSPIKE", "1"); print("effect TE_KNIGHTSPIKE is ", ftos(particleeffectnum("TE_KNIGHTSPIKE")), "\n");
			db_put(d, "TE_EXPLOSION", "1"); print("effect TE_EXPLOSION is ", ftos(particleeffectnum("TE_EXPLOSION")), "\n");
			db_put(d, "TE_EXPLOSIONQUAD", "1"); print("effect TE_EXPLOSIONQUAD is ", ftos(particleeffectnum("TE_EXPLOSIONQUAD")), "\n");
			db_put(d, "TE_TAREXPLOSION", "1"); print("effect TE_TAREXPLOSION is ", ftos(particleeffectnum("TE_TAREXPLOSION")), "\n");
			db_put(d, "TE_TELEPORT", "1"); print("effect TE_TELEPORT is ", ftos(particleeffectnum("TE_TELEPORT")), "\n");
			db_put(d, "TE_LAVASPLASH", "1"); print("effect TE_LAVASPLASH is ", ftos(particleeffectnum("TE_LAVASPLASH")), "\n");
			db_put(d, "TE_SMALLFLASH", "1"); print("effect TE_SMALLFLASH is ", ftos(particleeffectnum("TE_SMALLFLASH")), "\n");
			db_put(d, "TE_FLAMEJET", "1"); print("effect TE_FLAMEJET is ", ftos(particleeffectnum("TE_FLAMEJET")), "\n");
			db_put(d, "EF_FLAME", "1"); print("effect EF_FLAME is ", ftos(particleeffectnum("EF_FLAME")), "\n");
			db_put(d, "TE_BLOOD", "1"); print("effect TE_BLOOD is ", ftos(particleeffectnum("TE_BLOOD")), "\n");
			db_put(d, "TE_SPARK", "1"); print("effect TE_SPARK is ", ftos(particleeffectnum("TE_SPARK")), "\n");
			db_put(d, "TE_PLASMABURN", "1"); print("effect TE_PLASMABURN is ", ftos(particleeffectnum("TE_PLASMABURN")), "\n");
			db_put(d, "TE_TEI_G3", "1"); print("effect TE_TEI_G3 is ", ftos(particleeffectnum("TE_TEI_G3")), "\n");
			db_put(d, "TE_TEI_SMOKE", "1"); print("effect TE_TEI_SMOKE is ", ftos(particleeffectnum("TE_TEI_SMOKE")), "\n");
			db_put(d, "TE_TEI_BIGEXPLOSION", "1"); print("effect TE_TEI_BIGEXPLOSION is ", ftos(particleeffectnum("TE_TEI_BIGEXPLOSION")), "\n");
			db_put(d, "TE_TEI_PLASMAHIT", "1"); print("effect TE_TEI_PLASMAHIT is ", ftos(particleeffectnum("TE_TEI_PLASMAHIT")), "\n");
			db_put(d, "EF_STARDUST", "1"); print("effect EF_STARDUST is ", ftos(particleeffectnum("EF_STARDUST")), "\n");
			db_put(d, "TR_ROCKET", "1"); print("effect TR_ROCKET is ", ftos(particleeffectnum("TR_ROCKET")), "\n");
			db_put(d, "TR_GRENADE", "1"); print("effect TR_GRENADE is ", ftos(particleeffectnum("TR_GRENADE")), "\n");
			db_put(d, "TR_BLOOD", "1"); print("effect TR_BLOOD is ", ftos(particleeffectnum("TR_BLOOD")), "\n");
			db_put(d, "TR_WIZSPIKE", "1"); print("effect TR_WIZSPIKE is ", ftos(particleeffectnum("TR_WIZSPIKE")), "\n");
			db_put(d, "TR_SLIGHTBLOOD", "1"); print("effect TR_SLIGHTBLOOD is ", ftos(particleeffectnum("TR_SLIGHTBLOOD")), "\n");
			db_put(d, "TR_KNIGHTSPIKE", "1"); print("effect TR_KNIGHTSPIKE is ", ftos(particleeffectnum("TR_KNIGHTSPIKE")), "\n");
			db_put(d, "TR_VORESPIKE", "1"); print("effect TR_VORESPIKE is ", ftos(particleeffectnum("TR_VORESPIKE")), "\n");
			db_put(d, "TR_NEHAHRASMOKE", "1"); print("effect TR_NEHAHRASMOKE is ", ftos(particleeffectnum("TR_NEHAHRASMOKE")), "\n");
			db_put(d, "TR_NEXUIZPLASMA", "1"); print("effect TR_NEXUIZPLASMA is ", ftos(particleeffectnum("TR_NEXUIZPLASMA")), "\n");
			db_put(d, "TR_GLOWTRAIL", "1"); print("effect TR_GLOWTRAIL is ", ftos(particleeffectnum("TR_GLOWTRAIL")), "\n");
			db_put(d, "TR_SEEKER", "1"); print("effect TR_SEEKER is ", ftos(particleeffectnum("TR_SEEKER")), "\n");
			db_put(d, "SVC_PARTICLE", "1"); print("effect SVC_PARTICLE is ", ftos(particleeffectnum("SVC_PARTICLE")), "\n");

			fh = fopen("effectinfo.txt", FILE_READ);
			while((s = fgets(fh)))
			{
				tokenize(s); // tokenize_console would hit the loop counter :(
				if(argv(0) == "effect")
				{
					if(db_get(d, argv(1)) != "1")
					{
						if(particleeffectnum(argv(1)) >= 0)
							print("effect ", argv(1), " is ", ftos(particleeffectnum(argv(1))), "\n");
						db_put(d, argv(1), "1");
					}
				}
			}
			print("end of effects list\n");

			db_close(d);
			return;
			
		default:
		case GC_REQUEST_USAGE:
			print("\nUsage:^3 sv_cmd effectindexdump\n");
			print("  No arguments required.\n");
			return;
	}
}

void GameCommand_extendmatchtime(float request) // todo: Perhaps allows the user to send a specific time to extend it.
{
	switch(request)
	{
		case GC_REQUEST_HELP:
			print("  ^2extendmatchtime^7: Increase the timelimit value incrementally\n");
			return;
			
		case GC_REQUEST_COMMAND:
			changematchtime(autocvar_timelimit_increment* 60, autocvar_timelimit_min*60, autocvar_timelimit_max*60);
			return;
			
		default:
		case GC_REQUEST_USAGE:
			print("\nUsage:^3 sv_cmd extendmatchtime\n");
			print("  No arguments required.\n");
			print("  See also: ^2reducematchtime^7\n");
			return;
	}
}

void GameCommand_find(float request, string command)
{
	entity client;
	float argc = tokenize_console(command);
	
	switch(request)
	{
		case GC_REQUEST_HELP:
			print("  ^2find^7: Search through entities for matching classname\n");
			return;
			
		case GC_REQUEST_COMMAND:
			for(client = world; (client = find(client, classname, argv(1))); )
				print(etos(client), "\n");
			return;
			
		default:
			print("Incorrect parameters for \"find\"\n");
		case GC_REQUEST_USAGE:
			print("\nUsage:^3 sv_cmd find classname\n");
			print("  Where 'classname' is the classname to search for.\n");
			return;
	}
}

void GameCommand_gametype(float request, string command)
{
	float argc = tokenize_console(command);
	string s = argv(1);
	float t = MapInfo_Type_FromString(s), tsave = MapInfo_CurrentGametype();
	
	switch(request)
	{
		case GC_REQUEST_HELP:
			print("  ^2gametype^7: Simple command to change the active gametype\n");
			return;
			
		case GC_REQUEST_COMMAND:
			if(t)
			{
				MapInfo_SwitchGameType(t);
				MapInfo_FilterGametype(MapInfo_CurrentGametype(), MapInfo_CurrentFeatures(), MapInfo_RequiredFlags(), MapInfo_ForbiddenFlags(), 0);
				if(MapInfo_count > 0)
					bprint("Game type successfully switched to ", s, "\n");
				else
				{
					bprint("Cannot use this game type: no map for it found\n");
					MapInfo_SwitchGameType(tsave);
					MapInfo_FilterGametype(MapInfo_CurrentGametype(), MapInfo_CurrentFeatures(), MapInfo_RequiredFlags(), MapInfo_ForbiddenFlags(), 0);
				}
			}
			else
				bprint("Game type switch to ", s, " failed: this type does not exist!\n");
			return;
			
		default:
			print("Incorrect parameters for \"gametype\"\n");
		case GC_REQUEST_USAGE:
			print("\nUsage:^3 sv_cmd gametype mode\n");
			print("  Where 'mode' is the gametype mode to switch to.\n");
			print("  See also: ^2gotomap^7\n");
			return;
	}
}

void GameCommand_gettaginfo(float request, string command) // UNTESTED // todo: finish usage description for it (but, must first learn this shit)
{
	entity tmp_entity;
	float argc = tokenize_console(command), i;
	vector v;
	switch(request)
	{
		case GC_REQUEST_HELP:
			print("  ^2gettaginfo^7: Get specific information about a weapon model\n");
			return;
			
		case GC_REQUEST_COMMAND:
			if(argc >= 4)
			{
				tmp_entity = spawn();
				if(argv(1) == "w")
					setmodel(tmp_entity, (nextent(world)).weaponentity.model);
				else
				{
					precache_model(argv(1));
					setmodel(tmp_entity, argv(1));
				}
				tmp_entity.frame = stof(argv(2));
				if(substring(argv(3), 0, 1) == "#")
					i = stof(substring(argv(3), 1, -1));
				else
					i = gettagindex(tmp_entity, argv(3));
				if(i)
				{
					v = gettaginfo(tmp_entity, i);
					print("model ", tmp_entity.model, " frame ", ftos(tmp_entity.frame), " tag ", gettaginfo_name);
					print(" index ", ftos(i), " parent ", ftos(gettaginfo_parent), "\n");
					print(" vector = ", ftos(v_x), " ", ftos(v_y), " ", ftos(v_z), "\n");
					print(" offset = ", ftos(gettaginfo_offset_x), " ", ftos(gettaginfo_offset_y), " ", ftos(gettaginfo_offset_z), "\n");
					print(" forward = ", ftos(gettaginfo_forward_x), " ", ftos(gettaginfo_forward_y), " ", ftos(gettaginfo_forward_z), "\n");
					print(" right = ", ftos(gettaginfo_right_x), " ", ftos(gettaginfo_right_y), " ", ftos(gettaginfo_right_z), "\n");
					print(" up = ", ftos(gettaginfo_up_x), " ", ftos(gettaginfo_up_y), " ", ftos(gettaginfo_up_z), "\n");
					if(argc >= 6)
					{
						v_y = -v_y;
						localcmd(strcat(argv(4), vtos(v), argv(5), "\n"));
					}
				}
				else
					print("bone not found\n");
					
				remove(tmp_entity);
				return;
			}
			
		default:
			print("Incorrect parameters for \"gettaginfo\"\n");
		case GC_REQUEST_USAGE:
			print("\nUsage:^3 sv_cmd gettaginfo\n");
			print("  FIXME: Arguments currently unknown\n");
			print("  See also: ^2bbox^7\n");
			return;
	}
}

void GameCommand_gotomap(float request, string command)
{
	float argc = tokenize_console(command);
	
	switch(request)
	{
		case GC_REQUEST_HELP:
			print("  ^2gotomap^7: Simple command to switch to another map\n");
			return;
			
		case GC_REQUEST_COMMAND:
			if(argc == 2)
			{
				print(GotoMap(argv(1)), "\n");
				return;
			}
			
		default:
			print("Incorrect parameters for \"gotomap\"\n");
		case GC_REQUEST_USAGE:
			print("\nUsage:^3 sv_cmd gotomap map\n");
			print("  Where 'map' is the *.bsp file to change to.\n");
			print("  See also: ^2gametype^7\n");
			return;
	}
}

void GameCommand_ladder(float request)
{
	switch(request)
	{
		case GC_REQUEST_HELP:
			print("  ^2ladder^7: Get information about top players if supported\n");
			return;
			
		case GC_REQUEST_COMMAND:
			print(ladder_reply);
			return;
			
		default:
		case GC_REQUEST_USAGE:
			print("\nUsage:^3 sv_cmd ladder\n");
			print("  No arguments required.\n");
			return;
	}
}

void GameCommand_lockteams(float request)
{
	switch(request)
	{
		case GC_REQUEST_HELP:
			print("  ^2lockteams^7: Disable the ability for players to switch or enter teams\n");
			return;
			
		case GC_REQUEST_COMMAND:
			if(teamplay)
			{
				lockteams = 1;
				bprint("^1The teams are now locked.\n");
			}
			else
				bprint("That command can only be used in a team-based gamemode.\n");
			return;
			
		default:
		case GC_REQUEST_USAGE:
			print("\nUsage:^3 sv_cmd lockteams\n");
			print("  No arguments required.\n");
			print("  See also: ^2unlockteams^7\n");
			return;
	}
}

void GameCommand_make_mapinfo(float request) // UNTESTED
{
	entity tmp_entity;
	
	switch(request)
	{
		case GC_REQUEST_HELP:
			print("  ^2make_mapinfo^7: Automatically rebuild mapinfo files\n");
			return;
			
		case GC_REQUEST_COMMAND: 
			tmp_entity = spawn();
			tmp_entity.classname = "make_mapinfo";
			tmp_entity.think = make_mapinfo_Think;
			tmp_entity.nextthink = time; // this sucks... todo: re-write this -- Use initializeentity later
			MapInfo_Enumerate();
			return;
			
		default:
		case GC_REQUEST_USAGE:
			print("\nUsage:^3 sv_cmd make_mapinfo\n");
			print("  No arguments required.\n");
			return;
	}
}

void GameCommand_moveplayer(float request, string command)
{
	entity client;
	float argc, i;
	argc = tokenize_console(command); // we can only have one argc, so we store the information from it to other strings
	string targets = argv(1);
	string destination = argv(2);
	string notify = argv(3);
	argc = tokenizebyseparator(targets, ","); // and re-use it later for the target selection.
	
	switch(request)
	{
		case GC_REQUEST_HELP:
			print("  ^2moveplayer^7: Change the team/status of a player\n");
			return;
			
		case GC_REQUEST_COMMAND:
			// lets see if the target(s) even actually exist.
			if((targets) && (destination))
			{ 
				for(i = 0; i < argc; ++i)
				{
					// Check to see if the player is a valid target
					if((stof(argv(i)) < 1) | (stof(argv(i)) > maxclients)) // player_id is out of range
					{
						print(strcat("Player ", argv(i), " doesn't exist", (((i + 1) < argc) ? ", skipping to next player.\n" : ".\n")));
						continue; 
					}
					client = edict_num(stof(argv(i)));
					if not(client.flags & FL_CLIENT) // player entity is not a client
					{
						print(strcat("Player ", argv(i), " doesn't exist", (((i + 1) < argc) ? ", skipping to next player.\n" : ".\n")));
						continue;
					}
					
					// Where are we putting this player?
					if(destination == "spec" || destination == "spectator") 
					{
						if(client.classname != "spectator" && client.classname != "observer")
						{
							self = client;
							PutObserverInServer();
						}
						else
						{
							print("Player ", argv(i), " (", client.netname, ") is already spectating.\n");
						}
						return;
					}
					else
					{
						if(client.classname != "spectator" && client.classname != "observer")
						{
							if(teamplay)
							{
								// set up
								float team_color;
								float save = client.team_forced;
								client.team_forced = 0;

								// find the team to move the player to
								team_color = ColourToNumber(destination);
								if(team_color == client.team) // already on the destination team
								{
									// keep the forcing undone
									print("Player ", argv(i), " (", client.netname, ") is already on the ", ColoredTeamName(client.team), ".\n");
									return;
								} 
								else if(team_color == 0)  // auto team
								{
									team_color = NumberToTeamNumber(FindSmallestTeam(client, FALSE));
								}
								else
								{
									CheckAllowedTeams(client);
								}
								client.team_forced = save;
								
								// Check to see if the destination team is even available
								switch(team_color) 
								{
									case COLOR_TEAM1:
										if(c1 == -1) {
											print("Sorry, can't move player to red team if it doesn't exist.\n");
											return;
										}
										break;

									case COLOR_TEAM2:
										if(c2 == -1) {
											print("Sorry, can't move player to blue team if it doesn't exist.\n");
											return;
										}
										break;

									case COLOR_TEAM3:
										if(c3 == -1) {
											print("Sorry, can't move player to yellow team if it doesn't exist.\n");
											return;
										}
										break;

									case COLOR_TEAM4:
										if(c4 == -1) {
											print("Sorry, can't move player to pink team if it doesn't exist.\n");
											return;
										}
										break;

									default:
										print("Sorry, can't move player here if team ", destination, " doesn't exist.\n");
										return;
								}
								
								// If so, lets continue and finally move the player
								client.team_forced = 0;
								MoveToTeam(client, team_color, 6, stof(notify));
								print("Player ", argv(i), " (", client.netname, ") has been moved to the ", ColoredTeamName(team_color), ".\n");
								return;
							}
							else
							{
								print("Can't change teams when currently not playing a team game.\n");
								return;
							}
						}
						else
						{
							print("Can't change teams if the player isn't in the game.\n"); // well technically we could, but should we allow that? :P 
							return;
						}
					}
				}
				print("No acceptable players given, aborting.\n");
				return; // still correct parameters so return to avoid usage print
			}
			
		default:
			print("Incorrect parameters for \"moveplayer\"\n");
		case GC_REQUEST_USAGE:
			print("\nUsage:^3 sv_cmd moveplayer clientnumbers destination [notify]\n");
			print("  'clientnumbers' is a list (separated by commas) of player entity ID's\n");
			print("  'destination' is what to send the player to, be it team or spectating\n");
			print("  Full list of destinations here: \"spec, spectator, red, blue, yellow, pink, auto.\"\n");
			print("  'notify' is whether or not to send messages notifying of the move. Detail below.\n");
			print("    0 (00) automove centerprint, admin message; 1 (01) automove centerprint, no admin message\n");
			print("    2 (10) no centerprint, admin message; 3 (11) no centerprint, no admin message\n");
			print("Examples: moveplayer 1,3,5 red 3\n");
			print("          moveplayer 2 spec \n");
			print("  See also: ^2allspec^7\n");
			return;
	}
}

void GameCommand(string command)
{
	// ===== TODO list =====
	
	// Finish adding the rest of the commands
	
	// Add ifdef to stuffto so that is can only be used when the game code is compiled for it 
	//(this way it's more obscure and harder to abuse on normal servers)

	float search_request_type;
	float argc = tokenize_console(command);

	if(argv(0) == "help") 
	{
		if(argc == 1) 
		{
			print("\nUsage:^3 sv_cmd COMMAND...^7, where possible commands are:\n");
			GameCommand_adminmsg(GC_REQUEST_HELP, "");
			GameCommand_allready(GC_REQUEST_HELP);
			GameCommand_allspec(GC_REQUEST_HELP);
			GameCommand_anticheat(GC_REQUEST_HELP, "");
			GameCommand_bbox(GC_REQUEST_HELP);
			GameCommand_bot_cmd(GC_REQUEST_HELP, "");
			GameCommand_cointoss(GC_REQUEST_HELP);
			GameCommand_cvar_changes(GC_REQUEST_HELP);
			GameCommand_cvar_purechanges(GC_REQUEST_HELP);
			GameCommand_database(GC_REQUEST_HELP, "");
			GameCommand_defer_clear(GC_REQUEST_HELP, "");
			GameCommand_defer_clear_all(GC_REQUEST_HELP);
			GameCommand_delrec(GC_REQUEST_HELP, "");
			GameCommand_effectindexdump(GC_REQUEST_HELP);
			GameCommand_extendmatchtime(GC_REQUEST_HELP);
			GameCommand_find(GC_REQUEST_HELP, "");
			GameCommand_gametype(GC_REQUEST_HELP, "");
			GameCommand_gettaginfo(GC_REQUEST_HELP, "");
			GameCommand_gotomap(GC_REQUEST_HELP, "");
			GameCommand_ladder(GC_REQUEST_HELP);
			GameCommand_lockteams(GC_REQUEST_HELP);
			GameCommand_make_mapinfo(GC_REQUEST_HELP);
			GameCommand_moveplayer(GC_REQUEST_HELP, "");
			GameCommand_Vote("help", world);
			GameCommand_Ban("help");
			GameCommand_Generic("help");
			print("For help about specific commands, type sv_cmd help COMMAND\n");
			return;
		} 
		else
			search_request_type = GC_REQUEST_USAGE; // Instead of trying to call a command, we're going to see detailed information about it
	} 
	else if(GameCommand_Vote(command, world)) 
	{
		return; // handled by server/vote.qc 
	}
	else if(GameCommand_Ban(command)) 
	{
		return; // handled by server/ipban.qc
	}
	else if(GameCommand_Generic(command)) 
	{
		return; // handled by common/gamecommand.qc
	}
	else
		search_request_type = GC_REQUEST_COMMAND; // continue as usual and scan for normal commands
		
	switch( ((argv(0) == "help") ? argv(1) : argv(0)) ) // if first argument is help, then search for the second argument. Else, search for first. 
	{
		case "adminmsg": GameCommand_adminmsg(search_request_type, command); break;
		case "allready": GameCommand_allready(search_request_type); break;
		case "allspec": GameCommand_allspec(search_request_type); break;
		case "anticheat": GameCommand_anticheat(search_request_type, command); break;
		case "bbox": GameCommand_bbox(search_request_type); break;
		case "bot_cmd": GameCommand_bot_cmd(search_request_type, command); break;
		case "cointoss": GameCommand_cointoss(search_request_type); break; 
		case "cvar_changes": GameCommand_cvar_changes(search_request_type); break; 
		case "cvar_purechanges": GameCommand_cvar_purechanges(search_request_type); break; 
		case "database": GameCommand_database(search_request_type, command); break;
		case "defer_clear": GameCommand_defer_clear(search_request_type, command); break;
		case "defer_clear_all": GameCommand_defer_clear_all(search_request_type); break;
		case "delrec": GameCommand_delrec(search_request_type, command); break;
		case "effectindexdump": GameCommand_effectindexdump(search_request_type); break;
		case "extendmatchtime": GameCommand_extendmatchtime(search_request_type); break;
		case "find": GameCommand_find(search_request_type, command); break; 
		case "gametype": GameCommand_gametype(search_request_type, command); break;
		case "gettaginfo": GameCommand_gettaginfo(search_request_type, command); break;
		case "gotomap": GameCommand_gotomap(search_request_type, command); break;
		case "ladder": GameCommand_ladder(search_request_type); break;
		case "lockteams": GameCommand_lockteams(search_request_type); break;
		case "make_mapinfo": GameCommand_make_mapinfo(search_request_type); break;
		case "moveplayer": GameCommand_moveplayer(search_request_type, command); break;
		
		default:
			print("Invalid command. For a list of supported commands, try sv_cmd help.\n");
	}
}

