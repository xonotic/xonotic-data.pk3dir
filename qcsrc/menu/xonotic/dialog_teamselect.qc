#ifndef DIALOG_TEAMSELECT_H
#define DIALOG_TEAMSELECT_H
#include "rootdialog.qc"
CLASS(XonoticTeamSelectDialog, XonoticRootDialog)
	METHOD(XonoticTeamSelectDialog, fill, void(entity)); // to be overridden by user to fill the dialog with controls
	METHOD(XonoticTeamSelectDialog, showNotify, void(entity));
	ATTRIB(XonoticTeamSelectDialog, title, string, _("Team Selection")) // ;)
	ATTRIB(XonoticTeamSelectDialog, color, vector, SKINCOLOR_DIALOG_TEAMSELECT)
	ATTRIB(XonoticTeamSelectDialog, intendedWidth, float, 0.4)
	ATTRIB(XonoticTeamSelectDialog, rows, float, 5)
	ATTRIB(XonoticTeamSelectDialog, columns, float, 4)
	ATTRIB(XonoticTeamSelectDialog, name, string, "TeamSelect")
	ATTRIB(XonoticTeamSelectDialog, team1, entity, NULL)
	ATTRIB(XonoticTeamSelectDialog, team2, entity, NULL)
	ATTRIB(XonoticTeamSelectDialog, team3, entity, NULL)
	ATTRIB(XonoticTeamSelectDialog, team4, entity, NULL)
	ATTRIB(XonoticTeamSelectDialog, requiresConnection, float, true)
ENDCLASS(XonoticTeamSelectDialog)
#endif

#ifdef IMPLEMENTATION
entity makeTeamButton_T(string theName, vector theColor, string commandtheName, string theTooltip)
{
	entity b;
	b = makeXonoticBigCommandButton_T(theName, theColor, commandtheName, 1, theTooltip);
	return b;
}
entity makeTeamButton(string theName, vector theColor, string commandtheName)
{
	return makeTeamButton_T(theName, theColor, commandtheName, string_null);
}

void XonoticTeamSelectDialog_showNotify(entity me)
{
	float teams, nTeams;
	teams = cvar("_teams_available");
	nTeams = 0;
	me.team1.disabled = !(teams & 1); nTeams += boolean(teams & 1);
	me.team2.disabled = !(teams & 2); nTeams += boolean(teams & 2);
	me.team3.disabled = !(teams & 4); nTeams += boolean(teams & 4);
	me.team4.disabled = !(teams & 8); nTeams += boolean(teams & 8);
}

void XonoticTeamSelectDialog_fill(entity me)
{
	entity e;
	me.TR(me);
		me.TD(me, 2, 4, e = makeTeamButton_T(_("join 'best' team (auto-select)"), '0 0 0', "cmd selectteam auto; cmd join",
			_("Autoselect team (recommended)")));
			e.preferredFocusPriority = 1;
	me.TR(me);
	me.TR(me);
		me.TD(me, 2, 1, e = me.team1 = makeTeamButton(_("red"), '1 0.5 0.5', "cmd selectteam red; cmd join"));
		me.TD(me, 2, 1, e = me.team2 = makeTeamButton(_("blue"), '0.5 0.5 1', "cmd selectteam blue; cmd join"));
		me.TD(me, 2, 1, e = me.team3 = makeTeamButton(_("yellow"), '1 1 0.5', "cmd selectteam yellow; cmd join"));
		me.TD(me, 2, 1, e = me.team4 = makeTeamButton(_("pink"), '1 0.5 1', "cmd selectteam pink; cmd join"));
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 4, makeXonoticCommandButton(_("spectate"), '0 0 0', "cmd spectate", 1));
}
#endif

/* Click. The c-word is here so you can grep for it :-) */
