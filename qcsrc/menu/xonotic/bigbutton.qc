#include "bigbutton.qh"

entity makeXonoticBigButton(string theText, vector theColor)
{
	entity me;
	me = NEW(XonoticBigButton);
	me.configureXonoticButton(me, theText, theColor, string_null);
	return me;
}
