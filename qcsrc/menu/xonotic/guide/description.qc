#include "description.qh"

void XonoticGuideDescription_drawListBoxItem(entity me, int i, vector absSize, bool isSelected, bool isFocused)
{
	tokenizebyseparator(me.m_descriptionWrapped, "\n");
	draw_Text(me.keepspaceLeft * eX, argv(i), me.realFontSize, '1 1 1', 1, true);
}

/// wraps text and creates dot point lists from lines starting with "* "
string wrapGuideText(string desc, float maxWidth, vector theFontSize)
{
	string wrapped = "";
	bool keep_indenting = false;
	const int n = tokenizebyseparator(desc, "\n");
	for (int i = 0; i < n; ++i)
	{
		string s, line = "";
		getWrappedLine_remaining = argv(i);
		bool dotpoint = false, indent = false;
		if (substring(getWrappedLine_remaining, 0, 2) == "* ")
		{
			dotpoint = true;
			// We use Middle Dot (U+00B7) because it has the same width as space
			// and makes the alignment with wrapped lines perfect.
			getWrappedLine_remaining = strcat("  \xC2\xB7 ", substring(getWrappedLine_remaining, 2, -1));
		}
		else if (keep_indenting)
		{
			dotpoint = true;
			indent = true;
		}
		while (getWrappedLine_remaining)
		{
			if (indent) // indent lines inside dot point lists
				getWrappedLine_remaining = strcat("    ", getWrappedLine_remaining);
			s = getWrappedLine(maxWidth, theFontSize, draw_TextWidth_WithColors);
			indent = dotpoint;
			line = strcat(line, "\n", s);
		}
		wrapped = strcat(wrapped, line);

		// if the current line is indented, the following non-empty lines must be indented too
		keep_indenting = (indent && i + 1 < n && argv(i+1) != "");
	}
	return strcat(wrapped, "\n\n");
}

void XonoticGuideDescription_setDescription(entity me, string desc)
{
	if (me.m_description && me.m_description != desc)
		strunzone(me.m_description);
	me.m_description = strzone(desc);

	strfree(me.m_descriptionWrapped);

	const float maxWidth = 1 - me.keepspaceLeft - me.keepspaceRight;
	me.m_descriptionWrapped = strzone(wrapGuideText(me.m_description, maxWidth, me.realFontSize));

	me.nItems = tokenizebyseparator(me.m_descriptionWrapped, "\n");
	me.setSelected(me, 0); // reset scrollbar position
}

void XonoticGuideDescription_resizeNotify(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
{
	SUPER(XonoticGuideDescription).resizeNotify(me, relOrigin, relSize, absOrigin, absSize);

	me.itemAbsSize.y = absSize.y * me.itemHeight;
	me.itemAbsSize.x = absSize.x * (1 - me.controlWidth);
	me.realFontSize.y = me.fontSize / me.itemAbsSize.y;
	me.realFontSize.x = me.fontSize / me.itemAbsSize.x;
	me.keepspaceLeft = me.keepspaceRight = me.realFontSize.x;
	me.setDescription(me, me.m_description);
}
