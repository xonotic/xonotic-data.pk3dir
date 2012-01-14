#ifdef INTERFACE
CLASS(XonoticViewDialog) EXTENDS(XonoticDialog)
	METHOD(XonoticViewDialog, toString, string(entity))
	METHOD(XonoticViewDialog, fill, void(entity))
	METHOD(XonoticViewDialog, showNotify, void(entity))
	ATTRIB(XonoticViewDialog, title, string, _("View settings"))
	ATTRIB(XonoticViewDialog, color, vector, SKINCOLOR_DIALOG_WEAPONS)
	ATTRIB(XonoticViewDialog, intendedWidth, float, 0.4)
	ATTRIB(XonoticViewDialog, rows, float, 18)
	ATTRIB(XonoticViewDialog, columns, float, 3)
ENDCLASS(XonoticViewDialog)
#endif

#ifdef IMPLEMENTATION
void XonoticViewDialog_showNotify(entity me)
{
	loadAllCvars(me);
}
string XonoticViewDialog_toString(entity me)
{
	return "hi"; //me.weaponsList.toString(me.weaponsList);
}
void XonoticViewDialog_fill(entity me)
{
	entity e;

	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "cl_weaponpriority_useforcycling", _("Use priority list for weapon cycling")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "cl_autoswitch", _("Auto switch weapons on pickup")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "r_drawviewmodel", _("Draw 1st person weapon model")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.9, e = makeXonoticRadioButton(1, "cl_gunalign", "4", _("Left align")));
			setDependent(e, "r_drawviewmodel", 1, 1);
		me.TD(me, 1, 0.9, e = makeXonoticRadioButton(1, "cl_gunalign", "1", _("Center")));
			setDependent(e, "r_drawviewmodel", 1, 1);
		me.TD(me, 1, 1.0, e = makeXonoticRadioButton(1, "cl_gunalign", "3", _("Right align")));
			setDependent(e, "r_drawviewmodel", 1, 1);
	me.TR(me);
		me.TD(me, 1, me.columns, e = makeXonoticButton(_("OK"), '0 0 0'));
			e.onClick = Dialog_Close;
			e.onClickEntity = me;
}
#endif
