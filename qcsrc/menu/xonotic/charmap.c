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

string CHARMAP =
	"★◆■▮▰▬◣◤◥◢◀▲▶▼"
	"🌍🌎🌏🚀🌌👽🔫⌖❇❈←↑→↓"
	"☠☣☢⚛⚡⚙🔥❌⚠⛔❰❱❲❳"
	"😃😊😁😄😆😎😈😇😉😛😝😘❤ "
	"😐😒😕😮😲😞😟😠😣😭😵😴  "
	"\xEE\x83\xA1\xEE\x83\xA2\xEE\x83\xA3\xEE\x83\xA4\xEE\x83\xA5\xEE\x83\xA6\xEE\x83\xA7"
	"\xEE\x83\xA8\xEE\x83\xA9\xEE\x83\xAA\xEE\x83\xAB\xEE\x83\xAC\xEE\x83\xAD\xEE\x83\xAE"
	"\xEE\x83\xAF\xEE\x83\xB0\xEE\x83\xB1\xEE\x83\xB2\xEE\x83\xB3\xEE\x83\xB4\xEE\x83\xB5"
	"\xEE\x83\xB6\xEE\x83\xB7\xEE\x83\xB8\xEE\x83\xB9\xEE\x83\xBA\xEE\x80\x90\xEE\x80\x91"
	"\xEE\x82\xB0\xEE\x82\xB1\xEE\x82\xB2\xEE\x82\xB3\xEE\x82\xB4\xEE\x82\xB5\xEE\x82\xB6"
	"\xEE\x82\xB7\xEE\x82\xB8\xEE\x82\xB9\xEE\x82\xA1\xEE\x82\xBF\xEE\x82\xA6\xEE\x82\xA5"
	"\xEE\x83\x81\xEE\x83\x82\xEE\x83\x83\xEE\x83\x84\xEE\x83\x85\xEE\x83\x86\xEE\x83\x87"
	"\xEE\x83\x88\xEE\x83\x89\xEE\x83\x8A\xEE\x83\x8B\xEE\x83\x8C\xEE\x83\x8D\xEE\x83\x8E"
	"\xEE\x83\x8F\xEE\x83\x90\xEE\x83\x91\xEE\x83\x92\xEE\x83\x93\xEE\x83\x94\xEE\x83\x95"
	"\xEE\x83\x96\xEE\x83\x97\xEE\x83\x98\xEE\x83\x99\xEE\x83\x9A\xEE\x81\x9B\xEE\x81\x9D";

string charmap_cellToChar(vector cell)
{
	string character = substring(CHARMAP, cell_y * CHARMAP_COLS + cell_x, 1);

	if (character != " ")
		return character;
	else
		return "";
}

entity makeXonoticCharmap(entity controlledInputBox)
{
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

	float maxFontWidth = SKINFONTSIZE_NORMAL / absSize_x;
	float maxFontHeight = SKINFONTSIZE_NORMAL / absSize_y;

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

	if(me.realFontSize_x > maxFontWidth || me.realFontSize_y > maxFontHeight)
		me.realFontSize = eX * maxFontWidth + eY * maxFontHeight;
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

	float CHAR_OFFSET_X = me.realCellSize_x / 2;
	float CHAR_OFFSET_Y = (me.realCellSize_y - me.realFontSize_y) / 2;

	for(cell_y = 0; cell_y < CHARMAP_ROWS; ++cell_y)
	{
		charPos_y = cell_y / CHARMAP_ROWS + CHAR_OFFSET_Y;
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
			charPos_x = cell_x / CHARMAP_COLS + CHAR_OFFSET_X;
			draw_CenterText(charPos, character, me.realFontSize, SKINCOLOR_CHARMAP_CHAR, SKINALPHA_CHARMAP_CHAR, 0);
		}
	}
}
#endif
