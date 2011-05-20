#ifdef INTERFACE
CLASS(Image) EXTENDS(Item)
	METHOD(Image, configureImage, void(entity, string))
	METHOD(Image, draw, void(entity))
	METHOD(Image, toString, string(entity))
	METHOD(Image, resizeNotify, void(entity, vector, vector, vector, vector))
	METHOD(Image, updateAspect, void(entity))
	METHOD(Image, setZoom, void(entity, float))
	ATTRIB(Image, src, string, string_null)
	ATTRIB(Image, color, vector, '1 1 1')
	ATTRIB(Image, forcedAspect, float, 0)
	ATTRIB(Image, zoomFactor, float, 1)
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
	me.zoomFactor = 1;
}
void Image_draw(entity me)
{
	if (me.zoomFactor > 1)
		draw_SetClip();
	draw_Picture(me.imgOrigin, me.src, me.imgSize, me.color, 1);
	if (me.zoomFactor > 1)
		draw_ClearClip();
}
void Image_updateAspect(entity me)
{
	float asp;
	if(me.size_x <= 0 || me.size_y <= 0)
		return;
	if(me.forcedAspect == 0)
	{
		me.imgOrigin = '0 0 0';
		me.imgSize = '1 1 0';
	}
	else
	{
		if(me.forcedAspect < 0)
		{
			vector sz;
			sz = draw_PictureSize(me.src);
			asp = sz_x / sz_y;
		}
		else
			asp = me.forcedAspect;
		if(me.size_x > asp * me.size_y)
		{
			// x too large, so center x-wise
			me.imgSize = eY + eX * (me.size_y * asp / me.size_x);
		}
		else
		{
			// y too large, so center y-wise
			me.imgSize = eX + eY * (me.size_x / (asp * me.size_y));
		}
		if (me.zoomFactor)
			me.imgSize = me.imgSize * me.zoomFactor;
		me.imgOrigin = '0.5 0.5 0' - 0.5 * me.imgSize;
	}
}
void Image_setZoom(entity me, float z)
{
	if (z < 0)
		me.zoomFactor = -z;
	else if (z == 0)
		me.zoomFactor = 1;
	else
		me.zoomFactor *= z;
	me.zoomFactor = bound(1/16, me.zoomFactor, 16);
	me.updateAspect(me);
}
void Image_resizeNotify(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
{
	SUPER(Image).resizeNotify(me, relOrigin, relSize, absOrigin, absSize);
	me.updateAspect(me);
}
#endif
