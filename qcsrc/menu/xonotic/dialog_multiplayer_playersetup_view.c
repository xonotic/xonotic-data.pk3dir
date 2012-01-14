#ifdef INTERFACE
CLASS(XonoticViewDialog) EXTENDS(XonoticDialog)
	METHOD(XonoticViewDialog, toString, string(entity))
	METHOD(XonoticViewDialog, fill, void(entity))
	METHOD(XonoticViewDialog, showNotify, void(entity))
	ATTRIB(XonoticViewDialog, title, string, _("View settings"))
	ATTRIB(XonoticViewDialog, color, vector, SKINCOLOR_DIALOG_VIEW)
	ATTRIB(XonoticViewDialog, intendedWidth, float, 0.6)
	ATTRIB(XonoticViewDialog, rows, float, 10)
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
		me.TD(me, 1, 3, e = makeXonoticCheckBox(1, "cl_hidewaypoints", _("Show base waypoints")));
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Waypoint scale:")));
			me.TD(me, 1, 2, e = makeXonoticSlider(0.5, 1.5, 0.05, "g_waypointsprite_scale"));
				setDependent(e, "cl_hidewaypoints", 0, 0);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Waypoint alpha:")));
			me.TD(me, 1, 2, e = makeXonoticSlider(0.1, 1, 0.05, "g_waypointsprite_alpha"));
				setDependent(e, "cl_hidewaypoints", 0, 0);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(1, "hud_shownames", _("Show names above players")));
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
			
	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, e = makeXonoticButton(_("OK"), '0 0 0'));
			e.onClick = Dialog_Close;
			e.onClickEntity = me;
}
#endif
