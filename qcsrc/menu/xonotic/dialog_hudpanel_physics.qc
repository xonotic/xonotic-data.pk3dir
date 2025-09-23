#include "dialog_hudpanel_physics.qh"

#include "textlabel.qh"
#include "mixedslider.qh"
#include "checkbox.qh"
#include "slider.qh"
#include "radiobutton.qh"

void XonoticHUDPhysicsDialog_fill(entity me)
{
	entity e;
	string panelname = "physics";

	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticMixedSlider("hud_panel_physics"));
			e.setValueSpace(e, e.valueSpace * 1.2);
			e.addText(e, _("Disable"), 0);
			e.addText(e, _("Enable"), 1);
			e.addText(e, _("Enable even observing"), 2);
			e.addText(e, _("Enable only in Race/CTS"), 3);
			e.configureXonoticMixedSliderValues(e);

	dialog_hudpanel_main_settings(me, panelname);

	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticCheckBox(0, "hud_panel_physics_flip", _("Flip speed/acceleration positions")));
	me.TR(me);
		me.TD(me, 1, 1.4, e = makeXonoticTextLabel(0, _("Status bar")));
		me.TD(me, 1, 2.6, e = makeXonoticMixedSlider("hud_panel_physics_progressbar"));
			e.addText(e, _("None"),         0);
			e.addText(e, _("Speed"),        2);
			e.addText(e, _("Acceleration"), 3);
			e.addText(e, _("Both"),         1);
			e.configureXonoticMixedSliderValues(e);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 3.8, e = makeXonoticTextLabel(0, _("Status bar alignment:")));
			setDependent(e, "hud_panel_physics_progressbar", 1, 3);
	me.TR(me);
		me.TDempty(me, 0.4);
		me.TD(me, 1, 3.6/4, e = makeXonoticRadioButton(2, "hud_panel_physics_baralign", "0", _("Left")));
			setDependent(e, "hud_panel_physics_progressbar", 1, 3);
		me.TD(me, 1, 3.6/4, e = makeXonoticRadioButton(2, "hud_panel_physics_baralign", "1", _("Right")));
			setDependent(e, "hud_panel_physics_progressbar", 1, 3);
		me.TD(me, 1, 3.6/4, e = makeXonoticRadioButton(2, "hud_panel_physics_baralign", "2", _("Inward")));
			setDependent(e, "hud_panel_physics_progressbar", 1, 3);
		me.TD(me, 1, 3.6/4, e = makeXonoticRadioButton(2, "hud_panel_physics_baralign", "3", _("Outward")));
			setDependent(e, "hud_panel_physics_progressbar", 1, 3);

//speed
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Speed:")));
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "hud_panel_physics_speed_vertical", _("Include vertical speed")));
	// me.TR(me);
		// me.TDempty(me, 0.2);
		// me.TD(me, 1, 1.8, e = makeXonoticTextLabel(0, _("Full status bar at:")));
			// setDependent(e, "hud_panel_physics_progressbar", 1, 1);
		// me.TD(me, 1, 1, e = makeXonoticInputBox(1, "hud_panel_physics_speed_max"));
			// setDependent(e, "hud_panel_physics_progressbar", 1, 1);
		// me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("qu/s")));
			// setDependent(e, "hud_panel_physics_progressbar", 1, 1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 3.8/2, e = makeXonoticCheckBox(0, "hud_panel_physics_topspeed", _("Top speed")));
		me.TD(me, 1, 3.8/2, e = makeXonoticSlider(0.5, 5, 0.5, "hud_panel_physics_topspeed_time"));
			e.formatString = "S";
			e.setValueSpace(e, e.valueSpace * 1.5);
			setDependent(e, "hud_panel_physics_topspeed", 1, 1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 3.8/2, e = makeXonoticCheckBox(0, "hud_panel_physics_jumpspeed", _("Jump speed")));
		me.TD(me, 1, 3.8/2, e = makeXonoticSlider(0.5, 5, 0.5, "hud_panel_physics_jumpspeed_time"));
			e.formatString = "S";
			e.setValueSpace(e, e.valueSpace * 1.5);
			setDependent(e, "hud_panel_physics_jumpspeed", 1, 1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 3.8, e = makeXonoticCheckBox(0, "hud_panel_physics_speed_unit_show", _("Show speed unit")));
			setDependent(e, "hud_panel_physics_topspeed", 0, 0);
			setDependentOR(e, "hud_panel_physics_jumpspeed", 0, 0);

//acceleration
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Acceleration:")));
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "hud_panel_physics_acceleration_vertical", _("Include vertical acceleration")));
	// me.TR(me);
		// me.TDempty(me, 0.2);
		// me.TD(me, 1, 1.8, e = makeXonoticTextLabel(0, _("Full status bar at:")));
			// setDependent(e, "hud_panel_physics_progressbar", 1, 1);
		// me.TD(me, 1, 0.6, e = makeXonoticInputBox(1, "hud_panel_physics_acceleration_max"));
			// setDependent(e, "hud_panel_physics_progressbar", 1, 1);
}
