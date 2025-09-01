#include "dialog_termsofservice.qh"

#include "../menu.qh"
#include "mainwindow.qh"
#include "dialog_firstrun.qh"
#include "textbox.qh"
#include "textlabel.qh"
#include "button.qh"
#include "util.qh"

void Close_Clicked(entity btn, entity me)
{
	LOG_INFOF("Accepted ToS version %d", _Nex_ExtResponseSystem_NewToS);
	cvar_set("_termsofservice_accepted", ftos(_Nex_ExtResponseSystem_NewToS));
	localcmd("saveconfig\n");
	if (main.firstRunDialog.shouldShow())
		main.firstDraw = true;
	Dialog_Close(btn, me);
}

void DontAccept_Clicked(entity btn, entity me)
{
	localcmd("quit\n");
}

void XonoticToSDialog_loadXonoticToS(entity me)
{
	url_single_fopen(termsofservice_url, FILE_READ, XonoticToS_OnGet, me);
}

void XonoticToS_OnGet(entity fh, entity me, int status)
{
	switch (status) {
		case URL_READY_CLOSED:
		{
			break;
		}
		case URL_READY_ERROR:
		{
			me.textBox.setText(me.textBox, "Error reading ToS");
			break;
		}
		case URL_READY_CANREAD:
		{
			string temp = "";
			for (string s; (s = url_fgets(fh)); )
			{
				if (temp != "")
					temp = strcat(temp, "\n", s);
				else
					temp = s;
			}
			url_fclose(fh);
			me.textBox.setText(me.textBox, temp);
			break;
		}
		default:
		{
			break;
		}
	}
}

bool XonoticToSDialog_shouldShow()
{
	return (_Nex_ExtResponseSystem_NewToS && _Nex_ExtResponseSystem_NewToS > autocvar__termsofservice_accepted);
}

void XonoticToSDialog_fill(entity me)
{
	entity e;
	string subtitle;

	if (autocvar__termsofservice_accepted > 0)
		subtitle = _("Terms of Service have been updated. Please read them before continuing:");
	else
		subtitle = _("Welcome to Xonotic! Please read the following Terms of Service:");

	me.TR(me);
		me.TD(me, 1, 5, e = makeXonoticTextLabel(0, subtitle));
			e.allowWrap = true;

	me.TR(me);
	me.TR(me);
		me.TD(me, me.rows - 4, me.columns, me.textBox = makeXonoticTextBox());
			me.textBox.allowColors = true;

	me.TR(me);
	me.gotoRC(me, me.rows - 1, 0);

		me.TD(me, 1, me.columns/2, e = makeXonoticButton(_("Accept"), '0 1 0'));
		e.onClick = Close_Clicked;
		e.onClickEntity = me;

		me.TD(me, 1, me.columns/2, e = makeXonoticButton(_("Don't accept (quit the game)"), '1 0 0'));
		e.onClick = DontAccept_Clicked;
		e.onClickEntity = me;
}

