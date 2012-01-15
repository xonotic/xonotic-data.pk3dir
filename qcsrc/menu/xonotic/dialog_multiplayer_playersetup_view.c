#ifdef INTERFACE
CLASS(XonoticViewDialog) EXTENDS(XonoticDialog)
	METHOD(XonoticViewDialog, toString, string(entity))
	METHOD(XonoticViewDialog, fill, void(entity))
	METHOD(XonoticViewDialog, showNotify, void(entity))
	ATTRIB(XonoticViewDialog, title, string, _("View settings"))
	ATTRIB(XonoticViewDialog, color, vector, SKINCOLOR_DIALOG_VIEW)
	ATTRIB(XonoticViewDialog, intendedWidth, float, 0.9)
	ATTRIB(XonoticViewDialog, rows, float, 13)
	ATTRIB(XonoticViewDialog, columns, float, 6.2) // added extra .2 for center space 
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
	entity e, sl;
	float i;
	
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Field of view:")));
		me.TD(me, 1, 2, e = makeXonoticSlider(60, 130, 5, "fov"));
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Zoom:")));
		me.TD(me, 1, 2, e = makeXonoticTextSlider("cl_reticle"));
			e.addValue(e, _("Fullscreen"), "0");
			e.addValue(e, _("With reticle"), "1");
			e.configureXonoticTextSliderValues(e);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Factor:")));
		me.TD(me, 1, 2, e = makeXonoticSlider(2, 16, 0.5, "cl_zoomfactor"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Speed:")));
		me.TD(me, 1, 2, e = makeXonoticTextSlider("cl_zoomspeed"));
			e.addValue(e, "1", "1"); // Samual: for() loop doesn't work here, even though it would make sense.
			e.addValue(e, "2", "2");
			e.addValue(e, "3", "3");
			e.addValue(e, "4", "4");
			e.addValue(e, "5", "5");
			e.addValue(e, "6", "6");
			e.addValue(e, "7", "7");
			e.addValue(e, "8", "8");
			e.addValue(e, _("Instant"), "-1");
			e.configureXonoticTextSliderValues(e);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Sensitivity:")));
		me.TD(me, 1, 2, e = makeXonoticSlider(0, 1, 0.1, "cl_zoomsensitivity"));
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Velocity zoom:")));
		me.TD(me, 1, 2, e = makeXonoticTextSlider("cl_velocityzoom_type"));
			e.addValue(e, _("Disabled"), "0");
			e.addValue(e, _("Forward only"), "3");
			e.addValue(e, _("All directions"), "1");
			e.configureXonoticTextSliderValues(e);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Speed")));
		me.TD(me, 1, 2, e = makeXonoticSlider(-1, 1, 0.2, "cl_velocityzoom"));
		setDependent(e, "cl_velocityzoom_type", 1, 3);
	me.TR(me);
	
	me.gotoRC(me, 0, 3.2); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 3, e = makeXonoticRadioButton(1, "chase_active", "0", _("1st person perspective")));
		makeMulti(e, "crosshair_hittest_showimpact");
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.8, e = makeXonoticCheckBoxEx(0.05, 0, "cl_bobfall", _("Smooth the view when landing from a jump")));
		setDependent(e, "chase_active", -1, 0);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.8, e = makeXonoticCheckBoxEx(0.05, 0, "cl_smoothviewheight", _("Smooth the view while crouching")));
		setDependent(e, "chase_active", -1, 0);
	me.TR(me);
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticRadioButton(1, "chase_active", "1", _("3rd person perspective")));
		makeMulti(e, "crosshair_hittest_showimpact");
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Back distance")));
		setDependent(e, "chase_active", 1, 1);
		me.TD(me, 1, 2, e = makeXonoticSlider(10, 100, 1, "chase_back"));
		setDependent(e, "chase_active", 1, 1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Up distance")));
		setDependent(e, "chase_active", 1, 1);
		me.TD(me, 1, 2, e = makeXonoticSlider(10, 50, 1, "chase_up"));
		setDependent(e, "chase_active", 1, 1);
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(1, "cl_clippedspectating", _("Allow passing through walls while spectating")));
		
	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, e = makeXonoticButton(_("OK"), '0 0 0'));
			e.onClick = Dialog_Close;
			e.onClickEntity = me;
}
#endif
