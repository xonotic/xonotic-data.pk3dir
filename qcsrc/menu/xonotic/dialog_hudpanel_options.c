#ifdef INTERFACE
CLASS(XonoticHUDOptionsDialog) EXTENDS(XonoticRootDialog)
	METHOD(XonoticHUDOptionsDialog, fill, void(entity))
	ATTRIB(XonoticHUDOptionsDialog, title, string, "HUD Setup")
	ATTRIB(XonoticHUDOptionsDialog, color, vector, SKINCOLOR_DIALOG_TEAMSELECT)
	ATTRIB(XonoticHUDOptionsDialog, intendedWidth, float, 0.4)
	ATTRIB(XonoticHUDOptionsDialog, rows, float, 15)
	ATTRIB(XonoticHUDOptionsDialog, columns, float, 4)
	ATTRIB(XonoticHUDOptionsDialog, name, string, "HUDOptions")
ENDCLASS(XonoticHUDOptionsDialog)

#endif

#ifdef IMPLEMENTATION
void fillXonoticHUDOptionsDialog(entity me)
{
	entity e;
	me.TR(me);
	
}
#endif
