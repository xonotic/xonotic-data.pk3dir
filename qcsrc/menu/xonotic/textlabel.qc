#include "textlabel.qh"

entity makeXonoticTextLabel(float theAlign, string theText)
{
	entity me;
	me = NEW(XonoticTextLabel);
	me.configureXonoticTextLabel(me, theAlign, theText);
	return me;
}
entity makeXonoticHeaderLabel(string theText)
{
	entity me;
	me = makeXonoticTextLabel(0.5, theText);
	me.colorL = SKINCOLOR_HEADER;
	me.alpha = SKINALPHA_HEADER;
	me.isBold = true;
	return me;
}
void XonoticTextLabel_configureXonoticTextLabel(entity me, float theAlign, string theText)
{
	me.configureLabel(me, theText, me.fontSize, theAlign);
}
void XonoticTextLabel_draw(entity me)
{
	SUPER(XonoticTextLabel).draw(me);
}
