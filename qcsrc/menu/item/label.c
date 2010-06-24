#ifdef INTERFACE
CLASS(Label) EXTENDS(Item)
	METHOD(Label, configureLabel, void(entity, string, float, float))
	METHOD(Label, draw, void(entity))
	METHOD(Label, resizeNotify, void(entity, vector, vector, vector, vector))
	METHOD(Label, setText, void(entity, string))
	METHOD(Label, toString, string(entity))
	ATTRIB(Label, text, string, string_null)
	ATTRIB(Label, fontSize, float, 8)
	ATTRIB(Label, align, float, 0.5)
	ATTRIB(Label, allowCut, float, 0)
	ATTRIB(Label, allowColors, float, 0)
	ATTRIB(Label, keepspaceLeft, float, 0) // for use by subclasses (radiobuttons for example)
	ATTRIB(Label, keepspaceRight, float, 0)
	ATTRIB(Label, marginLeft, float, 0) // alternate way to specify keepspace* (in characters from the font)
	ATTRIB(Label, marginRight, float, 0)
	ATTRIB(Label, realFontSize, vector, '0 0 0')
	ATTRIB(Label, realOrigin, vector, '0 0 0')
	ATTRIB(Label, alpha, float, 0.7)
	ATTRIB(Label, colorL, vector, '1 1 1')
	ATTRIB(Label, disabled, float, 0)
	ATTRIB(Label, disabledAlpha, float, 0.3)
	ATTRIB(Label, textEntity, entity, NULL)
	ATTRIB(Label, allowWrap, float, 0)
	ATTRIB(Label, recalcPos, float, 0)
ENDCLASS(Label)
#endif

#ifdef IMPLEMENTATION
string Label_toString(entity me)
{
	return me.text;
}
void Label_setText(entity me, string txt)
{
	me.text = txt;
	me.recalcPos = 1;
}
void Label_resizeNotify(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
{
	SUPER(Label).resizeNotify(me, relOrigin, relSize, absOrigin, absSize);
	// absSize_y is height of label
	me.realFontSize_y = me.fontSize / absSize_y;
	me.realFontSize_x = me.fontSize / absSize_x;
	if(me.marginLeft)
		me.keepspaceLeft = me.marginLeft * me.realFontSize_x;
	if(me.marginRight)
		me.keepspaceRight = me.marginRight * me.realFontSize_x;
	me.realOrigin_y = 0.5 * (1 - me.realFontSize_y);
	me.realOrigin_x = me.align * (1 - me.keepspaceLeft - me.keepspaceRight - min(draw_TextWidth(me.text, me.allowColors, me.realFontSize), (1 - me.keepspaceLeft - me.keepspaceRight))) + me.keepspaceLeft;
	me.recalcPos = 0;
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
	if(me.disabled)
		draw_alpha *= me.disabledAlpha;

	if(me.textEntity)
	{
		t = me.textEntity.toString(me.textEntity);
		me.recalcPos = 1;
	}
	else
		t = me.text;

	if(me.recalcPos)
		me.realOrigin_x = me.align * (1 - me.keepspaceLeft - me.keepspaceRight - min(draw_TextWidth(t, me.allowColors, me.realFontSize), (1 - me.keepspaceLeft - me.keepspaceRight))) + me.keepspaceLeft;
	me.recalcPos = 0;

	//if(me.text == "Bookmark")
	//	draw_Fill(me.realOrigin, '0 1 0' + '1 0 0' * draw_TextWidth(t, me.allowColors, me.realFontSize), '1 0 1', 1);
	
	if(me.fontSize)
		if(t)
		{
			if(me.allowCut) // FIXME allowCut incompatible with align != 0
				draw_Text(me.realOrigin, draw_TextShortenToWidth(t, (1 - me.keepspaceLeft - me.keepspaceRight), me.allowColors, me.realFontSize), me.realFontSize, me.colorL, me.alpha, me.allowColors);
			else if(me.allowWrap) // FIXME allowWrap incompatible with align != 0
			{
				getWrappedLine_remaining = t;
				o = me.realOrigin;
				while(getWrappedLine_remaining)
				{
					if (me.allowColors)
						t = getWrappedLine((1 - me.keepspaceLeft - me.keepspaceRight), me.realFontSize, draw_TextWidth_WithColors);
					else
						t = getWrappedLine((1 - me.keepspaceLeft - me.keepspaceRight), me.realFontSize, draw_TextWidth_WithoutColors);
					draw_Text(o, t, me.realFontSize, me.colorL, me.alpha, me.allowColors);
					o_y += me.realFontSize_y;
				}
			}
			else
				draw_Text(me.realOrigin, t, me.realFontSize, me.colorL, me.alpha, me.allowColors);
		}
}
#endif
