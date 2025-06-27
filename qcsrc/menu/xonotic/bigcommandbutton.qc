#include "bigcommandbutton.qh"

entity makeXonoticBigCommandButton_T(string theText, vector theColor, string theCommand, int theFlags, string theTooltip)
{
	entity me;
	me = NEW(XonoticBigCommandButton);
	me.configureXonoticCommandButton(me, theText, theColor, theCommand, theFlags, theTooltip);
	return me;
}
entity makeXonoticBigCommandButton(string theText, vector theColor, string theCommand, int theFlags)
{
	return makeXonoticBigCommandButton_T(theText, theColor, theCommand, theFlags, string_null);
}
