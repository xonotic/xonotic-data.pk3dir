#include "bigbutton.qh"

entity makeXonoticBigButton_T(string theText, vector theColor, string theTooltip)
{
	entity me = NEW(XonoticBigButton);
	me.configureXonoticButton(me, theText, theColor, theTooltip);
	return me;
}
entity makeXonoticBigButton(string theText, vector theColor)
{
	entity me = NEW(XonoticBigButton);
	me.configureXonoticButton(me, theText, theColor, string_null);
	return me;
}
