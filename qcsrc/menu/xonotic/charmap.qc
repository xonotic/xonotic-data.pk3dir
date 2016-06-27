#include "charmap.qh"

#include "inputbox.qh"

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

string charmap_cellToChar(entity me, vector cell)
{
	string character = substring(CHARMAP, cell.y * me.columns + cell.x, 1);

	if(character != " ")
		return character;
	else
		return "";
}

entity makeXonoticCharmap(entity controlledInputBox)
{
	entity me;
	me = NEW(XonoticCharmap);
	me.configureXonoticCharmap(me, controlledInputBox);
	return me;
}

void XonoticCharmap_configureXonoticCharmap(entity me, entity controlledInputBox)
{
	me.inputBox = controlledInputBox;
	me.configureXonoticPicker(me);
}

void XonoticCharmap_resizeNotify(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
{
	SUPER(XonoticCharmap).resizeNotify(me, relOrigin, relSize, absOrigin, absSize);

	float maxFontWidth = SKINFONTSIZE_NORMAL / absSize.x;
	float maxFontHeight = SKINFONTSIZE_NORMAL / absSize.y;

	if((me.realCellSize.x * absSize.x) > (me.realCellSize.y * absSize.y))
	{
		me.realFontSize_x = me.realCellSize.y * absSize.y / absSize.x;
		me.realFontSize_y = me.realCellSize.y;
	}
	else
	{
		me.realFontSize_x = me.realCellSize.x;
		me.realFontSize_y = me.realCellSize.x * absSize.x / absSize.y;
	}

	if(me.realFontSize.x > maxFontWidth || me.realFontSize.y > maxFontHeight)
		me.realFontSize = eX * maxFontWidth + eY * maxFontHeight;

	me.charOffset = eX * me.realCellSize.x / 2 + eY * ((me.realCellSize.y - me.realFontSize.y) / 2);
}

float XonoticCharmap_keyDown(entity me, float key, float ascii, float shift)
{
	if(SUPER(XonoticCharmap).keyDown(me, key, ascii, shift))
		return 1;
	return me.inputBox.keyDown(me.inputBox, key, ascii, shift);
}

void XonoticCharmap_cellSelect(entity me, vector cell)
{
	string character = charmap_cellToChar(me, cell);
	if(character != "")
	{
		me.inputBox.enterText(me.inputBox, character);
		if(me.inputBox.applyButton)
			me.inputBox.applyButton.disabled = false;
	}
}

bool XonoticCharmap_cellIsValid(entity me, vector cell)
{
	if(charmap_cellToChar(me, cell) == "")
		return false;
	return true;
}

void XonoticCharmap_cellDraw(entity me, vector cell, vector cellPos)
{
	draw_CenterText(cellPos + me.charOffset, charmap_cellToChar(me, cell), me.realFontSize, SKINCOLOR_CHARMAP_CHAR, SKINALPHA_CHARMAP_CHAR, 0);
}

void XonoticCharmap_focusLeave(entity me)
{
	me.inputBox.saveCvars(me.inputBox);
}
