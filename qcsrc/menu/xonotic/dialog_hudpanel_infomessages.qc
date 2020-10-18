#include "dialog_hudpanel_infomessages.qh"

#include "textlabel.qh"
#include "checkbox.qh"

void XonoticHUDInfoMessagesDialog_fill(entity me)
{
	entity e;
	string panelname = "infomessages";

	dialog_hudpanel_main_checkbox(me, panelname);

	dialog_hudpanel_main_settings(me, panelname);

	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticTextLabel(0, _("Info messages:")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 3.8, e = makeXonoticCheckBox(0, "hud_panel_infomessages_flip", _("Flip align")));
}
