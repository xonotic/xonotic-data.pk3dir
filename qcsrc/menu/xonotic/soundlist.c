#ifdef INTERFACE
CLASS(XonoticSoundList) EXTENDS(XonoticListBox)
	METHOD(XonoticSoundList, configureXonoticSoundList, void(entity))
	ATTRIB(XonoticSoundList, rowsPerItem, float, 1)
	METHOD(XonoticSoundList, resizeNotify, void(entity, vector, vector, vector, vector))
	METHOD(XonoticSoundList, drawListBoxItem, void(entity, float, vector, float))
	METHOD(XonoticSoundList, getSounds, void(entity))
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
	ATTRIB(XonoticSoundList, playlist, entity, world)
ENDCLASS(XonoticSoundList)

entity makeXonoticSoundList();
void SoundList_Filter_Change(entity box, entity me);
void SoundList_Menu_Track_Change(entity box, entity me);
void SoundList_Menu_Track_Reset(entity box, entity me);
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

	if(me.filterString)
		//subdirectory in filterString allowed
		s = strcat("sound/cdtracks/*", me.filterString, "*.ogg");
	else
		s = "sound/cdtracks/*.ogg";

	if(me.listSound >= 0)
		search_end(me.listSound);

	me.listSound = search_begin(s, FALSE, TRUE);

	if(me.listSound < 0)
		me.nItems=0;
	else
		me.nItems=search_getsize(me.listSound);
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

	s = me.soundName(me,i);
	if(s == cvar_defstring("menu_cdtrack"))
		s = strcat(s, " [default menu track]");
	else if(s == cvar_string("menu_cdtrack"))
		s = strcat(s, " [current menu track]");
	s = draw_TextShortenToWidth(s, me.columnNameSize, 0, me.realFontSize);
	draw_Text(me.realUpperMargin * eY + me.columnNameOrigin * eX, s, me.realFontSize, '1 1 1', SKINALPHA_TEXT, 0);
}

void XonoticSoundList_showNotify(entity me)
{
	me.getSounds(me);
}

void SoundList_Menu_Track_Change(entity box, entity me)
{
	cvar_set("menu_cdtrack", me.soundName(me,me.selectedItem));
}

void SoundList_Menu_Track_Reset(entity box, entity me)
{
	cvar_set("menu_cdtrack", cvar_defstring("menu_cdtrack"));
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

void XonoticSoundList_clickListBoxItem(entity me, float i, vector where)
{
	if(i == me.lastClickedSound)
		if(time < me.lastClickedTime + 0.3)
		{
			// DOUBLE CLICK!
			me.setSelected(me, i);
			me.playlist.addToPlayList(me.playlist, me.soundName(me, i));
		}
	me.lastClickedSound = i;
	me.lastClickedTime = time;
}

float XonoticSoundList_keyDown(entity me, float scan, float ascii, float shift)
{
	if(scan == K_ENTER || scan == K_KP_ENTER || scan == K_SPACE) {
		me.playlist.addToPlayList(me.playlist, me.soundName(me, me.selectedItem));
		return 1;
	}
	else if(scan == K_DEL || scan == K_KP_DEL) {
		me.playlist.removeFromPlayList(me.playlist, me.soundName(me, me.selectedItem));
		return 1;
	}
	else
		return SUPER(XonoticSoundList).keyDown(me, scan, ascii, shift);
}
#endif

