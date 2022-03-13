#include "textbox.qh"
#include "../item/label.qh"

entity makeXonoticTextBox()
{
	entity me;
	me = NEW(XonoticTextBox);
	me.configureXonoticListBox(me);
	return me;
}

void XonoticTextBox_destroy(entity me)
{
	if (me.stringList >= 0)
	{
		buf_del(me.stringList);
		me.stringList = -1;
	}
}

void XonoticTextBox_setText(entity me, string text)
{
	if (me.stringList >= 0)
	{
		buf_del(me.stringList);
		me.stringList = -1;
	}

	int buf;
	int line = 0;

	string t;

	buf = buf_create();
	string separator = (me.escapedNewLines) ? "\\n" : "\n";
	for (int i = 0, n = tokenizebyseparator(text, separator); i < n; ++i)
	{
		t = substring(argv(i), 0, -1);
		getWrappedLine_remaining = t;
		while (getWrappedLine_remaining)
		{
			t = getWrappedLine(1, me.realFontSize, (me.allowColors) ? draw_TextWidth_WithColors : draw_TextWidth_WithoutColors);
			bufstr_set(buf, line, t);
			line++;
		}
	}

	me.stringList = buf;
	me.nItems = line+1;
}

string XonoticTextBox_getTextBoxLine(entity me, int i)
{
	if (me.stringList >= 0)
	{
		return bufstr_get(me.stringList, i);
	}
	return string_null;
}

// mostly copied from playerlist
// FIXME: is this really needed
void XonoticTextBox_resizeNotify(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
{
	me.itemAbsSize = '0 0 0';
	SUPER(XonoticTextBox).resizeNotify(me, relOrigin, relSize, absOrigin, absSize);

	me.itemAbsSize.y = absSize.y * me.itemHeight;
	me.itemAbsSize.x = absSize.x * (1 - me.controlWidth);
	me.realFontSize.y = me.fontSize / me.itemAbsSize.y;
	me.realFontSize.x = me.fontSize / me.itemAbsSize.x;
	string temp = string_null;
	for (int i = 0; i < me.nItems; ++i)
	{
		if (!temp)
		{
			temp = me.getTextBoxLine(me, i);
		}
		else
		{
			temp = strcat(temp, "\n", me.getTextBoxLine(me, i));
		}
	}
	me.setText(me, temp);
}

void XonoticTextBox_drawListBoxItem(entity me, int i, vector absSize, bool isSelected, bool isFocused)
{
	string s = me.getTextBoxLine(me, i);
	vector color = (me.allowColors) ? '1 1 1' : me.colorL;
	if (me.align == 0.5)
		draw_CenterText(0.5 * eX, s, me.realFontSize, color, 1, me.allowColors);
	else
		draw_Text(vec2(0, 0), s, me.realFontSize, color, me.alpha, me.allowColors);
}
