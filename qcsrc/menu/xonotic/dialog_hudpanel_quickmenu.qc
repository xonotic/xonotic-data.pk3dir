#include "dialog_hudpanel_quickmenu.qh"

#include "checkbox.qh"
#include "textlabel.qh"
#include "radiobutton.qh"

void XonoticHUDQuickMenuDialog_fill(entity me)
{
	entity e;
	string panelname = "quickmenu";

	// this panel has no main cvar
	//dialog_hudpanel_main_checkbox(me, panelname);

	dialog_hudpanel_main_settings(me, panelname);

	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticTextLabel(0, _("Text alignment:")));
	me.TR(me);
		me.TDempty(me, 0.2);
			me.TD(me, 1, 3.8/3, e = makeXonoticRadioButton(3, "hud_panel_quickmenu_align", "0", _("Left")));
			me.TD(me, 1, 3.8/3, e = makeXonoticRadioButton(3, "hud_panel_quickmenu_align", "0.5", _("Center")));
			me.TD(me, 1, 3.8/3, e = makeXonoticRadioButton(3, "hud_panel_quickmenu_align", "1", _("Right")));

	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticCheckBox(0, "hud_panel_quickmenu_translatecommands", _("Translate commands")));
	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticCheckBox(0, "hud_panel_quickmenu_server_is_default", _("Use the server's quickmenu")));
}
