#include "net.qh"

#ifdef SVQC
entity mapvote_ent;

void MapVote_TouchMask()
{
	mapvote_ent.SendFlags |= BIT(1);
}

void MapVote_TouchVotes(entity voter)
{
	mapvote_ent.SendFlags |= BIT(2);
}

void MapVote_Winner(int mappos)
{
	mapvote_ent.SendFlags |= BIT(3);
	mv_winner_time = time;
	mv_winner = mappos;
}
#endif

#ifdef CSQC
void MapVote_SendChoice(int index)
{
	TC(int, index);
	localcmd("\nimpulse ", ftos(index + 1), "\n");
}
#endif

#ifdef SVQC
void MapVote_WriteMask()
{
	int i;
	if (mv_count < 24)
	{
		int mask = 0;
		for (i = 0; i < mv_count; ++i)
			if (mv_flags[i] & GTV_AVAILABLE)
				mask |= BIT(i);

		if (mv_count < 8)
			WriteByte(MSG_ENTITY, mask);
		else if (mv_count < 16)
			WriteShort(MSG_ENTITY,mask);
		else
			WriteLong(MSG_ENTITY, mask);
	}
	else
	{
		for (i = 0; i < mv_count; ++i)
			WriteByte(MSG_ENTITY, mv_flags[i]);
	}
}
#elifdef CSQC
void MapVote_ReadMask()
{
	int i;
	if (mv_count < 24)
	{
		int mask;
		if (mv_count < 8)
			mask = ReadByte();
		else if (mv_count < 16)
			mask = ReadShort();
		else
			mask = ReadLong();

		for (i = 0; i < mv_count; ++i)
		{
			if (mask & BIT(i))
				mv_flags[i] |= GTV_AVAILABLE;
			else
				mv_flags[i] &= ~GTV_AVAILABLE;
		}
	}
	else
	{
		for (i = 0; i < mv_count; ++i)
			mv_flags[i] = ReadByte();
	}
}
#endif

#ifdef SVQC
// Sends a single map vote option to the client
void MapVote_SendOption(int i)
{
	// abstain
	if (mv_abstain && i == mv_count - 1)
	{
		WriteString(MSG_ENTITY, ""); // abstain needs no text
		WriteString(MSG_ENTITY, ""); // abstain needs no pack
		WriteString(MSG_ENTITY, ""); // abstain has no suggester
		WriteByte(MSG_ENTITY, 0); // abstain needs no screenshot dir
	}
	else
	{
		WriteString(MSG_ENTITY, mv_entries[i]);
		WriteString(MSG_ENTITY, mv_pakfile[i]);
		WriteString(MSG_ENTITY, mv_show_suggester ? mv_suggester[i] : "");
		WriteByte(MSG_ENTITY, mv_ssdir_i[i]);
	}
}
#elifdef CSQC
void MapVote_ReadOption(int i)
{
	TC(int, i);

	mv_entries[i] = strzone(ReadString());
	mv_data[i] = strzone(ReadString());
	mv_suggester[i] = strzone(ReadString());
	mv_flags[i] = GTV_AVAILABLE;
	const int j = bound(0, ReadByte(), mv_ssdirs_count - 1);

	mv_pics[i] = strzone(strcat(mv_ssdirs[j], "/", mv_entries[i]));
	mv_preview[i] = false;
	MapVote_CheckPic(mv_pics[i], mv_data[i], i);
}
#endif

#ifdef SVQC
// Sends a single gametype vote option to the client
void GameTypeVote_SendOption(int i)
{
	// abstain
	if (mv_abstain && i == mv_count - 1)
	{
		WriteString(MSG_ENTITY, ""); // abstain needs no text
		WriteByte(MSG_ENTITY, GTV_AVAILABLE);
	}
	else
	{
		const string type_name = mv_entries[i];
		WriteString(MSG_ENTITY, type_name);
		WriteByte(MSG_ENTITY, mv_flags[i]);
		if (mv_flags[i] & GTV_CUSTOM)
		{
			WriteString(MSG_ENTITY, cvar_string(
				strcat("sv_vote_gametype_", type_name, "_name")));
			WriteString(MSG_ENTITY, cvar_string(
				strcat("sv_vote_gametype_", type_name, "_description")));
			WriteString(MSG_ENTITY, cvar_string(
				strcat("sv_vote_gametype_", type_name, "_type")));
		}
	}
}
#elifdef CSQC
void GameTypeVote_ReadOption(int i)
{
	TC(int, i);

	mv_entries[i] = strzone(ReadString());
	mv_flags[i] = ReadByte();
	mv_suggester[i] = "";

	string basetype = "";

	if (mv_flags[i] & GTV_CUSTOM)
	{
		string name = ReadString();
		if (strlen(name) < 1)
			name = mv_entries[i];
		mv_data[i] = strzone(name);
		mv_desc[i] = strzone(ReadString());
		basetype = strzone(ReadString());
	}
	else
	{
		const Gametype type = MapInfo_Type_FromString(mv_entries[i], false, false);
		mv_data[i] = strzone(MapInfo_Type_ToText(type));
		mv_desc[i] = MapInfo_Type_Description(type);
	}

	string mv_picpath = sprintf("gfx/menu/%s/gametype_%s", autocvar_menu_skin, mv_entries[i]);
	if (precache_pic(mv_picpath) == "")
	{
		mv_picpath = strcat("gfx/menu/wickedx/gametype_", mv_entries[i]);
		if (precache_pic(mv_picpath) == "")
		{
			mv_picpath = sprintf("gfx/menu/%s/gametype_%s", autocvar_menu_skin, basetype);
			if (precache_pic(mv_picpath) == "")
				mv_picpath = strcat("gfx/menu/wickedx/gametype_", basetype);
		}
	}
	mv_pics[i] = strzone(mv_picpath);
	mv_preview[i] = PreviewExists(mv_pics[i]);
}
#endif

#ifdef CSQC
void MapVote_Init()
{
	mv_active = true;
	if (!autocvar_hud_cursormode)
		mousepos = (eX * vid_conwidth + eY * vid_conheight) * 0.5;
	mv_selection = -1;
	mv_selection_keyboard = false;

	string s;
	for (mv_ssdirs_count = 0; ; ++mv_ssdirs_count)
	{
		s = ReadString();
		if (s == "")
			break;
		if (mv_ssdirs_count < MAPVOTE_SSDIRS_COUNT)
			mv_ssdirs[mv_ssdirs_count] = s;
	}
	mv_ssdirs_count = min(mv_ssdirs_count, MAPVOTE_SSDIRS_COUNT);

	mv_count_real = mv_count = min(MAPVOTE_COUNT, ReadByte());
	mv_abstain = boolean(ReadByte());
	if (mv_abstain)
		--mv_count_real;
	mv_detail = ReadByte();

	mv_suggester_cache = "";
	mv_suggester_cachetime = 0;

	mv_ownvote = -1;
	mv_timeout = ReadCoord();

	const int gametypevote_flags = ReadByte();
	gametypevote = boolean(gametypevote_flags & BIT(0));
	if (gametypevote_flags)
		mv_chosenmap = strzone(ReadString());

	MapVote_ReadMask();
	int i;
	for (i = 0; i < mv_count; ++i)
		mv_flags_start[i] = mv_flags[i];

	// Assume mv_pk3list is NULL, there should only be 1 mapvote per round
	mv_pk3list = NULL; // I'm still paranoid!

	for (i = 0; i < mv_count; ++i)
	{
		mv_votes[i] = 0;
		mv_select_lasttime[i] = 0;

		if (gametypevote)
			GameTypeVote_ReadOption(i);
		else
			MapVote_ReadOption(i);
	}

	for (i = 0; i < mv_ssdirs_count; ++i)
		mv_ssdirs[mv_ssdirs_count] = string_null;
	mv_ssdirs_count = 0;
}

void MapVote_UpdateMask()
{
	MapVote_ReadMask();
	mv_reduce_time = time;
}

void MapVote_UpdateVotes()
{
	for (int i = 0; i < mv_count; ++i)
	{
		if (mv_flags[i] & GTV_AVAILABLE)
		{
			if (mv_detail)
				mv_votes[i] = ReadByte();
			else
				mv_votes[i] = 0;
		}
		else
			mv_votes[i] = -1;
	}
	if (mv_detail)
		mv_tie_winner = ReadChar();

	mv_ownvote = ReadByte() - 1;
}
#endif // CSQC

#ifdef SVQC
bool MapVote_SendEntity(entity this, entity to, int sf)
{
	int i;

	if (sf & BIT(0))
		sf &= ~BIT(1); // if we send 1, we don't need to also send 2
	if (!mv_winner_time)
		sf &= ~BIT(3); // no winner yet

	WriteHeader(MSG_ENTITY, ENT_CLIENT_MAPVOTE);
	WriteByte(MSG_ENTITY, sf);

	if (sf & BIT(0))
	{
		// flag 1 == initialization
		for (i = 0; i < mv_ssdirs_count; ++i)
			WriteString(MSG_ENTITY, mv_ssdirs[i]);
		WriteString(MSG_ENTITY, "");
		WriteByte(MSG_ENTITY, mv_count);
		WriteByte(MSG_ENTITY, mv_abstain);
		WriteByte(MSG_ENTITY, mv_detail);
		WriteCoord(MSG_ENTITY, mv_timeout);

		if (gametypevote)
		{
			// gametype vote
			WriteByte(MSG_ENTITY, BIT(0)); // gametypevote_flags
			WriteString(MSG_ENTITY, get_nextmap());
		}
		else if (autocvar_sv_vote_gametype)
		{
			// map vote but gametype has been chosen via voting screen
			WriteByte(MSG_ENTITY, BIT(1)); // gametypevote_flags
			const string voted_gametype_name = (voted_gametype_string == MapInfo_Type_ToString(voted_gametype))
				? MapInfo_Type_ToText(voted_gametype)
				: cvar_string(strcat("sv_vote_gametype_", voted_gametype_string, "_name"));
			WriteString(MSG_ENTITY, voted_gametype_name);
		}
		else
			WriteByte(MSG_ENTITY, 0); // map vote

		MapVote_WriteMask();

		// Send data for the vote options
		for (i = 0; i < mv_count; ++i)
		{
			if (gametypevote)
				GameTypeVote_SendOption(i);
			else
				MapVote_SendOption(i);
		}
	}

	if (sf & BIT(1)) // flag 2 == update of mask
		MapVote_WriteMask();

	if (sf & BIT(2))
	{
		if (mv_detail)
		{
			for (i = 0; i < mv_count; ++i)
				if (mv_flags[i] & GTV_AVAILABLE)
					WriteByte(MSG_ENTITY, mv_votes[i]);

			if (mv_detail == 2) // tell the client who the tie winner will be
				WriteChar(MSG_ENTITY, mv_ranked[0]);
			else if (mv_votes[mv_ranked[0]] == 0) // no votes yet, don't draw a winner (-1)
				WriteChar(MSG_ENTITY, -1);
			else // figure out winners yourself (-2)
				WriteChar(MSG_ENTITY, -2);
		}

		WriteByte(MSG_ENTITY, to.mapvote);
	}

	if (sf & BIT(3))
		WriteByte(MSG_ENTITY, mv_winner + 1);

	return true;
}

void MapVote_Spawn()
{
	Net_LinkEntity(mapvote_ent = new(mapvote_ent), false, 0, MapVote_SendEntity);
}
#elifdef CSQC
NET_HANDLE(ENT_CLIENT_MAPVOTE, bool isnew)
{
	make_pure(this);
	const int sf = ReadByte();
	return = true;

	if (sf & BIT(0))
		MapVote_Init();
	if (sf & BIT(1))
		MapVote_UpdateMask();
	if (sf & BIT(2))
		MapVote_UpdateVotes();
	if (sf & BIT(3))
	{
		mv_winner = ReadByte();
		mv_winner_time = time;
	}
}
#endif

#ifdef SVQC
void MapVote_SendPicture(entity to, int id)
{
	msg_entity = to;
	WriteHeader(MSG_ONE, TE_CSQC_PICTURE);
	WriteByte(MSG_ONE, id);
	WritePicture(MSG_ONE, strcat(mv_ssdirs[mv_ssdir_i[id]], "/", mv_entries[id]), 3072);
}
#elifdef CSQC
NET_HANDLE(TE_CSQC_PICTURE, bool isNew)
{
	Net_MapVote_Picture();
	return true;
}

void Net_MapVote_Picture()
{
	const int type = ReadByte();
	mv_preview[type] = true;
	mv_pics[type] = strzone(ReadPicture());
}
#endif
