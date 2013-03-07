#ifdef INTERFACE
CLASS(XonoticTowerDefenseDialog) EXTENDS(XonoticRootDialog)
	METHOD(XonoticTowerDefenseDialog, fill, void(entity)) // to be overridden by user to fill the dialog with controls
	ATTRIB(XonoticTowerDefenseDialog, title, string, _("Tower Defense Control Panel"))
	ATTRIB(XonoticTowerDefenseDialog, color, vector, SKINCOLOR_DIALOG_SANDBOXTOOLS)
	ATTRIB(XonoticTowerDefenseDialog, intendedWidth, float, 0.8)
	ATTRIB(XonoticTowerDefenseDialog, rows, float, 4)
	ATTRIB(XonoticTowerDefenseDialog, columns, float, 2)
	ATTRIB(XonoticTowerDefenseDialog, name, string, "TowerDefense")
ENDCLASS(XonoticTowerDefenseDialog)
#endif

#ifdef IMPLEMENTATION
void XonoticTowerDefenseDialog_fill(entity me)
{
	entity e;

	me.TR(me);
		me.TD(me, 1, 0.5, e = makeXonoticTextLabel(0, _("Turret:")));
	me.TR(me);
		me.TD(me, 1, 0.2, e = makeXonoticRadioButton(2, "menu_td_edit_spawn", "plasma", _("Plasma")));
		me.TD(me, 1, 0.2, e = makeXonoticRadioButton(2, "menu_td_edit_spawn", "mlrs", _("MLRS")));
		me.TD(me, 1, 0.2, e = makeXonoticRadioButton(2, "menu_td_edit_spawn", "flac", _("FLAC")));
		me.TD(me, 1, 0.2, e = makeXonoticRadioButton(2, "menu_td_edit_spawn", "barricade", _("Barricade")));
		me.TD(me, 1, 0.2, e = makeXonoticRadioButton(2, "menu_td_edit_spawn", "walker", _("Walker")));
		me.TR(me);
		me.TDempty(me, 0.5);
		me.TD(me, 1, 0.5, e = makeXonoticCommandButton(_("Spawn"), '0 0 0', "spawnturret $menu_td_edit_spawn", 0));
		me.TD(me, 1, 0.5, e = makeXonoticCommandButton(_("Remove"), '0 0 0', "rmturret", 0));
	me.TR(me);

	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, e = makeXonoticButton(_("OK"), '0 0 0'));
			e.onClick = Dialog_Close;
			e.onClickEntity = me;
}
#endif

/* Click. The c-word is here so you can grep for it :-) */
