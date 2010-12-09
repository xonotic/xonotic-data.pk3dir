float playerstats_db;
string playerstats_last;
string events_last;
.float playerstats_addedglobalinfo;
float playerstats_requested;

void PlayerStats_Init()
{
	string uri;
	playerstats_db = -1;
	playerstats_waitforme = TRUE;
	uri = autocvar_g_playerstats_uri;
	if(uri == "")
		return;
	playerstats_db = db_create();
	if(playerstats_db >= 0)
		playerstats_waitforme = FALSE; // must wait for it at match end
	
	PlayerStats_AddEvent(PLAYERSTATS_ALIVETIME);
	PlayerStats_AddEvent(PLAYERSTATS_KILLS);
}

void PlayerStats_AddPlayer(entity e)
{
	if(!e.crypto_idfp || playerstats_db < 0)
		return;
	
	string key;
	key = sprintf("%s:*", e.crypto_idfp);
	
	string p;
	p = db_get(playerstats_db, key);
	if(p == "")
	{
		if(playerstats_last)
		{
			db_put(playerstats_db, key, playerstats_last);
			strunzone(playerstats_last);
		}
		else
			db_put(playerstats_db, key, "#");
		playerstats_last = strzone(e.crypto_idfp);
	}
}

void PlayerStats_AddEvent(string event_id)
{
	if(playerstats_db < 0)
		return;
	
	string key;
	key = sprintf("*:%s", event_id);
	
	string p;
	p = db_get(playerstats_db, key);
	if(p == "")
	{
		if(events_last)
		{
			db_put(playerstats_db, key, events_last);
			strunzone(events_last);
		}
		else
			db_put(playerstats_db, key, "#");
		events_last = strzone(event_id);
	}
}

void PlayerStats_Event(entity e, string event_id, float value)
{
	if(!e.crypto_idfp || playerstats_db < 0)
		return;
	
	string key;
	float val;
	key = sprintf("%s:%s", e.crypto_idfp, event_id);
	val = stof(db_get(playerstats_db, key));
	val += value;
	db_put(playerstats_db, key, ftos(val));
}

void PlayerStats_Sent_URI_Get_Callback(float id, float status, string data)
{
	if(playerstats_requested)
		playerstats_waitforme = TRUE;
}

void PlayerStats_Shutdown()
{
	string p, pn;
	string e, en;
	string nn;
	float b;
	float i;
	string uri;

	if(playerstats_db < 0)
		return;

	uri = autocvar_g_playerstats_uri;
	if(uri != "")
	{
		b = buf_create();
		i = 0;

		db_dump(playerstats_db, "foo.db");

		bufstr_set(b, i++, "V 1");
		bufstr_set(b, i++, sprintf("T %s.%06d", strftime(FALSE, "%s"), floor(random() * 1000000)));
		bufstr_set(b, i++, sprintf("G %s", GetGametype()));
		bufstr_set(b, i++, sprintf("M %s", GetMapname()));
		for(p = playerstats_last; (pn = db_get(playerstats_db, sprintf("%s:*", p))) != ""; p = pn)
		{
			bufstr_set(b, i++, sprintf("P %s", p));
			nn = db_get(playerstats_db, sprintf("%s:_netname", p));
			if(nn != "")
				bufstr_set(b, i++, sprintf("n %s", nn));
			for(e = events_last; (en = db_get(playerstats_db, sprintf("*:%s", e))) != ""; e = en)
			{
				float v;
				v = stof(db_get(playerstats_db, sprintf("%s:%s", p, e)));
				bufstr_set(b, i++, sprintf("e %s %f", e, v));
			}
		}
		bufstr_set(b, i++, "");

		if(crypto_uri_postbuf(uri, URI_GET_PLAYERSTATS_SENT, "text/plain", "\n", b, 0))
			playerstats_requested = TRUE;
		else
			playerstats_waitforme = TRUE; // if posting fails, we must continue anyway

		buf_del(b);
	}
	else
		playerstats_waitforme = TRUE;

	db_close(playerstats_db);
	playerstats_db = -1;
}

void PlayerStats_AddGlobalInfo(entity p)
{
	if(playerstats_db < 0)
		return;
	if(!p.crypto_idfp || playerstats_db < 0)
		return;
	p.playerstats_addedglobalinfo = TRUE;

	// add global info!
	if(p.alivetime)
		PlayerStats_Event(p, PLAYERSTATS_ALIVETIME, time - p.alivetime);
	
	if(p.cvar_cl_allow_uid2name == 1)
		db_put(playerstats_db, sprintf("%s:_netname", p.crypto_idfp), p.netname);
}
