#include "dialog_monstertools.qh"

#include "textlabel.qh"
#include "radiobutton.qh"
#include "commandbutton.qh"
#include "slider.qh"

void XonoticMonsterToolsDialog_fill(entity me)
{
	entity e;

	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticTextLabel(0, _("Monster:")));
	me.TR(me);
		me.TD(me, 1, 4/5, e = makeXonoticRadioButton(2, "menu_monsters_edit_spawn", "zombie", _("Zombie")));
		me.TD(me, 1, 4/5, e = makeXonoticRadioButton(2, "menu_monsters_edit_spawn", "spider", _("Spider")));
		me.TD(me, 1, 4/5, e = makeXonoticRadioButton(2, "menu_monsters_edit_spawn", "golem", _("Golem")));
		me.TD(me, 1, 4/5, e = makeXonoticRadioButton(2, "menu_monsters_edit_spawn", "mage", _("Mage")));
		me.TD(me, 1, 4/5, e = makeXonoticRadioButton(2, "menu_monsters_edit_spawn", "wyvern", _("Wyvern")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.75, e = makeXonoticCommandButton(_("Spawn"), '0 0 0', "spawnmob $menu_monsters_edit_spawn $menu_monsters_edit_movetarget", 0));
		me.TD(me, 1, 0.75, e = makeXonoticCommandButton(_("Remove"), '0 0 0', "killmob", 0));
	me.TR(me);
		me.TD(me, 1, 0.75, e = makeXonoticCommandButton(_("Move target:"), '0 0 0', "editmob movetarget $menu_monsters_edit_movetarget", 0));
		me.TD(me, 1, 3.25/4, e = makeXonoticRadioButton(3, "menu_monsters_edit_movetarget", "1", _("Follow")));
		me.TD(me, 1, 3.25/4, e = makeXonoticRadioButton(3, "menu_monsters_edit_movetarget", "2", _("Wander")));
		me.TD(me, 1, 3.25/4, e = makeXonoticRadioButton(3, "menu_monsters_edit_movetarget", "3", _("Spawnpoint")));
		me.TD(me, 1, 3.25/4, e = makeXonoticRadioButton(3, "menu_monsters_edit_movetarget", "4", _("No moving")));
	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticTextLabel(0, _("Colors:")));
	me.TR(me);
		me.TD(me, 1, 0.75, e = makeXonoticCommandButton(_("Set skin:"), '0 0 0', "editmob skin $menu_monsters_edit_skin", 0));
		me.TD(me, 1, 1.25, e = makeXonoticSlider(0, 99, 1, "menu_monsters_edit_skin"));

	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, e = makeXonoticButton(_("OK"), '0 0 0'));
			e.onClick = Dialog_Close;
			e.onClickEntity = me;
}
