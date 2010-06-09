#ifdef INTERFACE
CLASS(XonoticHUDExitDialog) EXTENDS(XonoticRootDialog)
	METHOD(XonoticHUDExitDialog, fill, void(entity))
	ATTRIB(XonoticHUDExitDialog, title, string, "Exit HUD Setup")
	ATTRIB(XonoticHUDExitDialog, color, vector, SKINCOLOR_DIALOG_TEAMSELECT)
	ATTRIB(XonoticHUDExitDialog, intendedWidth, float, 0.9)
	ATTRIB(XonoticHUDExitDialog, rows, float, 22)
	ATTRIB(XonoticHUDExitDialog, columns, float, 6.5)
	ATTRIB(XonoticHUDExitDialog, name, string, "HUDExit")
ENDCLASS(XonoticHUDExitDialog)

#endif

#ifdef IMPLEMENTATION
void fillXonoticHUDExitDialog(entity me)
{
	entity e;
	me.TR(me);
		me.TD(me, 2, 1, makeXonoticCommandButton("Exit Setup", '1 0.5 0.5', "_hud_configure 0", 1));
}
#endif
