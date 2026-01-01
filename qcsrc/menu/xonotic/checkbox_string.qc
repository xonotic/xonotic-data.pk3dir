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
	me.checked = false;
	me.controlledCvar = (theCvar) ? theCvar : string_null;
	me.loadCvars(me);
	me.configureCheckBox(me, theText, me.fontSize, me.image);
}
void XonoticCheckBoxString_setChecked(entity me, bool foo)
{
	me.checked = !me.checked;
	me.saveCvars(me);
}
void XonoticCheckBoxString_loadCvars(entity me)
{
	if (!me.controlledCvar)
		return;

	if(cvar_string(me.controlledCvar) == me.yesString)
		me.checked = true;
}
void XonoticCheckBoxString_saveCvars(entity me)
{
	if (!me.controlledCvar)
		return;

	if(me.checked)
		cvar_set(me.controlledCvar, me.yesString);
	else
		cvar_set(me.controlledCvar, me.noString);

	CheckSendCvars(me, me.controlledCvar);
}
