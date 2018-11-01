#include "dialog_hudpanel_chat.qh"

#include "textlabel.qh"
#include "checkbox.qh"
#include "slider.qh"

void XonoticHUDChatDialog_fill(entity me)
{
	entity e;
	string panelname = "chat";

	dialog_hudpanel_main_checkbox(me, panelname);

	dialog_hudpanel_main_settings(me, panelname);

	me.TR(me);
		me.TD(me, 1, 2, e = makeXonoticTextLabel(0, _("Chat entries:")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Chat size:")));
		me.TD(me, 1, 2.6, e = makeXonoticSlider(6, 20, 1, "con_chatsize"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Chat lifetime:")));
		me.TD(me, 1, 2.6, e = makeXonoticSlider(5, 60, 5, "con_chattime"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 3.8, e = makeXonoticCheckBox(0, "con_chatsound", _("Chat beep sound")));
}
