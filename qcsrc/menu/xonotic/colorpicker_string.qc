#include "colorpicker_string.qh"

.bool disabled;

entity makeXonoticColorpickerString(string theCvar, string theDefaultCvar)
{
	entity me;
	me = NEW(XonoticColorpickerString);
	me.configureXonoticColorpickerString(me, theCvar, theDefaultCvar);
	return me;
}

void XonoticColorpickerString_configureXonoticColorpickerString(entity me, string theCvar, string theDefaultCvar)
{
	me.configureImage(me, me.image);
	me.controlledCvar = (theCvar) ? theCvar : string_null;
	me.loadCvars(me);
}

void XonoticColorpickerString_loadCvars(entity me)
{
	if (!me.controlledCvar)
		return;

	if(substring(me.controlledCvar, -1, 1) == "_")
	{
		me.prevcoords = color_hslimage(
			eX * cvar(strcat(me.controlledCvar, "red")) +
			eY * cvar(strcat(me.controlledCvar, "green")) +
			eZ * cvar(strcat(me.controlledCvar, "blue")),
			me.imagemargin);
	}
	else
		me.prevcoords = color_hslimage(stov(cvar_string(me.controlledCvar)), me.imagemargin);
}

void XonoticColorpickerString_saveCvars(entity me)
{
	if (!me.controlledCvar)
		return;

	if(substring(me.controlledCvar, -1, 1) == "_")
	{
		vector v = hslimage_color(me.prevcoords, me.imagemargin);
		cvar_set(strcat(me.controlledCvar, "red"), ftos(v.x));
		cvar_set(strcat(me.controlledCvar, "green"), ftos(v.y));
		cvar_set(strcat(me.controlledCvar, "blue"), ftos(v.z));
	}
	else
		cvar_set(me.controlledCvar, sprintf("%v", hslimage_color(me.prevcoords, me.imagemargin)));
}

METHOD(XonoticColorpickerString, mousePress, bool(XonoticColorpickerString this, vector pos))
{
	this.mouseDrag(this, pos);
	return true;
}

float XonoticColorpickerString_mouseDrag(entity me, vector coords)
{
	if(me.disabled)
		return 0;
	vector margin;
	margin = me.imagemargin;
	if(coords.x >= margin.x)
	if(coords.y >= margin.y)
	if(coords.x <= 1 - margin.x)
	if(coords.y <= 1 - margin.y)
	{
		me.prevcoords = coords;
		me.saveCvars(me);
	}

	return 1;
}

float XonoticColorpickerString_mouseRelease(entity me, vector coords)
{
	m_play_click_sound(MENU_SOUND_SLIDE);
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
		draw_Picture(me.imgOrigin + me.prevcoords - 0.5 * sz, strcat(me.src, "_selected"), sz, '1 1 1', 1);

	draw_alpha = save;
}
