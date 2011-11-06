#ifdef INTERFACE
CLASS(XonoticHUDQuickMenuDialog) EXTENDS(XonoticRootDialog)
	METHOD(XonoticHUDQuickMenuDialog, fill, void(entity))
	ATTRIB(XonoticHUDQuickMenuDialog, title, string, _("Quick Menu Panel"))
	ATTRIB(XonoticHUDQuickMenuDialog, color, vector, SKINCOLOR_DIALOG_TEAMSELECT)
	ATTRIB(XonoticHUDQuickMenuDialog, intendedWidth, float, 0.4)
	ATTRIB(XonoticHUDQuickMenuDialog, rows, float, 15)
	ATTRIB(XonoticHUDQuickMenuDialog, columns, float, 4)
	ATTRIB(XonoticHUDQuickMenuDialog, name, string, "HUDquickmenu")
ENDCLASS(XonoticHUDQuickMenuDialog)
#endif

#ifdef IMPLEMENTATION
void XonoticHUDQuickMenuDialog_fill(entity me)
{
	entity e;
	string panelname = "quickmenu";

	DIALOG_HUDPANEL_COMMON();
}
#endif
