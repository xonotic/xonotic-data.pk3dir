#include "checkbox_string.qh"

entity makeXonoticCheckBoxString(string theYesValue, string theNoValue, string theCvar, string theText)
{
	entity me;
	me = NEW(XonoticCheckBoxString);
	me.configureXonoticCheckBoxString(me, theYesValue, theNoValue, theCvar, theText);
	return me;
}
void XonoticCheckBoxString_configureXonoticCheckBoxString(entity me, string theYesValue, string theNoValue, string theCvar, string theText)
{
	me.yesString = theYesValue;
	me.noString = theNoValue;
	me.checked = 0;
	me.cvarName = (theCvar) ? theCvar : string_null;
	me.loadCvars(me);
	me.configureCheckBox(me, theText, me.fontSize, me.image);
}
void XonoticCheckBoxString_setChecked(entity me, float foo)
{
	me.checked = !me.checked;
	me.saveCvars(me);
}
void XonoticCheckBoxString_loadCvars(entity me)
{
	if (!me.cvarName)
		return;

	if(cvar_string(me.cvarName) == me.yesString)
		me.checked = 1;
}
void XonoticCheckBoxString_saveCvars(entity me)
{
	if (!me.cvarName)
		return;

	if(me.checked)
		cvar_set(me.cvarName, me.yesString);
	else
		cvar_set(me.cvarName, me.noString);

	CheckSendCvars(me, me.cvarName);
}
