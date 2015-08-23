#ifndef CROSSHAIRPICKER_H
#define CROSSHAIRPICKER_H
#include "picker.qc"
CLASS(XonoticCrosshairPicker, XonoticPicker)
	METHOD(XonoticCrosshairPicker, configureXonoticCrosshairPicker, void(entity));

	ATTRIB(XonoticCrosshairPicker, rows, float, 3)
	ATTRIB(XonoticCrosshairPicker, columns, float, 12)

	METHOD(XonoticCrosshairPicker, cellSelect, void(entity, vector));
	METHOD(XonoticCrosshairPicker, cellIsValid, bool(entity, vector));
	METHOD(XonoticCrosshairPicker, cellDraw, void(entity, vector, vector));
ENDCLASS(XonoticCrosshairPicker)
entity makeXonoticCrosshairPicker();
#endif

#ifdef IMPLEMENTATION

string crosshairpicker_cellToCrosshair(entity me, vector cell)
{
	if(cell.x < 0 || cell.x >= me.columns || cell.y < 0 || cell.y >= me.rows)
		return "";
	return ftos(31 + cell.y * me.columns + cell.x);
}

vector crosshairpicker_crosshairToCell(entity me, string crosshair_str)
{
	float crosshair = stof(crosshair_str) - 31;
	if(crosshair - floor(crosshair) > 0)
		return '-1 -1 0';
	return mod(crosshair, me.columns) * eX + floor(crosshair / me.columns) * eY;
}

entity makeXonoticCrosshairPicker()
{
	entity me;
	me = NEW(XonoticCrosshairPicker);
	me.configureXonoticCrosshairPicker(me);
	return me;
}

void XonoticCrosshairPicker_configureXonoticCrosshairPicker(entity me)
{
	me.configureXonoticPicker(me);
	SUPER(XonoticCrosshairPicker).cellSelect(me, crosshairpicker_crosshairToCell(me, cvar_string("crosshair")));
}

void XonoticCrosshairPicker_cellSelect(entity me, vector cell)
{
	cvar_set("crosshair", crosshairpicker_cellToCrosshair(me, me.focusedCell));
	SUPER(XonoticCrosshairPicker).cellSelect(me, me.focusedCell);
}

bool XonoticCrosshairPicker_cellIsValid(entity me, vector cell)
{
	if(crosshairpicker_cellToCrosshair(me, cell) == "")
		return false;
	return true;
}

void XonoticCrosshairPicker_cellDraw(entity me, vector cell, vector cellPos)
{
	vector sz;
	string cross = strcat("/gfx/crosshair", crosshairpicker_cellToCrosshair(me, cell));
	sz = draw_PictureSize(cross);
	sz = globalToBoxSize(sz, me.size);

	float ar = sz.x / sz.y;
	sz.x = me.realCellSize.x;
	sz.y = sz.x / ar;
	sz = sz * 0.95;

	vector crosshairPos = cellPos + 0.5 * me.realCellSize;
	draw_Picture(crosshairPos - 0.5 * sz, cross, sz, SKINCOLOR_CROSSHAIRPICKER_CROSSHAIR, SKINALPHA_CROSSHAIRPICKER_CROSSHAIR);

	if(cvar("crosshair_dot"))
		draw_Picture(crosshairPos - 0.5 * sz * cvar("crosshair_dot_size"), "/gfx/crosshairdot", sz * cvar("crosshair_dot_size"), SKINCOLOR_CROSSHAIRPICKER_CROSSHAIR, SKINALPHA_CROSSHAIRPICKER_CROSSHAIR);
}
#endif
