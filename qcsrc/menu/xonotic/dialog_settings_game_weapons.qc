#include "dialog_settings_game_weapons.qh"

#include "weaponslist.qh"
#include "commandbutton.qh"
#include "textlabel.qh"
#include "slider.qh"
#include "mixedslider.qh"
#include "checkbox.qh"
#include "button.qh"
#include "radiobutton.qh"

void XonoticGameWeaponsSettingsTab_showNotify(entity me)
{
	loadAllCvars(me);
}
entity makeXonoticGameWeaponsSettingsTab()
{
	entity me;
	me = NEW(XonoticGameWeaponsSettingsTab);
	me.configureDialog(me);
	return me;
}

void XonoticGameWeaponsSettingsTab_fill(entity me)
{
	entity e;
	entity weaponsApplyButton = makeXonoticCommandButton(_("Apply immediately"), '0 0 0',
		"sendcvar cl_weaponpriority"
		, COMMANDBUTTON_APPLY);
	weaponsApplyButton.disableOnClick = true;

	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticHeaderLabel(_("Weapon Priority List (* = mutator weapon)")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 9, 2.6, e = me.weaponsList = makeXonoticWeaponsList());
			e.applyButton = weaponsApplyButton;
	me.gotoRC(me, 10, 0.2);
		me.TD(me, 1, 2.6/2, e = makeXonoticButton(_("Up"), '0 0 0'));
			e.onClick = WeaponsList_MoveUp_Click;
			e.onClickEntity = me.weaponsList;
			e.applyButton = weaponsApplyButton;
		me.TD(me, 1, 2.6/2, e = makeXonoticButton(_("Down"), '0 0 0'));
			e.onClick = WeaponsList_MoveDown_Click;
			e.onClickEntity = me.weaponsList;
			e.applyButton = weaponsApplyButton;
	me.TR(me);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.8, e = makeXonoticCheckBox_T(0, "cl_weaponpriority_useforcycling", _("Use priority list for weapon cycling"),
			_("Make use of the list above when cycling through weapons with the mouse wheel")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.8, e = makeXonoticCheckBox(1, "cl_weaponimpulsemode", _("Cycle through only usable weapon selections")));
			e.sendCvars = true;

	me.gotoRC(me, 0, 3); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 3, e = makeXonoticHeaderLabel(_("Weapon Options")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "cl_unpress_attack_on_weapon_switch", _("Release attack buttons when you switch weapons")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox_T(0, "cl_autoswitch", _("Auto switch weapons on pickup"),
			_("Automatically switch to newly picked up weapons if they are better than what you are carrying")));
			e.sendCvars = true;
	me.TR(me);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Auto switch in CTS:")));
		me.TD(me, 1, 1.8, e = makeXonoticMixedSlider("cl_autoswitch_cts"));
			e.addText(e, _("Never"), 0);
			e.addText(e, _("Default"), -1);
			e.addText(e, _("Always"), 1);
			e.configureXonoticMixedSliderValues(e);
			e.sendCvars = true;

	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticHeaderLabel(_("Weapon Visuals")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox_T(0, "r_drawviewmodel", _("Draw 1st person weapon model"),
			_("Draw the weapon model")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.8/3, e = makeXonoticRadioButton_T(1, "cl_gunalign", "4", _("Left align"),
			_("Position of the weapon model; requires reconnect")));
			setDependentNOT(e, "cl_viewmodel_alpha", 0);
			setDependentAND(e, "r_drawviewmodel", 1, 1);
		me.TD(me, 1, 2.8/3, e = makeXonoticRadioButton_T(1, "cl_gunalign", "1", _("Center"),
			_("Position of the weapon model; requires reconnect")));
			setDependentNOT(e, "cl_viewmodel_alpha", 0);
			setDependentAND(e, "r_drawviewmodel", 1, 1);
		me.TD(me, 1, 2.8/3, e = makeXonoticRadioButton_T(1, "cl_gunalign", "3", _("Right align"),
			_("Position of the weapon model; requires reconnect")));
			setDependentNOT(e, "cl_viewmodel_alpha", 0);
			setDependentAND(e, "r_drawviewmodel", 1, 1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.8/2, e = makeXonoticCheckBox_T(0, "cl_followmodel", _("Gun model swaying"), "-"));
			makeMulti(e, "cl_leanmodel");
			setDependentNOT(e, "cl_viewmodel_alpha", 0);
			setDependentAND(e, "r_drawviewmodel", 1, 1);
		me.TD(me, 1, 2.8/2, e = makeXonoticCheckBox(0, "cl_bobmodel", _("Gun model bobbing")));
			setDependentNOT(e, "cl_viewmodel_alpha", 0);
			setDependentAND(e, "r_drawviewmodel", 1, 1);
	me.TR(me);
			me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Weapon model opacity:")));
				setDependent(e, "r_drawviewmodel", 1, 1);
			me.TD(me, 1, 1.8, e = makeXonoticSlider(0.05, 1, 0.05, "cl_viewmodel_alpha"));
				e.formatString = "%";
				setDependent(e, "r_drawviewmodel", 1, 1);

	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticTextLabel(0, _("Apply team colors to weapon beam effects:")));
	me.TR(me);
		me.TDempty(me, 0.2);
			me.TD(me, 1, 2.8/3, e = makeXonoticRadioButton(1, "cl_tracers_teamcolor", "0", _("Never")));
			me.TD(me, 1, 2.8/3, e = makeXonoticRadioButton(1, "cl_tracers_teamcolor", "1", _("In team games")));
			me.TD(me, 1, 2.8/3, e = makeXonoticRadioButton(1, "cl_tracers_teamcolor", "2", _("Always")));

	me.gotoRC(me, me.rows - 1, 0); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, me.columns, weaponsApplyButton);
}
