#ifdef INTERFACE
CLASS(XonoticSandboxToolsDialog) EXTENDS(XonoticRootDialog)
	METHOD(XonoticSandboxToolsDialog, fill, void(entity)) // to be overridden by user to fill the dialog with controls
	ATTRIB(XonoticSandboxToolsDialog, title, string, _("Sandbox Tools")) // ;)
	ATTRIB(XonoticSandboxToolsDialog, color, vector, SKINCOLOR_DIALOG_SANDBOXTOOLS)
	ATTRIB(XonoticSandboxToolsDialog, intendedWidth, float, 0.8)
	ATTRIB(XonoticSandboxToolsDialog, rows, float, 20)
	ATTRIB(XonoticSandboxToolsDialog, columns, float, 4)
	ATTRIB(XonoticSandboxToolsDialog, name, string, "SandboxTools")
ENDCLASS(XonoticSandboxToolsDialog)
#endif

#ifdef IMPLEMENTATION
void XonoticSandboxToolsDialog_fill(entity me)
{
	entity e, box;

	me.TR(me);
		me.TD(me, 1, 0.25, e = makeXonoticTextLabel(0, _("Model:")));
		me.TD(me, 1, 2.0, box = makeXonoticInputBox(1, "menu_sandbox_spawn_model"));
			box.forbiddenCharacters = "\r\n\\\"$"; // don't care, isn't getting saved
			box.maxLength = -127; // negative means encoded length in bytes
			box.saveImmediately = 1;
	me.TDempty(me, 0.2);
		me.TD(me, 1, 0.5, makeXonoticCommandButton(_("Spawn"), '0 0 0', "sandbox spawn_object $menu_sandbox_spawn_model", 0));

	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, e = makeXonoticButton(_("OK"), '0 0 0'));
			e.onClick = Dialog_Close;
			e.onClickEntity = me;
}
#endif

/* Click. The c-word is here so you can grep for it :-) */
