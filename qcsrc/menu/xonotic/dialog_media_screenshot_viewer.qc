#include "dialog_media_screenshot_viewer.qh"

#include "screenshotlist.qh"
#include "inputbox.qh"
#include "button.qh"

const float SCREENSHOTVIEWER_ZOOM_FACTOR = 1.5;

float music_playlist_index_backup;
void XonoticScreenshotViewerDialog_loadScreenshot(entity me, string scrImage)
{
	// disable music as it can lag depending on image loading time
	if(!cvar("menu_screenshotviewer_enablemusic"))
	if(cvar("music_playlist_index") != 999) // if the playlist isn't paused
	{
		// pause music
		if(cvar("music_playlist_index") != -1)
		{
			music_playlist_index_backup = cvar("music_playlist_index");
			cvar_set("music_playlist_sampleposition0", "0");
			cvar_set("music_playlist_index", "999");
		}
		else
			localcmd("\ncd pause\n");
	}

	if (me.currentScrPath == scrImage)
		return;
	strcpy(me.currentScrPath, scrImage);
	me.screenshotImage.load(me.screenshotImage, me.currentScrPath);
	me.frame.setText(me.frame, me.screenshotImage.screenshotTitle);
}
void prevScreenshot_Click(entity btn, entity me)
{
	me.scrList.goScreenshot(me.scrList, -1);
}
void nextScreenshot_Click(entity btn, entity me)
{
	me.scrList.goScreenshot(me.scrList, +1);
}
void increaseZoom_Click(entity btn, entity me)
{
	me.screenshotImage.setZoom(me.screenshotImage, -SCREENSHOTVIEWER_ZOOM_FACTOR, false);
}
void decreaseZoom_Click(entity btn, entity me)
{
	me.screenshotImage.setZoom(me.screenshotImage, -1 / SCREENSHOTVIEWER_ZOOM_FACTOR, false);
}
void resetZoom_Click(entity btn, entity me)
{
	me.screenshotImage.setZoom(me.screenshotImage, 0, false);
}
void toggleSlideShow_Click(entity btn, entity me)
{
	if (me.slideShowButton.forcePressed)
	{
		me.scrList.stopSlideShow(me.scrList);
		me.slideShowButton.forcePressed = false;
	}
	else
	{
		me.scrList.startSlideShow(me.scrList);
		me.slideShowButton.forcePressed = true;
	}
}
float XonoticScreenshotViewerDialog_keyDown(entity me, float key, float ascii, float shift)
{
	switch(key)
	{
		case K_KP_LEFTARROW:
		case K_LEFTARROW:
			me.scrList.goScreenshot(me.scrList, -1);
			return 1;
		case K_KP_RIGHTARROW:
		case K_RIGHTARROW:
			me.scrList.goScreenshot(me.scrList, +1);
			return 1;
		case K_KP_ENTER:
		case K_ENTER:
		case K_SPACE:
			// we cannot use SPACE/ENTER directly, as in a dialog they are needed
			// to press buttons while browsing with only the keyboard
			if (shift & S_CTRL)
			{
				toggleSlideShow_Click(NULL, me);
				return 1;
			}
			return SUPER(XonoticScreenshotViewerDialog).keyDown(me, key, ascii, shift);
		default:
			if (key == K_MWHEELUP || ascii == '+')
			{
				me.screenshotImage.setZoom(me.screenshotImage, -SCREENSHOTVIEWER_ZOOM_FACTOR, (key == K_MWHEELUP));
				return 1;
			}
			else if (key == K_MWHEELDOWN || ascii == '-')
			{
				me.screenshotImage.setZoom(me.screenshotImage, -1 / SCREENSHOTVIEWER_ZOOM_FACTOR, (key == K_MWHEELDOWN));
				return 1;
			}
			if (me.scrList.keyDown(me.scrList, key, ascii, shift))
			{
				// keyDown has already changed the selected item
				me.scrList.goScreenshot(me.scrList, 0);
				return 1;
			}
			return SUPER(XonoticScreenshotViewerDialog).keyDown(me, key, ascii, shift);
	}
}
void XonoticScreenshotViewerDialog_close(entity me)
{
	// resume music
	if(!cvar("menu_screenshotviewer_enablemusic"))
	if(cvar("music_playlist_index") == 999)
	{
		cvar_set("music_playlist_index", ftos(music_playlist_index_backup));
	}
	else
		localcmd("\ncd resume\n");

	me.scrList.stopSlideShow(me.scrList);
	me.slideShowButton.forcePressed = false;
	SUPER(XonoticScreenshotViewerDialog).close(me);
}
void XonoticScreenshotViewerDialog_fill(entity me)
{
	entity e;
	me.TR(me);
		me.TD(me, me.rows - 1, me.columns, e = makeXonoticScreenshotImage());
			e.showTitle = false; // dialog title is enough
			me.screenshotImage = e;
	me.gotoRC(me, me.rows - 1, 0);
		me.TDempty(me, 1/20 * me.columns);
		me.TD(me, 1, 1/20 * me.columns, e = makeXonoticButton("-", '0 0 0'));
			e.onClick = decreaseZoom_Click;
			e.onClickEntity = me;
		me.TD(me, 1, 1/20 * me.columns, e = makeXonoticButton("+", '0 0 0'));
			e.onClick = increaseZoom_Click;
			e.onClickEntity = me;
		me.TD(me, 1, 2/20 * me.columns, e = makeXonoticButton(_("Reset"), '0 0 0'));
			e.onClick = resetZoom_Click;
			e.onClickEntity = me;

		me.TDempty(me, 2/20 * me.columns);
		me.TD(me, 1, 3/20 * me.columns, e = makeXonoticButton(_("Previous"), '0 0 0'));
			e.onClick = prevScreenshot_Click;
			e.onClickEntity = me;
		me.TD(me, 1, 3/20 * me.columns, e = makeXonoticButton(_("Next"), '0 0 0'));
			e.onClick = nextScreenshot_Click;
			e.onClickEntity = me;

		me.TDempty(me, 2/20 * me.columns);
		me.TD(me, 1, 4/20 * me.columns, e = makeXonoticButton(_("Slide show"), '0 0 0'));
			e.onClick = toggleSlideShow_Click;
			e.onClickEntity = me;
			me.slideShowButton = e;
}
