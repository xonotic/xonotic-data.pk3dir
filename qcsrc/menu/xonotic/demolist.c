#ifdef INTERFACE
CLASS(XonoticDemoList) EXTENDS(XonoticListBox)
	METHOD(XonoticDemoList, configureXonoticDemoList, void(entity))
	ATTRIB(XonoticDemoList, rowsPerItem, float, 1)
	METHOD(XonoticDemoList, resizeNotify, void(entity, vector, vector, vector, vector))
	METHOD(XonoticDemoList, drawListBoxItem, void(entity, float, vector, float))
	METHOD(XonoticDemoList, getDemos, void(entity))
	METHOD(XonoticDemoList, startDemo, void(entity))
	METHOD(XonoticDemoList, timeDemo, void(entity))
	METHOD(XonoticDemoList, demoName, string(entity, float))
	METHOD(XonoticDemoList, clickListBoxItem, void(entity, float, vector))
	METHOD(XonoticDemoList, keyDown, float(entity, float, float, float))
	METHOD(XonoticDemoList, destroy, void(entity))
	METHOD(XonoticDemoList, showNotify, void(entity))

	ATTRIB(XonoticDemoList, listDemo, float, -1)
	ATTRIB(XonoticDemoList, realFontSize, vector, '0 0 0')
	ATTRIB(XonoticDemoList, columnNameOrigin, float, 0)
	ATTRIB(XonoticDemoList, columnNameSize, float, 0)
	ATTRIB(XonoticDemoList, realUpperMargin, float, 0)
	ATTRIB(XonoticDemoList, origin, vector, '0 0 0')
	ATTRIB(XonoticDemoList, itemAbsSize, vector, '0 0 0')

	ATTRIB(XonoticDemoList, lastClickedDemo, float, -1)
	ATTRIB(XonoticDemoList, lastClickedTime, float, 0)
	ATTRIB(XonoticDemoList, filterString, string, string_null)
ENDCLASS(XonoticDemoList)

entity demolist; // for reference elsewhere
entity makeXonoticDemoList();
void DemoList_Refresh_Click(entity btn, entity me);
void DemoList_Filter_Change(entity box, entity me);
#endif

#ifdef IMPLEMENTATION

entity makeXonoticDemoList()
{
	entity me;
	me = spawnXonoticDemoList();
	me.configureXonoticDemoList(me);
	return me;
}

void XonoticDemoList_configureXonoticDemoList(entity me)
{
	me.configureXonoticListBox(me);
	me.getDemos(me);
}

string XonoticDemoList_demoName(entity me, float i)
{
	string s;
	s = bufstr_get(me.listDemo, i);

	if(substring(s, 0, 1) == "/")
		s = substring(s, 1, strlen(s) - 1);  // remove the first forward slash

	return s;
}

// if subdir is TRUE look in subdirectories too (1 level)
void getDemos_for_ext(entity me, string ext, float subdir)
{
	string s;
	if (subdir)
		s="demos/*/";
	else
		s="demos/";
	if(me.filterString)
		s=strcat(s, me.filterString, ext);
	else
		s=strcat(s, "*", ext);

	float list, i, n;
	list = search_begin(s, FALSE, TRUE);
	if(list >= 0)
	{
		n = search_getsize(list);
		for(i = 0; i < n; ++i)
		{
			s = search_getfilename(list, i); // get initial full file name
			s = substring(s, 6, (strlen(s) - 6 - 4)); // remove "demos/" prefix and ".dem" suffix
			s = strdecolorize(s); // remove any pre-existing colors
			if(subdir)
			{
				s = strreplace("/", "^7/", s); // clear colors at the forward slash
				s = strcat("/", rgb_to_hexcolor(SKINCOLOR_DEMOLIST_SUBDIR), s); // add a forward slash for sorting, then color
				bufstr_add(me.listDemo, s, TRUE);
			}
			else { bufstr_add(me.listDemo, s, TRUE); }
		}
		search_end(list);
	}

	if (subdir)
		getDemos_for_ext(me, ext, FALSE);
}

void XonoticDemoList_getDemos(entity me)
{
	if (me.listDemo >= 0)
		buf_del(me.listDemo);
	me.listDemo = buf_create();
	if (me.listDemo < 0)
	{
		me.nItems = 0;
		return;
	}
	getDemos_for_ext(me, ".dem", TRUE);
	me.nItems = buf_getsize(me.listDemo);
	if(me.nItems > 0)
		buf_sort(me.listDemo, 128, FALSE);
}

void XonoticDemoList_destroy(entity me)
{
	if(me.nItems > 0)
		buf_del(me.listDemo);
}

void XonoticDemoList_resizeNotify(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
{
	me.itemAbsSize = '0 0 0';
	SUPER(XonoticDemoList).resizeNotify(me, relOrigin, relSize, absOrigin, absSize);

	me.realFontSize_y = me.fontSize / (me.itemAbsSize_y = (absSize_y * me.itemHeight));
	me.realFontSize_x = me.fontSize / (me.itemAbsSize_x = (absSize_x * (1 - me.controlWidth)));
	me.realUpperMargin = 0.5 * (1 - me.realFontSize_y);

	me.columnNameOrigin = me.realFontSize_x;
	me.columnNameSize = 1 - 2 * me.realFontSize_x;
}

void XonoticDemoList_drawListBoxItem(entity me, float i, vector absSize, float isSelected)
{
	string s;
	if(isSelected)
		draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED);

	s = me.demoName(me,i);
	s = draw_TextShortenToWidth(s, me.columnNameSize, 0, me.realFontSize);
	draw_Text(me.realUpperMargin * eY + (me.columnNameOrigin + 0.00 * (me.columnNameSize - draw_TextWidth(s, 0, me.realFontSize))) * eX, s, me.realFontSize, SKINCOLOR_TEXT, SKINALPHA_TEXT, 1);
}

void XonoticDemoList_showNotify(entity me)
{
	me.getDemos(me);
}

void DemoList_Refresh_Click(entity btn, entity me)
{
	me.getDemos(me);
	me.setSelected(me, 0); //always select the first element after a list update
}

void DemoList_Filter_Change(entity box, entity me)
{
	if(me.filterString)
		strunzone(me.filterString);

	if(box.text != "")
	{
		if (strstrofs(box.text, "*", 0) >= 0 || strstrofs(box.text, "?", 0) >= 0)
			me.filterString = strzone(box.text);
		else
			me.filterString = strzone(strcat("*", box.text, "*"));
	}
	else
		me.filterString = string_null;

	me.getDemos(me);
}

void XonoticDemoList_startDemo(entity me)
{
	string s;
	s = me.demoName(me, me.selectedItem);
	s = strdecolorize(s);

	localcmd("playdemo \"demos/", s, ".dem\" \nwait \ntogglemenu\n");
}

void XonoticDemoList_timeDemo(entity me)
{
	string s;
	s = me.demoName(me, me.selectedItem);
	s = strdecolorize(s);

	localcmd("timedemo \"demos/", s, ".dem\" \nwait \ntogglemenu\n");
}

void DemoConfirm_ListClick_Check_Gamestatus(entity me)
{
	if(!(gamestatus & (GAME_CONNECTED | GAME_ISSERVER))) // we're not in a match, lets watch the demo
	{
		me.startDemo(me);
	}
	else // already in a match, player has to confirm
	{
		DialogOpenButton_Click_withCoords(
			me,
			main.demostartconfirmDialog,
			boxToGlobal(eY * (me.selectedItem * me.itemHeight - me.scrollPos), me.origin, me.size),
			boxToGlobalSize(eY * me.itemHeight + eX * (1 - me.controlWidth), me.size)
		);
	}
}

void XonoticDemoList_clickListBoxItem(entity me, float i, vector where)
{
	if(i == me.lastClickedDemo)
		if(time < me.lastClickedTime + 0.3)
		{
			// DOUBLE CLICK!
			me.setSelected(me, i);
			DemoConfirm_ListClick_Check_Gamestatus(me);
		}
	me.lastClickedDemo = i;
	me.lastClickedTime = time;
}

float XonoticDemoList_keyDown(entity me, float scan, float ascii, float shift)
{
	if(scan == K_ENTER || scan == K_KP_ENTER)
	{
		DemoConfirm_ListClick_Check_Gamestatus(me);
		return 1;
	}
	else
	{
		return SUPER(XonoticDemoList).keyDown(me, scan, ascii, shift);
	}
}
#endif

