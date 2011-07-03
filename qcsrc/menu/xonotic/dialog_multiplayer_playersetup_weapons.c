#ifdef INTERFACE
CLASS(XonoticWeaponsDialog) EXTENDS(XonoticDialog)
	METHOD(XonoticWeaponsDialog, toString, string(entity))
	METHOD(XonoticWeaponsDialog, fill, void(entity))
	METHOD(XonoticWeaponsDialog, showNotify, void(entity))
	ATTRIB(XonoticWeaponsDialog, title, string, _("Weapon settings"))
	ATTRIB(XonoticWeaponsDialog, color, vector, SKINCOLOR_DIALOG_WEAPONS)
	ATTRIB(XonoticWeaponsDialog, intendedWidth, float, 0.4)
	ATTRIB(XonoticWeaponsDialog, rows, float, 18)
	ATTRIB(XonoticWeaponsDialog, columns, float, 3)
	ATTRIB(XonoticWeaponsDialog, weaponsList, entity, NULL)
ENDCLASS(XonoticWeaponsDialog)
#endif

#ifdef IMPLEMENTATION
void XonoticWeaponsDialog_showNotify(entity me)
{
        loadAllCvars(me);
}
string XonoticWeaponsDialog_toString(entity me)
{
	return me.weaponsList.toString(me.weaponsList);
}
void XonoticWeaponsDialog_fill(entity me)
{
	entity e;

	me.TR(me);
		me.TD(me, 1, 3, makeXonoticTextLabel(0, _("Weapon priority list:")));
	me.TR(me);
		me.TD(me, 10, 3, e = me.weaponsList = makeXonoticWeaponsList());
	me.gotoRC(me, 11, 0);
		me.TDempty(me, 0.5);
		me.TD(me, 1, 1, e = makeXonoticButton(_("Up"), '0 0 0'));
			e.onClick = WeaponsList_MoveUp_Click;
			e.onClickEntity = me.weaponsList;
		me.TD(me, 1, 1, e = makeXonoticButton(_("Down"), '0 0 0'));
			e.onClick = WeaponsList_MoveDown_Click;
			e.onClickEntity = me.weaponsList;
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
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "v_flipped", _("Flip view horizontally")));
	me.TR(me);
		me.TD(me, 1, me.columns, e = makeXonoticButton(_("OK"), '0 0 0'));
			e.onClick = Dialog_Close;
			e.onClickEntity = me;
}
#endif
