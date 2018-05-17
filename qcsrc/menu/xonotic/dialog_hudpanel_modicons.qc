#include "dialog_hudpanel_modicons.qh"

#include "checkbox.qh"

void XonoticHUDModIconsDialog_fill(entity me)
{
	//entity e;
	string panelname = "modicons";

	dialog_hudpanel_main_checkbox(me, panelname);

	dialog_hudpanel_main_settings(me, panelname);
}
