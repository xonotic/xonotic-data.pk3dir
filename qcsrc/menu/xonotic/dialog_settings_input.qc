#include "dialog_settings_input.qh"

#include "dialog_settings_input_userbind.qh"
#include "dialog_settings_bindings_reset.qh"
#include "skinlist.qh"
#include "slider_resolution.qh"
#include "../item/checkbox.qh"
#include "keybinder.qh"
#include "textlabel.qh"
#include "button.qh"
#include "slider.qh"
#include "mixedslider.qh"
#include "checkbox.qh"
#include "inputbox.qh"

void updateSensSlider(entity field, entity slider)
{
	if (slider == NULL)
		return;

	// Avoid onChange causing jittering
	slider.onChangeEntity = NULL;
	slider.setValue(slider, stof(field.text), autocvar_menu_animations > 0);
	slider.onChangeEntity = field;
}

void updateSensField(entity slider, entity field)
{
	if (field == NULL)
		return;

	if (slider.value)
	{
		// Avoid onChange causing jittering
		field.onChangeEntity = NULL;
		field.setText(field, ftos_decimals(slider.value, slider.valueDigits));
		field.onChangeEntity = slider;
	}
}

void linkSensitivities(entity slider, entity field)
{
	slider.onChange = updateSensField;
	slider.onChangeEntity = field;

	field.onChange = updateSensSlider;
	field.onChangeEntity = slider;
}

entity makeXonoticInputSettingsTab()
{
	entity me;
	me = NEW(XonoticInputSettingsTab);
	me.configureDialog(me);
	return me;
}

void CheckBox_Click_Redisplay(entity me, entity checkbox)
{
	CheckBox_Click(me, checkbox);
	localcmd("\ndefer 0.2 \"togglemenu 1\"\n");
	//m_display();
}
void XonoticInputSettingsTab_fill(entity me)
{
	entity e;
	entity kb = makeXonoticKeyBinder();

	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticHeaderLabel(_("Key Bindings")));
	me.TR(me);
		me.TD(me, me.rows - 3, 3, kb);
	me.gotoRC(me, me.rows - 2, 0);
		me.TD(me, 1, 1, e = makeXonoticButton(_("Change key..."), '0 0 0'));
			e.onClick = KeyBinder_Bind_Change;
			e.onClickEntity = kb;
			kb.keyGrabButton = e;
		me.TD(me, 1, 1, e = makeXonoticButton(_("Edit..."), '0 0 0'));
			e.onClick = KeyBinder_Bind_Edit;
			e.onClickEntity = kb;
			kb.userbindEditButton = e;
			kb.userbindEditDialog = main.userbindEditDialog;
			main.userbindEditDialog.keybindBox = kb;
		me.TD(me, 1, 1, e = makeXonoticButton(_("Clear"), '0 0 0'));
			e.onClick = KeyBinder_Bind_Clear;
			e.onClickEntity = kb;
			kb.clearButton = e;
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticButton(_("Reset all"), '0 0 0'));
			e.onClick = DialogOpenButton_Click;
			e.onClickEntity = main.bindingsResetDialog;

	me.gotoRC(me, 0, 3.2); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 3, e = makeXonoticHeaderLabel(_("Mouse")));
	me.TR(me);
		entity sensitivitySlider;
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Sensitivity:")));
		me.TD(me, 1, 1, e = makeXonoticSlider_T(0.1, 9.9, 0.1, "sensitivity",
			_("Mouse speed multiplier")));
			e.setValueSpace(e, 0);
			sensitivitySlider = e;
		me.TD(me, 1, 1, e = makeXonoticInputBox_T(0, "sensitivity",
			_("Mouse speed multiplier")));
			e.saveImmediately = true;
			e.allowedCharacters = "0.123456789";
			linkSensitivities(sensitivitySlider, e);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox_T(0, "m_filter", _("Smooth aiming"),
			_("Smooths the mouse movement, but makes aiming slightly less responsive")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox_T(1.022, "m_pitch", _("Invert aiming"),
			_("Invert mouse movement on the Y-axis")));

	string m_accelerate_tooltip = _("In-game linear acceleration factor. \"Fully disabled\" also disables other acceleration types that can be enabled via the m_accelerate_* cvars");
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Acceleration factor:")));
		me.TD(me, 1, 2, e = makeXonoticMixedSlider_T("m_accelerate", m_accelerate_tooltip));
			e.setValueSpace(e, e.valueSpace * 1.25);
			e.addText(e, ZCTX(_("MOUSEACCEL^Fully disabled")), 0);
			e.addText(e, ZCTX(_("MOUSEACCEL^Linear disabled")), 1);
			e.addRange(e, 1.2, 4, 0.2);
			e.configureXonoticMixedSliderValues(e);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Speed bounds:")));
			setDependent(e, "m_accelerate", 1, 0);
		me.TD(me, 1, 1, e = makeXonoticSlider_T(0, 10000, 500, "m_accelerate_minspeed",
			m_accelerate_tooltip));
			setDependent(e, "m_accelerate", 1, 0);
		me.TD(me, 1, 1, e = makeXonoticSlider_T(5000, 20000, 1000, "m_accelerate_maxspeed",
			m_accelerate_tooltip));
			setDependent(e, "m_accelerate", 1, 0);
	me.TR(me);
		me.TDempty(me, 0.2);
		if(cvar_type("vid_dgamouse") & CVAR_TYPEFLAG_ENGINE)
		{
			me.TD(me, 1, 2.8, e = makeXonoticCheckBox_T(0, "vid_dgamouse", _("Disable system mouse acceleration"),
				_("Make use of DGA mouse input")));
		}
		else if(cvar_type("apple_mouse_noaccel") & CVAR_TYPEFLAG_ENGINE)
			me.TD(me, 1, 2.8, e = makeXonoticCheckBox(0, "apple_mouse_noaccel", _("Disable system mouse acceleration")));
		else
		{
			me.TD(me, 1, 2.8, e = makeXonoticCheckBox(0, string_null, _("Disable system mouse acceleration")));
			e.disabled = 1; // the option is never available in this case, just there for show
		}
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox_T(0, "menu_mouse_absolute", _("Use system mouse positioning"), "-"));
			makeMulti(e, "hud_cursormode");
			e.onClick = CheckBox_Click_Redisplay;
			e.onClickEntity = e;

	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticHeaderLabel(_("Other")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox_T(0, "con_closeontoggleconsole", _("Pressing \"enter console\" key also closes it"),
			_("Allow the console toggling bind to also close the console")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(1, "cl_movement_track_canjump", _("Automatically repeat jumping if holding jump")));
			e.sendCvars = true;
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Jetpack on jump:")));
		me.TD(me, 1, 2, e = makeXonoticMixedSlider("cl_jetpack_jump"));
			e.addText(e, ZCTX(_("JPJUMP^Disabled")), 0);
			e.addText(e, _("Air only"), 1);
			e.addText(e, ZCTX(_("JPJUMP^All")), 2);
			e.configureXonoticMixedSliderValues(e);
			e.sendCvars = true;
	me.TR(me);
		if(cvar_type("joy_enable") & CVAR_TYPEFLAG_ENGINE)
		{
			me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "joy_enable", _("Use joystick input")));
				setDependentNOT(e, "joy_detected", 0);
		}
		else if(cvar_type("joystick") & CVAR_TYPEFLAG_ENGINE)
		{
			me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "joystick", _("Use joystick input")));
				setDependentNOT(e, "joy_detected", 0);
		}
		else
		{
			me.TD(me, 1, 3, e = makeXonoticCheckBox(0, string_null, _("Use joystick input")));
				e.disabled = 1; // the option is never available in this case, just there for show
		}
}
