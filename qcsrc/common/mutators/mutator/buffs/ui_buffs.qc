#include "ui_buffs.qh"

#include "buffs.qh"

#include <menu/xonotic/checkbox.qh>
#include <menu/xonotic/textlabel.qh>

entity makeXonoticMutatorBuffsTab()
{
	entity me = NEW(XonoticMutatorBuffsTab);
	me.configureDialog(me);
	return me;
}

void XonoticMutatorBuffsTab_fill(entity me)
{
	entity e;

	me.TR(me);
		me.TD(me, 1, 4 * 0.25, e = makeXonoticRadioButton(1, me.message, "0",  _("Disable")));
			Mutators_add_RadioButton(me, e);
		me.TD(me, 1, 4 * 0.5,  e = makeXonoticRadioButton(1, me.message, "-1", _("Enable only if placed by mapper")));
			Mutators_add_RadioButton(me, e);
		me.TD(me, 1, 4 * 0.25, e = makeXonoticRadioButton(1, me.message, "1",  _("Enable")));
			Mutators_add_RadioButton(me, e);

	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticTextLabel(0, _("Allow maps to spawn:")));
		int cols = 3;
		int j = 0;
		FOREACH(StatusEffects, it.instanceOfBuff,
		{
			if (j % cols == 0)
			{
				me.TR(me);
				me.TDempty(me, 0.2);
			}
			me.TD(me, 1, (4 - 0.2) / cols, e = makeXonoticCheckBox(0, strzone(strcat("g_buffs_", it.netname)), strzone(it.m_name)));
			++j;
		});
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 4 - 0.2, e = makeXonoticCheckBox(0, "g_buffs_replace_available", _("Replace unavailable buffs with others")));

	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticCheckBox(0, "g_buffs_drop", _("Allow dropping")));
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticCheckBox(0, "g_buffs_replace_powerups", _("Replace powerups with buffs")));
			setDependent(e, me.message, 1, 1);
}

#include <common/mutators/mutator/buffs/buff/medic.qh>
#include <common/mutators/mutator/buffs/buff/resistance.qh>

METHOD(XonoticMutatorBuffsTab, describe, string(XonoticMutatorBuffsTab me))
{
	return sprintf(_("Enable buff pickups (random bonuses like %s and %s) on the maps that support them."), COLORED_NAME(BUFF_MEDIC), COLORED_NAME(BUFF_RESISTANCE));
}
METHOD(XonoticMutatorBuffsTab, canEnable, bool(XonoticMutatorBuffsTab me, bool is_already_enabled))
{
	bool can_enable = true;
	if (is_already_enabled)
		return can_enable && cvar(me.message);
	return can_enable;
}
