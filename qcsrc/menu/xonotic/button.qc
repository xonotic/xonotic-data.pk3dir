#include "button.qh"

entity makeXonoticButton_T(string theText, vector theColor, string theTooltip)
{
	entity me;
	me = NEW(XonoticButton);
	me.configureXonoticButton(me, theText, theColor, theTooltip);
	return me;
}
entity makeXonoticButton(string theText, vector theColor)
{
	return makeXonoticButton_T(theText, theColor, string_null);
}

void XonoticButton_configureXonoticButton(entity me, string theText, vector theColor, string theTooltip)
{
	if(theColor == '0 0 0')
	{
		me.configureButton(me, theText, me.fontSize, me.image);
	}
	else
	{
		me.configureButton(me, theText, me.fontSize, me.grayImage);
		me.color = theColor;
		me.colorC = theColor;
		me.colorF = theColor;
	}
	setZonedTooltip(me, theTooltip, string_null);
}
