float playerstats_db;
string playerstats_last;
string events_last;
.float playerstats_addedglobalinfo;
float playerstats_requested;
.string playerstats_id;

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
	PlayerStats_AddEvent(PLAYERSTATS_WINS);
	PlayerStats_AddEvent(PLAYERSTATS_MATCHES);
	PlayerStats_AddEvent(PLAYERSTATS_JOINS);
	PlayerStats_AddEvent(PLAYERSTATS_SCOREBOARD_VALID);

	PlayerStats_AddEvent(PLAYERSTATS_ACHIEVEMENT_KILL_SPREE_3);
	PlayerStats_AddEvent(PLAYERSTATS_ACHIEVEMENT_KILL_SPREE_5);
	PlayerStats_AddEvent(PLAYERSTATS_ACHIEVEMENT_KILL_SPREE_10);
	PlayerStats_AddEvent(PLAYERSTATS_ACHIEVEMENT_KILL_SPREE_15);
	PlayerStats_AddEvent(PLAYERSTATS_ACHIEVEMENT_KILL_SPREE_20);
	PlayerStats_AddEvent(PLAYERSTATS_ACHIEVEMENT_KILL_SPREE_25);
	PlayerStats_AddEvent(PLAYERSTATS_ACHIEVEMENT_KILL_SPREE_30);
	PlayerStats_AddEvent(PLAYERSTATS_ACHIEVEMENT_BOTLIKE);
	PlayerStats_AddEvent(PLAYERSTATS_ACHIEVEMENT_FIRSTBLOOD);
	PlayerStats_AddEvent(PLAYERSTATS_ACHIEVEMENT_FIRSTVICTIM);
}

void PlayerStats_AddPlayer(entity e)
{
	if(playerstats_db < 0)
		return;

	if(e.crypto_idfp != "" && e.cvar_cl_allow_uidtracking == 1)
		e.playerstats_id = strzone(e.crypto_idfp);
	else if(clienttype(e) == CLIENTTYPE_BOT)
		e.playerstats_id = strzone(sprintf("bot#%d", e.playerid));
	else
		e.playerstats_id = strzone(sprintf("player#%d", e.playerid));
	
	string key;
	key = sprintf("%s:*", e.playerstats_id);
	
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
		playerstats_last = strzone(e.playerstats_id);
	}
}

void PlayerStats_AddTeam(float t)
{
	if(playerstats_db < 0)
		return;

	string key;
	key = sprintf("team#%d:*", t);
	
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
		playerstats_last = strzone(sprintf("team%d", t));
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
	if(!e.playerstats_id || playerstats_db < 0)
		return;
	
	string key;
	float val;
	key = sprintf("%s:%s", e.playerstats_id, event_id);
	val = stof(db_get(playerstats_db, key));
	val += value;
	db_put(playerstats_db, key, ftos(val));
}

void PlayerStats_TeamScore(float t, string event_id, float value)
{
	string key;
	float val;
	key = sprintf("team#%d:%s", t, event_id);
	val = stof(db_get(playerstats_db, key));
	val += value;
	db_put(playerstats_db, key, ftos(val));
}

void PlayerStats_Sent_URI_Get_Callback(float id, float status, string data)
{
	if(playerstats_requested)
		playerstats_waitforme = TRUE;
}

/*
	format spec:

	A collection of lines of the format <key> SPACE <value> NEWLINE, where
	<key> is always a single character.

	The following keys are defined:

	V: format version (always 1)
	T: time at which the game ended
	G: game type
	M: map name
	S: "hostname" of the server
	C: number of "unpure" cvar changes
	P: player ID of an existing player; this also sets the owner for all following "n" and "e" lines (lower case!)
	n: nickname of the player (optional)
	e: followed by an event name, a space, and the event count/score
		event names can be:
			alivetime: total playing time of the player
			wins: number of games won (can only be set if matches is set)
			matches: number of matches played to the end (not aborted by map switch)
			joins: number of matches joined (always 1 unless player never played during the match)
			scoreboardvalid: set to 1 if the player was there at the end of the match
			total-<scoreboardname>: total score of that scoreboard item
			scoreboard-<scoreboardname>: end-of-game score of that scoreboard item (can differ in non-team games)
			achievement-<achievementname>: achievement counters
*/

//#NO AUTOCVARS START
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
		bufstr_set(b, i++, sprintf("S %s", cvar_string("hostname")));
		bufstr_set(b, i++, sprintf("C %d", cvar_purechanges_count));
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
				if(v != 0)
					bufstr_set(b, i++, sprintf("e %s %g", e, v));
			}
		}
		bufstr_set(b, i++, "");

		if(autocvar_g_playerstats_debug)
		{
			for(i = 0; i < buf_getsize(b); ++i)
				print(bufstr_get(b, i), "\n");
		}

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
//#NO AUTOCVARS END

void PlayerStats_AddGlobalInfo(entity p)
{
	if(playerstats_db < 0)
		return;
	if(!p.playerstats_id || playerstats_db < 0)
		return;
	p.playerstats_addedglobalinfo = TRUE;

	// add global info!
	if(p.alivetime)
		PlayerStats_Event(p, PLAYERSTATS_ALIVETIME, time - p.alivetime);

	if(p.alivetime)
		PlayerStats_Event(p, PLAYERSTATS_ALIVETIME, time - p.alivetime);
	
	if(p.cvar_cl_allow_uid2name == 1 || clienttype(p) == CLIENTTYPE_BOT)
		db_put(playerstats_db, sprintf("%s:_netname", p.playerstats_id), p.netname);

	if(p.alivetime > 0)
		PlayerStats_Event(p, PLAYERSTATS_JOINS, 1);

	strunzone(p.playerstats_id);
	p.playerstats_id = string_null;
}

void PlayerStats_EndMatch(float finished)
{
	entity p;
	FOR_EACH_PLAYER(p)
	{
		PlayerScore_PlayerStats(p);
		PlayerStats_Event(p, PLAYERSTATS_SCOREBOARD_VALID, 1);
		if(finished)
		{
			PlayerStats_Event(p, PLAYERSTATS_WINS, p.winning);
			PlayerStats_Event(p, PLAYERSTATS_MATCHES, 1);
		}
	}
}
