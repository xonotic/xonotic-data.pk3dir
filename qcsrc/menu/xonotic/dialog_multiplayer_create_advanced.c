#ifdef INTERFACE
CLASS(XonoticAdvancedDialog) EXTENDS(XonoticDialog)
	METHOD(XonoticAdvancedDialog, fill, void(entity))
	METHOD(XonoticAdvancedDialog, showNotify, void(entity))
	METHOD(XonoticAdvancedDialog, close, void(entity))
	ATTRIB(XonoticAdvancedDialog, title, string, "Advanced server settings")
	ATTRIB(XonoticAdvancedDialog, color, vector, SKINCOLOR_DIALOG_ADVANCED)
	ATTRIB(XonoticAdvancedDialog, intendedWidth, float, 0.5)
	ATTRIB(XonoticAdvancedDialog, rows, float, 13)
	ATTRIB(XonoticAdvancedDialog, columns, float, 3)
	ATTRIB(XonoticAdvancedDialog, refilterEntity, entity, NULL)
ENDCLASS(XonoticAdvancedDialog)
#endif

#ifdef IMPLEMENTATION
void XonoticAdvancedDialog_showNotify(entity me)
{
	loadAllCvars(me);
}

void XonoticAdvancedDialog_fill(entity me)
{
	entity e;
	me.TR(me);
		me.TD(me, 1, 1.2, makeXonoticTextLabel(0, "Game settings:"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticCheckBox(0, "sv_spectate", "Allow spectating"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, "Spawn shield:"));
		me.TD(me, 1, 1.7, e = makeXonoticSlider(0, 15, 0.5, "g_spawnshieldtime"));
	me.TR(me);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, "Game speed:"));
		me.TD(me, 1, 1.7, e = makeXonoticSlider(0.5, 2.0, 0.1, "slowmo"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticCheckBoxEx(2, 0, "g_antilag", "AntiLag"));
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1.2, makeXonoticTextLabel(0, "Teamplay settings:"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, "Friendly fire scale:"));
		me.TD(me, 1, 1.7, e = makeXonoticSlider(0, 1.0, 0.05, "g_friendlyfire"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, "Friendly fire penalty:"));
		me.TD(me, 1, 1.7, e = makeXonoticSlider(0, 1.0, 0.05, "g_mirrordamage"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, "Teams:"));
		me.TD(me, 1, 1.7, e = makeXonoticTextSlider("g_tdm_teams_override g_domination_teams_override g_keyhunt_teams_override"));
			e.addValue(e, "Default", "0");
			e.addValue(e, "2 teams", "2");
			e.addValue(e, "3 teams", "3");
			e.addValue(e, "4 teams", "4");
			e.configureXonoticTextSliderValues(e);

	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, e = makeXonoticButton("OK", '0 0 0'));
			e.onClick = Dialog_Close;
			e.onClickEntity = me;
}

void XonoticAdvancedDialog_close(entity me)
{
	if(me.refilterEntity)
		me.refilterEntity.refilter(me.refilterEntity);
	SUPER(XonoticAdvancedDialog).close(me);
}
#endif
