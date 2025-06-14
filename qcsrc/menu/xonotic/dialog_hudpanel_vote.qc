#include "dialog_hudpanel_vote.qh"

#include "checkbox.qh"
#include "textlabel.qh"
#include "slider.qh"

void XonoticHUDVoteDialog_fill(entity me)
{
	entity e;
	string panelname = "vote";

	dialog_hudpanel_main_checkbox(me, panelname);

	dialog_hudpanel_main_settings(me, panelname);

	me.TR(me);
		me.TD(me, 1, 1.4, e = makeXonoticTextLabel(0, _("Opacity after voting:")));
		me.TD(me, 1, 2.6, e = makeXonoticSlider(0.1, 1, 0.1, "hud_panel_vote_alreadyvoted_alpha"));
			e.formatString = "%";
}
