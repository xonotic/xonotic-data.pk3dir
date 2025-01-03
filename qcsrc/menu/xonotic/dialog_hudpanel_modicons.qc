#include "dialog_hudpanel_modicons.qh"

#include "checkbox.qh"
#include "textlabel.qh"

void XonoticHUDModIconsDialog_fill(entity me)
{
	entity e;
	string panelname = "modicons";

	dialog_hudpanel_main_checkbox(me, panelname);

	dialog_hudpanel_main_settings(me, panelname);

	me.TR(me);
		me.TD(me, 1, 1.4, e = makeXonoticTextLabel(0, _("Clan Arena:")));
		me.TD(me, 1, 2.6, e = makeXonoticCheckBox(0, "hud_panel_modicons_ca_layout", _("Show icons")));
	me.TR(me);
		me.TD(me, 1, 1.4, e = makeXonoticTextLabel(0, _("Domination:")));
		me.TD(me, 1, 2.6, e = makeXonoticCheckBox(0, "hud_panel_modicons_dom_layout", _("Show icons")));
	me.TR(me);
		me.TD(me, 1, 1.4, e = makeXonoticTextLabel(0, _("Freeze Tag:")));
		me.TD(me, 1, 2.6, e = makeXonoticCheckBox(0, "hud_panel_modicons_freezetag_layout", _("Show icons")));
}
