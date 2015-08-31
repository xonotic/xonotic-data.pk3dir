#ifndef ITEM_IMAGE_H
#define ITEM_IMAGE_H
#include "../item.qc"
CLASS(Image, Item)
	METHOD(Image, configureImage, void(entity, string));
	METHOD(Image, draw, void(entity));
	METHOD(Image, toString, string(entity));
	METHOD(Image, resizeNotify, void(entity, vector, vector, vector, vector));
	METHOD(Image, updateAspect, void(entity));
	METHOD(Image, initZoom, void(entity));
	METHOD(Image, setZoom, void(entity, float, float));
	METHOD(Image, drag_setStartPos, float(entity, vector));
	METHOD(Image, drag, float(entity, vector));
	ATTRIB(Image, src, string, string_null)
	ATTRIB(Image, color, vector, '1 1 1')
	ATTRIB(Image, forcedAspect, float, 0) // special values: -1 keep image aspect ratio, -2 keep image size but bound to the containing box, -3 always keep image size
	ATTRIB(Image, zoomBox, float, 0) // used by forcedAspect -2 when the image is larger than the containing box
	ATTRIB(Image, zoomFactor, float, 1)
	ATTRIB(Image, zoomOffset, vector, '0.5 0.5 0')
	ATTRIB(Image, zoomSnapToTheBox, float, 1) // snap the zoomed in image to the box borders when zooming/dragging it
	ATTRIB(Image, zoomTime, float, 0)
	ATTRIB(Image, zoomLimitedByTheBox, float, 0) // forbids zoom if image would be larger than the containing box
	ATTRIB(Image, zoomMax, float, 0)
	ATTRIB(Image, start_zoomOffset, vector, '0 0 0')
	ATTRIB(Image, start_coords, vector, '0 0 0')
	ATTRIB(Image, imgOrigin, vector, '0 0 0')
	ATTRIB(Image, imgSize, vector, '0 0 0')
ENDCLASS(Image)
#endif

#ifdef IMPLEMENTATION
string Image_toString(entity me)
{
	return me.src;
}
void Image_configureImage(entity me, string path)
{
	me.src = path;
}
void Image_initZoom(entity me)
{
	me.zoomOffset = '0.5 0.5 0';
	me.zoomFactor = 1;
	if (me.forcedAspect == -2)
		me.zoomBox = -1; // calculate zoomBox at the first updateAspect call
	if (me.zoomLimitedByTheBox)
		me.zoomMax = -1; // calculate zoomMax at the first updateAspect call
}

void Image_draw(entity me)
{
	if(me.imgSize.x > 1 || me.imgSize.y > 1)
		draw_SetClip();
	draw_Picture(me.imgOrigin, me.src, me.imgSize, me.color, 1);
	if(me.imgSize.x > 1 || me.imgSize.y > 1)
		draw_ClearClip();
	SUPER(Image).draw(me);
}
void Image_updateAspect(entity me)
{
	float asp = 0;
	if(me.size.x <= 0 || me.size.y <= 0)
		return;
	if(me.forcedAspect == 0)
	{
		me.imgOrigin = '0 0 0';
		me.imgSize = '1 1 0';
	}
	else
	{
		vector sz = '0 0 0';
		if(me.forcedAspect < 0)
		{
			if (me.src != "")
				sz = draw_PictureSize(me.src);
			if(sz.x <= 0 || sz.y <= 0)
			{
				// image is broken or doesn't exist, set the size for the placeholder image
				sz.x = me.size.x;
				sz.y = me.size.y;
			}
			asp = sz.x / sz.y;
		}
		else
			asp = me.forcedAspect;

		if(me.forcedAspect <= -2)
		{
			me.imgSize_x = sz.x / me.size.x;
			me.imgSize_y = sz.y / me.size.y;
			if(me.zoomBox < 0 && (me.imgSize.x > 1 || me.imgSize.y > 1))
			{
				// image larger than the containing box, zoom it out to fit into the box
				if(me.size.x > asp * me.size.y)
					me.zoomBox = (me.size.y * asp / me.size.x) / me.imgSize.x;
				else
					me.zoomBox = (me.size.x / (asp * me.size.y)) / me.imgSize.y;
				me.zoomFactor = me.zoomBox;
			}
		}
		else
		{
			if(me.size.x > asp * me.size.y)
			{
				// x too large, so center x-wise
				me.imgSize = eY + eX * (me.size.y * asp / me.size.x);
			}
			else
			{
				// y too large, so center y-wise
				me.imgSize = eX + eY * (me.size.x / (asp * me.size.y));
			}
		}
	}

	if (me.zoomMax < 0)
	{
		if(me.zoomBox > 0)
			me.zoomMax = me.zoomBox;
		else
		{
			if(me.size.x > asp * me.size.y)
				me.zoomMax = (me.size.y * asp / me.size.x) / me.imgSize.x;
			else
				me.zoomMax = (me.size.x / (asp * me.size.y)) / me.imgSize.y;
		}
	}

	if (me.zoomMax > 0 && me.zoomFactor > me.zoomMax)
		me.zoomFactor = me.zoomMax;
	if (me.zoomFactor)
		me.imgSize = me.imgSize * me.zoomFactor;

	if(me.imgSize.x > 1 || me.imgSize.y > 1)
	{
		if(me.zoomSnapToTheBox)
		{
			if(me.imgSize.x > 1)
				me.zoomOffset_x = bound(0.5/me.imgSize.x, me.zoomOffset.x, 1 - 0.5/me.imgSize.x);
			else
				me.zoomOffset_x = bound(1 - 0.5/me.imgSize.x, me.zoomOffset.x, 0.5/me.imgSize.x);

			if(me.imgSize.y > 1)
				me.zoomOffset_y = bound(0.5/me.imgSize.y, me.zoomOffset.y, 1 - 0.5/me.imgSize.y);
			else
				me.zoomOffset_y = bound(1 - 0.5/me.imgSize.y, me.zoomOffset.y, 0.5/me.imgSize.y);
		}
		else
		{
			me.zoomOffset_x = bound(0, me.zoomOffset.x, 1);
			me.zoomOffset_y = bound(0, me.zoomOffset.y, 1);
		}
	}
	else
		me.zoomOffset = '0.5 0.5 0';

	me.imgOrigin_x = 0.5 - me.zoomOffset.x * me.imgSize.x;
	me.imgOrigin_y = 0.5 - me.zoomOffset.y * me.imgSize.y;
}
float Image_drag_setStartPos(entity me, vector coords)
{
	//if(me.imgSize_x > 1 || me.imgSize_y > 1) // check disabled: mousewheel zoom may start from a non-zoomed-in image
	{
		me.start_zoomOffset = me.zoomOffset;
		me.start_coords = coords;
	}
	return 1;
}
float Image_drag(entity me, vector coords)
{
	if(me.imgSize.x > 1 || me.imgSize.y > 1)
	{
		me.zoomOffset_x = me.start_zoomOffset.x + (me.start_coords.x - coords.x) / me.imgSize.x;
		me.zoomOffset_y = me.start_zoomOffset.y + (me.start_coords.y - coords.y) / me.imgSize.y;
		me.updateAspect(me);
	}
	return 1;
}
void Image_setZoom(entity me, float z, float atMousePosition)
{
	float prev_zoomFactor;
	prev_zoomFactor = me.zoomFactor;
	if (z < 0) // multiply by the current zoomFactor (but can also snap to real dimensions or to box)
	{
		me.zoomFactor *= -z;
		float realSize_in_the_middle, boxSize_in_the_middle;
		realSize_in_the_middle = ((prev_zoomFactor - 1) * (me.zoomFactor - 1) < 0);
		boxSize_in_the_middle = (me.zoomBox > 0 && (prev_zoomFactor - me.zoomBox) * (me.zoomFactor - me.zoomBox) < 0);
		if (realSize_in_the_middle && boxSize_in_the_middle)
		{
			// snap to real dimensions or to box
			if (prev_zoomFactor < me.zoomFactor)
				me.zoomFactor = min(1, me.zoomBox);
			else
				me.zoomFactor = max(1, me.zoomBox);
		}
		else if (realSize_in_the_middle)
			me.zoomFactor = 1; // snap to real dimensions
		else if (boxSize_in_the_middle)
			me.zoomFactor = me.zoomBox; // snap to box
	}
	else if (z == 0) // reset (no zoom)
	{
		if (me.zoomBox > 0)
			me.zoomFactor = me.zoomBox;
		else
			me.zoomFactor = 1;
	}
	else // directly set
		me.zoomFactor = z;
	me.zoomFactor = bound(1/16, me.zoomFactor, 16);
	if (me.zoomMax > 0 && me.zoomFactor > me.zoomMax)
		me.zoomFactor = me.zoomMax;
	if (prev_zoomFactor != me.zoomFactor)
	{
		me.zoomTime = time;
		if (atMousePosition)
		{
			me.zoomOffset_x = me.start_zoomOffset.x + (me.start_coords.x - 0.5) / me.imgSize.x;
			me.zoomOffset_y = me.start_zoomOffset.y + (me.start_coords.y - 0.5) / me.imgSize.y;
			// updateAspect will reset zoomOffset to '0.5 0.5 0' if
			// with this zoomFactor the image will not be zoomed in
			// (updateAspect will check the new values of imgSize).
		}
	}
	me.updateAspect(me);
}
void Image_resizeNotify(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
{
	SUPER(Image).resizeNotify(me, relOrigin, relSize, absOrigin, absSize);
	me.updateAspect(me);
}
#endif
