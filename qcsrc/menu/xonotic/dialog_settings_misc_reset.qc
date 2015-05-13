#ifndef DIALOG_SETTINGS_MISC_RESET_H
#define DIALOG_SETTINGS_MISC_RESET_H
#include "dialog.qc"
CLASS(XonoticResetDialog, XonoticDialog)
	METHOD(XonoticResetDialog, fill, void(entity))
	ATTRIB(XonoticResetDialog, title, string, _("Factory reset"))
	ATTRIB(XonoticResetDialog, color, vector, SKINCOLOR_DIALOG_QUIT)
	ATTRIB(XonoticResetDialog, intendedWidth, float, 0.5)
	ATTRIB(XonoticResetDialog, rows, float, 4)
	ATTRIB(XonoticResetDialog, columns, float, 2)
	ATTRIB(XonoticResetDialog, name, string, "Factory reset")
ENDCLASS(XonoticResetDialog)
#endif

#ifdef IMPLEMENTATION
void XonoticResetDialog_fill(entity me)
{
	entity e;
	me.TR(me);
		me.TD(me, 1, 2, makeXonoticTextLabel(0.5, _("Are you sure you want to reset all settings?")));
	me.TR(me);
		me.TD(me, 1, 2, makeXonoticTextLabel(0.5, _("This will create a backup config in your data directory")));
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticCommandButton(_("Yes"), '1 0 0', "saveconfig backup.cfg\n;\n exec defaultXonotic.cfg\n", 0));
		me.TD(me, 1, 1, e = makeXonoticButton(_("No"), '0 1 0'));
			e.onClick = Dialog_Close;
			e.onClickEntity = me;
}
#endif
