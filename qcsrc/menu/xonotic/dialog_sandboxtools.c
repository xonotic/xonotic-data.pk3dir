#ifdef INTERFACE
CLASS(XonoticSandboxToolsDialog) EXTENDS(XonoticRootDialog)
	METHOD(XonoticSandboxToolsDialog, fill, void(entity)) // to be overridden by user to fill the dialog with controls
	ATTRIB(XonoticSandboxToolsDialog, title, string, _("Sandbox Tools")) // ;)
	ATTRIB(XonoticSandboxToolsDialog, color, vector, SKINCOLOR_DIALOG_SANDBOXTOOLS)
	ATTRIB(XonoticSandboxToolsDialog, intendedWidth, float, 0.4)
	ATTRIB(XonoticSandboxToolsDialog, rows, float, 5)
	ATTRIB(XonoticSandboxToolsDialog, columns, float, 4)
	ATTRIB(XonoticSandboxToolsDialog, name, string, "SandboxTools")
ENDCLASS(XonoticSandboxToolsDialog)
#endif

#ifdef IMPLEMENTATION
void XonoticSandboxToolsDialog_fill(entity me)
{
	entity e;

	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, e = makeXonoticButton(_("OK"), '0 0 0'));
			e.onClick = Dialog_Close;
			e.onClickEntity = me;
}
#endif

/* Click. The c-word is here so you can grep for it :-) */
