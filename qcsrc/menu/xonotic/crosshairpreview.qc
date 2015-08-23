#ifndef CROSSHAIRPREVIEW_H
#define CROSSHAIRPREVIEW_H
#include "../item.qc"
CLASS(XonoticCrosshairPreview, Item)
	METHOD(XonoticCrosshairPreview, configureXonoticCrosshairPreview, void(entity));
	METHOD(XonoticCrosshairPreview, draw, void(entity));
	ATTRIB(XonoticCrosshairPreview, src, string, string_null)
	ATTRIB(XonoticCrosshairPreview, src2, string, string_null)
	ATTRIB(XonoticCrosshairPreview, disabled, float, 0)
	ATTRIB(XonoticCrosshairPreview, disabledAlpha, float, SKINALPHA_DISABLED)
ENDCLASS(XonoticCrosshairPreview)
entity makeXonoticCrosshairPreview();
#endif

#ifdef IMPLEMENTATION
entity makeXonoticCrosshairPreview()
{
	entity me;
	me = NEW(XonoticCrosshairPreview);
	me.configureXonoticCrosshairPreview(me);
	return me;
}

void XonoticCrosshairPreview_configureXonoticCrosshairPreview(entity me)
{
	me.src = strzone(strcat("/gfx/crosshair", cvar_string("crosshair")));
	me.src2 = "/gfx/crosshairdot";
}

void XonoticCrosshairPreview_draw(entity me)
{
	float save;
	save = draw_alpha;
	if(me.disabled)
		draw_alpha *= me.disabledAlpha;

	vector sz, rgb;
	float a;
	rgb = stov(cvar_string("crosshair_color"));
	a = cvar("crosshair_alpha");
	if(me.src)
		strunzone(me.src);
	me.src = strzone(strcat("/gfx/crosshair", cvar_string("crosshair")));

	sz = draw_PictureSize(me.src);
	sz = globalToBoxSize(sz, me.size);
	sz = sz * cvar("crosshair_size");

	draw_Picture('0.5 0.5 0' - 0.5 * sz, me.src, sz, rgb, a);
	if(cvar("crosshair_dot"))
	{
		if(cvar("crosshair_dot_color_custom") && (cvar_string("crosshair_dot_color") != "0"))
			rgb = stov(cvar_string("crosshair_dot_color"));

		draw_Picture('0.5 0.5 0' - 0.5 * sz * cvar("crosshair_dot_size"), me.src2, sz * cvar("crosshair_dot_size"), rgb, a * cvar("crosshair_dot_alpha"));
	}

	draw_alpha = save;

	SUPER(XonoticCrosshairPreview).draw(me);
}
#endif
