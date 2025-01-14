#include "dialog_hudpanel_score.qh"

#include "checkbox.qh"
#include "textlabel.qh"
#include "radiobutton.qh"

void XonoticHUDScoreDialog_fill(entity me)
{
	entity e;
	string panelname = "score";

	dialog_hudpanel_main_checkbox(me, panelname);

	dialog_hudpanel_main_settings(me, panelname);

	me.TR(me);
		me.TD(me, 1, 1.4, e = makeXonoticTextLabel(0, _("Rankings:")));
		me.TD(me, 1, 2.6/3, e = makeXonoticRadioButton(1, "hud_panel_score_rankings", "0", _("Off")));
		me.TD(me, 1, 2.6/3, e = makeXonoticRadioButton(1, "hud_panel_score_rankings", "1", _("And me")));
		me.TD(me, 1, 2.6/3, e = makeXonoticRadioButton(1, "hud_panel_score_rankings", "2", _("Pure")));
}
