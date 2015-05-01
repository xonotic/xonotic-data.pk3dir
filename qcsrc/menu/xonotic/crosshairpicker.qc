#ifdef INTERFACE
CLASS(XonoticCrosshairPicker) EXTENDS(Item)
	METHOD(XonoticCrosshairPicker, configureXonoticCrosshairPicker, void(entity))
	METHOD(XonoticCrosshairPicker, mousePress, float(entity, vector))
	METHOD(XonoticCrosshairPicker, mouseRelease, float(entity, vector))
	METHOD(XonoticCrosshairPicker, mouseMove, float(entity, vector))
	METHOD(XonoticCrosshairPicker, mouseDrag, float(entity, vector))
	METHOD(XonoticCrosshairPicker, keyDown, float(entity, float, float, float))
	METHOD(XonoticCrosshairPicker, draw, void(entity))
	ATTRIB(XonoticCrosshairPicker, focusable, float, 1)
	ATTRIB(XonoticCrosshairPicker, disabled, float, 0)
	ATTRIB(XonoticCrosshairPicker, alpha, float, 1)
	ATTRIB(XonoticCrosshairPicker, disabledAlpha, float, SKINALPHA_DISABLED)

	METHOD(XonoticCrosshairPicker, moveFocus, void(entity, vector, vector))
	METHOD(XonoticCrosshairPicker, setCrosshair, void(entity))
	ATTRIB(XonoticCrosshairPicker, realCellSize, vector, '0 0 0')
	ATTRIB(XonoticCrosshairPicker, focusedCell, vector, '-1 -1 0')
	ATTRIB(XonoticCrosshairPicker, focusedCellTime, float, 0)
	ATTRIB(XonoticCrosshairPicker, pressedCell, vector, '-1 -1 0')
ENDCLASS(XonoticCrosshairPicker)
entity makeXonoticCrosshairPicker();
#endif

#ifdef IMPLEMENTATION

const float CROSSHAIRPICKER_COLS = 12;
const float CROSSHAIRPICKER_ROWS = 3;

string crosshairpicker_cellToCrosshair(vector cell)
{
	float crosshair = 31 + cell.y * CROSSHAIRPICKER_COLS + cell.x;

	if (crosshair >= 31 && crosshair < 31 + CROSSHAIRPICKER_COLS * CROSSHAIRPICKER_ROWS)
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
	me.realCellSize = eX / CROSSHAIRPICKER_COLS + eY / CROSSHAIRPICKER_ROWS;
}

float XonoticCrosshairPicker_mouseMove(entity me, vector coords)
{
	vector prevFocusedCell = me.focusedCell;
	me.focusedCell_x = floor(coords.x * CROSSHAIRPICKER_COLS);
	me.focusedCell_y = floor(coords.y * CROSSHAIRPICKER_ROWS);

	if(me.focusedCell.x < 0 || me.focusedCell.y < 0 ||
	   me.focusedCell.x >= CROSSHAIRPICKER_COLS || me.focusedCell.y >= CROSSHAIRPICKER_ROWS)
	{
		me.focusedCell = '-1 -1 0';
		return 0;
	}

	if(me.focusedCell != prevFocusedCell)
		me.focusedCellTime = time;

	return 1;
}

float XonoticCrosshairPicker_mouseDrag(entity me, vector coords)
{
	return me.mouseMove(me, coords);
}

float XonoticCrosshairPicker_mousePress(entity me, vector coords)
{
	me.mouseMove(me, coords);

	if(me.focusedCell.x >= 0)
	{
		me.pressed = 1;
		me.pressedCell = me.focusedCell;
	}

	return 1;
}

float XonoticCrosshairPicker_mouseRelease(entity me, vector coords)
{
	if(!me.pressed)
		return 0;

	me.mouseMove(me, coords);

	if(me.focusedCell == me.pressedCell)
		me.setCrosshair(me);

	me.pressed = 0;
	return 1;
}

float XonoticCrosshairPicker_keyDown(entity me, float key, float ascii, float shift)
{
	switch(key)
	{
		case K_LEFTARROW:
		case K_KP_LEFTARROW:
			me.moveFocus(me, me.focusedCell, '-1 0 0');
			return 1;
		case K_RIGHTARROW:
		case K_KP_RIGHTARROW:
			me.moveFocus(me, me.focusedCell, '1 0 0');
			return 1;
		case K_UPARROW:
		case K_KP_UPARROW:
			me.moveFocus(me, me.focusedCell, '0 -1 0');
			return 1;
		case K_DOWNARROW:
		case K_KP_DOWNARROW:
			me.moveFocus(me, me.focusedCell, '0 1 0');
			return 1;
		case K_HOME:
		case K_KP_HOME:
			me.focusedCell = '0 0 0';
			return 1;
		case K_END:
		case K_KP_END:
			me.focusedCell_x = CROSSHAIRPICKER_COLS - 1;
			me.focusedCell_y = CROSSHAIRPICKER_ROWS - 1;
			return 1;
		case K_ENTER:
		case K_KP_ENTER:
		case K_INS:
		case K_KP_INS:
			me.setCrosshair(me);
			return 1;
	}
	return 0;
}

void XonoticCrosshairPicker_moveFocus(entity me, vector initialCell, vector step)
{
	me.focusedCell_x = mod(me.focusedCell.x + step.x + CROSSHAIRPICKER_COLS, CROSSHAIRPICKER_COLS);
	me.focusedCell_y = mod(me.focusedCell.y + step.y + CROSSHAIRPICKER_ROWS, CROSSHAIRPICKER_ROWS);

	if(me.focusedCell != initialCell) // Recursion break
		if(crosshairpicker_cellToCrosshair(me.focusedCell) == "")
			me.moveFocus(me, initialCell, step);
}

void XonoticCrosshairPicker_setCrosshair(entity me)
{
	cvar_set("crosshair", crosshairpicker_cellToCrosshair(me.focusedCell));
}

void XonoticCrosshairPicker_draw(entity me)
{
	vector sz, rgb;
	float save;

	me.focusable = !me.disabled;

	save = draw_alpha;
	if(me.disabled)
		draw_alpha *= me.disabledAlpha;

	string crosshair;
	vector cell, cellPos, crosshairPos;
	cell = '0 0 0';
	cellPos = '0 0 0';
	crosshairPos = '0 0 0';


	for(cell_y = 0; cell.y < CROSSHAIRPICKER_ROWS; ++cell.y)
	{
		crosshairPos_y = cell.y / CROSSHAIRPICKER_ROWS + 0.5 * me.realCellSize.y;
		for(cell_x = 0; cell.x < CROSSHAIRPICKER_COLS; ++cell.x)
		{
			crosshair = crosshairpicker_cellToCrosshair(cell);

			if(crosshair == "")
				continue;

			// Draw focused cell
			if(cell == me.focusedCell && me.focused)
			{
				if(!me.pressed || me.focusedCell == me.pressedCell)
				{
					cellPos_x = mod(me.focusedCell.x, CROSSHAIRPICKER_COLS) / CROSSHAIRPICKER_COLS;
					cellPos_y = mod(me.focusedCell.y, CROSSHAIRPICKER_ROWS) / CROSSHAIRPICKER_ROWS;
					draw_Fill(cellPos, me.realCellSize, SKINCOLOR_LISTBOX_FOCUSED, getHighlightAlpha(SKINALPHA_LISTBOX_FOCUSED, SKINFADEALPHA_LISTBOX_FOCUSED, me.focusedCellTime));
				}
			}

			// Draw crosshair
			crosshairPos_x = cell.x / CROSSHAIRPICKER_COLS + 0.5 * me.realCellSize.x;
			string cross = strcat("/gfx/crosshair", crosshairpicker_cellToCrosshair(cell));
			sz = draw_PictureSize(cross);
			sz = globalToBoxSize(sz, me.size);

			float ar = sz.x / sz.y;
			sz.x = me.realCellSize.x;
			sz.y = sz.x / ar;

			sz = sz * 0.95;

			rgb = '1 1 1';
			draw_Picture(crosshairPos - 0.5 * sz, cross, sz, rgb, me.alpha);
			if(cvar("crosshair_dot"))
			{
				if(cvar("crosshair_dot_color_custom") && (cvar_string("crosshair_dot_color") != "0"))
					rgb = stov(cvar_string("crosshair_dot_color"));

				draw_Picture(crosshairPos - 0.5 * sz * cvar("crosshair_dot_size"), "/gfx/crosshairdot", sz * cvar("crosshair_dot_size"), rgb, me.alpha);
			}
		}
	}

	draw_alpha = save;

	SUPER(XonoticCrosshairPicker).draw(me);
}
#endif
