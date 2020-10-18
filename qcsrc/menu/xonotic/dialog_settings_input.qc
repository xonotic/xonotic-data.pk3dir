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
#include "checkbox.qh"

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
	cmd("\ndefer 0.2 \"togglemenu 1\"\n");
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
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Sensitivity:")));
		me.TD(me, 1, 2, e = makeXonoticSlider_T(1, 32, 0.2, "sensitivity",
			_("Mouse speed multiplier")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox_T(0, "m_filter", _("Smooth aiming"),
			_("Smoothes the mouse movement, but makes aiming slightly less responsive")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox_T(1.022, "m_pitch", _("Invert aiming"),
			_("Invert mouse movement on the Y-axis")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox_T(0, "menu_mouse_absolute", _("Use system mouse positioning"), "-"));
			makeMulti(e, "hud_cursormode");
			e.onClick = CheckBox_Click_Redisplay;
			e.onClickEntity = e;
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "m_accelerate", _("Enable built in mouse acceleration")));
	me.TR(me);
		if(cvar_type("vid_dgamouse") & CVAR_TYPEFLAG_ENGINE)
		{
			me.TD(me, 1, 3, e = makeXonoticCheckBox_T(0, "vid_dgamouse", _("Disable system mouse acceleration"),
				_("Make use of DGA mouse input")));
		}
		else if(cvar_type("apple_mouse_noaccel") & CVAR_TYPEFLAG_ENGINE)
			me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "apple_mouse_noaccel", _("Disable system mouse acceleration")));
		else
		{
			me.TD(me, 1, 3, e = makeXonoticCheckBox(0, string_null, _("Disable system mouse acceleration")));
			e.disabled = 1; // the option is never available in this case, just there for show
		}

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
		me.TD(me, 1, 2, e = makeXonoticTextSlider("cl_jetpack_jump"));
			e.addValue(e, ZCTX(_("JPJUMP^Disabled")), "0");
			e.addValue(e, _("Air only"), "1");
			e.addValue(e, ZCTX(_("JPJUMP^All")), "2");
			e.configureXonoticTextSliderValues(e);
			e.sendCvars = true;
	me.TR(me);
		if(cvar_type("joy_enable") & CVAR_TYPEFLAG_ENGINE)
		{
			me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "joy_enable", _("Use joystick input")));
			setDependent(e, "joy_detected", 1, 10000000);
		}
		else if(cvar_type("joystick") & CVAR_TYPEFLAG_ENGINE)
		{
			me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "joystick", _("Use joystick input")));
			setDependent(e, "joy_detected", 1, 10000000);
		}
		else
		{
			me.TD(me, 1, 3, e = makeXonoticCheckBox(0, string_null, _("Use joystick input")));
			e.disabled = 1; // the option is never available in this case, just there for show
		}
}
