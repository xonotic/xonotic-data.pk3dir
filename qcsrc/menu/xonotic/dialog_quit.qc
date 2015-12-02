#ifndef DIALOG_QUIT_H
#define DIALOG_QUIT_H
#include "dialog.qc"
CLASS(XonoticQuitDialog, XonoticDialog)
	METHOD(XonoticQuitDialog, fill, void(entity));
	ATTRIB(XonoticQuitDialog, title, string, _("Quit"))
	ATTRIB(XonoticQuitDialog, tooltip, string, _("Quit the game"))
	ATTRIB(XonoticQuitDialog, color, vector, SKINCOLOR_DIALOG_QUIT)
	ATTRIB(XonoticQuitDialog, intendedWidth, float, 0.5)
	ATTRIB(XonoticQuitDialog, rows, float, 3)
	ATTRIB(XonoticQuitDialog, columns, float, 2)
	ATTRIB(XonoticQuitDialog, name, string, "Quit")
ENDCLASS(XonoticQuitDialog)
#endif

#ifdef IMPLEMENTATION
void XonoticQuitDialog_fill(entity me)
{
	entity e;
	me.TR(me);
		me.TD(me, 1, 2, makeXonoticTextLabel(0.5, _("Are you sure you want to quit?")));
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticCommandButton_T(_("Yes"), '1 0 0', "echo ]quit\nquit", 0,
			_("Back to work...")));
		me.TD(me, 1, 1, e = makeXonoticButton_T(_("No"), '0 1 0',
			_("I got some more fragging to do!")));
			e.onClick = Dialog_Close;
			e.onClickEntity = me;
}
#endif
