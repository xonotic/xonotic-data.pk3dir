#ifndef DIALOG_SOCIAL_H
#define DIALOG_SOCIAL_H

#include "../../common/mutators/mutator/social.qh"
#include "datasource.qc"
CLASS(FriendSource, DataSource)
    METHOD(FriendSource, getEntry, entity(int i, void(string name, string icon) returns))
    {
        int idx = 0;
        string name = string_null;
        FOREACH_DB(Social_db, idx++ == i, LAMBDA(
            name = v;
            break;
        ));
        if (returns) returns(name, string_null);
        return DataSource_true;
    }
    METHOD(FriendSource, reload, int(string filter)) {
        int n = 0;
        FOREACH_DB(Social_db, true, LAMBDA(++n));
        return n;
    }
ENDCLASS(FriendSource)

entity Social_inst;

#include "listbox.qc"
CLASS(XonoticFriendsList, XonoticListBox)
    ATTRIB(XonoticFriendsList, alphaBG, float, 0)
    ATTRIB(XonoticFriendsList, itemAbsSize, vector, '0 0 0')
    ATTRIB(XonoticFriendsList, origin, vector, '0 0 0')
    ATTRIB(XonoticFriendsList, realFontSize, vector, '0 0 0')
    ATTRIB(XonoticFriendsList, realUpperMargin, float, 0)
    ATTRIB(XonoticFriendsList, rowsPerItem, float, 2)
    ATTRIB(XonoticFriendsList, stringFilterBox, entity, NULL)
    ATTRIB(XonoticFriendsList, stringFilter, string, string_null)
    ATTRIB(XonoticFriendsList, typeToSearchString, string, string_null)
    ATTRIB(XonoticFriendsList, typeToSearchTime, float, 0)
    ATTRIB(XonoticFriendsList, source, DataSource, NULL)
    ATTRIB(XonoticFriendsList, onChange, void(entity, entity), func_null)
    ATTRIB(XonoticFriendsList, onChangeEntity, entity, NULL)
    string XonoticFriendsList_cb_name;
    void XonoticFriendsList_cb(string _name, string _icon)
    {
        XonoticFriendsList_cb_name = _name;
    }
    METHOD(XonoticFriendsList, drawListBoxItem, void(entity this, int i, vector absSize, bool isSelected, bool isFocused))
    {
        if (!this.source) return;
        if (!this.source.getEntry(i, XonoticFriendsList_cb)) return;
        string name = XonoticFriendsList_cb_name;
        if (isSelected) {
            draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED);
        } else if (isFocused) {
            this.focusedItemAlpha = getFadedAlpha(this.focusedItemAlpha, SKINALPHA_LISTBOX_FOCUSED, SKINFADEALPHA_LISTBOX_FOCUSED);
            draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_FOCUSED, this.focusedItemAlpha);
        }
        string s = draw_TextShortenToWidth(strdecolorize(name), 1, 0, this.realFontSize);
        draw_Text(this.realUpperMargin * eY + (0.5 * this.realFontSize.x) * eX, s, this.realFontSize, '1 1 1', SKINALPHA_TEXT, 0);
    }
    METHOD(XonoticFriendsList, refilter, void(entity this))
    {
        if (!this.source) {
            this.nItems = 0;
            return;
        }
        this.nItems = this.source.reload(this.stringFilter);
    }
    METHOD(XonoticFriendsList, resizeNotify, void(entity this, vector relOrigin, vector relSize, vector absOrigin, vector absSize))
    {
        super.resizeNotify(this, relOrigin, relSize, absOrigin, absSize);

        this.itemAbsSize = '0 0 0';
        this.realFontSize_y = this.fontSize / (this.itemAbsSize_y = (absSize.y * this.itemHeight));
        this.realFontSize_x = this.fontSize / (this.itemAbsSize_x = (absSize.x * (1 - this.controlWidth)));
        this.realUpperMargin = 0.5 * (1 - this.realFontSize.y);
    }
    INIT(XonoticFriendsList) {
    	Social_inst = this;
    }
    CONSTRUCTOR(XonoticFriendsList, DataSource _source) {
        CONSTRUCT(XonoticFriendsList);
        this.source = _source;
        this.configureXonoticListBox(this);
        this.refilter(this);
    }
ENDCLASS(XonoticFriendsList)

#include "dialog.qc"
CLASS(XonoticSocialDialog, XonoticDialog)
    METHOD(XonoticSocialDialog, fill, void(entity));
    ATTRIB(XonoticSocialDialog, title, string, _("Social"))
    ATTRIB(XonoticSocialDialog, color, vector, SKINCOLOR_DIALOG_SOCIAL)
    ATTRIB(XonoticSocialDialog, intendedWidth, float, 0.5)
    ATTRIB(XonoticSocialDialog, rows, float, 20)
    ATTRIB(XonoticSocialDialog, columns, float, 2)
    ATTRIB(XonoticSocialDialog, friendsList, XonoticFriendsList, NEW(XonoticFriendsList, NEW(FriendSource)))
ENDCLASS(XonoticSocialDialog)

#endif

#ifdef IMPLEMENTATION

REGISTER_MUTATOR(social_refreshmenu, true);
MUTATOR_HOOKFUNCTION(social_refreshmenu, Social_Add) {
    Social_inst.refilter(Social_inst);
}

METHOD(XonoticSocialDialog, fill, void(entity this))
{
    int
    col = 0, width = 2;
    this.gotoRC(this, 0, col);
        this.TD(this, this.rows, width, this.friendsList);
}
#endif
