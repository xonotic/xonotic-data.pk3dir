#include "dialog_multiplayer_join_termsofservice.qh"

#include "textbox.qh"
#include <lib/urllib.qh>


entity makeXonoticServerToSTab()
{
	entity me;
	me = NEW(XonoticServerToSTab);
	me.configureDialog(me);
	return me;
}

void XonoticServerToSTab_loadToS(entity me, string downloadurl)
{
	url_single_fopen(downloadurl, FILE_READ, AdditionalServerInfo_OnGet, me);
}

void XonoticServerToSTab_fill(entity me)
{
	entity e;
	me.TR(me);
	me.TD(me, me.rows, me.columns, e = me.textBox = makeXonoticTextBox());
		e.allowColors = true;
}

void AdditionalServerInfo_OnGet(entity fh, entity me, int status)
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
