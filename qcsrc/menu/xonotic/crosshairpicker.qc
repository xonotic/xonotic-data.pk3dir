#ifdef INTERFACE
CLASS(XonoticCrosshairPicker) EXTENDS(XonoticPicker)
	METHOD(XonoticCrosshairPicker, configureXonoticCrosshairPicker, void(entity))

	ATTRIB(XonoticCrosshairPicker, rows, float, 3)
	ATTRIB(XonoticCrosshairPicker, columns, float, 12)

	METHOD(XonoticCrosshairPicker, cellSelect, void(entity))
	METHOD(XonoticCrosshairPicker, cellIsValid, bool(entity, vector))
	METHOD(XonoticCrosshairPicker, cellDraw, void(entity, vector, vector, float))
ENDCLASS(XonoticCrosshairPicker)
entity makeXonoticCrosshairPicker();
#endif

#ifdef IMPLEMENTATION

string crosshairpicker_cellToCrosshair(entity me, vector cell)
{
	float crosshair = 31 + cell.y * me.columns + cell.x;

	if (crosshair >= 31 && crosshair < 31 + me.columns * me.rows)
		return ftos(crosshair);
	else
		return "";
}

entity makeXonoticCrosshairPicker()
{
	entity me;
	me = spawnXonoticCrosshairPicker();
	me.configureXonoticCrosshairPicker(me);
	return me;
}

void XonoticCrosshairPicker_configureXonoticCrosshairPicker(entity me)
{
	me.configureXonoticPicker(me);
}

void XonoticCrosshairPicker_cellSelect(entity me)
{
	cvar_set("crosshair", crosshairpicker_cellToCrosshair(me, me.focusedCell));
}

bool XonoticCrosshairPicker_cellIsValid(entity me, vector cell)
{
	if(crosshairpicker_cellToCrosshair(me, cell) == "")
		return false;
	return true;
}

void XonoticCrosshairPicker_cellDraw(entity me, vector cell, vector cellPos, float highlightedTime)
{
	vector sz, rgb;
	string cross = strcat("/gfx/crosshair", crosshairpicker_cellToCrosshair(me, cell));
	sz = draw_PictureSize(cross);
	sz = globalToBoxSize(sz, me.size);

	float ar = sz.x / sz.y;
	sz.x = me.realCellSize.x;
	sz.y = sz.x / ar;
	sz = sz * 0.95;

	rgb = '1 1 1';

	vector crosshairPos = cellPos + 0.5 * me.realCellSize;
	draw_Picture(crosshairPos - 0.5 * sz, cross, sz, rgb, me.alpha);

	if(cvar("crosshair_dot"))
	{
		if(cvar("crosshair_dot_color_custom") && (cvar_string("crosshair_dot_color") != "0"))
			rgb = stov(cvar_string("crosshair_dot_color"));

		draw_Picture(crosshairPos - 0.5 * sz * cvar("crosshair_dot_size"), "/gfx/crosshairdot", sz * cvar("crosshair_dot_size"), rgb, me.alpha);
	}
}
#endif
