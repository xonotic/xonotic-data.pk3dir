#ifndef BIGCOMMANDBUTTON_H
#define BIGCOMMANDBUTTON_H
#include "commandbutton.qc"
CLASS(XonoticBigCommandButton, XonoticCommandButton)
	METHOD(XonoticBigCommandButton, configureXonoticBigCommandButton, void(entity, string, vector, string, float, string));
	ATTRIB(XonoticBigCommandButton, image, string, SKINGFX_BUTTON_BIG)
	ATTRIB(XonoticBigCommandButton, grayImage, string, SKINGFX_BUTTON_BIG_GRAY)
ENDCLASS(XonoticBigCommandButton)
entity makeXonoticBigCommandButton_T(string theText, vector theColor, string theCommand, float closesMenu, string theTooltip);
entity makeXonoticBigCommandButton(string theText, vector theColor, string theCommand, float closesMenu);
#endif

#ifdef IMPLEMENTATION
entity makeXonoticBigCommandButton_T(string theText, vector theColor, string theCommand, float theFlags, string theTooltip)
{
	entity me;
	me = NEW(XonoticBigCommandButton);
	me.configureXonoticBigCommandButton(me, theText, theColor, theCommand, theFlags, theTooltip);
	return me;
}
entity makeXonoticBigCommandButton(string theText, vector theColor, string theCommand, float theFlags)
{
	return makeXonoticBigCommandButton_T(theText, theColor, theCommand, theFlags, string_null);
}

void XonoticBigCommandButton_configureXonoticBigCommandButton(entity me, string theText, vector theColor, string theCommand, float theFlags, string theTooltip)
{
	me.configureXonoticCommandButton(me, theText, theColor, theCommand, theFlags, theTooltip);
}
#endif
