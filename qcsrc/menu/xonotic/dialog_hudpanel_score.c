#ifdef INTERFACE
CLASS(XonoticHUDScoreDialog) EXTENDS(XonoticRootDialog)
	METHOD(XonoticHUDScoreDialog, fill, void(entity))
	ATTRIB(XonoticHUDScoreDialog, title, string, _("Score Panel"))
	ATTRIB(XonoticHUDScoreDialog, color, vector, SKINCOLOR_DIALOG_TEAMSELECT)
	ATTRIB(XonoticHUDScoreDialog, intendedWidth, float, 0.4)
	ATTRIB(XonoticHUDScoreDialog, rows, float, 15)
	ATTRIB(XonoticHUDScoreDialog, columns, float, 4)
	ATTRIB(XonoticHUDScoreDialog, name, string, "HUDscore")
ENDCLASS(XonoticHUDScoreDialog)
#endif

#ifdef IMPLEMENTATION
void XonoticHUDScoreDialog_fill(entity me)
{
	entity e;
	string panelname = "score";

	DIALOG_HUDPANEL_COMMON();
}
#endif
