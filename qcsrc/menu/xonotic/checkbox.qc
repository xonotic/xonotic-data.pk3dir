#include "checkbox.qh"

entity makeXonoticCheckBox_T(float isInverted, string theCvar, string theText, string theTooltip)
{
	float m, n;
	if(isInverted > 1)
	{
		n = isInverted - 1;
		m = -n;
	}
	else if(isInverted < -1)
	{
		n = isInverted + 1;
		m = -n;
	}
	else if(isInverted == 1)
	{
		n = 1;
		m = 0;
	}
	else
	{
		n = 0;
		m = 1;
	}
	return makeXonoticCheckBoxEx_T(m, n, theCvar, theText, theTooltip);
}
entity makeXonoticCheckBox(float isInverted, string theCvar, string theText)
{
	return makeXonoticCheckBox_T(isInverted, theCvar, theText, string_null);
}

entity makeXonoticCheckBoxEx_T(float theYesValue, float theNoValue, string theCvar, string theText, string theTooltip)
{
	entity me;
	me = NEW(XonoticCheckBox);
	me.configureXonoticCheckBox(me, theYesValue, theNoValue, theCvar, theText, theTooltip);
	return me;
}
entity makeXonoticCheckBoxEx(float theYesValue, float theNoValue, string theCvar, string theText)
{
	return makeXonoticCheckBoxEx_T(theYesValue, theNoValue, theCvar, theText, string_null);
}

void XonoticCheckBox_configureXonoticCheckBox(entity me, float theYesValue, float theNoValue, string theCvar, string theText, string theTooltip)
{
	me.yesValue = theYesValue;
	me.noValue = theNoValue;
	me.checked = false;
	me.controlledCvar = (theCvar) ? theCvar : string_null;
	me.loadCvars(me);
	setZonedTooltip(me, theTooltip, theCvar);
	me.configureCheckBox(me, theText, me.fontSize, me.image);
}
void XonoticCheckBox_setChecked(entity me, bool val)
{
	if(val != me.checked)
	{
		me.checked = val;
		me.saveCvars(me);
		if(me.linkedCheckBox)
			me.linkedCheckBox.loadCvars(me.linkedCheckBox);
	}
}
void XonoticCheckBox_loadCvars(entity me)
{
	if (!me.controlledCvar)
		return;

	float m = (me.yesValue + me.noValue) * 0.5;
	float d = (cvar(me.controlledCvar) - m) / (me.yesValue - m);
	me.checked = (d > 0);
}
void XonoticCheckBox_saveCvars(entity me)
{
	if (!me.controlledCvar)
		return;

	if(me.checked)
		cvar_set(me.controlledCvar, ftos_mindecimals(me.yesValue));
	else
		cvar_set(me.controlledCvar, ftos_mindecimals(me.noValue));

	CheckSendCvars(me, me.controlledCvar);
}
