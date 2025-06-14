#include "inputbox.qh"

entity makeXonoticInputBox_T(bool doEditColorCodes, string theCvar, string theTooltip)
{
	entity me;
	me = NEW(XonoticInputBox);
	me.configureXonoticInputBox(me, doEditColorCodes, theCvar, theTooltip);
	return me;
}
entity makeXonoticInputBox(bool doEditColorCodes, string theCvar)
{
	return makeXonoticInputBox_T(doEditColorCodes, theCvar, string_null);
}
void XonoticInputBox_configureXonoticInputBox(entity me, bool doEditColorCodes, string theCvar, string theTooltip)
{
	me.configureInputBox(me, "", 0, me.fontSize, me.image);
	me.editColorCodes = doEditColorCodes;
	me.controlledCvar = (theCvar) ? theCvar : string_null;
	me.loadCvars(me);
	setZonedTooltip(me, theTooltip, theCvar);
	me.cursorPos = strlen(me.text);
}
void XonoticInputBox_focusLeave(entity me)
{
	me.saveCvars(me);
}
void XonoticInputBox_setText(entity me, string val)
{
	if(me.text != val)
	{
		SUPER(XonoticInputBox).setText(me, val);
		if(me.onChange)
			me.onChange(me, me.onChangeEntity);
		if(me.saveImmediately)
			me.saveCvars(me);
	}
	else
		SUPER(XonoticInputBox).setText(me, val);
}
void XonoticInputBox_loadCvars(entity me)
{
	if (!me.controlledCvar)
		return;
	SUPER(XonoticInputBox).setText(me, cvar_string(me.controlledCvar));
}
void XonoticInputBox_saveCvars(entity me)
{
	if (!me.controlledCvar)
		return;
	cvar_set(me.controlledCvar, me.text);
	CheckSendCvars(me, me.controlledCvar);
}
float XonoticInputBox_keyDown(entity me, float key, float ascii, float shift)
{
	float r;
	r = 0;
	if(key == K_ENTER || key == K_KP_ENTER)
	{
		if(me.controlledCvar)
		{
			me.saveCvars(me);
			r = 1;
		}
		if(me.onEnter)
			me.onEnter(me, me.onEnterEntity);
	}
	if(SUPER(XonoticInputBox).keyDown(me, key, ascii, shift))
		r = 1;
	return r;
}
