#include "description.qh"

void XonoticGuideDescription_drawListBoxItem(entity this, int i, vector absSize, bool isSelected, bool isFocused)
{
	tokenizebyseparator(this.descriptionWrapped, "\n");
	draw_Text(this.realFontSize.x * eX + this.realUpperMargin * eY, argv(i), this.realFontSize, '1 1 1', 1, true);
}

void XonoticGuideDescription_setDescription(entity this, string desc)
{
	string current = this.description;
	if (current && current != desc)
		strunzone(current);
	this.description = strzone(desc);

	string currentWrapped = this.descriptionWrapped;
	if (currentWrapped)
		strunzone(currentWrapped);

	string wrapped = "";
	// horizontal padding is this.realFontSize.x on both sides
	float maxWidth = 1 - 2 * this.realFontSize.x;
	for (int i = 0, n = tokenizebyseparator(desc, "\n"); i < n; ++i)
	{
		string line = "";
		for (getWrappedLine_remaining = argv(i); getWrappedLine_remaining; )
		{
			string s = getWrappedLine(maxWidth, this.realFontSize, draw_TextWidth_WithColors);
			line = strcat(line, "\n", s);
		}
		wrapped = strcat(wrapped, line);
	}
	this.descriptionWrapped = strzone(wrapped);

	this.nItems = tokenizebyseparator(wrapped, "\n");
}

void XonoticGuideDescription_resizeNotify(entity this, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
{
	SUPER(XonoticGuideDescription).resizeNotify(this, relOrigin, relSize, absOrigin, absSize);

	this.realFontSize_y = this.fontSize / (absSize.y * this.itemHeight);
	this.realFontSize_x = this.fontSize / (absSize.x * (1 - this.controlWidth));
	this.realUpperMargin = 0.5 * (1 - this.realFontSize.y);
	this.setDescription(this, this.description);
}
