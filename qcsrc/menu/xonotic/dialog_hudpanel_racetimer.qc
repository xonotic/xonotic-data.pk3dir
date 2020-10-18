#include "dialog_hudpanel_racetimer.qh"

#include "checkbox.qh"

void XonoticHUDRaceTimerDialog_fill(entity me)
{
	//entity e;
	string panelname = "racetimer";

	dialog_hudpanel_main_checkbox(me, panelname);

	dialog_hudpanel_main_settings(me, panelname);
}
