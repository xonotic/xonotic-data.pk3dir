#include "dialog_termsofservice.qh"

#include "../menu.qh"
#include "mainwindow.qh"
#include "dialog_firstrun.qh"
#include "textbox.qh"
#include "textlabel.qh"
#include "button.qh"

void Close_Clicked(entity btn, entity me)
{
    cvar_set("_termsofservice_accepted", "1");
    localcmd("saveconfig");
    if (main.firstRunDialog.shouldShow())
    {
        main.dialogToShow = main.firstRunDialog;
    }
    Dialog_Close(btn, me);
}

void DontAccept_Clicked(entity btn, entity me)
{
    localcmd("quit");
}

void XonoticToSDialog_loadXonoticToS(entity me)
{
    string ToSText = "";
    int fh = fopen("tos.txt", FILE_READ);
    if (fh >= 0)
    {
        for (string line; (line = fgets(fh)); ) {
            if (ToSText != "")
            {
                ToSText = strcat(ToSText, "\n", line);
            }
            else
            {
                ToSText = line;
            }
        }
        fclose(fh);
    }
    me.textBox.setText(me.textBox, ToSText);
}

bool XonoticToSDialog_shouldShow()
{
    return (fexists("tos.txt") && !autocvar__termsofservice_accepted);
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

