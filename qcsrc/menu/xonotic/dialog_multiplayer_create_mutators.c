#ifdef INTERFACE
CLASS(XonoticMutatorsDialog) EXTENDS(XonoticDialog)
	METHOD(XonoticMutatorsDialog, toString, string(entity))
	METHOD(XonoticMutatorsDialog, fill, void(entity))
	METHOD(XonoticMutatorsDialog, showNotify, void(entity))
	METHOD(XonoticMutatorsDialog, close, void(entity))
	ATTRIB(XonoticMutatorsDialog, title, string, "Mutators")
	ATTRIB(XonoticMutatorsDialog, color, vector, SKINCOLOR_DIALOG_MUTATORS)
	ATTRIB(XonoticMutatorsDialog, intendedWidth, float, 0.9)
	ATTRIB(XonoticMutatorsDialog, rows, float, 18)
	ATTRIB(XonoticMutatorsDialog, columns, float, 6)
	ATTRIB(XonoticMutatorsDialog, refilterEntity, entity, NULL)
ENDCLASS(XonoticMutatorsDialog)
#endif

#ifdef IMPLEMENTATION
void XonoticMutatorsDialog_showNotify(entity me)
{
	loadAllCvars(me);
}

string weaponarenastring;
string weaponarenastring_cvar;
string WeaponArenaString()
{
	string s;
	float n, i, j;
	entity e;
	s = cvar_string("g_weaponarena");
	if(s == "0")
		return "";
	if(s == "all")
		return "All Weapons Arena";
	if(s == "most")
		return "Most Weapons Arena";
	if(s == weaponarenastring_cvar)
		return weaponarenastring;
	if(weaponarenastring)
		strunzone(weaponarenastring);
	if(weaponarenastring_cvar)
		strunzone(weaponarenastring_cvar);

	weaponarenastring_cvar = strzone(s);

	n = tokenize_console(s);
	s = "";
	for(i = 0; i < n; ++i)
	{
		for(j = WEP_FIRST; j <= WEP_LAST; ++j)
		{
			e = get_weaponinfo(j);
			if(argv(i) == e.netname)
				s = strcat(s, " & ", e.message);
		}
	}
	s = strcat(substring(s, 3, strlen(s) - 3), " Arena");
	
	weaponarenastring = strzone(s);

	return weaponarenastring;
}

string XonoticMutatorsDialog_toString(entity me)
{
	string s;
	s = "";
	if(cvar("g_dodging"))
		s = strcat(s, ", Dodging");
	if(cvar("g_minstagib"))
		s = strcat(s, ", MinstaGib");
	if(cvar("g_nix"))
		s = strcat(s, ", NIX");
	if(cvar("g_rocket_flying"))
		s = strcat(s, ", Rocket Flying");
	if(cvar_string("g_weaponarena") != "0")
		s = strcat(s, ", ", WeaponArenaString());
	if(cvar("g_start_weapon_laser") == 0)
		s = strcat(s, ", No start weapons");
	if(cvar("sv_gravity") < 800)
		s = strcat(s, ", Low gravity");
	if(cvar("g_cloaked"))
		s = strcat(s, ", Cloaked");
	if(cvar("g_grappling_hook"))
		s = strcat(s, ", Hook");
	if(cvar("g_laserguided_missile"))
		s = strcat(s, ", LG missiles");
	if(cvar("g_midair"))
		s = strcat(s, ", Midair");
	if(cvar("g_vampire"))
		s = strcat(s, ", Vampire");
	if(cvar("g_pinata"))
		s = strcat(s, ", Pinata");
	if(cvar("g_weapon_stay"))
		s = strcat(s, ", Weapons stay");
	if(cvar("g_bloodloss") > 0)
		s = strcat(s, ", Bloodloss");
	if(cvar("g_jetpack"))
		s = strcat(s, ", Jet pack");
	if(s == "")
		return "None";
	else
		return substring(s, 2, strlen(s) - 2);
}



// WARNING: dirty hack. TODO clean this up by putting this behaviour in extra classes.
void loadCvarsLaserWeaponArenaWeaponButton(entity me)
{
	tokenize_console(cvar_string("g_weaponarena"));
	me.checked = (argv(0) == me.cvarValue);
}

void saveCvarsLaserWeaponArenaWeaponButton(entity me)
{
	string suffix;

	suffix = "";
	if(me.cvarValue != "laser" && me.cvarValue != "most")
		if(cvar("menu_weaponarena_with_laser"))
			suffix = " laser";
	if(me.checked)
		cvar_set("g_weaponarena", strcat(me.cvarValue, suffix));
	else
		cvar_set("g_weaponarena", me.cvarOffValue);
}

.void(entity) draw_weaponarena;
.void(entity) saveCvars_weaponarena;
void saveCvarsLaserWeaponArenaLaserButton(entity me)
{
	// run the old function
	me.saveCvars_weaponarena(me);

	me.disabled = ((cvar_string("g_weaponarena") == "0") || (cvar_string("g_weaponarena") == "laser") || (cvar_string("g_weaponarena") == "most"));

	if not(me.disabled)
	{
		// check for the laser suffix
		string s;
		s = cvar_string("g_weaponarena");
		if(me.checked && substring(s, strlen(s) - 6, 6) != " laser")
			s = strcat(s, " laser");
		else if(!me.checked && substring(s, strlen(s) - 6, 6) == " laser")
			s = substring(s, 0, strlen(s) - 6);
		cvar_set("g_weaponarena", s);
	}
}

void preDrawLaserWeaponArenaLaserButton(entity me)
{
	me.disabled = ((cvar_string("g_weaponarena") == "0") || (cvar_string("g_weaponarena") == "laser") || (cvar_string("g_weaponarena") == "most"));
	// run the old function
	me.draw_weaponarena(me);
}
// WARNING: end of dirty hack. Do not try this at home.



void XonoticMutatorsDialog_fill(entity me)
{
	entity e, s, w;
	float i, j;
	string str, hstr;
	me.TR(me);
		me.TD(me, 1, 2, makeXonoticTextLabel(0, "Gameplay mutators:"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2, e = makeXonoticCheckBox(0, "g_dodging", "Dodging"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2, e = makeXonoticCheckBox(0, "g_cloaked", "Cloaked"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2, e = makeXonoticCheckBox(0, "g_midair", "Midair"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2, e = makeXonoticCheckBox(0, "g_vampire", "Vampire"));
	me.TR(me);
		me.TDempty(me, 0.2);
		s = makeXonoticSlider(10, 50, 1, "g_bloodloss");
		me.TD(me, 1, 2, e = makeXonoticSliderCheckBox(0, 1, s, "Blood loss"));
	me.TR(me);
		me.TDempty(me, 0.4);
		me.TD(me, 1, 1.8, s);
	me.TR(me);
		me.TDempty(me, 0.2);
		s = makeXonoticSlider(80, 400, 8, "sv_gravity");
			s.valueDigits = 0;
			s.valueDisplayMultiplier = 0.125; // show gravity in percent
		me.TD(me, 1, 2, e = makeXonoticSliderCheckBox(800, 1, s, "Low gravity"));
			e.savedValue = 200; // good on silvercity
	me.TR(me);
		me.TDempty(me, 0.4);
		me.TD(me, 1, 1.8, s);
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 2, makeXonoticTextLabel(0, "Weapon & item mutators:"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2, e = makeXonoticCheckBox(0, "g_grappling_hook", "Grappling hook"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2, e = makeXonoticCheckBox(0, "g_jetpack", "Jet pack"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2, e = makeXonoticCheckBox(0, "g_laserguided_missile", "Laser guided missiles"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2, e = makeXonoticCheckBox(0, "g_rocket_flying", "Rocket Flying"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2, e = makeXonoticCheckBox(0, "g_pinata", "Pinata"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2, e = makeXonoticCheckBoxEx(2, 0, "g_weapon_stay", "Weapons stay"));
	me.TR(me);

	me.gotoRC(me, 0, 2); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 4, makeXonoticTextLabel(0, "Weapon arenas:"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2, e = makeXonoticRadioButton(1, string_null, string_null, "Regular (no arena)"));
	for(i = WEP_FIRST, j = 0; i <= WEP_LAST; ++i)
	{
		w = get_weaponinfo(i);
		if(w.spawnflags & WEP_FLAG_HIDDEN)
			continue;
		if(j & 1 == 0)
			me.TR(me);
		str = w.netname;
		hstr = w.message;
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2, e = makeXonoticRadioButton(1, "g_weaponarena", strzone(str), strzone(hstr)));
			e.cvarOffValue = "0";
			// custom load/save logic that ignores a " laser" suffix, or adds it 
			e.loadCvars = loadCvarsLaserWeaponArenaWeaponButton;
			e.saveCvars = saveCvarsLaserWeaponArenaWeaponButton;
			e.loadCvars(e);
		++j;
	}
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1, e = makeXonoticCheckBox(0, "menu_weaponarena_with_laser", "with laser"));
			// hook the draw function to gray it out
			e.draw_weaponarena = e.draw;
			e.draw = preDrawLaserWeaponArenaLaserButton;
			// hook the save function to notify about the cvar
			e.saveCvars_weaponarena = e.saveCvars;
			e.saveCvars = saveCvarsLaserWeaponArenaLaserButton;
	me.TR(me);
		me.TD(me, 1, 4, makeXonoticTextLabel(0, "Special arenas:"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2, e = makeXonoticRadioButton(1, "g_minstagib", string_null, "MinstaGib"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2, e = makeXonoticRadioButton(1, "g_nix", string_null, "NIX"));
	me.TR(me);
		me.TDempty(me, 0.4);
		me.TD(me, 1, 1, e = makeXonoticCheckBox(0, "g_nix_with_laser", "with laser"));
			setDependent(e, "g_nix", 1, 1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2, e = makeXonoticRadioButton(1, "g_weaponarena", "most", "Most weapons"));
			e.cvarOffValue = "0";
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2, e = makeXonoticRadioButton(1, "g_start_weapon_laser", "0", "No start weapons"));
			e.cvarOffValue = "-1";
			makeMulti(e, "g_start_weapon_shotgun g_start_weapon_uzi g_start_weapon_grenadelauncher g_start_weapon_minelayer g_start_weapon_electro g_start_weapon_crylink g_start_weapon_nex g_start_weapon_hagar g_start_weapon_rocketlauncher g_start_weapon_campingrifle g_start_weapon_hlac g_start_weapon_seeker g_start_weapon_minstanex g_start_weapon_hook g_start_weapon_porto g_start_weapon_tuba");

	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, e = makeXonoticButton("OK", '0 0 0'));
			e.onClick = Dialog_Close;
			e.onClickEntity = me;
}

void XonoticMutatorsDialog_close(entity me)
{
	if(me.refilterEntity)
		me.refilterEntity.refilter(me.refilterEntity);
	SUPER(XonoticMutatorsDialog).close(me);
}
#endif
