#include "dialog_hudpanel_checkpoints.qh"

#include "textlabel.qh"
#include "checkbox.qh"
#include "slider.qh"
#include "radiobutton.qh"

void XonoticHUDCheckpointsDialog_fill(entity me)
{
	entity e;
	string panelname = "checkpoints";

	dialog_hudpanel_main_checkbox(me, panelname);

	dialog_hudpanel_main_settings(me, panelname);

	me.TR(me);
		me.TD(me, 1, 1.4, e = makeXonoticTextLabel(0, _("Font scale:")));
		me.TD(me, 1, 2.6, e = makeXonoticSlider(0.8, 2, 0.1, "hud_panel_checkpoints_fontscale"));
	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticCheckBox(0, "hud_panel_checkpoints_flip", _("Flip checkpoint order")));

	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticTextLabel(0, _("Text alignment:")));
	me.TR(me);
		me.TDempty(me, 0.2);
			me.TD(me, 1, 3.8/3, e = makeXonoticRadioButton(2, "hud_panel_checkpoints_align", "0", _("Left")));
			me.TD(me, 1, 3.8/3, e = makeXonoticRadioButton(2, "hud_panel_checkpoints_align", "0.5", _("Center")));
			me.TD(me, 1, 3.8/3, e = makeXonoticRadioButton(2, "hud_panel_checkpoints_align", "1", _("Right")));
}
