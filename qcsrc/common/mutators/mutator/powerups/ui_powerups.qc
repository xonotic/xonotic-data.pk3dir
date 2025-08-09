#include "ui_powerups.qh"

#include "powerups.qh"

#include <menu/xonotic/checkbox.qh>
#include <menu/xonotic/radiobutton.qh>
#include <menu/xonotic/textlabel.qh>

entity makeXonoticMutatorPowerupsTab()
{
	entity me = NEW(XonoticMutatorPowerupsTab);
	me.configureDialog(me);
	return me;
}

void MutatorPowerupsReplace_CheckBox_saveCvars(entity me)
{
	XonoticCheckBox_saveCvars(me);
	entity e;
	for (int i = 0; i < me.parent.cnt; ++i) // reload cvars for the RadioButtons
	{
		e = me.parent.(toggleableItems[i]);
		e.loadCvars(e);
	}
}

void XonoticMutatorPowerupsTab_fill(entity me)
{
	entity e;

	me.TR(me);
		me.TD(me, 1, 4 * 0.3, e = makeXonoticRadioButton(1, me.message, "0",  _("Disable")));
			Mutators_add_RadioButton(me, e);
		me.TD(me, 1, 4 * 0.4, e = makeXonoticRadioButton(1, me.message, "-1", _("Dependent on gametype")));
			Mutators_add_RadioButton(me, e);
		me.TD(me, 1, 4 * 0.3, e = makeXonoticRadioButton(1, me.message, "1",  _("Always enable")));
			Mutators_add_RadioButton(me, e);

	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticTextLabel(0, _("Allow maps to spawn:")));
		string name;
		int cols = 3;
		int j = 0;
		FOREACH(Items, it.instanceOfPowerup && it.netname != "extralife",
		{
			if (j % cols == 0)
			{
				me.TR(me);
				me.TDempty(me, 0.2);
			}
			switch (it.netname) // TODO: rename the cvars, or change the .netname
			{
				case "fuel_regen":
					name = "fuelregen";
					break;
				case "invincible":
					name = "shield";
					break;
				default:
					name = it.netname;
					break;
			}
			me.TD(me, 1, (4 - 0.2) / cols, e = makeXonoticCheckBox(0, strzone(strcat("g_powerups_", name)), strzone(it.m_name)));
			++j;
		});

	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticTextLabel(0, _("Drop on death")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, (4 - 0.2) / 3, e = makeXonoticRadioButton(2, "g_powerups_drop_ondeath", "0", _("Disabled")));
		me.TD(me, 1, (4 - 0.2) / 3, e = makeXonoticRadioButton(2, "g_powerups_drop_ondeath", "1", _("Timer continues")));
		me.TD(me, 1, (4 - 0.2) / 3, e = makeXonoticRadioButton(2, "g_powerups_drop_ondeath", "2", _("Timer pauses")));
	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticTextLabel(0, _("Allow dropping")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, (4 - 0.2) / 3, e = makeXonoticRadioButton(3, "g_powerups_drop", "0", _("Disabled")));
		me.TD(me, 1, (4 - 0.2) / 3, e = makeXonoticRadioButton(3, "g_powerups_drop", "1", _("Timer continues")));
		me.TD(me, 1, (4 - 0.2) / 3, e = makeXonoticRadioButton(3, "g_powerups_drop", "2", _("Timer pauses")));

	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticCheckBox(0, "g_buffs_replace_powerups", _("Replace powerups with buffs")));
			e.saveCvars = MutatorPowerupsReplace_CheckBox_saveCvars;
			setDependent(e, "g_buffs", 1, 1);
}

#include "powerup/invisibility.qh"
#include "powerup/strength.qh"

METHOD(XonoticMutatorPowerupsTab, describe, string(XonoticMutatorPowerupsTab me))
{
	return sprintf(_("Enable powerup pickups (powerful bonuses like %s and %s) on the maps that support them."), COLORED_NAME(ITEM_Strength), COLORED_NAME(ITEM_Invisibility));
}
METHOD(XonoticMutatorPowerupsTab, canEnable, bool(XonoticMutatorPowerupsTab me, bool is_already_enabled))
{
	bool can_enable = !(cvar("g_buffs") == 1 && cvar("g_buffs_replace_powerups"));
	if (is_already_enabled)
		return can_enable && cvar(me.message);
	return can_enable;
}
