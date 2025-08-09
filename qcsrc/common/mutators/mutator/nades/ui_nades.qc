#include "ui_nades.qh"

#include "nades.qh"

#include <menu/xonotic/checkbox.qh>
#include <menu/xonotic/slider.qh>
#include <menu/xonotic/radiobutton.qh>
#include <menu/xonotic/textlabel.qh>

entity makeXonoticMutatorNadesTab()
{
	entity me = NEW(XonoticMutatorNadesTab);
	me.configureDialog(me);
	return me;
}

void XonoticMutatorNadesTab_fill(entity me)
{
	entity e;

	Mutators_main_checkbox(me);

	me.TR(me);
		me.TD(me, 1, 2, e = makeXonoticCheckBox_T(0, "g_nades_bonus", _("Enable bonus nades"),
			_("Gives players a bonus grenade when they reach a certain score or have Strength")));
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Max bonus nades:")));
			setDependentNOT(e, "g_nades_bonus", 0);
		me.TD(me, 1, 0.8, e = makeXonoticSlider(1, 10, 1, "g_nades_bonus_max"));
			e.setValueSpace(e, e.valueSpace * 1.2);
			setDependentNOT(e, "g_nades_bonus", 0);
	me.TR(me);
		me.TD(me, 1, 2, e = makeXonoticCheckBox(0, "g_nades_client_select", _("Allow client selection")));
		me.TD(me, 1, 2, e = makeXonoticCheckBox(0, "g_nades_bonus_client_select", _("For bonus nades")));
			setDependentNOT(e, "g_nades_bonus", 0);
	me.TR(me);
		me.TD(me, 1, 2, e = makeXonoticTextLabel(0, _("Refire time:")));
		me.TD(me, 1, 2, e = makeXonoticSlider(1, 20, 1, "g_nades_nade_refire"));
			e.formatString = "s";
			e.setValueSpace(e, e.valueSpace * 1.2);

	me.TR(me);
		me.TD(me, 1, 4 / 2 - 0.2 * 3, e = makeXonoticTextLabel(0, _("Nade types:")));
		me.TD(me, 1, 0.2, e = makeXonoticTextLabel(0, "1"));
			e.marginLeft = 0.4; // improve text alignment with icons
			setDependent(e, "g_nades_client_select", 0, 0);
		me.TD(me, 1, 0.2, e = makeXonoticTextLabel(0, "2"));
			e.marginLeft = 0.4;
			setDependentNOT(e, "g_nades_bonus", 0);
			setDependentAND(e, "g_nades_bonus_client_select", 0, 0);
		me.TD(me, 1, 0.2, e = makeXonoticTextLabel(0, "3"));
			e.marginLeft = 0.4;
			setDependent(e, "g_nades_client_select", 1, 1);
			setDependentOR(e, "g_nades_bonus_client_select", 1, 1);
		me.TDempty(me, 4 / 2 - 0.2 * 3);
		me.TD(me, 1, 0.2, e = makeXonoticTextLabel(0, "1"));
			e.marginLeft = 0.4;
			setDependent(e, "g_nades_client_select", 0, 0);
		me.TD(me, 1, 0.2, e = makeXonoticTextLabel(0, "2"));
			e.marginLeft = 0.4;
			setDependentNOT(e, "g_nades_bonus", 0);
			setDependentAND(e, "g_nades_bonus_client_select", 0, 0);
		me.TD(me, 1, 0.2, e = makeXonoticTextLabel(0, "3"));
			e.marginLeft = 0.4;
			setDependent(e, "g_nades_client_select", 1, 1);
			setDependentOR(e, "g_nades_bonus_client_select", 1, 1);
		int j = 0;
		FOREACH(Nades, it != NADE_TYPE_Null,
		{
			if (j % 2 == 0)
				me.TR(me);
			me.TD(me, 1, 4 / 2 - 0.2 * 3, e = makeXonoticTextLabel(0, strzone(it.m_name)));
				e.align = 1;
				e.marginRight = 0.5;
			me.TD(me, 1, 0.2, e = makeXonoticRadioButton(1, "g_nades_nade_type", strzone(itos(it.impulse)), ""));
				setDependent(e, "g_nades_client_select", 0, 0);
			me.TD(me, 1, 0.2, e = makeXonoticRadioButton(2, "g_nades_bonus_type", strzone(itos(it.impulse)), ""));
				setDependentNOT(e, "g_nades_bonus", 0);
				setDependentAND(e, "g_nades_bonus_client_select", 0, 0);
			if (it == NADE_TYPE_NORMAL)
				me.TDempty(me, 0.2);
			else
			{
				me.TD(me, 1, 0.2, e = makeXonoticCheckBox(0, strzone(strcat("g_nades_", it.netname)), ""));
					setDependent(e, "g_nades_client_select", 1, 1);
					setDependentOR(e, "g_nades_bonus_client_select", 1, 1);
			}
			++j;
		});
		if (j % 2 == 0)
			me.TR(me);
		me.TD(me, 1, 4 / 2 - 0.2 * 3, e = makeXonoticTextLabel(0, _("Random"))); // put random nade at end of list
			e.align = 1;
			e.marginRight = 0.5;
		me.TD(me, 1, 0.2, e = makeXonoticRadioButton(1, "g_nades_nade_type", "0", ""));
			setDependent(e, "g_nades_client_select", 0, 0);
		me.TD(me, 1, 0.2, e = makeXonoticRadioButton(2, "g_nades_bonus_type", "0", ""));
			setDependentNOT(e, "g_nades_bonus", 0);
			setDependentAND(e, "g_nades_bonus_client_select", 0, 0);

	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 4 - 0.2, e = makeXonoticTextLabel(0, strzone(strcat("1. ", _("Normal nade type, if client selection is disabled")))));
			setDependent(e, "g_nades_client_select", 0, 0);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 4 - 0.2, e = makeXonoticTextLabel(0, strzone(strcat("2. ", _("Bonus nade type, if client selection is disabled")))));
			setDependentNOT(e, "g_nades_bonus", 0);
			setDependentAND(e, "g_nades_bonus_client_select", 0, 0);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 4 - 0.2, e = makeXonoticTextLabel(0, strzone(strcat("3. ", _("Allow client selection")))));
			setDependent(e, "g_nades_client_select", 1, 1);
			setDependentOR(e, "g_nades_bonus_client_select", 1, 1);
}

METHOD(XonoticMutatorNadesTab, describe, string(XonoticMutatorNadesTab me))
{
	return sprintf(_("Enable throwable grenades which explode with a variety of effects. Press %s or %s to use them."), strcat("^3", _("drop weapon"), "^7"), strcat("^3", _("hook"), "^7"));
}
METHOD(XonoticMutatorNadesTab, canEnable, bool(XonoticMutatorNadesTab me, bool is_already_enabled))
{
	bool can_enable = true;
	if (is_already_enabled)
		return can_enable && cvar(me.message);
	return can_enable;
}
