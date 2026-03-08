#include "ui_instagib.qh"

#include <menu/xonotic/checkbox.qh>
#include <menu/xonotic/slider.qh>
#include <menu/xonotic/textlabel.qh>

entity makeXonoticMutatorInstaGibTab()
{
	entity me = NEW(XonoticMutatorInstaGibTab);
	me.configureDialog(me);
	return me;
}

void MutatorInstaGib_CheckBox_saveCvars(entity me)
{
	XonoticCheckBox_saveCvars(me);
	if (cvar("g_instagib"))
	{
		if (cvar_string("g_weaponarena") != "0")
			cvar_set("g_weaponarena", "0"); // weaponarena can't be enabled if InstaGib is
		if (cvar("g_melee_only"))
			cvar_set("g_melee_only", "0");
		if (cvar("g_overkill"))
			cvar_set("g_overkill", "0");
		if (cvar("g_nix"))
			cvar_set("g_nix", "0");
	}
}

void XonoticMutatorInstaGibTab_fill(entity me)
{
	entity e = Mutators_main_checkbox(me);
		e.saveCvars = MutatorInstaGib_CheckBox_saveCvars;

	me.TR(me);
		me.TD(me, 1, 2, e = makeXonoticTextLabel(0, _("Starting ammo:")));
		me.TD(me, 1, 2, e = makeXonoticSlider(1, 30, 1, "g_instagib_ammo_start"));
	me.TR(me);
		me.TD(me, 1, 2, e = makeXonoticTextLabel(0, _("Ammo from weapons and cells:")));
		me.TD(me, 1, 2, e = makeXonoticSlider(0, 20, 1, "g_instagib_ammo_drop"));

	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 2, e = makeXonoticTextLabel(0, _("Extra lives per pickup:")));
			setDependentNOT(e, "g_powerups", 0);
		me.TD(me, 1, 2, e = makeXonoticSlider_T(1, 3, 1, "g_instagib_extralives",
			_("How many extra lives to reward a player when they pick up the Extra life")));
			setDependentNOT(e, "g_powerups", 0);

	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticCheckBox(0, "g_instagib_blaster_keepdamage", _("Keep Blaster damage")));
			setDependent(e, "g_rm", 0, 0);
	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticCheckBox(0, "g_instagib_blaster_keepforce", _("Keep Blaster force")));
			setDependent(e, "g_rm", 0, 0);

	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticCheckBox(0, "g_instagib_allow_jetpacks", _("Allow Jetpacks and Fuel regenerators")));
			setDependentNOT(e, "g_powerups", 0);

	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticCheckBox_T(0, "g_rm", _("Enable Rocketminsta"),
			_("The primary fire also explodes on impact, and the secondary fire shoots laser prongs")));
}

#include <common/weapons/weapon/vaporizer.qh>

METHOD(XonoticMutatorInstaGibTab, describe, string(XonoticMutatorInstaGibTab me))
{
	return sprintf(MENU_INSTAGIB_DESCRIPTION, COLORED_NAME(WEP_VAPORIZER));
}
METHOD(XonoticMutatorInstaGibTab, canEnable, bool(XonoticMutatorInstaGibTab me, bool is_already_enabled))
{
	bool can_enable = true;
	if (is_already_enabled)
		return can_enable && cvar(me.message);
	return can_enable;
}
