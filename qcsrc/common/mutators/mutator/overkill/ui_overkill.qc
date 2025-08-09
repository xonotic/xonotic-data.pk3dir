#include "ui_overkill.qh"

#ifdef MENU_INCLUDE_OVERKILL
#include <menu/xonotic/checkbox.qh>
#include <menu/xonotic/textlabel.qh>

entity makeXonoticMutatorOverkillTab()
{
	entity me = NEW(XonoticMutatorOverkillTab);
	me.configureDialog(me);
	return me;
}

void MutatorOverkill_CheckBox_saveCvars(entity me)
{
	XonoticCheckBox_saveCvars(me);
	if (cvar("g_overkill"))
	{
		if (cvar_string("g_weaponarena") != "0")
			cvar_set("g_weaponarena", "0"); // weaponarena can't be enabled if Overkill is
		if (cvar("g_melee_only"))
			cvar_set("g_melee_only", "0");
		if (cvar("g_nix"))
			cvar_set("g_nix", "0");
	}
}

void XonoticMutatorOverkillTab_fill(entity me)
{
	entity e = Mutators_main_checkbox(me);
		e.saveCvars = MutatorOverkill_CheckBox_saveCvars;

	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticCheckBox(0, "g_overkill_blaster_keepdamage", _("Keep Blaster damage")));
	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticCheckBox(0, "g_overkill_blaster_keepforce", _("Keep Blaster force")));

	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticTextLabel(0, _("Allow maps to spawn:")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, (4 - 0.2) / 3, e = makeXonoticCheckBox(1, "g_overkill_filter_armormega",  _("Mega armor")));
		me.TD(me, 1, (4 - 0.2) / 3, e = makeXonoticCheckBox(1, "g_overkill_filter_healthmega", _("Mega health")));
		me.TD(me, 1, (4 - 0.2) / 3, e = makeXonoticCheckBox(1, "g_overkill_filter_armorbig",   _("Big armor")));

	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticCheckBox(0, "g_overkill_powerups_replace", _("Replace Strength and Shield with weapons")));
			setDependentNOT(e, "g_powerups", 0);
}

#include <common/mutators/mutator/dodging/dodging.qh>
#include <common/mutators/mutator/nades/nades.qh>
#include <common/weapons/weapon/blaster.qh>

METHOD(XonoticMutatorOverkillTab, describe, string(XonoticMutatorOverkillTab me))
{
	return sprintf(MENU_OVERKILL_DESCRIPTION, COLORED_NAME(WEP_BLASTER), COLORED_NAME(MUTATOR_dodging), COLORED_NAME(MUTATOR_nades));
}
METHOD(XonoticMutatorOverkillTab, canEnable, bool(XonoticMutatorOverkillTab me, bool is_already_enabled))
{
	bool can_enable = !cvar("g_instagib");
	if (is_already_enabled)
		return can_enable && cvar(me.message);
	return can_enable;
}
#endif
