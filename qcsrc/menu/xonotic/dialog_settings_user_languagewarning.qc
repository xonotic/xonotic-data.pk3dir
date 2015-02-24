#ifdef INTERFACE
CLASS(XonoticLanguageWarningDialog) EXTENDS(XonoticDialog)
	METHOD(XonoticLanguageWarningDialog, fill, void(entity)) // to be overridden by user to fill the dialog with controls
	ATTRIB(XonoticLanguageWarningDialog, title, string, _("Warning"))
	ATTRIB(XonoticLanguageWarningDialog, color, vector, SKINCOLOR_DIALOG_HUDCONFIRM)
	ATTRIB(XonoticLanguageWarningDialog, intendedWidth, float, 0.6)
	ATTRIB(XonoticLanguageWarningDialog, rows, float, 5)
	ATTRIB(XonoticLanguageWarningDialog, columns, float, 4)
ENDCLASS(XonoticLanguageWarningDialog)
#endif

#ifdef IMPLEMENTATION
void XonoticLanguageWarningDialog_fill(entity me)
{
	entity e;
	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticTextLabel(0, _("While connected language changes will be applied only to the menu,")));
	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticTextLabel(0, _("full language changes will take effect starting from the next game")));
	me.TR(me);
	me.TR(me);
		// reconnect command doesn't work properly, otherwise it would replace disconnect
		me.TD(me, 1, 2, e = makeXonoticCommandButton(_("Disconnect now"), '0 0 0', "disconnect", 0));
		me.TD(me, 1, 2, e = makeXonoticCommandButton(_("Switch language"), '0 0 0', "prvm_language \"$_menu_prvm_language\"; menu_restart; menu_cmd languageselect", 0));
}
#endif
