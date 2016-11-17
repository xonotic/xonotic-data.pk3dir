#include "textbox.qh"

entity makeXonoticTextBox()
{
	entity me;
	me = NEW(XonoticTextBox);
	me.configureXonoticTextBox(me);
	return me;
}
void XonoticTextBox_configureXonoticTextBox(entity me)
{
	me.configureListBox(me, me.scrollbarWidth, 1); // item height gets set up later
}
void XonoticTextBox_setSelected(entity me, float i)
{
	// nothing
}
void XonoticTextBox_resizeNotify(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
{
	me.itemHeight = me.rowsPerItem * me.fontSize / absSize_y;
	SUPER(XonoticTextBox).resizeNotify(me, relOrigin, relSize, absOrigin, absSize);

	me.realFontSize_y = me.fontSize / (absSize_y * me.itemHeight);
	me.realFontSize_x = me.fontSize / (absSize_x * (1 - me.controlWidth));
	me.realUpperMargin = 0.5 * (1 - me.realFontSize_y);
}
void XonoticTextBox_setText(entity me, string theText)
{
	int i, k;
	string ts;
	if(me.textbuf >= 0)
		buf_del(me.textbuf);
	me.textbuf = buf_create();
	string s = strzone(theText);
	me.nItems = 0;
	k = tokenizebyseparator(s, "\\n");
	for(i = 0; i < k; ++i)
	{
		getWrappedLine_remaining = argv(i);
		if(!getWrappedLine_remaining)
		{
			bufstr_add(me.textbuf, "", 1);
			++me.nItems;
		}
		else while(getWrappedLine_remaining)
		{
			ts = getWrappedLine(1 - me.controlWidth, me.realFontSize, draw_TextWidth_WithColors);
			if (ts != "")
			{
				bufstr_add(me.textbuf, ts, 1);
				++me.nItems;
			}
		}
	}
	strunzone(s);
	me.textbufSize = buf_getsize(me.textbuf);
}
void XonoticTextBox_destroy(entity me)
{
	if(me.textbuf >= 0)
		buf_del(me.textbuf);
}
void XonoticTextBox_drawListBoxItem(entity me, int i, vector absSize, bool isSelected, bool isFocused)
{
	if(me.textbufSize > 0)
		draw_CenterText(me.realUpperMargin * eY + 0.5 * eX, bufstr_get(me.textbuf, i), me.realFontSize, '1 1 1', 1, me.allowColors);
}
