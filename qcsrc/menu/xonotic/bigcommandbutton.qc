#ifndef BIGCOMMANDBUTTON_H
#define BIGCOMMANDBUTTON_H
#include "commandbutton.qc"
CLASS(XonoticBigCommandButton, XonoticCommandButton)
	METHOD(XonoticBigCommandButton, configureXonoticBigCommandButton, void(entity, string, vector, string, float));
	ATTRIB(XonoticBigCommandButton, image, string, SKINGFX_BUTTON_BIG)
	ATTRIB(XonoticBigCommandButton, grayImage, string, SKINGFX_BUTTON_BIG_GRAY)
ENDCLASS(XonoticBigCommandButton)
entity makeXonoticBigCommandButton(string theText, vector theColor, string theCommand, float closesMenu);
#endif

#ifdef IMPLEMENTATION
entity makeXonoticBigCommandButton(string theText, vector theColor, string theCommand, float theFlags)
{
	entity me;
	me = NEW(XonoticBigCommandButton);
	me.configureXonoticBigCommandButton(me, theText, theColor, theCommand, theFlags);
	return me;
}

void XonoticBigCommandButton_configureXonoticBigCommandButton(entity me, string theText, vector theColor, string theCommand, float theFlags)
{
	me.configureXonoticCommandButton(me, theText, theColor, theCommand, theFlags);
}
#endif
