#include "weaponarenacheckbox.qh"

entity makeXonoticWeaponarenaCheckBox(string theWeapon, string theText)
{
	entity me;
	me = NEW(XonoticWeaponarenaCheckBox);
	me.configureXonoticWeaponarenaCheckBox(me, theWeapon, theText);
	return me;
}
void XonoticWeaponarenaCheckBox_configureXonoticWeaponarenaCheckBox(entity me, string theWeapon, string theText)
{
	me.netname = theWeapon;
	me.checked = false;
	me.loadCvars(me);
	me.configureCheckBox(me, theText, me.fontSize, me.image);
}
void XonoticWeaponarenaCheckBox_setChecked(entity me, bool foo)
{
	me.checked = !me.checked;
	me.saveCvars(me);
}
void XonoticWeaponarenaCheckBox_loadCvars(entity me)
{
	int n = tokenize_console(cvar_string("menu_weaponarena"));
	for (int i = 0; i < n; ++i)
	{
		if(argv(i) == me.netname)
		{
			me.checked = true;
			break;
		}
	}
}

void XonoticWeaponarenaCheckBox_saveCvars(entity me)
{
	if(me.checked)
		localcmd(strcat("\nmenu_cmd addtolist menu_weaponarena ", me.netname, "\n"));
	else
		localcmd(strcat("\nmenu_cmd removefromlist menu_weaponarena ", me.netname, "\n"));
	localcmd("\ng_weaponarena \"$menu_weaponarena\"\n");
}
