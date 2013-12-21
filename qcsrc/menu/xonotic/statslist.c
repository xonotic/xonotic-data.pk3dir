#ifdef INTERFACE
CLASS(XonoticStatsList) EXTENDS(XonoticListBox)
	METHOD(XonoticStatsList, configureXonoticStatsList, void(entity))
	ATTRIB(XonoticStatsList, rowsPerItem, float, 1.25)
	METHOD(XonoticStatsList, resizeNotify, void(entity, vector, vector, vector, vector))
	METHOD(XonoticStatsList, drawListBoxItem, void(entity, float, vector, float))
	METHOD(XonoticStatsList, getStats, void(entity))
	METHOD(XonoticStatsList, clickListBoxItem, void(entity, float, vector))
	METHOD(XonoticStatsList, keyDown, float(entity, float, float, float))
	METHOD(XonoticStatsList, destroy, void(entity))
	METHOD(XonoticStatsList, showNotify, void(entity))

	ATTRIB(XonoticStatsList, listStats, float, -1)
	ATTRIB(XonoticStatsList, realFontSize, vector, '0 0 0')
	ATTRIB(XonoticStatsList, columnNameOrigin, float, 0)
	ATTRIB(XonoticStatsList, columnNameSize, float, 0)
	ATTRIB(XonoticStatsList, realUpperMargin, float, 0)
	ATTRIB(XonoticStatsList, origin, vector, '0 0 0')
	ATTRIB(XonoticStatsList, itemAbsSize, vector, '0 0 0')

	ATTRIB(XonoticStatsList, lastClickedDemo, float, -1)
	ATTRIB(XonoticStatsList, lastClickedTime, float, 0)
	ATTRIB(XonoticStatsList, filterString, string, string_null)
ENDCLASS(XonoticStatsList)

entity statslist; // for reference elsewhere
entity makeXonoticStatsList();
#endif

#ifdef IMPLEMENTATION

entity makeXonoticStatsList()
{
	entity me;
	me = spawnXonoticStatsList();
	me.configureXonoticStatsList(me);
	return me;
}

void XonoticStatsList_configureXonoticStatsList(entity me)
{
	me.configureXonoticListBox(me);
	me.getStats(me);
}

void XonoticStatsList_getStats(entity me)
{
	if (me.listStats >= 0)
		buf_del(me.listStats);
	me.listStats = buf_create();
	if (me.listStats < 0)
	{
		me.nItems = 0;
		return;
	}
	
	string e = "", en = "";
	float i = 0;
	for(e = PS_D_IN_EVL; (en = db_get(PS_D_IN_DB, e)) != ""; e = en)
	{
		++i;
		bufstr_add(me.listStats, sprintf("%d:%s:%s\n", i, e, db_get(PS_D_IN_DB, sprintf("#%s", e))), TRUE);
	}
	
	me.nItems = buf_getsize(me.listStats);
	if(me.nItems > 0)
		buf_sort(me.listStats, 128, FALSE);
}

void XonoticStatsList_destroy(entity me)
{
	if(me.nItems > 0)
		buf_del(me.listStats);
}

void XonoticStatsList_resizeNotify(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
{
	me.itemAbsSize = '0 0 0';
	SUPER(XonoticStatsList).resizeNotify(me, relOrigin, relSize, absOrigin, absSize);

	me.realFontSize_y = me.fontSize / (me.itemAbsSize_y = (absSize_y * me.itemHeight));
	me.realFontSize_x = me.fontSize / (me.itemAbsSize_x = (absSize_x * (1 - me.controlWidth)));
	me.realUpperMargin = 0.5 * (1 - me.realFontSize_y);

	me.columnNameOrigin = me.realFontSize_x;
	me.columnNameSize = 1 - 2 * me.realFontSize_x;
}

void XonoticStatsList_drawListBoxItem(entity me, float i, vector absSize, float isSelected)
{
	string s;
	if(isSelected)
		draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED);

	s = bufstr_get(me.listStats, i);
	s = draw_TextShortenToWidth(s, me.columnNameSize, 0, me.realFontSize);
	draw_Text(me.realUpperMargin * eY + (me.columnNameOrigin + 0.00 * (me.columnNameSize - draw_TextWidth(s, 0, me.realFontSize))) * eX, s, me.realFontSize, '1 1 1', SKINALPHA_TEXT, 1);
}

void XonoticStatsList_showNotify(entity me)
{
	me.getStats(me);
}

void XonoticStatsList_clickListBoxItem(entity me, float i, vector where)
{
	if(i == me.lastClickedDemo)
		if(time < me.lastClickedTime + 0.3)
		{
			// DOUBLE CLICK!
			me.setSelected(me, i);
			//DemoConfirm_ListClick_Check_Gamestatus(me);
		}
	me.lastClickedDemo = i;
	me.lastClickedTime = time;
}

float XonoticStatsList_keyDown(entity me, float scan, float ascii, float shift)
{
	if(scan == K_ENTER || scan == K_KP_ENTER)
	{
		//DemoConfirm_ListClick_Check_Gamestatus(me);
		return 1;
	}
	else
	{
		return SUPER(XonoticStatsList).keyDown(me, scan, ascii, shift);
	}
}
#endif

