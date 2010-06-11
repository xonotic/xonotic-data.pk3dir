#ifdef INTERFACE
CLASS(XonoticCheckBoxHUDName) EXTENDS(CheckBox)
	METHOD(XonoticCheckBoxHUDName, configureXonoticCheckBoxHUDName, void(entity, float, float, float, string))
	METHOD(XonoticCheckBoxHUDName, setChecked, void(entity, float))
	ATTRIB(XonoticCheckBoxHUDName, fontSize, float, SKINFONTSIZE_NORMAL)
	ATTRIB(XonoticCheckBoxHUDName, image, string, SKINGFX_CHECKBOX)
	ATTRIB(XonoticCheckBoxHUDName, yesValue, float, 1)
	ATTRIB(XonoticCheckBoxHUDName, noValue, float, 0)

	ATTRIB(XonoticCheckBoxHUDName, color, vector, SKINCOLOR_CHECKBOX_N)
	ATTRIB(XonoticCheckBoxHUDName, colorC, vector, SKINCOLOR_CHECKBOX_C)
	ATTRIB(XonoticCheckBoxHUDName, colorF, vector, SKINCOLOR_CHECKBOX_F)
	ATTRIB(XonoticCheckBoxHUDName, colorD, vector, SKINCOLOR_CHECKBOX_D)

	ATTRIB(XonoticCheckBoxHUDName, setting, float, 0)
	METHOD(XonoticCheckBoxHUDName, loadCvars, void(entity))
	METHOD(XonoticCheckBoxHUDName, saveCvars, void(entity))

	ATTRIB(XonoticCheckBoxHUDName, alpha, float, SKINALPHA_TEXT)
	ATTRIB(XonoticCheckBoxHUDName, disabledAlpha, float, SKINALPHA_DISABLED)
ENDCLASS(XonoticCheckBoxHUDName)
entity makeXonoticCheckBoxHUDName(float, float, string);
entity makeXonoticCheckBoxHUDNameEx(float, float, float, string);
#endif

#ifdef IMPLEMENTATION
entity makeXonoticCheckBoxHUDName(float isInverted, float theSetting, string theText)
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
	return makeXonoticCheckBoxHUDNameEx(y, n, theSetting, theText);
}
entity makeXonoticCheckBoxHUDNameEx(float theYesValue, float theNoValue, float theSetting, string theText)
{
	entity me;
	me = spawnXonoticCheckBoxHUDName();
	me.configureXonoticCheckBoxHUDName(me, theYesValue, theNoValue, theSetting, theText);
	return me;
}
void configureXonoticCheckBoxHUDNameXonoticCheckBoxHUDName(entity me, float theYesValue, float theNoValue, float theSetting, string theText)
{
	me.yesValue = theYesValue;
	me.noValue = theNoValue;
	me.checked = 0;

	me.setting = theSetting;
	//me.tooltip = getZonedTooltipForIdentifier(theSetting);
	me.loadCvars(me);

	me.configureCheckBox(me, theText, me.fontSize, me.image);
}
void setCheckedXonoticCheckBoxHUDName(entity me, float val)
{
	if(val != me.checked)
	{
		me.checked = val;
		me.saveCvars(me);
	}
}
void loadCvarsXonoticCheckBoxHUDName(entity me)
{
	float m, d;

	m = (me.yesValue + me.noValue) * 0.5;
	d = (cvar(strcat("hud_", HUD_Panel_GetName(highlightedPanel), HUD_Panel_GetSettingName(me.setting))) - m) / (me.yesValue - m);
	me.checked = (d > 0);
}
void saveCvarsXonoticCheckBoxHUDName(entity me)
{
	if(me.checked)
		cvar_set(strcat("hud_", HUD_Panel_GetName(highlightedPanel), HUD_Panel_GetSettingName(me.setting)), ftos(me.yesValue));
	else
		cvar_set(strcat("hud_", HUD_Panel_GetName(highlightedPanel), HUD_Panel_GetSettingName(me.setting)), ftos(me.noValue));
}
#endif
