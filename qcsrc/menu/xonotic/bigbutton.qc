#ifndef BIGBUTTON_H
#define BIGBUTTON_H
#include "button.qc"
CLASS(XonoticBigButton, XonoticButton)
	METHOD(XonoticBigButton, configureXonoticBigButton, void(entity, string, vector));
	ATTRIB(XonoticBigButton, image, string, SKINGFX_BUTTON_BIG)
	ATTRIB(XonoticBigButton, grayImage, string, SKINGFX_BUTTON_BIG_GRAY)
ENDCLASS(XonoticBigButton)
entity makeXonoticBigButton(string theText, vector theColor);
#endif

#ifdef IMPLEMENTATION
entity makeXonoticBigButton(string theText, vector theColor)
{
	entity me;
	me = NEW(XonoticBigButton);
	me.configureXonoticBigButton(me, theText, theColor);
	return me;
}

void XonoticBigButton_configureXonoticBigButton(entity me, string theText, vector theColor)
{
	me.configureXonoticButton(me, theText, theColor, string_null);
}
#endif
