#ifdef INTERFACE
CLASS(XonoticColorpickerString) EXTENDS(Image)
	METHOD(XonoticColorpickerString, configureXonoticColorpickerString, void(entity, string))
	METHOD(XonoticColorpickerString, mousePress, float(entity, vector))
	METHOD(XonoticColorpickerString, mouseRelease, float(entity, vector))
	METHOD(XonoticColorpickerString, mouseDrag, float(entity, vector))
	ATTRIB(XonoticColorpickerString, cvarName, string, string_null)
	ATTRIB(XonoticColorpickerString, prevcoords, vector, '0 0 0')
	ATTRIB(XonoticColorpickerString, image, string, SKINGFX_COLORPICKER)
	ATTRIB(XonoticColorpickerString, imagemargin, vector, SKINMARGIN_COLORPICKER)
	ATTRIB(XonoticColorpickerString, focusable, float, 1)
	METHOD(XonoticColorpickerString, draw, void(entity))
	ATTRIB(XonoticColorpickerString, disabledAlpha, float, 0.3)
ENDCLASS(XonoticColorpickerString)
entity makeXonoticColorpickerString(string theCvar);
#endif

#ifdef IMPLEMENTATION
entity makeXonoticColorpickerString(string theCvar)
{
	entity me;
	me = spawnXonoticColorpickerString();
	me.configureXonoticColorpickerString(me, theCvar);
	return me;
}

void XonoticColorpickerString_configureXonoticColorpickerString(entity me, string theCvar)
{
	me.cvarName = theCvar;
	me.configureImage(me, me.image);
	me.prevcoords = '1 1 0';
}

float XonoticColorpickerString_mousePress(entity me, vector coords)
{
	me.mouseDrag(me, coords);
	return 1;
}

float XonoticColorpickerString_mouseDrag(entity me, vector coords)
{
	if(me.disabled)
		return 0;
	vector margin;
	margin = me.imagemargin;
	if(coords_x >= margin_x)
	if(coords_y >= margin_y)
	if(coords_x <= 1 - margin_x)
	if(coords_y <= 1 - margin_y)
	{
		cvar_set(me.cvarName, sprintf("%v", hslimage_color(coords, margin)));
		me.prevcoords = coords;
	}

	return 1;
}

float XonoticColorpickerString_mouseRelease(entity me, vector coords)
{
	me.mouseDrag(me, coords);
	return 1;
}

void XonoticColorpickerString_draw(entity me)
{
	float save;
	save = draw_alpha;
	if(me.disabled)
		draw_alpha *= me.disabledAlpha;

	SUPER(XonoticColorpickerString).draw(me);

	vector sz;
	sz = draw_PictureSize(strcat(me.src, "_selected"));
	sz = globalToBoxSize(sz, draw_scale);

	if(me.disabled)
		me.prevcoords = '1 1 0';
	else
		draw_Picture(me.imgOrigin + me.prevcoords - 0.5 * sz, strcat(me.src, "_selected"), sz, '1 1 1', 1);
	draw_alpha = save;
}
#endif
