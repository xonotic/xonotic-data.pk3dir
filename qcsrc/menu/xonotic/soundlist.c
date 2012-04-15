#ifdef INTERFACE
CLASS(XonoticSoundList) EXTENDS(XonoticListBox)
	METHOD(XonoticSoundList, configureXonoticSoundList, void(entity))
	ATTRIB(XonoticSoundList, rowsPerItem, float, 1)
	METHOD(XonoticSoundList, resizeNotify, void(entity, vector, vector, vector, vector))
	METHOD(XonoticSoundList, drawListBoxItem, void(entity, float, vector, float))
	METHOD(XonoticSoundList, getSounds, void(entity))
	METHOD(XonoticSoundList, stopSound, void(entity))
	METHOD(XonoticSoundList, startSound, void(entity, float))
	METHOD(XonoticSoundList, pauseSound, void(entity))
	METHOD(XonoticSoundList, soundName, string(entity, float))
	METHOD(XonoticSoundList, clickListBoxItem, void(entity, float, vector))
	METHOD(XonoticSoundList, keyDown, float(entity, float, float, float))
	METHOD(XonoticSoundList, destroy, void(entity))
	METHOD(XonoticSoundList, showNotify, void(entity))

	ATTRIB(XonoticSoundList, listSound, float, -1)
	ATTRIB(XonoticSoundList, realFontSize, vector, '0 0 0')
	ATTRIB(XonoticSoundList, columnNameOrigin, float, 0)
	ATTRIB(XonoticSoundList, columnNameSize, float, 0)
	ATTRIB(XonoticSoundList, realUpperMargin, float, 0)
	ATTRIB(XonoticSoundList, origin, vector, '0 0 0')
	ATTRIB(XonoticSoundList, itemAbsSize, vector, '0 0 0')

	ATTRIB(XonoticSoundList, lastClickedSound, float, -1)
	ATTRIB(XonoticSoundList, lastClickedTime, float, 0)
	ATTRIB(XonoticSoundList, filterString, string, string_null)
ENDCLASS(XonoticSoundList)

entity makeXonoticSoundList();
void StopSound_Click(entity btn, entity me);
void StartSound_Click(entity btn, entity me);
void PauseSound_Click(entity btn, entity me);
void PrevSound_Click(entity btn, entity me);
void NextSound_Click(entity btn, entity me);
void SoundList_Filter_Change(entity box, entity me);
#endif

#ifdef IMPLEMENTATION

entity makeXonoticSoundList()
{
	entity me;
	me = spawnXonoticSoundList();
	me.configureXonoticSoundList(me);
	return me;
}

void XonoticSoundList_configureXonoticSoundList(entity me)
{
	me.configureXonoticListBox(me);
	me.getSounds(me);
}

string XonoticSoundList_soundName(entity me, float i )
{
	string s;
	s = search_getfilename(me.listSound, i);
	s = substring(s, 15, strlen(s) - 15 - 4);  // sound/cdtracks/, .ogg
	return s;
}


void XonoticSoundList_getSounds(entity me)
{
	string s;
	float i;

	if(me.filterString)
		//subdirectory in filterString allowed
		s=strcat("sound/cdtracks/*", me.filterString, "*.ogg");
	else
		s="sound/cdtracks/*.ogg";

	if(me.listSound >= 0)
		search_end(me.listSound);

	me.listSound = search_begin(s, FALSE, TRUE);

	if(me.listSound < 0)
		me.nItems=0;
	else
		me.nItems=search_getsize(me.listSound);

	cvar_set("music_playlist_list0", "");
	s = "";
	for(i=0; i<me.nItems; ++i)
	{
		cvar_set("music_playlist_list0", strcat(cvar_string("music_playlist_list0"), me.soundName(me,i), " "));
	}
}

void XonoticSoundList_destroy(entity me)
{
	search_end(me.listSound);
}

void XonoticSoundList_resizeNotify(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
{
	me.itemAbsSize = '0 0 0';
	SUPER(XonoticSoundList).resizeNotify(me, relOrigin, relSize, absOrigin, absSize);

	me.realFontSize_y = me.fontSize / (me.itemAbsSize_y = (absSize_y * me.itemHeight));
	me.realFontSize_x = me.fontSize / (me.itemAbsSize_x = (absSize_x * (1 - me.controlWidth)));
	me.realUpperMargin = 0.5 * (1 - me.realFontSize_y);

	me.columnNameOrigin = me.realFontSize_x;
	me.columnNameSize = 1 - 2 * me.realFontSize_x;
}

void XonoticSoundList_drawListBoxItem(entity me, float i, vector absSize, float isSelected)
{
	string s;
	if(isSelected)
		draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED);

	if(cvar("music_playlist_current0") == i)
	{
		float f = cvar("music_playlist_sampleposition0");
		if(f == 0 || (((time * 2) & 1) && f > 0))
			s = ">";
		draw_Text(me.realUpperMargin * eY, s, me.realFontSize, '1 1 1', SKINALPHA_TEXT, 0);
	}

	s = me.soundName(me,i);
	s = draw_TextShortenToWidth(s, me.columnNameSize, 0, me.realFontSize);
	draw_Text(me.realUpperMargin * eY + me.columnNameOrigin * eX, s, me.realFontSize, '1 1 1', SKINALPHA_TEXT, 0);
}

void XonoticSoundList_showNotify(entity me)
{
	me.getSounds(me);
}

void SoundList_Filter_Change(entity box, entity me)
{
	if(me.filterString)
		strunzone(me.filterString);

	if(box.text != "")
		me.filterString = strzone(box.text);
	else
		me.filterString = string_null;

	me.getSounds(me);
}

void XonoticSoundList_stopSound(entity me)
{
	// STOP: list 0 is disabled by setting the index to 999
	// we set sampleposition0 to -1 to indicate that music is stopped
	cvar_set("music_playlist_index", "999");
	localcmd("wait; music_playlist_sampleposition0 -1\n");
}

void StopSound_Click(entity btn, entity me)
{
	me.stopSound(me);
}

void XonoticSoundList_startSound(entity me, float offset)
{
	float f;
	if(offset)
	{
		f = bound(0, cvar("music_playlist_current0") + offset, me.nItems - 1);
		if(f == cvar("music_playlist_current0"))
			return;
	}
	else
		f = me.selectedItem;
	// START: list 0 is disabled by setting the index to 999
	// we set current0 to the selected track and sampleposition0 to 0 to forget value saved by the engine
	// then we switch back to list 0
	cvar_set("music_playlist_index", "999");
	cvar_set("music_playlist_current0", ftos(f));
	localcmd("wait; music_playlist_sampleposition0 0; wait; music_playlist_index 0\n");
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

void XonoticSoundList_pauseSound(entity me)
{
	// PAUSE: list 0 is disabled by setting the index to 999
	// (we know the track is paused because the engine sets sampleposition0 to remember current position)
	// RESUME: list 0 is enabled by setting the index to 0
	// (we reset sampleposition0 to 0 to mark the track as in playing back state)
	if(cvar("music_playlist_index") == 0)
		localcmd("music_playlist_index 999");
	else
		localcmd("music_playlist_index 0; wait; music_playlist_sampleposition0 0\n");
}

void PauseSound_Click(entity btn, entity me)
{
	me.pauseSound(me);
}

void XonoticSoundList_clickListBoxItem(entity me, float i, vector where)
{
	if(i == me.lastClickedSound)
		if(time < me.lastClickedTime + 0.3)
		{
			// DOUBLE CLICK!
			me.setSelected(me, i);
			me.startSound(me, 0);
		}
	me.lastClickedSound = i;
	me.lastClickedTime = time;
}

float XonoticSoundList_keyDown(entity me, float scan, float ascii, float shift)
{
	if(scan == K_ENTER || scan == K_KP_ENTER) {
		me.startSound(me, 0);
		return 1;
	}
	else if(scan == K_SPACE) {
		me.pauseSound(me);
		return 1;
	}
	else
		return SUPER(XonoticSoundList).keyDown(me, scan, ascii, shift);
}
#endif

