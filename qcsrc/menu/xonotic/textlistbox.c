#ifdef INTERFACE
CLASS(XonoticTextListBox) EXTENDS(ListBox)
	METHOD(XonoticTextListBox, configureXonoticTextListBox, void(entity))
	ATTRIB(XonoticTextListBox, fontSize, float, SKINFONTSIZE_NORMAL)
	ATTRIB(XonoticTextListBox, scrollbarWidth, float, SKINWIDTH_SCROLLBAR)
	ATTRIB(XonoticTextListBox, src, string, SKINGFX_SCROLLBAR)
	ATTRIB(XonoticTextListBox, tolerance, vector, SKINTOLERANCE_SLIDER)
	ATTRIB(XonoticTextListBox, rowsPerItem, float, 1)
	METHOD(XonoticTextListBox, resizeNotify, void(entity, vector, vector, vector, vector))
	ATTRIB(XonoticTextListBox, color, vector, SKINCOLOR_SCROLLBAR_N)
	ATTRIB(XonoticTextListBox, colorF, vector, SKINCOLOR_SCROLLBAR_F)
	ATTRIB(XonoticTextListBox, color2, vector, SKINCOLOR_SCROLLBAR_S)
	ATTRIB(XonoticTextListBox, colorC, vector, SKINCOLOR_SCROLLBAR_C)
	ATTRIB(XonoticTextListBox, colorBG, vector, SKINCOLOR_LISTBOX_BACKGROUND)
	ATTRIB(XonoticTextListBox, alphaBG, float, SKINALPHA_LISTBOX_BACKGROUND)

	METHOD(XonoticTextListBox, setSelected, void(entity, float))
	METHOD(XonoticTextListBox, destroy, void(entity))
	ATTRIB(XonoticTextListBox, textbuf, float, -1)
	ATTRIB(XonoticTextListBox, allowColors, float, 0)
	METHOD(XonoticTextListBox, setText, void(entity, string))
	METHOD(XonoticTextListBox, drawListBoxItem, void(entity, float, vector, float)) // item number, width/height, selected
ENDCLASS(XonoticTextListBox)
entity makeXonoticTextListBox();
#endif

#ifdef IMPLEMENTATION
entity makeXonoticTextListBox()
{
	entity me;
	me = spawnXonoticTextListBox();
	me.configureXonoticTextListBox(me);
	return me;
}
void XonoticTextListBox_configureXonoticTextListBox(entity me)
{
	me.configureListBox(me, me.scrollbarWidth, 1); // item height gets set up later
}
void XonoticTextListBox_setSelected(entity me, float i)
{
	// nothing
}
void XonoticTextListBox_resizeNotify(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
{
	me.itemHeight = me.rowsPerItem * me.fontSize / absSize_y;
	SUPER(XonoticTextListBox).resizeNotify(me, relOrigin, relSize, absOrigin, absSize);

	me.realFontSize_y = me.fontSize / (absSize_y * me.itemHeight);
	me.realFontSize_x = me.fontSize / (absSize_x * (1 - me.controlWidth));
	me.realUpperMargin = 0.5 * (1 - me.realFontSize_y);
}
void XonoticTextListBox_setText(entity me, string theText)
{
	float i, k;
	if(me.textbuf >= 0)
		buf_del(me.textbuf);
	me.textbuf = buf_create();
	string s = strzone(theText);
	k = tokenizebyseparator(s, "\\n");
	for(i = 0; i < k; ++i)
		bufstr_add(me.textbuf, argv(i), 1);
	strunzone(s);
	me.nItems = k;
}
void XonoticTextListBox_destroy(entity me)
{
	if(me.textbuf >= 0)
		buf_del(me.textbuf);
}
void XonoticTextListBox_drawListBoxItem(entity me, float i, vector absSize, float isSelected)
{
	draw_CenterText(me.realUpperMargin * eY + 0.5 * eX, bufstr_get(me.textbuf, i), me.realFontSize, '1 1 1', 1, me.allowColors);
}
#endif
