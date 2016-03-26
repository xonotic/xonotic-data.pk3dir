#include "listbox.qh"

entity makeXonoticListBox()
{
	entity me;
	me = NEW(XonoticListBox);
	me.configureXonoticListBox(me);
	return me;
}
void XonoticListBox_configureXonoticListBox(entity me)
{
	me.configureListBox(me, me.scrollbarWidth, 1); // item height gets set up later
}
void XonoticListBox_resizeNotify(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
{
	me.itemHeight = me.rowsPerItem * me.fontSize / absSize.y;
	SUPER(XonoticListBox).resizeNotify(me, relOrigin, relSize, absOrigin, absSize);
}
