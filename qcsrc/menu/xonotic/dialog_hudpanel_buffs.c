#ifdef INTERFACE
CLASS(XonoticHUDBuffsDialog) EXTENDS(XonoticRootDialog)
	METHOD(XonoticHUDBuffsDialog, fill, void(entity))
	ATTRIB(XonoticHUDBuffsDialog, title, string, _("Buffs Panel"))
	ATTRIB(XonoticHUDBuffsDialog, color, vector, SKINCOLOR_DIALOG_TEAMSELECT)
	ATTRIB(XonoticHUDBuffsDialog, intendedWidth, float, 0.4)
	ATTRIB(XonoticHUDBuffsDialog, rows, float, 15)
	ATTRIB(XonoticHUDBuffsDialog, columns, float, 4)
	ATTRIB(XonoticHUDBuffsDialog, name, string, "HUDbuffs")
	ATTRIB(XonoticHUDBuffsDialog, requiresConnection, float, TRUE)
ENDCLASS(XonoticHUDBuffsDialog)
#endif

#ifdef IMPLEMENTATION
void XonoticHUDBuffsDialog_fill(entity me)
{
	entity e;
	string panelname = "buffs";

	DIALOG_HUDPANEL_COMMON();
}
#endif
