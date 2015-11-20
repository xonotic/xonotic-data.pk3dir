#ifndef DIALOG_MULTIPLAYER_PROFILE_H
#define DIALOG_MULTIPLAYER_PROFILE_H
#include "tab.qc"
CLASS(XonoticProfileTab, XonoticTab)
	METHOD(XonoticProfileTab, fill, void(entity));
	METHOD(XonoticProfileTab, draw, void(entity));
	ATTRIB(XonoticProfileTab, intendedWidth, float, 0.9)
	ATTRIB(XonoticProfileTab, rows, float, 23)
	ATTRIB(XonoticProfileTab, columns, float, 6.1) // added extra .2 for center space
	ATTRIB(XonoticProfileTab, playerNameLabel, entity, NULL)
	ATTRIB(XonoticProfileTab, playerNameLabelAlpha, float, SKINALPHA_HEADER)
ENDCLASS(XonoticProfileTab)
entity makeXonoticProfileTab();
#endif

#ifdef IMPLEMENTATION
entity makeXonoticProfileTab()
{
	entity me;
	me = NEW(XonoticProfileTab);
	me.configureDialog(me);
	return me;
}
void XonoticProfileTab_draw(entity me)
{
	if(cvar_string("_cl_name") == "Player")
		me.playerNameLabel.alpha = ((mod(time * 2, 2) < 1) ? 1 : 0);
	else
		me.playerNameLabel.alpha = me.playerNameLabelAlpha;
	SUPER(XonoticProfileTab).draw(me);
}
void XonoticProfileTab_fill(entity me)
{
	entity e, pms, label, box;
	float i;

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
		me.TD(me, 1, 3.0, box = makeXonoticInputBox_T(1, "_cl_name",
			_("Name under which you will appear in the game")));
			box.forbiddenCharacters = "\r\n\\\"$"; // don't care, isn't getting saved
			box.maxLength = -127; // negative means encoded length in bytes
			box.saveImmediately = 0;  // Sorry, can't do this, it spams "name" commands.
			box.enableClearButton = 0;
			label.textEntity = box;
	me.TR(me);
		me.TD(me, 5, 1, e = makeXonoticColorpicker(box));
		me.TD(me, 5, 2, e = makeXonoticCharmap(box));

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
		pms = makeXonoticPlayerModelSelector();
		me.TD(me, 1, 0.3, e = makeXonoticButton("<<", '0 0 0'));
			e.onClick = PlayerModelSelector_Prev_Click;
			e.onClickEntity = pms;
		me.TD(me, 11.5, 1.4, pms);
		me.TD(me, 1, 0.3, e = makeXonoticButton(">>", '0 0 0'));
			e.onClick = PlayerModelSelector_Next_Click;
			e.onClickEntity = pms;

	//me.setFirstColumn(me, me.currentColumn + 2); // MODEL LEFT, COLOR RIGHT
	me.gotoRC(me, me.currentRow, 0); me.setFirstColumn(me, me.currentColumn); // MODEL RIGHT, COLOR LEFT
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticHeaderLabel(_("Glowing color")));
		for(i = 0; i < 15; ++i)
		{
			if(mod(i, 5) == 0)
				me.TR(me);
			me.TDNoMargin(me, 1, 0.2, e = makeXonoticColorButton(1, 0, i), '0 1 0');
		}
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticHeaderLabel(_("Detail color")));
		for(i = 0; i < 15; ++i)
		{
			if(mod(i, 5) == 0)
				me.TR(me);
			me.TDNoMargin(me, 1, 0.2, e = makeXonoticColorButton(2, 1, i), '0 1 0');
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
	me.TR(me);
		me.TDempty(me, 0.25);
		me.TD(me, 1, 2.5, e = makeXonoticCheckBox(0, "cl_allow_uid2name", _("Allow player statistics to use your nickname")));
		setDependent(e, "cl_allow_uidtracking", 1, 1);
	me.gotoRC(me, 4, 3.1); // TOP RIGHT
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
		me.TD(me, 1, 3, e = makeXonoticHeaderLabel(_("Country")));

	me.TR(me);
		me.TDempty(me, 0.5);
		me.TD(me, 4.5, 2, e = makeXonoticLanguageList()); // todo: cl_country: create proper country list


	// ================
	//  GENDER SECTION
	// ================
	me.gotoRC(me, 13.5, 3.1); me.setFirstColumn(me, me.currentColumn); // BOTTOM SECTION, TOP POS
	//me.gotoRC(me, 19.5, 3.1); me.setFirstColumn(me, me.currentColumn); // BOTTOM SECTION, BOTTOM POS
	//me.gotoRC(me, 6.5, 3.1); me.setFirstColumn(me, me.currentColumn); // TOP SECTION, BOTTOM POS
	#if 0
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Gender:")));
		me.TD(me, 1, 2, e = makeXonoticTextSlider("_cl_gender"));
			e.addValue(e, _("Undisclosed"), "0");
			e.addValue(e, _("Female"), "1");
			e.addValue(e, _("Male"), "2");
			e.configureXonoticTextSliderValues(e);
	#else
			me.TD(me, 1, 3, e = makeXonoticHeaderLabel(_("Gender")));
		me.TR(me);
			#define GENDERWIDTH_OFFSET 0.25
			#define GENDERWIDTH_LENGTH 2.5
			#define GENDERWIDTH_ITEM (GENDERWIDTH_LENGTH / 3)
			me.TDempty(me, GENDERWIDTH_OFFSET);
			me.TD(me, 1, GENDERWIDTH_ITEM, e = makeXonoticRadioButton(3, "_cl_gender", "2", _("Female")));
			me.TD(me, 1, GENDERWIDTH_ITEM, e = makeXonoticRadioButton(3, "_cl_gender", "1", _("Male")));
			me.TD(me, 1, GENDERWIDTH_ITEM, e = makeXonoticRadioButton(3, "_cl_gender", "0", _("Undisclosed")));
	#endif

	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, makeXonoticCommandButton(_("Apply immediately"), '0 0 0', "color -1 -1;name \"$_cl_name\";sendcvar cl_autoswitch;sendcvar cl_forceplayermodels;sendcvar cl_forceplayermodelsfromxonotic;playermodel $_cl_playermodel;playerskin $_cl_playerskin", COMMANDBUTTON_APPLY));
}
#endif
