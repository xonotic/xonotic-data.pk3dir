#include "dialog_welcome.qh"

#include "image.qh"
#include "textlabel.qh"
#include "textbox.qh"
#include "radiobutton.qh"
#include "commandbutton.qh"
#include "slider.qh"
#include "util.qh"


void welcomeDialog_resetStrings(entity me)
{
	strcpy(me.serverinfo_name, _("Welcome"));
	strcpy(me.serverinfo_MOTD, "");
}

float XonoticWelcomeDialog_keyDown(entity me, float key, float ascii, float shift)
{
	switch(key)
	{
		//case K_KP_ENTER:
		//case K_ENTER:
		//case K_SPACE:
		//	me.close(me);
		//	return true;
		default:
			return SUPER(XonoticWelcomeDialog).keyDown(me, key, ascii, shift);
	}
}

// the same implentation in mousePress apparently works, but for some reason if you try to open
// the dialog again it doesn't show up and requires opening it a seconds time to show up
bool XonoticWelcomeDialog_mouseRelease(entity me, vector pos)
{
	if (pos.x >= 0 && pos.y >= 0 && pos.x < 1 && pos.y < 1)
	{
		return SUPER(XonoticWelcomeDialog).mouseRelease(me, pos);
	}
	me.close(me);
	return true;
}

void XonoticWelcomeDialog_destroy(entity me)
{
	cvar_set("_menu_welcome_dialog_available", "0");
}

void XonoticWelcomeDialog_readInputArgs(entity me, int argsbuf)
{
	int i = 0;
	string s;
	welcomeDialog_resetStrings(me);
	if(argsbuf >= 0)
	while((s = bufstr_get(argsbuf, i)) != "")
	{
		if(s == "HOSTNAME")
			strcpy(me.serverinfo_name, bufstr_get(argsbuf, ++i));
		else if(s == "WELCOME")
			strcpy(me.serverinfo_MOTD, bufstr_get(argsbuf, ++i));
		else if(s == "RESET")
		{
			welcomeDialog_resetStrings(me);
			break;
		}
		++i;
	}
	me.serverinfo_name_ent.setText(me.serverinfo_name_ent, me.serverinfo_name);
	me.serverinfo_MOTD_ent.setText(me.serverinfo_MOTD_ent, me.serverinfo_MOTD);
	me.frame.setText(me.frame, "Welcome to Xonotic git");
}

void XonoticWelcomeDialog_showNotify(entity me)
{
	SUPER(XonoticWelcomeDialog).showNotify(me);
	float teams, nTeams;
	teams = cvar("_teams_available");
	nTeams = 0;
	me.team1.disabled = !(teams & 1); nTeams += boolean(teams & 1);
	me.team2.disabled = !(teams & 2); nTeams += boolean(teams & 2);
	me.team3.disabled = !(teams & 4); nTeams += boolean(teams & 4);
	me.team4.disabled = !(teams & 8); nTeams += boolean(teams & 8);
}

void XonoticWelcomeDialog_draw(entity me)
{
	SUPER(XonoticWelcomeDialog).draw(me);
	if(me.serverinfo_MOTD == "" && gamestatus & (GAME_CONNECTED | GAME_ISSERVER))
	{
		// if serverinfo_MOTD is empty while connected it means we are connected to an old server
		// in this case show the csqc welcome message and instantly close the dialog
		localcmd("\n+show_info0; defer 2 -show_info0\n");
		me.close(me);
	}
}

void XonoticWelcomeDialog_fill(entity me)
{
	registercvar("_menu_welcome_dialog_available", "0", 0);
	cvar_set("_menu_welcome_dialog_available", "1");

	me.frame.allowColors = true; // allow color codes in the title

	entity e;

	me.TR(me);
		me.TD(me, 1, me.columns, me.serverinfo_name_ent = makeXonoticHeaderLabel("Server"));
		me.serverinfo_name_ent.allowColors = true;
	me.TR(me);
		me.TD(me, 2, 1, makeXonoticImage("/gfx/menu/luma/gametype_ca", 1));
		me.TD(me, 1, 3, makeXonoticTextLabel(0, "Game type: Clan Arena"));
	me.TR(me);
		me.TDempty(me, 1);
		me.TD(me, 1, 4, makeXonoticTextLabel(0, "Players: 4/24 (Warmup)"));
	me.TR(me);
		me.TD(me, 1, 2, makeXonoticTextLabel(0, "Frag limit: 0"));
	me.TR(me);
		me.TD(me, 1, 4, makeXonoticTextLabel(0, "Time limit: 10"));
	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticTextLabel(0, "Active modifications: Test\nNew line test"));
		e.escapedNewLines = true;
	me.TR(me);
	me.TR(me);
		me.TD(me, 2, 4, e = makeTeamButton_T(_("join"), '0 0 0', "cmd selectteam auto; cmd join",
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
		me.TD(me, 1, 4, makeXonoticCommandButton(_("spectate"), '0 0 0', "cmd spectate", COMMANDBUTTON_CLOSE));

	me.gotoRC(me, 1, 4);
		me.TD(me, me.rows - 1, 4, me.serverinfo_MOTD_ent = makeXonoticTextBox());
			me.serverinfo_MOTD_ent.align = 0.5;
			me.serverinfo_MOTD_ent.allowColors = true;
			me.serverinfo_MOTD_ent.escapedNewLines = true;
	/*me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, e = makeXonoticButton(_("OK"), '0 0 0'));
			e.onClick = Dialog_Close;
			e.onClickEntity = me;
			e.preferredFocusPriority = 1;*/
}
