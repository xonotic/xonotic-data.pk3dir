#include "dialog_hudpanel_centerprint.qh"

#include "checkbox.qh"
#include "textlabel.qh"
#include "slider.qh"
#include "mixedslider.qh"
#include "radiobutton.qh"

void XonoticHUDCenterprintDialog_fill(entity me)
{
	entity e;
	string panelname = "centerprint";
	float i;

	dialog_hudpanel_main_checkbox(me, panelname);

	dialog_hudpanel_main_settings(me, panelname);

	me.TR(me);
		me.TD(me, 1, 1.4, e = makeXonoticTextLabel(0, _("Message duration:")));
		me.TD(me, 1, 2.6, e = makeXonoticSlider(1, 10, 1, "hud_panel_centerprint_time"));
			e.formatString = "s";
			e.setValueSpace(e, e.valueSpace * 1.25);
	me.TR(me);
		me.TD(me, 1, 1.4, e = makeXonoticTextLabel(0, _("Fade time:")));
			setDependentNOT(e, "hud_panel_centerprint_time", 0);
		me.TD(me, 1, 2.6, e = makeXonoticMixedSlider("hud_panel_centerprint_fade_out"));
			e.formatString = "S";
			e.setValueSpace(e, e.valueSpace * 1.25);
			e.addText(e, ZCTX(_("FADESPEED^Instant")), 0);
			e.addRange(e, 0.05, 1, 0.05);
			e.configureXonoticMixedSliderValues(e);
			setDependentNOT(e, "hud_panel_centerprint_time", 0);
	me.TR(me);
		me.TD(me, 1, 1.4, e = makeXonoticTextLabel(0, _("Font scale:")));
			setDependentNOT(e, "hud_panel_centerprint_time", 0);
		me.TD(me, 1, 2.6, e = makeXonoticSlider(0.5, 2, 0.1, "hud_panel_centerprint_fontscale"));
			setDependentNOT(e, "hud_panel_centerprint_time", 0);
	me.TR(me);
		me.TD(me, 1, 1.4, e = makeXonoticTextLabel(0, _("Bold font scale:")));
			setDependentNOT(e, "hud_panel_centerprint_time", 0);
		me.TD(me, 1, 2.6, e = makeXonoticSlider(0.5, 3, 0.1, "hud_panel_centerprint_fontscale_bold"));
			setDependentNOT(e, "hud_panel_centerprint_time", 0);
	me.TR(me);
		me.TD(me, 1, 1.4, e = makeXonoticTextLabel(0, _("Title font scale:")));
			setDependentNOT(e, "hud_panel_centerprint_time", 0);
		me.TD(me, 1, 2.6, e = makeXonoticSlider(0.5, 4, 0.1, "hud_panel_centerprint_fontscale_title"));
			setDependentNOT(e, "hud_panel_centerprint_time", 0);
	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticCheckBox(0, "hud_panel_centerprint_flip", _("Flip messages order")));
			setDependentNOT(e, "hud_panel_centerprint_time", 0);

	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticTextLabel(0, _("Text alignment:")));
			setDependentNOT(e, "hud_panel_centerprint_time", 0);
	me.TR(me);
		me.TDempty(me, 0.2);
			me.TD(me, 1, 3.8/3, e = makeXonoticRadioButton(2, "hud_panel_centerprint_align", "0", _("Left")));
				setDependentNOT(e, "hud_panel_centerprint_time", 0);
			me.TD(me, 1, 3.8/3, e = makeXonoticRadioButton(2, "hud_panel_centerprint_align", "0.5", _("Center")));
				setDependentNOT(e, "hud_panel_centerprint_time", 0);
			me.TD(me, 1, 3.8/3, e = makeXonoticRadioButton(2, "hud_panel_centerprint_align", "1", _("Right")));
				setDependentNOT(e, "hud_panel_centerprint_time", 0);
}
