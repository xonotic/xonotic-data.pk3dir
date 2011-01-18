#ifdef INTERFACE
CLASS(XonoticFirstRunDialog) EXTENDS(XonoticRootDialog)
	METHOD(XonoticFirstRunDialog, fill, void(entity)) // to be overridden by user to fill the dialog with controls
	ATTRIB(XonoticFirstRunDialog, title, string, _("Welcome"))
	ATTRIB(XonoticFirstRunDialog, color, vector, SKINCOLOR_DIALOG_FIRSTRUN)
	ATTRIB(XonoticFirstRunDialog, intendedWidth, float, 0.6)
	ATTRIB(XonoticFirstRunDialog, rows, float, 15)
	ATTRIB(XonoticFirstRunDialog, columns, float, 3)
	ATTRIB(XonoticFirstRunDialog, name, string, "FirstRun")
	ATTRIB(XonoticFirstRunDialog, playerNameLabel, entity, NULL)
	ATTRIB(XonoticFirstRunDialog, playerNameLabelAlpha, float, 0)

	ATTRIB(XonoticFirstRunDialog, closable, float, 0)
ENDCLASS(XonoticFirstRunDialog)
#endif

#ifdef IMPLEMENTATION
float CheckFirstRunButton(entity me)
{
	if(cvar_string("_cl_name") != "Player")
		return 1;
	if(cvar_string("prvm_language") != prvm_language)
		return 1; // OK will then reopen the dialog in another language
	return 0;
}

void XonoticFirstRunDialog_fill(entity me)
{
	entity e;
	entity label, box;

	me.TR(me);
		me.TD(me, 2, 3, e = makeXonoticTextLabel(0, _("Welcome to Xonotic, please select your language preference and enter your player name to get started.  You can change these options later through the menu system.")));
		e.allowWrap = 1;
	me.TR(me);

	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticTextLabel(0, _("Text language:")));
	me.TR(me);
		me.TD(me, 3, 3, e = makeXonoticLanguageList());
			e.name = "languageselector_firstrun";
			e.doubleClickCommand = "saveconfig; menu_restart; togglemenu";
	me.TR(me);
	me.TR(me);

	me.TR(me);
		me.TD(me, 1, 0.5, me.playerNameLabel = makeXonoticTextLabel(0, _("Name:")));
			me.playerNameLabelAlpha = me.playerNameLabel.alpha;
		me.TD(me, 1, 2.5, label = makeXonoticTextLabel(0, string_null));
			label.allowCut = 1;
			label.allowColors = 1;
			label.alpha = 1;
	me.TR(me);
		me.TD(me, 1, 3.0, box = makeXonoticInputBox(1, "_cl_name"));
			box.forbiddenCharacters = "\r\n\\\"$"; // don't care, isn't getting saved
			box.maxLength = -127; // negative means encoded length in bytes
			box.saveImmediately = 1;
			label.textEntity = box;
	me.TR(me);
		me.TD(me, 5, 1, e = makeXonoticColorpicker(box));
		me.TD(me, 5, 2, e = makeXonoticCharmap(box));
	me.TR(me);
	me.TR(me);
	me.TR(me);
	me.TR(me);

	// because of the language selector, this is a menu_restart!
	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, e = makeXonoticCommandButton(_("Save settings"), '0 0 0', "saveconfig; menu_restart; togglemenu", COMMANDBUTTON_APPLY));
		setDependentWeird(e, CheckFirstRunButton);
}
#endif
