#ifdef INTERFACE
CLASS(XonoticMonsterToolsDialog) EXTENDS(XonoticRootDialog)
	METHOD(XonoticMonsterToolsDialog, fill, void(entity)) // to be overridden by user to fill the dialog with controls
	ATTRIB(XonoticMonsterToolsDialog, title, string, _("Monster Tools"))
	ATTRIB(XonoticMonsterToolsDialog, color, vector, SKINCOLOR_DIALOG_SANDBOXTOOLS)
	ATTRIB(XonoticMonsterToolsDialog, intendedWidth, float, 0.8)
	ATTRIB(XonoticMonsterToolsDialog, rows, float, 16)
	ATTRIB(XonoticMonsterToolsDialog, columns, float, 4)
	ATTRIB(XonoticMonsterToolsDialog, name, string, "MonsterTools")
ENDCLASS(XonoticMonsterToolsDialog)
#endif

#ifdef IMPLEMENTATION
void XonoticMonsterToolsDialog_fill(entity me)
{
	entity e, box;

	me.TR(me);
		me.TD(me, 1, 0.25, e = makeXonoticTextLabel(0, _("Monster:")));
		me.TD(me, 1, 1.5, box = makeXonoticInputBox(1, "menu_monsters_spawn_monster"));
			box.forbiddenCharacters = "\r\n\\\"$"; // don't care, isn't getting saved
			box.maxLength = -127; // negative means encoded length in bytes
			box.saveImmediately = 1;
		me.TD(me, 1, 0.25, e = makeXonoticTextLabel(0, _("Name:")));
		me.TD(me, 1, 1.5, box = makeXonoticInputBox(1, "menu_monsters_edit_name"));
			box.forbiddenCharacters = "\r\n\\\"$"; // don't care, isn't getting saved
			box.maxLength = -127; // negative means encoded length in bytes
			box.saveImmediately = 1;
		me.TR(me);
		me.TDempty(me, 0.5);
		me.TD(me, 1, 0.5, e = makeXonoticCommandButton(_("Spawn"), '0 0 0', "cmd mobspawn $menu_monsters_spawn_monster $menu_monsters_edit_movetarget \"$menu_monsters_edit_name\"", 0));
		me.TD(me, 1, 0.5, e = makeXonoticCommandButton(_("Remove"), '0 0 0', "cmd mobkill", 0));
		me.TD(me, 1, 0.5, e = makeXonoticCommandButton(_("Change name"), '0 0 0', "editmob name \"$menu_monsters_edit_name\"", 0));
	me.TR(me);
		me.TD(me, 1, 0.5, e = makeXonoticCommandButton(_("Move target:"), '0 0 0', "editmob movetarget $menu_monsters_edit_movetarget", 0));
		me.TD(me, 1, 0.5, e = makeXonoticRadioButton(2, "menu_monsters_edit_movetarget", "1", _("Follow")));
		me.TD(me, 1, 0.5, e = makeXonoticRadioButton(2, "menu_monsters_edit_movetarget", "2", _("Wander")));
		me.TD(me, 1, 0.5, e = makeXonoticRadioButton(2, "menu_monsters_edit_movetarget", "3", _("Spawnpoint")));
		me.TD(me, 1, 0.5, e = makeXonoticRadioButton(2, "menu_monsters_edit_movetarget", "4", _("No moving")));
	me.TR(me);
	me.TD(me, 1, 1.5, e = makeXonoticTextLabel(0, _("Colors:")));
	me.TR(me);
		me.TD(me, 1, 0.5, e = makeXonoticCommandButton(_("Set skin:"), '0 0 0', "editmob skin $menu_monsters_edit_skin", 0));
		me.TD(me, 1, 1.5, e = makeXonoticSlider(0, 99, 1, "menu_monsters_edit_skin"));
	me.TR(me);
		me.TD(me, 1, 0.5, e = makeXonoticCommandButton(_("Set color:"), '0 0 0', "editmob color \"$menu_monsters_edit_color\"", 0));
		me.TD(me, 2, 1.5, e = makeXonoticColorpickerString("menu_monsters_edit_color", "menu_monsters_edit_color"));
	me.TR(me);

	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, e = makeXonoticButton(_("OK"), '0 0 0'));
			e.onClick = Dialog_Close;
			e.onClickEntity = me;
}
#endif

/* Click. The c-word is here so you can grep for it :-) */
