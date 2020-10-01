#include "dialog_settings_game_weapons.qh"

#include "weaponslist.qh"
#include "commandbutton.qh"
#include "textlabel.qh"
#include "textslider.qh"
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
		"sendcvar cl_weaponpriority;"
		, COMMANDBUTTON_APPLY);
	weaponsApplyButton.disableOnClick = true;

	me.TR(me);
		me.TDempty(me, 0.25);
		me.TD(me, 1, 2.5, e = makeXonoticHeaderLabel(_("Weapon Priority List (* = mutator weapon)")));
	me.TR(me);
		me.TDempty(me, 0.25);
		me.TD(me, 9, 2.5, e = me.weaponsList = makeXonoticWeaponsList());
			e.applyButton = weaponsApplyButton;
	me.gotoRC(me, 10, 0.25);
		me.TD(me, 1, 1.25, e = makeXonoticButton(_("Up"), '0 0 0'));
			e.onClick = WeaponsList_MoveUp_Click;
			e.onClickEntity = me.weaponsList;
			e.applyButton = weaponsApplyButton;
		me.TD(me, 1, 1.25, e = makeXonoticButton(_("Down"), '0 0 0'));
			e.onClick = WeaponsList_MoveDown_Click;
			e.onClickEntity = me.weaponsList;
			e.applyButton = weaponsApplyButton;

	me.gotoRC(me, 0, 3); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 3, e = makeXonoticCheckBox_T(0, "cl_weaponpriority_useforcycling", _("Use priority list for weapon cycling"),
			_("Make use of the list above when cycling through weapons with the mouse wheel")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(1, "cl_weaponimpulsemode", _("Cycle through only usable weapon selections")));
			e.sendCvars = true;
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox_T(0, "cl_autoswitch", _("Auto switch weapons on pickup"),
			_("Automatically switch to newly picked up weapons if they are better than what you are carrying")));
			e.sendCvars = true;
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "cl_unpress_attack_on_weapon_switch", _("Release attack buttons when you switch weapons")));

	me.gotoRC(me, me.rows - 1, 0); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, me.columns, weaponsApplyButton);
}
