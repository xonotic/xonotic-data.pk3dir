#include "dialog_hudpanel_centerprint.qh"

#include "checkbox.qh"
#include "textlabel.qh"
#include "slider.qh"
#include "textslider.qh"
#include "radiobutton.qh"

void XonoticHUDCenterprintDialog_fill(entity me)
{
	entity e;
	string panelname = "centerprint";
	float i;

	dialog_hudpanel_main_checkbox(me, panelname);

	dialog_hudpanel_main_settings(me, panelname);

	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticTextLabel(0, _("Centerprints:")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Message duration:")));
		me.TD(me, 1, 2.6, e = makeXonoticSlider(1, 10, 1, "hud_panel_centerprint_time"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Fade time:")));
		me.TD(me, 1, 2.6, e = makeXonoticTextSlider("hud_panel_centerprint_fade_out"));
			e.addValue(e, ZCTX(_("FADESPEED^Instant")), "0");
			for(i = 1; i <= 19; ++i)
				e.addValue(e, strzone(ftos_decimals(i / 20, 2)), strzone(ftos_mindecimals(i / 20)));
			e.addValue(e, "1.00", "1");
			e.configureXonoticTextSliderValues(e);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Font scale:")));
		me.TD(me, 1, 2.6, e = makeXonoticSlider(0.5, 2, 0.1, "hud_panel_centerprint_fontscale"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Bold font scale:")));
		me.TD(me, 1, 2.6, e = makeXonoticSlider(0.5, 3, 0.1, "hud_panel_centerprint_fontscale_bold"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Title font scale:")));
		me.TD(me, 1, 2.6, e = makeXonoticSlider(0.5, 4, 0.1, "hud_panel_centerprint_fontscale_title"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 3.8, e = makeXonoticCheckBox(0, "hud_panel_centerprint_flip", _("Flip messages order")));
	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticTextLabel(0, _("Text alignment:")));
	me.TR(me);
		me.TDempty(me, 0.2);
			me.TD(me, 1, 3.8/3, e = makeXonoticRadioButton(3, "hud_panel_centerprint_align", "0", _("Left")));
			me.TD(me, 1, 3.8/3, e = makeXonoticRadioButton(3, "hud_panel_centerprint_align", "0.5", _("Center")));
			me.TD(me, 1, 3.8/3, e = makeXonoticRadioButton(3, "hud_panel_centerprint_align", "1", _("Right")));
}
