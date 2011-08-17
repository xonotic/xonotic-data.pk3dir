// files (-1 for URL)
.float url_fh;

// URLs
.string url_url;
.float url_wbuf;
.float url_wbufpos;
.float url_rbuf;
.float url_rbufpos;
.float url_id;
.url_ready_func url_ready;
.entity url_ready_pass;

entity url_fromid[NUM_URL_ID];
float autocvar__urllib_nextslot;

float url_URI_Get_Callback(float id, float status, string data)
{
	if(id < MIN_URL_ID)
		return 0;
	id -= MIN_URL_ID;
	if(id >= NUM_URL_ID)
		return 0;
	entity e;
	e = url_fromid[id];
	if(!e)
		return 0;
	if(e.url_rbuf >= 0 || e.url_wbuf >= 0)
	{
		print(sprintf("WARNING: handle %d (%s) has already received data?!?\n", id + NUM_URL_ID, e.url_url));
		return 0;
	}

	// whatever happens, we will remove the URL from the list of IDs
	url_fromid[id] = world;

	if(status == 0)
	{
		// WE GOT DATA!
		float n, i;
		n = tokenizebyseparator(data, "\n");
		e.url_rbuf = buf_create();
		e.url_rbufpos = 0;
		if(e.url_rbuf < 0)
		{
			print("buf_create: out of memory\n");
			e.url_ready(e, e.url_ready_pass, URL_READY_ERROR);
			strunzone(e.url_url);
			remove(e);
		}
		for(i = 0; i < n; ++i)
			bufstr_set(e.url_rbuf, i, argv(i));
		e.url_ready(e, e.url_ready_pass, URL_READY_CANREAD);
		return 1;
	}
	else
	{
		// an ERROR
		e.url_ready(e, e.url_ready_pass, -status);
		strunzone(e.url_url);
		remove(e);
		return 1;
	}
}

void url_fopen(string url, float mode, url_ready_func rdy, entity pass)
{
	entity e;
	float i;
	if(strstrofs(url, "://", 0) >= 0)
	{
		switch(mode)
		{
			case FILE_WRITE:
			case FILE_APPEND:
				// collect data to a stringbuffer for a POST request
				// attempts to close will result in a reading handle
				e = spawn();
				e.classname = "url_fopen_file";
				e.url_url = strzone(url);
				e.url_fh = -1;
				e.url_wbuf = buf_create();
				if(e.url_wbuf < 0)
				{
					print("buf_create: out of memory\n");
					rdy(e, pass, URL_READY_ERROR);
					strunzone(e.url_url);
					remove(e);
					return;
				}
				e.url_wbufpos = 0;
				e.url_rbuf = -1;
				rdy(e, pass, URL_READY_CANWRITE);
				break;

			case FILE_READ:
				// read data only
				for(i = autocvar__urllib_nextslot; i < NUM_URL_ID; ++i)
					if(url_fromid[i] == world)
						break;
				if(i >= NUM_URL_ID)
				{
					for(i = 0; i < autocvar__urllib_nextslot; ++i)
						if(url_fromid[i] == world)
							break;
					if(i >= autocvar__urllib_nextslot)
					{
						rdy(world, pass, URL_READY_ERROR);
						return;
					}
				}

				e = spawn();
				e.classname = "url_fopen_file";
				e.url_url = strzone(url);
				e.url_fh = -1;
				e.url_rbuf = -1;
				e.url_wbuf = -1;
				if(!uri_get(url, i + MIN_URL_ID))
				{
					rdy(e, pass, URL_READY_ERROR);
					strunzone(e.url_url);
					remove(e);
					return;
				}
				e.url_ready = rdy;
				e.url_ready_pass = pass;
				e.url_id = i;
				url_fromid[i] = e;
				cvar_set("_urllib_nextslot", ftos(mod(i + 1, NUM_URL_ID)));
				break;
		}
	}
	else
	{
		float fh;
		fh = fopen(url, mode);
		if(fh < 0)
		{
			rdy(world, pass, URL_READY_ERROR);
			return;
		}
		else
		{
			e = spawn();
			e.classname = "url_fopen_file";
			e.url_fh = fh;
			if(mode == FILE_READ)
				rdy(e, pass, URL_READY_CANREAD);
			else
				rdy(e, pass, URL_READY_CANWRITE);
		}
	}
}

void url_fclose(entity e, url_ready_func rdy, entity pass)
{
	float i;

	if(e.url_fh < 0)
	{
		if(e.url_wbuf >= 0)
		{
			for(i = autocvar__urllib_nextslot; i < NUM_URL_ID; ++i)
				if(url_fromid[i] == world)
					break;
			if(i >= NUM_URL_ID)
			{
				for(i = 0; i < autocvar__urllib_nextslot; ++i)
					if(url_fromid[i] == world)
						break;
				if(i >= autocvar__urllib_nextslot)
				{
					buf_del(e.url_wbuf);
					rdy(e, pass, URL_READY_ERROR);
					strunzone(e.url_url);
					remove(e);
					return;
				}
			}
			print(ftos(i), "\n");

			if(!uri_postbuf(e.url_url, i + MIN_URL_ID, "text/plain", "", e.url_wbuf))
			{
				buf_del(e.url_wbuf);
				rdy(e, pass, URL_READY_ERROR);
				strunzone(e.url_url);
				remove(e);
				return;
			}

			buf_del(e.url_wbuf);
			e.url_wbuf = -1;
			e.url_ready = rdy;
			e.url_ready_pass = pass;
			e.url_id = i;
			url_fromid[i] = e;
			cvar_set("_urllib_nextslot", ftos(mod(i + 1, NUM_URL_ID)));
		}
		else
		{
			// we have READ all data
			rdy(e, pass, URL_READY_CLOSED);
			buf_del(e.url_rbuf);
			strunzone(e.url_url);
			remove(e);
		}
	}
	else
	{
		// file
		fclose(e.url_fh);
		rdy(e, pass, URL_READY_CLOSED); // closing creates no reading handle
		remove(e);
	}
}

// with \n
string url_fgets(entity e)
{
	if(e.url_fh < 0)
	{
		// curl
		string s;
		s = bufstr_get(e.url_rbuf, e.url_rbufpos);
		e.url_rbufpos += 1;
		return s;
	}
	else
	{
		// file
		return fgets(e.url_fh);
	}
}

// without \n
void url_fputs(entity e, string s)
{
	if(e.url_fh < 0)
	{
		// curl
		bufstr_set(e.url_wbuf, e.url_wbufpos, s);
		e.url_wbufpos += 1;
	}
	else
	{
		// file
		fputs(e.url_fh, s);
	}
}
