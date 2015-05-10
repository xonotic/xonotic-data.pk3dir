#ifndef SCREENSHOTLIST_H
#define SCREENSHOTLIST_H
#include "listbox.qc"
CLASS(XonoticScreenshotList, XonoticListBox)
	METHOD(XonoticScreenshotList, configureXonoticScreenshotList, void(entity))
	ATTRIB(XonoticScreenshotList, rowsPerItem, float, 1)
	METHOD(XonoticScreenshotList, resizeNotify, void(entity, vector, vector, vector, vector))
	METHOD(XonoticScreenshotList, setSelected, void(entity, float))
	METHOD(XonoticScreenshotList, draw, void(entity))
	METHOD(XonoticScreenshotList, drawListBoxItem, void(entity, float, vector, float))
	METHOD(XonoticScreenshotList, getScreenshots, void(entity))
	METHOD(XonoticScreenshotList, previewScreenshot, void(entity))
	METHOD(XonoticScreenshotList, startScreenshot, void(entity))
	METHOD(XonoticScreenshotList, screenshotName, string(entity, float))
	METHOD(XonoticScreenshotList, doubleClickListBoxItem, void(entity, float, vector))
	METHOD(XonoticScreenshotList, keyDown, float(entity, float, float, float))
	METHOD(XonoticScreenshotList, destroy, void(entity))
	METHOD(XonoticScreenshotList, showNotify, void(entity))
	ATTRIB(XonoticScreenshotList, listScreenshot, float, -1)
	ATTRIB(XonoticScreenshotList, realFontSize, vector, '0 0 0')
	ATTRIB(XonoticScreenshotList, columnNameOrigin, float, 0)
	ATTRIB(XonoticScreenshotList, columnNameSize, float, 0)
	ATTRIB(XonoticScreenshotList, realUpperMargin, float, 0)
	ATTRIB(XonoticScreenshotList, origin, vector, '0 0 0')
	ATTRIB(XonoticScreenshotList, itemAbsSize, vector, '0 0 0')
	ATTRIB(XonoticScreenshotList, filterString, string, string_null)
	ATTRIB(XonoticScreenshotList, filterBox, entity, NULL)
	ATTRIB(XonoticScreenshotList, filterTime, float, 0)

	ATTRIB(XonoticScreenshotList, newScreenshotTime, float, 0)
	ATTRIB(XonoticScreenshotList, newSlideShowScreenshotTime, float, 0)
	ATTRIB(XonoticScreenshotList, prevSelectedItem, float, 0)

	ATTRIB(XonoticScreenshotList, screenshotBrowserDialog, entity, NULL)
	ATTRIB(XonoticScreenshotList, screenshotPreview, entity, NULL)
	ATTRIB(XonoticScreenshotList, screenshotViewerDialog, entity, NULL)
	METHOD(XonoticScreenshotList, goScreenshot, void(entity, float))
	METHOD(XonoticScreenshotList, startSlideShow, void(entity))
	METHOD(XonoticScreenshotList, stopSlideShow, void(entity))
ENDCLASS(XonoticScreenshotList)

entity makeXonoticScreenshotList();
void StartScreenshot_Click(entity btn, entity me);
void ScreenshotList_Refresh_Click(entity btn, entity me);
void ScreenshotList_Filter_Would_Change(entity box, entity me);
void ScreenshotList_Filter_Change(entity box, entity me);
#endif

#ifdef IMPLEMENTATION

entity makeXonoticScreenshotList()
{
	entity me;
	me = NEW(XonoticScreenshotList);
	me.configureXonoticScreenshotList(me);
	return me;
}

void XonoticScreenshotList_configureXonoticScreenshotList(entity me)
{
	me.configureXonoticListBox(me);
	me.getScreenshots(me);
}

string XonoticScreenshotList_screenshotName(entity me, float i)
{
	string s;
	s = bufstr_get(me.listScreenshot, i);

	if(substring(s, 0, 1) == "/")
		s = substring(s, 1, strlen(s) - 1);  // remove the first forward slash

	return s;
}

// if subdir is true look in subdirectories too (1 level)
void getScreenshots_for_ext(entity me, string ext, float subdir)
{
	string s;
	if (subdir)
		s="screenshots/*/";
	else
		s="screenshots/";
	if(me.filterString)
		s=strcat(s, me.filterString, ext);
	else
		s=strcat(s, "*", ext);

	float list, i, n;
	list = search_begin(s, false, true);
	if(list >= 0)
	{
		n = search_getsize(list);
		for(i = 0; i < n; ++i)
		{
			s = search_getfilename(list, i); // get initial full file name
			s = substring(s, 12, (strlen(s) - 12 - 4)); // remove "screenshots/" prefix and ".<ext>" suffix
			s = strdecolorize(s); // remove any pre-existing colors
			if(subdir)
			{
				s = strreplace("/", "^7/", s); // clear colors at the forward slash
				s = strcat("/", rgb_to_hexcolor(SKINCOLOR_SCREENSHOTLIST_SUBDIR), s); // add a forward slash for sorting, then color
				bufstr_add(me.listScreenshot, s, true);
			}
			else { bufstr_add(me.listScreenshot, s, true); }
		}
		search_end(list);
	}

	if (subdir)
		getScreenshots_for_ext(me, ext, false);
}

void XonoticScreenshotList_getScreenshots(entity me)
{
	if (me.listScreenshot >= 0)
		buf_del(me.listScreenshot);
	me.listScreenshot = buf_create();
	if (me.listScreenshot < 0)
	{
		me.nItems = 0;
		return;
	}
	getScreenshots_for_ext(me, ".jpg", true);
	getScreenshots_for_ext(me, ".tga", true);
	getScreenshots_for_ext(me, ".png", true);
	me.nItems = buf_getsize(me.listScreenshot);
	if(me.nItems > 0)
		buf_sort(me.listScreenshot, 128, false);
}

void XonoticScreenshotList_destroy(entity me)
{
	if(me.nItems > 0)
		buf_del(me.listScreenshot);
}

void XonoticScreenshotList_resizeNotify(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
{
	me.itemAbsSize = '0 0 0';
	SUPER(XonoticScreenshotList).resizeNotify(me, relOrigin, relSize, absOrigin, absSize);

	me.realFontSize_y = me.fontSize / (me.itemAbsSize_y = (absSize.y * me.itemHeight));
	me.realFontSize_x = me.fontSize / (me.itemAbsSize_x = (absSize.x * (1 - me.controlWidth)));
	me.realUpperMargin = 0.5 * (1 - me.realFontSize.y);

	me.columnNameOrigin = me.realFontSize.x;
	me.columnNameSize = 1 - 2 * me.realFontSize.x;
}

void XonoticScreenshotList_setSelected(entity me, float i)
{
	if (me.newSlideShowScreenshotTime)
		me.startSlideShow(me);
	me.prevSelectedItem = me.selectedItem;
	SUPER(XonoticScreenshotList).setSelected(me, i);
	if (me.pressed && me.selectedItem != me.prevSelectedItem)
	{
		// while dragging the scrollbar (or an item)
		// for a smooth mouse movement do not load immediately the new selected images
		me.newScreenshotTime = time + 0.22; // dragging an item we need a delay > 0.2 (from listbox: me.dragScrollTimer = time + 0.2;)
	}
	else if (time > me.newScreenshotTime)
	{
		me.newScreenshotTime = 0;
		me.previewScreenshot(me); // load the preview on selection change
	}
}

void XonoticScreenshotList_drawListBoxItem(entity me, float i, vector absSize, float isSelected)
{
	string s;
	if(isSelected)
		draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED);

	s = me.screenshotName(me,i);
	s = draw_TextShortenToWidth(s, me.columnNameSize, 0, me.realFontSize);
	draw_Text(me.realUpperMargin * eY + (me.columnNameOrigin + 0.00 * (me.columnNameSize - draw_TextWidth(s, 0, me.realFontSize))) * eX, s, me.realFontSize, '1 1 1', SKINALPHA_TEXT, 1);
}

void XonoticScreenshotList_showNotify(entity me)
{
	me.getScreenshots(me);
	me.previewScreenshot(me);
}

void ScreenshotList_Refresh_Click(entity btn, entity me)
{
	me.getScreenshots(me);
	me.setSelected(me, 0); //always select the first element after a list update
}

void ScreenshotList_Filter_Change(entity box, entity me)
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

	ScreenshotList_Refresh_Click(world, me);
}

void ScreenshotList_Filter_Would_Change(entity box, entity me)
{
	me.filterBox = box;
	me.filterTime = time + 0.5;
}

void XonoticScreenshotList_draw(entity me)
{
	if (me.filterTime && time > me.filterTime)
	{
		ScreenshotList_Filter_Change(me.filterBox, me);
		me.filterTime = 0;
	}
	if (me.newScreenshotTime && time > me.newScreenshotTime)
	{
		me.previewScreenshot(me);
		me.newScreenshotTime = 0;
	}
	else if (me.newSlideShowScreenshotTime && time > me.newSlideShowScreenshotTime)
	{
		if (me.selectedItem == me.nItems - 1) //last screenshot?
		{
			// restart from the first screenshot
			me.setSelected(me, 0);
			me.goScreenshot(me, +0);
		}
		else
			me.goScreenshot(me, +1);
	}
	SUPER(XonoticScreenshotList).draw(me);
}

void XonoticScreenshotList_startSlideShow(entity me)
{
	me.newSlideShowScreenshotTime = time + 3;
}

void XonoticScreenshotList_stopSlideShow(entity me)
{
	me.newSlideShowScreenshotTime = 0;
}

void XonoticScreenshotList_goScreenshot(entity me, float d)
{
	if(!me.screenshotViewerDialog)
		return;
	me.setSelected(me, me.selectedItem + d);
	me.screenshotViewerDialog.loadScreenshot(me.screenshotViewerDialog, strcat("/screenshots/", strdecolorize(me.screenshotName(me,me.selectedItem))));
}

void XonoticScreenshotList_startScreenshot(entity me)
{
	me.screenshotViewerDialog.loadScreenshot(me.screenshotViewerDialog, strcat("/screenshots/", strdecolorize(me.screenshotName(me,me.selectedItem))));
	// pop up screenshot
	DialogOpenButton_Click_withCoords(NULL, me.screenshotViewerDialog, me.origin + eX * (me.columnNameOrigin * me.size.x) + eY * ((me.itemHeight * me.selectedItem - me.scrollPos) * me.size.y), eY * me.itemAbsSize.y + eX * (me.itemAbsSize.x * me.columnNameSize));
}

void XonoticScreenshotList_previewScreenshot(entity me)
{
	if(!me.screenshotBrowserDialog)
		return;
	if (me.nItems <= 0)
		me.screenshotBrowserDialog.loadPreviewScreenshot(me.screenshotBrowserDialog, "");
	else
		me.screenshotBrowserDialog.loadPreviewScreenshot(me.screenshotBrowserDialog, strcat("/screenshots/", strdecolorize(me.screenshotName(me,me.selectedItem))));
}

void StartScreenshot_Click(entity btn, entity me)
{
	me.startScreenshot(me);
}

void XonoticScreenshotList_doubleClickListBoxItem(entity me, float i, vector where)
{
	me.startScreenshot(me);
}

float XonoticScreenshotList_keyDown(entity me, float scan, float ascii, float shift)
{
	if(scan == K_ENTER || scan == K_KP_ENTER || scan == K_MOUSE2 || scan == K_SPACE) {
		me.startScreenshot(me);
		return 1;
	}
	if(scan == K_MWHEELUP || scan == K_MWHEELDOWN)
		me.newScreenshotTime = time + 0.2;
	return SUPER(XonoticScreenshotList).keyDown(me, scan, ascii, shift);
}
#endif
