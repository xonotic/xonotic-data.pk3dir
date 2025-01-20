#include "dialog_hudpanel_engineinfo.qh"

#include "textlabel.qh"
#include "checkbox.qh"
#include "slider.qh"

void XonoticHUDEngineInfoDialog_fill(entity me)
{
	entity e;
	string panelname = "engineinfo";

	dialog_hudpanel_main_checkbox(me, panelname);

	dialog_hudpanel_main_settings(me, panelname);

	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticTextLabel(0, _("FPS:")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 3.8, e = makeXonoticCheckBox(0, "hud_panel_engineinfo_framecounter_exponentialmovingaverage", _("Use an averaging algorithm")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Decimal places:")));
		me.TD(me, 1, 2.6, e = makeXonoticSlider(0, 2, 1, "hud_panel_engineinfo_framecounter_decimals"));
}
