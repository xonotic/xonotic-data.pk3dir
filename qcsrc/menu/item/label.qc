#include "label.qh"

	string Label_toString(entity me)
	{
		return me.text;
	}
	void Label_setText(entity me, string txt)
	{
		me.text = txt;
		if (txt != me.currentText)
		{
			strcpy(me.currentText, txt);
			me.recalcPos = true;
		}
	}
	void Label_recalcPositionWithText(entity me, string t)
	{
		float spaceAvail;
		spaceAvail = 1 - me.keepspaceLeft - me.keepspaceRight;

		if (me.isBold) draw_beginBoldFont();

		float spaceUsed;
		spaceUsed = draw_TextWidth(t, me.allowColors, me.realFontSize);

		if (spaceUsed <= spaceAvail)
		{
			if (!me.overrideRealOrigin_x) me.realOrigin_x = me.align * (spaceAvail - spaceUsed) + me.keepspaceLeft;
			if (!me.overrideCondenseFactor) me.condenseFactor = 1;
		}
		else if (me.allowCut || me.allowWrap)
		{
			if (!me.overrideRealOrigin_x) me.realOrigin_x = me.keepspaceLeft;
			if (!me.overrideCondenseFactor) me.condenseFactor = 1;
		}
		else
		{
			if (!me.overrideRealOrigin_x) me.realOrigin_x = me.keepspaceLeft;
			if (!me.overrideCondenseFactor) me.condenseFactor = spaceAvail / spaceUsed;
			LOG_TRACEF("NOTE: label text %s too wide for label, condensed by factor %f", t, me.condenseFactor);
		}

		if (!me.overrideRealOrigin_y)
		{
			float lines;
			vector dfs;
			vector fs;

			// set up variables to draw in condensed size, but use hinting for original size
			fs = me.realFontSize;
			fs.x *= me.condenseFactor;

			dfs = draw_fontscale;
			draw_fontscale.x *= me.condenseFactor;

			if (me.allowCut)  // FIXME allowCut incompatible with align != 0
			{
				lines = 1;
			}
			else if (me.allowWrap)  // FIXME allowWrap incompatible with align != 0
			{
				getWrappedLine_remaining = me.text;
				lines = 0;
				while (getWrappedLine_remaining)
				{
					if (me.allowColors) getWrappedLine((1 - me.keepspaceLeft - me.keepspaceRight), fs, draw_TextWidth_WithColors);
					else getWrappedLine((1 - me.keepspaceLeft - me.keepspaceRight), fs, draw_TextWidth_WithoutColors);
					++lines;
				}
			}
			else
			{
				lines = 1;
			}

			draw_fontscale = dfs;

			float text_height = lines * me.realFontSize.y;
			if (lines > 1)
				text_height += (lines - 1) * me.realFontSize.y * me.allowWrap_spacing;
			me.realOrigin_y = 0.5 * (1 - text_height);
		}

		if (me.isBold) draw_endBoldFont();

		me.recalcPos = false;
	}
	void Label_resizeNotify(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
	{
		SUPER(Label).resizeNotify(me, relOrigin, relSize, absOrigin, absSize);

		// absSize_y is height of label
		me.realFontSize_y = absSize.y == 0 ? 0 : (me.fontSize / absSize.y);
		me.realFontSize_x = absSize.x == 0 ? 0 : (me.fontSize / absSize.x);
		if (me.marginLeft) me.keepspaceLeft = me.marginLeft * me.realFontSize.x;
		if (me.marginRight) me.keepspaceRight = me.marginRight * me.realFontSize.x;

		me.recalcPos = true;
	}
	void Label_configureLabel(entity me, string txt, float sz, float algn)
	{
		me.fontSize = sz;
		me.align = algn;
		me.setText(me, txt);
	}
	void Label_draw(entity me)
	{
		string t;
		vector o;
		if (me.disabled) draw_alpha *= me.disabledAlpha;

		if (me.textEntity)
		{
			t = me.textEntity.toString(me.textEntity);
			if (t != me.currentText)
			{
				strcpy(me.currentText, t);
				me.recalcPos = true;
			}
		}
		else
		{
			t = me.text;
		}

		if (me.recalcPos) me.recalcPositionWithText(me, t);

		if (me.fontSize)
			if (t)
			{
				vector dfs;
				vector fs;

				if (me.isBold) draw_beginBoldFont();

				// set up variables to draw in condensed size, but use hinting for original size
				fs = me.realFontSize;
				fs.x *= me.condenseFactor;

				dfs = draw_fontscale;
				draw_fontscale.x *= me.condenseFactor;

				if (me.allowCut)  // FIXME allowCut incompatible with align != 0
				{
					draw_Text(me.realOrigin, draw_TextShortenToWidth(t, (1 - me.keepspaceLeft - me.keepspaceRight), me.allowColors, fs), fs, me.colorL, me.alpha, me.allowColors);
				}
				else if (me.allowWrap)  // FIXME allowWrap incompatible with align != 0
				{
					getWrappedLine_remaining = t;
					o = me.realOrigin;
					while (getWrappedLine_remaining)
					{
						if (me.allowColors) t = getWrappedLine((1 - me.keepspaceLeft - me.keepspaceRight), fs, draw_TextWidth_WithColors);
						else t = getWrappedLine((1 - me.keepspaceLeft - me.keepspaceRight), fs, draw_TextWidth_WithoutColors);
						draw_Text(o, t, fs, me.colorL, me.alpha, me.allowColors);
						o.y += me.realFontSize.y * (1 + me.allowWrap_spacing);
					}
				}
				else
				{
					draw_Text(me.realOrigin, t, fs, me.colorL, me.alpha, me.allowColors);
				}

				draw_fontscale = dfs;

				if (me.isBold) draw_endBoldFont();
			}

		SUPER(Label).draw(me);
	}
