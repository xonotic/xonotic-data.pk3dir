#include "radarmap.qh"
#ifdef RADARMAP

#include <common/command/_mod.qh>
#include <common/mapobjects/triggers.qh>
#include <common/util.qh>
#include <lib/csqcmodel/sv_model.qh>
#include <server/intermission.qh>
#include <server/world.qh>

// ===============================================
//	Generates radar map images for use in the HUD
// ===============================================

float FullTraceFraction(vector a, vector mi, vector ma, vector b)
{
	vector c;
	float white, black;

	white = 0.001;
	black = 0.001;

	c = a;

	float n, m;
	n = m = 0;

	while (vdist(c - b, >, 1))
	{
		++m;

		tracebox(c, mi, ma, b, MOVE_WORLDONLY, NULL);
		++n;

		if (!trace_startsolid)
		{
			black += vlen(trace_endpos - c);
			c = trace_endpos;
		}

		n += tracebox_inverted(c, mi, ma, b, MOVE_WORLDONLY, NULL, false, NULL);

		white += vlen(trace_endpos - c);
		c = trace_endpos;
	}

	if (n > 200) LOG_TRACE("HOLY SHIT! FullTraceFraction: ", ftos(n), " total traces, ", ftos(m), " iterations");

	return white / (black + white);
}
float RadarMapAtPoint_Trace(float e, float f, float w, float h, float zmin, float zsize, float q)
{
	vector a, b, mi, ma;

	mi = '0 0 0';
	ma = '1 0 0' * w + '0 1 0' * h;
	a = '1 0 0' * e + '0 1 0' * f + '0 0 1' * zmin;
	b = '1 0 0' * e + '0 1 0' * f + '0 0 1' * (zsize + zmin);

	return FullTraceFraction(a, mi, ma, b);
}
float RadarMapAtPoint_LineBlock(float e, float f, float w, float h, float zmin, float zsize, float q)
{
	vector o, mi, ma;
	float i, r;
	vector dz;

	q = 256 * q - 1;
	// 256q-1 is the ideal sample count to map equal amount of sample values to one pixel value

	mi = '0 0 0';
	dz = (zsize / q) * '0 0 1';
	ma = '1 0 0' * w + '0 1 0' * h + dz;
	o = '1 0 0' * e + '0 1 0' * f + '0 0 1' * zmin;

	if (e < world.absmin.x - w) return 0;
	if (f < world.absmin.y - h) return 0;
	if (e > world.absmax.x) return 0;
	if (f > world.absmax.y) return 0;

	r = 0;
	for (i = 0; i < q; ++i)
	{
		vector v1, v2;
		v1 = v2 = o + dz * i + mi;
		v1_x += random() * (ma.x - mi.x);
		v1_y += random() * (ma.y - mi.y);
		v1_z += random() * (ma.z - mi.z);
		v2_x += random() * (ma.x - mi.x);
		v2_y += random() * (ma.y - mi.y);
		v2_z += random() * (ma.z - mi.z);
		traceline(v1, v2, MOVE_WORLDONLY, NULL);
		if (trace_startsolid || trace_fraction < 1) ++r;
	}
	return r / q;
}
float RadarMapAtPoint_Block(float e, float f, float w, float h, float zmin, float zsize, float q)
{
	vector o, mi, ma;
	float i, r;
	vector dz;

	q = 256 * q - 1;
	// 256q-1 is the ideal sample count to map equal amount of sample values to one pixel value

	mi = '0 0 0';
	dz = (zsize / q) * '0 0 1';
	ma = '1 0 0' * w + '0 1 0' * h + dz;
	o = '1 0 0' * e + '0 1 0' * f + '0 0 1' * zmin;

	if (e < world.absmin.x - w) return 0;
	if (f < world.absmin.y - h) return 0;
	if (e > world.absmax.x) return 0;
	if (f > world.absmax.y) return 0;

	r = 0;
	for (i = 0; i < q; ++i)
	{
		tracebox(o + dz * i, mi, ma, o + dz * i, MOVE_WORLDONLY, NULL);
		if (trace_startsolid) ++r;
	}
	return r / q;
}
float RadarMapAtPoint_Sample(float e, float f, float w, float h, float zmin, float zsize, float q)
{
	vector a, b, mi, ma;

	q *= 4;  // choose q so it matches the regular algorithm in speed

	q = 256 * q - 1;
	// 256q-1 is the ideal sample count to map equal amount of sample values to one pixel value

	mi = '0 0 0';
	ma = '1 0 0' * w + '0 1 0' * h;
	a = '1 0 0' * e + '0 1 0' * f + '0 0 1' * zmin;
	b = '1 0 0' * w + '0 1 0' * h + '0 0 1' * zsize;

	float c, i;
	c = 0;

	for (i = 0; i < q; ++i)
	{
		vector v;
		v.x = a.x + random() * b.x;
		v.y = a.y + random() * b.y;
		v.z = a.z + random() * b.z;
		traceline(v, v, MOVE_WORLDONLY, NULL);
		if (trace_startsolid) ++c;
	}

	return c / q;
}
void sharpen_set(int b, float v)
{
	sharpen_buffer[b + 2 * RADAR_WIDTH_MAX] = v;
}
float sharpen_getpixel(int b, int c)
{
	if (b < 0) return 0;
	if (b >= RADAR_WIDTH_MAX) return 0;
	if (c < 0) return 0;
	if (c > 2) return 0;
	return sharpen_buffer[b + c * RADAR_WIDTH_MAX];
}
float sharpen_get(float b, float a)
{
	float sum = sharpen_getpixel(b, 1);
	if (a == 0) return sum;
	sum *= (8 + 1 / a);
	sum -= sharpen_getpixel(b - 1, 0);
	sum -= sharpen_getpixel(b - 1, 1);
	sum -= sharpen_getpixel(b - 1, 2);
	sum -= sharpen_getpixel(b + 1, 0);
	sum -= sharpen_getpixel(b + 1, 1);
	sum -= sharpen_getpixel(b + 1, 2);
	sum -= sharpen_getpixel(b, 0);
	sum -= sharpen_getpixel(b, 2);
	return bound(0, sum * a, 1);
}
void sharpen_shift(int w)
{
	for (int i = 0; i < w; ++i)
	{
		sharpen_buffer[i] = sharpen_buffer[i + RADAR_WIDTH_MAX];
		sharpen_buffer[i + RADAR_WIDTH_MAX] = sharpen_buffer[i + 2 * RADAR_WIDTH_MAX];
		sharpen_buffer[i + 2 * RADAR_WIDTH_MAX] = 0;
	}
}
void sharpen_init(int w)
{
	for (int i = 0; i < w; ++i)
	{
		sharpen_buffer[i] = 0;
		sharpen_buffer[i + RADAR_WIDTH_MAX] = 0;
		sharpen_buffer[i + 2 * RADAR_WIDTH_MAX] = 0;
	}
}
void RadarMap_Next()
{
	if (radarmapper.count & 4)
	{
		localcmd("quit\n");
	}
	else if (radarmapper.count & 2)
	{
		localcmd(strcat("defer 1 \"sv_cmd radarmap --flags ", ftos(radarmapper.count), strcat(" --res ", ftos(radarmapper.size.x), " ", ftos(radarmapper.size.y), " --sharpen ", ftos(radarmapper.ltime), " --qual ", ftos(radarmapper.size.z)), "\"\n"));
		GotoNextMap(0);
	}
	delete(radarmapper);
	radarmapper = NULL;
}
void RadarMap_Think(entity this)
{
	// rough map entity
	//   cnt: current line
	//   size: pixel width/height
	//   maxs: cell width/height
	//   frame: counter

	float i, x, l;
	string si;

	if (this.frame == 0)
	{
		// initialize
		get_mi_min_max_texcoords(1);
		this.mins = mi_picmin;
		this.maxs_x = (mi_picmax.x - mi_picmin.x) / this.size.x;
		this.maxs_y = (mi_picmax.y - mi_picmin.y) / this.size.y;
		this.maxs_z = mi_max.z - mi_min.z;
		LOG_INFO("Picture mins/maxs: ", ftos(this.maxs.x), " and ", ftos(this.maxs.y), " should match");
		this.netname = strzone(strcat("gfx/", mi_shortname, "_radar.xpm"));
		if (!(this.count & 1))
		{
			this.cnt = fopen(this.netname, FILE_READ);
			if (this.cnt < 0) this.cnt = fopen(strcat("gfx/", mi_shortname, "_radar.tga"), FILE_READ);
			if (this.cnt < 0) this.cnt = fopen(strcat("gfx/", mi_shortname, "_radar.png"), FILE_READ);
			if (this.cnt < 0) this.cnt = fopen(strcat("gfx/", mi_shortname, "_radar.jpg"), FILE_READ);
			if (this.cnt < 0) this.cnt = fopen(strcat("gfx/", mi_shortname, "_mini.tga"), FILE_READ);
			if (this.cnt < 0) this.cnt = fopen(strcat("gfx/", mi_shortname, "_mini.png"), FILE_READ);
			if (this.cnt < 0) this.cnt = fopen(strcat("gfx/", mi_shortname, "_mini.jpg"), FILE_READ);
			if (this.cnt >= 0)
			{
				fclose(this.cnt);

				LOG_INFO(this.netname, " already exists, aborting (you may want to specify --force)");
				RadarMap_Next();
				return;
			}
		}
		this.cnt = fopen(this.netname, FILE_WRITE);
		if (this.cnt < 0)
		{
			LOG_INFO("Error writing ", this.netname);
			delete(this);
			radarmapper = NULL;
			return;
		}
		LOG_INFO("Writing to ", this.netname, "...");
		fputs(this.cnt, "/* XPM */\n");
		fputs(this.cnt, "static char *RadarMap[] = {\n");
		fputs(this.cnt, "/* columns rows colors chars-per-pixel */\n");
		fputs(this.cnt, strcat("\"", ftos(this.size.x), " ", ftos(this.size.y), " 256 2\",\n"));
		for (i = 0; i < 256; ++i)
		{
			si = substring(doublehex, i * 2, 2);
			fputs(this.cnt, strcat("\"", si, " c #", si, si, si, "\",\n"));
		}
		this.frame += 1;
		this.nextthink = time;
		sharpen_init(this.size.x);
	}
	else if (this.frame <= this.size.y)
	{
		// fill the sharpen buffer with this line
		sharpen_shift(this.size.x);
		i = this.count & 24;

		switch (i)
		{
			case 0:
			default:
				for (x = 0; x < this.size.x; ++x)
				{
					l = RadarMapAtPoint_Block(this.mins.x + x * this.maxs.x, this.mins.y + (this.size.y - this.frame) * this.maxs.y, this.maxs.x, this.maxs.y, this.mins.z, this.maxs.z, this.size.z);
					sharpen_set(x, l);
				}
				break;
			case 8:
				for (x = 0; x < this.size.x; ++x)
				{
					l = RadarMapAtPoint_Trace(this.mins.x + x * this.maxs.x, this.mins.y + (this.size.y - this.frame) * this.maxs.y, this.maxs.x, this.maxs.y, this.mins.z, this.maxs.z, this.size.z);
					sharpen_set(x, l);
				}
				break;
			case 16:
				for (x = 0; x < this.size.x; ++x)
				{
					l = RadarMapAtPoint_Sample(this.mins.x + x * this.maxs.x, this.mins.y + (this.size.y - this.frame) * this.maxs.y, this.maxs.x, this.maxs.y, this.mins.z, this.maxs.z, this.size.z);
					sharpen_set(x, l);
				}
				break;
			case 24:
				for (x = 0; x < this.size.x; ++x)
				{
					l = RadarMapAtPoint_LineBlock(this.mins.x + x * this.maxs.x, this.mins.y + (this.size.y - this.frame) * this.maxs.y, this.maxs.x, this.maxs.y, this.mins.z, this.maxs.z, this.size.z);
					sharpen_set(x, l);
				}
				break;
		}

		// do we have enough lines?
		if (this.frame >= 2)
		{
			// write a pixel line
			fputs(this.cnt, "\"");
			for (x = 0; x < this.size.x; ++x)
			{
				l = sharpen_get(x, this.ltime);
				fputs(this.cnt, substring(doublehex, 2 * floor(l * 256.0), 2));
			}
			if (this.frame == this.size.y)
			{
				fputs(this.cnt, "\"\n");
			}
			else
			{
				fputs(this.cnt, "\",\n");
				LOG_INFO(ftos(this.size.y - this.frame), " lines left");
			}
		}

		// is this the last line? then write back the missing line
		if (this.frame == this.size.y)
		{
			sharpen_shift(this.size.x);
			// write a pixel line
			fputs(this.cnt, "\"");
			for (x = 0; x < this.size.x; ++x)
			{
				l = sharpen_get(x, this.ltime);
				fputs(this.cnt, substring(doublehex, 2 * floor(l * 256.0), 2));
			}
			if (this.frame == this.size.y)
			{
				fputs(this.cnt, "\"\n");
			}
			else
			{
				fputs(this.cnt, "\",\n");
				LOG_INFO(ftos(this.size.y - this.frame), " lines left");
			}
		}

		this.frame += 1;
		this.nextthink = time;
	}
	else
	{
		// close the file
		fputs(this.cnt, "};\n");
		fclose(this.cnt);
		LOG_INFO("Finished. Please edit data/", this.netname, " with an image editing application and place it in the TGA format in the gfx folder.");
		RadarMap_Next();
	}
}

bool RadarMap_Make(int argc)
{
	float i;

	if (!radarmapper)
	{
		radarmapper = new(radarmapper);
		setthink(radarmapper, RadarMap_Think);
		radarmapper.nextthink = time;
		radarmapper.count = 8;  // default to the --trace method, as it is faster now
		radarmapper.ltime = 1;
		radarmapper.size = '512 512 1';
		for (i = 1; i < argc; ++i)
		{
			switch (argv(i))
			{
				case "--force":
				{ radarmapper.count |= 1;
				  break;
				}
				case "--loop":
				{ radarmapper.count |= 2;
				  break;
				}
				case "--quit":
				{ radarmapper.count |= 4;
				  break;
				}
				case "--block":
				{ radarmapper.count &= ~24;
				  break;
				}
				case "--trace":
				{ radarmapper.count &= ~24;
				  radarmapper.count |= 8;
				  break;
				}
				case "--sample":
				{ radarmapper.count &= ~24;
				  radarmapper.count |= 16;
				  break;
				}
				case "--lineblock":
				{ radarmapper.count |= 24;
				  break;
				}
				case "--flags":
				{ ++i;
				  radarmapper.count = stof(argv(i));
				  break;
				}  // for the recursive call
				case "--sharpen":
				{ ++i;
				  radarmapper.ltime = stof(argv(i));
				  break;
				}  // for the recursive call
				case "--res":  // minor alias
				case "--resolution":
				{ ++i;
				  radarmapper.size_x = stof(argv(i));
				  ++i;
				  radarmapper.size_y = stof(argv(i));
				  break;
				}
				case "--qual":  // minor alias
				case "--quality":
				{ ++i;
				  radarmapper.size_z = stof(argv(i));
				  break;
				}

				default:
					i = argc;
					delete(radarmapper);
					radarmapper = NULL;
					break;
			}
		}

		if (radarmapper)  // after doing the arguments, see if we successfully went forward.
		{
			LOG_INFO("Radarmap entity spawned.");
			return true;  // if so, don't print usage.
		}
	}

	return false;
}
#endif
