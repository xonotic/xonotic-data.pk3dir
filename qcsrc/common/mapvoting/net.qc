#include "net.qh"

#ifdef CSQC
void MapVote_SendChoice(int index)
{
	TC(int, index);
	localcmd("\nimpulse ", itos(index + 1), "\n");
}
#endif

#ifdef SVQC
void MapVote_WriteMask()
{
	for (int b, B, i = 0; i < mv_count_real; )
	{
		B = 0;
		for (b = BIT(0); b < BIT(8) && i < mv_count_real; b <<= 1, ++i)
			if (mv_flags[i] & GTV_AVAILABLE)
				B |= b;
		WriteByte(MSG_ENTITY, B);
	}
}
#elifdef CSQC
void MapVote_ReadMask()
{
	int b, B, i;
	for (i = 0; i < mv_count_real; )
		for (B = ReadByte(), b = BIT(0); b < BIT(8) && i < mv_count_real; b <<= 1, ++i)
		{
			if (B & b)
				mv_flags[i] |= GTV_AVAILABLE;
			else
				mv_flags[i] &= ~GTV_AVAILABLE;
		}
	if (mv_abstain) // make abstain available
		mv_flags[mv_count_real] |= GTV_AVAILABLE;
}
#endif

#ifdef SVQC
/// Sends a single map vote option to the client
void MapVote_WriteOption(int i)
{
	WriteString(MSG_ENTITY, mv_entries[i]);
	WriteString(MSG_ENTITY, mv_pakfile[i]);
	WriteString(MSG_ENTITY, mv_show_suggester ? mv_suggester[i] : "");
	WriteByte(MSG_ENTITY, mv_ssdir_i[i]);
}
#elifdef CSQC
void MapVote_ReadOption(int i)
{
	TC(int, i);
	mv_entries[i] = strzone(ReadString());
	mv_data[i] = strzone(ReadString());
	mv_suggester[i] = strzone(ReadString());
	mv_flags[i] = GTV_AVAILABLE;

	mv_pics[i] = strzone(strcat(mv_ssdirs[ReadByte()], "/", mv_entries[i]));
	mv_preview[i] = false;
	MapVote_CheckPic(mv_pics[i], mv_data[i], i);
}
#endif

#ifdef SVQC
/// Sends a single gametype vote option to the client
void GameTypeVote_WriteOption(int i)
{
	string type_name = mv_entries[i];
	WriteString(MSG_ENTITY, type_name);
	WriteByte(MSG_ENTITY, mv_flags[i]);
	if (mv_flags[i] & GTV_CUSTOM)
	{
		WriteString(MSG_ENTITY, cvar_string(strcat("sv_vote_gametype_", type_name, "_name")));
		WriteString(MSG_ENTITY, cvar_string(strcat("sv_vote_gametype_", type_name, "_description")));
		WriteString(MSG_ENTITY, cvar_string(strcat("sv_vote_gametype_", type_name, "_type")));
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
		Gametype type = MapInfo_Type_FromString(mv_entries[i], false, false);
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

#ifdef SVQC
void MapVote_WriteInit()
{
	int i;

	WriteByte(MSG_ENTITY, mv_ssdirs_count);
	for (i = 0; i < mv_ssdirs_count; ++i)
		WriteString(MSG_ENTITY, mv_ssdirs[i]);
	WriteByte(MSG_ENTITY, mv_count);
	WriteFloat(MSG_ENTITY, mv_timeout);

	if (gametypevote)
	{
		WriteByte(MSG_ENTITY, SF_MV_GTV_NOW); // gametypevote_flags: gametype vote
		WriteString(MSG_ENTITY, get_nextmap());
	}
	else if (autocvar_sv_vote_gametype)
	{
		WriteByte(MSG_ENTITY, SF_MV_GTV_DONE); // gametypevote_flags: map vote but gametype has been chosen via voting screen
		string voted_gametype_name = (voted_gametype_string == MapInfo_Type_ToString(voted_gametype))
			? MapInfo_Type_ToText(voted_gametype)
			: cvar_string(strcat("sv_vote_gametype_", voted_gametype_string, "_name"));
		WriteString(MSG_ENTITY, voted_gametype_name);
	}
	else
		WriteByte(MSG_ENTITY, SF_MV_GTV_MAPS); // gametypevote_flags: map vote

	MapVote_WriteMask();

	// Send data for the vote options
	void(int) WriteOption = (gametypevote ? GameTypeVote_WriteOption : MapVote_WriteOption);
	for (i = 0; i < mv_count_real; ++i)
		WriteOption(i);
}
#elifdef CSQC
void MapVote_ReadInit(int sf)
{
	mv_active = true;
	if (!autocvar_hud_cursormode)
		mousepos = (eX * vid_conwidth + eY * vid_conheight) * 0.5;
	mv_selection = -1;
	mv_selection_keyboard = false;

	string s;
	int i;
	mv_ssdirs_count = ReadByte(); // will be < MAPVOTE_SSDIRS_COUNT
	for (i = 0; i < mv_ssdirs_count; ++i)
		mv_ssdirs[i] = ReadString();

	mv_count_real = mv_count = ReadByte(); // will be < MAPVOTE_COUNT

	mv_abstain = boolean(sf & SF_MV_ABSTAIN);
	if (mv_abstain)
		--mv_count_real;
	mv_detail = (sf & SF_MV_DETAIL_WINNER) ? 2 : ((sf & SF_MV_DETAIL_COUNTS) ? 1 : 0);

	mv_suggester_cache = "";
	mv_suggester_cachetime = 0;

	mv_ownvote = -1;
	mv_timeout = ReadFloat();

	int gametypevote_flags = ReadByte();
	gametypevote = (gametypevote_flags == SF_MV_GTV_NOW);
	if (gametypevote_flags != SF_MV_GTV_MAPS)
		mv_chosenmap = strzone(ReadString());

	MapVote_ReadMask();
	for (i = 0; i < mv_count; ++i)
		mv_flags_start[i] = mv_flags[i];

	// Assume mv_pk3list is NULL, there should only be 1 mapvote per round
	mv_pk3list = NULL; // I'm still paranoid!

	void(int) ReadOption = (gametypevote ? GameTypeVote_ReadOption : MapVote_ReadOption);
	for (i = 0; i < mv_count_real; ++i)
	{
		mv_votes[i] = 0;
		mv_select_lasttime[i] = 0;
		ReadOption(i);
	}
	if (mv_abstain)
		mv_entries[mv_count_real] = "";

	for (i = 0; i < mv_ssdirs_count; ++i)
		mv_ssdirs[mv_ssdirs_count] = string_null;
	mv_ssdirs_count = 0;
}
#endif

#ifdef SVQC
bool MapVote_SendEntity(entity this, entity to, int sf)
{
	int i;
	if (!mv_winner_time)
		sf &= ~SF_MV_WINNER; // no winner yet

	// Pack some extra data into sf
	sf &= ~(SF_MV_ABSTAIN | SF_MV_DETAIL_COUNTS | SF_MV_DETAIL_WINNER);
	if (mv_abstain)
		sf |= SF_MV_ABSTAIN;
	if (mv_detail == 1)
		sf |= SF_MV_DETAIL_COUNTS;
	else if (mv_detail == 2)
		sf |= SF_MV_DETAIL_WINNER;

	WriteHeader(MSG_ENTITY, ENT_CLIENT_MAPVOTE);
	WriteByte(MSG_ENTITY, sf);
	if (sf & SF_MV_INIT)
		MapVote_WriteInit();
	else if (sf & SF_MV_MASK) // else if, since init already writes the mask
		MapVote_WriteMask();

	if (sf & SF_MV_VOTES)
	{
		if (mv_detail)
		{
			int i;
			for (i = 0; i < mv_count; ++i)
				if (mv_flags[i] & GTV_AVAILABLE)
					WriteByte(MSG_ENTITY, mv_votes[i]);

			if (mv_detail == 2) // tell the client what the tie winner will be
				i = mv_ranked[0];
			else if (mv_votes[mv_ranked[0]] == 0) // no votes yet, don't draw a winner (-1)
				i = -1;
			else // figure out winners yourself (-2)
				i = -2;
			WriteByte(MSG_ENTITY, i + 2);
		}

		WriteByte(MSG_ENTITY, to.mapvote);
	}

	if (sf & SF_MV_WINNER)
		WriteByte(MSG_ENTITY, mv_winner + 1);

	return true;
}

void MapVote_Spawn()
{
	Net_LinkEntity(mapvote_ent = new(mapvote_ent), false, 0, MapVote_SendEntity);
}
#elifdef CSQC
NET_HANDLE(ENT_CLIENT_MAPVOTE, bool isNew)
{
	int sf = ReadByte();

	if (sf & SF_MV_INIT)
		MapVote_ReadInit(sf);
	else if (sf & SF_MV_MASK)
	{
		MapVote_ReadMask();
		mv_reduce_time = time;
	}

	if (sf & SF_MV_VOTES)
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
			mv_tie_winner = ReadByte() - 2;

		mv_ownvote = ReadByte() - 1;
	}

	if (sf & SF_MV_WINNER)
	{
		mv_winner = ReadByte();
		mv_winner_time = time;
	}

	return true;
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
	int type = ReadByte();
	mv_preview[type] = true;
	mv_pics[type] = strzone(ReadPicture());
	return true;
}
#endif
