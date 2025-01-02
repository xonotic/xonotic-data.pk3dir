#include "description.qh"

void XonoticGuideDescription_drawListBoxItem(entity me, int i, vector absSize, bool isSelected, bool isFocused)
{
	tokenizebyseparator(me.descriptionWrapped, "\n");
	draw_Text(me.realFontSize.x * eX + me.realUpperMargin * eY, argv(i), me.realFontSize, '1 1 1', 1, true);
}

void XonoticGuideDescription_setDescription(entity me, string desc)
{
	string current = me.description;
	if (current && current != desc)
		strunzone(current);
	me.description = strzone(desc);

	string currentWrapped = me.descriptionWrapped;
	if (currentWrapped)
		strunzone(currentWrapped);

	string wrapped = "";
	// horizontal padding is me.realFontSize.x on both sides
	float maxWidth = 1 - 2 * me.realFontSize.x;
	for (int i = 0, n = tokenizebyseparator(desc, "\n"); i < n; ++i)
	{
		string line = "";
		for (getWrappedLine_remaining = argv(i); getWrappedLine_remaining; )
		{
			string s = getWrappedLine(maxWidth, me.realFontSize, draw_TextWidth_WithColors);
			line = strcat(line, "\n", s);
		}
		wrapped = strcat(wrapped, line);
	}
	me.descriptionWrapped = strzone(wrapped);

	me.nItems = tokenizebyseparator(wrapped, "\n");
}

void XonoticGuideDescription_resizeNotify(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
{
	SUPER(XonoticGuideDescription).resizeNotify(me, relOrigin, relSize, absOrigin, absSize);

	me.realFontSize_y = me.fontSize / (absSize.y * me.itemHeight);
	me.realFontSize_x = me.fontSize / (absSize.x * (1 - me.controlWidth));
	me.realUpperMargin = 0.5 * (1 - me.realFontSize.y);
	me.setDescription(me, me.description);
}
