#include "dialog.qh"

#include <menu/xonotic/inputbox.qh>
#include <menu/xonotic/listbox.qh>

#include "state.qh"

CLASS(XonoticChatList, XonoticListBox)
    ATTRIB(XonoticChatList, rowsPerItem, int, 1);
    ATTRIB(XonoticChatList, realFontSize, vector);
    ATTRIB(XonoticChatList, autoscroll, int);
    ATTRIB(XonoticChatList, inputbox, XonoticInputBox);

    METHOD(XonoticChatList, showNotify, void(XonoticChatList this));
    METHOD(XonoticChatList, resizeNotify, void(XonoticChatList this, vector, vector, vector, vector));
    METHOD(XonoticChatList, draw, void(XonoticChatList this));
    METHOD(XonoticChatList, drawListBoxItem, void(XonoticChatList this, int, vector, bool, bool));
ENDCLASS(XonoticChatList)

void XonoticChatDialog_onEnter(XonoticInputBox this, XonoticChatDialog data)
{
    entity e = this;
    localcmd("\n", chat_command, e.text, "\n");
    e.setText(e, chat_text);
    e.cursorPos = strlen(chat_text);
}

METHOD(XonoticChatDialog, fill, void(XonoticChatDialog this))
{
    entity list = NEW(XonoticChatList);;
    list.configureXonoticListBox(list);
    this.TR(this);
    {
        this.TD(this, this.rows - 1, this.columns, list);
    }
    this.gotoRC(this, this.rows - 1, 0);
    {
        entity e = list.inputbox = NEW(XonoticInputBox);
        e.configureXonoticInputBox(e, true, string_null, "");
        e.onEnter = XonoticChatDialog_onEnter;
        e.onEnterEntity = this;
        e.preferredFocusPriority = true;
        this.TD(this, 1, this.columns, e);
    }
}

METHOD(XonoticChatList, showNotify, void(XonoticChatList this))
{
    this.autoscroll = 1;
    entity e = this.inputbox;
    e.setText(e, chat_text);
    e.cursorPos = strlen(chat_text);
}

METHOD(XonoticChatList, resizeNotify, void(XonoticChatList this, vector relOrigin, vector relSize, vector absOrigin, vector absSize))
{
    SUPER(XonoticChatList).resizeNotify(this, relOrigin, relSize, absOrigin, absSize);

    this.realFontSize_y = this.fontSize / (absSize.y * this.itemHeight);
    this.realFontSize_x = this.fontSize / (absSize.x * (1 - this.controlWidth));
}

METHOD(XonoticChatList, draw, void(XonoticChatList this))
{
    int prevCount = this.nItems;
    this.nItems = chat_lines_count();
    if (this.autoscroll && prevCount != this.nItems) {
        this.scrollToItem(this, this.nItems - 1);
        if (this.autoscroll == 1) {
            this.autoscroll = 0;
        }
    }
    SUPER(XonoticChatList).draw(this);
}

METHOD(XonoticChatList, drawListBoxItem, void(XonoticChatList this, int i, vector absSize, bool isSelected, bool isFocused))
{
    string s = chat_lines_get(i);
    draw_Text(vec2(0, 0), s, this.realFontSize, '1 1 1', 1, true);
}
