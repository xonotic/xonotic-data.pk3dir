#ifdef INTERFACE
CLASS(XonoticCrosshairDialog) EXTENDS(XonoticDialog)
	METHOD(XonoticCrosshairDialog, toString, string(entity))
	METHOD(XonoticCrosshairDialog, fill, void(entity))
	METHOD(XonoticCrosshairDialog, showNotify, void(entity))
	ATTRIB(XonoticCrosshairDialog, title, string, _("Crosshair settings"))
	ATTRIB(XonoticCrosshairDialog, color, vector, SKINCOLOR_DIALOG_CROSSHAIR)
	ATTRIB(XonoticCrosshairDialog, intendedWidth, float, 0.5)
	ATTRIB(XonoticCrosshairDialog, rows, float, 12)
	ATTRIB(XonoticCrosshairDialog, columns, float, 3)
ENDCLASS(XonoticCrosshairDialog)
#endif

#ifdef IMPLEMENTATION
void XonoticCrosshairDialog_showNotify(entity me)
{
	loadAllCvars(me);
}
string XonoticCrosshairDialog_toString(entity me)
{
	return "hi"; // TODO: show status of crosshair dot and hittest and pickups and such here with text
}
void XonoticCrosshairDialog_fill(entity me)
{
	entity e;
	

		
	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, e = makeXonoticButton(_("OK"), '0 0 0'));
			e.onClick = Dialog_Close;
			e.onClickEntity = me;
}
#endif
