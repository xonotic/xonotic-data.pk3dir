#include "dialog_hudpanel_modicons.qh"

#include "checkbox.qh"
#include "mixedslider.qh"
#include "textlabel.qh"
#include <common/mapinfo.qh>
#include <common/gametypes/gametype/clanarena/clanarena.qh>
#include <common/gametypes/gametype/domination/domination.qh>
#include <common/gametypes/gametype/freezetag/freezetag.qh>
#include <common/gametypes/gametype/survival/survival.qh>

void XonoticHUDModIconsDialog_fill(entity me)
{
	entity e;
	string panelname = "modicons";

	dialog_hudpanel_main_checkbox(me, panelname);

	dialog_hudpanel_main_settings(me, panelname);

	string gt_str = CTX(_("GAMETYPE^%s:"));
	string text = _("Show icons");
	me.TR(me);
		me.TD(me, 1, 1.4, e = makeXonoticTextLabel(0, strzone(sprintf(gt_str, MapInfo_Type_ToText(MAPINFO_TYPE_CA)))));
		me.TD(me, 1, 2.6, e = makeXonoticCheckBox(0, "hud_panel_modicons_ca_layout", text));
	me.TR(me);
		me.TD(me, 1, 1.4, e = makeXonoticTextLabel(0, strzone(sprintf(gt_str, MapInfo_Type_ToText(MAPINFO_TYPE_DOMINATION)))));
		me.TD(me, 1, 2.6, e = makeXonoticCheckBox(0, "hud_panel_modicons_dom_layout", text));
	me.TR(me);
		me.TD(me, 1, 1.4, e = makeXonoticTextLabel(0, strzone(sprintf(gt_str, MapInfo_Type_ToText(MAPINFO_TYPE_FREEZETAG)))));
		me.TD(me, 1, 2.6, e = makeXonoticCheckBox(0, "hud_panel_modicons_ft_layout", text));
	me.TR(me);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, strzone(sprintf(gt_str, MapInfo_Type_ToText(MAPINFO_TYPE_SURVIVAL)))));
		me.TD(me, 1, 2.8, e = makeXonoticCheckBox(0, "cl_survival_reveal", _("Reveal Hunters when spectating")));
		// this technically isn't a modicons cvar since it also impacts the scoreboard & player colors, but it best fits here
	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticCheckBox(0, "hud_panel_modicons_animations", _("Enable animations")));
	me.TR(me);
		me.TD(me, 1, 1.8, e = makeXonoticTextLabel(0, _("Player name height:")));
		me.TD(me, 1, 2.2, e = makeXonoticMixedSlider_T("hud_panel_modicons_playername_height",
			_("Height of player names in the space given to player names and icons")));
			e.formatString = "%";
			e.setValueSpace(e, e.valueSpace * 1.25);
			e.addText(e, _("Disable"), 0);
			e.addRange(e, 0.1, 0.5, 0.05);
			e.configureXonoticMixedSliderValues(e);
}
