#ifdef INTERFACE
CLASS(XonoticGameWeaponsSettingsTab) EXTENDS(XonoticTab)
	//METHOD(XonoticGameWeaponsSettingsTab, toString, string(entity))
	METHOD(XonoticGameWeaponsSettingsTab, fill, void(entity))
	METHOD(XonoticGameWeaponsSettingsTab, showNotify, void(entity))
	ATTRIB(XonoticGameWeaponsSettingsTab, title, string, _("Weapons"))
	ATTRIB(XonoticGameWeaponsSettingsTab, intendedWidth, float, 0.9)
	ATTRIB(XonoticGameWeaponsSettingsTab, rows, float, 13)
	ATTRIB(XonoticGameWeaponsSettingsTab, columns, float, 6)
	ATTRIB(XonoticGameWeaponsSettingsTab, weaponsList, entity, NULL)
ENDCLASS(XonoticGameWeaponsSettingsTab)
entity makeXonoticGameWeaponsSettingsTab();
#endif

#ifdef IMPLEMENTATION
void XonoticGameWeaponsSettingsTab_showNotify(entity me)
{
	loadAllCvars(me);
}
entity makeXonoticGameWeaponsSettingsTab()
{
	entity me;
	me = spawnXonoticGameWeaponsSettingsTab();
	me.configureDialog(me);
	return me;
}

void XonoticGameWeaponsSettingsTab_fill(entity me)
{
	entity e;

	me.TR(me);
		me.TDempty(me, 0.25);
		me.TD(me, 1, 2.5, e = makeXonoticHeaderLabel(_("Weapon Priority List")));
	me.TR(me);
		me.TDempty(me, 0.25);
		me.TD(me, 10, 2.5, e = me.weaponsList = makeXonoticWeaponsList());
	me.gotoRC(me, 11, 0.25);
		me.TD(me, 1, 1.25, e = makeXonoticButton(_("Up"), '0 0 0'));
			e.onClick = WeaponsList_MoveUp_Click;
			e.onClickEntity = me.weaponsList;
		me.TD(me, 1, 1.25, e = makeXonoticButton(_("Down"), '0 0 0'));
			e.onClick = WeaponsList_MoveDown_Click;
			e.onClickEntity = me.weaponsList;

	me.gotoRC(me, 0, 3); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "cl_weaponpriority_useforcycling", _("Use priority list for weapon cycling")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(1, "cl_weaponimpulsemode", _("Cycle through only usable weapon selections")));
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "cl_autoswitch", _("Auto switch weapons on pickup")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "cl_unpress_attack_on_weapon_switch", _("Release attack buttons when you switch weapons")));
	me.TR(me);
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
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.8, e = makeXonoticCheckBox(0, "cl_followmodel", _("Gun model swaying")));
		makeMulti(e, "cl_leanmodel");
		setDependent(e, "r_drawviewmodel", 1, 1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.8, e = makeXonoticCheckBox(0, "cl_bobmodel", _("Gun model bobbing")));
		setDependent(e, "r_drawviewmodel", 1, 1);
}
#endif
