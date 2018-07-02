#include "picker.qh"

.bool pressed;

entity makeXonoticPicker()
{
	entity me;
	me = NEW(XonoticPicker);
	me.configureXonoticPicker(me);
	return me;
}

void XonoticPicker_configureXonoticPicker(entity me)
{
	me.realCellSize = eX / me.columns + eY / me.rows;
}

float XonoticPicker_mouseMove(entity me, vector coords)
{
	vector prevFocusedCell = me.focusedCell;
	me.focusedCell_x = floor(coords.x * me.columns);
	me.focusedCell_y = floor(coords.y * me.rows);

	if(me.focusedCell.x < 0 || me.focusedCell.y < 0 ||
	   me.focusedCell.x >= me.columns || me.focusedCell.y >= me.rows)
	{
		me.focusedCell = '-1 -1 0';
		return 0;
	}

	if(me.focusedCell != prevFocusedCell)
		me.focusedCellAlpha = SKINALPHA_LISTBOX_FOCUSED;

	return 1;
}

float XonoticPicker_mouseDrag(entity me, vector coords)
{
	return me.mouseMove(me, coords);
}

METHOD(XonoticPicker, mousePress, bool(XonoticPicker this, vector pos))
{
	this.mouseMove(this, pos);

	if(this.focusedCell.x >= 0)
	{
		this.pressed = 1;
		this.pressedCell = this.focusedCell;
	}

	return true;
}

float XonoticPicker_mouseRelease(entity me, vector coords)
{
	if(!me.pressed)
		return 0;

	me.mouseMove(me, coords);

	if(me.focusedCell == me.pressedCell)
		me.cellSelect(me, me.focusedCell);

	me.pressed = 0;
	return 1;
}

float XonoticPicker_keyDown(entity me, float key, float ascii, float shift)
{
	switch(key)
	{
		case K_END:
		case K_KP_END:
			// lower left cell then left arrow to select the last valid cell
			me.focusedCell = eY * (me.rows - 1);
		case K_LEFTARROW:
		case K_KP_LEFTARROW:
			me.moveFocus(me, me.focusedCell, '-1 0 0');
			return 1;
		case K_HOME:
		case K_KP_HOME:
			// upper right cell then right arrow to select the first valid cell
			me.focusedCell = eX * (me.columns - 1);
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
		case K_ENTER:
		case K_KP_ENTER:
		case K_INS:
		case K_KP_INS:
			me.cellSelect(me, me.focusedCell);
			return 1;
	}
	return 0;
}

void XonoticPicker_moveFocus(entity me, vector initialCell, vector step)
{
	me.focusedCell_x = mod(me.focusedCell.x + step.x + me.columns, me.columns);
	me.focusedCell_y = mod(me.focusedCell.y + step.y + me.rows, me.rows);

	if(me.focusedCell != initialCell) // Recursion break
		if(!me.cellIsValid(me, me.focusedCell))
			me.moveFocus(me, initialCell, step);

	me.focusedCellAlpha = SKINALPHA_LISTBOX_FOCUSED;
}

void XonoticPicker_cellSelect(entity me, vector cell)
{
	me.selectedCell = cell;
}

bool XonoticPicker_cellIsValid(entity me, vector cell)
{
	return true;
}

void XonoticPicker_cellDraw(entity me, vector cell, vector cellPos)
{
}

void XonoticPicker_draw(entity me)
{
	float save;

	me.focusable = !me.disabled;

	save = draw_alpha;
	if(me.disabled)
		draw_alpha *= me.disabledAlpha;

	vector cell, cellPos;
	cell = '0 0 0';
	cellPos = '0 0 0';

	for(cell_y = 0; cell.y < me.rows; ++cell.y)
	{
		cellPos_y = mod(cell.y, me.rows) / me.rows;
		for(cell_x = 0; cell.x < me.columns; ++cell.x)
		{
			if(!me.cellIsValid(me, cell))
				continue;

			cellPos_x = mod(cell.x, me.columns) / me.columns;

			if(cell == me.selectedCell)
				draw_Fill(cellPos, me.realCellSize, SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED);
			else if(cell == me.focusedCell && me.focused)
			{
				if(!me.pressed || me.focusedCell == me.pressedCell)
				{
					me.focusedCellAlpha = getFadedAlpha(me.focusedCellAlpha, SKINALPHA_LISTBOX_FOCUSED, SKINFADEALPHA_LISTBOX_FOCUSED);
					draw_Fill(cellPos, me.realCellSize, SKINCOLOR_LISTBOX_FOCUSED, me.focusedCellAlpha);
				}
			}

			me.cellDraw(me, cell, cellPos);
		}
	}

	draw_alpha = save;

	SUPER(XonoticPicker).draw(me);
}
