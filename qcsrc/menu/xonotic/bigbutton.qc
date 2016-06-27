#include "bigbutton.qh"

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
