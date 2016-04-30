#include "bigcommandbutton.qh"

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
