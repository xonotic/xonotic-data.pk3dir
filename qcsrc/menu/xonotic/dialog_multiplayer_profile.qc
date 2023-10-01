#include "dialog_multiplayer_profile.qh"

#include "playermodel.qh"
#include "statslist.qh"
#include "languagelist.qh"
#include "textlabel.qh"
#include "commandbutton.qh"
#include "inputbox.qh"
#include "colorpicker.qh"
#include "charmap.qh"
#include "colorbutton.qh"
#include "checkbox.qh"
#include "radiobutton.qh"

#define MENU_CVAR_NAME "_menu_cl_name"
#define MENU_CVAR_COLOR "_menu_cl_color"
#define MENU_CVAR_SKIN "_menu_cl_playerskin"
#define MENU_CVAR_MODEL "_menu_cl_playermodel"

entity makeXonoticProfileTab()
{
	entity me;
	me = NEW(XonoticProfileTab);
	me.configureDialog(me);

	// if color unset, set random color (init it)
	if (cvar_string("_cl_color") == cvar_defstring("_cl_color"))
	{
		// idk what meaning of 16, maybe just COLOR_BUTTONS_COUNT+1
		float randomColor = 16 * floor(random() * COLOR_BUTTONS_COUNT) + floor(random() * COLOR_BUTTONS_COUNT);
		cvar_set("_cl_color", ftos(randomColor));
	}

	return me;
}

void XonoticProfileTab_draw(entity me)
{
	string name = cvar_string("_cl_name");

	if(name == "Player")
		me.playerNameLabel.alpha = ((mod(time * 2, 2) < 1) ? 1 : 0);
	else
		me.playerNameLabel.alpha = me.playerNameLabelAlpha;
	
	// if values changed from console, update it in menu
	if (me.applyButton.disabled)
	{
		// name field
		string inputName  = cvar_string(MENU_CVAR_NAME);
		if (name != inputName)
		{
			cvar_set(MENU_CVAR_NAME, name);
			me.nameInput.loadCvars(me.nameInput);
		}

		// color buttons
		string color = cvar_string("_cl_color");
		string inputColor = cvar_string(MENU_CVAR_COLOR);
		if (color != inputColor)
		{
			cvar_set(MENU_CVAR_COLOR, color);
			for (int i = 0; i < COLOR_BUTTONS_COUNT; i++)
			{
				me.colorButtonGroup1[i].loadCvars(me.colorButtonGroup1[i]);
				me.colorButtonGroup2[i].loadCvars(me.colorButtonGroup2[i]);
			}
		}

		// player model
		string skin = cvar_string("_cl_playerskin");
		string skinInput = cvar_string(MENU_CVAR_SKIN);
		string model = cvar_string("_cl_playermodel");
		string modelInput = cvar_string(MENU_CVAR_MODEL);
		if (skin != skinInput || model != modelInput)
		{
			cvar_set(MENU_CVAR_SKIN, skin);
			cvar_set(MENU_CVAR_MODEL, model);
			me.playerModelSelector.loadCvars(me.playerModelSelector);
			me.playerModelSelector.go(me.playerModelSelector, 0);
		}
	}

	SUPER(XonoticProfileTab).draw(me);
}
void language_selector_click(entity me, entity btn)
{
	localcmd("\nmenu_cmd languageselect\n");
}
void XonoticProfileTab_fill(entity me)
{
	entity e, label;
	float i;
	me.applyButton = makeXonoticCommandButton(_("Apply immediately"), '0 0 0',
		"_cl_color \"$"MENU_CVAR_COLOR"\";"
		"color -1 -1;" // apply colors contained in _cl_color
		"name \"$"MENU_CVAR_NAME"\";"
		"playermodel $"MENU_CVAR_MODEL";"
		"playerskin $"MENU_CVAR_SKIN";"
		, COMMANDBUTTON_APPLY);
	me.applyButton.disableOnClick = true;

	// ==============
	//  NAME SECTION
	// ==============
	me.gotoRC(me, 0.5, 0);
		me.TD(me, 1, 3, me.playerNameLabel = makeXonoticHeaderLabel(_("Name")));

	me.gotoRC(me, 1.5, 0);
		me.TD(me, 1, 3, label = makeXonoticTextLabel(0.5, string_null));
			label.allowCut = 1;
			label.allowColors = 1;
			label.alpha = 1;
			label.isBold = true;
			label.fontSize = SKINFONTSIZE_TITLE;

	me.gotoRC(me, 2.5, 0);
		me.TD(me, 1, 3.0, me.nameInput = makeXonoticInputBox_T(1, MENU_CVAR_NAME,
			_("Name under which you will appear in the game")));
			me.nameInput.forbiddenCharacters = "\r\n\\\"$"; // don't care, isn't getting saved
			me.nameInput.maxLength = -127; // negative means encoded length in bytes
			me.nameInput.saveImmediately = 0;  // Sorry, can't do this, it spams "name" commands.
			me.nameInput.enableClearButton = 0;
			me.nameInput.applyButton = me.applyButton;
			label.textEntity = me.nameInput;
	me.TR(me);
		me.TD(me, 5, 1, e = makeXonoticColorpicker(me.nameInput));
		me.TD(me, 5, 2, e = makeXonoticCharmap(me.nameInput));

	// ===============
	//  MODEL SECTION
	// ===============
	//me.gotoRC(me, 0.5, 3.1); me.setFirstColumn(me, me.currentColumn); // TOP RIGHT
	//me.gotoRC(me, 9, 3.1); me.setFirstColumn(me, me.currentColumn); // BOTTOM RIGHT
	me.gotoRC(me, 9, 0); me.setFirstColumn(me, me.currentColumn); // BOTTOM LEFT
		me.TD(me, 1, 3, e = makeXonoticHeaderLabel(_("Model")));

	me.TR(me);
		//me.TDempty(me, 0); // MODEL LEFT, COLOR RIGHT
		me.TDempty(me, 1); // MODEL RIGHT, COLOR LEFT
		me.playerModelSelector = makeXonoticPlayerModelSelector(MENU_CVAR_SKIN, MENU_CVAR_MODEL);
		me.TD(me, 1, 0.3, e = makeXonoticButton("<<", '0 0 0'));
			e.onClick = PlayerModelSelector_Prev_Click;
			e.onClickEntity = me.playerModelSelector;
			e.applyButton = me.applyButton;
		me.TD(me, 11.5, 1.4, me.playerModelSelector);
		me.TD(me, 1, 0.3, e = makeXonoticButton(">>", '0 0 0'));
			e.onClick = PlayerModelSelector_Next_Click;
			e.onClickEntity = me.playerModelSelector;
			e.applyButton = me.applyButton;

	//me.setFirstColumn(me, me.currentColumn + 2); // MODEL LEFT, COLOR RIGHT
	me.gotoRC(me, me.currentRow, 0); me.setFirstColumn(me, me.currentColumn); // MODEL RIGHT, COLOR LEFT
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticHeaderLabel(_("Glowing color")));
		for(i = 0; i < COLOR_BUTTONS_COUNT; ++i)
		{
			if(mod(i, 5) == 0)
				me.TR(me);
			me.TDNoMargin(me, 1, 0.2, me.colorButtonGroup1[i] = makeXonoticColorButton(MENU_CVAR_COLOR, 1, 0, i), '0 1 0');
				me.colorButtonGroup1[i].applyButton = me.applyButton;
		}
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticHeaderLabel(_("Detail color")));
		for(i = 0; i < COLOR_BUTTONS_COUNT; ++i)
		{
			if(mod(i, 5) == 0)
				me.TR(me);
			me.TDNoMargin(me, 1, 0.2, me.colorButtonGroup2[i] = makeXonoticColorButton(MENU_CVAR_COLOR, 2, 1, i), '0 1 0');
				me.colorButtonGroup2[i].applyButton = me.applyButton;
		}

	// ====================
	//  STATISTICS SECTION
	// ====================
	me.gotoRC(me, 0.5, 3.1); me.setFirstColumn(me, me.currentColumn); // TOP RIGHT
	//me.gotoRC(me, 9, 3.1); me.setFirstColumn(me, me.currentColumn); // BOTTOM RIGHT
	//me.gotoRC(me, 9, 0); me.setFirstColumn(me, me.currentColumn); // BOTTOM LEFT
		me.TD(me, 1, 3, e = makeXonoticHeaderLabel(_("Statistics")));

	me.TR(me);
		me.TDempty(me, 0.25);
		me.TD(me, 1, 2.5, e = makeXonoticCheckBox(0, "cl_allow_uidtracking", _("Allow player statistics to track your client")));
			e.sendCvars = true;
	me.TR(me);
		me.TDempty(me, 0.25);
		me.TD(me, 1, 2.5, e = makeXonoticCheckBox(0, "cl_allow_uid2name", _("Allow player statistics to use your nickname")));
			e.sendCvars = true;
			setDependent(e, "cl_allow_uidtracking", 1, 1);
	me.TR(me);
		me.TDempty(me, 0.25);
		me.TD(me, 1, 2.5, e = makeXonoticCheckBox(0, "cl_allow_uidranking", _("Allow player statistics to rank you in leaderboards")));
			e.sendCvars = true;
			setDependent(e, "cl_allow_uidtracking", 1, 1);
	me.gotoRC(me, 4.5, 3.1); // TOP RIGHT
	//me.gotoRC(me, 12.5, 3.1); // BOTTOM RIGHT
	//me.gotoRC(me, 12.5, 0); // BOTTOM LEFT
		me.TDempty(me, 0.25);
		me.TD(me, 9, 2.5, statslist = makeXonoticStatsList());
		//setDependent(statslist, "cl_allow_uidtracking", 1, 1);

	// =================
	//  COUNTRY SECTION
	// =================
	me.gotoRC(me, 16, 3.1); me.setFirstColumn(me, me.currentColumn); // BOTTOM SECTION, TOP POS
	//me.gotoRC(me, 13.5, 3.1); me.setFirstColumn(me, me.currentColumn); // BOTTOM SECTION, TOP POS
	//me.gotoRC(me, 0.5, 3.1); me.setFirstColumn(me, me.currentColumn); // TOP SECTION, TOP POS
		//me.TD(me, 1, 3, e = makeXonoticHeaderLabel(_("Country")));

	me.TR(me);
		me.TDempty(me, 0.75);
		me.TD(me, 1, 1.5, e = makeXonoticButton(_("Select language..."), '0 0 0'));
			e.onClick = language_selector_click;
			e.onClickEntity = me;
		/*
		me.TDempty(me, 0.5);
		me.TD(me, 4.5, 2, e = makeXonoticLanguageList()); // todo: cl_country: create proper country list
		*/

	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, me.applyButton);
}
