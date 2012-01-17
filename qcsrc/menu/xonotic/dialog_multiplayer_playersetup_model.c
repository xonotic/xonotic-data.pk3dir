#ifdef INTERFACE
CLASS(XonoticModelDialog) EXTENDS(XonoticDialog)
	METHOD(XonoticModelDialog, toString, string(entity))
	METHOD(XonoticModelDialog, fill, void(entity))
	METHOD(XonoticModelDialog, showNotify, void(entity))
	ATTRIB(XonoticModelDialog, title, string, _("Model settings"))
	ATTRIB(XonoticModelDialog, color, vector, SKINCOLOR_DIALOG_MODEL)
	ATTRIB(XonoticModelDialog, intendedWidth, float, 0.5)
	ATTRIB(XonoticModelDialog, rows, float, 12)
	ATTRIB(XonoticModelDialog, columns, float, 3)
ENDCLASS(XonoticModelDialog)
#endif

#ifdef IMPLEMENTATION
void XonoticModelDialog_showNotify(entity me)
{
	loadAllCvars(me);
}
string XonoticModelDialog_toString(entity me)
{
	return "hi"; // TODO: show csqc model settings like forcemyplayer and deglowing/ghosting bodies with text here
}
void XonoticModelDialog_fill(entity me)
{
	entity e;
	

		
	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, e = makeXonoticButton(_("OK"), '0 0 0'));
			e.onClick = Dialog_Close;
			e.onClickEntity = me;
}
#endif
