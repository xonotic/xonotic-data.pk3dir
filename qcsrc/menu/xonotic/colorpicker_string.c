#ifdef INTERFACE
CLASS(XonoticColorpickerString) EXTENDS(Image)
	METHOD(XonoticColorpickerString, configureXonoticColorpickerString, void(entity, string, string))
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
entity makeXonoticColorpickerString(string theCvar, string theDefaultCvar);
#endif

#ifdef IMPLEMENTATION
entity makeXonoticColorpickerString(string theCvar, string theDefaultCvar)
{
	entity me;
	me = spawnXonoticColorpickerString();
	me.configureXonoticColorpickerString(me, theCvar, theDefaultCvar);
	return me;
}

void XonoticColorpickerString_configureXonoticColorpickerString(entity me, string theCvar, string theDefaultCvar)
{
	me.cvarName = theCvar;
	me.configureImage(me, me.image);
	if(cvar_string(theCvar) != "")
		me.prevcoords = color_hslimage(stov(cvar_string(theCvar)), me.imagemargin);
	else // use default
		me.prevcoords = color_hslimage(stov(cvar_string(theDefaultCvar)), me.imagemargin);
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

	if(!me.disabled)
	{
		cvar_set(me.cvarName, sprintf("%v", hslimage_color(me.prevcoords, me.imagemargin)));
		draw_Picture(me.imgOrigin + me.prevcoords - 0.5 * sz, strcat(me.src, "_selected"), sz, '1 1 1', 1);
	}
	draw_alpha = save;
}
#endif
