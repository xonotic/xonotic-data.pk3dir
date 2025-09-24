#include "dialog_hudpanel_modicons.qh"

#include "checkbox.qh"
#include "textlabel.qh"
#include <common/mapinfo.qh>
#include <common/gametypes/gametype/clanarena/clanarena.qh>
#include <common/gametypes/gametype/domination/domination.qh>
#include <common/gametypes/gametype/freezetag/freezetag.qh>

void XonoticHUDModIconsDialog_fill(entity me)
{
	entity e;
	string panelname = "modicons";

	dialog_hudpanel_main_checkbox(me, panelname);

	dialog_hudpanel_main_settings(me, panelname);

	me.TR(me);
		me.TD(me, 1, 1.4, e = makeXonoticTextLabel(0, ZCTX(sprintf(_("GAMETYPE^%s:"), MapInfo_Type_ToText(MAPINFO_TYPE_CA)))));
		me.TD(me, 1, 2.6, e = makeXonoticCheckBox(0, "hud_panel_modicons_ca_layout", _("Show icons")));
	me.TR(me);
		me.TD(me, 1, 1.4, e = makeXonoticTextLabel(0, ZCTX(sprintf(_("GAMETYPE^%s:"), MapInfo_Type_ToText(MAPINFO_TYPE_DOMINATION)))));
		me.TD(me, 1, 2.6, e = makeXonoticCheckBox(0, "hud_panel_modicons_dom_layout", _("Show icons")));
	me.TR(me);
		me.TD(me, 1, 1.4, e = makeXonoticTextLabel(0, ZCTX(sprintf(_("GAMETYPE^%s:"), MapInfo_Type_ToText(MAPINFO_TYPE_FREEZETAG)))));
		me.TD(me, 1, 2.6, e = makeXonoticCheckBox(0, "hud_panel_modicons_freezetag_layout", _("Show icons")));
}
