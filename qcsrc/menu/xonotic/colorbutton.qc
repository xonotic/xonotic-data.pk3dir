#include "colorbutton.qh"

entity makeXonoticColorButton(float theGroup, float theColor, float theValue)
{
	entity me;
	me = NEW(XonoticColorButton);
	me.configureXonoticColorButton(me, theGroup, theColor, theValue);
	return me;
}
void XonoticColorButton_configureXonoticColorButton(entity me, float theGroup, float theColor, float theValue)
{
	switch(theValue)
	{
		// rearrange 1..14 for rainbow order
		case  1: theValue = 10; break;
		case  2: theValue =  4; break;
		case  3: theValue =  1; break;
		case  4: theValue = 14; break;
		case  5: theValue = 12; break;
		case  6: theValue =  7; break;
		case  7: theValue =  3; break;
		case  8: theValue =  2; break;
		case  9: theValue =  6; break;
		case 10: theValue =  5; break;
		case 11: theValue = 13; break;
		case 12: theValue = 11; break;
		case 13: theValue =  8; break;
		case 14: theValue =  9; break;
		default:
			// no change
			break;
	}
	me.controlledCvar = "_cl_color";
	me.cvarValueFloat = theValue;
	me.cvarPart = theColor;
	me.loadCvars(me);
	me.configureRadioButton(me, string_null, me.fontSize, me.image, theGroup, 0);
}
void XonoticColorButton_setChecked(entity me, bool val)
{
	if(val != me.checked)
	{
		me.checked = val;
		me.saveCvars(me);
	}
}
void XonoticColorButton_loadCvars(entity me)
{
	if (!me.controlledCvar)
		return;

	if(cvar_string(me.controlledCvar) == cvar_defstring(me.controlledCvar))
		cvar_set(me.controlledCvar, ftos(16 * floor(random() * 15) + floor(random() * 15)));

	if(me.cvarPart == 1)
		me.checked = (cvar(me.controlledCvar) & 240) == me.cvarValueFloat * 16;
	else
		me.checked = (cvar(me.controlledCvar) & 15) == me.cvarValueFloat;
}
void XonoticColorButton_saveCvars(entity me)
{
	if (!me.controlledCvar)
		return;

	if(me.checked)
	{
		if(me.cvarPart == 1)
			cvar_set(me.controlledCvar, ftos((cvar(me.controlledCvar) & 15) + me.cvarValueFloat * 16));
		else
			cvar_set(me.controlledCvar, ftos((cvar(me.controlledCvar) & 240) + me.cvarValueFloat));
	}
}
void XonoticColorButton_draw(entity me)
{
	me.color  = colormapPaletteColor(me.cvarValueFloat, me.cvarPart);
	me.colorC = me.color;
	me.colorF = me.color;
	me.colorD = me.color;
	SUPER(XonoticColorButton).draw(me);
}
