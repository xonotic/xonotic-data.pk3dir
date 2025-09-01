#include "textlabel.qh"

entity makeXonoticTextLabel(float theAlign, string theText)
{
	entity me;
	me = NEW(XonoticTextLabel);
	me.configureLabel(me, theText, me.fontSize, theAlign);
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

void XonoticTextLabel_draw(entity me)
{
	SUPER(XonoticTextLabel).draw(me);
}
