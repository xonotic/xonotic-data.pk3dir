#include "ui_nix.qh"

#include <menu/xonotic/checkbox.qh>
#include <menu/xonotic/textlabel.qh>

entity makeXonoticMutatorNIXTab()
{
	entity me = NEW(XonoticMutatorNIXTab);
	me.configureDialog(me);
	return me;
}

void MutatorNIX_CheckBox_saveCvars(entity me)
{
	XonoticCheckBox_saveCvars(me);
	if (cvar("g_nix"))
	{
		if (cvar_string("g_weaponarena") != "0")
			cvar_set("g_weaponarena", "0"); // weaponarena can't be enabled if NIX is, or at least we pretend it can't
		if (cvar("g_melee_only"))
			cvar_set("g_melee_only", "0");
	}
}

void XonoticMutatorNIXTab_fill(entity me)
{
	entity e = Mutators_main_checkbox(me);
		e.saveCvars = MutatorNIX_CheckBox_saveCvars;

	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticCheckBox_T(0, "g_nix_with_blaster", _("With Blaster"),
			_("Always carry the Blaster as an additional weapon in NIX")));
	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticTextLabel(0, _("Allow maps to spawn:")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, (4 - 0.2) * 0.6, e = makeXonoticCheckBox(0, "g_nix_with_healtharmor", _("Health and armor")));
		me.TD(me, 1, (4 - 0.2) * 0.4, e = makeXonoticCheckBox(0, "g_nix_with_powerups",    _("Powerups")));
}

METHOD(XonoticMutatorNIXTab, describe, string(XonoticMutatorNIXTab me))
{
	return MENU_NIX_DESCRIPTION;
}
METHOD(XonoticMutatorNIXTab, canEnable, bool(XonoticMutatorNIXTab me, bool is_already_enabled))
{
	bool can_enable = (!cvar("g_instagib") && !cvar("g_overkill") && !cvar("g_melee_only"));
	if (is_already_enabled)
		return can_enable && cvar(me.message);
	return can_enable;
}
