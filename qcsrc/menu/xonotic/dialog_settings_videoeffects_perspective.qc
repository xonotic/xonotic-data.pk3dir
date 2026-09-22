#include "dialog_settings_videoeffects_perspective.qh"

#include "checkbox.qh"
#include "radiobutton.qh"
#include "slider.qh"
#include "textlabel.qh"

void XonoticVideoEffectsPerspectiveSettingsTab_showNotify(entity me)
{
	loadAllCvars(me);
}
entity makeXonoticVideoEffectsPerspectiveSettingsTab()
{
	entity me = NEW(XonoticVideoEffectsPerspectiveSettingsTab);
	me.configureDialog(me);
	return me;
}

void XonoticVideoEffectsPerspectiveSettingsTab_fill(entity me)
{
	entity e;

	me.gotoRC(me, 0, (me.columns - 3) * 0.5); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 3, e = makeXonoticHeaderLabel(_("Perspective")));
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Field of view:")));
		me.TD(me, 1, 2, e = makeXonoticSlider_T(60, 130, 5, "fov", _("Field of vision in degrees")));
			e.formatString = _("%s°");

	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticRadioButton(1, "chase_active", "0", _("1st person perspective")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.8, e = makeXonoticCheckBoxEx(2, 0, "cl_eventchase_death", _("Slide to third person upon death")));
			setDependent(e, "chase_active", -1, 0);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.8, e = makeXonoticCheckBoxEx(0.05, 0, "cl_bobfall", _("Smooth the view when landing from a jump")));
			setDependent(e, "chase_active", -1, 0);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.8, e = makeXonoticCheckBoxEx(0.05, 0, "cl_smoothviewheight", _("Smooth the view while crouching")));
			setDependent(e, "chase_active", -1, 0);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.8, e = makeXonoticCheckBoxEx_T(0.01, 0, "cl_bob", _("View bobbing while walking around"), "-"));
			makeMulti(e, "cl_bob2");
			setDependent(e, "chase_active", -1, 0);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.8, e = makeXonoticCheckBoxEx(1, 0, "v_idlescale", _("View waving while idle")));
			setDependent(e, "chase_active", -1, 0);

	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticRadioButton(1, "chase_active", "1", _("3rd person perspective")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Back distance")));
			setDependent(e, "chase_active", 1, 1);
		me.TD(me, 1, 1.8, e = makeXonoticSlider(10, 100, 1, "chase_back"));
			e.formatString = _("%s qu");
			setDependent(e, "chase_active", 1, 1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Up distance")));
			setDependent(e, "chase_active", 1, 1);
		me.TD(me, 1, 1.8, e = makeXonoticSlider(10, 50, 1, "chase_up"));
			e.formatString = _("%s qu");
			setDependent(e, "chase_active", 1, 1);

	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(1, "cl_clippedspectating", _("Allow passing through walls while spectating")));
			e.sendCvars = true;	
}
