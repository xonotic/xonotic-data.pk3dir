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
	LOG_INFO("Setting _termsofservice_accepted cvar to ", _Nex_ExtResponseSystem_NewToS);
    cvar_set("_termsofservice_accepted", _Nex_ExtResponseSystem_NewToS);
    localcmd("saveconfig");
    if (main.firstRunDialog.shouldShow())
		main.firstDraw = true;
    Dialog_Close(btn, me);
}

void DontAccept_Clicked(entity btn, entity me)
{
    localcmd("quit");
}

void XonoticToSDialog_loadXonoticToS(entity me)
{
	string downloadurl = "http://maria.omaera.org/tos.txt";
	url_single_fopen(downloadurl, FILE_READ, XonoticToS_OnGet, me);
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
            me.text = strzone("Error reading ToS");
            me.textBox.setText(me.textBox, me.text);
            break;
        }
		case URL_READY_CANREAD:
		{
            strfree(me.text);
            string temp = "";
			for (string s; (s = url_fgets(fh)); )
			{
                if (temp != "")
                {
				    temp = strcat(temp, "\n", s);
                }
                else
                {
                    temp = s;
                }
			}
			url_fclose(fh);
            me.text = strzone(temp);
            me.textBox.setText(me.textBox, me.text);
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
	LOG_INFO("newtos value: ", _Nex_ExtResponseSystem_NewToS);
	return (_Nex_ExtResponseSystem_NewToS != "" && _Nex_ExtResponseSystem_NewToS != autocvar__termsofservice_accepted);
}

void XonoticToSDialog_fill(entity me)
{
	entity e;

	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticTextLabel(0, _("Welcome to Xonotic! Please read the following Terms of Service")));
		e.allowWrap = 1;

    me.TR(me);
	me.TR(me);
		me.TD(me, me.rows - 4, me.columns, me.textBox = makeXonoticTextBox());
        me.loadXonoticToS(me);

    me.TR(me);
	me.gotoRC(me, me.rows - 1, 0);
        me.TD(me, 1, me.columns/2, e = makeXonoticButton(_("Accept"), '0 0 0'));
            e.onClick = Close_Clicked;
            e.onClickEntity = me;
        me.TD(me, 1, me.columns/2, e = makeXonoticButton(_("Don't accept (quit the game)"), '0 0 0'));
            e.onClick = DontAccept_Clicked;
            e.onClickEntity = me;
}

