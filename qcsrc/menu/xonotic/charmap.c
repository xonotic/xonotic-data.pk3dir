#ifdef INTERFACE
CLASS(XonoticCharmap) EXTENDS(Item)
	METHOD(XonoticCharmap, configureXonoticCharmap, void(entity, entity))
	METHOD(XonoticCharmap, mousePress, float(entity, vector))
	METHOD(XonoticCharmap, mouseRelease, float(entity, vector))
	METHOD(XonoticCharmap, mouseMove, float(entity, vector))
	METHOD(XonoticCharmap, mouseDrag, float(entity, vector))
	METHOD(XonoticCharmap, keyDown, float(entity, float, float, float))
	METHOD(XonoticCharmap, focusLeave, void(entity))
	METHOD(XonoticCharmap, resizeNotify, void(entity, vector, vector, vector, vector))
	METHOD(XonoticCharmap, draw, void(entity))
	ATTRIB(XonoticCharmap, focusable, float, 1)

	METHOD(XonoticCharmap, moveFocus, void(entity, vector, vector))
	METHOD(XonoticCharmap, enterChar, void(entity))
	ATTRIB(XonoticCharmap, inputBox, entity, NULL)
	ATTRIB(XonoticCharmap, realFontSize, vector, '0 0 0')
	ATTRIB(XonoticCharmap, realCellSize, vector, '0 0 0')
	ATTRIB(XonoticCharmap, focusedCell, vector, '-1 -1 0')
	ATTRIB(XonoticCharmap, previouslyFocusedCell, vector, '-1 -1 0')
ENDCLASS(XonoticCharmap)
entity makeXonoticCharmap(entity controlledInputBox);
#endif

#ifdef IMPLEMENTATION

#define CHARMAP_COLS 14
#define CHARMAP_ROWS 10
string charmapRow0[CHARMAP_COLS];
string charmapRow1[CHARMAP_COLS];
string charmapRow2[CHARMAP_COLS];
string charmapRow3[CHARMAP_COLS];
string charmapRow4[CHARMAP_COLS];
string charmapRow5[CHARMAP_COLS];
string charmapRow6[CHARMAP_COLS];
string charmapRow7[CHARMAP_COLS];
string charmapRow8[CHARMAP_COLS];
string charmapRow9[CHARMAP_COLS];

void charmap_initializeRows()
{
	if (charmapRow0[0] != "")
		return;

	charmapRow0[0]  = strzone(chr(0x2190));
	charmapRow0[1]  = strzone(chr(0x2191));
	charmapRow0[2]  = strzone(chr(0x2192));
	charmapRow0[3]  = strzone(chr(0x2193));
	charmapRow0[4]  = strzone(chr(0x25c0));
	charmapRow0[5]  = strzone(chr(0x25b2));
	charmapRow0[6]  = strzone(chr(0x25b6));
	charmapRow0[7]  = strzone(chr(0x25bc));
	charmapRow0[8]  = strzone(chr(0x25e3));
	charmapRow0[9]  = strzone(chr(0x25e4));
	charmapRow0[10] = strzone(chr(0x25e5));
	charmapRow0[11] = strzone(chr(0x25e2));
	charmapRow0[12] = strzone(chr(0x2770));
	charmapRow0[13] = strzone(chr(0x2771));

	charmapRow1[0]  = strzone(chr(0x25A0));
	charmapRow1[1]  = strzone(chr(0x25AC));
	charmapRow1[2]  = strzone(chr(0x25AE));
	charmapRow1[3]  = strzone(chr(0x25B0));
	charmapRow1[4]  = strzone(chr(0x25C6));
	charmapRow1[5]  = strzone(chr(0x25CF));
	charmapRow1[6]  = strzone(chr(0x2605));
	charmapRow1[7]  = strzone(chr(0x2764));
	charmapRow1[8]  = strzone(chr(0x1F52B));
	charmapRow1[9]  = strzone(chr(0x2316));
	charmapRow1[10] = strzone(chr(0x2747));
	charmapRow1[11] = strzone(chr(0x2748));
	charmapRow1[12] = strzone(chr(0x2772));
	charmapRow1[13] = strzone(chr(0x2773));

	charmapRow2[0]  = strzone(chr(0x1F47D));
	charmapRow2[1]  = strzone(chr(0x2620));
	charmapRow2[2]  = strzone(chr(0x2622));
	charmapRow2[3]  = strzone(chr(0x2623));
	charmapRow2[4]  = strzone(chr(0x2699));
	charmapRow2[5]  = strzone(chr(0x269B));
	charmapRow2[6]  = strzone(chr(0x26A0));
	charmapRow2[7]  = strzone(chr(0x26A1));
	charmapRow2[8]  = strzone(chr(0x274C));
	charmapRow2[9]  = strzone(chr(0x1F680));
	charmapRow2[10] = strzone(chr(0x1F30C));
	charmapRow2[11] = strzone(chr(0x1F30D));
	charmapRow2[12] = strzone(chr(0x1F30E));
	charmapRow2[13] = strzone(chr(0x1F30F));

	charmapRow3[0]  = strzone(chr(0x1F601));
	charmapRow3[1]  = strzone(chr(0x1F603));
	charmapRow3[2]  = strzone(chr(0x1F604));
	charmapRow3[3]  = strzone(chr(0x1F606));
	charmapRow3[4]  = strzone(chr(0x1F607));
	charmapRow3[5]  = strzone(chr(0x1F608));
	charmapRow3[6]  = strzone(chr(0x1F609));
	charmapRow3[7]  = strzone(chr(0x1F60A));
	charmapRow3[8]  = strzone(chr(0x1F60E));
	charmapRow3[9]  = strzone(chr(0x1F610));
	charmapRow3[10] = strzone(chr(0x1F612));
	charmapRow3[11] = strzone(chr(0x1F618));
	charmapRow3[12] = string_null;
	charmapRow3[13] = string_null;

	charmapRow4[0]  = strzone(chr(0x1F615));
	charmapRow4[1]  = strzone(chr(0x1F61B));
	charmapRow4[2]  = strzone(chr(0x1F61D));
	charmapRow4[3]  = strzone(chr(0x1F61E));
	charmapRow4[4]  = strzone(chr(0x1F61F));
	charmapRow4[5]  = strzone(chr(0x1F620));
	charmapRow4[6]  = strzone(chr(0x1F623));
	charmapRow4[7]  = strzone(chr(0x1F62D));
	charmapRow4[8]  = strzone(chr(0x1F62E));
	charmapRow4[9]  = strzone(chr(0x1F632));
	charmapRow4[10] = strzone(chr(0x1F635));
	charmapRow4[11] = strzone(chr(0x1F634));
	charmapRow4[12] = string_null;
	charmapRow4[13] = string_null;

	// Legacy characters:

	float i;
	for(i = 0; i < 14; ++i)
		charmapRow5[i] = strzone(chr(0xE0E1 + i));

	for(i = 0; i < 12; ++i)
		charmapRow6[i] = strzone(chr(0xE0EF + i));
	charmapRow6[12] = strzone(chr(0xE010));
	charmapRow6[13] = strzone(chr(0xE011));

	for(i = 0; i < 10; ++i)
		charmapRow7[i] = strzone(chr(0xE0B0 + i));
	charmapRow7[10] = strzone(chr(0xE0A1));
	charmapRow7[11] = strzone(chr(0xE0BF));
	charmapRow7[12] = strzone(chr(0xE0A6));
	charmapRow7[13] = strzone(chr(0xE0A5));

	for(i = 0; i < 14; ++i)
		charmapRow8[i] = strzone(chr(0xE0C1 + i));

	for(i = 0; i < 12; ++i)
		charmapRow9[i] = strzone(chr(0xE0CF + i));
	charmapRow9[12] = strzone(chr(0xE05B));
	charmapRow9[13] = strzone(chr(0xE05D));
}

string charmap_cellToChar(vector cell)
{
	if(!cvar("utf8_enable"))
		return "";

	if(cell_x >= CHARMAP_COLS)
		return "";

	switch(cell_y)
	{
		case 0: return charmapRow0[cell_x];
		case 1: return charmapRow1[cell_x];
		case 2: return charmapRow2[cell_x];
		case 3: return charmapRow3[cell_x];
		case 4: return charmapRow4[cell_x];
		case 5: return charmapRow5[cell_x];
		case 6: return charmapRow6[cell_x];
		case 7: return charmapRow7[cell_x];
		case 8: return charmapRow8[cell_x];
		case 9: return charmapRow9[cell_x];
	}
	return "";
}

entity makeXonoticCharmap(entity controlledInputBox)
{
	charmap_initializeRows();

	entity me;
	me = spawnXonoticCharmap();
	me.configureXonoticCharmap(me, controlledInputBox);
	return me;
}

void XonoticCharmap_configureXonoticCharmap(entity me, entity controlledInputBox)
{
	me.inputBox = controlledInputBox;
	me.realCellSize = eX / CHARMAP_COLS + eY / CHARMAP_ROWS;
}

void XonoticCharmap_resizeNotify(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
{
	SUPER(XonoticCharmap).resizeNotify(me, relOrigin, relSize, absOrigin, absSize);

	if((me.realCellSize_x * absSize_x) > (me.realCellSize_y * absSize_y))
	{
		me.realFontSize_x = me.realCellSize_y * absSize_y / absSize_x;
		me.realFontSize_y = me.realCellSize_y;
	}
	else
	{
		me.realFontSize_x = me.realCellSize_x;
		me.realFontSize_y = me.realCellSize_x * absSize_x / absSize_y;
	}
}

float XonoticCharmap_mouseMove(entity me, vector coords)
{
	me.focusedCell_x = floor(coords_x * CHARMAP_COLS);
	me.focusedCell_y = floor(coords_y * CHARMAP_ROWS);

	if(me.focusedCell_x < 0 || me.focusedCell_y < 0 ||
	   me.focusedCell_x >= CHARMAP_COLS || me.focusedCell_y >= CHARMAP_ROWS)
	{
		me.focusedCell = '-1 -1 0';
		return 0;
	}

	return 1;
}

float XonoticCharmap_mouseDrag(entity me, vector coords)
{
	return me.mouseMove(me, coords);
}

float XonoticCharmap_mousePress(entity me, vector coords)
{
	me.mouseMove(me, coords);

	if(me.focusedCell_x >= 0)
	{
		me.pressed = 1;
		me.previouslyFocusedCell = me.focusedCell;
	}

	return 1;
}

float XonoticCharmap_mouseRelease(entity me, vector coords)
{
	if(!me.pressed)
		return 0;

	me.mouseMove(me, coords);

	if(me.focusedCell == me.previouslyFocusedCell)
		me.enterChar(me);

	me.pressed = 0;
	return 1;
}

float XonoticCharmap_keyDown(entity me, float key, float ascii, float shift)
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
			me.focusedCell_x = CHARMAP_COLS - 1;
			me.focusedCell_y = CHARMAP_ROWS - 1;
			return 1;
		case K_ENTER:
		case K_KP_ENTER:
		case K_INS:
		case K_KP_INS:
			me.enterChar(me);
			return 1;
		default:
			return me.inputBox.keyDown(me.inputBox, key, ascii, shift);
	}
}

void XonoticCharmap_moveFocus(entity me, vector initialCell, vector step)
{
	me.focusedCell_x = mod(me.focusedCell_x + step_x + CHARMAP_COLS, CHARMAP_COLS);
	me.focusedCell_y = mod(me.focusedCell_y + step_y + CHARMAP_ROWS, CHARMAP_ROWS);

	if(me.focusedCell != initialCell) // Recursion break
		if(charmap_cellToChar(me.focusedCell) == "")
			me.moveFocus(me, initialCell, step);
}

void XonoticCharmap_enterChar(entity me)
{
	string character = charmap_cellToChar(me.focusedCell);
	if(character != "")
		me.inputBox.enterText(me.inputBox, character);
}

void XonoticCharmap_focusLeave(entity me)
{
	me.inputBox.saveCvars(me.inputBox);
}

void XonoticCharmap_draw(entity me)
{
	string character;
	vector cell, cellPos, charPos;
	cell = '0 0 0';
	cellPos = '0 0 0';
	charPos = '0 0 0';

	for(cell_y = 0; cell_y < CHARMAP_ROWS; ++cell_y)
	{
		charPos_y = cell_y / CHARMAP_ROWS + (me.realCellSize_y - me.realFontSize_y) / 2;
		for(cell_x = 0; cell_x < CHARMAP_COLS; ++cell_x)
		{
			character = charmap_cellToChar(cell);

			if(character == "")
				continue;

			// Draw focused cell
			if(cell == me.focusedCell && me.focused)
			{
				if(!me.pressed || me.focusedCell == me.previouslyFocusedCell)
				{
					cellPos_x = mod(me.focusedCell_x, CHARMAP_COLS) / CHARMAP_COLS;
					cellPos_y = mod(me.focusedCell_y, CHARMAP_ROWS) / CHARMAP_ROWS;
					draw_Fill(cellPos, me.realCellSize, SKINCOLOR_CHARMAP_FOCUS, SKINALPHA_CHARMAP_FOCUS);
				}
			}

			// Draw character
			charPos_x = cell_x / CHARMAP_COLS + me.realCellSize_x / 2;
			draw_CenterText(charPos, character, me.realFontSize, SKINCOLOR_CHARMAP_CHAR, SKINALPHA_CHARMAP_CHAR, 0);
		}
	}
}
#endif
