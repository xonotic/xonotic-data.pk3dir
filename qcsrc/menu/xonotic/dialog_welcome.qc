#include "dialog_welcome.qh"

#include "image.qh"
#include "textlabel.qh"
#include "textbox.qh"
#include "radiobutton.qh"
#include "commandbutton.qh"
#include "slider.qh"
#include <common/campaign_common.qh>

void welcomeDialog_resetStrings(entity me)
{
	strcpy(me.serverinfo_name, _("Welcome"));
	strcpy(me.serverinfo_MOTD, "");
}

float XonoticWelcomeDialog_keyDown(entity me, float key, float ascii, float shift)
{
	switch(key)
	{
		case K_KP_ENTER:
		case K_ENTER:
		case K_SPACE:
			XonoticCommandButton_Click(me.joinButton_ent, me);
			return true;
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
		else if(s == "CAMPAIGN")
		{
			strcpy(me.serverinfo_name, campaign_title);

			int level = stoi(bufstr_get(argsbuf, ++i)) - 1;
			string campaign_msg;
			if (level < 0 || level >= campaign_entries)
				campaign_msg = strcat("^1Error: invalid level number ", itos(level + 1));
			else
			{
				string desc = strcat(campaign_shortdesc[level], "\n\n", campaign_longdesc[level]);
				desc = strreplace("\n", "\\n", desc);
				campaign_msg = strreplace("_LEVEL_DESC", desc, bufstr_get(argsbuf, ++i));
			}
			strcpy(me.serverinfo_MOTD, campaign_msg);
			break;
		}
		else if(s == "RESET")
		{
			welcomeDialog_resetStrings(me);
			break;
		}
		++i;
	}
	//me.serverinfo_name_ent.setText(me.serverinfo_name_ent, me.serverinfo_name);
	me.serverinfo_MOTD_ent.setText(me.serverinfo_MOTD_ent, me.serverinfo_MOTD);
	me.frame.setText(me.frame, me.serverinfo_name);
}

void XonoticWelcomeDialog_draw(entity me)
{
	SUPER(XonoticWelcomeDialog).draw(me);

	if (!(gamestatus & (GAME_ISSERVER | GAME_CONNECTED)))
		me.close(me);

	if(me.serverinfo_MOTD == "" && (gamestatus & (GAME_CONNECTED | GAME_ISSERVER)))
	{
		// if serverinfo_MOTD is empty while connected it means we are connected to an old server
		// in this case show the csqc welcome message and instantly close the dialog
		localcmd("\n+show_info0; defer 2 -show_info0\n");
		me.close(me);
	}

	if (isdemo())
	{
		me.joinButton_ent.disabled = true;
		me.spectateButton_ent.disabled = true;
	}
	else
	{
		me.joinButton_ent.disabled = false;
		me.spectateButton_ent.disabled = false;
	}
}

void XonoticWelcomeDialog_fill(entity me)
{
	registercvar("_menu_welcome_dialog_available", "0", 0);
	cvar_set("_menu_welcome_dialog_available", "1");

	me.frame.allowColors = true; // allow color codes in the title

	entity e;

	me.TR(me);
		me.TD(me, me.rows - 1, me.columns, me.serverinfo_MOTD_ent = makeXonoticTextBox());
			me.serverinfo_MOTD_ent.align = 0.5;
			me.serverinfo_MOTD_ent.allowColors = true;
			me.serverinfo_MOTD_ent.escapedNewLines = true;
	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns / 2, me.joinButton_ent = makeXonoticCommandButton(_("Join"), '0 1 0', "cmd join", COMMANDBUTTON_CLOSE));
			me.joinButton_ent.preferredFocusPriority = 1;
		me.TD(me, 1, me.columns / 2, me.spectateButton_ent = makeXonoticCommandButton(_("Spectate"), '0 0 0', "cmd spectate", COMMANDBUTTON_CLOSE));
}
