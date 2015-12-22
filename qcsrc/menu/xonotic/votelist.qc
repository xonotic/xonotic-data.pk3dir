#ifndef VOTELIST_H
#define VOTELIST_H

#include "listbox.qc"
CLASS(XonoticVoteList, XonoticListBox)
	METHOD(XonoticVoteList, resizeNotify, void(XonoticVoteList this, vector relOrigin, vector relSize, vector absOrigin, vector absSize))
	{
		SUPER(XonoticVoteList).resizeNotify(this, relOrigin, relSize, absOrigin, absSize);
		this.realFontSize_y = this.fontSize / (absSize.y * this.itemHeight);
		this.realFontSize_x = this.fontSize / (absSize.x * (1 - this.controlWidth));
	}

	ATTRIB(XonoticVoteList, source, DataSource, NULL)

	METHOD(XonoticVoteList, refilter, void(XonoticVoteList this));
	METHOD(XonoticVoteList, setSelected, void(XonoticVoteList this, int i));
	METHOD(XonoticVoteList, drawListBoxItem, void(XonoticVoteList this, int i, vector absSize, bool isSelected, bool isFocused));

	CONSTRUCTOR(XonoticVoteList, DataSource _source)
	{
		CONSTRUCT(XonoticVoteList);
		this.source = _source;
		this.refilter(this);
	}

ENDCLASS(XonoticVoteList)

string XonoticVoteList_cb_name;
void XonoticVoteList_cb(string _name, string _icon) { XonoticVoteList_cb_name = _name; }

#endif

#ifdef IMPLEMENTATION

METHOD(XonoticVoteList, refilter, void(XonoticVoteList this))
{
	if (!this.source)
	{
		this.nItems = 0;
		return;
	}
	this.nItems = this.source.reload(this.source, "");
}

METHOD(XonoticVoteList, setSelected, void(XonoticVoteList this, int i))
{
	SUPER(XonoticVoteList).setSelected(this, i);
	if (!this.source.getEntry(this.source, i, XonoticVoteList_cb)) return;
	if (this.onChange) this.onChange(this, this.onChangeEntity);
}

METHOD(XonoticVoteList, drawListBoxItem, void(XonoticVoteList this, int i, vector absSize, bool isSelected, bool isFocused))
{
	if (!this.source.getEntry(this.source, i, XonoticVoteList_cb)) return;
	if (isSelected) draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED);
	string s = XonoticVoteList_cb_name;
	draw_Text(this.realUpperMargin * eY + this.columnNameOrigin * eX, s, this.realFontSize, '1 1 1', SKINALPHA_TEXT, 0);
}

#endif
