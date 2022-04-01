#include "dialog_multiplayer_create_mutators.qh"
#include <common/weapons/_all.qh>

#include "weaponarenacheckbox.qh"
#include "checkbox.qh"
#include "slider.qh"
#include "textlabel.qh"
#include "checkbox_slider_invalid.qh"
#include "radiobutton.qh"
#include "button.qh"

void XonoticMutatorsDialog_showNotify(entity me)
{
	SUPER(XonoticMutatorsDialog).showNotify(me);
	loadAllCvars(me);
}

string weaponarenastring;
string weaponarenastring_cvar;
string WeaponArenaString()
{
	string s;
	float n;
	s = cvar_string("g_weaponarena");
	if(s == "0" || s == "") return "";
	if(s == "all" || s == "1") return _("All Weapons Arena");
	if(s == "all_available") return _("All Available Weapons Arena");
	if(s == "most") return _("Most Weapons Arena");
	if(s == "most_available") return _("Most Available Weapons Arena");
	if(s == "devall") return "Dev All Weapons Arena"; // development option, do not translate
	if(s == "devall_available") return "Dev All Available Weapons Arena"; // development option, do not translate
	if(s == weaponarenastring_cvar)
		return weaponarenastring;

	strcpy(weaponarenastring_cvar, s);

	n = tokenize_console(s);
	s = "";
	for(int j = 0; j < n; ++j)
	{
		Weapon wep = Weapon_from_name(argv(j));
		if(wep != WEP_Null)
		{
			s = cons_mid(s, " & ", wep.m_name);
		}
	}
	if (s != "")
		s = sprintf(_("%s Arena"), s);
	else
		s = _("No Weapons Arena");

	strcpy(weaponarenastring, s);

	return weaponarenastring;
}

string XonoticMutatorsDialog_toString(entity me)
{
	string s = build_mutator_list("");
	if(cvar_string("g_weaponarena") != "0")
		s = cons_mid(s, ", ", WeaponArenaString());
	if(s == "")
		return ZCTX(_("MUT^None"));
	else
		return s;
}

float checkCompatibility_pinata(entity me)
{
	if(cvar("g_instagib"))
		return 0;
	if(cvar("g_nix"))
		return 0;
	if(cvar("g_overkill"))
		return 0;
	if(cvar("g_melee_only"))
		return 0;
	if(cvar_string("g_weaponarena") != "0")
		return 0;
	return 1;
}
float checkCompatibility_weaponstay(entity me)
{
	return checkCompatibility_pinata(me);
}
float checkCompatibility_newtoys(entity me)
{
	if(cvar("g_instagib"))
		return 0;
	if(cvar_string("g_weaponarena") == "most")
		return 1;
	if(cvar_string("g_weaponarena") == "all" || cvar_string("g_weaponarena") == "1")
		return 1;
	if(cvar_string("g_weaponarena") != "0")
		return 0;
	return 1;
}
float checkCompatibility_weaponarena_weapon(entity me)
{
	if(cvar("g_instagib"))
		return 0;
	if(cvar_string("g_weaponarena") == "most")
		return 0;
	if(cvar_string("g_weaponarena") == "all" || cvar_string("g_weaponarena") == "1")
		return 0;
	if(cvar_string("g_weaponarena") == "0")
		return 0;
	if(cvar_string("g_balance_blaster_weaponstartoverride") == "0")
		return 0;
	return 1;
}

void XonoticMutatorsDialog_fill(entity me)
{
	entity e, s, w;
	float i, j;
	me.TR(me);
		me.TD(me, 1, 2, makeXonoticTextLabel(0, _("Gameplay mutators:")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.8, e = makeXonoticCheckBox_T(0, "g_dodging", _("Dodging"),
			_("Enable dodging (quick acceleration in a given direction). Double-tap a directional key to dodge")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.8, e = makeXonoticCheckBox_T(0, "g_touchexplode", _("Touch explode"),
			_("An explosion occurs when two players collide")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.8, e = makeXonoticCheckBox_T(0, "g_cloaked", _("Cloaked"),
			_("All players are almost invisible")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.8, e = makeXonoticCheckBox_T(0, "g_buffs", _("Buffs"),
			_("Enable buff pickups (random bonuses like Medic, Invisible, etc.) on the maps that support it")));
			e.cvarOffValue = "-1"; // TODO: make this a radio button?
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.8, e = makeXonoticCheckBox_T(0, "g_midair", _("Midair"),
			_("Only possible to inflict damage on your enemy while they're airborne")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.8, e = makeXonoticCheckBox_T(0, "g_vampire", _("Vampire"),
			_("Damage done to your enemy gets added to your own health")));
			setDependent(e, "g_instagib", 0, 0);
	me.TR(me);
		me.TDempty(me, 0.2);
		s = makeXonoticSlider_T(10, 50, 1, "g_bloodloss",
			_("Amount of health below which players start bleeding out (health rots and they can't jump)"));
		me.TD(me, 1, 1.8, e = makeXonoticSliderCheckBox(0, 1, s, _("Blood loss")));
			setDependent(e, "g_instagib", 0, 0);
	me.TR(me);
		me.TDempty(me, 0.4);
		me.TD(me, 1, 1.6, s);
	me.TR(me);
		me.TDempty(me, 0.2);
		s = makeXonoticSlider_T(80, 400, 8, "sv_gravity",
			_("Make things fall to the ground slower (percentage of normal gravity)"));
			s.valueDigits = 0;
			s.valueDisplayMultiplier = 0.125; // show gravity in percent
		me.TD(me, 1, 1.8, e = makeXonoticSliderCheckBox(800, 1, s, _("Low gravity")));
			e.savedValue = 200; // good on silvercity
	me.TR(me);
		me.TDempty(me, 0.4);
		me.TD(me, 1, 1.6, s);
	me.TR(me);
		me.TD(me, 1, 2, makeXonoticTextLabel(0, _("Weapon & item mutators:")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.8, e = makeXonoticCheckBox_T(0, "g_grappling_hook", _("Grappling Hook"),
			_("Players spawn with the grappling hook. Press the 'hook' key to use it")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.8, e = makeXonoticCheckBox_T(0, "g_jetpack", _("Jetpack"),
			_("Players spawn with the jetpack. Double-tap 'jump' or press the 'jetpack' key to use it")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.8, e = makeXonoticCheckBox_T(0, "g_invincible_projectiles", _("Invincible Projectiles"),
			_("Projectiles can't be destroyed. However, you can still explode Electro orbs with the Electro primary fire")));
			setDependent(e, "g_instagib", 0, 0);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.8, e = makeXonoticCheckBox_T(0, "g_new_toys", _("New Toys"),
			_("Some weapon spawns will be randomly replaced with new weapons: Heavy Laser Assault Cannon, Mine Layer, Rifle, T.A.G. Seeker")));
			setDependentWeird(e, checkCompatibility_newtoys);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.8, e = makeXonoticCheckBox_T(0, "g_rocket_flying", _("Rocket Flying"),
			_("Devastator rockets can be detonated instantly (otherwise, there's a short delay). This allows players to fire and detonate a Devastator rocket while in the air for a strong mid-air boost even while moving fast")));
			setDependent(e, "g_instagib", 0, 0);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.8, e = makeXonoticCheckBox_T(0, "g_pinata", _("Piñata"),
			_("Players will drop all weapons they possessed when they are killed")));
			setDependentWeird(e, checkCompatibility_pinata);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.8, e = makeXonoticCheckBox_T(0, "g_weapon_stay", _("Weapons stay"),
			_("Weapons stay after they are picked up")));
			setDependentWeird(e, checkCompatibility_weaponstay);
	me.TR(me);

	me.gotoRC(me, 0, 2); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 2, e = makeXonoticRadioButton(1, string_null, string_null, _("Regular (no arena)")));
	string weaponarena_tooltip = strzone(_("Players will be given a set of weapons at spawn as well as unlimited ammo, without weapon pickups"));
	me.TR(me);
		me.TD(me, 1, 2, makeXonoticTextLabel(0, _("Weapon arenas:")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.8, e = makeXonoticRadioButton_T(1, "g_weaponarena", "menu_weaponarena", _("Custom weapons"), weaponarena_tooltip));
			e.cvarValueIsAnotherCvar = true;
			e.cvarOffValue = "0";

		me.TDempty(me, 0.1); // fix initial position
	for(i = WEP_FIRST, j = 0; i <= WEP_LAST; ++i)
	{
		w = REGISTRY_GET(Weapons, i);
		if (w.spawnflags & (WEP_FLAG_HIDDEN | WEP_FLAG_SPECIALATTACK))
			continue;
		if ((j % 3) == 0)
		{
			me.TR(me);
			me.TDempty(me, 0.4);
		}
		me.TD(me, 1, 1.2, e = makeXonoticWeaponarenaCheckBox(strzone(w.netname), strzone(w.m_name)));
			setDependentWeird(e, checkCompatibility_weaponarena_weapon);
		++j;
	}

	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.8, e = makeXonoticRadioButton_T(1, "g_weaponarena", "most", _("Most weapons"), weaponarena_tooltip));
			e.cvarOffValue = "0";
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.8, e = makeXonoticRadioButton_T(1, "g_weaponarena", "all", _("All weapons"), weaponarena_tooltip));
			e.cvarOffValue = "0";
	me.TR(me);
		me.TD(me, 1, 4, makeXonoticTextLabel(0, _("Special arenas:")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.8, e = makeXonoticRadioButton_T(1, "g_instagib", "1", _("InstaGib"),
			_("Players will be given only one weapon, which can instantly kill the opponent with a single shot. If the player runs out of ammo, he will have 10 seconds to find some or if he fails to do so, face death. The secondary fire mode does not inflict any damage but is good for doing trickjumps.")));
			e.cvarOffValue = "0";
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.8, e = makeXonoticRadioButton_T(1, "g_nix", "1", _("NIX"),
			_("No items Xonotic - instead of pickup items, everyone plays with the same weapon. After some time, a countdown will start, after which everyone will switch to another weapon.")));
			e.cvarOffValue = "0";
	me.TR(me);
		me.TDempty(me, 0.4);
		me.TD(me, 1, 1.6, e = makeXonoticCheckBox_T(0, "g_nix_with_blaster", _("with blaster"),
			_("Always carry the blaster as an additional weapon in Nix")));
			setDependent(e, "g_nix", 1, 1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.8, e = makeXonoticRadioButton_T(1, "g_balance_blaster_weaponstartoverride", "0", _("No start weapons"), "-"));
			e.cvarOffValue = "-1";
			makeMulti(e, "g_balance_shotgun_weaponstartoverride g_balance_machinegun_weaponstartoverride g_balance_devastator_weaponstartoverride g_balance_minelayer_weaponstartoverride g_balance_electro_weaponstartoverride g_balance_crylink_weaponstartoverride g_balance_hagar_weaponstartoverride g_balance_porto_weaponstartoverride g_balance_vaporizer_weaponstartoverride g_balance_hook_weaponstartoverride g_balance_rifle_weaponstartoverride g_balance_fireball_weaponstartoverride g_balance_seeker_weaponstartoverride g_balance_tuba_weaponstartoverride g_balance_arc_weaponstartoverride g_balance_vortex_weaponstartoverride g_balance_mortar_weaponstartoverride");

	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, e = makeXonoticButton(_("OK"), '0 0 0'));
			e.onClick = Dialog_Close;
			e.onClickEntity = me;
}

.void(entity) refilter;

void XonoticMutatorsDialog_close(entity me)
{
	if(me.refilterEntity)
		me.refilterEntity.refilter(me.refilterEntity);
	SUPER(XonoticMutatorsDialog).close(me);
}
