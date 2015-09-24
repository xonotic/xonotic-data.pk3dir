#ifndef CHECKBOX_H
#define CHECKBOX_H
#include "../item/checkbox.qc"
CLASS(XonoticCheckBox, CheckBox)
	METHOD(XonoticCheckBox, configureXonoticCheckBox, void(entity, float, float, string, string, string));
	METHOD(XonoticCheckBox, setChecked, void(entity, float));
	ATTRIB(XonoticCheckBox, fontSize, float, SKINFONTSIZE_NORMAL)
	ATTRIB(XonoticCheckBox, image, string, SKINGFX_CHECKBOX)
	ATTRIB(XonoticCheckBox, yesValue, float, 1)
	ATTRIB(XonoticCheckBox, noValue, float, 0)

	ATTRIB(XonoticCheckBox, color, vector, SKINCOLOR_CHECKBOX_N)
	ATTRIB(XonoticCheckBox, colorC, vector, SKINCOLOR_CHECKBOX_C)
	ATTRIB(XonoticCheckBox, colorF, vector, SKINCOLOR_CHECKBOX_F)
	ATTRIB(XonoticCheckBox, colorD, vector, SKINCOLOR_CHECKBOX_D)

	ATTRIB(XonoticCheckBox, cvarName, string, string_null)
	METHOD(XonoticCheckBox, loadCvars, void(entity));
	METHOD(XonoticCheckBox, saveCvars, void(entity));
	ATTRIB(XonoticCheckBox, sendCvars, float, 0)

	ATTRIB(XonoticCheckBox, alpha, float, SKINALPHA_TEXT)
	ATTRIB(XonoticCheckBox, disabledAlpha, float, SKINALPHA_DISABLED)
ENDCLASS(XonoticCheckBox)
entity makeXonoticCheckBox_T(float, string, string, string);
entity makeXonoticCheckBox(float, string, string);
entity makeXonoticCheckBoxEx_T(float, float, string, string, string);
entity makeXonoticCheckBoxEx(float, float, string, string);
#endif

#ifdef IMPLEMENTATION
entity makeXonoticCheckBox_T(float isInverted, string theCvar, string theText, string theTooltip)
{
	float y, n;
	if(isInverted > 1)
	{
		n = isInverted - 1;
		y = -n;
	}
	else if(isInverted < -1)
	{
		n = isInverted + 1;
		y = -n;
	}
	else if(isInverted == 1)
	{
		n = 1;
		y = 0;
	}
	else
	{
		n = 0;
		y = 1;
	}
	return makeXonoticCheckBoxEx_T(y, n, theCvar, theText, theTooltip);
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
	me.checked = 0;
	me.cvarName = (theCvar) ? theCvar : string_null;
	me.loadCvars(me);
	setZonedTooltip(me, theTooltip, theCvar);
	me.configureCheckBox(me, theText, me.fontSize, me.image);
}
void XonoticCheckBox_setChecked(entity me, float val)
{
	if(val != me.checked)
	{
		me.checked = val;
		me.saveCvars(me);
	}
}
void XonoticCheckBox_loadCvars(entity me)
{
	float m, d;

	if (!me.cvarName)
		return;

	m = (me.yesValue + me.noValue) * 0.5;
	d = (cvar(me.cvarName) - m) / (me.yesValue - m);
	me.checked = (d > 0);
}
void XonoticCheckBox_saveCvars(entity me)
{
	if (!me.cvarName)
		return;

	if(me.checked)
		cvar_set(me.cvarName, ftos(me.yesValue));
	else
		cvar_set(me.cvarName, ftos(me.noValue));

	CheckSendCvars(me, me.cvarName);
}
#endif
