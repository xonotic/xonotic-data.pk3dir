#ifndef ITEM_LISTBOX_H
#define ITEM_LISTBOX_H
#include "../item.qc"
CLASS(ListBox, Item)
	METHOD(ListBox, resizeNotify, void(entity, vector, vector, vector, vector));
	METHOD(ListBox, configureListBox, void(entity, float, float));
	METHOD(ListBox, draw, void(entity));
	METHOD(ListBox, keyDown, float(entity, float, float, float));
	METHOD(ListBox, mouseMove, float(entity, vector));
	METHOD(ListBox, mousePress, float(entity, vector));
	METHOD(ListBox, mouseDrag, float(entity, vector));
	METHOD(ListBox, mouseRelease, float(entity, vector));
	METHOD(ListBox, focusLeave, void(entity));
	ATTRIB(ListBox, focusable, float, 1)
	ATTRIB(ListBox, focusedItem, int, -1)
	ATTRIB(ListBox, focusedItemAlpha, float, 0.3)
	ATTRIB(ListBox, mouseMoveOffset, float, -1) // let know where the cursor is when the list scrolls without moving the cursor
	ATTRIB(ListBox, allowFocusSound, float, 1)
	ATTRIB(ListBox, selectedItem, int, 0)
	ATTRIB(ListBox, size, vector, '0 0 0')
	ATTRIB(ListBox, origin, vector, '0 0 0')
	ATTRIB(ListBox, scrollPos, float, 0) // measured in window heights, fixed when needed
	ATTRIB(ListBox, scrollPosTarget, float, 0)
	ATTRIB(ListBox, needScrollToItem, float, -1)
	METHOD(ListBox, scrollToItem, void(entity, int));
	ATTRIB(ListBox, previousValue, float, 0)
	ATTRIB(ListBox, pressed, float, 0) // 0 = normal, 1 = scrollbar dragging, 2 = item dragging, 3 = released
	ATTRIB(ListBox, pressOffset, float, 0)

	METHOD(ListBox, updateControlTopBottom, void(entity));
	ATTRIB(ListBox, controlTop, float, 0)
	ATTRIB(ListBox, controlBottom, float, 0)
	ATTRIB(ListBox, controlWidth, float, 0)
	ATTRIB(ListBox, dragScrollPos, vector, '0 0 0')
	ATTRIB(ListBox, selectionDoesntMatter, bool, false) // improves scrolling by keys for lists that don't need to show an active selection

	ATTRIB(ListBox, src, string, string_null) // scrollbar
	ATTRIB(ListBox, color, vector, '1 1 1')
	ATTRIB(ListBox, color2, vector, '1 1 1')
	ATTRIB(ListBox, colorC, vector, '1 1 1')
	ATTRIB(ListBox, colorF, vector, '1 1 1')
	ATTRIB(ListBox, tolerance, vector, '0 0 0') // drag tolerance
	ATTRIB(ListBox, scrollbarWidth, float, 0) // pixels
	ATTRIB(ListBox, nItems, float, 42)
	ATTRIB(ListBox, itemHeight, float, 0)
	ATTRIB(ListBox, colorBG, vector, '0 0 0')
	ATTRIB(ListBox, alphaBG, float, 0)

	ATTRIB(ListBox, lastClickedItem, float, -1)
	ATTRIB(ListBox, lastClickedTime, float, 0)

	METHOD(ListBox, drawListBoxItem, void(entity, int, vector, bool, bool)); // item number, width/height, isSelected, isFocused
	METHOD(ListBox, clickListBoxItem, void(entity, float, vector)); // item number, relative clickpos
	METHOD(ListBox, doubleClickListBoxItem, void(entity, float, vector)); // item number, relative clickpos
	METHOD(ListBox, setSelected, void(entity, float));

	METHOD(ListBox, getLastFullyVisibleItemAtScrollPos, float(entity, float));
	METHOD(ListBox, getFirstFullyVisibleItemAtScrollPos, float(entity, float));

	// NOTE: override these four methods if you want variable sized list items
	METHOD(ListBox, getTotalHeight, float(entity));
	METHOD(ListBox, getItemAtPos, float(entity, float));
	METHOD(ListBox, getItemStart, float(entity, float));
	METHOD(ListBox, getItemHeight, float(entity, float));
	// NOTE: if getItemAt* are overridden, it may make sense to cache the
	// start and height of the last item returned by getItemAtPos and fast
	// track returning their properties for getItemStart and getItemHeight.
	// The "hot" code path calls getItemAtPos first, then will query
	// getItemStart and getItemHeight on it soon.
	// When overriding, the following consistency rules must hold:
	// getTotalHeight() == SUM(getItemHeight(i), i, 0, me.nItems-1)
	// getItemStart(i+1) == getItemStart(i) + getItemHeight(i)
	//   for 0 <= i < me.nItems-1
	// getItemStart(0) == 0
	// getItemStart(getItemAtPos(p)) <= p
	//   if p >= 0
	// getItemAtPos(p) == 0
	//   if p < 0
	// getItemStart(getItemAtPos(p)) + getItemHeight(getItemAtPos(p)) > p
	//   if p < getTotalHeigt()
	// getItemAtPos(p) == me.nItems - 1
	//   if p >= getTotalHeight()
ENDCLASS(ListBox)
#endif

#ifdef IMPLEMENTATION
void ListBox_scrollToItem(entity me, int i)
{
	// scroll doesn't work properly until itemHeight is set to the correct value
	// at the first resizeNotify call
	if(me.itemHeight == 1) // initial temporary value of itemHeight is 1
	{
		me.needScrollToItem = i;
		return;
	}

	i = bound(0, i, me.nItems - 1);

	// scroll the list to make sure the selected item is visible
	// (even if the selected item doesn't change).
	if(i < me.getFirstFullyVisibleItemAtScrollPos(me, me.scrollPos))
	{
		// above visible area
		me.scrollPosTarget = me.getItemStart(me, i);
	}
	else if(i > me.getLastFullyVisibleItemAtScrollPos(me, me.scrollPos))
	{
		// below visible area
		if(i == me.nItems - 1)
			me.scrollPosTarget = me.getTotalHeight(me) - 1;
		else
			me.scrollPosTarget = me.getItemStart(me, i + 1) - 1;
	}
}

void ListBox_setSelected(entity me, float i)
{
	i = bound(0, i, me.nItems - 1);
	me.scrollToItem(me, i);
	me.selectedItem = i;
}
void ListBox_resizeNotify(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
{
	SUPER(ListBox).resizeNotify(me, relOrigin, relSize, absOrigin, absSize);
	me.controlWidth = me.scrollbarWidth / absSize.x;
}
void ListBox_configureListBox(entity me, float theScrollbarWidth, float theItemHeight)
{
	me.scrollbarWidth = theScrollbarWidth;
	me.itemHeight = theItemHeight;
}

float ListBox_getTotalHeight(entity me)
{
	return me.nItems * me.itemHeight;
}
float ListBox_getItemAtPos(entity me, float pos)
{
	return floor(pos / me.itemHeight);
}
float ListBox_getItemStart(entity me, float i)
{
	return me.itemHeight * i;
}
float ListBox_getItemHeight(entity me, float i)
{
	return me.itemHeight;
}

float ListBox_getLastFullyVisibleItemAtScrollPos(entity me, float pos)
{
	return me.getItemAtPos(me, pos + 0.999) - 1;
}
float ListBox_getFirstFullyVisibleItemAtScrollPos(entity me, float pos)
{
	return me.getItemAtPos(me, pos + 0.001) + 1;
}
float ListBox_keyDown(entity me, float key, float ascii, float shift)
{
	if(key == K_MWHEELUP)
	{
		me.scrollPosTarget = max(me.scrollPosTarget - 0.5, 0);
	}
	else if(key == K_MWHEELDOWN)
	{
		me.scrollPosTarget = min(me.scrollPosTarget + 0.5, me.getTotalHeight(me) - 1);
	}
	else if(key == K_PGUP || key == K_KP_PGUP)
	{
		if(me.selectionDoesntMatter)
		{
			me.scrollPosTarget = max(me.scrollPosTarget - 0.5, 0);
			return 1;
		}

		float i = me.selectedItem;
		float a = me.getItemHeight(me, i);
		for (;;)
		{
			--i;
			if (i < 0)
				break;
			a += me.getItemHeight(me, i);
			if (a >= 1)
				break;
		}
		me.setSelected(me, i + 1);
	}
	else if(key == K_PGDN || key == K_KP_PGDN)
	{
		if(me.selectionDoesntMatter)
		{
			me.scrollPosTarget = min(me.scrollPosTarget + 0.5, me.nItems * me.itemHeight - 1);
			return 1;
		}

		float i = me.selectedItem;
		float a = me.getItemHeight(me, i);
		for (;;)
		{
			++i;
			if (i >= me.nItems)
				break;
			a += me.getItemHeight(me, i);
			if (a >= 1)
				break;
		}
		me.setSelected(me, i - 1);
	}
	else if(key == K_UPARROW || key == K_KP_UPARROW)
	{
		if(me.selectionDoesntMatter)
		{
			me.scrollPosTarget = max(me.scrollPosTarget - me.itemHeight, 0);
			return 1;
		}

		me.setSelected(me, me.selectedItem - 1);
	}
	else if(key == K_DOWNARROW || key == K_KP_DOWNARROW)
	{
		if(me.selectionDoesntMatter)
		{
			me.scrollPosTarget = min(me.scrollPosTarget + me.itemHeight, me.nItems * me.itemHeight - 1);
			return 1;
		}

		me.setSelected(me, me.selectedItem + 1);
	}
	else if(key == K_HOME || key == K_KP_HOME)
		me.setSelected(me, 0);
	else if(key == K_END || key == K_KP_END)
		me.setSelected(me, me.nItems - 1);
	else
		return 0;
	return 1;
}
float ListBox_mouseMove(entity me, vector pos)
{
	me.mouseMoveOffset = -1;
	if(pos_x < 0) return 0;
	if(pos_y < 0) return 0;
	if(pos_x >= 1) return 0;
	if(pos_y >= 1) return 0;
	if(pos_x < 1 - me.controlWidth)
		me.mouseMoveOffset = pos.y;
	else
	{
		me.focusedItem = -1;
		me.mouseMoveOffset = -1;
	}
	return 1;
}
float ListBox_mouseDrag(entity me, vector pos)
{
	float hit;
	me.updateControlTopBottom(me);
	me.dragScrollPos = pos;
	if(me.pressed == 1)
	{
		hit = 1;
		if(pos.x < 1 - me.controlWidth - me.tolerance.y * me.controlWidth) hit = 0;
		if(pos.y < 0 - me.tolerance.x) hit = 0;
		if(pos.x >= 1 + me.tolerance.y * me.controlWidth) hit = 0;
		if(pos.y >= 1 + me.tolerance.x) hit = 0;
		if(hit)
		{
			// calculate new pos to v
			float d;
			d = (pos.y - me.pressOffset) / (1 - (me.controlBottom - me.controlTop)) * (me.getTotalHeight(me) - 1);
			me.scrollPosTarget = me.previousValue + d;
		}
		else
			me.scrollPosTarget = me.previousValue;
		me.scrollPosTarget = min(me.scrollPosTarget, me.getTotalHeight(me) - 1);
		me.scrollPosTarget = max(me.scrollPosTarget, 0);
	}
	else if(me.pressed == 2)
	{
		me.setSelected(me, me.getItemAtPos(me, me.scrollPos + pos.y));
		me.focusedItem = me.selectedItem;
		me.mouseMoveOffset = -1;
	}
	return 1;
}
float ListBox_mousePress(entity me, vector pos)
{
	if(pos.x < 0) return 0;
	if(pos.y < 0) return 0;
	if(pos.x >= 1) return 0;
	if(pos.y >= 1) return 0;
	me.dragScrollPos = pos;
	me.updateControlTopBottom(me);
	if(pos.x >= 1 - me.controlWidth)
	{
		// if hit, set me.pressed, otherwise scroll by one page
		if(pos.y < me.controlTop)
		{
			// page up
			me.scrollPosTarget = max(me.scrollPosTarget - 1, 0);
		}
		else if(pos.y > me.controlBottom)
		{
			// page down
			me.scrollPosTarget = min(me.scrollPosTarget + 1, me.getTotalHeight(me) - 1);
		}
		else
		{
			me.pressed = 1;
			me.pressOffset = pos.y;
			me.previousValue = me.scrollPos;
		}
	}
	else
	{
		// continue doing that while dragging (even when dragging outside). When releasing, forward the click to the then selected item.
		me.pressed = 2;
		// an item has been clicked. Select it, ...
		me.setSelected(me, me.getItemAtPos(me, me.scrollPos + pos.y));
		me.focusedItem = me.selectedItem;
	}
	return 1;
}
float ListBox_mouseRelease(entity me, vector pos)
{
	if(me.pressed == 1)
	{
		// slider dragging mode
		// in that case, nothing happens on releasing
	}
	else if(me.pressed == 2)
	{
		me.pressed = 3; // do that here, so setSelected can know the mouse has been released
		// item dragging mode
		// select current one one last time...
		me.setSelected(me, me.getItemAtPos(me, me.scrollPos + pos.y));
		me.focusedItem = me.selectedItem;
		// and give it a nice click event
		if(me.nItems > 0)
		{
			vector where = globalToBox(pos, eY * (me.getItemStart(me, me.selectedItem) - me.scrollPos), eX * (1 - me.controlWidth) + eY * me.getItemHeight(me, me.selectedItem));

			if((me.selectedItem == me.lastClickedItem) && (time < me.lastClickedTime + 0.3))
				me.doubleClickListBoxItem(me, me.selectedItem, where);
			else
				me.clickListBoxItem(me, me.selectedItem, where);

			me.lastClickedItem = me.selectedItem;
			me.lastClickedTime = time;
		}
	}
	me.pressed = 0;
	return 1;
}
void ListBox_focusLeave(entity me)
{
	// Reset the var pressed in case listbox loses focus
	// by a mouse click on an item of the list
	// for example showing a dialog on right click
	me.pressed = 0;
	me.focusedItem = -1;
	me.mouseMoveOffset = -1;
}
void ListBox_updateControlTopBottom(entity me)
{
	float f;
	// scrollPos is in 0..1 and indicates where the "page" currently shown starts.
	if(me.getTotalHeight(me) <= 1)
	{
		// we don't need no stinkin' scrollbar, we don't need no view control...
		me.controlTop = 0;
		me.controlBottom = 1;
		me.scrollPos = 0;
	}
	else
	{
		// if scroll pos is below end of list, fix it
		me.scrollPos = min(me.scrollPos, me.getTotalHeight(me) - 1);
		// if scroll pos is above beginning of list, fix it
		me.scrollPos = max(me.scrollPos, 0);
		// now that we know where the list is scrolled to, find out where to draw the control
		me.controlTop = max(0, me.scrollPos / me.getTotalHeight(me));
		me.controlBottom = min((me.scrollPos + 1) / me.getTotalHeight(me), 1);

		float minfactor;
		minfactor = 2 * me.controlWidth / me.size.y * me.size.x;
		f = me.controlBottom - me.controlTop;
		if(f < minfactor) // FIXME good default?
		{
			// f * X + 1 * (1-X) = minfactor
			// (f - 1) * X + 1 = minfactor
			// (f - 1) * X = minfactor - 1
			// X = (minfactor - 1) / (f - 1)
			f = (minfactor - 1) / (f - 1);
			me.controlTop = me.controlTop * f + 0 * (1 - f);
			me.controlBottom = me.controlBottom * f + 1 * (1 - f);
		}
	}
}
AUTOCVAR(menu_scroll_averaging_time, float, 0.16, "smooth scroll averaging time");
// scroll faster while dragging the scrollbar
AUTOCVAR(menu_scroll_averaging_time_pressed, float, 0.06, "smooth scroll averaging time when dragging the scrollbar");
void ListBox_draw(entity me)
{
	float i;
	vector absSize, fillSize = '0 0 0';
	vector oldshift, oldscale;

	// we can't do this in mouseMove as the list can scroll without moving the cursor
	float focusedItem_save = me.focusedItem;
	if(me.mouseMoveOffset != -1)
		me.focusedItem = me.getItemAtPos(me, me.scrollPos + me.mouseMoveOffset);
	if(me.focusedItem >= 0)
	if(focusedItem_save != me.focusedItem)
		me.focusedItemAlpha = SKINALPHA_LISTBOX_FOCUSED;

	if(me.needScrollToItem >= 0)
	{
		me.scrollToItem(me, me.needScrollToItem);
		me.needScrollToItem = -1;
	}
	if(me.scrollPos != me.scrollPosTarget)
	{
		float averaging_time = (me.pressed == 1)
			? autocvar_menu_scroll_averaging_time_pressed
			: autocvar_menu_scroll_averaging_time;
		// this formula works with whatever framerate
		float f = averaging_time ? exp(-frametime / averaging_time) : 0;
		me.scrollPos = me.scrollPos * f + me.scrollPosTarget * (1 - f);
		if(fabs(me.scrollPos - me.scrollPosTarget) < 0.001)
			me.scrollPos = me.scrollPosTarget;
	}

	if(me.pressed == 2)
		me.mouseDrag(me, me.dragScrollPos); // simulate mouseDrag event
	me.updateControlTopBottom(me);
	fillSize.x = (1 - me.controlWidth);
	if(me.alphaBG)
		draw_Fill('0 0 0', '0 1 0' + fillSize, me.colorBG, me.alphaBG);
	if(me.controlWidth)
	{
		draw_VertButtonPicture(eX * (1 - me.controlWidth), strcat(me.src, "_s"), eX * me.controlWidth + eY, me.color2, 1);
		if(me.getTotalHeight(me) > 1)
		{
			vector o, s;
			o = eX * (1 - me.controlWidth) + eY * me.controlTop;
			s = eX * me.controlWidth + eY * (me.controlBottom - me.controlTop);
			if(me.pressed == 1)
				draw_VertButtonPicture(o, strcat(me.src, "_c"), s, me.colorC, 1);
			else if(me.focused)
				draw_VertButtonPicture(o, strcat(me.src, "_f"), s, me.colorF, 1);
			else
				draw_VertButtonPicture(o, strcat(me.src, "_n"), s, me.color, 1);
		}
	}
	draw_SetClip();
	oldshift = draw_shift;
	oldscale = draw_scale;

	float y;
	i = me.getItemAtPos(me, me.scrollPos);
	y = me.getItemStart(me, i) - me.scrollPos;
	for (; i < me.nItems && y < 1; ++i)
	{
		draw_shift = boxToGlobal(eY * y, oldshift, oldscale);
		vector relSize = eX * (1 - me.controlWidth) + eY * me.getItemHeight(me, i);
		absSize = boxToGlobalSize(relSize, me.size);
		draw_scale = boxToGlobalSize(relSize, oldscale);
		me.drawListBoxItem(me, i, absSize, (me.selectedItem == i), (me.focusedItem == i));
		y += relSize.y;
	}
	draw_ClearClip();

	draw_shift = oldshift;
	draw_scale = oldscale;
	SUPER(ListBox).draw(me);
}

void ListBox_clickListBoxItem(entity me, float i, vector where)
{
	// template method
}

void ListBox_doubleClickListBoxItem(entity me, float i, vector where)
{
	// template method
}

void ListBox_drawListBoxItem(entity me, int i, vector absSize, bool isSelected, bool isFocused)
{
	draw_Text('0 0 0', sprintf(_("Item %d"), i), eX * (8 / absSize.x) + eY * (8 / absSize.y), (isSelected ? '0 1 0' : '1 1 1'), 1, 0);
}
#endif
