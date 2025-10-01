#include "dialog_hudpanel_chat.qh"

#include "textlabel.qh"
#include "checkbox.qh"
#include "slider.qh"
#include "mixedslider.qh"

void XonoticHUDChatDialog_fill(entity me)
{
	entity e;
	string panelname = "chat";

	dialog_hudpanel_main_checkbox(me, panelname);

	dialog_hudpanel_main_settings(me, panelname);

	me.TR(me);
		me.TD(me, 1, 1.4, e = makeXonoticTextLabel(0, _("Chat size:")));
		me.TD(me, 1, 2.6, e = makeXonoticSlider(6, 20, 1, "con_chatsize"));
	me.TR(me);
		me.TD(me, 1, 1.4, e = makeXonoticTextLabel(0, _("Chat lifetime:")));
		me.TD(me, 1, 2.6, e = makeXonoticMixedSlider("con_chattime"));
			e.formatString = "s";
			e.setValueSpace(e, e.valueSpace * 1.25);
			e.addRange(e, 5, 60, 5);
			e.addRange(e, 120, 300, 60);
			e.addText(e, ZCTX(_("LIFETIME^Infinite")), 0);
			e.configureXonoticMixedSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticCheckBox(0, "con_chatsound", _("Chat beep sound")));
}
