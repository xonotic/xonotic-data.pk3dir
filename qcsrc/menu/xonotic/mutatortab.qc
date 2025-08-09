#include "mutatortab.qh"

#include "checkbox.qh"
#include "checkbox_slider_invalid.qh"
#include "mixedslider.qh"
#include "radiobutton.qh"
#include "slider.qh"
#include "textlabel.qh"
#include <common/mutators/mutator/instagib/ui_instagib.qh>
#include <common/mutators/mutator/nix/ui_nix.qh>
#include <common/mutators/mutator/powerups/powerup/jetpack.qh>
#include <common/weapons/all.qh>

#ifdef MENU_INCLUDE_OVERKILL
	#include <common/mutators/mutator/dodging/dodging.qh>
	#include <common/mutators/mutator/nades/nades.qh>
#endif

void XonoticMutatorTab_showNotify(entity me)
{
	loadAllCvars(me);
}

entity Mutators_main_checkbox(entity me)
{
	entity e;
	me.TR(me);
		me.TDempty(me, 1.75);
		me.TD(me, 1, 2.25, e = makeXonoticCheckBox(0, me.message, _("Enable")));
			Mutators_add_CheckBox(me, e);
	return e;
}

// functions to add toggleableItems
void Mutators_toggleable_RadioButton_loadCvars(entity me)
{
	XonoticRadioButton_loadCvars(me);
	me.disabled = !me.parent.canEnable(me.parent, false);
}
void Mutators_add_RadioButton(entity me, entity e)
{
	e.loadCvars = Mutators_toggleable_RadioButton_loadCvars;
	me.(toggleableItems[me.cnt++]) = e;
}
void Mutators_toggleable_CheckBox_loadCvars(entity me)
{
	XonoticCheckBox_loadCvars(me);
	me.disabled = !me.parent.canEnable(me.parent, false);
}
void Mutators_add_CheckBox(entity me, entity e)
{
	e.loadCvars = Mutators_toggleable_CheckBox_loadCvars;
	me.(toggleableItems[me.cnt++]) = e;
}
void Mutators_toggleable_SliderCheckBox_loadCvars(entity me)
{
	me.disabled = !me.parent.canEnable(me.parent, false);
}
void Mutators_add_SliderCheckBox(entity me, entity e)
{
	e.loadCvars = Mutators_toggleable_SliderCheckBox_loadCvars;
	me.(toggleableItems[me.cnt++]) = e;
}


// Weapon arena "mutator"
entity makeXonoticWeaponarenaCheckBox(string theWeapon, string theText)
{
	entity me = NEW(XonoticWeaponarenaCheckBox);
	me.configureXonoticWeaponarenaCheckBox(me, theWeapon, theText);
	return me;
}

void XonoticWeaponarenaCheckBox_configureXonoticWeaponarenaCheckBox(entity me, string theWeapon, string theText)
{
	me.message = theWeapon;
	me.checked = false;
	me.loadCvars(me);
	me.configureCheckBox(me, theText, me.fontSize, me.image);
}

void XonoticWeaponarenaCheckBox_loadCvars(entity me)
{
	int n = tokenize_console(cvar_string("menu_weaponarena"));
	for (int i = 0; i < n; ++i)
		if (argv(i) == me.message)
		{
			me.checked = true;
			break;
		}
}
void XonoticWeaponarenaCheckBox_saveCvars(entity me)
{
	string mwa = cvar_string("menu_weaponarena");
	if (me.checked) // addtolist
	{
		if (mwa == "none")
			mwa = me.message;
		else
			mwa = cons(mwa, me.message);
	}
	else // removefromlist
	{
		string s;
		int n = tokenize_console(mwa);
		mwa = "";
		for (int i = 0; i < n; ++i)
		{
			s = argv(i);
			if (s != me.message)
				mwa = cons(mwa, s);
		}
		if (mwa == "")
			mwa = "none";
	}
	cvar_set("menu_weaponarena", mwa);
	switch (cvar_string("g_weaponarena"))
	{
		case "off":     case "":                  case "0":
		case "most":    case "most_available":
		case "all":     case "all_available":     case "1":
		case "devall":  case "devall_available":
			return;
		default:
			cvar_set("g_weaponarena", mwa);
	}

	entity e;
	for (int i = 0; i < me.parent.cnt; ++i) // reload cvars for the RadioButtons
	{
		e = me.parent.(toggleableItems[i]);
		e.loadCvars(e);
	}
}

entity makeXonoticMutatorWeaponArenaTab()
{
	entity me = NEW(XonoticMutatorWeaponArenaTab);
	me.configureDialog(me);
	return me;
}

void MutatorWeaponArenaDisable_RadioButton_loadCvars(entity me)
{
	me.checked = (cvar_string("menu_weaponstartoverride") == "-1"
		&& (cvar_string("g_weaponarena") == "0" || cvar_string("g_weaponarena") == "off" || cvar_string("g_weaponarena") == "")
		&& !cvar("g_instagib") && !cvar("g_nix") && !cvar("g_melee_only") && !cvar("g_overkill"));
}
void MutatorWeaponArenaCustom_RadioButton_loadCvars(entity me)
{
	switch (cvar_string("g_weaponarena"))
	{
		case "off":     case "":                  case "0":
		case "most":    case "most_available":
		case "all":     case "all_available":     case "1":
		case "devall":  case "devall_available":
			me.checked = false;
			return;
		default:
			me.checked = true;
			return;
	}
}
void MutatorWeaponArenaCustom_RadioButton_saveCvars(entity me)
{
	XonoticRadioButton_saveCvars(me);
	if (cvar_string("g_weaponarena") == "")
		cvar_set("g_weaponarena", cvar_string("menu_weaponarena"));
}

void XonoticMutatorWeaponArenaTab_fill(entity me)
{
	entity e;

	/* These RadioButtons have fairly complicated requirements to work properly:
	 * XonoticWeaponarenaCheckBox_saveCvars:
	 *   Clicking the CheckBox needs to update menu_weaponarena, but also g_weaponarena if "Custom weapons" has been selected.
	 *   We don't update g_weaponarena directly to allow saving selections.
	 *   Clicking a CheckBox also needs to reload cvars for the RadioButtons, since the CheckBox might've set g_weaponarena 0.
	 * MutatorWeaponArenaDisable_RadioButton_loadCvars:
	 *   "Disable" is true if g_weaponarena 0, but shouldn't be selected if any of the other options are chosen (e.g. g_instagib 1),
	 *   and consequently the CheckBoxes for these cvars in their own mutator tabs need to also adjust g_weaponarena.
	 * MutatorWeaponArenaCustom_RadioButton_loadCvars:
	 *   "Custom weapons" being selected has more complicated requirements than just if g_weaponarena is set to "".
	 * MutatorWeaponArenaCustom_RadioButton_saveCvars:
	 *   "Custom weapons" needs to set g_weaponarena to menu_weaponarena when selected.
	 * Need to reset g_weaponarena "" to g_weaponarena "0" where possible.
	 * Also, NIX and g_weaponarena can be technically be enabled together, but we just ignore that.
	 */
	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticRadioButton(1, me.message, "0", _("Disable")));
			Mutators_add_RadioButton(me, e);
			e.loadCvars = MutatorWeaponArenaDisable_RadioButton_loadCvars;
	me.TR(me);
		me.TD(me, 1, 2, e = makeXonoticRadioButton(1, me.message, "all", _("All weapons")));
			e.cvarOffValue = "0";
			Mutators_add_RadioButton(me, e);
		me.TD(me, 1, 2, e = makeXonoticRadioButton(1, me.message, "most", _("Most weapons")));
			e.cvarOffValue = "0";
			Mutators_add_RadioButton(me, e);
	me.TR(me);
		string multi = "";
		FOREACH(Weapons, it != WEP_Null,
		{
			if ((it.spawnflags & WEP_FLAG_HIDDEN) || it.netname == "ballstealer")
				continue;
			multi = cons(multi, strcat("g_balance_", it.netname, "_weaponstartoverride"));
		});
		me.TD(me, 1, 4, e = makeXonoticRadioButton_T(1, "menu_weaponstartoverride", "0", _("No start weapons"), "-"));
			e.cvarOffValue = "-1";
			makeMulti(e, strzone(multi));
			Mutators_add_RadioButton(me, e);
	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticRadioButton(1, me.message, "", _("Custom weapons")));
			e.cvarOffValue = "0";
			Mutators_add_RadioButton(me, e);
			e.loadCvars = MutatorWeaponArenaCustom_RadioButton_loadCvars;
			e.saveCvars = MutatorWeaponArenaCustom_RadioButton_saveCvars;
		int cols = 3;
		int j = 0;
		FOREACH(Weapons, it != WEP_Null,
		{
			if ((it.spawnflags & WEP_FLAG_HIDDEN) || it.netname == "ballstealer")
				continue;
			if (j % cols == 0)
			{
				me.TR(me);
				me.TDempty(me, 0.2);
			}
			me.TD(me, 1, (4 - 0.2) / cols, e = makeXonoticWeaponarenaCheckBox(strzone(it.netname), strzone(it.m_name)));
			++j;
		});

	me.TR(me);
		me.TD(me, 1, 4, makeXonoticTextLabel(0, _("Special arenas:")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, (4 - 0.2) / 2, e = makeXonoticRadioButton_T(1, "g_instagib", "1", MENU_INSTAGIB_NAME, sprintf(MENU_INSTAGIB_DESCRIPTION, UNCOLORED_NAME(WEP_VAPORIZER))));
			e.cvarOffValue = "0";
		me.TD(me, 1, (4 - 0.2) / 2, e = makeXonoticRadioButton_T(1, "g_nix", "1", MENU_NIX_NAME, MENU_NIX_DESCRIPTION));
			e.cvarOffValue = "0";
	me.TR(me);
		me.TDempty(me, 0.2);
#ifdef MENU_INCLUDE_OVERKILL
		me.TD(me, 1, (4 - 0.2) / 2, e = makeXonoticRadioButton_T(1, "g_overkill", "1", MENU_OVERKILL_NAME, sprintf(MENU_OVERKILL_DESCRIPTION, UNCOLORED_NAME(WEP_BLASTER), UNCOLORED_NAME(MUTATOR_dodging), UNCOLORED_NAME(MUTATOR_nades))));
			e.cvarOffValue = "0";
		me.TD(me, 1, (4 - 0.2) / 2, // ...
#else
		me.TD(me, 1, 4 - 0.2, // ...
#endif
			e = makeXonoticRadioButton_T(1, "g_melee_only", "1", _("Melee only arena"),
			sprintf(_("Players spawn with no ammo and no weapons except the %s, so can only slap other players."), UNCOLORED_NAME(WEP_SHOTGUN))));
			e.cvarOffValue = "0";
}

METHOD(XonoticMutatorWeaponArenaTab, describe, string(XonoticMutatorWeaponArenaTab me))
{
	return _("Players will be given a set of weapons on spawn along with unlimited ammo, without weapon pickups on the map.");
}
METHOD(XonoticMutatorWeaponArenaTab, canEnable, bool(XonoticMutatorWeaponArenaTab me, bool is_already_enabled))
{
	bool can_enable = true;
	// weaponarena can't be enabled with g_overkill 1, g_instagib 1, or g_melee_only 1,
	// ... but we ignore them here since they're lumped in the same RadioButton group
	if (is_already_enabled) // include g_melee_only, since it isn't elsewhere in the menu mutator list
		return can_enable && (!cvar("menu_weaponstartoverride") || cvar("g_melee_only")
			|| (cvar_string(me.message) != "0" && cvar_string(me.message) != "off" && cvar_string(me.message) != ""));
	return can_enable;
}


// Weapon stay "mutator"
entity makeXonoticMutatorWeaponStayTab()
{
	entity me = NEW(XonoticMutatorWeaponStayTab);
	me.configureDialog(me);
	return me;
}

void XonoticMutatorWeaponStayTab_fill(entity me)
{
	entity e;

	me.TR(me);
		me.TD(me, 1, 4 * 0.225, e = makeXonoticRadioButton(1, me.message, "0", _("Disable")));
			Mutators_add_RadioButton(me, e);
		me.TD(me, 1, 4 * 0.55,  e = makeXonoticRadioButton(1, me.message, "1", _("Enabled but pickups give no ammo")));
			Mutators_add_RadioButton(me, e);
		me.TD(me, 1, 4 * 0.225, e = makeXonoticRadioButton(1, me.message, "2", _("Enable")));
			Mutators_add_RadioButton(me, e);
}

METHOD(XonoticMutatorWeaponStayTab, describe, string(XonoticMutatorWeaponStayTab me))
{
	return _("Weapons stay on the map after they are picked up.");
}
METHOD(XonoticMutatorWeaponStayTab, canEnable, bool(XonoticMutatorWeaponStayTab me, bool is_already_enabled))
{
	// Weapon stay requires weapons to actually spawn on the map
	bool can_enable = (!cvar("g_instagib") && !cvar("g_nix") && !cvar("g_melee_only") && !cvar("g_overkill")
		&& (cvar_string("g_weaponarena") == "0" || cvar_string("g_weaponarena") == "off" || cvar_string("g_weaponarena") == ""));
	if (is_already_enabled)
		return can_enable && cvar(me.message);
	return can_enable;
}


// Offhand weapons "mutator"
entity makeXonoticMutatorOffhandWeaponsTab()
{
	entity me = NEW(XonoticMutatorOffhandWeaponsTab);
	me.configureDialog(me);
	return me;
}

void XonoticMutatorOffhandWeaponsTab_fill(entity me)
{
	entity e;

	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 4 - 0.2, e = makeXonoticCheckBox(0, "g_offhand_blaster", _("Offhand Blaster")));

	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 4 - 0.2, e = makeXonoticCheckBox(0, "g_grappling_hook", _("Offhand Hook")));
			setDependent(e, "g_offhand_blaster", 0, 0);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 4 - 0.2, e = makeXonoticCheckBox(0, "g_grappling_hook_useammo", _("Consume ammo")));
}

METHOD(XonoticMutatorOffhandWeaponsTab, describe, string(XonoticMutatorOffhandWeaponsTab me))
{
	return sprintf(_("Players spawn with an Offhand Blaster or Grappling Hook. Press %s to use it."), strcat("^3", _("hook"), "^7"));
}
METHOD(XonoticMutatorOffhandWeaponsTab, canEnable, bool(XonoticMutatorOffhandWeaponsTab me, bool is_already_enabled))
{
	bool can_enable = true;
	if (is_already_enabled)
		return can_enable && (cvar("g_offhand_blaster") || cvar("g_grappling_hook"));
	return can_enable;
}


// Jetpack "mutator"
entity makeXonoticMutatorJetpackTab()
{
	entity me = NEW(XonoticMutatorJetpackTab);
	me.configureDialog(me);
	return me;
}

void XonoticMutatorJetpackTab_fill(entity me)
{
	Mutators_main_checkbox(me);
}

METHOD(XonoticMutatorJetpackTab, describe, string(XonoticMutatorJetpackTab me))
{
	return sprintf(_("Players spawn with the %s. Double-tap %s or press %s to use it."), COLORED_NAME(ITEM_Jetpack), strcat("^3", _("jump"), "^7"), strcat("^3", _("jetpack"), "^7"));
}
METHOD(XonoticMutatorJetpackTab, canEnable, bool(XonoticMutatorJetpackTab me, bool is_already_enabled))
{
	bool can_enable = true;
	if (is_already_enabled)
		return can_enable && cvar(me.message);
	return can_enable;
}


// Custom physics "mutator"
entity makeXonoticMutatorCustomPhysicsTab()
{
	entity me = NEW(XonoticMutatorCustomPhysicsTab);
	me.configureDialog(me);
	return me;
}

void XonoticMutatorCustomPhysicsTab_fill(entity me)
{
	entity e, s;

	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticCheckBox_T(0, "g_dodging", _("Dodging"),
			_("Enable dodging (quick acceleration in a given direction). Double-tap a directional key to dodge")));

	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 2, e = makeXonoticTextLabel(0, _("Midair jumps:")));
		me.TD(me, 1, 2, e = makeXonoticMixedSlider_T("g_multijump",
			_("How many times players can jump while midair")));
			e.addText(e, _("Infinite"), -1);
			e.addRange(e, 0, 10, 1);
			e.configureXonoticMixedSliderValues(e);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 4 - 0.2, e = makeXonoticCheckBox_T(0, "g_multijump_add", _("Additive velocity"),
			_("Add on, rather than set, their vertical velocity each time the player jumps")));

	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticCheckBox_T(0, "g_walljump", _("Wall jumping"),
			_("Jump away from walls when running alongside them")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.8, makeXonoticTextLabel(0, _("Delay between walljumps:")));
		me.TD(me, 1, 2, e = makeXonoticSlider(0.5, 1.5, 0.1, "g_walljump_delay"));
			e.formatString = "S";
			e.setValueSpace(e, e.valueSpace * 1.25);

	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticCheckBox_T(0, "sv_doublejump", _("Double jumps"),
			_("Gain extra height when jumping again shortly after the first jump")));

	const float def_grav = stof(cvar_defstring("sv_gravity"));
	me.TR(me);
	me.TR(me);
		s = makeXonoticSlider_T(def_grav * 0.1, def_grav * 0.75, def_grav * 0.025, "sv_gravity",
			_("Make things fall to the ground slower (percentage of normal gravity)"));
			s.valueDigits = 3;
			s.valueDisplayMultiplier = 1 / def_grav; // show gravity as a percent of normal
			s.formatString = "%";
		me.TD(me, 1, 2, e = makeXonoticSliderCheckBox(def_grav, 1, s, _("Low gravity")));
			e.savedValue = def_grav * 0.25; // good on silvercity
		me.TD(me, 1, 2, s);

	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticCheckBox_T(0, "g_globalforces", _("Global forces"),
			_("Knockback experienced by any player affects all players")));
}

METHOD(XonoticMutatorCustomPhysicsTab, describe, string(XonoticMutatorCustomPhysicsTab me))
{
	return _("Various fun changes to physics and movement.");
}
METHOD(XonoticMutatorCustomPhysicsTab, canEnable, bool(XonoticMutatorCustomPhysicsTab me, bool is_already_enabled))
{
	bool can_enable = true;
	if (is_already_enabled)
		return can_enable && (cvar("g_dodging") || cvar("g_multijump") || cvar("g_walljump") || cvar("sv_doublejump")
			|| cvar("sv_gravity") < stof(cvar_defstring("sv_gravity")) || cvar("g_globalforces"));
	return can_enable;
}
