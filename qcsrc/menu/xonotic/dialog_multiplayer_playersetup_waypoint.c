#ifdef INTERFACE
CLASS(XonoticWaypointDialog) EXTENDS(XonoticDialog)
	METHOD(XonoticWaypointDialog, fill, void(entity))
	METHOD(XonoticWaypointDialog, showNotify, void(entity))
	ATTRIB(XonoticWaypointDialog, title, string, _("Waypoints"))
	ATTRIB(XonoticWaypointDialog, color, vector, SKINCOLOR_DIALOG_RADAR)
	ATTRIB(XonoticWaypointDialog, intendedWidth, float, 0.7)
	ATTRIB(XonoticWaypointDialog, rows, float, 6)
	ATTRIB(XonoticWaypointDialog, columns, float, 4)
ENDCLASS(XonoticWaypointDialog)
#endif

#ifdef IMPLEMENTATION
void XonoticWaypointDialog_showNotify(entity me)
{
        loadAllCvars(me);
}
void XonoticWaypointDialog_fill(entity me)
{
	entity e;
	
	me.TR(me);
		me.TD(me, 1, 4, makeXonoticTextLabel(0, _("Waypoint settings:")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 3.8, e = makeXonoticCheckBox(1, "cl_hidewaypoints", _("Show base waypoints")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Waypoint scale:")));
			me.TD(me, 1, 3, e = makeXonoticSlider(0.5, 1.5, 0.01, "g_waypointsprite_scale"));
				setDependent(e, "cl_hidewaypoints", 0, 0);
	me.TR(me);
 		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Waypoint alpha:")));
			me.TD(me, 1, 3, e = makeXonoticSlider(0.1, 1, 0.01, "g_waypointsprite_alpha"));
				setDependent(e, "cl_hidewaypoints", 0, 0);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Show names:")));
		me.TD(me, 1, 3, e = makeXonoticTextSlider("cl_shownames"));
			e.addValue(e, _("Never"), "0");
			e.addValue(e, _("Teammates"), "1");
			e.addValue(e, _("All players"), "2");
			e.configureXonoticTextSliderValues(e);
	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, e = makeXonoticButton(_("OK"), '0 0 0'));
			e.onClick = Dialog_Close;
			e.onClickEntity = me;
}

#endif
