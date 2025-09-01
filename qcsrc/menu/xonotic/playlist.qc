#include "playlist.qh"

entity makeXonoticPlayList()
{
	entity me;
	me = NEW(XonoticPlayList);
	me.configureXonoticPlayList(me);
	return me;
}

void XonoticPlayList_configureXonoticPlayList(entity me)
{
	me.nItems = tokenize_console(cvar_string("music_playlist_list0"));
	me.configureXonoticListBox(me);
}

void XonoticPlayList_resizeNotify(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
{
	me.itemAbsSize = '0 0 0';
	SUPER(XonoticPlayList).resizeNotify(me, relOrigin, relSize, absOrigin, absSize);

	me.itemAbsSize.y = absSize.y * me.itemHeight;
	me.itemAbsSize.x = absSize.x * (1 - me.controlWidth);
	me.realFontSize.y = me.fontSize / me.itemAbsSize.y;
	me.realFontSize.x = me.fontSize / me.itemAbsSize.x;
	me.realUpperMargin = 0.5 * (1 - me.realFontSize.y);

	me.columnNumberOrigin = 0;
	me.columnNumberSize = 3 * me.realFontSize.x;

	me.columnNameOrigin = me.columnNumberSize + me.realFontSize.x;
	me.columnNameSize = 1 - me.columnNameOrigin - me.realFontSize.x;
}

void XonoticPlayList_addToPlayList(entity me, string track)
{
	me.nItems = tokenize_console(cvar_string("music_playlist_list0"));
	if(me.nItems == 0)
	{
		cvar_set("music_playlist_list0", track);
		return;
	}
	float i;
	for(i = 0; i < me.nItems; ++i)
	{
		if(argv(i) == track)
			return; // track is already in playlist
	}
	cvar_set("music_playlist_list0", strcat(cvar_string("music_playlist_list0"), " ", track));
}

void XonoticPlayList_removeSelectedFromPlayList(entity me)
{
	float i, cpt = false;
	string s = "";
	me.nItems = tokenize_console(cvar_string("music_playlist_list0"));
	if(me.nItems == 0)
		return;
	for(i = 0; i < me.nItems; ++i)
	{
		if(i == me.selectedItem)
		{
			if(i == me.nItems - 1)
				me.setSelected(me, me.selectedItem - 1);
			if(cvar("music_playlist_index") == 0 || cvar("music_playlist_index") == 999)
			{
				if(cvar("music_playlist_current0") == i)
					cpt = true; // current playing track (we can't start next track here because startSound calls tokenize_console)
				else if(cvar("music_playlist_current0") > i)
					cvar_set("music_playlist_current0", ftos(cvar("music_playlist_current0") - 1));
			}
			continue;
		}
		s = strcat(s, " ", argv(i));
	}
	// we must stop the current playing track if it has been removed
	// otherwise pause/play button will resume from another track
	if(s == "")
	{
		cvar_set("music_playlist_list0", "");
		if(cpt)
			me.stopSound(me);
	}
	else
	{
		cvar_set("music_playlist_list0", substring(s, 1, strlen(s))); // remove initial space
		if(cpt)
			me.startSound(me, 0);
	}
}

void PlayList_Remove(entity btn, entity me)
{
	me.removeSelectedFromPlayList(me);
}

void PlayList_Remove_All(entity btn, entity me)
{
	cvar_set("music_playlist_list0", "");
	me.stopSound(me);
	me.selectedItem = 0;
}

float XonoticPlayList_mouseDrag(entity me, vector pos)
{
	float f, i;
	i = me.selectedItem;
	f = SUPER(XonoticPlayList).mouseDrag(me, pos);

	if(me.pressed != 1) // don't change priority if the person is just scrolling
	{
		if(me.selectedItem != i)
		{
			cvar_set("music_playlist_list0", swapInPriorityList(cvar_string("music_playlist_list0"), me.selectedItem, i));
			float c = cvar("music_playlist_current0");
			if(c == i)
				cvar_set("music_playlist_current0", ftos(me.selectedItem));
			else if(c == me.selectedItem)
				cvar_set("music_playlist_current0", ftos(i));
		}
	}

	return f;
}

void XonoticPlayList_draw(entity me)
{
	me.nItems = tokenize_console(cvar_string("music_playlist_list0"));
	if(cvar("music_playlist_index") == 0 || cvar("music_playlist_index") == 999)
		me.playingTrack = cvar("music_playlist_current0");
	else
		me.playingTrack = -1;
	SUPER(XonoticPlayList).draw(me);
}

void XonoticPlayList_drawListBoxItem(entity me, int i, vector absSize, bool isSelected, bool isFocused)
{
	string s;
	if(isSelected)
		draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED);
	else if(isFocused)
	{
		me.focusedItemAlpha = getFadedAlpha(me.focusedItemAlpha, SKINALPHA_LISTBOX_FOCUSED, SKINFADEALPHA_LISTBOX_FOCUSED);
		draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_FOCUSED, me.focusedItemAlpha);
	}

	if(i == me.playingTrack)
	{
		float f = cvar("music_playlist_sampleposition0");
		// display Play symbol: Unicode char U+25B6: Black Right-Pointing Triangle
		if(f <= 0 || (((time * 2) & 1) && f > 0))
			draw_Text(me.realUpperMargin * eY + (me.columnNumberOrigin + me.columnNumberSize) * eX, "\xE2\x96\xB6", me.realFontSize, '1 1 1', SKINALPHA_TEXT, 0);
	}

	s = ftos(i+1);
	draw_CenterText(me.realUpperMargin * eY + (me.columnNumberOrigin + 0.5 * me.columnNumberSize) * eX, s, me.realFontSize, '1 1 1', SKINALPHA_TEXT, 0);

	s = draw_TextShortenToWidth(argv(i), me.columnNameSize, 0, me.realFontSize);
	draw_Text(me.realUpperMargin * eY + me.columnNameOrigin * eX, s, me.realFontSize, '1 1 1', SKINALPHA_TEXT, 0);
}

void XonoticPlayList_stopSound(entity me)
{
	// STOP: list 0 is disabled by setting the index to -1
	// we set sampleposition0 to 0 to forget the position that the engine saves in this frame (for this reason we need to wait a frame)
	if(cvar("music_playlist_index") == 0 || cvar("music_playlist_index") == 999)
	{
		cvar_set("music_playlist_index", "-1");
		localcmd("\nwait; music_playlist_sampleposition0 0\n");
		localcmd("\ndefer 3 \"cd play $menu_cdtrack\"\n");
	}
}

void StopSound_Click(entity btn, entity me)
{
	me.stopSound(me);
}

void XonoticPlayList_startSound(entity me, float offset)
{
	float f;
	me.nItems = tokenize_console(cvar_string("music_playlist_list0"));
	if(offset)
	{
		if(cvar("music_playlist_index") == -1)
			return;
		f = bound(0, cvar("music_playlist_current0") + offset, me.nItems - 1);
		if(f == cvar("music_playlist_current0"))
			return;
	}
	else
	{
		f = me.selectedItem;
		// if it was paused then resume
		if(f == cvar("music_playlist_current0"))
		if(cvar("music_playlist_index") == 999)
		{
			me.resumeSound(me);
			return;
		}
		// if it was not paused then proceed with restart
	}

	// START: list 0 is disabled by setting the index to 999
	// we set current0 to the selected track and sampleposition0 to 0 to forget the position that the engine saves in this frame (for this reason we need to wait a frame)
	// then we switch back to list 0
	cvar_set("music_playlist_index", "999");
	cvar_set("music_playlist_current0", ftos(f));
	localcmd("\nwait; music_playlist_sampleposition0 0; wait; music_playlist_index 0\n");
}

void StartSound_Click(entity btn, entity me)
{
	me.startSound(me, 0);
}

void PrevSound_Click(entity btn, entity me)
{
	me.startSound(me, -1);
}

void NextSound_Click(entity btn, entity me)
{
	me.startSound(me, +1);
}

void XonoticPlayList_resumeSound(entity me)
{
	// RESUME: list 0 is enabled by setting the index to 0
	// (we reset sampleposition0 to 0 to mark the track as in playing back state)
	if(cvar("music_playlist_index") == 999)
		localcmd("\nmusic_playlist_index 0; wait; music_playlist_sampleposition0 0\n");
}
void XonoticPlayList_pauseSound(entity me)
{
	// PAUSE: list 0 is disabled by setting the index to 999
	// (we know the track is paused because the engine sets sampleposition0 to remember current position)
	if(cvar("music_playlist_index") == 0)
		localcmd("\nmusic_playlist_index 999\n");
	else me.resumeSound(me);
}

void PauseSound_Click(entity btn, entity me)
{
	me.pauseSound(me);
}

void XonoticPlayList_doubleClickListBoxItem(entity me, float i, vector where)
{
	me.startSound(me, 0);
}

float XonoticPlayList_keyDown(entity me, float scan, float ascii, float shift)
{
	if (scan == K_ENTER || scan == K_KP_ENTER || ((shift & S_CTRL) && scan == K_MOUSE1))
	{
		me.startSound(me, 0);
		return 1;
	}
	else if (scan == K_SPACE)
	{
		me.pauseSound(me);
		return 1;
	}
	else if (scan == K_DEL || scan == K_KP_DEL || scan == K_BACKSPACE || scan == K_MOUSE3
		|| ascii == '-')
	{
		me.removeSelectedFromPlayList(me);
		return 1;
	}
	else
		return SUPER(XonoticPlayList).keyDown(me, scan, ascii, shift);
}
